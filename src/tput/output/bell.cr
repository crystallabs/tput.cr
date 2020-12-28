class Tput
  module Output
    module Bell
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      def bell
        put(bel?) || _write "\x07"
      end
      alias_previous bel

      # CSI Ps SP t
      #   Set warning-bell volume (DECSWBV, VT520).
      #     Ps = 0  or 1  -> off.
      #     Ps = 2 , 3  or 4  -> low.
      #     Ps = 5 , 6 , 7 , or 8  -> high.
      def set_warning_bell_volume(param="")
        _write "\x1b[#{param || ""} t"
      end
      alias_previous decswbv

      # CSI Ps SP u
      #   Set margin-bell volume (DECSMBV, VT520).
      #     Ps = 1  -> off.
      #     Ps = 2 , 3  or 4  -> low.
      #     Ps = 0 , 5 , 6 , 7 , or 8  -> high.
      def set_margin_bell_volume(param="")
        _write "\x1b[#{param} u"
      end
      alias_previous decsmbv

    end
  end
end
