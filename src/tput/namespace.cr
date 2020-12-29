require "json"

class Tput
  # Various simple enums and classes which don't warrant a separate file
  module Namespace
    include Crystallabs::Helpers::Logging

    enum Color
      AliceBlue = 0xF0F8FF
      AntiqueWhite = 0xFAEBD7
      AntiqueWhite1 = 0xFFEFDB
      AntiqueWhite2 = 0xEEDFCC
      AntiqueWhite3 = 0xCDC0B0
      AntiqueWhite4 = 0x8B8378
      Aquamarine = 0x7FFFD4
      Aquamarine1 = 0x7FFFD4
      Aquamarine2 = 0x76EEC6
      Aquamarine3 = 0x66CDAA
      Azure = 0xF0FFFF
      Azure1 = 0xF0FFFF
      Azure2 = 0xE0EEEE
      Azure3 = 0xC1CDCD
      Azure4 = 0x838B8B
      Beige = 0xF5F5DC
      Bisque = 0xFFE4C4
      Bisque1 = 0xFFE4C4
      Bisque2 = 0xEED5B7
      Bisque3 = 0xCDB79E
      Bisque4 = 0x8B7D6B
      BlanchedAlmond = 0xFFEBCD
      Blue = 0x0000FF
      BlueViolet = 0x8A2BE2
      Brown = 0xA52A2A
      Brown1 = 0xFF4040
      Brown2 = 0xEE3B3B
      Brown3 = 0xCD3333
      Brown4 = 0x8B2323
      Burlywood = 0xDEB887
      Burlywood1 = 0xFFD39B
      Burlywood2 = 0xEEC591
      Burlywood3 = 0xCDAA7D
      Burlywood4 = 0x8B7355
      CadetBlue1 = 0x98F5FF
      CadetBlue2 = 0x8EE5EE
      CadetBlue3 = 0x7AC5CD
      Chartreuse = 0x7FFF00
      Chartreuse1 = 0x7FFF00
      Chartreuse2 = 0x76EE00
      Chartreuse3 = 0x66CD00
      Chocolate = 0xD2691E
      Chocolate1 = 0xFF7F24
      Chocolate2 = 0xEE7621
      Chocolate3 = 0xCD661D
      Chocolate4 = 0x8B4513
      Coral = 0xFF7F50
      Coral1 = 0xFF7256
      Coral2 = 0xEE6A50
      Coral3 = 0xCD5B45
      Coral4 = 0x8B3E2F
      CornflowerBlue = 0x6495ED
      Cornsilk = 0xFFF8DC
      Cornsilk1 = 0xFFF8DC
      Cornsilk2 = 0xEEE8CD
      Cornsilk3 = 0xCDC8B1
      Cornsilk4 = 0x8B8878
      DarkBlue = 0x00008B
      DarkCyan = 0x008B8B
      DarkGoldenrod = 0xB8860B
      DarkGoldenrod1 = 0xFFB90F
      DarkGoldenrod2 = 0xEEAD0E
      DarkGoldenrod3 = 0xCD950C
      DarkGoldenrod4 = 0x8B6508
      DarkGray = 0xA9A9A9
      DarkGrey = 0xA9A9A9
      DarkKhaki = 0xBDB76B
      DarkMagenta = 0x8B008B
      DarkOliveGreen1 = 0xCAFF70
      DarkOliveGreen2 = 0xBCEE68
      DarkOliveGreen3 = 0xA2CD5A
      DarkOliveGreen4 = 0x6E8B3D
      DarkOrange = 0xFF8C00
      DarkOrange1 = 0xFF7F00
      DarkOrange2 = 0xEE7600
      DarkOrange3 = 0xCD6600
      DarkOrange4 = 0x8B4500
      DarkOrchid = 0x9932CC
      DarkOrchid1 = 0xBF3EFF
      DarkOrchid2 = 0xB23AEE
      DarkOrchid3 = 0x9A32CD
      DarkOrchid4 = 0x68228B
      DarkRed = 0x8B0000
      DarkSalmon = 0xE9967A
      DarkSeaGreen = 0x8FBC8F
      DarkSeaGreen1 = 0xC1FFC1
      DarkSeaGreen2 = 0xB4EEB4
      DarkSeaGreen3 = 0x9BCD9B
      DarkSeaGreen4 = 0x698B69
      DarkSlateGray1 = 0x97FFFF
      DarkSlateGray2 = 0x8DEEEE
      DarkSlateGray3 = 0x79CDCD
      DarkViolet = 0x9400D3
      DebianRed = 0xD70751
      DeepPink = 0xFF1493
      DeepPink1 = 0xFF1493
      DeepPink2 = 0xEE1289
      DeepPink3 = 0xCD1076
      DeepPink4 = 0x8B0A50
      DimGray = 0x696969
      DimGrey = 0x696969
      Firebrick = 0xB22222
      Firebrick1 = 0xFF3030
      Firebrick2 = 0xEE2C2C
      Firebrick3 = 0xCD2626
      Firebrick4 = 0x8B1A1A
      FloralWhite = 0xFFFAF0
      Gainsboro = 0xDCDCDC
      GhostWhite = 0xF8F8FF
      Gold = 0xFFD700
      Gold1 = 0xFFD700
      Gold2 = 0xEEC900
      Gold3 = 0xCDAD00
      Gold4 = 0x8B7500
      Goldenrod = 0xDAA520
      Goldenrod1 = 0xFFC125
      Goldenrod2 = 0xEEB422
      Goldenrod3 = 0xCD9B1D
      Goldenrod4 = 0x8B6914
      Gray = 0xBEBEBE
      Gray100 = 0xFFFFFF
      Gray40 = 0x666666
      Gray41 = 0x696969
      Gray42 = 0x6B6B6B
      Gray43 = 0x6E6E6E
      Gray44 = 0x707070
      Gray45 = 0x737373
      Gray46 = 0x757575
      Gray47 = 0x787878
      Gray48 = 0x7A7A7A
      Gray49 = 0x7D7D7D
      Gray50 = 0x7F7F7F
      Gray51 = 0x828282
      Gray52 = 0x858585
      Gray53 = 0x878787
      Gray54 = 0x8A8A8A
      Gray55 = 0x8C8C8C
      Gray56 = 0x8F8F8F
      Gray57 = 0x919191
      Gray58 = 0x949494
      Gray59 = 0x969696
      Gray60 = 0x999999
      Gray61 = 0x9C9C9C
      Gray62 = 0x9E9E9E
      Gray63 = 0xA1A1A1
      Gray64 = 0xA3A3A3
      Gray65 = 0xA6A6A6
      Gray66 = 0xA8A8A8
      Gray67 = 0xABABAB
      Gray68 = 0xADADAD
      Gray69 = 0xB0B0B0
      Gray70 = 0xB3B3B3
      Gray71 = 0xB5B5B5
      Gray72 = 0xB8B8B8
      Gray73 = 0xBABABA
      Gray74 = 0xBDBDBD
      Gray75 = 0xBFBFBF
      Gray76 = 0xC2C2C2
      Gray77 = 0xC4C4C4
      Gray78 = 0xC7C7C7
      Gray79 = 0xC9C9C9
      Gray80 = 0xCCCCCC
      Gray81 = 0xCFCFCF
      Gray82 = 0xD1D1D1
      Gray83 = 0xD4D4D4
      Gray84 = 0xD6D6D6
      Gray85 = 0xD9D9D9
      Gray86 = 0xDBDBDB
      Gray87 = 0xDEDEDE
      Gray88 = 0xE0E0E0
      Gray89 = 0xE3E3E3
      Gray90 = 0xE5E5E5
      Gray91 = 0xE8E8E8
      Gray92 = 0xEBEBEB
      Gray93 = 0xEDEDED
      Gray94 = 0xF0F0F0
      Gray95 = 0xF2F2F2
      Gray96 = 0xF5F5F5
      Gray97 = 0xF7F7F7
      Gray98 = 0xFAFAFA
      Gray99 = 0xFCFCFC
      GreenYellow = 0xADFF2F
      Grey = 0xBEBEBE
      Grey100 = 0xFFFFFF
      Grey40 = 0x666666
      Grey41 = 0x696969
      Grey42 = 0x6B6B6B
      Grey43 = 0x6E6E6E
      Grey44 = 0x707070
      Grey45 = 0x737373
      Grey46 = 0x757575
      Grey47 = 0x787878
      Grey48 = 0x7A7A7A
      Grey49 = 0x7D7D7D
      Grey50 = 0x7F7F7F
      Grey51 = 0x828282
      Grey52 = 0x858585
      Grey53 = 0x878787
      Grey54 = 0x8A8A8A
      Grey55 = 0x8C8C8C
      Grey56 = 0x8F8F8F
      Grey57 = 0x919191
      Grey58 = 0x949494
      Grey59 = 0x969696
      Grey60 = 0x999999
      Grey61 = 0x9C9C9C
      Grey62 = 0x9E9E9E
      Grey63 = 0xA1A1A1
      Grey64 = 0xA3A3A3
      Grey65 = 0xA6A6A6
      Grey66 = 0xA8A8A8
      Grey67 = 0xABABAB
      Grey68 = 0xADADAD
      Grey69 = 0xB0B0B0
      Grey70 = 0xB3B3B3
      Grey71 = 0xB5B5B5
      Grey72 = 0xB8B8B8
      Grey73 = 0xBABABA
      Grey74 = 0xBDBDBD
      Grey75 = 0xBFBFBF
      Grey76 = 0xC2C2C2
      Grey77 = 0xC4C4C4
      Grey78 = 0xC7C7C7
      Grey79 = 0xC9C9C9
      Grey80 = 0xCCCCCC
      Grey81 = 0xCFCFCF
      Grey82 = 0xD1D1D1
      Grey83 = 0xD4D4D4
      Grey84 = 0xD6D6D6
      Grey85 = 0xD9D9D9
      Grey86 = 0xDBDBDB
      Grey87 = 0xDEDEDE
      Grey88 = 0xE0E0E0
      Grey89 = 0xE3E3E3
      Grey90 = 0xE5E5E5
      Grey91 = 0xE8E8E8
      Grey92 = 0xEBEBEB
      Grey93 = 0xEDEDED
      Grey94 = 0xF0F0F0
      Grey95 = 0xF2F2F2
      Grey96 = 0xF5F5F5
      Grey97 = 0xF7F7F7
      Grey98 = 0xFAFAFA
      Grey99 = 0xFCFCFC
      Honeydew = 0xF0FFF0
      Honeydew1 = 0xF0FFF0
      Honeydew2 = 0xE0EEE0
      Honeydew3 = 0xC1CDC1
      Honeydew4 = 0x838B83
      HotPink = 0xFF69B4
      HotPink1 = 0xFF6EB4
      HotPink2 = 0xEE6AA7
      HotPink3 = 0xCD6090
      HotPink4 = 0x8B3A62
      IndianRed = 0xCD5C5C
      IndianRed1 = 0xFF6A6A
      IndianRed2 = 0xEE6363
      IndianRed3 = 0xCD5555
      IndianRed4 = 0x8B3A3A
      Ivory = 0xFFFFF0
      Ivory1 = 0xFFFFF0
      Ivory2 = 0xEEEEE0
      Ivory3 = 0xCDCDC1
      Ivory4 = 0x8B8B83
      Khaki = 0xF0E68C
      Khaki1 = 0xFFF68F
      Khaki2 = 0xEEE685
      Khaki3 = 0xCDC673
      Khaki4 = 0x8B864E
      Lavender = 0xE6E6FA
      LavenderBlush = 0xFFF0F5
      LavenderBlush1 = 0xFFF0F5
      LavenderBlush2 = 0xEEE0E5
      LavenderBlush3 = 0xCDC1C5
      LavenderBlush4 = 0x8B8386
      LawnGreen = 0x7CFC00
      LemonChiffon = 0xFFFACD
      LemonChiffon1 = 0xFFFACD
      LemonChiffon2 = 0xEEE9BF
      LemonChiffon3 = 0xCDC9A5
      LemonChiffon4 = 0x8B8970
      LightBlue = 0xADD8E6
      LightBlue1 = 0xBFEFFF
      LightBlue2 = 0xB2DFEE
      LightBlue3 = 0x9AC0CD
      LightBlue4 = 0x68838B
      LightCoral = 0xF08080
      LightCyan = 0xE0FFFF
      LightCyan1 = 0xE0FFFF
      LightCyan2 = 0xD1EEEE
      LightCyan3 = 0xB4CDCD
      LightCyan4 = 0x7A8B8B
      LightGoldenrod = 0xEEDD82
      LightGoldenrod1 = 0xFFEC8B
      LightGoldenrod2 = 0xEEDC82
      LightGoldenrod3 = 0xCDBE70
      LightGoldenrod4 = 0x8B814C
      LightGoldenrodYellow = 0xFAFAD2
      LightGray = 0xD3D3D3
      LightGreen = 0x90EE90
      LightGrey = 0xD3D3D3
      LightPink = 0xFFB6C1
      LightPink1 = 0xFFAEB9
      LightPink2 = 0xEEA2AD
      LightPink3 = 0xCD8C95
      LightPink4 = 0x8B5F65
      LightSalmon = 0xFFA07A
      LightSalmon1 = 0xFFA07A
      LightSalmon2 = 0xEE9572
      LightSalmon3 = 0xCD8162
      LightSalmon4 = 0x8B5742
      LightSkyBlue = 0x87CEFA
      LightSkyBlue1 = 0xB0E2FF
      LightSkyBlue2 = 0xA4D3EE
      LightSkyBlue3 = 0x8DB6CD
      LightSlateBlue = 0x8470FF
      LightSlateGray = 0x778899
      LightSlateGrey = 0x778899
      LightSteelBlue = 0xB0C4DE
      LightSteelBlue1 = 0xCAE1FF
      LightSteelBlue2 = 0xBCD2EE
      LightSteelBlue3 = 0xA2B5CD
      LightSteelBlue4 = 0x6E7B8B
      LightYellow = 0xFFFFE0
      LightYellow1 = 0xFFFFE0
      LightYellow2 = 0xEEEED1
      LightYellow3 = 0xCDCDB4
      LightYellow4 = 0x8B8B7A
      Linen = 0xFAF0E6
      Magenta = 0xFF00FF
      Magenta1 = 0xFF00FF
      Magenta2 = 0xEE00EE
      Magenta3 = 0xCD00CD
      Magenta4 = 0x8B008B
      Maroon = 0xB03060
      Maroon1 = 0xFF34B3
      Maroon2 = 0xEE30A7
      Maroon3 = 0xCD2990
      Maroon4 = 0x8B1C62
      MediumAquamarine = 0x66CDAA
      MediumOrchid = 0xBA55D3
      MediumOrchid1 = 0xE066FF
      MediumOrchid2 = 0xD15FEE
      MediumOrchid3 = 0xB452CD
      MediumOrchid4 = 0x7A378B
      MediumPurple = 0x9370DB
      MediumPurple1 = 0xAB82FF
      MediumPurple2 = 0x9F79EE
      MediumPurple3 = 0x8968CD
      MediumSlateBlue = 0x7B68EE
      MediumVioletRed = 0xC71585
      MintCream = 0xF5FFFA
      MistyRose = 0xFFE4E1
      MistyRose1 = 0xFFE4E1
      MistyRose2 = 0xEED5D2
      MistyRose3 = 0xCDB7B5
      MistyRose4 = 0x8B7D7B
      Moccasin = 0xFFE4B5
      NavajoWhite = 0xFFDEAD
      NavajoWhite1 = 0xFFDEAD
      NavajoWhite2 = 0xEECFA1
      NavajoWhite3 = 0xCDB38B
      NavajoWhite4 = 0x8B795E
      OldLace = 0xFDF5E6
      OliveDrab = 0x6B8E23
      OliveDrab1 = 0xC0FF3E
      OliveDrab2 = 0xB3EE3A
      OliveDrab3 = 0x9ACD32
      OliveDrab4 = 0x698B22
      Orange = 0xFFA500
      Orange1 = 0xFFA500
      Orange2 = 0xEE9A00
      Orange3 = 0xCD8500
      Orange4 = 0x8B5A00
      OrangeRed = 0xFF4500
      OrangeRed1 = 0xFF4500
      OrangeRed2 = 0xEE4000
      OrangeRed3 = 0xCD3700
      OrangeRed4 = 0x8B2500
      Orchid = 0xDA70D6
      Orchid1 = 0xFF83FA
      Orchid2 = 0xEE7AE9
      Orchid3 = 0xCD69C9
      Orchid4 = 0x8B4789
      PaleGoldenrod = 0xEEE8AA
      PaleGreen = 0x98FB98
      PaleGreen1 = 0x9AFF9A
      PaleGreen2 = 0x90EE90
      PaleGreen3 = 0x7CCD7C
      PaleTurquoise = 0xAFEEEE
      PaleTurquoise1 = 0xBBFFFF
      PaleTurquoise2 = 0xAEEEEE
      PaleTurquoise3 = 0x96CDCD
      PaleTurquoise4 = 0x668B8B
      PaleVioletRed = 0xDB7093
      PaleVioletRed1 = 0xFF82AB
      PaleVioletRed2 = 0xEE799F
      PaleVioletRed3 = 0xCD6889
      PaleVioletRed4 = 0x8B475D
      PapayaWhip = 0xFFEFD5
      PeachPuff = 0xFFDAB9
      PeachPuff1 = 0xFFDAB9
      PeachPuff2 = 0xEECBAD
      PeachPuff3 = 0xCDAF95
      PeachPuff4 = 0x8B7765
      Peru = 0xCD853F
      Pink = 0xFFC0CB
      Pink1 = 0xFFB5C5
      Pink2 = 0xEEA9B8
      Pink3 = 0xCD919E
      Pink4 = 0x8B636C
      Plum = 0xDDA0DD
      Plum1 = 0xFFBBFF
      Plum2 = 0xEEAEEE
      Plum3 = 0xCD96CD
      Plum4 = 0x8B668B
      PowderBlue = 0xB0E0E6
      Purple = 0xA020F0
      Purple1 = 0x9B30FF
      Purple2 = 0x912CEE
      Purple3 = 0x7D26CD
      Red = 0xFF0000
      Red1 = 0xFF0000
      Red2 = 0xEE0000
      Red3 = 0xCD0000
      Red4 = 0x8B0000
      RosyBrown = 0xBC8F8F
      RosyBrown1 = 0xFFC1C1
      RosyBrown2 = 0xEEB4B4
      RosyBrown3 = 0xCD9B9B
      RosyBrown4 = 0x8B6969
      SaddleBrown = 0x8B4513
      Salmon = 0xFA8072
      Salmon1 = 0xFF8C69
      Salmon2 = 0xEE8262
      Salmon3 = 0xCD7054
      Salmon4 = 0x8B4C39
      SandyBrown = 0xF4A460
      Seashell = 0xFFF5EE
      Seashell1 = 0xFFF5EE
      Seashell2 = 0xEEE5DE
      Seashell3 = 0xCDC5BF
      Seashell4 = 0x8B8682
      Sienna = 0xA0522D
      Sienna1 = 0xFF8247
      Sienna2 = 0xEE7942
      Sienna3 = 0xCD6839
      Sienna4 = 0x8B4726
      SkyBlue = 0x87CEEB
      SkyBlue1 = 0x87CEFF
      SkyBlue2 = 0x7EC0EE
      SkyBlue3 = 0x6CA6CD
      SlateBlue = 0x6A5ACD
      SlateBlue1 = 0x836FFF
      SlateBlue2 = 0x7A67EE
      SlateBlue3 = 0x6959CD
      SlateGray = 0x708090
      SlateGray1 = 0xC6E2FF
      SlateGray2 = 0xB9D3EE
      SlateGray3 = 0x9FB6CD
      SlateGray4 = 0x6C7B8B
      SlateGrey = 0x708090
      Snow = 0xFFFAFA
      Snow1 = 0xFFFAFA
      Snow2 = 0xEEE9E9
      Snow3 = 0xCDC9C9
      Snow4 = 0x8B8989
      Tan = 0xD2B48C
      Tan1 = 0xFFA54F
      Tan2 = 0xEE9A49
      Tan3 = 0xCD853F
      Tan4 = 0x8B5A2B
      Thistle = 0xD8BFD8
      Thistle1 = 0xFFE1FF
      Thistle2 = 0xEED2EE
      Thistle3 = 0xCDB5CD
      Thistle4 = 0x8B7B8B
      Tomato = 0xFF6347
      Tomato1 = 0xFF6347
      Tomato2 = 0xEE5C42
      Tomato3 = 0xCD4F39
      Tomato4 = 0x8B3626
      Violet = 0xEE82EE
      VioletRed = 0xD02090
      VioletRed1 = 0xFF3E96
      VioletRed2 = 0xEE3A8C
      VioletRed3 = 0xCD3278
      VioletRed4 = 0x8B2252
      Wheat = 0xF5DEB3
      Wheat1 = 0xFFE7BA
      Wheat2 = 0xEED8AE
      Wheat3 = 0xCDBA96
      Wheat4 = 0x8B7E66
      White = 0xFFFFFF
      WhiteSmoke = 0xF5F5F5
      Yellow = 0xFFFF00
      Yellow1 = 0xFFFF00
      Yellow2 = 0xEEEE00
      Yellow3 = 0xCDCD00
      Yellow4 = 0x8B8B00
      YellowGreen = 0x9ACD32
    end

    @[Flags]
    enum MouseButton
        NoButton         = 0x00000000
        LeftButton       = 0x00000001
        RightButton      = 0x00000002
        MiddleButton     = 0x00000004
        BackButton       = 0x00000008
        XButton1         = BackButton
        ExtraButton1     = XButton1
        ForwardButton    = 0x00000010
        XButton2         = ForwardButton
        ExtraButton2     = ForwardButton
        TaskButton       = 0x00000020
        ExtraButton3     = TaskButton
        ExtraButton4     = 0x00000040
        ExtraButton5     = 0x00000080
        ExtraButton6     = 0x00000100
        ExtraButton7     = 0x00000200
        ExtraButton8     = 0x00000400
        ExtraButton9     = 0x00000800
        ExtraButton10    = 0x00001000
        ExtraButton11    = 0x00002000
        ExtraButton12    = 0x00004000
        ExtraButton13    = 0x00008000
        ExtraButton14    = 0x00010000
        ExtraButton15    = 0x00020000
        ExtraButton16    = 0x00040000
        ExtraButton17    = 0x00080000
        ExtraButton18    = 0x00100000
        ExtraButton19    = 0x00200000
        ExtraButton20    = 0x00400000
        ExtraButton21    = 0x00800000
        ExtraButton22    = 0x01000000
        ExtraButton23    = 0x02000000
        ExtraButton24    = 0x04000000
        AllButtons       = 0x07ffffff
        MaxMouseButton   = ExtraButton24
        # 4 high-order bits remain available for future use (0x08000000 through 0x40000000).
        #MouseButtonMask  = 0xffffffff # XXX
    end

    @[Flags]
    enum Orientation
        Horizontal = 0x1
        Vertical = 0x2
    end

    enum FocusPolicy
        NoFocus = 0
        TabFocus = 0x1
        ClickFocus = 0x2
        StrongFocus = TabFocus | ClickFocus | 0x8
        WheelFocus = StrongFocus | 0x4
    end

    enum TabFocusBehavior
        NoTabFocus           = 0x00
        TabFocusTextControls = 0x01
        TabFocusListControls = 0x02
        TabFocusAllControls  = 0xff
    end

    enum SortOrder
        AscendingOrder
        DescendingOrder
    end

    @[Flags]
    enum SplitBehaviorFlags
        KeepEmptyParts = 0
        SkipEmptyParts = 0x1
    end

    enum TileRule
        StretchTile
        RepeatTile
        RoundTile
    end

    @[Flags]
    enum AlignmentFlag
        AlignLeft = 0x0001
        AlignLeading = AlignLeft
        AlignRight = 0x0002
        AlignTrailing = AlignRight
        AlignHCenter = 0x0004
        AlignJustify = 0x0008
        AlignAbsolute = 0x0010
        AlignHorizontal_Mask = AlignLeft | AlignRight | AlignHCenter | AlignJustify | AlignAbsolute

        AlignTop = 0x0020
        AlignBottom = 0x0040
        AlignVCenter = 0x0080
        AlignBaseline = 0x0100

        AlignVertical_Mask = AlignTop | AlignBottom | AlignVCenter | AlignBaseline

        AlignCenter = AlignVCenter | AlignHCenter
    end

    enum TextFlag
        TextSingleLine = 0x0100
        TextDontClip = 0x0200
        TextExpandTabs = 0x0400
        TextShowMnemonic = 0x0800
        TextWordWrap = 0x1000
        TextWrapAnywhere = 0x2000
        TextDontPrint = 0x4000
        TextIncludeTrailingSpaces = 0x08000000
        TextHideMnemonic = 0x8000
        TextJustificationForced = 0x10000
        TextForceLeftToRight = 0x20000
        TextForceRightToLeft = 0x40000
        # Ensures that the longest variant is always used when computing the
        # size of a multi-variant string.
        TextLongestVariant = 0x80000
    end

    enum TextElideMode
        ElideLeft
        ElideRight
        ElideMiddle
        ElideNone
    end

    enum WhiteSpaceMode
        WhiteSpaceNormal
        WhiteSpacePre
        WhiteSpaceNoWrap
        WhiteSpaceModeUndefined = -1
    end

    enum HitTestAccuracy
      ExactHit
      FuzzyHit
    end

    @[Flags]
    enum WindowType
        Widget = 0x00000000
        Window = 0x00000001
        Dialog = 0x00000002 | Window
        Sheet = 0x00000004 | Window
        Drawer = Sheet | Dialog
        Popup = 0x00000008 | Window
        Tool = Popup | Dialog
        ToolTip = Popup | Sheet
        SplashScreen = ToolTip | Dialog
        Desktop = 0x00000010 | Window
        SubWindow = 0x00000012
        ForeignWindow = 0x00000020 | Window
        CoverWindow = 0x00000040 | Window

        WindowType_Mask = 0x000000ff
        MSWindowsFixedSizeDialogHint = 0x00000100
        MSWindowsOwnDC = 0x00000200
        BypassWindowManagerHint = 0x00000400
        X11BypassWindowManagerHint = BypassWindowManagerHint
        FramelessWindowHint = 0x00000800
        WindowTitleHint = 0x00001000
        WindowSystemMenuHint = 0x00002000
        WindowMinimizeButtonHint = 0x00004000
        WindowMaximizeButtonHint = 0x00008000
        WindowMinMaxButtonsHint = WindowMinimizeButtonHint | WindowMaximizeButtonHint
        WindowContextHelpButtonHint = 0x00010000
        WindowShadeButtonHint = 0x00020000
        WindowStaysOnTopHint = 0x00040000
        WindowTransparentForInput = 0x00080000
        WindowOverridesSystemGestures = 0x00100000
        WindowDoesNotAcceptFocus = 0x00200000
        MaximizeUsingFullscreenGeometryHint = 0x00400000

        CustomizeWindowHint = 0x02000000
        WindowStaysOnBottomHint = 0x04000000
        WindowCloseButtonHint = 0x08000000
        MacWindowToolBarButtonHint = 0x10000000
        BypassGraphicsProxyWidget = 0x20000000
        NoDropShadowWindowHint = 0x40000000
        #WindowFullscreenButtonHint = 0x80000000 # XXX
    end

    @[Flags]
    enum WindowState
        WindowNoState    = 0x00000000
        WindowMinimized  = 0x00000001
        WindowMaximized  = 0x00000002
        WindowFullScreen = 0x00000004
        WindowActive     = 0x00000008
    end

    @[Flags]
    enum ApplicationState
        ApplicationSuspended    = 0x00000000
        ApplicationHidden       = 0x00000001
        ApplicationInactive     = 0x00000002
        ApplicationActive       = 0x00000004
    end

    @[Flags]
    enum ScreenOrientation
        PrimaryOrientation           = 0x00000000
        PortraitOrientation          = 0x00000001
        LandscapeOrientation         = 0x00000002
        InvertedPortraitOrientation  = 0x00000004
        InvertedLandscapeOrientation = 0x00000008
    end

    enum WidgetAttribute
        WA_Disabled = 0
        WA_UnderMouse = 1
        WA_MouseTracking = 2
        # Formerly, 3 was WA_ContentsPropagated.
        WA_OpaquePaintEvent = 4
        WA_StaticContents = 5
        WA_LaidOut = 7
        WA_PaintOnScreen = 8
        WA_NoSystemBackground = 9
        WA_UpdatesDisabled = 10
        WA_Mapped = 11
        # Formerly, 12 was WA_MacNoClickThrough.
        WA_InputMethodEnabled = 14
        WA_WState_Visible = 15
        WA_WState_Hidden = 16

        WA_ForceDisabled = 32
        WA_KeyCompression = 33
        WA_PendingMoveEvent = 34
        WA_PendingResizeEvent = 35
        WA_SetPalette = 36
        WA_SetFont = 37
        WA_SetCursor = 38
        WA_NoChildEventsFromChildren = 39
        WA_WindowModified = 41
        WA_Resized = 42
        WA_Moved = 43
        WA_PendingUpdate = 44
        WA_InvalidSize = 45
        # Formerly 46 was WA_MacBrushedMetal and WA_MacMetalStyle.
        WA_CustomWhatsThis = 47
        WA_LayoutOnEntireRect = 48
        WA_OutsideWSRange = 49
        WA_GrabbedShortcut = 50
        WA_TransparentForMouseEvents = 51
        WA_PaintUnclipped = 52
        WA_SetWindowIcon = 53
        WA_NoMouseReplay = 54
        WA_DeleteOnClose = 55
        WA_RightToLeft = 56
        WA_SetLayoutDirection = 57
        WA_NoChildEventsForParent = 58
        WA_ForceUpdatesDisabled = 59

        WA_WState_Created = 60
        WA_WState_CompressKeys = 61
        WA_WState_InPaintEvent = 62
        WA_WState_Reparented = 63
        WA_WState_ConfigPending = 64
        WA_WState_Polished = 66
        # Formerly, 67 was WA_WState_DND.
        WA_WState_OwnSizePolicy = 68
        WA_WState_ExplicitShowHide = 69

        WA_ShowModal = 70 # ## deprecated since since 4.5.1 but still in use :-(
        WA_MouseNoMask = 71
        WA_NoMousePropagation = 73 # for now, might go away.
        WA_Hover = 74
        WA_InputMethodTransparent = 75 # Don't reset IM when user clicks on this (for virtual keyboards on embedded)
        WA_QuitOnClose = 76

        WA_KeyboardFocusChange = 77

        WA_AcceptDrops = 78
        WA_DropSiteRegistered = 79 # internal

        WA_WindowPropagation = 80

        WA_NoX11EventCompression = 81
        WA_TintedBackground = 82
        WA_X11OpenGLOverlay = 83
        WA_AlwaysShowToolTips = 84
        WA_MacOpaqueSizeGrip = 85
        WA_SetStyle = 86

        WA_SetLocale = 87
        WA_MacShowFocusRect = 88

        WA_MacNormalSize = 89  # Mac only
        WA_MacSmallSize = 90    # Mac only
        WA_MacMiniSize = 91     # Mac only

        WA_LayoutUsesWidgetRect = 92
        WA_StyledBackground = 93 # internal
        # Formerly, 94 was WA_MSWindowsUseDirect3D.
        WA_CanHostQMdiSubWindowTitleBar = 95 # Internal

        WA_MacAlwaysShowToolWindow = 96 # Mac only

        WA_StyleSheet = 97 # internal

        WA_ShowWithoutActivating = 98

        WA_X11BypassTransientForHint = 99

        WA_NativeWindow = 100
        WA_DontCreateNativeAncestors = 101

        # Formerly WA_MacVariableSize = 102     # Mac only

        WA_DontShowOnScreen = 103

        # window types from http:#standards.freedesktop.org/wm-spec/
        WA_X11NetWmWindowTypeDesktop = 104
        WA_X11NetWmWindowTypeDock = 105
        WA_X11NetWmWindowTypeToolBar = 106
        WA_X11NetWmWindowTypeMenu = 107
        WA_X11NetWmWindowTypeUtility = 108
        WA_X11NetWmWindowTypeSplash = 109
        WA_X11NetWmWindowTypeDialog = 110
        WA_X11NetWmWindowTypeDropDownMenu = 111
        WA_X11NetWmWindowTypePopupMenu = 112
        WA_X11NetWmWindowTypeToolTip = 113
        WA_X11NetWmWindowTypeNotification = 114
        WA_X11NetWmWindowTypeCombo = 115
        WA_X11NetWmWindowTypeDND = 116
        # Formerly, 117 was WA_MacFrameworkScaled.
        WA_SetWindowModality = 118
        WA_WState_WindowOpacitySet = 119 # internal
        WA_TranslucentBackground = 120

        WA_AcceptTouchEvents = 121
        WA_WState_AcceptedTouchBeginEvent = 122
        WA_TouchPadAcceptSingleTouchEvents = 123

        WA_X11DoNotAcceptFocus = 126
        # Formerly, 127 was WA_MacNoShadow

        WA_AlwaysStackOnTop = 128

        WA_TabletTracking = 129

        WA_ContentsMarginsRespectsSafeArea = 130

        WA_StyleSheetTarget = 131

        # Add new attributes before this line
        WA_AttributeCount
    end

    enum ApplicationAttribute
   
        # AA_ImmediateWidgetCreation = 0
        # AA_MSWindowsUseDirect3DByDefault = 1
        AA_DontShowIconsInMenus = 2
        AA_NativeWindows = 3
        AA_DontCreateNativeWidgetSiblings = 4
        AA_PluginApplication = 5
        AA_DontUseNativeMenuBar = 6
        AA_MacDontSwapCtrlAndMeta = 7
        AA_Use96Dpi = 8
        AA_DisableNativeVirtualKeyboard = 9
        # AA_X11InitThreads = 10
        AA_SynthesizeTouchForUnhandledMouseEvents = 11
        AA_SynthesizeMouseForUnhandledTouchEvents = 12
        AA_ForceRasterWidgets = 14
        AA_UseDesktopOpenGL = 15
        AA_UseOpenGLES = 16
        AA_UseSoftwareOpenGL = 17
        AA_ShareOpenGLContexts = 18
        AA_SetPalette = 19
        AA_UseStyleSheetPropagationInWidgetStyles = 22
        AA_DontUseNativeDialogs = 23
        AA_SynthesizeMouseForUnhandledTabletEvents = 24
        AA_CompressHighFrequencyEvents = 25
        AA_DontCheckOpenGLContextThreadAffinity = 26
        AA_DisableShaderDiskCache = 27
        AA_DontShowShortcutsInContextMenus = 28
        AA_CompressTabletEvents = 29
        # AA_DisableWindowContextHelpButton = 30
        AA_DisableSessionManager = 31

        # Add new attributes before this line
        AA_AttributeCount
    end


    # Image conversion flags.  The unusual ordering is caused by
    # compatibility and default requirements.

    @[Flags]
    enum ImageConversionFlag
        ColorMode_Mask          = 0x00000003
        AutoColor               = 0x00000000
        ColorOnly               = 0x00000003
        MonoOnly                = 0x00000002
        # Reserved             = 0x00000001

        AlphaDither_Mask        = 0x0000000c
        ThresholdAlphaDither    = 0x00000000
        OrderedAlphaDither      = 0x00000004
        DiffuseAlphaDither      = 0x00000008
        NoAlpha                 = 0x0000000c # Not supported

        Dither_Mask             = 0x00000030
        DiffuseDither           = 0x00000000
        OrderedDither           = 0x00000010
        ThresholdDither         = 0x00000020
        # ReservedDither       = 0x00000030

        DitherMode_Mask         = 0x000000c0
        AutoDither              = 0x00000000
        PreferDither            = 0x00000040
        AvoidDither             = 0x00000080

        NoOpaqueDetection       = 0x00000100
        NoFormatConversion      = 0x00000200
    end

    enum BGMode
        TransparentMode
        OpaqueMode
    end

    enum ArrowType
        NoArrow
        UpArrow
        DownArrow
        LeftArrow
        RightArrow
    end

    enum PenStyle ; # pen style
        NoPen
        SolidLine
        DashLine
        DotLine
        DashDotLine
        DashDotDotLine
        CustomDashLine
        MPenStyle = 0x0f
    end

    enum PenCapStyle ; # line endcap style
        FlatCap = 0x00
        SquareCap = 0x10
        RoundCap = 0x20
        MPenCapStyle = 0x30
    end

    enum PenJoinStyle ; # line join style
        MiterJoin = 0x00
        BevelJoin = 0x40
        RoundJoin = 0x80
        SvgMiterJoin = 0x100
        MPenJoinStyle = 0x1c0
    end

    enum BrushStyle ; # brush style
        NoBrush
        SolidPattern
        Dense1Pattern
        Dense2Pattern
        Dense3Pattern
        Dense4Pattern
        Dense5Pattern
        Dense6Pattern
        Dense7Pattern
        HorPattern
        VerPattern
        CrossPattern
        BDiagPattern
        FDiagPattern
        DiagCrossPattern
        LinearGradientPattern
        RadialGradientPattern
        ConicalGradientPattern
        TexturePattern = 24
    end

    enum SizeMode
        AbsoluteSize
        RelativeSize
    end

    enum UIEffect
        UI_General
        UI_AnimateMenu
        UI_FadeMenu
        UI_AnimateCombo
        UI_AnimateTooltip
        UI_FadeTooltip
        UI_AnimateToolBox
    end

    enum CursorShape
      Block = 0
      Box = 0

      Underline = 2
      Underscore = 2
      HLine = 2
      HBar = 2

      Line = 4
      VLine = 4
      VBar = 4
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
      BlinkingBox = 1
      SteadyBlock = 2
      SteadyBox = 2

      BlinkingUnderline = 3
      BlinkingUnderscore = 3
      BlinkingHLine = 3
      BlinkingHBar = 3
      SteadyUnderline = 4
      SteadyUnderscore = 4
      SteadyHLine = 4
      SteadyHBar = 4

      BlinkingLine = 5
      BlinkingVLine = 5
      BlinkingVBar = 5
      SteadyLine = 6
      SteadyVLine = 6
      SteadyVBar = 6
    end

    enum MouseCursorShape
        ArrowCursor
        UpArrowCursor
        CrossCursor
        WaitCursor
        IBeamCursor
        SizeVerCursor
        SizeHorCursor
        SizeBDiagCursor
        SizeFDiagCursor
        SizeAllCursor
        BlankCursor
        SplitVCursor
        SplitHCursor
        PointingHandCursor
        ForbiddenCursor
        WhatsThisCursor
        BusyCursor
        OpenHandCursor
        ClosedHandCursor
        DragCopyCursor
        DragMoveCursor
        DragLinkCursor
        LastCursor = DragLinkCursor
        BitmapCursor = 24
        CustomCursor = 25
    end

    enum TextFormat
        PlainText
        RichText
        AutoText
        MarkdownText
    end

    enum AspectRatioMode
        IgnoreAspectRatio
        KeepAspectRatio
        KeepAspectRatioByExpanding
    end

    @[Flags]
    enum DockWidgetArea
        LeftDockWidgetArea = 0x1
        RightDockWidgetArea = 0x2
        TopDockWidgetArea = 0x4
        BottomDockWidgetArea = 0x8

        DockWidgetArea_Mask = 0xf
        AllDockWidgetAreas = DockWidgetArea_Mask
        NoDockWidgetArea = 0
    end
    enum DockWidgetAreaSizes
        NDockWidgetAreas = 4
    end

    @[Flags]
    enum ToolBarArea
        LeftToolBarArea = 0x1
        RightToolBarArea = 0x2
        TopToolBarArea = 0x4
        BottomToolBarArea = 0x8

        ToolBarArea_Mask = 0xf
        AllToolBarAreas = ToolBarArea_Mask
        NoToolBarArea = 0
    end

    enum ToolBarAreaSizes
        NToolBarAreas = 4
    end

    enum DateFormat
        TextDate       # default
        ISODate        # ISO 8601
        RFC2822Date = 8 # RFC 2822 (+ 850 and 1036 during parsing)
        ISODateWithMs
    end

    enum TimeSpec
        LocalTime
        UTC
        OffsetFromUTC
        TimeZone
    end

    enum DayOfWeek
        Monday = 1
        Tuesday = 2
        Wednesday = 3
        Thursday = 4
        Friday = 5
        Saturday = 6
        Sunday = 7
    end

    enum ScrollBarPolicy
        ScrollBarAsNeeded
        ScrollBarAlwaysOff
        ScrollBarAlwaysOn
    end

    enum CaseSensitivity
        CaseInsensitive
        CaseSensitive
    end

    enum Corner
        TopLeftCorner = 0x00000
        TopRightCorner = 0x00001
        BottomLeftCorner = 0x00002
        BottomRightCorner = 0x00003
    end

    @[Flags]
    enum Edge
        TopEdge = 0x00001
        LeftEdge = 0x00002
        RightEdge = 0x00004
        BottomEdge = 0x00008
    end

    enum ConnectionType
        AutoConnection
        DirectConnection
        QueuedConnection
        BlockingQueuedConnection
        UniqueConnection =  0x80
        SingleShotConnection = 0x100
    end

    enum ShortcutContext
        WidgetShortcut
        WindowShortcut
        ApplicationShortcut
        WidgetWithChildrenShortcut
    end

    enum FillRule
        OddEvenFill
        WindingFill
    end

    enum MaskMode
        MaskInColor
        MaskOutColor
    end

    enum ClipOperation
        NoClip
        ReplaceClip
        IntersectClip
    end

    # Shape = 0x1, BoundingRect = 0x2
    enum ItemSelectionMode
        ContainsItemShape = 0x0
        IntersectsItemShape = 0x1
        ContainsItemBoundingRect = 0x2
        IntersectsItemBoundingRect = 0x3
    end

    enum ItemSelectionOperation
        ReplaceSelection
        AddToSelection
    end

    enum TransformationMode
        FastTransformation
        SmoothTransformation
    end

    enum Axis
        XAxis
        YAxis
        ZAxis
    end

    enum FocusReason
        MouseFocusReason
        TabFocusReason
        BacktabFocusReason
        ActiveWindowFocusReason
        PopupFocusReason
        ShortcutFocusReason
        MenuBarFocusReason
        OtherFocusReason
        NoFocusReason
    end

    enum ContextMenuPolicy
        NoContextMenu
        DefaultContextMenu
        ActionsContextMenu
        CustomContextMenu
        PreventContextMenu
    end

    @[Flags]
    enum InputMethodQuery
        ImEnabled = 0x1
        ImCursorRectangle = 0x2
        ImFont = 0x4
        ImCursorPosition = 0x8
        ImSurroundingText = 0x10
        ImCurrentSelection = 0x20
        ImMaximumTextLength = 0x40
        ImAnchorPosition = 0x80
        ImHints = 0x100
        ImPreferredLanguage = 0x200

        ImAbsolutePosition = 0x400
        ImTextBeforeCursor = 0x800
        ImTextAfterCursor = 0x1000
        ImEnterKeyType = 0x2000
        ImAnchorRectangle = 0x4000
        ImInputItemClipRectangle = 0x8000

        #ImPlatformData = 0x80000000 # XXX
        ImQueryInput = ImCursorRectangle | ImCursorPosition | ImSurroundingText |
                       ImCurrentSelection | ImAnchorRectangle | ImAnchorPosition
        #ImQueryAll = 0xffffffff # XXX
    end

    @[Flags]
    enum InputMethodHint
        ImhNone = 0x0

        ImhHiddenText = 0x1
        ImhSensitiveData = 0x2
        ImhNoAutoUppercase = 0x4
        ImhPreferNumbers = 0x8
        ImhPreferUppercase = 0x10
        ImhPreferLowercase = 0x20
        ImhNoPredictiveText = 0x40

        ImhDate = 0x80
        ImhTime = 0x100

        ImhPreferLatin = 0x200

        ImhMultiLine = 0x400

        ImhNoEditMenu = 0x800
        ImhNoTextHandles = 0x1000

        ImhDigitsOnly = 0x10000
        ImhFormattedNumbersOnly = 0x20000
        ImhUppercaseOnly = 0x40000
        ImhLowercaseOnly = 0x80000
        ImhDialableCharactersOnly = 0x100000
        ImhEmailCharactersOnly = 0x200000
        ImhUrlCharactersOnly = 0x400000
        ImhLatinOnly = 0x800000

        #ImhExclusiveInputMask = 0xffff0000 # XXX
    end

    enum EnterKeyType
        EnterKeyDefault
        EnterKeyReturn
        EnterKeyDone
        EnterKeyGo
        EnterKeySend
        EnterKeySearch
        EnterKeyNext
        EnterKeyPrevious
    end

    enum ToolButtonStyle
        ToolButtonIconOnly
        ToolButtonTextOnly
        ToolButtonTextBesideIcon
        ToolButtonTextUnderIcon
        ToolButtonFollowStyle
    end

    enum LayoutDirection
        LeftToRight
        RightToLeft
        LayoutDirectionAuto
    end

    enum AnchorPoint
        AnchorLeft = 0
        AnchorHorizontalCenter
        AnchorRight
        AnchorTop
        AnchorVerticalCenter
        AnchorBottom
    end

    @[Flags]
    enum FindChildOption
        FindDirectChildrenOnly = 0x0
        FindChildrenRecursively = 0x1
    end

    @[Flags]
    enum DropAction
        CopyAction = 0x1
        MoveAction = 0x2
        LinkAction = 0x4
        ActionMask = 0xff
        TargetMoveAction = 0x8002
        IgnoreAction = 0x0
    end

    enum CheckState
        Unchecked
        PartiallyChecked
        Checked
    end

    enum ItemDataRole
        DisplayRole = 0
        DecorationRole = 1
        EditRole = 2
        ToolTipRole = 3
        StatusTipRole = 4
        WhatsThisRole = 5
        # Metadata
        FontRole = 6
        TextAlignmentRole = 7
        BackgroundRole = 8
        ForegroundRole = 9
        CheckStateRole = 10
        # Accessibility
        AccessibleTextRole = 11
        AccessibleDescriptionRole = 12
        # More general purpose
        SizeHintRole = 13
        InitialSortOrderRole = 14
        # Internal UiLib roles. Start worrying when public roles go that high.
        DisplayPropertyRole = 27
        DecorationPropertyRole = 28
        ToolTipPropertyRole = 29
        StatusTipPropertyRole = 30
        WhatsThisPropertyRole = 31
        # Reserved
        UserRole = 0x0100
    end

    @[Flags]
    enum ItemFlag
        NoItemFlags = 0
        ItemIsSelectable = 1
        ItemIsEditable = 2
        ItemIsDragEnabled = 4
        ItemIsDropEnabled = 8
        ItemIsUserCheckable = 16
        ItemIsEnabled = 32
        ItemIsAutoTristate = 64
        ItemNeverHasChildren = 128
        ItemIsUserTristate = 256
    end

    @[Flags]
    enum MatchFlag
        MatchExactly = 0
        MatchContains = 1
        MatchStartsWith = 2
        MatchEndsWith = 3
        MatchRegularExpression = 4
        MatchWildcard = 5
        MatchFixedString = 8
        MatchCaseSensitive = 16
        MatchWrap = 32
        MatchRecursive = 64
    end

    enum WindowModality
        NonModal
        WindowModal
        ApplicationModal
    end

    @[Flags]
    enum TextInteractionFlag
        NoTextInteraction         = 0
        TextSelectableByMouse     = 1
        TextSelectableByKeyboard  = 2
        LinksAccessibleByMouse    = 4
        LinksAccessibleByKeyboard = 8
        TextEditable              = 16

        TextEditorInteraction     = TextSelectableByMouse | TextSelectableByKeyboard | TextEditable
        TextBrowserInteraction    = TextSelectableByMouse | LinksAccessibleByMouse | LinksAccessibleByKeyboard
    end

    enum EventPriority
        HighEventPriority = 1
        NormalEventPriority = 0
        LowEventPriority = -1
    end

    enum SizeHint
        MinimumSize
        PreferredSize
        MaximumSize
        MinimumDescent
        NSizeHints
    end

    enum WindowFrameSection
        NoSection
        LeftSection            # For resize
        TopLeftSection
        TopSection
        TopRightSection
        RightSection
        BottomRightSection
        BottomSection
        BottomLeftSection
        TitleBarArea    # For move
    end

    enum CoordinateSystem
        DeviceCoordinates
        LogicalCoordinates
    end

    @[Flags]
    enum TouchPointState
        TouchPointUnknownState = 0x00
        TouchPointPressed    = 0x01
        TouchPointMoved      = 0x02
        TouchPointStationary = 0x04
        TouchPointReleased   = 0x08
    end

    enum GestureState
   
        NoGesture
        GestureStarted  = 1
        GestureUpdated  = 2
        GestureFinished = 3
        GestureCanceled = 4
    end

    enum GestureType
   
        TapGesture        = 1
        TapAndHoldGesture = 2
        PanGesture        = 3
        PinchGesture      = 4
        SwipeGesture      = 5

        CustomGesture     = 0x0100

        LastGestureType   = ~0u32 # added 32
    end

    @[Flags]
    enum GestureFlag
   
        DontStartGestureOnChildren = 0x01
        ReceivePartialGestures     = 0x02
        IgnoredGesturesPropagateToParent = 0x04
    end

    enum NativeGestureType
   
        BeginNativeGesture
        EndNativeGesture
        PanNativeGesture
        ZoomNativeGesture
        SmartZoomNativeGesture
        RotateNativeGesture
        SwipeNativeGesture
    end

    enum NavigationMode
   
        NavigationModeNone
        NavigationModeKeypadTabOrder
        NavigationModeKeypadDirectional
        NavigationModeCursorAuto
        NavigationModeCursorForceVisible
    end

    enum CursorMoveStyle
        LogicalMoveStyle
        VisualMoveStyle
    end

    enum TimerType
        PreciseTimer
        CoarseTimer
        VeryCoarseTimer
    end

    enum ScrollPhase
        NoScrollPhase = 0
        ScrollBegin
        ScrollUpdate
        ScrollEnd
        ScrollMomentum
    end

    enum MouseEventSource
        MouseEventNotSynthesized
        MouseEventSynthesizedBySystem
        MouseEventSynthesizedByTput # product name
        MouseEventSynthesizedByApplication
    end

    @[Flags]
    enum MouseEventFlag
        NoMouseEventFlag = 0x00
        MouseEventCreatedDoubleClick = 0x01
        MouseEventFlagMask = 0xFF
    end

    enum ChecksumType
        ChecksumIso3309
        ChecksumItuV41
    end

    enum HighDpiScaleFactorRoundingPolicy
        Unset
        Round
        Ceil
        Floor
        RoundPreferFloor
        PassThrough
    end


    enum PaintDeviceFlags
        UnknownDevice = 0x00
        Widget        = 0x01
        Pixmap        = 0x02
        Image         = 0x03
        Printer       = 0x04
        Picture       = 0x05
        Pbuffer       = 0x06     # GL pbuffer
        FramebufferObject = 0x07 # GL framebuffer object
        CustomRaster  = 0x08
        PaintBuffer   = 0x0a
        OpenGL        = 0x0b
    end
    enum RelayoutType
        RelayoutNormal
        RelayoutDragging
        RelayoutDropped
    end

    enum DockPosition
        LeftDock
        RightDock
        TopDock
        BottomDock
        DockCount
    end

    enum Callback
        EventNotifyCallback
        LastCallback
    end

    class Size
      property width : Int32
      property height : Int32
      def initialize(@width, @height)
      end
      #def [](arg : Int32)
      #  case arg
      #  when 0
      #    @width
      #  when 1
      #    @height
      #  else
      #    raise IndexError.new "Index out of bounds"
      #  end
      #end
      def self.[](width, height)
        new width, height
      end
      def inspect(io)
        io << "Size[" << @width << ", " << @height << ']'
      end
    end

    class Point
      property x : Int32
      property y : Int32
      def initialize(@x=0, @y=0)
      end
      def self.[](x, y)
        new x, y
      end
      def inspect(io)
        io << "Point[" << @x << ", " << @y << ']'
      end
    end

    class Rect
      property x : Int32
      property y : Int32
      property width : Int32
      property height : Int32
      def initialize(@x, @y, @width, @height)
      end
      def initialize(top_left : Point, size : Size)
        @x, @y = top_left.x, top_left.y
        @width, @height = size.width, size.height
      end
      def initialize(top_left : Point, bottom_right : Point)
        @x, @y = top_left.x, top_left.y
        @width, @height = bottom_right.x-top_left.x, bottom_right.y-top_left.y
      end
    end

    class Line
      property x1 : Int32
      property x2 : Int32
      property y1 : Int32
      property y2 : Int32
      def initialize(@x1, @y1, @x2, @y2)
      end
    end

    class Margins
      property left : Int32
      property top : Int32
      property right : Int32
      property bottom : Int32
      def initialize(@left=0, @top=0, @right=0, @bottom=0)
      end
    end

    class Padding
      property left : Int32
      property top : Int32
      property right : Int32
      property bottom : Int32
      def initialize(@left=0, @top=0, @right=0, @bottom=0)
      end
    end

    class Position # XXX better name?
      property left : Int32
      property top : Int32
      property right : Int32
      property bottom : Int32
      def initialize(@left=0, @top=0, @right=0, @bottom=0)
      end
      def width
        raise "Not iplimented"
      end
      def height
        raise "Not iplimented"
      end
    end

    class Cursor
      property artificial : Bool = false
      property shape = CursorShape::Block
      property blink = false
      property color : Color? = nil

      property _set = false
      property _state = 1
      property _hidden = true
    end

    class CursorState
      property position : Point
      property? hidden : Bool
      def initialize(@position, @hidden)
      end
    end

    enum Charset
      ACS = 0
      SCLD = 0 # DEC Special Character and Line Drawing Set.
      UK = 1

      US = 2
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
    end

    enum Erase
      Below = 0
      Above = 1
      All = 2
      SavedLines = 3
    end
  end
end

#class KeyCombination
#  Key_unknown
#  Modifiers
#  KeyboardModifiers
#  KeyboardModifierMask
#end
