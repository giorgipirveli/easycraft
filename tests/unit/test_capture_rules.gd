extends GutTest

var world := {}


func _block_at(p: Vector3i) -> int:
	return world.get(p, BlockIds.AIR)


func before_each() -> void:
	world.clear()
	for x in range(-5, 6):                       # grass floor
		for z in range(-5, 6):
			world[Vector3i(x, 0, z)] = BlockIds.GRASS


func test_captures_a_connected_build_but_not_the_ground() -> void:
	world[Vector3i(0, 1, 0)] = BlockIds.RED
	world[Vector3i(0, 2, 0)] = BlockIds.RED
	world[Vector3i(1, 2, 0)] = BlockIds.YELLOW
	var r := CaptureRules.capture(Vector3i(0, 2, 0), _block_at)
	assert_false(r.has("error"))
	assert_eq((r.blocks as Dictionary).size(), 3)
	assert_false((r.blocks as Dictionary).has(Vector3i(0, 0, 0)))


func test_separate_builds_stay_separate() -> void:
	world[Vector3i(0, 1, 0)] = BlockIds.RED
	world[Vector3i(3, 1, 0)] = BlockIds.BLUE
	var r := CaptureRules.capture(Vector3i(0, 1, 0), _block_at)
	assert_eq((r.blocks as Dictionary).size(), 1)


func test_tapping_terrain_is_not_a_build() -> void:
	assert_eq(CaptureRules.capture(Vector3i(0, 0, 0), _block_at).error, "not_a_build")
	assert_eq(CaptureRules.capture(Vector3i(0, 5, 0), _block_at).error, "not_a_build")


func test_trees_can_come_alive() -> void:
	world[Vector3i(2, 1, 2)] = BlockIds.LOG
	world[Vector3i(2, 2, 2)] = BlockIds.LOG
	world[Vector3i(2, 3, 2)] = BlockIds.LEAVES
	assert_eq((CaptureRules.capture(Vector3i(2, 1, 2), _block_at).blocks as Dictionary).size(), 3)


func test_too_big_is_refused() -> void:
	for x in 15:
		for y in 15:
			world[Vector3i(x - 7, y + 1, 3)] = BlockIds.PLANKS   # 225 blocks, within radius
	assert_eq(CaptureRules.capture(Vector3i(0, 5, 3), _block_at).error, "too_big")


func test_radius_limits_long_builds() -> void:
	for z in 30:
		world[Vector3i(0, 1, z)] = BlockIds.BRICK
	var r := CaptureRules.capture(Vector3i(0, 1, 0), _block_at)
	assert_eq(r.error, "too_big", "a build reaching past the radius is too big to lift")


func test_every_error_has_a_message() -> void:
	for code in ["not_a_build", "too_big"]:
		assert_ne(CaptureRules.message(code), "")


func test_underground_ground_never_comes_alive_but_crystal_can() -> void:
	for id in [BlockIds.DEEPSTONE, BlockIds.BEDROCK, BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
		assert_false(CaptureRules.is_capturable(id), BlockIds.display_name(id))
	assert_true(CaptureRules.is_capturable(BlockIds.CRYSTAL))
