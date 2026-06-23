class Tput
  # Terminal query/response.
  #
  # Where `Probe` round-trips a *batch* of detection queries at startup, this
  # module exposes the individual, on-demand queries: write a request escape
  # sequence and synchronously read back the terminal's reply, parsed into a
  # typed result. It reuses `Probe`'s low-level reply readers
  # (`probe_read_byte`/`probe_read_csi`/`probe_read_osc`, `probe_ints`,
  # `parse_rgb`).
  #
  # These are the counterpart of Blessed's `Program#response` family
  # (`getCursor`, `dsr`/`deviceStatus`, `da`/`sendDeviceAttributes`,
  # `getCursorColor`, `getTextParams`, `getWindowSize`, `requestParameters`,
  # `requestLocatorPosition`). Blessed dispatches replies asynchronously through
  # its input EventEmitter; tput.cr has no such emitter, so — like `probe!` —
  # each query reads its reply synchronously, with a timeout.
  #
  # NOTE: because the read is synchronous and pulls straight from `@input`, a
  # query must not run concurrently with an active `Input#listen` loop (the two
  # would race for the same bytes). Issue these outside the main input loop
  # (e.g. during setup), the same constraint that applies to `probe!`.
  module Response
    include Crystallabs::Helpers::Alias_Methods

    # Default per-reply timeout. A responsive terminal answers almost
    # immediately; this only bounds the wait when the terminal stays silent.
    RESPONSE_TIMEOUT = 2.seconds

    # Requests the current cursor position (DSR 6 / CPR, `CSI 6 n`) and returns
    # it as a 0-based `Point` (matching `Tput#cursor`), or `nil` if the terminal
    # cannot be queried or does not answer.
    def report_cursor(timeout : Time::Span = RESPONSE_TIMEOUT) : Point?
      query("\e[6n", timeout) { |io| read_cursor_response io, timeout }
    end

    alias_previous get_cursor

    # Queries the cursor position and stores it for `#restore_reported_cursor`.
    # Returns `true` if the terminal reported a position.
    def save_reported_cursor(timeout : Time::Span = RESPONSE_TIMEOUT) : Bool
      if pos = report_cursor(timeout)
        @_rx = pos.x
        @_ry = pos.y
        true
      else
        false
      end
    end

    # Device Status Report (`CSI Ps n`, or `CSI ? Ps n` when *dec* is true).
    # Returns the numeric parameters of the reply (for *param* `6` this is the
    # CPR `row ; col`), or `nil` on no answer.
    def device_status(param = 0, dec = false, timeout : Time::Span = RESPONSE_TIMEOUT) : Array(Int32)?
      req = dec ? "\e[?#{param}n" : "\e[#{param}n"
      query(req, timeout) { |io| read_device_status_response io, timeout }
    end

    alias_previous dsr

    # Sends a Device Attributes request (DA1, `CSI Ps c`) and returns the
    # reported attribute parameters (e.g. `[62, 1, 6]`), or `nil` on no answer.
    def send_device_attributes(param = "", timeout : Time::Span = RESPONSE_TIMEOUT) : Array(Int32)?
      query("\e[#{param}c", timeout) { |io| read_device_attributes_response io, timeout }
    end

    alias_previous da

    # Queries a terminal text parameter (`OSC Ps ; ? BEL`) and returns its text
    # value (`Pt`), or `nil` on no answer.
    def get_text_params(param : Int32, timeout : Time::Span = RESPONSE_TIMEOUT) : String?
      query("\e]#{param};?\a", timeout) { |io| read_text_params_response io, timeout, param }
    end

    # Queries the hardware cursor color (OSC 12) and returns it as an `RGB`, or
    # `nil` if the terminal does not report one.
    def get_cursor_color(timeout : Time::Span = RESPONSE_TIMEOUT) : RGB?
      query("\e]12;?\a", timeout) { |io| read_cursor_color_response io, timeout }
    end

    # Requests the text-area size via XTWINOPS 18 (`CSI 18 t`) and returns
    # `{height, width}` in character cells, or `nil` on no answer.
    def get_window_size(timeout : Time::Span = RESPONSE_TIMEOUT) : {Int32, Int32}?
      query("\e[18t", timeout) { |io| read_window_size_response io, timeout }
    end

    alias_previous get_text_area_size

    # Requests Terminal Parameters (DECREQTPARM, `CSI Ps x`) and returns the
    # reported parameters, or `nil` on no answer.
    def request_parameters(param = 0, timeout : Time::Span = RESPONSE_TIMEOUT) : Array(Int32)?
      query("\e[#{param}x", timeout) { |io| read_request_parameters_response io, timeout }
    end

    alias_previous decreqtparm

    # Requests the current locator position (DECRQLP, `CSI Ps ' |`) and returns
    # the reported parameters (`Pe ; Prow ; Pcol ; Ppage`), or `nil` on no
    # answer.
    def request_locator_position(param = "", timeout : Time::Span = RESPONSE_TIMEOUT) : Array(Int32)?
      query("\e[#{param}'|", timeout) { |io| read_locator_position_response io, timeout }
    end

    alias_previous decrqlp, req_mouse_pos

    # Sends a Secondary Device Attributes request (DA2, `CSI > c`) and returns
    # the reported parameters `[type, version, keyboard]` (e.g. `[0, 276, 0]`),
    # or `nil` on no answer. More reliable than env-var heuristics for
    # identifying the terminal and its version.
    def secondary_device_attributes(timeout : Time::Span = RESPONSE_TIMEOUT) : Array(Int32)?
      query("\e[>c", timeout) { |io| read_csi_ints io, timeout, "c" }
    end

    alias_previous da2

    # Requests the terminal name and version via XTVERSION (`CSI > 0 q`) and
    # returns the reported string (e.g. `"kitty(0.32.0)"`, `"WezTerm …"`), or
    # `nil` if the terminal does not answer.
    def request_terminal_version(timeout : Time::Span = RESPONSE_TIMEOUT) : String?
      query("\e[>0q", timeout) { |io| read_xtversion_response io, timeout }
    end

    alias_previous xtversion

    # XTGETTCAP (`DCS + q <names> ST`): queries the terminal directly for one or
    # more terminfo/termcap capabilities *by name* (e.g. `"TN"` terminal name,
    # `"Co"` max colors, `"RGB"`), returning a `{name => value}` hash of the ones
    # the terminal recognized (an empty hash if it recognized none, `nil` if it
    # did not answer). Values are decoded from the hex the protocol uses. Lets a
    # program read capabilities straight from the terminal when terminfo is
    # absent or stale (kitty, foot, WezTerm, recent xterm, …).
    def request_termcap(*names : String, timeout : Time::Span = RESPONSE_TIMEOUT) : Hash(String, String)?
      hex = names.map { |n| n.to_slice.hexstring }.join(';')
      query("\eP+q#{hex}\e\\", timeout) { |io| read_xtgettcap_response io, timeout }
    end

    alias_previous xtgettcap

    # OSC 52: reads the terminal clipboard *selection* (`"c"`, `"p"`, …) and
    # returns its text, or `nil` if the terminal does not answer (many terminals
    # allow clipboard *writes* but disable reads for security).
    def get_clipboard(selection : String = "c", timeout : Time::Span = RESPONSE_TIMEOUT) : String?
      query("\e]52;#{selection};?\a", timeout) { |io| read_clipboard_response io, timeout }
    end

    # Queries whether the terminal supports a DEC private mode via DECRQM
    # (`CSI ? Pd $ p`). Returns `true` if the terminal reports the mode as
    # recognized (reply `Ps` of 1–4), `false` if not recognized, `nil` on no
    # answer. Used e.g. to detect synchronized output (mode 2026).
    def supports_private_mode?(mode : Int32, timeout : Time::Span = RESPONSE_TIMEOUT) : Bool?
      query("\e[?#{mode}$p", timeout) { |io| read_decrqm_response io, timeout, mode }
    end

    # Whether the terminal supports synchronized output (DEC private mode 2026).
    def supports_synchronized_output?(timeout : Time::Span = RESPONSE_TIMEOUT) : Bool?
      supports_private_mode? 2026, timeout
    end

    # Whether the terminal supports in-band resize notifications (DEC private
    # mode 2048). Also auto-detected at startup into `Features#in_band_resize?`.
    def supports_in_band_resize?(timeout : Time::Span = RESPONSE_TIMEOUT) : Bool?
      supports_private_mode? 2048, timeout
    end

    # Whether the terminal supports Unicode grapheme clustering (DEC mode 2027).
    def supports_grapheme_clustering?(timeout : Time::Span = RESPONSE_TIMEOUT) : Bool?
      supports_private_mode? 2027, timeout
    end

    # Whether the terminal supports color-scheme change notifications (DEC mode
    # 2031).
    def supports_color_scheme_notifications?(timeout : Time::Span = RESPONSE_TIMEOUT) : Bool?
      supports_private_mode? 2031, timeout
    end

    # Queries the terminal's current color scheme via `CSI ? 996 n`; the reply
    # `CSI ? 997 ; Ps n` gives the scheme (`Ps` 1 = dark, 2 = light). Returns the
    # `ColorScheme`, or `nil` if the terminal does not answer.
    def request_color_scheme(timeout : Time::Span = RESPONSE_TIMEOUT) : ColorScheme?
      query("\e[?996n", timeout) { |io| read_color_scheme_response io, timeout }
    end

    # --- Reply parsers --------------------------------------------------------
    #
    # Each reads and parses one reply from *io*, decoupled from `@input` so it
    # can be exercised against an `IO::Memory` of canned bytes (as the specs do).

    # Parses a CPR reply (`CSI row ; col R`) into a 0-based `Point`.
    def read_cursor_response(io : IO, timeout : Time::Span) : Point?
      ints = read_csi_ints(io, timeout, "R") || return nil
      return nil unless ints.size >= 2
      Point.new ints[1] - 1, ints[0] - 1
    end

    # Parses a DSR/CPR reply (final `n` for status, `R` for cursor position).
    def read_device_status_response(io : IO, timeout : Time::Span) : Array(Int32)?
      read_csi_ints io, timeout, "Rn"
    end

    # Parses a DA1 reply (`CSI ? … c`).
    def read_device_attributes_response(io : IO, timeout : Time::Span) : Array(Int32)?
      read_csi_ints io, timeout, "c"
    end

    # Parses an XTWINOPS size reply (`CSI 8 ; height ; width t`).
    def read_window_size_response(io : IO, timeout : Time::Span) : {Int32, Int32}?
      ints = read_csi_ints(io, timeout, "t") || return nil
      return nil unless ints.size >= 3
      {ints[1], ints[2]}
    end

    # Parses a DECREQTPARM reply (`CSI … x`).
    def read_request_parameters_response(io : IO, timeout : Time::Span) : Array(Int32)?
      read_csi_ints io, timeout, "x"
    end

    # Parses a DECRQLP locator-position reply (`CSI … & w`). The `&`
    # intermediate is stripped before the parameters are parsed.
    def read_locator_position_response(io : IO, timeout : Time::Span) : Array(Int32)?
      reply = read_csi_reply(io, timeout, "w") || return nil
      probe_ints reply[0].delete('&')
    end

    # Parses an OSC text-parameter reply (`OSC param ; Pt`) and returns `Pt`.
    def read_text_params_response(io : IO, timeout : Time::Span, param : Int32) : String?
      data = read_osc_reply(io, timeout, "#{param};") || return nil
      data.split(';', 2)[1]?
    end

    # Parses an OSC 12 cursor-color reply into an `RGB`.
    def read_cursor_color_response(io : IO, timeout : Time::Span) : RGB?
      pt = read_text_params_response(io, timeout, 12) || return nil
      parse_rgb pt
    end

    # Parses an XTVERSION reply (`DCS > | <name> ST`) and returns `<name>`.
    def read_xtversion_response(io : IO, timeout : Time::Span) : String?
      loop do
        b = probe_read_byte(io, timeout) || return nil
        next unless b == 0x1b_u8
        nb = probe_read_byte(io, timeout) || return nil
        next unless nb == 'P'.ord # DCS
        payload = probe_read_dcs io, timeout
        return payload[2..] if payload.starts_with? ">|"
      end
    end

    # Parses an OSC 52 clipboard reply (`OSC 52 ; <selection> ; <base64> ST`)
    # and returns the decoded text.
    def read_clipboard_response(io : IO, timeout : Time::Span) : String?
      data = read_osc_reply(io, timeout, "52;") || return nil
      b64 = data.split(';')[2]? || return nil
      Base64.decode_string b64
    rescue
      nil
    end

    # Parses an XTGETTCAP reply (`DCS 1 + r <name>=<value>;… ST` on success,
    # `DCS 0 + r … ST` when nothing was recognized). Names and values arrive
    # hex-encoded. Returns the decoded `{name => value}` pairs.
    def read_xtgettcap_response(io : IO, timeout : Time::Span) : Hash(String, String)?
      loop do
        b = probe_read_byte(io, timeout) || return nil
        next unless b == 0x1b_u8
        nb = probe_read_byte(io, timeout) || return nil
        next unless nb == 'P'.ord # DCS
        payload = probe_read_dcs io, timeout
        # Expect `<status>+r<body>`, status '1' (valid) or '0' (invalid).
        next unless payload.size >= 3 && payload[1] == '+' && payload[2] == 'r'
        result = {} of String => String
        return result unless payload[0] == '1'
        payload[3..].split(';').each do |pair|
          name, sep, value = pair.partition('=')
          next if name.empty?
          decoded = (n = unhex name) ? n : next
          result[decoded] = sep.empty? ? "" : (unhex(value) || "")
        end
        return result
      end
    end

    # Decodes a hex string to text, or `nil` if it is not valid hex.
    private def unhex(hex : String) : String?
      return "" if hex.empty?
      String.new hex.hexbytes
    rescue ArgumentError
      nil
    end

    # Parses a color-scheme reply (`CSI ? 997 ; Ps n`) into a `ColorScheme`.
    def read_color_scheme_response(io : IO, timeout : Time::Span) : ColorScheme?
      ints = read_csi_ints(io, timeout, "n") || return nil
      return nil unless ints[0]? == 997
      case ints[1]?
      when 1 then ColorScheme::Dark
      when 2 then ColorScheme::Light
      else        nil
      end
    end

    # Parses a DECRQM reply (`CSI ? mode ; Ps $ y`). Returns `true` if *mode* is
    # recognized (`Ps` 1–4), `false` if not (`Ps` 0), `nil` on a mismatched or
    # absent reply.
    def read_decrqm_response(io : IO, timeout : Time::Span, mode : Int32) : Bool?
      reply = read_csi_reply(io, timeout, "y") || return nil
      ints = reply[0].tr("?$", "").split(';').map(&.to_i?)
      return nil unless ints[0]? == mode
      ps = ints[1]?
      !!(ps && ps != 0)
    end

    # --- Internals ------------------------------------------------------------

    # Writes *request* to the terminal (bypassing the output buffer, flushed)
    # and synchronously reads its reply via the block, with raw input. Returns
    # `nil` without writing anything if the terminal can't be queried (e.g. not
    # a tty, as in tests / when piped).
    private def query(request : String, timeout : Time::Span, & : IO -> T) : T? forall T
      return nil unless probe_capable?

      result = nil
      with_raw_input do
        with_sync_output do
          @output.print request
          @output.flush
          result = yield @input
        end
      end
      result
    end

    # Reads CSI replies from *io* until one whose final byte is in *finals*
    # arrives, returning `{params, final}`. Unrelated bytes and non-matching
    # sequences are skipped. Returns `nil` on timeout/EOF.
    private def read_csi_reply(io : IO, timeout : Time::Span, finals : String) : {String, Char}?
      loop do
        b = probe_read_byte(io, timeout) || return nil
        next unless b == 0x1b_u8
        nb = probe_read_byte(io, timeout) || return nil
        next unless nb == '['.ord
        params, final = probe_read_csi io, timeout
        return {params, final} if finals.includes? final
      end
    end

    # Reads the next CSI reply whose final byte is in *finals* and returns its
    # parameters as integers (the common shape for DSR/DA/window/DECREQTPARM
    # replies). Returns `nil` on timeout/EOF.
    private def read_csi_ints(io : IO, timeout : Time::Span, finals : String) : Array(Int32)?
      reply = read_csi_reply(io, timeout, finals) || return nil
      probe_ints reply[0]
    end

    # Reads OSC replies from *io* until one whose payload starts with *prefix*
    # arrives, returning the payload. Returns `nil` on timeout/EOF.
    private def read_osc_reply(io : IO, timeout : Time::Span, prefix : String) : String?
      loop do
        b = probe_read_byte(io, timeout) || return nil
        next unless b == 0x1b_u8
        nb = probe_read_byte(io, timeout) || return nil
        next unless nb == ']'.ord
        data = probe_read_osc io, timeout
        return data if data.starts_with? prefix
      end
    end
  end
end
