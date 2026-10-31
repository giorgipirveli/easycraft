extends GutTest
## Owner #116 (2026-10-16 15:04, "build a house like in real world, take brick or stones and put in apropriate place"):
## VrBrickRules, hand building in the world in VR. The ghost's cell next to the brick in the hand (flush against the
## face it touches, only touching a block or the ground), the laser's own place checks, the block a hand takes out of a
## wall, what the hand then holds (the Survivor drop), and which hotbar items are bricks.

## Stone under y 0, and a wall of bricks at x = 3 (y 0..2).
func _block_at(c: Vector3i) -> int:
	if c.y < 0:
		return BlockIds.STONE
	if c.x == 3 and c.y <= 2 and c.z == 0:
		return BlockIds.BRICK if BlockIds.is_valid(BlockIds.BRICK) else BlockIds.STONE
	if c == Vector3i(5, 0, 0):
		return BlockIds.WATER
	return BlockIds.AIR


func test_a_brick_by_the_ground_goes_in_the_cell_it_is_in() -> void:
	assert_eq(VrBrickRules.ghost_cell(Vector3(1.4, 0.3, 0.5), Vector3(1.4, 1.5, 0.5), _block_at), Vector3i(1, 0, 0),
		"on the ground: flush on its top")


func test_a_brick_in_the_air_has_no_cell() -> void:
	assert_eq(VrBrickRules.ghost_cell(Vector3(1.4, 1.5, 0.5), Vector3(1.4, 1.6, 1.5), _block_at), VrBrickRules.NO_CELL,
		"touching nothing: nowhere to go")


func test_a_brick_beside_a_wall_settles_flush_against_its_face() -> void:
	assert_eq(VrBrickRules.ghost_cell(Vector3(2.8, 1.5, 0.5), Vector3(1.5, 1.6, 0.5), _block_at), Vector3i(2, 1, 0))


func test_a_brick_on_top_of_the_wall_starts_the_next_row() -> void:
	assert_eq(VrBrickRules.ghost_cell(Vector3(3.5, 3.2, 0.5), Vector3(2.0, 3.6, 0.5), _block_at), Vector3i(3, 3, 0),
		"row by row")


func test_a_brick_pushed_into_the_wall_comes_back_out_to_the_face_it_went_through() -> void:
	assert_eq(VrBrickRules.ghost_cell(Vector3(3.3, 1.5, 0.5), Vector3(2.0, 1.5, 0.5), _block_at), Vector3i(2, 1, 0))
	assert_eq(VrBrickRules.ghost_cell(Vector3(3.5, 1.5, 0.3), Vector3(3.5, 1.5, -1.0), _block_at), Vector3i(3, 1, -1),
		"from the other side")


func test_the_place_checks_are_the_lasers() -> void:
	var eye := Vector3(1.5, 1.6, 2.5)
	var none: Array[AABB] = []
	var id := BlockIds.STONE
	assert_true(VrBrickRules.may_place(Vector3i(1, 0, 0), id, eye, none, _block_at))
	assert_false(VrBrickRules.may_place(Vector3i(1, 1, 0), id, eye, none, _block_at), "touching nothing")
	assert_false(VrBrickRules.may_place(Vector3i(3, 0, 0), id, eye, none, _block_at), "a block is there")
	assert_true(VrBrickRules.may_place(Vector3i(5, 0, 0), id, eye, none, _block_at), "into water, as the laser may")
	var me: Array[AABB] = [PlacementRules.player_aabb(Vector3(1.5, 0.0, 0.5))]
	assert_false(VrBrickRules.may_place(Vector3i(1, 0, 0), id, eye, me, _block_at), "never inside a player")
	assert_false(VrBrickRules.may_place(Vector3i(1, 0, 0), id, Vector3(40, 1.6, 0), none, _block_at), "out of reach")
	assert_false(VrBrickRules.may_place(Vector3i(1, 0, 0), ItemIds.WAND, eye, none, _block_at), "only blocks")


func test_a_hand_takes_the_block_it_is_in_or_the_one_whose_face_it_touches() -> void:
	assert_eq(VrBrickRules.block_to_take(Vector3(3.5, 1.5, 0.5), _block_at), Vector3i(3, 1, 0), "in it")
	assert_eq(VrBrickRules.block_to_take(Vector3(2.97, 1.5, 0.5), _block_at), Vector3i(3, 1, 0), "3 cm from its face")
	assert_eq(VrBrickRules.block_to_take(Vector3(2.8, 1.5, 0.5), _block_at), VrBrickRules.NO_CELL, "20 cm away")
	assert_eq(VrBrickRules.block_to_take(Vector3(1.5, 1.5, 0.5), _block_at), VrBrickRules.NO_CELL, "in the air")


func test_what_the_hand_holds_after_taking_a_block_keeps_the_survivor_drop() -> void:
	assert_eq(VrBrickRules.brick_id(BlockIds.STONE, false, 0), BlockIds.STONE, "the Sandbox: the block itself")
	assert_eq(VrBrickRules.brick_id(BlockIds.STONE, true, GatherRules.pickaxe_tier(Inventory.new())),
		GatherRules.drop(BlockIds.STONE, GatherRules.pickaxe_tier(Inventory.new())), "Survivor: its drop, the tier's")
	assert_eq(VrBrickRules.brick_id(BlockIds.AIR, false, 0), BlockIds.AIR)


func test_only_blocks_come_out_of_the_bag_as_bricks() -> void:
	assert_eq(VrBrickRules.bag_brick(BlockIds.STONE), BlockIds.STONE)
	assert_eq(VrBrickRules.bag_brick(ItemIds.SWORD), 0, "a sword is no brick")
	assert_eq(VrBrickRules.bag_brick(ItemIds.WAND), 0)
	assert_eq(VrBrickRules.bag_brick(0), 0)


func test_the_wrist_slot_under_a_point_of_the_strip() -> void:
	var slots: Array[Rect2] = [Rect2(300, 640, 62, 62), Rect2(368, 640, 62, 62), Rect2(436, 640, 62, 62)]
	assert_eq(VrBrickRules.slot_at(Vector2(330, 670), slots), 0)
	assert_eq(VrBrickRules.slot_at(Vector2(435, 670), slots), 2, "in a gap: the nearest slot")
	assert_eq(VrBrickRules.slot_at(Vector2(700, 670), slots), -1, "past the row")
