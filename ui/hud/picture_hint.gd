class_name PictureHint
extends PanelContainer
## A first-time picture hint (M2 Task 3, the lead's child-friendly feedback): a big icon and a short
## line, centred below the toasts for a few seconds, so a child who can't read well yet still gets the
## picture. It never takes a tap.

const SECONDS := 5.0
const FADE_SECONDS := 0.5
const TOP := 176.0   # below the toast line (Hud toasts sit at 96)

var icon := TextureRect.new()
var label := Label.new()

var _box := StyleBoxFlat.new()
var _tween: Tween


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_box.bg_color = Color(0.08, 0.1, 0.17, 0.92)
	_box.set_border_width_all(4)
	_box.set_corner_radius_all(18)
	_box.set_content_margin_all(16)
	_box.content_margin_right = 26
	add_theme_stylebox_override("panel", _box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TextSize.mark(label, 26)   # M5 Task 1: TEXT SIZE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	row.add_child(label)
	add_child(row)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_top = TOP
	grow_horizontal = Control.GROW_DIRECTION_BOTH


## Shows `texture` tinted `tint` (the frame too) next to `text`, then fades away.
func show_hint(texture: Texture2D, tint: Color, text: String, seconds: float = SECONDS) -> void:
	icon.texture = texture
	icon.modulate = tint
	_box.border_color = tint
	label.text = text
	ReadAloud.auto(text)   # M3 Task 21a: "Read to me"
	visible = true
	modulate.a = 1.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(seconds)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(hide)
