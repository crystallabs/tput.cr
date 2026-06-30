class Tput
  # A single detected setting: its value rendered as a string, plus a
  # human-readable description of *how* that value was determined — e.g. an
  # environment variable, a `Tput` constructor option, a terminfo capability,
  # or live probing.
  struct Detection
    include JSON::Serializable

    getter value : String
    getter source : String

    def initialize(@value : String, @source : String)
    end

    def to_s(io)
      io << value << "  (" << source << ')'
    end
  end

  # All detected emulator + feature information, each value paired with a
  # description of how it was determined. Suitable for `to_pretty_json`.
  def detections : Hash(String, Hash(String, Detection))
    {
      "emulator" => emulator.detections,
      "graphics" => emulator.graphics_detections,
      "features" => features.detections,
    }
  end

  # Dumps all detected emulator and feature information to *io* (STDOUT by
  # default) in an aligned, human-readable report. Each line shows the setting
  # name, its value, and a description of how the value came to be (environment
  # variable, constructor option, terminfo, probing, or a default).
  #
  # ```
  # tput = Tput.new terminfo
  # tput.probe! # optional: fills in the live-probed colors/width
  # tput.dump
  # ```
  def dump(io : IO = STDOUT) : Nil
    dump_identity io
    io << '\n'
    dump_section io, "EMULATOR", emulator.detections
    io << '\n'
    dump_section io, "GRAPHICS (derived from emulator identity)", emulator.graphics_detections
    io << '\n'
    dump_section io, "FEATURES (static: env / terminfo / option)", features.static_detections
    io << '\n'
    dump_section io, "FEATURES (live probing)", features.probed_detections
  end

  # Dumps the core terminal identity — the resolved terminal name and its
  # aliases, whether a terminfo entry was loaded, and the detected screen size.
  # These are determined directly on `Tput` (not via `Features`/`Emulator`), so
  # they are reported separately from the detection sections.
  private def dump_identity(io : IO) : Nil
    nw = 8
    io << "IDENTITY\n"
    io << "  " << "name".ljust(nw) << "  " << @name << '\n'
    io << "  " << "aliases".ljust(nw) << "  " << (@aliases.empty? ? "(none)" : @aliases.join(", ")) << '\n'
    io << "  " << "terminfo".ljust(nw) << "  " << (@terminfo ? "loaded" : "(none — hardcoded fallback mode)") << '\n'
    io << "  " << "size".ljust(nw) << "  " << @screen.width << " x " << @screen.height << " (cols x rows)" << '\n'
  end

  private def dump_section(io : IO, title : String, map : Hash(String, Detection)) : Nil
    io << title << '\n'
    return if map.empty?
    nw = map.keys.max_of(&.size)
    vw = map.values.max_of(&.value.size)
    map.each do |name, d|
      io << "  " << name.ljust(nw) << "  " << d.value.ljust(vw) << "  " << d.source << '\n'
    end
  end

  # Builds a `{name => Detection}` map, pairing each stringified value with its
  # recorded provenance from *sources* (or `"unknown"` when none). Shared by the
  # emulator and feature static-detection reports, whose values come from a
  # literal `{name => value}` map.
  # :nodoc:
  def self.build_detections(pairs, sources : Hash(String, String)) : Hash(String, Detection)
    h = Hash(String, Detection).new
    pairs.each do |name, value|
      h[name] = Detection.new value.to_s, (sources[name]? || "unknown")
    end
    h
  end

  class Emulator
    # `{name => Detection}` for every emulator flag, with provenance.
    def detections : Hash(String, Tput::Detection)
      Tput.build_detections({
        "osxterm"    => osxterm?,
        "iterm2"     => iterm2?,
        "xfce"       => xfce?,
        "terminator" => terminator?,
        "lxterm"     => lxterm?,
        "vte"        => vte?,
        "rxvt"       => rxvt?,
        "xterm"      => xterm?,
        "tmux"       => tmux?,
        "screen"     => screen?,
        "kitty"      => kitty?,
        "wezterm"    => wezterm?,
        "ghostty"    => ghostty?,
        "konsole"    => konsole?,
        "mlterm"     => mlterm?,
        "foot"       => foot?,
      }, sources)
    end

    # `{name => Detection}` for the *derived* graphics capabilities — computed
    # from the emulator flags above rather than detected directly, so they have
    # no `sources` entry and carry a synthesized provenance instead.
    def graphics_detections : Hash(String, Tput::Detection)
      {
        "kitty_graphics" => Tput::Detection.new(kitty_graphics?.to_s, "derived: kitty / ghostty / konsole / wezterm"),
        "iterm_images"   => Tput::Detection.new(iterm_images?.to_s, "derived: iterm2 / wezterm"),
        "sixel"          => Tput::Detection.new(sixel?.to_s, "derived: foot / mlterm / wezterm / konsole, or DA1 attribute 4"),
        "best_graphics"  => Tput::Detection.new(best_graphics.to_s, "most capable of the above"),
      }
    end
  end

  class Features
    # `{name => Detection}` for the statically-detected features (env vars,
    # terminfo, constructor options).
    def static_detections : Hash(String, Tput::Detection)
      Tput.build_detections({
        "unicode"          => unicode?,
        "broken_acs"       => broken_acs?,
        "pc_rom_charset"   => pc_rom_charset?,
        "magic_cookie"     => magic_cookie?,
        "padding"          => padding?,
        "ansi_cursor"      => ansi_cursor?,
        "ansi_hpa"         => ansi_hpa?,
        "ansi_vpa"         => ansi_vpa?,
        "ansi_edit"        => ansi_edit?,
        "ansi_scroll"      => ansi_scroll?,
        "setbuf"           => setbuf?,
        "number_of_colors" => number_of_colors,
        "truecolor"        => truecolor?,
        "color"            => color?,
        "cursor_style"     => cursor_style?,
        "cursor_color"     => cursor_color?,
        "acsc"             => "#{acsc.size} mapping(s)",
      }, sources)
    end

    # `{name => Detection}` for the live-probed features. Values read
    # `(not probed)` until `Tput#probe!` has run and the terminal replied.
    def probed_detections : Hash(String, Tput::Detection)
      h = Hash(String, Tput::Detection).new
      h["ambiguous_width"] = det "ambiguous_width", ambiguous_width.try(&.to_s)
      h["default_foreground"] = det "default_foreground", default_foreground.try(&.to_s)
      h["default_background"] = det "default_background", default_background.try(&.to_s)

      # Report only how many palette entries the terminal reported, not the
      # colors themselves — the 16 hex values are noise for an identity dump.
      known = palette.count { |c| c }
      h["palette"] = det "palette", (known.zero? ? nil : "#{known}/16 detected (… colors not listed …)")

      h["da_params"] = det "da_params", da_params.try(&.join(';'))
      h["da2_params"] = det "da2_params", da2_params.try(&.join(';'))
      h["terminal_version"] = det "terminal_version", terminal_version
      h["kitty_keyboard"] = det "kitty_keyboard", kitty_keyboard_flags.try(&.to_s)
      h["modify_other_keys"] = det "modify_other_keys", modify_other_keys.try(&.to_s)
      # Boolean probe result: `true` after a positive DECRQM reply. Once a probe
      # has run, a missing reply is a definitive `false` (mode unsupported); only
      # before probing is it genuinely unknown ("(not probed)").
      h["in_band_resize"] = det "in_band_resize", (in_band_resize? ? "true" : (probed? ? "false" : nil))
      h
    end

    # All feature detections (static + probed) in one map.
    def detections : Hash(String, Tput::Detection)
      static_detections.merge probed_detections
    end

    private def det(name : String, value : String?) : Tput::Detection
      # Once a probe has run, an absent value means the terminal didn't answer,
      # not that probing never happened.
      placeholder = probed? ? "(no reply)" : "(not probed)"
      Tput::Detection.new (value || placeholder), (sources[name]? || "unknown")
    end
  end
end
