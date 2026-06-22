class Tput
  module Output
    module Colors
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      # Resets the terminal's dynamic colors back to their defaults.
      #
      # Uses the terminal's `Cr` capability when defined, falling back to the
      # hardcoded xterm sequence `OSC 112 BEL`.
      #
      #     OSC Ps ; Pt ST
      #     OSC Ps ; Pt BEL
      #       Reset colors
      #
      # NOTE: this emits the same sequence as `Cursor#reset_cursor_color`; both
      # names are kept for parity with the upstream API.
      def reset_colors(param = "")
        put_extended("Cr", param) || _tprint("\e]112\x07")
      end

      # Changes the terminal's dynamic colors. *param* is the color spec (e.g.
      # an `rgb:RRRR/GGGG/BBBB` string or an X11 color name).
      #
      # Uses the terminal's `Cs` capability when defined, falling back to the
      # hardcoded xterm sequence `OSC 12 ; Pt BEL`.
      #
      #     OSC Ps ; Pt ST
      #     OSC Ps ; Pt BEL
      #       Change dynamic colors
      def dynamic_colors(param)
        put_extended("Cs", param) || _tprint("\e]12;#{param}\x07")
      end
    end
  end
end
