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

    # Wrap escape sequences in DCS sequences and directly print to `@output`.
    #
    # Tmux will only forward escape sequences to the terminal if surrounded by a
    # DCS sequence.
    #
    # This method wraps the output in DCS sequences if the detected terminal
    # emulator is tmux, and then directly prints content to `@output`.
    # (Any existing buffer is first flushed.)
    #
    # If the terminal emulator is not detected to be tmux, the behavior is
    # identical to `#_write`.
    #
    #     Example: `DCS tmux; ESC Pt ST`
    #     Real: `DCS tmux; ESC Pt ESC \`
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
        #if (this.output.bytesWritten === 0)
        #	timer = setInterval(function()
        #		if (self.output.bytesWritten > 0 || ++iterations === 50)
        #			clearInterval(timer)
        #			self.flush()
        #			self._owrite(data)
        #		end
        #	end 100)
        #	return true
        #end

        # NOTE: Flushing the buffer is required in some cases.
        # The DCS code must be at the start of the output.
        flush

        # Write out raw now that the buffer is flushed.
        _owrite data
      else
        _write data
      end
    end

    # Directly writes string to `@output` (usually STDOUT). 
    #
    # Mostly not used directly, but through `#_write`.
    def _owrite(text : String)
      @output.print text
    end
    # :ditto:
    def _owrite(data : Bytes)
      @output.write data
    end
    # :ditto:
    def _owrite(data : IO)
      @output << data
    end
    # :ditto:
    private def _owrite(&block : IO -> Nil)
      with @output yield @output
    end

    # Standard output method.
    #
    # Takes into account internal buffering.
    def _write(bytes : Bytes)
      #return text if @ret
      if use_buffer?
        _buffer bytes
      else
        _owrite bytes
      end
    end
    # :ditto:
    def _write(str : String)
      _write str.to_slice
    end
    # :ditto:
    def _write(&block : IO -> Nil)
      if use_buffer?
        _buffer &block
      else
        _owrite &block
      end
    end

    # Standard output method which takes terminal padding (software timing/delays) into account.
    #
    # If no padding/delay instructions are found in the content, the behavior is
    # identical to `#_write`.
    def _pad_write(code, prn = ->_write(Bytes), done = nil)
      raise "Padding not supported yet"
      # tput._print, tput.print
    end

    # Saves `bytes` to local buffer.
    private def _buffer(bytes : Bytes)
      @_buf.write bytes
      flush
    end

    private def _buffer(&block : IO -> Nil)
      if @exiting
        flush
      end

      # Not needed any more since buf is now an IO rather than slice.
      # Essentially a += operation for Bytes
      #_buf = Bytes.new @_buf.size + bytes.size
      #@_buf.copy_to _buf
      #bytes.copy_to _buf + @_buf.size
      #@_buf = _buf

      with @_buf yield @_buf

      #if @exiting
        flush
      #end

      true
    end

    # Flushes internal buffer into `@output` and calls `@output.flush`
    def flush
      unless @_buf.empty?
        _owrite { |io| io << @_buf }
        @_buf.clear
        @output.flush
      end
    end
  end
end
