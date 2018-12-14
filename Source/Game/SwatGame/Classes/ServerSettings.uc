class ServerSettings extends Engine.ReplicationInfo
    config(SwatGuiState);

import enum EEntryType from SwatStartPointBase;
import enum EMPMode from Engine.Repo;

const MAX_MAPS = 40;
var(ServerSettings) config String         Maps[MAX_MAPS];
var(ServerSettings) config int            NumMaps;

var(ServerSettings) config EMPMode        GameType "What game type the server is running";
var(ServerSettings) config int            MapIndex "What map is currently being used";
var(ServerSettings) config int            NumRounds "How many rounds to play per map";
var(ServerSettings) config int            MaxPlayers "Maximum number of players allowed on this server";
var(ServerSettings) config int            RoundNumber "What is the current round number";
var(ServerSettings) config int            DeathLimit "How many deaths are required to lose a round (0 = No Death Limit)";
var(ServerSettings) config int            PostGameTimeLimit "Time between the end of the round and server loading the next level";
var(ServerSettings) config int            RoundTimeLimit "Time limit for each round (in seconds) (0 = No Time Limit)";
var(ServerSettings) config int            MPMissionReadyTime "Time (in seconds) for players to ready themselves in between rounds in a MP game";
var(ServerSettings) config bool           bShowTeammateNames "If true, will display teammates names";
var(ServerSettings) config bool           bShowEnemyNames "If true, will display enemy names";
var(ServerSettings) config bool           bNoRespawn "If true, the server will not respawn players";
var(ServerSettings) config bool           bQuickRoundReset "If true, the server will perform a quick reset in between rounds on the same map; if false, the server will do a full SwitchLevel between rounds";
var(ServerSettings) config float          FriendlyFireAmount "The damage modifier for friendly fire [0...1]";
var(ServerSettings) config float          EnemyFireAmount "The damage modifier for enemy fire [0...1]";
var(ServerSettings) config EEntryType     DesiredMPEntryPoint "Desired entry point for MP-coop games";

var(ServerSettings) localized config String         ServerName "Name of the server for display purposes";
var                 config String         Password "Password for the server for authenticating users";
var(ServerSettings) config bool           bPassworded "If true, the server is passworded";
var(ServerSettings) config bool           bLAN "If true, the server is hosted only over the LAN (not internet)";


var(ServerSettings)        bool           bDirty;

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

replication
{
	reliable if ( bNetDirty && (Role == ROLE_Authority) )
		GameType, Maps, NumMaps, MapIndex, NumRounds,
        MaxPlayers, RoundNumber, DeathLimit, PostGameTimeLimit,
        RoundTimeLimit, MPMissionReadyTime, bShowTeammateNames, bShowEnemyNames, bNoRespawn, 
        bQuickRoundReset, FriendlyFireAmount, EnemyFireAmount, DesiredMPEntryPoint,
        ServerName, Password, bPassworded, bLAN;
}

///////////////////////////////////////////////////////////////////////////////
// Initialize the Server settings - load the map list for the game type
///////////////////////////////////////////////////////////////////////////////

function PreBeginPlay()
{
    Super.PreBeginPlay();
    
    LoadMapListForGameType();
}

///////////////////////////////////////////////////////////////////////////////
// Set the ServerSettings on the server
///////////////////////////////////////////////////////////////////////////////

function SetAdminServerSettings( PlayerController PC, 
                            String newServerName, 
                            String newPassword, 
                            bool newbPassworded, 
                            bool newbLAN )
{
log( self$"::SetAdminServerSettings( "$PC$", ServerName="$newServerName$", Password="$newPassword$", bPassworded="$newbPassworded$", bLAN="$newbLAN$" )" );
    if( Level.Game.IsA( 'SwatGameInfo' ) && !SwatGameInfo(Level.Game).Admin.IsAdmin( PC ) )
        return;
        
    ServerName = newServerName;
    Password = newPassword;
    bPassworded = newbPassworded;
    bLAN = newbLAN;
}

function SetServerSettings( PlayerController PC, 
                            EMPMode newGameType, 
                            int newMapIndex, 
                            int newNumRounds, 
                            int newMaxPlayers, 
                            int newDeathLimit,
                            int newPostGameTimeLimit, 
                            int newRoundTimeLimit, 
                            int newMPMissionReadyTime, 
                            bool newbShowTeammateNames, 
                            bool newbShowEnemyNames, 
                            bool newbNoRespawn, 
                            bool newbQuickRoundReset, 
                            float newFriendlyFireAmount, 
                            float newEnemyFireAmount, 
                            EEntryType newDesiredMPEntryPoint )
{
log( self$"::SetServerSettings( "$PC$", newGameType="$GetEnum(EMPMode,newGameType)$", newMapIndex="$newMapIndex$", newNumRounds="$newNumRounds$", newMaxPlayers="$newMaxPlayers$", newDeathLimit="$newDeathLimit$", newPostGameTimeLimit="$newPostGameTimeLimit$", newRoundTimeLimit="$newRoundTimeLimit$", newMPMissionReadyTime="$newMPMissionReadyTime$", newbShowTeammateNames="$newbShowTeammateNames$", newbShowEnemyNames="$newbShowEnemyNames$", newbNoRespawn="$newbNoRespawn$", newbQuickRoundReset="$newbQuickRoundReset$", newFriendlyFireAmount="$newFriendlyFireAmount$", newEnemyFireAmount="$newEnemyFireAmount$", newDesiredMPEntryPoint="$GetEnum(EEntryType,newDesiredMPEntryPoint)$" )" );
    if( Level.Game.IsA( 'SwatGameInfo' ) && !SwatGameInfo(Level.Game).Admin.IsAdmin( PC ) )
        return;
        
    GameType = newGameType;
    MapIndex = newMapIndex;
    NumRounds = newNumRounds;
    MaxPlayers = newMaxPlayers;
    DeathLimit = newDeathLimit;
    PostGameTimeLimit = newPostGameTimeLimit;
    RoundTimeLimit = newRoundTimeLimit;
    MPMissionReadyTime = newMPMissionReadyTime;
    bShowTeammateNames = newbShowTeammateNames;
    bShowEnemyNames = newbShowEnemyNames;
    bNoRespawn = newbNoRespawn;
    bQuickRoundReset = newbQuickRoundReset;
    FriendlyFireAmount = newFriendlyFireAmount;
    EnemyFireAmount = newEnemyFireAmount;
    DesiredMPEntryPoint = newDesiredMPEntryPoint;
    
    RoundNumber=0;
    
log( self$"::SetServerSettings(...) ... saving config" );
    SaveMapListForGameType();
    SaveConfig();
    
    
    // notify clients the settings were updated by the admin
    SwatGameInfo(Level.Game).OnServerSettingsUpdated( PC );
}

///////////////////////////////////////////////////////////////////////////////
// Set a map at a specific index on the server
///////////////////////////////////////////////////////////////////////////////

function AddMap( PlayerController PC, string MapName )
{
    if( Level.Game.IsA( 'SwatGameInfo' ) && !SwatGameInfo(Level.Game).Admin.IsAdmin( PC ) )
        return;

    if( NumMaps >= MAX_MAPS )
        return;
        
    Maps[NumMaps] = MapName;
    
    NumMaps++;
}

function ClearMaps( PlayerController PC )
{
    local int i;
    
    if( Level.Game.IsA( 'SwatGameInfo' ) && !SwatGameInfo(Level.Game).Admin.IsAdmin( PC ) )
        return;

    for( i = 0; i < MAX_MAPS; i++ )
    {
        Maps[i] = "";
    }

    NumMaps=0;
}

///////////////////////////////////////////////////////////////////////////////
// Set the settings to bDirty - basically ensures a fresh reset for next round
///////////////////////////////////////////////////////////////////////////////

function SetDirty( PlayerController PC )
{
    if( Level.Game.IsA( 'SwatGameInfo' ) && !SwatGameInfo(Level.Game).Admin.IsAdmin( PC ) )
        return;

    bDirty = true;
}

///////////////////////////////////////////////////////////////////////////////
// Save/Load Maplist utilities
///////////////////////////////////////////////////////////////////////////////

private function SaveMapListForGameType()
{
    local MapRotation MapRotation;
    local int i;
    
    MapRotation = SwatRepo(Level.GetRepo()).GuiConfig.MapList[GameType];
    
    for( i = 0; i < MAX_MAPS; i++ )
    {
        MapRotation.Maps[i] = Maps[i];
    }
    
    MapRotation.SaveConfig();
}

private function LoadMapListForGameType()
{
    local MapRotation MapRotation;
    local int i;
    
    MapRotation = SwatRepo(Level.GetRepo()).GuiConfig.MapList[GameType];
    
    for( i = 0; i < MAX_MAPS; i++ )
    {
        Maps[i] = MapRotation.Maps[i];
    }
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
    EnemyFireAmount=1.0
    bShouldReplicateDefaultProperties=true
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
