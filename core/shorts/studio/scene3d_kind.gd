class_name Scene3DKind
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): the check of a 3D stage (StudioRules' format) and of the `scene3d` actor
## that shows one in a scene: "" when it can be drawn. The Short-level stage of a cinematic reel is checked by the same
## stage_problem (ShortCheck). The style guide in 3D: a camera move lasts at least ShortStyle.MOVE_MIN (a cut is a new
## shot, any time) and never glides at a constant speed (but round an orbit); a model's move lasts MOVE_MIN too.

const BOX := Vector2(60.0, 60.0)      # a scene3d actor's box on the stage: at least ...
const BOX_MAX := ShortRules.STAGE     # ... and at most the whole stage
const MAX_BUILD_GROUPS := 16
const MAX_CELLS := 400


## "" when `actor` ({kind: scene3d, at, w?, h?, stage}) is right.
static func problem(actor: Dictionary) -> String:
	if not actor.get("stage") is Dictionary:
		return "a scene3d actor has a stage {sky, light, models, effects, camera}"
	for key: String in ["w", "h"]:
		if actor.has(key):
			var v: Variant = actor[key]
			var most := BOX_MAX.x if key == "w" else BOX_MAX.y
			if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or float(v) < BOX.x or float(v) > most:
				return "a scene3d's %s is %d-%d" % [key, int(BOX.x), int(most)]
	return stage_problem(actor.stage)


## "" when `stage` can be drawn; `length` (seconds, when known): its moves, effects and keys must fit in it.
static func stage_problem(stage: Variant, length: float = -1.0) -> String:
	if not stage is Dictionary:
		return "a stage is a dictionary"
	var s: Dictionary = stage
	var why := _sky_problem(s.get("sky", "space"))
	if why != "":
		return why
	if s.has("light"):
		why = _keys_problem(s.light, "light", func(v: Variant) -> bool: return StudioRules.LIGHTS.has(str(v)),
			"one of %s" % ", ".join(StudioRules.LIGHTS.keys()))
		if why != "":
			return why
	if s.has("sun"):
		why = _keys_problem(s.sun, "sun", func(v: Variant) -> bool:
			return StudioRules.is_vec(v) and StudioRules.vec(v).length() >= 0.001, "a direction [x, y, z]")
		if why != "":
			return why
	var models: Variant = s.get("models", [])
	if not models is Array or (models as Array).size() > StudioRules.MAX_MODELS:
		return "at most %d models" % StudioRules.MAX_MODELS
	var ids := {}
	for m: Variant in models:
		why = _model_problem(m, ids, length)
		if why != "":
			return why
	why = _ride_problem(s, ids)
	if why != "":
		return why
	var effects: Variant = s.get("effects", [])
	if not effects is Array or (effects as Array).size() > StudioRules.MAX_EFFECTS:
		return "at most %d effects" % StudioRules.MAX_EFFECTS
	for e: Variant in effects:
		why = _effect_problem(e, ids, length)
		if why != "":
			return why
	return _camera_problem(s.get("camera"), ids, length)


## Round 2: `light` and `sun` are one value or keys [{at, <field>, dur?}] (a sunset); `good(v)` says a value is right.
static func _keys_problem(v: Variant, field: String, good: Callable, what: String) -> String:
	if good.call(v):   # one value (a sun is an array of three numbers itself)
		return ""
	if not v is Array or StudioRules.is_vec(v):
		return "" if good.call(v) else "%s is %s, or keys [{at, %s, dur?}]" % [field, what, field]
	if (v as Array).is_empty():
		return "%s's keys are [{at, %s, dur?}, ...]" % [field, field]
	for k: Variant in v:
		if not k is Dictionary or typeof(k.get("at")) not in [TYPE_INT, TYPE_FLOAT] or float(k.at) < 0.0:
			return "a %s key is {at, %s, dur?}" % [field, field]
		if k.has("dur") and (typeof(k.dur) not in [TYPE_INT, TYPE_FLOAT] or float(k.dur) < 0.0):
			return "a %s key's dur is 0 or more" % field
		if not good.call(k.get(field)):
			return "a %s key's %s is %s" % [field, field, what]
	return ""


## Round 2: every rider (`on`) rides on another model of the stage, never on itself or round in a ring.
static func _ride_problem(s: Dictionary, ids: Dictionary) -> String:
	for m: Variant in s.get("models", []):
		if m is Dictionary and str(m.get("model", "")) == "rope":
			for end: String in ["from", "to"]:
				if not ids.has(str(m.get(end, ""))) or str(m.get(end, "")) == str(m.get("id", "")):
					return "model '%s': a rope's %s is another model's id, not '%s'" % [m.get("id"), end, m.get(end)]
		if not m is Dictionary or not (m as Dictionary).has("on"):
			continue
		var id := str(m.get("id", ""))
		var on := str(m.on)
		if not ids.has(on) or on == id:
			return "model '%s': on is another model's id, not '%s'" % [id, on]
		var seen := {id: true}
		var up := StudioRules.model(s, on)
		while up.has("on"):
			var next := str(up.on)
			if seen.has(next) or seen.size() > StudioRules.MAX_RIDE:
				return "model '%s': riders go round in a ring (or more than %d deep)" % [id, StudioRules.MAX_RIDE]
			seen[next] = true
			up = StudioRules.model(s, next)
	return ""


static func _sky_problem(sky: Variant) -> String:
	if sky is Array:
		if (sky as Array).is_empty():
			return "a sky's keys are [{at, sky, dur?}, ...]"
		for k: Variant in sky:
			if not k is Dictionary or typeof(k.get("at")) not in [TYPE_INT, TYPE_FLOAT] or float(k.at) < 0.0:
				return "a sky key is {at, sky, dur?}"
			if k.has("dur") and (typeof(k.dur) not in [TYPE_INT, TYPE_FLOAT] or float(k.dur) < 0.0):
				return "a sky key's dur is 0 or more"
			var why := _sky_problem(k.get("sky"))
			if why != "":
				return why
		return ""
	if sky is String:
		return "" if StudioRules.SKIES.has(sky) else "unknown sky '%s' (%s)" % [sky, ", ".join(StudioRules.SKIES.keys())]
	if sky is Dictionary:
		for key: String in ["top", "horizon", "bottom"]:
			if sky.has(key) and not ShortRules.is_colour(sky[key]):
				return "a sky's %s is a colour" % key
		return "" if sky.has("top") else "a sky has a top colour"
	return "a sky is a name, {top, horizon, bottom} or keys"


static func _in_reach(v: Variant) -> bool:
	if not StudioRules.is_vec(v):
		return false
	var p := StudioRules.vec(v)
	return absf(p.x) <= StudioRules.REACH and absf(p.y) <= StudioRules.REACH and absf(p.z) <= StudioRules.REACH


static func _model_problem(m: Variant, ids: Dictionary, length: float) -> String:
	if not m is Dictionary:
		return "a model is a dictionary"
	var d: Dictionary = m
	var id := str(d.get("id", ""))
	var kind := str(d.get("model", ""))
	var where := "model '%s'" % id
	if id == "" or ids.has(id):
		return "%s: every model has an id of its own" % where
	ids[id] = kind
	if not StudioRules.MODELS.has(kind):
		return "%s: unknown model kind '%s' (%s)" % [where, kind, ", ".join(StudioRules.MODELS)]
	if not _in_reach(d.get("at")):
		return "%s: at is [x, y, z] within %d m" % [where, int(StudioRules.REACH)]
	if d.has("turn") and not StudioRules.is_vec(d.turn):
		return "%s: turn is [x, y, z] degrees" % where
	if d.has("size") and (typeof(d.size) not in [TYPE_INT, TYPE_FLOAT] or float(d.size) <= 0.0
			or float(d.size) > StudioRules.MAX_SIZE):
		return "%s: size is above 0, at most %d" % [where, int(StudioRules.MAX_SIZE)]
	if d.has("color") and not ShortRules.is_colour(d.color):
		return "%s: color is a colour" % where
	if d.has("stretch"):
		var st := StudioRules.vec(d.stretch)
		if not StudioRules.is_vec(d.stretch) or minf(st.x, minf(st.y, st.z)) <= 0.0 \
				or maxf(st.x, maxf(st.y, st.z)) > StudioRules.MAX_SIZE:
			return "%s: stretch is [x, y, z], each above 0" % where
	if d.has("on") and not d.on is String:
		return "%s: on is a model's id" % where
	var why := _kind_fields(kind, d)
	if why != "":
		return "%s: %s" % [where, why]
	var moves: Variant = d.get("moves", [])
	if not moves is Array or (moves as Array).size() > StudioRules.MAX_MODEL_MOVES:
		return "%s: at most %d moves" % [where, StudioRules.MAX_MODEL_MOVES]
	for mv: Variant in moves:
		why = _move_problem(mv, kind, length)
		if why != "":
			return "%s: %s" % [where, why]
	return ""


static func _kind_fields(kind: String, d: Dictionary) -> String:
	match kind:
		"rocket":
			if not StudioRules.ROCKETS.has(str(d.get("rocket", ""))):
				return "rocket is one of %s" % ", ".join(StudioRules.ROCKETS)
			if d.has("build"):
				if not d.build is Array or (d.build as Array).size() > MAX_BUILD_GROUPS:
					return "build is at most %d groups {blocks, at}" % MAX_BUILD_GROUPS
				for g: Variant in d.build:
					if not g is Dictionary or not g.get("blocks") is Array or typeof(g.get("at")) not in [TYPE_INT, TYPE_FLOAT]:
						return "a build group is {blocks: [block names], at, stage?}"
					if g.has("stage") and (typeof(g.stage) not in [TYPE_INT, TYPE_FLOAT] or int(g.stage) < 0):
						return "a build group's stage is a stage's number (0: the bottom one)"
					for b: Variant in g.blocks:
						if ShortCheck.block_id(b) < 0:
							return "unknown block %s" % b
		"planet":
			var body := StarMap.body(StringName(str(d.get("body", ""))))
			if body.is_empty() or not str(body.get("kind", "")) in ["planet", "moon", "dwarf"]:
				return "body is a planet, moon or dwarf planet of the Star Map, not '%s'" % d.get("body")
			if d.has("night") and (typeof(d.night) not in [TYPE_INT, TYPE_FLOAT] or float(d.night) < 0.0 or float(d.night) > 1.0):
				return "a planet's night (how bright its night side is) is 0-1"
		"ring_bits":
			if StudioRules.num(d, "inner", 1.6) >= StudioRules.num(d, "outer", 2.2) or StudioRules.num(d, "inner", 1.6) <= 0.0:
				return "ring bits go from inner to outer (radii), inner first"
			if StudioRules.num(d, "count", 800.0) < 1.0 or StudioRules.num(d, "count", 800.0) > 3000.0:
				return "ring bits are 1-3000 pieces"
			if d.has("arc") and (not d.arc is Array or (d.arc as Array).size() != 2):
				return "an arc is [from, to] degrees"
		"rings", "orbit_line":
			if kind == "orbit_line" and (typeof(d.get("radius")) not in [TYPE_INT, TYPE_FLOAT] or float(d.radius) <= 0.0):
				return "an orbit line has a radius"
		"ground":
			if d.has("look") and not StudioRules.GROUNDS.has(str(d.look)):
				return "a ground's look is one of %s" % ", ".join(StudioRules.GROUNDS)
		"blocks":
			if d.has("build"):
				if not StudioRules.BUILDS.has(str(d.build)):
					return "build is one of %s" % ", ".join(StudioRules.BUILDS)
				if str(d.build) == "wonder" and not WonderTour.has(StringName(str(d.get("wonder", "")))):
					return "a wonder is one of the tour's (%s)" % ", ".join(WonderTour.ids())
			elif d.get("cells") is Array or d.get("fill") is Array:
				return _cells_problem(d)
			else:
				return "blocks have a build, cells or a fill of shapes"
		"avatar":
			if d.has("look") and not StudioRules.LOOKS.has(str(d.look)):
				return "an avatar's look is one of %s" % ", ".join(StudioRules.LOOKS)
		"rope":   # round 2: its ends are models (checked once every model is known: _ride_problem)
			if not d.get("from") is String or not d.get("to") is String:
				return "a rope runs from a model to a model (from, to: ids)"
			if d.has("width") and (StudioRules.num(d, "width", 0.0) <= 0.0 or StudioRules.num(d, "width", 0.0) > 2.0):
				return "a rope's width is above 0, at most 2 m"
			if d.has("block") and ShortCheck.block_id(d.block) < 0:
				return "a rope's block is a block's name"
			for end: String in ["from_at", "to_at"]:
				if d.has(end) and not _in_reach(d[end]):
					return "a rope's %s is a point [x, y, z] in its model's frame" % end
	return ""


## A `blocks` model's own cells and shapes (StudioShapes): known blocks (AIR carves), at most so many, in a box a phone
## meshes quickly.
static func _cells_problem(d: Dictionary) -> String:
	var cells: Variant = d.get("cells", [])
	var shapes: Variant = d.get("fill", [])
	if not cells is Array or not shapes is Array or ((cells as Array).is_empty() and (shapes as Array).is_empty()):
		return "blocks have cells [x, y, z, block] or a fill of shapes"
	if (cells as Array).size() > MAX_CELLS:
		return "cells are 1-%d [x, y, z, block]" % MAX_CELLS
	for c: Variant in cells:
		if not c is Array or (c as Array).size() != 4 or StudioShapes.block(c[3]) < 0:
			return "a cell is [x, y, z, block]"
		for k in 3:
			if typeof(c[k]) not in [TYPE_INT, TYPE_FLOAT]:
				return "a cell is [x, y, z, block]"
	if (shapes as Array).size() > StudioShapes.MAX_SHAPES:
		return "at most %d shapes" % StudioShapes.MAX_SHAPES
	for sh: Variant in shapes:
		var why := StudioShapes.problem(sh)
		if why != "":
			return why
	if StudioShapes.bound(d) > StudioShapes.MAX_CELLS * 4:
		return "the shapes are too big (at most %d cells)" % StudioShapes.MAX_CELLS
	var made := StudioShapes.cells(d)
	if made.is_empty():
		return "the shapes leave no blocks"
	if made.size() > StudioShapes.MAX_CELLS:
		return "the shapes make %d cells (at most %d)" % [made.size(), StudioShapes.MAX_CELLS]
	var lo := Vector3i(1 << 30, 1 << 30, 1 << 30)
	var hi := -lo
	for c: Vector3i in made:
		lo = lo.min(c)
		hi = hi.max(c)
	var span := hi - lo + Vector3i.ONE
	if maxi(span.x, maxi(span.y, span.z)) > StudioShapes.MAX_SPAN:
		return "the blocks span %s (at most %d a side)" % [span, StudioShapes.MAX_SPAN]
	return ""


static func _move_problem(mv: Variant, kind: String, length: float) -> String:
	if not mv is Dictionary:
		return "a move is a dictionary"
	var m: Dictionary = mv
	var what := str(m.get("do", ""))
	if not StudioRules.MOVES.has(what):
		return "unknown move '%s'" % what
	if typeof(m.get("at")) not in [TYPE_INT, TYPE_FLOAT] or float(m.at) < 0.0:
		return "%s starts at a time" % what
	if m.has("dur") and (typeof(m.dur) not in [TYPE_INT, TYPE_FLOAT] or float(m.dur) < 0.0):
		return "%s's dur is 0 or more" % what
	if m.has("ease") and not StudioRules.EASES.has(str(m.ease)):
		return "unknown ease '%s'" % m.ease
	var dur := StudioMotion.duration(m)
	if what in ["move", "turn", "grow", "pop", "drop"] and dur < ShortStyle.MOVE_MIN - ShortRules.SLACK:
		return "a %s lasts %.1f s at least (%d frames)" % [what, ShortStyle.MOVE_MIN, ShortStyle.frames(ShortStyle.MOVE_MIN)]
	if what == "move" and str(m.get("ease", "")) == "linear":
		return "a move eases (no linear glides)"
	if length >= 0.0 and float(m.at) + (0.0 if what in ["spin", "orbit"] and not m.has("dur") else dur) \
			> length + ShortRules.SLACK:
		return "%s ends after the Short (%.1f s)" % [what, length]
	match what:
		"move", "turn":
			if not StudioRules.is_vec(m.get("to")):
				return "%s needs to: [x, y, z]" % what
		"orbit":
			if not StudioRules.is_vec(m.get("around")) or StudioRules.num(m, "period", 0.0) <= 0.0:
				return "an orbit needs around: [x, y, z] and a period above 0"
		"spin":
			if not m.has("rate") and not m.has("turns"):
				return "a spin has a rate (turns a second) or turns"
		"grow":
			if StudioRules.num(m, "to", 0.0) <= 0.0:
				return "grow needs to: a size above 0"
			if m.has("axis") and not StudioRules.AXES.has(str(m.axis)):
				return "a grow's axis is %s" % ", ".join(StudioRules.AXES)
		"legs":
			if kind != "avatar":
				return "only an avatar walks"
			if m.has("arms") and not StudioRules.ARMS.has(str(m.arms)):
				return "a walk's arms are %s" % ", ".join(StudioRules.ARMS)
			if StudioRules.num(m, "steps", 0.0) < 0.0 or absf(StudioRules.num(m, "lean", 0.0)) > 60.0:
				return "a walk's steps are 0 or more a second, its lean -60 to 60 degrees"
		"stage":
			if kind != "rocket":
				return "only a rocket lets a stage go"
			if typeof(m.get("stage")) not in [TYPE_INT, TYPE_FLOAT] or int(m.stage) < 0:
				return "stage is the stage's number (0: the bottom one)"
		"emote":
			if kind != "avatar":
				return "only an avatar plays an emote"
			if not StudioRules.EMOTES.has(str(m.get("emote", ""))) or not EmotePoses.has(StringName(str(m.emote))):
				return "emote is one of %s" % ", ".join(StudioRules.EMOTES)
	return ""


static func _effect_problem(e: Variant, ids: Dictionary, length: float) -> String:
	if not e is Dictionary:
		return "an effect is a dictionary"
	var d: Dictionary = e
	if not StudioRules.EFFECTS.has(str(d.get("kind", ""))):
		return "unknown effect '%s' (%s)" % [d.get("kind"), ", ".join(StudioRules.EFFECTS)]
	if d.has("on") and not ids.has(str(d.on)):
		return "an effect's on is a model's id, not '%s'" % d.on
	if d.has("at") and not _in_reach(d.at):
		return "an effect's at is [x, y, z]"
	for key: String in ["from", "to"]:
		if typeof(d.get(key)) not in [TYPE_INT, TYPE_FLOAT] or float(d[key]) < 0.0:
			return "an effect runs from and to (seconds)"
	if float(d.to) <= float(d.from):
		return "an effect's to is after its from"
	if length >= 0.0 and float(d.to) > length + ShortRules.SLACK:
		return "an effect ends after the Short (%.1f s)" % length
	if d.has("size") and StudioRules.num(d, "size", 0.0) <= 0.0:
		return "an effect's size is above 0"
	if d.has("color") and not ShortRules.is_colour(d.color):
		return "an effect's color is a colour"
	if d.has("gravity") and (typeof(d.gravity) not in [TYPE_INT, TYPE_FLOAT] or absf(float(d.gravity)) > 100.0):
		return "an effect's gravity is m/s² (+ up), -100 to 100"
	if d.has("area"):
		var a: Variant = d.area
		if not a is Array or (a as Array).size() != 2 or typeof(a[0]) not in [TYPE_INT, TYPE_FLOAT] \
				or typeof(a[1]) not in [TYPE_INT, TYPE_FLOAT] or float(a[0]) <= 0.0 or float(a[1]) <= 0.0 \
				or float(a[0]) > StudioRules.REACH or float(a[1]) > StudioRules.REACH:
			return "an effect's area is [x, z] metres, each above 0"
	return ""


static func _camera_problem(keys: Variant, ids: Dictionary, length: float) -> String:
	if not keys is Array or (keys as Array).is_empty() or (keys as Array).size() > StudioRules.MAX_KEYS:
		return "a camera is 1-%d keys {at, pos, look}" % StudioRules.MAX_KEYS
	for k: Variant in keys:
		if not k is Dictionary or typeof(k.get("at")) not in [TYPE_INT, TYPE_FLOAT] or float(k.at) < 0.0:
			return "a camera key starts at a time"
		if not _in_reach(k.get("pos")) or not _in_reach(k.get("look")):
			return "a camera key has pos and look [x, y, z]"
		if not k.has("aim") and StudioRules.vec(k.pos).distance_to(StudioRules.vec(k.look)) < 0.01:
			return "a camera key looks away from where it stands"
		if k.has("fov") and (typeof(k.fov) not in [TYPE_INT, TYPE_FLOAT] or float(k.fov) < StudioRules.FOV.x
				or float(k.fov) > StudioRules.FOV.y):
			return "a camera's fov is %d-%d degrees" % [int(StudioRules.FOV.x), int(StudioRules.FOV.y)]
		if k.has("ease") and not StudioRules.EASES.has(str(k.ease)):
			return "unknown camera ease '%s'" % k.ease
		if k.has("path") and not StudioRules.CAMERA_PATHS.has(str(k.path)):
			return "a camera path is %s" % " or ".join(StudioRules.CAMERA_PATHS)
		if k.has("follow") and not ids.has(str(k.follow)):
			return "a camera follows a model's id, not '%s'" % k.follow
		if k.has("aim") and not ids.has(str(k.aim)):
			return "a camera aims at a model's id, not '%s'" % k.aim
		if k.has("roll") and (typeof(k.roll) not in [TYPE_INT, TYPE_FLOAT] or absf(float(k.roll)) > 180.0):
			return "a camera's roll is -180 to 180 degrees"
		if k.has("shake") and StudioRules.num(k, "shake", -1.0) < 0.0:
			return "a camera's shake is 0 or more metres"
		if length >= 0.0 and float(k.at) > length + ShortRules.SLACK:
			return "a camera key comes after the Short (%.1f s)" % length
	var sorted := StudioCamera.sorted(keys)
	for i in range(1, sorted.size()):
		var k: Dictionary = sorted[i]
		if bool(k.get("cut", false)):
			continue
		if float(k.at) - float(sorted[i - 1].at) < ShortStyle.MOVE_MIN - ShortRules.SLACK:
			return "a camera move lasts %.1f s at least (%d frames); a cut is a new shot" % [ShortStyle.MOVE_MIN,
				ShortStyle.frames(ShortStyle.MOVE_MIN)]
		if str(k.get("ease", "")) == "linear" and str(k.get("path", "line")) != "orbit":
			return "a camera move eases (only an orbit may turn evenly)"
	return ""
