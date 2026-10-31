extends GutTest
## Owner #68 (grade 4 science and English): the generators of the first science unit (rock layers and fossils,
## 4-ESS1-1) and of "Words that sound alike" (L.4.1g), checked against what they show.

const SEEDS := 60


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), gen)
			check.call(ex, level)


func test_the_deeper_fossil_is_older() -> void:
	_each("g4s.older_fossil", func(ex: Dictionary, _l: int) -> void:
		var fossils: Dictionary = ex.picture.fossils
		var lowest := ""
		var depth := 99
		for layer: String in fossils:
			if int(layer) < depth:
				depth = int(layer)
				lowest = str(fossils[layer])
		assert_eq(ExerciseCheck.answer_text(ex), "the " + lowest))


func test_layers_add_up_their_years() -> void:
	_each("g4s.layer_years", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(str(ex.answer)), (ex.picture.blocks as Array).size() * int(ex.data.years)))


func test_top_and_bottom_layers() -> void:
	_each("g4s.layer_age", func(ex: Dictionary, _l: int) -> void:
		var youngest := str(ex.prompt).contains("youngest")
		assert_eq(ExerciseCheck.answer_text(ex), "the top layer" if youngest else "the bottom layer"))


func test_the_right_word_fills_the_blank() -> void:
	_each("g4e.homophone_blank", func(ex: Dictionary, _l: int) -> void:
		var right := ExerciseCheck.answer_text(ex)
		assert_eq(right.to_lower(), str(ex.data.word).to_lower())
		assert_true(str(ex.prompt).contains("___"))
		for c: Variant in ex.choices:
			assert_true(GenWords.sets_of(right.to_lower()).has(str(c).to_lower()), "%s is in %s's set" % [c, right]))


func test_a_sentence_is_right_only_with_its_own_word() -> void:
	_each("g4e.homophone_check", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ex.answer, str(ex.data.used).to_lower() == str(ex.data.word).to_lower(), str(ex.prompt)))


func test_the_sentence_bank_is_sound() -> void:
	for row: Array in GenWords.SENTENCES:
		var sentence: String = row[0]
		var word: String = row[1]
		assert_eq(sentence.count("___"), 1, sentence)
		assert_true(GenWords.sets_of(word.to_lower()).size() >= 2, "%s has a set" % word)
		assert_eq(sentence.begins_with("___"), word[0] == word[0].to_upper(), "%s: a capital only at the start" % sentence)
