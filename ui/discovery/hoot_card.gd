class_name HootCard
extends Control
## Owner #132 (W1): Professor Hoot's invitation over the world (owner #133: no child has to read): Hoot, one big DISCOVER
## picture and a small cross, on a small card at the top of the screen, never over the middle and never over the thumbs'
## buttons. His line is spoken by itself as the card pops in (show_line). It waits quietly (no countdown) for `stays`
## seconds, then fades; the cross puts it away; nothing is lost either way. Only the card takes a touch (blockers): the
## rest of the screen is the world's.

signal discover_pressed
signal dismissed
## The card went (DISCOVER, the cross, or its quiet fade): Hoot flies off.
signal gone

## The card's place: the top middle, under the toast's line, between the HUD's left and right columns.
const SPOT := Vector2(-205, 176)
const FADE := 0.6

var card := PanelContainer.new()
var discover: DiscoverButton
var not_now := Button.new()
## Seconds it waits before fading.
var stays := DiscoveryRules.HOOT_STAYS
var _tween: Tween


## A cross drawn in code (no word: "not now").
class Cross:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var a := minf(size.x, size.y) * 0.22
		var w := maxf(3.0, a * 0.35)
		draw_line(c + Vector2(-a, -a), c + Vector2(a, a), Color.WHITE, w, true)
		draw_line(c + Vector2(-a, a), c + Vector2(a, -a), Color.WHITE, w, true)


func _init() -> void:
	name = "HootCard"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	card.name = "Card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.96), 22, 12))
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.offset_left = SPOT.x
	card.offset_top = SPOT.y
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var owl := SchoolUi.teacher(116.0)
	owl.name = "Hoot"
	owl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(owl)
	discover = DiscoverButton.make(Vector2(176, 132), 22)
	discover.pressed.connect(func() -> void:
		hide_card()
		discover_pressed.emit())
	row.add_child(discover)
	not_now.name = "NotNow"
	not_now.custom_minimum_size = Vector2(64, 64)
	not_now.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	not_now.add_theme_stylebox_override("normal", UiKit.box(Color(0.2, 0.24, 0.36), 32, 8))
	not_now.add_theme_stylebox_override("hover", UiKit.box(Color(0.26, 0.3, 0.44), 32, 8))
	not_now.add_theme_stylebox_override("pressed", UiKit.box(Color(0.16, 0.18, 0.28), 32, 8))
	var cross := Cross.new()
	cross.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	not_now.add_child(cross)
	not_now.pressed.connect(func() -> void:
		hide_card()
		dismissed.emit())
	row.add_child(not_now)


## Hoot pops in and says `line` (at once, by itself: PlayVoice, Play G0's voice: on for everyone, owner #133).
func show_line(line: String) -> void:
	visible = true
	modulate.a = 1.0
	UiMotion.pop_in(card)
	Audio.play(&"ui_click")
	PlayVoice.say(line)
	restart_wait()


## The quiet wait starts again (then the fade).
func restart_wait() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	if not is_inside_tree():
		return
	_tween = create_tween()
	_tween.tween_interval(stays)
	_tween.tween_property(self, "modulate:a", 0.0, FADE)
	_tween.tween_callback(hide_card)


func hide_card() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	var was := visible
	visible = false
	modulate.a = 1.0
	if was:
		gone.emit()


## What takes a touch while it shows (the HUD's look area leaves it alone): the card only.
func blockers() -> Array[Control]:
	return [card] as Array[Control]
