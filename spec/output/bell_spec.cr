describe Tput::Output::Bell do

  x = Tput::Test.new

  describe "bell" do
    it "works with terminfo" do
      x.t.bell
      x.o.should eq "\x07"
    end

    it "works plain" do
      x.p.bel
      x.o.should eq "\x07"
    end
  end

  describe "warning bell volume" do
    it "works" do
      x.t.warning_bell_volume= Tput::Volume::High3
      x.o.should eq "\e[7} t"
      x.p.decswbv= Tput::Volume::High3
      x.o.should eq "\e[7} t"
    end
  end

  describe "margin bell volume" do
    it "works" do
      x.t.margin_bell_volume= Tput::Volume::Low2
      x.o.should eq "\e[3 u"
      x.p.decsmbv= Tput::Volume::Low2
      x.o.should eq "\e[3 u"
    end
  end
  
end
