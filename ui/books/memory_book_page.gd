class_name MemoryBookPage
extends VBoxContainer
## The Memory Book's page in the book (M3 Task 21b; research R2): the child's big moments, newest first, six to a
## page — each a card with the child's own photo (when one was taken soon after) or the moment's picture, its words
## and its date. ◀ ▶ turn the pages. It lives on this device only (MemoryBook) and nothing here shares it.

const PER_PAGE := 6
const COLUMNS := 3
const CARD := Vector2(328, 170)
const PHOTO := Vector2(160, 90)
const EMPTY_WORDS := "Your big moments will be kept here, like the first buddy you wake up!"

## The book and its file (tests use their own).
var book: Callable = func() -> MemoryBook: return MemoryBook.current()
var book_path: Callable = func() -> String: return MemoryBook.current_path()

var page := 0
var title := BookKit.label("Memory Book", 34, BookKit.TITLE_INK)
var page_label := BookKit.label("", 24, BookKit.SOFT_INK)
var prev_button := BookKit.button("", BookKit.PAGE_BUTTON)
var next_button := BookKit.button("", BookKit.PAGE_BUTTON)
var empty_label := BookKit.label(EMPTY_WORDS, 26, BookKit.SOFT_INK)

var _grid := GridContainer.new()
var _photos := {}   # file path -> Texture2D (while the book is open)


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	add_child(BookKit.page_row(title, prev_button, next_button, page_label,
		ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 60.0)))   # M3 Task 21a's speaker
	prev_button.pressed.connect(func() -> void: show_page(page - 1))
	next_button.pressed.connect(func() -> void: show_page(page + 1))
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.custom_minimum_size = Vector2(CARD.x * COLUMNS + 10 * (COLUMNS - 1), CARD.y * 2 + 10)
	add_child(_grid)
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.custom_minimum_size = Vector2(700, 0)
	add_child(empty_label)
	refresh()


func page_count() -> int:
	var b: MemoryBook = book.call()
	return maxi(ceili(b.entries.size() / float(PER_PAGE)), 1)


## Shows the newest memories first (call when the page shows).
func refresh() -> void:
	show_page(page)


func show_page(i: int) -> void:
	page = clampi(i, 0, page_count() - 1)
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var b: MemoryBook = book.call()
	var list := b.newest_first()
	for k in range(page * PER_PAGE, mini((page + 1) * PER_PAGE, list.size())):
		_grid.add_child(_card(list[k], b))
	empty_label.visible = list.is_empty()
	_grid.visible = not list.is_empty()
	page_label.text = "%d / %d" % [page + 1, page_count()]
	prev_button.disabled = page == 0
	next_button.disabled = page >= page_count() - 1


func _card(e: Dictionary, b: MemoryBook) -> Control:
	var id := StringName(str(e.id))
	var box := PanelContainer.new()
	box.custom_minimum_size = CARD
	box.add_theme_stylebox_override("panel", BookKit.card_box(BookKit.CARD, 8))
	box.set_meta(&"memory", id)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var photo := _photo(b.photo_path(id, book_path.call()))
	if photo:
		var t := TextureRect.new()
		t.name = "Photo"
		t.texture = photo
		t.custom_minimum_size = PHOTO
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(t)
	else:
		var pic := BookKit.picture(MemoryRules.picture_of(id), PHOTO.y)
		pic.name = "Picture"
		v.add_child(pic)
	var words := BookKit.label(MemoryRules.words_of(id), 20)
	words.name = "Words"
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size.x = CARD.x - 20
	v.add_child(words)
	var date := BookKit.label(MemoryRules.date_words(str(e.get("date", ""))), 17, BookKit.SOFT_INK)
	date.name = "Date"
	v.add_child(date)
	return box


func _photo(path: String) -> Texture2D:
	if path == "" or not FileAccess.file_exists(path):
		return null
	if not _photos.has(path):
		var img := Image.load_from_file(path)
		_photos[path] = ImageTexture.create_from_image(img) if img and not img.is_empty() else null
	return _photos[path]


## The cards showing now (tests): [{id, words, date, photo: bool}].
func shown() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in _grid.get_children():
		if c.is_queued_for_deletion():
			continue
		var v := c.get_child(0)
		out.append({"id": c.get_meta(&"memory"), "words": (v.get_node("Words") as Label).text,
			"date": (v.get_node("Date") as Label).text, "photo": v.has_node("Photo")})
	return out
