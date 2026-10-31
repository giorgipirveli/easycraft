class_name ToolBook
extends RefCounted
## Owner #117 (docs/design/life-skills.md §13, "The Tool Book" and the catalogue by area): every tool and device a child
## can learn, as data (data/tools/tools.json, read once and kept): {areas: [{id, title}], tools: [{id, name, kind (tool,
## device, safety), area, icon (ToolIcons), motions (ToolMotion's ten; the first is its main one; safety gear has
## none), for, hold, safety, grown_up (a grown-up's job in real life), checks {motion: its own numbers}, device (a
## device's ToolDevice data)}]}. The stamps a child earns with each are ToolData's; the page is ToolBookPage.

const PATH := "res://data/tools/tools.json"
const AREAS: Array[String] = ["building", "fixing", "kitchen", "home", "garden", "health", "money", "tech", "science",
	"around", "art"]
const KINDS: Array[String] = ["tool", "device", "safety"]
const RIGHT_TOOL := "That works better with the %s. The %s is for %s."
const PICK_UP := "Pick up the %s first."
const MAX_WORDS := 120

static var _data := {}
static var _by_id := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var text := FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
		var json := JSON.new()
		_data = json.data if text != "" and json.parse(text) == OK and json.data is Dictionary else {"areas": [], "tools": []}
		_by_id.clear()
		for t: Variant in _data.get("tools", []):
			if t is Dictionary and str((t as Dictionary).get("id", "")) != "":
				_by_id[str(t.id)] = t
	return _data


static func clear_cache() -> void:
	_data = {}
	_by_id.clear()


static func ids() -> Array[String]:
	data()
	var out: Array[String] = []
	for t: Variant in _data.get("tools", []):
		if t is Dictionary:
			out.append(str(t.get("id", "")))
	return out


static func has(id: String) -> bool:
	data()
	return _by_id.has(id)


static func entry(id: String) -> Dictionary:
	data()
	return _by_id.get(id, {})


static func name_of(id: String) -> String:
	return str(entry(id).get("name", id.replace("_", " ")))


static func area_title(area: String) -> String:
	for a: Variant in data().get("areas", []):
		if a is Dictionary and str(a.get("id", "")) == area:
			return str(a.get("title", ""))
	return ""


static func of_area(area: String) -> Array[String]:
	var out: Array[String] = []
	for id in ids():
		if str(entry(id).get("area", "")) == area:
			out.append(id)
	return out


static func motions(id: String) -> Array[String]:
	var out: Array[String] = []
	for m: Variant in entry(id).get("motions", []):
		out.append(str(m))
	return out


## The tool's own numbers for one of its motions ({} for none).
static func checks(id: String, motion: String) -> Dictionary:
	var c: Variant = entry(id).get("checks", {})
	if c is Dictionary and (c as Dictionary).get(motion) is Dictionary:
		return ((c as Dictionary)[motion] as Dictionary).duplicate(true)
	return {}


## A device's data for ToolDevice ({} for a tool).
static func device(id: String) -> Dictionary:
	var d: Variant = entry(id).get("device", {})
	return d if d is Dictionary else {}


## The picture's name: its own, else its motion's, else its kind's.
static func icon(id: String) -> String:
	var e := entry(id)
	if str(e.get("icon", "")) != "":
		return str(e.icon)
	var m := motions(id)
	return "motion_" + m[0] if not m.is_empty() else str(e.get("kind", "tool"))


## "The right tool for the job", kindly: "" when the tool in the hand is the one the job wants.
static func right_tool(wanted: String, held: String) -> String:
	if held == wanted or wanted == "":
		return ""
	if held == "":
		return PICK_UP % name_of(wanted)
	return RIGHT_TOOL % [name_of(wanted), name_of(held), str(entry(held).get("for", "something else"))]


## What is wrong with the catalogue ([] when nothing).
static func problems() -> Array[String]:
	var out: Array[String] = []
	var areas: Array[String] = []
	for a: Variant in data().get("areas", []):
		if not a is Dictionary or str(a.get("title", "")) == "":
			out.append("an area without its title")
			continue
		areas.append(str(a.id))
	if areas != AREAS:
		out.append("the areas are %s, not %s" % [areas, AREAS])
	var seen := {}
	for t: Variant in data().get("tools", []):
		if not t is Dictionary:
			out.append("a tool that is not an object")
			continue
		var id := str(t.get("id", ""))
		if id == "" or seen.has(id):
			out.append("%s: a missing or repeated id" % id)
		seen[id] = true
		for key: String in ["name", "for", "hold", "safety"]:
			var w := str(t.get(key, "")).strip_edges()
			if w == "" or w.length() > MAX_WORDS:
				out.append("%s: its %s must be 1-%d letters" % [id, key, MAX_WORDS])
		if not AREAS.has(str(t.get("area", ""))):
			out.append("%s: unknown area %s" % [id, t.get("area")])
		var kind := str(t.get("kind", ""))
		if not KINDS.has(kind):
			out.append("%s: unknown kind %s" % [id, kind])
		var ms := motions(id)
		if kind == "safety" and not ms.is_empty():
			out.append("%s: safety gear is put on, not used with a motion" % id)
		if kind != "safety" and ms.is_empty():
			out.append("%s needs its motions" % id)
		for m in ms:
			if not ToolMotion.ALL.has(m):
				out.append("%s: unknown motion %s" % [id, m])
		var c: Variant = t.get("checks", {})
		if c is Dictionary:
			for m: Variant in c:
				if not ms.has(str(m)):
					out.append("%s has checks for %s, not one of its motions" % [id, m])
				elif (c as Dictionary)[m] is Dictionary:
					var why := ToolMotion.problem(str(m), (c as Dictionary)[m])
					if why != "":
						out.append("%s: %s" % [id, why])
		if kind == "device":
			for why in ToolDevice.problems(t.get("device")):
				out.append("%s: %s" % [id, why])
	return out
