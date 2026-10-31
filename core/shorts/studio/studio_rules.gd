class_name StudioRules
extends RefCounted
## The Reel Studio (owner #96: "we must keep reels high quality, implement visuals, video, animation tools and use them";
## spec §5.12b): the words of a 3D stage's data, in one place. A stage is a small lit 3D set with a moving camera that a
## Short shows either as its whole picture (a cinematic reel: the Short's `stage`, its times in the Short's seconds) or
## as one actor of a scene (`{"kind": "scene3d", "stage": {...}}`, its times in the scene's seconds):
##
##   {sky, light, sun?, models: [...], effects: [...], camera: [...]}
##
## - sky: a preset (SKIES) or {top, horizon, bottom?} colours, or keys [{at, sky, dur?}] that fade from one to the next
##   (a launch: day, then space). The stars show through a sky as it darkens.
## - light: a preset (LIGHTS: key, fill and rim lights, no shadows). sun: [x, y, z] toward the key light (and the
##   planets' day side), else the preset's.
## - A model: {id, model (MODELS), at: [x, y, z], turn?: [x, y, z] degrees, size?, moves: [...], and its kind's fields}.
## - A model's move: {do (MOVES), at (seconds), dur?, ease?, ...}: entrances (appear, pop, drop) hide it before them.
## - An effect: {kind (EFFECTS), on?: a model's id (it follows it), at?: [x, y, z] (from that model, or the world's
##   middle), from, to (seconds: it spawns between them), size?, color?}. Seekable: every particle is a function of time.
## - The camera: keys [{at, pos: [x, y, z], look: [x, y, z], fov?, ease?, path? ("line" | "orbit"), cut?, follow?: a
##   model's id (pos and look are then from it), aim?: a model's id (look is then from it: it stays in the middle),
##   shake?}]: dolly, orbit, crane and push-in are keys eased between.
## Round 2 (learning reels): a model may ride on another (`on`: a crate on a lever's plank, Earth on its tilted axis; it
## goes and turns with it, in its space), be stretched along its own axes (`stretch`: [x, y, z]; `grow` with an `axis`),
## be a `mark` (nothing drawn: a point a camera rides with or aims at), be a `rope` (a thin line from its `from` model to
## its `to` model, `width` m, of a `block`'s look, wherever they go; `from_at`, `to_at`: points in their frames); an
## avatar walks (`legs`: {dur, steps?, arms?: swing | pull | push | up, lean?: degrees back}); `light` and `sun` may be
## keys [{at, light | sun, dur?}] that fade (a sunset); a `blocks` model may be made of shapes (`fill`: StudioShapes).
## Metres, y up (a block is 1 m). Pure: StudioCamera, StudioMotion and StudioParticles do the moving, Scene3DKind the
## checking, ui/shorts/actors/scene3d_*.gd the drawing.

## Model kinds.
const MODELS: Array[String] = ["rocket", "planet", "sun", "rings", "ring_bits", "orbit_line", "ground", "blocks", "avatar", "clouds",
	"pad", "mark", "rope"]
## Built-in rockets (StudioRockets: the missions' real parts, as a child builds them).
const ROCKETS: Array[String] = ["moon", "lander", "mars"]
## Named block builds (StudioBuilds: the game's own structures).
const BUILDS: Array[String] = ["launch_tower", "colony", "venus_city", "wonder"]
## Model moves. Entrances (the model is hidden before the first): appear, pop, drop.
const MOVES: Array[String] = ["appear", "pop", "drop", "out", "move", "turn", "spin", "orbit", "grow", "stage", "emote",
	"legs"]
const ENTRANCES: Array[String] = ["appear", "pop", "drop"]
const DURATIONS := {"appear": 0.0, "pop": 0.5, "drop": 0.9, "out": 0.4, "move": 1.0, "turn": 1.0, "spin": 1.0,
	"grow": 0.6, "stage": 0.0, "emote": 0.0, "legs": 1.2}
const MOVE_EASES := {"pop": "back", "drop": "bounce", "out": "in", "move": "smooth", "turn": "smooth", "spin": "linear",
	"grow": "back", "legs": "smooth"}
## Effects (StudioParticles).
const EFFECTS: Array[String] = ["flame", "smoke", "dust", "billow", "sparkles", "steam", "snow", "rain", "lava"]
## Sky presets: [top, horizon, bottom] and how see-through the sky is (0: space, the stars show; 1: none).
const SKIES := {
	"day": [Color("3a7be8"), Color("bfe6ff"), Color("8fb86a"), 1.0],
	"launch": [Color("2f6fd8"), Color("cfeeff"), Color("9aa3ad"), 1.0],
	"dusk": [Color("27306a"), Color("f5a05a"), Color("3a2a3a"), 1.0],
	"space": [Color(0, 0, 0), Color(0.02, 0.03, 0.08), Color(0, 0, 0), 0.0],
	"venus": [Color("d9a441"), Color("fbe7a8"), Color("f0c46a"), 1.0],
	"mars": [Color("b8704a"), Color("f0c89a"), Color("8a4a2a"), 1.0],
	"studio": [Color("1b2240"), Color("3b4a7a"), Color("141a30"), 1.0],
	"moon": [Color(0, 0, 0), Color(0.01, 0.01, 0.02), Color(0, 0, 0), 0.0],
	"night": [Color("070b1f"), Color("1a2650"), Color("0a0d1c"), 0.25],
}
## Light presets: [key colour, key energy, fill colour, fill energy, rim colour, rim energy, ambient colour, ambient
## energy, sun direction (toward the key)]. No light casts a shadow (phones).
const LIGHTS := {
	"studio": [Color("fff1dc"), 1.15, Color("a9c4ff"), 0.4, Color("ffffff"), 0.9, Color("5a6a9a"), 0.45, Vector3(0.55, 0.7, 0.45)],
	"day": [Color("fff4e0"), 1.2, Color("bcd8ff"), 0.35, Color("ffffff"), 0.5, Color("9fb8d8"), 0.6, Vector3(0.45, 0.8, 0.4)],
	"space": [Color("fff8ee"), 1.5, Color("8fa8ff"), 0.12, Color("cfe0ff"), 0.6, Color("202838"), 0.35, Vector3(0.75, 0.35, 0.55)],
	"moon": [Color("ffffff"), 1.1, Color("8fa8ff"), 0.1, Color("cfe0ff"), 0.45, Color("2a3040"), 0.3, Vector3(0.7, 0.45, 0.5)],
	"dusk": [Color("ffb070"), 1.0, Color("6a7ad8"), 0.35, Color("ffd0a0"), 0.8, Color("4a3a5a"), 0.5, Vector3(0.8, 0.25, 0.4)],
	"venus": [Color("fff0c8"), 1.0, Color("ffe0a0"), 0.45, Color("ffffff"), 0.6, Color("c8a060"), 0.7, Vector3(0.3, 0.9, 0.3)],
	"orrery": [Color("fff4d8"), 0.0, Color("8fa8ff"), 0.0, Color("ffffff"), 0.0, Color("303848"), 0.5, Vector3(0.0, 1.0, 0.0)],
	# Round 2: a moonlit night on the ground (dim and bluish; the lamps glow on their own).
	"night": [Color("9fb4ff"), 0.32, Color("5a6ad0"), 0.18, Color("b8c6ff"), 0.35, Color("1c2448"), 0.42, Vector3(-0.4, 0.7, 0.35)],
}
const CAMERA_PATHS: Array[String] = ["line", "orbit"]
## The eases a stage may use: ShortTimeline's and "accel" (StudioMotion.ease: a steady push).
const EASES: Array[String] = ["linear", "smooth", "out", "in", "back", "bounce", "elastic", "accel"]
const EMOTES: Array[String] = ["wave", "cheer", "clap", "think", "hooray", "thumbs_up", "victory", "dance_hop", "bow",
	"yawn", "stretch", "look", "laugh"]
## A walk's arms (StudioMotion.walk_pose): swinging, reaching forward to pull a rope, pushing ahead, held up.
const ARMS: Array[String] = ["swing", "pull", "push", "up"]
const AXES: Array[String] = ["x", "y", "z"]
## How many models deep a rider may sit on riders.
const MAX_RIDE := 6
## The avatar's looks: an outfit from AvatarCatalog (its own colours), or the child's first look.
const LOOKS: Array[String] = ["astronaut", "explorer", "default"]
const GROUNDS: Array[String] = ["moon", "mars", "grass", "sand", "concrete"]

## Limits (a phone draws a stage live: few things; a rendered reel may have more).
const MAX_MODELS := 24
const MAX_EFFECTS := 8
const MAX_KEYS := 24
const MAX_MODEL_MOVES := 16
const MAX_SIZE := 20000.0
const REACH := 20000.0          # every point of a stage inside this cube (metres)
const FOV := Vector2(10.0, 100.0)
const DEFAULT_FOV := 50.0
const FAR := 60000.0
## The sky's dome and the stars round the camera (metres).
const SKY_RADIUS := 20000.0
const STAR_RADIUS := 26000.0
const STAR_COUNT := 500
const STAR_SEED := 20261001

## How a stage is drawn: LIVE on a phone's screen (its pixels, a little antialiasing), RENDER for a video (Movie Maker:
## more antialiasing and the glow of flames and suns).
const LIVE := &"live"
const RENDER := &"render"
## The live stage's pixels at most (a phone's 9:16 player is ~288-432 wide) and the rendered video's sizes.
const LIVE_MAX := Vector2i(540, 960)
const RENDER_SIZES: Array[Vector2i] = [Vector2i(540, 960), Vector2i(720, 1280)]


## [x, y, z] as a Vector3 (Vector3.ZERO for anything else).
static func vec(v: Variant) -> Vector3:
	if is_vec(v):
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3.ZERO


static func is_vec(v: Variant) -> bool:
	if not v is Array or (v as Array).size() != 3:
		return false
	for k in 3:
		if typeof(v[k]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v[k])):
			return false
	return true


## A number field (default when missing or not a number).
static func num(d: Dictionary, key: String, default: float) -> float:
	var v: Variant = d.get(key, default)
	return float(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) else default


## A sky as its colours: {top, horizon, bottom, opacity}; a preset's name or a {top, horizon, bottom?, opacity?}.
static func sky_colours(sky: Variant) -> Dictionary:
	if sky is String and SKIES.has(sky):
		var p: Array = SKIES[sky]
		return {"top": p[0], "horizon": p[1], "bottom": p[2], "opacity": float(p[3])}
	if sky is Dictionary:
		var d: Dictionary = sky
		var top := ShortRules.colour(d.get("top"), Color.BLACK)
		var horizon := ShortRules.colour(d.get("horizon"), top)
		return {"top": top, "horizon": horizon, "bottom": ShortRules.colour(d.get("bottom"), horizon),
			"opacity": clampf(num(d, "opacity", 1.0), 0.0, 1.0)}
	return sky_colours("space")


## The sky at time `t`: a stage's `sky` (one sky, or keys fading from one to the next).
static func sky_at(sky: Variant, t: float) -> Dictionary:
	if not sky is Array:
		return sky_colours(sky)
	var keys: Array = sky
	if keys.is_empty():
		return sky_colours("space")
	var now := sky_colours((keys[0] as Dictionary).get("sky") if keys[0] is Dictionary else "space")
	for k: Variant in keys:
		if not k is Dictionary:
			continue
		var at := num(k, "at", 0.0)
		if t < at:
			break
		var next := sky_colours(k.get("sky"))
		var dur := num(k, "dur", 0.0)
		var p := 1.0 if dur <= 0.0 else clampf((t - at) / dur, 0.0, 1.0)
		var e := ShortTimeline.ease_value("smooth", p)
		now = {"top": (now.top as Color).lerp(next.top, e), "horizon": (now.horizon as Color).lerp(next.horizon, e),
			"bottom": (now.bottom as Color).lerp(next.bottom, e), "opacity": lerpf(now.opacity, next.opacity, e)}
	return now


## A light preset as a dictionary (studio's for anything unknown).
static func light(preset: Variant) -> Dictionary:
	var p: Array = LIGHTS.get(str(preset), LIGHTS.studio)
	return {"key": p[0], "key_energy": p[1], "fill": p[2], "fill_energy": p[3], "rim": p[4], "rim_energy": p[5],
		"ambient": p[6], "ambient_energy": p[7], "sun": p[8]}


## Toward the key light (the planets' day side) at the start: the stage's `sun`, else its light preset's.
static func sun_dir(stage: Dictionary) -> Vector3:
	return light_at(stage, 0.0).sun


## The stage's light at `t`: its preset, or its light keys fading from one preset to the next (a sunset), with `sun`
## (toward the key light, normalised) from its sun keys, else its one `sun`, else the preset's.
static func light_at(stage: Dictionary, t: float) -> Dictionary:
	var spec: Variant = stage.get("light", "studio")
	var out := light(spec)
	if spec is Array:
		out = light(_first_key(spec, "light"))
		for k: Variant in spec:
			if not k is Dictionary:
				continue
			var at := num(k, "at", 0.0)
			if t < at:
				break
			var e := _key_ease(k, t)
			var next := light(k.get("light"))
			for key: String in out:
				if out[key] is Color:
					out[key] = (out[key] as Color).lerp(next[key], e)
				elif out[key] is Vector3:
					out[key] = (out[key] as Vector3).lerp(next[key], e)
				else:
					out[key] = lerpf(float(out[key]), float(next[key]), e)
	var sun: Variant = stage.get("sun")
	if is_vec(sun):
		out.sun = vec(sun)
	elif sun is Array and not (sun as Array).is_empty():
		var d := vec(_first_key(sun, "sun"))
		for k: Variant in sun:
			if not k is Dictionary:
				continue
			if t < num(k, "at", 0.0):
				break
			d = d.lerp(vec(k.get("sun")), _key_ease(k, t))
		out.sun = d
	var dir: Vector3 = out.sun
	out.sun = dir.normalized() if dir.length() > 0.001 else Vector3.UP
	return out


## True when the stage's light changes over time (keys): the view sets its lights every pose then.
static func light_moves(stage: Dictionary) -> bool:
	return stage.get("light") is Array or stage.get("sun") is Array


static func _first_key(keys: Array, field: String) -> Variant:
	for k: Variant in keys:
		if k is Dictionary:
			return (k as Dictionary).get(field)
	return null


## How far a key's fade has come at `t` (smooth; at once without a dur).
static func _key_ease(k: Dictionary, t: float) -> float:
	var dur := num(k, "dur", 0.0)
	var p := 1.0 if dur <= 0.0 else clampf((t - num(k, "at", 0.0)) / dur, 0.0, 1.0)
	return ShortTimeline.ease_value("smooth", p)


## The model with id `id` in `stage` ({} for none).
static func model(stage: Dictionary, id: String) -> Dictionary:
	var list: Variant = stage.get("models", [])
	if list is Array:
		for m: Variant in list:
			if m is Dictionary and str((m as Dictionary).get("id", "")) == id:
				return m
	return {}


## How long a stage runs: its last camera key, move, sky key or effect's end (at least `least`).
static func length(stage: Dictionary, least: float = 0.0) -> float:
	var out := least
	for key: Variant in stage.get("camera", []):
		if key is Dictionary:
			out = maxf(out, num(key, "at", 0.0))
	for m: Variant in stage.get("models", []):
		if m is Dictionary:
			for mv: Variant in (m as Dictionary).get("moves", []):
				if mv is Dictionary:
					out = maxf(out, num(mv, "at", 0.0) + num(mv, "dur", float(DURATIONS.get(str(mv.get("do", "")), 0.0))))
	for e: Variant in stage.get("effects", []):
		if e is Dictionary:
			out = maxf(out, num(e, "to", 0.0))
	return out
