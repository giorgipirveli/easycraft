class_name PlutoTerrain
extends RefCounted
## Pluto's regions as pure rules (cosmos, spec §21b.2; New Horizons flew past it in 2015), for SpaceShape's planet PLUTO:
## every rule is a function of the seed and (x, z). Everything the rules look up (the plain's cells and floating hills,
## the mountains' blocks, the peak) is built in _init, before any generator thread starts, and only read afterwards, so
## the generator's threads share it without a lock. North is -z, east +x, as on MY MAP. Every column is a plain column
## of ground (no overhangs, no caves, no liquid). column() packs a column's height and kind (height * 16 + kind).
## - The heart (Tombaugh Regio): a heart shape a walk east of the world's middle (heart_sd: Inigo Quilez's exact heart
##   distance, HEART_S blocks to a unit), its point to the south. Its west half (Sputnik Planitia) is the plain: a basin
##   of pale nitrogen ice at PLAIN_Y, flat (the real one is a plain bigger than Texas and Oklahoma together, its cells
##   only tens of metres high over tens of km: flat at the game's scale), cut into cells CELL blocks across whose edges
##   are darker ice (the ice slowly churns like a lava lamp: warm ice rises in each cell's middle and sinks at its edges),
##   with a rim up to the uplands round it. Floating hills of water ice (lighter than nitrogen ice: they float like
##   icebergs) sit on the cells' edges in its western part (HILL_BAND), where the glaciers carry them from the mountains.
##   Its east half is the heart's bright side: bright methane snow on the uplands.
## - The ice mountains (Tenzing and Hillary Montes): a range of jumbled giant blocks of water ice along the plain's
##   south-west shore, each block flat-topped (BLOCK), rising to PEAK_H over the ground in the range's middle, snowy on
##   top.
## - The red-brown lands (Cthulhu): west of a wandering line (dark_edge), dark tholin dust over red-stained ice, rolling
##   hills whose tops are capped with methane frost (SNOW_LINE), old craters with frosty rims.
## - The uplands everywhere else: peach-tan frost of nitrogen and methane over water ice, gentle swells.
## Every step between two columns is at most MAX_STEP (a jump at 0.063 gravity climbs ~27); the plain, the rim and the
## uplands step one block at most.

const UPLANDS := 0      # peach-tan frost over water ice
const RIM := 1          # the rim from the plain up to the uplands
const PLAIN := 2        # the heart's nitrogen ice
const EDGE := 3         # a cell's edge (darker nitrogen ice)
const HILL := 4         # a floating hill of water ice on the plain
const MOUNTAIN := 5     # a block of the ice mountains
const PEAK := 6         # a snowy top block of the mountains
const DARK := 7         # the red-brown lands' tholin dust
const SNOWCAP := 8      # methane frost on the red-brown lands' hilltops and crater rims
const CRATER := 9       # a crater's red-stained ice
const BRIGHT := 10      # the heart's bright side: methane snow

const NONE := Vector2i(0x7fffffff, 0x7fffffff)
const MAX_STEP := 16
const PLAIN_Y := 44             # the heart plain's ground (the first empty y over its ice)
const BASE := 49.0              # the uplands ...
const SWELL := 2.0              # ... and their swells
const N2_DEPTH := 10            # the nitrogen ice fills the basin this deep under the plain's top
const SUB_DEPTH := 2            # frost, dust or snow under a top block
const RED_DEPTH := 3            # red-stained ice under the red-brown lands' dust
# The heart
const HEART_S := 330.0          # blocks to one unit of the heart shape (1.21 units wide, 1.1 tall: ~400 × 365 blocks)
const HEART_WEST := Vector2i(70, 95)   # the heart's westmost point: this far east of the world's middle ...
const HEART_Z := Vector2i(-40, 20)     # ... and this far north (-) or south (+)
const WOBBLE := 6.0             # the plain's shore wanders this much
const RIM_W := 14.0             # the rim from the plain's ice up to the uplands
# The cells and the floating hills
const CELL := 40                # a cell's grid square (one middle each, somewhere inside it)
const CELL_MARGIN := 6
const EDGE_W := 2.4             # a column whose second-nearest cell middle is within this of its nearest is an edge
const HILL_BAND := 110.0        # floating hills in the plain's western part: within this of its shore ...
const HILL_SHORE := 10.0        # ... and never within this of it
const HILL_CHANCE := 34         # of 100 cell edges (each cell's east and south edges)
const HILL_R := Vector2i(3, 5)
const HILL_H := Vector2i(3, 5)
# The ice mountains
const RANGE_FROM := Vector2(-0.08, 0.08)   # the range's ends in the heart's units, along its south-west side ...
const RANGE_TO := Vector2(-0.40, 0.40)
const RANGE_OUT := 8.0          # ... this far out from it (blocks)
const HALF_W := 32.0            # half the range's width
const BLOCK := 8                # a mountain block's grid square
const PEAK_H := 24              # the tallest blocks' rise over the ground
const PEAK_FROM := 0.85         # a block this high (× PEAK_H) is snowy on top
# The red-brown lands
const DARK_X := Vector2i(95, 125)   # their edge: this far west of the world's middle ...
const DARK_WANDER := 18.0       # ... wandering this much
const DARK_BLEND := 30.0        # the ground blends from the uplands' to theirs over this
const DARK_BASE := 49.0
const DARK_HILLS := 6.0
const SNOW_LINE := 54           # their hilltops from here up are capped with methane frost
const CRATER_CELL := 60
const CRATER_CHANCE := 45       # of 100 cells
const CRATER_R := Vector2i(7, 14)
const CRATER_DEPTH := 0.3       # × the radius
const RIM_OUT := 1.35           # a crater's raised rim runs out to this × the radius
# Features
const LOOKOUT_R := 2            # the Charon Lookout's round floor
const NOISE_MARGIN := 1.5       # FastNoiseLite's values stay within ±1: noise this far from mattering is skipped

var _seed := 0
var _hx := 0.0                  # the heart's point (its south tip), world x and z
var _hz := 0.0
var _dark_x := 0.0
var _m0 := Vector2.ZERO         # the mountain range's spine
var _m1 := Vector2.ZERO
var _sites := {}                # plain cells: Vector2i cell -> Vector2 middle
var _hills: Array[Vector4] = [] # (x, z, radius, height)
var _hill_cells := {}           # Vector2i cell -> PackedInt32Array of hill indices touching it
var _blocks := {}               # mountain block cells: Vector2i cell -> Vector4 (site x, site z, rise, top)
var _peak := Vector2i.ZERO
var _swell := FastNoiseLite.new()
var _shore := FastNoiseLite.new()
var _dark := FastNoiseLite.new()
var _hills_noise := FastNoiseLite.new()
## The Charon Lookout (SpaceShape places it by the landing pad): its middle, the top of its floor, its boxes
## [lo, hi (exclusive), id] and their bounds.
var lookout := NONE
var lookout_y := 0
var _built: Array = []
var _built_lo := Vector3i.ZERO
var _built_hi := Vector3i.ZERO


func _init(world_seed: int) -> void:
	_seed = world_seed
	var h := absi(_mix(world_seed + 26))
	var west := HEART_WEST.x + h % (HEART_WEST.y - HEART_WEST.x + 1)
	var north := HEART_Z.x + (h >> 7) % (HEART_Z.y - HEART_Z.x + 1)
	_hx = west + 0.6036 * HEART_S   # the lobes' circles: centred (±0.25, 0.75), radius √2/4
	_hz = north + 0.75 * HEART_S
	_dark_x = -float(DARK_X.x + (h >> 14) % (DARK_X.y - DARK_X.x + 1))
	var out := Vector2(-1.0, 1.0).normalized() * RANGE_OUT   # south-west in the world (+z is south)
	_m0 = heart_to_world(RANGE_FROM) + out
	_m1 = heart_to_world(RANGE_TO) + out
	_swell.seed = world_seed + 260
	_swell.frequency = 0.006
	_swell.fractal_octaves = 2
	_shore.seed = world_seed + 261
	_shore.frequency = 0.012
	_shore.fractal_octaves = 2
	_dark.seed = world_seed + 262
	_dark.frequency = 0.009
	_dark.fractal_octaves = 2
	_hills_noise.seed = world_seed + 263
	_hills_noise.frequency = 0.004
	_build_plain()
	_build_mountains()


# --- The heart -------------------------------------------------------------------------------------------------------

## A point of the heart's units (x east, y north; its point at 0, 0) in the world (x, z).
func heart_to_world(p: Vector2) -> Vector2:
	return Vector2(_hx + p.x * HEART_S, _hz - p.y * HEART_S)


## The world's (x, z) in the heart's units.
func world_to_heart(fx: float, fz: float) -> Vector2:
	return Vector2((fx - _hx) / HEART_S, (_hz - fz) / HEART_S)


## The heart's signed distance at (fx, fz), in blocks (negative inside), its shore wandering a little.
func heart_sd(fx: float, fz: float) -> float:
	return sd_heart(world_to_heart(fx, fz)) * HEART_S + WOBBLE * _shore.get_noise_2d(fx, fz)


## The plain's signed distance (the heart's west half), in blocks (negative on the plain).
func plain_sd(fx: float, fz: float) -> float:
	return maxf(heart_sd(fx, fz), fx - _hx)


## Inigo Quilez's exact signed distance to a heart (its point at the origin, its lobes up to y 1.1, 1.21 wide).
static func sd_heart(q: Vector2) -> float:
	var p := Vector2(absf(q.x), q.y)
	if p.y + p.x > 1.0:
		return (p - Vector2(0.25, 0.75)).length() - sqrt(2.0) / 4.0
	var m := maxf(p.x + p.y, 0.0) * 0.5
	return sqrt(minf((p - Vector2(0.0, 1.0)).length_squared(), (p - Vector2(m, m)).length_squared())) * signf(p.x - p.y)


## The heart's westmost point (the plain's) in the world.
func heart_west() -> Vector2i:
	var w := heart_to_world(Vector2(-0.6036, 0.75))
	return Vector2i(roundi(w.x), roundi(w.y))


## The middle of the heart's bright east half.
func bright_centre() -> Vector2i:
	var c := heart_to_world(Vector2(0.28, 0.72))
	return Vector2i(roundi(c.x), roundi(c.y))


# --- The plain's cells and floating hills (built once) ----------------------------------------------------------------

func _build_plain() -> void:
	var lo := heart_to_world(Vector2(-0.62, 1.12)) - Vector2(CELL * 2, CELL * 2)
	var hi := heart_to_world(Vector2(0.02, -0.02)) + Vector2(CELL * 2, CELL * 2)
	var c0 := Vector2i(floori(lo.x / CELL), floori(lo.y / CELL))
	var c1 := Vector2i(floori(hi.x / CELL), floori(hi.y / CELL))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_sites[Vector2i(cx, cz)] = _site(cx, cz)
	for cz in range(c0.y, c1.y):
		for cx in range(c0.x, c1.x):
			var a: Vector2 = _sites[Vector2i(cx, cz)]
			for n: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var k := absi(_mix(_mix(cx * 29 + n.x * 7 + _seed) + cz * 31 + n.y * 13))
				if k % 100 >= HILL_CHANCE:
					continue
				var m := (a + (_sites[Vector2i(cx, cz) + n] as Vector2)) * 0.5
				var inside := -plain_sd(m.x, m.y)
				if inside < HILL_SHORE or inside > HILL_BAND or near_mountain(m.x, m.y, 6.0):
					continue
				var r := HILL_R.x + (k >> 8) % (HILL_R.y - HILL_R.x + 1)
				var ht := HILL_H.x + (k >> 12) % (HILL_H.y - HILL_H.x + 1)
				_hills.append(Vector4(roundf(m.x), roundf(m.y), float(r), float(ht)))
	for i in _hills.size():
		var hl := _hills[i]
		for cz in range(floori((hl.y - hl.z) / CELL), floori((hl.y + hl.z) / CELL) + 1):
			for cx in range(floori((hl.x - hl.z) / CELL), floori((hl.x + hl.z) / CELL) + 1):
				var key := Vector2i(cx, cz)
				var list: PackedInt32Array = _hill_cells.get(key, PackedInt32Array())
				list.append(i)
				_hill_cells[key] = list


## The middle of cell (cx, cz), somewhere inside it.
func _site(cx: int, cz: int) -> Vector2:
	var h := absi(_mix(_mix(cx * 73 + 11 + _seed * 5) + cz * 97 - 3))
	var span := CELL - 2 * CELL_MARGIN
	return Vector2(cx * CELL + CELL_MARGIN + h % span, cz * CELL + CELL_MARGIN + (h >> 10) % span)


## The kind of a plain column at (fx, fz): a cell's edge, else its ice.
func _cell_kind(fx: float, fz: float) -> int:
	var c := Vector2i(floori(fx / CELL), floori(fz / CELL))
	var p := Vector2(fx, fz)
	var d1 := INF
	var d2 := INF
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var s: Variant = _sites.get(c + Vector2i(dx, dz))
			if s == null:
				continue
			var d := p.distance_to(s)
			if d < d1:
				d2 = d1
				d1 = d
			elif d < d2:
				d2 = d
	return EDGE if d2 - d1 < EDGE_W else PLAIN


## How far the floating hills rise over the plain at (fx, fz) (0 off them).
func hill_rise(fx: float, fz: float) -> float:
	var list: Variant = _hill_cells.get(Vector2i(floori(fx / CELL), floori(fz / CELL)))
	if list == null:
		return 0.0
	var best := 0.0
	for i: int in (list as PackedInt32Array):
		var hl := _hills[i]
		var d2 := ((fx - hl.x) * (fx - hl.x) + (fz - hl.y) * (fz - hl.y)) / (hl.z * hl.z)
		if d2 < 1.0:
			best = maxf(best, hl.w * (1.0 - d2))
	return best


## The floating hills: (x, z, radius, height) each.
func hills() -> Array[Vector4]:
	return _hills


## The floating hill nearest `from` (its middle), or NONE.
func nearest_hill(from: Vector2i) -> Vector2i:
	var best := NONE
	var best_d := INF
	for hl in _hills:
		var d := Vector2(hl.x - from.x, hl.y - from.y).length()
		if d < best_d:
			best_d = d
			best = Vector2i(int(hl.x), int(hl.y))
	return best


## The plain's shore on the way from `from` to the heart's westmost point (the first plain column), or NONE.
func plain_shore_toward(from: Vector2i) -> Vector2i:
	var to := Vector2(heart_west())
	var dir := (to - Vector2(from)).normalized()
	for r in range(0, 600):
		var p := Vector2i(roundi(from.x + dir.x * r), roundi(from.y + dir.y * r))
		var k := column(p.x, p.y) & 15
		if k == PLAIN or k == EDGE:
			return p
	return NONE


# --- The ice mountains (built once) -----------------------------------------------------------------------------------

func _build_mountains() -> void:
	var lo := _m0.min(_m1) - Vector2(HALF_W + BLOCK * 2, HALF_W + BLOCK * 2)
	var hi := _m0.max(_m1) + Vector2(HALF_W + BLOCK * 2, HALF_W + BLOCK * 2)
	var best := -1.0
	for cz in range(floori(lo.y / BLOCK), floori(hi.y / BLOCK) + 1):
		for cx in range(floori(lo.x / BLOCK), floori(hi.x / BLOCK) + 1):
			var h := absi(_mix(_mix(cx * 41 - 17 + _seed * 7) + cz * 53 + 29))
			var s := Vector2(cx * BLOCK + 1 + h % (BLOCK - 2), cz * BLOCK + 1 + (h >> 9) % (BLOCK - 2))
			var t := _along(s.x, s.y)
			var d := _segment_distance(s.x, s.y)
			var env := smoothstep(HALF_W, HALF_W * 0.25, d) * smoothstep(0.0, 0.22, t) * smoothstep(1.0, 0.78, t)
			var rise := env * PEAK_H * (0.75 + 0.25 * float((h >> 18) % 100) / 99.0)
			var top := roundf(_base_at(s.x, s.y) + rise) if rise >= 0.5 else 0.0   # (a block under 0.5 is no mountain)
			_blocks[Vector2i(cx, cz)] = Vector4(s.x, s.y, rise, top)
			if rise > best:
				best = rise
				_peak = Vector2i(int(s.x), int(s.y))


## The mountains' rise over the ground at (fx, fz): the rise of the block (the nearest block middle) it is in; 0 off the
## range.
func mountain_rise(fx: float, fz: float) -> float:
	return _block_at(fx, fz).z


## The mountain block (fx, fz) is in: (site x, site z, rise, top: its flat top's height), rise 0 off the range.
func _block_at(fx: float, fz: float) -> Vector4:
	if _segment_distance(fx, fz) >= HALF_W + BLOCK:
		return Vector4.ZERO
	var c := Vector2i(floori(fx / BLOCK), floori(fz / BLOCK))
	var best := INF
	var out := Vector4.ZERO
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var b: Variant = _blocks.get(c + Vector2i(dx, dz))
			if b == null:
				continue
			var v: Vector4 = b
			var d := (fx - v.x) * (fx - v.x) + (fz - v.y) * (fz - v.y)
			if d < best:
				best = d
				out = v
	return out


## The mountains' highest block (its middle).
func peak_centre() -> Vector2i:
	return _peak


## (fx, fz) is on the mountain range or within `margin` of it.
func near_mountain(fx: float, fz: float, margin: float = 0.0) -> bool:
	return _segment_distance(fx, fz) < HALF_W + margin


func _along(fx: float, fz: float) -> float:
	var ab := _m1 - _m0
	return clampf((Vector2(fx, fz) - _m0).dot(ab) / ab.length_squared(), 0.0, 1.0)


func _segment_distance(fx: float, fz: float) -> float:
	var ab := _m1 - _m0
	return Vector2(fx, fz).distance_to(_m0 + ab * _along(fx, fz))


# --- The red-brown lands ---------------------------------------------------------------------------------------------

## The red-brown lands' edge at z: every column west of it (less x) is theirs.
func dark_edge(fz: float) -> float:
	return _dark_x + DARK_WANDER * _dark.get_noise_2d(fz * 0.7, 900.0)


## The first red-brown column straight west of `from` (within 600 blocks), or NONE.
func first_dark_west_of(from: Vector2i) -> Vector2i:
	for dx in range(0, 600):
		var k := column(from.x - dx, from.y) & 15
		if is_dark(k):
			return Vector2i(from.x - dx, from.y)
	return NONE


## The crater of cell (cx, cz) (the red-brown lands'): (centre x, centre z, radius), radius 0 for none.
func crater_in_cell(cell: Vector2i) -> Vector3i:
	var h := absi(_mix(_mix(cell.x * 19 + 5 + _seed * 11) + cell.y * 23 - 7))
	if h % 100 >= CRATER_CHANCE:
		return Vector3i.ZERO
	var margin := CRATER_R.y + 8
	var span := CRATER_CELL - 2 * margin
	return Vector3i(cell.x * CRATER_CELL + margin + (h >> 8) % span, cell.y * CRATER_CELL + margin + (h >> 16) % span,
		CRATER_R.x + (h >> 24) % (CRATER_R.y - CRATER_R.x + 1))


## The craters' change to the ground at (fx, fz): a bowl (negative) inside one rising smoothly to a raised rim at its edge,
## the rim falling away outside it (no sharp crest: every step a block or two).
func crater_depth(fx: float, fz: float) -> float:
	var cell := Vector2i(floori(fx / CRATER_CELL), floori(fz / CRATER_CELL))
	var total := 0.0
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var c := crater_in_cell(cell + Vector2i(dx, dz))
			if c.z == 0:
				continue
			var r := float(c.z)
			var d2 := ((fx - c.x) * (fx - c.x) + (fz - c.y) * (fz - c.y)) / (r * r)
			if d2 >= RIM_OUT * RIM_OUT:
				continue
			var rim := maxf(1.0, r * 0.12)
			if d2 < 1.0:
				total += rim * d2 - r * CRATER_DEPTH * (1.0 - d2)
			else:
				total += rim * (RIM_OUT - sqrt(d2)) / (RIM_OUT - 1.0)
	return total


# --- A column ---------------------------------------------------------------------------------------------------------

## The uplands' own height at (fx, fz).
func uplands_height(fx: float, fz: float) -> float:
	return BASE + SWELL * _swell.get_noise_2d(fx, fz)


## Height * 16 + kind of the column at (x, z) (the landing pad's flattening is SpaceShape's). Noise nothing can need is
## skipped (the shore's wander far from the heart's edge, the red-brown lands' edge far from it: FastNoiseLite stays
## within ±1, NOISE_MARGIN is more), so every column gets the same answer, cheaper.
func column(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var hd := sd_heart(world_to_heart(fx, fz)) * HEART_S
	if hd > -WOBBLE * NOISE_MARGIN and hd < RIM_W + WOBBLE * NOISE_MARGIN:
		hd += WOBBLE * _shore.get_noise_2d(fx, fz)
	var pd := maxf(hd, fx - _hx)
	var ground := 0.0
	var kind := UPLANDS
	if pd < 0.0:   # the plain: flat nitrogen ice in cells, floating hills
		ground = PLAIN_Y
		kind = _cell_kind(fx, fz)
		var hill := hill_rise(fx, fz)
		if hill >= 0.5:
			ground = PLAIN_Y + hill
			kind = HILL
	else:
		var up := uplands_height(fx, fz)
		ground = up
		if pd < RIM_W:   # the rim up to the uplands (the bright side's snow on its east)
			ground = lerpf(PLAIN_Y, up, smoothstep(0.0, RIM_W, pd))
			kind = BRIGHT if hd < 0.0 else RIM
		elif hd < 0.0:   # the heart's bright east half
			kind = BRIGHT
		elif fx < _dark_x + DARK_WANDER * NOISE_MARGIN:   # (east of that the red-brown lands never reach)
			var t := smoothstep(0.0, DARK_BLEND, dark_edge(fz) - fx)
			if t > 0.0:   # the red-brown lands: rolling hills, old craters (fading in over the blend)
				var crater := crater_depth(fx, fz)
				ground = lerpf(up, DARK_BASE + DARK_HILLS * _hills_noise.get_noise_2d(fx, fz) + crater, t)
				if t >= 0.5:
					kind = DARK
					if crater < -0.8:
						kind = CRATER
					elif crater > 0.8 or roundi(ground) >= SNOW_LINE:
						kind = SNOWCAP
	var block := _block_at(fx, fz)
	if block.z >= 0.5:
		return _pack(maxf(block.w, roundf(ground)), PEAK if block.z >= PEAK_H * PEAK_FROM else MOUNTAIN)
	return _pack(ground, kind)


## The ground under the mountains at a block's middle (the plain, the rim or the uplands; their flat top stands on it).
func _base_at(fx: float, fz: float) -> float:
	var pd := plain_sd(fx, fz)
	var up := uplands_height(fx, fz)
	if pd < 0.0:
		return PLAIN_Y
	if pd < RIM_W:
		return lerpf(PLAIN_Y, up, smoothstep(0.0, RIM_W, pd))
	return up


## [grounds (PackedInt32Array), kinds (PackedByteArray)] of sx × sz columns from (x0, z0) (column()'s, one pass).
func columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var out := PackedInt32Array()
	out.resize(sx * sz)
	var kinds := PackedByteArray()
	kinds.resize(sx * sz)
	for z in sz:
		for x in sx:
			var c := column(x0 + x, z0 + z)
			out[x + z * sx] = c >> 4
			kinds[x + z * sx] = c & 15
	return [out, kinds]


# --- A column's blocks ------------------------------------------------------------------------------------------------

## The block at y (0 <= y < g) of a column of `kind` whose ground is g (the landing pad is SpaceShape's).
static func block(y: int, g: int, kind: int) -> int:
	if y == g - 1:
		return top_block(kind)
	if y >= g - 1 - sub_depth(kind, g):
		return sub_block(kind, y, g)
	return BlockIds.WATER_ICE


## How many layers of a column's own lie under its top block (the rest is water ice).
static func sub_depth(kind: int, g: int) -> int:
	match kind:
		PLAIN, EDGE, HILL:   # the nitrogen ice fills the basin (a floating hill's water ice, then nitrogen, under it)
			return maxi(g - 1 - (PLAIN_Y - N2_DEPTH), 0)
		MOUNTAIN, PEAK:
			return 0
		DARK, SNOWCAP:
			return SUB_DEPTH + RED_DEPTH
		CRATER:
			return RED_DEPTH
	return SUB_DEPTH


## The layer at y under a column's top block (above the water ice).
static func sub_block(kind: int, y: int, g: int) -> int:
	match kind:
		PLAIN, EDGE:
			return BlockIds.NITROGEN_ICE
		HILL:   # an iceberg: its water ice reaches as far under the plain as twice its height over it
			return BlockIds.WATER_ICE if y >= PLAIN_Y - 2 * (g - PLAIN_Y) else BlockIds.NITROGEN_ICE
		DARK, SNOWCAP:
			return BlockIds.THOLIN_DUST if y >= g - 1 - SUB_DEPTH else BlockIds.RED_ICE
		CRATER:
			return BlockIds.RED_ICE
		BRIGHT:
			return BlockIds.NITROGEN_ICE
	return BlockIds.PLUTO_FROST


## The top block of a column of `kind`.
static func top_block(kind: int) -> int:
	match kind:
		PLAIN:
			return BlockIds.NITROGEN_ICE
		EDGE:
			return BlockIds.CELL_EDGE
		HILL, MOUNTAIN:
			return BlockIds.WATER_ICE
		PEAK, SNOWCAP, BRIGHT:
			return BlockIds.METHANE_SNOW
		DARK:
			return BlockIds.THOLIN_DUST
		CRATER:
			return BlockIds.RED_ICE
	return BlockIds.PLUTO_FROST


## The uplands (where the landing pad, the aliens' camp and the boulders may be).
static func is_plains(kind: int) -> bool:
	return kind == UPLANDS


## The heart's plain (its ice or a cell's edge).
static func is_plain(kind: int) -> bool:
	return kind == PLAIN or kind == EDGE


## The red-brown lands (their dust, snowy tops or craters).
static func is_dark(kind: int) -> bool:
	return kind == DARK or kind == SNOWCAP or kind == CRATER


## Steep ground a secret keeps off: the mountains and the floating hills' band of the plain.
func steep_near(fx: float, fz: float, margin: float) -> bool:
	if near_mountain(fx, fz, margin + 4.0):
		return true
	var pd := plain_sd(fx, fz)
	return pd < margin and pd > -(HILL_BAND + HILL_H.y + margin)


# --- Sights -----------------------------------------------------------------------------------------------------------

## The sight at a column of packed `c` (column()): &"heart" (on the plain), &"hills" (a floating hill), &"mountains" (a
## snowy top block), &"dark" (the red-brown lands), &"bright" (the heart's bright side), or &"".
func sight(_x: int, _z: int, c: int) -> StringName:
	match c & 15:
		PLAIN, EDGE:
			return &"heart"
		HILL:
			return &"hills"
		PEAK:
			return &"mountains"
		DARK, SNOWCAP, CRATER:
			return &"dark"
		BRIGHT:
			return &"bright"
	return &""


# --- The Charon Lookout (by the landing pad) --------------------------------------------------------------------------

## Builds the Charon Lookout at column c on grounds `ground` (a Callable (x, z) -> int, the pad's blend included): a round
## floor of frost bricks (a plinth where the ground dips), a telescope on a truss looking west and up at Charon, a
## globe of Charon on a post and a glowing heart. Called once, before any generator thread starts.
func place_lookout(c: Vector2i, ground: Callable) -> void:
	lookout = c
	var top := -0x7fffffff
	var low := 0x7fffffff
	for dz in range(-LOOKOUT_R, LOOKOUT_R + 1):
		for dx in range(-LOOKOUT_R, LOOKOUT_R + 1):
			if dx * dx + dz * dz > LOOKOUT_R * LOOKOUT_R + 1:
				continue
			var g := int(ground.call(c.x + dx, c.y + dz))
			top = maxi(top, g)
			low = mini(low, g)
	lookout_y = top
	_built.clear()
	for dz in range(-LOOKOUT_R, LOOKOUT_R + 1):
		for dx in range(-LOOKOUT_R, LOOKOUT_R + 1):
			if dx * dx + dz * dz > LOOKOUT_R * LOOKOUT_R + 1:
				continue
			_add(Vector3i(c.x + dx, low - 1, c.y + dz), Vector3i(c.x + dx + 1, top, c.y + dz + 1), BlockIds.FROST_BRICK)
	var y := top
	_add(Vector3i(c.x, y, c.y), Vector3i(c.x + 1, y + 2, c.y + 1), BlockIds.TRUSS)             # the stand ...
	_add(Vector3i(c.x - 1, y + 2, c.y), Vector3i(c.x + 1, y + 3, c.y + 1), BlockIds.TELESCOPE)  # ... the tube ...
	_add(Vector3i(c.x - 2, y + 3, c.y), Vector3i(c.x - 1, y + 4, c.y + 1), BlockIds.TELESCOPE)  # ... up at Charon
	_add(Vector3i(c.x + 1, y, c.y + 1), Vector3i(c.x + 2, y + 1, c.y + 2), BlockIds.TRUSS)     # a post ...
	_add(Vector3i(c.x + 1, y + 1, c.y + 1), Vector3i(c.x + 2, y + 2, c.y + 2), BlockIds.CHARON_GLOBE)   # ... Charon
	_add(Vector3i(c.x + 1, y, c.y - 1), Vector3i(c.x + 2, y + 1, c.y), BlockIds.HEART_BEACON)  # a glowing heart
	_built_lo = Vector3i(c.x - LOOKOUT_R, low - 1, c.y - LOOKOUT_R)
	_built_hi = Vector3i(c.x + LOOKOUT_R + 1, y + 4, c.y + LOOKOUT_R + 1)


func _add(lo: Vector3i, hi: Vector3i, id: int) -> void:
	_built.append([lo, hi, id])


## The Charon Lookout's block at p, or -1 (the later box wins).
func built_at(p: Vector3i) -> int:
	if p.x < _built_lo.x or p.y < _built_lo.y or p.z < _built_lo.z or p.x >= _built_hi.x or p.y >= _built_hi.y \
			or p.z >= _built_hi.z:
		return -1
	for i in range(_built.size() - 1, -1, -1):
		var b: Array = _built[i]
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		if p.x >= lo.x and p.y >= lo.y and p.z >= lo.z and p.x < hi.x and p.y < hi.y and p.z < hi.z:
			return int(b[2])
	return -1


## The column (x, z) is under the Charon Lookout (within `margin`).
func on_lookout(x: int, z: int, margin: int = 0) -> bool:
	return lookout != NONE and absi(x - lookout.x) <= LOOKOUT_R + margin and absi(z - lookout.y) <= LOOKOUT_R + margin


## Writes the Charon Lookout where it reaches into this buffer.
func write(buf: VoxelBuffer, origin: Vector3i) -> void:
	if _built.is_empty():
		return
	var end := origin + buf.get_size()
	if _built_hi.x <= origin.x or _built_hi.y <= origin.y or _built_hi.z <= origin.z or _built_lo.x >= end.x \
			or _built_lo.y >= end.y or _built_lo.z >= end.z:
		return
	for b: Array in _built:
		var lo := (b[0] as Vector3i).max(origin)
		var hi := (b[1] as Vector3i).min(end)
		if lo.x >= hi.x or lo.y >= hi.y or lo.z >= hi.z:
			continue
		buf.fill_area(int(b[2]), lo - origin, hi - origin, VoxelBuffer.CHANNEL_TYPE)


static func _pack(h: float, kind: int) -> int:
	return clampi(roundi(h), SpaceShape.MIN_GROUND, SpaceShape.MAX_GROUND) * 16 + kind


static func _mix(v: int) -> int:
	var h := v * 668265263 + 374761393
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
