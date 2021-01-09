class Tput
  module Output
    module Rectangles
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      # CSI Pt; Pl; Pb; Pr; Ps$ r
      #   Change Attributes in Rectangular Area (DECCARA), VT400 and up.
      #     Pt; Pl; Pb; Pr denotes the rectangle.
      #     Ps denotes the SGR attributes to change: 0, 1, 4, 5, 7.
      # NOTE: xterm doesn't enable this code by default.
      def set_attr_in_rectangle(*arguments)
        _print "\e[#{arguments.join ';'}$r"
      end

      alias_previous deccara

      # CSI Pt; Pl; Pb; Pr; Ps$ t
      #   Reverse Attributes in Rectangular Area (DECRARA), VT400 and
      #   up.
      #     Pt; Pl; Pb; Pr denotes the rectangle.
      #     Ps denotes the attributes to reverse, i.e.,  1, 4, 5, 7.
      # NOTE: xterm doesn't enable this code by default.
      def reverse_attr_in_rectangle(*arguments)
        _print "\e[#{arguments.join ';'}$t"
      end

      alias_previous decrara

      # CSI Pt; Pl; Pb; Pr; Pp; Pt; Pl; Pp$ v
      #   Copy Rectangular Area (DECCRA, VT400 and up).
      #     Pt; Pl; Pb; Pr denotes the rectangle.
      #     Pp denotes the source page.
      #     Pt; Pl denotes the target location.
      #     Pp denotes the target page.
      # NOTE: xterm doesn't enable this code by default.
      def copy_rectangle(*arguments)
        _print "\e[#{arguments.join ';'}$v"
      end

      alias_previous deccra

      # CSI Ps x  Select Attribute Change Extent (DECSACE).
      #     Ps = 0  -> from start to end position, wrapped.
      #     Ps = 1  -> from start to end position, wrapped.
      #     Ps = 2  -> rectangle (exact).
      def select_change_extent(param = 0)
        _print "\e[#{param}x"
      end

      alias_previous decsace

      # CSI Pc; Pt; Pl; Pb; Pr$ x
      #   Fill Rectangular Area (DECFRA), VT420 and up.
      #     Pc is the character to use.
      #     Pt; Pl; Pb; Pr denotes the rectangle.
      # NOTE: xterm doesn't enable this code by default.
      def fill_rectangle(*arguments)
        _print "\e[#{arguments.join ';'}$x"
      end

      alias_previous decfra

      # CSI Pt; Pl; Pb; Pr$ z
      #   Erase Rectangular Area (DECERA), VT400 and up.
      #     Pt; Pl; Pb; Pr denotes the rectangle.
      # NOTE: xterm doesn't enable this code by default.
      def erase_rectangle(*arguments)
        _print "\e[#{arguments.join ';'}$z"
      end

      alias_previous decera

      # CSI Pt; Pl; Pb; Pr$ {
      #   Selective Erase Rectangular Area (DECSERA), VT400 and up.
      #     Pt; Pl; Pb; Pr denotes the rectangle.
      def selective_erase_rectangle(*arguments)
        _print "\e[#{arguments.join ';'}${"
      end

      alias_previous decsera
    end
  end
end
