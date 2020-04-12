require "terminfo"
require "timer"

require "./macros"
require "./helpers"
require "./terminal"
require "./methods"

# Resources:
#   $ man term
#   $ man terminfo
#   http://invisible-island.net/ncurses/man/term.5.html
#   https://en.wikipedia.org/wiki/Terminfo
#
# Todo:
# - xterm's XT (set-title capability?) value should
#   be true (at least tmux thinks it should).
#   It's not parsed as true. Investigate.
# - Possibly switch to other method of finding the
#   extended data string table: i += h.symOffsetCount * 2

# Class for outputting appropriate terminal escape sequences
module Tput
  VERSION = "0.4.2"

  include ::Tput::Terminal
  include ::Tput::Methods
  include ::Tput::Helpers

  # Controls whether results of string capability functions
  # should be memoized. If enabled, each combination of string
  # capability (capability name) and its arguments creates one
  # cache entry.
  class_property? use_cache : Bool = false

  # :nodoc:
  NO_ARGS = Array(Int16).new

  # DEC Special Character and Line Drawing Set.
  Acsc = {    # (0
    "`" => "\u25c6", # "◆"
    "a" => "\u2592", # "▒"
    "b" => "\u0009", # "\t"
    "c" => "\u000c", # "\f"
    "d" => "\u000d", # "\r"
    "e" => "\u000a", # "\n"
    "f" => "\u00b0", # "°"
    "g" => "\u00b1", # "±"
    "h" => "\u2424", # "\u2424" (NL)
    "i" => "\u000b", # "\v"
    "j" => "\u2518", # "┘"
    "k" => "\u2510", # "┐"
    "l" => "\u250c", # "┌"
    "m" => "\u2514", # "└"
    "n" => "\u253c", # "┼"
    "o" => "\u23ba", # "⎺"
    "p" => "\u23bb", # "⎻"
    "q" => "\u2500", # "─"
    "r" => "\u23bc", # "⎼"
    "s" => "\u23bd", # "⎽"
    "t" => "\u251c", # "├"
    "u" => "\u2524", # "┤"
    "v" => "\u2534", # "┴"
    "w" => "\u252c", # "┬"
    "x" => "\u2502", # "│"
    "y" => "\u2264", # "≤"
    "z" => "\u2265", # "≥"
    "{" => "\u03c0", # "π"
    "|" => "\u2260", # "≠"
    "}" => "\u00a3", # "£"
    "~" => "\u00b7"  # "·"
  }

  # Mapping of ACS unicode characters to the most similar-looking ascii characters.
  Utoa= {
    "\u25c6" => "*", # "◆"
    "\u2592" => " ", # "▒"
    # "\u0009" => "\t", # "\t"
    # "\u000c" => "\f", # "\f"
    # "\u000d" => "\r", # "\r"
    # "\u000a" => "\n", # "\n"
    "\u00b0" => "*", # "°"
    "\u00b1" => "+", # "±"
    "\u2424" => "\n", # "\u2424" (NL)
    # "\u000b" => "\v", # "\v"
    "\u2518" => "+", # "┘"
    "\u2510" => "+", # "┐"
    "\u250c" => "+", # "┌"
    "\u2514" => "+", # "└"
    "\u253c" => "+", # "┼"
    "\u23ba" => "-", # "⎺"
    "\u23bb" => "-", # "⎻"
    "\u2500" => "-", # "─"
    "\u23bc" => "-", # "⎼"
    "\u23bd" => "_", # "⎽"
    "\u251c" => "+", # "├"
    "\u2524" => "+", # "┤"
    "\u2534" => "+", # "┴"
    "\u252c" => "+", # "┬"
    "\u2502" => "|", # "│"
    "\u2264" => "<", # "≤"
    "\u2265" => ">", # "≥"
    "\u03c0" => "?", # "π"
    "\u2260" => "=", # "≠"
    "\u00a3" => "?", # "£"
    "\u00b7" => "*"  # "·"
  }

  Angles = {
    "\u2518": true, # "┘"
    "\u2510": true, # "┐"
    "\u250c": true, # "┌"
    "\u2514": true, # "└"
    "\u253c": true, # "┼"
    "\u251c": true, # "├"
    "\u2524": true, # "┤"
    "\u2534": true, # "┴"
    "\u252c": true, # "┬"
    "\u2502": true, # "│"
    "\u2500": true  # "─"
  }

  Langles = {
    "\u250c": true, # "┌"
    "\u2514": true, # "└"
    "\u253c": true, # "┼"
    "\u251c": true, # "├"
    "\u2534": true, # "┴"
    "\u252c": true, # "┬"
    "\u2500": true  # "─"
  }

  Uangles = {
    "\u2510": true, # "┐"
    "\u250c": true, # "┌"
    "\u253c": true, # "┼"
    "\u251c": true, # "├"
    "\u2524": true, # "┤"
    "\u252c": true, # "┬"
    "\u2502": true  # "│"
  }

  Rangles = {
    "\u2518": true, # "┘"
    "\u2510": true, # "┐"
    "\u253c": true, # "┼"
    "\u2524": true, # "┤"
    "\u2534": true, # "┴"
    "\u252c": true, # "┬"
    "\u2500": true  # "─"
  }

  Dangles = {
    "\u2518": true, # "┘"
    "\u2514": true, # "└"
    "\u253c": true, # "┼"
    "\u251c": true, # "├"
    "\u2524": true, # "┤"
    "\u2534": true, # "┴"
    "\u2502": true  # "│"
  }

  Cdangles = {
    "\u250c": true  # "┌"
  }

  # Every ACS angle character can be
  # represented by 4 bits ordered like this:
  # [langle][uangle][rangle][dangle]
  AngleTable = {
    "0000": "", # ?
    "0001": "\u2502", # "│" # ?
    "0010": "\u2500", # "─" # ??
    "0011": "\u250c", # "┌"
    "0100": "\u2502", # "│" # ?
    "0101": "\u2502", # "│"
    "0110": "\u2514", # "└"
    "0111": "\u251c", # "├"
    "1000": "\u2500", # "─" # ??
    "1001": "\u2510", # "┐"
    "1010": "\u2500", # "─" # ??
    "1011": "\u252c", # "┬"
    "1100": "\u2518", # "┘"
    "1101": "\u2524", # "┤"
    "1110": "\u2534", # "┴"
    "1111": "\u253c", # "┼"
    # Same as above, but as keys as ints.
    # XXX I think the above ones aren't even needed.
    "0": "", # ?
    "1": "\u2502", # "│" # ?
    "2": "\u2500", # "─" # ??
    "3": "\u250c", # "┌"
    "4": "\u2502", # "│" # ?
    "5": "\u2502", # "│"
    "6": "\u2514", # "└"
    "7": "\u251c", # "├"
    "8": "\u2500", # "─" # ??
    "9": "\u2510", # "┐"
    "10": "\u2500", # "─" # ??
    "11": "\u252c", # "┬"
    "12": "\u2518", # "┘"
    "13": "\u2524", # "┤"
    "14": "\u2534", # "┴"
    "15": "\u253c", # "┼"
  }

  # Instance of `Terminfo::Data`
  getter terminfo : ::Terminfo::Data
  # Does the terminal use unicode?
  getter? use_unicode  : Bool
  # Use sprintf?
  property? use_printf : Bool
  property? use_buffer : Bool
  property? zero_based : Bool
  # Is ACS broken?
  getter? has_broken_acs   : Bool
  getter? has_pcrom_set    : Bool
  getter? has_magic_cookie : Bool
  # Use padding?
  getter? use_padding  : Bool
  # Use setbuf?
  getter? setbuf       : Bool

  # ASCII chars to ACS chars
  getter acsc : Hash(String,String)
  # ACS chars to ASCII chars
  getter acscr : Hash(String,String)

  # Joined list of regular and extended Terminfo booleans
  getter booleans : Hash(String,Bool)
  # Joined list of regular and extended Terminfo numbers
  getter numbers  : Hash(String,Int16)
  # Joined list of regular and extended Terminfo strings
  getter strings  : Hash(String,String)

  # A collection of string capability methods. Each capability
  # accepts an Array(Int16) and returns a string.
  getter methods  : Hash(String, Proc(Array(Int16), String))

  property? use_cache : Bool = true
  getter? cursor_hidden : Bool = false
  getter? alt_screen : Bool = false

  getter _saved = Hash(String, NamedTuple(x: Int32, y: Int32, hidden: Bool)).new

  getter input : IO::FileDescriptor
  getter output : IO::FileDescriptor

  # Internal cache for string functions. When a certain string
  # capability method is called (with any needed arguments),
  # the result is memoized in @cache if `use_cache?` is *true*.
  @cache = Hash(UInt64,String).new

  @_exiting = false
  @_buf : String? = nil
  @_title = ""

  # TODO
  #_flush = flush func

  getter x : Int32 = 0
  getter y : Int32 = 0
  getter saved_x : Int32 = 0
  getter saved_y : Int32 = 0
  getter scroll_top : Int32
  getter scroll_bottom : Int32

  getter cols : Int32
  getter rows : Int32

  # Don't write to term but return what would be written
  @ret = false

  delegate name, names, description, to: @terminfo

  def initialize(
    term : String? = nil,
    terminfo : String? = nil,
    builtin : String? = nil,

    use_padding = nil,
    extended = true,
    @use_buffer = true,
    @zero_based = true,
    @use_cache = ::Tput.use_cache?,
    use_unicode = nil,
    @use_printf = true,
    #force_unicode =
    @input = STDIN,
    @output = STDOUT,
   )

    # This tries to detect the actual terminal emulator program,
    # not the term/terminfo type.
    detect_term_program

    @terminfo = begin
      if terminfo
        ::Terminfo::Data.new path: terminfo, extended: extended
      elsif term
        ::Terminfo::Data.new term: term, extended: extended
      elsif builtin
        ::Terminfo::Data.new builtin: builtin, extended: extended
      else
        ::Terminfo::Data.new extended: extended
      end
    rescue
      begin
        if term
          ::Terminfo::Data.new builtin: term, extended: extended
        else
          raise Exception.new
        end
      rescue
        ::Terminfo::Data.new builtin: "xterm", extended: extended
      end
    end

    # TODO have it here like this or always read real value?
    # What happens when we receive WINCH?
    @cols = ::Tput.cols
    @rows = ::Tput.rows

    @scroll_top = 0
    @scroll_bottom = @rows - 1

    @booleans = @terminfo.booleans.merge @terminfo.extended_booleans
    @numbers  = @terminfo.numbers.merge  @terminfo.extended_numbers
    @strings  = @terminfo.strings.merge  @terminfo.extended_strings

    @methods = generate_methods

    # Make terminfo and termcap names, and any additional aliases,
    # be the same as full/unabbreviated capability names.
    ::Terminfo::Booleans.each do |name|
      @booleans[name] = false unless @booleans.has_key? name
      ::Terminfo::Alias::Booleans[name]?.try &.each do |short|
        @booleans[short] = @booleans[name]
      end
    end
    ::Terminfo::Numbers.each do |name|
      @numbers[name] = -1 unless @numbers.has_key? name
      ::Terminfo::Alias::Numbers[name]?.try &.each do |short|
        @numbers[short] = @numbers[name]
      end
    end
    ::Terminfo::Strings.each do |name|
      @strings[name] = "" unless @strings.has_key? name
      # Reverse is here so that terminfo names would override termcap names,
      # in (any?) rare case of naming conflicts.
      ::Terminfo::Alias::Strings[name]?.try &.reverse_each do |short|
        @strings[short] = @strings[name]
        @methods[short] = @methods[name]
      end
    end

    # Terminal specifics:
    @use_unicode      = use_unicode.nil? ? detect_unicode : use_unicode
    @has_broken_acs   = detect_broken_acs
    @has_pcrom_set    = detect_pcrom_set
    @has_magic_cookie = detect_magic_cookie
    @use_padding      = use_padding || detect_padding
    @setbuf           = detect_setbuf # Not used
    @acsc, @acscr     = parse_acs

    if @use_padding
      STDERR.puts "Padding has been enabled."
    end

    #write = _write.bind
  end

  # Creates Procs around all string capabilities.
  def generate_methods(info=@terminfo)
    info.strings.map do |k, v| {k, capability_to_method(info, k, v)} end.to_h
  end

  # Converts terminfo string definition into a Proc.
  def capability_to_method(info,key,data : String)
    # TODO this gets called with init_file '\u0005\e[Z'  instead of filename?
    #if key=="init_file" || key=="reset_file"
    #  #begin
    #    str = File.read data
    #    return ->(arguments : Array(Int16)) {str}
    #  #rescue
    #  #  return ->noop
    #  #end
    #end

    ->(arguments : Array(Int16)) {
      pos = 0
      stack = Array(Int16).new
      String.build do |s|
        while i = data.index '%', pos
          len = 2
          s << data[pos...i]
          case data[i+1]
            when '%'
              s << '%'
            when 'i'
              arguments[0] += 1 if arguments[0]?
              arguments[1] += 1 if arguments[1]?
            when 'p'
              stack.push arguments[data[i+2].to_i-1]
              len += 1
            when 'd'
              s << stack.map(&.to_s).join ""
              stack.clear
            else
              raise Exception.new "Unsupported sequence %#{data[i+i]} in #{key}'s definition 'data.inspect'"
          end
          pos = i + len
        end
        s << data[pos..-1]
      end
    }
  end

  # Checks whether terminal feature exists.
  def has(name)
    if @booleans.has_key? name
      @booleans[name]
    elsif @numbers.has_key? name
      @numbers[name] != -1
    else
      @strings[name] != ""
    end
  end

  ##########################

  def _owrite(text)
    # TODO
    #return unless @output.writable?
    @output.write text.to_slice
  end
  alias_previous write

  def _write(text)
    return text if @ret
    return _buffer(text) if @use_buffer
    _owrite text
  end

  # Example: `DCS tmux; ESC Pt ST`
  # Real: `DCS tmux; ESC Pt ESC \`
  def _twrite(data)
    iterations = 0
    timer = nil

    if tmux?
      # Replace all STs with BELs so they can be nested within the DCS code.
      data = data.gsub /\x1b\\/, "\x07"

      # Wrap in tmux forward DCS:
      data = "\x1bPtmux;\x1b" + data + "\x1b\\"

      # If we've never even flushed yet, it means we're still in
      # the normal buffer. Wait for alt screen buffer.
      # TODO
      #if @output.bytes_written == 0
      #  50.times do
      #    sleep 0.1
      #    if @output.bytes_written > 0
      #      break
      #    end
      #  end
      #end

      # NOTE: Flushing the buffer is required in some cases.
      # The DCS code must be at the start of the output.
      flush

      # Write out raw now that the buffer is flushed.
      return _owrite data
    end

    _write data
  end

  def print(txt, attr=nil)
    attr ? _write(text(txt, attr)) : _write(txt)
  end
  alias_previous echo

  ##########################

  # Prints term/console escape sequence *name* invoked with any *arguments*.
  def put(name, *arguments)
    if @use_cache
      hash = {name, arguments}.hash
      return write @cache[hash] if @cache.has_key? hash
    end

    a = arguments.map(&.to_i16).to_a

    if !(@methods.has_key? name)
      return
    end

    ret = if a.is_a? Array(Int16)
      @methods[name].call a
    else
      @methods[name].call NO_ARGS
    end

    if @use_cache
      @cache[hash.not_nil!] = ret
    end

    write ret
  end

  def _buffer(text)
    if @_exiting
      flush
      _owrite(text)
      return
    end

    # TODO
    if text.is_a? Slice(UInt8)
      p "TEXT IS SLICE"
    end
    #@_buf.try do |buf|
    #  buf += text
    #  return
    #end

    #@_buf = text
    #flush # XXX _flush

    true
  end

  def flush
    @_buf.try do |buf|
      return if buf.empty? # XXX Needed?
      _owrite(buf)
      @_buf = nil
    end
  end

  ##########################

  # Parses terminal's ACS characters and returns
  # ASCII->ACS and ACS->ASCII mappings.
  def parse_acs
    acsc = {} of String => String
    acscr = {} of String => String

    if detect_pcrom_set @terminfo
      return acsc, acscr
    end

    acs_chars = @terminfo.strings["acs_chars"]? || ""
    Acsc.each do |ch, _|
      i = acs_chars.index ch

      if i.nil?
        next
      end

      nxt = acs_chars[(i+1)..(i+1)]?

      if !nxt || !Acsc[nxt]?
        next
      end

      acsc[ch] = Acsc[nxt]
      acscr[Acsc[nxt]] = ch
    end

    return acsc, acscr
  end

  # :nodoc:
  def noop
    ""
  end
  # :nodoc:
  def noop(a : Array(Int16))
    ""
  end

  # Writes content to process' STDOUT
  def write(data)
    # XXX this writes to process' stdout. Is it expected
    # that it avoids @program's functions for it, and its
    # buffering?
    STDOUT.write data.to_slice
  end
  alias_previous _write

  # Feature/quirk detection methods

  # Detects whether terminal is using unicode.
  def detect_unicode(info=@terminfo)
    if to_bool ENV["NCURSES_FORCE_UNICODE"]?
      return true
    end
    str = [ ENV["LANG"]?, ENV["LANGUAGE"]?, ENV["LC_ALL"]?, ENV["LC_CTYPE"]? ].join ':'
    str =~ /utf\-?8/i ? true : false # TODO || (get_console_cp == 65001)
  end

  # Detects whether terminal has broken ACS.
  def detect_broken_acs(info=@terminfo)
    # For some reason TERM=linux has smacs/rmacs, but it maps to `^[[11m`
    # and it does not switch to the DEC SCLD character set. What the hell?
    # xterm: \x1b(0, screen: \x0e, linux: \x1b[11m (doesn't work)
    # `man console_codes` says:
    # 11  select null mapping, set display control flag, reset tog‐
    #     gle meta flag (ECMA-48 says "first alternate font").
    # See ncurses:
    # ~/ncurses/ncurses/base/lib_set_term.c
    # ~/ncurses/ncurses/tinfo/lib_acs.c
    # ~/ncurses/ncurses/tinfo/tinfo_driver.c
    # ~/ncurses/ncurses/tinfo/lib_setup.c

    # ncurses-compatible env variable.
    if to_bool ENV["NCURSES_NO_UTF8_ACS"]?, false
      return true
    end

    # If the terminal supports unicode, we don't need ACS.
    if @numbers["U8"]?.try &.>= 0
      return to_bool @numbers["U8"]
    end

    # The linux console is just broken for some reason.
    # Apparently the Linux console does not support ACS,
    # but it does support the PC ROM character set.
    if name == "linux"
      return true
    end

    # PC alternate charset
    # if (acsc.indexOf('+\x10,\x11-\x18.\x190') === 0) {
    if detect_pcrom_set
      return true
    end

    false
  end

  def detect_pcrom_set(info=@terminfo)
    # If enter_pc_charset is the same as enter_alt_charset,
    # the terminal does not support SCLD as ACS.
    # See: ~/ncurses/ncurses/tinfo/lib_acs.c

    s = info.strings
    if (s["enter_pc_charset_mode"] != "" && s["enter_alt_charset_mode"] != "" &&
        (s["enter_pc_charset_mode"] == s["enter_alt_charset_mode"]) &&
        (s["exit_pc_charset_mode"] == s["exit_alt_charset_mode"]))
      return true
    end
    false
  end

  def detect_magic_cookie(info=@terminfo)
    to_bool ENV["NCURSES_NO_MAGIC_COOKIE"]?, false
  end

  def detect_padding(info=@terminfo)
    to_bool ENV["NCURSES_NO_PADDING"]?, false
  end

  def detect_setbuf(info=@terminfo)
    to_bool ENV["NCURSES_NO_SETBUF"]?, false
  end

  # Prints to terminal.
  def _print(code, prnt=nil, done=->(){})
    xon = !@booleans["needs_xon_xoff"] || @booleans["xon_xoff"]

    prnt = prnt || ->write(String)
    done = done || ->noop

    if !@use_padding
      prnt.call code
      return done.call
    end

    parts = code.split(/(?=\$<[\d.]+[*\/]{0,2}>)/)
    i = 0

     nxt = uninitialized -> Bool | Int32 | Nil
     nxt =  ->() {
      if i == parts.size
        return done.call
      end

      part = parts[i]
      i+=1
      padding = /^\$<([\d.]+)([*\/]{0,2})>/.match part
      #amount
      #suffix;
      #affect;

      if padding.nil?
        prnt.call part
        return nxt.call
      end

      part = part[padding[0].size..]
      amount = padding[1].to_i
      suffix = padding[2]

      # A `/'  suffix indicates  that  the  padding  is  mandatory and forces a
      # delay of the given number of milliseconds even on devices for which xon
      # is present to indicate flow control.
      if xon && !suffix.index('/')
        prnt.call part
        return nxt.call
      end

      ## A `*' indicates that the padding required is proportional to the number
      ## of lines affected by the operation, and  the amount  given  is the
      ## per-affected-unit padding required.  (In the case of insert character,
      ## the factor is still the number of lines affected.) Normally, padding is
      ## advisory if the device has the xon capability; it is used for cost
      ## computation but does not trigger delays.
      #if suffix.index('*')
      #  #amount = amount
      #  # XXX Disable this for now.
      #  ## if (affect = /\x1b\[(\d+)[LM]/.exec(part)) {
      #  ##   amount *= +affect[1];
      #  ## }
      #  ## The above is a huge workaround. In reality, we need to compile
      #  ## `_print` into the string functions and check the cap name and
      #  ## params.
      #  ## if (cap === 'insert_line' || cap === 'delete_line') {
      #  ##   amount *= params[0];
      #  ## }
      #  ## if (cap === 'clear_screen') {
      #  ##   amount *= process.stdout.rows;
      #  ## }
      #end

      raise Exception.new "Not implemented yet"
      return Timer.new(amount) {
        # TODO
        # This print should be executed with:
        # padding: true, needs_xon_xoff: true, xon_xoff: false
        prnt.call part
        return nxt.call
      }
    }
    nxt.call
  end

  # Represents complete tput class.
  #
  # This class should be used when a Tput class is preferred
  # over using a module.
  class Data
    include ::Tput
  end

  # Returns number of columns.
  #
  # Currently this uses ENV variables. For it to work, variable COLUMNS must be
  # exposed to environment with `declare -X COLUMNS` or `export COLUMNS`.
  # As such, it is effectively broken.
  #
  # Maybe it could issue `stty size` or `tput cols/lines`.
  # Or do something like https://github.com/crystal-lang/crystal/issues/2061
  def self.cols
    if ENV["COLUMNS"]?.nil?
      STDERR.puts "For now, please run 'export LINES COLUMNS' or 'declare -x LINES COLUMNS' before starting."
    end
    (ENV["COLUMNS"]?.try(&.to_i) || 1)
  end
  alias_method columns, cols

  # Returns number of lines.
  #
  # Currently this uses ENV variables. For it to work, variable LINES must be
  # exposed to environment with `declare -X LINES` or `export LINES`.
  # As such, it is effectively broken.
  #
  # Maybe it could issue `stty size` or `tput cols/lines`.
  # Or do something like https://github.com/crystal-lang/crystal/issues/2061
  def self.rows
    if ENV["LINES"]?.nil?
      STDERR.puts "For now, please run 'export LINES COLUMNS' or 'declare -x LINES COLUMNS' before starting."
    end
    (ENV["LINES"]?.try(&.to_i) || 1)
  end
  alias_method lines, rows
end
