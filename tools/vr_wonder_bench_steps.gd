extends Node
## The steps of tools/vr_wonder_bench.gd (loaded at run time).

const SEED := 12345

var _seconds := 6.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			_seconds = float(a.trim_prefix("--seconds="))
	# the Quest APK's platform, as tools/vr_bench_steps.gd plays it
	PlatformRules.simulated = PlatformRules.detect()
	for tag: String in [PlatformRules.MOBILE, PlatformRules.ANDROID, PlatformRules.QUEST]:
		PlatformRules.simulated[tag] = true
	RenderingServer.directional_shadow_atlas_set_size(
		int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size.mobile", 2048)), true)
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
		print("VR_WONDER_BENCH timeout: the child never stood")
		get_tree().quit(1)
		return
	await _wait(5.0)
	var interactor := player.get_node("BlockInteractor") as BlockInteractor
	await _phase("play")
	Vr.set(&"_preview_pitch", -0.7)   # the head looks down (the orrery, the bench, the hands)
	await _wait(1.0)
	await _phase("play_looking_down")
	# idea 1: the Star Map with the orrery under the eye panel
	var space := sandbox.get("space") as SpaceDirector
	space.open_picker()
	await _wait(1.0)
	var map := space.panel
	if map.vr_orrery == null:
		print("VR_WONDER_BENCH the orrery did not open")
	await _phase("orrery")
	map.true_size_button.pressed.emit()
	await _wait(1.0)
	await _phase("orrery_true_size")
	map.true_size_button.pressed.emit()
	await _wait(1.0)
	var jupiter := map.vr_orrery.body_grabbable(&"jupiter")
	Vr.grabber.give(VrRules.LEFT, jupiter)
	await _wait(1.0)
	await _phase("orrery_planet_in_hand")
	Vr.grabber.take_back(jupiter)
	space.close_picker()
	await _wait(1.0)
	# idea 2: the telescope at 8x, the magnifier
	Vr.set(&"_preview_pitch", 0.0)
	interactor.hotbar[1] = ItemIds.TELESCOPE
	interactor.hotbar[2] = ItemIds.MAGNIFIER
	interactor.select_slot(1)
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	await _wait(1.0)
	await _phase("telescope_8x")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	interactor.select_slot(2)
	Vr.set(&"_preview_pitch", -0.7)
	await _wait(1.0)
	await _phase("magnifier")
	var lens := Vr.grabber.get_node_or_null(^"VrLens") as VrLens
	print("VR_WONDER_BENCH magnifier closeup=%s" % (lens.closeup_shown() if lens else &"?"))
	interactor.select_slot(0)
	await _wait(1.0)
	# idea 4: the Lab bench with float or sink
	sandbox.call(&"open_lab")
	var lab := sandbox.get("lab_panel") as LabPanel
	lab.screen.open("float_sink")
	await _wait(1.0)
	if lab.vr_bench == null:
		print("VR_WONDER_BENCH the bench did not open")
	await _phase("lab_bench")
	lab.close()
	await _wait(1.0)
	await _phase("play_after")
	print("VR_WONDER_BENCH done")
	get_tree().quit(0)


func _phase(name: String) -> void:
	var frames := 0
	var sum := 0
	var most := 0
	var sum3 := 0
	var sum2 := 0
	var lens_sum := 0
	var t0 := Time.get_ticks_msec()
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
		var lens := Vr.grabber.get_node_or_null(^"VrLens") as VrLens if Vr.grabber != null else null
		if lens != null:
			lens_sum += int(VrBench.draw_split([lens.viewport]).draws_3d)
	var secs := maxf((Time.get_ticks_msec() - t0) / 1000.0, 0.001)
	print("VR_WONDER_BENCH phase=%s frames=%d fps=%.1f draws=%.1f most=%d draws_3d=%.1f draws_2d=%.1f lens=%.1f" % [name,
		frames, frames / secs, float(sum) / maxi(frames, 1), most, float(sum3) / maxi(frames, 1), float(sum2) / maxi(frames, 1),
		float(lens_sum) / maxi(frames, 1)])


func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
