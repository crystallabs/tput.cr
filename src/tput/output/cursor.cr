class Tput
  module Output
    module Cursor
      include Crystallabs::Helpers::Alias_Methods
      include Crystallabs::Helpers::Boolean
      include Macros

      # Positioning

      # CSI Ps E
      # Cursor Next Line Ps Times (default = 1) (CNL).
      # same as CSI Ps B ?
      def cursor_next_line(param=1)
        @position.y += param
        _ncoords
        _print { |io| io << "\x1b[" << param << 'E' }
      end
      alias_previous cnl

      # CSI Ps F
      # Cursor Preceding Line Ps Times (default = 1) (CNL).
      # reuse CSI Ps A ?
      def cursor_preceding_line(param=1)
        @position.y -= param
        _ncoords
        _print { |io| io << "\x1b[" << param << 'F' }
      end
      alias_previous cpl, cursor_previous_line

      # Sets cursor x coordinate to absolute value `param`.
      #
      #     CSI Ps G
      #     Cursor Character Absolute  [column] (default = [row,1]) (CHA).
      def cursor_char_absolute(point : Point)
        cursor_char_absolute point.x
      end
      # :ditto:
      def cursor_char_absolute(param=0)
        @position.x = param
        _ncoords

        put(hpa?(param)) || _print { |io| io << "\x1b[" << param+1 << 'G' }
      end
      alias_previous cha, setx, set_x

      # Sets cursor y coordinate to absolute value `param`.
      #
      #     CSI Pm d
      #     Line Position Absolute  [row] (default = [1,column]) (VPA).
      #
      # NOTE: Can't find in terminfo, no idea why it has multiple params.
      def cursor_line_pos_absolute(point : Point)
        cursor_line_pos_absolute point.y
      end
      def cursor_line_pos_absolute(param=1)
        @position.y = param
        _ncoords
        put(vpa?(param)) || _print { |io| io << "\x1b[" << param << 'd' }
      end
      alias_previous vpa, sety, line_pos_absolute, cursor_line_absolute, set_y

      # CSI Ps ; Ps H
      # Cursor Position [row;column] (default = [1,1]) (CUP).
      def cursor_pos(row=0, col=0)
        @position.x = col
        @position.y = row
        _ncoords()

        put(cup?(row, col)) ||
          _print { |io| io << "\x1b[" << row+1 << ';' << col+1 << 'H' }
      end
      alias_previous cup, pos

      # Moves cursor to desired point by using absolute coordinate instructions
      def move(point : Point)
        cursor_pos point.y, point.x
      end
      # :ditto:
      def move(x=nil, y=nil)
        cursor_pos y, x
      end
      alias_previous cursor_move, cursor_move_to

      # Moves cursor to desired point by using instructions relative to current position
      #
      # NOTE fix cud and cuu calls
      def omove(x=0, y=0)
        return if @position.x==x && @position.y==y

        if y == @position.y
          if x > @position.x
            cuf x-@position.x
          elsif x < @position.x
            cub @position.x-x
          end
        elsif x == @position.x
          if y > @position.y
            cud y-@position.y
          elsif y < @position.y
            cuu @position.y-y
          end
        else
          cup y, x
        end
      end
      # :ditto:
      def omove(point : Point)
        omove point.x, point.y
      end

      # Move cursor forward or back by `dx` columns
      def rsetx(dx)
        # Disabled originally
        #return h_position_relative(x)
        x > 0 ? forward(dx) : back(-dx)
      end

      # Move cursor forward or back by `dy` rows
      def rsety(dy)
        # Disabled originally
        #return v_position_relative(y)
        dy > 0 ? up(dy) : down(-dy)
      end

      # Move cursor by `dx` columns and `dy` rows
      def rmove(point : Point)
        rsetx point.x
        rsety point.y
      end
      # :ditto:
      def rmove(dx, dy)
        rsetx dx
        rsety dy
      end

      # Sets cursor shape.
      #
      # Only XTerm, (u)rxvt, screen, and iTerm2. Does nothing otherwise.
      # If you know of any others, post them.
      def cursor_shape(shape, blink=false)
        blink = blink ? 1 : 2

        if emulator.iterm2?
          case shape
            when CursorShape::Block
              _tprint "\x1b]50;CursorShape=0;BlinkingCursorEnabled=#{blink}\x07"
            when CursorShape::Underline
              _tprint "\x1b]50;CursorShape=2;BlinkingCursorEnabled=#{blink}\x07"
            when CursorShape::Line
              _tprint "\x1b]50;CursorShape=1;BlinkingCursorEnabled=#{blink}\x07"
          end
          true

        #elsif xterm? || screen? || rxvt?
        elsif name? "xterm", "screen", "rxvt"
          case shape
            when CursorShape::Block
              _tprint "\x1b[#{blink} q"
            when CursorShape::Underline
              _tprint "\x1b[#{blink+2} q"
            when CursorShape::Line
              _tprint "\x1b[#{blink+4} q"
          end
          true

        else
          false
        end
      end

      # Sets cursor color. XTerm, rxvt, and screen specific.
      #
      # Accepted values are the color names listed in `/etc/X11/rgb.txt`.
      def cursor_color(color : Color)
        cursor_color color.to_s.downcase
      end
      # :ditto:
      def cursor_color(color : String)
        if name? "xterm", "screen", "rxvt"
          _tprint "\x1b]12;#{color}\x07"
          return true
        end
        false
      end

      def reset_cursor
        if name? "xterm", "rxvt", "screen"
          # XXX Disabled originally
          # return reset_colors
          _tprint "\x1b[0 q"
          _tprint "\x1b]112\x07"
          # urxvt doesn't support OSC 112
          _tprint "\x1b]12;white\x07"
          return true
        end
        false
      end
      alias_previous cursor_reset

      # ESC 7 Save Cursor (DECSC).
      def save_cursor(key=nil)
        return lsave_cursor(key) if key
        @saved_position.x = @position.x
        @saved_position.y = @position.y
        put(sc?) || _print "\x1b7"
      end
      alias_previous sc

      # ESC 8 Restore Cursor (DECRC).
      def restore_cursor(key, hide)
        return lrestore_cursor(key, hide) if (key)
        if sp = @saved_position
          @position.x = sp.x
          @position.y = sp.y
          put(rc?) || _print "\x1b8"
        end
      end
      alias_previous rc

      # Save Cursor Locally
      def lsave_cursor(key="local")
        @_saved[key] = CursorState.new @position, @cursor_hidden
      end
      # Restore Cursor Locally
      def lrestore_cursor(key="local", hide=false)
        @_saved[key]?.try do |state|
          #delete @_saved[key]
          cup state.position
          if hide && (state.hidden? != @cursor_hidden)
            state.hidden? ? hide_cursor : show_cursor
          end
        end
      end

      # CSI Ps A
      # Cursor Up Ps Times (default = 1) (CUU).
      def cursor_up(param=nil)
        @position.y -= param || 1
        _ncoords()
        put(cuu?(0)) ||
          # XXX enable when solved: undefined method '*' for Slice(UInt8)
          #put(cuu1?.try { |v| repeat(v, param) }) ||
            _print { |io| io << "\x1b[" << param << 'A' }
      end
      alias_method cuu, up

# TODO Enable these after cursor_up is fixed to work.
# Requires param, but seems to be going 1 line too much.
#      # CSI Ps B
#      # Cursor Down Ps Times (default = 1) (CUD).
#      def cursor_down(param=1)
#        @position.y += param
#        _ncoords()
#        @tput.try do |tput|
#          unless tput.terminfo.has("parm_down_cursor")
#            return _write(repeat(tput.terminfo.get("cud1"), param))
#          end
#          return put("cud", param)
#        end
#        _write("\x1b[" + (param) + "B")
#      end
#      alias_previous cud, down
#
#      # CSI Ps C
#      # Cursor Forward Ps Times (default = 1) (CUF).
#      def cursor_forward(param=1)
#        @position.x += param
#        _ncoords()
#        @tput.try do |tput|
#          unless tput.terminfo.has("parm_right_cursor")
#            return _write(repeat(tput.terminfo.get("cuf1"), param))
#          end
#          return put("cuf", param)
#        end
#        _write("\x1b[" + (param) + "C")
#      end
#      alias_previous cuf, right, forward
#
#      # CSI Ps D
#      # Cursor Backward Ps Times (default = 1) (CUB).
#      def cursor_backward(param=1)
#        @position.x -= param
#        _ncoords()
#        @tput.try do |tput|
#          unless tput.terminfo.has("parm_left_cursor")
#            return _write(repeat(tput.terminfo.get("cub1"), param))
#          end
#          return put("cub", param)
#        end
#        _write("\x1b[" + (param) + "D")
#      end
#      alias_previous cub, left, back

      def hide_cursor
        @cursor_hidden = true
        put(civis?) || reset_mode "?25"
      end
      alias_previous dectcemh, cursor_invisible, vi, civis, cursor_invisible

      def show_cursor
        @cursor_hidden = false
        # Disabled originally:
        # NOTE: In xterm terminfo:
        # cnorm stops blinking cursor
        # cvvis starts blinking cursor
        # return _write("\x1b[?12l\x1b[?25h"); // cursor_normal
        # return _write("\x1b[?12;25h"); // cursor_visible
        put(cnorm?) || set_mode "?25"
      end
      alias_previous dectcem, cnorm, cvvis, cursor_visible

      # CSI Ps SP q
      #   Set cursor style (DECSCUSR, VT520).
      #     Ps = 0  -> blinking block.
      #     Ps = 1  -> blinking block (default).
      #     Ps = 2  -> steady block.
      #     Ps = 3  -> blinking underline.
      #     Ps = 4  -> steady underline.
      def set_cursor_style(param)
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

        (put(_Se?) && return) if param == 2
        put(_Ss?) || _print { |io| io << "\x1b[" << param << " q" }
      end
      alias_previous decscusr

      # CSI s
      #   Save cursor (ANSI.SYS).
      def save_cursor_a
        @saved_position.x = @position.x
        @saved_position.y = @position.y
        put(sc?) || _print "\x1b[s"
      end
      alias_previous sc_a

      # CSI u
      #   Restore cursor (ANSI.SYS).
      def restore_cursor_a
        @position.x = @saved_position.x
        @position.y = @saved_position.y
        put(rc?) || _print "\x1b[u"
      end
      alias_previous rc_a

      # CSI Ps I
      #   Cursor Forward Tabulation Ps tab stops (default = 1) (CHT).
      def cursor_forward_tab(param=1)
        @position.x += 8
        _ncoords
        put(tab?(param)) || _print { |io| io << "\x1b[" << param << "I" }
      end
      alias_previous cht

      # CSI Ps Z  Cursor Backward Tabulation Ps tab stops (default = 1) (CBT).
      def cursor_backward_tab(param=1)
        @position.x -= 8
        _ncoords
        put(cbt?(param)) || _print { |io| io << "\x1b[" << param << "Z" }
      end
      alias_previous cbt

      def restore_reported_cursor
        @_rx.try do |rx|
          @_ry.try do |ry|
            put(cup? ry, rx)
            # Disabled originally:
            # put "nel"
          end
        end
      end

      # 141 61 a * HPR -
      # Horizontal Position Relative
      # reuse CSI Ps C ?
      def h_position_relative(param=1)
        put(cuf?(param)) && return

        @position.x += param
        _ncoords
        # Disabled originally
        # Does not exist:
        # if (@terminfo) return put "hpr", param
        _print { |io| io << "\x1b[" << param << "a" }
      end
      alias_previous hpr

      # 145 65 e * VPR - Vertical Position Relative
      # reuse CSI Ps B ?
      def v_position_relative(param=1)
        put(cud?(param)) && return

        @position.y += param
        _ncoords

        # Disabled originally
        # Does not exist:
        # if (@terminfo) return put "vpr", param
        _print { |io| io << "\x1b[" << param << "e" }
      end
      alias_previous vpr

      # CSI Ps ; Ps f
      #   Horizontal and Vertical Position [row;column] (default =
      #   [1,1]) (HVP).
      def hv_position(row=0, col=0)
        @position.y = row
        @position.x = col
        _ncoords
        # Disabled originally
        # Does not exist (?):
        # put(hvp", row, col);
        put(cup?(row, col)) ||
          _print { |io| io << "\x1b[" << row + 1 << ';' << col + 1 << "f" }
      end
      alias_previous hvp

    end
  end
end
