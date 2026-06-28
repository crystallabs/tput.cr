describe Tput::Output::Text do
  x = Tput::Test.new

  describe "_attr empty array" do
    # An empty attribute list must NOT raise IndexError; it carries no
    # attribute and is treated like a blank/"normal" spec.
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "treats an empty array as normal/reset with #{t[1]}" do
        t[0]._attr([] of String, true).should eq "\e[m"
        t[0]._attr([] of String, false).should eq ""
      end
    end
  end

  describe "_attr negative 256-color" do
    # Only -1 was the documented "default" sentinel, but any negative value
    # must be treated as default rather than emitting a bogus SGR (e.g. -2
    # would otherwise fall through to `color < 16` and emit `\e[28m`).
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "treats -2 fg/bg as the default color with #{t[1]}" do
        t[0]._attr("-2 fg", true).should eq "\e[39m"
        t[0]._attr("-2 bg", true).should eq "\e[49m"
        # -1 (the documented sentinel) still behaves the same.
        t[0]._attr("-1 fg", true).should eq "\e[39m"
      end
    end
  end

  describe "edit/erase ops reject non-positive param" do
    # Mirrors insert_line/delete_line: a non-positive param raises ArgumentError
    # instead of emitting a malformed sequence like `\e[0X`.
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "raises on param == 0 with #{t[1]}" do
        expect_raises(ArgumentError) { t[0].insert_chars 0 }
        expect_raises(ArgumentError) { t[0].delete_chars 0 }
        expect_raises(ArgumentError) { t[0].erase_character 0 }
        expect_raises(ArgumentError) { t[0].repeat_preceding_character 0 }
        expect_raises(ArgumentError) { t[0].insert_columns 0 }
        expect_raises(ArgumentError) { t[0].delete_columns 0 }
        # Negative is rejected too.
        expect_raises(ArgumentError) { t[0].erase_character -1 }
      end
    end
  end
end
