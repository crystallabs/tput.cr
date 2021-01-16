describe Tput::Output::Misc do
  x = Tput::Test.new

  describe "nul" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].nul.should be_true
        x.o.should eq "\x80"
        t[0].null.should be_true
        x.o.should eq "\x80"
        t[0].pad.should be_true
        x.o.should eq "\x80"
      end
    end
  end

  describe "escape" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].escape.should be_true
        x.o.should eq "\e"
        t[0].esc.should be_true
        x.o.should eq "\e"
      end
    end
  end
end
