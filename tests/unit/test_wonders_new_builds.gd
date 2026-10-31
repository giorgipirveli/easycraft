extends GutTest
## Owner #78 (spec §24), the second tour: each of the New Seven Wonders recognisable from the real one's shape and
## colours in our own blocks (§3c), at a size a child walks round, walks into where the real one can be entered and
## climbs where it is safe (WonderBuildsNew). A child's walk is checked cell by cell (tests/fakes/wonder_walker.gd):
## standing needs two free cells over a solid one, a step up is one block (with room over the head), a fall a few
## blocks at most.

const Walker := preload("res://tests/fakes/wonder_walker.gd")
const Y := WonderTour.BASE_Y

var shape: WondersShape
var walker: Walker


func before_all() -> void:
	shape = WondersShape.new(7)
	walker = Walker.new(shape)


func _b(id: StringName, x: int, y: int, z: int) -> int:
	return walker.block(Walker.at(id, x, y, z))


func _count(id: StringName, block: int) -> int:
	var n := 0
	for b: Array in WonderBuilds.boxes(id):
		if b[2] == block:
			var s: Vector3i = b[1] - b[0]
			n += s.x * s.y * s.z
	return n


# --- The Great Wall ---

func test_the_great_wall_runs_on_its_ridge_with_battlements_to_the_north_and_five_towers() -> void:
	var g := NewSevenGround
	for x: int in [-50, -30, -10, 10, 30, 50]:
		var h := g.wall_walk(x)
		assert_eq(_b(&"great_wall", x, h - 1, 0), BlockIds.WALL_BRICK, "the walkway at %d" % x)
		assert_eq(_b(&"great_wall", x, h, 0), BlockIds.AIR, "room to walk at %d" % x)
		assert_eq(_b(&"great_wall", x, h, -3), BlockIds.WALL_BRICK, "the low inner parapet at %d" % x)
		assert_eq(_b(&"great_wall", x, h, 2), BlockIds.WALL_BRICK, "the outer battlements at %d" % x)
	var outer := Walker.at(&"great_wall", 0, 0, 2)
	var inner := Walker.at(&"great_wall", 0, 0, -3)
	assert_lt(outer.z, inner.z, "the battlements face north, where raiders came from")
	for t: int in g.WALL_TOWERS:
		var h := g.wall_walk(t)
		assert_eq(_b(&"great_wall", t, h, 0), BlockIds.AIR, "the walkway passes through the tower at %d" % t)
		assert_eq(_b(&"great_wall", t, h + 4, 0), BlockIds.WALL_BRICK, "the tower's roof at %d" % t)
	var east := Walker.at(&"great_wall", g.WALL_TOWERS[0], g.wall_walk(g.WALL_TOWERS[0]) + 5, 0)
	assert_eq(walker.block(east), BlockIds.BEACON_FIRE, "a beacon fire on a tower")
	assert_gt(east.x, WonderTour.WONDERS[&"great_wall"].centre.x, "on the east one")
	assert_gt(_count(&"great_wall", BlockIds.WALL_BRICK), 3000, "a long wall of grey bricks")


func test_a_child_climbs_onto_the_great_wall_and_walks_along_it_from_tower_to_tower() -> void:
	var g := NewSevenGround
	var within := Walker.around(&"great_wall")
	var gate := Walker.at(&"great_wall", 0, 0, -28)
	for t: int in [0, 21, -21, 42]:
		var h := g.wall_walk(t)
		assert_true(walker.walks(gate, Walker.inside(Walker.at(&"great_wall", t - 1, h, -1), Walker.at(&"great_wall", t + 1, h, 0)),
			within), "up the stair and along the walkway into the tower at %d" % t)


# --- Petra ---

func test_petra_is_carved_into_a_rose_cliff_with_the_treasurys_facade() -> void:
	var f := WonderBuildsNew.PETRA_FACE
	assert_eq(_b(&"petra", 12, 10, 0), BlockIds.ROSE_ROCK, "the cliff")
	assert_eq(_b(&"petra", 0, 5, -20), BlockIds.AIR, "the Siq, a narrow gorge ...")
	assert_eq(_b(&"petra", 2, 5, -20), BlockIds.ROSE_ROCK, "... 3 wide")
	assert_eq(_b(&"petra", 0, 30, -20), BlockIds.AIR, "open to the sky")
	var columns := 0
	for x in range(-9, 10):
		if _b(&"petra", x, 5, f) == BlockIds.ROSE_COLUMN:
			columns += 1
	assert_eq(columns, 6, "six columns across the Treasury's porch")
	for y in range(WonderBuildsNew.PETRA_LEDGE, WonderBuildsNew.PETRA_LEDGE + 3):
		assert_eq(_b(&"petra", 0, y, f), BlockIds.ROSE_STONE, "the urn on top (solid rock)")


func test_a_child_walks_through_the_siq_into_the_treasury_and_up_to_the_urn() -> void:
	var within := Walker.around(&"petra")
	var gate := Walker.at(&"petra", 0, 0, -31)
	var f := WonderBuildsNew.PETRA_FACE
	assert_true(walker.walks(gate, Walker.inside(Walker.at(&"petra", -3, 0, 8), Walker.at(&"petra", 3, 0, 12)), within),
		"through the Siq to the court before the Treasury")
	assert_true(walker.walks(gate, Walker.inside(Walker.at(&"petra", -3, 0, f + 5), Walker.at(&"petra", 3, 0, f + 9)), within),
		"in at its door to the chamber")
	var ledge := WonderBuildsNew.PETRA_LEDGE
	assert_true(walker.walks(gate, Walker.inside(Walker.at(&"petra", 1, ledge, f - 1), Walker.at(&"petra", 2, ledge, f - 1)),
		within), "up the stair cut in the rock to the ledge by the urn")


# --- The Colosseum ---

func test_the_colosseum_is_an_oval_of_arches_broken_on_its_south_side() -> void:
	var a := int(WonderBuildsNew.COL_A)
	assert_eq(_b(&"colosseum", -23, 15, 0), BlockIds.TRAVERTINE, "four storeys on the north side")
	assert_eq(_b(&"colosseum", 23, 12, 0), BlockIds.AIR, "the south side broke off above its second storey")
	assert_eq(_b(&"colosseum", 23, 7, 0), BlockIds.TRAVERTINE)
	var south := Walker.at(&"colosseum", 23, 0, 0)
	assert_gt(south.z, WonderTour.WONDERS[&"colosseum"].centre.y, "(frame +x is south)")
	assert_gt(WonderBuildsNew.arch_rects().size(), 24, "rows of arches all round")
	var east := Walker.at(&"colosseum", 0, 0, -a)
	var west := Walker.at(&"colosseum", 0, 0, a)
	assert_gt(absi(east.x - west.x), absi(Walker.at(&"colosseum", -24, 0, 0).z - Walker.at(&"colosseum", 24, 0, 0).z),
		"its long way runs east-west")
	assert_eq(_b(&"colosseum", 0, -1, 0), BlockIds.SAND, "the arena's sand")
	var tops: Array[int] = []
	for x in range(10, 22):   # the tiers rise from the arena's wall outward (their tops, looking down from above)
		var y := 20
		while y > -2 and Walker.is_free(_b(&"colosseum", x, y, -8)):
			y -= 1
		tops.append(y)
	for i in tops.size() - 1:
		assert_gte(tops[i + 1], tops[i], "the tiers rise outward (%s)" % [tops])
	assert_gt(tops[-1] - tops[0], 5)


func test_a_child_walks_into_the_arena_and_climbs_the_tiers_to_the_top() -> void:
	var within := Walker.around(&"colosseum")
	var gate := Walker.at(&"colosseum", 0, 0, -34)
	assert_true(walker.walks(gate, Walker.inside(Walker.at(&"colosseum", -3, 0, -3), Walker.at(&"colosseum", 3, 0, 3)), within),
		"in at the east entrance to the arena")
	var top := WonderBuildsNew.TOP_TIER
	assert_true(walker.walks(gate, func(p: Vector3i) -> bool: return p.y >= Y + top, within),
		"up the stairs to the walk behind the top tier")


# --- Chichen Itza ---

func test_el_castillo_has_nine_terraces_four_stairs_and_the_serpents_heads_to_the_north() -> void:
	var t := WonderBuildsNew.CASTILLO_TERRACES
	assert_eq(t.size(), 9, "nine terraces")
	for k in t.size():
		assert_eq(_b(&"chichen_itza", t[k], 2 * k, 5), BlockIds.MAYA_STONE, "terrace %d" % k)
		if k + 1 < t.size():
			assert_eq(_b(&"chichen_itza", t[k], 2 * k + 2, 5), BlockIds.AIR, "stepped in above terrace %d" % k)
	for side in 4:   # a stair up each side
		for j in WonderBuildsNew.CASTILLO_STEPS:
			var c := WonderBuildsNew._quarter(Vector3i(0, j, -(25 - j)), side)
			assert_eq(_b(&"chichen_itza", c.x, c.y, c.z), BlockIds.MAYA_STONE, "stair %d step %d" % [side, j])
	var head := Walker.at(&"chichen_itza", 3, 0, -26)
	assert_eq(walker.block(head), BlockIds.SERPENT_HEAD, "a feathered serpent's head at the foot of the stair")
	assert_lt(head.z, WonderTour.WONDERS[&"chichen_itza"].centre.y, "the north stair, as the real one")
	assert_eq(_b(&"chichen_itza", 0, WonderBuildsNew.CASTILLO_TOP + 4, -4), BlockIds.MAYA_CARVING, "the temple's carved band")


func test_a_child_climbs_el_castillo_into_its_temple() -> void:
	var within := Walker.around(&"chichen_itza")
	var gate := Walker.at(&"chichen_itza", 31, 0, 0)
	var t := WonderBuildsNew.CASTILLO_TOP
	assert_true(walker.walks(gate, Walker.inside(Walker.at(&"chichen_itza", -2, t, -2), Walker.at(&"chichen_itza", 2, t, 2)),
		within), "up a stair and into the temple on top")


# --- Machu Picchu ---

func test_machu_picchu_has_terraces_houses_and_its_temples_under_huayna_picchu() -> void:
	for k in WonderBuildsNew.MACHU_TERRACES:
		var r := WonderBuildsNew.machu_terrace(k)
		assert_eq(_b(&"machu_picchu", r.position.x, 2 * k + 1, 0), BlockIds.GRASS, "terrace %d's grass" % k)
		assert_eq(_b(&"machu_picchu", r.position.x, 2 * k, 0), BlockIds.INCA_STONE, "terrace %d's stone wall" % k)
	assert_gt(_count(&"machu_picchu", BlockIds.HAY), 60, "thatched roofs")
	var top := WonderBuildsNew.MACHU_TOP
	assert_eq(_b(&"machu_picchu", -19, top + 1, 4), BlockIds.AIR, "the Temple of the Three Windows' windows")
	assert_eq(_b(&"machu_picchu", -19, top + 1, 3), BlockIds.INCA_STONE)
	assert_eq(_b(&"machu_picchu", -12, top + 4, 13), BlockIds.INCA_STONE, "the Intihuatana stone on its knoll")
	var peak := WonderTour.to_world(&"machu_picchu", NewSevenGround.HUAYNA)
	assert_gt(shape.height_at(peak.x, peak.y), Y + top + 20, "Huayna Picchu towers behind")


func test_a_child_climbs_the_stair_to_machu_picchus_plaza() -> void:
	var within := Walker.around(&"machu_picchu")
	var top := WonderBuildsNew.MACHU_TOP
	assert_true(walker.walks(Walker.at(&"machu_picchu", 0, 0, -29),
		Walker.inside(Walker.at(&"machu_picchu", -4, top, -2), Walker.at(&"machu_picchu", 4, top, 2)), within),
		"up the stair through the terraces to the plaza")


# --- The Taj Mahal ---

func test_the_taj_mahal_has_its_dome_minarets_garden_and_river() -> void:
	var c := WonderBuildsNew.TAJ_TOMB
	var gold := 20 + WonderBuildsNew.DOME.size()
	assert_eq(_b(&"taj_mahal", 0, gold, c), BlockIds.GOLD_LEAF, "the golden top on the dome")
	assert_eq(_b(&"taj_mahal", 7, 22, c), BlockIds.MARBLE, "the onion dome bulges wider than its drum")
	assert_eq(_b(&"taj_mahal", 5, 18, c), BlockIds.MARBLE)
	assert_eq(_b(&"taj_mahal", 6, 18, c), BlockIds.AIR)
	for m: Vector2i in WonderBuildsNew.TAJ_MINARETS:
		assert_eq(_b(&"taj_mahal", m.x + 2, 12, m.y), BlockIds.MARBLE, "a minaret at %s" % m)
	assert_eq(_b(&"taj_mahal", 0, -1, -30), BlockIds.WATER, "the long pool in the garden")
	var river := Walker.at(&"taj_mahal", 0, -1, 36)
	assert_eq(walker.block(river), BlockIds.WATER, "the river behind it ...")
	assert_lt(river.z, Walker.at(&"taj_mahal", 0, 0, c).z, "... to the north, as the real one's")
	assert_eq(_b(&"taj_mahal", 0, 3, c), BlockIds.INLAID_MARBLE, "Mumtaz Mahal's tomb in the middle of the hall")
	assert_eq(_b(&"taj_mahal", 0, 5, -41), BlockIds.AIR, "the way through the great gate")
	assert_eq(_b(&"taj_mahal", -6, 5, -41), BlockIds.MUGHAL_RED, "of red sandstone")


func test_a_child_walks_through_the_gate_into_the_hall_and_up_the_minaret() -> void:
	var within := Walker.around(&"taj_mahal")
	var gate := Walker.at(&"taj_mahal", 0, 0, -48)
	var c := WonderBuildsNew.TAJ_TOMB
	var f := WonderBuildsNew.TAJ_FLOOR
	assert_true(walker.walks(gate, Walker.inside(Walker.at(&"taj_mahal", -2, f, c - 2), Walker.at(&"taj_mahal", 2, f, c + 2)),
		within), "through the gate and the garden, up the plinth, into the hall")
	var m := WonderBuildsNew.TAJ_HOLLOW
	var top := WonderBuildsNew.MINARET_FLOOR + 1
	assert_true(walker.walks(gate, Walker.inside(Walker.at(&"taj_mahal", m.x - 1, top, m.y - 1),
		Walker.at(&"taj_mahal", m.x + 1, top, m.y + 1)), within), "in at the minaret's door and up its spiral stair")


# --- Christ the Redeemer ---

func test_christ_the_redeemer_stands_on_corcovado_with_open_arms_facing_the_square() -> void:
	var s := WonderBuildsNew.statue_foot()
	assert_eq(s, NewSevenGround.CORCOVADO_TOP + WonderBuildsNew.PEDESTAL, "on its pedestal on the summit")
	assert_eq(_b(&"christ_redeemer", -12, s + 17, 0), BlockIds.SOAPSTONE, "one hand ...")
	assert_eq(_b(&"christ_redeemer", 12, s + 17, 0), BlockIds.SOAPSTONE, "... and the other: arms spread wide")
	assert_eq(_b(&"christ_redeemer", 0, s + 24, -1), BlockIds.SOAPSTONE, "its head")
	assert_eq(_b(&"christ_redeemer", 0, s + 25, -1), BlockIds.AIR)
	var b := WonderBuilds.bounds(&"christ_redeemer")
	assert_between((b[1] as Vector3i).y - Y, 70, 72, "high over everything round it")
	var front := Walker.at(&"christ_redeemer", 0, 0, -10)
	var back := Walker.at(&"christ_redeemer", 0, 0, 10)
	var sq := Vector2(WonderTour.NEW_SQUARE)
	assert_lt(Vector2(front.x, front.z).distance_to(sq), Vector2(back.x, back.z).distance_to(sq), "facing the square")


func test_a_child_climbs_the_stair_up_corcovado_to_the_statues_feet() -> void:
	var within := Walker.around(&"christ_redeemer")
	var top := NewSevenGround.CORCOVADO_TOP
	assert_true(walker.walks(Walker.at(&"christ_redeemer", 0, 0, -51),
		Walker.inside(Walker.at(&"christ_redeemer", -3, top, -6), Walker.at(&"christ_redeemer", 3, top, -3)), within),
		"up the 40 steps to the summit's terrace")


func test_the_builds_are_worked_out_once_with_the_first_tours() -> void:
	for id: StringName in WonderFacts.tour_ids(&"new"):
		var boxes := WonderBuilds.boxes(id)
		assert_gt(boxes.size(), 20, str(id))
		assert_same(WonderBuilds.boxes(id), boxes)
		var bounds := WonderBuilds.bounds(id)
		var r := WonderTour.reach(id)
		assert_true(r.grow(1).encloses(Rect2i((bounds[0] as Vector3i).x, (bounds[0] as Vector3i).z,
			(bounds[1] as Vector3i).x - (bounds[0] as Vector3i).x, (bounds[1] as Vector3i).z - (bounds[0] as Vector3i).z)),
			"%s's blocks stay within its reach (%s in %s)" % [id, bounds, r])
