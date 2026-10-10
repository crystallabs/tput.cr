require "./spec_helper"

# Canned probe replies: two CPRs (the ambiguous character's, then the VS16
# cluster's) and the DA1 terminator.
private def width_probe_io(ambiguous : Int32, vs16 : Int32)
  io = IO::Memory.new
  io << "\e[1;#{ambiguous + 1}R" << "\e[1;#{vs16 + 1}R" << "\e[?62;1;6c"
  io.rewind
  io
end

# `Tput::Emulator#vs16_widens?`: whether a VS16 emoji-presentation cluster
# advances the cursor two columns, as the width tables count it. Measured by
# the probe when it ran; by identity otherwise (kitty, Ghostty, WezTerm and
# iTerm2 widen; Apple Terminal advances one column).
describe Tput::Emulator do
  it "trusts every terminal but Apple Terminal to widen, absent a measurement" do
    x = Tput::Test.new
    em = Tput::Emulator.new x.t
    em.osxterm = false
    em.vs16_widens?.should be_true
    em.kitty = true
    em.vs16_widens?.should be_true
    em.osxterm = true
    em.vs16_widens?.should be_false
  end

  it "takes the probe's measurement over the identity" do
    x = Tput::Test.new
    em = Tput::Emulator.new x.t
    em.osxterm = true
    # `probe_consume` parses the replies in query order; `probe!` stores them.
    result = x.t.probe_consume width_probe_io(1, 2), 1.second
    result.ambiguous_width.should eq 1
    result.vs16_width.should eq 2
    x.t.features.vs16_width = result.vs16_width
    em.vs16_widens?.should be_true

    y = Tput::Test.new
    em2 = Tput::Emulator.new y.t
    em2.osxterm = false
    result = y.t.probe_consume width_probe_io(1, 1), 1.second
    result.vs16_width.should eq 1
    y.t.features.vs16_width = result.vs16_width
    em2.vs16_widens?.should be_false
  end

  it "re-measures the VS16 width on its own, in the current buffer" do
    x = Tput::Test.new
    io = IO::Memory.new "\e[?62;1;6c\e[1;2R"
    x.t.probe_vs16_consume(io, 1.second).should eq 1
    io = IO::Memory.new "\e[1;3R"
    x.t.probe_vs16_consume(io, 1.second).should eq 2
    x.t.probe_vs16_consume(IO::Memory.new, 1.second).should be_nil
    # Not a terminal: nothing is written, nothing measured.
    x.t.probe_vs16_width!.should be_nil
  end

  it "sends the VS16 cluster through the width probe" do
    x = Tput::Test.new
    x.t.build_probe_query.should contain "\r🖼\u{FE0F}\e[6n"
  end
end
