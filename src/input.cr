class Tput
  module Input

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

		# Copied from IO::FileDescriptor, as this method is sadly `private`.
		def raw_from_tc_mode!(fd, mode)
			LibC.cfmakeraw(pointerof(mode))
			LibC.tcsetattr(fd, Termios::LineControl::TCSANOW, pointerof(mode))
		end

		# Copied from IO::FileDescriptor, as this method is sadly `private`.
		def preserving_tc_mode(fd)
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

    def listen(&block : Proc(Key?,Nil))
      loop do
        with_raw_input do
          get_key.try { |k|
            block.call(k)
            emit KeyPressEvent, k
          }
        end
      end
    end
    def listen
      loop do
      #with_sync_output do
        with_raw_input do
          get_key.try { |k|
            emit KeyPressEvent, k
          }
        end
      #end
      end
    end

    def read_char
      if c = @input.read_char
        #yield << c
      end
      c
    end

    def get_key
      #sequence = Bytes.new 64
      k = if char = read_char #{ sequence }
        if char.control?
          key, mod = read_control(char) { @input.read_char }
          if key
            Key.new \
              key: Keys.new(key),
              modifier: mod
          else
            # Control pressed, but otherwise just "simple" key
            Key.new \
              key: Keys.new(char.ord),
              modifier: KeyModifier::CTRL |
                (char.uppercase? ? KeyModifier::SHIFT : KeyModifier::NONE)
              #sequence: sequence
          end
        else
          # Just "simple" key
          Key.new \
            key: Keys.new(char.ord),
            modifier: char.uppercase? ? KeyModifier::SHIFT : KeyModifier::NONE
            #sequence: sequence
        end
      end


    end

    def read_control(char : Char)
      case char.ord
      when 27 # Escape
        read_escape_sequence(char){ yield }
      else
        {char.ord, KeyModifier::CTRL}
      end
    end

    # TODO support alt+f keys, shift+f keys
    # many others too, but the framework is here.
    def read_escape_sequence(char)
      mod = KeyModifier::NONE

      key = case yield.try(&.ord)
      when 13
        mod |= KeyModifier::ALT
        Keys::Key_AltReturn
      when 79 # F-keys
        case yield.try(&.ord)
        when 80 then Keys::Key_F1
        when 81 then Keys::Key_F2
        when 82 then Keys::Key_F3
        when 83 then Keys::Key_F4
        else
          nil
        end
      when 91 # Movement and F-keys
        case yield.try(&.ord)
        when 49
          case yield.try(&.ord)
          when 53
            yield
            Keys::Key_F5
          when 55
            yield
            Keys::Key_F6
          when 56
            yield
            Keys::Key_F7
          when 57
            yield
            Keys::Key_F8
          when 59
            case yield.try(&.ord)
            when 50
              case yield.try(&.ord)
              when 65 then mod |= KeyModifier::SHIFT; Keys::Key_ShiftUp
              when 66 then mod |= KeyModifier::SHIFT; Keys::Key_ShiftDown
              when 67 then mod |= KeyModifier::SHIFT; Keys::Key_ShiftRight
              when 68 then mod |= KeyModifier::SHIFT; Keys::Key_ShiftLeft
              else
                nil
              end
            when 51
              case yield.try(&.ord)
              when 65 then mod |= KeyModifier::ALT; Keys::Key_AltUp
              when 66 then mod |= KeyModifier::ALT; Keys::Key_AltDown
              when 67 then mod |= KeyModifier::ALT; Keys::Key_AltRight
              when 68 then mod |= KeyModifier::ALT; Keys::Key_AltLeft
              else
                nil
              end
            when 53
              case yield.try(&.ord)
              when 65 then mod |= KeyModifier::CTRL; Keys::Key_CtrlUp
              when 66 then mod |= KeyModifier::CTRL; Keys::Key_CtrlDown
              when 67 then mod |= KeyModifier::CTRL; Keys::Key_CtrlRight
              when 68 then mod |= KeyModifier::CTRL; Keys::Key_CtrlLeft
              else
                nil
              end
            else
              nil
            end
          else
            Keys::Key_Home
          end
        when 50
          case yield.try(&.ord)
          when 48
            yield
            Keys::Key_F9
          when 49
            yield
            Keys::Key_F10
          when 51
            yield
            Keys::Key_F11
          when 52
            yield
            Keys::Key_F12
          else
            Keys::Key_Insert
          end
        when 51
          yield
          Keys::Key_Delete
        when 52
          yield
          Keys::Key_End
        when 53
          yield
          Keys::Key_PageUp
        when 54
          yield
          Keys::Key_PageDown
        when 65 then Keys::Key_Up
        when 66 then Keys::Key_Down
        when 67 then Keys::Key_Right
        when 68 then Keys::Key_Left
        when 70 then Keys::Key_End
        when 72 then Keys::Key_Home
        when 90 then mod |= KeyModifier::SHIFT; Keys::Key_ShiftTab
        else
          nil
        end
      # Alt-Letter keys
      when 97 then  mod |= KeyModifier::ALT; Keys::Key_AltA
      when 98 then  mod |= KeyModifier::ALT; Keys::Key_AltB
      when 99 then  mod |= KeyModifier::ALT; Keys::Key_AltC
      when 100 then mod |= KeyModifier::ALT; Keys::Key_AltD
      when 101 then mod |= KeyModifier::ALT; Keys::Key_AltE
      when 102 then mod |= KeyModifier::ALT; Keys::Key_AltF
      when 103 then mod |= KeyModifier::ALT; Keys::Key_AltG
      when 104 then mod |= KeyModifier::ALT; Keys::Key_AltH
      when 105 then mod |= KeyModifier::ALT; Keys::Key_AltI
      when 106 then mod |= KeyModifier::ALT; Keys::Key_AltJ
      when 107 then mod |= KeyModifier::ALT; Keys::Key_AltK
      when 108 then mod |= KeyModifier::ALT; Keys::Key_AltL
      when 109 then mod |= KeyModifier::ALT; Keys::Key_AltM
      when 110 then mod |= KeyModifier::ALT; Keys::Key_AltN
      when 111 then mod |= KeyModifier::ALT; Keys::Key_AltO
      when 112 then mod |= KeyModifier::ALT; Keys::Key_AltP
      when 113 then mod |= KeyModifier::ALT; Keys::Key_AltQ
      when 114 then mod |= KeyModifier::ALT; Keys::Key_AltR
      when 115 then mod |= KeyModifier::ALT; Keys::Key_AltS
      when 116 then mod |= KeyModifier::ALT; Keys::Key_AltT
      when 117 then mod |= KeyModifier::ALT; Keys::Key_AltU
      when 118 then mod |= KeyModifier::ALT; Keys::Key_AltV
      when 119 then mod |= KeyModifier::ALT; Keys::Key_AltW
      when 120 then mod |= KeyModifier::ALT; Keys::Key_AltX
      when 121 then mod |= KeyModifier::ALT; Keys::Key_AltY
      when 122 then mod |= KeyModifier::ALT; Keys::Key_AltZ
      else
        nil
      end || Keys::Key_unknown

      {key, mod}
    end

  end
end
