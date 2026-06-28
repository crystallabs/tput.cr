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
          _tprint "\e]50;CopyToClipboard=#{text}\x07"
          return true
        end
        false
      end

      # OSC 52: sets the terminal clipboard *selection* to *text*
      # (base64-encoded as the protocol requires). *selection* is `"c"` for the
      # clipboard, `"p"` for primary, etc. Unlike OS-level clipboard tools this
      # works through SSH and tmux. Read it back with `#get_clipboard`. Harmless
      # on terminals that don't support OSC 52 (they ignore it).
      def set_clipboard(text : String, selection : String = "c") : Nil
        _tprint "\e]52;#{selection};#{Base64.strict_encode text}\x07"
      end

      # OSC 52: clears the terminal clipboard *selection*.
      def clear_clipboard(selection : String = "c") : Nil
        _tprint "\e]52;#{selection};\x07"
      end

      # OSC 52: asks the terminal to report the clipboard *selection* without
      # waiting for the reply (`\e]52;<sel>;?\a`). Use this while `#listen` is
      # active — the reply arrives through the input stream and is surfaced as a
      # paste. (`Response#get_clipboard` is the synchronous counterpart, for use
      # outside the input loop.)
      def request_clipboard(selection : String = "c") : Nil
        _tprint "\e]52;#{selection};?\x07"
      end

      # OSC 8: begins a hyperlink to *uri*. Text emitted until `#end_hyperlink`
      # (or the next `#begin_hyperlink`) is clickable. *id* groups links that
      # should highlight as one when the pointer hovers any part — use the same
      # *id* for a link split across cells/lines. Widely supported (VTE, kitty,
      # iTerm2, WezTerm, foot, …) and ignored elsewhere.
      def begin_hyperlink(uri : String, id : String? = nil) : Nil
        _tprint "\e]8;#{id ? "id=#{id}" : ""};#{uri}\e\\"
      end

      # OSC 8: ends the current hyperlink (empty URI), so following text is no
      # longer clickable.
      def end_hyperlink : Nil
        _tprint "\e]8;;\e\\"
      end

      # OSC 8: emits *text* as a hyperlink to *uri* (begin + text + end).
      def hyperlink(text : String, uri : String, id : String? = nil) : Nil
        begin_hyperlink uri, id
        # The *display* text is ordinary content and must be printed normally —
        # NOT routed through `_tprint`. Only the OSC 8 begin/end markers are
        # escape sequences that need the multiplexer's DCS passthrough; wrapping
        # the text in it too (under tmux/screen) would hand the characters to the
        # *outer* terminal instead of rendering them in the pane, so the link's
        # label would vanish from the multiplexed screen.
        _print text
        end_hyperlink
      end

      # OSC 7: reports *path* to the terminal as the current working directory
      # (as a `file://` URI), so terminals that track cwd — "open new tab/split
      # here", window/tab titles — follow along. *host* is the URI host (empty =
      # local). Routed through tmux's DCS passthrough; ignored where unsupported.
      def report_cwd(path : String, host : String = "") : Nil
        _tprint "\e]7;file://#{host}#{path}\x07"
      end

      # OSC 9;4: drives the terminal's progress indicator (taskbar / tab badge).
      # *state*: 0 = clear, 1 = normal (show *progress*, 0–100), 2 = error,
      # 3 = indeterminate, 4 = warning/paused. Supported by ConEmu, Windows
      # Terminal, WezTerm, ghostty, … and ignored elsewhere.
      def progress(progress : Int32 = 0, state : Int32 = 1) : Nil
        _tprint "\e]9;4;#{state};#{progress}\x07"
      end

      # Begins a synchronized update (DEC private mode 2026): the terminal holds
      # off presenting output until `#end_synchronized_update`, then repaints the
      # whole frame at once — removing the flicker/tearing of a multi-write
      # redraw. Harmless on terminals that don't support it (they ignore it, and
      # also auto-release after a short timeout so a missing end can't freeze the
      # screen). Prefer the `#synchronized_update` block, which always pairs the
      # end marker.
      def begin_synchronized_update : Nil
        _tprint "\e[?2026h"
      end

      # Ends a synchronized update (DEC 2026), presenting the buffered frame.
      def end_synchronized_update : Nil
        _tprint "\e[?2026l"
      end

      # Brackets *block*'s output in a synchronized update (DEC 2026) so the
      # frame it draws is presented atomically. The end marker is emitted even if
      # the block raises, so a failure cannot leave the terminal frozen.
      def synchronized_update(&)
        begin_synchronized_update
        begin
          yield
        ensure
          end_synchronized_update
        end
      end

      # Enables Unicode grapheme clustering (DEC private mode 2027): the terminal
      # advances the cursor by *grapheme cluster* (emoji ZWJ sequences, a base +
      # combining marks, regional-indicator flags) rather than by codepoint —
      # matching this library's `full_unicode` cell model, so wide/clustered
      # glyphs stay aligned. Harmless on terminals that don't support it.
      def enable_grapheme_clustering : Nil
        _tprint "\e[?2027h"
      end

      # Disables Unicode grapheme clustering (DEC 2027).
      def disable_grapheme_clustering : Nil
        _tprint "\e[?2027l"
      end

      # Enables color-scheme (light/dark) change notifications (DEC private mode
      # 2031). The terminal then reports theme changes in-band as
      # `CSI ? 997 ; 1 n` (dark) / `CSI ? 997 ; 2 n` (light), surfaced as the
      # `color_scheme` of `Tput::Input#listen` events. Query the current scheme
      # with `#request_color_scheme`. Harmless on terminals that don't support it.
      def enable_color_scheme_notifications : Nil
        _tprint "\e[?2031h"
      end

      # Disables color-scheme change notifications (DEC 2031).
      def disable_color_scheme_notifications : Nil
        _tprint "\e[?2031l"
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
        _tprint "\e[>#{arguments.join ';'}T"
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
        _print { |io| io << "\e[>"; arguments.join(io, ";"); io << "m" }
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
