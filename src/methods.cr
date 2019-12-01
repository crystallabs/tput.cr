require "./macros"

module Tput
  module Methods

    def _ncoords
      if @x<0
        @x=0
      elsif @x > @cols
        @x = @cols -1
      end
      if @y < 0
        @y = 0
      elsif @y > @rows
        @y = @rows -1
      end
    end

    # TODO: Fix cud and cuu calls.
    def omove(x, y)
      if !@zero_based
        x = (x || 1) - 1
        y = (y || 1) - 1
      else
        x = x || 0
        y = y || 0
      end

      if (y == @y && x == @x)
        return
      end

      if y == @y
        if (x > @x)
          cuf(x - @x)
        elsif (x < @x)
          cub(@x - x)
        end

      elsif x == @x
        if (y > @y)
          cud(y - @y)
        elsif (y < @y)
          cuu(@y - y)
        end

      else
        if !@zero_based
          x+=1
          y+=1
        end
        cup y, x
      end
    end

    def rsetx(x)
      # return h_position_relative(x)
      #if (!x)
      #  return
      #end
      x > 0 ? forward(x) : back(-x)
    end

    def rsety(y)
      # return v_position_relative(y)
      #if (!y)
      #  return
      #end
      y > 0 ? up(y) : down(-y)
    end

    def rmove(x, y)
      rsetx(x)
      rsety(y)
    end

    def simple_insert(str, i, attr)
      _write repeat(str, i), attr
    end

    def repeat(str,i)
      if (!i || i < 0)
        i = 0
      end
      str.to_s * i
    end

    # Specific to iTerm2
    # Example:
    #  unless copy_to_clipboard text
    #    exec_clipboard_program text
    #  end
    def copy_to_clipboard(text)
      if iterm2?
        _twrite "\x1b]50;CopyToCliboard=" + text + "\x07"
        return true
      end
      false
    end

    # Cursor stuff

    # Only XTerm and iTerm2. If you know of any others, post them.
    def cursor_shape(shape, blink)
      if iterm2?
        case shape
          # XXX move to symbols?
          when "block"
            if !blink
              _twrite "\x1b]50;CursorShape=0;BlinkingCursorEnabled=0\x07"
            else
              _twrite "\x1b]50;CursorShape=0;BlinkingCursorEnabled=1\x07"
            end
          when "underline"
            if !blink
              # _twrite "\x1b]50;CursorShape=n;BlinkingCursorEnabled=0\x07"
            else
              # _twrite "\x1b]50;CursorShape=n;BlinkingCursorEnabled=1\x07"
            end
          when "line"
            if !blink
              _twrite "\x1b]50;CursorShape=1;BlinkingCursorEnabled=0\x07"
            else
              _twrite "\x1b]50;CursorShape=1;BlinkingCursorEnabled=1\x07"
            end
        end
        return true

      elsif term?("xterm") || term?("screen")
        case shape
          when "block"
            if !blink
              _twrite "\x1b[0 q"
            else
              _twrite "\x1b[1 q"
            end
          when "underline"
            if !blink
              _twrite "\x1b[2 q"
            else
              _twrite "\x1b[3 q"
            end
          when "line"
            if !blink
              _twrite "\x1b[4 q"
            else
              _twrite "\x1b[5 q"
            end
        end
        return true
      end

      false
    end

    def cursor_color(color)
      if term?("xterm") || term?("rxvt") || term?("screen")
        _twrite("\x1b]12" + color + "\x07")
        return true
      end
      false
    end

    def reset_cursor
      if term?("xterm") || term?("rxvt") || term?("screen")
        # XXX
        # return reset_colors()
        _twrite("\x1b[0 q")
        _twrite("\x1b]112\x07")
        # urxvt doesnt support OSC 112
        _twrite("\x1b]12;white\x07")
        return true
      end
      false
    end
    alias_previous cursor_reset

    # TODO - waiting for functional response()
    # getCursorColor, getTextParams

    ##########

    # Normal

    def nul
      ##if (has('pad')) put "pad"
      _write("\x80")
    end
    #alias_previous pad

    def bell
      (has("bel")) ? (put "bel") : _write("\x07")
    end
    alias_previous bel

    def vtab
      @y+=1
      _ncoords
      _write("\x0b")
    end

    def form
      (has("ff")) ? (put "ff") : _write("\x0c")
    end
    alias_previous ff

    def backspace
      @x-=1
      _ncoords
      (has("kbs")) ? (put "kbs") : _write("\x08")
    end
    alias_previous kbs

    def tab
      @x += 8
      _ncoords
      (has("ht")) ? (put "ht") : _write("\t")
    end
    alias_previous ht

    def shift_out
      # if (has("S2")) return put "S2"
      _write("\x0e")
    end

    def shift_in
      # if (has("S3")) return put "S3"
      _write("\x0f")
    end

    def cr
      @x = 0
      (has("cr")) ? (put "cr") : _write("\r")
    end
    alias_previous carriage_return # TODO can't alias 'return'

    def feed
      if @terminfo && has("eat_newline_glitch") && (@x >= @cols)
        return
      end
      @x = 0
      @y+=1
      _ncoords
      (has("nel")) ? (put "nel") : _write("\n")
    end
    alias_previous nel, newline, line_feed, linefeed, lf

    def crlf
      cr
      lf
    end

    # Esc

    # ESC D Index (IND is 0x84).
    def index
      @y+=1
      _ncoords
      @terminfo ? (put "ind") : _write("\x1bD")
    end
    alias_previous ind

    # ESC M Reverse Index (RI is 0x8d).
    def reverse_index
      @y-=1
      _ncoords
      @terminfo ? (put "ri") : _write("\x1bM")
    end
    alias_previous ri, reverse

    # ESC E Next Line (NEL is 0x85).
    def next_line
      @y+=1
      @x = 0
      _ncoords
      if (has("nel"))
        return put "nel"
      end
      _write("\x1bE")
    end

    # ESC c Full Reset (RIS).
    def reset
      @x = @y = 0
      if has "rs1"
        return put "rs1"
      end
      if has "ris"
        return put "ris"
      end
      _write("\x1bc")
    end

    # ESC H Tab Set (HTS is 0x88).
    def tab_set
      @terminfo ? (put "hts") : _write("\x1bH")
    end

    # ESC 7 Save Cursor (DECSC).
    def save_cursor(key=nil)
      if key
        return lsave_cursor(key)
      end
      @saved_x = @x || 0
      @saved_y = @y || 0
      @terminfo ? (put "sc") : _write("\x1b7")
    end
    alias_previous sc

    # ESC 8 Restore Cursor (DECRC).
    def restore_cursor(key=nil, hide=false)
      if key
        return lrestore_cursor(key, hide)
      end
      @x = @saved_x || 0
      @y = @saved_y || 0
      @terminfo ? (put "rc") : _write("\x1b8")
    end
    alias_previous rc

    # Save Cursor Locally
    def lsave_cursor(key=nil)
      # XXX there is a weird behavior. In functions calling this, if key
      # is not specified, the cursor will be saved to saved_x/saved_y.
      # So theoretically this can't be called without a key. Yet here
      # key is set to 'local' if unspecified. Maybe unify this behavior
      # by getting rid of saved_x/saved_y, and simply saving unnamed
      # positions into 'local'?
      key = key || "local"
      @_saved[key] = { x: @x, y: @y, hidden: @cursor_hidden }
    end

    # Restore Cursor Locally
    def lrestore_cursor(key=nil, hide=false)
      # XXX same note as above
      key = key || "local"
      @_saved[key]?.try do |pos|
        #delete @_saved[key]
        cup(pos[:y], pos[:x])
        if hide && pos[:hidden] != @cursor_hidden
          pos[:hidden] ? hide_cursor : show_cursor
        end
      end
    end

    # ESC # 3 DEC line height/width
    def line_height
      _write "\x1b#"
    end

    # ESC (,),*,+,-,. Designate G0-G2 Character Set.
    #
    # See also:
    # acs_chars / acsc / ac
    # enter_alt_charset_mode / smacs / as
    # exit_alt_charset_mode / rmacs / ae
    # enter_pc_charset_mode / smpch / S2
    # exit_pc_charset_mode / rmpch / S3
    def charset(val, level = 0)

      case (level)
        when 0
          level = '('
        when 1
          level = ')'
        when 2
          level = '*'
        when 3
          level = '+'
      end

      name = val.is_a?(String) ? val.downcase : val.to_s

      case (name)
        when "acs", "scld" # DEC Special Character and Line Drawing Set.
          if @terminfo
            return put "smacs"
          end
          val = '0'
        when "uk" # UK
          val = 'A'
        when "us", "usascii", "ascii" # United States (USASCII).
          if @terminfo
            return put "rmacs"
          end
          val = 'B'
        when "dutch" # Dutch
          val = '4'
        when "finnish" # Finnish
          val = 'C'
          val = '5'
        when "french" # French
          val = 'R'
        when "frenchcanadian" # FrenchCanadian
          val = 'Q'
        when "german"  # German
          val = 'K'
        when "italian" # Italian
          val = 'Y'
        when "norwegiandanish" # NorwegianDanish
          val = 'E'
          val = '6'
        when "spanish" # Spanish
          val = 'Z'
        when "swedish" # Swedish
          val = 'H'
          val = '7'
        when "swiss" # Swiss
          val = '='
        when "isolatin" # ISOLatin (actually /A)
          val = "/A"
        else # Default
          if @terminfo
            return put "rmacs"
          end
          val = "B"
      end

      _write "\x1b(" + val
    end

    def smacs
      charset("acs")
    end
    alias_previous enter_alt_charset_mode #, as # TODO can't alias to 'as'

    def rmacs
      charset("ascii")
    end
    alias_previous exit_alt_charset_mode, ae

    # ESC N
    # Single Shift Select of G2 Character Set
    # ( SS2 is 0x8e). This affects next character only.
    # ESC O
    # Single Shift Select of G3 Character Set
    # ( SS3 is 0x8f). This affects next character only.
    # ESC n
    # Invoke the G2 Character Set as GL (LS2).
    # ESC o
    # Invoke the G3 Character Set as GL (LS3).
    # ESC |
    # Invoke the G3 Character Set as GR (LS3R).
    # ESC }
    # Invoke the G2 Character Set as GR (LS2R).
    # ESC ~
    # Invoke the G1 Character Set as GR (LS1R).
    def set_g(val)
      # if (tput) put.S2()
      # if (tput) put.S3()
      case (val)
        when 1
          val = '~'; # GR
        when 2
          val = 'n'; # GL
          val = '}'; # GR
          val = 'N'; # Next Char Only
        when 3
          val = 'o'; # GL
          val = '|'; # GR
          val = 'O'; # Next Char Only
      end
      _write("\x1b" + val)
    end

    # OSC

    # OSC Ps ; Pt ST
    # OSC Ps ; Pt BEL
    #   Set Text Parameters.
    def title=(title)
      @_title = title

      # if (term?("screen")) {
      #   # Tmux pane
      #   # if (tmux?) {
      #   #   _write "\x1b]2;" + title + "\x1b\\"
      #   # end
      #   _write "\x1bk" + title + "\x1b\\"
      # end
      _twrite "\x1b]0;" + title + "\x07"

      @_title
    end

    # OSC Ps ; Pt ST
    # OSC Ps ; Pt BEL
    #   Reset colors
    def reset_colors(param)
      (has("Cr")) ? (put "Cr", param) : _twrite("\x1b]112\x07")
      #_twrite('\x1b]112;' + param + '\x07')
    end

    # OSC Ps ; Pt ST
    # OSC Ps ; Pt BEL
    #   Change dynamic colors
    def dynamic_colors(param)
      (has("Cs")) ? (put "Cs", param) : _twrite("\x1b]12;" + param + "\x07")
    end

    # OSC Ps ; Pt ST
    # OSC Ps ; Pt BEL
    #   Sel data
    def sel_data(a,b)
      (has("Ms")) ? (put "ms", a, b) : _twrite("\x1b]52;" + a + ';' + b.to_s + "\x07")
    end

    # CSI

    # CSI Ps A
    # Cursor Up Ps Times (default = 1) (CUU).
    def cursor_up(param=1)
      @y -= param
      _ncoords
      if @terminfo
        if !has("parm_up_cursor")
          return _write(repeat(@methods.call("cuu1", NO_ARGS), param))
        end
        return put "cuu", param
      end
      _write("\x1b[" + param + "A")
    end
    alias_previous cuu, up

    # CSI Ps B
    # Cursor Down Ps Times (default = 1) (CUD).
    def cursor_down(param = 1)
      @y += param
      _ncoords
      if @terminfo
        if !has("parm_down_cursor")
          return _write(repeat(@methods.call("cud1", NO_ARGS), param))
        end
        return put "cud", param
      end
      _write("\x1b[" + param + "B")
    end
    alias_previous cud, down

    # CSI Ps C
    # Cursor Forward Ps Times (default = 1) (CUF).
    def cursor_forward(param=1)
      @x += param
      _ncoords
      if @terminfo
        if !has("parm_right_cursor")
          return _write(repeat(@methods.call("cuf1", NO_ARGS), param))
        end
        return put "cuf", param
      end
      _write("\x1b[" + param + "C")
    end
    alias_previous cuf, right, forward

    # CSI Ps D
    # Cursor Backward Ps Times (default = 1) (CUB).
    def cursor_backward(param)
      @x -= param || 1
      _ncoords
      if @terminfo
        if !has("parm_left_cursor")
          return _write(repeat(@methods.call("cub1", NO_ARGS), param))
        end
        return put "cub", param
      end
      _write("\x1b[" + (param || "").to_s + "D")
    end
    alias_previous cub, left, back

    # CSI Ps ; Ps H
    # Cursor Position [row;column] (default = [1,1]) (CUP).
    def cursor_pos(row,col)
      if (!@zero_based)
        row = (row || 1) - 1
        col = (col || 1) - 1
      else
        row = row || 0
        col = col || 0
      end
      @x = col
      @y = row
      _ncoords

      @terminfo ? (put "cup", row, col) :
        _write("\x1b[" + (row + 1).to_s + ";" + (col + 1).to_s + "H")
    end
    alias_previous cup, pos, cursor_address, setxy, move

    # CSI Ps J  Erase in Display (ED).
    #     Ps = 0  -> Erase Below (default).
    #     Ps = 1  -> Erase Above.
    #     Ps = 2  -> Erase All.
    #     Ps = 3  -> Erase Saved Lines (xterm).
    # CSI ? Ps J
    #   Erase in Display (DECSED).
    #     Ps = 0  -> Selective Erase Below (default).
    #     Ps = 1  -> Selective Erase Above.
    #     Ps = 2  -> Selective Erase All.
    def erase_in_display(param)
      if @terminfo
        case param
          when "above"
            param = 1
          when "all"
            param = 2
          when "saved"
            param = 3
          when "below"
            param = 0
          else
            param = 0
        end
        # extended tput.E3 = ^[[3;J
        return put "ed", param
      end
      case param
        when "above"
          _write("\X1b[1J")
        when "all"
          _write("\x1b[2J")
        when "saved"
          _write("\x1b[3J")
        when "below"
          _write("\x1b[J")
        else
          _write("\x1b[J")
      end
    end
    alias_previous ed

    def clear
      @x = 0
      @y = 0
      @terminfo ? (put "clear") : _write("\x1b[H\x1b[J")
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
      if @terminfo
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
        put "el", param
      end
      case (param)
        when "left"
          _write("\x1b[1K")
        when "all"
          _write("\x1b[2K")
        when "right"
          _write("\x1b[K")
        else
          _write("\x1b[K")
      end
    end
    alias_previous el

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

    #   If xterm is compiled with the 16-color support disabled, it
    #   supports the following, from rxvt:
    #     Ps = 1 0 0  -> Set foreground and background color to
    #     default.

    #   If 88- or 256-color support is compiled, the following apply.
    #     Ps = 3 8  ; 5  ; Ps -> Set foreground color to the second
    #     Ps.
    #     Ps = 4 8  ; 5  ; Ps -> Set background color to the second
    #     Ps.
    def char_attributes(param,val)
      _write(_attr(param, val))
    end
    alias_previous sgr, attr

    def text(text,attr)
      _attr(attr, true) + text + _attr(attr, false)
    end

    # NOTE: sun-color may not allow multiple params for SGR.
    # XXX see if these attributes can somehow be combined with
    # Crystal's functionality in Colorize
    def _attr(param : Array | String, val = nil)
      parts = [] of String
      color = nil
      m = nil

      if param.is_a? Array
        parts = param
        param = parts[0] || "normal"
      else
        param = param || "normal"
        parts = param.split(/\s*[,;]\s*/)
      end

      if parts.size > 1
        used = {} of String => Bool
        out = [] of String

        parts.each do |part|
          part = (_attr(part, val) || "")[2..]
          break if part == ""
          break if used[part]
          used[part] = true
          out.push part
        end

        return "\x1b[" + out.join(";") + "m"
      end

      if param.index("no ") == 0
        param = param[3..]
        val = false
      elsif param.index("!") == 0
        param = param[1..]
        val = false
      end

      case param
        # attributes
        when "normal", "default"
          return "" if val == false
          return "\x1b[m"
        when "bold"
          return val == false ? "\x1b[22m" : "\x1b[1m"
        when "ul", "underline", "underlined"
          return val == false ? "\x1b[24m" : "\x1b[4m"
        when "blink"
          return val == false ? "\x1b[25m" : "\x1b[5m"
        when "inverse"
          return val == false ? "\x1b[27m" : "\x1b[7m"
        when "invisible"
          return val == false ? "\x1b[28m" : "\x1b[8m"

        # 8-color foreground
        when "black fg"
          return val == false ? "\x1b[39m" : "\x1b[30m"
        when "red fg"
          return val == false ? "\x1b[39m" : "\x1b[31m"
        when "green fg"
          return val == false ? "\x1b[39m" : "\x1b[32m"
        when "yellow fg"
          return val == false ? "\x1b[39m" : "\x1b[33m"
        when "blue fg"
          return val == false ? "\x1b[39m" : "\x1b[34m"
        when "magenta fg"
          return val == false ? "\x1b[39m" : "\x1b[35m"
        when "cyan fg"
          return val == false ? "\x1b[39m" : "\x1b[36m"
        when "white fg", "light grey fg", "light gray fg", "bright grey fg", "bright gray fg"
          return val == false ? "\x1b[39m" : "\x1b[37m"
        when "default fg"
          return "" if val == false
          return "\x1b[39m"

        # 8-color background
        when "black bg"
          return val == false ? "\x1b[49m" : "\x1b[40m"
        when "red bg"
          return val == false ? "\x1b[49m" : "\x1b[41m"
        when "green bg"
          return val == false ? "\x1b[49m" : "\x1b[42m"
        when "yellow bg"
          return val == false ? "\x1b[49m" : "\x1b[43m"
        when "blue bg"
          return val == false ? "\x1b[49m" : "\x1b[44m"
        when "magenta bg"
          return val == false ? "\x1b[49m" : "\x1b[45m"
        when "cyan bg"
          return val == false ? "\x1b[49m" : "\x1b[46m"
        when "white bg", "light grey bg", "light gray bg", "bright grey bg", "bright gray bg"
          return val == false ? "\x1b[49m" : "\x1b[47m"
        when "default bg"
          return "" if val == false
          return "\x1b[49m"

        # 16-color foreground
        when "light black fg", "bright black fg", "grey fg", "gray fg"
          return val == false ? "\x1b[39m" : "\x1b[90m"
        when "light red fg", "bright red fg"
          return val == false ? "\x1b[39m" : "\x1b[91m"
        when "light green fg", "bright green fg"
          return val == false ? "\x1b[39m" : "\x1b[92m"
        when "light yellow fg", "bright yellow fg"
          return val == false ? "\x1b[39m" : "\x1b[93m"
        when "light blue fg", "bright blue fg"
          return val == false ? "\x1b[39m" : "\x1b[94m"
        when "light magenta fg", "bright magenta fg"
          return val == false ? "\x1b[39m" : "\x1b[95m"
        when "light cyan fg", "bright cyan fg"
          return val == false ? "\x1b[39m" : "\x1b[96m"
        when "light white fg", "bright white fg"
          return val == false ? "\x1b[39m" : "\x1b[97m"

        # 16-color background
        when "light black bg", "bright black bg", "grey bg", "gray bg"
          return val == false ? "\x1b[49m" : "\x1b[100m"
        when "light red bg", "bright red bg"
          return val == false ? "\x1b[49m" : "\x1b[101m"
        when "light green bg", "bright green bg"
          return val == false ? "\x1b[49m" : "\x1b[102m"
        when "light yellow bg", "bright yellow bg"
          return val == false ? "\x1b[49m" : "\x1b[103m"
        when "light blue bg", "bright blue bg"
          return val == false ? "\x1b[49m" : "\x1b[104m"
        when "light magenta bg", "bright magenta bg"
          return val == false ? "\x1b[49m" : "\x1b[105m"
        when "light cyan bg", "bright cyan bg"
          return val == false ? "\x1b[49m" : "\x1b[106m"
        when "light white bg", "bright white bg"
          return val == false ? "\x1b[49m" : "\x1b[107m"

        # non-16-color rxvt default fg and bg
        when "default fg bg"
          return "" if val == false
          return term?("rxvt") ? "\x1b[100m" : "\x1b[39;49m"

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

            if val == false || color == -1
              return _attr "default " + m[2]
            end

            # TODO
            #color = ::Crysterm::Colors.reduce(color, @tput.colors)

            if color < 16 # TODO || (@tput && @tput.colors <= 16)
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
              return "\x1b[" + color.to_s + "m"
            end

            if m[2] == "fg"
              return "\x1b[38;5;" + color.to_s + "m"
            end

            if m[2] == "bg"
              return "\x1b[48;5;" + color.to_s + "m"
            end
          end

          if /^[\d;]*$/.match param
            return "\x1b[" + param + "m"
          end

          return
      end
    end

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

    # TODO
    # deviceStatus
    # restoreReportedCursor

    #
    # Additions
    #

    # CSI Ps @
    # Insert Ps (Blank) Character(s) (default = 1) (ICH).
    def insert_chars(param=1)
      @x += param
      _ncoords
      @terminfo ? put("ich", param) : _write("\x1b[" + param.to_s + '@')
    end
    alias_previous ich

    # CSI Ps E
    # Cursor Next Line Ps Times (default = 1) (CNL).
    # same as CSI Ps B ?
    def cursor_next_line(param)
      @y += param || 1
      _ncoords
      _write("\x1b[" + param.to_s + 'E')
    end
    alias_previous cnl

    # CSI Ps F
    # Cursor Preceding Line Ps Times (default = 1) (CNL).
    # reuse CSI Ps A ?
    def cursor_preceding_line(param)
      @y -= param || 1
      _ncoords
      _write("\x1b[" + param.to_s + 'F')
    end
    alias_previous cpl

    # CSI Ps G
    # Cursor Character Absolute  [column] (default = [row,1]) (CHA).
    def cursor_char_absolute(param)
      if !@zero_based
        param = (param || 1) - 1
      else
        param = param || 0
      end

      @x = param
      #@y = 0 # Bug in blessed
      _ncoords

      @terminfo ? put("hpa", param) : _write("\x1b[" + (param + 1).to_s + 'G')
    end
    alias_previous cha, setx

    # CSI Ps L
    # Insert Ps Line(s) (default = 1) (IL).
    def insert_lines(param)
      @terminfo ? put("il", param) : _write("\x1b[" + param.to_s + 'L')
    end
    alias_previous il

    # CSI Ps M
    # Delete Ps Line(s) (default = 1) (DL).
    def delete_lines(param)
      @terminfo ? put("dl", param) : _write("\x1b[" + param.to_s + 'M')
    end
    alias_previous dl

    # CSI Ps P
    # Delete Ps Character(s) (default = 1) (DCH).
    def delete_chars(param)
      @terminfo ? put("dch", param) : _write("\x1b[" + param.to_s + 'P')
    end
    alias_previous dch

    # CSI Ps X
    # Erase Ps Character(s) (default = 1) (ECH).
    def erase_chars(param)
      @terminfo ? put("ech", param) : _write("\x1b[" + param.to_s + 'X')
    end
    alias_previous ech

    # CSI Pm `  Character Position Absolute
    #   [column] (default = [row,1]) (HPA).
    def char_pos_absolute(param=nil)
      @x = param || 0
      _ncoords

      # XXX not applicable when we only accept param
      #param = arguments.join ';'
      @terminfo ? (put "hpa", param) : _write("\x1b[" + param.to_s + '`')
    end
    alias_previous hpa

    # 141 61 a * HPR -
    # Horizontal Position Relative
    # reuse CSI Ps C ?
    def h_position_relative(param=1)
      if (@terminfo)
        return cuf(param)
      end

      @x += param
      _ncoords
      # Does not exist:
      # if (@terminfo) return put "hpr", param
      _write("\x1b[" + param.to_s + 'a')
    end
    alias_previous hpr

    # TODO
    #def send_device_attributes(param, callback)

    # CSI Pm d
    # Line Position Absolute  [row] (default = [1,column]) (VPA).
    # NOTE: Can't find in terminfo, no idea why it has multiple params.
    def line_pos_absolute(param=1)
      @y = param
      _ncoords()
      @terminfo ? put("vpa", param) : _write("\x1b[" + param.to_s + 'G')
    end
    alias_previous vpa, sety

    # 145 65 e * VPR - Vertical Position Relative
    # reuse CSI Ps B ?
    def v_position_relative(param=1)
      return cud(param) if @terminfo

      @y += param
      _ncoords

      # Does not exist:
      # if (@terminfo) return put "vpr", param
      _write("\x1b[" + param.to_s + 'e')
    end
    alias_previous vpr

    # CSI Ps ; Ps f
    #   Horizontal and Vertical Position [row;column] (default =
    #   [1,1]) (HVP).
    def hv_position(row, col)
      if !@zero_based
        row = (row || 1) - 1
        col = (col || 1) - 1
      else
        row = row || 0
        col = col || 0
      end
      @y = row
      @x = col
      _ncoords
      # Does not exist (?):
      # @terminfo ? (put "hvp", row, col);
      @terminfo ? (put "cup", row, col) :
        _write("\x1b[" + (row + 1).to_s + ';' + (col + 1).to_s + 'f')
    end
    alias_previous hvp


    # CSI Pm h  Set Mode (SM).
    #     Ps = 2  -> Keyboard Action Mode (AM).
    #     Ps = 4  -> Insert Mode (IRM).
    #     Ps = 1 2  -> Send/receive (SRM).
    #     Ps = 2 0  -> Automatic Newline (LNM).
    # CSI ? Pm h
    #   DEC Private Mode Set (DECSET).
    #     Ps = 1  -> Application Cursor Keys (DECCKM).
    #     Ps = 2  -> Designate USASCII for character sets G0-G3
    #     (DECANM), and set VT100 mode.
    #     Ps = 3  -> 132 Column Mode (DECCOLM).
    #     Ps = 4  -> Smooth (Slow) Scroll (DECSCLM).
    #     Ps = 5  -> Reverse Video (DECSCNM).
    #     Ps = 6  -> Origin Mode (DECOM).
    #     Ps = 7  -> Wraparound Mode (DECAWM).
    #     Ps = 8  -> Auto-repeat Keys (DECARM).
    #     Ps = 9  -> Send Mouse X & Y on button press.  See the sec-
    #     tion Mouse Tracking.
    #     Ps = 1 0  -> Show toolbar (rxvt).
    #     Ps = 1 2  -> Start Blinking Cursor (att610).
    #     Ps = 1 8  -> Print form feed (DECPFF).
    #     Ps = 1 9  -> Set print extent to full screen (DECPEX).
    #     Ps = 2 5  -> Show Cursor (DECTCEM).
    #     Ps = 3 0  -> Show scrollbar (rxvt).
    #     Ps = 3 5  -> Enable font-shifting functions (rxvt).
    #     Ps = 3 8  -> Enter Tektronix Mode (DECTEK).
    #     Ps = 4 0  -> Allow 80 -> 132 Mode.
    #     Ps = 4 1  -> more(1) fix (see curses resource).
    #     Ps = 4 2  -> Enable Nation Replacement Character sets (DECN-
    #     RCM).
    #     Ps = 4 4  -> Turn On Margin Bell.
    #     Ps = 4 5  -> Reverse-wraparound Mode.
    #     Ps = 4 6  -> Start Logging.  This is normally disabled by a
    #     compile-time option.
    #     Ps = 4 7  -> Use Alternate Screen Buffer.  (This may be dis-
    #     abled by the titeInhibit resource).
    #     Ps = 6 6  -> Application keypad (DECNKM).
    #     Ps = 6 7  -> Backarrow key sends backspace (DECBKM).
    #     Ps = 1 0 0 0  -> Send Mouse X & Y on button press and
    #     release.  See the section Mouse Tracking.
    #     Ps = 1 0 0 1  -> Use Hilite Mouse Tracking.
    #     Ps = 1 0 0 2  -> Use Cell Motion Mouse Tracking.
    #     Ps = 1 0 0 3  -> Use All Motion Mouse Tracking.
    #     Ps = 1 0 0 4  -> Send FocusIn/FocusOut events.
    #     Ps = 1 0 0 5  -> Enable Extended Mouse Mode.
    #     Ps = 1 0 1 0  -> Scroll to bottom on tty output (rxvt).
    #     Ps = 1 0 1 1  -> Scroll to bottom on key press (rxvt).
    #     Ps = 1 0 3 4  -> Interpret "meta" key, sets eighth bit.
    #     (enables the eightBitInput resource).
    #     Ps = 1 0 3 5  -> Enable special modifiers for Alt and Num-
    #     Lock keys.  (This enables the numLock resource).
    #     Ps = 1 0 3 6  -> Send ESC   when Meta modifies a key.  (This
    #     enables the metaSendsEscape resource).
    #     Ps = 1 0 3 7  -> Send DEL from the editing-keypad Delete
    #     key.
    #     Ps = 1 0 3 9  -> Send ESC  when Alt modifies a key.  (This
    #     enables the altSendsEscape resource).
    #     Ps = 1 0 4 0  -> Keep selection even if not highlighted.
    #     (This enables the keepSelection resource).
    #     Ps = 1 0 4 1  -> Use the CLIPBOARD selection.  (This enables
    #     the selectToClipboard resource).
    #     Ps = 1 0 4 2  -> Enable Urgency window manager hint when
    #     Control-G is received.  (This enables the bellIsUrgent
    #     resource).
    #     Ps = 1 0 4 3  -> Enable raising of the window when Control-G
    #     is received.  (enables the popOnBell resource).
    #     Ps = 1 0 4 7  -> Use Alternate Screen Buffer.  (This may be
    #     disabled by the titeInhibit resource).
    #     Ps = 1 0 4 8  -> Save cursor as in DECSC.  (This may be dis-
    #     abled by the titeInhibit resource).
    #     Ps = 1 0 4 9  -> Save cursor as in DECSC and use Alternate
    #     Screen Buffer, clearing it first.  (This may be disabled by
    #     the titeInhibit resource).  This combines the effects of the 1
    #     0 4 7  and 1 0 4 8  modes.  Use this with terminfo-based
    #     applications rather than the 4 7  mode.
    #     Ps = 1 0 5 0  -> Set terminfo/termcap function-key mode.
    #     Ps = 1 0 5 1  -> Set Sun function-key mode.
    #     Ps = 1 0 5 2  -> Set HP function-key mode.
    #     Ps = 1 0 5 3  -> Set SCO function-key mode.
    #     Ps = 1 0 6 0  -> Set legacy keyboard emulation (X11R6).
    #     Ps = 1 0 6 1  -> Set VT220 keyboard emulation.
    #     Ps = 2 0 0 4  -> Set bracketed paste mode.
    # Modes:
    #   http://vt100.net/docs/vt220-rm/chapter4.html
    def set_mode(*arguments)
      param = arguments.join ';'
      _write "\x1b[" + param + 'h'
    end
    alias_previous sm

    def restore_reported_cursor
      @_rx.try do |rx|
        @_ry.try do |ry|
          cup ry, rx
          # return put "nel"
        end
      end
    end

    # TODO sendDeviceAttributes

    def decset(*arguments)
      param = arguments.join ';'
      set_mode "?" + param
    end

    def show_cursor
      @cursor_hidden = false
      # NOTE: In xterm terminfo:
      # cnorm stops blinking cursor
      # cvvis starts blinking cursor
      #if (@terminfo) return put "cvvis"
      # return _write("\x1b[?12l\x1b[?25h"); // cursor_normal
      # return _write("\x1b[?12;25h"); // cursor_visible
      @terminfo ? return(put "cnorm") : set_mode "?25"
    end
    alias_previous dectcem, cnorm, cvvis

    def alternate_buffer
      @alt_screen = true

      return(put "smcup") if @terminfo

      return if term?("vt") || term?("linux")

      set_mode "?47"
      set_mode "?1049"
    end
    alias_previous smcup, alternate

    # CSI Pm l  Reset Mode (RM).
    #     Ps = 2  -> Keyboard Action Mode (AM).
    #     Ps = 4  -> Replace Mode (IRM).
    #     Ps = 1 2  -> Send/receive (SRM).
    #     Ps = 2 0  -> Normal Linefeed (LNM).
    # CSI ? Pm l
    #   DEC Private Mode Reset (DECRST).
    #     Ps = 1  -> Normal Cursor Keys (DECCKM).
    #     Ps = 2  -> Designate VT52 mode (DECANM).
    #     Ps = 3  -> 80 Column Mode (DECCOLM).
    #     Ps = 4  -> Jump (Fast) Scroll (DECSCLM).
    #     Ps = 5  -> Normal Video (DECSCNM).
    #     Ps = 6  -> Normal Cursor Mode (DECOM).
    #     Ps = 7  -> No Wraparound Mode (DECAWM).
    #     Ps = 8  -> No Auto-repeat Keys (DECARM).
    #     Ps = 9  -> Don't send Mouse X & Y on button press.
    #     Ps = 1 0  -> Hide toolbar (rxvt).
    #     Ps = 1 2  -> Stop Blinking Cursor (att610).
    #     Ps = 1 8  -> Don't print form feed (DECPFF).
    #     Ps = 1 9  -> Limit print to scrolling region (DECPEX).
    #     Ps = 2 5  -> Hide Cursor (DECTCEM).
    #     Ps = 3 0  -> Don't show scrollbar (rxvt).
    #     Ps = 3 5  -> Disable font-shifting functions (rxvt).
    #     Ps = 4 0  -> Disallow 80 -> 132 Mode.
    #     Ps = 4 1  -> No more(1) fix (see curses resource).
    #     Ps = 4 2  -> Disable Nation Replacement Character sets (DEC-
    #     NRCM).
    #     Ps = 4 4  -> Turn Off Margin Bell.
    #     Ps = 4 5  -> No Reverse-wraparound Mode.
    #     Ps = 4 6  -> Stop Logging.  (This is normally disabled by a
    #     compile-time option).
    #     Ps = 4 7  -> Use Normal Screen Buffer.
    #     Ps = 6 6  -> Numeric keypad (DECNKM).
    #     Ps = 6 7  -> Backarrow key sends delete (DECBKM).
    #     Ps = 1 0 0 0  -> Don't send Mouse X & Y on button press and
    #     release.  See the section Mouse Tracking.
    #     Ps = 1 0 0 1  -> Don't use Hilite Mouse Tracking.
    #     Ps = 1 0 0 2  -> Don't use Cell Motion Mouse Tracking.
    #     Ps = 1 0 0 3  -> Don't use All Motion Mouse Tracking.
    #     Ps = 1 0 0 4  -> Don't send FocusIn/FocusOut events.
    #     Ps = 1 0 0 5  -> Disable Extended Mouse Mode.
    #     Ps = 1 0 1 0  -> Don't scroll to bottom on tty output
    #     (rxvt).
    #     Ps = 1 0 1 1  -> Don't scroll to bottom on key press (rxvt).
    #     Ps = 1 0 3 4  -> Don't interpret "meta" key.  (This disables
    #     the eightBitInput resource).
    #     Ps = 1 0 3 5  -> Disable special modifiers for Alt and Num-
    #     Lock keys.  (This disables the numLock resource).
    #     Ps = 1 0 3 6  -> Don't send ESC  when Meta modifies a key.
    #     (This disables the metaSendsEscape resource).
    #     Ps = 1 0 3 7  -> Send VT220 Remove from the editing-keypad
    #     Delete key.
    #     Ps = 1 0 3 9  -> Don't send ESC  when Alt modifies a key.
    #     (This disables the altSendsEscape resource).
    #     Ps = 1 0 4 0  -> Do not keep selection when not highlighted.
    #     (This disables the keepSelection resource).
    #     Ps = 1 0 4 1  -> Use the PRIMARY selection.  (This disables
    #     the selectToClipboard resource).
    #     Ps = 1 0 4 2  -> Disable Urgency window manager hint when
    #     Control-G is received.  (This disables the bellIsUrgent
    #     resource).
    #     Ps = 1 0 4 3  -> Disable raising of the window when Control-
    #     G is received.  (This disables the popOnBell resource).
    #     Ps = 1 0 4 7  -> Use Normal Screen Buffer, clearing screen
    #     first if in the Alternate Screen.  (This may be disabled by
    #     the titeInhibit resource).
    #     Ps = 1 0 4 8  -> Restore cursor as in DECRC.  (This may be
    #     disabled by the titeInhibit resource).
    #     Ps = 1 0 4 9  -> Use Normal Screen Buffer and restore cursor
    #     as in DECRC.  (This may be disabled by the titeInhibit
    #     resource).  This combines the effects of the 1 0 4 7  and 1 0
    #     4 8  modes.  Use this with terminfo-based applications rather
    #     than the 4 7  mode.
    #     Ps = 1 0 5 0  -> Reset terminfo/termcap function-key mode.
    #     Ps = 1 0 5 1  -> Reset Sun function-key mode.
    #     Ps = 1 0 5 2  -> Reset HP function-key mode.
    #     Ps = 1 0 5 3  -> Reset SCO function-key mode.
    #     Ps = 1 0 6 0  -> Reset legacy keyboard emulation (X11R6).
    #     Ps = 1 0 6 1  -> Reset keyboard emulation to Sun/PC style.
    #     Ps = 2 0 0 4  -> Reset bracketed paste mode.
    def reset_mode(*arguments)
      param = arguments.join ';'
      _write "\x1b[" + param + 'l'
    end
    alias_previous rm

    def decrst(*arguments)
      param = arguments.join ';'
      reset_mode "?" + param
    end

    def hide_cursor
      @cursor_hidden = true
      @terminfo ? (put "civis") : (reset_mode "?25")
    end
    alias_previous dectcemh, cursor_invisible, vi, civis

    def normal_buffer
      @alt_screen = false
      return(put "rmcup") if @terminfo

      reset_mode "?47"
      reset_mode "?1049"
    end
    alias_previous rmcup

    # CSI Ps ; Ps r
    #   Set Scrolling Region [top;bottom] (default = full size of win-
    #   dow) (DECSTBM).
    # CSI ? Pm r
    def set_scroll_region(top, bottom)
      if (!@zero_based)
        top = (top || 1) - 1
        bottom = (bottom || @rows) - 1
      else
        top = top || 0
        bottom = bottom || (@rows - 1)
      end
      @scroll_top = top
      @scroll_bottom = bottom
      @x = 0
      @y = 0
      _ncoords
      @terminfo ? (put "csr", top, bottom) :
        _write("\x1b[" + (top + 1).to_s + ';' + (bottom + 1).to_s + 'r')
    end
    alias_previous decstbm, csr

    # CSI s
    #   Save cursor (ANSI.SYS).
    def save_cursor_a
      @saved_x = @x
      @saved_y = @y
      @terminfo ? (put "sc") : _write("\x1b[s")
    end
    alias_previous sc_a

    # CSI u
    #   Restore cursor (ANSI.SYS).
    def restore_cursor_a
      @x = @saved_x || 0
      @y = @saved_y || 0
      @terminfo ? (put "rc") : _write("\x1b[u")
    end
    alias_previous rc_a

    #
    # List of less used ones:
    #

    # CSI Ps I
    #   Cursor Forward Tabulation Ps tab stops (default = 1) (CHT).
    # TODO ability to control tab width
    def cursor_forward_tab(param=1)
      @x += 8
      _ncoords
      @terminfo ? (put "tab", param) : _write("\x1b[" + param.to_s + 'I')
    end
    alias_previous cht

    # CSI Ps S  Scroll up Ps lines (default = 1) (SU).
    def scroll_up(param=1)
      @y -= param
      _ncoords
      @terminfo ? (put "parm_index", param) : _write("\x1b[" + param.to_s + 'S')
    end
    alias_previous su

    # CSI Ps T  Scroll down Ps lines (default = 1) (SD).
    def scroll_down(param=1)
      @y += param
      _ncoords
      @terminfo ? (put "parm_rindex", param) : _write("\x1b[" + param.to_s + 'T')
    end
    alias_previous sd

    # CSI > Ps; Ps T
    #   Reset one or more features of the title modes to the default
    #   value.  Normally, "reset" disables the feature.  It is possi-
    #   ble to disable the ability to reset features by compiling a
    #   different default for the title modes into xterm.
    #     Ps = 0  -> Do not set window/icon labels using hexadecimal.
    #     Ps = 1  -> Do not query window/icon labels using hexadeci-
    #     mal.
    #     Ps = 2  -> Do not set window/icon labels using UTF-8.
    #     Ps = 3  -> Do not query window/icon labels using UTF-8.
    #   (See discussion of "Title Modes").
    def reset_title_modes(*arguments)
      _write("\x1b[>" + arguments.join(';') + 'T')
    end

    # CSI Ps Z  Cursor Backward Tabulation Ps tab stops (default = 1) (CBT).
    # TODO ability to control tab width
    def cursor_backward_tab(param=1)
      @x -= 8
      _ncoords
      @terminfo ? (put "cbt", param) : _write("\x1b[" + param.to_s + 'Z')
    end
    alias_previous cbt

    # CSI Ps b  Repeat the preceding graphic character Ps times (REP).
    def repeat_preceding_character(param=1)
      @x += param
      _ncoords
      @terminfo ? (put "rep", param) : _write("\x1b[" + param.to_s + 'b')
    end
    alias_previous rep

    # CSI Ps g  Tab Clear (TBC).
    #     Ps = 0  -> Clear Current Column (default).
    #     Ps = 3  -> Clear All.
    # Potentially:
    #   Ps = 2  -> Clear Stops on Line.
    #   http:#vt100.net/annarbor/aaa-ug/section6.html
    def tab_clear(param=0)
      @terminfo ? put("tbc", param) : _write("\x1b[" + param.to_s + 'g')
    end
    alias_previous tbc

    # CSI Pm i  Media Copy (MC).
    #     Ps = 0  -> Print screen (default).
    #     Ps = 4  -> Turn off printer controller mode.
    #     Ps = 5  -> Turn on printer controller mode.
    # CSI ? Pm i
    #   Media Copy (MC, DEC-specific).
    #     Ps = 1  -> Print line containing cursor.
    #     Ps = 4  -> Turn off autoprint mode.
    #     Ps = 5  -> Turn on autoprint mode.
    #     Ps = 1  0  -> Print composed display, ignores DECPEX.
    #     Ps = 1  1  -> Print all pages.
    def media_copy(*arguments)
      _write "\x1b[" + arguments.join(';') + 'i'
    end
    alias_previous mc

    def mc0
      @terminfo ? (put "mc0") : mc("0")
    end
    alias_previous print_screen, ps

    def mc5
      @terminfo ? (put "mc5") : mc("5")
    end
    alias_previous prtr_on, po

    def mc4
      @terminfo ? (put "mc4") : mc("4")
    end
    alias_previous prtr_off, pf

    def mc5p
      @terminfo ? (put "mc5p") : mc("?5")
    end
    alias_previous prtr_non, pO

    # CSI > Ps; Ps m
    #   Set or reset resource-values used by xterm to decide whether
    #   to construct escape sequences holding information about the
    #   modifiers pressed with a given key.  The first parameter iden-
    #   tifies the resource to set/reset.  The second parameter is the
    #   value to assign to the resource.  If the second parameter is
    #   omitted, the resource is reset to its initial value.
    #     Ps = 1  -> modifyCursorKeys.
    #     Ps = 2  -> modifyFunctionKeys.
    #     Ps = 4  -> modifyOtherKeys.
    #   If no parameters are given, all resources are reset to their
    #   initial values.
    def set_resources(*arguments)
      _write("\x1b[>" + arguments.join(';') + 'm')
    end

    # CSI > Ps n
    #   Disable modifiers which may be enabled via the CSI > Ps; Ps m
    #   sequence.  This corresponds to a resource value of "-1", which
    #   cannot be set with the other sequence.  The parameter identi-
    #   fies the resource to be disabled:
    #     Ps = 1  -> modifyCursorKeys.
    #     Ps = 2  -> modifyFunctionKeys.
    #     Ps = 4  -> modifyOtherKeys.
    #   If the parameter is omitted, modifyFunctionKeys is disabled.
    #   When modifyFunctionKeys is disabled, xterm uses the modifier
    #   keys to make an extended sequence of functions rather than
    #   adding a parameter to each function key to denote the modi-
    #   fiers.
    def disable_modifiers(param=nil)
      _write("\x1b[>" + param.to_s + 'n')
    end

    # CSI > Ps p
    #   Set resource value pointerMode.  This is used by xterm to
    #   decide whether to hide the pointer cursor as the user types.
    #   Valid values for the parameter:
    #     Ps = 0  -> never hide the pointer.
    #     Ps = 1  -> hide if the mouse tracking mode is not enabled.
    #     Ps = 2  -> always hide the pointer.  If no parameter is
    #     given, xterm uses the default, which is 1 .
    def set_pointer_mode(param=nil)
      _write("\x1b[>" + param.to_s + 'p')
    end

    # CSI ! p   Soft terminal reset (DECSTR).
    # http:#vt100.net/docs/vt220-rm/table4-10.html
    def soft_reset
      #if (tput) put.init_2string()
      #if (tput) put.reset_2string()
      @terminfo ? (put "rs2") :
      #_write('\x1b[!p')
      #_write('\x1b[!p\x1b[?3;4l\x1b[4l\x1b>') # init
      _write("\x1b[!p\x1b[?3;4l\x1b[4l\x1b>") # reset
    end
    alias_previous decstr, rs2

    # CSI Ps$ p
    #   Request ANSI mode (DECRQM).  For VT300 and up, reply is
    #     CSI Ps; Pm$ y
    #   where Ps is the mode number as in RM, and Pm is the mode
    #   value:
    #     0 - not recognized
    #     1 - set
    #     2 - reset
    #     3 - permanently set
    #     4 - permanently reset
    def request_ansi_mode(param=nil)
      _write("\x1b[" + param.to_s + "$p")
    end
    alias_previous decrqm

    # CSI ? Ps$ p
    #   Request DEC private mode (DECRQM).  For VT300 and up, reply is
    #     CSI ? Ps; Pm$ p
    #   where Ps is the mode number as in DECSET, Pm is the mode value
    #   as in the ANSI DECRQM.
    def request_private_mode(param=nil)
      _write("\x1b[?" + param.to_s + "$p")
    end
    alias_previous decrqmp

    # CSI Ps ; Ps " p
    #   Set conformance level (DECSCL).  Valid values for the first
    #   parameter:
    #     Ps = 6 1  -> VT100.
    #     Ps = 6 2  -> VT200.
    #     Ps = 6 3  -> VT300.
    #   Valid values for the second parameter:
    #     Ps = 0  -> 8-bit controls.
    #     Ps = 1  -> 7-bit controls (always set for VT100).
    #     Ps = 2  -> 8-bit controls.
    def set_conformance_level(*arguments)
      _write("\x1b[" + arguments.join(';') + "\"p")
    end
    alias_previous decscl

    # CSI Ps q  Load LEDs (DECLL).
    #     Ps = 0  -> Clear all LEDS (default).
    #     Ps = 1  -> Light Num Lock.
    #     Ps = 2  -> Light Caps Lock.
    #     Ps = 3  -> Light Scroll Lock.
    #     Ps = 2  1  -> Extinguish Num Lock.
    #     Ps = 2  2  -> Extinguish Caps Lock.
    #     Ps = 2  3  -> Extinguish Scroll Lock.
    def load_leds(param=nil)
      _write("\x1b[" + param.to_s + 'q')
    end
    alias_previous decll

    # CSI Ps SP q
    #   Set cursor style (DECSCUSR, VT520).
    #     Ps = 0  -> blinking block.
    #     Ps = 1  -> blinking block (default).
    #     Ps = 2  -> steady block.
    #     Ps = 3  -> blinking underline.
    #     Ps = 4  -> steady underline.
    def set_cursor_style(param=1)
      case param
        when "blinking block"
          param = 1
        when "block", "steady block"
          param = 2
        when "blinking underline"
          param = 3
        when "underline", "steady underline"
          param = 4
        when "blinking bar"
          param = 5
        when "bar", "steady bar"
          param = 6
      end

      if (param == 2 && has("Se"))
        return put "Se"
      elsif has "Ss"
        return put "Ss", param
      end

      _write("\x1b[" + param.to_s + " q")
    end
    alias_previous decscusr

    # CSI Ps " q
    #   Select character protection attribute (DECSCA).  Valid values
    #   for the parameter:
    #     Ps = 0  -> DECSED and DECSEL can erase (default).
    #     Ps = 1  -> DECSED and DECSEL cannot erase.
    #     Ps = 2  -> DECSED and DECSEL can erase.
    def set_char_protection_attr(param=0)
      _write("\x1b[" + param.to_s + "\"q")
    end
    alias_previous decsca

    # CSI ? Pm r
    #   Restore DEC Private Mode Values.  The value of Ps previously
    #   saved is restored.  Ps values are the same as for DECSET.
    def restore_private_values(*arguments)
      _write("\x1b[?" + arguments.join(';') + 'r')
    end

    # CSI Pt; Pl; Pb; Pr; Ps$ r
    #   Change Attributes in Rectangular Area (DECCARA), VT400 and up.
    #     Pt; Pl; Pb; Pr denotes the rectangle.
    #     Ps denotes the SGR attributes to change: 0, 1, 4, 5, 7.
    # NOTE: xterm doesn't enable this code by default.
    def set_attr_in_rectangle(*arguments)
      _write("\x1b[" + arguments.join(';') + "$r")
    end
    alias_previous deccara

    # CSI ? Pm s
    #   Save DEC Private Mode Values.  Ps values are the same as for
    #   DECSET.
    def save_private_values(*arguments)
      _write("\x1b[?" + arguments.join(';') + 's')
    end

    # TODO getWindowSize manipulateWindow

    # CSI Pt; Pl; Pb; Pr; Ps$ t
    #   Reverse Attributes in Rectangular Area (DECRARA), VT400 and
    #   up.
    #     Pt; Pl; Pb; Pr denotes the rectangle.
    #     Ps denotes the attributes to reverse, i.e.,  1, 4, 5, 7.
    # NOTE: xterm doesn't enable this code by default.
    def reverse_attr_in_rectangle(*arguments)
      _write("\x1b[" + arguments.join(';') + "$t")
    end
    alias_previous decrara

    # CSI > Ps; Ps t
    #   Set one or more features of the title modes.  Each parameter
    #   enables a single feature.
    #     Ps = 0  -> Set window/icon labels using hexadecimal.
    #     Ps = 1  -> Query window/icon labels using hexadecimal.
    #     Ps = 2  -> Set window/icon labels using UTF-8.
    #     Ps = 3  -> Query window/icon labels using UTF-8.  (See dis-
    #     cussion of "Title Modes")
    # XXX VTE bizarrely echos this
    def set_title_mode_feature(*arguments)
      _twrite("\x1b[>" + arguments.join(';') + 't')
    end

    # CSI Ps SP t
    #   Set warning-bell volume (DECSWBV, VT520).
    #     Ps = 0  or 1  -> off.
    #     Ps = 2 , 3  or 4  -> low.
    #     Ps = 5 , 6 , 7 , or 8  -> high.
    def set_warning_bell_volume(param=nil)
      _write("\x1b[" + param.to_s + " t")
    end
    alias_previous decswbv

    # CSI Ps SP u
    #   Set margin-bell volume (DECSMBV, VT520).
    #     Ps = 1  -> off.
    #     Ps = 2 , 3  or 4  -> low.
    #     Ps = 0 , 5 , 6 , 7 , or 8  -> high.
    def set_margin_bell_volume(param=nil)
      _write("\x1b[" + param.to_s + " u")
    end
    alias_previous decsmbv

    # CSI Pt; Pl; Pb; Pr; Pp; Pt; Pl; Pp$ v
    #   Copy Rectangular Area (DECCRA, VT400 and up).
    #     Pt; Pl; Pb; Pr denotes the rectangle.
    #     Pp denotes the source page.
    #     Pt; Pl denotes the target location.
    #     Pp denotes the target page.
    # NOTE: xterm doesn't enable this code by default.
    def copy_rectangle(*arguments)
      _write("\x1b[" + arguments.join(';') + "$v")
    end
    alias_previous deccra

    # CSI Pt ; Pl ; Pb ; Pr ' w
    #   Enable Filter Rectangle (DECEFR), VT420 and up.
    #   Parameters are [top;left;bottom;right].
    #   Defines the coordinates of a filter rectangle and activates
    #   it.  Anytime the locator is detected outside of the filter
    #   rectangle, an outside rectangle event is generated and the
    #   rectangle is disabled.  Filter rectangles are always treated
    #   as "one-shot" events.  Any parameters that are omitted default
    #   to the current locator position.  If all parameters are omit-
    #   ted, any locator motion will be reported.  DECELR always can-
    #   cels any prevous rectangle definition.
    def enable_filter_rectangle(*arguments)
      _write("\x1b[" + arguments.join(';') + "'w")
    end
    alias_previous decefr

    # CSI Ps x  Request Terminal Parameters (DECREQTPARM).
    #   if Ps is a "0" (default) or "1", and xterm is emulating VT100,
    #   the control sequence elicits a response of the same form whose
    #   parameters describe the terminal:
    #     Ps -> the given Ps incremented by 2.
    #     Pn = 1  <- no parity.
    #     Pn = 1  <- eight bits.
    #     Pn = 1  <- 2  8  transmit 38.4k baud.
    #     Pn = 1  <- 2  8  receive 38.4k baud.
    #     Pn = 1  <- clock multiplier.
    #     Pn = 0  <- STP flags.
    def request_parameters(param=0)
      _write("\x1b[" + param.to_s + "x")
    end
    alias_previous decreqtparm

    # CSI Ps x  Select Attribute Change Extent (DECSACE).
    #     Ps = 0  -> from start to end position, wrapped.
    #     Ps = 1  -> from start to end position, wrapped.
    #     Ps = 2  -> rectangle (exact).
    def select_change_extent(param=0)
      _write("\x1b[" + param.to_s + "x")
    end
    alias_previous decsace

    # CSI Pc; Pt; Pl; Pb; Pr$ x
    #   Fill Rectangular Area (DECFRA), VT420 and up.
    #     Pc is the character to use.
    #     Pt; Pl; Pb; Pr denotes the rectangle.
    # NOTE: xterm doesn't enable this code by default.
    def fill_rectangle(*arguments)
      _write("\x1b[" + arguments.join(';') + "$x")
    end
    alias_previous decfra

    # CSI Ps ; Pu ' z
    #   Enable Locator Reporting (DECELR).
    #   Valid values for the first parameter:
    #     Ps = 0  -> Locator disabled (default).
    #     Ps = 1  -> Locator enabled.
    #     Ps = 2  -> Locator enabled for one report, then disabled.
    #   The second parameter specifies the coordinate unit for locator
    #   reports.
    #   Valid values for the second parameter:
    #     Pu = 0  <- or omitted -> default to character cells.
    #     Pu = 1  <- device physical pixels.
    #     Pu = 2  <- character cells.
    def enable_locator_reporting(*arguments)
      _write("\x1b[" + arguments.join(';') + "'z")
    end
    alias_previous decelr

    # CSI Pt; Pl; Pb; Pr$ z
    #   Erase Rectangular Area (DECERA), VT400 and up.
    #     Pt; Pl; Pb; Pr denotes the rectangle.
    # NOTE: xterm doesn't enable this code by default.
    def erase_rectangle(*arguments)
      _write("\x1b[" + arguments.join(';') + "$z")
    end
    alias_previous decera

    # CSI Pm ' {
    #   Select Locator Events (DECSLE).
    #   Valid values for the first (and any additional parameters)
    #   are:
    #     Ps = 0  -> only respond to explicit host requests (DECRQLP).
    #                (This is default).  It also cancels any filter
    #   rectangle.
    #     Ps = 1  -> report button down transitions.
    #     Ps = 2  -> do not report button down transitions.
    #     Ps = 3  -> report button up transitions.
    #     Ps = 4  -> do not report button up transitions.
    def set_locator_events(*arguments)
      _write("\x1b[" + arguments.join(';') + "'{")
    end
    alias_previous decsle

    # CSI Pt; Pl; Pb; Pr$ {
    #   Selective Erase Rectangular Area (DECSERA), VT400 and up.
    #     Pt; Pl; Pb; Pr denotes the rectangle.
    def selective_erase_rectangle(*arguments)
      _write("\x1b[" + arguments.join(';') + "${")
    end
    alias_previous decsera

    # TODO decrqlp

    # CSI P m SP }
    # Insert P s Column(s) (default = 1) (DECIC), VT420 and up.
    # NOTE: xterm doesn't enable this code by default.
    def insert_columns(*arguments)
      _write "\x1b[" + arguments.join(';') + " }"
    end
    alias_previous decic

    # CSI P m SP ~
    # Delete P s Column(s) (default = 1) (DECDC), VT420 and up
    # NOTE: xterm doesn't enable this code by default.
    def delete_columns(*arguments)
      _write "\x1b[" + arguments.join(';') + " ~"
    end
    alias_previous decdc

    # Returns number of columns.
    def cols
      @cols ||= ::Tput.cols
    end
    alias_previous columns

    # Returns number of lines.
    def lines
      @rows ||= ::Tput.lines
    end
    alias_previous rows

  end
end
