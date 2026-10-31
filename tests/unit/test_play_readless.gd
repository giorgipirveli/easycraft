extends GutTest
## Owner #133 ("consider no one will start reading in the game") and #134 (docs/design/future-lessons.md §2's mute
## test, §6): a challenge is played only when a child can do it without reading: an action (make a quantity, order,
## connect, sort, label, build, code, beat, mix, find) whose things are pictures, numbers or short names (spoken when
## touched), and whose question is short enough to be said. A written choice or a true-or-false claim is never dressed
## as a game: those stay in the School as they are, and are counted as its reading debt.

const SORT_NUMBERS := {"type": "sort", "prompt": "More than 100 or not?", "hint": "Hundreds.",
	"groups": ["more", "not more"], "items": ["347", "99", "120"], "answer": [0, 1, 0], "level": 1}
const SORT_SENTENCES := {"type": "sort", "prompt": "Sort the facts.", "hint": "Think.",
	"groups": ["true of plants", "true of animals"],
	"items": ["They make their own food from light", "They eat other living things"], "answer": [0, 1], "level": 1}
const NUMBER := {"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Put the parts together.",
	"level": 1}
const LONG_NUMBER := {"type": "number", "prompt": "A baker makes 12 rolls in the morning and 9 more after lunch, then sells 14 of them to the people of the village. How many are left?",
	"answer": "7", "hint": "Add, then take away.", "level": 2}
const CHOICE := {"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"],
	"answer": 0, "hint": "No hundreds.", "level": 1}
const CLAIM := {"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens.", "level": 1}
const ORDER := {"type": "order", "prompt": "Smallest to biggest.", "items": ["120", "99", "347"], "answer": [1, 0, 2],
	"hint": "Look at the hundreds.", "level": 2}


func test_words_are_what_has_letters_numbers_are_not_words() -> void:
	assert_eq(PlayReadless.words("3/4"), 0)
	assert_eq(PlayReadless.words("3,025 + 12 = ?"), 0)
	assert_eq(PlayReadless.words("5 cm"), 1)
	assert_eq(PlayReadless.words("not more"), 2)
	assert_eq(PlayReadless.words(""), 0)


func test_actions_with_numbers_or_short_names_play() -> void:
	assert_true(PlayReadless.plays(SORT_NUMBERS), "sorting numbers into bins with short names")
	assert_true(PlayReadless.plays(NUMBER), "making a quantity")
	assert_true(PlayReadless.plays(ORDER), "ordering numbers")


func test_written_choices_and_claims_are_never_played() -> void:
	assert_false(PlayReadless.plays(CHOICE))
	assert_eq(PlayReadless.why_not(CHOICE), PlayReadless.WRITTEN_CHOICE)
	assert_false(PlayReadless.plays(CLAIM))
	assert_eq(PlayReadless.why_not(CLAIM), PlayReadless.CLAIM)


func test_sentences_on_the_things_or_a_long_question_need_reading() -> void:
	assert_eq(PlayReadless.why_not(SORT_SENTENCES), PlayReadless.LONG_THING)
	assert_eq(PlayReadless.why_not(LONG_NUMBER), PlayReadless.LONG_PROMPT)
	assert_eq(PlayReadless.why_not(NUMBER), "")


func test_the_limits_are_the_mechanics_files() -> void:
	var r: Dictionary = PlayMechanics.data().get("readless", {})
	assert_eq(PlayReadless.thing_words(), int(r.get("thing_words", -1)))
	assert_eq(PlayReadless.prompt_words(), int(r.get("prompt_words", -1)))
	assert_eq(PlayReadless.min_round(), int(r.get("min_round", -1)))
	assert_eq(PlayReadless.thing_words(), 3)
	assert_eq(PlayReadless.prompt_words(), 16)
	assert_eq(PlayReadless.min_round(), 3)


func test_a_unit_s_playable_part_keeps_only_what_plays() -> void:
	var c := {"id": "g4.maths.x", "lesson": [{"text": "A card."}],
		"exercises": [SORT_NUMBERS, CHOICE, NUMBER, CLAIM, ORDER, SORT_SENTENCES]}
	var p := PlayReadless.content(c)
	assert_eq((p.exercises as Array).size(), 3)
	for ex: Dictionary in p.exercises:
		assert_true(PlayReadless.plays(ex))
	assert_eq((c.exercises as Array).size(), 6, "the unit itself is untouched")
	assert_true(PlayReadless.unit_plays(c))


func test_a_unit_with_too_little_to_play_stays_in_the_school() -> void:
	var c := {"id": "g4.history.x", "lesson": [{"text": "A card."}], "exercises": [CHOICE, CLAIM, NUMBER, SORT_SENTENCES]}
	assert_false(PlayReadless.unit_plays(c), "one playable challenge is not a game")


func test_a_generator_plays_when_its_exercises_play() -> void:
	var playing := ""
	var reading := ""
	for g in SchoolGen.ids():
		var ex := SchoolGen.make(g, 11, 2)
		if playing == "" and str(ex.get("type", "")) == "number" and PlayReadless.generator_plays(g):
			playing = g
		elif reading == "" and str(ex.get("type", "")) == "choice":
			reading = g
	assert_ne(playing, "", "a generator that makes numbers to make")
	assert_ne(reading, "", "a generator that makes written choices")
	assert_false(PlayReadless.generator_plays(reading))
	var c := {"id": "g4.maths.x", "lesson": [{"text": "A card."}], "exercises": [CHOICE],
		"generators": [{"gen": playing, "level": 1}, {"gen": reading, "level": 2}]}
	var p := PlayReadless.content(c)
	assert_eq((p.generators as Array).size(), 1)
	assert_eq(str((p.generators as Array)[0].gen), playing)
	assert_true(PlayReadless.unit_plays(c), "a generator never runs out")


func test_the_reading_debt_counts_what_needs_reading_and_why() -> void:
	var c := {"id": "g4.maths.x", "lesson": [{"text": "One card here."}, {"text": "And two."}],
		"exercises": [SORT_NUMBERS, CHOICE, NUMBER, CLAIM, CHOICE, SORT_SENTENCES]}
	var d := PlayReadless.debt(c)
	assert_eq(int(d.playable), 2)
	assert_eq(int(d.reading), 4)
	assert_eq(int(d.cards), 2)
	assert_eq(int(d.card_words), 5)
	assert_eq(int((d.why as Dictionary).get(PlayReadless.WRITTEN_CHOICE, 0)), 2)
	assert_eq(int((d.why as Dictionary).get(PlayReadless.CLAIM, 0)), 1)
	assert_eq(int((d.why as Dictionary).get(PlayReadless.LONG_THING, 0)), 1)
