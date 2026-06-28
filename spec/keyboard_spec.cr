require "./spec_helper"

# Enhanced keyboard protocols: end-to-end parsing of kitty / modifyOtherKeys
# sequences through `Tput::Input#listen`, the `Tput::KeyEvent` projection onto
# the legacy channels, runtime detection via `probe_consume`, and protocol
# selection (`best_keyboard_protocol`) with user exclusions.

private def feed_kb(data : String)
  events = [] of {Char, Tput::Key?, Tput::KeyEvent?}
  t = Tput.new \
    input: IO::Memory.new(data),
    output: IO::Memory.new,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false
  t.listen do |e|
    events << {e.char, e.key, e.key_event}
  end
  events
end

private def one_kb(data : String) : Tput::KeyEvent
  ev = feed_kb data
  ev.size.should eq 1
  ev[0][2].not_nil!
end

private def new_tput(input = "", output = IO::Memory.new)
  Tput.new \
    input: IO::Memory.new(input),
    output: output,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false
end

describe Tput::KeyEvent do
  describe "kitty / modifyOtherKeys-1 (u final)" do
    it "parses a modified key and projects onto the legacy Key" do
      ev = feed_kb("\e[97;5u")
      ev.size.should eq 1
      _char, key, kev = ev[0]
      kev = kev.not_nil!
      kev.codepoint.should eq 97
      kev.ctrl?.should be_true
      kev.press?.should be_true
      key.should eq Tput::Key::CtrlA # legacy projection still works
    end

    it "surfaces a plain printable key through char (report-all-keys)" do
      ev = feed_kb("\e[97u")
      char, key, kev = ev[0]
      char.should eq 'a' # typing still flows through `char`
      key.should be_nil  # no legacy control key
      kev.not_nil!.char.should eq 'a'
    end

    it "detects a lone modifier press and release (the Alt tap)" do
      press = one_kb("\e[57443;1:1u")
      press.modifier_key?.should be_true
      press.modifier_key.should eq :left_alt
      press.press?.should be_true

      release = feed_kb("\e[57443;1:3u")
      _char, key, kev = release[0]
      kev = kev.not_nil!
      kev.modifier_key.should eq :left_alt
      kev.release?.should be_true
      key.should be_nil # a release must not look like a key press
    end

    it "maps special keys by codepoint" do
      one_kb("\e[27u").to_legacy_key.should eq Tput::Key::Escape
      one_kb("\e[13u").to_legacy_key.should eq Tput::Key::Enter
      one_kb("\e[9u").to_legacy_key.should eq Tput::Key::Tab
      one_kb("\e[127u").to_legacy_key.should eq Tput::Key::Backspace
    end

    it "reports event type (press/repeat/release)" do
      one_kb("\e[97;1:1u").type.should eq Tput::KeyEvent::Type::Press
      one_kb("\e[97;1:2u").type.should eq Tput::KeyEvent::Type::Repeat
      one_kb("\e[97;1:3u").type.should eq Tput::KeyEvent::Type::Release
    end

    it "decodes associated text" do
      one_kb("\e[97;1;97u").text.should eq "a"
    end

    it "uses the shifted codepoint for Shift+key (not the base letter)" do
      ev = feed_kb("\e[97:65;2u") # key 'a', shifted 'A', Shift held
      char, _key, kev = ev[0]
      kev.not_nil!.shift?.should be_true
      char.should eq 'A'
      kev.not_nil!.char.should eq 'A'
    end

    it "projects the key for an auto-repeat (held key)" do
      ev = feed_kb("\e[97;5:2u") # Ctrl+A, repeat
      _char, key, kev = ev[0]
      kev.not_nil!.repeat?.should be_true
      key.should eq Tput::Key::CtrlA
    end

    it "does not treat a Private-Use functional codepoint as text" do
      ev = one_kb("\e[57364u") # a kitty functional key code (PUA)
      ev.char.should be_nil
      ev.modifier_key?.should be_false
    end

    it "surfaces a supplementary-plane character (emoji) through char" do
      # U+1F600 is above the kitty functional-key PUA (U+E000..U+F8FF); it is
      # real text and must not be filtered out like a functional key code.
      one_kb("\e[128512u").char.should eq '\u{1F600}'
    end
  end

  describe "modifyOtherKeys format 0 (27 ; mods ; code ~)" do
    it "parses a control combination" do
      ev = feed_kb("\e[27;5;99~")
      _char, key, kev = ev[0]
      kev = kev.not_nil!
      kev.codepoint.should eq 99
      kev.ctrl?.should be_true
      key.should eq Tput::Key::CtrlC
    end
  end

  describe "kitty modified nav keys with event type (legacy final)" do
    it "projects a modified press onto the legacy Key" do
      ev = feed_kb("\e[1;5:1A")
      _char, key, kev = ev[0]
      kev.not_nil!.ctrl?.should be_true
      key.should eq Tput::Key::CtrlUp
    end

    it "does not project a release onto the legacy Key" do
      ev = feed_kb("\e[1;5:3A")
      _char, key, kev = ev[0]
      kev.not_nil!.release?.should be_true
      key.should be_nil
    end

    it "projects a kitty function key (tilde + event type) onto the legacy Key" do
      feed_kb("\e[15;1:1~")[0][1].should eq Tput::Key::F5 # F5 press
      feed_kb("\e[15;5:1~")[0][1].should eq Tput::Key::F5 # Ctrl+F5 (no modified-F member)
      feed_kb("\e[29;1:1~")[0][1].should eq Tput::Key::Menu
      feed_kb("\e[34;1:1~")[0][1].should eq Tput::Key::F20
      feed_kb("\e[15;1:3~")[0][1].should be_nil # release must not project
    end
  end

  it "does not disturb legacy (non-enhanced) parsing" do
    feed_kb("\e[A")[0][1].should eq Tput::Key::Up
    feed_kb("\e[1;5C")[0][1].should eq Tput::Key::CtrlRight
  end

  describe "ignores ambient lock state in the modifier parameter" do
    # The kitty scheme folds CapsLock (64) and NumLock (128) into the modifier
    # bitmask, so the on-the-wire parameter is `1 + ctrl(4) + lock`. A modified
    # nav key must still project to its modified legacy member rather than
    # degrading to the base key just because a lock happens to be on.
    it "via the legacy final form" do
      feed_kb("\e[1;69A")[0][1].should eq Tput::Key::CtrlUp     # Ctrl + CapsLock
      feed_kb("\e[1;133C")[0][1].should eq Tput::Key::CtrlRight # Ctrl + NumLock
      feed_kb("\e[1;66H")[0][1].should eq Tput::Key::ShiftHome  # Shift + CapsLock
    end

    it "via the enhanced final form (kitty event type)" do
      feed_kb("\e[1;69:1A")[0][1].should eq Tput::Key::CtrlUp # Ctrl + CapsLock press
    end
  end
end

describe "Tput::Probe keyboard detection" do
  it "detects the kitty keyboard protocol from a CSI ? u reply" do
    t = new_tput
    # kitty reply (flags 5), then DA1 sentinel.
    t.probe_consume(IO::Memory.new("\e[?5u\e[c"), 1.second)
    t.features.kitty_keyboard?.should be_true
    t.features.kitty_keyboard_flags.should eq 5
  end

  it "detects modifyOtherKeys from a CSI > 4 ; level m reply" do
    t = new_tput
    t.probe_consume(IO::Memory.new("\e[>4;2m\e[c"), 1.second)
    t.features.modify_other_keys?.should be_true
    t.features.modify_other_keys.should eq 2
  end

  it "leaves both unsupported when the terminal stays silent" do
    t = new_tput
    t.probe_consume(IO::Memory.new("\e[c"), 1.second) # only DA1
    t.features.kitty_keyboard?.should be_false
    t.features.modify_other_keys?.should be_false
  end
end

describe "Tput::Keyboard selection" do
  it "picks the best supported protocol, kitty over modifyOtherKeys" do
    t = new_tput
    t.features.kitty_keyboard_flags = 0
    t.features.modify_other_keys = 2
    t.best_keyboard_protocol.should eq Tput::KeyboardProtocol::Kitty
  end

  it "falls back to modifyOtherKeys when kitty is unsupported" do
    t = new_tput
    t.features.modify_other_keys = 1
    t.best_keyboard_protocol.should eq Tput::KeyboardProtocol::ModifyOtherKeys
  end

  it "falls back to Legacy when nothing is supported" do
    new_tput.best_keyboard_protocol.should eq Tput::KeyboardProtocol::Legacy
  end

  it "honors user exclusions (keyboard.exclude)" do
    saved = Superconf.keyboard_exclude
    begin
      Superconf.keyboard_exclude = "kitty"
      t = new_tput
      t.features.kitty_keyboard_flags = 0
      t.features.modify_other_keys = 2
      t.best_keyboard_protocol.should eq Tput::KeyboardProtocol::ModifyOtherKeys
    ensure
      Superconf.keyboard_exclude = saved
    end
  end

  it "enables the chosen protocol and writes the expected sequence" do
    buf = IO::Memory.new
    t = new_tput(output: buf)
    t.features.kitty_keyboard_flags = 0
    t.enable_keyboard_protocol(events: true).should eq Tput::KeyboardProtocol::Kitty
    t.flush
    # Disambiguate(1)|ReportEventTypes(2)|ReportAlternateKeys(4)|ReportAllKeys(8)|
    # ReportAssociatedText(16) == 31
    buf.to_s.should contain "\e[>31u"
    t.keyboard_protocol.should eq Tput::KeyboardProtocol::Kitty

    t.disable_keyboard_protocol
    t.flush
    buf.to_s.should contain "\e[<u"
    t.keyboard_protocol.should be_nil
  end

  it "requests associated text alongside report-all-keys" do
    # `ReportAllKeys` makes the terminal report *every* key as an escape code and
    # stop sending the decoded text bytes; without `ReportAssociatedText` the
    # text a key produces (non-US layouts, AltGr, dead keys, caps lock) is lost
    # and `KeyEvent#char` can only guess from the base/shifted codepoint. The two
    # flags must therefore be requested together.
    buf = IO::Memory.new
    t = new_tput(output: buf)
    t.features.kitty_keyboard_flags = 0
    t.enable_keyboard_protocol(events: true)
    t.flush
    flags = buf.to_s.match(/\e\[>(\d+)u/).not_nil![1].to_i
    (flags & Tput::KittyKeyboard::ReportAllKeys.value).should_not eq 0
    (flags & Tput::KittyKeyboard::ReportAssociatedText.value).should_not eq 0
  end
end
