class_name InstallCard
extends VBoxContainer
## M7 (owner 2026-09-28: "they should get shortcut on the app so next time they just click and open it", "it must be
## very user friendly"): the main menu's "Add EasyCraft to this device" card (InstallOffer decides when). Picture first:
## the buddy (the app's icon, so the child knows what to look for on the Home Screen), then the title with the speaker,
## one line, and ADD (green) beside NOT NOW (blue). On Safari the line says the page will show how (its picture guide).

signal add_pressed
signal not_now_pressed

const PICTURE := preload("res://icon.png")
const PICTURE_SIZE := Vector2(200, 200)
## The rounded tile round the buddy: his picture's own edge teal (its square corners stay inside the round ones).
const FRAME := Color("0b7178")
const TITLE := "Add EasyCraft to this device"
const LINE := "Next time, one tap opens it, full screen, like an app."
const GUIDE_LINE := "We'll show you how: it takes 3 taps."
const BUTTON := Vector2(300, 100)

## Safari: ADD opens the page's picture guide (WebGlue.install_state's needs_guide).
var guide := false


func _ready() -> void:
	add_theme_constant_override("separation", 18)
	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", UiKit.box(FRAME, 30, 10))
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.texture = PICTURE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = PICTURE_SIZE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(picture)
	add_child(frame)
	add_child(ReadAloud.with_speaker(UiKit.title(TITLE), self))
	var line := Label.new()
	line.name = "Line"
	line.text = GUIDE_LINE if guide else LINE
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = 760
	add_child(line)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	var add := UiKit.big_button("ADD", UiKit.GREEN, BUTTON)
	add.name = "AddButton"
	add.add_theme_font_size_override("font_size", 44)
	add.pressed.connect(add_pressed.emit)
	var later := UiKit.big_button("NOT NOW", UiKit.BLUE, BUTTON)
	later.name = "NotNowButton"
	later.pressed.connect(not_now_pressed.emit)
	row.add_child(add)
	row.add_child(later)
	add_child(row)
