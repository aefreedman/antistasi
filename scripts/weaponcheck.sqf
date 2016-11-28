private ["_weapons"];

_weapons = _this select 0;

{
	call {
		if (_x in mguns) exitWith {server setVariable ["genLMGlocked",false,true];};
		if (_x in genGL) exitWith {server setVariable ["genGLlocked",false,true];};
		if (_x in srifles) exitWith {server setVariable ["genSNPRlocked",false,true];};
		if (_x in genATLaunchers) exitWith {server setVariable ["genATlocked",false,true];};
		if (_x in genAALaunchers) exitWith {server setVariable ["genAAlocked",false,true];};
	};
} forEach _weapons;