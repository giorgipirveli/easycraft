extends Node
## The steps of tools/vr_hands_bench.gd (loaded at run time).

const SEED := 12345

var _seconds := 6.0
var _taps := false
var _tapped := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			_seconds = float(a.trim_prefix("--seconds="))
		elif a == "--taps":
			_taps = true
	# the Quest APK's platform, as tools/vr_bench_steps.gd plays it
	PlatformRules.simulated = PlatformRules.detect()
	for tag: String in [PlatformRules.MOBILE, PlatformRules.ANDROID, PlatformRules.QUEST]:
		PlatformRules.simulated[tag] = true
	RenderingServer.directional_shadow_atlas_set_size(
		int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size.mobile", 2048)), true)
	print("VR_HANDS_BENCH physics_thread=%s" % ProjectSettings.get_setting("physics/3d/run_on_separate_thread", false))
	_run()


func _run() -> void:
	await get_tree().process_frame
	Vr.preview(true)
	Game.new_world_seed = SEED
	var old := get_tree().current_scene
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	var until := Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		var sb := get_tree().current_scene
		if sb != null and sb != old and sb.get("player") is Player and (sb.get("player") as Player).is_spawned():
			break
	var sandbox := get_tree().current_scene
	var player: Player = sandbox.get("player") if sandbox else null
	if player == null or not player.is_spawned():
		print("VR_HANDS_BENCH timeout: the child never stood")
		get_tree().quit(1)
		return
	await _wait(5.0)
	var interactor := player.get_node("BlockInteractor") as BlockInteractor
	if _taps:
		print("VR_HANDS_BENCH old_way_tap (expect the engine's error with the physics thread):")
		interactor.place_crosshair()   # straight from _process: the way before follow-up (a)
	await _phase("play", interactor)
	Vr.set(&"_preview_pitch", -0.7)   # the head looks down at the hands (the table, the brick, the model at the feet)
	await _wait(1.0)
	await _phase("play_looking_down", interactor)
	Vr.open_build_table()
	var t := Vr.build_table
	for x in range(4, 10):   # a little house: walls two high, a door, a roof row
		for z in range(4, 10):
			if x == 4 or x == 9 or z == 4 or z == 9:
				for y in 2:
					if not (x == 6 and z == 9):
						t.cells[Vector3i(x, y, z)] = BlockIds.PLANKS
			t.cells[Vector3i(x, 2, z)] = BlockIds.RED
	t.rebuild()
	await _phase("table", interactor)
	Vr.close_build_table()
	Vr.bricks.call(&"_hold", VrRules.RIGHT, BlockIds.STONE)
	await _phase("brick", interactor)
	Vr.bricks.grip_cancel(VrRules.RIGHT)
	if Vr.toggle_model_view():
		await _wait(3.0)
		await _phase("model", interactor)
		Vr.toggle_model_view()
	else:
		print("VR_HANDS_BENCH model view did not open")
	await _wait(1.0)
	print("VR_HANDS_BENCH done taps=%d unreadable=%d" % [_tapped, interactor.unreadable_queries])
	get_tree().quit(0)


func _phase(name: String, interactor: BlockInteractor) -> void:
	var frames := 0
	var sum := 0
	var most := 0
	var sum3 := 0
	var sum2 := 0
	var t0 := Time.get_ticks_msec()
	var next_tap := t0 + 1000
	while Time.get_ticks_msec() - t0 < int(_seconds * 1000.0):
		await get_tree().process_frame
		var vps: Array = [get_tree().root]
		vps.append_array(get_tree().root.find_children("*", "SubViewport", true, false))
		var split := VrBench.draw_split(vps)
		var d := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		frames += 1
		sum += d
		most = maxi(most, d)
		sum3 += int(split.draws_3d)
		sum2 += int(split.draws_2d)
		if _taps and Time.get_ticks_msec() > next_tap:
			next_tap += 1000
			_tapped += 1
			interactor.in_space(interactor.place_crosshair)   # follow-up (a): in the physics step when it must
	var secs := maxf((Time.get_ticks_msec() - t0) / 1000.0, 0.001)
	print("VR_HANDS_BENCH phase=%s frames=%d fps=%.1f draws=%.1f most=%d draws_3d=%.1f draws_2d=%.1f" % [name, frames,
		frames / secs, float(sum) / maxi(frames, 1), most, float(sum3) / maxi(frames, 1), float(sum2) / maxi(frames, 1)])


func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
