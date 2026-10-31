class_name ProspectState
extends RefCounted
## Prospecting in one world (spec §26; saved in WorldMeta.prospect): the quests started here and the step each waits
## at (a quest leads to one of this world's deposits), the one being followed, the deposits found (marked on MY MAP),
## and the oil wells built with the drums they still hold. Fair fun: a quest waits where it was for as long as it
## likes; nothing is lost. Parsed field by field (a broken save gives an empty state).

const MAX_FOUND := 256
const MAX_WELLS := 64

## The quest being followed (a DepositKinds kind, &"" for none).
var active: StringName = &""
## kind -> {"deposit": id, "step": the step being done}.
var quests := {}
## Deposit ids found here, in the order they were found.
var found: Array[String] = []
## Oil deposit id -> drums of crude oil its well still holds.
var wells := {}


func is_empty() -> bool:
	return active == &"" and quests.is_empty() and found.is_empty() and wells.is_empty()


## Starts (or picks up again) the quest of `kind`, leading to deposit `deposit_id`; the one followed before waits.
func start(kind: StringName, deposit_id: String) -> bool:
	if not DepositKinds.is_kind(kind):
		return false
	if not quests.has(String(kind)):
		if not DepositRules.is_id(deposit_id) or not deposit_id.begins_with(String(kind) + ":"):
			return false
		quests[String(kind)] = {"deposit": deposit_id, "step": 0}
	active = kind
	return true


## Stops following the quest (it waits at its step).
func stop() -> void:
	active = &""


func has_quest(kind: StringName) -> bool:
	return quests.has(String(kind))


func deposit_of(kind: StringName) -> String:
	return str((quests.get(String(kind), {}) as Dictionary).get("deposit", ""))


func step_of(kind: StringName) -> int:
	return int((quests.get(String(kind), {}) as Dictionary).get("step", -1))


## The quest's step `step` is done: it moves on to the next (never back, never past `count`). The new step.
func advance(kind: StringName, step: int, count: int) -> int:
	var q: Variant = quests.get(String(kind))
	if not q is Dictionary or int(q.step) != step:
		return step_of(kind)
	q.step = mini(step + 1, count)
	return int(q.step)


## The quest is done: its deposit is found (on MY MAP from now on) and it can be told again (for the next deposit).
## The deposit's id, or "" when there was no such quest.
func finish(kind: StringName) -> String:
	var id := deposit_of(kind)
	if id == "":
		return ""
	quests.erase(String(kind))
	if active == kind:
		active = &""
	if not found.has(id) and found.size() < MAX_FOUND:
		found.append(id)
	if kind == DepositKinds.OIL and not wells.has(id) and wells.size() < MAX_WELLS:
		wells[id] = DepositRules.OIL_DRUMS
	return id


func is_found(deposit_id: String) -> bool:
	return found.has(deposit_id)


## Pumps one drum from an oil well: true while it has oil (a deposit is finite; the next quest finds another).
func pump(deposit_id: String) -> bool:
	var left := int(wells.get(deposit_id, 0))
	if left <= 0:
		return false
	wells[deposit_id] = left - 1
	return true


func drums_left(deposit_id: String) -> int:
	return int(wells.get(deposit_id, 0))


func to_dict() -> Dictionary:
	return {"active": String(active), "quests": quests.duplicate(true), "found": found.duplicate(),
		"wells": wells.duplicate()}


static func from_dict(v: Variant) -> ProspectState:
	var s := ProspectState.new()
	if not v is Dictionary:
		return s
	var d: Dictionary = v
	var q: Variant = d.get("quests")
	if q is Dictionary:
		for k: Variant in q:
			var e: Variant = q[k]
			if not (k is String and DepositKinds.is_kind(StringName(k)) and e is Dictionary):
				continue
			var dep: Variant = (e as Dictionary).get("deposit")
			var step: Variant = (e as Dictionary).get("step")
			if not dep is String or not DepositRules.is_id(dep) or not (dep as String).begins_with(k + ":"):
				continue
			if typeof(step) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(step)) or float(step) < 0 or float(step) > 32:
				continue
			s.quests[k] = {"deposit": dep, "step": int(step)}
	var a: Variant = d.get("active")
	if a is String and s.quests.has(a):
		s.active = StringName(a)
	var f: Variant = d.get("found")
	if f is Array:
		for id: Variant in f:
			if id is String and DepositRules.is_id(id) and not s.found.has(id) and s.found.size() < MAX_FOUND:
				s.found.append(id)
	var w: Variant = d.get("wells")
	if w is Dictionary:
		for id: Variant in w:
			var n: Variant = w[id]
			if id is String and DepositRules.is_id(id) and (id as String).begins_with("oil:") \
					and typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)) and s.wells.size() < MAX_WELLS:
				s.wells[id] = clampi(int(n), 0, DepositRules.OIL_DRUMS)
	return s
