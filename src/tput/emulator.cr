require "json"
require "crystallabs-helpers"

class Tput
  # The most capable *in-band graphics protocol* a terminal advertises, ordered
  # least→most capable. Derived from terminal identity; see `Emulator#best_graphics`.
  enum GraphicsProtocol
    None  # no pixel graphics in-band; fall back to cell/glyph rendering
    Sixel # DCS sixel raster graphics
    Iterm # iTerm2 inline images (OSC 1337)
    Kitty # kitty graphics protocol (APC _G)
  end

  # Class for terminal emulator program detection.
  #
  # Best-effort only: detection relies on environment variables, which are
  # inherited by child processes. E.g. opening an xterm inside an lxterminal
  # propagates xterm-specific env vars into lxterm, confusing the detection.
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

    # The raw `$TERM_PROGRAM` value the emulator advertised (`""` if unset). Many
    # emulators (Apple Terminal, iTerm2, WezTerm, VS Code, …) self-identify here;
    # paired with `#term_program_version`.
    getter term_program : String

    # The raw `$TERM_PROGRAM_VERSION` value (`""` if unset).
    getter term_program_version : String

    @[JSON::Field(ignore: true)]
    # :nodoc:
    getter tput : Tput

    # For each emulator flag (by name), a description of how it was determined
    # (env var, terminfo/TERM name, etc.). Surfaced via `Tput#dump`.
    @[JSON::Field(ignore: true)]
    getter sources = Hash(String, String).new

    # Creates an instance of `Features` and performs the autodetection.
    def initialize(@tput : Tput)
      @sources = Hash(String, String).new
      term_program = @term_program = ENV["TERM_PROGRAM"]? || ""
      @term_program_version = ENV["TERM_PROGRAM_VERSION"]? || ""
      @sources["term_program"] = term_program.empty? ? "env TERM_PROGRAM unset" : %(env TERM_PROGRAM == "#{term_program}")
      @sources["term_program_version"] = @term_program_version.empty? ? "env TERM_PROGRAM_VERSION unset" : %(env TERM_PROGRAM_VERSION == "#{@term_program_version}")

      @osxterm = term_program == "Apple_Terminal"
      @sources["osxterm"] = %(env TERM_PROGRAM == "Apple_Terminal")

      @iterm2 = (term_program == "iTerm.app") || (to_b ENV["ITERM_SESSION_ID"]?)
      @sources["iterm2"] = %(env TERM_PROGRAM == "iTerm.app" or ITERM_SESSION_ID set)

      @xfce = to_b((ENV["COLORTERM"]? || "") =~ /xfce/i)
      @sources["xfce"] = %(env COLORTERM matches /xfce/i)

      @terminator = to_b ENV["TERMINATOR_UUID"]?
      @sources["terminator"] = %(env TERMINATOR_UUID set)

      # lxterminal exposes no env var to detect it.
      @lxterm = false
      @sources["lxterm"] = "not detectable (lxterminal exposes no env var)"

      # gnome-terminal/sakura use a VTE version that sets VTE_VERSION and supports SGR events.
      @vte = to_b(ENV["VTE_VERSION"]?) || @xfce || @terminator || @lxterm
      @sources["vte"] = %(env VTE_VERSION set, or implied by xfce/terminator/lxterm)

      @rxvt = ENV["COLORTERM"]?.try(&.starts_with?("rxvt")) || (@tput.name? "rxvt")
      @sources["rxvt"] = %(env COLORTERM starts with "rxvt", or terminal name matches "rxvt")

      @xterm = to_b ENV["XTERM_VERSION"]?
      @sources["xterm"] = %(env XTERM_VERSION set)

      @tmux = to_b(ENV["TMUX"]?)
      @sources["tmux"] = %(env TMUX set)

      @screen = ENV["TERM"]?.try(&.starts_with?("screen")) || @tput.name?("screen")
      @sources["screen"] = %(env TERM starts with "screen", or terminal name matches "screen")

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
    # Translates the env/name detection above into "can this terminal render
    # graphics via protocol X" (see `#best_graphics`).

    # Whether the terminal speaks the kitty graphics protocol.
    def kitty_graphics? : Bool
      kitty? || ghostty? || konsole? || wezterm?
    end

    # Whether the terminal renders iTerm2 inline images (OSC 1337).
    def iterm_images? : Bool
      iterm2? || wezterm?
    end

    # Whether the terminal renders sixel graphics. True for known sixel
    # emulators, or when a DA1 probe reply lists sixel support (device
    # attribute `4`). Plain xterm needs `-ti vt340` and isn't detectable from
    # env alone, so probe it for certainty.
    def sixel? : Bool
      return true if foot? || mlterm? || wezterm? || konsole?
      da = (@tput.features.da_params rescue nil)
      !!da.try(&.includes?(4))
    end

    # The most capable in-band graphics protocol this terminal advertises.
    # `GraphicsProtocol::None` means "no pixel graphics; use cell/glyph rendering".
    def best_graphics : GraphicsProtocol
      return GraphicsProtocol::Kitty if kitty_graphics?
      return GraphicsProtocol::Iterm if iterm_images?
      return GraphicsProtocol::Sixel if sixel?
      GraphicsProtocol::None
    end

    # --- Cell/glyph capability (best-effort, from terminal identity) ----------
    #
    # The Unicode "Symbols for Legacy Computing" ranges — sextants (U+1FB00…,
    # Unicode 13.0, 2020) and its "…Supplement" octants (U+1CD00…, Unicode 16.0,
    # 2024) — drive the high-resolution sub-cell glyph families used for
    # cell-grid image rendering. They are gated *separately*: a terminal can
    # render sextants but not the newer octants (older versions of the
    # self-rendering terminals did exactly this).
    #
    # Unlike graphics protocols these have *no* escape-sequence probe: a
    # terminal that lacks the glyph substitutes `?`/tofu, which is the same cell
    # width as a correct render and so indistinguishable at runtime. Support is
    # therefore decided from terminal identity (`#identity`) and, where it
    # matters, version (`#version`) via the tables below — the single place to
    # encode new terminal/version knowledge as it is learned, with no code
    # changes needed. See `#legacy_range_supported?` for the lookup policy.

    # Per-terminal sextant (U+1FB00) support. Key is `#identity`; value is the
    # minimum `#version` that supports it, or `nil` for "not supported at any
    # version". Terminals absent from the table are trusted (optimistic default).
    SEXTANT_SUPPORT = Hash(String, String?){
      # macOS terminals: bundled fonts don't cover the range → `?`.
      "iTerm2"         => nil,
      "Apple Terminal" => nil,
    }

    # Per-terminal octant (U+1CD00) support; same format as `SEXTANT_SUPPORT`.
    # Octants are Unicode 16.0 (2024), so even self-rendering terminals only
    # gained them recently — encode those as `identity => "min.version"`.
    OCTANT_SUPPORT = Hash(String, String?){
      "iTerm2"         => nil,
      "Apple Terminal" => nil,
      # kitty draws octants natively since 0.40.0 (older builds show tofu).
      "kitty" => "0.40.0",
    }

    # Whether the terminal reliably renders legacy-computing sextants (U+1FB00…).
    def legacy_computing_sextant? : Bool
      legacy_range_supported? SEXTANT_SUPPORT
    end

    # Whether the terminal reliably renders legacy-computing octants (U+1CD00…).
    def legacy_computing_octant? : Bool
      legacy_range_supported? OCTANT_SUPPORT
    end

    # Resolves a legacy-computing capability *table* against this terminal:
    #
    # * terminal not listed (incl. unidentified) → `true` (optimistic default);
    # * listed with `nil` → `false` (known to lack the range at any version);
    # * listed with a min version → `true` iff `#version` ≥ it. When the version
    #   can't be determined it is assumed current (`true`), so a capable terminal
    #   that doesn't self-report a version isn't penalised — only a *detected*
    #   older version is refused.
    private def legacy_range_supported?(table : Hash(String, String?)) : Bool
      key = identity
      return true unless key && table.has_key?(key)
      min = table[key]
      return false unless min
      v = version
      return true unless v
      cmp_versions(v, min) >= 0
    end

    # Compares two dotted-numeric version strings (e.g. `"0.40.0"` vs `"0.39"`),
    # returning -1/0/1. Integer groups are compared left to right; missing
    # trailing groups count as 0, and any non-numeric suffix is ignored.
    private def cmp_versions(a : String, b : String) : Int32
      pa = a.scan(/\d+/).map &.[0].to_i
      pb = b.scan(/\d+/).map &.[0].to_i
      Math.max(pa.size, pb.size).times do |i|
        x = pa[i]? || 0
        y = pb[i]? || 0
        return -1 if x < y
        return 1 if x > y
      end
      0
    end

    # --- Synthesized identity -------------------------------------------------
    #
    # Collapses the independent booleans above into a single "which terminal is
    # this" answer. Most-specific product wins, so a kitty that also looks
    # vaguely xterm-ish (via env leakage) still resolves to kitty.

    # Best-guess canonical product name, or `nil` if nothing matched. Concrete
    # products are preferred over generic families (vte/xterm); multiplexers
    # are reported separately via `#multiplexer`.
    def identity : String?
      return "kitty" if kitty?
      return "Ghostty" if ghostty?
      return "WezTerm" if wezterm?
      return "Konsole" if konsole?
      return "foot" if foot?
      return "mlterm" if mlterm?
      return "iTerm2" if iterm2?
      return "Apple Terminal" if osxterm?
      return "Terminator" if terminator?
      return "XFCE Terminal" if xfce?
      return "rxvt" if rxvt?
      return "xterm" if xterm?
      return "VTE-based" if vte?
      nil
    end

    # The terminal multiplexer the program is running *inside* (`tmux`/`screen`),
    # or `nil`. Separate from `#identity` since a multiplexer wraps, but doesn't
    # replace, the real terminal underneath.
    def multiplexer : String?
      return "tmux" if tmux?
      return "screen" if screen?
      nil
    end

    # Best-effort version string for the identified terminal, or `nil`. Prefers
    # the terminal's own XTVERSION self-report (populated by `Tput#probe!`),
    # falling back to `$TERM_PROGRAM_VERSION`. XTVERSION usually arrives as
    # `name(1.2.3)` or `name 1.2.3`; the bare version is extracted when present.
    def version : String?
      if v = @tput.features?.try(&.terminal_version)
        if m = v.match(/\(([^)]+)\)/)
          return m[1]
        elsif m = v.match(/\s+(\S+)$/)
          return m[1]
        else
          return v
        end
      end
      term_program_version.empty? ? nil : term_program_version
    end

    # Whether `#identity`/`#version` rest on the terminal's own self-report
    # (XTVERSION, via `Tput#probe!`) rather than env/TERM heuristics.
    def self_reported? : Bool
      !@tput.features?.try(&.terminal_version).nil?
    end

    # --- Probe-based hardening ------------------------------------------------
    #
    # Env/TERM detection is best-effort: env vars propagate to child processes
    # and survive tmux/ssh, so they can name the *wrong* terminal. `Tput#probe!`
    # asks the terminal itself (XTVERSION, `CSI > 0 q` → `features.terminal_version`),
    # which is authoritative. A confident match sets the corresponding
    # product-identity flag and clears the others (a terminal is exactly one
    # product). No-op when the terminal didn't answer.

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
                   return # unknown terminal, leave env detection untouched
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
      # Apple Terminal never answers XTVERSION, so any reply means we are not it.
      @osxterm = reidentify @osxterm, "osxterm", identity, v

      Log.trace { my self }
    end

    # Returns the new value for product flag *name* given the probed *identity*;
    # records provenance (confirmed on match, cleared when XTVERSION contradicts
    # a flag env had set).
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
