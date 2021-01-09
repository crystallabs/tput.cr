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

    getter? setbuf : Bool

    # Number of colors supported by the terminal
    getter number_of_colors : Int32

    # Color support flag (a yes/no)
    getter? color : Bool

    getter acsc : ACSHash

    @[JSON::Field(ignore: true)]
    getter acscr : ACSHash

    @[JSON::Field(ignore: true)]
    # :nodoc:
    getter tput : Tput

    def initialize(@tput : Tput)
      @unicode = detect_unicode
      @broken_acs = detect_broken_acs
      @pc_rom_charset = detect_pc_rom_charset
      @magic_cookie = detect_magic_cookie
      @padding = detect_padding
      @setbuf = detect_setbuf
      @number_of_colors = detect_number_of_colors
      @color = @number_of_colors > 2
      @acsc, @acscr = parse_acs

      Log.trace { my self }
    end

    def inspect(io)
      to_json io
    end

    # Detects Unicode support
    def detect_unicode
      if (@tput.force_unicode?) ||
         (to_b ENV["NCURSES_FORCE_UNICODE"]?) ||
         # (term_has_unicode?) || # Not always trustworthy:
         ({ENV["XTERM_LOCALE"]?,
           ENV["LANG"]?,
           ENV["LANGUAGE"]?,
           ENV["LC_ALL"]?,
           ENV["LC_CTYPE"]?}.any? { |var| var.try &.=~(/utf\-?8/i) }) ||
         (ENV["TERM"]?.try &.=~(/\bunicode\b/i)) ||
         # (@tput.emulator.xterm?.try { ENV["XTERM_LOCALE"]?.try &.=~(/utf\-?8/i) }) || # Done above, unspecific to xterm
         ({% if flag? :windows %}get_console_cp == 65001{% end %})
        return true
      end

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
      return true if to_b ENV["NCURSES_NO_UTF8_ACS"]?

      # If the terminal supports unicode, we don't need ACS.
      return true if term_has_unicode?

      # The linux console is just broken for some reason.
      # Apparently the Linux console does not support ACS,
      # but it does support the PC ROM character set.
      return true if @tput.terminfo.try(&.name.==("linux")) || ENV["TERM"]?.try(&.==("linux"))

      # PC alternate charset
      # if (acsc.indexOf('+\x10,\x11-\x18.\x190') === 0) {
      return true if detect_pc_rom_charset

      # XXX Possibly enable when tcap support is in. While we only support
      # terminfo, this is not relevant.
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
            return true if (epm == eam) && (shim.exit_pc_charset_mode? == shim.exit_alt_charset_mode?)
          end
        end
      end

      false
    end

    def detect_magic_cookie
      to_b ENV["NCURSES_NO_MAGIC_COOKIE"]?, false
    end

    def detect_padding
      v = to_b ENV["NCURSES_NO_PADDING"]?, false
      unless v
        # raise "Padding not supported yet"
        # TODO - Padding is always disabled currently
      end
      # return !!v
      false
    end

    def detect_setbuf
      to_b ENV["NCURSES_NO_SETBUF"]?, false
    end

    # Detects number of colors supported by the terminal (2 - 16M)
    def detect_number_of_colors
      colors = 2

      # NOTE Which of these 2 tests should come first?

      ENV["TERM"]?.try do |term|
        if md = /(\d+)colors?$/.match term
          colors = md[1].to_i
        end
      end

      if colors == 2
        @tput.terminfo.try do |t|
          t.get?(::Unibilium::Entry::Numeric::Max_colors).try do |v|
            colors = v
          end
        end
      end

      colors
    end

    # Parses terminal's ACS characters and returns
    # ASCII->ACS and ACS->ASCII mappings.
    def parse_acs
      acsc = ACSHash.new
      acscr = ACSHash.new
      return {acsc, acscr} if @pc_rom_charset

      acs_chars = @tput.shim.try(&.acs_chars.try { |v| String.new v }) || ""
      ACSC::Data.each do |ch, data|
        next unless i = acs_chars.index ch

        nxt = acs_chars[i + 1]?
        next if !nxt || !ACSC::Data[nxt]?
        ch2 = ACSC::Data[nxt][broken_acs? ? 2 : 1].as Char

        acsc[ch] = ch2
        acscr[ch2] = acsc[ch]
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
