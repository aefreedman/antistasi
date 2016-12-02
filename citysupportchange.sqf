 // multiplier for city support changes, for balance testing
#define INFLUENCE_SCALE_FACTOR 3

params["_opfor","_blufor","_pos"];
private ["_ciudad","_datos","_numCiv","_numVeh","_roads","_prestigeOPFOR","_prestigeBLUFOR"];

// primitive mutex/semaphore to prevent race conditions.
waitUntil {!cityIsSupportChanging};
cityIsSupportChanging = true;

_opfor = _opfor * INFLUENCE_SCALE_FACTOR;
_blufor = _blufor * INFLUENCE_SCALE_FACTOR;

_ciudad = if (typeName _pos == typeName "") then { _pos } else { [ciudades, _pos] call BIS_fnc_nearestPosition };
_datos = server getVariable _ciudad;
if (!(_datos isEqualType [])) exitWith {citySupportChanging = true; diag_log format ["Error in citysupportchange.sqf. Passed %1 as reference",_pos]};

diag_log format ["Changing City Support of %1 - AAF %2 FIA %3", _ciudad, _opfor, _blufor];

_numCiv = _datos select 0;
_numVeh = _datos select 1;
_prestigeOPFOR = _datos select 2;
_prestigeBLUFOR = _datos select 3;

_prestigeOPFOR = _prestigeOPFOR + _opfor;
_prestigeBLUFOR = _prestigeBLUFOR + _blufor;

if (_prestigeOPFOR > 99) then {_prestigeOPFOR = 99};
if (_prestigeBLUFOR > 99) then {_prestigeBLUFOR = 99};
if (_prestigeOPFOR < 1) then {_prestigeOPFOR = 1};
if (_prestigeBLUFOR < 1) then {_prestigeBLUFOR = 1};

_datos = [_numCiv, _numVeh,_prestigeOPFOR,_prestigeBLUFOR];

server setVariable [_ciudad,_datos,true];
cityIsSupportChanging = false;
true
