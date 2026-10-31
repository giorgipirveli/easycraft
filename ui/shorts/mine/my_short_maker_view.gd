class_name MyShortMakerView
extends Control
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): the maker, over the SHORTS tab (ShortsView.SIZE: 780 × 512 in the
## design space). A child makes a Short of their own in five steps with big buttons, and sees it on the right the whole
## time (the same player as every Short, 9:16: a tap plays and pauses it):
##
##   1 KIND   HOW I BUILT IT · 3 FACTS ABOUT… · STEP BY STEP            |  the Short as it is now
##   2 PICK   2-4 photos · a planet, a wonder or an animal · a build    |  (MyShortMaker: it always
##   3 WORDS  the title, each scene's caption, the ending: a quick       |   passes ShortCheck)
##            phrase (read aloud when tapped) or TYPE (the game's word   |
##            filter for children, English letters, no names)            |
##   4 LOOK   the backdrop, the music (the game's own pieces), the voice |
##   5 SAVE   watch it, then SAVE: it is kept in MY SHORTS on this device|
##   BACK                                               NEXT / SAVE
##
## Touch, mouse and controller (every choice is a button; PadFocus moves between them; Circle / B and Android Back go a
## step back: pad_back, back_if_open). Nothing here talks to a network, pays or counts: the Short is the reward.

signal saved(id: String)
signal closed

const SIZE := Vector2(780, 512)
const LEFT_W := 480.0
const PREVIEW_X := 492.0
const PREVIEW_SIZE := Vector2(288, 512)
const CONTENT_TOP := 60.0
const CONTENT_H := 380.0
const FOOT_Y := 448.0
const PINK := Color("d9437a")
const YELLOW := Color("ffd23f")
const INK := Color("1f2a4a")
const PANEL := Color(0.07, 0.08, 0.14, 0.98)
const CARD := Color(0.16, 0.2, 0.32, 0.95)

const KIND := 0
const PICK := 1
const WORDS := 2
const LOOK := 3
const SAVE := 4
const STEP_NAMES: Array[String] = ["KIND", "PICK", "WORDS", "LOOK", "SAVE"]
const FULL := "You have %d Shorts: the most this device keeps. Delete one in MY SHORTS to make a new one."
const NO_PHOTOS := "No photos yet! In your world, tap MORE, then PHOTO, and take a few of your build."
const NO_STAMPS := "Make your own stamps with the stamp tool, or pick one of these."
const STAYS := "It stays on this device. Only you can watch it."
const PHOTOS_PER_PAGE := 9
const THINGS_PER_PAGE := 8
const MUSIC_WORDS := {"": "No music", "ode_to_joy": "Ode to Joy", "spring": "Spring", "morning_mood": "Morning",
	"waltz_flowers": "Waltz", "fur_elise": "Für Elise", "nachtmusik": "Night Music", "mountain_king": "Mountain King"}

var profile: ProfileData
var save_profile := Callable()
var clock := Callable()             # () -> int unix seconds (tests)
var reduce_motion := false
## The recipe being made (MyShortRules.clean_recipe's keys; incomplete until PICK is done).
var recipe := {}
## The Short being changed ("" for a new one).
var editing := ""
var step := KIND
## WORDS: the slot being changed: "title", "body:<k>", "ending".
var slot := "title"
var photo_page := 0
var thing_kind := MyShortFacts.PLANET
var thing_page := 0

var preview := ShortPlayer.new()
var preview_window := PreviewWindow.new()
var preview_hint := Label.new()
var step_label := Label.new()
var note := Label.new()
var back_button: Button
var next_button: Button
var content := Control.new()
var type_field := LineEdit.new()
var type_ok: Button

var _pips: Array[Label] = []
var _dirty := false
var _built_json := ""
var _photos: Array[Dictionary] = []    # the album's and the folder's photos (MyShortAlbum.photos), newest first
var _importing := {}                   # file -> task (a folder's photo being copied into the album)
var _stashed_keys := {}
var _keys_off := false
var _photo_version := 0
var _play_after_build := false
var _slot_rows := {}                   # WORDS: slot -> its row


func _init() -> void:
	name = "MyShortMaker"
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var bg := Panel.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", UiKit.box(PANEL, 16, 0))
	bg.position = Vector2(-6, -6)
	bg.size = SIZE + Vector2(12, 12)
	add_child(bg)
	for i in STEP_NAMES.size():
		var pip := Label.new()
		pip.text = str(i + 1)
		pip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pip.position = Vector2(i * 34.0, 8)
		pip.size = Vector2(28, 28)
		pip.add_theme_font_size_override("font_size", 16)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pip)
		_pips.append(pip)
	step_label.position = Vector2(176, 2)
	step_label.size = Vector2(LEFT_W - 176, 44)
	step_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	step_label.max_lines_visible = 2
	step_label.add_theme_font_size_override("font_size", 22)
	step_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(step_label)
	content.position = Vector2(0, CONTENT_TOP)
	content.size = Vector2(LEFT_W, CONTENT_H)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	back_button = _button("BACK", &"up", UiKit.BLUE, Rect2(0, FOOT_Y, 150, 64), 20)
	back_button.name = "MakerBack"
	back_button.set_meta(&"pad_back", true)
	back_button.pressed.connect(back)
	next_button = _button("NEXT", &"down", UiKit.GREEN, Rect2(LEFT_W - 160, FOOT_Y, 160, 64), 22)
	next_button.name = "MakerNext"
	next_button.pressed.connect(next)
	note.position = Vector2(156, FOOT_Y)
	note.size = Vector2(LEFT_W - 156 - 166, 64)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note.max_lines_visible = 3
	note.add_theme_font_size_override("font_size", 14)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(note)
	preview_window.maker = self
	preview_window.position = Vector2(PREVIEW_X, 0)
	preview_window.size = PREVIEW_SIZE
	add_child(preview_window)
	preview.size = PREVIEW_SIZE
	preview_window.add_child(preview)
	preview_hint.text = "Your Short shows here"
	preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_hint.position = Vector2(20, 0)
	preview_hint.size = Vector2(PREVIEW_SIZE.x - 40, PREVIEW_SIZE.y)
	preview_hint.add_theme_font_size_override("font_size", 22)
	preview_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_window.add_child(preview_hint)
	type_field.max_length = MyShortRules.MAX_CAPTION
	type_field.placeholder_text = "Type here"
	type_field.add_theme_font_size_override("font_size", 18)
	type_field.text_submitted.connect(func(_t: String) -> void: _typed())
	type_field.focus_entered.connect(func() -> void: _game_keys(false))
	type_field.focus_exited.connect(func() -> void: _game_keys(true))
	set_process(false)


# --- Opening and closing -------------------------------------------------------------------------------------------------

## Opens the maker: a new Short, or `id`'s to change. False (and a word why) when this device keeps the most already.
func open(id: String = "") -> bool:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	reduce_motion = bool(profile.settings.get("reduce_motion", false))
	preview.reduce_motion = reduce_motion
	editing = id if profile.my_shorts.has(id) else ""
	recipe = profile.my_shorts.recipe(editing).duplicate(true) if editing != "" else {}
	visible = true
	set_process(true)
	if editing == "" and profile.my_shorts.is_full():
		_show_full()
		return false
	_go(PICK if editing != "" else KIND)
	return true


func is_open() -> bool:
	return visible


func close() -> void:
	if not visible:
		return
	_game_keys(true)
	preview.pause()
	visible = false
	set_process(false)
	MyShortAlbum.tidy(profile.my_shorts.files())
	closed.emit()


## A step back (Android Back, Circle / B, Esc, BACK): the first step closes the maker. False when it was not open.
func back() -> bool:
	if not visible:
		return false
	if type_field.is_inside_tree() and type_field.visible and type_field.has_focus():
		type_field.release_focus()
	if step == KIND or (editing != "" and step == PICK) or str(recipe.get("template", "")) == "":
		close()
	else:
		_go(step - 1)
	return true


func pad_back() -> bool:
	return back()


func next() -> void:
	if not _can_go_on():
		return
	if step == SAVE:
		_save()
	else:
		_go(step + 1)


# --- The steps -----------------------------------------------------------------------------------------------------------

func _go(to: int) -> void:
	step = clampi(to, KIND, SAVE)
	if step == WORDS:
		slot = "title"
	note.text = ""
	_build_page()
	_refresh()
	_dirty = true


func _refresh() -> void:
	for i in _pips.size():
		var on := i == step
		_pips[i].add_theme_color_override("font_color", INK if on else Color(1, 1, 1, 0.7))
		var box := UiKit.box(YELLOW if on else (PINK if i < step else CARD), 14, 0)
		_pips[i].add_theme_stylebox_override("normal", box)
	step_label.text = _step_words()
	next_button.text = "SAVE" if step == SAVE else "NEXT"
	(next_button.get_node("Icon") as ShortsIcon).set_shape(&"tick" if step == SAVE else &"down")
	next_button.visible = step != KIND
	next_button.disabled = not _can_go_on()
	back_button.text = "CLOSE" if step == KIND or (editing != "" and step == PICK) else "BACK"
	(back_button.get_node("Icon") as ShortsIcon).set_shape(&"cross" if back_button.text == "CLOSE" else &"up")
	if note.text == "" or note.get_meta(&"hint", false):
		note.text = _hint()
		note.set_meta(&"hint", true)
		note.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))


func _step_words() -> String:
	match step:
		KIND:
			return "What kind of Short?"
		PICK:
			match str(recipe.get("template", "")):
				MyShortRules.BUILT:
					return "Pick 2 to 4 photos"
				MyShortRules.FACTS:
					return "What is it about?"
				MyShortRules.STEPS:
					return "Pick a build"
		WORDS:
			return "Your words"
		LOOK:
			return "Look and sound"
		SAVE:
			return "Watch it, then SAVE"
	return ""


func _hint() -> String:
	match step:
		PICK:
			if recipe.get("template") == MyShortRules.BUILT:
				return "%d of 2-4 picked" % (recipe.get("photos", []) as Array).size()
		WORDS:
			return "Tap words to hear them"
	return ""


func _can_go_on() -> bool:
	return step != KIND and not MyShortRules.clean_recipe(_full_recipe()).is_empty()


## The recipe as it is, with the choices not made yet at their first.
func _full_recipe() -> Dictionary:
	var r := recipe.duplicate(true)
	if r.has("id"):
		r.erase("id")
	return r


func _build_page() -> void:
	_close_typing()
	_slot_rows.clear()
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	match step:
		KIND:
			_kind_page()
		PICK:
			match str(recipe.get("template", "")):
				MyShortRules.BUILT:
					_photos_page()
				MyShortRules.FACTS:
					_things_page()
				MyShortRules.STEPS:
					_builds_page()
		WORDS:
			_words_page()
		LOOK:
			_look_page()
		SAVE:
			_save_page()
	_mark_first()


## A controller's focus starts on the page's first choice (else NEXT or SAVE), never on the preview or BACK.
func _mark_first() -> void:
	for b: Control in [back_button, next_button, preview_window]:
		b.remove_meta(&"pad_first")
	for c in content.find_children("*", "BaseButton", true, false):
		if c is BaseButton and not (c as BaseButton).disabled and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			c.set_meta(&"pad_first", true)
			return
	next_button.set_meta(&"pad_first", true)


# --- 1 KIND ----------------------------------------------------------------------------------------------------------------

func _kind_page() -> void:
	var icons := {MyShortRules.BUILT: &"camera", MyShortRules.FACTS: &"planet", MyShortRules.STEPS: &"stairs"}
	var colours := {MyShortRules.BUILT: PINK, MyShortRules.FACTS: Color("7b4bd6"), MyShortRules.STEPS: UiKit.ORANGE}
	for i in MyShortRules.TEMPLATES.size():
		var t: String = MyShortRules.TEMPLATES[i]
		var w: Dictionary = MyShortRules.TEMPLATE_WORDS[t]
		var card := _card(Rect2(i * 162.0, 4, 152, 300), colours[t])
		card.name = "Kind_" + t
		var pic := ShortsIcon.new(icons[t], 78.0)
		pic.position = Vector2(37, 26)
		pic.size = Vector2(78, 78)
		card.add_child(pic)
		card.add_child(_words_label(str(w.title), 20, Rect2(8, 120, 136, 64), true))
		card.add_child(_words_label(str(w.line), 15, Rect2(8, 190, 136, 90), false, Color(1, 1, 1, 0.85)))
		card.pressed.connect(choose_template.bind(t))


func choose_template(t: String) -> void:
	if not MyShortRules.TEMPLATES.has(t):
		return
	if recipe.get("template") != t:
		recipe = {"template": t, "backdrop": {MyShortRules.BUILT: "sky", MyShortRules.FACTS: "space",
			MyShortRules.STEPS: "paper"}[t], "music": "", "voice": true, "captions": []}
		if t == MyShortRules.BUILT:
			recipe.photos = []
	Audio.play(&"pop")
	_go(PICK)


# --- 2 PICK: photos ---------------------------------------------------------------------------------------------------------

func _photos_page() -> void:
	_photos = MyShortAlbum.photos()
	if _photos.is_empty():
		var card := _card(Rect2(40, 40, 400, 260), CARD)
		card.disabled = true
		var pic := ShortsIcon.new(&"camera", 70.0)
		pic.position = Vector2(165, 24)
		pic.size = Vector2(70, 70)
		card.add_child(pic)
		card.add_child(_words_label(NO_PHOTOS, 18, Rect2(20, 110, 360, 130), false))
		return
	var pages := ceili(float(_photos.size()) / PHOTOS_PER_PAGE)
	photo_page = clampi(photo_page, 0, pages - 1)
	var picked: Array = recipe.get("photos", [])
	for k in PHOTOS_PER_PAGE:
		var i := photo_page * PHOTOS_PER_PAGE + k
		if i >= _photos.size():
			break
		var ph: Dictionary = _photos[i]
		var b := PhotoTile.new(ph, picked.find(ph.file) + 1)
		b.position = Vector2((k % 3) * 160.0, 4 + (k / 3) * 94.0)
		b.size = Vector2(152, 86)
		b.name = "Photo_%d" % i
		b.pressed.connect(toggle_photo.bind(i))
		content.add_child(b)
	if pages > 1:
		_page_buttons(photo_page, pages, func(p: int) -> void:
			photo_page = p
			_build_page())


## A photo picked or put back (its number shows the order it plays in).
func toggle_photo(i: int) -> void:
	if i < 0 or i >= _photos.size():
		return
	var ph: Dictionary = _photos[i]
	var picked: Array = recipe.get("photos", [])
	if picked.has(ph.file):
		picked.erase(ph.file)
	elif picked.size() >= MyShortRules.MAX_PHOTOS:
		_say("4 photos at most: tap one to put it back.")
		return
	else:
		picked.append(ph.file)
		_import(ph)
		Audio.play(&"pop")
	recipe.photos = picked
	for c in content.get_children():   # the tiles' numbers change in place
		if c is PhotoTile:
			(c as PhotoTile).number = picked.find((c as PhotoTile).photo.file) + 1
			c.queue_redraw()
	_refresh()
	_dirty = true


## A folder's photo is copied into the album on a worker thread (a phone takes a moment); the preview shows it then.
func _import(ph: Dictionary) -> void:
	var file := str(ph.file)
	if FileAccess.file_exists(MyShortAlbum.photo_path(file)) or _importing.has(file):
		return
	_importing[file] = WorkerThreadPool.add_task(func() -> void: MyShortAlbum.import_photo(ph), false, "My Shorts import")


## Every photo being copied, done (tests; SAVE waits for them).
func finish_imports() -> void:
	for file: String in _importing:
		WorkerThreadPool.wait_for_task_completion(int(_importing[file]))
	if not _importing.is_empty():
		_importing.clear()
		_photo_version += 1
		_dirty = true


# --- 2 PICK: a subject ------------------------------------------------------------------------------------------------------

func _things_page() -> void:
	var subject: Dictionary = recipe.get("subject", {})
	if subject.has("kind"):
		thing_kind = str(subject.kind)
	for i in MyShortFacts.KINDS.size():
		var k: String = MyShortFacts.KINDS[i]
		var chip := _chip(MyShortFacts.kind_words(k), Rect2(i * 162.0, 0, 152, 44), k == thing_kind)
		chip.name = "Subject_" + k
		chip.pressed.connect(func() -> void:
			thing_kind = k
			thing_page = 0
			_build_page())
	var list := MyShortFacts.things(thing_kind)
	var pages := ceili(float(list.size()) / THINGS_PER_PAGE)
	thing_page = clampi(thing_page, 0, maxi(pages - 1, 0))
	for k in THINGS_PER_PAGE:
		var i := thing_page * THINGS_PER_PAGE + k
		if i >= list.size():
			break
		var id: String = list[i]
		var on: bool = subject.get("kind") == thing_kind and subject.get("id") == id
		var b := ThingTile.new(thing_kind, id, on)
		b.position = Vector2((k % 4) * 120.0, 52 + (k / 4) * 134.0)
		b.size = Vector2(112, 126)
		b.name = "Thing_" + id
		b.pressed.connect(choose_subject.bind(thing_kind, id))
		content.add_child(b)
	if pages > 1:
		_page_buttons(thing_page, pages, func(p: int) -> void:
			thing_page = p
			_build_page())


func choose_subject(kind: String, id: String) -> void:
	if not MyShortFacts.has(kind, id):
		return
	recipe.subject = {"kind": kind, "id": id}
	recipe.facts = [0, 1, 2]
	recipe.title = ""
	Audio.play(&"pop")
	ReadAloud.speak(MyShortFacts.name_of(kind, id))
	_build_page()
	_refresh()
	_dirty = true


# --- 2 PICK: a build ----------------------------------------------------------------------------------------------------------

func _builds_page() -> void:
	var tiles: Array[Dictionary] = []
	var book := MyStampBook.current()
	for slot_i in book.slots():
		var blocks := book.blocks_of(slot_i)
		if MyShortRules.layers_of(blocks) >= MyShortRules.MIN_STEPS:
			tiles.append({"kind": "stamp", "slot": slot_i, "blocks": blocks, "name": MyStampBook.name_of(slot_i),
				"key": "stamp:%d:%d" % [slot_i, int(book.stamp(slot_i).get("at", 0))]})
	for id: String in MyShortRules.BLUEPRINTS:
		tiles.append({"kind": "blueprint", "id": id, "blocks": Blueprints.local(int(MyShortRules.BLUEPRINTS[id])),
			"name": MyShortRules.blueprint_name(id).capitalize(), "key": "bp:" + id})
	var build: Dictionary = recipe.get("build", {})
	for k in mini(tiles.size(), THINGS_PER_PAGE + 3):
		var t: Dictionary = tiles[k]
		var on: bool = (t.kind == "blueprint" and build.get("id") == t.get("id")) \
			or (t.kind == "stamp" and build.get("slot") == t.get("slot") and build.get("kind") == "stamp")
		var b := BuildTile.new(str(t.key), t.blocks, str(t.name), on)
		b.position = Vector2((k % 4) * 120.0, 4 + (k / 4) * 126.0)
		b.size = Vector2(112, 118)
		b.name = "Build_%d" % k
		b.pressed.connect(choose_build.bind(t))
		content.add_child(b)
	if book.slots().is_empty():
		content.add_child(_words_label(NO_STAMPS, 15, Rect2(0, 260, LEFT_W, 60), false, Color(1, 1, 1, 0.75)))


func choose_build(t: Dictionary) -> void:
	if t.kind == "blueprint":
		recipe.build = {"kind": "blueprint", "id": str(t.id)}
	else:
		var file := MyShortAlbum.keep_build(BuildCodec.encode(t.blocks), _now())
		if file == "":
			_say("That stamp could not be copied. Try another!")
			return
		recipe.build = {"kind": "stamp", "file": file, "layers": MyShortRules.layers_of(t.blocks), "slot": int(t.slot)}
	recipe.title = ""
	Audio.play(&"pop")
	_build_page()
	_refresh()
	_dirty = true


# --- 3 WORDS ----------------------------------------------------------------------------------------------------------------

## The slots a child fills: the title, each scene's words, the ending.
func slots() -> Array[String]:
	var out: Array[String] = ["title"]
	var n := 0
	match str(recipe.get("template", "")):
		MyShortRules.BUILT:
			n = (recipe.get("photos", []) as Array).size()
		MyShortRules.FACTS:
			n = MyShortRules.FACT_COUNT
		MyShortRules.STEPS:
			n = MyShortRules.steps_for(MyShortMaker.build_layers(recipe.get("build", {})))
	for k in n:
		out.append("body:%d" % k)
	out.append("ending")
	return out


func _slot_name(s: String) -> String:
	if s == "title":
		return "TITLE"
	if s == "ending":
		return "THE END"
	var k := int(s.trim_prefix("body:"))
	match str(recipe.template):
		MyShortRules.BUILT:
			return "PHOTO %d" % (k + 1)
		MyShortRules.FACTS:
			return "FACT %d" % (k + 1)
	return "STEP %d" % (k + 1)


## The words a slot shows now (the maker's own when the child chose none).
func slot_words(s: String) -> String:
	var short := MyShortMaker.make(_full_recipe())
	var i := slots().find(s)
	if short.is_empty() or i < 0 or i >= (short.scenes as Array).size():
		return ""
	return str(short.scenes[i].caption)


func _words_page() -> void:
	var list := slots()
	_slot_rows.clear()
	for i in list.size():
		var s: String = list[i]
		var row := _chip("", Rect2(0, i * 52.0, 220, 48), s == slot)
		row.name = "Slot_" + s.replace(":", "_")
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.clip_text = true
		row.add_theme_font_size_override("font_size", 14)
		row.pressed.connect(choose_slot.bind(s))
		_slot_rows[s] = row
	_refresh_slot_rows()
	var scroll := ScrollContainer.new()
	scroll.name = "Phrases"
	scroll.position = Vector2(232, 0)
	scroll.size = Vector2(LEFT_W - 232, CONTENT_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_fill_phrases()


## Each slot's row: its name and its words now (the Short made once), the slot being changed lit.
func _refresh_slot_rows() -> void:
	var short := MyShortMaker.make(_full_recipe())
	var list := slots()
	for s: String in _slot_rows:
		var row: Button = _slot_rows[s]
		var i := list.find(s)
		var words := str(short.scenes[i].caption) if not short.is_empty() and i >= 0 and i < (short.scenes as Array).size() else ""
		row.text = "%s  %s" % [_slot_name(s), words]
		_light(row, s == slot)


## The quick phrases (and TYPE MY OWN) for the slot being changed.
func _fill_phrases() -> void:
	var scroll := content.get_node_or_null("Phrases") as ScrollContainer
	if scroll == null:
		return
	for c in scroll.get_children():
		scroll.remove_child(c)
		c.queue_free()
	scroll.scroll_vertical = 0
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = LEFT_W - 244
	col.add_theme_constant_override("separation", 6)
	scroll.add_child(col)
	for p: String in phrases(slot):
		var b := _phrase_button(p)
		b.pressed.connect(choose_words.bind(p))
		col.add_child(b)
	if can_type(slot):
		var t := _phrase_button("TYPE MY OWN")
		t.name = "TypeOwn"
		t.add_theme_stylebox_override("normal", UiKit.box(UiKit.BLUE, 12, 6))
		var pic := ShortsIcon.new(&"pencil", 24.0)
		pic.position = Vector2(8, 10)
		pic.size = Vector2(24, 24)
		t.add_child(pic)
		t.pressed.connect(start_typing)
		col.add_child(t)


func choose_slot(s: String) -> void:
	slot = s
	_close_typing()
	var phrases_list := content.get_node_or_null("Phrases") as Control
	if phrases_list == null:
		_build_page()
	else:
		phrases_list.visible = true
		_refresh_slot_rows()
		_fill_phrases()
	_seek_preview(slots().find(s))


## The quick phrases a slot offers (read aloud when tapped).
func phrases(s: String) -> Array[String]:
	var t := str(recipe.get("template", ""))
	var out: Array[String] = []
	if s == "ending":
		for p: String in MyShortRules.ENDINGS.get(t, []):
			out.append(p)
		return out
	if s == "title":
		match t:
			MyShortRules.BUILT:
				for p: String in MyShortRules.TITLES[MyShortRules.BUILT]:
					out.append(p)
			MyShortRules.FACTS:
				var sub: Dictionary = recipe.get("subject", {})
				var name := MyShortFacts.name_of(str(sub.get("kind", "")), str(sub.get("id", "")))
				out.append(MyShortFacts.title_for(str(sub.get("kind", "")), str(sub.get("id", ""))))
				for p: String in ["All about %s", "%s is amazing!", "Did you know? %s"]:
					var w := p % name
					if w.length() <= MyShortRules.MAX_TITLE:
						out.append(w)
			MyShortRules.STEPS:
				for p: String in MyShortRules.STEP_TITLES:
					out.append(p % MyShortMaker.build_name(recipe.get("build", {})))
		return out
	match t:
		MyShortRules.BUILT:
			for p: String in MyShortRules.PHOTO_PHRASES:
				out.append(p)
		MyShortRules.FACTS:
			var sub: Dictionary = recipe.get("subject", {})
			for f in MyShortFacts.facts(str(sub.get("kind", "")), str(sub.get("id", ""))):
				out.append(f)
		MyShortRules.STEPS:
			for p: String in MyShortRules.STEP_PHRASES:
				out.append(p)
	return out


## Whether a slot takes typed words (a title and a photo's or a step's words; facts and endings are picked).
func can_type(s: String) -> bool:
	return s == "title" or (s.begins_with("body:") and recipe.get("template") != MyShortRules.FACTS)


## A quick phrase for the slot being changed (read aloud).
func choose_words(words: String) -> void:
	_set_slot(slot, words)
	ReadAloud.speak(words)


func _set_slot(s: String, words: String) -> void:
	if s == "title":
		recipe.title = words
	elif s == "ending":
		recipe.ending = words
	else:
		var k := int(s.trim_prefix("body:"))
		if recipe.get("template") == MyShortRules.FACTS:
			var facts := MyShortFacts.facts(str(recipe.subject.kind), str(recipe.subject.id))
			var i := facts.find(words)
			if i < 0:
				return
			var picks: Array = MyShortRules._clean_facts(recipe.get("facts", []), facts.size())
			var was := picks.find(i)
			if was >= 0:
				picks[was] = picks[k]   # already in another slot: the two swap
			picks[k] = i
			recipe.facts = picks
		else:
			var captions: Array = recipe.get("captions", [])
			while captions.size() <= k:
				captions.append("")
			captions[k] = words
			recipe.captions = captions
	if _slot_rows.is_empty():
		_build_page()
	else:
		_refresh_slot_rows()   # only the words change: the page stays (a phone rebuilds nothing more)
	_dirty = true
	_seek_preview(slots().find(s))


func start_typing() -> void:
	_close_typing()
	var most := MyShortRules.MAX_TITLE if slot == "title" else MyShortRules.MAX_CAPTION
	type_field.max_length = most
	type_field.text = ""
	var phrases_list := content.get_node_or_null("Phrases") as Control
	if phrases_list:
		phrases_list.visible = false   # the field takes the phrases' place, at the top (above a phone's keyboard)
	type_field.position = Vector2(232, 0)
	type_field.size = Vector2(LEFT_W - 232, 56)
	content.add_child(type_field)
	type_ok = _button("OK", &"tick", UiKit.GREEN, Rect2(232, 64, LEFT_W - 232, 56), 20)
	type_ok.name = "TypeOk"
	remove_child(type_ok)
	content.add_child(type_ok)
	type_ok.pressed.connect(_typed)
	type_field.grab_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_show(type_field.text)


## Typed words: the game's word filter for children, English letters, no names; kind words when they can't be used.
func type_words(text: String) -> bool:
	var most := MyShortRules.MAX_TITLE if slot == "title" else MyShortRules.MAX_CAPTION
	var r := MyShortRules.check_words(text, most, _names())
	if r.has("error"):
		_say(MyShortRules.message(str(r.error)), true)
		return false
	_set_slot(slot, str(r.text))
	return true


func _typed() -> void:
	if type_words(type_field.text):
		_close_typing()
		_build_page()


func _close_typing() -> void:
	if type_field.get_parent() != null:
		type_field.release_focus()
		type_field.get_parent().remove_child(type_field)
	if type_ok != null and is_instance_valid(type_ok):
		type_ok.queue_free()
		type_ok = null
	_game_keys(true)
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()


## Names a Short never shows: the child's username (and the name the profile keeps).
func _names() -> Array:
	return [profile.username] if profile != null else []


# --- 4 LOOK -------------------------------------------------------------------------------------------------------------------

func _look_page() -> void:
	content.add_child(_words_label("BACKDROP", 16, Rect2(0, 0, 200, 22), false))
	for i in MyShortRules.BACKDROPS.size():
		var b: String = MyShortRules.BACKDROPS[i]
		var sw := BackdropSwatch.new(b, recipe.get("backdrop") == b)
		sw.position = Vector2(i * 53.0, 26)
		sw.size = Vector2(48, 86)
		sw.name = "Backdrop_" + b
		sw.pressed.connect(choose_backdrop.bind(b))
		content.add_child(sw)
	content.add_child(_words_label("MUSIC", 16, Rect2(0, 124, 200, 22), false))
	for i in MyShortRules.MUSIC.size():
		var m: String = MyShortRules.MUSIC[i]
		var chip := _chip(str(MUSIC_WORDS.get(m, m)), Rect2((i % 4) * 120.0, 150 + (i / 4) * 48.0, 114, 42),
			recipe.get("music", "") == m)
		chip.name = "Music_" + (m if m != "" else "none")
		chip.add_theme_font_size_override("font_size", 14)
		chip.disabled = m != "" and not MusicPieces.present(StringName(m))
		chip.pressed.connect(choose_music.bind(m))
	content.add_child(_words_label("VOICE", 16, Rect2(0, 256, 200, 22), false))
	for i in 2:
		var on := i == 0
		var b := _chip("VOICE ON" if on else "VOICE OFF", Rect2(i * 162.0, 282, 152, 56), bool(recipe.get("voice", true)) == on)
		b.name = "Voice_" + ("on" if on else "off")
		b.pressed.connect(choose_voice.bind(on))


func choose_backdrop(b: String) -> void:
	if MyShortRules.BACKDROPS.has(b):
		recipe.backdrop = b
		_relight_look()
		_dirty = true


func choose_music(m: String) -> void:
	if MyShortRules.MUSIC.has(m):
		recipe.music = m
		_relight_look()
		_dirty = true
		_play_after_build = m != ""


func choose_voice(on: bool) -> void:
	recipe.voice = on
	_relight_look()
	_dirty = true


## LOOK's choices lit in place (the page stays).
func _relight_look() -> void:
	if step != LOOK:
		return
	for c in content.get_children():
		if c is BackdropSwatch:
			(c as BackdropSwatch).set_on(String(c.name).trim_prefix("Backdrop_") == recipe.get("backdrop"))
		elif c is Button and String(c.name).begins_with("Music_"):
			var m := String(c.name).trim_prefix("Music_")
			_light(c, (m if m != "none" else "") == recipe.get("music", ""))
		elif c is Button and String(c.name).begins_with("Voice_"):
			_light(c, (String(c.name) == "Voice_on") == bool(recipe.get("voice", true)))


# --- 5 SAVE -------------------------------------------------------------------------------------------------------------------

func _save_page() -> void:
	var short := MyShortMaker.make(_full_recipe())
	content.add_child(_words_label(str(short.get("title", "")), 30, Rect2(0, 20, LEFT_W, 90), true))
	var kind := str(MyShortRules.TEMPLATE_WORDS.get(str(recipe.get("template", "")), {}).get("title", ""))
	content.add_child(_words_label("%s · %d seconds" % [kind, roundi(ShortTimeline.length(short))], 18,
		Rect2(0, 120, LEFT_W, 30), true, Color(1, 1, 1, 0.85)))
	var pic := ShortsIcon.new(&"person", 64.0, YELLOW)
	pic.position = Vector2(LEFT_W * 0.5 - 32, 170)
	pic.size = Vector2(64, 64)
	content.add_child(pic)
	content.add_child(_words_label(STAYS, 18, Rect2(30, 246, LEFT_W - 60, 60), true))
	_play_after_build = true


func _save() -> void:
	finish_imports()
	var r := _full_recipe()
	r.erase("slot")
	if r.get("build") is Dictionary:
		(r.build as Dictionary).erase("slot")
	var id := editing
	if editing != "":
		if not profile.my_shorts.replace(editing, r, _now()):
			_say("That Short could not be kept. Try again!", true)
			return
	else:
		id = profile.my_shorts.add(r, _now())
		if id == "":
			_show_full()
			return
	save_profile.call()
	Audio.play(&"jingle_goal")
	close()
	saved.emit(id)


func _show_full() -> void:
	step = KIND
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	var card := _card(Rect2(40, 40, 400, 240), CARD)
	card.disabled = true
	card.add_child(_words_label(FULL % MyShortRules.MAX_SHORTS, 20, Rect2(20, 30, 360, 180), true))
	_refresh()
	next_button.visible = false
	step_label.text = "MY SHORTS is full"


# --- The preview -------------------------------------------------------------------------------------------------------------

func _process(_delta: float) -> void:
	for file: String in _importing.keys():
		if WorkerThreadPool.is_task_completed(int(_importing[file])):
			WorkerThreadPool.wait_for_task_completion(int(_importing[file]))
			_importing.erase(file)
			_photo_version += 1   # the preview's photo is in the album now
			_dirty = true
	if _dirty:
		_dirty = false
		_rebuild_preview()


## The Short as it is now in the player (built again only when the recipe changed).
func _rebuild_preview() -> void:
	var short := MyShortMaker.make(_full_recipe())
	var json := JSON.stringify(short) + ":%d" % _photo_version
	preview_hint.visible = short.is_empty()
	preview.visible = not short.is_empty()
	if short.is_empty():
		preview.pause()
		_built_json = ""
		return
	if json != _built_json:
		_built_json = json
		preview.build(short)
		if step == WORDS:
			_seek_preview(slots().find(slot))
		elif step == PICK and recipe.get("template") == MyShortRules.BUILT:
			_seek_preview(1)
	if _play_after_build:
		_play_after_build = false
		preview.play(true)
	_refresh()


func _seek_preview(scene: int) -> void:
	if not preview.is_built() or scene < 0:
		return
	preview.pause()
	var scenes := ShortTimeline.scenes(preview.short)
	if scene >= scenes.size():
		return
	preview.seek(ShortTimeline.scene_start(preview.short, scene) + minf(2.6, ShortTimeline.seconds_of(scenes[scene]) - 0.1))


## The Short being made, as a recipe (tests).
func current_short() -> Dictionary:
	return MyShortMaker.make(_full_recipe())


# --- Pieces --------------------------------------------------------------------------------------------------------------------

func _say(words: String, problem: bool = false) -> void:
	note.text = words
	note.set_meta(&"hint", false)
	note.add_theme_color_override("font_color", Color("ff9a8a") if problem else YELLOW)


## While typing, the keyboard's game keys must not play the game (as the chat does): out of the Input Map meanwhile.
func _game_keys(on: bool) -> void:
	if on == not _keys_off:
		return
	_keys_off = not on
	if on:
		for action: StringName in _stashed_keys:
			if InputMap.has_action(action):
				for e: InputEvent in _stashed_keys[action]:
					InputMap.action_add_event(action, e)
		_stashed_keys.clear()
		return
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		_stashed_keys[action] = InputMap.action_get_events(action)
		InputMap.action_erase_events(action)
		Input.action_release(action)


func _exit_tree() -> void:
	_game_keys(true)
	for file: String in _importing:
		WorkerThreadPool.wait_for_task_completion(int(_importing[file]))
	_importing.clear()


func _now() -> int:
	return int(clock.call()) if clock.is_valid() else int(Time.get_unix_time_from_system())


func _button(text: String, icon: StringName, colour: Color, r: Rect2, font: int) -> Button:
	var b := UiKit.big_button(text, colour, r.size)
	for state: String in ["normal", "hover", "pressed"]:
		var c := colour.lightened(0.12) if state == "hover" else (colour.darkened(0.15) if state == "pressed" else colour)
		b.add_theme_stylebox_override(state, UiKit.box(c, 16, 6))
	b.add_theme_stylebox_override("disabled", UiKit.box(Color(0.22, 0.22, 0.26, 0.75), 16, 6))
	b.add_theme_font_size_override("font_size", font)
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		(b.get_theme_stylebox(state) as StyleBoxFlat).content_margin_right = 14
	var side := minf(r.size.y * 0.5, 30.0)
	var pic := ShortsIcon.new(icon, side)
	pic.name = "Icon"
	pic.position = Vector2(12, (r.size.y - side) * 0.5)
	pic.size = Vector2(side, side)
	b.add_child(pic)
	add_child(b)
	return b


## A big tappable card in the content area.
func _card(r: Rect2, colour: Color) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	b.add_theme_stylebox_override("normal", UiKit.box(colour, 18, 0))
	b.add_theme_stylebox_override("hover", UiKit.box(colour.lightened(0.1), 18, 0))
	b.add_theme_stylebox_override("pressed", UiKit.box(colour.darkened(0.15), 18, 0))
	b.add_theme_stylebox_override("disabled", UiKit.box(colour, 18, 0))
	content.add_child(b)
	return b


## A choice (lit when chosen: pink with a yellow rim).
func _chip(text: String, r: Rect2, on: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.text = text
	b.position = r.position
	b.size = r.size
	b.add_theme_font_size_override("font_size", 16)
	var lit := UiKit.box(PINK, 12, 8)
	lit.border_color = YELLOW
	lit.set_border_width_all(3)
	var base := lit if on else UiKit.box(CARD, 12, 8)
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("hover", lit if on else UiKit.box(CARD.lightened(0.12), 12, 8))
	b.add_theme_stylebox_override("pressed", lit)
	b.add_theme_stylebox_override("disabled", UiKit.box(Color(0.2, 0.2, 0.24, 0.6), 12, 8))
	b.set_meta(&"on", on)
	content.add_child(b)
	return b


## A choice lit (pink with a yellow rim) or not.
func _light(b: Button, on: bool) -> void:
	if bool(b.get_meta(&"on", false)) == on:
		return
	var lit := UiKit.box(PINK, 12, 8)
	lit.border_color = YELLOW
	lit.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", lit if on else UiKit.box(CARD, 12, 8))
	b.add_theme_stylebox_override("hover", lit if on else UiKit.box(CARD.lightened(0.12), 12, 8))
	b.set_meta(&"on", on)


func _phrase_button(text: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.text = text
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(LEFT_W - 244, 46)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_stylebox_override("normal", UiKit.box(CARD, 12, 8))
	b.add_theme_stylebox_override("hover", UiKit.box(CARD.lightened(0.12), 12, 8))
	b.add_theme_stylebox_override("pressed", UiKit.box(PINK, 12, 8))
	if text == "TYPE MY OWN":
		(b.get_theme_stylebox("normal") as StyleBoxFlat).content_margin_left = 40
	return b


func _words_label(text: String, font: int, r: Rect2, centre: bool, colour: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # before the size: else the size grows to the unwrapped line
	l.text = text
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centre else HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER if centre else VERTICAL_ALIGNMENT_TOP
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _page_buttons(page: int, pages: int, go: Callable) -> void:
	var y := CONTENT_H - 50
	var prev := _chip("◀", Rect2(0, y, 70, 44), false)
	prev.name = "PagePrev"
	prev.disabled = page <= 0
	prev.pressed.connect(func() -> void: go.call(page - 1))
	content.add_child(_words_label("%d of %d" % [page + 1, pages], 16, Rect2(80, y, 120, 44), true))
	var nxt := _chip("▶", Rect2(210, y, 70, 44), false)
	nxt.name = "PageNext"
	nxt.disabled = page >= pages - 1
	nxt.pressed.connect(func() -> void: go.call(page + 1))


## The preview's window: a tap (or Cross / A) plays and pauses the Short being made.
class PreviewWindow:
	extends Control
	var maker: MyShortMakerView

	func _init() -> void:
		name = "MakerPreview"
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		var touch := event as InputEventScreenTouch
		if (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) or (touch and touch.pressed):
			pad_press()
			accept_event()

	func pad_press() -> bool:
		if maker and maker.preview.is_built():
			maker.preview.toggle()
		return true

	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.03, 0.03, 0.06)
		box.set_corner_radius_all(12)
		draw_style_box(box, Rect2(Vector2.ZERO, size))


## A photo to pick: the picture (loaded on a worker), its order number once picked.
class PhotoTile:
	extends Button
	var photo: Dictionary
	var number := 0
	var _tex: Texture2D

	func _init(p: Dictionary, n: int) -> void:
		photo = p
		number = n
		focus_mode = Control.FOCUS_NONE
		flat = true
		var path := str(p.get("path", ""))
		var ref: WeakRef = weakref(self)
		_tex = MyShortAlbum.texture(path, func(t: Texture2D) -> void:
			var me: PhotoTile = ref.get_ref()
			if me != null:
				me._tex = t
				me.queue_redraw())

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if _tex != null:
			MyShortDrawers.draw_cover(self, _tex, r)
		else:
			draw_rect(r, MyShortDrawers.EMPTY)
			MyShortDrawers.draw_camera(self, r.grow(-20), Color(1, 1, 1, 0.7))
		if number > 0:
			draw_rect(r, MyShortMakerView.YELLOW, false, 5.0)
			draw_circle(Vector2(22, 22), 17, MyShortMakerView.YELLOW)
			var f := get_theme_default_font()
			draw_string(f, Vector2(5, 30), str(number), HORIZONTAL_ALIGNMENT_CENTER, 34, 22, MyShortMakerView.INK)


## A planet, a wonder or an animal to pick, with its name.
class ThingTile:
	extends Button
	var kind := ""
	var id := ""
	var on := false

	func _init(k: String, i: String, chosen: bool) -> void:
		kind = k
		id = i
		on = chosen
		focus_mode = Control.FOCUS_NONE
		flat = true
		var label := Label.new()
		label.text = MyShortFacts.name_of(k, i)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.max_lines_visible = 2
		label.add_theme_font_size_override("font_size", 13)
		label.position = Vector2(2, 86)
		label.size = Vector2(108, 38)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		var actor: Control
		match k:
			MyShortFacts.PLANET:
				actor = ShortActor.new({"kind": "planet", "body": i, "size": 62})
			MyShortFacts.WONDER:
				actor = ShortActor.new({"kind": "wonder", "id": i, "size": 76})
			_:
				actor = ShortActor.new({"kind": "character", "who": i, "size": 76})
		add_child(actor)
		actor.position = Vector2(56, 44) - actor.size * 0.5
		actor.visible = true

	func _draw() -> void:
		var box := UiKit.box(MyShortMakerView.PINK if on else MyShortMakerView.CARD, 12, 0)
		if on:
			box.border_color = MyShortMakerView.YELLOW
			box.set_border_width_all(3)
		draw_style_box(box, Rect2(Vector2.ZERO, size))


## A build to show step by step: its blocks from above a corner, its name.
class BuildTile:
	extends Button
	var on := false
	var _pic: MyShortDrawers.IsoBuild

	func _init(key: String, blocks: Dictionary, title: String, chosen: bool) -> void:
		on = chosen
		focus_mode = Control.FOCUS_NONE
		flat = true
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_pic = MyShortDrawers.IsoBuild.cached(key, func() -> Dictionary: return blocks)
		var label := Label.new()
		label.text = title
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.position = Vector2(2, 92)
		label.size = Vector2(108, 22)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)

	func _draw() -> void:
		var box := UiKit.box(MyShortMakerView.PINK if on else MyShortMakerView.CARD, 12, 0)
		if on:
			box.border_color = MyShortMakerView.YELLOW
			box.set_border_width_all(3)
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		_pic.paint(self, Rect2(8, 6, size.x - 16, 84), float(_pic.layers))


## A backdrop to pick: a small copy of the stage's backdrop (the chosen one framed, over its picture).
class BackdropSwatch:
	extends Button
	var on := false
	var _frame := Panel.new()

	func _init(kind: String, chosen: bool) -> void:
		focus_mode = Control.FOCUS_NONE
		flat = true
		clip_contents = true
		var back := ShortBackdrop.new()
		back.show_scene({"background": kind}, 0.0)
		back.scale = Vector2.ONE * (48.0 / ShortRules.STAGE.x)
		add_child(back)
		var box := StyleBoxFlat.new()
		box.draw_center = false
		box.border_color = MyShortMakerView.YELLOW
		box.set_border_width_all(4)
		_frame.add_theme_stylebox_override("panel", box)
		_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_frame)
		set_on(chosen)

	func set_on(chosen: bool) -> void:
		on = chosen
		_frame.visible = chosen
