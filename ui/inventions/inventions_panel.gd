class_name InventionsPanel
extends Control
## Owner #78 (spec §21e): the Inventions book, "How people learned to fly", one paper page over the world (INVENT in
## MORE, I on a PC). A tab for each invention in history's order (its picture and its year; ✓ invented, pale while not
## yet in Survivor) and a page: the big picture, when and where, the real story (people of history), HOW IT WORKS (its
## science), what it opens in the game, and the School unit on its science. In Survivor also what it is made of at a
## Workbench (have / need), its price (free once the unit is mastered) and MAKE IT for the next one; TRY IT once it is
## invented; FLY WITH IT for a flying machine. In the Sandbox everything is open: TRY IT and FLY WITH IT for every
## one, and FREE FLYING back to the classic flying. The rocket's TRY IT is a bottle rocket in the book (BottleRocket).
## The director (InventionsDirector) does the making, the trying and the flying; the page only shows and asks.
## Mouse, keys (Esc closes), touch and game controllers (PadFocus watches it; Circle / B is BACK or X).

signal opened
signal closed
signal make_pressed(id: StringName)
signal try_pressed(id: StringName)
## FLY WITH IT (an invention id) or FREE FLYING (&"").
signal fly_pressed(id: StringName)

const PAGE_SIZE := Vector2(1200, 660)
const TAB_SIZE := Vector2(172, 112)
const TEXT_WIDTH := 800
const OK_INK := Color("1f7a3a")
const LATER_INK := Color("a8401a")

## () -> InventionData: what this child invented.
var data: Callable = func() -> InventionData: return Profile.data.inventions
## () -> bool: flying costs here (Survivor): the gates show.
var survivor: Callable = func() -> bool: return false
## (material) -> int: how much of a material (InventionLine.MATERIALS) the bag holds.
var have: Callable = func(_m: StringName) -> int: return 0
## () -> int: the child's gold.
var gold: Callable = func() -> int: return 0
## (id) -> bool: its School unit is mastered (it is free).
var mastered: Callable = func(_id: StringName) -> bool: return false
## () -> bool: a Workbench is within reach.
var near_workbench: Callable = func() -> bool: return false
## () -> int: the flying machine picked now (FlightCrafts.Craft).
var chosen: Callable = func() -> int: return FlightCrafts.Craft.NONE

## The invention on the page.
var shown: StringName = InventionLine.KITE
var page_panel := PanelContainer.new()
var close_button := BookKit.button("X", Vector2(72, 64), 30)
var make_button := BookKit.button("MAKE IT", Vector2(220, 72))
var try_button := BookKit.button("TRY IT", Vector2(200, 72))
var fly_button := BookKit.button("FLY WITH IT", Vector2(240, 72))
var free_button := BookKit.button("FREE FLYING", Vector2(240, 72))
var bottle := BottleRocket.new()

var _built := false
var _tabs := {}                     # id -> Button
var _tab_words := {}                # id -> Label
var _tab_pictures := {}             # id -> InventionPicture
var _picture := InventionPicture.new(&"kite", 250.0)
var _name := BookKit.label("", 36, BookKit.TITLE_INK)
var _when := BookKit.label("", 22, BookKit.SOFT_INK)
var _story := BookKit.label("", 19)
var _science := BookKit.label("", 19)
var _opens := BookKit.label("", 18, OK_INK)
var _safety := BookKit.label("", 16, LATER_INK)
var _school := BookKit.label("", 16, BookKit.SOFT_INK)
var _make_title := BookKit.label("", 19, BookKit.TITLE_INK)
var _needs := HBoxContainer.new()
var _price := BookKit.label("", 17, BookKit.SOFT_INK)
var _status := BookKit.label("", 22, OK_INK)
var _message := BookKit.label("", 19, LATER_INK)
var _page := VBoxContainer.new()
var _need_lines: Array[String] = []
var _buttons: Control


func _ready() -> void:
	name = "InventionsPanel"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(id: StringName = &"") -> void:
	_build()
	close_bottle()
	if InventionLine.has(id):
		shown = id
	else:
		var d: InventionData = data.call()
		var next := InventionRules.next(d)
		shown = next if bool(survivor.call()) and next != &"" else InventionLine.KITE
	say("")
	visible = true
	if PlatformRules.captures_mouse(PlatformRules.current()) and is_inside_tree():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh()
	_fit()
	Audio.play(&"ui_click")
	ReadAloud.auto(words())
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


## Android Back (and a pad's Circle / B from the page): true when it was open (the bottle rocket goes back first).
func close_if_open() -> bool:
	if not visible:
		return false
	if bottle_open():
		close_bottle()
	else:
		close()
	return true


func pad_back() -> bool:
	return close_if_open()


func show_invention(id: StringName) -> void:
	if not InventionLine.has(id):
		return
	_build()
	close_bottle()
	shown = id
	say("")
	refresh()


## invented / next (Survivor: the one to make now) / later / open (the Sandbox: everything).
func status(id: StringName) -> StringName:
	if not bool(survivor.call()):
		return &"open"
	var d: InventionData = data.call()
	if d.has(id):
		return &"invented"
	return &"next" if InventionRules.may_make(id, d) else &"later"


## The page and the tabs, filled fresh.
func refresh() -> void:
	_build()
	var e := InventionLine.entry(shown)
	var surv := bool(survivor.call())
	var d: InventionData = data.call()
	for id: StringName in InventionLine.ORDER:
		var st := status(id)
		(_tab_pictures[id] as InventionPicture).dim = st == &"later"
		(_tabs[id] as Button).modulate = Color.WHITE if id == shown else Color(1, 1, 1, 0.78)
		var mark := "✓ " if st == &"invented" else ""
		(_tab_words[id] as Label).text = "%s%s" % [mark, _year_words(id)]
	_picture.kind = e.picture
	_picture.dim = status(shown) == &"later"
	_name.text = str(e.name)
	_when.text = "%s · %s" % [e.when, e.where]
	_story.text = str(e.story)
	_science.text = Lang.t("How it works: %s") % e.science
	_opens.text = Lang.t("It opens: %s") % e.opens if surv else Lang.t("In Survivor it opens: %s") % e.opens
	_safety.text = str(e.get("safety", ""))
	_safety.visible = _safety.text != ""
	_school.text = Lang.t("In the School: %s") % InventionRules.unit_title(shown)
	var st := status(shown)
	var is_flyer := FlightCrafts.of_invention(shown) != FlightCrafts.Craft.NONE
	_fill_needs(surv and st != &"invented")
	_price.text = InventionRules.price_words(shown, bool(mastered.call(shown))) if surv and st != &"invented" else ""
	_price.visible = _price.text != ""
	_status.text = "Invented!" if st == &"invented" else ""
	_status.visible = _status.text != ""
	make_button.visible = surv and st == &"next"
	try_button.visible = not surv or st == &"invented"
	fly_button.visible = is_flyer and (not surv or st == &"invented")
	var picked := FlightCrafts.valid(int(chosen.call()))
	fly_button.text = "FLYING WITH IT" if is_flyer and picked == FlightCrafts.of_invention(shown) else "FLY WITH IT"
	free_button.visible = not surv and picked != FlightCrafts.Craft.NONE
	if surv and st == &"later":
		_say_quiet(Lang.t("Not yet: invent %s next. Each invention opens the next one!") %
			Lang.t(str(InventionLine.entry(InventionRules.next(d)).get("name", ""))))
	elif surv and st == &"next" and not bool(near_workbench.call()):
		_say_quiet(Lang.t("Make it at a Workbench: stand next to one, then MAKE IT."))


## "Sticks 2/4" for each material of the page's invention (Survivor, not invented yet).
func need_lines() -> Array[String]:
	return _need_lines.duplicate()


func price_text() -> String:
	return _price.text


func say(text: String) -> void:
	_message.text = text
	_message.visible = text != ""


func message() -> String:
	return _message.text


## What the speaker reads: the page.
func words() -> String:
	if bottle_open():
		return bottle.words()
	var parts: Array[String] = [_name.text, _when.text, _story.text, _science.text, _opens.text]
	if _safety.visible:
		parts.append(_safety.text)
	if _message.visible:
		parts.append(_message.text)
	return " ".join(parts)


func tab_ids() -> Array[StringName]:
	return InventionLine.ORDER.duplicate()


func tab_text(id: StringName) -> String:
	_build()
	return (_tab_words[id] as Label).text if _tab_words.has(id) else ""


func open_bottle() -> void:
	_build()
	bottle.reset()
	bottle.visible = true
	_page.visible = false
	_buttons.visible = false   # the bottle rocket has its own PUMP, LAUNCH and BACK
	_fit.call_deferred()   # the page's size follows next frame


func close_bottle() -> void:
	if not _built:
		return
	bottle.visible = false
	_page.visible = true
	_buttons.visible = true
	if visible:
		_fit.call_deferred()


func bottle_open() -> bool:
	return _built and bottle.visible


## What must not build or break under the book (LookBuildArea reads touches first).
func blockers() -> Array[Control]:
	return [self]


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


# --- building the book ---

func _build() -> void:
	if _built:
		return
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("f3e6c4")
	paper.border_color = Color("7a4a24")
	paper.set_border_width_all(8)
	paper.set_corner_radius_all(16)
	paper.set_content_margin_all(16)
	page_panel.add_theme_stylebox_override("panel", paper)
	page_panel.custom_minimum_size = Vector2(PAGE_SIZE.x, 0)
	center.add_child(page_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	page_panel.add_child(column)
	column.add_child(_head())
	column.add_child(_tab_row())
	column.add_child(_page_view())
	bottle.visible = false
	bottle.back_pressed.connect(close_bottle)
	column.add_child(bottle)
	_buttons = _button_row()
	column.add_child(_buttons)


func _head() -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var title := BookKit.label("How people learned to fly", 34, BookKit.TITLE_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(ReadAloud.button(words, 60.0))
	close_button.tooltip_text = "Close (Esc)"
	close_button.set_meta(&"pad_back", true)
	close_button.pressed.connect(close)
	head.add_child(close_button)
	return head


func _tab_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for id: StringName in InventionLine.ORDER:
		var b := BookKit.button("", TAB_SIZE, 16)
		b.name = "Tab_" + String(id)
		var inside := VBoxContainer.new()
		inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inside.alignment = BoxContainer.ALIGNMENT_CENTER
		inside.add_theme_constant_override("separation", 0)
		inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var pic := InventionPicture.new(StringName(InventionLine.entry(id).picture), 78.0)
		pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inside.add_child(pic)
		var word := BookKit.label("", 16)
		word.clip_text = true
		inside.add_child(word)
		b.add_child(inside)
		b.pressed.connect(func() -> void:
			Audio.play(&"ui_click")
			show_invention(id))
		row.add_child(b)
		_tabs[id] = b
		_tab_words[id] = word
		_tab_pictures[id] = pic
	return row


func _page_view() -> Control:
	_page.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_page.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.add_child(_picture)
	_status.custom_minimum_size.x = 250
	left.add_child(_status)
	row.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(TEXT_WIDTH + 30, 340)
	row.add_child(scroll)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 6)
	scroll.add_child(text)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 16)
	for l: Label in [_name, _when]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_row.add_child(l)
	text.add_child(title_row)
	for l: Label in [_story, _science, _opens, _safety, _school, _make_title, _price]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = TEXT_WIDTH
	var science_box := PanelContainer.new()
	science_box.add_theme_stylebox_override("panel", BookKit.card_box(Color(1, 1, 1, 0.45), 8))
	science_box.add_child(_science)
	text.add_child(_story)
	text.add_child(science_box)
	text.add_child(_opens)
	text.add_child(_safety)
	text.add_child(_school)
	_make_title.text = "Make it at a Workbench:"
	text.add_child(_make_title)
	_needs.add_theme_constant_override("separation", 10)
	text.add_child(_needs)
	text.add_child(_price)
	return _page


func _button_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	make_button.pressed.connect(func() -> void: make_pressed.emit(shown))
	try_button.pressed.connect(func() -> void: try_pressed.emit(shown))
	fly_button.pressed.connect(func() -> void: fly_pressed.emit(shown))
	free_button.pressed.connect(func() -> void: fly_pressed.emit(&""))
	make_button.set_meta(&"pad_first", true)
	for b: Button in [make_button, try_button, fly_button, free_button]:
		row.add_child(b)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.x = 420
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(_message)
	return row


func _fill_needs(on: bool) -> void:
	for c in _needs.get_children():
		_needs.remove_child(c)
		c.queue_free()
	_need_lines.clear()
	_make_title.visible = on
	_needs.visible = on
	if not on:
		return
	for n: Array in InventionLine.entry(shown).needs:
		var m: StringName = n[0]
		var got := int(have.call(m))
		var line := "%s %d/%d" % [InventionLine.material_name(m), mini(got, int(n[1])), int(n[1])]
		_need_lines.append(line)
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", BookKit.card_box(Color(1, 1, 1, 0.5), 6))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		chip.add_child(h)
		h.add_child(BookKit.picture(int(InventionLine.MATERIALS[m].ids[0]), 36.0))
		h.add_child(BookKit.label(line, 18, OK_INK if got >= int(n[1]) else LATER_INK))
		chip.tooltip_text = str(n[2])
		_needs.add_child(chip)


func _year_words(id: StringName) -> String:
	var y := int(InventionLine.entry(id).year)
	return "long ago" if y < 0 else ("the %ds" % (y - y % 10) if id == InventionLine.GLIDER else str(y))


## A line said by the page itself (it never covers the director's answer).
func _say_quiet(text: String) -> void:
	if _message.text == "":
		say(text)


## A screen smaller than the book draws it smaller.
func _fit() -> void:
	var room := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var need := page_panel.get_combined_minimum_size()
	var s := minf(1.0, minf((room.y - 12.0) / maxf(need.y, 1.0), (room.x - 12.0) / maxf(need.x, 1.0)))
	page_panel.scale = Vector2(s, s)
	page_panel.pivot_offset = need * 0.5
