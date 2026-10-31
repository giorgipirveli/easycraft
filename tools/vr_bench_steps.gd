extends Node
## tools/vr_bench.gd's steps (a separate file: a SceneTree script compiles before the autoloads exist).
## P5 (owner #101, #108): any world (--world=<n>), the Launch Site (--at=launch), a FLY cruise (--cruise=<seconds>), the
## draws' sources (--blame), the device line (the model, the preset, the refresh rate) and the main thread's own CPU.

const SEED := 12345
## --blame: a part of the scene whose hiding drops at least this many draws is looked into, its children one by one.
const BLAME_DEEPER := 6
const BLAME_DEPTH := 4
## --blame: frames waited after hiding or showing a part, then frames averaged.
const BLAME_SETTLE := 3
const BLAME_FRAMES := 4

var _seconds := 20.0
var _turns := 4
## --flat: the same run without the rig (the phone's camera; a comparison).
var _flat := false
var _world := 1
var _at := ""
var _cruise := 0.0
## --walk=<seconds>: then walking ahead on the ground (new terrain streaming in at a child's pace), turning at a hill.
var _walk := 0.0
var _blame := false
## --shot=<folder>: after the standing window, the VR canvas (the HUD's tray) and the head's view as PNGs there.
var _shot := ""
var _time := -1.0
## --long: every frame over VrBench.OVER_MS in a measured window, with what it spent its time on (tools/frame_blame.gd)
## and the main thread's own CPU in it (a long frame with little CPU waited: for the GPU, a shader, or this busy PC).
var _long := false
## --menu: the main menu in the headset (its eye panel and the backdrop's hill) instead of a world.
var _menu := false
var _blamer: Node
var _phase := ""
var _phase_t0 := 0
var _sched := PackedInt64Array([0, 0])
## The preview plays the Quest APK's platform (PlatformRules: no touch HUD, the phone's 1280 × 720 canvas, no keys card):
## the HUD the headset draws. --desktop-ui keeps this PC's.
var _quest := true
var _bench: VrBench


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			_seconds = float(a.trim_prefix("--seconds="))
		elif a.begins_with("--turns="):
			_turns = int(a.trim_prefix("--turns="))
		elif a == "--flat":
			_flat = true
		elif a.begins_with("--world="):
			_world = int(a.trim_prefix("--world="))
		elif a.begins_with("--at="):
			_at = a.trim_prefix("--at=")
		elif a.begins_with("--cruise="):
			_cruise = float(a.trim_prefix("--cruise="))
		elif a.begins_with("--walk="):
			_walk = float(a.trim_prefix("--walk="))
		elif a.begins_with("--shot="):
			_shot = a.trim_prefix("--shot=")
		elif a == "--blame":
			_blame = true
		elif a.begins_with("--time="):
			_time = float(a.trim_prefix("--time="))
		elif a == "--desktop-ui":
			_quest = false
		elif a == "--long":
			_long = true
		elif a == "--menu":
			_menu = true
		elif a.begins_with("--voxel-threads="):   # a Quest's pool: 4 of its 8 cores (Voxel Tools' ratio 0.5), 3 of 6
			VoxelEngine.set_thread_count(int(a.trim_prefix("--voxel-threads=")))
	if _flat:
		_quest = false
	if _quest:
		PlatformRules.simulated = PlatformRules.detect()
		for tag: String in [PlatformRules.MOBILE, PlatformRules.ANDROID, PlatformRules.QUEST]:
			PlatformRules.simulated[tag] = true
		# Godot's own `.mobile` defaults the Quest APK gets (an Android is "mobile"): the sun's shadow map 2048, hard
		# shadow edges (the desktop's 4096 and soft filter cost vr_plus 10 ms more on this iGPU).
		RenderingServer.directional_shadow_atlas_set_size(
			int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size.mobile", 2048)), true)
		RenderingServer.directional_soft_shadow_filter_set_quality(int(ProjectSettings.get_setting(
			"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile", 0)))
	if _long:
		_blamer = load("res://tools/frame_blame.gd").new()
		_blamer.threshold_ms = int(VrBench.OVER_MS)
		_blamer.window.connect(_on_long_window)
		get_tree().root.add_child.call_deferred(_blamer)
	_run()


func _on_long_window(ms: float) -> void:
	var now := _schedstat()
	if _phase != "" and ms > VrBench.OVER_MS:
		var line := "VR_BENCH long %.0f ms in %s at +%.1f s [main thread: cpu %.1f ms, runqueue %.1f ms] voxel_tasks=%d" % [
			ms, _phase, (Time.get_ticks_msec() - _phase_t0) / 1000.0, (now[0] - _sched[0]) / 1e6, (now[1] - _sched[1]) / 1e6,
			WorldService.voxel_tasks()]
		line += " terrain=%s" % _terrain_stats()
		var d: String = _blamer.describe()
		if d != "":
			line += "\n    " + d
		print(line)
	_sched = now


## The world's VoxelTerrain.get_statistics(), its non-zero numbers (the terrain's own main-thread work in a long frame).
func _terrain_stats() -> String:
	var sb := get_tree().current_scene
	var w: WorldService = sb.get("world") if sb != null else null
	if w == null or w.terrain() == null:
		return "-"
	var parts: Array[String] = []
	var st: Dictionary = w.terrain().get_statistics()
	for k: String in st:
		if (st[k] is int or st[k] is float) and float(st[k]) != 0.0:
			parts.append("%s:%s" % [k, st[k]])
	return ",".join(parts)


func _schedstat() -> PackedInt64Array:
	var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
	if f == null:
		return PackedInt64Array([0, 0])
	var parts := f.get_line().split(" ")
	return PackedInt64Array([int(parts[0]), int(parts[1])])


func _run() -> void:
	await get_tree().process_frame
	if not _flat:
		Vr.preview(true)
	if _menu:
		await _menu_run()
		return
	Game.new_world_seed = SEED
	var old := get_tree().current_scene
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, _world)
	var until := Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		var sb := get_tree().current_scene
		if sb != null and sb != old and sb.get("player") is Player and (sb.get("player") as Player).is_spawned():
			break
	var sandbox := get_tree().current_scene
	var player: Player = sandbox.get("player") if sandbox else null
	if player == null or not player.is_spawned():
		print("VR_BENCH timeout: the child never stood")
		get_tree().quit(1)
		return
	if _time >= 0.0 and sandbox.get("sky") is SkyCycle:
		(sandbox.get("sky") as SkyCycle).set_time(_time)
	if _at == "launch" and not await _to_launch_site(sandbox, player):
		get_tree().quit(1)
		return
	await _wait(5.0)
	print("%s world=%d run=%s" % [GraphicsPreset.device_line(GraphicsPreset.model(), _preset_in_use(), _refresh_rate(), [],
		RenderingServer.get_current_rendering_method()), Game.universe, "flat" if _flat else ("preview_quest" if _quest else "preview")])
	_bench = Vr.bench
	if _flat:
		_bench = VrBench.new()
		add_child(_bench)
	var stand := await _window("stand", player, _seconds, _turns)
	if _shot != "":
		await _shots(_shot)
	if _blame:
		await _blame_draws(sandbox)
	if _walk > 0.0:
		Input.action_press("move_forward")
		var from := player.global_position
		var walk_end := Time.get_ticks_msec() + int(_walk * 1000.0)
		var walker := func() -> void:   # a coroutine beside the window: its copies of the locals live through its loop
			var stuck_check := Time.get_ticks_msec() + 1500
			var last := player.global_position
			while Time.get_ticks_msec() < walk_end:
				await get_tree().process_frame
				if Time.get_ticks_msec() > stuck_check:   # against a hill: turn like a child would, and hop
					stuck_check = Time.get_ticks_msec() + 1500
					if player.global_position.distance_to(last) < 1.0:
						if _flat:
							player.rig.yaw += PI * 0.5
						else:
							Vr.turn(PI * 0.5)
						Input.action_press("jump")
					else:
						Input.action_release("jump")
					last = player.global_position
		walker.call()
		await _window("walk", player, _walk, 0)
		Input.action_release("move_forward")
		Input.action_release("jump")
		print("VR_BENCH walked %.0f m" % Vector2(player.global_position.x - from.x, player.global_position.z - from.z).length())
	if _cruise > 0.0:
		player.set_physics_mode(PhysicsMode.Mode.FLY)
		Input.action_press("jump")
		await _wait(2.5)   # up above the hills
		Input.action_release("jump")
		Input.action_press("move_forward")
		var from := player.global_position
		await _window("cruise", player, _cruise, 0)
		Input.action_release("move_forward")
		print("VR_BENCH cruised %.0f m" % Vector2(player.global_position.x - from.x, player.global_position.z - from.z).length())
	get_tree().quit(0 if not stand.is_empty() else 1)


## --menu: the main menu (its backdrop world and the eye panel with the menu's screen), measured like a world.
func _menu_run() -> void:
	get_tree().change_scene_to_file(Game.MENU_SCENE)
	await _wait(12.0)   # the backdrop's terrain and the panel
	print("%s world=menu run=%s" % [GraphicsPreset.device_line(GraphicsPreset.model(), _preset_in_use(), _refresh_rate(),
		[], RenderingServer.get_current_rendering_method()), "flat" if _flat else "preview_quest"])
	_bench = Vr.bench
	if _flat:
		_bench = VrBench.new()
		add_child(_bench)
	var s := await _window("menu", null, _seconds, 0)
	if _blame:
		await _blame_draws(get_tree().current_scene)
	get_tree().quit(0 if not s.is_empty() else 1)


## One measured window of `seconds` (`turns` snap turns of 90° through it): VR_BENCH lines a second and a summary.
func _window(phase: String, player: Player, seconds: float, turns: int) -> Dictionary:
	_bench.restart(1.0)
	_phase = phase
	_phase_t0 = Time.get_ticks_msec()
	var sums := {"fps": 0.0, "draws": 0.0, "primitives": 0.0, "objects": 0.0, "process_ms": 0.0, "physics_ms": 0.0,
		"gpu_ms": 0.0}
	var most := {"draws": 0, "primitives": 0, "objects": 0}
	var worst := 0.0
	var over := 0
	var n := 0
	var turn_every := seconds / maxf(float(turns), 1.0)
	var next_turn := turn_every
	var t0 := Time.get_ticks_msec()
	var cpu0 := main_thread_cpu_ms()
	var frames := 0
	var split := {"draws_3d": 0.0, "draws_2d": 0.0}
	var split_most := {"draws_3d": 0, "draws_2d": 0}
	var seen := _bench.lines
	var vps := _viewports()   # found again each second (a search of the whole tree every frame would cost a frame's time)
	while (Time.get_ticks_msec() - t0) / 1000.0 < seconds:
		await get_tree().process_frame
		frames += 1
		var now := draw_split(vps)
		for k: String in split:
			split[k] += now[k]
			split_most[k] = maxi(int(split_most[k]), int(now[k]))
		var t := (Time.get_ticks_msec() - t0) / 1000.0
		if turns > 0 and t >= next_turn:
			next_turn += turn_every
			if _flat:
				player.rig.yaw += PI * 0.5
			else:
				Vr.turn(PI * 0.5)
		if _bench.lines != seen:
			seen = _bench.lines
			vps = _viewports()
			var l := _bench.last
			n += 1
			for k: String in sums:
				sums[k] += float(l[k])
			for k: String in most:
				most[k] = maxi(int(most[k]), int(l[k]))
			worst = maxf(worst, float(l.worst_ms))
			over += int(l.over)
	_phase = ""
	if n == 0:
		return {}
	var out := {"phase": phase, "world": Game.universe, "flat": _flat, "seconds": int(seconds), "lines": n,
		"fps": sums.fps / n, "draws": sums.draws / n, "most_draws": most.draws, "primitives": sums.primitives / n,
		"most_primitives": most.primitives, "objects": sums.objects / n, "worst_ms": worst, "over28": over,
		"process_ms": sums.process_ms / n, "physics_ms": sums.physics_ms / n, "gpu_ms": sums.gpu_ms / n,
		"cpu_ms": (main_thread_cpu_ms() - cpu0) / maxf(frames, 1.0),
		"draws_3d": split.draws_3d / maxf(frames, 1.0), "most_3d": split_most.draws_3d,
		"draws_2d": split.draws_2d / maxf(frames, 1.0), "most_2d": split_most.draws_2d}
	print(summary_line(out))
	return out


## --shot: the VR canvas and the head's view, a frame after they were drawn.
func _shots(folder: String) -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	await _frames(3)
	var canvas := Vr.ui_viewport()
	var images := {"vr_canvas": canvas.get_texture().get_image() if canvas != null else null,
		"view": get_viewport().get_texture().get_image()}
	for k: String in images:
		if images[k] != null:   # headless draws nothing
			(images[k] as Image).save_png(folder.path_join("%s_w%d.png" % [k, Game.universe]))
	print("VR_BENCH shots in %s" % folder)


static func summary_line(s: Dictionary) -> String:
	return ("VR_BENCH summary phase=%s world=%d flat=%s seconds=%d lines=%d fps=%.1f draws=%.0f most_draws=%d "
		+ "primitives=%.0f most_primitives=%d objects=%.0f worst_ms=%.1f over28=%d process_ms=%.2f physics_ms=%.2f "
		+ "gpu_ms=%.2f cpu_ms=%.2f draws_3d=%.0f most_3d=%d draws_2d=%.0f most_2d=%d") % [s.phase, s.world, s.flat,
		s.seconds, s.lines, s.fps, s.draws, s.most_draws, s.primitives, s.most_primitives, s.objects, s.worst_ms, s.over28,
		s.process_ms, s.physics_ms, s.gpu_ms, s.cpu_ms, s.draws_3d, s.most_3d, s.draws_2d, s.most_2d]


## This frame's draws split: the 3D views' (every viewport's scene and shadow draws) and the 2D canvases' (the VR
## canvas with the HUD, the root's): Meta's draw budget is the scene's; a canvas's draws are small 2D batches.
static func draw_split(viewports: Array[Viewport]) -> Dictionary:
	var d3 := 0
	var d2 := 0
	for v: Variant in viewports:
		if not is_instance_valid(v):
			continue   # a SubViewport freed since the list was made
		var rid := (v as Viewport).get_viewport_rid()
		d3 += RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		d3 += RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		d2 += RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	return {"draws_3d": d3, "draws_2d": d2}


## The main thread's own CPU time so far (ms; Linux /proc: what the frames cost whatever else the PC runs), 0 elsewhere.
static func main_thread_cpu_ms() -> float:
	var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
	if f == null:
		return 0.0
	return float(f.get_line().get_slice(" ", 0)) / 1000000.0


## The preset in use: the VR one in a session (GraphicsPreset.vr_preset), else the child's.
func _preset_in_use() -> String:
	var chosen := str(Profile.data.settings.get("graphics", "medium"))
	return GraphicsPreset.vr_preset(chosen) if GraphicsPreset.vr_session else chosen


func _refresh_rate() -> float:
	return DisplayServer.screen_get_refresh_rate()


## --at=launch: the child stands beside the Launch Site's board once the site is placed and built.
func _to_launch_site(sandbox: Node, player: Player) -> bool:
	var site: LaunchDirector = sandbox.get("launch_site")
	var until := Time.get_ticks_msec() + 60000
	while (site == null or site.site.is_empty() or site.buildings == null) and Time.get_ticks_msec() < until:
		await get_tree().process_frame
		site = sandbox.get("launch_site")
	if site == null or site.site.is_empty():
		print("VR_BENCH no launch site")
		return false
	var at := LaunchSite.board_position(site.site) + Vector3(0.0, 0.05, 6.0)   # the turns look at the tower and the pad
	player.spawn_at(at)
	print("VR_BENCH at launch site %s" % at)
	return true


# --- --blame: where the draws come from ---

## Each viewport's own draws (3D, shadows, 2D), then the main view's 3D draws with each part of the scene hidden in turn
## (what the hiding saves is that part's), looking into every part worth BLAME_DEEPER draws or more.
func _blame_draws(sandbox: Node) -> void:
	await _frames(BLAME_SETTLE)
	for vp: Viewport in _viewports():
		var rid := vp.get_viewport_rid()
		print("VR_BENCH viewport path=%s draws_3d=%d shadow=%d canvas=%d objects=%d primitives=%d" % [
			get_tree().root.get_path_to(vp), _info(rid, 0, 2), _info(rid, 1, 2), _info(rid, 2, 2), _info(rid, 0, 0),
			_info(rid, 0, 1)])
	var base := await _draws(get_viewport(), 0)
	print("VR_BENCH blame base draws_3d=%.1f" % base)
	var roots: Array[Node] = [sandbox, Vr]
	for r: Node in roots:
		await _blame_in(r, base, 0, get_viewport(), 0)
	var canvas := Vr.ui_viewport()
	if canvas != null:
		var base_2d := await _draws(canvas, 2)
		print("VR_BENCH blame base canvas=%.1f (%s)" % [base_2d, get_tree().root.get_path_to(canvas)])
		await _blame_in(canvas, base_2d, 0, canvas, 2)


## Hides each child of `node` in turn and prints what `vp`'s draws of `type` (0: 3D, 2: the 2D canvas) drop by.
func _blame_in(node: Node, base: float, depth: int, vp: Viewport, type: int) -> void:
	for c: Node in node.get_children():
		if not _shown(c):
			continue
		_show(c, false)
		var without := await _draws(vp, type)
		_show(c, true)
		var saved := base - without
		if saved >= 1.0:
			var kinds := _kinds(c) if type == 0 else _controls(c)
			print("VR_BENCH blame %s depth=%d part=%s class=%s draws=%.1f %s" % ["3d" if type == 0 else "canvas", depth,
				get_tree().root.get_path_to(c),
				c.get_class() if c.get_script() == null else str((c.get_script() as Script).get_global_name()), saved,
				kinds])
		if saved >= BLAME_DEEPER and depth < BLAME_DEPTH and c.get_child_count() > 0:
			await _blame_in(c, base, depth + 1, vp, type)
	await _frames(BLAME_SETTLE)


func _shown(n: Node) -> bool:
	if n is Node3D:
		return (n as Node3D).visible
	if n is CanvasItem:
		return (n as CanvasItem).visible
	if n is CanvasLayer:
		return (n as CanvasLayer).visible
	return false


func _show(n: Node, on: bool) -> void:
	n.set("visible", on)


## How many visible Controls a part of the canvas has, and how many of them draw text.
func _controls(n: Node) -> String:
	var all := 0
	var text := 0
	for c: Node in n.find_children("*", "Control", true, false):
		if (c as Control).is_visible_in_tree():
			all += 1
			if c is Label or c is Button or c is RichTextLabel:
				text += 1
	return "controls=%d with_text=%d" % [all, text]


## What a part holds that draws: GeometryInstance3D kinds and their count (visible ones), e.g. "Label3D=12 Mesh=3".
func _kinds(n: Node) -> String:
	var counts := {}
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false) + ([n] if n is GeometryInstance3D else []):
		if not (g as Node3D).is_visible_in_tree():
			continue
		var k := g.get_class().trim_suffix("Instance3D")
		counts[k] = int(counts.get(k, 0)) + 1
	var parts: Array[String] = []
	for k: String in counts:
		parts.append("%s=%d" % [k, counts[k]])
	return " ".join(parts)


## `vp`'s draws of `type` (0: 3D, 2: canvas), the mean of a few frames after a short settle.
func _draws(vp: Viewport, type: int) -> float:
	await _frames(BLAME_SETTLE)
	var rid := vp.get_viewport_rid()
	var sum := 0.0
	for i in BLAME_FRAMES:
		await get_tree().process_frame
		sum += _info(rid, type, 2)
	return sum / BLAME_FRAMES


func _info(rid: RID, type: int, what: int) -> int:
	return RenderingServer.viewport_get_render_info(rid, type, what)


func _viewports() -> Array[Viewport]:
	var out: Array[Viewport] = [get_tree().root]
	for v: Node in get_tree().root.find_children("*", "SubViewport", true, false):
		out.append(v as Viewport)
	return out


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
