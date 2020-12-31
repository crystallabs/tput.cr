describe Tput::Output::Scrolling do

  x = Tput::Test.new

  describe "set_scroll_region" do

    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].set_scroll_region 0, 0
        x.o.should eq "\e[1;1r"
        t[0].scroll_top.should eq 0
        t[0].scroll_bottom.should eq 0

        t[0].set_scroll_region 19, 21
        x.o.should eq "\e[20;22r"
        t[0].scroll_top.should eq 19
        t[0].scroll_bottom.should eq 21

        #Log.trace { t[0].screen }

        t[0].set_scroll_region 100_000, 100_000
        x.o.should eq "\e[24;24r"
        t[0].scroll_top.should eq 23
        t[0].scroll_bottom.should eq 23

        t[0].set_scroll_region -10, -6
        x.o.should eq "\e[15;19r"
        t[0].scroll_top.should eq 14
        t[0].scroll_bottom.should eq 18
      end
    end

  end
  
end
