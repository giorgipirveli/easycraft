extends GutTest
## Owner #79, #86, #87 (spec §25.3, §21d.4): the RocketFlight node, headless, stepped by hand (tick). A whole flight in the
## rocket the child built (from the pad in the world, up into the flight's own space, the stages falling away, the
## landing) and a landing on its own: the hooks the sandbox gives are called (the player hidden and safe, the world's sun
## off in space, the sky's climb), `landed` comes once with the destination, the cockpit shows the countdown and the
## dials, a stage mesh falls away, QUIT (abort) puts everything back, SKIP jumps to the landing.

var flight: RocketFlight
var ui: Control
var calls := {}
var landed_at: Array[int] = []
var ended := 0


func before_each() -> void:
	calls = {"take_over": [], "world_light": [], "sky": [], "safe": 0}
	landed_at.clear()
	ended = 0
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.make_current()
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child_autofree(ui)
	flight = RocketFlight.new()
	flight.auto_tick = false
	flight.ui_parent = ui
	flight.take_over = func(on: bool) -> void: (calls.take_over as Array).append(on)
	flight.world_light = func(on: bool) -> void: (calls.world_light as Array).append(on)
	flight.sky_climb = func(c: float) -> void: (calls.sky as Array).append(c)
	flight.keep_safe = func() -> void: calls.safe += 1
	flight.landed.connect(func(u: int) -> void: landed_at.append(u))
	flight.ended.connect(func() -> void: ended += 1)
	add_child_autofree(flight)
	FlightTicket.parked = {}


func after_each() -> void:
	FlightTicket.parked = {}
	FlightTicket.test_pending = 0


## Plays the flight with a child who presses what is asked at once, holds burns, never steers.
func _fly(max_seconds: float = 400.0, delta: float = 0.1) -> float:
	var t := 0.0
	while flight.is_active() and t < max_seconds:
		var waiting := flight.run.waiting_for()
		flight.cockpit.throttle = flight.run.test_throttle()   # owner #106: the descent flown well too
		if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			flight.cockpit.action_pressed.emit()
		flight.tick(delta)
		t += delta
	return t


func test_a_whole_flight_to_the_moon_lands_once() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	assert_true(flight.is_active())
	assert_eq(calls.take_over, [true], "the player hidden and held")
	assert_true(flight.camera.current, "the flight's camera")
	assert_not_null(ui.get_node_or_null("Cockpit"), "the cockpit over the game")
	var t := _fly()
	assert_eq(landed_at, [SpaceRules.MOON])
	assert_between(t, 100.0, 180.0, "two to three minutes")
	assert_has(calls.world_light, false, "the world's sun off in the flight's space")
	assert_gt(calls.safe, 10, "the player kept safe all the way")
	assert_eq(FlightTicket.parked.get("destination"), SpaceRules.MOON, "the lander parks by the pad")
	assert_eq(FlightTicket.parked.cells, RocketStages.lander(flight.rocket))
	assert_eq(ended, 0, "landed, not aborted")


func test_the_countdown_and_the_dials_show() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	while flight.run.phase() != FlightPlan.COUNTDOWN:
		flight.tick(0.1)
	flight.tick(0.1)
	assert_true(flight.cockpit.countdown.visible)
	assert_eq(flight.cockpit.countdown.text, "10")
	for i in 55:
		flight.tick(0.1)
	assert_eq(flight.cockpit.countdown.text, "5")
	assert_eq(flight.cockpit.dist_value.text, "384,400 km")
	assert_eq(flight.cockpit.speed_value.text, "0.0 km/s")


func test_the_rocket_leaves_the_pad_and_goes_into_its_own_space() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var pad_y := flight.body.position.y
	while flight.run.phase() != FlightPlan.ASCENT:
		flight.cockpit.throttle = 1.0
		flight.tick(0.1)
	for i in 20:
		flight.tick(0.1)
	assert_gt(flight.body.position.y, pad_y + 30.0, "rising over the pad")
	assert_false(flight.space.visible, "still in the world")
	while flight.run.phase() == FlightPlan.ASCENT and flight.run.progress() < 0.6:
		flight.tick(0.1)
	assert_true(flight.space.visible, "above the clouds: the flight's space")
	assert_eq(flight.camera.environment, flight.space.env)
	assert_eq(flight.camera.cull_mask & 1, 0, "the world is not drawn there")
	assert_true(flight.space.earth.visible, "the Earth below")


func test_the_first_stage_falls_away() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var stages := flight.body.stages.size()
	while flight.run.phase() != FlightPlan.STAGING or flight.run.waiting_for() != FlightPlan.STAGE:
		flight.cockpit.throttle = 1.0
		flight.tick(0.1)
	assert_eq(flight.body.dropped, 0)
	assert_eq(flight.cockpit.action.text, "STAGE")
	assert_true(flight.cockpit.action.waiting)
	flight.cockpit.action_pressed.emit()
	flight.tick(0.1)
	assert_eq(flight.body.dropped, 1)
	assert_eq(flight.body.stages[0].get_parent(), flight.space, "the empty stage falls in space, not with the rocket")
	assert_eq(stages, 2)


## Owner #106: its last 120 m are a practice descent the child flies (here flown well): about half a minute.
func test_a_landing_on_its_own_on_mercury_takes_about_half_a_minute() -> void:
	flight.land(SpaceRules.MERCURY)
	assert_false(flight.flown)
	assert_true(flight.space.visible, "it starts in orbit over Mercury")
	assert_eq(RocketStages.stage_count(flight.rocket), 1, "the lander")
	var t := _fly(60.0)
	assert_eq(landed_at, [SpaceRules.MERCURY])
	assert_between(t, 15.0, 40.0)
	assert_eq(float(FlightLooks.look(SpaceRules.MERCURY).sun_size), 3.0, "Mercury's big Sun")


func test_a_landing_on_its_own_on_the_moon_shows_the_ground_rising_and_puts_the_legs_out() -> void:
	flight.land(SpaceRules.MOON)
	var saw_ground := false
	var legs := 0.0
	var dust := false
	var t := 0.0
	while flight.is_active() and t < 60.0:
		flight.cockpit.throttle = flight.run.test_throttle()   # owner #106: the practice descent flown well
		flight.tick(0.1)
		t += 0.1
		if flight.pose.get("ground", false):
			saw_ground = true
		legs = maxf(legs, float(flight.pose.get("legs", 0.0)))
		dust = dust or (flight.space.dust != null and flight.space.dust.emitting)
	assert_true(saw_ground)
	assert_eq(legs, 1.0)
	assert_true(dust, "the engine blows the dust as the ground comes up")
	assert_eq(landed_at, [SpaceRules.MOON])


func test_quit_puts_everything_back() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MARS, 2), 1)
	for i in 400:
		flight.cockpit.throttle = 1.0
		flight.tick(0.1)
	flight.abort()
	assert_eq(ended, 1)
	assert_eq(landed_at, [] as Array[int])
	assert_eq(calls.take_over.back(), false, "the player and the HUD back")
	assert_eq(calls.world_light.back(), true, "the world's sun back")
	assert_eq(calls.sky.back(), 0.0, "the sky back to the day's")
	assert_false(flight.camera.current)
	await wait_frames(2)
	assert_null(ui.get_node_or_null("Cockpit"), "the cockpit gone")


func test_skip_jumps_a_repeat_flight_to_its_landing() -> void:
	flight.skippable = true
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 3), 1)
	assert_true(flight.cockpit.skip_button.visible)
	flight.tick(0.1)
	flight.cockpit.skip_pressed.emit()
	assert_eq(flight.run.phase(), FlightPlan.DEORBIT)
	assert_eq(flight.body.dropped, 2, "only the lander")
	var t := _fly(60.0)
	assert_eq(landed_at, [SpaceRules.MOON])
	assert_lt(t, 50.0)


func test_skip_ends_a_repeat_landing_at_once() -> void:
	flight.skippable = true
	flight.land(SpaceRules.MOON)
	flight.tick(0.1)
	flight.cockpit.skip_pressed.emit()
	assert_eq(landed_at, [SpaceRules.MOON])
	assert_false(flight.is_active())


func test_a_rocket_of_parts_no_page_draws_yet_still_flies() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2, true), 1)
	assert_eq(flight.body.stages.size(), 2)
	assert_gt(flight.body.stages[0].mesh.get_surface_count(), 0)
	var t := _fly()
	assert_eq(landed_at, [SpaceRules.MOON])


func test_every_movie_moment_plays_on_the_way_to_far_worlds() -> void:
	for dest in [SpaceRules.TITAN, SpaceRules.BOING]:
		var f := RocketFlight.new()
		f.auto_tick = false
		f.ui_parent = ui
		add_child_autofree(f)
		f.start(RocketStages.test_rocket(dest, 2), 1)
		var seen := {}
		var t := 0.0
		while f.is_active() and t < 400.0:
			var waiting := f.run.waiting_for()
			f.cockpit.throttle = f.run.test_throttle()   # owner #106: the descent flown well too
			if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
				f.cockpit.action_pressed.emit()
			f.tick(0.1)
			t += 0.1
			if f.pose.get("moment", &"") != &"":
				seen[f.pose.moment] = true
			if f.moments.tunnel and f.moments.tunnel.visible:
				seen[&"tunnel_drawn"] = true
			if f.moments.rocks and f.moments.rocks.visible:
				seen[&"rocks_drawn"] = true
			if not f.moments.puffs.is_empty() and f.moments.puffs[0].visible:
				seen[&"nebula_drawn"] = true
		for m in FlightPlan.moments(dest):
			assert_true(seen.has(m), "world %d: %s" % [dest, m])
		if dest == SpaceRules.TITAN:
			assert_true(seen.has(&"rocks_drawn"))
			assert_true(seen.has(&"tunnel_drawn"))
		else:
			assert_true(seen.has(&"nebula_drawn"))
