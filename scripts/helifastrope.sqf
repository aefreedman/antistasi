_vehGroup = _this select 0;
_dest = _this select 1;
_orig = _this select 2;
_duration = _this select 3;
_infGroups = _this select 4;
_mrk = _this select 5;

diag_log format ["Transport heading for %1", _dest];

_wp100 = _vehGroup addWaypoint [_dest, 50];
_wp100 setWaypointBehaviour "CARELESS";
_wp100 setWaypointSpeed "FULL";

_veh = vehicle (units (_infGroups select 0) select 0);

waitUntil {sleep 1; ((not alive _veh) || (speed _veh < 20)) && (_veh distance _dest < 300)};

(_infGroups select 0) call SHK_Fastrope_fnc_AIs;
sleep 2;
(_infGroups select 1) call SHK_Fastrope_fnc_AIs;



_wp201 = (_infGroups select 0) addWaypoint [getMarkerPos _mrk, 0];
_wp201 setWaypointType "SAD";
_wp201 setWaypointBehaviour "AWARE";
(_infGroups select 0) setCombatMode "RED";

0 = [leader (_infGroups select 1), _mrk, "AWARE", "SPAWNED","NOVEH", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";

sleep 6;
_wp102 = _vehGroup addWaypoint [_orig, 50];
_wp102 setWaypointSpeed "FULL";
_wp102 setWaypointBehaviour "CARELESS";
_wp102 setWaypointStatements ["true", "deletevehicle (vehicle this); {deleteVehicle _x;} foreach thisList"];
_vehGroup setCurrentWaypoint _wp102;

_duration = _duration - 120;
sleep _duration;

_wp202 = (_infGroups select 0) addWaypoint [_orig, 50];
_wp203 setWaypointCombatMode "GREEN";
_wp301 = (_infGroups select 1) addWaypoint [_orig, 50];
_wp301 setWaypointCombatMode "GREEN";