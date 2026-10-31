class_name WonderBuilds
extends RefCounted
## The blocks of the wonders in world 41 (owner #78, spec §24), both tours (the New Seven's builds are WonderBuildsNew'),
## as pure rules: each wonder a list of boxes
## [lo, hi exclusive, block id] in world cells, filled in order (later ones win), recognisable from the real one's
## shape and colours in our own blocks (§3c), at a size a child walks round, walks into where the real one can be
## entered and climbs where it is safe (WonderTour says where each stands). Every build is drawn in its own frame (its
## front toward -z, y up from the tour's ground) and turned into the world. The landing square, the paths, the
## signposts, the plaques, the causeway's paving and the river, the New Seven's square and the Wonders Road (its speed
## pads) are the tours' own boxes (extras). The generator writes
## them chunk by chunk from buckets (column_boxes): the same everywhere, worked out once (seed-free, behind a mutex:
## the generator's threads share them). The wonders' secrets (hidden rooms, treasure) are WondersSecretRules', written
## after these.
##   Great Pyramid: 29 courses of limestone (a real pyramid's slope, about 52 degrees), casing stones at its foot, the
##     entrance on the north face (a step up to it), the corridor, the Queen's Chamber (a gabled room), the ascending
##     stairs, the Grand Gallery (tall, corbelled), the King's Chamber of pink granite with its stone box.
##   Hanging Gardens: four terraces of Babylon brick with blue glazed bands, gardens of grass, flowers, palms and
##     trailing plants, stairs up the middle, arches into a vaulted gallery, a water screw by a pool, a channel to a
##     pool on top.
##   Temple of Artemis: a marble platform of three steps, two rows of columns all round (about 90), a scrolled top on
##     each, the carved band, a tiled roof with pediments, the inner hall (its door to the west).
##   Statue of Zeus: its temple (6 by 13 columns, as the real one), the hall with galleries up stairs at its sides, the
##     black floor with a marble rim for olive oil, and Zeus on his throne of ebony and gold: ivory skin, a gold robe,
##     an olive wreath, Victory on his hand, a sceptre with an eagle, his head just under the roof.
##   Mausoleum: a podium with stairs, 36 columns round the tomb hall, the carved band, a stepped pyramid roof, and four
##     horses pulling a chariot on top.
##   Colossus: a white marble base with stairs, a bronze figure standing with its legs together, a cloak down to the
##     base, a crown of sun rays and a torch held high (as people imagine it).
##   Lighthouse: three tiers on the island (square, eight-sided, round) of white stone, stairs round a pillar inside the
##     first, a spiral up a shaft through the others, terraces with parapets, the fire at the top under a bronze roof.

const Y := WonderTour.BASE_Y
const CHUNK := 16

static var _mutex := Mutex.new()
static var _ready := false
static var _wonders := {}          # id -> Array of boxes
static var _extras: Array = []
static var _buckets := {}          # Vector2i (chunk column) -> Array of boxes
static var _bounds := {}           # id -> [lo, hi exclusive] of its own boxes


## Wonder `id`'s boxes (world cells).
static func boxes(id: StringName) -> Array:
	_build()
	return _wonders.get(id, [])


## The tour's own boxes: the landing square, paths, signposts, plaques, the causeway's paving, the river.
static func extras() -> Array:
	_build()
	return _extras


## Every box that reaches into the 16 x 16 chunk column (cx, cz) (chunk coordinates), in the order they are filled.
static func column_boxes(cx: int, cz: int) -> Array:
	_build()
	return _buckets.get(Vector2i(cx, cz), [])


## Wonder `id`'s bounds [lo, hi exclusive] (its own boxes).
static func bounds(id: StringName) -> Array:
	_build()
	return _bounds.get(id, [])


## The block the tour puts at p, or -1 where it puts nothing (the reference for tests and tools).
static func block_at(p: Vector3i) -> int:
	var list := column_boxes(floori(p.x / float(CHUNK)), floori(p.z / float(CHUNK)))
	for i in range(list.size() - 1, -1, -1):
		var b: Array = list[i]
		if _inside(b[0], b[1], p):
			return b[2]
	return -1


static func _inside(lo: Vector3i, hi: Vector3i, p: Vector3i) -> bool:
	return p.x >= lo.x and p.y >= lo.y and p.z >= lo.z and p.x < hi.x and p.y < hi.y and p.z < hi.z


static func _build() -> void:
	if _ready:
		return
	_mutex.lock()
	if not _ready:
		var w := {}
		for id: StringName in WonderTour.ids():
			var b := Frame.new(id)
			match id:
				&"pyramid":
					_pyramid(b)
				&"gardens":
					_gardens(b)
				&"artemis":
					_artemis(b)
				&"zeus":
					_zeus(b)
				&"mausoleum":
					_mausoleum(b)
				&"colossus":
					_colossus(b)
				&"lighthouse":
					_lighthouse(b)
				&"great_wall":   # the second tour, the New Seven Wonders (WonderBuildsNew)
					WonderBuildsNew.great_wall(b)
				&"petra":
					WonderBuildsNew.petra(b)
				&"colosseum":
					WonderBuildsNew.colosseum(b)
				&"chichen_itza":
					WonderBuildsNew.chichen_itza(b)
				&"machu_picchu":
					WonderBuildsNew.machu_picchu(b)
				&"taj_mahal":
					WonderBuildsNew.taj_mahal(b)
				&"christ_redeemer":
					WonderBuildsNew.christ_redeemer(b)
				&"grand_canyon":   # the third tour, the Seven Natural Wonders (WonderBuildsNature; NatureGround's ground)
					WonderBuildsNature.grand_canyon(b)
				&"barrier_reef":
					WonderBuildsNature.barrier_reef(b)
				&"rio_harbour":
					WonderBuildsNature.rio_harbour(b)
				&"everest":
					WonderBuildsNature.everest(b)
				&"northern_lights":
					WonderBuildsNature.northern_lights(b)
				&"paricutin":
					WonderBuildsNature.paricutin(b)
				&"victoria_falls":
					WonderBuildsNature.victoria_falls(b)
			w[id] = b.out
		var extra := _tour_extras()
		var buckets := {}
		var bounds := {}
		for id: StringName in WonderTour.ids():
			var lo := Vector3i(0x7fffffff, 0x7fffffff, 0x7fffffff)
			var hi := -lo
			for box: Array in w[id]:
				lo = lo.min(box[0])
				hi = hi.max(box[1])
				_bucket(buckets, box)
			bounds[id] = [lo, hi]
		for box: Array in extra:
			_bucket(buckets, box)
		_wonders = w
		_extras = extra
		_buckets = buckets
		_bounds = bounds
		_ready = true
	_mutex.unlock()


static func _bucket(buckets: Dictionary, box: Array) -> void:
	var lo: Vector3i = box[0]
	var hi: Vector3i = box[1]
	for cz in range(floori(lo.z / float(CHUNK)), floori((hi.z - 1) / float(CHUNK)) + 1):
		for cx in range(floori(lo.x / float(CHUNK)), floori((hi.x - 1) / float(CHUNK)) + 1):
			var key := Vector2i(cx, cz)
			if not buckets.has(key):
				buckets[key] = []
			(buckets[key] as Array).append(box)


## A wonder's own frame: boxes given between two corner cells (inclusive, any order), x across, y up from the tour's
## ground, z from its front (-z) to its back, turned into world boxes.
class Frame:
	var id: StringName
	var out: Array = []
	var _centre: Vector2i   # (its place and facing, looked up once: the builds make thousands of boxes at a world's load)
	var _face: Vector2i

	func _init(wonder: StringName) -> void:
		id = wonder
		var w: Dictionary = WonderTour.WONDERS[wonder]
		_centre = w.centre
		_face = w.face

	func box(a: Vector3i, b: Vector3i, block: int) -> void:
		var p := _centre + WonderTour.turn(Vector2i(a.x, a.z), _face)
		var q := _centre + WonderTour.turn(Vector2i(b.x, b.z), _face)
		var y := WonderBuilds.Y
		out.append([Vector3i(mini(p.x, q.x), mini(a.y, b.y) + y, mini(p.y, q.y)),
			Vector3i(maxi(p.x, q.x) + 1, maxi(a.y, b.y) + y + 1, maxi(p.y, q.y) + 1), block])

	func cell(p: Vector3i, block: int) -> void:
		box(p, p, block)

	## A ring one block wide at height y round the rect x0..x1, z0..z1 (its four sides).
	func ring(x0: int, x1: int, z0: int, z1: int, y: int, block: int) -> void:
		box(Vector3i(x0, y, z0), Vector3i(x1, y, z0), block)
		box(Vector3i(x0, y, z1), Vector3i(x1, y, z1), block)
		box(Vector3i(x0, y, z0), Vector3i(x0, y, z1), block)
		box(Vector3i(x1, y, z0), Vector3i(x1, y, z1), block)

	## A column: its base, shaft and top.
	func column(x: int, z: int, y0: int, y1: int, top: int) -> void:
		cell(Vector3i(x, y0, z), BlockIds.MARBLE)
		box(Vector3i(x, y0 + 1, z), Vector3i(x, y1 - 1, z), BlockIds.MARBLE_COLUMN)
		cell(Vector3i(x, y1, z), top)

	## A date palm: a trunk and a star of fronds.
	func palm(x: int, y: int, z: int, trunk: int) -> void:
		box(Vector3i(x, y, z), Vector3i(x, y + trunk - 1, z), BlockIds.PALM_LOG)
		var t := y + trunk
		box(Vector3i(x - 2, t, z), Vector3i(x + 2, t, z), BlockIds.PALM_LEAVES)
		box(Vector3i(x, t, z - 2), Vector3i(x, t, z + 2), BlockIds.PALM_LEAVES)
		cell(Vector3i(x, t + 1, z), BlockIds.PALM_LEAVES)


# --- The Great Pyramid of Giza ---

## The half width of course k (0 at the ground): the real slope, about 52 degrees (1.28 up for 1 in).
static func pyramid_half(k: int) -> int:
	return 22 - int(k * 0.78)


const PYRAMID_COURSES := 29


static func _pyramid(b: Frame) -> void:
	for k in PYRAMID_COURSES:
		var h := pyramid_half(k)
		b.box(Vector3i(-h, k, -h), Vector3i(h, k, h), BlockIds.LIMESTONE)
	b.box(Vector3i(-22, 0, -22), Vector3i(22, 0, -22), BlockIds.CASING_STONE)   # casing stones still at its foot
	b.box(Vector3i(-2, 0, -23), Vector3i(2, 0, -23), BlockIds.LIMESTONE)          # the step up to the entrance
	# the entrance corridor (feet at 3, on the north face) and its lamps
	b.box(Vector3i(-2, 3, -20), Vector3i(2, 5, -15), BlockIds.AIR)
	b.cell(Vector3i(-3, 5, -17), BlockIds.DESERT_LAMP)
	b.cell(Vector3i(3, 5, -17), BlockIds.DESERT_LAMP)
	# the Queen's Chamber: a passage west of the stairs, a gabled room
	b.box(Vector3i(-2, 3, -14), Vector3i(-1, 5, -5), BlockIds.AIR)
	b.box(Vector3i(-5, 3, -4), Vector3i(0, 6, 1), BlockIds.AIR)
	b.box(Vector3i(-4, 7, -4), Vector3i(-1, 7, 1), BlockIds.AIR)
	b.cell(Vector3i(-6, 5, -1), BlockIds.DESERT_LAMP)
	b.cell(Vector3i(-3, 4, -9), BlockIds.DESERT_LAMP)
	# the ascending stairs (east)
	for i in 5:
		b.box(Vector3i(1, 4 + i, -14 + i), Vector3i(2, 6 + i, -14 + i), BlockIds.AIR)
	# the Grand Gallery: its floor steps up, its walls step in (a corbelled roof)
	for z in range(-9, 0):
		var f := 9 + (z + 9) / 3
		b.box(Vector3i(0, f, z), Vector3i(3, f + 2, z), BlockIds.AIR)
		b.box(Vector3i(1, f + 3, z), Vector3i(2, f + 5, z), BlockIds.AIR)
	b.cell(Vector3i(-1, 11, -7), BlockIds.DESERT_LAMP)
	b.cell(Vector3i(-1, 12, -3), BlockIds.DESERT_LAMP)
	# the antechamber and the King's Chamber of pink granite with its stone box
	b.box(Vector3i(1, 11, 0), Vector3i(2, 13, 1), BlockIds.AIR)
	b.box(Vector3i(-4, 10, 2), Vector3i(5, 16, 8), BlockIds.GRANITE)
	b.box(Vector3i(-3, 11, 3), Vector3i(4, 15, 7), BlockIds.AIR)
	b.box(Vector3i(1, 11, 2), Vector3i(2, 13, 2), BlockIds.AIR)
	b.box(Vector3i(2, 11, 4), Vector3i(4, 12, 6), BlockIds.GRANITE)
	b.cell(Vector3i(3, 12, 5), BlockIds.AIR)
	b.cell(Vector3i(-4, 13, 5), BlockIds.DESERT_LAMP)
	b.cell(Vector3i(5, 13, 4), BlockIds.DESERT_LAMP)


## Pyramid frame cells of its rooms, for the tests and the smoke: {room: [lo, hi] inclusive, feet: the floor's y}.
const PYRAMID_ROOMS := {
	"entrance": [Vector3i(-2, 3, -20), Vector3i(2, 5, -15)],
	"queens_chamber": [Vector3i(-5, 3, -4), Vector3i(0, 6, 1)],
	"grand_gallery": [Vector3i(0, 9, -9), Vector3i(3, 11, -1)],
	"kings_chamber": [Vector3i(-3, 11, 3), Vector3i(4, 15, 7)],
}


# --- The Hanging Gardens of Babylon ---

const GARDEN_LEVELS := 4


static func garden_half(k: int) -> int:
	return 16 - 4 * k


static func _gardens(b: Frame) -> void:
	for k in GARDEN_LEVELS:
		var h := garden_half(k)
		var top := 4 * k + 3
		b.box(Vector3i(-h, 0, -h), Vector3i(h, top, h), BlockIds.BABYLON_BRICK)
		for side: Array in [[-h, h, -h, -h], [-h, h, h, h], [-h, -h, -h, h], [h, h, -h, h]]:   # a blue glazed band
			b.box(Vector3i(side[0], top - 1, side[2]), Vector3i(side[1], top - 1, side[3]), BlockIds.GLAZED_BRICK)
		b.box(Vector3i(-h, top - 1, -h) + Vector3i(1, 0, 1), Vector3i(h, top - 1, h) - Vector3i(1, 0, 1), BlockIds.DIRT)
		b.box(Vector3i(-h, top, -h), Vector3i(h, top, h), BlockIds.GRASS)
	# the stairs: up to the first garden, then up each terrace's middle
	for j in 4:
		b.box(Vector3i(-1, 0, -20 + j), Vector3i(1, j, -20 + j), BlockIds.BABYLON_BRICK)
	for k in GARDEN_LEVELS - 1:
		var h := garden_half(k)
		for j in 4:
			b.box(Vector3i(-1, 4 * k + 3, -h + j), Vector3i(1, 4 * k + 4 + j, -h + j), BlockIds.BABYLON_BRICK)
	# arches into a vaulted gallery under the first terrace
	b.box(Vector3i(-12, 0, -15), Vector3i(12, 1, -13), BlockIds.AIR)
	for x0: int in [-10, 8]:
		b.box(Vector3i(x0, 0, -16), Vector3i(x0 + 2, 1, -16), BlockIds.AIR)
	b.cell(Vector3i(-12, 1, -12), BlockIds.DESERT_LAMP)
	b.cell(Vector3i(12, 1, -12), BlockIds.DESERT_LAMP)
	b.cell(Vector3i(0, 1, -12), BlockIds.DESERT_LAMP)
	# the gardens: palms at each terrace's corners, bushes, flowers, plants trailing over the walls
	for k in GARDEN_LEVELS:
		var h := garden_half(k)
		var ground := 4 * k + 4
		var c := h - 2
		for p: Vector2i in [Vector2i(-c, -c), Vector2i(c, -c), Vector2i(-c, c), Vector2i(c, c)]:
			b.palm(p.x, ground, p.y, 3 if k == GARDEN_LEVELS - 1 else 4)
		if k < GARDEN_LEVELS - 1:
			for p: Vector2i in [Vector2i(-c, 0), Vector2i(c, 0), Vector2i(0, c)]:
				b.cell(Vector3i(p.x, ground, p.y), BlockIds.LEAVES)
			var e := h - 1
			for i in range(-e + 2, e - 1, 3):
				for p: Vector2i in [Vector2i(i, e), Vector2i(-e, i), Vector2i(e, i)]:
					b.cell(Vector3i(p.x, ground, p.y), BlockIds.FLOWERS)
				if absi(i) > 2:
					b.cell(Vector3i(i, ground, -e), BlockIds.FLOWERS)
		if k >= 1:
			for i in range(-h + 2, h - 1, 4):
				if absi(i) <= 2:
					continue
				for p: Vector3i in [Vector3i(i, 0, -h - 1), Vector3i(i, 0, h + 1), Vector3i(-h - 1, 0, i), Vector3i(h + 1, 0, i)]:
					b.box(p + Vector3i(0, 4 * k + 1, 0), p + Vector3i(0, 4 * k + 2, 0), BlockIds.LEAVES)
	# water: a pool at the back, the screw that lifts it, a channel over the terraces to a pool on top
	b.box(Vector3i(-2, -1, 17), Vector3i(2, -1, 19), BlockIds.WATER)
	b.box(Vector3i(0, 0, 17), Vector3i(0, 15, 17), BlockIds.SCREW_PUMP)
	b.box(Vector3i(-1, 15, 3), Vector3i(1, 15, 16), BlockIds.BABYLON_BRICK)
	b.box(Vector3i(0, 16, 3), Vector3i(0, 16, 16), BlockIds.WATER)
	for z: int in [8, 12, 16]:
		b.box(Vector3i(0, 0, z), Vector3i(0, 14, z), BlockIds.BABYLON_BRICK)
	b.box(Vector3i(-2, 15, -2), Vector3i(2, 15, 2), BlockIds.WATER)


## The gardens' terrace tops (frame y of the grass) for the tests: level k's grass is at 4k + 3.
static func garden_top(k: int) -> int:
	return 4 * k + 3


# --- The Temple of Artemis at Ephesus ---

static func _artemis(b: Frame) -> void:
	b.box(Vector3i(-13, 0, -27), Vector3i(13, 0, 27), BlockIds.MARBLE)
	b.box(Vector3i(-12, 1, -26), Vector3i(12, 1, 26), BlockIds.MARBLE)
	b.box(Vector3i(-11, 2, -25), Vector3i(11, 2, 25), BlockIds.MARBLE)   # the stylobate: feet at 3
	var cols := artemis_columns()
	for c: Vector2i in cols:
		b.column(c.x, c.y, 3, 13, BlockIds.CAPITAL)
	# the hall: marble walls, its door to the west (the real temple faced west), lamps
	b.box(Vector3i(-4, 3, -12), Vector3i(4, 13, 16), BlockIds.MARBLE)
	b.box(Vector3i(-3, 3, -11), Vector3i(3, 13, 15), BlockIds.AIR)
	b.box(Vector3i(-1, 3, -12), Vector3i(1, 7, -12), BlockIds.AIR)
	for p: Vector3i in [Vector3i(-4, 8, -6), Vector3i(4, 8, -6), Vector3i(-4, 8, 6), Vector3i(4, 8, 6), Vector3i(-4, 8, 13),
			Vector3i(4, 8, 13)]:
		b.cell(p, BlockIds.DESERT_LAMP)
	# the roof: a marble beam, the carved band, the tiles and the pediments
	b.box(Vector3i(-11, 14, -25), Vector3i(11, 15, 25), BlockIds.MARBLE)
	b.ring(-11, 11, -25, 25, 15, BlockIds.FRIEZE)
	for j in 6:
		var h := 11 - 2 * j
		b.box(Vector3i(-h, 16 + j, -24), Vector3i(h, 16 + j, 24), BlockIds.ROOF_TILES)
		b.box(Vector3i(-h, 16 + j, -25), Vector3i(h, 16 + j, -25), BlockIds.MARBLE)
		b.box(Vector3i(-h, 16 + j, 25), Vector3i(h, 16 + j, 25), BlockIds.MARBLE)


## The Temple of Artemis's columns (frame x, z): two rows all round, a porch of six at the front, three at the back.
static func artemis_columns() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(-9, 10, 3):
		out.append(Vector2i(x, -24))
		out.append(Vector2i(x, 24))
	for z in range(-21, 22, 3):
		out.append(Vector2i(-9, z))
		out.append(Vector2i(9, z))
	for x in range(-6, 7, 3):
		out.append(Vector2i(x, -21))
		out.append(Vector2i(x, 21))
	for z in range(-18, 19, 3):
		out.append(Vector2i(-6, z))
		out.append(Vector2i(6, z))
	for x: int in [-3, 0, 3]:
		out.append(Vector2i(x, -18))
		out.append(Vector2i(x, -15))
		out.append(Vector2i(x, 18))
	return out


# --- The Statue of Zeus at Olympia (in its temple) ---

static func _zeus(b: Frame) -> void:
	b.box(Vector3i(-12, 0, -27), Vector3i(12, 0, 27), BlockIds.WHITE_BRICK)
	b.box(Vector3i(-11, 1, -26), Vector3i(11, 1, 26), BlockIds.WHITE_BRICK)
	b.box(Vector3i(-10, 2, -25), Vector3i(10, 2, 25), BlockIds.WHITE_BRICK)   # feet at 3
	for c: Vector2i in zeus_columns():
		b.column(c.x, c.y, 3, 17, BlockIds.MARBLE)   # a plain (Doric) top
	# the hall
	b.box(Vector3i(-7, 3, -18), Vector3i(7, 17, 21), BlockIds.WHITE_BRICK)
	b.box(Vector3i(-6, 3, -17), Vector3i(6, 17, 20), BlockIds.AIR)
	b.box(Vector3i(-2, 3, -18), Vector3i(2, 10, -18), BlockIds.AIR)   # the great door (east)
	# galleries up stairs at both sides (visitors climbed to see Zeus closer)
	for s: int in [-1, 1]:
		for j in 6:
			b.box(Vector3i(6 * s, 3, -17 + j), Vector3i(5 * s, 3 + j, -17 + j), BlockIds.WHITE_BRICK)
		b.box(Vector3i(6 * s, 9, -11), Vector3i(4 * s, 9, 6), BlockIds.WHITE_BRICK)   # (they end before the throne)
		b.box(Vector3i(4 * s, 10, -10), Vector3i(4 * s, 10, 6), BlockIds.MARBLE)   # the parapet
		for z in range(-10, 7, 4):
			b.box(Vector3i(4 * s, 3, z), Vector3i(4 * s, 8, z), BlockIds.MARBLE_COLUMN)
			b.box(Vector3i(4 * s, 11, z), Vector3i(4 * s, 16, z), BlockIds.MARBLE_COLUMN)
		for z: int in [-8, 0, 8, 16]:
			b.cell(Vector3i(7 * s, 7, z), BlockIds.DESERT_LAMP)
			b.cell(Vector3i(7 * s, 13, z), BlockIds.DESERT_LAMP)
	# the black floor with a marble rim that held olive oil (it kept the ivory from cracking)
	b.box(Vector3i(-3, 2, 0), Vector3i(3, 2, 5), BlockIds.EBONY)
	b.ring(-4, 4, -1, 6, 3, BlockIds.MARBLE)
	_zeus_statue(b)
	# the roof
	b.box(Vector3i(-10, 18, -25), Vector3i(10, 19, 25), BlockIds.WHITE_BRICK)
	b.ring(-10, 10, -25, 25, 19, BlockIds.FRIEZE)
	for j in 6:
		var h := 10 - 2 * j
		b.box(Vector3i(-h, 20 + j, -24), Vector3i(h, 20 + j, 24), BlockIds.ROOF_TILES)
		b.box(Vector3i(-h, 20 + j, -25), Vector3i(h, 20 + j, -25), BlockIds.MARBLE)
		b.box(Vector3i(-h, 20 + j, 25), Vector3i(h, 20 + j, 25), BlockIds.MARBLE)


## Zeus on his throne at the back of the hall, facing the door (-z): about 12 blocks tall, his head just under the roof.
static func _zeus_statue(b: Frame) -> void:
	b.box(Vector3i(-5, 3, 7), Vector3i(5, 4, 19), BlockIds.EBONY)            # the base of dark stone
	b.box(Vector3i(-4, 5, 12), Vector3i(4, 7, 18), BlockIds.EBONY)           # the seat
	b.box(Vector3i(-5, 5, 18), Vector3i(5, 14, 19), BlockIds.EBONY)          # the throne's back ...
	b.box(Vector3i(-5, 15, 18), Vector3i(5, 15, 19), BlockIds.GOLD_LEAF)     # ... trimmed with gold
	for s: int in [-1, 1]:
		b.box(Vector3i(5 * s, 5, 12), Vector3i(5 * s, 7, 12), BlockIds.EBONY)
		b.box(Vector3i(5 * s, 8, 12), Vector3i(5 * s, 9, 17), BlockIds.GOLD_LEAF)   # the armrests
		b.box(Vector3i(3 * s, 5, 9), Vector3i(1 * s, 8, 10), BlockIds.GOLD_LEAF)    # the robe over his shins
		b.box(Vector3i(3 * s, 8, 9), Vector3i(1 * s, 9, 14), BlockIds.GOLD_LEAF)    # ... and his lap
	b.box(Vector3i(-3, 5, 7), Vector3i(3, 5, 8), BlockIds.GOLD_LEAF)         # the footstool
	b.box(Vector3i(-3, 10, 13), Vector3i(3, 12, 16), BlockIds.IVORY)         # his chest (ivory)
	b.box(Vector3i(1, 10, 13), Vector3i(3, 12, 16), BlockIds.GOLD_LEAF)      # the gold cloak over a shoulder
	b.box(Vector3i(-4, 13, 13), Vector3i(4, 13, 16), BlockIds.IVORY)        # shoulders
	b.box(Vector3i(-1, 14, 14), Vector3i(1, 14, 15), BlockIds.IVORY)        # neck
	b.box(Vector3i(-2, 15, 13), Vector3i(2, 17, 16), BlockIds.IVORY)        # head
	b.box(Vector3i(-1, 14, 12), Vector3i(1, 15, 12), BlockIds.GOLD_LEAF)     # beard
	b.box(Vector3i(-2, 17, 14), Vector3i(2, 17, 16), BlockIds.GOLD_LEAF)     # hair
	b.box(Vector3i(-3, 16, 13), Vector3i(-3, 16, 16), BlockIds.OLIVE_LEAVES)   # the olive wreath
	b.box(Vector3i(3, 16, 13), Vector3i(3, 16, 16), BlockIds.OLIVE_LEAVES)
	b.box(Vector3i(-2, 16, 17), Vector3i(2, 16, 17), BlockIds.OLIVE_LEAVES)
	# his right arm holds a small Victory; his left holds a sceptre with an eagle on top
	b.box(Vector3i(-5, 10, 14), Vector3i(-5, 12, 15), BlockIds.IVORY)
	b.box(Vector3i(-5, 10, 11), Vector3i(-5, 10, 13), BlockIds.IVORY)
	b.box(Vector3i(-5, 11, 10), Vector3i(-5, 12, 10), BlockIds.GOLD_LEAF)
	b.box(Vector3i(5, 10, 13), Vector3i(5, 12, 14), BlockIds.IVORY)
	b.box(Vector3i(5, 12, 11), Vector3i(5, 13, 12), BlockIds.IVORY)
	b.box(Vector3i(6, 5, 11), Vector3i(6, 16, 11), BlockIds.GOLD_LEAF)
	b.box(Vector3i(6, 17, 10), Vector3i(6, 17, 12), BlockIds.GOLD_LEAF)


## The Temple of Zeus's columns (frame x, z): 6 across its ends, 13 along its sides, as the real one.
static func zeus_columns() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(-10, 11, 4):
		out.append(Vector2i(x, -24))
		out.append(Vector2i(x, 24))
	for z in range(-20, 21, 4):
		out.append(Vector2i(-10, z))
		out.append(Vector2i(10, z))
	return out


# --- The Mausoleum at Halicarnassus ---

static func _mausoleum(b: Frame) -> void:
	b.box(Vector3i(-9, 0, -11), Vector3i(9, 1, 11), BlockIds.MARBLE)
	b.box(Vector3i(-9, 2, -11), Vector3i(9, 7, 11), BlockIds.WHITE_BRICK)
	b.box(Vector3i(-10, 8, -12), Vector3i(10, 8, 12), BlockIds.MARBLE)   # the podium's top: feet at 9
	for j in 9:
		b.box(Vector3i(-2, 0, -20 + j), Vector3i(2, j, -20 + j), BlockIds.MARBLE)   # the stairs up the front
	for c: Vector2i in mausoleum_columns():
		b.column(c.x, c.y, 9, 15, BlockIds.CAPITAL)
	b.box(Vector3i(-5, 9, -7), Vector3i(5, 15, 7), BlockIds.MARBLE)
	b.box(Vector3i(-4, 9, -6), Vector3i(4, 14, 6), BlockIds.AIR)
	b.box(Vector3i(-1, 9, -7), Vector3i(1, 11, -7), BlockIds.AIR)
	b.cell(Vector3i(-5, 12, 0), BlockIds.DESERT_LAMP)
	b.cell(Vector3i(5, 12, 0), BlockIds.DESERT_LAMP)
	b.box(Vector3i(-9, 16, -11), Vector3i(9, 17, 11), BlockIds.MARBLE)
	b.ring(-9, 9, -11, 11, 17, BlockIds.FRIEZE)
	for j in MAUSOLEUM_STEPS:   # the stepped pyramid roof
		b.box(Vector3i(-9 + j, 18 + j, -11 + j), Vector3i(9 - j, 18 + j, 11 - j), BlockIds.MARBLE)
	var top := 18 + MAUSOLEUM_STEPS   # feet on the roof's top
	for x: int in [-3, -1, 1, 3]:   # four horses ...
		b.cell(Vector3i(x, top, -3), BlockIds.MARBLE)
		b.cell(Vector3i(x, top, 0), BlockIds.MARBLE)
		b.box(Vector3i(x, top + 1, -3), Vector3i(x, top + 1, 0), BlockIds.MARBLE)
		b.box(Vector3i(x, top + 2, -4), Vector3i(x, top + 3, -4), BlockIds.MARBLE)
		b.cell(Vector3i(x, top + 1, 1), BlockIds.MARBLE)
	b.box(Vector3i(0, top + 1, -3), Vector3i(0, top + 1, 1), BlockIds.GOLD_LEAF)   # ... pulling a chariot
	b.box(Vector3i(-2, top, 2), Vector3i(2, top, 4), BlockIds.MARBLE)
	b.box(Vector3i(-2, top + 1, 2), Vector3i(2, top + 1, 2), BlockIds.GOLD_LEAF)
	b.box(Vector3i(-2, top + 1, 3), Vector3i(-2, top + 1, 4), BlockIds.GOLD_LEAF)
	b.box(Vector3i(2, top + 1, 3), Vector3i(2, top + 1, 4), BlockIds.GOLD_LEAF)
	b.cell(Vector3i(-3, top, 3), BlockIds.BRONZE)
	b.cell(Vector3i(3, top, 3), BlockIds.BRONZE)


const MAUSOLEUM_STEPS := 7


## The Mausoleum's 36 columns (frame x, z), as the real one had.
static func mausoleum_columns() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(-8, 9, 2):
		out.append(Vector2i(x, -10))
		out.append(Vector2i(x, 10))
	for z in range(-8, 9, 2):
		out.append(Vector2i(-8, z))
		out.append(Vector2i(8, z))
	return out


# --- The Colossus of Rhodes ---

const COLOSSUS_FEET := 7   # the figure's feet stand on its base's top


static func _colossus(b: Frame) -> void:
	b.box(Vector3i(-5, 0, -5), Vector3i(5, 1, 5), BlockIds.MARBLE)
	b.box(Vector3i(-4, 2, -4), Vector3i(4, 5, 4), BlockIds.MARBLE)
	b.box(Vector3i(-5, 6, -5), Vector3i(5, 6, 5), BlockIds.MARBLE)
	for j in 7:
		b.box(Vector3i(-1, 0, -12 + j), Vector3i(1, j, -12 + j), BlockIds.MARBLE)
	var g := COLOSSUS_FEET
	for s: int in [-1, 1]:
		b.box(Vector3i(2 * s, g, -1), Vector3i(1 * s, g + 10, 0), BlockIds.BRONZE)   # legs, close together
		b.box(Vector3i(2 * s, g, -2), Vector3i(1 * s, g, -2), BlockIds.BRONZE)       # toes
	b.box(Vector3i(-5, g, -1), Vector3i(-4, g + 12, 1), BlockIds.BRONZE)    # the cloak falling to the base
	b.box(Vector3i(-3, g + 11, -1), Vector3i(3, g + 17, 1), BlockIds.BRONZE)   # hips and body
	b.box(Vector3i(-4, g + 18, -1), Vector3i(4, g + 18, 1), BlockIds.BRONZE)   # shoulders
	b.box(Vector3i(-1, g + 19, -1), Vector3i(1, g + 19, 0), BlockIds.BRONZE)   # neck
	b.box(Vector3i(-2, g + 20, -2), Vector3i(2, g + 23, 1), BlockIds.BRONZE)   # head
	for r: Vector3i in [Vector3i(0, 24, -1), Vector3i(0, 25, -1), Vector3i(-2, 24, -1), Vector3i(2, 24, -1),
			Vector3i(-3, 22, -1), Vector3i(-3, 23, -1), Vector3i(3, 22, -1), Vector3i(3, 23, -1)]:
		b.cell(r + Vector3i(0, g, 0), BlockIds.GOLD_LEAF)   # a crown of sun rays
	b.box(Vector3i(-5, g + 13, -1), Vector3i(-4, g + 17, 0), BlockIds.BRONZE)   # the arm holding the cloak
	b.box(Vector3i(4, g + 18, -1), Vector3i(5, g + 25, 0), BlockIds.BRONZE)    # the arm held high ...
	b.box(Vector3i(4, g + 26, -1), Vector3i(5, g + 26, 0), BlockIds.GOLD_LEAF)
	b.box(Vector3i(4, g + 27, -1), Vector3i(5, g + 27, 0), BlockIds.BEACON_FIRE)   # ... with a torch


# --- The Lighthouse of Alexandria (on its island) ---

const LIGHTHOUSE_TIER := 15        # the first tier's height (its roof slab at this y)
const LIGHTHOUSE_TERRACE := 16     # feet on the first tier's roof
const LIGHTHOUSE_TOP := 35         # feet in the lantern by the fire
## The spiral round the shaft's pillar (frame x, z), from the shaft's door.
const SHAFT := [Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1)]
const SHAFT_STEPS := 19


## The first tier's stairs round its pillar: step k's middle (frame x, z), one block higher each; the corners fill
## their 3 x 3, the sides their 3 across. The last is the far corner, under the hatch onto the terrace.
static func lighthouse_steps() -> Array[Vector2i]:
	var out: Array[Vector2i] = [Vector2i(1, -4), Vector2i(2, -4), Vector2i(4, -4)]
	for z in range(-2, 3):
		out.append(Vector2i(4, z))
	out.append(Vector2i(4, 4))
	for x in range(2, -3, -1):
		out.append(Vector2i(x, 4))
	out.append(Vector2i(-4, 4))
	return out


static func _lighthouse(b: Frame) -> void:
	# tier 1: square, hollow round a pillar, its stairs filled from the floor, a roof terrace with a hatch
	var t := LIGHTHOUSE_TIER
	b.box(Vector3i(-6, 0, -6), Vector3i(6, t, 6), BlockIds.WHITE_BRICK)
	b.box(Vector3i(-5, 0, -5), Vector3i(5, t - 1, 5), BlockIds.AIR)
	b.box(Vector3i(-2, 0, -2), Vector3i(2, t - 1, 2), BlockIds.WHITE_BRICK)
	b.box(Vector3i(-1, 0, -6), Vector3i(1, 2, -6), BlockIds.AIR)   # the door (west, toward the causeway)
	var steps := lighthouse_steps()
	for k in steps.size():
		var c: Vector2i = steps[k]
		var lo := Vector3i(c.x, 0, c.y)
		var hi := Vector3i(c.x, k, c.y)
		if absi(c.x) == 4 and absi(c.y) == 4:
			lo += Vector3i(-1, 0, -1)
			hi += Vector3i(1, 0, 1)
		elif absi(c.y) == 4:
			lo.z -= 1
			hi.z += 1
		else:
			lo.x -= 1
			hi.x += 1
		b.box(lo, hi, BlockIds.WHITE_BRICK)
		if k + 1 >= t - 2:   # the last three steps: room over the head all the way up
			b.box(Vector3i(lo.x, t, lo.z), Vector3i(hi.x, t, hi.z), BlockIds.AIR)   # the hatch onto the terrace
	for p: Vector3i in [Vector3i(0, 6, 6), Vector3i(6, 6, 0), Vector3i(-6, 6, 0), Vector3i(0, 11, 6), Vector3i(6, 11, 0),
			Vector3i(-6, 11, 0), Vector3i(0, 11, -6)]:
		b.box(p, p + Vector3i(0, 1, 0), BlockIds.GLASS)
	b.cell(Vector3i(-3, 8, -3), BlockIds.DESERT_LAMP)
	b.cell(Vector3i(3, 8, 3), BlockIds.DESERT_LAMP)
	b.ring(-6, 6, -6, 6, LIGHTHOUSE_TERRACE, BlockIds.WHITE_BRICK)   # the terrace's parapet
	# tier 2: eight-sided, solid round a spiral shaft; tier 3: round
	var s0 := LIGHTHOUSE_TERRACE
	_octagon(b, 3, s0, s0 + 11, BlockIds.WHITE_BRICK)
	_octagon(b, 3, s0 + 12, s0 + 12, BlockIds.WHITE_BRICK)
	_octagon(b, 2, s0 + 12, s0 + 12, BlockIds.AIR)   # its terrace's parapet
	b.box(Vector3i(-2, s0 + 12, -1), Vector3i(2, s0 + 17, 1), BlockIds.WHITE_BRICK)
	b.box(Vector3i(-1, s0 + 12, -2), Vector3i(1, s0 + 17, 2), BlockIds.WHITE_BRICK)
	# the shaft through tiers 2 and 3: a way in from the terrace, the pillar, the spiral
	b.box(Vector3i(0, s0, -3), Vector3i(0, s0 + 2, -2), BlockIds.AIR)
	var floor := LIGHTHOUSE_TOP - 1
	b.box(Vector3i(-1, s0, -1), Vector3i(1, floor - 1, 1), BlockIds.AIR)
	b.box(Vector3i(0, s0, 0), Vector3i(0, floor - 1, 0), BlockIds.WHITE_BRICK)
	for k in SHAFT_STEPS:
		var c: Vector2i = SHAFT[k % SHAFT.size()]
		b.cell(Vector3i(c.x, s0 + k, c.y), BlockIds.WHITE_BRICK)
	# the lantern: its floor (open over the last steps), four pillars, a low wall, the fire, a bronze roof
	b.box(Vector3i(-2, floor, -1), Vector3i(2, floor, 1), BlockIds.WHITE_BRICK)
	b.box(Vector3i(-1, floor, -2), Vector3i(1, floor, 2), BlockIds.WHITE_BRICK)
	for k in range(SHAFT_STEPS - 4, SHAFT_STEPS - 1):   # room over the head up the last steps
		var c: Vector2i = SHAFT[k % SHAFT.size()]
		b.cell(Vector3i(c.x, floor, c.y), BlockIds.AIR)
	var y := LIGHTHOUSE_TOP
	for p: Vector2i in [Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(2, 1)]:
		b.box(Vector3i(p.x, y, p.y), Vector3i(p.x, y + 2, p.y), BlockIds.WHITE_BRICK)
	for p: Vector2i in [Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2),
			Vector2i(-2, 0), Vector2i(2, 0)]:
		b.cell(Vector3i(p.x, y, p.y), BlockIds.WHITE_BRICK)
	b.box(Vector3i(0, y, 0), Vector3i(0, y + 1, 0), BlockIds.BEACON_FIRE)
	b.box(Vector3i(-2, y + 3, -1), Vector3i(2, y + 3, 1), BlockIds.BRONZE)
	b.box(Vector3i(-1, y + 3, -2), Vector3i(1, y + 3, 2), BlockIds.BRONZE)
	b.box(Vector3i(-1, y + 4, 0), Vector3i(1, y + 4, 0), BlockIds.BRONZE)
	b.box(Vector3i(0, y + 4, -1), Vector3i(0, y + 4, 1), BlockIds.BRONZE)
	b.cell(Vector3i(0, y + 5, 0), BlockIds.GOLD_LEAF)


## An eight-sided slab of half size h from y0 to y1 (three boxes).
static func _octagon(b: Frame, h: int, y0: int, y1: int, block: int) -> void:
	b.box(Vector3i(-h, y0, -h + 2), Vector3i(h, y1, h - 2), block)
	b.box(Vector3i(-h + 1, y0, -h + 1), Vector3i(h - 1, y1, h - 1), block)
	b.box(Vector3i(-h + 2, y0, -h), Vector3i(h - 2, y1, h), block)


# --- The tour's own: the landing square, paths, signposts, plaques, the causeway, the river ---

static func _tour_extras() -> Array:
	var out: Array = []
	var y := Y - 1
	var r := WonderTour.PLAZA_R
	for c: Vector2i in WonderTour.SQUARES.values():   # the tours' squares: rounds of paving
		for dz in range(-r, r + 1):
			var hw := int(sqrt((r + 0.5) * (r + 0.5) - dz * dz))
			out.append([Vector3i(c.x - hw, y, c.y + dz), Vector3i(c.x + hw + 1, y + 1, c.y + dz + 1), BlockIds.PAVING])
	var road := WonderTour.road()   # the Wonders Road between them (straight west, sand), speed pads across it
	var w := WonderTour.PATH_HALF
	out.append([Vector3i(road[1].x, y, -w), Vector3i(road[0].x + 1, y + 1, w + 1), WonderTour.ROAD_BLOCK])
	for x: int in WonderTour.road_pads():
		out.append([Vector3i(x, y, -w), Vector3i(x + 1, y + 1, w + 1), BlockIds.SPEED_PAD])
	_path(out, WonderTour.trail(), y, WonderTour.TRAIL_BLOCK)   # the Nature Trail (south, dirt), speed pads across it
	for p: Vector2i in WonderTour.trail_pads():
		out.append([Vector3i(p.x - w, y, p.y), Vector3i(p.x + w + 1, y + 1, p.y + 1), BlockIds.SPEED_PAD])
	for id: StringName in WonderTour.ids():
		var nature := WonderFacts.tour_of(id) == &"nature"
		_path(out, WonderTour.path(id), y, WonderTour.NATURE_PATH_BLOCK if nature else BlockIds.PAVING)
		_signpost(out, WonderTour.signpost(id))
		var p := WonderTour.plaque(id)
		out.append([p, p + Vector3i.ONE, BlockIds.WONDER_PLAQUE])
	for tour: StringName in WonderFacts.TOUR_IDS:
		if tour != &"nature":
			_signpost(out, WonderTour.road_signpost(tour))   # the Wonders Road's ends
		if tour != &"new":
			_signpost(out, WonderTour.trail_signpost(tour))   # the Nature Trail's ends
		var t := WonderTour.tour_plaque(tour)
		out.append([t, t + Vector3i.ONE, BlockIds.WONDER_PLAQUE])
	var c := WonderTour.CAUSEWAY
	out.append([Vector3i(c.position.x, y, c.position.y), Vector3i(c.end.x, y + 1, c.end.y), BlockIds.PAVING])
	out.append([Vector3i(c.position.x, Y, c.position.y), Vector3i(c.end.x, Y + 1, c.position.y + 1), BlockIds.WHITE_BRICK])
	out.append([Vector3i(c.position.x, Y, c.end.y - 1), Vector3i(c.end.x, Y + 1, c.end.y), BlockIds.WHITE_BRICK])
	var rv := WonderTour.RIVER
	out.append([Vector3i(rv.position.x, y - 2, rv.position.y), Vector3i(rv.end.x, y + 1, rv.end.y), BlockIds.WATER])
	return out


## A signpost at (x, z): a post and a board on top.
static func _signpost(out: Array, s: Vector2i) -> void:
	out.append([Vector3i(s.x, Y, s.y), Vector3i(s.x + 1, Y + 2, s.y + 1), BlockIds.LOG])
	out.append([Vector3i(s.x, Y + 2, s.y), Vector3i(s.x + 1, Y + 3, s.y + 1), BlockIds.PLANKS])


## A straight path 3 wide from a to b (its paving, or `block`, replaces the ground's top), a box per step along its
## longer way (WonderTour.line_cells).
static func _path(out: Array, ends: Array[Vector2i], y: int, block: int = BlockIds.PAVING) -> void:
	var d: Vector2i = ends[1] - ends[0]
	var along_x := absi(d.x) >= absi(d.y)
	var w := WonderTour.PATH_HALF
	for p in WonderTour.line_cells(ends[0], ends[1]):
		if along_x:
			out.append([Vector3i(p.x, y, p.y - w), Vector3i(p.x + 1, y + 1, p.y + w + 1), block])
		else:
			out.append([Vector3i(p.x - w, y, p.y), Vector3i(p.x + w + 1, y + 1, p.y + 1), block])
