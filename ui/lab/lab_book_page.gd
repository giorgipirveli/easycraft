class_name LabBookPage
extends VBoxContainer
## Spec §23.1-23.2: the Lab Book, a page of the book (the Secret Book's LAB tab, and the Lab's own LAB BOOK). A tile for
## every experiment (LabExperiments, so new ones come by themselves) with its picture, its name and a star once done; a
## tap opens its card: what the child guessed, what happened (the experiment's result) and, when the guess did not
## match, "Scientists guess wrong all the time; that is how they learn!" (never a mark). Brown ink on the book's paper.

const COLUMNS := 3
const TILE := Vector2(340, 172)

## The Lab Book's data (the Lab and tests use their own profile's).
var data: Callable = func() -> LabData: return Profile.data.lab

var count_label := BookKit.label("", 22, BookKit.SOFT_INK)
var back_button := BookKit.button("BACK", Vector2(200, 72))
var detail_title := BookKit.label("", 32, BookKit.TITLE_INK)
var detail_guess := BookKit.label("", 22)
var detail_result := BookKit.label("", 22)
var detail_note := BookKit.label("", 20, BookKit.SOFT_INK)
var detail_art: LabArt.Card
var detail_star: LabArt.Star
var shown := ""

var _grid := GridContainer.new()
var _detail := VBoxContainer.new()
var _tiles: Array[Button] = []
var _ids: Array[String] = []


func _ready() -> void:
	name = "LabBook"
	add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	var title := BookKit.label("Lab Book", 34, BookKit.TITLE_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 64.0))
	count_label.custom_minimum_size.x = 320
	head.add_child(count_label)
	add_child(head)
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	add_child(_grid)
	for id in LabExperiments.ids():
		var e := LabExperiments.experiment(id)
		if e.is_empty():
			continue
		var b := _tile(e)
		_grid.add_child(b)
		_tiles.append(b)
		_ids.append(id)
	_build_detail()
	refresh()


func _tile(e: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	for state: String in ["normal", "hover"]:
		b.add_theme_stylebox_override(state, BookKit.card_box(BookKit.CARD, 8))
	b.add_theme_stylebox_override("pressed", BookKit.card_box(Color(1, 1, 1, 0.55), 8))
	b.set_meta(&"id", str(e.id))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var art := LabArt.Card.new(str((e.get("scene", {}) as Dictionary).get("kind", "")), Vector2(TILE.x - 16, 96))
	v.add_child(art)
	var words := BookKit.label(str(e.title), 21)
	words.name = "Words"
	v.add_child(words)
	var status := BookKit.label("", 17, BookKit.SOFT_INK)
	status.name = "Status"
	v.add_child(status)
	var star := LabArt.Star.new(34.0)
	star.name = "Star"
	star.position = Vector2(TILE.x - 44, 8)
	b.add_child(star)
	b.pressed.connect(open_card.bind(str(e.id)))
	return b


func _build_detail() -> void:
	_detail.visible = false
	_detail.add_theme_constant_override("separation", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	detail_art = LabArt.Card.new("", Vector2(260, 180))
	left.add_child(detail_art)
	detail_star = LabArt.Star.new(48.0)
	detail_star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(detail_star)
	row.add_child(left)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 10)
	for l: Label in [detail_title, detail_guess, detail_result, detail_note]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 700
		words.add_child(l)
	row.add_child(words)
	_detail.add_child(row)
	back_button.pressed.connect(close_card)
	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	back_row.add_child(back_button)
	_detail.add_child(back_row)
	add_child(_detail)


## Fills every tile from the Lab Book (call when the page shows).
func refresh() -> void:
	var d: LabData = data.call()
	var done := 0
	for i in _tiles.size():
		var id := _ids[i]
		var star := d.has_star(id)
		done += 1 if star else 0
		(_tiles[i].get_node("Star") as LabArt.Star).filled = star
		var status := _tiles[i].get_child(0).get_node("Status") as Label
		if star:
			status.text = "Done!" if d.runs(id) == 1 else "Done %d times" % d.runs(id)
		elif d.planted_at(id) > 0:
			status.text = "Growing: come back soon"
		else:
			status.text = "Not tried yet"
	count_label.text = "%d of %d experiments done" % [done, _tiles.size()]
	if shown != "":
		open_card(shown)


## The card of experiment `id`: the guess, what happened, and a kind word.
func open_card(id: String) -> void:
	var e := LabExperiments.experiment(id)
	if e.is_empty():
		return
	shown = id
	var d: LabData = data.call()
	detail_art.kind = str((e.get("scene", {}) as Dictionary).get("kind", ""))
	detail_art.queue_redraw()
	detail_star.filled = d.has_star(id)
	detail_title.text = str(e.title)
	var guess: Variant = d.guess(id)
	detail_guess.text = "You guessed: %s" % LabExperiments.predict_words(e, guess) if guess != null else "No guess yet."
	if d.has_star(id):
		detail_result.text = "What happened: %s" % str(e.result)
		if guess != null and not d.matched(id):
			detail_note.text = LabScreen.GUESS_AGAIN
		elif guess != null:
			detail_note.text = "Your guess matched what happened."
		else:
			detail_note.text = ""
		detail_note.text += ("\n" if detail_note.text != "" else "") + ("Done once." if d.runs(id) == 1 else "Done %d times." % d.runs(id))
	else:
		detail_result.text = "Not tried yet: tap a lab bench, or TRY IT IN THE LAB in the School." if d.planted_at(id) <= 0 \
			else "The seeds are growing: come back after two game days."
		detail_note.text = ""
	_grid.visible = false
	_detail.visible = true


func close_card() -> void:
	shown = ""
	_detail.visible = false
	_grid.visible = true


func tiles() -> Array[Button]:
	return _tiles


func tile_star(i: int) -> bool:
	return (_tiles[i].get_node("Star") as LabArt.Star).filled
