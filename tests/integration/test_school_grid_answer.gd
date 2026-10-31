extends GutTest
## Owner #68, grade 5 maths (5.G.1-2): a "point" exercise is answered by tapping a point on a coordinate grid
## (GridAnswer): a tap (a finger or the mouse) picks the nearest crossing, which shows as a dot with its pair written
## under the grid; tapping again moves it; CHECK answers. A miss keeps the dot (the child moves it); the second miss
## shows the right point. It fits the exercise panel.

const POINT := {"type": "point", "prompt": "Tap the point (4, 7).", "grid": {"x_max": 10, "y_max": 8},
	"answer": [4, 7], "hint": "Go 4 across first, then 7 up.", "explain": "4 across and 7 up: (4, 7)."}
const STEPPED := {"type": "point", "prompt": "Tap the point (3, 15).", "grid": {"x_max": 6, "y_max": 18, "y_step": 3,
	"points": [{"x": 1, "y": 3, "label": "A"}]}, "answer": [3, 15], "hint": "The lines up the side go in threes."}

var done: Array = []


func before_each() -> void:
	done.clear()


func _panel(ex: Dictionary) -> ExercisePanel:
	var p := ExercisePanel.new(ex, 0)
	p.answered.connect(func(first: bool) -> void: done.append(first))
	add_child_autofree(p)
	return p


func _click(view: Control, local: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = local
		view._gui_input(ev)


func test_the_panel_answers_with_a_grid() -> void:
	var p := _panel(POINT)
	await wait_process_frames(1)
	assert_true(p.answer_widget is GridAnswer)
	assert_true(p.check_button.visible, "a tap picks, CHECK answers")
	assert_true(p.check_button.disabled, "no point yet")


func test_a_tap_picks_a_point_and_check_answers() -> void:
	var p := _panel(POINT)
	await wait_process_frames(1)
	var g: GridAnswer = p.answer_widget
	g.tap(Vector2i(4, 7))
	assert_eq(g.response(), Vector2i(4, 7))
	assert_string_contains(g.said.text, "(4, 7)")
	assert_false(p.check_button.disabled)
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)
	p.next_button.pressed.emit()
	assert_eq(done, [true])


func test_a_miss_keeps_the_point_then_the_answer_shows() -> void:
	var p := _panel(POINT)
	await wait_process_frames(1)
	var g: GridAnswer = p.answer_widget
	g.tap(Vector2i(7, 4))
	p.check()
	assert_eq(p.state, ExercisePanel.ASKING)
	assert_string_contains(p.feedback.text, "Go 4 across first")
	assert_eq(g.response(), Vector2i(7, 4), "the dot stays, to be moved")
	g.tap(Vector2i(4, 6))
	p.check()
	assert_eq(p.state, ExercisePanel.SHOWN)
	assert_eq(g.response(), Vector2i(4, 7), "the right point shows")
	g.tap(Vector2i(1, 1))
	assert_eq(g.response(), Vector2i(4, 7), "locked")
	p.next_button.pressed.emit()
	assert_eq(done, [false])


func test_a_click_on_the_grid_finds_the_nearest_crossing() -> void:
	var p := _panel(STEPPED)
	await wait_process_frames(2)
	var g: GridAnswer = p.answer_widget
	var frame := g.view.frame()
	_click(g.view, SchoolPictureG5.grid_at(frame, Vector2i(3, 15)) + Vector2(5, 6))
	assert_eq(g.response(), Vector2i(3, 15))
	_click(g.view, SchoolPictureG5.grid_at(frame, Vector2i(0, 0)) + Vector2(-4, 4))
	assert_eq(g.response(), Vector2i(0, 0), "the origin too")
	_click(g.view, Vector2(-500, -500))
	assert_eq(g.response(), Vector2i(0, 0), "a tap far off the grid changes nothing")


func test_a_tap_off_the_crossings_is_not_taken() -> void:
	var p := _panel(STEPPED)
	await wait_process_frames(1)
	var g: GridAnswer = p.answer_widget
	g.tap(Vector2i(3, 14))
	assert_false(g.is_ready())


func test_it_fits_the_panel() -> void:
	for ex: Dictionary in [POINT, STEPPED]:
		var p := _panel(ex)
		await wait_process_frames(2)
		var size := p.get_combined_minimum_size()
		assert_lte(size.x, ExercisePanel.SIZE.x, "width %s" % size)
		assert_lte(size.y, ExercisePanel.SIZE.y, "height %s" % size)


func test_the_worked_answer_names_the_point() -> void:
	var ex := POINT.duplicate(true)
	ex.erase("explain")
	var p := _panel(ex)
	await wait_process_frames(1)
	var g: GridAnswer = p.answer_widget
	g.tap(Vector2i(1, 1))
	p.check()
	g.tap(Vector2i(2, 2))
	p.check()
	assert_string_contains(p.feedback.text, "(4, 7)")
