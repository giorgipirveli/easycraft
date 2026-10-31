class_name WonderBuildsNew
extends RefCounted
## The blocks of the second tour in world 41, the New Seven Wonders (owner #78, spec §24), as pure rules: each built in
## its own frame (WonderBuilds.Frame: its front toward -z, y up from the tour's ground) and turned into the world by
## WonderBuilds, which buckets them with the first tour's. Recognisable from the real ones' shapes and colours in our own
## blocks (§3c: WondersBlocks' pages 36-37, the first tour's marble, white stone, gold leaf and fire, the game's own
## sand, grass, hay, leaves and water), at a size a child walks round, walks into where the real one can be entered and
## climbs where it is safe (the tests walk every way in).
##   Great Wall: a wall of grey bricks along a ridge (NewSevenGround), its walkway rising and falling, a low parapet on the
##     inner (south) side and battlements on the outer (north), five watchtowers the walkway passes through (arrow
##     windows, battlements on their roofs, a beacon fire on the east one), a stair up to the middle tower.
##   Petra: a cliff of rose rock, the Siq (a narrow winding gorge open to the sky) to a court before the Treasury's
##     facade (six columns, a pediment, the round tholos with the urn on top), its door into a plain chamber, and a stair
##     cut in the rock up to a ledge by the urn.
##   Colosseum: an oval of travertine, three storeys of arches and a top storey on the north side, only two storeys on
##     the broken south side (as today); an arena of sand, a ring of tiers rising round it, a corridor under them, four
##     entrances on its axes and stairs up the tiers.
##   Chichen Itza: El Castillo, nine terraces of Maya stone, a stair up each side (18 steps here; 91 on the real one)
##     with balustrades, the feathered serpent's heads at the foot of the north stair, the temple on top with its carved
##     band and its doors.
##   Machu Picchu: six terraces of Inca stone with grass on them, a stair up the middle to the plaza, stone houses with
##     thatched roofs, the Temple of the Sun's curved tower on its rock, the Temple of the Three Windows, the
##     Intihuatana stone on its knoll, Huayna Picchu behind (NewSevenGround).
##   Taj Mahal: the red sandstone gate with its arch, the garden with its long pool, walks, a marble pool and cypresses,
##     the marble plinth, the tomb with a great arch on each side, the hall with the two tombs under a lamp, the onion
##     dome with its golden top, four small domed kiosks, four minarets (one hollow with a spiral stair), the river.
##   Christ the Redeemer: a stair of 40 steps up Corcovado (NewSevenGround), the summit's terrace with a low wall, the
##     pedestal, and the statue of soapstone with its arms spread wide, facing the square.

const AIR := BlockIds.AIR


# --- The Great Wall of China ---

static func great_wall(b: WonderBuilds.Frame) -> void:
	var g := NewSevenGround
	var half := g.WALL_HALF
	# the wall's body, a run of equal walkway heights at a time, its inner parapet and its outer battlements' wall
	var x := -half
	while x <= half:
		var h := g.wall_walk(x)
		var x1 := x
		while x1 + 1 <= half and g.wall_walk(x1 + 1) == h:
			x1 += 1
		b.box(Vector3i(x, 0, -3), Vector3i(x1, h - 1, 2), BlockIds.WALL_BRICK)
		b.box(Vector3i(x, h, -3), Vector3i(x1, h, -3), BlockIds.WALL_BRICK)
		b.box(Vector3i(x, h, 2), Vector3i(x1, h, 2), BlockIds.WALL_BRICK)
		x = x1 + 1
	for xm in range(-half, half + 1, 2):   # merlons: the battlements face north, where raiders came from
		b.cell(Vector3i(xm, g.wall_walk(xm) + 1, 2), BlockIds.WALL_BRICK)
	for s: int in [-1, 1]:   # the wall's broken ends: a parapet across (no fall off the end)
		b.box(Vector3i(half * s, g.wall_walk(half * s), -2), Vector3i(half * s, g.wall_walk(half * s), 1), BlockIds.WALL_BRICK)
	for t: int in g.WALL_TOWERS:
		_watchtower(b, t, t == g.WALL_TOWERS[0])   # frame -x is world east (the wall faces south)
	# the stair up to the middle tower's south door
	var h0 := g.wall_walk(0)
	for j in h0:
		var z := -5 - (h0 - 1 - j)
		b.box(Vector3i(-1, 0, z), Vector3i(1, j, z), BlockIds.WALL_BRICK)
		b.box(Vector3i(-1, j + 1, z), Vector3i(1, j + 3, z), AIR)
		for s: int in [-2, 2]:
			b.box(Vector3i(s, 0, z), Vector3i(s, j + 1, z), BlockIds.WALL_BRICK)
	b.box(Vector3i(-1, h0, -4), Vector3i(1, h0 + 2, -4), AIR)


## A watchtower at the wall's frame x `t`: its base, a room the walkway passes through (doorways east and west, arrow
## windows north and south, a lamp), a roof with battlements; `beacon`: a signal fire on its roof.
static func _watchtower(b: WonderBuilds.Frame, t: int, beacon: bool) -> void:
	var h := NewSevenGround.wall_walk(t)
	var r := NewSevenGround.TOWER_HALF
	b.box(Vector3i(t - r, 0, -4), Vector3i(t + r, h + 3, 3), BlockIds.WALL_BRICK)
	b.box(Vector3i(t - r + 1, h, -3), Vector3i(t + r - 1, h + 3, 2), AIR)
	for s: int in [-1, 1]:
		b.box(Vector3i(t + r * s, h, -2), Vector3i(t + r * s, h + 2, 1), AIR)
	for wx: int in [t - 1, t + 1]:
		b.box(Vector3i(wx, h + 1, 3), Vector3i(wx, h + 2, 3), AIR)
		b.box(Vector3i(wx, h + 1, -4), Vector3i(wx, h + 2, -4), AIR)
	b.cell(Vector3i(t, h + 2, 3), BlockIds.DESERT_LAMP)
	b.box(Vector3i(t - r, h + 4, -4), Vector3i(t + r, h + 4, 3), BlockIds.WALL_BRICK)
	for i in range(-r, r + 1, 2):
		b.cell(Vector3i(t + i, h + 5, -4), BlockIds.WALL_BRICK)
		b.cell(Vector3i(t + i, h + 5, 3), BlockIds.WALL_BRICK)
	for z in range(-4, 4, 2):
		b.cell(Vector3i(t - r, h + 5, z), BlockIds.WALL_BRICK)
		b.cell(Vector3i(t + r, h + 5, z), BlockIds.WALL_BRICK)
	if beacon:
		b.cell(Vector3i(t, h + 5, 0), BlockIds.BEACON_FIRE)


# --- Petra ---

## The Treasury's face (the court ends one block before it) and the ledge by its urn (feet on it).
const PETRA_FACE := 14
const PETRA_LEDGE := 25
## The cliff's ribs: (x from, x to, top, front z); the ones round the Treasury stand over its urn.
const PETRA_RIBS: Array[Vector4i] = [Vector4i(-25, -21, 24, -23), Vector4i(-20, -16, 28, -24), Vector4i(-15, -11, 31, -22),
	Vector4i(-10, -6, 33, -24), Vector4i(-5, -1, 30, -24), Vector4i(0, 4, 32, -23), Vector4i(5, 9, 34, -24),
	Vector4i(10, 14, 30, -22), Vector4i(15, 19, 27, -24), Vector4i(20, 25, 23, -23)]


static func petra(b: WonderBuilds.Frame) -> void:
	var rock := BlockIds.ROSE_ROCK
	for s: Vector4i in PETRA_RIBS:   # the cliff: weathered ribs of rock, each its own height and depth
		b.box(Vector3i(s.x, 0, s.w), Vector3i(s.y, s.z, 26), rock)
	b.box(Vector3i(-14, 34, 2), Vector3i(-4, 35, 20), rock)   # knobs on its top
	b.box(Vector3i(3, 35, -2), Vector3i(9, 36, 12), rock)
	b.box(Vector3i(-25, 17, -24), Vector3i(-19, 34, -18), AIR)   # worn corners
	b.box(Vector3i(19, 19, -24), Vector3i(25, 34, -15), AIR)
	b.box(Vector3i(-12, 26, -24), Vector3i(-8, 34, -21), AIR)
	# the Siq: a narrow winding gorge from the front to the court, open to the sky
	b.box(Vector3i(-1, 0, -24), Vector3i(1, 40, -14), AIR)
	b.box(Vector3i(1, 0, -14), Vector3i(4, 40, -8), AIR)
	b.box(Vector3i(-2, 0, -8), Vector3i(2, 40, -1), AIR)
	b.box(Vector3i(-1, 0, -1), Vector3i(1, 40, 5), AIR)
	b.box(Vector3i(-10, 0, 0), Vector3i(10, 40, PETRA_FACE - 1), AIR)   # the court before the Treasury
	_treasury(b)
	_petra_stair(b)


## The Treasury's facade, carved out of the cliff: the porch of six columns, the entablature and pediment, the door into
## its plain chamber; the upper storey's recess with the round tholos, the side pavilions' columns and half-pediments, the
## urn on top.
static func _treasury(b: WonderBuilds.Frame) -> void:
	var f := PETRA_FACE
	var stone := BlockIds.ROSE_STONE
	var col := BlockIds.ROSE_COLUMN
	b.box(Vector3i(-7, 0, f), Vector3i(7, 9, f + 2), AIR)   # the porch
	for x: int in [-8, -5, -2, 2, 5, 8]:
		b.box(Vector3i(x, 0, f), Vector3i(x, 9, f), col)
	b.box(Vector3i(-9, 10, f - 1), Vector3i(9, 11, f), stone)   # the entablature
	b.box(Vector3i(-5, 12, f - 1), Vector3i(5, 12, f), stone)   # the pediment
	b.box(Vector3i(-3, 13, f - 1), Vector3i(3, 13, f), stone)
	b.box(Vector3i(-1, 14, f - 1), Vector3i(1, 14, f), stone)
	b.box(Vector3i(-1, 0, f + 3), Vector3i(1, 4, f + 3), AIR)   # the door
	b.box(Vector3i(-4, 0, f + 4), Vector3i(4, 6, f + 10), AIR)   # the chamber
	b.cell(Vector3i(0, 5, f + 10), BlockIds.DESERT_LAMP)
	b.box(Vector3i(-8, 16, f), Vector3i(8, 24, f + 1), AIR)   # the upper storey's recess
	b.box(Vector3i(-9, 15, f - 1), Vector3i(9, 15, f), stone)
	b.box(Vector3i(-2, 16, f + 1), Vector3i(2, 22, f + 1), stone)   # the tholos: its drum and columns
	b.box(Vector3i(-1, 16, f), Vector3i(1, 22, f), stone)
	for x: int in [-3, 3, -8, -6, 6, 8]:
		b.box(Vector3i(x, 16, f), Vector3i(x, 22, f), col)
	b.box(Vector3i(-8, 23, f), Vector3i(-5, 23, f), stone)   # the half-pediments
	b.box(Vector3i(-8, 24, f), Vector3i(-7, 24, f), stone)
	b.box(Vector3i(5, 23, f), Vector3i(8, 23, f), stone)
	b.box(Vector3i(7, 24, f), Vector3i(8, 24, f), stone)
	b.box(Vector3i(-2, 23, f), Vector3i(2, 23, f + 1), stone)   # the tholos's roof ...
	b.box(Vector3i(-1, 24, f), Vector3i(1, 24, f + 1), stone)
	b.box(Vector3i(0, PETRA_LEDGE, f), Vector3i(0, PETRA_LEDGE + 2, f), stone)   # ... and the urn (solid rock)


## A stair cut in the rock up the court's east side: a flight back into the cliff, a landing, a flight forward, a way
## out onto a ledge along the facade by the urn (a low wall on its edge).
static func _petra_stair(b: WonderBuilds.Frame) -> void:
	var f := PETRA_FACE
	for j in 18:   # flight 1: x 11..12, back into the cliff
		var z := 6 + j
		b.box(Vector3i(11, 0, z), Vector3i(12, j, z), BlockIds.ROSE_ROCK)
		b.box(Vector3i(11, j + 1, z), Vector3i(12, j + 3, z), AIR)
	b.box(Vector3i(11, 18, 24), Vector3i(14, 20, 25), AIR)   # the landing (feet 18)
	var top := PETRA_LEDGE - 1
	for j in top - 17:   # flight 2: x 13..14, forward, up to the ledge's level
		var z := 23 - j
		b.box(Vector3i(13, 0, z), Vector3i(14, 18 + j, z), BlockIds.ROSE_ROCK)
		b.box(Vector3i(13, 19 + j, z), Vector3i(14, 21 + j, z), AIR)
	var z_end := 23 - (top - 18)
	b.box(Vector3i(13, PETRA_LEDGE, f - 1), Vector3i(14, PETRA_LEDGE + 2, z_end), AIR)   # the way out
	b.box(Vector3i(10, PETRA_LEDGE, f - 1), Vector3i(12, PETRA_LEDGE + 2, f - 1), AIR)
	b.box(Vector3i(-10, PETRA_LEDGE - 1, f - 1), Vector3i(12, PETRA_LEDGE - 1, f - 1), BlockIds.ROSE_STONE)   # the ledge
	b.box(Vector3i(-10, PETRA_LEDGE, f - 2), Vector3i(10, PETRA_LEDGE, f - 2), BlockIds.ROSE_STONE)   # its low wall
	b.box(Vector3i(-10, PETRA_LEDGE, f - 1), Vector3i(-10, PETRA_LEDGE, f - 1), BlockIds.ROSE_STONE)


# --- The Colosseum ---

## Its outer oval's half sizes (frame z along, its long way east-west; frame x across) and its arena's.
const COL_A := 29.0
const COL_B := 24.0
const ARENA := Vector2(15.0, 9.0)
const TIERS := 10
const TOP_TIER := 13   # feet on the walk behind the top tier
const ARCHES := 36


static func colosseum(b: WonderBuilds.Frame) -> void:
	var trav := BlockIds.TRAVERTINE
	# the seating's mass inside the outer wall, then carved: the tiers, the arena, the corridor under them
	_oval(b, COL_A - 2, COL_B - 2, 0, TOP_TIER - 1, trav)
	for k in range(1, TIERS + 1):
		var e := tier(k)
		_oval(b, e.x, e.y, 2 + k, TOP_TIER, AIR)
	_oval(b, ARENA.x, ARENA.y, 0, TOP_TIER, AIR)
	_oval(b, ARENA.x, ARENA.y, -1, -1, BlockIds.SAND)
	_oval_ring(b, COL_A - 2, COL_B - 2, 3, 0, 2, AIR)   # the corridor under the tiers
	# the outer wall: four storeys on the north side, three, then two on the broken south side (frame +x is south)
	for row: Array in _oval_rows(COL_A, COL_B):
		var x: int = row[0]
		var top := 15 if x <= 4 else (11 if x <= 9 else 7)
		for run: Vector2i in _ring_runs(x, COL_A, COL_B, 2):
			b.box(Vector3i(x, 0, run.x), Vector3i(x, top, run.y), trav)
	# the arches of the three lower storeys (the top storey is a solid wall)
	for arch: Rect2i in arch_rects():
		for s in 3:
			if s == 2 and arch.end.x - 1 > 9:
				continue   # the broken south side has no third storey
			b.box(Vector3i(arch.position.x, 4 * s, arch.position.y), Vector3i(arch.end.x - 1, 4 * s + 2, arch.end.y - 1), AIR)
	# the four entrances on its axes, and stairs up the tiers beside the north and south ones
	b.box(Vector3i(-1, 0, -int(COL_A)), Vector3i(1, 2, int(COL_A)), AIR)
	b.box(Vector3i(-int(COL_B), 0, -1), Vector3i(int(COL_B), 2, 1), AIR)
	for s: int in [-1, 1]:
		for j in TOP_TIER:
			var x := s * (10 + j)
			b.box(Vector3i(x, maxi(j - 1, 0), 2), Vector3i(x, j, 4), trav)
			b.box(Vector3i(x, j + 1, 2), Vector3i(x, j + 3, 4), AIR)
	for row: Array in _oval_rows(COL_A - 2, COL_B - 2):   # a railing on the top walk where the outer wall broke off
		var x: int = row[0]
		if x >= 5:
			for run: Vector2i in _ring_runs(x, COL_A - 2, COL_B - 2, 1):
				b.box(Vector3i(x, TOP_TIER, run.x), Vector3i(x, TOP_TIER, run.y), trav)


## Tier k's inner edge (half sizes along z, across x): from the arena's edge (k 0) out to the walk behind the top tier.
static func tier(k: int) -> Vector2:
	return ARENA.lerp(Vector2(COL_A - 4, COL_B - 4), float(k) / TIERS)


## The outer wall's arches: each a frame rect (x, z) of the wall's cells in its slice of the oval.
static func arch_rects() -> Array[Rect2i]:
	var cells := {}
	for row: Array in _oval_rows(COL_A, COL_B):
		var x: int = row[0]
		for run: Vector2i in _ring_runs(x, COL_A, COL_B, 2):
			for z in range(run.x, run.y + 1):
				var a := fposmod(atan2(z / COL_A, x / COL_B) / TAU * ARCHES, float(ARCHES))
				var k := floori(a)
				var frac := a - k
				if frac < 0.25 or frac > 0.75:
					continue
				if not cells.has(k):
					cells[k] = Rect2i(x, z, 1, 1)
				else:
					cells[k] = (cells[k] as Rect2i).expand(Vector2i(x, z)).expand(Vector2i(x + 1, z + 1))
	var out: Array[Rect2i] = []
	for k: int in cells:
		var r: Rect2i = cells[k]
		if absi(r.position.x + r.size.x / 2) <= 1 or absi(r.position.y + r.size.y / 2) <= 1:
			continue   # the axes' entrances are there
		out.append(r)
	return out


## The oval's rows: [x, half length along z] for each x across it.
static func _oval_rows(a: float, b: float) -> Array:
	var out: Array = []
	for x in range(-floori(b), floori(b) + 1):
		var k := 1.0 - pow(x / (b + 0.5), 2.0)
		if k < 0.0:
			continue
		out.append([x, floori((a + 0.5) * sqrt(k))])
	return out


## A filled oval (half sizes a along z, b across x) from y0 to y1.
static func _oval(bf: WonderBuilds.Frame, a: float, b: float, y0: int, y1: int, block: int) -> void:
	for row: Array in _oval_rows(a, b):
		bf.box(Vector3i(row[0], y0, -int(row[1])), Vector3i(row[0], y1, int(row[1])), block)


## An oval ring `thick` blocks thick inside the oval (a, b), from y0 to y1.
static func _oval_ring(bf: WonderBuilds.Frame, a: float, b: float, thick: int, y0: int, y1: int, block: int) -> void:
	for row: Array in _oval_rows(a, b):
		for run: Vector2i in _ring_runs(row[0], a, b, thick):
			bf.box(Vector3i(row[0], y0, run.x), Vector3i(row[0], y1, run.y), block)


## The z runs (inclusive) of row x of the ring between the oval (a, b) and the one `thick` smaller.
static func _ring_runs(x: int, a: float, b: float, thick: int) -> Array[Vector2i]:
	var ko := 1.0 - pow(x / (b + 0.5), 2.0)
	if ko < 0.0:
		return [] as Array[Vector2i]
	var zo := floori((a + 0.5) * sqrt(ko))
	var ki := 1.0 - pow(x / (b - thick + 0.5), 2.0)
	if ki < 0.0:
		return [Vector2i(-zo, zo)] as Array[Vector2i]
	var zi := floori((a - thick + 0.5) * sqrt(ki))
	return [Vector2i(-zo, -zi - 1), Vector2i(zi + 1, zo)] as Array[Vector2i]


# --- Chichen Itza: El Castillo ---

## Its nine terraces' half sizes (each 2 high), the last one the platform the temple stands on.
const CASTILLO_TERRACES: Array[int] = [19, 17, 16, 14, 13, 11, 10, 8, 7]
const CASTILLO_STEPS := 18
const CASTILLO_TOP := 18   # feet on the platform


static func chichen_itza(b: WonderBuilds.Frame) -> void:
	var stone := BlockIds.MAYA_STONE
	for k in CASTILLO_TERRACES.size():
		var h: int = CASTILLO_TERRACES[k]
		b.box(Vector3i(-h, 2 * k, -h), Vector3i(h, 2 * k + 1, h), stone)
	for side in 4:   # a stair up each side, balustrades one step higher
		for j in CASTILLO_STEPS:
			var d := 25 - j
			_quarter_box(b, side, Vector3i(-2, 0, -d), Vector3i(2, j, -d), stone)
			_quarter_box(b, side, Vector3i(-3, 0, -d), Vector3i(-3, j + 1, -d), stone)
			_quarter_box(b, side, Vector3i(3, 0, -d), Vector3i(3, j + 1, -d), stone)
	for s: int in [-3, 3]:   # the feathered serpent's heads at the foot of the north stair
		b.box(Vector3i(s, 0, -26), Vector3i(s, 1, -26), BlockIds.SERPENT_HEAD)
	var t := CASTILLO_TOP   # the temple on top: its walls, the carved band, the roof and its crest, its doors
	b.box(Vector3i(-4, t, -4), Vector3i(4, t + 4, 4), stone)
	b.box(Vector3i(-3, t, -3), Vector3i(3, t + 3, 3), AIR)
	b.ring(-4, 4, -4, 4, t + 4, BlockIds.MAYA_CARVING)
	b.box(Vector3i(-4, t + 5, -4), Vector3i(4, t + 5, 4), stone)
	for i in range(-3, 4, 2):
		b.cell(Vector3i(i, t + 6, 0), stone)
	b.box(Vector3i(-1, t, -4), Vector3i(1, t + 2, -4), AIR)   # the wide north door
	for s: int in [-2, 2]:
		b.cell(Vector3i(s, t, -5), BlockIds.SERPENT_HEAD)
	b.box(Vector3i(0, t, 4), Vector3i(0, t + 2, 4), AIR)
	b.box(Vector3i(4, t, 0), Vector3i(4, t + 2, 0), AIR)
	b.box(Vector3i(-4, t, 0), Vector3i(-4, t + 2, 0), AIR)
	b.cell(Vector3i(0, t + 3, 3), BlockIds.DESERT_LAMP)


## A box given for the north side, turned a quarter at a time round the middle (0 north, 1 east, 2 south, 3 west).
static func _quarter_box(b: WonderBuilds.Frame, side: int, p: Vector3i, q: Vector3i, block: int) -> void:
	b.box(_quarter(p, side), _quarter(q, side), block)


static func _quarter(v: Vector3i, side: int) -> Vector3i:
	match side:
		1:
			return Vector3i(-v.z, v.y, v.x)
		2:
			return Vector3i(-v.x, v.y, -v.z)
		3:
			return Vector3i(v.z, v.y, -v.x)
	return v


# --- Machu Picchu ---

const MACHU_TERRACES := 6
const MACHU_TOP := 12   # feet on the plaza


## Terrace k's rect (frame x, z; inclusive): 2 in at the front and sides, 1 at the back; its grass at y 2k + 1.
static func machu_terrace(k: int) -> Rect2i:
	var hx := 30 - 2 * k
	return Rect2i(-hx, -(22 - 2 * k), 2 * hx + 1, 22 - k + 22 - 2 * k + 1)


static func machu_picchu(b: WonderBuilds.Frame) -> void:
	var stone := BlockIds.INCA_STONE
	for k in MACHU_TERRACES:
		var r := machu_terrace(k)
		b.box(Vector3i(r.position.x, 0, r.position.y), Vector3i(r.end.x - 1, 2 * k, r.end.y - 1), stone)
		b.box(Vector3i(r.position.x, 2 * k + 1, r.position.y), Vector3i(r.end.x - 1, 2 * k + 1, r.end.y - 1), BlockIds.GRASS)
	for j in MACHU_TOP:   # the stair up the middle, cut through the terraces
		var z := -23 + j
		b.box(Vector3i(-1, maxi(j - 1, 0), z), Vector3i(1, j, z), stone)
		b.box(Vector3i(-1, j + 1, z), Vector3i(1, j + 3, z), AIR)
	var y := MACHU_TOP
	for xc: int in [10, 16]:   # houses east of the plaza: stone walls, a door, a window, thatched gabled roofs
		for zc: int in [-8, -1, 6]:
			b.box(Vector3i(xc - 2, y, zc - 2), Vector3i(xc + 2, y + 2, zc + 2), stone)
			b.box(Vector3i(xc - 1, y, zc - 1), Vector3i(xc + 1, y + 2, zc + 1), AIR)
			b.box(Vector3i(xc - 2, y, zc), Vector3i(xc - 2, y + 1, zc), AIR)
			b.cell(Vector3i(xc + 2, y + 1, zc), AIR)
			b.box(Vector3i(xc - 2, y + 3, zc - 2), Vector3i(xc + 2, y + 3, zc + 2), BlockIds.HAY)
			b.box(Vector3i(xc - 1, y + 4, zc - 2), Vector3i(xc + 1, y + 4, zc + 2), BlockIds.HAY)
			b.box(Vector3i(xc, y + 5, zc - 2), Vector3i(xc, y + 5, zc + 2), BlockIds.HAY)
	_temple_of_the_sun(b, y)
	# the Temple of the Three Windows: a wall with three windows looking east, two side walls
	b.box(Vector3i(-19, y, 0), Vector3i(-19, y + 4, 8), stone)
	b.box(Vector3i(-19, y, 0), Vector3i(-15, y + 3, 0), stone)
	b.box(Vector3i(-19, y, 8), Vector3i(-15, y + 3, 8), stone)
	for z: int in [2, 4, 6]:
		b.box(Vector3i(-19, y + 1, z), Vector3i(-19, y + 2, z), AIR)
	# the Intihuatana stone on its knoll
	b.box(Vector3i(-16, y, 10), Vector3i(-8, y, 16), stone)
	b.box(Vector3i(-15, y + 1, 11), Vector3i(-9, y + 1, 15), stone)
	b.box(Vector3i(-14, y + 2, 12), Vector3i(-10, y + 2, 14), stone)
	b.box(Vector3i(-12, y + 3, 13), Vector3i(-12, y + 4, 13), stone)


## The Temple of the Sun: its curved tower (a D of fine stone) on a rock, the rock's east face walled with Inca stone
## (the cave under it: WondersSecretRules).
static func _temple_of_the_sun(b: WonderBuilds.Frame, y: int) -> void:
	b.box(Vector3i(-17, y, -9), Vector3i(-10, y + 3, -2), BlockIds.STONE)
	b.box(Vector3i(-10, y, -8), Vector3i(-10, y + 3, -3), BlockIds.INCA_STONE)
	var c := Vector2(-13.5, -5.5)
	for x in range(-17, -10):
		for z in range(-9, -1):
			var d := Vector2(x, z).distance_to(c)
			if (d >= 2.2 and d <= 3.5 and x <= -13) or (x == -11 and z >= -8 and z <= -3):
				b.box(Vector3i(x, y + 4, z), Vector3i(x, y + 7, z), BlockIds.INCA_STONE)
	b.box(Vector3i(-16, y + 6, -5), Vector3i(-16, y + 6, -5), AIR)   # its two small windows
	b.box(Vector3i(-14, y + 6, -8), Vector3i(-14, y + 6, -8), AIR)


# --- The Taj Mahal ---

## The tomb's middle (frame z), its feet on the plinth, the treasure minaret's place and its stair.
const TAJ_TOMB := 13
const TAJ_FLOOR := 3
const TAJ_MINARETS: Array[Vector2i] = [Vector2i(-13, 0), Vector2i(13, 0), Vector2i(-13, 26), Vector2i(13, 26)]
const TAJ_HOLLOW := Vector2i(13, 26)
const MINARET_FLOOR := 21   # the top balcony's floor (feet one higher)
const MINARET_STEPS := 19
const DOME: Array[int] = [6, 7, 7, 7, 7, 6, 6, 5, 4, 3, 2, 1]   # the onion dome's radius from y 20 up


static func taj_mahal(b: WonderBuilds.Frame) -> void:
	_taj_gate(b)
	_taj_garden(b)
	var marble := BlockIds.MARBLE
	b.box(Vector3i(-15, 0, -2), Vector3i(15, 2, 28), marble)   # the plinth, a band of inlaid marble round it
	b.ring(-15, 15, -2, 28, 1, BlockIds.INLAID_MARBLE)
	for j in 3:
		b.box(Vector3i(-2, 0, -5 + j), Vector3i(2, j, -5 + j), marble)
	_taj_tomb(b)
	for m: Vector2i in TAJ_MINARETS:
		_minaret(b, m, m == TAJ_HOLLOW)
	b.box(Vector3i(-22, -3, 34), Vector3i(22, -1, 38), BlockIds.WATER)   # the river behind (the real one's Yamuna)


## The great gate of red sandstone: its arch through, the arch's marble frame, small white domes along its top.
static func _taj_gate(b: WonderBuilds.Frame) -> void:
	b.box(Vector3i(-8, 0, -44), Vector3i(8, 11, -38), BlockIds.MUGHAL_RED)
	b.box(Vector3i(-2, 0, -44), Vector3i(2, 5, -38), AIR)
	b.box(Vector3i(-3, 0, -44), Vector3i(3, 8, -43), AIR)
	b.box(Vector3i(-3, 0, -39), Vector3i(3, 8, -38), AIR)
	for z: int in [-44, -38]:
		b.box(Vector3i(-4, 9, z), Vector3i(4, 9, z), BlockIds.INLAID_MARBLE)
		b.box(Vector3i(-4, 0, z), Vector3i(-4, 8, z), BlockIds.INLAID_MARBLE)
		b.box(Vector3i(4, 0, z), Vector3i(4, 8, z), BlockIds.INLAID_MARBLE)
	for x in range(-7, 8, 2):
		b.cell(Vector3i(x, 12, -41), BlockIds.MARBLE)
		b.cell(Vector3i(x, 13, -41), BlockIds.GOLD_LEAF)
	for x: int in [-8, 8]:
		for z: int in [-44, -38]:
			b.box(Vector3i(x, 12, z), Vector3i(x, 13, z), BlockIds.MARBLE)
			b.cell(Vector3i(x, 14, z), BlockIds.GOLD_LEAF)


## The garden: the central walk with its long water channel, the cross walk, the raised marble pool in the middle, rows
## of cypresses.
static func _taj_garden(b: WonderBuilds.Frame) -> void:
	b.box(Vector3i(-3, -1, -37), Vector3i(3, -1, -3), BlockIds.PAVING)
	b.box(Vector3i(-16, -1, -21), Vector3i(16, -1, -19), BlockIds.PAVING)
	b.box(Vector3i(-1, -1, -36), Vector3i(1, -1, -4), BlockIds.WATER)
	b.box(Vector3i(-4, -1, -24), Vector3i(4, -1, -16), BlockIds.MARBLE)
	b.ring(-4, 4, -24, -16, 0, BlockIds.MARBLE)
	b.box(Vector3i(-3, 0, -23), Vector3i(3, 0, -17), BlockIds.WATER)
	for z in range(-35, -4, 4):
		if absi(z + 20) <= 5:
			continue
		for x: int in [-5, 5]:
			b.cell(Vector3i(x, 0, z), BlockIds.LOG)
			b.box(Vector3i(x, 1, z), Vector3i(x, 5, z), BlockIds.DARK_LEAVES)


## The tomb: its eight-sided walls, a great arch on each side (an inlaid frame round it, a door at its back), the hall
## with the two tombs under a hanging lamp, the drum, the onion dome and its golden top, four small domed kiosks.
static func _taj_tomb(b: WonderBuilds.Frame) -> void:
	var c := TAJ_TOMB
	var f := TAJ_FLOOR
	var marble := BlockIds.MARBLE
	var inlay := BlockIds.INLAID_MARBLE
	_oct(b, 0, c, 9, 3, f, 16, marble)
	_oct(b, 0, c, 5, 2, f, 11, AIR)
	for s: int in [-1, 1]:   # the arches front and back (z), then the sides (x)
		var z := c + 9 * s
		b.box(Vector3i(-3, f, z - s), Vector3i(3, f + 9, z), AIR)
		b.box(Vector3i(-4, f, z), Vector3i(-4, f + 10, z), inlay)
		b.box(Vector3i(4, f, z), Vector3i(4, f + 10, z), inlay)
		b.box(Vector3i(-4, f + 10, z), Vector3i(4, f + 10, z), inlay)
		b.box(Vector3i(-1, f, z - 3 * s), Vector3i(1, f + 3, z - 2 * s), AIR)
		var x := 9 * s
		b.box(Vector3i(x - s, f, c - 3), Vector3i(x, f + 9, c + 3), AIR)
		b.box(Vector3i(x, f, c - 4), Vector3i(x, f + 10, c - 4), inlay)
		b.box(Vector3i(x, f, c + 4), Vector3i(x, f + 10, c + 4), inlay)
		b.box(Vector3i(x, f + 10, c - 4), Vector3i(x, f + 10, c + 4), inlay)
		b.box(Vector3i(x - 3 * s, f, c - 1), Vector3i(x - 2 * s, f + 3, c + 1), AIR)
	b.box(Vector3i(0, f, c - 1), Vector3i(0, f, c + 1), inlay)   # Mumtaz Mahal's tomb in the middle ...
	b.box(Vector3i(2, f, c - 1), Vector3i(2, f, c + 1), inlay)   # ... Shah Jahan's beside it
	b.cell(Vector3i(0, f + 8, c), BlockIds.DESERT_LAMP)   # the lamp hanging over them
	_disc(b, 0, c, 5, 17, 19, marble)   # the drum
	for i in DOME.size():
		_disc(b, 0, c, DOME[i], 20 + i, 20 + i, marble)
	b.box(Vector3i(0, 20 + DOME.size(), c), Vector3i(0, 23 + DOME.size(), c), BlockIds.GOLD_LEAF)
	for sx: int in [-6, 6]:   # the kiosks round the dome
		for sz: int in [-6, 6]:
			var k := Vector2i(sx, c + sz)
			for p: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				b.box(Vector3i(k.x + p.x, 17, k.y + p.y), Vector3i(k.x + p.x, 18, k.y + p.y), marble)
			b.box(Vector3i(k.x - 1, 19, k.y - 1), Vector3i(k.x + 1, 19, k.y + 1), marble)
			b.cell(Vector3i(k.x, 20, k.y), marble)
			b.cell(Vector3i(k.x, 21, k.y), BlockIds.GOLD_LEAF)


## A minaret at `m` on the plinth: eight-sided, three balconies, a small domed kiosk on top; `hollow`: a spiral stair
## round a pillar inside (in at a door facing the tomb) up to the top balcony.
static func _minaret(b: WonderBuilds.Frame, m: Vector2i, hollow: bool) -> void:
	var f := TAJ_FLOOR
	var marble := BlockIds.MARBLE
	var top := MINARET_FLOOR
	_oct(b, m.x, m.y, 2, 1, f, top - 1, marble)
	for y: int in [9, 15, top]:
		_oct(b, m.x, m.y, 3, 1, y, y, marble)
	_oct(b, m.x, m.y, 3, 1, top + 1, top + 1, marble)   # the top balcony's low wall
	_oct(b, m.x, m.y, 2, 1, top + 1, top + 1, AIR)
	for p: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)]:   # the kiosk's posts
		b.box(Vector3i(m.x + p.x, top + 1, m.y + p.y), Vector3i(m.x + p.x, top + 2, m.y + p.y), marble)
	_oct(b, m.x, m.y, 2, 1, top + 3, top + 3, marble)
	b.cell(Vector3i(m.x, top + 4, m.y), marble)
	b.cell(Vector3i(m.x, top + 5, m.y), BlockIds.GOLD_LEAF)
	if not hollow:
		return
	b.box(Vector3i(m.x - 1, f, m.y - 1), Vector3i(m.x + 1, top - 1, m.y + 1), AIR)
	b.box(Vector3i(m.x, f, m.y), Vector3i(m.x, top - 1, m.y), marble)
	var door := -signi(m.x)
	b.box(Vector3i(m.x + 2 * door, f, m.y), Vector3i(m.x + 2 * door, f + 1, m.y), AIR)
	var shaft := WonderBuilds.SHAFT
	for k in MINARET_STEPS:
		var s: Vector2i = shaft[k % shaft.size()]
		b.cell(Vector3i(m.x + s.x, f + k, m.y + s.y), marble)
	for k in range(MINARET_STEPS - 4, MINARET_STEPS - 1):   # room over the head up the last steps
		var s: Vector2i = shaft[k % shaft.size()]
		b.cell(Vector3i(m.x + s.x, top, m.y + s.y), AIR)


## An eight-sided slab centred (cx, cz), half size h, corners cut by `cut`, from y0 to y1.
static func _oct(b: WonderBuilds.Frame, cx: int, cz: int, h: int, cut: int, y0: int, y1: int, block: int) -> void:
	for i in cut + 1:
		b.box(Vector3i(cx - h + i, y0, cz - h + cut - i), Vector3i(cx + h - i, y1, cz + h - cut + i), block)


## A round disc of radius r centred (cx, cz), from y0 to y1 (a row of boxes).
static func _disc(b: WonderBuilds.Frame, cx: int, cz: int, r: int, y0: int, y1: int, block: int) -> void:
	for dz in range(-r, r + 1):
		var hw := int(sqrt((r + 0.5) * (r + 0.5) - dz * dz))
		b.box(Vector3i(cx - hw, y0, cz + dz), Vector3i(cx + hw, y1, cz + dz), block)


# --- Christ the Redeemer ---

const CHRIST_STAIR_FOOT := -46   # the stair's first step (frame z); its last lands on the summit
const SUMMIT_R := 8
const PEDESTAL := 6              # the pedestal's height over the summit


## The statue's foot (frame y): on the pedestal on the summit.
static func statue_foot() -> int:
	return NewSevenGround.CORCOVADO_TOP + PEDESTAL


static func christ_redeemer(b: WonderBuilds.Frame) -> void:
	var top := NewSevenGround.CORCOVADO_TOP
	var white := BlockIds.WHITE_BRICK
	_disc(b, 0, 0, SUMMIT_R, top - 9, top - 1, white)   # the summit's terrace ...
	_disc(b, 0, 0, SUMMIT_R, top, top + 3, AIR)
	for dz in range(-SUMMIT_R, SUMMIT_R + 1):   # ... and its low wall (open where the stair arrives)
		var hw := int(sqrt((SUMMIT_R + 0.5) * (SUMMIT_R + 0.5) - dz * dz))
		for x: int in [-hw, hw]:
			b.cell(Vector3i(x, top, dz), white)
	for dx in range(-SUMMIT_R, SUMMIT_R + 1):
		var hz := int(sqrt((SUMMIT_R + 0.5) * (SUMMIT_R + 0.5) - dx * dx))
		b.cell(Vector3i(dx, top, hz), white)
		if absi(dx) > 1:
			b.cell(Vector3i(dx, top, -hz), white)
	for j in top:   # the stair up Corcovado (cut into the terrace's edge at its top), a low wall each side
		var z := CHRIST_STAIR_FOOT + j
		b.box(Vector3i(-1, 0, z), Vector3i(1, j, z), white)
		b.box(Vector3i(-1, j + 1, z), Vector3i(1, j + 3, z), AIR)
		for s: int in [-2, 2]:
			b.box(Vector3i(s, 0, z), Vector3i(s, j + 1, z), white)
	b.box(Vector3i(-2, top, -2), Vector3i(2, top + PEDESTAL - 1, 2), white)   # the pedestal
	_statue(b, statue_foot())


## The statue of soapstone, facing -z (the square): the robe to the hem, the body, the arms spread wide with their
## sleeves, the hands, the neck and the head.
static func _statue(b: WonderBuilds.Frame, s: int) -> void:
	var soap := BlockIds.SOAPSTONE
	b.box(Vector3i(-3, s, -1), Vector3i(3, s + 2, 1), soap)
	b.box(Vector3i(-1, s, -2), Vector3i(1, s, -2), soap)
	b.box(Vector3i(-2, s + 3, -1), Vector3i(2, s + 19, 1), soap)
	b.box(Vector3i(-12, s + 17, -1), Vector3i(12, s + 18, 0), soap)
	b.box(Vector3i(-6, s + 14, -1), Vector3i(-3, s + 16, 0), soap)
	b.box(Vector3i(3, s + 14, -1), Vector3i(6, s + 16, 0), soap)
	b.box(Vector3i(-12, s + 16, -1), Vector3i(-11, s + 16, 0), soap)
	b.box(Vector3i(11, s + 16, -1), Vector3i(12, s + 16, 0), soap)
	b.box(Vector3i(-1, s + 20, -1), Vector3i(1, s + 20, 0), soap)
	b.box(Vector3i(-1, s + 21, -2), Vector3i(1, s + 23, 0), soap)
	b.box(Vector3i(-1, s + 24, -1), Vector3i(1, s + 24, 0), soap)
