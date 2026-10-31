extends GutTest


func test_spawn_height_is_just_above_feet_block() -> void:
	var y := SpawnRules.spawn_y(41)
	assert_gt(y, 41.0)
	assert_lt(y, 41.5)


func test_fall_limit() -> void:
	assert_true(SpawnRules.has_fallen(-65.0))
	assert_false(SpawnRules.has_fallen(-10.0))


func test_first_free_y_skips_solid_blocks() -> void:
	var solid := func(y: int) -> bool: return y >= 10 and y <= 12
	assert_eq(SpawnRules.first_free_y(10, solid, 100), 13)


func test_first_free_y_needs_two_free_blocks() -> void:
	var solid := func(y: int) -> bool: return y == 10 or y == 12
	assert_eq(SpawnRules.first_free_y(10, solid, 100), 13, "a 1-block gap at 11 is too small")


func test_first_free_y_when_already_free() -> void:
	var solid := func(_y: int) -> bool: return false
	assert_eq(SpawnRules.first_free_y(7, solid, 100), 7)


func test_first_free_y_stops_at_max() -> void:
	var solid := func(_y: int) -> bool: return true
	assert_eq(SpawnRules.first_free_y(0, solid, 50), 50)


func test_readiness_probe_uses_the_ground_below_a_mid_air_save() -> void:
	assert_eq(SpawnRules.readiness_probe_y(80.0, 30), 31.0, "flying save: wait for the ground, not the air")


func test_readiness_probe_keeps_underground_saves() -> void:
	assert_eq(SpawnRules.readiness_probe_y(12.0, 30), 12.0, "cave save: wait for the cave itself")
