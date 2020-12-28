class Tput

  # Listing of recognized keys with key names.
  enum Keys
    Key_CtrlA = 1
    Key_CtrlB = 2
    Key_CtrlC = 3
    Key_CtrlD = 4
    Key_CtrlE = 5
    Key_CtrlF = 6
    Key_CtrlG = 7
    Key_CtrlH = 8

    Key_Tab = 9
    Key_CtrlI = 9

    Key_ShiftTab = 10
    Key_CtrlJ = 10

    Key_CtrlK = 11
    Key_CtrlL = 12

    Key_Return = 13
    Key_CtrlM = 13

    Key_AltReturn = 14
    Key_CtrlN = 14

    Key_CtrlO = 15
    Key_CtrlP = 16
    Key_CtrlQ = 17
    Key_CtrlR = 18
    Key_CtrlS = 19
    Key_CtrlT = 20
    Key_CtrlU = 21
    Key_CtrlV = 22
    Key_CtrlW = 23
    Key_CtrlX = 24
    Key_CtrlY = 25
    Key_CtrlZ = 26

    Key_Escape = 27

    # Unicode Basic Latin block (
    Key_Space = 32
    Key_Any = Key_Space
    Key_Exclam = 33
    Key_QuoteDbl = 34
    Key_NumberSign = 35
    Key_Dollar = 36
    Key_Percent = 37
    Key_Ampersand = 38
    Key_Apostrophe = 39
    Key_ParenLeft = 40
    Key_ParenRight = 41
    Key_Asterisk = 42
    Key_Plus = 43
    Key_Comma = 44
    Key_Minus = 45
    Key_Period = 46
    Key_Slash = 47
    Key_0 = 48
    Key_1 = 49
    Key_2 = 50
    Key_3 = 51
    Key_4 = 52
    Key_5 = 53
    Key_6 = 54
    Key_7 = 55
    Key_8 = 56
    Key_9 = 57
    Key_Colon = 58
    Key_Semicolon = 59
    Key_Less = 60
    Key_Equal = 61
    Key_Greater = 62
    Key_Question = 63
    Key_At = 64
    Key_A = 65
    Key_B = 66
    Key_C = 67
    Key_D = 68
    Key_E = 69
    Key_F = 70
    Key_G = 71
    Key_H = 72
    Key_I = 73
    Key_J = 74
    Key_K = 75
    Key_L = 76
    Key_M = 77
    Key_N = 78
    Key_O = 79
    Key_P = 80
    Key_Q = 81
    Key_R = 82
    Key_S = 83
    Key_T = 84
    Key_U = 85
    Key_V = 86
    Key_W = 87
    Key_X = 88
    Key_Y = 89
    Key_Z = 90
    Key_BracketLeft = 91
    Key_Backslash = 92
    Key_BracketRight = 93
    Key_AsciiCircum = 94
    Key_Underscore = 95
    Key_QuoteLeft = 96

    Key_a = 97
    Key_b = 98
    Key_c = 99
    Key_d = 100
    Key_e = 101
    Key_f = 102
    Key_g = 103
    Key_h = 104
    Key_i = 105
    Key_j = 106
    Key_k = 107
    Key_l = 108
    Key_m = 109
    Key_n = 110
    Key_o = 111
    Key_p = 112
    Key_q = 113
    Key_r = 114
    Key_s = 115
    Key_t = 116
    Key_u = 117
    Key_v = 118
    Key_w = 119
    Key_x = 120
    Key_y = 121
    Key_z = 122

    Key_BraceLeft = 123
    Key_Bar = 124
    Key_BraceRight = 125
    Key_AsciiTilde = 126

    Key_Backspace = 127

    # Unicode Latin-1 Supplement block (
    Key_nobreakspace = 160
    Key_exclamdown = 161
    Key_cent = 162
    Key_sterling = 163
    Key_currency = 164
    Key_yen = 165
    Key_brokenbar = 166
    Key_section = 167
    Key_diaeresis = 168
    Key_copyright = 169
    Key_ordfeminine = 170
    Key_guillemotleft = 171         # left angle quotation mark
    Key_notsign = 172
    Key_hyphen = 173
    Key_registered = 174
    Key_macron = 175
    Key_degree = 176
    Key_plusminus = 177
    Key_twosuperior = 178
    Key_threesuperior = 179
    Key_acute = 180
    Key_mu = 181
    Key_paragraph = 182
    Key_periodcentered = 183
    Key_cedilla = 184
    Key_onesuperior = 185
    Key_masculine = 186
    Key_guillemotright = 187         # right angle quotation mark
    Key_onequarter = 188
    Key_onehalf = 189
    Key_threequarters = 190
    Key_questiondown = 191
    Key_Agrave = 192
    Key_Aacute = 193
    Key_Acircumflex = 194
    Key_Atilde = 195
    Key_Adiaeresis = 196
    Key_Aring = 197
    Key_AE = 198
    Key_Ccedilla = 199
    Key_Egrave = 200
    Key_Eacute = 201
    Key_Ecircumflex = 202
    Key_Ediaeresis = 203
    Key_Igrave = 204
    Key_Iacute = 205
    Key_Icircumflex = 206
    Key_Idiaeresis = 207
    Key_ETH = 208
    Key_Ntilde = 209
    Key_Ograve = 210
    Key_Oacute = 211
    Key_Ocircumflex = 212
    Key_Otilde = 213
    Key_Odiaeresis = 214
    Key_multiply = 215
    Key_Ooblique = 216
    Key_Ugrave = 217
    Key_Uacute = 218
    Key_Ucircumflex = 219
    Key_Udiaeresis = 220
    Key_Yacute = 221
    Key_THORN = 222
    Key_ssharp = 223
    Key_division = 247
    Key_ydiaeresis = 255

    # The rest of the Unicode values are skipped here
    # so that we can represent them along with Keys
    # in the same data type. The maximum Unicode value
    # is 1114111 so we start our custom keys at
    # higher values to not clash with the Unicode values
    # but still give plenty of room to grow.
    #
    # Note: Do not depend on the numerical values in client programs.

    Key_ShiftUp = 16777000
    Key_ShiftDown
    Key_ShiftLeft
    Key_ShiftRight
    Key_CtrlUp
    Key_CtrlDown
    Key_CtrlLeft
    Key_CtrlRight
    Key_AltUp
    Key_AltDown
    Key_AltLeft
    Key_AltRight

    Key_AltA # = 27 97
    Key_AltB # = 27 98
    Key_AltC #      ...
    Key_AltD
    Key_AltE
    Key_AltF
    Key_AltG
    Key_AltH
    Key_AltI
    Key_AltJ
    Key_AltK
    Key_AltL
    Key_AltM
    Key_AltN
    Key_AltO
    Key_AltP
    Key_AltQ
    Key_AltR
    Key_AltS
    Key_AltT
    Key_AltU
    Key_AltV
    Key_AltW
    Key_AltX
    Key_AltY
    Key_AltZ

    #Key_Escape = 16777216                 # misc keys
    #Key_Tab = 16777217
    Key_Backtab = 16777218
    #Key_Backspace = 16777219
    #Key_Return = 16777220
    Key_Enter = 16777221
    Key_Insert = 16777222
    Key_Delete = 16777223
    Key_Pause = 16777224
    Key_Print = 16777225                # print screen
    Key_SysReq = 16777226
    Key_Clear = 16777227
    Key_Home = 16777232                 # cursor movement
    Key_End = 16777233
    Key_Left = 16777234
    Key_Up = 16777235
    Key_Right = 16777236
    Key_Down = 16777237
    Key_PageUp = 16777238
    Key_PageDown = 16777239
    Key_Shift = 16777248                 # modifiers
    Key_Control = 16777249
    Key_Meta = 16777250
    Key_Alt = 16777251
    Key_CapsLock = 16777252
    Key_NumLock = 16777253
    Key_ScrollLock = 16777254
    Key_F1 = 16777264                 # function keys
    Key_F2 = 16777265
    Key_F3 = 16777266
    Key_F4 = 16777267
    Key_F5 = 16777268
    Key_F6 = 16777269
    Key_F7 = 16777270
    Key_F8 = 16777271
    Key_F9 = 16777272
    Key_F10 = 16777273
    Key_F11 = 16777274
    Key_F12 = 16777275
    Key_F13 = 16777276
    Key_F14 = 16777277
    Key_F15 = 16777278
    Key_F16 = 16777279
    Key_F17 = 16777280
    Key_F18 = 16777281
    Key_F19 = 16777282
    Key_F20 = 16777283
    Key_F21 = 16777284
    Key_F22 = 16777285
    Key_F23 = 16777286
    Key_F24 = 16777287
    Key_F25 = 16777288                 # F25 .. F35 only on X11
    Key_F26 = 16777289
    Key_F27 = 16777290
    Key_F28 = 16777291
    Key_F29 = 16777292
    Key_F30 = 16777293
    Key_F31 = 16777294
    Key_F32 = 16777295
    Key_F33 = 16777296
    Key_F34 = 16777297
    Key_F35 = 16777298
    Key_Super_L = 16777299                  # extra keys
    Key_Super_R = 16777300
    Key_Menu = 16777301
    Key_Hyper_L = 16777302
    Key_Hyper_R = 16777303
    Key_Help = 16777304
    Key_Direction_L = 16777305
    Key_Direction_R = 16777312

    # International input method support (X keycode - 
    # Only interesting if you are writing your own input method

    # International & multi-key character composition
    Key_AltGr               = 16781571
    Key_Multi_key           = 16781600  # Multi-key character compose
    Key_Codeinput           = 16781623
    Key_SingleCandidate     = 16781628
    Key_MultipleCandidate   = 16781629
    Key_PreviousCandidate   = 16781630

    # Misc Functions
    Key_Mode_switch         = 16781694  # Character set switch
    #Key_script_switch       = 16781694  # Alias for mode_switch

    # Japanese keyboard support
    Key_Kanji               = 16781601  # Kanji, Kanji convert
    Key_Muhenkan            = 16781602  # Cancel Conversion
    #Key_Henkan_Mode         = 16781603  # Start/Stop Conversion
    Key_Henkan              = 16781603  # Alias for Henkan_Mode
    Key_Romaji              = 16781604  # to Romaji
    Key_Hiragana            = 16781605  # to Hiragana
    Key_Katakana            = 16781606  # to Katakana
    Key_Hiragana_Katakana   = 16781607  # Hiragana/Katakana toggle
    Key_Zenkaku             = 16781608  # to Zenkaku
    Key_Hankaku             = 16781609  # to Hankaku
    Key_Zenkaku_Hankaku     = 16781610  # Zenkaku/Hankaku toggle
    Key_Touroku             = 16781611  # Add to Dictionary
    Key_Massyo              = 16781612  # Delete from Dictionary
    Key_Kana_Lock           = 16781613  # Kana Lock
    Key_Kana_Shift          = 16781614  # Kana Shift
    Key_Eisu_Shift          = 16781615  # Alphanumeric Shift
    Key_Eisu_toggle         = 16781616  # Alphanumeric toggle
    #Key_Kanji_Bangou        = 16781623  # Codeinput
    #Key_Zen_Koho            = 16781629  # Multiple/All Candidate(s)
    #Key_Mae_Koho            = 16781630  # Previous Candidate

    # Korean keyboard support
    #
    # In fact, many Korean users need only 2 keys, Key_Hangul and
    # Key_Hangul_Hanja. But rest of the keys are good for future.

    Key_Hangul              = 16781617  # Hangul start/stop(toggle)
    Key_Hangul_Start        = 16781618  # Hangul start
    Key_Hangul_End          = 16781619  # Hangul end, English start
    Key_Hangul_Hanja        = 16781620  # Start Hangul->Hanja Conversion
    Key_Hangul_Jamo         = 16781621  # Hangul Jamo mode
    Key_Hangul_Romaja       = 16781622  # Hangul Romaja mode
    #Key_Hangul_Codeinput    = 16781623  # Hangul code input mode
    Key_Hangul_Jeonja       = 16781624  # Jeonja mode
    Key_Hangul_Banja        = 16781625  # Banja mode
    Key_Hangul_PreHanja     = 16781626  # Pre Hanja conversion
    Key_Hangul_PostHanja    = 16781627  # Post Hanja conversion
    #Key_Hangul_SingleCandidate   = 16781628  # Single candidate
    #Key_Hangul_MultipleCandidate = 16781629  # Multiple candidate
    #Key_Hangul_PreviousCandidate = 16781630  # Previous candidate
    Key_Hangul_Special      = 16781631  # Special symbols
    #Key_Hangul_switch       = 16781694  # Alias for mode_switch

    # dead keys (X keycode - 60672 to avoid the conflict)
    Key_Dead_Grave          = 16781904
    Key_Dead_Acute          = 16781905
    Key_Dead_Circumflex     = 16781906
    Key_Dead_Tilde          = 16781907
    Key_Dead_Macron         = 16781908
    Key_Dead_Breve          = 16781909
    Key_Dead_Abovedot       = 16781910
    Key_Dead_Diaeresis      = 16781911
    Key_Dead_Abovering      = 16781912
    Key_Dead_Doubleacute    = 16781913
    Key_Dead_Caron          = 16781914
    Key_Dead_Cedilla        = 16781915
    Key_Dead_Ogonek         = 16781916
    Key_Dead_Iota           = 16781917
    Key_Dead_Voiced_Sound   = 16781918
    Key_Dead_Semivoiced_Sound = 16781919
    Key_Dead_Belowdot       = 16781920
    Key_Dead_Hook           = 16781921
    Key_Dead_Horn           = 16781922
    Key_Dead_Stroke         = 16781923
    Key_Dead_Abovecomma     = 16781924
    Key_Dead_Abovereversedcomma = 16781925
    Key_Dead_Doublegrave    = 16781926
    Key_Dead_Belowring      = 16781927
    Key_Dead_Belowmacron    = 16781928
    Key_Dead_Belowcircumflex = 16781929
    Key_Dead_Belowtilde     = 16781930
    Key_Dead_Belowbreve     = 16781931
    Key_Dead_Belowdiaeresis = 16781932
    Key_Dead_Invertedbreve  = 16781933
    Key_Dead_Belowcomma     = 16781934
    Key_Dead_Currency       = 16781935
    Key_Dead_a              = 16781952
    Key_Dead_A              = 16781953
    Key_Dead_e              = 16781954
    Key_Dead_E              = 16781955
    Key_Dead_i              = 16781956
    Key_Dead_I              = 16781957
    Key_Dead_o              = 16781958
    Key_Dead_O              = 16781959
    Key_Dead_u              = 16781960
    Key_Dead_U              = 16781961
    Key_Dead_Small_Schwa    = 16781962
    Key_Dead_Capital_Schwa  = 16781963
    Key_Dead_Greek          = 16781964
    Key_Dead_Lowline        = 16781968
    Key_Dead_Aboveverticalline = 16781969
    Key_Dead_Belowverticalline = 16781970
    Key_Dead_Longsolidusoverlay = 16781971

    # multimedia/internet keys - ignored by default
    Key_Back  = 16777313
    Key_Forward  = 16777314
    Key_Stop  = 16777315
    Key_Refresh  = 16777316
    Key_VolumeDown = 16777328
    Key_VolumeMute  = 16777329
    Key_VolumeUp = 16777330
    Key_BassBoost = 16777331
    Key_BassUp = 16777332
    Key_BassDown = 16777333
    Key_TrebleUp = 16777334
    Key_TrebleDown = 16777335
    Key_MediaPlay  = 16777344
    Key_MediaStop  = 16777345
    Key_MediaPrevious  = 16777346
    Key_MediaNext  = 16777347
    Key_MediaRecord = 16777348
    Key_MediaPause = 16777349
    Key_MediaTogglePlayPause = 16777350
    Key_HomePage  = 16777360
    Key_Favorites  = 16777361
    Key_Search  = 16777362
    Key_Standby = 16777363
    Key_OpenUrl = 16777364
    Key_LaunchMail  = 16777376
    Key_LaunchMedia = 16777377
    Key_Launch0  = 16777378
    Key_Launch1  = 16777379
    Key_Launch2  = 16777380
    Key_Launch3  = 16777381
    Key_Launch4  = 16777382
    Key_Launch5  = 16777383
    Key_Launch6  = 16777384
    Key_Launch7  = 16777385
    Key_Launch8  = 16777386
    Key_Launch9  = 16777387
    Key_LaunchA  = 16777388
    Key_LaunchB  = 16777389
    Key_LaunchC  = 16777390
    Key_LaunchD  = 16777391
    Key_LaunchE  = 16777392
    Key_LaunchF  = 16777393
    Key_MonBrightnessUp = 16777394
    Key_MonBrightnessDown = 16777395
    Key_KeyboardLightOnOff = 16777396
    Key_KeyboardBrightnessUp = 16777397
    Key_KeyboardBrightnessDown = 16777398
    Key_PowerOff = 16777399
    Key_WakeUp = 16777400
    Key_Eject = 16777401
    Key_ScreenSaver = 16777402
    Key_WWW = 16777403
    Key_Memo = 16777404
    Key_LightBulb = 16777405
    Key_Shop = 16777406
    Key_History = 16777407
    Key_AddFavorite = 16777408
    Key_HotLinks = 16777409
    Key_BrightnessAdjust = 16777410
    Key_Finance = 16777411
    Key_Community = 16777412
    Key_AudioRewind = 16777413 # Media rewind
    Key_BackForward = 16777414
    Key_ApplicationLeft = 16777415
    Key_ApplicationRight = 16777416
    Key_Book = 16777417
    Key_CD = 16777418
    Key_Calculator = 16777419
    Key_ToDoList = 16777420
    Key_ClearGrab = 16777421
    Key_Close = 16777422
    Key_Copy = 16777423
    Key_Cut = 16777424
    Key_Display = 16777425 # Output switch key
    Key_DOS = 16777426
    Key_Documents = 16777427
    Key_Excel = 16777428
    Key_Explorer = 16777429
    Key_Game = 16777430
    Key_Go = 16777431
    Key_iTouch = 16777432
    Key_LogOff = 16777433
    Key_Market = 16777434
    Key_Meeting = 16777435
    Key_MenuKB = 16777436
    Key_MenuPB = 16777437
    Key_MySites = 16777438
    Key_News = 16777439
    Key_OfficeHome = 16777440
    Key_Option = 16777441
    Key_Paste = 16777442
    Key_Phone = 16777443
    Key_Calendar = 16777444
    Key_Reply = 16777445
    Key_Reload = 16777446
    Key_RotateWindows = 16777447
    Key_RotationPB = 16777448
    Key_RotationKB = 16777449
    Key_Save = 16777450
    Key_Send = 16777451
    Key_Spell = 16777452
    Key_SplitScreen = 16777453
    Key_Support = 16777454
    Key_TaskPane = 16777455
    Key_Terminal = 16777456
    Key_Tools = 16777457
    Key_Travel = 16777458
    Key_Video = 16777459
    Key_Word = 16777460
    Key_Xfer = 16777461
    Key_ZoomIn = 16777462
    Key_ZoomOut = 16777463
    Key_Away = 16777464
    Key_Messenger = 16777465
    Key_WebCam = 16777466
    Key_MailForward = 16777467
    Key_Pictures = 16777468
    Key_Music = 16777469
    Key_Battery = 16777470
    Key_Bluetooth = 16777471
    Key_WLAN = 16777472
    Key_UWB = 16777473
    Key_AudioForward = 16777474 # Media fast-forward
    Key_AudioRepeat = 16777475 # Toggle repeat mode
    Key_AudioRandomPlay = 16777476 # Toggle shuffle mode
    Key_Subtitle = 16777477
    Key_AudioCycleTrack = 16777478
    Key_Time = 16777479
    Key_Hibernate = 16777480
    Key_View = 16777481
    Key_TopMenu = 16777482
    Key_PowerDown = 16777483
    Key_Suspend = 16777484
    Key_ContrastAdjust = 16777485

    Key_LaunchG  = 16777486
    Key_LaunchH  = 16777487

    Key_TouchpadToggle = 16777488
    Key_TouchpadOn = 16777489
    Key_TouchpadOff = 16777490

    Key_MicMute = 16777491

    Key_Red = 16777492
    Key_Green = 16777493
    Key_Yellow = 16777494
    Key_Blue = 16777495

    Key_ChannelUp = 16777496
    Key_ChannelDown = 16777497

    Key_Guide    = 16777498
    Key_Info     = 16777499
    Key_Settings = 16777500

    Key_MicVolumeUp   = 16777501
    Key_MicVolumeDown = 16777502

    Key_New      = 16777504
    Key_Open     = 16777505
    Key_Find     = 16777506
    Key_Undo     = 16777507
    Key_Redo     = 16777508

    Key_MediaLast = 16842751

    # Keypad navigation keys
    Key_Select = 16842752
    Key_Yes = 16842753
    Key_No = 16842754

    # Newer misc keys
    Key_Cancel  = 16908289
    Key_Printer = 16908290
    Key_Execute = 16908291
    Key_Sleep   = 16908292
    Key_Play    = 16908293 # Not the same as Key_MediaPlay
    Key_Zoom    = 16908294
    #Key_Jisho   = 16908295 # IME: Dictionary key
    #Key_Oyayubi_Left = 16908296 # IME: Left Oyayubi key
    #Key_Oyayubi_Right = 16908297 # IME: Right Oyayubi key
    Key_Exit    = 16908298

    # Device keys
    Key_Context1 = 17825792
    Key_Context2 = 17825793
    Key_Context3 = 17825794
    Key_Context4 = 17825795
    Key_Call = 17825796       # set absolute state to in a call (do not toggle state)
    Key_Hangup = 17825797     # set absolute state to hang up (do not toggle state)
    Key_Flip = 17825798
    Key_ToggleCallHangup = 17825799 # a toggle key for answering, or hanging up, based on current call state
    Key_VoiceDial = 17825800
    Key_LastNumberRedial = 17825801

    Key_Camera = 17825824
    Key_CameraFocus = 17825825

    # WARNING: Do not add any keys in the range 18874368 to 0xffffffff
    # as those bits are reserved for the KeyboardModifier enum below.

    Key_unknown = 33554431
  end

  @[Flags]
  enum KeyModifier
    NoModifier           = 0x00000000
    ShiftModifier        = 0x02000000
    ControlModifier      = 0x04000000
    AltModifier          = 0x08000000
    MetaModifier         = 0x10000000
    KeypadModifier       = 0x20000000
    GroupSwitchModifier  = 0x40000000
    # Do not extend the mask to include 0x01000000
    #KeyboardModifierMask = 0xfe000000 # XXX

    NONE          = NoModifier
    META          = MetaModifier
    SHIFT         = ShiftModifier
    CTRL          = ControlModifier
    ALT           = AltModifier
    #MODIFIER_MASK = KeyboardModifierMask # XXX ^
  end

  record Key,
    key : Keys,
    modifier : KeyModifier = KeyModifier::NONE,
    sequence : Bytes? = nil
end
