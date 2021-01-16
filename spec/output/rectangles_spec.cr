describe Tput::Output::Scrolling do
  x = Tput::Test.new

  describe "selective_erase_rectangle" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].selective_erase_rectangle(10, 12, 21, 23).should be_true
        x.o.should eq "\e[11;13;22;24${"
        t[0].decsera.should be_true
        x.o.should eq "\e[1;1;#{t[0].screen.height};#{t[0].screen.width}${"
      end
    end
  end

  describe "erase_rectangle" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].erase_rectangle(10, 12, 21, 23).should be_true
        x.o.should eq "\e[11;13;22;24$z"
        t[0].decera.should be_true
        x.o.should eq "\e[1;1;#{t[0].screen.height};#{t[0].screen.width}$z"
      end
    end
  end
end
