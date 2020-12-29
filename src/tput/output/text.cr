class Tput
  module Output
    module Text
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      # Prints text with optional attributes
      def print(txt, attr=nil)
        # XXX to_slice until it's replaced with direct io write
        _print (attr ? text(txt, attr) : txt)
      end
      alias_previous echo

      # Writes string `str` (repeated `i` times and with `attr` attributes)
      def simple_insert(str, i, attr)
        _write (str*i), attr
      end

      # Repeats string `str` `i` times.
      def repeat(str,i = 1)
        if (!i || i < 0)
          i = 0
        end
        str * i
      end

      def vtab
        @position.y+=1
        _ncoords
        _print "\x0b"
      end

      def form
        put(ff?) || _print "\x0c"
      end
      alias_previous ff, formfeed, form_feed

      def backspace
        @position.x-=1
        _ncoords
        put(kbs?) || _print "\x08"
      end
      alias_previous kbs

      def tab
        @position.x += 8
        _ncoords
        put(ht?) || _print "\t"
      end
      alias_previous ht

      def shift_out
        #put(S2?) ||
        _print "\x0e"
      end

      def shift_in
        #has_and_put("S3") ||
        _print "\x0f"
      end

      def cr
        @position.x = 0
        put(cr?) || _print "\r"
      end
      #alias_previous # TODO can't alias 'return'

      def feed
        @shim.try do |s|
          if s.eat_newline_glitch? && @position.x >= @screen_size.width
            return
          end
        end

        @position.x = 0
        @position.y+=1
        _ncoords()
        put(nel?) || _print "\n"
      end
      alias_previous nel, newline

      # ESC E Next Line (NEL is 0x85).
      def next_line
        @position.y+=1
        @position.x = 0
        _ncoords
        put(nel?) || _print "\x1bE"
      end

      # ESC H Tab Set (HTS is 0x88).
      def tab_set
        put(hts?) || _print "\x1bH"
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

      def text(text, attr)
        _attr(attr, true) + text + _attr(attr, false)
      end

      # NOTE this function is a mess. Rework and improve.
      #
      # NOTE: sun-color may not allow multiple params for SGR.
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
            part = (_attr(part, val) || "")
            part = part[2..]? || ""
            break if !part && (part == "")
            break if used[part]?
            used[part] = true
            outbuf.push part
          end

          #return outbuf.map{|e| "\x1b[#{e}m"}.join
          # TODO figure this out. Sequence gets aborted at some point
          # and the rest printed to the screen.
          return "\x1b[#{outbuf.join ';'}m"
        end

        if param.index("no ") == 0
          param = param[3..]
          val = false
        elsif param.index("!") == 0
          param = param[1..]
          val = false
        end

        # TODO turn to enum
        # TODO turn !val ? y : x   into  val ? x : y
        case param
          # attributes
          when "normal", "default"
            return "" if !val
            return "\x1b[m"
          when "bold"
            return !val ? "\x1b[22m" : "\x1b[1m"
          when "ul", "underline", "underlined"
            return !val ? "\x1b[24m" : "\x1b[4m"
          when "blink"
            return !val ? "\x1b[25m" : "\x1b[5m"
          when "inverse"
            return !val ? "\x1b[27m" : "\x1b[7m"
          when "invisible"
            return !val ? "\x1b[28m" : "\x1b[8m"

          # 8-color foreground
          when "black fg"
            return !val ? "\x1b[39m" : "\x1b[30m"
          when "red fg"
            return !val ? "\x1b[39m" : "\x1b[31m"
          when "green fg"
            return !val ? "\x1b[39m" : "\x1b[32m"
          when "yellow fg"
            return !val ? "\x1b[39m" : "\x1b[33m"
          when "blue fg"
            return !val ? "\x1b[39m" : "\x1b[34m"
          when "magenta fg"
            return !val ? "\x1b[39m" : "\x1b[35m"
          when "cyan fg"
            return !val ? "\x1b[39m" : "\x1b[36m"
          when "white fg", "light grey fg", "light gray fg", "bright grey fg", "bright gray fg"
            return !val ? "\x1b[39m" : "\x1b[37m"
          when "default fg"
            return "" if !val
            return "\x1b[39m"

          # 8-color background
          when "black bg"
            return !val ? "\x1b[49m" : "\x1b[40m"
          when "red bg"
            return !val ? "\x1b[49m" : "\x1b[41m"
          when "green bg"
            return !val ? "\x1b[49m" : "\x1b[42m"
          when "yellow bg"
            return !val ? "\x1b[49m" : "\x1b[43m"
          when "blue bg"
            return !val ? "\x1b[49m" : "\x1b[44m"
          when "magenta bg"
            return !val ? "\x1b[49m" : "\x1b[45m"
          when "cyan bg"
            return !val ? "\x1b[49m" : "\x1b[46m"
          when "white bg", "light grey bg", "light gray bg", "bright grey bg", "bright gray bg"
            return !val ? "\x1b[49m" : "\x1b[47m"
          when "default bg"
            return "" if !val
            return "\x1b[49m"

          # 16-color foreground
          when "light black fg", "bright black fg", "grey fg", "gray fg"
            return !val ? "\x1b[39m" : "\x1b[90m"
          when "light red fg", "bright red fg"
            return !val ? "\x1b[39m" : "\x1b[91m"
          when "light green fg", "bright green fg"
            return !val ? "\x1b[39m" : "\x1b[92m"
          when "light yellow fg", "bright yellow fg"
            return !val ? "\x1b[39m" : "\x1b[93m"
          when "light blue fg", "bright blue fg"
            return !val ? "\x1b[39m" : "\x1b[94m"
          when "light magenta fg", "bright magenta fg"
            return !val ? "\x1b[39m" : "\x1b[95m"
          when "light cyan fg", "bright cyan fg"
            return !val ? "\x1b[39m" : "\x1b[96m"
          when "light white fg", "bright white fg"
            return !val ? "\x1b[39m" : "\x1b[97m"

          # 16-color background
          when "light black bg", "bright black bg", "grey bg", "gray bg"
            return !val ? "\x1b[49m" : "\x1b[100m"
          when "light red bg", "bright red bg"
            return !val ? "\x1b[49m" : "\x1b[101m"
          when "light green bg", "bright green bg"
            return !val ? "\x1b[49m" : "\x1b[102m"
          when "light yellow bg", "bright yellow bg"
            return !val ? "\x1b[49m" : "\x1b[103m"
          when "light blue bg", "bright blue bg"
            return !val ? "\x1b[49m" : "\x1b[104m"
          when "light magenta bg", "bright magenta bg"
            return !val ? "\x1b[49m" : "\x1b[105m"
          when "light cyan bg", "bright cyan bg"
            return !val ? "\x1b[49m" : "\x1b[106m"
          when "light white bg", "bright white bg"
            return !val ? "\x1b[49m" : "\x1b[107m"

          # non-16-color rxvt default fg and bg
          when "default fg bg"
            return "" if !val
            return name?("rxvt") ? "\x1b[100m" : "\x1b[39;49m"

          else
            # 256-color fg and bg
            if param[0] == "#"
              raise Exception.new "Not implemented yet; use less than 256colors+#ccc, or implement this."
              # TODO This requires color functions as separate shard
              #param = param.sub(/#(?:[0-9a-f]{3}){1,2}/i) { |s| color_match s }
            end

            m = /^(-?\d+) (fg|bg)$/.match param
            if m
              color = m[1].to_i

              if !val || color == -1
                return _attr "default #{m[2]}"
              end

              # TODO
              #color = ::Crysterm::Colors.reduce(color, @tput.colors)

              # XXX color < 16 or <=? Seems <= ?
              if (color < 16) || @shim.try { |s| s.colors?.try { |c| c <= 16}}
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
                return "\x1b[#{color}m"
              end

              if m[2] == "fg"
                return "\x1b[38;5;#{color}m"
              end

              if m[2] == "bg"
                return "\x1b[48;5;#{color}m"
              end
            end

            if /^[\d;]*$/.match param
              return "\x1b[#{param}m"
            end

            return ""
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
      def insert_chars(param=1)
        @position.x += param
        _ncoords
        put(ich?(param)) || _print { |io| io << "\x1b[" << param << "@" }
      end
      alias_previous ich

      # CSI Ps L
      # Insert Ps Line(s) (default = 1) (IL).
      def insert_lines(param=1)
        put(il?(param)) || _print { |io| io << "\x1b[" << param << "L" }
      end
      alias_previous il

      # CSI Ps M
      # Delete Ps Line(s) (default = 1) (DL).
      def delete_lines(param=1)
        put(dl?(param)) || _print { |io| io << "\x1b[" << param << "M" }
      end
      alias_previous dl

      # CSI Ps P
      # Delete Ps Character(s) (default = 1) (DCH).
      def delete_chars(param=1)
        put(dch?(param)) || _print { |io| io << "\x1b[" << param << "P" }
      end
      alias_previous dch

      # CSI Ps X
      # Erase Ps Character(s) (default = 1) (ECH).
      def erase_chars(param=1)
        put(ech?(param)) || _print { |io| io << "\x1b[" << param << "X" }
      end
      alias_previous ech

      # ESC # 3 DEC line height/width
      def line_height
        _print "\x1b#"
      end

      # OSC Ps ; Pt ST
      # OSC Ps ; Pt BEL
      #   Sel data
      def sel_data(a,b)
        put(_Ms?(a,b)) || _tprint "\x1b]52;#{a};#{b}\x07"
      end

      # CSI Ps K  Erase in Line (EL).
      #     Ps = 0  -> Erase to Right (default).
      #     Ps = 1  -> Erase to Left.
      #     Ps = 2  -> Erase All.
      # CSI ? Ps K
      #   Erase in Line (DECSEL).
      #     Ps = 0  -> Selective Erase to Right (default).
      #     Ps = 1  -> Selective Erase to Left.
      #     Ps = 2  -> Selective Erase All.
      def erase_in_line(param)

        @shim.try { |shim|
          # Disabled originally
          #if (tput.back_color_erase) ...
          case (param)
            when "left"
              param = 1
            when "all"
              param = 2
            when "right"
              param = 0
            else
              param = 0
          end
          put(el?(param))
        } ||

        case (param)
          when "left"
            _print "\x1b[1K"
          when "all"
            _print "\x1b[2K"
          when "right"
            _print "\x1b[K"
          else
            _print "\x1b[K"
        end
      end
      alias_previous el

      # CSI P m SP }
      # Insert P s Column(s) (default = 1) (DECIC), VT420 and up.
      # NOTE: xterm doesn't enable this code by default.
      def insert_columns(*arguments)
        _print "\x1b[#{arguments.join ';'} }"
      end
      alias_previous decic

      # CSI P m SP ~
      # Delete P s Column(s) (default = 1) (DECDC), VT420 and up
      # NOTE: xterm doesn't enable this code by default.
      def delete_columns(*arguments)
        _print "\x1b[#{arguments.join ';'} ~"
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
      def repeat_preceding_character(param=1)
        @position.x += param
        _ncoords
        put(rep?(param)) || _print { |io| io << "\x1b[" << param << "b" }
      end
      alias_previous rep, rpc

      # CSI Ps g  Tab Clear (TBC).
      #     Ps = 0  -> Clear Current Column (default).
      #     Ps = 3  -> Clear All.
      # Potentially:
      #   Ps = 2  -> Clear Stops on Line.
      #   http:#vt100.net/annarbor/aaa-ug/section6.html
      def tab_clear(param=0)
        put(tbc?(param)) || _print { |io| io << "\x1b[" << param << "g" }
      end
      alias_previous tbc

      # CSI Ps " q
      #   Select character protection attribute (DECSCA).  Valid values
      #   for the parameter:
      #     Ps = 0  -> DECSED and DECSEL can erase (default).
      #     Ps = 1  -> DECSED and DECSEL cannot erase.
      #     Ps = 2  -> DECSED and DECSEL can erase.
      def set_char_protection_attr(param=0)
        _print { |io| io << "\x1b[" << param << "\"q" }
      end
      alias_previous decsca

    end
  end
end
