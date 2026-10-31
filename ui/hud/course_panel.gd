class_name CoursePanel
extends Control
## A course's small picture panel (M3 Task 7): a tap on its FINISH (or START) while not racing opens it. The
## builder's goals as pictures: a gold, a silver and a bronze medal, each with its time and big - and + buttons
## (a second a tap; the times keep their order); the best time with a star and who ran it; a robot badge when a
## bot friend can race the best run. Every change goes to the host (Session.request_course_goals); the host's
## answer (course_info_received) redraws it. A centred overlay like the Totem's panel: it closes on its X, a
## tap outside it, Back or pause.

signal opened
signal closed

const PANEL_SIZE := Vector2(700, 520)
const STEP_MS := 1000
const STEP_BUTTON := Vector2(96, 84)

var close_button: Button
var info := {}
var _panel := PanelContainer.new()
var _times: Array[Label] = []
var _steps: Array[Button] = []      # [- gold, + gold, - silver, + silver, - bronze, + bronze]
var _best_label := Label.new()
var _bot_row := HBoxContainer.new()


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.12, 0.16), 26, 20))
	add_child(_panel)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		_panel.set_anchor(side, 0.5)
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_top = -PANEL_SIZE.y * 0.5
	_panel.offset_bottom = PANEL_SIZE.y * 0.5
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	column.add_child(_header())
	for i in 3:
		column.add_child(_goal_row(i))
	column.add_child(_best_row())
	_bot_row.add_theme_constant_override("separation", 12)
	var badge := TextureRect.new()
	badge.texture = BotFriend.robot_badge()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bot_row.add_child(badge)
	_bot_row.add_child(_word("Bot friends can race your best run!", 24))
	column.add_child(_bot_row)


## Opens with a course's info from the host (CourseDirector.info_of).
func open(course: Dictionary) -> void:
	show_info(course)
	visible = true
	opened.emit()


func close() -> void:
	if visible:
		visible = false
		closed.emit()


## The host's info for the course (also after a goal changed).
func show_info(course: Dictionary) -> void:
	info = course
	var goals := goals_ms()
	for i in 3:
		_times[i].text = CourseRules.format_time(goals[i]) if goals.size() == 3 else "-"
	var best := int(course.get("best", 0))
	_best_label.text = "%s  %s" % [CourseRules.format_time(best), str(course.get("best_name", ""))] if best > 0 else "-"
	_bot_row.visible = bool(course.get("ghost", false))


func goals_ms() -> Array[int]:
	return CourseRules.clean_goals(info.get("goals", []))


## Medal `i` (0 gold, 1 silver, 2 bronze) a second faster (-1) or slower (+1): asks the host.
func step(i: int, direction: int) -> void:
	var goals := goals_ms()
	if goals.size() != 3 or not info.has("cell"):
		return
	var changed := CourseRules.step_goal(goals, i, direction * STEP_MS)
	info.goals = changed
	show_info(info)
	Session.request_course_goals(info.cell, changed)


func step_buttons() -> Array[Button]:
	return _steps


func panel_rect(screen: Vector2) -> Rect2:
	return Rect2(screen * 0.5 - PANEL_SIZE * 0.5, PANEL_SIZE)


## A tap outside the panel closes it (the dim area).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()


func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var flag := TextureRect.new()
	flag.texture = BlockIcons.icon(BlockIds.FINISH)
	flag.custom_minimum_size = Vector2(56, 56)
	flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(flag)
	var title := _word("Your course", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	close_button = UiKit.big_button("X", UiKit.RED, Vector2(84, 84))
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


func _goal_row(i: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var medal := RaceClock.Picture.new()
	medal.kind = CourseRules.MEDALS[i]
	medal.custom_minimum_size = Vector2(64, 64)
	row.add_child(medal)
	var time := _word("-", 36)
	time.custom_minimum_size.x = 170
	_times.append(time)
	row.add_child(time)
	for direction in [-1, 1]:
		var b := UiKit.big_button("-" if direction < 0 else "+", UiKit.BLUE if direction < 0 else UiKit.ORANGE, STEP_BUTTON)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 40)
		b.name = "%s%s" % [String(CourseRules.MEDALS[i]).capitalize(), "Faster" if direction < 0 else "Slower"]
		b.pressed.connect(step.bind(i, direction))
		_steps.append(b)
		row.add_child(b)
	return row


func _best_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var star := RaceClock.Picture.new()
	star.kind = &"star"
	star.custom_minimum_size = Vector2(48, 48)
	row.add_child(star)
	_best_label.add_theme_font_size_override("font_size", 30)
	row.add_child(_best_label)
	return row


func _word(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
