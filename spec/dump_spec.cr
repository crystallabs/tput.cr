describe "Tput#dump / detections" do
  x = Tput::Test.new

  describe "detections" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "exposes value + source for emulator and features with #{t[1]}" do
        d = t[0].detections
        d.keys.should eq ["emulator", "features"]

        # Every emulator flag has a value and a non-empty source description.
        emu = d["emulator"]
        emu.has_key?("xterm").should be_true
        emu.each do |_name, det|
          det.source.empty?.should be_false
          det.source.should_not eq "unknown"
        end

        # Features: number_of_colors and its provenance are present.
        feat = d["features"]
        feat.has_key?("number_of_colors").should be_true
        feat.has_key?("unicode").should be_true
        feat["unicode"].source.empty?.should be_false

        # Every detected ANSI fast-path feature is reported (including
        # ansi_edit/ansi_scroll, which were once missing from the dump).
        {"ansi_cursor", "ansi_hpa", "ansi_vpa", "ansi_edit", "ansi_scroll"}.each do |k|
          feat.has_key?(k).should be_true
          feat[k].source.empty?.should be_false
          feat[k].source.should_not eq "unknown"
        end
      end
    end
  end

  describe "dump" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "writes an aligned, sectioned report with #{t[1]}" do
        io = IO::Memory.new
        t[0].dump io
        out = io.to_s

        out.should contain "EMULATOR"
        out.should contain "FEATURES (static"
        out.should contain "FEATURES (live probing)"
        out.should contain "xterm"
        out.should contain "number_of_colors"
        # Probe fields are reported as not-probed until Tput#probe! runs.
        out.should contain "(not probed)"
      end
    end
  end

  describe "probed provenance" do
    it "records the probe source for each live-probed field" do
      tp = x.p
      canned = IO::Memory.new
      canned << "\e]10;rgb:ffff/ffff/ffff\a"  # default fg
      canned << "\e]11;rgb:0000/0000/0000\a"  # default bg
      canned << "\e]4;1;rgb:cd00/0000/0000\a" # palette idx 1
      canned << "\e[1;2R"                     # CPR row 1 col 2 => width 1
      canned << "\e[?62;1;6c"                 # DA1 terminator
      canned.rewind

      res = tp.probe_consume canned, 1.second
      res.got_da.should be_true
      if w = res.ambiguous_width
        tp.features.ambiguous_width = w
        tp.features.sources["ambiguous_width"] = "probed via DSR/CPR cursor-position measurement"
      end

      probed = tp.features.probed_detections
      probed["default_foreground"].value.should eq "#ffffff"
      probed["default_foreground"].source.should eq "probed via OSC 10 reply"
      probed["default_background"].value.should eq "#000000"
      probed["default_background"].source.should eq "probed via OSC 11 reply"
      probed["palette"].source.should eq "probed via OSC 4 replies"
      probed["da_params"].value.should eq "62;1;6"
      probed["da_params"].source.should eq "probed via DA1 (CSI c) reply"
      probed["ambiguous_width"].value.should eq "1"
    end

    it "surfaces every seeded probe-only field, marked (not probed) before probing" do
      # Each of these is seeded with provenance in Features#initialize and must
      # appear in the live-probing section even before Tput#probe! runs.
      probed = Tput::Test.new.p.features.probed_detections
      {"ambiguous_width", "default_foreground", "default_background", "palette",
       "da_params", "da2_params", "terminal_version", "kitty_keyboard",
       "modify_other_keys", "in_band_resize"}.each do |k|
        probed.has_key?(k).should be_true
        probed[k].value.should eq "(not probed)"
        probed[k].source.empty?.should be_false
      end
    end

    it "surfaces in_band_resize once positively probed" do
      tp = Tput::Test.new.p
      tp.features.probed_detections["in_band_resize"].value.should eq "(not probed)"

      canned = IO::Memory.new
      canned << "\e[?2048;1$y" # DECRQM: mode 2048 (in-band resize) supported
      canned << "\e[?62;1;6c"  # DA1 terminator
      canned.rewind
      tp.probe_consume canned, 1.second

      probed = tp.features.probed_detections
      probed["in_band_resize"].value.should eq "true"
      probed["in_band_resize"].source.should eq "probed via DECRQM (CSI ? 2048 $ p)"
    end
  end

  describe "JSON serialization" do
    it "renders detections with a separate value and source field" do
      json = x.t.detections.to_json
      json.should contain %("value":)
      json.should contain %("source":)
    end

    it "serializes the whole Tput object (Size/Point to_json fix)" do
      # Previously raised: 'Tput::Namespace::Size#to_json' expected IO not
      # JSON::Builder. Should now produce valid JSON including nested fields.
      json = x.t.to_pretty_json
      json.should contain %("features":)
      json.should contain %("emulator":)
      json.should contain %("screen":)
      json.should contain %("width": 80)
    end

    it "excludes the internal force_unicode flag (JSON::Field ignore)" do
      x.t.to_json.should_not contain "force_unicode"
    end
  end
end
