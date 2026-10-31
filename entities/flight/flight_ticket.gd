class_name FlightTicket
extends RefCounted
## What a rocket flight leaves for the next world (owner #79, #87), kept small so the menu and the boot can name it
## without compiling the flight (the sandbox loads RocketFlight only when a flight starts):
## - the developer's test flight (the developer menu's FLY, --fly-moon, --fly=<world>, --land=<world>): the sandbox
##   flies a test rocket there (or plays the landing on its own) once the child stands in the next world;
## - the lander that just touched down ({"destination", "cells"}): the sandbox of that world stands it by the landing pad.

static var test_pending := 0
static var test_landing := false
static var parked := {}


## The test flight waiting ({"destination", "landing"}; destination 0: none), and forgets it.
static func take_test() -> Dictionary:
	var t := {"destination": test_pending, "landing": test_landing}
	test_pending = 0
	test_landing = false
	return t


## The lander parked for world u ({} for none; forgets it either way).
static func take_parked(u: int) -> Dictionary:
	var p := parked
	parked = {}
	return p if int(p.get("destination", 0)) == u else {}


## The developer's flight asked for on the command line: --fly-moon (the Moon), --fly=<world>, --land=<world> (the
## landing on its own). {"destination": 0} for none.
static func from_args(args: Array) -> Dictionary:
	for a: Variant in args:
		var s := str(a)
		if s == "--fly-moon":
			return {"destination": SpaceRules.MOON, "landing": false}
		if s.begins_with("--fly="):
			return {"destination": int(s.trim_prefix("--fly=")), "landing": false}
		if s.begins_with("--land="):
			return {"destination": int(s.trim_prefix("--land=")), "landing": true}
	return {"destination": 0, "landing": false}
