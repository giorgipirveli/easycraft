class_name ChoiceAnswer
extends GridContainer
## Owner #68 (spec §22.1): the choices of a "choice" exercise (text or pictures), or TRUE / FALSE; a tap answers
## (`submitted`). A choice tried and missed rests (greyed); the right one turns green when found or shown.
## Every answer widget has: signal changed, response(), is_ready(), mark_wrong(), mark_right(), lock(),
## show_answer(answer).

signal changed
signal submitted

const WIDTH := 272.0
const TEXT_HEIGHT := 100.0
const PICTURE_HEIGHT := 150.0

var choices: Array = []
var buttons: Array[Button] = []
var truefalse := false
var picked := -1


func _init(ex: Dictionary) -> void:
	truefalse = str(ex.get("type", "")) == "truefalse"
	choices = ["TRUE", "FALSE"] if truefalse else ex.get("choices", [])
	columns = 1 if choices.size() == 1 else 2
	add_theme_constant_override("h_separation", 14)
	add_theme_constant_override("v_separation", 12)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pictures := choices.any(func(c: Variant) -> bool: return c is Dictionary and c.has("picture"))
	for i in choices.size():
		var c: Variant = choices[i]
		var b := SchoolUi.button(ExerciseCheck.item_text(c), UiKit.GREEN if truefalse and i == 0 else (
			UiKit.RED if truefalse else Color()), Vector2(WIDTH, PICTURE_HEIGHT if pictures else TEXT_HEIGHT))
		b.name = "Choice%d" % i
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 30 if truefalse else 28)
		if c is Dictionary and c.has("picture"):
			var pic := SchoolPicture.new(c.picture, Vector2(WIDTH - 24, PICTURE_HEIGHT - 24))
			pic.playing = SchoolPicture.should_play(c.picture, true)   # owner #94: still unless it asks to move
			pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			pic.offset_left = 12
			pic.offset_top = 12
			pic.offset_right = -12
			pic.offset_bottom = -12
			b.add_child(pic)
		b.pressed.connect(choose.bind(i))
		buttons.append(b)
		add_child(b)


## A tap on choice i: it is the answer.
func choose(i: int) -> void:
	if i < 0 or i >= buttons.size() or buttons[i].disabled:
		return
	picked = i
	changed.emit()
	submitted.emit()


func response() -> Variant:
	return picked == 0 if truefalse else picked


func is_ready() -> bool:
	return picked >= 0


func mark_wrong() -> void:
	if picked >= 0:
		buttons[picked].disabled = true
	picked = -1


func mark_right() -> void:
	_green(picked)


func lock() -> void:
	for b in buttons:
		b.disabled = true


func show_answer(answer: Variant) -> void:
	_green((0 if answer else 1) if truefalse else int(answer))


func _green(i: int) -> void:
	if i < 0 or i >= buttons.size():
		return
	for state: String in ["normal", "disabled", "hover", "pressed"]:
		buttons[i].add_theme_stylebox_override(state, UiKit.box(UiKit.GREEN))
	buttons[i].add_theme_color_override("font_disabled_color", Color.WHITE)
