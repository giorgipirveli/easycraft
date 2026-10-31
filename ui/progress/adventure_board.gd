class_name AdventureBoard
extends VBoxContainer
## The pause menu's BOARD page (M3 Task 12, spec §5.8, research R4 and R5): the level and its XP bar,
## the title on the name tag (the child picks among the earned ones), the three picture goals with
## their progress (a tap picks a new one from the list), the pet's present when one waits, and the
## trophy room. Pictures first, a few words each, nothing that expires. Reads and changes the progress
## through the Progress autoload.

signal closed

const CARD := Vector2(300, 260)
const TILE := Vector2(140, 150)
const COLUMNS := 8
const TITLE_ROWS := 6
const GOLD_TEXT := Color("ffd23f")

var level_label: Label
var xp_bar: ProgressBar
var xp_label: Label


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	show_board()


func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()


## The board: level, title, the three goals, a waiting present, TROPHIES and BACK.
func show_board() -> void:
	_clear()
	var d := Progress.data()
	BoardRules.ensure_board(d)
	add_child(UiKit.title("Adventure board", 42))
	add_child(_header(d))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in BoardRules.SLOTS:
		cards.add_child(_card(d, i))
	add_child(cards)
	if d.present_waiting:
		var present := picture_button(&"gift", "A present from your pet! Open it", Vector2(CARD.x * 3 + 32, 90), 30, true)
		present.name = "Present"
		present.pressed.connect(show_present)
		add_child(present)
	var row := _row()
	var trophies := UiKit.big_button("TROPHIES", UiKit.ORANGE, Vector2(300, 86))
	trophies.name = "Trophies"
	trophies.pressed.connect(show_trophies)
	row.add_child(trophies)
	row.add_child(_back(func() -> void: closed.emit()))
	add_child(row)


func _header(d: ProgressData) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(ProgressPicture.new(&"level", 64))
	level_label = Label.new()
	xp_bar = ProgressBar.new()
	xp_label = Label.new()
	level_label.text = tr("Level %d") % d.level()
	level_label.add_theme_font_size_override("font_size", 34)
	level_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(level_label)
	var bar_box := VBoxContainer.new()
	bar_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bar := LevelRules.level_progress(d.xp)
	xp_bar.custom_minimum_size = Vector2(320, 28)
	xp_bar.show_percentage = false
	xp_bar.max_value = maxf(float(bar.y), 1.0)
	xp_bar.value = float(bar.x)
	bar_box.add_child(xp_bar)
	xp_label.text = "%d / %d" % [bar.x, bar.y] if bar.y > 0 else "Top level!"
	xp_label.add_theme_font_size_override("font_size", 20)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar_box.add_child(xp_label)
	h.add_child(bar_box)
	var title := UiKit.big_button(LevelRules.title_text(Progress.shown_title()), UiKit.BLUE, Vector2(320, 72))
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 26)
	title.pressed.connect(show_titles)
	h.add_child(title)
	return h


## One goal card: its picture, words, progress and reward; done or empty cards invite a new pick.
func _card(d: ProgressData, slot: int) -> Button:
	var s: Dictionary = d.board[slot]
	var g := BoardRules.goal(StringName(str(s.goal)))
	var words := "Pick a goal!"
	var picture: StringName = &"board"
	if not g.is_empty():
		picture = g.picture
		words = ("Done! " if s.done else "") + str(g.words)
	var b := Button.new()
	b.name = "Card%d" % slot
	b.custom_minimum_size = CARD
	b.set_meta(&"words", words)
	b.pressed.connect(show_picker.bind(slot))
	b.pressed.connect(Audio.play.bind(&"ui_click"))
	if s.done:
		b.add_theme_stylebox_override("normal", UiKit.box(UiKit.GREEN.darkened(0.25)))
	var v := _inside(b, 12)
	v.add_child(ProgressPicture.new(picture, 84))
	v.add_child(_words(words, 26, CARD.x - 30))
	if not g.is_empty():
		var p := BoardRules.progress(d, slot)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(180, 22)
		bar.show_percentage = false
		bar.max_value = float(p.y)
		bar.value = float(p.x)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
		row.add_child(_words("%d/%d" % [p.x, p.y], 22, 0))
		v.add_child(row)
		v.add_child(_reward(g, 20) if not s.done else _words("Tap: a new goal", 20, 0))
	return b


func _reward(g: Dictionary, font: int) -> Label:
	var gold := int(g.gold)
	var l := _words(tr("+%d gold") % gold if gold > 0 and Progress.survivor.call() else "a sticker", font, 0)
	if gold > 0 and Progress.survivor.call():
		l.add_theme_color_override("font_color", GOLD_TEXT)
	return l


## The list of goals to pick for `slot`: every goal not on the board, as picture tiles.
func show_picker(slot: int) -> void:
	_clear()
	var d := Progress.data()
	add_child(UiKit.title("Pick a goal", 42))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(TILE.x * COLUMNS + 8 * (COLUMNS - 1), TILE.y * 3 + 16)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for id in BoardRules.choices(d):
		var g := BoardRules.goal(id)
		var t := Button.new()
		t.name = "Pick_%s" % id
		t.custom_minimum_size = TILE
		t.pressed.connect(_pick.bind(slot, id))
		t.pressed.connect(Audio.play.bind(&"ui_click"))
		var v := _inside(t, 4)
		v.add_theme_constant_override("separation", 2)
		v.add_child(ProgressPicture.new(g.picture, 52))
		v.add_child(_words(str(g.words), 17, TILE.x - 10))
		var got := int(d.stickers.get(String(id), 0))
		var reward := _reward(g, 15)
		if got > 0:
			reward.text += "  ★%d" % got
		v.add_child(reward)
		var where := where_words(id, Game.mode, Game.universe)   # owner #45a
		if where != "":
			var w := _words(where, 13, TILE.x - 8)
			w.name = "Where"
			w.add_theme_color_override("font_color", Color("b3e5fc"))
			v.add_child(w)
		grid.add_child(t)
	scroll.add_child(grid)
	add_child(scroll)
	var row := _row()
	row.add_child(_back(show_board))
	add_child(row)


## Owner #45a: where a goal counts when it isn't here ("in Monster Wave", "in the Sandstorm Desert"; "" here).
static func where_words(id: StringName, mode: StringName, universe: int) -> String:
	var modes := BoardRules.modes_of(id)
	var u := BoardRules.universe_of(id)
	if u > 0 and (u != universe or not modes.has(mode)):
		return QuestRules.in_universe(u)   # a universe's goal: its place says it all
	if not modes.has(mode):
		for m: StringName in [ModeRules.SURVIVOR, ModeRules.WAVE, ModeRules.SANDBOX]:
			if modes.has(m):
				return {ModeRules.SURVIVOR: "in Survivor", ModeRules.WAVE: "in Monster Wave",
					ModeRules.SANDBOX: "in the Sandbox"}[m]
	return ""


func _pick(slot: int, id: StringName) -> void:
	Progress.pick_goal(slot, id)
	show_board()


## The titles: every play style's, the earned ones to pick, the rest locked; or the one played most.
func show_titles() -> void:
	_clear()
	var d := Progress.data()
	add_child(UiKit.title("Your title", 42))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	var earned := LevelRules.earned_titles(d.style_xp)
	for style in LevelRules.STYLE_ORDER:
		var b := UiKit.big_button(LevelRules.title_text(style), UiKit.BLUE if earned.has(style) else Color(), Vector2(420, 64))
		b.name = "Title_%s" % style
		b.add_theme_font_size_override("font_size", 26)
		b.disabled = not earned.has(style)
		b.pressed.connect(_choose_title.bind(style))
		grid.add_child(b)
	for t in QuestRules.titles(d):   # owner #45a: the quest stories' titles, once each story is done
		var b := UiKit.big_button(LevelRules.title_text(t), UiKit.GREEN, Vector2(420, 64))
		b.name = "Title_%s" % t
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_choose_title.bind(t))
		grid.add_child(b)
	var scroll := ScrollContainer.new()   # 14 play styles and up to 9 stories: 6 rows show, the rest scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(420 * 2 + 12 + 12, 64 * TITLE_ROWS + 10 * (TITLE_ROWS - 1) + 4)
	scroll.add_child(grid)
	add_child(scroll)
	var row := _row()
	var auto := UiKit.big_button("MOST PLAYED", UiKit.GREEN, Vector2(300, 86))
	auto.name = "Title_auto"
	auto.pressed.connect(_choose_title.bind(&""))
	row.add_child(auto)
	row.add_child(_back(show_board))
	add_child(row)


func _choose_title(style: StringName) -> void:
	Progress.choose_title(style)
	show_board()


## The pet's present: three gifts to pick from (Sandbox stickers; Survivor gold or blocks from the host).
func show_present() -> void:
	_clear()
	var is_survivor: bool = Progress.survivor.call()
	add_child(UiKit.title("A present from your pet!", 42))
	add_child(_words("Pick one:", 28, 0))
	var row := _row()
	for id in PresentRules.gifts(is_survivor):
		var g := PresentRules.gift(id, is_survivor)
		var b := picture_button(g.picture, str(g.words), Vector2(260, 220), 28, false)
		b.name = "Gift_%s" % id
		b.pressed.connect(_open.bind(id))
		row.add_child(b)
	add_child(row)
	var back := _row()
	back.add_child(_back(show_board))
	add_child(back)


func _open(id: StringName) -> void:
	Progress.open_present(id)
	show_board()


func show_trophies() -> void:
	_clear()
	var room := TrophyRoom.new()
	room.closed.connect(show_board)
	add_child(room)


# --- Pieces ------------------------------------------------------------------------------------------

func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return row


func _back(action: Callable) -> Button:
	var b := UiKit.big_button("BACK", Color(), Vector2(300, 86))
	b.name = "Back"
	b.pressed.connect(action)
	return b


## A box filling a button (the button still takes the taps).
static func _inside(b: Button, margin: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, margin)
	return v


static func _words(text: String, font: int, width: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = width
	return l


## A big button with a picture and its words (side by side when `wide`, else the words under it).
static func picture_button(picture: StringName, words: String, min_size: Vector2, font: int, wide: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	b.add_theme_stylebox_override("normal", UiKit.box(UiKit.ORANGE))
	b.add_theme_stylebox_override("hover", UiKit.box(UiKit.ORANGE.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", UiKit.box(UiKit.ORANGE.darkened(0.15)))
	b.pressed.connect(Audio.play.bind(&"ui_click"))
	var box: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	b.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	box.add_child(ProgressPicture.new(picture, minf(min_size.y - 30.0, 110.0) if not wide else min_size.y - 24.0))
	var l := _words(words, font, 0.0 if wide else min_size.x - 20.0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(l)
	return b
