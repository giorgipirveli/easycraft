class_name FrostShape
extends MeadowsShape
## Pure terrain rules for Frostpeak (M3 Task 3, spec §14.1), a MeadowsShape every world system can use
## (height_at, is_river, tree_at, spawn_column, ...): snowy valleys (snowy grass over dirt), stone peaks with
## a cap of snow (cliffs show their rock; frozen ore glitters in it), frozen lakes (ice at the banks' level
## over water), pine forests, and igloos: small snow-brick domes on flat valley ground (FrostSecretRules
## hides a room under some of them). No rivers and no open water: only lakes go below SEA_LEVEL, and ice
## covers them. Every rule is a function of world (x, z) and the seed, so chunks meet without seams;
## read-only after construction apart from the igloos' small cache behind a mutex (generator threads
## share one shape).

## What a column is (terrain_at, column().y).
const VALLEY := 0
const LAKE := 2
const PEAK := 3

const BASE := 34.0                # the valley floor's mean height
const BASE_SWELL := 5.0           # ... rolling this much up and down
const PEAK_HEIGHT := 46.0         # the highest ridge above the floor, inside a mountain range
const HILLS := 0.12               # outside the ranges the ridges are this share as high: low hills
const SNOW_LINE := 46             # ground this high is a peak: snow on stone
const TREE_LINE := 58             # no pines at or above this
const DIRT_DEPTH := 3             # dirt under a valley's snowy grass
const LAKE_CELL := 112            # at most one lake per cell of this size
const LAKE_PER_MILLE := 500
const LAKE_MIN_R := 8             # the ice's radius
const LAKE_MAX_R := 15
const LAKE_BANK := 5              # snowy banks this wide, rising two blocks
const LAKE_FADE := 12             # the valley flattens down to the banks this far out
const LAKE_MARGIN := LAKE_MAX_R + LAKE_BANK + LAKE_FADE + 1   # a lake never leaves its cell
const LAKE_BED_DEPTH := 5         # the deepest water under the middle of the ice
const LAKE_RANGE_CLEAR := -0.05   # no lake where the mountain-range noise is above this
const ORE_PER_MILLE := 60         # of peak columns: frozen ore 1-3 blocks under the snow
const NO_ORE := -0x7fffffff
const FOREST_FROM := 0.12         # forest noise above this is a pine forest ...
const FOREST_PER_MILLE := 45      # ... where this many columns in a thousand grow a pine
const OPEN_PER_MILLE := 4         # lone pines in the open
const IGLOO_CELL := 96            # at most one igloo per cell of this size
const IGLOO_PER_MILLE := 650
const IGLOO_R := 3                # the dome's radius: 7 x 7 blocks, 4 high
const IGLOO_FLAT := 2             # its ground rises and falls at most this much
const IGLOO_CLEAR := IGLOO_R + 2  # pines, secrets and spawns keep this far from its middle (tree_at)
const IGLOO_MARGIN := IGLOO_R + 3
const CACHE_LIMIT := 512
const SPAWN_FLAT := 3             # the spawn's 13 x 13 blocks rise and fall at most this much
## Every column's ground is below this (the highest floor plus the highest ridge): chunks above it are sky.
const TOP := int(BASE + BASE_SWELL + PEAK_HEIGHT) + 1
## Pines reach at most this far over the ground (the tallest trunk and its tip).
const PINE_TOP := 10
const DIRS: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0), Vector3i(0, 0, -1)]

var _base := FastNoiseLite.new()
var _range := FastNoiseLite.new()
var _ridges := FastNoiseLite.new()
var _forest := FastNoiseLite.new()
var _igloos := {}
var _mutex := Mutex.new()


func _init(world_seed: int) -> void:
	super(world_seed)
	_base.seed = world_seed + 21
	_base.frequency = 0.005
	_base.fractal_type = FastNoiseLite.FRACTAL_NONE
	_range.seed = world_seed + 22
	_range.frequency = 0.0025
	_range.fractal_type = FastNoiseLite.FRACTAL_NONE
	_ridges.seed = world_seed + 23
	_ridges.frequency = 0.008
	_ridges.fractal_octaves = 2
	_forest.seed = world_seed + 24
	_forest.frequency = 0.006
	_forest.fractal_type = FastNoiseLite.FRACTAL_NONE


func height_at(x: int, z: int) -> int:
	return column(x, z).x


func is_river(_x: int, _z: int) -> bool:
	return false


## VALLEY, LAKE (the ice and its banks) or PEAK.
func terrain_at(x: int, z: int) -> int:
	return column(x, z).y


## Where a child's feet stand in column (x, z): on a frozen lake, on its ice.
func surface_at(x: int, z: int) -> int:
	var col := column(x, z)
	return SEA_LEVEL if col.y == LAKE and col.x < SEA_LEVEL else col.x


## (height, kind, frozen ore's y or NO_ORE) of column (x, z): one call gives the generator everything.
func column(x: int, z: int) -> Vector3i:
	return column_near(x, z, _lake_near(x, z))


## column() with the lake of the column's LAKE_CELL cell already known (lake_of_cell: the generator looks
## each cell's lake up once per chunk).
func column_near(x: int, z: int, lake: Vector3i) -> Vector3i:
	var floor_h := BASE + BASE_SWELL * _base.get_noise_2d(x, z)
	var r := _range.get_noise_2d(x, z)
	var mask := HILLS + (1.0 - HILLS) * smoothstep(0.05, 0.4, r)
	var ridge := 1.0 - absf(_ridges.get_noise_2d(x, z))
	var h := floor_h + PEAK_HEIGHT * mask * ridge * ridge
	if lake.z > 0:
		var d := Vector2(x - lake.x, z - lake.y).length()
		if d >= lake.z + LAKE_BANK + LAKE_FADE:
			pass                       # out of its reach
		elif d < lake.z:
			var k := d / lake.z
			return Vector3i(clampi(int(lerpf(SEA_LEVEL - LAKE_BED_DEPTH, SEA_LEVEL - 1.0, k * k)), MIN_HEIGHT, MAX_HEIGHT), LAKE, NO_ORE)
		elif d < lake.z + LAKE_BANK:
			return Vector3i(SEA_LEVEL + int(2.0 * (d - lake.z) / LAKE_BANK), LAKE, NO_ORE)
		else:
			var bank_end := lake.z + LAKE_BANK
			h = lerpf(SEA_LEVEL + 2.0, h, smoothstep(bank_end, bank_end + LAKE_FADE, d))   # the valley comes down
	var hi := clampi(int(h), MIN_HEIGHT, MAX_HEIGHT)
	if hi < SNOW_LINE:
		return Vector3i(hi, VALLEY, NO_ORE)
	var k2 := absi(_hash(x * 13 - 5, z * 7 + 11)) % 1000
	return Vector3i(hi, PEAK, hi - 2 - k2 % 3 if k2 < ORE_PER_MILLE else NO_ORE)


## The lake of LAKE_CELL cell (cell_x, cell_z): (centre x, centre z, ice radius), or radius 0. One lake at
## most per cell, drawn from the seed; never in a mountain range.
func lake_of_cell(cell_x: int, cell_z: int) -> Vector3i:
	var h := _hash(cell_x * 7919 + 31, cell_z * 104729 + 17)
	if absi(h) % 1000 >= LAKE_PER_MILLE:
		return Vector3i.ZERO
	var span := LAKE_CELL - 2 * LAKE_MARGIN
	var cx := cell_x * LAKE_CELL + LAKE_MARGIN + absi(h >> 8) % span
	var cz := cell_z * LAKE_CELL + LAKE_MARGIN + absi(h >> 20) % span
	if _range.get_noise_2d(cx, cz) > LAKE_RANGE_CLEAR:
		return Vector3i.ZERO
	return Vector3i(cx, cz, LAKE_MIN_R + absi(h >> 32) % (LAKE_MAX_R - LAKE_MIN_R + 1))


## The lake whose reach (ice, banks, flattened valley) covers (x, z), or radius 0 (lake_of_cell, with the
## range noise read only when (x, z) is in reach).
func _lake_near(x: int, z: int) -> Vector3i:
	var cell_x := floori(x / float(LAKE_CELL))
	var cell_z := floori(z / float(LAKE_CELL))
	var h := _hash(cell_x * 7919 + 31, cell_z * 104729 + 17)
	if absi(h) % 1000 >= LAKE_PER_MILLE:
		return Vector3i.ZERO
	var span := LAKE_CELL - 2 * LAKE_MARGIN
	var cx := cell_x * LAKE_CELL + LAKE_MARGIN + absi(h >> 8) % span
	var cz := cell_z * LAKE_CELL + LAKE_MARGIN + absi(h >> 20) % span
	var r := LAKE_MIN_R + absi(h >> 32) % (LAKE_MAX_R - LAKE_MIN_R + 1)
	var reach := r + LAKE_BANK + LAKE_FADE
	if (x - cx) * (x - cx) + (z - cz) * (z - cz) >= reach * reach:
		return Vector3i.ZERO           # out of its reach: whether it exists does not matter here
	if _range.get_noise_2d(cx, cz) > LAKE_RANGE_CLEAR:
		return Vector3i.ZERO
	return Vector3i(cx, cz, r)


# --- Layers ------------------------------------------------------------------------------------

## The block at height y of column `col` (column()); bed: the bedrock's top there.
func block_in_column(y: int, col: Vector3i, bed: int = WORLD_BOTTOM) -> int:
	if y <= bed:
		return BlockIds.BEDROCK
	var h := col.x
	if y >= h:
		if y < SEA_LEVEL:
			return BlockIds.ICE if col.y == LAKE and y == SEA_LEVEL - 1 else BlockIds.WATER
		return BlockIds.AIR
	match col.y:
		PEAK:
			if y == h - 1:
				return BlockIds.SNOW
			if y == col.z:
				return BlockIds.FROZEN_ORE
		LAKE:
			if h < SEA_LEVEL:
				if y >= h - 2:
					return BlockIds.DIRT                  # the lake bed
			elif y == h - 1:
				return BlockIds.SNOWY_GRASS
			elif y >= h - 1 - DIRT_DEPTH:
				return BlockIds.DIRT
		_:
			if y == h - 1:
				return BlockIds.SNOWY_GRASS
			if y >= h - 1 - DIRT_DEPTH:
				return BlockIds.DIRT
	return BlockIds.STONE if y >= 0 else BlockIds.DEEPSTONE


## Frostpeak's layers when only the height is known (MeadowsShape's signature).
func column_block(y: int, height: int, bed_top: int = WORLD_BOTTOM) -> int:
	return block_in_column(y, Vector3i(height, PEAK if height >= SNOW_LINE else VALLEY, NO_ORE), bed_top)


## Where the plain stone ends in column `col`: the generator writes the layers from here up
## (FrostGenerator; equal to block_in_column: tested). A peak's frozen ore lies below it, in the stone.
func stone_top(col: Vector3i) -> int:
	match col.y:
		PEAK:
			return col.x - 1
		LAKE:
			return col.x - 2 if col.x < SEA_LEVEL else col.x - 1 - DIRT_DEPTH
	return col.x - 1 - DIRT_DEPTH


# --- Pines -------------------------------------------------------------------------------------

## Inside a pine forest (the forest noise).
func forest_at(x: int, z: int) -> bool:
	return _forest.get_noise_2d(x, z) > FOREST_FROM


## A pine grows here: often in forests, now and then in the open; never on a lake or its banks, at or
## above the tree line, or in an igloo's way.
func pine_at(x: int, z: int) -> bool:
	return pine_base(x, z) != NO_PINE


const NO_PINE := -0x7fffffff


## The ground a pine at (x, z) stands on (its first log's height), or NO_PINE (pine_at in one call).
func pine_base(x: int, z: int) -> int:
	var r := absi(_hash(x * 3 + 1, z * 5 - 2)) % 1000
	if r >= FOREST_PER_MILLE:
		return NO_PINE
	if r >= OPEN_PER_MILLE and not forest_at(x, z):
		return NO_PINE
	var col := column(x, z)
	if col.y == LAKE or col.x >= TREE_LINE or not igloo_near(x, z).is_empty():
		return NO_PINE
	return col.x


## A pine's trunk: 5 to 8 blocks.
func pine_height(x: int, z: int) -> int:
	return 5 + absi(_hash(z * 7 - 1, x * 11 + 3)) % 4


func tree_height(x: int, z: int) -> int:
	return pine_height(x, z)


## Trees are the pines, and igloos count as trees too (secrets, spawns and animals keep off them).
func tree_at(x: int, z: int) -> bool:
	return pine_at(x, z) or not igloo_near(x, z).is_empty()


# --- Igloos ------------------------------------------------------------------------------------

## The igloo whose middle is within IGLOO_CLEAR of (x, z) (sideways), or {}.
func igloo_near(x: int, z: int) -> Dictionary:
	var c0 := Vector2i(floori((x - IGLOO_CLEAR) / float(IGLOO_CELL)), floori((z - IGLOO_CLEAR) / float(IGLOO_CELL)))
	var c1 := Vector2i(floori((x + IGLOO_CLEAR) / float(IGLOO_CELL)), floori((z + IGLOO_CLEAR) / float(IGLOO_CELL)))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var ig := igloo_in_cell(Vector2i(cx, cz))
			if ig.is_empty():
				continue
			var c: Vector3i = ig.center
			if (x - c.x) * (x - c.x) + (z - c.z) * (z - c.z) <= IGLOO_CLEAR * IGLOO_CLEAR:
				return ig
	return {}


## The igloo of one IGLOO_CELL cell, or {} (shared: never change the returned dictionary): {cell, center
## (the floor's middle, where feet stand), dir (the doorway's side), boxes ([lo, hi exclusive, block id],
## later ones win), lo, hi}. On flat valley ground (a forest's pines keep clear of it); it stays inside its cell.
func igloo_in_cell(cell: Vector2i) -> Dictionary:
	_mutex.lock()
	var cached: Variant = _igloos.get(cell)
	_mutex.unlock()
	if cached != null:
		return cached
	var ig := _make_igloo(cell)
	_mutex.lock()
	if _igloos.size() >= CACHE_LIMIT:
		_igloos.clear()
	_igloos[cell] = ig
	_mutex.unlock()
	return ig


func _make_igloo(cell: Vector2i) -> Dictionary:
	var h := _hash(cell.x * 6271 + 101, cell.y * 92821 - 37)
	if absi(h) % 1000 >= IGLOO_PER_MILLE:
		return {}
	var span := IGLOO_CELL - 2 * IGLOO_MARGIN
	var x := cell.x * IGLOO_CELL + IGLOO_MARGIN + absi(h >> 8) % span
	var z := cell.y * IGLOO_CELL + IGLOO_MARGIN + absi(h >> 20) % span
	var col := column(x, z)
	if col.y != VALLEY:
		return {}
	var g := col.x
	for off: Vector2i in [Vector2i(-4, 0), Vector2i(4, 0), Vector2i(0, -4), Vector2i(0, 4)]:
		var c := column(x + off.x, z + off.y)
		if c.y != VALLEY or absi(c.x - g) > IGLOO_FLAT:
			return {}
	var dir := DIRS[absi(h >> 32) % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var c := Vector3i(x, g, z)
	var r := IGLOO_R
	var boxes: Array = []
	for y in range(g - 3, g):                                   # a foundation and the floor
		SecretRules._disc(boxes, Vector3i(x, y, z), r, BlockIds.PACKED_SNOW)
	for y in [g, g + 1]:                                        # the dome: walls, a smaller ring, a cap
		SecretRules._disc(boxes, Vector3i(x, y, z), r, BlockIds.SNOW_BRICK)
	SecretRules._disc(boxes, Vector3i(x, g + 2, z), r - 1, BlockIds.SNOW_BRICK)
	SecretRules._disc(boxes, Vector3i(x, g + 3, z), r - 2, BlockIds.SNOW_BRICK)
	for y in [g, g + 1]:                                        # room inside
		SecretRules._disc(boxes, Vector3i(x, y, z), r - 1, BlockIds.AIR)
	SecretRules._disc(boxes, Vector3i(x, g + 2, z), r - 2, BlockIds.AIR)
	SecretRules._box(boxes, c + dir * r, c + dir * r + Vector3i.UP, BlockIds.AIR)                    # the doorway
	SecretRules._box(boxes, c - dir * r + Vector3i.UP, c - dir * r + Vector3i.UP, BlockIds.ICE_LANTERN)   # a lantern
	SecretRules._box(boxes, c + side * r + Vector3i.UP, c + side * r + Vector3i.UP, BlockIds.FROSTED_GLASS)  # a window
	var lo := Vector3i(x - r, g - 3, z - r)
	return {"cell": cell, "center": c, "dir": dir, "boxes": boxes, "lo": lo, "hi": Vector3i(x + r + 1, g + 4, z + r + 1)}


## The block igloo `ig` puts at p, or -1 where it puts nothing.
static func igloo_block(p: Vector3i, ig: Dictionary) -> int:
	if ig.is_empty() or not SecretRules._contains(ig.lo, ig.hi, p):
		return -1
	var boxes: Array = ig.boxes
	for i in range(boxes.size() - 1, -1, -1):
		if SecretRules._contains(boxes[i][0], boxes[i][1], p):
			return boxes[i][2]
	return -1


## The block an igloo puts at p, or -1 (the generator's reference).
func igloo_block_at(p: Vector3i) -> int:
	return igloo_block(p, igloo_in_cell(Vector2i(floori(p.x / float(IGLOO_CELL)), floori(p.z / float(IGLOO_CELL)))))


# --- The spawn ---------------------------------------------------------------------------------

## A new world's first spawn: an open, gentle valley near the origin (not a peak, a lake or an igloo).
func spawn_column() -> Vector2i:
	for ring in SPAWN_SEARCH_RINGS:
		var r := ring * SPAWN_SEARCH_STEP
		for i in maxi(ring * 8, 1):
			var a := TAU * i / maxi(ring * 8, 1)
			var c := Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
			if _open_and_flat(c):
				return c
	return Vector2i.ZERO


func _open_and_flat(c: Vector2i) -> bool:
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	for dz in [-6, 0, 6]:
		for dx in [-6, 0, 6]:
			var col := column(c.x + dx, c.y + dz)
			if col.y != VALLEY:
				return false
			lo = mini(lo, col.x)
			hi = maxi(hi, col.x)
	return hi - lo <= SPAWN_FLAT and not tree_at(c.x, c.y)
