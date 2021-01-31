class Tput
  module Output
    module Text
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Crystallabs::Helpers::Logging
      include Macros

      ## Prints text with optional attributes
      #def print(txt, attr = nil)
      #  # XXX to_slice until it's replaced with direct io write
      #  _print (attr ? text(txt, attr) : txt)
      #end
      #alias_previous echo

      # Writes string `str` (repeated `i` times and with `attr` attributes)
      def simple_insert(str, i = 1, attr = nil)
        if i > 1
          _print str.to_s*i, attr
        else
          _print str, attr
        end
      end

      def echo(text, attr = nil)
        _print attr ? text(text, attr) : text
      end

      def text(text, attr)
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
        put(&.kbs?) || _print "\b" # "\x08"
      end

      alias_previous kbs, bs

      # TODO - Horribly broken
      #
      # Moves the cursor to the next character tab stop.
      #
      # TODO Currently it assumes tabs are 8 characters wide. There is no support for detecting actual tab width.
      # TODO Actually - look at tab_size. So at least the user can manually adjust.
      # TODO But, TAB doesn't move +8. It moves to the next tab stop. And there is always one at very end of line.
      #
      # Aliases: ht, tab, htab
      private def horizontal_tab
        @cursor.x += 8
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
        # TODO - maybe it is not enough to check the bottom of the screen, but
        # scroll region?
        _x, y = _adjust_xy_rel 0, 1
        @cursor.y += y

        # TODO the IFs
        # if y == 1
        #  # We can proceed
        # XXX really? we do nel here?
        put(&.nel?) || _print "\n"
        # else
        #  # We are already on the last line; either ignoring the sequence
        #  # or scrolling should happen.
        # end
      end

      alias_previous feed, lf, next_line, nel

      # Moves the cursor one row down without changing the column position.
      #
      # TODO What about scrolling?
      #
      # Aliases: vtab, vt
      def vertical_tab
        # TODO - maybe it is not enough to check the bottom of the screen, but
        # scroll region?
        _x, y = _adjust_xy_rel 0, 1
        @cursor.y += y

        # TODO the IFs
        # if y == 1
        #  # We can proceed
        _print "\v"
        # else
        #  # We are already on the last line; what happens?
        # end
      end

      alias_previous vtab, vt

      # Moves the cursor one row down without changing the column position.
      #
      # TODO What about scrolling?
      #
      # Aliases: ff
      def form_feed
        # TODO - maybe it is not enough to check the bottom of the screen, but
        # scroll region?
        _x, y = _adjust_xy_rel 0, 1
        @cursor.y += y

        # TODO the IFs
        # if y == 1
        #  # We can proceed
        _print "\f"
        # else
        #  # We are already on the last line; what happens?
        # end
      end

      alias_previous ff

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
        _write _attr(param, val)
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
        parts = [] of String
        color = nil
        m = nil

        case param
        when Array
          parts = param
          param = parts[0].blank? ? "normal" : parts[0]
        when String
          param = param.blank? ? "normal" : param
          parts = param.split /\s*[,;]\s*/
        end

        if parts.size > 1
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

            break unless part
            break if used[part]?
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
          return "\e[m"
        when "bold"
          return !val ? "\e[22m" : "\e[1m"
        when "ul", "underline", "underlined"
          return !val ? "\e[24m" : "\e[4m"
        when "blink"
          return !val ? "\e[25m" : "\e[5m"
        when "inverse"
          return !val ? "\e[27m" : "\e[7m"
        when "invisible"
          return !val ? "\e[28m" : "\e[8m"
          # 8-color foreground
        when "black fg"
          return !val ? "\e[39m" : "\e[30m"
        when "red fg"
          return !val ? "\e[39m" : "\e[31m"
        when "green fg"
          return !val ? "\e[39m" : "\e[32m"
        when "yellow fg"
          return !val ? "\e[39m" : "\e[33m"
        when "blue fg"
          return !val ? "\e[39m" : "\e[34m"
        when "magenta fg"
          return !val ? "\e[39m" : "\e[35m"
        when "cyan fg"
          return !val ? "\e[39m" : "\e[36m"
        when "white fg", "light grey fg", "light gray fg", "bright grey fg", "bright gray fg"
          return !val ? "\e[39m" : "\e[37m"
        when "default fg"
          return "" if !val
          return "\e[39m"

          # 8-color background
        when "black bg"
          return !val ? "\e[49m" : "\e[40m"
        when "red bg"
          return !val ? "\e[49m" : "\e[41m"
        when "green bg"
          return !val ? "\e[49m" : "\e[42m"
        when "yellow bg"
          return !val ? "\e[49m" : "\e[43m"
        when "blue bg"
          return !val ? "\e[49m" : "\e[44m"
        when "magenta bg"
          return !val ? "\e[49m" : "\e[45m"
        when "cyan bg"
          return !val ? "\e[49m" : "\e[46m"
        when "white bg", "light grey bg", "light gray bg", "bright grey bg", "bright gray bg"
          return !val ? "\e[49m" : "\e[47m"
        when "default bg"
          return "" if !val
          return "\e[49m"

          # 16-color foreground
        when "light black fg", "bright black fg", "grey fg", "gray fg"
          return !val ? "\e[39m" : "\e[90m"
        when "light red fg", "bright red fg"
          return !val ? "\e[39m" : "\e[91m"
        when "light green fg", "bright green fg"
          return !val ? "\e[39m" : "\e[92m"
        when "light yellow fg", "bright yellow fg"
          return !val ? "\e[39m" : "\e[93m"
        when "light blue fg", "bright blue fg"
          return !val ? "\e[39m" : "\e[94m"
        when "light magenta fg", "bright magenta fg"
          return !val ? "\e[39m" : "\e[95m"
        when "light cyan fg", "bright cyan fg"
          return !val ? "\e[39m" : "\e[96m"
        when "light white fg", "bright white fg"
          return !val ? "\e[39m" : "\e[97m"
          # 16-color background
        when "light black bg", "bright black bg", "grey bg", "gray bg"
          return !val ? "\e[49m" : "\e[100m"
        when "light red bg", "bright red bg"
          return !val ? "\e[49m" : "\e[101m"
        when "light green bg", "bright green bg"
          return !val ? "\e[49m" : "\e[102m"
        when "light yellow bg", "bright yellow bg"
          return !val ? "\e[49m" : "\e[103m"
        when "light blue bg", "bright blue bg"
          return !val ? "\e[49m" : "\e[104m"
        when "light magenta bg", "bright magenta bg"
          return !val ? "\e[49m" : "\e[105m"
        when "light cyan bg", "bright cyan bg"
          return !val ? "\e[49m" : "\e[106m"
        when "light white bg", "bright white bg"
          return !val ? "\e[49m" : "\e[107m"
          # non-16-color rxvt default fg and bg
        when "default fg bg"
          return "" if !val
          return name?("rxvt") ? "\e[100m" : "\e[39;49m"
        else
          # 256-color fg and bg
          if param[0] == "#"
            raise Exception.new "Not implemented yet; use less than 256colors+#ccc, or implement this."
            # TODO This requires color functions as separate shard
            # param = param.sub(/#(?:[0-9a-f]{3}){1,2}/i) { |s| color_match s }
          end

          m = param.match /^(-?\d+) (fg|bg)$/
          if m
            color = m[1].to_i

            if !val || color == -1
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

          return
        end
      end

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
      #     Ps = 1 0 0  -> Set foreground and background color to
      #     default.
      #
      #   If 88- or 256-color support is compiled, the following apply.
      #     Ps = 3 8  ; 5  ; Ps -> Set foreground color to the second
      #     Ps.
      #     Ps = 4 8  ; 5  ; Ps -> Set background color to the second
      #     Ps.
      def char_attributes(param, val)
        _write _attr param, val
      end

      alias_previous sgr, attr

      # CSI Ps @
      # Insert Ps (Blank) Character(s) (default = 1) (ICH).
      # XXX switch to adjust_xy
      def insert_chars(param = 1)
        @cursor.x += param
        _ncoords
        put(&.ich?(param)) || _print { |io| io << "\e[" << param << '@' }
      end

      alias_previous ich

      # Insert line(s).
      #     CSI Ps L
      #     Insert Ps Line(s) (default = 1) (IL).
      def insert_line(param : Int = 1)
        param > 0 || raise ArgumentError.new "param > 0"

        if param == 1
          put(&.il1?) || put(&.il?(param))
        else
          put(&.il?(param))
        end || _print { |io| io << "\e[" << param << 'L' }
      end

      alias_previous il

      # Delete line(s).
      #     CSI Ps M
      #     Delete Ps Line(s) (default = 1) (DL).
      def delete_line(param : Int = 1)
        param > 0 || raise ArgumentError.new "param > 0"

        if param == 1
          put(&.dl1?) || put(&.dl?(param))
        else
          put(&.dl?(param))
        end || _print { |io| io << "\e[" << param << 'M' }
      end

      alias_previous dl

      # CSI Ps P
      # Delete Ps Character(s) (default = 1) (DCH).
      def delete_chars(param = 1)
        put(&.dch?(param)) || _print { |io| io << "\e[" << param << 'P' }
      end

      alias_previous dch

      # Erase character(s).
      #     CSI Ps X
      #     Erase Ps Character(s) (default = 1) (ECH).
      def erase_character(param : Int = 1)
        put(&.ech?(param)) || _print { |io| io << "\e[" << param << 'X' }
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
        put(&._Ms?(a, b)) || _tprint { |io| io << "\e]52;" << a << ';' << b << "\x07" }
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
        case (param)
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
        _print { |io| io << "\e[" << n << " ~" }
      end

      alias_previous decdc

      def set_foreground(color, val)
        color = color.split(/\s*[,;]\s*/).join(" fg, ") + " fg"
        attr(color, val)
      end

      alias_previous fg

      def set_background(color, val)
        color = color.split(/\s*[,;]\s*/).join(" bg, ") + " bg"
        attr(color, val)
      end

      alias_previous bg

      # CSI Ps b  Repeat the preceding graphic character Ps times (REP).
      def repeat_preceding_character(param = 1)
        @cursor.x += param
        _ncoords
        put(&.rep?(param)) || _print { |io| io << "\e[" << param << "b" }
      end

      alias_previous rep, rpc

      # CSI Ps g  Tab Clear (TBC).
      #     Ps = 0  -> Clear Current Column (default).
      #     Ps = 3  -> Clear All.
      # Potentially:
      #   Ps = 2  -> Clear Stops on Line.
      #   http:#vt100.net/annarbor/aaa-ug/section6.html
      def tab_clear(param = 0)
        put(&.tbc?(param)) || _print { |io| io << "\e[" << param << "g" }
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
