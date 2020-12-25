require "./output/*"
class Tput
  module Output

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

    @ret = false

    @[JSON::Field(ignore: true)]
    @_buf : Bytes? = nil

    getter? use_buffer : Bool

    # Example: `DCS tmux; ESC Pt ST`
    # Real: `DCS tmux; ESC Pt ESC \`
    def _twrite(data)
      iterations = 0

      if emulator.tmux?
        # Replace all STs with BELs so they can be nested within the DCS code.
        data = data.gsub /\x1b\\/, "\x07"

        # Wrap in tmux forward DCS:
        data = "\x1bPtmux;\x1b" + data + "\x1b\\"

        # TODO
        ## If we've never even flushed yet, it means we're still in
        ## the normal buffer. Wait for alt screen buffer.
        #if (this.output.bytesWritten === 0) {
        #	timer = setInterval(function() {
        #		if (self.output.bytesWritten > 0 || ++iterations === 50) {
        #			clearInterval(timer);
        #			self.flush();
        #			self._owrite(data);
        #		}
        #	}, 100);
        #	return true;
        #}

        # NOTE: Flushing the buffer is required in some cases.
        # The DCS code must be at the start of the output.
        flush

        # Write out raw now that the buffer is flushed.
        _owrite data
      end

      _write data
    end

    def _owrite(text : String)
      #return unless @output.writable? # XXX
      @output.print text
    end
    def _owrite(data : Bytes)
      #return unless @output.writable? # XXX
      @output.write data
    end

    def _write(text)
      return text if @ret
      return _buffer(text) if use_buffer?
      _owrite text
    end

    def _buffer(text)
      if @exiting
        flush
        _owrite text
        return
      end

      ## TODO Fix this, then default to use_buffer=true
      #if b = @_buf
      #  #b += text
      #  return
      #end

      #@_buf = text
      flush # XXX Why here

      true
    end

    def flush
      @_buf.try do |buf|
        _owrite buf
        _buf = nil
      end
    end
  end
end
