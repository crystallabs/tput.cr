class Tput
  module Events
    include EventHandler

    #event EventEvent#, ...

    event LogEvent, message : String
    event WarningEvent, message : String
    event ErrorEvent, message : String
    event ExitEvent, code : Int32

    event SubmitEvent#, ...value...
    event CancelEvent#, ...value...
    event ResetEvent#, ...value...
    event CompleteEvent
    event ResetEvent

    event DataEvent#, data : ...

    event ResizeEvent
    event DestroyEvent
    event HideEvent
    event ShowEvent
    event AttachEvent
    event DetachEvent

    event SetContentEvent
    event ParseContentEvent
    #event MoveEvent # But this one without args
    event CancelEvent
    event FocusEvent
    event BlurEvent

    #event ActionEvent, item : Item, selected : Bool # waiting Item
    #event SelectEvent, item : Item, selected : Bool # waiting Item
    #event SelectItemEvent, item : Item, selected : Bool # waiting Item
    #event SelectTabEvent, item : Item, index : Int32

    event CreateItemEvent
    event AddItemEvent
    event RemoveItemEvent
    event InsertItemEvent
    event SetItemsEvent

    event PreRenderEvent
    event RenderEvent#, ... coords ...
    event PreDrawEvent
    event DrawEvent#, ... coords ...
    event RefreshEvent

    event CheckEvent
    event UncheckEvent

    event CdEvent#, file, cwd
    event FileEvent#, file, cwd

    #event ReparentEvent, e : Element
    #event AdoptEvent, e : Element

    event MouseEvent#, key : ...
    event MouseWheelEvent#, ...
    event MouseButtonDownEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    event MouseButtonUpEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    event MouseButtonClickEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    event MouseButtonDoubleClickEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    event MouseOutEvent#, ...
    event MouseOverEvent#, ...

    event ResponseEvent#, out : ...
    #event ResponseEvent_#{out}#, out : ...

    event MoveEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    event DragEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point

    event TitleEvent, title : String

    event ScrollEvent # No data?
    event PressEvent # What is this?

    event KeyPressEvent
    # Keep the list in sync with Key enum, just suffix with _Event
    event Key_Space_Event
    event Key_Any_Event
    event Key_Exclam_Event
    event Key_QuoteDbl_Event
    event Key_NumberSign_Event
    event Key_Dollar_Event
    event Key_Percent_Event
    event Key_Ampersand_Event
    event Key_Apostrophe_Event
    event Key_ParenLeft_Event
    event Key_ParenRight_Event
    event Key_Asterisk_Event
    event Key_Plus_Event
    event Key_Comma_Event
    event Key_Minus_Event
    event Key_Period_Event
    event Key_Slash_Event
    event Key_0_Event
    event Key_1_Event
    event Key_2_Event
    event Key_3_Event
    event Key_4_Event
    event Key_5_Event
    event Key_6_Event
    event Key_7_Event
    event Key_8_Event
    event Key_9_Event
    event Key_Colon_Event
    event Key_Semicolon_Event
    event Key_Less_Event
    event Key_Equal_Event
    event Key_Greater_Event
    event Key_Question_Event
    event Key_At_Event
    event Key_A_Event
    event Key_B_Event
    event Key_C_Event
    event Key_D_Event
    event Key_E_Event
    event Key_F_Event
    event Key_G_Event
    event Key_H_Event
    event Key_I_Event
    event Key_J_Event
    event Key_K_Event
    event Key_L_Event
    event Key_M_Event
    event Key_N_Event
    event Key_O_Event
    event Key_P_Event
    event Key_Q_Event
    event Key_R_Event
    event Key_S_Event
    event Key_T_Event
    event Key_U_Event
    event Key_V_Event
    event Key_W_Event
    event Key_X_Event
    event Key_Y_Event
    event Key_Z_Event
    event Key_BracketLeft_Event
    event Key_Backslash_Event
    event Key_BracketRight_Event
    event Key_AsciiCircum_Event
    event Key_Underscore_Event
    event Key_QuoteLeft_Event
    event Key_BraceLeft_Event
    event Key_Bar_Event
    event Key_BraceRight_Event
    event Key_AsciiTilde_Event
    event Key_nobreakspace_Event
    event Key_exclamdown_Event
    event Key_cent_Event
    event Key_sterling_Event
    event Key_currency_Event
    event Key_yen_Event
    event Key_brokenbar_Event
    event Key_section_Event
    event Key_diaeresis_Event
    event Key_copyright_Event
    event Key_ordfeminine_Event
    event Key_guillemotleft_Event
    event Key_notsign_Event
    event Key_hyphen_Event
    event Key_registered_Event
    event Key_macron_Event
    event Key_degree_Event
    event Key_plusminus_Event
    event Key_twosuperior_Event
    event Key_threesuperior_Event
    event Key_acute_Event
    event Key_mu_Event
    event Key_paragraph_Event
    event Key_periodcentered_Event
    event Key_cedilla_Event
    event Key_onesuperior_Event
    event Key_masculine_Event
    event Key_guillemotright_Event
    event Key_onequarter_Event
    event Key_onehalf_Event
    event Key_threequarters_Event
    event Key_questiondown_Event
    event Key_Agrave_Event
    event Key_Aacute_Event
    event Key_Acircumflex_Event
    event Key_Atilde_Event
    event Key_Adiaeresis_Event
    event Key_Aring_Event
    event Key_AE_Event
    event Key_Ccedilla_Event
    event Key_Egrave_Event
    event Key_Eacute_Event
    event Key_Ecircumflex_Event
    event Key_Ediaeresis_Event
    event Key_Igrave_Event
    event Key_Iacute_Event
    event Key_Icircumflex_Event
    event Key_Idiaeresis_Event
    event Key_ETH_Event
    event Key_Ntilde_Event
    event Key_Ograve_Event
    event Key_Oacute_Event
    event Key_Ocircumflex_Event
    event Key_Otilde_Event
    event Key_Odiaeresis_Event
    event Key_multiply_Event
    event Key_Ooblique_Event
    event Key_Ugrave_Event
    event Key_Uacute_Event
    event Key_Ucircumflex_Event
    event Key_Udiaeresis_Event
    event Key_Yacute_Event
    event Key_THORN_Event
    event Key_ssharp_Event
    event Key_division_Event
    event Key_ydiaeresis_Event
    event Key_Escape_Event
    event Key_Tab_Event
    event Key_Backtab_Event
    event Key_Backspace_Event
    event Key_Return_Event
    event Key_Enter_Event
    event Key_Insert_Event
    event Key_Delete_Event
    event Key_Pause_Event
    event Key_Print_Event
    event Key_SysReq_Event
    event Key_Clear_Event
    event Key_Home_Event
    event Key_End_Event
    event Key_Left_Event
    event Key_Up_Event
    event Key_Right_Event
    event Key_Down_Event
    event Key_PageUp_Event
    event Key_PageDown_Event
    event Key_Shift_Event
    event Key_Control_Event
    event Key_Meta_Event
    event Key_Alt_Event
    event Key_CapsLock_Event
    event Key_NumLock_Event
    event Key_ScrollLock_Event
    event Key_F1_Event
    event Key_F2_Event
    event Key_F3_Event
    event Key_F4_Event
    event Key_F5_Event
    event Key_F6_Event
    event Key_F7_Event
    event Key_F8_Event
    event Key_F9_Event
    event Key_F10_Event
    event Key_F11_Event
    event Key_F12_Event
    event Key_F13_Event
    event Key_F14_Event
    event Key_F15_Event
    event Key_F16_Event
    event Key_F17_Event
    event Key_F18_Event
    event Key_F19_Event
    event Key_F20_Event
    event Key_F21_Event
    event Key_F22_Event
    event Key_F23_Event
    event Key_F24_Event
    event Key_F25_Event
    event Key_F26_Event
    event Key_F27_Event
    event Key_F28_Event
    event Key_F29_Event
    event Key_F30_Event
    event Key_F31_Event
    event Key_F32_Event
    event Key_F33_Event
    event Key_F34_Event
    event Key_F35_Event
    event Key_Super_L_Event
    event Key_Super_R_Event
    event Key_Menu_Event
    event Key_Hyper_L_Event
    event Key_Hyper_R_Event
    event Key_Help_Event
    event Key_Direction_L_Event
    event Key_Direction_R_Event
    event Key_AltGr_Event              
    event Key_Multi_key_Event          
    event Key_Codeinput_Event          
    event Key_SingleCandidate_Event    
    event Key_MultipleCandidate_Event  
    event Key_PreviousCandidate_Event  
    event Key_Mode_switch_Event        
    event Key_Kanji_Event              
    event Key_Muhenkan_Event           
    event Key_Henkan_Event             
    event Key_Romaji_Event             
    event Key_Hiragana_Event           
    event Key_Katakana_Event           
    event Key_Hiragana_Katakana_Event  
    event Key_Zenkaku_Event            
    event Key_Hankaku_Event            
    event Key_Zenkaku_Hankaku_Event    
    event Key_Touroku_Event            
    event Key_Massyo_Event             
    event Key_Kana_Lock_Event          
    event Key_Kana_Shift_Event         
    event Key_Eisu_Shift_Event         
    event Key_Eisu_toggle_Event        
    event Key_Hangul_Event             
    event Key_Hangul_Start_Event       
    event Key_Hangul_End_Event         
    event Key_Hangul_Hanja_Event       
    event Key_Hangul_Jamo_Event        
    event Key_Hangul_Romaja_Event      
    event Key_Hangul_Jeonja_Event      
    event Key_Hangul_Banja_Event       
    event Key_Hangul_PreHanja_Event    
    event Key_Hangul_PostHanja_Event   
    event Key_Hangul_Special_Event     
    event Key_Dead_Grave_Event         
    event Key_Dead_Acute_Event         
    event Key_Dead_Circumflex_Event    
    event Key_Dead_Tilde_Event         
    event Key_Dead_Macron_Event        
    event Key_Dead_Breve_Event         
    event Key_Dead_Abovedot_Event      
    event Key_Dead_Diaeresis_Event     
    event Key_Dead_Abovering_Event     
    event Key_Dead_Doubleacute_Event   
    event Key_Dead_Caron_Event         
    event Key_Dead_Cedilla_Event       
    event Key_Dead_Ogonek_Event        
    event Key_Dead_Iota_Event          
    event Key_Dead_Voiced_Sound_Event  
    event Key_Dead_Semivoiced_Sound_Event
    event Key_Dead_Belowdot_Event      
    event Key_Dead_Hook_Event          
    event Key_Dead_Horn_Event          
    event Key_Dead_Stroke_Event        
    event Key_Dead_Abovecomma_Event    
    event Key_Dead_Abovereversedcomma_Event
    event Key_Dead_Doublegrave_Event   
    event Key_Dead_Belowring_Event     
    event Key_Dead_Belowmacron_Event   
    event Key_Dead_Belowcircumflex_Event
    event Key_Dead_Belowtilde_Event    
    event Key_Dead_Belowbreve_Event    
    event Key_Dead_Belowdiaeresis_Event
    event Key_Dead_Invertedbreve_Event 
    event Key_Dead_Belowcomma_Event    
    event Key_Dead_Currency_Event      
    event Key_Dead_a_Event             
    event Key_Dead_A_Event             
    event Key_Dead_e_Event             
    event Key_Dead_E_Event             
    event Key_Dead_i_Event             
    event Key_Dead_I_Event             
    event Key_Dead_o_Event             
    event Key_Dead_O_Event             
    event Key_Dead_u_Event             
    event Key_Dead_U_Event             
    event Key_Dead_Small_Schwa_Event   
    event Key_Dead_Capital_Schwa_Event 
    event Key_Dead_Greek_Event         
    event Key_Dead_Lowline_Event       
    event Key_Dead_Aboveverticalline_Event
    event Key_Dead_Belowverticalline_Event
    event Key_Dead_Longsolidusoverlay_Event
    event Key_Back_Event 
    event Key_Forward_Event 
    event Key_Stop_Event 
    event Key_Refresh_Event 
    event Key_VolumeDown_Event
    event Key_VolumeMute_Event 
    event Key_VolumeUp_Event
    event Key_BassBoost_Event
    event Key_BassUp_Event
    event Key_BassDown_Event
    event Key_TrebleUp_Event
    event Key_TrebleDown_Event
    event Key_MediaPlay_Event 
    event Key_MediaStop_Event 
    event Key_MediaPrevious_Event 
    event Key_MediaNext_Event 
    event Key_MediaRecord_Event
    event Key_MediaPause_Event
    event Key_MediaTogglePlayPause_Event
    event Key_HomePage_Event 
    event Key_Favorites_Event 
    event Key_Search_Event 
    event Key_Standby_Event
    event Key_OpenUrl_Event
    event Key_LaunchMail_Event 
    event Key_LaunchMedia_Event
    event Key_Launch0_Event 
    event Key_Launch1_Event 
    event Key_Launch2_Event 
    event Key_Launch3_Event 
    event Key_Launch4_Event 
    event Key_Launch5_Event 
    event Key_Launch6_Event 
    event Key_Launch7_Event 
    event Key_Launch8_Event 
    event Key_Launch9_Event 
    event Key_LaunchA_Event 
    event Key_LaunchB_Event 
    event Key_LaunchC_Event 
    event Key_LaunchD_Event 
    event Key_LaunchE_Event 
    event Key_LaunchF_Event 
    event Key_MonBrightnessUp_Event
    event Key_MonBrightnessDown_Event
    event Key_KeyboardLightOnOff_Event
    event Key_KeyboardBrightnessUp_Event
    event Key_KeyboardBrightnessDown_Event
    event Key_PowerOff_Event
    event Key_WakeUp_Event
    event Key_Eject_Event
    event Key_ScreenSaver_Event
    event Key_WWW_Event
    event Key_Memo_Event
    event Key_LightBulb_Event
    event Key_Shop_Event
    event Key_History_Event
    event Key_AddFavorite_Event
    event Key_HotLinks_Event
    event Key_BrightnessAdjust_Event
    event Key_Finance_Event
    event Key_Community_Event
    event Key_AudioRewind_Event
    event Key_BackForward_Event
    event Key_ApplicationLeft_Event
    event Key_ApplicationRight_Event
    event Key_Book_Event
    event Key_CD_Event
    event Key_Calculator_Event
    event Key_ToDoList_Event
    event Key_ClearGrab_Event
    event Key_Close_Event
    event Key_Copy_Event
    event Key_Cut_Event
    event Key_Display_Event
    event Key_DOS_Event
    event Key_Documents_Event
    event Key_Excel_Event
    event Key_Explorer_Event
    event Key_Game_Event
    event Key_Go_Event
    event Key_iTouch_Event
    event Key_LogOff_Event
    event Key_Market_Event
    event Key_Meeting_Event
    event Key_MenuKB_Event
    event Key_MenuPB_Event
    event Key_MySites_Event
    event Key_News_Event
    event Key_OfficeHome_Event
    event Key_Option_Event
    event Key_Paste_Event
    event Key_Phone_Event
    event Key_Calendar_Event
    event Key_Reply_Event
    event Key_Reload_Event
    event Key_RotateWindows_Event
    event Key_RotationPB_Event
    event Key_RotationKB_Event
    event Key_Save_Event
    event Key_Send_Event
    event Key_Spell_Event
    event Key_SplitScreen_Event
    event Key_Support_Event
    event Key_TaskPane_Event
    event Key_Terminal_Event
    event Key_Tools_Event
    event Key_Travel_Event
    event Key_Video_Event
    event Key_Word_Event
    event Key_Xfer_Event
    event Key_ZoomIn_Event
    event Key_ZoomOut_Event
    event Key_Away_Event
    event Key_Messenger_Event
    event Key_WebCam_Event
    event Key_MailForward_Event
    event Key_Pictures_Event
    event Key_Music_Event
    event Key_Battery_Event
    event Key_Bluetooth_Event
    event Key_WLAN_Event
    event Key_UWB_Event
    event Key_AudioForward_Event
    event Key_AudioRepeat_Event
    event Key_AudioRandomPlay_Event
    event Key_Subtitle_Event
    event Key_AudioCycleTrack_Event
    event Key_Time_Event
    event Key_Hibernate_Event
    event Key_View_Event
    event Key_TopMenu_Event
    event Key_PowerDown_Event
    event Key_Suspend_Event
    event Key_ContrastAdjust_Event
    event Key_LaunchG_Event 
    event Key_LaunchH_Event 
    event Key_TouchpadToggle_Event
    event Key_TouchpadOn_Event
    event Key_TouchpadOff_Event
    event Key_MicMute_Event
    event Key_Red_Event
    event Key_Green_Event
    event Key_Yellow_Event
    event Key_Blue_Event
    event Key_ChannelUp_Event
    event Key_ChannelDown_Event
    event Key_Guide_Event   
    event Key_Info_Event    
    event Key_Settings_Event
    event Key_MicVolumeUp_Event  
    event Key_MicVolumeDown_Event
    event Key_New_Event     
    event Key_Open_Event    
    event Key_Find_Event    
    event Key_Undo_Event    
    event Key_Redo_Event    
    event Key_MediaLast_Event
    event Key_Select_Event
    event Key_Yes_Event
    event Key_No_Event
    event Key_Cancel_Event 
    event Key_Printer_Event
    event Key_Execute_Event
    event Key_Sleep_Event  
    event Key_Play_Event   
    event Key_Zoom_Event   
    event Key_Exit_Event   
    event Key_Context1_Event
    event Key_Context2_Event
    event Key_Context3_Event
    event Key_Context4_Event
    event Key_Call_Event
    event Key_Hangup_Event
    event Key_Flip_Event
    event Key_ToggleCallHangup_Event
    event Key_VoiceDial_Event
    event Key_LastNumberRedial_Event
    event Key_Camera_Event
    event Key_CameraFocus_Event
    event Key_unknown_Event

    #Key_Kanji_Bangou_Event       
    #Key_Zen_Koho_Event           
    #Key_Mae_Koho_Event           
    #Key_Hangul_Codeinput_Event   
    #Key_Hangul_SingleCandidate_Event  
    #Key_Hangul_MultipleCandidate_Event
    #Key_Hangul_PreviousCandidate_Event
    #Key_Hangul_switch_Event      
    #Key_Jisho_Event  
    #Key_Oyayubi_Left_Event
    #Key_Oyayubi_Right_Event
  end
end
