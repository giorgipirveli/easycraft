extends GutTest
## Owner #118 (docs/design/life-skills.md §14; Life L3b): the second part of the dangers wave in the room host, flat and
## in a simulated headset. Safe Streets' crossing at the wrong moment (a car coming, before the green man) is now a true
## safe mistake on the Middle track: time freezes, the street's gentle picture, the coach's why, GOT IT, then the child
## waits for the gap (Little keeps L2's kind miss: the car stops gently). Be a tree (a dog runs at you): flat, the BE A
## TREE button; in a headset, the head down, the hands in and still. Running from the dog, grabbing someone stuck to a
## current, tipping the head back for a nosebleed, water on a pan fire: each frozen safely.

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


func _open(exp_id: String, track: String, expert: bool = false) -> LifeRoomHost:
	host = LifeRoomHost.new()
	host.setup(exp_id, track, expert, 1, "ge")
	host.finished.connect(func(o: Dictionary) -> void: outcomes.append(o))
	host.open(parent)
	await wait_process_frames(3)
	return host


func _vr_open(exp_id: String, track: String) -> LifeRoomHost:
	Vr.simulate(true)
	await wait_process_frames(2)
	return await _open(exp_id, track)


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


const LIMIT := 3.0


func _taken() -> void:
	await wait_process_frames(1)
	await wait_until(func() -> bool: return host.closed or (host._pressed.is_empty() and host._answer < 0 and host._action == ""),
		LIMIT, "the host took the input")


func _tap(target: String) -> void:
	host.finger_down(host.screen_of(target))
	await _taken()
	host.finger_up()


# --- Safe Streets: the wrong moment ----------------------------------------------------------------------------------

func test_flat_stepping_out_from_behind_the_van_while_a_car_comes_freezes_time() -> void:
	await _open("safe_streets", "middle")
	var street := host.room as StreetRoom
	_jump("cross_van")
	while street.traffic.safe_gap(street.cross_x(host.run.current())):
		street.traffic.step(0.05)
	await wait_process_frames(1)
	await _tap("far_kerb_van")
	assert_true(host.frozen, "time froze: a safe mistake, never L2's miss")
	assert_eq(host.room.mistake_shown, "step_out_van")
	assert_not_null(host.room.get_node_or_null(^"MistakePicture"), "the street's gentle picture")
	assert_string_contains(host.hud.mistake_why.text, "can't see you")
	assert_eq(host.run.total_hints(), 0, "never a miss")
	assert_eq(host.run.total_mistakes(), 1)
	assert_eq(street.traffic.cars.filter(func(car: Dictionary) -> bool: return str(car.why) == "child").size(), 0,
		"no car had to stop: the child never left the van's edge")
	var xs: Array = street.traffic.cars.map(func(car: Dictionary) -> float: return float(car.x))
	await wait_process_frames(5)
	assert_eq(street.traffic.cars.map(func(car: Dictionary) -> float: return float(car.x)), xs, "the cars stand still")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	assert_false(host.frozen, "GOT IT")
	assert_true(_at("cross_van"), "then wait for the gap")
	while not street.traffic.safe_gap(street.cross_x(host.run.current())) \
			or street.traffic.time_to_next() < LifeTraffic.CROSS_SECONDS + 1.0:
		street.traffic.step(0.05)
	await _tap("far_kerb_van")
	await wait_until(func() -> bool: return not _at("cross_van"), LIMIT, "across, at the right moment")
	assert_false(_at("cross_van"))
	assert_eq(host.run.total_hints(), 0, "the By myself stamp stays")


func test_little_keeps_the_kind_miss_and_the_car_stops_gently() -> void:
	await _open("safe_streets", "little")
	var street := host.room as StreetRoom
	_jump("cross")
	while street.traffic.safe_gap():
		street.traffic.step(0.05)
	await wait_process_frames(1)
	await _tap("far_kerb")
	assert_false(host.frozen, "on the Little track no mistake is ever shown")
	assert_eq(host.run.hints_on(host.run.index), 1, "a kind miss")


func test_vr_the_trigger_before_the_green_man_freezes_time() -> void:
	await _vr_open("safe_streets", "middle")
	var street := host.room as StreetRoom
	_jump("green")
	await wait_process_frames(2)
	assert_false(street.safe_now(host.run.current()), "the red man first")
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 1.0)
	await wait_until(func() -> bool: return host.frozen, LIMIT, "frozen")
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 0.0)
	assert_true(host.frozen)
	assert_eq(host.room.mistake_shown, "step_out_red")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	assert_false(host.frozen)
	assert_true(_at("green"))


# --- Be a tree, and running from the dog -------------------------------------------------------------------------------

func test_flat_running_from_the_dog_freezes_time_then_be_a_tree() -> void:
	await _open("animals", "middle")
	_jump("tree")
	await wait_process_frames(2)
	assert_eq(str(host.hud.action_button.get_meta(&"words")), "BE A TREE", "the action's own words")
	assert_true(host.room.time_scale < 1.0, "a danger moment: the dog runs slowly on a first try")
	await _tap("run_away")
	assert_true(host.frozen, "running from the dog: time freezes")
	assert_eq(host.room.mistake_shown, "dog_chase")
	assert_not_null(host.room.get_node_or_null(^"MistakePicture"), "a figure running, the dog bounding after: still")
	assert_string_contains(host.hud.mistake_why.text, "chase")
	assert_eq(host.run.total_hints(), 0)
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	host.hud.action_pressed.emit("tree")
	await wait_until(func() -> bool: return not _at("tree"), LIMIT, "a tree")
	assert_false(_at("tree"), "BE A TREE: done")
	assert_eq(host.run.total_hints(), 0, "the By myself stamp stays")


func test_vr_be_a_tree_is_the_head_down_the_hands_in_and_still() -> void:
	await _vr_open("animals", "little")
	_jump("tree")
	await wait_process_frames(2)
	var to_play := Vr.rig.global_transform.affine_inverse()
	var stand := host.stand.global_position
	var b := host.stand.global_basis
	Vr.sim_head(to_play * Transform3D(b, stand))   # looking ahead, hands out: not a tree
	Vr.sim_hand(VrRules.LEFT, to_play * Transform3D(Basis(), stand + b * Vector3(-0.35, -0.3, -0.45)))
	Vr.sim_hand(VrRules.RIGHT, to_play * Transform3D(Basis(), stand + b * Vector3(0.35, -0.3, -0.45)))
	await wait_seconds(1.5)
	assert_eq(float(host.run.state.get("t", 0.0)), 0.0, "looking ahead with the arms out is not a tree")
	var down := b * Basis(Vector3.RIGHT, -0.7)   # the head tipped down: looking at the feet
	Vr.sim_head(to_play * Transform3D(down, stand))
	Vr.sim_hand(VrRules.LEFT, to_play * Transform3D(Basis(), stand + b * Vector3(-0.12, -0.55, -0.12)))
	Vr.sim_hand(VrRules.RIGHT, to_play * Transform3D(Basis(), stand + b * Vector3(0.12, -0.55, -0.12)))
	await wait_until(func() -> bool: return not _at("tree"), 3.0 / maxf(host.danger_scale, 0.01) + 3.0, "still as a tree")
	assert_false(_at("tree"), "head down, arms in, still: a tree")


# --- Electricity, medical, the pan fire ---------------------------------------------------------------------------------

## The smoke found it: a hand at the RCD's test button also touched the fuse box's bigger cover target (the nearest by its
## radius). Once the cover is touched, its target goes.
func test_vr_a_hand_at_the_rcd_presses_the_rcd() -> void:
	await _vr_open("electricity", "big")
	_jump("fuse_box")
	await wait_process_frames(2)
	var to_play := Vr.rig.global_transform.affine_inverse()
	var squeeze := func(target: String) -> void:
		Vr.sim_hand(VrRules.RIGHT, to_play * Transform3D(Basis(), host.room.target_position(target)))
		Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	squeeze.call("fuse_box")
	await wait_process_frames(2)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_until(func() -> bool: return _at("rcd") and host._pause <= 0.0, LIMIT + LifeRoomHost.DONE_PAUSE,
		"the cover touched, the RCD's step began")
	assert_false(host.room.target_node("fuse_box").is_visible_in_tree(), "the cover's target is gone")
	squeeze.call("rcd_test")
	await wait_process_frames(3)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_until(func() -> bool: return not _at("rcd"), LIMIT, "the test button pressed")
	assert_false(_at("rcd"), "a hand at the RCD presses the RCD")

func test_flat_grabbing_someone_stuck_to_electricity_freezes_time() -> void:
	await _open("electricity", "big")
	_jump("stuck_info")
	await wait_process_frames(1)
	_jump("stuck")
	await wait_process_frames(2)
	await _tap("gus_stuck")
	assert_true(host.frozen)
	assert_eq(host.room.mistake_shown, "current_through")
	assert_string_contains(host.hud.mistake_why.text, "through you too")
	assert_string_contains(host.hud.mistake_right.text, "112", "the region's number in the right way")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	assert_has(host.room.glowing(), "main_switch", "the right way glows")
	await _tap("main_switch")
	await wait_until(func() -> bool: return not _at("stuck"), LIMIT, "the power off")
	assert_false(_at("stuck"))


func test_flat_tipping_the_head_back_for_a_nosebleed_freezes_time() -> void:
	await _open("medical", "middle")
	_jump("nose")
	await wait_process_frames(2)
	await _tap("head_back")
	assert_true(host.frozen)
	assert_eq(host.room.mistake_shown, "throat")
	assert_string_contains(host.hud.mistake_right.text, "lean forward")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	await _tap("lean_forward")
	await wait_until(func() -> bool: return not _at("nose"), LIMIT, "leaning forward")
	assert_false(_at("nose"))


func test_flat_water_on_a_pan_fire_is_frozen_before_the_flare() -> void:
	await _open("kitchen", "middle")
	_jump("pan_fire")
	await wait_process_frames(1)
	_jump("lid")
	await wait_process_frames(2)
	var kitchen := host.room as KitchenRoom
	assert_true(kitchen.flame.visible, "the pan's flame")
	await _tap("water_jug")
	assert_true(host.frozen, "the water jug: frozen before the flare")
	assert_eq(host.room.mistake_shown, "flare")
	assert_string_contains(host.hud.mistake_why.text, "lid")
	var s := kitchen.flame.scale
	await wait_process_frames(5)
	assert_eq(kitchen.flame.scale, s, "the flame stands still")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	await _tap("pan_lid")
	await wait_until(func() -> bool: return not _at("lid"), LIMIT, "the lid on")
	assert_false(kitchen.flame.visible, "the lid keeps the air out")
