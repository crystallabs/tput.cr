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
  # name, its value, and how the value was determined (env var, constructor
  # option, terminfo, probing, or a default).
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

    # Lead with the synthesized answer: which terminal this most likely is,
    # its version, and whether that rests on self-report or env/TERM heuristics.
    emu = emulator?
    if emu
      ident = emu.identity || "(unidentified)"
      ident += " #{emu.version}" if emu.version
      ident += " inside #{emu.multiplexer}" if emu.multiplexer
      how = emu.self_reported? ? "XTVERSION self-report" : "env/TERM heuristic"
      io << "  " << "emulator".ljust(nw) << "  " << ident << "  (" << how << ")\n"
    end

    io << "  " << "name".ljust(nw) << "  " << @name << '\n'
    io << "  " << "aliases".ljust(nw) << "  " << (@aliases.empty? ? "(none)" : @aliases.join(", ")) << '\n'
    io << "  " << "terminfo".ljust(nw) << "  " << (@terminfo ? "loaded" : "(none — hardcoded fallback mode)") << '\n'

    if emu && !emu.term_program.empty?
      tp = emu.term_program
      tp += " #{emu.term_program_version}" unless emu.term_program_version.empty?
      io << "  " << "program".ljust(nw) << "  " << tp << "  (env TERM_PROGRAM)\n"
    end

    # Decoded device attributes — the terminal's own statement of its hardware
    # class and feature set, when probed. Most authoritative capability
    # evidence after XTVERSION.
    if f = features?
      dec = f.da_decoded
      io << "  " << "device".ljust(nw) << "  " << dec.join(", ") << "  (DA1)\n" unless dec.empty?
      if d2 = f.da2_decoded
        io << "  " << "device2".ljust(nw) << "  " << d2 << "  (DA2)\n"
      end
    end

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
  # recorded provenance from *sources* (or `"unknown"`). Shared by the emulator
  # and feature static-detection reports.
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

      # Report only the count of reported palette entries — the 16 hex values
      # would be noise for an identity dump.
      known = palette.count { |c| c }
      h["palette"] = det "palette", (known.zero? ? nil : "#{known}/16 detected (… colors not listed …)")

      h["da_params"] = det "da_params", da_params.try(&.join(';'))
      h["da2_params"] = det "da2_params", da2_params.try(&.join(';'))
      h["terminal_version"] = det "terminal_version", terminal_version
      h["kitty_keyboard"] = det "kitty_keyboard", kitty_keyboard_flags.try(&.to_s)
      h["modify_other_keys"] = det "modify_other_keys", modify_other_keys.try(&.to_s)
      # `true` after a positive DECRQM reply; once probed, a missing reply is
      # definitive `false` (unsupported), not unknown.
      h["in_band_resize"] = det "in_band_resize", (in_band_resize? ? "true" : (probed? ? "false" : nil))
      h
    end

    # All feature detections (static + probed) in one map.
    def detections : Hash(String, Tput::Detection)
      static_detections.merge probed_detections
    end

    private def det(name : String, value : String?) : Tput::Detection
      # Once probed, an absent value means no reply, not that probing never ran.
      placeholder = probed? ? "(no reply)" : "(not probed)"
      Tput::Detection.new (value || placeholder), (sources[name]? || "unknown")
    end
  end
end
