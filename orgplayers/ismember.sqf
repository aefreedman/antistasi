params["_obj"];
if !(isMultiplayer) exitWith { true };
if (isNil "miembros") exitWith { true };
if (count miembros < 1) exitWith { true };
_owner = _obj getVariable ["owner",_obj];
(getPlayerUID _owner) in miembros;
