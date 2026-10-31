extends GutTest
## "My showcase" (M4 Wave 3, agent I): the build area around where the child stands (32 wide, from the
## ground under the feet up), as one build text the server keeps (at most 32 x 32 x 32 and 48 KiB), with
## the child's nearest buddy waving in it when one stands inside.


func _flat_world(extra: Dictionary) -> Callable:
	return func(p: Vector3i) -> int:
		if extra.has(p):
			return extra[p]
		return BlockIds.GRASS if p.y == 9 else (BlockIds.DIRT if p.y < 9 else BlockIds.AIR)


func test_the_area_is_32_wide_around_the_feet_from_a_little_below_up() -> void:
	var box := ShowcaseArea.box_around(Vector3(100.4, 10.0, -20.7))
	assert_eq(box.size, Vector3i(32, 32, 32))
	assert_eq(box.origin, Vector3i(100 - 16, 10 - ShowcaseArea.BELOW, -21 - 16), "8 layers under the feet: a build downhill comes too")
	assert_eq(box.origin.y + ShowcaseArea.GROUND_LAYER, 9, "its ground layer is the one the child stood on")
	var high := ShowcaseArea.box_around(Vector3(0, WorldService.MAX_Y - 3, 0))
	assert_lte(high.origin.y + high.size.y, WorldService.MAX_Y, "never above the world")
	var low := ShowcaseArea.box_around(Vector3(0, WorldService.MIN_Y, 0))
	assert_gte(low.origin.y, WorldService.MIN_Y)


func test_a_snapshot_keeps_the_area_and_turns_items_into_air() -> void:
	var house := {Vector3i(5, 10, 5): BlockIds.PLANKS, Vector3i(5, 11, 5): BlockIds.GLASS, Vector3i(6, 10, 5): ItemIds.SWORD}
	var box := ShowcaseArea.box_around(Vector3(5.5, 10, 5.5))
	var text := ShowcaseArea.snapshot(box.origin, box.size, _flat_world(house))
	assert_eq(BuildCodec.size_of(text), Vector3i(32, 32, 32))
	var back := BuildCodec.decode(text, BuildCodec.SHOWCASE)
	var local: Vector3i = Vector3i(5, 10, 5) - box.origin
	assert_eq(back[local], BlockIds.PLANKS)
	assert_eq(back[local + Vector3i.UP], BlockIds.GLASS)
	assert_false(back.has(local + Vector3i.RIGHT), "a sword is never a block")
	assert_eq(back[Vector3i(0, ShowcaseArea.GROUND_LAYER, 0)], BlockIds.GRASS, "the ground the child stood on comes too")
	assert_eq(back[Vector3i(0, 0, 0)], BlockIds.DIRT, "and what is under it")
	assert_eq(back.size(), 32 * 32 * ShowcaseArea.BELOW + 2, "eight layers of ground and the two blocks")
	assert_eq(ShowcaseArea.problem(text), "")


func test_a_very_busy_area_is_too_detailed_and_an_empty_one_is_nothing() -> void:
	var cells := PackedInt32Array()
	for i in 32 * 32 * 32:
		cells.append(200 if i % 2 == 0 else 201)
	assert_eq(ShowcaseArea.problem(BuildCodec.encode_cells(Vector3i(32, 32, 32), cells)), "too_detailed")
	var air := PackedInt32Array()
	air.resize(8)
	assert_eq(ShowcaseArea.problem(BuildCodec.encode_cells(Vector3i(2, 2, 2), air)), "empty")
	assert_ne(ShowcaseArea.message("too_detailed"), "")
	assert_ne(ShowcaseArea.message("empty"), "")


func test_a_buddy_inside_the_area_waves_there() -> void:
	var box := ShowcaseArea.box_around(Vector3(0, 10, 0))
	var blocks := {Vector3i(0, 0, 0): BlockIds.CRYSTAL, Vector3i(0, 1, 0): BlockIds.CRYSTAL}
	var entry := ShowcaseArea.buddy_entry(blocks, Vector3(3.5, 10.0, -2.5), box.origin, box.size)
	assert_eq(entry.at, [3 + 16, ShowcaseArea.BELOW, -3 + 16])
	assert_eq(BuildCodec.decode(entry.build, BuildCodec.BUDDY).size(), 2)
	assert_eq(ShowcaseArea.buddy_entry(blocks, Vector3(40, 10, 0), box.origin, box.size), {}, "outside the area")
	var nearest := ShowcaseArea.nearest_buddy([
		{"blocks": blocks, "pos": Vector3(10, 10, 10)}, {"blocks": blocks, "pos": Vector3(1, 10, 1)}], Vector3(0, 10, 0), box)
	assert_eq(nearest.at, [1 + 16, ShowcaseArea.BELOW, 1 + 16])


func test_the_bulk_copy_and_the_cell_by_cell_read_agree() -> void:
	var buf := VoxelBuffer.new()
	buf.create(5, 4, 3)
	buf.set_voxel(BlockIds.BRICK, 1, 2, 0, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(200, 4, 0, 2, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.GRASS, 0, 0, 0, VoxelBuffer.CHANNEL_TYPE)
	var by_cell := ShowcaseArea.snapshot(Vector3i.ZERO, Vector3i(5, 4, 3), func(p: Vector3i) -> int:
		return buf.get_voxel(p.x, p.y, p.z, VoxelBuffer.CHANNEL_TYPE))
	assert_eq(ShowcaseArea.snapshot_buffer(buf), by_cell)
	var one := VoxelBuffer.new()
	one.create(2, 2, 2)
	one.fill(BlockIds.STONE, VoxelBuffer.CHANNEL_TYPE)
	assert_eq(BuildCodec.count_of(ShowcaseArea.snapshot_buffer(one)), 8, "a copy of one block everywhere")


func test_the_snapshot_can_run_off_the_main_thread() -> void:
	var buf := VoxelBuffer.new()
	buf.create(32, 32, 32)
	buf.set_voxel(BlockIds.BRICK, 3, 3, 3, VoxelBuffer.CHANNEL_TYPE)
	var text: String = await ShowcaseArea.snapshot_async(get_tree(), buf)
	assert_eq(BuildCodec.decode(text, BuildCodec.SHOWCASE), {Vector3i(3, 3, 3): BlockIds.BRICK})
