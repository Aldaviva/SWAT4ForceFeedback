class IdleDefinition extends Core.Object
    within IdleActionsList
    perobjectconfig;

///////////////////////////////////////////////////////////////////////////////
//
// IdleDefinition Enumerations

enum EIdleCharacterType
{
    AllTypesIdle,
    OnlyWeaponUsersIdle,
    EnemyIdle,
    OfficerIdle,
    HostageIdle
};

enum EIdleTime
{
    IdleAnytimeExceptAiming,
    IdleAiming,
	IdleAnytime
};

enum EIdleCharacterAggression
{
	AggressionDoesNotMatter,
	PassiveCharactersOnly,
	AggressiveCharactersOnly
};

enum EIdleWeaponStatus
{
	IdleWeaponDoesNotMatter,
    IdleWithMachineGun,
	IdleWithG36,
	IdleWithSubMachineGun,
	IdleWithUMP,
    IdleWithHandgun,
	IdleWithShotgun,
	IdleWithPaintballGun,
	IdleWithGrenade,
	IdleWithAnyWeapon,
    IdleWithoutWeapon
};

enum ECharacterIdlePosition
{
	IdlePositionDoesNotMatter,
    IdleStanding,
    IdleCrouching
};

///////////////////////////////////////////////////////////////////////////////
//
// IdleDefinition Configuration Variables
var config EIdleCharacterType		IdleCharacterType;
var config EIdleTime				IdleTime;
var config EIdleWeaponStatus		IdleWeaponStatus;
var config ECharacterIdlePosition	CharacterIdlePosition;
var config name						IdleCategory;
var config EIdleCharacterAggression IdleCharacterAggression;
var config float					Weight;

