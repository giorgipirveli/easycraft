class_name TutorialData
extends RefCounted
## The profile's record of the tutorial with Pip (M3 Task 15, spec §14.9; ProfileData.tutorial): whether it was
## offered and what the child chose, the step a stopped tutorial goes on from, whether the reward was paid (once per
## profile) and whether SETTINGS asked for it again. Pure; from_dict never fails.

const NEW := &""                  # never started (an offer not answered is still new)
const STARTED := &"started"       # playing, or stopped: it goes on at `step`
const SKIPPED := &"skipped"       # SKIP: never asked again (SETTINGS can still play it)
const DONE := &"done"
const STATES: Array[StringName] = [NEW, STARTED, SKIPPED, DONE]
## How far each state is (the backup merge keeps the furthest).
const _RANK := {NEW: 0, STARTED: 1, SKIPPED: 2, DONE: 3}

var state: StringName = NEW
## The next step to play (TutorialRules' order) while STARTED.
var step := 0
var rewarded := false
## SETTINGS → PIP'S LESSONS: the next solo Survivor game starts it without asking.
var replay := false


static func from_dict(v: Variant) -> TutorialData:
	var t := TutorialData.new()
	if not v is Dictionary:
		return t
	var d: Dictionary = v
	var s := StringName(str(d.get("state", "")))
	t.state = s if STATES.has(s) else NEW
	var n: Variant = d.get("step", 0)
	if typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)):
		t.step = clampi(int(n), 0, TutorialRules.count() - 1)
	t.rewarded = d.get("rewarded") is bool and bool(d.rewarded)
	t.replay = d.get("replay") is bool and bool(d.replay)
	return t


func to_dict() -> Dictionary:
	return {"state": String(state), "step": step, "rewarded": rewarded, "replay": replay}


func is_empty() -> bool:
	return state == NEW and step == 0 and not rewarded and not replay


## The backup merge (ProfileBackup): a paid reward and a skip are never lost, the furthest step is kept.
func merge_from(other: TutorialData) -> void:
	if other == null:
		return
	if int(_RANK[other.state]) > int(_RANK[state]):
		state = other.state
		step = other.step
	elif other.state == state:
		step = maxi(step, other.step)
	rewarded = rewarded or other.rewarded
	replay = replay or other.replay
