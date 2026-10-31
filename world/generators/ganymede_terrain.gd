class_name GanymedeTerrain
extends RefCounted
## Ganymede's regions as pure rules (cosmos, spec §21b.2; spacecraft flew past it in 1979, circled Jupiter among its moons
## from 1995 and swept by in 2021), for SpaceShape's planet GANYMEDE: every rule is a function of the seed and (x, z). What
## the rules look up (the plain's middle, the dark terrain's line, the furrows' middle, the ray crater and its rays, the
## poles' lines, the built parts) is made in _init and place_parts, before any generator thread starts, and only read
## afterwards, so the generator's threads share it without a lock. North is -z, east +x, as on MY MAP. Every column is a
## plain column of ground (no overhangs, no caves, no liquid). column() packs a column's height and kind (height * 16 +
## kind).
## - The smooth plain (SMOOTH): bright ice round the world's middle, gentle swells; the landing pad is here.
## - The bright grooved terrain (RIDGE, GROOVE): everywhere else on the bright side, in lanes (sulci) LANE_CELL across,
##   each with long parallel ridges and grooves running its own way (a period of a few blocks, up to ~2.5 high), flat
##   seams where lanes meet (it formed as the icy crust stretched and cracked).
## - The old dark terrain (DARK, FURROW, OLD_CRATER): west of a wandering line, DARK_RISE higher, dark ice mixed with
##   dust, crossed by long curved furrows (arcs round one far-off middle: the scars of an old giant impact) and pocked with
##   old, softened craters (about 4 billion years old).
## - A young bright ray crater (CRATER, PIT, RAY): a walk east, a bowl of fresh ice with a pit in its middle (many of
##   Ganymede's big craters have one) and a low rim; long rays of fresh ice thrown out across the ground, narrowing and
##   breaking up far out (laid on the ground: they never change its height).
## - Frost at the poles (FROST): north of one wandering line and south of another, white frost with a violet tint over
##   whatever ground is there (the magnetic field steers Jupiter's particles onto the poles, brightening the ice).
## - Built parts (place_parts, written by the generator with the colonies' flag): the Jupiter Lookout by the pad, the
##   Aurora Watch on the northern frost straight north of it, the ocean drill a walk south-west; the ground round the
##   watch and the drill is calm (no grooves) so they stand level.
## Every step between two columns is at most MAX_STEP (a jump at 0.146 gravity climbs ~11); the plain steps a block at
## most.

const SMOOTH := 0       # the smooth plain of bright ice round the pad
const RIDGE := 1        # a groove lane's ridges
const GROOVE := 2       # its grooves' floors
const DARK := 3         # the old dark terrain
const FURROW := 4       # its long curved furrows
const OLD_CRATER := 5   # its old, softened craters
const RAY := 6          # a young crater's bright rays across the ground
const CRATER := 7       # the ray crater's bowl and rim
const PIT := 8          # the pit in its middle
const FROST := 9        # frost at the poles

const NONE := Vector2i(0x7fffffff, 0x7fffffff)
const MAX_STEP := 2
const BASE := 50.0              # the bright ground ...
const SWELL := 2.0              # ... and its swells
const SUB_DEPTH := 3            # a column's own layers under its top (then the crust's water ice)
const NOISE_MARGIN := 1.05      # FastNoiseLite's values stay within ±1: noise this far from mattering is skipped
# The smooth plain round the world's middle
const PLAIN_R := 64.0
const PLAIN_WOBBLE := 7.0
const PLAIN_BLEND := 18.0       # the grooves grow out of it over this
# The grooved terrain
const LANE_CELL := 84           # a lane's cell
const LANE_MARGIN := 10
const PERIOD := Vector2i(7, 11) # a lane's grooves repeat every this many blocks ...
const SLOPE := 0.82             # ... and are at most this steep (height × π ÷ period)
const RIDGE_H := 2.5            # ... and at most this high
const SEAM := Vector2(3.0, 18.0)   # lanes meet in flat seams: their grooves fade over this much edge-ness
# The dark terrain (west)
const DARK_X := Vector2i(95, 125)   # its line: this far west of the world's middle ...
const DARK_WANDER := 14.0       # ... wandering this much
const DARK_RISE := 3.0          # it stands this much higher ...
const DARK_BLEND := 14.0        # ... rising over this
const FURROW_FAR := Vector2i(520, 640)   # the furrows' middle: this far west of the dark line
const FURROW_SPACING := 30.0    # a furrow every this many blocks out from it ...
const FURROW_DEPTH := 2.0       # ... this deep ...
const FURROW_W := Vector2(1.0, 4.0)   # ... its walls from this far from its line to this
const OLD_CELL := 44            # old craters: at most one per cell ...
const OLD_CHANCE := 75          # ... in this many cells of 100
const OLD_R := Vector2i(4, 10)
const OLD_DEPTH := 0.3          # × its radius
const OLD_RIM := 0.5
const OLD_OUT := 1.3            # its low rim runs out to this × its radius
# The bright ray crater (east)
const CRATER_DIST := Vector2i(120, 150)
const CRATER_ANGLE := Vector2i(-20, 20)   # degrees from east toward south
const CRATER_R := Vector2i(13, 16)
const CRATER_DEPTH := 0.38      # × its radius
const CRATER_RIM := 2.0
const CRATER_OUT := 1.5         # its rim runs out to this × its radius
const PIT_R := 0.26             # × its radius: the pit in its middle ...
const PIT_DEPTH := 2.0          # ... this deep
const CALM_OUT := 1.9           # no grooves this near it (× its radius)
const RAYS := Vector2i(10, 13)
const RAY_LEN := Vector2i(60, 100)   # from its rim
const RAY_W := 2.6              # half a ray's width at the rim ...
const RAY_TAPER := 0.7          # ... narrowing by this share far out
const RAY_FADE := 0.6           # it breaks up into specks past this share of its length
# Frost at the poles
const NORTH := Vector2i(200, 240)   # the north frost's line: this far north of the world's middle ...
const SOUTH := Vector2i(250, 290)   # ... the south frost's this far south ...
const POLE_WANDER := 16.0       # ... wandering this much
const POLE_PATCH := 8.0         # its edge is patchy over this
# Built parts
const LOOKOUT_AT := Vector2i(12, -3)   # the Jupiter Lookout: this far from the pad's middle (east, towards Jupiter)
const LOOKOUT_R := 2            # its round floor
const WATCH_IN := 16            # the Aurora Watch: this far inside the north frost's line ...
const WATCH_X := 12             # ... this far east of the pad's middle
const WATCH_R := 2
const DRILL_DIST := Vector2i(80, 100)   # the ocean drill: this far from the pad's middle ...
const DRILL_ANGLE := Vector2i(110, 130)   # ... this many degrees from east toward south (south-west)
const DRILL_R := 3              # its floor (7 × 7) ...
const SHAFT_DEPTH := 8          # ... round a shaft 3 × 3 this deep (a Ganymede jump climbs ~11)
const PART_CALM := Vector2(9.0, 18.0)   # the ground is calm (no grooves) this near a part, blending out to this
const PART_REACH := 3           # standing this close to a part's middle (either way) is its sight

var _seed := 0
var _plain_r := 0.0
var _dark_x := 0.0
var _furrow := Vector2.ZERO
var _crater := Vector2i.ZERO
var _crater_r := 0.0
var _rays: Array[PackedFloat32Array] = []   # [cos, sin, length, phase]
var _north := 0.0
var _south := 0.0
var _swell := FastNoiseLite.new()
var _wobble := FastNoiseLite.new()
var _dark := FastNoiseLite.new()
var _poles := FastNoiseLite.new()
var _patch := FastNoiseLite.new()
## The built parts (place_parts): their middles and the top of their floors.
var lookout := NONE
var lookout_y := 0
var watch := NONE
var watch_y := 0
var drill := NONE
var drill_y := 0
var _calm_spots: Array[Vector2i] = []   # the watch's and the drill's middles: no grooves near them
var _parts: Array = []   # [lo (Vector3i), hi (Vector3i, exclusive), boxes [[lo, hi, id]]]


func _init(world_seed: int) -> void:
	_seed = world_seed
	var h := absi(_mix(world_seed + 28))
	_plain_r = PLAIN_R
	_dark_x = -float(DARK_X.x + h % (DARK_X.y - DARK_X.x + 1))
	_north = -float(NORTH.x + (h >> 5) % (NORTH.y - NORTH.x + 1))
	_south = float(SOUTH.x + (h >> 11) % (SOUTH.y - SOUTH.x + 1))
	var h2 := absi(_mix(world_seed * 5 + 2801))
	var ff := float(FURROW_FAR.x + h2 % (FURROW_FAR.y - FURROW_FAR.x + 1))
	_furrow = Vector2(_dark_x - ff, float((h2 >> 9) % 301 - 150))
	var ca := deg_to_rad(float(CRATER_ANGLE.x + (h2 >> 17) % (CRATER_ANGLE.y - CRATER_ANGLE.x + 1)))
	var cd := float(CRATER_DIST.x + (h2 >> 23) % (CRATER_DIST.y - CRATER_DIST.x + 1))
	_crater = Vector2i(roundi(cos(ca) * cd), roundi(sin(ca) * cd))
	var h3 := absi(_mix(world_seed * 7 - 2803))
	_crater_r = float(CRATER_R.x + h3 % (CRATER_R.y - CRATER_R.x + 1))
	var n := RAYS.x + (h3 >> 4) % (RAYS.y - RAYS.x + 1)
	for i in n:   # spread round it, each nudged a little
		var hr := absi(_mix(h3 + i * 977))
		var a := TAU * (float(i) + 0.35 * float(hr % 100) / 100.0) / n
		var length := float(RAY_LEN.x + (hr >> 8) % (RAY_LEN.y - RAY_LEN.x + 1))
		_rays.append(PackedFloat32Array([cos(a), sin(a), length, float((hr >> 16) % 628) / 100.0]))
	_swell.seed = world_seed + 280
	_swell.frequency = 0.005
	_swell.fractal_octaves = 2
	_wobble.seed = world_seed + 281
	_wobble.frequency = 0.6
	_wobble.fractal_octaves = 1
	_dark.seed = world_seed + 282
	_dark.frequency = 0.008
	_dark.fractal_octaves = 2
	_poles.seed = world_seed + 283
	_poles.frequency = 0.006
	_poles.fractal_octaves = 2
	_patch.seed = world_seed + 284
	_patch.frequency = 0.06
	_patch.fractal_octaves = 1


# --- The plain and the grooves -----------------------------------------------------------------------------------------

## The ground's own height at (fx, fz) before any region (gentle swells).
func swell_height(fx: float, fz: float) -> float:
	return BASE + SWELL * _swell.get_noise_2d(fx, fz)


## The smooth plain's edge in the direction of (dx, dz) from the world's middle.
func plain_radius(dx: float, dz: float) -> float:
	var a := atan2(dz, dx)
	return _plain_r + PLAIN_WOBBLE * _wobble.get_noise_2d(cos(a) * 3.0, sin(a) * 3.0)


## The middle of lane cell (cx, cz), somewhere inside it.
func _lane_site(cx: int, cz: int) -> Vector2:
	var h := absi(_mix(_mix(cx * 41 + 11 + _seed * 7) + cz * 59 - 13))
	var span := LANE_CELL - 2 * LANE_MARGIN
	return Vector2(cx * LANE_CELL + LANE_MARGIN + h % span, cz * LANE_CELL + LANE_MARGIN + (h >> 10) % span)


## Lane cell c's grooves: [along (unit Vector2), period, height, phase].
func _lane(c: Vector2i) -> Array:
	var h := absi(_mix(_mix(c.x * 67 - 5 + _seed * 11) + c.y * 73 + 3))
	var a := float(h % 180) / 180.0 * PI
	var period := float(PERIOD.x + (h >> 8) % (PERIOD.y - PERIOD.x + 1))
	var height := minf(RIDGE_H, SLOPE * period / PI)
	return [Vector2(cos(a), sin(a)), period, height, float((h >> 12) % 100) / 100.0]


## The lane at (x, z): {cell, along (the grooves' way), strength (0 on a seam, 1 well inside a lane)}.
func lane_at(x: int, z: int) -> Dictionary:
	var fx := float(x)
	var fz := float(z)
	var near := _nearest_lanes(fx, fz)
	var cell: Vector2i = near[0]
	var lane := _lane(cell)
	return {"cell": cell, "along": lane[0], "strength": smoothstep(SEAM.x, SEAM.y, float(near[1]))}


## [the nearest lane cell, its edge-ness (the second-nearest lane middle's distance less the nearest's)].
func _nearest_lanes(fx: float, fz: float) -> Array:
	var c := Vector2i(floori(fx / LANE_CELL), floori(fz / LANE_CELL))
	var p := Vector2(fx, fz)
	var d1 := INF
	var d2 := INF
	var best := c
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var d := p.distance_to(_lane_site(c.x + dx, c.y + dz))
			if d < d1:
				d2 = d1
				d1 = d
				best = Vector2i(c.x + dx, c.y + dz)
			elif d < d2:
				d2 = d
	return [best, d2 - d1]


## [the grooves' height over the swells at (fx, fz) (0 .. a lane's height, before the plain's and the calm spots'
## fading), how far it is up its ridge (0 in a groove, 1 on a crest)].
func _grooves(fx: float, fz: float) -> PackedFloat32Array:
	var near := _nearest_lanes(fx, fz)
	var lane := _lane(near[0])
	var strength := smoothstep(SEAM.x, SEAM.y, float(near[1]))
	if strength <= 0.0:
		return PackedFloat32Array([0.0, 0.0])
	var along: Vector2 = lane[0]
	var across := -along.y * fx + along.x * fz
	var wave := 0.5 - 0.5 * cos(TAU * (across / float(lane[1]) + float(lane[3])))
	return PackedFloat32Array([float(lane[2]) * wave * strength, wave])


# --- The dark terrain --------------------------------------------------------------------------------------------------

## The dark terrain's line at z: every column west of it (less x) is the old dark terrain's.
func dark_edge(fz: float) -> float:
	return _dark_x + DARK_WANDER * _dark.get_noise_2d(500.0, fz)


## The furrows' far-off middle (west of the dark line).
func furrow_centre() -> Vector2i:
	return Vector2i(roundi(_furrow.x), roundi(_furrow.y))


## The k-th furrow's radius round its middle.
func furrow_radius(k: int) -> float:
	return (float(k) + 0.5) * FURROW_SPACING


## A point on a furrow near `from` (the nearest arc's crossing of the line from the furrows' middle to `from`, pushed
## into the dark terrain).
func furrow_point_near(from: Vector2i) -> Vector2i:
	var to := Vector2(from) - _furrow
	var r := to.length()
	var k := maxi(0, floori(r / FURROW_SPACING))
	var dir := to.normalized()
	for i in 40:   # the first arc inside the dark terrain
		var p := _furrow + dir * furrow_radius(maxi(0, k - i))
		if p.x < dark_edge(p.y) - DARK_BLEND - 6.0:
			return Vector2i(roundi(p.x), roundi(p.y))
	return NONE


## How deep (x, z)'s furrow is under the dark ground (0 off every furrow) and how far it is from the furrow's line.
func _furrow_dip(fx: float, fz: float) -> Vector2:
	var r := Vector2(fx, fz).distance_to(_furrow)
	var s := absf(fposmod(r, FURROW_SPACING) - FURROW_SPACING * 0.5)
	return Vector2(FURROW_DEPTH * (1.0 - smoothstep(FURROW_W.x, FURROW_W.y, s)), s)


## The old crater of cell (cx, cz): [middle x, middle z, radius] or [] (none).
func _old_crater(cx: int, cz: int) -> Array:
	var h := absi(_mix(_mix(cx * 23 + 7 + _seed * 3) + cz * 29 - 1))
	if h % 100 >= OLD_CHANCE:
		return []
	var r := float(OLD_R.x + (h >> 7) % (OLD_R.y - OLD_R.x + 1))
	var m := ceili(r * OLD_OUT) + 1
	var span := OLD_CELL - 2 * m
	return [cx * OLD_CELL + m + (h >> 11) % span, cz * OLD_CELL + m + (h >> 19) % span, r]


## The old craters' dip at (x, z) (negative in a bowl, a little positive on a rim) and whether (x, z) is in a bowl.
func _old_craters(x: int, z: int) -> Vector2:
	var cx := floori(float(x) / OLD_CELL)
	var cz := floori(float(z) / OLD_CELL)
	var e: Array = _old_crater(cx, cz)   # a crater stays inside its cell (rim and all)
	if e.is_empty():
		return Vector2.ZERO
	var r: float = e[2]
	var d2 := (float(x - int(e[0])) * float(x - int(e[0])) + float(z - int(e[1])) * float(z - int(e[1]))) / (r * r)
	if d2 >= OLD_OUT * OLD_OUT:
		return Vector2.ZERO
	if d2 < 1.0:
		return Vector2(OLD_RIM * d2 - r * OLD_DEPTH * (1.0 - d2), 1.0 if d2 < 0.72 else 0.0)
	return Vector2(OLD_RIM * (OLD_OUT - sqrt(d2)) / (OLD_OUT - 1.0), 0.0)


## The first dark column straight west of `from` (within 400 blocks), or NONE.
func first_dark_west_of(from: Vector2i) -> Vector2i:
	for d in range(0, 400):
		var k := column(from.x - d, from.y) & 15
		if k == DARK:
			return Vector2i(from.x - d, from.y)
	return NONE


# --- The bright ray crater ---------------------------------------------------------------------------------------------

func crater_centre() -> Vector2i:
	return _crater


func crater_radius() -> int:
	return int(_crater_r)


## (x, z) is in the ray crater's pit (column()'s PIT: nothing else lies over it).
func in_pit(x: int, z: int) -> bool:
	var dx := float(x - _crater.x)
	var dz := float(z - _crater.y)
	return sqrt(dx * dx + dz * dz) / _crater_r < PIT_R * 0.8


## (x, z) is on one of the crater's rays (outside its rim).
func _on_ray(x: int, z: int) -> bool:
	var dx := float(x - _crater.x)
	var dz := float(z - _crater.y)
	var d := sqrt(dx * dx + dz * dz)
	var from := _crater_r * 1.0
	if d < from or d > from + float(RAY_LEN.y) + RAY_W:
		return false
	for r: PackedFloat32Array in _rays:
		var along := dx * r[0] + dz * r[1] - from
		if along < 0.0 or along > r[2]:
			continue
		var across := absf(-dx * r[1] + dz * r[0] + 1.2 * sin(along * 0.08 + r[3]))
		if across >= RAY_W * (1.0 - RAY_TAPER * along / r[2]) + 0.4:
			continue
		if along > RAY_FADE * r[2]:   # it breaks up into specks far out
			var gap := (along / r[2] - RAY_FADE) / (1.0 - RAY_FADE) * 85.0
			if absi(_mix(x * 31 + z * 17 + _seed)) % 100 < int(gap):
				continue
		return true
	return false


# --- Frost at the poles ------------------------------------------------------------------------------------------------

## The north frost's line at x: north of it (less z) is frost.
func north_edge(fx: float) -> float:
	return _north + POLE_WANDER * _poles.get_noise_2d(fx, 900.0)


## The south frost's line at x: south of it (more z) is frost.
func south_edge(fx: float) -> float:
	return _south + POLE_WANDER * _poles.get_noise_2d(fx, -900.0)


## (x, z) wears the poles' frost (its edge patchy over POLE_PATCH).
func _frosty(fx: float, fz: float) -> bool:
	var lim := POLE_WANDER * NOISE_MARGIN
	var into := 0.0
	if fz < _north + lim:
		into = north_edge(fx) - fz
	elif fz > _south - lim:
		into = fz - south_edge(fx)
	else:
		return false
	if into <= 0.0:
		return false
	if into >= POLE_PATCH:
		return true
	return into > POLE_PATCH * (0.5 + 0.5 * _patch.get_noise_2d(fx, fz))


## The first frost column straight north of `from` (within 400 blocks), or NONE.
func frost_point_north_of(from: Vector2i) -> Vector2i:
	for d in range(0, 400):
		if column(from.x, from.y - d) & 15 == FROST and not on_part(from.x, from.y - d, PART_REACH):
			return Vector2i(from.x, from.y - d - 2)   # a step past the patchy edge
	return NONE


# --- A column ----------------------------------------------------------------------------------------------------------

## Height * 16 + kind of the column at (x, z) (the landing pad's flattening is SpaceShape's). Noise nothing can need is
## skipped (the plain's edge far from it, the dark line far from it, the poles' lines far from them), so every column
## gets the same answer, cheaper.
func column(x: int, z: int) -> int:
	return _column(x, z, true)


## The ground's height at (x, z) as if no ray lay on it (the rays never change it: tests).
func ground_without_rays(x: int, z: int) -> int:
	return _column(x, z, false) >> 4


func _column(x: int, z: int, rays: bool) -> int:
	var fx := float(x)
	var fz := float(z)
	var base := swell_height(fx, fz)
	# how much of the grooves show: none on the plain, none near the crater and the calm spots
	var groove_k := 1.0
	var d0 := sqrt(fx * fx + fz * fz)
	if d0 < _plain_r + PLAIN_WOBBLE * NOISE_MARGIN + PLAIN_BLEND:
		var pr := plain_radius(fx, fz) if d0 > _plain_r - PLAIN_WOBBLE * NOISE_MARGIN else _plain_r
		groove_k = smoothstep(pr, pr + PLAIN_BLEND, d0)
	var cdx := fx - _crater.x
	var cdz := fz - _crater.y
	var cd := sqrt(cdx * cdx + cdz * cdz) / _crater_r
	if cd < CALM_OUT + 0.6:
		groove_k = minf(groove_k, smoothstep(CALM_OUT - 0.3, CALM_OUT + 0.6, cd))
	for c: Vector2i in _calm_spots:
		var pd := Vector2(fx - c.x, fz - c.y).length()
		if pd < PART_CALM.y:
			groove_k = minf(groove_k, smoothstep(PART_CALM.x, PART_CALM.y, pd))
	var bright := base
	var kind := SMOOTH
	if groove_k > 0.0:
		var gr := _grooves(fx, fz)
		bright = base + gr[0] * groove_k
		if groove_k >= 0.5 and gr[0] > 0.05:
			kind = RIDGE if gr[1] > 0.45 else GROOVE
		elif groove_k >= 0.5:
			kind = RIDGE
	var h := bright
	# the old dark terrain (west of its line)
	if fx < _dark_x + DARK_WANDER * NOISE_MARGIN:
		var m := dark_edge(fz) - fx   # how far west of its line
		if m > 0.0:
			var t := smoothstep(0.0, DARK_BLEND, m)
			var fur := _furrow_dip(fx, fz)
			var old := _old_craters(x, z)
			var dark := base + DARK_RISE - fur.x * t + old.x * t
			h = lerpf(bright, dark, t)
			if t >= 0.5:
				kind = DARK
				if fur.x > FURROW_DEPTH * 0.45:
					kind = FURROW
				if old.y > 0.0:
					kind = OLD_CRATER
	# the ray crater (its bowl, its pit, its rim)
	if cd < CRATER_OUT:
		if cd < 1.0:
			var d2 := cd * cd
			h = base + CRATER_RIM * d2 - _crater_r * CRATER_DEPTH * (1.0 - d2)
			kind = CRATER
			if cd < PIT_R:
				var pd2 := (cd / PIT_R) * (cd / PIT_R)
				h -= PIT_DEPTH * (1.0 - pd2)
				if cd < PIT_R * 0.8:
					kind = PIT
		else:
			h = lerpf(base + CRATER_RIM, h, smoothstep(1.0, CRATER_OUT, cd))
			if cd < 1.2:
				kind = CRATER
	if rays and kind != CRATER and kind != PIT and _on_ray(x, z):
		kind = RAY
	# frost at the poles, over whatever ground is there
	if (fz < _north + POLE_WANDER * NOISE_MARGIN or fz > _south - POLE_WANDER * NOISE_MARGIN) and _frosty(fx, fz):
		kind = FROST
	return _pack(h, kind)


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


## The first grooved column straight south of `from` (within 400 blocks) well inside a lane, or NONE.
func first_groove_toward(from: Vector2i) -> Vector2i:
	for d in range(0, 400):
		var p := from + Vector2i(0, d)
		var k := column(p.x, p.y) & 15
		if is_grooved(k) and float(lane_at(p.x, p.y).strength) > 0.9 and not on_part(p.x, p.y, PART_REACH):
			return p
	return NONE


# --- A column's blocks -------------------------------------------------------------------------------------------------

## The block at y (0 <= y < g) of a column of `kind` whose ground is g (the landing pad is SpaceShape's).
static func block(y: int, g: int, kind: int) -> int:
	if y == g - 1:
		return top_block(kind)
	if y >= g - 1 - SUB_DEPTH:
		return sub_block(kind, y, g)
	return BlockIds.WATER_ICE


## The layer at y under a column's top block (above the crust's water ice).
static func sub_block(kind: int, y: int, g: int) -> int:
	match kind:
		DARK, FURROW, OLD_CRATER:
			return BlockIds.OLD_ICE
		CRATER, PIT:   # fresh ice the crash brought up
			return BlockIds.RAY_ICE if y >= g - 3 else BlockIds.GROOVED_ICE
	return BlockIds.GROOVED_ICE


## The top block of a column of `kind`.
static func top_block(kind: int) -> int:
	match kind:
		GROOVE:
			return BlockIds.TROUGH_ICE
		DARK:
			return BlockIds.DARK_ICE
		FURROW, OLD_CRATER:
			return BlockIds.OLD_ICE
		RAY, CRATER, PIT:
			return BlockIds.RAY_ICE
		FROST:
			return BlockIds.POLAR_FROST
	return BlockIds.GROOVED_ICE


## The smooth plain (where the landing pad and the aliens' camp may be).
static func is_plains(kind: int) -> bool:
	return kind == SMOOTH


## The bright grooved terrain (its ridges and grooves).
static func is_grooved(kind: int) -> bool:
	return kind == RIDGE or kind == GROOVE


## The old dark terrain (its dark ice, furrows and old craters).
static func is_dark(kind: int) -> bool:
	return kind == DARK or kind == FURROW or kind == OLD_CRATER


## The crater near the pad's place, the dark terrain, the frost: the pad keeps away (on the smooth plain).
func calm(x: int, z: int) -> bool:
	var fx := float(x)
	var fz := float(z)
	if fx - dark_edge(fz) < 60.0 or north_edge(fx) > fz - 150.0 or south_edge(fx) < fz + 150.0:
		return false
	return Vector2(fx - _crater.x, fz - _crater.y).length() > _crater_r * CALM_OUT + 40.0


## (fx, fz) is on or near the crater or a built part (special ground a secret keeps off).
func steep_near(fx: float, fz: float, margin: float) -> bool:
	if Vector2(fx - _crater.x, fz - _crater.y).length() < _crater_r * CRATER_OUT + margin:
		return true
	for p: Array in _parts:
		var lo: Vector3i = p[0]
		var hi: Vector3i = p[1]
		if fx > lo.x - margin and fx < hi.x + margin and fz > lo.z - margin and fz < hi.z + margin:
			return true
	return false


# --- Sights ------------------------------------------------------------------------------------------------------------

## The built part's sight at (x, z) (standing by it): &"lookout", &"aurora" (the Aurora Watch), &"ocean" (the ocean
## drill), or &"".
func part_sight(x: int, z: int) -> StringName:
	if _by(lookout, x, z):
		return &"lookout"
	if _by(watch, x, z):
		return &"aurora"
	if _by(drill, x, z):
		return &"ocean"
	return &""


func _by(c: Vector2i, x: int, z: int) -> bool:
	return c != NONE and absi(x - c.x) <= PART_REACH and absi(z - c.y) <= PART_REACH


## The sight at a column of packed `c` (column()): &"grooves", &"dark", &"crater" (its bowl, pit and rays), &"frost",
## or &"".
func sight(_x: int, _z: int, c: int) -> StringName:
	match c & 15:
		RIDGE, GROOVE:
			return &"grooves"
		DARK, FURROW, OLD_CRATER:
			return &"dark"
		RAY, CRATER, PIT:
			return &"crater"
		FROST:
			return &"frost"
	return &""


## The sights MY MAP shows from the landing, [id, column] each: the lookout, the first grooves south of the pad, the dark
## terrain west of it, the crater, the frost north of it, the Aurora Watch, the ocean drill.
func sight_spots(from: Vector2i) -> Array:
	return [[&"lookout", lookout], [&"grooves", first_groove_toward(from)], [&"dark", first_dark_west_of(from)],
		[&"crater", _crater], [&"frost", frost_point_north_of(from)], [&"aurora", watch], [&"ocean", drill]]


# --- The built parts ---------------------------------------------------------------------------------------------------

## Builds the parts round the landing pad at `spawn` on grounds `ground` (a Callable (x, z) -> int, the pad's blend
## included): the Jupiter Lookout by the pad, the Aurora Watch on the northern frost straight north, the ocean drill a
## walk south-west. The watch's and the drill's ground is calm first (no grooves near them). Called once, before any
## generator thread starts.
func place_parts(spawn: Vector2i, ground: Callable) -> void:
	_parts.clear()
	var hd := absi(_mix(_seed * 13 + 2807))
	var da := deg_to_rad(float(DRILL_ANGLE.x + hd % (DRILL_ANGLE.y - DRILL_ANGLE.x + 1)))
	var dd := float(DRILL_DIST.x + (hd >> 8) % (DRILL_DIST.y - DRILL_DIST.x + 1))
	drill = spawn + Vector2i(roundi(cos(da) * dd), roundi(sin(da) * dd))
	watch = Vector2i(spawn.x + WATCH_X, floori(north_edge(float(spawn.x + WATCH_X))) - WATCH_IN)
	_calm_spots = [watch, drill]
	lookout = spawn + LOOKOUT_AT
	_place_lookout(ground)
	_place_watch(ground)
	_place_drill(ground)


## [lowest, highest] ground over a round floor of radius r round c.
func _floor_span(c: Vector2i, r: int, ground: Callable) -> Vector2i:
	var top := -0x7fffffff
	var low := 0x7fffffff
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dz * dz > r * r + 1:
				continue
			var g := int(ground.call(c.x + dx, c.y + dz))
			top = maxi(top, g)
			low = mini(low, g)
	return Vector2i(low, top)


## A round floor of groove bricks (a plinth where the ground dips) at c, its top at `top`.
func _round_floor(boxes: Array, c: Vector2i, r: int, low: int, top: int) -> void:
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dz * dz <= r * r + 1:
				_add(boxes, Vector3i(c.x + dx, low - 1, c.y + dz), Vector3i(c.x + dx + 1, top, c.y + dz + 1),
					BlockIds.GROOVE_BRICK)


## The Jupiter Lookout: a round floor, a telescope on a stand looking east and up at Jupiter, a globe of Jupiter on a
## post, an aurora lamp.
func _place_lookout(ground: Callable) -> void:
	var c := lookout
	var span := _floor_span(c, LOOKOUT_R, ground)
	lookout_y = span.y
	var y := span.y
	var boxes: Array = []
	_round_floor(boxes, c, LOOKOUT_R, span.x, y)
	_add(boxes, Vector3i(c.x, y, c.y), Vector3i(c.x + 1, y + 2, c.y + 1), BlockIds.TRUSS)                  # the stand ...
	_add(boxes, Vector3i(c.x, y + 2, c.y), Vector3i(c.x + 1, y + 3, c.y + 1), BlockIds.TELESCOPE)           # ... the tube ...
	_add(boxes, Vector3i(c.x + 1, y + 3, c.y), Vector3i(c.x + 2, y + 4, c.y + 1), BlockIds.TELESCOPE)       # ... up at Jupiter
	_add(boxes, Vector3i(c.x - 1, y, c.y + 1), Vector3i(c.x, y + 1, c.y + 2), BlockIds.TRUSS)              # a post ...
	_add(boxes, Vector3i(c.x - 1, y + 1, c.y + 1), Vector3i(c.x, y + 2, c.y + 2), BlockIds.JUPITER_GLOBE)   # ... Jupiter
	_add(boxes, Vector3i(c.x + 1, y, c.y + 1), Vector3i(c.x + 2, y + 1, c.y + 2), BlockIds.AURORA_LAMP)     # a lamp
	_parts.append([Vector3i(c.x - LOOKOUT_R, span.x - 1, c.y - LOOKOUT_R),
		Vector3i(c.x + LOOKOUT_R + 1, y + 4, c.y + LOOKOUT_R + 1), boxes])


## The Aurora Watch: a round floor on the frost, a mast with an aurora lamp on top, a long boom out east with the
## magnetometer at its tip, aurora crystals round its foot.
func _place_watch(ground: Callable) -> void:
	var c := watch
	var span := _floor_span(c, WATCH_R, ground)
	watch_y = span.y
	var y := span.y
	var boxes: Array = []
	_round_floor(boxes, c, WATCH_R, span.x, y)
	_add(boxes, Vector3i(c.x, y, c.y), Vector3i(c.x + 1, y + 6, c.y + 1), BlockIds.TRUSS)                  # the mast
	_add(boxes, Vector3i(c.x, y + 6, c.y), Vector3i(c.x + 1, y + 7, c.y + 1), BlockIds.AURORA_LAMP)         # its lamp
	_add(boxes, Vector3i(c.x + 1, y + 5, c.y), Vector3i(c.x + 5, y + 6, c.y + 1), BlockIds.TRUSS)           # the boom ...
	_add(boxes, Vector3i(c.x + 5, y + 5, c.y), Vector3i(c.x + 6, y + 6, c.y + 1), BlockIds.MAGNETOMETER)    # ... its sensor
	_add(boxes, Vector3i(c.x - 2, y, c.y), Vector3i(c.x - 1, y + 1, c.y + 1), BlockIds.AURORA_CRYSTAL)      # crystals
	_add(boxes, Vector3i(c.x, y, c.y - 2), Vector3i(c.x + 1, y + 1, c.y - 1), BlockIds.AURORA_CRYSTAL)
	_parts.append([Vector3i(c.x - WATCH_R, span.x - 1, c.y - WATCH_R), Vector3i(c.x + 6, y + 7, c.y + WATCH_R + 1), boxes])


## The ocean drill: a 7 × 7 floor of bricks round a 3 × 3 shaft SHAFT_DEPTH deep, lined with deep blue ice, the drill's
## light (glow ice) at its bottom; a tower of trusses on four legs over it, a frame on top with the drill's motor in its
## middle (nothing hangs in the shaft: a child jumps straight out), lamps on two legs.
func _place_drill(ground: Callable) -> void:
	var c := drill
	var span := _floor_span(c, DRILL_R + 1, ground)
	drill_y = span.y
	var y := span.y
	var r := DRILL_R
	var boxes: Array = []
	_add(boxes, Vector3i(c.x - r, span.x - 1, c.y - r), Vector3i(c.x + r + 1, y, c.y + r + 1), BlockIds.GROOVE_BRICK)
	_add(boxes, Vector3i(c.x - r, y, c.y - r), Vector3i(c.x + r + 1, y + 8, c.y + r + 1), BlockIds.AIR)   # room round it
	_add(boxes, Vector3i(c.x - 2, y - SHAFT_DEPTH - 2, c.y - 2), Vector3i(c.x + 3, y - 1, c.y + 3), BlockIds.DEEP_ICE)
	_add(boxes, Vector3i(c.x - 1, y - SHAFT_DEPTH - 1, c.y - 1), Vector3i(c.x + 2, y - SHAFT_DEPTH, c.y + 2), BlockIds.GLOW_ICE)
	_add(boxes, Vector3i(c.x - 1, y - SHAFT_DEPTH, c.y - 1), Vector3i(c.x + 2, y, c.y + 2), BlockIds.AIR)   # the shaft
	for d: Vector2i in [Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(2, 2)]:   # four legs
		_add(boxes, Vector3i(c.x + d.x, y, c.y + d.y), Vector3i(c.x + d.x + 1, y + 6, c.y + d.y + 1), BlockIds.TRUSS)
	_add(boxes, Vector3i(c.x - 2, y + 6, c.y - 2), Vector3i(c.x + 3, y + 7, c.y - 1), BlockIds.TRUSS)   # the frame on top
	_add(boxes, Vector3i(c.x - 2, y + 6, c.y + 2), Vector3i(c.x + 3, y + 7, c.y + 3), BlockIds.TRUSS)
	_add(boxes, Vector3i(c.x - 2, y + 6, c.y - 1), Vector3i(c.x - 1, y + 7, c.y + 2), BlockIds.TRUSS)
	_add(boxes, Vector3i(c.x + 2, y + 6, c.y - 1), Vector3i(c.x + 3, y + 7, c.y + 2), BlockIds.TRUSS)
	_add(boxes, Vector3i(c.x - 1, y + 6, c.y), Vector3i(c.x + 2, y + 7, c.y + 1), BlockIds.TRUSS)       # a cross bar ...
	_add(boxes, Vector3i(c.x, y + 6, c.y), Vector3i(c.x + 1, y + 7, c.y + 1), BlockIds.POWER_PACK)    # ... the drill's motor
	_add(boxes, Vector3i(c.x - 2, y + 7, c.y - 2), Vector3i(c.x - 1, y + 8, c.y - 1), BlockIds.STATION_LAMP)
	_add(boxes, Vector3i(c.x + 2, y + 7, c.y + 2), Vector3i(c.x + 3, y + 8, c.y + 3), BlockIds.STATION_LAMP)
	_parts.append([Vector3i(c.x - r, mini(span.x - 1, y - SHAFT_DEPTH - 2), c.y - r),
		Vector3i(c.x + r + 1, y + 8, c.y + r + 1), boxes])


func _add(boxes: Array, lo: Vector3i, hi: Vector3i, id: int) -> void:
	boxes.append([lo, hi, id])


## A built part's block at p, or -1 (the later box wins).
func built_at(p: Vector3i) -> int:
	for part: Array in _parts:
		var plo: Vector3i = part[0]
		var phi: Vector3i = part[1]
		if p.x < plo.x or p.y < plo.y or p.z < plo.z or p.x >= phi.x or p.y >= phi.y or p.z >= phi.z:
			continue
		var boxes: Array = part[2]
		for i in range(boxes.size() - 1, -1, -1):
			var b: Array = boxes[i]
			var lo: Vector3i = b[0]
			var hi: Vector3i = b[1]
			if p.x >= lo.x and p.y >= lo.y and p.z >= lo.z and p.x < hi.x and p.y < hi.y and p.z < hi.z:
				return int(b[2])
	return -1


## The column (x, z) is under a built part (within `margin`).
func on_part(x: int, z: int, margin: int = 0) -> bool:
	for part: Array in _parts:
		var lo: Vector3i = part[0]
		var hi: Vector3i = part[1]
		if x >= lo.x - margin and x < hi.x + margin and z >= lo.z - margin and z < hi.z + margin:
			return true
	return false


## Writes the built parts where they reach into this buffer.
func write(buf: VoxelBuffer, origin: Vector3i) -> void:
	var end := origin + buf.get_size()
	for part: Array in _parts:
		var plo: Vector3i = part[0]
		var phi: Vector3i = part[1]
		if phi.x <= origin.x or phi.y <= origin.y or phi.z <= origin.z or plo.x >= end.x or plo.y >= end.y \
				or plo.z >= end.z:
			continue
		for b: Array in part[2]:
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
