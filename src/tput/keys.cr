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

    # Unused; forces autonumbering of following fields to avoid collisions.
    FixAutonumbering = 1000

    Home
    End
    PageUp
    PageDown
    Insert
    Delete

    Clear

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

    ShiftHome
    ShiftEnd
    ShiftInsert
    ShiftDelete
    ShiftPageUp
    ShiftPageDown
    CtrlHome
    CtrlEnd
    CtrlInsert
    CtrlDelete
    CtrlPageUp
    CtrlPageDown
    AltHome
    AltEnd
    AltInsert
    AltDelete
    AltPageUp
    AltPageDown

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
    F13
    F14
    F15
    F16
    F17
    F18
    F19
    F20
    F21
    F22
    F23
    F24

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

    # Mouse-reporting introducer detected: `\e[M` (X10), `\e[<` (SGR / DEC-locator),
    # `\e[I`/`\e[O` (focus in/out), or numeric `\e[…M` (URxvt). Payload parsed by
    # `Tput::Input#read_mouse` into `Tput::Mouse::Event`.
    Mouse = 16777302

    # Enhanced keyboard sequence: kitty keyboard protocol event (`CSI … u`), xterm
    # `modifyOtherKeys` report (`CSI 27 ; … ~`), or a legacy-final key with a kitty
    # event-type sub-parameter (`CSI 1 ; 5 : 3 A`). Re-parsed by
    # `Tput::Input#parse_key_event` into `Tput::KeyEvent`.
    Enhanced = 16777303

    # Bracketed paste (DEC private mode 2004): `\e[200~` begins, `\e[201~` ends.
    # On `PasteStart`, `Tput::Input#listen` reads the body via `#read_paste` up to
    # `PasteEnd` and delivers it as the `paste` argument.
    PasteStart = 16777304
    PasteEnd   = 16777305

    # In-band terminal resize report (DEC private mode 2048),
    # `\e[48;rows;cols;ypixels;xpixels t`. Parsed by `Tput::Input#parse_resize`
    # into `Tput::Resize`, delivered as `#listen`'s `resize` argument.
    Resize = 16777306

    # OSC reply (`\e]…`); `Tput::Input#listen` reads and dispatches the payload
    # (e.g. OSC 52 clipboard reply -> `paste`).
    Osc = 16777307

    # Color-scheme report (DEC private mode 2031), `\e[?997;Ps n`
    # (`Ps` 1 = dark, 2 = light). Parsed into `Tput::ColorScheme`, delivered as
    # `#listen`'s `color_scheme` argument.
    ColorScheme = 16777308

    Unknown = 33554431

    # Reads a `Control` input from *char*. If an escape sequence was detected,
    # calls the given block for the next `Char?`.
    def self.read_control(char : Char, &) : Key?
      case o = char.ord
      when Key::Escape.value
        read_escape_sequence(char) { yield } || Key::Escape
      else
        # Restrict to 7-bit C0/DEL so a C1 control (U+0080/U+0081, arriving as
        # UTF-8 `0xC2 0x80`) isn't mistaken for auto-numbered `AltEnter` (128) /
        # `ShiftTab` (129).
        Key.from_value?(o) if o < 0x80
      end # || Key::Unknown
    end

    # Dispatches on the byte after `ESC`: `O` (SS3), `[` (CSI, delegating numeric
    # parameter lists to `#read_numeric_csi`), or a letter (Alt+letter). Modified
    # function keys (e.g. Shift+F5) report the base F-key; no modified-F-key
    # members exist.
    private def self.read_escape_sequence(char, &)
      o = yield.try(&.ord) || -1
      # A run of extra `ESC`s (Alt+Esc, or Alt-prefixed sequences that
      # meta-send-escape as `\e\e[A`): treat the *last* ESC as the real
      # introducer and dispatch on the byte that follows it, rather than
      # swallowing the whole sequence. A bare `\e\e` exhausts input here
      # (`o == -1`) and falls through to `Key::Escape` via `read_control`; the
      # phantom-escape suppression in `Input#listen` exempts that `\e\e` shape
      # so one Escape is still delivered. (An iterative loop, not recursion:
      # a block-yielding method that called itself couldn't be inlined.)
      while o == 27
        o = yield.try(&.ord) || -1
      end
      case o
      when 13 then Key::AltEnter
      when 93 then Key::Osc # `\e]…` OSC reply (e.g. OSC 52 clipboard)
      when 79               # SS3: `\eO…` — application-mode cursor / F1-F4 keys
        case yield.try(&.ord)
        when 65 then Key::Up
        when 66 then Key::Down
        when 67 then Key::Right
        when 68 then Key::Left
          # SS3-encoded Home/End from DECCKM application cursor keys mode (enabled
          # by this library). Without these, `\eOH`/`\eOF` fall through to `nil`
          # and the leading `\e` reads as a bare Escape.
        when 72 then Key::Home
        when 70 then Key::End
        when 69 then Key::Clear
        when 80 then Key::F1
        when 81 then Key::F2
        when 82 then Key::F3
        when 83 then Key::F4
          # rxvt ctrl+cursor: `\eOa`-`\eOe` (lowercase)
        when  97 then Key::CtrlUp
        when  98 then Key::CtrlDown
        when  99 then Key::CtrlRight
        when 100 then Key::CtrlLeft
        when 101 then Key::Clear
        else
          nil
        end
      when 91 # CSI: `\e[…` — cursor/function keys and mouse reports
        o = yield.try(&.ord) || -1
        case o
        when 77 then Key::Mouse # `\e[M` -> X10 mouse report (binary payload follows)
        when 73 then Key::Mouse # `\e[I` -> focus-in report
        when 79 then Key::Mouse # `\e[O` -> focus-out report
        when 60 then Key::Mouse # `\e[<` -> SGR / DEC-locator mouse report
        when 65 then Key::Up
        when 66 then Key::Down
        when 67 then Key::Right
        when 68 then Key::Left
        when 69 then Key::Clear
        when 70 then Key::End
        when 72 then Key::Home
        when 90 then Key::ShiftTab
          # rxvt shift+cursor: `\e[a`-`\e[e` (lowercase)
        when 97  then Key::ShiftUp
        when 98  then Key::ShiftDown
        when 99  then Key::ShiftRight
        when 100 then Key::ShiftLeft
        when 101 then Key::Clear
        when 91  then read_bracket_csi { yield } # `\e[[…` putty / Cygwin function keys
        when 63  then read_private_csi { yield } # `\e[?…` private report (color scheme 997)
        when 62  then read_gt_csi { yield }      # `\e[>…` secondary-DA-style reply (DA2)
        when 48..57
          # Numeric CSI parameter list: navigation/function key (`\e[3~`,
          # `\e[1;5C`, …) or URxvt mouse report (`\e[ Cb ; Cx ; Cy M`).
          read_numeric_csi(o - 48) { yield }
        else
          nil
        end
      when 97..122
        # Alt+<letter>: ESC followed by `a`-`z`. `AltA`..`AltZ` are contiguous and
        # alphabetical, matching bytes 97..122 (same invariant `KeyEvent#u_key`
        # relies on).
        Key.from_value? Key::AltA.value + (o - 97)
      else
        nil
      end
    end

    # Reads a numeric CSI parameter list (`\e[ … <final>`) whose first digit
    # value is *first*, then classifies it as a key or a URxvt mouse report.
    # Yields for each subsequent input char.
    private def self.read_numeric_csi(first : Int32, &) : Key?
      # `classify_csi` only consults the first two parameters, so capture just
      # those (`p0`/`p1`) instead of allocating an `Array` per key. A `:`
      # sub-parameter is flattened like `;` (exact grouping recovered from raw
      # bytes by `Input#parse_key_event`); `colon` records one was present so
      # `classify_csi` can detect an enhanced event even on a legacy final byte
      # (e.g. an event-type on `…A`).
      p0 : Int32? = nil
      p1 : Int32? = nil
      count = 0
      cur = first
      final = nil
      colon = false
      locator = false # `&` intermediate seen -> DEC-locator report
      loop do
        o = yield.try(&.ord)
        break unless o
        if 48 <= o <= 57 # digit
          cur = cur * 10 + (o - 48)
          next
        end
        # A separator or the final byte closes the current parameter.
        case count
        when 0 then p0 = cur
        when 1 then p1 = cur
        end
        count += 1
        cur = 0
        case o
        when 58 then colon = true # ':' kitty sub-parameter (enhanced marker)
        when 59                   # ';' parameter separator: nothing extra
        when 32..47
          # CSI intermediate byte (0x20-0x2F).
          #
          # `&` (0x26) always introduces a DEC-locator report
          # (`CSI Pe [; Cx ; Cy ; Cp] & w`) — rxvt's modified-nav finals use `$`
          # and `^`, never `&` — so keep scanning for the trailing `w` regardless
          # of parameter count. The "locator unavailable/outside" report is the
          # single-parameter `CSI Pe & w` (e.g. `\e[0&w`); treating `&` as final
          # would leave `w` unread and leak it as a phantom keystroke.
          #
          # Other intermediates are kept only in a multi-parameter sequence —
          # e.g. the `$` of a non-private DECRPM reply `CSI Ps ; Pm $ y` (answer
          # to `#request_ansi_mode`/`decrqm`), where mistaking `$` for final would
          # leak `y` and mis-decode as an rxvt ShiftXXX nav key. (Private form
          # `\e[?…$y` is handled in `read_private_csi`.) A single-parameter `$` is
          # rxvt's shift-modified navigation terminator (`\e[3$` = Shift+Delete),
          # which legitimately ends the sequence (`count` still 1), so fall
          # through to the final.
          if o == '&'.ord
            locator = true
          elsif count >= 2
            # genuine multi-parameter intermediate (e.g. DECRPM `$`): keep scanning
          else
            final = o
            break
          end
        else
          final = o
          break
        end
      end
      return nil unless final
      # `& w`-terminated multi-parameter report is a DEC-locator event; hand to
      # `Input#read_mouse`, which re-parses via `Mouse.parse_dec`. Real
      # DEC-locator reports carry no `<` introducer, so this numeric path (not
      # SGR `\e[<`) is how they arrive.
      return Key::Mouse if locator && final == 'w'.ord
      classify_csi p0, p1, final, colon
    end

    # Reads a `\e[?… <final>` private report. Recognizes the color-scheme report
    # (`\e[?997;Ps n`, DEC mode 2031); other private reports are ignored.
    private def self.read_private_csi(&) : Key?
      # Only the first parameter (`997` color-scheme marker) is consulted, so
      # capture it into a local instead of allocating an `Array` per report.
      p0 : Int32? = nil
      cur = 0
      final = nil
      loop do
        o = yield.try(&.ord)
        break unless o
        case o
        when 48..57 then cur = cur * 10 + (o - 48)
        when 59     then p0 = cur if p0.nil?; cur = 0
        when 32..47
          # CSI intermediate byte (0x20-0x2F), e.g. the `$` in a DECRPM reply
          # `\e[? Ps ; Pm $ y`. Not the final byte; keep scanning, or the real
          # final (`y`) leaks out of `#listen` as a phantom keystroke.
        else p0 = cur if p0.nil?; final = o; break
        end
      end
      return nil unless final
      return Key::ColorScheme if final == 'n'.ord && p0 == 997
      nil
    end

    # Reads and discards a `\e[>… <final>` report: the secondary device-attributes
    # reply (`\e[> Pp ; Pv ; Pc c`) and similar `>`-parameterized replies, none of
    # which map to a key. Must consume the whole sequence through the final byte
    # (`0x40`-`0x7E`), or a reply arriving mid-`#listen` leaks its parameter list
    # and final byte as phantom keystrokes. Always returns `nil`.
    private def self.read_gt_csi(&) : Key?
      loop do
        o = yield.try(&.ord)
        break unless o
        # Parameter bytes (`0x30`-`0x3F`: digits, `;`, `:`) and CSI intermediates
        # (`0x20`-`0x2F`) continue the sequence; the first byte outside that
        # range is the final byte (consumed here) — or a stray that also ends it.
        break unless 0x20 <= o <= 0x3F
      end
      nil
    end

    # Reads the tail of a `\e[[…` sequence (putty / Cygwin function keys).
    private def self.read_bracket_csi(&) : Key?
      case o = yield.try(&.ord) || -1
      when 65 then Key::F1 # `\e[[A`  (Cygwin)
      when 66 then Key::F2 # `\e[[B`
      when 67 then Key::F3 # `\e[[C`
      when 68 then Key::F4 # `\e[[D`
      when 69 then Key::F5 # `\e[[E`
      when 48..57
        read_numeric_csi(o - 48) { yield } # `\e[[5~`/`\e[[6~`  (putty)
      else
        nil
      end
    end

    # Maps a parsed CSI (`params`, `final` byte) to a key. `M`/`m` finals are a
    # URxvt mouse report (handled by `Tput::Input`), surfaced here as
    # `Key::Mouse`. `$`/`^` finals are rxvt shift/ctrl-modified navigation keys.
    private def self.classify_csi(p0 : Int32?, p1 : Int32?, final : Int32, enhanced = false) : Key?
      # Enhanced keyboard sequences: `u` final (kitty / modifyOtherKeys-1), a
      # legacy final with a kitty event-type sub-parameter, or the
      # modifyOtherKeys format-0 marker (first parameter 27 on a `~` final).
      # Whole sequence re-parsed into a `KeyEvent` by `Input#parse_key_event`.
      return Key::Enhanced if final == 'u'.ord
      return Key::Enhanced if enhanced
      if final == '~'.ord
        case p0
        when 27 then return Key::Enhanced    # modifyOtherKeys format 0
        when 200 then return Key::PasteStart # bracketed paste begin
        when 201 then return Key::PasteEnd   # bracketed paste end
        end
      end
      # In-band resize report (DEC private mode 2048): `\e[48; … t`.
      return Key::Resize if final == 't'.ord && p0 == 48

      case final
      when 'M'.ord, 'm'.ord then Key::Mouse # URxvt mouse report
      when '~'.ord          then csi_tilde_key p0, p1
      when '$'.ord          then csi_tilde_key p0, 2 # rxvt shift+nav
      when '^'.ord          then csi_tilde_key p0, 5 # rxvt ctrl+nav
      when 'A'.ord, 'B'.ord, 'C'.ord, 'D'.ord, 'F'.ord, 'H'.ord
        csi_letter_key final, p1
        # Modified F1-F4 (modern xterm): `CSI 1 ; mod P/Q/R/S`. Unmodified F1-F4
        # arrive as SS3 (`\eOP`-`\eOS`); the CSI form only appears with a
        # modifier, so `p0 == 1` guards against a `CSI row;col R` (CPR) reply
        # being misread as F3. No distinct modified-F-key members exist, so the
        # held modifier is ignored (matching `#function_key`).
      when 'P'.ord then Key::F1 if p0 == 1
      when 'Q'.ord then Key::F2 if p0 == 1
      when 'R'.ord then Key::F3 if p0 == 1
      when 'S'.ord then Key::F4 if p0 == 1
      else
        nil
      end
    end

    # `\e[ N [;mod] ~` navigation/function keys, with optional modifier
    # (2 = shift, 3 = alt, 5 = ctrl). Modifiers apply to the navigation keys;
    # function keys ignore them (no distinct modified-F-key members exist).
    private def self.csi_tilde_key(n : Int32?, mod : Int32?) : Key?
      if keys = csi_tilde_keys n
        csi_modified mod, *keys
      else
        function_key n # F1-F20 / Menu (no distinct modified members)
      end
    end

    # The four legacy navigation members (base / shift / alt / ctrl) for a
    # `\e[ N ~` parameter, or `nil` for function keys (no distinct modified
    # members — see `#function_key`).
    #
    # Shared by legacy `#csi_tilde_key` and enhanced-keyboard projection
    # `KeyEvent#tilde_key` (like `#function_key`) so both routes agree on the
    # navigation-key mapping; each applies its own modifier scheme
    # (`#csi_modified` vs `KeyEvent#nav`).
    def self.csi_tilde_keys(n : Int32?) : Tuple(Key, Key, Key, Key)?
      case n
      when 1, 7 then {Key::Home, Key::ShiftHome, Key::AltHome, Key::CtrlHome}
      when 2    then {Key::Insert, Key::ShiftInsert, Key::AltInsert, Key::CtrlInsert}
      when 3    then {Key::Delete, Key::ShiftDelete, Key::AltDelete, Key::CtrlDelete}
      when 4, 8 then {Key::End, Key::ShiftEnd, Key::AltEnd, Key::CtrlEnd}
      when 5    then {Key::PageUp, Key::ShiftPageUp, Key::AltPageUp, Key::CtrlPageUp}
      when 6    then {Key::PageDown, Key::ShiftPageDown, Key::AltPageDown, Key::CtrlPageDown}
      else           nil
      end
    end

    # Maps a `\e[ N ~` parameter for function keys F1-F20 / Menu. No distinct
    # *modified* enum members exist, so any held modifier is ignored (matching
    # the legacy parser). `nil` for any non-function-key `n`.
    #
    # Shared by legacy `#csi_tilde_key` and enhanced-keyboard projection
    # `KeyEvent#tilde_key`, so both routes agree on function-key numbering.
    def self.function_key(n : Int32?) : Key?
      case n
      when 11 then Key::F1 # rxvt
      when 12 then Key::F2 # rxvt
      when 13 then Key::F3 # rxvt
      when 14 then Key::F4 # rxvt
      when 15 then Key::F5
      when 17 then Key::F6
      when 18 then Key::F7
      when 19 then Key::F8
      when 20 then Key::F9
      when 21 then Key::F10
      when 23 then Key::F11
      when 24 then Key::F12
      when 25 then Key::F13
      when 26 then Key::F14
      when 28 then Key::F15
      when 29 then Key::Menu # `\e[29~` is Menu on modern xterm (historically F16)
      when 31 then Key::F17
      when 32 then Key::F18
      when 33 then Key::F19
      when 34 then Key::F20
      else         nil
      end
    end

    # `\e[ [1;mod] <letter>` cursor / Home / End keys, with optional modifier
    # (2 = shift, 3 = alt, 5 = ctrl).
    private def self.csi_letter_key(final : Int32, mod : Int32?) : Key?
      if keys = csi_letter_keys final.chr
        csi_modified mod, *keys
      end
    end

    # The four legacy cursor/Home/End members (base / shift / alt / ctrl) for a
    # `\e[ … <letter>` final, or `nil` for any other letter.
    #
    # Shared by legacy `#csi_letter_key` and enhanced-keyboard projection
    # `KeyEvent#to_legacy_key` (like `#csi_tilde_keys`), so both routes agree on
    # the cursor-key mapping; each applies its own modifier scheme.
    def self.csi_letter_keys(final : Char) : Tuple(Key, Key, Key, Key)?
      case final
      when 'A' then {Key::Up, Key::ShiftUp, Key::AltUp, Key::CtrlUp}
      when 'B' then {Key::Down, Key::ShiftDown, Key::AltDown, Key::CtrlDown}
      when 'C' then {Key::Right, Key::ShiftRight, Key::AltRight, Key::CtrlRight}
      when 'D' then {Key::Left, Key::ShiftLeft, Key::AltLeft, Key::CtrlLeft}
      when 'H' then {Key::Home, Key::ShiftHome, Key::AltHome, Key::CtrlHome}
      when 'F' then {Key::End, Key::ShiftEnd, Key::AltEnd, Key::CtrlEnd}
      else          nil
      end
    end

    private def self.csi_modified(mod : Int32?, base : Key, shift : Key, alt : Key, ctrl : Key) : Key
      # On-the-wire modifier parameter is `1 + bitmask`; recover it as `Modifiers`
      # (masked to the 8 defined bits) and let `#pick_nav` strip lock bits and
      # choose the variant, same logic as the enhanced projection (`KeyEvent#nav`).
      m = mod ? Modifiers.from_value((mod - 1) & 0xFF) : Modifiers::None
      m.pick_nav base, shift, alt, ctrl
    end
  end
end
