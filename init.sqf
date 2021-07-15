// given from editor
// marker, area, marker_base (air base or fob with room for heli operation)
// vehicle, ah9
// man, player

// create zone_base trigger from the marker_base marker that was placed in editor
"marker_base" setMarkerAlpha 0; // hide the base marker
zone_base = [objNull, "marker_base"] call BIS_fnc_triggerToMarker; // yes this fnc name is backward
zone_base setTriggerActivation ["ANYPLAYER", "PRESENT", true]; // true=repeatable
zone_base setTriggerTimeout [2,2,2,true]; // true=interruptable=timeoutmode, false=noninterruptable=countdownmode
zone_base setTriggerStatements [
	"this", // condition
	"call fn_enter_base;", // activation
	"call fn_leave_base;" // deactivation
];
fn_enter_base = {
	hint "Entering friendly airspace.";
};
fn_leave_base = {
	hint "Leaving friendly airspace.";
	has_left_base = true; // only want to set this once on first departure
};



// =============================================================================
// TODO

// create zone - enemy spawn
// create zone - enemy clearance (a bit bigger than spawn)
// create waypoint - player group, seek and destroy

// spawn targets
// add patrol routes to targets

// mission features
// notif: leaving base
// refit when landed at base

// mission logic
// targets eliminated
// landed at base after targets eliminated

