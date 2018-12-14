class ThrownWeapon extends Weapon
    abstract;


var private float ThrowSpeed;                   //set this with SetThrowSpeed() before calling Use()

var config class<SwatGrenadeProjectile> ProjectileClass;

var config name FirstPersonPreThrowAnimation;   //the animation that the ThrownWeapon's first-person model should play before thrown, ie. pin-being-pulled

//clients interested when a grenade is thrown or detonates
var array<IInterestedGrenadeThrowing> InterestedGrenadeRegistrants;

function PostBeginPlay()
{
    Super.PostBeginPlay();

    assert(ProjectileClass != None);    //should be set in ThrownWeapon subclass
}

simulated function OnPlayerUse()
{
    Level.GetLocalPlayerController().Throw();
}

function SetThrowSpeed(float inThrowSpeed)
{
    ThrowSpeed = inThrowSpeed;
}

//called from HandheldEquipment::DoUsing()
simulated latent protected function DoUsingHook()
{
    local Hands Hands;
    local Pawn PawnOwner;
    local int PawnThrowAnimationChannel;

    //Play, then finish, animations on pawn, hands, and the models they hold.
    //We need to play both first, then finish both, since finishing happens latently,
    //  and we want them to play simultaneously.

    //pick long-throw/short-throw animations
    
    PawnOwner = Pawn(Owner);
    Hands = PawnOwner.GetHands();

    //
    // Play
    //

        // Pawn
        PawnThrowAnimationChannel = PawnOwner.AnimPlayEquipment(
			kAPT_Normal,
            ICanThrowWeapons(PawnOwner).GetThrowAnimation(ThrowSpeed), 
            ICanThrowWeapons(PawnOwner).GetPawnThrowTweenTime(), 
			ICanThrowWeapons(PawnOwner).GetPawnThrowRootBone());

        // Hands
        if (Hands != None)
            Hands.PlayAnim(Hands.GetThrowAnimation(ThrowSpeed));

    //
    // Finish
    //

        // Pawn
        Pawn(Owner).FinishAnim(PawnThrowAnimationChannel);

        // Hands
        if (Hands != None)
        {
            Hands.FinishAnim();
        }
}

//called from HandheldEquipment::OnUseKeyFrame()
simulated function UsedHook()
{
    local ICanThrowWeapons Holder;
    local vector InitialLocation;
    local rotator ThrownDirection;

    if ( IsAvailable() && Level.NetMode != NM_Client )
    {
        Holder = ICanThrowWeapons(Owner);
        assertWithDescription(Holder != None,
                              "[tcohen] "$class.name$" was notified OnThrown(), but its Owner ("$Owner
                              $") cannot throw weapons.");
        
        Holder.GetThrownProjectileParams(InitialLocation, ThrownDirection);
        
        SpawnProjectile(InitialLocation, vector(ThrownDirection) * ThrowSpeed);
    }
}

function SwatGrenadeProjectile SpawnProjectile(vector inLocation, vector inVelocity)
{
    local SwatGrenadeProjectile Projectile;
    
    Projectile = Owner.Spawn(
            ProjectileClass,
            Owner,
            ,                   //tag: default
            inLocation,
            ,                   //SpawnRotation: default
            true);              //bNoCollisionFail
    assertWithDescription(Projectile != None,
        "[tcohen] The thrown "$class.name
        $" failed to spawn its projectile of class "$ProjectileClass
        $".  Make sure that the specified ProjectileClass is a subclass of SwatGrenadeProjectile, and Check the log for spawning errors.");

    Projectile.Velocity = inVelocity;

    Projectile.TriggerEffectEvent('Thrown');

	RegisterInterestedGrenadeRegistrantWithProjectile(Projectile);

    return Projectile;
}

event Destroyed()
{
    Super.Destroyed();

    //destroy my models
    if (FirstPersonModel != None)
        FirstPersonModel.Destroy();
    if (ThirdPersonModel != None)
        ThirdPersonModel.Destroy();
}

//
// Registering for Grenade Detonation
//

// Register the clients interested in grenade detonation, that are already registered with the weapon, 
// on the newly spawned projectile
function RegisterInterestedGrenadeRegistrantWithProjectile(SwatGrenadeProjectile Projectile)
{
	local int i;
	assert(Projectile != None);

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		Projectile.RegisterInterestedGrenadeRegistrant(InterestedGrenadeRegistrants[i]);
	}
}

// Returns true if the client is already registered on this weapon, false otherwise
private function bool IsAnInterestedGrenadeRegistrant(IInterestedGrenadeThrowing Client)
{
	local int i;

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		if (InterestedGrenadeRegistrants[i] == Client)
			return true;
	}

	// didn't find it
	return false;
}

function RegisterInterestedGrenadeThrowing(IInterestedGrenadeThrowing Client)
{
	assert(! IsAnInterestedGrenadeRegistrant(Client));

	InterestedGrenadeRegistrants[InterestedGrenadeRegistrants.Length] = Client;
}

function UnRegisterInterestedGrenadeThrowing(IInterestedGrenadeThrowing Client)
{
	local int i;

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		if (InterestedGrenadeRegistrants[i] == Client)
		{
			InterestedGrenadeRegistrants.Remove(i, 1);
			break;
		}
	}
}

defaultproperties
{
    UnavailableAfterUsed=true
    bStatic=False
    bBounce=true
    CollisionRadius=5
    CollisionHeight=5
}

