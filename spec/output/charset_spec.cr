alias C = Tput::Namespace::Charset

describe Tput::Output::Charset do

  x = Tput::Test.new

  describe "generic alt_charset_mode" do
    it "works with terminfo" do
      x.t.smacs
      x.o.should eq "\e(0"

      x.t.rmacs
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
      x.t.charset= C::UK
      x.o.should eq "\e(A"

      x.t.charset= C::Isolatin
      x.o.should eq "\e(/A"

      x.t.rmacs
      x.o.should eq "\e(B"
    end

    it "works plain" do
      x.p.charset= C::UK
      x.o.should eq "\e(A"

      x.p.charset= C::Isolatin
      x.o.should eq "\e(/A"

      x.p.rmacs
      x.o.should eq "\e(B"
    end
  end
  
end
