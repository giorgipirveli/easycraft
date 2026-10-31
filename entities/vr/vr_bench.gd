class_name VrBench
extends Node
## Owner #101 (VR on the Meta Quest, the research's budget: 72 Hz is a 13.9 ms frame; P1's acceptance: at least 72 FPS on
## average, no frame over 28 ms after 5 s, at most 150 draws): one VR_BENCH line every `every` seconds while a headset
## session runs (the lead reads them with `adb logcat -s godot:V | grep VR_BENCH`), and in the desktop preview
## (tools/vr_bench.gd). Each line: the frames per second, the worst frame and how many took over two refreshes (28 ms),
## the draws, primitives and objects of the last frame, the main thread's process and physics times, and the GPU's.
## Owner #110 (VR P5's follow-up b): the VR preset by name (vr, vr_plus) and the draws split: draws_3d (every viewport's
## 3D and shadow draws: the scene, Meta's budget) and draws_2d (the canvases': the HUD's tray is drawn every frame).

const OVER_MS := 28.0
const PREFIX := "VR_BENCH"

var every := 10.0
## Lines printed (tests), and the last one's numbers.
var lines := 0
var last := {}

var _t := 0.0
var _frames := 0
var _worst := 0.0
var _over := 0
var _vp: RID


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)


func _process(delta: float) -> void:
	sample(delta)


## Starts counting again, a line every `seconds` from now (tools/vr_bench.gd: after the world's load).
func restart(seconds: float) -> void:
	every = seconds
	_t = 0.0
	_frames = 0
	_worst = 0.0
	_over = 0


## One frame of `delta` seconds; a line once `every` seconds have gone.
func sample(delta: float) -> void:
	_t += delta
	_frames += 1
	var ms := delta * 1000.0
	_worst = maxf(_worst, ms)
	if ms > OVER_MS:
		_over += 1
	if _t < every:
		return
	last = {
		"fps": _frames / _t, "worst_ms": _worst, "over": _over,
		"draws": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(_vp),
	}
	last.merge(draw_split(_viewports()))
	print(line(last, {"world": Game.universe, "preset": preset_name(Profile.data.settings),
		"renderer": RenderingServer.get_current_rendering_method()}))
	lines += 1
	_t = 0.0
	_frames = 0
	_worst = 0.0
	_over = 0


## The line for numbers `n` and context `ctx` (world, preset, renderer); a split not measured prints -1.
static func line(n: Dictionary, ctx: Dictionary) -> String:
	return "%s world=%s vr_preset=%s renderer=%s fps=%.1f worst_ms=%.1f over28=%d draws=%d draws_3d=%d draws_2d=%d primitives=%d objects=%d process_ms=%.2f physics_ms=%.2f gpu_ms=%.2f" % [
		PREFIX, ctx.get("world", "?"), ctx.get("preset", "?"), ctx.get("renderer", "?"), float(n.fps),
		float(n.worst_ms), int(n.over), int(n.draws), int(n.get("draws_3d", -1)), int(n.get("draws_2d", -1)),
		int(n.primitives), int(n.objects), float(n.process_ms), float(n.physics_ms), float(n.gpu_ms)]


## The preset in use by name: in a real session the headset's VR preset (GraphicsPreset.vr_preset: a phone preset reads
## as vr or vr_plus), else the child's own.
static func preset_name(settings: Dictionary) -> String:
	var chosen := str(settings.get("graphics", "medium"))
	return GraphicsPreset.vr_preset(chosen) if GraphicsPreset.vr_session else chosen


## The last frame's draws of `viewports`, split: {draws_3d (the 3D and shadow passes), draws_2d (the canvases)}; a freed
## viewport is skipped (tools/vr_bench_steps.gd's draw_split: three render-info reads each).
static func draw_split(viewports: Array) -> Dictionary:
	var d3 := 0
	var d2 := 0
	for v: Variant in viewports:
		if not is_instance_valid(v) or not v is Viewport:
			continue
		var rid := (v as Viewport).get_viewport_rid()
		d3 += RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		d3 += RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		d2 += RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	return {"draws_3d": d3, "draws_2d": d2}


## The root and every SubViewport (the VR canvas, a mirror, a photo camera), once a line.
func _viewports() -> Array:
	var out: Array = [get_tree().root]
	out.append_array(get_tree().root.find_children("*", "SubViewport", true, false))
	return out
