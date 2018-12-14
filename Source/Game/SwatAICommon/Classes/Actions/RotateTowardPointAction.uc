///////////////////////////////////////////////////////////////////////////////
// RotateTowardPointAction.uc - RotateTowardPointAction class
// Action class that causes AI to turn towards a point in worldspace

class RotateTowardPointAction extends SwatMovementAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) vector   PointToRotateToward;

///////////////////////////////////////////////////////////////////////////////
//
// State code

state Running
{
Begin:
    assert(achievingGoal.IsA('RotateTowardPointGoal'));

    RotateTowardPoint(PointToRotateToward);

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'RotateTowardPointGoal'
}