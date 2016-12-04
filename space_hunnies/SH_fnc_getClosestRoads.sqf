/**
 * Gets road locations within a radius around a position with incremental search capped at max radius.
 * Will guarantee that a road is found if max radius is 0 or nil
 *
 * Arguments:
 * 0: positionAGLS Target marker object, DEFAULT [0, 0, 0]
 * 1: (Optional) INT radius of initial search, DEFAULT 1
 * 2: (Optional) INT maximum radius to search, DEFAULT 0
 *
 * Return Value: The position of all road segments within the search radius
 *
 * Modifies Globals: None
 *
 * Example:
 *
 */
private _searchIncrement = 10;
private _defaultSearchRadius = 5;

if (!params [["_searchPosition", [0, 0, 0], [[]]], ["_startRadius", _defaultSearchRadius, 0], ["_maxRadius", 0, 0]]) exitWith {};

private _roads = [];
if !(_searchPosition isEqualTo [0, 0, 0]) then {
    while { count _roads == 0 && (_radius < _maxRadius && _maxRadius > 0) } do {
        _roads = _searchPosition nearRoads _radius;
        _radius = _radius + _searchIncrement;
    };
};
_roads