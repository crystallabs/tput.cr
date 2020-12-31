describe Tput::Output::Cursor do

  x = Tput::Test.new

  describe "cursor_pos" do

    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].cursor_pos(0, 0).should be_true
        x.o.should eq "\e[1;1H"
        t[0].cursor.x.should eq 0
        t[0].cursor.y.should eq 0

        t[0].cup(19, 21).should be_true
        x.o.should eq "\e[20;22H"
        t[0].cursor.x.should eq 21
        t[0].cursor.y.should eq 19

        t[0].pos(100_000, 100_000).should be_true
        x.o.should eq "\e[24;80H"
        t[0].cursor.x.should eq 79
        t[0].cursor.y.should eq 23

        t[0].cursor_position(-10, -6).should be_true
        x.o.should eq "\e[15;75H"
        t[0].cursor.x.should eq 74
        t[0].cursor.y.should eq 14
      end
    end

  end

  # ----

  describe "cursor_next_line" do
    it "works with terminfo" do
      x.t.sety 0; x.output.clear
      x.t.cursor_next_line
      x.o.should eq "\e[1E"
    end

    it "works plain" do
      x.t.sety 0; x.output.clear
      x.p.cursor_next_line 3
      x.o.should eq "\e[3E"
    end
  end

  describe "reset_cursor_color" do
    pending "works with terminfo" do
      x.t.emulator.tmux= true
      x.t.reset_cursor_color
      x.o.should eq "\e]112\a"
    end

    it "works plain" do
      x.p.emulator.tmux= true # Also test wrapping in DCS sequences
      x.p.reset_cursor_color
      x.o.should eq "\ePtmux;\e\e]112\a\e\\"
      x.p.emulator.tmux= false
    end
  end

  describe "dynamic_cursor_color" do
    pending "works" do
    end
  end
  
end
