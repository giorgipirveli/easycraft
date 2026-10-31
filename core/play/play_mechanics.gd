class_name PlayMechanics
extends RefCounted
## Owner #122 (docs/design/learning-is-play.md §5.1, spec §22.0): the generic mechanics, as data
## (`data/play/mechanics.json`): each exercise type is played through one of them (Make it for a number, Sort it, Order it,
## Connect it for a match, Fix it for a label, Build it, Code it for a robot, Beat it for a rhythm, Mix it, Find it for a
## point, Choose by doing for a choice, Test it for true or false), so every written unit is a game. A unit's play level
## is P0 (the generic mechanics) until its `play` block names a signature game listed under "signature" (P1: steps
## G1-G5; none yet). `ExerciseCheck` stays the referee: the mechanics only change how an answer is made.

const FILE := "res://data/play/mechanics.json"
const P0 := "P0"
const P1 := "P1"

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var json := JSON.new()
		var text := FileAccess.get_file_as_string(FILE) if FileAccess.file_exists(FILE) else ""
		if text != "" and json.parse(text) == OK and json.data is Dictionary:
			_data = json.data
		else:
			_data = {"mechanics": [], "signature": {}}
	return _data


## The mechanics' ids, in the design's order.
static func ids() -> Array[String]:
	var out: Array[String] = []
	for m: Dictionary in data().get("mechanics", []):
		out.append(str(m.get("id", "")))
	return out


static func entry(id: String) -> Dictionary:
	for m: Dictionary in data().get("mechanics", []):
		if str(m.get("id", "")) == id:
			return m
	return {}


## The mechanic an exercise type plays through ("" for a type with none).
static func of(type: String) -> String:
	for m: Dictionary in data().get("mechanics", []):
		if (m.get("types", []) as Array).has(type):
			return str(m.id)
	return ""


static func of_exercise(ex: Dictionary) -> String:
	return of(str(ex.get("type", "")))


## "Make it", "Choose by doing".
static func name_of(id: String) -> String:
	return str(entry(id).get("name", ""))


## Owner #133 (rule 0): the few words on the screen while a challenge of this mechanic is spoken ("Sort them!").
static func say_of(id: String) -> String:
	return str(entry(id).get("say", ""))


## Owner #134: kept (an action that is the answer) or shelved (a written choice or claim in costume: never played).
static func kept(id: String) -> bool:
	return str(entry(id).get("status", "kept")) == "kept"


## The problem that appears in the place when this mechanic opens a unit (the hook, when the unit has none of its own).
static func hook_of(id: String) -> String:
	return str(entry(id).get("hook", ""))


## What a child does in it, in a child's words.
static func does(id: String) -> String:
	return str(entry(id).get("does", ""))


## The world's test button's words ("RUN THE MACHINE"); "" when the act itself answers (Choose by doing, Test it).
static func go_words(id: String) -> String:
	return str(entry(id).get("go", ""))


## The mechanics a written unit's challenges use: its hand-written exercises', and one generated exercise of each
## generator at its level.
static func of_unit(content: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for t: String in _types(content):
		var m := of(t)
		if m != "" and not out.has(m):
			out.append(m)
	return out


## The unit's most used mechanic (its place on the map; a tie goes to the design's order).
static func main_of(content: Dictionary) -> String:
	var counts := {}
	for t: String in _types(content, true):
		var m := of(t)
		if m != "":
			counts[m] = int(counts.get(m, 0)) + 1
	var best := ""
	for id in ids():
		if counts.has(id) and (best == "" or int(counts[id]) > int(counts[best])):
			best = id
	return best


## The exercise types of a written unit that no mechanic plays ([] for every unit: the audit lists any other).
static func unplayable(content: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for t: String in _types(content):
		if of(t) == "" and not out.has(t):
			out.append(t)
	return out


## P1 when the unit's play block names a signature game that is built; otherwise P0.
static func level(content: Dictionary) -> String:
	var play: Variant = content.get("play")
	if play is Dictionary and signature_games().has(str((play as Dictionary).get("game", ""))):
		return P1
	return P0


## The signature games built so far: id -> {name, script} (none in G0). A game is a PlayStation subclass (its `script`)
## with `static func expresses(ex: Dictionary) -> bool`; each wave adds its games here (data/play/mechanics.json, one
## entry each: "owner #122 (G1a)").
static func signature_games() -> Dictionary:
	var s: Variant = data().get("signature", {})
	return s if s is Dictionary else {}


static func game_name(id: String) -> String:
	var g: Variant = signature_games().get(id)
	return str((g as Dictionary).get("name", "")) if g is Dictionary else ""


## The game's station script ("" when the game is not built).
static func game_script(id: String) -> String:
	var g: Variant = signature_games().get(id)
	return str((g as Dictionary).get("script", "")) if g is Dictionary else ""


## The signature game `game` plays `ex` in its own station (its `expresses`): a deep game is designed to be played
## without reading (future-lessons.md §2), so what it expresses plays whatever its type.
static func game_expresses(game: String, ex: Dictionary) -> bool:
	var path := game_script(game) if game != "" else ""
	if path == "" or not ResourceLoader.exists(path):
		return false
	var script := load(path) as GDScript
	return script != null and script.has_method(&"expresses") and bool(script.call(&"expresses", ex))


## Every type a unit's challenges can have (each once, unless `every`: one per exercise and generator).
static func _types(content: Dictionary, every: bool = false) -> Array[String]:
	var out: Array[String] = []
	for ex: Variant in content.get("exercises", []):
		if ex is Dictionary:
			var t := str((ex as Dictionary).get("type", ""))
			if every or not out.has(t):
				out.append(t)
	for g: Variant in content.get("generators", []):
		if not g is Dictionary:
			continue
		var made := SchoolGen.make(str((g as Dictionary).get("gen", "")), 1, int((g as Dictionary).get("level", 1)))
		if not made.is_empty():
			var t := str(made.get("type", ""))
			if every or not out.has(t):
				out.append(t)
	return out
