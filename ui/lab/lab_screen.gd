class_name LabScreen
extends VBoxContainer
## Spec §23 (owner #74): the Science Lab. Opened by a tap on a lab bench (LabPanel, in a world) or by TRY IT IN THE LAB on
## a School unit's page (inside the School's frame); every page fits SchoolUi.FRAME. Pages:
## - LIST: a big picture card per experiment (LabExperiments), a star once done; LAB BOOK;
## - PREDICT (step 1): "What do you think will happen?", the guess (LabPredict), TRY IT! (in Survivor the bench's supplies
##   come from the bag first: `supplies`);
## - TRY (step 2): the experiment's small scene (LabView over its LabModel), what just happened, WHAT HAPPENED? once seen;
##   the plants' pots keep growing when the child leaves (their planting is in the Lab Book);
## - WHY (step 3): the guess, what happened, the why cards (read aloud), the Lab Book's star; LEARN MORE, DO IT AGAIN;
## - BOOK: the Lab Book (LabBookPage); LEARN: the School's unit page inside the Lab (its BACK comes back here).
## A guess is never marked: step 3 says kindly whether it matched. No timers, nothing to fail, every step a tap.
## `profile`, `save_profile` and `now` default to the game's own (tests set theirs); `supplies` (e) -> "" when the bench
## may run it (the host took the blocks) or the words of what it needs; `learn_more` (unit id) replaces LEARN.

signal closed

const LIST := &"list"
const PREDICT := &"predict"
const TRY := &"try"
const WHY := &"why"
const BOOK := &"book"
const LEARN := &"learn"
const GUESS_AGAIN := "Scientists guess wrong all the time; that is how they learn!"
const GUESS_MATCHED := "Your guess matched what happened. Well predicted!"
const GUESS_FIRST := "What do you think will happen? Any guess is a good start."
const STEPS: Array[String] = ["1 PREDICT", "2 TRY IT", "3 WHY"]
const LAB_COLOUR := Color("2fae4e")   # the School's science green
const CARD := Vector2(372, 234)

var profile: ProfileData
var save_profile := Callable()
var now := Callable()
var supplies := Callable()
var learn_more := Callable()

var page: StringName = &""
var experiment_id := ""
var experiment: Dictionary
var model: LabModel
var view: LabView
var predict_answer: LabPredict
var cards: Array[Button] = []
var book: LabBookPage
var school: SchoolScreen
var why_card: Label
var why_index := 0
var status: Label
var note: Label
var try_button: Button
var what_button: Button
var _direct := false
var _before_learn: StringName = &""


func _init() -> void:
	name = "Lab"
	custom_minimum_size = SchoolUi.FRAME
	add_theme_constant_override("separation", 14)


func _ready() -> void:
	_defaults()
	if page == &"":
		show_list()


func _defaults() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	if not now.is_valid():
		now = func() -> int: return int(Time.get_unix_time_from_system())


## A host opens the Lab on one experiment (the School's TRY IT IN THE LAB): its BACK leaves the Lab.
func start_on(id: String) -> void:
	_direct = true
	open(id)


# --- LIST ----------------------------------------------------------------------------------------------------------

func show_list() -> void:
	_defaults()
	_clear(LIST)
	var book_button := _small("LAB BOOK", show_book, 220)
	add_child(_header("Science Lab", func() -> void: closed.emit(), [book_button]))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for id in LabExperiments.ids():
		var e := LabExperiments.experiment(id)
		if e.is_empty():
			continue
		var c := _card(e)
		c.pressed.connect(open.bind(id))
		cards.append(c)
		grid.add_child(c)
	add_child(grid)
	var line := SchoolUi.words("Predict, try it, then find out why. Tap a card to start!", 24, 1000)
	line.add_theme_color_override("font_color", SchoolUi.HINT)
	add_child(line)
	ReadAloud.auto("Science Lab")


func _card(e: Dictionary) -> Button:
	var id := str(e.id)
	var b := SchoolUi.button("", Color(0.16, 0.2, 0.3), CARD)
	b.name = "Card_" + id
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 8
	var art := LabArt.Card.new(str((e.get("scene", {}) as Dictionary).get("kind", "")), Vector2(CARD.x - 20, 128))
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(art)
	var title := SchoolUi.words(str(e.title), 28, CARD.x - 16)
	v.add_child(title)
	var line := SchoolUi.words(str(e.card), 20, CARD.x - 16)
	line.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	v.add_child(line)
	b.add_child(v)
	var star := LabArt.Star.new(40.0)
	star.name = "Star"
	star.filled = profile.lab.has_star(id)
	star.position = Vector2(CARD.x - 52, 10)
	b.add_child(star)
	if profile.lab.planted_at(id) > 0:
		var growing := SchoolUi.words("growing", 18, 110)
		growing.add_theme_color_override("font_color", SchoolUi.GOOD)
		growing.position = Vector2(12, 12)
		b.add_child(growing)
	return b


# --- PREDICT -------------------------------------------------------------------------------------------------------

## Opens experiment `id`: its prediction, or its pots when the plants are already growing.
func open(id: String) -> void:
	_defaults()
	var e := LabExperiments.experiment(id)
	if e.is_empty():
		show_list()
		return
	experiment_id = id
	experiment = e
	if str((e.get("scene", {}) as Dictionary).get("kind", "")) == "plants" and profile.lab.planted_at(id) > 0:
		show_try()
	else:
		show_predict()


func show_predict() -> void:
	_clear(PREDICT)
	add_child(_header(str(experiment.title), _back, [_steps(0)]))
	var p := LabExperiments.predict_of(experiment)
	var prompt := SchoolUi.words(str(p.get("prompt", "")), 30, 1100)
	add_child(prompt)
	predict_answer = LabPredict.new(p, (experiment.get("scene", {}) as Dictionary).get("things", []))
	predict_answer.changed.connect(_refresh_predict)
	add_child(predict_answer)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	note = SchoolUi.words(GUESS_FIRST, 24, 720)
	note.name = "Note"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	note.add_theme_color_override("font_color", SchoolUi.HINT)
	row.add_child(note)
	try_button = SchoolUi.button("TRY IT!", UiKit.GREEN, Vector2(280, 84))
	try_button.name = "TryIt"
	try_button.pressed.connect(_try_it)
	row.add_child(try_button)
	add_child(row)
	_refresh_predict()
	ReadAloud.auto(str(p.get("prompt", "")))


func _refresh_predict() -> void:
	if try_button:
		try_button.disabled = not predict_answer.is_ready()


## TRY IT!: the bench's supplies (Survivor), the guess into the Lab Book, then the scene.
func _try_it() -> void:
	if page != PREDICT or not predict_answer.is_ready():
		return
	var need := str(supplies.call(experiment)) if supplies.is_valid() else ""
	if need != "":
		note.text = need
		ReadAloud.auto(need)
		return
	var guess: Variant = predict_answer.response()
	profile.lab.set_guess(experiment_id, guess, LabExperiments.matched(experiment, guess))
	save_profile.call()
	show_try()


# --- TRY -----------------------------------------------------------------------------------------------------------

func show_try() -> void:
	_clear(TRY)
	add_child(_header(str(experiment.title), _back, [_steps(1)]))
	var words := HBoxContainer.new()
	words.add_theme_constant_override("separation", 24)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	var safety := str(experiment.get("safety", ""))
	var how := SchoolUi.words(str(experiment.get("try", "")), 24, 1100.0 if safety == "" else 680.0)
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(how)
	if safety != "":
		var careful := SchoolUi.words(safety, 20, 420)
		careful.name = "Safety"
		careful.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		careful.add_theme_color_override("font_color", SchoolUi.HINT)
		words.add_child(careful)
	add_child(words)
	model = LabModels.make(experiment.scene, now)
	if model is LabPlants:
		(model as LabPlants).restore(profile.lab.planted_at(experiment_id))
	view = LabView.make(model)
	view.custom_minimum_size.y = LabView.SIZE.y
	view.changed.connect(_on_scene_changed)
	add_child(view)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	status = SchoolUi.words("", 26, 820)
	status.name = "Status"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(status)
	what_button = SchoolUi.button("WHAT HAPPENED?", SchoolUi.TEAL, Vector2(330, 84))
	what_button.name = "WhatHappened"
	what_button.pressed.connect(_what_happened)
	row.add_child(what_button)
	add_child(row)
	_refresh_try()
	ReadAloud.auto(str(experiment.get("try", "")))


func _on_scene_changed() -> void:
	if model is LabPlants:
		var at := (model as LabPlants).planted_at
		if at > 0 and profile.lab.planted_at(experiment_id) != at:
			profile.lab.set_planted(experiment_id, at)   # the pots keep growing while the child is away
			save_profile.call()
	_refresh_try()
	if model.last != "":
		ReadAloud.auto(model.last)


func _refresh_try() -> void:
	status.text = model.last
	what_button.disabled = not model.done()
	if model.done() and model.last == "":
		status.text = "Now find out why!"
	elif model is LabPlants and model.last == "" and (model as LabPlants).planted_at > 0:
		status.text = "The seeds are growing. Tap LOOK AGAIN after a game day."


## WHAT HAPPENED?: a run done (the Lab Book's star the first time), then step 3.
func _what_happened() -> void:
	if page != TRY or not model.done():
		return
	var first := profile.lab.finish(experiment_id)
	if first and EarnRules.credit(profile, EarnRules.LAB_STAR_GOLD) > 0 and profile == Profile.data:   # owner #79
		Session.gold_changed.emit(profile.survivor_gold)   # a world's gold counter shows it
	if model is LabPlants:
		profile.lab.set_planted(experiment_id, 0)   # picked: the pots are empty for next time
	save_profile.call()
	Audio.play(&"jingle_badge" if first else &"jingle_goal")
	show_why(0, first)


# --- WHY -----------------------------------------------------------------------------------------------------------

func show_why(card: int = 0, first_star: bool = false) -> void:
	_clear(WHY)
	add_child(_header(str(experiment.title), _back, [_steps(2)]))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 30)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	var guess: Variant = profile.lab.guess(experiment_id)
	left.add_child(_left("You guessed:", 22, Color(1, 1, 1, 0.75)))
	left.add_child(_left(LabExperiments.predict_words(experiment, guess) if guess != null else "No guess this time.", 24))
	var kind := _left(GUESS_MATCHED if profile.lab.matched(experiment_id) else GUESS_AGAIN, 22, SchoolUi.GOLD
		if profile.lab.matched(experiment_id) else SchoolUi.HINT)
	kind.name = "Kind"
	left.add_child(kind)
	left.add_child(_left("What happened:", 22, Color(1, 1, 1, 0.75)))
	left.add_child(_left(str(experiment.result), 24))
	if first_star:
		var star_row := HBoxContainer.new()
		star_row.add_theme_constant_override("separation", 10)
		star_row.add_child(LabArt.Star.new(40.0))
		(star_row.get_child(0) as LabArt.Star).filled = true
		var got := _left("A star for your Lab Book!", 24, SchoolUi.GOLD)
		got.custom_minimum_size.x = 320
		star_row.add_child(got)
		var gold := _left(EarnRules.lab_words(), 24, SchoolUi.GOLD)   # owner #79: "+25 gold!" in the same row
		gold.custom_minimum_size.x = 120
		star_row.add_child(gold)
		left.add_child(star_row)
	body.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	var why: Array = experiment.get("why", [])
	why_index = clampi(card, 0, maxi(why.size() - 1, 0))
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", UiKit.box(SchoolUi.PAPER, 18, 20))
	paper.custom_minimum_size = Vector2(600, 250)
	why_card = SchoolUi.words(str(why[why_index]) if not why.is_empty() else "", 26, 560)
	why_card.name = "WhyCard"
	why_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	why_card.add_theme_color_override("font_color", SchoolUi.INK)
	paper.add_child(why_card)
	right.add_child(paper)
	var turn := HBoxContainer.new()
	turn.alignment = BoxContainer.ALIGNMENT_CENTER
	turn.add_theme_constant_override("separation", 18)
	var prev := SchoolUi.button("PREVIOUS", UiKit.BLUE, Vector2(200, 68))
	prev.visible = why_index > 0
	prev.pressed.connect(func() -> void: show_why(why_index - 1))
	turn.add_child(prev)
	turn.add_child(SchoolUi.words("Why? %d of %d" % [why_index + 1, why.size()], 22, 150))
	var next := SchoolUi.button("NEXT", SchoolUi.TEAL, Vector2(200, 68))
	next.visible = why_index < why.size() - 1
	next.pressed.connect(func() -> void: show_why(why_index + 1))
	turn.add_child(next)
	right.add_child(turn)
	body.add_child(right)
	add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	var learn := SchoolUi.button("LEARN MORE", SchoolUi.SUBJECT_COLORS.science, Vector2(300, 80))
	learn.name = "LearnMore"
	learn.pressed.connect(_learn_more)
	row.add_child(learn)
	var again := SchoolUi.button("DO IT AGAIN", UiKit.GREEN, Vector2(300, 80))
	again.pressed.connect(open.bind(experiment_id))
	row.add_child(again)
	var lab_book := SchoolUi.button("LAB BOOK", UiKit.BLUE, Vector2(260, 80))
	lab_book.pressed.connect(show_book)
	row.add_child(lab_book)
	add_child(row)
	ReadAloud.auto(why_card.text)


func _learn_more() -> void:
	var unit := LabExperiments.learn_unit(experiment, profile.school.grade)
	if unit == "":
		return
	if learn_more.is_valid():
		learn_more.call(unit)
	else:
		show_learn(unit)


# --- BOOK and LEARN ------------------------------------------------------------------------------------------------

func show_book() -> void:
	_defaults()
	_clear(BOOK)
	add_child(_header("Science Lab", show_list))   # the page's own title says Lab Book
	var paper := PanelContainer.new()
	var style := UiKit.box(Color("f3e6c4"), 16, 18)
	style.border_color = Color("7a4a24")
	style.set_border_width_all(6)
	paper.add_theme_stylebox_override("panel", style)
	paper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	book = LabBookPage.new()
	var lab := profile.lab
	book.data = func() -> LabData: return lab
	paper.add_child(book)
	add_child(paper)


## The School's unit page inside the Lab (LEARN MORE); its BACK, or the School's own leaving, comes back here.
func show_learn(unit_id: String) -> void:
	_defaults()
	_before_learn = page
	_clear(LEARN)
	school = SchoolScreen.new()
	school.profile = profile
	school.save_profile = save_profile
	school.lab_link = false
	school.home_unit = unit_id
	school.closed.connect(_back_from_learn)
	add_child(school)
	school.show_unit(unit_id)


func _back_from_learn() -> void:
	match _before_learn:
		WHY:
			show_why(why_index)
		PREDICT:
			show_predict()
		_:
			show_list()


## An experiment's BACK: the list, or out of the Lab when a host opened it on this experiment.
func _back() -> void:
	if _direct:
		closed.emit()
	else:
		show_list()


# --- Shared pieces -------------------------------------------------------------------------------------------------

## BACK, the Lab's owl, the title with its speaker (it reads the whole page), then `extra` controls.
func _header(title: String, back: Callable, extra: Array = []) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var b := SchoolUi.button("BACK", UiKit.BLUE, Vector2(150, 64))
	b.name = "Back"
	b.pressed.connect(back)
	row.add_child(b)
	row.add_child(SchoolUi.teacher(64.0))
	var room := SchoolUi.FRAME.x - 150.0 - 64.0 - 64.0 - 16.0 * (3 + extra.size())
	for c: Control in extra:
		room -= c.get_combined_minimum_size().x
	var label := SchoolUi.fit_title(title, room)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var speaker := ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 64.0)
	speaker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(speaker)
	for c: Control in extra:
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(c)
	return row


## The three steps, the one showing lit.
func _steps(at: int) -> Control:
	var row := HBoxContainer.new()
	row.name = "Steps"
	row.add_theme_constant_override("separation", 6)
	for i in STEPS.size():
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiKit.box(SchoolUi.TEAL if i == at else Color(0.2, 0.24, 0.36), 12, 8))
		var l := Label.new()
		l.text = STEPS[i]
		l.add_theme_font_size_override("font_size", 18)
		l.modulate = Color.WHITE if i == at else Color(1, 1, 1, 0.6)
		p.add_child(l)
		row.add_child(p)
	return row


func _small(text: String, action: Callable, width: float) -> Button:
	var b := SchoolUi.button(text, Color(0.2, 0.24, 0.36), Vector2(width, 64))
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(action)
	return b


func _left(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var l := SchoolUi.words(text, font_size, 480)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_color_override("font_color", color)
	return l


## Empties the page (at once: tests look at the new one in the same frame) and names the new one.
func _clear(next: StringName) -> void:
	page = next
	cards.clear()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	view = null
	predict_answer = null
	try_button = null
	what_button = null
	why_card = null
	book = null
	school = null
