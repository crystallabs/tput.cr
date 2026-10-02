require "spec"

# Doesn't have effect
# require "log"
# Log.setup_from_env backend: Log::IOBackend.new STDERR

require "../src/tput"

class Tput
  class Test
    ENV["TERM"] = "xterm-256color"

    getter input = IO::Memory.new
    getter output = IO::Memory.new

    getter t : Tput
    getter p : Tput

    getter term : Unibilium

    def initialize
      @term = Unibilium.from_file "#{__DIR__}/../support/xterm-256color"

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
