class_name LifeRoomHud
extends CanvasLayer
## Owner #112, #113 (docs/design/life-skills.md §3, §10): what the child sees over a practice room (flat on the screen; in
## VR on the panel, UiLayers.route). One thing at a time, everything read aloud on the Little track:
## - the coach's bar: Professor Hoot, the step's words with a speaker, "3 of 12", the step's little progress bar;
## - SHOW ME (the coach shows the step) and I NEED A BREAK (always there: a calm card, CARRY ON or STOP FOR NOW);
## - a kind line that pops up (what went well, a gentle "stay low");
## - the step's own controls at the bottom: OK for words, big picture answers, GET LOW, an action's big button (STOP,
##   COVER FACE, ROLL: in VR only after the coach has shown it twice: the body does it there), the beat meter, the
##   clock of a time-lapse, the coins' sum with TAKE ONE BACK, the basket with PAY;
## - flat only: the tap area over the room (fingers reach the 3D things: the host picks what is under them) and the
##   coach's ghost finger.
## Life L2 (owner #112): LOOK LEFT and LOOK RIGHT for a look (in VR after the coach showed it twice: the head does it
## there), the clock of the 20 seconds' rub, the gauge of a pour (the cup's marks, the scales' grams) and of a pedal (the
## speed and its limit), the balloon guide of balloon breathing, and the faces of a feeling.
## Life L3a (owner #118, design §14): a safe mistake's freeze: a soft veil over the room (flat: the scene softens, never
## sudden) and the coach's card (the picture of what would happen, the calm why, the right way, GOT IT, read aloud); a
## SLOW PRACTICE mark while a danger moment's time is slowed; the wrong body action's own picture button beside the right
## one (STAND UP on the ice: the child may try it, safely); an action's `button` words, a basket's `pay` words.
## The host (LifeRoomHost) listens to its signals; nothing here changes the run.

signal ok
signal answered(index: int)
signal action_pressed(action: String)
signal low_toggled(on: bool)
signal coins_back
signal pay
signal show_me
signal break_changed(open: bool)
signal stop_for_now
signal finger(kind: String, pos: Vector2)
signal look_pressed(side: String)
signal mistake_ok

const LAYER := 40
const CANVAS := Vector2(1280, 720)
const ACTION_WORDS := {"still": "STOP", "cover": "COVER FACE", "roll": "ROLL", "low": "GET LOW", "look": "LOOK AROUND",
	"stand": "STAND UP", "tree": "BE A TREE"}   # Life L3b: be a tree (a dog runs at you)
const ACTION_ICONS := {"still": "hand", "cover": "cough", "roll": "roll", "low": "low", "look": "people", "stand": "stand",
	"tree": "be_a_tree"}
## Life L3a: the freeze's soft veil (a pale calm blue, see-through) and its card's words.
const VEIL := Color(0.86, 0.92, 1.0, 0.42)
const MISTAKE_TITLE := "Time stands still. Let's see why."
const SLOW_WORDS := "SLOW PRACTICE"
const BREAK_WORDS := "Take a break. That's fine! You can carry on now, or stop for now. Nothing is lost."
## Android Back in a room (Life L2, owner #112: L1's follow-up): the same calm card asks first.
const LEAVE_WORDS := "Leave the practice? Nothing is lost: you can come back any time."
const FEEDBACK_TIME := 2.6

var root: Control
var tap_area: Control
var top: PanelContainer
var say_label: Label
var counter: Label
var bar: ProgressBar
var feedback: Label
var bottom: HBoxContainer
var ghost: LifeGhostFinger
var break_card: PanelContainer
var break_words: Label
var stop_button: Button
var low_button: Button
var show_me_button: Button
var break_button: Button
var beat: BeatMeter
var clock: Clock
var sum_label: Label
var choice_buttons: Array[Button] = []
var action_button: Button
var ok_button: Button
var look_left: Button
var look_right: Button
var gauge: Gauge
var breath: BreathGuide
## Life L3a: the freeze (veil, card), the slow mark, the wrong action's button, the basket's pay button.
var veil: ColorRect
var mistake_card: PanelContainer
var mistake_why: Label
var mistake_right: Label
var mistake_pic: LifeIcons
var slow_mark: HBoxContainer
var mistake_action: Button
var pay_button: Button
var _veil_tween: Tween
var vr := false
var track := "little"
var step := {}
var coach_shows := 0
var _feedback_t := 0.0
var _finger_down := false


func _init() -> void:
	name = "LifeRoomHud"
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
	feedback = OnlineUi.words("", 30, 900)
	feedback.name = "Feedback"
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.add_theme_color_override("font_color", SchoolUi.GOOD)
	feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	feedback.offset_left = -450
	feedback.offset_right = 450
	feedback.offset_top = 150
	feedback.offset_bottom = 220
	root.add_child(feedback)
	bottom = HBoxContainer.new()
	bottom.name = "Bottom"
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 22)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -214
	bottom.offset_bottom = -14
	bottom.offset_left = 250
	bottom.offset_right = -20
	root.add_child(bottom)
	low_button = SchoolUi.button("GET LOW", Color("6b7a99"), Vector2(220, 110))
	low_button.name = "GetLow"
	low_button.toggle_mode = true
	low_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	low_button.offset_left = 16
	low_button.offset_right = 236
	low_button.offset_top = -126
	low_button.offset_bottom = -16
	low_button.toggled.connect(func(on: bool) -> void:
		low_button.text = "LOW DOWN" if on else "GET LOW"
		low_toggled.emit(on))
	low_button.visible = false
	root.add_child(low_button)
	ghost = LifeGhostFinger.new()
	root.add_child(ghost)
	_slow_mark()
	_mistake_card()   # under the break card: I NEED A BREAK always works, even while frozen
	_break_card()


func _top_bar() -> void:
	top = PanelContainer.new()
	top.name = "CoachBar"
	top.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.86), 22, 14))
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
	row.add_child(SchoolUi.teacher(86.0))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	say_label = Label.new()
	say_label.name = "Say"
	say_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	say_label.custom_minimum_size = Vector2(700, 0)
	say_label.add_theme_font_size_override("font_size", 26)
	col.add_child(say_label)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 12)
	col.add_child(info)
	counter = Label.new()
	counter.add_theme_font_size_override("font_size", 18)
	counter.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	info.add_child(counter)
	bar = ProgressBar.new()
	bar.name = "StepBar"
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.0
	bar.custom_minimum_size = Vector2(260, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(bar)
	row.add_child(ReadAloud.button(func() -> String: return say_label.text, 64.0))


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
	break_button = SchoolUi.button("I NEED A BREAK", Color("3a7be8"), Vector2(284, 62))
	break_button.name = "NeedABreak"
	break_button.add_theme_font_size_override("font_size", 24)
	break_button.pressed.connect(open_break)
	col.add_child(break_button)


func _break_card() -> void:
	break_card = PanelContainer.new()
	break_card.name = "BreakCard"
	break_card.add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.16, 0.28, 0.97), 26, 28))
	break_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	break_card.offset_left = -360
	break_card.offset_right = 360
	break_card.offset_top = -190
	break_card.offset_bottom = 190
	break_card.visible = false
	root.add_child(break_card)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 22)
	break_card.add_child(col)
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
	stop_button = SchoolUi.button("STOP FOR NOW", Color("6b7a99"), Vector2(290, 84))
	stop_button.name = "StopForNow"
	stop_button.pressed.connect(func() -> void: stop_for_now.emit())
	buttons.add_child(stop_button)


## Life L3a: "SLOW PRACTICE" under the coach's bar while a danger moment's time is slowed.
func _slow_mark() -> void:
	slow_mark = HBoxContainer.new()
	slow_mark.name = "SlowMark"
	slow_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slow_mark.add_theme_constant_override("separation", 8)
	slow_mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	slow_mark.offset_left = 22
	slow_mark.offset_top = 146
	slow_mark.offset_right = 360
	slow_mark.offset_bottom = 190
	slow_mark.add_child(LifeIcons.new("clock", 40.0))
	var words := OnlineUi.words(SLOW_WORDS, 22, 280)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_theme_color_override("font_color", SchoolUi.HINT)
	slow_mark.add_child(words)
	slow_mark.visible = false
	root.add_child(slow_mark)


## Life L3a: the soft veil over the room and the coach's card of a safe mistake (built hidden).
func _mistake_card() -> void:
	veil = ColorRect.new()
	veil.name = "Veil"
	veil.color = VEIL
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP   # while frozen, a tap on the room does nothing
	veil.visible = false
	root.add_child(veil)
	mistake_card = PanelContainer.new()
	mistake_card.name = "MistakeCard"
	mistake_card.add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.16, 0.28, 0.97), 26, 24))
	mistake_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	mistake_card.offset_left = -420
	mistake_card.offset_right = 420
	mistake_card.offset_top = -230
	mistake_card.offset_bottom = 230
	mistake_card.visible = false
	root.add_child(mistake_card)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	mistake_card.add_child(col)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 14)
	head.add_child(SchoolUi.teacher(70.0))
	var title := OnlineUi.words(MISTAKE_TITLE, 24, 560)
	title.add_theme_color_override("font_color", SchoolUi.HINT)
	head.add_child(title)
	col.add_child(head)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	col.add_child(body)
	mistake_pic = LifeIcons.new("question", 130.0)
	mistake_pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body.add_child(mistake_pic)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 10)
	body.add_child(words)
	mistake_why = OnlineUi.words("", 25, 600)
	mistake_why.name = "Why"
	mistake_why.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(mistake_why)
	mistake_right = OnlineUi.words("", 22, 600)
	mistake_right.name = "Right"
	mistake_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mistake_right.add_theme_color_override("font_color", SchoolUi.GOOD)
	words.add_child(mistake_right)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var ok_now := SchoolUi.button("GOT IT", UiKit.GREEN, Vector2(300, 84))
	ok_now.name = "GotIt"
	ok_now.pressed.connect(func() -> void: mistake_ok.emit())
	row.add_child(ok_now)
	row.add_child(ReadAloud.button(func() -> String: return "%s %s" % [mistake_why.text, mistake_right.text], 64.0))
	col.add_child(row)


## A safe mistake: the veil fades in (never sudden) and the coach's card shows the picture, the why and the right way.
func show_mistake(m: Dictionary) -> void:
	mistake_why.text = str(m.get("why", ""))
	mistake_right.text = str(m.get("right", ""))
	mistake_pic.icon = str(m.get("icon", "question")) if LifeIcons.has(str(m.get("icon", ""))) else "question"
	mistake_pic.queue_redraw()
	_fade_veil(true)
	mistake_card.visible = true
	UiMotion.pop_in(mistake_card)
	if is_inside_tree():
		PadFocus.take(mistake_card)
	LifeVoice.say("%s %s" % [mistake_why.text, mistake_right.text], track)


func hide_mistake() -> void:
	mistake_card.visible = false
	_fade_veil(false)


func mistake_open() -> bool:
	return mistake_card.visible


func _fade_veil(on: bool) -> void:
	if _veil_tween:
		_veil_tween.kill()
	if on and not veil.visible:
		veil.modulate.a = 0.0   # softens from clear
	veil.visible = true
	if not is_inside_tree() or UiMotion.calm():
		veil.modulate.a = 1.0 if on else 0.0
		veil.visible = on
		return
	_veil_tween = create_tween()
	_veil_tween.tween_property(veil, "modulate:a", 1.0 if on else 0.0, LifeRoomHost.FREEZE_FADE * (1.0 if on else 0.5))
	if not on:
		_veil_tween.tween_callback(func() -> void: veil.visible = false)


func set_slow(on: bool) -> void:
	slow_mark.visible = on


func set_vr(on: bool) -> void:
	vr = on
	tap_area.mouse_filter = Control.MOUSE_FILTER_IGNORE if on else Control.MOUSE_FILTER_STOP
	_refresh_controls()


func open_break() -> void:
	_open_card(BREAK_WORDS, "STOP FOR NOW")


## Android Back in a room: "Leave the practice?" with CARRY ON and LEAVE (the same calm way out as STOP FOR NOW).
func open_leave() -> void:
	_open_card(LEAVE_WORDS, "LEAVE")


func _open_card(words: String, stop_words: String) -> void:
	if break_card.visible:
		return
	break_words.text = words
	stop_button.text = stop_words
	break_card.visible = true
	if is_inside_tree():
		PadFocus.take(break_card)
	LifeVoice.say(words, track)
	break_changed.emit(true)


func close_break() -> void:
	if not break_card.visible:
		return
	break_card.visible = false
	break_changed.emit(false)


func break_open() -> bool:
	return break_card.visible


## A new step: its words, its place in the run, its controls.
func show_step(s: Dictionary, index: int, total: int) -> void:
	step = s
	coach_shows = 0
	say_label.text = str(s.get("say", ""))
	counter.text = "%d of %d" % [index + 1, total]
	bar.value = 0.0
	_build_controls()
	LifeVoice.say(say_label.text, track)


func set_fraction(f: float) -> void:
	bar.value = clampf(f, 0.0, 1.0)
	if clock != null:
		clock.fraction = f


## A kind line for a moment (what went well; a gentle reminder).
func pop_line(text: String, good: bool = true) -> void:
	if text.strip_edges() == "":
		return
	feedback.text = text
	feedback.add_theme_color_override("font_color", SchoolUi.GOOD if good else SchoolUi.HINT)
	feedback.visible = true
	_feedback_t = FEEDBACK_TIME
	UiMotion.pop_in(feedback)
	LifeVoice.say(text, track)


## The coach showed the step once more (in VR the body-action buttons appear after the second time).
func coached() -> void:
	coach_shows += 1
	_refresh_controls()


func set_low_visible(on: bool) -> void:
	low_button.visible = on and (not vr or coach_shows >= 2)


func set_rate(rate: float, count: int, pushes: int) -> void:
	if beat:
		beat.rate = rate
		beat.count = count
		beat.pushes = pushes
		beat.queue_redraw()


func set_sum(text: String) -> void:
	if sum_label:
		sum_label.text = text


## Life L2: a pour's or a pedal's gauge (the band is where to be).
func set_gauge(value: float, lo: float, hi: float, top: float, words: String) -> void:
	if gauge:
		gauge.value = value
		gauge.lo = lo
		gauge.hi = hi
		gauge.top = maxf(top, 0.001)
		gauge.words = words
		gauge.queue_redraw()


func set_breath(phase: String, count: int, breaths: int) -> void:
	if breath:
		breath.phase = phase
		breath.count = count
		breath.breaths = breaths


## The middle of LOOK LEFT or LOOK RIGHT on the canvas (the coach's ghost finger presses it).
func look_centre(side: String) -> Vector2:
	var b := look_left if side == "left" else look_right
	return b.get_global_rect().get_center() if b != null else CANVAS * 0.5


## A pour's amount in words: the cup's fraction, the scales' grams, the kettle's line.
static func amount_words(level: float, unit: String, want: float) -> String:
	match unit:
		"g":
			return "%d of %d g" % [roundi(level), roundi(want)]
		"cup":
			return "%s cup" % _fraction(level)
		"line":
			return "MAX" if level > 0.82 else ("between MIN and MAX" if level >= 0.35 else "under MIN")
		"soil":   # Life L3c (owner #112): Home Helper's plants: how damp the soil is
			return "the soil is still dry" if level < want - 0.15 else ("damp: just right" if level <= want + 0.15 else "too wet")
	return "%d%%" % roundi(level * 100.0)


static func _fraction(level: float) -> String:
	var quarters := roundi(level * 4.0)
	return ["0", "1/4", "1/2", "3/4", "1"][clampi(quarters, 0, 4)]


## The middle of choice `i` on the canvas (the ghost finger points there).
func choice_centre(i: int) -> Vector2:
	if i < 0 or i >= choice_buttons.size():
		return CANVAS * 0.5
	var b := choice_buttons[i]
	return b.get_global_rect().get_center()


func _process(delta: float) -> void:
	if _feedback_t > 0.0:
		_feedback_t -= delta
		if _feedback_t <= 0.0:
			feedback.visible = false


func _build_controls() -> void:
	OnlineUi.clear(bottom)
	choice_buttons.clear()
	action_button = null
	ok_button = null
	beat = null
	clock = null
	sum_label = null
	look_left = null
	look_right = null
	gauge = null
	breath = null
	mistake_action = null
	pay_button = null
	match str(step.get("kind", "")):
		"info":
			ok_button = SchoolUi.button("OK!", UiKit.GREEN, Vector2(280, 96))
			ok_button.name = "Ok"
			ok_button.pressed.connect(func() -> void: ok.emit())
			bottom.add_child(ok_button)
		"choose", "count", "feel":
			var choices: Array = step.get("choices", [])
			var wide := minf(300.0, (CANVAS.x - 290.0 - 22.0 * (choices.size() - 1)) / maxf(choices.size(), 1.0))
			for i in choices.size():
				var b := _picture_button(str(choices[i].get("text", "")), str(choices[i].get("icon", "")), Vector2(wide, 190))
				b.name = "Choice%d" % i
				b.pressed.connect(func() -> void: answered.emit(i))
				bottom.add_child(b)
				choice_buttons.append(b)
		"action":
			var a := str(step.get("action", ""))
			if a != "low":
				action_button = _picture_button(str(step.get("button", ACTION_WORDS.get(a, a.to_upper()))),
					str(ACTION_ICONS.get(a, "hand")), Vector2(300, 190))
				action_button.name = "Action"
				action_button.pressed.connect(func() -> void: action_pressed.emit(a))
				bottom.add_child(action_button)
			var m: Variant = step.get("safe_mistake")   # Life L3a: the wrong body action, to try safely (STAND UP)
			if m is Dictionary and str((m as Dictionary).get("try", "")).begins_with("action:"):
				var wrong := str(m.try).trim_prefix("action:")
				mistake_action = _picture_button(str(ACTION_WORDS.get(wrong, wrong.to_upper())),
					str(ACTION_ICONS.get(wrong, "hand")), Vector2(300, 190))
				mistake_action.name = "MistakeAction"
				mistake_action.pressed.connect(func() -> void: action_pressed.emit(wrong))
				bottom.add_child(mistake_action)
				if hash(str(step.get("id", ""))) % 2 == 0:
					bottom.move_child(mistake_action, 0)   # never always the same side
		"rhythm":
			beat = BeatMeter.new()
			bottom.add_child(beat)
		"timelapse", "rub":
			clock = Clock.new()
			clock.label = str(step.get("label", ""))
			bottom.add_child(clock)
		"look":
			look_left = _picture_button("LOOK LEFT", "look_left", Vector2(280, 190))
			look_left.name = "LookLeft"
			look_left.pressed.connect(func() -> void: look_pressed.emit("left"))
			bottom.add_child(look_left)
			look_right = _picture_button("LOOK RIGHT", "look_right", Vector2(280, 190))
			look_right.name = "LookRight"
			look_right.pressed.connect(func() -> void: look_pressed.emit("right"))
			bottom.add_child(look_right)
		"pour", "steady":
			gauge = Gauge.new()
			bottom.add_child(gauge)
		"breathe":
			breath = BreathGuide.new()
			breath.in_s = float(step.get("in", 3.0))
			breath.out_s = float(step.get("out", 3.0))
			breath.breaths = int(step.get("breaths", 3))
			bottom.add_child(breath)
		"coins":
			sum_label = OnlineUi.words("", 28, 420)
			sum_label.name = "Sum"
			bottom.add_child(sum_label)
			var back := SchoolUi.button("TAKE ONE BACK", Color("6b7a99"), Vector2(280, 80))
			back.name = "TakeOneBack"
			back.add_theme_font_size_override("font_size", 24)
			back.pressed.connect(func() -> void: coins_back.emit())
			bottom.add_child(back)
		"basket":
			sum_label = OnlineUi.words("", 26, 460)
			sum_label.name = "Sum"
			bottom.add_child(sum_label)
			var p := SchoolUi.button(str(step.get("pay", "PAY")), UiKit.GREEN, Vector2(220, 84))
			p.name = "Pay"
			p.pressed.connect(func() -> void: pay.emit())
			bottom.add_child(p)
			pay_button = p
	_refresh_controls()


func _refresh_controls() -> void:
	if action_button != null:
		action_button.visible = not vr or coach_shows >= 2
	if mistake_action != null:
		mistake_action.visible = not vr or coach_shows >= 2   # in a headset the body does it (the head coming up)
	for b: Button in [look_left, look_right]:
		if b != null:
			b.visible = not vr or coach_shows >= 2   # in a headset the head looks
	var low_step := str(step.get("kind", "")) == "action" and str(step.get("action", "")) == "low"
	if low_step or bool(step.get("low", false)):
		set_low_visible(true)


## A big picture answer: the picture over its words (the words wrap; the whole card is the button).
func _picture_button(text: String, icon: String, min_size: Vector2) -> Button:
	var b := SchoolUi.button("", Color(0.16, 0.22, 0.36), min_size)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 8
	col.offset_bottom = -8
	b.add_child(col)
	var pic := LifeIcons.new(icon, 96.0)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(pic)
	var words := OnlineUi.words(text, 22 if text.length() > 22 else 26, min_size.x - 20.0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(words)
	b.set_meta(&"words", text)
	return b


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
	if event.is_action_pressed("ui_accept") and not break_card.visible and mistake_card.visible:
		mistake_ok.emit()   # A says GOT IT (Life L3a)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not break_card.visible and ok_button != null and ok_button.visible:
		ok.emit()   # A says yes
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if break_card.visible:
			close_break()
		else:
			open_break()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:   # Android's Back: "Leave the practice?" (a second Back carries on)
		if break_card.visible:
			close_break()
		else:
			open_leave()


## The CPR beat: a ring that pulses at 110 a minute, and the rate on a gauge whose middle band (100-120) is green.
class BeatMeter:
	extends Control
	var rate := 0.0
	var count := 0
	var pushes := 30
	var _t := 0.0

	func _init() -> void:
		name = "BeatMeter"
		custom_minimum_size = Vector2(520, 180)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_style_box(UiKit.box(Color(0.08, 0.1, 0.17, 0.86), 22, 0), Rect2(Vector2.ZERO, size))
		var beat_on := fmod(_t, LifeBeat.BEAT_SECONDS) < 0.15
		var c := Vector2(90, size.y * 0.5)
		draw_circle(c, 56.0 if beat_on else 48.0, Color(1, 0.86, 0.3, 0.9 if beat_on else 0.5))
		LifeIcons.paint(self, "hands_chest", Rect2(c - Vector2(36, 36), Vector2(72, 72)))
		var gauge := Rect2(Vector2(180, 52), Vector2(310, 34))
		draw_rect(gauge, Color(1, 1, 1, 0.15))
		var lo := gauge.position.x + gauge.size.x * (LifeBeat.MIN_RATE - 60.0) / 100.0
		var hi := gauge.position.x + gauge.size.x * (LifeBeat.MAX_RATE - 60.0) / 100.0
		draw_rect(Rect2(Vector2(lo, gauge.position.y), Vector2(hi - lo, gauge.size.y)), Color(0.3, 0.85, 0.4, 0.75))
		if rate > 0.0:
			var x := gauge.position.x + gauge.size.x * clampf((rate - 60.0) / 100.0, 0.0, 1.0)
			draw_rect(Rect2(Vector2(x - 4, gauge.position.y - 8), Vector2(8, gauge.size.y + 16)), Color.WHITE)
		var font := get_theme_default_font()
		draw_string(font, Vector2(180, 40), "slower", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
		draw_string(font, Vector2(430, 40), "faster", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
		draw_string(font, Vector2(180, 130), "%d of %d pushes" % [count, pushes], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)


## A time-lapse's clock: its hand sweeps as the step plays, the label (20 minutes) under it.
class Clock:
	extends Control
	var fraction := 0.0
	var label := ""

	func _init() -> void:
		name = "Clock"
		custom_minimum_size = Vector2(240, 190)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, 78)
		draw_circle(c, 66, Color("fdfdf8"))
		draw_arc(c, 66, 0, TAU, 40, Color("1f2a4a"), 5, true)
		draw_arc(c, 58, -PI / 2, -PI / 2 + TAU * clampf(fraction, 0.0, 1.0), 40, Color(0.35, 0.65, 0.95, 0.85), 12, true)
		var a := -PI / 2 + TAU * fraction * 4.0
		draw_line(c, c + Vector2(cos(a), sin(a)) * 50, Color("1f2a4a"), 5, true)
		draw_string(get_theme_default_font(), Vector2(0, 182), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color.WHITE)


## Life L2: a pour's level or a pedal's needle on a bar; the green band is where to stop (or to stay).
class Gauge:
	extends Control
	var value := 0.0
	var lo := 0.0
	var hi := 0.0
	var top := 1.0
	var words := ""

	func _init() -> void:
		name = "Gauge"
		custom_minimum_size = Vector2(560, 150)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_style_box(UiKit.box(Color(0.08, 0.1, 0.17, 0.86), 22, 0), Rect2(Vector2.ZERO, size))
		var bar := Rect2(Vector2(30, 34), Vector2(size.x - 60, 40))
		draw_rect(bar, Color(1, 1, 1, 0.15))
		var x0 := bar.position.x + bar.size.x * clampf(lo / top, 0.0, 1.0)
		var x1 := bar.position.x + bar.size.x * clampf(hi / top, 0.0, 1.0)
		draw_rect(Rect2(Vector2(x0, bar.position.y), Vector2(maxf(x1 - x0, 4.0), bar.size.y)), Color(0.3, 0.85, 0.4, 0.75))
		var fill := bar.size.x * clampf(value / top, 0.0, 1.0)
		draw_rect(Rect2(bar.position, Vector2(fill, bar.size.y)), Color(0.55, 0.8, 1.0, 0.55))
		draw_rect(Rect2(Vector2(bar.position.x + fill - 4, bar.position.y - 10), Vector2(8, bar.size.y + 20)), Color.WHITE)
		draw_string(get_theme_default_font(), Vector2(30, 122), words, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 30, Color.WHITE)


## Life L2, balloon breathing: a balloon that grows for IN and shrinks for OUT at the step's pace (the child breathes with
## it), the breaths done so far.
class BreathGuide:
	extends Control
	var phase := "rest"
	var count := 0
	var breaths := 3
	var in_s := 3.0
	var out_s := 3.0
	var _t := 0.0

	func _init() -> void:
		name = "BreathGuide"
		custom_minimum_size = Vector2(420, 190)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_style_box(UiKit.box(Color(0.08, 0.1, 0.17, 0.86), 22, 0), Rect2(Vector2.ZERO, size))
		var cycle := in_s + out_s
		var k := fmod(_t, cycle)
		var grow := k / in_s if k < in_s else 1.0 - (k - in_s) / out_s
		var c := Vector2(110, size.y * 0.5)
		draw_circle(c, 30.0 + 46.0 * grow, Color("8b6fd6"))
		draw_circle(c + Vector2(-14, -16) * (0.6 + grow), 8.0, Color(1, 1, 1, 0.5))
		var font := get_theme_default_font()
		draw_string(font, Vector2(220, 80), "IN..." if k < in_s else "OUT...", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.WHITE)
		draw_string(font, Vector2(220, 140), "%d of %d" % [count, breaths], HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
			Color(1, 1, 1, 0.8))
