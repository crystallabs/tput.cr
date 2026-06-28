describe Tput::Output::Cursor do
  x = Tput::Test.new

  describe "cursor_pos" do
    [{x.t, "terminfo"}, {x.p, "plain"}].each do |t|
      it "works with #{t[1]}" do
        t[0].cursor_pos(0, 0).should be_true
        x.o.should eq "\e[1;1H"
        t[0].cursor.x.should eq 0
        t[0].cursor.y.should eq 0

        t[0].cup(19, 21).should be_true
        x.o.should eq "\e[20;22H"
        t[0].cursor.x.should eq 21
        t[0].cursor.y.should eq 19

        t[0].pos(100_000, 100_000).should be_true
        x.o.should eq "\e[24;80H"
        t[0].cursor.x.should eq 79
        t[0].cursor.y.should eq 23

        t[0].cursor_position(-10, -6).should be_true
        x.o.should eq "\e[15;75H"
        t[0].cursor.x.should eq 74
        t[0].cursor.y.should eq 14
      end
    end
  end

  describe "hide & show cursor" do
    it "works with terminfo" do
      x.t.hide_cursor.should be_true
      x.o.should eq "\e[?25l"
      x.t.dectcemh.should be_true
      x.o.should eq "\e[?25l"
      x.t.cursor_invisible.should be_true
      x.o.should eq "\e[?25l"
      x.t.vi.should be_true
      x.o.should eq "\e[?25l"
      x.t.civis.should be_true
      x.o.should eq "\e[?25l"
      x.t.cursor_hidden?.should be_true

      x.t.show_cursor.should be_true
      x.o.should eq "\e[?12l\e[?25h"
      x.t.dectcem.should be_true
      x.o.should eq "\e[?12l\e[?25h"
      x.t.cnorm.should be_true
      x.o.should eq "\e[?12l\e[?25h"
      x.t.cvvis.should be_true
      x.o.should eq "\e[?12l\e[?25h"
      x.t.cursor_visible.should be_true
      x.o.should eq "\e[?12l\e[?25h"
      x.t.cursor_hidden?.should be_false
    end
    it "works with plain" do
      x.p.hide_cursor.should be_true
      x.o.should eq "\e[?25l"
      x.p.cursor_hidden?.should be_true

      x.p.show_cursor.should be_true
      x.o.should eq "\e[?25h"
      x.p.cursor_hidden?.should be_false
    end
  end

  # ----

  describe "cursor_next_line" do
    it "works with terminfo" do
      x.t.sety 0; x.o
      x.t.cursor_next_line
      x.o.should eq "\e[1E"
    end

    it "works plain" do
      x.p.sety 0; x.o
      x.p.cursor_next_line 3
      x.o.should eq "\e[3E"
    end

    it "resets the tracked column to 0 (CNL/CPL move to first column)" do
      x.t.cup 5, 10; x.o
      x.t.cursor.x.should eq 10

      x.t.cursor_next_line 2
      x.t.cursor.x.should eq 0
      x.t.cursor.y.should eq 7

      x.t.cuf 4; x.o
      x.t.cursor.x.should eq 4

      x.t.cursor_preceding_line
      x.t.cursor.x.should eq 0
      x.t.cursor.y.should eq 6
    end
  end

  describe "absolute positioners default to the origin" do
    # vpa/hpa use the same 0-based param convention as cha (the sequence emits
    # param + 1), so a no-arg call must land on index 0 (the first row/column),
    # not index 1.
    it "cursor_line_absolute (vpa) defaults to row 0" do
      x.t.cup 5, 7; x.o
      x.t.cursor_line_absolute
      x.t.cursor.y.should eq 0
      x.t.cursor.x.should eq 7
      x.o.should eq "\e[1d"
    end

    it "char_pos_absolute (hpa) defaults to column 0" do
      x.p.cup 5, 7; x.o
      x.p.char_pos_absolute
      x.p.cursor.x.should eq 0
      x.p.cursor.y.should eq 5
      x.o.should eq "\e[1`"
    end
  end

  describe "absolute positioners emit the clamped coordinate" do
    # `_ncoords` pulls an out-of-range column/row back onto the screen, so the
    # emitted CSI must carry the *clamped* `@cursor` value — emitting the raw
    # `param` would desync the wire output from `@cursor` (and produce a bogus
    # column/row for large values), just as it would for CUP/HVP.
    it "cursor_char_absolute (cha/setx) clamps the emitted column" do
      x.t.cup 0, 0; x.o
      x.t.cursor_char_absolute 100_000
      x.t.cursor.x.should eq 79
      x.o.should eq "\e[80G"
    end

    it "cursor_line_absolute (vpa/sety) clamps the emitted row" do
      x.t.cup 0, 0; x.o
      x.t.cursor_line_absolute 100_000
      x.t.cursor.y.should eq 23
      x.o.should eq "\e[24d"
    end

    it "char_pos_absolute (hpa) clamps the emitted column (plain)" do
      x.p.cup 0, 0; x.o
      x.p.char_pos_absolute 100_000
      x.p.cursor.x.should eq 79
      x.o.should eq "\e[80`"
    end
  end

  describe "relative position helpers track the cursor" do
    # h_position_relative (hpr) must update @cursor.x just as
    # v_position_relative (vpr) updates @cursor.y; otherwise later relative
    # moves desync. The emitted bytes are the CUF/CUD forms on an ANSI terminal.
    it "h_position_relative updates @cursor.x" do
      x.t.cup 4, 6; x.o
      x.t.h_position_relative 3
      x.t.cursor.x.should eq 9
      x.t.cursor.y.should eq 4
      x.o.should eq "\e[3C"
    end

    it "v_position_relative updates @cursor.y" do
      x.t.cup 4, 6; x.o
      x.t.v_position_relative 2
      x.t.cursor.y.should eq 6
      x.t.cursor.x.should eq 6
      x.o.should eq "\e[2B"
    end
  end

  describe "cursor_forward_tab / cursor_backward_tab" do
    # The terminfo `tab`/`cbt` caps are single, non-parametric tabs; for
    # param > 1 the parametric CHT/CBT sequence must be emitted (not a single
    # tab) so the wire output matches the param * 8 cursor advance.
    it "emits the parametric CHT for param > 1 (terminfo)" do
      x.t.cup 0, 0; x.o
      x.t.cursor_forward_tab 3
      x.o.should eq "\e[3I"
      x.t.cursor.x.should eq 24
    end

    it "emits the parametric CBT for param > 1 (terminfo)" do
      x.t.cup 0, 40; x.o
      x.t.cursor_backward_tab 2
      x.o.should eq "\e[2Z"
      x.t.cursor.x.should eq 24
    end
  end

  describe "single-step cursor fallback (cuu1/cud1/cuf1/cub1)" do
    # vt52 has the single-step caps (ESC A/B/C/D) but no parametric cursor caps
    # and is non-ANSI, so cursor_up takes the "repeat cuu1 param times" branch.
    # That branch must terminate the expression (emit once), not fall through
    # and ALSO print the CSI fallback — which would double the output.
    it "emits only the repeated cuu1, not an extra CSI fallback" do
      buf = IO::Memory.new
      vt = Tput.new(
        terminfo: Unibilium.from_terminal("vt52"),
        input: IO::Memory.new,
        output: buf,
        screen_size: Tput::DEFAULT_SCREEN_SIZE)
      vt.cup 10, 0
      vt.flush
      buf.clear
      vt.cursor_up 3
      vt.flush
      String.new(buf.to_slice).should eq "\eA\eA\eA"
    end
  end

  describe "hv_position (HVP)" do
    # HVP is the twin of CUP (#cursor_position), so it must adjust its
    # coordinates the same way: clamp/​wrap through _adjust_xy_abs and emit the
    # *resulting* cursor. Previously it emitted the raw, unadjusted args while
    # storing the clamped position — desyncing the wire output from @cursor, and
    # turning edge-relative (negative) coordinates into a malformed CSI.
    it "tracks the cursor and emits the adjusted position (terminfo)" do
      x.t.cup 0, 0; x.o
      x.t.hv_position(5, 7).should be_true
      x.o.should eq "\e[6;8H"
      x.t.cursor.y.should eq 5
      x.t.cursor.x.should eq 7
    end

    it "wraps negative coordinates from the bottom/right edge, like cursor_position" do
      x.t.cup 0, 0; x.o
      # -1,-1 -> bottom-right cell (row 23, col 79 on the 24x80 default screen),
      # emitted as a valid CSI — not "\e[0;0H" / a negative parameter.
      x.t.hv_position(-1, -1).should be_true
      x.o.should eq "\e[24;80H"
      x.t.cursor.y.should eq 23
      x.t.cursor.x.should eq 79
    end

    it "clamps out-of-range coordinates so @cursor matches the wire output" do
      x.t.cup 0, 0; x.o
      x.t.hv_position(100_000, 100_000).should be_true
      x.o.should eq "\e[24;80H"
      x.t.cursor.y.should eq 23
      x.t.cursor.x.should eq 79
    end
  end

  describe "cursor_shape" do
    it "uses a 0/1 boolean for iTerm2 BlinkingCursorEnabled (not DECSCUSR 1/2)" do
      x.t.features.cursor_style = true
      x.t.emulator.iterm2 = true

      x.t.cursor_shape(Tput::CursorShape::Block, blink: false).should be_true
      x.o.should eq "\e]50;CursorShape=0;BlinkingCursorEnabled=0\a"

      x.t.cursor_shape(Tput::CursorShape::Block, blink: true).should be_true
      x.o.should eq "\e]50;CursorShape=0;BlinkingCursorEnabled=1\a"

      # DECSCUSR path still uses the 1 (blink) / 2 (steady) encoding.
      x.t.emulator.iterm2 = false
      x.t.cursor_shape(Tput::CursorShape::Block, blink: false).should be_true
      x.o.should eq "\e[2 q"
    end
  end

  describe "reset_cursor_color" do
    it "works with terminfo" do
      x.t.emulator.tmux = true # Terminfo (Cr) path is not DCS-wrapped
      x.t.reset_cursor_color
      x.o.should eq "\e]112\a"
      x.t.emulator.tmux = false
    end

    it "works plain" do
      x.p.emulator.tmux = true # Also test wrapping in DCS sequences
      x.p.reset_cursor_color
      x.o.should eq "\ePtmux;\e\e]112\a\e\\"
      x.p.emulator.tmux = false
    end
  end

  describe "save_cursor_a / restore_cursor_a (ANSI.SYS)" do
    # The `_a` variants are SCOSC/SCORC (`CSI s` / `CSI u`) and must emit those
    # literal sequences even when a terminfo is loaded — they must NOT route
    # through the terminfo `sc`/`rc` caps, which are the distinct DECSC/DECRC
    # (`\e7`/`\e8`) operations. `#save_cursor`/`#restore_cursor` are the DECSC ones.
    it "emits CSI s / CSI u, not DECSC / DECRC, with terminfo" do
      x.t.cup 8, 9; x.o

      x.t.save_cursor_a.should be_true
      x.o.should eq "\e[s"
      x.t.saved_cursor.not_nil!.x.should eq 9
      x.t.saved_cursor.not_nil!.y.should eq 8

      x.t.cursor.x = 0
      x.t.cursor.y = 0

      x.t.restore_cursor_a.should be_true
      x.o.should eq "\e[u"
      x.t.cursor.x.should eq 9
      x.t.cursor.y.should eq 8
    end
  end

  describe "lsave_cursor / lrestore_cursor (local save)" do
    # `@cursor` is a mutable `Point` (reference type), so the local save must
    # store a *copy*. Storing the live cursor aliased the saved state to the
    # cursor itself: a later move mutated the "saved" point in place, so the
    # restore returned the current position instead of the saved one.
    it "restores the position captured at save time, not the latest one" do
      x.t.cup 8, 9; x.o
      x.t.lsave_cursor("local")

      # Move away after saving; this must NOT disturb the saved state.
      x.t.cup 2, 3; x.o
      x.t.cursor.x.should eq 3
      x.t.cursor.y.should eq 2

      x.t.lrestore_cursor("local")
      # The local restore re-issues a cup to the saved position; drain it from
      # the shared buffer so it does not leak into the next example.
      x.o.should eq "\e[9;10H"
      x.t.cursor.x.should eq 9
      x.t.cursor.y.should eq 8
    end
  end

  describe "dynamic_cursor_color" do
    it "works with terminfo" do
      x.t.dynamic_cursor_color "blue"
      x.o.should eq "\e]12;blue\a"
    end

    it "works plain" do
      x.p.dynamic_cursor_color "blue"
      x.o.should eq "\e]12;blue\a"
    end
  end
end
