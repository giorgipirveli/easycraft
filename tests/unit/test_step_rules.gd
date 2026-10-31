extends GutTest
## Deferred M1 minor: auto-step and unstuck scaled to the body (Size Magic). The 0.65 m ledge probe
## sat inside a giant's 0.9 m radius, so a giant never stepped up, and unstuck only looked at the
## centre column, so a giant's side could stay inside a wall.

const R := PlacementRules.PLAYER_RADIUS
const GIANT_R := PlacementRules.PLAYER_RADIUS * 3.0
const NORMAL_ROOM := 2   # SizeMagic.clearance_blocks(NORMAL)
const GIANT_ROOM := 6    # SizeMagic.clearance_blocks(GIANT)
const GIANT_AT := Vector3(6.05, 10.05, 5.5)   # its right side touches the ledge face at x = 7

var cells := {}


func before_each() -> void:
	cells = {}


func _solid(cell: Vector3i) -> bool:
	return cells.has(cell)


func test_room_matches_size_magic() -> void:
	assert_eq(SizeMagic.clearance_blocks(SizeMagic.Mode.NORMAL), NORMAL_ROOM)
	assert_eq(SizeMagic.clearance_blocks(SizeMagic.Mode.GIANT), GIANT_ROOM)


func test_a_normal_player_steps_onto_a_ledge_just_ahead() -> void:
	cells[Vector3i(6, 10, 5)] = true
	var at := Vector3(5.65, 10.05, 5.5)
	assert_true(StepRules.wants_step(at, Vector3.RIGHT, R, NORMAL_ROOM, _solid))
	assert_false(StepRules.wants_step(at, Vector3.LEFT, R, NORMAL_ROOM, _solid), "walking away from it")


func test_a_normal_player_does_not_step_a_two_block_wall() -> void:
	cells[Vector3i(6, 10, 5)] = true
	cells[Vector3i(6, 11, 5)] = true
	assert_false(StepRules.wants_step(Vector3(5.65, 10.05, 5.5), Vector3.RIGHT, R, NORMAL_ROOM, _solid))


func test_a_giant_steps_onto_a_ledge_at_its_edge() -> void:
	cells[Vector3i(7, 10, 5)] = true
	assert_true(StepRules.wants_step(GIANT_AT, Vector3.RIGHT, GIANT_R, GIANT_ROOM, _solid))


func test_a_giant_does_not_step_a_two_block_wall() -> void:
	cells[Vector3i(7, 10, 5)] = true
	cells[Vector3i(7, 11, 5)] = true
	assert_false(StepRules.wants_step(GIANT_AT, Vector3.RIGHT, GIANT_R, GIANT_ROOM, _solid))


func test_a_giant_needs_room_for_its_whole_height_on_the_ledge() -> void:
	cells[Vector3i(7, 10, 5)] = true
	cells[Vector3i(7, 16, 5)] = true      # 6 rows up from the ledge top: where the giant's head goes
	assert_false(StepRules.wants_step(GIANT_AT, Vector3.RIGHT, GIANT_R, GIANT_ROOM, _solid))
	cells.erase(Vector3i(7, 16, 5))
	cells[Vector3i(7, 17, 5)] = true      # one row higher: it fits
	assert_true(StepRules.wants_step(GIANT_AT, Vector3.RIGHT, GIANT_R, GIANT_ROOM, _solid))


func test_a_giant_does_not_hop_into_a_low_ceiling() -> void:
	cells[Vector3i(7, 10, 5)] = true
	cells[Vector3i(6, 16, 5)] = true      # right above the giant's head
	assert_false(StepRules.wants_step(GIANT_AT, Vector3.RIGHT, GIANT_R, GIANT_ROOM, _solid))


func test_the_footprint_covers_every_column_under_the_body() -> void:
	assert_eq(StepRules.footprint(Vector3(5.5, 0.0, 5.5), R).size(), 1)
	assert_has(StepRules.footprint(Vector3(5.5, 0.0, 5.5), R), Vector2i(5, 5))
	assert_eq(StepRules.footprint(Vector3(5.1, 0.0, 5.5), R).size(), 2, "straddling a block edge")
	assert_eq(StepRules.footprint(Vector3(5.5, 0.0, 5.5), GIANT_R).size(), 9, "a giant stands on 3 x 3")
	assert_eq(StepRules.footprint(Vector3(5.3, 0.0, 5.5), R).size(), 1, "touching a face is not standing in that block")


func test_unstuck_lifts_a_giant_whose_side_is_in_a_wall() -> void:
	for y in range(10, 13):
		cells[Vector3i(6, y, 5)] = true   # a 3-high wall beside the centre column
	var feet := Vector3(5.5, 10.05, 5.5)
	assert_eq(StepRules.first_free_y(feet, GIANT_R, GIANT_ROOM, 100, _solid), 13, "onto the wall")
	assert_eq(StepRules.first_free_y(feet, R, NORMAL_ROOM, 100, _solid), 10, "a normal body there is fine")
