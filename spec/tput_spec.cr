require "./spec_helper"

class Tput
  class Test
    ENV["TERM"] = "xterm-256color"

    getter input = IO::Memory.new
    getter output = IO::Memory.new

    getter t : Tput
    getter p : Tput

    getter term : Unibilium::Terminfo

    def initialize
      @term = Unibilium::Terminfo.from_env # _file "../support/xterm-256color"

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
end
