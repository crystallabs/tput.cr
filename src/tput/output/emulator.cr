class Tput
  module Output
    module Emulator
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      # Sets terminal emulator's title.
      #
      # To change title without issuing an instruction to the terminal, use `#title=`.
      #
      #     OSC Ps ; Pt ST
      #     OSC Ps ; Pt BEL
      #       Set Text Parameters.
      def title=(title)
        @_title = title

        # D O:
        # if (term('screen')) {
        #   # Tmux pane
        #   # if (tmux) {
        #   #   _write('\e]2;' + title + '\e\\')
        #   # }
        #   _write('\ek' + title + '\e\\')
        # }

        _tprint "\e]0;#{title}\x07"
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
          _tprint "\e]50;CopyToCliboard=#{text}\x07"
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
        _tprint "\e[>#{arguments.join ';'}t"
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
        _print "\e[>#{arguments.join ';'}T"
      end

      # CSI > Ps; Ps m
      #   Set or reset resource-values used by xterm to decide whether
      #   to construct escape sequences holding information about the
      #   modifiers pressed with a given key.  The first parameter iden-
      #   tifies the resource to set/reset.  The second parameter is the
      #   value to assign to the resource.  If the second parameter is
      #   omitted, the resource is reset to its initial value.
      #     Ps = 1  -> modifyCursorKeys.
      #     Ps = 2  -> modifyFunctionKeys.
      #     Ps = 4  -> modifyOtherKeys.
      #   If no parameters are given, all resources are reset to their
      #   initial values.
      def set_resources(*arguments)
        _print { |io| "\e[>"; arguments.join(io, ";"); io << "m" }
      end

      # CSI > Ps n
      #   Disable modifiers which may be enabled via the CSI > Ps; Ps m
      #   sequence.  This corresponds to a resource value of "-1", which
      #   cannot be set with the other sequence.  The parameter identi-
      #   fies the resource to be disabled:
      #     Ps = 1  -> modifyCursorKeys.
      #     Ps = 2  -> modifyFunctionKeys.
      #     Ps = 4  -> modifyOtherKeys.
      #   If the parameter is omitted, modifyFunctionKeys is disabled.
      #   When modifyFunctionKeys is disabled, xterm uses the modifier
      #   keys to make an extended sequence of functions rather than
      #   adding a parameter to each function key to denote the modi-
      #   fiers.
      def disable_modifiers(param = "")
        _print { |io| io << "\e[>" << param << 'n' }
      end

      # CSI > Ps p
      #   Set resource value pointerMode.  This is used by xterm to
      #   decide whether to hide the pointer cursor as the user types.
      #   Valid values for the parameter:
      #     Ps = 0  -> never hide the pointer.
      #     Ps = 1  -> hide if the mouse tracking mode is not enabled.
      #     Ps = 2  -> always hide the pointer.  If no parameter is
      #     given, xterm uses the default, which is 1 .
      def set_pointer_mode(param = "")
        _print { |io| io << "\e[>" << param << 'p' }
      end
    end
  end
end
