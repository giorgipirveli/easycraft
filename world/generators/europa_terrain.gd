class_name EuropaTerrain
extends RefCounted
## Europa's regions as pure rules (cosmos, spec §21b.2), for SpaceShape's planet EUROPA: every rule is a function of the
## seed and (x, z) (the ocean well's blocks of y too), read-only after construction (the generator's threads share it).
## North is -z, as on MY MAP.
## - The crust: smooth white ice (Europa is one of the smoothest bodies in the solar system: gentle swells, a step now
##   and then) over blue deep ice with a white band every RING_EVERY blocks, the rocky seafloor under y 0.
## - The lineae: three families of long cracks crossing the ice at different angles (noise lines stretched along each
##   family's direction), each a trough of reddish ice with a ridge of stained ice on either side (Europa's double
##   ridges); they fade out and in again over the ice, and keep away from the other regions.
## - The ice cliffs: a plateau of ice CLIFF * 2 over the plains, two cliffs with a terrace between them, its faces
##   showing the ice's layers; smooth on top.
## - The water plumes: geyser vents here and there (at most one per VENT_CELL cell), each in a low mound crusted with
##   salt; the vent block at the bottom of its hole throws a child up (PadRules).
## - The ocean under the ice: a round well through the crust (WELL_R), open to the sky, a ramp winding down its wall
##   (RAMP_IN..WELL_R) from the rim to a shelf over the water, the ocean at the bottom (SEAFLOOR..OCEAN_TOP) reaching
##   on under the ice (BELL), glowing rings of ice on the wall; a flat rim round it.
## Every step between two columns outside the well is at most MAX_STEP (a jump at 0.13 gravity climbs ~13). column()
## packs a column's height and kind (height * 16 + kind); a well column's height there is the ice's top (the rim),
## well_ground() its real ground and well_block() its blocks, for the generator's fast path and SpaceShape's reference
## alike.

const PLAINS := 0
const LINEA := 1        # a crack's trough of reddish ice
const RIDGE := 2        # the stained ridges beside it
const CLIFFS := 3       # the ice cliffs' terrace (one cliff up)
const CLIFF_TOP := 4    # their plateau (two cliffs up)
const WELL := 5         # the ocean well and the ice over its water (in_well)
const MOUND := 6        # a plume's mound of salt
const VENT := 7         # its vent

const MAX_STEP := 10
const BASE := 52.0
const SWELL := 2.5
const NONE := Vector2i(0x7fffffff, 0x7fffffff)
# The lineae
const LINEA_FREQ := 0.0035
const LINEA_STRETCH := 0.2       # a crack runs this much longer along its family's direction
const LINEA_W := 0.06            # |noise| under this: a crack with its ridges
const TROUGH := 0.35             # ... and under this share of it: the trough
const RIDGE_H := 2.0
const LINEA_MASK := -0.35        # the cracks fade out where the mask noise falls under this
# The ice cliffs
const MESA_DISTANCE := Vector2i(180, 220)   # from the middle of the world
const MESA_RADIUS := 55.0
const MESA_WOBBLE := 10.0
const CLIFF := 8
const TERRACE := 7
const CLIFF_QUIET := 12.0        # no cracks this near the cliffs' foot
# The ocean well
const WELL_DISTANCE := Vector2i(190, 240)
const WELL_R := 11
const RAMP_IN := 6
const BELL := 14                 # the water reaches under the ice out to here
const OCEAN_TOP := 6             # the first air over the water
const SEAFLOOR := -2             # the water's lowest y (the seafloor rock under it)
const RAMP_END := 0.85           # of a turn: the ramp comes down to the shelf here
const WELL_FLAT := 22
const WELL_BLEND := 34
const RING_EVERY := 6
# The water plumes
const VENT_CELL := 160
const VENT_CHANCE := 65          # of 100 cells
const VENT_MARGIN := 24
const MOUND_R := 3.6
const RIM_R := 2.6
const HOLE_R := 1.5
const VENT_CLEAR := 50.0         # vents keep this far from the well's middle
# Ice blades (penitentes)
const FIELD := 0.5               # the blade fields' noise over this

var _seed := 0
var _well := Vector2i.ZERO
var _well_top := 0
var _ramp0 := 0.0
var _mesa := Vector2i.ZERO
var _dirs: Array[Vector2] = []
var _swell := FastNoiseLite.new()
var _lines: Array[FastNoiseLite] = []
var _mask := FastNoiseLite.new()
var _edge := FastNoiseLite.new()
var _field := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	_seed = world_seed
	var h := absi(_mix(world_seed))
	var wa := deg_to_rad(float(h % 360))
	var wd := WELL_DISTANCE.x + (h >> 9) % (WELL_DISTANCE.y - WELL_DISTANCE.x + 1)
	_well = Vector2i(roundi(cos(wa) * wd), roundi(sin(wa) * wd))
	var ma := wa + deg_to_rad(150.0 + float((h >> 17) % 61))   # the cliffs on the far side of the middle
	var md := MESA_DISTANCE.x + (h >> 23) % (MESA_DISTANCE.y - MESA_DISTANCE.x + 1)
	_mesa = Vector2i(roundi(cos(ma) * md), roundi(sin(ma) * md))
	_ramp0 = float((h >> 5) % 628) / 100.0
	var turn := deg_to_rad(float((h >> 29) % 60))
	for i in 3:
		_dirs.append(Vector2.from_angle(turn + i * PI / 3.0))
		var n := FastNoiseLite.new()
		n.seed = world_seed + 201 + i
		n.frequency = LINEA_FREQ
		n.fractal_octaves = 1
		_lines.append(n)
	_swell.seed = world_seed + 200
	_swell.frequency = 0.003
	_swell.fractal_octaves = 3
	_mask.seed = world_seed + 204
	_mask.frequency = 0.002
	_mask.fractal_octaves = 1
	_edge.seed = world_seed + 205
	_edge.frequency = 0.6
	_edge.fractal_octaves = 1
	_field.seed = world_seed + 206
	_field.frequency = 0.01
	_field.fractal_octaves = 1
	_well_top = plains_height(_well.x, _well.y)


## The middle of the ocean well.
func well_centre() -> Vector2i:
	return _well


## The ice's top round the well (its flat rim, where the ramp starts).
func well_top() -> int:
	return _well_top


## The angle (radians, from +x toward +z) where the ramp leaves the rim; it winds down the wall that way round.
func ramp_start() -> float:
	return _ramp0


## The middle of the ice cliffs' plateau.
func mesa_centre() -> Vector2i:
	return _mesa


## The plains' own height at (x, z) (no crack, cliff or well).
func plains_height(x: int, z: int) -> int:
	return roundi(BASE + SWELL * _swell.get_noise_2d(x, z))


## The column (x, z) is the ocean well's: its cavity, its ramp or the ice over its water.
func in_well(x: int, z: int) -> bool:
	return (x - _well.x) * (x - _well.x) + (z - _well.y) * (z - _well.y) <= BELL * BELL


## Height * 16 + kind of the column at (x, z) (the landing pad's flattening is SpaceShape's). A WELL column's height is
## the ice's top there (well_ground: its real ground).
func column(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var p := BASE + SWELL * _swell.get_noise_2d(fx, fz)
	var quiet := 1.0
	var wdx := fx - _well.x
	var wdz := fz - _well.y
	var wd2 := wdx * wdx + wdz * wdz
	if wd2 <= BELL * BELL:
		return _pack(_well_top, WELL)
	if wd2 < WELL_BLEND * WELL_BLEND:   # a flat rim, blending back into the plains
		quiet = smoothstep(float(WELL_FLAT), float(WELL_BLEND), sqrt(wd2))
		p = lerpf(float(_well_top), p, quiet)
	var v := vent_in_cell(Vector2i(floori(fx / VENT_CELL), floori(fz / VENT_CELL)))
	if v != NONE:
		var vdx := fx - v.x
		var vdz := fz - v.y
		var vd2 := vdx * vdx + vdz * vdz
		if vd2 < MOUND_R * MOUND_R:
			var base := float(plains_height(v.x, v.y))
			if vd2 < HOLE_R * HOLE_R:
				return _pack(base, VENT)
			return _pack(base + (2.0 if vd2 < RIM_R * RIM_R else 1.0), MOUND)
		if vd2 < (MOUND_R + 8.0) * (MOUND_R + 8.0):
			quiet = minf(quiet, smoothstep(MOUND_R, MOUND_R + 8.0, sqrt(vd2)))
	var mdx := fx - _mesa.x
	var mdz := fz - _mesa.y
	var reach := MESA_RADIUS + MESA_WOBBLE + CLIFF_QUIET
	if mdx * mdx + mdz * mdz < reach * reach:
		var s := mesa_radius(mdx, mdz) - sqrt(mdx * mdx + mdz * mdz)
		if s >= float(TERRACE):
			return _pack(p + CLIFF * 2, CLIFF_TOP)
		if s >= 0.0:
			return _pack(p + CLIFF, CLIFFS)
		quiet = minf(quiet, smoothstep(0.0, CLIFF_QUIET, -s))
	if quiet > 0.0:
		var t := linea_t(fx, fz, quiet)
		if t < 1.0:
			if t < TROUGH:
				return _pack(p - 1.0, LINEA)
			return _pack(p + RIDGE_H * sin(PI * (t - TROUGH) / (1.0 - TROUGH)), RIDGE)
	return _pack(p, PLAINS)


## How far (x, z) is from the middle of a crack: 0 in it, 1 at its ridges' outer edge, more away from every crack
## (`quiet` 0..1 narrows the cracks near the other regions; the mask fades them out and in over the ice).
func linea_t(fx: float, fz: float, quiet: float = 1.0) -> float:
	var m := smoothstep(LINEA_MASK, LINEA_MASK + 0.2, _mask.get_noise_2d(fx, fz)) * quiet
	if m <= 0.001:
		return INF
	var best := INF
	for i in 3:
		var d := _dirs[i]
		var u := fx * d.x + fz * d.y
		var w := -fx * d.y + fz * d.x
		best = minf(best, absf(_lines[i].get_noise_2d(u * LINEA_STRETCH, w)))
	return best / LINEA_W / m


## The ice cliffs' edge `(dx, dz)` from the plateau's middle is this far from it (a wobbly round edge).
func mesa_radius(dx: float, dz: float) -> float:
	var a := atan2(dz, dx)
	return MESA_RADIUS + MESA_WOBBLE * _edge.get_noise_2d(cos(a) * 3.0, sin(a) * 3.0)


# --- The water plumes -------------------------------------------------------------------------------------

## The vent of cell (x, z / VENT_CELL), or NONE: at most one per cell, well inside it, never near the well or the cliffs.
func vent_in_cell(cell: Vector2i) -> Vector2i:
	var h := absi(_mix(_mix(cell.x * 7 + 3 + _seed) + cell.y * 13 - 5))
	if h % 100 >= VENT_CHANCE:
		return NONE
	var span := VENT_CELL - 2 * VENT_MARGIN
	var v := Vector2i(cell.x * VENT_CELL + VENT_MARGIN + (h >> 8) % span, cell.y * VENT_CELL + VENT_MARGIN + (h >> 20) % span)
	if Vector2(v - _well).length() < VENT_CLEAR:
		return NONE
	if Vector2(v - _mesa).length() < MESA_RADIUS + MESA_WOBBLE + CLIFF_QUIET + 8.0:
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


# --- The ocean well ---------------------------------------------------------------------------------------

## The real ground of a WELL column at (x, z) whose ice top is `top`: the seafloor in the open middle, the ramp's top
## on the wall, the ice over the water beyond.
func well_ground(x: int, z: int, top: int) -> int:
	var r2 := (x - _well.x) * (x - _well.x) + (z - _well.y) * (z - _well.y)
	if r2 <= RAMP_IN * RAMP_IN:
		return SEAFLOOR
	if r2 <= WELL_R * WELL_R:
		return ramp_top(x, z)
	return top


## The ramp's top at (x, z) (a ramp column): the rim at its start, down round the wall to the shelf over the water.
func ramp_top(x: int, z: int) -> int:
	var a := fposmod(atan2(float(z - _well.y), float(x - _well.x)) - _ramp0, TAU) / TAU
	if a >= RAMP_END:
		return OCEAN_TOP + 1
	return _well_top - roundi(float(_well_top - OCEAN_TOP - 1) * a / RAMP_END)


## The well's block at (x, y, z) of a WELL column whose ice top is `top`, or -1 where the column's own layers stand:
## the water from SEAFLOOR to OCEAN_TOP, air over the open middle, the ramp (glowing at its inner edge), the glowing
## rings on the wall.
func well_block(x: int, y: int, z: int, top: int) -> int:
	if y >= top or y < SEAFLOOR:
		return -1
	if y < OCEAN_TOP:
		return BlockIds.WATER
	var r2 := (x - _well.x) * (x - _well.x) + (z - _well.y) * (z - _well.y)
	if r2 <= RAMP_IN * RAMP_IN:
		return BlockIds.AIR
	if r2 <= WELL_R * WELL_R:
		var rt := ramp_top(x, z)
		if y >= rt:
			return BlockIds.AIR
		if y == rt - 1:
			return BlockIds.GLOW_ICE if r2 <= (RAMP_IN + 1) * (RAMP_IN + 1) else BlockIds.EUROPA_ICE
		return BlockIds.EUROPA_ICE if y == rt - 2 else BlockIds.DEEP_ICE
	if r2 <= (WELL_R + 1) * (WELL_R + 1) and y < top - 2 and posmod(y - OCEAN_TOP, RING_EVERY) == RING_EVERY / 2:
		return BlockIds.GLOW_ICE
	return -1


## The ice's top and bottom of the well's cavity: [lo (x, SEAFLOOR, z), hi exclusive].
func well_box() -> Array[Vector3i]:
	return [Vector3i(_well.x - BELL, SEAFLOOR, _well.y - BELL), Vector3i(_well.x + BELL + 1, _well_top, _well.y + BELL + 1)]


# --- A column's blocks ------------------------------------------------------------------------------------

## The block at y (0 <= y < g) of a column of `kind` whose ground is g (the landing pad and the well are SpaceShape's).
static func block(y: int, g: int, kind: int) -> int:
	if y == g - 1:
		return top_block(kind)
	if y >= g - 1 - SUB_DEPTH:
		return sub_block(kind, y, g)
	return rock_block(y)


const SUB_DEPTH := 2


## The top block: white ice, a crack's reddish ice, its ridges' stained ice, a mound's salt, a vent.
static func top_block(kind: int) -> int:
	match kind:
		LINEA:
			return BlockIds.LINEA_ICE
		RIDGE:
			return BlockIds.BAND_ICE
		MOUND:
			return BlockIds.SALT
		VENT:
			return BlockIds.GEYSER_VENT
	return BlockIds.EUROPA_ICE


## A layer under the top: white ice (a crack's stain goes one block down).
static func sub_block(kind: int, y: int, g: int) -> int:
	return BlockIds.BAND_ICE if kind == LINEA and y == g - 2 else BlockIds.EUROPA_ICE


## The ice at y >= 0 under the top layers: blue deep ice with a white band every RING_EVERY blocks.
static func rock_block(y: int) -> int:
	return BlockIds.EUROPA_ICE if posmod(y, RING_EVERY) == 0 else BlockIds.DEEP_ICE


## A column no crack or region touches: the landing pad's place.
func calm(x: int, z: int) -> bool:
	return linea_t(float(x), float(z)) >= 1.5


## (x, z) is in a field of ice blades (penitentes).
func blade_field(x: int, z: int) -> bool:
	return _field.get_noise_2d(x, z) > FIELD


# --- Sights ---------------------------------------------------------------------------------------------

## The sight at a column of packed `c` (column()) at (x, z): &"ocean" (the water at the bottom of the well: its open
## middle and the shelf), &"cliffs" (their plateau), &"plume" (a vent and its mound), &"linea" (a crack), or &"".
func sight(x: int, z: int, c: int) -> StringName:
	match c & 15:
		WELL:
			var r2 := (x - _well.x) * (x - _well.x) + (z - _well.y) * (z - _well.y)
			if r2 <= RAMP_IN * RAMP_IN or (r2 <= WELL_R * WELL_R and ramp_top(x, z) <= OCEAN_TOP + 1):
				return &"ocean"
		CLIFF_TOP:
			return &"cliffs"
		MOUND, VENT:
			return &"plume"
		LINEA:
			return &"linea"
	return &""


static func _pack(h: float, kind: int) -> int:
	return clampi(roundi(h), SpaceShape.MIN_GROUND, SpaceShape.MAX_GROUND) * 16 + kind


static func _mix(v: int) -> int:
	var h := v * 668265263 + 374761393
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
