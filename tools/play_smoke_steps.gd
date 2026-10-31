extends Node
## The steps of tools/play_smoke.gd (a Node, so it may use the autoloads and the game's classes).

const LIMIT := 30.0   # seconds a run may take

var _fails := 0
var _runs := 0
var _layer: CanvasLayer
var _holder: Control


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var only := ""
	var unit_only := ""
	var modes: Array = ["flat", "vr"]
	var grades: Array = []
	for a in args:
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a.begins_with("--modes="):
			modes = a.trim_prefix("--modes=").split(",")
		elif a.begins_with("--unit="):
			unit_only = a.trim_prefix("--unit=")
		elif a.begins_with("--grades="):
			for g in a.trim_prefix("--grades=").split(","):
				grades.append(int(g))
	Profile.data.settings.reduce_motion = true
	_layer = CanvasLayer.new()
	add_child(_layer)
	_holder = Control.new()
	_layer.add_child(_holder)
	if only == "" or only == "types":
		for t: String in ExerciseCheck.TYPES:
			if not PlayMechanics.kept(PlayMechanics.of(t)):   # owner #134: a written choice or claim is never played
				print("PLAY_SMOKE type %s: shelved (%s): it stays in the School" % [t, PlayMechanics.name_of(PlayMechanics.of(t))])
				continue
			var found := _first_of_type(t)
			if found.is_empty():
				print("PLAY_SMOKE type %s: no hand-written exercise that plays without reading (its generators play it)" % t)
				continue
			for mode: String in modes:
				await _play_one(found.unit, found.ex, mode)
	if only == "" or only == "units":
		for g in Curriculum.grades():
			if not grades.is_empty() and not grades.has(g):
				continue
			for s: Dictionary in Curriculum.subjects(g):
				var id := _first_written(g, str(s.id))
				if id == "" and unit_only == "":
					print("PLAY_SMOKE g%d %s: no unit plays without reading yet (it stays in the School)" % [g, s.id])
				if id == "" or (unit_only != "" and id != unit_only):
					continue
				await _play_unit(id, "flat")
				if g == 5 and modes.has("vr"):
					await _play_unit(id, "vr")
	Vr.simulate(false)
	print("PLAY_SMOKE done runs=%d failed=%d" % [_runs, _fails])
	get_tree().quit(0 if _fails == 0 else 1)


func _first_of_type(t: String) -> Dictionary:
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				for ex: Dictionary in Curriculum.content(str(u.id)).get("exercises", []):
					if str(ex.type) == t and PlayReadless.plays(ex):
						return {"unit": str(u.id), "ex": ex}
	return {}


## The subject's first unit that plays without reading (owner #134: the rest stay in the School).
func _first_written(g: int, subject: String) -> String:
	for u: Dictionary in Curriculum.units(g, subject):
		if Curriculum.has_content(str(u.id)) and PlayHost.plays(Curriculum.content(str(u.id))):
			return str(u.id)
	return ""


func _open(id: String, mode: String) -> PlayHost:
	Vr.simulate(mode == "vr")
	await get_tree().process_frame
	await get_tree().process_frame
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:   # every run starts with open hands
		Vr.sim_input(side, &"grip", 0.0)
		Vr.sim_input(side, &"trigger", 0.0)
	var host := PlayHost.new()
	host.setup(id, Curriculum.content(id), 11, 0, Curriculum.unit(id))
	host.open(_holder)
	for i in 3:
		await get_tree().physics_frame
		await get_tree().process_frame
	host.end_hook()
	return host


## One exercise in its station through the real host: played right by the coach's steps.
func _play_one(id: String, ex: Dictionary, mode: String) -> void:
	_runs += 1
	var t0 := Time.get_ticks_msec()
	var host: PlayHost = await _open(id, mode)
	host.show_exercise(ex.duplicate(true))
	await get_tree().process_frame
	var ok: bool = await _solve(host, mode)
	var right := ok and host.loop.answered and host.loop.first_try
	var label := "type %s (%s) %s %s" % [str(ex.type), host.station().mechanic, id, mode]
	var why := "" if right else "not answered right by acting (answered %s, tries %d, response %s, ghost %s)" % [
		host.loop.answered, host.loop.tries, host.station().response(), host.station().ghost()]
	host.close()
	await get_tree().process_frame
	_result(label, right, t0, why)


## A whole unit's round to its end: six right the first time, and the outcome sent.
func _play_unit(id: String, mode: String) -> void:
	_runs += 1
	var t0 := Time.get_ticks_msec()
	var host: PlayHost = await _open(id, mode)
	var outcome := {}
	host.finished.connect(func(o: Dictionary) -> void: outcome.merge(o))   # a lambda keeps its own copy of a local: merge
	var why := ""
	var total := host.loop.total()
	for i in total:
		if not is_instance_valid(host) or host.closed:
			break
		var ok: bool = await _solve(host, mode)
		if not ok or not host.loop.first_try:
			why = "challenge %d (%s) not right by acting (tries %d, response %s)" % [i + 1, host.station().mechanic,
				host.loop.tries, host.station().response()]
			break
		host.next()
		await get_tree().process_frame
		if is_instance_valid(host) and not host.closed and host.loop.phase == PlayLoop.WHY:
			host.play_on()
			await get_tree().process_frame
		if (Time.get_ticks_msec() - t0) / 1000.0 > LIMIT:
			why = "too slow"
			break
	var good := why == "" and int(outcome.get("right_first", -1)) == int(outcome.get("total", -2))
	if why == "" and not good:
		why = "the round's end: %s" % outcome
	if is_instance_valid(host) and not host.closed:
		host.close()
	await get_tree().process_frame
	_result("unit %s %s" % [id, mode], good, t0, why)


## Plays the current challenge by the coach's steps (flat: fingers; VR: hands, carrying, the laser for the far).
func _solve(host: PlayHost, mode: String) -> bool:
	var st := host.station()
	for k in 120:
		if host.loop.answered:
			return true
		var steps := st.ghost()
		if steps.is_empty():
			break
		for t in steps:
			if mode == "vr":
				await _vr_tap(host, t)
			else:
				if OS.has_environment("PLAY_SMOKE_DEBUG"):
					print("PLAY_SMOKE_DEBUG tap %s at %s picks %s; at %s" % [t, host.screen_of(t), host.pick(host.screen_of(t)),
						st.get("placing").at if st.get("placing") != null else ""])
				host.finger_down(host.screen_of(t))
				host.finger_up(host.screen_of(t))
				await get_tree().process_frame
	if not host.loop.answered and not st.answers_by_acting():
		if mode == "vr":
			await _vr_tap(host, PlayStation.GO)
		else:
			host.finger_down(host.screen_of(PlayStation.GO))
			host.finger_up(host.screen_of(PlayStation.GO))
		await get_tree().process_frame
	return host.loop.answered


## VR: the right hand goes to the thing and squeezes; a lifted thing is carried to the place the coach's next step names
## (or the hand lets go where it is: a press).
func _vr_tap(host: PlayHost, t: String) -> void:
	var st := host.station()
	if not host.arena.has_target(t):
		return
	var at := host.arena.target_position(t)
	if OS.has_environment("PLAY_SMOKE_DEBUG"):
		print("PLAY_SMOKE_DEBUG vr tap %s at %.2f m, carried '%s', holding %s, touching '%s'" % [t,
			host.arena.vr_stand(PlayArena.VIEW).origin.distance_to(at), st.carried, host._holding, host._touching(at)])
	var by_hand := st.carried != "" and host._holding.has(VrRules.RIGHT)   # a thing in the hand goes by the hand
	if not by_hand and host.arena.vr_stand(PlayArena.VIEW).origin.distance_to(at) > 1.1:   # far: the laser's trigger
		await _laser_tap(host, at)
		return
	if st.carried != "" and st.spots_for(st.carried).has(t):   # carrying: the hand goes there and lets go
		_hand(at)
		for i in 3:
			await get_tree().process_frame
		Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
		for i in 3:
			await get_tree().process_frame
		return
	_hand(at)
	await get_tree().process_frame
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	for i in 3:
		await get_tree().process_frame
	if st.carried == "":   # a press: let go at once
		Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
		await get_tree().process_frame


func _laser_tap(host: PlayHost, at: Vector3) -> void:
	var from := host.arena.vr_stand(PlayArena.VIEW).origin + Vector3(0.15, -0.3, -0.1)
	var side := Vr.pointing_hand()
	var b := Basis.looking_at((at - from).normalized(), Vector3.UP)
	Vr.sim_hand(side, Vr.rig.global_transform.affine_inverse() * Transform3D(b, from))
	await get_tree().process_frame
	Vr.sim_input(side, &"trigger", 1.0)
	await get_tree().process_frame
	await get_tree().process_frame
	Vr.sim_input(side, &"trigger", 0.0)
	await get_tree().process_frame


func _hand(at: Vector3) -> void:
	Vr.sim_hand(VrRules.RIGHT, Vr.rig.global_transform.affine_inverse() * Transform3D(Basis(), at))


func _result(label: String, ok: bool, t0: int, why: String) -> void:
	if not ok:
		_fails += 1
	print("PLAY_SMOKE %s %s %.1fs%s" % [label, "PASS" if ok else "FAIL", (Time.get_ticks_msec() - t0) / 1000.0,
		"" if ok else " " + why])
