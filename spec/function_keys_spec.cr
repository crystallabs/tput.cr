require "./spec_helper"

# F1-F12 in every encoding a terminal sends them: SS3 (`\eOP`-`\eOS`, xterm
# and macOS Terminal.app), the rxvt `\e[11~`-`\e[14~`, the modified xterm
# `\e[1;mod P`, putty/Cygwin's `\e[[A`, the `\e[N~` of F5-F12, and the kitty
# keyboard protocol's `\e[P`, `\e[Q`, `\e[13~` and `\e[S` (kitty, Ghostty,
# iTerm2, WezTerm, foot with the protocol on), F3's `~` form keeping clear of
# a cursor position report.

private def feed(data : String)
  events = [] of {Char, Tput::Key?}
  t = Tput.new \
    input: IO::Memory.new(data),
    output: IO::Memory.new,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false
  t.listen do |e|
    events << {e.char, e.key}
  end
  events
end

private def key_of(data : String) : Tput::Key?
  ev = feed data
  ev.size.should eq 1
  ev[0][1]
end

describe "Tput function keys" do
  it "decodes F1-F4 as SS3" do
    key_of("\eOP").should eq Tput::Key::F1
    key_of("\eOQ").should eq Tput::Key::F2
    key_of("\eOR").should eq Tput::Key::F3
    key_of("\eOS").should eq Tput::Key::F4
  end

  it "decodes F1-F4 as rxvt's CSI N ~" do
    key_of("\e[11~").should eq Tput::Key::F1
    key_of("\e[12~").should eq Tput::Key::F2
    key_of("\e[13~").should eq Tput::Key::F3
    key_of("\e[14~").should eq Tput::Key::F4
  end

  it "decodes F1-F4 as the kitty keyboard protocol sends them" do
    key_of("\e[P").should eq Tput::Key::F1
    key_of("\e[Q").should eq Tput::Key::F2
    key_of("\e[13~").should eq Tput::Key::F3
    key_of("\e[S").should eq Tput::Key::F4
  end

  it "decodes modified F1-F4 (CSI 1 ; mod P-S), legacy and kitty" do
    key_of("\e[1;2P").should eq Tput::Key::F1
    key_of("\e[1;5Q").should eq Tput::Key::F2
    key_of("\e[1;3R").should eq Tput::Key::F3
    key_of("\e[13;5~").should eq Tput::Key::F3
    key_of("\e[1;2S").should eq Tput::Key::F4
    key_of("\e[1;1:1P").should eq Tput::Key::F1 # kitty, with the event type
  end

  it "decodes putty/Cygwin's F1-F5" do
    key_of("\e[[A").should eq Tput::Key::F1
    key_of("\e[[B").should eq Tput::Key::F2
    key_of("\e[[C").should eq Tput::Key::F3
    key_of("\e[[D").should eq Tput::Key::F4
    key_of("\e[[E").should eq Tput::Key::F5
  end

  it "decodes F5-F12 as CSI N ~" do
    {15 => Tput::Key::F5, 17 => Tput::Key::F6, 18 => Tput::Key::F7, 19 => Tput::Key::F8,
     20 => Tput::Key::F9, 21 => Tput::Key::F10, 23 => Tput::Key::F11, 24 => Tput::Key::F12,
    }.each do |n, key|
      key_of("\e[#{n}~").should eq key
      key_of("\e[#{n};2~").should eq key
    end
  end

  it "keeps the keys typed after an F-key" do
    feed("\e[Px\e[Sy").should eq [{'\e', Tput::Key::F1}, {'x', nil}, {'\e', Tput::Key::F4}, {'y', nil}]
  end

  it "takes no cursor position report for F3" do
    feed("\e[12;40R").none? { |e| e[1] == Tput::Key::F3 }.should be_true
  end
end
