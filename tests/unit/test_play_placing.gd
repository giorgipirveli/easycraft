extends GutTest
## Owner #122 (docs/design/learning-is-play.md §5.1): Sort it (things into bins), Order it (planks into a bridge's
## slots), Connect it (a wire from each post to a socket) and Fix it (labels onto a picture's pins) are things put into
## places. A thing is in one place at most; a bin holds many, a slot, a socket or a pin one. The places make the
## response in ExerciseCheck's own form.

const SORT := {"type": "sort", "prompt": "Living or not?", "hint": "Does it grow?", "groups": ["living", "not living"],
	"items": ["a tree", "a rock", "a frog", "a cloud"], "answer": [0, 1, 0, 1]}
const ORDER := {"type": "order", "prompt": "Smallest first.", "hint": "Hundreds.", "items": ["4,210", "4,021", "4,201"],
	"answer": [1, 2, 0]}
const MATCH := {"type": "match", "prompt": "Animal and young.", "hint": "A baby cat?", "items": ["cat", "dog", "cow"],
	"matches": ["puppy", "calf", "kitten"], "answer": [2, 0, 1]}
const LABEL := {"type": "label", "prompt": "Label it.", "hint": "Top first.", "picture": {"kind": "blocks", "tens": 1},
	"spots": [[0.2, 0.2], [0.8, 0.8]], "labels": ["stomach", "mouth"], "answer": [1, 0]}


func test_a_sort_puts_many_things_in_a_bin() -> void:
	var p := PlayPlacing.for_exercise(SORT)
	assert_eq(p.places, 2)
	assert_true(p.many)
	p.put(0, 0)
	p.put(2, 0)
	p.put(1, 1)
	assert_false(p.complete())
	p.put(3, 1)
	assert_true(p.complete())
	assert_true(ExerciseCheck.is_right(SORT, p.response()))


func test_an_order_fills_slots_one_plank_each() -> void:
	var p := PlayPlacing.for_exercise(ORDER)
	assert_false(p.many)
	p.put(1, 0)
	p.put(2, 1)
	p.put(0, 2)
	assert_true(ExerciseCheck.is_right(ORDER, p.response()), "the planks in slot order")
	p.put(0, 1)
	assert_eq(p.at[2], -1, "the plank that was there goes home")
	assert_eq(p.occupant(1), 0)
	assert_false(p.complete())


func test_a_match_and_a_label_are_one_to_a_place() -> void:
	var m := PlayPlacing.for_exercise(MATCH)
	for i in 3:
		m.put(i, int(MATCH.answer[i]))
	assert_true(ExerciseCheck.is_right(MATCH, m.response()))
	var l := PlayPlacing.for_exercise(LABEL)
	l.put(0, 1)
	l.put(1, 0)
	assert_true(ExerciseCheck.is_right(LABEL, l.response()))


func test_a_wrong_placing_is_not_right() -> void:
	var p := PlayPlacing.for_exercise(SORT)
	for i in 4:
		p.put(i, 0)
	assert_true(p.complete())
	assert_false(ExerciseCheck.is_right(SORT, p.response()))


func test_the_ghost_takes_a_wrong_one_back_then_places_a_right_one() -> void:
	var p := PlayPlacing.for_exercise(ORDER)
	p.put(0, 0)
	assert_eq(p.ghost_step(ORDER), {"thing": 0, "place": -1}, "the wrong plank comes off first")
	p.take(0)
	assert_eq(p.ghost_step(ORDER), {"thing": 1, "place": 0}, "then the first right plank")
	for e: Dictionary in [SORT, ORDER, MATCH, LABEL]:
		var q := PlayPlacing.for_exercise(e)
		for i in q.things + 1:
			var g := q.ghost_step(e)
			if g.is_empty():
				break
			q.apply(g)
		assert_true(ExerciseCheck.is_right(e, q.response()), "%s: the ghost's steps lead to the answer" % e.type)


func test_the_answer_shown_is_right_and_clear_empties() -> void:
	for e: Dictionary in [SORT, ORDER, MATCH, LABEL]:
		var p := PlayPlacing.for_exercise(e)
		p.show_answer(e)
		assert_true(ExerciseCheck.is_right(e, p.response()), str(e.type))
		p.clear()
		assert_eq(p.placed_count(), 0)


## The School's files are JSON: their answers' numbers are floats (3.0). The places and the coach's steps read them.
func test_answers_read_from_json_with_float_numbers() -> void:
	for e: Dictionary in [SORT, ORDER, MATCH, LABEL]:
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(e))
		var p := PlayPlacing.for_exercise(parsed)
		for i in p.things + 1:
			var g := p.ghost_step(parsed)
			if g.is_empty():
				break
			p.apply(g)
		assert_true(ExerciseCheck.is_right(parsed, p.response()), "%s from JSON: %s" % [e.type, p.response()])
