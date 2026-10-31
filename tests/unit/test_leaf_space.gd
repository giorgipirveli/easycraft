extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.11, §4.3): the leaf's inside at the child's size (rung 5, about
## x85,000: 16 x 16 m across, the leaf pressed to 10 m tall). One pure layout: where every door, cell, column, pipe and
## sugar spot is, from the setting and a seed. The place draws from it, and the flyer is pushed out of the same shapes (no
## physics bodies), so what a child sees is what stops them; the doors have room above them to hover and squeeze, the
## sugar waits where nothing hides it, and the cactus's stem has big store cells and jars.


func _min_gap(points: Array) -> float:
	var best := INF
	for i in points.size():
		for j in range(i + 1, points.size()):
			best = minf(best, (points[i] as Vector3).distance_to(points[j]))
	return best


func test_the_sunflower_s_leaf_has_six_doors_in_its_floor_with_room_between() -> void:
	var s := LeafSpace.make("sunflower")
	assert_eq(s.doors.size(), 6)
	var at: Array = []
	for d: Dictionary in s.doors:
		var p: Vector3 = d.at
		assert_almost_eq(p.y, 0.0, 0.001, "in the floor")
		assert_lte(absf(p.x), LeafSpace.HALF - 1.5, "inside the leaf")
		assert_lte(absf(p.z), LeafSpace.HALF - 1.5)
		at.append(p)
	assert_gte(_min_gap(at), 3.0, "a child fits between two doors")
	assert_between(s.entry_door, 0, 5)
	assert_true(s.free_at(s.start, 0.4), "the child arrives in the open")
	assert_lt(Vector2(s.start.x, s.start.z).distance_to(Vector2(at[s.entry_door].x, at[s.entry_door].z)), 0.5,
		"above the door they came in by")


func test_every_door_has_room_above_it_to_hover_and_squeeze() -> void:
	for setting: String in ["sunflower", "cactus"]:
		var s := LeafSpace.make(setting)
		for d: Dictionary in s.doors:
			for h: float in [0.6, 1.2, 1.8]:
				assert_true(s.free_at((d.at as Vector3) + Vector3(0, h, 0), 0.5), "%s: above a door at %.1f m" % [setting, h])


func test_the_sugar_waits_where_nothing_hides_it_and_the_pipes_mouths_are_open() -> void:
	var s := LeafSpace.make("sunflower")
	assert_gte(s.sugar_spots.size(), 6)
	for p: Vector3 in s.sugar_spots:
		assert_true(s.free_at(p, 0.35), "a sugar spot at %s is in the open" % p)
		assert_between(p.y, 1.5, LeafSpace.COLUMNS_FROM, "between the floor and the columns")
	for mouth: Vector3 in [s.vein.gold_mouth, s.vein.blue_mouth]:
		assert_true(s.free_at(mouth, 0.3), "a pipe's mouth at %s" % mouth)
	assert_gt((s.vein.gold_mouth as Vector3).distance_to(s.vein.blue_mouth), 0.8, "two pipes, apart")


func test_the_flyer_is_pushed_out_of_cells_columns_floor_roof_and_walls() -> void:
	var s := LeafSpace.make("sunflower")
	var cell: Dictionary = s.cells[0]
	var inside: Vector3 = (cell.at as Vector3) + Vector3(0.1, 0.05, 0)
	var out := s.push_out(inside, 0.3)
	assert_gte(out.distance_to(cell.at), float(cell.radius) + 0.3 - 0.001, "out of a cell")
	assert_true(s.free_at(out, 0.29))
	assert_almost_eq(s.push_out(Vector3(0, -2, 0), 0.3).y, 0.3, 0.001, "never through the floor")
	assert_almost_eq(s.push_out(Vector3(20, 2, 0), 0.3).x, LeafSpace.HALF - 0.3, 0.001, "nor through the walls")
	assert_lte(s.push_out(Vector3(0, 30, 0), 0.3).y, LeafSpace.ROOF - 0.3 + 0.001, "nor the roof")
	var open_air := s.start
	assert_eq(s.push_out(open_air, 0.3), open_air, "the open air is left alone")
	var column: Dictionary = s.columns[0]
	var in_column: Vector3 = (column.at as Vector3) + Vector3(0, 1.0, 0)
	assert_true(s.free_at(s.push_out(in_column, 0.3), 0.29), "out of a column")


func test_a_line_of_sight_is_blocked_only_by_something_solid() -> void:
	var s := LeafSpace.make("sunflower")
	var cell: Dictionary = s.cells[0]
	var c: Vector3 = cell.at
	var r := float(cell.radius)
	assert_false(s.clear_line(c + Vector3(-r - 1.0, 0, 0), c + Vector3(r + 1.0, 0, 0)), "through a cell")
	assert_true(s.clear_line(s.start, s.start + Vector3(0, 0.5, 0)), "a short hop in the open")


func test_the_cactus_stem_has_wide_apart_doors_big_store_cells_and_eight_jars() -> void:
	var s := LeafSpace.make("cactus")
	assert_eq(s.doors.size(), 6, "the model's six doors")
	var at: Array = s.doors.map(func(d: Dictionary) -> Vector3: return d.at)
	assert_gte(_min_gap(at), 4.0, "fewer doors in the same floor: farther apart")
	var stores := s.cells.filter(func(c: Dictionary) -> bool: return str(c.kind) == "store")
	assert_gte(stores.size(), 4, "the big pale water-store cells")
	for c: Dictionary in stores:
		assert_gte(float(c.radius), 2.0)
	assert_eq(s.jars.size(), 8, "a jar for each sugar's worth of kept air")
	for j: Vector3 in s.jars:
		var held := stores.any(func(c: Dictionary) -> bool: return j.distance_to(c.at) <= float(c.radius) - 0.4)
		assert_true(held, "the jar at %s is in a store cell's water (its vacuole), seen through its glassy skin" % j)
	assert_true(s.clear_line(s.start, s.jars[0], true), "store cells are see-through")
	assert_true(LeafSpace.make("sunflower").jars.is_empty(), "jars are the cactus's")


func test_the_same_setting_and_seed_make_the_same_leaf() -> void:
	var a := LeafSpace.make("sunflower", 3)
	var b := LeafSpace.make("sunflower", 3)
	assert_eq(JSON.stringify(a.cells), JSON.stringify(b.cells))
	assert_eq(JSON.stringify(a.columns), JSON.stringify(b.columns))
	assert_ne(JSON.stringify(a.cells), JSON.stringify(LeafSpace.make("sunflower", 4).cells), "another seed, other cells")


func test_any_seed_keeps_the_doors_the_sugar_the_mouths_and_the_way_in_open() -> void:
	for setting: String in ["sunflower", "cactus"]:
		for seed in 40:
			var s := LeafSpace.make(setting, seed)
			var ok := s.free_at(s.start, 0.4)
			for d: Dictionary in s.doors:
				for h: float in [0.6, 1.2, 1.8]:
					ok = ok and s.free_at((d.at as Vector3) + Vector3(0, h, 0), 0.5)
			for p: Vector3 in s.sugar_spots:
				ok = ok and s.free_at(p, 0.35)
			for m: Vector3 in [s.vein.gold_mouth, s.vein.blue_mouth]:
				ok = ok and s.free_at(m, 0.3)
			assert_true(ok, "%s, seed %d" % [setting, seed])
			assert_gte(s.cells.size(), 12, "%s, seed %d: a full leaf of cells" % [setting, seed])
