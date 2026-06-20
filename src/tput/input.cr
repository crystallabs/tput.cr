class Tput
  module Input
    include Crystallabs::Helpers::Logging

    # Enables synced (unbuffered) output for the duration of the block.
    def with_sync_output(&)
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
    def with_raw_input(&)
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
    private def preserving_tc_mode(fd, &)
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

    def next_char(timeout : Bool = false, &)
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

    def listen(&block : Proc(Char, Key?, Array(Char), Mouse::Event?, Nil))
      with_raw_input do
        sequence = [] of Char
        while char = next_char { sequence }
          key = nil
          mouse = nil
          if char.control?
            key = Key.read_control(char) { next_char(true) { sequence } }

            # A mouse report introducer was detected; its payload bytes have
            # not been consumed yet, so read and parse them now. The encoding
            # is told apart by the last char read so far: `\e[M` -> X10,
            # `\e[<` -> SGR. On success the report is delivered as a
            # `Mouse::Event` and is no longer treated as a key.
            if key == Key::Mouse
              mouse = read_mouse(sequence) { next_char(true) { sequence } }
              key = nil
            end
          end
          yield char, key, sequence.dup, mouse
          sequence.clear
        end
      end
    end

    # Reads and parses the payload of a mouse report whose introducer (`\e[M`
    # or `\e[<`) has already been consumed into *sequence*. Returns the parsed
    # `Mouse::Event`, or `nil` if the stream ended or the report was malformed.
    private def read_mouse(sequence, &) : Mouse::Event?
      case sequence.last?
      when 'M'
        # X10 / normal encoding: exactly three raw bytes follow.
        cb = yield
        cx = yield
        cy = yield
        return nil unless cb && cx && cy
        Mouse.parse_x10 cb.ord, cx.ord, cy.ord
      when '<'
        # SGR encoding: `Cb ; Cx ; Cy` then a final `M` (press) or `m` (release).
        params = [] of Int32
        current = 0
        final = nil
        while c = yield
          case c
          when '0'..'9'
            current = current * 10 + (c.ord - '0'.ord)
          when ';'
            params << current
            current = 0
          when 'M', 'm'
            params << current
            final = c
            break
          else
            return nil
          end
        end
        return nil unless final && params.size >= 3
        Mouse.parse_sgr params[0], params[1], params[2], final
      else
        nil
      end
    end
  end
end
