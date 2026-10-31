class_name GraphicsPreset
extends RefCounted
## Graphics settings per preset (Low / Medium / High), view distance limits and graphics styles.

const STYLES: Array[String] = ["blocky", "realistic"]   # pixel-art blocks, or CC0 photo textures
const MIN_VIEW_DISTANCE := 64
## Vertical streaming: the streamed box starts VIEW_BELOW blocks under the feet, the ground or the
## sea level, whichever is lowest, and reaches up from there. A player on the surface never streams
## (generates, meshes) the caves far below; a player in a cave still gets everything around them; a
## player flying high still sees the ground (found on the emulator: it vanished when only the feet
## counted); a player on a peak still sees the valleys and the sea (review I2).
const VIEW_BELOW := 24
const MIN_VERTICAL_HALF := 64
const MAX_VIEW_DISTANCE := 192
## M5 Task 3 (spec §15.3): LOW is for weak phones: a short view (view_max), no shadows, a smaller 3D resolution, half
## the particles (Fx.particle_scale), simpler water (one uniform of the shared water material), and fewer monsters
## (monsters_near: the night monsters near each child, MonsterDirector) and animals (animals_near, AnimalDirector);
## 0 there: no cap of the phone's own, the game's caps only.
const PRESETS := {
	"low": {"shadows": false, "shadow_distance": 0.0, "scale_3d": 0.75, "msaa": Viewport.MSAA_DISABLED,
		"view_max": 64, "particles": 0.5, "simple_water": true, "monsters_near": 6, "animals_near": 12, "sway": false},
	"medium": {"shadows": true, "shadow_distance": 40.0, "scale_3d": 1.0, "msaa": Viewport.MSAA_DISABLED,
		"view_max": MAX_VIEW_DISTANCE, "particles": 1.0, "simple_water": false, "monsters_near": 0, "animals_near": 0,
		"sway": false},
	"high": {"shadows": true, "shadow_distance": 80.0, "scale_3d": 1.0, "msaa": Viewport.MSAA_2X,
		"view_max": MAX_VIEW_DISTANCE, "particles": 1.0, "simple_water": false, "monsters_near": 0, "animals_near": 0,
		"sway": true},
	# Owner #101 (VR on the Meta Quest, the plan's ruling 2): the headset's, from LOW (Quest 2 is the floor: about 100
	# draws at 72 Hz, in stereo). Full resolution (OpenXR's render target sets the size; scale_3d under 1 moves
	# tonemapping into a later pass), MSAA 2x (a headset shows every jagged edge). VR's own keys: no glow (it turns
	# foveation off), the blocky style only (realistic waits for vr_plus on a Quest 3), the sky re-tinted every 2 s.
	# P5: the refresh rate it asks for, at most 16 particle bursts alive (Fx), and Voxel Tools' 16-cube terrain blocks
	# again (`mesh_block`): a 32-cube block had a third of the draws, but its collision shape is built on the main thread
	# in one go, a 30-50 ms frame on this desktop for every block streaming in (docs/devlog/parts/vr-perf.md).
	"vr": {"shadows": false, "shadow_distance": 0.0, "scale_3d": 1.0, "msaa": Viewport.MSAA_2X,
		"view_max": 64, "particles": 0.5, "simple_water": true, "monsters_near": 6, "animals_near": 8, "sway": false,
		"glow": false, "style": "blocky", "mesh_block": 16, "sky_interval": 2.0, "refresh": 72.0, "fx_live": 16},
	# P5 (owner #108: "i have quest 3"): what a Quest 3 / 3S adds (about 2.5x Quest 2's GPU; the research's defaults):
	# 90 Hz (stepped down once to the next rate when frames keep missing: watch_refresh), sun shadows to 24 m, MSAA 4x,
	# the child's own style (REALISTIC allowed; glow stays off: not stereo-safe), and an 80-block view (the research's 96
	# drew 213 a frame in Green Meadows with 16-cube blocks, over a Quest 3's 200; 80: 173). The rest as `vr` until the
	# headset's numbers say more (the notes: docs/devlog/parts/vr-perf.md).
	"vr_plus": {"shadows": true, "shadow_distance": 24.0, "scale_3d": 1.0, "msaa": Viewport.MSAA_4X,
		"view_max": 80, "particles": 0.5, "simple_water": true, "monsters_near": 6, "animals_near": 8, "sway": false,
		"glow": false, "style": "", "mesh_block": 16, "sky_interval": 2.0, "refresh": 90.0, "fx_live": 16},
}
## P5: the presets a headset's settings page offers, and a phone's (or a PC's).
const VR_CHOICES: Array[String] = ["vr", "vr_plus"]
const PHONE_CHOICES: Array[String] = ["low", "medium", "high"]
## P5: the headset's model (OS.get_model_name(): "Quest 2", "Quest 3", "Quest 3S" ...); "" reads it from the device
## (tests set one).
static var headset := ""
## P5, watch_refresh: a window of this many seconds whose frames average under HEADROOM of the rate asked for is a miss;
## MISSES of them in a row step the rate down once, to the next the headset offers (never under FLOOR_HZ). A window
## holding a frame over HITCH_SECONDS (a world loading, a first sight) counts neither way.
const HEADROOM_WINDOW := 5.0
const HEADROOM := 0.93
const HEADROOM_MISSES := 2
const HITCH_SECONDS := 0.1
const FLOOR_HZ := 72.0
## Owner #101: true while a headset session runs (Vr sets it). Every phone preset then reads as "vr": a phone's
## shadows and view would miss the headset's frame time, and a judder sickens a child. A VR preset stays itself.
static var vr_session := false
## Voxel Tools' own mesh block size, off VR.
const MESH_BLOCK := 16
## A phone with less memory than this, or with LOW_CORES cores or fewer, starts on LOW (M5 Task 3). A "3 GB" phone
## reports about 2.7-2.9 GiB, a "4 GB" one about 3.6-3.8 GiB.
const LOW_RAM_BYTES := 3584 * 1024 * 1024
const LOW_CORES := 4


static func params(preset: String) -> Dictionary:
	if vr_session:
		preset = vr_preset(preset)
	return PRESETS.get(preset, PRESETS["medium"])


## P5: the VR preset a headset session uses for the child's saved choice `chosen`: a VR one stays itself (a Quest 3
## child who picked VR keeps it), any other (a phone's, or none) is the headset's own pick (vr_for_model).
static func vr_preset(chosen: String = "") -> String:
	return chosen if VR_CHOICES.has(chosen) else vr_for_model(model())


## P5: `vr_plus` on a Quest 3 or 3S, `vr` on every other headset (the Quest 2 is the floor; the Quest Pro's XR2+ Gen 1
## is a Quest 2's GPU). Android's Build.MODEL ("Quest 3", "Quest 3S"; adb prints "Quest_3").
static func vr_for_model(name: String) -> String:
	return "vr_plus" if name.to_lower().replace("_", " ").contains("quest 3") else "vr"


## The headset's model: `headset`, or the device's own.
static func model() -> String:
	return headset if headset != "" else OS.get_model_name()


## The graphics style a world shows: the child's, or in a headset session the VR preset's (`vr`: blocky; `vr_plus`: the
## child's). `chosen`: the child's graphics preset ("" : the headset's own pick).
static func style_in_use(style: String, chosen: String = "") -> String:
	if not vr_session:
		return style
	var forced := str(params(chosen).get("style", ""))
	return forced if forced != "" else style


## REALISTIC's glow (WorldService.apply_style): never in a headset session (not stereo-safe; it also turns Godot 4.7's
## subsampled foveation off). Off VR as before.
static func glow_allowed(chosen: String) -> bool:
	return not vr_session or bool(params(chosen).get("glow", true))


## Seconds between the sky's re-tints: `usual` (SkyCycle's), longer in a headset session.
static func sky_interval(usual: float) -> float:
	return float(params(vr_preset()).sky_interval) if vr_session else usual


## VoxelTerrain.mesh_block_size for a new world. P5: a `backdrop` (the menu's: nothing walks there, its viewer builds no
## collisions) keeps BACKDROP_BLOCK in a headset, a third of the draws without the 32-cube blocks' collision stutter.
const BACKDROP_BLOCK := 32


static func mesh_block_size(backdrop: bool = false) -> int:
	if not vr_session:
		return MESH_BLOCK
	return BACKDROP_BLOCK if backdrop else int(params(vr_preset()).mesh_block)


## P5: the refresh rate a headset session asks for with the child's choice `chosen` (Vr._tune: the nearest the headset
## offers, nearest_rate).
static func refresh_rate(chosen: String) -> float:
	return float(PRESETS[vr_preset(chosen)].refresh)


## The rate in `offered` nearest `want` (`want` when nothing is offered: WebXR's list may be empty).
static func nearest_rate(want: float, offered: Array) -> float:
	if offered.is_empty():
		return want
	var best := float(offered[0])
	for r: Variant in offered:
		if absf(float(r) - want) < absf(best - want):
			best = float(r)
	return best


## P5: "90 Hz when there is headroom". Fed each frame's `delta` with the rate asked for now; returns the rate to ask
## for: the next lower one `offered` (FLOOR_HZ at the least) after HEADROOM_MISSES windows in a row whose frames ran
## under HEADROOM of `rate`, once per session (`w` is the caller's state, {} at the start; never back up: no see-saw).
static func watch_refresh(w: Dictionary, delta: float, rate: float, offered: Array) -> float:
	if w.get("stepped", false):
		return rate
	w.t = float(w.get("t", 0.0)) + delta
	w.frames = int(w.get("frames", 0)) + 1
	if delta > HITCH_SECONDS:
		w.hitch = true
	if w.t < HEADROOM_WINDOW:
		return rate
	var clean := not bool(w.get("hitch", false))
	var missed: bool = clean and float(w.frames) / float(w.t) < rate * HEADROOM
	w.t = 0.0
	w.frames = 0
	w.hitch = false
	if not clean:
		return rate   # a load: counts neither way
	w.misses = int(w.get("misses", 0)) + 1 if missed else 0
	if w.misses < HEADROOM_MISSES:
		return rate
	var lower := FLOOR_HZ
	for r: Variant in offered:
		if float(r) < rate - 0.5 and float(r) > lower:
			lower = float(r)
	w.stepped = true
	return lower if lower < rate else rate


## P5: the line that says what a session runs on, printed when it asks for a refresh rate (the lead reads it from logcat
## on the first headset run; tools/vr_bench.gd prints it too): the model, the VR preset, the rate asked and those offered.
static func device_line(headset_model: String, preset: String, refresh: float, offered: Array, renderer: String) -> String:
	var rates: Array[String] = []
	for r: Variant in offered:
		rates.append("%.0f" % float(r))
	return "VR_BENCH device model=%s preset=%s refresh_hz=%.0f offered=%s renderer=%s" % [
		headset_model.replace(" ", "_"), preset, refresh, ",".join(rates) if not rates.is_empty() else "none", renderer]


## P5: the presets the settings page offers: in a headset `vr` and `vr_plus`, else LOW, MEDIUM and HIGH.
static func choices(in_vr: bool) -> Array[String]:
	return VR_CHOICES if in_vr else PHONE_CHOICES


## A preset's button words ("VR PLUS").
static func label(preset: String) -> String:
	return preset.to_upper().replace("_", " ")


## P5: the preset a new profile starts on: `device_pick` (for_device's), or on the Quest APK (`platform`,
## PlatformRules) the headset's VR preset for `headset_model`. A browser can't tell which headset it runs in: its
## session reads the phone pick as the headset's own (vr_preset).
static func first_preset(device_pick: String, platform: Dictionary, headset_model: String) -> String:
	return vr_for_model(headset_model) if PlatformRules.starts_vr(platform) else device_pick


## The visuals brief: leaves and plants sway in the wind (BlockLibrary.set_sway) on HIGH (the cut-out shader it needs costs
## too much on a phone's Vulkan: docs/devlog/parts/visuals.md), never with Reduce motion.
static func sways(settings: Dictionary) -> bool:
	return bool(params(str(settings.get("graphics", "medium"))).get("sway", false)) \
		and not bool(settings.get("reduce_motion", false))


static func clamp_view_distance(distance: int) -> int:
	return clampi(distance, MIN_VIEW_DISTANCE, MAX_VIEW_DISTANCE)


## The view distance the game uses for `settings`: the child's slider, never more than the preset allows (LOW: 64).
static func view_distance(settings: Dictionary) -> int:
	var preset := params(str(settings.get("graphics", "medium")))
	return mini(clamp_view_distance(int(settings.get("view_distance", 128))), int(preset.view_max))


## The preset a phone starts on (its first start only): LOW with little memory or few cores, else MEDIUM (never HIGH
## by itself). ram_bytes <= 0 or cores <= 0: not known.
static func for_device(ram_bytes: int, cores: int) -> String:
	if ram_bytes > 0 and ram_bytes < LOW_RAM_BYTES:
		return "low"
	if cores > 0 and cores <= LOW_CORES:
		return "low"
	return "medium"


## Half the height of the streamed box for a view distance.
static func vertical_half(view_distance: int) -> float:
	return maxf(view_distance * 0.5, MIN_VERTICAL_HALF)


## VoxelViewer.view_distance_vertical_ratio for a view distance.
static func viewer_ratio(view_distance: int) -> float:
	return vertical_half(view_distance) / view_distance


## The streamed height range (bottom, top) for feet at feet_y above ground (or sea) at ground_y.
static func vertical_range(feet_y: float, ground_y: int, view_distance: int) -> Vector2:
	var bottom := minf(feet_y, mini(ground_y, MeadowsShape.SEA_LEVEL)) - VIEW_BELOW
	return Vector2(bottom, bottom + 2.0 * vertical_half(view_distance))


## The VoxelViewer's height: the middle of the streamed box.
static func viewer_y(feet_y: float, ground_y: int, view_distance: int) -> float:
	return vertical_range(feet_y, ground_y, view_distance).x + vertical_half(view_distance)
