if !(isServer) exitWith {};

_vehicles = [
"I_MRAP_03_F",
"I_MRAP_03_hmg_F",
"I_MRAP_03_gmg_F",
"I_APC_Wheeled_03_cannon_F",
"I_APC_tracked_03_cannon_F",
"I_MBT_03_cannon_F"
];

_textures = [
["dgc\dgc_fiaveh\data\mrap03\mrap_03_ext_fia_co.paa"],
["dgc\dgc_fiaveh\data\mrap03\mrap_03_ext_fia_co.paa","dgc\dgc_fiaveh\data\mrap03\turret_co.paa"],
["dgc\dgc_fiaveh\data\mrap03\mrap_03_ext_fia_co.paa","dgc\dgc_fiaveh\data\mrap03\turret_co.paa"],
["dgc\dgc_fiaveh\data\afv4\APC_Wheeled_03_Ext_fia_CO.paa","dgc\dgc_fiaveh\data\afv4\APC_Wheeled_03_Ext2_fia_CO.paa","dgc\dgc_fiaveh\data\afv4\RCWS30_fia_CO.paa","A3\armor_f_gamma\APC_Wheeled_03\data\APC_Wheeled_03_Ext_alpha_CO.paa"],
["dgc\dgc_fiaveh\data\fv720\apc_tracked_03_ext_fia_co.paa","dgc\dgc_fiaveh\data\fv720\apc_tracked_03_ext2_fia_co.paa"],
["dgc\dgc_fiaveh\data\mbt52\mbt_03_ext01_fia_co.paa","dgc\dgc_fiaveh\data\mbt52\mbt_03_ext02_fia_co.paa","dgc\dgc_fiaveh\data\mbt52\mbt_03_rcws_fia_co.paa"]
];

_texturedVehicles = [];
for "_i" from 0 to (count _vehicles - 1) do {
  _s = (_vehicles select _i) + "_customTextures";
  diag_log _s;
  server setVariable [_s , _textures select _i, true];
};