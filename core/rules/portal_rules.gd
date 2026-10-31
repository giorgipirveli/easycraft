class_name PortalRules
extends RefCounted
## Portal frames and cores (M3 Task 5, spec §14.2), as pure rules. A portal is an upright ring of
## Portal Frame blocks round a doorway 1–3 wide and 2–3 high (the ring's corners are optional), with
## exactly one Portal Core in its bottom row. It is found from its core (find) and stays a portal while
## its ring is whole and its doorway open (frame_ok). Two cores link (PortalLinks); walking into one
## doorway brings you out in front of the other one, on the side with room and ground, never into a wall.
##
## A portal is a Dictionary {core: Vector3i, axis: AXIS_X (the doorway runs along X, faces ±Z) or AXIS_Z,
## lo: Vector3i (the doorway's lowest cell, lowest along its axis), size: Vector2i (width, height)} and,
## once worked out, exit: Vector3 (where a traveller arrives; INF = walled in).

const AXIS_X := 0
const AXIS_Z := 1
const MIN_WIDTH := 1
const MAX_WIDTH := 3
const MIN_HEIGHT := 2
const MAX_HEIGHT := 3
## Cells within this box round a core can change its frame or its exit (find looks no further).
const WATCH := Vector3i(MAX_WIDTH + 2, MAX_HEIGHT + 2, MAX_WIDTH + 2)
const IN_DEPTH := 0.8             # walking in: this close to the doorway's middle plane
const COOLDOWN := 1.0             # seconds before the same traveller can go again


## The portal whose core is at `core`, or {} when there is no whole frame round an open doorway there.
## block_at(cell: Vector3i) -> int.
static func find(core: Vector3i, block_at: Callable) -> Dictionary:
	if not is_core(int(block_at.call(core))):
		return {}
	for axis in [AXIS_X, AXIS_Z]:
		var along := _along(axis)
		for w in range(MIN_WIDTH, MAX_WIDTH + 1):
			for h in range(MIN_HEIGHT, MAX_HEIGHT + 1):
				for i in w:
					var p := {"core": core, "axis": axis, "lo": core + Vector3i.UP - along * i, "size": Vector2i(w, h)}
					if frame_ok(p, block_at):
						return p
	return {}


## The ring is whole (frame blocks, its core the only core) and the doorway open.
static func frame_ok(p: Dictionary, block_at: Callable) -> bool:
	if p.is_empty():
		return false
	var core: Vector3i = p.core
	for c in ring_cells(p):
		var id: int = block_at.call(c)
		if (not is_core(id)) if c == core else id != BlockIds.PORTAL_FRAME:
			return false
	for c in opening_cells(p):
		if BlockIds.is_solid(int(block_at.call(c))):
			return false
	return true


## The ring without its corners: the bottom row (the core is one of them) first, then the sides and top.
static func ring_cells(p: Dictionary) -> Array[Vector3i]:
	var along := _along(int(p.axis))
	var lo: Vector3i = p.lo
	var size: Vector2i = p.size
	var out: Array[Vector3i] = []
	for i in size.x:
		out.append(lo + along * i + Vector3i.DOWN)
	for j in size.y:
		out.append(lo - along + Vector3i(0, j, 0))
		out.append(lo + along * size.x + Vector3i(0, j, 0))
	for i in size.x:
		out.append(lo + along * i + Vector3i(0, size.y, 0))
	return out


static func opening_cells(p: Dictionary) -> Array[Vector3i]:
	var along := _along(int(p.axis))
	var lo: Vector3i = p.lo
	var size: Vector2i = p.size
	var out: Array[Vector3i] = []
	for i in size.x:
		for j in size.y:
			out.append(lo + along * i + Vector3i(0, j, 0))
	return out


## The middle of the doorway.
static func center(p: Dictionary) -> Vector3:
	var along := Vector3(_along(int(p.axis)))
	var size: Vector2i = p.size
	return Vector3(p.lo) + Vector3(0.5, 0.0, 0.5) + along * (size.x - 1) * 0.5 + Vector3(0, size.y * 0.5, 0)


## Which way the doorway faces (one of its two sides).
static func normal(p: Dictionary) -> Vector3i:
	return Vector3i(0, 0, 1) if int(p.axis) == AXIS_X else Vector3i(1, 0, 0)


## A traveller's feet in the doorway (anywhere across it, up to IN_DEPTH from its middle plane).
static func in_opening(feet: Vector3, p: Dictionary) -> bool:
	if p.is_empty() or not feet.is_finite():
		return false
	var lo: Vector3i = p.lo
	var size: Vector2i = p.size
	var local := feet - Vector3(lo)
	var across := local.x if int(p.axis) == AXIS_X else local.z
	var depth := (local.z if int(p.axis) == AXIS_X else local.x) - 0.5
	return across >= 0.0 and across <= float(size.x) and local.y >= -0.2 and local.y < float(size.y) - 0.5 \
		and absf(depth) <= IN_DEPTH


## Where a traveller comes out of portal p: in front of the doorway's middle, on the side with room for
## a body (2 blocks) and ground under it, else the side with room; INF when both sides are walled in.
static func exit_spot(p: Dictionary, block_at: Callable) -> Vector3:
	var along := _along(int(p.axis))
	var size: Vector2i = p.size
	var mid: Vector3i = p.lo + along * (size.x / 2)
	var n := normal(p)
	var roomy := Vector3.INF
	for side in [1, -1]:
		var cell: Vector3i = mid + n * side
		if BlockIds.is_solid(int(block_at.call(cell))) or BlockIds.is_solid(int(block_at.call(cell + Vector3i.UP))):
			continue
		var spot := Vector3(cell) + Vector3(0.5, 0.0, 0.5)
		if BlockIds.is_solid(int(block_at.call(cell + Vector3i.DOWN))):
			return spot
		if not roomy.is_finite():
			roomy = spot
	return roomy


## The yaw that looks from the doorway out over the exit (a traveller never faces back in).
static func exit_yaw(p: Dictionary, exit: Vector3) -> float:
	var d := exit - center(p)
	return atan2(-d.x, -d.z)


## Could a block change at `cell` change the frame of the core at `core`?
static func watches(core: Vector3i, cell: Vector3i) -> bool:
	var d := (cell - core).abs()
	return d.x <= WATCH.x and d.z <= WATCH.z and cell.y >= core.y - 2 and cell.y <= core.y + WATCH.y


static func _along(axis: int) -> Vector3i:
	return Vector3i(1, 0, 0) if axis == AXIS_X else Vector3i(0, 0, 1)

# --- Owner feedback #39: universe portals ------------------------------------------------------------------

## A block that can sit in a frame's core slot: the linking Portal Core, or a universe crystal's core (a universe
## portal: CrystalRules, PortalGates).
static func is_core(id: int) -> bool:
	return id == BlockIds.PORTAL_CORE or CrystalRules.is_universe_core(id)
