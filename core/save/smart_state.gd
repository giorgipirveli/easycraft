class_name SmartState
extends RefCounted
## A world's saved smart-block state (M3 Task 7), WorldMeta.smart:
## - "teleports": TeleportLinks.to_save (the pad pairs),
## - "courses": CourseBook.to_save (goals, best times, the best runs recorded for bots),
## - "power": [Vector3i, ...] cells the host looks at again when the world loads (buttons still pressed,
##   plates someone stood on when it was saved), at most MAX_POWER_CELLS.
## clean() never fails: whatever is broken reads as nothing.

const MAX_POWER_CELLS := 256
const _FAR := 100000000.0


static func clean(data: Variant) -> Dictionary:
	var d: Dictionary = data if data is Dictionary else {}
	return {"teleports": TeleportLinks.from_save(d.get("teleports")).to_save(),
		"courses": CourseBook.from_save(d.get("courses")).to_save(), "power": cells(d.get("power"))}


## The power cells, as Vector3i (saved as [x, y, z]); broken entries dropped.
static func cells(list: Variant) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if not list is Array:
		return out
	for v: Variant in list:
		if out.size() >= MAX_POWER_CELLS:
			break
		if v is Vector3i:
			out.append(v)
		elif v is Array and (v as Array).size() == 3 and (v as Array).all(_finite):
			out.append(Vector3i(int(v[0]), int(v[1]), int(v[2])))
	return out


## For world.json: the power cells as arrays.
static func to_json(d: Dictionary) -> Dictionary:
	var power := []
	for c in cells(d.get("power")):
		power.append([c.x, c.y, c.z])
	return {"teleports": d.get("teleports", []), "courses": d.get("courses", {}), "power": power}


static func _finite(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and absf(float(v)) < _FAR
