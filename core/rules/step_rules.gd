class_name StepRules
extends RefCounted
## Auto-step and unstuck, scaled to the body (Size Magic): a body of any size hops onto a 1-block
## ledge it walks into, and a body stuck in blocks moves up until its whole footprint has room.
## solid: func(cell: Vector3i) -> bool.

const PROBE_MARGIN := 0.35   # how far past the body's edge the ledge probe reaches
const EDGE := 0.01           # a body touching a block face is not standing in that block


## True when a body walking along dir meets a 1-block ledge with room for its whole height on top
## (clearance rows) and room above its head for the hop.
static func wants_step(feet: Vector3, dir: Vector3, radius: float, clearance: int, solid: Callable) -> bool:
	var ahead := feet + Vector3(dir.x, 0.0, dir.z).normalized() * (radius + PROBE_MARGIN)
	var ledge := Vector3i(floori(ahead.x), floori(feet.y + 0.1), floori(ahead.z))
	if not solid.call(ledge):
		return false
	for dy in range(1, clearance + 1):
		if solid.call(ledge + Vector3i(0, dy, 0)):
			return false
	return not solid.call(Vector3i(floori(feet.x), ledge.y + clearance, floori(feet.z)))


## Block columns (x, z) under a body of `radius` centred at feet: 1 to 4 for a normal player,
## up to 9 for a giant.
static func footprint(feet: Vector3, radius: float) -> Array[Vector2i]:
	var columns: Array[Vector2i] = []
	for x in range(floori(feet.x - radius + EDGE), floori(feet.x + radius - EDGE) + 1):
		for z in range(floori(feet.z - radius + EDGE), floori(feet.z + radius - EDGE) + 1):
			columns.append(Vector2i(x, z))
	return columns


## Unstuck: the first feet row from the current one up where every footprint column has
## `clearance` free rows (max_y if none).
static func first_free_y(feet: Vector3, radius: float, clearance: int, max_y: int, solid: Callable) -> int:
	var columns := footprint(feet, radius)
	var row_blocked := func(y: int) -> bool:
		for c in columns:
			if solid.call(Vector3i(c.x, y, c.y)):
				return true
		return false
	return SpawnRules.first_free_y(floori(feet.y + 0.01), row_blocked, max_y, clearance)
