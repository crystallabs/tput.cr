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
      def reverseIndex
        @cursor.y -= 1
        _ncoords
        put(&.ri?) || _print "\eM"
      end

      alias_previous ri, reverse

      # CSI Ps S  Scroll up Ps lines (default = 1) (SU).
      def scroll_up(param = 1)
        @cursor.y -= param
        _ncoords
        put(&.parm_index?(param)) || _print { |io| io << "\e[" << param << "S" }
      end

      alias_previous su

      # CSI Ps T  Scroll down Ps lines (default = 1) (SD).
      def scroll_down(param = 1)
        @cursor.y += param
        _ncoords
        put(&.parm_rindex?(param)) || _print { |io| io << "\e[" << param << "T" }
      end

      alias_previous sd

      # Set scroll region.
      #
      #     CSI Ps ; Ps r
      #       Set Scrolling Region [top;bottom] (default = full size of win-
      #       dow) (DECSTBM).
      #     CSI ? Pm r
      #
      # NOTE: This function uses absolute values, so negative numbers
      # are not brought back to 0, but instead count from the bottom of the
      # screen up.
      #
      # NOTE: Similarly, there is no checking that the `top` value is
      # smaller than `bottom`.
      def set_scroll_region(top : Int = 0, bottom : Int = (@screen.height - 1))
        _, top = _adjust_xy_abs 0, top
        _, bottom = _adjust_xy_abs 0, bottom
        @scroll_top = top
        @scroll_bottom = bottom
        @cursor.x = 0
        @cursor.y = 0
        put(&.csr?(top, bottom)) || _print { |io| io << "\e[" << top + 1 << ';' << bottom + 1 << 'r' }
      end

      alias_previous decstbm, csr
    end
  end
end
