extends GutTest

const AREA := 128


func test_deterministic_for_same_seed() -> void:
	var a := MeadowsShape.new(42)
	var b := MeadowsShape.new(42)
	for i in 50:
		var x := i * 37 - 900
		var z := i * 53 + 400
		assert_eq(a.height_at(x, z), b.height_at(x, z))
		assert_eq(a.tree_at(x, z), b.tree_at(x, z))


func test_heights_stay_in_range() -> void:
	var s := MeadowsShape.new(7)
	for x in range(0, AREA, 4):
		for z in range(0, AREA, 4):
			var h := s.height_at(x * 13, z * 13)
			assert_between(h, MeadowsShape.MIN_HEIGHT, MeadowsShape.MAX_HEIGHT)


func test_different_seeds_differ() -> void:
	var a := MeadowsShape.new(1)
	var b := MeadowsShape.new(2)
	var differs := false
	for x in range(0, 64, 4):
		for z in range(0, 64, 4):
			if a.height_at(x, z) != b.height_at(x, z):
				differs = true
	assert_true(differs)


func test_trees_never_grow_in_water_or_on_beaches() -> void:
	var s := MeadowsShape.new(12345)
	for x in AREA:
		for z in AREA:
			if s.tree_at(x, z):
				assert_gt(s.height_at(x, z), MeadowsShape.SEA_LEVEL + 1, "tree at %d,%d" % [x, z])


func test_some_trees_exist() -> void:
	var s := MeadowsShape.new(12345)
	var count := 0
	for x in AREA:
		for z in AREA:
			if s.tree_at(x, z):
				count += 1
	assert_gt(count, 0)


func test_tree_height_in_range() -> void:
	var s := MeadowsShape.new(3)
	for i in 100:
		assert_between(s.tree_height(i, i * 7), 4, 6)


func test_column_layers_on_land() -> void:
	var s := MeadowsShape.new(1)
	var h := MeadowsShape.SEA_LEVEL + 10
	assert_eq(s.column_block(h, h), BlockIds.AIR, "above ground is air")
	assert_eq(s.column_block(h - 1, h), BlockIds.GRASS, "top is grass")
	assert_eq(s.column_block(h - 3, h), BlockIds.DIRT)
	assert_eq(s.column_block(h - 10, h), BlockIds.STONE)


func test_column_layers_under_water() -> void:
	var s := MeadowsShape.new(1)
	var h := MeadowsShape.SEA_LEVEL - 5
	assert_eq(s.column_block(MeadowsShape.SEA_LEVEL - 1, h), BlockIds.WATER, "water up to sea level")
	assert_eq(s.column_block(MeadowsShape.SEA_LEVEL, h), BlockIds.AIR)
	assert_eq(s.column_block(h - 1, h), BlockIds.SAND, "lake floor is sand")


# --- World v2: oceans and rivers ---

func _share_below_sea(s: MeadowsShape) -> float:
	var below := 0
	var n := 0
	for x in range(-4096, 4096, 64):
		for z in range(-4096, 4096, 64):
			n += 1
			if s.height_at(x, z) < MeadowsShape.SEA_LEVEL:
				below += 1
	return float(below) / n


func test_oceans_and_land_are_both_common() -> void:
	for seed in [1, 42, 12345]:
		var share := _share_below_sea(MeadowsShape.new(seed))
		assert_between(share, 0.2, 0.6, "seed %d: share under water = %.2f" % [seed, share])


func test_oceans_get_deep() -> void:
	var s := MeadowsShape.new(42)
	var lowest := MeadowsShape.MAX_HEIGHT
	for x in range(-4096, 4096, 32):
		for z in range(-4096, 4096, 128):
			lowest = mini(lowest, s.height_at(x, z))
	assert_lt(lowest, MeadowsShape.SEA_LEVEL - 10, "deep water to dive into")


func _river_columns(s: MeadowsShape) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for x in range(-2048, 2048, 8):
		for z in range(-2048, 2048, 8):
			if s.is_river(x, z):
				found.append(Vector2i(x, z))
	return found


func test_rivers_exist_and_are_filled_with_water() -> void:
	var s := MeadowsShape.new(12345)
	var rivers := _river_columns(s)
	assert_gt(rivers.size(), 100, "rivers wind across the land")
	for c in rivers:
		var h := s.height_at(c.x, c.y)
		assert_lt(h, MeadowsShape.SEA_LEVEL, "river bed below the water line at %s" % c)
		assert_eq(s.column_block(MeadowsShape.SEA_LEVEL - 1, h), BlockIds.WATER)


func _run(s: MeadowsShape, c: Vector2i, step: Vector2i) -> int:
	var n := 1
	for dir in [step, -step]:
		var p: Vector2i = c + dir
		while s.is_river(p.x, p.y) and n < 200:
			n += 1
			p += dir
	return n


func test_river_channels_are_a_few_blocks_wide() -> void:
	var s := MeadowsShape.new(12345)
	var widths: Array[int] = []
	for c in _river_columns(s):
		widths.append(mini(_run(s, c, Vector2i(1, 0)), _run(s, c, Vector2i(0, 1))))
	widths.sort()
	var median := widths[widths.size() / 2]
	assert_between(median, 4, 30, "median river width %d" % median)


func test_spawn_column_is_on_dry_land_near_the_origin() -> void:
	for seed in range(1, 31):
		var s := MeadowsShape.new(seed)
		var c := s.spawn_column()
		assert_gt(s.height_at(c.x, c.y), MeadowsShape.SEA_LEVEL + 1, "seed %d spawn %s is dry land" % [seed, c])
		assert_false(s.is_river(c.x, c.y))
		assert_lt(c.length(), 3000.0, "seed %d spawn near the origin" % seed)


# --- World v2: underground layers ---

func test_stone_above_zero_deepstone_below() -> void:
	var s := MeadowsShape.new(1)
	assert_eq(s.column_block(10, 40), BlockIds.STONE)
	assert_eq(s.column_block(0, 40), BlockIds.STONE)
	assert_eq(s.column_block(-1, 40), BlockIds.DEEPSTONE)
	assert_eq(s.column_block(-50, 40), BlockIds.DEEPSTONE)


func test_bedrock_floor_is_noisy_between_minus_64_and_minus_61() -> void:
	var s := MeadowsShape.new(5)
	var tops := {}
	for x in 40:
		for z in 40:
			var top := s.bedrock_top(x, z)
			assert_between(top, MeadowsShape.WORLD_BOTTOM, MeadowsShape.WORLD_BOTTOM + 3)
			tops[top] = true
			assert_eq(s.column_block(top, 40, top), BlockIds.BEDROCK)
			assert_eq(s.column_block(MeadowsShape.WORLD_BOTTOM, 40, top), BlockIds.BEDROCK, "the very bottom is always bedrock")
			assert_eq(s.column_block(top + 1, 40, top), BlockIds.DEEPSTONE)
	assert_eq(tops.size(), 4, "all four floor heights occur")
