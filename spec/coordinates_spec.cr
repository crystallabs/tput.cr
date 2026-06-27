require "./spec_helper"

# Runs *block* with TPUT_SCREEN_SIZE set to *val*, restoring the previous value
# (or absence) afterwards so the global ENV doesn't leak across specs.
private def with_screen_size_env(val : String, &)
  saved = ENV["TPUT_SCREEN_SIZE"]?
  ENV["TPUT_SCREEN_SIZE"] = val
  begin
    yield
  ensure
    if saved
      ENV["TPUT_SCREEN_SIZE"] = saved
    else
      ENV.delete "TPUT_SCREEN_SIZE"
    end
  end
end

# Non-tty output, so size_from_ioctl/Term::Screen.size are skipped and the
# result reflects only TPUT_SCREEN_SIZE (or the built-in default).
private def screen_for_env(val : String) : Tput::Namespace::Size
  with_screen_size_env val do
    Tput.new(input: IO::Memory.new, output: IO::Memory.new, probe: false).screen
  end
end

describe "Tput::Coordinates#get_screen_size" do
  it "honors a well-formed TPUT_SCREEN_SIZE (rows x cols)" do
    s = screen_for_env "20x10"
    s.height.should eq 20
    s.width.should eq 10
  end

  it "falls back to the default for a malformed value instead of crashing" do
    # A single number, non-numeric, and junk must not raise IndexError /
    # ArgumentError at startup — they fall through to the default size.
    {"80", "abc", "12xyz", "x", ""}.each do |bad|
      s = screen_for_env bad
      s.width.should eq Tput::DEFAULT_SCREEN_SIZE.width
      s.height.should eq Tput::DEFAULT_SCREEN_SIZE.height
    end
  end
end
