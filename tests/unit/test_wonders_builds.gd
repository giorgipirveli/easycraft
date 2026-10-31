extends GutTest
## Owner #78 (spec §24): each wonder of the first tour recognisable from the real one's shape and colours, in our own
## blocks (§3c), at a size a child walks round, walks into where the real one can be entered and climbs where it is
## safe (WonderBuilds). A child's walk is checked cell by cell: standing needs two free cells over a solid one, a step
## up is one block (with room over the head), a fall a few blocks at most.

const Y := WonderTour.BASE_Y

var shape: WondersShape


func before_all() -> void:
	shape = WondersShape.new(7)


## The block at p: the tour's, else the ground's.
func _block(p: Vector3i) -> int:
	var b := WonderBuilds.block_at(p)
	if b >= 0:
		return b
	return BlockIds.STONE if p.y < shape.height_at(p.x, p.z) else BlockIds.AIR


func _free(id: int) -> bool:
	return not BlockIds.is_solid(id) or id == BlockIds.FLOWERS


func _stands(p: Vector3i) -> bool:
	return _free(_block(p)) and _free(_block(p + Vector3i.UP)) and not _free(_block(p + Vector3i.DOWN))


## A cell of wonder `id`'s own frame in the world (y up from the tour's ground).
func _w(id: StringName, x: int, y: int, z: int) -> Vector3i:
	var q := WonderTour.to_world(id, Vector2i(x, z))
	return Vector3i(q.x, Y + y, q.y)


## Can a child walk from `from` (feet) to any cell of `goal` (feet cells)? `up`: the highest step (2: a double jump);
## `within` (x, z): the ground the walk keeps to (the whole tour when empty).
func _walks(from: Vector3i, goal: Callable, up: int = 1, within: Rect2i = Rect2i(-200, -200, 400, 400),
		limit: int = 80000) -> bool:
	if not _stands(from):
		gut.p("not standing at the start %s" % from)
		return false
	var seen := {from: true}
	var queue: Array[Vector3i] = [from]
	var n := 0
	while not queue.is_empty() and n < limit:
		var p: Vector3i = queue.pop_front()
		n += 1
		if goal.call(p):
			return true
		for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			for q: Vector3i in _moves(p, p + d, up):
				if not seen.has(q) and within.has_point(Vector2i(q.x, q.z)):
					seen[q] = true
					queue.append(q)
	return false


func _moves(p: Vector3i, c: Vector3i, up: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for dy in range(1, up + 1):   # up a step: room over the head here and there
		var q := c + Vector3i(0, dy, 0)
		var room := true
		for k in range(2, dy + 2):
			room = room and _free(_block(p + Vector3i(0, k, 0)))
		if room and _stands(q):
			out.append(q)
	if _free(_block(c)) and _free(_block(c + Vector3i.UP)):   # across, then down a few at most
		var y := c.y
		while y > c.y - 4 and _free(_block(Vector3i(c.x, y - 1, c.z))):
			y -= 1
		var q := Vector3i(c.x, y, c.z)
		if _stands(q):
			out.append(q)
	return out


func _in(lo: Vector3i, hi: Vector3i) -> Callable:
	var a := lo.min(hi)
	var b := lo.max(hi)
	return func(p: Vector3i) -> bool:
		return p.x >= a.x and p.y >= a.y and p.z >= a.z and p.x <= b.x and p.y <= b.y and p.z <= b.z


func _count(id: StringName, block: int) -> int:
	var n := 0
	for b: Array in WonderBuilds.boxes(id):
		if b[2] == block:
			var s: Vector3i = b[1] - b[0]
			n += s.x * s.y * s.z
	return n


# --- The Great Pyramid ---

func test_the_pyramid_has_its_real_slope_and_is_limestone() -> void:
	assert_eq(WonderBuilds.PYRAMID_COURSES, 29)
	var base := WonderBuilds.pyramid_half(0) * 2 + 1
	var height := WonderBuilds.PYRAMID_COURSES
	var slope := rad_to_deg(atan(float(height) / (base / 2.0)))
	assert_between(slope, 49.0, 55.0, "about 52 degrees like the real one (%.1f)" % slope)
	assert_eq(_block(_w(&"pyramid", 0, 0, 0)), BlockIds.LIMESTONE, "solid limestone at its heart's foot")
	assert_eq(_block(_w(&"pyramid", 0, 28, 0)), BlockIds.LIMESTONE, "its top")
	assert_eq(_block(_w(&"pyramid", 0, 29, 0)), BlockIds.AIR)
	assert_eq(_block(_w(&"pyramid", 10, 0, -22)), BlockIds.CASING_STONE, "casing stones still at its foot")
	assert_eq(_block(_w(&"pyramid", 20, 20, 20)), BlockIds.AIR, "stepped sides, not a box")


func test_a_child_walks_into_the_pyramid_to_both_chambers() -> void:
	var outside := _w(&"pyramid", 0, 0, -27)
	var rooms := WonderBuilds.PYRAMID_ROOMS
	for room: String in ["queens_chamber", "kings_chamber", "grand_gallery"]:
		var r: Array = rooms[room]
		assert_true(_walks(outside, _in(_w(&"pyramid", r[0].x, r[0].y, r[0].z), _w(&"pyramid", r[1].x, r[1].y, r[1].z))),
			"the %s from the entrance on the north face" % room)
	var kings: Array = rooms["kings_chamber"]
	assert_eq(_block(_w(&"pyramid", kings[0].x - 1, kings[0].y, kings[0].z)), BlockIds.GRANITE, "pink granite walls")
	assert_eq(kings[1].x - kings[0].x + 1, 8, "the King's Chamber is long east to west")
	var box := 0
	for x in range(-3, 5):
		for z in range(3, 8):
			if _block(_w(&"pyramid", x, 11, z)) == BlockIds.GRANITE:
				box += 1
	assert_gt(box, 4, "the king's stone box stands in it")


func test_the_pyramid_can_be_climbed_step_by_step_with_a_double_jump() -> void:
	assert_true(_walks(_w(&"pyramid", -15, 0, -27), func(p: Vector3i) -> bool: return p.y >= Y + 28, 2),
		"the top (its steps are one or two blocks: a double jump)")


# --- The Hanging Gardens ---

func test_the_gardens_are_four_terraces_of_brick_with_gardens_and_blue_bands() -> void:
	for k in WonderBuilds.GARDEN_LEVELS:
		var h := WonderBuilds.garden_half(k)
		assert_eq(_block(_w(&"gardens", h, WonderBuilds.garden_top(k), 0)), BlockIds.GRASS, "terrace %d's garden" % k)
		assert_eq(_block(_w(&"gardens", h, WonderBuilds.garden_top(k) - 1, 0)), BlockIds.GLAZED_BRICK,
			"terrace %d's blue band" % k)
		assert_eq(_block(_w(&"gardens", h, 0, 0)), BlockIds.BABYLON_BRICK, "terrace %d's brick" % k)
	assert_gt(_count(&"gardens", BlockIds.PALM_LEAVES), 30, "palms on every terrace")
	assert_gt(_count(&"gardens", BlockIds.LEAVES), 10, "plants trailing over the walls")
	assert_gt(_count(&"gardens", BlockIds.SCREW_PUMP), 10, "the water screw")
	assert_gt(_count(&"gardens", BlockIds.WATER), 20, "the pools and the channel")


func test_a_child_climbs_the_gardens_to_the_top_and_walks_under_its_arches() -> void:
	var front := _w(&"gardens", 0, 0, -24)
	assert_true(_walks(front, func(p: Vector3i) -> bool: return p.y >= Y + WonderBuilds.garden_top(3) + 1),
		"up the stairs to the top garden")
	assert_true(_walks(front, _in(_w(&"gardens", -12, 0, -15), _w(&"gardens", 12, 0, -13))), "into the vaulted gallery")


# --- The Temple of Artemis ---

func test_the_temple_of_artemis_has_about_a_hundred_marble_columns_and_faces_west() -> void:
	var cols := WonderBuilds.artemis_columns()
	assert_between(cols.size(), 85, 110, "two rows all round and a porch (the real one had more than 100)")
	var seen := {}
	for c in cols:
		assert_false(seen.has(c), "one column at %s" % c)
		seen[c] = true
		assert_eq(_block(_w(&"artemis", c.x, 6, c.y)), BlockIds.MARBLE_COLUMN)
		assert_eq(_block(_w(&"artemis", c.x, 13, c.y)), BlockIds.CAPITAL, "its scrolled top")
	var door := _w(&"artemis", 0, 3, -12)
	assert_eq(_block(door), BlockIds.AIR, "the door")
	assert_lt(door.x, WonderTour.WONDERS[&"artemis"].centre.x, "the door is on the west side")
	assert_true(_walks(_w(&"artemis", 0, 0, -31), _in(_w(&"artemis", -3, 3, -10), _w(&"artemis", 3, 3, 8))),
		"up the steps, between the columns and into the hall")
	assert_gt(_count(&"artemis", BlockIds.FRIEZE), 50, "the carved band under the roof")


# --- The Statue of Zeus ---

func test_zeus_sits_in_a_temple_of_6_by_13_columns_his_head_under_the_roof() -> void:
	var cols := WonderBuilds.zeus_columns()
	assert_eq(cols.size(), 6 * 2 + 11 * 2, "6 across each end, 13 along each side")
	var head := _w(&"zeus", 0, 17, 14)
	assert_eq(_block(head), BlockIds.GOLD_LEAF, "his hair of gold at the very top")
	assert_eq(_block(head + Vector3i.UP), BlockIds.WHITE_BRICK, "the roof right over his head")
	assert_eq(_block(_w(&"zeus", 0, 11, 13)), BlockIds.IVORY, "ivory skin")
	assert_eq(_block(_w(&"zeus", 2, 8, 10)), BlockIds.GOLD_LEAF, "a golden robe")
	assert_eq(_block(_w(&"zeus", 0, 6, 15)), BlockIds.EBONY, "a throne of ebony")
	assert_gt(_count(&"zeus", BlockIds.OLIVE_LEAVES), 4, "his olive wreath")
	assert_eq(_block(_w(&"zeus", 0, 2, 2)), BlockIds.EBONY, "the black floor for the olive oil")
	assert_eq(_block(_w(&"zeus", 0, 3, -1)), BlockIds.MARBLE, "its marble rim")


func test_a_child_walks_into_the_temple_of_zeus_and_up_to_its_galleries() -> void:
	var front := _w(&"zeus", 0, 0, -31)
	assert_true(_walks(front, _in(_w(&"zeus", -3, 3, -10), _w(&"zeus", 3, 3, -2))), "into the hall")
	assert_true(_walks(front, _in(_w(&"zeus", -6, 10, -10), _w(&"zeus", -5, 10, 6))), "up to a gallery")


# --- The Mausoleum ---

func test_the_mausoleum_has_36_columns_a_stepped_roof_and_four_horses() -> void:
	assert_eq(WonderBuilds.mausoleum_columns().size(), 36, "36 columns, as the real one")
	for j in WonderBuilds.MAUSOLEUM_STEPS:
		assert_eq(_block(_w(&"mausoleum", 9 - j, 18 + j, 0)), BlockIds.MARBLE, "roof step %d" % j)
		assert_eq(_block(_w(&"mausoleum", 9 - j + 1, 18 + j, 0)), BlockIds.AIR, "the step in front of step %d" % j)
	var top := 18 + WonderBuilds.MAUSOLEUM_STEPS
	var horses := 0
	for x: int in [-3, -1, 1, 3]:
		if _block(_w(&"mausoleum", x, top + 1, -2)) == BlockIds.MARBLE:
			horses += 1
	assert_eq(horses, 4, "four horses on top")
	assert_true(_walks(_w(&"mausoleum", 0, 0, -24), _in(_w(&"mausoleum", -4, 9, -6), _w(&"mausoleum", 4, 9, 6))),
		"up the stairs, between the columns into the tomb hall")


# --- The Colossus ---

func test_the_colossus_stands_in_bronze_legs_together_on_a_marble_base() -> void:
	var g := WonderBuilds.COLOSSUS_FEET
	assert_eq(_block(_w(&"colossus", 0, 3, 0)), BlockIds.MARBLE, "a white marble base")
	assert_eq(_block(_w(&"colossus", -1, g + 2, 0)), BlockIds.BRONZE, "a leg")
	assert_eq(_block(_w(&"colossus", 1, g + 2, 0)), BlockIds.BRONZE, "the other leg")
	assert_eq(_block(_w(&"colossus", 0, g + 2, 0)), BlockIds.AIR, "legs together, not over a harbour")
	var b := WonderBuilds.bounds(&"colossus")
	assert_between((b[1] as Vector3i).y - Y, 32, 38, "about 33 m of statue on its base")
	assert_eq(_block(_w(&"colossus", 4, g + 27, 0)), BlockIds.BEACON_FIRE, "the torch held high")
	assert_true(_walks(_w(&"colossus", 0, 0, -15), func(p: Vector3i) -> bool: return p.y == Y + g),
		"up the steps to its feet")


# --- The Lighthouse ---

func test_the_lighthouse_has_three_tiers_and_a_fire_and_a_child_climbs_to_it() -> void:
	assert_eq(_block(_w(&"lighthouse", 6, 5, 0)), BlockIds.WHITE_BRICK, "the square first tier")
	assert_eq(_block(_w(&"lighthouse", 3, 20, 0)), BlockIds.WHITE_BRICK, "the eight-sided second tier")
	assert_eq(_block(_w(&"lighthouse", 3, 20, 3)), BlockIds.AIR, "its corners are cut")
	assert_eq(_block(_w(&"lighthouse", 2, 30, 0)), BlockIds.WHITE_BRICK, "the round third tier")
	assert_eq(_block(_w(&"lighthouse", 2, 30, 2)), BlockIds.AIR)
	var top := WonderBuilds.LIGHTHOUSE_TOP
	assert_eq(_block(_w(&"lighthouse", 0, top, 0)), BlockIds.BEACON_FIRE, "the fire at the top")
	var causeway := Vector3i(WonderTour.CAUSEWAY.position.x + 30, Y, -40)
	var island := Rect2i(WonderTour.CAUSEWAY.position.x + 28, WonderTour.ISLAND.y - 14, 60, 28)
	assert_true(_walks(causeway, _in(_w(&"lighthouse", -1, top, -1), _w(&"lighthouse", 1, top, 1)), 1, island),
		"along the causeway, in at the door, up the stairs and the spiral to the fire")


# --- The tour's own ---

func test_the_landing_square_paths_signposts_and_plaques() -> void:
	assert_eq(_block(Vector3i(0, Y - 1, 0)), BlockIds.PAVING, "the landing square")
	assert_eq(_block(Vector3i(0, Y, 0)), BlockIds.AIR, "the landing spot is free")
	for id in WonderTour.ids():
		assert_eq(_block(WonderTour.plaque(id)), BlockIds.WONDER_PLAQUE, "%s's plaque" % id)
		var s := WonderTour.signpost(id)
		assert_eq(_block(Vector3i(s.x, Y, s.y)), BlockIds.LOG, "%s's signpost" % id)
		var ends := WonderTour.path(id)
		var surface := WonderTour.NATURE_PATH_BLOCK if WonderFacts.tour_of(id) == &"nature" else BlockIds.PAVING
		for t in 21:   # every step along the path is paving (nature's: a dirt path) to stand on
			var p := Vector2i((Vector2(ends[0]).lerp(Vector2(ends[1]), t / 20.0)).round())
			assert_eq(_block(Vector3i(p.x, Y - 1, p.y)), surface, "%s's path at %s" % [id, p])
			assert_true(_stands(Vector3i(p.x, Y, p.y)), "%s's path is clear at %s" % [id, p])
	assert_eq(_block(WonderTour.tour_plaque()), BlockIds.WONDER_PLAQUE)


func test_the_builds_are_worked_out_once_and_bucketed_by_chunk_column() -> void:
	var boxes := WonderBuilds.boxes(&"pyramid")
	assert_same(WonderBuilds.boxes(&"pyramid"), boxes, "the same list every time")
	var c := WonderTour.WONDERS[&"pyramid"].centre as Vector2i
	var bucket := WonderBuilds.column_boxes(floori(c.x / 16.0), floori(c.y / 16.0))
	assert_gt(bucket.size(), 20)
	for b: Array in bucket:
		assert_true(b.size() == 3 and b[0] is Vector3i and b[1] is Vector3i and b[2] is int)
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		assert_true(lo.x < hi.x and lo.y < hi.y and lo.z < hi.z, "a box with room in it")
