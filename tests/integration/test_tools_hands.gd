extends GutTest
## Owner #117 (docs/design/life-skills.md §13): all ten motions through the whole chain, the way a room uses them. VR: a
## simulated headset (Vr.simulate), a tool from the Tool Book taken by a fake hand (VR-HANDS' grab), the hand moving the
## real way, the held ToolProp's tip and the trigger made into samples (ToolSample.vr) for ToolMotion. Flat: a camera
## and a finger's screen points (ToolSample.flat), the phone's gesture for each motion. Each is done well (it finishes)
## and badly (it never does).

const DT := 1.0 / 72.0
const WORK := Vector3(0.4, 1.0, -0.6)

var prop: ToolProp
var frame := Transform3D.IDENTITY


func before_each() -> void:
	frame = ToolSample.work_frame(WORK, Vector3.RIGHT, Vector3.UP)


func after_each() -> void:
	Vr.simulate(false)
	await wait_process_frames(1)


func _hand(world: Transform3D, side: StringName = VrRules.RIGHT) -> void:
	Vr.sim_hand(side, Vr.rig.global_transform.affine_inverse() * world)


## A headset, and the tool taken by the right hand.
func _take(tool: String) -> void:
	Vr.simulate(true)
	await wait_process_frames(2)
	prop = ToolProp.new(tool)
	add_child_autofree(prop)
	prop.global_position = WORK + Vector3(0, 0.3, 0.3)
	_hand(Transform3D(Basis(), prop.global_position))
	Vr.step(DT)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	Vr.step(DT)
	Vr.step(DT)
	assert_eq(Vr.grabber.held(VrRules.RIGHT), prop.grabbable, tool + " is in the hand")


## Moves the hand so the tool's working point (for `motion`) is at `local` in the work's frame, the hand turned `basis`.
func _tip_at(motion: String, local: Vector3, basis: Basis = Basis()) -> void:
	var tip_node: Node3D = prop.tips.get(motion, null)
	var offset := tip_node.position if tip_node != null else Vector3.ZERO
	_hand(Transform3D(basis, frame * local - basis * offset))
	Vr.step(DT)


func _sample(m: ToolMotion, other: Vector3 = Vector3.INF) -> Dictionary:
	return m.feed(ToolSample.vr(frame, prop.tip(m.motion), Vr.trigger(VrRules.RIGHT), DT, other))


## Runs a hand path: `at(t) -> [local, basis]` for `seconds`; true when the motion finished.
func _vr_run(m: ToolMotion, seconds: float, at: Callable, other: Vector3 = Vector3.INF) -> bool:
	for i in ceili(seconds / DT):
		var p: Array = at.call(i * DT)
		_tip_at(m.motion, p[0], p[1] if p.size() > 1 else Basis())
		_sample(m, other)
		if m.done:
			return true
	return m.done


func _motion(name: String, tool: String) -> ToolMotion:
	return ToolMotion.new(name, ToolBook.checks(tool, name))


func test_vr_strike_a_hammer_swung_onto_the_nail() -> void:
	await _take("hammer")
	var m := _motion("strike", "hammer")
	assert_true(_vr_run(m, 2.0, func(t: float) -> Array:
		var c := fmod(t, 0.4)
		return [Vector3(0, 0.12 - c * 2.0 if c < 0.08 else 0.15, 0)]), "three swings down onto it")
	var miss := _motion("strike", "hammer")
	assert_false(_vr_run(miss, 2.0, func(t: float) -> Array:
		var c := fmod(t, 0.4)
		return [Vector3(0.3, 0.12 - c * 2.0 if c < 0.08 else 0.15, 0)]), "swings beside it")


func test_vr_stroke_a_saw_along_the_line() -> void:
	await _take("saw")
	var m := _motion("stroke", "saw")
	assert_true(_vr_run(m, 6.0, func(t: float) -> Array:
		var u := fmod(t * 0.3, 0.4)
		return [Vector3((u if u < 0.2 else 0.4 - u) - 0.1, 0.0, 0)]))
	var off := _motion("stroke", "saw")
	assert_false(_vr_run(off, 6.0, func(t: float) -> Array:
		var u := fmod(t * 0.3, 0.4)
		return [Vector3((u if u < 0.2 else 0.4 - u) - 0.1, 0.0, 0.1)]), "far off the line")


func test_vr_twist_a_screwdriver_turned_in_line() -> void:
	await _take("screwdriver")
	var down := Basis.looking_at(Vector3.DOWN, Vector3.FORWARD)
	var m := _motion("twist", "screwdriver")
	assert_true(_vr_run(m, 4.0, func(t: float) -> Array:
		return [Vector3.ZERO, Basis(Vector3.UP, -t * 4.0) * down]), "two turns, clockwise from above")
	var wrong := _motion("twist", "screwdriver")
	assert_false(_vr_run(wrong, 4.0, func(t: float) -> Array:
		return [Vector3.ZERO, Basis(Vector3.UP, t * 4.0) * down]), "the other way")


func test_vr_squeeze_pliers_held_firmly() -> void:
	await _take("pliers")
	var m := _motion("squeeze", "pliers")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.8)
	assert_true(_vr_run(m, 2.0, func(_t: float) -> Array: return [Vector3(0, 0.02, 0)]))
	var light := _motion("squeeze", "pliers")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.3)
	assert_false(_vr_run(light, 2.0, func(_t: float) -> Array: return [Vector3(0, 0.02, 0)]), "too light")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)


func test_vr_press_a_bike_pump_pushed_all_the_way() -> void:
	await _take("bike_pump")
	var m := _motion("press", "bike_pump")
	assert_true(_vr_run(m, 8.0, func(t: float) -> Array:
		return [Vector3(0, 0.08 if fmod(t, 0.6) < 0.3 else -0.06, 0)]), "ten full pushes")
	var shallow := _motion("press", "bike_pump")
	assert_false(_vr_run(shallow, 8.0, func(t: float) -> Array:
		return [Vector3(0, 0.08 if fmod(t, 0.6) < 0.3 else -0.01, 0)]), "never all the way")


func test_vr_spread_a_trowel_low_along_the_bed() -> void:
	await _take("trowel")
	var m := ToolMotion.new("spread", {}, {"length": 0.9})
	assert_true(_vr_run(m, 3.0, func(t: float) -> Array: return [Vector3(t * 0.45, 0.005, 0)]))
	var high := ToolMotion.new("spread", {}, {"length": 0.9})
	assert_false(_vr_run(high, 3.0, func(t: float) -> Array: return [Vector3(t * 0.45, 0.06, 0)]), "lifted off it")


func test_vr_measure_a_tape_hooked_and_pulled() -> void:
	await _take("tape")
	var m := ToolMotion.new("measure", {}, {"length": 1.0})
	assert_true(_vr_run(m, 3.5, func(t: float) -> Array:
		return [Vector3(0.0 if t < 0.2 else minf((t - 0.2) * 0.6, 1.0), 0.0, 0)]))
	assert_almost_eq(m.reading, 1.0, 0.02)
	var loose := ToolMotion.new("measure", {}, {"length": 1.0})
	assert_false(_vr_run(loose, 3.5, func(t: float) -> Array:
		return [Vector3(0.4 + minf(t * 0.6, 0.6), 0.0, 0)]), "never hooked on the start")


func test_vr_pour_a_watering_can_tipped_over_the_pot() -> void:
	await _take("watering_can")
	var m := ToolMotion.new("pour", {}, {"want": 0.5})
	var tipped := Basis(Vector3.FORWARD, 1.3)
	assert_true(_vr_run(m, 2.0, func(t: float) -> Array:
		return [Vector3(0, 0.15, 0), tipped if t < 1.45 else Basis()]))
	var beside := ToolMotion.new("pour", {}, {"want": 0.5})
	assert_false(_vr_run(beside, 2.0, func(t: float) -> Array:
		return [Vector3(0.5, 0.15, 0), tipped if t < 1.45 else Basis()]), "beside the pot")


func test_vr_aim_a_spirit_level_held_true() -> void:
	await _take("spirit_level")
	var along := Basis.looking_at(Vector3.RIGHT, Vector3.UP)
	var m := _motion("aim", "spirit_level")
	assert_true(_vr_run(m, 1.6, func(_t: float) -> Array: return [Vector3(0, 0.005, 0), along]))
	var across := _motion("aim", "spirit_level")
	assert_false(_vr_run(across, 1.6, func(_t: float) -> Array:
		return [Vector3(0, 0.005, 0), Basis.looking_at(Vector3.FORWARD, Vector3.UP)]), "across the row")


func test_vr_cut_scissors_slowly_fingers_back() -> void:
	await _take("scissors")
	var m := ToolMotion.new("cut", {}, {"length": 0.2})
	assert_true(_vr_run(m, 2.0, func(t: float) -> Array: return [Vector3(minf(t * 0.15, 0.21), 0.0, 0)],
		frame * Vector3(-0.1, 0.0, 0.08)))
	var claw := ToolMotion.new("cut", {}, {"length": 0.2})
	assert_false(_vr_run(claw, 2.0, func(t: float) -> Array: return [Vector3(minf(t * 0.15, 0.21), 0.0, 0)],
		frame * Vector3(0.15, 0.0, 0.0)), "fingers ahead of the blade")


# --- Flat: a camera and a finger -----------------------------------------------------------------------------------

var _cam: Camera3D


func _camera() -> Camera3D:
	var view := SubViewport.new()
	view.size = Vector2i(1280, 720)
	add_child_autofree(view)
	_cam = Camera3D.new()
	_cam.fov = 72.0
	view.add_child(_cam)
	_cam.global_transform = Transform3D(Basis.looking_at(WORK - (WORK + Vector3(0, 0.9, 0.9)), Vector3.UP),
		WORK + Vector3(0, 0.9, 0.9))
	return _cam


## A finger at `local` (the work's frame) on the screen, down or not: one sample for `m`.
func _finger(m: ToolMotion, local: Vector3, down: bool) -> void:
	var px := _cam.unproject_position(frame * local)
	m.feed(ToolSample.flat(frame, _cam.project_ray_origin(px), _cam.project_ray_normal(px), down, DT, 0.02))


func _flat_run(m: ToolMotion, seconds: float, at: Callable) -> bool:
	for i in ceili(seconds / DT):
		var p: Array = at.call(i * DT)
		_finger(m, p[0], p[1])
		if m.done:
			return true
	return m.done


func test_flat_each_motion_by_its_phone_gesture() -> void:
	_camera()
	var gestures := {
		"strike": func(t: float) -> Array: return [Vector3.ZERO, fmod(t, 0.3) < 0.1],
		"stroke": func(t: float) -> Array:
			var u := fmod(t * 0.3, 0.4)
			return [Vector3((u if u < 0.2 else 0.4 - u) - 0.1, 0, 0), true],
		"twist": func(t: float) -> Array: return [Vector3(cos(t * 4.0), 0, sin(t * 4.0)) * 0.05, true],
		"squeeze": func(_t: float) -> Array: return [Vector3.ZERO, true],
		"press": func(t: float) -> Array: return [Vector3.ZERO, t > 0.1],
		"spread": func(t: float) -> Array: return [Vector3(minf(t * 0.45, 0.92), 0, 0), true],
		"measure": func(t: float) -> Array: return [Vector3(0.0 if t < 0.2 else minf((t - 0.2) * 0.6, 1.0), 0, 0), true],
		"pour": func(t: float) -> Array: return [Vector3.ZERO, t < 2.1],
		"aim": func(_t: float) -> Array: return [Vector3.ZERO, true],
		"cut": func(t: float) -> Array: return [Vector3(minf(t * 0.15, 0.31), 0, 0), true],
	}
	var numbers := {"spread": {"length": 0.9}, "measure": {"length": 1.0}, "pour": {"want": 0.5}}
	for name in ToolMotion.ALL:
		var m := ToolMotion.new(name, {}, numbers.get(name, {}))
		assert_true(_flat_run(m, 6.0, gestures[name]), name + " by its phone gesture")
	for name in ToolMotion.ALL:
		var away := ToolMotion.new(name, {}, numbers.get(name, {}))
		assert_false(_flat_run(away, 6.0, func(_t: float) -> Array: return [Vector3(0.5, 0, 0.5), false]),
			name + ": a finger that never touches does nothing")
