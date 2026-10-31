class_name LeafBeats
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.10; future-lessons.md §3.5, invisible assessment): the game
## never asks a question to check; it judges beats from what the leaf did, as the voyage plays, and each beat becomes one
## SkillShown event for the voyage's unit. The rules (the voyage's `judge` numbers):
## - blaze / the desert's day: the leaf never below `droop` in it, and in its second half at most `max_open` of the doors
##   open on average (two of six);
## - cloud: at least `min_sugar` built in it, and the doors' open share over its last 70 % at least `contrast` above
##   the blaze before it (contrast: random, always-open and always-closed cannot pass);
## - the desert's night: at least `night_open` of the doors open on average over its last 70 %;
## - the desert's dawn (a day's first `dawn` s): the leaf never below `droop` in it, and at most `dawn_doors` open when
##   it ends;
## - act 1 (B1): all doors shut and the leaf standing again, without a second ghost or SHOW ME (`act1_done`).
## Voiced turns, the trap and the evening are not judged (no beat names them); extra turns are judged by their kind.
## Help given while a beat is open (`help`) makes it HELPED (SHOWN when the ghost did it); a missed beat is HELPED too:
## neither is right the first time. A transfer voyage's passed beats are NEW_SETTING, noted with where they happened.

## The kinds of help: Hoot says the cue, the ghost does a step, SHOW ME, the "too dry" rescue; the ghost finished it.
const HINT := "hint"
const GHOST := "ghost"
const SHOW_ME := "show_me"
const RESCUE := "rescue"
const SHOWN_HELP := "shown"
const DEFAULT_JUDGE := {"droop": 0.55, "max_open": 0.34, "tail": 0.3, "half": 0.5, "min_sugar": 1.6, "contrast": 0.4,
	"night_open": 0.5, "dawn": 8.0, "dawn_doors": 2}

var voyage_id := ""
var unit := ""
var transfer := false
var setting := ""
## What the voyage's beats show (the lead's ruling on finding 2: the sunflower "the water-and-air balance", by the
## leaf's own feedback; the desert night "the weather idea", anticipating the cool), in each event's note.
var shows := ""
var judge := {}
## {id, rule, segment (its id), passed, kind (SkillShown's), help, note}, in the order they were judged.
var results: Array[Dictionary] = []

var _weather: LeafWeather
var _defs: Array[Dictionary] = []
var _acc := {}           # segment index -> Seg: what was seen in it
var _help := {}          # beat id -> the strongest help given while it was open
var _judged := {}        # beat id -> true
var _last_made := -1.0   # sugar after the last step seen
var _now := -1           # the segment of the last step seen
var _since := 0.0
var _tail := 0.3
var _half := 0.5
var _dawn := 8.0


## What was seen in one segment of the script (time-weighted, from each step's start).
class Seg:
	extends RefCounted
	var t := 0.0
	var min_w := 1.0
	var made_start := 0.0
	var made_end := 0.0
	var tail_open := 0.0
	var tail_t := 0.0
	var half_open := 0.0
	var half_t := 0.0
	var dawn_min_w := 1.0
	var dawn_open := 0
	var dawn_seen := false
	var dawn_done := false
	var doors := 6


static func for_voyage(id: String, weather: LeafWeather) -> LeafBeats:
	var v := LeafVoyages.voyage(id)
	var b := LeafBeats.new()
	b.voyage_id = id
	b.unit = str(v.get("unit", ""))
	b.transfer = bool(v.get("transfer", false))
	b.setting = str(v.get("setting", ""))
	b.shows = str(v.get("shows", ""))
	b.judge = DEFAULT_JUDGE.duplicate()
	b.judge.merge(v.get("judge", {}), true)
	for d: Dictionary in v.get("beats", []):
		b._defs.append(d)
	b._weather = weather
	b._tail = float(b.judge.tail)
	b._half = float(b.judge.half)
	b._dawn = float(b.judge.dawn)
	return b


## One step of the voyage was played: `w` is the weather at the step's start (LeafWeather.at), `sim` the leaf after the
## step. Returns the beats judged now (their windows ended).
func observe(w: Dictionary, sim: LeafSim, dt: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var index: int = w.get("index", -1)
	if index < 0:
		return out
	if index != _now and _now >= 0:
		out.append_array(_judge_segment(_now))
	_now = index
	_since = w.since
	var a := _seg(index, sim)
	var seconds: float = w.seconds
	var open := sim.doors.count(true)
	a.t += dt
	if sim.water < a.min_w:
		a.min_w = sim.water
	a.made_end = sim.made
	if _since >= _tail * seconds:
		a.tail_open += open * dt
		a.tail_t += dt
	if _since >= _half * seconds:
		a.half_open += open * dt
		a.half_t += dt
	if _since < _dawn:
		if sim.water < a.dawn_min_w:
			a.dawn_min_w = sim.water
		a.dawn_open = open
		a.dawn_seen = true
	elif not a.dawn_done:
		a.dawn_done = true
		out.append_array(_judge_dawn(index))
	_last_made = sim.made
	return out


## The voyage is over: what is left to judge (the last segment's beats).
func finish() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _now >= 0:
		out.append_array(_judge_dawn(_now))
		out.append_array(_judge_segment(_now))
	return out


## Act 1 is done (all doors shut, the leaf standing again): B1, SOLVED unless the ghost had to help again or SHOW ME
## was used (`helped`).
func act1_done(helped: bool) -> Dictionary:
	for d in _defs:
		if str(d.get("rule", "")) == "act1" and not _judged.has(str(d.id)):
			var note := "%s: shut every door after the demonstration" % str(d.id)
			return _add(d, "", true, GHOST if helped else "", note)
	return {}


## Help was given now (HINT, GHOST, SHOW_ME, RESCUE, or SHOWN_HELP when the ghost finished it): every beat open now is
## helped.
func help(kind: String) -> void:
	for d in _open_defs():
		var id := str(d.id)
		if kind == SHOWN_HELP or str(_help.get(id, "")) != SHOWN_HELP:
			_help[id] = kind


## The beats open now (their window holds the moment of the last step seen).
func open_now() -> Array[Dictionary]:
	return _open_defs()


## Whether a beat judges the script's segment `index` (the voiced turns, the trap and the evening teach: none does).
func judges(index: int) -> bool:
	return not _defs_for(index).is_empty()


## Every judged beat as a SkillShown event for the voyage's unit.
func record(shown: SkillShown) -> void:
	for r in results:
		shown.add(unit, str(r.kind), str(r.note))


## The judged beats passed with no help (what counts: SOLVED and NEW_SETTING).
func right_first() -> int:
	return results.filter(func(r: Dictionary) -> bool: return SkillShown.COUNTS.has(str(r.kind))).size()


# --- Judging -------------------------------------------------------------------------------------------------------

func _seg(index: int, sim: LeafSim) -> Seg:
	var a: Seg = _acc.get(index)
	if a == null:
		a = Seg.new()
		a.made_start = _last_made if _last_made >= 0.0 else sim.made
		a.made_end = a.made_start
		a.doors = sim.doors.size()
		_acc[index] = a
	return a


func _defs_for(index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if index < 0 or index >= _weather.segments.size():
		return out
	var seg := _weather.segments[index]
	var id := str(seg.get("id", ""))
	for d in _defs:
		if str(d.get("segment", "")) == id:
			out.append(d)
	if out.is_empty() and bool(seg.get("extra", false)):
		var kind := str(seg.kind)
		var n := id.trim_prefix(kind)
		out.append({"id": ("C" if kind == "cloud" else "Z") + n, "segment": id, "rule": kind})
	return out


func _open_defs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in _defs_for(_now):
		if _judged.has(str(d.id)):
			continue
		if str(d.rule) == "dawn" and _since >= float(judge.dawn):
			continue
		out.append(d)
	return out


func _judge_segment(index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _acc.has(index):
		return out
	var a: Seg = _acc[index]
	for d in _defs_for(index):
		if _judged.has(str(d.id)) or str(d.rule) == "dawn":
			continue
		var r := _rule(str(d.rule), index, a)
		out.append(_add(d, str(d.segment), bool(r[0]), str(_help.get(str(d.id), "")), str(r[1])))
	return out


func _judge_dawn(index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _acc.has(index):
		return out
	var a: Seg = _acc[index]
	for d in _defs_for(index):
		if str(d.rule) != "dawn" or _judged.has(str(d.id)) or not a.dawn_seen:
			continue
		var droop := float(judge.droop)
		var ok := a.dawn_min_w >= droop and a.dawn_open <= int(judge.dawn_doors)
		var note := "%s: %d doors open as the dawn ended, the stem at %.2f at its driest" % [d.id, a.dawn_open,
			a.dawn_min_w]
		out.append(_add(d, str(d.segment), ok, str(_help.get(str(d.id), "")), note))
	return out


## [passed, note] for a rule over a segment's record.
func _rule(rule: String, index: int, a: Seg) -> Array:
	var doors := maxi(a.doors, 1)
	var droop := float(judge.droop)
	var longer := bool(_weather.segments[index].get("longer", false))
	var tag := " (long window)" if longer else ""
	match rule:
		"blaze", "day":
			var share := a.half_open / (a.half_t * doors) if a.half_t > 0.0 else 0.0
			var ok := a.min_w >= droop and share <= float(judge.max_open)
			return [ok, "%.2f of the doors open in its second half, the leaf at %.2f at its driest%s" % [share, a.min_w,
				tag]]
		"cloud":
			var share := _tail_share(a, doors)
			var before := _blaze_share_before(index)
			var made := a.made_end - a.made_start
			var ok := made >= float(judge.min_sugar) - 0.0001 and share - before >= float(judge.contrast) - 0.0001
			return [ok, "opened %.2f more than in the blaze before, %.1f sugar built%s" % [share - before, made, tag]]
		"night":
			var share := _tail_share(a, doors)
			return [share >= float(judge.night_open) - 0.0001, "%.2f of the doors open through the night%s" % [share,
				tag]]
	return [false, "no rule %s" % rule]


func _tail_share(a: Seg, doors: int) -> float:
	return a.tail_open / (a.tail_t * doors) if a.tail_t > 0.0 else 0.0


## The open share over the last 70 % of the latest blaze before segment `index` (0 when there was none).
func _blaze_share_before(index: int) -> float:
	for i in range(index - 1, -1, -1):
		if str(_weather.segments[i].kind) == "blaze" and _acc.has(i):
			var a: Seg = _acc[i]
			return _tail_share(a, maxi(a.doors, 1))
	return 0.0


func _add(d: Dictionary, segment: String, passed: bool, help_kind: String, note: String) -> Dictionary:
	var kind := SkillShown.HELPED
	if help_kind == SHOWN_HELP:
		kind = SkillShown.SHOWN
	elif passed and help_kind == "":
		kind = SkillShown.NEW_SETTING if transfer else SkillShown.SOLVED
	var body := note.trim_prefix(str(d.id) + ":").trim_prefix(str(d.id)).strip_edges()
	if not passed:
		body = "missed: " + body
	if help_kind != "":
		body += " [help: %s]" % help_kind
	var parts := PackedStringArray()
	if shows != "":
		parts.append(shows)
	if transfer and setting != "":
		parts.append(setting)
	var about := ", ".join(parts)
	var r := {"id": str(d.id), "rule": str(d.get("rule", "")), "segment": segment, "passed": passed, "kind": kind,
		"help": help_kind, "note": "%s (%s) %s" % [d.id, about, body] if about != "" else "%s %s" % [d.id, body]}
	results.append(r)
	_judged[str(d.id)] = true
	return r
