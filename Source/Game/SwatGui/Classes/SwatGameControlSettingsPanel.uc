// ====================================================================
//  Class:  SwatGui.SwatGameControlSettingsPanel
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatGameControlSettingsPanel extends SwatSettingsPanel
     ;

import enum ECommandInterfaceStyle from SwatGame.SwatGUIConfig;
import enum eVoiceType from SwatGame.SwatGUIConfig;

var(SWATGui) private EditInline Config GUIComboBox MyVoiceTypeBox;
var(SWATGui) private EditInline Config GUIEditBox MyMPNameBox;

var(SWATGui) private EditInline Config GUICheckBoxButton MyAlwaysRunCheck;
var(SWATGui) private EditInline Config GUIComboBox MyNetSpeedBox;
var(SWATGui) private EditInline Config GUICheckBoxButton MyHelpTextCheck;
#if IG_CAPTIONS 
var(SWATGui) private EditInline Config GUICheckBoxButton MyShowSubtitlesCheck;
#endif
var(SWATGui) private EditInline Config GUIRadioButton MyGraphicCICheck;
var(SWATGui) private EditInline Config GUIRadioButton MyClassicCICheck;
var(SWATGui) private EditInline Config GUISlider MyMouseSensitivity;
var(SWATGui) private EditInline Config GUICheckBoxButton MyInvertMouseCheck;
var(SWATGui) private EditInline Config GUIPanel MyGCIOptions;
var(SWATGui) private EditInline Config GUIRadioButton MyGCIOption1Check;
var(SWATGui) private EditInline Config GUIRadioButton MyGCIOption2Check;
var(SWATGui) private EditInline Config GUIRadioButton MyGCIOption3Check;
var(SWATGui) private EditInline Config GUIRadioButton MyGCIOption4Check;
var(SWATGui) private EditInline Config GUIRadioButton MyGCIExitMenuOptionCheck;

var(SWATGui) private EditInline Config GUILabel MyGCIOptionS1P1Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS1P2Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS1P3Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS2P1Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS2P2Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS2P3Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS3P1Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS3P2Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS3P3Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS4P1Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS4P2Label;
var(SWATGui) private EditInline Config GUILabel MyGCIOptionS4P3Label;

var() private config localized string GCIOptionS1P1String;
var() private config localized string GCIOptionS1P2String;
var() private config localized string GCIOptionS1P3String;
var() private config localized string GCIOptionS2P1String;
var() private config localized string GCIOptionS2P2String;
var() private config localized string GCIOptionS2P3String;
var() private config localized string GCIOptionS3P1String;
var() private config localized string GCIOptionS3P2String;
var() private config localized string GCIOptionS3P3String;
var() private config localized string GCIOptionS4P1String;
var() private config localized string GCIOptionS4P2String;
var() private config localized string GCIOptionS4P3String;

var() private float DefaultMouseSensitivity;

function InitComponent(GUIComponent MyOwner)
{
    local int i;
	Super.InitComponent(MyOwner);
	
    MyMPNameBox.MaxWidth = GC.MPNameLength;
    MyMPNameBox.AllowedCharSet = GC.MPNameAllowableCharSet;

	for( i = 0; i < GC.NetworkConnectionChoices.Length; i++ )
	{
    	MyNetSpeedBox.AddItem(GC.NetworkConnectionChoices[i],,,GC.NetworkConnectionSpeeds[i]);
    }
    MyNetSpeedBox.SetIndex(0);

	for( i = 0; i < GC.VoiceTypeChoices.Length; i++ )
	{
    	MyVoiceTypeBox.AddItem(GC.VoiceTypeChoices[i]);
    }
    MyVoiceTypeBox.SetIndex(0);

    MyMouseSensitivity.OnChange=OnMouseSensitivityChanged;
    MyInvertMouseCheck.OnChange=OnInvertMouseClicked;
    MyHelpTextCheck.OnChange=OnHelpTextClicked; 
    
    MyGraphicCICheck.OnChange=OnCISelectionChanged;
}

event Show()
{
    Super.Show();
    
    MyGCIOptionS1P1Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS1P1String, "[k=", "]" ) );
    MyGCIOptionS1P2Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS1P2String, "[k=", "]" ) );
    MyGCIOptionS1P3Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS1P3String, "[k=", "]" ) );
    MyGCIOptionS2P1Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS2P1String, "[k=", "]" ) );
    MyGCIOptionS2P2Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS2P2String, "[k=", "]" ) );
    MyGCIOptionS2P3Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS2P3String, "[k=", "]" ) );
    MyGCIOptionS3P1Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS3P1String, "[k=", "]" ) );
    MyGCIOptionS3P2Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS3P2String, "[k=", "]" ) );
    MyGCIOptionS3P3Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS3P3String, "[k=", "]" ) );
    MyGCIOptionS4P1Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS4P1String, "[k=", "]" ) );
    MyGCIOptionS4P2Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS4P2String, "[k=", "]" ) );
    MyGCIOptionS4P3Label.SetCaption( ReplaceKeybindingCodes( GCIOptionS4P3String, "[k=", "]" ) );
    
    MyGCIOptions.SetActive( MyGraphicCICheck.bChecked );
    MyGCIOptions.SetVisibility( MyGraphicCICheck.bChecked );
}

function SaveSettings()
{
    local int NewNetSpeed;

    //TODO
    SwatPlayerController(PlayerOwner()).SetName( MyMPNameBox.GetText() );
    
    GC.PreferredVoiceType = eVoiceType( MyVoiceTypeBox.GetIndex() );
    if (GC.PreferredVoiceType != eVoiceType.VOICETYPE_Random)
    {
        // User is using a non-random voice type. Invalidate the random
        // voice cache so that next time the user switches to a random 
        // voice type, a new random voice will be cached.
        GC.CachedRandomVoice = eVoiceType.VOICETYPE_Random;
    }
    NewNetSpeed = MyNetSpeedBox.List.GetExtraIntData();
    class'Player'.default.ConfiguredInternetSpeed = NewNetSpeed;
    class'Player'.static.StaticSaveConfig();
    PlayerOwner().SetNetSpeed( NewNetSpeed );
    GC.NetSpeedSelection = MyNetSpeedBox.GetIndex();
    
    GC.bUseExitMenu = MyGCIExitMenuOptionCheck.bChecked;
    
    if( MyGCIOption1Check.bChecked )
        GC.GCIButtonMode = 1;
    else if( MyGCIOption2Check.bChecked )
        GC.GCIButtonMode = 2;
    else if( MyGCIOption3Check.bChecked )
        GC.GCIButtonMode = 3;
    else if( MyGCIOption4Check.bChecked )
        GC.GCIButtonMode = 4;
    else
        GC.GCIButtonMode = 0;
    
    if (MyGraphicCICheck.bChecked)
        GC.CommandInterfaceStyle = ECommandInterfaceStyle.CommandInterface_Graphic;
    else
        GC.CommandInterfaceStyle = ECommandInterfaceStyle.CommandInterface_Classic;
    
    GC.SetCurrentCommandInterfaceStyle( GC.CommandInterfaceStyle );

    if( SwatGamePlayerController(PlayerOwner()) != None )
        SwatGamePlayerController(PlayerOwner()).SetCommandInterface(GC.CurrentCommandInterfaceStyle);

    GC.bAlwaysRun = MyAlwaysRunCheck.bChecked;
    if( SwatGamePlayerController(PlayerOwner()) != None )
        SwatGamePlayerController(PlayerOwner()).SetAlwaysRun( GC.bAlwaysRun );
    
#if IG_CAPTIONS 
    GC.bShowSubtitles = MyShowSubtitlesCheck.bChecked;
#endif
    
    GC.SaveConfig();
}

function LoadSettings()
{
    local bool IsMouseInverted;
    local float MouseXMultiplier, MouseYMultiplier;

    MyMPNameBox.SetText( GC.MPName );
    MyNetSpeedBox.SetIndex(GC.NetSpeedSelection);
    MyVoiceTypeBox.SetIndex(GC.PreferredVoiceType);

    if( GC.CommandInterfaceStyle == ECommandInterfaceStyle.CommandInterface_Graphic )
        SetRadioGroup(MyGraphicCICheck);
    else //if( GC.CommandInterfaceStyle == ECommandInterfaceStyle.CommandInterface_Classic )
        SetRadioGroup(MyClassicCICheck);

    switch( GC.GCIButtonMode )
    {
        case 1:
            MyGCIOptions.SetRadioGroup(MyGCIOption1Check);
            break;
        case 2:
            MyGCIOptions.SetRadioGroup(MyGCIOption2Check);
            break;
        case 3:
            MyGCIOptions.SetRadioGroup(MyGCIOption3Check);
            break;
        case 4:
            MyGCIOptions.SetRadioGroup(MyGCIOption4Check);
            break;
        default:
            MyGCIOptions.SetRadioGroup(None);
            break;
    }
        
    MyGCIExitMenuOptionCheck.SetChecked( GC.bUseExitMenu );
        
    MyHelpTextCheck.SetChecked( GC.bShowHelp );
    MyAlwaysRunCheck.SetChecked( GC.bAlwaysRun );
    
    MouseXMultiplier = float(PlayerOwner().ConsoleCommand("Get WinDrv.WindowsClient MouseXMultiplier"));
    MouseYMultiplier = float(PlayerOwner().ConsoleCommand("Get WinDrv.WindowsClient MouseYMultiplier"));
    //Log("Mouse Multipliers Are: X="$MouseXMultiplier$" Y="$MouseYMultiplier);
    MyMouseSensitivity.SetValue( MouseXMultiplier );

    IsMouseInverted = bool(PlayerOwner().ConsoleCommand("Get PlayerInput bInvertMouse"));
    //Log("Mouse Inverted Is: "$IsMouseInverted);
    MyInvertMouseCheck.SetChecked( IsMouseInverted );
    
#if IG_CAPTIONS 
    MyShowSubtitlesCheck.SetChecked( GC.bShowSubtitles );
#endif
}

private function OnMouseSensitivityChanged( GUIComponent Sender )
{
    local float Multiplier;
    Multiplier = GUISlider(Sender).Value;
    
    // clamp to 0.01...1.0 range, because unreal treats 0.0 as 1.0 for mouse sensitivity
    Multiplier = FClamp(Multiplier, 0.01, 1.0);
    
    //Log("Setting mouse sensitivity multiplier to "$Multiplier);
	
	Controller.StaticExec("Set WinDrv.WindowsClient MouseXMultiplier"@Multiplier);
	Controller.StaticExec("Set WinDrv.WindowsClient MouseYMultiplier"@Multiplier);
}

private function OnInvertMouseClicked( GUIComponent Sender )
{
    //Log("Setting mouse inversion to "$MyInvertMouseCheck.bChecked);
	Controller.StaticExec("Set PlayerInput bInvertMouse "$(MyInvertMouseCheck.bChecked));
}

private function OnHelpTextClicked( GUIComponent Sender )
{
    //Log("Setting help text display toggle to to "$MyHelpTextCheck.bChecked);
    GC.bShowHelp = MyHelpTextCheck.bChecked;
    Controller.bDontDisplayHelpText = !GC.bShowHelp;
    Controller.TopPage().HelpText.SetVisibility(GC.bShowHelp);
}

private function OnCISelectionChanged( GUIComponent Sender )
{
    MyGCIOptions.SetActive( MyGraphicCICheck.bChecked );
    MyGCIOptions.SetVisibility( MyGraphicCICheck.bChecked );
}


protected function ResetToDefaults()
{
    //set the game defaults here
    MyMouseSensitivity.SetValue( DefaultMouseSensitivity );
	MyInvertMouseCheck.SetChecked( false );
	MyHelpTextCheck.SetChecked( true );
	MyAlwaysRunCheck.SetChecked( false );
    SetRadioGroup(MyGraphicCICheck);
    MyGCIOptions.SetRadioGroup(MyGCIOption2Check);
}

defaultproperties
{
    ConfirmResetString="Are you sure that you wish to reset all game settings to their defaults?"
    
    DefaultMouseSensitivity=0.5
    
    GCIOptionS1P1String="Hold [k=OpenGraphicCommandInterface | RightMouseAlias] to open menu"
    GCIOptionS1P2String="Click [k=Fire] to select"
    GCIOptionS1P3String="Release [k=OpenGraphicCommandInterface | RightMouseAlias] to cancel"
    GCIOptionS2P1String="Hold [k=OpenGraphicCommandInterface | RightMouseAlias] to open menu"
    GCIOptionS2P2String="Release [k=OpenGraphicCommandInterface | RightMouseAlias] to select"
    GCIOptionS2P3String="Click [k=Fire] to cancel"
    GCIOptionS3P1String="Click [k=OpenGraphicCommandInterface | RightMouseAlias] to open menu"
    GCIOptionS3P2String="Click [k=Fire] to select"
    GCIOptionS3P3String="Click [k=OpenGraphicCommandInterface | RightMouseAlias] to cancel"
    GCIOptionS4P1String="Click [k=OpenGraphicCommandInterface | RightMouseAlias] to open menu"
    GCIOptionS4P2String="Click [k=OpenGraphicCommandInterface | RightMouseAlias] to select"
    GCIOptionS4P3String="Click [k=Fire] to cancel"
}
