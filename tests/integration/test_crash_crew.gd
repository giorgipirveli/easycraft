extends GutTest
## Owner #106, crew flights: everyone on board crashes together. The pilot's descent is the one that counts; each crew
## member's flight follows it into the crash and comes home the same way (`crashed` on every game, never `landed`);
## only the host's rocket breaks (a crew member's `wreck` is its sandbox's: nothing on a guest). The host's crew flight
## is over without anybody's world moving.

const FakeNet := preload("res://tests/integration/test_crew_flights.gd").FakeNet

var pilot: RocketFlight
var crew: RocketFlight
var ui: Control
var now := 0.0
var events := {"pilot_crashed": 0, "crew_crashed": 0, "landed": 0, "pilot_wreck": 0, "crew_wreck": 0}


func _flight(follow: bool) -> RocketFlight:
	var f := RocketFlight.new()
	f.auto_tick = false
	f.ui_parent = ui
	f.crew_follow = follow
	f.clock = func() -> float: return now
	f.landed.connect(func(_u: int) -> void: events.landed += 1)
	f.crashed.connect(func(_u: int) -> void: events["crew_crashed" if follow else "pilot_crashed"] += 1)
	f.wreck = func() -> Dictionary:
		events["crew_wreck" if follow else "pilot_wreck"] += 1
		return {} if follow else {"count": 7, "gold": 95}
	add_child_autofree(f)
	return f


func before_each() -> void:
	now = 0.0
	events = {"pilot_crashed": 0, "crew_crashed": 0, "landed": 0, "pilot_wreck": 0, "crew_wreck": 0}
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.make_current()
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child_autofree(ui)
	pilot = _flight(false)
	crew = _flight(true)
	crew.pilot = "Anna"
	crew.seat = 1
	crew.crew_size = 2
	FlightTicket.parked = {}


func after_each() -> void:
	FlightTicket.parked = {}


func test_everyone_on_board_crashes_together_and_comes_home() -> void:
	var rocket := RocketStages.test_rocket(SpaceRules.MOON, 2)
	pilot.start(rocket, 1)
	crew.start(rocket, 1)
	var t := 0.0
	var next_word := 0.0
	var crew_saw_descent := false
	var crew_words := ""
	while (is_instance_valid(pilot) and pilot.is_active()) or (is_instance_valid(crew) and crew.is_active()):
		if t > 400.0:
			break
		if is_instance_valid(pilot) and pilot.is_active():
			var w := pilot.run.waiting_for()
			pilot.cockpit.throttle = 0.0 if w == FlightPlan.DESCEND else pilot.run.test_throttle()
			if w in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
				pilot.cockpit.action_pressed.emit()
			pilot.tick(0.1)
			if t >= next_word and pilot.is_active():
				next_word += 0.3
				crew.follow_pilot(pilot.crew_state())
		now += 0.1
		if is_instance_valid(crew) and crew.is_active():
			crew.tick(0.1)
			if not crew.is_active():
				t += 0.1
				continue
			if crew.run.phase() == FlightPlan.DESCENT and crew.cockpit.state.has("descent"):
				crew_saw_descent = true
			if crew.run.phase() == FlightPlan.HOME:
				crew_words = crew.cockpit.words.text
		t += 0.1
	assert_eq(events.pilot_crashed, 1, "the pilot's flight crashed and came home")
	assert_eq(events.crew_crashed, 1, "the crew member's too")
	assert_eq(events.landed, 0, "nobody landed")
	assert_true(crew_saw_descent, "the crew member watched the pilot's descent on its own dials")
	assert_eq(events.pilot_wreck, 1, "the host's rocket broke once")
	assert_ne(crew_words, "", "the crew member's way home says what happens")


func test_the_hosts_crew_flight_is_over_and_nobody_moves() -> void:
	var net: Node = FakeNet.new()
	add_child_autofree(net)
	var c := CrewFlights.new()
	c.net = net
	c.host = true
	c.peers = func() -> Array[int]: return [2] as Array[int]
	add_child_autofree(c)
	c.flying = true
	c.crew = [{"peer": 1, "name": "Anna", "look": "", "seat": 0}, {"peer": 2, "name": "Sam", "look": "", "seat": 1}]
	assert_eq(c.crew_peers(), [2] as Array[int])
	c.crashed()
	assert_false(c.flying, "the crew flight is over")
	assert_false(c.moving_crew(false), "no world moves after a crash")
	assert_eq(net.of("board"), [], "nobody is sent anywhere")
	var guest := CrewFlights.new()
	guest.net = net
	add_child_autofree(guest)
	guest.flying = true
	guest.follower_crashed()
	assert_false(guest.flying)
	assert_string_contains(CrewFlightRules.CRASHED_HOME, "rebuild")
