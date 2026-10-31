class_name WonderCard
extends PanelContainer
## A wonder's plaque card in the world (owner #78, spec §24): a tap on the plaque by a wonder opens it: its stamp, its
## name (read aloud with a speaker), where and when it was built, whether it still stands, its real facts, QUIZ once the
## child has reached it (the fact quiz in place of the facts, WonderQuizView) and CLOSE. A tour's square's plaque (&"tour"
## on the landing square, &"tour_new" on the New Seven's, &"tour_nature" on the nature square) tells its tour: what it
## is, which are gone or all still standing (or made by nature), and which the child has visited.
## Holds nothing still (the game goes on under it); a game controller has it while it shows (PadFocus).

signal closed

const WIDTH := 760.0

var wonder: StringName
var close_button: Button
var quiz_button: Button
var facts := Label.new()
var quiz := WonderQuizView.new()


## data: () -> WonderData; pay: (gold) -> void; save: () -> void.
func _init(id: StringName, data: Callable, pay: Callable, save: Callable) -> void:
	wonder = id
	name = "WonderCard"
	add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.08, 0.05, 0.95), 22, 24))
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var w: WonderData = data.call()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	add_child(row)
	var stamp := WonderStamp.new(id, _is_tour(id) or w.stamped(id), 120.0)
	stamp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(stamp)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	row.add_child(v)
	var title := UiKit.title(_title(id), 34)
	v.add_child(ReadAloud.with_speaker(title, self, _words))
	var where := Label.new()
	where.text = _where(id)
	where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	where.custom_minimum_size.x = WIDTH
	where.add_theme_font_size_override("font_size", 20)
	where.add_theme_color_override("font_color", Color("ffe14d"))
	v.add_child(where)
	facts.text = _facts(id, w)
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts.custom_minimum_size.x = WIDTH
	facts.add_theme_font_size_override("font_size", 21)
	v.add_child(facts)
	quiz.data = data
	quiz.pay = pay
	quiz.save = save
	quiz.visible = false
	quiz.finished.connect(close)
	v.add_child(quiz)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	quiz_button = UiKit.big_button("QUIZ", UiKit.ORANGE, Vector2(220, 72))
	quiz_button.visible = not _is_tour(id) and WondersPassportRules.may_quiz(w, id)
	quiz_button.pressed.connect(start_quiz)
	buttons.add_child(quiz_button)
	close_button = UiKit.big_button("CLOSE", UiKit.GREEN, Vector2(220, 72))
	close_button.pressed.connect(close)
	buttons.add_child(close_button)
	v.add_child(buttons)


func _ready() -> void:
	PadFocus.take(self, quiz_button if quiz_button.visible else close_button)


## A tour's square's plaque (&"tour", &"tour_new", &"tour_nature"), not a wonder's.
static func _is_tour(id: StringName) -> bool:
	return WonderFacts.tour_of_plaque(id) != &""


static func _title(id: StringName) -> String:
	if _is_tour(id):
		return str(WonderFacts.tour_info(WonderFacts.tour_of_plaque(id)).title)
	return WonderFacts.display_name(id)


static func _where(id: StringName) -> String:
	if _is_tour(id):
		return str(WonderFacts.tour_info(WonderFacts.tour_of_plaque(id)).where)
	var f := WonderFacts.of(id)
	return "%s · %s · %s" % [str(f.get("place", "")), WonderFacts.when_words(id), WonderFacts.status_words(id)]


static func _facts(id: StringName, w: WonderData) -> String:
	var lines: Array[String] = []
	if _is_tour(id):
		var tour := WonderFacts.tour_of_plaque(id)
		for fact: String in WonderFacts.tour_info(tour).facts:
			lines.append("•  " + fact)
		var names: Array[String] = []
		for wid: StringName in WonderFacts.tour_ids(tour):
			names.append(WonderFacts.display_name(wid) + (" (visited)" if w.stamped(wid) else ""))
		lines.append("")
		lines.append(", ".join(names))
		return "\n".join(lines)
	for fact: String in WonderFacts.of(id).get("facts", []):
		lines.append("•  " + fact)
	if not w.stamped(id) and not WondersPassportRules.questions(id).is_empty():
		lines.append("Walk up to it: your Wonders Passport gets its stamp, and then you can take its quiz.")
	return "\n".join(lines)


func _words() -> String:
	return ReadAloud.words_of(self)


## The card's QUIZ: the wonder's questions in place of its facts.
func start_quiz() -> void:
	facts.visible = false
	quiz_button.visible = false
	quiz.visible = true
	quiz.start(wonder)


## Circle / B on the card closes it (the game's Back would open the pause menu under it).
func pad_back() -> bool:
	close()
	return true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if visible and k != null and k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
