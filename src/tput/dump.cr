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
      "features" => features.detections,
    }
  end

  # Publish all detected terminal facts into the shared `Superconf` registry as
  # read-only entries (keys `tput.emulator.*` / `tput.features.*`), so they show
  # up in the application's unified config dump next to the configurable options.
  # Called automatically at the end of `initialize`.
  def publish_detections : Nil
    detections.each do |group, h|
      h.each do |name, d|
        Superconf.detect "tput.#{group}.#{name}", d.value, d.source
      end
    end
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
    dump_section io, "EMULATOR", emulator.detections
    io << '\n'
    dump_section io, "FEATURES (static: env / terminfo / option)", features.static_detections
    io << '\n'
    dump_section io, "FEATURES (live probing)", features.probed_detections
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

  class Emulator
    # `{name => Detection}` for every emulator flag, with provenance.
    def detections : Hash(String, Tput::Detection)
      h = Hash(String, Tput::Detection).new
      {
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
      }.each do |name, value|
        h[name] = Tput::Detection.new value.to_s, (sources[name]? || "unknown")
      end
      h
    end
  end

  class Features
    # `{name => Detection}` for the statically-detected features (env vars,
    # terminfo, constructor options).
    def static_detections : Hash(String, Tput::Detection)
      h = Hash(String, Tput::Detection).new
      {
        "unicode"          => unicode?.to_s,
        "broken_acs"       => broken_acs?.to_s,
        "pc_rom_charset"   => pc_rom_charset?.to_s,
        "magic_cookie"     => magic_cookie?.to_s,
        "padding"          => padding?.to_s,
        "setbuf"           => setbuf?.to_s,
        "number_of_colors" => number_of_colors.to_s,
        "truecolor"        => truecolor?.to_s,
        "color"            => color?.to_s,
        "cursor_style"     => cursor_style?.to_s,
        "cursor_color"     => cursor_color?.to_s,
        "acsc"             => "#{acsc.size} mapping(s)",
      }.each do |name, value|
        h[name] = Tput::Detection.new value, (sources[name]? || "unknown")
      end
      h
    end

    # `{name => Detection}` for the live-probed features. Values read
    # `(not probed)` until `Tput#probe!` has run and the terminal replied.
    def probed_detections : Hash(String, Tput::Detection)
      h = Hash(String, Tput::Detection).new
      h["ambiguous_width"] = det "ambiguous_width", ambiguous_width.try(&.to_s)
      h["default_foreground"] = det "default_foreground", default_foreground.try(&.to_s)
      h["default_background"] = det "default_background", default_background.try(&.to_s)

      known = palette.count { |c| c }
      pal = known.zero? ? nil : palette.map { |c| c.try(&.to_s) || "------" }.join(' ')
      h["palette"] = det "palette", pal.try { |s| "#{known}/16: #{s}" }

      h["da_params"] = det "da_params", da_params.try(&.join(';'))
      h
    end

    # All feature detections (static + probed) in one map.
    def detections : Hash(String, Tput::Detection)
      static_detections.merge probed_detections
    end

    private def det(name : String, value : String?) : Tput::Detection
      Tput::Detection.new (value || "(not probed)"), (sources[name]? || "unknown")
    end
  end
end
