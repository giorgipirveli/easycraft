extends Node
## The steps of tools/reel_render.gd (a Node, so it may use the autoloads and the Shorts' classes): films a Short frame
## by frame for the Movie Maker, saves moments as pictures, benches the live reels.

const FPS := 30.0
const BENCH_SIZES: Array[Vector2i] = [Vector2i(288, 512), Vector2i(432, 768)]
const CINEMATIC_DIR := "res://data/shorts/cinematic"

var player: ShortPlayer
var args := {}
var _frame := 0
var _length := 0.0
var _movie := false
var _out := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED   # pixel for pixel
	Scene3DModels.warm()   # the stages' maps and pictures, as the Theater opening makes them in the game
	Scene3DModels.sync_blocks = true   # round 2: the Movie Maker never films a blocks model still being meshed
	FlightLooks.settle()
	_out = ProjectSettings.globalize_path("user://reel_render")
	DirAccess.make_dir_recursive_absolute(_out)
	if args.has("bench"):
		_bench.call_deferred()
		return
	var id := str(args.get("short", ""))
	var s := ShortLibrary.get_short(id)
	if s.is_empty():
		print("RENDER no short %s" % id)
		get_tree().quit(1)
		return
	player = ShortPlayer.new()
	player.prefer_live = true
	player.plate_only = not args.has("full")
	player.voice_on = false
	player.hide_play_sign = true
	player.size = get_window().size
	add_child(player)
	player.build(s)
	_length = player.length()
	if args.has("movie"):
		_movie = true
		AudioServer.set_bus_mute(0, true)   # the video is pictures only: the Short plays its own sounds live
		player.seek(0.0)
		print("RENDER movie %s %.1f s %d frames at %s" % [id, _length, ceili(_length * FPS), get_window().size])
		return
	_frames.call_deferred(id)


## The Movie Maker draws a frame after every process step at a fixed 30 a second: frame n is the Short at n / 30.
func _process(_delta: float) -> void:
	if not _movie:
		return
	var t := _frame / FPS
	if t > _length + 0.001:
		print("RENDER done %d frames" % _frame)
		get_tree().quit()
		return
	player.seek(minf(t, _length))
	_frame += 1


func _frames(id: String) -> void:
	for at: String in str(args.get("frames", "0")).split(",", false):
		player.seek(clampf(float(at), 0.0, _length))
		for k in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/%s_%06.2f.png" % [_out, id, float(at)]
		get_viewport().get_texture().get_image().save_png(path)
		print("RENDER frame %s" % path)
	get_tree().quit()


# --- The bench: a live reel in a phone's player -------------------------------------------------------------------

func _bench() -> void:
	var ids: Array[String] = []
	if args.has("short"):
		ids.assign(str(args.short).split(",", false))
	else:
		for f in DirAccess.get_files_at(CINEMATIC_DIR):
			if f.ends_with(".json"):
				var s := ShortLibrary.get_short(f.get_basename())
				if not s.has("video"):
					ids.append(f.get_basename())
	var seconds := float(args.get("seconds", "0"))
	for id in ids:
		for px in BENCH_SIZES:
			await _bench_one(id, px, seconds)
	get_tree().quit()


func _bench_one(id: String, px: Vector2i, seconds: float) -> void:
	get_window().size = px
	var p := ShortPlayer.new()
	p.voice_on = false
	p.size = Vector2(px)
	add_child(p)
	p.build(ShortLibrary.get_short(id))
	var view := p.plate() as Scene3DView
	if view == null:
		print("BENCH %s has no live stage" % id)
		p.queue_free()
		return
	for k in 3:
		await get_tree().process_frame
	var rid := view.viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var length := p.length() if seconds <= 0.0 else minf(seconds, p.length())
	var gpu: Array[float] = []
	var cpu: Array[float] = []
	var pose: Array[float] = []
	var draws := 0
	var prims := 0
	var t := 0.0
	while t < length:
		var t0 := Time.get_ticks_usec()
		p.seek(t)
		pose.append((Time.get_ticks_usec() - t0) / 1000.0)
		await RenderingServer.frame_post_draw
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
		draws = maxi(draws, RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
		prims = maxi(prims, RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME))
		t += 1.0 / FPS
	print("BENCH %s %s pixels %s: stage GPU avg %.2f ms p95 %.2f max %.2f | render CPU avg %.2f | pose avg %.2f max %.2f ms | draws %d | primitives %d" % [
		id, px, view.pixels(), _avg(gpu), _pct(gpu, 0.95), _max(gpu), _avg(cpu), _avg(pose), _max(pose), draws, prims])
	p.queue_free()
	await get_tree().process_frame


static func _avg(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(a.size(), 1.0)


static func _max(a: Array[float]) -> float:
	var m := 0.0
	for v in a:
		m = maxf(m, v)
	return m


static func _pct(a: Array[float], q: float) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return s[mini(int(q * s.size()), s.size() - 1)]
