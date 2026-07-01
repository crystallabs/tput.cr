class Tput
  module Output
    module Cursor
      include Crystallabs::Helpers::Alias_Methods
      include Crystallabs::Helpers::Boolean
      include Macros

      # CUU/CUD/CUF/CUB share one emit shape, differing only in capability and
      # final CSI byte: if not verified standard-ANSI, prefer the parametric cap
      # (`<parm_cap>?(param)`), else repeat the single-step cap (`<step_cap>`)
      # `param` times; `CSI <param> <final>` is both the ANSI fast path and the
      # fallback. (`Int#times` returns nil, so the repeat branch yields explicit
      # `true` — otherwise the chain falls through and double-emits the CSI.)
      private macro _emit_parm_move(param, parm_cap, step_cap, final)
        (!features.ansi_cursor? && (put(&.{{parm_cap}}?({{param}})) ||
          (has?(&.{{step_cap}}?) && ({{param}}.times { put(&.{{step_cap}}) }; true)))) ||
          _print { |io| io << "\e[" << {{param}} << {{final}} }
      end

      # Positioning

      # CSI Ps E
      # Cursor Next Line Ps Times (default = 1) (CNL).
      # same as CSI Ps B ?
      def cursor_next_line(param = 1)
        _, param = _adjust_xy_rel 0, param
        @cursor.y += param
        # CNL moves to the first column of the target line; reset tracked column too.
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
        # CPL, like CNL, moves to the first column of the target line.
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
        # Emit the clamped `@cursor.x`, not raw `param`: `_ncoords` may pull an
        # out-of-range value back onto the screen, and emitting the original would
        # desync the wire output from `@cursor`. Mirrors CUP/HVP setters.
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
        # `param` is 0-based (sequence emits `param + 1`), so default is row 0,
        # matching `cursor_char_absolute`.
        @cursor.y = param
        _ncoords
        # Emit clamped `@cursor.y`, not raw `param` — see `#cursor_char_absolute`.
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
        # Fast path: if `cup` is verified standard ANSI, build the sequence
        # directly and skip the per-call `tparm` FFI (~6x faster).
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
      # Only emits when `Features#cursor_style?` confirms the terminal supports
      # hardware cursor styling. iTerm2 uses proprietary OSC 50; others use
      # standard DECSCUSR (`CSI Ps SP q`). Returns `true` if emitted, `false` if
      # unsupported (caller, e.g. `Screen#apply_cursor`, falls back to an
      # artificial cursor).
      def cursor_shape(shape, blink = false)
        return false unless features.cursor_style?

        if emulator.iterm2?
          # iTerm2's `BlinkingCursorEnabled` is boolean (1/0), NOT the DECSCUSR
          # 1/2 encoding below — reusing that sent `=2` for steady, which iTerm2
          # reads as "blinking enabled".
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
          # Standard DECSCUSR. 1 = blinking, 2 = steady; underline/line shapes
          # add 2/4 to reach the 6 DECSCUSR values.
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
      # Accepted values are color names listed in `/etc/X11/rgb.txt`.
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
        put(&.rc?) || _print "\e8" if _restore_saved_cursor
      end

      # Restores `@cursor` from `@saved_cursor` (set by `#save_cursor`/
      # `#save_cursor_a`) and reports whether a saved position existed. Clamps
      # the restored point onto the current screen, since it may have shrunk
      # since capture — the terminal's own DECRC/SCORC clamps too, so without
      # this `@cursor` would desync from the terminal's actual position.
      private def _restore_saved_cursor : Bool
        if sp = @saved_cursor
          @cursor.x = sp.x
          @cursor.y = sp.y
          _ncoords
          true
        else
          false
        end
      end

      alias_previous rc

      # Save Cursor Locally
      def lsave_cursor(key = :local)
        # `@cursor` is a mutable reference type, so save a *copy* (as `#save_cursor`
        # does with `@cursor.dup`) — storing the live object would alias the saved
        # position to the cursor, so later moves would corrupt the saved state.
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
        _emit_parm_move param, cuu, cuu1, 'A'
      end

      alias_previous cuu, up

      # CSI Ps B
      # Cursor Down Ps Times (default = 1) (CUD).
      def cursor_down(param = 1)
        _, param = _adjust_xy_rel 0, param
        @cursor.y += param
        _emit_parm_move param, cud, cud1, 'B'
      end

      alias_previous cud, down

      # Cursor forward.
      #     CSI Ps C
      #     Cursor Forward Ps Times (default = 1) (CUF).
      def cursor_forward(param : Int = 1)
        param, _ = _adjust_xy_rel param
        @cursor.x += param
        _emit_parm_move param, cuf, cuf1, 'C'
      end

      alias_previous cuf, forward, right, cursor_right, parm_right_cursor

      # CSI Ps D
      # Cursor Backward Ps Times (default = 1) (CUB).
      def cursor_backward(param = 1)
        param, _ = _adjust_xy_rel -param
        param *= -1
        @cursor.x -= param
        _emit_parm_move param, cub, cub1, 'D'
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
        # In xterm terminfo: cnorm stops blinking cursor, cvvis starts it.
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
        # Emit literal ANSI.SYS `CSI s` (SCOSC), not the terminfo `sc` cap — that's
        # DECSC (`\e7`), a different op that also saves attributes/charset and
        # interacts with the scroll region. `#save_cursor` is the DECSC one.
        _print "\e[s"
      end

      alias_previous sc_a

      # CSI u
      #   Restore cursor (ANSI.SYS).
      def restore_cursor_a
        _restore_saved_cursor
        # Counterpart of `#save_cursor_a`: emit literal ANSI.SYS `CSI u` (SCORC),
        # not the terminfo `rc` cap (DECRC) which restores DECSC-saved state.
        _print "\e[u"
      end

      alias_previous rc_a

      # CSI Ps I
      #   Cursor Forward Tabulation Ps tab stops (default = 1) (CHT).
      def cursor_forward_tab(param = 1)
        # CHT moves to the *next* tab stop, not a flat `+param*8`. With standard
        # 8-column stops, the param-th forward stop from column x is
        # `(x // 8 + param) * 8` — e.g. from column 3, one tab lands on 8, not 11.
        # The old `+param*8` over-advanced `@cursor.x` from non-multiple-of-8
        # columns, desyncing it from the terminal's actual CHT position. The two
        # agree at tab-aligned columns, so aligned-start specs are unaffected.
        @cursor.x = (@cursor.x // 8 + param) * 8
        _ncoords
        # terminfo `tab` is a single, non-parametric tab stop; use it only for
        # `param == 1` and emit the parametric CHT sequence otherwise.
        (param == 1 && put(&.tab?)) || _print { |io| io << "\e[" << param << "I" }
      end

      alias_previous cht

      # CSI Ps Z  Cursor Backward Tabulation Ps tab stops (default = 1) (CBT).
      def cursor_backward_tab(param = 1)
        # CBT moves to the *previous* tab stop, mirroring CHT above. The previous
        # 8-column stop of x>0 is `((x - 1) // 8) * 8`, and each further step
        # subtracts another 8: `(((x - 1) // 8) - (param - 1)) * 8`. From column 10
        # one back-tab lands on 8, not `10-8=2`. Negative results (or x==0) are
        # pulled to column 0 by `_ncoords`. Equals old `-param*8` at aligned columns.
        @cursor.x = @cursor.x > 0 ? (((@cursor.x - 1) // 8) - (param - 1)) * 8 : 0
        _ncoords
        # terminfo `cbt` is single, non-parametric; use it only for `param == 1`.
        (param == 1 && put(&.cbt?)) || _print { |io| io << "\e[" << param << 'Z' }
      end

      alias_previous cbt

      def restore_reported_cursor
        @_rx.try do |rx|
          @_ry.try do |ry|
            # Use high-level `cup` (updates @cursor), not the raw `put(&.cup?...)`
            # primitive — the reported position (0-based, see
            # `#save_reported_cursor`) must update the tracked cursor too, or
            # later relative moves desync. Emits the same bytes either way.
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
        # `param` is 0-based (sequence emits `param + 1`), so default is column 0,
        # matching `cursor_char_absolute`.
        @cursor.x = param
        _ncoords
        # Emit clamped `@cursor.x`, not raw `param` — see `#cursor_char_absolute`.
        # terminfo's `hpa` emits the `CSI Ps G` form; only the no-terminfo
        # fallback uses `CSI Ps \``. The fast path mirrors terminfo.
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
        # Keep @cursor.x in sync (mirrors `v_position_relative`); leaving it
        # stale would desync later relative moves.
        @cursor.x += param
        _ncoords

        # Mirror terminfo `cuf` branch (emits `CSI Ps C`); no-terminfo fallback
        # uses `CSI Ps a` (HPR) form.
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

        # Mirror terminfo `cud` branch (emits `CSI Ps B`); no-terminfo fallback
        # uses `CSI Ps e` (VPR) form.
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
        # Adjust through `_adjust_xy_abs` (like CUP twin `#cursor_position`)
        # rather than clamping only the tracked cursor afterwards: the old code
        # emitted unadjusted `row`/`col` while storing the clamped position, so
        # negative args (meaning "from bottom/right edge") produced a malformed
        # CSI, and out-of-range args desynced output from `@cursor`. Now both
        # agree, and edge-relative coordinates work as in `#cursor_position`.
        @cursor.x, @cursor.y = _adjust_xy_abs col, row
        # D O:
        # Does not exist (?):
        # put(&.hvp", row, col);
        # Mirror terminfo `cup` branch (emits `CSI r;c H`); no-terminfo fallback
        # uses `CSI r;c f` (HVP) form.
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
