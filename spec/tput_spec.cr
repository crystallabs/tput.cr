require "./spec_helper"

class Tput
  class Test
    ENV["TERM"] = "xterm-256color"

    getter input = IO::Memory.new
    getter output = IO::Memory.new

    getter t : Tput
    getter p : Tput

    getter term : Unibilium

    def initialize
      @term = Unibilium.from_env # _file "../support/xterm-256color"

      # tput with terminfo
      @t = Tput.new \
        terminfo: term,
        input: @input,
        output: @output,
        screen_size: Tput::DEFAULT_SCREEN_SIZE

      # tput plain
      @p = Tput.new \
        input: @input,
        output: @output,
        screen_size: Tput::DEFAULT_SCREEN_SIZE
    end

    def o
      # Output is now batched in an internal buffer and only reaches `@output`
      # on flush (the consumer flushes at frame boundaries). Drain both tput
      # instances' buffers so this reflects what has actually reached the
      # terminal; flush is a no-op for whichever instance has nothing buffered.
      @t.flush
      @p.flush
      s = String.new @output.to_slice
      @output.clear
      s
    end

    def esc(*args)
      "\e" + args.join
    end
  end
end

describe Tput do
  x = Tput::Test.new

  describe "#capture" do
    it "returns the emitted sequence as a string instead of writing it" do
      seq = x.t.capture(&.cursor_pos(1, 2))
      seq.should eq "\e[2;3H"
      # Nothing leaked to the real output.
      x.o.should eq ""
    end

    it "captures the output of multiple calls" do
      seq = x.p.capture { |t| t.bell; t.cursor_pos 0, 0 }
      seq.should eq "\x07\e[1;1H"
      x.o.should eq ""
    end

    it "resumes writing to the terminal afterwards" do
      x.p.capture(&.bell)
      x.p.bell
      x.o.should eq "\x07"
    end
  end

  # Regression: a caller diverting output via `@ret` (e.g. Crysterm's `divert`)
  # must capture *all* tput output, including the ansi_* fast paths, which emit
  # through the block form of `_print`. Before the fix that block form ignored
  # `@ret` and leaked straight to `@output`.
  describe "#ret diversion" do
    it "captures block-form fast-path output" do
      t = Tput::Test.new
      t.t.features.ansi_cursor?.should be_true # ensure the fast path is active
      t.t.features.ansi_scroll?.should be_true
      buf = IO::Memory.new
      t.t.ret = buf
      t.t.cursor_pos(5, 9)         # ansi_cursor fast path -> _print { block }
      t.t.set_scroll_region(5, 20) # ansi_scroll fast path -> _print { block }
      t.t.ret = nil
      buf.to_s.should eq "\e[6;10H\e[6;21r"
      t.o.should eq "" # nothing leaked to the real output
    end
  end
end
