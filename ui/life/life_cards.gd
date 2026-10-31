class_name LifeCards
extends RefCounted
## Owner #112, #113 (docs/design/life-skills.md §3, §7, §10): Life's shared pieces on top of SchoolUi: a big button
## with a picture over its word (the tracks, the areas, the units), the Passport's three stamps, the "name it" card in
## the authorities' own words with its source, and the Try it for real card (the child shows a grown-up).

const COLOUR := Color("2f7f6a")   # Life's own colour: a calm deep green
const PAPER := Color("fdf6e3")
const INK := Color("1f2a4a")
const STAMPS: Array[Array] = [[LifeData.DONE, "stamp_done", "DONE IT"], [LifeData.SELF, "stamp_self", "BY MYSELF"],
	[LifeData.EXPERT, "stamp_expert", "EXPERT"]]


## A big button whose picture sits over its words (the words stay the button's text: tests and the pad read it).
## `pic_share` is the picture's share of the height and `bottom` the room kept under the words (a unit card's stars:
## the emulator, 2026-10-17, showed them over two-line titles).
static func picture_button(text: String, icon: String, colour: Color, min_size: Vector2, font_size: int = 26,
		pic_share: float = 0.5, bottom: float = 8.0) -> Button:
	var b := SchoolUi.button(text, colour, min_size)
	b.add_theme_font_size_override("font_size", font_size)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var px := minf(min_size.y * pic_share, min_size.x * 0.55)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var own := b.get_theme_stylebox(state) if b.has_theme_stylebox_override(state) \
			else UiKit.theme().get_stylebox(state, "Button")
		var box := own.duplicate() as StyleBoxFlat
		if box:
			box.content_margin_top = px + 14.0
			box.content_margin_bottom = bottom
			b.add_theme_stylebox_override(state, box)
	var pic := LifeIcons.new(icon, px)
	pic.name = "Picture"
	pic.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	pic.offset_left = -px * 0.5
	pic.offset_right = px * 0.5
	pic.offset_top = 10.0
	pic.offset_bottom = 10.0 + px
	b.add_child(pic)
	return b


## The three stamps of a skill (an earned one in its ink, the others pale), with their words under them.
static func stamps_row(stamps: int, px: float = 72.0, words: bool = true) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Stamps"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s: Array in STAMPS:
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_theme_constant_override("separation", 2)
		var pic := LifeIcons.new(str(s[1]), px)
		pic.name = "Stamp_" + str(s[1])
		pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pic.modulate = Color.WHITE if stamps & int(s[0]) else Color(1, 1, 1, 0.22)
		col.add_child(pic)
		if words:
			var l := SchoolUi.words(str(s[2]), 15, px + 20.0)
			l.modulate = Color.WHITE if stamps & int(s[0]) else Color(1, 1, 1, 0.45)
			col.add_child(l)
		row.add_child(col)
	return row


## The "name it" card: the title, the steps numbered in the authorities' own words, the source in small letters.
static func name_it(card: Dictionary, width: float = 760.0) -> PanelContainer:
	var p := _paper("NameIt")
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	p.add_child(col)
	var title := SchoolUi.words(str(card.get("title", "")), 34, width)
	title.add_theme_color_override("font_color", INK)
	title.add_theme_constant_override("outline_size", 0)
	col.add_child(title)
	var i := 0
	for line: Variant in card.get("lines", []):
		i += 1
		var l := SchoolUi.words("%d.  %s" % [i, str(line)], 27, width)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.add_theme_color_override("font_color", INK)
		l.add_theme_constant_override("outline_size", 0)
		col.add_child(l)
	var src := SchoolUi.words("From: " + str(card.get("source", "")), 17, width)
	src.add_theme_color_override("font_color", Color(INK, 0.7))
	src.add_theme_constant_override("outline_size", 0)
	col.add_child(src)
	return p


## Try it for real: something to do with a grown-up at home, never in the game; the child shows the grown-up.
static func try_real(text: String, width: float = 560.0) -> PanelContainer:
	var p := _paper("TryReal")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	p.add_child(row)
	row.add_child(LifeIcons.new("grown_up", 80.0))
	var col := VBoxContainer.new()
	row.add_child(col)
	var title := SchoolUi.words("Try it for real", 26, width - 100.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_color_override("font_color", COLOUR.darkened(0.2))
	title.add_theme_constant_override("outline_size", 0)
	col.add_child(title)
	var l := SchoolUi.words(text + " Show your grown-up how!", 20, width - 100.0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	col.add_child(l)
	return p


static func _paper(card_name: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = card_name
	p.add_theme_stylebox_override("panel", UiKit.box(PAPER, 18, 18))
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return p
