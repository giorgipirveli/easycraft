extends GutTest
## Owner #116, #117, #118: Real Builder played through the real ToolRoomHost (Life's room host with the tool engine).
## Flat: the tray's tool and a finger: a tap alone never spreads mortar (the motion is needed), the wrong tool is noticed
## kindly, a tap lays the brick nearest the finger; the mixer's order and its safety steps; the saw without goggles is a
## safe mistake (the coach's why and the sawdust, never a miss). VR (fake hands, Vr.simulate): a tool taken from the
## bench and used with its real motion on the work, a brick carried to its place, a push with the hand. Whole runs, flat
## and in VR: every track finishes by itself with no hint, the walls in bond, the tools' stamps come out.

const Driver := preload("res://tools/real_builder_driver.gd")
const DT := 1.0 / 30.0

var host: ToolRoomHost
var parent: Node
var used: Array = []
var _motion_was := false


func before_each() -> void:
	used.clear()
	parent = Node.new()
	add_child_autofree(parent)
	_motion_was = Profile.data.settings.get("reduce_motion", false)
	Profile.data.settings.reduce_motion = true   # the camera moves at once (the tests tick by themselves)


func after_each() -> void:
	if is_instance_valid(host) and not host.closed:
		host.close()
	Vr.simulate(false)
	Profile.data.settings.reduce_motion = _motion_was
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(track: String, expert: bool = false) -> ToolRoomHost:
	host = ToolRoomHost.new()
	host.setup(RealBuilder.ID, track, expert, 1, "ge")
	host.tools_used.connect(func(e: Array, _x: bool) -> void: used.append_array(e))
	host.open(parent)
	host.set_process(false)   # the tests tick it themselves
	return host


func _tick(n: int = 1) -> void:
	for i in n:
		if Vr.active():
			Vr.step_physics()
			Vr.step(DT)
		host._process(DT)
		if is_instance_valid(host.room):
			host.room._process(DT)


## Plays steps the right way until the run reaches `step_id`.
func _until(step_id: String, in_vr: bool = false) -> Driver:
	var d := Driver.new(host, in_vr)
	var guard := 0
	while not host.run.finished and str(host.run.current().get("id", "")) != step_id and guard < 20000:
		d.tick()
		guard += 1
	while host._pause > 0.0:
		_tick()
	return d


func _finger(kind: String, at: Vector3) -> void:
	host.hud.finger.emit(kind, host.camera.unproject_position(at))


## Life L1's Experiences play through this host exactly as through Life's own: their rooms give no work frames and run
## no devices, so no step is taken over (the engine opts in by the room).
func test_life_l1s_experiences_are_untouched() -> void:
	for exp_id in LifeExperience.IDS:
		if exp_id == RealBuilder.ID:
			continue   # the engine's own Experience (the lead wired it into Life: owner #116)
		for track in LifeData.TRACKS:
			_open_any(exp_id, track)
			for step in host.run.steps:
				host._begin(step)
				assert_null(host.motion, "%s.%s %s" % [exp_id, track, step.id])
				assert_null(host.device, "%s.%s %s" % [exp_id, track, step.id])
			host.close()


func _open_any(exp_id: String, track: String) -> void:
	host = ToolRoomHost.new()
	host.setup(exp_id, track, false, 1, "ge")
	host.open(parent)
	host.set_process(false)


func test_it_opens_on_its_own_site_with_its_own_steps() -> void:
	_open("little")
	assert_true(host.room is RealBuilderSite, "Real Builder's site, before Life's catalogue knows it")
	assert_eq(host.run.steps.size(), RealBuilder.steps("little", false, 1, "ge").size())
	assert_eq(str(host.run.current().id), "hello")
	assert_true(host.room.global_position.distance_to(LifeRoomHost.ROOM_ORIGIN) < 0.01)


func test_a_tap_alone_never_spreads_the_mortar() -> void:
	_open("little")
	_until("mortar_1")
	host.tray.select("trowel")
	var bed := host.room.target_position("bed_1")
	for i in 20:
		_finger("down", bed)
		_tick()
		_finger("up", bed)
		_tick()
	assert_eq(str(host.run.current().id), "mortar_1", "the trowel must sweep along the bed")
	var frame: Transform3D = host.room.call(&"work_frame", "bed_1")
	_finger("down", frame * Vector3(0.0, 0, 0))
	for i in 110:
		_finger("move", frame * Vector3(minf(i * 0.015, 1.36), 0, 0))
		_tick()
	_finger("up", frame * Vector3(1.36, 0, 0))
	_tick(2)
	assert_ne(str(host.run.current().id), "mortar_1", "a sweep along it spreads it")


func test_the_wrong_tool_is_noticed_kindly_and_the_right_one_glows() -> void:
	_open("little")
	_until("mortar_1")
	host.tray.select("spirit_level")
	_finger("down", host.room.target_position("bed_1"))
	_tick(2)
	assert_string_starts_with(host.hud.feedback.text, "That works better with the trowel")
	assert_eq(host.tray.glowing, "trowel")
	assert_eq(host.run.total_hints(), 0, "kind words, never a miss")


func test_a_tap_lays_the_brick_nearest_the_finger() -> void:
	_open("little")
	_until("row_1")
	var site := host.room as RealBuilderSite
	var right: Dictionary = site.free_pieces("course_1")[2]
	_finger("down", site.to_global(right.centre as Vector3))
	_tick()
	_finger("up", site.to_global(right.centre as Vector3))
	_tick()
	assert_true(site.laid.has(str(right.id)), "the one under the finger")
	assert_eq(int(host.run.state.get("t", 0)), 1)


func test_the_mixer_goes_in_order_and_safety_first() -> void:
	_open("middle")
	_until("mix")
	assert_not_null(host.device)
	assert_eq(host.device.next_do(), "switch", "gloves and goggles are on already: their steps are done")
	_finger("down", host.room.target_position("mixer_cement"))
	_tick()
	_finger("up", host.room.target_position("mixer_cement"))
	_tick()
	assert_eq(host.hud.feedback.text, ToolDevice.FIRST % "switch it on")
	assert_eq(host.device.index, 2, "nothing skipped")
	var site := host.room as RealBuilderSite
	for c: String in ["switch", "water", "sand", "cement", "water", "switch"]:
		_finger("down", host.room.target_position("mixer_" + c))
		_tick()
		_finger("up", host.room.target_position("mixer_" + c))
		_tick()
		if c == "sand":
			assert_true(site.drum_turning, "the drum turns while it mixes")
	assert_true(host.device.finished)
	_tick(2)
	assert_ne(str(host.run.current().id), "mix")


func test_the_saw_without_goggles_is_a_safe_mistake() -> void:
	_open("middle")
	_until("saw")
	assert_false(host.worn.has("goggles"), "off since the mixer")
	var hints := host.run.total_hints()
	host.tray.select("saw")
	var frame: Transform3D = host.room.call(&"work_frame", "rafter_cut")
	_finger("down", frame * Vector3(-0.1, 0, 0))
	for i in 30:
		_finger("move", frame * Vector3(-0.1 + 0.2 * absf(sin(i * 0.2)), 0, 0))
		_tick()
	_finger("up", frame.origin)
	_tick()
	# Life L3b (owner #118): a true safe mistake now: time freezes, the sawdust's still picture, the coach's card
	assert_true(host.frozen, "the saw without goggles freezes time")
	assert_true(host.room.frozen)
	assert_eq(host.room.mistake_shown, "sawdust")
	assert_not_null(host.room.get_node_or_null(^"MistakePicture"), "a still puff of sawdust at the work")
	assert_string_contains(host.hud.mistake_why.text, "Sawdust and chips fly up towards your eyes")
	assert_eq(host.run.total_hints(), hints, "a safe mistake is never a miss")
	assert_eq(host.run.total_mistakes(), 1, "counted once (a held saw tries it only once)")
	assert_almost_eq(host.motion.fraction(), 0.0, 0.001, "no sawing without the goggles")
	host.hud.mistake_ok.emit()
	_tick()
	assert_false(host.frozen, "GOT IT")
	assert_null(host.room.get_node_or_null(^"MistakePicture"), "the picture goes")
	_finger("down", frame * Vector3(-0.1, 0, 0))
	for i in 10:
		_finger("move", frame * Vector3(-0.1 + 0.2 * absf(sin(i * 0.2)), 0, 0))
		_tick()
	_finger("up", frame.origin)
	_tick()
	assert_false(host.frozen, "once explained, another try shows the gear (the old shaped way)")
	assert_has(host.room.glowing(), "goggles")
	_finger("down", host.room.target_position("goggles"))
	_tick()
	_finger("up", host.room.target_position("goggles"))
	_tick()
	assert_true(host.worn.has("goggles"))


func test_little_flat_played_through_with_no_hint() -> void:
	_open("little")
	var d := Driver.new(host, false)
	assert_true(d.play(), "finished; stuck at " + str(host.run.current().get("id", "")))
	assert_eq(int(host.outcome.stamps), LifeData.DONE | LifeData.SELF, "by myself")
	var site := host.room as RealBuilderSite
	assert_eq(BrickBond.straight_joints(site.visible_pieces()), [], "the wall in bond")
	var tools := {}
	for e: Dictionary in used:
		tools[e.tool] = true
	for t: String in ["hard_hat", "gloves", "trowel", "spirit_level"]:
		assert_true(tools.has(t), "the Tool Book hears of the " + t)


func test_middle_and_big_flat_played_through() -> void:
	for track: String in ["middle", "big"]:
		used.clear()
		_open(track)
		var d := Driver.new(host, false)
		assert_true(d.play(), "%s finished; stuck at %s" % [track, host.run.current().get("id", "")])
		assert_eq(int(host.outcome.get("hints", -1)), 0, track)
		await wait_process_frames(2)


func test_the_expert_try_too() -> void:
	_open("middle", true)
	var d := Driver.new(host, false)
	assert_true(d.play(), "stuck at " + str(host.run.current().get("id", "")))
	assert_eq(int(host.outcome.stamps), LifeData.DONE | LifeData.SELF | LifeData.EXPERT)


# --- VR (fake hands) ----------------------------------------------------------------------------------------------

func _vr_open(track: String) -> void:
	Vr.simulate(true)
	await wait_process_frames(2)
	_open(track)
	_tick(3)


func _hand(world: Transform3D, side: StringName = VrRules.RIGHT) -> void:
	Vr.sim_hand(side, Vr.rig.global_transform.affine_inverse() * world)


func test_vr_the_tray_hides_and_the_tools_are_on_the_bench() -> void:
	await _vr_open("little")
	assert_true(host.vr)
	assert_false(host.tray.visible)
	assert_true((host.room as RealBuilderSite).props().has("trowel"))


func test_vr_a_tool_taken_and_used_with_its_real_motion() -> void:
	await _vr_open("little")
	_until("tap_down", true)
	var site := host.room as RealBuilderSite
	var trowel: ToolProp = site.props().trowel
	_hand(Transform3D(Basis(), trowel.global_position))
	_tick()
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_tick(2)
	assert_eq(host._held_prop(VrRules.RIGHT), trowel, "taken with the grip")
	var frame: Transform3D = site.work_frame("block_high")
	var tip: Node3D = trowel.tips.strike
	var buzz := Vr.haptics
	for swing in 3:
		for y: float in [0.14, 0.08, 0.02, -0.04, 0.16, 0.16]:
			_hand(Transform3D(Basis(), frame * Vector3(0, y, 0) - tip.position))
			_tick()
	_tick(2)
	assert_ne(str(host.run.current().id), "tap_down", "two good taps with the trowel")
	assert_gt(Vr.haptics, buzz, "a soft buzz on each good tap")


func test_vr_a_brick_is_carried_to_its_place() -> void:
	await _vr_open("little")
	_until("row_1", true)
	var site := host.room as RealBuilderSite
	var place: Dictionary = site.free_pieces("course_1")[0]
	Vr.sim_input(VrRules.LEFT, &"grip", 0.0)
	_hand(Transform3D(Basis(), site._hand.global_position), VrRules.LEFT)
	_tick()
	Vr.sim_input(VrRules.LEFT, &"grip", 1.0)
	_tick(2)
	_hand(Transform3D(Basis(), site.to_global(place.centre as Vector3)), VrRules.LEFT)
	_tick(2)
	assert_true(site._ghost.visible, "its place shows under the hand")
	Vr.sim_input(VrRules.LEFT, &"grip", 0.0)
	_tick(2)
	assert_true(site.laid.has(str(place.id)), "let go at its place: laid there")
	assert_eq(int(host.run.state.get("t", 0)), 1)


func test_vr_a_squeeze_at_the_row_lays_nothing() -> void:
	await _vr_open("little")
	_until("row_1", true)
	_hand(Transform3D(Basis(), host.room.target_position("course_1")))
	for i in 6:
		Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0 if i % 2 == 0 else 0.0)
		_tick()
	assert_eq(int(host.run.state.get("t", 0)), 0, "bricks are carried and laid, never squeezed into place")


func test_little_and_middle_in_vr_played_through() -> void:
	for track: String in ["little", "middle"]:
		used.clear()
		await _vr_open(track)
		var d := Driver.new(host, true)
		assert_true(d.play(), "%s finished in VR; stuck at %s" % [track, host.run.current().get("id", "")])
		assert_eq(int(host.outcome.get("hints", -1)), 0, track)
		Vr.simulate(false)
		await wait_process_frames(2)
