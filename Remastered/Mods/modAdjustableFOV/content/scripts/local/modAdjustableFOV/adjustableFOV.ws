// one camera's vanilla fov and our written value
class ModAdjustableFOVSlot
{
	var cam : CCustomCamera;
	var raw : float;
	var written : float;
	var valid : bool;

	function Raw( getterValid : bool, getterValue : float, getterOffset : float ) : float
	{
		var fov : float;

		fov = cam.fov;
		if( valid && AbsF( fov - written ) < 0.05 )
			return raw;

		// getter values already carry the offset
		if( getterValid && AbsF( fov - getterValue ) < 0.05 )
			return fov - getterOffset;

		return fov;
	}

	function Write( fov : float )
	{
		if( AbsF( cam.fov - fov ) > 0.001 )
			cam.fov = fov;
	}
}

@addField( CR4Player ) private var modFovOffset : float;
@addField( CR4Player ) private var modFovDepth : int;
@addField( CR4Player ) private var modFovGame : ModAdjustableFOVSlot;
@addField( CR4Player ) private var modFovTop : ModAdjustableFOVSlot;
@addField( CR4Player ) private var modFovGameActive : bool;
@addField( CR4Player ) private var modFovTopActive : bool;
@addField( CR4Player ) private var modFovTopWasActive : bool;
@addField( CR4Player ) private var modFovGetterValid : bool;
@addField( CR4Player ) private var modFovGetterValue : float;
@addField( CR4Player ) private var modFovGetterOffset : float;

// the player is rebuilt on load, the game camera isn't
@addField( CR4Game ) public var modFovSavedValid : bool;
@addField( CR4Game ) public var modFovSavedRaw : float;
@addField( CR4Game ) public var modFovSavedWritten : float;

@addMethod( CR4Game ) public function ModAdjustableFOVSave( raw : float, written : float )
{
	modFovSavedValid = true;
	modFovSavedRaw = raw;
	modFovSavedWritten = written;
}

// same range as the slider in modAdjustableFOV.xml
@addMethod( CR4Player ) public function ModAdjustableFOVSetFromString( value : string )
{
	var previous : float;

	previous = modFovOffset;
	modFovOffset = ClampF( StringToFloat( value ), -25, 25 );

	if( modFovOffset != previous )
		ModAdjustableFOVNormalize();
}

@addMethod( CR4Player ) public function ModAdjustableFOVLoad()
{
	ModAdjustableFOVSetFromString( theGame.GetInGameConfigWrapper().GetVarValue( 'modAdjustableFOV', 'mod_adjusted_fov' ) );
}

@addMethod( CR4Player ) private function ModAdjustableFOVSlots()
{
	var gameCamera : CCustomCamera;
	var topmost : CCustomCamera;
	var active : bool;

	if( !modFovGame )
		modFovGame = new ModAdjustableFOVSlot in this;
	if( !modFovTop )
		modFovTop = new ModAdjustableFOVSlot in this;

	gameCamera = theGame.GetGameCamera();
	if( modFovGame.cam != gameCamera )
	{
		modFovGame.cam = gameCamera;
		modFovGame.valid = false;

		if( gameCamera && theGame.modFovSavedValid && AbsF( gameCamera.fov - theGame.modFovSavedWritten ) < 0.05 )
		{
			modFovGame.valid = true;
			modFovGame.raw = theGame.modFovSavedRaw;
			modFovGame.written = theGame.modFovSavedWritten;
		}
	}
	modFovGameActive = false;
	if( gameCamera )
		modFovGameActive = true;

	// the horse camera copies the game camera's fov
	topmost = (CCustomCamera)theCamera.GetTopmostCameraObject();
	active = gameCamera && topmost && topmost != gameCamera;
	if( active && ( !modFovTopWasActive || modFovTop.cam != topmost ) )
	{
		if( modFovTop.cam != topmost )
			modFovTop.valid = false;
		modFovTop.cam = topmost;

		if( modFovGame.valid && AbsF( topmost.fov - modFovGame.written ) < 0.05 )
		{
			modFovTop.valid = true;
			modFovTop.raw = modFovGame.raw;
			modFovTop.written = modFovGame.written;
		}
	}
	modFovTopWasActive = active;
	modFovTopActive = active;
}

@addMethod( CR4Player ) private function ModAdjustableFOVPut( slot : ModAdjustableFOVSlot )
{
	slot.written = slot.raw + modFovOffset;
	slot.valid = true;
	slot.Write( slot.written );

	if( slot == modFovGame )
		theGame.ModAdjustableFOVSave( slot.raw, slot.written );
}

@addMethod( CR4Player ) private function ModAdjustableFOVRestore( slot : ModAdjustableFOVSlot )
{
	slot.raw = slot.Raw( modFovGetterValid, modFovGetterValue, modFovGetterOffset );
	slot.Write( slot.raw );
}

// vanilla springs its own fov inside a camera tick
@addMethod( CR4Player ) public function ModAdjustableFOVBegin()
{
	if( modFovDepth == 0 )
	{
		ModAdjustableFOVSlots();
		if( modFovGameActive )
			ModAdjustableFOVRestore( modFovGame );
		if( modFovTopActive )
			ModAdjustableFOVRestore( modFovTop );
	}

	modFovDepth += 1;
}

@addMethod( CR4Player ) public function ModAdjustableFOVEnd()
{
	modFovDepth -= 1;
	if( modFovDepth > 0 )
		return;

	modFovDepth = 0;
	if( modFovGameActive && modFovGame.cam )
	{
		modFovGame.raw = modFovGame.cam.fov;
		ModAdjustableFOVPut( modFovGame );
	}
	if( modFovTopActive && modFovTop.cam )
	{
		modFovTop.raw = modFovTop.cam.fov;
		ModAdjustableFOVPut( modFovTop );
	}
}

// writes outside a camera tick
@addMethod( CR4Player ) public function ModAdjustableFOVNormalize()
{
	if( modFovDepth > 0 )
		return;

	ModAdjustableFOVSlots();
	if( modFovGameActive && modFovGame.cam )
	{
		modFovGame.raw = modFovGame.Raw( modFovGetterValid, modFovGetterValue, modFovGetterOffset );
		ModAdjustableFOVPut( modFovGame );
	}
	if( modFovTopActive && modFovTop.cam )
	{
		modFovTop.raw = modFovTop.Raw( modFovGetterValid, modFovGetterValue, modFovGetterOffset );
		ModAdjustableFOVPut( modFovTop );
	}
}

// vanilla leaves the game camera at its sprint fov
@addMethod( CR4Player ) public function ModAdjustableFOVDismount()
{
	fovVel = 0;

	if( !modFovGetterValid || modFovDepth > 0 )
		return;

	ModAdjustableFOVSlots();
	if( !modFovGameActive || !modFovGame.cam )
		return;

	modFovGame.raw = modFovGetterValue - modFovGetterOffset;
	ModAdjustableFOVPut( modFovGame );
}

@wrapMethod( CR4Player ) function OnSpawned( spawnData : SEntitySpawnData )
{
	var result : bool;

	result = wrappedMethod( spawnData );
	ModAdjustableFOVLoad();

	return result;
}

// offset only for sets outside a camera tick
@wrapMethod( CR4Player ) function GetExplorationCameraFov() : float
{
	var fov : float;

	fov = wrappedMethod();
	if( modFovDepth > 0 )
		return fov;

	modFovGetterValid = true;
	modFovGetterValue = fov + modFovOffset;
	modFovGetterOffset = modFovOffset;
	return modFovGetterValue;
}

@wrapMethod( CR4PlayerStateExploration ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	parent.ModAdjustableFOVBegin();
	result = wrappedMethod( moveData, dt );
	parent.ModAdjustableFOVEnd();

	return result;
}

@wrapMethod( CR4PlayerStateCombat ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	parent.ModAdjustableFOVBegin();
	result = wrappedMethod( moveData, dt );
	parent.ModAdjustableFOVEnd();

	return result;
}

@wrapMethod( CR4PlayerStateUseGenericVehicle ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	parent.ModAdjustableFOVBegin();
	result = wrappedMethod( moveData, dt );
	parent.ModAdjustableFOVEnd();

	return result;
}

@wrapMethod( CR4PlayerStateHorseRiding ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result : bool;

	parent.ModAdjustableFOVBegin();
	result = wrappedMethod( moveData, dt );
	parent.ModAdjustableFOVEnd();

	return result;
}

@wrapMethod( CR4PlayerStateHorseRiding ) function OnLeaveState( nextStateName : name )
{
	var result : bool;

	result = wrappedMethod( nextStateName );
	parent.ModAdjustableFOVDismount();

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
