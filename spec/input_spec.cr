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
  t.listen do |char, key, _seq, mouse|
    events << {char, key, mouse}
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

    it "corrects the VTE coordinate overflow in X10" do
      # cx byte 0x10 is below the 0x20 floor -> overflowed; folded back by 0xff.
      m = one_mouse("\e[M\x20\x10\x22").not_nil!
      m.x.should eq (0x10 + 0xff) - 0x20 - 1
    end

    it "parses URxvt encoding" do
      m = one_mouse("\e[32;10;20M").not_nil!
      m.button.should eq Tput::Mouse::Button::Left
      m.action.should eq Tput::Mouse::Action::Down
      m.x.should eq 9
      m.y.should eq 19
    end

    it "parses DEC-locator events" do
      m = one_mouse("\e[<2;10;20;1&w").not_nil!
      m.button.should eq Tput::Mouse::Button::Left
      m.action.should eq Tput::Mouse::Action::Down
      m.x.should eq 9
      m.y.should eq 19
      m.page.should eq 1
    end

    it "parses focus in/out" do
      one_mouse("\e[I").not_nil!.action.should eq Tput::Mouse::Action::Focus
      one_mouse("\e[O").not_nil!.action.should eq Tput::Mouse::Action::Blur
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
end
