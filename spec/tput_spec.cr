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
      seq = x.t.capture { |t| t.cursor_pos 1, 2 }
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
      x.p.capture { |t| t.bell }
      x.p.bell
      x.o.should eq "\x07"
    end
  end
end
