class_name AvatarTile
extends Button
## One big square in the avatar editor (M3 Task 9): the item's picture (AvatarIcon), its short name,
## a rim in its rarity colour (§13.2), a gold coin and price or a padlock when it is locked, a tick
## when it is worn. Also used for the editor's tabs (a picture over a word).

var slot: StringName = &""
var item: StringName = &""
var caption := ""
var selected := false:
	set(value):
		selected = value
		queue_redraw()
var locked := false:
	set(value):
		locked = value
		queue_redraw()
var price := 0                         # shown on a locked gold item
var rarity_color := AvatarCatalog.RARITY_COLORS[AvatarCatalog.COMMON]
## An emote tile's figure can dance while the editor shows it (the wheel slots do).
var animate_emote := false
## Owner 35: on the child's wish list (a small heart instead of the padlock).
var wished := false:
	set(value):
		wished = value
		queue_redraw()
## Owner 48: the child's look, for pictures drawn in its colours (clothes, BOY / GIRL / JUST ME, presets).
var look: AvatarLook
## Owner 48: the caption's font size under a picture (big choice tiles use a bigger word).
var caption_size := 19

var _box := StyleBoxFlat.new()
var _t := 0.0


func _init(tile_slot: StringName = &"", tile_item: StringName = &"", size_px: Vector2 = Vector2(128, 128)) -> void:
	slot = tile_slot
	item = tile_item
	custom_minimum_size = size_px
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_contents = true
	pressed.connect(Audio.play.bind(&"ui_click"))


func _process(delta: float) -> void:
	if animate_emote and is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	_box.bg_color = Color(0.2, 0.25, 0.38, 0.95) if not selected else Color(0.3, 0.36, 0.52, 1.0)
	_box.border_color = Color(1, 0.85, 0.2) if selected else rarity_color
	_box.set_border_width_all(6 if selected else 3)
	_box.set_corner_radius_all(16)
	draw_style_box(_box, r)
	var font := get_theme_default_font()
	var wide := size.x > size.y * 1.5    # a tab: the picture beside its word
	var pic: Rect2
	var text_at := Vector2(0, size.y - 8)
	var text_w := size.x
	var font_size := caption_size
	if wide:
		pic = Rect2(Vector2(6, 10), Vector2(size.y - 20, size.y - 20))
		text_at = Vector2(pic.end.x, size.y * 0.5 + 7)
		text_w = size.x - pic.end.x - 2
		font_size = 18
	elif caption != "":
		var side := minf(size.x * 0.76, size.y - 15.0 - caption_size)
		pic = Rect2(Vector2((size.x - side) * 0.5, 6), Vector2(side, side))
	else:
		pic = r.grow(-size.x * 0.1)
	if slot == AvatarCatalog.EMOTE and animate_emote:
		AvatarIcon.figure(self, pic, AvatarLook.new().resolve(), EmotePoses.sample(item, _t))
	elif slot != &"":
		AvatarIcon.draw_item(self, pic, slot, item, look)
	if caption != "":
		var shown := atr(caption)   # M3 Task 21a
		while font_size > 13 and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > text_w - 8:
			font_size -= 1   # long names shrink to fit
		draw_string_outline(font, text_at, shown, HORIZONTAL_ALIGNMENT_CENTER, text_w, font_size, 5, Color(0, 0, 0, 0.8))
		draw_string(font, text_at, shown, HORIZONTAL_ALIGNMENT_CENTER, text_w, font_size, Color.WHITE)
	if locked:
		draw_rect(r.grow(-3), Color(0, 0, 0, 0.35))
		if price > 0:
			_coin_tag(font)
		elif wished:
			_heart(Vector2(size.x - 24, 24), 12.0)
		else:
			_padlock(Vector2(size.x - 24, 24), 13.0)
	if selected:
		_tick(Vector2(22, 22))
	_rarity_pips()   # M5 Task 1: never colour alone


## A gold coin with the price, top right.
func _coin_tag(font: Font) -> void:
	var text := str(price)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	var tag := Rect2(Vector2(size.x - w - 40, 4), Vector2(w + 36, 30))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.7)
	bg.set_corner_radius_all(14)
	draw_style_box(bg, tag)
	draw_circle(tag.position + Vector2(15, 15), 10.0, Color("d99a00"))
	draw_circle(tag.position + Vector2(15, 15), 7.5, Color("ffd23f"))
	draw_string(font, tag.position + Vector2(29, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)


func _padlock(c: Vector2, r: float) -> void:
	draw_arc(c + Vector2(0, -r * 0.35), r * 0.6, PI, TAU, 16, Color.WHITE, 4.0, true)
	draw_rect(Rect2(c + Vector2(-r, -r * 0.3), Vector2(r * 2, r * 1.5)), Color.WHITE)
	draw_circle(c + Vector2(0, r * 0.35), r * 0.25, Color(0.2, 0.2, 0.25))


func _heart(c: Vector2, r: float) -> void:
	var red := Color("ff6fa8")
	draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, red)
	draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, red)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, 0), c + Vector2(r * 1.02, 0), c + Vector2(0, r * 1.1)]), red)


func _tick(c: Vector2) -> void:
	draw_circle(c, 16.0, Color("2fae4e"))
	draw_polyline(PackedVector2Array([c + Vector2(-8, 0), c + Vector2(-2, 7), c + Vector2(9, -7)]), Color.WHITE, 4.0, true)


# --- M5 Task 1: never colour alone ---

## The rarity counted in pips as well as the rim (common 1 ... legendary 5, like the tier items' icons); 0 for a tile
## without a rarity colour (a tab).
func rarity_pips() -> int:
	var rarity: Variant = AvatarCatalog.RARITY_COLORS.find_key(rarity_color)
	return [AvatarCatalog.COMMON, AvatarCatalog.UNCOMMON, AvatarCatalog.RARE, AvatarCatalog.EPIC,
		AvatarCatalog.LEGENDARY].find(rarity) + 1 if rarity != null else 0


## White pips with a dark edge along the bottom-left corner, above the caption (shown while worn too, when the rim
## is gold).
func _rarity_pips() -> void:
	var n := rarity_pips()
	if n <= 0 or slot == &"" or size.x > size.y * 1.5:
		return
	var y := size.y - (caption_size + 22.0 if caption != "" else 14.0)
	for i in n:
		var c := Vector2(14.0 + i * 11.0, y)
		draw_circle(c, 5.0, Color(0.1, 0.12, 0.18, 0.9))
		draw_circle(c, 3.5, Color.WHITE)
