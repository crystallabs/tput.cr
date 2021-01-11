class Tput
  module Output
    module Screen
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      def clear
        @cursor.x = 0
        @cursor.y = 0
        put(&.clear?) || _print "\e[H\e[J"
      end

      # CSI Ps J  Erase in Display (ED).
      #     Ps = 0  -> Erase Below (default).
      #     Ps = 1  -> Erase Above.
      #     Ps = 2  -> Erase All.
      #     Ps = 3  -> Erase Saved Lines (xterm).
      # CSI ? Ps J
      #   Erase in Display (DECSED).
      #     Ps = 0  -> Selective Erase Below (default).
      #     Ps = 1  -> Selective Erase Above.
      #     Ps = 2  -> Selective Erase All.
      def erase_in_display(param = Erase::Below)
        # Disabled originally
        # extended tput.E3 = ^[[3;J
        put(&.ed?(param.value)) || _print { |io| io << "\e[" << param.value << 'J' }
      end

      alias_previous ed

      def alternate_buffer
        @is_alt = true
        put(&.smcup?) && return
        return if name? "vt", "linux"
        set_mode "?47"
        set_mode "?1049"
      end

      alias_previous alternate, smcup

      def normal_buffer
        @is_alt = false
        put(&.rmcup?) && return
        reset_mode "?47"
        reset_mode "?1049"
      end

      alias_previous rmcup
    end
  end
end
