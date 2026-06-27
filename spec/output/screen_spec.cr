describe Tput::Output::Screen do
  x = Tput::Test.new

  describe "erase_in_display" do
    it "uses the terminfo `ed` capability for the default Below case" do
      x.t.erase_in_display
      x.o.should eq "\e[J"

      x.t.erase_in_display Tput::Erase::Below
      x.o.should eq "\e[J"
    end

    it "emits the explicit CSI for Above/All even with terminfo" do
      # `ed`/`clr_eos` is hardcoded to erase-below and ignores any parameter,
      # so the non-default extents must not be routed through it.
      x.t.erase_in_display Tput::Erase::Above
      x.o.should eq "\e[1J"

      x.t.erase_in_display Tput::Erase::All
      x.o.should eq "\e[2J"
    end

    it "works plain" do
      x.p.erase_in_display
      x.o.should eq "\e[0J"

      x.p.erase_in_display Tput::Erase::All
      x.o.should eq "\e[2J"
    end
  end
end
