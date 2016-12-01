if (!isServer and hasInterface) exitWith{};

/*
params
0: base/airport/carrier to start from (marker)
1: target location (position)
2: marker for dismounts to patrol (marker)
3: patrol duration (time in minutes)
4: composition: transport/destroy/mixed (string)
5: size: large/small (string)
6: source of the QRF request (optional)

If origin is an airport/carrier, the QRF will consist of air cavalry. Otherwise it'll be ground forces in MRAPs/trucks.
*/

_orig = _this select 0;
_dest = _this select 1;
_mrk = _this select 2;
_duration = _this select 3;
_composition = _this select 4;
_size = _this select 5;

_source = "";
_origMarker = _this select 0;
if (count _this > 6) then {
  _source = _this select 6;
};

// FIA bases/airports
_bases = bases arrayIntersect mrkAAF;
_airports = aeropuertos arrayIntersect mrkAAF;

_posComp = ["transport", "destroy", "mixed"];
if !(_composition in _posComp) exitWith {};

// define type of QRF and vehicles by type of origin
_type = "air";
_side = side_red;
_lead = opHeliSD;
_transport = opHeliFR;
_dismountGroup = opGroup_Recon_Team;
if (_size == "large") then {
  _dismountGroup = opGroup_Squad;
};
_dismountGroupEscort = selectRandom infTeam;
if !(_orig == "spawnCSAT") then {
  _side = side_green;
  _lead = heli_escort;
  if (_size == "small") then {
    _transport = heli_default;
    _dismountGroup = selectRandom infTeam;
    _dismountGroup = (cfgInf >> _dismountGroup);
    if (_orig in _bases) then {
      _type = "land";
      _lead = selectRandom vehLead;
      _transport = enemyMotorpoolDef;
      _dismountGroup = selectRandom infSquad;
      _dismountGroup = (cfgInf >> _dismountGroup);
    };
  }
  else {
    _transport = heli_transport;
    _dismountGroup = selectRandom infSquad;
    _dismountGroup = (cfgInf >> _dismountGroup);
    if (_orig in _bases) then {
      _type = "land";
      _lead = selectRandom vehAPC;
      _transport = enemyMotorpoolDef;
      _dismountGroup = selectRandom infSquad;
      _dismountGroup = (cfgInf >> _dismountGroup);
    };
  };
};

// initialisation of units
_initUnits = {
    private _soldiersToInit = _this select 0;
    private _vehicleToInit = _this select 1;
    private _initSide = _this select 2;

    if (_initSide == side_red) then {
      if (typeName _soldiersToInit == "ARRAY") then {
        {[_x] spawn CSATinit} forEach _soldiersToInit;
      }
      else {
        {[_x] spawn CSATinit} forEach units _soldiersToInit;
      };
        if !(_vehicleToInit isEqualTo "none") then {
          [_vehicleToInit] spawn CSATVEHinit;
        };
    };

    if (_initSide == side_green) then {
        if (typeName _soldiersToInit == "ARRAY") then {
        {[_x] spawn genInit} forEach _soldiersToInit;
      }
      else {
        {[_x] spawn genInit} forEach units _soldiersToInit;
      };
        if !(_vehicleToInit isEqualTo "none") then {
          [_vehicleToInit] spawn VEHinit;
        };
    };
};

// create a patrol marker if none provided
if (_mrk == "none") then {
  _mrk = createMarkerLocal [format ["Patrol-%1", random 100],_dest];
  _mrk setMarkerShapeLocal "RECTANGLE";
  _mrk setMarkerSizeLocal [150,150];
  _mrk setMarkerTypeLocal "hd_warning";
  _mrk setMarkerColorLocal "ColorRed";
  _mrk setMarkerBrushLocal "DiagGrid";
    _mrk setMarkerAlpha 0;
};

// get the position of the target marker
if !(typeName _orig == "ARRAY") then {
  _orig = getMarkerPos _orig;
};

_endTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _duration];
_endTime = dateToNumber _endTime;

// arrays of all spawned units/groups
_grupos = [];
_soldados = [];
_vehiculos = [];

// initialise groups, two for vehicles, two for dismounts
_grpVeh1 = createGroup _side;
_grupos pushBack _grpVeh1;

_grpVeh2 = createGroup _side;
_grupos pushBack _grpVeh2;

_grpDis1 = createGroup _side;
_grupos pushBack _grpDis1;

_grpDis2 = createGroup _side;
_grupos pushBack _grpDis2;

_grpDisEsc = createGroup _side;
_grupos pushBack _grpDisEsc;

// air cav
if (_type == "air") then {

  if ((_composition == "destroy") || (_composition == "mixed")) then {
    // attack chopper/armed escort
    _vehicle = [_orig, 0, _lead, _side] call bis_fnc_spawnvehicle;
    _heli1 = _vehicle select 0;
    _heliCrew1 = _vehicle select 1;
    _grpVeh1 = _vehicle select 2;
    [_heliCrew1, _heli1, _side] call _initUnits;
    _soldados = _soldados + _heliCrew1;
    _grupos = _grupos + [_grpVeh1];
    _vehiculos = _vehiculos + [_heli1];
    _heli1 lock 3;

    // spawn loiter script for armed escort
    diag_log format ["Escort dispatched to %1", _dest];
    [_grpVeh1, _dest, _orig, _duration*60] spawn heliLoiter;
  };

  // small delay to prevent crashes when both helicopters are spawned
  if (_composition == "mixed") then {
    sleep 5;
  };

  if ((_composition == "transport") || (_composition == "mixed")) then {
    // landing pad, to allow for dismounts
    _landpos1 = [];
    if (_source == "campQRF") then {
      _landpos1 = [_dest, 300, 500, 10, 0, 0.3, 0] call BIS_Fnc_findSafePos;
    }
    else {
      _landpos1 = [_dest, 50, 300, 10, 0, 0.3, 0] call BIS_Fnc_findSafePos;
    };
    _landpos1 set [2, 0];
    _pad1 = createVehicle ["Land_HelipadEmpty_F", _landpos1, [], 0, "NONE"];
    _vehiculos = _vehiculos + [_pad1];

    // shift the spawn position of second chopper to avoid crash
    _pos2 = _orig;
    _zshift2 = (_orig select 2) + 50;
    _pos2 set [2, _zshift2];

    // troop transport chopper
    _vehicle2 = [_pos2, 0, _transport, _side] call bis_fnc_spawnvehicle;
    _heli2 = _vehicle2 select 0;
    _heliCrew2 = _vehicle2 select 1;
    _grpVeh2 = _vehicle2 select 2;
    [_heliCrew2, _heli2, _side] call _initUnits;
    _soldados = _soldados + _heliCrew2;
    _grupos = _grupos + [_grpVeh2];
    _vehiculos = _vehiculos + [_heli2];
    _heli2 lock 3;

    // spawn dismounts
    _grpDis2 = [_orig, _side, _dismountGroup] call BIS_Fnc_spawnGroup;
    [_grpDis2, "none", _side] call _initUnits;
    {
      _soldados pushBack _x;
      _x assignAsCargo _heli2;
      _x moveInCargo _heli2;
    } forEach units _grpDis2;
    _grpDis2 selectLeader (units _grpDis2 select 0);

    // spawn dismount script
    diag_log format ["Transport dispatched to %1", _dest];
    if (_size == "large") then {
      _grpDis1 = [_orig, _side, _dismountGroup] call BIS_Fnc_spawnGroup;
      [_grpDis1, "none", _side] call _initUnits;
      {
        _soldados pushBack _x;
        _x assignAsCargo _heli2;
        _x moveInCargo _heli2;
      } forEach units _grpDis1;
      _grpDis1 selectLeader (units _grpDis1 select 0);

      [_grpVeh2, _landpos1, _pos2, _duration*60, [_grpDis1,_grpDis2], _mrk] spawn heliFastrope;
    }
    else {
      [_grpVeh2, _landpos1, _pos2, _duration*60, _grpDis2, _mrk] spawn transportTroops;
    };

    // if the QRF is dispatched to an FIA camp, provide the group
    if (_source == "campQRF") then {
      if (_size == "large") then {
        server setVariable ["campQRF", [_grpDis1,_grpDis2], true];
      }
      else {
        server setVariable ["campQRF", [_grpDis2], true];
      };
    };
  };
}

// ground QRF
else {
  // find spawn positions on a road
  _tam = 10;
  _roads = [];

  while {true} do {
  _roads = _orig nearRoads _tam;
  if (count _roads > 2) exitWith {};
  _tam = _tam + 10;
  };


  if ((_composition == "destroy") || (_composition == "mixed")) then {
    // first MRAP, escort
    _vehicle1 = [position (_roads select 0), 0, _lead, _side] call bis_fnc_spawnvehicle;
    _veh1 = _vehicle1 select 0;
    _vehCrew1 = _vehicle1 select 1;
    _grpVeh1 = _vehicle1 select 2;
    [_vehCrew1, _veh1, _side] call _initUnits;
    _soldados = _soldados + _vehCrew1;
    _vehiculos = _vehiculos + [_veh1];

    if (_size == "large") then {
      _grpDisEsc = [_orig, _side, _dismountGroupEscort] call BIS_Fnc_spawnGroup;
      [_grpDisEsc, "none", _side] call _initUnits;
      {
        _soldados pushBack _x;
        _x assignAsCargo _veh1;
        _x moveInCargo _veh1;
      } forEach units _grpDisEsc;
      _grpDisEsc selectLeader (units _grpDisEsc select 0);

      // add waypoints
      [_grpVeh1, _dest, _orig, _duration*60, [_grpDisEsc], _mrk] spawn heliLoiter;
    };

    // add waypoints
    [_grpVeh1, _dest, _orig, _duration*60, _mrk] spawn heliLoiter;
    diag_log format ["Escort dispatched to %1", _dest];
  };

  // small delay to allow for AI pathfinding shenanigans
  if (_composition == "mixed") then {
    sleep 25;
  };

  if ((_composition == "transport") || (_composition == "mixed")) then {
    // dismount position
    _landpos1 = [_dest, position (_roads select 1), 0] call findSafeRoadToUnload;

    // second vehicle
    _vehicle2 = [position (_roads select 1), 0, _transport, _side] call bis_fnc_spawnvehicle;
    _veh2 = _vehicle2 select 0;
    _vehCrew2 = _vehicle2 select 1;
    _grpVeh2 = _vehicle2 select 2;
    [_vehCrew2, _veh2, _side] call _initUnits;
    _soldados = _soldados + _vehCrew2;
    _vehiculos = _vehiculos + [_veh2];

    // add dismounts
    _grpDis2 = [_orig, _side, _dismountGroup] call BIS_Fnc_spawnGroup;
    [_grpDis2, "none", _side] call _initUnits;
    {
      _soldados pushBack _x;
      _x assignAsCargo _veh2;
      _x moveInCargo _veh2;
    } forEach units _grpDis2;
    _grpDis2 selectLeader (units _grpDis2 select 0);

    if (_size == "large") then {
      _grpDis1 = [_orig, _side, _dismountGroup] call BIS_Fnc_spawnGroup;
      [_grpDis1, "none", _side] call _initUnits;
      {
        _soldados pushBack _x;
        _x assignAsCargo _veh2;
        _x moveInCargo _veh2;
      } forEach units _grpDis1;
      _grpDis1 selectLeader (units _grpDis1 select 0);
    };

    // spawn dismount script
    diag_log format ["Transport dispatched to %1", _dest];
    [_grpVeh2, _landpos1, _orig, _duration*60, [_grpDis1, _grpDis2], _mrk] spawn transportTroops;
  };
};

waitUntil {sleep 10; (dateToNumber date > _endTime) or ({alive _x} count _soldados == 0)};

// remove the remains
{
  _soldado = _x;
  waitUntil {sleep 1; {_x distance _soldado < distanciaSPWN} count (allPlayers - hcArray) == 0};
  deleteVehicle _soldado;
} forEach _soldados;

{deleteGroup _x} forEach _grupos;

{
  _vehiculo = _x;
  waitUntil {sleep 1; {_x distance _vehiculo < distanciaSPWN/2} count (allPlayers - hcArray) == 0};
  deleteVehicle _x
} forEach _vehiculos;