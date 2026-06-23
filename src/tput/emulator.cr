require "json"
require "crystallabs-helpers"

class Tput
  # The most capable *in-band graphics protocol* a terminal advertises, ordered
  # least→most capable. A pure terminal characteristic (derived from terminal
  # identity), so consumers can map it onto their own rendering backends without
  # repeating the detection. See `Emulator#best_graphics`.
  enum GraphicsProtocol
    None  # no pixel graphics in-band; fall back to cell/glyph rendering
    Sixel # DCS sixel raster graphics
    Iterm # iTerm2 inline images (OSC 1337)
    Kitty # kitty graphics protocol (APC _G)
  end

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

    # Is the emulator kitty? (graphics-capable)
    property? kitty : Bool

    # Is the emulator WezTerm? (graphics-capable)
    property? wezterm : Bool

    # Is the emulator Ghostty? (graphics-capable)
    property? ghostty : Bool

    # Is the emulator KDE Konsole? (graphics-capable)
    property? konsole : Bool

    # Is the emulator mlterm? (graphics-capable)
    property? mlterm : Bool

    # Is the emulator foot? (graphics-capable)
    property? foot : Bool

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

      @kitty = to_b(ENV["KITTY_WINDOW_ID"]?) || @tput.name?("xterm-kitty")
      @sources["kitty"] = %(env KITTY_WINDOW_ID set, or terminal name "xterm-kitty")

      @wezterm = (term_program == "WezTerm") || to_b(ENV["WEZTERM_PANE"]?) || to_b(ENV["WEZTERM_EXECUTABLE"]?)
      @sources["wezterm"] = %(env TERM_PROGRAM == "WezTerm", or WEZTERM_* set)

      @ghostty = (term_program == "ghostty") || @tput.name?("xterm-ghostty")
      @sources["ghostty"] = %(env TERM_PROGRAM == "ghostty", or terminal name "xterm-ghostty")

      @konsole = to_b(ENV["KONSOLE_VERSION"]?)
      @sources["konsole"] = %(env KONSOLE_VERSION set)

      @mlterm = to_b(ENV["MLTERM"]?)
      @sources["mlterm"] = %(env MLTERM set)

      @foot = @tput.name?("foot")
      @sources["foot"] = %(terminal name matches "foot")

      Log.trace { my self }
    end

    # --- Graphics capability (best-effort, from terminal identity) ------------
    #
    # These translate the env/name detection above into "can this terminal
    # render graphics via protocol X". They are terminal *characteristics*; a
    # consumer maps them onto its own rendering backends (see `#best_graphics`).

    # Whether the terminal speaks the kitty graphics protocol (kitty itself, or
    # other emulators that implement it).
    def kitty_graphics? : Bool
      kitty? || ghostty? || konsole? || wezterm?
    end

    # Whether the terminal renders iTerm2 inline images (OSC 1337).
    def iterm_images? : Bool
      iterm2? || wezterm?
    end

    # Whether the terminal renders sixel graphics. True for known sixel
    # emulators, or when a DA1 probe reply (if the terminal was probed) lists
    # sixel support (device attribute `4`). Plain xterm needs `-ti vt340` and
    # isn't detectable from the environment, so probe it if you need certainty.
    def sixel? : Bool
      return true if foot? || mlterm? || wezterm? || konsole?
      da = (@tput.features.da_params rescue nil)
      !!da.try(&.includes?(4))
    end

    # The most capable in-band graphics protocol this terminal advertises (a
    # pure terminal fact). `GraphicsProtocol::None` means "no pixel graphics;
    # use cell/glyph rendering".
    def best_graphics : GraphicsProtocol
      return GraphicsProtocol::Kitty if kitty_graphics?
      return GraphicsProtocol::Iterm if iterm_images?
      return GraphicsProtocol::Sixel if sixel?
      GraphicsProtocol::None
    end

    # --- Probe-based hardening ------------------------------------------------
    #
    # The env/TERM detection above is best-effort: env vars propagate to child
    # processes and survive across tmux/ssh, so they can name the *wrong*
    # terminal. `Tput#probe!` asks the terminal itself (XTVERSION,
    # `CSI > 0 q` → `features.terminal_version`), and the terminal's own answer
    # is authoritative. This reconciles the two: a confident XTVERSION match
    # sets the corresponding product-identity flag and clears the others (a
    # terminal is exactly one product). No-op when the terminal didn't answer.

    # Refines identity from the probed XTVERSION string. Called by `Tput#probe!`.
    def refine_from_probe! : Nil
      v = @tput.features?.try &.terminal_version
      return unless v

      d = v.downcase
      identity = if d.starts_with?("kitty")
                   "kitty"
                 elsif d.includes?("wezterm")
                   "wezterm"
                 elsif d.includes?("ghostty")
                   "ghostty"
                 elsif d.starts_with?("foot")
                   "foot"
                 elsif d.includes?("konsole")
                   "konsole"
                 elsif d.includes?("iterm")
                   "iterm2"
                 elsif d.includes?("mlterm")
                   "mlterm"
                 elsif d.includes?("rxvt")
                   "rxvt"
                 elsif d.starts_with?("xterm")
                   "xterm"
                 else
                   return # unknown terminal: leave env detection untouched
                 end

      @kitty = reidentify @kitty, "kitty", identity, v
      @wezterm = reidentify @wezterm, "wezterm", identity, v
      @ghostty = reidentify @ghostty, "ghostty", identity, v
      @foot = reidentify @foot, "foot", identity, v
      @konsole = reidentify @konsole, "konsole", identity, v
      @iterm2 = reidentify @iterm2, "iterm2", identity, v
      @mlterm = reidentify @mlterm, "mlterm", identity, v
      @rxvt = reidentify @rxvt, "rxvt", identity, v
      @xterm = reidentify @xterm, "xterm", identity, v

      Log.trace { my self }
    end

    # Returns the new value for product flag *name* given the probed *identity*,
    # recording the provenance: confirmed when it matches, cleared when XTVERSION
    # contradicts a flag env had set.
    private def reidentify(was : Bool, name : String, identity : String, version : String) : Bool
      on = name == identity
      if on
        @sources[name] = %(probed via XTVERSION ("#{version}"))
      elsif was
        @sources[name] = %(cleared by XTVERSION ("#{version}") — reports a different terminal)
      end
      on
    end

    def inspect(io)
      to_json io
    end
  end
end
