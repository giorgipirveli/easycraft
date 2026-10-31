class_name LeafVoyages
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5-3.6, §3.8, §4.3): Inside a Leaf's catalogue, as data
## (`data/play/leaf/voyages.json`, `lines.json`): the ladder (rungs 4-8, one Size Magic depth a grade), the kinds of
## weather (heat, light, and which way a plant that knows the rule sets its doors), and each voyage: its unit (the
## School's record), plant and dressing, the simulation's numbers (LeafSim), the weather script (LeafWeather), the
## judged beats (LeafBeats) and Hoot's lines by cue. Pure: no nodes.

const FILE := "res://data/play/leaf/voyages.json"
const LINES_FILE := "res://data/play/leaf/lines.json"
## A question line answered by what happens next (the dusk answers "When does it cool down?").
const WORLD := "world"
## The pictures a voyage's HUD shows for an answer (PlayGlyph's, and "again": LeafHud's ↻, drawn in B2).
const PICTURES: Array[String] = ["go", "next", "pause", "stop", "eye", "close", "again"]

static var _data := {}
static var _lines := {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = _read(FILE, {"rungs": [], "weather": {}, "voyages": []})
	return _data


## The voyages' ids in the board's order.
static func ids() -> Array[String]:
	var out: Array[String] = []
	for v: Dictionary in data().get("voyages", []):
		out.append(str(v.get("id", "")))
	return out


## A voyage's entry ({} for an unknown id).
static func voyage(id: String) -> Dictionary:
	for v: Dictionary in data().get("voyages", []):
		if str(v.get("id", "")) == id:
			return v
	return {}


static func unit(id: String) -> String:
	return str(voyage(id).get("unit", ""))


static func is_transfer(id: String) -> bool:
	return bool(voyage(id).get("transfer", false))


## On the board: everyone's first voyage is open; another opens once the voyage it comes after is done.
static func unlocked(id: String, done: Array) -> bool:
	var v := voyage(id)
	if v.is_empty():
		return false
	var after := str(v.get("after", ""))
	return after == "" or done.has(after)


## The ladder: {rung, grade, name, depth, scale} for rungs 4-8.
static func rungs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in data().get("rungs", []):
		out.append(r)
	return out


## The kinds of weather: {kind: {heat, light, doors ("open" or "shut"), night, dawn_heat, dawn_light}}.
static func weather_kinds() -> Dictionary:
	return data().get("weather", {})


## Every line: {id, when, text, answer (a question's: WORLD or pictures), for (praise: what it praises)}.
static func lines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for l: Dictionary in _all_lines().get("lines", []):
		out.append(l)
	return out


## A line's words ("" for an unknown id).
static func line(id: String) -> String:
	for l: Dictionary in _all_lines().get("lines", []):
		if str(l.get("id", "")) == id:
			return str(l.get("text", ""))
	return ""


static func _all_lines() -> Dictionary:
	if _lines.is_empty():
		_lines = _read(LINES_FILE, {"lines": []})
	return _lines


static func _read(path: String, empty: Dictionary) -> Dictionary:
	var json := JSON.new()
	var text := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	if text != "" and json.parse(text) == OK and json.data is Dictionary:
		return json.data
	return empty
