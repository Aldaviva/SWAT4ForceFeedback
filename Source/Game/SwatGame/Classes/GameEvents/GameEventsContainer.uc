class GameEventsContainer extends Core.Object;

// This class is used by SwatGameInfo to simply contain an instance of each
// GameEvent. It exists just to simplify SwatGameInfo's list of member
// variables.

var GameEvent_BombDisabled              BombDisabled;
var GameEvent_GameStarted               GameStarted;
var GameEvent_MissionStarted            MissionStarted;
var GameEvent_PostGameStarted           PostGameStarted;
var GameEvent_InanimateDisabled         InanimateDisabled;
var GameEvent_EvidenceSecured           EvidenceSecured;
var GameEvent_MissionCompleted          MissionCompleted;
var GameEvent_MissionEnded              MissionEnded;
var GameEvent_MissionFailed             MissionFailed;
var GameEvent_PawnArrested              PawnArrested;
var GameEvent_PawnDamaged               PawnDamaged;
var GameEvent_PawnDestroyed             PawnDestroyed;
var GameEvent_PawnDied                  PawnDied;
var GameEvent_ReportableReportedToTOC   ReportableReportedToTOC;
var GameEvent_PawnIncapacitated         PawnIncapacitated;
var GameEvent_PawnUnarrestBegan         PawnUnarrestBegan;
var GameEvent_PawnUnarrested            PawnUnarrested;
var GameEvent_PlayerDied                PlayerDied;
var GameEvent_Special                   Special;
var GameEvent_VIPReachedGoal            VIPReachedGoal;
var GameEvent_EnemyFiredWeapon          EnemyFiredWeapon;
var GameEvent_GrenadeDetonated          GrenadeDetonated;

overloaded function Construct()
{
    BombDisabled                = new(none) class'GameEvent_BombDisabled';
    GameStarted                 = new(none) class'GameEvent_GameStarted';
    MissionStarted              = new(none) class'GameEvent_MissionStarted';
    PostGameStarted             = new(none) class'GameEvent_PostGameStarted';
    InanimateDisabled           = new(none) class'GameEvent_InanimateDisabled';
    EvidenceSecured             = new(none) class'GameEvent_EvidenceSecured';
    MissionCompleted            = new(none) class'GameEvent_MissionCompleted';
    MissionEnded                = new(none) class'GameEvent_MissionEnded';
    MissionFailed               = new(none) class'GameEvent_MissionFailed';
    PawnArrested                = new(none) class'GameEvent_PawnArrested';
    PawnDamaged                 = new(none) class'GameEvent_PawnDamaged';
    PawnDestroyed               = new(none) class'GameEvent_PawnDestroyed';
    PawnDied                    = new(none) class'GameEvent_PawnDied';
    ReportableReportedToTOC     = new(none) class'GameEvent_ReportableReportedToTOC';
    PawnIncapacitated           = new(none) class'GameEvent_PawnIncapacitated';
    PawnUnarrestBegan           = new(none) class'GameEvent_PawnUnarrestBegan';
    PawnUnarrested              = new(none) class'GameEvent_PawnUnarrested';
    PlayerDied                  = new(none) class'GameEvent_PlayerDied';
    Special                     = new(none) class'GameEvent_Special';
    VIPReachedGoal              = new(none) class'GameEvent_VIPReachedGoal';
    EnemyFiredWeapon            = new(none) class'GameEvent_EnemyFiredWeapon';
    GrenadeDetonated            = new(none) class'GameEvent_GrenadeDetonated';
}
