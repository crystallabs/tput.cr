class Tput
  enum Key
    CtrlA = 1
    CtrlB = 2
    CtrlC = 3
    CtrlD = 4
    CtrlE = 5
    CtrlF = 6
    CtrlG = 7
    CtrlH = 8

    Tab   = 9
    CtrlI = 9

    CtrlJ = 10
    CtrlK = 11
    CtrlL = 12

    Enter = 13
    CtrlM = 13

    CtrlN = 14
    CtrlO = 15
    CtrlP = 16
    CtrlQ = 17
    CtrlR = 18
    CtrlS = 19
    CtrlT = 20
    CtrlU = 21
    CtrlV = 22
    CtrlW = 23
    CtrlX = 24
    CtrlY = 25
    CtrlZ = 26

    Escape = 27

    Space = 32

    Backspace = 127
    AltEnter
    ShiftTab

    # Never used in code, just a hint for Crystal to not create collisions
    # while assigning enum numbers to the following, unnumbered fields.
    FixAutonumbering = 1000

    Home
    End
    PageUp
    PageDown
    Insert
    Delete

    Up
    Down
    Left
    Right
    ShiftUp
    ShiftDown
    ShiftLeft
    ShiftRight
    CtrlUp
    CtrlDown
    CtrlLeft
    CtrlRight
    AltUp
    AltDown
    AltLeft
    AltRight

    F1
    F2
    F3
    F4
    F5
    F6
    F7
    F8
    F9
    F10
    F11
    F12

    AltA # = 27 97
    AltB # = 27 98
    AltC #      ...
    AltD
    AltE
    AltF
    AltG
    AltH
    AltI
    AltJ
    AltK
    AltL
    AltM
    AltN
    AltO
    AltP
    AltQ
    AltR
    AltS
    AltT
    AltU
    AltV
    AltW
    AltX
    AltY
    AltZ

    Menu = 16777301

    Unknown = 33554431

    # Reads a `Control` input from *char*.  If an escape sequence was detected,
    # calls the given block for the next `Char?`.
    def self.read_control(char : Char) : Key?
      case char.ord
      when Key::Escape.value
        read_escape_sequence(char) { yield } || Key::Escape
      else
        Key.from_value?(char.ord)
      end # || Key::Unknown
    end

    # Reads further chars while determining the key that was pressed.
    private def self.read_escape_sequence(char)
      # TODO add support alt+Fn keys, shift+Fn keys, and
      # many others too, but the complete framework is here,
      # it just comes down to adding tree elements.
      case yield.try(&.ord)
      when 13 then Key::AltEnter
        # when 27 then Key::Escape
      when 79 # Movement and F-keys
        case yield.try(&.ord)
        when 65 then Key::Up
        when 66 then Key::Down
        when 67 then Key::Right
        when 68 then Key::Left
        when 80 then Key::F1
        when 81 then Key::F2
        when 82 then Key::F3
        when 83 then Key::F4
        else
          nil
        end
      when 91 # Movement and F-keys
        case yield.try(&.ord)
        when 49
          case yield.try(&.ord)
          when 53
            yield
            Key::F5
          when 55
            yield
            Key::F6
          when 56
            yield
            Key::F7
          when 57
            yield
            Key::F8
          when 59
            case yield.try(&.ord)
            when 50
              case yield.try(&.ord)
              when 65 then Key::ShiftUp
              when 66 then Key::ShiftDown
              when 67 then Key::ShiftRight
              when 68 then Key::ShiftLeft
              else
                nil
              end
            when 51
              case yield.try(&.ord)
              when 65 then Key::AltUp
              when 66 then Key::AltDown
              when 67 then Key::AltRight
              when 68 then Key::AltLeft
              else
                nil
              end
            when 53
              case yield.try(&.ord)
              when 65 then Key::CtrlUp
              when 66 then Key::CtrlDown
              when 67 then Key::CtrlRight
              when 68 then Key::CtrlLeft
              else
                nil
              end
            else
              nil
            end
          else
            Key::Home
          end
        when 50
          case yield.try(&.ord)
          when 48
            yield
            Key::F9
          when 49
            yield
            Key::F10
          when 51
            yield
            Key::F11
          when 52
            yield
            Key::F12
          when 57
            case yield.try(&.ord)
            when 126
              Key::Menu
            end
          else
            Key::Insert
          end
        when 51
          yield
          Key::Delete
        when 52
          yield
          Key::End
        when 53
          yield
          Key::PageUp
        when 54
          yield
          Key::PageDown
        when 65 then Key::Up
        when 66 then Key::Down
        when 67 then Key::Right
        when 68 then Key::Left
        when 70 then Key::End
        when 72 then Key::Home
        when 90 then Key::ShiftTab
        else
          nil
        end
        # Alt-Letter keys
      when  97 then Key::AltA
      when  98 then Key::AltB
      when  99 then Key::AltC
      when 100 then Key::AltD
      when 101 then Key::AltE
      when 102 then Key::AltF
      when 103 then Key::AltG
      when 104 then Key::AltH
      when 105 then Key::AltI
      when 106 then Key::AltJ
      when 107 then Key::AltK
      when 108 then Key::AltL
      when 109 then Key::AltM
      when 110 then Key::AltN
      when 111 then Key::AltO
      when 112 then Key::AltP
      when 113 then Key::AltQ
      when 114 then Key::AltR
      when 115 then Key::AltS
      when 116 then Key::AltT
      when 117 then Key::AltU
      when 118 then Key::AltV
      when 119 then Key::AltW
      when 120 then Key::AltX
      when 121 then Key::AltY
      when 122 then Key::AltZ
      else
        nil
      end
    end
  end
end
