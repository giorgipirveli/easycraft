class_name IoTerrain
extends RefCounted
## Io's regions as pure rules (cosmos, spec §21b.2), for SpaceShape's planet IO: every rule is a function of the seed and
## (x, z), read-only after construction (the generator's threads share it). North is -z, as on MY MAP. Every column is a
## plain column of ground (no overhangs, no caves, no water: Io has no water to speak of).
## - The plains: yellow sulphur, gentle swells, orange sulphur patches and white frost (frozen sulphur dioxide), over
##   Io's rock with a layer of old black lava every LAYER_EVERY blocks.
## - The volcanoes (at most one per VENT_CELL cell): a low cone of black lava rock, a crater on top with the vent at its
##   bottom (the vent throws a child up: PadRules), a skirt of black lava round its foot and a ring of red sulphur further
##   out (the red rings real plumes drop round their volcanoes).
## - Small lava lakes (paterae, at most one per PATERA_CELL cell): a hollow floored with lava crust (black with glowing
##   cracks), a shore of black lava rock. Cooled: no hot lava in them.
## - The big lava lake (one per world, a walk from the pad): a flat crust in a hollow with hot lava under it, a narrow
##   moat of bright hot lava (MOAT_W) round it, a step under the crust, fenced by a rim of black lava rock (MOAT_DEPTH over
##   the moat); CAUSEWAYS paths of black lava rock step down from the rim across the moat to the crust. Hot lava never
##   hurts (spec §3c): touching it, a warm bounce throws the child up and out (PadRules.LAVA_SPEED), and no band of it is
##   wider than MOAT_W, so nobody is ever stuck in it.
## - The mountain (one per world): a tilted block of crust (real Io mountains are blocks of crust pushed up), an ellipse
##   rising gently (RAMP per block) from one long side to a flat top PEAK_H high, frosty white, and falling steeply (SIDE
##   per block) on the other sides; its faces show the rock's layers.
## Every step between two columns is at most MAX_STEP (a jump at 0.18 gravity climbs ~9). column() packs a column's height
## and kind (height * 16 + kind).

const PLAINS := 0       # yellow sulphur
const ORANGE := 1       # orange sulphur patches
const FROST := 2        # white frost (frozen sulphur dioxide)
const RED_RING := 3     # red sulphur round a volcano
const PATERA := 4       # a small lava lake's crust
const SHORE := 5        # black lava rock: a small lake's shore, the big lake's rim and causeways, a cone's skirt
const LAKE := 6         # the big lava lake's crust
const MOAT := 7         # its bright hot lava
const CONE := 8         # a volcano's cone
const VENT := 9         # its vent
const MOUNTAIN := 10    # the mountain's slopes
const PEAK := 11        # its flat top

const MAX_STEP := 8
const BASE := 48.0
const SWELL := 3.0
const NONE := Vector2i(0x7fffffff, 0x7fffffff)
const LAYER_EVERY := 6          # a layer of black lava in the rock every this many blocks
const SUB_DEPTH := 3            # the deepest layers under a top block (the lake's hot lava)
# The plains' patches
const PATCH_FREQ := 0.011
const ORANGE_AT := 0.32         # the orange noise over this: orange sulphur
const FROST_AT := 0.38          # the frost noise over this: white frost
# The big lava lake
const LAKE_DISTANCE := Vector2i(170, 230)   # from the middle of the world
const LAKE_R := 28              # the moat's outer edge
const MOAT_W := 2
const RIM_W := 3
const LAKE_DOWN := 3            # the crust this far under the ground round the lake
const MOAT_DEPTH := 5           # the moat's lava this far under the rim's top (a step under the crust)
const CAUSEWAYS := 4
const CAUSEWAY_HALF := 1.6      # a causeway's half-width
const LAKE_FLAT := 40           # flat ground round the rim out to here ...
const LAKE_BLEND := 54          # ... blending back into the plains by here
const LAVA_DEPTH := 3           # hot lava under the crust and the moat
# The volcanoes
const VENT_CELL := 170
const VENT_CHANCE := 60         # of 100 cells
const VENT_MARGIN := 30
const CONE_R := 8.0
const CONE_H := 6
const CRATER_R := 2.6
const HOLE_R := 1.5
const HOLE_DOWN := 3            # the vent this far under the crater's rim
const SKIRT := 2.0              # black lava round the cone's foot
const RING_IN := 11.0
const RING_OUT := 16.0
# The small lava lakes
const PATERA_CELL := 110
const PATERA_CHANCE := 45
const PATERA_MARGIN := 20
const PATERA_R := Vector2i(6, 11)
const PATERA_DOWN := 2
const PATERA_SHORE := 1.6
# The mountain
const MOUNTAIN_DISTANCE := Vector2i(210, 260)
const MOUNT_A := 55.0           # half its length
const MOUNT_B := 36.0           # half its width (the gentle side to the steep side)
const PEAK_H := 40
const RAMP := 1.0               # blocks up per block on the gentle side
const SIDE := 3.0               # ... on the steep sides (a jump each)
const MOUNT_QUIET := 14.0       # no volcano or small lake this near its foot

var _seed := 0
var _lake := Vector2i.ZERO
var _lake_top := 0
var _way0 := 0.0
var _mount := Vector2i.ZERO
var _mount_u := Vector2.RIGHT    # along its length
var _mount_w := Vector2.DOWN     # from the gentle side to the steep side
var _peak := Vector2i.ZERO
var _swell := FastNoiseLite.new()
var _orange := FastNoiseLite.new()
var _frost := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	_seed = world_seed
	var h := absi(_mix(world_seed + 21))
	var la := deg_to_rad(float(h % 360))
	var ld := LAKE_DISTANCE.x + (h >> 9) % (LAKE_DISTANCE.y - LAKE_DISTANCE.x + 1)
	_lake = Vector2i(roundi(cos(la) * ld), roundi(sin(la) * ld))
	var ma := la + deg_to_rad(150.0 + float((h >> 17) % 61))   # the mountain on the far side of the middle
	var md := MOUNTAIN_DISTANCE.x + (h >> 23) % (MOUNTAIN_DISTANCE.y - MOUNTAIN_DISTANCE.x + 1)
	_mount = Vector2i(roundi(cos(ma) * md), roundi(sin(ma) * md))
	var turn := deg_to_rad(float((h >> 5) % 180))
	_mount_u = Vector2.from_angle(turn)
	_mount_w = Vector2(-_mount_u.y, _mount_u.x)
	var peak_w := ((PEAK_H / RAMP - MOUNT_B) + MOUNT_B * (1.0 - PEAK_H / SIDE / MOUNT_B)) / 2.0
	_peak = _mount + Vector2i(roundi(_mount_w.x * peak_w), roundi(_mount_w.y * peak_w))
	_way0 = float((h >> 3) % 628) / 100.0
	_swell.seed = world_seed + 210
	_swell.frequency = 0.004
	_swell.fractal_octaves = 3
	_orange.seed = world_seed + 211
	_orange.frequency = PATCH_FREQ
	_orange.fractal_octaves = 2
	_frost.seed = world_seed + 212
	_frost.frequency = PATCH_FREQ * 1.3
	_frost.fractal_octaves = 2
	_lake_top = plains_height(_lake.x, _lake.y)


## The middle of the big lava lake.
func lake_centre() -> Vector2i:
	return _lake


## The flat ground round the big lava lake (its rim stands one over it, its crust LAKE_DOWN under it).
func lake_top() -> int:
	return _lake_top


## The angle (radians, from +x toward +z) of causeway k across the moat.
func causeway_angle(k: int) -> float:
	return _way0 + TAU * k / CAUSEWAYS


## The middle of the mountain's ellipse.
func mountain_centre() -> Vector2i:
	return _mount


## The middle of the mountain's flat top.
func peak_centre() -> Vector2i:
	return _peak


## The way from the mountain's gentle side to its steep side (a unit vector in (x, z)).
func mountain_up() -> Vector2:
	return _mount_w


## The plains' own height at (x, z) (no volcano, lake or mountain).
func plains_height(x: int, z: int) -> int:
	return roundi(BASE + SWELL * _swell.get_noise_2d(x, z))


## Height * 16 + kind of the column at (x, z) (the landing pad's flattening is SpaceShape's).
func column(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var p := BASE + SWELL * _swell.get_noise_2d(fx, fz)
	var ldx := fx - _lake.x
	var ldz := fz - _lake.y
	var ld2 := ldx * ldx + ldz * ldz
	if ld2 < LAKE_BLEND * LAKE_BLEND:
		var d := sqrt(ld2)
		if d < LAKE_R + RIM_W:
			return _lake_column(ldx, ldz, d)
		p = lerpf(float(_lake_top), p, smoothstep(float(LAKE_FLAT), float(LAKE_BLEND), d))
		return _pack(p, _patch(fx, fz))
	var rise := mountain_rise(fx, fz)
	if rise > 0.0:
		return _pack(p + minf(rise, PEAK_H), PEAK if rise >= PEAK_H else MOUNTAIN)
	var v := vent_in_cell(Vector2i(floori(fx / VENT_CELL), floori(fz / VENT_CELL)))
	if v != NONE:
		var vdx := fx - v.x
		var vdz := fz - v.y
		var vd2 := vdx * vdx + vdz * vdz
		if vd2 < RING_OUT * RING_OUT:
			var vd := sqrt(vd2)
			var base := float(plains_height(v.x, v.y))
			if vd < HOLE_R:
				return _pack(base + CONE_H - HOLE_DOWN, VENT)
			if vd < CRATER_R:
				return _pack(base + CONE_H, CONE)
			if vd < CONE_R:
				return _pack(base + roundf(CONE_H * (CONE_R - vd) / (CONE_R - CRATER_R)), CONE)
			if vd < CONE_R + SKIRT:
				return _pack(lerpf(base, p, 0.5), SHORE)
			return _pack(p, RED_RING if vd >= RING_IN else _patch(fx, fz))
	var pt := patera_in_cell(Vector2i(floori(fx / PATERA_CELL), floori(fz / PATERA_CELL)))
	if pt.z > 0:
		var pdx := fx - pt.x
		var pdz := fz - pt.y
		var pd2 := pdx * pdx + pdz * pdz
		var r := float(pt.z)
		if pd2 < (r + PATERA_SHORE) * (r + PATERA_SHORE):
			var floor_h := float(plains_height(pt.x, pt.y))
			return _pack(floor_h - PATERA_DOWN, PATERA) if pd2 < r * r else _pack(floor_h, SHORE)
	return _pack(p, _patch(fx, fz))


## A plains column's colour: orange sulphur, white frost or yellow sulphur.
func _patch(fx: float, fz: float) -> int:
	if _orange.get_noise_2d(fx, fz) > ORANGE_AT:
		return ORANGE
	if _frost.get_noise_2d(fx, fz) > FROST_AT:
		return FROST
	return PLAINS


## The big lake's column (dx, dz) from its middle, d = its distance (under LAKE_R + RIM_W): a causeway, the crust, the
## moat or the rim.
func _lake_column(dx: float, dz: float, d: float) -> int:
	var crust := _lake_top - LAKE_DOWN
	if d >= LAKE_R - MOAT_W and on_causeway(dx, dz):
		return _pack(crust + clampi(floori(d) - (LAKE_R - MOAT_W), 0, LAKE_DOWN + 1), SHORE)
	if d < LAKE_R - MOAT_W:
		return _pack(crust, LAKE)
	if d < LAKE_R:
		return _pack(crust - 1, MOAT)
	return _pack(_lake_top + 1, SHORE)


## (dx, dz) from the big lake's middle is on one of its causeways.
func on_causeway(dx: float, dz: float) -> bool:
	for k in CAUSEWAYS:
		var dir := Vector2.from_angle(causeway_angle(k))
		if dx * dir.x + dz * dir.y > 0.0 and absf(dx * dir.y - dz * dir.x) <= CAUSEWAY_HALF:
			return true
	return false


## How far the mountain rises over the plains at (fx, fz) (<= 0 off it): up RAMP per block from its gentle side, down
## SIDE per block of the distance inside its edge, at most PEAK_H.
func mountain_rise(fx: float, fz: float) -> float:
	var d := Vector2(fx - _mount.x, fz - _mount.y)
	var u := d.dot(_mount_u) / MOUNT_A
	var w := d.dot(_mount_w)
	var e := sqrt(u * u + (w / MOUNT_B) * (w / MOUNT_B))
	if e >= 1.0:
		return 0.0
	return minf(minf(RAMP * (w + MOUNT_B), SIDE * (1.0 - e) * MOUNT_B), float(PEAK_H))


## (x, z) is near the mountain (on it or within MOUNT_QUIET of its foot).
func near_mountain(fx: float, fz: float, margin: float = MOUNT_QUIET) -> bool:
	var d := Vector2(fx - _mount.x, fz - _mount.y)
	var u := d.dot(_mount_u) / (MOUNT_A + margin)
	var w := d.dot(_mount_w) / (MOUNT_B + margin)
	return u * u + w * w < 1.0


# --- The volcanoes -----------------------------------------------------------------------------------------

## The vent of cell (x, z / VENT_CELL), or NONE: at most one per cell, well inside it, never near the lake or the
## mountain.
func vent_in_cell(cell: Vector2i) -> Vector2i:
	var h := absi(_mix(_mix(cell.x * 7 + 3 + _seed) + cell.y * 13 - 5))
	if h % 100 >= VENT_CHANCE:
		return NONE
	var span := VENT_CELL - 2 * VENT_MARGIN
	var v := Vector2i(cell.x * VENT_CELL + VENT_MARGIN + (h >> 8) % span, cell.y * VENT_CELL + VENT_MARGIN + (h >> 20) % span)
	if Vector2(v - _lake).length() < LAKE_BLEND + RING_OUT + 4.0:
		return NONE
	if near_mountain(float(v.x), float(v.y), MOUNT_QUIET + RING_OUT):
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


# --- The small lava lakes --------------------------------------------------------------------------------------

## The small lava lake of cell (x, z / PATERA_CELL): (centre x, centre z, radius), radius 0 for none. Never near the big
## lake or the mountain, never where a volcano's rings are.
func patera_in_cell(cell: Vector2i) -> Vector3i:
	var h := absi(_mix(_mix(cell.x * 11 - 7 + _seed * 3) + cell.y * 17 + 9))
	if h % 100 >= PATERA_CHANCE:
		return Vector3i.ZERO
	var span := PATERA_CELL - 2 * PATERA_MARGIN
	var c := Vector2i(cell.x * PATERA_CELL + PATERA_MARGIN + (h >> 8) % span,
		cell.y * PATERA_CELL + PATERA_MARGIN + (h >> 18) % span)
	var r := PATERA_R.x + (h >> 26) % (PATERA_R.y - PATERA_R.x + 1)
	var reach := float(r) + PATERA_SHORE
	if Vector2(c - _lake).length() < LAKE_BLEND + reach + 4.0:
		return Vector3i.ZERO
	if near_mountain(float(c.x), float(c.y), MOUNT_QUIET + reach):
		return Vector3i.ZERO
	var near := RING_OUT + reach + 2.0   # the volcanoes' rings win: only the vent cells that near can hold one
	var v0 := Vector2i(floori((c.x - near) / VENT_CELL), floori((c.y - near) / VENT_CELL))
	var v1 := Vector2i(floori((c.x + near) / VENT_CELL), floori((c.y + near) / VENT_CELL))
	for vz in range(v0.y, v1.y + 1):
		for vx in range(v0.x, v1.x + 1):
			var v := vent_in_cell(Vector2i(vx, vz))
			if v != NONE and Vector2(v - c).length() < near:
				return Vector3i.ZERO
	return Vector3i(c.x, c.y, r)


## A small lava lake within `radius` of (x, z) (its shore counts).
func patera_near(x: int, z: int, radius: float) -> bool:
	var c0 := Vector2i(floori((x - radius - 20.0) / PATERA_CELL), floori((z - radius - 20.0) / PATERA_CELL))
	var c1 := Vector2i(floori((x + radius + 20.0) / PATERA_CELL), floori((z + radius + 20.0) / PATERA_CELL))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var pt := patera_in_cell(Vector2i(cx, cz))
			if pt.z > 0 and Vector2(pt.x - x, pt.y - z).length() < radius + pt.z + PATERA_SHORE:
				return true
	return false


# --- A column's blocks ------------------------------------------------------------------------------------

## The block at y (0 <= y < g) of a column of `kind` whose ground is g (the landing pad is SpaceShape's).
static func block(y: int, g: int, kind: int) -> int:
	if y == g - 1:
		return top_block(kind)
	if y >= g - 1 - sub_depth(kind):
		return sub_block(kind)
	return rock_block(y)


## How many layers of a column's own lie under its top block (the rest is rock).
static func sub_depth(kind: int) -> int:
	match kind:
		LAKE, MOAT, CONE, VENT:
			return SUB_DEPTH
		PATERA, SHORE:
			return 1
		MOUNTAIN, PEAK:
			return 0
	return 2


## The top block: sulphur (yellow, orange, frost, red), a lake's crust, hot lava, black lava rock, a vent, the
## mountain's rock and its frosty top.
static func top_block(kind: int) -> int:
	match kind:
		ORANGE:
			return BlockIds.ORANGE_SULPHUR
		FROST, PEAK:
			return BlockIds.SULPHUR_FROST
		RED_RING:
			return BlockIds.RED_SULPHUR
		PATERA, LAKE:
			return BlockIds.LAVA_CRUST
		MOAT:
			return BlockIds.HOT_LAVA
		SHORE, CONE:
			return BlockIds.BLACK_LAVA
		VENT:
			return BlockIds.VOLCANO_VENT
		MOUNTAIN:
			return BlockIds.IO_ROCK
	return BlockIds.SULPHUR


## The layers under the top: hot lava under a lake's crust and its moat, black lava under a cone, a shore and a small
## lake, sulphur under the plains.
static func sub_block(kind: int) -> int:
	match kind:
		LAKE, MOAT:
			return BlockIds.HOT_LAVA
		PATERA, SHORE, CONE, VENT:
			return BlockIds.BLACK_LAVA
	return BlockIds.SULPHUR


## The rock at y >= 0 under the layers: Io's rock with a layer of black lava every LAYER_EVERY blocks.
static func rock_block(y: int) -> int:
	return BlockIds.BLACK_LAVA if posmod(y, LAYER_EVERY) == 0 else BlockIds.IO_ROCK


## A plains kind (sulphur of any colour: where the landing pad and the features may be).
static func is_plains(kind: int) -> bool:
	return kind == PLAINS or kind == ORANGE or kind == FROST


# --- Sights ---------------------------------------------------------------------------------------------

## The sight at a column of packed `c` (column()) at (x, z): &"lake" (a lava lake: the big one's crust, moat, rim and
## causeways, a small one's crust), &"mountain" (its top), &"plume" (a volcano's cone and vent), &"ring" (its red ring),
## or &"".
func sight(x: int, z: int, c: int) -> StringName:
	match c & 15:
		LAKE, MOAT, PATERA:
			return &"lake"
		SHORE:
			if Vector2(x - _lake.x, z - _lake.y).length() < LAKE_R + RIM_W:
				return &"lake"
		PEAK:
			return &"mountain"
		CONE, VENT:
			return &"plume"
		RED_RING:
			return &"ring"
	return &""


static func _pack(h: float, kind: int) -> int:
	return clampi(roundi(h), SpaceShape.MIN_GROUND, SpaceShape.MAX_GROUND) * 16 + kind


static func _mix(v: int) -> int:
	var h := v * 668265263 + 374761393
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
