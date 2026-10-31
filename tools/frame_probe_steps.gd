extends Node
## The steps of tools/frame_probe.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).

const ALL := ["menu", "new", "walk", "cruise", "fly", "trip", "continue", "survivor"]
const SEED := 12345
## The autopilot's runs as the lead makes them on the emulator (the developer menu's WORLD, then AUTOPILOT BLOCKY: a new
## Survivor world of that world, tools/autopilot.gd's 60 s play and 2 km flight), by phase name (2026-09-30, the frame
## spikes: docs/devlog/parts/frame-spikes.md). Not in ALL: pick them with --phases=.
const PILOTS := {"moon-pilot": SpaceRules.MOON, "mars-pilot": 19, "venus-pilot": 24, "wonders-pilot": EarthRules.WONDERS}
## World 41's second tour: a new Survivor world there, down the Wonders Road on foot (its speed pads), then a flight
## round the New Seven's wonders (not in ALL).
const ROAD := "wonders-road"
## World 41's third tour: down the Nature Trail on foot, then a flight round the Seven Natural Wonders (not in ALL).
const TRAIL := "nature-trail"

var _phases: Array = ALL.duplicate()
var _over := 50
var _blame: Node
var _stats := {}   # phase -> {frames, sum, worst, over16, over33, over50, over100, over200}
var _order: Array[String] = []
var _phase := ""
var _phase_t0 := 0
var _last := 0
var _added := {}
var _menu_seconds := 3.0
## () -> String: what a long frame's line says besides its phase (the autopilot's t, where the child is).
var _context: Callable
## The main thread's time on a CPU and waiting for one (/proc/thread-self/schedstat, ns) at the last frame's start: a
## long frame's line says how much of it was work and how much this shared PC's other programs took (--cpu).
var _cpu := false
var _sched := PackedInt64Array([0, 0])
var _sights: Node   # tools/first_sights.gd (--sights)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.MOON)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--phases="):
			_phases = Array(a.trim_prefix("--phases=").split(","))
		elif a.begins_with("--over="):
			_over = int(a.trim_prefix("--over="))
		elif a.begins_with("--menu-seconds="):
			_menu_seconds = float(a.trim_prefix("--menu-seconds="))
		elif a == "--cpu":
			_cpu = true
		elif a.begins_with("--voxel-threads="):
			VoxelEngine.set_thread_count(int(a.trim_prefix("--voxel-threads=")))
	print("PROBE voxel threads: %d" % VoxelEngine.get_thread_count())
	if OS.get_cmdline_user_args().has("--sights"):   # the first sights of every draw, with their warm-up tier
		ShaderWarmup.done = true   # as after a menu's warm-up (a browser, the emulator): the spawn's prewarms are left to it
		var sights: Node = load("res://tools/first_sights.gd").new()
		_sights = sights
		sights.set("context", func() -> String:
			var ctx := "%s +%.1f s" % [_phase, (Time.get_ticks_msec() - _phase_t0) / 1000.0]
			return ctx + (" (%s)" % _context.call() if _context.is_valid() else ""))
		get_tree().root.add_child.call_deferred(sights)
	if not OS.get_cmdline_user_args().has("--no-blame"):
		_blame = load("res://tools/frame_blame.gd").new()
		_blame.threshold_ms = _over
		_blame.window.connect(_on_window)
		get_tree().root.add_child.call_deferred(_blame)
	else:
		get_tree().process_frame.connect(_on_frame)
	get_tree().node_added.connect(func(n: Node) -> void:
		var sc: Script = n.get_script()
		var key: String = sc.resource_path.get_file() if sc and sc.resource_path != "" else n.get_class()
		_added[key] = int(_added.get(key, 0)) + 1)
	for s in [ModeRules.slot(ModeRules.SANDBOX, 1), ModeRules.slot(ModeRules.SANDBOX, SpaceRules.MOON),
			ModeRules.slot(ModeRules.SURVIVOR, 1)]:
		WorldSaves.delete(s)
	_last = Time.get_ticks_usec()
	_run()


func _begin(phase: String) -> void:
	_phase = phase
	_phase_t0 = Time.get_ticks_msec()
	if not _stats.has(phase):
		_stats[phase] = {"frames": 0, "sum": 0.0, "worst": 0.0, "over16": 0, "over33": 0, "over50": 0, "over100": 0,
			"over200": 0}
		_order.append(phase)
	print("PROBE phase %s begins at %d ms (load %s)" % [phase, _phase_t0, _load()])


func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


## Every frame without the blame: its length (between two process_frame signals).
func _on_frame() -> void:
	var now := Time.get_ticks_usec()
	var ms := (now - _last) / 1000.0
	_last = now
	_on_window(ms)


## Every frame: its length (with the blame, measured by it: between two process_frame signals).
func _on_window(ms: float) -> void:
	if _phase != "":
		var s: Dictionary = _stats[_phase]
		s.frames += 1
		s.sum += ms
		s.worst = maxf(s.worst, ms)
		for t in [16, 33, 50, 100, 200]:
			if ms > t:
				s["over%d" % t] += 1
		if ms > _over:
			var top := _added.keys()
			top.sort_custom(func(a, b): return _added[a] > _added[b])
			var parts: Array[String] = []
			for k in top.slice(0, 6):
				parts.append("%s x%d" % [k, _added[k]])
			var line := "PROBE long %.0f ms in %s at +%.1f s" % [ms, _phase, (Time.get_ticks_msec() - _phase_t0) / 1000.0]
			if _context.is_valid():
				line += " (%s)" % _context.call()
			if _cpu:
				var now := _schedstat()
				line += " [main thread: cpu %.1f ms, runqueue %.1f ms]" % [(now[0] - _sched[0]) / 1e6, (now[1] - _sched[1]) / 1e6]
			if not parts.is_empty():
				line += "; added " + ", ".join(parts)
			if _blame:
				var d: String = _blame.describe()
				if d != "":
					line += "\n    " + d
			print(line)
	_added.clear()
	if _cpu:
		_sched = _schedstat()


## The main thread's [ns on a CPU, ns waiting on the run queue] so far.
func _schedstat() -> PackedInt64Array:
	var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
	if f == null:
		return PackedInt64Array([0, 0])
	var parts := f.get_line().split(" ")
	return PackedInt64Array([int(parts[0]), int(parts[1])])


func _sb() -> Node:
	var sb := get_tree().current_scene
	return sb if sb != null and sb.get("player") != null else null


func _player() -> Player:
	var sb := _sb()
	return sb.player as Player if sb else null


func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame


## Waits for a new sandbox scene (not `old`) whose player stands in the world; false after 90 s.
func _wait_spawned(old: Node) -> bool:
	var until := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		var sb := _sb()
		if sb != null and sb != old and (sb.player as Player).is_spawned():
			return true
	print("PROBE timeout waiting for the child to stand")
	return false


func _start(mode: StringName, fresh: bool, name: String) -> bool:
	var old := get_tree().current_scene
	print("PROBE voxel tasks queued before the switch: %d" % WorldService.voxel_tasks())
	_begin(name + "-load")
	if fresh:
		Game.new_world_seed = SEED
	Game.start_world(mode, fresh, DifficultyRules.NORMAL, 1)
	if not await _wait_spawned(old):
		return false
	_begin(name + "-play")
	await _wait(10.0)
	return true


## SAVE AND QUIT (or the menu at the start): the quit's frames count in `phase` too.
func _to_menu(phase: String) -> void:
	var sb := _sb()
	var old := get_tree().current_scene
	print("PROBE voxel tasks queued before quitting: %d" % WorldService.voxel_tasks())
	_begin(phase)
	if sb:
		sb.call("_save_and_quit")
	else:
		get_tree().change_scene_to_file(Game.MENU_SCENE)
	while get_tree().current_scene == old or get_tree().current_scene == null:
		await get_tree().process_frame
	await _wait(_menu_seconds)


func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _phases.has("menu"):
		await _to_menu("menu")
	if _phases.has("new"):
		if not await _start(ModeRules.SANDBOX, true, "new"):
			return _done(1)
	if _phases.has("walk") and _player():
		_begin("walk")
		var p := _player()
		var rng := RandomNumberGenerator.new()
		rng.seed = SEED
		Input.action_press("move_forward")
		Input.action_press("jump")
		var from := p.global_position
		var until := Time.get_ticks_msec() + 60000
		var turns := 0
		while Time.get_ticks_msec() < until:
			await _wait(1.5)
			if p.global_position.distance_to(from) < 1.0:   # stuck against a hill: turn like a child would
				p.rig.yaw += PI / 2.0 + rng.randf_range(-0.5, 0.5)
				turns += 1
			from = p.global_position
		Input.action_release("move_forward")
		Input.action_release("jump")
		print("PROBE walked to %s (%d turns)" % [p.global_position, turns])
		await _wait(1.0)   # two quick JUMP taps would switch FLY off again (owner #54)
	if _phases.has("cruise") and _player():
		_begin("cruise")
		var p := _player()
		p.set_physics_mode(PhysicsMode.Mode.FLY)
		Input.action_press("jump")
		await _wait(2.5)   # up above the hills
		Input.action_release("jump")
		Input.action_press("move_forward")
		var from := p.global_position
		var stuck := 0
		var until := Time.get_ticks_msec() + 30000
		while Time.get_ticks_msec() < until:
			await _wait(1.5)
			if p.global_position.distance_to(from) < 1.0:   # boxed in (after the walk: a hollow): turn, then lift out
				stuck += 1
				p.rig.yaw += PI / 2.0
				if stuck >= 2:
					p.global_position.y += 8.0
			from = p.global_position
		Input.action_release("move_forward")
		print("PROBE cruised to %s" % p.global_position)
		p.set_physics_mode(PhysicsMode.Mode.NORMAL)
		await _wait(3.0)
	if _phases.has("fly") and _player():
		_begin("fly")
		var p := _player()
		p.set_physics_mode(PhysicsMode.Mode.FLY)
		Input.action_press("jump")
		var until := Time.get_ticks_msec() + 60000
		var sb := _sb()
		var y := p.global_position.y
		var check := Time.get_ticks_msec() + 2000
		var stuck := 0
		while not (sb.get("space") and sb.space.panel.visible) and Time.get_ticks_msec() < until:
			await get_tree().process_frame
			if Time.get_ticks_msec() > check:   # under an overhang: fly out from under it
				check = Time.get_ticks_msec() + 2000
				if p.global_position.y < y + 1.0:
					stuck += 1
					p.rig.yaw += PI / 2.0
					Input.action_press("move_forward")
					if stuck >= 4:   # still boxed in (a cave after the cruise): lift it out, this is a measurement
						p.global_position.y += 6.0
				else:
					Input.action_release("move_forward")
				y = p.global_position.y
		Input.action_release("jump")
		Input.action_release("move_forward")
		print("PROBE picker at y=%.1f" % p.global_position.y)
		if not sb.space.panel.visible:
			print("PROBE no picker: mode %s, sleeping %s, knocked out %s, riding %s, hiding %s, gadget %s, water %s, velocity %s" % [
				p.physics_mode, p.sleeping, p.knocked_out, p.is_riding(), p.is_hiding(), p.gadget_move, p.water_state, p.velocity])
		if _phases.has("trip") and sb.space.panel.visible:
			var old := get_tree().current_scene
			print("PROBE voxel tasks queued before the trip: %d" % WorldService.voxel_tasks())
			_begin("trip-load")
			sb.space.panel.body_for(&"moon").pressed.emit()
			sb.space.panel.action_button.pressed.emit()
			if not await _wait_spawned(old):
				return _done(1)
			_begin("trip-play")
			await _wait(15.0)
	if _phases.has("continue"):
		await _to_menu("menu-2")
		if not await _start(ModeRules.SANDBOX, false, "continue"):
			return _done(1)
	if _phases.has("survivor"):
		await _to_menu("menu-3")
		if not await _start(ModeRules.SURVIVOR, true, "survivor"):
			return _done(1)
	for p: String in _phases:
		if PILOTS.has(p):
			if not await _pilot(p, int(PILOTS[p])):
				return _done(1)
		elif p == ROAD:
			if not await _road():
				return _done(1)
		elif p == TRAIL:
			if not await _road(&"nature"):
				return _done(1)
	_done(0)


## The autopilot in a new Survivor world of `universe`, as the developer menu starts it: `<name>-load` until the child
## stands, `<name>-wait` (its 3 s), `<name>-play` (60 s), `<name>-fly` (2 km), then the menu (`<name>-quit`). Long frames
## say the autopilot's own t (and in the flight, the distance flown), to line up with its AUTOPILOT slow lines.
func _pilot(name: String, universe: int) -> bool:
	var old := get_tree().current_scene
	print("PROBE voxel tasks queued before %s: %d" % [name, WorldService.voxel_tasks()])
	WorldSaves.delete(ModeRules.slot(ModeRules.SURVIVOR, universe))
	_begin(name + "-load")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.NORMAL, universe)
	Game.autopilot = true   # as the developer menu's AUTOPILOT button: after start_world, read by the new scene
	if not await _wait_spawned(old):
		return false
	var sb := _sb()
	var pilot: Node = null
	for c in sb.get_children():
		if c.get_script() and (c.get_script() as Script).resource_path.ends_with("autopilot.gd"):
			pilot = c
	if pilot == null:
		print("PROBE no autopilot in %s" % name)
		return false
	_begin(name + "-wait")
	var seen := "wait"
	var pilot_ref: WeakRef = weakref(pilot)   # the lambda outlives the world (a freed capture is an error)
	_context = func() -> String:
		var pilot_now: Node = pilot_ref.get_ref()
		if pilot_now == null:
			return ""
		var p := _player()
		var out := "pilot t=%.2f" % float(pilot_now.get("_t"))
		if p and str(pilot_now.get("_phase")) == "fly":
			var start: Vector3 = pilot_now.get("_start")
			out += " flown=%d m" % Vector2(p.global_position.x - start.x, p.global_position.z - start.z).length()
		if p:
			out += " at %s" % Vector3i(p.global_position)
		return out
	var until := Time.get_ticks_msec() + 600000
	while Time.get_ticks_msec() < until and is_instance_valid(pilot) and get_tree().current_scene == sb:
		await get_tree().process_frame
		var ph := str(pilot.get("_phase")) if is_instance_valid(pilot) else "done"
		if ph != seen:
			seen = ph
			if ph == "done":
				break
			_begin("%s-%s" % [name, ph])
	_context = Callable()
	_begin(name + "-quit")
	while get_tree().current_scene == sb or get_tree().current_scene == null:
		await get_tree().process_frame
	await _wait(2.0)
	return true


## World 41: a new Survivor world, then down the Wonders Road on foot to the New Seven's square (the road's speed
## pads push), then a flight at 20 m over the ground round the New Seven's wonders and back to the square. With `tour`
## &"nature" (owner #78's third tour, phases "trail-…"): down the Nature Trail to the nature square and a flight round
## the Seven Natural Wonders.
func _road(tour: StringName = &"new") -> bool:
	var tag := "road" if tour == &"new" else "trail"
	var old := get_tree().current_scene
	WorldSaves.delete(ModeRules.slot(ModeRules.SURVIVOR, EarthRules.WONDERS))
	_begin(tag + "-load")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.NORMAL, EarthRules.WONDERS)
	if not await _wait_spawned(old):
		return false
	_begin(tag + "-stand")
	await _wait(5.0)
	var p := _player()
	var p_ref: WeakRef = weakref(p)
	_context = func() -> String:
		var now: Node3D = p_ref.get_ref()
		return "at %s" % Vector3i(now.global_position) if now else ""
	_begin(tag + "-walk")
	var square := Vector2(WonderTour.square(tour))
	Input.action_press("move_forward")
	var until := Time.get_ticks_msec() + 150000
	var from := p.global_position
	var check := Time.get_ticks_msec() + 1500
	while Vector2(p.global_position.x, p.global_position.z).distance_to(square) > 6.0 and Time.get_ticks_msec() < until:
		await get_tree().process_frame
		_face(p, square)   # along the road (z = 0, west) or the trail (straight south-south-east)
		if Time.get_ticks_msec() > check:
			check = Time.get_ticks_msec() + 1500
			if p.global_position.distance_to(from) < 1.0:   # something in the way: hop over it
				Input.action_press("jump")
				await _wait(0.3)
				Input.action_release("jump")
			from = p.global_position
	Input.action_release("move_forward")
	print("PROBE walked the %s to %s" % [tag, Vector3i(p.global_position)])
	_begin(tag + "-fly")
	p.set_physics_mode(PhysicsMode.Mode.FLY)
	Input.action_press("jump")
	await _wait(2.0)   # up over the wonders
	Input.action_release("jump")
	var stops: Array[Vector2] = []
	for id: StringName in WonderTour.ids():
		if WonderFacts.tour_of(id) == tour:
			stops.append(Vector2(WonderTour.WONDERS[id].centre))
	stops.append(square)
	Input.action_press("move_forward")
	for stop in stops:
		var give_up := Time.get_ticks_msec() + 60000
		while Vector2(p.global_position.x, p.global_position.z).distance_to(stop) > 6.0 and Time.get_ticks_msec() < give_up:
			await get_tree().process_frame
			_face(p, stop)
			var ground := float(p.world.surface_height(int(p.global_position.x), int(p.global_position.z)))
			if p.global_position.y < ground + 20.0:   # keep over the wonders' tops
				p.global_position.y += 0.5
		print("PROBE over %s at %s" % [stop, Vector3i(p.global_position)])
	Input.action_release("move_forward")
	_context = Callable()
	_begin(tag + "-hover")
	await _wait(5.0)
	return true


## Turns the child toward `to` (x, z): forward is Basis(UP, yaw) * FORWARD (Player).
func _face(p: Player, to: Vector2) -> void:
	var d := to - Vector2(p.global_position.x, p.global_position.z)
	if d.length() > 0.5:
		p.rig.yaw = atan2(-d.x, -d.y)


func _done(code: int) -> void:
	_phase = ""
	for phase in _order:
		var s: Dictionary = _stats[phase]
		print("PROBE phase %-14s frames %5d  avg %6.1f ms  worst %6.0f ms  >16: %4d  >33: %4d  >50: %3d  >100: %3d  >200: %3d" % [
			phase, s.frames, s.sum / maxf(s.frames, 1), s.worst, s.over16, s.over33, s.over50, s.over100, s.over200])
	if _sights:
		for line: String in _sights.call(&"summary"):
			print(line)
	print("PROBE done (load %s)" % _load())
	get_tree().quit(code)
