class Tput
  module Output
    module Screen
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      def clear
        @position.x = 0
        @position.y = 0
        put(clear?) || _print "\x1b[H\x1b[J"
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
      def erase_in_display(param=nil)
        @shim.try { |shim|
          case (param)
            when "above"
              param = 1
            when "all"
              param = 2
            when "saved"
              param = 3
            when "below"
              param = 0
            else
              param = 0
          end
          # Disabled originally
          # extended tput.E3 = ^[[3;J
          put(ed?(param))
        } ||

        case param
          when "above"
            _print "\X1b[1J"
          when "all"
            _print "\x1b[2J"
          when "saved"
            _print "\x1b[3J"
          when "below"
            _print "\x1b[J"
          else
            _print "\x1b[J"
        end
      end
      alias_previous ed

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
        _print "\x1b[#{arguments.join ';'}i"
      end
      alias_previous mc

      def mc0
        put(mc0?) || put(mc?(0))
      end
      alias_previous print_screen, ps

      def alternate_buffer
        @is_alt = true
        put(smcup?) && return
        return if name? "vt", "linux"
        set_mode "?47"
        set_mode "?1049"
      end
      alias_previous alternate, smcup

      def normal_buffer
        @is_alt = false
        put(rmcup?) && return
        reset_mode "?47"
        reset_mode "?1049"
      end
      alias_previous rmcup

    end
  end
end
