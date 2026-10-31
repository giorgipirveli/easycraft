class_name BottleSpot
extends RefCounted
## Where a friend's bottle arrives (M4 Wave 3, agent I; research D5): floating on the water nearest to
## where the child starts playing, else on the nearest beach (sand open to the sky), else on the ground a
## few steps away. Bottles keep SPREAD blocks apart. Pure: the caller finds the water and sand cells
## (one bulk copy of the area, WorldService.copy_box + BotRules.find_in_buffer) and reads a few blocks
## through block_at(pos) -> id.

const WATER := &"water"
const BEACH := &"beach"
const GROUND := &"ground"
const RADIUS := 24           # blocks around the start the caller looks in
const SPREAD := 2.0          # blocks between two bottles
const FLOAT_Y := 0.8         # a floating bottle's centre above the water cell's bottom
const _CHECKED := 64         # candidates looked at (nearest first), so a big sea costs little


## `count` spots near `near` (the player's feet cell): [{"kind", "cell", "pos"}], nearest first.
static func find(near: Vector3i, count: int, water: Array[Vector3i], sand: Array[Vector3i], block_at: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_take(out, count, near, water, block_at, WATER, FLOAT_Y)
	_take(out, count, near, sand, block_at, BEACH, 1.25)
	var k := 0
	while out.size() < count and k < 60:   # a ring of spots a few steps around the player, then wider
		var r := 3.0 + 2.0 * floorf(k / 6.0)
		var angle := TAU * (k % 6) / 6.0
		var cell := near + Vector3i(roundi(r * cos(angle)), 0, roundi(r * sin(angle)))
		if _far_from(out, cell):
			out.append({"kind": GROUND, "cell": cell, "pos": Vector3(cell) + Vector3(0.5, 0.25, 0.5)})
		k += 1
	return out


static func _take(out: Array[Dictionary], count: int, near: Vector3i, cells: Array[Vector3i], block_at: Callable,
		kind: StringName, lift: float) -> void:
	if out.size() >= count or cells.is_empty():
		return
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return Vector3(a - near).length_squared() < Vector3(b - near).length_squared())
	for k in mini(sorted.size(), _CHECKED):
		var cell: Vector3i = sorted[k]
		if out.size() >= count:
			return
		if block_at.call(cell + Vector3i.UP) != BlockIds.AIR or not _far_from(out, cell):
			continue
		out.append({"kind": kind, "cell": cell, "pos": Vector3(cell) + Vector3(0.5, lift, 0.5)})


static func _far_from(out: Array[Dictionary], cell: Vector3i) -> bool:
	for s in out:
		if Vector3(s.cell - cell).length() < SPREAD:
			return false
	return true
