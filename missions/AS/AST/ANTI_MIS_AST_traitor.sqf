params ["_marker", "_source"];

//Spacehunnie note : should only execute for the host/server (?)
if (!isServer and hasInterface) exitWith{};

// "Civ" is passed as param if you requested the mission from Petros or a civilian
if (_source == "civ") then {
  //_val = server getVariable "civActive";
  //server setVariable ["civActive", server getVariable "civActive" + 1, true];
};

// LOCAL "const" VARIABLES
private _taskID = "AST";
private _taskTimeLimitMins = 60;
private _taskNewState = "New";
private _taskPlayerDiscoveredState = "Discovered";
private _taskSuccessState = "Success";
private _taskFailState = "Fail";
private _taskExpiredState = "Expired";
private _taskType = "Kill";
private _taskDesciptionStart = "A traitor has scheduled a meeting with USSR in %1. Kill him before he provides enough intel to give us trouble. Do this before %2:%3. We don't where exactly this meeting will happen. You will recognise the building by the nearby Offroad and USSR presence.";
private _taskDesciptionDiscovered = "A traitor has scheduled a meeting with USSR in %1. Kill him before he provides enough intel to give us trouble. Do this before %2:%3. We don't where exactly this meeting will happen. You will recognise the building by the nearby Offroad and USSR presence.";
private _taskDesciptionSuccess = "A traitor has scheduled a meeting with USSR in %1. Kill him before he provides enough intel to give us trouble. Do this before %2:%3. We don't where exactly this meeting will happen. You will recognise the building by the nearby Offroad and USSR presence.";
private _taskDesciptionFailure = "A traitor has scheduled a meeting with USSR in %1. Kill him before he provides enough intel to give us trouble. Do this before %2:%3. We don't where exactly this meeting will happen. You will recognise the building by the nearby Offroad and USSR presence.";
private _taskTitle = "Kill the Traitor";

// DETERMINE MISSION LOCATION
// The marker location around which the traitor will spawn, NOT the actual position of the traitor
private _targetTraitorSpawnLocation = getMarkerPos _marker;
private _houseSearchRadius = 100;
private _markerPos = getmarkerpos _marker;
private _houseObject = _markerPos nearObjects ["House", _houseSearchRadius] select 0;
diag_log "House Object:";
diag_log _houseObject;
//private _houseObject = _targetTraitorSpawnLocation call CBA_fnc_getNearestBuilding;

// Traitor "runaway base" location setup
// Spacehunnie note: mrkFIA is a global for "FIA Markers"
//private _closestBaseMarkerToTraitorArray = [[bases - mrkFIA], _targetTraitorSpawnLocation] call BIS_Fnc_nearestPosition; // errors?
private _closestBaseMarkerToTraitorArray = ["base"];
diag_log "Closest Base Marker Array";
diag_log _closestBaseMarkerToTraitorArray;
private _closestBaseMarkerPos = getMarkerPos "base";
diag_log "Closest Base Marker Pos";
diag_log _closestBaseMarkerPos;

private _taskExpireTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _taskTimeLimitMins];
private _taskExpireTimeFloat = dateToNumber _taskExpireTime;

_fnc_getTaskDesciptionForState = {
  params ["_location", "_taskState"];
  // Spacehunnie note: func "localizar" gets a string that describes the marker location e.g. "Outpost"
  private _markerDescription = [_location] call localizar; 
  private _descriptionString = "";
  switch (_taskState) do {
    case (_taskNewState): { _descriptionString = _taskDesciptionStart; };
    case (_taskPlayerDiscoveredState): { _descriptionString = _taskDesciptionDiscovered; };
    case (_taskSuccessState): { _descriptionString = _taskDesciptionSuccess; };
    case (_taskFailState): { _descriptionString = _taskDesciptionFailure; };
    default { _descriptionString = ""; };
  };
  private _dateArray = numberToDate [2035, _taskExpireTimeFloat];
  format [_descriptionString, _markerDescription, _dateArray select 3, _dateArray select 4];
};

/** Shortcut function to create the task for this mission 
*/
_fnc_updateTask = {
  params ["_originObject", "_description", "_taskType", "_startState"];
  private _priority = 5;
  private _showNotification = true;
  private _isGlobal = true;
  //private _taskDestination = (position _originObject) getPos [random 100, random 360];
  private _taskDestination = _markerPos;

  // Spacehunnie note: taskID's like "AST" ensure you don't have multiple active missions of a category
  [_taskID, [side_blue, civilian], [_description, _taskTitle, _marker], _taskDestination, _startState, _priority, _showNotification, _isGlobal, _taskType] call BIS_fnc_setTask;
};

// Do this only once per mission
_fnc_publishTask = {
  if (!params [["_task", "", [""]]]) exitwith {} ;
  misiones pushBack _task; // Spacehunnie note: misiones is the global list of missions 
  publicVariable "misiones"; // Spacehunnie note: sends the mission list to all clients
};

// Updates the task via _result and returns the taskID after updating the task
_fnc_resolveTask = {
  params ["_result"];
  diag_log "--Missions-- Resolving Traitor mission with result:";
  diag_log _result;
  private _initTaskWithState = "";

  switch (_result) do {
    case (_taskPlayerDiscoveredState): {
      _initTaskWithState = "AUTOASSIGNED";
      //hint "You have been discovered. The traitor is fleeing to the nearest base. Go and kill him!";
      { _x enableAI "MOVE"; } forEach units _traitorGroup;
      _traitorUnit assignAsDriver _vehicle;
      [_traitorUnit] orderGetin true;
      _wp0 = _traitorGroup addWaypoint [_vehiclePosition, 0];
      _wp0 setWaypointType "GETIN";
      _wp1 = _traitorGroup addWaypoint [_closestBaseMarkerPos, 1];
      _wp1 setWaypointType "MOVE";
      _wp1 setWaypointBehaviour "CARELESS";
      _wp1 setWaypointSpeed "FULL";
      diag_log "--MISSION--  Mission continuing!";
    };
    case (_taskSuccessState): { 
      _initTaskWithState = "SUCCEEDED";
      
      [0,3] remoteExec ["prestige",2];
      [0,300] remoteExec ["resourcesFIA",2];
      [5,stavros] call playerScoreAdd;
      //[10, clientowner] call playerScoreAdd; need to send the object not the ID
      diag_log "--MISSION--  Good job, soldier!";
    };
    case (_taskFailState): {      
      _initTaskWithState = "FAILED";  
      [-10,stavros] call playerScoreAdd;
      if (isPlayer Stavros) then {
        if (!("DEF_HQ" in misiones)) then {
          [] remoteExec ["ataqueHQ",HCattack];
        };
      } else {
        // some other punishment
      };
      diag_log "--MISSION--  Unfortunate!";
    };
    case (_taskExpiredState): {
      // should be same as discovered
    };
    default {};
  };

  private _description = [_marker, _result] call _fnc_getTaskDesciptionForState;
  [_houseObject, _description, _taskType, _initTaskWithState] call _fnc_updateTask;
};

_fnc_spawnVehicle = {
  params ["_vehicleType", "_targetPos"];
//  private _roads = [position _targetObject] call SH_fnc_getClosestRoads;
  private _roads = _targetPos nearRoads 100;
  diag_log "Closest Roads:";
  diag_log _roads;
  private _closestRoad = _roads select 0;
  diag_log _closestRoad;
  private _connectedRoads = roadsConnectedTo _closestRoad;
  private _vehicleDirection = [getPos (_connectedRoads select 0), getPos _closestRoad] call BIS_fnc_DirTo;
  private _vehiclePosition = [getPos _closestRoad, 3, _vehicleDirection + 90] call BIS_Fnc_relPos;

  _vehicle = _vehicleType createVehicle _vehiclePosition;
  _vehicle allowDamage false;
  _vehicle setDir _vehicleDirection;
  sleep 15;
  _vehicle allowDamage true;
  _vehicle;
};

_fnc_spawnPatrolGroup = {
  params ["_patrolCenter", "_dogChance"];
  // Spacehunnie note: This invisible marker is sent to UPSMON to define the patrol area for the group
  private _marker = createMarkerLocal [format ["%1patrolarea", floor random 100], _patrolCenter];
  _marker setMarkerShapeLocal "RECTANGLE";
  _marker setMarkerSizeLocal [50,50];
  _marker setMarkerTypeLocal "hd_warning";
  _marker setMarkerColorLocal "ColorRed";
  _marker setMarkerBrushLocal "DiagGrid";
  _marker setMarkerAlphaLocal 0;

  private _group = [_targetTraitorSpawnLocation, side_green, (cfgInf >> selectRandom infSquad)] call BIS_Fnc_spawnGroup;
  sleep 1;

  if (random 100 < _dogChance) then {
    private _perro = _group createUnit ["Fin_random_F", _patrolCenter, [], 0, "FORM"];
    [_perro] spawn guardDog;
  };
  _nul = [leader _group, _marker, "SAFE", "SPAWNED", "NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";
  { [_x] spawn genInitBASES } forEach units _group;
  _group;
};

// Create the task in the starting state and publish it
[[_houseObject, [_marker, _taskNewState] call _fnc_getTaskDesciptionForState, _taskType, _taskNewState ] call _fnc_updateTask] call _fnc_publishTask;

// SPAWN UNITS
private _locationsInsideHouse = [_houseObject] call BIS_fnc_buildingPositions;
diag_log "Locations in house:";
diag_log _locationsInsideHouse;
private _soldierPositions = [];

if ((count _locationsInsideHouse) < 2) then {
  _soldierPositions pushBack (_houseObject buildingExit 0);
} else {
  _soldierPositions pushBack (_locationsInsideHouse select 1);
};
_soldierPositions pushBack (_houseObject buildingExit 0);

_traitorGroup = createGroup side_red;



// Create the Traitor and his escorts
// Spacehunnie note: opI_x are predefined unit compositions
// OFF2 = Officer; SL = Squad Leader; RFL1 = Rifleman
private _traitorUnit = _traitorGroup createUnit [opI_OFF2, _locationsInsideHouse select 0, [], 0, "NONE"];
_traitorUnit allowDamage false;
private _traitorEscortSquadLeader = _traitorGroup createUnit [opI_SL, _soldierPositions select 0, [], 0, "NONE"];
private _traitorEscort = _traitorGroup createUnit [opI_RFL1, _soldierPositions select 1, [], 0, "NONE"];
_traitorGroup selectLeader _traitorUnit;

// Adds event handlers for AAF units
{_nul = [_x] spawn CSATinit; _x allowFleeing 0 } forEach units _traitorGroup;

private _vehicle = [opMRAPu, position _houseObject] call _fnc_spawnVehicle;

// Spacehunnie note: Keeps the traitor from getting accidentally killed by the spawning vehicle ? ?? Is this even required?
_traitorUnit allowDamage true; 
_nul = [_vehicle] spawn genVEHinit;

{_x disableAI "MOVE"; _x setUnitPos "UP"} forEach units _traitorGroup;

private _patrolGroup = [position _houseObject, 25] call _fnc_spawnPatrolGroup;

/// EVERYTHING BELOW IS WIN/LOSE CONDITION CODE
// First stop execution of script until the mission timer expires, the player is discovered, or the traitor dies
private _task = [];
waitUntil {sleep 1; (dateToNumber date > _taskExpireTimeFloat) or (not alive _traitorUnit) or ({_traitorUnit knowsAbout _x > 1.4} count ([500,0,_traitorUnit,"BLUFORSpawn"] call distanceUnits) > 0)};

// Spacehunnie note: will only trigger if the player is discovered, otherwise the script skips to the next wait until
if ({_traitorUnit knowsAbout _x > 1.4} count ([500,0,_traitorUnit,"BLUFORSpawn"] call distanceUnits) > 0) then {
  _task = [_taskPlayerDiscoveredState] call _fnc_resolveTask;
};

waitUntil  {sleep 1; (dateToNumber date > _taskExpireTimeFloat) or (not alive _traitorUnit) or (_traitorUnit distance _closestBaseMarkerPos < 20)};

if (not alive _traitorUnit) then {
  _task = [_taskSuccessState] call _fnc_resolveTask;
} else {
  if (dateToNumber date > _taskExpireTimeFloat) then {
    _task = [_taskExpiredState] call _fnc_resolveTask;
  } else {
    _task = [_taskFailState] call _fnc_resolveTask;
  };
};

// Spacehunnie note: Spawns a timer for the mission that deletes the mission when the timer expires

_nul = [1200, _task] spawn borrarTask;

if (_source == "civ") then {
  _val = server getVariable "civActive";
  server setVariable ["civActive", _val - 1, true];
};

waitUntil {sleep 1; !([distanciaSPWN,1,_vehicle,"BLUFORSpawn"] call distanceUnits)};

{
waitUntil {sleep 1; !([distanciaSPWN,1,_x,"BLUFORSpawn"] call distanceUnits)};
deleteVehicle _x
} forEach units _traitorGroup;
deleteGroup _traitorGroup;

{
waitUntil {sleep 1; !([distanciaSPWN,1,_x,"BLUFORSpawn"] call distanceUnits)};
deleteVehicle _x
} forEach units _patrolGroup;
deleteGroup _patrolGroup;

waitUntil {sleep 1; !([distanciaSPWN,1,_vehicle,"BLUFORSpawn"] call distanceUnits)};
deleteVehicle _vehicle;
