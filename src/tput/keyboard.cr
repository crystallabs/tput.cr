class Tput
  # Enhanced keyboard protocols, ordered least → most capable (mirroring
  # `GraphicsProtocol`). `Legacy` is the always-available baseline — the
  # xterm-style encodings `Tput::Key` parses unconditionally — and the others
  # re-encode keyboard input more richly, but only when the terminal supports
  # them (discovered by `Tput#probe!`, see `Tput::Features`).
  enum KeyboardProtocol
    Legacy
    ModifyOtherKeys
    Kitty
  end

  # Kitty keyboard protocol progressive-enhancement flags — a bitmask pushed
  # onto the terminal's keyboard stack with `CSI > flags u`. They are additive:
  #
  #   * `DisambiguateEscapeCodes` — safe to always enable; only removes
  #     ambiguity (Esc vs Alt, Tab vs Ctrl+I, …), never relocates ordinary text.
  #   * `ReportEventTypes` — adds press / repeat / **release** to each event.
  #   * `ReportAlternateKeys` — adds the shifted and base-layout codepoints.
  #   * `ReportAllKeys` — reports **every** key as an escape code, including lone
  #     modifiers and plain text (needed to observe a bare Alt tap).
  #   * `ReportAssociatedText` — attaches the text a key would produce.
  @[Flags]
  enum KittyKeyboard
    DisambiguateEscapeCodes
    ReportEventTypes
    ReportAlternateKeys
    ReportAllKeys
    ReportAssociatedText
  end

  # Enhanced keyboard protocol negotiation and enabling.
  #
  # `Tput#probe!` detects which protocols the terminal supports; this module
  # picks the best one (honoring user exclusions) and turns it on/off. The
  # selection mirrors the image-backend `resolve` pattern: a ranked candidate
  # list, minus the user-excluded protocols, picking the first the terminal
  # actually supports, falling back to the always-available `Legacy` baseline.
  #
  # Parsing of the resulting sequences is unconditional and lives in
  # `Tput::Input#parse_key_event` / `Tput::KeyEvent`: a terminal that doesn't
  # support (or that the user excluded) an enhanced protocol simply never emits
  # the richer sequences, so the parser never sees them.
  module Keyboard
    # Ranked candidate protocols, best → worst, always ending in `Legacy`.
    def keyboard_candidates : Array(KeyboardProtocol)
      [KeyboardProtocol::Kitty, KeyboardProtocol::ModifyOtherKeys, KeyboardProtocol::Legacy]
    end

    # Protocols the user has excluded via the `keyboard.exclude` config option
    # (comma/space-separated names, e.g. `"kitty modify_other_keys"`). Unknown
    # names are ignored. Mirrors crysterm's `media.exclude`.
    def excluded_keyboard_protocols : Array(KeyboardProtocol)
      Superconf.keyboard_exclude
        .split(/[\s,]+/, remove_empty: true)
        .compact_map { |s| KeyboardProtocol.parse?(s) }
    end

    # Whether *protocol* is usable on this terminal. `Legacy` always is; the
    # enhanced ones require the corresponding `Tput#probe!` reply.
    def keyboard_protocol_supported?(protocol : KeyboardProtocol) : Bool
      case protocol
      in .legacy?            then true
      in .kitty?             then features.kitty_keyboard?
      in .modify_other_keys? then features.modify_other_keys?
      end
    end

    # The keyboard protocol to use: an explicit `keyboard.protocol` config
    # override if set, otherwise the first ranked candidate that is neither
    # user-excluded nor unsupported — falling back to `Legacy`, which always
    # works.
    def best_keyboard_protocol : KeyboardProtocol
      forced = Superconf.keyboard_protocol
      if forced != "auto"
        if p = KeyboardProtocol.parse?(forced)
          return p
        end
      end

      excluded = excluded_keyboard_protocols
      keyboard_candidates.each do |protocol|
        next if excluded.includes? protocol
        return protocol if keyboard_protocol_supported? protocol
      end
      KeyboardProtocol::Legacy
    end

    # Enables the best available enhanced keyboard protocol
    # (`#best_keyboard_protocol`) and returns the protocol actually enabled
    # (`Legacy` means nothing extra was turned on).
    #
    # Pass *events* `true` to also request modifier-aware and
    # press/repeat/release reporting — the flags needed to observe lone modifier
    # keys and key releases (e.g. a "tap Alt" gesture). With *events* `false`
    # only escape-code disambiguation is requested, which never relocates
    # ordinary typing. *events* is ignored by `ModifyOtherKeys`, which cannot
    # report lone modifiers or releases regardless.
    def enable_keyboard_protocol(events : Bool = false) : KeyboardProtocol
      protocol = best_keyboard_protocol
      case protocol
      when .kitty?
        flags = KittyKeyboard::DisambiguateEscapeCodes
        if events
          flags |= KittyKeyboard::ReportEventTypes | KittyKeyboard::ReportAllKeys |
                   KittyKeyboard::ReportAlternateKeys |  # so shifted codepoints arrive
                   KittyKeyboard::ReportAssociatedText   # so the text a key *produces* arrives
          # `ReportAllKeys` makes the terminal report every key — plain typing
          # included — as an escape code, and it then stops sending the decoded
          # text bytes. Without `ReportAssociatedText` the `u` events carry only
          # the raw key codepoint, so `KeyEvent#char` can do no better than guess
          # from the base/shifted codepoint — wrong for non-US layouts, AltGr,
          # dead keys, and caps lock. Requesting the associated text is what lets
          # `#char` reproduce what the user actually typed (see `KeyEvent#char`).
        end
        enable_kitty_keyboard flags
      when .modify_other_keys?
        enable_modify_other_keys 2
      end
      @keyboard_events = events
      @keyboard_protocol = protocol
    end

    # Disables whatever enhanced protocol `#enable_keyboard_protocol` turned on,
    # restoring the terminal's default keyboard reporting.
    def disable_keyboard_protocol : Nil
      case @keyboard_protocol
      when KeyboardProtocol::Kitty           then disable_kitty_keyboard
      when KeyboardProtocol::ModifyOtherKeys then disable_modify_other_keys
      end
      @keyboard_protocol = nil
    end

    # --- Low-level enable/disable --------------------------------------------

    # Pushes a kitty keyboard *flags* set onto the terminal's protocol stack
    # (`CSI > flags u`); undo with `#disable_kitty_keyboard`.
    def enable_kitty_keyboard(flags : KittyKeyboard = KittyKeyboard::DisambiguateEscapeCodes) : Nil
      _print "\e[>#{flags.value}u"
    end

    # Pops one entry off the terminal's kitty keyboard protocol stack
    # (`CSI < u`), undoing one `#enable_kitty_keyboard`.
    def disable_kitty_keyboard : Nil
      _print "\e[<u"
    end

    # Enables xterm `modifyOtherKeys` at *level* (1 or 2), via `CSI > 4 ; Ps m`.
    def enable_modify_other_keys(level : Int32 = 2) : Nil
      set_resources 4, level
    end

    # Disables xterm `modifyOtherKeys` (`CSI > 4 n`).
    def disable_modify_other_keys : Nil
      disable_modifiers "4"
    end
  end
end
