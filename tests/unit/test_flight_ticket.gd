extends GutTest
## Owner #79, #87: what a flight leaves for the next world (FlightTicket): the developer's test flight (the developer
## menu's FLY ROCKET, --fly-moon, --fly=<world>, --land=<world>) and the lander that landed, each read once.


func after_each() -> void:
	FlightTicket.test_pending = 0
	FlightTicket.test_landing = false
	FlightTicket.parked = {}


func test_the_command_line_asks_for_a_flight_or_a_landing() -> void:
	assert_eq(FlightTicket.from_args(["--fly-moon"]), {"destination": SpaceRules.MOON, "landing": false})
	assert_eq(FlightTicket.from_args(["--x", "--fly=19"]), {"destination": SpaceRules.MARS, "landing": false})
	assert_eq(FlightTicket.from_args(["--land=23"]), {"destination": SpaceRules.MERCURY, "landing": true})
	assert_eq(int(FlightTicket.from_args(["--survivor"]).destination), 0, "nothing asked")


func test_a_test_flight_is_taken_once() -> void:
	FlightTicket.test_pending = SpaceRules.MARS
	FlightTicket.test_landing = true
	assert_eq(FlightTicket.take_test(), {"destination": SpaceRules.MARS, "landing": true})
	assert_eq(int(FlightTicket.take_test().destination), 0, "forgotten")


func test_the_lander_parks_only_in_the_world_it_landed_on() -> void:
	FlightTicket.parked = {"destination": SpaceRules.MOON, "cells": {Vector3i.ZERO: BlockIds.STONE}}
	assert_eq(FlightTicket.take_parked(SpaceRules.MARS), {}, "another world: none (and it is forgotten)")
	assert_eq(FlightTicket.take_parked(SpaceRules.MOON), {})
	FlightTicket.parked = {"destination": SpaceRules.MOON, "cells": {Vector3i.ZERO: BlockIds.STONE}}
	assert_eq(FlightTicket.take_parked(SpaceRules.MOON).cells, {Vector3i.ZERO: BlockIds.STONE})
	assert_eq(FlightTicket.parked, {})


func test_the_lander_stands_with_a_body_to_bump_into() -> void:
	var r := RocketStages.default_lander(SpaceRules.MOON)
	var lander: Node3D = load("res://entities/flight/rocket_flight.gd").stand(r.cells)
	add_child_autofree(lander)
	assert_true(lander is StaticBody3D)
	assert_eq(lander.find_children("*", "MeshInstance3D", false, false).size(), 1)
	assert_eq(lander.find_children("*", "CollisionShape3D", false, false).size(), 1)
