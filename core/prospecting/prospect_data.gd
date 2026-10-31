class_name ProspectData
extends RefCounted
## Prospecting's part of the profile (spec §26; ProfileData.prospect): the quests this child has finished at least once
## (their first gold is paid once, like a School unit), how many deposits they found in every world, and today's gold
## from finding more (ProspectRewards: a cap a day, so it never becomes a grind). Account-wide; merge_from never loses a
## quest done or a find.

const MAX_FINDS := 100_000

## Quest kinds finished at least once, in the order they were first finished.
var done: Array[String] = []
var finds := 0
## {"d": day, "g": gold from finds that day}.
var today := {}


func is_empty() -> bool:
	return done.is_empty() and finds == 0


func has_done(kind: StringName) -> bool:
	return done.has(String(kind))


func to_dict() -> Dictionary:
	return {"done": done.duplicate(), "finds": finds, "today": today.duplicate()}


static func from_dict(v: Variant) -> ProspectData:
	var p := ProspectData.new()
	if not v is Dictionary:
		return p
	var d: Dictionary = v
	var list: Variant = d.get("done")
	if list is Array:
		for k: Variant in list:
			if k is String and DepositKinds.is_kind(StringName(k)) and not p.done.has(k):
				p.done.append(k)
	var n: Variant = d.get("finds")
	if typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)):
		p.finds = clampi(int(n), 0, MAX_FINDS)
	var t: Variant = d.get("today")
	if t is Dictionary:
		var day: Variant = (t as Dictionary).get("d")
		var g: Variant = (t as Dictionary).get("g")
		if typeof(day) in [TYPE_INT, TYPE_FLOAT] and typeof(g) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(day)) \
				and is_finite(float(g)) and float(day) >= 0 and float(g) >= 0 and float(g) <= EarnRules.PROSPECT_FIND_DAY_CAP:
			p.today = {"d": int(day), "g": int(g)}
	return p


## Keeps the best of both copies: every quest done, the bigger count of finds (today's gold stays this device's).
func merge_from(other: ProspectData) -> void:
	for k in other.done:
		if not done.has(k):
			done.append(k)
	finds = maxi(finds, other.finds)
