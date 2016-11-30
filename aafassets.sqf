/*
 * Called when an AAF tank, APC, Heli or Plane is killed.
 * Simply subtracts 1 from various global counts that keep
 * track of AAF assets. Also removes *all* of the vehicle
 * type from the AAF available vehicle list.
 *
 * Arguments:
 * 0: Target vehicle <OBJECT>
 *
 * Return Value: Nothing
 *
 * Modifies Globals: APCAAFCurrent (and tanks, planes, etc), vehAAFAT, planesAAF
 *
 * Example:
 * _veh addEventHandler ["killed",{[_this select 0] call AAFassets;}];
 */

if !(isPlayer stavros) exitWith {};

params ["_vehicle"];
private ["_vehicle_type"];
_vehicle_type = [_vehicle] call _fnc_getTypeForVehicle;

switch (_vehicle_type) do {
	case ("APC"): _fnc_subtractAPC;
	case ("TANK"): _fnc_subtractTANK;
	case ("HELI"): _fnc_subtractHELI;
	case ("PLANE"): _fnc_subtractPLANE;
	default {
		if (debug) then { hint format ["AAFAssets called w/unknown vehicle %1", typeOf _vehicle]; };
	};
};

_fnc_subtractAPC = {
	["APCAAFcurrent", APCAAFcurrent] call _fnc_safeSubtractAssetCount;
	if (APCAAFcurrent < 0) then {
		private ["_to_subtract"];
		_to_subtract = vehAPC - vehIFV;
	  ["vehAAFAT", vehAAFAT, _to_subtract] call _fnc_removeDestroyedVehicleTypeFromSpawnList;
	};
};
_fnc_subtractTANK = {
	["tanksAAFcurrent", tanksAAFcurrent] call _fnc_safeSubtractAssetCount;
	if (tanksAAFcurrent < 0) then {
	  ["vehAAFAT", vehAAFAT, vehTank] call _fnc_removeDestroyedVehicleTypeFromSpawnList;
	};
};
_fnc_subtractHELI = {
	["helisAAFcurrent", helisAAFcurrent] call _fnc_safeSubtractAssetCount;
	if (helisAAFcurrent < 0) then {
	  ["planesAAF", planesAAF, heli_armed] call _fnc_removeDestroyedVehicleTypeFromSpawnList;
	};
};
_fnc_subtractPLANE = {
	["planesAAFcurrent", planesAAFcurrent] call _fnc_safeSubtractAssetCount;
	if (planesAAFcurrent < 0) then {
	  ["planesAAF", planesAAF, planes] call _fnc_removeDestroyedVehicleTypeFromSpawnList;
	};
};

// Subtract 1 from asset and redeclare public
_fnc_safeSubtractAssetCount = {
	params ["_variable", "_value"];
	_value = _value - 1;
	if (_value < 0) then { _value = 0 };
	missionNamespace setVariable [_variable, _value, true];
};

// Does what it says on the tin
_fnc_removeDestroyedVehicleTypeFromSpawnList = {
 params ["_variable", "_spawnlist", "_vehicles_to_remove"];
 private ["_new_spawnlist"];
 _new_spawnlist = _spawnlist - _vehicles_to_remove;

 missionNamespace setVariable [_variable, _new_spawnlist, true];
};

// Vehicle convert into 1 of 4 string "types"
_fnc_getTypeForVehicle =  {
	params ["_vehicle"];
	_vehicle_class = typeOf _vehicle;

	switch true do {
	  case ((_vehicle_class in vehAPC) or (_vehicle_type in vehIFV)): {"APC"};
	  case (_vehicle_class in vehTank): {"TANK"};
	  case (_vehicle_class in vehHeli): {"HELI"};
	  case (_vehicle_class in vehPlane): {"PLANE"};
	  default { objNull };
	};
};
