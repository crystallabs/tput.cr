class Tput
  module Output
    module Colors
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      # Already in cursor.cr, with better names.
      #
      # # OSC Ps ; Pt ST
      # # OSC Ps ; Pt BEL
      # #   Reset colors
      # def reset_colors(param)
      #  put(&._Cr?(param)) || _twrite "\e]112\x07"
      #  # Why not?
      #  #_twrite "\e]112;" + param + "\x07"
      # end

      # # OSC Ps ; Pt ST
      # # OSC Ps ; Pt BEL
      # #   Change dynamic colors
      # def dynamic_colors(param)
      #  put(&._Cs?(param)) || _twrite { |io| io << "\e]12;" << param << "\x07" }
      # end
    end
  end
end
