describe Tput::Output::Text do

  x = Tput::Test.new

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

        t[0].el(Tput::Namespace::LineDirection::Right).should be_true
        x.o.should eq "\e[K"

        t[0].el(Tput::Namespace::LineDirection::Left).should be_true
        x.o.should eq "\e[1K"

        t[0].el(Tput::Namespace::LineDirection::All).should be_true
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

        t[0].pos 0,0; x.output.clear
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
        t[0].pos 8,9; x.output.clear

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

        t[0].cursor.x=0
        t[0].cursor.y=0

        t[0].restore_cursor.should be_true
        t[0].cursor.x.should eq 12
        t[0].cursor.y.should eq 10

        t[0].rc.should be_true
        sc.x.should eq 12 # Saved position should not change on restore
        sc.y.should eq 10
      end
    end
  end

  # TODO test lsave/lrestore
  
end
