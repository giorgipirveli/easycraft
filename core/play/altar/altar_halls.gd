class_name AltarHalls
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5, §3.5b, §3.6, §3.8, §3.10, §4.3): Balance Altar's
## catalogue, as data (`data/play/altar/halls.json`, `lines.json`): the ladder (wings 5-8, one a grade, their units and
## rooms), the fade's starting stage per grade, and each room: its unit (the School's record), tools, music, place, the
## altars in order (a form for AltarGen, or a taught altar's fixed pans; taught or judged; the Great Altar; each one's
## Glimmer) and Hoot's lines by cue. Pure: no nodes.

const FILE := "res://data/play/altar/halls.json"
const LINES_FILE := "res://data/play/altar/lines.json"
## A question line answered by what happens next.
const WORLD := "world"
## The pictures a room's HUD shows for an answer (PlayGlyph's, and "again": the ↻, drawn in B2).
const PICTURES: Array[String] = ["go", "next", "pause", "stop", "eye", "close", "again"]
## The Glimmers GlimmerModel draws (the hall's biggest, the Great Altar's, is a dragon).
const GLIMMERS: Array[String] = ["fox", "bunny", "bird", "turtle", "fish", "cat", "dragon"]

static var _data := {}
static var _lines := {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = _read(FILE, {"rooms": [], "wings": [], "stages": {}})
	return _data


## The rooms' ids in the board's order.
static func ids() -> Array[String]:
	var out: Array[String] = []
	for r: Dictionary in data().get("rooms", []):
		out.append(str(r.get("id", "")))
	return out


## A room's entry ({} for an unknown id).
static func room(id: String) -> Dictionary:
	for r: Dictionary in data().get("rooms", []):
		if str(r.get("id", "")) == id:
			return r
	return {}


static func unit(id: String) -> String:
	return str(room(id).get("unit", ""))


static func is_transfer(id: String) -> bool:
	return bool(room(id).get("transfer", false))


## Where a transfer room is (its NEW_SETTING events' note); "" for a room that is not one.
static func setting(id: String) -> String:
	return str(room(id).get("setting", ""))


## On the board: everyone's first room is open; another opens once the room it comes after is lit.
static func unlocked(id: String, done: Array) -> bool:
	var r := room(id)
	if r.is_empty():
		return false
	var after := str(r.get("after", ""))
	return after == "" or done.has(after)


## The tools a room offers besides the hands ("bowls", "gem_bag", "pump").
static func tools(id: String) -> Array[String]:
	var out: Array[String] = []
	for t: Variant in room(id).get("tools", []):
		out.append(str(t))
	return out


## A room's altars in order: {n, form, glimmer, taught, demo, trap, great, pans, x}.
static func altars(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for a: Dictionary in room(id).get("altars", []):
		out.append(a)
	return out


## The pans of one altar: a taught altar's fixed ones, else new from `rng` by its form.
static func altar_state(altar: Dictionary, rng: RandomNumberGenerator) -> AltarState:
	if str(altar.get("form", "")) == "fixed":
		return AltarGen.fixed(altar.get("pans", [1, 1, 0, 2]), int(altar.get("x", 1)))
	return AltarGen.make(str(altar.form), rng)


## The kind of event an altar freed first time records: SOLVED in the hall, NEW_SETTING for the Great Altar (the lead's
## ruling 6: the hall's two-move finale is transfer evidence for the one-step unit) and for every altar of a transfer
## room.
static func solved_kind(id: String, altar: Dictionary) -> String:
	if is_transfer(id) or bool(altar.get("great", false)):
		return SkillShown.NEW_SETTING
	return SkillShown.SOLVED


## Hoot's lines by cue for a room ({cue: line id, or [ids]}).
static func cues(id: String) -> Dictionary:
	return room(id).get("cues", {})


## The ladder: {wing, grade, name, units, rooms} for wings 5-8.
static func wings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w: Dictionary in data().get("wings", []):
		out.append(w)
	return out


## The fade's starting stage for a grade (AltarRunes' stages; pictures when the grade is not on the ladder).
static func start_stage(grade: int) -> int:
	return int((data().get("stages", {}) as Dictionary).get(str(grade), AltarRunes.PICTURES))


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


## A line as it is said: "[n gems]" becomes "one gem" or "four gems", "[n]" a number word.
static func say(id: String, vars: Dictionary = {}) -> String:
	var text := line(id)
	if vars.has("n"):
		var n := int(vars.n)
		text = text.replace("[n gems]", AltarRunes.count_words(n, "gem")).replace("[n]", AltarRunes.number_word(n))
	return text


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
