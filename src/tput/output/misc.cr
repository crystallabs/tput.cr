class Tput
  module Output
    module Misc
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      def nul
        # Disabled originally
        # #if (has('pad')) return put.pad
        _print "\x80"
      end

      alias_previous pad

      # CSI Ps q  Load LEDs (DECLL).
      #     Ps = 0  -> Clear all LEDS (default).
      #     Ps = 1  -> Light Num Lock.
      #     Ps = 2  -> Light Caps Lock.
      #     Ps = 3  -> Light Scroll Lock.
      #     Ps = 2  1  -> Extinguish Num Lock.
      #     Ps = 2  2  -> Extinguish Caps Lock.
      #     Ps = 2  3  -> Extinguish Scroll Lock.
      def load_leds(param = 0)
        _print { |io| io << "\e[" << param << 'q' }
      end

      alias_previous decll

      # CSI Pm i  Media Copy (MC).
      #     Ps = 0  -> Print screen (default).
      #     Ps = 4  -> Turn off printer controller mode.
      #     Ps = 5  -> Turn on printer controller mode.
      # CSI ? Pm i
      #   Media Copy (MC, DEC-specific).
      #     Ps = 1  -> Print line containing cursor.
      #     Ps = 4  -> Turn off autoprint mode.
      #     Ps = 5  -> Turn on autoprint mode.
      #     Ps = 1  0  -> Print composed display, ignores DECPEX.
      #     Ps = 1  1  -> Print all pages.
      def media_copy(*arguments)
        _print "\e[#{arguments.join ';'}i"
      end

      alias_previous mc

      def mc0
        put(mc0?) || put(mc?(0)) || false
      end

      alias_previous print_screen, ps

      def mc5
        put(mc5?) || media_copy(5)
      end

      alias_previous prtr_on, po

      def mc4
        put(mc4?) || media_copy(4)
      end

      alias_previous prtr_off, pf

      def mc5p
        put(mc5p?) || media_copy("?5")
      end

      alias_previous prtr_non, p0
    end
  end
end
