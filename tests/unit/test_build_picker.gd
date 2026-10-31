extends GutTest
## BuildPicker (M4 Wave 3, agent I; M3 Task 8's Build-and-Wear reuses it): tap a block of a small build
## and get the connected blocks that are not natural ground, at most 8 x 8 x 8 and 512 blocks.


## A world of `blocks` over flat grass at y 0 (dirt under it).
func _world(blocks: Dictionary) -> Callable:
	return func(p: Vector3i) -> int:
		if blocks.has(p):
			return blocks[p]
		if p.y == 0:
			return BlockIds.GRASS
		return BlockIds.DIRT if p.y < 0 else BlockIds.AIR


func _tower(at: Vector3i, height: int, id: int = BlockIds.PLANKS) -> Dictionary:
	var b := {}
	for y in height:
		b[at + Vector3i(0, y, 0)] = id
	return b


func test_the_connected_build_is_picked_and_the_ground_is_not() -> void:
	var build := _tower(Vector3i(3, 1, 3), 4)
	build[Vector3i(4, 2, 3)] = BlockIds.GLASS
	build[Vector3i(9, 1, 9)] = BlockIds.BRICK   # another build, not touching
	var r := BuildPicker.pick(Vector3i(3, 2, 3), _world(build))
	assert_false(r.has("error"), str(r))
	assert_eq((r.blocks as Dictionary).size(), 5)
	assert_false((r.blocks as Dictionary).has(Vector3i(9, 1, 9)), "only what touches")
	assert_false((r.blocks as Dictionary).has(Vector3i(3, 0, 3)), "never the grass under it")
	assert_eq(r.origin, Vector3i(3, 1, 3))
	assert_eq(r.size, Vector3i(2, 4, 1))


func test_the_local_build_starts_at_its_lowest_corner() -> void:
	var build := _tower(Vector3i(-7, 5, 12), 2, BlockIds.BRICK)
	var r := BuildPicker.pick(Vector3i(-7, 6, 12), _world(build))
	assert_eq(BuildPicker.local(r), {Vector3i(0, 0, 0): BlockIds.BRICK, Vector3i(0, 1, 0): BlockIds.BRICK})


func test_natural_ground_is_not_a_build() -> void:
	var r := BuildPicker.pick(Vector3i(0, 0, 0), _world({}))
	assert_eq(r.get("error"), "not_a_build")
	assert_eq(BuildPicker.pick(Vector3i(0, 5, 0), _world({})).get("error"), "not_a_build", "air")


func test_a_side_longer_than_eight_is_too_big() -> void:
	var r := BuildPicker.pick(Vector3i(0, 1, 0), _world(_tower(Vector3i(0, 1, 0), 9)))
	assert_eq(r.get("error"), "too_big")
	assert_false(BuildPicker.pick(Vector3i(0, 1, 0), _world(_tower(Vector3i(0, 1, 0), 8))).has("error"), "eight is fine")


func test_more_than_512_blocks_is_too_big_and_a_full_cube_of_eight_is_not() -> void:
	var cube := {}
	for x in 8:
		for y in 8:
			for z in 8:
				cube[Vector3i(x, y + 1, z)] = BlockIds.BRICK
	var r := BuildPicker.pick(Vector3i(0, 1, 0), _world(cube))
	assert_eq((r.get("blocks", {}) as Dictionary).size(), 512)
	cube[Vector3i(8, 1, 0)] = BlockIds.BRICK
	assert_eq(BuildPicker.pick(Vector3i(0, 1, 0), _world(cube)).get("error"), "too_big")


func test_a_huge_build_stops_the_search_early() -> void:
	# A wall 100 long: the picker gives up once the box is too big, reading only a few cells.
	var wall := {}
	for x in 100:
		wall[Vector3i(x, 1, 0)] = BlockIds.PLANKS if x % 2 else BlockIds.BRICK
	var reads := [0]
	var world := _world(wall)
	var counted := func(p: Vector3i) -> int:
		reads[0] += 1
		return world.call(p)
	assert_eq(BuildPicker.pick(Vector3i(0, 1, 0), counted).get("error"), "too_big")
	assert_lt(reads[0], 200, "stops early: %d reads" % reads[0])


func test_the_picked_build_encodes_as_a_gift() -> void:
	var build := _tower(Vector3i(3, 1, 3), 3)
	var r := BuildPicker.pick(Vector3i(3, 1, 3), _world(build))
	var text := BuildCodec.encode(r.blocks)
	assert_eq(BuildCodec.decode(text, BuildCodec.GIFT), BuildPicker.local(r))


func test_the_words_for_a_child() -> void:
	assert_string_contains(BuildPicker.message("not_a_build"), "build")
	assert_string_contains(BuildPicker.message("too_big"), "8")
	assert_eq(BuildPicker.message(""), "")
