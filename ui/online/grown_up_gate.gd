class_name GrownUpGate
extends HBoxContainer
## The parent gate in front of online play's grown-up pages (M4 Wave 1, Agent C; spec §5.14): the
## existing ParentGate (M3 Task 17), a multiplication written in words so a young child can't copy
## digits, answered on a number pad. A wrong answer asks a new question; the third in a row rests every gate for a
## minute (ParentGate's one count for the app run; M4 Task 10 review E): the pad rests and a kind line counts down to
## when a grown-up can try again. It is a speed bump; the verification provider behind it is the real check (§17.2).

signal passed
signal cancelled

const MAX_TYPED := 4
const KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "DEL", "0", "OK"]

var rng := RandomNumberGenerator.new()
var msec := Callable()   # () -> int msec; default Time.get_ticks_msec (tests give their own)
var question: Dictionary = {}
var question_label: Label
var entry := Label.new()
var back_button: Button
var keys := {}   # key text -> Button

var _typed := ""
var _shown_wait := -1   # the seconds the rest line shows (-1: not resting)


func _ready() -> void:
	if not AgeBand.restrictions:   # the owner, 2026-09-29: no grown-up confirmations for now
		passed.emit.call_deferred()
		return
	add_theme_constant_override("separation", 34)
	alignment = BoxContainer.ALIGNMENT_CENTER
	rng.randomize()
	var left := OnlineUi.column(18)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	question_label = OnlineUi.words("", 30, 420)
	left.add_child(question_label)
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entry.add_theme_font_size_override("font_size", 48)
	left.add_child(entry)
	back_button = OnlineUi.button("BACK", UiKit.BLUE, Vector2(300, 80))
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(func() -> void: cancelled.emit())
	left.add_child(back_button)
	add_child(left)
	var pad := GridContainer.new()
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", 10)
	pad.add_theme_constant_override("v_separation", 10)
	for key in KEYS:
		var b := OnlineUi.button(key, UiKit.GREEN if key == "OK" else Color(), Vector2(OnlineUi.MIN_WIDTH, 70))
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(press.bind(key))
		keys[key] = b
		pad.add_child(b)
	add_child(pad)
	_new_question("Grown-ups only!")
	if ParentGate.is_locked(_now()):
		_rest()


## A key on the pad (tests press them too). Nothing while the gate rests.
func press(key: String) -> void:
	if ParentGate.is_locked(_now()):
		return
	match key:
		"DEL":
			_typed = _typed.left(-1)
		"OK":
			if ParentGate.check(question, _typed):
				ParentGate.record_right()
				passed.emit()
			elif ParentGate.record_wrong(_now()):
				_rest()
			else:
				_new_question("Not quite. Try again!")
			return
		_:
			if _typed.length() < MAX_TYPED:
				_typed += key
	entry.text = _typed if _typed != "" else "_"


func _new_question(heading: String) -> void:
	question = ParentGate.make(rng)
	question_label.text = "%s\n%s" % [heading, question.text]
	_typed = ""
	entry.text = "_"


## The gate rests: the pad too, and the line counts down (_process); then a new question.
func _rest() -> void:
	_typed = ""
	entry.text = ""
	_shown_wait = -1
	_set_pad(false)
	_show_wait()
	set_process(true)


func _process(_delta: float) -> void:
	if _shown_wait < 0:
		set_process(false)
	elif ParentGate.is_locked(_now()):
		_show_wait()
	else:
		_shown_wait = -1
		_set_pad(true)
		_new_question("Grown-ups only!")


func _show_wait() -> void:
	var wait := ParentGate.wait_seconds(_now())
	if wait != _shown_wait:
		_shown_wait = wait
		question_label.text = ParentGate.locked_text(wait)


func _set_pad(on: bool) -> void:
	for key: String in keys:
		(keys[key] as Button).disabled = not on


func _now() -> int:
	return int(msec.call()) if msec.is_valid() else Time.get_ticks_msec()
