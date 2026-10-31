extends GutTest
## Owner #94 (spec §5.12b): a "Lesson in a minute" is made at run time from any written School unit's lesson (grades
## 3-7): a title, its cards in turn (each card's picture popping in, its words as the caption and the voice; long cards
## split, the minute shared out), 30-60 seconds, and LEARN IT opens that unit.


func after_each() -> void:
	Curriculum.clear_cache()


func _captions(s: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for scene: Dictionary in s.scenes:
		out.append(str(scene.caption))
	return out


func _pictures(s: Dictionary) -> Array:
	var out: Array = []
	for scene: Dictionary in s.scenes:
		for a: Dictionary in scene.actors:
			if a.kind == "picture" and not out.has(a.picture):
				out.append(a.picture)
	return out


func test_a_unit_becomes_a_short_with_its_title_cards_and_link() -> void:
	var id := "g4.science.rock_layers"
	var s := LessonShort.make(id)
	assert_eq(ShortCheck.problems(s, true), [] as Array[String])
	assert_eq(s.id, "lesson:" + id)
	assert_eq(s.title, Curriculum.unit(id).title)
	assert_eq(s.topic, "science")
	assert_eq(s.grade, 4)
	assert_eq(s.link, {"unit": id})
	var cards: Array = Curriculum.content(id).lesson
	assert_eq(s.scenes[0].caption, s.title, "it opens on the unit's title")
	# The lessons' quality round (2026-10-01) opened every unit with a Quick memory, which the minute leaves out whole
	# (LessonShort.teaching): the caption after the title is the first words that teach.
	var first_words := ""
	for c: Dictionary in cards:
		var kept := LessonShort.teaching(LessonShort.sentences(str(c.text)))
		if not kept.is_empty():
			first_words = kept[0]
			break
	var first := str(s.scenes[1].caption)
	assert_true(first_words.begins_with(first), "then the first card's words: %s" % first)
	assert_false(first.begins_with("Quick memory"), "never the quick memory")
	assert_string_contains(str(s.scenes[s.scenes.size() - 1].caption), "LEARN IT", "it ends where to learn more")
	for c: Dictionary in cards:
		if c.has("picture"):
			assert_true(_pictures(s).has(c.picture) or ShortTimeline.length(s) > 50.0,
				"a card's picture pops in (unless the minute ran out)")
	var length := ShortTimeline.length(s)
	assert_true(length >= 30.0 and length <= 60.0, "%.1f s" % length)


func test_a_long_sentence_is_split_where_it_breathes() -> void:
	var text := "This sentence is long on purpose, with commas that give it room to breathe, so that no caption is ever " \
		+ "taller than the band at the bottom of the screen, which holds five lines of letters at most."
	var parts := LessonShort.chunks(text)
	assert_gt(parts.size(), 1)
	for p in parts:
		assert_lte(p.length(), ShortRules.LESSON_MAX_CAPTION)
	assert_eq(" ".join(parts), text, "nothing is lost")


func test_sentences_split_after_their_full_stops_but_not_inside_numbers() -> void:
	assert_eq(LessonShort.sentences("It is 2.5 m tall. Then it grows! Why? It rains."),
		["It is 2.5 m tall.", "Then it grows!", "Why?", "It rains."] as Array[String])


func test_every_written_unit_of_grades_3_to_7_makes_a_good_short() -> void:
	var made := 0
	var bad: Array[String] = []
	var shortest := 999.0
	var longest := 0.0
	for g in [3, 4, 5, 6, 7]:
		for sub in Curriculum.subjects(g):
			for u in Curriculum.units(g, str(sub.id)):
				if not u.has("file"):
					continue
				var s := LessonShort.make(str(u.id))
				var why := ShortCheck.problems(s, true)
				if not why.is_empty():
					bad.append_array(why)
				made += 1
				shortest = minf(shortest, ShortTimeline.length(s))
				longest = maxf(longest, ShortTimeline.length(s))
	assert_gt(made, 600, "hundreds of Lessons in a minute from day one")
	assert_eq(bad.slice(0, 20), [] as Array[String], "%d problems" % bad.size())
	gut.p("lessons: %d, %.1f-%.1f s" % [made, shortest, longest])


## Owner #96's review: a card without a picture borrows one of its unit's exercise pictures that asks nothing, else its
## headline shows big.
func test_a_card_without_a_picture_borrows_one_or_shows_its_headline() -> void:
	assert_eq(LessonShort.headline("Producers are plants: they make their own food from sunlight."), "Producers are plants")
	assert_eq(LessonShort.headline("Most animals eat more than one thing, and more than one animal eats them."),
		"Most animals eat more than one thing")
	assert_eq(LessonShort.headline("A food web joins many food chains together."), "A food web joins many food chains together")
	assert_eq(LessonShort.headline("This is a very long sentence without any colon or comma in it that goes on and on."), "")
	assert_true(LessonShort.asks_nothing({"kind": "blocks", "thousands": 0, "hundreds": 3, "tens": 4, "ones": 5}))
	assert_false(LessonShort.asks_nothing({"kind": "food_web", "nodes": [["grass", 0, 1], ["?", 0, 0]], "links": [[0, 1]]}),
		"a question mark: it asks")
	assert_false(LessonShort.asks_nothing({"kind": "life_cycle", "stages": ["egg", "chick", "hen"], "hide": 1}), "a hidden part")
	var s := LessonShort.make("g5.science.food_webs")
	var heads: Array = []
	for scene: Dictionary in s.scenes:
		for a: Dictionary in scene.actors:
			if a.kind == "words" and a.get("width") == 290:
				heads.append(a.text)
	assert_gt(heads.size(), 3, "a lesson without pictures shows its cards' headlines")
	# Each headline comes from the lesson's own sentences (the lessons are rewritten over time: no fixed wording here).
	var text := ""
	for c: Dictionary in Curriculum.content("g5.science.food_webs").lesson:
		text += str(c.text) + " "
	for h: String in heads:
		assert_true(text.contains(h), "a headline from the lesson: %s" % h)


## Owner #96's review: a lesson's "Quick memory" (a question on an earlier unit and its answer in brackets) is left out of
## the minute, which teaches this unit; the rest of that card stays, and a headline never ends on a dangling word.
func test_the_minute_leaves_out_the_quick_memory_and_keeps_the_rest() -> void:
	assert_eq(LessonShort.teaching(["Quick memory: which metal came after bronze?", "(Iron.)",
		"Every invention builds on older ones."] as Array[String]), ["Every invention builds on older ones."] as Array[String])
	assert_eq(LessonShort.teaching(["Quick memory: what does a map's key tell you? (What each symbol means.)",
		"Today: the compass."] as Array[String]), ["Today: the compass."] as Array[String])
	assert_eq(LessonShort.teaching(["Rock forms in layers.", "(Mostly.)"] as Array[String]),
		["Rock forms in layers.", "(Mostly.)"] as Array[String], "only a Quick memory's answer goes")
	assert_eq(LessonShort.headline("Insulators do not: plastic, rubber, wood, glass, paper and cloth."), "",
		"not \"Insulators do not\"")
	assert_eq(LessonShort.headline("Worked example: 36 + 47."), "Worked example")
	var s := LessonShort.make("g4.science.circuits")
	assert_eq(ShortCheck.problems(s, true), [] as Array[String])
	for scene: Dictionary in s.scenes:
		assert_false(str(scene.caption).begins_with("Quick memory"), scene.caption)
		assert_false(str(scene.caption).begins_with("("), scene.caption)


## Owner #94 (lesson quality, round 2): most lessons' Quick memory has a line before its question ("Quick memory: in
## grade 5 you learned latitude. What is the latitude of the Equator? (0°.) Today: …") or an answer without brackets
## (maths and science: "Expand 3(x + 2). Multiply both terms: 3x + 6."): 372 of 645 minutes opened on an earlier unit's
## question. The whole memory is left out, up to its bracketed answer or to "Today" or "Now".
func test_the_minute_leaves_out_the_whole_quick_memory() -> void:
	assert_eq(LessonShort.teaching(["Quick memory: in grade 5 you learned latitude.", "What is the latitude of the Equator?",
		"(0°.)", "Today: the great voyages."] as Array[String]), ["Today: the great voyages."] as Array[String])
	assert_eq(LessonShort.teaching(["Quick memory: last unit, expressions.", "Expand 3(x + 2).",
		"Multiply both terms: 3x + 6."] as Array[String]), [] as Array[String], "an answer without brackets")
	assert_eq(LessonShort.teaching(["Quick memory: in grade 5 you met particles.", "What is all matter made of?",
		"Tiny particles, too small to see.", "Now: what are those particles made of?"] as Array[String]),
		["Now: what are those particles made of?"] as Array[String])
	assert_eq(LessonShort.teaching(["Quick memory: what is empathy?", "(Imagining how someone else feels.)",
		"Empathy helps a lot when friends fall out."] as Array[String]),
		["Empathy helps a lot when friends fall out."] as Array[String], "a line after the answer stays")
	var opened_on_memory: Array[String] = []
	for g in [3, 4, 5, 6, 7]:
		for sub in Curriculum.subjects(g):
			for u in Curriculum.units(g, str(sub.id)):
				if not u.has("file"):
					continue
				var first := str((Curriculum.content(str(u.id)).lesson[0] as Dictionary).text)
				if not first.begins_with("Quick memory"):
					continue
				var all := LessonShort.sentences(first)
				var kept := LessonShort.teaching(all)
				var question := all.find(all.filter(func(x: String) -> bool: return x.ends_with("?"))[0]) \
					if all.any(func(x: String) -> bool: return x.ends_with("?")) else -1
				if question >= 0 and kept.has(all[question]) and question < all.size() - 1 \
						and not all[question].begins_with("Today") and not all[question].begins_with("Now"):
					opened_on_memory.append(str(u.id))
	assert_eq(opened_on_memory.slice(0, 10), [] as Array[String], "%d minutes keep their memory's question" %
		opened_on_memory.size())


func test_an_unwritten_unit_makes_nothing() -> void:
	assert_true(LessonShort.make("g8.science.no_such_unit").is_empty())
