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
end
