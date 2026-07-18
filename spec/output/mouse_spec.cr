describe Tput::Output::Mouse do
  x = Tput::Test.new

  describe "enable_mouse / disable_mouse" do
    it "enables button+drag+all-motion tracking with SGR" do
      x.t.enable_mouse
      x.o.should eq "\e[?1000h\e[?1002h\e[?1003h\e[?1006h"
    end

    it "disables the same modes" do
      x.t.disable_mouse
      x.o.should eq "\e[?1000l\e[?1002l\e[?1003l\e[?1006l"
    end

    it "additionally toggles focus reporting when asked" do
      x.t.enable_mouse(focus: true)
      x.o.should eq "\e[?1000h\e[?1002h\e[?1003h\e[?1004h\e[?1006h"
    end

    it "additionally enables SGR-Pixels (1016) and caches the cell size when pixels given" do
      x.t.enable_mouse(pixels: {8, 16})
      x.o.should eq "\e[?1000h\e[?1002h\e[?1003h\e[?1006h\e[?1016h"
      x.t.mouse_cell_pixels.should eq({8, 16})
    end

    it "disables 1016 and clears the cached cell size" do
      # 1004 is reset too: the focus enable two tests up survives the
      # pixels-only re-assert (focus/pixels are three-state; `nil` preserves),
      # so teardown must turn it off.
      x.t.disable_mouse
      x.o.should eq "\e[?1000l\e[?1002l\e[?1003l\e[?1004l\e[?1006l\e[?1016l"
      x.t.mouse_cell_pixels.should be_nil
      x.t.mouse_focus_enabled?.should be_false
    end

    it "a re-assert with nil pixels/focus preserves both modes" do
      x.t.enable_mouse(focus: true, pixels: {8, 16})
      x.o
      x.t.enable_mouse
      x.o.should eq "\e[?1000h\e[?1002h\e[?1003h\e[?1006h"
      x.t.mouse_cell_pixels.should eq({8, 16})
      x.t.mouse_focus_enabled?.should be_true
      x.t.disable_mouse
      x.o
    end

    it "explicit false downgrades pixels/focus only when active" do
      x.t.enable_mouse(focus: true, pixels: {8, 16})
      x.o
      x.t.enable_mouse(focus: false, pixels: false)
      x.o.should eq "\e[?1000h\e[?1002h\e[?1003h\e[?1004l\e[?1006h\e[?1016l"
      x.t.mouse_cell_pixels.should be_nil
      x.t.mouse_focus_enabled?.should be_false

      # Inactive modes: false must not emit stray DECRSTs.
      x.t.enable_mouse(focus: false, pixels: false)
      x.o.should eq "\e[?1000h\e[?1002h\e[?1003h\e[?1006h"
      x.t.disable_mouse
      x.o
    end
  end

  describe "set_mouse" do
    it "leaves nil modes untouched and toggles the rest" do
      x.t.set_mouse(x10: true)
      x.o.should eq "\e[?9h"

      x.t.set_mouse(send_focus: true)
      x.o.should eq "\e[?1004h"

      x.t.set_mouse(sgr: false)
      x.o.should eq "\e[?1006l"

      x.t.set_mouse(urxvt: true)
      x.o.should eq "\e[?1015h"
    end

    it "expands normal into vt200 + all_motion" do
      x.t.set_mouse(normal: true)
      x.o.should eq "\e[?1000h\e[?1003h"
    end

    it "aliases hilite_tracking to vt200_hilite" do
      x.t.set_mouse(hilite_tracking: true)
      x.o.should eq "\e[?1001h"
    end

    it "emits the DEC locator enable/disable sequences" do
      x.t.set_mouse(dec: true)
      x.o.should eq "\e[1;2'z\e[1;3'{"
      x.t.set_mouse(dec: false)
      x.o.should eq "\e['z"
    end

    it "passes all_motion through directly under tmux (DCS-wrapped)" do
      x.t.emulator.tmux = true
      x.t.set_mouse(all_motion: true)
      x.o.should eq "\ePtmux;\e\e[?1003h\e\\"
      x.t.emulator.tmux = false
    end
  end

  # Regression for BUGS11 #32: focus reporting (mode 1004) enabled via
  # enable_mouse(focus: true) must be turned back off by the paired teardown
  # paths, otherwise \e[I/\e[O garbage leaks to the shell after exit/suspend.
  describe "focus reporting (1004) teardown [BUGS11 #32]" do
    it "disable_mouse turns off focus reporting enabled via enable_mouse(focus: true)" do
      y = Tput::Test.new
      y.t.enable_mouse(focus: true)
      y.o # drain enable output
      y.t.disable_mouse
      y.o.should contain "\e[?1004l"
    end

    it "restore_terminal turns off focus reporting" do
      y = Tput::Test.new
      y.t.enable_mouse(focus: true)
      y.o # drain enable output
      y.t.restore_terminal
      y.o.should contain "\e[?1004l"
    end

    it "disable_mouse does not touch 1004 when focus reporting was never enabled" do
      y = Tput::Test.new
      y.t.enable_mouse
      y.o # drain enable output
      y.t.disable_mouse
      y.o.should_not contain "1004"
    end
  end

  # Regression for BUGS11 #32 & #34: pause/resume must round-trip both the
  # SGR-Pixels (1016) mode with its cached cell size and focus reporting (1004).
  describe "pause/resume restores mouse state [BUGS11 #32 & #34]" do
    it "re-enables SGR-Pixels (1016) and restores the cached cell size" do
      y = Tput::Test.new
      y.t.enable_mouse(pixels: {8, 16})
      y.o # drain enable output
      resume = y.t.pause
      y.t.mouse_cell_pixels.should be_nil # teardown cleared it
      y.o                                 # drain teardown output
      resume.call
      y.o.should contain "\e[?1016h"
      y.t.mouse_cell_pixels.should eq({8, 16})
    end

    it "re-enables focus reporting (1004) across pause/resume" do
      y = Tput::Test.new
      y.t.enable_mouse(focus: true)
      y.o # drain enable output
      resume = y.t.pause
      y.o # drain teardown output
      resume.call
      y.o.should contain "\e[?1004h"
    end
  end
end
