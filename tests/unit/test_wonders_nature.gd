extends GutTest
## Owner #78 (spec §24), the third tour: the Seven Natural Wonders of the World (a list from 1997) in world 41. Where
## they stand (WonderTour: round their own square at the end of the Nature Trail, south of the landing square, out of
## the landing spot's view), the trail with its speed pads, the square's signposts and plaque; their words (WonderFacts:
## honest, nature's science, religion as culture and belief, people of history only) and the Wonders Passport for three
## tours (WondersPassportRules).

const Y := WonderTour.BASE_Y
const NATURE: Array[StringName] = [&"grand_canyon", &"barrier_reef", &"rio_harbour", &"everest", &"northern_lights",
	&"paricutin", &"victoria_falls"]


func test_the_third_tour_is_the_seven_natural_wonders_in_their_lists_order() -> void:
	assert_eq(WonderFacts.tour_ids(&"nature"), NATURE)
	assert_eq(WonderFacts.TOUR_IDS, [&"ancient", &"new", &"nature"] as Array[StringName])
	assert_eq(WonderFacts.ORDER.size(), 21, "three tours of seven")
	assert_eq(WonderTour.ids().size(), 21)
	for id in NATURE:
		assert_true(WonderFacts.has(id) and WonderTour.has(id), str(id))
		assert_eq(WonderFacts.tour_of(id), &"nature")
		assert_eq(WonderFacts.status(id), WonderFacts.NATURAL, "%s is made by nature" % id)
		assert_eq(WonderTour.square_of(id), WonderTour.NATURE_SQUARE)
	assert_eq(WonderFacts.tour_info(&"nature").plaque, &"tour_nature")
	assert_eq(WonderFacts.tour_of_plaque(&"tour_nature"), &"nature")
	for id: StringName in NATURE + [&"tour_nature"]:
		assert_true(WonderStamp.INKS.has(id), "%s's stamp has its own ink" % id)


func test_the_nature_square_is_south_out_of_the_landing_spots_view() -> void:
	var s := Vector2(WonderTour.NATURE_SQUARE)
	assert_gt(s.y, 0.0, "south of the landing square")
	assert_gt(s.length() - WonderTour.NATURE_R, float(GraphicsPreset.MAX_VIEW_DISTANCE),
		"the whole region is past the landing spot's farthest view")
	var new_sq := Vector2(WonderTour.NEW_SQUARE)
	assert_gt(s.distance_to(new_sq), WonderTour.NATURE_R + WonderTour.NEW_R + 2.0 * WonderTour.BLEND,
		"apart from the New Seven's region and its blend")


func test_the_nature_trail_runs_from_the_landing_square_to_the_nature_square() -> void:
	var shape := WondersShape.new(4242)
	assert_eq(BlockLibrary.page_of(WonderTour.TRAIL_BLOCK), BlockLibrary.page_of(BlockIds.GRASS),
		"the trail adds no material to the chunks it crosses")
	var trail := WonderTour.trail()
	assert_lt(Vector2(trail[0]).length(), float(WonderTour.PLAZA_R), "it leaves the landing square")
	assert_lt(Vector2(trail[1] - WonderTour.NATURE_SQUARE).length(), float(WonderTour.PLAZA_R), "it reaches the nature square")
	var cells := WonderTour.line_cells(trail[0], trail[1])
	for i in range(0, cells.size(), 7):
		var c: Vector2i = cells[i]
		assert_eq(shape.height_at(c.x, c.y), Y, "the trail is level at %s" % c)
		assert_has([WonderTour.TRAIL_BLOCK, BlockIds.SPEED_PAD], WonderBuilds.block_at(Vector3i(c.x, Y - 1, c.y)),
			"the trail's surface at %s" % c)
		assert_eq(WonderBuilds.block_at(Vector3i(c.x, Y, c.y)), -1, "nothing stands on the trail at %s" % c)
		for d in range(-3, 4):
			assert_false(shape.tree_at(c.x + d, c.y), "no tree on the trail at %s" % (c + Vector2i(d, 0)))
	var pads := WonderTour.trail_pads()
	assert_gte(pads.size(), 5, "speed pads along it past the first park")
	for p: Vector2i in pads:
		assert_gt(Vector2(p).length(), float(GraphicsPreset.MAX_VIEW_DISTANCE), "out of the landing spot's view")
		for dx in range(-1, 2):
			assert_eq(WonderBuilds.block_at(Vector3i(p.x + dx, Y - 1, p.y)), BlockIds.SPEED_PAD, "a row of pads at %s" % p)
		assert_has(cells, p, "on the trail")


func test_the_trail_keeps_off_the_first_tours_wonders_and_paths() -> void:
	var trail := WonderTour.trail()
	for id: StringName in WonderFacts.tour_ids(&"ancient"):
		var r := WonderTour.reach(id).grow(3)
		for c in WonderTour.line_cells(trail[0], trail[1]):
			assert_false(r.has_point(c), "the trail keeps off %s (%s)" % [id, c])
		var ends := WonderTour.path(id)
		var a := Vector2(trail[1] - trail[0]).normalized()
		var b := Vector2(ends[1] - ends[0]).normalized()
		assert_lt(a.dot(b), cos(deg_to_rad(18.0)), "the trail leaves the square away from %s's path" % id)


func test_the_nature_square_its_signposts_its_plaque_and_the_trails_signs() -> void:
	var c := WonderTour.NATURE_SQUARE
	assert_eq(WonderBuilds.block_at(Vector3i(c.x, Y - 1, c.y)), BlockIds.PAVING, "the nature square")
	var tp := WonderTour.tour_plaque(&"nature")
	assert_eq(WonderBuilds.block_at(tp), BlockIds.WONDER_PLAQUE)
	assert_eq(WonderTour.plaque_at(tp), &"tour_nature")
	var seen := {}
	for end: StringName in [&"ancient", &"nature"]:
		var s := WonderTour.trail_signpost(end)
		assert_eq(WonderBuilds.block_at(Vector3i(s.x, Y, s.y)), BlockIds.LOG, "the trail's signpost on %s's square" % end)
		assert_lte(Vector2(s - WonderTour.square(end)).length(), float(WonderTour.PLAZA_R))
		seen[s] = true
	var trail := WonderTour.trail()
	var on_trail := WonderTour.line_cells(trail[0], trail[1])
	for id in WonderFacts.ORDER:
		var s := WonderTour.signpost(id)
		assert_false(seen.has(s), "%s's signpost has its own place" % id)
		seen[s] = true
		for d in range(-1, 2):
			assert_false(on_trail.has(s + Vector2i(d, 0)), "%s's signpost is off the trail" % id)
	for tour: StringName in [&"ancient", &"new"]:
		var r := WonderTour.road_signpost(tour)
		assert_false(seen.has(r), "the Wonders Road's sign on %s's square has its own place" % tour)


func test_each_natural_wonder_stands_in_its_region_apart_from_every_other() -> void:
	var ids := WonderTour.ids()
	for id in NATURE:
		var c: Vector2i = WonderTour.WONDERS[id].centre
		assert_lt(WonderTour.nature_distance(c.x, c.y), WonderTour.NATURE_R - 30.0, "%s is in its region" % id)
		var g := WonderTour.gate(id)
		assert_lt(WonderTour.nature_distance(g.x, g.y), WonderTour.NATURE_R - 10.0, "%s's gate is in its region" % id)
		var r := WonderTour.reach(id)
		assert_false(r.grow(4).has_point(WonderTour.NATURE_SQUARE), "%s keeps off the square" % id)
		var nearest := Vector2(clampi(0, r.position.x, r.end.x - 1), clampi(0, r.position.y, r.end.y - 1))
		assert_gt(nearest.length(), float(GraphicsPreset.MAX_VIEW_DISTANCE) + 24.0,
			"%s is out of the landing spot's view (%s)" % [id, nearest])
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			assert_false(WonderTour.reach(ids[i]).grow(3).intersects(WonderTour.reach(ids[j]).grow(3)),
				"%s and %s stand apart" % [ids[i], ids[j]])


func test_every_nature_path_is_level_and_on_grass_or_snow() -> void:
	var shape := WondersShape.new(4242)
	for id in NATURE:
		var ends := WonderTour.path(id)
		for c in WonderTour.line_cells(ends[0], ends[1]):
			assert_eq(shape.height_at(c.x, c.y), Y, "%s's path is level at %s" % [id, c])
			assert_eq(WonderBuilds.block_at(Vector3i(c.x, Y - 1, c.y)), WonderTour.NATURE_PATH_BLOCK,
				"%s's path is a dirt path at %s" % [id, c])


func test_far_out_it_is_green_meadows_own_land_and_the_edge_blends() -> void:
	var shape := WondersShape.new(4242)
	var meadows := MeadowsShape.new(4242)
	var s := WonderTour.NATURE_SQUARE
	for p: Vector2i in [s + Vector2i(0, 330), s + Vector2i(340, 0), s + Vector2i(-330, 80)]:
		assert_eq(shape.height_at(p.x, p.y), meadows.height_at(p.x, p.y), str(p))
	var edge := s + Vector2i(-WonderTour.NATURE_R - WonderTour.BLEND / 2, 0)
	var h := shape.height_at(edge.x, edge.y)
	var m := meadows.height_at(edge.x, edge.y)
	assert_between(h, mini(Y, m) - 1, maxi(Y, m) + 1, "half way through the blend")


func test_the_third_tours_words_are_honest_and_respectful() -> void:
	for id in NATURE:
		var w := WonderFacts.of(id)
		assert_between((w.facts as Array).size(), 4, 6, str(id))
		assert_eq((w.quiz as Array).size(), 3, str(id))
		assert_true(str(w.sight).begins_with("You reached"), str(id))
		assert_true(str(w.secret).begins_with("You found"), str(id))
		assert_true(w.has("formed"), "%s says how nature made it" % id)
		var rights := {}
		for q: Dictionary in w.quiz:
			assert_true(str(q.id).begins_with(String(id)), str(q.id))
			assert_eq((q.choices as Array).size(), 3)
			rights[q.right] = true
		assert_gt(rights.size(), 1, "%s's right answers are not always in one place" % id)
	var said := func(id: StringName) -> String: return " ".join(WonderFacts.of(id).facts as Array)
	assert_string_contains(said.call(&"grand_canyon"), "Colorado River", "how the canyon was carved")
	assert_string_contains(said.call(&"barrier_reef"), "related to jellyfish", "a coral reef's animals")
	assert_string_contains(said.call(&"everest"), "India", "the highest mountain, and why it grows")
	assert_string_contains(said.call(&"everest"), "still pushing")
	assert_string_contains(said.call(&"everest"), "Buddhists believe", "religion as belief")
	assert_string_contains(said.call(&"northern_lights"), "solar wind", "what makes the northern lights")
	assert_string_contains(said.call(&"paricutin"), "1943", "a volcano born in a cornfield")
	assert_string_contains(said.call(&"paricutin"), "cornfield")
	assert_string_contains(WonderFacts.of(&"victoria_falls").sight, "the smoke that thunders")
	assert_string_contains(said.call(&"rio_harbour"), "River of January")
	assert_string_contains(WonderFacts.of(&"paricutin").secret, "candles and flowers", "religion as culture")
	assert_string_contains(" ".join(WonderFacts.NATURE_TOUR_FACTS as Array), "1997")
	assert_eq(WonderFacts.called(&"everest"), "Mount Everest", "said without a \"the\"")
	assert_eq(WonderFacts.called(&"victoria_falls"), "Victoria Falls")
	assert_eq(WonderFacts.called(&"paricutin"), "Parícutin")
	assert_eq(WonderFacts.called(&"grand_canyon"), "the Grand Canyon")
	assert_eq(WonderFacts.called(&"northern_lights"), "the Northern Lights")
	assert_eq(WonderFacts.status_words(&"everest"), "A wonder of nature")
	assert_string_contains(WonderFacts.status_words(&"paricutin"), "Quiet since 1952", "its glowing crater is explained")
	assert_eq(WonderFacts.when_words(&"paricutin"), "born in 1943")
	assert_eq(WonderFacts.when_words(&"pyramid"), "built about 4,500 years ago", "the built ones keep their words")


func test_the_passport_counts_three_tours_and_points_to_the_next() -> void:
	var w := WonderData.new()
	for id in NATURE.slice(0, 6):
		w.stamp(id)
	assert_eq(WondersPassportRules.count_words(w), "6 of 21 stamps")
	assert_eq(WondersPassportRules.tour_stamped(w, &"nature"), 6)
	w.stamp(NATURE[6])
	assert_eq(WondersPassportRules.stamp_words(w, NATURE[6]),
		"Stamp! You have all 7 stamps of the Seven Natural Wonders of the World! 7 of 21 wonders in your Wonders Passport.")
	var list: Array[Dictionary] = []
	for id in WonderFacts.ORDER:
		list.append({"id": id, "name": WonderFacts.display_name(id), "pos": WonderTour.centre(id),
			"found": WonderFacts.tour_of(id) == &"nature"})
	assert_eq(WondersPassportRules.tour_progress_words(list, Vector3.ZERO, &"nature"),
		"You visited all 7 of the Seven Natural Wonders of the World! The Seven Ancient Wonders wait along the Nature "
		+ "Trail. Follow the arrow.")
	for e in list:
		e.found = WonderFacts.tour_of(e.id) != &"new"
	assert_eq(WondersPassportRules.tour_progress_words(list, Vector3.ZERO, &"ancient"),
		"You visited all 7 of the Seven Wonders of the Ancient World! The New Seven Wonders wait along the Wonders Road. "
		+ "Follow the arrow.")
	for e in list:
		e.found = WonderFacts.tour_of(e.id) == &"new" or WonderFacts.tour_of(e.id) == &"ancient"
	assert_eq(WondersPassportRules.tour_progress_words(list, Vector3.ZERO, &"new"),
		"You visited all 7 of the New Seven Wonders! The Seven Natural Wonders wait along the Nature Trail. Follow the arrow.")
	assert_string_contains(WondersPassportRules.clue(&"everest"), "Nature Trail")
	assert_string_contains(WondersPassportRules.clue(&"petra"), "Wonders Road")
	assert_false(WondersPassportRules.clue(&"pyramid").contains("Road"), "the first tour is round the landing square")
	var back := WonderData.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	assert_true(back.stamped(&"victoria_falls"), "the new stamps are saved")
	back.answer("everest_1", true)
	assert_true(WonderData.from_dict(back.to_dict()).quiz_right("everest_1"), "and their quizzes")
	var other := WonderData.new()
	other.stamp(&"grand_canyon")
	other.merge_from(back)
	assert_true(other.stamped(&"grand_canyon") and other.stamped(&"paricutin"), "the backup merges them without loss")
