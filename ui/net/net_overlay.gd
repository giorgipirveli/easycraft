class_name NetOverlay
extends Control
## Plain words for network problems (M4 Wave 1 A, spec §17.0), over everything in the world scene.
## Session.net_notice brings them (NetWords): while a guest rejoins, "The internet went away. Trying
## again…" covers the game (dots go round, taps are eaten); news such as "You're back!" or a host
## whose server went away shows as a short note at the top that never takes a tap; goodbye() puts up
## the words the sandbox leaves for the menu with. Works while the world is stopped.

const REJOINING := &"rejoining"
const NOTE := &"note"
const GOODBYE := &"goodbye"
const HIDDEN := &""
const GOODBYE_SECONDS := 3.0

## How long a note stays.
var note_seconds := 3.5

var _mode: StringName = HIDDEN
var _shade := ColorRect.new()
var _center := CenterContainer.new()
var _words := Label.new()
var _dots := Label.new()
var _note := Label.new()
var _note_until := 0.0
var _spin := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_shade.color = Color(0.05, 0.08, 0.18, 0.78)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 24)
	_center.add_child(column)
	_style(_words, 44)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.custom_minimum_size = Vector2(900, 0)
	column.add_child(_words)
	_style(_dots, 48)
	column.add_child(_dots)
	_style(_note, 30)
	_note.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_note.position.y = 24
	_note.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_note)
	Session.net_notice.connect(_on_notice)
	if Session.a_rejoining():
		_show(REJOINING, NetWords.text(NetWords.LINK_LOST))


func mode() -> StringName:
	return _mode


func words() -> String:
	return _note.text if _mode == NOTE else _words.text


## The words the game leaves for the menu with (the sandbox quits GOODBYE_SECONDS later).
func goodbye(text: String) -> void:
	_show(GOODBYE, text)


func _on_notice(code: StringName, text: String) -> void:
	if _mode == GOODBYE:
		return
	if code == NetWords.LINK_LOST:
		_show(REJOINING, text)
	else:
		_show(NOTE, text)


func _show(mode_name: StringName, text: String) -> void:
	_mode = mode_name
	var cover := mode_name != NOTE
	_shade.visible = cover
	_center.visible = cover
	_note.visible = not cover
	_dots.visible = mode_name == REJOINING
	if cover:
		_words.text = text
	else:
		_note.text = text
		_note_until = Time.get_ticks_msec() / 1000.0 + note_seconds
	mouse_filter = Control.MOUSE_FILTER_STOP if cover else Control.MOUSE_FILTER_IGNORE
	visible = true


func _process(delta: float) -> void:
	if _mode == REJOINING:
		_spin += delta
		var lit := int(_spin * 3.0) % 3
		_dots.text = ["●  ○  ○", "○  ●  ○", "○  ○  ●"][lit]
	elif _mode == NOTE and Time.get_ticks_msec() / 1000.0 >= _note_until:
		_mode = HIDDEN
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE


static func _style(l: Label, font_size: int) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.2))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
