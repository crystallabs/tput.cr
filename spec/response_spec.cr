describe Tput::Response do
  x = Tput::Test.new
  t = x.p # parsing needs no terminfo

  describe "#read_cursor_response" do
    it "parses a CPR reply into a 0-based Point" do
      pos = t.read_cursor_response(IO::Memory.new("\e[12;48R"), 1.second)
      pos.should_not be_nil
      pos.not_nil!.y.should eq 11
      pos.not_nil!.x.should eq 47
    end

    it "skips unrelated sequences before the reply" do
      pos = t.read_cursor_response(IO::Memory.new("\e[0n\e[5;9R"), 1.second)
      pos.not_nil!.x.should eq 8
      pos.not_nil!.y.should eq 4
    end

    it "returns nil at EOF with no reply" do
      t.read_cursor_response(IO::Memory.new(""), 1.second).should be_nil
    end
  end

  describe "#read_device_attributes_response" do
    it "parses a DA1 reply, stripping the private marker" do
      t.read_device_attributes_response(IO::Memory.new("\e[?62;1;6c"), 1.second).should eq [62, 1, 6]
    end
  end

  describe "#read_device_status_response" do
    it "parses both status (n) and cursor (R) replies" do
      t.read_device_status_response(IO::Memory.new("\e[0n"), 1.second).should eq [0]
      t.read_device_status_response(IO::Memory.new("\e[7;3R"), 1.second).should eq [7, 3]
    end
  end

  describe "#read_window_size_response" do
    it "parses an XTWINOPS 18 reply into {height, width}" do
      t.read_window_size_response(IO::Memory.new("\e[8;24;80t"), 1.second).should eq({24, 80})
    end

    it "skips a non-size XTWINOPS report (shared 't' final) and matches op 8" do
      # All XTWINOPS replies end in 't'; only the op code distinguishes them. A
      # window-position report (`CSI 3 ; x ; y t`) must not be misread as the
      # character size — it has to be skipped, and the real op-8 reply matched.
      io = IO::Memory.new("\e[3;100;200t\e[8;24;80t")
      t.read_window_size_response(io, 1.second).should eq({24, 80})
    end

    it "treats a lone non-size report as no answer" do
      t.read_window_size_response(IO::Memory.new("\e[3;100;200t"), 1.second).should be_nil
    end
  end

  describe "#read_pixel_size_response" do
    it "parses an XTWINOPS 16 cell-size reply into {height, width} px" do
      t.read_pixel_size_response(IO::Memory.new("\e[6;20;10t"), 1.second).should eq({20, 10})
    end

    it "parses an XTWINOPS 14 text-area reply too (same wire shape)" do
      t.read_pixel_size_response(IO::Memory.new("\e[4;480;800t"), 1.second).should eq({480, 800})
    end

    it "rejects a zero-valued reply (no real pixel grid, e.g. under tmux)" do
      t.read_pixel_size_response(IO::Memory.new("\e[6;0;0t"), 1.second).should be_nil
    end

    it "disambiguates cell size (op 6) from a stale text-area report (op 4)" do
      # `get_cell_size_pixels` sends `CSI 16 t` and must read back only the cell
      # report (op 6, e.g. 20x10). A leftover text-area-pixels report (op 4,
      # e.g. 480x800) sharing the `t` final must be skipped, not returned as the
      # cell size — otherwise the cell aspect ratio is wildly wrong.
      io = IO::Memory.new("\e[4;480;800t\e[6;20;10t")
      t.read_pixel_size_response(io, 1.second, 6).should eq({20, 10})
    end

    it "disambiguates text-area size (op 4) from a stale cell report (op 6)" do
      io = IO::Memory.new("\e[6;20;10t\e[4;480;800t")
      t.read_pixel_size_response(io, 1.second, 4).should eq({480, 800})
    end

    it "returns nil at EOF with no reply" do
      t.read_pixel_size_response(IO::Memory.new(""), 1.second).should be_nil
    end
  end

  describe "#read_request_parameters_response" do
    it "parses a DECREQTPARM reply" do
      t.read_request_parameters_response(IO::Memory.new("\e[2;1;1;112;112;1;0x"), 1.second)
        .should eq [2, 1, 1, 112, 112, 1, 0]
    end
  end

  describe "#read_locator_position_response" do
    it "parses a DECRQLP reply, dropping the & intermediate" do
      t.read_locator_position_response(IO::Memory.new("\e[1;2;34;56&w"), 1.second).should eq [1, 2, 34, 56]
    end
  end

  describe "#read_text_params_response" do
    it "returns the Pt of an OSC reply" do
      t.read_text_params_response(IO::Memory.new("\e]52;c;Zm9v\a"), 1.second, 52).should eq "c;Zm9v"
    end

    it "accepts an ST-terminated reply too" do
      t.read_text_params_response(IO::Memory.new("\e]12;rgb:1111/2222/3333\e\\"), 1.second, 12)
        .should eq "rgb:1111/2222/3333"
    end

    it "preserves multi-byte UTF-8 in the payload (e.g. a window title)" do
      # The shared OSC/DCS reader must not decode each byte as its own codepoint;
      # "é" (2 bytes) and "—" (3 bytes) have to survive intact, not become mojibake.
      t.read_text_params_response(IO::Memory.new("\e]0;café — app\a"), 1.second, 0)
        .should eq "café — app"
    end
  end

  describe "#read_cursor_color_response" do
    it "parses an OSC 12 reply into RGB" do
      rgb = t.read_cursor_color_response(IO::Memory.new("\e]12;rgb:1111/2222/3333\a"), 1.second)
      rgb.should_not be_nil
      rgb.not_nil!.to_s.should eq "#112233"
    end
  end
end
