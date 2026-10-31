class_name TourScout
extends RefCounted
## Pure helpers for the acceptance tour (tools/tour.gd): where a peak, water, a beach, level ground
## and a dry cave are near the spawn, from the world's generator rules alone, so the tour knows
## where to go before that terrain is loaded. Nearest first (rings around the centre).

const NO_COLUMN := Vector2i(-2147483647, -2147483647)
const NOT_FOUND := Vector3i(0, -9999, 0)
## water(): which water counts.
const ANY := -1
const SEA := 0       # oceans and lakes (not a river channel)
const RIVER := 1
const CEILING_SCAN := 32

var shape: MeadowsShape
var caves: CaveShape
var generator: MeadowsGenerator   # reference_block: the exact block (trees aside)


## terrain (owner #45b): the world's terrain version (WorldMeta.terrain): 2 is the wild meadows.
func _init(world_seed: int, terrain: int = 1) -> void:
	shape = MeadowsBiomeShape.new(world_seed) if terrain >= MeadowsBiomeShape.TERRAIN else MeadowsShape.new(world_seed)
	caves = CaveShape.new(world_seed)
	generator = MeadowsBiomeGenerator.new() if terrain >= MeadowsBiomeShape.TERRAIN else MeadowsGenerator.new()
	generator.world_seed = world_seed


## The highest column within `radius` of `center`: sampled every `step` blocks, then every block
## around the best sample. Returns Vector3i(x, ground height, z).
func peak(center: Vector2i, radius: int, step: int = 4) -> Vector3i:
	var best := Vector3i(center.x, shape.height_at(center.x, center.y), center.y)
	for dz in range(-radius, radius + 1, step):
		for dx in range(-radius, radius + 1, step):
			if dx * dx + dz * dz <= radius * radius:
				best = _higher(best, center.x + dx, center.y + dz)
	var coarse := best
	for dz in range(1 - step, step):
		for dx in range(1 - step, step):
			var x := coarse.x + dx
			var z := coarse.z + dz
			if (x - center.x) * (x - center.x) + (z - center.y) * (z - center.y) <= radius * radius:
				best = _higher(best, x, z)
	return best


## The column of water nearest to `center` (sampled every `step` blocks) that is at least `depth`
## blocks deep; `kind`: ANY, SEA or RIVER. NO_COLUMN when there is none within `radius`.
func water(center: Vector2i, radius: int, depth: int = 1, kind: int = ANY, step: int = 4) -> Vector2i:
	for r in range(0, radius + 1, step):
		var best := NO_COLUMN
		var best_d := INF
		for c in _ring(center, r, step):
			if shape.height_at(c.x, c.y) > MeadowsShape.SEA_LEVEL - depth:
				continue
			if kind != ANY and shape.is_river(c.x, c.y) != (kind == RIVER):
				continue
			var d := Vector2(c - center).length()
			if d < best_d:
				best = c
				best_d = d
		if best != NO_COLUMN:
			return best
	return NO_COLUMN


## A beach for "water flows into a dug hole": {"land": Vector2i, "water": Vector2i}, 4-neighbours,
## where land has a solid block at the waterline (y = SEA_LEVEL - 1) and water has water there.
## Found by walking from the nearest water back towards `center`; {} when there is none.
func shore(center: Vector2i, radius: int) -> Dictionary:
	var p := water(center, radius)
	if p == NO_COLUMN:
		return {}
	var y := MeadowsShape.SEA_LEVEL - 1
	while p != center:
		var d := center - p
		var next := p + (Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y)))
		if generator.reference_block(p.x, y, p.y) == BlockIds.WATER \
				and BlockIds.is_solid(generator.reference_block(next.x, y, next.y)):
			return {"land": next, "water": p}
		p = next
	return {}


## The nearest column (sampled every 2 blocks) in the middle of level, dry ground: every column
## within `half` blocks has the same height, none is a river, and no tree's leaves reach over it.
## Things placed or called there (animals, beds, practice targets) never end up inside a hillside
## or under a canopy. NO_COLUMN when none within `radius`.
func flat(center: Vector2i, radius: int, half: int = 2) -> Vector2i:
	for r in range(0, radius + 1, 2):
		for c in _ring(center, r, 2):
			if _is_flat(c, half):
				return c
	return NO_COLUMN


func _is_flat(c: Vector2i, half: int) -> bool:
	var h := shape.height_at(c.x, c.y)
	if h <= MeadowsShape.SEA_LEVEL + 1:
		return false
	# The corners first: most bumpy spots fail there, before the whole square is read.
	for d: Vector2i in [Vector2i(-half, -half), Vector2i(half, -half), Vector2i(-half, half), Vector2i(half, half)]:
		if shape.height_at(c.x + d.x, c.y + d.y) != h:
			return false
	for dz in range(-half, half + 1):
		for dx in range(-half, half + 1):
			var x := c.x + dx
			var z := c.y + dz
			if shape.height_at(x, z) != h or shape.is_river(x, z):
				return false
	var reach := half + MeadowsGenerator.TREE_REACH   # no leaves hang over it either
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			if shape.tree_at(c.x + dx, c.y + dz):
				return false
	return true


## A dry cave spot near `center` with the feet between y_min and y_max: air at the feet and the
## head, under a solid ceiling (so the cave mood turns on). Candidates come from the cave noise on
## its 4-block grid, nearest column first; each is checked block by block with reference_block.
## NOT_FOUND when there is none within `radius`.
func cave(center: Vector2i, radius: int, y_min: int, y_max: int) -> Vector3i:
	var cell := CaveShape.CELL
	var origin := Vector2i(center.x - posmod(center.x, cell), center.y - posmod(center.y, cell))
	var y_top := y_max - posmod(y_max, cell)
	for r in range(0, radius + 1, cell):
		for c in _ring(origin, r, cell):
			var h := shape.height_at(c.x, c.y)
			var near_water := CaveShape.is_near_water(h)
			var entrance := caves.entrance_open(c.x, c.y)
			for y in range(y_top, y_min - 1, -cell):
				if y > y_max:
					continue
				var v := caves.sample(c.x, y, c.y)   # a grid point: exactly value_at there
				if caves.decide(v, y, h, near_water, entrance) != BlockIds.AIR:
					continue
				var spot := Vector3i(c.x, y, c.y)
				if _room(spot):
					return spot
	return NOT_FOUND


func _room(spot: Vector3i) -> bool:
	if generator.reference_block(spot.x, spot.y, spot.z) != BlockIds.AIR \
			or generator.reference_block(spot.x, spot.y + 1, spot.z) != BlockIds.AIR:
		return false
	for dy in range(2, CEILING_SCAN + 1):
		if BlockIds.is_solid(generator.reference_block(spot.x, spot.y + dy, spot.z)):
			return true
	return false


func _higher(best: Vector3i, x: int, z: int) -> Vector3i:
	var h := shape.height_at(x, z)
	return Vector3i(x, h, z) if h > best.y else best


## The columns on the square ring at Chebyshev distance r from c, every `step` blocks.
static func _ring(c: Vector2i, r: int, step: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if r == 0:
		out.append(c)
		return out
	for d in range(-r, r + 1, step):
		out.append(c + Vector2i(d, -r))
		out.append(c + Vector2i(d, r))
	for d in range(-r + step, r, step):
		out.append(c + Vector2i(-r, d))
		out.append(c + Vector2i(r, d))
	return out
