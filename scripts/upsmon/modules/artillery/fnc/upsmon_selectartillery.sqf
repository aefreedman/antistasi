/****************************************************************
File: UPSMON_selectartillery.sqf
Author: Azroul13

Description:
	Select the artillery that has ammunition and are near the group.

Parameter(s):
	<--- Artillery groups array
	<--- type of round ("HE","WP","ILLUM")
	<--- position of the leader of the group
Returns:
	Artillery group
****************************************************************/

private ["_artillerysidegrps","_askMission","_RadioRange","_npcpos","_roundsask","_targetpos","_area","_artilleryunit","_rounds","_artiarray","_arti","_vehicledemo"];

params ["_artillerysidegrps", "_askMission", "_RadioRange", "_npcpos", "_roundsask", "_targetpos", "_area"];

_artilleryunit = ObjNull;
_artiarray = [_artillerysidegrps, [], { _npcpos vectorDistance (leader _x) }, "ASCEND"] call BIS_fnc_sortBy;
{
	_arti = _x;

	if (count (units _x) > 0) then {
		if (count (_grp getvariable ["UPSMON_Battery",[]]) > 0) then {
			if ((round([getposATL (leader _arti),_npcpos] call UPSMON_distancePosSqr)) <= _RadioRange) then {
				if !(_grp getVariable ["UPSMON_ArtiBusy",false]) then {
					_result = [0,ObjNull,0,0];
					_vehicledemo = (_grp getvariable ["UPSMON_Battery",[]]) select 0;

					if (count (_grp getvariable ["UPSMON_Mortarmun",[]]) > 0) then {
						if (typename ((_grp getvariable ["UPSMON_Battery",[]])select 0) == "ARRAY") then {
							_backpack = backpack (_vehicledemo select 0);
							_vehicledemo = ([_backpack] call UPSMON_checkbackpack) select 0;
							_result = [_askMission,_vehicledemo] call UPSMON_getmuninfos;
						}	else {
							_result = [_askmission,typeof _vehicledemo] call UPSMON_getmuninfosbackpack;
						};
					} else {
						_result = [_askMission,(_grp getvariable ["UPSMON_Battery",[]])] call UPSMON_getmuninfos;
					};

					if ((_result select 0) > 0) then {
						if ((_targetPos inRangeOfArtillery [_vehicledemo, _result select 1])) then {
							_side = side _arti;
							_alliednear = [_targetpos,_result select 2,_side] call UPSMON_Splashzone;

							if (!_alliednear) exitwith {
								_grp getVariable ["UPSMON_ArtiBusy",true];
								_arti setvariable ["UPSMON_Artifiremission",[_targetPos,_askmission,_roundsask,_area]];
							};
						};
					};
				};
			};
		};
	};

	if (UPSMON_Debug>0) then {
		diag_log format ["Busy:%1 Distance:%2 RadioRange:%3 Rounds:%4",_artibusy,leader _x distance _npcpos,_RadioRange,_rounds];
	};
} forEach _artiarray;
