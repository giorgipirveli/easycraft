class_name WondersPassportPage
extends VBoxContainer
## The Wonders Passport's page in the book (owner #78, spec §24): a stamp for every wonder of every tour (WonderFacts,
## so a new tour's wonders come by themselves), under its tour's heading (with how many of it are stamped), stamped
## once the child reached it (WonderData.stamp), a pale ring with a question mark until then, and its quiz stars. A tap opens its card: the big stamp, its name, where and when, whether
## it still stands, its real facts (read aloud with the page's speaker), and QUIZ once it is stamped (WonderQuizView:
## each question pays once, right the first time); a wonder not visited yet says how to get there.

const COLUMNS := 4
const TILE := Vector2(240, 176)
const ROWS_SHOWN := 2
const STAMP := 104.0

## The book's data (tests use their own).
var data: Callable = func() -> WonderData: return Profile.data.wonder

var count_label := BookKit.label("", 22, BookKit.SOFT_INK)
var back_button := BookKit.button("BACK", Vector2(200, 64))
var quiz_button := BookKit.button("QUIZ", Vector2(200, 64))
var detail_name := BookKit.label("", 32, BookKit.TITLE_INK)
var detail_where := BookKit.label("", 20, BookKit.SOFT_INK)
var detail_facts := BookKit.label("", 20)
var detail_stamp := WonderStamp.new(&"", false, 150.0)
var quiz := WonderQuizView.new()
var shown: StringName = &""   # the card's wonder (&"": the stamps show)

var _sections := VBoxContainer.new()
var _headings := {}   # tour -> its heading Label
var _scroll := ScrollContainer.new()
var _detail := VBoxContainer.new()
var _facts_box := ScrollContainer.new()
var _tiles: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	var title := BookKit.label("Wonders Passport", 34, BookKit.TITLE_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 60.0))
	count_label.custom_minimum_size.x = 300
	head.add_child(count_label)
	add_child(head)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(TILE.x * COLUMNS + 8 * (COLUMNS - 1) + 14, TILE.y * ROWS_SHOWN + 8 * (ROWS_SHOWN - 1))
	_sections.add_theme_constant_override("separation", 8)
	_scroll.add_child(_sections)
	add_child(_scroll)
	for tour: StringName in WonderFacts.TOUR_IDS:   # each tour under its heading, its stamps in its list's order
		var heading_label := BookKit.label("", 24, BookKit.TITLE_INK)
		heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_headings[tour] = heading_label
		_sections.add_child(heading_label)
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_sections.add_child(grid)
		for id: StringName in WonderFacts.tour_ids(tour):
			var b := _tile(id)
			grid.add_child(b)
			_tiles.append(b)
	_build_detail()
	refresh()


func _tile(id: StringName) -> Button:
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.add_theme_stylebox_override("normal", BookKit.card_box(BookKit.CARD, 4))
	b.add_theme_stylebox_override("hover", BookKit.card_box(BookKit.CARD, 4))
	b.add_theme_stylebox_override("pressed", BookKit.card_box(Color(1, 1, 1, 0.55), 4))
	b.set_meta(&"wonder", id)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var stamp := WonderStamp.new(id, false, STAMP)
	stamp.name = "Stamp"
	stamp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(stamp)
	var words := BookKit.label("", 17)
	words.name = "Words"
	words.clip_text = true
	words.custom_minimum_size.x = TILE.x - 10
	v.add_child(words)
	var stars := BookKit.label("", 16, BookKit.SOFT_INK)
	stars.name = "Stars"
	v.add_child(stars)
	b.pressed.connect(open_card.bind(id))
	return b


func _build_detail() -> void:
	_detail.visible = false
	_detail.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	detail_stamp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(detail_stamp)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 6)
	for l: Label in [detail_name, detail_where, detail_facts]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 760
	words.add_child(detail_name)
	words.add_child(detail_where)
	_facts_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_facts_box.custom_minimum_size = Vector2(780, 200)
	var inner := VBoxContainer.new()
	inner.add_child(detail_facts)
	quiz.visible = false
	quiz.finished.connect(_quiz_done)
	inner.add_child(quiz)
	_facts_box.add_child(inner)
	words.add_child(_facts_box)
	row.add_child(words)
	_detail.add_child(row)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	quiz_button.pressed.connect(start_quiz)
	buttons.add_child(quiz_button)
	back_button.pressed.connect(close_card)
	buttons.add_child(back_button)
	_detail.add_child(buttons)
	_detail.custom_minimum_size.y = _scroll.custom_minimum_size.y
	add_child(_detail)


## Fills every stamp from the book (call when the page shows).
func refresh() -> void:
	var w: WonderData = data.call()
	quiz.data = data
	count_label.text = WondersPassportRules.count_words(w)
	for tour: StringName in _headings:
		(_headings[tour] as Label).text = "%s · %d of %d" % [WonderFacts.tour_info(tour).heading,
			WondersPassportRules.tour_stamped(w, tour), WonderFacts.tour_ids(tour).size()]
	var list := WondersPassportRules.stamps(w)
	for i in _tiles.size():
		var e: Dictionary = list[i]
		var v := _tiles[i].get_child(0)
		(v.get_node("Stamp") as WonderStamp).stamped = bool(e.stamped)
		(v.get_node("Words") as Label).text = str(WonderFacts.of(e.id).get("short", e.name)) if bool(e.stamped) else "???"
		(v.get_node("Stars") as Label).text = "quiz: %d of %d" % [int(e.stars), int(e.questions)] if bool(e.stamped) else ""
	if shown != &"":
		open_card(shown)


## Wonder `id`'s card.
func open_card(id: StringName) -> void:
	shown = id
	var w: WonderData = data.call()
	var f := WonderFacts.of(id)
	var stamped := w.stamped(id)
	detail_stamp.wonder = id
	detail_stamp.stamped = stamped
	detail_name.text = str(f.get("name", ""))
	detail_where.text = "%s · %s · %s" % [str(f.get("place", "")), WonderFacts.when_words(id),
		WonderFacts.status_words(id)]
	var lines: Array[String] = []
	for fact: String in f.get("facts", []):
		lines.append("•  " + fact)
	detail_facts.text = "\n".join(lines) if stamped else WondersPassportRules.clue(id) + "\n\n" + "\n".join(lines)
	detail_facts.visible = true
	quiz.visible = false
	quiz_button.visible = WondersPassportRules.may_quiz(w, id)
	_scroll.visible = false
	_detail.visible = true


func close_card() -> void:
	shown = &""
	quiz.visible = false
	_detail.visible = false
	_scroll.visible = true


## The card's QUIZ: the wonder's questions in place of its facts.
func start_quiz() -> void:
	if shown == &"":
		return
	detail_facts.visible = false
	quiz_button.visible = false
	quiz.visible = true
	quiz.start(shown)


func _quiz_done() -> void:
	var id := shown
	refresh()
	if id != &"":
		open_card(id)


## The stamps in WonderFacts.ORDER (the first tour's, then the second's) (tests).
func tiles() -> Array[Button]:
	return _tiles


func tile_words(i: int) -> String:
	return (_tiles[i].get_child(0).get_node("Words") as Label).text


func tile_stamped(i: int) -> bool:
	return (_tiles[i].get_child(0).get_node("Stamp") as WonderStamp).stamped


## Tour `tour`'s heading (tests).
func heading(tour: StringName) -> String:
	return (_headings[tour] as Label).text
