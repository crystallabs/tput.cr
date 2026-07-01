class Tput
  module Output
    module Scrolling
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      # Moves the cursor one line down without changing column position, scrolling if needed.
      #
      #     ESC D Index (IND is 0x84).
      #
      # Aliases: ind, scroll_forward
      def index
        _x, y = _adjust_xy_rel 0, 1
        @cursor.y += y
        put(&.ind?) || _print "\eD"
      end

      alias_previous ind, scroll_forward

      # ESC M Reverse Index (RI is 0x8d).
      def reverse_index
        _x, y = _adjust_xy_rel 0, -1
        @cursor.y += y
        put(&.ri?) || _print "\eM"
      end

      alias_previous ri, reverse

      # CSI Ps S  Scroll up Ps lines (default = 1) (SU).
      def scroll_up(param = 1)
        # SU scrolls region content, not the cursor (ECMA-48/xterm: "active
        # presentation position is not changed"). Unlike IND (`#index`), do NOT
        # touch `@cursor` here — mutating it would desync the tracked cursor from
        # the terminal's real one, corrupting later relative moves.
        (!features.ansi_scroll? && put(&.parm_index?(param))) || _print { |io| io << "\e[" << param << "S" }
      end

      alias_previous su

      # CSI Ps T  Scroll down Ps lines (default = 1) (SD).
      def scroll_down(param = 1)
        # Like SU above: cursor position unchanged (ECMA-48/xterm), leave `@cursor` alone.
        (!features.ansi_scroll? && put(&.parm_rindex?(param))) || _print { |io| io << "\e[" << param << "T" }
      end

      alias_previous sd

      # Set scroll region.
      #
      #     CSI Ps ; Ps r
      #       Set Scrolling Region [top;bottom] (default = full size of win-
      #       dow) (DECSTBM).
      #     CSI ? Pm r
      #
      # NOTE: Uses absolute values; negative numbers count from the bottom of
      # the screen rather than clamping to 0.
      #
      # NOTE: No check that `top` is smaller than `bottom`.
      def set_scroll_region(top : Int = 0, bottom : Int = (@screen.height - 1))
        _, top = _adjust_xy_abs 0, top
        _, bottom = _adjust_xy_abs 0, bottom
        @scroll_top = top
        @scroll_bottom = bottom
        @cursor.x = 0
        @cursor.y = 0
        (!features.ansi_scroll? && put(&.csr?(top, bottom))) || _print { |io| io << "\e[" << top + 1 << ';' << bottom + 1 << 'r' }
      end

      alias_previous decstbm # , csr # <- don't alias to `csr`. Very confusing.
    end
  end
end
