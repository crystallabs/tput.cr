describe Tput::Output::Charset do

  x = Tput::Test.new

  describe "enter_alt_charset_mode" do
    it "works with terminfo" do
      x.t.smacs
      x.o.should eq x.esc "(0"

      x.t.rmacs
      x.o.should eq x.esc "(B"
    end

    it "works plain" do
    end
  end
  
end
