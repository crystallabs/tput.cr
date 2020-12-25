require "json"

class Tput
  class Features
		include Crystallabs::Helpers::Logging
    include JSON::Serializable
		include Crystallabs::Helpers::Boolean

    alias ACSHash = Hash(String, String)

    getter? \
      unicode : Bool,
      broken_acs : Bool,
      pc_rom_charset : Bool,
      magic_cookie : Bool,
      padding : Bool,
      setbuf : Bool,
      acsc : ACSHash,
      acscr : ACSHash

    @[JSON::Field(ignore: true)]
    getter acsc : ACSHash

    @[JSON::Field(ignore: true)]
    getter acscr : ACSHash

    @[JSON::Field(ignore: true)]
    getter tput : Tput

    def initialize(@tput : Tput)
      @unicode        = detect_unicode
      @broken_acs     = detect_broken_acs
      @pc_rom_charset = detect_pc_rom_charset
      @magic_cookie   = detect_magic_cookie
      @padding        = detect_padding
      @setbuf         = detect_setbuf
      @acsc, @acscr   = parse_acs
    end

    def detect_unicode
      return true if \
        (@tput.force_unicode?) ||
			  (to_b ENV["NCURSES_FORCE_UNICODE"]?) ||
			  ({ ENV["LANG"]?, ENV["LANGUAGE"]?, ENV["LC_ALL"]?, ENV["LC_CTYPE"]? }.any? { |var| var.try &.=~(/utf\-?8/i) }) ||
        #(xterm?.try { ENV["XTERM_LOCALE"]?.try &.=~(/utf\-?8/i) }) ||
        ({% if flag? :windows %}get_console_cp == 65001{% end %})
      false
    end

		# Detects whether terminal has broken ACS.
    def detect_broken_acs
			# For some reason TERM=linux has smacs/rmacs, but it maps to `^[[11m`
			# and it does not switch to the DEC SCLD character set.
			# xterm: \x1b(0, screen: \x0e, linux: \x1b[11m (doesn't work)
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
      @tput.terminfo.try do |t|
        if t.extensions.has?("U8")
          return t.extensions.get_num("U8") > 0
        end
      end

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
			to_b ENV["NCURSES_NO_PADDING"]?, false
		end

		def detect_setbuf
			to_b ENV["NCURSES_NO_SETBUF"]?, false
		end

    # Parses terminal's ACS characters and returns
    # ASCII->ACS and ACS->ASCII mappings.
    def parse_acs
      acsc = ACSHash.new
      acscr = ACSHash.new
      return { acsc, acscr } if @pc_rom_charset
      
      acs_chars = @tput.shim.try(&.acs_chars.try { |v| String.new v }) || ""
      ACSC.each do |ch, _|
        next unless i = acs_chars.index ch

        nxt = acs_chars[(i+1)..(i+1)]?

        next if !nxt || !ACSC[nxt]?

        acsc[ch] = ACSC[nxt]
        acscr[ACSC[nxt]] = ch
      end

      { acsc, acscr }
    end

    # TODO
		def get_console_cp
			0
		end
  end
end
