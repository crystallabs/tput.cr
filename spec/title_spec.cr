require "./spec_helper"

# The terminal's title: `Tput#title=` sends OSC 0 on every terminal (one
# without titles ignores it), plain under tmux and screen, with control
# characters dropped; the terminal's own title is saved on its title stack
# before the first one and put back when the terminal is handed back.

private def tput(env = {} of String => String?)
  output = IO::Memory.new
  t = with_env(env) do
    Tput.new input: IO::Memory.new, output: output,
      screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
  end
  {t, output}
end

private def with_env(env, &)
  saved = env.keys.to_h { |k| {k, ENV[k]?} }
  env.each { |k, v| v ? (ENV[k] = v) : ENV.delete(k) }
  begin
    yield
  ensure
    saved.each { |k, v| v ? (ENV[k] = v) : ENV.delete(k) }
  end
end

describe "Tput#title=" do
  it "saves the terminal's title once, then sets the title" do
    t, output = tput
    t.title = "doc.md • MD"
    t.title = "other.md • MD"
    t.flush
    output.to_s.should eq "\e[22;0t\e]0;doc.md • MD\a\e]0;other.md • MD\a"
    t._title.should eq "other.md • MD"
    t.title_pushed?.should be_true
  end

  it "puts the terminal's title back once, and saves it again on the next title" do
    t, output = tput
    t.title = "a"
    t.restore_title
    t.restore_title
    t.title = "b"
    t.flush
    output.to_s.should eq "\e[22;0t\e]0;a\a\e[23;0t\e[22;0t\e]0;b\a"
  end

  it "puts back nothing when no title was set" do
    t, output = tput
    t.restore_title
    t.flush
    output.to_s.should eq ""
  end

  it "drops control characters, so a title cannot end the OSC early" do
    t, output = tput
    t.title = "a\e]0;x\ab\u009Dc"
    t.flush
    output.to_s.should end_with "\e]0;a]0;xbc\a"
  end

  it "sends the title as is under tmux, which takes it as the pane's" do
    t, output = tput({"TMUX" => "/tmp/tmux-1/default,1,0", "TERM" => "screen-256color"})
    t.emulator.tmux?.should be_true
    t.title = "doc.md • MD"
    t.flush
    output.to_s.should contain "\e]0;doc.md • MD\a"
    output.to_s.should_not contain "\ePtmux;"
  end

  it "gives the terminal's title back while paused and the program's on resume" do
    t, output = tput
    t.title = "doc.md • MD"
    t.flush
    output.clear
    t.pause
    t.flush
    output.to_s.should contain "\e[23;0t"
    output.clear
    t.resume
    t.flush
    output.to_s.should contain "\e[22;0t\e]0;doc.md • MD\a"
  end
end
