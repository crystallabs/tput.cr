class Tput
  module Output
    module Terminal
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      # ESC c Full Reset (RIS).
      def reset
        @position.x = @position.y = 0
        put(s.rs1?) || put(s.ris?) || _write "\x1bc"
      end

      # CSI ! p   Soft terminal reset (DECSTR).
      # http:#vt100.net/docs/vt220-rm/table4-10.html
      def soft_reset
        # Disabled originally:
        #if (tput) put.init_2string()
        #if (tput) put.reset_2string()
        #_write('\x1b[!p')
        #_write('\x1b[!p\x1b[?3;4l\x1b[4l\x1b>'); # init
        put(s.rs2?) || _write "\x1b[!p\x1b[?3;4l\x1b[4l\x1b>" # reset
      end
      alias_previous decstr, rs2

      # CSI Pm h  Set Mode (SM).
      #     Ps = 2  -> Keyboard Action Mode (AM).
      #     Ps = 4  -> Insert Mode (IRM).
      #     Ps = 1 2  -> Send/receive (SRM).
      #     Ps = 2 0  -> Automatic Newline (LNM).
      # CSI ? Pm h
      #   DEC Private Mode Set (DECSET).
      #     Ps = 1  -> Application Cursor Keys (DECCKM).
      #     Ps = 2  -> Designate USASCII for character sets G0-G3
      #     (DECANM), and set VT100 mode.
      #     Ps = 3  -> 132 Column Mode (DECCOLM).
      #     Ps = 4  -> Smooth (Slow) Scroll (DECSCLM).
      #     Ps = 5  -> Reverse Video (DECSCNM).
      #     Ps = 6  -> Origin Mode (DECOM).
      #     Ps = 7  -> Wraparound Mode (DECAWM).
      #     Ps = 8  -> Auto-repeat Keys (DECARM).
      #     Ps = 9  -> Send Mouse X & Y on button press.  See the sec-
      #     tion Mouse Tracking.
      #     Ps = 1 0  -> Show toolbar (rxvt).
      #     Ps = 1 2  -> Start Blinking Cursor (att610).
      #     Ps = 1 8  -> Print form feed (DECPFF).
      #     Ps = 1 9  -> Set print extent to full screen (DECPEX).
      #     Ps = 2 5  -> Show Cursor (DECTCEM).
      #     Ps = 3 0  -> Show scrollbar (rxvt).
      #     Ps = 3 5  -> Enable font-shifting functions (rxvt).
      #     Ps = 3 8  -> Enter Tektronix Mode (DECTEK).
      #     Ps = 4 0  -> Allow 80 -> 132 Mode.
      #     Ps = 4 1  -> more(1) fix (see curses resource).
      #     Ps = 4 2  -> Enable Nation Replacement Character sets (DECN-
      #     RCM).
      #     Ps = 4 4  -> Turn On Margin Bell.
      #     Ps = 4 5  -> Reverse-wraparound Mode.
      #     Ps = 4 6  -> Start Logging.  This is normally disabled by a
      #     compile-time option.
      #     Ps = 4 7  -> Use Alternate Screen Buffer.  (This may be dis-
      #     abled by the titeInhibit resource).
      #     Ps = 6 6  -> Application keypad (DECNKM).
      #     Ps = 6 7  -> Backarrow key sends backspace (DECBKM).
      #     Ps = 1 0 0 0  -> Send Mouse X & Y on button press and
      #     release.  See the section Mouse Tracking.
      #     Ps = 1 0 0 1  -> Use Hilite Mouse Tracking.
      #     Ps = 1 0 0 2  -> Use Cell Motion Mouse Tracking.
      #     Ps = 1 0 0 3  -> Use All Motion Mouse Tracking.
      #     Ps = 1 0 0 4  -> Send FocusIn/FocusOut events.
      #     Ps = 1 0 0 5  -> Enable Extended Mouse Mode.
      #     Ps = 1 0 1 0  -> Scroll to bottom on tty output (rxvt).
      #     Ps = 1 0 1 1  -> Scroll to bottom on key press (rxvt).
      #     Ps = 1 0 3 4  -> Interpret "meta" key, sets eighth bit.
      #     (enables the eightBitInput resource).
      #     Ps = 1 0 3 5  -> Enable special modifiers for Alt and Num-
      #     Lock keys.  (This enables the numLock resource).
      #     Ps = 1 0 3 6  -> Send ESC   when Meta modifies a key.  (This
      #     enables the metaSendsEscape resource).
      #     Ps = 1 0 3 7  -> Send DEL from the editing-keypad Delete
      #     key.
      #     Ps = 1 0 3 9  -> Send ESC  when Alt modifies a key.  (This
      #     enables the altSendsEscape resource).
      #     Ps = 1 0 4 0  -> Keep selection even if not highlighted.
      #     (This enables the keepSelection resource).
      #     Ps = 1 0 4 1  -> Use the CLIPBOARD selection.  (This enables
      #     the selectToClipboard resource).
      #     Ps = 1 0 4 2  -> Enable Urgency window manager hint when
      #     Control-G is received.  (This enables the bellIsUrgent
      #     resource).
      #     Ps = 1 0 4 3  -> Enable raising of the window when Control-G
      #     is received.  (enables the popOnBell resource).
      #     Ps = 1 0 4 7  -> Use Alternate Screen Buffer.  (This may be
      #     disabled by the titeInhibit resource).
      #     Ps = 1 0 4 8  -> Save cursor as in DECSC.  (This may be dis-
      #     abled by the titeInhibit resource).
      #     Ps = 1 0 4 9  -> Save cursor as in DECSC and use Alternate
      #     Screen Buffer, clearing it first.  (This may be disabled by
      #     the titeInhibit resource).  This combines the effects of the 1
      #     0 4 7  and 1 0 4 8  modes.  Use this with terminfo-based
      #     applications rather than the 4 7  mode.
      #     Ps = 1 0 5 0  -> Set terminfo/termcap function-key mode.
      #     Ps = 1 0 5 1  -> Set Sun function-key mode.
      #     Ps = 1 0 5 2  -> Set HP function-key mode.
      #     Ps = 1 0 5 3  -> Set SCO function-key mode.
      #     Ps = 1 0 6 0  -> Set legacy keyboard emulation (X11R6).
      #     Ps = 1 0 6 1  -> Set VT220 keyboard emulation.
      #     Ps = 2 0 0 4  -> Set bracketed paste mode.
      # Modes:
      #   http://vt100.net/docs/vt220-rm/chapter4.html
      def set_mode(*arguments)
        param = arguments.join(';') || ""
        _write "\x1b[#{param}h"
      end
      alias_previous sm

      # CSI Pm l  Reset Mode (RM).
      #     Ps = 2  -> Keyboard Action Mode (AM).
      #     Ps = 4  -> Replace Mode (IRM).
      #     Ps = 1 2  -> Send/receive (SRM).
      #     Ps = 2 0  -> Normal Linefeed (LNM).
      # CSI ? Pm l
      #   DEC Private Mode Reset (DECRST).
      #     Ps = 1  -> Normal Cursor Keys (DECCKM).
      #     Ps = 2  -> Designate VT52 mode (DECANM).
      #     Ps = 3  -> 80 Column Mode (DECCOLM).
      #     Ps = 4  -> Jump (Fast) Scroll (DECSCLM).
      #     Ps = 5  -> Normal Video (DECSCNM).
      #     Ps = 6  -> Normal Cursor Mode (DECOM).
      #     Ps = 7  -> No Wraparound Mode (DECAWM).
      #     Ps = 8  -> No Auto-repeat Keys (DECARM).
      #     Ps = 9  -> Don't send Mouse X & Y on button press.
      #     Ps = 1 0  -> Hide toolbar (rxvt).
      #     Ps = 1 2  -> Stop Blinking Cursor (att610).
      #     Ps = 1 8  -> Don't print form feed (DECPFF).
      #     Ps = 1 9  -> Limit print to scrolling region (DECPEX).
      #     Ps = 2 5  -> Hide Cursor (DECTCEM).
      #     Ps = 3 0  -> Don't show scrollbar (rxvt).
      #     Ps = 3 5  -> Disable font-shifting functions (rxvt).
      #     Ps = 4 0  -> Disallow 80 -> 132 Mode.
      #     Ps = 4 1  -> No more(1) fix (see curses resource).
      #     Ps = 4 2  -> Disable Nation Replacement Character sets (DEC-
      #     NRCM).
      #     Ps = 4 4  -> Turn Off Margin Bell.
      #     Ps = 4 5  -> No Reverse-wraparound Mode.
      #     Ps = 4 6  -> Stop Logging.  (This is normally disabled by a
      #     compile-time option).
      #     Ps = 4 7  -> Use Normal Screen Buffer.
      #     Ps = 6 6  -> Numeric keypad (DECNKM).
      #     Ps = 6 7  -> Backarrow key sends delete (DECBKM).
      #     Ps = 1 0 0 0  -> Don't send Mouse X & Y on button press and
      #     release.  See the section Mouse Tracking.
      #     Ps = 1 0 0 1  -> Don't use Hilite Mouse Tracking.
      #     Ps = 1 0 0 2  -> Don't use Cell Motion Mouse Tracking.
      #     Ps = 1 0 0 3  -> Don't use All Motion Mouse Tracking.
      #     Ps = 1 0 0 4  -> Don't send FocusIn/FocusOut events.
      #     Ps = 1 0 0 5  -> Disable Extended Mouse Mode.
      #     Ps = 1 0 1 0  -> Don't scroll to bottom on tty output
      #     (rxvt).
      #     Ps = 1 0 1 1  -> Don't scroll to bottom on key press (rxvt).
      #     Ps = 1 0 3 4  -> Don't interpret "meta" key.  (This disables
      #     the eightBitInput resource).
      #     Ps = 1 0 3 5  -> Disable special modifiers for Alt and Num-
      #     Lock keys.  (This disables the numLock resource).
      #     Ps = 1 0 3 6  -> Don't send ESC  when Meta modifies a key.
      #     (This disables the metaSendsEscape resource).
      #     Ps = 1 0 3 7  -> Send VT220 Remove from the editing-keypad
      #     Delete key.
      #     Ps = 1 0 3 9  -> Don't send ESC  when Alt modifies a key.
      #     (This disables the altSendsEscape resource).
      #     Ps = 1 0 4 0  -> Do not keep selection when not highlighted.
      #     (This disables the keepSelection resource).
      #     Ps = 1 0 4 1  -> Use the PRIMARY selection.  (This disables
      #     the selectToClipboard resource).
      #     Ps = 1 0 4 2  -> Disable Urgency window manager hint when
      #     Control-G is received.  (This disables the bellIsUrgent
      #     resource).
      #     Ps = 1 0 4 3  -> Disable raising of the window when Control-
      #     G is received.  (This disables the popOnBell resource).
      #     Ps = 1 0 4 7  -> Use Normal Screen Buffer, clearing screen
      #     first if in the Alternate Screen.  (This may be disabled by
      #     the titeInhibit resource).
      #     Ps = 1 0 4 8  -> Restore cursor as in DECRC.  (This may be
      #     disabled by the titeInhibit resource).
      #     Ps = 1 0 4 9  -> Use Normal Screen Buffer and restore cursor
      #     as in DECRC.  (This may be disabled by the titeInhibit
      #     resource).  This combines the effects of the 1 0 4 7  and 1 0
      #     4 8  modes.  Use this with terminfo-based applications rather
      #     than the 4 7  mode.
      #     Ps = 1 0 5 0  -> Reset terminfo/termcap function-key mode.
      #     Ps = 1 0 5 1  -> Reset Sun function-key mode.
      #     Ps = 1 0 5 2  -> Reset HP function-key mode.
      #     Ps = 1 0 5 3  -> Reset SCO function-key mode.
      #     Ps = 1 0 6 0  -> Reset legacy keyboard emulation (X11R6).
      #     Ps = 1 0 6 1  -> Reset keyboard emulation to Sun/PC style.
      #     Ps = 2 0 0 4  -> Reset bracketed paste mode.
      def reset_mode(*arguments)
        param = arguments.join(';') || ""
        _write "\x1b[#{param}l"
      end
      alias_previous rm

      # CSI Ps$ p
      #   Request ANSI mode (DECRQM).  For VT300 and up, reply is
      #     CSI Ps; Pm$ y
      #   where Ps is the mode number as in RM, and Pm is the mode
      #   value:
      #     0 - not recognized
      #     1 - set
      #     2 - reset
      #     3 - permanently set
      #     4 - permanently reset
      def request_ansi_mode(param="")
        _write "\x1b[#{param}$p"
      end
      alias_previous decrqm
  
      # CSI ? Ps$ p
      #   Request DEC private mode (DECRQM).  For VT300 and up, reply is
      #     CSI ? Ps; Pm$ p
      #   where Ps is the mode number as in DECSET, Pm is the mode value
      #   as in the ANSI DECRQM.
      def request_private_mode(param="")
        _write "\x1b[?#{param}$p"
      end
      alias_previous decrqmp
  
      # CSI Ps ; Ps " p
      #   Set conformance level (DECSCL).  Valid values for the first
      #   parameter:
      #     Ps = 6 1  -> VT100.
      #     Ps = 6 2  -> VT200.
      #     Ps = 6 3  -> VT300.
      #   Valid values for the second parameter:
      #     Ps = 0  -> 8-bit controls.
      #     Ps = 1  -> 7-bit controls (always set for VT100).
      #     Ps = 2  -> 8-bit controls.
      def set_conformance_level(*arguments)
        _write "\x1b[#{arguments.join ';'}\"p"
      end
      alias_previous decscl

      def decset(*arguments)
        set_mode "?#{arguments.join ';'}"
      end

      def decrst(*arguments)
        reset_mode "?#{arguments.join ';'}"
      end


    end
  end
end
