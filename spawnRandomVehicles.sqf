/*

This script spawns random vehicles on roads in a specified area.
Originally for helicopter practice: target id, engagement, and evasion.

Usage:
Create a new mission in the Arma Editor and save it.
Copy this script into the mission folder.
Add a marker area object and configure it to cover area of desired vehicle spawns.
Add a game logic object with this init line:
    _handle = [side, marker, density, civs, crewed, tasked, marked] execVM "spawnRandomVehicles.sqf";
Where:
    side (str) = faction of vehicles, either "blue" or "red"
    marker (str) = variable name of the marker area
    density (int) = minimun distance between vehicles in meters
    civs (bool) = include some civilian vehicles
    crewed (bool) = add crew to each vehicle
    tasked (bool) = add a random move waypoint and drive back and forth 
    marked (bool)] = add map marks for each vehicle
Example:
    _rz = [40,"red","redzone",20,true,true,false] execVM "spawnRandomVehicles.sqf";

*/

if (!isServer) exitWith {}; // exit if not server

params [
    "_side",
    "_markerName",
    "_density",
    "_includeCivs",
    "_crewed",
    "_tasked",
    "_marked"
];

// base vehicle lists
_milBlue = ["B_G_Van_01_fuel_F","B_Truck_01_fuel_F","B_Truck_01_transport_F"]; // unarmed
_milBlue append ["B_G_Offroad_01_armed_F","B_LSV_01_armed_F","B_MRAP_01_hmg_F"]; // armed
_milRed = ["O_Truck_02_fuel_F","O_Truck_03_fuel_F","O_Truck_03_transport_F","O_Truck_02_transport_F"]; // unarmed
_milRed append ["O_G_Offroad_01_armed_F","O_MRAP_02_hmg_F","O_LSV_02_armed_F"]; //armed
_civCiv = ["C_Hatchback_01_F","C_Offroad_01_F","C_Offroad_02_unarmed_F","C_Van_01_box_F","C_Truck_02_transport_F","C_Tractor_01_F"];

// build array of available vehicles
_vehicles = [];
if (_side == "blue") then {_vehicles append _milBlue;};
if (_side == "red") then {_vehicles append _milRed;};
if (_includeCivs) then {_vehicles append _civCiv};

// collect road segments within marker area
_markerPos = getMarkerPos _markerName;
_markerSize = getMarkerSize _markerName select 0;
_roadSegments = _markerPos nearRoads _markerSize;

// calculate vehicle count based on zone size, approx 1 per 2 sq km
_vehicleCount = ceil (((_markerSize*2/1000)^2)/2);

// spawn vehicles
for "_i" from 1 to _vehicleCount do {
    scopeName "spawner";
    
    // select a random road segment that is clear
    _roadSeg = selectRandom _roadSegments;
    _tries = 1;
    while {count (nearestObjects [_roadSeg, ["Car","Truck","APC","Tank"], _density]) > 0} do {
        _roadSeg = selectRandom _roadSegments;
        _tries = _tries + 1;
        if (_tries > 20) then {
            hint format ["Spawned %1 out of %2 requested vehicles.",_i,_vehicleCount];
            breakOut "spawner";
        };
    };
    
    // use an adjacent road segment to align the vehicle to the road
    _connectedSegs = roadsConnectedTo _roadSeg;
    _vDirection = random(360);
    if (count _connectedSegs > 0) then {
        _vDirection = _roadSeg getDir (_connectedSegs select 0);
    };
    
    // select a random vehicle type
    _newType = selectRandom _vehicles;
    
    // spawn and rotate the new vehicle
    _vehicle = _newType createVehicle getPosATL(_roadSeg);
    _vehicle setDir _vDirection;
    
    // option - marked
    if (_marked) then {
        _vmarker = ["loc_Truck", format ["%1",_i], _roadSeg] call BIS_fnc_markerCreate;
    };
    
    // option - crewed
    if (_crewed) then {
        
        // create vehicle crew
        _vcrew = createVehicleCrew _vehicle;
        
        // make the crew bad at shooting (bad aim = more heli practice)
        {_x setSkill ["aimingSpeed", 0.05];} forEach units _vcrew;
        
        // option - tasked
        if (_tasked) then {
        
            // pick a road destination within 1km
            _wpRoadSegments = _roadSeg nearRoads 1000;
            _p0 = selectRandom _wpRoadSegments;
            
            // add waypoint at origin
            _wp0 = _vcrew addWaypoint [_roadSeg,0];
            _wp0 setWaypointType "MOVE";
            
            // add waypoint at destination
            _wp1 = _vcrew addWaypoint [_p0,0];
            _wp1 setWaypointType "MOVE";
            
            // add cycle waypoint to force loop
            _wp2 = _vcrew addWaypoint [_p0 getPos [50,0],0];
            _wp2 setWaypointType "CYCLE";
        };
    };    
};
