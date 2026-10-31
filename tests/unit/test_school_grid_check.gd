extends GutTest
## Owner #68, grade 5 maths (5.G.1, 5.G.2, 5.OA.3): the coordinate grid. A grid is {x_max, y_max, x_step?, y_step?,
## points?: [{x, y, label?}], join?, x_name?, y_name?} (GridCheck); a "point" exercise asks the child to tap one point of
## it: {type: "point", grid, answer: [x, y]}, and the response is the Vector2i tapped. Exactly one point is right.

const GRID := {"x_max": 10, "y_max": 8}
const POINT := {"type": "point", "prompt": "Tap the point (4, 7).", "grid": GRID, "answer": [4, 7],
	"hint": "Go 4 across first, then 7 up.", "explain": "4 across and 7 up."}


func test_a_grid_is_valid() -> void:
	assert_eq(GridCheck.problem(GRID), "")
	assert_eq(GridCheck.problem({"x_max": 12, "y_max": 24, "y_step": 2, "points": [{"x": 3, "y": 6, "label": "A"}],
		"join": true, "x_name": "days", "y_name": "cm"}), "")


func test_broken_grids_are_problems() -> void:
	for g: Variant in [null, {}, {"x_max": 0, "y_max": 5}, {"x_max": 5, "y_max": 30}, {"x_max": 10, "y_max": 9, "y_step": 2},
			{"x_max": 5, "y_max": 5, "points": [{"x": 6, "y": 1}]}, {"x_max": 5, "y_max": 5, "points": [{"x": 1}]},
			{"x_max": 10, "y_max": 10, "x_step": 2, "points": [{"x": 3, "y": 1}]},
			{"x_max": 5, "y_max": 5, "points": [{"x": 1, "y": 1, "label": "TOO LONG"}]},
			{"x_max": 5, "y_max": 5, "points": "A"}, {"x_max": 5.5, "y_max": 5}]:
		assert_ne(GridCheck.problem(g), "", str(g))


func test_the_lines_of_a_grid() -> void:
	assert_eq(GridCheck.lines({"x_max": 12, "y_max": 24, "y_step": 2}), Vector2i(12, 12))
	assert_true(GridCheck.on_grid(GRID, Vector2i(0, 0)), "the origin")
	assert_true(GridCheck.on_grid(GRID, Vector2i(10, 8)))
	assert_false(GridCheck.on_grid(GRID, Vector2i(11, 3)))
	assert_false(GridCheck.on_grid({"x_max": 10, "y_max": 10, "x_step": 2}, Vector2i(3, 3)), "between two lines")


func test_a_tap_snaps_to_the_nearest_point() -> void:
	assert_eq(GridCheck.nearest(GRID, Vector2(3.4, 6.6)), Vector2i(3, 7))
	assert_eq(GridCheck.nearest(GRID, Vector2(-0.4, 9.2)), Vector2i(0, 8), "kept on the grid")
	assert_eq(GridCheck.nearest({"x_max": 10, "y_max": 20, "y_step": 5}, Vector2(2.2, 7.6)), Vector2i(2, 10))


func test_a_point_is_written_as_a_pair() -> void:
	assert_eq(GridCheck.text(Vector2i(4, 7)), "(4, 7)")


func test_a_point_exercise_is_valid_and_right_by_its_answer_only() -> void:
	assert_eq(ExerciseCheck.problem(POINT), "")
	assert_eq(ExerciseCheck.answer_of(POINT), Vector2i(4, 7))
	assert_true(ExerciseCheck.is_right(POINT, Vector2i(4, 7)))
	assert_false(ExerciseCheck.is_right(POINT, Vector2i(7, 4)), "the pair the other way round")
	assert_false(ExerciseCheck.is_right(POINT, Vector2i(4, 6)))
	assert_false(ExerciseCheck.is_right(POINT, [4, 7]), "the response is the point tapped")
	assert_false(ExerciseCheck.is_right(POINT, null))
	assert_eq(ExerciseCheck.answer_text(POINT), "(4, 7)")


func test_broken_point_exercises_are_problems() -> void:
	var off := POINT.duplicate(true)
	off.answer = [11, 2]
	var between := POINT.duplicate(true)
	between.grid = {"x_max": 10, "y_max": 10, "x_step": 2}
	between.answer = [3, 4]
	var no_grid := POINT.duplicate(true)
	no_grid.erase("grid")
	var one := POINT.duplicate(true)
	one.answer = [4]
	for ex: Dictionary in [off, between, no_grid, one]:
		assert_ne(ExerciseCheck.problem(ex), "", str(ex))
