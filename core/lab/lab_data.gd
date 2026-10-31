class_name LabData
extends RefCounted
## Spec §23.2: the Lab Book's part of the profile (ProfileData.lab). Per experiment id: its last guess (a choice's index
## or a sort's groups), whether that guess matched what happened (never shown as a mark), how many times it was done (a
## star from the first) and when the plants' seeds went in (unix seconds). Account-wide, parsed entry by entry and field
## by field (a bad one falls back on its own), kept by the server backup: merge_from never loses a star, a guess or a
## planting. An id the game does not know yet (a newer game's experiment) is kept as it is.

const MAX_ENTRIES := 64
const MAX_GUESS := 8      # a sort's things
const MAX_RUNS := 9999
const _ID := "^[a-z][a-z0-9_]{0,31}$"

## id -> {"g": guess (int or Array[int]), "m": matched (bool), "n": runs done (int), "p": planted at (int)}; a field
## is left out while it has nothing.
var entries := {}


func is_empty() -> bool:
	return entries.is_empty()


func guess(id: String) -> Variant:
	return (entries.get(id, {}) as Dictionary).get("g")


func matched(id: String) -> bool:
	return bool((entries.get(id, {}) as Dictionary).get("m", false))


func runs(id: String) -> int:
	return int((entries.get(id, {}) as Dictionary).get("n", 0))


func has_star(id: String) -> bool:
	return runs(id) > 0


func planted_at(id: String) -> int:
	return int((entries.get(id, {}) as Dictionary).get("p", 0))


## Experiments with a star.
func stars() -> int:
	var n := 0
	for id: String in entries:
		n += 1 if has_star(id) else 0
	return n


func set_guess(id: String, g: Variant, is_match: bool) -> void:
	var clean: Variant = _clean_guess(g)
	var e := _entry(id)
	if e.is_empty() and not entries.has(id):
		return
	if clean == null:
		e.erase("g")
		e.erase("m")
	else:
		e["g"] = clean
		e["m"] = is_match
	_tidy(id)


## The experiment was done once more: true the first time (the star).
func finish(id: String) -> bool:
	var e := _entry(id)
	if e.is_empty() and not entries.has(id):
		return false
	var first := int(e.get("n", 0)) == 0
	e["n"] = mini(int(e.get("n", 0)) + 1, MAX_RUNS)
	return first


## The plants' seeds went in at `at` (unix seconds); 0: the pots are empty again.
func set_planted(id: String, at: int) -> void:
	var e := _entry(id)
	if e.is_empty() and not entries.has(id):
		return
	if at > 0:
		e["p"] = at
	else:
		e.erase("p")
	_tidy(id)


func to_dict() -> Dictionary:
	return entries.duplicate(true)


static func from_dict(v: Variant) -> LabData:
	var d := LabData.new()
	if not v is Dictionary:
		return d
	var re := RegEx.create_from_string(_ID)
	for id: Variant in v:
		var src: Variant = v[id]
		if not id is String or not re.search(id) or not src is Dictionary or d.entries.size() >= MAX_ENTRIES:
			continue
		var e := {}
		var g: Variant = _clean_guess(src.get("g"))
		if g != null:
			e["g"] = g
			e["m"] = bool(src.get("m", false)) if src.get("m") is bool else false
		var n: Variant = src.get("n")
		if _whole(n) and int(n) >= 1:
			e["n"] = mini(int(n), MAX_RUNS)
		var p: Variant = src.get("p")
		if _whole(p) and float(p) > 0.0 and float(p) < 1e12:
			e["p"] = int(p)
		if not e.is_empty():
			d.entries[id] = e
	return d


## Keeps the best of both copies (the server backup's merge, ProfileBackup): the most runs; this copy's guess, or the
## other's when this one has none; the earlier planting (its seeds have grown longer).
func merge_from(other: LabData) -> void:
	for id: String in other.entries:
		var theirs: Dictionary = other.entries[id]
		if not entries.has(id) and entries.size() >= MAX_ENTRIES:
			continue
		var e := _entry(id)
		if theirs.has("n"):
			e["n"] = maxi(int(e.get("n", 0)), int(theirs["n"]))
		if not e.has("g") and theirs.has("g"):
			e["g"] = (theirs["g"] as Array).duplicate() if theirs["g"] is Array else theirs["g"]
			e["m"] = bool(theirs.get("m", false))
		if theirs.has("p"):
			e["p"] = mini(int(e["p"]), int(theirs["p"])) if e.has("p") else int(theirs["p"])


## An entry with nothing left in it goes.
func _tidy(id: String) -> void:
	if entries.has(id) and (entries[id] as Dictionary).is_empty():
		entries.erase(id)


func _entry(id: String) -> Dictionary:
	if not entries.has(id):
		if entries.size() >= MAX_ENTRIES or not RegEx.create_from_string(_ID).search(id):
			return {}
		entries[id] = {}
	return entries[id]


## A choice's index, or a sort's groups (each 0-2); null for anything else.
static func _clean_guess(g: Variant) -> Variant:
	if _whole(g) and int(g) >= 0 and int(g) < 16:
		return int(g)
	if g is Array and not (g as Array).is_empty() and (g as Array).size() <= MAX_GUESS:
		var out: Array = []
		for x: Variant in g:
			if not _whole(x) or int(x) < -1 or int(x) > 2:
				return null
			out.append(int(x))
		return out
	return null


static func _whole(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and float(v) == floorf(float(v))
