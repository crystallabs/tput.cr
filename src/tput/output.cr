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
    def _tprint(data)

      iterations = 0

      if emulator.tmux?
        # Replace all STs with BELs so they can be nested within the DCS code.
        data = data.gsub /\e\\/, "\x07"

        # Wrap in tmux forward DCS:
        data = "\ePtmux;\e" + data + "\e\\"

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
        _oprint data
      else
        _print data
      end
    end

    # Directly writes string to `@output` (usually STDOUT). 
    #
    # Mostly not used directly, but through `#_write`.
    def _owrite(*args)
      args.map { |arg| @output.write arg }
    end

    def _oprint(*args)
      # https://github.com/crystal-lang/crystal/pull/10152
      args.join io: @output
    end

    def _with_io(&block : IO -> Nil)
      yield @output
    end

    #def _owrite(text : String)
    #  @output.print text
    #end
    ## :ditto:
    #def _owrite(data : Bytes)
    #  @output.write data
    #end
    ## :ditto:
    #def _owrite(data : IO)
    #  @output << data
    #end
    ## :ditto:

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
    def _print(&block : IO -> Nil)
      if use_buffer?
        _buffer_print &block
      else
        _with_io &block
      end
    end

    #def _write(bytes : Bytes)
    #  #return text if @ret
    #  if use_buffer?
    #    _buffer bytes
    #  else
    #    _owrite bytes
    #  end
    #end
    ## :ditto:
    #def _write(str : String)
    #  _write str.to_slice
    #end
    ## :ditto:
    #def _write(&block : IO -> Nil)
    #  if use_buffer?
    #    _buffer &block
    #  else
    #    _owrite &block
    #  end
    #end

    # Standard output method which takes terminal padding (software timing/delays) into account.
    #
    # If no padding/delay instructions are found in the content, the behavior is
    # identical to `#_write`.
    def _pad_write(code, prn = ->_write(Bytes), done = nil)
      raise "Padding not supported yet"
      # tput._print, tput.print
    end

    # Saves `bytes` to local buffer.
    private def _buffer_write(*args) #bytes : Bytes)
      if @exiting
        flush
        return _owrite *args
      end
      # Not needed any more since buf is now an IO rather than slice.
      # Essentially a += operation for Bytes
      #_buf = Bytes.new @_buf.size + bytes.size
      #@_buf.copy_to _buf
      #bytes.copy_to _buf + @_buf.size
      #@_buf = _buf
      #@_buf.write bytes
      args.each { |a| @_buf.write a }
      flush
    end
    private def _buffer_print(*args)
      if @exiting
        flush
        return _oprint *args
      end

      # https://github.com/crystal-lang/crystal/pull/10152
      v = args.join io: @_buf
      flush
      v
    end
    private def _buffer_print(&block : IO -> Nil)
      v = if @exiting
        flush
        _with_io &block
      else
        yield @_buf
      end
      flush
      v
    end
    #private def _buffer(&block : IO -> Nil)
    #  with @_buf yield @_buf
    #  true
    #end

    # Flushes internal buffer into `@output` and calls `@output.flush`
    def flush
      unless @_buf.empty?
        #IO.copy @_buf, @output
        @output << @_buf
        @_buf.clear
        @output.flush
      end
      true
    end
  end
end
