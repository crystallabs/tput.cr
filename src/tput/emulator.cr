require "json"
require "crystallabs-helpers"

class Tput
  # Class for terminal emulator program detection.
  #
  # The detection is always just a best-effort because it relies on testing environment
  # variables, and these are passed from processes to children. (I.e. if a person opens
  # an xterm, then an lxterminal in it, xterm-specific environment variables will propagate
  # to lxterm, confusing the detection.
  class Emulator
    include JSON::Serializable
    include Crystallabs::Helpers::Logging
    include Crystallabs::Helpers::Boolean

    # Is the emulator Mac OS X terminal?
    property? osxterm : Bool

    # Is the emulator iTerm2?
    property? iterm2 : Bool

    # Is the emulator XFCE's terminal?
    property? xfce : Bool

    # Is the emulator terminator?
    property? terminator : Bool

    # Is the emulator LXDE's lxterm?
    property? lxterm : Bool

    # Is the emulator based on VTE?
    property? vte : Bool

    # Is the emulator rxvt?
    property? rxvt : Bool

    # Is the emulator xterm?
    property? xterm : Bool

    # Is the emulator tmux?
    property? tmux : Bool

    # Is the emulator screen?
    property? screen : Bool

    @[JSON::Field(ignore: true)]
    # :nodoc:
    getter tput : Tput

    # For each emulator flag (by name), a human-readable description of *how* it
    # was determined (which environment variable, terminfo/TERM name, etc.).
    # Surfaced via `Tput#dump`.
    @[JSON::Field(ignore: true)]
    getter sources = Hash(String, String).new

    # Creates an instance of `Features` and performs the autodetection.
    def initialize(@tput : Tput)
      @sources = Hash(String, String).new
      term_program = ENV["TERM_PROGRAM"]? || ""

      @osxterm = term_program == "Apple_Terminal"
      @sources["osxterm"] = %(env TERM_PROGRAM == "Apple_Terminal")

      @iterm2 = (term_program == "iTerm.app") || (to_b ENV["ITERM_SESSION_ID"]?)
      @sources["iterm2"] = %(env TERM_PROGRAM == "iTerm.app" or ITERM_SESSION_ID set)

      @xfce = to_b((ENV["COLORTERM"]? || "") =~ /xfce/i)
      @sources["xfce"] = %(env COLORTERM matches /xfce/i)

      @terminator = to_b ENV["TERMINATOR_UUID"]?
      @sources["terminator"] = %(env TERMINATOR_UUID set)

      # NOTE: lxterminal does not provide an env variable to check for.
      @lxterm = false
      @sources["lxterm"] = "not detectable (lxterminal exposes no env var)"

      # gnome-terminal and sakura use a later version of VTE which provides VTE_VERSION as well as supports SGR events.
      @vte = to_b(ENV["VTE_VERSION"]?) || @xfce || @terminator || @lxterm
      @sources["vte"] = %(env VTE_VERSION set, or implied by xfce/terminator/lxterm)

      @rxvt = ENV["COLORTERM"]?.try(&.starts_with?("rxvt")) || (@tput.name? "rxvt")
      @sources["rxvt"] = %(env COLORTERM starts with "rxvt", or terminal name matches "rxvt")

      @xterm = to_b ENV["XTERM_VERSION"]?
      @sources["xterm"] = %(env XTERM_VERSION set)

      @tmux = to_b(ENV["TMUX"]?)
      @sources["tmux"] = %(env TMUX set)
      # XXX Detect TMUX version?

      @screen = (ENV["TERM"]? == "screen")
      @sources["screen"] = %(env TERM == "screen")

      Log.trace { my self }
    end

    def inspect(io)
      to_json io
    end
  end
end
