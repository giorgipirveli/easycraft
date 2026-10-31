class_name AnimalBookPage
extends VBoxContainer
## The Animal Book's page in the book (M3 Task 21b; research C1): a tile for every animal kind of the game
## (AnimalBookRules: the species table, so new animals come by themselves) — its picture and name once met, a
## silhouette and "???" until then — with a treat mark when fed and a heart when it became a pet. A tap opens its
## card: the big picture, the name, a fun fact, the marks, and for a kind not met yet a clue where it lives.

const COLUMNS := 8
const TILE := Vector2(122, 120)
const ROWS_SHOWN := 3
const MARK := 24.0

## The book's data (tests use their own).
var data: Callable = func() -> WonderData: return Profile.data.wonder

var count_label := BookKit.label("", 22, BookKit.SOFT_INK)
var back_button := BookKit.button("BACK", Vector2(200, 72))
var detail_name := BookKit.label("", 34, BookKit.TITLE_INK)
var detail_fact := BookKit.label("", 26)
var detail_marks := BookKit.label("", 24, BookKit.SOFT_INK)
var detail_portrait := AnimalPortrait.new(&"", 220)
var shown_species: StringName = &""   # the card's kind (&"": the grid shows)

var _grid := GridContainer.new()
var _scroll := ScrollContainer.new()
var _detail := VBoxContainer.new()
var _tiles: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	var title := BookKit.label("Animal Book", 34, BookKit.TITLE_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 60.0))   # M3 Task 21a's speaker
	count_label.custom_minimum_size.x = 260
	head.add_child(count_label)
	add_child(head)
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(TILE.x * COLUMNS + 6 * (COLUMNS - 1) + 14, TILE.y * ROWS_SHOWN + 6 * (ROWS_SHOWN - 1))
	_scroll.add_child(_grid)
	add_child(_scroll)
	for sp in AnimalBookRules.species():
		var b := _tile(sp)
		_grid.add_child(b)
		_tiles.append(b)
	_build_detail()
	refresh()


func _tile(sp: StringName) -> Button:
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.add_theme_stylebox_override("normal", BookKit.card_box(BookKit.CARD, 4))
	b.add_theme_stylebox_override("hover", BookKit.card_box(BookKit.CARD, 4))
	b.add_theme_stylebox_override("pressed", BookKit.card_box(Color(1, 1, 1, 0.55), 4))
	b.set_meta(&"species", sp)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var pic := AnimalPortrait.new(sp, 70)
	pic.name = "Picture"
	v.add_child(pic)
	var words := BookKit.label("", 16)
	words.name = "Words"
	words.clip_text = true
	words.custom_minimum_size.x = TILE.x - 8
	v.add_child(words)
	var marks := HBoxContainer.new()
	marks.name = "Marks"
	marks.alignment = BoxContainer.ALIGNMENT_CENTER
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fed := ProgressPicture.new(&"treat", MARK)
	fed.name = "Fed"
	marks.add_child(fed)
	var friend := ProgressPicture.new(&"heart", MARK)
	friend.name = "Friend"
	friend.visible = AnimalBookRules.can_befriend(sp)
	marks.add_child(friend)
	v.add_child(marks)
	b.pressed.connect(open_card.bind(sp))
	return b


func _build_detail() -> void:
	_detail.visible = false
	_detail.alignment = BoxContainer.ALIGNMENT_CENTER
	_detail.add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(detail_portrait)
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 12)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_fact.custom_minimum_size.x = 560
	detail_marks.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(detail_name)
	words.add_child(detail_fact)
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
	count_label.text = AnimalBookRules.count_words(d)
	for b in _tiles:
		var sp: StringName = b.get_meta(&"species")
		var marks := AnimalBookRules.flags(d, sp)
		var met := marks & WonderData.MET != 0
		var v := b.get_child(0)
		(v.get_node("Picture") as AnimalPortrait).dim = not met
		(v.get_node("Words") as Label).text = AnimalBookRules.name_of(sp) if met else "???"
		(v.get_node("Marks/Fed") as ProgressPicture).dim = marks & WonderData.FED == 0
		(v.get_node("Marks/Friend") as ProgressPicture).dim = marks & WonderData.FRIEND == 0
	if shown_species != &"":
		open_card(shown_species)


## The card of kind `sp`.
func open_card(sp: StringName) -> void:
	shown_species = sp
	var d: WonderData = data.call()
	var marks := AnimalBookRules.flags(d, sp)
	var met := marks & WonderData.MET != 0
	detail_portrait.species = sp
	detail_portrait.dim = not met
	detail_name.text = AnimalBookRules.name_of(sp) if met else "???"
	detail_fact.text = AnimalBookRules.fact_of(sp) if met else AnimalBookRules.home_words(sp)
	var parts: Array[String] = [tr("Met ✓") if met else tr("Not met yet")]   # each translated before they join
	if met:
		parts.append(tr("Fed ✓") if marks & WonderData.FED else tr("Not fed yet"))
		if AnimalBookRules.can_befriend(sp):
			parts.append(tr("Your pet ✓") if marks & WonderData.FRIEND else tr("Can be a pet"))
	detail_marks.text = "   ".join(PackedStringArray(parts))
	_scroll.visible = false
	_detail.visible = true


func close_card() -> void:
	shown_species = &""
	_detail.visible = false
	_scroll.visible = true


## The tiles in the species table's order (tests).
func tiles() -> Array[Button]:
	return _tiles


func tile_words(i: int) -> String:
	return (_tiles[i].get_child(0).get_node("Words") as Label).text


func tile_dim(i: int) -> bool:
	return (_tiles[i].get_child(0).get_node("Picture") as AnimalPortrait).dim
