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
  # kind is meaningful per event — mouse report, paste, in-band resize, or key
  # transition — told apart with the predicates below; remaining fields are `nil`.
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
    # Decoded text of an OSC 52 clipboard *read* reply (`request_clipboard`).
    # Distinct from `paste`: this is the answer to a programmatic clipboard
    # query, not user-pasted input.
    getter clipboard : String?

    def initialize(@char, @key = nil, @sequence : Array(Char)? = nil, @mouse = nil,
                   @key_event = nil, @paste = nil, @resize = nil, @color_scheme = nil,
                   @clipboard = nil)
    end

    # Raw input bytes for this event. A single-character event carries no array
    # — `#listen` passes `nil` and the byte is reconstructed here on demand, so
    # plain typing allocates nothing unless a consumer reads the sequence.
    def sequence : Array(Char)
      @sequence || [@char]
    end

    # The raw input sequence *as stored* — `nil` for a single-character event
    # (plain typing). Unlike `#sequence`, this never materializes a
    # one-element `[@char]` array, so a consumer that can carry the nilable
    # form through avoids the per-keypress allocation.
    def sequence? : Array(Char)?
      @sequence
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

    # Whether this event is an OSC 52 clipboard *read* reply.
    def clipboard? : Bool
      !@clipboard.nil?
    end

    # Whether this event is a key transition (not mouse/paste/resize/scheme/clipboard).
    def key_transition? : Bool
      @mouse.nil? && @paste.nil? && @resize.nil? && @color_scheme.nil? && @clipboard.nil?
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

    # Yields the input's `fd` and held raw `@mode` when raw mode is in effect on
    # a tty, no-op otherwise. Shared by `#suspend_raw_input`/`#restore_raw_input`.
    private def with_held_raw_mode(&)
      input = @input
      mode = @mode
      if mode && input.responds_to?(:fd) && input.tty?
        yield input.fd, mode
      end
    end

    # Temporarily returns the terminal to the saved (cooked) mode while a raw
    # `#listen` is active — used by `#pause`/`#restore_terminal`.
    private def suspend_raw_input
      with_held_raw_mode do |fd, mode|
        cooked = mode
        LibC.tcsetattr(fd, Termios::LineControl::TCSANOW, pointerof(cooked))
      end
    end

    # Re-applies raw mode after `#suspend_raw_input` — used by the `#resume`
    # continuation.
    private def restore_raw_input
      with_held_raw_mode do |fd, mode|
        raw_from_tc_mode! fd, mode
      end
    end

    # Runs *block* with the input's read timeout set to `@read_timeout` (cleared
    # afterwards) when *timeout* is requested and supported. Shared by
    # `#next_char`/`#next_byte`.
    private def with_read_timeout(timeout : Bool, &)
      input = @input

      if timeout && input.responds_to? :"read_timeout="
        input.read_timeout = @read_timeout
      end

      # Clear the timeout in an `ensure`, mirroring `Probe#probe_read_byte`: an
      # IO error escaping the block would otherwise leave the read timeout set
      # permanently, so every later blocking read would spuriously time out.
      begin
        yield
      ensure
        if timeout && input.responds_to? :"read_timeout="
          input.read_timeout = nil
        end
      end
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

    # Reads one raw 8-bit byte (`0..255`), or `nil` on EOF/timeout. Bypasses
    # UTF-8 decoding — needed for X10 mouse encoding, whose payload bytes may
    # exceed `0x7F` and would be corrupted by `read_char`.
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
          clipboard = nil
          if char.control?
            key = Key.read_control(char) { next_char(true) { sequence } }

            case key
            when Key::Mouse
              # Mouse report introducer detected; parse the rest. Encoding is
              # told apart by the char after `\e[` (see `#read_mouse`): `M` X10,
              # `<` SGR/DEC-locator, `I`/`O` focus, a digit URxvt.
              mouse = read_mouse(sequence) { next_char(true) { sequence } }
              key = nil
            when Key::Enhanced
              # Enhanced keyboard sequence (kitty protocol / modifyOtherKeys).
              # Re-parse into a `KeyEvent`, then project back onto legacy
              # channels: a printable press still arrives as `char`, a
              # recognizable key still maps to `Key`. Release/repeat leaves
              # `key` clear so it isn't mistaken for a press.
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
              # Bracketed paste (DEC 2004): read body verbatim to the `\e[201~`
              # terminator, deliver as `paste` rather than key input.
              paste = read_paste { next_char(true) { sequence } }
              key = nil
            when Key::PasteEnd
              key = nil # stray end-marker with no matching start; ignore
            when Key::Resize
              # In-band resize report (DEC 2048).
              resize = parse_resize sequence
              key = nil
            when Key::ColorScheme
              # Color-scheme report (DEC 2031): `\e[?997;Ps n`.
              color_scheme = parse_color_scheme sequence
              key = nil
            when Key::Osc
              # OSC reply (`\e]…`). OSC 52 clipboard read reply surfaces on its
              # own `clipboard` channel, distinct from a bracketed paste.
              clipboard = read_osc_clipboard { next_char(true) { sequence } }
              key = nil
            end
          end

          # An escape sequence consumed but producing nothing to deliver must NOT
          # surface as a phantom Escape key. Two shapes: a parsed-away/malformed
          # report (`key` cleared to `nil`), or an unrecognized sequence that
          # `read_control` collapsed to `Key::Escape` but which consumed bytes
          # (`sequence.size > 1`, vs. a bare Escape which consumes none). A real
          # bare Escape and any printable key are kept. A terminal `\e\e` (double
          # Escape, e.g. Alt+Esc) is exempted: it legitimately delivers one
          # `Key::Escape` rather than being discarded.
          double_escape = sequence.size == 2 && sequence[1] == '\e'
          if char == '\e' && mouse.nil? && key_event.nil? &&
             paste.nil? && resize.nil? && color_scheme.nil? && clipboard.nil? &&
             (key.nil? || (key == Key::Escape && sequence.size > 1 && !double_escape))
            sequence.clear
            next
          end

          # Single-char event: hand it no array, let it reconstruct `[char]`
          # lazily. Multi-byte sequences are dup'd since the live buffer is
          # cleared and reused below.
          seq = sequence.size == 1 ? nil : sequence.dup
          yield InputEvent.new char, key, seq, mouse, key_event, paste, resize, color_scheme, clipboard
          sequence.clear
        end
      end
    end

    # Reads the body of a bracketed paste (`\e[200~ … \e[201~`) verbatim, up to
    # but not including the terminator (consumed). Body is not interpreted.
    # Yields for each input char.
    private def read_paste(&) : String
      term = "\e[201~"
      body = String::Builder.new
      matched = 0
      loop do
        c = yield
        unless c
          # Stream ended mid-paste: the partial terminator match was actually
          # paste content, flush it.
          body << term[0, matched] if matched > 0
          break
        end
        if c == term[matched]
          matched += 1
          break if matched == term.size # full terminator consumed
        else
          # Mismatch: partial match was literal content. Flush it, then re-test
          # the current char as a possible fresh start (terminator has no
          # repeated prefix, so one re-test suffices).
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
    # (`\e[ … <final>`), ignoring any private marker/intermediates. Shared by
    # `#parse_resize`/`#parse_color_scheme`.
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

    # Reads an OSC payload up to its terminator (BEL or ST); if it's an OSC 52
    # clipboard reply (`52;<sel>;<base64>`), returns the decoded text, else `nil`.
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
    # as the `paste` argument of `#listen` instead of individual key presses.
    # Harmless on unsupporting terminals.
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
    # any `SIGWINCH`). Harmless on unsupporting terminals.
    def enable_in_band_resize : Nil
      decset 2048
      @in_band_resize_enabled = true
    end

    # Disables in-band resize notifications (DEC private mode 2048).
    def disable_in_band_resize : Nil
      decrst 2048
      @in_band_resize_enabled = false
    end

    # Re-parses an enhanced keyboard sequence — already captured in *sequence*
    # (`ESC [ … final`) — into a `KeyEvent`.
    #
    # Parameter bytes between `[` and the final byte are split into
    # semicolon-separated groups, each carrying optional colon-separated
    # sub-parameters (kitty's `key:shifted:base`, `modifiers:event-type`);
    # empty fields become `nil`. `KeyEvent.from_csi` interprets the groups
    # according to the final byte.
    private def parse_key_event(sequence : Array(Char)) : KeyEvent?
      return nil if sequence.size < 3
      final = sequence.last

      # `KeyEvent.from_csi` only consults the first three sub-parameters of
      # group 0 (`number:shifted:base`), first two of group 1 (`mods:event`),
      # and all of group 2 (associated text). Captured directly into locals
      # instead of a nested `Array(Array(Int32?))` per event, since under
      # kitty's report-all-keys flag this runs on every keystroke. `g2` is
      # allocated lazily, only when associated text is present (rare).
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

    # Reads and parses the payload of a mouse report whose introducer is
    # already consumed into *sequence*. `sequence[2]` (the char after `\e[`)
    # selects the encoding:
    #
    #   * `M`      — X10 / normal (three raw bytes follow).
    #   * `I`/`O`  — focus-in / focus-out (no payload).
    #   * `<`      — SGR (1006) (parameter list follows).
    #   * a digit  — URxvt (1015) or DEC-locator (`… & w`); whole report already
    #                captured in *sequence*.
    #
    # Returns the parsed `Mouse::Event`, or `nil` if the stream ended or malformed.
    private def read_mouse(sequence, &) : Mouse::Event?
      case sequence[2]? || '\0'
      when 'M'
        # X10 / normal encoding: three raw 8-bit bytes follow, read via
        # `next_byte` (not UTF-8 `read_char`) so a coordinate past column/row 95
        # (byte >= 0x80) survives intact.
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
        # Numeric-CSI mouse report, already captured in *sequence*: DEC-locator
        # ends in `& w`, URxvt (1015) ends in `M`/`m`.
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
    # Only three parameters matter, collected into fixed locals (no per-report
    # `Array`) since a mouse drag is a burst of these. *idx* counts parameters
    # seen so the final byte can verify there were enough.
    #
    # (DEC-locator reports are not `<`-introduced — they're `CSI Cb;Cx;Cy;Cp & w`,
    # reach the numeric-CSI path, and are parsed by `#read_dec`.)
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
          # `\e[<…M/m` is byte-identical for SGR (1006, cells) and SGR-Pixels
          # (1016, pixels); only the active mode tells them apart. When pixel
          # mode is on (`@mouse_cell_pixels` set), decode the params as pixels
          # and derive cell coords with the cached cell size.
          if cp = @mouse_cell_pixels
            return Mouse.parse_sgr_pixels p0, p1, p2, c, cp[0], cp[1]
          end
          return Mouse.parse_sgr p0, p1, p2, c
        else
          return nil
        end
      end
      nil
    end

    # Scans the `;`-separated decimal parameters of a numeric-CSI mouse report
    # already captured in *sequence* (from index 2) into a fixed four-slot
    # buffer. Stops at the first byte in *terminators* (`&` for DEC-locator,
    # `M`/`m` for URxvt) or any other non-digit, non-`;` byte. Returns the
    # buffer paired with the parameter count. `StaticArray` returned by value
    # keeps this allocation-free on the hot mouse-drag path.
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
    # in *sequence*. Terminates on the `&` intermediate and requires all four parameters.
    private def read_dec(sequence) : Mouse::Event?
      params, idx = scan_csi_mouse_params sequence, "&"
      return nil unless idx >= 4 # Cb ; Cx ; Cy ; Cp (the `&` closes Cp -> idx 4)
      Mouse.parse_dec params[0], params[1], params[2], params[3]
    end

    # Parses a URxvt report (`\e[ Cb ; Cx ; Cy M`) already captured in
    # *sequence*. Terminates on the `M`/`m` final and requires three parameters.
    private def read_urxvt(sequence) : Mouse::Event?
      params, idx = scan_csi_mouse_params sequence, "Mm"
      return nil unless idx >= 3 # Cb ; Cx ; Cy
      Mouse.parse_urxvt params[0], params[1], params[2]
    end
  end
end
