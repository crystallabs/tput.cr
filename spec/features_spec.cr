# Runs *block* with the given environment variables temporarily set (a `nil`
# value deletes the var), restoring the previous environment afterwards.
def with_env(vars : Hash(String, String?), &)
  saved = {} of String => String?
  vars.each_key { |k| saved[k] = ENV[k]? }
  vars.each { |k, v| v ? (ENV[k] = v) : ENV.delete(k) }
  begin
    yield
  ensure
    saved.each { |k, v| v ? (ENV[k] = v) : ENV.delete(k) }
  end
end

# A plain (terminfo-less) Tput so env-based detection is isolated from terminfo.
def plain_tput
  Tput.new(
    input: IO::Memory.new,
    output: IO::Memory.new,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false)
end

# Canned terminal input: an optional DECRQSS *dcs* reply followed by a DA1
# terminator (so `probe_consume` stops).
def truecolor_probe_io(dcs : String?)
  io = IO::Memory.new
  io << dcs if dcs
  io << "\e[?62;1;6c" # DA1
  io.rewind
  io
end

# A Tput backed by the current terminfo, after *mutate* tweaks its extensions.
def terminfo_tput(&)
  ti = Unibilium.from_env
  yield ti
  Tput.new(
    terminfo: ti,
    input: IO::Memory.new,
    output: IO::Memory.new,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false)
end

describe Tput::Features do
  describe "truecolor detection" do
    it "is false with no COLORTERM/terminfo indicator" do
      with_env({"COLORTERM" => nil}) do
        f = plain_tput.features
        f.truecolor?.should be_false
        f.sources["truecolor"].should contain "default"
      end
    end

    it %(detects COLORTERM="truecolor") do
      with_env({"COLORTERM" => "truecolor"}) do
        f = plain_tput.features
        f.truecolor?.should be_true
        f.number_of_colors.should eq 0x1000000
        f.sources["truecolor"].should eq %(env COLORTERM="truecolor")
        # number_of_colors provenance points back at the truecolor reason.
        f.sources["number_of_colors"].should contain "truecolor"
      end
    end

    it %(detects COLORTERM="24bit") do
      with_env({"COLORTERM" => "24bit"}) do
        plain_tput.features.truecolor?.should be_true
      end
    end

    it "ignores non-truecolor COLORTERM values" do
      with_env({"COLORTERM" => "rxvt"}) do
        plain_tput.features.truecolor?.should be_false
      end
    end

    it "detects the terminfo Tc capability" do
      with_env({"COLORTERM" => nil}) do
        f = terminfo_tput(&.extensions.add("Tc", true)).features
        f.truecolor?.should be_true
        f.sources["truecolor"].should eq "terminfo Tc capability"
      end
    end

    it "detects the terminfo RGB capability" do
      with_env({"COLORTERM" => nil}) do
        f = terminfo_tput(&.extensions.add("RGB", true)).features
        f.truecolor?.should be_true
        f.sources["truecolor"].should eq "terminfo RGB capability"
      end
    end

    it "detects terminfo setrgbf/setrgbb capabilities" do
      with_env({"COLORTERM" => nil}) do
        f = terminfo_tput(&.extensions.add("setrgbf", "\e[38m")).features
        f.truecolor?.should be_true
        f.sources["truecolor"].should contain "setrgbf"
      end
    end

    it "surfaces truecolor in the dump and detections" do
      with_env({"COLORTERM" => "truecolor"}) do
        t = plain_tput
        t.features.static_detections.has_key?("truecolor").should be_true
        io = IO::Memory.new
        t.dump io
        io.to_s.should contain "truecolor"
      end
    end
  end

  describe "truecolor live probing (DECRQSS)" do
    it "confirms truecolor when the SGR readback keeps the RGB triplet" do
      with_env({"COLORTERM" => nil}) do
        t = plain_tput
        t.features.truecolor?.should be_false
        t.probe_consume truecolor_probe_io("\eP1$r0;48:2::1:2:3m\e\\"), 1.second
        t.features.truecolor?.should be_true
        t.features.number_of_colors.should eq 0x1000000
        t.features.sources["truecolor"].should contain "DECRQSS"
      end
    end

    it "accepts the semicolon-form RGB readback too" do
      with_env({"COLORTERM" => nil}) do
        t = plain_tput
        t.probe_consume truecolor_probe_io("\eP1$r0;48;2;1;2;3m\e\\"), 1.second
        t.features.truecolor?.should be_true
      end
    end

    it "does not confirm when the terminal downsamples to indexed color" do
      with_env({"COLORTERM" => nil}) do
        t = plain_tput
        t.probe_consume truecolor_probe_io("\eP1$r0;48;5;16m\e\\"), 1.second
        t.features.truecolor?.should be_false
      end
    end

    it "does not confirm when there is no DECRQSS reply" do
      with_env({"COLORTERM" => nil}) do
        t = plain_tput
        t.probe_consume truecolor_probe_io(nil), 1.second
        t.features.truecolor?.should be_false
      end
    end
  end
end
