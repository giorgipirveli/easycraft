class_name BookKit
extends RefCounted
## The books' look (M3 Task 21b): brown ink on the Secret Book's paper, soft paper buttons, and one picture
## control for anything a page shows — a ProgressPictures name, an animal kind (AnimalPortrait) or a block or item
## id (its icon). Built in code like every menu; no textures or materials of its own.

const INK := Color("3b2a18")
const TITLE_INK := Color("5a3310")
const SOFT_INK := Color("7a5a3a")
const CARD := Color(1, 1, 1, 0.35)
const BUTTON := Color("d9b77e")
const BUTTON_DOWN := Color("c49a5c")
const PAGE_BUTTON := Vector2(90, 90)


static func label(text: String, font_size: int = 22, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func card_box(color: Color = CARD, margin: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(12)
	s.set_content_margin_all(margin)
	return s


## A paper button with brown words (big enough for small fingers).
static func button(text: String, min_size: Vector2, font_size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, INK)
	b.add_theme_color_override("font_disabled_color", Color(INK, 0.35))
	var normal := card_box(BUTTON, 6)
	normal.border_color = Color("7a4a24")
	normal.set_border_width_all(3)
	var down := normal.duplicate() as StyleBoxFlat
	down.bg_color = BUTTON_DOWN
	var off := normal.duplicate() as StyleBoxFlat
	off.bg_color = Color(BUTTON, 0.4)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("disabled", off)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


## A picture of `p` in a square of `px`: a ProgressPictures name, an animal kind or a block or item id.
static func picture(p: Variant, px: float) -> Control:
	if p is StringName and not ProgressPictures.knows(p) and AnimalRules.SPECIES.has(p):
		return AnimalPortrait.new(p, px)
	if p is int:
		var t := TextureRect.new()
		t.texture = BlockIcons.icon(p)
		t.custom_minimum_size = Vector2(px, px)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return t
	return ProgressPicture.new(StringName(str(p)), px)


## ◀ title ▶ with big page buttons (the Secret Book's own row, for the books' pages), and a speaker (M3 Task 21a's
## ReadAloud: hidden where there is no voice) after the title when one is given.
static func page_row(title: Label, prev: Button, next: Button, count: Label, speaker: Control = null) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	for b: Button in [prev, next]:
		b.custom_minimum_size = PAGE_BUTTON
		b.add_theme_font_size_override("font_size", 40)
		b.focus_mode = Control.FOCUS_NONE
	prev.text = "◀"
	next.text = "▶"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(prev)
	row.add_child(title)
	if speaker:
		row.add_child(speaker)
	row.add_child(count)
	row.add_child(next)
	return row
