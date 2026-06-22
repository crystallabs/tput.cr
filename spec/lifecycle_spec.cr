# Process-lifecycle: pause/resume/restore_terminal. Uses fresh `Tput`s (not the
# shared `Tput::Test` fixture) so the mutable paused/mouse/alt state doesn't
# leak into other specs. `IO::Memory` isn't a tty, so the raw-mode toggling is a
# safe no-op here.

private def fresh_tput
  Tput.new \
    input: IO::Memory.new,
    output: IO::Memory.new,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false
end

private def output_of(t : Tput) : String
  String.new t.output.as(IO::Memory).to_slice
end

describe "Tput lifecycle" do
  describe "#mouse_enabled?" do
    it "tracks enable_mouse / disable_mouse" do
      t = fresh_tput
      t.mouse_enabled?.should be_false
      t.enable_mouse
      t.mouse_enabled?.should be_true
      t.disable_mouse
      t.mouse_enabled?.should be_false
    end
  end

  describe "#pause / #resume" do
    it "disables mouse on pause and re-enables it on resume" do
      t = fresh_tput
      t.enable_mouse
      t.pause
      t.mouse_enabled?.should be_false
      t.resume
      t.mouse_enabled?.should be_true
    end

    it "shows the cursor when pausing" do
      t = fresh_tput
      t.hide_cursor
      buf = t.output.as(IO::Memory)
      buf.clear
      t.pause
      output_of(t).should contain "\e[?25h" # cursor shown before handing back
    end
  end

  describe "#restore_terminal" do
    it "shows the cursor and disables mouse" do
      t = fresh_tput
      t.enable_mouse
      buf = t.output.as(IO::Memory)
      buf.clear

      t.restore_terminal

      s = output_of(t)
      s.should contain "\e[?25h"   # show cursor
      s.should contain "\e[?1006l" # mouse (SGR) disabled
      t.mouse_enabled?.should be_false
    end
  end
end
