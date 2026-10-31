extends GutTest
## Owner #110, VR round 4 idea 5 (VR-HANDS; the research §5.3 "Build with your hands: the Build Table", R5): the Build
## Table's grid as pure rules. 10 cm cells, 16 a side (My Stamps' cap); the cell under the hand, a block only where it
## stands on the table or touches another, the mirror across the middle, turning in quarter turns, the build as a stamp
## for the world, and the School's boards (a wall: columns and rows up; a farm: seen from above).


func test_the_cell_under_a_point_of_the_tables_space() -> void:
	var size := BuildTableRules.FREE_SIZE
	assert_eq(BuildTableRules.cell_at(Vector3(0.05, 0.05, 0.05), size), Vector3i(0, 0, 0))
	assert_eq(BuildTableRules.cell_at(Vector3(1.55, 0.31, 0.72), size), Vector3i(15, 3, 7))
	assert_eq(BuildTableRules.cell_at(Vector3(1.65, 0.05, 0.05), size), BuildTableRules.NO_CELL, "past the edge")
	assert_eq(BuildTableRules.cell_at(Vector3(0.5, -0.02, 0.5), size), BuildTableRules.NO_CELL, "under the top")


func test_a_ghost_stands_on_the_table_or_touches_a_block() -> void:
	var size := BuildTableRules.FREE_SIZE
	var cells := {Vector3i(3, 0, 3): BlockIds.STONE}
	assert_eq(BuildTableRules.ghost_cell(Vector3(0.55, 0.05, 0.55), cells, size), Vector3i(5, 0, 5), "on the top")
	assert_eq(BuildTableRules.ghost_cell(Vector3(0.35, 0.15, 0.35), cells, size), Vector3i(3, 1, 3), "on the stone")
	assert_eq(BuildTableRules.ghost_cell(Vector3(0.95, 0.55, 0.95), cells, size), BuildTableRules.NO_CELL, "mid-air")
	assert_eq(BuildTableRules.ghost_cell(Vector3(0.35, 0.05, 0.35), cells, size), BuildTableRules.NO_CELL,
		"a block is there: it is touched, not built on")
	assert_eq(BuildTableRules.touched(Vector3(0.35, 0.05, 0.35), cells, size), Vector3i(3, 0, 3))


func test_the_mirror_copies_across_the_middle() -> void:
	var size := BuildTableRules.FREE_SIZE
	assert_eq(BuildTableRules.mirrored(Vector3i(2, 1, 4), size), Vector3i(13, 1, 4))
	assert_eq(BuildTableRules.mirrored(Vector3i(13, 1, 4), size), Vector3i(2, 1, 4))


func test_a_quarter_turn_turns_the_build_round_the_tables_middle() -> void:
	var size := BuildTableRules.FREE_SIZE
	var cells := {Vector3i(0, 0, 0): BlockIds.STONE, Vector3i(1, 2, 0): BlockIds.GLASS}
	var once := BuildTableRules.turned(cells, 1, size)
	assert_eq(once.size(), 2)
	assert_eq(once.get(Vector3i(0, 0, 15)), BlockIds.STONE, "counter-clockwise: the far-left corner to the near-left")
	var near_left := BuildTableRules.turned({Vector3i(0, 0, 15): BlockIds.STONE}, 1, size)
	assert_true(near_left.has(Vector3i(15, 0, 15)), "the near-left corner to the near-right")
	assert_eq(BuildTableRules.turned(BuildTableRules.turned(once, 1, size), 2, size), cells, "four turns: as it was")
	assert_eq(BuildTableRules.turned(cells, -1, size), BuildTableRules.turned(cells, 3, size))


func test_a_two_hand_twist_turns_in_quarters_past_45_degrees() -> void:
	assert_eq(BuildTableRules.twist_quarters(deg_to_rad(30.0)), 0)
	assert_eq(BuildTableRules.twist_quarters(deg_to_rad(50.0)), 1)
	assert_eq(BuildTableRules.twist_quarters(deg_to_rad(-50.0)), -1)
	assert_eq(BuildTableRules.twist_quarters(deg_to_rad(140.0)), 2)


func test_the_build_is_a_stamp_facing_the_child() -> void:
	# z counts towards the child: row 6 is nearer than row 2
	var cells := {Vector3i(4, 0, 6): BlockIds.STONE, Vector3i(5, 0, 6): BlockIds.STONE, Vector3i(4, 1, 2): BlockIds.GLASS}
	var stamp := BuildTableRules.as_stamp(cells)
	assert_eq(stamp.size(), 3)
	assert_true(stamp.has(Vector3i(-1, 0, 0)) and stamp.has(Vector3i(0, 0, 0)), "the nearest row at z = 0, centred")
	assert_eq(stamp.get(Vector3i(-1, 1, 4)), BlockIds.GLASS, "further away on the table: further away in the world")
	assert_eq(MyStampBook.refusal(BuildTableRules.stamp_blocks(cells)), "", "My Stamps takes it")


func test_the_schools_boards_on_the_table() -> void:
	var wall := {"cols": 4, "rows": 3, "block": BlockIds.STONE, "view": "wall"}
	assert_eq(BuildTableRules.board_size(wall), Vector3i(4, 3, 1), "a wall: columns across, rows up")
	assert_eq(BuildTableRules.board_cell(Vector3i(2, 1, 0), wall), Vector2i(2, 1))
	assert_eq(BuildTableRules.table_cell(Vector2i(2, 1), wall), Vector3i(2, 1, 0))
	var farm := {"cols": 5, "rows": 4, "block": BlockIds.GRASS, "view": "farm"}
	assert_eq(BuildTableRules.board_size(farm), Vector3i(5, 1, 4), "a farm: seen from above")
	assert_eq(BuildTableRules.board_cell(Vector3i(3, 0, 3), farm), Vector2i(3, 0), "its row 0 nearest the child")
	assert_eq(BuildTableRules.table_cell(Vector2i(3, 2), farm), Vector3i(3, 0, 1))
	assert_eq(BuildTableRules.board_cell(BuildTableRules.table_cell(Vector2i(4, 3), farm), farm), Vector2i(4, 3))


func test_a_board_needs_no_support_for_a_wall_or_a_farm_cell() -> void:
	var wall := {"cols": 4, "rows": 3, "block": BlockIds.STONE, "view": "wall"}
	var size := BuildTableRules.board_size(wall)
	assert_eq(BuildTableRules.ghost_cell(Vector3(0.25, 0.25, 0.05), {}, size, false), Vector3i(2, 2, 0),
		"a board's cell is a cell wherever it is")
