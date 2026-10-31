class_name RealBuilder
extends RefCounted
## Owner #116, #117 (docs/superpowers/plans/2026-10-16-vr-round4.md "Round 4b"; docs/design/life-skills.md §13): Real
## Builder, the tool engine's first user, as a Life Experience in Life L1's own format (LifeExperience's header), in
## data/tools/real_builder.json. Its steps add the engine's fields: `checks` (the motion's numbers for this step), `gear`
## (the safety gear a find step puts on), `safety` (gear that must be on before this tool: the saw's goggles), `glow`
## (false: the bricks' places do not glow, the Expert try), `safe_mistake` (owner #118, design §14: {wrong, event, why,
## right}: a natural mistake a child may try on the Middle and Big tracks, the room's gentle `event` showing what would
## happen and the coach's calm `why`; shaped for Life's coming "safe mistake" kind, played today with LifeCheck's kinds:
## ToolRoomHost says the why and shows the event, never a miss). Tokens, the region's words and the seeded choice order work
## as LifeExperience's (its resolve and vars are reused), so once Life's catalogue knows the id the same file plays
## through LifeExperience unchanged (the lead's hook: docs/devlog/parts/tools-r4b.md).

const ID := "real_builder"
const PATH := "res://data/tools/real_builder.json"
const ROOM := "building_site"
## The Life units' lesson files (the School's format), per track.
const UNIT_FILES := {"little": "res://data/tools/units/real_builder_little.json",
	"middle": "res://data/tools/units/real_builder_middle.json", "big": "res://data/tools/units/real_builder_big.json"}
const UNIT_IDS := {"little": "life.home.real_builder_little", "middle": "life.home.real_builder_middle",
	"big": "life.home.real_builder_big"}
## Kinds of step a hand does (Life L1's test of the same name: each names its motion).
const HANDS_ON: Array[String] = ["rhythm", "taps", "sequence", "coins", "basket", "sweep", "point", "hands"]
## A safe mistake's parts (owner #118).
const SAFE_MISTAKE_KEYS: Array[String] = ["wrong", "event", "why", "right"]

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var text := FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
		var json := JSON.new()
		_data = json.data if text != "" and json.parse(text) == OK and json.data is Dictionary else {}
	return _data


static func clear_cache() -> void:
	_data = {}


static func title() -> String:
	return str(data().get("title", "Real Builder"))


static func track_data(track: String) -> Dictionary:
	var tracks: Variant = data().get("tracks")
	return (tracks as Dictionary).get(track, {}) if tracks is Dictionary else {}


static func vars(track: String, seed: int, region: String) -> Dictionary:
	return LifeExperience.vars(ID, track, seed, region)


## A run's steps (LifeExperience.steps' rules): the try's steps, tokens filled, choices in the seed's order.
static func steps(track: String, expert: bool, seed: int, region: String) -> Array[Dictionary]:
	var v := vars(track, seed, region)
	var out: Array[Dictionary] = []
	for s: Variant in track_data(track).get("steps", []):
		if not s is Dictionary:
			continue
		var mode := str((s as Dictionary).get("mode", ""))
		if (mode == "expert" and not expert) or (mode == "normal" and expert):
			continue
		out.append(_mixed(LifeExperience.resolve(s, v), seed))
	return out


static func check(track: String, region: String, seed: int = 0) -> Array[Dictionary]:
	var v := vars(track, seed, region)
	var out: Array[Dictionary] = []
	var i := 0
	for q: Variant in track_data(track).get("check", []):
		if q is Dictionary:
			var step: Dictionary = LifeExperience.resolve(q, v)
			step.kind = "choose"
			step.id = "check_%d" % i
			out.append(_mixed(step, seed))
		i += 1
	return out


static func devices(region: String = LifeRegion.DEFAULT) -> Dictionary:
	var d: Variant = data().get("devices", {})
	return LifeExperience.resolve(d, vars("little", 0, region)) if d is Dictionary else {}


static func card(track: String, region: String = LifeRegion.DEFAULT) -> Dictionary:
	return LifeExperience.resolve(track_data(track).get("name_it", {}), vars(track, 0, region))


static func words(track: String, key: String, region: String = LifeRegion.DEFAULT) -> String:
	return LifeExperience.fill(str(track_data(track).get(key, "")), vars(track, 0, region))


## Every tool a track's steps use (the tools and the gear), for the Tool Book and the room's bench.
static func tools_of(track: String) -> Array[String]:
	var out: Array[String] = []
	for expert: bool in [false, true]:
		for s in steps(track, expert, 0, LifeRegion.DEFAULT):
			var list: Array = [s.get("tool", ""), s.get("safety", "")] + (s.get("gear", []) as Array)
			for t: Variant in list:
				if str(t) != "" and not out.has(str(t)):
					out.append(str(t))
	return out


## The seeded order of a choice step's choices (the data writes the right one first); the answer follows.
static func _mixed(step: Dictionary, seed: int) -> Dictionary:
	var choices: Variant = step.get("choices")
	if not choices is Array or (choices as Array).size() < 2 or typeof(step.get("answer")) not in [TYPE_INT, TYPE_FLOAT]:
		return step
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, str(step.get("id", "")), str(step.get("say", ""))])
	var order: Array = range((choices as Array).size())
	GenKit.shuffle(rng, order)
	var mixed: Array = []
	for i: int in order:
		mixed.append(choices[i])
	step.choices = mixed
	step.answer = order.find(int(step.answer))
	return step


## What is wrong with the Experience ([] when nothing): Life L1's rules for an Experience, and the engine's: each tool
## step's tool is in the Tool Book and used with one of its motions, with sane numbers; the gear is safety gear; the
## devices run.
static func problems() -> Array[String]:
	var out: Array[String] = []
	var d := data()
	if d.is_empty():
		return ["real_builder: no file or a broken one"]
	for key: String in ["title", "area", "room"]:
		if str(d.get(key, "")) == "":
			out.append("real_builder has no %s" % key)
	var devs := devices()
	for dev: String in devs:
		for why in ToolDevice.problems(devs[dev]):
			out.append("device %s: %s" % [dev, why])
	for track in LifeData.TRACKS:
		var t := track_data(track)
		var where := "real_builder.%s" % track
		if t.is_empty():
			out.append(where + " is missing")
			continue
		for key: String in ["skill", "twist", "can_now", "try_real"]:
			if str(t.get(key, "")).strip_edges() == "":
				out.append("%s has no %s" % [where, key])
		var c := card(track)
		if str(c.get("title", "")) == "" or str(c.get("source", "")) == "" or not c.get("lines") is Array \
				or (c.lines as Array).size() < 3 or (c.lines as Array).size() > 5:
			out.append(where + ": its name-it card needs a title, 3-5 lines and its source")
		var sources: Variant = t.get("sources")
		if not sources is Array or (sources as Array).size() < 2:
			out.append(where + " needs two sources or more")
		else:
			for s: Variant in sources:
				if not s is Dictionary or not str((s as Dictionary).get("url", "")).begins_with("https://") \
						or str((s as Dictionary).get("fact", "")) == "":
					out.append("%s: a source without its fact or url: %s" % [where, s])
		var questions := check(track, LifeRegion.DEFAULT)
		if questions.size() < 3 or questions.size() > 5:
			out.append(where + " needs 3-5 check questions")
		for q in questions:
			var why := LifeCheck.problem(q)
			if why != "":
				out.append("%s check: %s" % [where, why])
			for ch: Variant in q.get("choices", []):
				if not LifeIcons.has(str((ch as Dictionary).get("icon", ""))):
					out.append("%s check: %s needs a known picture" % [where, ch])
		for expert: bool in [false, true]:
			var list := steps(track, expert, 1, LifeRegion.DEFAULT)
			if list.size() < LifeExperience.MIN_STEPS:
				out.append("%s: only %d steps" % [where, list.size()])
				continue
			if str(list.back().get("kind", "")) != "info":
				out.append(where + ": a run ends with kind words (an info step)")
			for step in list:
				out.append_array(_step_problems(step, where, devs))
	var seen := {}
	for p in out:
		seen[p] = true
	var unique: Array[String] = []
	for p: String in seen:
		unique.append(p)
	return unique


static func _step_problems(step: Dictionary, where: String, devs: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var id := str(step.get("id", "?"))
	var why := LifeCheck.problem(step)
	if why != "":
		out.append("%s %s: %s" % [where, id, why])
	if id == "?" or id == "":
		out.append(where + ": a step without an id")
	if HANDS_ON.has(str(step.get("kind", ""))) and not ToolMotion.ALL.has(str(step.get("motion", ""))):
		out.append("%s %s: a hands-on step names its motion" % [where, id])
	for ch: Variant in step.get("choices", []):
		if not LifeIcons.has(str((ch as Dictionary).get("icon", ""))):
			out.append("%s %s: %s needs a known picture" % [where, id, ch])
	var tool := str(step.get("tool", ""))
	var motion := str(step.get("motion", ""))
	if tool != "":
		if not ToolBook.has(tool):
			out.append("%s %s: %s is not in the Tool Book" % [where, id, tool])
		elif not ToolBook.motions(tool).has(motion):
			out.append("%s %s: a %s is not used with %s" % [where, id, tool, motion])
	if step.has("checks"):
		var c: Variant = step.checks
		var w := ToolMotion.problem(motion, c if c is Dictionary else {})
		if w != "":
			out.append("%s %s: %s" % [where, id, w])
	for g: Variant in (step.get("gear", []) as Array) + ([step.safety] if step.has("safety") else []):
		if str(ToolBook.entry(str(g)).get("kind", "")) != "safety":
			out.append("%s %s: %s is not safety gear" % [where, id, g])
	if step.has("device") and not devs.has(str(step.device)):
		out.append("%s %s: no device %s" % [where, id, step.device])
	for key: String in ["say", "done", "miss"]:
		if str(step.get(key, "")).contains("{"):
			out.append("%s %s: a token left in %s" % [where, id, key])
	if step.has("safe_mistake"):
		var m: Variant = step.safe_mistake
		if where.ends_with(".little"):
			out.append("%s %s: on the Little track the coach guides before any mistake" % [where, id])
		if not m is Dictionary:
			out.append("%s %s: a safe mistake is {wrong, event, why, right}" % [where, id])
		else:
			for key: String in SAFE_MISTAKE_KEYS:
				var w := str((m as Dictionary).get(key, "")).strip_edges()
				if w == "" or w.length() > LifeCheck.MAX_SAY:
					out.append("%s %s: its safe mistake needs its %s" % [where, id, key])
	return out
