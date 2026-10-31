class_name ToolData
extends RefCounted
## Owner #117 (docs/design/life-skills.md §13 "The Tool Book", §11): the child's Tool Book in the profile
## (ProfileData.tools), so the existing backup carries it and nothing else is sent anywhere. Per tool (ToolBook ids
## only): s, its stamps (LifeData.DONE: Done it, with the coach's help; SELF: By myself, no hint; EXPERT: on an Expert
## try with no hint), and u, how many times it was used well. Parsed field by field, limited in size.

const MAX_TOOLS := 300
const MAX_USES := 100_000
const ALL_STAMPS := LifeData.DONE | LifeData.SELF | LifeData.EXPERT

## Tool id -> stamps.
var stamps := {}
## Tool id -> uses.
var uses := {}


func is_empty() -> bool:
	return stamps.is_empty() and uses.is_empty()


func stamps_of(id: String) -> int:
	return int(stamps.get(id, 0))


func uses_of(id: String) -> int:
	return int(uses.get(id, 0))


func has_stamp(id: String, stamp: int) -> bool:
	return stamps_of(id) & stamp != 0


## The tools used by the child alone at least once ("You can use 23 tools").
func can_use() -> int:
	var n := 0
	for id: String in stamps:
		if int(stamps[id]) & LifeData.SELF:
			n += 1
	return n


## A finished run's tool steps ([{tool, hinted}]): every tool gets Done it; By myself when none of its steps needed a
## hint; Expert too on an Expert try. Returns {tool: the stamps new this time}.
func record(entries: Array, expert: bool) -> Dictionary:
	var hinted := {}
	for e: Variant in entries:
		if not e is Dictionary:
			continue
		var id := str((e as Dictionary).get("tool", ""))
		if not ToolBook.has(id):
			continue
		hinted[id] = bool(hinted.get(id, false)) or bool((e as Dictionary).get("hinted", false))
		if stamps.size() < MAX_TOOLS or stamps.has(id):
			uses[id] = mini(uses_of(id) + 1, MAX_USES)
	var got := {}
	for id: String in hinted:
		if not stamps.has(id) and stamps.size() >= MAX_TOOLS:
			continue
		var bits := LifeData.DONE
		if not bool(hinted[id]):
			bits |= LifeData.SELF
			if expert:
				bits |= LifeData.EXPERT
		var before := stamps_of(id)
		stamps[id] = before | bits
		if stamps_of(id) != before:
			got[id] = stamps_of(id) & ~before
	return got


func to_dict() -> Dictionary:
	return {"s": stamps.duplicate(), "u": uses.duplicate()}


static func from_dict(v: Variant) -> ToolData:
	var d := ToolData.new()
	if not v is Dictionary:
		return d
	var s: Variant = (v as Dictionary).get("s")
	if s is Dictionary:
		for id: Variant in s:
			if d.stamps.size() >= MAX_TOOLS:
				break
			var bits: Variant = s[id]
			if id is String and ToolBook.has(id) and typeof(bits) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(bits)) \
					and int(bits) > 0:
				d.stamps[id] = clampi(int(bits), 0, ALL_STAMPS)   # as LifeData's stamps
	var u: Variant = (v as Dictionary).get("u")
	if u is Dictionary:
		for id: Variant in u:
			if d.uses.size() >= MAX_TOOLS:
				break
			var n: Variant = u[id]
			if id is String and ToolBook.has(id) and typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)) \
					and int(n) > 0:
				d.uses[id] = mini(int(n), MAX_USES)
	return d


## Merges an older copy into this one (ProfileBackup.merge): every stamp of both, the most uses.
func merge_from(other: ToolData) -> void:
	for id: String in other.stamps:
		if stamps.has(id) or stamps.size() < MAX_TOOLS:
			stamps[id] = stamps_of(id) | other.stamps_of(id)
	for id: String in other.uses:
		if uses.has(id) or uses.size() < MAX_TOOLS:
			uses[id] = maxi(uses_of(id), other.uses_of(id))
