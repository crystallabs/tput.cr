class Tput
  # Various tables and static/fixed data.
  module ACSC
    include Crystallabs::Helpers::Logging

    # ACS = Alternate Character Set.
    # DEC VT100 Special Character and Line Drawing Set.
    Data = {
      # acsc   ACS           Unicode      ASCII    Glyph
      # char   Name          Default      Default  Name
      # ----------------------------------------------------------------------------
      '0' => {:BLOCK, '\u25ae', '#'},      # ▮ solid square block
      'h' => {:BOARD, '\u2592', '#'},      # ▒ board of squares
      'v' => {:BTEE, '\u2534', '+'},       # ┴ bottom tee
      '~' => {:BULLET, '\u00b7', 'o'},     # · bullet
      'a' => {:CKBOARD, '\u2592', ':'},    # ▒ checker board (stipple)
      '.' => {:DARROW, '\u2193', 'v'},     # ↓ arrow pointing down
      'f' => {:DEGREE, '\u00b0', '\''},    # ° degree symbol
      '`' => {:DIAMOND, '\u25c6', '+'},    # ◆ diamond
      '>' => {:GEQUAL, '\u2265', '>'},     # ≥ greater-than-or-equal-to
      'q' => {:HLINE, '\u2500', '-'},      # ─ horizontal line
      'i' => {:LANTERN, '\u2603', '#'},    # ☃ lantern symbol
      ',' => {:LARROW, '\u2190', '<'},     # ← arrow pointing left
      'y' => {:LEQUAL, '\u2264', '<'},     # ≤ less-than-or-equal-to
      'm' => {:LLCORNER, '\u2514', '+'},   # └ lower left-hand corner
      'j' => {:LRCORNER, '\u2518', '+'},   # ┘ lower right-hand corner
      't' => {:LTEE, '\u2524', '+'},       # ┤ left tee
      '|' => {:NEQUAL, '\u2260', '!'},     # ≠ not-equal
      '{' => {:PI, '\u03c0', '*'},         # π greek pi
      'g' => {:PLMINUS, '\u00b1', '#'},    # ± plus/minus
      'n' => {:PLUS, '\u253c', '+'},       # ┼ plus
      '+' => {:RARROW, '\u2192', '>'},     # → arrow pointing right
      'u' => {:RTEE, '\u251c', '+'},       # ├ right tee
      'o' => {:S1, '\u23ba', '-'},         # ⎺ scan line 1
      'p' => {:S3, '\u23bb', '-'},         # ⎻ scan line 3
      'r' => {:S7, '\u23bc', '-'},         # ⎼ scan line 7
      's' => {:S9, '\u23bd', '_'},         # ⎽ scan line 9
      '}' => {:STERLING, '\u00a3', 'f'},   # £ pound-sterling symbol
      'w' => {:TTEE, '\u252c', '+'},       # ┬ top tee
      '-' => {:UARROW, '\u2191', '^'},     # ↑ arrow pointing up
      'l' => {:ULCORNER, '\u250c', '+'},   # ┌ upper left-hand corner
      'k' => {:URCORNER, '\u2510', '+'},   # ┐ upper right-hand corner
      'x' => {:VLINE, '\u2502', '|'},      # │ vertical line
      'V' => {:T_BTEE, '\u253b', '+'},     # ┻ thick tee pointing up
      'Q' => {:T_HLINE, '\u2501', '-'},    # ━ thick horizontal line
      'M' => {:T_LLCORNER, '\u2517', '+'}, # ┗ thick lower left corner
      'J' => {:T_LRCORNER, '\u251b', '+'}, # ┛ thick lower right corner
      'T' => {:T_LTEE, '\u252b', '+'},     # ┫ thick tee pointing right
      'N' => {:T_PLUS, '\u254b', '+'},     # ╋ thick large plus
      'U' => {:T_RTEE, '\u2523', '+'},     # ┣ thick tee pointing left
      'W' => {:T_TTEE, '\u2533', '+'},     # ┳ thick tee pointing down
      'L' => {:T_ULCORNER, '\u250f', '+'}, # ┏ thick upper left corner
      'K' => {:T_URCORNER, '\u2513', '+'}, # ┓ thick upper right corner
      'X' => {:T_VLINE, '\u2503', '|'},    # ┃ thick vertical line
      'H' => {:D_BTEE, '\u2569', '+'},     # ╩ double tee pointing up
      'R' => {:D_HLINE, '\u2550', '-'},    # ═ double horizontal line
      'D' => {:D_LLCORNER, '\u255a', '+'}, # ╚ double lower left corner
      'A' => {:D_LRCORNER, '\u255d', '+'}, # ╝ double lower right corner
      'F' => {:D_LTEE, '\u2560', '+'},     # ╠ double tee pointing right
      'E' => {:D_PLUS, '\u256c', '+'},     # ╬ double large plus
      'G' => {:D_RTEE, '\u2563', '+'},     # ╣ double tee pointing left
      'I' => {:D_TTEE, '\u2566', '+'},     # ╦ double tee pointing down
      'C' => {:D_ULCORNER, '\u2554', '+'}, # ╔ double upper left corner
      'B' => {:D_URCORNER, '\u2557', '+'}, # ╗ double upper right corner
      'Y' => {:D_VLINE, '\u2551', '|'},    # ║ double vertical line
    }

    # The best way to define a new device's graphics set is to add a
    # column to a copy of this table for your terminal, giving the
    # character which (when emitted between smacs/rmacs switches) will
    # be rendered as the corresponding graphic.  Then read off the
    # VT100/your terminal character pairs right to left in sequence;
    # these become the ACSC string.
  end
end
