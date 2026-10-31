extends GutTest
## Owner #106 in a headset (owner #101, #108 "continue and finish vr"): the Moon descent the child flies, flown with
## the controllers only (Vr.simulate; the trigger through VrInput, the Input map and the cockpit, never the cockpit's
## throttle set by hand). The trigger is the throttle lever: as far as it is squeezed (half a squeeze half the
## throttle, at once) and it falls back at the lever's spring when let go; a child who squeezes when it falls too fast
## lands softly with fuel left, and nobody squeezing crashes (no autopilot in VR either). A is GO on the first try's
## card. The lander never lurches the seated child (no tip, no shake); a practice's next try is a dip to black; the
## whole trip has no cut the child sees. After a crash the way home is fade cuts, never one long black: the capsule
## heading home and the re-entry seen from the seat, then, from a still spot on the ground by the pad, the capsule
## coming down under its parachute and the rocket falling (the controllers buzz where the flat game shakes).

const DT := 1.0 / 30.0
## A head going this much further than the frame before went (metres) is a cut: a seat riding a climbing rocket goes
## steadily, a cut moves it all at once. (A step's first frame starts it at its 0, so the rocket stalls for one frame
## where two steps meet: at most one frame's move, 0.44 m at the climb's start, under this.)
const CUT := 1.0
## In the descent and the crash the lander is still round the seated child (the ground moves): metres a frame at most.
const STILL := 0.05

var flight: RocketFlight
var ui: Control
var stand: Node3D
var landed_at: Array[int] = []
var crashed_at: Array[int] = []
var wrecks := 0


func before_each() -> void:
	landed_at.clear()
	crashed_at.clear()
	wrecks = 0
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.make_current()
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child_autofree(ui)
	stand = Node3D.new()   # stands in for the player's feet
	add_child_autofree(stand)
	Vr.simulate(true)
	Vr.anchor(stand, &"feet")
	flight = _new_flight()
	FlightTicket.parked = {}


func _new_flight() -> RocketFlight:
	var f := RocketFlight.new()
	f.auto_tick = false
	f.ui_parent = ui
	f.wreck = func() -> Dictionary:
		wrecks += 1
		return {"count": 9, "gold": 120}
	f.landed.connect(func(u: int) -> void: landed_at.append(u))
	f.crashed.connect(func(u: int) -> void: crashed_at.append(u))
	add_child_autofree(f)
	return f


func after_each() -> void:
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	Vr.sim_input(VrRules.RIGHT, &"ax_button", false)
	if Vr.input:
		Vr.input.release_all()
	Input.flush_buffered_events()
	Vr.simulate(false)
	Vr.anchor(null)
	FlightTicket.parked = {}
	Input.action_release(&"rocket_throttle")


## Up to the descent as the flat tests fly it (the cockpit's throttle from the run, the steps' presses).
func _to_descent() -> void:
	var t := 0.0
	while flight.is_active() and flight.run.phase() != FlightPlan.DESCENT and t < 300.0:
		flight.cockpit.throttle = flight.run.test_throttle()
		if flight.run.waiting_for() in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			flight.cockpit.action_pressed.emit()
		flight.tick(0.1)
		t += 0.1
	flight.cockpit.throttle = 0.0


## One frame in the headset, in a frame's order: the right trigger at `squeeze` (A held when `a`), Vr's frame (the
## controllers read, the fade stepped), the input map, the cockpit's lever, the flight.
func _frame(squeeze: float, a: bool = false, dt: float = DT) -> void:
	Vr.sim_input(VrRules.RIGHT, &"trigger", squeeze)
	Vr.sim_input(VrRules.RIGHT, &"ax_button", a)
	Vr.step(dt)
	Input.flush_buffered_events()
	flight.cockpit._process(dt)
	flight.tick(dt)


## A child at the trigger: squeezes all the way while it falls faster than a safe glide down (1 m/s at the ground), lets
## go otherwise (never a half squeeze, never the run's own pilot).
static func _child(d: FlightDescent) -> float:
	var want := sqrt(1.0 + 2.0 * 0.35 * (d.thrust - d.gravity) * maxf(d.height, 0.0))
	return 1.0 if d.speed > want else 0.0


func test_the_trigger_alone_lands_the_moon_descent_softly() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	_to_descent()
	assert_eq(flight.run.phase(), FlightPlan.DESCENT)
	assert_true(Vr.seated(), "in the lander's seat")
	var d := flight.run.descent
	var st := {"squeezed": 0, "let_go": 0, "t": 0.0}
	while flight.is_active() and flight.run.phase() == FlightPlan.DESCENT and float(st.t) < 120.0:
		var s := _child(d)
		st.squeezed = int(st.squeezed) + (1 if s > 0.0 else 0)
		st.let_go = int(st.let_go) + (1 if s == 0.0 else 0)
		_frame(s)
		st.t = float(st.t) + DT
	gut.p("VR descent by the trigger: touchdown %.2f m/s, %.1f s of fuel left, %.1f s down" % [d.touchdown_speed,
		d.fuel, d.time])
	assert_eq(d.state, FlightDescent.LANDED, "a soft landing")
	assert_lte(d.touchdown_speed, FlightDescent.SAFE_SPEED, "at or under 3 m/s")
	assert_gt(d.fuel, 0.0, "with fuel left")
	assert_false(flight.run.helped(), "the child landed it, not Mission Control")
	assert_gt(int(st.squeezed), 30, "the trigger did the braking")
	assert_gt(int(st.let_go), 30, "and was let go between")
	while flight.is_active():
		_frame(0.0)
	assert_eq(landed_at, [SpaceRules.MOON], "landed once")
	assert_eq(crashed_at, [] as Array[int])


func test_the_whole_trip_with_the_controllers_only_never_jumps_the_head_unseen() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var st := {"t": 0.0, "last": Vr.head_transform().origin, "step": Vector3.ZERO, "jumps": [], "a_was": false,
		"presses": 0}
	while flight.is_active() and float(st.t) < 400.0:
		var run := flight.run
		var waiting := run.waiting_for()
		var squeeze := 0.0
		if waiting == FlightPlan.DESCEND and run.descent != null:
			squeeze = _child(run.descent)
		elif run.test_throttle() > 0.5:
			squeeze = 1.0   # lift-off and the burns: the trigger all the way
		var a := waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE] and not bool(st.a_was)
		st.a_was = a
		st.presses = int(st.presses) + (1 if a else 0)
		_frame(squeeze, a)
		st.t = float(st.t) + DT
		var moved := _jolt(st)
		var near := _near()
		var seen_near := near or bool(st.get("near", false))   # (near this frame or the last: a jump into space too)
		st.near = near
		if flight.is_active() and seen_near and moved > CUT and Vr.fade_amount() < 0.99:
			(st.jumps as Array).append("%s at %.3f: %.2f m, black %.2f" % [run.phase(), run.progress(), moved,
				Vr.fade_amount()])
	assert_eq(landed_at, [SpaceRules.MOON], "lift-off, the burns, the stages and the descent: all by the controllers")
	assert_gt(int(st.presses), 0, "A did the stages, the legs and the parachute")
	assert_eq(st.jumps, [], "the seat never jumps the head where the child sees it")


func test_the_climb_goes_on_at_the_lift_offs_speed_never_stopping_dead() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var secs := {}
	for s: Dictionary in flight.run.steps:
		secs[s.phase] = float(s.seconds)
	var e := 0.002
	var info := {"done": true, "destination": SpaceRules.MOON}
	var lift_end := (float(FlightShots.pose(FlightPlan.LIFTOFF, 1.0, info).rise)
		- float(FlightShots.pose(FlightPlan.LIFTOFF, 1.0 - e, info).rise)) / (e * float(secs[FlightPlan.LIFTOFF]))
	var climb_start := (float(FlightShots.pose(FlightPlan.ASCENT, e, info).rise)
		- float(FlightShots.pose(FlightPlan.ASCENT, 0.0, info).rise)) / (e * float(secs[FlightPlan.ASCENT]))
	assert_gt(lift_end, 10.0, "the lift-off ends fast")
	assert_almost_eq(climb_start, lift_end, lift_end * 0.15, "and the climb starts at that speed (m/s)")
	assert_almost_eq(float(FlightShots.pose(FlightPlan.ASCENT, 0.0, info).rise), 40.0, 0.001, "from where it got to")


func test_nobody_squeezing_crashes_no_autopilot_in_vr_either() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	_to_descent()
	var t := 0.0
	while flight.run.phase() == FlightPlan.DESCENT and t < 120.0:
		_frame(0.0)
		t += DT
	assert_true(flight.run.crashed())
	assert_gt(flight.run.descent.touchdown_speed, FlightDescent.SAFE_SPEED)


func test_the_trigger_is_the_lever_half_a_squeeze_half_the_throttle_at_once() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	_frame(0.6)
	var half := flight.cockpit.throttle
	for i in 20:
		_frame(0.6)
	assert_almost_eq(half, 0.5, 0.02, "0.6 of the trigger past its 0.2 dead zone is half the throttle, at once")
	assert_almost_eq(flight.cockpit.throttle, 0.5, 0.02, "and stays there (no climb to full)")
	_frame(1.0)
	assert_almost_eq(flight.cockpit.throttle, 1.0, 0.001, "all the way: full at once")
	_frame(0.0, false, 0.1)
	assert_almost_eq(flight.cockpit.throttle, 1.0 - 0.1 * FlightCockpit.THROTTLE_SPRING, 0.01,
		"let go: it falls back at the lever's spring")
	assert_almost_eq(flight.cockpit.lever.value, flight.cockpit.throttle, 0.001, "the dashboard's lever shows it")


func test_off_vr_a_pulled_trigger_still_climbs_to_full() -> void:
	Vr.simulate(false)
	var flat := _new_flight()
	flat.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	assert_false(flat.cockpit.analog_throttle, "the flat game's lever, keys and pads as before")
	assert_true(flight.cockpit == null or not flight.cockpit.analog_throttle)


func test_a_is_go_on_the_first_try_card() -> void:
	flight.first_try = true
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	_to_descent()
	_frame(0.0)
	assert_true(flight.run.descent.held(), "the hint card holds the descent")
	var h := flight.run.descent.height
	_frame(0.0, true)
	_frame(0.0, false)
	assert_false(flight.run.descent.held(), "A on the right controller is GO")
	for i in 10:
		_frame(0.0)
	assert_lt(flight.run.descent.height, h, "the descent is on")


## How far the head went this frame off the way it was going (a rocket climbing fast moves it steadily; a jump moves it
## all at once): `st` keeps "last" (the head's place) and "step" (the last frame's move).
static func _jolt(st: Dictionary) -> float:
	var at := Vr.head_transform().origin
	var step := at - (st.last as Vector3)
	var off := (step - (st.step as Vector3)).length() if not bool(st.get("jumped", false)) else 0.0
	st.jumped = off > CUT   # (the frame after a jump goes on from where it landed: no second jump)
	st.moved = step.length()
	st.last = at
	st.step = step
	return off


## Something near is in view (the real world, or a ground under 300 m in the space set): a head's jump shows against
## it. Out in space only the stars and far worlds are round the capsule (a seat swinging a metre is not seen).
func _near() -> bool:
	var p := flight.pose
	return bool(p.get("world", false)) or (bool(p.get("ground", false)) and float(p.get("ground_h", INF)) < 300.0)


## Degrees round from where `node` faces to `at` (seen from above).
static func _off_ahead(node: Node3D, at: Vector3) -> float:
	var fwd := -node.global_basis.z
	var to := at - node.global_position
	return absf(rad_to_deg(Vector2(fwd.x, fwd.z).angle_to(Vector2(to.x, to.z))))


## Flies the descent with nobody squeezing and plays the way home to its end, a frame at a time: what the head saw.
func _crash_and_watch() -> Dictionary:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	_to_descent()
	var st := {"last": Vr.head_transform().origin, "step": Vector3.ZERO, "phase": &"", "jumps_seen": [], "shake": 0.0,
		"black_run": 0.0, "longest_black": 0.0, "seen": {}, "first_fade": {}, "spot_moved": 0.0, "spot": Vector3.INF,
		"level": true, "shell_at_spot": [], "shell_seated": [], "rocket_drawn": {}, "wreck_ahead": -1.0,
		"capsule_ahead": -1.0, "dash_ahead": true, "buzz_crash": 0, "buzz_hit": 0, "t": 0.0}
	var buzzes := Vr.haptics
	var was_hit := false
	var was_crashed := false
	while flight.is_active() and float(st.t) < 200.0:
		_frame(0.0)
		st.t = float(st.t) + DT
		if not flight.is_active():
			break
		var phase := flight.run.phase()
		var fade := Vr.fade_amount()
		var head := Vr.head_transform()
		var moved := _jolt(st)
		if phase != st.phase:
			(st.first_fade as Dictionary)[phase] = fade
			st.phase = phase
		var near := _near()
		var seen_near := near or bool(st.get("near", false))
		st.near = near
		if seen_near and moved > CUT and fade < 0.99:
			(st.jumps_seen as Array).append("%s %.2f m at black %.2f" % [phase, moved, fade])
		if phase in [FlightPlan.DESCENT, FlightPlan.CRASH] and float(st.moved) > STILL and fade < 0.99:
			(st.jumps_seen as Array).append("%s lurched %.2f m at black %.2f" % [phase, float(st.moved), fade])
		st.shake = maxf(float(st.shake), float(flight.pose.shake))
		st.black_run = float(st.black_run) + DT if fade >= 0.99 else 0.0
		st.longest_black = maxf(float(st.longest_black), float(st.black_run))
		(st.seen as Dictionary)[phase] = maxf(float((st.seen as Dictionary).get(phase, 0.0)), 1.0 - fade)
		var mask_has_rocket := (Vr.camera.cull_mask & RocketFlight.ROCKET_LAYER) != 0
		(st.rocket_drawn as Dictionary)[phase] = mask_has_rocket
		var capsule := flight.get_node("VrSeat/VrCapsule") as VrCapsule
		if phase in [FlightPlan.HOME_CHUTE, FlightPlan.WRECK, FlightPlan.HOME]:
			var seat := flight.get_node("VrSeat") as Node3D
			if (st.spot as Vector3) != Vector3.INF:
				st.spot_moved = maxf(float(st.spot_moved), seat.global_position.distance_to(st.spot as Vector3))
			st.spot = seat.global_position
			st.level = bool(st.level) and seat.global_basis.y.dot(Vector3.UP) > 0.999
			(st.shell_at_spot as Array).append(capsule.layers)
			st.capsule_ahead = maxf(float(st.capsule_ahead), _off_ahead(seat, flight.body.global_position))
			if flight.wreck_node != null and flight.wreck_node.visible:
				st.wreck_ahead = maxf(float(st.wreck_ahead), _off_ahead(seat, flight.wreck_node.global_position))
			var dash := flight.vr_dashboard()
			st.dash_ahead = bool(st.dash_ahead) and (head.affine_inverse() * dash.global_position).z < 0.0
		else:
			(st.shell_seated as Array).append(capsule.layers)
		if flight.run.crashed() and not was_crashed:
			was_crashed = true
			st.buzz_crash = Vr.haptics - buzzes
		if flight._wreck_hit and not was_hit:
			was_hit = true
			st.buzz_hit = Vr.haptics - buzzes - int(st.buzz_crash)
	return st


func test_the_crash_never_lurches_nor_shakes_the_seated_child() -> void:
	var st := _crash_and_watch()
	assert_eq(crashed_at, [SpaceRules.MOON], "crashed once")
	assert_eq(float(st.shake), 0.0, "never a shake in VR")
	assert_eq(st.jumps_seen, [], "every jump of the head is under black (the lander's tip is no lurch in VR)")
	assert_gt(int(st.buzz_crash), 0, "the crash's bump is the controllers' buzz")
	assert_gt(int(st.buzz_hit), 0, "and so is the rocket hitting the ground")


func test_the_way_home_is_fade_cuts_never_one_long_black() -> void:
	var st := _crash_and_watch()
	gut.p("VR way home: %.1f s, longest black %.2f s, first frames %s" % [float(st.t), float(st.longest_black),
		str(st.first_fade)])
	assert_eq(crashed_at, [SpaceRules.MOON])
	assert_eq(wrecks, 1, "the rocket's parts broke once")
	assert_lt(float(st.longest_black), 3.0, "never black for more than about 3 s (the research's rule)")
	for phase: StringName in [FlightPlan.ESCAPE, FlightPlan.HOME_ENTRY, FlightPlan.HOME_CHUTE, FlightPlan.WRECK,
			FlightPlan.HOME]:
		assert_gt(float((st.seen as Dictionary).get(phase, 0.0)), 0.9, "%s is seen, not black" % phase)
	var first: Dictionary = st.first_fade
	assert_gte(float(first.get(FlightPlan.ESCAPE, 0.0)), 0.99, "the cut from the Moon to the way home is black")
	assert_gte(float(first.get(FlightPlan.HOME_ENTRY, 0.0)), 0.99, "and the rocket turning round for the re-entry")
	assert_gte(float(first.get(FlightPlan.HOME_CHUTE, 0.0)), 0.99, "and the cut from the seat to the spot by the pad")
	assert_false(Vr.seated(), "the seat let go: the child stands by the Launch Site")
	assert_eq(Vr.anchor_node(), stand)


func test_the_end_of_the_way_home_is_watched_from_a_still_spot_by_the_pad() -> void:
	var st := _crash_and_watch()
	gut.p("VR spot: the capsule within %.0f°, the falling rocket within %.0f° of ahead" % [float(st.capsule_ahead),
		float(st.wreck_ahead)])
	assert_lt(float(st.spot_moved), 0.01, "the spot never moves (the capsule and the rocket do)")
	assert_true(st.level, "level: the child's own head looks up at the parachute")
	var at_spot: Array = st.shell_at_spot
	var seated: Array = st.shell_seated
	assert_false(at_spot.is_empty())
	assert_eq(at_spot.max(), 0, "out in the open: the capsule's round room is not drawn round the spot")
	assert_gt(seated.min(), 0, "in the seat the capsule's round room is round the child")
	var drawn: Dictionary = st.rocket_drawn
	assert_true(bool(drawn.get(FlightPlan.WRECK, false)), "the rocket and the capsule are drawn from the spot")
	assert_false(bool(drawn.get(FlightPlan.ESCAPE, true)), "never from inside (its own hull)")
	assert_between(float(st.capsule_ahead), 0.0, 60.0, "the capsule coming down is in front of the child")
	assert_between(float(st.wreck_ahead), 0.0, 60.0, "and so is the rocket falling")
	assert_true(st.dash_ahead, "the dashboard's words stay ahead of the eyes")


func test_a_practice_try_again_is_a_dip_to_black() -> void:
	flight.land(SpaceRules.MOON)
	assert_true(flight.run.practice)
	var st := {"h": INF, "resets": 0, "fade_at_reset": [],
		"black_run": 0.0, "longest_black": 0.0, "t": 0.0}
	while flight.is_active() and float(st.t) < 120.0:
		_frame(0.0)
		st.t = float(st.t) + DT
		if not flight.is_active() or flight.run.descent == null:
			continue
		var h := flight.run.descent.height
		if h > float(st.h) + 10.0:
			st.resets = int(st.resets) + 1
			(st.fade_at_reset as Array).append(Vr.fade_amount())
		st.h = h
		var fade := Vr.fade_amount()
		st.black_run = float(st.black_run) + DT if fade >= 0.99 else 0.0
		st.longest_black = maxf(float(st.longest_black), float(st.black_run))
	assert_eq(landed_at, [SpaceRules.MOON], "Mission Control lands the last try")
	assert_eq(int(st.resets), FlightRun.PRACTICE_TRIES - 1, "two tries again from the top")
	for f: float in st.fade_at_reset:
		assert_gte(f, 0.99, "the lander back at the top is a jump: under black")
	assert_lt(float(st.longest_black), 3.0)
