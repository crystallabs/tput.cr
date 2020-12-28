class Tput
  module Output
    module Misc
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      def nul
        # Disabled originally
        ##if (has('pad')) return put.pad
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
      def load_leds(param="")
        _print { |io| io << "\x1b[" << param << 'q' }
      end
      alias_previous decll

    end
  end
end
