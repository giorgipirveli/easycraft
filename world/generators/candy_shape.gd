class_name CandyShape
extends MeadowsShape
## Pure terrain rules for the Candy Kingdom (M3 Task 4, spec §14.1), a MeadowsShape every world system can
## use (height_at, is_river, tree_at, spawn_column, ...): rolling frosting plains, winding chocolate rivers
## (the sea level's water: WATER blocks that look like chocolate in this universe, so they flow and swim like
## water) with chocolate banks, round gumdrop hills (green or red), tiered cake mountains (sponge striped
## with jam and cream, cream icing on each tier, sprinkles on the top one), candy-cane forests, lollipop
## trees and cotton candy. Every rule is a function of world (x, z) and the seed, so chunks meet without
## seams; read-only after construction (generator threads share it). Secrets are CandySecretRules'.

## What a column is (terrain_at, column().y).
const PLAINS := 0
const RIVER := 1                  # a chocolate river's channel (under water)
const BANK := 2                   # its chocolate bank
const GREEN_HILL := 3             # a gumdrop hill
const RED_HILL := 4
const CAKE_MOUNTAIN := 5

const BASE := 34.0                # the frosting plains' mean height
const BASE_SWELL := 5.0           # ... rolling this much up and down
const CAKE_DEPTH := 4             # sponge under the frosting
const CHOCOLATE_DEPTH := 10       # a chocolate layer, then stone this far under the ground
# Chocolate rivers: the river noise |n| inside CHOCO_CHANNEL is chocolate, out to CHOCO_BANK its chocolate
# bank, out to CHOCO_VALLEY the plains slope down to it.
const CHOCO_CHANNEL := 0.024
const CHOCO_BANK := 0.036
const CHOCO_VALLEY := 0.075
const RIVER_DEPTH := 4            # blocks of chocolate in the middle of a river (chest deep swims)
# Gumdrop hills: at most one per HILL_CELL cell, a dome of radius HILL_MIN_R..HILL_MAX_R.
const HILL_CELL := 64
const HILL_PER_MILLE := 520
const HILL_MIN_R := 7
const HILL_MAX_R := 13
const HILL_RISE := 0.8            # a hill's middle rises this × its radius
const HILL_MARGIN := HILL_MAX_R + 1
# Cake mountains: at most one per MOUNTAIN_CELL cell; TIERS round tiers, each TIER_H high, the next one
# TIER_SHARES of the bottom tier's radius, the edges gently wavy.
const MOUNTAIN_CELL := 224
const MOUNTAIN_PER_MILLE := 480
const MOUNTAIN_MIN_R := 22
const MOUNTAIN_MAX_R := 32
const TIERS := 3
const TIER_H := 12
const TIER_SHARES: Array[float] = [1.0, 0.64, 0.33]
const WOBBLE := 0.08              # the edge waves this much in and out
const MOUNTAIN_MARGIN := int(MOUNTAIN_MAX_R * (1.0 + WOBBLE)) + 2
## A tier's layers from its bottom: [from, to, block] (the rest is sponge); a tier's top is cream icing,
## the top tier's sprinkles.
const LAYERS: Array = [[0, 4, BlockIds.CAKE], [4, 5, BlockIds.JAM], [5, 8, BlockIds.CAKE], [8, 9, BlockIds.CREAM],
	[9, TIER_H, BlockIds.CAKE]]
# Plants (per mille of plains columns; the forests' own numbers inside a candy-cane forest).
const NO_PLANT := 0
const CANE := 1
const LOLLIPOP_TREE := 2
const COTTON := 3
const COTTON_PER_MILLE := 6
const CANE_PER_MILLE := 2
const LOLLIPOP_PER_MILLE := 3
const FOREST_CANE_PER_MILLE := 18
const FOREST_LOLLIPOP_PER_MILLE := 13
const FOREST_FROM := 0.22         # forest noise above this is a candy-cane forest
const PLANT_REACH := 2            # a cane's hook and a lollipop reach this far from their stick
const WAYS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
## Plants reach at most this far over the ground (a lollipop's stick and top).
const PLANT_TOP := 9
const SPAWN_FLAT := 3             # the spawn's 13 x 13 blocks rise and fall at most this much
## Every column's ground is below this (the highest plains plus a whole cake): chunks above it are sky.
const TOP := int(BASE + BASE_SWELL) + TIERS * TIER_H + 1

var _base := FastNoiseLite.new()
var _choco := FastNoiseLite.new()
var _forest := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	super(world_seed)
	_base.seed = world_seed + 21
	_base.frequency = 0.004
	_base.fractal_type = FastNoiseLite.FRACTAL_NONE
	_choco.seed = world_seed + 22
	_choco.frequency = 0.0022
	_choco.fractal_octaves = 2
	_forest.seed = world_seed + 23
	_forest.frequency = 0.006
	_forest.fractal_type = FastNoiseLite.FRACTAL_NONE


func height_at(x: int, z: int) -> int:
	return column(x, z).x


func is_river(x: int, z: int) -> bool:
	return column(x, z).y == RIVER


## PLAINS, RIVER, BANK, GREEN_HILL, RED_HILL or CAKE_MOUNTAIN.
func terrain_at(x: int, z: int) -> int:
	return column(x, z).y


## The ground a hill or a cake stands on (a cake's is flat: the plains at its middle); elsewhere the height.
func floor_at(x: int, z: int) -> int:
	return column(x, z).z


## (height, kind, floor) of column (x, z): one call gives everything.
func column(x: int, z: int) -> Vector3i:
	return _column_of(x, z, _mountain_near(x, z), hill_near(x, z))


## The same as column(x, z) for a column inside an area whose hills and cakes were looked up once
## (features_in: the generator's chunk), so each cell's hash is worked out once per chunk, not per column.
func column_among(x: int, z: int, features: Array) -> Vector3i:
	var m := Vector4i.ZERO
	for c: Vector4i in features[1]:
		var reach := c.z * (1.0 + WOBBLE) + 1.0
		if float((x - c.x) * (x - c.x) + (z - c.y) * (z - c.y)) < reach * reach:
			m = c
			break
	var hill := Vector3i.ZERO
	for c: Vector3i in features[0]:
		if (x - c.x) * (x - c.x) + (z - c.y) * (z - c.y) < c.z * c.z:
			hill = c
			break
	return _column_of(x, z, m, hill)


## [hills: Array[Vector3i], cakes: Array[Vector4i]] whose cells overlap [x0, x1) × [z0, z1) (hill_near's and
## _mountain_near's, before the distance check): nothing reaches out of its cell.
func features_in(x0: int, z0: int, x1: int, z1: int) -> Array:
	var hills: Array[Vector3i] = []
	for cz in range(floori(z0 / float(HILL_CELL)), floori((z1 - 1) / float(HILL_CELL)) + 1):
		for cx in range(floori(x0 / float(HILL_CELL)), floori((x1 - 1) / float(HILL_CELL)) + 1):
			var hill := _hill_of_cell(cx, cz)
			if hill.z > 0:
				hills.append(hill)
	var cakes: Array[Vector4i] = []
	for cz in range(floori(z0 / float(MOUNTAIN_CELL)), floori((z1 - 1) / float(MOUNTAIN_CELL)) + 1):
		for cx in range(floori(x0 / float(MOUNTAIN_CELL)), floori((x1 - 1) / float(MOUNTAIN_CELL)) + 1):
			var cake := _mountain_of_cell(cx, cz)
			if cake.z > 0:
				cakes.append(cake)
	return [hills, cakes]


func _column_of(x: int, z: int, m: Vector4i, hill: Vector3i) -> Vector3i:
	if m.z > 0:
		var tiers := _tiers_at(x, z, m)
		if tiers > 0:
			var f := BASE + BASE_SWELL * _base.get_noise_2d(m.x, m.y)
			return _col(f + tiers * TIER_H, CAKE_MOUNTAIN, f)
	var h := BASE + BASE_SWELL * _base.get_noise_2d(x, z)
	var kind := PLAINS
	var r := absf(_choco.get_noise_2d(x, z))
	if r < CHOCO_VALLEY:
		h = lerpf(h, SEA_LEVEL + 1.0, smoothstep(CHOCO_VALLEY, CHOCO_CHANNEL, r))
		if r < CHOCO_CHANNEL:
			h = minf(h, SEA_LEVEL - 1.0 - (RIVER_DEPTH - 1.0) * (1.0 - r / CHOCO_CHANNEL))
			return _col(h, RIVER, h)
		if r < CHOCO_BANK:
			kind = BANK
	if hill.z > 0:
		var rise := _dome(x, z, hill)
		if rise >= 1.0:
			return _col(h + rise, GREEN_HILL if (hill.x + hill.y) & 1 == 0 else RED_HILL, h)
	return _col(h, kind, h)


func _col(h: float, kind: int, floor_h: float) -> Vector3i:
	return Vector3i(clampi(int(h), MIN_HEIGHT, MAX_HEIGHT), kind, clampi(int(floor_h), MIN_HEIGHT, MAX_HEIGHT))


# --- Gumdrop hills and cake mountains --------------------------------------------------------------

## The gumdrop hill whose dome may cover (x, z): (centre x, centre z, radius), or radius 0. One hill at most
## per HILL_CELL cell, drawn from the seed, never leaving its cell.
func hill_near(x: int, z: int) -> Vector3i:
	var hill := _hill_of_cell(floori(x / float(HILL_CELL)), floori(z / float(HILL_CELL)))
	if hill.z == 0 or (x - hill.x) * (x - hill.x) + (z - hill.y) * (z - hill.y) >= hill.z * hill.z:
		return Vector3i.ZERO           # out of its reach: whether it exists does not matter here
	return hill


## The gumdrop hill of cell (cell_x, cell_z): (centre x, centre z, radius), or radius 0 (none). Its colour is
## the parity of its centre (column_among).
func _hill_of_cell(cell_x: int, cell_z: int) -> Vector3i:
	var h := _hash(cell_x * 6151 + 29, cell_z * 92821 - 5)
	if absi(h) % 1000 >= HILL_PER_MILLE:
		return Vector3i.ZERO
	var span := HILL_CELL - 2 * HILL_MARGIN
	var cx := cell_x * HILL_CELL + HILL_MARGIN + absi(h >> 8) % span
	var cz := cell_z * HILL_CELL + HILL_MARGIN + absi(h >> 20) % span
	return Vector3i(cx, cz, HILL_MIN_R + absi(h >> 32) % (HILL_MAX_R - HILL_MIN_R + 1))


## A gumdrop's dome: high in the middle, rounding down to its edge.
func _dome(x: int, z: int, hill: Vector3i) -> float:
	var q := (float((x - hill.x) * (x - hill.x) + (z - hill.y) * (z - hill.y))) / float(hill.z * hill.z)
	return HILL_RISE * hill.z * pow(maxf(1.0 - q, 0.0), 0.6)


## The cake mountain that may cover (x, z): (centre x, centre z, bottom tier's radius, wave seed), or radius
## 0. One at most per MOUNTAIN_CELL cell, never leaving its cell.
func _mountain_near(x: int, z: int) -> Vector4i:
	var m := _mountain_of_cell(floori(x / float(MOUNTAIN_CELL)), floori(z / float(MOUNTAIN_CELL)))
	var reach := m.z * (1.0 + WOBBLE) + 1.0
	if m.z == 0 or float((x - m.x) * (x - m.x) + (z - m.y) * (z - m.y)) >= reach * reach:
		return Vector4i.ZERO
	return m


## The cake mountain of cell (cell_x, cell_z), or radius 0 (none).
func _mountain_of_cell(cell_x: int, cell_z: int) -> Vector4i:
	var h := _hash(cell_x * 4099 - 17, cell_z * 65537 + 3)
	if absi(h) % 1000 >= MOUNTAIN_PER_MILLE:
		return Vector4i.ZERO
	var span := MOUNTAIN_CELL - 2 * MOUNTAIN_MARGIN
	var cx := cell_x * MOUNTAIN_CELL + MOUNTAIN_MARGIN + absi(h >> 8) % span
	var cz := cell_z * MOUNTAIN_CELL + MOUNTAIN_MARGIN + absi(h >> 20) % span
	var r := MOUNTAIN_MIN_R + absi(h >> 32) % (MOUNTAIN_MAX_R - MOUNTAIN_MIN_R + 1)
	return Vector4i(cx, cz, r, absi(h >> 40) % 1000)


## How many tiers of cake mountain `m` stand on (x, z) (0: none).
func _tiers_at(x: int, z: int, m: Vector4i) -> int:
	var dx := float(x - m.x)
	var dz := float(z - m.y)
	var d := sqrt(dx * dx + dz * dz)
	var a := atan2(dz, dx)
	var wave := 1.0 + WOBBLE * (0.6 * sin(3.0 * a + m.w * 0.0063) + 0.4 * sin(5.0 * a + m.w * 0.011))
	var tiers := 0
	for i in TIERS:
		if d < m.z * TIER_SHARES[i] * wave:
			tiers = i + 1
	return tiers


# --- Layers ------------------------------------------------------------------------------------

## The block at height y of column `col` (column()); bed: the bedrock's top there.
func block_in_column(y: int, col: Vector3i, bed: int = WORLD_BOTTOM) -> int:
	if y <= bed:
		return BlockIds.BEDROCK
	var h := col.x
	if y >= h:
		return BlockIds.WATER if y < SEA_LEVEL else BlockIds.AIR
	var f := col.z
	match col.y:
		RIVER, BANK:
			if y >= h - CHOCOLATE_DEPTH:
				return BlockIds.CHOCOLATE
			return BlockIds.STONE if y >= 0 else BlockIds.DEEPSTONE
		GREEN_HILL, RED_HILL:
			if y >= f - 1:
				return BlockIds.GUMDROP if col.y == GREEN_HILL else BlockIds.RED_GUMDROP
		CAKE_MOUNTAIN:
			if y == h - 1:
				return BlockIds.SPRINKLES if h - f >= TIERS * TIER_H else BlockIds.CREAM
			if y >= f - 1:
				return layer_at(y - (f - 1))
		_:
			if y == h - 1:
				return BlockIds.FROSTING
	if y >= f - 1 - CAKE_DEPTH:
		return BlockIds.CAKE
	if y >= f - CHOCOLATE_DEPTH:
		return BlockIds.CHOCOLATE
	return BlockIds.STONE if y >= 0 else BlockIds.DEEPSTONE


## A cake mountain's layer `k` blocks above its bottom layer (LAYERS, repeating every tier).
static func layer_at(k: int) -> int:
	var within := posmod(k, TIER_H)
	for l: Array in LAYERS:
		if within >= int(l[0]) and within < int(l[1]):
			return l[2]
	return BlockIds.CAKE


## Plains layers when only the height is known (MeadowsShape's signature).
func column_block(y: int, height: int, bed_top: int = WORLD_BOTTOM) -> int:
	return block_in_column(y, Vector3i(height, PLAINS, height), bed_top)


## Where the stone ends in column `col`: the generator writes the chocolate, cake and the rest from here
## up (CandyGenerator._write_candy_column, equal to block_in_column: tested).
func stone_top(col: Vector3i) -> int:
	return col.z - CHOCOLATE_DEPTH


# --- Plants ------------------------------------------------------------------------------------

## Inside a candy-cane forest.
func forest_at(x: int, z: int) -> bool:
	return _forest.get_noise_2d(x, z) > FOREST_FROM


## NO_PLANT, CANE, LOLLIPOP_TREE or COTTON; only on the plains (never a bank, a hill or a cake).
func plant_at(x: int, z: int) -> int:
	var r := absi(_hash(x * 3 + 1, z * 5 - 2)) % 1000
	if r >= COTTON_PER_MILLE + FOREST_CANE_PER_MILLE + FOREST_LOLLIPOP_PER_MILLE:
		return NO_PLANT
	if r >= COTTON_PER_MILLE + CANE_PER_MILLE + LOLLIPOP_PER_MILLE and not forest_at(x, z):
		return NO_PLANT
	if column(x, z).y != PLAINS:
		return NO_PLANT
	if r < COTTON_PER_MILLE:
		return COTTON
	var forest := forest_at(x, z)
	var canes := FOREST_CANE_PER_MILLE if forest else CANE_PER_MILLE
	var lollipops := FOREST_LOLLIPOP_PER_MILLE if forest else LOLLIPOP_PER_MILLE
	var k := r - COTTON_PER_MILLE
	if k < canes:
		return CANE
	if k < canes + lollipops:
		return LOLLIPOP_TREE
	return NO_PLANT


## Trees are the kingdom's plants (secrets and spawns keep off them).
func tree_at(x: int, z: int) -> bool:
	return plant_at(x, z) != NO_PLANT


## A candy cane's pole 4-7 tall, a lollipop's stick 3-5, a cotton candy bush 1-2.
func plant_height(x: int, z: int) -> int:
	var k := absi(_hash(z * 7 - 1, x * 11 + 3))
	match plant_at(x, z):
		CANE:
			return 4 + k % 4
		LOLLIPOP_TREE:
			return 3 + k % 3
	return 1 + k % 2


func tree_height(x: int, z: int) -> int:
	return plant_height(x, z)


## Which way a cane's hook bends, and which way a lollipop faces (one of MeadowsShape's four ways).
func plant_dir(x: int, z: int) -> Vector2i:
	return WAYS[absi(_hash(x * 13 + 5, z * 3 - 7)) % 4]


# --- The spawn ---------------------------------------------------------------------------------

## A new world's first spawn: open, gentle frosting near the origin (not a hill, a cake or a river bank).
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
			if col.y != PLAINS:
				return false
			lo = mini(lo, col.x)
			hi = maxi(hi, col.x)
	return hi - lo <= SPAWN_FLAT and lo > SEA_LEVEL + 1 and not tree_at(c.x, c.y)
