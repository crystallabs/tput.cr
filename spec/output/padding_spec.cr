describe "Padding" do
  x = Tput::Test.new

  describe "detection" do
    it "is enabled by default" do
      x.t.features.padding?.should be_true
    end

    it "is disabled when NCURSES_NO_PADDING is set" do
      ENV["NCURSES_NO_PADDING"] = "1"
      begin
        t = Tput.new \
          terminfo: x.term,
          input: IO::Memory.new,
          output: IO::Memory.new,
          screen_size: Tput::DEFAULT_SCREEN_SIZE
        t.features.padding?.should be_false
      ensure
        ENV.delete "NCURSES_NO_PADDING"
      end
    end
  end

  describe "#_pad_write" do
    it "writes content unchanged when there are no padding markers" do
      x.p._pad_write "\e[2J".to_slice
      x.o.should eq "\e[2J"
    end

    it "strips advisory padding markers (terminal assumed to have flow control)" do
      # The plain instance has no terminfo, so `needs_xon_xoff` is unset and
      # `xon` is assumed true -> advisory padding is skipped (markers stripped,
      # no delay).
      x.p._pad_write "abc$<5>def".to_slice
      x.o.should eq "abcdef"
    end

    it "strips proportional and fractional padding markers" do
      x.p._pad_write "a$<10*>b$<2.5>c".to_slice
      x.o.should eq "abc"
    end

    it "strips a mandatory padding marker (and honors its delay)" do
      x.p._pad_write "x$<1/>y".to_slice
      x.o.should eq "xy"
    end
  end
end
