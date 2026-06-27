describe Tput::Output::Bell do
  x = Tput::Test.new

  describe "bell" do
    it "works with terminfo" do
      x.t.bell.should be_true
      x.o.should eq "\x07"
      x.t.bel.should be_true
      x.o.should eq "\x07"
    end
    it "works plain" do
      x.p.bell.should be_true
      x.o.should eq "\x07"
      x.p.bel.should be_true
      x.o.should eq "\x07"
    end
  end

  describe "warning bell volume" do
    it "works" do
      x.t.warning_bell_volume = Tput::Volume::High3
      x.o.should eq "\e[7 t"
      x.p.decswbv = Tput::Volume::High3
      x.o.should eq "\e[7 t"
    end
  end

  describe "margin bell volume" do
    it "works" do
      x.t.margin_bell_volume = Tput::Volume::Low2
      x.o.should eq "\e[3 u"
      x.p.decsmbv = Tput::Volume::Low2
      x.o.should eq "\e[3 u"
    end

    it "silences with Volume::Off (DECSMBV Ps=0 is high, so it maps to Ps=1)" do
      x.t.margin_bell_volume = Tput::Volume::Off
      x.o.should eq "\e[1 u"
      # DECSWBV keeps Ps=0 as off, so the warning bell is left untranslated.
      x.t.warning_bell_volume = Tput::Volume::Off
      x.o.should eq "\e[0 t"
    end
  end
end
