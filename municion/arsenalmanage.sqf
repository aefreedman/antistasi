#include "globals.hpp"

if (!isServer) exitWith {};
private ["_armasInInventory","_armasInInventoryNoAttachments","_addedWeapons","_lockedWeapon","_armasFinal","_precio","_arma","_armaTrad","_priceAdd","_updated","_magazinesInInventory","_addedMagazines","_magazine","_magazinesFinal","_itemsInInventory","_addedItems","_item","_cuenta","_itemsFinal","_mochisInInventory","_mochisTrad","_addedMochis","_lockedMochi","_mochisFinal","_mochi","_mochiTrad","_armasAttachments","_armaConCosa"];

_updated = "";

_armasInInventory = weaponCargo caja;
_mochisInInventory = backpackCargo caja;
_magazinesInInventory = magazineCargo caja;
_itemsInInventory = itemCargo caja;

_fabricas = count (fabricas - mrkAAF);

_addedMagazines = [];
_fnc_attemptMagazineUnlock = {
	params ["_magazine"];
  if !(_magazine in unlockedMagazines) then {
		private _required_mags_to_unlock = BASE_MAG_UNLOCK + (count unlockedMagazines) - unlockedMagazinesInitial - (FACTORY_BONUS*_fabricas);
    if ({ _x == _magazine } count _magazinesInInventory >= _required_mags_to_unlock) then {
			_addedMagazines pushBackUnique _magazine;
			unlockedMagazines pushBackUnique _magazine;
			_updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgMagazines" >> _magazine >> "displayName")];
		};
	};
};
{ [_x] call _fnc_attemptMagazineUnlock } forEach allMagazines;

// Turn our list of armas-in-inventory into a list of base weapon classes.
// Removes attachments from classname basically.
_armasInInventoryNoAttachments = _armasInInventory apply { _x call BIS_fnc_baseWeapon };

_addedWeapons = [];
_fnc_attemptWeaponUnlock = {
	params ["_lockedWeapon"];
	if !(_lockedWeapon in unlockedWeapons) then {
		private _required_weps_to_unlock = BASE_WEP_UNLOCK + (count unlockedWeapons) - unlockedWeaponsInitial -  (FACTORY_BONUS*_fabricas);
		private _magazines = getArray (configFile / "CfgWeapons" / _x / "magazines");
		private _has_enough_to_unlock = {_x == _lockedWeapon} count _armasInInventoryNoAttachments >= _required_weps_to_unlock;
		private _unlocked_mags = unlockedMagazines arrayIntersect _magazines;
		if (_has_enough_to_unlock && !(_unlocked_mags isEqualTo [])) then {
			_addedWeapons pushBackUnique _lockedWeapon;
			unlockedWeapons pushBackUnique _lockedWeapon;
			_updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgWeapons" >> _lockedWeapon >> "displayName")];
		};
	};
};
{ [_x] call _fnc_attemptWeaponUnlock; } forEach lockedWeapons;


if (count _addedMagazines > 0) then {
	// XLA fixed arsenal
	if (hayXLA) then {
		[caja,_addedMagazines,true,false] call XLA_fnc_addVirtualMagazineCargo;
	} else {
		[caja,_addedMagazines,true,false] call BIS_fnc_addVirtualMagazineCargo;
	};
	publicVariable "unlockedMagazines";
};

if (count _addedWeapons > 0) then {
	lockedWeapons = lockedWeapons - _addedWeapons;
	// XLA fixed arsenal
	if (hayXLA) then {
		[caja,_addedWeapons,true,false] call XLA_fnc_addVirtualWeaponCargo;
	} else {
		[caja,_addedWeapons,true,false] call BIS_fnc_addVirtualWeaponCargo;
	};
	publicVariable "unlockedWeapons";
	[_addedWeapons] spawn weaponCheck;
};

_magazinesFinal = []; // Magazines in inventory that are not unlocked
{
	if (not(_x in unlockedMagazines)) then {
		_magazinesFinal pushBack _x;
	};
} forEach _magazinesInInventory;

_armasFinal = []; // contains weapons not unlocked
_armasAttachments = weaponsItems caja;

// for each arma in inventory...
// push not unlocked weapons in armasFinal
// add unlocked weapons attachments to the itemsInInventory list
for "_i" from 0 to (count _armasInInventory) - 1 do {
	_arma = _armasInInventory select _i; //classname WITH attachment
	_armaTrad = _armasInInventoryNoAttachments select _i; //classname WITHOUT attachments
	if !(_armaTrad in unlockedWeapons) then {
		_armasFinal pushBack _arma;
	} else { // this weapon is unlocked
		if (_arma != _armaTrad) then { // if the arma has attachments
			_armaConCosa = _armasAttachments select _i; // get attachments for this gun
			if ((_armaConCosa select 0) == _arma) then {
				{
				  if (typeName _x != typeName []) then {_itemsInInventory pushBack _x};
				} forEach (_armaConCosa - [_arma]);
			};
		};
	};
};

// prepare list of base-classes of backpacks
_mochisTrad = _mochisInInventory apply { _x call BIS_fnc_basicBackpack };

_addedMochis = [];
_fnc_attemptMochiUnlock = {
	params ["_lockedMochi"];
	private _required_mochis_to_unlock = BASE_MOCHI_UNLOCK + (count unlockedBackpacks) - unlockedBackpacksInitial - (FACTORY_BONUS*_fabricas);
  if ({_x == _lockedMochi} count _mochisTrad >= _required_mochis_to_unlock) then {
	  _addedMochis pushBackUnique _lockedMochi;
	  _updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgVehicles" >> _lockedMochi >> "displayName")];
	};
};
{ [_x] call _fnc_attemptMochiUnlock; } forEach lockedMochis;

// set unlocked/locked globals and update crate
if (count _addedMochis > 0) then {
	lockedMochis = lockedMochis - _addedMochis; //verificar si tiene que ser pública
	// XLA fixed arsenal
	if (hayXLA) then {
		[caja,_addedMochis,true,false] call XLA_fnc_addVirtualBackpackCargo;
	} else {
		[caja,_addedMochis,true,false] call BIS_fnc_addVirtualBackpackCargo;
	};
	unlockedBackpacks = unlockedBackpacks + _addedMochis;
	publicVariable "unlockedBackpacks";
};

// Like armasFinal, contains mochi classes that are not let unlocked
_mochisFinal = [];
for "_i" from 0 to (count _mochisInInventory) - 1 do {
	_mochi = _mochisInInventory select _i;
	_mochiTrad = _mochisTrad select _i;
	if !(_mochiTrad in unlockedBackpacks) then {
		_mochisFinal pushBack _mochi;
	};
};

_addedItems = [];
_fnc_attemptItemUnlock = {
	params["_item"];
  if !(_item in unlockedItems) then {
		private _required_vests_to_unlock = BASE_VEST_UNLOCK + (count unlockedItems) - unlockedItemsInitial - (FACTORY_BONUS*_fabricas);
		if ((_item in vests) && ({_x == _item} count _itemsInInventory >= _required_vests_to_unlock)) then {
			_addedItems pushBackUnique _item;
			unlockedItems pushBackUnique _item;
			_updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgWeapons" >> _item >> "displayName")];
		} else {
			private _required_optics_to_unlock = BASE_OPTIC_UNLOCK + (count unlockedItems) - unlockedOpticsInitial - (FACTORY_BONUS*_fabricas);
			if ((_item in opticasAAF) && {_x == _item} count _itemsInInventory >= _required_optics_to_unlock) then {
				_addedItems pushBackUnique _item;
				unlockedItems pushBackUnique _item;
				unlockedOptics pushBackUnique _item; publicVariable "unlockedOptics";
				_updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgWeapons" >> _item >> "displayName")];
			} else {
				private _required_items_to_unlock = BASE_ITEM_UNLOCK + (count unlockedItems) - unlockedItemsInitial - (FACTORY_BONUS*_fabricas);
				if ({_x == _item} count _itemsInInventory >= _required_items_to_unlock) then  {
					_addedItems pushBackUnique _item;
					unlockedItems pushBackUnique _item;
					_updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgWeapons" >> _item >> "displayName")];
				};
			};
		};
	};
};
{ [_x] call _fnc_attemptItemUnlock; } forEach allItems + ["bipod_01_F_snd","bipod_01_F_blk","bipod_01_F_mtp","bipod_02_F_blk","bipod_02_F_tan","bipod_02_F_hex","bipod_03_F_blk","B_UavTerminal"] + bluItems - ["NVGoggles","Laserdesignator"];

if !("NVGoggles" in unlockedItems) then {
	private _required_nvgs_to_unlock = BASE_NVG_UNLOCK - (FACTORY_BONUS*_fabricas);
	if ({(_x == "NVGoggles") or (_x == "NVGoggles_OPFOR") or (_x == "NVGoggles_INDEP") or (_x == indNVG)} count itemCargo caja >= _required_nvgs_to_unlock) then {
		_addedItems = _addedItems + ["NVGoggles","NVGoggles_OPFOR","NVGoggles_INDEP"];
		unlockedItems = unlockedItems + ["NVGoggles","NVGoggles_OPFOR","NVGoggles_INDEP",indNVG];
		_updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgWeapons" >> "NVGoggles" >> "displayName")];
	};
};

if !("Laserdesignator" in unlockedItems) then {
	private _required_designators_to_unlock = BASE_DESIGNATOR_UNLOCK - (FACTORY_BONUS*_fabricas);
	if ({(_x == "Laserdesignator") or (_x == "Laserdesignator_02") or (_x == "Laserdesignator_03")} count itemCargo caja >= _required_designators_to_unlock) then {
	_addedItems pushBack "Laserdesignator";
	unlockedItems pushBack "Laserdesignator";
	_updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgWeapons" >> "Laserdesignator" >> "displayName")];
	};
};

if !("Rangefinder" in unlockedItems) then {
	private _required_rangefinders_to_unlock = BASE_RANGEFINDER_UNLOCK - (FACTORY_BONUS*_fabricas);
	if ({(_x == "Rangefinder")} count weaponCargo caja >= _required_rangefinders_to_unlock) then {
		_addedItems pushBack "Rangefinder";
		unlockedItems pushBack "Rangefinder";
		_updated = format ["%1%2<br/>",_updated,getText (configFile >> "CfgWeapons" >> "Rangefinder" >> "displayName")];
	};
};

if ((hayACE) && ("ItemGPS" in unlockedItems)) then {
	unlockedItems pushBackUnique "ACE_DAGR";
};

if (count _addedItems > 0) then {
  // XLA fixed arsenal
	if (hayXLA) then {
		[caja,_addedItems,true,false] call XLA_fnc_addVirtualItemCargo;
	} else {
		[caja,_addedItems,true,false] call BIS_fnc_addVirtualItemCargo;
	};
	publicVariable "unlockedItems";
};

_itemsFinal = [];
for "_i" from 0 to (count _itemsInInventory) - 1 do {
	_item = _itemsInInventory select _i;
	if !(_item in unlockedItems) then {
		if ((_item == "NVGoggles_OPFOR") or (_item == "NVGoggles_INDEP")) then {
			if !("NVGoggles" in unlockedItems) then {
 				_itemsFinal pushBack _item;
			} else {
				if ((_item == "Laserdesignator_02") or (_item == "Laserdesignator_03")) then {
					if (not("Laserdesignator" in unlockedItems)) then {
						_itemsFinal pushBack _item;
					};
				} else {
					// experimental: if item not unlocked and not TFAR radio, add to ammo box
					if !(toLower _item find "tf_anprc152" >= 0) then {_itemsFinal pushBack _item};
				};
			};
		};
	};
};

//[0,_precio] remoteExec ["resourcesFIA",2];

// Remove things from the inventory which have been unlocked, add back in with
// the various _Final vars
if (count _armasInInventory != count _armasFinal) then {
	clearWeaponCargoGlobal caja;
	{caja addWeaponCargoGlobal [_x,1]} forEach _armasFinal;
	unlockedRifles = unlockedweapons -  hguns -  mlaunchers - rlaunchers - ["Binocular","Laserdesignator","Rangefinder"] - srifles - mguns;
	publicVariable "unlockedRifles";
};
if (count _mochisInInventory != count _mochisFinal) then {
	clearBackpackCargoGlobal caja;
	{caja addBackpackCargoGlobal [_x,1]} forEach _mochisFinal;
};
if (count _magazinesInInventory != count _magazinesFinal) then {
	clearMagazineCargoGlobal caja;
	{caja addMagazineCargoGlobal [_x,1]} forEach _magazinesFinal;
};
if (count _itemsInInventory != count _itemsFinal) then {
	clearItemCargoGlobal caja;
	{caja addItemCargoGlobal [_x,1]} forEach _itemsFinal;
};

publicVariable "unlockedWeapons";
publicVariable "unlockedRifles";
publicVariable "unlockedItems";
publicVariable "unlockedOptics";
publicVariable "unlockedBackpacks";
publicVariable "unlockedMagazines";

_updated
