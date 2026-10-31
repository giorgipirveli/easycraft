class_name QuestData
extends RefCounted
## A child's quests (owner #45a, spec §14.17), kept in the profile's progress (ProgressData.quests): the
## chain being followed, the chains started and waiting where they were, the stories done and the places
## they led to. The rules are QuestRules'; this is only the data, parsed field by field (a bad field falls
## back on its own). Nothing here has a date: no clock can make a story expire.

const MAX_PLACES := 64

## The chain being followed (&"" = none).
var active: StringName = &""
## chain id -> {"step": the step being done, "start": its counter when counting began (-1: waiting, not
## counting), "extra": counted before (a stop, a friend's help)}. Started and not done.
var chains := {}
## The stories done, in the order they were done (keepsakes and titles come from them).
var done: Array[String] = []
## Where the stories led: {"chain", "u" (universe), "seed" (the world), "x", "y", "z"} (the world map shows them).
var places: Array[Dictionary] = []


func is_empty() -> bool:
	return active == &"" and chains.is_empty() and done.is_empty() and places.is_empty()


func to_dict() -> Dictionary:
	return {"active": String(active), "chains": chains, "done": done, "places": places}


static func from_dict(v: Variant) -> QuestData:
	var q := QuestData.new()
	if not v is Dictionary:
		return q
	var src: Dictionary = v
	var dn: Variant = src.get("done")
	if dn is Array:
		for id: Variant in dn:
			if id is String and not QuestRules.chain(StringName(id)).is_empty() and not q.done.has(id):
				q.done.append(id)
	var ch: Variant = src.get("chains")
	if ch is Dictionary:
		for id: Variant in ch:
			var e: Variant = ch[id]
			if not (id is String and e is Dictionary) or q.done.has(id):
				continue
			var c := QuestRules.chain(StringName(id))
			if c.is_empty():
				continue
			var past_last := (c.steps as Array).size()   # every step done: the rewards wait (QuestDirector gives them)
			var start := ProgressData._int(e.get("start"), -1)
			q.chains[id] = {"step": clampi(ProgressData._int(e.get("step"), 0), 0, past_last),
				"start": start if start >= 0 else -1, "extra": maxi(ProgressData._int(e.get("extra"), 0), 0)}
	var a: Variant = src.get("active")
	if a is String and q.chains.has(a):
		q.active = StringName(a)
	var pl: Variant = src.get("places")
	if pl is Array:
		for p: Variant in pl:
			var place := clean_place(p)
			if not place.is_empty() and q.places.size() < MAX_PLACES:
				q.places.append(place)
	return q


## A whole place of a known chain, or {}.
static func clean_place(p: Variant) -> Dictionary:
	if not p is Dictionary:
		return {}
	var id: Variant = p.get("chain")
	if not id is String or QuestRules.chain(StringName(id)).is_empty():
		return {}
	var out := {"chain": id}
	for key: String in ["u", "seed"]:
		var n: Variant = p.get(key)
		if typeof(n) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)):
			return {}
		out[key] = int(n)
	for key: String in ["x", "y", "z"]:
		var n: Variant = p.get(key)
		if typeof(n) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)):
			return {}
		out[key] = clampf(float(n), -1.0e7, 1.0e7)
	return out


func has_place(chain_id: StringName) -> bool:
	for p in places:
		if p.chain == String(chain_id):
			return true
	return false


## The server backup's merge (ProfileBackup): every story done and every place of both; the chain being
## followed and the waiting ones stay this copy's (a story done in the other copy is no longer waiting).
func merge_from(other: QuestData) -> void:
	for id in other.done:
		if not done.has(id):
			done.append(id)
	for p in other.places:
		if not has_place(StringName(str(p.chain))) and places.size() < MAX_PLACES:
			places.append(p.duplicate())
	for id in done:
		chains.erase(id)
	if not chains.has(String(active)):
		active = &""
