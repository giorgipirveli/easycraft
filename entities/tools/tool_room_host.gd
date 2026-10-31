class_name ToolRoomHost
extends LifeRoomHost
## Owner #116, #117 (docs/design/life-skills.md §13: "one engine, many skills"): Life's room host (LifeRoomHost: flat and
## VR, the coach, the glow, the break, the stamps' run) with the tool engine in it. Every frame its sample (LifeCheck's
## keys) goes through the engine first, so Life's rules never change:
## - **A real motion** (a step with `motion`, on a target the room gives a work frame: RealBuilderSite.has_work): the
##   step's target is pressed only when ToolMotion says the motion was done well, with the step's tool (its checks: the
##   Tool Book's for the tool, the step's own). Flat: the tray's tool and the finger (ToolSample.flat); VR: the held
##   ToolProp's tip (VR-HANDS' grab) and the trigger (ToolSample.vr), the other hand for a cut's claw; no tool named: the
##   hand itself (a push). Its kind words are said, a good use buzzes softly, its progress keeps the coach waiting.
## - **The right tool for the job:** another tool on the work says kindly which one works better (ToolBook.right_tool);
##   nothing in the hand says to pick it up; the right one glows (the tray flat, the bench in VR).
## - **Safety first:** a step's `safety` gear must be on; trying without it (owner #118: a safe mistake, shaped for Life's
##   coming kind) says the coach's calm why and shows the room's gentle event, never a miss; the gear glows.
## - **A device** (a step's `device`): its controls are pressed in the order (ToolDevice), its safety steps first (gear
##   already worn counts), what it shows reaches the room; the step is done when the device's order is.
## - **Placing** (bricks, blocks, lintels): flat, a tap lays the free piece nearest the finger; VR, only a piece carried
##   to its place and let go counts (the room's `placed`).
## The room opts in (its work frames, its devices: has_work, has_device): an L1 room plays exactly as before. Real Builder plays here before Life's
## catalogue knows it (open swaps in its site and steps); the stamps of the tools used come out as `tools_used`.

signal tools_used(entries: Array, expert: bool)

## A fingertip's size on the screen (px) for a flat motion's reach.
const FINGER_PX := 44.0
## Words about the tool (the right one, pick it up, safety) at most this often (s).
const SAY_EVERY := 3.0
## A hand or tool this close to the work is trying it (m).
const NEAR_WORK := 0.25

var tray: ToolTray
var motion: ToolMotion
var device: ToolDevice
## Gear the child has on now (hard_hat, gloves, goggles).
var worn := {}
## Flat: the tool in the hand (the tray's).
var selected := ""

var _index_seen := -1
var _run_seen: LifeRun
var _finger_down := false
var _finger_pos := Vector2.ZERO
var _placed: Array[String] = []
var _said_at := {}
var _walked := false
var _tool_side: StringName = &""
var _want_gear := ""


# --- Opening ------------------------------------------------------------------------------------------------------

func open(parent: Node) -> void:
	super.open(parent)
	if experience == RealBuilder.ID and not room is RealBuilderSite:
		_swap_in_real_builder()
	if room is RealBuilderSite:
		(room as RealBuilderSite).placed.connect(func(t: String) -> void: _placed.append(t))
	hud.finger.connect(_on_tool_finger)
	tray = ToolTray.new()
	UiLayers.route(tray, self)
	tray.picked.connect(func(id: String) -> void: selected = id)
	tray.set_tools(_bench_tools())
	tray.visible = false
	finished.connect(func(_o: Dictionary) -> void: tools_used.emit(tool_entries(), expert))


## Life's catalogue does not know Real Builder yet (the lead's hook): its site and its steps in place of the empty ones.
func _swap_in_real_builder() -> void:
	var old := room
	remove_child(old)
	old.free()
	room = RealBuilderSite.new(track)
	room.position = ROOM_ORIGIN
	add_child(room)
	camera.environment = room.env
	if vr:
		Vr.view_like(camera)
	run = LifeRun.new(RealBuilder.steps(track, expert, seed, region), expert)
	_start_step(true)


func _bench_tools() -> Array[String]:
	var out: Array[String] = []
	if room is RealBuilderSite:
		for t: String in (room as RealBuilderSite).props():
			out.append(t)
	return out


func _on_tool_finger(kind: String, pos: Vector2) -> void:
	_finger_pos = pos
	if kind == "down":
		_finger_down = true
	elif kind == "up":
		_finger_down = false


# --- Every frame: Life's sample through the engine ------------------------------------------------------------------

func _flat_sample(step: Dictionary, delta: float) -> Dictionary:
	return _engine(step, super._flat_sample(step, delta), delta, false)


func _vr_sample(step: Dictionary, delta: float) -> Dictionary:
	return _engine(step, super._vr_sample(step, delta), delta, true)


func _engine(step: Dictionary, s: Dictionary, delta: float, in_vr: bool) -> Dictionary:
	if run != _run_seen or run.index != _index_seen:
		_begin(step)
	var pressed: Array = s.get("pressed", [])
	for p: Variant in pressed:
		if str(ToolBook.entry(str(p)).get("kind", "")) == "safety" and room.has_target(str(p)):
			_wear(str(p))
	var target := str(step.get("target", ""))
	if device != null:
		_device_frame(step, s, pressed)
	elif _placement(target):
		_placing(step, s, pressed, in_vr)
	elif motion != null:
		_motion_frame(step, s, delta, in_vr)
	s.pressed = pressed
	return s


## A new step: its recogniser or its device; the tray shows when it wants a tool.
func _begin(step: Dictionary) -> void:
	if _run_seen == run and _index_seen >= 0 and _index_seen < run.steps.size():
		var prev: Dictionary = run.steps[_index_seen]
		if str(prev.get("after", "")) == "goggles_off":
			worn.erase("goggles")
	_run_seen = run
	_index_seen = run.index
	motion = null
	device = null
	_walked = false
	_want_gear = ""
	_placed.clear()
	var target := str(step.get("target", ""))
	if str(step.get("device", "")) != "" and room.has_method(&"has_device") and bool(room.call(&"has_device", str(step.device))):
		var data := _device_data(str(step.device))
		if not data.is_empty():
			device = ToolDevice.from(data, str(step.device))
			_device_auto()
	elif str(step.get("motion", "")) != "" and _has_work(target) and str(step.get("kind", "")) == "touch":
		var tool := str(step.get("tool", ""))
		var checks: Variant = step.get("checks", {})
		motion = ToolMotion.new(str(step.motion), ToolBook.checks(tool, str(step.motion)) if tool != "" else {},
			checks if checks is Dictionary else {})
	if tray != null:
		tray.visible = not vr and str(step.get("tool", "")) != "" and motion != null
		tray.glow("")
	if room is RealBuilderSite:
		(room as RealBuilderSite).show_reading("", Vector3.ZERO)


func _has_work(target: String) -> bool:
	return room.has_method(&"has_work") and bool(room.call(&"has_work", target))


func _placement(target: String) -> bool:
	return room is RealBuilderSite and (room as RealBuilderSite).is_placement(target)


func _wear(gear: String) -> void:
	worn[gear] = true
	if room is RealBuilderSite:
		(room as RealBuilderSite).gear_on(gear)
	if _want_gear == gear:
		_want_gear = ""


# --- A real motion ------------------------------------------------------------------------------------------------

func _motion_frame(step: Dictionary, s: Dictionary, delta: float, in_vr: bool) -> void:
	var target := str(step.target)
	(s.get("pressed", []) as Array).erase(target)
	(s.get("held", []) as Array).erase(target)
	var tool := str(step.get("tool", ""))
	var frame := Transform3D(room.call(&"work_frame", target))
	var sample := {}
	var trying := false
	if in_vr:
		var r := _vr_tool_sample(step, frame, delta)
		sample = r.sample
		trying = r.trying
	else:
		var r := _flat_tool_sample(step, frame, delta)
		sample = r.sample
		trying = r.trying
	if sample.is_empty():
		return
	var gear := str(step.get("safety", ""))
	if gear != "" and not worn.has(gear):
		if trying:
			_safe_mistake(step, gear, s)
		return
	var e := motion.feed(sample)
	if str(e.said) != "":
		hud.pop_line(str(e.said), str(e.verdict) == "good")
	if bool(e.progress):
		run.idle = 0.0
	if float(e.buzz) > 0.0 and in_vr and _tool_side != &"":
		Vr.haptic(_tool_side, float(e.buzz), 0.05)
	if motion.motion == ToolMotion.MEASURE:
		_measuring(step, frame)
	if motion.done:
		(s.pressed as Array).append(target)


## Flat: the tray's tool and the finger on the work. {sample, trying}.
func _flat_tool_sample(step: Dictionary, frame: Transform3D, delta: float) -> Dictionary:
	var tool := str(step.get("tool", ""))
	var from := camera.project_ray_origin(_finger_pos)
	var dir := camera.project_ray_normal(_finger_pos)
	var depth := maxf((frame.origin - camera.global_position).dot(-camera.global_basis.z), 0.1)
	var height := maxf(get_viewport().get_visible_rect().size.y, 1.0)
	var reach := FINGER_PX * 2.0 * depth * tan(deg_to_rad(camera.fov) * 0.5) / height
	if tool != "" and selected != tool:
		if _finger_down:
			_say(ToolBook.right_tool(tool, selected))
			tray.glow(tool)
		return {"sample": {}, "trying": false}
	var sample := ToolSample.flat(frame, from, dir, _finger_down, delta, reach)
	var on_work: bool = sample.has("at") and Vector2((sample.at as Vector3).x, (sample.at as Vector3).z).length() <= 1.0
	return {"sample": sample, "trying": _finger_down and on_work}


## VR: the held tool's tip (or the hand for a push) on the work. {sample, trying}.
func _vr_tool_sample(step: Dictionary, frame: Transform3D, delta: float) -> Dictionary:
	var tool := str(step.get("tool", ""))
	_tool_side = &""
	var other := Vector3.INF
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var prop := _held_prop(side)
		var hand := Vr.hand_grip(side)
		var near := (frame.affine_inverse() * hand.origin).length() <= NEAR_WORK + 0.5 \
			or hand.origin.distance_to(room.target_position(str(step.target))) <= NEAR_WORK
		if tool == "":
			if near or _tool_side == &"":
				_tool_side = side
			continue
		if prop != null and prop.tool_id == tool:
			_tool_side = side
		elif prop != null and near:
			_say(ToolBook.right_tool(tool, prop.tool_id))
		elif prop == null and near and _held_prop(VrRules.LEFT if side == VrRules.RIGHT else VrRules.RIGHT) == null:
			_say(ToolBook.right_tool(tool, ""))
	if _tool_side == &"":
		if tool != "":
			room.glow(["tool_" + tool] as Array[String])
		return {"sample": {}, "trying": false}
	var other_side := VrRules.LEFT if _tool_side == VrRules.RIGHT else VrRules.RIGHT
	if motion.motion == ToolMotion.CUT:
		other = Vr.hand_grip(other_side).origin
	var tip := Vr.hand_grip(_tool_side)
	if tool != "":
		tip = _held_prop(_tool_side).tip(motion.motion)
	var sample := ToolSample.vr(frame, tip, Vr.trigger(_tool_side), delta, other)
	var at: Vector3 = sample.at
	return {"sample": sample, "trying": at.y <= 0.12 and Vector2(at.x, at.z).length() <= 1.0}


func _held_prop(side: StringName) -> ToolProp:
	if Vr.grabber == null:
		return null
	var g := Vr.grabber.held(side)
	return g.thing() as ToolProp if g != null and is_instance_valid(g) else null


## Owner #118: trying without the gear. The coach's calm why, the room's gentle event, the gear glows; never a miss.
## Life L3b: a safe mistake with a `try` ("unsafe": the saw before the goggles) is tried for real the first time: this
## frame's sample says the step's target was pressed at an unsafe moment, so Life's run counts the mistake and the host
## freezes time (freeze_for: the still picture, the coach's card). Once explained, a later try is the shaped way above.
func _safe_mistake(step: Dictionary, gear: String, s: Dictionary = {}) -> void:
	if LifeCheck.tries_mistake(step) and run.mistakes_on(run.index) == 0 and s.has("pressed"):
		s["safe"] = false
		(s.pressed as Array).append(str(step.get("target", "")))
		return
	var m: Variant = step.get("safe_mistake", {})
	var why := str((m as Dictionary).get("why", "")) if m is Dictionary else ""
	if why == "":
		why = ToolDevice.SAFETY_FIRST % (ToolBook.name_of(gear) + " on")
	if _say(why) and m is Dictionary and str((m as Dictionary).get("event", "")) != "":
		room.react(str(m.event))
	_want_gear = gear
	room.glow([gear] as Array[String])


func _measuring(step: Dictionary, frame: Transform3D) -> void:
	if not motion.hooked():
		return
	if room is RealBuilderSite:
		var at := frame * Vector3(motion.reading, 0.0, 0.0)
		(room as RealBuilderSite).show_reading("%.2f m" % motion.reading, at)
	if vr and not _walked and str(step.get("walk", "")) != "" and room.views.has(str(step.walk)):
		_walked = true   # a long tape: hooked on, the child is carried along to its end
		stand.global_transform = room.vr_stand(str(step.walk))
		Vr.blink()


# --- A device -----------------------------------------------------------------------------------------------------

func _device_data(id: String) -> Dictionary:
	var own: Dictionary = RealBuilder.devices(region) if experience == RealBuilder.ID else LifeExperience.devices(experience, region)
	return own.get(id, ToolBook.device(id))


## The gear already on does its safety steps by itself (gloves on: done).
func _device_auto() -> void:
	while device != null and not device.finished and worn.has(device.next_do()):
		device.use(device.next_do())
	_device_shows()


func _device_frame(step: Dictionary, s: Dictionary, pressed: Array) -> void:
	var target := str(step.target)
	var prefix := str(step.device) + "_"
	for p: Variant in pressed.duplicate():
		var name := str(p)
		var control := name.substr(prefix.length()) if name.begins_with(prefix) else name
		if not device.knows(control):
			continue
		pressed.erase(p)
		var r := device.use(control)
		if bool(r.ok):
			run.idle = 0.0
			if vr:
				for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
					Vr.haptic(side, 0.3, 0.05)
			_device_auto()
		elif str(r.said) != "":
			_say(str(r.said))
	pressed.erase(target)
	if device.finished:
		pressed.append(target)
	_device_shows()


func _device_shows() -> void:
	if room is RealBuilderSite and device != null:
		(room as RealBuilderSite).device_shows(device.displays)


func _device_next_target() -> String:
	if device == null or device.finished:
		return ""
	var n := device.next_do()
	return n if room.has_target(n) else "%s_%s" % [device.id, n]


# --- Placing ------------------------------------------------------------------------------------------------------

func _placing(step: Dictionary, s: Dictionary, pressed: Array, in_vr: bool) -> void:
	var target := str(step.target)
	var site := room as RealBuilderSite
	if in_vr:
		if target.begins_with("course") or target.begins_with("lintel_"):
			pressed.erase(target)   # a brick is carried to its place, never squeezed into it
		for t in _placed:
			if t == target:
				pressed.append(target)
		_placed.clear()
		return
	if pressed.has(target):
		var from := camera.project_ray_origin(_finger_pos)
		var dir := camera.project_ray_normal(_finger_pos)
		var to := site.target_position(target)
		site.aim_point = from + dir * maxf((to - from).dot(dir), 0.0)


# --- The glow, the bar, the coach ---------------------------------------------------------------------------------

func _after_progress(step: Dictionary, state: Dictionary, done: bool) -> void:
	super._after_progress(step, state, done)
	if done:
		return
	if run != _run_seen or run.index != _index_seen:
		_begin(step)
	if device != null:
		var n := _device_next_target()
		room.glow([n] as Array[String] if n != "" else [] as Array[String])
		hud.set_fraction(device.fraction())
	elif motion != null:
		hud.set_fraction(motion.fraction())
		var tool := str(step.get("tool", ""))
		if _want_gear != "":
			room.glow([_want_gear] as Array[String])
		elif tool != "" and not vr and selected != tool and tray != null:
			tray.glow(tool)
		elif tool != "" and vr and _held_prop(VrRules.LEFT) == null and _held_prop(VrRules.RIGHT) == null:
			room.glow(["tool_" + tool] as Array[String])


func _coach() -> void:
	var step := run.current()
	if device == null and motion == null:
		super._coach()
		return
	hud.coached()
	hud.pop_line(str(step.get("say", "")), false)
	var at := room.target_position(str(step.target))
	var how := "tap"
	if device != null:
		var n := _device_next_target()
		if n != "":
			at = room.target_position(n)
	else:
		at = Transform3D(room.call(&"work_frame", str(step.target))).origin
		how = {"strike": "taps", "stroke": "drag", "spread": "drag", "measure": "drag", "cut": "drag", "twist": "drag"}.get(
			motion.motion, "hold")
		var tool := str(step.get("tool", ""))
		if not vr and tool != "" and selected != tool:
			hud.ghost.show_at(tray.centre_of(tool), "tap")
			return
	if vr:
		ghost.demonstrate({"taps": "taps", "drag": "sweep", "hold": "hold"}.get(how, "touch"), at, Vr.head_transform())
	else:
		hud.ghost.show_at(camera.unproject_position(at), how)


## Kind words about tools at most every SAY_EVERY s (the same words); true when said now.
func _say(words: String) -> bool:
	if words == "":
		return false
	var now := run.clock if run != null else 0.0
	if now - float(_said_at.get(words, -INF)) < SAY_EVERY:
		return false
	_said_at[words] = now
	hud.pop_line(words, false)
	return true


# --- The Tool Book's stamps -----------------------------------------------------------------------------------------

## Every tool, piece of gear and device this run's finished steps used, with whether the coach helped: [{tool, hinted}]
## (ToolData.record).
func tool_entries() -> Array:
	var out := []
	for i in mini(run.steps_log.size(), run.steps.size()):
		var step: Dictionary = run.steps[i]
		var hinted := bool(run.steps_log[i].get("hinted", false))
		var used: Array = [step.get("tool", ""), step.get("device", "")] + (step.get("gear", []) as Array)
		for t: Variant in used:
			if str(t) != "" and ToolBook.has(str(t)):
				out.append({"tool": str(t), "hinted": hinted})
	return out
