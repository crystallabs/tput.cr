class Tput
  # Keyboard modifiers, as a bitmask.
  #
  # The bit order matches the modifier encoding shared by xterm
  # (`modifyOtherKeys`) and the kitty keyboard protocol: the on-the-wire value
  # is `1 + bitmask`, with `shift = 1`, `alt = 2`, `ctrl = 4`, `super = 8`,
  # `hyper = 16`, `meta = 32`, `caps_lock = 64`, `num_lock = 128`. So a raw
  # modifier parameter `Pm` maps to `Modifiers.new(Pm - 1)` (see
  # `KeyEvent.from_csi`).
  @[Flags]
  enum Modifiers
    Shift
    Alt
    Ctrl
    Super
    Hyper
    Meta
    CapsLock
    NumLock
  end

  # A single, normalized **key** event — the keyboard counterpart of
  # `Tput::Mouse::Event`.
  #
  # The legacy parser (`Tput::Key.read_control`) collapses every keystroke into
  # a flat `Key` enum value, which cannot carry a modifier bitmask, a key
  # *release*, auto-repeat, or a lone modifier press. When the terminal speaks
  # an enhanced keyboard protocol (the kitty keyboard protocol, or xterm
  # `modifyOtherKeys`) `Tput::Input#listen` parses those richer sequences into a
  # `KeyEvent` and yields it alongside the legacy `Key`.
  #
  # The encodings understood (all re-parsed from the raw sequence by
  # `Input#parse_key_event`):
  #
  #   * kitty / `modifyOtherKeys` format 1 — `CSI number ; mods : event ; text u`
  #   * `modifyOtherKeys` format 0          — `CSI 27 ; mods ; number ~`
  #   * kitty modified nav/function keys    — a legacy final byte (`A`-`H`, `~`)
  #     carrying an event-type sub-parameter, e.g. `CSI 1 ; 5 : 3 A` (Ctrl+Up
  #     release).
  struct KeyEvent
    # Whether the event is a key press, an auto-repeat, or a release. Only the
    # kitty protocol (with its *report event types* flag) distinguishes these;
    # everything else is always a `Press`.
    enum Type
      Press   = 1
      Repeat  = 2
      Release = 3
    end

    # The primary key number from the sequence. For a `u`-final (kitty /
    # modifyOtherKeys-1) event this is the Unicode codepoint or kitty functional
    # key code; for the legacy-final forms it is the legacy CSI parameter (and
    # `final` identifies the key instead).
    getter number : Int32

    # The CSI final byte of the originating sequence (`'u'`, `'~'`, or a cursor
    # letter such as `'A'`). Together with `number` it determines the key.
    getter final : Char

    # The active modifiers.
    getter mods : Modifiers

    # Press / repeat / release.
    getter type : Type

    # kitty *alternate keys*: the shifted and base-layout codepoints, when the
    # terminal reports them (the *report alternate keys* flag). `nil` otherwise.
    getter shifted : Int32?
    getter base : Int32?

    # kitty *associated text*: the text the key would produce, when the terminal
    # reports it (the *report associated text* flag). `nil` otherwise.
    getter text : String?

    # kitty functional key codes for the standalone modifier keys. A `u`-final
    # event whose `number` is one of these is a lone modifier press/release —
    # the basis for gestures like "tap Alt" (see `#modifier_key`).
    MODIFIER_KEYS = {
      57441 => :left_shift, 57442 => :left_control, 57443 => :left_alt,
      57444 => :left_super, 57445 => :left_hyper, 57446 => :left_meta,
      57447 => :right_shift, 57448 => :right_control, 57449 => :right_alt,
      57450 => :right_super, 57451 => :right_hyper, 57452 => :right_meta,
    }

    def initialize(@number, @final, @mods = Modifiers::None, @type = Type::Press,
                   @shifted = nil, @base = nil, @text = nil)
    end

    # The Unicode codepoint this event carries, for `u`-final events. Meaningless
    # for the legacy-final forms (where `number` is a CSI parameter).
    def codepoint : Int32
      number
    end

    def press? : Bool
      type.press?
    end

    def release? : Bool
      type.release?
    end

    def repeat? : Bool
      type.repeat?
    end

    {% for m in %w[shift alt ctrl super hyper meta] %}
      def {{m.id}}? : Bool
        mods.{{m.id}}?
      end
    {% end %}

    # Whether this event is a standalone modifier key (Left/Right Shift, Ctrl,
    # Alt, Super, Hyper, Meta) — only ever reported under the kitty protocol's
    # *report all keys* flag.
    def modifier_key? : Bool
      final == 'u' && MODIFIER_KEYS.has_key?(number)
    end

    # Which standalone modifier key this is (`:left_alt`, `:right_ctrl`, …), or
    # `nil` if the event is not a lone modifier. A `release?` of one of these is
    # the "modifier tapped" gesture.
    def modifier_key : Symbol?
      MODIFIER_KEYS[number]? if final == 'u'
    end

    # The printable character this key would produce, for press/repeat events
    # with no control-style modifier held — so plain typing keeps flowing through
    # `Input#listen`'s `char` argument even when the terminal reports all keys as
    # escape sequences. `nil` for releases, control combos, and non-text keys.
    #
    # Prefers the terminal-supplied associated *text* (handles layouts, caps
    # lock, dead keys); otherwise the shifted codepoint when Shift is held and
    # reported (so `Shift+a` is `A`, not `a`), else the base codepoint.
    def char : Char?
      return nil unless press? || repeat?
      if t = text
        return t[0]?
      end
      return nil unless final == 'u'
      # Don't surface a character when ctrl/alt/super/meta is held — those are
      # control combinations, represented through `to_legacy_key`/`mods`.
      return nil if ctrl? || alt? || super? || meta? || hyper?
      cp = (shift? ? shifted : nil) || number
      # Functional keys (kitty codes for arrows, F-keys, modifiers, …) live in
      # the Unicode Private Use Area (0xE000+); they are not text.
      return nil if cp < 0x20 || cp >= 0xE000
      cp.chr rescue nil
    end

    # Projects this event back onto the flat `Key` enum, so consumers that only
    # understand legacy keys keep working. Returns `nil` when there is no legacy
    # equivalent (a plain printable key — surfaced via `#char` instead — a lone
    # modifier, or a modifier combination the enum can't express).
    #
    # Releases return `nil` deliberately: a consumer that predates the enhanced
    # stream should not mistake a key *release* for a press. Auto-repeats do
    # project (a held key still produces its key).
    def to_legacy_key : Key?
      return nil unless press? || repeat?

      case final
      when 'A' then nav Key::Up, Key::ShiftUp, Key::AltUp, Key::CtrlUp
      when 'B' then nav Key::Down, Key::ShiftDown, Key::AltDown, Key::CtrlDown
      when 'C' then nav Key::Right, Key::ShiftRight, Key::AltRight, Key::CtrlRight
      when 'D' then nav Key::Left, Key::ShiftLeft, Key::AltLeft, Key::CtrlLeft
      when 'H' then nav Key::Home, Key::ShiftHome, Key::AltHome, Key::CtrlHome
      when 'F' then nav Key::End, Key::ShiftEnd, Key::AltEnd, Key::CtrlEnd
      when '~' then tilde_key
      when 'u' then u_key
      else          nil
      end
    end

    # Picks the legacy enum member for a cursor/nav key given the held modifier.
    # Only single shift/alt/ctrl map to distinct members; anything else (a
    # combination, or super/meta) falls back to the unmodified key.
    private def nav(base : Key, shift : Key, alt : Key, ctrl : Key) : Key
      return shift if mods == Modifiers::Shift
      return alt if mods == Modifiers::Alt
      return ctrl if mods == Modifiers::Ctrl
      base
    end

    private def tilde_key : Key?
      base = case number
             when 1, 7 then {Key::Home, Key::ShiftHome, Key::AltHome, Key::CtrlHome}
             when 2    then {Key::Insert, Key::ShiftInsert, Key::AltInsert, Key::CtrlInsert}
             when 3    then {Key::Delete, Key::ShiftDelete, Key::AltDelete, Key::CtrlDelete}
             when 4, 8 then {Key::End, Key::ShiftEnd, Key::AltEnd, Key::CtrlEnd}
             when 5    then {Key::PageUp, Key::ShiftPageUp, Key::AltPageUp, Key::CtrlPageUp}
             when 6    then {Key::PageDown, Key::ShiftPageDown, Key::AltPageDown, Key::CtrlPageDown}
             else           nil
             end
      base ? nav(*base) : nil
    end

    # Maps a `u`-final key number to a legacy `Key`, applying ctrl/alt the way
    # the legacy parser does (`Ctrl+A`, `Alt+A`, …). Plain printable keys return
    # `nil` (use `#char`); lone modifiers and unknown functional codes too.
    private def u_key : Key?
      case number
      when 27  then Key::Escape
      when 13  then Key::Enter
      when 9   then mods.shift? ? Key::ShiftTab : Key::Tab
      when 127 then Key::Backspace
      when 'a'.ord..'z'.ord
        if ctrl?
          Key.from_value?(number - 'a'.ord + 1) # CtrlA..CtrlZ
        elsif alt?
          Key.from_value?(Key::AltA.value + (number - 'a'.ord))
        else
          nil
        end
      when 'A'.ord..'Z'.ord
        lower = number - 'A'.ord + 'a'.ord
        if ctrl?
          Key.from_value?(lower - 'a'.ord + 1)
        elsif alt?
          Key.from_value?(Key::AltA.value + (lower - 'a'.ord))
        else
          nil
        end
      else
        nil
      end
    end

    # Builds a `KeyEvent` from the parsed CSI sub-parameters and the *final*
    # byte. The arguments are the first three sub-parameters of group 0
    # (`number : shifted : base`), the first two of group 1 (`mods : event`),
    # and group 2 in full (`text` — the associated-text codepoints, `nil` when
    # absent). See `Input#parse_key_event` for how these are extracted.
    def self.from_csi(final : Char, g0_0 : Int32?, g0_1 : Int32?, g0_2 : Int32?,
                      g1_0 : Int32?, g1_1 : Int32?, g2 : Array(Int32?)?) : KeyEvent
      if final == '~' && g0_0 == 27
        # modifyOtherKeys format 0: CSI 27 ; mods ; number ~
        modval = g1_0 || 1
        number = g2.try(&.[0]?) || 0
        return new number, 'u', mods_from(modval), Type::Press
      end

      number = g0_0 || 0
      modval = g1_0 || 1
      event = g1_1 || 1
      text = decode_text g2

      new number, final, mods_from(modval), (Type.from_value?(event) || Type::Press),
        g0_1, g0_2, text
    end

    private def self.mods_from(value : Int32) : Modifiers
      return Modifiers::None if value <= 0
      Modifiers.from_value((value - 1) & 0xFF)
    end

    private def self.decode_text(group : Array(Int32?)?) : String?
      return nil unless group
      cps = group.compact
      return nil if cps.empty?
      String.build { |io| cps.each { |cp| io << cp.chr } }
    rescue
      nil
    end
  end
end
