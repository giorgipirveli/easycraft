class_name CrewCallCard
extends Control
## Crew flights (spec §21d.6 phase 2): the call's card over the world, on every game in it. A friend's card asks
## ("Anna is launching to the Moon! Take your seat.") with TAKE MY SEAT and STAY HERE and the countdown's big number;
## the pilot's card calls ("Calling your crew to the Moon!"), lists each friend's answer, and has LAUNCH NOW and NOT
## YET; when the seats are too few it says so and offers FLY WITH 1 FRIEND (or FLY ALONE) and ADD CAPSULES FIRST.
## Then words only (a seat is ready, the launch waits…), which may close by themselves. Read aloud; big buttons; the
## mouse, touch and a game controller (PadFocus) alike. It works while the world is paused.

signal answered(take: bool)
signal launch_now_pressed
signal not_yet_pressed
signal chose(fly: bool)
signal closed

const ASK := &"ask"
const PILOT := &"pilot"
const CHOOSE := &"choose"
const WORDS := &"words"
const SIZE := Vector2(820, 0)

var mode: StringName = WORDS
var take_button: Button
var stay_button: Button
var now_button: Button
var not_yet_button: Button
var fly_button: Button
var wait_button: Button
var words := Label.new()
var lines := Label.new()
var count := Label.new()

var _panel := PanelContainer.new()
var _left := -1.0       # seconds on the countdown (< 0: none)
var _close_in := -1.0   # seconds until it closes by itself (< 0: stays)


func _ready() -> void:
	name = "CrewCallCard"
	theme = UiKit.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.06, 0.09, 0.2, 0.94), 26, 26))
	_panel.custom_minimum_size = SIZE
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_panel.add_child(v)
	for l: Label in [words, lines, count]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(SIZE.x - 60, 0)
		v.add_child(l)
	words.add_theme_font_size_override("font_size", 36)
	lines.add_theme_font_size_override("font_size", 26)
	lines.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	count.add_theme_font_size_override("font_size", 72)
	count.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	v.add_child(row)
	take_button = UiKit.big_button(CrewFlightRules.TAKE, UiKit.GREEN, Vector2(340, 96))
	stay_button = UiKit.big_button(CrewFlightRules.STAY, UiKit.BLUE, Vector2(300, 96))
	now_button = UiKit.big_button(CrewFlightRules.LAUNCH_NOW, UiKit.GREEN, Vector2(320, 96))
	not_yet_button = UiKit.big_button(CrewFlightRules.NOT_YET, UiKit.BLUE, Vector2(260, 96))
	fly_button = UiKit.big_button(CrewFlightRules.fly_with_words(1), UiKit.GREEN, Vector2(360, 96))
	wait_button = UiKit.big_button(CrewFlightRules.ADD_CAPSULES, UiKit.ORANGE, Vector2(360, 96))
	take_button.name = "Take"
	stay_button.name = "Stay"
	now_button.name = "LaunchNow"
	not_yet_button.name = "NotYet"
	fly_button.name = "Fly"
	wait_button.name = "Wait"
	for b: Button in [take_button, stay_button, now_button, not_yet_button, fly_button, wait_button]:
		b.add_theme_font_size_override("font_size", 30)
		row.add_child(b)
	take_button.pressed.connect(func() -> void: answer(true))
	stay_button.pressed.connect(func() -> void: answer(false))
	now_button.pressed.connect(func() -> void: launch_now_pressed.emit())
	not_yet_button.pressed.connect(func() -> void: not_yet_pressed.emit())
	fly_button.pressed.connect(func() -> void: chose.emit(true))
	wait_button.pressed.connect(func() -> void: chose.emit(false))
	_show_buttons([])
	PadFocus.watch(self)


## A friend's card: the call's words and TAKE MY SEAT / STAY HERE, `seconds` on the clock.
func ask(text: String, seconds: float) -> void:
	mode = ASK
	_say(text)
	lines.visible = false
	_left = seconds
	_close_in = -1.0
	_show_count()
	_show_buttons([take_button, stay_button])


## TAKE MY SEAT (true) or STAY HERE: once.
func answer(take: bool) -> void:
	if mode != ASK:
		return
	answered.emit(take)


## The pilot's card while it calls: `title`, a line per friend, `seconds` on the clock.
func calling(title: String, friend_lines: Array[String], seconds: float) -> void:
	var first := mode != PILOT
	mode = PILOT
	if first:
		_say(title)
	lines.text = "\n".join(friend_lines)
	lines.visible = not friend_lines.is_empty()
	_left = seconds
	_close_in = -1.0
	_show_count()
	if first:
		_show_buttons([now_button, not_yet_button])


## The pilot's choice: the kind words why not everyone fits, FLY WITH … (`fly_words`) and ADD CAPSULES FIRST.
func choose(text: String, fly_words: String) -> void:
	mode = CHOOSE
	_say(text)
	lines.visible = false
	fly_button.text = fly_words
	_left = -1.0
	_close_in = -1.0
	_show_buttons([fly_button, wait_button])


## Words only; after `seconds` (> 0) the card closes by itself; the countdown stays if it runs.
func say(text: String, seconds: float = -1.0, keep_count: bool = false) -> void:
	mode = WORDS
	_say(text)
	lines.visible = false
	if not keep_count:
		_left = -1.0
	_close_in = seconds
	_show_buttons([])


func seconds_left() -> float:
	return _left


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


func _show_count() -> void:
	count.text = str(ceili(_left)) if _left > 0.0 else ""
	count.visible = _left > 0.0


func _say(text: String) -> void:
	if words.text != text:
		words.text = text
		ReadAloud.auto(text)


func _show_buttons(shown: Array) -> void:
	for b: Button in [take_button, stay_button, now_button, not_yet_button, fly_button, wait_button]:
		b.visible = shown.has(b)


func _process(delta: float) -> void:
	if _left >= 0.0:
		_left = maxf(_left - delta, 0.0)
	_show_count()
	if _close_in > 0.0:
		_close_in -= delta
		if _close_in <= 0.0:
			close()
