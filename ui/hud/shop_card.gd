class_name ShopCard
extends Button
## One picture card in Tilly's shop (M2 Task 7): the thing's icon, a coin with its short price, a
## count badge ("×4" blocks per purchase, or how many you have to sell), a have/need bar under a
## price the player can't afford yet ("3 / 20", the lead's note), and a green check on a tool the
## player already has. Selected cards have a gold border (one ButtonGroup per panel).

const SIZE := Vector2(150, 164)
const ICON_SIZE := 70.0
const CHECK := Color("5ee07a")
## Stand-in tints for tier tools whose own icon is not drawn yet (their line's wood icon, tinted).
const TIER_TINTS: Array[Color] = [Color.WHITE, Color("a9a9a9"), Color("e8ecf5"), Color("7fe6ff"), Color("c58cff")]

var id := 0
var owned := false

var _icon := TextureRect.new()
var _price := Label.new()
var _badge := Label.new()
var _need_box := VBoxContainer.new()
var _need_bar := ProgressBar.new()
var _need_label := Label.new()

static var _potion_icons := {}


func _init(item_id: int = 0) -> void:
	id = item_id
	custom_minimum_size = SIZE
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_stylebox_override("normal", _box(Color(0.14, 0.18, 0.3, 0.95), Color(0.3, 0.36, 0.52)))
	add_theme_stylebox_override("hover", _box(Color(0.18, 0.23, 0.38, 0.97), Color(0.4, 0.46, 0.64)))
	add_theme_stylebox_override("pressed", _box(Color(0.24, 0.22, 0.12, 0.98), CoinIcon.GOLD, 5))
	add_theme_stylebox_override("hover_pressed", _box(Color(0.24, 0.22, 0.12, 0.98), CoinIcon.GOLD, 5))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 8)
	_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.texture = icon_for(item_id)
	_icon.self_modulate = tint_for(item_id)
	column.add_child(_icon)
	var price_row := HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_row.add_child(CoinIcon.new(24))
	_style(_price, 24, Color.WHITE)
	price_row.add_child(_price)
	column.add_child(price_row)
	_need_bar.custom_minimum_size = Vector2(0, 9)
	_need_bar.show_percentage = false
	_need_bar.max_value = 1.0
	_need_bar.step = 0.0
	_need_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = CoinIcon.GOLD
	fill.set_corner_radius_all(4)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.45)
	back.set_corner_radius_all(4)
	_need_bar.add_theme_stylebox_override("fill", fill)
	_need_bar.add_theme_stylebox_override("background", back)
	_need_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_need_box.add_theme_constant_override("separation", 0)
	_need_box.add_child(_need_bar)
	_style(_need_label, 15, Color("ffe9a8"))
	_need_box.add_child(_need_label)
	_need_box.visible = false
	column.add_child(_need_box)
	_style(_badge, 20, Color.WHITE)
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_badge)
	_badge.position = Vector2(SIZE.x - 66, 4)
	_badge.size = Vector2(60, 26)


## price: gold per purchase (or per block sold); gold: what the player has (the bar shows only when
## it isn't enough and `show_need`); badge: "×4" or "" ; have_it: a tool already owned.
func show_offer(price: int, gold: int, badge: String, have_it: bool, show_need: bool) -> void:
	owned = have_it
	_price.text = GoldFormat.short(price)
	_badge.text = badge
	_badge.visible = badge != ""
	_need_box.visible = show_need and gold < price and not have_it
	if _need_box.visible:
		_need_bar.value = clampf(float(gold) / maxf(float(price), 1.0), 0.0, 1.0)
		_need_label.text = GoldFormat.have_need(gold, price)
	modulate = Color(1, 1, 1, 0.6) if have_it else Color.WHITE
	queue_redraw()


func price_text() -> String:
	return _price.text


func badge_text() -> String:
	return _badge.text if _badge.visible else ""


func need_visible() -> bool:
	return _need_box.visible


func need_text() -> String:
	return _need_label.text


func need_ratio() -> float:
	return _need_bar.value


func icon_texture() -> Texture2D:
	return _icon.texture


## A green check in the top-left corner on a tool the player already has.
func _draw() -> void:
	if owned:
		draw_circle(Vector2(22, 22), 15, Color(0, 0, 0, 0.55))
		draw_polyline(PackedVector2Array([Vector2(14, 22), Vector2(20, 29), Vector2(31, 14)]), CHECK, 4.0, true)


## The thing's icon: its own, a potion bottle drawn here, or its tool line's wood icon (tinted).
static func icon_for(item_id: int) -> Texture2D:
	var tex := BlockIcons.icon(item_id)
	if tex:
		return tex
	if ItemIds.POTIONS.has(item_id):
		return potion_icon(item_id)
	return BlockIcons.icon(ShopRules.base_tool(item_id))


static func tint_for(item_id: int) -> Color:
	var tier := ShopRules.tier_of(item_id)
	return TIER_TINTS[tier] if tier > 0 and BlockIcons.icon(item_id) == null else Color.WHITE


## A 16 x 16 pixel-art bottle in the potion's colour (Moon Jump green, Invisibility blue, Speed
## yellow), built once each; Task 6's own potion icons win when they exist.
static func potion_icon(item_id: int) -> Texture2D:
	if _potion_icons.has(item_id):
		return _potion_icons[item_id]
	var liquid: Color = {ItemIds.POTION_JUMP: Color("5ee07a"), ItemIds.POTION_INVIS: Color("8fd3ff"),
		ItemIds.POTION_SPEED: Color("ffd23f")}.get(item_id, Color("ff7eb6"))
	var rows := [
		"......cccc......",
		"......cccc......",
		".......gg.......",
		".......gg.......",
		"......gggg......",
		".....gLLLLg.....",
		"....gLLLLLLg....",
		"...gLLwLLLLLg...",
		"...gLwLLLLLLg...",
		"...gLLLLLLLLg...",
		"...gLLLLLLLLg...",
		"...gLLLLLLLLg...",
		"....gLLLLLLg....",
		".....gggggg.....",
		"................",
		"................",
	]
	var colors := {"c": Color("8a5a33"), "g": Color("d9f2ff"), "L": liquid, "w": Color.WHITE}
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var ch: String = rows[y][x]
			img.set_pixel(x, y, colors.get(ch, Color(0, 0, 0, 0)))
	var tex := ImageTexture.create_from_image(img)
	_potion_icons[item_id] = tex
	return tex


static func _box(bg: Color, border: Color, width: int = 2) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(14)
	b.set_content_margin_all(6)
	return b


static func _style(l: Label, font_size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
