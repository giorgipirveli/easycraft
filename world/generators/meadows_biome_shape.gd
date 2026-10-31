class_name MeadowsBiomeShape
extends MeadowsShape
## The wild meadows (owner feedback #45b, spec §14.18): Green Meadows' terrain version 2, for new worlds only (a
## world saved before keeps version 1: MeadowsShape). The same continents, hills and mountains, with biomes blended
## in: birch forests, dark forests, flower fields, swamps with pools and lily pads, wide beaches, a sea with
## islands, tall mountains with rock faces and snowy tops; rivers that run to the sea; and deeper cave regions
## (glowing mushroom caves, underground lakes). Every rule is a function of world (x, z) and the seed, so chunks
## meet without seams; read-only apart from a small cache behind a mutex (the generator threads share it).
##
## column(x, z) = (height, biome, flags). Rivers are two families of long winding lines: family A is where
## x + warp(x, z) is near a multiple of RIVER_SPACING_A, family B the same with z. The warp never turns faster
## than the line runs (its slope stays under 1), so each line crosses the whole world without closing into a
## loop, meets every line of the other family and, sooner or later, the sea.

const TERRAIN := 2

## Biomes (column().y).
const MEADOW := 0
const FLOWERS := 1
const BIRCH := 2
const DARK := 3
const SWAMP := 4
const BEACH := 5
const MOUNTAIN := 6
const SEA := 7          # the open sea and lakes (under water, not a river)
const RIVER := 8
const ISLAND := 9       # dry land out at sea
const BIOME_NAMES: Array[String] = ["meadow", "flower field", "birch forest", "dark forest", "swamp", "beach",
	"mountain", "sea", "river", "island"]
## Where a fresh world's first spawn may be.
const SPAWN_BIOMES: Array[int] = [MEADOW, FLOWERS, BIRCH]

## Flags (column().z).
const F_RIVER := 1
const F_FLOWER := 2     # a flower stands on the ground
const F_LILY := 4       # a lily pad lies on the water
## Trees (tree_kind).
const NO_TREE := 0
const OAK := 1
const BIRCH_TREE := 2
const DARK_TREE := 3
## Trees per mille of columns, by biome (the meadow's oaks are where the old meadows had them).
const TREES_PER_MILLE := {MEADOW: 14, FLOWERS: 3, BIRCH: 48, DARK: 60, SWAMP: 12, ISLAND: 16, MOUNTAIN: 5}
const MAX_TREES_PER_MILLE := 60
const FLOWERS_PERCENT := {FLOWERS: 24, MEADOW: 2}
const LILY_PERCENT := 18

const MOUNTAIN_SCALE := 82.0    # the old meadows: 70 × m² (rarely more than 20 blocks)
const MOUNTAIN_FROM := 0.18     # the mountain noise rises from here (a quarter of the land) ...
const MOUNTAIN_SPAN := 0.36     # ... to full height this much higher
const SOFT_CAP := 100.0         # heights above this rise half as fast (the tallest peaks stay under 120)
const ROCK_LINE := 80           # bare rock above this on mountains ...
const SNOW_LINE := 90           # ... and snow above this
const BEACH_TOP := 2            # beaches reach this far over the sea level
# Rivers.
const RIVER_SPACING_A := 1000.0
const RIVER_SPACING_B := 1300.0
const RIVER_WARP := 120.0
const RIVER_WARP_FREQUENCY := 0.0014
const RIVER_HALF := 3.5         # half a river's width inland ...
const ESTUARY := 6.0            # ... and this much more where it meets the sea
const RIVER_BANKS := 14.0       # the valley slopes down to the water over this many blocks
# Swamps and islands.
const SWAMP_FROM := 0.25        # wetness from which the land flattens into a swamp ...
const SWAMP_FULL := 0.4         # ... fully
const SWAMP_DIP := 3.0          # pools where the detail noise dips (about a quarter of a swamp)
const ISLE_FROM := 0.38         # island noise from which the sea bed rises ...
const ISLE_FULL := 0.62         # ... to an island's top
# Forests and flower fields.
const BIRCH_FROM := 0.2         # warmth above this: birch forest
const DARK_BELOW := -0.2        # warmth below this: dark forest
const FLOWERS_BELOW := -0.18    # dryness: flower fields
# Cave regions (CAVE_REGION x CAVE_REGION columns each, a multiple of the chunk size).
const CAVE_REGION := 128
const PLAIN_CAVES := 0
const MUSHROOM_CAVES := 1
const LAKE_CAVES := 2
const MUSHROOM_PER_MILLE := 180
const LAKE_PER_MILLE := 150
const CACHE_LIMIT := 2048       # remembered chunk columns

var _river_a := FastNoiseLite.new()
var _river_b := FastNoiseLite.new()
var _warmth := FastNoiseLite.new()
var _wet := FastNoiseLite.new()
var _isle := FastNoiseLite.new()
var _offset_a := 0.0
var _offset_b := 0.0
var _cache := {}
var _mutex := Mutex.new()


func _init(world_seed: int) -> void:
	super(world_seed)
	for n: FastNoiseLite in [_river_a, _river_b]:
		n.frequency = RIVER_WARP_FREQUENCY
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
	_river_a.seed = world_seed + 30
	_river_b.seed = world_seed + 31
	_warmth.seed = world_seed + 32
	_warmth.frequency = 0.0017
	_warmth.fractal_octaves = 2
	_wet.seed = world_seed + 33
	_wet.frequency = 0.0021
	_wet.fractal_octaves = 2
	_isle.seed = world_seed + 34
	_isle.frequency = 0.011
	_isle.fractal_octaves = 2
	_offset_a = float(posmod(_hash(17, 3), int(RIVER_SPACING_A)))
	_offset_b = float(posmod(_hash(5, 29), int(RIVER_SPACING_B)))


func height_at(x: int, z: int) -> int:
	return column(x, z).x


func is_river(x: int, z: int) -> bool:
	return column(x, z).z & F_RIVER != 0


## (height, river flag): the old shape's pair (the treasure pack asks for it).
func _column(x: int, z: int) -> Vector2i:
	var c := column(x, z)
	return Vector2i(c.x, 1 if c.z & F_RIVER else 0)


## (height, biome, flags) of column (x, z): one call gives everything.
func column(x: int, z: int) -> Vector3i:
	var detail := _detail.get_noise_2d(x, z)
	var hills := _hills.get_noise_2d(x, z)
	var c := _continents.get_noise_2d(x, z)
	var land := smoothstep(COAST_LOW, COAST_HIGH, c)
	var m := clampf((_mountains.get_noise_2d(x, z) - MOUNTAIN_FROM) / MOUNTAIN_SPAN, 0.0, 1.0)
	var peak := MOUNTAIN_SCALE * pow(m, 1.6) if m > 0.0 else 0.0
	var wet := _wet.get_noise_2d(x, z)
	var swamp := 0.0
	var h := 0.0
	if land > 0.0:
		h = 34.0 + 15.0 * hills + 3.0 * detail + peak
		swamp = smoothstep(SWAMP_FROM, SWAMP_FULL, wet) * (1.0 - smoothstep(4.0, 14.0, peak))
		if swamp > 0.0:
			h = lerpf(h, SEA_LEVEL + 0.5 + SWAMP_DIP * detail, swamp)
	var isle := 0.0
	if land < 1.0:
		var deep := smoothstep(COAST_LOW, DEEP_OCEAN, c)
		var sea_h := SEA_LEVEL - 3.0 - 15.0 * deep + 3.0 * hills + 2.0 * detail
		isle = smoothstep(ISLE_FROM, ISLE_FULL, _isle.get_noise_2d(x, z)) * (1.0 - land)
		if isle > 0.0:
			sea_h = lerpf(sea_h, SEA_LEVEL + 2.0 + 7.0 * isle + 2.0 * detail, isle)
		h = lerpf(sea_h, h, land)
	if h > SOFT_CAP:
		h = SOFT_CAP + (h - SOFT_CAP) * 0.5
	var flags := 0
	if h >= SEA_LEVEL - 0.5:
		var d := minf(_line_distance(river_line_a(x, z) + _offset_a, RIVER_SPACING_A),
			_line_distance(river_line_b(x, z) + _offset_b, RIVER_SPACING_B))
		var half := RIVER_HALF + ESTUARY * (1.0 - _coast(c))
		var bank := half + RIVER_BANKS
		if d < bank:
			h = lerpf(h, SEA_LEVEL + 1.0, smoothstep(bank, half, d))
			if d < half:
				h = minf(h, SEA_LEVEL - 1.0 - 3.0 * (1.0 - d / half))
				flags = F_RIVER
	var hi := clampi(int(h), MIN_HEIGHT, MAX_HEIGHT)
	var out := Vector3i(hi, _biome(x, z, hi, flags, land, isle, swamp, peak, wet), flags)
	if out.y == SWAMP and hi < SEA_LEVEL:
		if absi(_hash(x * 7 + 3, z * 5 - 11)) % 100 < LILY_PERCENT:
			out.z |= F_LILY
	else:
		var chance: int = FLOWERS_PERCENT.get(out.y, 0)
		if chance > 0 and layers(out) == &"grass" and absi(_hash(x * 11 - 5, z * 13 + 7)) % 100 < chance:
			out.z |= F_FLOWER
	return out


## Which biome a column is (its height, what made it).
func _biome(x: int, z: int, h: int, flags: int, land: float, isle: float, swamp: float, peak: float, wet: float) -> int:
	if flags & F_RIVER:
		return RIVER
	if h < SEA_LEVEL:
		return SWAMP if swamp > 0.5 and land >= 1.0 else SEA
	if swamp > 0.5:
		return SWAMP
	if h <= SEA_LEVEL + 1 or (h <= SEA_LEVEL + BEACH_TOP and land < 1.0):
		return BEACH
	if isle > 0.25 and land < 0.5:
		return ISLAND
	if peak > 16.0 and h >= ROCK_LINE - 16:
		return MOUNTAIN
	var warmth := _warmth.get_noise_2d(x, z)
	if warmth > BIRCH_FROM:
		return BIRCH
	if warmth < DARK_BELOW:
		return DARK
	if wet < FLOWERS_BELOW:
		return FLOWERS
	return MEADOW


## 0 at the open sea, 1 well inland (the coast in between).
func _coast(c: float) -> float:
	return smoothstep(COAST_LOW, COAST_HIGH + 0.3, c)


## How far inland (x, z) is: 0 at the open sea, 1 well inland.
func coast_share(x: int, z: int) -> float:
	return _coast(_continents.get_noise_2d(x, z))


## The open sea: past the coast (rivers reach it).
func is_open_sea(x: int, z: int) -> bool:
	return _continents.get_noise_2d(x, z) < COAST_LOW and height_at(x, z) < SEA_LEVEL


## Family A's line value at (x, z): rivers run where it is near a multiple of RIVER_SPACING_A.
func river_line_a(x: int, z: int) -> float:
	return x + RIVER_WARP * _river_a.get_noise_2d(x, z)


func river_line_b(x: int, z: int) -> float:
	return z + RIVER_WARP * _river_b.get_noise_2d(x, z)


## Half a river's width at (x, z) (wider near the sea).
func river_half_width(x: int, z: int) -> float:
	return RIVER_HALF + ESTUARY * (1.0 - coast_share(x, z))


static func _line_distance(v: float, spacing: float) -> float:
	return absf(fposmod(v + spacing * 0.5, spacing) - spacing * 0.5)


# --- Trees ---

## NO_TREE, OAK, BIRCH_TREE or DARK_TREE at (x, z).
func tree_kind(x: int, z: int) -> int:
	var roll := absi(_hash(x, z)) % 1000
	if roll >= MAX_TREES_PER_MILLE:
		return NO_TREE
	return tree_for(column(x, z), roll)


## The tree of a column already worked out, for its roll (absi(_hash(x, z)) % 1000).
static func tree_for(c: Vector3i, roll: int) -> int:
	if c.x <= SEA_LEVEL + 1 or c.z & F_RIVER or roll >= int(TREES_PER_MILLE.get(c.y, 0)):
		return NO_TREE
	match c.y:
		BIRCH:
			return BIRCH_TREE
		DARK, SWAMP:
			return DARK_TREE
		MOUNTAIN:
			return BIRCH_TREE if c.x < ROCK_LINE else NO_TREE
	return OAK


func tree_roll(x: int, z: int) -> int:
	return absi(_hash(x, z)) % 1000


## A tree's trunk: an oak 4-6, a birch 5-7, a dark oak 4-6 (3-4 in a swamp).
func tree_trunk(kind: int, c: Vector3i, x: int, z: int) -> int:
	var v := absi(_hash(z, x)) % 3
	match kind:
		BIRCH_TREE:
			return 5 + v
		DARK_TREE:
			return (3 + v % 2) if c.y == SWAMP else 4 + v
	return 4 + v


## The trees standing in the chunk column at (x0, z0) whose trunk is inside [lo, hi) (sideways), in the column's
## order (z, then x): 3 ints each, (lx | lz << 8 | kind << 16), the base (ground) height, the trunk. Worked out from
## the columns themselves (the generator's cold path; chunk_columns keeps the whole column's).
func trees_of(x0: int, z0: int, lo: Vector2i, hi: Vector2i) -> PackedInt32Array:
	var out := PackedInt32Array()
	for lz in range(maxi(lo.y - z0, 0), mini(hi.y - z0, 16)):
		for lx in range(maxi(lo.x - x0, 0), mini(hi.x - x0, 16)):
			var roll := absi(_hash(x0 + lx, z0 + lz)) % 1000
			if roll >= MAX_TREES_PER_MILLE:
				continue
			var c := column(x0 + lx, z0 + lz)
			var kind := tree_for(c, roll)
			if kind != NO_TREE:
				out.append_array([lx | (lz << 8) | (kind << 16), c.x, tree_trunk(kind, c, x0 + lx, z0 + lz)])
	return out


func tree_at(x: int, z: int) -> bool:
	return tree_kind(x, z) != NO_TREE


# --- Blocks ---

## Block at height y of a column (column()'s value); bed_top: the bedrock's top. Trees aside (the generator's
## reference): the ground's layers, the water, a flower on the ground and a lily pad on the water.
func block_in_column(y: int, c: Vector3i, bed_top: int = WORLD_BOTTOM) -> int:
	if y <= bed_top:
		return BlockIds.BEDROCK
	var h := c.x
	if y >= h:
		if y < SEA_LEVEL:
			return BlockIds.WATER
		if y == h and c.z & F_FLOWER:
			return BlockIds.FLOWERS
		if y == SEA_LEVEL and h < SEA_LEVEL and c.z & F_LILY:
			return BlockIds.LILY_PAD
		return BlockIds.AIR
	if y < h - 4:
		return BlockIds.STONE if y >= 0 else BlockIds.DEEPSTONE
	var top := y == h - 1
	match layers(c):
		&"snow":
			return BlockIds.SNOW if top else BlockIds.STONE
		&"rock":
			return BlockIds.STONE
		&"sand":
			return BlockIds.SAND
		&"mud":
			return BlockIds.MUD if top else BlockIds.DIRT
	return BlockIds.GRASS if top else BlockIds.DIRT


## What a column's top 4 blocks are: &"grass" (grass over dirt), &"sand", &"mud" (mud over dirt), &"rock" (stone)
## or &"snow" (snow over stone).
static func layers(c: Vector3i) -> StringName:
	var h := c.x
	if c.y == SWAMP:
		return &"mud"
	if c.y == MOUNTAIN or h >= ROCK_LINE:
		if h >= SNOW_LINE:
			return &"snow"
		if h >= ROCK_LINE:
			return &"rock"
	if h <= SEA_LEVEL + 1 or c.y == BEACH or c.y == SEA or c.y == RIVER:
		return &"sand"
	return &"grass"


# --- A chunk column at once (the generator) ---

## Every column of the 16 x 16 chunk column at (x0, z0), worked out once for the whole stack of chunks:
## [heights, info, highest, lowest, trees] (PackedInt32Array heights and info: x + z * 16; unpack(h, info) is the
## column; trees as trees_of gives them, for the whole column). Shared: never change what it returns.
func chunk_columns(x0: int, z0: int) -> Array:
	var key := Vector2i(x0, z0)
	_mutex.lock()
	var got: Variant = _cache.get(key)
	_mutex.unlock()
	if got != null:
		return got
	var heights := PackedInt32Array()
	var info := PackedInt32Array()
	heights.resize(256)
	info.resize(256)
	var top := -0x7fffffff
	var low := 0x7fffffff
	var trees := PackedInt32Array()
	var i := 0
	for z in 16:
		for x in 16:
			var c := column(x0 + x, z0 + z)
			heights[i] = c.x
			info[i] = c.y | (c.z << 8)
			top = maxi(top, c.x)
			low = mini(low, c.x)
			var roll := absi(_hash(x0 + x, z0 + z)) % 1000
			if roll < MAX_TREES_PER_MILLE:
				var kind := tree_for(c, roll)
				if kind != NO_TREE:
					trees.append_array([x | (z << 8) | (kind << 16), c.x, tree_trunk(kind, c, x0 + x, z0 + z)])
			i += 1
	var out := [heights, info, top, low, trees]
	_mutex.lock()
	if _cache.size() >= CACHE_LIMIT:
		_cache.clear()
	_cache[key] = out
	_mutex.unlock()
	return out


static func unpack(height: int, info: int) -> Vector3i:
	return Vector3i(height, info & 0xff, info >> 8)


# --- Cave regions ---

## PLAIN_CAVES, MUSHROOM_CAVES (glowing caps, a mud floor, giant mushrooms) or LAKE_CAVES (the deep caverns
## flooded higher up) for the region of (x, z).
func cave_region(x: int, z: int) -> int:
	var r := absi(_hash(floori(x / float(CAVE_REGION)) * 7919 + 13, floori(z / float(CAVE_REGION)) * 104729 - 7)) % 1000
	if r < MUSHROOM_PER_MILLE:
		return MUSHROOM_CAVES
	if r < MUSHROOM_PER_MILLE + LAKE_PER_MILLE:
		return LAKE_CAVES
	return PLAIN_CAVES


# --- The spawn ---

## A dry, friendly column near the origin for a fresh world's first spawn: a meadow, a flower field or a birch
## forest, off the rivers and below the rock line (searched outward in rings like the old meadows).
func spawn_column() -> Vector2i:
	for ring in SPAWN_SEARCH_RINGS:
		var r := ring * SPAWN_SEARCH_STEP
		for i in maxi(ring * 8, 1):
			var a := TAU * i / maxi(ring * 8, 1)
			var p := Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
			var c := column(p.x, p.y)
			if c.x > SEA_LEVEL + 2 and c.x < ROCK_LINE - 20 and c.z & F_RIVER == 0 and c.y in SPAWN_BIOMES:
				return p
	return super()
