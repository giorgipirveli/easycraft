class_name LaunchSite
extends RefCounted
## Where a home world's Launch Site stands (spec §21d.1): placed like the Shorts Theater (TheaterSite) a short walk from
## the world spawn, on flat, dry ground with no tree near it, facing the spawn; never in the Theater's direction seen
## from the spawn (in front of it or hidden behind it) and never on it; the same seed always gives the same place and
## the world save keeps it (and whether its pad is stamped yet).
##
## The site is a concrete plaza (PLAZA_MIN … PLAZA_MAX in local cells, +Z towards the spawn, turned by `facing` like
## the Theater): the launch pad in its middle, 11 × 11 (the build square SQUARE_HALF × 2 + 1 = RocketCheck.PAD wide in
## a ring of yellow-and-black stripes), the service tower beside it and Mission Control with the Mission Board in
## front, facing the spawn. The pad is voxel blocks (stamped once: pad_changes) so friends build on it together; the
## tower and Mission Control are models nobody can break (LaunchBuildings).
##
## A site: {pos: Vector3i(the pad's middle x, the concrete's y, z), facing: 0..3}. The concrete lies on the highest
## ground under the plaza; a plinth fills down to lower ground (PLINTH_DEPTH at most). Rockets stand on it from y + 1.

const SQUARE_HALF := 4       # the build square: 9 × 9 (RocketCheck.PAD)
const PAD_HALF := 5          # with its ring of stripes: 11 × 11
const PLAZA_MIN := Vector2i(-13, -6)
const PLAZA_MAX := Vector2i(9, 6)
const PLINTH_DEPTH := 6
const CLEAR_UP := 16         # the natural check looks this far over the plaza (a tall tree's crown): nothing a child built
const CLEAR_MARGIN := 3      # ... and this far round it, where the stamp clears the trees too (their crowns reach 3)
## Trees and plants: the stamp clears them off the plaza (and trees round it) on a site that has them.
const TREE_KINDS: Array[int] = [BlockIds.LOG, BlockIds.LEAVES, BlockIds.BIRCH_LOG, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LOG,
	BlockIds.DARK_LEAVES, BlockIds.PINE_LOG, BlockIds.PINE_NEEDLES, BlockIds.PALM_LOG, BlockIds.PALM_LEAVES,
	BlockIds.CANDY_CANE, BlockIds.LOLLIPOP, BlockIds.MUSHROOM_STEM, BlockIds.GLOW_CAP, BlockIds.CACTUS, BlockIds.DEAD_BUSH,
	BlockIds.COTTON_CANDY, BlockIds.GLOW_MUSHROOM, BlockIds.FLOWERS, BlockIds.WHEAT, BlockIds.BUSH, BlockIds.LILY_PAD]
## Blocks the natural check lets by besides BotRules.NATURAL (the ground, trees and ores): plants and the pad's own.
const _WILD: Array[int] = [BlockIds.PAD_CONCRETE, BlockIds.PAD_STRIPE]
## The search's tiers: flat open ground first; then steeper ground (the plinth fills it) where trees are cleared.
const TIERS: Array = [[2, false], [4, true], [6, true]]
## Local cells (x, z): the service tower (3 × 3, behind the pad's right corner) and Mission Control (5 × 6, left of
## the pad); the board stands in front of Mission Control, its face towards the spawn.
const TOWER_MIN := Vector2i(6, -5)
const TOWER_MAX := Vector2i(8, -3)
const CONTROL_MIN := Vector2i(-12, -4)
const CONTROL_MAX := Vector2i(-8, 1)
const BOARD_AT := Vector2(-10.0, 3.0)    # the board's face (local, from the pad's middle cell's centre)
const BOARD_REACH := 3.2                 # walking up this close opens it
const BOARD_HEIGHT := 4.0                # feet this far above or below the plaza still count

const RADII: Array[int] = [36, 34, 38, 40, 32, 42, 44, 46]
const ANGLES := 48
const TREE_MARGIN := 2
const MIN_EDGE_FROM_SPAWN := 24   # past the spawn clearing, Tilly's stall (12) and the Monster Totem (20)
const MAX_FROM_SPAWN := 58.0      # inside the ring the generated places keep free (MeadowsPlaces.CLEAR_OF_SPAWN, 60)
const THEATER_CLEAR := 8          # blocks between the Theater's walls and the plaza
const SIGHT_GAP := 30.0           # degrees between the Theater and the site, seen from the spawn
const REJECTED_CLEAR := 30.0      # a site passed over (a child's build) keeps its neighbours' middles this far away


## The first good site around `spawn`, or {}. height_at(x, z) -> int is the first empty y (the ground's top + 1),
## is_dry(x, z) -> bool land to build on, has_tree(x, z) -> bool a trunk there; theater: the Theater's site ({} for
## none); avoid: Array of Vector2i spots to keep KEEP_CLEAR from.
static func pick(spawn: Vector2i, world_seed: int, height_at: Callable, is_dry: Callable, has_tree: Callable,
		theater: Dictionary = {}, avoid: Array = [], rejected: Array = []) -> Dictionary:
	var start := _start_angle(world_seed)
	for tier: Array in TIERS:
		for r in RADII:
			for i in ANGLES:
				var a := TAU * float((start + i) % ANGLES) / ANGLES
				var c := spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
				if _near_any(c, rejected, REJECTED_CLEAR):
					continue
				var site := _try(c, spawn, height_at, is_dry, has_tree, theater, avoid, int(tier[0]), bool(tier[1]))
				if not site.is_empty():
					return site
	return {}


## pick() with a home world's terrain rules (its first spawn) and its Theater; `rejected`: middles of sites passed over
## (a child's build stood there).
static func pick_for(shape: MeadowsShape, theater: Dictionary = {}, avoid: Array = [], rejected: Array = []) -> Dictionary:
	return pick(shape.spawn_column(), shape.seed, shape.height_at,
		func(x: int, z: int) -> bool: return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z),
		shape.tree_at, theater, avoid, rejected)


static func _near_any(c: Vector2i, spots: Array, r: float) -> bool:
	for a: Variant in spots:
		if a is Vector2i and Vector2(c - (a as Vector2i)).length() < r:
			return true
	return false


## The world cell (x, z) of the local cell `local` (+Z towards the spawn, turned by the site's facing).
static func to_world(site: Dictionary, local: Vector2i) -> Vector2i:
	var p: Vector3i = site.pos
	return Vector2i(p.x, p.z) + Vector2i(_turn(Vector2(local), int(site.facing)).round())


## A local point (from the pad's middle cell's centre) in the world at height y.
static func to_world_point(site: Dictionary, local: Vector2, y: float) -> Vector3:
	var p: Vector3i = site.pos
	var w := _turn(local, int(site.facing))
	return Vector3(p.x + 0.5 + w.x, y, p.z + 0.5 + w.y)


## The build square's corner cell on the rocket's first layer (the rocket's cells are relative to it, y up).
static func corner(site: Dictionary) -> Vector3i:
	var p: Vector3i = site.pos
	return Vector3i(p.x - SQUARE_HALF, p.y + 1, p.z - SQUARE_HALF)


## [[Vector3i, block id], …]: the plaza's concrete floor (the pad's stripes round the build square) at the site's y,
## and the plinth under it down to the ground (at most PLINTH_DEPTH).
static func pad_changes(site: Dictionary, height_at: Callable) -> Array:
	var p: Vector3i = site.pos
	var out: Array = []
	for lx in range(PLAZA_MIN.x, PLAZA_MAX.x + 1):
		for lz in range(PLAZA_MIN.y, PLAZA_MAX.y + 1):
			var w := to_world(site, Vector2i(lx, lz))
			var h: int = height_at.call(w.x, w.y)
			for y in range(maxi(h, p.y - PLINTH_DEPTH), p.y):
				out.append([Vector3i(w.x, y, w.y), BlockIds.PAD_CONCRETE])
			var ring := maxi(absi(lx), absi(lz)) == PAD_HALF
			out.append([Vector3i(w.x, p.y, w.y), BlockIds.PAD_STRIPE if ring else BlockIds.PAD_CONCRETE])
	return out


## [lowest corner, size] of the box the natural check reads: the plaza and CLEAR_MARGIN round it, from the plinth's
## bottom to CLEAR_UP over the floor.
static func natural_box(site: Dictionary) -> Array:
	var p: Vector3i = site.pos
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := -lo
	for c: Vector2i in [PLAZA_MIN, PLAZA_MAX, Vector2i(PLAZA_MIN.x, PLAZA_MAX.y), Vector2i(PLAZA_MAX.x, PLAZA_MIN.y)]:
		var w := to_world(site, c)
		lo = Vector2i(mini(lo.x, w.x), mini(lo.y, w.y))
		hi = Vector2i(maxi(hi.x, w.x), maxi(hi.y, w.y))
	lo -= Vector2i.ONE * CLEAR_MARGIN
	hi += Vector2i.ONE * CLEAR_MARGIN
	var bottom := p.y - PLINTH_DEPTH
	return [Vector3i(lo.x, bottom, lo.y), Vector3i(hi.x - lo.x + 1, p.y + CLEAR_UP - bottom + 1, hi.y - lo.y + 1)]


## The plaza and its margin hold only the world's own ground, trees, plants and air (and the pad's own concrete: a
## stamp cut short goes on), never a child's build. read(Vector3i) -> int is a block (one bulk copy of natural_box on a
## worker is fine).
static func natural(site: Dictionary, read: Callable) -> bool:
	var box := natural_box(site)
	var lo: Vector3i = box[0]
	var size: Vector3i = box[1]
	for x in range(lo.x, lo.x + size.x):
		for z in range(lo.z, lo.z + size.z):
			for y in range(lo.y, lo.y + size.y):
				var id: int = read.call(Vector3i(x, y, z))
				if id != BlockIds.AIR and not BotRules.NATURAL.has(id) and not _WILD.has(id) and not TREE_KINDS.has(id):
					return false
	return true


## [[Vector3i, AIR], …]: the trees and plants the stamp clears first: everything over the plaza's floor on the plaza,
## and the trees (TREE_KINDS) in the margin round it.
static func clear_changes(site: Dictionary, read: Callable) -> Array:
	var p: Vector3i = site.pos
	var box := natural_box(site)
	var lo: Vector3i = box[0]
	var size: Vector3i = box[1]
	var plaza := {}
	for lx in range(PLAZA_MIN.x, PLAZA_MAX.x + 1):
		for lz in range(PLAZA_MIN.y, PLAZA_MAX.y + 1):
			plaza[to_world(site, Vector2i(lx, lz))] = true
	var out: Array = []
	for x in range(lo.x, lo.x + size.x):
		for z in range(lo.z, lo.z + size.z):
			var on_plaza := plaza.has(Vector2i(x, z))
			for y in range(lo.y, lo.y + size.y):
				var at := Vector3i(x, y, z)
				var id: int = read.call(at)
				if id == BlockIds.AIR:
					continue
				if TREE_KINDS.has(id) or (on_plaza and y > p.y and not _WILD.has(id)):
					out.append([at, BlockIds.AIR])
	return out


## The Mission Board's face in the world (at the plaza's floor + 1).
static func board_position(site: Dictionary) -> Vector3:
	if site.is_empty():
		return Vector3.INF
	return to_world_point(site, BOARD_AT, (site.pos as Vector3i).y + 1)


## Feet at `feet` stand at the Mission Board (walking up to it opens it).
static func near_board(site: Dictionary, feet: Vector3) -> bool:
	if site.is_empty() or not feet.is_finite():
		return false
	var b := board_position(site)
	return Vector2(feet.x - b.x, feet.z - b.z).length() <= BOARD_REACH and absf(feet.y - b.y) <= BOARD_HEIGHT


static func to_save(site: Dictionary, stamped: bool) -> Array:
	if site.is_empty():
		return []
	var p: Vector3i = site.pos
	return [p.x, p.y, p.z, int(site.facing), 1 if stamped else 0]


## The saved site ({pos, facing, stamped}), or {} if the save is broken (then it is placed again).
static func from_save(v: Variant) -> Dictionary:
	if not v is Array or (v as Array).size() != 5:
		return {}
	for n: Variant in v:
		if not typeof(n) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)) or float(n) != floorf(float(n)):
			return {}
	var facing := int(v[3])
	if facing < 0 or facing > 3 or absf(float(v[0])) > 1e8 or absf(float(v[2])) > 1e8:
		return {}
	return {"pos": Vector3i(int(v[0]), int(v[1]), int(v[2])), "facing": facing, "stamped": int(v[4]) != 0}


static func _turn(v: Vector2, facing: int) -> Vector2:
	match posmod(facing, 4):
		1:
			return Vector2(v.y, -v.x)
		2:
			return Vector2(-v.x, -v.y)
		3:
			return Vector2(-v.y, v.x)
	return v


static func _start_angle(world_seed: int) -> int:
	var h := world_seed * 2654435761 + 97
	h = h ^ (h >> 13)
	return posmod(h, ANGLES)


static func _try(c: Vector2i, spawn: Vector2i, height_at: Callable, is_dry: Callable, has_tree: Callable,
		theater: Dictionary, avoid: Array, max_step: int, trees_ok: bool) -> Dictionary:
	var facing := TheaterSite.facing_towards(c, spawn)
	var site := {"pos": Vector3i(c.x, 0, c.y), "facing": facing}
	var cells: Array[Vector2i] = []
	for lx in range(PLAZA_MIN.x, PLAZA_MAX.x + 1):
		for lz in range(PLAZA_MIN.y, PLAZA_MAX.y + 1):
			cells.append(to_world(site, Vector2i(lx, lz)))
	# The corners first: most spots fail on distance, the Theater or a slope right there.
	var corners: Array[Vector2i] = [cells[0], cells[PLAZA_MAX.y - PLAZA_MIN.y], cells[cells.size() - 1],
		cells[cells.size() - 1 - (PLAZA_MAX.y - PLAZA_MIN.y)]]
	for k in corners:
		var d := Vector2(k - spawn).length()
		if d < MIN_EDGE_FROM_SPAWN or d > MAX_FROM_SPAWN:
			return {}
	if not theater.is_empty():
		var t := Vector2i((theater.pos as Vector3i).x, (theater.pos as Vector3i).z)
		if rad_to_deg(absf(Vector2(c - spawn).angle_to(Vector2(t - spawn)))) < SIGHT_GAP:
			return {}
		for k in corners:
			if TheaterSite.edge_distance(t, k) < THEATER_CLEAR:
				return {}
	var lo := 1 << 30
	var hi := -(1 << 30)
	for k in corners:
		var h: int = height_at.call(k.x, k.y)
		lo = mini(lo, h)
		hi = maxi(hi, h)
	if hi - lo > max_step:
		return {}
	for k in cells:
		if Vector2(k - spawn).length() < MIN_EDGE_FROM_SPAWN:
			return {}
		if not theater.is_empty() and TheaterSite.edge_distance(Vector2i((theater.pos as Vector3i).x,
				(theater.pos as Vector3i).z), k) < THEATER_CLEAR:
			return {}
		for a: Variant in avoid:
			if a is Vector2i and Vector2(k - (a as Vector2i)).length() < TheaterSite.KEEP_CLEAR:
				return {}
		if not is_dry.call(k.x, k.y):
			return {}
		var h: int = height_at.call(k.x, k.y)
		lo = mini(lo, h)
		hi = maxi(hi, h)
		if hi - lo > max_step:
			return {}
	if trees_ok:
		site.pos = Vector3i(c.x, hi, c.y)
		return site
	var lo_x := 1 << 30
	var hi_x := -(1 << 30)
	var lo_z := 1 << 30
	var hi_z := -(1 << 30)
	for k in cells:
		lo_x = mini(lo_x, k.x)
		hi_x = maxi(hi_x, k.x)
		lo_z = mini(lo_z, k.y)
		hi_z = maxi(hi_z, k.y)
	for x in range(lo_x - TREE_MARGIN, hi_x + TREE_MARGIN + 1):
		for z in range(lo_z - TREE_MARGIN, hi_z + TREE_MARGIN + 1):
			if has_tree.call(x, z):
				return {}
	site.pos = Vector3i(c.x, hi, c.y)
	return site
