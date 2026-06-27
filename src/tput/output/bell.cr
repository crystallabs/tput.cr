class Tput
  module Output
    module Bell
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      # Ring the bell.
      #
      # TODO The bell is further subject to style and sound.
      #
      # Aliases: bel
      def bell
        put(&.bel?) || _print "\a" # "\x07"
      end

      alias_previous bel

      # CSI Ps SP t
      #   Set warning-bell volume (DECSWBV, VT520).
      #     Ps = 0  or 1  -> off.
      #     Ps = 2 , 3  or 4  -> low.
      #     Ps = 5 , 6 , 7 , or 8  -> high.
      def warning_bell_volume=(param : Volume)
        _print { |io| io << "\e[" << param.value << " t" }
      end

      alias_previous :decswbv=

      # CSI Ps SP u
      #   Set margin-bell volume (DECSMBV, VT520).
      #     Ps = 1  -> off.
      #     Ps = 2 , 3  or 4  -> low.
      #     Ps = 0 , 5 , 6 , 7 , or 8  -> high.
      def margin_bell_volume=(param : Volume)
        # DECSMBV differs from DECSWBV at Ps=0: for the margin bell Ps=0 is the
        # *loudest* setting, while Ps=1 means "off". Translate the silent
        # `Volume::Off` (value 0) to 1 so that asking for `Off` actually silences
        # the margin bell, keeping the enum's intent consistent across both bells.
        value = param.off? ? 1 : param.value
        _print { |io| io << "\e[" << value << " u" }
      end

      alias_previous :decsmbv=
    end
  end
end
