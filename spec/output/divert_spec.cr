require "../spec_helper"

private def new_tput(output = IO::Memory.new)
  Tput.new input: IO::Memory.new(""), output: output,
    screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
end

# When a caller sets the `@ret` diverter (e.g. Crysterm's `divert`, which routes
# escape sequences into an `IO::Memory`), *every* output primitive must write to
# it — including the internal-buffer fast paths used while `use_buffer` is on
# (which is Tput's default). The block-form `_print` already honored `@ret`; this
# verifies the args/string and byte fast paths do too, so output isn't silently
# leaked into `@_buf` (and from there to the real terminal) instead of captured.
describe "Tput output diverter (@ret) with buffering enabled" do
  it "routes string (args-form) output to @ret, not the buffer" do
    real_out = IO::Memory.new
    t = new_tput real_out
    t.use_buffer?.should be_true # default — the path under test

    diverter = IO::Memory.new
    t.ret = diverter
    t.save_cursor_a # emits via args-form `_print "\e[s"`
    t.ret = nil

    diverter.to_s.should eq "\e[s"
    # Nothing leaked into the internal buffer / real output.
    t.flush
    real_out.to_s.should eq ""
  end

  it "routes block-form output to @ret as well (consistency guard)" do
    real_out = IO::Memory.new
    t = new_tput real_out

    diverter = IO::Memory.new
    t.ret = diverter
    t.cursor_position 1, 2 # emits via block-form `_print { |io| ... }`
    t.ret = nil

    diverter.to_s.should eq "\e[2;3H"
    t.flush
    real_out.to_s.should eq ""
  end
end
