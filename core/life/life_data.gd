class_name LifeData
extends RefCounted
## Owner #112 (docs/design/life-skills.md §3, §7, §11; spec §27): Life's part of the profile (ProfileData.life). Kept in
## the profile so the existing backup carries it, and nothing else is sent anywhere. Parsed field by field (a bad field
## falls back on its own), limited in size (the server keeps profiles up to 1 MiB and 5000 keys an object).
## - track: the child's track ("" until picked: little 6-8, middle 9-11, big 12+); track_locked: a grown-up chose it.
## - region: the grown-up's region for the emergency number and the side of the road ("" = from the device: LifeRegion).
## - careful: the careful topics' switches (design §6), all off; nothing is behind them yet.
## - units: each Life unit's progress, with SchoolData's short keys (MasteryRules reads them). The Life units that are a
##   School unit keep their progress in the School's (one unit, one reward).
## - skills: each skill's (an Experience on a track: "<experience>.<track>") short keys: s the Passport's stamps (DONE |
##   SELF | EXPERT), r runs finished, b the first before-check's right answers (-1 never), q its questions, a the best
##   after-check (-1 never), l the latest after-check, t the day last played, d the day the next repeat is suggested, x
##   the repeat step, g its gold paid, w the seconds of the first finished run, c the day it was first done.
## - intensity (Life L3a, owner #118, design §14): the grown-up's choice for the dangerous Experiences: GENTLE (the
##   default) or REAL ("more real", only ever used on the Big track: intensity_for). Merged like the careful switches.
## Days are SchoolClock's whole days. First-time measurements stay on the device (LifeMeasure), never in here.

const TRACKS: Array[String] = ["little", "middle", "big"]
const DONE := 1     # Done it (with the coach's help)
const SELF := 2     # By myself (no hints)
const EXPERT := 4   # Expert (the harder version, no hints)
const CAREFUL_TOPICS: Array[String] = ["body_safety", "puberty", "consent", "crises", "substances"]
const GENTLE := "gentle"
const REAL := "real"
const INTENSITIES: Array[String] = [GENTLE, REAL]
## The only track a grown-up's "more real" reaches (12 and up).
const REAL_TRACK := "big"
const MAX_UNITS := 500
const MAX_SKILLS := 300
const MAX_QUESTIONS := 5
const MAX_SECONDS := 36_000
const SKILL_DEFAULTS := {"s": 0, "r": 0, "b": -1, "q": 0, "a": -1, "l": -1, "t": 0, "d": 0, "x": 0, "g": false, "w": 0,
	"c": 0}
const SKILL_LIMITS := {"s": DONE | SELF | EXPERT, "r": SchoolData.MAX_COUNT, "b": MAX_QUESTIONS, "q": MAX_QUESTIONS,
	"a": MAX_QUESTIONS, "l": MAX_QUESTIONS, "t": SchoolData.MAX_DAY, "d": SchoolData.MAX_DAY, "x": SchoolData.MAX_STEP,
	"w": MAX_SECONDS, "c": SchoolData.MAX_DAY}
## Keys that may be -1 ("never").
const MAY_BE_NEVER: Array[String] = ["b", "a", "l"]

static var _unit_re := RegEx.create_from_string("^life\\.[a-z][a-z_]*\\.[a-z0-9_]+$")
static var _skill_re := RegEx.create_from_string("^[a-z][a-z_]*\\.(little|middle|big)$")

var track := ""
var track_locked := false
var region := ""
var careful := {}
var intensity := GENTLE
var units := {}
var skills := {}
var success := SuccessData.new()   # owner #115: Success S2's goals, habit garden, people and stories (core/success)


static func valid_track(t: String) -> bool:
	return TRACKS.has(t)


static func valid_unit_id(id: String) -> bool:
	return id.length() <= 64 and _unit_re.search(id) != null


static func valid_skill_id(id: String) -> bool:
	return id.length() <= 64 and _skill_re.search(id) != null


func is_empty() -> bool:
	return track == "" and not track_locked and region == "" and careful.is_empty() and units.is_empty() \
		and skills.is_empty() and success.is_empty() and intensity == GENTLE   # owner #115, #118


## Life L3a: the intensity a try on `track` plays with: REAL only on the Big track when a grown-up chose it.
func intensity_for(t: String) -> String:
	return REAL if intensity == REAL and t == REAL_TRACK else GENTLE


func careful_on(topic: String) -> bool:
	return bool(careful.get(topic, false))


func set_careful(topic: String, on: bool) -> void:
	if not CAREFUL_TOPICS.has(topic):
		return
	if on:
		careful[topic] = true
	else:
		careful.erase(topic)


# --- Units (SchoolData's keys) ---

func unit(id: String) -> Dictionary:
	var out := SchoolData.DEFAULTS.duplicate()
	var stored: Variant = units.get(id)
	if stored is Dictionary:
		out.merge(stored, true)
	return out


func set_unit(id: String, p: Dictionary) -> void:
	if not valid_unit_id(id) or (not units.has(id) and units.size() >= MAX_UNITS):
		return
	var clean := _clean(p, SchoolData.DEFAULTS, SchoolData.LIMITS, [])
	if clean.is_empty():
		units.erase(id)
	else:
		units[id] = clean


# --- Skills (the Experiences on their tracks) ---

func skill(id: String) -> Dictionary:
	var out := SKILL_DEFAULTS.duplicate()
	var stored: Variant = skills.get(id)
	if stored is Dictionary:
		out.merge(stored, true)
	return out


func set_skill(id: String, p: Dictionary) -> void:
	if not valid_skill_id(id) or (not skills.has(id) and skills.size() >= MAX_SKILLS):
		return
	var clean := _clean(p, SKILL_DEFAULTS, SKILL_LIMITS, MAY_BE_NEVER)
	if clean.is_empty():
		skills.erase(id)
	else:
		skills[id] = clean


func has_stamp(id: String, stamp: int) -> bool:
	return int(skill(id).s) & stamp != 0


func to_dict() -> Dictionary:
	return {"track": track, "locked": track_locked, "region": region, "careful": careful.duplicate(),
		"intensity": intensity, "units": units.duplicate(true), "skills": skills.duplicate(true),
		"success": success.to_dict()}   # owner #115, #118


static func from_dict(v: Variant) -> LifeData:
	var d := LifeData.new()
	if not v is Dictionary:
		return d
	var src: Dictionary = v
	var t: Variant = src.get("track", "")
	if t is String and valid_track(t):
		d.track = t
	d.track_locked = src.get("locked") is bool and src.locked
	var r: Variant = src.get("region", "")
	if r is String and LifeRegion.valid(r):
		d.region = r
	var c: Variant = src.get("careful")
	if c is Dictionary:
		for topic: Variant in c:
			if topic is String and c[topic] is bool and c[topic]:
				d.set_careful(topic, true)
	var i: Variant = src.get("intensity", GENTLE)
	if i is String and INTENSITIES.has(i):
		d.intensity = i
	var u: Variant = src.get("units")
	if u is Dictionary:
		for id: Variant in u:
			if id is String and u[id] is Dictionary:
				d.set_unit(id, u[id])
	var k: Variant = src.get("skills")
	if k is Dictionary:
		for id: Variant in k:
			if id is String and k[id] is Dictionary:
				d.set_skill(id, k[id])
	d.success = SuccessData.from_dict(src.get("success"))   # owner #115
	return d


## Merges an older copy into this one (ProfileBackup.merge merges into the newer): every star, stamp, run, paid reward
## and best after-check is kept, the first before-check (the lower), the latest after-check from the copy that played
## last, the further repeat step; the track and the region when this copy has none; a grown-up's lock from either. The
## careful topics' switches stay this copy's (the grown-up's latest choice).
func merge_from(other: LifeData) -> void:
	if track == "":
		track = other.track
	if region == "":
		region = other.region
	track_locked = track_locked or other.track_locked
	for id: String in other.units:
		var a := unit(id)
		var b := other.unit(id)
		for key: String in ["s", "r", "a", "f", "b", "t"]:
			a[key] = maxi(int(a[key]), int(b[key]))
		a.l = bool(a.l) or bool(b.l)
		a.p = bool(a.p) or bool(b.p)
		_merge_step(a, b)
		if int(a.m) == 0 or (int(b.m) > 0 and int(b.m) < int(a.m)):
			a.m = b.m
		set_unit(id, a)
	for id: String in other.skills:
		var a := skill(id)
		var b := other.skill(id)
		a.s = int(a.s) | int(b.s)
		a.r = maxi(int(a.r), int(b.r))
		a.q = maxi(int(a.q), int(b.q))
		a.a = maxi(int(a.a), int(b.a))
		if int(a.b) < 0 or (int(b.b) >= 0 and int(b.b) < int(a.b)):
			a.b = b.b
		if int(b.t) > int(a.t) or int(a.l) < 0:
			if int(b.l) >= 0:
				a.l = b.l
		a.t = maxi(int(a.t), int(b.t))
		a.g = bool(a.g) or bool(b.g)
		if int(a.w) <= 0:
			a.w = b.w
		if int(a.c) == 0 or (int(b.c) > 0 and int(b.c) < int(a.c)):
			a.c = b.c
		_merge_step(a, b)
		set_skill(id, a)
	success.merge_from(other.success)   # owner #115: a kept day, a person met or a story read is never lost


## The further repeat step wins, with its day (on the same step, the later day).
static func _merge_step(a: Dictionary, b: Dictionary) -> void:
	if int(b.x) > int(a.x):
		a.x = b.x
		a.d = b.d
	elif int(b.x) == int(a.x):
		a.d = maxi(int(a.d), int(b.d))


## Only the keys of `defaults`, each a clean value (`never`'s keys may be -1), and none left at its default.
static func _clean(p: Dictionary, defaults: Dictionary, limits: Dictionary, never: Array) -> Dictionary:
	var out := {}
	for k: String in defaults:
		var v: Variant = p.get(k, defaults[k])
		var clean: Variant
		if defaults[k] is bool:
			clean = v is bool and v
		elif typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)):
			clean = clampi(int(v), -1 if never.has(k) else 0, int(limits[k]))
		else:
			clean = defaults[k]
		if clean != defaults[k]:
			out[k] = clean
	return out
