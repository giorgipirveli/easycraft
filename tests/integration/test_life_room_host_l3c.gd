extends GutTest
## Owner #112, #118 (docs/design/life-skills.md §5 rows 7, 10, 11, §14; Life L3c): the three new Experiences in the room
## host, flat and in a simulated headset. Online City: answering a stranger (SEND PHOTO) freezes time, then BLOCK; in VR
## the play tablet is held in the off hand, facing the eyes, the other hand presses its buttons and the holding hand never
## does. Find Your Way: STAY HERE; walking off with someone who says "come with me" freezes time, then the shop worker;
## Big's platform edge while the train comes in. Home Helper: the watering can tilted over the plant in VR, the smoke
## alarm's test button held by hand, a knife pointing up is a kind miss (never a safe mistake: chores have none).

var host: LifeRoomHost
var parent: Node
var outcomes: Array = []


func before_each() -> void:
	Profile.data.settings.reduce_motion = true   # the views jump (a glide could leave a target behind the camera)
	outcomes.clear()
	parent = Node.new()
	add_child_autofree(parent)


func after_each() -> void:
	Profile.data.settings.reduce_motion = false
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


func _pick_up() -> void:
	_jump("pick")
	await wait_process_frames(2)
	host.room.step_done(host.run.current())   # picked up: the tablet is held from here on


# --- Online City -------------------------------------------------------------------------------------------------------

func test_flat_answering_a_stranger_freezes_time_then_block() -> void:
	await _open("online_city", "middle")
	await _pick_up()
	_jump("stranger")
	await wait_process_frames(2)
	await _tap("send_photo")
	assert_true(host.frozen, "answering the stranger: time freezes")
	assert_eq(host.room.mistake_shown, "photo_sent")
	assert_not_null(host.room.get_node_or_null(^"MistakePicture"), "the photo frozen on its way")
	assert_string_contains(host.hud.mistake_why.text, "can't take it back")
	assert_eq(host.run.total_hints(), 0, "never a miss")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	assert_false(host.frozen)
	assert_has(host.room.glowing(), "block", "the right way glows")
	await _tap("block")
	await wait_until(func() -> bool: return not _at("stranger"), LIMIT, "blocked")
	assert_false(_at("stranger"))
	assert_eq(host.run.total_hints(), 0, "the By myself stamp stays")


func test_flat_clicking_free_gold_freezes_time_then_close() -> void:
	await _open("online_city", "big")
	await _pick_up()
	_jump("gold")
	await wait_process_frames(2)
	await _tap("get_gold")
	assert_true(host.frozen, "the scam clicked: time freezes")
	assert_eq(host.room.mistake_shown, "scam_hook")
	assert_string_contains(host.hud.mistake_why.text, "scam")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	await _tap("close_x")
	await wait_until(func() -> bool: return not _at("gold"), LIMIT, "closed")
	assert_false(_at("gold"))


func test_vr_the_tablet_is_held_in_the_off_hand_and_the_other_hand_presses() -> void:
	await _vr_open("online_city", "middle")
	await _pick_up()
	_jump("game")
	await wait_process_frames(2)
	assert_true(_at("game"))
	var to_play := Vr.rig.global_transform.affine_inverse()
	var stand := host.stand.global_position
	var b := host.stand.global_basis
	Vr.sim_head(to_play * Transform3D(b, stand))
	var off: StringName = VrRules.LEFT if Vr.pointing_hand() == VrRules.RIGHT else VrRules.RIGHT
	var hand_at := stand + b * Vector3(-0.2, -0.4, -0.3)
	Vr.sim_hand(off, to_play * Transform3D(Basis(), hand_at))
	await wait_process_frames(3)
	var tablet := (host.room as OnlineRoom).tablet
	assert_lt(tablet.global_position.distance_to(hand_at), 0.25, "the tablet is in the off hand")
	assert_gt(tablet.global_basis.z.normalized().dot((stand - tablet.global_position).normalized()), 0.9, "its face to the eyes")
	# the holding hand squeezing at its own button presses nothing
	Vr.sim_hand(off, to_play * Transform3D(Basis(), hand_at))
	await wait_process_frames(1)
	Vr.sim_input(off, &"grip", 1.0)
	await wait_process_frames(4)
	Vr.sim_input(off, &"grip", 0.0)
	assert_true(_at("game"), "the hand holding the tablet never presses its own buttons")
	# the other hand at GAME PARK, squeezing: pressed
	var press_side: StringName = Vr.pointing_hand()
	Vr.sim_hand(press_side, to_play * Transform3D(Basis(), host.room.target_position("app_game")))
	Vr.sim_input(press_side, &"grip", 0.0)
	await wait_process_frames(2)
	Vr.sim_hand(press_side, to_play * Transform3D(Basis(), host.room.target_position("app_game")))
	Vr.sim_input(press_side, &"grip", 1.0)
	await wait_until(func() -> bool: return not _at("game"), LIMIT, "GAME PARK pressed")
	Vr.sim_input(press_side, &"grip", 0.0)
	assert_false(_at("game"), "the other hand presses the tablet's button")


# --- Find Your Way ------------------------------------------------------------------------------------------------------

func test_flat_stay_here_then_walking_off_freezes_time() -> void:
	await _open("find_way", "middle")
	_jump("lost")
	await wait_process_frames(1)
	_jump("stay")
	await wait_process_frames(2)
	assert_eq(str(host.hud.action_button.get_meta(&"words")), "STAY HERE", "the action's own words")
	host.hud.action_pressed.emit("still")
	await wait_until(func() -> bool: return not _at("stay"), LIMIT, "stayed")
	_jump("come_with")
	await wait_process_frames(2)
	var room := host.room as FindWayRoom
	var at := room.stranger.global_position
	await _tap("come_with")
	assert_true(host.frozen, "walking off with him: time freezes")
	assert_eq(host.room.mistake_shown, "walk_off")
	assert_string_contains(host.hud.mistake_why.text, "right where you are")
	assert_eq(room.stranger.global_position, at, "he stands where he stood")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	assert_has(host.room.glowing(), "worker", "the shop worker glows")
	await _tap("worker")
	await wait_until(func() -> bool: return not _at("come_with"), LIMIT, "asked the shop worker")
	assert_false(_at("come_with"))
	assert_eq(host.run.total_hints(), 0)


func test_little_never_shows_a_mistake_the_coach_says_the_rule_first() -> void:
	await _open("find_way", "little")
	_jump("never_go")
	await wait_process_frames(2)
	assert_string_contains(str(host.run.current().say), "Never go anywhere with anyone", "the rule first")
	assert_false(host.run.current().has("safe_mistake"))


func test_flat_the_platform_edge_while_the_train_comes_freezes_time() -> void:
	await _open("find_way", "big")
	_jump("platform")
	await wait_process_frames(2)
	assert_true(host.room.time_scale < 1.0, "a danger moment: the train comes in slowly on a first try")
	assert_true((host.room as FindWayRoom).train_moving, "the train is coming")
	await _tap("platform_edge")
	assert_true(host.frozen)
	assert_eq(host.room.mistake_shown, "edge_wind")
	var x := (host.room as FindWayRoom).train.position.x
	await wait_process_frames(5)
	assert_eq((host.room as FindWayRoom).train.position.x, x, "the train stands still")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	await _tap("behind_line")
	await wait_until(func() -> bool: return not _at("platform"), LIMIT + LifeRoomHost.DONE_PAUSE, "behind the line")
	assert_false(_at("platform"))


# --- Home Helper --------------------------------------------------------------------------------------------------------

func test_a_knife_pointing_up_is_a_kind_miss_never_a_freeze() -> void:
	await _open("home_helper", "big")
	_jump("knives")
	await wait_process_frames(2)
	await _tap("slot_up")
	assert_false(host.frozen, "chores have no safe mistakes")
	assert_eq(host.run.hints_on(host.run.index), 1, "a kind miss with its why")
	await _tap("slot_down")
	await wait_until(func() -> bool: return not _at("knives"), LIMIT, "point down")
	assert_false(_at("knives"))


func test_vr_the_watering_can_tilted_over_the_plant_waters_it() -> void:
	await _vr_open("home_helper", "little")
	_jump("plant")
	await wait_process_frames(2)
	var to_play := Vr.rig.global_transform.affine_inverse()
	var at := host.room.target_position("plant_a")
	Vr.sim_hand(VrRules.RIGHT, to_play * Transform3D(Basis(), at))   # upright: not pouring yet
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_seconds(0.5)
	assert_eq(float(host.run.state.get("level", 0.0)), 0.0, "held upright, nothing pours")
	Vr.sim_hand(VrRules.RIGHT, to_play * Transform3D(Basis(Vector3.FORWARD, deg_to_rad(70.0)), at))
	await wait_until(func() -> bool: return float(host.run.state.get("level", 0.0)) >= 0.45, 5.0, "pouring")
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	Vr.sim_hand(VrRules.RIGHT, to_play * Transform3D(Basis(), at + Vector3(0, 0.4, 0.3)))
	await wait_until(func() -> bool: return not _at("plant"), LIMIT, "damp: just right")
	assert_false(_at("plant"), "watered by tilting the can")


func test_vr_the_smoke_alarms_button_is_held_by_hand() -> void:
	await _vr_open("home_helper", "middle")
	_jump("smoke")
	await wait_process_frames(2)
	var to_play := Vr.rig.global_transform.affine_inverse()
	Vr.sim_hand(VrRules.RIGHT, to_play * Transform3D(Basis(), host.room.target_position("smoke_test")))
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_until(func() -> bool: return not _at("smoke"), 2.0 + LIMIT, "held until it beeps")
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	assert_false(_at("smoke"))
