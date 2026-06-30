require "json"

class Tput
  # Terminal features auto-detection.
  #
  # Involved in a terminal are the terminal emulator in use (`Tput::Emulator`) and
  # the term type initialized/running in it (`ENV["TERM"]` usually).
  #
  # After those two variables are known, the features autodetection is ran to
  # figure out the final details of terminal's behavior.
  class Features
    include JSON::Serializable
    include Crystallabs::Helpers::Logging
    include Crystallabs::Helpers::Boolean

    alias ACSHash = Hash(Char, Char)

    # Is unicode supported?
    getter? unicode : Bool

    # Does the terminal have broken ACS chars?
    getter? broken_acs : Bool

    # Does the terminal support PC ROM charset?
    getter? pc_rom_charset : Bool

    getter? magic_cookie : Bool

    getter? padding : Bool

    # Whether the terminal's cursor-movement capabilities (`cup`, `cuu`, `cud`,
    # `cuf`, `cub`) are byte-for-byte standard ANSI/VT100. When true, `Tput`
    # builds those sequences directly instead of paying a `tparm` FFI call per
    # move — roughly 6x faster, and cursor moves dominate frame rendering. The
    # value is verified at startup by actually running each capability through
    # terminfo and comparing the result to the canonical ANSI sequence, so any
    # deviation (exotic terminal, embedded padding, reordered params) safely
    # falls back to the terminfo path.
    getter? ansi_cursor : Bool

    # Like `ansi_cursor?`, but for the column-address capability `hpa`
    # (`cursor_char_absolute` / `char_pos_absolute`).
    getter? ansi_hpa : Bool

    # Like `ansi_cursor?`, but for the row-address capability `vpa`
    # (`cursor_line_absolute`).
    getter? ansi_vpa : Bool

    # Like `ansi_cursor?`, but for the line-editing capabilities `ich`, `il`,
    # `dl`, `dch`, `ech` and `rep` (insert/delete/erase chars and lines).
    getter? ansi_edit : Bool

    # Like `ansi_cursor?`, but for the scroll capabilities `csr` (scroll
    # region), `parm_index` (SU) and `parm_rindex` (SD).
    getter? ansi_scroll : Bool

    getter? setbuf : Bool

    # Number of colors supported by the terminal
    getter number_of_colors : Int32

    # Does the terminal support 24-bit direct ("true") color? Set statically by
    # `detect_truecolor`, and upgraded to `true` by `Tput#probe!` if a live
    # DECRQSS readback confirms it (see `Tput::Probe`).
    property? truecolor : Bool

    # Color support flag (a yes/no)
    getter? color : Bool

    # Does the terminal support styling its *hardware* cursor — shape and blink
    # via DECSCUSR (`CSI Ps SP q`), or iTerm2's proprietary OSC 50? Detected
    # statically from the emulator/term name, and upgraded to a confirmed `true`
    # by `Tput#probe!` when a DECRQSS readback of the cursor style succeeds (see
    # `Tput::Probe`). When this is `false`, Crysterm falls back to drawing an
    # artificial cursor for any non-default shape (see `Screen#apply_cursor`).
    property? cursor_style : Bool

    # Does the terminal support recoloring its *hardware* cursor via OSC 12
    # (`OSC 12 ; color ST`)? Detected statically; upgraded to a confirmed `true`
    # by `Tput#probe!` when the terminal answers an OSC 12 color query.
    property? cursor_color : Bool

    getter acsc : ACSHash

    @[JSON::Field(ignore: true)]
    getter acscr : ACSHash

    # Runtime-probed results, filled in by `Tput#probe!` (see `Tput::Probe`).
    # They stay `nil`/empty until probing runs and the terminal replies.

    # Rendered width (in cells) of an ambiguous-width character, as actually
    # measured via DSR/CPR. 1 = narrow, 2 = wide; `nil` if not probed.
    @[JSON::Field(ignore: true)]
    property ambiguous_width : Int32? = nil

    # Default foreground color reported via OSC 10.
    @[JSON::Field(ignore: true)]
    property default_foreground : RGB? = nil

    # Default background color reported via OSC 11.
    @[JSON::Field(ignore: true)]
    property default_background : RGB? = nil

    # The 16 indexed palette colors reported via OSC 4 (`nil` per entry until
    # probed / if the terminal didn't answer for that index).
    @[JSON::Field(ignore: true)]
    property palette : Array(RGB?) = Array(RGB?).new(16, nil)

    # Numeric parameters from the DA1 (`CSI c`) device-attributes reply.
    @[JSON::Field(ignore: true)]
    property da_params : Array(Int32)? = nil

    # The kitty keyboard protocol flags the terminal reported active in answer to
    # a `CSI ? u` query, or `nil` if it did not answer (protocol unsupported). A
    # non-`nil` value — even `0` — means the protocol *is* supported; the number
    # is the currently-active enhancement flags. See `Tput::Keyboard`.
    @[JSON::Field(ignore: true)]
    property kitty_keyboard_flags : Int32? = nil

    # The xterm `modifyOtherKeys` level the terminal reported in answer to a
    # `CSI ? 4 m` query (0, 1, or 2), or `nil` if it did not answer (support not
    # detectable). See `Tput::Keyboard`.
    @[JSON::Field(ignore: true)]
    property modify_other_keys : Int32? = nil

    # Secondary device-attributes (DA2, `CSI > c`) parameters
    # `[type, version, keyboard]`, or `nil` if not probed / unanswered. A more
    # reliable terminal identity/version source than the env-var heuristics in
    # `Emulator`.
    @[JSON::Field(ignore: true)]
    property da2_params : Array(Int32)? = nil

    # Terminal name and version as reported by XTVERSION (`CSI > 0 q`), e.g.
    # `"kitty(0.32.0)"`, or `nil` if not probed / unanswered.
    @[JSON::Field(ignore: true)]
    property terminal_version : String? = nil

    # Whether the terminal supports in-band resize notifications (DEC private
    # mode 2048), as probed via DECRQM at startup. When true, a consumer can
    # prefer in-band resize reports over `SIGWINCH`. `false` when unsupported or
    # not probed.
    @[JSON::Field(ignore: true)]
    property? in_band_resize : Bool = false

    @[JSON::Field(ignore: true)]
    # :nodoc:
    getter tput : Tput

    # For each detected field (by name), a human-readable description of *how*
    # its value was determined — e.g. an environment variable, a `Tput`
    # constructor option, a terminfo capability, or live probing. Populated by
    # the `detect_*` methods and by `Tput#probe!`. Surfaced via `Tput#dump`.
    @[JSON::Field(ignore: true)]
    getter sources = Hash(String, String).new

    # Provenance recorded for the probe-only fields before any probe has run.
    # After `Tput#probe!` runs (see `mark_probed!`), any field still carrying
    # this baseline means "the terminal was asked but did not report it".
    BASELINE_PROBE_SOURCE = "not probed (call Tput#probe!)"

    # Whether a live probe (`Tput#probe!`) has run. Distinguishes "the terminal
    # was asked but did not report this" from "no probe has happened yet", so the
    # dump can stop saying "(not probed)" once probing has actually occurred.
    @[JSON::Field(ignore: true)]
    property? probed : Bool = false

    def initialize(@tput : Tput)
      @sources = Hash(String, String).new

      # Baseline provenance for the probe-only fields; overwritten by
      # `Tput#probe!` if/when the terminal actually answers.
      {"ambiguous_width", "default_foreground", "default_background",
       "palette", "da_params", "kitty_keyboard", "modify_other_keys",
       "da2_params", "terminal_version", "in_band_resize"}.each do |k|
        @sources[k] = BASELINE_PROBE_SOURCE
      end

      @unicode = detect_unicode
      @broken_acs = detect_broken_acs
      @pc_rom_charset = detect_pc_rom_charset
      @magic_cookie = detect_magic_cookie
      @padding = detect_padding
      @ansi_cursor = detect_ansi_cursor
      @ansi_hpa = detect_ansi_hpa
      @ansi_vpa = detect_ansi_vpa
      @ansi_edit = detect_ansi_edit
      @ansi_scroll = detect_ansi_scroll
      @setbuf = detect_setbuf
      @truecolor = detect_truecolor
      @number_of_colors = detect_number_of_colors
      @color = @number_of_colors > 2
      @sources["color"] = "derived from number_of_colors (#{@number_of_colors}) > 2"
      @cursor_style = detect_cursor_style
      @cursor_color = detect_cursor_color
      @acsc, @acscr = parse_acs

      Log.trace { my self }
    end

    def inspect(io)
      to_json io
    end

    # Records that a live probe (`Tput#probe!`) has run. Any probe-only field the
    # terminal never answered still carries its pre-probe `BASELINE_PROBE_SOURCE`,
    # so rewrite those to say a probe actually ran and got no reply — instead of
    # the now-misleading "not probed (call Tput#probe!)". Called by `Tput#probe!`.
    def mark_probed! : Nil
      @probed = true
      @sources.each do |k, v|
        @sources[k] = "probed — terminal did not report" if v == BASELINE_PROBE_SOURCE
      end
    end

    # Marks the terminal as 24-bit truecolor-capable (e.g. after a successful
    # live probe), updating the derived color fields and recording *source* as
    # the provenance for both `truecolor` and `number_of_colors`.
    def confirm_truecolor!(source : String) : Nil
      @truecolor = true
      @number_of_colors = 0x1000000
      @color = true
      @sources["truecolor"] = source
      @sources["number_of_colors"] = "24-bit truecolor (#{source})"
      @sources["color"] = "derived from number_of_colors (#{@number_of_colors}) > 2"
    end

    # Detects Unicode support
    def detect_unicode
      if @tput.force_unicode?
        @sources["unicode"] = "Tput#force_unicode constructor option"
        return true
      end

      if to_b ENV["NCURSES_FORCE_UNICODE"]?
        @sources["unicode"] = %(env NCURSES_FORCE_UNICODE)
        return true
      end

      {"XTERM_LOCALE", "LANG", "LANGUAGE", "LC_ALL", "LC_CTYPE"}.each do |name|
        if ENV[name]?.try &.=~(/utf\-?8/i)
          @sources["unicode"] = %(env #{name} matches /utf-?8/i)
          return true
        end
      end

      if ENV["TERM"]?.try &.=~(/\bunicode\b/i)
        @sources["unicode"] = %(env TERM contains "unicode")
        return true
      end

      {% if flag? :windows %}
        if get_console_cp == 65001
          @sources["unicode"] = "Windows console codepage 65001 (UTF-8)"
          return true
        end
      {% end %}

      @sources["unicode"] = "default — no UTF-8 locale/TERM indicator found"
      false
    end

    # Detects whether terminal has broken ACS characters
    def detect_broken_acs
      # For some reason TERM=linux has smacs/rmacs, but it maps to `^[[11m`
      # and it does not switch to the DEC SCLD character set.
      # xterm: \e(0, screen: \x0e, linux: \e[11m (doesn't work)
      # `man console_codes` says:
      # 11  select null mapping, set display control flag, reset tog‐
      #     gle meta flag (ECMA-48 says "first alternate font").
      # See ncurses:
      # ~/ncurses/ncurses/base/lib_set_term.c
      # ~/ncurses/ncurses/tinfo/lib_acs.c
      # ~/ncurses/ncurses/tinfo/tinfo_driver.c
      # ~/ncurses/ncurses/tinfo/lib_setup.c

      # ncurses-compatible env variable.
      if to_b ENV["NCURSES_NO_UTF8_ACS"]?
        @sources["broken_acs"] = %(env NCURSES_NO_UTF8_ACS)
        return true
      end

      # If the terminal supports unicode, we don't need ACS.
      if term_has_unicode?
        @sources["broken_acs"] = "terminfo extension U8 > 0 (unicode, ACS unused)"
        return true
      end

      # The linux console is just broken for some reason.
      # Apparently the Linux console does not support ACS,
      # but it does support the PC ROM character set.
      if @tput.terminfo.try(&.name.==("linux")) || ENV["TERM"]?.try(&.==("linux"))
        @sources["broken_acs"] = %(TERM/terminfo name "linux" (broken ACS))
        return true
      end

      # PC alternate charset
      # if (acsc.indexOf('+\x10,\x11-\x18.\x190') === 0) {
      if detect_pc_rom_charset
        @sources["broken_acs"] = "terminfo: PC ROM charset present (no SCLD ACS)"
        return true
      end

      # XXX Possibly enable when termcap support gets added. Since we only support
      # terminfo for now, this is not relevant.
      #  // screen termcap is bugged?
      #  if (@termcap
      #      && @tput.terminfo.name.indexOf('screen') === 0
      #      && ENV["TERMCAP"].try { |t| t.starts_with? "screen" }
      #      && ~process.env.TERMCAP.indexOf('hhII00')) {
      #    if (~info.strings.enter_alt_charset_mode.indexOf('\x0e')
      #        || ~info.strings.enter_alt_charset_mode.indexOf('\x0f')
      #        || ~info.strings.set_attributes.indexOf('\x0e')
      #        || ~info.strings.set_attributes.indexOf('\x0f')) {
      #      true;
      #    end
      #  end

      @sources["broken_acs"] = "default — no broken-ACS indicator"
      false
    end

    # Detects whether terminal supports PC ROM charset
    def detect_pc_rom_charset
      # If enter_pc_charset is the same as enter_alt_charset,
      # the terminal does not support SCLD as ACS.
      # See: ~/ncurses/ncurses/tinfo/lib_acs.c

      @tput.shim.try do |shim|
        shim.enter_pc_charset_mode?.try do |epm|
          shim.enter_alt_charset_mode?.try do |eam|
            if (epm == eam) && (shim.exit_pc_charset_mode? == shim.exit_alt_charset_mode?)
              @sources["pc_rom_charset"] = "terminfo: enter_pc_charset == enter_alt_charset"
              return true
            end
          end
        end
      end

      @sources["pc_rom_charset"] = @tput.shim ? "default — terminfo PC/ALT charset caps differ/absent" : "default — no terminfo (hardcoded mode)"
      false
    end

    def detect_magic_cookie
      detect_ncurses_flag "magic_cookie", "NCURSES_NO_MAGIC_COOKIE"
    end

    # Detects a boolean feature that is *on* by default and turned *off* by the
    # presence of an `NCURSES_NO_*` env variable, recording the env var or the
    # default as provenance. Shared by the `magic_cookie` and `setbuf`
    # detections.
    #
    # The `NCURSES_NO_*` variables are *disable* switches (their very name says
    # "no <feature>"), so — exactly like `detect_padding`/`NCURSES_NO_PADDING`,
    # and matching ncurses/blessed — the feature defaults to true and the
    # variable's mere presence turns it off. The value is irrelevant:
    # `NCURSES_NO_SETBUF` set to anything (even `"0"`) means "no setbuf".
    private def detect_ncurses_flag(feature : String, env : String) : Bool
      present = !ENV[env]?.nil?
      @sources[feature] = present ? "env #{env} (disabled)" : "default (true)"
      !present
    end

    def detect_padding
      # Padding is honored unless explicitly disabled via the ncurses-compatible
      # NCURSES_NO_PADDING env variable. See `Tput::Output#_pad_write`.
      v = ENV["NCURSES_NO_PADDING"]?.nil?
      @sources["padding"] = ENV["NCURSES_NO_PADDING"]? ? "env NCURSES_NO_PADDING (disabled)" : "default (enabled)"
      v
    end

    def detect_ansi_cursor
      # Run each capability through terminfo with sample values and compare to
      # canonical ANSI. The samples are >1 and distinct so a missing `%i`
      # (1-based) increment in `cup` or a swapped row/col would be caught.
      detect_ansi "ansi_cursor" do |s|
        seq_eq(s.cup?(5, 9), "\e[6;10H") && # cup?(row, col) -> CSI (row+1);(col+1) H
          seq_eq(s.cuu?(3), "\e[3A") &&
          seq_eq(s.cud?(3), "\e[3B") &&
          seq_eq(s.cuf?(3), "\e[3C") &&
          seq_eq(s.cub?(3), "\e[3D")
      end
    end

    # `hpa` (column_address, CHA — `CSI Ps G`) verified standard ANSI.
    def detect_ansi_hpa
      detect_ansi("ansi_hpa") { |s| seq_eq(s.hpa?(4), "\e[5G") }
    end

    # `vpa` (row_address, VPA — `CSI Ps d`) verified standard ANSI.
    def detect_ansi_vpa
      detect_ansi("ansi_vpa") { |s| seq_eq(s.vpa?(4), "\e[5d") }
    end

    # `ich`/`il`/`dl`/`dch`/`ech` (line-editing) verified standard ANSI.
    #
    # `rep` is deliberately excluded: terminfo's `rep` is a two-parameter
    # capability that emits the character *and* the repeat (`%p1%c%p2%{1}%-%db`,
    # e.g. xterm), so it is not byte-equal to the raw one-parameter `CSI Pn b`
    # this group's fast path would build — it would never verify and would pin
    # the whole group to the tparm path. `repeat_preceding_character` keeps its
    # own `put(&.rep?)` route instead.
    def detect_ansi_edit
      detect_ansi "ansi_edit" do |s|
        seq_eq(s.ich?(4), "\e[4@") &&
          seq_eq(s.il?(4), "\e[4L") &&
          seq_eq(s.dl?(4), "\e[4M") &&
          seq_eq(s.dch?(4), "\e[4P") &&
          seq_eq(s.ech?(4), "\e[4X")
      end
    end

    # `csr` (DECSTBM)/`parm_index` (SU)/`parm_rindex` (SD) verified standard ANSI.
    def detect_ansi_scroll
      detect_ansi "ansi_scroll" do |s|
        seq_eq(s.csr?(5, 9), "\e[6;10r") &&
          seq_eq(s.parm_index?(4), "\e[4S") &&
          seq_eq(s.parm_rindex?(4), "\e[4T")
      end
    end

    # Verifies, once at startup, that the terminfo capabilities a group of
    # cursor methods rely on produce byte-for-byte standard ANSI when run
    # through `tparm` — letting those methods build the sequences directly and
    # skip the per-call FFI. Returns `false` when there is no terminfo (the
    # no-terminfo code paths already emit ANSI fallbacks directly, so there is
    # no `tparm` call to avoid) and on any mismatch — including an embedded
    # `$<...>` padding marker — or error, keeping the safe terminfo path.
    private def detect_ansi(name : String, & : Unibilium::Terminfo::Shim -> Bool) : Bool
      shim = @tput.shim
      unless shim
        @sources[name] = "no terminfo (using ANSI fallback)"
        return false
      end

      ok = yield shim
      @sources[name] = ok ? "terminfo caps verified ANSI" : "terminfo caps non-ANSI (using tparm)"
      ok
    rescue
      # A missing/raising capability -> stay on the safe terminfo path.
      @sources[name] = "detection error (using tparm)"
      false
    end

    private def seq_eq(bytes : Bytes?, expected : String) : Bool
      !bytes.nil? && bytes == expected.to_slice
    end

    def detect_setbuf
      detect_ncurses_flag "setbuf", "NCURSES_NO_SETBUF"
    end

    # Detects whether the terminal supports 24-bit direct ("true") color.
    #
    # Truecolor is advertised through several independent channels, none of
    # which is universal, so we check them in order of reliability:
    #
    # * `COLORTERM=truecolor` / `COLORTERM=24bit` — the out-of-band env hint set
    #   by most modern emulators and multiplexers.
    # * terminfo `RGB` — ncurses' direct-color capability (boolean, or numeric
    #   `RGB#n` bits-per-channel, or a string variant; any form counts).
    # * terminfo `Tc` — the older tmux/community extended-boolean convention.
    # * terminfo `Max_colors >= 16_777_216` — the full 24-bit space declared
    #   directly.
    # * terminfo `setrgbf` / `setrgbb` — direct-color fg/bg setter strings.
    def detect_truecolor
      if ct = ENV["COLORTERM"]?
        if ct == "truecolor" || ct == "24bit"
          @sources["truecolor"] = %(env COLORTERM="#{ct}")
          return true
        end
      end

      @tput.terminfo.try do |t|
        ext = t.extensions

        if ext.has? "RGB"
          @sources["truecolor"] = "terminfo RGB capability"
          return true
        end

        if ext.get_bool? "Tc"
          @sources["truecolor"] = "terminfo Tc capability"
          return true
        end

        t.get?(::Unibilium::Entry::Numeric::Max_colors).try do |v|
          if v >= 0x1000000
            @sources["truecolor"] = "terminfo Max_colors = #{v}"
            return true
          end
        end

        if ext.has?("setrgbf") || ext.has?("setrgbb")
          @sources["truecolor"] = "terminfo setrgbf/setrgbb capability"
          return true
        end
      end

      @sources["truecolor"] = "default — no truecolor env/terminfo indicator"
      false
    end

    # Detects whether the terminal can style its hardware cursor (shape/blink).
    #
    # There is no terminfo capability for DECSCUSR in the base set, so this is a
    # best-effort guess from the emulator/term name. It is deliberately
    # conservative (only terminals known to honor the sequence are flagged), and
    # `Tput#probe!` confirms the rest at runtime via a DECRQSS readback.
    def detect_cursor_style
      if iterm2_env?
        @sources["cursor_style"] = %(emulator iTerm2 (OSC 50 cursor shape))
        return true
      end

      if @tput.name? "xterm", "screen", "rxvt"
        @sources["cursor_style"] = %(term name xterm/screen/rxvt (DECSCUSR))
        return true
      end

      @sources["cursor_style"] = "default — no known DECSCUSR support (call Tput#probe! to confirm)"
      false
    end

    # Detects whether the terminal can recolor its hardware cursor (OSC 12).
    def detect_cursor_color
      if @tput.name? "xterm", "screen", "rxvt"
        @sources["cursor_color"] = %(term name xterm/screen/rxvt (OSC 12))
        return true
      end

      @sources["cursor_color"] = "default — no known OSC 12 support (call Tput#probe! to confirm)"
      false
    end

    # Marks the hardware cursor as styleable (shape/blink) after a successful
    # live probe, recording *source* as the provenance.
    def confirm_cursor_style!(source : String) : Nil
      @cursor_style = true
      @sources["cursor_style"] = source
    end

    # Marks the hardware cursor as recolorable after a successful live probe.
    def confirm_cursor_color!(source : String) : Nil
      @cursor_color = true
      @sources["cursor_color"] = source
    end

    # Whether the terminal speaks the kitty keyboard protocol (it answered the
    # `CSI ? u` probe).
    def kitty_keyboard? : Bool
      !@kitty_keyboard_flags.nil?
    end

    # Whether the terminal supports xterm `modifyOtherKeys` (it answered the
    # `CSI ? 4 m` probe).
    def modify_other_keys? : Bool
      !@modify_other_keys.nil?
    end

    # Records that the terminal speaks the kitty keyboard protocol, with *flags*
    # the active enhancement bits it reported. Called by `Tput#probe!`.
    def confirm_kitty_keyboard!(flags : Int32, source : String) : Nil
      @kitty_keyboard_flags = flags
      @sources["kitty_keyboard"] = source
    end

    # Records the terminal's `modifyOtherKeys` *level*. Called by `Tput#probe!`.
    def confirm_modify_other_keys!(level : Int32, source : String) : Nil
      @modify_other_keys = level
      @sources["modify_other_keys"] = source
    end

    # iTerm2 detection by env, replicated here because `Features` is constructed
    # before `Emulator` (see `Tput#initialize`), so `@tput.emulator` is not yet
    # available. Mirrors `Emulator#iterm2?`.
    private def iterm2_env? : Bool
      (ENV["TERM_PROGRAM"]? == "iTerm.app") || to_b(ENV["ITERM_SESSION_ID"]?)
    end

    # Detects number of colors supported by the terminal (2 - 16M)
    def detect_number_of_colors
      # Truecolor (detected separately) means the full 16M-color space.
      if @truecolor
        @sources["number_of_colors"] = "24-bit truecolor (#{@sources["truecolor"]?})"
        return 0x1000000 # 16_777_216
      end

      colors = 2

      ENV["TERM"]?.try do |term|
        if md = /(\d+)colors?$/.match term
          colors = md[1].to_i
          @sources["number_of_colors"] = %(env TERM="#{term}" (#{colors}-color suffix))
        end
      end

      if colors == 2
        @tput.terminfo.try do |t|
          t.get?(::Unibilium::Entry::Numeric::Max_colors).try do |v|
            colors = v
            @sources["number_of_colors"] = "terminfo numeric capability Max_colors = #{v}"
          end
        end
      end

      @sources["number_of_colors"] ||= "default (2 — no COLORTERM/TERM/terminfo color info)"
      colors
    end

    # Parses terminal's ACS characters and returns
    # ASCII->ACS and ACS->ASCII mappings.
    def parse_acs
      acsc = ACSHash.new
      acscr = ACSHash.new
      if @pc_rom_charset
        @sources["acsc"] = "skipped — PC ROM charset in use"
        return {acsc, acscr}
      end

      acs_chars = @tput.shim.try(&.acs_chars.try { |v| String.new v }) || ""
      @sources["acsc"] = @tput.shim ? "terminfo acs_chars capability" : "default — no terminfo (hardcoded mode)"

      # `acs_chars` is a flat list of (canonical, terminal-specific) character
      # pairs. The *first* char of each pair is the canonical VT100 ACS code, and
      # that canonical code is what determines the glyph. Walk the string strictly
      # pair-by-pair: searching for each char with `index` instead lands on a
      # pair's second (terminal-specific) member whenever the mapping isn't the
      # identity, then pairs it with the wrong neighbour — yielding wrong glyphs
      # and spurious keys.
      i = 0
      while i + 1 < acs_chars.size
        ch = acs_chars[i]
        i += 2
        next unless ACSC::Data[ch]?
        ch2 = ACSC::Data[ch][broken_acs? ? 2 : 1].as Char

        acsc[ch] = ch2
        acscr[ch2] = ch
      end

      {acsc, acscr}
    end

    # Gets console codepage (Windows-specific)
    def get_console_cp
      0
    end

    private def term_has_unicode?
      @tput.terminfo.try do |t|
        if t.extensions.has?("U8")
          return t.extensions.get_num("U8") > 0
        end
      end
    end
  end
end
