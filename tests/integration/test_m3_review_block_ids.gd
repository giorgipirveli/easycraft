extends GutTest
## M3 Task 19 (the whole-branch review): block ids past 255 (owner #45b's page 13, M3 Task 21c's pumpkins) meet the
## native byte searches of a copied box. A 16-bit voxel keeps its id in two bytes, low byte first: ROOF_TILES (266) is
## 0x0A 0x01, and its low byte is LIGHT (10). MonsterDirector.find_blocks matched the low byte alone, so every village
## roof was a light: monsters kept away from it and a child hiding under one was "in the light" (StealthDirector).
## BotRules.find_in_buffer could not look for an id past 255 at all (an air box answered "all birch logs").


func _box(fill: int = BlockIds.GRASS) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(9, 9, 9)
	buf.fill(fill, VoxelBuffer.CHANNEL_TYPE)
	return buf


func test_the_worlds_boxes_keep_ids_in_16_bits() -> void:
	assert_eq(_box().get_channel_depth(VoxelBuffer.CHANNEL_TYPE), VoxelBuffer.DEPTH_16_BIT,
		"WorldService.copy_box makes its boxes the same way")
	assert_eq(BlockIds.ROOF_TILES & 0xFF, BlockIds.LIGHT, "the clash this file is about")


func test_a_roof_is_not_a_light() -> void:
	var buf := _box()
	buf.set_voxel(BlockIds.ROOF_TILES, 1, 2, 3, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.ROOF_TILES, 4, 4, 4, VoxelBuffer.CHANNEL_TYPE)
	var origin := Vector3i(10, 20, 30)
	assert_eq(MonsterDirector.find_blocks(buf, origin, MonsterRules.LIGHT_BLOCKS), [] as Array[Vector3i],
		"village roofs are no lanterns")
	buf.set_voxel(BlockIds.LIGHT, 5, 6, 7, VoxelBuffer.CHANNEL_TYPE)
	assert_eq(MonsterDirector.find_blocks(buf, origin, MonsterRules.LIGHT_BLOCKS), [origin + Vector3i(5, 6, 7)] as Array[Vector3i],
		"a real light block is still found")


func test_find_blocks_finds_an_id_past_255() -> void:
	var buf := _box()
	buf.set_voxel(BlockIds.PUMPKIN, 2, 0, 8, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.PAINTED_PINK, 3, 3, 3, VoxelBuffer.CHANNEL_TYPE)   # 255: one byte, high byte 0
	buf.set_voxel(BlockIds.PURPLE, 5, 5, 5, VoxelBuffer.CHANNEL_TYPE)          # 16: the pumpkin's (272) low byte
	var ids: Array[int] = [BlockIds.PUMPKIN]
	assert_eq(MonsterDirector.find_blocks(buf, Vector3i.ZERO, ids), [Vector3i(2, 0, 8)] as Array[Vector3i])
	ids = [BlockIds.PURPLE]
	assert_eq(MonsterDirector.find_blocks(buf, Vector3i.ZERO, ids), [Vector3i(5, 5, 5)] as Array[Vector3i],
		"a pumpkin is no purple block")
	ids = [BlockIds.PAINTED_PINK]
	assert_eq(MonsterDirector.find_blocks(buf, Vector3i.ZERO, ids), [Vector3i(3, 3, 3)] as Array[Vector3i])


func test_bots_find_an_id_past_255_and_air_is_no_birch_log() -> void:
	var buf := _box()
	buf.set_voxel(BlockIds.BIRCH_LOG, 1, 2, 3, VoxelBuffer.CHANNEL_TYPE)
	var ids: Array[int] = [BlockIds.BIRCH_LOG]
	assert_eq(BotRules.find_in_buffer(buf, Vector3i(5, 5, 5), ids), [Vector3i(6, 7, 8)] as Array[Vector3i])
	var air := _box(BlockIds.AIR)
	air.set_voxel(BlockIds.STONE, 0, 0, 0, VoxelBuffer.CHANNEL_TYPE)   # not uniform: its bytes are searched
	assert_eq(BotRules.find_in_buffer(air, Vector3i.ZERO, ids), [] as Array[Vector3i], "256's low byte is air's")


func test_bots_still_find_their_ores_beside_blocks_past_255() -> void:
	var buf := _box()
	buf.set_voxel(BlockIds.DARK_LOG, 0, 0, 0, VoxelBuffer.CHANNEL_TYPE)   # 258: low byte 2, like DIRT
	buf.set_voxel(BlockIds.GOLD, 8, 8, 8, VoxelBuffer.CHANNEL_TYPE)
	var dirt: Array[int] = [BlockIds.DIRT]
	assert_eq(BotRules.find_in_buffer(buf, Vector3i.ZERO, dirt), [] as Array[Vector3i], "a dark log is no dirt")
	assert_eq(BotRules.find_in_buffer(buf, Vector3i.ZERO, BotRules.SHINY), [Vector3i(8, 8, 8)] as Array[Vector3i])
