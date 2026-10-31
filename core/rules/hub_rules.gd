class_name HubRules
extends RefCounted
## The portal hub's stone circle (M3 Task 5, spec §14.1): a ring of standing stones by every Survivor
## world's spawn. Walking into it opens the hub (the unlocked universes; tap one to travel there). It
## stands on dry, nearly level ground (a block up or down) a few steps from the spawn, clear of trees, Tilly's stall and the Totem,
## found from the world's seed and terrain rules alone, so every game of a LAN world agrees where.

## Rings tried, nearest first (Tilly stands at 12, the Totem at 20).
const RADII: Array[int] = [7, 6, 8, 5, 9, 10, 4, 11]
const ANGLE_STEPS := 32
const DRY_RADIUS := 2            # the 5 x 5 under the stones is dry, at most a block up or down
const CLEAR_RADIUS := 3          # no tree trunk this close (in columns) to the middle
const CLEAR_OF := 6.0            # this far from Tilly's stall and the Totem
const INSIDE := 1.7              # the middle, where walking in opens the hub
const INSIDE_HEIGHT := 1.6       # feet within this of the ground (not flying over it)
const LEAVE := 3.2               # walked this far away: it opens again next time
const STONES := 8
const STONE_RING := 2.6          # the stones' distance from the middle


## {pos: Vector3 (the middle, on the ground), yaw}. height_at(x, z) -> int, ground_ok(x, z) -> bool,
## tree_at(x, z) -> bool; avoid: places to keep CLEAR_OF away from. With no good spot, the first ring's.
static func circle_spot(world_seed: int, spawn: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable,
		avoid: Array[Vector3]) -> Dictionary:
	var start := absi(world_seed * 83492791 ^ 2654435) % ANGLE_STEPS
	for r in RADII:
		for i in ANGLE_STEPS:
			var c := _ring_cell(spawn, r, start + i)
			if _clear_of(c, avoid) and _good(c, height_at, ground_ok, tree_at):
				return _spot(c, spawn, height_at)
	for i in ANGLE_STEPS:
		var c := _ring_cell(spawn, RADII[0], start + i)
		if _clear_of(c, avoid):
			return _spot(c, spawn, height_at)
	return _spot(_ring_cell(spawn, RADII[0], start), spawn, height_at)


## The circle in a real world: clear of where Tilly's stall and the Totem go (from the same seed).
static func circle_for_world(world_seed: int, shape: MeadowsShape, spawn: Vector2i) -> Dictionary:
	var caves := CaveShape.new(world_seed)
	var ground_ok := func(x: int, z: int) -> bool:
		return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) and not caves.entrance_open(x, z)
	var stall: Vector3 = TraderRules.stall_for_world(world_seed, shape, spawn).pos
	var totem: Vector3 = WaveRules.totem_for_world(world_seed, shape, spawn, stall).pos
	var avoid: Array[Vector3] = [stall, totem]
	return circle_spot(world_seed, spawn, shape.height_at, ground_ok, shape.tree_at, avoid)


## Feet in the middle of the circle at `center`, on the ground.
static func inside(feet: Vector3, center: Vector3) -> bool:
	return feet.is_finite() and _flat(feet, center) <= INSIDE and absf(feet.y - center.y) <= INSIDE_HEIGHT


## Walked far enough away for the circle to open the hub again next time.
static func left(feet: Vector3, center: Vector3) -> bool:
	return not feet.is_finite() or _flat(feet, center) > LEAVE or absf(feet.y - center.y) > INSIDE_HEIGHT * 2.0


static func _ring_cell(spawn: Vector2i, r: int, step: int) -> Vector2i:
	var a := TAU * (step % ANGLE_STEPS) / ANGLE_STEPS
	return spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))


static func _good(c: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> bool:
	var h := int(height_at.call(c.x, c.y))
	for dx in range(-DRY_RADIUS, DRY_RADIUS + 1):
		for dz in range(-DRY_RADIUS, DRY_RADIUS + 1):
			if absi(int(height_at.call(c.x + dx, c.y + dz)) - h) > 1 or not ground_ok.call(c.x + dx, c.y + dz):
				return false
	for dx in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
		for dz in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
			if tree_at.call(c.x + dx, c.y + dz):
				return false
	return true


static func _clear_of(c: Vector2i, avoid: Array[Vector3]) -> bool:
	for p in avoid:
		if p.is_finite() and Vector2(c.x + 0.5 - p.x, c.y + 0.5 - p.z).length() < CLEAR_OF:
			return false
	return true


static func _spot(c: Vector2i, spawn: Vector2i, height_at: Callable) -> Dictionary:
	var d := Vector2(spawn - c)
	return {"pos": Vector3(c.x + 0.5, float(height_at.call(c.x, c.y)), c.y + 0.5), "yaw": atan2(-d.x, -d.y)}


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
