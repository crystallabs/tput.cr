class Tput
  module Output
    module Text
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Crystallabs::Helpers::Logging
      include Macros

      # ICH/DCH/ECH share one emit shape: prefer the parametric edit cap as a
      # fast path only when the terminal isn't verified standard-ANSI, otherwise
      # the literal `CSI <param> <final>` is both the ANSI fast path and the
      # universal fallback. They differ only in their cap and final CSI byte.
      private macro _emit_char_edit(param, cap, final)
        (!features.ansi_edit? && put(&.{{cap}}?({{param}}))) || _print { |io| io << "\e[" << {{param}} << {{final}} }
      end

      # # Prints text with optional attributes
      # def print(txt, attr = nil)
      #  # XXX to_slice until it's replaced with direct io write
      #  _print (attr ? text(txt, attr) : txt)
      # end
      # alias_previous echo

      # Writes string `str` (repeated `i` times and with `attr` attributes)
      def simple_insert(str, i = 1, attr = nil)
        echo (i > 1 ? str.to_s * i : str), attr
      end

      def echo(text, attr = nil)
        if attr
          # Write the opening attribute, the text, and the closing attribute
          # straight to the output IO instead of concatenating them into a
          # temporary `String` first (this is on the styled-text hot path).
          _print { |io| io << _attr(attr, true) << text << _attr(attr, false) }
        else
          _print text
        end
      end

      def text(text, attr)
        # Plain concatenation. A `String.build` variant was tried (to "allocate
        # once") but benchmarked ~44% slower for the common short-string case:
        # the builder's default 64-byte buffer plus its final exact-size
        # truncation copy costs more than two small concatenations. The hot,
        # IO-materializing path is `#echo`, which writes the attrs straight to
        # the output IO (no intermediate String at all); prefer it where a
        # String result isn't actually needed. See bench/perf.cr (text_styled).
        _attr(attr, true) + text + _attr(attr, false)
      end

      # Moves the cursor one position to the left.
      #
      # Aliases: kbs, bs
      def backspace
        x, _y = _adjust_xy_rel -1
        x *= -1
        if x > 0
          @cursor.x -= 1
        end
        # Move the cursor one column left via the terminfo `cub1` (cursor_left)
        # OUTPUT capability — NOT `kbs`. `kbs` is `key_backspace`: the byte the
        # Backspace *key* sends, an INPUT capability. On terminals where it
        # differs from cub1 (e.g. macOS xterm and the linux console, where
        # kbs is DEL / `\177`) writing it does NOT move the terminal cursor, so
        # emitting it while decrementing `@cursor.x` above desynced the tracked
        # cursor from the real one (the same desync class as the ICH/DECRC/SU
        # fixes). cub1 is `\b` on xterm, matching the literal fallback; blessed's
        # `backspace` likewise emits a plain `\x08`, never `kbs`.
        put(&.cub1?) || _print "\b" # "\x08"
      end

      alias_previous kbs, bs

      # Moves the cursor to the next character tab stop.
      #
      # TODO Currently it assumes tabs are 8 characters wide. There is no support for detecting actual tab width.
      # TODO Actually - look at tab_size. So at least the user can manually adjust.
      #
      # Aliases: ht, tab, htab
      private def horizontal_tab
        # HT advances to the *next* tab stop, not a flat `+8`. With the standard
        # 8-column stops the next stop from column x is `(x // 8 + 1) * 8` — e.g.
        # from column 3 a tab lands on 8, not 11. The old `+= 8` over-advanced
        # `@cursor.x` from any column that wasn't already a multiple of 8,
        # desyncing the tracked cursor from where the terminal's HT actually
        # leaves it (the same desync class as the CHT/ICH fixes). The two agree at
        # tab-aligned columns, so existing aligned-start specs are intact. This is
        # the single-tab form of `#cursor_forward_tab` (CHT, param == 1).
        @cursor.x = (@cursor.x // 8 + 1) * 8
        _ncoords
        put(&.ht?) || _print "\t"
      end

      alias_previous ht, tab, htab

      # Switches to an alternative character set.
      #
      # Aliases: so
      def shift_out
        # put(&.S2?) ||
        _print "\x0e"
      end

      alias_previous so

      # Switches back to regular character set after `#shift_out`.
      #
      # Aliases: si
      def shift_in
        # has_and_put(&."S3") ||
        _print "\x0f"
      end

      alias_previous si

      # Moves the cursor to column 0.
      #
      # Aliases: cr
      def carriage_return
        @cursor.x = 0
        put(&.cr?) || _print "\r"
      end

      alias_previous cr

      # Moves the cursor one row down and to column 0, scrolling if needed.
      #
      # Scrolling is restricted to scroll margins and will only happen on the bottom line.
      #
      # TODO Adjusting internal data based on scrolling is not yet supported. (Whether scroll offsets need to be adjusted internally is yet to be checked.)
      #
      # Aliases: feed, lf, next_line, nel
      def line_feed
        @shim.try do |s|
          if s.eat_newline_glitch? && @cursor.x >= @screen.width
            return
          end
        end

        @cursor.x = 0
        # NOTE: This is a line feed (LF), so always emit a literal "\n".
        # The terminfo `nel` capability is NOT used here: it encodes NEL
        # (next-line, e.g. "\eE" on xterm), which is a distinct operation.
        _advance_line "\n"
      end

      alias_previous feed, lf, next_line, nel

      # Moves the cursor one row down without changing the column position.
      #
      # TODO What about scrolling?
      #
      # Aliases: vtab, vt
      def vertical_tab
        _advance_line "\v"
      end

      alias_previous vtab, vt

      # Moves the cursor one row down without changing the column position.
      #
      # TODO What about scrolling?
      #
      # Aliases: ff
      def form_feed
        _advance_line "\f"
      end

      alias_previous ff

      # Moves the cursor one row down (within scroll limits, via `_adjust_xy_rel`)
      # without changing the column, then emits *seq*. Shared by the one-row-down
      # controls `#line_feed` ("\n"), `#vertical_tab` ("\v") and `#form_feed`
      # ("\f"), which differ only in the byte written.
      private def _advance_line(seq : String)
        # TODO - maybe it is not enough to check the bottom of the screen, but
        # scroll region?
        _x, y = _adjust_xy_rel 0, 1
        @cursor.y += y
        # TODO the IFs: when y == 1 we proceed; otherwise we are already on the
        # last line and either the sequence is ignored or scrolling should happen.
        _print seq
      end

      # Places a tab stop at the current cursor position.
      #
      #     ESC H Tab Set (HTS is 0x88).
      #
      # Aliases: horizontal_tab_set, hts
      def horizontal_tabulation_set
        put(&.hts?) || _print "\eH"
      end

      alias_previous horizontal_tab_set, hts

      # CSI Pm m  Character Attributes (SGR).
      #     Ps = 0  -> Normal (default).
      #     Ps = 1  -> Bold.
      #     Ps = 4  -> Underlined.
      #     Ps = 5  -> Blink (appears as Bold).
      #     Ps = 7  -> Inverse.
      #     Ps = 8  -> Invisible, i.e., hidden (VT300).
      #     Ps = 2 2  -> Normal (neither bold nor faint).
      #     Ps = 2 4  -> Not underlined.
      #     Ps = 2 5  -> Steady (not blinking).
      #     Ps = 2 7  -> Positive (not inverse).
      #     Ps = 2 8  -> Visible, i.e., not hidden (VT300).
      #     Ps = 3 0  -> Set foreground color to Black.
      #     Ps = 3 1  -> Set foreground color to Red.
      #     Ps = 3 2  -> Set foreground color to Green.
      #     Ps = 3 3  -> Set foreground color to Yellow.
      #     Ps = 3 4  -> Set foreground color to Blue.
      #     Ps = 3 5  -> Set foreground color to Magenta.
      #     Ps = 3 6  -> Set foreground color to Cyan.
      #     Ps = 3 7  -> Set foreground color to White.
      #     Ps = 3 9  -> Set foreground color to default (original).
      #     Ps = 4 0  -> Set background color to Black.
      #     Ps = 4 1  -> Set background color to Red.
      #     Ps = 4 2  -> Set background color to Green.
      #     Ps = 4 3  -> Set background color to Yellow.
      #     Ps = 4 4  -> Set background color to Blue.
      #     Ps = 4 5  -> Set background color to Magenta.
      #     Ps = 4 6  -> Set background color to Cyan.
      #     Ps = 4 7  -> Set background color to White.
      #     Ps = 4 9  -> Set background color to default (original).
      #
      #   If 16-color support is compiled, the following apply.  Assume
      #   that xterm's resources are set so that the ISO color codes are
      #   the first 8 of a set of 16.  Then the aixterm colors are the
      #   bright versions of the ISO colors:
      #
      #     Ps = 9 0  -> Set foreground color to Black.
      #     Ps = 9 1  -> Set foreground color to Red.
      #     Ps = 9 2  -> Set foreground color to Green.
      #     Ps = 9 3  -> Set foreground color to Yellow.
      #     Ps = 9 4  -> Set foreground color to Blue.
      #     Ps = 9 5  -> Set foreground color to Magenta.
      #     Ps = 9 6  -> Set foreground color to Cyan.
      #     Ps = 9 7  -> Set foreground color to White.
      #     Ps = 1 0 0  -> Set background color to Black.
      #     Ps = 1 0 1  -> Set background color to Red.
      #     Ps = 1 0 2  -> Set background color to Green.
      #     Ps = 1 0 3  -> Set background color to Yellow.
      #     Ps = 1 0 4  -> Set background color to Blue.
      #     Ps = 1 0 5  -> Set background color to Magenta.
      #     Ps = 1 0 6  -> Set background color to Cyan.
      #     Ps = 1 0 7  -> Set background color to White.
      #
      #   If xterm is compiled with the 16-color support disabled, it
      #   supports the following, from rxvt:
      #
      #     Ps = 1 0 0  -> Set foreground and background color to
      #     default.
      #
      #   If 88- or 256-color support is compiled, the following apply.
      #     Ps = 3 8  ; 5  ; Ps -> Set foreground color to the second
      #     Ps.
      #     Ps = 4 8  ; 5  ; Ps -> Set background color to the second
      #     Ps.
      def char_attributes(param, val)
        _print _attr(param, val)
      end

      alias_previous sgr, attr

      # NOTE this function is a mess. Rework and improve.
      #
      # NOTE: sun-color may not allow multiple params for SGR.
      #
      # Allow printing to IO instead of returning strings. I suppose
      # the places where this is called from should make it quite
      # suitable to do so.
      #
      # XXX see if these attributes can somehow be combined with
      # Crystal's functionality in Colorize.
      # Also make this accept enum values rather than parsing a
      # string.
      def _attr(param : Array | String, val = true)
        # Cache the String case (by far the common one); the parse is pure and
        # its result deterministic for the life of the instance. The Array case
        # is rare and not worth keying, so it computes directly. A limit of 0
        # disables the cache (always recompute).
        if param.is_a?(String) && @attr_cache_limit > 0
          cached = @_attr_cache[{param, val}]?
          return cached if cached
          result = _compute_attr(param, val)
          # FIFO eviction: `Hash` keeps insertion order, so `shift?` drops the
          # oldest entry. The working set of attribute specs is tiny, so this
          # effectively never fires for normal use — it only bounds memory
          # against dynamic/unbounded inputs (e.g. a distinct truecolor per cell).
          @_attr_cache.shift? if @_attr_cache.size >= @attr_cache_limit
          @_attr_cache[{param, val}] = result
          return result
        end

        _compute_attr(param, val)
      end

      private def _compute_attr(param : Array | String, val = true)
        parts = [] of String
        color = nil
        m = nil
        multi = false

        case param
        when Array
          parts = param
          # Guard the empty list: `parts[0]` would raise IndexError. An empty
          # spec carries no attribute, so treat it like a blank/"normal" one
          # (consistent with the `parts[0].blank?` -> "normal" handling below).
          param = (parts.empty? || parts[0].blank?) ? "normal" : parts[0]
          multi = parts.size > 1
        when String
          param = param.blank? ? "normal" : param
          # Only the multi-component form needs splitting. The overwhelmingly
          # common single spec — including every truecolor "#rrggbb fg" — has no
          # `,`/`;` separator, so skip the regex scan and the 1-element Array it
          # would allocate. Byte-identical: a separator-less string splits to
          # exactly `[param]` (size 1), which already fell straight through here.
          if param.includes?(',') || param.includes?(';')
            parts = param.split /\s*[,;]\s*/
            multi = parts.size > 1
          end
        end

        if multi
          used = {} of String => Bool
          outbuf = [] of String

          parts.each do |part|
            # TODO having '? || ""' at the end makes for some errors
            # to creep in undetected. Like attr = "fg black, bg white".
            # (The second attr isn't honored)
            part = _attr(part, val)
            if part
              part = part[2...-1]?
            end

            next unless part
            # A component whose SGR body is empty (e.g. "normal"/"default", which
            # yield a bare "\e[m") must be dropped — emitting it would inject a
            # stray empty parameter like "\e[;31m". In the JS original "" is
            # falsy and skipped here; Crystal's "" is truthy, so skip explicitly.
            next if part.empty?
            next if used[part]?
            used[part] = true
            outbuf.push part
          end

          # return outbuf.map{|e| "\e[#{e}m"}.join
          # TODO figure this out. Sequence gets aborted at some point
          # and the rest printed to the screen.
          return "\e[#{outbuf.join ';'}m"
        end

        if param.starts_with? "no "
          param = param[3..]
          val = false
        elsif param.starts_with? "!"
          param = param[1..]
          val = false
        end

        # TODO turn to enum
        # TODO turn !val ? y : x   into  val ? x : y
        case param
        # attributes
        when "normal", "default"
          return "" if !val
          "\e[m"
        when "bold"
          !val ? "\e[22m" : "\e[1m"
        when "italic"
          !val ? "\e[23m" : "\e[3m"
        when "ul", "underline", "underlined"
          !val ? "\e[24m" : "\e[4m"
        when "blink"
          !val ? "\e[25m" : "\e[5m"
        when "reverse", "inverse"
          !val ? "\e[27m" : "\e[7m"
        when "invisible"
          !val ? "\e[28m" : "\e[8m"
        when "strikethrough", "strike", "crossed", "crossed_out"
          !val ? "\e[29m" : "\e[9m"
          # 8-color foreground
        when "black fg"
          !val ? "\e[39m" : "\e[30m"
        when "red fg"
          !val ? "\e[39m" : "\e[31m"
        when "green fg"
          !val ? "\e[39m" : "\e[32m"
        when "yellow fg"
          !val ? "\e[39m" : "\e[33m"
        when "blue fg"
          !val ? "\e[39m" : "\e[34m"
        when "magenta fg"
          !val ? "\e[39m" : "\e[35m"
        when "cyan fg"
          !val ? "\e[39m" : "\e[36m"
        when "white fg", "light grey fg", "light gray fg", "bright grey fg", "bright gray fg"
          !val ? "\e[39m" : "\e[37m"
        when "default fg"
          return "" if !val
          "\e[39m"

          # 8-color background
        when "black bg"
          !val ? "\e[49m" : "\e[40m"
        when "red bg"
          !val ? "\e[49m" : "\e[41m"
        when "green bg"
          !val ? "\e[49m" : "\e[42m"
        when "yellow bg"
          !val ? "\e[49m" : "\e[43m"
        when "blue bg"
          !val ? "\e[49m" : "\e[44m"
        when "magenta bg"
          !val ? "\e[49m" : "\e[45m"
        when "cyan bg"
          !val ? "\e[49m" : "\e[46m"
        when "white bg", "light grey bg", "light gray bg", "bright grey bg", "bright gray bg"
          !val ? "\e[49m" : "\e[47m"
        when "default bg"
          return "" if !val
          "\e[49m"

          # 16-color foreground
        when "light black fg", "bright black fg", "grey fg", "gray fg"
          !val ? "\e[39m" : "\e[90m"
        when "light red fg", "bright red fg"
          !val ? "\e[39m" : "\e[91m"
        when "light green fg", "bright green fg"
          !val ? "\e[39m" : "\e[92m"
        when "light yellow fg", "bright yellow fg"
          !val ? "\e[39m" : "\e[93m"
        when "light blue fg", "bright blue fg"
          !val ? "\e[39m" : "\e[94m"
        when "light magenta fg", "bright magenta fg"
          !val ? "\e[39m" : "\e[95m"
        when "light cyan fg", "bright cyan fg"
          !val ? "\e[39m" : "\e[96m"
        when "light white fg", "bright white fg"
          !val ? "\e[39m" : "\e[97m"
          # 16-color background
        when "light black bg", "bright black bg", "grey bg", "gray bg"
          !val ? "\e[49m" : "\e[100m"
        when "light red bg", "bright red bg"
          !val ? "\e[49m" : "\e[101m"
        when "light green bg", "bright green bg"
          !val ? "\e[49m" : "\e[102m"
        when "light yellow bg", "bright yellow bg"
          !val ? "\e[49m" : "\e[103m"
        when "light blue bg", "bright blue bg"
          !val ? "\e[49m" : "\e[104m"
        when "light magenta bg", "bright magenta bg"
          !val ? "\e[49m" : "\e[105m"
        when "light cyan bg", "bright cyan bg"
          !val ? "\e[49m" : "\e[106m"
        when "light white bg", "bright white bg"
          !val ? "\e[49m" : "\e[107m"
          # non-16-color rxvt default fg and bg
        when "default fg bg"
          return "" if !val
          name?("rxvt") ? "\e[100m" : "\e[39;49m"
        else
          # 256-color fg and bg
          # 24-bit truecolor: "#rgb fg" or "#rrggbb bg" -> CSI 38;2;r;g;b m (fg) / 48;2;… (bg)
          if hm = param.match /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}) (fg|bg)$/
            return _attr "default #{hm[2]}" if !val
            hex = hm[1]
            if hex.size == 3
              r = hex[0].to_i(16) * 0x11
              g = hex[1].to_i(16) * 0x11
              b = hex[2].to_i(16) * 0x11
            else
              r = hex[0, 2].to_i(16)
              g = hex[2, 2].to_i(16)
              b = hex[4, 2].to_i(16)
            end
            return "\e[#{hm[2] == "fg" ? 38 : 48};2;#{r};#{g};#{b}m"
          end

          m = param.match /^(-?\d+) (fg|bg)$/
          if m
            color = m[1].to_i

            # Any negative color is the "default" sentinel, not just -1. Other
            # negatives (e.g. -2) must NOT fall through to the `color < 16`
            # branch below, which would emit a bogus SGR like `\e[{color+30}m`.
            if !val || color < 0
              return _attr "default #{m[2]}"
            end

            # TODO
            # color = ::Crysterm::Colors.reduce(color, @tput.colors)

            # XXX color < 16 or <=? Seems <= ?
            if (color < 16) || @shim.try { |s| s.colors?.try { |c| c <= 16 } }
              if m[2] == "fg"
                if color < 8
                  color += 30
                elsif color < 16
                  color -= 8
                  color += 90
                end
              elsif m[2] == "bg"
                if color < 8
                  color += 40
                elsif color < 16
                  color -= 8
                  color += 100
                end
              end
              return "\e[#{color}m"
            end

            if m[2] == "fg"
              return "\e[38;5;#{color}m"
            end

            if m[2] == "bg"
              return "\e[48;5;#{color}m"
            end
          end

          if param.match /^[\d;]*$/
            return "\e[#{param}m"
          end

          ""
        end
      end

      # CSI Ps @
      # Insert Ps (Blank) Character(s) (default = 1) (ICH).
      def insert_chars(param = 1)
        param > 0 || raise ArgumentError.new "param > 0"

        # ICH inserts blank characters *at* the cursor and shifts the existing
        # content to its right; the active position (the cursor) stays put. Do
        # NOT advance `@cursor.x` here (that was copy-pasted from REP, which does
        # move) — doing so desynced the tracked cursor from the terminal's real
        # cursor on every insert. `delete_chars`/`erase_character` correctly leave
        # the cursor alone too.
        _emit_char_edit param, ich, '@'
      end

      alias_previous ich

      # Insert line(s).
      #     CSI Ps L
      #     Insert Ps Line(s) (default = 1) (IL).
      def insert_line(param : Int = 1)
        param > 0 || raise ArgumentError.new "param > 0"

        # IL moves the active position to the first column of the line (the line
        # home position), unlike the character ops ICH/DCH/ECH which leave the
        # cursor put. Reset the tracked column to match the terminal's real
        # cursor — leaving `@cursor.x` stale desynced every later relative move
        # (the same desync class as the ICH/SU/DECRC fixes). The row is unchanged.
        @cursor.x = 0
        # `param == 1` uses the static `il1` cap (no tparm), so it keeps its
        # terminfo route and exact byte output; only the parameterized
        # `param > 1` case (which would invoke tparm) takes the ansi_edit fast path.
        (param == 1 ? (put(&.il1?) || put(&.il?(param))) : (!features.ansi_edit? && put(&.il?(param)))) ||
          _print { |io| io << "\e[" << param << 'L' }
      end

      alias_previous il

      # Delete line(s).
      #     CSI Ps M
      #     Delete Ps Line(s) (default = 1) (DL).
      def delete_line(param : Int = 1)
        param > 0 || raise ArgumentError.new "param > 0"

        # Like IL, DL moves the active position to the first column of the line;
        # keep the tracked column in sync with the terminal's real cursor (see
        # `#insert_line`). The row is unchanged.
        @cursor.x = 0
        # `param == 1` uses the static `dl1` cap (no tparm); only `param > 1`
        # (parameterized, would invoke tparm) takes the ansi_edit fast path.
        (param == 1 ? (put(&.dl1?) || put(&.dl?(param))) : (!features.ansi_edit? && put(&.dl?(param)))) ||
          _print { |io| io << "\e[" << param << 'M' }
      end

      alias_previous dl

      # CSI Ps P
      # Delete Ps Character(s) (default = 1) (DCH).
      def delete_chars(param = 1)
        param > 0 || raise ArgumentError.new "param > 0"

        _emit_char_edit param, dch, 'P'
      end

      alias_previous dch

      # Erase character(s).
      #     CSI Ps X
      #     Erase Ps Character(s) (default = 1) (ECH).
      def erase_character(param : Int = 1)
        param > 0 || raise ArgumentError.new "param > 0"

        _emit_char_edit param, ech, 'X'
      end

      alias_previous ech, erase_chars

      # ESC # 3 DEC line height/width
      # XXX is this supposed to return result?
      def line_height
        _print "\e#"
      end

      # OSC Ps ; Pt ST
      # OSC Ps ; Pt BEL
      #   Sel data
      def sel_data(a, b)
        put_extended("Ms", a, b) || _tprint("\e]52;#{a};#{b}\x07")
      end

      # Erase in line.
      #     CSI Ps K  Erase in Line (EL).
      #         Ps = 0  -> Erase to Right (default).
      #         Ps = 1  -> Erase to Left.
      #         Ps = 2  -> Erase All.
      #     CSI ? Ps K
      #       Erase in Line (DECSEL).
      #         Ps = 0  -> Selective Erase to Right (default).
      #         Ps = 1  -> Selective Erase to Left.
      #         Ps = 2  -> Selective Erase All.
      def erase_in_line(param = LineDirection::Right)
        # NOTE xterm terminfo does not seem to have parametric 'el'?
        #   clr_eol                   / el         = \e[K
        # How did this work originally then?

        # put(&.el?(param.value)) ||
        case param
        when LineDirection::Right
          put(&.clr_eol?) || _print "\e[K"
        when LineDirection::Left
          put(&.clr_bol?) || _print "\e[1K"
        when LineDirection::All
          _print "\e[2K" # <- if no el?, why would this succeed?
          # Should we do instead manual erase to left and right?:
          # _print "\e[1K"
          # _print "\e[K"
        end
      end

      alias_previous el

      # Inserts `n` times columns into the scrolling region, starting with the column that has the cursor.
      #
      # As columns are inserted, the columns between the cursor and the right margin move to the right.
      # Columns are inserted blank with no visual character attributes.
      #
      # Has no effect outside the scrolling margins.
      #
      #     CSI P m SP }
      #     Insert P s Column(s) (default = 1) (DECIC), VT420 and up.
      #
      # NOTE: xterm doesn't enable this code by default.
      #
      # Aliases: decic
      def insert_columns(n = 1)
        n > 0 || raise ArgumentError.new "n > 0"

        _print { |io| io << "\e[" << n << " }" }
      end

      alias_previous decic

      # Deletes `n` times columns, starting with the column that has the cursor.
      #
      # As columns are deleted, the remaining columns between the cursor and the right
      # margin move to the left. The terminal adds blank columns with no visual
      # character attributes at the right margin.
      #
      # Has no effect outside the scrolling margins.
      #
      #     CSI P m SP ~
      #     Delete P s Column(s) (default = 1) (DECDC), VT420 and up
      #
      # NOTE xterm doesn't enable this code by default.
      #
      # Aliases: decdc
      def delete_columns(n = 1)
        n > 0 || raise ArgumentError.new "n > 0"

        _print { |io| io << "\e[" << n << " ~" }
      end

      alias_previous decdc

      def set_foreground(color, val)
        attr(_color_spec(color, " fg"), val)
      end

      alias_previous fg

      def set_background(color, val)
        attr(_color_spec(color, " bg"), val)
      end

      alias_previous bg

      # Suffixes each comma/semicolon-separated component of *color* with
      # *suffix* (e.g. `"red,blue"`, `" fg"` -> `"red fg, blue fg"`), built in a
      # single pass instead of `split.join(...) + suffix` (which allocated an
      # intermediate joined string plus the concatenation temporary).
      private def _color_spec(color : String, suffix : String) : String
        String.build do |io|
          first = true
          color.split(/\s*[,;]\s*/).each do |c|
            io << ", " unless first
            first = false
            io << c << suffix
          end
        end
      end

      # CSI Ps b  Repeat the preceding graphic character Ps times (REP).
      def repeat_preceding_character(param = 1)
        param > 0 || raise ArgumentError.new "param > 0"

        @cursor.x += param
        _ncoords
        # REP repeats the character already emitted, so the sequence carries only
        # the count. Do NOT use the terminfo `rep` cap here: it is a different
        # operation (`repeat_char`, format `%p1%c…%p2…`) that takes the *character*
        # as its first parameter — feeding it the count alone emits that count as
        # a literal control char plus a malformed sequence. There is no terminfo
        # capability for REP, so emit it directly.
        _print { |io| io << "\e[" << param << "b" }
      end

      alias_previous rep, rpc

      # CSI Ps g  Tab Clear (TBC).
      #     Ps = 0  -> Clear Current Column (default).
      #     Ps = 3  -> Clear All.
      # Potentially:
      #   Ps = 2  -> Clear Stops on Line.
      #   http:#vt100.net/annarbor/aaa-ug/section6.html
      def tab_clear(param = 0)
        # The terminfo `tbc` cap is `clear_all_tabs` — the fixed, non-parametric
        # `CSI 3 g` ("clear all") form. Use it only for `param == 3`; otherwise
        # (notably the default `param == 0`, "clear the current column") emit the
        # parametric `CSI Ps g` directly, or `tbc` would wrongly clear all stops.
        (param == 3 && put(&.tbc?)) || _print { |io| io << "\e[" << param << "g" }
      end

      alias_previous tbc

      # CSI Ps " q
      #   Select character protection attribute (DECSCA).  Valid values
      #   for the parameter:
      #     Ps = 0  -> DECSED and DECSEL can erase (default).
      #     Ps = 1  -> DECSED and DECSEL cannot erase.
      #     Ps = 2  -> DECSED and DECSEL can erase.
      def set_char_protection_attr(param = 0)
        _print { |io| io << "\e[" << param << "\"q" }
      end

      alias_previous decsca
    end
  end
end
