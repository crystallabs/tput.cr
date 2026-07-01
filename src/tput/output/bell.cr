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
        set_bell_volume param.value, 't'
      end

      alias_previous :decswbv=

      # CSI Ps SP u
      #   Set margin-bell volume (DECSMBV, VT520).
      #     Ps = 1  -> off.
      #     Ps = 2 , 3  or 4  -> low.
      #     Ps = 0 , 5 , 6 , 7 , or 8  -> high.
      def margin_bell_volume=(param : Volume)
        # DECSMBV differs from DECSWBV at Ps=0: for the margin bell, Ps=0 is
        # loudest and Ps=1 means off. Translate `Volume::Off` (0) to 1 so `Off`
        # actually silences the margin bell.
        value = param.off? ? 1 : param.value
        set_bell_volume value, 'u'
      end

      alias_previous :decsmbv=

      # Shared framing for the DEC bell-volume ops: `CSI Ps SP <final>`
      # (DECSWBV `SP t`, DECSMBV `SP u`).
      private def set_bell_volume(value, final : Char)
        _print { |io| io << "\e[" << value << ' ' << final }
      end
    end
  end
end
