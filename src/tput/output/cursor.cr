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
      def cursor_next_line(param = 1)
        _, param = _adjust_xy_rel 0, param
        @cursor.y += param
        _print { |io| io << "\e[" << param << 'E' }
      end

      alias_previous cnl

      # CSI Ps F
      # Cursor Preceding Line Ps Times (default = 1) (CNL).
      # reuse CSI Ps A ?
      def cursor_preceding_line(param = 1)
        _, param = _adjust_xy_rel 0, -param
        param *= -1
        @cursor.y -= param
        _print { |io| io << "\e[" << param << 'F' }
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
      def cursor_char_absolute(param = 0)
        @cursor.x = param
        _ncoords
        put(&.hpa?(param)) || _print { |io| io << "\e[" << param + 1 << 'G' }
      end

      alias_previous cha, setx, set_x

      # Sets cursor y coordinate to absolute value `param`.
      #
      #     CSI Pm d
      #     Line Position Absolute  [row] (default = [1,column]) (VPA).
      #
      # NOTE: Can't find in terminfo, no idea why it has multiple params (Pm).
      def cursor_line_absolute(point : Point)
        cursor_line_absolute point.y
      end

      def cursor_line_absolute(param = 1)
        # TODO switch to adjust_xy
        @cursor.y = param
        _ncoords
        put(&.vpa?(param)) || _print { |io| io << "\e[" << param << 'd' }
      end

      alias_previous vpa, sety, line_absolute, line_pos_absolute, set_y

      # Set cursor position.
      #     CSI Ps ; Ps H
      #     Cursor Position [row;column] (default = [1,1]) (CUP).
      def cursor_position(point : Tput::Point)
        cursor_position point.y, point.x
      end

      # :ditto:
      def cursor_position(row : Int = 0, column : Int = 0)
        @cursor.x, @cursor.y = _adjust_xy_abs column, row
        put(&.cup?(@cursor.y, @cursor.x)) ||
          _print { |io| io << "\e[" << @cursor.y + 1 << ';' << @cursor.x + 1 << 'H' }
      end

      alias_previous cursor_pos, cup, pos, setyx

      # Moves cursor to desired point by using absolute coordinate instructions
      def move(point : Point)
        cursor_pos point.y, point.x
      end

      # :ditto:
      def move(x = nil, y = nil)
        cursor_pos y, x
      end

      alias_previous cursor_move, cursor_move_to

      # Moves cursor to desired point by using instructions relative to current position
      #
      # NOTE fix cud and cuu calls
      def omove(x = 0, y = 0)
        return if @cursor.x == x && @cursor.y == y

        if y == @cursor.y
          if x > @cursor.x
            cuf x - @cursor.x
          elsif x < @cursor.x
            cub @cursor.x - x
          end
        elsif x == @cursor.x
          if y > @cursor.y
            cud y - @cursor.y
          elsif y < @cursor.y
            cuu @cursor.y - y
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
        # return h_position_relative(x)
        dx > 0 ? forward(dx) : back(-dx)
      end

      # Move cursor forward or back by `dy` rows
      def rsety(dy)
        # Disabled originally
        # return v_position_relative(y)
        dy > 0 ? down(dy) : up(-dy)
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
      def cursor_shape(shape, blink = false)
        blink = blink ? 1 : 2

        if emulator.iterm2?
          case shape
          when CursorShape::Block
            _tprint "\e]50;CursorShape=0;BlinkingCursorEnabled=#{blink}\x07"
          when CursorShape::Underline
            _tprint "\e]50;CursorShape=2;BlinkingCursorEnabled=#{blink}\x07"
          when CursorShape::Line
            _tprint "\e]50;CursorShape=1;BlinkingCursorEnabled=#{blink}\x07"
          end
          true

          # elsif xterm? || screen? || rxvt?
        elsif name? "xterm", "screen", "rxvt"
          case shape
          when CursorShape::Block
            _tprint "\e[#{blink} q"
          when CursorShape::Underline
            _tprint "\e[#{blink + 2} q"
          when CursorShape::Line
            _tprint "\e[#{blink + 4} q"
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
          _tprint "\e]12;#{color}\x07"
          return true
        end
        false
      end

      def reset_cursor
        if name? "xterm", "rxvt", "screen"
          # D O: XXX
          # return reset_colors
          _tprint "\e[0 q"
          _tprint "\e]112\x07"
          # urxvt doesn't support OSC 112
          _tprint "\e]12;white\x07"
          return true
        end
        false
      end

      alias_previous cursor_reset

      # Save cursor position.
      #
      # ESC 7 Save Cursor (DECSC).
      def save_cursor(key : String? = nil)
        return lsave_cursor(key) if key
        @saved_cursor = @cursor.dup
        put(&.sc?) || _print "\e7"
      end

      alias_previous sc

      # Restore saved cursor position.
      #
      # ESC 8 Restore Cursor (DECRC).
      def restore_cursor(key : String? = nil, hide : Bool = false)
        return lrestore_cursor(key, hide) if (key)
        if sp = @saved_cursor
          @cursor.x = sp.x
          @cursor.y = sp.y
          put(&.rc?) || _print "\e8"
        end
      end

      alias_previous rc

      # Save Cursor Locally
      def lsave_cursor(key = :local)
        @_saved[key] = CursorState.new @cursor, @cursor_hidden
      end

      # Restore Cursor Locally
      def lrestore_cursor(key = :local, hide = false)
        @_saved[key]?.try do |state|
          # delete @_saved[key]
          cup state.position
          if hide && (state.hidden? != @cursor_hidden)
            state.hidden? ? hide_cursor : show_cursor
          end
        end
      end

      # CSI Ps A
      # Cursor Up Ps Times (default = 1) (CUU).
      def cursor_up(param = 1)
        _, param = _adjust_xy_rel 0, -param
        param *= -1
        @cursor.y -= param
        put(&.cuu?(param)) ||
          (has? &.cuu1? && param.times { put(&.cuu1) }) ||
          _print { |io| io << "\e[" << param << 'A' }
      end

      alias_previous cuu, up

      # CSI Ps A
      # Cursor Up Ps Times (default = 1) (CUU).
      def cursor_down(param = 1)
        _, param = _adjust_xy_rel 0, param
        @cursor.y += param
        put(&.cud?(param)) ||
          (has? &.cud1? && param.times { put(&.cud1) }) ||
          _print { |io| io << "\e[" << param << 'B' }
      end

      alias_previous cud, down

      # Cursor forward.
      #     CSI Ps C
      #     Cursor Forward Ps Times (default = 1) (CUF).
      def cursor_forward(param : Int = 1)
        param, _ = _adjust_xy_rel param
        @cursor.x += param
        put(&.cuf?(param)) ||
          (has? &.cuf1? && param.times { put(&.cuf1) }) ||
          _print { |io| io << "\e[" << param << 'C' }
      end

      alias_previous cuf, forward, right, cursor_right, parm_right_cursor

      # CSI Ps A
      # Cursor Up Ps Times (default = 1) (CUU).
      def cursor_backward(param = 1)
        param, _ = _adjust_xy_rel -param
        param *= -1
        @cursor.x -= param
        put(&.cub?(param)) ||
          (has? &.cub1? && param.times { put(&.cub1) }) ||
          _print { |io| io << "\e[" << param << 'D' }
      end

      alias_previous cub, left, back

      def hide_cursor
        @cursor_hidden = true
        put(&.civis?) || reset_mode "?25"
      end

      alias_previous dectcemh, cursor_invisible, vi, civis

      def show_cursor
        @cursor_hidden = false
        # Disabled originally:
        # NOTE: In xterm terminfo:
        # cnorm stops blinking cursor
        # cvvis starts blinking cursor
        # return _write("\e[?12l\e[?25h"); // cursor_normal
        # return _write("\e[?12;25h"); // cursor_visible
        put(&.cnorm?) || set_mode "?25"
      end

      alias_previous dectcem, cnorm, cvvis, cursor_visible

      # CSI Ps SP q
      #   Set cursor style (DECSCUSR, VT520).
      #     Ps = 0  -> blinking block.
      #     Ps = 1  -> blinking block (default).
      #     Ps = 2  -> steady block.
      #     Ps = 3  -> blinking underline.
      #     Ps = 4  -> steady underline.
      def set_cursor_style(style = CursorStyle::SteadyBlock)
        (put(&._Se?) && return) if style.value == 2
        put(&._Ss?(param)) || _print { |io| io << "\e[" << style.value << " q" }
      end

      alias_previous decscusr

      # CSI s
      #   Save cursor (ANSI.SYS).
      def save_cursor_a
        @saved_cursor.x = @cursor.x
        @saved_cursor.y = @cursor.y
        put(&.sc?) || _print "\e[s"
      end

      alias_previous sc_a

      # CSI u
      #   Restore cursor (ANSI.SYS).
      def restore_cursor_a
        @cursor.x = @saved_cursor.x
        @cursor.y = @saved_cursor.y
        _ncoords
        put(&.rc?) || _print "\e[u"
      end

      alias_previous rc_a

      # CSI Ps I
      #   Cursor Forward Tabulation Ps tab stops (default = 1) (CHT).
      def cursor_forward_tab(param = 1)
        @cursor.x += 8
        _ncoords
        put(&.tab?(param)) || _print { |io| io << "\e[" << param << "I" }
      end

      alias_previous cht

      # CSI Ps Z  Cursor Backward Tabulation Ps tab stops (default = 1) (CBT).
      def cursor_backward_tab(param = 1)
        @cursor.x -= 8
        _ncoords
        put(&.cbt?(param)) || _print { |io| io << "\e[" << param << 'Z' }
      end

      alias_previous cbt

      def restore_reported_cursor
        @_rx.try do |rx|
          @_ry.try do |ry|
            put(&.cup? ry, rx)
            # D O:
            # put "nel"
          end
        end
      end

      # CSI Pm `  Character Position Absolute
      #   [column] (default = [row,1]) (HPA).
      # TODO switch to adjust_xy
      def char_pos_absolute(param = 1)
        @x = param
        _ncoords
        put(&.hpa?(param)) || _print { |io| io << "\e[" << param << '`' }
      end

      alias_previous hpa

      # 141 61 a * HPR -
      # Horizontal Position Relative
      # reuse CSI Ps C ?
      # TODO switch to adjust_xy; how can we put cuf() without adjusting state?
      def h_position_relative(param = 1)
        put(&.cuf?(param)) && return

        @cursor.x += param
        _ncoords
        # Disabled originally
        # Does not exist:
        # if (@terminfo) return put "hpr", param
        _print { |io| io << "\e[" << param << 'a' }
      end

      alias_previous hpr

      # 145 65 e * VPR - Vertical Position Relative
      # reuse CSI Ps B ?
      # TODO adjust_xy
      def v_position_relative(param = 1)
        @cursor.y += param
        _ncoords

        put(&.cud?(param)) ||
          # Disabled originally
          # Does not exist:
          # if (@terminfo) return put "vpr", param
          _print { |io| io << "\e[" << param << 'e' }
      end

      alias_previous vpr

      # CSI Ps ; Ps f
      #   Horizontal and Vertical Position [row;column] (default =
      #   [1,1]) (HVP).
      # TODO adjust_xy
      def hv_position(row = 0, col = 0)
        @cursor.y = row
        @cursor.x = col
        _ncoords
        # D O:
        # Does not exist (?):
        # put(&.hvp", row, col);
        put(&.cup?(row, col)) ||
          _print { |io| io << "\e[" << row + 1 << ';' << col + 1 << 'f' }
      end

      alias_previous hvp

      # OSC Ps ; Pt ST
      # OSC Ps ; Pt BEL
      #   Reset colors
      def reset_cursor_color
        # TODO - enable when put supports extended caps, unpend test
        # put(&._Cr?) ||
        _tprint "\e]112\x07"
      end

      # OSC Ps ; Pt ST
      # OSC Ps ; Pt BEL
      #   Change dynamic colors
      def dynamic_cursor_color(param)
        put(&._Cs?(param)) || _tprint "\e]12;#{param}\x07"
      end
    end
  end
end
