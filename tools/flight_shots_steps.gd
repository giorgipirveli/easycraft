extends Node
## The steps of tools/flight_shots.gd: a new Sandbox world, then the test flight (or landing), pictures at its big
## moments and each phase's frame times.

const SEED := 12345
const SHOT_SIZE := Vector2i(640, 360)
const LIMIT := 420.0
## Seconds the child stands in the new world before the flight starts (the world's own first work is not the flight's).
const SETTLE := 6.0

## [phase, progress, view (&"" the story's), name]
const SHOTS := [
	[&"countdown", 0.75, &"", "cockpit_on_the_pad"],
	[&"countdown", 0.95, &"chase", "engines_lit"],
	[&"liftoff", 0.6, &"", "lift_off"],
	[&"ascent", 0.2, &"", "climbing_inside"],
	[&"ascent", 0.18, &"chase", "climbing_outside"],
	[&"ascent", 0.3, &"", "clouds"],
	[&"ascent", 0.75, &"", "earth_curve_inside"],
	[&"staging", 0.45, &"", "stage_falls"],
	[&"orbit", 0.3, &"", "orbit_earth_below"],
	[&"orbit", 0.8, &"", "leaving_earth"],
	[&"jump", 0.3, &"", "light_speed_lines"],
	[&"jump", 0.75, &"", "light_speed_rush"],
	[&"asteroids", 0.5, &"", "asteroids"],
	[&"asteroids", 0.6, &"inside", "asteroids"],
	[&"warp", 0.5, &"", "warp_tunnel"],
	[&"wormhole", 0.22, &"", "wormhole_mouth"],
	[&"wormhole", 0.6, &"", "wormhole_tunnel"],
	[&"nebula", 0.5, &"", "nebula"],
	[&"nebula", 0.6, &"chase", "nebula"],
	[&"cruise", 0.5, &"", "cruise_inside"],
	[&"cruise", 0.6, &"chase", "earth_behind"],
	[&"cruise", 0.95, &"", "destination_ahead"],
	[&"arrive", 0.7, &"", "orbit_destination"],
	[&"deorbit", 0.5, &"", "coming_down"],
	[&"deorbit", 0.6, &"inside", "coming_down_inside"],
	[&"entry", 0.5, &"", "fiery_entry"],
	[&"chute", 0.6, &"", "parachute"],
	[&"landing", 0.35, &"", "ground_rising"],
	[&"landing", 0.8, &"", "touching_down"],
	[&"landing", 0.7, &"inside", "pad_below_inside"],
	[&"landed", 0.2, &"", "touchdown"],
]

var _dest := SpaceRules.MOON
var _landing := false
var _shots := true
var _out := ""
var _t := 0.0
var _next := 0
var _frames := {}   # phase -> {n, sum, worst, o33, o50, o100}
var _phase: StringName = &""
var _hold := 0.0
var _pending_view: StringName = &""
var _landed := false
var _started := false
var _stood := 0.0
var _asked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var style := "blocky"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dest="):
			_dest = int(a.get_slice("=", 1))
		elif a == "--landing":
			_landing = true
		elif a == "--no-shots":
			_shots = false
		elif a.begins_with("--style="):
			style = a.get_slice("=", 1)
	_shots = _shots and DisplayServer.get_name() != "headless"
	Profile.data.settings.style = style
	Profile.data.settings.keys_seen = true   # the KEYS card (a PC's first world) would cover the pictures
	Game.mode = ModeRules.SANDBOX
	Game.universe = 1
	Game.start_new_world = true
	Game.new_world_seed = SEED
	_out = OS.get_environment("XDG_DATA_HOME").path_join("flight_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	print("FLIGHT_SHOTS dest=%d landing=%s style=%s shots=%s load=%s" % [_dest, _landing, style, _shots,
		Performance.get_monitor(Performance.TIME_PROCESS)])
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > LIMIT:
		print("FLIGHT_SHOTS timeout")
		_report()
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null:
		return
	var f: Variant = sandbox.get("flight")
	if not _asked:
		var pl: Variant = sandbox.get("player")
		if pl == null or not (pl as Player).is_spawned():
			return
		_stood += delta
		if _stood < SETTLE:
			return
		_asked = true
		var t0 := Time.get_ticks_usec()
		var why: String = sandbox.call("land_on_space", _dest) if _landing \
			else sandbox.call("fly_rocket", RocketStages.test_rocket(_dest, 2))
		print("FLIGHT_SHOTS started %s in %.1f ms" % [why if why != "" else "ok", (Time.get_ticks_usec() - t0) / 1000.0])
		return
	if f == null or not is_instance_valid(f):
		if _started:   # the flight ended: the space world loads
			if not _landed:
				_landed = true
				print("FLIGHT_SHOTS landed; world loading")
			var p: Variant = sandbox.get("player")
			if Game.universe == _dest and p != null and (p as Player).is_spawned():
				_hold += delta
				if _hold > 2.0:
					_shot("arrived_by_the_lander")
					_report()
					get_tree().quit(0)
		return
	var flight: Node3D = f
	if not _started:
		_started = true
		flight.set("auto_tick", false)   # the flight is ticked here, its own cost timed
	var run: FlightRun = flight.get("run")
	if run == null:
		return
	var phase := run.phase()
	if phase != _phase:
		_phase = phase
	_play_child(flight, run)
	var t0 := Time.get_ticks_usec()
	flight.call("tick", delta)
	_count(String(phase), delta, (Time.get_ticks_usec() - t0) / 1000.0)
	if not is_instance_valid(flight) or not flight.call("is_active"):
		return
	if not _shots:
		return
	while _next < SHOTS.size():
		var s: Array = SHOTS[_next]
		var order := _order(run, s[0])
		if order == -1 or order == 1:   # this trip has none of that phase, or it has passed
			_next += 1
			continue
		if order == 2 or run.progress() < float(s[1]):
			break
		if true:
			if s[2] != &"" and _pending_view == &"":
				_pending_view = s[2]
				flight.set("view", s[2])
				_hold = 0.0
				return
			if _pending_view != &"":
				_hold += delta
				if _hold < 0.8:
					return
			_shot(str(s[3]) + ("_" + String(_pending_view) if _pending_view != &"" else ""))
			if _pending_view != &"":
				flight.set("view", &"")
				_pending_view = &""
			_next += 1
		break


## 0: the shot's phase is now; 1: it has passed; 2: it is still to come; -1: this trip has none of it.
func _order(run: FlightRun, phase: StringName) -> int:
	var first := -1
	var last := -1
	for i in run.steps.size():
		if run.steps[i].phase == phase:
			last = i
			if first == -1:
				first = i
	if first == -1:
		return -1
	if run.phase() == phase:
		return 0
	return 1 if run.index > last else 2


func _play_child(flight: Node3D, run: FlightRun) -> void:
	var cockpit: FlightCockpit = flight.get("cockpit")
	if cockpit == null:
		return
	var waiting := run.waiting_for()
	if waiting in [FlightPlan.THROTTLE, FlightPlan.BURN, FlightPlan.DESCEND]:   # owner #106: the descent flown well
		cockpit.lever.held = true
		cockpit.lever.value = run.test_throttle()
	else:
		cockpit.lever.held = false
	if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
		cockpit.action_pressed.emit()


func _count(phase: String, delta: float, tick_ms: float) -> void:
	if not _frames.has(phase):
		_frames[phase] = {"n": 0, "sum": 0.0, "worst": 0.0, "o33": 0, "o50": 0, "o100": 0, "tick": 0.0, "tick_worst": 0.0}
	var d: Dictionary = _frames[phase]
	var ms := delta * 1000.0
	d.n += 1
	d.sum += ms
	d.worst = maxf(d.worst, ms)
	d.tick += tick_ms
	d.tick_worst = maxf(d.tick_worst, tick_ms)
	d.o33 += int(ms > 33.3)
	d.o50 += int(ms > 50.0)
	d.o100 += int(ms > 100.0)


func _report() -> void:
	for phase: String in _frames:
		var d: Dictionary = _frames[phase]
		if d.n == 0:
			continue
		print(("FLIGHT_FRAMES phase=%s frames=%d avg_ms=%.1f worst_ms=%.1f over33=%d over50=%d over100=%d "
			+ "flight_tick_avg_ms=%.2f flight_tick_worst_ms=%.2f") % [phase, d.n, d.sum / d.n, d.worst, d.o33, d.o50, d.o100,
			d.tick / d.n, d.tick_worst])


func _shot(name: String) -> void:
	if not _shots:
		return
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	img.resize(SHOT_SIZE.x, SHOT_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var path := _out.path_join("%02d_%s.jpg" % [_next, name])
	img.save_jpg(path, 0.82)
	print("FLIGHT_SHOT %s %s" % [name, path])
