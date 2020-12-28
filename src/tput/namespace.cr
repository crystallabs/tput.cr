require "json"

class Tput
  # Various simple enums and classes which don't warrant a separate file
  module Namespace

    enum GlobalColor
        Color0
        Color1
        Black
        White
        DarkGray
        Gray
        LightGray
        Red
        Green
        Blue
        Cyan
        Magenta
        Yellow
        DarkRed
        DarkGreen
        DarkBlue
        DarkCyan
        DarkMagenta
        DarkYellow
        Transparent
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
      Block
      Underline
      Line
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

    struct Size
      include JSON::Serializable
      property width : Int32
      property height : Int32
      def initialize(@width, @height)
      end
    end

    struct Point
      include JSON::Serializable
      property x : Int32
      property y : Int32
      property? zero_based : Bool
      def initialize(@x=0, @y=0, @zero_based=true)
      end
    end

    struct Rect
      include JSON::Serializable
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

    struct Line
      include JSON::Serializable
      property x1 : Int32
      property x2 : Int32
      property y1 : Int32
      property y2 : Int32
      def initialize(@x1, @y1, @x2, @y2)
      end
    end

    struct Margins
      include JSON::Serializable
      property left : Int32
      property top : Int32
      property right : Int32
      property bottom : Int32
      def initialize(@left=0, @top=0, @right=0, @bottom=0)
      end
    end

    struct Padding
      include JSON::Serializable
      property left : Int32
      property top : Int32
      property right : Int32
      property bottom : Int32
      def initialize(@left=0, @top=0, @right=0, @bottom=0)
      end
    end

    struct Position # XXX better name?
      include JSON::Serializable
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

    struct TextCursor
      property artificial : Bool = false
      property shape = CursorShape::Block
      property blink = false
      property color : GlobalColor? = GlobalColor::Red #nil

      property _set = false
      property _state = 1
      property _hidden = true
    end

  end
end

#class KeyCombination
#  Key_unknown
#  Modifiers
#  KeyboardModifiers
#  KeyboardModifierMask
#end
