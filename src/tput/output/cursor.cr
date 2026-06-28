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
        # CNL moves to the first column of the target line, so the tracked
        # column must be reset too (otherwise later relative moves go stale).
        @cursor.x = 0
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
        # CPL, like CNL, moves to the first column of the target line; keep the
        # tracked column in sync.
        @cursor.x = 0
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
        # Emit the *clamped* column (`@cursor.x`), not the raw `param`: `_ncoords`
        # may pull an out-of-range `param` back onto the screen, so emitting the
        # original value (and feeding it to `hpa`'s tparm) would desync the wire
        # output from `@cursor` and produce a bogus column for large values.
        # Mirrors the CUP/HVP setters, which already emit the adjusted coordinate.
        # Fast path: `hpa` verified standard ANSI (== this fallback), skip tparm.
        (!features.ansi_hpa? && put(&.hpa?(@cursor.x))) ||
          _print { |io| io << "\e[" << @cursor.x + 1 << 'G' }
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

      def cursor_line_absolute(param = 0)
        # TODO switch to adjust_xy
        # `param` is 0-based (the sequence emits `param + 1`), so the default
        # must be 0 — the first row — matching `cursor_char_absolute`.
        @cursor.y = param
        _ncoords
        # Emit the *clamped* row (`@cursor.y`), not the raw `param` — see the note
        # in `#cursor_char_absolute`: `_ncoords` may clamp an out-of-range `param`,
        # so emitting the original would desync the wire output from `@cursor`.
        # Fast path: `vpa` verified standard ANSI (== this fallback), skip tparm.
        (!features.ansi_vpa? && put(&.vpa?(@cursor.y))) ||
          _print { |io| io << "\e[" << @cursor.y + 1 << 'd' }
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
        # Fast path: when the terminal's `cup` is verified standard ANSI, build
        # the sequence directly and skip the per-call `tparm` FFI (~6x faster).
        (!features.ansi_cursor? && put(&.cup?(@cursor.y, @cursor.x))) ||
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

      # Sets the *hardware* cursor shape.
      #
      # Emits the right escape sequence only when the terminal is known (or has
      # been probed) to support hardware cursor styling — see
      # `Features#cursor_style?`. iTerm2 uses its proprietary OSC 50; every other
      # supported terminal uses the standard DECSCUSR (`CSI Ps SP q`). Returns
      # `true` if a sequence was emitted, `false` if the terminal can't style its
      # cursor (the caller, e.g. `Screen#apply_cursor`, then falls back to an
      # artificial cursor).
      def cursor_shape(shape, blink = false)
        return false unless features.cursor_style?

        if emulator.iterm2?
          # iTerm2's `BlinkingCursorEnabled` is a boolean flag (1 = on, 0 = off),
          # NOT the DECSCUSR 1/2 encoding below — reusing the latter here sent
          # `=2` for a steady cursor, which iTerm2 reads as "blinking enabled".
          enabled = blink ? 1 : 0
          case shape
          when CursorShape::Block
            _tprint "\e]50;CursorShape=0;BlinkingCursorEnabled=#{enabled}\x07"
          when CursorShape::Underline
            _tprint "\e]50;CursorShape=2;BlinkingCursorEnabled=#{enabled}\x07"
          when CursorShape::Line
            _tprint "\e]50;CursorShape=1;BlinkingCursorEnabled=#{enabled}\x07"
          end
        else
          # Standard DECSCUSR. Used for xterm/screen/rxvt and any terminal whose
          # support was confirmed by probing. 1 = blinking, 2 = steady; the
          # underline/line shapes add 2/4 to reach the 6 DECSCUSR values.
          blink = blink ? 1 : 2
          case shape
          when CursorShape::Block
            _tprint "\e[#{blink} q"
          when CursorShape::Underline
            _tprint "\e[#{blink + 2} q"
          when CursorShape::Line
            _tprint "\e[#{blink + 4} q"
          end
        end
        true
      end

      # Sets cursor color. XTerm, rxvt, and screen specific.
      #
      # Accepted values are the color names listed in `/etc/X11/rgb.txt`.
      def cursor_color(color : Color)
        cursor_color color.to_s.downcase
      end

      # :ditto:
      def cursor_color(color : String)
        return false unless features.cursor_color?
        _tprint "\e]12;#{color}\x07"
        true
      end

      def reset_cursor
        emitted = false

        if features.cursor_style?
          _tprint "\e[0 q"
          emitted = true
        end

        if features.cursor_color?
          _tprint "\e]112\x07"
          # urxvt doesn't support OSC 112
          _tprint "\e]12;white\x07"
          emitted = true
        end

        emitted
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
        return lrestore_cursor(key, hide) if key
        if sp = @saved_cursor
          @cursor.x = sp.x
          @cursor.y = sp.y
          # Clamp the restored position back onto the screen, exactly as the
          # SCORC counterpart `#restore_cursor_a` already does. The saved point
          # was in bounds when captured, but the screen may have shrunk since
          # (terminal resize); the terminal's own DECRC clamps to the current
          # size, so without this `@cursor` would be left out of bounds and
          # desync from where the terminal actually places the cursor — breaking
          # every later relative move computed from it.
          _ncoords
          put(&.rc?) || _print "\e8"
        end
      end

      alias_previous rc

      # Save Cursor Locally
      def lsave_cursor(key = :local)
        # `@cursor` is a mutable `Point` (a reference type), so the saved state
        # must hold a *copy* — exactly as `#save_cursor` does with `@cursor.dup`.
        # Storing the live `@cursor` aliased the saved position to the cursor
        # itself, so every later move mutated the "saved" point in place and
        # `#lrestore_cursor` would restore the *current* position, not the saved one.
        @_saved[key] = CursorState.new @cursor.dup, @cursor_hidden
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
        # `Int#times` returns nil, so the repeat branch must yield an explicit
        # `true` after emitting — otherwise the chain falls through and ALSO
        # prints the CSI fallback (double emission).
        (!features.ansi_cursor? && (put(&.cuu?(param)) ||
          (has?(&.cuu1?) && (param.times { put(&.cuu1) }; true)))) ||
          _print { |io| io << "\e[" << param << 'A' }
      end

      alias_previous cuu, up

      # CSI Ps A
      # Cursor Up Ps Times (default = 1) (CUU).
      def cursor_down(param = 1)
        _, param = _adjust_xy_rel 0, param
        @cursor.y += param
        (!features.ansi_cursor? && (put(&.cud?(param)) ||
          (has?(&.cud1?) && (param.times { put(&.cud1) }; true)))) ||
          _print { |io| io << "\e[" << param << 'B' }
      end

      alias_previous cud, down

      # Cursor forward.
      #     CSI Ps C
      #     Cursor Forward Ps Times (default = 1) (CUF).
      def cursor_forward(param : Int = 1)
        param, _ = _adjust_xy_rel param
        @cursor.x += param
        (!features.ansi_cursor? && (put(&.cuf?(param)) ||
          (has?(&.cuf1?) && (param.times { put(&.cuf1) }; true)))) ||
          _print { |io| io << "\e[" << param << 'C' }
      end

      alias_previous cuf, forward, right, cursor_right, parm_right_cursor

      # CSI Ps A
      # Cursor Up Ps Times (default = 1) (CUU).
      def cursor_backward(param = 1)
        param, _ = _adjust_xy_rel -param
        param *= -1
        @cursor.x -= param
        (!features.ansi_cursor? && (put(&.cub?(param)) ||
          (has?(&.cub1?) && (param.times { put(&.cub1) }; true)))) ||
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
        # TODO - enable when put supports extended caps (Se/Ss)
        # (put(&._Se?) && return) if style.value == 2
        # put(&._Ss?(style.value)) ||
        _print { |io| io << "\e[" << style.value << " q" }
      end

      alias_previous decscusr

      # CSI s
      #   Save cursor (ANSI.SYS).
      def save_cursor_a
        @saved_cursor = @cursor.dup
        # Emit the literal ANSI.SYS `CSI s` (SCOSC). Do NOT route through the
        # terminfo `sc` cap: that is DECSC (`\e7`), a *different* operation that
        # also saves attributes/charset and interacts with the scroll region.
        # The `_a` variant exists precisely to provide the SCOSC form; `#save_cursor`
        # is the DECSC one.
        _print "\e[s"
      end

      alias_previous sc_a

      # CSI u
      #   Restore cursor (ANSI.SYS).
      def restore_cursor_a
        if sp = @saved_cursor
          @cursor.x = sp.x
          @cursor.y = sp.y
          _ncoords
        end
        # Counterpart of `#save_cursor_a`: emit the literal ANSI.SYS `CSI u`
        # (SCORC), not the terminfo `rc` cap (DECRC, `\e8`) which restores the
        # state saved by DECSC rather than SCOSC.
        _print "\e[u"
      end

      alias_previous rc_a

      # CSI Ps I
      #   Cursor Forward Tabulation Ps tab stops (default = 1) (CHT).
      def cursor_forward_tab(param = 1)
        # CHT moves to the *next* tab stop, not a flat `+param*8`. With the
        # standard 8-column stops the param-th forward stop from column x is
        # `(x // 8 + param) * 8` — e.g. from column 3, one tab lands on 8, not 11.
        # The old `+param*8` over-advanced `@cursor.x` from any column that wasn't
        # already a multiple of 8, desyncing the tracked cursor from where the
        # terminal's CHT actually leaves it (the ICH/DECRC desync class). The two
        # agree at tab-aligned columns, so existing aligned-start specs are intact.
        @cursor.x = (@cursor.x // 8 + param) * 8
        _ncoords
        # The terminfo `tab` cap is a single, non-parametric tab; it only matches
        # one tab stop, so use it solely for `param == 1` and emit the parametric
        # CHT sequence otherwise (there is no parametric terminfo cap for it).
        (param == 1 && put(&.tab?)) || _print { |io| io << "\e[" << param << "I" }
      end

      alias_previous cht

      # CSI Ps Z  Cursor Backward Tabulation Ps tab stops (default = 1) (CBT).
      def cursor_backward_tab(param = 1)
        # CBT moves to the *previous* tab stop, the mirror of CHT above. The
        # previous 8-column stop of x>0 is `((x - 1) // 8) * 8`, and each further
        # step subtracts another 8: `(((x - 1) // 8) - (param - 1)) * 8`. From
        # column 10 one back-tab lands on 8, not `10-8=2`. A negative result (or
        # x==0, which has no earlier stop) is pulled back to column 0 by `_ncoords`.
        # Equals the old `-param*8` at tab-aligned columns, so aligned specs hold.
        @cursor.x = @cursor.x > 0 ? (((@cursor.x - 1) // 8) - (param - 1)) * 8 : 0
        _ncoords
        # As with `tab` above, the terminfo `cbt` cap is single, non-parametric;
        # use it only for `param == 1`, else emit the parametric CBT sequence.
        (param == 1 && put(&.cbt?)) || _print { |io| io << "\e[" << param << 'Z' }
      end

      alias_previous cbt

      def restore_reported_cursor
        @_rx.try do |rx|
          @_ry.try do |ry|
            # Go through the high-level `cup` (which updates @cursor) rather than
            # the raw `put(&.cup?...)` primitive: the reported position (stored
            # 0-based, see `#save_reported_cursor`) must become the tracked
            # cursor too, otherwise @cursor is left stale and later relative
            # moves desync. Emits the same bytes the primitive would.
            cup ry, rx
            # D O:
            # put "nel"
          end
        end
      end

      # CSI Pm `  Character Position Absolute
      #   [column] (default = [row,1]) (HPA).
      # TODO switch to adjust_xy
      def char_pos_absolute(param = 0)
        # `param` is 0-based (the sequence emits `param + 1`), so the default
        # must be 0 — the first column — matching `cursor_char_absolute`.
        @cursor.x = param
        _ncoords
        # Emit the *clamped* column (`@cursor.x`), not the raw `param` — see the
        # note in `#cursor_char_absolute`: `_ncoords` may clamp an out-of-range
        # `param`, so emitting the original would desync the wire from `@cursor`.
        # When terminfo is present its `hpa` emits the `CSI Ps G` form; only the
        # no-terminfo fallback uses `CSI Ps \``. The fast path mirrors terminfo.
        if features.ansi_hpa?
          _print { |io| io << "\e[" << @cursor.x + 1 << 'G' }
        else
          put(&.hpa?(@cursor.x)) || _print { |io| io << "\e[" << @cursor.x + 1 << '`' }
        end
      end

      alias_previous hpa

      # 141 61 a * HPR -
      # Horizontal Position Relative
      # reuse CSI Ps C ?
      # TODO switch to adjust_xy
      def h_position_relative(param = 1)
        # Keep @cursor.x in sync (mirrors `v_position_relative` and Blessed's
        # `cuf()`-method delegation); leaving it stale here desynced later
        # relative moves. Emitted bytes are unchanged.
        @cursor.x += param
        _ncoords

        # Mirror the terminfo `cuf` branch (emits `CSI Ps C`); only the
        # no-terminfo fallback uses the `CSI Ps a` (HPR) form.
        if features.ansi_cursor?
          _print { |io| io << "\e[" << param << 'C' }
        else
          put(&.cuf?(param)) ||
            # Disabled originally
            # Does not exist:
            # if (@terminfo) return put "hpr", param
            _print { |io| io << "\e[" << param << 'a' }
        end
      end

      alias_previous hpr

      # 145 65 e * VPR - Vertical Position Relative
      # reuse CSI Ps B ?
      # TODO adjust_xy
      def v_position_relative(param = 1)
        @cursor.y += param
        _ncoords

        # Mirror the terminfo `cud` branch (emits `CSI Ps B`); only the
        # no-terminfo fallback uses the `CSI Ps e` (VPR) form.
        if features.ansi_cursor?
          _print { |io| io << "\e[" << param << 'B' }
        else
          put(&.cud?(param)) ||
            # Disabled originally
            # Does not exist:
            # if (@terminfo) return put "vpr", param
            _print { |io| io << "\e[" << param << 'e' }
        end
      end

      alias_previous vpr

      # CSI Ps ; Ps f
      #   Horizontal and Vertical Position [row;column] (default =
      #   [1,1]) (HVP).
      def hv_position(row = 0, col = 0)
        # Adjust through `_adjust_xy_abs` (like the CUP twin `#cursor_position`)
        # rather than assigning the raw args and only clamping the tracked cursor
        # afterwards with `_ncoords`. The old code emitted the *unadjusted*
        # `row`/`col` while storing the clamped position, so:
        #   * negative args — which mean "from the bottom/right edge", exactly as
        #     in `#cursor_position` — produced a malformed CSI with a negative
        #     parameter (e.g. `hv_position(-1, -1)` -> "\e[0;0f"/"\e[-?…"), and
        #   * out-of-range args desynced the emitted sequence from `@cursor`.
        # Now the wire output and `@cursor` always agree, and edge-relative
        # (negative) coordinates work as they do for `#cursor_position`.
        @cursor.x, @cursor.y = _adjust_xy_abs col, row
        # D O:
        # Does not exist (?):
        # put(&.hvp", row, col);
        # Mirror the terminfo `cup` branch (emits `CSI r;c H`); only the
        # no-terminfo fallback uses the `CSI r;c f` (HVP) form.
        if features.ansi_cursor?
          _print { |io| io << "\e[" << @cursor.y + 1 << ';' << @cursor.x + 1 << 'H' }
        else
          put(&.cup?(@cursor.y, @cursor.x)) ||
            _print { |io| io << "\e[" << @cursor.y + 1 << ';' << @cursor.x + 1 << 'f' }
        end
      end

      alias_previous hvp

      # OSC Ps ; Pt ST
      # OSC Ps ; Pt BEL
      #   Reset colors
      def reset_cursor_color
        put_extended("Cr") || _tprint("\e]112\x07")
      end

      # OSC Ps ; Pt ST
      # OSC Ps ; Pt BEL
      #   Change dynamic colors
      def dynamic_cursor_color(param)
        put_extended("Cs", param) || _tprint("\e]12;#{param}\x07")
      end
    end
  end
end
