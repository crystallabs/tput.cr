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
        _print { |io| io << "\e["; arguments.join(io, ';'); io << "'w" }
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
        _print { |io| io << "\e["; arguments.join(io, ';'); io << "'{" }
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
        _print { |io| io << "\e["; arguments.join(io, ';'); io << "'z" }
      end

      alias_previous decelr

      # Enables xterm mouse reporting. We turn on:
      #   * 1000 - report button press and release
      #   * 1002 - additionally report motion while a button is held (drag)
      #   * 1003 - additionally report all motion
      #   * 1006 - SGR extended encoding (coordinates beyond column/row 223,
      #            and unambiguous press/release)
      #
      # 1006 is what makes `Tput::Input#listen` receive the modern `\e[<…M/m`
      # reports it prefers to parse. (Focus reporting, mode 1004, is left out.)
      def enable_mouse
        decset 1000
        decset 1002
        decset 1003
        decset 1006
      end

      # Disables the xterm mouse reporting modes enabled by `#enable_mouse`.
      def disable_mouse
        decrst 1000
        decrst 1002
        decrst 1003
        decrst 1006
      end
    end
  end
end
