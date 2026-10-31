extends GutTest
## Owner #110 (VR round 4, idea 8) with fake hands (Vr.simulate): the cockpit you touch. Seated in the capsule, STAGE,
## LEGS and LIGHTS are big buttons on the dashboard; STAGE and LEGS light up when the flight waits for them and a
## fingertip's poke does them (the stage falls away with a thump in both hands, the legs come out); a dark button only
## clicks softly; LIGHTS turns the cabin lights off and on; the finger stops at the panel. On the burns both controllers
## rumble in short capped pulses, stronger with more throttle; the countdown's last three seconds tick. A and the trigger
## keep working (test_vr_rig_rocket.gd, test_vr_rig_descent.gd). Off VR none of it exists.

var flight: RocketFlight
var ui: Control
var stand: Node3D


func before_each() -> void:
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.make_current()
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child_autofree(ui)
	stand = Node3D.new()
	add_child_autofree(stand)
	FlightTicket.parked = {}


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	FlightTicket.parked = {}
	FlightTicket.test_pending = 0


func _start(vr: bool = true, landing: bool = false) -> void:
	if vr:
		Vr.simulate(true)
		Vr.anchor(stand, &"feet")
	flight = RocketFlight.new()
	flight.auto_tick = false
	flight.ui_parent = ui
	add_child_autofree(flight)
	if landing:
		flight.land(SpaceRules.MOON)
	else:
		flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)


## Flies on (the throttle a good child holds, no button pressed) until `done` says so; false when it never did.
func _fly_until(done: Callable, max_seconds: float = 200.0, delta: float = 0.05) -> bool:
	var t := 0.0
	while flight.is_active() and t < max_seconds:
		if done.call():
			return true
		flight.cockpit.throttle = flight.run.test_throttle()
		flight.tick(delta)
		t += delta
	return false


## Puts `side`'s fake hand so its index fingertip is `z` metres in front of `button`'s middle on the dashboard (the
## hand pointing into it), then a frame: the hands drawn (Vr.step) and the flight's tick.
func _finger(side: StringName, button: StringName, z: float, delta: float = 0.02) -> void:
	var c := flight.cockpit
	var band := FlightCockpit.dashboard_rect(c.size)
	band.position += c.get_global_rect().position
	var px: Vector2 = (CockpitTouchRules.button_rects(band)[button] as Rect2).get_center()
	_finger_at(side, px, band, z, delta)


func _finger_at(side: StringName, px: Vector2, band: Rect2, z: float, delta: float = 0.02) -> void:
	var q := CockpitTouchRules.quad_size()
	var local := Vector3(((px.x - band.position.x) / band.size.x - 0.5) * q.x, (0.5 - (px.y - band.position.y) /
		band.size.y) * q.y, z)
	var dash := flight.vr_dashboard().global_transform
	var tip := CockpitTouchRules.fingertip(Transform3D.IDENTITY, side, 0.0)
	var hand := Transform3D(dash.basis, dash * local - dash.basis * tip)
	Vr.sim_hand(side, Vr.rig.global_transform.affine_inverse() * hand)
	Vr.step(delta)
	flight.tick(delta)


func _finger_away(side: StringName) -> void:
	_finger(side, CockpitTouchRules.LIGHTS, 0.2)


func test_the_dashboard_shows_stage_legs_and_lights_in_vr() -> void:
	_start()
	flight.tick(0.05)
	var c := flight.cockpit
	var band := FlightCockpit.dashboard_rect(c.size)
	for b: StringName in CockpitTouchRules.BUTTONS:
		var button: Control = c.poke_buttons[b]
		assert_true(button.is_visible_in_tree(), "%s shows" % b)
		assert_true(band.encloses(button.get_rect()), "%s on the dashboard" % b)
		assert_eq(button.get_rect(), CockpitTouchRules.button_rects(band)[b], "%s where the rules say" % b)
	assert_false(c.poke_lit(CockpitTouchRules.STAGE), "nothing to stage yet: dark")
	assert_true(c.poke_lit(CockpitTouchRules.LIGHTS), "the cabin lights are on")


func test_off_vr_there_are_no_poke_buttons_and_no_buzz() -> void:
	_start(false)
	var buzz := Vr.haptics
	_fly_until(func() -> bool: return flight.run.phase() == FlightPlan.ASCENT, 60.0)
	assert_false(flight.cockpit.dashboard_mode)
	for b: StringName in CockpitTouchRules.BUTTONS:
		assert_false((flight.cockpit.poke_buttons[b] as Control).is_visible_in_tree(), "%s hidden on a screen" % b)
	assert_eq(Vr.haptics, buzz, "no headset, no buzz")
	assert_eq(flight.vr_haptic_log, [], "nothing logged")


func test_a_fingertip_pokes_stage_and_the_empty_stage_falls_away_with_a_thump() -> void:
	_start()
	assert_true(_fly_until(func() -> bool: return flight.run.waiting_for() == FlightPlan.STAGE), "waits for STAGE")
	var c := flight.cockpit
	flight.tick(0.02)
	assert_true(c.poke_lit(CockpitTouchRules.STAGE), "STAGE lights up")
	_finger(&"right", CockpitTouchRules.STAGE, 0.04)
	assert_eq(flight.run.waiting_for(), FlightPlan.STAGE, "a finger near it is no press")
	assert_true(c.poke_hovered(CockpitTouchRules.STAGE), "it glows under the finger")
	var buzz := Vr.haptics
	var dropped := flight.run.dropped()
	_finger(&"right", CockpitTouchRules.STAGE, -0.004)
	assert_ne(flight.run.waiting_for(), FlightPlan.STAGE, "pressed: staged")
	assert_true(c.poke_down(CockpitTouchRules.STAGE), "the button went in")
	assert_gt(Vr.haptics, buzz, "a buzz")
	var clicks := flight.vr_haptic_log.filter(func(p: Array) -> bool: return float(p[3]) == float(CockpitTouchRules.CLICK[2]))
	assert_eq(clicks.size(), 1, "a click in that hand")
	assert_true(_fly_until(func() -> bool: return flight.body.dropped > dropped, 10.0), "the stage falls away")
	var thumps := flight.vr_haptic_log.filter(func(p: Array) -> bool: return float(p[3]) == float(CockpitTouchRules.THUMP[2]))
	assert_eq(thumps.size(), 1, "one thump, in both hands")


func test_legs_light_up_at_the_landing_and_a_poke_puts_them_out() -> void:
	_start()
	assert_true(_fly_until(func() -> bool:
		if flight.run.waiting_for() in [FlightPlan.STAGE, FlightPlan.PARACHUTE]:
			flight.cockpit.action_pressed.emit()   # A still works
		return flight.run.waiting_for() == FlightPlan.LEGS, 400.0), "waits for LEGS")
	flight.tick(0.02)
	assert_true(flight.cockpit.poke_lit(CockpitTouchRules.LEGS))
	assert_false(flight.cockpit.poke_lit(CockpitTouchRules.STAGE), "STAGE is dark now")
	_finger(&"left", CockpitTouchRules.LEGS, 0.03)
	_finger(&"left", CockpitTouchRules.LEGS, -0.002)
	assert_ne(flight.run.waiting_for(), FlightPlan.LEGS, "legs out, by the left hand's finger")


func test_a_dark_button_only_clicks_softly_and_a_crew_member_never_stages() -> void:
	_start()
	flight.tick(0.05)
	_finger(&"right", CockpitTouchRules.STAGE, 0.03)
	_finger(&"right", CockpitTouchRules.STAGE, -0.002)
	assert_eq(flight.run.dropped(), 0, "nothing staged")
	assert_eq(float(flight.vr_haptic_log.back()[1]), float(CockpitTouchRules.DARK[0]), "a soft click")
	assert_true(_fly_until(func() -> bool: return flight.run.waiting_for() == FlightPlan.STAGE), "waits for STAGE")
	flight.crew_follow = true
	_finger(&"right", CockpitTouchRules.STAGE, 0.03)
	_finger(&"right", CockpitTouchRules.STAGE, -0.002)
	assert_eq(flight.run.waiting_for(), FlightPlan.STAGE, "the pilot flies: a crew member's STAGE does nothing")


func test_lights_turn_the_cabin_lights_off_and_on() -> void:
	_start()
	flight.tick(0.05)
	var mat := flight.vr_capsule().material_override as ShaderMaterial
	var on: Color = mat.get_shader_parameter(&"shell")
	_finger(&"right", CockpitTouchRules.LIGHTS, 0.03)
	_finger(&"right", CockpitTouchRules.LIGHTS, -0.002)
	assert_false(flight.cabin_lights, "off")
	var off: Color = mat.get_shader_parameter(&"shell")
	assert_lt(off.get_luminance(), on.get_luminance() * 0.6, "the capsule goes dark: the stars show better")
	assert_false(flight.cockpit.poke_lit(CockpitTouchRules.LIGHTS))
	_finger(&"right", CockpitTouchRules.LIGHTS, 0.05)
	_finger(&"right", CockpitTouchRules.LIGHTS, -0.002)
	assert_true(flight.cabin_lights, "on again")
	assert_eq(mat.get_shader_parameter(&"shell"), on)


func test_the_finger_stops_at_the_panel() -> void:
	_start()
	flight.tick(0.05)
	_finger(&"right", CockpitTouchRules.LIGHTS, 0.03)
	_finger(&"right", CockpitTouchRules.LIGHTS, -0.03)   # the real hand 3 cm behind the panel
	var model := Vr.hand_models[&"right"] as VrHandModel
	var tip := CockpitTouchRules.fingertip(model.global_transform, &"right", model.trigger)
	var z := (flight.vr_dashboard().global_transform.affine_inverse() * tip).z
	assert_almost_eq(z, 0.0, 0.002, "the hand's picture stops with its fingertip on the panel")


func test_the_burn_rumbles_in_short_pulses_and_the_countdown_ticks() -> void:
	_start()
	_fly_until(func() -> bool: return flight.run.phase() == FlightPlan.ASCENT and flight.run.progress() > 0.3)
	var ticks := flight.vr_haptic_log.filter(func(p: Array) -> bool: return float(p[3]) == float(CockpitTouchRules.TICK[2]))
	assert_eq(ticks.size(), CockpitTouchRules.TICKS_FROM, "3, 2, 1 tick on the hands")
	var rumble := flight.vr_haptic_log.filter(func(p: Array) -> bool: return float(p[3]) == CockpitTouchRules.RUMBLE_HZ)
	assert_gt(rumble.size(), 10, "the lift-off and the climb rumble")
	for i in rumble.size():
		assert_lte(float(rumble[i][2]), CockpitTouchRules.RUMBLE_PULSE, "short pulses")
		assert_lte(float(rumble[i][1]), CockpitTouchRules.RUMBLE_MAX, "capped")
		if i > 0:
			assert_gte(float(rumble[i][0]) - float(rumble[i - 1][0]), CockpitTouchRules.RUMBLE_EVERY - 0.051, "with gaps")
	assert_gte(float(rumble[0][0]), float(ticks[0][0]) - 0.06, "the engines light at T-3: never a rumble before")


func test_more_throttle_rumbles_stronger_in_the_descent() -> void:
	_start(true, true)
	assert_true(_fly_until(func() -> bool: return flight.run.phase() == FlightPlan.DESCENT, 60.0), "the descent")
	var amp := {}
	for thr: float in [0.25, 1.0]:
		flight.vr_haptic_log.clear()
		for i in 20:
			flight.cockpit.throttle = thr
			flight.tick(0.05)
		var r := flight.vr_haptic_log.filter(func(p: Array) -> bool: return float(p[3]) == CockpitTouchRules.RUMBLE_HZ)
		assert_false(r.is_empty(), "it rumbles at %.2f" % thr)
		amp[thr] = float(r.back()[1]) if not r.is_empty() else 0.0
	assert_gt(float(amp[1.0]), float(amp[0.25]), "a full throttle rumbles stronger")
