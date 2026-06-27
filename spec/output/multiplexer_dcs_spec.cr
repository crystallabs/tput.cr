require "../spec_helper"

private def new_tput(output = IO::Memory.new)
  Tput.new input: IO::Memory.new(""), output: output,
    screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
end

# `_tprint` wraps escape sequences in the terminal multiplexer's DCS passthrough
# (tmux or GNU screen) so they reach the outer terminal; on a plain terminal it
# passes through unchanged. (Uses `report_cwd`, an OSC 7 emitter routed through
# `_tprint`, as a representative payload.)
describe "Tput#_tprint multiplexer DCS passthrough" do
  it "wraps OSC in the tmux passthrough (leading ESC doubled)" do
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = true
    t.emulator.screen = false
    t.report_cwd "/x"
    buf.to_s.should eq "\ePtmux;\e\e]7;file:///x\a\e\\"
  end

  it "wraps OSC in the GNU screen passthrough (payload verbatim)" do
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = false
    t.emulator.screen = true
    t.report_cwd "/x"
    buf.to_s.should eq "\eP\e]7;file:///x\a\e\\"
  end

  it "passes through unchanged on a plain (non-multiplexed) terminal" do
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = false
    t.emulator.screen = false
    t.report_cwd "/x"
    t.flush # the plain branch buffers (only the DCS branches write directly)
    buf.to_s.should eq "\e]7;file:///x\a"
  end

  it "converts an inner ST to BEL so it can't terminate the screen DCS early" do
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = false
    t.emulator.screen = true
    t._tprint "\e]8;;\e\\" # an ST-terminated OSC (e.g. OSC 8 hyperlink end)
    buf.to_s.should eq "\eP\e]8;;\a\e\\"
  end
end
