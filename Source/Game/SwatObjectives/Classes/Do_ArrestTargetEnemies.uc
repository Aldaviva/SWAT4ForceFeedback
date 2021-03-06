class Do_ArrestTargetEnemies extends SwatGame.Objective_Do
    implements  IInterested_GameEvent_GameStarted, 
                IInterested_GameEvent_PawnDied, 
                IInterested_GameEvent_PawnIncapacitated, 
                IInterested_GameEvent_PawnArrested;

var config name SpawnerGroup;

var array<SwatEnemy> Targets;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.GameStarted.Register(self);
    Game.GameEvents.PawnDied.Register(self);
    Game.GameEvents.PawnIncapacitated.Register(self);
    Game.GameEvents.PawnArrested.Register(self);

    //add our SpawnerGroup to the Game's list of MissionObjectiveSpawnerGroups.
    SwatRepo(Game.Level.GetRepo()).MissionObjectives.AddMissionObjectiveSpawnerGroup(self, SpawnerGroup);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.GameStarted.UnRegister(self);
    Game.GameEvents.PawnDied.UnRegister(self);
    Game.GameEvents.PawnIncapacitated.UnRegister(self);
    Game.GameEvents.PawnArrested.UnRegister(self);
}

//IInterested_GameEvent_GameStarted Implementation
function OnGameStarted()
{
    local SwatEnemy Current;

    foreach Game.DynamicActors(class'SwatEnemy', Current)
    {
        if (Current.GetSpawner().SpawnedFromGroup() == SpawnerGroup)
        {
            if (Game.DebugObjectives)
                log("[OBJECTIVES] The "$class.name$" Objective named "$name
                    $" is adding "$Current.name
                    $" from SpawnerGroup "$SpawnerGroup
                    $" to its list of Targets.");
                
            Targets[Targets.length] = Current;
        }
    }

    assertWithDescription(Targets.length > 0,
            "[tcohen] The "$class.name
            $" named "$name
            $" can't be completed because it doesn't have any Targets.  Check that the SpawnerGroup specified in the Objective ("$SpawnerGroup
            $") matches a SpawnerGroup specified in the SpawningManager's Roster.");
}

//IInterested_GameEvent_PawnDied Implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return;   //we don't care
    if (ICanBeSpawned(Pawn).GetSpawner().SpawnedFromGroup() != SpawnerGroup)
        return;     //it wasn't spawned from the SpawnerGroup that interests us

    RemoveTarget(Pawn, 'PawnDied');
    SetStatus(ObjectiveStatus_Failed);
}

//IInterested_GameEvent_PawnIncapacitated Implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return;   //we don't care

    if (RemoveTarget(Pawn, 'PawnIncapacitated'))
        SetStatus(ObjectiveStatus_Completed);
}

//IInterested_GameEvent_PawnArrested Implementation
function OnPawnArrested( Pawn Pawn, Pawn Arrester )
{
    if (!Pawn.IsA('SwatEnemy')) return;   //we don't care

    if (RemoveTarget(Pawn, 'PawnArrested'))
        SetStatus(ObjectiveStatus_Completed);
}

//returns true if the last Target was removed
private function bool RemoveTarget(Pawn Pawn, name DebugWhy)
{
    local int i;

    for (i=0; i<Targets.length; ++i)
    {
        if (Targets[i] == Pawn)
        {
            //that's our guy... remove him from our list of active targets
            if (Game.DebugObjectives)
                log("[OBJECTIVES] The "$class.name
                    $" Objective named "$name
                    $" is removing "$Targets[i].name
                    $" from its list of Targets because "$DebugWhy
                    $".  Number of remaining Targets: "$Targets.length-1);
            Targets.Remove(i, 1);

            return (Targets.length == 0);
        }
    }

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" was called to RemoveTarget("$Pawn.name
            $") because "$DebugWhy
            $", but "$Pawn.Name
            $" is not in its list of Targets.");

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" was called to RemoveTarget("$Pawn.name
            $") because "$DebugWhy
            $", but "$Pawn.Name
            $" is not in its list of Targets.");
}
