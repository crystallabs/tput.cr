class Tput
  module Output
    module Emulator
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      # Sets terminal emulator's title.
      #
      # To change title without issuing an instruction to the terminal, use `#title=`.
      #
      #     OSC Ps ; Pt ST
      #     OSC Ps ; Pt BEL
      #       Set Text Parameters.
      def set_title(title)
        @_title = title

        # Disabled originally
        # if (term('screen')) {
        #   # Tmux pane
        #   # if (tmux) {
        #   #   _write('\x1b]2;' + title + '\x1b\\')
        #   # }
        #   _write('\x1bk' + title + '\x1b\\')
        # }

        _tprint "\x1b]0;#{title}\x07"
      end

      # Copies text to clipboard. Does nothing if terminal emulator is not iTerm2.
      #
      # This specificness could be circumvented by executing an external clipboard
      # program when this capability is missing.
      #
      # Example:
      #      unless copy_to_clipboard text
      #        exec_clipboard_program text
      #      end
      def copy_to_clipboard(text)
        if emulator.iterm2?
          _tprint "\x1b]50;CopyToCliboard=#{text}\x07"
          return true
        end
        false
      end

      # CSI > Ps; Ps t
      #   Set one or more features of the title modes.  Each parameter
      #   enables a single feature.
      #     Ps = 0  -> Set window/icon labels using hexadecimal.
      #     Ps = 1  -> Query window/icon labels using hexadecimal.
      #     Ps = 2  -> Set window/icon labels using UTF-8.
      #     Ps = 3  -> Query window/icon labels using UTF-8.  (See dis-
      #     cussion of "Title Modes")
      # XXX VTE bizarelly echos this:
      def set_title_mode_feature(*arguments)
        _tprint "\x1b[>#{arguments.join ';'}t"
      end

      # CSI > Ps; Ps T
      #   Reset one or more features of the title modes to the default
      #   value.  Normally, "reset" disables the feature.  It is possi-
      #   ble to disable the ability to reset features by compiling a
      #   different default for the title modes into xterm.
      #     Ps = 0  -> Do not set window/icon labels using hexadecimal.
      #     Ps = 1  -> Do not query window/icon labels using hexadeci-
      #     mal.
      #     Ps = 2  -> Do not set window/icon labels using UTF-8.
      #     Ps = 3  -> Do not query window/icon labels using UTF-8.
      #   (See discussion of "Title Modes").
      def reset_title_modes(*arguments)
        _print "\x1b[>#{arguments.join ';'}T"
      end

    end
  end
end
