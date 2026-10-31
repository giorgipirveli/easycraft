extends GutTest
## The research's "code the robot" (docs/design/school-curriculum-research.md §5.3; grade 3 computing: algorithms,
## sequences, debugging): a robot on a grid of squares faces N, E, S or W; a program is a list of commands, F (one square
## forward), L and R (turn left or right where it stands). It must reach the flag without bumping into a wall or leaving
## the grid (and, when the board has gems, pick up every one), in at most `max` commands when the exercise says so.

## 5 × 4: the robot at the top left facing east, the flag at the bottom right, a wall at (2, 0).
const BOARD := {"cols": 5, "rows": 4, "start": [0, 0], "facing": "E", "goal": [4, 3], "walls": [[2, 0]]}


func test_the_robot_runs_its_program() -> void:
	var r := RobotCheck.run(BOARD, ["F", "R", "F", "L", "F", "F", "F"])
	assert_eq(r.pos, Vector2i(4, 1))
	assert_eq(r.facing, "E")
	assert_false(r.crashed)
	assert_eq(r.path, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)])


func test_a_wall_or_the_edge_stops_it() -> void:
	var hit := RobotCheck.run(BOARD, ["F", "F", "R"])
	assert_true(hit.crashed, "the wall at (2, 0)")
	assert_eq(hit.pos, Vector2i(1, 0), "it stays in front of the wall")
	assert_eq(hit.crash_step, 1)
	var off := RobotCheck.run(BOARD, ["L", "F"])
	assert_true(off.crashed, "off the top edge")


func test_right_when_it_reaches_the_flag() -> void:
	var ex := {"type": "robot", "prompt": "Get the robot to the flag.", "hint": "Turn to face the flag's way.", "board": BOARD}
	assert_eq(ExerciseCheck.problem(ex), "")
	assert_true(ExerciseCheck.is_right(ex, ["F", "R", "F", "F", "F", "L", "F", "F", "F"]))
	assert_false(ExerciseCheck.is_right(ex, ["F", "R", "F", "F", "F"]), "not at the flag")
	assert_false(ExerciseCheck.is_right(ex, ["F", "F", "R", "F", "F", "F", "L", "F", "F"]), "it bumped the wall first")
	assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)), "the shortest program works")
	assert_eq((ExerciseCheck.answer_of(ex) as Array).size(), 9, "3 down, 3 across, 2 turns … the shortest")


func test_at_most_so_many_commands() -> void:
	var ex := {"type": "robot", "prompt": "In 9 commands or fewer.", "hint": "No extra turns.", "board": BOARD, "max": 9}
	assert_eq(ExerciseCheck.problem(ex), "")
	var long := ["R", "F", "F", "F", "L", "R", "L", "F", "F", "F", "F"]
	assert_true(RobotCheck.reaches(BOARD, long), "it gets there…")
	assert_false(ExerciseCheck.is_right(ex, long), "…in 11 commands: too many")
	ex.max = 5
	assert_ne(ExerciseCheck.problem(ex), "", "no program is that short")


func test_gems_must_all_be_picked_up() -> void:
	var b := BOARD.duplicate(true)
	b.gems = [[1, 2]]
	var ex := {"type": "robot", "prompt": "Pick up the gem, then go to the flag.", "hint": "Visit the gem first.", "board": b}
	assert_eq(ExerciseCheck.problem(ex), "")
	assert_false(ExerciseCheck.is_right(ex, ["R", "F", "F", "F", "L", "F", "F", "F", "F"]), "missed the gem")
	assert_true(ExerciseCheck.is_right(ex, ["R", "F", "F", "L", "F", "R", "F", "L", "F", "F", "F"]))
	assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)))


func test_odd_boards_say_why() -> void:
	var bad := {
		"too big": {"cols": 12},
		"the flag in a wall": {"walls": [[4, 3]]},
		"the start off the grid": {"start": [7, 0]},
		"a way to face": {"facing": "up"},
		"no way to the flag": {"walls": [[3, 3], [4, 2]]},
	}
	for why: String in bad:
		var b := BOARD.duplicate(true)
		b.merge(bad[why], true)
		assert_ne(RobotCheck.problem(b), "", why)


func test_the_answer_in_words() -> void:
	var ex := {"type": "robot", "prompt": "p", "hint": "h", "board": {"cols": 3, "rows": 3, "start": [0, 0],
		"facing": "S", "goal": [0, 2]}}
	assert_eq(ExerciseCheck.answer_text(ex), "FORWARD, FORWARD")
