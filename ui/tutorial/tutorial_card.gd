class_name TutorialCard
extends PanelContainer
## Pip's picture bubble for the tutorial step being played (M3 Task 15, spec §14.9): the step's picture, its very
## short words (a Label: it translates itself), the steps as dots, a speaker that reads the words, and a small X that
## stops the tutorial. Under the toasts, between the top-left buttons (and RIDE) and the find arrow, above the
## crosshair; only its two buttons take a touch (the sandbox adds them to the look area's blockers). Not a HUD
## button: it shows only while the tutorial plays.

signal stop_pressed

const TOP := 176.0
const WIDTH := 390.0
const MAX_HEIGHT := 150.0
const WORDS_WIDTH := 206.0
## The words' NORMAL size (TextSize: BIG makes it 28; M5 Task 6 review).
const WORDS_PX := 22
## At a bigger TEXT SIZE the words take the picture's place too (the step's picture and the dots step aside), so the
## card keeps its box: clear of the HUD's buttons and above the crosshair (a 390 x 150 card has no room to grow).
const BIG_WORDS_WIDTH := 288.0
const BUTTON := 52.0
const BG := Color(0.08, 0.1, 0.17, 0.9)
const RIM := Color("7fd8ff")   # Pip's blue eyes

var picture := TutorialPicture.new([], 72.0)
var words := Label.new()
var dots := StepDots.new()
var speaker: Button
var stop_button: Button


func _init() -> void:
	name = "TutorialCard"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UiKit.box(BG, 18, 10)
	box.border_color = RIM
	box.set_border_width_all(3)
	add_theme_stylebox_override("panel", box)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -WIDTH * 0.5
	offset_right = WIDTH * 0.5
	offset_top = TOP
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	row.add_child(picture)
	var middle := VBoxContainer.new()
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 6)
	words.custom_minimum_size.x = WORDS_WIDTH
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.add_child(words)
	middle.add_child(dots)
	row.add_child(middle)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	speaker = ReadAloud.button(func() -> String: return words.text, BUTTON)
	speaker.name = "TutorialSpeaker"
	speaker.focus_mode = Control.FOCUS_NONE
	buttons.add_child(speaker)
	_small(speaker, UiKit.BLUE)
	stop_button = UiKit.big_button("X", UiKit.RED, Vector2(BUTTON, BUTTON))
	stop_button.name = "TutorialStop"
	stop_button.focus_mode = Control.FOCUS_NONE
	stop_button.add_theme_font_size_override("font_size", 24)
	_small(stop_button, UiKit.RED)
	stop_button.tooltip_text = "Stop Pip's lessons"
	stop_button.pressed.connect(func() -> void: stop_pressed.emit())
	buttons.add_child(stop_button)
	row.add_child(buttons)
	fit_text_size()


func _ready() -> void:
	Game.settings_applied.connect(func(_s: Dictionary) -> void: fit_text_size())   # changed in SETTINGS while it plays


## Shows step `i` of `count` (TutorialRules' picture and words).
func show_step(i: int, count: int) -> void:
	picture.picture = TutorialRules.picture(i)
	words.text = TutorialRules.words(i)
	dots.count = count
	dots.current = i
	fit_text_size()
	visible = true


## The words at the chosen TEXT SIZE (M5 Task 1's rule for words read while playing; the M5 Task 6 review found the
## card left out): NORMAL beside the picture over the dots, BIG across the picture's place without the dots.
func fit_text_size() -> void:
	TextSize.mark(words, WORDS_PX)
	var big := TextSize.factor() > 1.0
	picture.visible = not big
	dots.visible = not big
	words.custom_minimum_size.x = BIG_WORDS_WIDTH if big else WORDS_WIDTH


## Thin margins: two buttons stacked stay inside MAX_HEIGHT.
static func _small(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", UiKit.box(color, 12, 4))
	b.add_theme_stylebox_override("hover", UiKit.box(color.lightened(0.12), 12, 4))
	b.add_theme_stylebox_override("pressed", UiKit.box(color.darkened(0.15), 12, 4))


## What takes a touch (the look area's blockers).
func blockers() -> Array[Control]:
	return [speaker, stop_button]


## The steps as dots: done ones green, this one orange and bigger, the rest grey.
class StepDots:
	extends Control
	const DOT := 7.0
	const GAP := 20.0
	var count := 0:
		set(value):
			count = value
			custom_minimum_size = Vector2(maxf(count, 1) * GAP, 2.0 * DOT + 4.0)
			queue_redraw()
	var current := 0:
		set(value):
			current = value
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in count:
			var c := Vector2(GAP * (i + 0.5), size.y * 0.5)
			if i < current:
				draw_circle(c, DOT * 0.8, Color("6bd66b"))
			elif i == current:
				draw_circle(c, DOT, Color("ffb13b"))
			else:
				draw_circle(c, DOT * 0.7, Color(1, 1, 1, 0.35))
