class_name VenusTerrain
extends RefCounted
## Venus's cloud city as pure rules (cosmos, spec §21b.2), for SpaceShape's planet VENUS. About 50 km above Venus's
## hot ground the air presses like Earth's and a balloon full of the air we breathe floats: scientists have imagined
## airships and floating cities there. The world is that city, over the yellow clouds.
## - The clouds: yellow cloud tops (CLOUD_LOW-CLOUD_HIGH, soft puffs from noise) over deeper clouds down to the bedrock,
##   everywhere, far below the city. A child never reaches them: feet below LIFT_Y and a warm breeze lifts the child back
##   to the city (the descriptor's void line, DragonRules), so the acid clouds are a fact to learn, never a place to fall.
## - The platforms: round decks all at DECK_Y (the first empty y over every deck and bridge, so every walk between them is
##   level), each over a round silvery float hull (HULL_EDGE thick at its rim, deeper toward its middle), a white frame
##   ring at the rim. The landing deck round the spawn (the landing pad; the cloud scope at its rim, facing the open side,
##   a sight); the city's ring round it: the airship dock (its mooring mast, a sight; the Research Blimp, the world's
##   landmark, moored beyond it: SpaceSecretRules), the aliens' camp deck, the show deck (the Theater's), the cloud homes
##   (four little domed homes round a square, a sight), the sky garden (a pond with a lamp fountain, turf, flowers and
##   trees from Earth, a sight), the west lookout (a telescope facing west, where the Sun rises on Venus: a sight) and
##   the orchard; an outer ring of groves and plazas (RING2) and, far out, isles in a grid of ISLE_CELL cells.
## - The bridges: 3 wide, honey planks on a white keel, between the landing deck and the ring, round the ring, out to the
##   outer ring, to the nearest isles and between neighbouring isles; lamp posts along their edges.
## North is -z, as on MY MAP. `flip` (from the seed) mirrors the city north-south (the lookout stays west). Every rule is a
## function of the seed and (x, z) (y for the city's built parts), read-only after construction (the generator's threads
## share it). columns() does a block of columns at once (the generator's path) and equals column().

const CLOUD := 0        # no platform: the yellow clouds far below
const DECK := 1         # a platform's cream deck
const GARDEN := 2       # a garden's turf
const RIM := 3          # a platform's white rim
const BRIDGE := 4       # a bridge's planks

## Platform roles.
const LANDING := &"landing"
const DOCK := &"dock"
const CAMP := &"camp"
const SHOW := &"show"
const HOMES := &"homes"
const GARDEN_DECK := &"garden"
const LOOKOUT := &"lookout"
const ORCHARD := &"orchard"
const GROVE := &"grove"
const PLAZA := &"plaza"

const DECK_Y := 80              # the decks' top: the first empty y over every deck and bridge
const LIFT_Y := 56.0            # feet under this: the warm breeze lifts the child back to the city
const CLOUD_BASE := 34.0
const CLOUD_SWELL := 4.0
const CLOUD_PUFF := 2.5
const CLOUD_LOW := 28
const CLOUD_HIGH := 42          # no cloud top reaches this (the lift line stays far above them)
const HULL_EDGE := 2            # a hull's thickness at its rim ...
const HULL_DEEP := 0.8          # ... and this × the radius more at its middle
const BRIDGE_HALF := 1.5        # a bridge's columns: this far from its line (3 wide)
const LANDING_R := 20
const NONE := Vector2i(0x7fffffff, 0x7fffffff)
## The spawn (the landing pad's middle): the dock's side north (or south, flipped); both keep the Research Blimp inside
## one secrets area (SecretRules.AREA).
const SPAWN := Vector2i(40, 88)
const SPAWN_FLIPPED := Vector2i(40, 40)
## The city's ring: [role, x, z (north: -z), radius] round the spawn.
const RING := [[DOCK, 0, -46, 11], [CAMP, 30, -30, 12], [SHOW, 42, 0, 12], [HOMES, 34, 34, 14],
	[GARDEN_DECK, -34, 34, 14], [LOOKOUT, -46, 0, 11], [ORCHARD, -32, -32, 12]]
## The promenade's bridges between ring neighbours (indexes into RING; the south stays open).
const CHORDS := [[0, 1], [1, 2], [2, 3], [4, 5], [5, 6], [6, 0]]
const RING2_D := Vector2i(94, 106)
const RING2_R := Vector2i(10, 14)
const RING2_TURN := 4.0         # degrees each outer platform may turn from its place
const ISLE_CELL := 96
const ISLE_CHANCE := 60         # of 100 cells
const ISLE_MARGIN := 20         # an isle's middle is at least this far inside its cell
const ISLE_R := Vector2i(9, 14)
const ISLE_FROM := 175.0        # no isle nearer the spawn (the outer ring and its bridges stay clear)
const ISLE_LINK := 130.0        # an outer platform's bridge to its nearest isle, at most this long
## No isle, nor a bridge between two isles, comes nearer the spawn than this (isles from ISLE_FROM less ISLE_R; a bridge
## between neighbouring isles dips at most ~20 nearer than its ends).
const ISLE_NEAR := 140.0
## Features (the city's "trees"): lamp posts on rims and along bridges, flowers and little trees in the gardens.
const LAMP_PER_MILLE := 60      # of a rim's columns
const LAMP_EVERY := 8           # blocks along a bridge between two lamps (sides taking turns)
const FLOWER_PER_MILLE := 70    # of a garden's turf
const TREE_PER_MILLE := 12
const LAMP_H := 3               # two blocks of post, the lamp
const TREE_H := 4               # two blocks of trunk, a crown two high
const FEATURE_LOOK := 6         # a feature looks this far round its column (a bridge's end, a platform's edge)
const NO_FEATURE := 0
const LAMP := 1
const FLOWER := 2
const TREE := 3
## Sights: standing this close (either way) to a sight's spot finds it; the garden's is its pond's ring.
const SIGHT_REACH := 2
const GARDEN_REACH := 3
const SCOPE_OUT := 19           # the cloud scope: this far from the pad's middle, its tube over the rim
const MAST_OUT := 7             # the dock's mooring mast: this far out from the dock's middle ...
const MAST_SIDE := 4            # ... and this far to the east
const MAST_H := 11
const HOME_STEP := 5            # the homes round their square: this far east-west and north-south of its middle
const LOOKOUT_OUT := 8          # the west lookout's telescope: this far west of the lookout deck's middle
const HOME_COLORS: Array[int] = [BlockIds.PAINTED_TEAL, BlockIds.PAINTED_PINK, BlockIds.PAINTED_SKY,
	BlockIds.PAINTED_YELLOW]
const CHUNK := 16
const GRID := 32                # the city's platforms and bridges are looked up by GRID × GRID buckets
const STRIDE := 7               # a built part's box in _boxes: lo.x, lo.y, lo.z, hi.x, hi.y, hi.z, id

var flip := false
var _seed := 0
var _spawn := SPAWN
var _north := Vector2i(0, -1)   # toward the dock (south when flipped)
## Every platform of the landing deck, the ring and the outer ring: [role, cx, cz, r] (isles are drawn per cell).
var _plats: Array = []
## Every bridge of the city but the isles' own: [ax, az, bx, bz].
var _bridges: Array = []
var _roles := {}                # role -> its platform (the landing deck and the ring's)
var _sights: Array = []         # [[id, spot], ...]
var _boxes := PackedInt32Array()   # the city's built parts: lo.x, lo.y, lo.z, hi.x, hi.y, hi.z, id (later ones win)
var _index := {}                # chunk (16 cubed) -> PackedInt32Array of box indexes
var _keep: Array = []           # [cx, cz, r]: spots the features and the secrets keep clear of (the built parts)
var _cloud := FastNoiseLite.new()
var _puff := FastNoiseLite.new()
var _plat_grid := {}            # bucket -> PackedInt32Array of _plats' indexes whose box reaches into it
var _bridge_grid := {}          # bucket -> PackedInt32Array of _bridges' indexes


func _init(world_seed: int) -> void:
	_seed = world_seed
	flip = absi(_mix(world_seed + 24)) % 2 == 1
	_spawn = SPAWN_FLIPPED if flip else SPAWN
	_north = Vector2i(0, 1 if flip else -1)
	_cloud.seed = world_seed + 240
	_cloud.frequency = 0.018
	_cloud.fractal_octaves = 3
	_puff.seed = world_seed + 241
	_puff.frequency = 0.08
	_make_city()
	_make_grid()
	_make_built()
	_make_index()


# --- The layout ------------------------------------------------------------------------------------------------------

func spawn() -> Vector2i:
	return _spawn


## The platform of `role` (the landing deck or one of the ring's): [role, cx, cz, r], [] for none.
func platform(role: StringName) -> Array:
	return _roles.get(role, [])


## The middle of `role`'s platform (NONE for none).
func centre(role: StringName) -> Vector2i:
	var p: Array = platform(role)
	return Vector2i(p[1], p[2]) if not p.is_empty() else NONE


## The way from the spawn to the dock (north, or south when flipped).
func north() -> Vector2i:
	return _north


## Every platform but the isles: [[role, cx, cz, r], ...].
func platforms() -> Array:
	return _plats


## Every bridge but the isles' own: [[ax, az, bx, bz], ...].
func bridges() -> Array:
	return _bridges


func _make_city() -> void:
	var s := _spawn
	_add_plat(LANDING, s.x, s.y, LANDING_R)
	var sz := -1 if flip else 1
	for e: Array in RING:
		_add_plat(e[0], s.x + int(e[1]), s.y + int(e[2]) * sz, int(e[3]))
	var land: Array = _plats[0]
	for i in RING.size():
		_add_bridge(land, _plats[i + 1])
	for c: Array in CHORDS:
		_add_bridge(_plats[int(c[0]) + 1], _plats[int(c[1]) + 1])
	var outer: Array = []
	for k in 8:
		var h := absi(_mix(_seed * 31 + k * 7919))
		var a := deg_to_rad(22.5 + 45.0 * k + (float(h % 81) / 10.0 - RING2_TURN))
		var d := RING2_D.x + (h >> 8) % (RING2_D.y - RING2_D.x + 1)
		var r := RING2_R.x + (h >> 16) % (RING2_R.y - RING2_R.x + 1)
		var p := [GROVE if k % 2 == 0 else PLAZA, s.x + roundi(cos(a) * d), s.y + roundi(sin(a) * d), r]
		_plats.append(p)
		outer.append(p)
	for k in 8:   # each to its nearest ring platform (never the dock: the blimp's side stays clear; nor the lookout)
		var best: Array = []
		var best_d := INF
		for i in RING.size():
			var q: Array = _plats[i + 1]
			if q[0] == DOCK or q[0] == LOOKOUT:
				continue
			var dd := Vector2(q[1] - outer[k][1], q[2] - outer[k][2]).length()
			if dd < best_d:
				best_d = dd
				best = q
		_add_bridge(outer[k], best)
		_add_bridge(outer[k], outer[(k + 1) % 8])
		var isle := _nearest_isle(Vector2i(outer[k][1], outer[k][2]))
		if not isle.is_empty():
			_add_bridge(outer[k], isle)


## The buckets of the platforms' and the bridges' boxes (_near looks up only the buckets its box reaches into).
func _make_grid() -> void:
	for i in _plats.size():
		var p: Array = _plats[i]
		_bucket(_plat_grid, i, int(p[1]) - int(p[3]), int(p[2]) - int(p[3]), int(p[1]) + int(p[3]), int(p[2]) + int(p[3]))
	var m := ceili(BRIDGE_HALF)
	for i in _bridges.size():
		var b: Array = _bridges[i]
		_bucket(_bridge_grid, i, mini(b[0], b[2]) - m, mini(b[1], b[3]) - m, maxi(b[0], b[2]) + m, maxi(b[1], b[3]) + m)


static func _bucket(grid: Dictionary, i: int, x0: int, z0: int, x1: int, z1: int) -> void:
	for bz in range(floori(z0 / float(GRID)), floori(z1 / float(GRID)) + 1):
		for bx in range(floori(x0 / float(GRID)), floori(x1 / float(GRID)) + 1):
			var key := Vector2i(bx, bz)
			var list: PackedInt32Array = grid.get(key, PackedInt32Array())
			list.append(i)
			grid[key] = list


## The indexes in `grid`'s buckets under the box (each once, in the order they were added).
static func _in_buckets(grid: Dictionary, x0: int, z0: int, x1: int, z1: int) -> PackedInt32Array:
	var b0 := Vector2i(floori(x0 / float(GRID)), floori(z0 / float(GRID)))
	var b1 := Vector2i(floori(x1 / float(GRID)), floori(z1 / float(GRID)))
	if b0 == b1:
		return grid.get(b0, PackedInt32Array())
	var seen := {}
	for bz in range(b0.y, b1.y + 1):
		for bx in range(b0.x, b1.x + 1):
			for i: int in (grid.get(Vector2i(bx, bz), PackedInt32Array()) as PackedInt32Array):
				seen[i] = true
	var out := PackedInt32Array(seen.keys())
	out.sort()
	return out


func _add_plat(role: StringName, x: int, z: int, r: int) -> void:
	var p := [role, x, z, r]
	_plats.append(p)
	if not _roles.has(role):
		_roles[role] = p


func _add_bridge(a: Array, b: Array) -> void:
	_bridges.append([int(a[1]), int(a[2]), int(b[1]), int(b[2])])


## The isle of cell (cx, cz): [role, x, z, r], or [] (none there).
func isle(cell: Vector2i) -> Array:
	var h := absi(_mix(cell.x * 73856093 ^ cell.y * 19349663 ^ (_seed + 245)))
	if h % 100 >= ISLE_CHANCE:
		return []
	var span := ISLE_CELL - 2 * ISLE_MARGIN
	var x := cell.x * ISLE_CELL + ISLE_MARGIN + (h >> 7) % span
	var z := cell.y * ISLE_CELL + ISLE_MARGIN + (h >> 14) % span
	if Vector2(x - _spawn.x, z - _spawn.y).length() < ISLE_FROM:
		return []
	return [GROVE if (h >> 21) % 5 < 2 else PLAZA, x, z, ISLE_R.x + (h >> 24) % (ISLE_R.y - ISLE_R.x + 1)]


func _nearest_isle(at: Vector2i) -> Array:
	var best: Array = []
	var best_d := ISLE_LINK
	var c := Vector2i(floori(at.x / float(ISLE_CELL)), floori(at.y / float(ISLE_CELL)))
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var i := isle(c + Vector2i(dx, dz))
			if i.is_empty():
				continue
			var d := Vector2(i[1] - at.x, i[2] - at.y).length()
			if d < best_d:
				best_d = d
				best = i
	return best


# --- Columns ---------------------------------------------------------------------------------------------------------

## The cloud top at (x, z): the first empty y over the clouds.
func cloud_top(x: int, z: int) -> int:
	var fx := float(x)
	var fz := float(z)
	var v := CLOUD_BASE + CLOUD_SWELL * _cloud.get_noise_2d(fx, fz) + CLOUD_PUFF * _puff.get_noise_2d(fx, fz)
	return clampi(roundi(v), CLOUD_LOW, CLOUD_HIGH - 1)


## [kind, top, bottom, cloud] of the column at (x, z): its kind (CLOUD, DECK, …), the first empty y over it, the lowest
## block of its platform or bridge (the cloud top when there is none), and its cloud top.
func column(x: int, z: int) -> PackedInt32Array:
	var near := _near(x, z, x, z)
	return _column(x, z, near[0], near[1])


## [tops, kinds, bottoms, clouds] of sx × sz columns from (x0, z0) (index x + z * sx), exactly column()'s, the
## platforms and bridges near the block gathered once (the generator's path).
func columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var near := _near(x0, z0, x0 + sx - 1, z0 + sz - 1)
	var tops := PackedInt32Array()
	tops.resize(sx * sz)
	var kinds := PackedByteArray()
	kinds.resize(sx * sz)
	var bottoms := PackedInt32Array()
	bottoms.resize(sx * sz)
	var clouds := PackedInt32Array()
	clouds.resize(sx * sz)
	for z in sz:
		for x in sx:
			var c := _column(x0 + x, z0 + z, near[0], near[1])
			var i := x + z * sx
			kinds[i] = c[0]
			tops[i] = c[1]
			bottoms[i] = c[2]
			clouds[i] = c[3]
	return [tops, kinds, bottoms, clouds]


## The first empty y over the column at (x, z): a deck's or a bridge's, else its clouds' top (cheaper than column()).
func top_at(x: int, z: int) -> int:
	var near := _near(x, z, x, z)
	return DECK_Y if _built(x, z, near[0], near[1])[0] != CLOUD else cloud_top(x, z)


## The kind of the column at (x, z) (without its clouds' top: cheaper than column()).
func kind_at(x: int, z: int) -> int:
	var near := _near(x, z, x, z)
	return _built(x, z, near[0], near[1])[0]


## The platform holding the column (x, z) ([role, cx, cz, r]; [] on a bridge or over the clouds).
func platform_at(x: int, z: int) -> Array:
	var near := _near(x, z, x, z)
	for p: Array in near[0]:
		if _inside(p, x, z):
			return p
	return []


func _column(x: int, z: int, plats: Array, bridges: Array) -> PackedInt32Array:
	var cloud := cloud_top(x, z)
	var c := _built(x, z, plats, bridges)
	if c[0] == CLOUD:
		return PackedInt32Array([CLOUD, cloud, cloud, cloud])
	c.append(cloud)
	return c


## [kind, top, bottom] of a platform's or a bridge's column at (x, z) ([CLOUD, 0, 0] over the clouds: its clouds are
## column()'s).
func _built(x: int, z: int, plats: Array, bridges: Array) -> PackedInt32Array:
	for p: Array in plats:
		var dx := float(x - int(p[1]))
		var dz := float(z - int(p[2]))
		var r := float(p[3])
		var d2 := dx * dx + dz * dz
		if d2 > r * r:
			continue
		var d := sqrt(d2)
		var depth := HULL_EDGE + floori(HULL_DEEP * r * sqrt(maxf(1.0 - d2 / (r * r), 0.0)))
		var kind := RIM if d > r - 1.0 else (GARDEN if _turfed(p[0]) else DECK)
		return PackedInt32Array([kind, DECK_Y, DECK_Y - 1 - depth])
	var line := INF   # the nearest bridge's line (where bridges cross, its keel whichever bridge it is)
	for b: Array in bridges:
		line = minf(line, _along(b, x, z).y)
	if line <= BRIDGE_HALF:
		return PackedInt32Array([BRIDGE, DECK_Y, DECK_Y - 2 if line <= 0.5 else DECK_Y - 1])
	return PackedInt32Array([CLOUD, 0, 0])


static func _turfed(role: StringName) -> bool:
	return role == GARDEN_DECK or role == ORCHARD or role == GROVE


static func _inside(p: Array, x: int, z: int) -> bool:
	var dx := x - int(p[1])
	var dz := z - int(p[2])
	return dx * dx + dz * dz <= int(p[3]) * int(p[3])


## (how far along bridge b the column (x, z) is, from its start; how far from its line), INF off its ends.
static func _along(b: Array, x: int, z: int) -> Vector2:
	var a := Vector2(b[0], b[1])
	var e := Vector2(b[2], b[3])
	var ab := e - a
	var len2 := ab.length_squared()
	if len2 <= 0.0:
		return Vector2(INF, INF)
	var p := Vector2(x, z)
	var t := (p - a).dot(ab) / len2
	if t < 0.0 or t > 1.0:
		return Vector2(INF, INF)
	return Vector2(t * sqrt(len2), (a + ab * t).distance_to(p))


## [platforms, bridges] that may touch the columns x0..x1, z0..z1 (the landing deck, the rings, the isles of the cells
## round them and their bridges).
func _near(x0: int, z0: int, x1: int, z1: int) -> Array:
	var plats: Array = []
	for k: int in _in_buckets(_plat_grid, x0, z0, x1, z1):
		var p: Array = _plats[k]
		if _box_near(x0, z0, x1, z1, int(p[1]) - int(p[3]), int(p[2]) - int(p[3]), int(p[1]) + int(p[3]),
				int(p[2]) + int(p[3])):
			plats.append(p)
	var bridges: Array = []
	for k: int in _in_buckets(_bridge_grid, x0, z0, x1, z1):
		var b: Array = _bridges[k]
		if _bridge_near(b, x0, z0, x1, z1):
			bridges.append(b)
	var far := maxf(maxf(absf(x0 - _spawn.x), absf(x1 - _spawn.x)), maxf(absf(z0 - _spawn.y), absf(z1 - _spawn.y)))
	if far * sqrt(2.0) < ISLE_NEAR:
		return [plats, bridges]   # the city's middle: no isle and no isle's bridge comes this near
	# An isle stays inside its cell, and a bridge between two neighbouring isles inside their two cells: only the isles of
	# the box's cells, and the bridges with an end in one of them, can touch it.
	var c0 := Vector2i(floori(x0 / float(ISLE_CELL)), floori(z0 / float(ISLE_CELL)))
	var c1 := Vector2i(floori(x1 / float(ISLE_CELL)), floori(z1 / float(ISLE_CELL)))
	var got := {}
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var i := _isle_of(got, Vector2i(cx, cz))
			if not i.is_empty():
				plats.append(i)
	for cz in range(c0.y, c1.y + 1):   # the bridges east
		for cx in range(c0.x - 1, c1.x + 1):
			_isle_bridge(got, Vector2i(cx, cz), Vector2i(cx + 1, cz), x0, z0, x1, z1, bridges)
	for cz in range(c0.y - 1, c1.y + 1):   # the bridges south
		for cx in range(c0.x, c1.x + 1):
			_isle_bridge(got, Vector2i(cx, cz), Vector2i(cx, cz + 1), x0, z0, x1, z1, bridges)
	return [plats, bridges]


## isle(c), drawn once per look (`got`: cell -> its isle).
func _isle_of(got: Dictionary, c: Vector2i) -> Array:
	var i: Variant = got.get(c)
	if i == null:
		i = isle(c)
		got[c] = i
	return i


## The bridge between the isles of cells a and b (when both have one) into `bridges`, when it may touch the box.
func _isle_bridge(got: Dictionary, a: Vector2i, b: Vector2i, x0: int, z0: int, x1: int, z1: int, bridges: Array) -> void:
	var i := _isle_of(got, a)
	if i.is_empty():
		return
	var j := _isle_of(got, b)
	if j.is_empty():
		return
	var br := [int(i[1]), int(i[2]), int(j[1]), int(j[2])]
	if _bridge_near(br, x0, z0, x1, z1):
		bridges.append(br)


static func _box_near(x0: int, z0: int, x1: int, z1: int, lx: int, lz: int, hx: int, hz: int) -> bool:
	return lx <= x1 and hx >= x0 and lz <= z1 and hz >= z0


static func _bridge_near(b: Array, x0: int, z0: int, x1: int, z1: int) -> bool:
	var m := ceili(BRIDGE_HALF)
	return _box_near(x0, z0, x1, z1, mini(b[0], b[2]) - m, mini(b[1], b[3]) - m, maxi(b[0], b[2]) + m,
		maxi(b[1], b[3]) + m)


## The top block of a column of `kind` (the landing pad is SpaceShape's).
static func top_block(kind: int) -> int:
	match kind:
		GARDEN:
			return BlockIds.SKY_TURF
		RIM:
			return BlockIds.SKY_FRAME
		BRIDGE:
			return BlockIds.SKY_BRIDGE
	return BlockIds.CLOUD_DECK


## The block of a platform's or a bridge's column of `kind` under its top (from `bottom` up): a bridge's keel, a hull.
static func under_block(kind: int) -> int:
	return BlockIds.SKY_FRAME if kind == BRIDGE else BlockIds.FLOAT_HULL


## The block at height y of a column [kind, top, bottom, cloud] (no built parts, no features, no pad).
static func block(y: int, c: PackedInt32Array) -> int:
	if c[0] != CLOUD and y >= c[2] and y < c[1]:
		return top_block(c[0]) if y == c[1] - 1 else under_block(c[0])
	if y < c[3]:
		return BlockIds.VENUS_CLOUD if y == c[3] - 1 else BlockIds.DEEP_CLOUD
	return BlockIds.AIR


# --- Features --------------------------------------------------------------------------------------------------------

## The feature standing on column (x, z): NO_FEATURE, LAMP, FLOWER or TREE (only on platforms and bridges; never on the
## camp and show decks, on the dock, round the built parts or at a bridge's ends).
func feature_at(x: int, z: int) -> int:
	return _feature(x, z, _near(x - FEATURE_LOOK, z - FEATURE_LOOK, x + FEATURE_LOOK, z + FEATURE_LOOK))


## [tx, tz, feature, ...] of every feature on the sx × sz columns from (x0, z0) in (z, x) order, exactly feature_at's,
## the platforms and bridges near them gathered once (the generator's path). `spawn_clear`: none within it of the spawn.
func features(x0: int, z0: int, sx: int, sz: int, spawn_clear: int) -> PackedInt32Array:
	var near := _near(x0 - FEATURE_LOOK, z0 - FEATURE_LOOK, x0 + sx - 1 + FEATURE_LOOK, z0 + sz - 1 + FEATURE_LOOK)
	var out := PackedInt32Array()
	if near[0].is_empty() and near[1].is_empty():
		return out
	for z in range(z0, z0 + sz):
		for x in range(x0, x0 + sx):
			if (x - _spawn.x) * (x - _spawn.x) + (z - _spawn.y) * (z - _spawn.y) <= spawn_clear * spawn_clear:
				continue
			var f := _feature(x, z, near)
			if f != NO_FEATURE:
				out.append_array([x, z, f])
	return out


func _feature(x: int, z: int, near: Array) -> int:
	var c := _built(x, z, near[0], near[1])
	if c[0] == CLOUD:
		return NO_FEATURE
	var roll := absi(_mix(x * 3 + 17 ^ z * 5 - 29 ^ _seed)) % 1000
	if c[0] == BRIDGE:
		for b: Array in near[1]:
			var t := _along(b, x, z)
			if t.y > 0.75 and t.y <= BRIDGE_HALF and posmod(floori(t.x), LAMP_EVERY) == LAMP_EVERY / 2:
				var side := signf((b[2] - b[0]) * (z - b[1]) - (b[3] - b[1]) * (x - b[0]))
				if (side > 0.0) == (posmod(floori(t.x / LAMP_EVERY), 2) == 0) and not _by_platform(x, z, near[0], 2):
					return LAMP
		return NO_FEATURE
	var p: Array = []
	for q: Array in near[0]:
		if _inside(q, x, z):
			p = q
			break
	if p.is_empty() or p[0] == CAMP or p[0] == SHOW or p[0] == DOCK or _kept(x, z, 1):
		return NO_FEATURE
	if c[0] == RIM:
		return LAMP if roll < LAMP_PER_MILLE and not _by_bridge(x, z, near[1], 3) else NO_FEATURE
	if c[0] != GARDEN:
		return NO_FEATURE
	var d := Vector2(x - int(p[1]), z - int(p[2])).length()
	if roll < TREE_PER_MILLE and d <= float(p[3]) - 3.0 and not _kept(x, z, 3):
		return TREE
	return FLOWER if roll >= TREE_PER_MILLE and roll < TREE_PER_MILLE + FLOWER_PER_MILLE else NO_FEATURE


## The column is within `m` of a bridge's line (a bridge's end on a rim: no lamp in the way).
static func _by_bridge(x: int, z: int, bridges: Array, m: int) -> bool:
	for b: Array in bridges:
		var t := _along(b, x, z)
		if t.y <= BRIDGE_HALF + m:
			return true
	return false


## The column is within `m` of a platform (a bridge's end: no lamp in the way).
static func _by_platform(x: int, z: int, plats: Array, m: int) -> bool:
	for p: Array in plats:
		var r := int(p[3]) + m
		var dx := x - int(p[1])
		var dz := z - int(p[2])
		if dx * dx + dz * dz <= r * r:
			return true
	return false


## The column is within `margin` of one of the city's built parts (their ground: the keep list).
func _kept(x: int, z: int, margin: int) -> bool:
	for k: Array in _keep:
		var r := float(k[2]) + margin
		if Vector2(x - int(k[0]), z - int(k[1])).length_squared() <= r * r:
			return true
	return false


## How tall the feature on (x, z) is.
static func feature_height(f: int) -> int:
	match f:
		LAMP:
			return LAMP_H
		TREE:
			return TREE_H
		FLOWER:
			return 1
	return 0


## The block the feature `f` standing on column (tx, tz) (its ground `base`: the first empty y) puts at p, or -1.
static func feature_block(f: int, tx: int, tz: int, base: int, p: Vector3i) -> int:
	var dx := p.x - tx
	var dz := p.z - tz
	var up := p.y - base
	match f:
		LAMP:
			if dx == 0 and dz == 0 and up >= 0 and up < LAMP_H:
				return BlockIds.CLOUD_LAMP if up == LAMP_H - 1 else BlockIds.SKY_FRAME
		FLOWER:
			if dx == 0 and dz == 0 and up == 0:
				return BlockIds.FLOWERS
		TREE:
			if dx == 0 and dz == 0 and up >= 0 and up < 2:
				return BlockIds.LOG
			if up == 2 and absi(dx) <= 1 and absi(dz) <= 1:
				return BlockIds.LEAVES
			if up == 3 and absi(dx) + absi(dz) <= 1:
				return BlockIds.LEAVES
	return -1


# --- The built parts (the generator writes them over the platforms: write, block_at) ---------------------------------

func _make_built() -> void:
	var y := DECK_Y   # the first empty layer over the decks
	var s := _spawn
	# the cloud scope at the landing deck's rim, looking out and down over the open side
	var out := -_north
	var scope := s + out * SCOPE_OUT
	_put(Vector3i(scope.x, y, scope.y), Vector3i(scope.x, y, scope.y), BlockIds.SKY_FRAME)
	_put(Vector3i(scope.x, y + 1, scope.y), Vector3i(scope.x, y + 1, scope.y) + Vector3i(out.x, 0, out.y),
		BlockIds.TELESCOPE)
	_keep.append([scope.x, scope.y, 2])
	_sights.append([&"scope", scope - out])
	# the dock's mooring mast: a plinth, the mast, its lamp, an arm toward the blimp
	var dk := centre(DOCK)
	var mast := dk + _north * MAST_OUT + Vector2i(MAST_SIDE, 0)
	_put(Vector3i(mast.x - 1, y, mast.y - 1), Vector3i(mast.x + 1, y, mast.y + 1), BlockIds.SKY_FRAME)
	_put(Vector3i(mast.x, y + 1, mast.y), Vector3i(mast.x, y + MAST_H - 1, mast.y), BlockIds.SKY_FRAME)
	_put(Vector3i(mast.x, y + MAST_H, mast.y), Vector3i(mast.x, y + MAST_H, mast.y), BlockIds.CLOUD_LAMP)
	_put(Vector3i(mast.x, y + MAST_H - 2, mast.y) + Vector3i(_north.x, 0, _north.y),
		Vector3i(mast.x, y + MAST_H - 2, mast.y) + Vector3i(_north.x, 0, _north.y) * 3, BlockIds.SKY_FRAME)
	_keep.append([mast.x, mast.y, 2])
	_sights.append([&"dock", mast + Vector2i(-2, 0)])   # beside its plinth, on the deck
	# the sky garden: a round pond of water and a lamp fountain in its middle, a path round it
	var g := centre(GARDEN_DECK)
	_put(Vector3i(g.x - 2, y - 1, g.y - 2), Vector3i(g.x + 2, y - 1, g.y + 2), BlockIds.CLOUD_DECK)
	_put(Vector3i(g.x - 1, y - 1, g.y - 1), Vector3i(g.x + 1, y - 1, g.y + 1), BlockIds.WATER)
	_put(Vector3i(g.x, y - 1, g.y), Vector3i(g.x, y, g.y), BlockIds.SKY_FRAME)
	_put(Vector3i(g.x, y + 1, g.y), Vector3i(g.x, y + 1, g.y), BlockIds.CLOUD_LAMP)
	_keep.append([g.x, g.y, 3])
	_sights.append([&"garden", g + Vector2i(0, 2)])   # on the path round the pond
	# the cloud homes: four little domed homes round a square, their doors toward it
	var hm := centre(HOMES)
	for i in 4:   # on the square's diagonals
		_home(hm + Vector2i(HOME_STEP if i % 2 == 0 else -HOME_STEP, HOME_STEP if i < 2 else -HOME_STEP), hm, y,
			HOME_COLORS[i])
	_sights.append([&"homes", hm])
	# the west lookout: a telescope on its stand at the deck's west edge, looking west (where the Sun rises on Venus)
	var lk := centre(LOOKOUT)
	var tel := lk + Vector2i(-LOOKOUT_OUT, 0)
	_put(Vector3i(tel.x, y, tel.y), Vector3i(tel.x, y, tel.y), BlockIds.SKY_FRAME)
	_put(Vector3i(tel.x - 1, y + 1, tel.y), Vector3i(tel.x, y + 1, tel.y), BlockIds.TELESCOPE)
	_keep.append([tel.x, tel.y, 2])
	_sights.append([&"lookout", tel + Vector2i(1, 0)])


## A little home at c (5 × 5): peach walls three high, a door toward `square`, a window in each other wall, a lamp under
## its dome, a stepped dome of `roof` with a lamp on top.
func _home(c: Vector2i, square: Vector2i, y: int, roof: int) -> void:
	_put(Vector3i(c.x - 2, y, c.y - 2), Vector3i(c.x + 2, y + 2, c.y + 2), BlockIds.HOME_PANEL)
	_put(Vector3i(c.x - 1, y, c.y - 1), Vector3i(c.x + 1, y + 2, c.y + 1), BlockIds.AIR)
	var to := square - c
	var door := Vector2i(signi(to.x), 0) if absi(to.x) >= absi(to.y) else Vector2i(0, signi(to.y))
	for w: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var at := c + w * 2
		if w == door:
			_put(Vector3i(at.x, y, at.y), Vector3i(at.x, y + 1, at.y), BlockIds.AIR)
		else:
			_put(Vector3i(at.x, y + 1, at.y), Vector3i(at.x, y + 1, at.y), BlockIds.GLASS)
	_put(Vector3i(c.x - 2, y + 3, c.y - 1), Vector3i(c.x + 2, y + 3, c.y + 1), roof)
	_put(Vector3i(c.x - 1, y + 3, c.y - 2), Vector3i(c.x + 1, y + 3, c.y + 2), roof)
	_put(Vector3i(c.x - 1, y + 4, c.y - 1), Vector3i(c.x + 1, y + 4, c.y + 1), roof)
	_put(Vector3i(c.x, y + 3, c.y), Vector3i(c.x, y + 3, c.y), BlockIds.CLOUD_LAMP)
	_put(Vector3i(c.x, y + 5, c.y), Vector3i(c.x, y + 5, c.y), BlockIds.CLOUD_LAMP)
	_keep.append([c.x, c.y, 3])


## A box between two corner cells (inclusive, any order).
func _put(a: Vector3i, b: Vector3i, id: int) -> void:
	var lo := a.min(b)
	var hi := a.max(b) + Vector3i.ONE
	_boxes.append_array([lo.x, lo.y, lo.z, hi.x, hi.y, hi.z, id])


func _make_index() -> void:
	for i in _boxes.size() / STRIDE:
		var k := i * STRIDE
		for cz in range(floori(_boxes[k + 2] / float(CHUNK)), floori((_boxes[k + 5] - 1) / float(CHUNK)) + 1):
			for cy in range(floori(_boxes[k + 1] / float(CHUNK)), floori((_boxes[k + 4] - 1) / float(CHUNK)) + 1):
				for cx in range(floori(_boxes[k] / float(CHUNK)), floori((_boxes[k + 3] - 1) / float(CHUNK)) + 1):
					var key := Vector3i(cx, cy, cz)
					var list: PackedInt32Array = _index.get(key, PackedInt32Array())
					list.append(i)
					_index[key] = list


## The block the city's built parts put at p, or -1 (the generator's reference; later boxes win).
func built_at(p: Vector3i) -> int:
	var list: Variant = _index.get(Vector3i(floori(p.x / float(CHUNK)), floori(p.y / float(CHUNK)),
		floori(p.z / float(CHUNK))))
	if list == null:
		return -1
	var ids: PackedInt32Array = list
	for j in range(ids.size() - 1, -1, -1):
		var k := ids[j] * STRIDE
		if p.x >= _boxes[k] and p.y >= _boxes[k + 1] and p.z >= _boxes[k + 2] and p.x < _boxes[k + 3] \
				and p.y < _boxes[k + 4] and p.z < _boxes[k + 5]:
			return _boxes[k + 6]
	return -1


## Writes the built parts that reach into the buffer (the generator's fast path; equal to built_at).
func write(buf: VoxelBuffer, origin: Vector3i) -> void:
	var size := buf.get_size()
	if size != Vector3i(CHUNK, CHUNK, CHUNK) or posmod(origin.x, CHUNK) != 0 or posmod(origin.y, CHUNK) != 0 \
			or posmod(origin.z, CHUNK) != 0:
		_write_any(buf, origin)
		return
	var list: Variant = _index.get(Vector3i(floori(origin.x / float(CHUNK)), floori(origin.y / float(CHUNK)),
		floori(origin.z / float(CHUNK))))
	if list == null:
		return
	var end := origin + size
	for i: int in (list as PackedInt32Array):
		var k := i * STRIDE
		var bl := Vector3i(maxi(_boxes[k], origin.x), maxi(_boxes[k + 1], origin.y), maxi(_boxes[k + 2], origin.z)) - origin
		var bh := Vector3i(mini(_boxes[k + 3], end.x), mini(_boxes[k + 4], end.y), mini(_boxes[k + 5], end.z)) - origin
		if bl.x < bh.x and bl.y < bh.y and bl.z < bh.z:
			buf.fill_area(_boxes[k + 6], bl, bh, VoxelBuffer.CHANNEL_TYPE)


## Any buffer (not one aligned chunk): every box, in painting order.
func _write_any(buf: VoxelBuffer, origin: Vector3i) -> void:
	var end := origin + buf.get_size()
	for i in _boxes.size() / STRIDE:
		var k := i * STRIDE
		var bl := Vector3i(maxi(_boxes[k], origin.x), maxi(_boxes[k + 1], origin.y), maxi(_boxes[k + 2], origin.z)) - origin
		var bh := Vector3i(mini(_boxes[k + 3], end.x), mini(_boxes[k + 4], end.y), mini(_boxes[k + 5], end.z)) - origin
		if bl.x < bh.x and bl.y < bh.y and bl.z < bh.z:
			buf.fill_area(_boxes[k + 6], bl, bh, VoxelBuffer.CHANNEL_TYPE)


## The highest y any built part reaches, plus one.
func built_top() -> int:
	var top := DECK_Y
	for i in _boxes.size() / STRIDE:
		top = maxi(top, _boxes[i * STRIDE + 4])
	return top


func box_count() -> int:
	return _boxes.size() / STRIDE


# --- Sights, secrets and the places others stand -------------------------------------------------------------------

## The sight a child standing at (x, z) is at (&"scope", &"dock", &"garden", &"homes", &"lookout"), &"" for none.
func sight_at(x: int, z: int) -> StringName:
	for e: Array in _sights:
		var at: Vector2i = e[1]
		var reach := GARDEN_REACH if e[0] == &"garden" else SIGHT_REACH
		if absi(x - at.x) <= reach and absi(z - at.y) <= reach:
			return e[0]
	return &""


## The sights' spots, in MY MAP's order: [[id, Vector2i], ...].
func sight_spots() -> Array:
	return _sights


## The column (x, z) is on the aliens' camp deck (where their camp stands: AlienRules).
func camp_spot(x: int, z: int) -> bool:
	var p: Array = platform(CAMP)
	return not p.is_empty() and _inside(p, x, z)


## The column (x, z) is on the show deck (the only place the Theater may stand: TheaterSite).
func show_spot(x: int, z: int) -> bool:
	var p: Array = platform(SHOW)
	return not p.is_empty() and _inside(p, x, z)


## Where a secret drawn at (x, z) of the secrets area `area` goes: a spot on a platform whose middle is in the area (the
## one `v` picks; never the landing deck, the camp's or the show's), up to `inner` inside its rim; NONE without one.
func secret_spot(area: Vector2i, v: int, inner: int) -> Vector2i:
	var a0 := area * SecretRules.AREA
	var list: Array = []
	for p: Array in _plats:
		if _in_area(p, a0) and not p[0] in [LANDING, CAMP, SHOW]:
			list.append(p)
	for cz in range(floori(a0.y / float(ISLE_CELL)), floori((a0.y + SecretRules.AREA - 1) / float(ISLE_CELL)) + 1):
		for cx in range(floori(a0.x / float(ISLE_CELL)), floori((a0.x + SecretRules.AREA - 1) / float(ISLE_CELL)) + 1):
			var i := isle(Vector2i(cx, cz))
			if not i.is_empty() and _in_area(i, a0):
				list.append(i)
	if list.is_empty():
		return NONE
	var p: Array = list[absi(v) % list.size()]
	var room := maxi(int(p[3]) - inner, 0)
	var h := absi(_mix(v + 97))
	var a := float(h % 3600) / 3600.0 * TAU
	var d := float((h >> 12) % (room + 1))
	return Vector2i(int(p[1]) + roundi(cos(a) * d), int(p[2]) + roundi(sin(a) * d))


static func _in_area(p: Array, a0: Vector2i) -> bool:
	return int(p[1]) >= a0.x and int(p[2]) >= a0.y and int(p[1]) < a0.x + SecretRules.AREA \
		and int(p[2]) < a0.y + SecretRules.AREA


## A secret (its boxes [[lo, hi, id], ...] and their bounds [lo, hi)) is held by the city: every column under each box is
## a platform's (never a bridge's, never the clouds'; not the camp's or the show's deck), and under a box that goes down
## into a deck the hull reaches lower still; it keeps `gap` from the built parts.
func holds(boxes: Array, lo: Vector3i, hi: Vector3i, gap: int) -> bool:
	var near := _near(lo.x, lo.z, hi.x - 1, hi.z - 1)
	var cols := {}
	for b: Array in boxes:
		var a: Vector3i = b[0]
		var e: Vector3i = b[1]
		for z in range(a.z, e.z):
			for x in range(a.x, e.x):
				var key := Vector2i(x, z)
				var c: PackedInt32Array = cols.get(key, PackedInt32Array())
				if c.is_empty():
					c = _built(x, z, near[0], near[1])
					if c[0] == CLOUD or c[0] == BRIDGE or camp_spot(x, z) or show_spot(x, z):
						return false
					cols[key] = c
				if a.y < DECK_Y - 1 and c[2] >= a.y:
					return false
	var mid := Vector2((lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5)
	var half := Vector2(hi.x - lo.x, hi.z - lo.z).length() * 0.5
	for k: Array in _keep:
		if mid.distance_to(Vector2(k[0], k[1])) <= half + float(k[2]) + gap:
			return false
	return true


func _mix(n: int) -> int:
	var h := n * 374761393 + _seed * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
