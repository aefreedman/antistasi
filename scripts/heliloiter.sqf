_vehGroup = _this select 0;
_dest = _this select 1;
_orig = _this select 2;
_duration = _this select 3;

_dismounts = "";

// armed helicopters
if (count _this == 4) then {
  _dist = _orig distance2d _dest;
  _dir = _orig getDir _dest;
  _div = (floor (_dist / 150)) - 1;

  _x1 = _orig select 0;
  _y1 = _orig select 1;
  _x2 = _dest select 0;
  _y2 = _dest select 1;

  _x3 = (_x1 + _div*_x2) / (_div + 1);
  _y3 = (_y1 + _div*_y2) / (_div + 1);
  _z3 = 50;

  _approachPos = [_x3, _y3, _z3];

  _wp100 = _vehGroup addWaypoint [_approachPos, 50];
  _wp100 setWaypointSpeed "FULL";
  _wp100 setWaypointBehaviour "CARELESS";

  _wp101 = _vehGroup addWaypoint [_dest, 50];
  _wp101 setWaypointType "LOITER";
  _wp101 setWaypointLoiterType "CIRCLE";
  _wp101 setWaypointLoiterRadius 300;
  _wp101 setWaypointCombatMode "YELLOW";
  _wp101 setWaypointSpeed "LIMITED";

  sleep _duration;
}

// armed ground vehicles
else {

  // APC with dismounts
  if (typeName _dismounts == "ARRAY") then {
    _dismounts = _this select 4 select 0;
    _mrk = _this select 5;
    _wp200 = _vehGroup addWaypoint [_dest, 50];
    _wp200 setWaypointSpeed "FULL";
    _wp200 setWaypointBehaviour "CARELESS";
    _wp200 setWaypointType "TR UNLOAD";
    _wp300 = _dismounts addWaypoint [_dest, 50];
    _wp300 setWaypointType "GETOUT";
    _wp300 synchronizeWaypoint [_wp200];
    _wp301 = _dismounts addWaypoint [getMarkerPos _mrk, 0];
    _wp301 setWaypointType "SAD";
    _wp301 setWaypointBehaviour "COMBAT";
    _dismounts setCombatMode "RED";


    0 = [leader _vehGroup, _mrk, "COMBAT", "SPAWNED", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";

    sleep _duration;
  }

  // APC/MRAP without dismounts
  else {
    _mrk = _this select 4;
    _wp300 = _vehGroup addWaypoint [_dest, 50];
    _wp300 setWaypointSpeed "FULL";
    _wp300 setWaypointBehaviour "CARELESS";
    _wp300 setWaypointType "SAD";

    waitUntil {sleep 5; ((units _vehGroup select 0) distance _dest < 100)};

    0 = [leader _vehGroup, _mrk, "COMBAT", "SPAWNED", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";

    sleep _duration;
  };
};

_wp50 = _vehGroup addWaypoint [_orig, 50];
_wp50 setWaypointBehaviour "CARELESS";
_wp50 setWaypointStatements ["true", "deletevehicle (vehicle this); {deleteVehicle _x;} foreach thisList"];
_vehGroup setCurrentWaypoint _wp50;
