require "./spec_helper"

class Tput
  class Test
    ENV["TERM"] = "xterm-256color"

    getter input = IO::Memory.new
    getter output = IO::Memory.new

    getter t : Tput
    getter p : Tput

    def initialize
      tinfo = Unibilium::Terminfo.from_env #_file "../support/xterm-256color"

      # tput with terminfo
      @t = Tput.new \
        terminfo: tinfo,
        input: @input,
        output: @output

      # tput plain
      @p = Tput.new \
        input: @input,
        output: @output
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
end
