class_name WonderQuizView
extends VBoxContainer
## A wonder's fact quiz (owner #78, spec §24): its questions one at a time, each with three big answers and a speaker
## (read aloud), what the answer was, NEXT and at the end DONE. A question answered right the first time pays
## EarnRules.FACT_QUIZ_GOLD once (WondersPassportRules.answer; `pay` takes it: Survivor's wallet or the profile, like
## the School); later tries never pay, but a child may always try again to learn it. Used in the Wonders Passport's
## page and on a wonder's plaque card (WonderCard).

signal finished

const ANSWER_SIZE := Vector2(560, 60)
const RIGHT_COLOR := Color("2fae4e")
const WRONG_COLOR := Color("d9463b")

## The book's data (tests use their own).
var data: Callable = func() -> WonderData: return Profile.data.wonder
## (gold) -> void: pays the child (the sandbox's; by default the profile's Survivor gold, like the School's).
var pay: Callable = func(gold: int) -> void: EarnRules.credit(Profile.data, gold)
var save: Callable = func() -> void: Profile.save()

var wonder: StringName = &""
var index := 0
var question_label := Label.new()
var answers: Array[Button] = []
var said := Label.new()
var next_button: Button

var _answered := false


func _init() -> void:
	name = "WonderQuiz"
	add_theme_constant_override("separation", 10)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.custom_minimum_size.x = ANSWER_SIZE.x
	question_label.add_theme_font_size_override("font_size", 26)
	add_child(ReadAloud.with_speaker(question_label, self, _words))
	for i in 3:
		var b := UiKit.big_button("", UiKit.BLUE, ANSWER_SIZE)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(pick.bind(i))
		answers.append(b)
		add_child(b)
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	said.custom_minimum_size.x = ANSWER_SIZE.x
	said.add_theme_font_size_override("font_size", 22)
	add_child(said)
	next_button = UiKit.big_button("NEXT", UiKit.GREEN, Vector2(220, 60))
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.pressed.connect(_next)
	add_child(next_button)


## Starts wonder `id`'s quiz at its first question.
func start(id: StringName) -> void:
	wonder = id
	index = 0
	_show()


func questions() -> Array:
	return WondersPassportRules.questions(wonder)


func _show() -> void:
	var qs := questions()
	if index >= qs.size():
		finished.emit()
		return
	var q: Dictionary = qs[index]
	question_label.text = "%d of %d: %s" % [index + 1, qs.size(), str(q.q)]
	for i in answers.size():
		var b := answers[i]
		b.text = str((q.choices as Array)[i]) if i < (q.choices as Array).size() else ""
		b.visible = b.text != ""
		b.disabled = false
		b.add_theme_stylebox_override("disabled", UiKit.box(UiKit.BLUE.darkened(0.3)))
	said.text = ""
	next_button.visible = false
	_answered = false
	if is_inside_tree() and answers.size() > 0:
		PadFocus.take(_panel(), answers[0])


## The child picks answer i of the question showing.
func pick(i: int) -> void:
	if _answered or wonder == &"":
		return
	var qs := questions()
	if index >= qs.size():
		return
	var q: Dictionary = qs[index]
	var w: WonderData = data.call()
	var r := WondersPassportRules.answer(w, str(q.id), i)
	_answered = true
	if int(r.gold) > 0:
		pay.call(int(r.gold))
	save.call()
	said.text = str(r.words)
	said.add_theme_color_override("font_color", RIGHT_COLOR if bool(r.right) else WRONG_COLOR)
	Audio.play(&"sparkle" if bool(r.right) else &"ui_click")
	for j in answers.size():
		answers[j].disabled = true
		if j == int(q.right):
			answers[j].add_theme_stylebox_override("disabled", UiKit.box(RIGHT_COLOR))
	next_button.text = "DONE" if index + 1 >= qs.size() else "NEXT"
	next_button.visible = true
	if is_inside_tree():
		PadFocus.take(_panel(), next_button)


func _next() -> void:
	index += 1
	_show()


func _words() -> String:
	var parts: Array[String] = [question_label.text]
	for b in answers:
		if b.visible:
			parts.append(b.text)
	return " ".join(parts)


## The panel a game controller moves round in while the quiz shows: the plaque's card or the book (PadFocus watches both).
func _panel() -> Control:
	var n: Node = self
	while n.get_parent() is Control:
		n = n.get_parent()
		if n is WonderCard or n is SecretBook:
			break
	return n as Control
