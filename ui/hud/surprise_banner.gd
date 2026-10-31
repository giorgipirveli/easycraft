class_name SurpriseBanner
extends PanelContainer
## A short golden banner for surprises (M2 Task 16, spec §12.16): "You found a hidden room!" with the
## secret's picture. Banners wait their turn, so a find and its treasure both show. Top centre, under the
## toasts; it never takes a tap.

const SHOW_TIME := 2.8
const FADE := 0.3
const TOP := 176.0

var label := Label.new()
var picture := TextureRect.new()
var _queue: Array = []            # [text, picture id]
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.2, 0.12, 0.02, 0.92)
	box.border_color = Color("ffd23f")
	box.set_border_width_all(4)
	box.set_corner_radius_all(20)
	box.set_content_margin_all(12)
	box.content_margin_left = 20
	box.content_margin_right = 26
	add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	picture.custom_minimum_size = Vector2(56, 56)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	TextSize.mark(label, 32)   # M5 Task 1: TEXT SIZE
	label.add_theme_color_override("font_color", Color("fff3c4"))
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0, 0.9))
	label.add_theme_constant_override("outline_size", 8)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_top = TOP
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	visible = false


## Shows a banner now, or after the ones already waiting. picture: a Riddles picture id, or -1.
func show_banner(text: String, picture_id: int = -1) -> void:
	_queue.append([text, picture_id])
	if not visible:
		_next()


func showing() -> String:
	return label.text if visible else ""


func waiting() -> int:
	return _queue.size()


func _next() -> void:
	if _queue.is_empty():
		visible = false
		return
	var e: Array = _queue.pop_front()
	label.text = e[0]
	ReadAloud.auto(e[0])   # M3 Task 21a: "Read to me"
	picture.visible = int(e[1]) >= 0
	if picture.visible:
		picture.texture = Pictures.texture(int(e[1]))
	visible = true
	modulate.a = 0.0
	offset_top = TOP - 24.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel()
	_tween.tween_property(self, "modulate:a", 1.0, FADE)
	_tween.tween_property(self, "offset_top", TOP, FADE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_interval(SHOW_TIME)
	_tween.chain().tween_property(self, "modulate:a", 0.0, FADE)
	_tween.chain().tween_callback(_next)
