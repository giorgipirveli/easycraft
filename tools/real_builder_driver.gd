extends RefCounted
## Owner #116, #117: plays Real Builder through the real ToolRoomHost like a child who does every step the right way,
## frame by frame on a fixed clock (no waiting for real frames): flat with a finger on the screen (the tray's tool, taps,
## drags) or in a simulated headset with fake hands (Vr.simulate: taking tools from the bench, the real motions with their
## tips on the work, bricks carried to their places). For the tests (tests/integration/test_real_builder_host.gd) and
## the headless smoke (tools/real_builder_smoke.gd). Each ToolMotion is done well, so a run ends with no hint at all.

const DT := 1.0 / 30.0

var host: ToolRoomHost
var vr := false
var ticks := 0
## Per step: its ticks so far, the phase of its motion.
var _step_ticks := 0
var _seen := -1
var _phase := 0
var _held: Node3D = null
var _grip_on := false
var log: Array[String] = []


func _init(room_host: ToolRoomHost, in_vr: bool) -> void:
	host = room_host
	vr = in_vr


## Plays until the run is finished (or `limit` frames): true when it finished.
func play(limit: int = 30000) -> bool:
	while not host.closed and ticks < limit:
		tick()
	return host.closed and not host.outcome.is_empty() and bool(host.outcome.get("finished", false))


func tick() -> void:
	ticks += 1
	if host.run.index != _seen:
		_seen = host.run.index
		_step_ticks = 0
		_phase = 0
		if not host.run.finished:
			log.append(str(host.run.current().get("id", "")))
	if host._pause <= 0.0 and not host.run.finished:
		_step_ticks += 1   # the step's own frames: from when it shows (after the last one's pause)
		_act(host.run.current())
	if vr:
		Vr.step_physics()
		Vr.step(DT)
	host._process(DT)
	if is_instance_valid(host.room):
		host.room._process(DT)


# --- What a child does on each kind of step -----------------------------------------------------------------------

func _act(step: Dictionary) -> void:
	var kind := str(step.get("kind", ""))
	var target := str(step.get("target", ""))
	var site := host.room as RealBuilderSite
	match kind:
		"info":
			if _step_ticks == 2:
				host.hud.ok.emit()
		"choose", "count":
			if _step_ticks == 2:
				host.hud.answered.emit(int(step.get("answer", 0)))
		"find", "go":
			var next := host.run.next_targets()
			if not next.is_empty():
				_press_at(host.room.target_position(next[0]))
		"timelapse":
			pass
		"taps":
			if site.is_placement(target) and vr and (target.begins_with("course") or target.begins_with("lintel_")):
				_carry(site, target)
			elif site.is_placement(target) and site.mine.has(target) and not site.free_pieces(target).is_empty():
				_press_at(site.to_global(site.free_pieces(target)[0].centre as Vector3))
			else:
				_press_at(host.room.target_position(target))
		"touch":
			if str(step.get("device", "")) != "":
				var n := host._device_next_target()
				if n != "":
					_press_at(host.room.target_position(n))
			elif host.motion != null:
				_use_tool(step)
			elif site.is_placement(target) and vr:
				_carry(site, target)
			else:
				_press_at(host.room.target_position(target))


## A tap (flat) or a squeeze of the hand on it (VR), every few frames.
func _press_at(at: Vector3) -> void:
	var beat := _step_ticks % 6
	if vr:
		_hand(VrRules.LEFT, Transform3D(Basis(), at))   # the free hand: the right one holds the tools
		Vr.sim_input(VrRules.LEFT, &"trigger", 1.0 if beat == 2 else 0.0)
		return
	if beat == 1:
		host.hud.finger.emit("down", host.camera.unproject_position(at))
	elif beat == 2:
		host.hud.finger.emit("up", host.camera.unproject_position(at))


## VR: take the pallet's brick (or lintel), carry it to its free place, let go.
func _carry(site: RealBuilderSite, target: String) -> void:
	var piece := site._hand
	var place := Vector3.INF
	if target.begins_with("lintel_"):
		var l: Dictionary = site._pieces.get(site._lintel_of(target), {})
		place = site.to_global(l.centre as Vector3) if not l.is_empty() else Vector3.INF
	elif not site.free_pieces(target).is_empty():
		place = site.to_global(site.free_pieces(target)[0].centre as Vector3)
	if not place.is_finite():
		return
	match _phase:   # with the free hand (the left): the right keeps its tool
		0:
			_hand(VrRules.LEFT, Transform3D(Basis(), piece.global_position))
			Vr.sim_input(VrRules.LEFT, &"grip", 0.0)
			_phase = 1
		1:
			Vr.sim_input(VrRules.LEFT, &"grip", 1.0)
			_phase = 2
		2:
			_hand(VrRules.LEFT, Transform3D(Basis(), place + Vector3(0, 0.01, 0)))
			_phase = 3
		3:
			Vr.sim_input(VrRules.LEFT, &"grip", 0.0)
			_phase = 0


## A tool step: the gear first if it wants it, the tool picked up, then its motion done well on the work.
func _use_tool(step: Dictionary) -> void:
	var tool := str(step.get("tool", ""))
	var gear := str(step.get("safety", ""))
	if gear != "" and not host.worn.has(gear):
		_press_at(host.room.target_position(gear))
		return
	if tool != "" and not _holding(tool):
		_pick_up(tool)
		return
	var frame := Transform3D(host.room.call(&"work_frame", str(step.target)))
	var t := (_step_ticks - _phase) * DT
	var path := _path(host.motion, t)
	if path.is_empty():
		return
	var p: Vector3 = path.at
	var down: bool = path.down
	if vr:
		var basis := Basis()
		if host.motion.motion == ToolMotion.AIM and float(host.motion.checks.tol) < 3.0:
			basis = Basis.looking_at(frame.basis * _vec(host.motion.checks.dir), frame.basis.y)
		var tip_world := frame * p
		var tip_local := Transform3D.IDENTITY
		if tool != "" and _held is ToolProp:
			var tip_node: Node3D = (_held as ToolProp).tips.get(host.motion.motion, null)
			if tip_node != null:
				tip_local = tip_node.transform
		var hand := Transform3D(basis, tip_world - basis * tip_local.origin)
		_hand(VrRules.RIGHT, hand)
		Vr.sim_input(VrRules.RIGHT, &"trigger", 0.8 if down else 0.0)
	else:
		var screen := host.camera.unproject_position(frame * Vector3(p.x, 0.0, p.z))   # a finger is on the surface
		if down and not host._finger_down:
			host.hud.finger.emit("down", screen)
		elif down:
			host.hud.finger.emit("move", screen)
		elif host._finger_down:
			host.hud.finger.emit("up", screen)


func _holding(tool: String) -> bool:
	if not vr:
		return host.selected == tool
	var p := host._held_prop(VrRules.RIGHT)
	return p != null and p.tool_id == tool


func _pick_up(tool: String) -> void:
	_phase = _step_ticks + 3
	if not vr:
		host.tray.select(tool)
		return
	var site := host.room as RealBuilderSite
	var prop: ToolProp = site.props()[tool]
	if _grip_on:
		Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
		_grip_on = false
		return
	_hand(VrRules.RIGHT, Transform3D(Basis(), prop.global_position))
	Vr.step(DT)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_grip_on = true
	_held = prop


## Where the tool's working point is at time `t` of a motion done well (the work's frame), and whether it presses.
func _path(m: ToolMotion, t: float) -> Dictionary:
	var c := m.checks
	match m.motion:
		ToolMotion.SPREAD:
			return {"at": Vector3(minf(t * 0.45, float(c.length) + 0.02) - 0.0, 0.006, 0.0), "down": true}
		ToolMotion.STRIKE:
			var cycle := fmod(t, 0.5)
			var y := 0.12 - cycle * 2.0 if cycle < 0.1 else 0.15
			return {"at": Vector3(0, maxf(y, -0.02), 0), "down": cycle < 0.1}
		ToolMotion.AIM:
			return {"at": Vector3(0, 0.005, 0), "down": true}
		ToolMotion.MEASURE:
			var length := float(c.length)
			var x := 0.0 if t < 0.2 else minf((t - 0.2) * 0.6, length)
			return {"at": Vector3(x, 0.005, 0), "down": true}
		ToolMotion.STROKE:
			var u := fmod(t * 0.3, 0.4)
			return {"at": Vector3((u if u < 0.2 else 0.4 - u) - 0.1, 0.005, 0), "down": true}
		ToolMotion.PRESS:
			var k := fmod(t, 0.6)
			return {"at": Vector3(0, 0.05 if k < 0.2 else -0.02, 0), "down": k >= 0.2}
		ToolMotion.TWIST, ToolMotion.SQUEEZE, ToolMotion.POUR, ToolMotion.CUT:
			return {"at": Vector3(minf(t * 0.1, float(c.get("length", 0.3))), 0.0, 0.0), "down": true}
	return {}


func _hand(side: StringName, world: Transform3D) -> void:
	Vr.sim_hand(side, Vr.rig.global_transform.affine_inverse() * world)


static func _vec(v: Variant) -> Vector3:
	if v is Array and (v as Array).size() == 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3.RIGHT
