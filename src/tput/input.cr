class Tput
  # An in-band terminal resize report (DEC private mode 2048): the new size in
  # character cells, plus the window size in pixels when the terminal provides
  # it (`0` when unknown).
  record Resize,
    rows : Int32,
    cols : Int32,
    pixel_height : Int32,
    pixel_width : Int32

  # The terminal's light/dark color scheme, as reported by DEC mode 2031
  # notifications or `#request_color_scheme`.
  enum ColorScheme
    Dark
    Light
  end

  # One unit of terminal input, as yielded by `Tput::Input#listen`. Exactly one
  # *kind* is meaningful per event — a mouse report, a paste, an in-band resize,
  # or a key transition — told apart with the predicates below; the remaining
  # fields are `nil`.
  #
  #   * `char` / `key` / `sequence` — the key transition (and the raw bytes).
  #   * `mouse`       — a parsed mouse/focus report (`#mouse?`).
  #   * `paste`       — bracketed-paste body (`#paste?`).
  #   * `resize`      — in-band resize report (`#resize?`).
  #   * `key_event`   — the rich keyboard event, when an enhanced protocol is
  #                     active (carries modifiers, press/repeat/release, …).
  struct InputEvent
    getter char : Char
    getter key : Key?
    getter mouse : Mouse::Event?
    getter key_event : KeyEvent?
    getter paste : String?
    getter resize : Resize?
    getter color_scheme : ColorScheme?

    def initialize(@char, @key = nil, @sequence : Array(Char)? = nil, @mouse = nil,
                   @key_event = nil, @paste = nil, @resize = nil, @color_scheme = nil)
    end

    # The raw input bytes for this event. A single-character event (the common
    # typing path) carries no array — `#listen` passes `nil` and the lone byte
    # is reconstructed here on demand, so plain typing allocates nothing unless
    # a consumer actually reads the sequence. Multi-byte sequences (escape
    # sequences, mouse/paste reports) carry their captured bytes verbatim.
    def sequence : Array(Char)
      @sequence || [@char]
    end

    # Whether this event is a mouse/focus report.
    def mouse? : Bool
      !@mouse.nil?
    end

    # Whether this event is a bracketed paste.
    def paste? : Bool
      !@paste.nil?
    end

    # Whether this event is an in-band resize report.
    def resize? : Bool
      !@resize.nil?
    end

    # Whether this event is a color-scheme (light/dark) change report.
    def color_scheme? : Bool
      !@color_scheme.nil?
    end

    # Whether this event is a key transition (not mouse/paste/resize/scheme).
    def key_transition? : Bool
      @mouse.nil? && @paste.nil? && @resize.nil? && @color_scheme.nil?
    end

    # Whether this is a key *release* (only when enhanced event reporting is on).
    def release? : Bool
      !!@key_event.try(&.release?)
    end

    # Whether this is an auto-repeat key event.
    def repeat? : Bool
      !!@key_event.try(&.repeat?)
    end
  end

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

    # Runs *block* with the input's read timeout set to `@read_timeout` for the
    # duration (and cleared again afterwards) when *timeout* is requested and the
    # input supports it. Shared by `#next_char`/`#next_byte`, whose only real
    # difference is the read call (`read_char` vs `read_byte`) wrapped here.
    private def with_read_timeout(timeout : Bool, &)
      input = @input

      if timeout && input.responds_to? :"read_timeout="
        input.read_timeout = @read_timeout
      end

      result = yield

      if timeout && input.responds_to? :"read_timeout="
        input.read_timeout = nil
      end

      result
    end

    def next_char(timeout : Bool = false, &)
      c = with_read_timeout(timeout) do
        begin
          @input.read_char
        rescue IO::TimeoutError
          nil
        end
      end

      if c
        yield << c
      end

      c
    end

    # Reads one raw 8-bit byte (`0..255`), or `nil` on EOF/timeout. Mirrors
    # `#next_char`'s optional read timeout but bypasses UTF-8 decoding — needed
    # for the X10 mouse encoding, whose payload bytes are raw values that may
    # exceed `0x7F` (a coordinate past column/row 95) and would be corrupted by
    # `read_char`.
    private def next_byte(timeout : Bool = false) : Int32?
      b = with_read_timeout(timeout) do
        begin
          @input.read_byte
        rescue IO::TimeoutError
          nil
        end
      end

      b.try &.to_i
    end

    def listen(& : InputEvent -> Nil)
      with_raw_input do
        sequence = [] of Char
        while char = next_char { sequence }
          key = nil
          mouse = nil
          key_event = nil
          paste = nil
          resize = nil
          color_scheme = nil
          if char.control?
            key = Key.read_control(char) { next_char(true) { sequence } }

            case key
            when Key::Mouse
              # A mouse report introducer was detected; parse the rest now. The
              # encoding is told apart by the char after `\e[` (see
              # `#read_mouse`): `M` X10, `<` SGR/DEC-locator, `I`/`O` focus, a
              # digit URxvt. On success the report is delivered as a
              # `Mouse::Event` and is no longer treated as a key.
              mouse = read_mouse(sequence) { next_char(true) { sequence } }
              key = nil
            when Key::Enhanced
              # An enhanced keyboard sequence (kitty protocol / modifyOtherKeys).
              # Re-parse the bytes already captured in `sequence` into a rich
              # `KeyEvent`, then project it back onto the legacy channels so
              # existing consumers keep working: a printable press still arrives
              # as `char`, and a recognizable key still maps to a `Key`. A
              # release/repeat leaves `key` clear (so it isn't mistaken for a
              # press); `char` keeps its escape-introducer value in that case,
              # matching how legacy escape-sequence keys already behave.
              key_event = parse_key_event sequence
              if ev = key_event
                key = ev.to_legacy_key
                if c = ev.char
                  char = c
                end
              else
                key = nil
              end
            when Key::PasteStart
              # Bracketed paste (DEC 2004): read the body verbatim up to the
              # `\e[201~` terminator and deliver it as `paste`, so it is never
              # interpreted as key input.
              paste = read_paste { next_char(true) { sequence } }
              key = nil
            when Key::PasteEnd
              key = nil # stray end-marker with no matching start; ignore
            when Key::Resize
              # In-band resize report (DEC 2048): parse the new size from the
              # captured sequence.
              resize = parse_resize sequence
              key = nil
            when Key::ColorScheme
              # Color-scheme report (DEC 2031): `\e[?997;Ps n`.
              color_scheme = parse_color_scheme sequence
              key = nil
            when Key::Osc
              # OSC reply (`\e]…`). The OSC 52 clipboard reply is surfaced as a
              # paste, so a programmatic clipboard read flows through the same
              # channel as a bracketed paste.
              paste = read_osc_clipboard { next_char(true) { sequence } }
              key = nil
            end
          end

          # An escape sequence that was consumed but produced nothing to deliver
          # must NOT surface as a phantom Escape key. Two shapes:
          #   * a parsed-away/malformed mouse/paste/resize/scheme report, or a
          #     non-clipboard OSC reply — `key` was cleared to `nil`; or
          #   * an *unrecognized* sequence (e.g. a stray `\e[?…c` DA1/DSR reply
          #     arriving mid-`listen`) that `read_control` collapsed to
          #     `Key::Escape` — distinguishable from a real bare Escape because it
          #     consumed bytes (`sequence.size > 1`; a bare Escape consumes none).
          # A real bare Escape (`key == Key::Escape`, `sequence == ['\e']`) and
          # any printable key (`char != '\e'`) are kept.
          if char == '\e' && mouse.nil? && key_event.nil? &&
             paste.nil? && resize.nil? && color_scheme.nil? &&
             (key.nil? || (key == Key::Escape && sequence.size > 1))
            sequence.clear
            next
          end

          # A single-char event is the common typing path: `char == sequence[0]`,
          # so hand the event no array and let it reconstruct `[char]` lazily
          # (most consumers never read `sequence`). Multi-byte sequences are
          # dup'd, since the live buffer is cleared and reused below.
          seq = sequence.size == 1 ? nil : sequence.dup
          yield InputEvent.new char, key, seq, mouse, key_event, paste, resize, color_scheme
          sequence.clear
        end
      end
    end

    # Reads the body of a bracketed paste (`\e[200~ … \e[201~`) verbatim, up to
    # but not including the `\e[201~` terminator, which is consumed. The body may
    # contain any bytes (newlines, escape sequences, control chars); it is *not*
    # interpreted. Yields for each input char.
    private def read_paste(&) : String
      term = "\e[201~"
      body = String::Builder.new
      matched = 0
      loop do
        c = yield
        unless c
          # Stream ended mid-paste: a partially-matched terminator prefix was
          # actually paste content, so flush it before returning.
          body << term[0, matched] if matched > 0
          break
        end
        if c == term[matched]
          matched += 1
          break if matched == term.size # full terminator consumed
        else
          # Mismatch: the partial match was literal paste content. Flush it,
          # then re-test the current char as a possible fresh start. (The
          # terminator has no repeated prefix, so a single re-test suffices.)
          body << term[0, matched] if matched > 0
          matched = 0
          if c == term[0]
            matched = 1
          else
            body << c
          end
        end
      end
      body.to_s
    end

    # Parses an in-band resize report (`\e[48;rows;cols;ypixels;xpixels t`),
    # already captured in *sequence*, into a `Resize`. Returns `nil` if the
    # leading parameter is not the resize marker `48`.
    private def parse_resize(sequence : Array(Char)) : Resize?
      nums = csi_param_ints sequence
      return nil unless nums[0]? == 48
      Resize.new (nums[1]? || 0), (nums[2]? || 0), (nums[3]? || 0), (nums[4]? || 0)
    end

    # Parses the `;`-separated decimal parameters of a captured CSI *sequence*
    # (`\e[ … <final>`), ignoring any private marker / intermediates. Shared by
    # the in-band reports (`#parse_resize`, `#parse_color_scheme`).
    private def csi_param_ints(sequence : Array(Char)) : Array(Int32)
      nums = [] of Int32
      cur = 0
      (2...(sequence.size - 1)).each do |i|
        c = sequence[i]
        if '0' <= c <= '9'
          cur = cur * 10 + (c.ord - '0'.ord)
        elsif c == ';'
          nums << cur
          cur = 0
        end
      end
      nums << cur
      nums
    end

    # Parses a color-scheme report (`\e[?997;Ps n`), captured in *sequence*, into
    # a `ColorScheme` (`Ps` 1 = dark, 2 = light); `nil` if unrecognized.
    private def parse_color_scheme(sequence : Array(Char)) : ColorScheme?
      nums = csi_param_ints sequence
      return nil unless nums[0]? == 997
      case nums[1]?
      when 1 then ColorScheme::Dark
      when 2 then ColorScheme::Light
      else        nil
      end
    end

    # Reads an OSC payload up to its terminator (BEL or ST) and, if it is an OSC
    # 52 clipboard reply (`52;<sel>;<base64>`), returns the decoded text;
    # otherwise `nil`. Yields for each input char.
    private def read_osc_clipboard(&) : String?
      body = String::Builder.new
      loop do
        c = yield
        break unless c
        case c
        when '\a' # BEL terminator
          break
        when '\e' # possible ST (ESC \)
          n = yield
          break if n.nil? || n == '\\'
          body << '\e'
          body << n
        else
          body << c
        end
      end
      data = body.to_s
      return nil unless data.starts_with? "52;"
      b64 = data.split(';')[2]? || return nil
      Base64.decode_string b64
    rescue
      nil
    end

    # Enables bracketed paste (DEC private mode 2004). Pasted text then arrives
    # as the `paste` argument of `#listen` instead of as individual key presses.
    # Harmless on terminals that don't support it (they ignore the request).
    def enable_bracketed_paste : Nil
      decset 2004
      @bracketed_paste_enabled = true
    end

    # Disables bracketed paste (DEC private mode 2004).
    def disable_bracketed_paste : Nil
      decrst 2004
      @bracketed_paste_enabled = false
    end

    # Enables in-band resize notifications (DEC private mode 2048). Resize
    # reports then arrive as the `resize` argument of `#listen` (in addition to
    # any `SIGWINCH`). Harmless on terminals that don't support it.
    def enable_in_band_resize : Nil
      decset 2048
      @in_band_resize_enabled = true
    end

    # Disables in-band resize notifications (DEC private mode 2048).
    def disable_in_band_resize : Nil
      decrst 2048
      @in_band_resize_enabled = false
    end

    # Re-parses an enhanced keyboard sequence — already fully captured in
    # *sequence* (`ESC [ … final`) by the lazy key reader — into a `KeyEvent`.
    #
    # The parameter bytes between `[` and the final byte are split into
    # semicolon-separated groups, each of which may carry colon-separated
    # sub-parameters (kitty uses these for `key:shifted:base` and
    # `modifiers:event-type`); empty fields become `nil` (kitty "default").
    # `KeyEvent.from_csi` then interprets the groups according to the final byte.
    private def parse_key_event(sequence : Array(Char)) : KeyEvent?
      return nil if sequence.size < 3
      final = sequence.last

      # `KeyEvent.from_csi` only consults the first three sub-parameters of
      # group 0 (`number : shifted : base`), the first two of group 1
      # (`mods : event`), and the whole of group 2 (associated text). Capture
      # those directly into locals instead of building a nested
      # `Array(Array(Int32?))` per event — under the kitty *report-all-keys*
      # flag this path runs on every keystroke, plain typing included. Group 2
      # (`g2`) is allocated lazily, only when associated text is actually
      # present (rare).
      g0_0 = g0_1 = g0_2 = nil
      g1_0 = g1_1 = nil
      g2 : Array(Int32?)? = nil
      group = 0
      sub = 0
      num : Int32? = nil

      i = 2
      last = sequence.size - 1 # the final byte is excluded from the param scan
      while i <= last
        c = i == last ? ';' : sequence[i] # the final byte closes the last group
        case c
        when '0'..'9'
          num = (num || 0) * 10 + (c.ord - '0'.ord)
        when ':', ';' # sub-parameter / parameter separator
          case group
          when 0
            case sub
            when 0 then g0_0 = num
            when 1 then g0_1 = num
            when 2 then g0_2 = num
            end
          when 1
            case sub
            when 0 then g1_0 = num
            when 1 then g1_1 = num
            end
          when 2
            (g2 ||= [] of Int32?) << num
          end
          num = nil
          if c == ':'
            sub += 1
          else
            group += 1
            sub = 0
          end
        else
          # Ignore anything unexpected (e.g. a private marker).
        end
        i += 1
      end

      KeyEvent.from_csi final, g0_0, g0_1, g0_2, g1_0, g1_1, g2
    end

    # Reads and parses the payload of a mouse report whose introducer has
    # already been consumed into *sequence*. The character right after `\e[`
    # (`sequence[2]`) selects the encoding:
    #
    #   * `M`      — X10 / normal (three raw bytes follow).
    #   * `I`/`O`  — focus-in / focus-out (no payload).
    #   * `<`      — SGR (1006) (the parameter list follows).
    #   * a digit  — URxvt (1015) or DEC-locator (`… & w`); the whole report is
    #                already in *sequence* (the key parser captured it).
    #
    # Returns the parsed `Mouse::Event`, or `nil` if the stream ended or the
    # report was malformed.
    private def read_mouse(sequence, &) : Mouse::Event?
      case sequence[2]? || '\0'
      when 'M'
        # X10 / normal encoding: exactly three raw 8-bit bytes follow. They are
        # read as bytes (not via the UTF-8 `read_char` path) so a coordinate
        # past column/row 95 (byte >= 0x80) survives intact, and recorded in
        # *sequence* verbatim (codepoints 0..255).
        cb = next_byte true
        cx = next_byte true
        cy = next_byte true
        return nil unless cb && cx && cy
        sequence << cb.chr << cx.chr << cy.chr
        Mouse.parse_x10 cb, cx, cy
      when 'I' then Mouse::Event.focus
      when 'O' then Mouse::Event.blur
      when '<' then read_sgr { yield }
      when '0'..'9'
        # A numeric-CSI mouse report, already fully captured in *sequence*: a
        # DEC-locator report ends in `& w`, a URxvt (1015) report in `M`/`m`.
        if sequence[-1]? == 'w'
          read_dec sequence
        else
          read_urxvt sequence
        end
      else nil
      end
    end

    # Reads an SGR (`Cb ; Cx ; Cy M|m`) parameter list following the `\e[<`
    # introducer. Yields for each char.
    #
    # Only three parameters are meaningful (`Cb ; Cx ; Cy`), so they are
    # collected into fixed locals — no per-report `Array` — on the hottest input
    # path (a mouse drag is a burst of these). *idx* counts parameters seen so a
    # final byte can verify there were enough.
    #
    # (DEC-locator reports are *not* `<`-introduced — they are `CSI Cb ; Cx ; Cy
    # ; Cp & w`, reach the numeric-CSI path, and are parsed by `#read_dec`.)
    private def read_sgr(&) : Mouse::Event?
      p0 = p1 = p2 = 0
      idx = 0
      cur = 0
      while c = yield
        case c
        when '0'..'9' then cur = cur * 10 + (c.ord - '0'.ord)
        when ';'
          case idx
          when 0 then p0 = cur
          when 1 then p1 = cur
          end
          idx += 1; cur = 0
        when 'M', 'm'
          p2 = cur if idx == 2
          return nil unless idx >= 2 # Cb ; Cx ; Cy
          return Mouse.parse_sgr p0, p1, p2, c
        else
          return nil
        end
      end
      nil
    end

    # Scans the `;`-separated decimal parameters of a numeric-CSI mouse report
    # already captured in *sequence* (from index 2) into a fixed four-slot
    # buffer. Scanning stops at the first byte in *terminators* — the report's
    # intermediate/final (`&` for DEC-locator, `M`/`m` for URxvt) — or at any
    # other non-digit, non-`;` byte. Returns the buffer paired with the number of
    # parameters seen, so the caller can verify it got enough. The buffer is a
    # `StaticArray` returned by value, keeping this allocation-free on the hot
    # mouse-drag path (where these reports arrive in bursts).
    private def scan_csi_mouse_params(sequence, terminators : String) : Tuple(StaticArray(Int32, 4), Int32)
      params = StaticArray(Int32, 4).new(0)
      idx = 0
      cur = 0
      i = 2
      while i < sequence.size
        c = sequence[i]
        if '0' <= c <= '9'
          cur = cur * 10 + (c.ord - '0'.ord)
        elsif c == ';' || terminators.includes?(c)
          params[idx] = cur if idx < 4
          idx += 1
          cur = 0
          break if c != ';' # a terminator (intermediate/final) closes the report
        else
          break
        end
        i += 1
      end
      {params, idx}
    end

    # Parses a DEC-locator report (`\e[ Cb ; Cx ; Cy ; Cp & w`) already captured
    # in *sequence* (the numeric-CSI key parser consumed the whole report through
    # its `w` final). Terminates on the `&` intermediate and requires all four
    # parameters.
    private def read_dec(sequence) : Mouse::Event?
      params, idx = scan_csi_mouse_params sequence, "&"
      return nil unless idx >= 4 # Cb ; Cx ; Cy ; Cp (the `&` closes Cp -> idx 4)
      Mouse.parse_dec params[0], params[1], params[2], params[3]
    end

    # Parses a URxvt report (`\e[ Cb ; Cx ; Cy M`) already captured in
    # *sequence* (the key parser consumed the whole parameter list). Terminates
    # on the `M`/`m` final and requires three parameters.
    private def read_urxvt(sequence) : Mouse::Event?
      params, idx = scan_csi_mouse_params sequence, "Mm"
      return nil unless idx >= 3 # Cb ; Cx ; Cy
      Mouse.parse_urxvt params[0], params[1], params[2]
    end
  end
end
