extends GutTest
## M3 Task 8 (spec §14.5, §5.5): the Sandbox power tools' pure rules. LINE: two taps, a straight line of the held
## block that you can walk along (each block touches the last one by a face), at most 64 blocks. FILL: the box
## between two taps, at most 4,096 blocks. COPY: two taps select a box of at most 16 on every side; the copy is
## kept the way it faced you, so a paste turns with you (and TURN adds quarter turns). Every tool only ever fills
## empty cells (air or water): it never breaks anything, a friend's build included.


func test_a_line_along_an_axis() -> void:
	var cells := PowerTools.line_cells(Vector3i(2, 5, -1), Vector3i(6, 5, -1))
	assert_eq(cells, [Vector3i(2, 5, -1), Vector3i(3, 5, -1), Vector3i(4, 5, -1), Vector3i(5, 5, -1), Vector3i(6, 5, -1)] as Array[Vector3i])
	var back := PowerTools.line_cells(Vector3i(0, 9, 0), Vector3i(0, 6, 0))
	assert_eq(back, [Vector3i(0, 9, 0), Vector3i(0, 8, 0), Vector3i(0, 7, 0), Vector3i(0, 6, 0)] as Array[Vector3i])
	assert_eq(PowerTools.line_cells(Vector3i(1, 1, 1), Vector3i(1, 1, 1)), [Vector3i(1, 1, 1)] as Array[Vector3i])


## A diagonal is a staircase: every block shares a face with the one before (you can walk up and along it).
func test_a_diagonal_line_is_a_staircase_from_end_to_end() -> void:
	for pair: Array in [[Vector3i(0, 0, 0), Vector3i(5, 3, 0)], [Vector3i(0, 0, 0), Vector3i(-4, 0, 7)],
			[Vector3i(3, 10, -2), Vector3i(-2, 4, 5)], [Vector3i(0, 0, 0), Vector3i(1, 1, 1)]]:
		var a: Vector3i = pair[0]
		var b: Vector3i = pair[1]
		var cells := PowerTools.line_cells(a, b)
		var d := (b - a).abs()
		assert_eq(cells.size(), d.x + d.y + d.z + 1, "%s -> %s" % [a, b])
		assert_eq(cells[0], a)
		assert_eq(cells[-1], b)
		for i in range(1, cells.size()):
			var step := (cells[i] - cells[i - 1]).abs()
			assert_eq(step.x + step.y + step.z, 1, "face to face at %d" % i)
		# it stays close to the straight line between the two ends
		var ab := Vector3(b - a)
		for c in cells:
			var ac := Vector3(c - a)
			var off := (ac - ab * (ac.dot(ab) / ab.length_squared())).length()
			assert_lt(off, 1.5, "%s near the line" % c)


func test_a_line_is_capped() -> void:
	assert_eq(PowerTools.line_refusal(Vector3i(0, 0, 0), Vector3i(63, 0, 0)), "", "64 blocks")
	assert_eq(PowerTools.line_refusal(Vector3i(0, 0, 0), Vector3i(64, 0, 0)), PowerTools.TOO_LONG, "65 blocks")
	assert_eq(PowerTools.line_refusal(Vector3i(0, 0, 0), Vector3i(30, 30, 3)), "", "a staircase of 64")
	assert_eq(PowerTools.line_refusal(Vector3i(0, 0, 0), Vector3i(30, 30, 4)), PowerTools.TOO_LONG)
	assert_eq(PowerTools.LINE_MAX, 64)


func test_the_box_between_two_corners() -> void:
	var cells := PowerTools.box_cells(Vector3i(3, 1, 2), Vector3i(1, 2, 2))
	assert_eq(cells.size(), 6)
	assert_eq(PowerTools.box_size(Vector3i(3, 1, 2), Vector3i(1, 2, 2)), Vector3i(3, 2, 1))
	assert_eq(PowerTools.box_count(Vector3i(3, 1, 2), Vector3i(1, 2, 2)), 6)
	for x in range(1, 4):
		for y in range(1, 3):
			assert_has(cells, Vector3i(x, y, 2))


## FILL: at most 4,096 blocks (the brief's cap): 16³ fits, one more layer does not, nor does a long flat floor.
func test_a_fill_is_capped_at_4096() -> void:
	assert_eq(PowerTools.FILL_MAX, 4096)
	assert_eq(PowerTools.fill_refusal(Vector3i(0, 0, 0), Vector3i(15, 15, 15)), "", "16 x 16 x 16")
	assert_eq(PowerTools.fill_refusal(Vector3i(0, 0, 0), Vector3i(63, 0, 63)), "", "64 x 1 x 64")
	assert_eq(PowerTools.fill_refusal(Vector3i(0, 0, 0), Vector3i(15, 16, 15)), PowerTools.TOO_BIG)
	assert_eq(PowerTools.fill_refusal(Vector3i(-40, 0, 0), Vector3i(40, 0, 50)), PowerTools.TOO_BIG)
	assert_eq(PowerTools.message(PowerTools.TOO_BIG), "That box is too big! At most 4,096 blocks.")


func test_a_fill_puts_the_block_only_into_empty_cells() -> void:
	var world := {Vector3i(1, 0, 0): BlockIds.BRICK, Vector3i(2, 0, 0): BlockIds.WATER}
	var get_block := func(p: Vector3i) -> int: return world.get(p, BlockIds.AIR)
	var edits := PowerTools.fill_edits(Vector3i(0, 0, 0), Vector3i(2, 1, 0), BlockIds.GLASS, get_block)
	assert_eq(edits.size(), 5, "the brick stays; water is filled")
	for e: Array in edits:
		assert_eq(e[1], BlockIds.GLASS)
		assert_ne(e[0], Vector3i(1, 0, 0))
	var line := PowerTools.line_edits(Vector3i(0, 0, 0), Vector3i(3, 0, 0), BlockIds.STONE, get_block)
	assert_eq(line.size(), 3)
	assert_true(PowerTools.is_empty(BlockIds.AIR) and PowerTools.is_empty(BlockIds.WATER))
	assert_false(PowerTools.is_empty(BlockIds.STONE))


func test_copy_is_capped_at_16_on_every_side() -> void:
	assert_eq(PowerTools.COPY_MAX_SIDE, 16)
	assert_eq(PowerTools.copy_refusal(Vector3i(0, 0, 0), Vector3i(15, 15, 15)), "")
	assert_eq(PowerTools.copy_refusal(Vector3i(0, 0, 0), Vector3i(16, 0, 0)), PowerTools.TOO_BIG_COPY)
	assert_eq(PowerTools.copy_refusal(Vector3i(0, -3, 0), Vector3i(0, 13, 0)), PowerTools.TOO_BIG_COPY)


## A copy reads the box's bytes (one bulk copy of the world, DEVELOPMENT.md §8): its blocks from the box's lowest
## corner, without air, bedrock or anything that is not a block.
func test_a_copy_reads_the_blocks_of_the_box() -> void:
	var buf := VoxelBuffer.new()
	buf.create(3, 2, 2)
	buf.set_voxel(BlockIds.BRICK, 0, 0, 0, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.GLASS, 2, 1, 1, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.BEDROCK, 1, 0, 1, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.PAINTED_PINK, 1, 1, 0, VoxelBuffer.CHANNEL_TYPE)
	var blocks := PowerTools.copy_buffer(buf)
	assert_eq(blocks, {Vector3i(0, 0, 0): BlockIds.BRICK, Vector3i(2, 1, 1): BlockIds.GLASS,
		Vector3i(1, 1, 0): BlockIds.PAINTED_PINK})
	var one := VoxelBuffer.new()
	one.create(2, 2, 2)
	one.fill(BlockIds.STONE, VoxelBuffer.CHANNEL_TYPE)   # stored as one value until decompressed
	assert_eq(PowerTools.copy_buffer(one).size(), 8)


## An L of three blocks copied facing north (-Z), then pasted: facing north it keeps its shape; facing east it
## has turned a quarter to the right with the child.
func test_a_paste_turns_with_you() -> void:
	var copy := {Vector3i(0, 0, 0): BlockIds.RED, Vector3i(1, 0, 0): BlockIds.BLUE, Vector3i(0, 0, 1): BlockIds.GREEN}
	var north := Vector3i(0, 0, -1)
	var stamp := PowerTools.to_stamp(copy, north)
	var anchor := Vector3i(10, 5, 10)
	var same := _cells(PowerTools.paste_edits(stamp, anchor, north))
	assert_eq(same.size(), 3)
	# same shape, moved: red at the corner, blue one to the east of it, green one to the south of it
	var red: Vector3i = same.find_key(BlockIds.RED)
	assert_eq(same.get(red + Vector3i(1, 0, 0)), BlockIds.BLUE)
	assert_eq(same.get(red + Vector3i(0, 0, 1)), BlockIds.GREEN)
	for p: Vector3i in same:
		assert_eq(p.y, anchor.y, "it stands on the tapped cell")
		assert_lte(p.z, anchor.z, "it reaches away from the child (north)")
	var east := _cells(PowerTools.paste_edits(stamp, anchor, Vector3i(1, 0, 0)))
	var red_e: Vector3i = east.find_key(BlockIds.RED)
	assert_eq(east.get(red_e + Vector3i(0, 0, 1)), BlockIds.BLUE, "east of red is now south of it")
	assert_eq(east.get(red_e + Vector3i(-1, 0, 0)), BlockIds.GREEN, "south of red is now west of it")
	for p: Vector3i in east:
		assert_gte(p.x, anchor.x, "it reaches away from the child (east)")


## TURN: four quarter turns are the copy again; each keeps it standing on the tapped cell, centred, reaching away.
func test_turn_quarter_turns() -> void:
	var stamp := PowerTools.to_stamp({Vector3i(0, 0, 0): BlockIds.RED, Vector3i(1, 0, 0): BlockIds.BLUE,
		Vector3i(0, 1, 2): BlockIds.GREEN}, Vector3i(0, 0, -1))
	assert_eq(PowerTools.turned(stamp, 4), stamp)
	assert_eq(PowerTools.turned(PowerTools.turned(stamp, 1), 3), stamp)
	var once := PowerTools.turned(stamp, 1)
	assert_ne(once, stamp)
	var min_z := 99
	var min_y := 99
	var lo_x := 99
	var hi_x := -99
	for p: Vector3i in once:
		min_z = mini(min_z, p.z)
		min_y = mini(min_y, p.y)
		lo_x = mini(lo_x, p.x)
		hi_x = maxi(hi_x, p.x)
	assert_eq(min_z, 0)
	assert_eq(min_y, 0)
	assert_eq(lo_x, -floori((hi_x - lo_x + 1) / 2.0), "centred left to right")
	assert_eq(PowerTools.turned(stamp, -1), PowerTools.turned(stamp, 3))
	# a quarter to the right: what was further away is now on the right
	var two := PowerTools.turned({Vector3i(0, 0, 0): BlockIds.RED, Vector3i(0, 0, 1): BlockIds.BLUE}, 1)
	var red: Vector3i = two.find_key(BlockIds.RED)
	var blue: Vector3i = two.find_key(BlockIds.BLUE)
	assert_eq(blue - red, Vector3i(1, 0, 0), "blue went from behind red to its right")


func _cells(edits: Array) -> Dictionary:
	var out := {}
	for e: Array in edits:
		out[e[0]] = e[1]
	return out
