@addField( CR4Player ) private var modFovAdjusted : float;
@addField( CR4Player ) private var modFovCurrent : float;
@addField( CR4Player ) private var modFovVelocity : float;

// vanilla FOV is 60, 70 while sprinting
@addMethod( CR4Player ) public function ModAdjustableFOVTarget( widen : bool ) : float
{
	var target : float;

	target = modFovAdjusted;
	if( target <= 0 )
		target = 60;

	if( widen )
		target += 10;

	return target;
}

// same range as the slider in modAdjustableFOV.xml
@addMethod( CR4Player ) public function ModAdjustableFOVSetFromString( value : string )
{
	var previous : float;

	previous = modFovAdjusted;
	modFovAdjusted = 60 + ClampF( StringToFloat( value ), -25, 25 );

	if( modFovAdjusted != previous )
		ModAdjustableFOVSnap();
}

@addMethod( CR4Player ) public function ModAdjustableFOVLoad()
{
	ModAdjustableFOVSetFromString( theGame.GetInGameConfigWrapper().GetVarValue( 'modAdjustableFOV', 'mod_adjusted_fov' ) );
}

// writing fov disturbs camera blends
@addMethod( CR4Player ) private function ModAdjustableFOVWrite( fov : float )
{
	var gameCamera : CCustomCamera;
	var topmost : CCustomCamera;

	gameCamera = theGame.GetGameCamera();
	if( gameCamera && AbsF( gameCamera.fov - fov ) > 0.01 )
		gameCamera.fov = fov;

	topmost = (CCustomCamera)theCamera.GetTopmostCameraObject();
	if( topmost && AbsF( topmost.fov - fov ) > 0.01 )
		topmost.fov = fov;
}

// DampFloatSpring's out arguments don't write back here
@addMethod( CR4Player ) public function ModAdjustableFOVApply( dt : float, widen : bool )
{
	var x, decay, diff, temp : float;

	if( modFovCurrent <= 0 )
		modFovCurrent = ModAdjustableFOVTarget( false );

	x = 2.0 * dt;
	decay = 1.0 / ( 1.0 + x + 0.48 * x * x + 0.235 * x * x * x );
	diff = modFovCurrent - ModAdjustableFOVTarget( widen );
	temp = ( modFovVelocity + 2.0 * diff ) * dt;
	modFovVelocity = ( modFovVelocity - 2.0 * temp ) * decay;
	modFovCurrent = ModAdjustableFOVTarget( widen ) + ( diff + temp ) * decay;

	ModAdjustableFOVWrite( modFovCurrent );
}

// vanilla's sprint camera condition, minus combat
@addMethod( CR4Player ) public function ModAdjustableFOVWiden() : bool
{
	return sprintingCamera && !IsInCombat() && !GetExplCamera() && !GetCmbtCamera() && !IsModernExplorationCamera();
}

@addMethod( CR4Player ) public function ModAdjustableFOVSnap()
{
	modFovCurrent = ModAdjustableFOVTarget( false );
	modFovVelocity = 0;
	ModAdjustableFOVWrite( modFovCurrent );
}

// MountHorse has no camera hook
@addMethod( CR4Player ) timer function ModAdjustableFOVCatchUp( dt : float, id : int )
{
	if( GetCurrentStateName() == 'MountHorse' )
		ModAdjustableFOVSnap();
}

@wrapMethod( CR4Player ) function OnSpawned( spawnData : SEntitySpawnData )
{
	var result : bool;

	result = wrappedMethod( spawnData );

	ModAdjustableFOVLoad();
	AddTimer( 'ModAdjustableFOVCatchUp', 0, true );

	return result;
}

// vanilla sets this on dismount
@wrapMethod( CR4Player ) function GetExplorationCameraFov() : float
{
	wrappedMethod();
	return ModAdjustableFOVTarget( false );
}

@wrapMethod( CR4PlayerStateExploration ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	result = wrappedMethod( moveData, dt );
	parent.ModAdjustableFOVApply( dt, parent.ModAdjustableFOVWiden() );

	return result;
}

@wrapMethod( CR4PlayerStateCombat ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	result = wrappedMethod( moveData, dt );
	parent.ModAdjustableFOVApply( dt, parent.ModAdjustableFOVWiden() );

	return result;
}

@wrapMethod( CR4PlayerStateUseGenericVehicle ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	result = wrappedMethod( moveData, dt );

	if( parent.GetCurrentStateName() != 'HorseRiding' )
		parent.ModAdjustableFOVApply( dt, false );

	return result;
}

@wrapMethod( CR4PlayerStateHorseRiding ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	result = wrappedMethod( moveData, dt );
	parent.ModAdjustableFOVSnap();

	return result;
}

@wrapMethod( CR4PlayerStateHorseRiding ) function OnEnterState( prevStateName : name )
{
	var result : bool;

	result = wrappedMethod( prevStateName );
	parent.ModAdjustableFOVSnap();

	return result;
}

@wrapMethod( CR4PlayerStateAimThrow ) function OnLeaveState( nextStateName : name )
{
	var result : bool;

	result = wrappedMethod( nextStateName );
	parent.ModAdjustableFOVSnap();

	return result;
}

@wrapMethod( CR4IngameMenu ) function OnOptionValueChanged( groupId : int, optionName : name, optionValue : string )
{
	var result : bool;

	result = wrappedMethod( groupId, optionName, optionValue );

	if( thePlayer && optionName == 'mod_adjusted_fov' )
		thePlayer.ModAdjustableFOVSetFromString( optionValue );

	return result;
}

@wrapMethod( CR4IngameMenu ) function SaveChangedSettings()
{
	wrappedMethod();

	if( thePlayer )
		thePlayer.ModAdjustableFOVLoad();
}
