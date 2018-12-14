class CommandInterface extends PlayerFocusInterface
    implements  IInterested_GameEvent_GameStarted,
                ISpeechClient, 
                IEffectObserver
    dependsOn(SwatGUIConfig)
    native
    abstract;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum SpeechRecognitionConfidence from Engine.SpeechManager;
import enum eVoiceType from SwatGame.SwatGUIConfig;

//Ideally these should be protected, and GUIGraphicCommandInterface should be a friend of CommandInterface.
//Since UnrealScript doesn't support friend classes, these need to be public.
var SwatAICommon.OfficerTeamInfo            Element;
var SwatAICommon.OfficerTeamInfo            RedTeam;
var SwatAICommon.OfficerTeamInfo            BlueTeam;
//
var SwatAICommon.OfficerTeamInfo            CurrentCommandTeam;    //the officer team to which commands are currently being directed

var class<CommandInterfaceContextsList>     ContextsListClass;              //the class that is used to contain the list of contexts for this CommandInterface
                                                                            //this is used to support independent CommandInterface configuration in SP vs. MP

var class<CommandInterfaceMenuInfo>         MenuInfoClass;                  //the class to instantiate for each entry in the MenuInfo array
                                                                            //this is used to support independent CommandInterface configuration in SP vs. MP
var array<CommandInterfaceMenuInfo>         MenuInfo;                       //information about each of the menus as a whole, eg. AnchorCommand

//StaticCommands
//
//These are commands that are *always* available and need *no* special handling code.
//A Command will be instantiated with each name, and added to the Commands array.
//Each of these static commands will have its Command member set to Command_Static, and its bStatic member set to true.
//This is an optimization: static commands are made available when the game starts, are never cleared, and are never
//  reevaluated for availability.
//Note that there *are* some commands that are bStatic=true that are *not* in this list.  These
//  are commands that are always available, and don't need to be reevaluated, but they *do*
//  have associated special handling code.  These commands are not listed in the StaticCommands
//  array, but rather have their own unique ECommand enum value so that they can be uniquely identified by
//  their ECommand value like other "dynamic" commands.
//For reference:
//  - Commands have a unique ECommand value iff there is unique code associated with the command.
//  - Commands are set to bStatic=true iff they are always available, and so they never need to be evaluated for availability.
//
var config class<CommandInterfaceStaticCommands> StaticCommandsClass;       //the class that is used to contain the list of static commands for this CommandInterface
                                                                            //this is used to support independent CommandInterface configuration in SP vs. MP
var array<name>                             StaticCommands;                 //a list of "static" commands, configured in CommandInterfaceStaticCommands subclasses for SP and for MP

var class<Command>                          CommandClass;                   //the class to be instantiated for each defined command
var array<Command>                          Commands;                       //all Commands recognized by the CommandInterface

var bool                                    Enabled;                        //whether this CommandInterface is able to handle requests to give commands now
var bool                                    DefaultCommandEnabled;          //whether this CommandInterface is able to handle requests to give default commands now

enum CommandInterfacePage
{
    Page_None,

    Page_Command,
    Page_Deploy,
    //MP-only
    Page_Response,
    Page_RapidDeployment,
    Page_VIPEscort,
    Page_General
};
var protected CommandInterfacePage          CurrentPage;                    //which page of the command interface is currently selected
                                                                            //PLEASE only access thru Set/GetCurrentPage
var protected CommandInterfacePage          CurrentMainPage;                //which page of the command interface is currently the main page

//each command's MenuPadStatus is updated when the CommandInterface is updated.
//the MenuPadStatus represents the status/availability of a particular command:
enum MenuPadStatus
{
    Pad_Normal,         //the command is available, and the CurrentCommandTeam reports that it can execute the command
    Pad_GreyedOut,      //the command makes logical sense in the current context, but the CurrentCommandTeam reports that it can't execute the command now (probably missing required equipment)
    Pad_Disabled        //the command doesn't make logical sense in the current context
};

var private Command                         DefaultCommand;                 //the current DefaultCommand, which is automatically set based on what the player is looking at.  this command is given if the player presses the default command key.
var private int                             DefaultPriority;                //The priority of the current DefaultCommand.  Used to permit default commands to be overridden by other commands with more specific contexts.
var private Command                         CurrentOverrideDefaultCommand;  //if the CurrentPage specifies an OverrideDefaultCommand, then this is set to that command
var protected GUIDefaultCommandIndicator    DefaultCommandControl;          //the GUI control that displays the current DefaultCommand
var protected GUILabel                      CurrentMainPageControl;         //the GUI control that displays the CurrentMainPage

var private bool                            Selected;                       //true if this CommandInterface is the local player's currently selected command interface

//the PendingCommand variables are used to hold information about a command that has been given, but
//  has not yet finished being spoken.  these variables are used to send the command to the officers
//  once the speech has finished.
var private Command                         PendingCommand;
var private vector                          PendingCommandOrigin;           //the location of the player's camera at the time that the command was given, ie. started
var private SwatAICommon.OfficerTeamInfo    PendingCommandTeam;             //the officer team to which the command was directed
var private array<Focus>                    PendingCommandFoci;             //the CommandInterface's list of Foci (see PlayerFocusInterface.uc) at the time that the command was given
var private int                             PendingCommandFociLength;       //the length of Foci (see PlayerFocusInterface.uc) at the time that the command was given
var private SwatAICharacter                 PendingCommandTargetCharacter;  //the AI character to which the PendingCommand refers

//in Training, the CommandInterface is used in a "mode" where the player is expected to give
//  a specific command, possibly to a specific team, and/or at a specific Door.
//if there is an ExpectedCommand, then other commands will be ignored.
var name                                    ExpectedCommand;                //the command that the player is expected to give, if any
var name                                    ExpectedCommandTeam;            //the team that the player is expected to command, if any
var name                                    ExpectedCommandTargetDoor;      //the door to which the player is expected to refer, if any
var name                                    ExpectedCommandSource;          //the source viewport from which the command should be given, if any

var private SwatDoor                        CurrentDoorFocus;               //while updating the CommandInterface, the Door that is currently being considered

var private SwatAICommon.OfficerTeamInfo    LastCommandTeam;                //the last team to which a command was given
var private bool                            CommandSpeechInitialized;       //used to detect and manage the initiation and interruption of command speech

var config bool                             DebugTerminalLocation;          //if true, then when a command is given, a debug box will be drawn in the world at the location that is considered the target of the command

var vector                                  LastFocusUpdateOrigin;          //the origin (start) of the trace the last time that the CommandInterface was updated

var String                                  GaveCommandString;              //the string used for concatenating MP command client messages, eg. "tektor: Fall In"

var config bool                             SometimesSendInterruptedCommand;//if true, then interrupted commands are sometimes sent to the officers

enum ECommand
{
    Command_None,

    //MAIN Menu

    Command_Command,
    Command_Deploy,

    //Command Menu

    Command_StackUpAndTryDoor,
    Command_PickLock,
    Command_MoveAndClear,

    Command_BreachAndClear,
    Command_BreachAndMakeEntry,
    Command_OpenAndClear,
    Command_OpenAndMakeEntry,

    Command_BangAndClear,
    Command_BreachBangAndClear,
    Command_BreachBangAndMakeEntry,
    Command_OpenBangAndClear,
    Command_OpenBangAndMakeEntry,

    Command_GasAndClear,
    Command_BreachGasAndClear,
    Command_BreachGasAndMakeEntry,
    Command_OpenGasAndClear,
    Command_OpenGasAndMakeEntry,

    Command_StingAndClear,
    Command_BreachStingAndClear,
    Command_BreachStingAndMakeEntry,
    Command_OpenStingAndClear,
    Command_OpenStingAndMakeEntry,

    Command_FallIn,
    Command_MoveTo,
    Command_Cover,
    Command_Disable,
    Command_DisableBomb,
    Command_DisableBoobyTrap,
    Command_CloseDoor,
    Command_RemoveWedge,
    Command_SecureEvidence,
    Command_Restrain,
    Command_MirrorRoom,
    Command_MirrorUnderDoor,
    Command_MirrorCorner,
    Command_Report,

    //DEPLOY Menu

    Command_Deploy_Wedge,
    Command_Deploy_BreachingShotgun,
    Command_Deploy_LessLethalShotgun,
    Command_Deploy_Taser,
    Command_Deploy_Flashbang,
    Command_Deploy_CSGas,
    Command_Deploy_StingGrenade,
    Command_Deploy_PepperSpray,
    Command_Deploy_C2Charge,
    Command_Deploy_CSBallLauncher,

    //
    // All Static Commands have their ECommand set to Command_Static
    //

    Command_Static
};

simulated function PreBeginPlay()
{
    local int i;
    local CommandInterfaceContextsList ContextsList;
    local CommandInterfaceStaticCommands StaticCommandsList;

    Super.PreBeginPlay();

    //always start on the Command page
    CurrentPage = Page_Command;
    SetMainPage(Page_Command);

    //Other PlayerFocusInterfaces have their "Context" and "DoorRelatedContext" lists
    //  automatically filled from their config file.
    //CommandInterfaces can't use this technique, because different subclasses use
    //  different config files, to support independent CommandInterface configuration
    //  between SP and MP games.
    //So instead, CommandInterfaces use CommandInterfaceContextsLists, and copy the
    //  contexts configured in those classes into the CommandInterfaces context lists.

    ContextsList = new(None) ContextsListClass;
    assert(ContextsList != None);

    for (i=0; i<ContextsList.Context.length; ++i)
        Context[i] = ContextsList.Context[i];

    for (i=0; i<ContextsList.DoorRelatedContext.length; ++i)
        DoorRelatedContext[i] = ContextsList.DoorRelatedContext[i];

    //Copy static commands from CommandInterfaceStaticCommands container into this CommandInterface

    StaticCommandsList = new(None) StaticCommandsClass;
    assert(StaticCommandsList != None);

    for (i=0; i<StaticCommandsList.StaticCommand.length; ++i)
        StaticCommands[i] = StaticCommandsList.StaticCommand[i];

    //instantiate CommandInterfaceMenuInfos
    for (i=1; i<CommandInterfacePage.EnumCount; ++i)    //skip Page_None enum value 0
    {
        MenuInfo[i] = new(None, string(GetEnum(CommandInterfacePage, i))) MenuInfoClass;
        assert(MenuInfo[i] != None);
    }
}

//initialize the CommandInterface
simulated function PostBeginPlay()
{
    local int i, j;
    local int NumDynamicCommands;
    local Command NewCommand;

    Super.PostBeginPlay();

    Label = 'CommandInterface';

    assert(CommandClass != None);

    //instantiate all of the commands that the CommandInterface recognizes
    NumDynamicCommands = int(ECommand.EnumCount);
    for (i=0; i<int(ECommand.Command_Static); ++i)
        NewCommand = InstantiateCommand(i, GetEnum(ECommand, i), ECommand(i));
    //instantiate static commands
    for (i=0; i<StaticCommands.length; ++i)
    {
        NewCommand = InstantiateCommand(NumDynamicCommands + i, StaticCommands[i], Command_Static);
        NewCommand.bStatic = true;
    }
    //lookup MenuInfos' OverrideDefaultCommands
    for (i=1; i<CommandInterfacePage.EnumCount; ++i)    //skip Page_None enum value 0
    {
        if (MenuInfo[i].OverrideDefaultCommand != '')
        {
            for (j=0; j<Commands.length; ++j)
                if ( Commands[j] != None && Commands[j].name == MenuInfo[i].OverrideDefaultCommand)
                    MenuInfo[i].OverrideDefaultCommandObject = Commands[j];

            //MenuInfo[i] specifies an OverrideDefaultCommand.
            //That OverrideDefaultCommand should have been found by
            //  iterating over all commands (the j loop).
            assertWithDescription(MenuInfo[i].OverrideDefaultCommandObject != None,
                "[tcohen] The OverrideDefaultCommand "$MenuInfo[i].OverrideDefaultCommand
                $" specified for the CommandInterface menu named "$MenuInfo[i].name
                $" is not a valid command name.  Please fix this in CommandInterfaceMenus_MP/SP.ini");
        }
    }

    if( Level.NetMode == NM_Standalone )
    {
        //cache references to the officer teams
        Element = SwatAIRepository(Level.AIRepo).GetElementSquad();
        RedTeam = SwatAIRepository(Level.AIRepo).GetRedSquad();
        BlueTeam = SwatAIRepository(Level.AIRepo).GetBlueSquad();
    }

    //initialize the current team to the element
    SetCurrentTeam(Element);

#if IG_SPEECH_RECOGNITION
    Level.GetEngine().SpeechManager.RegisterRuleInterest(self, 'Team');
    Level.GetEngine().SpeechManager.RegisterRuleInterest(self, 'Command');
#endif

    if( Level.NetMode == NM_Standalone )
    {
        //register for notification that the game has started
        SwatGameInfo(Level.Game).GameEvents.GameStarted.Register(self);
    }
    else
    {
        //in Multiplayer, we dont need to (and cannot) wait for the GameStarted Game Event
        Initialize();
    }
}

//set the type of focus interface, consistent through subclasses
//  used to test if Contexts meets special conditions for this type of PlayerFocusInterface 
simulated function SetFocusInterfaceType()
{
    FocusInterfaceType = 'CommandInterface';
}

simulated function Command InstantiateCommand(int Index, name InstanceName, ECommand Command)
{
    local Command NewCommand;

    NewCommand = new (None, string(InstanceName)) CommandClass;
    assert(NewCommand != None);
    Commands[Index] = NewCommand;
    NewCommand.Index = Index;

    assertWithDescription(NewCommand.Page != Page_None || NewCommand.Command == Command_None,
        "[tcohen] "$class.name
        $"::InstantiateCommand() There is no Page specified for "$InstanceName
        $".  Check that the config file contains a specification for this Command.");
    
    NewCommand.Command = Command;

    if (NewCommand.SubPage != Page_None)
        NewCommand.bStatic = true;  //submenu anchors are always static, ie. never context sensitive

    return NewCommand;
}

simulated function OnGameStarted()
{
    Initialize();
}

simulated function Initialize()
{
    local SwatGamePlayerController Player;

    Player = SwatGamePlayerController(Level.GetLocalPlayerController());
    assert(Player != None);

    DefaultCommandControl = Player.GetHUDPage().DefaultCommand;
    assert(DefaultCommandControl != None);

    CurrentMainPageControl = Player.GetHUDPage().CommandInterfaceMenuPage;
    assert(CurrentMainPageControl != None);

    SetMainPage(CommandInterfacePage(CurrentMainPage));

    Player.UpdateFocus();   //need to update focus so that View.OnCurrentTeamChanged() has valid commands to use when refreshing pad styles

    CheckTeam();

    DefaultCommandControl.OnCurrentTeamChanged(CurrentCommandTeam);
    
    ActivateStaticCommands();
}

simulated function ActivateStaticCommands()
{
    local int i;

    //activate all static commands
    for (i=0; i<Commands.length; ++i)
    {
        if( Commands[i] != None && Commands[i].bStatic )
            SetCommandStatus(Commands[i]);
    }
}

//updates Selected to reflect whether this CommandInterface is the local player's currently selected CommandInterface
simulated function OnSelectedCommandInterfaceChanged(CommandInterface NewSelected)
{
    Selected = (NewSelected == self);
    SetCurrentTeam(CurrentCommandTeam);
}

//
// Update Sequence - See documentation above PlayerFocusInterface::PreUpdate()
//

simulated protected function bool PreUpdateHook(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    local bool Result;

    //a command interface wants to update if it is enabled and it is the player's selected command interface
    Result = (Enabled && Player.GetCommandInterface() == self);

    return Result;
}

simulated protected function ResetFocusHook(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    if (CurrentOverrideDefaultCommand == None)
    {
        //reset default command
        DefaultCommand = Commands[ECommand.Command_FallIn];
        DefaultPriority = -1;
    }
    else if (DefaultCommand != CurrentOverrideDefaultCommand)
    {
        DefaultCommand = CurrentOverrideDefaultCommand;
        DefaultCommandControl.SetCaption( GetColorizedCommandText(DefaultCommand) );
    }

    CurrentDoorFocus = None;

    ClearCommands(false);   //not a page change

    //remember the origin of the focus trace
    LastFocusUpdateOrigin = SwatGamePlayerController(Level.GetLocalPlayerController()).LastFocusUpdateOrigin;
}

simulated protected event PostContextMatched(PlayerInterfaceContext inContext, Actor Target)
{
    local CommandInterfaceContext Context;
    local int i;

    Context = CommandInterfaceContext(inContext);

    for (i=0; i<Context.Command.length; ++i)
        SetCommandStatus(Commands[int(Context.Command[i])]);

    if (Context.DefaultCommand != Command_None)
        ConsiderDefaultCommand(Commands[int(Context.DefaultCommand)], Context.DefaultCommandPriority);
}

simulated protected event PostDoorRelatedContextMatched(PlayerInterfaceDoorRelatedContext inContext, Actor Target)
{
    local CommandInterfaceDoorRelatedContext Context;
    local int i;

    CurrentDoorFocus = SwatDoor(Target);
    assert(CurrentDoorFocus != None);
    Context = CommandInterfaceDoorRelatedContext(inContext);

    for (i=0; i<Context.Command.length; ++i)
        SetCommandStatus(Commands[int(Context.Command[i])]);

    if (Context.DefaultCommand != Command_None)
        ConsiderDefaultCommand(Commands[int(Context.DefaultCommand)], Context.DefaultCommandPriority);
}

simulated function PostUpdate();

//
// (End of Update Sequence)
//

//set the CurrentCommandTeam by OfficerTeamInfo, and permit subclasses to do something when the current team changes
simulated overloaded final function SetCurrentTeam(SwatAICommon.OfficerTeamInfo NewTeam)
{
    if (NewTeam != CurrentCommandTeam)
    {
        CurrentCommandTeam = NewTeam;

        if (DefaultCommandControl != None)
            DefaultCommandControl.OnCurrentTeamChanged(NewTeam);

        OnCurrentTeamChanged(NewTeam);
    }
}
simulated protected function OnCurrentTeamChanged(SwatAICommon.OfficerTeamInfo NewTeam);

//set the CurrentCommandTeam by name, and check that that is an appropriate team to be the current team
simulated overloaded final function SetCurrentTeam(name NewTeam)
{
    switch (NewTeam)
    {
        case 'RedTeam':
            SetCurrentTeam(RedTeam);
            break;
        case 'BlueTeam':
            SetCurrentTeam(BlueTeam);
            break;
        case 'Element':
            SetCurrentTeam(Element);
            break;
        default:
            assert(false);
    }

	CheckTeam();
}

simulated final function name GetCurrentTeam()
{
    switch (CurrentCommandTeam)
    {
        case RedTeam:
            return 'RedTeam';
        case BlueTeam:
            return 'BlueTeam';
        case Element:
            return 'Element';
        default:
            assert(false);
    }
}

//forward to the PlayerController a request to UpdateFocus()
simulated final function UpdateFocus()
{
    SwatGamePlayerController(Level.GetLocalPlayerController()).UpdateFocus();
}

//set the current CommandInterfacePage... implemented in subclasses
simulated function SetCurrentPage(CommandInterfacePage NewPage, optional bool Force);

//return the currently selected CommandInterfacePage
simulated function CommandInterfacePage GetCurrentPage()
{
    return CurrentPage;
}

//return the currently selected main CommandInterfacePage
simulated function CommandInterfacePage GetCurrentMainPage()
{
    return CurrentMainPage;
}

//select the page that is the parent of the current page
simulated function Back()
{
    if (CurrentPage != CurrentMainPage)
        SetCurrentPage(CurrentMainPage);
}

//set the current team to the next available officer team with wrapping
simulated function NextTeam()
{
    if (CurrentCommandTeam == Element)
        SetCurrentTeam(RedTeam);
    else
    if (CurrentCommandTeam == RedTeam)
        SetCurrentTeam(BlueTeam);
    else
    if (CurrentCommandTeam == BlueTeam)
        SetCurrentTeam(Element);
    else
        assertWithDescription(false,
            "[tcohen] CommandInterface::NextTeam() CurrentCommandTeam isn't Red, Blue, or Element.");

    CheckTeam();
}

simulated final function SetMainPage(CommandInterfacePage Page)
{
    PreMainPageChanged();

    CurrentMainPage = Page;

    if( CurrentMainPage < MenuInfo.Length )
    {
        if (CurrentMainPageControl != None)
            CurrentMainPageControl.SetCaption(MenuInfo[int(Page)].Text);

        CurrentOverrideDefaultCommand = MenuInfo[int(CurrentMainPage)].OverrideDefaultCommandObject;
    }

    SwatGamePlayerController(Level.GetLocalPlayerController()).UpdateFocus();   //need to update default command
    
    PostMainPageChanged();
}
simulated protected function PreMainPageChanged();   //for subclasses
simulated protected function PostMainPageChanged();   //for subclasses

//set the current main menu to the next available main menu with wrapping
//implemented in-terms-of SetMainPage()
simulated final function NextMainPage()
{
    local int CurrentMainPageIndex;
    local bool FoundNextMainPage;
//log( self$"::NextMainPage()" );

    CurrentMainPageIndex = int(CurrentMainPage);
    FoundNextMainPage = false;

    while (!FoundNextMainPage)
    {
        CurrentMainPageIndex++;

        if (CurrentMainPageIndex >= CommandInterfacePage.EnumCount)
            CurrentMainPageIndex = 1;   //wrap to the first page after Page_None

        if  (
                MenuInfo[CurrentMainPageIndex].AnchorCommand == Command_None    //its a main page
            &&  MenuInfo[CurrentMainPageIndex].IsAvailable(Level)               //its available
            )
            FoundNextMainPage = true;
    }

    SetMainPage(CommandInterfacePage(CurrentMainPageIndex));
}

//checks if a team has no members, and if so, selects the appropriate team
simulated function CheckTeam()
{
    local bool RedHasMembers, BlueHasMembers;

    if (!Element.HasActiveMembers())
        //all of the officers are incapacitated
        Deactivate();
    else
    {
        RedHasMembers = RedTeam.HasActiveMembers();
        BlueHasMembers = BlueTeam.HasActiveMembers();

        if (!RedHasMembers)
            SetCurrentTeam(BlueTeam);
        else
        if (!BlueHasMembers)
            SetCurrentTeam(RedTeam);
    }
}

//returns if the currently selected team has active members
simulated function bool CurrentTeamHasActiveMembers()
{
    return CurrentCommandTeam.HasActiveMembers();
}

//set this CommandInterface to not handle requests to give commands
simulated final function Deactivate()
{
    Enabled = false;

    DefaultCommandControl.Hide();

    PostDeactivated();
}
//let subclasses react to this change of state
simulated protected function PostDeactivated();

//set the MenuPadStatus for the specified Command
simulated function SetCommandStatus(Command Command, optional bool TeamChanged)
{
    local MenuPadStatus Status;

    if (Command == None) return;

    if  (
            Command.IsCancel
        ||  Command.SubPage != Page_None                        //command is an achor for a sub-page
        ||  TeamCanExecuteCommand(Command, CurrentDoorFocus)
        )
        Status = Pad_Normal;
    else
        Status = Pad_GreyedOut;

    SetCommand(Command, Status);
}

//reset all commands to their pre-updated, ie. unavailable, state.
//this is called
//  a) before updating commands so that commands that shouldn't available
//  in the current context will not be presented to the user.
//  b) before changing pages
simulated function ClearCommands(bool PageChange);

//consider changing the current default command to the supplied command.
//the supplied command will be selected as the new default command if
//  it is higher priority than the current default command AND the currently
//  selected officer team can execute that command.
simulated final function ConsiderDefaultCommand(Command inDefaultCommand, byte inDefaultPriority)
{
    if (CurrentOverrideDefaultCommand != None)
        return; //the default command is overridden

    if  (
            inDefaultPriority > DefaultPriority     //this default's priority is higher than any current default command
        &&  TeamCanExecuteCommand(inDefaultCommand, CurrentDoorFocus)
        )
    {
        DefaultCommand = inDefaultCommand;
        DefaultPriority = inDefaultPriority;

        DefaultCommandControl.SetCaption( GetColorizedCommandText(DefaultCommand) );
    }
}

//set the command (and details thereof) that the player is "expected" to give.
//while an ExpectedCommand is in effect, if another command is given, then
//  will not be sent to the officers, and a 'MessageUnexpectedCommandGiven'
//  message will be sent.
//this is used by the scripting ActionSetExpectedCommand in Training.
function SetExpectedCommand(
    name inExpectedCommand,
    name inExpectedCommandTeam,
    name inExpectedCommandTargetDoor,
    name inExpectedCommandSource)
{
    local name PreviousExpectedCommand;
    local int i;

    PreviousExpectedCommand = ExpectedCommand;

    ExpectedCommand = inExpectedCommand;
    ExpectedCommandTeam = inExpectedCommandTeam;
    ExpectedCommandTargetDoor = inExpectedCommandTargetDoor;
    ExpectedCommandSource = inExpectedCommandSource;

    //if the ExpectedCommand or the PreviousExpectedCommand are bStatic,
    //  then reset them here (because static commands aren't otherwise updated).

    for (i=0; i<Commands.length; ++i)
        if  (
                Commands[i] != None
            &&  Commands[i].bStatic
            &&  (
                    Commands[i].Name == ExpectedCommand
                ||  Commands[i].Name == PreviousExpectedCommand
                )
            )
            SetCommandStatus(Commands[i]);

    DefaultCommandControl.SetCaption( GetColorizedCommandText(DefaultCommand) );
}

//returns the text of Command with colorization if indicated
//(colorization happens if the Command is the ExpectedCommand)
native final function string GetColorizedCommandText(Command Command);

//given that Command is the ExpectedCommand, returns the colorized
//  string for it, based on the ExpectedCommandTeam.
simulated final event string ColorizeExpectedCommand(Command Command)
{
    switch (ExpectedCommandTeam)
    {
    case 'Element':
        return "[c=FFC800][b]" $ Command.Text $ "[\\b][\\c]";
    case 'RedTeam':
        return "[c=800000][b]" $ Command.Text $ "[\\b][\\c]";
    case 'BlueTeam':
        return "[c=0000af][b]" $ Command.Text $ "[\\b][\\c]";
    default:
        return "[c=00af00][b]" $ Command.Text $ "[\\b][\\c]";
    }
}

simulated final function Command GetDefaultCommand()
{
    return DefaultCommand;
}

//subclasses implement this to update the visual representation of a command to match the command's new MenuPadStatus
simulated function SetCommand(Command Command, MenuPadStatus Status);

native final function bool TeamCanExecuteCommand(Command Command, optional SwatDoor Door);

//begin the process of giving the specified command.
//the specified command will be selected either from the ClassicCommandInterface,
//  GraphicCommandInterface, or from the DefaultCommand.
//this involves remembering the details of the command so that these details can
//  be used when the command is finished being spoken and is sent to the officers.
//this begins speaking the given command by either starting team speech or
//  command speech, depending on whether the team your talking to is the same
//  team as the last command given.
simulated function GiveCommand(Command Command)
{
    local SwatGamePlayerController Player;
    local ExternalViewportManager ExternalViewportManager;
    local IControllableThroughViewport Controllable;
    local Actor OriginActor;

    //handle cancel command
    if (Command.IsCancel)
    {
        CancelGivingCommand();
        return;
    }
    
    //handle submenu anchors
    if (Command.SubPage != Page_None)
    {
        SetCurrentPage(Command.SubPage);
        return;
    }

    //determine the source of the command
    Player = SwatGamePlayerController(Level.GetLocalPlayerController());

    //return early if the player is dead or has no pawn to issue commands from
    if( Player.Pawn == None || Player.Pawn.CheckDead( Player.Pawn ) )
    {
        return;
    }
    
    FlushPendingCommand();
    
    ExternalViewportManager = Player.GetExternalViewportManager();
    if (Player.ActiveViewport == ExternalViewportManager)
    {
        Controllable = ExternalViewportManager.GetCurrentControllable();
        OriginActor = Actor(Controllable);
        assert(Controllable != None);
        PendingCommandOrigin = ExternalViewportManager.GetCurrentControllable().GetViewportLocation();
    }
    else
    {
        OriginActor = Player.Pawn;
        PendingCommandOrigin = LastFocusUpdateOrigin;
    }

    PendingCommand = Command;
    PendingCommandTeam = CurrentCommandTeam;
    PendingCommandFoci = Foci;
    PendingCommandFociLength = FociLength;
    PendingCommandTargetCharacter = SwatAICharacter(GetFocusOfClass('SwatAICharacter'));
    
    log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds
        $", Player began to give "$Command.name
        $" through "$OriginActor.name
        $" from ("$PendingCommandOrigin
        $") to "$CurrentCommandTeam
        $".  Focus: "$GetPendingFocusString());

    if (Level.NetMode == NM_Standalone)
        GiveCommandSP();
    else
        GiveCommandMP();
}

function FlushPendingCommand(); //nothing to do in the global state, since any pending command has already completed

simulated function GiveCommandSP()
{
    switch (PendingCommand.EffectEvent)
    {
        case '':
            assertWithDescription(false,
                "[COMMAND INTERFACE SPEECH] The EffectEvent is missing for the given Command "$PendingCommand.name);
            break;

        default:
            if (CurrentCommandTeam == LastCommandTeam)
            {
                //TMC 6-7-2004 Fix 4202: When giving command, team name shouldn't be said every time
                //TMC 6-17-2004 Fix 4530: GCI stopped responding: moved into default case
                GotoState('SpeakingCommand');
                ExplicitBeginState();
            }
            else
                StartCommand();
    }
}

simulated function GiveCommandMP()
{
    local Actor PendingCommandTargetActor;
    local Vector PendingCommandTargetLocation;
    local eVoiceType VoiceType;
    local string SourceID, TargetID;

    PendingCommandTargetActor = GetPendingCommandTargetActor();
    //note that GetPendingCommandTargetActor() returns None if the PendingCommand
    //  isn't associated with any particular actor.
    if (PendingCommandTargetActor != None)
        PendingCommandTargetLocation = PendingCommandTargetActor.Location;
    else    //no target actor
        PendingCommandTargetLocation = GetLastFocusLocation();  //the point where the command interface focus trace was blocked
    
    if( NetPlayer(PlayerPawn) != None )
    {
        if( NetPlayer(PlayerPawn).IsTheVIP() )
            VoiceType = eVoiceType.VOICETYPE_VIP;
        else
            VoiceType = NetPlayer(PlayerPawn).VoiceType;
    }
    SourceID = PlayerPawn.UniqueID();
    if( PendingCommandTargetActor != None )
        TargetID = PendingCommandTargetActor.UniqueID();
    
    if( PlayerController.CanIssueCommand() )
    {
        PlayerController.StartIssueCommandTimer();
    
        //RPC the command to remote clients (will skip the local player)
        PlayerController.ServerGiveCommand(
            PendingCommand.Index,
            Command_MP(PendingCommand).IsTaunt,
            PlayerPawn,
            SourceID,
            PendingCommandTargetActor,
            TargetID,
            PendingCommandTargetLocation, 
            VoiceType );

        //instant feedback on client who gives the command (the local player)
        ReceiveCommandMP(
            PendingCommand.Index,
            PlayerPawn,
            SourceID,
            PlayerController.GetHumanReadableName(),
            PendingCommandTargetActor,
            TargetID,
            PendingCommandTargetLocation,
            VoiceType );
    }
}

simulated function ReceiveCommandMP(
        int CommandIndex,           //index into Commands array of the command that is being given
        Actor Source,               //the player giving the command
        string SourceID,            //unique ID of the source
        String SourceActorName,     //the human readable name of the player giving the command
        Actor TargetActor,          //the actor that the command refers to
        string TargetID,            //unique ID of the target
        Vector TargetLocation,      //the location that the command refers to.
        eVoiceType VoiceType)       //the voice to use when playing this command
{
    local Actor SourceOfSound;
    local Name VoiceTag;
    
    if( Source == None && SourceID != "" )
        Source = FindByUniqueID( None, SourceID );
        
    if( TargetActor == None && TargetID != "" )
        TargetActor = FindByUniqueID( None, TargetID );
    
    //Note!  This is a command received from (potentially) another client.
    //  The PendingCommand* variables can NOT be used here.

    log("TMC CommandInterface::ReceiveCommandMP() received the command "$Commands[CommandIndex].name
            $", Source="$Source
            $", TargetActor="$TargetActor
            $", TargetLocation="$TargetLocation
            $", VoiceType="$GetEnum(eVoiceType,VoiceType)
            $", Command_MP(Commands[CommandIndex]).ArrowLifetime = "$Command_MP(Commands[CommandIndex]).ArrowLifetime );

    //taunts are played on the speaker, others are played on the listener
    if (Command_MP(Commands[CommandIndex]).IsTaunt)
        SourceOfSound = Source;
    else
        SourceOfSound = PlayerPawn;

    //choose the voice type that should be used for the source of this command
    VoiceTag = SwatRepo(Level.GetRepo()).GuiConfig.GetTagForVoiceType( VoiceType );

    //set temporary effect contexts for target SwatPawns regarding gender and hostility
    if (TargetActor != None && TargetActor.IsA('SwatPawn'))
    {
        if (TargetActor.IsA('SwatAICharacter') && SwatAICharacter(TargetActor).IsFemale())
            AddContextForNextEffectEvent('Female');
        else
            AddContextForNextEffectEvent('Male');

        //for 'OrderedRestrain', players on other team are considered suspects, ie. use more agressive language, "Tie up that idiot"
        if (TargetActor.IsA('SwatHostage'))
            AddContextForNextEffectEvent('Civilian');
        else
            AddContextForNextEffectEvent('Suspect');
    }
    //note that if the TargetActor is None or not a SwatPawn, then no temporary contexts will be added
    
    //trigger the sound effect for the command given
    if( SourceOfSound != None )
        SourceOfSound.TriggerEffectEvent(Commands[CommandIndex].EffectEvent,,,,,,,,VoiceTag);

    //display the command given as a chat message
    PlayerController.ClientMessage(
        "[c=FFC800][b]"$SourceActorName $ GaveCommandString $ Commands[CommandIndex].Text,
        'CommandGiven');

    //Display the Command Arrow
    if( Source != None && Command_MP(Commands[CommandIndex]).ArrowLifetime > 0.0 )
    {
        Assert( Source.IsA('SwatPlayer') );
        SwatPlayer(Source).ShowCommandArrow( Command_MP(Commands[CommandIndex]).ArrowLifetime, Source, TargetActor, Source.Location, TargetLocation, ( Command_MP(Commands[CommandIndex]).IsTaunt || Command_MP(Commands[CommandIndex]).TargetIsSelf ) );
    }
    
    //PlayerController.myHUD.AddDebugBox(TargetLocation, 5, class'Engine.Canvas'.Static.MakeColor(255,200,200), 10);
    //PlayerController.myHUD.AddDebugLine(Source.Location, TargetLocation, class'Engine.Canvas'.Static.MakeColor(255,50,50), 10);
}

//called when the player selects one of the GCI's "Exit Menu" pads.
//implemented in the GCI subclass.
simulated function CancelGivingCommand();

//whenever GotoState('SpeakingCommand') is called, the caller should immediately call ExplicitBeginState().
//this would be just BeginState(), but it needs to happen even if the CommandInterface is already
//  in state 'SpeakingCommand'.
function ExplicitBeginState()
{
    assertWithDescription(false,
        "[tcohen] CommandInterface::ExplicitBeginState() was called in the Global state.  This should only (and always) be called immediately after calling GotoState('SpeakingCommand').");
}

//when giving a command to a team that is not the most recent team to receive a command,
//  select the appropriate speech for the new team, and begin speaking that.
//we trigger the "team" speech before going into state SpeakingTeam
//  because we may be cutting-off some already-playing speech.  If that's the case,
//  then we want to catch the OnEffectStopped() in the Global state.
function StartCommand()
{
    //in case we're playing something else, go back to the global state
    //  to prepare for commanding.
    GotoState('');

    if (PendingCommandTeam == Element)
        Level.GetLocalPlayerController().Pawn.TriggerEffectEvent(
            'OrderedElement', , , , , , , Self);  //pass Self as IEffectObserver
    else
    if (PendingCommandTeam == RedTeam)
        Level.GetLocalPlayerController().Pawn.TriggerEffectEvent(
            'OrderedRed', , , , , , , Self);  //pass Self as IEffectObserver
    else
    if (PendingCommandTeam == BlueTeam)
        Level.GetLocalPlayerController().Pawn.TriggerEffectEvent(
            'OrderedBlue', , , , , , , Self);  //pass Self as IEffectObserver
    else
        assertWithDescription(false,
            "[tcohen] CommandInterface::SpeakTeam() PendingCommandTeam isn't Red, Blue, or Element.");

    GotoState('SpeakingTeam');
}

state Speaking
{
    function FlushPendingCommand()
    {
        if (SometimesSendInterruptedCommand)
        {
            //Compare PendingCommandTeam with CurrentCommandTeam to determine
            //  if the interrupted command should be sent.
            //Our rule is this:
            //  If the player gives a command to team A but interrupts that command
            //      before it has completed with a command to team B,
            //  then the first command is sent to team A IF AND ONLY IF:
            //      A and B are different teams and B is not the Element.

            if  (
                    PendingCommandTeam != CurrentCommandTeam
                &&  CurrentCommandTeam != Element
                )
            {
                log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds
                    $", ...          the previous command was INTERRUPTED, and WILL be sent to the Officers. "
                    $"(SometimesSendInterruptedCommand=true, PendingCommandTeam="$PendingCommandTeam.class.name
                    $", CurrentCommandTeam="$CurrentCommandTeam.class.name$")");

                SendCommandToOfficers();
            }
            else
                log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds
                    $", ...          the previous command was INTERRUPTED, and will NOT be sent to the Officers. "
                    $"(SometimesSendInterruptedCommand=true, PendingCommandTeam="$PendingCommandTeam.class.name
                    $", CurrentCommandTeam="$CurrentCommandTeam.class.name$")");
        }
        else
            log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds
                $", ...          the previous command was INTERRUPTED, and will not be sent to the Officers. "
                $"(SometimesSendInterruptedCommand=false)");
    }
}

//wait for the team speech to finish
state SpeakingTeam extends Speaking
{
    // Called whenever an effect is started.
    function OnEffectStarted(Actor inStartedEffect) {}

    // Called whenever an effect is stopped.
    function OnEffectStopped(Actor inStoppedEffect, bool Completed)
    {
        if (SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState != GAMESTATE_MidGame)
        {
            GotoState('');
            return;
        }

        if (Completed)
        {
            LastCommandTeam = PendingCommandTeam;
            GotoState('SpeakingCommand');
            ExplicitBeginState();
        }
        else
            GotoState('');
    }
}

//play the speech for a given command and wait for it to finish.
//this also handles interrupting a previous command if another command is given before the first is finished being spoken.
state SpeakingCommand extends Speaking
{
    // called when an effect is initialized, which happens before it is started
    function OnEffectInitialized(Actor inInitializedEffect)
    {
        CommandSpeechInitialized = true;
    }

    // Called whenever an effect is started.
    function OnEffectStarted(Actor inStartedEffect) {}

    // Called whenever an effect is stopped.
    // the command speech has either completed, or it has been interrupted.
    function OnEffectStopped(Actor inStoppedEffect, bool Completed)
    {
        if (SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState != GAMESTATE_MidGame)
        {
            GotoState('');
            return;
        }

        if (Completed)
        {
            log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds$", "$PendingCommand.name$" completed.");
            SendCommandToOfficers();
        }
        //else, PendingCommand is probably a new command that was just started

        if (CommandSpeechInitialized)
            GotoState('');
        //otherwise, we're starting a command speech that has interrupted
        //  an already-playing command speech.
        //in that case, we want to remain in the SpeakingCommand state.
    }

    //this functions as a BeginState(), but is explicitly called so that it
    //  happens even if the CommandInterface is already in this state.
    function ExplicitBeginState()
    {
        local name EffectTag;

        if (PendingCommandTargetCharacter != None)
        {
            if (PendingCommandTargetCharacter.IsA('SwatEnemy'))
            {
                if (PendingCommandTargetCharacter.IsFemale())
                    EffectTag = 'FemaleSuspect';
                else
                    EffectTag = 'MaleSuspect';
            }
            else
            if (PendingCommandTargetCharacter.IsA('SwatHostage'))
            {
                if (PendingCommandTargetCharacter.IsFemale())
                    EffectTag = 'FemaleCivilian';
                else
                    EffectTag = 'MaleCivilian';
            }
        }

        //detect if the TriggerEffectEvent didn't result in any speech
        CommandSpeechInitialized = false;

        //instigate the command speech
        Level.GetLocalPlayerController().Pawn.TriggerEffectEvent(
            PendingCommand.EffectEvent, , , , , , , Self, EffectTag);  //pass Self as IEffectObserver
        //this should generate a callback to OnEffectInitialized(), where we set CommandSpeechInitialized=true

        if (!CommandSpeechInitialized)
        {
            //triggering the speech for the pending command didn't result in any sound starting.
            //this can happen if the player is shot while giving a command, causing the player to play a higher priority sound
            Warn("[tcohen] Tried to start the speech for the pending command "$PendingCommand.name
                $", but triggering the "$PendingCommand.EffectEvent
                $" did not result in any sound starting.");
            GotoState('');  //fail-safe (otherwise the CommandInterface would appear to be "hung")
        }
    }
}

simulated function bool IsExpectedCommandSource(name CommandSource)
{
    // RedTeam and BlueTeam are special aliases that match if the specific
    // team members were the source.
    if (ExpectedCommandSource == 'RedTeam')
    {
        return CommandSource == 'OfficerRedOne' || CommandSource == 'OfficerRedTwo';
    }
    if (ExpectedCommandSource == 'BlueTeam')
    {
        return CommandSource == 'OfficerBlueOne' || CommandSource == 'OfficerBlueTwo';
    }

    // Otherwise, fall back on an exact match
    return CommandSource == ExpectedCommandSource;
}

//send the pending command to the officers, now that any necessary speech has completed
simulated function SendCommandToOfficers()
{
    local Actor PendingCommandTargetActor;
    local name LastFocusSource;

    PendingCommandTargetActor = GetPendingCommandTargetActor();

    if (Level.GetLocalPlayerController().Pawn == None)
    {
        log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds
            $", ...          in SendCommandToOfficers(), Level.GetLocalPlayerController().Pawn is none");
        return;
    }

    LastFocusSource = SwatGamePlayerController(Level.GetLocalPlayerController()).GetLastFocusSource();

    //check the given command against any current expected command - for Training mission
    if  (
            (   //unexpected command
                ExpectedCommand != ''
            &&  PendingCommand.name != ExpectedCommand
            )
        ||  (   //unexpected command team
                ExpectedCommandTeam != ''
            &&  PendingCommandTeam.label != ExpectedCommandTeam
            )
        ||  (
                //unexpected command target door
                ExpectedCommandTargetDoor != ''
            &&  (
                    PendingCommandTargetActor == None
                ||  !PendingCommandTargetActor.IsA('SwatDoor')
                ||  PendingCommandTargetActor.label != ExpectedCommandTargetDoor
                )
            )
        ||  (   //unexpected command source
                ExpectedCommandSource != ''
            && !IsExpectedCommandSource(LastFocusSource)
            )
        )
    {
        dispatchMessage(new class'MessageUnexpectedCommandGiven'(
                    ExpectedCommand,
                    ExpectedCommandTeam,
                    ExpectedCommandTargetDoor,
                    ExpectedCommandSource,
                    PendingCommand.name,
                    PendingCommandTeam.name,
                    PendingCommandTargetActor.name,
                    LastFocusSource));

        log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds
            $", ...          sent MessageUnexpectedCommandGiven:"
            $"  ExpectedCommand="$ExpectedCommand$", PendingCommand.name="$PendingCommand.name$"."
            $"  ExpectedCommandTeam="$ExpectedCommandTeam$", PendingCommandTeam.name="$PendingCommandTeam.name$"."
            $"  PendingCommandTargetActor.class="$PendingCommandTargetActor.class.name
            $", PendingCommandTargetActor.name="$PendingCommandTargetActor.name$"."
            $". Focus: "$GetPendingFocusString());

        return;
    }
    
    //
    // "THE BIG ASS SWITCH"
    //
    // Call into the current AI OfficerTeamInfo and give it the command.
    //

    assertWithDescription(PendingCommand != None,
        "[tcohen] CommandInterface::SendCommandToOfficers() was called with PendingCommand=None");

    if (PendingCommandTargetActor != None)
        log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds
            $", ...          sending "$PendingCommand.name
            $" to "$PendingCommandTeam.class.name
            $". Focus: "$GetPendingFocusString()
            $"  PendingCommandTargetActor.class="$PendingCommandTargetActor.class.name
            $", PendingCommandTargetActor.name="$PendingCommandTargetActor.name$".");
    else
        log("[COMMAND INTERFACE] At Time "$Level.TimeSeconds
            $", ...          sending "$PendingCommand.name
            $" to "$PendingCommandTeam.class.name
            $". Focus: "$GetPendingFocusString()
            $"  PendingCommandTargetActor=None.");

    Switch (PendingCommand.Command)
    {
        case Command_FallIn:
            PendingCommandTeam.FallIn(
                Level.GetLocalPlayerController().Pawn,
                PendingCommandOrigin);
            break;

        case Command_MoveTo:
            PendingCommandTeam.MoveTo(
                Level.GetLocalPlayerController().Pawn,
                PendingCommandOrigin,
                GetLastFocusLocation());
            break;

        case Command_Cover:
            PendingCommandTeam.Cover(
                Level.GetLocalPlayerController().Pawn, 
                PendingCommandOrigin,
                GetLastFocusLocation());
            break;

        case Command_Deploy_Flashbang:
            PendingCommandTeam.DeployThrownItemAt(
                Level.GetLocalPlayerController().Pawn, 
                PendingCommandOrigin,
                Slot_Flashbang,
                GetLastFocusLocation(),
                SwatDoor(PendingCommandTargetActor));
            Back();
            break;

        case Command_Deploy_CSGas:
            PendingCommandTeam.DeployThrownItemAt(
                Level.GetLocalPlayerController().Pawn, 
                PendingCommandOrigin,
                Slot_CSGasGrenade,
                GetLastFocusLocation(),
                SwatDoor(PendingCommandTargetActor));
            Back();
            break;

        case Command_Deploy_StingGrenade:
            PendingCommandTeam.DeployThrownItemAt(
                Level.GetLocalPlayerController().Pawn, 
                PendingCommandOrigin,
                Slot_StingGrenade,
                GetLastFocusLocation(),
                SwatDoor(PendingCommandTargetActor));
            Back();
            break;

        case Command_Disable:
            if (PendingCommandTargetActor != None)
                PendingCommandTeam.DisableTarget(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                        PendingCommandTargetActor);
            break;

        case Command_RemoveWedge:
            PendingCommandTeam.RemoveWedge(
                Level.GetLocalPlayerController().Pawn, 
                PendingCommandOrigin,
                SwatDoor(PendingCommandTargetActor));
            break;

        case Command_SecureEvidence:
            if (PendingCommandTargetActor != None)
            PendingCommandTeam.SecureEvidence(
                Level.GetLocalPlayerController().Pawn, 
                PendingCommandOrigin,
                    PendingCommandTargetActor);
            break;

        case Command_MirrorCorner:
            if (PendingCommandTargetActor != None)
                PendingCommandTeam.MirrorCorner(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                        PendingCommandTargetActor);
            break;

        //Commands that require a valid Door

        case Command_StackUpAndTryDoor:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.StackUpAndTryDoorAt(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        case Command_PickLock:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.PickLock(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        case Command_MoveAndClear:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.MoveAndClear(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        //clear with nothing

        case Command_BreachAndClear:
        case Command_BreachAndMakeEntry:
        case Command_OpenAndClear:
        case Command_OpenAndMakeEntry:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.BreachAndClear(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        //clear with bang

        case Command_BangAndClear:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.BangAndClear(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        case Command_BreachBangAndClear:
        case Command_BreachBangAndMakeEntry:
        case Command_OpenBangAndClear:
        case Command_OpenBangAndMakeEntry:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.BreachBangAndClear(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        //clear with gas

        case Command_GasAndClear:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.GasAndClear(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        case Command_BreachGasAndClear:
        case Command_BreachGasAndMakeEntry:
        case Command_OpenGasAndClear:
        case Command_OpenGasAndMakeEntry:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.BreachGasAndClear(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        //clear with sting

        case Command_StingAndClear:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.StingAndClear(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        case Command_BreachStingAndClear:
        case Command_BreachStingAndMakeEntry:
        case Command_OpenStingAndClear:
        case Command_OpenStingAndMakeEntry:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.BreachStingAndClear(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        case Command_Deploy_C2Charge:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.DeployC2(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            Back();
            break;

        case Command_Deploy_BreachingShotgun:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.DeployShotgun(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            Back();
            break;

        case Command_Deploy_Wedge:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.DeployWedge(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            Back();
            break;

        case Command_CloseDoor:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.CloseDoor(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        case Command_MirrorRoom:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.MirrorRoom(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        case Command_MirrorUnderDoor:
            if (CheckForValidDoor(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.MirrorUnderDoor(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    SwatDoor(PendingCommandTargetActor));
            break;

        //Commands that require a valid Pawn

        case Command_Restrain:
            if (CheckForValidPawn(PendingCommand, PendingCommandTargetActor))
                PendingCommandTeam.Restrain(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    Pawn(PendingCommandTargetActor));
            break;

        case Command_Deploy_PepperSpray:
            if (CheckForValidPawn(PendingCommand, PendingCommandTargetActor))
            {
                PendingCommandTeam.DeployPepperSpray(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    Pawn(PendingCommandTargetActor));
                Back();
            }
            break;

        case Command_Deploy_Taser:
            if (CheckForValidPawn(PendingCommand, PendingCommandTargetActor))
            {
                PendingCommandTeam.DeployTaser(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    Pawn(PendingCommandTargetActor));
                Back();
            }
            break;

        case Command_Deploy_LessLethalShotgun:
            if (CheckForValidPawn(PendingCommand, PendingCommandTargetActor))
            {
                PendingCommandTeam.DeployLessLethalShotgun(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    Pawn(PendingCommandTargetActor));
                Back();
            }
            break;

        case Command_Deploy_CSBallLauncher:
            if (CheckForValidPawn(PendingCommand, PendingCommandTargetActor))
            {
                PendingCommandTeam.DeployPepperBallGun(
                    Level.GetLocalPlayerController().Pawn, 
                    PendingCommandOrigin,
                    Pawn(PendingCommandTargetActor));
                Back();
            }
            break;

        default:
            assertWithDescription(false,
                "[tcohen] CommandInterface::SendCommandToOfficers() Unexpected command "$GetEnum(ECommand,PendingCommand.Command));
            return;
    }

    if  (
            PendingCommandTargetActor != None
        &&  PendingCommandTargetActor.IsA('SwatDoor')
        )
        dispatchMessage(new class'MessageCommandGiven'(PendingCommand.name, PendingCommandTeam.label, PendingCommandTargetActor.label));
    else
        dispatchMessage(new class'MessageCommandGiven'(PendingCommand.name, PendingCommandTeam.label, ''));

    return;
}

//Returns the Actor to which the PendingCommand refers
//  ONLY IF the PendingCommand is associated with a target actor!
//If the PendingCommand isn't associated with any particular Actor,
//  then GetPendingCommandTargetActor() returns None.
simulated private function Actor GetPendingCommandTargetActor()
{
    local Actor TemporaryActor;

    Switch (PendingCommand.Command)
    {
        //
        // Door-related commands
        //

        //cases where we prefer a closed door
        case Command_StackUpAndTryDoor:
        case Command_PickLock:
        case Command_BreachAndClear:
        case Command_BreachAndMakeEntry:
        case Command_OpenAndClear:
        case Command_OpenAndMakeEntry:
        case Command_BangAndClear:
        case Command_BreachBangAndClear:
        case Command_BreachBangAndMakeEntry:
        case Command_OpenBangAndClear:
        case Command_OpenBangAndMakeEntry:
        case Command_BreachGasAndClear:
        case Command_BreachGasAndMakeEntry:
        case Command_OpenGasAndClear:
        case Command_OpenGasAndMakeEntry:
        case Command_BreachStingAndClear:
        case Command_BreachStingAndMakeEntry:
        case Command_OpenStingAndClear:
        case Command_OpenStingAndMakeEntry:
        case Command_Deploy_C2Charge:
        case Command_Deploy_BreachingShotgun:
        case Command_Deploy_Wedge:
        case Command_MirrorUnderDoor:
            return GetDoorFocus();

        //cases where we prefer an open door
        case Command_MoveAndClear:
        case Command_GasAndClear:
        case Command_StingAndClear:
        case Command_MirrorRoom:
        case Command_Deploy_Flashbang:
        case Command_Deploy_CSGas:
        case Command_Deploy_StingGrenade:
            return GetDoorFocus(true);          //prefer open door

        case Command_CloseDoor:
            return GetDoorFocus(true, true);    //prefer farthest open door

        //
        // Pawn-related commands (or _potentially_ pawn-related)
        //

        case Command_Restrain:
        case Command_Deploy_PepperSpray:
        case Command_Deploy_Taser:
        case Command_Deploy_LessLethalShotgun:
        case Command_Deploy_CSBallLauncher:
            return GetPendingFocusOfClass('Pawn');

        //
        // Commands with other misc. target classes
        //

        case Command_Disable:
            return GetPendingFocusOfClass('ICanBeDisabled');

        case Command_RemoveWedge:
            //a player can remove a wedge by pointing at the wedge or at the door its deployed on
            TemporaryActor = GetDoorFocus();
            if (TemporaryActor != None)
                return TemporaryActor;
            else
            {
                TemporaryActor = GetPendingFocusOfClass('DeployedWedge');
                assertWithDescription(TemporaryActor != None,
                    "[tcohen] CommandInterface::GetPendingCommandTargetActor() Gave Command_RemoveWedge,"
                    $" but GetDoorFocus()=None,"
                    $" and GetPendingFocusOfClass('DeployedWedge') is also None.  What're we removing?");

                TemporaryActor = DeployedWedgeBase(TemporaryActor).GetDoorDeployedOn();

                assertWithDescription(TemporaryActor.IsA('SwatDoor'),
                    "[tcohen] CommandInterface::GetPendingCommandTargetActor() Gave Command_RemoveWedge,"
                    $" and DeployedWedge="$TemporaryActor
                    $", but DeployedWedge.GetDoorDeployedOn() returned None.  What Door is it deployed on?");

                return TemporaryActor;
            }
            
            //shouldn't get here... the above if() should return in either case
            assert(false);

        case Command_SecureEvidence:
            return GetPendingFocusOfClass('IEvidence');

        case Command_MirrorCorner:
            return GetPendingFocusOfClass('MirrorPoint');

        default:
            return None;
    }
}

simulated function GiveDefaultCommand()
{
    if (DefaultCommandEnabled)
        GiveCommand(DefaultCommand);
}

//
// These are utility functions that are used by SendCommandToOfficers() to
//  validate conditions for the pending command, and determine
//  which objects need to be communicated to the OfficerTeamInfo.
//

//check that Door is a valid door as required to give the command Command
simulated function bool CheckForValidDoor(Command Command, Actor Door)
{
    local bool ValidDoor;

    ValidDoor = (Door != None && Door.IsA('Door'));
    assertWithDescription(ValidDoor,
        "[tcohen] CommandInterface::CheckForValidDoor() Gave "$GetEnum(ECommand, Command.Command)
        $" which requires a valid Door, but Door="$Door);

    return ValidDoor;
}

//check that Pawn is a valid pawn as required to give the command Command
simulated function bool CheckForValidPawn(Command Command, Actor Pawn)
{
    local bool ValidPawn;

    ValidPawn = (Pawn != None && Pawn.IsA('Pawn'));
    assertWithDescription(ValidPawn,
        "[tcohen] CommandInterface::CheckForValidPawn() Gave "$GetEnum(ECommand, Command.Command)
        $" which requires a valid Pawn, but Pawn="$Pawn);

    return ValidPawn;
}

//returns the first Actor (if any) in the list of PendingCommandFoci that is an instance of ClassName
simulated protected function Actor GetPendingFocusOfClass(name ClassName)
{
    local int i;

    for (i=0; i<PendingCommandFociLength; ++i)
        if (PendingCommandFoci[i].Actor != None && PendingCommandFoci[i].Actor.IsA(ClassName))
            return PendingCommandFoci[i].Actor;

    return None;
}

//returns the first Actor (if any) in the list of PendingCommandFoci that is Examinable
simulated function Actor GetExaminableFocus()
{
    local int i;

    for (i=0; i<PendingCommandFociLength; ++i)
        if (PendingCommandFoci[i].Actor.Examinable)
            return PendingCommandFoci[i].Actor;

    return None;
}

//returns the first Actor (if any) in the list of PendingCommandFoci that can be used
simulated function Actor GetUsableFocus()
{
    local int i;

    for (i=0; i<PendingCommandFociLength; ++i)
        if (PendingCommandFoci[i].Actor.CanBeUsed())
            return PendingCommandFoci[i].Actor;

    return None;
}

//returns a SwatDoor in the list of PendingCommandFoci.
//by default, if there is more than one SwatDoor in PendingCommandFoci,
//  then GetDoorFocus() will returh the closest door, and the one that is closed.
//you can change the way GetDoorFocus selects from multiple SwatDoors by specifying
//  PreferOpenDoor or PreferFarthestDoor.
simulated function SwatDoor GetDoorFocus(optional bool PreferOpenDoor, optional bool PreferFarthestDoor)
{
    local SwatDoor SwatDoor;
    local SwatDoor Result;
    local int i;

    if (!PreferFarthestDoor)
    {
        //enumerate PendingCommandFoci forward

        for (i=0; i<PendingCommandFociLength; ++i)
        {
            SwatDoor = SwatDoor(PendingCommandFoci[i].Actor);

            if (SwatDoor == None)
                continue;

            Result = SwatDoor;

            if (SwatDoor.IsOpen() == PreferOpenDoor)
                break;
        }
    }
    else
    {
        //enumerate PendingCommandFoci backward

        for (i = PendingCommandFociLength - 1; i >= 0; --i)
        {
            SwatDoor = SwatDoor(PendingCommandFoci[i].Actor);

            if (SwatDoor == None)
                continue;

            Result = SwatDoor;

            if (SwatDoor.IsOpen() == PreferOpenDoor)
                break;
        }
    }

    return Result;
}

//returns the location of the last actor in the list of PendingCommandFoci
simulated function vector GetLastFocusLocation()
{
    local Color Color;

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games 
    if (DebugTerminalLocation)
    {
        Color.R = 255;
        Level.GetLocalPlayerController().myHUD.AddDebugBox(
            PendingCommandFoci[FociLength-1].Location,  //center
            5,                                          //size
            Color,                                      //color
            3);                                         //lifespan
    }
#endif
    return (PendingCommandFoci[PendingCommandFociLength-1].Location);
}

//not currently supported
//ISpeechClient implementation
//called by the speech recognition system when a speech command is recognized
simulated function OnSpeechCommandRecognized(name Rule, name Value, SpeechRecognitionConfidence Confidence)
{
    switch (Rule)
    {
        case 'Team':
            switch (Value)
            {
                case 'RedTeam':
                    SetCurrentTeam(RedTeam);
                    break;
                case 'BlueTeam':
                    SetCurrentTeam(BlueTeam);
                    break;
                case 'Element':
                    SetCurrentTeam(Element);
                    break;
                default:
                    assert(false);  //unexpected team
            }
            break;

        case 'Command':
//TMC TODO 2/1/2004 now that commands are objects per enum value, need to find a different way to identify command spoken...
//  probably associate an integer in the grammar
//            GiveCommand(Value);
            break;

        default:
            assert(false);          //unexpected rule
    }
}

// IEffectObserver implementation

// we don't care about getting IEffectObserver callbacks in the Global state

// Called whenever an effect is started.
function OnEffectStarted(Actor inStartedEffect);

// Called whenever an effect is stopped.
function OnEffectStopped(Actor inStoppedEffect, bool Completed);

function OnEffectInitialized(Actor inInitializedEffect);

//debugging

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games 
simulated function TestDoorBlocking(Pawn Pawn, int Times)
{
    SwatDoor(GetFocusOfClass('SwatDoor')).TestBlocking(Pawn, Times);
}
#endif

//returns a string representing the current list of PendingCommandFociLength
simulated function string GetPendingFocusString()
{
    local int i;
    local string Result;
    
    for (i=0; i<PendingCommandFociLength; ++i)
    {
        Result = Result
            $"("
            $"Context="$PendingCommandFoci[i].Context
            $", Actor="$PendingCommandFoci[i].Actor.name
            $", Location="$PendingCommandFoci[i].Location
            $", Region="$GetEnum(ESkeletalRegion, PendingCommandFoci[i].Region)
            $") ";
    }

    return Result;
}

simulated event Destroyed()
{
    if( Level.NetMode == NM_Standalone )
        SwatGameInfo(Level.Game).GameEvents.GameStarted.UnRegister(Self);
    
    Super.Destroyed();
}

cpptext
{
    virtual UBOOL DoorRelatedContextMatches(UPlayerInterfaceDoorRelatedContext* DoorRelatedContext, ASwatDoor* Door);
    virtual UBOOL ContextMatches(UPlayerInterfaceContext* inContext, AActor* Candidate);
    FString GetColorizedCommandText(UCommand* Command);
}

defaultproperties
{
    Enabled=true
    DefaultCommandEnabled=true

    AlwaysAddDoor=true
    GaveCommandString=": "
}
