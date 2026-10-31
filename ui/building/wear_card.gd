class_name WearCard
extends Control
## Build-and-Wear's choice (M3 Task 8; spec §14.5, §3a): the wand tapped a small build (at most 5 x 5 x 5), which
## glows. Four big picture buttons: WAKE UP (a buddy, as the wand always did), HAT, BACKPACK or WINGS (the build is
## copied onto the avatar, and stays in the world), and CANCEL. The sandbox does what was chosen (`chosen`).

## &"wake", a WearRules slot, or &"" for CANCEL.
signal chosen(choice: StringName)

const CHOICES: Array[StringName] = [&"wake", WearRules.HAT, WearRules.BACK, WearRules.WINGS]
const WORDS := {&"wake": "WAKE UP", WearRules.HAT: "HAT", WearRules.BACK: "BACKPACK", WearRules.WINGS: "WINGS"}
const COLORS := {&"wake": Color("2fae4e"), WearRules.HAT: Color("7b4bd6"), WearRules.BACK: Color("7b4bd6"),
	WearRules.WINGS: Color("7b4bd6")}

## BuildPicker.pick's answer for the tapped build, and the tapped cell (WAKE UP sparks it).
var picked := {}
var cell := Vector3i.ZERO
var box := PanelContainer.new()
var cancel_button := UiKit.big_button("CANCEL", UiKit.BLUE, Vector2(200, 80))

var _choices: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	box.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.96), 22, 18))
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	box.add_child(column)
	column.add_child(OnlineUi.words("Your build! What should it be?", 30, 760))
	var buttons: Array = []
	for c in CHOICES:
		var b := UiKit.big_button(WORDS[c], COLORS[c], Vector2(180, 150))
		b.name = String(c)
		b.icon = BuildToolIcons.choice_picture(c)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.expand_icon = false
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(choose.bind(c))
		_choices.append(b)
		buttons.append(b)
	column.add_child(OnlineUi.row(buttons, 14))
	cancel_button.name = "Cancel"
	cancel_button.pressed.connect(choose.bind(&""))
	column.add_child(OnlineUi.row([cancel_button]))


func show_for(p: Dictionary, c: Vector3i) -> void:
	picked = p
	cell = c
	visible = true


func choose(choice: StringName) -> void:
	visible = false
	chosen.emit(choice)


func choice_buttons() -> Array[Button]:
	return _choices


## The card's box, for the HUD's look area (its taps never build).
func blockers() -> Array[Control]:
	return [box]
