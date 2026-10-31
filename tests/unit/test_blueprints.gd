extends GutTest


func test_every_stamp_has_valid_blocks_in_bounds() -> void:
	for stamp in ItemIds.STAMPS:
		var blocks := Blueprints.local(stamp)
		assert_gt(blocks.size(), 20, ItemIds.display_name(stamp))
		for pos: Vector3i in blocks:
			var id: int = blocks[pos]
			assert_true(id == BlockIds.AIR or BlockIds.is_valid(id), "%s id %d" % [ItemIds.display_name(stamp), id])
			assert_between(pos.x, -9, 9)
			assert_between(pos.y, -1, 14)
			assert_between(pos.z, -1, 17)   # roofs and canopies may overhang one block


func test_house_has_a_door_windows_and_a_light() -> void:
	var house := Blueprints.local(ItemIds.STAMP_HOUSE)
	assert_eq(house[Vector3i(0, 0, 0)], BlockIds.AIR, "door bottom")
	assert_eq(house[Vector3i(0, 1, 0)], BlockIds.AIR, "door top")
	assert_true(house.values().has(BlockIds.GLASS))
	assert_true(house.values().has(BlockIds.LIGHT))


func test_facing_for_yaw() -> void:
	assert_eq(Blueprints.facing_for_yaw(0.0), Vector3i(0, 0, -1))
	assert_eq(Blueprints.facing_for_yaw(PI / 2.0), Vector3i(-1, 0, 0))
	assert_eq(Blueprints.facing_for_yaw(PI), Vector3i(0, 0, 1))


func test_rotation_maps_local_axes() -> void:
	var fwd := Vector3i(0, 0, -1)
	assert_eq(Blueprints.to_world(Vector3i(0, 0, 1), Vector3i.ZERO, fwd), Vector3i(0, 0, -1), "local forward")
	assert_eq(Blueprints.to_world(Vector3i(1, 0, 0), Vector3i.ZERO, fwd), Vector3i(1, 0, 0), "local right")
	assert_eq(Blueprints.to_world(Vector3i(1, 2, 0), Vector3i(10, 20, 30), Vector3i(1, 0, 0)), Vector3i(10, 22, 31))


func test_placement_keeps_block_count_in_every_direction() -> void:
	var n := Blueprints.local(ItemIds.STAMP_TOWER).size()
	for fwd in [Vector3i(0, 0, -1), Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(-1, 0, 0)]:
		var changes := Blueprints.place(ItemIds.STAMP_TOWER, Vector3i(5, 30, 5), fwd)
		assert_eq(changes.size(), n)
		var seen := {}
		for c: Array in changes:
			seen[c[0]] = true
		assert_eq(seen.size(), n, "no two blocks land on the same spot")
