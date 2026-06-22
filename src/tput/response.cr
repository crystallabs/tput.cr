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
