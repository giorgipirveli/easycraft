extends GutTest
## Owner #68 (spec §22.1): one exercise on screen. A choice or TRUE / FALSE answers at a tap; a number, an order or a
## build answers with CHECK. A miss says "Not yet" with the hint and lets the child try again; a second miss shows how
## it works and the answer; NEXT then says the exercise is done, once, with whether it was right the first time.

const CHOICE := {"type": "choice", "prompt": "3 × 4 = ?", "choices": ["12", "7", "34"], "answer": 0,
	"hint": "Count 3 rows of 4.", "explain": "3 rows of 4 make 12.", "picture": {"kind": "array", "rows": 3, "cols": 4}}
const NUMBER := {"type": "number", "prompt": "3 km = ? m", "answer": "3,000", "hint": "1 km = 1,000 m."}
const TF := {"type": "truefalse", "prompt": "Every square is a rectangle.", "answer": true, "hint": "Four right angles?"}
const ORDER := {"type": "order", "prompt": "Smallest first.", "items": ["4,210", "4,021", "4,201"], "answer": [1, 2, 0],
	"hint": "Look at the hundreds."}
const SORT := {"type": "sort", "prompt": "Living or not living?", "groups": ["Living", "Not living"],
	"items": ["a tree", "a rock", "a frog", "a cloud"], "answer": [0, 1, 0, 1], "hint": "Does it grow and feed?"}
const MATCH := {"type": "match", "prompt": "Match each animal to its young.", "items": ["cat", "dog", "frog"],
	"matches": ["puppy", "tadpole", "kitten"], "answer": [2, 0, 1], "hint": "What is a baby frog called?"}
const BUILD := {"type": "build", "prompt": "Build 2 rows of 3.", "board": {"cols": 6, "rows": 4, "block": 9, "given": []},
	"goal": {"kind": "array", "rows": 2, "cols": 3}, "hint": "Make a row of 3 first."}
const LABEL := {"type": "label", "prompt": "Label the digestive system.", "hint": "Food goes down from the mouth.",
	"picture": {"kind": "digestion"}, "spots": [[0.5, 0.12], [0.5, 0.45], [0.42, 0.8]],
	"labels": ["stomach", "mouth", "small intestine"], "answer": [1, 0, 2]}

var done: Array = []


func before_each() -> void:
	done.clear()


func _panel(ex: Dictionary) -> ExercisePanel:
	var p := ExercisePanel.new(ex, 0)
	p.answered.connect(func(first: bool) -> void: done.append(first))
	add_child_autofree(p)
	return p


func test_a_right_choice_at_the_first_tap() -> void:
	var p := _panel(CHOICE)
	await wait_process_frames(1)
	p.answer_widget.choose(0)
	assert_eq(p.state, ExercisePanel.RIGHT)
	assert_true(p.next_button.visible)
	assert_true(p.feedback.visible)
	p.next_button.pressed.emit()
	p.next_button.pressed.emit()
	assert_eq(done, [true], "answered once, right the first time")


func test_a_miss_gives_the_hint_then_the_answer() -> void:
	var p := _panel(CHOICE)
	await wait_process_frames(1)
	p.answer_widget.choose(1)
	assert_eq(p.state, ExercisePanel.ASKING, "one more try")
	assert_string_contains(p.feedback.text, "Count 3 rows of 4.")
	assert_false(p.next_button.visible)
	assert_true(p.answer_widget.buttons[1].disabled, "the tried choice rests")
	p.answer_widget.choose(2)
	assert_eq(p.state, ExercisePanel.SHOWN)
	assert_string_contains(p.feedback.text, "3 rows of 4 make 12.")
	assert_true(p.next_button.visible)
	p.next_button.pressed.emit()
	assert_eq(done, [false])


func test_right_on_the_second_try_is_praised_but_not_first_time() -> void:
	var p := _panel(TF)
	await wait_process_frames(1)
	p.answer_widget.choose(1)   # FALSE
	p.answer_widget.choose(0)   # TRUE
	assert_eq(p.state, ExercisePanel.RIGHT)
	assert_true(SchoolWords.RIGHT_AFTER_HELP.has(p.feedback.text.get_slice("\n", 0)))
	p.next_button.pressed.emit()
	assert_eq(done, [false])


func test_a_number_on_the_pad() -> void:
	var p := _panel(NUMBER)
	await wait_process_frames(1)
	var pad: NumberAnswerPad = p.answer_widget
	assert_true(p.check_button.disabled, "nothing typed yet")
	for k in ["3", "0", "0", "0"]:
		pad.press(k)
	assert_eq(pad.box.text, "3,000", "grouped as it is typed")
	assert_false(p.check_button.disabled)
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT, "check twice counts once")
	p.next_button.pressed.emit()
	assert_eq(done, [true])


func test_a_year_on_the_pad_has_no_comma() -> void:
	var p := _panel({"type": "number", "prompt": "What year is MDCCCL?", "answer": "1850", "year": true,
		"hint": "M is 1,000."})
	await wait_process_frames(1)
	var pad: NumberAnswerPad = p.answer_widget
	for k in ["1", "8", "5", "0"]:
		pad.press(k)
	assert_eq(pad.box.text, "1850", "a year, not 1,850")
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


func test_the_pad_shows_only_the_keys_the_answer_needs() -> void:
	var p := _panel({"type": "number", "prompt": "2/8 + 3/8 = ?", "answer": "5/8", "hint": "Add the tops."})
	await wait_process_frames(1)
	var pad: NumberAnswerPad = p.answer_widget
	assert_true(pad.keys.has("/"))
	assert_false(pad.keys.has("."))
	assert_false(pad.keys.has("-"))


func test_order_by_tapping() -> void:
	var p := _panel(ORDER)
	await wait_process_frames(1)
	var o: OrderAnswer = p.answer_widget
	o.tap(1)
	o.tap(2)
	assert_true(p.check_button.disabled, "not every item placed yet")
	o.tap(0)
	assert_eq(o.response(), [1, 2, 0])
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


func test_order_clear_starts_again() -> void:
	var p := _panel(ORDER)
	await wait_process_frames(1)
	var o: OrderAnswer = p.answer_widget
	o.tap(0)
	o.clear()
	assert_eq(o.response(), [])


## The research's new types (§5.3): a tap puts a thing in the next group (and round again); CHECK when all are sorted.
func test_sort_by_tapping_each_thing_into_its_group() -> void:
	var p := _panel(SORT)
	await wait_process_frames(1)
	var s: SortAnswer = p.answer_widget
	assert_eq(s.response(), [-1, -1, -1, -1], "nothing sorted yet")
	s.tap(0)                   # a tree: Living
	s.tap(1)
	s.tap(1)                   # a rock: Living, then Not living
	s.tap(2)
	assert_true(p.check_button.disabled, "the cloud is not sorted yet")
	s.tap(3)
	s.tap(3)
	assert_eq(s.response(), [0, 1, 0, 1])
	assert_string_contains(s.buttons[1].text, "Not living")
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


func test_a_wrong_sort_shows_the_answer_after_two_misses() -> void:
	var p := _panel(SORT)
	await wait_process_frames(1)
	var s: SortAnswer = p.answer_widget
	for i in 4:
		s.tap(i)               # all Living
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.ASKING, "Not yet: try again")
	for i in 4:
		s.tap(i)
		s.tap(i)
		s.tap(i)               # round the groups: back to Living
	p.check_button.pressed.emit()
	assert_eq(s.response(), [0, 1, 0, 1], "the answer shows")


## Tap a thing on the left, then its partner on the right: they get the same number. A tap on a paired one unpairs it.
func test_match_by_tapping_pairs() -> void:
	var p := _panel(MATCH)
	await wait_process_frames(1)
	var m: MatchAnswer = p.answer_widget
	m.tap_left(0)
	m.tap_right(2)             # cat - kitten
	m.tap_left(1)
	m.tap_right(1)             # dog - tadpole (wrong for now)
	m.tap_left(1)              # unpair the dog
	m.tap_left(1)
	m.tap_right(0)             # dog - puppy
	assert_true(p.check_button.disabled, "the frog is not matched yet")
	m.tap_left(2)
	m.tap_right(1)
	assert_eq(m.response(), [2, 0, 1])
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


## The research's "label the diagram" (§5.3): the picture moves to the answer side with numbered pins on it (the left
## keeps the prompt), the labels under it. Tap a label, then its pin: both show the pin's number and colour. A tap on a
## placed label takes it off; a miss clears them all.
func test_label_by_tapping_a_label_then_its_pin() -> void:
	var p := _panel(LABEL)
	await wait_process_frames(2)
	var l: LabelAnswer = p.answer_widget
	assert_null(p.picture, "one picture, the one with the pins")
	assert_not_null(l.picture)
	assert_eq(l.picture.size, ExerciseCheck.LABEL_BOX)
	assert_eq(l.pins.size(), 3)
	for i in 3:
		var centre := l.pins[i].position + l.pins[i].size / 2.0
		var want := Vector2(LABEL.spots[i][0], LABEL.spots[i][1]) * ExerciseCheck.LABEL_BOX
		assert_lt(centre.distance_to(want), 1.0 + LabelAnswer.PIN / 2.0, "pin %d on its spot" % (i + 1))
		assert_gte(l.pins[i].size.x, 48.0, "a pin a finger can hit")
		assert_eq(l.pins[i].text, str(i + 1))
	l.tap_pin(0)                # nothing chosen: nothing happens
	assert_eq(l.response(), [-1, -1, -1])
	l.tap_label(0)
	l.tap_pin(2)                # stomach on 3 (wrong for now)
	l.tap_label(0)              # take it off
	l.tap_label(0)
	l.tap_pin(1)                # stomach on 2
	l.tap_label(1)
	l.tap_pin(0)                # mouth on 1
	assert_true(p.check_button.disabled, "the small intestine is not placed yet")
	assert_string_contains(l.labels[0].text, "2", "the label shows its pin's number")
	l.tap_label(2)
	l.tap_pin(2)
	assert_eq(l.response(), [1, 0, 2])
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


func test_a_pin_beside_the_drawing_has_a_line_to_its_part() -> void:
	var ex := LABEL.duplicate(true)
	ex.spots = [[0.23, 0.16, 0.5, 0.2], [0.77, 0.44, 0.53, 0.5], [0.23, 0.7, 0.44, 0.69]]
	var p := _panel(ex)
	await wait_process_frames(1)
	var l: LabelAnswer = p.answer_widget
	assert_eq(l.leaders.size(), 3, "a line for each pin that points at a part")
	assert_eq(l.leaders[0][1], Vector2(0.5, 0.2) * ExerciseCheck.LABEL_BOX, "it ends at the part")
	assert_eq(l.leaders[0][0], Vector2(0.23, 0.16) * ExerciseCheck.LABEL_BOX, "it starts at the pin")


func test_a_missed_label_clears_and_the_answer_is_shown_after_two() -> void:
	var p := _panel(LABEL)
	await wait_process_frames(1)
	var l: LabelAnswer = p.answer_widget
	for round in 2:
		for i in 3:
			l.tap_label(i)
			l.tap_pin(i)            # every label on the wrong pin but one
		p.check_button.pressed.emit()
		if round == 0:
			assert_eq(l.response(), [-1, -1, -1], "a miss clears the labels")
	assert_eq(p.state, ExercisePanel.SHOWN)
	assert_eq(l.response(), [1, 0, 2], "the worked answer places them")


## The research's "listen and choose" (§5.3): an exercise with a sound has a big LISTEN button that plays it, as
## often as the child likes.
func test_an_exercise_with_a_sound_has_listen() -> void:
	var ex := {"type": "choice", "prompt": "Which note is higher?", "hint": "Listen again: which one sounds like a bird?",
		"choices": ["the first", "the second"], "answer": 1, "sound": {"kind": "notes", "notes": ["C4", "G4"]}}
	var p := _panel(ex)
	await wait_process_frames(1)
	assert_not_null(p.listen_button, "LISTEN")
	assert_gte(p.listen_button.custom_minimum_size.y, 64.0)
	p.listen_button.pressed.emit()
	p.listen_button.pressed.emit()
	assert_eq(p.listens, 2, "again and again")
	assert_not_null(p.sound_player.stream)
	var quiet := _panel(CHOICE)
	await wait_process_frames(1)
	assert_null(quiet.listen_button, "no sound, no LISTEN")


## "Code the robot" (§5.3): tap FORWARD, TURN LEFT, TURN RIGHT to write a program; UNDO takes the last one back; CHECK
## runs it. A miss keeps the program and draws where the robot went, so the child can find the bug.
func test_code_the_robot_by_tapping_commands() -> void:
	var ex := {"type": "robot", "prompt": "Get the robot to the flag.", "hint": "Count the squares.",
		"board": {"cols": 4, "rows": 3, "start": [0, 0], "facing": "E", "goal": [2, 1]}}
	var p := _panel(ex)
	await wait_process_frames(1)
	var r: RobotAnswer = p.answer_widget
	assert_true(p.check_button.disabled, "no program yet")
	r.forward_button.pressed.emit()
	r.forward_button.pressed.emit()
	r.right_button.pressed.emit()
	r.left_button.pressed.emit()
	r.undo_button.pressed.emit()
	assert_eq(r.response(), ["F", "F", "R"])
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.ASKING, "not at the flag yet")
	assert_eq(r.response(), ["F", "F", "R"], "the program stays to fix")
	assert_eq(r.last_run.pos, Vector2i(2, 0), "where the robot went shows")
	r.forward_button.pressed.emit()
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


## "Copy the rhythm": LISTEN plays the claps; a tap on a beat box turns it into a clap (and back into a rest); MINE plays
## the child's own pattern; CHECK when they are ready.
func test_copy_the_rhythm_by_tapping_boxes() -> void:
	var ex := {"type": "rhythm", "prompt": "Listen, then copy the claps.", "hint": "Listen for the gaps.",
		"sound": {"kind": "rhythm", "pattern": "x--x", "tempo": 90}}
	var p := _panel(ex)
	await wait_process_frames(1)
	var r: RhythmAnswer = p.answer_widget
	assert_not_null(p.listen_button, "LISTEN plays the claps to copy")
	assert_eq(r.boxes.size(), 4)
	assert_eq(r.response(), "----")
	r.boxes[0].pressed.emit()
	r.boxes[2].pressed.emit()
	r.boxes[2].pressed.emit()
	r.boxes[3].pressed.emit()
	assert_eq(r.response(), "x--x")
	r.mine_button.pressed.emit()
	assert_not_null(r.player.stream, "the child's own pattern plays")
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


## "Mix the colour": a tap on a paint pot adds a drop to the bowl, which shows the mixed colour; CLEAR empties it.
func test_mix_the_colour_with_drops() -> void:
	var ex := {"type": "mix", "prompt": "Make green.", "hint": "Blue and one more.", "target": "green"}
	var p := _panel(ex)
	await wait_process_frames(1)
	var m: MixAnswer = p.answer_widget
	assert_true(p.check_button.disabled, "an empty bowl")
	m.pots["blue"].pressed.emit()
	m.pots["red"].pressed.emit()
	m.clear_button.pressed.emit()
	assert_eq(m.response(), {})
	m.pots["blue"].pressed.emit()
	m.pots["yellow"].pressed.emit()
	assert_eq(m.response(), {"blue": 1, "yellow": 1})
	assert_true(m.bowl_colour().g > m.bowl_colour().r, "the bowl looks green")
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


## The worked answer is said once: an explanation that already gives it (in any case) is not followed by "The answer
## is …", and a sentence never ends in two full stops.
func test_the_worked_answer_is_not_said_twice() -> void:
	var ex := SORT.duplicate(true)
	ex.groups = ["living", "never living"]
	ex.explain = "Living: a tree, a frog. Never living: a rock, a cloud."
	var p := _panel(ex)
	await wait_process_frames(1)
	var s: SortAnswer = p.answer_widget
	for n in 2:
		for i in 4:
			s.tap(i)
		p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.SHOWN)
	assert_false(p.feedback.text.contains("The answer is"), p.feedback.text)
	assert_false(p.feedback.text.contains(".."), p.feedback.text)


func test_build_on_the_board() -> void:
	var p := _panel(BUILD)
	await wait_process_frames(1)
	var b: BuildBoard = p.answer_widget
	for x in 3:
		for y in 2:
			b.toggle(Vector2i(x, y))
	assert_eq(b.placed.size(), 6)
	assert_string_contains(b.count_label.text, "6 blocks")
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.RIGHT)


func test_a_build_shown_after_two_misses() -> void:
	var p := _panel(BUILD)
	await wait_process_frames(1)
	var b: BuildBoard = p.answer_widget
	b.toggle(Vector2i(0, 0))
	p.check_button.pressed.emit()
	p.check_button.pressed.emit()
	assert_eq(p.state, ExercisePanel.SHOWN)
	assert_true(BuildCheck.check(BUILD.goal, BUILD.board, b.cells()), "the board now shows a right build")


func test_given_blocks_stay() -> void:
	var ex := BUILD.duplicate(true)
	ex.board.given = [[0, 0]]
	ex.goal = {"kind": "count", "n": 3}
	var p := _panel(ex)
	await wait_process_frames(1)
	var b: BuildBoard = p.answer_widget
	b.toggle(Vector2i(0, 0))
	assert_true(b.cells().has(Vector2i(0, 0)), "a given block can't be taken away")


func test_it_fits_its_frame() -> void:
	var robot := {"type": "robot", "prompt": "Get the robot to the flag.", "hint": "Count the squares.",
		"board": {"cols": 8, "rows": 8, "start": [0, 0], "facing": "E", "goal": [7, 7]}}
	var rhythm := {"type": "rhythm", "prompt": "Copy the claps.", "hint": "Listen again.",
		"sound": {"kind": "rhythm", "pattern": "x-x-xx-x", "tempo": 120}}
	var mix := {"type": "mix", "prompt": "Make a light green.", "hint": "Green first, then white.", "target": "light green"}
	var long_sort := {"type": "sort", "prompt": "Which food group?", "hint": "Where does it come from?",
		"groups": ["Fruit and vegetables", "Starchy foods like bread", "Proteins such as beans"],
		"items": ["a big bowl of porridge with milk and honey", "a crunchy green apple from the tree",
		"a handful of roasted chickpeas and lentils", "brown rice with peas and sweetcorn on top",
		"carrot sticks with a spoonful of hummus", "a slice of wholemeal toast with jam"],
		"answer": [1, 0, 2, 1, 0, 1]}
	var long_labels := LABEL.duplicate(true)
	long_labels.labels = ["the long gullet tube", "a very big stomach bag", "the small intestine", "the large intestine",
		"the mouth with teeth"]
	long_labels.spots = [[0.1, 0.1], [0.5, 0.1], [0.9, 0.1], [0.3, 0.9], [0.7, 0.9]]
	long_labels.answer = [1, 0, 2, 3, 4]
	for ex: Dictionary in [CHOICE, NUMBER, TF, ORDER, BUILD, SORT, MATCH, robot, rhythm, mix, long_sort, LABEL,
			long_labels]:
		var p := _panel(ex)
		await wait_process_frames(2)
		var size := p.get_combined_minimum_size()
		assert_lte(size.x, ExercisePanel.SIZE.x, "%s width %s" % [ex.type, size])
		assert_lte(size.y, ExercisePanel.SIZE.y, "%s height %s" % [ex.type, size])


func test_the_speaker_reads_the_prompt_in_words() -> void:
	var p := _panel(CHOICE)
	await wait_process_frames(1)
	assert_string_contains(p.spoken_text(), "3 times 4 equals what")
	assert_string_contains(p.spoken_text(), "12", "the choices too")


## Every hand-written exercise of the written units fits the exercise panel (a long sort's groups once pushed the answer
## column off the screen: the grade 3 life agent's report). One panel per exercise, freed at once.
func test_every_written_exercise_fits_its_frame() -> void:
	var too_big: Array[String] = []
	var checked := 0
	for g in Curriculum.grades():
		for sub: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(sub.id)):
				var c := Curriculum.content(str(u.id))
				if c.is_empty():
					continue
				for ex: Dictionary in c.exercises:
					if not str(ex.type) in ["sort", "match", "order", "choice", "mix", "robot", "rhythm", "label"]:
						continue
					var p := ExercisePanel.new(ex, 0)
					add_child(p)
					var need := p.get_combined_minimum_size()
					if need.x > ExercisePanel.SIZE.x or need.y > ExercisePanel.SIZE.y:
						too_big.append("%s: %s %s" % [ex.id, ex.type, need])
					checked += 1
					p.free()
	for t in too_big:
		print("TOO_BIG ", t)
	assert_eq(too_big, [] as Array[String], "every exercise fits")
	assert_gt(checked, 500, "the written exercises were checked")

