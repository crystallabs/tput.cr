describe Tput::Output::Terminal do
  x = Tput::Test.new

  describe "manipulate_window (XTWINOPS)" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].manipulate_window(18).should be_true
        x.o.should eq "\e[18t"

        t[0].manipulate_window(8, 10, 20).should be_true
        x.o.should eq "\e[8;10;20t"

        t[0].xtwinops(8, 10, 20).should be_true
        x.o.should eq "\e[8;10;20t"
      end
    end
  end

  describe "resize_window" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].resize_window(24, 80).should be_true
        x.o.should eq "\e[8;24;80t"
      end
    end
  end

  describe "maximize_window" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].maximize_window.should be_true
        x.o.should eq "\e[8;65535;65535t"
      end
    end
  end
end
