class_name TritonTerrain
extends RefCounted
## Triton's regions as pure rules (cosmos, spec §21b.2; Voyager 2 flew past it in 1989), for SpaceShape's planet TRITON:
## every rule is a function of the seed and (x, z). What the rules look up (the cap's line, the first geyser, the frozen
## lake, the crater, the cantaloupe terrain's line, the streaks' directions) is built in _init, before any generator
## thread starts, and only read afterwards, so the generator's threads share it without a lock. North is -z, east +x, as
## on MY MAP. Every column is a plain column of ground (no overhangs, no caves, no liquid). column() packs a column's
## height and kind (height * 16 + kind).
## - The bright band (FROST): fresh nitrogen frost over a crust of frozen nitrogen over an icy mantle (water ice), gentle
##   swells; the landing pad is here.
## - The south polar cap (Uhlanga Regio): south of a wandering line (cap_edge), pink nitrogen ice (sunlight turns its
##   methane pink), a little higher than the band, mottled with darker patches. Geysers: at most one per VENT_CELL cell,
##   deep in the cap (the first one south of the world's middle, FIRST_*): a dark vent (a pad: a gentle puff carries a
##   child up and the wind drifts it north-east, PadRules) in a ring of dark dust, flush with the ice; from each a dark
##   streak of dust runs downwind to the north-east (the real streaks: about 50, some over 150 km long, "southwesterly
##   winds ... deposits to the northeast of most vents"), narrowing and breaking up as it goes.
## - The cantaloupe terrain (Bubembe Regio): north-west of a wandering line, dimples (cells MELON_CELL across, each sunk in
##   its middle) with pale ridges between them, like a melon's rind.
## - A walled plain (like Ruach Planitia): a walk north-east, a frozen lake of ice lava: a flat floor sunk under the band,
##   terraced walls (a step a block, STEP_W wide) up to a flat rim, blending back into the band.
## - One of Triton's few craters: a walk east, a bowl dug through the frost into nitrogen ice, a low rim (its ground is
##   young: very few craters).
## Every step between two columns is at most MAX_STEP (a jump at 0.079 gravity climbs ~21); the band, the cap, the
## cantaloupe terrain and the lake's floor and walls step one block at most.

const FROST := 0        # the bright band's fresh nitrogen frost
const CAP := 1          # the polar cap's pink ice
const MOTTLE := 2       # its darker mottled patches
const STREAK := 3       # a geyser's dark streak on the cap
const SPOT := 4         # the ring of dark dust round a vent
const VENT := 5         # a geyser's vent
const DIMPLE := 6       # the cantaloupe terrain's dimples
const RIDGE := 7        # the ridges between them
const LAKE := 8         # the frozen lake's flat floor of ice lava
const TERRACE := 9      # its terraced walls
const CRATER := 10      # the crater's bowl

const NONE := Vector2i(0x7fffffff, 0x7fffffff)
const MAX_STEP := 2
const BASE := 50.0              # the band ...
const SWELL := 1.5              # ... and its swells
const FROST_DEPTH := 4          # a crust of frozen nitrogen under a column's top (then water ice)
const NOISE_MARGIN := 1.05      # FastNoiseLite's values stay within ±1: noise this far from mattering is skipped
const INV_SQRT2 := 0.70710678
# The polar cap
const CAP_Z := Vector2i(70, 95) # its edge: this far south of the world's middle ...
const CAP_WANDER := 12.0        # ... wandering this much
const CAP_RISE := 2.0           # the cap stands this much higher ...
const CAP_BLEND := 14.0         # ... rising over this
const MOTTLE_OVER := 0.38       # the mottle noise over this: a darker patch
# The geysers
const VENT_CELL := 96
const VENT_CHANCE := 70         # of 100 cells
const VENT_MARGIN := 14         # a vent stays this far inside its cell (its ring never crosses a cell's side)
const VENT_IN := 16             # and this far inside the cap (at least)
const FIRST_X := Vector2i(-20, 20)   # the first geyser: this far east of the world's middle ...
const FIRST_IN := Vector2i(22, 28)   # ... and this much deeper than VENT_IN would need
const FIRST_CLEAR := 100.0      # no other geyser this near it (its streak alone, no other's near it)
const HOLE_R := 1.3             # the vent's dark hole (a plus of five columns) ...
const SPOT_R := 3.2             # ... in its ring of dark dust
const STREAK_LEN := Vector2i(40, 72)
const FIRST_LEN := 44.0
const STREAK_W := Vector2(2.5, 3.8)   # half its width at the vent
const TAPER := 0.75             # it narrows to a quarter of that far downwind
const MEANDER := 1.2            # it wanders sideways this much
const MEANDER_K := 0.12
const FADE_FROM := 0.65         # it breaks up into specks past this share of its length
const TURN := 15                # its direction: north-east ± this many degrees
# The cantaloupe terrain
const MELON_D := Vector2i(105, 135)   # its edge: this far north-west of the world's middle ...
const MELON_WANDER := 14.0      # ... wandering this much
const MELON_BLEND := 14.0       # the ground blends into it over this
const MELON_CELL := 26
const MELON_MARGIN := 4
const MELON_RISE := 2.0         # its ground this much over the band's ...
const DIMPLE_D := 2.5           # ... each dimple sunk this much in its middle ...
const DIMPLE_W := 14.0          # ... from this far from its side (the edge-ness e: 0 on a ridge's crest)
const RIDGE_H := 1.0            # ... the ridges this much higher
const RIDGE_W := 4.0
# The walled plain (a frozen lake of ice lava)
const LAKE_DIST := Vector2i(150, 190)
const LAKE_ANGLE := Vector2i(-65, -40)   # degrees from east toward south (negative: north-east)
const LAKE_R := 38
const LAKE_WOBBLE := 4
const LAKE_Y := 46              # its floor (the first empty y over the ice)
const STEPS := 6                # its walls: steps of one block ...
const STEP_W := 2               # ... this wide, up to the rim (LAKE_Y + STEPS)
const RIM_FLAT := 9             # the rim's flat top
const LAKE_BLEND := 10.0        # then down into the band over this
# The crater
const CRATER_DIST := Vector2i(115, 140)
const CRATER_ANGLE := Vector2i(0, 15)   # degrees from east toward south
const CRATER_R := Vector2i(10, 13)
const CRATER_DEPTH := 0.35      # × the radius
const RIM_OUT := 1.4            # its low rim runs out to this × the radius
# Features
const LOOKOUT_R := 2            # the Neptune Lookout's round floor

var _seed := 0
var _cap_z := 0.0
var _melon_d := 0.0
var _first := NONE
var _first_cell := NONE
var _lake := Vector2i.ZERO
var _crater := Vector2i.ZERO
var _crater_r := 0.0
var _dirs: Array[Vector2] = []  # the streaks' directions (x east, y = z: north is -), north-east ± TURN
var _swell := FastNoiseLite.new()
var _cap := FastNoiseLite.new()
var _mottle := FastNoiseLite.new()
var _melon := FastNoiseLite.new()
var _edge := FastNoiseLite.new()
## The Neptune Lookout (SpaceShape places it by the landing pad): its middle, the top of its floor, its boxes
## [lo, hi (exclusive), id] and their bounds.
var lookout := NONE
var lookout_y := 0
var _built: Array = []
var _built_lo := Vector3i.ZERO
var _built_hi := Vector3i.ZERO


func _init(world_seed: int) -> void:
	_seed = world_seed
	var h := absi(_mix(world_seed + 27))
	_cap_z = float(CAP_Z.x + h % (CAP_Z.y - CAP_Z.x + 1))
	_melon_d = float(MELON_D.x + (h >> 5) % (MELON_D.y - MELON_D.x + 1))
	var h2 := absi(_mix(world_seed * 3 + 2701))
	var la := deg_to_rad(float(LAKE_ANGLE.x + h2 % (LAKE_ANGLE.y - LAKE_ANGLE.x + 1)))
	var ld := float(LAKE_DIST.x + (h2 >> 7) % (LAKE_DIST.y - LAKE_DIST.x + 1))
	_lake = Vector2i(roundi(cos(la) * ld), roundi(sin(la) * ld))
	var ca := deg_to_rad(float(CRATER_ANGLE.x + (h2 >> 14) % (CRATER_ANGLE.y - CRATER_ANGLE.x + 1)))
	var cd := float(CRATER_DIST.x + (h2 >> 19) % (CRATER_DIST.y - CRATER_DIST.x + 1))
	_crater = Vector2i(roundi(cos(ca) * cd), roundi(sin(ca) * cd))
	_crater_r = float(CRATER_R.x + (h2 >> 25) % (CRATER_R.y - CRATER_R.x + 1))
	for i in 2 * TURN + 1:   # north-east ± TURN degrees: x east, the second value z (north is -)
		var a := deg_to_rad(45.0 + i - TURN)
		_dirs.append(Vector2(cos(a), -sin(a)))
	var fx := FIRST_X.x + (h >> 11) % (FIRST_X.y - FIRST_X.x + 1)
	var fin := FIRST_IN.x + (h >> 17) % (FIRST_IN.y - FIRST_IN.x + 1)
	_first = Vector2i(fx, ceili(_cap_z + CAP_WANDER) + VENT_IN + fin)
	_first_cell = Vector2i(floori(float(_first.x) / VENT_CELL), floori(float(_first.y) / VENT_CELL))
	_swell.seed = world_seed + 270
	_swell.frequency = 0.006
	_swell.fractal_octaves = 2
	_cap.seed = world_seed + 271
	_cap.frequency = 0.01
	_cap.fractal_octaves = 2
	_mottle.seed = world_seed + 272
	_mottle.frequency = 0.03
	_mottle.fractal_octaves = 2
	_melon.seed = world_seed + 273
	_melon.frequency = 0.008
	_melon.fractal_octaves = 2
	_edge.seed = world_seed + 274
	_edge.frequency = 0.6
	_edge.fractal_octaves = 1


# --- The band ----------------------------------------------------------------------------------------------------------

## The band's own height at (fx, fz) (before the cap's rise, the lake, the crater and the cantaloupe terrain).
func frost_height(fx: float, fz: float) -> float:
	return BASE + SWELL * _swell.get_noise_2d(fx, fz)


# --- The polar cap and its geysers -------------------------------------------------------------------------------------

## The cap's edge at x: every column south of it (more z) is the cap's.
func cap_edge(fx: float) -> float:
	return _cap_z + CAP_WANDER * _cap.get_noise_2d(fx, 300.0)


## The first geyser: south of the world's middle, deep in the cap (its streak runs north-east over the pink ice alone).
func first_geyser() -> Vector2i:
	return _first


## The vent of cell (x, z / VENT_CELL), or NONE: at most one per cell, well inside it, deep in the cap (south of the
## cap's farthest wander), never near the first geyser (the first geyser's own cell has it).
func vent_in_cell(cell: Vector2i) -> Vector2i:
	if cell == _first_cell:
		return _first
	var h := absi(_mix(_mix(cell.x * 7 + 3 + _seed * 13) + cell.y * 11 - 9))
	if h % 100 >= VENT_CHANCE:
		return NONE
	var span := VENT_CELL - 2 * VENT_MARGIN
	var v := Vector2i(cell.x * VENT_CELL + VENT_MARGIN + (h >> 8) % span, cell.y * VENT_CELL + VENT_MARGIN + (h >> 18) % span)
	if float(v.y) < _cap_z + CAP_WANDER * NOISE_MARGIN + VENT_IN:
		return NONE
	if Vector2(v - _first).length() < FIRST_CLEAR:
		return NONE
	return v


## Every vent within `radius` of (x, z).
func vents_near(x: int, z: int, radius: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var c0 := Vector2i(floori((x - radius) / VENT_CELL), floori((z - radius) / VENT_CELL))
	var c1 := Vector2i(floori((x + radius) / VENT_CELL), floori((z + radius) / VENT_CELL))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var v := vent_in_cell(Vector2i(cx, cz))
			if v != NONE and Vector2(v.x - x, v.y - z).length() <= radius:
				out.append(v)
	return out


## The vent nearest `from` (within two cells), or NONE.
func nearest_vent(from: Vector2i) -> Vector2i:
	var best := NONE
	var best_d := INF
	for v in vents_near(from.x, from.y, VENT_CELL * 2.0):
		var d := Vector2(v - from).length_squared()
		if d < best_d:
			best_d = d
			best = v
	return best


## A vent's streak: how far it runs downwind.
func streak_length(v: Vector2i) -> float:
	if v == _first:
		return FIRST_LEN
	var h := absi(_mix(v.x * 31 + v.y * 17 + _seed))
	return float(STREAK_LEN.x + h % (STREAK_LEN.y - STREAK_LEN.x + 1))


## The point of vent v's streak `a` blocks downwind, on its middle line (it wanders a little sideways).
func streak_centre(v: Vector2i, a: float) -> Vector2i:
	var s := _streak_of(v)
	var dir: Vector2 = s[0]
	var p := Vector2(v) + dir * a - Vector2(-dir.y, dir.x) * MEANDER * sin(a * MEANDER_K + float(s[1]))
	return Vector2i(roundi(p.x), roundi(p.y))


## [direction, meander phase, half width at the vent] of vent v's streak.
func _streak_of(v: Vector2i) -> Array:
	if v == _first:
		return [_dirs[TURN], 0.0, 3.2]
	var h := absi(_mix(v.x * 29 - v.y * 23 + _seed * 3))
	return [_dirs[h % _dirs.size()], float((h >> 6) % 628) / 100.0,
		STREAK_W.x + float((h >> 16) % 100) / 99.0 * (STREAK_W.y - STREAK_W.x)]


## (fx, fz) is on a geyser's dark streak (the cap's part of it; the caller knows it is on the cap).
func _on_streak(x: int, z: int) -> bool:
	var fx := float(x)
	var fz := float(z)
	var reach := float(STREAK_LEN.y) + STREAK_W.y + MEANDER + 2.0
	var c0 := Vector2i(floori((fx - reach) / VENT_CELL), floori((fz - SPOT_R - 2.0) / VENT_CELL))
	var c1 := Vector2i(floori((fx + SPOT_R + 2.0) / VENT_CELL), floori((fz + reach) / VENT_CELL))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var v := vent_in_cell(Vector2i(cx, cz))
			if v == NONE:
				continue
			var s := _streak_of(v)
			var dir: Vector2 = s[0]
			var d := Vector2(fx - v.x, fz - v.y)
			var a := d.dot(dir)
			var length := streak_length(v)
			if a < 1.0 or a > length:
				continue
			var across := absf(d.dot(Vector2(-dir.y, dir.x)) + MEANDER * sin(a * MEANDER_K + float(s[1])))
			if across >= float(s[2]) * (1.0 - TAPER * a / length) + 0.6:
				continue
			if a > FADE_FROM * length:   # it breaks up into specks far downwind
				var gap := (a / length - FADE_FROM) / (1.0 - FADE_FROM) * 80.0
				if absi(_mix(x * 31 + z * 17 + _seed)) % 100 < int(gap):
					continue
			return true
	return false


## The cap's first plain pink column straight south of `from` (within 400 blocks), or NONE.
func cap_point_south_of(from: Vector2i) -> Vector2i:
	for dz in range(0, 400):
		var k := column(from.x, from.y + dz) & 15
		if k == CAP or k == MOTTLE:
			return Vector2i(from.x, from.y + dz)
	return NONE


# --- The cantaloupe terrain --------------------------------------------------------------------------------------------

## How far (x, z) is from the cantaloupe terrain's edge (positive outside it, negative in it).
func melon_edge_distance(x: int, z: int) -> float:
	return _melon_edge(float(x), float(z)) - (-float(x) - float(z)) * INV_SQRT2


func _melon_edge(fx: float, fz: float) -> float:
	return _melon_d + MELON_WANDER * _melon.get_noise_2d((fx - fz) * INV_SQRT2 * 0.7, 700.0)


## The middle of dimple (cell) (cx, cz), somewhere inside it.
func _melon_site(cx: int, cz: int) -> Vector2:
	var h := absi(_mix(_mix(cx * 53 + 7 + _seed * 9) + cz * 61 - 5))
	var span := MELON_CELL - 2 * MELON_MARGIN
	return Vector2(cx * MELON_CELL + MELON_MARGIN + h % span, cz * MELON_CELL + MELON_MARGIN + (h >> 10) % span)


## How far (fx, fz) is from its dimple's side: the second-nearest dimple middle's distance less the nearest's (0 on a
## ridge's crest).
func _melon_e(fx: float, fz: float) -> float:
	var c := Vector2i(floori(fx / MELON_CELL), floori(fz / MELON_CELL))
	var p := Vector2(fx, fz)
	var d1 := INF
	var d2 := INF
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var d := p.distance_to(_melon_site(c.x + dx, c.y + dz))
			if d < d1:
				d2 = d1
				d1 = d
			elif d < d2:
				d2 = d
	return d2 - d1


## The dimple middle nearest (x, z).
func melon_site_near(p: Vector2i) -> Vector2i:
	var c := Vector2i(floori(float(p.x) / MELON_CELL), floori(float(p.y) / MELON_CELL))
	var best := Vector2.ZERO
	var best_d := INF
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var s := _melon_site(c.x + dx, c.y + dz)
			var d := s.distance_to(Vector2(p))
			if d < best_d:
				best_d = d
				best = s
	return Vector2i(int(best.x), int(best.y))


## The first dimple column on the way north-west from `from` (within 500 blocks), or NONE.
func first_melon_toward(from: Vector2i) -> Vector2i:
	for d in range(0, 360):
		var p := from + Vector2i(-d, -d)
		if column(p.x, p.y) & 15 == DIMPLE:
			return p
	return NONE


# --- The frozen lake and the crater ------------------------------------------------------------------------------------

## The middle of the walled plain's frozen lake.
func lake_centre() -> Vector2i:
	return _lake


## The lake's floor's edge `(dx, dz)` from its middle is this far from it (a wobbly round edge).
func lake_radius(dx: float, dz: float) -> float:
	var a := atan2(dz, dx)
	return LAKE_R + LAKE_WOBBLE * _edge.get_noise_2d(cos(a) * 3.0, sin(a) * 3.0)


## How far the lake's walls, rim and blend reach from its middle.
func lake_reach() -> float:
	return LAKE_R + LAKE_WOBBLE + STEPS * STEP_W + RIM_FLAT + LAKE_BLEND


## The crater's middle and radius.
func crater_centre() -> Vector2i:
	return _crater


func crater_radius() -> int:
	return int(_crater_r)


## (fx, fz) is on or near the lake, the crater or a geyser (steep or special ground a secret keeps off).
func steep_near(fx: float, fz: float, margin: float) -> bool:
	if Vector2(fx - _lake.x, fz - _lake.y).length() < lake_reach() - LAKE_BLEND + margin:
		return true
	if Vector2(fx - _crater.x, fz - _crater.y).length() < _crater_r * RIM_OUT + margin:
		return true
	return not vents_near(roundi(fx), roundi(fz), SPOT_R + margin + 2.0).is_empty()


## The lake near the pad's place (or the crater, a geyser, the cap or the cantaloupe terrain): the pad keeps away.
func calm(x: int, z: int) -> bool:
	var fx := float(x)
	var fz := float(z)
	if cap_edge(fx) - fz < 50.0 or melon_edge_distance(x, z) < 50.0:
		return false
	if Vector2(fx - _lake.x, fz - _lake.y).length() < lake_reach() + 30.0:
		return false
	return Vector2(fx - _crater.x, fz - _crater.y).length() > _crater_r * RIM_OUT + 40.0


# --- A column ----------------------------------------------------------------------------------------------------------

## Height * 16 + kind of the column at (x, z) (the landing pad's flattening is SpaceShape's). Noise nothing can need is
## skipped (the cap's line far from it, the cantaloupe terrain's line far from it), so every column gets the same answer,
## cheaper.
func column(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var frost := frost_height(fx, fz)
	var wander := CAP_WANDER * NOISE_MARGIN
	if fz > _cap_z - wander:   # the cap (south of its line)
		var into := fz - _cap_z
		if into < wander + CAP_BLEND:
			into = fz - cap_edge(fx)
		if into > 0.0:
			return _cap_column(x, z, frost + CAP_RISE * smoothstep(0.0, CAP_BLEND, into))
	var ldx := fx - _lake.x
	var ldz := fz - _lake.y
	var reach := lake_reach()
	if ldx * ldx + ldz * ldz < reach * reach:   # the walled plain
		var s := sqrt(ldx * ldx + ldz * ldz) - lake_radius(ldx, ldz)
		if s < 0.0:
			return _pack(LAKE_Y, LAKE)
		if s < STEPS * STEP_W:
			return _pack(LAKE_Y + 1 + floori(s / STEP_W), TERRACE)
		var rim := float(LAKE_Y + STEPS)
		return _pack(lerpf(rim, frost, smoothstep(float(RIM_FLAT), RIM_FLAT + LAKE_BLEND, s - STEPS * STEP_W)), FROST)
	var cdx := fx - _crater.x
	var cdz := fz - _crater.y
	var d2 := (cdx * cdx + cdz * cdz) / (_crater_r * _crater_r)
	if d2 < RIM_OUT * RIM_OUT:   # the crater: a bowl rising smoothly to a low rim, falling away outside it
		var rim := maxf(1.0, _crater_r * 0.12)
		if d2 < 1.0:
			return _pack(frost + rim * d2 - _crater_r * CRATER_DEPTH * (1.0 - d2), CRATER if d2 < 0.8 else FROST)
		return _pack(frost + rim * (RIM_OUT - sqrt(d2)) / (RIM_OUT - 1.0), FROST)
	var m := (-fx - fz) * INV_SQRT2
	var mwander := MELON_WANDER * NOISE_MARGIN
	if m > _melon_d - mwander:   # the cantaloupe terrain (north-west of its line)
		var t := 1.0
		if m < _melon_d + mwander + MELON_BLEND:
			var me := _melon_edge(fx, fz)
			t = smoothstep(me, me + MELON_BLEND, m)
		if fz > _cap_z - wander - MELON_BLEND:   # far west it meets the cap: it fades back to the band by the cap's edge
			t = minf(t, smoothstep(0.0, MELON_BLEND, cap_edge(fx) - fz))
		if t > 0.0:
			var e := _melon_e(fx, fz)
			var melon := frost + MELON_RISE - DIMPLE_D * smoothstep(RIDGE_W, DIMPLE_W, e) \
				+ RIDGE_H * (1.0 - smoothstep(0.0, RIDGE_W, e))
			var kind := FROST
			if t >= 0.5:
				kind = RIDGE if e < RIDGE_W * 0.6 else DIMPLE
			return _pack(lerpf(frost, melon, t), kind)
	return _pack(frost, FROST)


## A cap column whose ground is g: a geyser's vent and its ring of dust (flush with the vent), a streak, a mottled patch
## or pink ice.
func _cap_column(x: int, z: int, g: float) -> int:
	var v := vent_in_cell(Vector2i(floori(float(x) / VENT_CELL), floori(float(z) / VENT_CELL)))
	if v != NONE:
		var d2 := float((x - v.x) * (x - v.x) + (z - v.y) * (z - v.y))
		if d2 < SPOT_R * SPOT_R:   # (a vent is deep in the cap: its ground there is the band's plus the full rise)
			var vg := frost_height(float(v.x), float(v.y)) + CAP_RISE
			return _pack(vg, VENT if d2 <= HOLE_R * HOLE_R else SPOT)
	if _on_streak(x, z):
		return _pack(g, STREAK)
	if _mottle.get_noise_2d(float(x), float(z)) > MOTTLE_OVER:
		return _pack(g, MOTTLE)
	return _pack(g, CAP)


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


# --- A column's blocks -------------------------------------------------------------------------------------------------

## The block at y (0 <= y < g) of a column of `kind` whose ground is g (the landing pad is SpaceShape's).
static func block(y: int, g: int, kind: int) -> int:
	if y == g - 1:
		return top_block(kind)
	if y >= g - 1 - sub_depth(kind):
		return sub_block(kind, y, g)
	return BlockIds.WATER_ICE


## How many layers of a column's own lie under its top block (the rest is water ice: Triton's icy mantle).
static func sub_depth(kind: int) -> int:
	match kind:
		DIMPLE, RIDGE:
			return 3
		LAKE, TERRACE:   # the ice lava's layers
			return 5
	return FROST_DEPTH


## The layer at y under a column's top block (above the water ice).
static func sub_block(kind: int, y: int, g: int) -> int:
	match kind:
		FROST:   # a second layer of frost, then the crust of frozen nitrogen
			return BlockIds.TRITON_FROST if y == g - 2 else BlockIds.NITROGEN_ICE
		CAP, MOTTLE, STREAK, SPOT:   # pink ice, then nitrogen ice
			return BlockIds.PINK_ICE if y >= g - 3 else BlockIds.NITROGEN_ICE
		DIMPLE, RIDGE:
			return BlockIds.CANTALOUPE_ICE
		LAKE, TERRACE:
			return BlockIds.ICE_LAVA
	return BlockIds.NITROGEN_ICE


## The top block of a column of `kind`.
static func top_block(kind: int) -> int:
	match kind:
		CAP:
			return BlockIds.PINK_ICE
		MOTTLE:
			return BlockIds.MOTTLED_ICE
		STREAK, SPOT:
			return BlockIds.GEYSER_DUST
		VENT:
			return BlockIds.NITROGEN_GEYSER
		DIMPLE:
			return BlockIds.CANTALOUPE_ICE
		RIDGE:
			return BlockIds.RIDGE_ICE
		LAKE, TERRACE:
			return BlockIds.ICE_LAVA
		CRATER:   # dug through the frost into the nitrogen ice under it
			return BlockIds.NITROGEN_ICE
	return BlockIds.TRITON_FROST


## The bright band (where the landing pad, the aliens' camp and the boulders may be).
static func is_plains(kind: int) -> bool:
	return kind == FROST


## The polar cap (its ice, patches, streaks and geysers).
static func is_cap(kind: int) -> bool:
	return kind >= CAP and kind <= VENT


## The cantaloupe terrain (its dimples and ridges).
static func is_melon(kind: int) -> bool:
	return kind == DIMPLE or kind == RIDGE


# --- Sights ------------------------------------------------------------------------------------------------------------

## The sight at a column of packed `c` (column()): &"geyser" (a vent and its ring), &"trail" (a dark streak: the word
## "streak" is kept out of the game's text, test_no_guilt_words), &"cap" (pink ice), &"melon" (the cantaloupe terrain),
## &"lake" (the frozen lake's floor), &"crater", or &"".
func sight(_x: int, _z: int, c: int) -> StringName:
	match c & 15:
		VENT, SPOT:
			return &"geyser"
		STREAK:
			return &"trail"
		CAP, MOTTLE:
			return &"cap"
		DIMPLE, RIDGE:
			return &"melon"
		LAKE:
			return &"lake"
		CRATER:
			return &"crater"
	return &""


## The sights MY MAP shows from the landing, [id, column] each (the lookout's is SpaceShape's): the first geyser, a point
## on its streak, the cap south of the pad, the cantaloupe terrain north-west of it, the lake, the crater.
func sight_spots(from: Vector2i) -> Array:
	return [[&"geyser", _first], [&"trail", streak_centre(_first, 16.0)], [&"cap", cap_point_south_of(from)],
		[&"melon", first_melon_toward(from)], [&"lake", _lake], [&"crater", _crater]]


# --- The Neptune Lookout (by the landing pad) --------------------------------------------------------------------------

## Builds the Neptune Lookout at column c on grounds `ground` (a Callable (x, z) -> int, the pad's blend included): a
## round floor of cap bricks (a plinth where the ground dips), a telescope on a truss looking north-east and up at
## Neptune, a globe of Neptune on a post and a blue beacon. Called once, before any generator thread starts.
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
			_add(Vector3i(c.x + dx, low - 1, c.y + dz), Vector3i(c.x + dx + 1, top, c.y + dz + 1), BlockIds.CAP_BRICK)
	var y := top
	_add(Vector3i(c.x, y, c.y), Vector3i(c.x + 1, y + 2, c.y + 1), BlockIds.TRUSS)                 # the stand ...
	_add(Vector3i(c.x, y + 2, c.y), Vector3i(c.x + 1, y + 3, c.y + 1), BlockIds.TELESCOPE)          # ... the tube ...
	_add(Vector3i(c.x + 1, y + 3, c.y - 1), Vector3i(c.x + 2, y + 4, c.y), BlockIds.TELESCOPE)      # ... up at Neptune
	_add(Vector3i(c.x - 1, y, c.y + 1), Vector3i(c.x, y + 1, c.y + 2), BlockIds.TRUSS)             # a post ...
	_add(Vector3i(c.x - 1, y + 1, c.y + 1), Vector3i(c.x, y + 2, c.y + 2), BlockIds.NEPTUNE_GLOBE)  # ... Neptune
	_add(Vector3i(c.x + 1, y, c.y + 1), Vector3i(c.x + 2, y + 1, c.y + 2), BlockIds.BLUE_BEACON)    # a blue beacon
	_built_lo = Vector3i(c.x - LOOKOUT_R, low - 1, c.y - LOOKOUT_R)
	_built_hi = Vector3i(c.x + LOOKOUT_R + 1, y + 4, c.y + LOOKOUT_R + 1)


func _add(lo: Vector3i, hi: Vector3i, id: int) -> void:
	_built.append([lo, hi, id])


## The Neptune Lookout's block at p, or -1 (the later box wins).
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


## The column (x, z) is under the Neptune Lookout (within `margin`).
func on_lookout(x: int, z: int, margin: int = 0) -> bool:
	return lookout != NONE and absi(x - lookout.x) <= LOOKOUT_R + margin and absi(z - lookout.y) <= LOOKOUT_R + margin


## Writes the Neptune Lookout where it reaches into this buffer.
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
