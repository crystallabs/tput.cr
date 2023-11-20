class Tput
  module Input
    include Crystallabs::Helpers::Logging

    # Enables synced (unbuffered) output for the duration of the block.
    def with_sync_output
      output = @output
      if output.is_a?(IO::Buffered)
        before = output.sync?

        begin
          output.sync = true
          yield
        ensure
          output.sync = before
        end
      else
        yield
      end
    end

    # Enables raw (unbuffered, non-cooked) input for the duration of the block.
    def with_raw_input
      input = @input
      if @mode.nil? && input.responds_to?(:fd) && input.tty?
        preserving_tc_mode(input.fd) do |mode|
          raw_from_tc_mode!(input.fd, mode)
          yield
        end
      else
        yield
      end
    end

    # Copied from IO::FileDescriptor, as this method is sadly `private` there.
    private def raw_from_tc_mode!(fd, mode)
      LibC.cfmakeraw(pointerof(mode))
      LibC.tcsetattr(fd, Termios::LineControl::TCSANOW, pointerof(mode))
    end

    # Copied from IO::FileDescriptor, as this method is sadly `private` there.
    private def preserving_tc_mode(fd)
      if LibC.tcgetattr(fd, out mode) != 0
        raise RuntimeError.from_errno("Failed to enable raw mode on output")
      end

      before = mode
      @mode = mode

      begin
        yield mode
      ensure
        @mode = nil
        LibC.tcsetattr(fd, Termios::LineControl::TCSANOW, pointerof(before))
      end
    end

    def next_char(timeout : Bool = false)
      input = @input

      if timeout && input.responds_to? :"read_timeout="
        input.read_timeout = @read_timeout
      end

      begin
        c = input.read_char
      rescue IO::TimeoutError
        c = nil
      end

      if c
        yield << c
      end

      if timeout && input.responds_to? :"read_timeout="
        input.read_timeout = nil
      end

      c
    end

    def listen(&block : Proc(Char, Key?, Array(Char), Nil))
      with_raw_input do
        sequence = [] of Char
        while char = next_char { sequence }
          key = nil
          if char.control?
            key = Key.read_control(char) { next_char(true) { sequence } }
          end
          yield char, key, sequence.dup
          sequence.clear
        end
      end
    end
  end
end
