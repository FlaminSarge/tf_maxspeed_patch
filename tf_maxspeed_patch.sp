#pragma semicolon 1

#include <sourcemod>

new Address:pPatchLocation;
new iRestoreData;
new Float:speedVal;

public Plugin:myinfo =
{
	name = "[TF2] Max Speed Patch",
	author = "FlaminSarge",
	description = "Unlimits max speed (from 520)",
	version = "0.1.0",
	url = "https://github.com/FlaminSarge/tf_maxspeed_patch"
}

public OnPluginStart()
{
	new Handle:cv_speed = CreateConVar("tf_maxspeed_limit", "1040.0", "[TF2] Max Speed Patch speed limit");
	HookConVarChange(cv_speed, cvhook_speed);
	speedVal = GetConVarFloat(cv_speed);
}
public cvhook_speed(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	speedVal = GetConVarFloat(cvar);
	RemovePatch();
	ApplyPatch();
}
public OnConfigsExecuted()
{
	ApplyPatch();
}
public OnPluginEnd()
{
	RemovePatch();
}
public OnMapEnd()
{
	OnPluginEnd();
}
ApplyPatch()	//TODO: Generalize this plugin to use GameConfGetKeyValue to do an arbitrary number of patches
{
	pPatchLocation = Address_Null;
	iRestoreData = 0;

	new Handle:hGameConf = LoadGameConfigFile("tf.maxspeed");
	if(hGameConf == INVALID_HANDLE)
	{
		LogError("Failed to load maxspeed patch: Missing gamedata/tf.maxspeed.txt");
		return;
	}

	new iOffs = GameConfGetOffset(hGameConf, "Offset_ProcessMovement");
	if (iOffs == -1)
	{
		LogError("Failed to load maxspeed patch: Could not load patch offset");
		CloseHandle(hGameConf);
		return;
	}

	pPatchLocation = GameConfGetAddress(hGameConf, "CTFGameMovement::ProcessMovement");
	if (pPatchLocation == Address_Null)
	{
		LogError("Failed to load maxspeed patch: Failed to locate \"CTFGameMovement::ProcessMovement\"");
		CloseHandle(hGameConf);
		return;
	}
	CloseHandle(hGameConf);

	pPatchLocation += Address:iOffs;

	iRestoreData = LoadFromAddress(pPatchLocation, NumberType_Int32);
	if ((Float:iRestoreData) != 520.0)
	{
		LogError("Value at (0x%.8X) was not expected: (%.4f) != 520.0. Cowardly refusing to do things.", pPatchLocation, iRestoreData);
		iRestoreData = 0;
		pPatchLocation = Address_Null;
		return;
	}
	LogMessage("Patching ProcessMovement data at (0x%.8X) from (%.4f) to (%.4f).", pPatchLocation, Float:iRestoreData, Float:speedVal);
	StoreToAddress(pPatchLocation, _:speedVal, NumberType_Int32);
}

RemovePatch()
{
	if(pPatchLocation == Address_Null) return;
	if(iRestoreData <= 0) return;

	LogMessage("Restoring ProcessMovement data at (0x%.8X) to (%.4f).", pPatchLocation, Float:iRestoreData);
	StoreToAddress(pPatchLocation, iRestoreData, NumberType_Int32);

	pPatchLocation = Address_Null;
	iRestoreData = 0;
}