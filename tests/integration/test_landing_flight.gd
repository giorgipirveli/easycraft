extends GutTest
## Owner #106: the RocketFlight node with the descent the child flies (headless, stepped by hand). Flown well it lands
## once (`landed`, the lander parked); not flown it crashes: the way home plays (the capsule under its parachute beside
## the pad in the real world, the rocket falling by the Launch Site, the sandbox's `wreck` hook breaking the pad's parts
## once), `crashed` comes once and everything is put back. The cockpit shows the descent's dials and colours, its BURN
## button holds full throttle, the first try's hint card holds the descent until GO. The Star Map's LAND is a practice.
## In VR the way home is fade cuts (never one long black, never a shake; the rest in test_vr_rig_descent.gd).

var flight: RocketFlight
var ui: Control
var calls := {}
var landed_at: Array[int] = []
var crashed_at: Array[int] = []
var wrecks := 0


func before_each() -> void:
	calls = {"take_over": [], "world_light": []}
	landed_at.clear()
	crashed_at.clear()
	wrecks = 0
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.make_current()
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child_autofree(ui)
	flight = _new_flight()
	FlightTicket.parked = {}


func _new_flight() -> RocketFlight:
	var f := RocketFlight.new()
	f.auto_tick = false
	f.ui_parent = ui
	f.take_over = func(on: bool) -> void: (calls.take_over as Array).append(on)
	f.world_light = func(on: bool) -> void: (calls.world_light as Array).append(on)
	f.wreck = func() -> Dictionary:
		wrecks += 1
		return {"count": 9, "gold": 120}
	f.landed.connect(func(u: int) -> void: landed_at.append(u))
	f.crashed.connect(func(u: int) -> void: crashed_at.append(u))
	add_child_autofree(f)
	return f


func after_each() -> void:
	FlightTicket.parked = {}
	if Vr.active():
		Vr.simulate(false)
		Vr.anchor(null)


## Plays the flight with a child who does what is asked; in the descent `pilot` (0..1 from the run) flies, and `each`
## after every tick.
func _fly(pilot: Callable, each: Callable = Callable(), most: float = 400.0, delta: float = 0.1) -> float:
	var t := 0.0
	while flight.is_active() and t < most:
		var waiting := flight.run.waiting_for()
		flight.cockpit.throttle = float(pilot.call(flight.run)) if waiting == FlightPlan.DESCEND \
			else flight.run.test_throttle()
		if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			flight.cockpit.action_pressed.emit()
		flight.tick(delta)
		t += delta
		if each.is_valid():
			each.call(t)
	return t


func _good(r: FlightRun) -> float:
	return FlightDescent.test_pilot(r.descent)


func _nobody(_r: FlightRun) -> float:
	return 0.0


func test_a_descent_flown_well_lands_once() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var t := _fly(_good)
	assert_eq(landed_at, [SpaceRules.MOON])
	assert_eq(crashed_at, [] as Array[int])
	assert_between(t, 100.0, 190.0, "still two to three minutes")
	assert_eq(FlightTicket.parked.get("destination"), SpaceRules.MOON, "the lander parks by the pad")
	assert_eq(wrecks, 0, "nothing broke")


func test_nobody_flying_the_descent_crashes_and_comes_home() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var seen := {"chute_world": false, "side": 0.0, "wreck_fell": false, "tilt": 0.0}
	_fly(_nobody, func(_t: float) -> void:
		if not flight.is_active():
			return
		var phase := flight.run.phase()
		if phase == FlightPlan.CRASH:
			seen.tilt = maxf(float(seen.tilt), float(flight.pose.tilt))
		if phase == FlightPlan.HOME_CHUTE and bool(flight.pose.world) and float(flight.pose.chute) > 0.5:
			seen.chute_world = true
			seen.side = (flight.body.position - flight.body.pivot).x
		if phase == FlightPlan.WRECK and flight.wreck_node != null and flight.run.progress() < FlightShots.WRECK_HIT:
			seen.wreck_fell = seen.wreck_fell or flight.wreck_node.position.y > flight.body.pivot.y + 5.0)
	assert_eq(crashed_at, [SpaceRules.MOON], "crashed once")
	assert_eq(landed_at, [] as Array[int], "never landed")
	assert_true(FlightTicket.parked.is_empty(), "no lander parks anywhere")
	assert_gt(float(seen.tilt), 10.0, "the lander tipped over")
	assert_true(seen.chute_world, "home under the parachute, in the real world")
	assert_gt(absf(float(seen.side)), 4.0, "beside the pad, not on the rocket standing there")
	assert_true(seen.wreck_fell, "the rocket fell by the Launch Site")
	assert_eq(wrecks, 1, "its parts broke once")
	assert_eq((calls.take_over as Array).back(), false, "everything put back")
	assert_eq((calls.world_light as Array).back(), true)
	assert_true(flight.is_queued_for_deletion(), "the flight is over")


func test_the_way_home_says_what_broke() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var said := [""]
	_fly(_nobody, func(_t: float) -> void:
		if flight.is_active() and flight.run.phase() == FlightPlan.HOME:
			said[0] = flight.cockpit.words.text)
	assert_string_contains(str(said[0]), "9 parts broke")
	assert_string_contains(str(said[0]), "120 gold")


func test_the_cockpit_shows_the_descent_and_burn_holds_full_throttle() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	while flight.run.phase() != FlightPlan.DESCENT:
		flight.cockpit.throttle = flight.run.test_throttle()
		if flight.run.waiting_for() == FlightPlan.LEGS:
			flight.cockpit.action_pressed.emit()
		flight.tick(0.1)
	flight.cockpit.throttle = 0.0
	flight.tick(0.1)
	var d: Dictionary = flight.cockpit.state.get("descent", {})
	assert_false(d.is_empty(), "the descent's dials")
	assert_almost_eq(float(d.h), flight.run.descent.height, 0.001)
	assert_almost_eq(float(d.v), flight.run.descent.speed, 0.001)
	assert_has(FlightDescent.COLORS, d.zone)
	assert_true(flight.cockpit.descent_dials.visible)
	assert_eq(flight.cockpit.action.text, "BURN")
	assert_true(flight.cockpit.action.visible)
	flight.cockpit.action_held = true
	flight.tick(0.1)
	assert_eq(flight.run.throttle, 1.0, "BURN held: full throttle")
	assert_eq(flight.run.waiting_for(), FlightPlan.DESCEND, "pressing BURN never lands it by itself")
	flight.cockpit.action_pressed.emit()
	flight.tick(0.1)
	assert_eq(flight.run.waiting_for(), FlightPlan.DESCEND)
	flight.cockpit.action_held = false
	for i in 25:
		flight.cockpit.throttle = 0.0
		flight.tick(0.1)
	assert_ne(str(flight.cockpit.hint.text), "", "short words while it falls")


func test_the_first_try_hint_card_holds_the_descent_until_go() -> void:
	flight.first_try = true
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	while flight.run.phase() != FlightPlan.DESCENT:
		flight.cockpit.throttle = flight.run.test_throttle()
		if flight.run.waiting_for() == FlightPlan.LEGS:
			flight.cockpit.action_pressed.emit()
		flight.tick(0.1)
	flight.tick(0.1)
	assert_true(flight.run.descent.easy, "the easy first try")
	assert_true(flight.cockpit.hint_card.visible, "its hint card")
	var h := flight.run.descent.height
	for i in 10:
		flight.tick(0.1)
	assert_eq(flight.run.descent.height, h, "held while the card shows")
	flight.cockpit.go_pressed.emit()
	for i in 5:
		flight.tick(0.1)
	assert_false(flight.cockpit.hint_card.visible)
	assert_lt(flight.run.descent.height, h, "GO: the descent is on")


func test_a_star_map_landing_is_a_practice() -> void:
	flight.land(SpaceRules.MERCURY)
	assert_true(flight.run.practice)
	var t := _fly(_nobody, Callable(), 120.0)
	assert_eq(landed_at, [SpaceRules.MERCURY], "never stuck: Mission Control lands it after the tries")
	assert_eq(crashed_at, [] as Array[int], "a practice never crashes the trip")
	assert_eq(wrecks, 0)
	assert_lt(t, 90.0)
	var good := _new_flight()
	landed_at.clear()
	flight = good
	flight.land(SpaceRules.MOON)
	var t2 := _fly(_good, Callable(), 120.0)
	assert_eq(landed_at, [SpaceRules.MOON])
	assert_between(t2, 12.0, 40.0, "flown well: about half a minute")


func test_in_vr_the_way_home_is_fade_cuts_with_no_shake() -> void:
	var stand := Node3D.new()
	add_child_autofree(stand)
	Vr.simulate(true)
	Vr.anchor(stand, &"feet")
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var seen := {"shake": 0.0, "home_steps": [], "black_run": 0.0, "longest_black": 0.0}
	_fly(_nobody, func(_t: float) -> void:
		if not flight.is_active():
			return
		var phase := flight.run.phase()
		seen.shake = maxf(float(seen.shake), float(flight.pose.shake))
		if phase in [FlightPlan.CRASH, FlightPlan.ESCAPE, FlightPlan.HOME_ENTRY, FlightPlan.HOME_CHUTE,
				FlightPlan.WRECK, FlightPlan.HOME]:
			if not (seen.home_steps as Array).has(phase):
				(seen.home_steps as Array).append(phase)
			seen.black_run = float(seen.black_run) + 0.1 if Vr.fade_amount() >= 0.99 else 0.0
			seen.longest_black = maxf(float(seen.longest_black), float(seen.black_run)))
	assert_eq(crashed_at, [SpaceRules.MOON])
	assert_eq(float(seen.shake), 0.0, "never a shake in VR")
	assert_lt(float(seen.longest_black), 3.0, "fade cuts, never one long black (what each cut hides: "
		+ "test_vr_rig_descent.gd)")
	assert_has(seen.home_steps, FlightPlan.HOME_CHUTE, "the parachute coming down, watched from a still spot by the pad")
	assert_has(seen.home_steps, FlightPlan.WRECK, "and the rocket falling there")
	assert_eq(wrecks, 1)
	assert_false(Vr.seated(), "the seat let go: the child stands by the Launch Site")
