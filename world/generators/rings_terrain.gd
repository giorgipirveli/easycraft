class_name RingsTerrain
extends RefCounted
## Saturn's rings as pure rules (cosmos, spec §21b.2), for SpaceShape's planet RINGS. The rings are countless chunks of
## water ice (and a little rock), from dust grains to chunks as big as a house, in a sheet only about 10 m thick but
## thousands of kilometres wide, in bands with gaps (NASA). The world is a strip of that sheet: the bands run east-west
## forever (the rings go all the way round Saturn), and north is towards Saturn (-z, as on MY MAP), which hangs huge over
## the northern horizon (the descriptor's sky). From north to south:
## - the C ring (C_IN-B_IN): fewer, smaller chunks of darker, dustier ice;
## - the B ring (B_IN-B_OUT), the brightest and densest: big chunks of frosty ice with flat tops (a child walks and builds
##   on them: at 0.05 gravity a one-block step is a slow hop, so no step on a chunk) and rough, rounded undersides, boulders and pebbles between them; the landing chunk (the pad, the Ring Station,
##   the Saturn scope at its north rim), the aliens' camp chunk, the show chunk (the Theater's), the explorer's chunk (the
##   Ring Explorer, the world's landmark: SpaceSecretRules) and the edge chunk at the B ring's outer edge (a beacon: the
##   Cassini Division's sight);
## - the Cassini Division (B_OUT-A_IN), a wide gap: only a few small, darker lumps;
## - the A ring (A_IN-A_OUT), with the Encke Gap (ENCKE_IN-ENCKE_OUT) where Pan, a little walnut-shaped moon (a round
##   body with a ridge round its middle), sweeps a clear lane, and the narrow Keeler Gap (KEELER_IN-KEELER_OUT);
## - the thin F ring (F_MID): two braided strands of small lumps, and a chunk with a beacon (a sight);
## - beyond: space. North of the C ring: space too, and Saturn.
## Chunk tops float at slightly different heights (TOP_BASE ± TOP_SPREAD); at 0.05 of Earth's gravity a jump carries a
## child from chunk to chunk. A child who falls between them is carried back to the last chunk it stood on long before
## LIFT_Y (the descriptor's void line: DragonRules), so falling is never a danger and Saturn is never reached.
## Layout: big chunks one per BIG × BIG cell at most (each inside its own cell), lumps one per SMALL × SMALL cell at most
## (never near a big chunk, the fixed chunks or Pan), F ring lumps per F_STEP along the strands; every column holds one
## span at most. `flip` (from the seed) mirrors the fixed chunks east-west. Every rule is a function of the seed and
## (x, z) (y for the built parts), read-only after construction (the generator's threads share it). columns() does a
## block of columns at once (the generator's path) and equals column().

## Column kinds.
const VOID := 0          # nothing: open space between the chunks, in the gaps, beyond the rings
const ICE_FLAT := 1      # a big chunk of frosty ice with a flat top (B and A rings, the fixed chunks)
const DUSTY_FLAT := 2    # a big chunk of dusty ice (the C ring)
const ICE_LUMP := 3      # a boulder or a pebble of ice
const DUSTY_LUMP := 4    # a darker, dustier lump (the C ring, the Cassini Division)
const ROCK_LUMP := 5     # a lump of rock
const MOONLET := 6       # Pan's round body
const RIDGE := 7         # the ridge round Pan's middle

## Bands.
const NO_BAND := 0
const C_BAND := 1
const B_BAND := 2
const CASSINI_BAND := 3
const A_BAND := 4
const F_BAND := 5

## Fixed chunks' roles.
const LANDING := &"landing"
const CAMP := &"camp"
const SHOW := &"show"
const EXPLORER := &"explorer"
const EDGE := &"edge"
const C_SPOT := &"c_spot"
const F_SPOT := &"f_spot"

## The bands, in blocks south of the spawn (negative: north, towards Saturn).
const C_IN := -290
const B_IN := -150
const B_OUT := 90
const A_IN := 150
const ENCKE_IN := 270
const ENCKE_OUT := 326
const KEELER_IN := 345
const KEELER_OUT := 350
const A_OUT := 360
const F_MID := 393
const F_SWING := 2.5         # the F ring's strands wander this far either way
const F_STEP := 5            # a lump every F_STEP along x on each strand (at most)
const F_CHANCE := 70

const TOP_BASE := 64         # the fixed chunks' tops (the first empty y over them) ...
const TOP_SPREAD := 7        # ... the others' up to this either way
const LUMP_LOW := 58         # a lump's middle between these
const LUMP_HIGH := 69
const LIFT_Y := 50.0         # feet under this: carried back to the rings (under every chunk's top)
const DEEP := 0.9            # a big chunk's underside: this × its radius deep at its middle
const WOBBLE_A := 0.10       # a big chunk's outline wobbles in from its radius (two waves round it)
const WOBBLE_B := 0.06
const WOBBLE_MAX := 1.0      # ... never out past it
const BIG := 32
const BIG_R := Vector2i(6, 13)
const SMALL := 10
const SMALL_R := Vector2i(1, 3)
const CLEAR := 4             # procedural chunks keep this far from the fixed chunks, Pan and big chunks
## Chances (of 100 cells) per band: big chunks, lumps.
const BIG_CHANCE := {C_BAND: 36, B_BAND: 92, A_BAND: 80}
const SMALL_CHANCE := {C_BAND: 30, B_BAND: 45, CASSINI_BAND: 20, A_BAND: 40}
const ROCKY := 12            # of 100 lumps are rock

## Pan in the Encke Gap: its body's radius and half height, its ridge's radius, its middle's height.
const PAN_X := 18            # east of the spawn (west when flipped)
const PAN_R := 11
const PAN_HALF := 7
const PAN_RIDGE := 14
const PAN_Y := 60

## The spawn (the landing pad's middle) and the fixed chunks round it: [role, kind, x, z (south: +z), radius, top].
const SPAWN := Vector2i(40, 24)
const FIXED := [
	[LANDING, ICE_FLAT, 0, 0, 22],
	[CAMP, ICE_FLAT, 34, 14, 10],
	[SHOW, ICE_FLAT, -36, 16, 12],
	[EXPLORER, ICE_FLAT, 6, 50, 13],
	[EDGE, ICE_FLAT, -24, 78, 10],
	[C_SPOT, DUSTY_FLAT, 0, -220, 8],
	[F_SPOT, ICE_FLAT, 0, F_MID, 5],
]

## The built parts on the landing chunk: the Saturn scope at its north rim, the Ring Station, the Saturn model.
const SCOPE_OUT := 20        # the scope: this far north of the pad
const STATION := Vector2i(14, -4)   # the station's middle (east of the pad; west when flipped)
const STATION_HALF := Vector2i(3, 2)
const STATION_H := 3
const MODEL := Vector2i(12, 7)      # the Saturn model on its post
const BEACON_H := 3                 # a beacon: two blocks of truss, the lamp
## Sights: standing this close (either way) to a sight's spot finds it; Pan's is its top.
const SIGHT_REACH := 2
const PAN_REACH := 4
const NONE := Vector2i(0x7fffffff, 0x7fffffff)
const VOID_TOP := MeadowsShape.SEA_LEVEL   # a VOID column's height: "no ground here" (the Dragon Realm's rule)
const CHUNK := 16
const STRIDE := 7            # a built part's box: lo.x, lo.y, lo.z, hi.x, hi.y, hi.z, id

var flip := false
var _seed := 0
var _spawn := SPAWN
var _fixed: Array = []       # [kind, cx, cz, r, top, 0 (a perfect disc), hash, role]
var _roles := {}             # role -> its fixed chunk
var _pan: Array = []         # [MOONLET, cx, cz, PAN_RIDGE, PAN_Y, PAN_HALF, 0, &"pan"]
var _sights: Array = []      # [[id, spot], ...]
var _keep: Array = []        # [cx, cz, r]: the built parts' ground (features, secrets and spawners keep clear)
var _boxes := PackedInt32Array()
var _index := {}             # chunk (16 cubed) -> PackedInt32Array of box indexes


func _init(world_seed: int) -> void:
	_seed = world_seed
	flip = absi(_mix(world_seed + 25)) % 2 == 1
	var sx := -1 if flip else 1
	for e: Array in FIXED:
		var c := [int(e[1]), _spawn.x + int(e[2]) * sx, _spawn.y + int(e[3]), int(e[4]), TOP_BASE, 0, 0, e[0]]
		_fixed.append(c)
		_roles[e[0]] = c
	_pan = [MOONLET, _spawn.x + PAN_X * sx, _spawn.y + (ENCKE_IN + ENCKE_OUT) / 2, PAN_RIDGE, PAN_Y, PAN_HALF, 0, &"pan"]
	_make_built()
	_make_index()


# --- The layout ------------------------------------------------------------------------------------------------------

func spawn() -> Vector2i:
	return _spawn


## The fixed chunk of `role`: [kind, cx, cz, r, top, 0, 0, role]; [] for none.
func fixed(role: StringName) -> Array:
	return _roles.get(role, [])


## The middle of `role`'s fixed chunk (&"pan": Pan's) (NONE for none).
func centre(role: StringName) -> Vector2i:
	if role == &"pan":
		return Vector2i(_pan[1], _pan[2])
	var c: Array = fixed(role)
	return Vector2i(c[1], c[2]) if not c.is_empty() else NONE


## Every fixed chunk: [[kind, cx, cz, r, top, 0, 0, role], ...].
func fixed_chunks() -> Array:
	return _fixed


## The band at z: C_BAND … F_BAND, NO_BAND in a gap or beyond the rings.
func band(z: int) -> int:
	var d := z - _spawn.y
	if d >= C_IN and d < B_IN:
		return C_BAND
	if d >= B_IN and d < B_OUT:
		return B_BAND
	if d >= B_OUT and d < A_IN:
		return CASSINI_BAND
	if d >= A_IN and d < A_OUT and not (d >= ENCKE_IN and d < ENCKE_OUT) and not (d >= KEELER_IN and d < KEELER_OUT):
		return A_BAND
	if absi(d - F_MID) <= ceili(F_SWING) + 3:
		return F_BAND
	return NO_BAND


## The big chunk of cell (bx, bz): [kind, cx, cz, r, top, 1 (wobbly, rough underneath), hash, &""], or [].
func big_chunk(cell: Vector2i) -> Array:
	var h := absi(_mix(cell.x * 73856093 ^ cell.y * 19349663 ^ (_seed + 251)))
	var r := BIG_R.x + (h >> 7) % (BIG_R.y - BIG_R.x + 1)
	var m := r + 1
	var span := BIG - 2 * m
	var cx := cell.x * BIG + m + (h >> 11) % span
	var cz := cell.y * BIG + m + (h >> 17) % span
	var b := band(cz)
	if b != band(cz - m) or b != band(cz + m) or not BIG_CHANCE.has(b) or h % 100 >= int(BIG_CHANCE[b]):
		return []
	if C_BAND == b:
		r = mini(r, 8)
	if _near_fixed(cx, cz, r * WOBBLE_MAX + CLEAR):
		return []
	var top := TOP_BASE - TOP_SPREAD + (h >> 23) % (2 * TOP_SPREAD + 1)
	return [DUSTY_FLAT if b == C_BAND else ICE_FLAT, cx, cz, r, top, 1, h, &""]


## The lump of cell (sx, sz): [kind, cx, cz, r, middle y, half height, hash, &""], or [].
func lump(cell: Vector2i) -> Array:
	var h := absi(_mix(cell.x * 83492791 ^ cell.y * 29717 ^ (_seed + 253)))
	var r := SMALL_R.x + (h >> 7) % (SMALL_R.y - SMALL_R.x + 1)
	var span := SMALL - 2 * r - 2
	var cx := cell.x * SMALL + r + 1 + (h >> 10) % span
	var cz := cell.y * SMALL + r + 1 + (h >> 14) % span
	var b := band(cz)
	if b != band(cz - r - 1) or b != band(cz + r + 1) or not SMALL_CHANCE.has(b) or h % 100 >= int(SMALL_CHANCE[b]):
		return []
	if _near_fixed(cx, cz, r + CLEAR):
		return []
	var bc := Vector2i(floori(cx / float(BIG)), floori(cz / float(BIG)))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var big := big_chunk(bc + Vector2i(dx, dz))
			if not big.is_empty() and Vector2(cx - int(big[1]), cz - int(big[2])).length() \
					< float(big[3]) * WOBBLE_MAX + r + CLEAR:
				return []
	var kind := ICE_LUMP
	if (h >> 18) % 100 < ROCKY:
		kind = ROCK_LUMP
	elif b == C_BAND or b == CASSINI_BAND:
		kind = DUSTY_LUMP
	var cy := LUMP_LOW + (h >> 21) % (LUMP_HIGH - LUMP_LOW + 1)
	return [kind, cx, cz, r, cy, maxi(1, roundi(r * 0.8)), h, &""]


## The F ring's lump at step i on strand s (0 or 1): [ICE_LUMP, cx, cz, r, middle y, half height, hash, &""], or [].
func f_lump(i: int, s: int) -> Array:
	var h := absi(_mix(i * 2654435 ^ (s + 1) * 40503 ^ (_seed + 257)))
	if h % 100 >= F_CHANCE:
		return []
	var cx := i * F_STEP + 2 + (h >> 8) % 2
	var wave := sin(cx / 17.0 + 0.4) if s == 0 else -sin(cx / 13.0 + 1.3)
	var cz := _spawn.y + F_MID + roundi(F_SWING * wave)
	var r := 2 if (h >> 12) % 100 < 15 else 1
	if _near_fixed(cx, cz, r + CLEAR):
		return []
	return [ICE_LUMP, cx, cz, r, 62 + (h >> 16) % 5, 1, h, &""]


## Some fixed chunk (or Pan) lies within `reach` (plus its own radius) of (x, z).
func _near_fixed(x: int, z: int, reach: float) -> bool:
	for c: Array in _fixed:
		var rr := float(c[3]) + reach
		if absi(x - int(c[1])) <= rr and absi(z - int(c[2])) <= rr \
				and Vector2(x - int(c[1]), z - int(c[2])).length_squared() < rr * rr:
			return true
	var pr := float(PAN_RIDGE) + reach
	return Vector2(x - int(_pan[1]), z - int(_pan[2])).length_squared() < pr * pr


# --- Columns ---------------------------------------------------------------------------------------------------------

## [kind, top, bottom] of the column at (x, z): its kind (VOID, ICE_FLAT, …), the first empty y over it and its lowest
## block (VOID: SpaceShape's "no ground" height, twice).
func column(x: int, z: int) -> PackedInt32Array:
	return _column(x, z, _near(x, z, x, z))


## [tops, kinds, bottoms] of sx × sz columns from (x0, z0) (index x + z * sx), exactly column()'s, the chunks near the
## block gathered once (the generator's path).
func columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var near := _near(x0, z0, x0 + sx - 1, z0 + sz - 1)
	var tops := PackedInt32Array()
	tops.resize(sx * sz)
	var kinds := PackedByteArray()
	kinds.resize(sx * sz)
	var bottoms := PackedInt32Array()
	bottoms.resize(sx * sz)
	for z in sz:
		for x in sx:
			var c := _column(x0 + x, z0 + z, near)
			var i := x + z * sx
			kinds[i] = c[0]
			tops[i] = c[1]
			bottoms[i] = c[2]
	return [tops, kinds, bottoms]


## The first empty y over the column (x, z): its chunk's top, else VOID_TOP.
func top_at(x: int, z: int) -> int:
	return column(x, z)[1]


func kind_at(x: int, z: int) -> int:
	return column(x, z)[0]


## No ground for a spawner (the aliens, Tilly, the Totem, the Theater, secrets): open space, a lump, Pan.
func is_open(x: int, z: int) -> bool:
	var k := kind_at(x, z)
	return k != ICE_FLAT and k != DUSTY_FLAT


## The chunk holding the column (x, z) ([kind, cx, cz, r, …]; [] over open space).
func chunk_at(x: int, z: int) -> Array:
	for c: Array in _near(x, z, x, z):
		if not _hit(c, x, z).is_empty():
			return c
	return []


func _column(x: int, z: int, near: Array) -> PackedInt32Array:
	for c: Array in near:
		var hit := _hit(c, x, z)
		if not hit.is_empty():
			return hit
	return PackedInt32Array([VOID, VOID_TOP, VOID_TOP])


## [kind, top, bottom] where chunk c covers the column (x, z), else empty.
func _hit(c: Array, x: int, z: int) -> PackedInt32Array:
	var kind: int = c[0]
	var dx := x - int(c[1])
	var dz := z - int(c[2])
	var r := int(c[3])
	var d2 := dx * dx + dz * dz
	if kind == ICE_FLAT or kind == DUSTY_FLAT:
		var wobbly := int(c[5]) == 1
		var rmax := r * WOBBLE_MAX if wobbly else float(r)
		if d2 > rmax * rmax:
			return PackedInt32Array()
		var d := sqrt(float(d2))
		var re := float(r)
		if wobbly:
			var h := int(c[6])
			var a := atan2(float(dz), float(dx))
			re = r * (1.0 - WOBBLE_A * (0.5 + 0.5 * sin(3.0 * a + float(h & 1023) / 163.0))
				- WOBBLE_B * (0.5 + 0.5 * sin(5.0 * a + float((h >> 10) & 1023) / 163.0)))
		if d > re:
			return PackedInt32Array()
		var t := sqrt(maxf(1.0 - (d * d) / (re * re), 0.0))
		var depth := 1 + floori(DEEP * r * t)
		var top := int(c[4])
		if wobbly:
			depth = maxi(1, depth + absi(_mix(x * 7 + 3 ^ z * 13 - 5 ^ int(c[6]))) % 3 - 1)
		return PackedInt32Array([kind, top, top - 1 - depth])
	if kind == MOONLET:
		if d2 > r * r:
			return PackedInt32Array()
		var cy := int(c[4])
		var body := 1.0 - float(d2) / float(PAN_R * PAN_R)
		var hh := floori(float(c[5]) * sqrt(body)) if body > 0.0 else -1
		if hh >= 1:
			return PackedInt32Array([MOONLET, cy + hh + 1, cy - hh])
		return PackedInt32Array([RIDGE, cy + 1, cy - 1])
	var rr := (r + 0.5) * (r + 0.5)
	if d2 > rr:
		return PackedInt32Array()
	var half := floori(float(c[5]) * sqrt(maxf(1.0 - d2 / rr, 0.0)) + 0.5)
	return PackedInt32Array([kind, int(c[4]) + half + 1, int(c[4]) - half])


## Every chunk that may touch the columns x0..x1, z0..z1, in one fixed order (the fixed chunks, Pan, the big chunks,
## the lumps, the F ring's lumps; cells row by row), so a column meets them in the same order from any look.
func _near(x0: int, z0: int, x1: int, z1: int) -> Array:
	var out: Array = []
	for c: Array in _fixed:
		var r := int(c[3])
		if int(c[1]) + r >= x0 and int(c[1]) - r <= x1 and int(c[2]) + r >= z0 and int(c[2]) - r <= z1:
			out.append(c)
	if int(_pan[1]) + PAN_RIDGE >= x0 and int(_pan[1]) - PAN_RIDGE <= x1 and int(_pan[2]) + PAN_RIDGE >= z0 \
			and int(_pan[2]) - PAN_RIDGE <= z1:
		out.append(_pan)
	var lo := z0 - _spawn.y
	var hi := z1 - _spawn.y
	if hi < C_IN or lo >= A_OUT and (lo > F_MID + 8 or hi < F_MID - 8):
		return out   # beyond the rings (the F ring's lumps below)
	if hi >= C_IN and lo < A_OUT:
		for bz in range(floori(z0 / float(BIG)), floori(z1 / float(BIG)) + 1):
			for bx in range(floori(x0 / float(BIG)), floori(x1 / float(BIG)) + 1):
				var b := big_chunk(Vector2i(bx, bz))
				if not b.is_empty():
					out.append(b)
		for sz in range(floori(z0 / float(SMALL)), floori(z1 / float(SMALL)) + 1):
			for sx in range(floori(x0 / float(SMALL)), floori(x1 / float(SMALL)) + 1):
				var l := lump(Vector2i(sx, sz))
				if not l.is_empty():
					out.append(l)
	if hi >= F_MID - 8 and lo <= F_MID + 8:
		for i in range(floori(x0 / float(F_STEP)) - 1, floori(x1 / float(F_STEP)) + 2):
			for s in 2:
				var f := f_lump(i, s)
				if not f.is_empty():
					out.append(f)
	return out


## The top block of a column of `kind` (the landing pad is SpaceShape's).
static func top_block(kind: int) -> int:
	match kind:
		ICE_FLAT, ICE_LUMP:
			return BlockIds.RING_FROST
		DUSTY_FLAT, DUSTY_LUMP:
			return BlockIds.DUSTY_ICE
		ROCK_LUMP:
			return BlockIds.RING_ROCK
		MOONLET:
			return BlockIds.MOONLET_ICE
		RIDGE:
			return BlockIds.RIDGE_DUST
	return BlockIds.AIR


## The block under a column's top.
static func under_block(kind: int) -> int:
	match kind:
		ICE_FLAT, ICE_LUMP:
			return BlockIds.RING_ICE
		DUSTY_FLAT, DUSTY_LUMP:
			return BlockIds.DUSTY_ICE
		ROCK_LUMP:
			return BlockIds.RING_ROCK
		MOONLET:
			return BlockIds.MOONLET_ICE
		RIDGE:
			return BlockIds.RIDGE_DUST
	return BlockIds.AIR


## The block at height y of a column [kind, top, bottom] (no built parts, no pad).
static func block(y: int, c: PackedInt32Array) -> int:
	if c[0] == VOID or y < c[2] or y >= c[1]:
		return BlockIds.AIR
	return top_block(c[0]) if y == c[1] - 1 else under_block(c[0])


# --- The built parts (the generator writes them over the chunks: write, built_at) -----------------------------------

func _make_built() -> void:
	var s := _spawn
	var y := int(fixed(LANDING)[4])   # the first empty layer over the landing chunk
	var sx := -1 if flip else 1
	# the Saturn scope at the landing chunk's north rim, looking north at Saturn
	var scope := s + Vector2i(0, -SCOPE_OUT)
	_put(Vector3i(scope.x, y, scope.y), Vector3i(scope.x, y, scope.y), BlockIds.TRUSS)
	_put(Vector3i(scope.x, y + 1, scope.y), Vector3i(scope.x, y + 1, scope.y - 1), BlockIds.TELESCOPE)
	_keep.append([scope.x, scope.y, 2])
	_sights.append([&"scope", scope + Vector2i(0, 2)])
	# the Ring Station: white panels round a room, round windows, a door towards the pad, lamps, a roof with a radio dish
	# and a glowing power pack
	var st := s + Vector2i(STATION.x * sx, STATION.y)
	var hx := STATION_HALF.x
	var hz := STATION_HALF.y
	_put(Vector3i(st.x - hx, y, st.y - hz), Vector3i(st.x + hx, y + STATION_H - 1, st.y + hz), BlockIds.STATION_PANEL)
	_put(Vector3i(st.x - hx + 1, y, st.y - hz + 1), Vector3i(st.x + hx - 1, y + STATION_H - 1, st.y + hz - 1), BlockIds.AIR)
	for wx: int in [-1, 1]:   # windows in the long walls
		_put(Vector3i(st.x + wx, y + 1, st.y - hz), Vector3i(st.x + wx, y + 1, st.y - hz), BlockIds.STATION_WINDOW)
		_put(Vector3i(st.x + wx, y + 1, st.y + hz), Vector3i(st.x + wx, y + 1, st.y + hz), BlockIds.STATION_WINDOW)
	var door := Vector2i(st.x - hx * sx, st.y)   # the end towards the pad
	_put(Vector3i(door.x, y, door.y), Vector3i(door.x, y + 1, door.y), BlockIds.AIR)
	var back := Vector2i(st.x + hx * sx, st.y)
	_put(Vector3i(back.x, y + 1, back.y), Vector3i(back.x, y + 1, back.y), BlockIds.STATION_WINDOW)
	_put(Vector3i(st.x - hx, y + STATION_H, st.y - hz), Vector3i(st.x + hx, y + STATION_H, st.y + hz), BlockIds.STATION_PANEL)
	_put(Vector3i(st.x, y + STATION_H - 1, st.y), Vector3i(st.x, y + STATION_H - 1, st.y), BlockIds.STATION_LAMP)
	_put(Vector3i(st.x - hx, y + STATION_H, st.y - hz), Vector3i(st.x - hx, y + STATION_H, st.y - hz), BlockIds.STATION_LAMP)
	_put(Vector3i(st.x + hx, y + STATION_H, st.y + hz), Vector3i(st.x + hx, y + STATION_H, st.y + hz), BlockIds.STATION_LAMP)
	var dish := Vector3i(st.x + sx, y + STATION_H + 1, st.y)
	_put(dish, dish + Vector3i(0, 1, 0), BlockIds.TRUSS)
	_put(dish + Vector3i(-1, 2, -1), dish + Vector3i(1, 2, 1), BlockIds.RADIO_DISH)
	_put(dish + Vector3i(0, 3, 0), dish + Vector3i(0, 3, 0), BlockIds.TRUSS)
	var power := Vector3i(st.x - 2 * sx, y + STATION_H + 1, st.y)
	_put(power, power, BlockIds.POWER_PACK)
	_keep.append([st.x, st.y, hx + 2])
	_sights.append([&"station", door - Vector2i(2 * sx, 0)])
	# the Saturn model: a banded Saturn on a truss post, a ring of frost round its middle
	var md := s + Vector2i(MODEL.x * sx, MODEL.y)
	_put(Vector3i(md.x, y, md.y), Vector3i(md.x, y + 1, md.y), BlockIds.TRUSS)
	var mc := Vector3i(md.x, y + 3, md.y)
	_put(mc + Vector3i(-1, -1, 0), mc + Vector3i(1, 1, 0), BlockIds.SATURN_BAND)
	_put(mc + Vector3i(0, -1, -1), mc + Vector3i(0, 1, 1), BlockIds.SATURN_BAND)
	for d: Vector3i in [Vector3i(-2, 0, -2), Vector3i(2, 0, -2), Vector3i(-2, 0, 2), Vector3i(2, 0, 2)]:
		_put(mc + Vector3i(d.x, 0, 0), mc + Vector3i(d.x, 0, 0), BlockIds.RING_FROST)
		_put(mc + Vector3i(0, 0, d.z), mc + Vector3i(0, 0, d.z), BlockIds.RING_FROST)
		_put(mc + Vector3i(signi(d.x), 0, signi(d.z)) * 2 - Vector3i(signi(d.x), 0, 0),
			mc + Vector3i(signi(d.x), 0, signi(d.z)) * 2 - Vector3i(signi(d.x), 0, 0), BlockIds.RING_FROST)
		_put(mc + Vector3i(signi(d.x), 0, signi(d.z)) * 2 - Vector3i(0, 0, signi(d.z)),
			mc + Vector3i(signi(d.x), 0, signi(d.z)) * 2 - Vector3i(0, 0, signi(d.z)), BlockIds.RING_FROST)
	_keep.append([md.x, md.y, 3])
	# the beacons: the Cassini Division's at the edge chunk's south rim, the C ring's and the F ring's on their chunks
	var edge: Array = fixed(EDGE)
	_beacon(Vector2i(edge[1], int(edge[2]) + int(edge[3]) - 2), int(edge[4]), &"cassini", Vector2i(0, -2))
	var cr: Array = fixed(C_SPOT)
	_beacon(Vector2i(cr[1], cr[2]), int(cr[4]), &"c_ring", Vector2i(0, 2))
	var fr: Array = fixed(F_SPOT)
	_beacon(Vector2i(fr[1], fr[2]), int(fr[4]), &"f_ring", Vector2i(0, -2))
	# Pan's beacon on its top
	var pan := Vector2i(_pan[1], _pan[2])
	var pan_top := PAN_Y + PAN_HALF + 1
	_put(Vector3i(pan.x, pan_top, pan.y), Vector3i(pan.x, pan_top, pan.y), BlockIds.RING_BEACON)
	_sights.append([&"pan", pan])


## A beacon at column c on a chunk whose top is y: two blocks of truss and the teal lamp; its sight beside it.
func _beacon(c: Vector2i, y: int, id: StringName, beside: Vector2i) -> void:
	_put(Vector3i(c.x, y, c.y), Vector3i(c.x, y + BEACON_H - 2, c.y), BlockIds.TRUSS)
	_put(Vector3i(c.x, y + BEACON_H - 1, c.y), Vector3i(c.x, y + BEACON_H - 1, c.y), BlockIds.RING_BEACON)
	_keep.append([c.x, c.y, 1])
	_sights.append([id, c + beside])


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


## The block the built parts put at p, or -1 (the generator's reference; later boxes win).
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


func box_count() -> int:
	return _boxes.size() / STRIDE


## The highest y any built part reaches, plus one.
func built_top() -> int:
	var top := TOP_BASE
	for i in _boxes.size() / STRIDE:
		top = maxi(top, _boxes[i * STRIDE + 4])
	return top


## The column (x, z) is within `margin` of one of the built parts (their ground: the keep list).
func kept(x: int, z: int, margin: int) -> bool:
	for k: Array in _keep:
		var r := float(k[2]) + margin
		if Vector2(x - int(k[0]), z - int(k[1])).length_squared() <= r * r:
			return true
	return false


# --- Sights, secrets and the places others stand -------------------------------------------------------------------

## The sight a child standing at (x, z) is at (&"scope", &"station", &"cassini", &"c_ring", &"f_ring", &"pan"), &"" for
## none.
func sight_at(x: int, z: int) -> StringName:
	for e: Array in _sights:
		var at: Vector2i = e[1]
		var reach := PAN_REACH if e[0] == &"pan" else SIGHT_REACH
		if absi(x - at.x) <= reach and absi(z - at.y) <= reach:
			return e[0]
	return &""


## The sights' spots, in MY MAP's order: [[id, Vector2i], ...].
func sight_spots() -> Array:
	return _sights


## The column (x, z) is on the aliens' camp chunk (where their camp stands: AlienRules).
func camp_spot(x: int, z: int) -> bool:
	return _on(fixed(CAMP), x, z)


## The column (x, z) is on the show chunk (the only place the Theater may stand: TheaterSite).
func show_spot(x: int, z: int) -> bool:
	return _on(fixed(SHOW), x, z)


static func _on(c: Array, x: int, z: int) -> bool:
	if c.is_empty():
		return false
	var dx := x - int(c[1])
	var dz := z - int(c[2])
	return dx * dx + dz * dz <= int(c[3]) * int(c[3])


## Where a secret drawn in the secrets area `area` goes: a spot on a big chunk whose middle is in the area (the one `v`
## picks; never the landing, camp, show or explorer chunk), up to `inner` inside its rim; NONE without one.
func secret_spot(area: Vector2i, v: int, inner: int) -> Vector2i:
	var a0 := area * SecretRules.AREA
	var list: Array = []
	for c: Array in _fixed:
		if _in_area(c, a0) and not c[7] in [LANDING, CAMP, SHOW, EXPLORER] and int(c[3]) - inner >= 2:
			list.append(c)
	for bz in range(floori(a0.y / float(BIG)), floori((a0.y + SecretRules.AREA - 1) / float(BIG)) + 1):
		for bx in range(floori(a0.x / float(BIG)), floori((a0.x + SecretRules.AREA - 1) / float(BIG)) + 1):
			var b := big_chunk(Vector2i(bx, bz))
			if not b.is_empty() and _in_area(b, a0) and int(b[3]) - inner >= 2:
				list.append(b)
	if list.is_empty():
		return NONE
	var c: Array = list[absi(v) % list.size()]
	var room := maxi(int(c[3]) - inner, 0)
	var h := absi(_mix(v + 97))
	var a := float(h % 3600) / 3600.0 * TAU
	var d := float((h >> 12) % (room + 1))
	return Vector2i(int(c[1]) + roundi(cos(a) * d), int(c[2]) + roundi(sin(a) * d))


static func _in_area(c: Array, a0: Vector2i) -> bool:
	return int(c[1]) >= a0.x and int(c[2]) >= a0.y and int(c[1]) < a0.x + SecretRules.AREA \
		and int(c[2]) < a0.y + SecretRules.AREA


## A secret (its boxes [[lo, hi, id], ...] and their bounds [lo, hi)) is held by a chunk: every column under each box is
## a big chunk's (never open space, a lump or Pan; not the camp's or the show's chunk), and under a box that reaches down
## into the chunk its ice reaches lower still; it keeps `gap` from the built parts.
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
					c = _column(x, z, near)
					if (c[0] != ICE_FLAT and c[0] != DUSTY_FLAT) or camp_spot(x, z) or show_spot(x, z):
						return false
					cols[key] = c
				if a.y < c[1] and c[2] >= a.y:
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
