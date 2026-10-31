extends GutTest
## Crew flights (spec §21d.6 phase 2; owner #78 "which can be built by team or alone", #79): the pure rules. How many
## friends fit in the rocket (the check with the whole crew: a seat each, air and water for everyone), the kind words
## when they don't ("3 friends want to fly and the rocket has 1 seat: add crew capsules!"), the words a crew member
## reads while the pilot flies, how far a crew member's flight may run past the pilot's last word, the crew badge.


## The Moon rocket of tools/mission_smoke_steps.gd: one seat.
static func one_seat() -> Dictionary:
	return {"destination": SpaceRules.MOON, "cells": load("res://tools/mission_smoke_steps.gd").moon_rocket(),
		"stages": [], "seats": 1}


## The crew rocket of tools/net_test.gd: two seats (a second capsule is heavier: more fuel and an engine more).
static func two_seats() -> Dictionary:
	return {"destination": SpaceRules.MOON, "cells": load("res://tools/net_test.gd").crew_rocket(), "stages": [],
		"seats": 2}


func test_the_crew_rocket_passes_the_check_for_two_astronauts() -> void:
	var cells: Dictionary = two_seats().cells
	assert_true(RocketCheck.check(cells, MissionRules.for_world(SpaceRules.MOON), 2).ok, "two seats, air, fuel")
	assert_false(RocketCheck.check(cells, MissionRules.for_world(SpaceRules.MOON), 3).ok, "not three")


func test_room_counts_the_friends_the_rocket_carries() -> void:
	assert_eq(CrewFlightRules.room(one_seat(), 0), 0, "nobody wants to fly along")
	assert_eq(CrewFlightRules.room(one_seat(), 1), 0, "one seat: the pilot's")
	assert_eq(CrewFlightRules.room(one_seat(), 3), 0)
	assert_eq(CrewFlightRules.room(two_seats(), 1), 1, "two seats: a friend flies along")
	assert_eq(CrewFlightRules.room(two_seats(), 3), 1, "only one of three")


func test_room_counts_air_and_water_for_everyone_too() -> void:
	var r := two_seats()
	var cells: Dictionary = (r.cells as Dictionary).duplicate()
	for p: Vector3i in cells:
		if int(cells[p]) == BlockIds.SERVICE_MODULE and p.x != 4:
			cells[p] = BlockIds.FUEL_TANK   # owner #98: a service module for each astronaut; this one has one for two
			break
	r.cells = cells
	assert_eq(CrewFlightRules.room(r, 1), 0)
	assert_string_contains(CrewFlightRules.short_words(r, 1), "air and water")
	assert_string_contains(CrewFlightRules.short_words(r, 1), "2 astronauts")


func test_the_words_when_the_seats_are_too_few() -> void:
	assert_eq(CrewFlightRules.short_words(one_seat(), 3),
		"3 friends want to fly and the rocket has 1 seat: add crew capsules!")
	assert_eq(CrewFlightRules.short_words(one_seat(), 1),
		"1 friend wants to fly and the rocket has 1 seat: add a crew capsule!")
	assert_eq(CrewFlightRules.short_words(two_seats(), 2),
		"2 friends want to fly and the rocket has 2 seats: add a crew capsule!")
	assert_eq(CrewFlightRules.short_words(two_seats(), 1), "", "everyone fits")


func test_the_pilots_choice_names_how_many_fly() -> void:
	assert_eq(CrewFlightRules.fly_with_words(0), "FLY ALONE")
	assert_eq(CrewFlightRules.fly_with_words(1), "FLY WITH 1 FRIEND")
	assert_eq(CrewFlightRules.fly_with_words(2), "FLY WITH 2 FRIENDS")


func test_the_call_says_who_launches_where() -> void:
	assert_eq(CrewFlightRules.call_words("Anna", SpaceRules.MOON), "Anna is launching to the Moon! Take your seat.")
	assert_eq(CrewFlightRules.call_words("", SpaceRules.MARS), "Your friend is launching to Mars! Take your seat.")


func test_friends_who_do_not_fly_hear_kind_words() -> void:
	var stayed := CrewFlightRules.left_words(CrewFlightRules.STAYED, "Anna", SpaceRules.MOON)
	assert_string_contains(stayed, "Anna's world is flying to the Moon")
	assert_string_contains(stayed, "menu")
	var full := CrewFlightRules.left_words(CrewFlightRules.NO_SEAT, "Anna", SpaceRules.MOON)
	assert_string_contains(full, "no seat for you")
	assert_string_contains(full, "crew capsule")
	assert_ne(CrewFlightRules.left_words(CrewFlightRules.STAYED, "", SpaceRules.MOON), "", "no name: still kind words")


func test_a_crew_member_reads_what_the_pilot_does() -> void:
	var lift := {"phase": FlightPlan.LIFTOFF, "action": FlightPlan.THROTTLE, "words": "Push the throttle all the way up!"}
	assert_eq(CrewFlightRules.crew_words(lift, "Anna"), "Anna pushes the throttle up. Hold on tight!")
	var stage := {"phase": FlightPlan.STAGING, "action": FlightPlan.STAGE, "words": "press STAGE!"}
	assert_eq(CrewFlightRules.crew_words(stage, "Anna"), "Anna lets the empty stage go!")
	var board := {"phase": FlightPlan.BOARD, "action": &"", "words": "Climb in and buckle up! You are the pilot."}
	assert_eq(CrewFlightRules.crew_words(board, "Anna"), "Climb in and buckle up! Anna is the pilot, you are the crew.")
	var steer := {"phase": FlightPlan.ASCENT, "action": &"", "steer": true, "words": "Steer into the green ring!"}
	assert_eq(CrewFlightRules.crew_words(steer, "Anna"), "Anna steers. Look out of the window!")
	var cruise := {"phase": FlightPlan.CRUISE, "action": &"", "words": "3 days to the Moon."}
	assert_eq(CrewFlightRules.crew_words(cruise, "Anna"), "3 days to the Moon.", "the story's words are everyone's")
	assert_eq(CrewFlightRules.crew_words(stage, ""), "The pilot lets the empty stage go!")


func test_every_action_of_a_real_trip_has_crew_words() -> void:
	for dest: int in [SpaceRules.MOON, SpaceRules.MARS]:
		for s: Dictionary in FlightPlan.steps(dest, 3):
			var w := CrewFlightRules.crew_words(s, "Anna")
			assert_ne(w, "", "%s" % s.phase)
			if s.get("action", &"") != &"":
				assert_string_contains(w, "Anna", "%s: the pilot does it" % s.phase)


func test_a_crew_members_flight_runs_a_little_past_the_pilots_last_word_and_no_more() -> void:
	assert_almost_eq(CrewFlightRules.upto(10.0, 0.2), 10.2, 0.001)
	assert_almost_eq(CrewFlightRules.upto(10.0, 5.0), 10.0 + CrewFlightRules.FOLLOW_AHEAD, 0.001, "the pilot paused: it waits")
	assert_almost_eq(CrewFlightRules.upto(10.0, -1.0), 10.0, 0.001)


func test_the_crew_badge_names_the_friends() -> void:
	assert_eq(CrewFlightRules.badge_words(SpaceRules.MOON, ["Anna", "Sam"]), "Crew of the Moon mission with Anna and Sam")
	assert_eq(CrewFlightRules.badge_words(SpaceRules.MARS, ["Anna"]), "Crew of the Mars mission with Anna")
	assert_eq(CrewFlightRules.badge_words(SpaceRules.MOON, ["A", "B", "C"]), "Crew of the Moon mission with A, B and C")
	assert_eq(CrewFlightRules.badge_words(SpaceRules.MOON, []), "Crew of the Moon mission")


func test_names_are_the_ones_the_world_shows_or_a_friend() -> void:
	assert_eq(CrewFlightRules.shown_name("Sam"), "Sam")
	assert_eq(CrewFlightRules.shown_name(""), "A friend")
	assert_eq(CrewFlightRules.shown_name("   "), "A friend")
