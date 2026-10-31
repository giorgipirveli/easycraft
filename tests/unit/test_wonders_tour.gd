extends GutTest
## Owner #78 (spec §24): where the Seven Wonders of the Ancient World stand in world 41 (WonderTour) and the ground
## under them (WondersShape): the same in every world, round the landing spot, each on the flat park at the tour's
## ground level, none on another or on a path, each facing the way its path comes (or where the real one faced), the
## sea with its beach to the north-east, the Lighthouse's island and causeway, Giza's sand, and Green Meadows' own land
## far out.

var shape: WondersShape


func before_all() -> void:
	shape = WondersShape.new(4242)


func test_the_tour_is_the_seven_ancient_wonders_in_the_old_lists_order() -> void:
	var ancient: Array[StringName] = [&"pyramid", &"gardens", &"artemis", &"zeus", &"mausoleum", &"colossus", &"lighthouse"]
	assert_eq(WonderFacts.tour_ids(&"ancient"), ancient)
	assert_eq(WonderTour.ids().slice(0, 7), ancient, "the first tour first (the New Seven, then nature's after it)")
	assert_eq(WonderTour.ids().size(), 21)
	for id in WonderTour.ids():
		assert_true(WonderFacts.has(id), str(id))
		assert_true(WonderTour.has(id), str(id))


func test_each_wonder_stands_on_level_ground_within_the_flat_park() -> void:
	for id in WonderFacts.tour_ids(&"ancient"):
		var f := WonderTour.footprint(id)
		var far := maxf(Vector2(f.position).length(), Vector2(f.end).length())
		assert_lt(far, WonderTour.FLAT_R - 10.0, "%s is in the flat park (%.0f)" % [id, far])
		if id == &"lighthouse":
			continue
		for x in range(f.position.x, f.end.x, 3):
			for z in range(f.position.y, f.end.y, 3):
				assert_eq(shape.height_at(x, z), WonderTour.BASE_Y, "%s's ground at %d, %d" % [id, x, z])


func test_no_wonder_stands_on_another_or_on_the_landing_square() -> void:
	var ids := WonderTour.ids()
	for i in ids.size():
		var a := WonderTour.footprint(ids[i]).grow(4)
		assert_false(a.has_point(Vector2i.ZERO), "%s keeps off the landing spot" % ids[i])
		for j in range(i + 1, ids.size()):
			assert_false(a.intersects(WonderTour.footprint(ids[j]).grow(4)), "%s and %s" % [ids[i], ids[j]])
		assert_false(a.intersects(WonderTour.WORKSHOP), "%s and the workshop" % ids[i])


func test_every_path_runs_from_the_landing_square_to_its_gate_and_crosses_no_other_wonder() -> void:
	for id in WonderTour.ids():
		var ends := WonderTour.path(id)
		assert_lt(Vector2(ends[0] - WonderTour.square_of(id)).length(), WonderTour.PLAZA_R + 0.5,
			"%s's path starts on its tour's square" % id)
		for other in WonderTour.ids():
			var f := WonderTour.footprint(other)
			for t in 41:
				var p := Vector2i((Vector2(ends[0]).lerp(Vector2(ends[1]), t / 40.0)).round())
				assert_false(f.has_point(p), "%s's path crosses %s at %s" % [id, other, p])
		var gate := WonderTour.gate(id)
		assert_eq(shape.height_at(gate.x, gate.y), WonderTour.BASE_Y, "%s's gate on flat ground" % id)
		var plaque := WonderTour.plaque(id)
		assert_eq(WonderTour.plaque_at(plaque), id)
		assert_eq(plaque.y, WonderTour.BASE_Y, "the plaque stands on the ground")
	assert_eq(WonderTour.plaque_at(WonderTour.tour_plaque()), &"tour", "the landing square's own plaque")
	assert_eq(WonderTour.plaque_at(Vector3i(1, 2, 3)), &"")


func test_signposts_stand_on_the_landing_square() -> void:
	var seen := {}
	for id in WonderTour.ids():
		var s := WonderTour.signpost(id)
		assert_lte(Vector2(s - WonderTour.square_of(id)).length(), float(WonderTour.PLAZA_R), "%s's signpost on the square" % id)
		assert_false(seen.has(s), "one signpost per wonder")
		seen[s] = true


func test_the_fronts_face_where_they_should() -> void:
	assert_eq(WonderTour.WONDERS[&"pyramid"].face, WonderTour.N, "the pyramid's entrance is on its north face")
	assert_eq(WonderTour.WONDERS[&"artemis"].face, WonderTour.W, "the Temple of Artemis faced west")
	assert_eq(WonderTour.WONDERS[&"zeus"].face, WonderTour.E, "the Temple of Zeus faced east")
	assert_eq(WonderTour.turn(Vector2i(0, -1), WonderTour.E), Vector2i(1, 0))
	assert_eq(WonderTour.turn(Vector2i(0, -1), WonderTour.W), Vector2i(-1, 0))
	assert_eq(WonderTour.turn(Vector2i(0, -1), WonderTour.S), Vector2i(0, 1))
	assert_eq(WonderTour.turn(Vector2i(1, 0), WonderTour.E), Vector2i(0, 1), "facing east, the right hand is south")


func test_the_sea_the_beach_the_island_and_the_causeway() -> void:
	assert_lt(shape.height_at(170, -100), MeadowsShape.SEA_LEVEL, "the sea to the north-east")
	assert_eq(shape.height_at(170, -100), WonderTour.SEA_FLOOR)
	var beach := Vector2i(110, -30)
	assert_between(WonderTour.coast_distance(beach.x, beach.y), -WonderTour.BEACH_IN, 8.0)
	assert_true(shape.sandy(beach.x, beach.y), "a sandy beach")
	assert_eq(shape.height_at(WonderTour.ISLAND.x, WonderTour.ISLAND.y), WonderTour.BASE_Y, "the island's top is level")
	for x in range(WonderTour.CAUSEWAY.position.x, WonderTour.CAUSEWAY.end.x):
		assert_eq(shape.height_at(x, -40), WonderTour.BASE_Y, "the causeway at %d" % x)
	assert_lt(shape.height_at(120, -46), MeadowsShape.SEA_LEVEL, "water beside the causeway")
	var col := WonderTour.footprint(&"colossus")
	assert_lt(WonderTour.coast_distance(col.position.x, col.end.y), -WonderTour.BEACH_IN, "the Colossus by the shore")


func test_giza_is_sand_and_the_park_is_grass_with_trees_off_the_wonders_and_paths() -> void:
	var p := WonderTour.to_world(&"pyramid", Vector2i(0, -28))
	assert_true(shape.sandy(p.x, p.y), "sand in front of the pyramid")
	assert_false(shape.sandy(-60, 0), "grass in the park")
	for id in WonderTour.ids():
		if WonderFacts.tour_of(id) == &"nature":
			continue   # nature's own trees grow round its wonders, never on its builds (test_wonders_nature_ground)
		var f := WonderTour.footprint(id).grow(WondersShape.CLEAR_MARGIN)
		for x in range(f.position.x, f.end.x):
			for z in range(f.position.y, f.end.y):
				assert_false(shape.tree_at(x, z), "no tree at %s by %s" % [Vector2i(x, z), id])
	var trees := 0
	for x in range(-180, 180, 2):
		for z in range(-180, 180, 2):
			if shape.tree_at(x, z):
				trees += 1
	assert_gt(trees, 50, "a park with trees (%d)" % trees)
	assert_eq(shape.tree_kind(-150, 0), &"olive", "olive trees to the west (Greece)")
	assert_eq(shape.tree_kind(0, 110), &"palm", "palms on Giza's sand")


func test_spawners_keep_off_the_wonders_and_the_landing_spot_is_the_square() -> void:
	assert_eq(shape.spawn_column(), Vector2i.ZERO)
	for id in WonderTour.ids():
		var c: Vector2i = WonderTour.WONDERS[id].centre
		assert_true(shape.is_river(c.x, c.y), "%s: dry land for spawners keeps off it" % id)
		assert_true(shape.is_built(c.x, c.y))
	assert_false(shape.is_river(0, 0), "the landing square is land")
	assert_false(shape.is_river(-60, 20), "the park is land")


func test_far_out_it_is_green_meadows_own_land() -> void:
	var meadows := MeadowsShape.new(4242)
	for p: Vector2i in [Vector2i(400, 0), Vector2i(-300, 300), Vector2i(0, -900)]:
		assert_eq(shape.height_at(p.x, p.y), meadows.height_at(p.x, p.y), str(p))
		assert_eq(shape.is_river(p.x, p.y), meadows.is_river(p.x, p.y), str(p))
