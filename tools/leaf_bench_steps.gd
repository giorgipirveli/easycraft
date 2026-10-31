extends Node
## The steps of tools/leaf_bench.gd (a Node, so it may use the autoloads and the game's classes).

const UNIT := "g5.science.plants_air_water"

var _seconds := 5.0
var _host: LeafVoyageHost
var _layer: CanvasLayer


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			_seconds = float(a.trim_prefix("--seconds="))
	get_window().size = Vector2i(1280, 720)
	Profile.data.settings.reduce_motion = false
	await _build_times()
	await _open("5.1")
	await _measure("garden")
	_host.water_now()
	var built := Time.get_ticks_usec()
	_host.tap_target("leaf")   # the dive starts: the leaf's place and the dive are built now
	print("LEAF_BENCH build_at_the_dive_5.1 ms=%.1f" % ((Time.get_ticks_usec() - built) / 1000.0))
	_host.step(LeafJourney.DIVE_TIME * 0.4)
	await _measure("dive", 1.0)
	_host.step(LeafJourney.DIVE_TIME * 0.6 + LeafJourney.UNDER_TIME + LeafVoyageHost.GLIDE_MAX + 0.4)
	_host.place.show_all(false)
	_host.avatar.set_carried(LeafAvatar.MAX_CARRY)
	await _measure("inside_5.1_heaviest")
	_host.journey.run.phase = LeafRun.DONE
	_host.set_process(false)
	var t := 0.0
	while t < LeafJourney.RETURN_TIME + LeafJourney.ANSWER_GAP * 6.0:
		_host.step(0.1)
		t += 0.1
	_host.set_process(true)
	await _measure("end_card")
	await _close()
	await _open("5.T1")
	built = Time.get_ticks_usec()
	_host.tap_target("leaf")
	print("LEAF_BENCH build_at_the_dive_5.T1 ms=%.1f" % ((Time.get_ticks_usec() - built) / 1000.0))
	_host.set_process(false)
	t = 0.0
	while t < LeafJourney.DIVE_TIME + LeafJourney.UNDER_TIME + LeafVoyageHost.GLIDE_MAX + 0.4:
		_host.step(0.1)
		t += 0.1
	_host.set_process(true)
	_host.place.show_all(true)
	_host.avatar.set_carried(LeafAvatar.MAX_CARRY)
	await _measure("inside_5.T1_night_heaviest")
	await _close()
	get_tree().quit()


## How long each place takes to build at once (twice: the first pays for loading the scripts), and a staged place's
## and dive's steps one by one (the host builds them a step a frame in the garden): LEAF_BENCH build ... ms=<n>.
func _build_times() -> void:
	var stage := Node3D.new()
	add_child(stage)
	for i in 2:
		for what: String in ["garden", "dive", "place_sunflower", "place_cactus"]:
			var t := Time.get_ticks_usec()
			var n: Node3D
			match what:
				"garden":
					n = LeafGarden.new()
				"dive":
					n = LeafDive.new()
				"place_sunflower":
					n = LeafPlace.new("sunflower")
				"place_cactus":
					n = LeafPlace.new("cactus")
			stage.add_child(n)
			print("LEAF_BENCH build round=%d %s ms=%.1f" % [i, what, (Time.get_ticks_usec() - t) / 1000.0])
			n.free()
	for what: String in ["dive", "sunflower", "cactus"]:
		var n: Node3D = LeafDive.new() if what == "dive" else LeafPlace.new(what)
		n.set("staged", true)
		var t := Time.get_ticks_usec()
		stage.add_child(n)
		var steps := ["setup %.1f" % ((Time.get_ticks_usec() - t) / 1000.0)]
		var worst := 0.0
		var done := false
		while not done:
			t = Time.get_ticks_usec()
			done = bool(n.call("build_step"))
			var ms := (Time.get_ticks_usec() - t) / 1000.0
			worst = maxf(worst, ms)
			steps.append("%.1f" % ms)
		print("LEAF_BENCH build staged %s worst_ms=%.1f steps=%s" % [what, worst, " ".join(steps)])
		n.free()
	stage.queue_free()
	await get_tree().process_frame


func _open(voyage: String) -> void:
	_layer = CanvasLayer.new()
	add_child(_layer)
	var screen := Control.new()
	_layer.add_child(screen)
	_host = LeafVoyageHost.new()
	_host.progress_path = "user://leaf_bench_progress.json"
	_host.setup(UNIT, {"id": UNIT, "exercises": [], "play": {"game": "leaf_voyage", "params": {"voyage": voyage}}}, 7,
		0, {})
	var built := Time.get_ticks_usec()
	_host.open(screen)   # the garden and the HUD are built now
	print("LEAF_BENCH build_at_open_%s ms=%.1f" % [voyage, (Time.get_ticks_usec() - built) / 1000.0])
	for i in 10:
		await get_tree().process_frame


func _close() -> void:
	if not _host.closed:
		_host.close()
	_layer.queue_free()
	await get_tree().process_frame


## Lets the moment play `seconds` (after a second to settle), noting every frame's time and draw calls.
func _measure(moment: String, seconds: float = -1.0) -> void:
	var span := _seconds if seconds < 0.0 else seconds
	var settle := 0.0
	while settle < 1.0:
		await get_tree().process_frame
		settle += get_process_delta_time()
	var frames := 0
	var worst := 0.0
	var draws := 0
	var draws_max := 0
	var t := 0.0
	while t < span:
		await RenderingServer.frame_post_draw
		var dt := get_process_delta_time()
		var d := int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		frames += 1
		worst = maxf(worst, dt)
		draws += d
		draws_max = maxi(draws_max, d)
		t += dt
	print("LEAF_BENCH %s frames=%d fps=%.0f worst_ms=%.1f draws=%.0f draws_max=%d" % [moment, frames,
		frames / maxf(t, 0.001), worst * 1000.0, float(draws) / maxi(frames, 1), draws_max])
