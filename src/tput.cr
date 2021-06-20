require "log"
Log.setup_from_env backend: Log::IOBackend.new STDERR

require "term-screen"

require "unibilium"
require "unibilium-shim"
require "crystallabs-helpers"

require "./tput/ext"
require "./tput/macros"
require "./tput/namespace"
require "./tput/keys"
require "./tput/output"
require "./tput/input"
require "./tput/coordinates"
require "./tput/acsc"
require "./tput/features"
require "./tput/emulator"

# Many Tput methods correspond to terminal sequences. Often times methods are named
# according to their purpose, and then aliased to the names of sequences used behind
# the scenes.
#
# For example, method `#delete_columns` is directly implemented using sequence `decdc`.
# Therefore, it is also accessible under the alias `#decdc`.
#
# Furthermore, for understanding the instructions on terminal sequences, the following
# names are important:
#
#     ESC - Sequence starting with ESC (\x1b)
#     CSI - Control Sequence Introducer: sequence starting with ESC [ (7bit) or CSI (\x9B, 8bit)
#     DCS - Device Control String: sequence starting with ESC P (7bit) or DCS (\x90, 8bit)
#     OSC - Operating System Command: sequence starting with ESC ] (7bit) or OSC (\x9D, 8bit)
#     C0: single byte command (7bit control codes, byte range \x00 .. \x1F, \x7F)
#     C1: single byte command (8bit control codes, byte range \x80 .. \x9F)
#
# Some sequences accept arguments. Their naming and types correspond to those used in
# XTerm documentation:
#
#     Ps: A single (usually optional) numeric parameter, composed of one or more decimal digits.
#     Pm: A multiple numeric parameter composed of any number of single numeric parameters, separated by ; character(s), e.g. ` Ps ; Ps ; … `.
#     Pt: A text parameter composed of printable characters.
#
# In all of the examples above, spaces exist just for clarity and are not part of actual escape
# sequences. For example, in "ESC [" or " Ps ; Ps ;" there are no actual spaces.
class Tput
  VERSION = "1.0.1"
  include Namespace
  include JSON::Serializable
  include Crystallabs::Helpers::Logging

  ESC  = "\x1b"
  CSI7 = "\x1b["
  CSI8 = "\x9b"
  DCS7 = "\x1bP"
  DCS8 = "\x90"
  OSC7 = "\x1b]"
  OSC8 = "\x9d"

  DEFAULT_SCREEN_SIZE = Size.new 80, 24 # Opinions vary: 24, 25, 27

  @[JSON::Field(ignore: true)]
  property input : IO::FileDescriptor

  @[JSON::Field(ignore: true)]
  property output : IO::FileDescriptor

  @[JSON::Field(ignore: true)]
  property error : IO::FileDescriptor

  @[JSON::Field(ignore: true)]
  @mode : LibC::Termios? = nil

  @[JSON::Field(ignore: true)]
  getter? force_unicode

  @[JSON::Field(ignore: true)]
  getter terminfo : Unibilium::Terminfo?

  @[JSON::Field(ignore: true)]
  getter shim : Unibilium::Terminfo::Shim?

  getter! features : Features
  getter! emulator : Emulator

  getter? cursor_hidden : Bool = false

  getter? force_unicode : Bool

  @name : String
  # @aliases : Array[String]

  getter _title : String = ""

  getter screen : Size
  getter cursor : Point
  getter saved_cursor : Point?

  property _saved = Hash(String | Symbol | UInt64, CursorState).new

  @[JSON::Field(ignore: true)]
  @_buf = IO::Memory.new

  getter? use_buffer : Bool

  property? _exiting = false

  property ret : IO? = nil

  getter is_alt = false

  getter scroll_top = 0
  getter scroll_bottom = 0

  # Timeout when reading escape sequences. If an escape sequence (ESC)
  # comes in on input, we have no way of telling whether this is an
  # ESC key or the start of an escape sequence.
  # So we read with a timeout. If there is no input by the time it
  # times out, we consider it was a key press.
  #
  # All other apps like Vi
  # etc. read the escape key in the terminal this way.
  #
  # The default timeout is 400 milliseconds, the same as in Qt.
  getter read_timeout : Time::Span = 400.milliseconds

  include Coordinates

  def initialize(
    @terminfo = nil,
    @input = STDIN,
    @output = STDOUT.dup,
    @error = STDERR.dup,
    force_unicode = nil,
    @use_buffer = true,
    screen_size = nil
  )

    @force_unicode = true

    @screen = screen_size || get_screen_size
    @cursor = Point.new

    @name = (@terminfo.try(&.name) || ENV["TERM"]? || "xterm").downcase
    @aliases = (@terminfo.try(&.aliases.map(&.downcase))) || [] of String
    Log.trace { my @name, @aliases }

    @shim = @terminfo.try { |t| Unibilium::Terminfo::Shim.new t }

    @features = Features.new self
    @emulator = Emulator.new self
  end

  def sigtstp(callback)
    r = pause
    Signal::CONT.trap do
      Signal::CONT.ignore
      r.call
      callback.try &.call
    end

    Process.signal Signal::TSTP, 0
  end

  def name?(nam : String)
    # Aliases are checked first because aliases[0] is what we consider *the*
    # emulator name.
    # XXX possibly turn the check into /(word)\b/, so that it matches e.g.
    # xterm and xterm-256color, but not xterminator.
    return true if @aliases.any? &.starts_with?(nam)
    @name.starts_with? nam
  end

  def name?(*names)
    names.any? { |name| name? name }
  end

  def has?
    @shim.try { |s| yield(s) ? true : false }
  end

  # Outputs a string capability to the designated `@output`, if
  # the capability exists.
  #
  # For this method to work, the Tput instance needs to be
  # initialized with Terminfo data. If Terminfo data is not
  # present, nil will be returned.
  #
  # ```
  # put &.smcup?
  #
  # put &.cursor_pos?(10, 20)
  # ```
  def put
    @shim.try { |s|
      yield(s).try { |data|
        features.padding? ? _pad_write(data) : _write(data)
      }
    }
  end

  def pause(callback : Proc? = nil)
    alt = is_alt
    mouse = false # mouse_enabled? # XXX

    # We should do something else here.
    # Paused program should block writes rather than send them to null.

    lsave_cursor :pause
    normal_buffer if alt
    show_cursor
    # XXX
    # if mouse
    #  disable_mouse
    # end

    # XXX
    # wr = @output.write
    # @output.write = nothing
    # if @input.set_raw_mode
    #  @input.set_raw_mode false
    # end
    # @input.pause

    @_resume = ->{
      @_resume = nil

      # XXX No support yet.
      # @input.set_raw_mode true
      # @input.resume
      # @output.write = write

      alternate_buffer if alt
      # D O:
      # csr 0, @screen.height - 1
      # XXX no support yet
      # if mouse
      #  enable_mouse
      # end

      lrestore_cursor :pause, true
      callback.try &.call
    }
  end

  def resume
    @_resume.try &.call
  end

  # # Unused. Redirects all output into a variable and returns it
  # # Maybe do with macros, or method_missing to be able to call any
  # # method, or so.
  # def out(args)
  #  ret = Bytes.new
  #  @ret=true
  #  # ret += ...
  #  @ret=false
  #  ret
  # end

  include ACSC
  include Output
  include Input
end
