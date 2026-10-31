extends GutTest
## Owner #94 (the lesson-quality brief, "the School's teaching, beyond the files"): an answer right after a hint also
## shows why (the worked answer), so a lucky second tap still teaches; Professor Hoot's praise changes from round to
## round (not the same six lines in the same order every time); and every hand-written exercise's worked answer fits
## its panel with the picture beside it (a long one shrinks the picture, then the words, never off the card).

const TF := {"type": "truefalse", "prompt": "Every square is a rectangle.", "answer": true,
	"hint": "Does a square have four right angles?", "explain": "A square has four right angles, so it is a rectangle."}
const NO_WHY := {"type": "truefalse", "prompt": "Every square is a rectangle.", "answer": true,
	"hint": "Does a square have four right angles?"}
const LONG := {"type": "choice", "level": 3, "picture": {"kind": "array", "rows": 3, "cols": 4},
	"prompt": "Zara builds 3 rows of 4 blocks, then Bram adds 2 more rows of 4 on top of hers. How many blocks are in the whole wall now? Count the rows first.",
	"choices": ["20", "12", "14", "24"], "answer": 0, "hint": "Count the rows: 3 of Zara's and 2 of Bram's. Each row has 4.",
	"explain": "Zara's wall has 3 rows and Bram adds 2 more, so the wall has 3 + 2 = 5 rows. Each row has 4 blocks, so 5 × 4 = 20 blocks in the whole wall. You can check by counting in fours: 4, 8, 12, 16, 20. That is the answer."}


func _panel(ex: Dictionary, praise_from: int = 0) -> ExercisePanel:
	var p := ExercisePanel.new(ex, 0)
	p.praise_from = praise_from
	add_child_autofree(p)
	return p


func test_right_after_a_hint_shows_why() -> void:
	var p := _panel(TF)
	await wait_process_frames(1)
	p.answer_widget.choose(1)   # FALSE: not yet, the hint
	p.answer_widget.choose(0)   # TRUE
	assert_eq(p.state, ExercisePanel.RIGHT)
	assert_true(SchoolWords.RIGHT_AFTER_HELP.has(p.feedback.text.get_slice("\n", 0)), "praise first")
	assert_string_contains(p.feedback.text, TF.explain)
	assert_string_contains(p.feedback.text, SchoolWords.HERE_IS_WHY)


func test_right_after_a_hint_without_a_worked_answer_is_only_praise() -> void:
	var p := _panel(NO_WHY)
	await wait_process_frames(1)
	p.answer_widget.choose(1)
	p.answer_widget.choose(0)
	assert_eq(p.feedback.text.get_slice_count("\n"), 1, p.feedback.text)


func test_right_the_first_time_is_praise_only() -> void:
	var p := _panel(TF)
	await wait_process_frames(1)
	p.answer_widget.choose(0)
	assert_false(p.feedback.text.contains(TF.explain), "no lesson when it is known")


func test_praise_changes_from_round_to_round() -> void:
	var first_lines := {}
	for seed in 12:
		var p := _panel(TF, seed * 7919)
		await wait_process_frames(1)
		p.answer_widget.choose(0)
		first_lines[p.feedback.text.get_slice("\n", 0)] = true
	assert_gte(first_lines.size(), 5, "the first answer's praise varies: %s" % [first_lines.keys()])
	for line: String in first_lines:
		assert_true(SchoolWords.RIGHT.has(line), line)


func test_the_praise_is_for_effort_and_strategy() -> void:
	assert_gte(SchoolWords.RIGHT.size(), 10, "enough to vary")
	assert_gte(SchoolWords.RIGHT_AFTER_HELP.size(), 5)
	for line in SchoolWords.RIGHT + SchoolWords.RIGHT_AFTER_HELP:
		for word: String in ["genius", "smart", "clever", "wrong", "failed", "bad", "easy", "natural", "talent"]:
			assert_false(line.to_lower().contains(word), "'%s' in '%s'" % [word, line])


func test_a_long_worked_answer_shrinks_the_picture_to_fit() -> void:
	var p := _panel(LONG)
	await wait_process_frames(1)
	p.answer_widget.choose(1)
	p.answer_widget.choose(2)
	assert_eq(p.state, ExercisePanel.SHOWN)
	assert_lte(p.left_column.get_combined_minimum_size().y, ExercisePanel.SIZE.y, "the worked answer fits")
	assert_lt(p.picture.custom_minimum_size.y, ExercisePanel.PICTURE.y, "the picture gave way")
	assert_gte(p.picture.custom_minimum_size.y, ExercisePanel.MIN_PICTURE_H, "and is still a picture")


func test_every_hand_written_worked_answer_fits_its_panel() -> void:
	var over: Array[String] = []
	var n := 0
	for g in [3, 4, 5, 6, 7]:
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				if not Curriculum.has_content(str(u.id)):
					continue
				for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
					var p := ExercisePanel.new(ex, 0)
					add_child(p)
					p.show_worked_answer()
					var h := p.left_column.get_combined_minimum_size().y
					if h > ExercisePanel.SIZE.y:
						over.append("%s: %d" % [ex.id, int(h)])
					p.free()
					n += 1
	gut.p("%d exercises' worked answers" % n)
	assert_eq(over, [] as Array[String], "\n".join(over))
