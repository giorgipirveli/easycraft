class_name LabExperiments
extends RefCounted
## Spec §23.3 (owner #74): the Science Lab's experiments, as data. `data/lab/index.json` lists them in the Lab's order
## ({"experiments": [id, …]}); `data/lab/<id>.json` is one experiment:
## - id, title (a card's words), card (one line under it), units (the School's unit ids it goes with: TRY IT IN THE LAB
##   on their pages, LEARN MORE from here), supplies ({block name: count}, taken from the bag in Survivor);
## - predict: step 1, a School exercise form without a hint (a guess is never marked): {type "choice", prompt, choices,
##   answer} or {type "sort", prompt, groups [yes, no], by}: a sort of the scene's things by their flag `by`;
## - scene: step 2's small scene (LabModels); try: what to do there; safety (optional): words for the burner, the battery;
## - result: what happens (step 3 and the Lab Book); why: 1-4 cards of why, each read aloud.
## Files are read the first time they are asked for (clear_cache for tests); nothing loads at the game's start.

const DIR := "res://data/lab"
const INDEX := "index.json"
const MAX_TITLE := 24
const MAX_CARD := 44
const MAX_PROMPT := 180
const MAX_CHOICE := 28
const MAX_TRY := 140
const MAX_SAFETY := 140
const MAX_RESULT := 200
const MAX_WHY := 230
const MAX_WHY_CARDS := 4
const MAX_UNITS := 6
## The ordinary blocks a bench's supplies may cost in Survivor, by the names the data uses.
const SUPPLY_BLOCKS := {"planks": BlockIds.PLANKS, "stone": BlockIds.STONE, "dirt": BlockIds.DIRT, "sand": BlockIds.SAND,
	"glass": BlockIds.GLASS, "log": BlockIds.LOG, "leaves": BlockIds.LEAVES, "coal": BlockIds.COAL, "iron": BlockIds.IRON}
const MAX_SUPPLIES := 3   # blocks in all

static var _ids: Array[String] = []
static var _loaded := false
static var _cache := {}   # id -> its parsed file ({} when missing or broken)


## The experiments in the Lab's order.
static func ids() -> Array[String]:
	if not _loaded:
		_loaded = true
		_ids.clear()
		var d: Variant = _parse(_read(DIR.path_join(INDEX)))
		if d is Dictionary and d.get("experiments") is Array:
			for id: Variant in d.experiments:
				if id is String and not _ids.has(id):
					_ids.append(id)
	return _ids


## Experiment `id` ({} when there is none, or its file is broken or another's).
static func experiment(id: String) -> Dictionary:
	if not _cache.has(id):
		var d: Variant = _parse(_read(DIR.path_join(id + ".json")))
		_cache[id] = d if d is Dictionary and str((d as Dictionary).get("id", "")) == id else {}
	return _cache[id]


## Tests: use `list` as the index and `e` as an experiment.
static func put_ids(list: Array[String]) -> void:
	_loaded = true
	_ids = list.duplicate()


static func put(id: String, e: Dictionary) -> void:
	_cache[id] = e


static func clear_cache() -> void:
	_loaded = false
	_ids.clear()
	_cache.clear()


## The experiments that list School unit `unit_id` (its page shows TRY IT IN THE LAB).
static func for_unit(unit_id: String) -> Array[String]:
	var out: Array[String] = []
	for id in ids():
		if (experiment(id).get("units", []) as Array).has(unit_id):
			out.append(id)
	return out


## LEARN MORE's unit: the first of the child's grade, else of the nearest grade below, else the first listed.
static func learn_unit(e: Dictionary, grade: int) -> String:
	var units: Array = e.get("units", [])
	if units.is_empty():
		return ""
	var best := ""
	var best_grade := -1
	for u: Variant in units:
		var g := _grade_of(str(u))
		if g <= grade and g > best_grade:
			best = str(u)
			best_grade = g
	return best if best != "" else str(units[0])


static func _grade_of(unit_id: String) -> int:
	return int(unit_id.get_slice(".", 0).substr(1))


## Step 1 as a School exercise (ExerciseCheck's form): a sort gets its items (the things' names) and its answer (what
## each thing really does) from the scene.
static func predict_of(e: Dictionary) -> Dictionary:
	var p: Dictionary = (e.get("predict", {}) as Dictionary).duplicate(true)
	if str(p.get("type", "")) == "sort":
		var items: Array = []
		var answer: Array = []
		var by := str(p.get("by", ""))
		for t: Variant in (e.get("scene", {}) as Dictionary).get("things", []):
			if t is Dictionary:
				items.append(str(t.get("name", "")))
				answer.append(0 if bool(t.get(by, false)) else 1)
		p.items = items
		p.answer = answer
	return p


## Whether a guess matched what happens (never shown as a mark: step 3 says it kindly either way).
static func matched(e: Dictionary, guess: Variant) -> bool:
	return guess != null and ExerciseCheck.is_right(predict_of(e), guess)


## A guess in words: a choice's text, or "Floats: wood, ice. Sinks: stone." ("" for no guess).
static func predict_words(e: Dictionary, guess: Variant) -> String:
	var p := predict_of(e)
	match str(p.get("type", "")):
		"choice":
			var choices: Array = p.get("choices", [])
			if typeof(guess) in [TYPE_INT, TYPE_FLOAT] and int(guess) >= 0 and int(guess) < choices.size():
				return ExerciseCheck.item_text(choices[int(guess)])
		"sort":
			if not guess is Array:
				return ""
			var parts: Array[String] = []
			var groups: Array = p.get("groups", [])
			for g in groups.size():
				var names: Array[String] = []
				for i in mini((guess as Array).size(), (p.items as Array).size()):
					if typeof(guess[i]) in [TYPE_INT, TYPE_FLOAT] and int(guess[i]) == g:
						names.append(str(p.items[i]).to_lower())
				if not names.is_empty():
					parts.append("%s: %s." % [groups[g], ", ".join(names)])
			return " ".join(parts)
	return ""


## The blocks one run costs in Survivor: block id -> count.
static func supplies(e: Dictionary) -> Dictionary:
	var out := {}
	var s: Variant = e.get("supplies", {})
	if s is Dictionary:
		for k: Variant in s:
			if SUPPLY_BLOCKS.has(str(k)) and typeof(s[k]) in [TYPE_INT, TYPE_FLOAT] and int(s[k]) > 0:
				out[SUPPLY_BLOCKS[str(k)]] = int(s[k])
	return out


## "1 Planks and 1 Stone".
static func supplies_words(e: Dictionary) -> String:
	var parts: Array[String] = []
	var s := supplies(e)
	for id: int in s:
		parts.append("%d %s" % [int(s[id]), BlockIds.display_name(id)])
	return LabColours._and(parts)


## Every text a child reads in experiment `e` (the content test checks their words).
static func words_of(e: Dictionary) -> Array[String]:
	var out: Array[String] = [str(e.get("title", "")), str(e.get("card", "")), str(e.get("try", "")),
		str(e.get("safety", "")), str(e.get("result", ""))]
	var p := predict_of(e)
	out.append(str(p.get("prompt", "")))
	for c: Variant in p.get("choices", []) + p.get("groups", []) + p.get("items", []):
		out.append(ExerciseCheck.item_text(c))
	for w: Variant in e.get("why", []):
		out.append(str(w))
	return out


## What is wrong with experiment `e` ([] when nothing).
static func problems(e: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var id := str(e.get("id", ""))
	if not RegEx.create_from_string("^[a-z][a-z0-9_]{0,31}$").search(id):
		out.append("a bad id '%s'" % id)
	for f: Array in [["title", MAX_TITLE], ["card", MAX_CARD], ["try", MAX_TRY], ["result", MAX_RESULT]]:
		var t: Variant = e.get(f[0])
		if not t is String or str(t).strip_edges() == "" or str(t).length() > int(f[1]):
			out.append("%s: its %s is 1-%d letters" % [id, f[0], f[1]])
	if e.has("safety") and (not e.safety is String or str(e.safety).length() > MAX_SAFETY):
		out.append("%s: its safety words are at most %d letters" % [id, MAX_SAFETY])
	var units: Variant = e.get("units")
	if not units is Array or (units as Array).is_empty() or (units as Array).size() > MAX_UNITS:
		out.append("%s: 1-%d School units" % [id, MAX_UNITS])
	else:
		for u: Variant in units:
			if Curriculum.unit(str(u)).is_empty():
				out.append("%s: %s is not a unit of the School" % [id, u])
	var why: Variant = e.get("why")
	if not why is Array or (why as Array).is_empty() or (why as Array).size() > MAX_WHY_CARDS:
		out.append("%s: 1-%d why cards" % [id, MAX_WHY_CARDS])
	else:
		for w: Variant in why:
			if not w is String or str(w).strip_edges() == "" or str(w).length() > MAX_WHY:
				out.append("%s: a why card is 1-%d letters" % [id, MAX_WHY])
	var s: Variant = e.get("supplies")
	var total := 0
	if s is Dictionary:
		for k: Variant in s:
			if not SUPPLY_BLOCKS.has(str(k)) or typeof(s[k]) not in [TYPE_INT, TYPE_FLOAT] or int(s[k]) < 1:
				out.append("%s: supplies of %s" % [id, k])
			else:
				total += int(s[k])
	if total < 1 or total > MAX_SUPPLIES:
		out.append("%s: supplies of 1-%d ordinary blocks" % [id, MAX_SUPPLIES])
	var scene_why := LabModels.problem(e.get("scene"))
	if scene_why != "":
		out.append("%s: %s" % [id, scene_why])
	out.append_array(_predict_problems(e, id))
	return out


static func _predict_problems(e: Dictionary, id: String) -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = e.get("predict")
	if not raw is Dictionary:
		return ["%s: no prediction" % id]
	var p := predict_of(e)
	var prompt: Variant = p.get("prompt")
	if not prompt is String or str(prompt).strip_edges() == "" or str(prompt).length() > MAX_PROMPT:
		out.append("%s: the prediction's prompt is 1-%d letters" % [id, MAX_PROMPT])
		return out
	var ex := p.duplicate(true)
	ex.hint = "-"   # a guess is never marked, so it has no hint; the School's checker wants one
	match str(p.get("type", "")):
		"choice":
			var why := ExerciseCheck.problem(ex)
			if why != "":
				out.append("%s: its prediction: %s" % [id, why])
			for c: Variant in p.get("choices", []):
				if ExerciseCheck.item_text(c).length() > MAX_CHOICE:
					out.append("%s: a guess of at most %d letters" % [id, MAX_CHOICE])
		"sort":
			var scene: Dictionary = e.get("scene", {}) if e.get("scene") is Dictionary else {}
			if not ["tank", "magnet"].has(str(scene.get("kind", ""))):
				out.append("%s: a sort's things come from a tank or a magnet scene" % id)
			var by := str(p.get("by", ""))
			if by != ("floats" if str(scene.get("kind", "")) == "tank" else "magnetic"):
				out.append("%s: the sort goes by the scene's own flag" % id)
			var groups: Variant = p.get("groups")
			if not groups is Array or (groups as Array).size() != 2:
				out.append("%s: a sort's two groups (yes, no)" % id)
			else:
				for g: Variant in groups:
					if not g is String or str(g).strip_edges() == "" or str(g).length() > ExerciseCheck.MAX_GROUP:
						out.append("%s: a group's name is 1-%d letters" % [id, ExerciseCheck.MAX_GROUP])
		_:
			out.append("%s: a prediction is a choice or a sort" % id)
	return out


static func _parse(text: String) -> Variant:
	var json := JSON.new()
	if text == "" or json.parse(text) != OK:
		return null
	return json.data


static func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
