class_name VrBrickRules
extends RefCounted
## Owner #116 (2026-10-16 15:04: "using vr it should be possible to build a house for example like in real world, take
## brick or stones and put in apropriate place"; it overrides the research's R5 for the world itself; VR-HANDS,
## docs/devlog/parts/vr-r4-hands.md): hand building in the world, as pure rules. A block comes into the hand as a brick
## (from the shoulder bag, the wrist hotbar, or out of a wall); a life-size ghost shows the world cell it goes into: the
## cell the brick is in when that touches another block or the ground, or, pushed into a block, the cell before the face
## it went through (flush against it); only where the laser's own place could put it (air or water, in reach, never in a
## player). Blocks have no turn of their own in this game: the ghost is the grid's cube. World units (1 m a block).

## The brick's side in the hand (the child's metres) and its middle ahead of the palm.
const BRICK := 0.12
const AHEAD := 0.04
## A hand this close to a block's face (or in it) takes that block out with the grip (the child's metres).
const FACE_REACH := 0.05
## The grip this close to the wrist hotbar's strip takes its slot's block; the fingertip this close touches a slot.
const WRIST_GRIP := 0.06
const WRIST_TOUCH := 0.02
## No cell.
const NO_CELL := Vector3i(0, -1000000, 0)

const _SIDES: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.DOWN, Vector3i.UP, Vector3i.FORWARD,
	Vector3i.BACK]


## The world cell a brick whose middle is at `at` goes into (NO_CELL: none); `came_from` is where the hand was last in
## the air (or the head); `block_at(cell) -> id`.
static func ghost_cell(at: Vector3, came_from: Vector3, block_at: Callable) -> Vector3i:
	var c := Vector3i(at.floor())
	if BlockIds.is_solid(int(block_at.call(c))):
		var d := at - came_from
		if d.length() < 0.0001:
			return NO_CELL
		var solid := func(p: Vector3i) -> bool: return BlockIds.is_solid(int(block_at.call(p)))
		var hit := GridRay.cast(came_from, d.normalized(), d.length() + 0.01, solid)
		if hit == null or hit.previous_position == hit.position or hit.distance < 0.0001:
			return NO_CELL
		c = hit.previous_position
	return c if touching(c, block_at) else NO_CELL


## A solid block on one of the cell's six sides (the ground counts).
static func touching(cell: Vector3i, block_at: Callable) -> bool:
	for s in _SIDES:
		if BlockIds.is_solid(int(block_at.call(cell + s))):
			return true
	return false


## The laser's own place checks for a hand's brick: a block id (or a crystal), into air or water, touching a block, in
## reach of `eye`, never inside one of `bodies` (players' AABBs). The host checks again (Session).
static func may_place(cell: Vector3i, id: int, eye: Vector3, bodies: Array[AABB], block_at: Callable) -> bool:
	var block := CrystalRules.core_for_item(id) if CrystalRules.is_crystal(id) else id
	if not BlockIds.is_valid(block):
		return false
	var now := int(block_at.call(cell))
	if now != BlockIds.AIR and now != BlockIds.WATER:
		return false
	if not touching(cell, block_at) or not PlacementRules.in_reach(eye, cell):
		return false
	return PlacementRules.can_place(cell, bodies, block)


## The block a hand at `at` takes out with the grip: the one it is in, else the one whose face is within `reach` (world
## units); NO_CELL for none. Bedrock never comes out.
static func block_to_take(at: Vector3, block_at: Callable, reach: float = FACE_REACH) -> Vector3i:
	var c := Vector3i(at.floor())
	if _takeable(int(block_at.call(c))):
		return c
	var f := at - Vector3(c)
	var best := NO_CELL
	var best_d := reach
	for s in _SIDES:
		var d: float
		if s.x != 0:
			d = f.x if s.x < 0 else 1.0 - f.x
		elif s.y != 0:
			d = f.y if s.y < 0 else 1.0 - f.y
		else:
			d = f.z if s.z < 0 else 1.0 - f.z
		if d <= best_d and _takeable(int(block_at.call(c + s))):
			best_d = d
			best = c + s
	return best


static func _takeable(id: int) -> bool:
	return BlockIds.is_solid(id) and BlockIds.is_breakable(id)


## What the hand holds after taking `old` out of the world: the Survivor's drop for the pickaxe `tier` (AIR: too hard
## for it, nothing), else what placing it again uses (an open door is a door).
static func brick_id(old: int, survivor: bool, tier: int) -> int:
	if old == BlockIds.AIR:
		return BlockIds.AIR
	return GatherRules.drop(old, tier) if survivor else GatherRules.cost(old)


## The hotbar item `item` as a brick from the bag: itself when it is a block (or a crystal), else 0 (a tool, a weapon, a
## stamp, a treat: the laser's).
static func bag_brick(item: int) -> int:
	if PetRules.is_treat(item):
		return 0
	return item if BlockIds.is_valid(item) or CrystalRules.is_crystal(item) else 0


## The slot (of `slots`, canvas rects in order) under a canvas point `px` of the wrist's hotbar: the one it is in, else
## the nearest along the row within half a slot; -1 for none.
static func slot_at(px: Vector2, slots: Array[Rect2]) -> int:
	var best := -1
	var best_d := INF
	for i in slots.size():
		var r := slots[i]
		if r.has_point(px):
			return i
		var d := absf(px.x - r.get_center().x)
		if px.y >= r.position.y - r.size.y * 0.5 and px.y <= r.end.y + r.size.y * 0.5 and d <= r.size.x and d < best_d:
			best_d = d
			best = i
	return best
