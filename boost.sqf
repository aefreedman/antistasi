if (!isServer) exitWith{};

scriptName "boost";

server setVariable ["hr",200,true];
server setVariable ["resourcesFIA",100000,true];
server setVariable ["prestigeNATO",80,true];

{ unlockedWeapons pushBackUnique _x; } forEach genWeapons;
{ unlockedWeapons pushBackUnique _x; } forEach genLaunchers;

{ unlockedMagazines pushBackUnique _x; } forEach genAmmo;
{ unlockedMagazines pushBackUnique _x; } forEach genMissiles;
{ unlockedMagazines pushBackUnique _x; } forEach genMines;

{ unlockedItems pushBackUnique _x; } forEach genVests;
{ unlockedItems pushBackUnique _x; } forEach genHelmets;
{ unlockedItems pushBackUnique _x; } forEach genItems;
{ unlockedItems pushBackUnique _x; } forEach genOptics;
{ unlockedItems pushBackUnique _x; } forEach bluItems;

publicVariable "unlockedWeapons";
publicVariable "unlockedMagazines";
publicVariable "unlockedItems";

if (hayXLA) then {
	[caja,unlockedWeapons,true,false] call XLA_fnc_addVirtualWeaponCargo;
	[caja,unlockedMagazines,true,false] call XLA_fnc_addVirtualMagazineCargo;
	[caja,unlockedItems,true,false] call XLA_fnc_addVirtualItemCargo;
} else {
	[caja,unlockedWeapons,true,false] call BIS_fnc_addVirtualWeaponCargo;
	[caja,unlockedMagazines,true,false] call BIS_fnc_addVirtualMagazineCargo;
	[caja,unlockedItems,true,false] call BIS_fnc_addVirtualItemCargo;
};

[unlockedWeapons] call weaponCheck;
