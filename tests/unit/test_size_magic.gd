extends GutTest


func test_scales() -> void:
	assert_eq(SizeMagic.scale(SizeMagic.Mode.NORMAL), 1.0)
	assert_eq(SizeMagic.scale(SizeMagic.Mode.TINY), 0.25)
	assert_eq(SizeMagic.scale(SizeMagic.Mode.GIANT), 3.0)


func test_cycle() -> void:
	assert_eq(SizeMagic.next(SizeMagic.Mode.NORMAL), SizeMagic.Mode.TINY)
	assert_eq(SizeMagic.next(SizeMagic.Mode.TINY), SizeMagic.Mode.GIANT)
	assert_eq(SizeMagic.next(SizeMagic.Mode.GIANT), SizeMagic.Mode.NORMAL)


func test_clearance_in_blocks() -> void:
	assert_eq(SizeMagic.clearance_blocks(SizeMagic.Mode.NORMAL), 2)
	assert_eq(SizeMagic.clearance_blocks(SizeMagic.Mode.TINY), 1)
	assert_eq(SizeMagic.clearance_blocks(SizeMagic.Mode.GIANT), 6)


func test_speed_and_jump_grow_with_size() -> void:
	var t := SizeMagic.Mode.TINY
	var n := SizeMagic.Mode.NORMAL
	var g := SizeMagic.Mode.GIANT
	assert_lt(SizeMagic.walk_speed_factor(t), SizeMagic.walk_speed_factor(n))
	assert_lt(SizeMagic.walk_speed_factor(n), SizeMagic.walk_speed_factor(g))
	assert_lt(SizeMagic.jump_factor(t), SizeMagic.jump_factor(n))
	assert_lt(SizeMagic.jump_factor(n), SizeMagic.jump_factor(g))
	assert_eq(SizeMagic.walk_speed_factor(n), 1.0)
	assert_eq(SizeMagic.jump_factor(n), 1.0)


func test_every_mode_has_a_label() -> void:
	for m in [SizeMagic.Mode.NORMAL, SizeMagic.Mode.TINY, SizeMagic.Mode.GIANT]:
		assert_ne(SizeMagic.label(m), "")


func test_tiny_player_fits_a_one_block_gap() -> void:
	var solid := func(y: int) -> bool: return y == 10 or y == 12   # 1-block gap at y = 11
	assert_eq(SpawnRules.first_free_y(10, solid, 100, SizeMagic.clearance_blocks(SizeMagic.Mode.TINY)), 11)
	assert_eq(SpawnRules.first_free_y(10, solid, 100, SizeMagic.clearance_blocks(SizeMagic.Mode.NORMAL)), 13)


func test_giant_needs_six_free_blocks() -> void:
	var solid := func(y: int) -> bool: return y == 15
	assert_eq(SpawnRules.first_free_y(10, solid, 100, 6), 16)


func test_tiny_body_lets_you_build_at_normal_head_height() -> void:
	var tiny: Array[AABB] = [PlacementRules.player_aabb(Vector3(5.5, 10.0, 5.5), 0.25)]
	assert_true(PlacementRules.can_place(Vector3i(5, 11, 5), tiny, BlockIds.STONE))
	assert_false(PlacementRules.can_place(Vector3i(5, 10, 5), tiny, BlockIds.STONE))


func test_giant_body_blocks_a_wide_area() -> void:
	var giant: Array[AABB] = [PlacementRules.player_aabb(Vector3(5.5, 10.0, 5.5), 3.0)]
	assert_false(PlacementRules.can_place(Vector3i(6, 14, 5), giant, BlockIds.STONE))
