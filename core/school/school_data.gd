class_name SchoolData
extends RefCounted
## The School's part of the profile (owner #68, spec §22.2; ProfileData.school): the grade the child picked (0 = not
## yet), whether a grown-up fixed it, and each unit's progress. Account-wide, offline-first, parsed field by field (a bad
## field falls back on its own), kept by the server backup's merge (merge_from never loses a star or a paid reward).
##
## A unit's progress has short keys (a child who practises every unit of every grade still keeps the profile small):
## l the lesson read, s stars (0-3, MasteryRules), r rounds finished, a answers, f answers right the first time,
## b the best round (percent), x the review step, d the day the next review is suggested, t the day last practised,
## m the day it was mastered, p its gold paid. Days are whole days of the device's calendar (SchoolClock), 0 = never.

const GRADES: Array[int] = [3, 4, 5, 6, 7, 8]   # grade 3 from owner #70 (2026-09-29: "start from grade 3")
const MAX_UNITS := 4000   # every subject of every grade (owner #70), and more to come
const MAX_COUNT := 999_999
const MAX_DAY := 1_000_000
const MAX_STEP := 9
const DEFAULTS := {"l": false, "s": 0, "r": 0, "a": 0, "f": 0, "b": 0, "x": 0, "d": 0, "t": 0, "m": 0, "p": false}
## The most each number may be (anything else is clamped into 0 … this).
const LIMITS := {"s": 3, "r": MAX_COUNT, "a": MAX_COUNT, "f": MAX_COUNT, "b": 100, "x": MAX_STEP, "d": MAX_DAY,
	"t": MAX_DAY, "m": MAX_DAY}

static var _id := RegEx.create_from_string("^g(1[0-2]|[1-9])\\.[a-z][a-z_]*\\.[a-z0-9_]+$")   # grades 1-12: the School grows (#70, #71)

var grade := 0
var grade_locked := false
## Unit id -> progress (only the keys that differ from DEFAULTS are stored).
var units := {}


static func valid_id(id: String) -> bool:
	return id.length() <= 64 and _id.search(id) != null


func is_empty() -> bool:
	return grade == 0 and not grade_locked and units.is_empty()


## A unit's progress with every key (a copy: change it with set_progress).
func progress(id: String) -> Dictionary:
	var out := DEFAULTS.duplicate()
	var stored: Variant = units.get(id)
	if stored is Dictionary:
		out.merge(stored, true)
	return out


func set_progress(id: String, p: Dictionary) -> void:
	if not valid_id(id) or (not units.has(id) and units.size() >= MAX_UNITS):
		return
	var clean := _clean(p)
	if clean.is_empty():
		units.erase(id)
	else:
		units[id] = clean


func to_dict() -> Dictionary:
	return {"grade": grade, "locked": grade_locked, "units": units.duplicate(true)}


static func from_dict(v: Variant) -> SchoolData:
	var s := SchoolData.new()
	if not v is Dictionary:
		return s
	var d: Dictionary = v
	var g: Variant = d.get("grade", 0)
	if typeof(g) in [TYPE_INT, TYPE_FLOAT] and float(g) == floorf(float(g)) and GRADES.has(int(g)):
		s.grade = int(g)
	s.grade_locked = d.get("locked") is bool and d.locked
	var u: Variant = d.get("units")
	if u is Dictionary:
		for id: Variant in u:
			if id is String and valid_id(id) and u[id] is Dictionary:
				s.set_progress(id, u[id])
	return s


## Keeps the best of both copies: every lesson read, star, count, best round and paid reward; the further review step
## (with its day); the grade this copy chose (the other's when this one has none); a grown-up's lock from either.
func merge_from(other: SchoolData) -> void:
	if grade == 0:
		grade = other.grade
	grade_locked = grade_locked or other.grade_locked
	for id: String in other.units:
		var a := progress(id)
		var b := other.progress(id)
		for k: String in ["s", "r", "a", "f", "b", "t"]:
			a[k] = maxi(int(a[k]), int(b[k]))
		a.l = bool(a.l) or bool(b.l)
		a.p = bool(a.p) or bool(b.p)
		if int(b.x) > int(a.x):
			a.x = b.x
			a.d = b.d
		elif int(b.x) == int(a.x):
			a.d = maxi(int(a.d), int(b.d))
		if int(a.m) == 0 or (int(b.m) > 0 and int(b.m) < int(a.m)):
			a.m = b.m   # the first day it was mastered: "remembered" means a later day than that
		set_progress(id, a)


## Only the keys of DEFAULTS, each a clean value, and none left at its default.
static func _clean(p: Dictionary) -> Dictionary:
	var out := {}
	for k: String in DEFAULTS:
		var v: Variant = p.get(k, DEFAULTS[k])
		var clean: Variant
		if DEFAULTS[k] is bool:
			clean = v is bool and v
		elif typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)):
			clean = clampi(int(v), 0, int(LIMITS[k]))
		else:
			clean = 0
		if clean != DEFAULTS[k]:
			out[k] = clean
	return out
