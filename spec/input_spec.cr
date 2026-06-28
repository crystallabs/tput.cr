# End-to-end input parsing: feeds canned bytes through `Tput::Input#listen`
# (exercising `Tput::Key.read_control` + `read_mouse` + `Tput::Mouse`) and
# collects the decoded events. `IO::Memory` is not a tty, so `with_raw_input`
# is a no-op and reads return immediately, ending the loop at EOF.

private def feed(data : String)
  events = [] of {Char, Tput::Key?, Tput::Mouse::Event?}
  t = Tput.new \
    input: IO::Memory.new(data),
    output: IO::Memory.new,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false
  t.listen do |e|
    events << {e.char, e.key, e.mouse}
  end
  events
end

private def one_key(data : String) : Tput::Key?
  ev = feed data
  ev.size.should eq 1
  ev[0][1]
end

private def one_mouse(data : String) : Tput::Mouse::Event?
  ev = feed data
  ev.size.should eq 1
  ev[0][2]
end

private def feed_paste(data : String) : Array(String)
  pastes = [] of String
  t = Tput.new \
    input: IO::Memory.new(data),
    output: IO::Memory.new,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false
  t.listen { |e| pastes << e.paste.not_nil! if e.paste? }
  pastes
end

describe Tput::Input do
  describe "key parsing" do
    it "parses CSI cursor keys" do
      one_key("\e[A").should eq Tput::Key::Up
      one_key("\e[B").should eq Tput::Key::Down
      one_key("\e[C").should eq Tput::Key::Right
      one_key("\e[D").should eq Tput::Key::Left
      one_key("\e[H").should eq Tput::Key::Home
      one_key("\e[F").should eq Tput::Key::End
    end

    it "parses SS3 cursor/function keys" do
      one_key("\eOA").should eq Tput::Key::Up
      one_key("\eOH").should eq Tput::Key::Home
      one_key("\eOP").should eq Tput::Key::F1
    end

    it "parses navigation tilde keys" do
      one_key("\e[1~").should eq Tput::Key::Home
      one_key("\e[2~").should eq Tput::Key::Insert
      one_key("\e[3~").should eq Tput::Key::Delete
      one_key("\e[4~").should eq Tput::Key::End
      one_key("\e[5~").should eq Tput::Key::PageUp
      one_key("\e[6~").should eq Tput::Key::PageDown
    end

    it "parses function keys F5-F12" do
      one_key("\e[15~").should eq Tput::Key::F5
      one_key("\e[17~").should eq Tput::Key::F6
      one_key("\e[20~").should eq Tput::Key::F9
      one_key("\e[24~").should eq Tput::Key::F12
    end

    it "parses modified cursor keys" do
      one_key("\e[1;2A").should eq Tput::Key::ShiftUp
      one_key("\e[1;3B").should eq Tput::Key::AltDown
      one_key("\e[1;5C").should eq Tput::Key::CtrlRight
    end

    it "parses ShiftTab" do
      one_key("\e[Z").should eq Tput::Key::ShiftTab
    end

    it "parses F13-F20 (extended xterm codes)" do
      one_key("\e[25~").should eq Tput::Key::F13
      one_key("\e[26~").should eq Tput::Key::F14
      one_key("\e[28~").should eq Tput::Key::F15
      one_key("\e[31~").should eq Tput::Key::F17
      one_key("\e[34~").should eq Tput::Key::F20
      one_key("\e[29~").should eq Tput::Key::Menu # 29 is Menu, not F16
    end

    it "parses the modifier matrix on navigation keys" do
      one_key("\e[2;2~").should eq Tput::Key::ShiftInsert
      one_key("\e[3;5~").should eq Tput::Key::CtrlDelete
      one_key("\e[3;3~").should eq Tput::Key::AltDelete
      one_key("\e[5;5~").should eq Tput::Key::CtrlPageUp
      one_key("\e[1;5H").should eq Tput::Key::CtrlHome # letter form
      one_key("\e[1;2F").should eq Tput::Key::ShiftEnd
    end

    it "parses rxvt shift/ctrl cursor and nav variants" do
      one_key("\e[a").should eq Tput::Key::ShiftUp
      one_key("\e[d").should eq Tput::Key::ShiftLeft
      one_key("\eOa").should eq Tput::Key::CtrlUp
      one_key("\eOd").should eq Tput::Key::CtrlLeft
      one_key("\e[3$").should eq Tput::Key::ShiftDelete
      one_key("\e[3^").should eq Tput::Key::CtrlDelete
      one_key("\e[7~").should eq Tput::Key::Home # rxvt home
      one_key("\e[8~").should eq Tput::Key::End  # rxvt end
    end

    it "parses rxvt F1-F4 and putty/Cygwin function keys" do
      one_key("\e[11~").should eq Tput::Key::F1
      one_key("\e[14~").should eq Tput::Key::F4
      one_key("\e[[A").should eq Tput::Key::F1 # Cygwin
      one_key("\e[[E").should eq Tput::Key::F5
      one_key("\e[[5~").should eq Tput::Key::PageUp # putty
      one_key("\e[[6~").should eq Tput::Key::PageDown
    end

    it "parses the Clear key" do
      one_key("\e[E").should eq Tput::Key::Clear
      one_key("\eOE").should eq Tput::Key::Clear
    end

    it "parses Alt+letter across the whole a-z range" do
      one_key("\ea").should eq Tput::Key::AltA
      one_key("\em").should eq Tput::Key::AltM
      one_key("\ez").should eq Tput::Key::AltZ
    end

    it "fully consumes a private DECRPM reply ending in an intermediate byte" do
      # `\e[?2026;1$y` (a DECRPM reply to a DECRQM mode query) ends in `$ y`,
      # where `$` is a CSI intermediate byte and `y` the real final. The whole
      # sequence must be consumed; truncating at `$` would leave `y` to surface
      # as a phantom keystroke.
      feed("\e[?2026;1$y").should be_empty
    end

    it "fully consumes a non-private DECRPM reply ending in an intermediate byte" do
      # `\e[4;1$y` is the reply to a *non-private* DECRQM query
      # (`#request_ansi_mode`/`decrqm`): mode 4 (IRM) reported as set. Like the
      # private form it ends in `$ y`, where `$` is a CSI intermediate byte and
      # `y` the real final, but it reaches the numeric (non-`?`) CSI path.
      # Treating `$` as the final would leave `y` to surface as a phantom
      # keystroke and mis-decode the reply as Shift+End — the whole sequence
      # must be consumed.
      feed("\e[4;1$y").should be_empty
    end

    it "fully consumes a secondary device-attributes (DA2) reply" do
      # `\e[>0;276;0c` is the DA2 reply (`CSI > Pp ; Pv ; Pc c`). The `>` prefix
      # introduces no key, but if it arrives mid-`listen` the whole parameter
      # list and final `c` must be consumed; truncating at `>` would leak
      # `0;276;0c` as a burst of phantom keystrokes.
      feed("\e[>0;276;0c").should be_empty
    end

    it "does not mistake C1 control characters for AltEnter/ShiftTab" do
      # U+0080/U+0081 are C1 controls (arriving as UTF-8 0xC2 0x80 / 0xC2 0x81);
      # their codepoints 128/129 must not collide with the auto-numbered
      # AltEnter(128)/ShiftTab(129) enum members.
      one_key("\u0080").should be_nil
      one_key("\u0081").should be_nil
    end
  end

  describe "mouse parsing" do
    it "parses SGR press/release" do
      m = one_mouse("\e[<0;10;20M").not_nil!
      m.action.should eq Tput::Mouse::Action::Down
      m.button.should eq Tput::Mouse::Button::Left
      m.x.should eq 9
      m.y.should eq 19
      one_mouse("\e[<0;10;20m").not_nil!.action.should eq Tput::Mouse::Action::Up
    end

    it "parses SGR wheel and motion" do
      one_mouse("\e[<64;5;5M").not_nil!.action.should eq Tput::Mouse::Action::WheelUp
      one_mouse("\e[<65;5;5M").not_nil!.action.should eq Tput::Mouse::Action::WheelDown
      m = one_mouse("\e[<35;5;5M").not_nil!
      m.action.should eq Tput::Mouse::Action::Move
    end

    it "parses SGR modifiers" do
      m = one_mouse("\e[<4;1;1M").not_nil! # shift bit
      m.shift?.should be_true
      m = one_mouse("\e[<16;1;1M").not_nil! # ctrl bit
      m.ctrl?.should be_true
    end

    it "parses X10 / normal encoding" do
      m = one_mouse("\e[M\x20\x21\x22").not_nil!
      m.button.should eq Tput::Mouse::Button::Left
      m.x.should eq 0
      m.y.should eq 1
    end

    it "corrects the VTE coordinate overflow in X10 (mod-256 unwrap)" do
      # VTE sends coordinates as unsigned bytes, so a `+32`-biased byte past 255
      # wraps modulo 256 and lands below the 0x20 floor. Byte 0x10 (16) is such
      # an overflow: its true biased byte is 16 + 256 = 272, i.e. column 240
      # (1-based) -> cell 239 (0-based). Unwrapping by a full 256 (not 0xff, which
      # lands one cell short at 238) recovers the correct cell.
      m = one_mouse("\e[M\x20\x10\x22").not_nil!
      m.x.should eq 239
      m.x.should eq (0x10 + 256) - 0x20 - 1
    end

    it "reads X10 coordinate bytes raw, not UTF-8 decoded" do
      # A column past 95 sends a byte >= 0x80; read as a byte it survives intact
      # (run through `read_char` it would be mangled into U+FFFD).
      io = IO::Memory.new
      io.write Bytes[0x1bu8, '['.ord.to_u8, 'M'.ord.to_u8, 0x20u8, 0xc8u8, 0x22u8]
      io.rewind
      t = Tput.new \
        input: io,
        output: IO::Memory.new,
        screen_size: Tput::DEFAULT_SCREEN_SIZE,
        probe: false
      mice = [] of Tput::Mouse::Event
      t.listen { |e| mice << e.mouse.not_nil! if e.mouse? }
      mice.size.should eq 1
      mice[0].x.should eq (0xc8 - 32 - 1) # 167, decoded from the raw byte
    end

    it "parses URxvt encoding" do
      m = one_mouse("\e[32;10;20M").not_nil!
      m.button.should eq Tput::Mouse::Button::Left
      m.action.should eq Tput::Mouse::Action::Down
      m.x.should eq 9
      m.y.should eq 19
    end

    it "parses DEC-locator events (CSI Cb;Cx;Cy;Cp & w, no `<` prefix)" do
      # A real DEC-locator report is introduced by a digit (the event code) and
      # terminated by `& w`; there is no `\e[<` prefix. It must route through the
      # numeric-CSI path and reach `Mouse.parse_dec`.
      m = one_mouse("\e[2;10;20;1&w").not_nil!
      m.button.should eq Tput::Mouse::Button::Left
      m.action.should eq Tput::Mouse::Action::Down
      m.x.should eq 9
      m.y.should eq 19
      m.page.should eq 1

      # A release (odd event code) keeps the button identity.
      up = one_mouse("\e[7;10;20;2&w").not_nil! # right button up, page 2
      up.button.should eq Tput::Mouse::Button::Right
      up.action.should eq Tput::Mouse::Action::Up
      up.page.should eq 2

      # A `w` final that is NOT a DEC-locator report (no `&` intermediate) must
      # not be mistaken for one; it is simply an unrecognized CSI and drops.
      feed("\e[1;2w").should be_empty
    end

    it "fully consumes a single-parameter DEC-locator report (CSI Pe & w)" do
      # The "locator unavailable/outside" report is a *single*-parameter
      # `CSI Pe & w` (e.g. `\e[0&w`). The `&` intermediate must not be mistaken
      # for the final just because only one parameter preceded it; doing so left
      # the `w` unread, leaking it as a phantom `w` keystroke.
      feed("\e[0&w").should be_empty
    end

    it "parses focus in/out" do
      one_mouse("\e[I").not_nil!.action.should eq Tput::Mouse::Action::Focus
      one_mouse("\e[O").not_nil!.action.should eq Tput::Mouse::Action::Blur
    end

    it "reports extra side buttons (8/9) as Unknown via SGR, not Left/Middle" do
      # Bit 7 marks buttons 8-11 (back/forward); their low bits must not be
      # mistaken for Left/Middle/Right.
      back = one_mouse("\e[<128;5;5M").not_nil!
      back.action.should eq Tput::Mouse::Action::Down
      back.button.should eq Tput::Mouse::Button::Unknown
      one_mouse("\e[<129;5;5M").not_nil!.button.should eq Tput::Mouse::Button::Unknown
    end

    it "normalizes the urxvt wheel-during-motion bug (128/129)" do
      # urxvt reports 128/129 instead of 96/97 for a wheel up/down during a
      # drag; both must still decode as a wheel, keeping the up/down direction.
      one_mouse("\e[128;5;5M").not_nil!.action.should eq Tput::Mouse::Action::WheelUp
      one_mouse("\e[129;5;5M").not_nil!.action.should eq Tput::Mouse::Action::WheelDown
    end
  end

  # vt300 reports are not auto-routed (the ancient `\e[24…~[x,y]\r` form
  # collides with F-key parsing); the parser is exercised directly.
  describe "Tput::Mouse.parse_vt300" do
    it "decodes button and coordinates" do
      m = Tput::Mouse.parse_vt300 1, 10, 20
      m.action.should eq Tput::Mouse::Action::Down
      m.button.should eq Tput::Mouse::Button::Left
      m.x.should eq 9
      m.y.should eq 19
      Tput::Mouse.parse_vt300(2, 1, 1).button.should eq Tput::Mouse::Button::Middle
      Tput::Mouse.parse_vt300(5, 1, 1).button.should eq Tput::Mouse::Button::Right
    end
  end

  describe "bracketed paste" do
    it "delivers the body up to the terminator" do
      feed_paste("\e[200~hello\e[201~").should eq ["hello"]
    end

    it "flushes a partial terminator left by a truncated stream" do
      # The stream ends in the middle of the `\e[201~` terminator; those bytes
      # are paste content and must not be dropped.
      feed_paste("\e[200~abc\e[20").should eq ["abc\e[20"]
    end
  end

  describe "Tput::Mouse.parse_dec" do
    it "decodes button press/release pairs, keeping the button on release" do
      # Even codes are presses, the following odd code the matching release.
      mid_up = Tput::Mouse.parse_dec 5, 10, 20, 1 # middle button up
      mid_up.action.should eq Tput::Mouse::Action::Up
      mid_up.button.should eq Tput::Mouse::Button::Middle

      right_up = Tput::Mouse.parse_dec 7, 10, 20, 1 # right button up
      right_up.action.should eq Tput::Mouse::Action::Up
      right_up.button.should eq Tput::Mouse::Button::Right

      left_up = Tput::Mouse.parse_dec 3, 10, 20, 1 # left button up
      left_up.action.should eq Tput::Mouse::Action::Up
      left_up.button.should eq Tput::Mouse::Button::Left
    end
  end
end
