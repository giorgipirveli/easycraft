class_name PlayHud
extends CanvasLayer
## Owner #122 (G0; docs/design/learning-is-play.md rules 2, 3, 4, 7): what the child sees over the play arena (flat on the
## screen; in VR on the panel, UiLayers.route). Words are tools, not walls: the challenge's own words in the coach's bar
## (read aloud: a speaker, and "Read to me"), the world's answer and the hint in one line under it, the coach's see-why
## card after the try. Everything else is the place itself:
## - the coach's bar: Professor Hoot, the words (the hook first, then each challenge's), "2 of 6", a speaker;
## - SHOW ME (the coach's ghost does one step) and I NEED A BREAK (the calm card: CARRY ON or STOP FOR NOW), always;
## - at the bottom: what the station reads (the number made), the world's test (its own words: RUN THE MACHINE, WALK
##   ACROSS…) when the act itself doesn't answer, and NEXT once a challenge is answered;
## - flat only: the tap area over the place (the host picks what is under a finger) and the coach's ghost finger.
## The host (PlayHost) listens to its signals; nothing here judges an answer.
## Owner #133, rule 0 (`voice`: PlayVoice.on()): a child never has to read. Every line is spoken at once, by itself; the
## bar keeps only the caption (the numbers themselves, or the mechanic's few words: at most PlayReadless.screen_words()
## words on the screen), the big ear says it again, the count is dots, the buttons are pictures (their words in the
## tooltip), and the world's answer and the coach's lines are heard, not written. Without a voice (or with Read to me
## turned off) every word shows, as for a reader.

signal finger(kind: String, pos: Vector2)
signal go
signal next
signal play_on
signal show_me
signal break_changed(open: bool)
signal stop_for_now

const LAYER := 40
const CANVAS := Vector2(1280, 720)
## Where a thing to tap may be on the screen: under the coach's bar, above the bottom row.
const FREE := Rect2(12, 150, 1256, 450)
const BREAK_WORDS := "Take a break. That's fine! You can carry on now, or stop for now. Nothing is lost."
const LEAVE_WORDS := "Leave the game? Nothing is lost: you can come back any time."

var root: Control
var tap_area: Control
var say_label: Label
var counter: Label
var feedback: Label
var gold_line: Label
var readout: Label
var go_button: Button
var next_button: Button
var show_me_button: Button
var break_button: Button
var stop_button: Button
var why_card: PanelContainer
var why_words: Label
var play_on_button: Button
var break_card: PanelContainer
var break_words: Label
## A tap on the place's board: its picture big (a tap anywhere closes it).
var picture_card: PanelContainer
var picture_view: SchoolPicture
var ghost: LifeGhostFinger
var vr := false
## Owner #133: the voice speaks and the screen shows pictures (PlayVoice.on()).
var voice := false
## The big ear: says the bar's whole line again.
var ear: Button
## The round's challenges as dots (with the voice on).
var pips: PlayGlyph
var _finger_down := false
## What the bar says (spoken; the ear repeats it), whatever the screen shows.
var _spoken := ""
var _caption := ""
## The picture buttons: {button: [glyph, its words]}.
var _glyphs := {}


func _init() -> void:
	name = "PlayHud"
	layer = LAYER
	root = Control.new()
	root.name = "Root"
	root.theme = UiKit.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	tap_area = Control.new()
	tap_area.name = "TapArea"
	tap_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_area.mouse_filter = Control.MOUSE_FILTER_STOP
	tap_area.gui_input.connect(_on_tap_input)
	root.add_child(tap_area)
	_top_bar()
	_side_buttons()
	feedback = OnlineUi.words("", 28, 940)
	feedback.name = "Feedback"
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	feedback.offset_left = -480
	feedback.offset_right = 480
	feedback.offset_top = 150
	feedback.offset_bottom = 230
	feedback.visible = false
	root.add_child(feedback)
	_bottom_row()
	ghost = LifeGhostFinger.new()
	root.add_child(ghost)
	_why_card()
	_picture_card()
	_break_card()


func _top_bar() -> void:
	var top := PanelContainer.new()
	top.name = "CoachBar"
	top.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.86), 22, 12))
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -310
	top.offset_top = 10
	top.offset_bottom = 140
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	top.add_child(row)
	row.add_child(SchoolUi.teacher(80.0))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	say_label = Label.new()
	say_label.name = "Say"
	say_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	say_label.custom_minimum_size = Vector2(700, 0)
	say_label.add_theme_font_size_override("font_size", 26)
	col.add_child(say_label)
	counter = Label.new()
	counter.name = "Counter"
	counter.add_theme_font_size_override("font_size", 20)
	counter.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	col.add_child(counter)
	pips = PlayGlyph.new(PlayGlyph.PIPS, 44.0)
	pips.name = "Pips"
	pips.ink = Color(1, 1, 1, 0.85)
	pips.visible = false
	col.add_child(pips)
	ear = ReadAloud.button(func() -> String: return SchoolSpeech.spoken(_spoken), 96.0)
	ear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ear)


func _side_buttons() -> void:
	var col := VBoxContainer.new()
	col.name = "Side"
	col.add_theme_constant_override("separation", 10)
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	col.offset_left = -296
	col.offset_right = -12
	col.offset_top = 10
	col.offset_bottom = 150
	root.add_child(col)
	show_me_button = SchoolUi.button("SHOW ME", Color("c49a12"), Vector2(284, 62))
	show_me_button.name = "ShowMe"
	show_me_button.add_theme_font_size_override("font_size", 26)
	show_me_button.pressed.connect(func() -> void: show_me.emit())
	col.add_child(show_me_button)
	_picture(show_me_button, PlayGlyph.EYE)
	break_button = SchoolUi.button("I NEED A BREAK", Color("3a7be8"), Vector2(284, 62))
	break_button.name = "NeedABreak"
	break_button.add_theme_font_size_override("font_size", 24)
	break_button.pressed.connect(open_break)
	col.add_child(break_button)
	_picture(break_button, PlayGlyph.PAUSE)


func _bottom_row() -> void:
	var row := HBoxContainer.new()
	row.name = "Bottom"
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -112
	row.offset_bottom = -14
	row.offset_left = 20
	row.offset_right = -20
	root.add_child(row)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(words)
	readout = OnlineUi.words("", 28, 560)
	readout.name = "Readout"
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(readout)
	gold_line = OnlineUi.words("", 24, 560)
	gold_line.name = "GoldLine"
	gold_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	gold_line.add_theme_color_override("font_color", SchoolUi.GOLD)
	gold_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_line.visible = false
	words.add_child(gold_line)
	go_button = SchoolUi.button("TEST IT", UiKit.GREEN, Vector2(330, 92))
	go_button.name = "Go"
	go_button.add_theme_font_size_override("font_size", 28)
	go_button.pressed.connect(func() -> void: go.emit())
	row.add_child(go_button)
	_picture(go_button, PlayGlyph.GO, 60.0)
	next_button = SchoolUi.button("NEXT", SchoolUi.TEAL, Vector2(260, 92))
	next_button.name = "Next"
	next_button.pressed.connect(func() -> void: next.emit())
	next_button.visible = false
	row.add_child(next_button)
	_picture(next_button, PlayGlyph.NEXT, 60.0)


## The coach's see-why card (after the try): Professor Hoot, the one line, LET'S PLAY!
func _why_card() -> void:
	why_card = _card("WhyCard")
	var col := why_card.get_child(0) as VBoxContainer
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.add_child(SchoolUi.teacher(110.0))
	why_words = OnlineUi.words("", 32, 520)
	why_words.name = "WhyWords"
	row.add_child(why_words)
	col.add_child(row)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	play_on_button = SchoolUi.button("LET'S PLAY!", UiKit.GREEN, Vector2(320, 86))
	play_on_button.name = "PlayOn"
	play_on_button.pressed.connect(func() -> void:
		why_card.visible = false
		play_on.emit())
	buttons.add_child(play_on_button)
	_picture(play_on_button, PlayGlyph.GO, 56.0)
	buttons.add_child(ReadAloud.button(func() -> String: return why_words.text, 64.0))
	col.add_child(buttons)


func _picture_card() -> void:
	picture_card = _card("PictureCard")
	picture_card.offset_left = -560
	picture_card.offset_right = 560
	picture_card.offset_top = -270
	picture_card.offset_bottom = 270
	picture_card.mouse_filter = Control.MOUSE_FILTER_STOP
	picture_card.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed) or (e is InputEventMouseButton
				and (e as InputEventMouseButton).pressed):
			hide_picture())
	var col := picture_card.get_child(0) as VBoxContainer
	col.add_theme_constant_override("separation", 10)
	var close := SchoolUi.button("CLOSE", SchoolUi.TEAL, Vector2(220, 64))
	close.name = "ClosePicture"
	close.pressed.connect(hide_picture)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(close)
	_picture(close, PlayGlyph.CLOSE, 40.0)


## The board's picture, big (from a tap on the board in the place).
func show_picture(data: Dictionary) -> void:
	if picture_view != null:
		picture_view.queue_free()
	picture_view = SchoolPicture.new(data, Vector2(1060, 430))
	picture_view.playing = SchoolPicture.should_play(data, true)
	picture_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := picture_card.get_child(0) as VBoxContainer
	col.add_child(picture_view)
	col.move_child(picture_view, 0)
	picture_card.visible = true
	UiMotion.pop_in(picture_card)


func hide_picture() -> void:
	picture_card.visible = false


func _break_card() -> void:
	break_card = _card("BreakCard")
	var col := break_card.get_child(0) as VBoxContainer
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.add_child(SchoolUi.teacher(100.0))
	break_words = OnlineUi.words(BREAK_WORDS, 28, 500)
	break_words.name = "BreakWords"
	row.add_child(break_words)
	col.add_child(row)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 22)
	col.add_child(buttons)
	var carry := SchoolUi.button("CARRY ON", UiKit.GREEN, Vector2(290, 84))
	carry.name = "CarryOn"
	carry.pressed.connect(close_break)
	buttons.add_child(carry)
	_picture(carry, PlayGlyph.GO, 52.0)
	stop_button = SchoolUi.button("STOP FOR NOW", Color("6b7a99"), Vector2(290, 84))
	stop_button.name = "StopForNow"
	stop_button.pressed.connect(func() -> void: stop_for_now.emit())
	buttons.add_child(stop_button)
	_picture(stop_button, PlayGlyph.STOP, 52.0)


func _card(card_name: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.16, 0.28, 0.97), 26, 26))
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left = -380
	card.offset_right = 380
	card.offset_top = -190
	card.offset_bottom = 190
	card.visible = false
	root.add_child(card)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 22)
	card.add_child(col)
	return card


## A button's picture (shown with the voice on, in place of its words).
func _picture(b: Button, glyph: String, side: float = 48.0) -> void:
	var g := PlayGlyph.on_button(b, glyph, side)
	g.visible = false
	_glyphs[b] = [g, b.text]


# --- What the host shows -------------------------------------------------------------------------------------------

## Owner #133: the voice speaks and the buttons are pictures (on), or every word shows, as for a reader (off).
func set_voice(on: bool) -> void:
	voice = on
	for b: Button in _glyphs:
		var g: PlayGlyph = _glyphs[b][0]
		if not on and b.text == "":
			b.text = str(_glyphs[b][1])
		elif on and b.text != "":
			_glyphs[b][1] = b.text
			b.tooltip_text = b.text
			b.text = ""
		g.visible = on
	counter.visible = not on
	pips.visible = on
	feedback.visible = feedback.visible and not on
	why_words.visible = not on
	break_words.visible = not on
	say_label.text = _caption if on else _spoken


## A button's words (kept for the tooltip and a reader when the voice is on).
func _set_words(b: Button, words: String) -> void:
	b.tooltip_text = words
	if _glyphs.has(b):
		_glyphs[b][1] = words
	b.text = "" if voice and _glyphs.has(b) else words


func set_vr(on: bool) -> void:
	vr = on
	tap_area.mouse_filter = Control.MOUSE_FILTER_IGNORE if on else Control.MOUSE_FILTER_STOP


## The words in the coach's bar (the hook, a challenge's prompt), read aloud. With the voice on they are spoken at
## once and the bar shows only `caption` (owner #133).
func say(text: String, index: int = -1, total: int = 0, caption: String = "") -> void:
	_spoken = text
	_caption = caption
	say_label.text = caption if voice else text
	counter.text = "%d of %d" % [index + 1, total] if index >= 0 else ""
	pips.set_pips(index, total if index >= 0 else 0)
	if voice:
		PlayVoice.say(text)
	else:
		ReadAloud.auto(SchoolSpeech.spoken(text))


## A new challenge: its words, its test's words (or none when the act answers), nothing answered yet.
func show_challenge(text: String, index: int, total: int, go_words: String, caption: String = "") -> void:
	say(text, index, total, caption)
	feedback.visible = false
	gold_line.visible = false
	next_button.visible = false
	_set_words(go_button, go_words)
	go_button.visible = go_words != ""
	go_button.disabled = false
	why_card.visible = false


## The world's answer and the coach's words, under the bar (good: green; a hint: warm, never red).
## With the voice on, heard and not written (the place answers on the screen: owner #133, "World answers").
func line(text: String, good: bool) -> void:
	feedback.text = text
	feedback.add_theme_color_override("font_color", SchoolUi.GOOD if good else SchoolUi.HINT)
	if voice:
		feedback.visible = false
		PlayVoice.say(text)
		return
	feedback.visible = text != ""
	if feedback.visible:
		UiMotion.pop_in(feedback)
		ReadAloud.auto(SchoolSpeech.spoken(text))


## The gold an answer paid (`amount`: with the voice on just "+5 gold").
func gold(words: String, amount: int = 0) -> void:
	gold_line.text = "+%d gold" % amount if voice and amount > 0 else words
	gold_line.visible = words != ""
	if gold_line.visible:
		UiMotion.pop_in(gold_line)


func answered() -> void:
	go_button.visible = false
	next_button.visible = true


func set_readout(text: String) -> void:
	readout.text = text


func show_why(text: String) -> void:
	why_words.text = text
	why_words.visible = not voice
	why_card.visible = true
	UiMotion.pop_in(why_card)
	if is_inside_tree():
		PadFocus.take(why_card)
	if voice:
		PlayVoice.say(text)
	else:
		ReadAloud.auto(SchoolSpeech.spoken(text))


func open_break() -> void:
	_open_card(BREAK_WORDS, "STOP FOR NOW")


## Android Back in the place: "Leave the game?" with CARRY ON and LEAVE.
func open_leave() -> void:
	_open_card(LEAVE_WORDS, "LEAVE")


func _open_card(words: String, stop_words: String) -> void:
	if break_card.visible:
		return
	break_words.text = words
	break_words.visible = not voice
	_set_words(stop_button, stop_words)
	break_card.visible = true
	if is_inside_tree():
		PadFocus.take(break_card)
	if voice:
		PlayVoice.say(words)
	else:
		ReadAloud.auto(words)
	break_changed.emit(true)


func close_break() -> void:
	if not break_card.visible:
		return
	break_card.visible = false
	break_changed.emit(false)


func break_open() -> bool:
	return break_card.visible


## Owner #133 (rule 0): the words a child would have to read on the screen now (visible labels and buttons; numbers are
## not words), for the tests and the smoke run.
func screen_words() -> int:
	return PlayReadless.words(screen_text())


func screen_text() -> String:
	var parts := PackedStringArray()
	for n in root.find_children("*", "", true, false):
		var c := n as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if c is Label and (c as Label).text.strip_edges() != "":
			parts.append((c as Label).text)
		elif c is Button and (c as Button).text.strip_edges() != "":
			parts.append((c as Button).text)
	return " ".join(parts)


func _on_tap_input(event: InputEvent) -> void:
	if vr:
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).index == 0:
		var t := event as InputEventScreenTouch
		_finger_down = t.pressed
		finger.emit("down" if t.pressed else "up", t.position)
		tap_area.accept_event()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == 0 and _finger_down:
		finger.emit("move", (event as InputEventScreenDrag).position)
		tap_area.accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if break_card.visible:
			close_break()
		else:
			open_break()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:   # Android's Back: "Leave the game?" (a second Back carries on)
		if break_card.visible:
			close_break()
		else:
			open_leave()
