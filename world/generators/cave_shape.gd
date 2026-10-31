class_name CaveShape
extends RefCounted
## Pure cave rules. Three 3D noises: a spaghetti tunnel runs where |a| and |b| are both small, a
## cavern opens where c is high (deep underground only). The noises are sampled on a coarse
## 4-block grid and interpolated, like Minecraft; `cell_may_carve` proves when a whole 4³ cell
## cannot hold a cave so the generator can skip it. Everything is a function of world coordinates,
## so chunks meet without seams. Read-only after construction (shared by generator threads).

const CELL := 4
const TUNNEL_WIDTH := 0.12          # |a| and |b| below this carve a tunnel (about 4 blocks wide)
const TUNNEL_SQUASH := 1.4          # vertical noise scale: tunnels are wider than tall, and wander sideways
const CAVERN_THRESHOLD := 0.6       # c above this carves a cavern, at full depth
const CAVERN_START_Y := 0           # no caverns above this
const CAVERN_FULL_Y := -24          # caverns reach full size below this
const LAND_CRUST := 4               # solid blocks kept under the ground, unless an entrance is open
const WATER_CRUST := 6              # solid blocks kept under oceans, rivers and lakes
const FLOOD_Y := -40                # caves below this are underground lakes
const ENTRANCE_THRESHOLD := 0.6     # entrance noise above this lets tunnels break the surface
const _EPSILON := 0.000001          # float slack for the skip test (lerp can round past a corner)

var _a := FastNoiseLite.new()
var _b := FastNoiseLite.new()
var _c := FastNoiseLite.new()
var _entrance := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	for n: FastNoiseLite in [_a, _b]:
		n.frequency = 0.02
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
	_a.seed = world_seed + 10
	_b.seed = world_seed + 11
	_c.seed = world_seed + 12
	_c.frequency = 0.014
	_c.fractal_octaves = 2
	_entrance.seed = world_seed + 13
	_entrance.frequency = 0.02
	_entrance.fractal_type = FastNoiseLite.FRACTAL_NONE


## Raw noise values (a, b, c) at a grid point.
func sample(x: int, y: int, z: int) -> Vector3:
	var ys := y * TUNNEL_SQUASH
	return Vector3(_a.get_noise_3d(x, ys, z), _b.get_noise_3d(x, ys, z), _c.get_noise_3d(x, y, z))


## Interpolated values at any block: the reference the generator's fast path must match.
func value_at(x: int, y: int, z: int) -> Vector3:
	var x0 := x - posmod(x, CELL)
	var y0 := y - posmod(y, CELL)
	var z0 := z - posmod(z, CELL)
	var corners := PackedVector3Array()
	corners.resize(8)
	for i in 8:
		corners[i] = sample(x0 + (i & 1) * CELL, y0 + ((i >> 1) & 1) * CELL, z0 + ((i >> 2) & 1) * CELL)
	return interpolate(corners, (x - x0) / float(CELL), (y - y0) / float(CELL), (z - z0) / float(CELL))


## Trilinear interpolation; corner i sits at (i & 1, (i >> 1) & 1, (i >> 2) & 1).
static func interpolate(c: PackedVector3Array, fx: float, fy: float, fz: float) -> Vector3:
	var bottom := c[0].lerp(c[1], fx).lerp(c[2].lerp(c[3], fx), fy)
	var top := c[4].lerp(c[5], fx).lerp(c[6].lerp(c[7], fx), fy)
	return bottom.lerp(top, fz)


## c needed for a cavern at height y (above 1 means never).
func cavern_threshold(y: int) -> float:
	if y >= CAVERN_START_Y:
		return 2.0
	var t := clampf(float(CAVERN_START_Y - y) / (CAVERN_START_Y - CAVERN_FULL_Y), 0.0, 1.0)
	return lerpf(1.0, CAVERN_THRESHOLD, t)


## False when no block inside the cell can be a cave. Exact: interpolated values stay within the
## range of the corners. threshold_a/b: cavern thresholds at the cell's bottom and top.
static func cell_may_carve(c: PackedVector3Array, threshold_a: float, threshold_b: float) -> bool:
	var lo := c[0]
	var hi := c[0]
	for i in range(1, 8):
		lo = lo.min(c[i])
		hi = hi.max(c[i])
	var tunnel := lo.x < TUNNEL_WIDTH + _EPSILON and hi.x > -TUNNEL_WIDTH - _EPSILON \
		and lo.y < TUNNEL_WIDTH + _EPSILON and hi.y > -TUNNEL_WIDTH - _EPSILON
	return tunnel or hi.z > minf(threshold_a, threshold_b) - _EPSILON


## Columns at or just above the water line keep the thicker water crust (river banks, beaches).
static func is_near_water(surface: int) -> bool:
	return surface <= MeadowsShape.SEA_LEVEL + 2


## True where tunnels may break through the ground (rare cave entrances).
func entrance_open(x: int, z: int) -> bool:
	return _entrance.get_noise_2d(x, z) > ENTRANCE_THRESHOLD


## What a cave makes of block y in a column with ground height `surface`: AIR, WATER (flooded deep
## caves) or -1 (stays solid). near_water: the column is under or next to water (thicker crust).
func decide(v: Vector3, y: int, surface: int, near_water: bool, entrance: bool = false) -> int:
	if y <= MeadowsShape.WORLD_BOTTOM + 3 or y >= surface:
		return -1
	if near_water:
		if y >= surface - WATER_CRUST:
			return -1
	elif not entrance and y >= surface - LAND_CRUST:
		return -1
	var tunnel := absf(v.x) < TUNNEL_WIDTH and absf(v.y) < TUNNEL_WIDTH
	if not tunnel and v.z <= cavern_threshold(y):
		return -1
	return BlockIds.WATER if y < FLOOD_Y else BlockIds.AIR
