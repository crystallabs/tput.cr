module Tput
  # Mixin containing terminal/console functions
  module Terminal

    getter? osxterm : Bool = false
    getter? iterm2 : Bool = false
    getter? xfce : Bool = false
    getter? terminator : Bool = false
    getter? lxde : Bool = false
    getter? vte : Bool = false
    getter? rxvt : Bool = false
    getter? xterm : Bool = false
    getter? tmux : Bool = false
    getter tmux_version : Int32 = 0

    def self.find_terminal(terminal = nil, term = nil)
      (terminal || term || ENV["TERM"]? || "{% if flag?(:windows) %}windows-ansi{% else %}xterm{% end %}").downcase
    end

    def detect_term_program
      term_program = ENV["TERM_PROGRAM"]? || ""
      @osxterm = term_program == "Apple_Terminal"
      @iterm2  = (term_program == "iTerm.app") || to_bool(ENV["ITERM_SESSION_ID"]?)

      @xfce = !!((ENV["COLORTERM"]?||"") =~ /xfce/i)
      @terminator = to_bool(ENV["TERMINATOR_UUID"]?)
      @lxde = false # TODO missing check
      # NOTE: lxterminal does not provide an env var to check for.
      # NOTE: gnome-terminal and sakura use a later version of VTE which provides VTE_VERSION as well as supports SGR events.
      @vte = to_bool(ENV["VTE_VERSION"]?) || @xfce || @terminator || @lxde

      # XXX These two could be more complete
      @rxvt  = !!((ENV["COLORTERM"]?||"") =~ /rxvt/i)
      @xterm = !!((ENV["XTERM_VERSION"]?||"") =~ /^XTerm/i)

      @tmux = to_bool(ENV["TMUX"]?)
      @tmux_version = 0
      if @tmux
        @tmux_version = (`tmux -V | cut -d' ' -f2`[0]?.try &.to_i) || 0
      end
    end

    # Reports whether current terminal is *name* or its subtype.
    def term?(name : String)
      if @terminfo
        return true if @terminfo.name.index(name) == 0
        @terminfo.names.each do |n|
          return true if n.index(name) == 0
        end
      else
        raise Exception.new "Checking term without @terminfo not supported yet"
      end
      false
    end

  end
end
