extends GutTest
## Owner #78 (spec §24), the second tour: the New Seven Wonders (chosen in 2007) in world 41. Where they stand
## (WonderTour: round their own square at the end of the Wonders Road, west of the landing square), the ground under
## them (WondersShape, NewSevenGround: level for the flat ones, the Great Wall's ridge, Corcovado, Huayna Picchu), the
## road with its speed pads, the square's signposts and plaque, Green Meadows' own land far out; their words
## (WonderFacts: honest, religion as culture and belief, hard history named with respect) and the Wonders Passport for
## both tours (WondersPassportRules).

const Y := WonderTour.BASE_Y
const NEW: Array[StringName] = [&"great_wall", &"petra", &"colosseum", &"chichen_itza", &"machu_picchu", &"taj_mahal",
	&"christ_redeemer"]

var shape: WondersShape


func before_all() -> void:
	shape = WondersShape.new(4242)


func test_the_second_tour_is_the_new_seven_in_their_lists_order() -> void:
	assert_eq(WonderFacts.tour_ids(&"new"), NEW)
	assert_eq(WonderFacts.TOUR_IDS, [&"ancient", &"new", &"nature"] as Array[StringName])
	for id in NEW:
		assert_true(WonderFacts.has(id) and WonderTour.has(id), str(id))
		assert_eq(WonderFacts.tour_of(id), &"new")
		assert_eq(WonderFacts.status(id), WonderFacts.STANDING, "%s still stands" % id)
		assert_eq(WonderTour.square_of(id), WonderTour.NEW_SQUARE)
	assert_eq(WonderFacts.tour_of(&"pyramid"), &"ancient")
	assert_eq(WonderTour.square_of(&"pyramid"), Vector2i.ZERO)
	assert_eq(WonderFacts.tour_of(&"moon"), &"")


func test_the_wonders_road_runs_west_from_the_landing_square_to_the_new_square() -> void:
	var page := BlockLibrary.page_of(WonderTour.ROAD_BLOCK)
	assert_eq(page, BlockLibrary.page_of(BlockIds.GRASS), "the road adds no material to the chunks it crosses")
	var road := WonderTour.road()
	assert_lt(Vector2(road[0]).length(), float(WonderTour.PLAZA_R), "it leaves the landing square")
	assert_lt(Vector2(road[1] - WonderTour.NEW_SQUARE).length(), float(WonderTour.PLAZA_R), "it reaches the new square")
	assert_eq(road[0].y, 0)
	assert_eq(road[1].y, 0)
	for x in range(road[1].x, road[0].x + 1, 5):
		assert_eq(shape.height_at(x, 0), Y, "the road is level at %d" % x)
		for z in range(-1, 2):
			assert_has([WonderTour.ROAD_BLOCK, BlockIds.SPEED_PAD], WonderBuilds.block_at(Vector3i(x, Y - 1, z)),
				"the road's surface at %d, %d" % [x, z])
			assert_eq(WonderBuilds.block_at(Vector3i(x, Y, z)), -1, "nothing stands on the road at %d, %d" % [x, z])
		for z in range(-3, 4):
			assert_false(shape.tree_at(x, z), "no tree on the road at %d, %d" % [x, z])
	var pads := WonderTour.road_pads()
	assert_gte(pads.size(), 5, "speed pads along it past the first park")
	for x in pads:
		assert_gt(float(-x), float(GraphicsPreset.MAX_VIEW_DISTANCE), "out of the landing spot's view (a glowing material)")
		for z in range(-1, 2):
			assert_eq(WonderBuilds.block_at(Vector3i(x, Y - 1, z)), BlockIds.SPEED_PAD, "a row of speed pads at %d" % x)
		assert_between(x, road[1].x, road[0].x)


func test_the_new_square_its_signposts_its_plaque_and_the_roads_signs() -> void:
	var c := WonderTour.NEW_SQUARE
	assert_eq(WonderBuilds.block_at(Vector3i(c.x, Y - 1, c.y)), BlockIds.PAVING, "the New Seven's square")
	var tp := WonderTour.tour_plaque(&"new")
	assert_eq(WonderBuilds.block_at(tp), BlockIds.WONDER_PLAQUE)
	assert_eq(WonderTour.plaque_at(tp), &"tour_new")
	assert_eq(WonderTour.plaque_at(WonderTour.tour_plaque()), &"tour", "the landing square's stays the first tour's")
	var seen := {}
	for tour: StringName in [&"ancient", &"new"]:   # the Wonders Road's two ends
		var s := WonderTour.road_signpost(tour)
		assert_eq(WonderBuilds.block_at(Vector3i(s.x, Y, s.y)), BlockIds.LOG, "the road's signpost on %s's square" % tour)
		assert_lte(Vector2(s - WonderTour.square(tour)).length(), float(WonderTour.PLAZA_R))
		assert_gt(absi(s.y), 1, "beside the road, not on it")
		seen[s] = true
	for id in NEW:
		var s := WonderTour.signpost(id)
		assert_false(seen.has(s), "%s's signpost has its own place" % id)
		seen[s] = true
		assert_lte(Vector2(s - c).length(), float(WonderTour.PLAZA_R), "%s's signpost on the new square" % id)
		assert_true(absi(s.y) > 1 or s.x < WonderTour.road()[1].x, "%s's signpost is off the road" % id)


func test_each_new_wonder_stands_in_its_region_apart_from_every_other() -> void:
	var ids := WonderTour.ids()
	for id in NEW:
		var r := WonderTour.reach(id)
		for p: Vector2i in [r.position, r.end - Vector2i.ONE, Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.position.y)]:
			assert_lt(WonderTour.new_distance(p.x, p.y), WonderTour.NEW_R - 4.0, "%s is in its region (%s)" % [id, p])
			assert_gt(Vector2(p).length(), float(WonderTour.FLAT_R), "%s is past the first park" % id)
		assert_false(r.grow(4).has_point(WonderTour.NEW_SQUARE), "%s keeps off the square" % id)
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			assert_false(WonderTour.reach(ids[i]).grow(3).intersects(WonderTour.reach(ids[j]).grow(3)),
				"%s and %s stand apart" % [ids[i], ids[j]])


func test_the_ground_is_level_under_the_flat_wonders() -> void:
	for id: StringName in [&"petra", &"colosseum", &"chichen_itza", &"machu_picchu", &"taj_mahal"]:
		var f := WonderTour.footprint(id)
		for x in range(f.position.x, f.end.x, 3):
			for z in range(f.position.y, f.end.y, 3):
				assert_eq(shape.height_at(x, z), Y, "%s's ground at %d, %d" % [id, x, z])


func test_the_wall_stands_on_a_ridge_christ_on_corcovado_and_huayna_picchu_behind_machu_picchu() -> void:
	var g := NewSevenGround
	for x: int in [-40, -10, 0, 21, 50]:
		var crest := WonderTour.to_world(&"great_wall", Vector2i(x, 0))
		var want := g.wall_walk(x) - g.WALL_ABOVE
		assert_almost_eq(shape.height_at(crest.x, crest.y) - Y, want, 1, "the ridge's crest under the wall at %d" % x)
		assert_gte(g.wall_walk(x) - (shape.height_at(crest.x, crest.y) - Y), g.WALL_ABOVE, "the wall stands over it")
	var foot := WonderTour.to_world(&"great_wall", Vector2i(0, -26))
	assert_eq(shape.height_at(foot.x, foot.y), Y, "flat ground at the ridge's foot")
	var c: Vector2i = WonderTour.WONDERS[&"christ_redeemer"].centre
	assert_eq(shape.height_at(c.x, c.y), Y + g.CORCOVADO_TOP, "Corcovado's summit")
	assert_eq(shape.height_at(c.x, c.y - 50), Y, "and its foot")
	var hp := WonderTour.to_world(&"machu_picchu", g.HUAYNA)
	assert_eq(shape.height_at(hp.x, hp.y), Y + int(g.HUAYNA_TOP), "Huayna Picchu's peak")
	for x in range(-g.WALL_HALF, g.WALL_HALF):
		assert_lte(absi(g.wall_walk(x + 1) - g.wall_walk(x)), 1, "the walkway climbs a block a step at most (%d)" % x)
	for t: int in g.WALL_TOWERS:
		for d in range(-g.TOWER_HALF, g.TOWER_HALF + 1):
			assert_eq(g.wall_walk(t + d), g.wall_walk(t), "level through the tower at %d" % t)
	assert_eq(g.WALL_C, WonderTour.WONDERS[&"great_wall"].centre, "the ground's hills stand where the wonders do")
	assert_eq(WonderTour.WONDERS[&"great_wall"].face, WonderTour.S, "(the ridge's sums take the wall facing south)")
	assert_eq(g.CORCOVADO_C, WonderTour.WONDERS[&"christ_redeemer"].centre)
	assert_eq(g.HUAYNA_C, WonderTour.to_world(&"machu_picchu", g.HUAYNA))


func test_every_new_path_is_level() -> void:
	for id in NEW:
		var ends := WonderTour.path(id)
		for t in 31:
			var p := Vector2i((Vector2(ends[0]).lerp(Vector2(ends[1]), t / 30.0)).round())
			assert_eq(shape.height_at(p.x, p.y), Y, "%s's path is level at %s" % [id, p])


func test_far_out_it_is_green_meadows_own_land_and_the_edge_blends() -> void:
	var meadows := MeadowsShape.new(4242)
	for p: Vector2i in [Vector2i(-350, 450), Vector2i(-850, 0), Vector2i(-350, -520), Vector2i(-620, 250)]:
		assert_eq(shape.height_at(p.x, p.y), meadows.height_at(p.x, p.y), str(p))
		assert_eq(shape.is_river(p.x, p.y), meadows.is_river(p.x, p.y), str(p))
	var edge := WonderTour.NEW_SQUARE + Vector2i(0, WonderTour.NEW_R + WonderTour.BLEND / 2)
	var h := shape.height_at(edge.x, edge.y)
	var m := meadows.height_at(edge.x, edge.y)
	assert_between(h, mini(Y, m) - 1, maxi(Y, m) + 1, "half way through the blend")


func test_petras_desert_and_the_regions_trees() -> void:
	var front := WonderTour.to_world(&"petra", Vector2i(0, -34))
	assert_true(shape.sandy(front.x, front.y), "sand before Petra's cliff")
	var garden := WonderTour.to_world(&"taj_mahal", Vector2i(10, -30))
	assert_false(shape.sandy(garden.x, garden.y), "the Taj Mahal's garden is green")
	var trees := 0
	for x in range(-520, -180, 2):
		for z in range(-160, 160, 2):
			if shape.tree_at(x, z):
				trees += 1
				if x * x + z * z > WonderTour.BLEND_R * WonderTour.BLEND_R:   # (the first park's olive grove ends there)
					assert_eq(shape.tree_kind(x, z), &"oak", "oaks round the New Seven")
	assert_gt(trees, 40, "a park with trees round the New Seven (%d)" % trees)
	for id in NEW:
		var r := WonderTour.reach(id).grow(WondersShape.CLEAR_MARGIN)
		for x in range(r.position.x, r.end.x, 2):
			for z in range(r.position.y, r.end.y, 2):
				assert_false(shape.tree_at(x, z), "no tree at %s by %s" % [Vector2i(x, z), id])
		var cc: Vector2i = WonderTour.WONDERS[id].centre
		assert_true(shape.is_river(cc.x, cc.y), "%s: spawners keep off it" % id)


func test_the_second_tours_words_are_honest_and_respectful() -> void:
	for id in NEW:
		var w := WonderFacts.of(id)
		assert_between((w.facts as Array).size(), 4, 6, str(id))
		assert_gte((w.quiz as Array).size(), 2, str(id))
		assert_true(str(w.sight).begins_with("You reached"), str(id))
		assert_true(str(w.secret).begins_with("You found"), str(id))
		for q: Dictionary in w.quiz:
			assert_true(str(q.id).begins_with(String(id)), str(q.id))
	var said := func(id: StringName) -> String: return " ".join(WonderFacts.of(id).facts as Array)
	assert_string_contains(WonderFacts.of(&"christ_redeemer").sight, "Christians believe", "religion as belief")
	assert_string_contains(WonderFacts.of(&"chichen_itza").sight, "they believed was a god", "religion as belief")
	assert_string_contains(said.call(&"taj_mahal"), "the holy book of Islam", "religion as culture")
	assert_string_contains(said.call(&"colosseum"), "enslaved people", "hard history named with respect")
	assert_string_contains(said.call(&"great_wall"), "were made to build it", "forced labour named")
	assert_string_contains(said.call(&"machu_picchu"), "Spanish conquerors", "the conquest named")
	assert_string_contains(said.call(&"great_wall"), "cannot see it from the Moon", "a myth put right")
	assert_string_contains(" ".join(WonderFacts.NEW_TOUR_FACTS as Array), "2007")
	assert_string_contains(WonderFacts.of(&"petra").secret, "solid rock", "the urn's legend, told as a legend")
	assert_eq(WonderFacts.called(&"petra"), "Petra", "said without a \"the\"")
	assert_eq(WonderFacts.called(&"christ_redeemer"), "Christ the Redeemer")
	assert_eq(WonderFacts.called(&"great_wall"), "the Great Wall of China")
	assert_eq(WonderFacts.called(&"pyramid"), "the Great Pyramid of Giza")


func test_the_passport_counts_both_tours_and_says_when_a_tour_is_complete() -> void:
	var w := WonderData.new()
	for id in NEW.slice(0, 6):
		w.stamp(id)
	assert_eq(WondersPassportRules.count_words(w), "6 of 21 stamps")
	assert_eq(WondersPassportRules.tour_stamped(w, &"new"), 6)
	w.stamp(NEW[6])
	assert_eq(WondersPassportRules.stamp_words(w, NEW[6]),
		"Stamp! You have all 7 stamps of the New Seven Wonders! 7 of 21 wonders in your Wonders Passport.")
	assert_eq(WondersPassportRules.stamp_words(w, &"pyramid"), "Stamp! 7 of 21 wonders in your Wonders Passport.")
	var list: Array[Dictionary] = []
	for id in WonderFacts.ORDER:
		list.append({"id": id, "name": WonderFacts.display_name(id), "pos": WonderTour.centre(id),
			"found": WonderFacts.tour_of(id) == &"new"})
	assert_eq(WondersPassportRules.tour_progress_words(list, Vector3.ZERO, &"new"),
		"You visited all 7 of the New Seven Wonders! The Seven Ancient Wonders wait along the Wonders Road. Follow the arrow.")
	list[0].found = true
	assert_string_contains(WondersPassportRules.tour_progress_words(list, Vector3.ZERO, &"ancient"),
		"1 of 7 of the Seven Wonders of the Ancient World visited! Next: the ")
	assert_string_contains(WondersPassportRules.clue(&"petra"), "Wonders Road")
	var back := WonderData.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	assert_true(back.stamped(&"christ_redeemer"), "the new stamps are saved")
	back.answer("great_wall_1", true)
	assert_true(WonderData.from_dict(back.to_dict()).quiz_right("great_wall_1"), "and their quizzes")
