class_name MarsTerrain
extends RefCounted
## Mars's regions as pure rules (cosmos, spec §21b.2), for SpaceShape's planet MARS: every rule is a function of the
## seed and (x, z), read-only after construction (the generator's threads share it). North is -z, as on MY MAP.
## - The plains: red dust over rusty regolith over basalt with pale layers (every 7 blocks, 2 are layered rock),
##   gentle swells, craters with raised rims (SpaceShape's craters) and dry river valleys with pale beds.
## - The giant shield volcano (like Olympus Mons, the tallest volcano in the solar system): north-west of the landing
##   pad, a two-step cliff at its foot (the real one has a cliff ring too), wide gentle flanks of lava rock rising
##   ~70 blocks (bare basalt near the top, dusty lower down) and a caldera sunk into its top; terraced walls.
## - The canyon (like Valles Marineris, which runs along Mars's equator): east-west, south of the pad, about 2,400 blocks
##   long, a flat dusty floor at CANYON_FLOOR and terraced walls whose pale layers show.
## - The polar caps: north of north_edge() water ice rising gently to a plateau, dust layers inside (the real caps'
##   layered deposits) and troughs cut by the wind; south of south_edge() the same topped with dry ice (frozen carbon
##   dioxide, as on the real south cap); frost patches on the dust near both.
## Every step between two columns is at most 4 blocks (a jump at Mars's 0.38 gravity climbs ~4.4): the cliffs and
## terraces come in steps of 3 and 4. Heights stay between SpaceShape.MIN_GROUND and MAX_GROUND (under the
## generator's SKY_TOP). column() packs a column's height and kind (height * 16 + kind), for the generator's fast path
## and SpaceShape's reference alike.

const PLAINS := 0
const VALLEY := 1        # a dry river bed
const CANYON := 2        # the canyon's floor and its terraced walls
const VOLCANO := 3       # the volcano's cliff and flanks
const CALDERA := 4       # the pit on its top
const NORTH_CAP := 5
const SOUTH_CAP := 6
const FROST_N := 7       # frost patches on the dust near the north cap (water ice)
const FROST_S := 8       # ... near the south cap (dry ice)

const BASE := 54.0
const SWELL := 5.0
const FINE := 1.2
const MAX_GROUND := 138
# The volcano
const VOLCANO_RADIUS := 190
const CALDERA_RADIUS := 30
const CLIFF := 4                 # two steps of this at its foot
const FLANK := 64                # the flanks' rise from the cliff's top to the rim
const CALDERA_DEPTH := 12
const CALDERA_WALL := 8          # its terraced wall's width
const DUST_LINE := 40            # above this rise the lava rock is bare
const SUMMIT := 6                # the summit's sight reaches this far past the caldera's edge
const VOLCANO_DISTANCE := Vector2i(280, 310)   # from the middle of the world, north-west
# The canyon
const CANYON_FLOOR := 30
const CANYON_STEP := 3
const CANYON_WALL := 24
const CANYON_FLOOR_W := 10.0     # half the floor's width (± 5)
const CANYON_HALF := 1200        # half its length
const CANYON_FADE := 160         # it gets shallower over this at each end
# The polar caps
const NORTH := -560
const SOUTH := 760
const EDGE_WOBBLE := 24.0
const CAP_RISE := 14.0
const CAP_RAMP := 3.0            # blocks walked per block of rise onto a cap
const ICE_FLOOR := 44            # a cap's ice (with its dust layers) goes down to here
const FROST_BAND := 70.0
const TROUGH_W := 0.05
const TROUGH_DEPTH := 4.0
# The dry rivers
const VALLEY_W := 0.05
const VALLEY_DEPTH := 5.0
const VALLEY_BED := 1.5          # a valley this deep has a pale bed
const VALLEY_MASK := -0.15
const QUIET := 40.0              # rivers and craters fade out this far before a cap or the volcano's cliff

var _volcano := Vector2i.ZERO
var _canyon_z := 0.0
var _canyon_x := 0
var _phase := 0.0
var _north := NORTH
var _south := SOUTH
var _swell := FastNoiseLite.new()
var _fine := FastNoiseLite.new()
var _valley := FastNoiseLite.new()
var _mask := FastNoiseLite.new()
var _edge := FastNoiseLite.new()
var _trough := FastNoiseLite.new()
var _frost := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	var h := absi(_mix(world_seed))
	var a := deg_to_rad(215.0 + float(h % 31))                 # north-west: 215°..245° (x east, z south)
	var d := VOLCANO_DISTANCE.x + (h >> 5) % (VOLCANO_DISTANCE.y - VOLCANO_DISTANCE.x + 1)
	_volcano = Vector2i(roundi(cos(a) * d), roundi(sin(a) * d))
	_canyon_z = 150.0 + float((h >> 11) % 30)
	_canyon_x = (h >> 16) % 201 - 100
	_phase = float((h >> 7) % 628) / 100.0
	_north = NORTH - (h >> 13) % 40
	_south = SOUTH + (h >> 19) % 40
	_swell.seed = world_seed + 190
	_swell.frequency = 0.006
	_swell.fractal_octaves = 3
	_fine.seed = world_seed + 191
	_fine.frequency = 0.05
	_valley.seed = world_seed + 192
	_valley.frequency = 0.004
	_valley.fractal_octaves = 1
	_mask.seed = world_seed + 193
	_mask.frequency = 0.003
	_mask.fractal_octaves = 1
	_edge.seed = world_seed + 194
	_edge.frequency = 0.01
	_edge.fractal_octaves = 1
	_trough.seed = world_seed + 195
	_trough.frequency = 0.012
	_trough.fractal_octaves = 1
	_frost.seed = world_seed + 196
	_frost.frequency = 0.08
	_frost.fractal_octaves = 1


## The middle of the volcano's caldera.
func volcano_centre() -> Vector2i:
	return _volcano


## The canyon's middle line at x (its floor's centre).
func canyon_z(x: int) -> float:
	return _canyon_z + 26.0 * sin(x * 0.0055 + _phase) + 9.0 * sin(x * 0.017 + _phase * 2.0)


## [first x, last x] of the canyon.
func canyon_span() -> Vector2i:
	return Vector2i(_canyon_x - CANYON_HALF, _canyon_x + CANYON_HALF)


## 1 along the canyon, easing to 0 at its ends.
func canyon_fade(x: int) -> float:
	return smoothstep(float(CANYON_HALF), float(CANYON_HALF - CANYON_FADE), absf(float(x - _canyon_x)))


## The north cap's edge line (its wobble aside): the cap is north of it (smaller z).
func north_edge() -> int:
	return _north


## The south cap's edge line: the cap is south of it.
func south_edge() -> int:
	return _south


## Height * 16 + kind of the column at (x, z), with SpaceShape's craters' change `crater` there (the landing pad's
## flattening is SpaceShape's).
func column(x: int, z: int, crater: float) -> int:
	var plains := BASE + SWELL * _swell.get_noise_2d(x, z) + FINE * _fine.get_noise_2d(x, z)
	var dx := float(x - _volcano.x)
	var dz := float(z - _volcano.y)
	var d := sqrt(dx * dx + dz * dz)
	if d < VOLCANO_RADIUS:
		var rise := volcano_rise(d)
		return _pack(plains + rise, CALDERA if d < CALDERA_RADIUS else VOLCANO)
	var fz := float(z)
	var north := float(_north) + EDGE_WOBBLE * _edge.get_noise_1d(x * 0.8)
	var south := float(_south) + EDGE_WOBBLE * _edge.get_noise_1d(x * 0.8 + 900.0)
	if fz < north:
		return _pack(plains + _cap_rise(x, z, (north - fz) / CAP_RAMP), NORTH_CAP)
	if fz > south:
		return _pack(plains + _cap_rise(x, z, (fz - south) / CAP_RAMP), SOUTH_CAP)
	var quiet := smoothstep(0.0, QUIET, minf(minf(fz - north, south - fz), d - VOLCANO_RADIUS))
	var h := plains + crater * quiet
	var kind := PLAINS
	var vn := absf(_valley.get_noise_2d(x, z))
	if vn < VALLEY_W:
		var carve := VALLEY_DEPTH * (1.0 - (vn / VALLEY_W) * (vn / VALLEY_W)) * quiet \
			* smoothstep(VALLEY_MASK, VALLEY_MASK + 0.15, _mask.get_noise_2d(x, z))
		h -= carve
		if carve >= VALLEY_BED:
			kind = VALLEY
	var cz := canyon_z(x)
	var off := absf(fz - cz)
	if off < CANYON_FLOOR_W + 5.0 + CANYON_WALL:
		var fade := canyon_fade(x)
		if fade > 0.0:
			var fw := CANYON_FLOOR_W + 5.0 * _edge.get_noise_1d(x * 1.7 + 500.0)
			var bottom := h - (h - float(CANYON_FLOOR)) * fade
			var ch := h
			if off <= fw:
				ch = bottom
			elif off < fw + CANYON_WALL:   # terraces: the wall's slope in steps of CANYON_STEP on a fixed grid
				var t := (off - fw) / CANYON_WALL
				ch = maxf(bottom, floorf((bottom + t * (h - bottom)) / CANYON_STEP) * CANYON_STEP)
			if ch < h - 0.5:
				h = ch
				kind = CANYON
	if kind == PLAINS and (fz - north < FROST_BAND or south - fz < FROST_BAND):
		var near_north := fz - north < FROST_BAND
		var k := (fz - north if near_north else south - fz) / FROST_BAND
		if _frost.get_noise_2d(x, z) > -0.3 + 0.9 * k:
			kind = FROST_N if near_north else FROST_S
	return _pack(h, kind)


## The volcano's rise over the plains `d` from its middle: the cliff's two steps at its foot, the long gentle flanks up
## to the rim, the caldera's terraced wall down to its flat floor.
func volcano_rise(d: float) -> float:
	if d >= VOLCANO_RADIUS:
		return 0.0
	if d > VOLCANO_RADIUS - 3:
		return float(CLIFF)
	if d > VOLCANO_RADIUS - 6:
		return float(CLIFF * 2)
	var rim := float(CLIFF * 2 + FLANK)
	if d >= CALDERA_RADIUS:
		return float(CLIFF * 2) + FLANK * (VOLCANO_RADIUS - 6 - d) / float(VOLCANO_RADIUS - 6 - CALDERA_RADIUS)
	var floor_rise := rim - CALDERA_DEPTH
	var inner := float(CALDERA_RADIUS - CALDERA_WALL)
	if d <= inner:
		return floor_rise
	return floor_rise + floorf((d - inner) / CALDERA_WALL * CALDERA_DEPTH / CANYON_STEP) * CANYON_STEP


## A cap's rise `ramp` blocks in from its edge (up to CAP_RISE), with the wind's troughs further in.
func _cap_rise(x: int, z: int, ramp: float) -> float:
	var rise := minf(CAP_RISE, ramp)
	if ramp > CAP_RISE + 6.0:
		var tn := absf(_trough.get_noise_2d(x, z))
		if tn < TROUGH_W:
			rise -= TROUGH_DEPTH * (1.0 - tn / TROUGH_W) * minf(1.0, (ramp - CAP_RISE - 6.0) / 4.0)
	return rise


## The volcano's kinds: lava rock all the way down.
static func is_volcanic(kind: int) -> bool:
	return kind == VOLCANO or kind == CALDERA


static func is_cap(kind: int) -> bool:
	return kind == NORTH_CAP or kind == SOUTH_CAP


# --- A column's blocks ---------------------------------------------------------------------------------

## The block at y (0 <= y < g) of a column of `kind` whose ground is g (the landing pad is SpaceShape's).
static func block(y: int, g: int, kind: int) -> int:
	if y == g - 1:
		return top_block(kind, g)
	if y >= g - 1 - sub_depth(kind, g):
		return sub_block(kind, y, g)
	return rock_block(y, kind)


## The top block: red dust, a pale river bed, bare lava rock high on the volcano, ice or dry ice on the caps.
static func top_block(kind: int, g: int) -> int:
	match kind:
		VALLEY:
			return BlockIds.MARS_SEDIMENT
		VOLCANO:
			return BlockIds.BASALT if float(g) >= BASE + DUST_LINE else BlockIds.MARS_DUST
		CALDERA:
			return BlockIds.BASALT
		NORTH_CAP, FROST_N:
			return BlockIds.POLAR_ICE
		SOUTH_CAP, FROST_S:
			return BlockIds.DRY_ICE
	return BlockIds.MARS_DUST


## How many blocks under the top are the column's own layers (the rest is rock).
static func sub_depth(kind: int, g: int) -> int:
	match kind:
		VALLEY, CANYON:
			return 2
		VOLCANO, CALDERA:
			return 0
		NORTH_CAP, SOUTH_CAP:
			return maxi(g - 1 - ICE_FLOOR, 0)
	return 3


## A layer under the top: regolith; a river bed's pale layer; a cap's ice with a dust layer every 5 blocks.
static func sub_block(kind: int, y: int, g: int) -> int:
	match kind:
		VALLEY:
			return BlockIds.MARS_SEDIMENT if y == g - 2 else BlockIds.MARS_REGOLITH
		NORTH_CAP, SOUTH_CAP:
			return BlockIds.MARS_DUST if posmod(y, 5) == 0 and y < g - 2 else BlockIds.POLAR_ICE
	return BlockIds.MARS_REGOLITH


## The rock at y >= 0: the volcano's basalt; elsewhere basalt with 2 pale layers in every 7.
static func rock_block(y: int, kind: int) -> int:
	if is_volcanic(kind):
		return BlockIds.BASALT
	return BlockIds.MARS_SEDIMENT if posmod(y, 7) >= 5 else BlockIds.BASALT


## A column no river, crater edge or region touches: the landing pad's place.
func calm(x: int, z: int) -> bool:
	return absf(_valley.get_noise_2d(x, z)) >= VALLEY_W * 1.5


# --- Sights ---------------------------------------------------------------------------------------------

## The sight at a column of packed `c` (column()) at (x, z): &"volcano" (its summit), &"canyon" (its floor),
## &"north_cap", &"south_cap", &"river" (a dry river bed), or &"".
func sight(x: int, z: int, c: int) -> StringName:
	match c & 15:
		CALDERA:
			return &"volcano"
		VOLCANO:
			return &"volcano" if Vector2(x - _volcano.x, z - _volcano.y).length() < CALDERA_RADIUS + SUMMIT else &""
		CANYON:
			return &"canyon" if (c >> 4) <= CANYON_FLOOR + 4 else &""
		NORTH_CAP:
			return &"north_cap"
		SOUTH_CAP:
			return &"south_cap"
		VALLEY:
			return &"river"
	return &""


static func _pack(h: float, kind: int) -> int:
	return clampi(roundi(h), SpaceShape.MIN_GROUND, MAX_GROUND) * 16 + kind


static func _mix(v: int) -> int:
	var h := v * 668265263 + 374761393
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
