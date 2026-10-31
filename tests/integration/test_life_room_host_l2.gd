extends GutTest
## Owner #112, #113 (docs/design/life-skills.md §4, §5 #4-#6, §10; Life L2): L2's steps in the room host, flat and in a
## simulated headset. Flat: a LOOK swipe or button looks that way (the view turns, then comes back); a tap across the
## road when a car is coming is a kind miss and the car stops gently; rubbing is a finger moving on the hands; pouring,
## breathing and the pedal are a finger held; a feeling is any picture. VR: the head's turn looks; the hand at the jug,
## squeezing and tilted, pours; the hands rising breathe in; the trigger is the pedal; both hands moving at the sink rub;
## the hand's own path across the food cuts. The HUD shows each step's own controls.

var host: LifeRoomHost
var parent: Node
var outcomes: Array = []


func before_each() -> void:
	outcomes.clear()
	parent = Node.new()
	add_child_autofree(parent)


func after_each() -> void:
	if is_instance_valid(host) and not host.closed:
		host.close()
	Vr.simulate(false)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(exp_id: String, track: String, expert: bool = false, region: String = "ge") -> LifeRoomHost:
	host = LifeRoomHost.new()
	host.setup(exp_id, track, expert, 1, region)
	host.finished.connect(func(o: Dictionary) -> void: outcomes.append(o))
	host.open(parent)
	await wait_process_frames(3)
	return host


## Straight to a step (the ones before it as if done).
func _jump(step_id: String) -> void:
	for i in host.run.steps.size():
		if str(host.run.steps[i].id) == step_id:
			host.run.index = i
			host.run.state = LifeCheck.begin(host.run.steps[i])
			host._pause = 0.0
			host._start_step()
			return
	fail_test("no step " + step_id)


func _at(step_id: String) -> bool:
	return str(host.run.current().get("id", "")) == step_id


## Waits for the state a step needs, never a count of frames (a busy PC: the lead's flake, 2026-10-16).
const LIMIT := 3.0


## Waits until one of the host's frames has sampled this frame's input (a press, a look, an answer).
func _taken() -> void:
	await wait_process_frames(1)
	await wait_until(func() -> bool: return host.closed or (host._pressed.is_empty() and host._answer < 0 and host._looked == ""),
		LIMIT, "the host took the input")


# --- Flat ------------------------------------------------------------------------------------------------------------

func test_flat_a_look_button_or_a_swipe_looks_that_way_and_the_view_turns() -> void:
	await _open("safe_streets", "little", false, "ge")
	_jump("look")
	await wait_process_frames(1)
	assert_true(host.hud.look_left.visible and host.hud.look_right.visible, "LOOK LEFT and LOOK RIGHT")
	var yaw := host.camera.global_basis.get_euler().y
	host.hud.look_pressed.emit("left")
	await _taken()
	assert_eq(int(host.run.state.i), 1, "looked left first (cars drive on the right in Georgia)")
	await wait_until(func() -> bool: return host.camera.global_basis.get_euler().y > yaw + 0.3, LIMIT, "turning left")
	assert_gt(host.camera.global_basis.get_euler().y, yaw + 0.3, "the view turned left")
	var c := LifeRoomHud.CANVAS * 0.5
	host.finger_down(c)
	host.finger_move(c + Vector2(260, 0))
	host.finger_up()
	await _taken()
	assert_eq(int(host.run.state.i), 2, "a swipe to the right looks right")
	await wait_until(func() -> bool: return host.camera.global_basis.get_euler().y < yaw - 0.3, LIMIT, "turning right")
	await wait_until(func() -> bool: return absf(host.camera.global_basis.get_euler().y - yaw) < 0.05,
		LIMIT + LifeRoomHost.LOOK_HOLD, "turning back")
	assert_almost_eq(host.camera.global_basis.get_euler().y, yaw, 0.05, "and the view comes back")


func test_flat_crossing_when_a_car_comes_is_a_kind_miss_and_the_car_stops() -> void:
	await _open("safe_streets", "little")
	var street := host.room as StreetRoom
	_jump("cross")
	while street.traffic.safe_gap():
		street.traffic.step(0.05)
	await wait_process_frames(1)
	assert_eq(host.room.glowing(), [] as Array[String], "nothing glows while a car comes")
	host.finger_down(host.screen_of("far_kerb"))
	await _taken()
	host.finger_up()
	assert_true(_at("cross"), "not across: wait")
	assert_eq(host.run.hints_on(host.run.index), 1, "a kind miss (the step shows again)")
	var stopping := street.traffic.cars.filter(func(car: Dictionary) -> bool: return str(car.why) == "child")
	assert_gt(stopping.size(), 0, "the coming cars stop gently")
	while not street.traffic.safe_gap():
		street.traffic.step(0.05)
	await wait_until(func() -> bool: return host.room.glowing() == (["far_kerb"] as Array[String]), LIMIT, "the glow")
	assert_eq(host.room.glowing(), ["far_kerb"] as Array[String], "a big gap: the other side glows")
	while not street.traffic.safe_gap(0.0) or street.traffic.time_to_next() < LifeTraffic.CROSS_SECONDS + 1.0:
		street.traffic.step(0.05)   # a gap with a second to spare: the host's next frame still sees it
	host.finger_down(host.screen_of("far_kerb"))
	await _taken()
	host.finger_up()
	assert_false(_at("cross"), "across")


func test_flat_rubbing_is_a_finger_moving_on_the_hands() -> void:
	await _open("kitchen", "little")
	_jump("rub")
	await wait_process_frames(1)
	assert_not_null(host.hud.clock, "the 20 seconds' clock")
	var at := host.screen_of("hands")
	host.finger_down(at)
	await wait_seconds(0.4)
	assert_almost_eq(float(host.run.state.t), 0.0, 0.05, "a finger held still is not rubbing")
	for i in 20:
		host.finger_move(at + Vector2(30.0 if i % 2 == 0 else -30.0, 0))
		await wait_process_frames(1)
	assert_gt(float(host.run.state.t), 0.05, "rubbing counts")
	host.finger_up()


func test_flat_pouring_is_a_finger_held_on_the_jug_and_let_go_at_the_line() -> void:
	await _open("kitchen", "little")
	_jump("pour")
	await wait_process_frames(1)
	assert_not_null(host.hud.gauge, "the cup's gauge")
	var want := float(host.run.current().want)
	host.finger_down(host.screen_of("jug"))
	while float(host.run.state.level) < want:
		await wait_process_frames(1)
	host.finger_up()
	await wait_until(func() -> bool: return not _at("pour"), LIMIT, "poured")
	assert_false(_at("pour"), "poured to the line")


func test_flat_breathing_is_holding_in_and_letting_go_out() -> void:
	await _open("calm_corner", "little")
	_jump("breathe")
	await wait_process_frames(1)
	assert_not_null(host.hud.breath, "the balloon guide")
	host.finger_down(host.screen_of("balloon"))
	await wait_until(func() -> bool: return str(host.run.state.phase) == "in", LIMIT, "breathing in")
	assert_eq(str(host.run.state.phase), "in")
	host.finger_up()
	await wait_until(func() -> bool: return str(host.run.state.phase) != "in", LIMIT, "breathing out")
	assert_ne(str(host.run.state.phase), "in")


func test_flat_a_feeling_is_any_picture() -> void:
	await _open("calm_corner", "little")
	_jump("me")
	await wait_process_frames(1)
	assert_gt(host.hud.choice_buttons.size(), 2, "the faces")
	host.hud.answered.emit(4)
	await _taken()
	assert_eq(host.run.total_hints(), 0, "never a miss, never a hint")
	assert_false(_at("me"))


func test_flat_the_pedal_held_raises_the_needle() -> void:
	await _open("safe_streets", "big")
	_jump("speed")
	await wait_process_frames(1)
	assert_not_null(host.hud.gauge, "the speedometer's gauge")
	host.finger_down(host.screen_of("accelerator"))
	await wait_until(func() -> bool: return float(host.run.state.value) > 2.0, LIMIT, "the needle rises")
	assert_gt(float(host.run.state.value), 2.0)
	host.finger_up()


# --- VR --------------------------------------------------------------------------------------------------------------

func _vr_open(exp_id: String, track: String) -> void:
	Vr.simulate(true)
	await wait_process_frames(2)
	await _open(exp_id, track)
	await wait_physics_frames(2)
	await wait_process_frames(2)


func _hand_at(side: StringName, world: Vector3, tilt: float = 0.0) -> void:
	Vr.sim_hand(side, Vr.rig.global_transform.affine_inverse() * Transform3D(Basis(Vector3.FORWARD, tilt), world))


func _head_turned(yaw: float) -> void:
	var stand := host.stand.global_transform
	Vr.sim_head(Vr.rig.global_transform.affine_inverse() * Transform3D(stand.basis * Basis(Vector3.UP, yaw), stand.origin))


func test_vr_the_heads_turn_looks_both_ways() -> void:
	await _vr_open("safe_streets", "little")
	_jump("look")
	await wait_process_frames(2)
	host.set_process(false)
	_head_turned(deg_to_rad(50.0))
	await wait_process_frames(1)
	var s := host._vr_sample(host.run.current(), 0.05)
	assert_gt(float(s.look_yaw), 0.6, "the head turned left")
	_head_turned(deg_to_rad(-50.0))
	await wait_process_frames(1)
	s = host._vr_sample(host.run.current(), 0.05)
	assert_lt(float(s.look_yaw), -0.6, "and right")


## A child who sits still: after the coach has shown a look twice, LOOK LEFT and LOOK RIGHT appear on the tray and look.
func test_vr_the_look_buttons_come_after_two_showings_and_look() -> void:
	await _vr_open("safe_streets", "little")
	_jump("look")
	await wait_process_frames(2)
	assert_false(host.hud.look_left.visible, "the head looks first")
	host.hud.coached()
	host.hud.coached()
	assert_true(host.hud.look_left.visible, "then the buttons, after two showings")
	host.set_process(false)
	host.hud.look_pressed.emit("left")
	assert_eq(str(host._vr_sample(host.run.current(), 0.05).get("looked", "")), "left")


func test_vr_the_hand_on_the_jug_squeezing_and_tilted_pours() -> void:
	await _vr_open("kitchen", "little")
	_jump("pour")
	await wait_process_frames(2)
	host.set_process(false)
	var jug := host.room.target_position("jug")
	_hand_at(VrRules.RIGHT, jug)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_process_frames(1)
	var s := host._vr_sample(host.run.current(), 0.05)
	assert_false((s.held as Array).has("jug"), "upright: not pouring yet")
	_hand_at(VrRules.RIGHT, jug, deg_to_rad(70.0))
	await wait_process_frames(1)
	s = host._vr_sample(host.run.current(), 0.05)
	assert_true((s.held as Array).has("jug"), "tilted: it pours")
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)


func test_vr_hands_rising_breathe_in_and_falling_breathe_out() -> void:
	await _vr_open("calm_corner", "little")
	_jump("breathe")
	await wait_process_frames(2)
	host.set_process(false)
	var eye := host.stand.global_position
	var fwd := -host.stand.global_basis.z
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		_hand_at(side, eye + fwd * 0.3 + Vector3(0, -0.7, 0))
	await wait_process_frames(1)
	assert_false((host._vr_sample(host.run.current(), 0.05).held as Array).has("balloon"), "hands low: breathing out")
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		_hand_at(side, eye + fwd * 0.3 + Vector3(0, -0.3, 0))
	await wait_process_frames(1)
	assert_true((host._vr_sample(host.run.current(), 0.05).held as Array).has("balloon"), "hands up: breathing in")


func test_vr_the_trigger_is_the_pedal() -> void:
	await _vr_open("safe_streets", "big")
	_jump("speed")
	await wait_process_frames(2)
	host.set_process(false)
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 1.0)
	await wait_process_frames(1)
	assert_true((host._vr_sample(host.run.current(), 0.05).held as Array).has("accelerator"))
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 0.0)
	await wait_process_frames(1)
	assert_false((host._vr_sample(host.run.current(), 0.05).held as Array).has("accelerator"))


func test_vr_both_hands_moving_at_the_sink_rub() -> void:
	await _vr_open("kitchen", "little")
	_jump("rub")
	await wait_process_frames(2)
	host.set_process(false)
	var at := host.room.target_position("hands")
	var rubbed := false
	for i in 8:
		var dx := 0.05 if i % 2 == 0 else -0.05
		_hand_at(VrRules.LEFT, at + Vector3(-0.04 + dx, 0, 0))
		_hand_at(VrRules.RIGHT, at + Vector3(0.04 - dx, 0, 0))
		await wait_process_frames(1)
		rubbed = rubbed or (host._vr_sample(host.run.current(), 0.05).get("rubbing", []) as Array).has("hands")
	assert_true(rubbed, "hands moving together at the sink: rubbing")


func test_vr_the_hands_own_path_across_the_food_cuts() -> void:
	await _vr_open("kitchen", "little")
	_jump("cut")
	await wait_process_frames(2)
	host.set_process(false)
	var at := host.room.target_position("cut_food")
	var right := host.stand.global_basis.x
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_hand_at(VrRules.RIGHT, at + right * 0.1)
	await wait_process_frames(1)
	var s := host._vr_sample(host.run.current(), 0.05)
	assert_gt(float(s.get("sweep_u", 0.0)), 0.5, "the knife hand on the right of the food")
	_hand_at(VrRules.RIGHT, at - right * 0.1)
	await wait_process_frames(1)
	s = host._vr_sample(host.run.current(), 0.05)
	assert_lt(float(s.get("sweep_u", 0.0)), -0.5, "and on its left")
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)


## In a headset the way across is straight ahead: the choice is when, so the trigger crosses (never at the panel's
## buttons). Unsafe: a kind miss and the cars stop; safe: across.
func test_vr_the_trigger_crosses_when_it_is_safe() -> void:
	await _vr_open("safe_streets", "little")
	var street := host.room as StreetRoom
	_jump("cross")
	while street.traffic.safe_gap():
		street.traffic.step(0.05)
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 1.0)
	await wait_until(func() -> bool: return host.run.hints_on(host.run.index) == 1, LIMIT, "a kind miss")
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 0.0)
	assert_true(_at("cross"), "not across: wait")
	assert_gt(street.traffic.cars.filter(func(car: Dictionary) -> bool: return str(car.why) == "child").size(), 0,
		"the coming cars stop gently")
	await wait_process_frames(2)
	while not street.traffic.safe_gap() or street.traffic.time_to_next() < LifeTraffic.CROSS_SECONDS + 1.0:
		street.traffic.step(0.05)
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 1.0)
	await wait_until(func() -> bool: return not _at("cross"), LIMIT, "across")
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 0.0)
	assert_false(_at("cross"), "across, at the right moment")
