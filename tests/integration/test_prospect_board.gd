extends GutTest
## Gemma's board (spec §26.2): her quests as cards (START, GO ON, FIND ANOTHER; the other world's say where they are),
## a quest's steps as School exercises (the map drawn from this world inside the map step), a walk's card (LET'S GO),
## MARK IT, the find (the gold, how it is dug out and refined), MY FINDS. It fits a phone and a PC screen.

const CAMP := Vector3(10, 40, 20)

var board: ProspectBoard
var started: Array = []
var answered: Array = []
var marked: Array = []
var _steps: Array[Dictionary] = []
var _at := 0


func before_each() -> void:
	started.clear()
	answered.clear()
	marked.clear()
	board = ProspectBoard.new()
	add_child_autofree(board)
	board.quests = func() -> Array:
		var out: Array = []
		for k in DepositKinds.told_in(1):   # Earth's six (spec §26.5: a board tells its place's quests)
			out.append({"kind": k, "title": ProspectQuests.quest(k).title, "here": DepositKinds.universe_of(k) == 1,
				"where": "the Sandstorm Desert", "status": "going" if k == DepositKinds.IRON else "new", "step": 2,
				"steps": 7, "found": 1 if k == DepositKinds.COAL else 0})
		return out
	board.step_view = func(kind: StringName) -> Dictionary:
		if _steps.is_empty() or _at >= _steps.size():
			return {}
		return {"kind": kind, "title": "Gold in the hills", "index": _at, "count": _steps.size(), "step": _steps[_at]}
	board.distance_to = func(_k: StringName) -> int: return 240
	board.start_pressed.connect(func(k: StringName) -> void: started.append(k))
	board.step_answered.connect(func(k: StringName, i: int) -> void: answered.append([k, i]))
	board.mark_pressed.connect(func(k: StringName) -> void: marked.append(k))
	var shape := MeadowsBiomeShape.new(12345)
	var rules := DepositRules.for_world(12345, shape, SecretRules.new(12345, shape))
	_steps = ProspectQuests.steps(DepositKinds.GOLD, rules.nearest(DepositKinds.GOLD, CAMP), CAMP, 3)
	_at = 0
	await wait_process_frames(1)


func test_the_quests_cards() -> void:
	board.open_quests()
	await wait_process_frames(2)
	assert_true(board.visible)
	assert_eq(board.view, ProspectBoard.QUESTS)
	assert_eq(board.cards.size(), 6)
	var gold := board.find_child("Quest_gold", true, false) as Button
	assert_false(gold.disabled)
	assert_eq(gold.get_meta(&"action"), "START")
	assert_eq((board.find_child("Quest_iron", true, false) as Button).get_meta(&"action"), "GO ON")
	assert_eq((board.find_child("Quest_coal", true, false) as Button).get_meta(&"action"), "FIND ANOTHER")
	var oil := board.find_child("Quest_oil", true, false) as Button
	assert_true(oil.disabled, "the desert's quests are told in the desert")
	assert_true(_texts(oil).any(func(t: String) -> bool: return t.contains("Sandstorm Desert")))
	gold.pressed.emit()
	assert_eq(started, [DepositKinds.GOLD])
	await _fits()


func test_a_guest_reads_but_does_not_start() -> void:
	board.guest = true
	board.open_quests()
	await wait_process_frames(1)
	assert_true((board.find_child("Quest_gold", true, false) as Button).disabled)
	assert_true(_texts(board).any(func(t: String) -> bool: return t.contains("friend's world")))


func test_the_map_step_draws_this_worlds_map_and_answers() -> void:
	board.open_step(DepositKinds.GOLD)
	await wait_process_frames(2)
	assert_eq(board.view, ProspectBoard.STEP)
	assert_not_null(board.exercise)
	var map := board.exercise.find_child("QuestMap", true, false) as ProspectMap
	assert_not_null(map, "the map is inside the exercise")
	assert_not_null(map.picture, "drawn from the ground")
	var x := map.to_map(_steps[0].map.target)
	assert_true(Rect2(Vector2.ONE * ProspectMap.LABEL_PX, Vector2.ONE * ProspectMap.MAP_PX).has_point(x), "the X is on the map")
	await _fits()
	_answer(board.exercise)
	assert_eq(answered, [[DepositKinds.GOLD, 0]])


func test_a_quiz_is_answered_one_exercise_after_another() -> void:
	_at = _index_of(ProspectQuests.QUIZ)
	board.open_step(DepositKinds.GOLD)
	await wait_process_frames(1)
	var n := ProspectQuests.exercises(_steps[_at]).size()
	for i in n:
		assert_eq(answered.size(), 0, "not done after %d of %d" % [i, n])
		_answer(board.exercise)
		await wait_process_frames(1)
	assert_eq(answered, [[DepositKinds.GOLD, _at]], "the step is answered once, at the end")


func test_a_walk_says_where_and_lets_go() -> void:
	_at = _index_of(ProspectQuests.REACH)
	board.open_step(DepositKinds.GOLD)
	await wait_process_frames(1)
	var words := board.find_child("StepWords", true, false) as Label
	assert_string_contains(words.text, "Walk to the river")
	assert_true(_texts(board).any(func(t: String) -> bool: return t.contains("240 m")), "how far it is")
	board.action_button.pressed.emit()
	assert_false(board.visible, "LET'S GO closes the board")


func test_mark_it_and_the_find() -> void:
	_at = _steps.size() - 1
	board.open_step(DepositKinds.GOLD)
	await wait_process_frames(1)
	assert_eq(board.action_button.name, "MarkIt")
	board.action_button.pressed.emit()
	assert_eq(marked, [DepositKinds.GOLD])
	board.show_done(DepositKinds.GOLD, "+100 gold: you found your first gold!", "gold vein")
	await wait_process_frames(1)
	assert_eq(board.view, ProspectBoard.DONE)
	var texts := _texts(board)
	assert_true(texts.any(func(t: String) -> bool: return t.contains("+100 gold")))
	assert_true(texts.any(func(t: String) -> bool: return t.contains("4 Gold Quartz → 1 Gold in the Clay Oven")),
		"how it is refined: %s" % str(texts))
	await _fits()
	board.action_button.pressed.emit()
	assert_eq(board.view, ProspectBoard.QUESTS)


func test_my_finds_and_closing() -> void:
	board.finds = func() -> Array: return [{"kind": DepositKinds.COAL, "name": "Coal seam", "pos": Vector3.ZERO}]
	board.open_quests()
	await wait_process_frames(1)
	(board.find_child("MyFinds", true, false) as Button).pressed.emit()
	assert_eq(board.view, ProspectBoard.FINDS)
	assert_true(_texts(board).any(func(t: String) -> bool: return t == "Coal seam"))
	assert_true(board.close_if_open())
	assert_false(board.visible)
	assert_false(board.close_if_open())


func _index_of(type: StringName) -> int:
	for i in _steps.size():
		if _steps[i].type == type:
			return i
	return -1


## Answers the exercise on screen right, then NEXT.
func _answer(p: ExercisePanel) -> void:
	var ex := p.ex
	match str(ex.type):
		"choice":
			p.answer_widget.choose(int(ex.answer))
		"truefalse":
			p.answer_widget.choose(0 if bool(ex.answer) else 1)
		"number":
			for ch in str(ex.answer):
				p.answer_widget.press(ch)
			p.check_button.pressed.emit()
		"order":
			for i: int in ex.answer:
				p.answer_widget.tap(i)
			p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT, "answered right: %s" % ex.prompt)
	p.next_button.pressed.emit()


func _texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	for l in root.find_children("*", "Label", true, false):
		out.append((l as Label).text)
	return out


## The panel fits the screen (scaled down on a small one, never cut).
func _fits() -> void:
	await wait_process_frames(2)
	var panel := board._panel
	var need := panel.get_combined_minimum_size() * panel.scale
	var room := board.get_viewport_rect().size
	assert_lte(need.x, room.x + 1.0, "width %s in %s" % [need, room])
	assert_lte(need.y, room.y + 1.0, "height %s in %s" % [need, room])
