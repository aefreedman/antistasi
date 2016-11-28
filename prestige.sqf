private ["_nato","_csat"];

waitUntil {!prestigeIsChanging};
prestigeIsChanging = true;
_nato = _this select 0;
_csat = _this select 1;

_natoT = server getVariable "prestigeNATO";
_csatT = server getVariable "prestigeCSAT";

_natoT = _natoT + _nato;
_csatT = _csatT + _csat;

if (_natoT < 0) then {_natoT = 0};
if (_natoT > 100) then {_natoT = 100};
if (_csatT < 0) then {_csatT = 0};
if (_csatT > 100) then {_csatT = 100};


if (_nato != 0) then {server setVariable ["prestigeNATO",_natoT,true]};
if (_csat != 0) then {server setVariable ["prestigeCSAT",_csatT,true]};
prestigeIsChanging = false;

_texto = "";
_natoSim = "";
if (_nato > 0) then {_natoSim = "+"};

_csatSim = "";
if (_csat > 0) then {_castSim = "+"};
if ((_nato != 0) and (_csat != 0)) then
	{
	_texto = format ["<t size='0.6' color='#C1C0BB'>Prestige Change.<br/> <t size='0.5' color='#C1C0BB'><br/>NATO: %3%1<br/>CSAT: %4%2",_nato,_csat,_natoSim,_csatSim]
	}
else
	{
	if (_nato != 0) then {_texto = format ["<t size='0.6' color='#C1C0BB'>Prestige Change.<br/> <t size='0.5' color='#C1C0BB'><br/>NATO: %3%1",_nato,_csat,_natoSim]} else {_texto = format ["<t size='0.6' color='#C1C0BB'>Prestige Change.<br/> <t size='0.5' color='#C1C0BB'><br/>CSAT: %4%2",_nato,_csat,_natoSim,_csatSim]};
	};

if (_texto != "") then {[petros,"income",_texto] remoteExec ["commsMP",stavros]};
