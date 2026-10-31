class_name TutorialCourse
extends RefCounted
## "Pip's playground" (M3 Task 15, spec §14.9): where the tutorial's steps happen in the real world near the spawn,
## as pure rules. A straight course on a level pad, `a` blocks along its direction and `s` blocks to its side:
##   a -1..1  the start (plain ground)          a 2..7   the hole to jump (6 wide, 2 deep)
##   a 8..10  the landing                        a 11..13 the hole to bridge (3 across)
##   a 16     the wall (2 high)                  a 18..19 two bushes (s 2), a 20 the Workbench (s -2)
##   a 22     where the practice slime comes from
## The site: level, dry ground (no water, river or cave mouth in or around it), no tree trunk on it (a tree beside it
## keeps its trunk; leaves over the pad are cleared while it stands and come back),
## the whole course inside the treasure pack's spawn circle (TreasurePlaces.CLEAR_OF_SPAWN: no treasure place ever
## stands there), clear of the spawn and of the landmarks near it (`avoid`: Tilly, the Totem, the stone circle, the
## Theater, the quest giver). The most level site nearest the spawn wins; the pad fills dips and cuts bumps of at
## most TOLERANCES' last value. A site is {origin: Vector3i(x, the pad's feet level, z), dir: 0..3}.

const A_MIN := -1
const A_MAX := 22
const S_HALF := 2
const GAP_FROM := 2
const GAP_TO := 7
const LAND_FROM := 8
const LAND_TO := 10
const BRIDGE_FROM := 11
const BRIDGE_TO := 13
const WALL_A := 16
const WALL_HIGH := 2
const BUSHES: Array[Vector2i] = [Vector2i(18, 2), Vector2i(19, 2)]
const BENCH := Vector2i(20, -2)
const SLIME := Vector2i(22, 0)
const START := Vector2i(-1, 0)
const PIT_DEPTH := 2
## Cells from the pad up that are cleared (flowers, a bump) and down that may be filled (a dip).
const CLEAR_UP := 5
const FILL_DOWN := 4

const TREE_MARGIN := 0
const DRY_MARGIN := 1
const SPAWN_KEEP := 4.0           # the spawn column stays this far from the course
const RADII: Array[int] = [12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 33, 36]
const ANGLES := 24
## How far the pad may lie from the ground (a tolerance of t: the ground varies by at most 2t).
const TOLERANCES: Array[int] = [1, 2, 3, 4]
## +Z, +X, -Z, -X: the way the course runs.
const DIRS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]

## Zones for the jump (TutorialChecks.JumpWatch).
const OUTSIDE := 0
const NEAR := 1
const GAP := 2
const FAR := 3
const PIT := 4


static func dir_of(site: Dictionary) -> Vector2i:
	return DIRS[posmod(int(site.get("dir", 0)), 4)]


static func side_of(site: Dictionary) -> Vector2i:
	var d := dir_of(site)
	return Vector2i(-d.y, d.x)


static func level(site: Dictionary) -> int:
	return (site.origin as Vector3i).y


static func column(site: Dictionary, a: int, s: int) -> Vector2i:
	var o: Vector3i = site.origin
	return Vector2i(o.x, o.z) + dir_of(site) * a + side_of(site) * s


static func cell(site: Dictionary, a: int, s: int, dy: int) -> Vector3i:
	var c := column(site, a, s)
	return Vector3i(c.x, level(site) + dy, c.y)


## The course's columns (a, s over the whole pad).
static func footprint(site: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for a in range(A_MIN, A_MAX + 1):
		for s in range(-S_HALF, S_HALF + 1):
			out.append(column(site, a, s))
	return out


static func bench(site: Dictionary) -> Vector3i:
	return cell(site, BENCH.x, BENCH.y, 0)


## A cell's middle at feet level: where the child stands.
static func spot(site: Dictionary, a: int, s: int) -> Vector3:
	return Vector3(cell(site, a, s, 0)) + Vector3(0.5, 0.0, 0.5)


static func start_pos(site: Dictionary) -> Vector3:
	return spot(site, START.x, START.y)


## Where step `id` happens (the arrow's target when the child is far off).
static func station(site: Dictionary, id: StringName) -> Vector3:
	match id:
		&"move", &"jump":
			return start_pos(site)
		&"bridge":
			return spot(site, LAND_FROM + 1, 0)
		&"wall":
			return spot(site, WALL_A - 1, 0)
		&"hide":
			return spot(site, BUSHES[0].x, BUSHES[0].y)
		&"craft":
			return spot(site, BENCH.x, BENCH.y + 1)
	return Vector3.INF


## The cells that glow for step `id` (BuildOutline).
static func outline(site: Dictionary, id: StringName) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	match id:
		&"jump":
			for a in range(LAND_FROM, LAND_TO + 1):
				for s in range(-S_HALF, S_HALF + 1):
					out.append(cell(site, a, s, -1))
		&"bridge":
			for a in range(BRIDGE_FROM, BRIDGE_TO + 1):
				out.append(cell(site, a, 0, -1))
		&"wall":
			for s in range(-S_HALF, S_HALF + 1):
				for dy in WALL_HIGH:
					out.append(cell(site, WALL_A, s, dy))
		&"hide":
			for b in BUSHES:
				out.append(cell(site, b.x, b.y, 0))
		&"craft":
			out.append(bench(site))
	return out


## [lowest corner, size] of the box holding every cell the course reads or changes (TutorialProps' plan, clearing and
## natural check, the bridge's and the wall's checks): one bulk copy of it serves them all.
static func box(site: Dictionary) -> Array:
	var r := _rect(site)
	var y0 := level(site)
	return [Vector3i(int(r.position.x), y0 - FILL_DOWN - 2, int(r.position.y)),
		Vector3i(int(r.size.x), FILL_DOWN + 2 + CLEAR_UP, int(r.size.y))]


## Course coordinates (a, s) of a world position's column.
static func local(site: Dictionary, pos: Vector3) -> Vector2i:
	var o: Vector3i = site.origin
	var rel := Vector2i(floori(pos.x) - o.x, floori(pos.z) - o.z)
	var d := dir_of(site)
	var side := side_of(site)
	return Vector2i(rel.x * d.x + rel.y * d.y, rel.x * side.x + rel.y * side.y)


## Which part of the course the feet are in (for the jump). This side of the hole is NEAR, also behind the pad (a
## child running down onto it from higher ground); anywhere past the hole is FAR, the bridge's hole too: a full triple
## jump carries about 12 blocks and may land in it (that child did cross the jump's hole). Beside it is OUTSIDE.
static func zone(site: Dictionary, feet: Vector3) -> int:
	var l := local(site, feet)
	if absi(l.y) > S_HALF or l.x > A_MAX:
		return OUTSIDE
	if l.x >= LAND_FROM:
		return FAR
	if l.x < GAP_FROM:
		return NEAR
	if feet.y < level(site) - 0.5:
		return PIT
	return GAP


## The feet stand on the course or within `margin` columns of it.
static func on_footprint(site: Dictionary, feet: Vector3, margin: int) -> bool:
	var l := local(site, feet)
	return l.x >= A_MIN - margin and l.x <= A_MAX + margin and absi(l.y) <= S_HALF + margin


# --- Where it goes ---

## The playground in a real world: `shape`'s terrain (dry: above the sea, no river, no cave mouth), trees, `avoid`
## ([{at: Vector2 (x, z), r: float}]: the landmarks near the spawn); accept(site) -> bool turns a site down (a
## child's build there).
static func pick_for(shape: MeadowsShape, spawn: Vector2i, avoid: Array, accept := Callable()) -> Dictionary:
	var caves := CaveShape.new(shape.seed)
	var is_dry := func(x: int, z: int) -> bool:
		return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) and not caves.entrance_open(x, z)
	return pick(spawn, shape.seed, shape.height_at, is_dry, shape.tree_at, avoid, accept)


## The first good site around `spawn` ({} when there is none): the most level first (TOLERANCES), then nearest
## the spawn (RADII), angles turned by the seed, the course running away from the spawn first.
## height_at(x, z) -> int is the ground's feet level, is_dry(x, z) -> bool, has_tree(x, z) -> bool (a trunk).
static func pick(spawn: Vector2i, world_seed: int, height_at: Callable, is_dry: Callable, has_tree: Callable,
		avoid: Array, accept := Callable()) -> Dictionary:
	var heights := {}
	var dry := {}
	var trees := {}
	var shapes := {}   # (start, dir) -> [lo, hi] or [] (no good: dry, trees, the circle, the landmarks)
	var start_step := absi(world_seed * 2654435 ^ 918273) % ANGLES
	for tol in TOLERANCES:
		for r in RADII:
			for i in ANGLES:
				var ang := TAU * float((start_step + i) % ANGLES) / ANGLES
				var c := spawn + Vector2i(roundi(cos(ang) * r), roundi(sin(ang) * r))
				for d in _dirs_from(c - spawn):
					var key := Vector3i(c.x, c.y, d)
					if not shapes.has(key):
						shapes[key] = _measure(c, d, spawn, height_at, is_dry, has_tree, avoid, heights, dry, trees)
					var m: Array = shapes[key]
					if m.is_empty() or int(m[1]) - int(m[0]) > 2 * tol:
						continue
					var site := {"origin": Vector3i(c.x, ceili((int(m[0]) + int(m[1])) / 2.0), c.y), "dir": d}
					if accept.is_valid() and not bool(accept.call(site)):
						shapes[key] = []
						continue
					return site
	return {}


## The four ways, the one most away from the spawn first.
static func _dirs_from(out: Vector2i) -> Array[int]:
	var order: Array[int] = [0, 1, 2, 3]
	order.sort_custom(func(x: int, y: int) -> bool:
		return Vector2(DIRS[x]).dot(Vector2(out)) > Vector2(DIRS[y]).dot(Vector2(out)))
	return order


## [lowest, highest] ground over the course starting at column c running dir d, or [] when it can't go there.
static func _measure(c: Vector2i, d: int, spawn: Vector2i, height_at: Callable, is_dry: Callable, has_tree: Callable,
		avoid: Array, heights: Dictionary, dry: Dictionary, trees: Dictionary) -> Array:
	var site := {"origin": Vector3i(c.x, 0, c.y), "dir": d}
	var rect := _rect(site)
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
		if (corner as Vector2).distance_to(Vector2(spawn) + Vector2(0.5, 0.5)) > TreasurePlaces.CLEAR_OF_SPAWN:
			return []
	if _dist_to_rect(Vector2(spawn) + Vector2(0.5, 0.5), rect) < SPAWN_KEEP:
		return []
	for e: Variant in avoid:
		if e is Dictionary and (e as Dictionary).get("at") is Vector2 \
				and _dist_to_rect(e.at, rect) < float((e as Dictionary).get("r", 0.0)):
			return []
	var lo := 1 << 30
	var hi := -(1 << 30)
	for x in range(int(rect.position.x) - DRY_MARGIN, int(rect.end.x) + DRY_MARGIN):
		for z in range(int(rect.position.y) - DRY_MARGIN, int(rect.end.y) + DRY_MARGIN):
			var k := Vector2i(x, z)
			if not dry.has(k):
				dry[k] = bool(is_dry.call(x, z))
			if not dry[k]:
				return []
			if x < int(rect.position.x) or x >= int(rect.end.x) or z < int(rect.position.y) or z >= int(rect.end.y):
				continue
			if not heights.has(k):
				heights[k] = int(height_at.call(x, z))
			lo = mini(lo, heights[k])
			hi = maxi(hi, heights[k])
			if hi - lo > 2 * TOLERANCES[-1]:
				return []
	for x in range(int(rect.position.x) - TREE_MARGIN, int(rect.end.x) + TREE_MARGIN):
		for z in range(int(rect.position.y) - TREE_MARGIN, int(rect.end.y) + TREE_MARGIN):
			var k := Vector2i(x, z)
			if not trees.has(k):
				trees[k] = bool(has_tree.call(x, z))
			if trees[k]:
				return []
	return [lo, hi]


## The course's columns as a rectangle [x, z) in world columns.
static func _rect(site: Dictionary) -> Rect2:
	var a := column(site, A_MIN, -S_HALF)
	var b := column(site, A_MAX, S_HALF)
	var lo := Vector2(mini(a.x, b.x), mini(a.y, b.y))
	var hi := Vector2(maxi(a.x, b.x), maxi(a.y, b.y))
	return Rect2(lo, hi - lo + Vector2.ONE)


static func _dist_to_rect(p: Vector2, r: Rect2) -> float:
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return q.distance_to(p)
