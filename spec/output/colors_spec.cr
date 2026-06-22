describe Tput::Output::Colors do
  x = Tput::Test.new

  describe "reset_colors" do
    it "uses the Cr capability with terminfo" do
      x.t.reset_colors
      x.o.should eq "\e]112\a"
    end

    it "falls back to OSC 112 when plain" do
      x.p.reset_colors
      x.o.should eq "\e]112\a"
    end

    it "wraps the fallback in DCS under tmux" do
      x.p.emulator.tmux = true
      x.p.reset_colors
      x.o.should eq "\ePtmux;\e\e]112\a\e\\"
      x.p.emulator.tmux = false
    end
  end

  describe "dynamic_colors" do
    it "uses the Cs capability with terminfo" do
      x.t.dynamic_colors "red"
      x.o.should eq "\e]12;red\a"
    end

    it "falls back to OSC 12 when plain" do
      x.p.dynamic_colors "red"
      x.o.should eq "\e]12;red\a"
    end
  end
end
