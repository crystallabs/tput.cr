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
        rectangle_op 'r', *arguments
      end

      alias_previous deccara

      # CSI Pt; Pl; Pb; Pr; Ps$ t
      #   Reverse Attributes in Rectangular Area (DECRARA), VT400 and
      #   up.
      #     Pt; Pl; Pb; Pr denotes the rectangle.
      #     Ps denotes the attributes to reverse, i.e.,  1, 4, 5, 7.
      # NOTE: xterm doesn't enable this code by default.
      def reverse_attr_in_rectangle(*arguments)
        rectangle_op 't', *arguments
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
        rectangle_op 'v', *arguments
      end

      alias_previous deccra

      # CSI Ps * x  Select Attribute Change Extent (DECSACE), VT420 and up.
      #     Ps = 0  -> from start to end position, wrapped.
      #     Ps = 1  -> from start to end position, wrapped.
      #     Ps = 2  -> rectangle (exact).
      #
      # The `*` (0x2A) intermediate byte is mandatory: without it the terminal
      # parses `CSI Ps x` as DECREQTPARM (Request Terminal Parameters), triggering
      # an unsolicited parameter report instead of selecting the change extent.
      def select_change_extent(param = 0)
        _print "\e[#{param}*x"
      end

      alias_previous decsace

      # CSI Pc; Pt; Pl; Pb; Pr$ x
      #   Fill Rectangular Area (DECFRA), VT420 and up.
      #     Pc is the character to use.
      #     Pt; Pl; Pb; Pr denotes the rectangle.
      # NOTE: xterm doesn't enable this code by default.
      def fill_rectangle(*arguments)
        rectangle_op 'x', *arguments
      end

      alias_previous decfra

      # Shared framing for the DEC rectangle ops that take coordinate/parameter
      # args: `CSI Pt;Pl;Pb;Pr[;…] $ <final>` (DECCARA `$r`, DECRARA `$t`,
      # DECCRA `$v`, DECFRA `$x`).
      private def rectangle_op(final : Char, *arguments)
        _print { |io| io << "\e["; arguments.join(io, ';'); io << '$' << final }
      end

      # Shared framing for the DEC erase-rectangle ops that take explicit
      # coordinates with the standard 1-based (`+1`) conversion and screen-sized
      # defaults: `CSI Pt;Pl;Pb;Pr $ <final>` (DECERA `$z`, DECSERA `${`).
      # Distinct from `rectangle_op` above, which joins raw splat arguments.
      private def erase_rectangle_op(final : String, top, left, bottom, right)
        _print { |io| io << "\e[" << (top + 1) << ';' << (left + 1) << ';' << (bottom + 1) << ';' << (right + 1) << final }
      end

      # Erases characters from the specified rectangular area in page memory.
      # When an area is erased, all character positions are replaced with the space character.
      # Character values and visual attributes from the specified area are erased.
      # Line attributes are not erased.
      #
      #     CSI Pt; Pl; Pb; Pr$ z
      #       Erase Rectangular Area (DECERA), VT400 and up.
      #         Pt; Pl; Pb; Pr denotes the rectangle.
      #
      # NOTE: xterm doesn't enable this code by default.
      #
      # Aliases: decera
      def erase_rectangle(top = 0, left = 0, bottom = @screen.height - 1, right = @screen.width - 1)
        erase_rectangle_op "$z", top, left, bottom, right
      end

      alias_previous decera

      # Erases all erasable characters from a specified rectangular area in page memory.
      # The select character protection attribute (DECSCA) control function defines whether
      # or not DECSERA can erase characters.
      #
      # When an area is erased, DECSERA replaces character positions with the space character (2/0). DECSERA does not change:
      # - Visual attributes set by the select graphic rendition (SGR) function
      # - Protection attributes set by DECSCA
      # - Line attributes
      #
      # The coordinates of the rectangular area are affected by the setting of origin mode (DECOM).
      # Method is not affected by the page margins.
      #
      #     CSI Pt; Pl; Pb; Pr$ {
      #       Selective Erase Rectangular Area (DECSERA), VT400 and up.
      #         Pt; Pl; Pb; Pr denotes the rectangle.
      #
      # Aliases: decsera
      def selective_erase_rectangle(top = 0, left = 0, bottom = @screen.height - 1, right = @screen.width - 1)
        erase_rectangle_op "${", top, left, bottom, right
      end

      alias_previous decsera
    end
  end
end
