extends GutTest
## Owner #68 (spec §22.1, ruling 6): the block board's goals ("build the answer"), checked on any set of cells so a build
## in the world can be checked the same way later. Cells are Vector2i (x across, y up from the ground row).

const WALL := {"cols": 8, "rows": 5, "block": 9, "given": [], "view": "wall"}


func _rect(x0: int, y0: int, w: int, h: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			out.append(Vector2i(x, y))
	return out


func test_count() -> void:
	var goal := {"kind": "count", "n": 5}
	assert_true(BuildCheck.check(goal, WALL, _rect(0, 0, 5, 1)))
	assert_true(BuildCheck.check(goal, WALL, [Vector2i(0, 0), Vector2i(3, 2), Vector2i(7, 4), Vector2i(1, 1), Vector2i(2, 3)]),
		"any five blocks")
	assert_false(BuildCheck.check(goal, WALL, _rect(0, 0, 4, 1)))
	assert_false(BuildCheck.check(goal, WALL, _rect(0, 0, 6, 1)))


func test_array_is_a_filled_rectangle_of_rows_and_columns() -> void:
	var goal := {"kind": "array", "rows": 3, "cols": 4}
	assert_true(BuildCheck.check(goal, WALL, _rect(0, 0, 4, 3)))
	assert_true(BuildCheck.check(goal, WALL, _rect(2, 1, 4, 3)), "anywhere on the board")
	assert_false(BuildCheck.check(goal, WALL, _rect(0, 0, 3, 4)), "4 rows of 3 is another array")
	var holey := _rect(0, 0, 4, 3)
	holey.remove_at(5)
	holey.append(Vector2i(7, 4))
	assert_false(BuildCheck.check(goal, WALL, holey), "twelve blocks, but not a filled 3 by 4")
	assert_true(BuildCheck.check({"kind": "array", "rows": 3, "cols": 4, "any_turn": true}, WALL, _rect(0, 0, 3, 4)),
		"any_turn: either way round")


func test_rectangle_by_area_perimeter_and_smallest_side() -> void:
	var area := {"kind": "rectangle", "area": 12}
	assert_true(BuildCheck.check(area, WALL, _rect(0, 0, 6, 2)))
	assert_true(BuildCheck.check(area, WALL, _rect(0, 0, 3, 4)))
	assert_false(BuildCheck.check(area, WALL, _rect(0, 0, 5, 2)))
	var farm := {"kind": "rectangle", "area": 12, "perimeter": 14}
	assert_true(BuildCheck.check(farm, WALL, _rect(0, 0, 4, 3)))
	assert_false(BuildCheck.check(farm, WALL, _rect(0, 0, 6, 2)), "area 12 but fence 16")
	var wide := {"kind": "rectangle", "area": 8, "min_side": 2}
	assert_false(BuildCheck.check(wide, WALL, _rect(0, 0, 8, 1)))
	assert_true(BuildCheck.check(wide, WALL, _rect(0, 0, 4, 2)))


func test_fraction_of_the_wall() -> void:
	var wall := {"cols": 8, "rows": 1, "block": 9, "given": []}
	var goal := {"kind": "fraction", "num": 3, "den": 8}
	assert_true(BuildCheck.check(goal, wall, _rect(0, 0, 3, 1)))
	assert_true(BuildCheck.check(goal, wall, [Vector2i(1, 0), Vector2i(4, 0), Vector2i(7, 0)]), "any 3 of the 8")
	assert_false(BuildCheck.check(goal, wall, _rect(0, 0, 4, 1)))
	var tenths := {"cols": 10, "rows": 2, "block": 9, "given": []}
	assert_true(BuildCheck.check({"kind": "fraction", "num": 3, "den": 10}, tenths, _rect(0, 0, 6, 1)), "3/10 of 20 is 6")


func test_mirror_finishes_the_other_half() -> void:
	var board := {"cols": 8, "rows": 4, "block": 9, "given": [[0, 0], [1, 0], [1, 1], [3, 2]]}
	var goal := {"kind": "mirror", "sum": 7}
	var given := BuildCheck.given(board)
	var done := given.duplicate()
	done.append_array([Vector2i(7, 0), Vector2i(6, 0), Vector2i(6, 1), Vector2i(4, 2)])
	assert_true(BuildCheck.check(goal, board, done))
	var half := done.duplicate()
	half.pop_back()
	assert_false(BuildCheck.check(goal, board, half), "one block short")
	assert_false(BuildCheck.check(goal, board, given), "nothing built yet")
	var extra := done.duplicate()
	extra.append(Vector2i(5, 3))
	assert_false(BuildCheck.check(goal, board, extra), "a block with no twin")


func test_every_cell_must_be_on_the_board_and_given_cells_stay() -> void:
	assert_false(BuildCheck.check({"kind": "count", "n": 2}, WALL, [Vector2i(0, 0), Vector2i(8, 0)]))
	assert_false(BuildCheck.check({"kind": "count", "n": 2}, WALL, [Vector2i(0, 0), Vector2i(0, -1)]))
	var board := {"cols": 4, "rows": 2, "block": 9, "given": [[0, 0]]}
	assert_false(BuildCheck.check({"kind": "count", "n": 2}, board, [Vector2i(1, 0), Vector2i(2, 0)]),
		"the given block cannot go away")
	assert_true(BuildCheck.check({"kind": "count", "n": 2}, board, [Vector2i(0, 0), Vector2i(2, 0)]))


func test_duplicates_count_once() -> void:
	assert_false(BuildCheck.check({"kind": "count", "n": 2}, WALL, [Vector2i(0, 0), Vector2i(0, 0)]))


func test_every_goal_has_an_example_that_passes() -> void:
	var cases := [
		[{"kind": "count", "n": 7}, WALL],
		[{"kind": "array", "rows": 3, "cols": 4}, WALL],
		[{"kind": "array", "rows": 2, "cols": 5, "any_turn": true}, WALL],
		[{"kind": "rectangle", "area": 12, "perimeter": 14}, WALL],
		[{"kind": "rectangle", "area": 16, "min_side": 2}, WALL],
		[{"kind": "fraction", "num": 3, "den": 4}, {"cols": 8, "rows": 1, "block": 9, "given": []}],
		[{"kind": "mirror", "sum": 7}, {"cols": 8, "rows": 4, "block": 9, "given": [[0, 0], [2, 1], [3, 3]]}],
		[{"kind": "count", "n": 6}, {"cols": 4, "rows": 3, "block": 9, "given": [[0, 0], [1, 0]]}],
	]
	for c: Array in cases:
		var goal: Dictionary = c[0]
		var board: Dictionary = c[1]
		assert_eq(BuildCheck.problem(goal, board), "", "%s is a good goal" % goal)
		var ex := BuildCheck.example(goal, board)
		assert_true(BuildCheck.check(goal, board, ex), "%s: the example %s passes" % [goal, ex])


func test_goals_that_cannot_be_done_are_problems() -> void:
	assert_ne(BuildCheck.problem({"kind": "count", "n": 41}, WALL), "", "more blocks than the board holds")
	assert_ne(BuildCheck.problem({"kind": "array", "rows": 6, "cols": 2}, WALL), "", "taller than the board")
	assert_ne(BuildCheck.problem({"kind": "rectangle", "area": 12, "perimeter": 13}, WALL), "", "no such rectangle")
	assert_ne(BuildCheck.problem({"kind": "fraction", "num": 1, "den": 3}, {"cols": 8, "rows": 1, "block": 9}), "",
		"a third of 8 blocks")
	assert_ne(BuildCheck.problem({"kind": "mirror", "sum": 9}, {"cols": 8, "rows": 2, "block": 9, "given": [[0, 0]]}),
		"", "the twin of (0, 0) would be (9, 0), off the board")
	assert_ne(BuildCheck.problem({"kind": "mirror", "sum": 7}, {"cols": 8, "rows": 2, "block": 9, "given": []}), "",
		"nothing to mirror")
	assert_ne(BuildCheck.problem({"kind": "sing"}, WALL), "", "an unknown kind")
	assert_ne(BuildCheck.problem({"kind": "count", "n": 3}, {"cols": 20, "rows": 5, "block": 9}), "", "too wide a board")
	assert_ne(BuildCheck.problem({"kind": "count", "n": 3}, {"cols": 4, "rows": 2, "block": 9, "given": [[5, 0]]}), "",
		"a given block off the board")
