extends GutTest
## Owner #68 (spec §22.1, §22.5): every exercise type's checker. An exercise in the data is valid (`problem` says "")
## and its own right answer (`answer_of`) passes its own checker; other answers do not.

const CHOICE := {"type": "choice", "prompt": "3 × 4 = ?", "choices": ["12", "7", "34"], "answer": 0,
	"hint": "Count 3 rows of 4.", "explain": "3 rows of 4 make 12."}
const NUMBER := {"type": "number", "prompt": "3 km = ? m", "answer": "3,000", "hint": "1 km = 1,000 m."}
const FRACTION := {"type": "number", "prompt": "2/8 + 3/8 = ?", "answer": "5/8", "hint": "Add the tops."}
const TF := {"type": "truefalse", "prompt": "Every square is a rectangle.", "answer": true, "hint": "Four right angles?"}
const ORDER := {"type": "order", "prompt": "Smallest first.", "items": ["4,210", "4,021", "4,201"], "answer": [1, 2, 0],
	"hint": "Look at the hundreds."}
## The research's new types (docs/design/school-curriculum-research.md §5.3): sort things into groups, match pairs.
const SORT := {"type": "sort", "prompt": "Living or not living?", "groups": ["Living", "Not living"],
	"items": ["a tree", "a rock", "a frog", "a cloud"], "answer": [0, 1, 0, 1], "hint": "Does it grow and feed?"}
const MATCH := {"type": "match", "prompt": "Match each animal to its young.", "items": ["cat", "dog", "frog"],
	"matches": ["puppy", "tadpole", "kitten"], "answer": [2, 0, 1], "hint": "What is a baby frog called?"}
const BUILD := {"type": "build", "prompt": "Build 3 rows of 4.", "board": {"cols": 8, "rows": 5, "block": 9, "given": []},
	"goal": {"kind": "array", "rows": 3, "cols": 4}, "hint": "Make a row of 4 first."}


func test_the_samples_are_valid_and_their_answers_are_right() -> void:
	for ex: Dictionary in [CHOICE, NUMBER, FRACTION, TF, ORDER, BUILD, SORT, MATCH]:
		assert_eq(ExerciseCheck.problem(ex), "", "%s is valid" % ex.type)
		assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)), "%s: its own answer is right" % ex.type)


func test_choice() -> void:
	assert_true(ExerciseCheck.is_right(CHOICE, 0))
	assert_false(ExerciseCheck.is_right(CHOICE, 1))
	assert_false(ExerciseCheck.is_right(CHOICE, "0"), "an index, not text")
	assert_false(ExerciseCheck.is_right(CHOICE, -1))


func test_number_by_value() -> void:
	assert_true(ExerciseCheck.is_right(NUMBER, "3000"))
	assert_false(ExerciseCheck.is_right(NUMBER, "300"))
	assert_false(ExerciseCheck.is_right(NUMBER, ""))
	assert_true(ExerciseCheck.is_right(FRACTION, "10/16"), "an equal fraction is right")
	assert_false(ExerciseCheck.is_right(FRACTION, "5/6"))
	var also := NUMBER.duplicate()
	also.accept = ["3000.0"]
	assert_true(ExerciseCheck.is_right(also, "3000"))
	assert_eq(ExerciseCheck.answer_of(NUMBER), "3000", "typed without commas")


func test_true_false() -> void:
	assert_true(ExerciseCheck.is_right(TF, true))
	assert_false(ExerciseCheck.is_right(TF, false))
	assert_false(ExerciseCheck.is_right(TF, 1))


func test_order() -> void:
	assert_true(ExerciseCheck.is_right(ORDER, [1, 2, 0]))
	assert_false(ExerciseCheck.is_right(ORDER, [1, 0, 2]))
	assert_false(ExerciseCheck.is_right(ORDER, [1, 2]), "not finished")


func test_sort_into_groups() -> void:
	assert_true(ExerciseCheck.is_right(SORT, [0, 1, 0, 1]))
	assert_false(ExerciseCheck.is_right(SORT, [0, 0, 0, 1]))
	assert_false(ExerciseCheck.is_right(SORT, [0, 1, 0, -1]), "one not sorted yet")
	assert_false(ExerciseCheck.is_right(SORT, [0, 1, 0]))
	assert_eq(ExerciseCheck.answer_text(SORT), "Living: a tree, a frog. Not living: a rock, a cloud.")
	var bad := {
		"one group": {"groups": ["Living"]},
		"four groups": {"groups": ["a", "b", "c", "d"]},
		"all in one group": {"answer": [0, 0, 0, 0]},
		"an answer per item": {"answer": [0, 1, 0]},
		"a group that is not there": {"answer": [0, 1, 0, 2]},
		"two items the same": {"items": ["a tree", "a tree", "a frog", "a cloud"]},
	}
	for why: String in bad:
		var ex := SORT.duplicate(true)
		ex.merge(bad[why], true)
		assert_ne(ExerciseCheck.problem(ex), "", why)


func test_a_sorts_answer_in_words_starts_each_group_with_a_capital() -> void:
	var ex := SORT.duplicate(true)
	ex.groups = ["living", "never living"]
	assert_eq(ExerciseCheck.answer_text(ex), "Living: a tree, a frog. Never living: a rock, a cloud.")


func test_match_pairs() -> void:
	assert_true(ExerciseCheck.is_right(MATCH, [2, 0, 1]))
	assert_false(ExerciseCheck.is_right(MATCH, [0, 2, 1]))
	assert_false(ExerciseCheck.is_right(MATCH, [2, 0, -1]), "one not matched yet")
	assert_eq(ExerciseCheck.answer_text(MATCH), "cat: kitten, dog: puppy, frog: tadpole")
	var bad := {
		"one pair": {"items": ["cat"], "matches": ["kitten"], "answer": [0]},
		"not as many matches": {"matches": ["puppy", "tadpole"]},
		"a match used twice": {"answer": [2, 2, 1]},
		"already side by side": {"answer": [0, 1, 2]},
		"too long for its column": {"matches": ["a very young dog, still with its mum", "tadpole", "kitten"]},
	}
	for why: String in bad:
		var ex := MATCH.duplicate(true)
		ex.merge(bad[why], true)
		assert_ne(ExerciseCheck.problem(ex), "", why)


## "Copy the rhythm" (§5.3 tap the rhythm): the child hears claps (the exercise's own rhythm sound) and marks each beat
## box as a clap or a rest; the pattern is checked, never the speed.
func test_copy_the_rhythm() -> void:
	var ex := {"type": "rhythm", "prompt": "Listen, then copy the claps.", "hint": "Listen for the gaps.",
		"sound": {"kind": "rhythm", "pattern": "x-x-xx--", "tempo": 90}}
	assert_eq(ExerciseCheck.problem(ex), "")
	assert_true(ExerciseCheck.is_right(ex, "x-x-xx--"))
	assert_false(ExerciseCheck.is_right(ex, "x-x-x---"))
	assert_false(ExerciseCheck.is_right(ex, ["x"]))
	assert_eq(ExerciseCheck.answer_of(ex), "x-x-xx--")
	assert_eq(ExerciseCheck.answer_text(ex), "clap, rest, clap, rest, clap, clap, rest, rest")
	ex.sound = {"kind": "rhythm", "pattern": "x-x-xx--x", "tempo": 90}
	assert_ne(ExerciseCheck.problem(ex), "", "at most 8 beat boxes")
	ex.sound = {"kind": "notes", "notes": ["C4"]}
	assert_ne(ExerciseCheck.problem(ex), "", "a rhythm to copy is claps")
	ex.erase("sound")
	assert_ne(ExerciseCheck.problem(ex), "", "nothing to hear")


## "Mix the colour" (§5.3; art: colour mixing): drops of paint in a bowl make the target colour when their shares
## match its recipe (painters' primaries: red + yellow = orange, yellow + blue = green, red + blue = purple; a colour
## with white is a tint, with black a shade; the three primaries together make brown).
func test_mix_the_colour_by_its_recipe() -> void:
	var ex := {"type": "mix", "prompt": "Make orange.", "hint": "Which two primaries?", "target": "orange"}
	assert_eq(ExerciseCheck.problem(ex), "")
	assert_true(ExerciseCheck.is_right(ex, {"red": 1, "yellow": 1}))
	assert_true(ExerciseCheck.is_right(ex, {"red": 3, "yellow": 3}), "the same shares")
	assert_false(ExerciseCheck.is_right(ex, {"red": 1, "yellow": 2}), "more yellow: a yellow-orange")
	assert_false(ExerciseCheck.is_right(ex, {"red": 1, "blue": 1}))
	assert_false(ExerciseCheck.is_right(ex, {}))
	assert_eq(ExerciseCheck.answer_of(ex), {"red": 1, "yellow": 1})
	assert_eq(ExerciseCheck.answer_text(ex), "1 red and 1 yellow")
	for target: String in ["green", "purple", "pink", "dark blue", "brown", "light green"]:
		var e := ex.duplicate()
		e.target = target
		assert_eq(ExerciseCheck.problem(e), "", target)
		assert_true(ExerciseCheck.is_right(e, ExerciseCheck.answer_of(e)), target)
	ex.target = "gold"
	assert_ne(ExerciseCheck.problem(ex), "", "a colour the paints can't make")


func test_build() -> void:
	var cells: Array[Vector2i] = []
	for y in 3:
		for x in 4:
			cells.append(Vector2i(x, y))
	assert_true(ExerciseCheck.is_right(BUILD, cells))
	cells.pop_back()
	assert_false(ExerciseCheck.is_right(BUILD, cells))


func test_answer_text_for_the_worked_answer() -> void:
	assert_eq(ExerciseCheck.answer_text(CHOICE), "12")
	assert_eq(ExerciseCheck.answer_text(NUMBER), "3,000")
	assert_eq(ExerciseCheck.answer_text(TF), "True")
	assert_eq(ExerciseCheck.answer_text(ORDER), "4,021, 4,201, 4,210")


func test_pad_keys_follow_the_answer() -> void:
	assert_eq(ExerciseCheck.pad_keys(NUMBER), [] as Array[String])
	assert_eq(ExerciseCheck.pad_keys(FRACTION), ["/"] as Array[String])


func test_problems_are_found() -> void:
	var bad := {
		"no prompt": {"type": "truefalse", "prompt": "", "answer": true, "hint": "h"},
		"no hint": {"type": "truefalse", "prompt": "p", "answer": true},
		"unknown type": {"type": "essay", "prompt": "p", "hint": "h"},
		"answer out of range": {"type": "choice", "prompt": "p", "choices": ["a", "b"], "answer": 2, "hint": "h"},
		"one choice": {"type": "choice", "prompt": "p", "choices": ["a"], "answer": 0, "hint": "h"},
		"same choices": {"type": "choice", "prompt": "p", "choices": ["a", "a"], "answer": 0, "hint": "h"},
		"not a number": {"type": "number", "prompt": "p", "answer": "twelve", "hint": "h"},
		"too long to type": {"type": "number", "prompt": "p", "answer": "12345678901", "hint": "h"},
		"order already right": {"type": "order", "prompt": "p", "items": ["a", "b"], "answer": [0, 1], "hint": "h"},
		"order not a shuffle": {"type": "order", "prompt": "p", "items": ["a", "b", "c"], "answer": [1, 1, 0], "hint": "h"},
		"true/false not a bool": {"type": "truefalse", "prompt": "p", "answer": "yes", "hint": "h"},
		"build that cannot be done": {"type": "build", "prompt": "p", "board": {"cols": 2, "rows": 2, "block": 9},
			"goal": {"kind": "count", "n": 9}, "hint": "h"},
		"level 4": {"type": "truefalse", "prompt": "p", "answer": true, "hint": "h", "level": 4},
		"a prompt too long for the panel": {"type": "truefalse", "prompt": "word ".repeat(40), "answer": true, "hint": "h"},
		"a choice too long for its button": {"type": "choice", "prompt": "p", "choices": ["a", "long ".repeat(15)],
			"answer": 0, "hint": "h"},
	}
	for why: String in bad:
		assert_ne(ExerciseCheck.problem(bad[why]), "", why)


func test_choices_may_be_pictures() -> void:
	var ex := {"type": "choice", "prompt": "Which shows 3/4?", "hint": "Count the shaded parts.", "answer": 1,
		"choices": [{"picture": {"kind": "bar", "den": 4, "num": 1}}, {"picture": {"kind": "bar", "den": 4, "num": 3}}]}
	assert_eq(ExerciseCheck.problem(ex), "")
	assert_true(ExerciseCheck.is_right(ex, 1))


## A number exercise whose answer is a year says so ("year": true): the pad and the worked answer show "1850", never
## "1,850".
func test_a_year_answer_is_shown_without_a_comma() -> void:
	var ex := {"type": "number", "prompt": "What year is MDCCCL?", "answer": "1850", "year": true, "hint": "M is 1,000."}
	assert_eq(ExerciseCheck.problem(ex), "")
	assert_eq(ExerciseCheck.answer_text(ex), "1850")
	assert_false(ExerciseCheck.grouped(ex))
	assert_true(ExerciseCheck.grouped(NUMBER))
	assert_true(ExerciseCheck.is_right(ex, "1850"))
	var bad := ex.duplicate()
	bad.year = "yes"
	assert_ne(ExerciseCheck.problem(bad), "", "year is true or false")
	bad = ex.duplicate()
	bad.answer = "18.5"
	assert_ne(ExerciseCheck.problem(bad), "", "a year is a whole number")


## The research's "label the diagram" (§5.3; the parts of a plant, the digestive system, a volcano, the continents):
## numbered pins on the picture, the labels beside it; each label goes to its pin. Pins are fractions of the picture's
## box (LabelAnswer.PICTURE), never side by side with their labels in order.
const LABEL := {"type": "label", "prompt": "Label the digestive system.", "hint": "Food goes down from the mouth.",
	"picture": {"kind": "digestion"}, "spots": [[0.5, 0.12], [0.5, 0.45], [0.42, 0.8]],
	"labels": ["stomach", "mouth", "small intestine"], "answer": [1, 0, 2]}


func test_label_is_valid_and_checked_like_pairs() -> void:
	assert_eq(ExerciseCheck.problem(LABEL), "")
	assert_true(ExerciseCheck.is_right(LABEL, [1, 0, 2]))
	assert_true(ExerciseCheck.is_right(LABEL, ExerciseCheck.answer_of(LABEL)))
	assert_false(ExerciseCheck.is_right(LABEL, [0, 1, 2]))
	assert_false(ExerciseCheck.is_right(LABEL, [1, 0, -1]), "every label placed")
	assert_eq(ExerciseCheck.answer_text(LABEL), "1: mouth, 2: stomach, 3: small intestine", "pin by pin")


func test_label_problems() -> void:
	var cases := {
		"no picture": {"picture": null},
		"too few spots": {"spots": [[0.5, 0.5]], "labels": ["mouth"], "answer": [0]},
		"a spot off the picture": {"spots": [[0.5, 0.12], [1.2, 0.45], [0.42, 0.8]]},
		"a spot that is not a point": {"spots": [[0.5, 0.12], "middle", [0.42, 0.8]]},
		"spots on top of each other": {"spots": [[0.5, 0.12], [0.52, 0.13], [0.42, 0.8]]},
		"labels and spots differ": {"labels": ["stomach", "mouth"], "answer": [1, 0]},
		"the same label twice": {"labels": ["mouth", "mouth", "gullet"]},
		"a long label": {"labels": ["stomach", "mouth", "the long winding small intestine"]},
		"already in order": {"answer": [0, 1, 2]},
		"a spot used twice": {"answer": [1, 1, 2]},
	}
	for why: String in cases:
		var ex := LABEL.duplicate(true)
		for k: String in cases[why]:
			if cases[why][k] == null:
				ex.erase(k)
			else:
				ex[k] = cases[why][k]
		assert_ne(ExerciseCheck.problem(ex), "", why)


## A small drawing's parts are too close for pins on them: a spot may be [x, y, tx, ty], the pin at (x, y) beside the
## drawing with a line to the part at (tx, ty), as textbooks label diagrams.
func test_a_label_spot_may_point_at_its_part() -> void:
	var ex := LABEL.duplicate(true)
	ex.spots = [[0.23, 0.16, 0.5, 0.2], [0.77, 0.44, 0.53, 0.5], [0.23, 0.7, 0.44, 0.69]]
	assert_eq(ExerciseCheck.problem(ex), "")
	ex.spots = [[0.23, 0.16, 0.5], [0.77, 0.44, 0.53, 0.5], [0.23, 0.7, 0.44, 0.69]]
	assert_ne(ExerciseCheck.problem(ex), "", "a part needs both x and y")
	ex.spots = [[0.23, 0.16, 1.5, 0.2], [0.77, 0.44, 0.53, 0.5], [0.23, 0.7, 0.44, 0.69]]
	assert_ne(ExerciseCheck.problem(ex), "", "the part is on the picture")
