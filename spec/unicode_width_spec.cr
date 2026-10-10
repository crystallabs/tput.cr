require "./spec_helper"

# Display widths of the characters whose column count terminals disagree on
# least — East-Asian wide, emoji with and without a forced presentation —
# pinned so the `WIDE` table stays exact where it matters most: a glyph
# counted 2 columns that a terminal draws in 1 shifts the rest of its row.
describe Tput::Unicode do
  u = Tput::Unicode

  it "counts East-Asian wide and fullwidth characters as 2 columns" do
    u.display_width("中").should eq 2
    u.display_width("ｆｕｌｌ").should eq 8
    u.display_width("한").should eq 2
  end

  it "counts emoji-presentation pictographs as 2 columns" do
    {"💾", "📄", "🚀", "🌈", "⚡", "⏩", "⌛", "🟢", "🥳", "🪐"}.each do |e|
      u.display_width(e).should eq(2), e.inspect
    end
  end

  it "counts text-presentation pictographs as 1 column" do
    # Supplementary-plane ones were counted 2 (their whole blocks were listed
    # wide) although terminals draw them in 1 column, like their BMP peers.
    {"🖼", "🗑", "🏷", "🌧", "🌡", "🛡", "🗄", "🖌", "👁", "🗖", "🕴", "🛠"}.each do |e|
      u.display_width(e).should eq(1), e.inspect
    end
    {"⚠", "✂", "☎", "✏", "ℹ", "☀", "⏱"}.each do |e|
      u.display_width(e).should eq(1), e.inspect
    end
  end

  it "promotes a text-presentation pictograph to 2 columns with VS16" do
    {"🖼️", "🗑️", "⚠️", "✂️", "☀️"}.each do |e|
      u.display_width(e).should eq(2), e.inspect
    end
  end

  it "keeps flags, skin tones and ZWJ sequences at 2 columns" do
    u.display_width("🇺🇸").should eq 2
    u.display_width("👍🏽").should eq 2
    u.display_width("👨‍👩‍👧").should eq 2
  end

  it "measures a mixed string by the sum of its graphemes" do
    u.display_width("a🖼 b💾 c").should eq 8
  end
end
