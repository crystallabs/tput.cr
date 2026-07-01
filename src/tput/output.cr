require "./output/*"

class Tput
  module Output
    include Crystallabs::Helpers::Logging

    include Output::Cursor
    include Output::Text
    include Output::Misc
    include Output::Scrolling
    include Output::Charset
    include Output::Emulator
    include Output::Colors
    include Output::Bell
    include Output::Rectangles
    include Output::Mouse
    include Output::Screen
    include Output::Terminal

    # Wrap escape sequences in DCS sequences and directly print to `@output`.
    #
    # A terminal multiplexer (tmux or GNU screen) only forwards an escape
    # sequence to the outer terminal if wrapped in that multiplexer's DCS
    # passthrough. Applies the wrapping when the detected emulator is tmux or
    # screen, then prints directly to `@output` (flushing any existing buffer
    # first). On a non-multiplexed terminal, behaves like `#_write`.
    #
    #     Example (tmux):   `DCS tmux; ESC Pt ST`  ->  `\ePtmux;\e … \e\\`
    #     Example (screen): `DCS ESC Pt ST`        ->  `\eP … \e\\`
    def _tprint(data)
      if emulator.tmux? || emulator.screen?
        # Replace all STs with BELs so they can be nested within the DCS code.
        data = data.gsub /\e\\/, "\x07"

        # Wrap in the multiplexer's forward DCS. Every ESC byte *inside* the
        # wrapped payload must be doubled, otherwise the multiplexer treats it as
        # the end of (or a new) control sequence and truncates/mangles the rest.
        # Only the payload's ESCs are doubled — never the `\eP` introducer or the
        # `\e\\` ST terminator that frame the passthrough.
        data = if emulator.tmux?
                 # The `\ePtmux;` introducer is followed by `;`, so the payload's
                 # leading ESC is itself internal and gets doubled too.
                 "\ePtmux;" + data.gsub('\e', "\e\e") + "\e\\"
               else
                 # GNU screen's plain `\eP` introducer is immediately followed by
                 # the payload's leading ESC, which stays single; only *internal*
                 # ESCs are doubled.
                 "\eP" + data.gsub(/(?<=.)\e/, "\e\e") + "\e\\"
               end

        # TODO
        # # If we've never even flushed yet, it means we're still in
        # # the normal buffer. Wait for alt screen buffer.
        # if (this.output.bytesWritten === 0)
        #	timer = setInterval(function()
        #		if (self.output.bytesWritten > 0 || ++iterations === 50)
        #			clearInterval(timer)
        #			self.flush()
        #			self._owrite(data)
        #		end
        #	end 100)
        #	return true
        # end

        # NOTE: Flushing the buffer is required in some cases.
        # The DCS code must be at the start of the output.
        flush

        # Write out raw now that the buffer is flushed.
        _oprint data
      else
        _print data
      end
    end

    # Directly writes string to `@output` (usually STDOUT).
    #
    # Mostly not used directly, but through `#_write`.
    def _owrite(*args)
      # No support for this yet:
      # return unless @output.writable?
      args.map { |arg| (@ret || @output).write arg }
      # TODO drop writes if in pause mode
      # same for _oprint
    end

    def _oprint(*args)
      # https://github.com/crystal-lang/crystal/pull/10152
      args.join io: @ret || @output
      true
    end

    def _with_io(& : IO -> Nil)
      # `@ret` (set by a caller diverting output, e.g. Crysterm's `divert`) takes
      # precedence over `@output`, matching `_owrite`/`_oprint` — otherwise the
      # block form of `_print` would bypass a diverter and leak to `@output`.
      yield(@ret || @output)
      true
    end

    # Standard output method.
    #
    # Takes into account internal buffering.
    def _write(*args)
      if use_buffer?
        _buffer_write *args
      else
        _owrite *args
      end
    end

    def _print(*args)
      if use_buffer?
        _buffer_print *args
      else
        _oprint *args
      end
    end

    def _print(& : IO -> Nil)
      # Yield the block directly instead of forwarding it (`_buffer_print &block`
      # / `_with_io &block`). Passing a block to a method with a typed
      # `&block : IO -> Nil` parameter materializes it as a heap `Proc` closure
      # (~16 B/call); since this is on the per-frame render hot path (every
      # cursor move emits via it), that showed up at 16 B/op. Inlining the
      # dispatch keeps the block a true yield, so the fast paths allocate
      # nothing. Branch logic below matches `_buffer_print(&block)` + `_with_io`.
      if use_buffer?
        if @_exiting
          flush
          yield(@ret || @output)
        else
          yield(@ret || @_buf)
        end
      else
        yield(@ret || @output)
      end
      true
    end

    # def _write(bytes : Bytes)
    #  #return text if @ret
    #  if use_buffer?
    #    _buffer bytes
    #  else
    #    _owrite bytes
    #  end
    # end
    # # :ditto:
    # def _write(str : String)
    #  _write str.to_slice
    # end
    # # :ditto:
    # def _write(&block : IO -> Nil)
    #  if use_buffer?
    #    _buffer &block
    #  else
    #    _owrite &block
    #  end
    # end

    # Matches a terminfo padding instruction: `$<delay[*/]>`, where *delay* is a
    # number of milliseconds (optionally fractional) and the optional `*` / `/`
    # suffixes mark it as proportional / mandatory respectively.
    PADDING_RE = /\$<([\d.]+)([*\/]{0,2})>/

    # Standard output method which takes terminal padding (software timing/delays) into account.
    #
    # Compiled terminfo capabilities can embed padding instructions of the form
    # `$<delay>` (e.g. `$<5>`, `$<10*>`, `$<5/>`). Unibilium performs parameter
    # substitution but, like ncurses' `tparm`, leaves these markers in the
    # output; honoring them (ncurses' `tputs` job) is left to us. Strips the
    # markers and, where the terminal lacks hardware flow control, sleeps for
    # the requested delay before emitting the following bytes.
    #
    # With no padding instructions, behaves like `#_write`. See ncurses'
    # `tinfo/lib_tputs.c`.
    def _pad_write(code : Bytes) : Bool
      # Fast path: no `$<` marker — write the bytes as-is, without allocating a
      # `String`. Padding is rare on modern terminals and this is on the
      # per-frame render path, so it must stay allocation-free.
      unless padding_marker? code
        _write code
        return true
      end

      str = String.new code

      # `xon` means the terminal has hardware flow control (XON/XOFF). When it
      # does, advisory padding (without a mandatory `/` suffix) is skipped; only
      # mandatory delays are honored.
      xon = !has?(&.needs_xon_xoff?) || !!has?(&.xon_xoff?)

      rest = str
      while m = PADDING_RE.match(rest)
        pre = m.pre_match
        _write pre.to_slice unless pre.empty?

        amount = m[1].to_f
        suffix = m[2]

        # `/` forces the delay even when flow control is present. `*` marks the
        # delay as proportional to the number of affected lines; we keep the
        # base amount rather than scaling it (as in Blessed).
        mandatory = suffix.includes? '/'
        if (mandatory || !xon) && amount > 0
          sleep amount.milliseconds
        end

        rest = m.post_match
      end

      _write rest.to_slice unless rest.empty?
      true
    end

    # Whether *code* contains a `$<` padding-instruction introducer, scanned
    # directly over the bytes so the no-padding fast path in `#_pad_write` never
    # allocates a `String`.
    private def padding_marker?(code : Bytes) : Bool
      i = 0
      last = code.size - 1
      while i < last
        return true if code.unsafe_fetch(i) == 0x24_u8 && code.unsafe_fetch(i + 1) == 0x3c_u8 # "$<"
        i += 1
      end
      false
    end

    # Saves `bytes` to local buffer.
    private def _buffer_write(*args) # bytes : Bytes)
      if @_exiting
        flush
        _owrite *args
        return true
      end
      # Not needed any more since buf is now an IO rather than slice.
      # Essentially a += operation for Bytes
      # _buf = Bytes.new @_buf.size + bytes.size
      # @_buf.copy_to _buf
      # bytes.copy_to _buf + @_buf.size
      # @_buf = _buf
      # @_buf.write bytes
      #
      # As in `_owrite`/`_buffer_print`, a diverter (`@ret`) wins over the
      # internal buffer so diverted output isn't leaked into `@_buf`. Without
      # this, a `@ret` set while buffering is enabled (the default) was honored
      # by the block-form fast path but silently bypassed here.
      dest = @ret || @_buf
      args.each { |a| dest.write a }
      true
    end

    private def _buffer_print(*args)
      if @_exiting
        flush
        _oprint *args
        return true
      end

      # As in the block form below and `_oprint`, a diverter (`@ret`) wins over
      # the internal buffer so diverted output isn't leaked into `@_buf`.
      # https://github.com/crystal-lang/crystal/pull/10152
      args.join io: @ret || @_buf
      true
    end

    private def _buffer_print(&block : IO -> Nil)
      if @_exiting
        flush
        _with_io &block
      else
        # As in `_with_io`, a diverter (`@ret`) wins over the internal buffer.
        yield(@ret || @_buf)
      end
      true
    end

    # private def _buffer(&block : IO -> Nil)
    #  with @_buf yield @_buf
    #  true
    # end

    # Flushes internal buffer into `@output` and calls `@output.flush`
    def flush
      unless @_buf.empty?
        # `@output << @_buf` would route via `IO::Memory#to_s`, allocating a
        # full String copy on every flush; `to_slice` is a view over the same
        # bytes.
        @output.write @_buf.to_slice
        @_buf.clear
        @output.flush
      end
      true
    end
  end
end
