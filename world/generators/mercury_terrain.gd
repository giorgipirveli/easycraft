class_name MercuryTerrain
extends RefCounted
## Mercury's regions as pure rules (cosmos, spec §21b.2), for SpaceShape's planet MERCURY: every rule is a function of the
## seed and (x, z), read-only after construction but for its caches of drawn features (a mutex guards them: the
## generator's threads share it). North is -z, as on MY MAP. Every column is a plain column of ground (no overhangs, no
## caves, no liquid).
## - The plains: grey dust over grey rock, gentle swells, patches of darker blue-grey dust.
## - Small craters (at most one per CRATER_CELL cell): a bowl with a raised rim (the Moon's shape); some young ones throw
##   out bright rays of pale dust (their bowl pale too).
## - Big craters (at most one per BIG_CELL cell): a flat floor BIG_DEPTH under the plains, a central peak, terraced walls
##   (TERRACE high each) up to a raised rim. Near a pole (|z| > POLE) their floors hold ice (SHADOW_ICE): the shadowed
##   craters where sunlight never reaches. The ice crater (one per world, far to the north: a sight) has no peak.
## - Long cliffs (lobate scarps: at most one per SCARP_CELL cell, and the great scarp a walk from the world's middle):
##   an arc of a circle whose inside is a raised slab, its back sloping gently down over BACK, its front a face of
##   terraces (STEP high, LEDGE deep) down to the plains, the arc's ends fading out over TAPER. Mercury shrank as it
##   cooled and its crust squeezed up into cliffs like these. Overlapping cliffs keep the higher one.
## No small crater touches a big one or a cliff, and no big crater a cliff or the ice crater (each is dropped where it
## would), so every column belongs to one of them and every step between two columns is at most MAX_STEP (a jump at 0.38
## gravity climbs ~4.4). column() packs a column's height and kind (height * 16 + kind); columns() does a block of them
## at once (the generator's path) and equals it.

const PLAINS := 0       # grey dust
const DARK := 1         # darker blue-grey dust
const RAY := 2          # a young crater's bright rays (and its pale bowl)
const BIG_WALL := 3     # a big crater's terraced wall
const BIG_FLOOR := 4    # a big crater's flat floor
const PEAK := 5         # a big crater's central peak
const ICE := 6          # a polar big crater's floor of ice
const SCARP := 7        # a long cliff's face (and its crest)

const MAX_STEP := 4
const BASE := 52.0
const SWELL := 3.0
const NONE := Vector2i(0x7fffffff, 0x7fffffff)
const DUST_DEPTH := 2           # dust (or ice) under a top block
const DARK_FREQ := 0.011
const DARK_AT := 0.3
const CACHE := 4096             # drawn cells kept (per kind of feature)
# Small craters (the Moon's shape)
const CRATER_CELL := 36
const CRATER_CHANCE := 60       # of 100 cells
const CRATER_MARGIN := 6
const CRATER_R := Vector2i(3, 10)
const CRATER_DEPTH := 0.42      # × the radius
const RIM_OUT := 1.35           # the rim runs out to this × the radius
const RAY_MIN := 5              # a crater this wide or wider ...
const RAY_CHANCE := 30          # ... is young and throws rays (of 100)
const RAY_REACH := 3.0          # × the radius
const RAYS := Vector2i(7, 11)
# Big craters
const BIG_CELL := 220
const BIG_CHANCE := 40          # of 100 cells
const BIG_MARGIN := 40          # a big crater and its rim stay inside their cell (BIG_R.y × BIG_OUT < BIG_MARGIN)
const BIG_R := Vector2i(20, 28)
const BIG_DEPTH := 9            # the floor under the plains
const BIG_RIM := 3              # the rim over the plains
const BIG_OUT := 1.3            # the rim runs out to this × the radius
const FLOOR := 0.45             # the flat floor: this share of the radius
const PEAK_R := 0.2             # the central peak: this share ...
const PEAK_H := 6               # ... this high over the floor
const TERRACE := 3              # the walls' steps
const POLE := 360.0             # beyond this north or south of the world's middle, big craters' floors hold ice
const ICE_DISTANCE := Vector2i(400, 460)   # the ice crater: this far north of the world's middle ...
const ICE_SIDE := 80            # ... at most this far east or west
const ICE_R := 26.0
# Long cliffs (lobate scarps)
const SCARP_CELL := 400
const SCARP_CHANCE := 55        # of 100 cells
const SCARP_R := Vector2i(150, 250)
const SCARP_SPAN := Vector2(0.3, 0.55)   # half the arc (radians)
const SCARP_H := Vector2(12.0, 18.0)
const BACK := 48.0              # the slab's back slopes down over this
const LEDGE := 2.0              # each terrace of the face is this deep ...
const STEP := 3                 # ... and this high
const TAPER := 60.0             # the arc's ends fade out over this (blocks along it)
const LOBES := 3                # the face bulges in and out a little (lobate)
const LOBE := 0.04
const GREAT_R := 230.0          # the great scarp: its arc ...
const GREAT_DISTANCE := Vector2i(110, 150)   # ... its face this far from the world's middle ...
const GREAT_SPAN := 0.7
const GREAT_H := 18.0

var _seed := 0
var _great := []                 # [cx, cz, r0, mid angle, half span, height, lobe phase]
var _ice := Vector2.ZERO
var _swell := FastNoiseLite.new()
var _dark := FastNoiseLite.new()
var _mutex := Mutex.new()
var _arcs := {}
var _bigs := {}
var _smalls := {}


func _init(world_seed: int) -> void:
	_seed = world_seed
	var h := absi(_mix(world_seed + 23))
	var dist := GREAT_DISTANCE.x + h % (GREAT_DISTANCE.y - GREAT_DISTANCE.x + 1)
	var ang := float((h >> 9) % 3600) / 3600.0 * TAU   # from the world's middle toward the great scarp
	var u := Vector2.from_angle(ang)
	var c := u * (GREAT_R + dist)
	_great = [c.x, c.y, GREAT_R, wrapf(ang + PI, -PI, PI), GREAT_SPAN, GREAT_H, float((h >> 21) % 628) / 100.0]
	var hi := absi(_mix(world_seed + 24))
	_ice = Vector2(hi % (2 * ICE_SIDE + 1) - ICE_SIDE,
		-(ICE_DISTANCE.x + (hi >> 8) % (ICE_DISTANCE.y - ICE_DISTANCE.x + 1)))
	_swell.seed = world_seed + 230
	_swell.frequency = 0.004
	_swell.fractal_octaves = 3
	_dark.seed = world_seed + 231
	_dark.frequency = DARK_FREQ
	_dark.fractal_octaves = 2


## The great scarp: [cx, cz, r0, mid angle (from its centre to its face's middle), half span, height, lobe phase].
func great_arc() -> Array:
	return _great


## The middle of the ice crater (far to the north).
func ice_centre() -> Vector2i:
	return Vector2i(roundi(_ice.x), roundi(_ice.y))


## The plains' own height at (x, z) (no crater, no cliff).
func plains_height(x: int, z: int) -> int:
	return roundi(BASE + SWELL * _swell.get_noise_2d(float(x), float(z)))


## Height * 16 + kind of the column at (x, z) (the landing pad's flattening is SpaceShape's).
func column(x: int, z: int) -> int:
	var f := _near(x, z, x, z)
	return _column(x, z, f[0], f[1], f[2])


## [heights (PackedInt32Array), kinds (PackedByteArray)] of sx × sz columns from (x0, z0) (index x + z * sx), exactly
## column()'s, the features near the block drawn once (the generator's path).
func columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var f := _near(x0, z0, x0 + sx - 1, z0 + sz - 1)
	var out := PackedInt32Array()
	out.resize(sx * sz)
	var kinds := PackedByteArray()
	kinds.resize(sx * sz)
	for z in sz:
		for x in sx:
			var c := _column(x0 + x, z0 + z, f[0], f[1], f[2])
			out[x + z * sx] = c >> 4
			kinds[x + z * sx] = c & 15
	return [out, kinds]


## One column from the features near it: a big crater's (at most one holds it), else the cliffs' (the highest), else
## the plains with the small craters' bowls and rims and their rays.
func _column(x: int, z: int, arcs: Array, bigs: Array, smalls: Array) -> int:
	var fx := float(x)
	var fz := float(z)
	var p := BASE + SWELL * _swell.get_noise_2d(fx, fz)
	for b: Array in bigs:
		var dx: float = fx - b[0]
		var dz: float = fz - b[1]
		var r: float = b[2]
		var d2 := dx * dx + dz * dz
		if d2 < r * r * BIG_OUT * BIG_OUT:
			return _big(roundi(p), sqrt(d2) / r, b, fx, fz)
	if not arcs.is_empty():
		var rise := 0.0
		var face := false
		for a: Array in arcs:
			var v := _arc(a, fx, fz)
			if v.x > rise:
				rise = v.x
				face = v.y > 0.0
			elif v.x == rise and v.y > 0.0 and rise > 0.0:
				face = true
		if rise > 0.0:
			return _pack(p + rise, SCARP if face else _patch(fx, fz))
	var dip := 0.0
	var bright := false
	for c: Array in smalls:
		var dx: float = fx - c[0]
		var dz: float = fz - c[1]
		var r: float = c[2]
		dip = _crater_add(dip, dx, dz, r)
		if c[3] > 0.0 and not bright:
			bright = _in_ray(dx, dz, r, c)
	return _pack(p + dip, RAY if bright else _patch(fx, fz))


## A big crater's column at t (its distance / its radius) over plains of height h0.
func _big(h0: int, t: float, b: Array, fx: float, fz: float) -> int:
	if t >= 1.0:   # the raised rim
		return _pack_int(h0 + roundi(BIG_RIM * (BIG_OUT - t) / (BIG_OUT - 1.0)), _patch(fx, fz))
	if t >= FLOOR:   # the terraced wall, from the floor up to the rim
		var u := (t - FLOOR) / (1.0 - FLOOR)
		return _pack_int(h0 - BIG_DEPTH + TERRACE * ceili(u * (BIG_DEPTH + BIG_RIM) / TERRACE), BIG_WALL)
	if b[4] > 0.0 and t < PEAK_R:
		return _pack_int(h0 - BIG_DEPTH + roundi(PEAK_H * (1.0 - t / PEAK_R)), PEAK)
	return _pack_int(h0 - BIG_DEPTH, ICE if b[3] > 0.0 else BIG_FLOOR)


## A cliff's rise at (fx, fz) and whether it is its face: Vector2(rise, 1 on its face or crest).
func _arc(a: Array, fx: float, fz: float) -> Vector2:
	var dx: float = fx - a[0]
	var dz: float = fz - a[1]
	var d := sqrt(dx * dx + dz * dz)
	var r0: float = a[2]
	var height: float = a[5]
	if d < r0 * (1.0 - LOBE) - BACK - 1.0 or d > r0 * (1.0 + LOBE) + _face_width(height) + 1.0:
		return Vector2.ZERO
	var ang := atan2(dz, dx)
	var off := absf(wrapf(ang - a[3], -PI, PI))
	var span: float = a[4]
	if off >= span:
		return Vector2.ZERO
	var top := height * smoothstep(0.0, 1.0, (span - off) * r0 / TAPER)
	var s := d - r0 * (1.0 + LOBE * sin(LOBES * ang + a[6]))
	if s <= 0.0:
		var rise := top * clampf(1.0 + s / BACK, 0.0, 1.0)
		return Vector2(rise, 1.0 if s > -LEDGE and top > STEP else 0.0)
	var down := top - STEP * ceilf(s / LEDGE)
	return Vector2(down, 1.0) if down > 0.0 else Vector2.ZERO


static func _face_width(height: float) -> float:
	return ceilf(height / STEP) * LEDGE + 1.0


## The small craters' change to the ground `total` at offset (dx, dz) from a crater of radius r (the Moon's rule).
static func _crater_add(total: float, dx: float, dz: float, r: float) -> float:
	var d2 := (dx * dx + dz * dz) / (r * r)
	if d2 >= RIM_OUT * RIM_OUT:
		return total
	if d2 < 1.0:
		return total - r * CRATER_DEPTH * (1.0 - d2)
	return total + maxf(1.0, r * 0.16) * (RIM_OUT - sqrt(d2)) / (RIM_OUT - 1.0)


## A young crater's rays at offset (dx, dz): its bowl and rim, and streaks out to RAY_REACH, thinner farther out.
static func _in_ray(dx: float, dz: float, r: float, c: Array) -> bool:
	var t := sqrt(dx * dx + dz * dz) / r
	if t < RIM_OUT:
		return true
	if t >= RAY_REACH:
		return false
	return cos(c[4] * atan2(dz, dx) + c[5]) > 0.55 + 0.4 * (t - RIM_OUT) / (RAY_REACH - RIM_OUT)


## Grey dust or a darker patch.
func _patch(fx: float, fz: float) -> int:
	return DARK if _dark.get_noise_2d(fx, fz) > DARK_AT else PLAINS


# --- The features near a block of columns ------------------------------------------------------------------

## [arcs, bigs, smalls] that may touch the columns x0..x1, z0..z1 (a superset: each column checks its own), in cell order.
func _near(x0: int, z0: int, x1: int, z1: int) -> Array:
	var arcs: Array = []
	var reach := SCARP_R.y * (1.0 + LOBE) + _face_width(SCARP_H.y) + 2.0
	for cz in range(floori((z0 - reach) / SCARP_CELL), floori((z1 + reach) / SCARP_CELL) + 1):
		for cx in range(floori((x0 - reach) / SCARP_CELL), floori((x1 + reach) / SCARP_CELL) + 1):
			var a := arc_in_cell(Vector2i(cx, cz))
			if not a.is_empty() and _arc_box(a, x0, z0, x1, z1):
				arcs.append(a)
	if _arc_box(_great, x0, z0, x1, z1):
		arcs.append(_great)
	var bigs: Array = []
	var big_reach := BIG_R.y * BIG_OUT + 1.0
	for cz in range(floori((z0 - big_reach) / BIG_CELL), floori((z1 + big_reach) / BIG_CELL) + 1):
		for cx in range(floori((x0 - big_reach) / BIG_CELL), floori((x1 + big_reach) / BIG_CELL) + 1):
			var b := big_in_cell(Vector2i(cx, cz))
			if not b.is_empty() and _box_gap(b[0], b[1], x0, z0, x1, z1) < b[2] * BIG_OUT + 1.0:
				bigs.append(b)
	if _box_gap(_ice.x, _ice.y, x0, z0, x1, z1) < ICE_R * BIG_OUT + 1.0:
		bigs.append(_ice_crater())
	var smalls: Array = []
	var small_reach := CRATER_R.y * RAY_REACH + 1.0
	for cz in range(floori((z0 - small_reach) / CRATER_CELL), floori((z1 + small_reach) / CRATER_CELL) + 1):
		for cx in range(floori((x0 - small_reach) / CRATER_CELL), floori((x1 + small_reach) / CRATER_CELL) + 1):
			var c := small_in_cell(Vector2i(cx, cz))
			if not c.is_empty():
				var r: float = c[2] * (RAY_REACH if c[3] > 0.0 else RIM_OUT) + 1.0
				if _box_gap(c[0], c[1], x0, z0, x1, z1) < r:
					smalls.append(c)
	return [arcs, bigs, smalls]


## The ice crater as a big crater: [cx, cz, r, icy, peak].
func _ice_crater() -> Array:
	return [_ice.x, _ice.y, ICE_R, 1.0, 0.0]


## How far (px, pz) is from the box of columns x0..x1, z0..z1 (0 inside).
static func _box_gap(px: float, pz: float, x0: int, z0: int, x1: int, z1: int) -> float:
	return Vector2(clampf(px, x0, x1) - px, clampf(pz, z0, z1) - pz).length()


## An arc's ring (its slab, its face) may touch the box.
static func _arc_box(a: Array, x0: int, z0: int, x1: int, z1: int) -> bool:
	var near := _box_gap(a[0], a[1], x0, z0, x1, z1)
	var far := 0.0
	for p: Vector2 in [Vector2(x0, z0), Vector2(x1, z0), Vector2(x0, z1), Vector2(x1, z1)]:
		far = maxf(far, p.distance_to(Vector2(a[0], a[1])))
	var r0: float = a[2]
	return near <= r0 * (1.0 + LOBE) + _face_width(a[5]) + 1.0 and far >= r0 * (1.0 - LOBE) - BACK - 1.0


# --- Drawn features, cell by cell (cached) --------------------------------------------------------------------

## The long cliff of scarp cell `cell`: [cx, cz, r0, mid angle, half span, height, lobe phase], or [] (none, or it would
## cross the ice crater).
func arc_in_cell(cell: Vector2i) -> Array:
	_mutex.lock()
	var got: Variant = _arcs.get(cell)
	_mutex.unlock()
	if got != null:
		return got
	var a := _draw_arc(cell)
	_mutex.lock()
	if _arcs.size() >= CACHE:
		_arcs.clear()
	_arcs[cell] = a
	_mutex.unlock()
	return a


func _draw_arc(cell: Vector2i) -> Array:
	var h := absi(_mix(_mix(cell.x * 13 + 3 + _seed * 5) + cell.y * 29 + 17))
	if h % 100 >= SCARP_CHANCE:
		return []
	var c := Vector2(cell.x * SCARP_CELL + (h >> 8) % SCARP_CELL, cell.y * SCARP_CELL + (h >> 18) % SCARP_CELL)
	var r0 := float(SCARP_R.x + (h >> 28) % (SCARP_R.y - SCARP_R.x + 1))
	var h2 := absi(_mix(h + 99))
	var a := [c.x, c.y, r0, float(h2 % 3600) / 3600.0 * TAU - PI,
		lerpf(SCARP_SPAN.x, SCARP_SPAN.y, float((h2 >> 12) % 100) / 99.0),
		lerpf(SCARP_H.x, SCARP_H.y, float((h2 >> 20) % 100) / 99.0), float((h2 >> 28) % 628) / 100.0]
	if _arc_touches(a, _ice.x, _ice.y, ICE_R * BIG_OUT + 8.0):
		return []   # never through the ice crater
	return a


## The big crater of big cell `cell`: [cx, cz, r, icy (1 near a pole), peak (1)], or [] (none, or it would touch a cliff
## or the ice crater).
func big_in_cell(cell: Vector2i) -> Array:
	_mutex.lock()
	var got: Variant = _bigs.get(cell)
	_mutex.unlock()
	if got != null:
		return got
	var b := _draw_big(cell)
	_mutex.lock()
	if _bigs.size() >= CACHE:
		_bigs.clear()
	_bigs[cell] = b
	_mutex.unlock()
	return b


func _draw_big(cell: Vector2i) -> Array:
	var h := absi(_mix(_mix(cell.x * 31 + 5 + _seed * 7) + cell.y * 43 - 11))
	if h % 100 >= BIG_CHANCE:
		return []
	var span := BIG_CELL - 2 * BIG_MARGIN
	var c := Vector2(cell.x * BIG_CELL + BIG_MARGIN + (h >> 8) % span, cell.y * BIG_CELL + BIG_MARGIN + (h >> 17) % span)
	var r := float(BIG_R.x + (h >> 26) % (BIG_R.y - BIG_R.x + 1))
	if c.distance_to(_ice) < (r + ICE_R) * BIG_OUT + 8.0 or scarp_near(c.x, c.y, r * BIG_OUT + 4.0):
		return []
	return [c.x, c.y, r, 1.0 if absf(c.y) > POLE else 0.0, 1.0]


## The small crater of crater cell `cell`: [cx, cz, r, young (1: it throws rays), rays, ray phase], or [] (none, or it
## would touch a big crater or a cliff).
func small_in_cell(cell: Vector2i) -> Array:
	_mutex.lock()
	var got: Variant = _smalls.get(cell)
	_mutex.unlock()
	if got != null:
		return got
	var c := _draw_small(cell)
	_mutex.lock()
	if _smalls.size() >= CACHE:
		_smalls.clear()
	_smalls[cell] = c
	_mutex.unlock()
	return c


func _draw_small(cell: Vector2i) -> Array:
	var h := absi(_mix(_mix(cell.x * 7 + 11 + _seed) + cell.y * 13 - 5))
	if h % 100 >= CRATER_CHANCE:
		return []
	var span := CRATER_CELL - 2 * CRATER_MARGIN
	var cx := float(cell.x * CRATER_CELL + CRATER_MARGIN + (h >> 8) % span)
	var cz := float(cell.y * CRATER_CELL + CRATER_MARGIN + (h >> 16) % span)
	var r := float(CRATER_R.x + (h >> 24) % (CRATER_R.y - CRATER_R.x + 1))
	var reach := r * RIM_OUT + 1.0
	if big_near(cx, cz, reach) or scarp_near(cx, cz, reach):
		return []
	var h2 := absi(_mix(h + 7))
	var young := r >= RAY_MIN and h2 % 100 < RAY_CHANCE
	return [cx, cz, r, 1.0 if young else 0.0, float(RAYS.x + (h2 >> 8) % (RAYS.y - RAYS.x + 1)),
		float((h2 >> 16) % 628) / 100.0]


## Some cliff's slab or face lies within `margin` of (x, z).
func scarp_near(x: float, z: float, margin: float) -> bool:
	if _arc_touches(_great, x, z, margin):
		return true
	var cell := Vector2i(floori(x / SCARP_CELL), floori(z / SCARP_CELL))
	var cells := ceili((SCARP_R.y * (1.0 + LOBE) + _face_width(SCARP_H.y) + margin) / SCARP_CELL)
	for dz in range(-cells, cells + 1):
		for dx in range(-cells, cells + 1):
			var a := arc_in_cell(cell + Vector2i(dx, dz))
			if not a.is_empty() and _arc_touches(a, x, z, margin):
				return true
	return false


## Some big crater (or the ice crater), rim and all, lies within `margin` of (x, z).
func big_near(x: float, z: float, margin: float) -> bool:
	if Vector2(x, z).distance_to(_ice) < ICE_R * BIG_OUT + margin:
		return true
	var reach := BIG_R.y * BIG_OUT + margin
	for cz in range(floori((z - reach) / BIG_CELL), floori((z + reach) / BIG_CELL) + 1):
		for cx in range(floori((x - reach) / BIG_CELL), floori((x + reach) / BIG_CELL) + 1):
			var b := big_in_cell(Vector2i(cx, cz))
			if not b.is_empty() and Vector2(x, z).distance_to(Vector2(b[0], b[1])) < b[2] * BIG_OUT + margin:
				return true
	return false


## (x, z) lies in a small crater's bowl or rim.
func small_crater_at(x: int, z: int) -> bool:
	var cell := Vector2i(floori(x / float(CRATER_CELL)), floori(z / float(CRATER_CELL)))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var c := small_in_cell(cell + Vector2i(dx, dz))
			if not c.is_empty() and Vector2(x - c[0], z - c[1]).length() < c[2] * RIM_OUT:
				return true
	return false


## A cliff's face (or its crest) or any big crater lies within `margin` of (x, z): steep ground a secret keeps off.
func steep_near(x: float, z: float, margin: float) -> bool:
	if big_near(x, z, margin):
		return true
	var arcs: Array = [_great]
	var cell := Vector2i(floori(x / SCARP_CELL), floori(z / SCARP_CELL))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var a := arc_in_cell(cell + Vector2i(dx, dz))
			if not a.is_empty():
				arcs.append(a)
	for a: Array in arcs:
		var d := Vector2(x, z).distance_to(Vector2(a[0], a[1]))
		var r0: float = a[2]
		if d < r0 * (1.0 - LOBE) - LEDGE - margin - 1.0 or d > r0 * (1.0 + LOBE) + _face_width(a[5]) + margin:
			continue
		if absf(wrapf(atan2(z - a[1], x - a[0]) - a[3], -PI, PI)) < a[4] + margin / maxf(d, 1.0):
			return true
	return false


## An arc's slab or face lies within `margin` of (x, z).
static func _arc_touches(a: Array, x: float, z: float, margin: float) -> bool:
	var d := Vector2(x, z).distance_to(Vector2(a[0], a[1]))
	var r0: float = a[2]
	if d < r0 * (1.0 - LOBE) - BACK - margin or d > r0 * (1.0 + LOBE) + _face_width(a[5]) + margin:
		return false
	return absf(wrapf(atan2(z - a[1], x - a[0]) - a[3], -PI, PI)) <= a[4] + margin / maxf(d, 1.0)


# --- Places for MY MAP ---------------------------------------------------------------------------------------

## A column on the great scarp's face (its top terrace) on the way from its centre to `from` (the arc's middle part when
## `from` lies off its ends).
func great_face_toward(from: Vector2i) -> Vector2i:
	var a := _great
	var r0: float = a[2]
	var ang := atan2(from.y - a[1], from.x - a[0])
	var limit: float = a[4] - (TAPER + 20.0) / r0
	var off := clampf(wrapf(ang - a[3], -PI, PI), -limit, limit)
	ang = a[3] + off
	var dir := Vector2.from_angle(ang)
	var d := r0 * (1.0 + LOBE * sin(LOBES * ang + a[6])) + 1.0
	for i in 6:   # the first column out from the crest whose own cliff is the face
		var p := Vector2(a[0], a[1]) + dir * (d + i * 0.5)
		var q := Vector2i(roundi(p.x), roundi(p.y))
		if (column(q.x, q.y) & 15) == SCARP:
			return q
	var p := Vector2(a[0], a[1]) + dir * d
	return Vector2i(roundi(p.x), roundi(p.y))


## The middle of the big crater (with a central peak, no ice) nearest `from` within a few big cells, or NONE.
func nearest_crater(from: Vector2i) -> Vector2i:
	var best := NONE
	var best_d := INF
	var cell := Vector2i(floori(from.x / float(BIG_CELL)), floori(from.y / float(BIG_CELL)))
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			var b := big_in_cell(cell + Vector2i(dx, dz))
			if b.is_empty() or b[3] > 0.0:
				continue
			var d := Vector2(from).distance_to(Vector2(b[0], b[1]))
			if d < best_d:
				best_d = d
				best = Vector2i(roundi(b[0]), roundi(b[1]))
	return best


# --- A column's blocks ------------------------------------------------------------------------------------

## The block at y (0 <= y < g) of a column of `kind` whose ground is g (the landing pad is SpaceShape's).
static func block(y: int, g: int, kind: int) -> int:
	if y == g - 1:
		return top_block(kind)
	if y >= g - 1 - sub_depth(kind):
		return sub_block(kind)
	return BlockIds.MERCURY_ROCK


## How many layers of a column's own lie under its top block (the rest is rock): none on the rocky walls and faces.
static func sub_depth(kind: int) -> int:
	match kind:
		BIG_WALL, PEAK, SCARP:
			return 0
	return DUST_DEPTH


## The top block: grey dust, darker dust, the rays' bright dust, rock on the walls, faces and peaks, ice on a polar floor.
static func top_block(kind: int) -> int:
	match kind:
		DARK:
			return BlockIds.DARK_DUST
		RAY:
			return BlockIds.RAY_DUST
		BIG_WALL, PEAK, SCARP:
			return BlockIds.MERCURY_ROCK
		ICE:
			return BlockIds.SHADOW_ICE
	return BlockIds.MERCURY_DUST


## The layers under the top: ice under ice, dust elsewhere.
static func sub_block(kind: int) -> int:
	return BlockIds.SHADOW_ICE if kind == ICE else BlockIds.MERCURY_DUST


## A plains kind (grey dust, darker dust, the rays: where the landing pad and the boulders may be).
static func is_plains(kind: int) -> bool:
	return kind == PLAINS or kind == DARK or kind == RAY


# --- Sights ---------------------------------------------------------------------------------------------

## The sight at a column of packed `c` (column()) at (x, z): &"scarp" (a long cliff's face or crest), &"crater" (a big
## crater's floor or peak), &"ice" (a polar crater's ice), or &"" (the thermometer is SpaceShape's).
func sight(_x: int, _z: int, c: int) -> StringName:
	match c & 15:
		SCARP:
			return &"scarp"
		BIG_FLOOR, PEAK:
			return &"crater"
		ICE:
			return &"ice"
	return &""


static func _pack(h: float, kind: int) -> int:
	return clampi(roundi(h), SpaceShape.MIN_GROUND, SpaceShape.MAX_GROUND) * 16 + kind


static func _pack_int(h: int, kind: int) -> int:
	return clampi(h, SpaceShape.MIN_GROUND, SpaceShape.MAX_GROUND) * 16 + kind


static func _mix(v: int) -> int:
	var h := v * 668265263 + 374761393
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
