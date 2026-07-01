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

    # Picks among the four legacy nav-key variants (base/shift/alt/ctrl) after
    # dropping the ambient lock bits. The kitty protocol folds CapsLock/NumLock
    # into this field; without stripping them, a commonly-on NumLock would make
    # modified nav keys (Ctrl+Up, Shift+Home) fail the exact match below and
    # degrade to base. Only a single shift/alt/ctrl selects a distinct member;
    # any other combination (or super/meta) falls back to base.
    #
    # Shared by the legacy CSI parser (`Key.csi_modified`) and the
    # enhanced-keyboard projection (`KeyEvent#nav`).
    def pick_nav(base : Key, shift : Key, alt : Key, ctrl : Key) : Key
      effective = self & ~(CapsLock | NumLock)
      return shift if effective == Shift
      return alt if effective == Alt
      return ctrl if effective == Ctrl
      base
    end
  end

  # A single, normalized **key** event — the keyboard counterpart of
  # `Tput::Mouse::Event`.
  #
  # The legacy parser (`Tput::Key.read_control`) collapses every keystroke into
  # a flat `Key` enum value, which can't carry a modifier bitmask, a key
  # *release*, auto-repeat, or a lone modifier press. When the terminal speaks
  # an enhanced keyboard protocol (kitty, or xterm `modifyOtherKeys`),
  # `Tput::Input#listen` parses those into a `KeyEvent` alongside the legacy `Key`.
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
    # Whether the event is a press, auto-repeat, or release. Only kitty (with
    # *report event types*) distinguishes these; everything else is `Press`.
    enum Type
      Press   = 1
      Repeat  = 2
      Release = 3
    end

    # The primary key number from the sequence. For a `u`-final (kitty/
    # modifyOtherKeys-1) event this is the Unicode codepoint or kitty functional
    # key code; for legacy-final forms it's the legacy CSI parameter (`final`
    # identifies the key instead).
    getter number : Int32

    # The CSI final byte of the originating sequence (`'u'`, `'~'`, or a cursor
    # letter such as `'A'`). Together with `number` it determines the key.
    getter final : Char

    # The active modifiers.
    getter mods : Modifiers

    # Press / repeat / release.
    getter type : Type

    # kitty *alternate keys*: shifted and base-layout codepoints, when reported
    # (*report alternate keys* flag). `nil` otherwise.
    getter shifted : Int32?
    getter base : Int32?

    # kitty *associated text*: the text the key would produce, when reported
    # (*report associated text* flag). `nil` otherwise.
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

    # The Unicode codepoint for `u`-final events. Meaningless for legacy-final
    # forms (where `number` is a CSI parameter).
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

    # Whether this event is a standalone modifier key press (Left/Right Shift,
    # Ctrl, Alt, Super, Hyper, Meta) — only reported under kitty's *report all
    # keys* flag.
    def modifier_key? : Bool
      final == 'u' && MODIFIER_KEYS.has_key?(number)
    end

    # Which standalone modifier key this is (`:left_alt`, `:right_ctrl`, …), or
    # `nil` if not a lone modifier. A `release?` of one of these is the
    # "modifier tapped" gesture.
    def modifier_key : Symbol?
      MODIFIER_KEYS[number]? if final == 'u'
    end

    # The printable character this key would produce, for press/repeat events
    # with no control-style modifier held — so plain typing keeps flowing
    # through `Input#listen`'s `char` argument even under an enhanced protocol.
    # `nil` for releases, control combos, and non-text keys.
    #
    # Prefers the terminal-supplied associated *text* (handles layouts, caps
    # lock, dead keys); else the shifted codepoint when Shift is held and
    # reported (`Shift+a` → `A`), else the base codepoint.
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
      # kitty functional key codes (arrows, F-keys, modifiers, …) occupy the
      # Unicode Private Use Area U+E000..U+F8FF; not text. Codepoints above that
      # range (emoji, supplementary-plane chars) are real text and pass through.
      return nil if cp < 0x20 || (0xE000 <= cp <= 0xF8FF)
      cp.chr rescue nil
    end

    # Projects this event back onto the flat `Key` enum, for consumers that only
    # understand legacy keys. Returns `nil` when there's no legacy equivalent (a
    # plain printable key — use `#char` — a lone modifier, or an unexpressable
    # combination).
    #
    # Releases return `nil` deliberately, so a legacy consumer never mistakes a
    # release for a press. Auto-repeats do project.
    def to_legacy_key : Key?
      return nil unless press? || repeat?

      case final
      when 'A', 'B', 'C', 'D', 'H', 'F'
        # Cursor/Home/End keys; base/shift/alt/ctrl table shared with the legacy
        # parser (`Key.csi_letter_keys`), `nav` applies this event's mods.
        if keys = Key.csi_letter_keys final
          nav(*keys)
        end
      when '~' then tilde_key
      when 'u' then u_key
      else          nil
      end
    end

    # Picks the legacy enum member for a cursor/nav key given the held modifier.
    # Only single shift/alt/ctrl map to distinct members; anything else (a
    # combination, or super/meta) falls back to the unmodified key.
    private def nav(base : Key, shift : Key, alt : Key, ctrl : Key) : Key
      mods.pick_nav base, shift, alt, ctrl
    end

    private def tilde_key : Key?
      # Navigation keys carry distinct modified members (via `nav`, table shared
      # with `Key.csi_tilde_keys`); function keys (`\e[15;1:1~` F5, …) don't —
      # delegate to `Key.function_key` so a kitty-reported F-key still projects.
      if keys = Key.csi_tilde_keys number
        nav(*keys)
      else
        Key.function_key(number)
      end
    end

    # Maps a `u`-final key number to a legacy `Key`, applying ctrl/alt like the
    # legacy parser (`Ctrl+A`, `Alt+A`, …). Plain printable keys, lone modifiers,
    # and unknown functional codes return `nil` (use `#char`).
    private def u_key : Key?
      case number
      when 27               then Key::Escape
      when 13               then Key::Enter
      when 9                then mods.shift? ? Key::ShiftTab : Key::Tab
      when 127              then Key::Backspace
      when 'a'.ord..'z'.ord then ctrl_alt_letter number
      when 'A'.ord..'Z'.ord then ctrl_alt_letter number - 'A'.ord + 'a'.ord
      else                       nil
      end
    end

    # Maps a lowercase letter codepoint to its Ctrl-/Alt-modified legacy key
    # (`CtrlA`..`CtrlZ`/`AltA`..`AltZ`), or `nil` when neither modifier is held
    # (plain letter, use `#char`). Shared by the `a`-`z` and `A`-`Z` branches of
    # `#u_key`.
    private def ctrl_alt_letter(lower : Int32) : Key?
      if ctrl?
        Key.from_value?(lower - 'a'.ord + 1) # CtrlA..CtrlZ
      elsif alt?
        Key.from_value?(Key::AltA.value + (lower - 'a'.ord))
      else
        nil
      end
    end

    # Builds a `KeyEvent` from the parsed CSI sub-parameters and the *final*
    # byte: first three sub-params of group 0 (`number : shifted : base`),
    # first two of group 1 (`mods : event`), group 2 in full (associated-text
    # codepoints). See `Input#parse_key_event`.
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
