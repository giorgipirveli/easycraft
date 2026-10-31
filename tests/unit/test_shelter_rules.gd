extends GutTest
## Build to Survive's shelter rule (spec §12.18): a player is sheltered when a solid block is within 4 above
## the head (a roof) and walls close them in at the head and at the feet: a flood through open cells (four
## sides at a time, never across a crack where two blocks only touch at an edge) never gets 6 blocks away.
## It is the exact form of "every flat ray meets a wall within 6": a fixed set of rays would miss a
## window between two of them. Closed doors, glass and leaves are solid; open doors, water, bushes and air
## are not.

const FEET := Vector3i(10, 20, -4)

var _blocks := {}


func before_each() -> void:
	_blocks.clear()


func _at(p: Vector3i) -> int:
	return _blocks.get(p, BlockIds.AIR)


func _solid() -> Callable:
	return func(p: Vector3i) -> bool: return BlockIds.is_solid(_at(p))


## A room around FEET: walls `r` blocks out on every side, `high` blocks tall from the floor (FEET.y),
## a roof `roof` blocks above the head (0 = none), all of `id`.
func _room(r: int, high: int = 2, roof: int = 1, id: int = BlockIds.PLANKS) -> void:
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			_blocks[FEET + Vector3i(dx, -1, dz)] = BlockIds.STONE   # a floor
			if absi(dx) == r or absi(dz) == r:
				for dy in high:
					_blocks[FEET + Vector3i(dx, dy, dz)] = id
			if roof > 0:
				_blocks[FEET + Vector3i(dx, 1 + roof, dz)] = id


func test_a_closed_room_with_a_roof_is_a_shelter() -> void:
	_room(2)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE)
	assert_true(ShelterRules.is_sheltered(FEET, _solid()))


func test_no_walls_and_no_roof_is_open() -> void:
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.OPEN)
	assert_false(ShelterRules.is_sheltered(FEET, _solid()))


func test_walls_without_a_roof() -> void:
	_room(2, 2, 0)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.NO_ROOF)
	assert_false(ShelterRules.is_sheltered(FEET, _solid()))


func test_a_roof_counts_up_to_four_above_the_head() -> void:
	_room(2, 6, 4)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE, "4 above the head")
	_blocks.clear()
	_room(2, 7, 5)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.NO_ROOF, "5 above the head is too high")


func test_a_roof_alone_over_open_ground_leaves_a_gap() -> void:
	_blocks[FEET + Vector3i(0, 2, 0)] = BlockIds.PLANKS
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.GAP)


func test_a_closed_door_is_a_wall_an_open_door_a_gap() -> void:
	_room(2)
	_blocks[FEET + Vector3i(2, 0, 0)] = BlockIds.DOOR
	_blocks[FEET + Vector3i(2, 1, 0)] = BlockIds.DOOR
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE, "a closed doorway")
	_blocks[FEET + Vector3i(2, 0, 0)] = BlockIds.DOOR_OPEN
	_blocks[FEET + Vector3i(2, 1, 0)] = BlockIds.DOOR_OPEN
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.GAP, "the door is open")


func test_one_missing_block_at_the_head_or_the_feet_is_a_gap() -> void:
	_room(2)
	_blocks.erase(FEET + Vector3i(-2, 1, 1))
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.GAP, "a window at the head")
	_blocks[FEET + Vector3i(-2, 1, 1)] = BlockIds.PLANKS
	_blocks.erase(FEET + Vector3i(1, 0, 2))
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.GAP, "a hole at the feet: a slime fits through")


func test_every_direction_is_checked_even_between_the_main_ones() -> void:
	_room(4)
	_blocks.erase(FEET + Vector3i(4, 1, 2))   # a window about 27 degrees off the +X ray
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.GAP)


func test_a_missing_corner_block_still_closes_the_room() -> void:
	_room(2)
	for dy in 2:
		_blocks.erase(FEET + Vector3i(2, dy, 2))   # the walls still touch at their edges: nobody fits through
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE)


func test_walls_count_within_six_blocks() -> void:
	_room(6)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE, "a big hall, corners included")
	_blocks.clear()
	_room(7)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.GAP, "too far to close anyone in")


func test_glass_and_leaves_are_walls_water_and_bushes_are_not() -> void:
	_room(2, 2, 1, BlockIds.GLASS)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE, "a glass house")
	_blocks.clear()
	_room(2, 2, 1, BlockIds.LEAVES)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE, "a hedge hut")
	for id in [BlockIds.WATER, BlockIds.BUSH, BlockIds.DOOR_OPEN]:
		_blocks.clear()
		_room(2, 2, 1, BlockIds.PLANKS)
		for dy in 2:
			_blocks[FEET + Vector3i(0, dy, -2)] = id
		assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.GAP, BlockIds.display_name(id))


func test_a_little_cave_is_a_shelter() -> void:
	for dx in range(-7, 8):
		for dz in range(-7, 8):
			for dy in range(-1, 7):
				_blocks[FEET + Vector3i(dx, dy, dz)] = BlockIds.STONE
	_blocks.erase(FEET)
	_blocks.erase(FEET + Vector3i.UP)
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE)


func test_the_hints_are_short_and_kind() -> void:
	assert_eq(ShelterRules.hint(ShelterRules.SAFE), "Safe inside!")
	assert_eq(ShelterRules.hint(ShelterRules.NO_ROOF), "Add a roof!")
	assert_eq(ShelterRules.hint(ShelterRules.GAP), "Close the gap!")
	assert_eq(ShelterRules.hint(ShelterRules.OPEN), "Build walls and a roof!")


func test_the_feet_cell_of_a_body_and_the_box_to_read() -> void:
	assert_eq(ShelterRules.feet_cell(Vector3(3.4, 20.0, -0.2)), Vector3i(3, 20, -1))
	assert_eq(ShelterRules.feet_cell(Vector3(3.4, 20.99, 5.9)), Vector3i(3, 20, 5))
	var box := ShelterRules.box(FEET)
	var origin: Vector3i = box[0]
	var size: Vector3i = box[1]
	assert_eq(origin, FEET - Vector3i(6, 0, 6))
	assert_eq(size, Vector3i(13, 6, 13), "every cell the rule reads: head + 4 up, 6 around")
	_room(6, 2, 4)
	var reader := func(p: Vector3i) -> bool:
		var l := p - origin
		assert_true(l.x >= 0 and l.y >= 0 and l.z >= 0 and l.x < size.x and l.y < size.y and l.z < size.z, "read %s inside the box" % p)
		return BlockIds.is_solid(_at(p))
	ShelterRules.check(FEET, reader)


## A bent way out: straight rays from the middle would all meet a wall, but a monster walks round the bend.
func test_a_passage_round_a_corner_is_a_way_out() -> void:
	_room(2)
	for dy in 2:
		_blocks.erase(FEET + Vector3i(2, dy, 0))                # a doorway on +X ...
		_blocks[FEET + Vector3i(3, dy, -1)] = BlockIds.PLANKS   # ... into a corridor along +Z (x = 3)
		for dz in range(-1, 9):
			_blocks[FEET + Vector3i(4, dy, dz)] = BlockIds.PLANKS   # its far wall, right behind the doorway
			if dz >= 3:
				_blocks[FEET + Vector3i(2, dy, dz)] = BlockIds.PLANKS   # its near wall past the room
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.GAP, "the corridor leads out")
	for dy in 2:
		_blocks[FEET + Vector3i(3, dy, 5)] = BlockIds.PLANKS   # a wall across the corridor
	assert_eq(ShelterRules.check(FEET, _solid()), ShelterRules.SAFE, "closed off: a nook of the house")


func test_sheltered_asks_for_the_roof_first() -> void:
	var reads := [0]
	var counting := func(p: Vector3i) -> bool:
		reads[0] += 1
		return BlockIds.is_solid(_at(p))
	assert_false(ShelterRules.is_sheltered(FEET, counting))
	assert_lte(reads[0], ShelterRules.ROOF_REACH, "no roof: no need to look at walls")
