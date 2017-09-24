#pragma semicolon 1

#pragma newdecls required

#include <sourcemod>

#define DEFAULT_MAXSPEED 520.0

Address pPatchLocation;
int iRestoreData;
float speedVal;


public Plugin myinfo = {
	name = "[TF2] Max Speed Patch",
	author = "FlaminSarge",
	description = "Unlimits max running speed (from 520)",
	version = "0.1.0",
	url = "https://github.com/FlaminSarge/tf_maxspeed_patch"
}

public void OnPluginStart() {
	char strDefaultSpeed[16];
	FloatToString(DEFAULT_MAXSPEED, strDefaultSpeed, sizeof(strDefaultSpeed));
	ConVar cv_speed = CreateConVar("tf_maxspeed_limit", strDefaultSpeed, "[TF2] Max Speed Patch speed limit");
	cv_speed.AddChangeHook(cvhook_speed);
	speedVal = cv_speed.FloatValue;
}
public void cvhook_speed(ConVar cvar, const char[] oldVal, const char[] newVal) {
	speedVal = cvar.FloatValue;
	RemovePatch();
	ApplyPatch();
}
public void OnConfigsExecuted() {
	ApplyPatch();
}
public void OnPluginEnd() {
	RemovePatch();
}
public void OnMapEnd() {
	OnPluginEnd();
}
void ApplyPatch() {	//TODO: Generalize this plugin to use GameConfGetKeyValue to do an arbitrary number of patches
	pPatchLocation = Address_Null;
	iRestoreData = 0;

	Handle hGameConf = LoadGameConfigFile("tf.maxspeed");
	if (hGameConf == INVALID_HANDLE) {
		LogError("Failed to load maxspeed patch: Missing gamedata/tf.maxspeed.txt");
		return;
	}

	int iOffs = GameConfGetOffset(hGameConf, "Offset_ProcessMovement");
	if (iOffs == -1) {
		LogError("Failed to load maxspeed patch: Could not load patch offset");
		CloseHandle(hGameConf);
		return;
	}

	pPatchLocation = GameConfGetAddress(hGameConf, "CTFGameMovement::ProcessMovement");
	if (pPatchLocation == Address_Null) {
		LogError("Failed to load maxspeed patch: Failed to locate \"CTFGameMovement::ProcessMovement\"");
		CloseHandle(hGameConf);
		return;
	}
	CloseHandle(hGameConf);

	pPatchLocation += view_as<Address>(iOffs);

	iRestoreData = LoadFromAddress(pPatchLocation, NumberType_Int32);
	if (view_as<float>(iRestoreData) != DEFAULT_MAXSPEED) {
		LogError("Value at (0x%.8X) was not expected: (%.4f) != %.1f. Cowardly refusing to do things.", pPatchLocation, iRestoreData, DEFAULT_MAXSPEED);
		iRestoreData = 0;
		pPatchLocation = Address_Null;
		return;
	}
	LogMessage("Patching ProcessMovement data at (0x%.8X) from (%.4f) to (%.4f).", pPatchLocation, view_as<float>(iRestoreData), speedVal);
	StoreToAddress(pPatchLocation, view_as<int>(speedVal), NumberType_Int32);
}

void RemovePatch() {
	if (pPatchLocation == Address_Null || iRestoreData <= 0) {
		return;
	}

	LogMessage("Restoring ProcessMovement data at (0x%.8X) to (%.4f).", pPatchLocation, view_as<float>(iRestoreData));
	StoreToAddress(pPatchLocation, iRestoreData, NumberType_Int32);

	pPatchLocation = Address_Null;
	iRestoreData = 0;
}