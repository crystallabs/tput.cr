require "../spec_helper"

private def tmux_tput(output)
  Tput.new(input: IO::Memory.new(""), output: output,
    screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false).tap do |t|
    t.emulator.tmux = true
    t.emulator.screen = false
  end
end

# DEC private modes 2026 (synchronized output), 2027 (grapheme clustering) and
# 2031 (color-scheme notifications), plus the title-mode set/reset pair, are now
# emitted through `_tprint` so they are DCS-passthrough-wrapped under a terminal
# multiplexer like the other multiplexer-aware sequences. On a plain terminal
# the emitted bytes are unchanged.
describe "DEC private modes / title modes via _tprint" do
  x = Tput::Test.new

  describe "plain (non-multiplexed) emission is unchanged" do
    it "begin/end synchronized update (DEC 2026)" do
      x.t.begin_synchronized_update
      x.o.should eq "\e[?2026h"
      x.t.end_synchronized_update
      x.o.should eq "\e[?2026l"
    end

    it "enable/disable grapheme clustering (DEC 2027)" do
      x.t.enable_grapheme_clustering
      x.o.should eq "\e[?2027h"
      x.t.disable_grapheme_clustering
      x.o.should eq "\e[?2027l"
    end

    it "enable/disable color-scheme notifications (DEC 2031)" do
      x.t.enable_color_scheme_notifications
      x.o.should eq "\e[?2031h"
      x.t.disable_color_scheme_notifications
      x.o.should eq "\e[?2031l"
    end

    it "set/reset title modes (symmetric)" do
      x.t.set_title_mode_feature 0, 2
      x.o.should eq "\e[>0;2t"
      x.t.reset_title_modes 0, 2
      x.o.should eq "\e[>0;2T"
    end
  end

  describe "wrapped in the tmux DCS passthrough under a multiplexer" do
    it "begin/end synchronized update (DEC 2026)" do
      buf = IO::Memory.new
      t = tmux_tput buf
      t.begin_synchronized_update
      buf.to_s.should eq "\ePtmux;\e\e[?2026h\e\\"

      buf.clear
      t.end_synchronized_update
      buf.to_s.should eq "\ePtmux;\e\e[?2026l\e\\"
    end

    it "enable/disable grapheme clustering (DEC 2027)" do
      buf = IO::Memory.new
      t = tmux_tput buf
      t.enable_grapheme_clustering
      buf.to_s.should eq "\ePtmux;\e\e[?2027h\e\\"

      buf.clear
      t.disable_grapheme_clustering
      buf.to_s.should eq "\ePtmux;\e\e[?2027l\e\\"
    end

    it "enable/disable color-scheme notifications (DEC 2031)" do
      buf = IO::Memory.new
      t = tmux_tput buf
      t.enable_color_scheme_notifications
      buf.to_s.should eq "\ePtmux;\e\e[?2031h\e\\"

      buf.clear
      t.disable_color_scheme_notifications
      buf.to_s.should eq "\ePtmux;\e\e[?2031l\e\\"
    end

    it "set/reset title modes (symmetric)" do
      buf = IO::Memory.new
      t = tmux_tput buf
      t.set_title_mode_feature 0, 2
      buf.to_s.should eq "\ePtmux;\e\e[>0;2t\e\\"

      buf.clear
      t.reset_title_modes 0, 2
      buf.to_s.should eq "\ePtmux;\e\e[>0;2T\e\\"
    end
  end
end
