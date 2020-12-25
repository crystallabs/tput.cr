class Tput
  module Output
    module Charset
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      # ESC (,),*,+,-,. Designate G0-G2 Character Set.
      def charset(val, level = 0)

        # See also:
        # acs_chars / acsc / ac
        # enter_alt_charset_mode / smacs / as
        # exit_alt_charset_mode / rmacs / ae
        # enter_pc_charset_mode / smpch / S2
        # exit_pc_charset_mode / rmpch / S3

        case (level)
          when 0
            level = "("
          when 1
            level = ")"
          when 2
            level = "*"
          when 3
            level = "+"
        end

        name = val.is_a?(String) ? val.downcase : val

        case (name)
          when "acs", "scld" # DEC Special Character and Line Drawing Set.
            return true if put(s.smacs?)
            val = "0"
          when "uk" # UK
            val = "A"
          when "us", "usascii", "ascii" # United States (USASCII).
            return true if put(s.rmacs?)
            val = "B"
          when "dutch" # Dutch
            val = "4"
          when "finnish" # Finnish
            #val = "C"
            val = "5"
          when "french" # French
            val = "R"
          when "frenchcanadian" # FrenchCanadian
            val = "Q"
          when "german"  # German
            val = "K"
          when "italian" # Italian
            val = "Y"
          when "norwegiandanish" # NorwegianDanish
            #val = "E"
            val = "6"
          when "spanish" # Spanish
            val = "Z"
          when "swedish" # Swedish
            #val = "H"
            val = "7"
          when "swiss" # Swiss
            val = "="
          when "isolatin" # ISOLatin (actually /A)
            val = "/A"
          else # Default
            return true if put(s.rmacs?)
            val = "B"
        end

        _write "\x1b(#{val}"
      end

      # TODO avoid use of strings
      def smacs
        charset "acs"
      end
      alias_previous enter_alt_charset_mode #, as # TODO can't alias to 'as'

      def rmacs
        charset "ascii"
      end
      alias_previous exit_alt_charset_mode, ae

      # ESC N
      # Single Shift Select of G2 Character Set
      # ( SS2 is 0x8e). This affects next character only.
      # ESC O
      # Single Shift Select of G3 Character Set
      # ( SS3 is 0x8f). This affects next character only.
      # ESC n
      # Invoke the G2 Character Set as GL (LS2).
      # ESC o
      # Invoke the G3 Character Set as GL (LS3).
      # ESC |
      # Invoke the G3 Character Set as GR (LS3R).
      # ESC }
      # Invoke the G2 Character Set as GR (LS2R).
      # ESC ~
      # Invoke the G1 Character Set as GR (LS1R).
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

        _write "\x1b#{val}"
      end

    end
  end
end
