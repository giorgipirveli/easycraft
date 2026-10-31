extends Node
## The steps of tools/life_bench.gd (owner #94): its header says what it measures and how to run it.

const TIMEOUT := 300.0
const SETTLE := 8.0
const WINDOWS: Array[String] = ["day-on", "day-off", "night-on", "night-off"]

var window := 15.0
var _t := 0.0
var _step := -1
var _step_t := 0.0
var _frames := 0
var _cpu_at := 0.0
var _frames_at := 0
var _proc_ms := 0.0
var _life_us := 0
var _showed := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.new_world_seed = 20260925
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-seed="):
			Game.new_world_seed = int(a.trim_prefix("--smoke-seed="))
		elif a.begins_with("--window="):
			window = float(a.trim_prefix("--window="))
		elif a.begins_with("--voxel-threads="):   # a phone's share of cores (frame_probe's advice: 2)
			VoxelEngine.set_thread_count(int(a.trim_prefix("--voxel-threads=")))
	Game.mode = ModeRules.SANDBOX
	Game.universe = 1
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("LIFE_BENCH begin seed=%d window=%.0f load=%s" % [Game.new_world_seed, window, _load()])

func _sandbox() -> Node:
	var s := get_tree().current_scene
	if s == null or s.get("player") == null or not (s.player as Player).is_spawned():
		return null
	return s

func _life(s: Node) -> AmbientLife:
	return s.get_node_or_null(^"AmbientLife") as AmbientLife

func _process(delta: float) -> void:
	_t += delta
	_frames += 1
	if _t > TIMEOUT:
		print("LIFE_BENCH timeout at step %d" % _step)
		_finish(1)
		return
	var s := _sandbox()
	if s == null:
		return
	var life := _life(s)
	if life == null:   # it comes with the HUD (Sandbox._universe_hud), after the loading card
		if _t > TIMEOUT * 0.5:
			print("LIFE_BENCH no AmbientLife in this world (was --no-ambient-life given?)")
			_finish(1)
		return
	_step_t += delta
	if _step < 0:
		if _step_t >= SETTLE:
			_begin(s, life, 0)
		return
	_proc_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	if WINDOWS[_step].ends_with("-on"):
		var t0 := Time.get_ticks_usec()
		life.tick(delta)
		_life_us += Time.get_ticks_usec() - t0
		if life.fireflies.emitting:
			_showed["fireflies"] = true
		if life.birds.visible:
			_showed["birds"] = true
	if _step_t >= window:
		_report()
		if _step + 1 < WINDOWS.size():
			_begin(s, life, _step + 1)
		else:
			_finish(0)

## A window: the clock (noon or midnight) and the life on (stepped here) or off (as if it were not there).
func _begin(s: Node, life: AmbientLife, step: int) -> void:
	_step = step
	_step_t = 0.0
	var which := WINDOWS[step]
	s.call("set_time_of_day", DayCycle.NOON if which.begins_with("day") else 0.95)
	var on := which.ends_with("-on")
	life.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	life.visible = on
	life.set_process(false)   # the "on" windows step it here, timed
	if not on:
		life.fireflies.set_on(false)
		life.birds.set_on(false)
	_cpu_at = _cpu_ms()
	_frames_at = _frames
	_proc_ms = 0.0
	_life_us = 0
	_showed = {}

func _report() -> void:
	var frames := maxi(_frames - _frames_at, 1)
	print("LIFE_BENCH window=%s main_thread_cpu_ms_per_frame=%.3f process_ms_per_frame=%.3f life_tick_us=%.1f frames=%d fireflies=%s birds=%s load=%s" % [
		WINDOWS[_step], (_cpu_ms() - _cpu_at) / frames, _proc_ms / frames, float(_life_us) / frames, frames,
		_showed.has("fireflies"), _showed.has("birds"), _load()])

func _finish(code: int) -> void:
	print("LIFE_BENCH done")
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(code))

## The main thread's user + system CPU time so far, in ms (0 where /proc is missing).
func _cpu_ms() -> float:
	var f := FileAccess.open("/proc/thread-self/stat", FileAccess.READ)
	if f == null:
		return 0.0
	var fields := f.get_line().get_slice(")", 1).split(" ", false)
	return (int(fields[11]) + int(fields[12])) * 10.0

func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"
