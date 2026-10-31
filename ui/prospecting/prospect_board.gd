class_name ProspectBoard
extends Control
## Gemma the geologist's board (spec §26.2): walking up to her at her camp opens it, and so does DIG (MORE) or J on a PC
## anywhere in the world (the journal). One panel, big buttons, read aloud like the School, three views:
## - QUESTS: a card for each kind of deposit (its picture, its story's title, where it is found, how far the child has
##   come, START / GO ON / FIND ANOTHER; the other world's quests say where they are told).
## - A STEP of the quest being followed: its map, clue, problem or quiz as School exercises (ExercisePanel: a miss gets a
##   hint and another try, a second miss shows how; right the first time pays the School's answer gold); a walk says
##   where to go (the compass shows the way: LET'S GO); the last step MARK IT marks the deposit on MY MAP, then the find:
##   the gold, how it is dug out and refined, what it sells for.
## - MY FINDS: the deposits found in this world and how each is worked.
## It never holds the game still. Its model is the director's (Callables); what the child does goes back as signals.

signal opened
signal closed
## START / GO ON / FIND ANOTHER on a quest's card.
signal start_pressed(kind: StringName)
## Every exercise of the step being shown was answered: move the quest on.
signal step_answered(kind: StringName, step: int)
## MARK IT on the quest's last step.
signal mark_pressed(kind: StringName)

const QUESTS := &"quests"
const STEP := &"step"
const DONE := &"done"
const FINDS := &"finds"
const PANEL_SIZE := Vector2(1200, 660)
const GOLD_COLOR := Color("ffd23f")
const PAPER := Color("fdf6e3")
const CARD_TEXT := 226.0          # a quest card's words wrap in this width (beside its picture)

## () -> Array of {kind, title, story, where, here (this world tells it), status ("new", "going", "done"), step, steps,
## found (in this world)}.
var quests: Callable = func() -> Array: return []
## (kind) -> {kind, title, index, count, step (ProspectQuests' step)} of that quest's step now ({} for none).
var step_view: Callable = func(_kind: StringName) -> Dictionary: return {}
## () -> Array of {kind, name, pos: Vector3}: the deposits found in this world.
var finds: Callable = func() -> Array: return []
## (kind) -> int: metres from the child to the quest's walking step's place (-1: unknown).
var distance_to: Callable = func(_kind: StringName) -> int: return -1
## (x, z) -> Color: the ground's colour for the quest's map.
var map_sampler := Callable()
## The quest map's samples across (ProspectMap: fewer on the planets).
var map_samples := ProspectMap.SAMPLES
## () -> int: gold for an answer right the first time (EarnRules.answer_gold; the School's cap).
var first_try_gold := Callable()
## () -> int: the child's gold.
var gold: Callable = func() -> int: return 0
## A LAN guest: the deposits here are the host's (the quests start in the child's own world).
var guest := false
## Her name (the board's title) and her hello on the quests' cards (spec §26.5: the space geologist's on the planets).
var who := "Gemma the geologist"
var hello_words := "Hello, explorer! Rocks tell stories. Pick a quest, and I'll teach you to find the Earth's riches."


var view: StringName = QUESTS
var kind: StringName = &""
var step_index := -1
var exercise: ExercisePanel
var close_button: Button
var gold_label: Label
var title_label: Label
var cards: Array[Button] = []
var action_button: Button

var _panel: PanelContainer
var _content: VBoxContainer
var _built := false
var _quiz_at := 0
var _said := ""


func _ready() -> void:
	name = "ProspectBoard"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()


func is_open() -> bool:
	return visible


## Opens on the quests' cards.
func open_quests() -> void:
	_show()
	show_quests()


## Opens on the step of `quest_kind` being done (its card when it has no step now).
func open_step(quest_kind: StringName) -> void:
	_show()
	show_step(quest_kind)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Android Back: true when the board was open (now closed).
func close_if_open() -> bool:
	if not visible:
		return false
	close()
	return true


func blockers() -> Array[Control]:
	return [self]


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


# --- The views ------------------------------------------------------------------------------------------------------

func show_quests() -> void:
	_build()
	view = QUESTS
	kind = &""
	step_index = -1
	_clear()
	_title(who)
	var hello := SchoolUi.words(hello_words, 24, PANEL_SIZE.x - 80)
	_content.add_child(hello)
	if guest:
		_content.add_child(_line("These rocks belong to your friend's world. Start a quest in your own world!", Color("ffd166")))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	cards.clear()
	for q: Dictionary in quests.call():
		grid.add_child(_card(q))
	_content.add_child(grid)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var mine := UiKit.big_button("MY FINDS", UiKit.BLUE, Vector2(260, 64))
	mine.name = "MyFinds"
	mine.pressed.connect(show_finds)
	row.add_child(mine)
	_content.add_child(row)
	_speak("%s. %s" % [who, hello.text])


func show_step(quest_kind: StringName) -> void:
	_build()
	var v: Dictionary = step_view.call(quest_kind)
	if v.is_empty():
		show_quests()
		return
	view = STEP
	kind = quest_kind
	step_index = int(v.index)
	_quiz_at = 0
	_clear()
	var s: Dictionary = v.step
	_title("%s · Step %d of %d" % [str(v.title), step_index + 1, int(v.count)])
	match s.type:
		ProspectQuests.MAP, ProspectQuests.CLUE, ProspectQuests.PROBLEM, ProspectQuests.QUIZ:
			_show_exercise(s)
		ProspectQuests.MARK:
			_show_mark(s)
		_:
			_show_walk(s)


## The quest's deposit is marked: the gold, the find's facts, how it is dug out and refined.
func show_done(quest_kind: StringName, gold_words: String, map_name: String) -> void:
	_build()
	view = DONE
	kind = quest_kind
	_clear()
	_title("You found it!")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.add_child(_picture(quest_kind, 170.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var what := SchoolUi.words("The %s is on your map now (MAP)." % map_name, 28, 900)
	col.add_child(what)
	var paid := SchoolUi.words(gold_words, 30, 900)
	paid.add_theme_color_override("font_color", GOLD_COLOR)
	paid.name = "GoldWords"
	col.add_child(paid)
	col.add_child(SchoolUi.words(str(DepositKinds.data(quest_kind).get("work", "")), 24, 900))
	row.add_child(col)
	_content.add_child(row)
	_content.add_child(_line("In a Survivor world, dig it out and refine it:", Color.WHITE))
	for l in RefiningRules.lines_for(quest_kind):
		_content.add_child(_line("• " + l, Color("cfe8ff")))
	action_button = UiKit.big_button("GREAT!", UiKit.GREEN, Vector2(260, 72))
	action_button.name = "Great"
	action_button.pressed.connect(show_quests)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(action_button)
	_content.add_child(bottom)
	Audio.play(&"fanfare")
	_speak("You found it! " + what.text + " " + gold_words)


func show_finds() -> void:
	_build()
	view = FINDS
	_clear()
	_title("My finds")
	var list: Array = finds.call()
	if list.is_empty():
		_content.add_child(SchoolUi.words("Nothing found in this world yet. Start a quest, and the finds go on your map!", 26,
			PANEL_SIZE.x - 80))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PANEL_SIZE.x - 60, PANEL_SIZE.y - 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	for f: Dictionary in list:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(_picture(f.kind, 90.0))
		var words := VBoxContainer.new()
		words.add_child(_line(str(f.name), GOLD_COLOR, 26))
		for l in RefiningRules.lines_for(f.kind):
			words.add_child(_line(l, Color("cfe8ff"), 20))
		row.add_child(words)
		col.add_child(row)
	scroll.add_child(col)
	_content.add_child(scroll)
	var back := UiKit.big_button("QUESTS", UiKit.BLUE, Vector2(240, 64))
	back.pressed.connect(show_quests)
	_content.add_child(back)


# --- A step's parts ---------------------------------------------------------------------------------------------------

func _show_exercise(s: Dictionary) -> void:
	var list := ProspectQuests.exercises(s)
	if _quiz_at >= list.size():
		return
	exercise = ExercisePanel.new(list[_quiz_at], _quiz_at)
	exercise.first_try_gold = first_try_gold
	exercise.answered.connect(_on_answered.bind(s), CONNECT_ONE_SHOT)
	if s.type == ProspectQuests.MAP:
		var map := ProspectMap.new(s.map, map_sampler, map_samples)
		map.name = "QuestMap"
		var left := exercise.get_child(0)
		left.add_child(map)
		left.move_child(map, 1)
	elif s.type == ProspectQuests.QUIZ:
		_content.add_child(_line("Gemma's quiz: %d of %d" % [_quiz_at + 1, list.size()], GOLD_COLOR, 22))
	_content.add_child(exercise)


func _on_answered(_first_try: bool, s: Dictionary) -> void:
	_quiz_at += 1
	var list := ProspectQuests.exercises(s)
	if _quiz_at < list.size():
		var old := exercise
		for c in _content.get_children():
			if c != _content.get_child(0):
				_content.remove_child(c)
				c.queue_free()
		if old and is_instance_valid(old):
			old.queue_free()
		_show_exercise(s)
		return
	step_answered.emit(kind, step_index)


func _show_walk(s: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.add_child(_picture(kind, 200.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	var words := SchoolUi.words(str(s.words) + "!", 36, 860)
	words.name = "StepWords"
	col.add_child(words)
	var how := "The compass at the top of the screen points the way." if s.type == ProspectQuests.REACH \
		else "Look around when you get there: %s." % str(DepositKinds.data(kind).get("sign", "its sign"))
	col.add_child(SchoolUi.words(how, 26, 860))
	var far: int = distance_to.call(kind)
	if far >= 0:
		col.add_child(_line("It is about %d m away." % far, GOLD_COLOR, 26))
	row.add_child(col)
	_content.add_child(row)
	action_button = UiKit.big_button("LET'S GO!", UiKit.GREEN, Vector2(300, 80))
	action_button.name = "LetsGo"
	action_button.pressed.connect(close)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(action_button)
	_content.add_child(bottom)
	_speak(words.text + " " + how)


func _show_mark(s: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.add_child(_picture(kind, 200.0))
	var words := SchoolUi.words("You did it! %s." % str(s.words), 36, 860)
	words.name = "StepWords"
	row.add_child(words)
	_content.add_child(row)
	action_button = UiKit.big_button("MARK IT!", UiKit.ORANGE, Vector2(300, 80))
	action_button.name = "MarkIt"
	action_button.pressed.connect(func() -> void: mark_pressed.emit(kind))
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(action_button)
	_content.add_child(bottom)
	_speak(words.text)


func _card(q: Dictionary) -> Button:
	var k: StringName = q.kind
	var status := str(q.get("status", "new"))
	var here: bool = q.get("here", false)
	var line := ""
	var button := ""
	if not here:
		line = "Told in %s" % str(q.get("where", ""))
	elif status == "going":
		line = "Step %d of %d" % [int(q.step) + 1, int(q.steps)]
		button = "GO ON"
	else:
		line = "Found %d here" % int(q.get("found", 0)) if int(q.get("found", 0)) > 0 else ("Done before!" if status == "done" else "New!")
		button = "FIND ANOTHER" if status == "done" or int(q.get("found", 0)) > 0 else "START"
	var b := Button.new()
	b.name = "Quest_" + String(k)
	b.custom_minimum_size = Vector2(370, 190)
	b.add_theme_stylebox_override("normal", UiKit.box(Color(0.16, 0.22, 0.36) if here else Color(0.18, 0.18, 0.22)))
	b.add_theme_stylebox_override("hover", UiKit.box(Color(0.22, 0.3, 0.46) if here else Color(0.2, 0.2, 0.24)))
	b.disabled = not here or guest
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	var pic := _picture(k, 120.0)
	row.add_child(pic)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	col.add_child(_line(str(q.get("title", "")), GOLD_COLOR, 22, CARD_TEXT))
	col.add_child(_line(DepositKinds.display_name(k), Color.WHITE, 20, CARD_TEXT))
	col.add_child(_line(line, Color("cfe8ff"), 20, CARD_TEXT))
	if button != "" and not guest:
		col.add_child(_line(button, Color("8dff8a"), 24, CARD_TEXT))
	row.add_child(col)
	b.add_child(row)
	b.set_meta(&"action", button)
	b.pressed.connect(func() -> void:
		Audio.play(&"ui_click")
		start_pressed.emit(k))
	cards.append(b)
	return b


## A deposit kind's picture on a paper disc.
func _picture(k: StringName, side: float) -> Control:
	var c := _Pic.new()
	c.kind = k
	c.custom_minimum_size = Vector2(side, side)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _line(text: String, color: Color, size: int = 22, width: float = -1.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width if width > 0.0 else minf(PANEL_SIZE.x - 80, 220 + text.length() * 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _title(text: String) -> void:
	title_label.text = text
	gold_label.text = "%s gold" % GoldFormat.short(int(gold.call()))


func _speak(text: String) -> void:
	_said = text
	ReadAloud.auto(text)


## What the speaker reads.
func words() -> String:
	return _said if _said != "" else title_label.text


# --- Building the panel -----------------------------------------------------------------------------------------------

func _show() -> void:
	_build()
	visible = true
	if PlatformRules.captures_mouse(PlatformRules.current()) and is_inside_tree():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play(&"ui_click")
	opened.emit()
	_fit.call_deferred()


func _build() -> void:
	if _built:
		return
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.09, 0.15, 0.97)
	box.border_color = Color("c9922a")
	box.set_border_width_all(3)
	box.set_corner_radius_all(22)
	box.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.custom_minimum_size = PANEL_SIZE
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	column.add_child(head)
	title_label = UiKit.title(who, 34)
	title_label.add_theme_color_override("font_color", GOLD_COLOR)
	head.add_child(ReadAloud.with_speaker(title_label, self, words))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var quests_button := UiKit.big_button("QUESTS", UiKit.BLUE, Vector2(170, 60))
	quests_button.name = "QuestsTab"
	quests_button.pressed.connect(show_quests)
	head.add_child(quests_button)
	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 24)
	gold_label.add_theme_color_override("font_color", GOLD_COLOR)
	head.add_child(gold_label)
	close_button = UiKit.big_button("X", UiKit.RED, Vector2(72, 60))
	close_button.name = "Close"
	close_button.tooltip_text = "Close (Esc)"
	close_button.pressed.connect(close)
	head.add_child(close_button)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	column.add_child(_content)


func _clear() -> void:
	exercise = null
	action_button = null
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	_content.add_child(Control.new())   # a spacer the answers' refresh keeps


func _fit() -> void:
	if _panel == null:
		return
	var room := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var need := _panel.get_combined_minimum_size()
	var s := minf(1.0, minf((room.y - 16.0) / maxf(need.y, 1.0), (room.x - 16.0) / maxf(need.x, 1.0)))
	_panel.scale = Vector2(s, s)
	_panel.pivot_offset = need * 0.5


## A deposit kind's picture on a round paper badge.
class _Pic:
	extends Control

	var kind: StringName

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c, r, Color("5a3d1e"))
		draw_circle(c, r - 4.0, Color("fdf6e3"))
		ProspectPictures.draw(self, kind, Rect2(c - Vector2(r, r) * 0.7, Vector2(r, r) * 1.4))
