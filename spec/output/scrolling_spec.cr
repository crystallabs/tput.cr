describe Tput::Output::Scrolling do

  x = Tput::Test.new

  describe "index" do
    it "works with terminfo" do
      t = {x.t, "terminfo"}
      t[0].setyx 10, 10
      x.o
      ypos = t[0].cursor.y

      t[0].index.should be_true
      x.o.should eq "\n"
      t[0].cursor.y.should eq ypos+1
      t[0].cursor.x.should eq 10

      t[0].scroll_forward.should be_true
      x.o.should eq "\n"
      t[0].cursor.y.should eq ypos+2
      t[0].cursor.x.should eq 10

      t[0].ind.should be_true
      x.o.should eq "\n"
      t[0].cursor.y.should eq ypos+3
      t[0].cursor.x.should eq 10

      # Now test that at the end the y coordinate does not keep increasing
      t[0].sety 10000 # Make sure we're on the last line of screen
      x.o # Read/empty the buffer
      ypos = t[0].cursor.y

      t[0].index.should be_true
      x.o.should eq "\n"
      t[0].cursor.y.should eq ypos
      t[0].cursor.x.should eq 10

      t[0].ind.should be_true
      x.o.should eq "\n"
      t[0].cursor.y.should eq ypos
      t[0].cursor.x.should eq 10
    end

    it "works with plain" do
      t = {x.p, "plain"}
      t[0].setyx 10, 10
      x.o
      ypos = t[0].cursor.y

      t[0].index.should be_true
      x.o.should eq "\eD"
      t[0].cursor.y.should eq ypos+1
      t[0].cursor.x.should eq 10

      t[0].scroll_forward.should be_true
      x.o.should eq "\eD"
      t[0].cursor.y.should eq ypos+2
      t[0].cursor.x.should eq 10

      t[0].ind.should be_true
      x.o.should eq "\eD"
      t[0].cursor.y.should eq ypos+3
      t[0].cursor.x.should eq 10

      # Now test that at the end the y coordinate does not keep increasing
      t[0].sety 10000 # Make sure we're on the last line of screen
      x.o # Read/empty the buffer
      ypos = t[0].cursor.y

      t[0].index.should be_true
      x.o.should eq "\eD"
      t[0].cursor.y.should eq ypos
      t[0].cursor.x.should eq 10

      t[0].ind.should be_true
      x.o.should eq "\eD"
      t[0].cursor.y.should eq ypos
      t[0].cursor.x.should eq 10
    end

  end

  describe "set_scroll_region" do

    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].set_scroll_region(0, 0).should be_true
        x.o.should eq "\e[1;1r"
        t[0].scroll_top.should eq 0
        t[0].scroll_bottom.should eq 0

        t[0].csr(19, 21).should be_true
        x.o.should eq "\e[20;22r"
        t[0].scroll_top.should eq 19
        t[0].scroll_bottom.should eq 21

        #Log.trace { t[0].screen }

        t[0].decstbm(100_000, 100_000).should be_true
        x.o.should eq "\e[24;24r"
        t[0].scroll_top.should eq 23
        t[0].scroll_bottom.should eq 23

        t[0].set_scroll_region(-10, -6).should be_true
        x.o.should eq "\e[15;19r"
        t[0].scroll_top.should eq 14
        t[0].scroll_bottom.should eq 18
      end
    end

  end
  
end
