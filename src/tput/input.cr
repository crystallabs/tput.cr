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

    # Temporarily returns the terminal to the saved (cooked) mode while a raw
    # `#listen` is active — used by `#pause`/`#restore_terminal`. `@mode` holds
    # the original mode captured by `preserving_tc_mode`; a no-op when raw mode
    # isn't currently held or the input isn't a tty.
    private def suspend_raw_input
      input = @input
      mode = @mode
      if mode && input.responds_to?(:fd) && input.tty?
        cooked = mode
        LibC.tcsetattr(input.fd, Termios::LineControl::TCSANOW, pointerof(cooked))
      end
    end

    # Re-applies raw mode after `#suspend_raw_input` — used by the `#resume`
    # continuation.
    private def restore_raw_input
      input = @input
      mode = @mode
      if mode && input.responds_to?(:fd) && input.tty?
        raw_from_tc_mode! input.fd, mode
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

            # A mouse report introducer was detected; parse the rest now. The
            # encoding is told apart by the char after `\e[` (see `#read_mouse`):
            # `M` X10, `<` SGR/DEC-locator, `I`/`O` focus, a digit URxvt. On
            # success the report is delivered as a `Mouse::Event` and is no
            # longer treated as a key.
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

    # Reads and parses the payload of a mouse report whose introducer has
    # already been consumed into *sequence*. The character right after `\e[`
    # (`sequence[2]`) selects the encoding:
    #
    #   * `M`      — X10 / normal (three raw bytes follow).
    #   * `I`/`O`  — focus-in / focus-out (no payload).
    #   * `<`      — SGR (1006) or DEC-locator (the parameter list follows).
    #   * a digit  — URxvt (1015); the whole report is already in *sequence*.
    #
    # Returns the parsed `Mouse::Event`, or `nil` if the stream ended or the
    # report was malformed.
    private def read_mouse(sequence, &) : Mouse::Event?
      case sequence[2]? || '\0'
      when 'M'
        # X10 / normal encoding: exactly three raw bytes follow.
        cb = yield
        cx = yield
        cy = yield
        return nil unless cb && cx && cy
        Mouse.parse_x10 cb.ord, cx.ord, cy.ord
      when 'I'      then Mouse::Event.focus
      when 'O'      then Mouse::Event.blur
      when '<'      then read_sgr_or_dec { yield }
      when '0'..'9' then read_urxvt sequence
      else               nil
      end
    end

    # Reads an SGR (`Cb ; Cx ; Cy M|m`) or DEC-locator (`Cb ; Cx ; Cy ; Cp & w`)
    # parameter list following the `\e[<` introducer. Yields for each char.
    private def read_sgr_or_dec(&) : Mouse::Event?
      params = [] of Int32
      current = 0
      while c = yield
        case c
        when '0'..'9' then current = current * 10 + (c.ord - '0'.ord)
        when ';'      then params << current; current = 0
        when 'M', 'm'
          params << current
          return nil unless params.size >= 3
          return Mouse.parse_sgr params[0], params[1], params[2], c
        when '&'
          # DEC locator: `&` then `w`.
          params << current
          return nil unless yield == 'w' && params.size >= 4
          return Mouse.parse_dec params[0], params[1], params[2], params[3]
        else
          return nil
        end
      end
      nil
    end

    # Parses a URxvt report (`\e[ Cb ; Cx ; Cy M`) already captured in
    # *sequence* (the key parser consumed the whole parameter list).
    private def read_urxvt(sequence) : Mouse::Event?
      params = [] of Int32
      current = 0
      i = 2
      while i < sequence.size
        c = sequence[i]
        case c
        when '0'..'9' then current = current * 10 + (c.ord - '0'.ord)
        when ';'      then params << current; current = 0
        when 'M', 'm' then params << current; break
        else               break
        end
        i += 1
      end
      return nil unless params.size >= 3
      Mouse.parse_urxvt params[0], params[1], params[2]
    end
  end
end
