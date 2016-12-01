_crate4 = "Box_NATO_WpsSpecial_F" createVehicle (position player);
_nul = [_crate4] call emptyCrate;

_weapons = lockedWeapons - vanillaWeapons;
_accessories = allAccessories - vanillaAccessories;

for [{_i=1},{_i<=5},{_i=_i+1}] do {
  _cosa = _weapons call BIS_Fnc_selectRandom;
  _num = 1 + (floor random 5);
  _crate4 addItemCargoGlobal [_cosa, _num];
  _magazines = getArray (configFile / "CfgWeapons" / _cosa / "magazines");
  _crate4 addMagazineCargoGlobal [_magazines select 0, _num * 3];
};

for [{_i=1},{_i<=3},{_i=_i+1}] do {
  _cosa = _accessories call BIS_Fnc_selectRandom;
  _num = 1 + (floor random 5);
  _crate4 addItemCargoGlobal [_cosa, _num];
};