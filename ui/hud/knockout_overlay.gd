class_name KnockoutOverlay
extends Control
## The knock-out fade (M2 Task 2, spec §12.3): the screen goes dark red with a big message ("You were
## knocked out!" in Survivor, a gentler one in Sandbox) and one picture tip under it (KnockoutRules.TIPS:
## an icon and a kind line about what helps) while the player is down; it fades away once they are
## back on their feet. Never takes a tap.

const FALL_TIME := 0.45
const DIM := 0.8
const GET_UP_TIME := 0.8
const ICON_SIZE := 72.0
## The words sit in the screen above its bottom 220 px (1280 × 720), where GET UP and SLEEP are.
const WORDS_LIFT := 220.0

var _shade := ColorRect.new()
var _label := Label.new()
var _tip_row := HBoxContainer.new()
var _tip_icon := TextureRect.new()
var _tip_label := Label.new()
var _column := VBoxContainer.new()
var _tween: Tween
var _down := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0
	_shade.color = Color(0.22, 0.02, 0.05, DIM)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -WORDS_LIFT   # M2 Task 17: GET UP (135 tall) waits under the words
	var column := _column
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 20)
	center.add_child(column)
	_style(_label, 64, Color(1.0, 0.93, 0.85), 14)
	column.add_child(_label)
	_tip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tip_row.add_theme_constant_override("separation", 18)
	column.add_child(_tip_row)
	_tip_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	_tip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tip_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp pixel art
	_tip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_row.add_child(_tip_icon)
	_style(_tip_label, 32, Color(1.0, 0.97, 0.8), 10)
	TextSize.mark(_tip_label, 32)   # M5 Task 1: TEXT SIZE (the message is 64 px already)
	_tip_row.add_child(_tip_label)


## Down: the message, and the tip ({icon: id, text: String}) when there is one.
func knock_out(text: String, tip: Dictionary = {}) -> void:
	_down = true
	_label.text = text
	_tip_label.text = str(tip.get("text", ""))
	_tip_icon.texture = BlockIcons.icon(int(tip.icon)) if tip.has("icon") else null
	_tip_row.visible = _tip_label.text != ""
	visible = true
	_fade(1.0, FALL_TIME)


func get_up() -> void:
	if not _down and not visible:
		return
	_down = false
	_fade(0.0, GET_UP_TIME)
	_tween.tween_callback(func() -> void: visible = false)


## Where the message and its tip are (canvas units).
func words_rect() -> Rect2:
	return _column.get_global_rect()


func is_down() -> bool:
	return _down


## M4 E: the words under the message while a friend can help (in the tip's place, no picture).
func set_help_text(text: String) -> void:
	if text == "" or _tip_label.text == text:
		return
	_tip_label.text = text
	_tip_icon.texture = null
	_tip_row.visible = true


func message() -> String:
	return _label.text


func tip_text() -> String:
	return _tip_label.text


func tip_icon() -> Texture2D:
	return _tip_icon.texture


func _fade(alpha: float, seconds: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, seconds)


static func _style(l: Label, font_size: int, color: Color, outline: int) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.3, 0.02, 0.05))
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
