class_name SecretBook
extends Control
## The Secret Book (M2 Task 16, spec §12.16 and §5.7): a page with a slot per kind of secret — its picture,
## name and how many were found (account-wide, the profile) once found, "???" until then — this world's
## found / total for the areas explored, and a shelf of the treasure-only things found (tap one to hold it).
## A full-screen overlay: a tap outside the page closes it.
## Owner 42 (spec §12.16b): a second page, "Treasure Hunt", with the treasure pack's kinds; until one is found
## its slot shows a picture riddle (a picture of where to look and a few words). Big ◀ ▶ buttons turn the
## pages; the book always opens on the first.

signal treasure_picked(id: int)

const NAMES := {
	SecretRules.TREASURE: "Buried Treasure", SecretRules.ROOM: "Hidden Room", SecretRules.ISLAND: "Sky Island",
	SecretRules.GOLDEN: "Golden Animal", SecretRules.TEMPLE: "Puzzle Temple", SecretRules.WANDERER: "The Wanderer",
	SecretRules.STAR: "Fallen Star", SecretRules.GEODE: "Crystal Geode",
}
const SLOT_SIZE := Vector2(250, 104)
const PAGE_BUTTON := Vector2(90, 90)
const TREASURE_TITLE := "Treasure Hunt"
const KEEPSAKE_TITLE := "Keepsakes"
const RECIPES_TITLE := "Buddy Recipes"   # M3 Task 20b
const ALBUM_TITLE := "Buddy Album"
const CAVE_TITLE := "Cave Book"   # universe 6: the Glow Caves' wonders and sights (owner #122)
## The Cave Book's pictures: a block of each place (dimmed until found).
const CAVE_PICTURES := {&"grotto": BlockIds.GLOW_WORMS, &"drip": BlockIds.STALACTITE, &"echo": BlockIds.CAVE_STONE,
	&"rain": BlockIds.WATER, &"lake": BlockIds.CAVE_PEARL, &"crystals": BlockIds.SELENITE, &"longest": BlockIds.FLOWSTONE}

var director: SecretDirector
var world_label := Label.new()
var title := Label.new()
var page_label := Label.new()
var prev_button := Button.new()
var next_button := Button.new()
var page := 0
var page_panel := PanelContainer.new()
var _pages: Array[Dictionary] = []  # {kinds, grid, slots: Array[{kind, picture, name}]}
var _shelf := HBoxContainer.new()
var _counts := Vector2i.ZERO
## M7 (the browser's freezes): the HUD's book is built the first time it opens (or a page, a tab or its slots are
## asked for), not when it enters the tree: a world switch built its ~500 nodes with the rest of the HUD in one frame.
## Set before adding it.
var build_later := false
var _built := false


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not build_later:
		_build()


## The pages and the tabs (once; everything that shows or reads them asks for it).
func _build() -> void:
	if _built:
		return
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper_box := page_panel
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("f3e6c4")
	paper.border_color = Color("7a4a24")
	paper.set_border_width_all(8)
	paper.set_corner_radius_all(16)
	paper.set_content_margin_all(22)
	paper_box.add_theme_stylebox_override("panel", paper)
	add_child(paper_box)
	paper_box.anchor_left = 0.5
	paper_box.anchor_right = 0.5
	paper_box.anchor_top = 0.5
	paper_box.anchor_bottom = 0.5
	paper_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	paper_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	paper_box.add_child(_books_column(column))   # M3 Task 21b: the books' tabs beside the Secret Book's pages
	column.add_child(_title_row())
	var first: Array[StringName] = SecretRules.KINDS.duplicate()
	first.append(MouseVillages.KIND)   # M3 Task 21c: the Tiny world's mouse villages
	_add_page(first, column)
	_add_page(TreasurePlaces.KINDS, column)
	_add_keepsake_page(column)   # owner #45a: the quest stories' keepsakes
	_add_recipe_page(column)   # M3 Task 20b: the secret buddy shapes
	_add_album_page(column)   # M3 Task 20b: every buddy this child woke
	_add_cave_page(column)   # universe 6: the Glow Caves' Cave Book
	world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_label.add_theme_font_size_override("font_size", 24)
	world_label.add_theme_color_override("font_color", Color("3b2a18"))
	column.add_child(world_label)
	var shelf_row := HBoxContainer.new()
	shelf_row.add_theme_constant_override("separation", 10)
	var shelf_title := Label.new()
	shelf_title.text = "Treasures:"
	shelf_title.add_theme_font_size_override("font_size", 24)
	shelf_title.add_theme_color_override("font_color", Color("5a3310"))
	shelf_row.add_child(shelf_title)
	_shelf.add_theme_constant_override("separation", 8)
	shelf_row.add_child(_shelf)
	column.add_child(shelf_row)
	show_page(0)


## ◀ the title, the page number ▶.
func _title_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	for b: Button in [prev_button, next_button]:
		b.custom_minimum_size = PAGE_BUTTON
		b.add_theme_font_size_override("font_size", 40)
		b.focus_mode = Control.FOCUS_NONE
	prev_button.text = "◀"
	next_button.text = "▶"
	prev_button.pressed.connect(func() -> void: _turn(-1))
	next_button.pressed.connect(func() -> void: _turn(1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("5a3310"))
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_label.add_theme_font_size_override("font_size", 24)
	page_label.add_theme_color_override("font_color", Color("7a5a3a"))
	row.add_child(prev_button)
	row.add_child(title)
	row.add_child(ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 60.0))   # M3 Task 21a
	row.add_child(page_label)
	row.add_child(next_button)
	return row


func _add_page(kinds: Array[StringName], column: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	var slots: Array[Dictionary] = []
	for kind in kinds:
		grid.add_child(_slot(kind, slots))
	_pages.append({"kinds": kinds, "grid": grid, "slots": slots})


func open() -> void:
	_build()
	show_tab(SECRETS_TAB)   # M3 Task 21b: the Secret Book's own tab first
	show_page(0)
	visible = true
	UiMotion.pop_in(self)   # owner #94: every panel pops in the same way
	Audio.play(&"ui_click")
	if director:
		if not director.counts_changed.is_connected(_on_counts):
			director.counts_changed.connect(_on_counts)
		director.request_book_counts()


func close() -> void:
	visible = false


func page_count() -> int:
	_build()
	return _pages.size()


## Shows page i (0: the M2 secrets of this universe, 1: the treasure hunt).
func show_page(i: int) -> void:
	_build()
	page = clampi(i, 0, _pages.size() - 1)
	for k in _pages.size():
		(_pages[k].grid as Control).visible = k == page
	title.text = TREASURE_TITLE if page == 1 else (KEEPSAKE_TITLE if page == 2 else tr("Secret Book — %s") % Lang.t(UniverseRegistry.display_name(Game.universe)))
	if _pages[page].has("title"):
		title.text = _pages[page].title   # M3 Task 20b
	page_label.text = "%d / %d" % [page + 1, _pages.size()]
	prev_button.disabled = page == 0
	next_button.disabled = page == _pages.size() - 1
	refresh()


func _turn(step: int) -> void:
	Audio.play(&"ui_click")
	show_page(page + step)


## Fills the pages from the profile (kinds found, the shelf) and the world counts.
func refresh() -> void:
	_build()
	for p: Dictionary in _pages:
		for slot: Dictionary in p.slots:
			if slot.has("keepsake"):
				_fill_keepsake(slot)
			elif slot.has("recipe"):
				_fill_recipe(slot)   # M3 Task 20b
			elif slot.has("cave"):
				_fill_cave(slot)   # universe 6
			else:
				_fill(slot)
	_fill_album()   # M3 Task 20b
	if director:
		_counts = director.book_counts()
	world_label.text = world_line()
	for c in _shelf.get_children():
		_shelf.remove_child(c)
		c.queue_free()
	for id in Profile.data.treasures:
		var b := Button.new()
		b.icon = BlockIcons.icon(id)
		b.expand_icon = true
		b.custom_minimum_size = Vector2(64, 64)
		b.tooltip_text = ItemIds.display_name(id)
		b.set_meta(&"id", id)
		b.pressed.connect(_pick.bind(id))
		_shelf.add_child(b)
	if Profile.data.treasures.is_empty():
		var none := Label.new()
		none.text = "none yet — open chests!"
		none.add_theme_font_size_override("font_size", 22)
		none.add_theme_color_override("font_color", Color("7a5a3a"))
		_shelf.add_child(none)


## A found kind shows its picture, name and count; the M2 kinds show "???" until then, the treasure pack's a
## picture riddle.
func _fill(slot: Dictionary) -> void:
	var kind: StringName = slot.kind
	var n := int(Profile.data.secret_book.get(String(kind), 0))
	var pic := slot.picture as TextureRect
	var label := slot.name as Label
	if n > 0:
		pic.texture = Pictures.texture(SecretDirector.picture_of(kind))
		var kind_name: String = MouseVillages.NAME if kind == MouseVillages.KIND else NAMES.get(kind, TreasureRules.NAMES.get(kind, ""))
		label.text = "%s\n× %d" % [tr(kind_name), n]
		label.add_theme_font_size_override("font_size", 22)
	elif kind == MouseVillages.KIND:   # M3 Task 21c: a picture riddle, like the treasure pack's
		pic.texture = Pictures.texture(TinyPictures.DOOR)
		label.text = MouseVillages.BOOK_RIDDLE
		label.add_theme_font_size_override("font_size", 18)
	elif TreasureRules.BOOK_RIDDLES.has(kind):
		var riddle: Dictionary = TreasureRules.BOOK_RIDDLES[kind]
		pic.texture = Pictures.texture(int(riddle.picture))
		label.text = riddle.text
		label.add_theme_font_size_override("font_size", 18)
	else:
		pic.texture = Pictures.texture(Riddles.QUESTION)
		label.text = "???"
		label.add_theme_font_size_override("font_size", 22)


## "In this world: 3 of 11 secrets found in the areas you explored".
func world_line() -> String:
	return tr("In this world: %d of %d secrets found in the places you explored") % [_counts.x, _counts.y]


## The texts of the slots on the page showing now.
func slot_texts() -> Array[String]:
	_build()
	var out: Array[String] = []
	for slot: Dictionary in _pages[page].slots:
		out.append((slot.name as Label).text)
	return out


## The picture of slot i on the page showing now.
func slot_picture(i: int) -> Texture2D:
	_build()
	return (_pages[page].slots[i].picture as TextureRect).texture


func shelf_ids() -> Array[int]:
	_build()
	var out: Array[int] = []
	for c in _shelf.get_children():
		if c is Button and not c.is_queued_for_deletion():
			out.append(int(c.get_meta(&"id")))
	return out


func _slot(kind: StringName, slots: Array[Dictionary]) -> Control:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.35)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(8)
	box.add_theme_stylebox_override("panel", style)
	box.custom_minimum_size = SLOT_SIZE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(80, 80)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("3b2a18"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(SLOT_SIZE.x - 80 - 10 - 16, 0)
	row.add_child(label)
	slots.append({"kind": kind, "picture": pic, "name": label})
	return box


# --- Owner #45a: the Keepsakes page (a spot per quest story; its keepsake once the story is done) ---

func _add_keepsake_page(column: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	var slots: Array[Dictionary] = []
	for c: Dictionary in QuestRules.CHAINS:
		var box := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.35)
		style.set_corner_radius_all(12)
		style.set_content_margin_all(6)
		box.add_theme_stylebox_override("panel", style)
		box.custom_minimum_size = Vector2(190, 120)
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(v)
		var pic := ProgressPicture.new((c.keepsake as Dictionary).picture, 64)
		v.add_child(pic)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("3b2a18"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(176, 0)
		v.add_child(label)
		grid.add_child(box)
		slots.append({"keepsake": c.id, "picture": pic, "name": label})
	_pages.append({"kinds": [] as Array[StringName], "grid": grid, "slots": slots})


func _fill_keepsake(slot: Dictionary) -> void:
	var id: StringName = slot.keepsake
	var got := QuestRules.is_done(Progress.data(), id)
	(slot.picture as ProgressPicture).dim = not got
	(slot.name as Label).text = str(QuestRules.keepsake(id).words) if got \
		else tr("Ask %s") % str(QuestRules.giver(QuestRules.chain(id).giver).name)


func _on_counts(counts: Vector2i) -> void:
	_counts = counts
	world_label.text = world_line()


func _pick(id: int) -> void:
	Audio.play(&"ui_click")
	close()
	treasure_picked.emit(id)


## Taps on the dimmed area (outside the page) close it.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()

# --- M3 Task 21b: books and memories (the book's tabs) ---
# The BOOK button opens one book with a row of picture tabs: SECRETS (the Secret Book's pages above), ANIMALS (the
# Animal Book), MEMORIES (the Memory Book), IDEAS (idea cards) and SAVING (the saving list). No new HUD button.

const SECRETS_TAB := &"secrets"
const ANIMALS_TAB := &"animals"
const MEMORIES_TAB := &"memories"
const IDEAS_TAB := &"ideas"
const SAVING_TAB := &"saving"
const SPACE_TAB := &"space"   # owner #72/#74, spec §21b.2: the Space Book
const LAB_TAB := &"lab"   # spec §23: the Science Lab's Lab Book
const WONDERS_TAB := &"wonders"   # owner #78, spec §24: the Wonders Passport
const TABS: Array[StringName] = [SECRETS_TAB, ANIMALS_TAB, SPACE_TAB, WONDERS_TAB, LAB_TAB, MEMORIES_TAB, IDEAS_TAB,
	SAVING_TAB]
const TAB_WORDS := {SECRETS_TAB: "SECRETS", ANIMALS_TAB: "ANIMALS", SPACE_TAB: "SPACE", WONDERS_TAB: "WONDERS",
	LAB_TAB: "LAB", MEMORIES_TAB: "MEMORIES", IDEAS_TAB: "IDEAS", SAVING_TAB: "SAVING"}
const TAB_PICTURES := {SECRETS_TAB: &"chest", ANIMALS_TAB: &"dog", SPACE_TAB: &"star", WONDERS_TAB: &"pyramid",
	LAB_TAB: &"lab", MEMORIES_TAB: &"photo", IDEAS_TAB: &"house", SAVING_TAB: &"coin"}
## The tabs stand in a column left of the pages (a row over them would make the tallest page too tall for the
## 720 px screen), narrow enough for the widest page (M3 Task 20b's buddy recipes) to fit 1280 px beside them.
const TAB_SIZE := Vector2(104, 76)

var tab: StringName = SECRETS_TAB
var tab_buttons := {}   # tab -> Button
var animal_page := AnimalBookPage.new()
var memory_page := MemoryBookPage.new()
var idea_page := IdeaCardsPage.new()
var saving_page := SavingPage.new()
var space_page := SpaceBookPage.new()
var lab_page := LabBookPage.new()   # spec §23
var passport_page := WondersPassportPage.new()   # owner #78, spec §24
var _secrets_view: Control


func _books_column(secrets: VBoxContainer) -> HBoxContainer:
	_secrets_view = secrets
	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	var tabs := VBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for t in TABS:
		var b := BookKit.button("", TAB_SIZE, 18)
		b.name = "Tab_" + String(t)
		var inside := VBoxContainer.new()
		inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inside.alignment = BoxContainer.ALIGNMENT_CENTER
		inside.add_theme_constant_override("separation", 0)
		inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var vr := Vr.active()   # owner #101: a 24 px word never fits the tab (VrReadability): the picture alone, bigger
		inside.add_child(ProgressPicture.new(TAB_PICTURES[t], 60 if vr else 44))
		var word := BookKit.label(TAB_WORDS[t], 14)
		word.clip_text = true   # a long word never widens the column
		word.visible = not vr
		inside.add_child(word)
		b.tooltip_text = TAB_WORDS[t]
		b.add_child(inside)
		b.pressed.connect(_on_tab.bind(t))
		tab_buttons[t] = b
		tabs.add_child(b)
	outer.add_child(tabs)
	var pages := VBoxContainer.new()
	pages.add_theme_constant_override("separation", 12)
	pages.add_child(secrets)
	for p: Control in [animal_page, memory_page, idea_page, saving_page, space_page, lab_page, passport_page]:
		p.visible = false
		pages.add_child(p)
	outer.add_child(pages)
	return outer


func _on_tab(t: StringName) -> void:
	Audio.play(&"ui_click")
	show_tab(t)


## Shows one of the book's tabs (TABS), filled fresh.
func show_tab(t: StringName) -> void:
	_build()
	if not TABS.has(t):
		return
	tab = t
	var pages := {SECRETS_TAB: _secrets_view, ANIMALS_TAB: animal_page, MEMORIES_TAB: memory_page, IDEAS_TAB: idea_page,
		SAVING_TAB: saving_page, SPACE_TAB: space_page, LAB_TAB: lab_page, WONDERS_TAB: passport_page}
	for k: StringName in pages:
		(pages[k] as Control).visible = k == t
		(tab_buttons[k] as Button).modulate = Color.WHITE if k == t else Color(1, 1, 1, 0.6)
	match t:
		SECRETS_TAB:
			refresh()
		ANIMALS_TAB:
			animal_page.close_card()
			animal_page.refresh()
		SPACE_TAB:
			space_page.close_card()
			space_page.refresh()
		LAB_TAB:   # spec §23: the Lab Book
			lab_page.close_card()
			lab_page.refresh()
		WONDERS_TAB:   # owner #78: the Wonders Passport
			passport_page.close_card()
			passport_page.refresh()
		MEMORIES_TAB:
			memory_page.page = 0
			memory_page.refresh()
		SAVING_TAB:
			saving_page.refresh()


## Opens the book on tab `t` (a bookshelf's tap opens the memories).
func open_tab(t: StringName) -> void:
	open()
	show_tab(t)

# --- M3 Task 20b: buddy magic's pages ---
# "Buddy Recipes": a slot per secret buddy shape (BuddyRecipes): its silhouette and a picture riddle until the child
# wakes one, then its picture in its blocks' colours and its name. "Buddy Album": every buddy this child woke
# (ProfileData.buddy_magic: the newest ALBUM_MAX, the older ones as a count), newest first: its picture (the front
# of its build), its name, the universe and the day.

const RECIPE_SLOT := Vector2(272, 112)
const ALBUM_COLUMNS := 5
const ALBUM_CARD := Vector2(150, 150)
const ALBUM_HEIGHT := 360.0

var recipes_line := Label.new()
var album_line := Label.new()
var _album_grid := GridContainer.new()


func _add_recipe_page(column: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	column.add_child(box)
	_book_label(recipes_line, 22)
	box.add_child(recipes_line)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	var slots: Array[Dictionary] = []
	for r: Dictionary in BuddyRecipes.RECIPES:
		var cell := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.35)
		style.set_corner_radius_all(12)
		style.set_content_margin_all(8)
		cell.add_theme_stylebox_override("panel", style)
		cell.custom_minimum_size = RECIPE_SLOT
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		cell.add_child(row)
		var pic := BuildPicture.new(80.0)
		var sil := BuddyRecipes.silhouette(r.id)
		var ids := PackedInt32Array()
		for cls: StringName in sil.cells:
			ids.append(BuddyRecipes.block_of(cls))
		pic.set_cells(sil.w, sil.h, ids)
		row.add_child(pic)
		var label := Label.new()
		_book_label(label, 17)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(RECIPE_SLOT.x - 80 - 10 - 16, 0)
		row.add_child(label)
		grid.add_child(cell)
		slots.append({"recipe": r.id, "picture": pic, "name": label})
	_pages.append({"kinds": [] as Array[StringName], "grid": box, "slots": slots, "title": RECIPES_TITLE})


func _add_album_page(column: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	column.add_child(box)
	_book_label(album_line, 22)
	box.add_child(album_line)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2((ALBUM_CARD.x + 10) * ALBUM_COLUMNS, ALBUM_HEIGHT)
	box.add_child(scroll)
	_album_grid.columns = ALBUM_COLUMNS
	_album_grid.add_theme_constant_override("h_separation", 10)
	_album_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_album_grid)
	_pages.append({"kinds": [] as Array[StringName], "grid": box, "slots": [] as Array[Dictionary], "title": ALBUM_TITLE})


func _fill_recipe(slot: Dictionary) -> void:
	var r := BuddyRecipes.recipe(slot.recipe)
	var found := Profile.data.buddy_magic.has_found(slot.recipe)
	(slot.picture as BuildPicture).shadow = not found
	(slot.name as Label).text = str(r.title) if found else str(r.hint)
	(slot.name as Label).add_theme_font_size_override("font_size", 22 if found else 17)
	recipes_line.text = tr("Secret shapes found: %d of %d. Build one and wake it with the wand!") % [
		Profile.data.buddy_magic.found.size(), BuddyRecipes.RECIPES.size()]


# --- Universe 6: the Cave Book (owner #122: what a child found by playing is kept) ---

var caves_line := Label.new()


func _add_cave_page(column: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	column.add_child(box)
	_book_label(caves_line, 22)
	box.add_child(caves_line)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	var slots: Array[Dictionary] = []
	for kind: StringName in GlowWonderRules.BOOK:
		grid.add_child(_slot(kind, slots))
		slots[-1]["cave"] = true
	_pages.append({"kinds": [] as Array[StringName], "grid": box, "slots": slots, "title": CAVE_TITLE})


## A page's name, then its fact once found ("???" until then); its picture dimmed until found.
func _fill_cave(slot: Dictionary) -> void:
	var kind: StringName = slot.kind
	var got := Profile.data.wonder.cave_found(kind)
	var pic := slot.picture as TextureRect
	pic.texture = BlockIcons.icon(int(CAVE_PICTURES.get(kind, BlockIds.CAVE_STONE)))
	pic.modulate = Color.WHITE if got else Color(1, 1, 1, 0.35)
	var label := slot.name as Label
	label.text = "%s\n%s" % [tr(GlowWonderRules.name_of(kind)), tr(str(GlowWonderRules.BOOK_LINES[kind])) if got else "???"]
	label.add_theme_font_size_override("font_size", 18)
	var n := 0
	for k: StringName in GlowWonderRules.BOOK:
		if Profile.data.wonder.cave_found(k):
			n += 1
	caves_line.text = tr("Found in the Glow Caves: %d of %d. Play with the caves to find the rest!") % [n,
		GlowWonderRules.BOOK.size()]


func _fill_album() -> void:
	for c in _album_grid.get_children():
		_album_grid.remove_child(c)
		c.free()
	var m := Profile.data.buddy_magic
	for i in range(m.album.size() - 1, -1, -1):
		_album_grid.add_child(_album_card(m.album[i]))
	if m.album.is_empty():
		album_line.text = "No buddies yet: build something and wake it with the wand!"
	else:
		album_line.text = tr("Buddies woken: %d") % m.woken if m.older == 0 \
			else tr("Buddies woken: %d (not shown: %d older)") % [m.woken, m.older]


func _album_card(e: Dictionary) -> Control:
	var cell := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.35)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(6)
	cell.add_theme_stylebox_override("panel", style)
	cell.custom_minimum_size = ALBUM_CARD
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	cell.add_child(v)
	var pic := BuildPicture.new(72.0)
	pic.show_code(str(e.get("pic", "")))
	v.add_child(pic)
	var n := Label.new()
	_book_label(n, 18)
	n.text = str(e.name)
	n.clip_text = true
	n.custom_minimum_size.x = ALBUM_CARD.x - 12
	if str(e.recipe) != "":
		n.add_theme_color_override("font_color", Color("7b4bd6"))   # a secret shape
	v.add_child(n)
	var where := Label.new()
	_book_label(where, 15)
	where.text = BuddyMagicData.where_words(e)
	var when := BuddyMagicData.when_words(e)
	if when != "":
		where.text += "\n" + when
	v.add_child(where)
	cell.set_meta(&"words", "%s\n%s" % [n.text, where.text])
	cell.set_meta(&"picture", pic)
	return cell


## The album's cards on show, newest first: "name\nwhere\nwhen" each.
func album_cards() -> Array[String]:
	_build()
	var out: Array[String] = []
	for c in _album_grid.get_children():
		out.append(str(c.get_meta(&"words")))
	return out


func album_picture(i: int) -> BuildPicture:
	_build()
	return _album_grid.get_child(i).get_meta(&"picture") as BuildPicture


## The picture of recipe slot i.
func recipe_picture(i: int) -> BuildPicture:
	_build()
	for p: Dictionary in _pages:
		if p.get("title", "") == RECIPES_TITLE:
			return p.slots[i].picture as BuildPicture
	return null


static func _book_label(l: Label, font_size: int) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("3b2a18"))
