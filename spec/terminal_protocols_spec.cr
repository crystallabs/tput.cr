require "./spec_helper"

# Bracketed paste (2004), in-band resize (2048), and the XTVERSION / DA2 / OSC 52
# / DECRQM query+reply parsers.

private def feed_all(data : String)
  events = [] of {Char, Tput::Key?, String?, Tput::Resize?}
  t = Tput.new \
    input: IO::Memory.new(data),
    output: IO::Memory.new,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false
  t.listen do |e|
    events << {e.char, e.key, e.paste, e.resize}
  end
  events
end

private def new_tput(output = IO::Memory.new)
  Tput.new input: IO::Memory.new(""), output: output,
    screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
end

describe "bracketed paste (DEC 2004)" do
  it "delivers the paste body as a single string" do
    ev = feed_all("\e[200~hello world\e[201~")
    ev.size.should eq 1
    ev[0][2].should eq "hello world"
  end

  it "treats embedded escape sequences as literal text, not keys" do
    ev = feed_all("\e[200~a\e[Bb\e[201~")
    ev.size.should eq 1
    ev[0][2].should eq "a\e[Bb" # the \e[B (Down) is part of the paste, not a key
    ev[0][1].should be_nil
  end

  it "enables/disables via DEC mode 2004" do
    buf = IO::Memory.new
    t = new_tput buf
    t.enable_bracketed_paste
    t.bracketed_paste_enabled?.should be_true
    t.disable_bracketed_paste
    t.flush
    buf.to_s.should contain "\e[?2004h"
    buf.to_s.should contain "\e[?2004l"
  end
end

describe "in-band resize (DEC 2048)" do
  it "parses a resize report into cells and pixels" do
    ev = feed_all("\e[48;24;80;600;800t")
    ev.size.should eq 1
    r = ev[0][3].not_nil!
    r.rows.should eq 24
    r.cols.should eq 80
    r.pixel_height.should eq 600
    r.pixel_width.should eq 800
  end

  it "does not disturb other CSI 't' or legacy parsing" do
    feed_all("\e[A")[0][1].should eq Tput::Key::Up
  end
end

describe "color scheme (DEC 2031) + OSC 52 clipboard via listen" do
  it "parses a color-scheme report into ColorScheme" do
    feed_all("\e[?997;1n")[0][1].should be_nil # not a key
    schemes = [] of Tput::ColorScheme?
    t = Tput.new input: IO::Memory.new("\e[?997;1n\e[?997;2n"), output: IO::Memory.new,
      screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
    t.listen { |e| schemes << e.color_scheme }
    schemes.should eq [Tput::ColorScheme::Dark, Tput::ColorScheme::Light]
  end

  it "surfaces an OSC 52 clipboard reply as a paste" do
    data = "\e]52;c;#{Base64.strict_encode "hello"}\a"
    ev = feed_all(data)
    ev.size.should eq 1
    ev[0][2].should eq "hello" # delivered through the paste channel
  end

  it "ignores a non-clipboard OSC reply (no phantom key)" do
    feed_all("\e]11;rgb:1234/5678/9abc\a").size.should eq 0
  end

  it "ignores a stray paste-end marker (no phantom key)" do
    feed_all("\e[201~").size.should eq 0
  end

  it "ignores a stray private CSI reply mid-listen (no phantom Escape)" do
    feed_all("\e[?62;1;6c").size.should eq 0 # a DA1-style reply, not a key
  end

  it "still delivers a real bare Escape" do
    ev = feed_all("\e")
    ev.size.should eq 1
    ev[0][1].should eq Tput::Key::Escape
  end

  it "request_color_scheme parses the CSI ? 997 reply" do
    t = new_tput
    t.read_color_scheme_response(IO::Memory.new("\e[?997;2n"), 1.second).should eq Tput::ColorScheme::Light
  end

  it "enable methods emit the right DEC modes" do
    buf = IO::Memory.new
    t = new_tput buf
    t.enable_grapheme_clustering
    t.enable_color_scheme_notifications
    t.request_clipboard
    t.flush
    s = buf.to_s
    s.should contain "\e[?2027h"
    s.should contain "\e[?2031h"
    s.should contain "\e]52;c;?"
  end
end

describe "Emulator probe hardening (XTVERSION)" do
  it "overrides env-misdetected identity from XTVERSION" do
    t = new_tput
    t.emulator.iterm2 = true # pretend env propagated the wrong terminal
    t.features.terminal_version = "kitty(0.32.0)"
    t.emulator.refine_from_probe!
    t.emulator.kitty?.should be_true
    t.emulator.iterm2?.should be_false
  end

  it "leaves identity untouched for an unknown XTVERSION" do
    t = new_tput
    t.emulator.iterm2 = true
    t.features.terminal_version = "Mystery 1.0"
    t.emulator.refine_from_probe!
    t.emulator.iterm2?.should be_true
  end
end

describe "Emulator screen detection" do
  it "detects GNU screen from a suffixed TERM (e.g. screen-256color)" do
    with_env({"TERM" => "screen-256color", "TMUX" => nil}) do
      plain_tput.emulator.screen?.should be_true
    end
  end

  it "still detects a bare TERM=screen" do
    with_env({"TERM" => "screen", "TMUX" => nil}) do
      plain_tput.emulator.screen?.should be_true
    end
  end

  it "does not flag a non-screen TERM" do
    with_env({"TERM" => "xterm-256color", "TMUX" => nil}) do
      plain_tput.emulator.screen?.should be_false
    end
  end
end

describe "Tput::Probe XTVERSION / DA2" do
  it "detects DA2 (CSI > c) without mistaking it for the DA1 terminator" do
    t = new_tput
    t.probe_consume(IO::Memory.new("\e[>0;276;0c\e[c"), 1.second)
    t.features.da2_params.should eq [0, 276, 0]
    t.features.da_params.should_not be_nil # DA1 still seen as the terminator
  end

  it "detects the terminal version via XTVERSION (DCS > |)" do
    t = new_tput
    t.probe_consume(IO::Memory.new("\eP>|kitty(0.32.0)\e\\\e[c"), 1.second)
    t.features.terminal_version.should eq "kitty(0.32.0)"
  end

  it "detects in-band resize support via DECRQM 2048" do
    t = new_tput
    t.probe_consume(IO::Memory.new("\e[?2048;1$y\e[c"), 1.second)
    t.features.in_band_resize?.should be_true
  end

  it "treats DECRQM 2048 Ps=0 as unsupported" do
    t = new_tput
    t.probe_consume(IO::Memory.new("\e[?2048;0$y\e[c"), 1.second)
    t.features.in_band_resize?.should be_false
  end

  it "applies every color in a combined OSC 4 palette reply" do
    # xterm answers a batched `OSC 4 ; 0 ; ? ; 1 ; ? ; …` query with a single
    # reply "of the same form", carrying all the index;color pairs at once.
    t = new_tput
    t.probe_consume(
      IO::Memory.new("\e]4;0;rgb:0000/0000/0000;1;rgb:ffff/0000/0000;15;rgb:ffff/ffff/ffff\a\e[c"),
      1.second)
    t.features.palette[0].not_nil!.to_s.should eq "#000000"
    t.features.palette[1].not_nil!.to_s.should eq "#ff0000"
    t.features.palette[15].not_nil!.to_s.should eq "#ffffff"
  end
end

describe "Tput::Response parsers" do
  it "parses an OSC 52 clipboard reply (base64)" do
    t = new_tput
    io = IO::Memory.new("\e]52;c;#{Base64.strict_encode "hello"}\a")
    t.read_clipboard_response(io, 1.second).should eq "hello"
  end

  it "parses an XTVERSION DCS reply" do
    t = new_tput
    io = IO::Memory.new("\eP>|WezTerm 20240203\e\\")
    t.read_xtversion_response(io, 1.second).should eq "WezTerm 20240203"
  end

  it "parses an XTVERSION DCS reply terminated by BEL instead of ST" do
    # Exercises the shared OSC/DCS string reader's BEL-termination path.
    t = new_tput
    io = IO::Memory.new("\eP>|kitty(0.32.0)\a")
    t.read_xtversion_response(io, 1.second).should eq "kitty(0.32.0)"
  end

  it "parses DECRQM replies (supported vs not)" do
    t = new_tput
    t.read_decrqm_response(IO::Memory.new("\e[?2026;1$y"), 1.second, 2026).should be_true
    t.read_decrqm_response(IO::Memory.new("\e[?2026;0$y"), 1.second, 2026).should be_false
  end

  it "parses an XTGETTCAP reply (hex name=value pairs)" do
    t = new_tput
    # TN=xterm-kitty, Co=256 — hex-encoded as the protocol requires.
    tn = "TN".to_slice.hexstring
    name = "xterm-kitty".to_slice.hexstring
    co = "Co".to_slice.hexstring
    val = "256".to_slice.hexstring
    io = IO::Memory.new("\eP1+r#{tn}=#{name};#{co}=#{val}\e\\")
    result = t.read_xtgettcap_response(io, 1.second)
    result.should eq({"TN" => "xterm-kitty", "Co" => "256"})
  end

  it "merges XTGETTCAP replies sent one-per-capability (xterm style)" do
    t = new_tput
    # xterm answers a multi-name query with a *separate* DCS reply per
    # capability, unlike kitty/foot which batch them into one. All requested
    # caps must be collected, not just the first.
    tn = "TN".to_slice.hexstring
    name = "xterm".to_slice.hexstring
    co = "Co".to_slice.hexstring
    val = "256".to_slice.hexstring
    io = IO::Memory.new("\eP1+r#{tn}=#{name}\e\\\eP1+r#{co}=#{val}\e\\")
    t.read_xtgettcap_response(io, 1.second, 2).should eq({"TN" => "xterm", "Co" => "256"})
  end

  it "treats an XTGETTCAP failure reply (0+r) as empty" do
    t = new_tput
    io = IO::Memory.new("\eP0+r#{"TN".to_slice.hexstring}\e\\")
    t.read_xtgettcap_response(io, 1.second).should eq({} of String => String)
  end
end

describe "OSC 52 + synchronized output writers" do
  it "set_clipboard emits OSC 52 with base64" do
    buf = IO::Memory.new
    t = new_tput buf
    t.set_clipboard "hello"
    t.flush
    buf.to_s.should contain "\e]52;c;#{Base64.strict_encode "hello"}\a"
  end

  it "emits an OSC 8 hyperlink (begin + text + end)" do
    buf = IO::Memory.new
    t = new_tput buf
    t.hyperlink "click", "http://example.com"
    t.flush
    buf.to_s.should eq "\e]8;;http://example.com\e\\click\e]8;;\e\\"
  end

  it "emits an OSC 8 hyperlink with an id" do
    buf = IO::Memory.new
    t = new_tput buf
    t.begin_hyperlink "http://x", id: "g1"
    t.flush
    buf.to_s.should eq "\e]8;id=g1;http://x\e\\"
  end

  it "synchronized_update brackets the block in DEC 2026 and always ends it" do
    buf = IO::Memory.new
    t = new_tput buf
    expect_raises(Exception, "boom") do
      t.synchronized_update { t.flush; raise "boom" }
    end
    t.flush
    s = buf.to_s
    s.should contain "\e[?2026h"
    s.should contain "\e[?2026l" # emitted even though the block raised
  end
end
