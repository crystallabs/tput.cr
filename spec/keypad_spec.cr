require "./spec_helper"

# The numeric keypad: application keypad mode (DECKPAM, `\eO` + letter) and
# kitty's `KP_*` codes both arrive as a `Tput::KeyEvent` that `#keypad?`
# tells apart and that projects onto the key it stands for — the keypad's
# Enter as `Key::Enter`, its digits and operators as characters.

private def feed(data : String)
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

private def one(data : String)
  ev = feed data
  ev.size.should eq 1
  ev[0]
end

describe "Tput numeric keypad" do
  describe "application keypad mode (SS3)" do
    it "delivers the keypad's Enter as Key::Enter, marked as the keypad's" do
      _char, key, kev = one("\eOM")
      key.should eq Tput::Key::Enter
      kev = kev.not_nil!
      kev.keypad?.should be_true
      kev.number.should eq 57414
    end

    it "delivers the digits and the operators as characters" do
      {
        "\eOp" => '0', "\eOq" => '1', "\eOu" => '5', "\eOy" => '9',
        "\eOj" => '*', "\eOk" => '+', "\eOl" => ',', "\eOm" => '-',
        "\eOn" => '.', "\eOo" => '/', "\eOX" => '=',
      }.each do |seq, ch|
        char, key, kev = one(seq)
        char.should eq ch
        key.should be_nil
        kev.not_nil!.keypad?.should be_true
      end
    end

    it "leaves the cursor, function and rxvt keys of SS3 as they were" do
      one("\eOA")[1].should eq Tput::Key::Up
      one("\eOH")[1].should eq Tput::Key::Home
      one("\eOP")[1].should eq Tput::Key::F1
      one("\eOa")[1].should eq Tput::Key::CtrlUp
      one("\eOE")[1].should eq Tput::Key::Clear
      one("\eOA")[2].should be_nil
    end

    it "keeps the keys typed after a keypad key" do
      ev = feed("\eOu\eOMx")
      ev.map { |e| {e[0], e[1]} }.should eq [{'5', nil}, {'\e', Tput::Key::Enter}, {'x', nil}]
    end
  end

  describe "kitty keyboard protocol (KP_* codes)" do
    it "delivers KP_ENTER as Key::Enter, with its modifiers" do
      _char, key, kev = one("\e[57414u")
      key.should eq Tput::Key::Enter
      kev.not_nil!.keypad?.should be_true
      one("\e[57414;1:3u")[1].should be_nil # a release is no press
    end

    it "delivers the keypad's digits as characters, NumLock or not" do
      char, key, _ = one("\e[57404u")
      char.should eq '5'
      key.should be_nil
      one("\e[57404;129u")[0].should eq '5' # NumLock on
      one("\e[57413u")[0].should eq '+'
    end

    it "delivers the keypad's navigation keys as the cursor and editing keys" do
      one("\e[57417u")[1].should eq Tput::Key::Left
      one("\e[57419;5u")[1].should eq Tput::Key::CtrlUp
      one("\e[57423;5u")[1].should eq Tput::Key::CtrlHome
      one("\e[57422u")[1].should eq Tput::Key::PageDown
      one("\e[57426u")[1].should eq Tput::Key::Delete
      one("\e[57427u")[1].should be_nil # KP_BEGIN stands for no key
    end

    it "is told apart from the main keyboard's keys" do
      one("\e[13u")[2].not_nil!.keypad?.should be_false
      one("\e[53u")[2].not_nil!.keypad?.should be_false
    end
  end

  describe "#to_legacy_bytes" do
    it "sends what the key the keypad key stands for sends" do
      Tput::KeyEvent.new(57414, 'u').to_legacy_bytes.should eq "\r"
      Tput::KeyEvent.new(57414, 'u', Tput::Modifiers::Alt).to_legacy_bytes.should eq "\e\r"
      Tput::KeyEvent.new(57404, 'u').to_legacy_bytes.should eq "5"
      Tput::KeyEvent.new(57417, 'u', Tput::Modifiers::Ctrl).to_legacy_bytes.should eq "\e[1;5D"
      Tput::KeyEvent.new(57421, 'u').to_legacy_bytes.should eq "\e[5~"
      Tput::KeyEvent.new(57427, 'u').to_legacy_bytes.should be_nil
      Tput::KeyEvent.from_ss3_keypad('M').not_nil!.to_legacy_bytes.should eq "\r"
      Tput::KeyEvent.from_ss3_keypad('A').should be_nil
    end
  end
end
