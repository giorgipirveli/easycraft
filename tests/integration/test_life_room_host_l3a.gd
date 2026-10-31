extends GutTest
## Owner #118 (docs/design/life-skills.md §14; Life L3a): the framework additions in the room host, flat and in a
## simulated headset. A safe mistake (the wrong thing pressed, the STAND UP picture, the head coming up on the ice)
## freezes the room: its own time and tweens stop, the scene softens (flat: a soft veil over the screen; VR: the view
## dims a little, under the panel), the room shows its gentle picture of what would happen, and the coach's card says
## the calm why and the right way. GOT IT goes on: the picture goes, the room moves again, the right thing glows and the
## coach shows it, and no hint was counted (on the Expert try, one is). A danger step's room time is slow on the first
## tries and real on the Expert try (a marker says "slow practice"); `glow: false` hides the glow but the coach still
## shows; an action's big button and a basket's words come from the step.

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


func _open(exp_id: String, track: String, expert: bool = false, intensity: String = LifeData.GENTLE,
		tries: int = 0) -> LifeRoomHost:
	host = LifeRoomHost.new()
	host.setup(exp_id, track, expert, 1, "ge", intensity, tries)
	host.finished.connect(func(o: Dictionary) -> void: outcomes.append(o))
	host.open(parent)
	await wait_process_frames(3)
	return host


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


# --- The freeze ------------------------------------------------------------------------------------------------------

func test_flat_a_safe_mistake_freezes_the_room_and_the_coach_says_why() -> void:
	await _open("water_safety", "middle")
	_jump("reach")
	await wait_process_frames(2)
	await _tap("jump_in")
	assert_true(host.frozen, "time froze")
	assert_true(host.room.frozen)
	assert_eq(host.room.process_mode, Node.PROCESS_MODE_DISABLED, "the room's own time and tweens stopped")
	assert_eq(host.room.mistake_shown, "two_in_water", "the gentle picture of what would happen")
	assert_not_null(host.room.get_node_or_null(^"MistakePicture"))
	assert_true(host.hud.mistake_card.visible, "the coach's card")
	assert_string_contains(host.hud.mistake_why.text, "grabs anything")
	assert_string_contains(host.hud.mistake_right.text, "reach with the pole")
	assert_true(host.hud.veil.visible, "the scene softens (flat: a soft veil)")
	assert_eq(host.room.glowing(), [] as Array[String], "everything stills")
	assert_eq(host.run.total_hints(), 0, "never a miss")
	assert_eq(host.run.total_mistakes(), 1)
	await _tap("reach_pole")
	assert_true(_at("reach"), "nothing moves on while frozen")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	assert_false(host.frozen, "GOT IT: the step goes on")
	assert_eq(host.room.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(host.room.mistake_shown, "")
	assert_null(host.room.get_node_or_null(^"MistakePicture"), "the picture is gone")
	assert_false(host.hud.mistake_card.visible)
	assert_has(host.room.glowing(), "reach_pole", "the right way glows")
	assert_string_contains(host.hud.feedback.text, "reach with the pole", "and the coach says it")
	await _tap("reach_pole")
	await wait_until(func() -> bool: return not _at("reach"), LIMIT, "done the right way")
	assert_false(_at("reach"), "done the right way")
	assert_eq(host.run.total_hints(), 0, "the By myself stamp stays")


func test_the_room_starts_moving_again_after_the_freeze() -> void:
	await _open("water_safety", "middle")
	_jump("rip")
	await wait_process_frames(2)
	var room := host.room as WaterRoom
	room.on_event("rip_on")
	await wait_process_frames(3)
	await _tap("swim_back")
	assert_true(host.frozen)
	assert_eq(room.mistake_shown, "rip_tired")
	var frozen_z := room.arrows[0].position.z
	await wait_process_frames(5)
	assert_eq(room.arrows[0].position.z, frozen_z, "the rip's arrows are still while frozen")
	host.hud.mistake_ok.emit()
	await wait_process_frames(8)
	assert_ne(room.arrows[0].position.z, frozen_z, "and drift again after")


func test_flat_standing_up_on_the_ice_is_the_stand_up_picture() -> void:
	await _open("water_safety", "big")
	_jump("roll")
	host.set_low(true)
	await wait_process_frames(2)
	assert_not_null(host.hud.mistake_action, "a STAND UP picture beside ROLL (the wrong way, to try)")
	assert_true(host.hud.mistake_action.visible)
	host.hud.action_pressed.emit("stand")
	await _taken()
	assert_true(host.frozen)
	assert_eq(host.room.mistake_shown, "ice_cracks")
	host.hud.mistake_ok.emit()
	await wait_process_frames(2)
	host.hud.action_pressed.emit("roll")
	await wait_until(func() -> bool: return not _at("roll"), LIMIT, "rolled")
	assert_false(_at("roll"))


func test_vr_the_head_coming_up_on_the_ice_freezes_and_the_view_dims() -> void:
	Vr.simulate(true)
	await _open("water_safety", "big")
	_jump("roll")
	await wait_process_frames(2)
	var stand := host.stand.global_position
	var to_play := Vr.rig.global_transform.affine_inverse()
	Vr.sim_head(to_play * Transform3D(host.stand.global_basis, stand + Vector3(0, -0.45, 0)))
	await wait_process_frames(4)
	assert_false(host.frozen, "low on the ice")
	Vr.sim_head(to_play * Transform3D(host.stand.global_basis, stand))
	await wait_until(func() -> bool: return host.frozen, LIMIT, "standing up")
	assert_true(host.frozen, "the head came up: standing on the ice")
	await wait_seconds(LifeRoomHost.FREEZE_FADE + 0.2)
	assert_gt(Vr.fade_amount(), 0.1, "the view dims a little (never black)")
	assert_lt(Vr.fade_amount(), 0.6)
	assert_true(host.hud.mistake_card.visible, "the card on the panel")
	host.hud.mistake_ok.emit()
	await wait_seconds(LifeRoomHost.FREEZE_FADE + 0.2)
	assert_lt(Vr.fade_amount(), 0.01, "clear again")


func test_on_the_expert_try_a_safe_mistake_counts_as_a_hint() -> void:
	await _open("earth_weather", "middle", true)
	_jump("cover")
	host.set_low(true)
	await wait_process_frames(2)
	await _tap("door_out")
	assert_true(host.frozen)
	assert_eq(host.run.total_hints(), 1, "the Expert stamp waits for a try without the wrong way")


func test_closing_while_frozen_leaves_nothing_dimmed() -> void:
	Vr.simulate(true)
	await _open("poisons_cupboard", "middle")
	_jump("mix")
	await wait_process_frames(2)
	host._pressed.append("mix_bucket")
	await wait_until(func() -> bool: return host.frozen, LIMIT, "mixing tried")
	assert_true(host.frozen)
	host.stop_for_now()
	await wait_seconds(0.3)
	assert_lt(Vr.fade_amount(), 0.01, "the way out at any moment, and the view is clear")


## The smoke found it (2026-10-17): in VR a hand on Bobo's buckle also touched the jacket's own bigger target, which won
## as the nearest, so the buckle never clicked. Once the jacket is on, its target goes.
func test_vr_a_hand_on_the_buckle_clicks_the_buckle() -> void:
	Vr.simulate(true)
	await _open("water_safety", "little")
	_jump("jacket")
	await wait_process_frames(2)
	var to_play := Vr.rig.global_transform.affine_inverse()
	var squeeze := func(target: String) -> void:
		Vr.sim_hand(VrRules.RIGHT, to_play * Transform3D(Basis(), host.room.target_position(target)))
		Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	squeeze.call("jacket_on")
	await wait_process_frames(2)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_until(func() -> bool: return _at("buckle") and host._pause <= 0.0, LIMIT + LifeRoomHost.DONE_PAUSE,
		"the jacket is on and the buckle's step began")
	assert_true(_at("buckle"))
	squeeze.call("jacket_buckle")
	await wait_process_frames(3)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_until(func() -> bool: return not _at("buckle"), LIMIT, "the buckle clicked")
	assert_false(_at("buckle"), "the buckle clicked")


# --- Time, glow and words --------------------------------------------------------------------------------------------

func test_a_danger_step_is_slow_on_the_first_tries_and_real_on_the_expert_try() -> void:
	await _open("earth_weather", "middle", false, LifeData.GENTLE, 0)
	_jump("drop")
	await wait_process_frames(2)
	assert_almost_eq(host.room.time_scale, LifeRun.SLOW_FIRST, 0.001, "the shaking at half speed on the first try")
	assert_true(host.hud.slow_mark.visible, "the HUD says it is slow practice")
	_jump("flood")
	await wait_process_frames(2)
	assert_almost_eq(host.room.time_scale, 1.0, 0.001, "not a danger moment: real time")
	assert_false(host.hud.slow_mark.visible)
	host.close()
	await _open("earth_weather", "middle", false, LifeData.GENTLE, 3)
	_jump("drop")
	await wait_process_frames(2)
	assert_almost_eq(host.room.time_scale, LifeRun.SLOW_LATER, 0.001, "later tries: a little slow")
	host.close()
	await _open("earth_weather", "middle", true)
	_jump("drop")
	await wait_process_frames(2)
	assert_almost_eq(host.room.time_scale, 1.0, 0.001, "the Expert try: real time")
	host.close()
	await _open("earth_weather", "big", false, LifeData.REAL)
	_jump("drop")
	await wait_process_frames(2)
	assert_almost_eq(host.room.time_scale, 1.0, 0.001, "a grown-up's 'more real' (Big): real time")
	assert_true(host.room.more_real(), "and the room knows it")


func test_the_drop_wanted_in_time_counts_the_rooms_slow_time() -> void:
	await _open("earth_weather", "middle", false, LifeData.GENTLE, 0)
	_jump("drop")
	var within := float(host.run.current().within)
	await wait_seconds(within + 0.3)
	assert_eq(host.run.hints_on(host.run.index), 0, "at half speed the child has twice as long")


func test_glow_false_hides_the_glow_but_the_coach_still_shows() -> void:
	await _open("earth_weather", "little", true)
	_jump("cover")
	host.set_low(true)
	await wait_process_frames(2)
	assert_eq(host.room.glowing(), [] as Array[String], "the Expert try: nothing glows")
	host.show_me()
	await wait_process_frames(1)
	assert_true(host.hud.ghost.visible, "SHOW ME still shows the way")


func test_an_actions_big_button_and_a_baskets_words_come_from_the_step() -> void:
	await _open("water_safety", "big")
	_jump("still")
	await wait_process_frames(2)
	assert_eq(str(host.hud.action_button.get_meta(&"words")), "KEEP STILL")
	host.close()
	await _open("earth_weather", "big")
	_jump("bag")
	await wait_process_frames(2)
	assert_string_contains(host.hud.sum_label.text, "spaces")
	assert_eq(host.hud.pay_button.text, "ZIP IT UP")
