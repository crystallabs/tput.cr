class Tput
  # Class for terminal emulator program detection.
  #
  # The detection is always just a best-effort because it relies on testing environment
  # variables, and these are passed from processes to children. (I.e. if a person opens
  # an xterm, then an lxterminal in it, xterm-specific environment variables will propagate
  # to lxterm, confusing the detection.
  class Emulator
    include Crystallabs::Helpers::Logging
    include JSON::Serializable
    include Crystallabs::Helpers::Boolean

    getter? osxterm : Bool
    getter? iterm2 : Bool
    getter? xfce : Bool
    getter? terminator : Bool
    getter? lxterm : Bool
    getter? vte : Bool
    getter? rxvt : Bool
    getter? xterm : Bool
    getter? tmux : Bool

    @[JSON::Field(ignore: true)]
    getter tput : Tput

    def initialize(@tput : Tput)
      term_program = ENV["TERM_PROGRAM"]? || ""

      @osxterm = term_program == "Apple_Terminal"

      @iterm2 = (term_program == "iTerm.app") || (to_b ENV["ITERM_SESSION_ID"]?)

      @xfce = to_b ((ENV["COLORTERM"]? || "") =~ /xfce/i)

      @terminator = to_b ENV["TERMINATOR_UUID"]?

      # NOTE: lxterminal does not provide an enviable to check for.
      @lxterm = false

      # gnome-terminal and sakura use a later version of VTE which provides VTE_VERSION as well as supports SGR events.
      @vte = to_b(ENV["VTE_VERSION"]?) || @xfce || @terminator || @lxterm

      @rxvt = to_b((ENV["COLORTERM"]? || "") =~ /rxvt/i)

      @xterm = to_b ENV["XTERM_VERSION"]?

      @tmux = to_b (ENV["TMUX"]?)
      # XXX Detect TMUX version?
    end
  end
end
