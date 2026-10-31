class_name DragonShape
extends MeadowsShape
## Pure terrain rules for the Dragon Realm (owner feedback #39, spec §14.2a), a MeadowsShape every world system can
## use (height_at, is_river, tree_at, spawn_column, ...): floating islands over a starry void. An island mask from
## noise; each island a flat-ish top of sky grass (its height from a slow noise, so neighbouring islands float at
## different heights, about 40-85) over floatstone that tapers down to a thin rim, deep floatstone underneath; a big
## home island round the world spawn, always (its middle from the seed, near the origin); nothing below the islands
## (no bedrock, no water: the void). Giant glowing mushrooms and crystal spires are the realm's trees; flat clouds
## drift under and between the islands; ores lie in the island rock by depth under its top.
##
## A void column's height is VOID_HEIGHT (the sea level): every spawner that asks for dry land (> SEA_LEVEL + 1: animals,
## Tilly, the stone circle, the Theater, secrets) and every one that asks for water deep enough to swim in (fish: two
## blocks under the sea level) says "no ground here". Every rule is a function of world (x, z) and the seed, so
## chunks meet without seams; read-only after construction (generator threads share it).

const VOID_HEIGHT := SEA_LEVEL
# The island mask: noise above ISLAND_FROM is an island; (mask - ISLAND_FROM) / ISLAND_SPAN is how deep inside it
# a column lies (0 at the rim, 1 far in).
const MASK_FREQUENCY := 0.011
const ISLAND_FROM := 0.18
const ISLAND_SPAN := 0.3
# An island's top: ALT_MID +- ALT_SWING (a slow noise), a little detail, its rim rounded down by RIM.
const ALT_MID := 62.0
const ALT_SWING := 20.0
const DETAIL := 2.0
const RIM := 2.0
# The home island: a disc of HOME_R (its edge wobbling by HOME_WOBBLE) round `home`, which lies within HOME_OFFSET of
# the origin; it reaches its full depth HOME_RAMP in from its edge, sits at HOME_ALT, and its height blends into the
# islands next to it over HOME_BLEND. Flatter than the others (HOME_DETAIL).
const HOME_R := 64.0
const HOME_WOBBLE := 0.08
const HOME_RAMP := 20.0
const HOME_ALT := 56.0
const HOME_BLEND := 28.0
const HOME_OFFSET := 16
const HOME_DETAIL := 0.8
# The underside: EDGE_THICK at the rim, DEPTH more far in (a tapered cone), a little wobble; never below MIN_BOTTOM
# (DragonRules.RESCUE_Y lies under it). SOIL blocks of floatstone under the sky grass; the lower DEEP_SHARE of a
# column is deep floatstone.
const EDGE_THICK := 3
const DEPTH := 30.0
const UNDER_WOBBLE := 3.0
const MIN_BOTTOM := 12
const SOIL := 3
const DEEP_SHARE := 0.5
## Every island's top is below this: chunks above it hold only plants, clouds' tops and secrets.
const TOP := int(ALT_MID + ALT_SWING + DETAIL) + 2
# Clouds: flat-bottomed puffs 1-CLOUD_MAX thick where the cloud noise is above CLOUD_FROM, their base at
# CLOUD_BASE +- CLOUD_SWING (a slow noise), only in the air.
const CLOUD_FREQUENCY := 0.02
const CLOUD_FROM := 0.45
const CLOUD_BASE := 30.0
const CLOUD_SWING := 12.0
const CLOUD_MAX := 3
const CLOUD_LOW := int(CLOUD_BASE - CLOUD_SWING) - 1
const CLOUD_HIGH := int(CLOUD_BASE + CLOUD_SWING) + CLOUD_MAX + 1
# Plants (per mille of the island columns thick enough to hold one; the groves' own numbers inside a grove).
const NO_PLANT := 0
const SPIRE := 1                  # a crystal spire: a tall glowing golden crystal pillar (owner #43) (a shorter one beside the tall ones)
const MUSHROOM := 2               # a giant mushroom: a pale stalk under a round glowing cap
const SPIRE_PER_MILLE := 2
const MUSHROOM_PER_MILLE := 3
const GROVE_SPIRE_PER_MILLE := 7
const GROVE_MUSHROOM_PER_MILLE := 13
const GROVE_FROM := 0.3
const PLANT_MIN_DEPTH := 8        # a plant grows where the island is at least this thick (not on its thin rim)
const PLANT_REACH := 3            # a cap reaches this far from its stalk
const PLANT_TOP := 16             # plants reach at most this far over the ground
const WAYS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
# Ores: veins inside ORE_CELL cells, each ore in its band of depth under the island's top.
const ORE_CELL := 8
const MAX_VEIN := 6
const ORE_DEPTH := {BlockIds.COAL: Vector2i(2, 16), BlockIds.IRON: Vector2i(5, 24), BlockIds.GOLD: Vector2i(10, 32),
	BlockIds.CRYSTAL: Vector2i(14, 40), BlockIds.DIAMOND: Vector2i(18, 44)}
## [ore, chance per mille per cell, min size, max size]
const ORE_VEINS := [[BlockIds.COAL, 700, 4, 6], [BlockIds.IRON, 450, 3, 5], [BlockIds.GOLD, 260, 2, 4],
	[BlockIds.CRYSTAL, 170, 2, 3], [BlockIds.DIAMOND, 110, 1, 3]]
const _STEPS: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]
# The spawn: a column near the home island's middle whose 13 x 13 blocks rise and fall at most SPAWN_FLAT, with no
# plant within SPAWN_CLEAR.
const SPAWN_FLAT := 2
const SPAWN_CLEAR := 3
const SPAWN_RINGS := 9
const SPAWN_RING_STEP := 3

## The home island's middle.
var home: Vector2i

var _mask := FastNoiseLite.new()
var _alt := FastNoiseLite.new()
var _top_detail := FastNoiseLite.new()
var _under := FastNoiseLite.new()
var _cloud := FastNoiseLite.new()
var _cloud_alt := FastNoiseLite.new()
var _grove := FastNoiseLite.new()
var _wobble := Vector2.ZERO
var _spawn: Vector2i


func _init(world_seed: int) -> void:
	super(world_seed)
	_mask.seed = world_seed + 51
	_mask.frequency = MASK_FREQUENCY
	_mask.fractal_octaves = 2
	_alt.seed = world_seed + 52
	_alt.frequency = 0.0045
	_alt.fractal_type = FastNoiseLite.FRACTAL_NONE
	_top_detail.seed = world_seed + 53
	_top_detail.frequency = 0.05
	_top_detail.fractal_type = FastNoiseLite.FRACTAL_NONE
	_under.seed = world_seed + 54
	_under.frequency = 0.09
	_under.fractal_type = FastNoiseLite.FRACTAL_NONE
	_cloud.seed = world_seed + 55
	_cloud.frequency = CLOUD_FREQUENCY
	_cloud.fractal_octaves = 2
	_cloud_alt.seed = world_seed + 56
	_cloud_alt.frequency = 0.006
	_cloud_alt.fractal_type = FastNoiseLite.FRACTAL_NONE
	_grove.seed = world_seed + 57
	_grove.frequency = 0.008
	_grove.fractal_type = FastNoiseLite.FRACTAL_NONE
	home = Vector2i(absi(_hash(7, 11)) % (2 * HOME_OFFSET + 1) - HOME_OFFSET,
		absi(_hash(13, 17)) % (2 * HOME_OFFSET + 1) - HOME_OFFSET)
	_wobble = Vector2(float(absi(_hash(19, 23)) % 628) / 100.0, float(absi(_hash(29, 31)) % 628) / 100.0)
	_spawn = _find_spawn()


# --- Columns -----------------------------------------------------------------------------------

## (top, bottom, deep top) of column (x, z): solid from bottom up to top - 1 (the sky grass), deep floatstone below
## the deep top; Vector3i.ZERO in the void.
func column(x: int, z: int) -> Vector3i:
	var m := _mask.get_noise_2d(x, z)
	var dx := float(x - home.x)
	var dz := float(z - home.y)
	var d := sqrt(dx * dx + dz * dz)
	var home_s := -1.0
	var home_w := 0.0
	if d < HOME_R * (1.0 + HOME_WOBBLE) + HOME_BLEND:
		var edge := _home_radius(dx, dz)
		home_s = (edge - d) / HOME_RAMP
		home_w = clampf((edge + HOME_BLEND - d) / HOME_BLEND, 0.0, 1.0)
	var s := maxf((m - ISLAND_FROM) / ISLAND_SPAN, home_s)
	if s <= 0.0:
		return Vector3i.ZERO
	s = minf(s, 1.0)
	var alt := lerpf(ALT_MID + ALT_SWING * _alt.get_noise_2d(x, z), HOME_ALT, home_w)
	var detail := _top_detail.get_noise_2d(x, z) * lerpf(DETAIL, HOME_DETAIL, home_w)
	var top := clampi(roundi(alt + detail - RIM * (1.0 - smoothstep(0.0, 0.3, s))), MIN_HEIGHT, MAX_HEIGHT)
	var depth := maxi(int(EDGE_THICK + DEPTH * pow(s, 0.8) + UNDER_WOBBLE * s * _under.get_noise_2d(x, z)), EDGE_THICK)
	var bottom := maxi(top - depth, MIN_BOTTOM)
	var deep := clampi(bottom + int((top - bottom) * DEEP_SHARE), bottom, top - 1 - SOIL)
	return Vector3i(top, bottom, maxi(deep, bottom))


func _home_radius(dx: float, dz: float) -> float:
	var a := atan2(dz, dx)
	return HOME_R * (1.0 + HOME_WOBBLE * (0.6 * sin(3.0 * a + _wobble.x) + 0.4 * sin(5.0 * a + _wobble.y)))


func is_island(x: int, z: int) -> bool:
	var c := column(x, z)
	return c.x > c.y


## The island's top (the first air over its sky grass), or VOID_HEIGHT over the void.
func height_at(x: int, z: int) -> int:
	var c := column(x, z)
	return c.x if c.x > c.y else VOID_HEIGHT


func is_river(_x: int, _z: int) -> bool:
	return false


## No bedrock anywhere: the world's floor is the void.
func bedrock_top(_x: int, _z: int) -> int:
	return WORLD_BOTTOM - 16


## The cloud in column (x, z): [base, top) (base == top: none). Flat-bottomed, thicker in the middle of a puff.
func cloud_at(x: int, z: int) -> Vector2i:
	var n := _cloud.get_noise_2d(x, z)
	if n <= CLOUD_FROM:
		return Vector2i.ZERO
	var thick := clampi(1 + int((n - CLOUD_FROM) / (1.0 - CLOUD_FROM) * CLOUD_MAX * 2.0), 1, CLOUD_MAX)
	var base := int(CLOUD_BASE + CLOUD_SWING * _cloud_alt.get_noise_2d(x, z))
	return Vector2i(base, base + thick)


## The block at height y of column `col` (column()) with its cloud (cloud_at()); an island's rock wins over a cloud.
func block_in_column(y: int, col: Vector3i, cloud: Vector2i) -> int:
	if col.x > col.y and y >= col.y and y < col.x:
		if y == col.x - 1:
			return BlockIds.SKY_GRASS
		return BlockIds.DEEP_FLOATSTONE if y < col.z else BlockIds.FLOATSTONE
	if y >= cloud.x and y < cloud.y:
		return BlockIds.CLOUD
	return BlockIds.AIR


## MeadowsShape's signature, when only the height is known: an island's layers under `height`, air over the void.
func column_block(y: int, height: int, _bed_top: int = WORLD_BOTTOM) -> int:
	if height == VOID_HEIGHT or y >= height or y < MIN_BOTTOM:
		return BlockIds.AIR
	return BlockIds.SKY_GRASS if y == height - 1 else BlockIds.FLOATSTONE


# --- Plants ------------------------------------------------------------------------------------

## Inside a grove, where mushrooms and spires grow thick.
func grove_at(x: int, z: int) -> bool:
	return _grove.get_noise_2d(x, z) > GROVE_FROM


## NO_PLANT, SPIRE or MUSHROOM; only where the island is thick enough (never on its thin rim, never over the void).
func plant_at(x: int, z: int) -> int:
	var r := absi(_hash(x * 5 + 3, z * 7 - 1)) % 1000
	if r >= GROVE_SPIRE_PER_MILLE + GROVE_MUSHROOM_PER_MILLE:
		return NO_PLANT
	var grove := grove_at(x, z)
	var spires := GROVE_SPIRE_PER_MILLE if grove else SPIRE_PER_MILLE
	var mushrooms := GROVE_MUSHROOM_PER_MILLE if grove else MUSHROOM_PER_MILLE
	if r >= spires + mushrooms:
		return NO_PLANT
	var c := column(x, z)
	if c.x - c.y < PLANT_MIN_DEPTH:
		return NO_PLANT
	return SPIRE if r < spires else MUSHROOM


## The realm's trees are its plants (secrets and spawns keep off them; the axe fells a mushroom).
func tree_at(x: int, z: int) -> bool:
	return plant_at(x, z) != NO_PLANT


## A spire 5-14 blocks tall, a mushroom's stalk 4-8.
func plant_height(x: int, z: int) -> int:
	var k := absi(_hash(z * 11 + 5, x * 13 - 7))
	match plant_at(x, z):
		SPIRE:
			return 5 + k % 10
		MUSHROOM:
			return 4 + k % 5
	return 0


func tree_height(x: int, z: int) -> int:
	return plant_height(x, z)


## Which side a spire's smaller pillar stands on (one of four ways).
func plant_dir(x: int, z: int) -> Vector2i:
	return WAYS[absi(_hash(x * 17 - 3, z * 19 + 5)) % 4]


# --- Ores --------------------------------------------------------------------------------------

## The veins of ore cell `cell` (world position / ORE_CELL): [{"ore", "blocks": Array[Vector3i], "depth"}]. At most one
## vein of each ore, its middle inside the island rock at a depth (under the island's top) in that ore's band; every
## block stays inside the cell, so no chunk ever cuts a vein. The generator puts them only into floatstone (ore_in).
func veins_in_cell(cell: Vector3i) -> Array:
	var out: Array = []
	var base := cell * ORE_CELL
	for i in ORE_VEINS.size():
		var row: Array = ORE_VEINS[i]
		var h := absi(_hash3(cell.x * 3 + i, cell.y * 5 - i * 7, cell.z * 7 + i * 13))
		if h % 1000 >= int(row[1]):
			continue
		var p := base + Vector3i(1 + (h >> 10) % (ORE_CELL - 2), 1 + (h >> 14) % (ORE_CELL - 2), 1 + (h >> 18) % (ORE_CELL - 2))
		var col := column(p.x, p.z)
		if col.x <= col.y or p.y < col.y or p.y >= col.x - 1:
			continue
		var depth := col.x - p.y
		var band: Vector2i = ORE_DEPTH[row[0]]
		if depth < band.x or depth > band.y:
			continue
		var size: int = int(row[2]) + (h >> 22) % (int(row[3]) - int(row[2]) + 1)
		var blocks: Array[Vector3i] = []
		var walk := h >> 26
		for k in size:
			if not blocks.has(p):
				blocks.append(p)
			p = (p + _STEPS[walk % 6]).clamp(base, base + Vector3i.ONE * (ORE_CELL - 1))
			walk = walk / 6 if walk >= 6 else absi(_hash3(p.x, p.y + k, p.z))
		out.append({"ore": row[0], "blocks": blocks, "depth": depth})
	return out


## The ore at world position p, or -1 (slow: rebuilds the cell's veins; for the reference). The first vein wins.
func ore_at(p: Vector3i) -> int:
	var cell := Vector3i(floori(p.x / float(ORE_CELL)), floori(p.y / float(ORE_CELL)), floori(p.z / float(ORE_CELL)))
	for vein: Dictionary in veins_in_cell(cell):
		if (vein.blocks as Array).has(p):
			return vein.ore
	return -1


## What an ore does to the block it lands on: floatstone becomes the ore; anything else stays.
static func ore_in(current: int, ore: int) -> int:
	return ore if current == BlockIds.FLOATSTONE or current == BlockIds.DEEP_FLOATSTONE else current


func _hash3(x: int, y: int, z: int) -> int:
	return _hash(x * 73856093 ^ y * 19349663, z * 83492791 + y)


# --- The spawn ---------------------------------------------------------------------------------

## A new world's first spawn: flat, open sky grass near the home island's middle (the same for a seed).
func spawn_column() -> Vector2i:
	return _spawn


func _find_spawn() -> Vector2i:
	for ring in SPAWN_RINGS:
		var r := ring * SPAWN_RING_STEP
		for i in maxi(ring * 8, 1):
			var a := TAU * i / maxi(ring * 8, 1)
			var c := home + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
			if _open_and_flat(c):
				return c
	return home


func _open_and_flat(c: Vector2i) -> bool:
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	for dz in [-6, 0, 6]:
		for dx in [-6, 0, 6]:
			var col := column(c.x + dx, c.y + dz)
			if col.x <= col.y:
				return false
			lo = mini(lo, col.x)
			hi = maxi(hi, col.x)
	if hi - lo > SPAWN_FLAT or lo <= SEA_LEVEL + 1:
		return false
	for dz in range(-SPAWN_CLEAR, SPAWN_CLEAR + 1):
		for dx in range(-SPAWN_CLEAR, SPAWN_CLEAR + 1):
			if plant_at(c.x + dx, c.y + dz) != NO_PLANT:
				return false
	return true
