extends GutTest
## Owner #112, #113 (docs/design/life-skills.md §3, §4, §10): a try in its practice room. Flat: the room's camera shows
## the step, a finger on (or near) the glowing thing does it, the coach shows by a ghost finger (after 10 s, or SHOW ME),
## GET LOW lowers the view, I NEED A BREAK holds everything and STOP FOR NOW ends calmly; the screen it came from hides
## and comes back. VR (a simulated headset): the child stands at the view's spot, the hand on a thing squeezing presses
## it, the head low is "low", both hands push the chest and the controllers buzz on the pushes.

var host: LifeRoomHost
var parent: Node
var outcomes: Array = []
var stops: Array = []


func before_each() -> void:
	outcomes.clear()
	stops.clear()
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
	host.stopped.connect(func(o: Dictionary) -> void: stops.append(o))
	host.open(parent)
	await wait_process_frames(3)
	return host


func _skip_pause() -> void:
	host._pause = minf(host._pause, 0.01)


## The helpers wait for the state they need, never a count of frames (the lead's flake on a busy PC, 2026-10-16: a
## tap came before the run had left the step before). LIMIT seconds at most for each wait.
const LIMIT := 3.0


## Waits until the host has taken this frame's input (a press, OK, an answer): one of its frames has sampled it.
func _taken() -> void:
	await wait_process_frames(1)
	await wait_until(func() -> bool: return host.closed or (host._pressed.is_empty() and not host._ok and host._answer < 0),
		LIMIT, "the host took the input")


## When the step `before` is done, waits until the next one has started (its kind words' pause cut short).
func _next_started(before: int) -> void:
	if host.closed or host.run.index == before:
		return
	await wait_until(func() -> bool:
		_skip_pause()
		return host.closed or host.run.finished or host._pause <= 0.0, LIMIT, "the next step started")


## A tap on the glowing thing (its screen point), lifted once the host took it.
func _tap(target: String) -> void:
	var before := host.run.index
	host.finger_down(host.screen_of(target))
	await _taken()
	host.finger_up()
	await _next_started(before)


func _ok() -> void:
	var before := host.run.index
	host.hud.ok.emit()
	await _taken()
	await _next_started(before)


func _answer() -> void:
	var before := host.run.index
	host.hud.answered.emit(int(host.run.current().answer))
	await _taken()
	await _next_started(before)


func test_the_room_shows_the_first_step_and_its_camera() -> void:
	await _open("little_lifesaver", "little")
	assert_eq(str(host.run.current().id), "hello")
	assert_string_contains(host.hud.say_label.text, "Bobo")
	assert_eq(get_viewport().get_camera_3d(), host.camera)
	assert_true(host.room.global_position.distance_to(LifeRoomHost.ROOM_ORIGIN) < 0.01, "far above the world")


func test_a_tap_on_the_glowing_thing_does_the_step() -> void:
	await _open("little_lifesaver", "little")
	await _ok()
	await _answer()   # is it safe?
	assert_eq(str(host.run.current().id), "ask")
	assert_eq(host.room.glowing(), ["buddy_shoulder"] as Array[String], "the one next thing glows")
	await _tap("buddy_shoulder")
	assert_eq(str(host.run.current().id), "phone")


func test_a_finger_near_a_thing_still_reaches_it() -> void:
	await _open("little_lifesaver", "little")
	await _ok()
	await _answer()
	host.finger_down(host.screen_of("buddy_shoulder") + Vector2(30, 20))
	await _taken()
	host.finger_up()
	assert_ne(str(host.run.current().id), "ask")


func test_a_tap_on_something_else_waits_kindly() -> void:
	await _open("little_lifesaver", "little")
	await _ok()
	await _answer()
	await _tap("phone")
	assert_eq(str(host.run.current().id), "ask", "not yet the phone: nothing is lost")
	assert_eq(host.run.total_hints(), 0)


func test_the_coach_shows_after_ten_seconds_with_the_ghost_finger() -> void:
	await _open("little_lifesaver", "little")
	await _ok()
	await _answer()
	host.run.idle = LifeRun.COACH_AFTER - 0.001
	await wait_until(func() -> bool: return host.hud.ghost.showing(), LIMIT, "the coach")
	assert_true(host.hud.ghost.showing(), "the coach shows by doing")
	assert_eq(host.run.hints_on(host.run.index), 1)


func test_show_me_is_always_there() -> void:
	await _open("little_lifesaver", "little")
	await _ok()
	host.hud.show_me.emit()
	await wait_process_frames(1)
	assert_true(host.hud.ghost.showing())
	assert_eq(host.run.total_hints(), 1)


func test_a_wrong_picture_is_a_kind_miss_that_shows_again() -> void:
	await _open("little_lifesaver", "little")
	await _ok()
	var right := int(host.run.current().answer)
	host.hud.answered.emit((right + 1) % (host.run.current().choices as Array).size())
	await _taken()
	assert_eq(str(host.run.current().id), "safe", "the same step again")
	assert_true(host.hud.feedback.visible)
	assert_true(host.hud.ghost.showing(), "the ghost finger shows the right one")


func test_i_need_a_break_holds_everything() -> void:
	await _open("little_lifesaver", "little")
	await _ok()
	host.hud.open_break()
	assert_true(host.paused)
	host.run.idle = LifeRun.COACH_AFTER - 0.001
	await wait_process_frames(3)
	assert_eq(host.run.total_hints(), 0, "no coach while resting")
	host.hud.close_break()
	assert_false(host.paused)


func test_stop_for_now_ends_calmly_and_the_screen_comes_back() -> void:
	var layer := CanvasLayer.new()
	parent.add_child(layer)
	var screen := Control.new()
	layer.add_child(screen)
	host = LifeRoomHost.new()
	host.setup("fire_escape", "little", false, 1, "ge")
	host.stopped.connect(func(o: Dictionary) -> void: stops.append(o))
	var before := get_viewport().get_camera_3d()
	host.open(screen)
	await wait_process_frames(2)
	assert_false(layer.visible, "the screen it came from hides")
	host.hud.stop_for_now.emit()
	await wait_process_frames(2)
	assert_eq(stops.size(), 1)
	assert_true(layer.visible, "and comes back")
	assert_false(bool(stops[0].finished), "nothing is recorded as done; nothing is lost")
	assert_eq(get_viewport().get_camera_3d(), before)


func test_get_low_lowers_the_view() -> void:
	await _open("fire_escape", "middle")
	var y := host.camera.global_position.y
	host.hud.low_button.button_pressed = true
	await wait_seconds(LifeRoomHost.GLIDE + 0.2)
	assert_lt(host.camera.global_position.y, y - 0.4)
	assert_true(host.low_on)


func test_a_low_step_waits_until_the_child_is_low() -> void:
	await _open("fire_escape", "middle")
	await _ok()
	await _answer()
	assert_eq(str(host.run.current().id), "low")
	host.hud.low_button.button_pressed = true
	await wait_until(func() -> bool:
		_skip_pause()
		return str(host.run.current().id) == "check" and host._pause <= 0.0, LIMIT, "low long enough")
	assert_eq(str(host.run.current().id), "check")
	host.hud.low_button.button_pressed = false
	host.finger_down(host.screen_of("door_hall"))
	await wait_seconds(0.5)
	assert_eq(host.run.fraction(), 0.0, "standing up: the check waits, kindly")
	host.finger_up()


func test_little_lifesaver_little_played_through_flat() -> void:
	await _open("little_lifesaver", "little", false, "uk")
	var steps := host.run.steps
	var frames := 0
	while outcomes.is_empty() and frames < 400:
		frames += 1
		if host.closed:
			break
		if host.run.finished:   # the last step's kind words, then the end
			_skip_pause()
			await wait_process_frames(1)
			continue
		var step := host.run.current()
		match str(step.kind):
			"info":
				await _ok()
			"choose", "count":
				await _answer()
			"touch":
				await _tap(str(step.target))
			"sequence":
				await _tap(host.run.next_targets()[0])
			"hold":
				var before := host.run.index
				host.finger_down(host.screen_of(str(step.target)))
				await wait_until(func() -> bool: return host.run.index != before, float(step.get("seconds", 2.0)) + LIMIT,
					"held long enough")
				host.finger_up()
				await _next_started(before)
			_:
				await wait_process_frames(1)
	assert_eq(outcomes.size(), 1, "finished")
	if outcomes.is_empty():
		return
	var o: Dictionary = outcomes[0]
	assert_eq(int(o.stamps), LifeData.DONE | LifeData.SELF, "by myself")
	assert_gt((o.log as Array).size(), 8)
	assert_eq(steps.filter(func(s: Dictionary) -> bool: return str(s.kind) == "sequence")[0].targets,
		["key_9", "key_9", "key_9"], "the UK's 999")


# --- VR (a simulated headset) ---------------------------------------------------------------------------------------

func _vr_open(exp_id: String, track: String) -> void:
	Vr.simulate(true)
	await wait_process_frames(2)
	await _open(exp_id, track)
	await wait_physics_frames(2)
	await wait_process_frames(2)


## Puts a simulated hand at a world point (its aim pose in the play space).
func _hand_at(side: StringName, world: Vector3) -> void:
	Vr.sim_hand(side, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * world))


func test_vr_the_child_stands_at_the_views_spot() -> void:
	await _vr_open("little_lifesaver", "little")
	assert_true(host.vr)
	assert_eq(Vr.anchor_node(), host.stand)
	assert_true(host.hud.tap_area.mouse_filter == Control.MOUSE_FILTER_IGNORE, "no flat tap area in VR")


func test_vr_the_hand_on_a_thing_squeezing_presses_it() -> void:
	await _vr_open("little_lifesaver", "little")
	await _ok()
	await _answer()
	assert_eq(str(host.run.current().id), "ask")
	_hand_at(VrRules.RIGHT, host.room.target_position("buddy_shoulder"))
	await wait_process_frames(2)
	assert_eq(str(host.run.current().id), "ask", "a hand there, not squeezing: nothing yet")
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_until(func() -> bool: return str(host.run.current().id) != "ask", LIMIT, "the squeeze presses")
	assert_ne(str(host.run.current().id), "ask", "the hand is here and squeezing")
	assert_gt(Vr.haptics, 0, "a little buzz")
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)


## The phone's keys sit 9.5 cm apart: a squeezing hand presses only the key nearest to it, never its neighbours.
func test_vr_a_squeeze_presses_only_the_nearest_key() -> void:
	await _vr_open("little_lifesaver", "little")
	host.room.step_done({"id": "phone", "kind": "touch", "target": "phone"})
	host.set_process(false)   # this test reads the samples itself
	_hand_at(VrRules.RIGHT, host.room.target_position("key_1") + Vector3(0.01, 0, 0))
	var dial := {"kind": "sequence", "targets": ["key_1", "key_1", "key_2"], "say": "Dial."}
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	host._vr_sample(dial, 0.05)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	var sample := host._vr_sample(dial, 0.05)
	assert_eq(sample.pressed, ["key_1"], "key_2 and key_4 are touched too, but key_1 is nearest")
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)


func test_vr_the_head_low_is_low() -> void:
	await _vr_open("fire_escape", "middle")
	var sample := host._vr_sample({"kind": "action", "action": "low", "say": "x"}, 0.1)
	assert_false(bool(sample.low))
	var head := Vr.head_transform()
	var play := Vr.rig.global_transform.affine_inverse() * head
	play.origin.y -= 0.45
	Vr.sim_head(play)
	await wait_process_frames(2)
	sample = host._vr_sample({"kind": "action", "action": "low", "say": "x"}, 0.1)
	assert_true(bool(sample.low), "really getting low under the smoke")


func test_vr_both_hands_push_the_chest_and_buzz() -> void:
	await _vr_open("little_lifesaver", "big")
	var chest := host.room.target_position("chest")
	var step := {"kind": "rhythm", "target": "chest", "pushes": 30, "good": 20, "say": "Push."}
	var buzz := Vr.haptics
	var pushes := 0
	for i in 4:
		for dy: float in [0.0, -0.025, -0.05, -0.025, 0.0]:
			_hand_at(VrRules.LEFT, chest + Vector3(0, dy, 0))
			_hand_at(VrRules.RIGHT, chest + Vector3(0, dy + 0.02, 0))
			await wait_process_frames(1)
			pushes += int(host._vr_sample(step, 0.05).get("pushes", 0))
			host._pushes = 0
	assert_eq(pushes, 4, "down and up four times: four pushes")
	assert_gt(Vr.haptics, buzz, "the controllers buzz on the pushes")


func test_vr_closing_gives_the_anchor_back() -> void:
	var before := Node3D.new()
	add_child_autofree(before)
	Vr.simulate(true)
	await wait_process_frames(2)
	Vr.anchor(before, &"menu")
	await _open("money_stall", "little")
	assert_eq(Vr.anchor_node(), host.stand)
	host.hud.stop_for_now.emit()
	await wait_process_frames(2)
	assert_eq(Vr.anchor_node(), before, "back where the child was")
