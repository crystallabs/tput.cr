require "log"
Log.setup_from_env backend: Log::IOBackend.new STDERR

require "term-screen"

require "unibilium"
require "unibilium-shim"
require "crystallabs-helpers"

require "./tput/ext"
require "./tput/macros"
require "./tput/options"
require "./tput/namespace"
require "./tput/keys"
require "./tput/output"
require "./tput/input"
require "./tput/coordinates"
require "./tput/acsc"
require "./tput/features"
require "./tput/emulator"

class Tput
  VERSION = "0.1.0"
  include JSON::Serializable
  include Crystallabs::Helpers::Logging

  DEFAULT_SCREEN_SIZE = Size.new 80, 24 # Opinions vary: 24, 25, 27

  @[JSON::Field(ignore: true)]
  @input : IO

  @[JSON::Field(ignore: true)]
  @output : IO

  @[JSON::Field(ignore: true)]
  @error : IO

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
  #@aliases : Array[String]

  @_title : String = ""

  getter screen : Size
  getter cursor : Point
  getter saved_cursor : Point?

  @[JSON::Field(ignore: true)]
  @_buf = IO::Memory.new

  getter? use_buffer : Bool

  getter? exiting = false

  #@ret = false # Unused. Return data instead of write()ing it?

  getter is_alt = false

  getter scroll_top = 0
  getter scroll_bottom = 0

  include Coordinates

  def initialize(
    @terminfo=nil,
    @input = STDIN,
    @output = STDOUT.dup,
    @error = STDERR.dup,
    force_unicode = nil,
    @use_buffer = true,
    screen_size = nil,
  )

    options = Options.new

    @force_unicode = unless force_unicode.nil?
      force_unicode
    else
      options.force_unicode
    end

    @screen = screen_size || get_screen_size
    @cursor = Point.new

    @name = (@terminfo.try(&.name) || ENV["TERM"]? || "xterm").downcase
    @aliases = (@terminfo.try(&.aliases.map(&.downcase))) || [] of String
    Log.trace { my @name, @aliases }

    @shim = @terminfo.try { |t| Unibilium::Terminfo::Shim.new t }

    @features = Features.new self
    @emulator = Emulator.new self

    Signal::WINCH.trap do
      reset_screen_size
    end
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

  ## Unused. Redirects all output into a variable and returns it
  ## Maybe do with macros, or method_missing to be able to call any
  ## method, or so.
  #def out(args)
  #  ret = Bytes.new
  #  @ret=true
  #  # ret += ...
  #  @ret=false
  #  ret
  #end

  include ACSC
  include Output
  include Input
  
end
