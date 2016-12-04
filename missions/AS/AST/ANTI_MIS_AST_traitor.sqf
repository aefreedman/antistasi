params ["_marker", "_source"];

//Spacehunnie note : should only execute for the host/server (?)
if (!isServer and hasInterface) exitWith{};

// "Civ" is passed as param if you requested the mission from Petros or a civilian
if (_source == "civ") then {
  server setVariable ["civActive", server getVariable "civActive" + 1, true];
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
//private _houseObject = _marker nearObjects ["house", _houseSearchRadius];
private _houseObject = _marker call CBA_fnc_getNearestBuilding;

private _taskExpireTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + _taskTimeLimitMins];
private _taskExpireTimeFloat = dateToNumber _taskExpireTime;

_fnc_getTaskDesciptionForState = {
  params ["_marker", "_taskState"];
  // Spacehunnie note: func "localizar" gets a string that describes the marker location e.g. "Outpost"
  private _markerDescription = [_marker] call localizar; 
  private _descriptionString = "";
  switch (_taskState) do {
    case _taskNewState: { _descriptionString = _taskDesciptionStart };
    case _taskPlayerDiscoveredState: { _descriptionString = _taskDesciptionDiscovered };
    case _taskSuccessState: { _descriptionString = _taskDesciptionSuccess };
    case _taskFailState: { _descriptionString = _taskDesciptionFailure };
    default { "" };
  };
  [format [_descriptionString,_markerDescription,numberToDate [2035,_taskExpireTimeFloat] select 3,numberToDate [2035,_taskExpireTimeFloat] select 4], _taskTitle, _marker]
};

/** Shortcut function to create the task for this mission 
*/
_fnc_updateTask = {
  params ["_origin", "_description", "_taskType", "_startState"];
  private _priority = 5;
  private _showNotification = true;
  private _isGlobal = true;
  private _taskOwner = [side_blue, civilian]; // Spacehunnie note: why is the civilian group an owner of this task?
  private _taskDestination = _origin getPos [random 100, random 360];

  // Spacehunnie note: taskID's like "AST" ensure you don't have multiple active missions of a category
  [_taskID, _taskOwner, _description, _taskDestination, _startState, _priority, _showNotification, _isGlobal, _taskType] call BIS_fnc_setTask
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
  private _taskStartState = "";
  switch (_result) do {
    case _taskPlayerDiscoveredState || _taskExpiredState: {
      _taskStartState = "AUTOASSIGNED";
      //hint "You have been discovered. The traitor is fleeing to the nearest base. Go and kill him!";
      { _x enableAI "MOVE"; } forEach units _traitorGroup;
      _traitorUnit assignAsDriver _vehicle;
      [_traitorUnit] orderGetin true;
      _wp0 = _traitorGroup addWaypoint [_vehiclePosition, 0];
      _wp0 setWaypointType "GETIN";
      _wp1 = _traitorGroup addWaypoint [_closestBase,1];
      _wp1 setWaypointType "MOVE";
      _wp1 setWaypointBehaviour "CARELESS";
      _wp1 setWaypointSpeed "FULL";
    };
    case _taskSuccessState: { 
      _taskStartState = "SUCCEEDED";
      
      [0,3] remoteExec ["prestige",2];
      [0,300] remoteExec ["resourcesFIA",2];
      [5,stavros] call playerScoreAdd;
      [10, clientowner] call playerScoreAdd;
    };
    case _taskFailState: {      
      _taskStartState = "FAILED";  
      [-10,stavros] call playerScoreAdd;
      if (isPlayer Stavros) then {
        if (!("DEF_HQ" in misiones)) then {
          [] remoteExec ["ataqueHQ",HCattack];
        };
      } else {
        _minasFIA = allmines - (detectedMines side_red);
        if (count _minasFIA > 0) then {
          {if (random 100 < 30) then {side_red revealMine _x;}} forEach _minasFIA;
        };
      };
    };
    default { _task = ""; };
  };
  [position _houseObject, [_marker, _result] _fnc_getTaskDesciptionForState, _taskType, _taskStartState] _fnc_updateTask
};

_fnc_spawnVehicle = {
  param ["_vehicleType", "_targetObject"];
  private _road = [_targetObject] SH_fnc_getClosestRoad select 0;
  private _vehicleDirection = [getPos (roadsConnectedto _road select 0), getPos _road] call BIS_fnc_DirTo;
  private _vehiclePosition = [getPos _road, 3, _vehicleDirection + 90] call BIS_Fnc_relPos;

  _vehicle = _vehicleType createVehicle _vehiclePosition;
  _vehicle allowDamage false;
  _vehicle setDir _vehicleDirection;
  sleep 15;
  _vehicle allowDamage true;
  _vehicle
};

_fnc_spawnPatrolGroup = {
  params [["_patrolCenter", [], [[]], 3], ["_dogChance", 0, 0]];
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
  _group
};

// Create the task in the starting state and publish it
[[position _houseObject, [_marker, _taskNewState] _fnc_getTaskDesciptionForState, _taskType, "AUTOASSIGN" ] _fnc_updateTask] _fnc_publishTask;

// SPAWN UNITS
private _locationsInsideHouse = _houseObject call BIS_fnc_buildingPositions;
private _soldierPositions = [];

if (count _locationsInsideHouse < 2) then {
  _soldierPositions pushBack _houseObject buildingExit 0;
} else {
  _soldierPositions pushBack _locationsInsideHouse select 1;
};
_soldierPositions pushBack _houseObject buildingExit 0;

_traitorGroup = createGroup side_red;

// Traitor "runaway base" location setup
// Spacehunnie note: mrkFIA is a global for "FIA Markers"
private _closestBaseToTraitor = [[bases - mrkFIA], _targetTraitorSpawnLocation] call BIS_Fnc_nearestPosition;
private _closestBase = getMarkerPos _closestBaseToTraitor;

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

private _vehicle = [opMRAPu, _houseObject] _fnc_spawnVehicle;

// Spacehunnie note: Keeps the traitor from getting accidentally killed by the spawning vehicle ? ?? Is this even required?
_traitorUnit allowDamage true; 
_nul = [_vehicle] spawn genVEHinit;

{_x disableAI "MOVE"; _x setUnitPos "UP"} forEach units _traitorGroup;

private _patrolGroup = [getPos _houseObject, 25] _fnc_spawnPatrolGroup;

/// EVERYTHING BELOW IS WIN/LOSE CONDITION CODE
// First stop execution of script until the mission timer expires, the player is discovered, or the traitor dies
private _task = [];
waitUntil {sleep 1; (dateToNumber date > _taskExpireTimeFloat) or (not alive _traitorUnit) or ({_traitorUnit knowsAbout _x > 1.4} count ([500,0,_traitorUnit,"BLUFORSpawn"] call distanceUnits) > 0)};

// Spacehunnie note: will only trigger if the player is discovered, otherwise the script skips to the next wait until
if ({_traitorUnit knowsAbout _x > 1.4} count ([500,0,_traitorUnit,"BLUFORSpawn"] call distanceUnits) > 0) then {
  _task = [_taskPlayerDiscoveredState] _fnc_resolveTask;
};

waitUntil  {sleep 1; (dateToNumber date > _taskExpireTimeFloat) or (not alive _traitorUnit) or (_traitorUnit distance _closestBase < 20)};

if (not alive _traitorUnit) then {
  _task = [_taskSuccessState] _fnc_resolveTask;
} else {
  if (dateToNumber date > _taskExpireTimeFloat) then {
    _task = [_taskExpiredState] _fnc_resolveTask;
  } else {
    _task = [_taskFailState] _fnc_resolveTask;
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
