require "log"
Log.setup_from_env backend: Log::IOBackend.new STDERR

require "term-screen"

require "unibilium"
require "unibilium-shim"
require "crystallabs-helpers"

require "./tput/config"

require "./tput/ext"
require "./tput/macros"
require "./tput/namespace"
require "./tput/keys"
require "./tput/mouse"
require "./tput/output"
require "./tput/input"
require "./tput/coordinates"
require "./tput/acsc"
require "./tput/features"
require "./tput/emulator"
require "./tput/probe"
require "./tput/response"
require "./tput/dump"

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
#     ESC - Sequence starting with ESC (\e)
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
#     Pm: A multiple numeric parameter composed of any number of single numeric parameters, separated by ";", e.g. ` Ps ; Ps ; … `.
#     Pt: A text parameter composed of printable characters.
#
# In all of the examples above, spaces exist just for clarity and are not part of actual escape
# sequences. For example, in "ESC [" or " Ps ; Ps ;" there are no actual spaces.
class Tput
  VERSION = "1.0.8"
  include Namespace
  include JSON::Serializable
  include Crystallabs::Helpers::Logging

  ESC  = "\e"
  CSI7 = "\e["
  CSI8 = "\x9b"
  DCS7 = "\eP"
  DCS8 = "\x90"
  OSC7 = "\e]"
  OSC8 = "\x9d"

  DEFAULT_SCREEN_SIZE = Size.new 80, 24 # Opinions vary: 24, 25, 27

  @[JSON::Field(ignore: true)]
  property input : IO

  @[JSON::Field(ignore: true)]
  property output : IO

  @[JSON::Field(ignore: true)]
  property error : IO

  @[JSON::Field(ignore: true)]
  @mode : LibC::Termios? = nil

  @[JSON::Field(ignore: true)]
  getter? force_unicode

  @[JSON::Field(ignore: true)]
  getter terminfo : Unibilium?

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

  # Internal cursor-save state. Keys can be Symbol/UInt64, which aren't valid
  # JSON object keys, so it's excluded from serialization.
  @[JSON::Field(ignore: true)]
  property _saved = Hash(String | Symbol | UInt64, CursorState).new

  @[JSON::Field(ignore: true)]
  @_buf = IO::Memory.new

  getter? use_buffer : Bool

  property? _exiting = false

  # Whether xterm mouse reporting is currently enabled (tracked by
  # `#enable_mouse`/`#disable_mouse`). Used by `#pause` to restore it on resume.
  getter? mouse_enabled = false

  @[JSON::Field(ignore: true)]
  property ret : IO? = nil

  getter is_alt = false

  getter scroll_top = 0
  getter scroll_bottom = 0

  # Resume continuation set by `#pause` and invoked by `#resume`.
  @[JSON::Field(ignore: true)]
  @_resume : Proc(Nil)? = nil

  # Last reported cursor position (parsed from a DSR response), used by
  # `#restore_reported_cursor`.
  @_rx : Int32? = nil
  @_ry : Int32? = nil

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
  @[JSON::Field(ignore: true)]
  getter read_timeout : Time::Span = Superconf.tput_read_timeout

  include Coordinates

  def initialize(
    @terminfo = nil,
    @input = STDIN,
    # NOTE: not `.dup` — `Object#dup` shallow-copies the IO and aliases the same
    # fd with close_on_finalize=true; the discarded alias closes the shared fd on
    # GC, causing spurious EBADF ("File not open for ...") errors. Use the std
    # stream directly (a single, never-collected global).
    @output = STDOUT,
    @error = STDERR,
    force_unicode = nil,
    @use_buffer = Superconf.tput_use_buffer,
    screen_size = nil,
    probe = Superconf.tput_probe,
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

    # Augment the static (ENV/terminfo) detection above with live probing:
    # round-trip a batch of query sequences and read the terminal's replies.
    # Only runs when attached to a real terminal; safely skipped for pipes,
    # files, and test doubles.
    probe! if probe && probe_capable?
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

  def has?(&)
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
  def put(&)
    @shim.try { |s|
      yield(s).try { |data|
        features.padding? ? _pad_write(data) : _write(data)
      }
    }
  end

  # Like `#put`, but resolves a *user-defined* (extended) string capability by
  # name and runs it with the given arguments.
  #
  # The predefined Terminfo capabilities are exposed via the shim (and used
  # through `#put`), but capabilities such as `Cr` (reset cursor color),
  # `Cs` (set cursor color) or `Ms` (store data in the clipboard) live outside
  # that set and are only present as terminfo *extensions*. This looks one up
  # by name, formats it with *args*, and writes the result.
  #
  # Returns `true` if the capability existed and was written, `nil`/`false`
  # otherwise (no Terminfo data, or the extension is not defined).
  #
  # ```
  # put_extended "Cr"          # reset cursor color, if the terminal defines Cr
  # put_extended "Cs", "white" # set cursor color
  # ```
  def put_extended(name : String, *args)
    @terminfo.try { |ti|
      ti.extensions.get_str?(name).try { |cap|
        data = ti.run(cap, *args)
        features.padding? ? _pad_write(data) : _write(data)
        true
      }
    }
  end

  # Suspends the program's use of the terminal: saves the cursor, leaves the
  # alternate buffer, shows the cursor, disables mouse reporting, and returns
  # the input to cooked mode — leaving the terminal usable by another program
  # (a shell, `$EDITOR`, …). Returns — and stores in `@_resume` — a continuation
  # that `#resume` (or `#sigtstp`'s `SIGCONT` handler) invokes to restore
  # everything.
  #
  # The caller must not emit output between `#pause` and `#resume`; the dominant
  # use (`#sigtstp`) suspends the whole process, so this is automatic there.
  def pause(callback : Proc? = nil) : Proc(Nil)
    alt = is_alt
    mouse = mouse_enabled?

    lsave_cursor :pause
    disable_mouse if mouse
    normal_buffer if alt
    show_cursor

    # Make sure the restore sequences actually reach the terminal before we
    # hand it back to cooked mode.
    flush
    suspend_raw_input

    @_resume = -> {
      @_resume = nil
      restore_raw_input

      alternate_buffer if alt
      enable_mouse if mouse
      lrestore_cursor :pause, true
      callback.try &.call
    }
  end

  def resume
    @_resume.try &.call
  end

  # Restores the terminal to the state it was in before the program took it
  # over: shows the cursor, leaves the alternate buffer, disables mouse
  # reporting, and returns the input to cooked mode. Intended for clean
  # teardown on exit. (Listener/instance bookkeeping is the caller's concern.)
  def restore_terminal : Nil
    disable_mouse if mouse_enabled?
    normal_buffer if is_alt
    show_cursor
    flush
    suspend_raw_input
  end

  # Captures the escape sequences emitted by the calls made inside the block
  # and returns them as a `String`, instead of writing them to the terminal.
  #
  # This is the equivalent of Blessed's `Program#out(name, *args)` dispatcher.
  # Crystal has no by-name dynamic dispatch (and `out` is a reserved word), so
  # a block is used instead:
  #
  # ```
  # seq = tput.capture &.cursor_pos(1, 2) # => "\e[2;3H"
  # # or:
  # seq = tput.capture { |t| t.cursor_pos 1, 2; t.bell }
  # ```
  #
  # Output is captured regardless of internal buffering, by temporarily
  # redirecting `@output`. Anything already buffered is flushed to the real
  # output first, so only what the block emits is captured.
  def capture(&) : String
    flush

    saved_output = @output
    saved_ret = @ret
    io = IO::Memory.new
    @output = io
    @ret = nil
    begin
      yield self
      flush
    ensure
      @output = saved_output
      @ret = saved_ret
    end

    io.to_s
  end

  include ACSC
  include Output
  include Input
  include Probe
  include Response
end
