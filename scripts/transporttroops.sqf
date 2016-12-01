_vehGroup = _this select 0;
_dest = _this select 1;
_orig = _this select 2;
_duration = _this select 3;
_infGroups = _this select 4;
_mrk = _this select 5;

_infGroup1 = _infGroups;
_infGroup2 = "";
if (typeName _infGroups == "ARRAY") then {
  _infGroup1 = _infGroups select 0;
  _infGroup2 = _infGroups select 1;
};

diag_log format ["Transport heading for %1", _dest];

_wp100 = _vehGroup addWaypoint [_dest, 0];
_wp100 setWaypointBehaviour "CARELESS";
_wp100 setWaypointSpeed "FULL";
_wp100 setWaypointType "TR UNLOAD";
_wp101 = _infGroup1 addWaypoint [_dest, 0];
_wp101 setWaypointType "GETOUT";
_wp101 synchronizeWaypoint [_wp100];
if (typeName _infGroups == "ARRAY") then {
  _wp201 = _infGroup2 addWaypoint [_dest, 0];
  _wp201 setWaypointType "GETOUT";
  _wp201 synchronizeWaypoint [_wp100];
};
_wp104 = _infGroup1 addWaypoint [getMarkerPos _mrk, 0];
_wp104 setWaypointType "SAD";
_wp104 setWaypointBehaviour "AWARE";
_infGroup1 setCombatMode "RED";
if (typeName _infGroups == "ARRAY") then {
  _wp202 = _infGroup2 addWaypoint [getMarkerPos _mrk, 0];
  _wp202 setWaypointType "SAD";
  _wp202 setWaypointBehaviour "AWARE";
  _infGroup2 setCombatMode "RED";
};

_wp102 = _vehGroup addWaypoint [_orig, 50];
_wp102 setWaypointSpeed "FULL";
_wp102 setWaypointBehaviour "CARELESS";
_wp102 setWaypointStatements ["true", "deletevehicle (vehicle this); {deleteVehicle _x;} foreach thisList"];

waitUntil {sleep 5; ((units _infGroup1 select 0) distance _dest < 10)};

sleep 20;
_vehGroup setCurrentWaypoint _wp102;

if (typeName _infGroups == "ARRAY") then {
  0 = [leader _infGroup2, _mrk, "AWARE", "SPAWNED","NOVEH", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";
};

sleep _duration;

_wp103 = _infGroup1 addWaypoint [_orig, 50];
_wp103 setWaypointCombatMode "GREEN";
if (typeName _infGroups == "ARRAY") then {
  _wp203 = _infGroup2 addWaypoint [_orig, 50];
  _wp203 setWaypointCombatMode "GREEN";
};