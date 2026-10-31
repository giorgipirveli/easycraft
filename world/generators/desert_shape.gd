class_name DesertShape
extends MeadowsShape
## Pure terrain rules for the Sandstorm Desert (M3 Task 2, spec §14.1), a MeadowsShape every world system
## can use (height_at, is_river, tree_at, spawn_column, ...): a sandy floor with long dune ridges across the
## wind, striped red mesas with terraced cliffs, oases (a pond, grassy banks, palms), cacti and dry bushes.
## No rivers and no sea: only oasis ponds go below SEA_LEVEL (which fills them). Every rule is a function
## of world (x, z) and the seed, so chunks meet without seams; read-only after construction (generator
## threads share it). Pyramids and the other secrets are DesertSecretRules'.

## What a column is (terrain_at, column().y).
const DESERT := 0
const OASIS := 2
const MESA := 3

const BASE := 32.0                # the desert floor's mean height
const BASE_SWELL := 4.0           # ... rolling this much up and down
const DUNE_HEIGHT := 9.0          # a dune ridge's crest above the floor, inside a dune field
const SAND_DEPTH := 4             # sand this deep on the open desert (a dune is sand all through)
const SANDSTONE_DEPTH := 10       # sandstone this far under the floor, then stone
const MESA_FROM := 0.42           # mesa noise above this is a mesa top ...
const MESA_EDGE := 0.06           # ... and over this band below it the cliffs step up
const MESA_TERRACES := 3          # cliffs in this many steps
const MESA_RISE := 16             # a mesa's top above the floor (+ the floor's own swell)
const MESA_STRIPE := 7            # every MESA_STRIPE blocks up a mesa, a light stripe ...
const MESA_STRIPE_LIGHT := 2      # ... this thick
const OASIS_CELL := 128           # at most one oasis per cell of this size
const OASIS_PER_MILLE := 450
const OASIS_MIN_R := 6            # the pond's radius
const OASIS_MAX_R := 11
const OASIS_BANK := 6             # grassy banks this wide round the pond
const OASIS_FADE := 10            # dunes flatten out this far round the banks
const OASIS_MARGIN := OASIS_MAX_R + OASIS_BANK + OASIS_FADE + 1   # an oasis never leaves its cell
const OASIS_MESA_CLEAR := 0.12    # no oasis where the mesa noise is this close to a mesa
const NO_PLANT := 0
const CACTUS := 1
const PALM := 2
const BUSH := 3
const PALM_PER_MILLE := 25        # of oasis bank columns
const CACTUS_PER_MILLE := 5       # of open desert columns
const BUSH_PER_MILLE := 8
const SPAWN_FLAT := 3             # the spawn's 13 x 13 blocks rise and fall at most this much
## Every column's ground is below this (the highest floor plus a mesa's rise): chunks above it are sky.
const TOP := int(BASE + BASE_SWELL) + MESA_RISE + 1
## Plants reach at most this far over the ground (a palm's trunk and crown).
const PLANT_TOP := 9

var _base := FastNoiseLite.new()
var _field := FastNoiseLite.new()
var _dunes := FastNoiseLite.new()
var _mesas := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	super(world_seed)
	_base.seed = world_seed + 11
	_base.frequency = 0.004
	_base.fractal_type = FastNoiseLite.FRACTAL_NONE
	_field.seed = world_seed + 13
	_field.frequency = 0.003
	_field.fractal_type = FastNoiseLite.FRACTAL_NONE
	_dunes.seed = world_seed + 14
	_dunes.frequency = 0.012
	_dunes.fractal_type = FastNoiseLite.FRACTAL_NONE
	_mesas.seed = world_seed + 15
	_mesas.frequency = 0.007
	_mesas.fractal_octaves = 2


func height_at(x: int, z: int) -> int:
	return column(x, z).x


func is_river(_x: int, _z: int) -> bool:
	return false


## DESERT, OASIS or MESA.
func terrain_at(x: int, z: int) -> int:
	return column(x, z).y


## The desert floor under (x, z): a mesa stands on it; elsewhere it is the ground without its dune.
func floor_at(x: int, z: int) -> int:
	return column(x, z).z


## (height, kind, floor) of column (x, z): one call gives the generator everything.
func column(x: int, z: int) -> Vector3i:
	var floor_h := BASE + BASE_SWELL * _base.get_noise_2d(x, z)
	var field := smoothstep(-0.15, 0.35, _field.get_noise_2d(x, z))
	var ridge := 1.0 - absf(_dunes.get_noise_2d(x * 0.8 + z * 0.45, z * 1.3 - x * 0.25))
	var dune := DUNE_HEIGHT * field * ridge * ridge
	var h := floor_h + dune
	var o := _oasis_near(x, z)
	if o.z > 0:
		var d := Vector2(x - o.x, z - o.y).length()
		if d < o.z:
			var k := d / o.z
			return _col(lerpf(SEA_LEVEL - 3.0, SEA_LEVEL - 1.0, k * k), OASIS, floor_h)
		if d < o.z + OASIS_BANK:
			return _col(lerpf(SEA_LEVEL + 1.0, floor_h, smoothstep(o.z, o.z + OASIS_BANK, d)), OASIS, floor_h)
		h = floor_h + dune * smoothstep(o.z + OASIS_BANK, o.z + OASIS_BANK + OASIS_FADE, d)   # the dunes calm down
	var m := _mesas.get_noise_2d(x, z)
	if m > MESA_FROM - MESA_EDGE:
		var t := clampf((m - (MESA_FROM - MESA_EDGE)) / MESA_EDGE, 0.0, 1.0)
		var terrace := minf(floorf(t * (MESA_TERRACES + 1)) / MESA_TERRACES, 1.0)
		if terrace > 0.0:
			return _col(maxf(h, floor_h + MESA_RISE * terrace), MESA, floor_h)
	return _col(h, DESERT, floor_h)


func _col(h: float, kind: int, floor_h: float) -> Vector3i:
	return Vector3i(clampi(int(h), MIN_HEIGHT, MAX_HEIGHT), kind, clampi(int(floor_h), MIN_HEIGHT, MAX_HEIGHT))


## The oasis whose reach (pond, banks, flattened dunes) covers (x, z): (centre x, centre z, pond radius),
## or radius 0. One oasis at most per OASIS_CELL cell, drawn from the seed; never next to a mesa.
func _oasis_near(x: int, z: int) -> Vector3i:
	var cell_x := floori(x / float(OASIS_CELL))
	var cell_z := floori(z / float(OASIS_CELL))
	var h := _hash(cell_x * 7919 + 13, cell_z * 104729 + 7)
	if absi(h) % 1000 >= OASIS_PER_MILLE:
		return Vector3i.ZERO
	var span := OASIS_CELL - 2 * OASIS_MARGIN
	var cx := cell_x * OASIS_CELL + OASIS_MARGIN + absi(h >> 8) % span
	var cz := cell_z * OASIS_CELL + OASIS_MARGIN + absi(h >> 20) % span
	var r := OASIS_MIN_R + absi(h >> 32) % (OASIS_MAX_R - OASIS_MIN_R + 1)
	var reach := r + OASIS_BANK + OASIS_FADE
	if (x - cx) * (x - cx) + (z - cz) * (z - cz) >= reach * reach:
		return Vector3i.ZERO           # out of its reach: whether it exists does not matter here
	if _mesas.get_noise_2d(cx, cz) > MESA_FROM - MESA_EDGE - OASIS_MESA_CLEAR:
		return Vector3i.ZERO
	return Vector3i(cx, cz, r)


# --- Layers ------------------------------------------------------------------------------------

## The block at height y of column `col` (column()); bed: the bedrock's top there.
func block_in_column(y: int, col: Vector3i, bed: int = WORLD_BOTTOM) -> int:
	if y <= bed:
		return BlockIds.BEDROCK
	var h := col.x
	if y >= h:
		return BlockIds.WATER if y < SEA_LEVEL else BlockIds.AIR
	match col.y:
		MESA:
			if y == h - 1:
				return BlockIds.RED_SAND
			if y >= col.z - 1:
				return BlockIds.SANDSTONE if posmod(y, MESA_STRIPE) < MESA_STRIPE_LIGHT else BlockIds.RED_SANDSTONE
		OASIS:
			if h <= SEA_LEVEL:
				if y >= h - 3:
					return BlockIds.SAND
			elif y == h - 1:
				return BlockIds.GRASS
			elif y >= h - 4:
				return BlockIds.DIRT
			if y >= h - SANDSTONE_DEPTH:
				return BlockIds.SANDSTONE
			return BlockIds.STONE if y >= 0 else BlockIds.DEEPSTONE
		_:
			if y >= mini(h - SAND_DEPTH, col.z - 2):
				return BlockIds.SAND
	if y >= col.z - SANDSTONE_DEPTH:
		return BlockIds.SANDSTONE
	return BlockIds.STONE if y >= 0 else BlockIds.DEEPSTONE


## Plain desert layers when only the height is known (MeadowsShape's signature).
func column_block(y: int, height: int, bed_top: int = WORLD_BOTTOM) -> int:
	return block_in_column(y, Vector3i(height, DESERT, height), bed_top)


## Where the stone ends in column `col`: the generator writes sandstone, sand and the rest from here up
## (DesertGenerator._write_runs, equal to block_in_column: tested).
func stone_top(col: Vector3i) -> int:
	var top := col.z - SANDSTONE_DEPTH
	if col.y == OASIS:
		top = mini(top, col.x - SANDSTONE_DEPTH)
	return top


# --- Plants ------------------------------------------------------------------------------------

## NO_PLANT, CACTUS or BUSH on the open desert, PALM on an oasis bank.
func plant_at(x: int, z: int) -> int:
	var r := absi(_hash(x * 3 + 1, z * 5 - 2)) % 1000
	if r >= PALM_PER_MILLE:
		return NO_PLANT
	var col := column(x, z)
	if col.y == OASIS:
		return PALM if col.x > SEA_LEVEL + 1 else NO_PLANT
	if col.y != DESERT:
		return NO_PLANT
	if r < CACTUS_PER_MILLE:
		return CACTUS
	if r < CACTUS_PER_MILLE + BUSH_PER_MILLE:
		return BUSH
	return NO_PLANT


## Trees are the desert's plants (secrets and spawns keep off them).
func tree_at(x: int, z: int) -> bool:
	return plant_at(x, z) != NO_PLANT


## A cactus 1-3 blocks tall, a palm trunk 5-7; a bush is one block.
func plant_height(x: int, z: int) -> int:
	var k := absi(_hash(z * 7 - 1, x * 11 + 3))
	return 5 + k % 3 if plant_at(x, z) == PALM else 1 + k % 3


func tree_height(x: int, z: int) -> int:
	return plant_height(x, z)


# --- The spawn ---------------------------------------------------------------------------------

## A new world's first spawn: open, gentle sand near the origin (not a mesa, an oasis or a dune's side).
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
			if col.y != DESERT:
				return false
			lo = mini(lo, col.x)
			hi = maxi(hi, col.x)
	return hi - lo <= SPAWN_FLAT and not tree_at(c.x, c.y)
