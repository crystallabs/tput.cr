class Tput
  module Output
    module Charset
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      alias C = Tput::Namespace::Charset

      # ESC (,),*,+,-,. Designate G0-G2 Character Set.
      #
      #     See also:
      #     acs_chars / acsc / ac
      #     enter_alt_charset_mode / smacs / as
      #     exit_alt_charset_mode / rmacs / ae
      #     enter_pc_charset_mode / smpch / S2
      #     exit_pc_charset_mode / rmpch / S3
      def charset(charset : Tput::Namespace::Charset?) #, level = 0)

        #case (level)
        #  when 0
        #    level = "("
        #  when 1
        #    level = ")"
        #  when 2
        #    level = "*"
        #  when 3
        #    level = "+"
        #end

        #name = val.is_a?(String) ? val.downcase : val

        case (charset)
          when C::ACS, C::SCLD
            return true if put(smacs?)
            val = "0"
          when C::UK
            val = "A"
          when C::ASCII
            return true if put(rmacs?)
            val = "B"
          when C::Dutch
            val = "4"
          when C::Finnish
            #val = "C"
            val = "5"
          when C::French
            val = "R"
          when C::FrenchCanadian
            val = "Q"
          when C::German
            val = "K"
          when C::Italian
            val = "Y"
          when C::NorwegianDanish
            #val = "E"
            val = "6"
          when C::Spanish
            val = "Z"
          when C::Swedish
            #val = "H"
            val = "7"
          when C::Swiss
            val = "="
          when C::Isolatin
            val = "/A"
          when nil # Default
            return true if put(rmacs?)
            val = "B"
          else
            raise "Unsupported charset '#{charset}'"
        end

        _print { |io| io << "\e(" << val }
      end

      # Enter ACS/SCLD character set
      def enter_alt_charset_mode 
        charset Tput::Namespace::Charset::ACS
      end
      alias_previous smacs #, as # TODO can't alias to 'as'

      # Exit any character set by returning back to ASCII
      def exit_alt_charset_mode
        charset Tput::Namespace::Charset::ASCII
      end
      alias_previous rmacs, ae

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
            val = '~'; # GR
          when 2
            #val = 'n'; # GL
            #val = '}'; # GR
            val = 'N'; # Next Char Only
          when 3
            #val = 'o'; # GL
            #val = '|'; # GR
            val = 'O'; # Next Char Only
        end

        _print { |io| io << "\e" << val }
      end

    end
  end
end
