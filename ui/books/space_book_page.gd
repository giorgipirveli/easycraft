class_name SpaceBookPage
extends VBoxContainer
## The Space Book's page in the book (owner #72, #74; spec §21b.2): a tile for every body of the Star Map (StarMap, so
## new planets come by themselves), in the map's order: its picture and name once the child opened its card in space,
## a shadow and "???" until then, a flag once they landed there. A tap opens its card: the big picture, the name, its
## three real facts (read aloud with the page's speaker), or for one not seen yet where to find it.

const COLUMNS := 8
const TILE := Vector2(122, 120)
const ROWS_SHOWN := 3
const MARK := 24.0
const SILHOUETTE := Color(0.25, 0.24, 0.3)   # a body not seen yet: its shape only

## The book's data (tests use their own).
var data: Callable = func() -> WonderData: return Profile.data.wonder

var count_label := BookKit.label("", 22, BookKit.SOFT_INK)
var back_button := BookKit.button("BACK", Vector2(200, 72))
var detail_name := BookKit.label("", 34, BookKit.TITLE_INK)
var detail_facts := BookKit.label("", 24)
var detail_marks := BookKit.label("", 22, BookKit.SOFT_INK)
var detail_picture: StarBody
var shown: StringName = &""   # the card's body (&"": the grid shows)

var _grid := GridContainer.new()
var _scroll := ScrollContainer.new()
var _detail := VBoxContainer.new()
var _tiles: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	var title := BookKit.label("Space Book", 34, BookKit.TITLE_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 60.0))
	count_label.custom_minimum_size.x = 300
	head.add_child(count_label)
	add_child(head)
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(TILE.x * COLUMNS + 6 * (COLUMNS - 1) + 14, TILE.y * ROWS_SHOWN + 6 * (ROWS_SHOWN - 1))
	_scroll.add_child(_grid)
	add_child(_scroll)
	for d in StarMap.bodies():
		var b := _tile(d)
		_grid.add_child(b)
		_tiles.append(b)
	_build_detail()
	refresh()


## A small picture of body `d` (its colours, its rings), without its name.
static func picture(d: Dictionary, radius: float) -> StarBody:
	var look := d.duplicate()
	look.name = ""
	look.size = minf(float(d.size), radius)
	var p := StarBody.new(look)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return p


func _tile(d: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.add_theme_stylebox_override("normal", BookKit.card_box(Color(0.12, 0.14, 0.3, 0.92), 4))
	b.add_theme_stylebox_override("hover", BookKit.card_box(Color(0.12, 0.14, 0.3, 0.92), 4))
	b.add_theme_stylebox_override("pressed", BookKit.card_box(Color(0.2, 0.22, 0.42), 4))
	b.set_meta(&"body", d.id)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var pic := picture(d, 26.0)
	pic.name = "Picture"
	pic.custom_minimum_size = Vector2(TILE.x - 10, 70)
	v.add_child(pic)
	var words := BookKit.label("", 15)
	words.name = "Words"
	words.clip_text = true
	words.custom_minimum_size.x = TILE.x - 8
	v.add_child(words)
	var flag := ProgressPicture.new(&"flag", MARK)   # landed here: a flag in the tile's corner
	flag.name = "Flag"
	flag.position = Vector2(TILE.x - MARK - 6, 6)
	b.add_child(flag)
	b.pressed.connect(open_card.bind(d.id))
	return b


func _build_detail() -> void:
	_detail.visible = false
	_detail.alignment = BoxContainer.ALIGNMENT_CENTER
	_detail.add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	detail_picture = picture({"id": &"card", "name": "", "kind": "planet", "size": 70.0, "color": Color.WHITE,
		"color2": Color.WHITE, "ring": true}, 70.0)
	row.add_child(detail_picture)
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 12)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_facts.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_facts.custom_minimum_size.x = 620
	detail_marks.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(detail_name)
	words.add_child(detail_facts)
	words.add_child(detail_marks)
	row.add_child(words)
	_detail.add_child(row)
	back_button.pressed.connect(close_card)
	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	back_row.add_child(back_button)
	_detail.add_child(back_row)
	_detail.custom_minimum_size.y = _scroll.custom_minimum_size.y
	add_child(_detail)


## Fills every tile from the book (call when the page shows).
func refresh() -> void:
	var d: WonderData = data.call()
	count_label.text = SpaceBookRules.count_words(d)
	for b in _tiles:
		var id: StringName = b.get_meta(&"body")
		var marks := SpaceBookRules.marks(d, id)
		var seen := marks & WonderData.SEEN != 0
		var v := b.get_child(0)
		var pic := v.get_node("Picture") as StarBody
		pic.set_state(StarMap.LOOK if seen else StarMap.LOCKED)
		pic.modulate = Color.WHITE if seen else SILHOUETTE
		(v.get_node("Words") as Label).text = str(StarMap.body(id).name) if seen else "???"
		(b.get_node("Flag") as ProgressPicture).visible = marks & WonderData.LANDED != 0
	if shown != &"":
		open_card(shown)


## The card of body `id`.
func open_card(id: StringName) -> void:
	shown = id
	var b := StarMap.body(id)
	var marks := SpaceBookRules.marks(data.call(), id)
	var seen := marks & WonderData.SEEN != 0
	var look := b.duplicate()
	look.name = ""
	look.size = 70.0
	detail_picture.data = look
	detail_picture.radius = 70.0
	detail_picture.set_state(StarMap.LOOK if seen else StarMap.LOCKED)
	detail_picture.modulate = Color.WHITE if seen else SILHOUETTE
	detail_name.text = str(b.name) if seen else "???"
	if seen:
		var lines: Array[String] = []
		for f: String in b.facts:
			lines.append("•  " + f)
		detail_facts.text = "\n".join(lines)
	else:
		detail_facts.text = SpaceBookRules.clue(id)
	detail_marks.text = "" if not seen else (tr("You landed here ✓") if marks & WonderData.LANDED else tr("Seen ✓"))
	_scroll.visible = false
	_detail.visible = true


func close_card() -> void:
	shown = &""
	_detail.visible = false
	_scroll.visible = true


## The tiles in the Star Map's order (tests).
func tiles() -> Array[Button]:
	return _tiles


func tile_words(i: int) -> String:
	return (_tiles[i].get_child(0).get_node("Words") as Label).text


func tile_dim(i: int) -> bool:
	return (_tiles[i].get_child(0).get_node("Picture") as StarBody).state == StarMap.LOCKED


func tile_flag(i: int) -> bool:
	return (_tiles[i].get_node("Flag") as ProgressPicture).visible
