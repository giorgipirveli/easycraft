class_name TrophyRoom
extends VBoxContainer
## The trophy room (M3 Task 12, spec §14.11, research C3 and C5): every badge on three wooden shelves,
## the ones still to find as shadows ("7 of 24 badges": a finite collection, complete-able by play), and
## the sticker book (a sticker for every board goal done and every sticker present). Reached from the
## adventure board. The in-world trophy shelf is M3 Task 21's.

signal closed

const BADGE := Vector2(124, 126)
const PER_SHELF := 8
const STICKER := Vector2(116, 118)
const STICKER_COLUMNS := 9
const STICKER_ROWS := 3        # rows shown at once; the rest scroll
const WOOD := Color("8d6e63")
const DARK_WOOD := Color("5d4037")

var count_label: Label


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	show_badges()


func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()


func show_badges() -> void:
	_clear()
	var d := Progress.data()
	add_child(UiKit.title("Trophy room", 40))
	count_label = _words(tr("%d of %d badges") % [AchievementRules.unlocked_count(d), AchievementRules.BADGES.size()], 24)
	add_child(count_label)
	var shelf: HBoxContainer = null
	for i in AchievementRules.BADGES.size():
		if i % PER_SHELF == 0:
			shelf = HBoxContainer.new()
			shelf.add_theme_constant_override("separation", 8)
			shelf.alignment = BoxContainer.ALIGNMENT_CENTER
			add_child(shelf)
			add_child(_plank())
		var b: Dictionary = AchievementRules.BADGES[i]
		var have := d.achievements.has(String(b.id))
		shelf.add_child(_tile("Badge_%s" % b.id, b.picture, str(b.words) if have else "???", not have, BADGE))
	var row := _row()
	var stickers := UiKit.big_button("STICKERS", UiKit.ORANGE, Vector2(300, 80))
	stickers.name = "Stickers"
	stickers.pressed.connect(show_stickers)
	row.add_child(stickers)
	row.add_child(_back(func() -> void: closed.emit()))
	add_child(row)


## Every sticker there is: a board goal's picture for each goal done, and the presents' stickers.
func show_stickers() -> void:
	_clear()
	var d := Progress.data()
	add_child(UiKit.title("Sticker book", 40))
	var all: Array = []
	for g: Dictionary in BoardRules.GOALS:
		all.append([String(g.id), g.picture, str(g.words)])
	for id: StringName in PresentRules.STICKERS:
		var g := PresentRules.gift(id, false)
		all.append([String(id), g.picture, str(g.words)])
	for p: Dictionary in BookPages.PAGES:   # M3 Task 21b: a Secret Book page done
		all.append([str(p.sticker), p.picture, "Page done!"])
	var have := 0
	var grid := GridContainer.new()
	grid.columns = STICKER_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for s: Array in all:
		var n := int(d.stickers.get(s[0], 0))
		if n > 0:
			have += 1
		grid.add_child(_tile("Sticker_%s" % s[0], s[1], ("×%d" % n) if n > 0 else "?", n == 0, STICKER))
	count_label = _words(tr("%d of %d stickers") % [have, all.size()], 24)
	add_child(count_label)
	var scroll := ScrollContainer.new()   # owner #45a: many more goals, so the book scrolls (3 rows show)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(STICKER.x * STICKER_COLUMNS + 8 * (STICKER_COLUMNS - 1) + 12,
		STICKER.y * STICKER_ROWS + 8 * (STICKER_ROWS - 1) + 4)
	scroll.add_child(grid)
	add_child(scroll)
	var row := _row()
	row.add_child(_back(show_badges))
	add_child(row)


func _tile(tile_name: String, picture: StringName, words: String, dim: bool, tile_size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = tile_name
	p.custom_minimum_size = tile_size
	p.add_theme_stylebox_override("panel", UiKit.box(Color(0.2, 0.16, 0.12, 0.9) if dim else Color(0.35, 0.27, 0.14, 0.95), 16, 6))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	var pic := ProgressPicture.new(picture, 60)
	pic.dim = dim
	v.add_child(pic)
	var l := _words(words, 16)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = tile_size.x - 16
	v.add_child(l)
	p.add_child(v)
	return p


func _plank() -> ColorRect:
	var r := ColorRect.new()
	r.color = WOOD
	r.custom_minimum_size = Vector2(BADGE.x * PER_SHELF + 8 * (PER_SHELF - 1) + 24, 8)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return r


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return row


func _back(action: Callable) -> Button:
	var b := UiKit.big_button("BACK", Color(), Vector2(300, 80))
	b.name = "Back"
	b.pressed.connect(action)
	return b


static func _words(text: String, font: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
