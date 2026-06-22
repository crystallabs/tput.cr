alias C = Tput::Namespace::Charset

describe Tput::Output::Charset do
  x = Tput::Test.new

  describe "generic alt_charset_mode" do
    it "works with terminfo" do
      x.t.enter_alt_charset_mode
      x.o.should eq "\e(0"

      x.t.exit_alt_charset_mode
      x.o.should eq "\e(B"
    end

    it "works plain" do
      x.p.smacs
      x.o.should eq "\e(0"

      x.p.rmacs
      x.o.should eq "\e(B"
    end
  end

  describe "specific alt_charset_mode" do
    it "works with terminfo" do
      x.t.charset = C::UK
      x.o.should eq "\e(A"

      x.t.charset = C::Isolatin
      x.o.should eq "\e(/A"

      x.t.rmacs
      x.o.should eq "\e(B"
    end

    it "works plain" do
      x.p.charset = C::UK
      x.o.should eq "\e(A"

      x.p.charset = C::Isolatin
      x.o.should eq "\e(/A"

      x.p.rmacs
      x.o.should eq "\e(B"
    end
  end

  describe "enable_acs" do
    # xterm-256color does not define `ena_acs`, so both terminfo and plain fall
    # back to the hardcoded ACS-designation sequence.
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].enable_acs
        x.o.should eq "\e(B\e)0"

        t[0].ena_acs # alias
        x.o.should eq "\e(B\e)0"
      end
    end
  end
end
