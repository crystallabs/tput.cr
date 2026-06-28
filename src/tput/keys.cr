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

    # Sentinel returned by `read_control` when a mouse-reporting introducer is
    # detected: `\e[M` (X10), `\e[<` (SGR / DEC-locator), `\e[I`/`\e[O` (focus
    # in/out), or a numeric `\e[…M` (URxvt). The payload is parsed by
    # `Tput::Input#read_mouse` into a `Tput::Mouse::Event`.
    Mouse = 16777302

    # Sentinel returned when an *enhanced* keyboard sequence is detected: a
    # kitty keyboard protocol event (`CSI … u`), an xterm `modifyOtherKeys`
    # report (`CSI 27 ; … ~`), or a legacy-final key carrying a kitty event-type
    # sub-parameter (`CSI 1 ; 5 : 3 A`). The full sequence is re-parsed by
    # `Tput::Input#parse_key_event` into a `Tput::KeyEvent`.
    Enhanced = 16777303

    # Sentinels for bracketed paste (DEC private mode 2004): `\e[200~` begins a
    # paste and `\e[201~` ends it. On `PasteStart`, `Tput::Input#listen` reads
    # the body verbatim (via `#read_paste`) up to the `PasteEnd` marker and
    # delivers it as the `paste` argument.
    PasteStart = 16777304
    PasteEnd   = 16777305

    # Sentinel for an in-band terminal resize report (DEC private mode 2048),
    # `\e[48;rows;cols;ypixels;xpixels t`. Parsed by `Tput::Input#parse_resize`
    # into a `Tput::Resize` and delivered as the `resize` argument of `#listen`.
    Resize = 16777306

    # Sentinel for an OSC reply (`\e]…`); `Tput::Input#listen` reads the payload
    # and dispatches it (e.g. an OSC 52 clipboard reply → `paste`).
    Osc = 16777307

    # Sentinel for a color-scheme report (DEC private mode 2031),
    # `\e[?997;Ps n` (`Ps` 1 = dark, 2 = light). Parsed into a `Tput::ColorScheme`
    # and delivered as the `color_scheme` argument of `#listen`.
    ColorScheme = 16777308

    Unknown = 33554431

    # Reads a `Control` input from *char*.  If an escape sequence was detected,
    # calls the given block for the next `Char?`.
    def self.read_control(char : Char, &) : Key?
      case o = char.ord
      when Key::Escape.value
        read_escape_sequence(char) { yield } || Key::Escape
      else
        # Only the 7-bit C0 controls (and DEL) map to a legacy key by codepoint.
        # Restrict the lookup to that range so a C1 control (U+0080/U+0081,
        # arriving e.g. as UTF-8 `0xC2 0x80`) is not mistaken for the
        # auto-numbered `AltEnter` (128) / `ShiftTab` (129) enum members.
        Key.from_value?(o) if o < 0x80
      end # || Key::Unknown
    end

    # Reads further chars while determining the key that was pressed.
    #
    # Dispatches on the byte after `ESC`: `O` (SS3), `[` (CSI — which delegates
    # numeric parameter lists to `#read_numeric_csi`), or a letter (Alt+letter).
    # Modified function keys (e.g. Shift+F5) currently report the base F-key, as
    # there are no distinct modified-F-key members.
    private def self.read_escape_sequence(char, &)
      case o = yield.try(&.ord) || -1
      when 13 then Key::AltEnter
        # when 27 then Key::Escape
      when 93 then Key::Osc # `\e]…` OSC reply (e.g. OSC 52 clipboard)
      when 79               # SS3: `\eO…` — application-mode cursor / F1-F4 keys
        case yield.try(&.ord)
        when 65 then Key::Up
        when 66 then Key::Down
        when 67 then Key::Right
        when 68 then Key::Left
          # SS3-encoded Home/End, sent by terminals in application cursor keys
          # mode (DECCKM, which this library enables). Without these, `\eOH`/`\eOF`
          # fall through to `nil` and the leading `\e` is read as a bare Escape.
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
          # A numeric CSI parameter list: a navigation/function key (`\e[3~`,
          # `\e[1;5C`, …) or a URxvt mouse report (`\e[ Cb ; Cx ; Cy M`).
          read_numeric_csi(o - 48) { yield }
        else
          nil
        end
      when 97..122
        # Alt+<letter>: ESC followed by `a`-`z`. The `AltA`..`AltZ` enum members
        # are contiguous and alphabetical, matching bytes 97..122 (the same
        # invariant `KeyEvent#u_key` relies on).
        Key.from_value? Key::AltA.value + (o - 97)
      else
        nil
      end
    end

    # Reads a numeric CSI parameter list (`\e[ … <final>`) whose first digit
    # value is *first*, then classifies it as a key or a URxvt mouse report.
    # Yields for each subsequent input char.
    private def self.read_numeric_csi(first : Int32, &) : Key?
      # `classify_csi` only ever consults the first two parameters, so capture
      # just those (`p0`/`p1`) into locals instead of allocating an `Array` per
      # key. A `:` sub-parameter is flattened the same as `;` (the precise
      # grouping is recovered from the raw bytes by `Input#parse_key_event`);
      # `colon` records that one was present so `classify_csi` can tell this is
      # an enhanced event even on a legacy final byte (e.g. an event-type on
      # `…A`).
      p0 : Int32? = nil
      p1 : Int32? = nil
      count = 0
      cur = first
      final = nil
      colon = false
      locator = false # an `&` intermediate was seen -> DEC-locator report
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
          # A CSI *intermediate* byte (0x20-0x2F). In a multi-parameter
          # sequence it is a genuine intermediate — e.g. the `$` of a
          # *non-private* DECRPM reply `CSI Ps ; Pm $ y` (the answer to
          # `#request_ansi_mode`/`decrqm`) — so keep scanning for the real final
          # (`y`). Mistaking `$` for the final would leave `y` unread and leak
          # it as a phantom keystroke (and mis-decode the reply as an rxvt
          # ShiftXXX nav key). The private form `\e[?…$y` is handled separately
          # in `read_private_csi`.
          #
          # A *single*-parameter `$` is instead rxvt's shift-modified
          # navigation terminator (`\e[3$` = Shift+Delete), which legitimately
          # ends the sequence — `count` is still 1 there (only this byte closed
          # a parameter), so fall through and treat it as the final.
          if count >= 2
            # `&` (0x26) is the intermediate of a DEC-locator report
            # (`CSI Cb ; Cx ; Cy ; Cp & w`); record it so the trailing `w` final
            # routes to the mouse parser rather than being dropped.
            locator = true if o == '&'.ord
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
      # A `& w`-terminated multi-parameter report is a DEC-locator event; hand it
      # to `Input#read_mouse`, which re-parses the captured sequence via
      # `Mouse.parse_dec`. (Real DEC-locator reports carry no `<` introducer, so
      # this numeric path — not the SGR `\e[<` path — is how they actually
      # arrive.)
      return Key::Mouse if locator && final == 'w'.ord
      classify_csi p0, p1, final, colon
    end

    # Reads a `\e[?… <final>` private report. Recognizes the color-scheme report
    # (`\e[?997;Ps n`, DEC mode 2031); other private reports are ignored.
    private def self.read_private_csi(&) : Key?
      # Only the first parameter is consulted (the `997` color-scheme marker), so
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
          # A CSI *intermediate* byte (0x20-0x2F), e.g. the `$` in a DECRPM
          # reply `\e[? Ps ; Pm $ y`. It is not the final byte, so keep
          # scanning; otherwise the real final (`y`) is left unread and leaks
          # out of `#listen` as a phantom keystroke.
        else p0 = cur if p0.nil?; final = o; break
        end
      end
      return nil unless final
      return Key::ColorScheme if final == 'n'.ord && p0 == 997
      nil
    end

    # Reads and discards a `\e[>… <final>` report. The `>` prefix introduces the
    # secondary device-attributes reply (`\e[> Pp ; Pv ; Pc c`) and similar
    # `>`-parameterized terminal replies; none map to a key. Like
    # `#read_private_csi` drains `\e[?…` reports, the *whole* sequence — through
    # the final byte (`0x40`-`0x7E`) — must be consumed, otherwise a reply that
    # arrives mid-`#listen` leaks its parameter list and final byte out as a
    # burst of phantom keystrokes. Always returns `nil`.
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
      # Enhanced keyboard sequences: a `u` final (kitty / modifyOtherKeys-1), a
      # legacy final carrying a kitty event-type sub-parameter, or the
      # modifyOtherKeys format-0 marker (first parameter 27 on a `~` final). The
      # whole sequence is re-parsed into a `KeyEvent` by `Input#parse_key_event`.
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
      else
        nil
      end
    end

    # `\e[ N [;mod] ~` navigation/function keys, with optional modifier
    # (2 = shift, 3 = alt, 5 = ctrl). Modifiers apply to the navigation keys;
    # function keys ignore them (no distinct modified-F-key members exist).
    private def self.csi_tilde_key(n : Int32?, mod : Int32?) : Key?
      case n
      when 1, 7 then csi_modified mod, Key::Home, Key::ShiftHome, Key::AltHome, Key::CtrlHome
      when 2    then csi_modified mod, Key::Insert, Key::ShiftInsert, Key::AltInsert, Key::CtrlInsert
      when 3    then csi_modified mod, Key::Delete, Key::ShiftDelete, Key::AltDelete, Key::CtrlDelete
      when 4, 8 then csi_modified mod, Key::End, Key::ShiftEnd, Key::AltEnd, Key::CtrlEnd
      when 5    then csi_modified mod, Key::PageUp, Key::ShiftPageUp, Key::AltPageUp, Key::CtrlPageUp
      when 6    then csi_modified mod, Key::PageDown, Key::ShiftPageDown, Key::AltPageDown, Key::CtrlPageDown
      else           function_key n # F1-F20 / Menu (no distinct modified members)
      end
    end

    # Maps a `\e[ N ~` parameter for the function keys F1-F20 / Menu. These have
    # no distinct *modified* enum members, so any held modifier is intentionally
    # ignored (matching the legacy parser). `nil` for any non-function-key `n`.
    #
    # Shared by the legacy `#csi_tilde_key` and the enhanced-keyboard projection
    # `KeyEvent#tilde_key`, so both routes agree on the function-key numbering.
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
      case final
      when 'F'.ord then csi_modified mod, Key::End, Key::ShiftEnd, Key::AltEnd, Key::CtrlEnd
      when 'H'.ord then csi_modified mod, Key::Home, Key::ShiftHome, Key::AltHome, Key::CtrlHome
      when 'A'.ord then csi_modified mod, Key::Up, Key::ShiftUp, Key::AltUp, Key::CtrlUp
      when 'B'.ord then csi_modified mod, Key::Down, Key::ShiftDown, Key::AltDown, Key::CtrlDown
      when 'C'.ord then csi_modified mod, Key::Right, Key::ShiftRight, Key::AltRight, Key::CtrlRight
      when 'D'.ord then csi_modified mod, Key::Left, Key::ShiftLeft, Key::AltLeft, Key::CtrlLeft
      else              nil
      end
    end

    private def self.csi_modified(mod : Int32?, base : Key, shift : Key, alt : Key, ctrl : Key) : Key
      # The on-the-wire modifier parameter is `1 + bitmask`. Strip the lock bits
      # (CapsLock = 64, NumLock = 128) before matching: terminals speaking the
      # kitty scheme fold the active lock state into this field, and NumLock in
      # particular is commonly on — which would otherwise degrade every modified
      # navigation key (Ctrl+Up, Shift+Home, …) to its unmodified base.
      m = mod ? ((mod - 1) & ~(64 | 128)) + 1 : nil
      case m
      when 2 then shift
      when 3 then alt
      when 5 then ctrl
      else        base
      end
    end
  end
end
