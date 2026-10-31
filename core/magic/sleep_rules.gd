class_name SleepRules
extends RefCounted
## Where a sleeping buddy's blocks land. The footprint starts at the buddy's spot and rises over
## terrain (slopes), but a player standing in it means "step back" — blocks never trap anyone.

const MAX_RISE := 8


## Returns {"base": Vector3i} (world position of block offset 0,0,0) or {"error": code}.
static func find_base(buddy_pos: Vector3, size: Vector3i, blocks: Dictionary, is_solid: Callable,
		player_bodies: Array[AABB]) -> Dictionary:
	var start := Vector3i(roundi(buddy_pos.x - size.x * 0.5), roundi(buddy_pos.y), roundi(buddy_pos.z - size.z * 0.5))
	for dy in MAX_RISE + 1:
		var base := start + Vector3i(0, dy, 0)
		var fits := true
		for p: Vector3i in blocks:
			if is_solid.call(base + p):
				fits = false
				break
		if not fits:
			continue
		for p: Vector3i in blocks:
			var cell := AABB(Vector3(base + p), Vector3.ONE)
			for body in player_bodies:
				if body.intersects(cell):
					return {"error": "player_in_the_way"}
		return {"base": base}
	return {"error": "no_room"}


static func message(code: String) -> String:
	match code:
		"player_in_the_way":
			return "Step back so your buddy has room to sleep!"
		"no_room":
			return "No room here for your buddy to sleep. Try a flatter spot!"
		"too_far":
			return "Get closer to your buddy first!"
		"not_yours":
			return "That's a friend's buddy!"
		_:
			return ""
