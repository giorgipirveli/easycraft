class_name ExercisePanel
extends HBoxContainer
## Owner #68 (spec §22.1): one exercise. Left: the prompt with its speaker (maths said in words, SchoolSpeech), the
## picture, and Professor Hoot's feedback. Right: the answer widget (ChoiceAnswer, NumberAnswerPad, OrderAnswer or
## BuildBoard) and CHECK (a choice or TRUE / FALSE answers at a tap), then NEXT.
## A miss: "Not yet" with the hint, and another try. A second miss: how it works and the answer (SHOWN). NEXT emits
## `answered(first_try)` once: only an answer right the first time counts towards stars (MasteryRules).
## Owner #94: an answer right after the hint also shows why (the worked answer); the praise starts at `praise_from` (the
## round's seed), so it changes from round to round; a long worked answer shrinks the picture (never below
## MIN_PICTURE_H), then its words, so it always fits the panel.

signal answered(first_try: bool)

const ASKING := 0
const RIGHT := 1
const SHOWN := 2
const SIZE := Vector2(1180, 540)
const LEFT_W := 580.0
const RIGHT_W := 560.0
const PICTURE := Vector2(580, 250)
const MIN_PICTURE_H := 110.0
const SMALL_WORDS := 22

var ex: Dictionary
var number := 0
## Owner #94: where Professor Hoot's praise starts (SchoolScreen gives the round's seed).
var praise_from := 0
var left_column: VBoxContainer
var state := ASKING
var tries := 0
var prompt_label: Label
var picture: SchoolPicture
var feedback: Label
var answer_widget: Control
var check_button: Button
var next_button: Button
## LISTEN, when the exercise has a sound (SchoolSound), its player and how often it was played.
var listen_button: Button
var sound_player: AudioStreamPlayer
var listens := 0
var _told := false
## Owner #79 (spec §25.1): () -> gold paid for an answer right the first time (EarnRules; the School sets it); its words
## show under Professor Hoot's in gold ("+5 gold: right the first time!").
var first_try_gold := Callable()
var gold_line: Label


func _init(exercise: Dictionary = {}, index: int = 0) -> void:
	ex = exercise
	number = index
	name = "Exercise"
	add_theme_constant_override("separation", 40)
	alignment = BoxContainer.ALIGNMENT_CENTER
	var left := VBoxContainer.new()
	left_column = left
	left.custom_minimum_size.x = LEFT_W
	left.add_theme_constant_override("separation", 12)
	prompt_label = SchoolUi.words(str(ex.get("prompt", "")), 30, LEFT_W - 80)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.add_child(ReadAloud.with_speaker(prompt_label, self, spoken_text))
	if ex.get("picture") is Dictionary and str(ex.get("type", "")) != "label":   # a label's picture has its pins
		picture = SchoolPicture.new(ex.picture, PICTURE)
		picture.playing = SchoolPicture.should_play(ex.picture, true)   # owner #94: still unless it asks to move
		left.add_child(picture)
	if ex.get("sound") is Dictionary:   # the research's "listen and choose" (§5.3)
		listen_button = SchoolUi.listen_button(ex.sound, func() -> void: listens += 1)
		sound_player = listen_button.get_meta(&"player")
		left.add_child(listen_button)
	feedback = SchoolUi.words("", 26, LEFT_W)
	feedback.name = "Feedback"
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	feedback.visible = false
	left.add_child(feedback)
	gold_line = SchoolUi.words("", 26, LEFT_W)
	gold_line.name = "GoldLine"
	gold_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	gold_line.add_theme_color_override("font_color", SchoolUi.GOLD)
	gold_line.visible = false
	left.add_child(gold_line)
	add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = RIGHT_W
	right.add_theme_constant_override("separation", 16)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	answer_widget = _widget()
	right.add_child(answer_widget)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	check_button = SchoolUi.button("CHECK", UiKit.GREEN, Vector2(260, 80))
	check_button.name = "Check"
	check_button.pressed.connect(check)
	next_button = SchoolUi.button("NEXT", SchoolUi.TEAL, Vector2(260, 80))
	next_button.name = "Next"
	next_button.visible = false
	next_button.pressed.connect(_next)
	row.add_child(check_button)
	row.add_child(next_button)
	right.add_child(row)
	add_child(right)
	var taps := answer_widget is ChoiceAnswer
	check_button.visible = not taps
	answer_widget.connect(&"changed", _refresh)
	if answer_widget.has_signal(&"submitted"):
		answer_widget.connect(&"submitted", check)
	_refresh()


func _ready() -> void:
	ReadAloud.auto(spoken_text())   # "Read to me" (M3 Task 21a)


## The prompt as it is said, with the choices ("3 times 4 equals what? 12, 7, 34.").
func spoken_text() -> String:
	var words := SchoolSpeech.spoken(str(ex.get("prompt", "")))
	var list: Array = ex.get("choices", ex.get("items", [])) + ex.get("matches", []) + ex.get("groups", [])
	var named: Array[String] = []
	for c: Variant in list:
		var t := ExerciseCheck.item_text(c)
		if t != "":
			named.append(SchoolSpeech.spoken(t))
	if not named.is_empty():
		words += " " + ", ".join(named) + "."
	return words


## CHECK (or a tap on a choice): right, not yet (the hint), or the second miss (the worked answer).
func check() -> void:
	if state != ASKING or not answer_widget.call(&"is_ready"):
		return
	if ExerciseCheck.is_right(ex, answer_widget.call(&"response")):
		state = RIGHT
		answer_widget.call(&"mark_right")
		answer_widget.call(&"lock")
		var praise := SchoolWords.right(number + praise_from) if tries == 0 \
			else SchoolWords.right_after_help(number + praise_from)
		var why := str(ex.get("explain", "")).strip_edges()
		if tries > 0 and why != "":   # owner #94: right after the hint, the worked answer too
			praise += "\n%s %s" % [SchoolWords.HERE_IS_WHY, why]
		_say(praise, SchoolUi.GOOD)
		Audio.play(&"ding")
		var middle := (answer_widget as Control).get_global_rect().get_center()
		UiMotion.burst(self, middle, 8 if tries == 0 else 5)   # owner #94: a right answer bursts a few stars
		if tries == 0 and first_try_gold.is_valid():   # owner #79: a few gold for an answer right the first time
			var gold := int(first_try_gold.call())
			if gold > 0:
				gold_line.text = EarnRules.answer_words(gold)
				gold_line.visible = true
				UiMotion.pop_in(gold_line)
				UiMotion.fly(self, middle, gold_line, 3, UiFlyers.COIN)
		_finish()
		return
	tries += 1
	if tries < 2:
		answer_widget.call(&"mark_wrong")
		_say("%s\n%s" % [SchoolWords.not_yet(number), str(ex.get("hint", ""))], SchoolUi.HINT)
		Audio.play(&"ui_tick")
		_refresh()
		return
	show_worked_answer()


## The second miss: how it works and the answer (SHOWN), then NEXT.
func show_worked_answer() -> void:
	state = SHOWN
	answer_widget.call(&"lock")
	answer_widget.call(&"show_answer", ExerciseCheck.answer_of(ex))
	var how := str(ex.get("explain", ""))
	var answer := ExerciseCheck.answer_text(ex)
	var lines: Array[String] = [SchoolWords.SHOW_HOW]
	if how != "":
		lines.append(how)
	var plain := answer.trim_suffix(".")
	if plain != "" and not how.to_lower().contains(plain.to_lower()):   # said once, whatever its capitals
		lines.append("The answer is %s." % plain)
	_say("\n".join(lines), SchoolUi.HINT)
	_finish()


func _say(text: String, color: Color) -> void:
	feedback.text = text
	feedback.add_theme_color_override("font_color", color)
	feedback.visible = true
	_fit()
	ReadAloud.auto(SchoolSpeech.spoken(text))


## Owner #94: the left column fits the panel: a long worked answer first shrinks the picture (to MIN_PICTURE_H at the
## least), then the feedback's words get smaller.
func _fit() -> void:
	var over := left_column.get_combined_minimum_size().y - SIZE.y
	if over <= 0.0:
		return
	if picture != null:
		picture.custom_minimum_size.y = maxf(MIN_PICTURE_H, picture.custom_minimum_size.y - over)
		over = left_column.get_combined_minimum_size().y - SIZE.y
	if over > 0.0:
		feedback.add_theme_font_size_override("font_size", SMALL_WORDS)
		gold_line.add_theme_font_size_override("font_size", SMALL_WORDS)


func _finish() -> void:
	check_button.visible = false
	next_button.visible = true


func _next() -> void:
	if _told or state == ASKING:
		return
	_told = true
	answered.emit(state == RIGHT and tries == 0)


func _refresh() -> void:
	check_button.disabled = state != ASKING or not answer_widget.call(&"is_ready")


func _widget() -> Control:
	match str(ex.get("type", "")):
		"number":
			return NumberAnswerPad.new(ex)
		"order":
			return OrderAnswer.new(ex)
		"build":
			return BuildBoard.new(ex)
		"point":   # grade 5: tap a point on a coordinate grid
			return GridAnswer.new(ex)
		"sort":    # the research's new types (§5.3)
			return SortAnswer.new(ex)
		"match":
			return MatchAnswer.new(ex)
		"robot":   # §5.3 "code the robot"
			return RobotAnswer.new(ex)
		"rhythm":  # §5.3 "tap the rhythm"
			return RhythmAnswer.new(ex)
		"mix":     # §5.3 "mix the colour"
			return MixAnswer.new(ex)
		"label":   # §5.3 "label the diagram"
			return LabelAnswer.new(ex)
	return ChoiceAnswer.new(ex)
