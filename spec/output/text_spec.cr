describe Tput::Output::Text do
  x = Tput::Test.new
  y = Tput::Test.new

  describe "horizontal_tabulation_set" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].horizontal_tabulation_set.should be_true
        x.o.should eq "\eH"
        t[0].horizontal_tab_set.should be_true
        x.o.should eq "\eH"
        t[0].hts.should be_true
        x.o.should eq "\eH"
      end
    end
  end

  describe "shift_out" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].shift_out.should be_true
        x.o.should eq "\x0e"
        t[0].so.should be_true
        x.o.should eq "\x0e"
      end
    end
  end

  describe "shift_in" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].shift_in.should be_true
        x.o.should eq "\x0f"
        t[0].si.should be_true
        x.o.should eq "\x0f"
      end
    end
  end

  describe "carriage_return" do
    [{y.t, "terminfo"}, {y.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].setyx 0, 10
        y.o
        ypos = t[0].cursor.y

        t[0].carriage_return.should be_true
        y.o.should eq "\r"
        t[0].cursor.y.should eq ypos
        t[0].cursor.x.should eq 0

        t[0].setyx 0, 10
        y.o
        ypos = t[0].cursor.y

        t[0].cr.should be_true
        y.o.should eq "\r"
        t[0].cursor.y.should eq ypos
        t[0].cursor.x.should eq 0
      end
    end
  end

  describe "form_feed" do
    [{y.t, "terminfo"}, {y.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].setyx 0, 10
        y.o
        ypos = t[0].cursor.y

        # Test all aliases

        t[0].form_feed.should be_true
        y.o.should eq "\f"
        t[0].cursor.y.should eq ypos + 1
        t[0].cursor.x.should eq 10

        t[0].ff.should be_true
        y.o.should eq "\f"
        t[0].cursor.y.should eq ypos + 2
        t[0].cursor.x.should eq 10

        # Now test that at the end the y coordinate does not keep increasing
        t[0].sety 10000 # Make sure we're on the last line of screen
        y.o             # Read/empty the buffer
        ypos = t[0].cursor.y

        t[0].ff.should be_true
        y.o.should eq "\f"
        t[0].cursor.y.should eq ypos
        t[0].cursor.x.should eq 10

        t[0].ff.should be_true
        y.o.should eq "\f"
        t[0].cursor.y.should eq ypos
        t[0].cursor.x.should eq 10
      end
    end
  end

  describe "vertical_tab" do
    [{y.t, "terminfo"}, {y.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].setyx 0, 10
        y.o
        ypos = t[0].cursor.y

        # Test all aliases

        t[0].vertical_tab.should be_true
        y.o.should eq "\v"
        t[0].cursor.y.should eq ypos + 1
        t[0].cursor.x.should eq 10

        t[0].vtab.should be_true
        y.o.should eq "\v"
        t[0].cursor.y.should eq ypos + 2
        t[0].cursor.x.should eq 10

        t[0].vt.should be_true
        y.o.should eq "\v"
        t[0].cursor.y.should eq ypos + 3
        t[0].cursor.x.should eq 10

        # Now test that at the end the y coordinate does not keep increasing
        t[0].sety 10000 # Make sure we're on the last line of screen
        y.o             # Read/empty the buffer
        ypos = t[0].cursor.y

        t[0].vtab.should be_true
        y.o.should eq "\v"
        t[0].cursor.y.should eq ypos
        t[0].cursor.x.should eq 10

        t[0].vt.should be_true
        y.o.should eq "\v"
        t[0].cursor.y.should eq ypos
        t[0].cursor.x.should eq 10
      end
    end
  end

  describe "line_feed" do
    [{y.t, "terminfo"}, {y.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].setyx 0, 10
        y.o
        ypos = t[0].cursor.y

        # Test all aliases

        t[0].line_feed.should be_true
        y.o.should eq "\n"
        t[0].cursor.y.should eq ypos + 1
        t[0].cursor.x.should eq 0

        t[0].feed.should be_true
        y.o.should eq "\n"
        t[0].cursor.y.should eq ypos + 2
        t[0].cursor.x.should eq 0

        t[0].nel.should be_true
        y.o.should eq "\n"
        t[0].cursor.y.should eq ypos + 3
        t[0].cursor.x.should eq 0

        # Now test that at the end the y coordinate does not keep increasing
        t[0].sety 10000 # Make sure we're on the last line of screen
        y.o             # Read/empty the buffer
        ypos = t[0].cursor.y

        t[0].next_line.should be_true
        y.o.should eq "\n"
        t[0].cursor.y.should eq ypos
        t[0].cursor.x.should eq 0

        t[0].nel.should be_true
        y.o.should eq "\n"
        t[0].cursor.y.should eq ypos
        t[0].cursor.x.should eq 0
      end
    end
  end

  describe "backspace" do
    it "works with terminfo" do
      t = {y.t, "terminfo"}

      t[0].setx 3
      y.o # Read/empty the buffer

      # Since we are at x==3, we can backspace 3 times:

      t[0].backspace.should be_true
      t[0].cursor.x.should eq 2
      y.o.should eq "\u007F"

      t[0].bs.should be_true
      t[0].cursor.x.should eq 1
      y.o.should eq "\u007F"

      t[0].bs.should be_true
      t[0].cursor.x.should eq 0
      y.o.should eq "\u007F"

      # After that, x remains at 0

      t[0].bs.should be_true
      t[0].cursor.x.should eq 0
      y.o.should eq "\u007F"

      t[0].bs.should be_true
      t[0].cursor.x.should eq 0
      y.o.should eq "\u007F"
    end
    it "works with plain" do
      t = {y.p, "plain"}

      t[0].setx 3
      y.o # Read/empty the buffer

      # Since we are at x==3, we can backspace 3 times:

      t[0].backspace.should be_true
      t[0].cursor.x.should eq 2
      y.o.should eq "\b"

      t[0].bs.should be_true
      t[0].cursor.x.should eq 1
      y.o.should eq "\b"

      t[0].bs.should be_true
      t[0].cursor.x.should eq 0
      y.o.should eq "\b"

      # After that, nothing happens:

      t[0].bs.should be_true
      t[0].cursor.x.should eq 0
      y.o.should eq "\b"

      t[0].bs.should be_true
      t[0].cursor.x.should eq 0
      y.o.should eq "\b"
    end
  end

  describe "insert_line" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        expect_raises(ArgumentError) {
          t[0].insert_line 0
        }
        expect_raises(ArgumentError) {
          t[0].il -1
        }
      end
    end
    it "works with terminfo" do
      t = {x.t, "terminfo"}
      t[0].il.should be_true
      x.o.should eq "\e[L"

      t[0].il(1).should be_true
      x.o.should eq "\e[L"

      t[0].il(12).should be_true
      x.o.should eq "\e[12L"
    end
    it "works with plain" do
      t = {x.p, "plain"}
      t[0].il.should be_true
      x.o.should eq "\e[1L"

      t[0].il(1).should be_true
      x.o.should eq "\e[1L"

      t[0].il(12).should be_true
      x.o.should eq "\e[12L"
    end
  end

  describe "delete_line" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        expect_raises(ArgumentError) {
          t[0].delete_line 0
        }
        expect_raises(ArgumentError) {
          t[0].dl -1
        }
      end
    end
    it "works with terminfo" do
      t = {x.t, "terminfo"}
      t[0].dl.should be_true
      x.o.should eq "\e[M"

      t[0].dl(1).should be_true
      x.o.should eq "\e[M"

      t[0].dl(12).should be_true
      x.o.should eq "\e[12M"
    end
    it "works with plain" do
      t = {x.p, "plain"}
      t[0].dl.should be_true
      x.o.should eq "\e[1M"

      t[0].dl(1).should be_true
      x.o.should eq "\e[1M"

      t[0].dl(12).should be_true
      x.o.should eq "\e[12M"
    end
  end

  describe "erase_in_line" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[0]}" do
        t[0].erase_in_line.should be_true
        x.o.should eq "\e[K"

        t[0].el(Tput::LineDirection::Right).should be_true
        x.o.should eq "\e[K"

        t[0].el(Tput::LineDirection::Left).should be_true
        x.o.should eq "\e[1K"

        t[0].el(Tput::LineDirection::All).should be_true
        x.o.should eq "\e[2K"
      end
    end
  end

  describe "erase_character" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[0]}" do
        t[0].erase_character.should be_true
        x.o.should eq "\e[1X"

        t[0].ech(9).should be_true
        x.o.should eq "\e[9X"

        t[0].erase_chars(12).should be_true
        x.o.should eq "\e[12X"
      end
    end
  end

  describe "cursor_forward" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[0]}" do
        t[0].cursor_forward.should be_true
        x.o.should eq "\e[1C"
        t[0].cursor.x.should eq 1

        t[0].cuf(9).should be_true
        x.o.should eq "\e[9C"
        t[0].cursor.x.should eq 10

        t[0].right(12).should be_true
        x.o.should eq "\e[12C"
        t[0].cursor.x.should eq 22

        t[0].parm_right_cursor(2).should be_true
        x.o.should eq "\e[2C"
        t[0].cursor.x.should eq 24

        t[0].cursor_right(2).should be_true
        x.o.should eq "\e[2C"
        t[0].cursor.x.should eq 26

        t[0].pos 0, 0; x.output.clear
        t[0].cursor.x.should eq 0

        t[0].forward(100_000).should be_true
        x.o.should eq "\e[79C"
        t[0].cursor.x.should eq 79
      end
    end
  end

  describe "save & restore cursor" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[0]}" do
        t[0].pos 8, 9; x.output.clear

        t[0].saved_cursor.should be_nil

        t[0].save_cursor.should be_true

        t[0].pos 10, 12; x.output.clear
        t[0].sc.should be_true
        x.o.should eq "\e7"

        sc = t[0].saved_cursor.not_nil!
        sc.x.should eq sc.x
        sc.y.should eq sc.y

        sc.x.should eq 12
        sc.y.should eq 10

        t[0].cursor.x = 0
        t[0].cursor.y = 0

        t[0].restore_cursor.should be_true
        t[0].cursor.x.should eq 12
        t[0].cursor.y.should eq 10

        t[0].rc.should be_true
        sc.x.should eq 12 # Saved position should not change on restore
        sc.y.should eq 10

        x.o # Read/empty the buffer
      end
    end
  end

  describe "delete_columns" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].delete_columns.should be_true
        x.o.should eq "\e[1 ~"
        t[0].decdc(7).should be_true
        x.o.should eq "\e[7 ~"
      end
    end
  end

  describe "insert_columns" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].insert_columns.should be_true
        x.o.should eq "\e[1 }"
        t[0].decic(7).should be_true
        x.o.should eq "\e[7 }"
      end
    end
  end

  # TODO test lsave/lrestore

  describe "echo" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].echo("test").should be_true
        x.o.should eq "test"
        # TODO - test with attributes
      end
    end
  end
end
