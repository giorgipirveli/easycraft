class_name TradeSlot
extends Button
## One square of the trade window (owner #37, spec §14.23): a thing's picture with its count in the corner, or an
## empty square. Icon first (ShopCard's icons), no words to read; big enough for a child's finger.

const SIZE := Vector2(80, 80)
const EMPTY := Color(0.12, 0.14, 0.22, 0.9)
const FULL := Color(0.18, 0.23, 0.38, 0.97)

var id := -1
var count := 0

var _icon := TextureRect.new()
var _count := Label.new()


func _init() -> void:
	custom_minimum_size = SIZE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 10)
	_count.add_theme_font_size_override("font_size", 22)
	_count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_count.add_theme_constant_override("outline_size", 6)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count)
	_count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 4)
	show_thing(-1, 0)


## Shows `n` of `thing` (-1: an empty square).
func show_thing(thing: int, n: int) -> void:
	id = thing
	count = n
	var has := thing >= 0 and n > 0
	_icon.texture = ShopCard.icon_for(thing) if has else null
	_icon.self_modulate = ShopCard.tint_for(thing) if has else Color.WHITE
	_count.text = GoldFormat.short(n) if has and n > 1 else ""
	disabled = not has
	add_theme_stylebox_override("normal", UiKit.box(FULL if has else EMPTY, 12, 4))
	add_theme_stylebox_override("hover", UiKit.box(FULL.lightened(0.1) if has else EMPTY, 12, 4))
	add_theme_stylebox_override("pressed", UiKit.box(FULL.lightened(0.2), 12, 4))
	add_theme_stylebox_override("disabled", UiKit.box(FULL if has else EMPTY, 12, 4))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
