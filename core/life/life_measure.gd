class_name LifeMeasure
extends RefCounted
## Owner #113 (docs/design/life-skills.md §10 "Measured"): each Experience step's success measured on the device: how
## often it is done without the coach's hint, how long it takes, and how the very first time went. Kept in its own file
## (PATH), never in the profile, so the backup never carries it and nothing is sent; the lead and the playtests read it
## from the device to redesign a step most children miss.
## steps: "<skill>/<step id>" -> {n runs that reached it, u done without a hint, s seconds in all, f the first time was
## unaided (1/0), ft the first time's seconds, m runs that tried its safe mistake first (Life L3a, owner #118: how often
## children try the wrong way), fm the first time did (1/0)}.

const PATH := "user://life_measure.json"
const VERSION := 1
const MAX_STEPS := 2000

var path := PATH
var steps := {}


func _init(file: String = PATH) -> void:
	path = file
	_load()


## A finished run's log (LifeRun.steps_log) for `skill`.
func note(skill: String, log_entries: Array[Dictionary]) -> void:
	for e in log_entries:
		var key := "%s/%s" % [skill, str(e.get("id", ""))]
		var first := not steps.has(key)
		if first and steps.size() >= MAX_STEPS:
			continue
		var st: Dictionary = steps.get(key, _blank())
		var unaided := not bool(e.get("hinted", false))
		var seconds := maxf(float(e.get("seconds", 0.0)), 0.0)
		var tried := int(e.get("mistakes", 0)) > 0
		st.n = int(st.n) + 1
		st.u = int(st.u) + (1 if unaided else 0)
		st.s = float(st.s) + seconds
		st.m = int(st.get("m", 0)) + (1 if tried else 0)
		if first:
			st.f = 1 if unaided else 0
			st.ft = seconds
			st.fm = 1 if tried else 0
		steps[key] = st


func step(skill: String, step_id: String) -> Dictionary:
	var st: Dictionary = _blank()
	st.merge(steps.get("%s/%s" % [skill, step_id], {}), true)
	return st


static func _blank() -> Dictionary:
	return {"n": 0, "u": 0, "s": 0.0, "f": 0, "ft": 0.0, "m": 0, "fm": 0}


## The share of runs that did the step without a hint (0..1; 0 when never reached).
func unaided_share(skill: String, step_id: String) -> float:
	var st := step(skill, step_id)
	return float(st.u) / float(st.n) if int(st.n) > 0 else 0.0


func save() -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"version": VERSION, "steps": steps}))
	f.close()
	return true


func _load() -> void:
	steps = {}
	if not FileAccess.file_exists(path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return
	var saved: Variant = (json.data as Dictionary).get("steps")
	if not saved is Dictionary:
		return
	for key: Variant in saved:
		var st: Variant = saved[key]
		if key is String and st is Dictionary and steps.size() < MAX_STEPS:
			steps[key] = {"n": maxi(int(st.get("n", 0)), 0), "u": maxi(int(st.get("u", 0)), 0),
				"s": maxf(float(st.get("s", 0.0)), 0.0), "f": int(st.get("f", 0)), "ft": maxf(float(st.get("ft", 0.0)), 0.0),
				"m": maxi(int(st.get("m", 0)), 0), "fm": int(st.get("fm", 0))}
