class_name GlowShape
extends MeadowsShape
## Pure terrain rules for universe 6, the Glow Caves (spec §5.1; brief docs/superpowers/plans/2026-10-01-glow-caves-brief.md),
## a MeadowsShape every world system can use (height_at, is_river, tree_at, spawn_column, ...): a 2.5-D layered cave.
## Every column (x, z) has three heights from slow 2-D noises (column()):
## - the cavern FLOOR (height_at: where every spawner, Tilly, the Totem, secrets, animals and monsters find their
##   ground): a slow swell of 30 +- 16 (every dry step one block at most), dipping under LAKE_LEVEL into lakes;
## - the CEILING: the floor (or a lake's water line) plus a clearance from a cellular noise: each cell a hall, domed
##   high in its middle (up to ~24 blocks) and low at its edge, rock WALLS along the cells' borders (floor == ceiling),
##   broken by wide PASSAGES where a gate noise opens them;
## - the ROOF: a meadow of grass over the rock (the way in and out), ROOF_MID +- 3.
## DAYLIGHT SHAFTS (one in about half of the SHAFT_CELL squares, always one by the home hall) open the roof to the sky
## over a radius of SHAFT_R: a pool in the middle, a spiral RAMP round the wall that climbs one block a step from the
## hall's floor to the roof's meadow. The HOME hall round the spawn (near the origin, from the seed) is open, high and
## dry. The glow: glow-moss carpets on the floor, glow-worm ceilings, giant glowshrooms (blue and rose caps), small
## glowshrooms, selenite beams in the crystal halls (the Cave of Crystals); stone: stalagmites, stalactites, flowstone
## columns and the flowstone at the walls' feet. Every rule is a function of (x, z) and the seed, so chunks meet
## without seams; read-only after construction (the generator's threads share it).

## A wall column's height_at: the sea level, as the Dragon Realm's void: every spawner asking for dry land (> SEA_LEVEL
## + 1) or for water deep enough to swim in (two under it) finds no ground in the rock.
const NO_GROUND := SEA_LEVEL
## The caves' rock ends in bedrock here (BED_BOTTOM up to 3 higher); nothing is under it (a chunk there costs nothing).
const BED_BOTTOM := -16
## Water fills a lake up to (not including) this height; dry land is above it.
const LAKE_LEVEL := SEA_LEVEL
# The floor: FLOOR_MID + FLOOR_SWING * a slow noise + a little detail (its slope stays under one block a block).
const FLOOR_MID := 30.0
const FLOOR_SWING := 16.0
const FLOOR_FREQUENCY := 0.004
const FLOOR_DETAIL := 0.6
const LAKE_DEEPEN := 1.6           # under the water line the bed falls this much faster (lakes 4-8 deep)
const MIN_FLOOR := 12
# The halls: a cellular noise's F2 - F1 (0 at the cells' borders, ~0.2 typical, up to ~0.9 in a cell's middle).
const HALL_FREQUENCY := 0.014
const HALL_WARP := 22.0            # the cells' borders wind (a domain warp of this many blocks)
const WALL_EDGE := 0.07            # closer to a border than this: rock (a wall), unless a passage opens it
const GATE_FREQUENCY := 0.025
const GATE_FROM := 0.05            # the gate noise above this opens a wall into a passage
const PASSAGE_CLEAR := 6           # a passage's height
const CLEAR_MIN := 7.0             # a hall's ceiling at its edge ...
const CLEAR_MAX := 22.0            # ... and in its middle (a dome)
const DOME_EDGE := 0.42            # the dome reaches its top this far into a cell
const CLEAR_WOBBLE := 2.0
# The roof: a meadow on the rock; at least ROOF_ROCK of rock over every hall's ceiling.
const ROOF_MID := 76
const ROOF_SWING := 3.0
const ROOF_ROCK := 6
const SOIL := 3                    # dirt under the roof's grass
# The home hall: open, high and dry within HOME_OPEN of `home` (near the origin, within HOME_OFFSET, from the seed), its
# floor at HOME_FLOOR, blended into the caves round it over HOME_BLEND.
const HOME_OFFSET := 12
const HOME_OPEN := 34
const HOME_BLEND := 30.0
const HOME_FLOOR := 33.0
const HOME_CLEAR := 22.0
# Daylight shafts: one per SHAFT_CELL square (SHAFT_CHANCE of them), radius SHAFT_R: the ramp is the ring RAMP_IN..SHAFT_R,
# the pool inside it POOL_DEPTH deep (its water POOL_WATER deep); the home hall's shaft HOME_SHAFT from home.
const SHAFT_CELL := 96
const SHAFT_CHANCE := 55           # per cent
const SHAFT_MARGIN := 24          # > SHAFT_R: a shaft stays inside its own square
const SHAFT_R := 10
const RAMP_IN := 7
const POOL_DEPTH := 3
const POOL_WATER := 2
const HOME_SHAFT := 24
# The glow on the floor and the ceiling (noise above these): glow-moss carpets, glow-worm ceilings.
const MOSS_FREQUENCY := 0.05
const MOSS_FROM := 0.18
const WORMS_FREQUENCY := 0.03
const WORMS_FROM := 0.1
const FLOW_EDGE := 0.085           # floor this close to a wall: flowstone at its foot
# The crystal halls (the Cave of Crystals): a slow noise above CRYSTAL_FROM.
const CRYSTAL_FREQUENCY := 0.006
const CRYSTAL_FROM := 0.38
const GROVE_FREQUENCY := 0.012
const GROVE_FROM := 0.28
# Plants on the floor (per mille of the open, dry columns; groves and crystal halls have their own numbers).
const NO_PLANT := 0
const BLUE_GIANT := 1              # a giant glowshroom with a blue cap: a pale stem 4-8, a cap 7 across
const ROSE_GIANT := 2              # ... with a rose cap
const BLUE_SMALL := 3              # a small glowshroom: a stem 1-2 and one cap block
const ROSE_SMALL := 4
const STALAGMITE := 5              # 0-2 flowstone and a stalagmite on top
const COLUMN := 6                  # a flowstone column from the floor to the ceiling (a stalactite met its stalagmite)
const BEAM := 7                    # a selenite beam: a slanting line of crystal 6-14 long (crystal halls only)
const GIANT_PER_MILLE := 5
const GROVE_GIANT_PER_MILLE := 22
const SMALL_PER_MILLE := 14
const STALAGMITE_PER_MILLE := 12
const COLUMN_PER_MILLE := 2
const BEAM_BLOCK := 4               # beams: one may stand in a 4 x 4 square of columns ...
const BEAM_SQUARES_PER_MILLE := 300  # ... in this many of them (inside a crystal hall)
const HANG_PER_MILLE := 22         # stalactites hanging from the ceiling
const FLOWER_LONE_PER_MILLE := 12  # the roof's meadow: a flower alone on this many columns in a thousand ...
const FLOWER_PER_MILLE := 380      # ... and on this many inside its flower patches
const FLOWER_PATCH := 0.32         # a patch: the grove noise (stretched) over this
const FLOWER_STRETCH := 1.9
const PLANT_REACH := 3             # a giant cap reaches this far from its stem
const BEAM_REACH := 8              # a beam reaches this far from its foot
const SPAWN_CLEAR := 4             # nothing grows this close to the spawn
const WAYS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0),
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]

## The home hall's middle.
var home: Vector2i

var _floor := FastNoiseLite.new()
var _floor_detail := FastNoiseLite.new()
var _halls := FastNoiseLite.new()
var _gate := FastNoiseLite.new()
var _clear := FastNoiseLite.new()
var _roof := FastNoiseLite.new()
var _moss := FastNoiseLite.new()
var _worms := FastNoiseLite.new()
var _crystal := FastNoiseLite.new()
var _grove := FastNoiseLite.new()
var _home_shaft: Vector2i
var _spawn: Vector2i


func _init(world_seed: int) -> void:
	super(world_seed)
	_floor.seed = world_seed + 61
	_floor.frequency = FLOOR_FREQUENCY
	_floor.fractal_octaves = 2
	_floor_detail.seed = world_seed + 62
	_floor_detail.frequency = 0.05
	_floor_detail.fractal_type = FastNoiseLite.FRACTAL_NONE
	_halls.seed = world_seed + 63
	_halls.noise_type = FastNoiseLite.TYPE_CELLULAR
	_halls.frequency = HALL_FREQUENCY
	_halls.fractal_type = FastNoiseLite.FRACTAL_NONE
	_halls.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	_halls.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	_halls.domain_warp_enabled = true   # the walls wind like rock, not straight like a building's
	_halls.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
	_halls.domain_warp_amplitude = HALL_WARP
	_halls.domain_warp_frequency = 0.02
	_halls.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_NONE
	_gate.seed = world_seed + 64
	_gate.frequency = GATE_FREQUENCY
	_gate.fractal_type = FastNoiseLite.FRACTAL_NONE
	_clear.seed = world_seed + 65
	_clear.frequency = 0.03
	_clear.fractal_type = FastNoiseLite.FRACTAL_NONE
	_roof.seed = world_seed + 66
	_roof.frequency = 0.01
	_roof.fractal_type = FastNoiseLite.FRACTAL_NONE
	_moss.seed = world_seed + 67
	_moss.frequency = MOSS_FREQUENCY
	_moss.fractal_type = FastNoiseLite.FRACTAL_NONE
	_worms.seed = world_seed + 68
	_worms.frequency = WORMS_FREQUENCY
	_worms.fractal_type = FastNoiseLite.FRACTAL_NONE
	_crystal.seed = world_seed + 69
	_crystal.frequency = CRYSTAL_FREQUENCY
	_crystal.fractal_type = FastNoiseLite.FRACTAL_NONE
	_grove.seed = world_seed + 70
	_grove.frequency = GROVE_FREQUENCY
	_grove.fractal_type = FastNoiseLite.FRACTAL_NONE
	home = Vector2i(absi(_hash(71, 73)) % (2 * HOME_OFFSET + 1) - HOME_OFFSET,
		absi(_hash(79, 83)) % (2 * HOME_OFFSET + 1) - HOME_OFFSET)
	var a := float(absi(_hash(89, 97)) % 628) / 100.0
	_home_shaft = home + Vector2i(roundi(cos(a) * HOME_SHAFT), roundi(sin(a) * HOME_SHAFT))
	_spawn = _find_spawn()


# --- Columns -----------------------------------------------------------------------------------

## (floor, ceiling, roof) of column (x, z): rock under the floor, air (or a lake's water) up to the ceiling, rock and
## the meadow up to the roof. A wall: floor == ceiling (rock up to the roof). A daylight shaft: ceiling == roof.
func column(x: int, z: int) -> Vector3i:
	var roof := roof_at(x, z)
	var shaft := shaft_near(x, z)
	if shaft.x != 0x7fffffff:
		return _shaft_column(x, z, shaft, roof)
	return _cave_column(x, z, roof)


func roof_at(x: int, z: int) -> int:
	return ROOF_MID + roundi(ROOF_SWING * _roof.get_noise_2d(x, z))


## How much a column belongs to the home hall (1 inside HOME_OPEN, 0 beyond its blend).
func _home_weight(x: int, z: int) -> float:
	var d := Vector2(x - home.x, z - home.y).length()
	return clampf((HOME_OPEN + HOME_BLEND - d) / HOME_BLEND, 0.0, 1.0)


## The floor before lakes and walls: the slow swell, flattened to HOME_FLOOR round home.
func _dry_floor(x: int, z: int, home_w: float) -> float:
	var f := FLOOR_MID + FLOOR_SWING * _floor.get_noise_2d(x, z) + FLOOR_DETAIL * _floor_detail.get_noise_2d(x, z)
	return lerpf(f, HOME_FLOOR, home_w)


## F2 - F1 of the hall cells (0 at a border); home is always deep inside its hall.
func hall_edge(x: int, z: int) -> float:
	var e := _halls.get_noise_2d(x, z) + 1.0
	return maxf(e, DOME_EDGE * _home_weight(x, z))


## A column outside the shafts; `edge` its hall_edge when the caller has it already.
func _cave_column(x: int, z: int, roof: int, edge: float = NAN) -> Vector3i:
	var home_w := _home_weight(x, z)
	var f := _dry_floor(x, z, home_w)
	var floor_y := roundi(f)
	if floor_y < LAKE_LEVEL:
		floor_y = maxi(LAKE_LEVEL - roundi((LAKE_LEVEL - f) * LAKE_DEEPEN), MIN_FLOOR)
	if is_nan(edge):
		edge = maxf(_halls.get_noise_2d(x, z) + 1.0, DOME_EDGE * home_w)
	var base := maxi(floor_y, LAKE_LEVEL)
	var clear: int
	if edge < WALL_EDGE:
		if _gate.get_noise_2d(x, z) <= GATE_FROM:
			return Vector3i(floor_y, floor_y, roof)       # a wall
		clear = PASSAGE_CLEAR
	else:
		var dome := smoothstep(WALL_EDGE, DOME_EDGE, edge)
		var c := CLEAR_MIN + (CLEAR_MAX - CLEAR_MIN) * dome + CLEAR_WOBBLE * _clear.get_noise_2d(x, z)
		clear = roundi(lerpf(c, HOME_CLEAR, home_w))
	var ceil_y := mini(base + maxi(clear, 3), roof - ROOF_ROCK)
	return Vector3i(floor_y, maxi(ceil_y, base + 3), roof)


# --- Daylight shafts ---------------------------------------------------------------------------

## The middle of the daylight shaft column (x, z) lies in (x, y), or (0x7fffffff, 0) when it lies in none. A shaft
## stays inside its own SHAFT_CELL square (SHAFT_MARGIN > SHAFT_R), so only the column's square is looked at: its cheap
## hash first, the shaft's own checks (noise) only when its disc reaches the column.
func shaft_near(x: int, z: int) -> Vector2i:
	if (x - _home_shaft.x) * (x - _home_shaft.x) + (z - _home_shaft.y) * (z - _home_shaft.y) <= SHAFT_R * SHAFT_R:
		return _home_shaft
	var c := _shaft_candidate(Vector2i(floori(x / float(SHAFT_CELL)), floori(z / float(SHAFT_CELL))))
	if c.x == 0x7fffffff or (x - c.x) * (x - c.x) + (z - c.y) * (z - c.y) > SHAFT_R * SHAFT_R:
		return Vector2i(0x7fffffff, 0)
	return c if _shaft_ok(c) else Vector2i(0x7fffffff, 0)


func in_shaft(x: int, z: int) -> bool:
	return shaft_near(x, z).x != 0x7fffffff


## The home hall's shaft (always there).
func home_shaft() -> Vector2i:
	return _home_shaft


## The shaft of a SHAFT_CELL square, or (0x7fffffff, 0): drawn from the seed, kept only deep inside a dry hall and away
## from the home hall (its own shaft stands there).
func shaft_of_cell(cell: Vector2i) -> Vector2i:
	var c := _shaft_candidate(cell)
	return c if c.x != 0x7fffffff and _shaft_ok(c) else Vector2i(0x7fffffff, 0)


func _shaft_candidate(cell: Vector2i) -> Vector2i:
	var h := absi(_hash(cell.x * 7 + 101, cell.y * 13 - 103))
	if h % 100 >= SHAFT_CHANCE:
		return Vector2i(0x7fffffff, 0)
	var span := SHAFT_CELL - 2 * SHAFT_MARGIN
	return cell * SHAFT_CELL + Vector2i(SHAFT_MARGIN + (h >> 8) % span, SHAFT_MARGIN + (h >> 16) % span)


func _shaft_ok(c: Vector2i) -> bool:
	if Vector2(c - home).length() < HOME_OPEN + HOME_BLEND + SHAFT_R:
		return false
	return hall_edge(c.x, c.y) >= 0.2 and _dry_floor(c.x, c.y, 0.0) >= LAKE_LEVEL + 3


## A column of a daylight shaft round `mid`: open to the sky; the pool inside RAMP_IN; the spiral ramp from RAMP_IN to
## SHAFT_R, one turn from the hall's floor (east of the middle, going round towards +z) up to just under the roof.
func _shaft_column(x: int, z: int, mid: Vector2i, roof: int) -> Vector3i:
	var base := _shaft_floor(mid)
	var d := Vector2(x - mid.x, z - mid.y)
	if d.length() < RAMP_IN:
		return Vector3i(base - POOL_DEPTH, roof, roof)
	return Vector3i(ramp_height(mid, x, z, roof), roof, roof)


## The hall floor a shaft stands on (its middle's).
func _shaft_floor(mid: Vector2i) -> int:
	return maxi(roundi(_dry_floor(mid.x, mid.y, _home_weight(mid.x, mid.y))), LAKE_LEVEL + 2)


## The ramp's top in column (x, z) of the shaft round `mid`: one block over the hall floor at the start (angle 0),
## rising evenly round the turn to one under the roof.
func ramp_height(mid: Vector2i, x: int, z: int, roof: int) -> int:
	var base := _shaft_floor(mid)
	var a := fposmod(atan2(float(z - mid.y), float(x - mid.x)), TAU) / TAU
	var top := maxi(roof - 1, base + 2)
	return clampi(base + 1 + floori(a * (top - base)), base + 1, top)


## Where water stands in column (x, z) up to (exclusive): a lake's LAKE_LEVEL, a shaft pool's, or 0 (none).
func water_top(x: int, z: int) -> int:
	var mid := shaft_near(x, z)
	if mid.x != 0x7fffffff:
		if Vector2(x - mid.x, z - mid.y).length() < RAMP_IN:
			return _shaft_floor(mid) - POOL_DEPTH + POOL_WATER
		return 0
	var c := column(x, z)
	return LAKE_LEVEL if c.x < c.y and c.x < LAKE_LEVEL else 0


## Everything the generator writes in column (x, z), worked out together: [floor, ceiling, roof, the floor's top block,
## the ceiling's block, water top (0: none), the top of the plain stone (STONE under it; cave stone over it up to the
## floor's top block), the bedrock's top].
func layers(x: int, z: int) -> PackedInt32Array:
	var roof := roof_at(x, z)
	var mid := shaft_near(x, z)
	var out := PackedInt32Array()
	out.resize(8)
	out[7] = bedrock_top(x, z)
	if mid.x != 0x7fffffff:
		var c := _shaft_column(x, z, mid, roof)
		var pool := Vector2(x - mid.x, z - mid.y).length() < RAMP_IN
		var base := _shaft_floor(mid)
		out[0] = c.x
		out[1] = c.y
		out[2] = c.z
		out[3] = BlockIds.LAKE_STONE if pool else BlockIds.FLOWSTONE
		out[4] = BlockIds.AIR
		out[5] = base - POOL_DEPTH + POOL_WATER if pool else 0
		out[6] = base - POOL_DEPTH - 4
		return out
	var edge := hall_edge(x, z)
	var c := _cave_column(x, z, roof, edge)
	out[0] = c.x
	out[1] = c.y
	out[2] = c.z
	out[6] = c.x - 4
	if c.x == c.y:
		out[3] = BlockIds.CAVE_STONE
		out[4] = BlockIds.CAVE_STONE
		return out
	if c.x <= LAKE_LEVEL + 1:
		out[3] = BlockIds.LAKE_STONE
	elif moss_at(x, z):
		out[3] = BlockIds.GLOW_MOSS
	elif edge < FLOW_EDGE:
		out[3] = BlockIds.FLOWSTONE
	else:
		out[3] = BlockIds.CAVE_STONE
	out[4] = ceiling_block(x, z)
	out[5] = LAKE_LEVEL if c.x < LAKE_LEVEL else 0
	return out


## The block at height y of a column with these layers (layers()), plants and secrets aside.
static func block_in_layers(y: int, l: PackedInt32Array) -> int:
	var floor_y := l[0]
	var ceil_y := l[1]
	var roof := l[2]
	if y >= roof or y < BED_BOTTOM:
		return BlockIds.AIR
	if y <= l[7]:
		return BlockIds.BEDROCK
	if y < floor_y or (floor_y == ceil_y and y < roof - 1 - SOIL):
		if y < 0 and y < l[6]:
			return BlockIds.DEEPSTONE
		if y < l[6]:
			return BlockIds.STONE
		if floor_y == ceil_y:
			return BlockIds.CAVE_STONE
		return l[3] if y == floor_y - 1 else BlockIds.CAVE_STONE
	if y < ceil_y:
		return BlockIds.WATER if y < l[5] else BlockIds.AIR
	if ceil_y == roof:
		return BlockIds.AIR
	if y == roof - 1:
		return BlockIds.GRASS
	if y >= roof - 1 - SOIL:
		return BlockIds.DIRT
	return l[4] if y == ceil_y else BlockIds.CAVE_STONE


# --- MeadowsShape's questions ------------------------------------------------------------------

## The cavern floor (the first air or water over the rock), NO_GROUND in a wall.
func height_at(x: int, z: int) -> int:
	var c := column(x, z)
	return c.x if c.x < c.y else NO_GROUND


## The top a child stands on: the floor of an open column, the roof's meadow on a wall.
func walk_top(x: int, z: int) -> int:
	var c := column(x, z)
	return c.x if c.x < c.y else c.z


func is_river(_x: int, _z: int) -> bool:
	return false


func bedrock_top(x: int, z: int) -> int:
	return BED_BOTTOM + absi(_hash(x * 31 + 7, z * 17 - 3)) % 4


## Under a ceiling (not in a shaft's open column, not in a wall).
func roofed(x: int, z: int) -> bool:
	var c := column(x, z)
	return c.x < c.y and c.y < c.z


func crystal_hall(x: int, z: int) -> bool:
	return _crystal.get_noise_2d(x, z) > CRYSTAL_FROM and _home_weight(x, z) < 0.5


func grove_at(x: int, z: int) -> bool:
	return _grove.get_noise_2d(x, z) > GROVE_FROM


## A flower on the roof's meadow over column (x, z) (on its grass: never over a daylight shaft).
func flower_on_roof(x: int, z: int) -> bool:
	return flower_spot(x, z) and not in_shaft(x, z)


## The flower rule without the shaft (the generator knows the column's sky already): in patches, and a few alone.
func flower_spot(x: int, z: int) -> bool:
	var h := absi(_hash(x * 13 - 5, z * 11 + 9)) % 1000
	if h < FLOWER_LONE_PER_MILLE:
		return true
	if h >= FLOWER_PER_MILLE:
		return false
	return _grove.get_noise_2d(x * FLOWER_STRETCH + 913.0, z * FLOWER_STRETCH - 377.0) > FLOWER_PATCH


func moss_at(x: int, z: int) -> bool:
	return _moss.get_noise_2d(x, z) > MOSS_FROM


func worms_at(x: int, z: int) -> bool:
	return _worms.get_noise_2d(x, z) > WORMS_FROM


## The block on top of the floor of an open column: lake stone in and round the lakes, glow moss in its carpets,
## flowstone at a wall's foot, else cave stone. (A shaft's ramp and pool: cave stone and lake stone.)
func floor_block(x: int, z: int, col: Vector3i) -> int:
	if col.x <= LAKE_LEVEL + 1:
		return BlockIds.LAKE_STONE
	if in_shaft(x, z):
		return BlockIds.FLOWSTONE if Vector2(shaft_near(x, z) - Vector2i(x, z)).length() >= RAMP_IN else BlockIds.LAKE_STONE
	if moss_at(x, z):
		return BlockIds.GLOW_MOSS
	if hall_edge(x, z) < FLOW_EDGE:
		return BlockIds.FLOWSTONE
	return BlockIds.CAVE_STONE


## The ceiling's lowest block of a roofed column: a glow-worm ceiling in its patches, else cave stone.
func ceiling_block(x: int, z: int) -> int:
	return BlockIds.GLOW_WORMS if worms_at(x, z) else BlockIds.CAVE_STONE


## Is there a glow within `r` blocks of column (x, z) (looked at every other column): glow moss on the floor, a
## glow-worm ceiling, a glowshroom, a selenite beam?
func glow_near(x: int, z: int, r: int) -> bool:
	for dz in range(-r, r + 1, 2):
		for dx in range(-r, r + 1, 2):
			if dx * dx + dz * dz > r * r:
				continue
			var cx := x + dx
			var cz := z + dz
			var c := column(cx, cz)
			if c.x == c.y:
				continue
			if moss_at(cx, cz) and c.x > LAKE_LEVEL + 1:
				return true
			if c.y < c.z and worms_at(cx, cz):
				return true
			if plant_at(cx, cz) in [BLUE_GIANT, ROSE_GIANT, BLUE_SMALL, ROSE_SMALL, BEAM]:
				return true
	return false


# --- Plants ------------------------------------------------------------------------------------

## What grows on the floor of column (x, z): NO_PLANT, a giant or small glowshroom, a stalagmite, a column or a beam;
## only on open, dry floor with room for it, never in a shaft or within SPAWN_CLEAR of the spawn. The kind comes from
## the column's hash in fixed bands (a beam from its BEAM_BLOCK square's: beam_foot), the noises only where they matter.
func plant_at(x: int, z: int) -> int:
	var kind := NO_PLANT
	var r := absi(_hash(x * 5 + 3, z * 7 - 1)) % 1000
	if r < GROVE_GIANT_PER_MILLE:
		if r < GIANT_PER_MILLE or grove_at(x, z):
			kind = BLUE_GIANT if absi(_hash(x, z * 3)) % 2 == 0 else ROSE_GIANT
	elif r < GROVE_GIANT_PER_MILLE + SMALL_PER_MILLE:
		kind = BLUE_SMALL if absi(_hash(x * 3, z)) % 2 == 0 else ROSE_SMALL
	elif r < GROVE_GIANT_PER_MILLE + SMALL_PER_MILLE + STALAGMITE_PER_MILLE:
		kind = STALAGMITE
	elif r < GROVE_GIANT_PER_MILLE + SMALL_PER_MILLE + STALAGMITE_PER_MILLE + COLUMN_PER_MILLE:
		kind = COLUMN
	if kind == NO_PLANT:
		if beam_foot(floori(x / float(BEAM_BLOCK)), floori(z / float(BEAM_BLOCK))) != Vector2i(x, z):
			return NO_PLANT
		kind = BEAM
	return _fits(x, z, kind)


## The column where the beam of BEAM_BLOCK square (bx, bz) stands (one in BEAM_SQUARES_PER_MILLE squares, inside a crystal
## hall), or (0x7fffffff, 0): the generator looks at the squares round a chunk, not at every column.
func beam_foot(bx: int, bz: int) -> Vector2i:
	var h := absi(_hash(bx * 29 + 11, bz * 31 - 13))
	if h % 1000 >= BEAM_SQUARES_PER_MILLE:
		return Vector2i(0x7fffffff, 0)
	var foot := Vector2i(bx * BEAM_BLOCK + (h >> 10) % BEAM_BLOCK, bz * BEAM_BLOCK + (h >> 14) % BEAM_BLOCK)
	return foot if crystal_hall(foot.x, foot.y) else Vector2i(0x7fffffff, 0)


## `kind` if it fits column (x, z): open dry floor, room under the ceiling, not in a shaft, not by the spawn.
func _fits(x: int, z: int, kind: int) -> int:
	if absi(x - _spawn.x) <= SPAWN_CLEAR and absi(z - _spawn.y) <= SPAWN_CLEAR:
		return NO_PLANT
	if in_shaft(x, z):
		return NO_PLANT
	var c := column(x, z)
	if c.x == c.y or c.x <= LAKE_LEVEL + 1:
		return NO_PLANT
	var room := c.y - c.x
	match kind:
		BLUE_GIANT, ROSE_GIANT:
			if room < plant_height(x, z, kind) + 4:
				return NO_PLANT
		COLUMN:
			if room > 16 or room < 4:
				return NO_PLANT
		BEAM:
			if room < 6:
				return NO_PLANT
		_:
			if room < 5:
				return NO_PLANT
	return kind


## A giant's stem 4-8 tall, a small one's 1-2, a stalagmite's flowstone 0-2 (and its tip), a beam's length 6-14.
func plant_height(x: int, z: int, kind: int = -1) -> int:
	var k := absi(_hash(z * 11 + 5, x * 13 - 7))
	if kind < 0:
		kind = plant_at(x, z)
	match kind:
		BLUE_GIANT, ROSE_GIANT:
			return 4 + k % 5
		BLUE_SMALL, ROSE_SMALL:
			return 1 + k % 2
		STALAGMITE:
			return k % 3
		BEAM:
			return 6 + k % 9
	return 0


func tree_at(x: int, z: int) -> bool:
	var p := plant_at(x, z)
	return p == BLUE_GIANT or p == ROSE_GIANT


func tree_height(x: int, z: int) -> int:
	return plant_height(x, z)


## The way a beam leans (one of eight).
func beam_dir(x: int, z: int) -> Vector2i:
	return WAYS[absi(_hash(x * 17 - 3, z * 19 + 5)) % 8]


## The cells of the beam whose foot is (x, z): from the floor, slanting up two blocks every three steps along its way,
## stopping where a column's ceiling (or rock) is in the way, never out of BEAM_REACH; thick ones (every third) are two
## blocks high.
func beam_cells(x: int, z: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var c := column(x, z)
	var way := beam_dir(x, z)
	var length := mini(plant_height(x, z, BEAM), BEAM_REACH)
	var thick := absi(_hash(x * 23, z * 29)) % 3 == 0
	for i in length:
		var px := x + way.x * i
		var pz := z + way.y * i
		var y := c.x + i * 2 / 3
		var here := column(px, pz)
		if here.x == here.y or y >= here.y - 1 or y < here.x:
			break
		out.append(Vector3i(px, y, pz))
		if thick and y + 1 < here.y - 1:
			out.append(Vector3i(px, y + 1, pz))
	return out


## A stalactite hanging from the ceiling of column (x, z): how many blocks long (0: none); its lowest block is the
## stalactite's picture, the rest flowstone. Only under a ceiling with room under it.
func hang_at(x: int, z: int) -> int:
	var r := absi(_hash(x * 19 + 7, z * 23 - 11)) % 1000
	if r >= HANG_PER_MILLE:
		return 0
	if in_shaft(x, z):
		return 0
	var c := column(x, z)
	if c.x == c.y or c.y >= c.z:
		return 0
	var room := c.y - maxi(c.x, LAKE_LEVEL)
	var length := 1 + r % 4
	if room < length + 4:
		return 0
	return length


# --- The spawn ---------------------------------------------------------------------------------

func spawn_column() -> Vector2i:
	return _spawn


func _find_spawn() -> Vector2i:
	for ring in 10:
		var r := ring * 3
		for i in maxi(ring * 8, 1):
			var a := TAU * i / maxi(ring * 8, 1)
			var c := home + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
			if _flat_and_open(c):
				return c
	return home


func _flat_and_open(c: Vector2i) -> bool:
	if Vector2(c - _home_shaft).length() <= SHAFT_R + 4:
		return false
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	for dz in [-6, 0, 6]:
		for dx in [-6, 0, 6]:
			var col := column(c.x + dx, c.y + dz)
			if col.x == col.y or col.x <= LAKE_LEVEL + 1:
				return false
			lo = mini(lo, col.x)
			hi = maxi(hi, col.x)
	return hi - lo <= 2
