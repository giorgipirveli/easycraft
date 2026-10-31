extends GutTest


func test_idle_player_floats_up_slowly_in_water() -> void:
	var v := -3.0
	for i in 120:
		v = WaterRules.vertical_velocity(v, false, 1.0 / 60.0)
	assert_gt(v, 0.0, "drifts up")
	assert_lt(v, WaterRules.SWIM_UP_SPEED, "but slower than swimming")


func test_holding_jump_swims_up() -> void:
	assert_eq(WaterRules.vertical_velocity(-2.0, true, 0.016), WaterRules.SWIM_UP_SPEED)


func test_malformed_batch_entries_are_dropped() -> void:
	var clean := EditBatch.sanitize([[Vector3i(1, 2, 3), BlockIds.RED], "junk", [Vector3i(0, 0, 0)], [1, 2], [Vector3i(4, 5, 6), 999], [Vector3i(7, 8, 9), BlockIds.AIR]], 100)
	assert_eq(clean, [[Vector3i(1, 2, 3), BlockIds.RED], [Vector3i(7, 8, 9), BlockIds.AIR]])


func test_batch_is_capped() -> void:
	var many := []
	for i in 50:
		many.append([Vector3i(i, 0, 0), BlockIds.RED])
	assert_eq(EditBatch.sanitize(many, 10).size(), 10)


func test_biggest_mirrored_stamp_fits_the_batch_limit() -> void:
	for stamp in ItemIds.STAMPS:
		assert_lte(Blueprints.local(stamp).size() * 2, EditBatch.MAX_BATCH, ItemIds.display_name(stamp))
