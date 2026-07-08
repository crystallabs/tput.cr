class Tput
  module Output
    module Mouse
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

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
        locator_op 'w', *arguments
      end

      alias_previous decefr

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
        locator_op '{', *arguments
      end

      alias_previous decsle

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
        locator_op 'z', *arguments
      end

      alias_previous decelr

      # General mouse-mode setter. Each argument selects a reporting mode; pass
      # `true` to enable it, `false` to disable it, or leave it `nil` to not
      # touch it. This is the equivalent of Blessed's `Program#setMouse`.
      #
      # * *x10* — `?9`, X10 compatibility (press only).
      # * *vt200* — `?1000`, normal tracking (press + release).
      # * *vt200_hilite* — `?1001`, highlight tracking.
      # * *cell_motion* — `?1002`, button-event tracking (motion while pressed).
      # * *all_motion* — `?1003`, any-event tracking. Under tmux this is passed
      #   through directly (tmux gates `?1003`).
      # * *send_focus* — `?1004`, FocusIn/FocusOut reporting.
      # * *utf* — `?1005`, UTF-8 extended coordinates.
      # * *sgr* — `?1006`, SGR extended encoding (the modern default).
      # * *urxvt* — `?1015`, urxvt extended encoding.
      # * *pixels* — `?1016`, SGR-Pixels encoding (DEC 1016). Identical wire
      #   format to `sgr` (`\e[< Cb ; Cx ; Cy M|m`) but the coordinates are
      #   **pixels** rather than cells. Supersedes 1006 when both are on, so a
      #   caller wanting pixel resolution should still leave `sgr` enabled as a
      #   fallback. Enabling here only toggles the mode byte; the cell size
      #   needed to derive cell coordinates is set separately via
      #   `#mouse_cell_pixels=` (see `#enable_mouse`).
      # * *dec* — DEC locator mode (DECELR/DECSLE).
      # * *pterm*, *jsbterm* — pterm / jsbterm private mouse protocols.
      # * *normal* — convenience for `vt200` + `all_motion`.
      # * *hilite_tracking* — alias of *vt200_hilite*.
      #
      # GPM (Linux console) is not handled here: it's not a terminal-sequence
      # mode and is managed one layer up (e.g. Crysterm's `gpm` integration),
      # converting into the same `Tput::Mouse::Event`.
      def set_mouse(
        x10 : Bool? = nil,
        vt200 : Bool? = nil,
        vt200_hilite : Bool? = nil,
        cell_motion : Bool? = nil,
        all_motion : Bool? = nil,
        send_focus : Bool? = nil,
        utf : Bool? = nil,
        sgr : Bool? = nil,
        urxvt : Bool? = nil,
        pixels : Bool? = nil,
        dec : Bool? = nil,
        pterm : Bool? = nil,
        jsbterm : Bool? = nil,
        normal : Bool? = nil,
        hilite_tracking : Bool? = nil,
      )
        # normalMouse = vt200 + allMotion; hiliteTracking aliases vt200Hilite.
        unless normal.nil?
          vt200 = normal if vt200.nil?
          all_motion = normal if all_motion.nil?
        end
        vt200_hilite = hilite_tracking if vt200_hilite.nil?

        toggle_mode 9, x10
        toggle_mode 1000, vt200
        toggle_mode 1001, vt200_hilite
        toggle_mode 1002, cell_motion

        # tmux only forwards cellMotion; pass anyMotion straight through.
        unless all_motion.nil?
          if emulator.tmux?
            _tprint(all_motion ? "\e[?1003h" : "\e[?1003l")
          else
            toggle_mode 1003, all_motion
          end
        end

        toggle_mode 1004, send_focus
        toggle_mode 1005, utf
        toggle_mode 1006, sgr
        toggle_mode 1015, urxvt
        toggle_mode 1016, pixels

        unless dec.nil?
          _print(dec ? "\e[1;2'z\e[1;3'{" : "\e['z")
        end
        unless pterm.nil?
          _print(pterm ? "\e[>1h\e[>6h\e[>7h\e[>1h\e[>9l" : "\e[>1l\e[>6l\e[>7l\e[>1l\e[>9h")
        end
        unless jsbterm.nil?
          _print(jsbterm ? "\e[0~ZwLMRK+1Q\e\\" : "\e[0~ZwQ\e\\")
        end
      end

      # Enables xterm mouse reporting (button + drag + all-motion tracking with
      # the modern SGR encoding):
      #   * 1000 - report button press and release
      #   * 1002 - additionally report motion while a button is held (drag)
      #   * 1003 - additionally report all motion
      #   * 1006 - SGR extended encoding (coordinates beyond column/row 223,
      #            and unambiguous press/release)
      #
      # 1006 is what makes `Tput::Input#listen` receive the modern `\e[<…M/m`
      # reports. Pass *focus* `true` to also enable FocusIn/FocusOut (mode 1004).
      #
      # Pass *pixels* the terminal's cell size (`{cell_w, cell_h}` in pixels) to
      # additionally enable SGR-Pixels reporting (DEC 1016): reports then carry
      # pixel coordinates, and the parser (`#read_sgr`) uses this cell size to
      # derive cell coordinates while surfacing the raw pixels on the event's
      # `px`/`py`. 1006 stays enabled as a cell-coordinate fallback. Leave
      # *pixels* `nil` (the default) for ordinary cell-resolution reporting.
      def enable_mouse(focus : Bool = false, pixels : Tuple(Int32, Int32)? = nil)
        set_mouse vt200: true, cell_motion: true, all_motion: true, sgr: true,
          pixels: (pixels ? true : nil), send_focus: (focus ? true : nil)
        @mouse_cell_pixels = pixels
        @mouse_focus_enabled = focus
        @mouse_enabled = true
      end

      # Disables the xterm mouse reporting modes enabled by `#enable_mouse`
      # (including SGR-Pixels 1016 and its cached cell size, and focus reporting
      # mode 1004 if it was enabled via `enable_mouse(focus: true)`).
      def disable_mouse(focus : Bool = false)
        set_mouse vt200: false, cell_motion: false, all_motion: false, sgr: false,
          pixels: (@mouse_cell_pixels ? false : nil),
          send_focus: ((focus || @mouse_focus_enabled) ? false : nil)
        @mouse_cell_pixels = nil
        @mouse_focus_enabled = false
        @mouse_enabled = false
      end

      # Enables or disables a numeric DEC private mode (`CSI ? Ps h` / `l`),
      # skipping the write entirely when *on* is `nil`.
      private def toggle_mode(mode : Int32, on : Bool?)
        return if on.nil?
        on ? decset(mode) : decrst(mode)
      end

      # Shared framing for the DEC locator ops that take coordinate/parameter
      # args: `CSI P… ' <final>` (DECEFR `'w`, DECSLE `'{`, DECELR `'z`). The
      # `'` (0x27) intermediate byte mirrors `Rectangles#rectangle_op`'s `$`.
      private def locator_op(final : Char, *arguments)
        _print { |io| io << "\e["; arguments.join(io, ';'); io << '\'' << final }
      end
    end
  end
end
