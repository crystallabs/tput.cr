require "./spec_helper"

private def bugs20_tput(input : String = "", output : IO = IO::Memory.new) : Tput
  Tput.new \
    input: IO::Memory.new(input),
    output: output,
    screen_size: Tput::DEFAULT_SCREEN_SIZE,
    probe: false
end

# Yields a Tput reading the read end of a pipe, and the write end. The escape
# and paste timeouts are set through the config the constructor reads.
private def bugs20_with_pipe_tput(read_timeout : Time::Span? = nil, paste_timeout : Time::Span? = nil, &)
  saved_read = Superconf.tput_read_timeout
  saved_paste = Superconf.tput_paste_timeout
  r, w = IO.pipe
  begin
    Superconf.tput_read_timeout = read_timeout if read_timeout
    Superconf.tput_paste_timeout = paste_timeout if paste_timeout
    t = Tput.new input: r, output: IO::Memory.new, screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
    yield t, w
  ensure
    Superconf.tput_read_timeout = saved_read
    Superconf.tput_paste_timeout = saved_paste
    w.close rescue nil
    r.close rescue nil
  end
end

private def bugs20_feed(data : String) : Array(Tput::InputEvent)
  events = [] of Tput::InputEvent
  bugs20_tput(data).listen do |e|
    events << e
  end
  events
end

describe Tput::Input do
  describe "numeric parameter accumulation" do
    it "saturates at Int32::MAX for every value past it" do
      Tput::Key.acc_digit(12, 3).should eq 123
      Tput::Key.acc_digit(214748364, 7).should eq Int32::MAX
      Tput::Key.acc_digit(214748364, 8).should eq Int32::MAX
      Tput::Key.acc_digit(214748365, 0).should eq Int32::MAX
      Tput::Key.acc_digit(Int32::MAX, 9).should eq Int32::MAX
    end

    it "consumes a CSI parameter just past Int32::MAX without raising" do
      bugs20_feed("\e[2500000000~").empty?.should be_true
    end

    it "parses an SGR mouse report whose coordinate is just past Int32::MAX" do
      ev = bugs20_feed("\e[<0;2500000000;5M")
      ev.size.should eq 1
      m = ev[0].mouse.not_nil!
      m.x.should eq Int32::MAX - 1
      m.y.should eq 4
    end
  end

  describe "an Escape key typed just ahead of a terminal report" do
    it "delivers the Escape and then the SGR mouse report" do
      ev = bugs20_feed("\e\e[<0;10;5M")
      ev.size.should eq 2
      ev[0].key.should eq Tput::Key::Escape
      ev[0].mouse?.should be_false
      m = ev[1].mouse.not_nil!
      m.action.should eq Tput::Mouse::Action::Down
      m.x.should eq 9
      m.y.should eq 4
    end

    it "delivers the Escape and then the X10 mouse report" do
      ev = bugs20_feed("\e\e[M !!")
      ev.size.should eq 2
      ev[0].key.should eq Tput::Key::Escape
      m = ev[1].mouse.not_nil!
      m.button.should eq Tput::Mouse::Button::Left
      m.x.should eq 0
      m.y.should eq 0
    end

    it "delivers the Escape and then the URxvt mouse report" do
      ev = bugs20_feed("\e\e[32;10;5M")
      ev.size.should eq 2
      ev[0].key.should eq Tput::Key::Escape
      m = ev[1].mouse.not_nil!
      m.x.should eq 9
      m.y.should eq 4
    end

    it "delivers the Escape and then the paste" do
      ev = bugs20_feed("\e\e[200~hi\e[201~")
      ev.size.should eq 2
      ev[0].key.should eq Tput::Key::Escape
      ev[1].paste.should eq "hi"
    end

    it "still reads an Alt-prefixed cursor key as one key" do
      ev = bugs20_feed("\e\e[A")
      ev.size.should eq 1
      ev[0].key.should eq Tput::Key::Up
    end
  end

  describe "a long input sequence" do
    it "carries the whole sequence and leaves the parser ready for the next key" do
      body = "a" * 1000
      ev = bugs20_feed("\e[200~#{body}\e[201~x")
      ev.size.should eq 2
      ev[0].paste.should eq body
      ev[0].sequence.size.should eq 1012
      ev[1].char.should eq 'x'
      ev[1].sequence.should eq ['x']
    end
  end

  describe "a mouse, resize or color-scheme report" do
    it "carries no raw sequence" do
      ev = bugs20_feed("\e[<0;10;5M\e[48;24;80;0;0t\e[?997;1n\e[A")
      ev.size.should eq 4
      ev[0].mouse?.should be_true
      ev[0].sequence?.should be_nil
      ev[1].resize?.should be_true
      ev[1].sequence?.should be_nil
      ev[2].color_scheme?.should be_true
      ev[2].sequence?.should be_nil
      ev[3].key.should eq Tput::Key::Up
      ev[3].sequence.should eq ['\e', '[', 'A']
    end
  end

  describe "an ESC-prefixed key" do
    it "is the key with Alt held" do
      ev = bugs20_feed("\e1")
      ev.size.should eq 1
      ke = ev[0].key_event.not_nil!
      ke.codepoint.should eq '1'.ord
      ke.mods.should eq Tput::Modifiers::Alt
      ev[0].key.should be_nil
      ev[0].sequence.should eq ['\e', '1']
    end

    it "reads an uppercase letter as Alt+Shift+letter" do
      ev = bugs20_feed("\eA")
      ev.size.should eq 1
      ke = ev[0].key_event.not_nil!
      ke.codepoint.should eq 'a'.ord
      ke.mods.should eq Tput::Modifiers::Alt | Tput::Modifiers::Shift
      ke.shifted.should eq 'A'.ord
      ev[0].key.should eq Tput::Key::AltA
    end

    it "reads DEL as Alt+Backspace" do
      ev = bugs20_feed("\e\u007f")
      ev.size.should eq 1
      ev[0].key.should eq Tput::Key::Backspace
      ev[0].key_event.not_nil!.alt?.should be_true
    end

    it "reads a control character as Ctrl+Alt+letter" do
      ev = bugs20_feed("\e\u0003")
      ev.size.should eq 1
      ev[0].key.should eq Tput::Key::CtrlC
      ev[0].key_event.not_nil!.mods.should eq Tput::Modifiers::Alt | Tput::Modifiers::Ctrl
    end

    it "keeps Alt+letter and Alt+Enter as their own keys" do
      ev = bugs20_feed("\eq\e\r")
      ev.map(&.key).should eq [Tput::Key::AltQ, Tput::Key::AltEnter]
      ev[0].key_event.should be_nil
    end

    it "is still one key after an extra ESC" do
      ev = bugs20_feed("\e\e1")
      ev.size.should eq 1
      ev[0].key_event.not_nil!.codepoint.should eq '1'.ord
    end

    it "reads a sequence introducer with nothing after it as the Alt key" do
      {"\e[" => '[', "\e]" => ']', "\e^" => '^', "\e_" => '_'}.each do |data, c|
        ev = bugs20_feed(data)
        ev.size.should eq 1
        ke = ev[0].key_event.not_nil!
        ke.codepoint.should eq c.ord
        ke.mods.should eq Tput::Modifiers::Alt
      end
      {"\eO" => Tput::Key::AltO, "\eP" => Tput::Key::AltP, "\eX" => Tput::Key::AltX}.each do |data, key|
        ev = bugs20_feed(data)
        ev.size.should eq 1
        ev[0].key.should eq key
        ev[0].key_event.not_nil!.shift?.should be_true
      end
    end

    it "does not read real sequences as Alt keys" do
      ev = bugs20_feed("\e[A\eOP\e]0;t\a\ePq\e\\\e_Gi=1;OK\e\\\e^pm\e\\\eXsos\e\\\e\\z")
      ev.map(&.key).should eq [Tput::Key::Up, Tput::Key::F1, nil]
      ev.all?(&.key_event.nil?).should be_true
      ev[2].char.should eq 'z'
    end
  end

  describe "a DCS, APC, PM or SOS string" do
    it "is consumed through its terminator" do
      ev = bugs20_feed("a\eP>|xterm(388)\e\\b\e_Gi=31;OK\e\\c\e^x\e\\d\eXy\e\\e")
      ev.map(&.char).join.should eq "abcde"
      ev.all?(&.key.nil?).should be_true
    end

    it "is ended by CAN or SUB" do
      ev = bugs20_feed("\ePabc\u0018x\e_abc\u001ay")
      ev.map(&.char).join.should eq "xy"
    end

    it "keeps an ESC inside the string as part of it" do
      ev = bugs20_feed("\ePa\eb\e\\x")
      ev.map(&.char).join.should eq "x"
    end
  end

  describe "an SS3 sequence with parameters" do
    it "reads the modified F1-F4" do
      bugs20_feed("\eO1;5P").map(&.key).should eq [Tput::Key::F1]
      bugs20_feed("\eO5Q").map(&.key).should eq [Tput::Key::F2]
      bugs20_feed("\eO2R\eO1;2Sx").map(&.key).should eq [Tput::Key::F3, Tput::Key::F4, nil]
    end

    it "applies the modifier to a cursor key" do
      bugs20_feed("\eO5A").map(&.key).should eq [Tput::Key::CtrlUp]
      bugs20_feed("\eO1;2D").map(&.key).should eq [Tput::Key::ShiftLeft]
      bugs20_feed("\eO3H").map(&.key).should eq [Tput::Key::AltHome]
    end

    it "leaks nothing of an unknown one" do
      ev = bugs20_feed("\eO1;5zx")
      ev.map(&.char).should eq ['x']
    end
  end

  describe "a bracketed paste that stalls" do
    it "goes on past the escape timeout, to the end marker" do
      bugs20_with_pipe_tput(read_timeout: 20.milliseconds) do |t, w|
        events = [] of Tput::InputEvent
        done = Channel(Nil).new
        spawn do
          t.listen { |e| events << e }
          done.send nil
        end
        w.print "\e[200~abc"
        w.flush
        sleep 80.milliseconds
        events.should be_empty
        w.print "def\e[201~x"
        w.flush
        w.close
        done.receive
        events.size.should eq 2
        events[0].paste.should eq "abcdef"
        events[1].char.should eq 'x'
      end
    end

    it "ends without a marker once the stream is idle for the paste timeout" do
      bugs20_with_pipe_tput(read_timeout: 20.milliseconds, paste_timeout: 60.milliseconds) do |t, w|
        events = Channel(Tput::InputEvent).new(8)
        spawn { t.listen { |e| events.send e } }
        w.print "\e[200~abc"
        w.flush
        events.receive.paste.should eq "abc"
        w.print "x"
        w.flush
        events.receive.char.should eq 'x'
        w.close
      end
    end
  end

  describe "#stop_listen" do
    it "ends a listen that is waiting for input, and loses none" do
      bugs20_with_pipe_tput do |t, w|
        seen = [] of Char
        done = Channel(Nil).new
        spawn do
          t.listen { |e| seen << e.char }
          done.send nil
        end
        w.print "a"
        w.flush
        until seen.size == 1
          Fiber.yield
        end

        t.listening?.should be_true
        t.stop_listen
        done.receive
        t.listening?.should be_false

        # Arrives while nobody listens: the next listen gets it, first.
        w.print "b"
        w.flush
        spawn do
          t.listen { |e| seen << e.char }
          done.send nil
        end
        w.print "c"
        w.flush
        w.close
        done.receive
        seen.should eq ['a', 'b', 'c']
      end
    end

    it "hands input read ahead of a stop to the next listen, of another Tput too" do
      r, w = IO.pipe
      begin
        a = Tput.new input: r, output: IO::Memory.new, screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
        b = Tput.new input: r, output: IO::Memory.new, screen_size: Tput::DEFAULT_SCREEN_SIZE, probe: false
        seen = [] of Char
        w.print "xyz\e[A"
        w.close
        a.listen do |e|
          seen << e.char
          a.stop_listen
        end
        seen.should eq ['x']
        keys = [] of Tput::Key?
        b.listen do |e|
          seen << e.char
          keys << e.key
        end
        seen.should eq ['x', 'y', 'z', '\e']
        keys.last.should eq Tput::Key::Up
      ensure
        w.close rescue nil
        r.close rescue nil
      end
    end

    it "gives back the part of a sequence read when the stop came" do
      bugs20_with_pipe_tput(read_timeout: 2.seconds) do |t, w|
        keys = [] of Tput::Key?
        done = Channel(Nil).new
        spawn do
          t.listen { |e| keys << e.key }
          done.send nil
        end
        w.print "\e["
        w.flush
        sleep 20.milliseconds
        t.stop_listen
        done.receive
        keys.should be_empty

        w.print "A"
        w.close
        t.listen { |e| keys << e.key }
        keys.should eq [Tput::Key::Up]
      end
    end

    it "leaves the input open and readable for a query" do
      bugs20_with_pipe_tput do |t, w|
        done = Channel(Nil).new
        spawn do
          t.listen { }
          done.send nil
        end
        Fiber.yield
        t.stop_listen
        done.receive
        t.input.closed?.should be_false
        w.print "q"
        w.flush
        t.input.read_char.should eq 'q'
      end
    end

    it "stops a listen on an in-memory input from its handler, keeping the rest" do
      t = bugs20_tput("abc")
      seen = [] of Char
      t.listen do |e|
        seen << e.char
        t.stop_listen
      end
      seen.should eq ['a']
      t.listen { |e| seen << e.char }
      seen.should eq ['a', 'b', 'c']
    end

    it "reads what a query left in the input's own buffer" do
      bugs20_with_pipe_tput do |t, w|
        w.print "\e[5;9Rkl"
        w.close
        # A reply read byte by byte leaves the keys typed after it buffered
        # in the input itself.
        input = t.input
        6.times { input.read_byte }
        seen = [] of Char
        t.listen { |e| seen << e.char }
        seen.should eq ['k', 'l']
      end
    end
  end
end

describe Tput::Output do
  it "flushes the bytes ahead of a padding delay before waiting" do
    output = IO::Memory.new
    t = bugs20_tput output: output
    t.use_buffer?.should be_true
    t._pad_write "ab$<1/>cd".to_slice
    output.to_s.should eq "ab"
    t.flush
    output.to_s.should eq "abcd"
  end

  it "neither flushes nor waits while output is diverted" do
    output = IO::Memory.new
    ret = IO::Memory.new
    t = bugs20_tput output: output
    t._write "x".to_slice
    t.ret = ret
    started = Time.instant
    t._pad_write "ab$<300/>cd".to_slice
    (Time.instant - started).should be < 200.milliseconds
    t.ret = nil
    ret.to_s.should eq "abcd"
    output.to_s.should eq ""
  end
end

describe Tput::Keyboard do
  it "pops the kitty keyboard stack before enabling the protocol again" do
    buf = IO::Memory.new
    t = bugs20_tput(output: buf)
    t.features.kitty_keyboard_flags = 0

    t.enable_keyboard_protocol(events: false).should eq Tput::KeyboardProtocol::Kitty
    t.enable_keyboard_protocol(events: true).should eq Tput::KeyboardProtocol::Kitty
    t.flush
    buf.to_s.should eq "\e[>1u\e[<u\e[>31u"

    t.disable_keyboard_protocol
    t.flush
    buf.to_s.should eq "\e[>1u\e[<u\e[>31u\e[<u"
    t.keyboard_protocol.nil?.should be_true
  end
end

describe Tput::Probe do
  it "reads a reply that follows a stray ESC" do
    t = bugs20_tput
    pos = t.read_cursor_response(IO::Memory.new("\e\e[5;9R"), 1.second).not_nil!
    pos.x.should eq 8
    pos.y.should eq 4

    t.probe_consume(IO::Memory.new("\e\e[?62;1;6c"), 1.second).got_da.should be_true
    t.probe_vs16_consume(IO::Memory.new("\e\e[1;3R"), 1.second).should eq 2
  end

  it "ignores a color reply with a signed component" do
    t = bugs20_tput
    res = t.probe_consume IO::Memory.new("\e]11;rgb:-f/00/00\a\e[?62;1;6c"), 1.second
    res.got_da.should be_true
    t.features.default_background.nil?.should be_true
  end
end

describe Tput::Output::Text do
  it "treats a color number too large for an Int32 as an unknown attribute" do
    bugs20_tput._attr("99999999999 fg").should eq ""
    bugs20_tput._attr("99999999999 bg", false).should eq ""
  end
end

describe Tput::Output::Text do
  it "emits nothing for a list of attributes that all come to nothing" do
    t = bugs20_tput
    t._attr("foo, bar").should eq ""
    t._attr("foo").should eq ""
    t._attr("default fg, default bg", false).should eq ""
    t._attr(["foo", "bar"]).should eq ""
  end

  it "still emits the reset for a list of normal/default" do
    t = bugs20_tput
    t._attr("normal, default").should eq "\e[m"
    t._attr("normal, foo").should eq "\e[m"
    t._attr("foo, red fg").should eq "\e[31m"
  end
end

describe Tput::Features do
  it "ignores a TERM color-count suffix too large for an Int32" do
    with_env({"TERM" => "xterm-99999999999color", "COLORTERM" => nil}) do
      plain_tput.features.number_of_colors.should eq 2
    end
  end
end

describe Tput::Emulator do
  it "compares a version carrying a digit run too long for an Int32" do
    env = {
      "KITTY_WINDOW_ID"      => nil,
      "TERM_PROGRAM"         => "ghostty",
      "TERM_PROGRAM_VERSION" => "1.2.0+12345678901234",
    } of String => String?
    with_env(env) do
      plain_tput.emulator.legacy_computing_octant?.should be_true
    end
  end
end

describe Tput::Unicode do
  u = Tput::Unicode

  it "counts bidi and invisible format characters as zero columns" do
    {'\u{200E}', '\u{200F}', '\u{202A}', '\u{202E}', '\u{2060}', '\u{2066}', '\u{2069}', '\u{061C}'}.each do |c|
      u.codepoint_width(c).should eq(0), c.ord.to_s(16)
    end
    u.display_width("a\u{200E}b").should eq 2
  end

  it "keeps a subdivision flag's tag characters in the flag's cluster" do
    content = "\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}".chars
    u.grapheme_extender?(content[1]).should be_true
    u.needs_cluster?(content[0], content[1]).should be_true
    cluster, ci = u.extend_grapheme content, 1, content[0]
    ci.should eq content.size
    cluster.should eq content.join
    u.width(cluster).should eq 2
    u.codepoint_width(content[1]).should eq 0
  end
end
