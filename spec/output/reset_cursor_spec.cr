require "../spec_helper"

describe "Tput#reset_cursor" do
  x = Tput::Test.new

  it "puts the terminal's own cursor color back, not white" do
    x.t.features.cursor_style = true
    x.t.features.cursor_color = true
    x.t.emulator.rxvt = false
    x.t.reset_cursor.should be_true
    x.o.should eq "\e[0 q\e]112\a"
  end

  it "sets white, urxvt's default, where OSC 112 is not understood" do
    x.t.features.cursor_style = true
    x.t.features.cursor_color = true
    x.t.emulator.rxvt = true
    x.t.reset_cursor.should be_true
    x.o.should eq "\e[0 q\e]112\a\e]12;white\a"
    x.t.emulator.rxvt = false
  end
end
