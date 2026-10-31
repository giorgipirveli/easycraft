class_name FarmSite
extends RefCounted
## Where a Gold Farm stands (M3 Task 10): placed like a stamp. The child taps the ground; the tapped cell
## is the middle of the farm's front row, the farm reaches away from them and its barn door faces them.
## The footprint is 9 × 7 blocks around its centre cell (HALF_W, HALF_D): the barn (5 × 5) on the left,
## a yard in front of its door and the field (4 × 7) on the right. It needs flat ground (a column one
## block lower is filled by the barn's plinth) and open room over it (the barn's height over the barn,
## FIELD_ROOM over the rest). "Inside" is anywhere over the footprint, up to TOP above the floor.
## facing: the door's side, 0 = +Z, 1 = +X, 2 = -Z, 3 = -X (the building's quarter turns, as TheaterSite).

const HALF_W := 4                  # local x: -4..4
const HALF_D := 3                  # local z: -3..3; the door looks down +Z
const BARN_MIN := Vector2i(-4, -3) # the barn's columns (local x, z), inclusive
const BARN_MAX := Vector2i(0, 1)
const BARN_ROOM := 6               # free cells over the barn's columns
const FIELD_ROOM := 2              # free cells over the field and the yard
const MAX_DIP := 1
const TOP := 7.0                   # "inside" reaches this high over the floor
const BELOW := 1.0                 # ... and this far under it (a dip)


static func door_dir(facing: int) -> Vector2i:
	match posmod(facing, 4):
		0:
			return Vector2i(0, 1)
		1:
			return Vector2i(1, 0)
		2:
			return Vector2i(0, -1)
	return Vector2i(-1, 0)


## The facing whose door looks back along `forward` (the way the child looks, Blueprints.facing_for_yaw).
static func facing_for_forward(forward: Vector3i) -> int:
	var back := Vector2i(-forward.x, -forward.z)
	for f in 4:
		if door_dir(f) == back:
			return f
	return 0


## The centre cell of a farm whose front row's middle is `anchor` (the tapped cell).
static func center_for(anchor: Vector3i, facing: int) -> Vector3i:
	var d := door_dir(facing)
	return anchor - Vector3i(d.x, 0, d.y) * HALF_D


## A local column (x, z) of the farm centred on `center` as a world column (x, z).
static func to_world_cell(center: Vector3i, facing: int, local: Vector2i) -> Vector2i:
	var r: Vector2i
	match posmod(facing, 4):
		0:
			r = local
		1:
			r = Vector2i(local.y, -local.x)
		2:
			r = Vector2i(-local.x, -local.y)
		_:
			r = Vector2i(-local.y, local.x)
	return Vector2i(center.x, center.z) + r


## A world point in the farm's own space: x across, y up from the floor, z towards the door; the centre
## cell's middle is the origin.
static func to_local(center: Vector3i, facing: int, pos: Vector3) -> Vector3:
	var a := pos.x - (center.x + 0.5)
	var b := pos.z - (center.z + 0.5)
	var y := pos.y - center.y
	match posmod(facing, 4):
		0:
			return Vector3(a, y, b)
		1:
			return Vector3(-b, y, a)
		2:
			return Vector3(-a, y, -b)
	return Vector3(b, y, -a)


## Every world column (x, z) of the farm.
static func cells(center: Vector3i, facing: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(-HALF_W, HALF_W + 1):
		for z in range(-HALF_D, HALF_D + 1):
			out.append(to_world_cell(center, facing, Vector2i(x, z)))
	return out


static func is_barn(local: Vector2i) -> bool:
	return local.x >= BARN_MIN.x and local.x <= BARN_MAX.x and local.y >= BARN_MIN.y and local.y <= BARN_MAX.y


## Why a farm can't stand here ("" = it can): "farm_ground" (no flat, dry ground under it) or "farm_room"
## (something in the way). block_at(Vector3i) -> int reads the world (a box copied once).
static func refusal(center: Vector3i, facing: int, block_at: Callable) -> String:
	for x in range(-HALF_W, HALF_W + 1):
		for z in range(-HALF_D, HALF_D + 1):
			var w := to_world_cell(center, facing, Vector2i(x, z))
			var under := int(block_at.call(Vector3i(w.x, center.y - 1, w.y)))
			if not _ground(under):
				var lower := int(block_at.call(Vector3i(w.x, center.y - 2, w.y)))
				if not _open(under) or under == BlockIds.WATER or not _ground(lower):
					return "farm_ground"
			var room := BARN_ROOM if is_barn(Vector2i(x, z)) else FIELD_ROOM
			for y in range(center.y, center.y + room):
				if not _open(int(block_at.call(Vector3i(w.x, y, w.y)))):
					return "farm_room"
	return ""


## The box a refusal() check reads: [origin, size] (one copy of the world).
static func box(center: Vector3i) -> Array:
	var r := maxi(HALF_W, HALF_D)
	return [Vector3i(center.x - r, center.y - 1 - MAX_DIP, center.z - r), Vector3i(2 * r + 1, BARN_ROOM + 1 + MAX_DIP, 2 * r + 1)]


## True when feet at `pos` are over the farm (barn, yard or field).
static func is_inside(farm: Dictionary, pos: Vector3) -> bool:
	if not farm.has("pos") or not pos.is_finite():
		return false
	var l := to_local(farm.pos, int(farm.facing), pos)
	return absf(l.x) < HALF_W + 0.5 and absf(l.z) < HALF_D + 0.5 and l.y >= -BELOW and l.y <= TOP


## True when feet at `pos` stand where the barn's walls go (placing a farm there would trap them).
static func in_barn(farm: Dictionary, pos: Vector3) -> bool:
	if not farm.has("pos") or not pos.is_finite():
		return false
	var l := to_local(farm.pos, int(farm.facing), pos)
	return l.x > BARN_MIN.x - 0.8 and l.x < BARN_MAX.x + 0.8 and l.z > BARN_MIN.y - 0.8 and l.z < BARN_MAX.y + 0.8 \
		and l.y > -1.0 and l.y < BARN_ROOM


const _MESSAGES := {
	"farm_ground": "Find flat, dry ground for your farm!",
	"farm_room": "Something is in the way! Find an open spot for your farm.",
}


static func message(key: String) -> String:
	return _MESSAGES.get(key, "")


static func _ground(id: int) -> bool:
	return BlockIds.is_solid(id)


## Room a farm may take: air, or something bodies walk through (a bush); never water.
static func _open(id: int) -> bool:
	return id != BlockIds.WATER and not BlockIds.is_solid(id)
