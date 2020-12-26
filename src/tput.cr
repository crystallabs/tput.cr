require "log"
Log.setup_from_env

require "term-screen"

require "unibilium"
require "unibilium-shim"
require "crystallabs-helpers"
require "event_handler"

require "./macros"
require "./namespace"
require "./output"
require "./coordinates"
require "./data"
require "./features"
require "./emulator"
require "./events"

class Tput
  VERSION = "0.1.0"
  #include JSON::Serializable
  include Crystallabs::Helpers::Logging

  DEFAULT_SCREEN_SIZE = {24, 80} # Opinions vary: 24, 25, 27

  @[JSON::Field(ignore: true)]
  @input : IO
  @[JSON::Field(ignore: true)]
  @output : IO
  @[JSON::Field(ignore: true)]
  @error : IO

  @[JSON::Field(ignore: true)]
  getter? force_unicode

  @[JSON::Field(ignore: true)]
  getter terminfo : Unibilium::Terminfo?

  @[JSON::Field(ignore: true)]
  getter shim : Unibilium::Terminfo::Shim?

  getter! features : Features
  getter! emulator : Emulator

  @name : String
  #@aliases : Array[String]

  @_title : String?

  @screen_size : Size
  @position : Point

  @ret = false

  @[JSON::Field(ignore: true)]
  @_buf : Bytes? = nil

  getter? use_buffer : Bool

  getter? exiting = false

  include Coordinates

  def initialize(
    @terminfo=nil,
    @input = STDIN,
    @output = STDOUT,
    @error = STDERR,
    @force_unicode = false,
    @use_buffer = false,
  )
    @screen_size = get_screen_size
    @position = Point.new

    @name = (@terminfo.try(&.name) || ENV["TERM"]? || "xterm").downcase
    @aliases = (@terminfo.try(&.aliases.map(&.downcase))) || [] of String
    Log.trace { "Terminfo: #{@name.inspect} (#{@aliases.inspect})" }

    @shim = @terminfo.try { |t| Unibilium::Terminfo::Shim.new t }

    @features = Features.new self
    @emulator = Emulator.new self

    #Log.trace { to_json }
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

  # TODO -> redirects all output into a variable and returns it
  # Maybe do with macros, or method_missing to be able to call any
  # method, or so.
  def out(args)
    ret = Bytes.new
    @ret=true
    # ret += ...
    @ret=false
    ret
  end

  include Namespace
  include Data
  include Output
  include Events
  
end
