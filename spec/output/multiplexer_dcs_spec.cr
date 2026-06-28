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

  # A payload may legitimately contain ESC bytes *after* its leading one (e.g. a
  # sequence that itself embeds an ESC). Every such inner ESC must be doubled so
  # the multiplexer forwards the whole payload instead of stopping at the first
  # internal ESC. A plain single-leading-ESC payload must stay unchanged.
  it "doubles every internal ESC in the tmux passthrough payload" do
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = true
    t.emulator.screen = false
    t._tprint "\eA\eB" # leading ESC + one internal ESC
    # leading ESC doubled (internal to `\ePtmux;`) and the inner ESC doubled too
    buf.to_s.should eq "\ePtmux;\e\eA\e\eB\e\\"

    # A single-leading-ESC payload is unchanged from the historical wrapping.
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = true
    t.emulator.screen = false
    t._tprint "\e]7;x\a"
    buf.to_s.should eq "\ePtmux;\e\e]7;x\a\e\\"
  end

  it "doubles every internal ESC in the GNU screen passthrough payload" do
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = false
    t.emulator.screen = true
    t._tprint "\eA\eB" # leading ESC + one internal ESC
    # leading ESC sits against `\eP` and stays single; the inner ESC is doubled
    buf.to_s.should eq "\eP\eA\e\eB\e\\"

    # A single-leading-ESC payload is unchanged (verbatim) from before.
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = false
    t.emulator.screen = true
    t._tprint "\e]7;x\a"
    buf.to_s.should eq "\eP\e]7;x\a\e\\"
  end

  # The OSC 8 begin/end markers need DCS passthrough, but the link's *display
  # text* is ordinary content and must render in the pane — it must NOT be
  # wrapped in the multiplexer passthrough (which would divert it to the outer
  # terminal and drop it from the multiplexed screen).
  it "does not wrap the hyperlink display text in the tmux passthrough" do
    buf = IO::Memory.new
    t = new_tput buf
    t.emulator.tmux = true
    t.emulator.screen = false
    t.hyperlink "label", "http://x"
    t.flush
    buf.to_s.should eq \
      "\ePtmux;\e\e]8;;http://x\a\e\\" + # begin (wrapped)
        "label" +                       # display text (NOT wrapped)
        "\ePtmux;\e\e]8;;\a\e\\"         # end (wrapped)
  end
end
