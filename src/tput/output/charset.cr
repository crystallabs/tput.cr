class Tput
  module Output
    module Charset
      include Crystallabs::Helpers::Alias_Methods
      # include Crystallabs::Helpers::Boolean
      include Macros

      alias C = Tput::Namespace::Charset

      # Activate a different charset.
      #
      # Empty value resets to terminal default.
      #
      #     ESC (,),*,+,-,. Designate G0-G2 Character Set.
      #
      #     See also:
      #     acs_chars / acsc / ac
      #     enter_alt_charset_mode / smacs / as
      #     exit_alt_charset_mode / rmacs / ae
      #     enter_pc_charset_mode / smpch / S2
      #     exit_pc_charset_mode / rmpch / S3
      def charset=(charset : C?) # , level = 0)

        # case (level)
        #  when 0
        #    level = "("
        #  when 1
        #    level = ")"
        #  when 2
        #    level = "*"
        #  when 3
        #    level = "+"
        # end

        # name = val.is_a?(String) ? val.downcase : val

        val = case (charset)
              when C::ACS, C::SCLD
                return true if put(&.smacs?)
                :"0"
              when C::UK
                :"A"
              when C::ASCII
                return true if put(&.rmacs?)
                :"B"
              when C::DECCyrillic
                :"&4"
              when C::DECRussian
                :"&5"
              when C::DECSupplemental
                :"<"
              when C::DECSupplemental94
                :"%5"
              when C::DECTechnical
                :">"
              when C::Dutch
                :"4"
              when C::Finnish
                # :"C"
                :"5"
              when C::French
                # :"f"
                :"R"
              when C::FrenchCanadian
                # :"9"
                :"Q"
              when C::German
                :"K"
              when C::Greek
                :"\">"
              when C::Greek94
                :"\"?"
              when C::Hebrew
                :"%="
              when C::Hebrew94
                :"\"4"
              when C::Italian
                :"Y"
              when C::NorwegianDanish
                # :"`"
                # :"E"
                :"6"
              when C::Portugese
                :"%6"
              when C::SCS_NRCS
                :"%3"
              when C::Spanish
                :"Z"
              when C::Swedish
                # :"H"
                :"7"
              when C::Swiss
                :"="
              when C::Turkish
                :"%2"
              when C::Turkish94
                :"%0"
              when C::Isolatin
                :"/A"
              when nil # Default
                return true if put(&.rmacs?)
                :"B"
              else
                raise "Unsupported charset '#{charset}'"
              end

        _print { |io| io << "\e(" << val }
      end

      # Enter alternate (DEC TV100/ACS/SCLD) character set.
      #
      # Equivalent to:
      #     self.charset= Tput::Charset::ACS
      def enter_alt_charset_mode
        self.charset= C::ACS
      end

      alias_previous smacs # , as # TODO can't alias to 'as'

      # Exit any alternate character set by returning to terminal's default.
      #
      # Equivalent to:
      #     charset=()

      def exit_alt_charset_mode
        self.charset=()
      end

      alias_previous rmacs # , ae # Unclear name avoid aliasing to this

      # Set G character set.
      #
      # This method currently sets it non-configurable for the next character only.
      #
      #     ESC N
      #     Single Shift Select of G2 Character Set
      #     ( SS2 is 0x8e). This affects next character only.
      #     ESC O
      #     Single Shift Select of G3 Character Set
      #     ( SS3 is 0x8f). This affects next character only.
      #     ESC n
      #     Invoke the G2 Character Set as GL (LS2).
      #     ESC o
      #     Invoke the G3 Character Set as GL (LS3).
      #     ESC |
      #     Invoke the G3 Character Set as GR (LS3R).
      #     ESC }
      #     Invoke the G2 Character Set as GR (LS2R).
      #     ESC ~
      #     Invoke the G1 Character Set as GR (LS1R).

      def set_g(val)
        # Disabled originally
        # if (tput) put.S2()
        # if (tput) put.S3()
        case (val)
        when 1
          val = '~'
          # GR
        when 2
          # val = 'n'; # GL
          # val = '}'; # GR
          val = 'N'
          # Next Char Only
        when 3
          # val = 'o'; # GL
          # val = '|'; # GR
          val = 'O'
          # Next Char Only
        end

        _print { |io| io << "\e" << val }
      end
    end
  end
end
