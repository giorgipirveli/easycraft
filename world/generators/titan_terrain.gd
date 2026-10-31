class_name TitanTerrain
extends RefCounted
## Titan's regions as pure rules (cosmos, spec §21b.2), for SpaceShape's planet TITAN: every rule is a function of the seed
## and (x, z), read-only after construction (the generator's threads share it). North is -z, as on MY MAP. Every column
## is a plain column of ground (no overhangs, no caves); a column whose ground lies under LIQUID_TOP is filled with liquid
## up to it (the game's WATER, shown as liquid methane in Titan's world: BlockLibrary.set_liquid), like a lake.
## - The plains: orange-brown soil (Titan's ground under its orange haze), gentle swells, patches of ice pebbles (the
##   rounded pebbles of water ice a probe saw where it landed), over icy rock (water ice as hard as stone).
## - The methane sea (one per world, to the north: Titan's biggest seas lie near its north pole): a wide basin whose shore
##   wanders a little, its bed deepening one block every SLOPE blocks to SEA_DEPTH, a beach level with the methane's top
##   and a gentle coast up to the plains, so a child walks out of it anywhere.
## - Small methane lakes (at most one per LAKE_CELL cell; more of them to the north, none among the dunes): the same shape,
##   LAKE_DEPTH deep.
## - The dunes (to the south, from dune_edge() on, like the long dunes round Titan's equator): long ridges of dark grains
##   running east-west, DUNE_SPACING apart, up to about DUNE_H high, with corridors of soil and pebbles between them.
## - The icy mountains (one range per world, to the east or west): a ridge of icy rock rising a block per block to a top
##   up to PEAK_H over the plains, highest in its middle, pale with ice pebbles on top.
## Every step between two columns is at most MAX_STEP (a jump at 0.14 gravity climbs ~12), and one block round every lake
## and the sea. column() packs a column's height and kind (height * 16 + kind).

const PLAINS := 0       # orange-brown soil
const PEBBLES := 1      # ice pebbles on the soil
const DUNE := 2         # a dune's dark grains
const SHORE := 3        # a lake's beach and the foot of its coast
const LAKE := 4         # a lake's bed, under the methane
const SEA_SHORE := 5    # the sea's beach and the foot of its coast
const SEA := 6          # the sea's bed, under the methane
const MOUNTAIN := 7     # the icy mountains' slopes
const PEAK := 8         # their top

const MAX_STEP := 8
const BASE := 50.0
const SWELL := 3.0
const NONE := Vector2i(0x7fffffff, 0x7fffffff)
## The methane's surface: the first air over a lake or the sea (the liquid fills up to y LIQUID_TOP - 1).
const LIQUID_TOP := 45
const SUB_DEPTH := 2            # soil under a top block (the dunes: DUNE_SUB grains)
const DUNE_SUB := 3
# The plains' pebble patches
const PEBBLE_FREQ := 0.012
const PEBBLES_AT := 0.3
# The basins (the sea and the lakes): the bed deepens one block every SLOPE blocks from a waterline one deep (wading)
const SLOPE := 3.0
const BEACH := 4.0              # a beach this wide, level with the methane's top ...
const COAST := 16.0             # ... then a coast rising to the plains (at most a block per 2 blocks)
const SHORE_UP := 0.4           # the coast's foot (this share of it) is still shore
# The sea
const SEA_DISTANCE := Vector2i(250, 290)   # its middle, north of the world's middle
const SEA_SIDE := 60            # ... and at most this far east or west of it
const SEA_R := 115.0            # its waterline's radius ...
const SEA_WOBBLE := 16.0        # ... wandering this much
const SEA_DEPTH := 8
# The lakes
const LAKE_CELL := 120
const LAKE_MARGIN := 30         # a lake and its coast stay inside their cell (R + BEACH + COAST < LAKE_MARGIN)
const LAKE_R := Vector2i(8, 10)
const LAKE_DEPTH := 3
const LAKE_CHANCE := 30         # of 100 cells in the middle ...
const LAKE_NORTH_CHANCE := 70   # ... rising to this far to the north
const LAKE_NORTH := 400.0       # (blocks north of the world's middle where it is highest)
# The dunes
const DUNE_EDGE := Vector2i(130, 170)   # the dune field's north edge, south of the world's middle
const DUNE_RAMP := 48.0         # the dunes grow to their full height over this
const DUNE_SPACING := 28.0
const DUNE_SHARE := 0.7         # of the spacing a dune covers (the rest is a corridor)
const DUNE_H := 6.0
const DUNE_FREQ := 0.02         # the dunes' wander and their heights' noise
# The icy mountains
const MOUNTAIN_X := Vector2i(220, 260)   # the range's middle, east or west of the world's middle ...
const MOUNTAIN_Z := Vector2i(-40, 10)    # ... and north-south
const MOUNTAIN_HALF := 60.0     # half its length (it runs roughly north-south)
const MOUNTAIN_TILT := 25       # degrees off north-south at most
const HALF_W := 36.0            # half its width
const PEAK_H := 30
const RAMP := 1.0               # blocks up per block
const PEAK_FROM := 5            # its top: within this of its height

var _seed := 0
var _sea := Vector2i.ZERO
var _dune_z := 0
var _m0 := Vector2.ZERO          # the range's ends
var _m1 := Vector2.ZERO
var _swell := FastNoiseLite.new()
var _pebbles := FastNoiseLite.new()
var _shore := FastNoiseLite.new()
var _dunes := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	_seed = world_seed
	var h := absi(_mix(world_seed + 22))
	var sd := SEA_DISTANCE.x + h % (SEA_DISTANCE.y - SEA_DISTANCE.x + 1)
	_sea = Vector2i((h >> 7) % (2 * SEA_SIDE + 1) - SEA_SIDE, -sd)
	_dune_z = DUNE_EDGE.x + (h >> 14) % (DUNE_EDGE.y - DUNE_EDGE.x + 1)
	var east := (h >> 19) % 2 == 0
	var mx := MOUNTAIN_X.x + (h >> 20) % (MOUNTAIN_X.y - MOUNTAIN_X.x + 1)
	var mz := MOUNTAIN_Z.x + (h >> 3) % (MOUNTAIN_Z.y - MOUNTAIN_Z.x + 1)
	var mid := Vector2(mx if east else -mx, mz)
	var tilt := deg_to_rad(float((h >> 11) % (2 * MOUNTAIN_TILT + 1) - MOUNTAIN_TILT))
	var along := Vector2(sin(tilt), cos(tilt)) * MOUNTAIN_HALF
	_m0 = mid - along
	_m1 = mid + along
	_swell.seed = world_seed + 220
	_swell.frequency = 0.004
	_swell.fractal_octaves = 3
	_pebbles.seed = world_seed + 221
	_pebbles.frequency = PEBBLE_FREQ
	_pebbles.fractal_octaves = 2
	_shore.seed = world_seed + 222
	_shore.frequency = 0.008
	_shore.fractal_octaves = 2
	_dunes.seed = world_seed + 223
	_dunes.frequency = DUNE_FREQ
	_dunes.fractal_octaves = 1


## The middle of the methane sea.
func sea_centre() -> Vector2i:
	return _sea


## The dune field's north edge (the dunes grow south of it).
func dune_edge() -> int:
	return _dune_z


## The middle of the icy mountains' top (the range's middle: its highest part).
func peak_centre() -> Vector2i:
	var m := (_m0 + _m1) * 0.5
	return Vector2i(roundi(m.x), roundi(m.y))


## The plains' own height at (x, z) (no basin, dune or mountain).
func plains_height(x: int, z: int) -> int:
	return roundi(BASE + SWELL * _swell.get_noise_2d(x, z))


## Height * 16 + kind of the column at (x, z) (the landing pad's flattening is SpaceShape's).
func column(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var p := BASE + SWELL * _swell.get_noise_2d(fx, fz)
	var sdx := fx - _sea.x
	var sdz := fz - _sea.y
	var reach := SEA_R + SEA_WOBBLE + BEACH + COAST
	var sd2 := sdx * sdx + sdz * sdz
	if sd2 < reach * reach:
		var r := SEA_R + SEA_WOBBLE * _shore.get_noise_2d(fx, fz)
		var b := _basin(sqrt(sd2), r, SEA_DEPTH, p, SEA, SEA_SHORE, fx, fz)
		if b >= 0:
			return b
	var rise := mountain_rise(fx, fz)
	if rise > 0.0:
		return _pack(p + rise, PEAK if rise >= _ridge_height(fx, fz) - PEAK_FROM else MOUNTAIN)
	if fz > _dune_z:
		var dune := dune_rise(fx, fz)
		if dune >= 1.0:
			return _pack(p + dune, DUNE)
		return _pack(p + dune, _patch(fx, fz))
	var l := lake_in_cell(Vector2i(floori(fx / LAKE_CELL), floori(fz / LAKE_CELL)))
	if l.z > 0:
		var b := _basin(Vector2(fx - l.x, fz - l.y).length(), float(l.z), LAKE_DEPTH, p, LAKE, SHORE, fx, fz)
		if b >= 0:
			return b
	return _pack(p, _patch(fx, fz))


## A basin's packed column at distance d from its middle, its waterline r, `depth` deep, over plains of height p: its
## `bed` under the methane (one deep at the waterline, a block deeper every SLOPE blocks in), its `shore` on the beach
## (level with the methane's top) and the coast's foot, the plains' patches up the rest of the coast; -1 beyond it.
func _basin(d: float, r: float, depth: int, p: float, bed: int, shore: int, fx: float, fz: float) -> int:
	if d < r:
		return (LIQUID_TOP - clampi(1 + floori((r - d - 1.0) / SLOPE), 1, depth)) * 16 + bed
	if d < r + BEACH:
		return LIQUID_TOP * 16 + shore
	var k := (d - r - BEACH) / COAST
	if k >= 1.0:
		return -1
	var h := maxi(roundi(lerpf(float(LIQUID_TOP), p, smoothstep(0.0, 1.0, k))), LIQUID_TOP)
	return h * 16 + (shore if k < SHORE_UP else _patch(fx, fz))


## A plains column's patch: ice pebbles or soil.
func _patch(fx: float, fz: float) -> int:
	return PEBBLES if _pebbles.get_noise_2d(fx, fz) > PEBBLES_AT else PLAINS


# --- The dunes ---------------------------------------------------------------------------------------------

## How high the dunes rise over the plains at (fx, fz) (0 in a corridor between them and north of the field): ridges
## running east-west, wandering a little, growing over DUNE_RAMP from the field's edge.
func dune_rise(fx: float, fz: float) -> float:
	var grow := smoothstep(float(_dune_z), float(_dune_z) + DUNE_RAMP, fz)
	if grow <= 0.0:
		return 0.0
	var n := _dunes.get_noise_2d(fx, fz)
	var ph := (fz + 7.0 * sin(fx * 0.011) + 5.0 * n) / DUNE_SPACING
	var f := ph - floorf(ph)
	var s := clampf((f - (1.0 - DUNE_SHARE) * 0.5) / DUNE_SHARE, 0.0, 1.0)
	var bump := sin(PI * s)
	return grow * DUNE_H * (1.0 + 0.2 * _dunes.get_noise_2d(fx * 0.3 + 500.0, fz * 0.3)) * bump * bump


## The first dune straight south of `from` (within 600 blocks), or NONE.
func first_dune_south_of(from: Vector2i) -> Vector2i:
	for dz in range(0, 600):
		if (column(from.x, from.y + dz) & 15) == DUNE:
			return Vector2i(from.x, from.y + dz)
	return NONE


# --- The sea ------------------------------------------------------------------------------------------------

## The sea's beach on the way from its middle to `from` (the first beach column coming out of it).
func sea_beach_toward(from: Vector2i) -> Vector2i:
	var dir := Vector2(from - _sea).normalized()
	for r in range(0, int(SEA_R + SEA_WOBBLE + BEACH + COAST)):
		var p := Vector2i(roundi(_sea.x + dir.x * r), roundi(_sea.y + dir.y * r))
		if (column(p.x, p.y) & 15) == SEA_SHORE:
			return p
	return NONE


# --- The lakes ----------------------------------------------------------------------------------------------

## The lake of cell (x, z / LAKE_CELL): (centre x, centre z, waterline radius), radius 0 for none. More of them to the
## north; never among the dunes, near the sea or by the mountains.
func lake_in_cell(cell: Vector2i) -> Vector3i:
	var h := absi(_mix(_mix(cell.x * 11 - 7 + _seed * 3) + cell.y * 17 + 9))
	var span := LAKE_CELL - 2 * LAKE_MARGIN
	var c := Vector2i(cell.x * LAKE_CELL + LAKE_MARGIN + (h >> 8) % span, cell.y * LAKE_CELL + LAKE_MARGIN + (h >> 18) % span)
	var north := clampf(-float(c.y) / LAKE_NORTH, 0.0, 1.0)
	if h % 100 >= roundi(lerpf(LAKE_CHANCE, LAKE_NORTH_CHANCE, north)):
		return Vector3i.ZERO
	var r := LAKE_R.x + (h >> 26) % (LAKE_R.y - LAKE_R.x + 1)
	var reach := float(r) + BEACH + COAST
	if float(c.y) + reach > float(_dune_z) - 20.0:
		return Vector3i.ZERO
	if Vector2(c - _sea).length() < SEA_R + SEA_WOBBLE + BEACH + COAST + reach + 10.0:
		return Vector3i.ZERO
	if near_mountain(float(c.x), float(c.y), reach + 10.0):
		return Vector3i.ZERO
	return Vector3i(c.x, c.y, r)


## A lake within `radius` of (x, z) (its coast counts).
func lake_near(x: int, z: int, radius: float) -> bool:
	var c0 := Vector2i(floori((x - radius) / LAKE_CELL), floori((z - radius) / LAKE_CELL))
	var c1 := Vector2i(floori((x + radius) / LAKE_CELL), floori((z + radius) / LAKE_CELL))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var l := lake_in_cell(Vector2i(cx, cz))
			if l.z > 0 and Vector2(l.x - x, l.y - z).length() < radius + l.z + BEACH + COAST:
				return true
	return false


# --- The icy mountains --------------------------------------------------------------------------------------

## How far the range's top rises over the plains at the point of its ridge nearest (fx, fz): PEAK_H in its middle,
## lower toward its ends.
func _ridge_height(fx: float, fz: float) -> float:
	var ab := _m1 - _m0
	var t := clampf((Vector2(fx, fz) - _m0).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return PEAK_H * (0.6 + 0.4 * sin(PI * t))


## How far the icy mountains rise over the plains at (fx, fz) (<= 0 off them): up RAMP per block from their foot, at most
## their ridge's height there.
func mountain_rise(fx: float, fz: float) -> float:
	var d := _segment_distance(fx, fz)
	if d >= HALF_W:
		return 0.0
	return minf(_ridge_height(fx, fz), RAMP * (HALF_W - d))


## (x, z) is on the icy mountains or within `margin` of their foot.
func near_mountain(fx: float, fz: float, margin: float = 0.0) -> bool:
	return _segment_distance(fx, fz) < HALF_W + margin


func _segment_distance(fx: float, fz: float) -> float:
	var ab := _m1 - _m0
	var p := Vector2(fx, fz)
	var t := clampf((p - _m0).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(_m0 + ab * t)


# --- A column's blocks ------------------------------------------------------------------------------------

## The block at y (0 <= y < g) of a column of `kind` whose ground is g (the landing pad and the liquid are SpaceShape's).
static func block(y: int, g: int, kind: int) -> int:
	if y == g - 1:
		return top_block(kind)
	if y >= g - 1 - sub_depth(kind):
		return sub_block(kind)
	return BlockIds.ICY_ROCK


## How many layers of a column's own lie under its top block (the rest is icy rock).
static func sub_depth(kind: int) -> int:
	match kind:
		DUNE:
			return DUNE_SUB
		MOUNTAIN, PEAK:
			return 0
	return SUB_DEPTH


## The top block: soil, ice pebbles, dark dune grains, the wet shore (and the basins' beds), icy rock, pale pebbles on the
## mountains' top.
static func top_block(kind: int) -> int:
	match kind:
		PEBBLES, PEAK:
			return BlockIds.ICE_PEBBLES
		DUNE:
			return BlockIds.DUNE_SAND
		SHORE, LAKE, SEA_SHORE, SEA:
			return BlockIds.WET_SHORE
		MOUNTAIN:
			return BlockIds.ICY_ROCK
	return BlockIds.TITAN_SOIL


## The layers under the top: dark grains inside a dune, soil elsewhere.
static func sub_block(kind: int) -> int:
	return BlockIds.DUNE_SAND if kind == DUNE else BlockIds.TITAN_SOIL


## A plains kind (soil or pebbles: where the landing pad and the ice boulders may be).
static func is_plains(kind: int) -> bool:
	return kind == PLAINS or kind == PEBBLES


## A shore kind (a lake's or the sea's beach and the foot of its coast).
static func is_shore(kind: int) -> bool:
	return kind == SHORE or kind == SEA_SHORE


## A basin's bed kind (under the methane).
static func is_bed(kind: int) -> bool:
	return kind == LAKE or kind == SEA


# --- Sights ---------------------------------------------------------------------------------------------

## The sight at a column of packed `c` (column()) at (x, z): &"sea" (in the sea or on its shore), &"lake" (a lake or its
## shore), &"dunes" (on a dune), &"mountain" (the mountains' top), or &"".
func sight(_x: int, _z: int, c: int) -> StringName:
	match c & 15:
		SEA, SEA_SHORE:
			return &"sea"
		LAKE, SHORE:
			return &"lake"
		DUNE:
			return &"dunes"
		PEAK:
			return &"mountain"
	return &""


static func _pack(h: float, kind: int) -> int:
	return clampi(roundi(h), SpaceShape.MIN_GROUND, SpaceShape.MAX_GROUND) * 16 + kind


static func _mix(v: int) -> int:
	var h := v * 668265263 + 374761393
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
