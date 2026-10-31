class_name TheaterSite
extends RefCounted
## Where the Shorts Theater stands (spec §5.12, §14.12; M3 Task 17): about 30 blocks from the world
## spawn, on flat, dry ground with no tree near it, its door facing the spawn. The same seed always
## gives the same place (the seed turns the search around the spawn), and the world save keeps it.
##
## The building is 9 × 9 blocks (HALF = 4 around the centre cell). Its nearest wall stays
## MIN_EDGE_FROM_SPAWN blocks from the spawn: past the spawn clearing, 12 blocks past Tilly's stall
## (TRADER_DISTANCE) and 4 past the Monster Totem (TOTEM_DISTANCE), whichever way those face. Known
## spots (`avoid`, e.g. the stall and the Totem once they are placed) keep KEEP_CLEAR blocks free.
##
## Sites are tried about 30 blocks out first (RADII), then further out (FAR_RADII), then once more
## with steeper ground allowed (RELAXED_STEP); a world with none of these (all sea and cliffs) has no
## Theater. Measured over 87 seeds: 75 about 30 blocks out, 12 at 38-48, none without one; at most
## 61 ms on this PC, once when the world is made (a LAN guest works it out when it joins).
##
## A site: {pos: Vector3i(centre x, floor y, centre z), facing: 0..3}. The floor is the highest
## ground under the building; a stone plinth (PLINTH_DEPTH deep) fills down to lower ground.
## facing: the door's side, 0 = +Z, 1 = +X, 2 = -Z, 3 = -X (the building's rotation in quarter turns).

const HALF := 4
const WALL_HEIGHT := 6
const PLINTH_DEPTH := 6      # the stone under the floor reaches this far down
const RADII: Array[int] = [30, 32, 28, 34, 36]   # about 30 blocks out, nearest to 30 first
const FAR_RADII: Array[int] = [38, 40, 42, 44, 46, 48]   # a coast or a forest around the spawn
const ANGLES := 48
const MAX_STEP := 2          # the ground under the building may differ by this much
const TREE_MARGIN := 2       # no tree this close to the walls (leaves reach 2 blocks)
## The last try, for a spawn among the sea, rivers and hills: steeper ground (the plinth fills it).
const RELAXED_STEP := 4
const APRON := 2             # dry ground this far in front of the door
const MIN_EDGE_FROM_SPAWN := 24
const TRADER_DISTANCE := 12  # M2 §12.7: Tilly's stall
const TOTEM_DISTANCE := 20   # M2 §12.8: the Monster Totem
const SPAWN_CLEAR := 16      # the spawn clearing (no secrets, no buildings)
const KEEP_CLEAR := 6
## Seen from the spawn, a known spot within LANDMARK_NEAR blocks of it (the stall, the Totem) keeps
## SIGHT_GAP degrees either side free, so the Theater never hides behind it (M2 dev log 19:30).
const LANDMARK_NEAR := 24.0
const SIGHT_GAP := 35.0


## The first good site around `spawn`, or {} if there is none. height_at(x, z) -> int is the ground
## height (the first empty y), is_dry(x, z) -> bool is land a building can stand on (no water, no
## river), has_tree(x, z) -> bool is a tree trunk there. avoid: Array of Vector2i spots to keep clear.
static func pick(spawn: Vector2i, world_seed: int, height_at: Callable, is_dry: Callable, has_tree: Callable,
		avoid: Array = []) -> Dictionary:
	var start := _start_angle(world_seed)
	var all_radii: Array[int] = []
	all_radii.append_array(RADII)
	all_radii.append_array(FAR_RADII)
	all_radii.sort()
	var tiers := [[RADII, MAX_STEP, TREE_MARGIN], [FAR_RADII, MAX_STEP, TREE_MARGIN],
		[all_radii, RELAXED_STEP, TREE_MARGIN]]
	for tier: Array in tiers:
		for r: int in tier[0]:
			for i in ANGLES:
				var a := TAU * float((start + i) % ANGLES) / ANGLES
				var c := spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
				var site := _try(c, spawn, height_at, is_dry, has_tree, avoid, tier[1], tier[2])
				if not site.is_empty():
					return site
	return {}


## pick() with the Green Meadows terrain rules and the world's first spawn (spec §21c: never on a colony's ground, the
## Moon's and Mars's flat ground round their domes).
static func pick_for(shape: MeadowsShape, avoid: Array = []) -> Dictionary:
	return pick(shape.spawn_column(), shape.seed, shape.height_at,
		func(x: int, z: int) -> bool: return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) \
			and not on_colony(shape, x, z),
		shape.tree_at, avoid)


## Spec §21c: (x, z) is on a space world's colony ground (a site there would stand in the colony). Cosmos: on Venus's
## cloud city the Theater stands only on the show deck (anywhere else is the homes', the gardens', the aliens' camp's);
## in Saturn's rings only on the show chunk.
static func on_colony(shape: MeadowsShape, x: int, z: int) -> bool:
	var space := shape as SpaceShape
	if space != null and space.venus != null:
		return not space.venus.show_spot(x, z)
	if space != null and space.rings != null:
		return not space.rings.show_spot(x, z)
	return space != null and space.colony != null and space.colony.covers(x, z, APRON)


## Spec §21c: a site saved before its world had a colony stands on the colony's ground (it is picked again).
static func stands_on_colony(shape: MeadowsShape, site: Dictionary) -> bool:
	if site.is_empty():
		return false
	var c: Vector3i = site.pos
	for d: Vector2i in [Vector2i.ZERO, Vector2i(HALF, HALF), Vector2i(-HALF, HALF), Vector2i(HALF, -HALF),
			Vector2i(-HALF, -HALF)]:
		if on_colony(shape, c.x + d.x, c.z + d.y):
			return true
	return false


static func door_dir(facing: int) -> Vector2i:
	match posmod(facing, 4):
		0:
			return Vector2i(0, 1)
		1:
			return Vector2i(1, 0)
		2:
			return Vector2i(0, -1)
	return Vector2i(-1, 0)


## The side of the building that looks most towards `to`.
static func facing_towards(from: Vector2i, to: Vector2i) -> int:
	var d := to - from
	if absi(d.x) > absi(d.y):
		return 1 if d.x > 0 else 3
	return 0 if d.y >= 0 else 2


## Distance from cell `p` to the nearest cell of the building centred on `center`.
static func edge_distance(center: Vector2i, p: Vector2i) -> float:
	var dx := maxi(absi(p.x - center.x) - HALF, 0)
	var dz := maxi(absi(p.y - center.y) - HALF, 0)
	return Vector2(dx, dz).length()


## True when feet at `pos` are in the Theater's room (inside the walls, not in the doorway).
static func is_inside(site: Dictionary, pos: Vector3) -> bool:
	if site.is_empty() or not pos.is_finite():
		return false
	var c: Vector3i = site.pos
	var inner := HALF - 1   # the room is the footprint minus the 1-block walls
	var lx := pos.x - (c.x + 0.5)
	var lz := pos.z - (c.z + 0.5)
	var ly := pos.y - c.y
	return absf(lx) < inner + 0.5 and absf(lz) < inner + 0.5 and ly >= -0.5 and ly < WALL_HEIGHT


static func to_save(site: Dictionary) -> Array:
	if site.is_empty():
		return []
	var p: Vector3i = site.pos
	return [p.x, p.y, p.z, int(site.facing)]


## The saved site, or {} if the save is broken (then it is placed again).
static func from_save(v: Variant) -> Dictionary:
	if not v is Array or (v as Array).size() != 4:
		return {}
	for n: Variant in v:
		if not typeof(n) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)) or float(n) != floorf(float(n)):
			return {}
	var facing := int(v[3])
	if facing < 0 or facing > 3:
		return {}
	return {"pos": Vector3i(int(v[0]), int(v[1]), int(v[2])), "facing": facing}


static func _start_angle(world_seed: int) -> int:
	var h := world_seed * 1103515245 + 12345
	h = h ^ (h >> 16)
	return posmod(h, ANGLES)


## Seen from the spawn, would a building at `c` stand right behind the landmark `a`?
static func _behind(c: Vector2i, a: Vector2i, spawn: Vector2i) -> bool:
	var to_a := Vector2(a - spawn)
	if to_a.length() > LANDMARK_NEAR or to_a.length() < 0.5:
		return false
	return rad_to_deg(absf(Vector2(c - spawn).angle_to(to_a))) < SIGHT_GAP


static func _try(c: Vector2i, spawn: Vector2i, height_at: Callable, is_dry: Callable, has_tree: Callable,
		avoid: Array, max_step: int, tree_margin: int) -> Dictionary:
	if edge_distance(c, spawn) < MIN_EDGE_FROM_SPAWN:
		return {}
	for a: Variant in avoid:
		if a is Vector2i and (edge_distance(c, a) < KEEP_CLEAR or _behind(c, a, spawn)):
			return {}
	# Quick look at the corners and the middle first: most spots on a hillside fail here.
	var lo := 1 << 30
	var hi := -(1 << 30)
	for o: Vector2i in [Vector2i.ZERO, Vector2i(-HALF, -HALF), Vector2i(HALF, -HALF), Vector2i(-HALF, HALF), Vector2i(HALF, HALF)]:
		var h: int = height_at.call(c.x + o.x, c.y + o.y)
		lo = mini(lo, h)
		hi = maxi(hi, h)
	if hi - lo > max_step:
		return {}
	for x in range(c.x - HALF, c.x + HALF + 1):
		for z in range(c.y - HALF, c.y + HALF + 1):
			if not is_dry.call(x, z):
				return {}
			var h: int = height_at.call(x, z)
			lo = mini(lo, h)
			hi = maxi(hi, h)
			if hi - lo > max_step:
				return {}
	var m := HALF + tree_margin
	for x in range(c.x - m, c.x + m + 1):
		for z in range(c.y - m, c.y + m + 1):
			if has_tree.call(x, z):
				return {}
	var facing := facing_towards(c, spawn)
	var door := door_dir(facing)
	var side := Vector2i(door.y, door.x)
	for step in range(HALF + 1, HALF + 1 + APRON):
		for s in range(-1, 2):
			var p := c + door * step + side * s
			if not is_dry.call(p.x, p.y) or has_tree.call(p.x, p.y):
				return {}
			if absi(int(height_at.call(p.x, p.y)) - hi) > max_step + 1:
				return {}
	return {"pos": Vector3i(c.x, hi, c.y), "facing": facing}
