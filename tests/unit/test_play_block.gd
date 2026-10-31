extends GutTest
## Owner #122 (docs/design/learning-is-play.md §4, §7): a unit's optional `play` block {hook, game, params, coach,
## world_task}, and what a unit plays without one: the hook from its main mechanic, the coach's lines from its cards (one
## idea each, at most 12 words, never the "Quick memory" question or the world card), the world task from its "Try it in
## the world" card.

const CARDS := [
	{"text": "Quick memory: what is 3 × 4?"},
	{"text": "A digit's place tells what it is worth. In 347 the 4 means four tens, which is 40, not 4."},
	{"text": "Horses, bison, deer and mammoths."},
	{"text": "It can be a street, a school or a village."},
	{"text": "Each place is worth ten times the place to its right, all the way along a number."},
	{"text": "We read big numbers in groups of three."},
	{"text": "Try it in the world: build a tower of 347 blocks in your world. Next: big numbers in a table."}]


func test_a_good_play_block_has_no_problems() -> void:
	var play := {"hook": "The bakery's pies must be shared fairly by four buddies.", "game": "generic",
		"params": {"maker": "fraction", "costume": "give"}, "coach": ["Equal parts make a fair share.",
		"The bottom number counts the parts."], "world_task": "Share a cake fairly at home with a grown-up."}
	assert_eq(PlayBlock.problems(play), [] as Array[String])
	assert_eq(PlayBlock.problems(null), [] as Array[String], "no block: the generic mechanics")


func test_a_play_block_s_problems_are_named() -> void:
	assert_ne(PlayBlock.problems("play"), [] as Array[String], "not an object")
	assert_ne(PlayBlock.problems({"hoook": "x"}), [] as Array[String], "an unknown field")
	assert_ne(PlayBlock.problems({"hook": "x".repeat(PlayBlock.MAX_HOOK + 1)}), [] as Array[String], "a long hook")
	assert_ne(PlayBlock.problems({"coach": ["one two three four five six seven eight nine ten eleven twelve thirteen"]}),
		[] as Array[String], "a coach line of 13 words")
	assert_ne(PlayBlock.problems({"coach": "Equal parts."}), [] as Array[String], "coach is a list")
	assert_ne(PlayBlock.problems({"world_task": "x".repeat(PlayBlock.MAX_TASK + 1)}), [] as Array[String])
	assert_ne(PlayBlock.problems({"params": {"maker": "abacus"}}), [] as Array[String], "an unknown maker")
	assert_ne(PlayBlock.problems({"params": {"costume": "dance"}}), [] as Array[String], "an unknown costume")
	assert_ne(PlayBlock.problems({"game": 3}), [] as Array[String])


func test_the_coach_s_lines_come_from_the_cards_one_short_idea_each() -> void:
	var lines := PlayBlock.derived_coach(CARDS)
	assert_eq(lines, ["A digit's place tells what it is worth.", "We read big numbers in groups of three."] as Array[String],
		"never the memory question, a list, a sentence that starts 'It', a long one or the world card")
	for l in lines:
		assert_lte(PlayBlock.words(l), PlayBlock.MAX_COACH_WORDS)


func test_the_play_block_s_coach_lines_come_first() -> void:
	var c := {"lesson": CARDS, "play": {"coach": ["Ten ones make a ten."]}}
	assert_eq(PlayBlock.coach(c), ["Ten ones make a ten."] as Array[String])
	assert_eq(PlayBlock.coach({"lesson": CARDS}).size(), 2)


func test_a_unit_with_no_short_idea_gets_its_goal() -> void:
	var c := {"lesson": [{"text": "Horses, bison, deer and mammoths."}]}
	assert_eq(PlayBlock.coach(c, {"goals": ["Read and write big numbers"]}),
		["Now you can read and write big numbers."] as Array[String])


func test_the_world_task_is_the_world_card_without_its_next() -> void:
	assert_eq(PlayBlock.world_task({"lesson": CARDS}), "Build a tower of 347 blocks in your world.")
	assert_eq(PlayBlock.world_task({"lesson": CARDS, "play": {"world_task": "Count the sheep on your farm."}}),
		"Count the sheep on your farm.")
	assert_eq(PlayBlock.world_task({"lesson": [{"text": "We read big numbers in groups of three."}]}, {"title": "Big numbers"}),
		"Teach it: show a grown-up or a friend what you found out about big numbers.")


func test_the_hook_is_the_unit_s_or_its_main_mechanic_s() -> void:
	var c := {"exercises": [{"type": "sort"}, {"type": "sort"}, {"type": "choice"}]}
	assert_eq(PlayBlock.hook(c), PlayMechanics.hook_of("sort"))
	c.play = {"hook": "The recycling truck is here!"}
	assert_eq(PlayBlock.hook(c), "The recycling truck is here!")


func test_curriculum_keeps_a_unit_s_play_block_and_checks_it() -> void:
	var id := "g4.maths.big_numbers"
	Curriculum.clear_cache()
	Curriculum.put_content(id, {"id": id, "lesson": CARDS, "exercises": [{"type": "truefalse", "prompt": "In 347, the 4 is 40.",
		"answer": true, "hint": "Tens."}], "play": {"hook": "The bank's vault needs a number.", "coach": ["A digit's place tells its worth."]}})
	assert_eq(str(Curriculum.content(id).play.hook), "The bank's vault needs a number.")
	assert_eq(Curriculum.content_problems(id), [] as Array[String])
	Curriculum.put_content(id, {"id": id, "lesson": CARDS, "exercises": [{"type": "truefalse", "prompt": "In 347, the 4 is 40.",
		"answer": true, "hint": "Tens."}], "play": {"coach": "not a list"}})
	assert_true(Curriculum.content_problems(id).any(func(p: String) -> bool: return p.contains("play")))
	Curriculum.clear_cache()


## The content agents' example (DEVELOPMENT.md "The play block"): one unit of every subject has a hand-written play block,
## and every block in the School's files is well formed, its maker and coach lines included.
func test_every_subject_has_an_example_block_and_every_block_is_well_formed() -> void:
	var subjects := {}
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				var c := Curriculum.content(str(u.id))
				if not c.has("play"):
					continue
				subjects[str(s.id)] = true
				assert_eq(PlayBlock.problems(c.play), [] as Array[String], str(u.id))
				assert_ne(PlayBlock.hook(c), "", str(u.id))
				assert_false(PlayBlock.coach(c, u).is_empty(), str(u.id))
	for s: String in Curriculum.SUBJECTS:
		assert_true(subjects.has(s), "%s has a unit written play-first" % s)
	Curriculum.clear_cache()
