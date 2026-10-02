require "../../spec_helper"

private def new_tput(output = IO::Memory.new)
  Tput.new input: IO::Memory.new(""), output: output,
    screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
end

describe "Tput::Output::Rectangles#select_change_extent (DECSACE)" do
  it "emits the mandatory `*` intermediate so it isn't parsed as DECREQTPARM" do
    buf = IO::Memory.new
    t = new_tput buf
    t.select_change_extent 2
    t.flush
    # Must be CSI Ps * x, not the bare CSI Ps x (which is DECREQTPARM).
    buf.to_s.should eq "\e[2*x"
    buf.to_s.should_not eq "\e[2x"
  end

  it "defaults Ps to 0" do
    buf = IO::Memory.new
    t = new_tput buf
    t.select_change_extent
    t.flush
    buf.to_s.should eq "\e[0*x"
  end
end
