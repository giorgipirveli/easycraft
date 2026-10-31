class_name CrewBadges
extends RefCounted
## Crew flights (spec §21d.6 phase 2): the crew badges a child earned by flying a mission with friends ("Crew of the Moon
## mission with Anna and Sam", CrewFlightRules.badge_words). Kept by the profile in MissionData.crews (backed up with it;
## the merge never loses one). The same crew (the same names, in any order) to the same world is one badge. Names are
## the ones the world showed (the host's word), cut to MAX_NAME; at most MAX badges (the oldest go first).

const MAX := 60
const MAX_NAME := 24
const MAX_MATES := 5

## Each: {"world": int, "with": Array[String] (sorted)}, oldest first.
var list: Array[Dictionary] = []


func is_empty() -> bool:
	return list.is_empty()


## A crew flew a mission to world u with `mates` (the other crew members' names): true when it is a new badge.
func add(u: int, mates: Array) -> bool:
	if not MissionRules.has_mission(u):
		return false
	var names := _clean(mates)
	if names.is_empty() or has(u, names):
		return false
	list.append({"world": u, "with": names})
	while list.size() > MAX:
		list.pop_front()
	return true


func has(u: int, mates: Array) -> bool:
	var names := _clean(mates)
	for b in list:
		if int(b.world) == u and b.with == names:
			return true
	return false


func for_world(u: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in list:
		if int(b.world) == u:
			out.append(b)
	return out


## Every badge's words, oldest first.
func words() -> Array[String]:
	var out: Array[String] = []
	for b in list:
		out.append(CrewFlightRules.badge_words(int(b.world), b.with))
	return out


func to_array() -> Array:
	var out: Array = []
	for b in list:
		out.append({"world": int(b.world), "with": (b.with as Array).duplicate()})
	return out


static func from_array(v: Variant) -> CrewBadges:
	var c := CrewBadges.new()
	if not v is Array:
		return c
	for row: Variant in v:
		if not row is Dictionary:
			continue
		var u: Variant = (row as Dictionary).get("world")
		var w: Variant = (row as Dictionary).get("with")
		if typeof(u) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(u)) or not w is Array:
			continue
		c.add(int(u), w)
	return c


## Keeps every badge of both copies.
func merge_from(other: CrewBadges) -> void:
	for b in other.list:
		add(int(b.world), b.with)


static func _clean(mates: Array) -> Array[String]:
	var out: Array[String] = []
	for n: Variant in mates:
		if not (n is String or n is StringName):
			continue
		var s := str(n).strip_edges().left(MAX_NAME)
		if s != "" and not out.has(s):
			out.append(s)
	out.sort()
	return out.slice(0, MAX_MATES)
