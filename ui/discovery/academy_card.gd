class_name AcademyCard
extends Control
## Owner #132 (W1), stage 3, with #133 and #134: a door of the Discovery Academy whose games are not built yet shows this
## calm card while the child stands at it: Professor Hoot and the door's picture on its colour, a speaker and a cross,
## no words to read; its line is spoken ("The History Museum! Hoot is still building it. Come back soon!"). Never a list
## of lessons. Walking away (the director) or the cross puts it away; nothing is lost.

signal dismissed

const SOON_LINE := "%s! Hoot is still building it. Come back soon!"

var card := PanelContainer.new()
var door := ""
var picture: AcademyIcons.Picture
var cross := Button.new()
var _row := HBoxContainer.new()


func _init() -> void:
	name = "AcademyCard"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	card.name = "Card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.96), 22, 14))
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.offset_left = -230
	card.offset_top = HootCard.SPOT.y - 20
	add_child(card)
	_row.add_theme_constant_override("separation", 18)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_row)
	var owl := SchoolUi.teacher(120.0)
	owl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(owl)
	picture = AcademyIcons.Picture.new("", 150.0)
	picture.name = "Picture"
	_row.add_child(picture)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 12)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(side)
	cross.name = "Close"
	cross.custom_minimum_size = Vector2(64, 64)
	cross.add_theme_stylebox_override("normal", UiKit.box(Color(0.2, 0.24, 0.36), 32, 8))
	cross.add_theme_stylebox_override("hover", UiKit.box(Color(0.26, 0.3, 0.44), 32, 8))
	cross.add_theme_stylebox_override("pressed", UiKit.box(Color(0.16, 0.18, 0.28), 32, 8))
	var x := HootCard.Cross.new()
	x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cross.add_child(x)
	cross.pressed.connect(func() -> void:
		hide_card()
		dismissed.emit())
	side.add_child(cross)
	side.add_child(ReadAloud.button(line, 64.0))


## The card for door `id` (AcademyPlaza.SPOTS): its picture on its colour; its line is spoken.
func show_door(id: String) -> void:
	door = id
	var s: Dictionary = AcademyPlaza.SPOTS[id]
	picture.picture = str(s.picture)
	picture.back = AcademyBuildings._colour(str(s.subject))
	picture.queue_redraw()
	visible = true
	UiMotion.pop_in(card)
	PlayVoice.say(line())


## The spoken line of the door showing.
func line() -> String:
	if door == "":
		return ""
	return SOON_LINE % str(AcademyPlaza.SPOTS[door].name)


func hide_card() -> void:
	visible = false


func blockers() -> Array[Control]:
	return [card] as Array[Control]
