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

  describe "force_unicode constructor option" do
    it "is honored instead of being forced always-on (env auto-detect otherwise)" do
      with_env({
        "NCURSES_FORCE_UNICODE" => nil, "XTERM_LOCALE" => nil, "LANG" => nil,
        "LANGUAGE" => nil, "LC_ALL" => nil, "LC_CTYPE" => nil, "TERM" => "xterm",
      }) do
        # Default (not forced): env decides, and with no UTF-8 indicator that's
        # false — proving detect_unicode actually runs (it was dead before).
        auto = plain_tput
        auto.force_unicode?.should be_false
        auto.features.unicode?.should be_false
        auto.features.sources["unicode"].should contain "default"

        # Explicit force_unicode: true overrides the environment.
        forced = Tput.new(
          input: IO::Memory.new, output: IO::Memory.new,
          screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false,
          force_unicode: true)
        forced.force_unicode?.should be_true
        forced.features.unicode?.should be_true
        forced.features.sources["unicode"].should eq "Tput#force_unicode constructor option"
      end
    end
  end

  describe "hardware cursor styling detection" do
    it "flags xterm-family terminals as cursor-styleable (DECSCUSR + OSC 12)" do
      with_env({"TERM" => "xterm-256color", "ITERM_SESSION_ID" => nil}) do
        f = plain_tput.features
        f.cursor_style?.should be_true
        f.cursor_color?.should be_true
        f.sources["cursor_style"].should contain "DECSCUSR"
        f.sources["cursor_color"].should contain "OSC 12"
      end
    end

    it "flags iTerm2 as cursor-styleable via env even on an unknown TERM" do
      with_env({"TERM" => "dumb", "ITERM_SESSION_ID" => "w0t0p0:UUID"}) do
        f = plain_tput.features
        f.cursor_style?.should be_true
        f.sources["cursor_style"].should contain "iTerm2"
      end
    end

    it "does not flag an unknown terminal" do
      with_env({"TERM" => "dumb", "ITERM_SESSION_ID" => nil}) do
        f = plain_tput.features
        f.cursor_style?.should be_false
        f.cursor_color?.should be_false
        f.sources["cursor_style"].should contain "default"
      end
    end

    it "surfaces the cursor capabilities in the dump" do
      with_env({"TERM" => "xterm-256color"}) do
        t = plain_tput
        t.features.static_detections.has_key?("cursor_style").should be_true
        io = IO::Memory.new
        t.dump io
        io.to_s.should contain "cursor_style"
      end
    end
  end

  describe "ACS parsing" do
    # acsc is a list of (canonical, terminal-specific) pairs. With a non-identity
    # mapping the canonical codes are '0' (BLOCK) and 'm' (LLCORNER); 'q' and 'x'
    # are only terminal-specific bytes and must not become canonical keys.
    it "walks acs_chars pairwise and keys off the canonical (first) char" do
      t = terminfo_tput { |ti| ti.set(Unibilium::Entry::String::Acs_chars, "0qmx") }
      f = t.features

      idx = f.broken_acs? ? 2 : 1
      glyph0 = Tput::ACSC::Data['0'][idx].as(Char)
      glyphm = Tput::ACSC::Data['m'][idx].as(Char)

      f.acsc['0'].should eq glyph0
      f.acsc['m'].should eq glyphm
      # 'q'/'x' are pair-second members, never canonical keys.
      f.acsc.has_key?('q').should be_false
      f.acsc.has_key?('x').should be_false

      # Reverse map points the glyph back to its canonical char.
      f.acscr[glyph0].should eq '0'
      f.acscr[glyphm].should eq 'm'
    end
  end

  describe "hardware cursor live probing" do
    it "confirms cursor styling from a DECSCUSR (` q`) DECRQSS readback" do
      with_env({"TERM" => "dumb", "ITERM_SESSION_ID" => nil}) do
        t = plain_tput
        t.features.cursor_style?.should be_false
        t.probe_consume truecolor_probe_io("\eP1$r2 q\e\\"), 1.second
        t.features.cursor_style?.should be_true
        t.features.sources["cursor_style"].should contain "DECSCUSR"
      end
    end

    it "does not confirm cursor styling from a `0$r` rejection" do
      with_env({"TERM" => "dumb", "ITERM_SESSION_ID" => nil}) do
        t = plain_tput
        t.probe_consume truecolor_probe_io("\eP0$r\e\\"), 1.second
        t.features.cursor_style?.should be_false
      end
    end

    it "confirms cursor color from an OSC 12 reply" do
      with_env({"TERM" => "dumb", "ITERM_SESSION_ID" => nil}) do
        t = plain_tput
        t.features.cursor_color?.should be_false
        io = IO::Memory.new
        io << "\e]12;rgb:1111/2222/3333\e\\" # OSC 12 cursor-color report
        io << "\e[?62;1;6c"                  # DA1 terminator
        io.rewind
        t.probe_consume io, 1.second
        t.features.cursor_color?.should be_true
        t.features.sources["cursor_color"].should contain "OSC 12"
      end
    end
  end
end
