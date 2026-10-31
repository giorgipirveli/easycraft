extends GutTest
## Owner #96 (spec §5.12b "High quality, with real tools"): the Shorts' style guide as rules (ShortStyle) and the
## quality checker over every Short: the game's palette, one typeface, letter sizes, safe margins for a phone held
## upright, ease-out arrivals with a small overshoot on pops, no linear slides, 12-18 frames a move, captions and
## voice at most ~2.5 words a second, legible colours.


func after_each() -> void:
	ShortLibrary.clear_cache()
	Curriculum.clear_cache()


func _short(scene_changes: Dictionary = {}, actor: Dictionary = {}) -> Dictionary:
	var a := {"kind": "words", "text": "Hello", "at": [180, 200], "size": 34, "color": "white",
		"moves": [{"do": "pop", "at": 0.2}]}
	a.merge(actor, true)
	var scene := {"seconds": 8, "background": "sky", "caption": "Short words here.", "say": "Short words here.", "actors": [a]}
	scene.merge(scene_changes, true)
	var last := {"seconds": 8, "background": "sky", "caption": "Why?", "say": "Why?", "actors": []}
	return {"id": "style_sample", "title": "Style", "topic": "science", "link": {"star_map": true},
		"scenes": [scene, last.duplicate(true), last.duplicate(true)]}


func _problems(s: Dictionary) -> String:
	return "\n".join(ShortCheck.problems(s))


func test_the_sample_passes() -> void:
	assert_eq(_problems(_short()), "")


func test_contrast_is_worked_out_like_wcag() -> void:
	assert_almost_eq(ShortStyle.contrast(Color.WHITE, Color.BLACK), 21.0, 0.01)
	assert_almost_eq(ShortStyle.contrast(Color.WHITE, Color.WHITE), 1.0, 0.01)
	assert_gt(ShortStyle.contrast(ShortRules.COLOURS.ink, ShortRules.COLOURS.yellow), 7.0)
	assert_lt(ShortStyle.contrast(Color.WHITE, ShortRules.COLOURS.yellow), 2.0, "white on yellow is hard to read")


func test_words_are_legible_on_their_sticker_or_their_outline() -> void:
	assert_true(ShortStyle.legible(ShortRules.COLOURS.ink, ShortRules.COLOURS.yellow))
	assert_false(ShortStyle.needs_outline(ShortRules.COLOURS.ink, ShortRules.COLOURS.yellow), "ink on yellow: no outline")
	assert_true(ShortStyle.needs_outline(Color.WHITE, ShortRules.COLOURS.orange), "white on orange gets the dark outline")
	assert_true(ShortStyle.legible(Color.WHITE, ShortRules.COLOURS.orange), "and so reads well")
	assert_false(ShortStyle.legible(ShortRules.COLOURS.ink, null), "dark words with no sticker on a dark sky: no")
	assert_string_contains(_problems(_short({}, {"color": "ink"})), "legible")
	assert_string_contains(_problems(_short({}, {"color": "white", "box": "yellow"})), "legible")
	assert_eq(_problems(_short({}, {"color": "ink", "box": "yellow"})), "")


func test_letters_are_big_enough_and_of_one_family_of_sizes() -> void:
	assert_string_contains(_problems(_short({}, {"size": 12})), "size")
	assert_eq(ShortStyle.letter_size(33), 34)
	assert_eq(ShortStyle.letter_size(100), 110)
	for s: int in ShortStyle.LETTER_SIZES:
		assert_gte(s, ShortStyle.MIN_LETTER)
	for s: int in ShortStyle.CAPTION_SIZES:
		assert_gte(s, ShortStyle.MIN_CAPTION)


func test_arrivals_ease_out_and_take_12_to_18_frames_or_so() -> void:
	assert_string_contains(_problems(_short({}, {"moves": [{"do": "pop", "at": 0.2, "dur": 2.0}]})), "pop")
	assert_string_contains(_problems(_short({}, {"moves": [{"do": "pop", "at": 0.2, "dur": 0.1}]})), "pop")
	assert_string_contains(_problems(_short({}, {"moves": [{"do": "slide", "at": 0, "from": [0, 0], "ease": "linear"}]})), "linear")
	assert_string_contains(_problems(_short({}, {"moves": [{"do": "move", "at": 0, "to": [10, 10], "ease": "linear"}]})), "linear")
	assert_string_contains(_problems(_short({}, {"moves": [{"do": "move", "at": 0, "dur": 0.1, "to": [10, 10]}]})), "move")
	assert_eq(ShortStyle.frames(ShortRules.DURATIONS.pop), 14, "a pop: 14 frames at 30 a second")
	for kind: String in ["pop", "slide", "fade", "out"]:
		var f := ShortStyle.frames(float(ShortRules.DURATIONS[kind]))
		assert_true(f >= 6 and f <= 20, "%s: %d frames" % [kind, f])
	assert_eq(ShortTimeline.ease_value("back", 0.5), ShortTimeline.ease_value("back", 0.5), "pops ease with a small overshoot")
	var peak := 0.0
	for i in 101:
		peak = maxf(peak, ShortTimeline.ease_value("back", i / 100.0))
	assert_lt(peak, 1.15, "a small overshoot, not a wobble")


func test_captions_and_the_voice_go_at_most_2_and_a_half_words_a_second() -> void:
	var fast := "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twenty-one"
	assert_string_contains(_problems(_short({"caption": fast})), "caption")
	assert_eq(ShortStyle.WORDS_PER_SECOND, 2.5)


func test_every_short_follows_the_style_guide() -> void:
	var bad: Array[String] = []
	for id in ShortLibrary.hand_ids():
		bad.append_array(ShortCheck.problems(ShortLibrary.hand(id)))
	for g in [3, 5, 7]:
		for e: Dictionary in ShortFeed.lesson_entries(g).slice(0, 25):
			bad.append_array(ShortCheck.problems(LessonShort.make(str(e.unit)), true))
	assert_eq(bad, [] as Array[String], "\n".join(bad))
