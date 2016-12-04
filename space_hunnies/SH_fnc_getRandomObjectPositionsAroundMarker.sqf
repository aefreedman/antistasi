/**
 * Gets the specified number of positions for objects of type around a marker
 *
 * Arguments:
 * 0: STRING Target marker object, DEFAULT "", if empty will exit
 * 1: STRING Type of object to search for, DEFAULT ""
 * 2: INT Maximum number of positions to return, DEFAULT 1
 * 3: INT Radius around marker to search, DEFAULT sizeMarker return value
 *
 * Return Value: Array of positions
 *
 * Modifies Globals: None
 *
 * Example:
 *
 */

if (!params [["_targetMarker", "", [""]], ["_objectType", "", [""]] , ["_numberOfPositions", 1, [0]], ["_searchRadius", 0, [0]]]) exitWith {};

if (_targetMarker == "") exitWith {
    diag_log "[SH] Something attempted to search a position but didn't pass a target location!"
};

// _searchRadius is only 0 by default
if (_searchRadius == 0) then {
    _searchRadius = [_targetMarker] call sizeMarker;
};

private _objects = [];
if (_objectType != "") then { 
    objects = getMarkerPos _targetMarker nearObjects [_objectType, _searchRadius];
} else {
    objects = getMarkerPos _targetMarker nearObjects _searchRadius;
};

private _objectPositions = [];

for "_i" from 0 to _numberOfPositions min count _objects do {
    _objectPositions pushBack position objects select _i;
};

_objectPositions