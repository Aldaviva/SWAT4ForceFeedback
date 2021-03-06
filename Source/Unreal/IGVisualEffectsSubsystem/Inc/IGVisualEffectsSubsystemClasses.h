/*===========================================================================
	  C++ class	definitions	exported from UnrealScript.
	  This is automatically	generated by the tools.
	  DO NOT modify	this manually! Edit	the	corresponding .uc files	instead!
===========================================================================*/
#if SUPPORTS_PRAGMA_PACK
#pragma pack (push,4)
#endif

#ifndef IGVISUALEFFECTSSUBSYSTEM_API
#define IGVISUALEFFECTSSUBSYSTEM_API DLL_IMPORT
#endif

#ifndef NAMES_ONLY
#define AUTOGENERATE_NAME(name) extern IGVISUALEFFECTSSUBSYSTEM_API	FName IGVISUALEFFECTSSUBSYSTEM_##name;
#define AUTOGENERATE_FUNCTION(cls,idx,name)
#endif


#ifndef NAMES_ONLY

// Enum MatchResult is declared in "..\IGVisualEffectsSubsystem\Classes\VisualEffectsSubsystem.uc"
enum MatchResult
{
	 MatchResult_None        =0,
	 MatchResult_Matched     =1,
	 MatchResult_UseDefault  =2,
	 MatchResult_MAX         =3,
};


// Class	AVisualEffectsSubsystem is declared in "..\IGVisualEffectsSubsystem\Classes\VisualEffectsSubsystem.uc"
class IGVISUALEFFECTSSUBSYSTEM_API	AVisualEffectsSubsystem	: public AEffectsSubsystem
{
public:
    TArrayNoInit<class UClass*> MatchingEffectClasses;
    TArrayNoInit<class UClass*> DefaultEffectClasses;
    TArrayNoInit<class UClass*> SelectedEffectClasses;
    INT CurrentDecal;
	   DECLARE_FUNCTION(execPostLoaded);
	   DECLARE_CLASS(AVisualEffectsSubsystem,AEffectsSubsystem,0|CLASS_Config,IGVisualEffectsSubsystem)
    //declaration of script-side
    //  var private native noexport const int PrecacheVisualEffects[5];
    TSet<UClass*> PrecacheVisualEffects;

    //overridden from EffectsSubsystem
    void PrecacheEffectSpecification(UEffectSpecification* Spec);

    //instruct the engine to precache all assets related to the specified Effect class.
    //Effect can theoretically be any class<Actor>, but is usually one of:
    //  Emitter, Projector, DynamicLight.
    void PrecacheVisualEffect(UClass* EffectClass);
};

// Class	UVisualEffectSpecification is declared in "..\IGVisualEffectsSubsystem\Classes\VisualEffectSpecification.uc"
class IGVISUALEFFECTSSUBSYSTEM_API	UVisualEffectSpecification	: public UEffectSpecification
{
public:
    TArrayNoInit<BYTE> MaterialType;
    TArrayNoInit<class UClass*> EffectClass;
	   DECLARE_CLASS(UVisualEffectSpecification,UEffectSpecification,0|CLASS_Config,IGVisualEffectsSubsystem)
	   NO_DEFAULT_CONSTRUCTOR(UVisualEffectSpecification)
};

#endif

AUTOGENERATE_FUNCTION(AVisualEffectsSubsystem,-1,execPostLoaded);

#ifndef NAMES_ONLY
#undef AUTOGENERATE_NAME
#undef AUTOGENERATE_FUNCTION
#endif

#if SUPPORTS_PRAGMA_PACK
#pragma pack	(pop)
#endif

#ifdef VERIFY_CLASS_SIZES
VERIFY_CLASS_SIZE_NODIE(UVisualEffectSpecification)
VERIFY_CLASS_SIZE_NODIE(AVisualEffectsSubsystem)
#endif // VERIFY_CLASS_SIZES
