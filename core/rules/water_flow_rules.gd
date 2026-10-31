class_name WaterFlowRules
extends RefCounted
## Flowing water, as pure rules. Water falls first; on a floor it spreads sideways up to
## MAX_SPREAD blocks from where it started (falling keeps the distance, so a flood stays within that
## reach). Water never spreads onto the top of other water, so waterfalls merge into lakes. Flow
## starts when water is placed, or when a block next to water is broken; removing water never pulls
## water back (so players can clean up). Flowed water is plain static water (no drying up in M1b).

const MAX_SPREAD := 5
const MAX_FLOOD := 400      # cells one flood may fill before it stops
const _SIDES: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
const _FEEDERS: Array[Vector3i] = [Vector3i.UP, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]


## Water cells that start flowing after the block at pos changed from old_id to new_id.
## Entries are Vector4i(x, y, z, spread distance). block_at(pos) -> id, or -1 where not loaded.
static func sources_for_change(pos: Vector3i, old_id: int, new_id: int, block_at: Callable) -> Array[Vector4i]:
	var out: Array[Vector4i] = []
	if new_id == BlockIds.WATER and old_id != BlockIds.WATER:
		out.append(Vector4i(pos.x, pos.y, pos.z, 0))
	elif new_id == BlockIds.AIR and old_id != BlockIds.WATER and old_id != BlockIds.AIR:
		for d in _FEEDERS:
			var q := pos + d
			if block_at.call(q) == BlockIds.WATER:
				out.append(Vector4i(q.x, q.y, q.z, 0))
	return out


## One simulation step over the queue of flowing water cells (Vector4i: position + spread distance).
## Fills at most mini(budget, flood_left) cells. Returns {"fill": cells to turn into water now,
## "queue": the queue for the next step (unfinished cells first, then the new water)}.
static func step(queue: Array[Vector4i], block_at: Callable, budget: int, flood_left: int) -> Dictionary:
	var limit := mini(budget, flood_left)
	var fills: Array[Vector4i] = []
	var taken := {}
	var i := 0
	while i < queue.size() and fills.size() < limit:
		var targets := _targets(queue[i], block_at, taken)
		var room := limit - fills.size()
		for k in mini(room, targets.size()):
			fills.append(targets[k])
			taken[Vector3i(targets[k].x, targets[k].y, targets[k].z)] = true
		if targets.size() > room:
			break          # this cell is not finished: it stays at the front of the queue
		i += 1
	var rest: Array[Vector4i] = queue.slice(i)
	rest.append_array(fills)
	return {"fill": fills, "queue": rest}


static func _targets(c: Vector4i, block_at: Callable, taken: Dictionary) -> Array[Vector4i]:
	var out: Array[Vector4i] = []
	var p := Vector3i(c.x, c.y, c.z)
	var below := _id(p + Vector3i.DOWN, block_at, taken)
	if below == BlockIds.AIR:
		out.append(Vector4i(p.x, p.y - 1, p.z, c.w))       # falls first, keeping its distance
		return out
	if below < 0 or c.w >= MAX_SPREAD:
		return out                                           # unknown ground, or spent
	# Standing on water (a lake's surface, or a waterfall landing on one), water only pours into
	# places whose floor is not water: it fills a channel dug beside a lake, but never lays a
	# layer on top of the lake.
	var on_water := below == BlockIds.WATER
	for s in _SIDES:
		var n := p + s
		if _id(n, block_at, taken) != BlockIds.AIR:
			continue
		if on_water and _id(n + Vector3i.DOWN, block_at, taken) == BlockIds.WATER:
			continue
		out.append(Vector4i(n.x, n.y, n.z, c.w + 1))
	return out


static func _id(p: Vector3i, block_at: Callable, taken: Dictionary) -> int:
	return BlockIds.WATER if taken.has(p) else block_at.call(p)
