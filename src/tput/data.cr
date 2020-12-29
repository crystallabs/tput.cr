class Tput

  # Various tables and static/fixed data.
  module Data
    include Crystallabs::Helpers::Logging

    # ACS = Alternate Character Set.
    # DEC Special Character and Line Drawing Set.
    #
    # Mapping of ACS ascii characters to the most similar-looking UTF characters.
    # This is a default list; in a particular terminal it may be affected by the
    # term's value of string capability "acs_chars".
    #
    #      Glyph                       ACS            Ascii     acsc     acsc
    #      Name                        Name           Default   Char     Value
    #      ────────────────────────────────────────────────────────────────────
    #      arrow pointing right        ACS_RARROW     >         +        0x2b
    #      arrow pointing left         ACS_LARROW     <         ,        0x2c
    #      arrow pointing up           ACS_UARROW     ^         -        0x2d
    #      arrow pointing down         ACS_DARROW     v         .        0x2e
    #      solid square block          ACS_BLOCK      #         0        0x30
    #      diamond                     ACS_DIAMOND    +         `        0x60
    #      checker board (stipple)     ACS_CKBOARD    :         a        0x61
    #      degree symbol               ACS_DEGREE     \         f        0x66
    #      plus/minus                  ACS_PLMINUS    #         g        0x67
    #      board of squares            ACS_BOARD      #         h        0x68
    #      lantern symbol              ACS_LANTERN    #         i        0x69
    #      lower right corner          ACS_LRCORNER   +         j        0x6a
    #      upper right corner          ACS_URCORNER   +         k        0x6b
    #      upper left corner           ACS_ULCORNER   +         l        0x6c
    #      lower left corner           ACS_LLCORNER   +         m        0x6d
    #      large plus or crossover     ACS_PLUS       +         n        0x6e
    #      scan line 1                 ACS_S1         ~         o        0x6f
    #      scan line 3                 ACS_S3         -         p        0x70
    #      horizontal line             ACS_HLINE      -         q        0x71
    #      scan line 7                 ACS_S7         -         r        0x72
    #      scan line 9                 ACS_S9         _         s        0x73
    #      tee pointing right          ACS_LTEE       +         t        0x74
    #      tee pointing left           ACS_RTEE       +         u        0x75
    #      tee pointing up             ACS_BTEE       +         v        0x76
    #      tee pointing down           ACS_TTEE       +         w        0x77
    #      vertical line               ACS_VLINE      |         x        0x78
    #      less-than-or-equal-to       ACS_LEQUAL     <         y        0x79
    #      greater-than-or-equal-to    ACS_GEQUAL     >         z        0x7a
    #      greek pi                    ACS_PI         *         {        0x7b
    #      not-equal                   ACS_NEQUAL     !         |        0x7c
    #      UK pound sign               ACS_STERLING   f         }        0x7d
    #      bullet                      ACS_BULLET     o         ~        0x7e
    #
    # The best way to define a new device's graphics set is to add a
    # column to a copy of this table for your terminal, giving the
    # character which (when emitted between smacs/rmacs switches) will
    # be rendered as the corresponding graphic.  Then read off the
    # VT100/your terminal character pairs right to left in sequence;
    # these become the ACSC string.
    ACSC = {    # (0
      # Char         # Proposed Unicode equivalent 
      # 0x5f Blank     U+00A0 NO-BREAK SPACE 
      "`" => "\u25c6", # "◆"
      "a" => "\u2592", # "▒"
      "b" => "\u0009", # "\t"
      "c" => "\u000c", # "\f"
      "d" => "\u000d", # "\r"
      "e" => "\u000a", # "\n"
      "f" => "\u00b0", # "°"
      "g" => "\u00b1", # "±"
      "h" => "\u2424", # "\u2424" (NL - newline)
      "i" => "\u000b", # "\v"
      "j" => "\u2518", # "┘"
      "k" => "\u2510", # "┐"
      "l" => "\u250c", # "┌"
      "m" => "\u2514", # "└"
      "n" => "\u253c", # "┼"
      "o" => "\u23ba", # "⎺"
      "p" => "\u23bb", # "⎻"
      "q" => "\u2500", # "─"
      "r" => "\u23bc", # "⎼"
      "s" => "\u23bd", # "⎽"
      "t" => "\u251c", # "├"
      "u" => "\u2524", # "┤"
      "v" => "\u2534", # "┴"
      "w" => "\u252c", # "┬"
      "x" => "\u2502", # "│"
      "y" => "\u2264", # "≤"
      "z" => "\u2265", # "≥"
      "{" => "\u03c0", # "π"
      "|" => "\u2260", # "≠"
      "}" => "\u00a3", # "£"
      "~" => "\u00b7"  # "·"
    }

    # Mapping of ACS unicode characters to the most similar-looking ascii characters.
    UtoA = {
      "\u25c6" => "*", # "◆"
      "\u2592" => " ", # "▒"
      # "\u0009" => "\t", # "\t"
      # "\u000c" => "\f", # "\f"
      # "\u000d" => "\r", # "\r"
      # "\u000a" => "\n", # "\n"
      "\u00b0" => "*", # "°"
      "\u00b1" => "+", # "±"
      "\u2424" => "\n", # "\u2424" (NL)
      # "\u000b" => "\v", # "\v"
      "\u2518" => "+", # "┘"
      "\u2510" => "+", # "┐"
      "\u250c" => "+", # "┌"
      "\u2514" => "+", # "└"
      "\u253c" => "+", # "┼"
      "\u23ba" => "-", # "⎺"
      "\u23bb" => "-", # "⎻"
      "\u2500" => "-", # "─"
      "\u23bc" => "-", # "⎼"
      "\u23bd" => "_", # "⎽"
      "\u251c" => "+", # "├"
      "\u2524" => "+", # "┤"
      "\u2534" => "+", # "┴"
      "\u252c" => "+", # "┬"
      "\u2502" => "|", # "│"
      "\u2264" => "<", # "≤"
      "\u2265" => ">", # "≥"
      "\u03c0" => "?", # "π"
      "\u2260" => "=", # "≠"
      "\u00a3" => "?", # "£"
      "\u00b7" => "*"  # "·"
    }

  end
end
