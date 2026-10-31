extends GutTest
## Crew flights (spec §21d.6 phase 2, the brief's item 2): every crew member sees the real flight from a seat in the
## capsule (a RocketFlight from the same rocket description on each device); the pilot's flight is the one that counts;
## a crew member's view follows the pilot's steering, never its own; its cockpit has no throttle, ACTION or SKIP; its
## words say what the pilot does. Two flights here, stepped by hand: the pilot's word goes to the crew's as it would
## over the network (crew_state -> follow_pilot).

var pilot: RocketFlight
var crew: RocketFlight
var ui: Control
var now := 0.0
var landed := {"pilot": 0, "crew": 0}


func _flight(follow: bool) -> RocketFlight:
	var f := RocketFlight.new()
	f.auto_tick = false
	f.ui_parent = ui
	f.crew_follow = follow
	f.clock = func() -> float: return now
	f.landed.connect(func(_u: int) -> void: landed["crew" if follow else "pilot"] += 1)
	add_child_autofree(f)
	return f


func before_each() -> void:
	now = 0.0
	landed = {"pilot": 0, "crew": 0}
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


## Plays both: the pilot like a child who presses what is asked at once (and steers right at times); its word reaches
## the crew every `every` seconds.
func _fly(max_seconds: float = 400.0, delta: float = 0.1, every: float = 0.3) -> void:
	var t := 0.0
	var next_word := 0.0
	while (pilot.is_active() or crew.is_active()) and t < max_seconds:
		if pilot.is_active():
			var waiting := pilot.run.waiting_for()
			pilot.cockpit.throttle = pilot.run.test_throttle()   # owner #106: the descent flown well too
			if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
				pilot.cockpit.action_pressed.emit()
			pilot.cockpit.stick = Vector2(1, 0) if int(t) % 7 == 0 else Vector2.ZERO
			pilot.tick(delta)
		if t >= next_word:
			next_word += every
			crew.follow_pilot(pilot.crew_state())
		now += delta
		crew.tick(delta)
		t += delta


func test_the_crew_flies_the_same_trip_and_lands_with_the_pilot() -> void:
	var rocket := RocketStages.test_rocket(SpaceRules.MOON, 2)
	pilot.start(rocket, 1)
	crew.start(rocket, 1)
	_fly()
	assert_eq(landed.pilot, 1, "the pilot's flight lands once")
	assert_eq(landed.crew, 1, "the crew member's lands too")
	assert_eq(crew.run.dropped(), pilot.run.dropped(), "the same stages fell away")


func test_the_crew_members_cockpit_has_no_controls() -> void:
	var rocket := RocketStages.test_rocket(SpaceRules.MOON, 2)
	crew.skippable = true
	crew.start(rocket, 1)
	crew.follow_pilot({"i": 2, "t": 0.0, "done": false, "dropped": 0})
	crew.tick(0.1)
	crew.tick(0.1)
	assert_true(crew.cockpit.crew_member)
	assert_false(crew.cockpit.lever.visible, "no throttle")
	assert_false(crew.cockpit.action.visible, "no ACTION button")
	assert_false(crew.cockpit.skip_button.visible, "no SKIP: the pilot's trip")
	assert_true(crew.cockpit.view_button.visible, "the view stays the child's own")
	assert_eq(crew.cockpit.words.text, "Anna pushes the throttle up. Hold on tight!")
	crew.cockpit.action_pressed.emit()
	crew.tick(0.1)
	assert_false(crew.run.action_done_here(), "a crew member's button never flies the rocket")


func test_the_crew_members_view_follows_the_pilots_steering_never_its_own() -> void:
	var rocket := RocketStages.test_rocket(SpaceRules.MOON, 2)
	crew.start(rocket, 1)
	var ascent := 3
	crew.follow_pilot({"i": ascent, "t": 2.0, "done": true, "dropped": 0, "off": Vector2(12, -4)})
	crew.cockpit.stick = Vector2(-1, 1)   # the crew member's own drag does nothing
	for i in 30:
		crew.tick(0.1)
	assert_almost_eq(crew.steering.off.x, 12.0, 0.01)
	assert_almost_eq(crew.steering.off.y, -4.0, 0.01)


func test_a_crew_member_waits_for_the_pilots_word() -> void:
	var rocket := RocketStages.test_rocket(SpaceRules.MOON, 2)
	crew.start(rocket, 1)
	for i in 50:
		now += 0.1
		crew.tick(0.1)
	assert_eq(crew.run.phase(), FlightPlan.BOARD, "nothing from the pilot yet: still boarding")
	crew.follow_pilot({"i": 1, "t": 4.0, "done": false, "dropped": 0})
	crew.tick(0.1)
	assert_eq(crew.run.phase(), FlightPlan.COUNTDOWN)
	for i in 30:   # the pilot's word stops (it paused): the crew's flight runs on 1 s at most
		now += 0.1
		crew.tick(0.1)
	assert_almost_eq(crew.run.t, 4.0 + CrewFlightRules.FOLLOW_AHEAD, 0.01)


func test_each_crew_member_sits_in_a_seat_of_their_own() -> void:
	var rocket := RocketStages.test_rocket(SpaceRules.MOON, 2)
	pilot.seat = 0
	pilot.crew_size = 2
	pilot.start(rocket, 1)
	crew.start(rocket, 1)
	for i in 40:   # past the boarding's glide: both inside the capsule for the countdown
		pilot.tick(0.1)
		crew.follow_pilot(pilot.crew_state())
		crew.tick(0.1)
	assert_eq(crew.run.phase(), FlightPlan.COUNTDOWN)
	var a := pilot.camera.global_position
	var b := crew.camera.global_position
	assert_almost_eq(a.distance_to(b), RocketFlight.SEAT_GAP, 0.05, "side by side in the capsule")
