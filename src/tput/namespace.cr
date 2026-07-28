require "json"

class Tput
  module Namespace
    enum Color
      None                 =        0
      AliceBlue            = 0xF0F8FF
      AntiqueWhite         = 0xFAEBD7
      AntiqueWhite1        = 0xFFEFDB
      AntiqueWhite2        = 0xEEDFCC
      AntiqueWhite3        = 0xCDC0B0
      AntiqueWhite4        = 0x8B8378
      Aquamarine           = 0x7FFFD4
      Aquamarine1          = 0x7FFFD4
      Aquamarine2          = 0x76EEC6
      Aquamarine3          = 0x66CDAA
      Azure                = 0xF0FFFF
      Azure1               = 0xF0FFFF
      Azure2               = 0xE0EEEE
      Azure3               = 0xC1CDCD
      Azure4               = 0x838B8B
      Beige                = 0xF5F5DC
      Bisque               = 0xFFE4C4
      Bisque1              = 0xFFE4C4
      Bisque2              = 0xEED5B7
      Bisque3              = 0xCDB79E
      Bisque4              = 0x8B7D6B
      BlanchedAlmond       = 0xFFEBCD
      Blue                 = 0x0000FF
      BlueViolet           = 0x8A2BE2
      Brown                = 0xA52A2A
      Brown1               = 0xFF4040
      Brown2               = 0xEE3B3B
      Brown3               = 0xCD3333
      Brown4               = 0x8B2323
      Burlywood            = 0xDEB887
      Burlywood1           = 0xFFD39B
      Burlywood2           = 0xEEC591
      Burlywood3           = 0xCDAA7D
      Burlywood4           = 0x8B7355
      CadetBlue1           = 0x98F5FF
      CadetBlue2           = 0x8EE5EE
      CadetBlue3           = 0x7AC5CD
      Chartreuse           = 0x7FFF00
      Chartreuse1          = 0x7FFF00
      Chartreuse2          = 0x76EE00
      Chartreuse3          = 0x66CD00
      Chocolate            = 0xD2691E
      Chocolate1           = 0xFF7F24
      Chocolate2           = 0xEE7621
      Chocolate3           = 0xCD661D
      Chocolate4           = 0x8B4513
      Coral                = 0xFF7F50
      Coral1               = 0xFF7256
      Coral2               = 0xEE6A50
      Coral3               = 0xCD5B45
      Coral4               = 0x8B3E2F
      CornflowerBlue       = 0x6495ED
      Cornsilk             = 0xFFF8DC
      Cornsilk1            = 0xFFF8DC
      Cornsilk2            = 0xEEE8CD
      Cornsilk3            = 0xCDC8B1
      Cornsilk4            = 0x8B8878
      DarkBlue             = 0x00008B
      DarkCyan             = 0x008B8B
      DarkGoldenrod        = 0xB8860B
      DarkGoldenrod1       = 0xFFB90F
      DarkGoldenrod2       = 0xEEAD0E
      DarkGoldenrod3       = 0xCD950C
      DarkGoldenrod4       = 0x8B6508
      DarkGray             = 0xA9A9A9
      DarkGrey             = 0xA9A9A9
      DarkKhaki            = 0xBDB76B
      DarkMagenta          = 0x8B008B
      DarkOliveGreen1      = 0xCAFF70
      DarkOliveGreen2      = 0xBCEE68
      DarkOliveGreen3      = 0xA2CD5A
      DarkOliveGreen4      = 0x6E8B3D
      DarkOrange           = 0xFF8C00
      DarkOrange1          = 0xFF7F00
      DarkOrange2          = 0xEE7600
      DarkOrange3          = 0xCD6600
      DarkOrange4          = 0x8B4500
      DarkOrchid           = 0x9932CC
      DarkOrchid1          = 0xBF3EFF
      DarkOrchid2          = 0xB23AEE
      DarkOrchid3          = 0x9A32CD
      DarkOrchid4          = 0x68228B
      DarkRed              = 0x8B0000
      DarkSalmon           = 0xE9967A
      DarkSeaGreen         = 0x8FBC8F
      DarkSeaGreen1        = 0xC1FFC1
      DarkSeaGreen2        = 0xB4EEB4
      DarkSeaGreen3        = 0x9BCD9B
      DarkSeaGreen4        = 0x698B69
      DarkSlateGray1       = 0x97FFFF
      DarkSlateGray2       = 0x8DEEEE
      DarkSlateGray3       = 0x79CDCD
      DarkViolet           = 0x9400D3
      DebianRed            = 0xD70751
      DeepPink             = 0xFF1493
      DeepPink1            = 0xFF1493
      DeepPink2            = 0xEE1289
      DeepPink3            = 0xCD1076
      DeepPink4            = 0x8B0A50
      DimGray              = 0x696969
      DimGrey              = 0x696969
      Firebrick            = 0xB22222
      Firebrick1           = 0xFF3030
      Firebrick2           = 0xEE2C2C
      Firebrick3           = 0xCD2626
      Firebrick4           = 0x8B1A1A
      FloralWhite          = 0xFFFAF0
      Gainsboro            = 0xDCDCDC
      GhostWhite           = 0xF8F8FF
      Gold                 = 0xFFD700
      Gold1                = 0xFFD700
      Gold2                = 0xEEC900
      Gold3                = 0xCDAD00
      Gold4                = 0x8B7500
      Goldenrod            = 0xDAA520
      Goldenrod1           = 0xFFC125
      Goldenrod2           = 0xEEB422
      Goldenrod3           = 0xCD9B1D
      Goldenrod4           = 0x8B6914
      Gray                 = 0xBEBEBE
      Gray100              = 0xFFFFFF
      Gray40               = 0x666666
      Gray41               = 0x696969
      Gray42               = 0x6B6B6B
      Gray43               = 0x6E6E6E
      Gray44               = 0x707070
      Gray45               = 0x737373
      Gray46               = 0x757575
      Gray47               = 0x787878
      Gray48               = 0x7A7A7A
      Gray49               = 0x7D7D7D
      Gray50               = 0x7F7F7F
      Gray51               = 0x828282
      Gray52               = 0x858585
      Gray53               = 0x878787
      Gray54               = 0x8A8A8A
      Gray55               = 0x8C8C8C
      Gray56               = 0x8F8F8F
      Gray57               = 0x919191
      Gray58               = 0x949494
      Gray59               = 0x969696
      Gray60               = 0x999999
      Gray61               = 0x9C9C9C
      Gray62               = 0x9E9E9E
      Gray63               = 0xA1A1A1
      Gray64               = 0xA3A3A3
      Gray65               = 0xA6A6A6
      Gray66               = 0xA8A8A8
      Gray67               = 0xABABAB
      Gray68               = 0xADADAD
      Gray69               = 0xB0B0B0
      Gray70               = 0xB3B3B3
      Gray71               = 0xB5B5B5
      Gray72               = 0xB8B8B8
      Gray73               = 0xBABABA
      Gray74               = 0xBDBDBD
      Gray75               = 0xBFBFBF
      Gray76               = 0xC2C2C2
      Gray77               = 0xC4C4C4
      Gray78               = 0xC7C7C7
      Gray79               = 0xC9C9C9
      Gray80               = 0xCCCCCC
      Gray81               = 0xCFCFCF
      Gray82               = 0xD1D1D1
      Gray83               = 0xD4D4D4
      Gray84               = 0xD6D6D6
      Gray85               = 0xD9D9D9
      Gray86               = 0xDBDBDB
      Gray87               = 0xDEDEDE
      Gray88               = 0xE0E0E0
      Gray89               = 0xE3E3E3
      Gray90               = 0xE5E5E5
      Gray91               = 0xE8E8E8
      Gray92               = 0xEBEBEB
      Gray93               = 0xEDEDED
      Gray94               = 0xF0F0F0
      Gray95               = 0xF2F2F2
      Gray96               = 0xF5F5F5
      Gray97               = 0xF7F7F7
      Gray98               = 0xFAFAFA
      Gray99               = 0xFCFCFC
      GreenYellow          = 0xADFF2F
      Grey                 = 0xBEBEBE
      Grey100              = 0xFFFFFF
      Grey40               = 0x666666
      Grey41               = 0x696969
      Grey42               = 0x6B6B6B
      Grey43               = 0x6E6E6E
      Grey44               = 0x707070
      Grey45               = 0x737373
      Grey46               = 0x757575
      Grey47               = 0x787878
      Grey48               = 0x7A7A7A
      Grey49               = 0x7D7D7D
      Grey50               = 0x7F7F7F
      Grey51               = 0x828282
      Grey52               = 0x858585
      Grey53               = 0x878787
      Grey54               = 0x8A8A8A
      Grey55               = 0x8C8C8C
      Grey56               = 0x8F8F8F
      Grey57               = 0x919191
      Grey58               = 0x949494
      Grey59               = 0x969696
      Grey60               = 0x999999
      Grey61               = 0x9C9C9C
      Grey62               = 0x9E9E9E
      Grey63               = 0xA1A1A1
      Grey64               = 0xA3A3A3
      Grey65               = 0xA6A6A6
      Grey66               = 0xA8A8A8
      Grey67               = 0xABABAB
      Grey68               = 0xADADAD
      Grey69               = 0xB0B0B0
      Grey70               = 0xB3B3B3
      Grey71               = 0xB5B5B5
      Grey72               = 0xB8B8B8
      Grey73               = 0xBABABA
      Grey74               = 0xBDBDBD
      Grey75               = 0xBFBFBF
      Grey76               = 0xC2C2C2
      Grey77               = 0xC4C4C4
      Grey78               = 0xC7C7C7
      Grey79               = 0xC9C9C9
      Grey80               = 0xCCCCCC
      Grey81               = 0xCFCFCF
      Grey82               = 0xD1D1D1
      Grey83               = 0xD4D4D4
      Grey84               = 0xD6D6D6
      Grey85               = 0xD9D9D9
      Grey86               = 0xDBDBDB
      Grey87               = 0xDEDEDE
      Grey88               = 0xE0E0E0
      Grey89               = 0xE3E3E3
      Grey90               = 0xE5E5E5
      Grey91               = 0xE8E8E8
      Grey92               = 0xEBEBEB
      Grey93               = 0xEDEDED
      Grey94               = 0xF0F0F0
      Grey95               = 0xF2F2F2
      Grey96               = 0xF5F5F5
      Grey97               = 0xF7F7F7
      Grey98               = 0xFAFAFA
      Grey99               = 0xFCFCFC
      Honeydew             = 0xF0FFF0
      Honeydew1            = 0xF0FFF0
      Honeydew2            = 0xE0EEE0
      Honeydew3            = 0xC1CDC1
      Honeydew4            = 0x838B83
      HotPink              = 0xFF69B4
      HotPink1             = 0xFF6EB4
      HotPink2             = 0xEE6AA7
      HotPink3             = 0xCD6090
      HotPink4             = 0x8B3A62
      IndianRed            = 0xCD5C5C
      IndianRed1           = 0xFF6A6A
      IndianRed2           = 0xEE6363
      IndianRed3           = 0xCD5555
      IndianRed4           = 0x8B3A3A
      Ivory                = 0xFFFFF0
      Ivory1               = 0xFFFFF0
      Ivory2               = 0xEEEEE0
      Ivory3               = 0xCDCDC1
      Ivory4               = 0x8B8B83
      Khaki                = 0xF0E68C
      Khaki1               = 0xFFF68F
      Khaki2               = 0xEEE685
      Khaki3               = 0xCDC673
      Khaki4               = 0x8B864E
      Lavender             = 0xE6E6FA
      LavenderBlush        = 0xFFF0F5
      LavenderBlush1       = 0xFFF0F5
      LavenderBlush2       = 0xEEE0E5
      LavenderBlush3       = 0xCDC1C5
      LavenderBlush4       = 0x8B8386
      LawnGreen            = 0x7CFC00
      LemonChiffon         = 0xFFFACD
      LemonChiffon1        = 0xFFFACD
      LemonChiffon2        = 0xEEE9BF
      LemonChiffon3        = 0xCDC9A5
      LemonChiffon4        = 0x8B8970
      LightBlue            = 0xADD8E6
      LightBlue1           = 0xBFEFFF
      LightBlue2           = 0xB2DFEE
      LightBlue3           = 0x9AC0CD
      LightBlue4           = 0x68838B
      LightCoral           = 0xF08080
      LightCyan            = 0xE0FFFF
      LightCyan1           = 0xE0FFFF
      LightCyan2           = 0xD1EEEE
      LightCyan3           = 0xB4CDCD
      LightCyan4           = 0x7A8B8B
      LightGoldenrod       = 0xEEDD82
      LightGoldenrod1      = 0xFFEC8B
      LightGoldenrod2      = 0xEEDC82
      LightGoldenrod3      = 0xCDBE70
      LightGoldenrod4      = 0x8B814C
      LightGoldenrodYellow = 0xFAFAD2
      LightGray            = 0xD3D3D3
      LightGreen           = 0x90EE90
      LightGrey            = 0xD3D3D3
      LightPink            = 0xFFB6C1
      LightPink1           = 0xFFAEB9
      LightPink2           = 0xEEA2AD
      LightPink3           = 0xCD8C95
      LightPink4           = 0x8B5F65
      LightSalmon          = 0xFFA07A
      LightSalmon1         = 0xFFA07A
      LightSalmon2         = 0xEE9572
      LightSalmon3         = 0xCD8162
      LightSalmon4         = 0x8B5742
      LightSkyBlue         = 0x87CEFA
      LightSkyBlue1        = 0xB0E2FF
      LightSkyBlue2        = 0xA4D3EE
      LightSkyBlue3        = 0x8DB6CD
      LightSlateBlue       = 0x8470FF
      LightSlateGray       = 0x778899
      LightSlateGrey       = 0x778899
      LightSteelBlue       = 0xB0C4DE
      LightSteelBlue1      = 0xCAE1FF
      LightSteelBlue2      = 0xBCD2EE
      LightSteelBlue3      = 0xA2B5CD
      LightSteelBlue4      = 0x6E7B8B
      LightYellow          = 0xFFFFE0
      LightYellow1         = 0xFFFFE0
      LightYellow2         = 0xEEEED1
      LightYellow3         = 0xCDCDB4
      LightYellow4         = 0x8B8B7A
      Linen                = 0xFAF0E6
      Magenta              = 0xFF00FF
      Magenta1             = 0xFF00FF
      Magenta2             = 0xEE00EE
      Magenta3             = 0xCD00CD
      Magenta4             = 0x8B008B
      Maroon               = 0xB03060
      Maroon1              = 0xFF34B3
      Maroon2              = 0xEE30A7
      Maroon3              = 0xCD2990
      Maroon4              = 0x8B1C62
      MediumAquamarine     = 0x66CDAA
      MediumOrchid         = 0xBA55D3
      MediumOrchid1        = 0xE066FF
      MediumOrchid2        = 0xD15FEE
      MediumOrchid3        = 0xB452CD
      MediumOrchid4        = 0x7A378B
      MediumPurple         = 0x9370DB
      MediumPurple1        = 0xAB82FF
      MediumPurple2        = 0x9F79EE
      MediumPurple3        = 0x8968CD
      MediumSlateBlue      = 0x7B68EE
      MediumVioletRed      = 0xC71585
      MintCream            = 0xF5FFFA
      MistyRose            = 0xFFE4E1
      MistyRose1           = 0xFFE4E1
      MistyRose2           = 0xEED5D2
      MistyRose3           = 0xCDB7B5
      MistyRose4           = 0x8B7D7B
      Moccasin             = 0xFFE4B5
      NavajoWhite          = 0xFFDEAD
      NavajoWhite1         = 0xFFDEAD
      NavajoWhite2         = 0xEECFA1
      NavajoWhite3         = 0xCDB38B
      NavajoWhite4         = 0x8B795E
      OldLace              = 0xFDF5E6
      OliveDrab            = 0x6B8E23
      OliveDrab1           = 0xC0FF3E
      OliveDrab2           = 0xB3EE3A
      OliveDrab3           = 0x9ACD32
      OliveDrab4           = 0x698B22
      Orange               = 0xFFA500
      Orange1              = 0xFFA500
      Orange2              = 0xEE9A00
      Orange3              = 0xCD8500
      Orange4              = 0x8B5A00
      OrangeRed            = 0xFF4500
      OrangeRed1           = 0xFF4500
      OrangeRed2           = 0xEE4000
      OrangeRed3           = 0xCD3700
      OrangeRed4           = 0x8B2500
      Orchid               = 0xDA70D6
      Orchid1              = 0xFF83FA
      Orchid2              = 0xEE7AE9
      Orchid3              = 0xCD69C9
      Orchid4              = 0x8B4789
      PaleGoldenrod        = 0xEEE8AA
      PaleGreen            = 0x98FB98
      PaleGreen1           = 0x9AFF9A
      PaleGreen2           = 0x90EE90
      PaleGreen3           = 0x7CCD7C
      PaleTurquoise        = 0xAFEEEE
      PaleTurquoise1       = 0xBBFFFF
      PaleTurquoise2       = 0xAEEEEE
      PaleTurquoise3       = 0x96CDCD
      PaleTurquoise4       = 0x668B8B
      PaleVioletRed        = 0xDB7093
      PaleVioletRed1       = 0xFF82AB
      PaleVioletRed2       = 0xEE799F
      PaleVioletRed3       = 0xCD6889
      PaleVioletRed4       = 0x8B475D
      PapayaWhip           = 0xFFEFD5
      PeachPuff            = 0xFFDAB9
      PeachPuff1           = 0xFFDAB9
      PeachPuff2           = 0xEECBAD
      PeachPuff3           = 0xCDAF95
      PeachPuff4           = 0x8B7765
      Peru                 = 0xCD853F
      Pink                 = 0xFFC0CB
      Pink1                = 0xFFB5C5
      Pink2                = 0xEEA9B8
      Pink3                = 0xCD919E
      Pink4                = 0x8B636C
      Plum                 = 0xDDA0DD
      Plum1                = 0xFFBBFF
      Plum2                = 0xEEAEEE
      Plum3                = 0xCD96CD
      Plum4                = 0x8B668B
      PowderBlue           = 0xB0E0E6
      Purple               = 0xA020F0
      Purple1              = 0x9B30FF
      Purple2              = 0x912CEE
      Purple3              = 0x7D26CD
      Red                  = 0xFF0000
      Red1                 = 0xFF0000
      Red2                 = 0xEE0000
      Red3                 = 0xCD0000
      Red4                 = 0x8B0000
      RosyBrown            = 0xBC8F8F
      RosyBrown1           = 0xFFC1C1
      RosyBrown2           = 0xEEB4B4
      RosyBrown3           = 0xCD9B9B
      RosyBrown4           = 0x8B6969
      SaddleBrown          = 0x8B4513
      Salmon               = 0xFA8072
      Salmon1              = 0xFF8C69
      Salmon2              = 0xEE8262
      Salmon3              = 0xCD7054
      Salmon4              = 0x8B4C39
      SandyBrown           = 0xF4A460
      Seashell             = 0xFFF5EE
      Seashell1            = 0xFFF5EE
      Seashell2            = 0xEEE5DE
      Seashell3            = 0xCDC5BF
      Seashell4            = 0x8B8682
      Sienna               = 0xA0522D
      Sienna1              = 0xFF8247
      Sienna2              = 0xEE7942
      Sienna3              = 0xCD6839
      Sienna4              = 0x8B4726
      SkyBlue              = 0x87CEEB
      SkyBlue1             = 0x87CEFF
      SkyBlue2             = 0x7EC0EE
      SkyBlue3             = 0x6CA6CD
      SlateBlue            = 0x6A5ACD
      SlateBlue1           = 0x836FFF
      SlateBlue2           = 0x7A67EE
      SlateBlue3           = 0x6959CD
      SlateGray            = 0x708090
      SlateGray1           = 0xC6E2FF
      SlateGray2           = 0xB9D3EE
      SlateGray3           = 0x9FB6CD
      SlateGray4           = 0x6C7B8B
      SlateGrey            = 0x708090
      Snow                 = 0xFFFAFA
      Snow1                = 0xFFFAFA
      Snow2                = 0xEEE9E9
      Snow3                = 0xCDC9C9
      Snow4                = 0x8B8989
      Tan                  = 0xD2B48C
      Tan1                 = 0xFFA54F
      Tan2                 = 0xEE9A49
      Tan3                 = 0xCD853F
      Tan4                 = 0x8B5A2B
      Thistle              = 0xD8BFD8
      Thistle1             = 0xFFE1FF
      Thistle2             = 0xEED2EE
      Thistle3             = 0xCDB5CD
      Thistle4             = 0x8B7B8B
      Tomato               = 0xFF6347
      Tomato1              = 0xFF6347
      Tomato2              = 0xEE5C42
      Tomato3              = 0xCD4F39
      Tomato4              = 0x8B3626
      Violet               = 0xEE82EE
      VioletRed            = 0xD02090
      VioletRed1           = 0xFF3E96
      VioletRed2           = 0xEE3A8C
      VioletRed3           = 0xCD3278
      VioletRed4           = 0x8B2252
      Wheat                = 0xF5DEB3
      Wheat1               = 0xFFE7BA
      Wheat2               = 0xEED8AE
      Wheat3               = 0xCDBA96
      Wheat4               = 0x8B7E66
      White                = 0xFFFFFF
      WhiteSmoke           = 0xF5F5F5
      Yellow               = 0xFFFF00
      Yellow1              = 0xFFFF00
      Yellow2              = 0xEEEE00
      Yellow3              = 0xCDCD00
      Yellow4              = 0x8B8B00
      YellowGreen          = 0x9ACD32
    end

    @[Flags]
    enum Orientation
      Horizontal = 0x1
      Vertical   = 0x2
    end

    @[Flags]
    enum AlignFlag
      Left     = 0x0001
      Leading  = Left
      Right    = 0x0002
      Trailing = Right
      HCenter  = 0x0004
      # Justify         = 0x0008
      # Absolute        = 0x0010
      Horizontal_Mask = Left | Right | HCenter # | Justify | Absolute

      Top     = 0x0020
      Bottom  = 0x0040
      VCenter = 0x0080
      # Baseline = 0x0100

      Vertical_Mask = Top | Bottom | VCenter # | Baseline

      Center = VCenter | HCenter
    end

    enum CursorShape
      # No predefined shape: the cursor is drawn from its own `style` (custom
      # glyph/colors). Used by the artificial cursor; the hardware cursor ignores
      # this value.
      #
      # This is also why `CursorShape` is a plain enum, not `@[Flags]`: a flags
      # enum auto-generates `None = 0`, which would collide with `Block = 0`
      # (`Block == None`, `block?` always true). The shapes are mutually
      # exclusive, so a plain enum is correct.
      None = 0

      Block = 1
      Box   = 1

      Underline  = 2
      Underscore = 2
      HLine      = 2
      HBar       = 2

      Line  = 4
      VLine = 4
      VBar  = 4
    end

    # CSI Ps SP q
    #   Set cursor style (DECSCUSR, VT520).
    #     Ps = 0  -> blinking block.
    #     Ps = 1  -> blinking block (default).
    #     Ps = 2  -> steady block.
    #     Ps = 3  -> blinking underline.
    #     Ps = 4  -> steady underline.
    #     And 5 and 6?
    enum CursorStyle
      BlinkingBlock = 1
      BlinkingBox   = 1
      SteadyBlock   = 2
      SteadyBox     = 2

      BlinkingUnderline  = 3
      BlinkingUnderscore = 3
      BlinkingHLine      = 3
      BlinkingHBar       = 3
      SteadyUnderline    = 4
      SteadyUnderscore   = 4
      SteadyHLine        = 4
      SteadyHBar         = 4

      BlinkingLine  = 5
      BlinkingVLine = 5
      BlinkingVBar  = 5
      SteadyLine    = 6
      SteadyVLine   = 6
      SteadyVBar    = 6
    end

    # GUI mouse-pointer shapes settable via xterm's `OSC 22 ; Pt ST`
    # (see `Tput::Output#mouse_cursor_shape`). `#cursor_name` yields the
    # on-the-wire name handed to the terminal.
    #
    # Naming — where a shape exists in both Qt's `Qt::CursorShape` and the X11
    # cursor font (`X11/cursorfont.h`), the Qt name is the primary member and the
    # X11 cursor-font name is an alias (e.g. `ArrowCursor`/`LeftPtr`,
    # `PointingHandCursor`/`Hand2`, `IBeamCursor`/`Xterm`). Other cursor-font
    # glyphs use their cursorfont names; Qt-only shapes (diagonal resizes, drag,
    # open/closed hand, forbidden, busy, blank, splitters) use their Qt names.
    #
    # On-the-wire mapping (`#cursor_name`):
    #   * Members backed by a cursor-font glyph emit that glyph name.
    #   * Qt-only shapes with no cursor-font glyph emit an Xcursor theme name
    #     (e.g. `left_ptr_watch`, `dnd-move`), resolved only on terminals whose
    #     OSC 22 falls back to the Xcursor library (recent xterm).
    #
    # Best-effort and applies only while the pointer is over the terminal
    # window: xterm honors it, most other emulators (and Wayland-native
    # terminals) ignore it. OSC 22 has no custom-bitmap option, so Qt's
    # `BitmapCursor`/`CustomCursor` have no equivalent here.
    enum MouseCursorShape
      XCursor
      Arrow
      BasedArrowDown
      BasedArrowUp
      Boat
      Bogosity
      BottomLeftCorner
      BottomRightCorner
      BottomSide
      BottomTee
      BoxSpiral
      UpArrowCursor # X11 center_ptr
      CenterPtr          = UpArrowCursor
      Circle
      Clock
      CoffeeMug
      Cross
      CrossReverse
      CrossCursor # X11 crosshair
      Crosshair          = CrossCursor
      DiamondCross
      Dot
      Dotbox
      DoubleArrow
      DraftLarge
      DraftSmall
      DrapedBox
      Exchange
      SizeAllCursor # X11 fleur
      Fleur              = SizeAllCursor
      Gobbler
      Gumby
      Hand1
      PointingHandCursor # X11 hand2
      Hand2              = PointingHandCursor
      Heart
      Icon
      IronCross
      ArrowCursor # X11 left_ptr
      LeftPtr            = ArrowCursor
      LeftSide
      LeftTee
      LeftButton
      LlAngle
      LrAngle
      Man
      MiddleButton
      Mouse
      Pencil
      Pirate
      Plus
      WhatsThisCursor # X11 question_arrow
      QuestionArrow      = WhatsThisCursor
      RightPtr
      RightSide
      RightTee
      RightButton
      RtlLogo
      Sailboat
      SbDownArrow
      SizeHorCursor # X11 sb_h_double_arrow
      SbHDoubleArrow     = SizeHorCursor
      SbLeftArrow
      SbRightArrow
      SbUpArrow
      SizeVerCursor # X11 sb_v_double_arrow
      SbVDoubleArrow     = SizeVerCursor
      Shuttle
      Sizing
      Spider
      Spraycan
      Star
      Target
      Tcross
      TopLeftArrow
      TopLeftCorner
      TopRightCorner
      TopSide
      TopTee
      Trek
      UlAngle
      Umbrella
      UrAngle
      WaitCursor # X11 watch
      Watch              = WaitCursor
      IBeamCursor # X11 xterm
      Xterm              = IBeamCursor

      # Qt shapes with no X11 cursor-font glyph; `#cursor_name` emits an Xcursor
      # theme name for these. Offset to leave the cursor-font block contiguous.
      SizeBDiagCursor  = 100
      SizeFDiagCursor
      SplitVCursor
      SplitHCursor
      BlankCursor
      ForbiddenCursor
      BusyCursor
      OpenHandCursor
      ClosedHandCursor
      DragCopyCursor
      DragMoveCursor
      DragLinkCursor

      # The name OSC 22 expects on the wire for this shape.
      def cursor_name : String
        case self
        # Qt-primary members backed by a cursor-font glyph (their `to_s` is the
        # Qt name, so the cursor-font name is mapped explicitly).
        when ArrowCursor        then "left_ptr"
        when UpArrowCursor      then "center_ptr"
        when CrossCursor        then "crosshair"
        when WaitCursor         then "watch"
        when IBeamCursor        then "xterm"
        when SizeVerCursor      then "sb_v_double_arrow"
        when SizeHorCursor      then "sb_h_double_arrow"
        when SizeAllCursor      then "fleur"
        when PointingHandCursor then "hand2"
        when WhatsThisCursor    then "question_arrow"
          # Qt-only shapes -> Xcursor theme names.
        when SizeBDiagCursor  then "size_bdiag"
        when SizeFDiagCursor  then "size_fdiag"
        when SplitVCursor     then "split_v"
        when SplitHCursor     then "split_h"
        when BlankCursor      then "blank"
        when ForbiddenCursor  then "crossed_circle"
        when BusyCursor       then "left_ptr_watch"
        when OpenHandCursor   then "openhand"
        when ClosedHandCursor then "closedhand"
        when DragCopyCursor   then "copy"
        when DragMoveCursor   then "dnd-move"
        when DragLinkCursor   then "dnd-link"
          # X11 spells these irregularly.
        when XCursor      then "X_cursor"
        when LeftButton   then "leftbutton"
        when MiddleButton then "middlebutton"
        when RightButton  then "rightbutton"
          # Remaining members: the underscored member name is the cursor-font name.
        else to_s.underscore
        end
      end
    end

    class Size
      include JSON::Serializable

      property width : Int32
      property height : Int32

      def initialize(@width, @height)
      end

      # def [](arg : Int32)
      #  case arg
      #  when 0
      #    @width
      #  when 1
      #    @height
      #  else
      #    raise IndexError.new "Index out of bounds"
      #  end
      # end
      def self.[](width, height)
        new width, height
      end

      def to_s(io)
        io << "Size[" << @width << ", " << @height << ']'
      end
    end

    class Point
      include JSON::Serializable

      property x : Int32
      property y : Int32

      def initialize(@x = 0, @y = 0)
      end

      def self.[](x, y)
        new x, y
      end

      def to_s(io)
        io << "Point[" << @x << ", " << @y << ']'
      end
    end

    class Cursor
      property shape = CursorShape::Block
      property blink = false

      property _set = false
    end

    class CursorState
      property position : Point
      property? hidden : Bool

      def initialize(@position, @hidden)
      end
    end

    enum Charset
      ACS  = 0
      SCLD = 0 # DEC Special Character and Line Drawing Set.
      UK   = 1

      US    = 2
      ASCII = 2

      Dutch
      Finnish
      French
      FrenchCanadian
      German
      Italian
      NorwegianDanish
      Spanish
      Swedish
      Swiss
      Isolatin

      DECCyrillic
      DECRussian
      DECSupplemental
      DECSupplemental94
      DECTechnical
      Greek
      Greek94
      Hebrew
      Hebrew94
      Portugese
      SCS_NRCS
      Turkish
      Turkish94
    end

    enum Erase
      Below      = 0
      Above      = 1
      All        = 2
      SavedLines = 3
    end

    enum Volume
      Off  = 0
      Off2 = 1

      Low1 = 2
      Low2 = 3
      Low3 = 4

      High1 = 5
      High2 = 6
      High3 = 7
      High4 = 8
    end

    enum LineDirection
      Right = 0
      Left  = 1
      All   = 2
    end
  end
end

# class KeyCombination
#  Key_unknown
#  Modifiers
#  KeyboardModifiers
#  KeyboardModifierMask
# end
