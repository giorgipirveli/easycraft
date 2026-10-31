class_name TraderRules
extends RefCounted
## Tilly the trader (M2 spec §12.7): where her stall stands and how close a player must be to trade.
## Survivor worlds only. The stall stands on level, dry ground 12 blocks from the world spawn,
## facing it, clear of trees; the spot is found from the world's seed and terrain rules alone (no
## loaded chunks needed), so the same world always puts her in the same place.

const STALL_DISTANCE := 12
## Rings tried when the 12-block ring has no good spot, nearest first.
const RADII: Array[int] = [12, 11, 13, 10, 14, 9, 15, 8, 16]
const ANGLE_STEPS := 48
const CLEAR_RADIUS := 3          # no tree trunk this close (in columns) to the stall's centre
const CHEST_HEIGHT := 1.1        # Tilly's chest above her feet: taps and reach aim here
const TAP_RADIUS := 0.8
const TAP_REACH := 6.0           # a player's eye to Tilly's chest
const HOST_REACH := 8.0          # the host's check, with slack for network lag


static func wants_trader(mode: StringName) -> bool:
	return mode == ModeRules.SURVIVOR


## {pos: Vector3 (feet, cell centre), yaw: float (front -Z towards the spawn)}.
## height_at(x, z) -> int: ground height; ground_ok(x, z) -> bool: dry land a stall may stand on;
## tree_at(x, z) -> bool: a tree trunk grows there. With no good spot anywhere, she still comes.
static func stall_spot(world_seed: int, spawn: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> Dictionary:
	var start := absi(world_seed * 73856093 ^ 19349663) % ANGLE_STEPS
	for r in RADII:
		for i in ANGLE_STEPS:
			var c := _ring_cell(spawn, r, start + i)
			if _good(c, height_at, ground_ok, tree_at):
				return _spot(c, spawn, height_at)
	return _spot(_ring_cell(spawn, STALL_DISTANCE, start), spawn, height_at)


## The stall in a real world: the generator's ground, never on beaches, rivers, sea or a cave mouth.
static func stall_for_world(world_seed: int, shape: MeadowsShape, spawn: Vector2i) -> Dictionary:
	var caves := CaveShape.new(world_seed)
	var ground_ok := func(x: int, z: int) -> bool:
		return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) and not caves.entrance_open(x, z)
	return stall_spot(world_seed, spawn, shape.height_at, ground_ok, shape.tree_at)


## A world's stall: a Survivor world gets one the first time (saved in `meta` from then on, so it
## never moves). Returns whether the world has a trader.
static func place_in(meta: WorldMeta, mode: StringName, shape: MeadowsShape, spawn: Vector2i) -> bool:
	if not wants_trader(mode):
		return false
	if not meta.has_trader():
		var spot := stall_for_world(meta.seed, shape, spawn)
		meta.trader_pos = spot.pos
		meta.trader_yaw = spot.yaw
	return true


## What the host's spawner sends everyone for the stall (Trader.setup).
static func spawn_data(meta: WorldMeta) -> Dictionary:
	return {"pos": meta.trader_pos, "yaw": meta.trader_yaw, "hint": not meta.trader_visited}


static func _ring_cell(spawn: Vector2i, r: int, step: int) -> Vector2i:
	var a := TAU * (step % ANGLE_STEPS) / ANGLE_STEPS
	return spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))


## 3 x 3 level, dry cells, and no trunk within CLEAR_RADIUS.
static func _good(c: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> bool:
	var h := int(height_at.call(c.x, c.y))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if int(height_at.call(c.x + dx, c.y + dz)) != h or not ground_ok.call(c.x + dx, c.y + dz):
				return false
	for dx in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
		for dz in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
			if tree_at.call(c.x + dx, c.y + dz):
				return false
	return true


static func _spot(c: Vector2i, spawn: Vector2i, height_at: Callable) -> Dictionary:
	var d := Vector2(spawn - c)
	return {"pos": Vector3(c.x + 0.5, float(height_at.call(c.x, c.y)), c.y + 0.5), "yaw": atan2(-d.x, -d.y)}


## Is a player's eye within `reach` of Tilly (feet at trader_pos)?
static func in_reach(eye: Vector3, trader_pos: Vector3, reach: float) -> bool:
	return eye.is_finite() and eye.distance_to(trader_pos + Vector3(0, CHEST_HEIGHT, 0)) <= reach


## How far along a tap ray (from, unit dir) Tilly is, or -1 if it misses her.
static func ray_hit(from: Vector3, dir: Vector3, trader_pos: Vector3) -> float:
	var center := trader_pos + Vector3(0, CHEST_HEIGHT, 0)
	var t := (center - from).dot(dir)
	if t <= 0.0 or (from + dir * t).distance_to(center) > TAP_RADIUS:
		return -1.0
	return t
