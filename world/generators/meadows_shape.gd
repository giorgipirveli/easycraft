class_name MeadowsShape
extends RefCounted
## Pure terrain rules for Green Meadows: height (continents and oceans, hills, mountains, river
## channels), layers and tree placement from a seed. Every rule is a function of world (x, z) only,
## so chunks meet without seams. Read-only after construction, so generator threads can share it.

const SEA_LEVEL := 24
const WORLD_BOTTOM := -64   # bedrock from here up to 3 blocks higher
const MIN_HEIGHT := 4
const MAX_HEIGHT := 120
const TREE_CHANCE_PER_MILLE := 14
# Continentalness: below COAST_LOW it is open ocean, above COAST_HIGH it is land.
const COAST_LOW := -0.22
const COAST_HIGH := -0.04
const DEEP_OCEAN := -0.5
# River noise |n|: inside RIVER_CHANNEL it is water, out to RIVER_VALLEY the banks slope down.
const RIVER_CHANNEL := 0.02
const RIVER_VALLEY := 0.06
const SPAWN_SEARCH_STEP := 16
const SPAWN_SEARCH_RINGS := 150

var seed: int
var _hills := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _mountains := FastNoiseLite.new()
var _continents := FastNoiseLite.new()
var _rivers := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	seed = world_seed
	_hills.seed = world_seed
	_hills.frequency = 0.004
	_hills.fractal_octaves = 3
	_detail.seed = world_seed + 1
	_detail.frequency = 0.03
	_mountains.seed = world_seed + 2
	_mountains.frequency = 0.0015
	_continents.seed = world_seed + 3
	_continents.frequency = 0.0005
	_continents.fractal_octaves = 3
	_rivers.seed = world_seed + 4
	_rivers.frequency = 0.0012
	_rivers.fractal_octaves = 2


## Height of the ground at (x, z): the first empty y above the top solid block.
## Everything below SEA_LEVEL above the ground is water (oceans, lakes and river channels).
func height_at(x: int, z: int) -> int:
	return _column(x, z).x


## True inside a river channel that was carved into land (its bed is under water).
func is_river(x: int, z: int) -> bool:
	return _column(x, z).y == 1


## A dry-land column near the origin for a fresh world's first spawn (searches outward in rings).
func spawn_column() -> Vector2i:
	for ring in SPAWN_SEARCH_RINGS:
		var r := ring * SPAWN_SEARCH_STEP
		for i in maxi(ring * 8, 1):
			var a := TAU * i / maxi(ring * 8, 1)
			var c := Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
			if height_at(c.x, c.y) > SEA_LEVEL + 2 and not is_river(c.x, c.y):
				return c
	return Vector2i.ZERO


## (height, river flag) for column (x, z).
func _column(x: int, z: int) -> Vector2i:
	var detail := _detail.get_noise_2d(x, z)
	var hills := _hills.get_noise_2d(x, z)
	var c := _continents.get_noise_2d(x, z)
	var land := smoothstep(COAST_LOW, COAST_HIGH, c)
	var deep := smoothstep(COAST_LOW, DEEP_OCEAN, c)
	var mountains := maxf(_mountains.get_noise_2d(x, z), 0.0)
	var land_h := 34.0 + 15.0 * hills + 3.0 * detail + 70.0 * mountains * mountains
	var sea_h := SEA_LEVEL - 3.0 - 15.0 * deep + 3.0 * hills + 2.0 * detail
	var h := lerpf(sea_h, land_h, land)
	var river := false
	var r := absf(_rivers.get_noise_2d(x, z))
	if r < RIVER_VALLEY and h > SEA_LEVEL + 1:
		h = lerpf(h, SEA_LEVEL + 1.0, smoothstep(RIVER_VALLEY, RIVER_CHANNEL, r))
		if r < RIVER_CHANNEL:
			h = minf(h, SEA_LEVEL - 1.0 - 3.0 * (1.0 - r / RIVER_CHANNEL))
			river = true
	return Vector2i(clampi(int(h), MIN_HEIGHT, MAX_HEIGHT), 1 if river else 0)


func tree_at(x: int, z: int) -> bool:
	if absi(_hash(x, z)) % 1000 >= TREE_CHANCE_PER_MILLE:
		return false
	return height_at(x, z) > SEA_LEVEL + 1


## Trunk height, 4 to 6 blocks.
func tree_height(x: int, z: int) -> int:
	return 4 + absi(_hash(z, x)) % 3


## Top of the bedrock floor at (x, z): WORLD_BOTTOM to WORLD_BOTTOM + 3.
func bedrock_top(x: int, z: int) -> int:
	return WORLD_BOTTOM + absi(_hash(x * 31 + 7, z * 17 - 3)) % 4


## Block at height y in a column whose ground height is `height` and bedrock top is `bed_top`.
func column_block(y: int, height: int, bed_top: int = WORLD_BOTTOM) -> int:
	if y <= bed_top:
		return BlockIds.BEDROCK
	if y >= height:
		return BlockIds.WATER if y < SEA_LEVEL else BlockIds.AIR
	var beach := height <= SEA_LEVEL + 1
	if y == height - 1:
		return BlockIds.SAND if beach else BlockIds.GRASS
	if y >= height - 4:
		return BlockIds.SAND if beach else BlockIds.DIRT
	return BlockIds.STONE if y >= 0 else BlockIds.DEEPSTONE


func _hash(x: int, z: int) -> int:
	var h := x * 374761393 + z * 668265263 + seed * 982451653
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
