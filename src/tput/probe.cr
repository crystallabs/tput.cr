class Tput
  # A 24-bit color parsed from an OSC color report (`rgb:rr/gg/bb`).
  record RGB, r : UInt8, g : UInt8, b : UInt8 do
    def to_s(io)
      io << "#%02x%02x%02x" % {r, g, b}
    end
  end

  # Runtime terminal probing.
  #
  # Unlike `Features`/`Emulator`, which infer capabilities statically from
  # `ENV` and terminfo, this module discovers them by *literally trying*: it
  # writes a batch of query escape sequences to the terminal and reads the
  # replies back. This is the same technique used by Microsoft's `edit`:
  #
  # * OSC 10 / OSC 11      -> default foreground / background color
  # * OSC 4 ; 0..15        -> the 16 indexed palette colors
  # * SGR 48;2 + DECRQSS   -> whether 24-bit ("true") color survives a round
  #                           trip: we set a distinctive RGB background, ask the
  #                           terminal to report its current SGR, and check the
  #                           reply still carries the RGB triplet.
  # * DECRQSS ` q`         -> whether the terminal honors DECSCUSR cursor-style
  #                           setting: we ask it to report its current cursor
  #                           style; a valid `1$r…<space>q` reply confirms the
  #                           hardware cursor is styleable.
  # * OSC 12 ; ?           -> whether the terminal can report (and thus set) its
  #                           hardware cursor color.
  # * print `…` + DSR/CPR  -> measured width of an ambiguous-width char
  # * DA1 (`CSI c`)        -> device attributes, *and* a universal terminator:
  #                           every terminal answers DA1, but not all answer
  #                           the OSC queries, so its reply tells us when to
  #                           stop reading.
  #
  # Results are stored on `Tput#features` (`Features#default_foreground`,
  # `#default_background`, `#palette`, `#ambiguous_width`, `#da_params`).
  module Probe
    include Crystallabs::Helpers::Logging

    # Outcome of consuming the terminal's probe replies.
    record ProbeResult,
      ambiguous_width : Int32? = nil,
      got_da : Bool = false

    # Whether probing is possible (both ends must be a real terminal).
    def probe_capable? : Bool
      i, o = @input, @output
      i.responds_to?(:fd) && i.tty? && o.responds_to?(:fd) && o.tty?
    end

    # Probes the terminal for its features by round-tripping query sequences.
    #
    # Returns `true` if at least the DA1 terminator came back (i.e. the
    # terminal participated), `false` if probing was skipped or timed out
    # with no response. *timeout* bounds the wait for each individual reply;
    # a responsive terminal returns almost immediately thanks to the DA1
    # sentinel.
    def probe!(timeout : Time::Span = 3.seconds) : Bool
      return false unless probe_capable?

      result = ProbeResult.new
      with_raw_input do
        with_sync_output do
          probe_write build_probe_query
          result = probe_consume @input, timeout

          # Restore the cursor saved by DECSC (`\e7`) at the head of the query,
          # then erase from there to the end of the display (`\e[J`). This wipes
          # the `…` width probe and any printable fragments a non-conforming
          # terminal echoed from our DCS/DECRQSS queries (e.g. `$qm`, `$q q`),
          # including any that wrapped onto following lines, and leaves the
          # cursor exactly where it was before probing.
          probe_write "\e8\e[J"
        end
      end

      if w = result.ambiguous_width
        features.ambiguous_width = w
        features.sources["ambiguous_width"] = "probed via DSR/CPR cursor-position measurement"
      end

      # Harden the env/TERM-based emulator identity with the terminal's own
      # XTVERSION self-report (now stored on `features`).
      emulator?.try &.refine_from_probe!

      Log.trace { "probe!: #{result}" }
      result.got_da
    end

    # Reads and parses the terminal's replies from *io* until DA1 arrives or a
    # read times out. OSC color replies are applied to `features` as they come
    # in; the ambiguous-width measurement and DA1 presence are returned.
    #
    # Decoupled from `@input` so it can be exercised against an `IO::Memory`
    # holding canned responses, without a real terminal.
    def probe_consume(io : IO, timeout : Time::Span) : ProbeResult
      f = features
      width : Int32? = nil
      got_da = false

      loop do
        b = probe_read_byte io, timeout
        break unless b
        # Anything that isn't the start of a sequence (stray NUL, etc.) is
        # ignored; real replies all begin with ESC.
        next unless b == 0x1b_u8

        case probe_read_byte io, timeout
        when '['.ord # CSI
          params, final = probe_read_csi io, timeout
          case final
          when 'c'
            if params.starts_with? ">"
              # DA2 (secondary device attributes): `CSI > type ; version ; kbd c`.
              # Distinguished from DA1 by the `>` private marker; not a terminator.
              f.da2_params = probe_ints params
              f.sources["da2_params"] = "probed via DA2 (CSI > c) reply"
            else
              # DA1 reply. Doubles as the end-of-responses sentinel.
              f.da_params = probe_ints params
              f.sources["da_params"] = "probed via DA1 (CSI c) reply"
              got_da = true
              break
            end
          when 'R'
            # CPR `row ; col`. The char was printed at column 1, so the
            # reported column minus one is its rendered width.
            ints = probe_ints params
            width = ints[1] - 1 if ints.size >= 2
          when 'u'
            # Kitty keyboard protocol reply (`CSI ? <flags> u`). Any reply means
            # the protocol is supported; the value is the active flags.
            flags = probe_ints(params)[0]? || 0
            f.confirm_kitty_keyboard! flags, "probed via CSI ? u (kitty keyboard protocol)"
          when 'm'
            # XTQMODKEYS reply (`CSI > 4 ; <level> m`). Confirms xterm
            # modifyOtherKeys support and reports the current level.
            ints = probe_ints params
            if ints[0]? == 4
              f.confirm_modify_other_keys! (ints[1]? || 0), "probed via CSI ? 4 m (modifyOtherKeys)"
            end
          when 'y'
            # DECRQM reply (`CSI ? mode ; Ps $ y`): mode-support probe. A `Ps`
            # of 1–4 means the mode is recognized. We probe 2048 (in-band resize).
            ints = params.tr("?$", "").split(';').map(&.to_i?)
            if ints[0]? == 2048 && (ps = ints[1]?) && ps != 0
              f.in_band_resize = true
              f.sources["in_band_resize"] = "probed via DECRQM (CSI ? 2048 $ p)"
            end
          end
        when ']'.ord # OSC
          apply_osc_color f, probe_read_osc(io, timeout)
        when 'P'.ord # DCS (DECRQSS / XTVERSION reply)
          payload = probe_read_dcs io, timeout
          if payload.starts_with? ">|"
            # XTVERSION: terminal name+version, e.g. `>|kitty(0.32.0)`.
            f.terminal_version = payload[2..]
            f.sources["terminal_version"] = "probed via XTVERSION (DCS > | …)"
          elsif truecolor_confirmed? payload
            f.confirm_truecolor! "probed via DECRQSS (24-bit SGR readback)"
          elsif cursor_style_confirmed? payload
            f.confirm_cursor_style! "probed via DECRQSS (DECSCUSR cursor-style readback)"
          end
        end
      end

      ProbeResult.new ambiguous_width: width, got_da: got_da
    end

    # Builds the single batched query string. `DECSC` (`\e7`) saves the cursor
    # up front — before any query is sent — so `probe!` can restore it exactly
    # and erase anything a non-conforming terminal echoed back. For the width
    # probe, `\r` parks the cursor at column 1 so the CPR column maps directly
    # to the rendered width. DA1 goes last so its reply terminates the read.
    def build_probe_query : String
      String.build do |io|
        io << "\e7"                # DECSC: save cursor before anything is sent
        io << "\e]10;?\a\e]11;?\a" # default fg / bg
        io << "\e]12;?\a"          # hardware cursor color (OSC 12)
        io << "\e]4"               # indexed palette 0..15
        16.times { |i| io << ';' << i << ";?" }
        io << '\a'
        # Truecolor probe: set bg to RGB(1,2,3), ask for the current SGR via
        # DECRQSS (DCS $q m ST), then reset. If the terminal kept the 24-bit
        # value its reply echoes `1;2;3`; if it lacks truecolor it downsamples
        # (or doesn't answer DECRQSS at all).
        io << "\e[48;2;1;2;3m\eP$qm\e\\\e[m"
        # Cursor-style probe: ask for the current DECSCUSR setting via DECRQSS
        # (DCS $q <space> q ST). A terminal that honors cursor styling answers
        # `1$r<n> q`; one that doesn't sends `0$r` or nothing.
        io << "\eP$q q\e\\"
        io << "\r…\e[6n" # park at column 1, print ambiguous char, CPR
        # Enhanced keyboard protocols. Both are private queries that supporting
        # terminals answer and others silently ignore: `CSI ? u` → kitty
        # keyboard protocol (`CSI ? <flags> u`); `CSI ? 4 m` → XTQMODKEYS for
        # xterm modifyOtherKeys (`CSI > 4 ; <level> m`).
        io << "\e[?u"
        io << "\e[?4m"
        io << "\e[?2048$p" # DECRQM: in-band resize support (`CSI ? 2048 ; Ps $ y`)
        io << "\e[>0q"     # XTVERSION: terminal name+version (DCS reply)
        io << "\e[>c"      # DA2: secondary attributes (`CSI > … c`), before DA1
        io << "\e[c"       # DA1: capabilities + terminator
      end
    end

    # Writes *data* straight to the terminal, bypassing the output buffer,
    # and flushes so the query actually leaves before we start reading.
    private def probe_write(data : String) : Nil
      @output.print data
      @output.flush
    end

    # Reads a single byte from *io*, honoring *timeout*. Returns `nil` on
    # timeout or EOF.
    private def probe_read_byte(io : IO, timeout : Time::Span) : UInt8?
      if io.responds_to? :"read_timeout="
        io.read_timeout = timeout
      end
      begin
        io.read_byte
      rescue IO::TimeoutError
        nil
      ensure
        if io.responds_to? :"read_timeout="
          io.read_timeout = nil
        end
      end
    end

    # Reads the remainder of a CSI sequence (parameter and intermediate
    # bytes) up to and including the final byte. Returns the raw parameter
    # string and the final byte as a `Char`.
    private def probe_read_csi(io : IO, timeout : Time::Span) : {String, Char}
      params = String::Builder.new
      loop do
        b = probe_read_byte io, timeout
        return {params.to_s, '\0'} unless b
        # Final bytes are 0x40..0x7e; everything before is param/intermediate.
        if 0x40_u8 <= b <= 0x7e_u8
          return {params.to_s, b.chr}
        end
        params << b.chr
      end
    end

    # Reads the payload of an OSC sequence up to its terminator (BEL, or
    # ST = `ESC \`). Returns the payload without the terminator.
    private def probe_read_osc(io : IO, timeout : Time::Span) : String
      probe_read_string_terminated io, timeout
    end

    # Reads the payload of a DCS sequence (everything after `ESC P`) up to its
    # string terminator (ST = `ESC \`, or BEL). Returns the payload without the
    # terminator. The DECRQSS reply we care about looks like `1$rPm` where `P`
    # is the active SGR parameter list, e.g. `1$r0;48:2::1:2:3m`.
    private def probe_read_dcs(io : IO, timeout : Time::Span) : String
      probe_read_string_terminated io, timeout
    end

    # Shared reader for an OSC or DCS control-string payload: both run until a
    # string terminator (ST = `ESC \`) or BEL and return the bytes before it. A
    # lone `ESC` not followed by `\` is kept as literal payload.
    #
    # Bytes are accumulated raw and decoded as UTF-8 only at the end: a payload
    # like a window title (`get_text_params`) or terminal name (XTVERSION) may
    # carry multi-byte characters, and decoding each byte on its own as a
    # codepoint would turn them into Latin-1 mojibake.
    private def probe_read_string_terminated(io : IO, timeout : Time::Span) : String
      data = IO::Memory.new
      loop do
        b = probe_read_byte io, timeout
        return data.to_s unless b
        case b
        when 0x07_u8 # BEL
          return data.to_s
        when 0x1b_u8 # possible ST: ESC \
          nxt = probe_read_byte io, timeout
          return data.to_s if nxt.nil? || nxt == '\\'.ord
          data.write_byte 0x1b_u8
          data.write_byte nxt
        else
          data.write_byte b
        end
      end
    end

    # Decides whether a DECRQSS SGR reply confirms 24-bit color. A valid reply
    # starts with `1$r`; truecolor terminals echo the background we set back as
    # an RGB triplet (`48:2:…1:2:3` or `48;2;1;2;3`). A 256-color terminal
    # downsamples (e.g. `48;5;N`) and fails the match; one without DECRQSS never
    # sends a DCS reply at all.
    private def truecolor_confirmed?(data : String) : Bool
      data.includes?("$r") && !!data.match(/48[:;]2[:;].*1[:;]2[:;]3/)
    end

    # Decides whether a DECRQSS reply confirms DECSCUSR cursor styling. A valid
    # reply starts with `1$r` and is terminated by the DECSCUSR final ` q`
    # (space + `q`), e.g. `1$r2 q`. An unsupported terminal answers `0$r` (no
    # trailing ` q`) or sends no DCS reply at all.
    private def cursor_style_confirmed?(data : String) : Bool
      data.includes?("1$r") && data.rstrip.ends_with?(" q")
    end

    # Splits a CSI parameter string like `"0;36"` (or `"?62;1;6"`) into its
    # numeric components. A leading private marker (`?`/`>`/`=`/`<`), as used
    # by DA1 replies, is stripped first so the first parameter parses.
    private def probe_ints(params : String) : Array(Int32)
      params = params.lstrip "?>=<"
      params.split(';').map { |p| p.to_i? || 0 }
    end

    # Applies one parsed OSC color reply to *f*. Recognized forms:
    # `10;rgb:…` (fg), `11;rgb:…` (bg), `4;<n>;rgb:…` (palette entry).
    private def apply_osc_color(f : Features, data : String) : Nil
      parts = data.split(';')
      return if parts.size < 2

      case parts[0]
      when "10"
        if rgb = parse_rgb parts[1]
          f.default_foreground = rgb
          f.sources["default_foreground"] = "probed via OSC 10 reply"
        end
      when "11"
        if rgb = parse_rgb parts[1]
          f.default_background = rgb
          f.sources["default_background"] = "probed via OSC 11 reply"
        end
      when "12"
        # The terminal answered with its current cursor color, so OSC 12 is
        # supported (and thus settable). We don't need the value itself.
        f.confirm_cursor_color! "probed via OSC 12 reply"
      when "4"
        # A single OSC 4 reply can carry *several* `index;rgb:…` pairs: xterm
        # answers a batched query (`OSC 4 ; 0 ; ? ; 1 ; ? ; …`) with one reply
        # "of the same form", so all 16 colors arrive together. Walk every pair
        # rather than just the first. (`rgb:…` has no `;`, so the split aligns.)
        i = 1
        while i + 1 < parts.size
          idx = parts[i].to_i?
          if idx && 0 <= idx < 16 && (rgb = parse_rgb parts[i + 1])
            f.palette[idx] = rgb
            f.sources["palette"] = "probed via OSC 4 replies"
          end
          i += 2
        end
      end
    end

    # Parses an `rgb:RR/GG/BB` spec (1-4 hex digits per channel) into an
    # `RGB`, scaling each channel down to 8 bits.
    private def parse_rgb(spec : String) : RGB?
      return nil unless spec.starts_with? "rgb:"
      comps = spec[4..].split('/')
      return nil unless comps.size == 3

      vals = comps.map do |c|
        v = c.to_i?(16)
        return nil unless v
        case c.size
        when 1 then (v * 0xff // 0xf).to_u8
        when 2 then v.to_u8
        when 3 then ((v * 0xff + 0x7ff) // 0xfff).to_u8
        when 4 then ((v * 0xff + 0x7fff) // 0xffff).to_u8
        else        return nil
        end
      end

      RGB.new vals[0], vals[1], vals[2]
    end
  end
end
