extends GutTest
## Owner #70, grade 3 English (G3WordsGen, "g3e"): every generator's answer is worked out again here from the
## exercise's `data` with the test's own spelling and grammar rules (and its own list of irregular words), for many
## seeds and every level; every exercise must be valid (ExerciseCheck); the sentence banks are sound.

const SEEDS := 60
const IRREGULAR_PLURALS := {"mouse": "mice", "child": "children", "man": "men", "woman": "women", "foot": "feet",
	"tooth": "teeth", "goose": "geese", "ox": "oxen", "sheep": "sheep", "deer": "deer"}
const VES := ["leaf", "wolf", "knife", "loaf", "shelf"]
const IRREGULAR_PASTS := {"run": "ran", "swim": "swam", "take": "took", "go": "went", "see": "saw", "eat": "ate",
	"write": "wrote", "think": "thought", "catch": "caught", "find": "found", "sing": "sang", "fly": "flew",
	"bring": "brought", "sit": "sat", "make": "made", "tell": "told"}
const IRREGULAR_COMPARE := {"good": ["better", "best"], "bad": ["worse", "worst"]}
const LONG_ADJECTIVES := ["beautiful", "dangerous", "careful", "exciting"]
const PRONOUNS := ["I", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them", "his", "its", "our",
	"their"]


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			check.call(ex, level)


func _right(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


func _vowel(c: String) -> bool:
	return "aeiou".contains(c)


## One vowel, then a consonant, a vowel and a last consonant that is not w, x or y: "hop", "swim", "big".
func _short(w: String) -> bool:
	var vowels := 0
	for c in w:
		if _vowel(c):
			vowels += 1
	var n := w.length()
	return vowels == 1 and n >= 3 and not _vowel(w[n - 1]) and _vowel(w[n - 2]) and not _vowel(w[n - 3]) \
		and not "wxy".contains(w[n - 1])


func _consonant_y(w: String) -> bool:
	return w.ends_with("y") and not _vowel(w[w.length() - 2])


# --- Nouns and pronouns ---------------------------------------------------------------------------------------------

func test_plurals_follow_the_rules_or_the_irregular_list() -> void:
	_each("g3e.plural", func(ex: Dictionary, _l: int) -> void:
		var one := str(ex.data.one)
		var many: String
		if IRREGULAR_PLURALS.has(one):
			many = IRREGULAR_PLURALS[one]
		elif VES.has(one):
			many = one.trim_suffix("fe").trim_suffix("f") + "ves"
		elif one.ends_with("s") or one.ends_with("x") or one.ends_with("ch") or one.ends_with("sh"):
			many = one + "es"
		elif _consonant_y(one):
			many = one.left(-1) + "ies"
		else:
			many = one + "s"
		assert_eq(_right(ex), many, str(ex.prompt)))


func test_the_pronoun_bank_is_sound() -> void:
	for row: Array in G3WordsGen.PRONOUNS:
		var sentence: String = row[0]
		assert_eq(sentence.count("___"), 1, sentence)
		assert_true(PRONOUNS.has(str(row[1]).to_lower()), "%s is a pronoun" % row[1])
		assert_false((row[2] as Array).has(row[1]), "%s: the answer is not a wrong choice" % sentence)
		var starts := sentence.begins_with("___") or sentence.contains(". ___")
		assert_eq(starts, str(row[1])[0] == str(row[1])[0].to_upper(), "%s: a capital at a sentence's start" % sentence)
	_each("g3e.pronoun", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_right(ex), str(ex.data.pronoun))
		assert_eq(str(ex.explain), str(ex.data.sentence).replace("___", str(ex.data.pronoun))))


# --- Verbs ----------------------------------------------------------------------------------------------------------

func test_past_tenses_follow_the_rules_or_the_irregular_list() -> void:
	_each("g3e.past_tense", func(ex: Dictionary, _l: int) -> void:
		var base := str(ex.data.base)
		var past: String
		if IRREGULAR_PASTS.has(base):
			past = IRREGULAR_PASTS[base]
		elif base.ends_with("e"):
			past = base + "d"
		elif _consonant_y(base):
			past = base.left(-1) + "ied"
		elif _short(base):
			past = base + base.right(1) + "ed"
		else:
			past = base + "ed"
		assert_eq(_right(ex), past, str(ex.prompt)))


func test_the_verb_agrees_with_its_subject() -> void:
	_each("g3e.verb_agree", func(ex: Dictionary, _l: int) -> void:
		var who := str(ex.data.subject)
		var one := not (who in ["I", "You", "They", "We"] or who.contains(" and ") or who.ends_with("s")
			or who == "The children")
		assert_eq(bool(ex.data.one), one, who)
		var verb := str(ex.data.verb)
		var expect: String
		if verb == "be":
			expect = "am" if who == "I" else ("is" if one else "are")
		elif not one:
			expect = verb
		elif verb.ends_with("s") or verb.ends_with("x") or verb.ends_with("ch") or verb.ends_with("sh") \
				or verb.ends_with("o"):
			expect = verb + "es"
		elif _consonant_y(verb):
			expect = verb.left(-1) + "ies"
		else:
			expect = verb + "s"
		assert_eq(_right(ex), expect, str(ex.prompt)))


# --- Describing and joining -----------------------------------------------------------------------------------------

func test_comparing_words_follow_the_rules() -> void:
	_each("g3e.compare", func(ex: Dictionary, _l: int) -> void:
		var base := str(ex.data.base)
		var two := bool(ex.data.two)
		var expect: String
		if IRREGULAR_COMPARE.has(base):
			expect = IRREGULAR_COMPARE[base][0 if two else 1]
		elif LONG_ADJECTIVES.has(base):
			expect = ("more " if two else "most ") + base
		elif base.ends_with("e"):
			expect = base + ("r" if two else "st")
		elif _consonant_y(base):
			expect = base.left(-1) + ("ier" if two else "iest")
		elif _short(base):
			expect = base + base.right(1) + ("er" if two else "est")
		else:
			expect = base + ("er" if two else "est")
		assert_eq(_right(ex), expect, str(ex.prompt))
		assert_eq(str(ex.prompt).contains(" than "), two, "two things are compared with than"))


func test_the_joining_word_bank_is_sound() -> void:
	for row: Array in G3WordsGen.JOINS:
		var sentence: String = row[0]
		assert_eq(sentence.count("___"), 1, sentence)
		assert_false((row[2] as Array).has(row[1]), sentence)
		assert_eq(sentence.begins_with("___"), str(row[1])[0] == str(row[1])[0].to_upper(), sentence)
		for w: Variant in row[2]:
			assert_eq(str(w)[0] == str(w)[0].to_upper(), sentence.begins_with("___"), "%s: %s" % [sentence, w])
	_each("g3e.conjunction", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_right(ex), str(ex.data.word)))


# --- Punctuation ----------------------------------------------------------------------------------------------------

func test_apostrophes_show_who_owns_it() -> void:
	_each("g3e.possessive", func(ex: Dictionary, level: int) -> void:
		var who := str(ex.data.who)
		var owner := who + "'s"
		if not ex.data.one and who.ends_with("s"):
			owner = who + "'"
		assert_eq(_right(ex), "the %s %s" % [owner, ex.data.thing], str(ex.prompt))
		if level == 1:
			assert_true(ex.data.one, "level 1 has one owner"))


func test_speech_marks_go_round_the_spoken_words() -> void:
	_each("g3e.speech_marks", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var expect: String
		if d.first:
			expect = "\"%s%s\" %s %s." % [d.words, "," if str(d.mark) == "." else str(d.mark), d.verb, d.who]
		else:
			expect = "%s %s, \"%s%s\"" % [d.who, d.verb, d.words, d.mark]
		assert_eq(_right(ex), expect, str(ex.prompt))
		assert_eq(bool(d.first), level == 3)
		# Only the right one has the spoken words and their own mark (a comma when the speech comes first and would
		# end in a full stop) between two speech marks.
		var quoted := "\"%s%s\"" % [d.words, "," if d.first and str(d.mark) == "." else str(d.mark)]
		for c: Variant in ex.choices:
			assert_eq(str(c).contains(quoted), str(c) == expect, "%s: only the right one has %s" % [c, quoted]))


# --- Spelling -------------------------------------------------------------------------------------------------------

func test_suffixes_follow_the_spelling_rules() -> void:
	_each("g3e.add_suffix", func(ex: Dictionary, _l: int) -> void:
		var base := str(ex.data.base)
		var suffix := str(ex.data.suffix)
		var expect: String
		if _consonant_y(base) and suffix != "ing":
			expect = base.left(-1) + "i" + suffix
		elif _vowel(suffix[0]) and base.ends_with("e"):
			expect = base.left(-1) + suffix
		elif _vowel(suffix[0]) and _short(base):
			expect = base + base.right(1) + suffix
		else:
			expect = base + suffix
		assert_eq(_right(ex), expect, str(ex.prompt)))


func test_alphabetical_order() -> void:
	_each("g3e.alpha_order", func(ex: Dictionary, level: int) -> void:
		var sorted: Array = (ex.data.words as Array).duplicate()
		sorted.sort()
		var shown: Array = []
		for i: Variant in ex.answer:
			shown.append(ex.items[int(i)])
		assert_eq(shown, sorted, str(ex.items))
		if level == 3:
			var first := str(sorted[0]).left(2)
			for w: Variant in sorted:
				assert_eq(str(w).left(2), first, "level 3 words share their first two letters"))


# --- Word building --------------------------------------------------------------------------------------------------

func test_word_parts_give_the_meaning() -> void:
	var prefixes := {"un": ["not", "cannot", "unkind"], "re": ["again"], "dis": ["not"], "pre": ["before"]}
	var suffixes := {"ful": ["full of"], "less": ["without"], "ly": ["in a", "in an"], "able": ["can be", "cannot be"],
		"er": ["a person who"]}
	_each("g3e.word_part", func(ex: Dictionary, _l: int) -> void:
		var word := str(ex.data.word)
		var meaning := str(ex.data.meaning)
		assert_eq(_right(ex), meaning)
		var fits := false
		for p: String in prefixes:
			if word.begins_with(p):
				for m: String in prefixes[p]:
					fits = fits or meaning.contains(m)
		for s: String in suffixes:
			if word.ends_with(s):
				for m: String in suffixes[s]:
					fits = fits or meaning.contains(m)
		assert_true(fits, "%s: %s" % [word, meaning]))


func test_syllables_are_counted_by_their_beats() -> void:
	_each("g3e.syllables", func(ex: Dictionary, _l: int) -> void:
		var split := str(ex.data.split)
		assert_eq(int(str(ex.answer)), split.count("-") + 1, split)
		assert_true(str(ex.prompt).contains("\"%s\"" % split.replace("-", "")), str(ex.prompt))
		for part in split.split("-"):
			var has_vowel := false
			for c in part:
				has_vowel = has_vowel or "aeiouy".contains(c)
			assert_true(has_vowel, "every syllable of %s has a vowel sound" % split))


# --- Writing --------------------------------------------------------------------------------------------------------

func test_facts_and_opinions() -> void:
	var opinion_words: Array[String] = ["scary", "best", "tastiest", "worst", "nicer", "prettiest", "boring", "amazing",
		"fun", "loveliest"]
	var is_opinion := func(s: String) -> bool:
		for w in opinion_words:
			if RegEx.create_from_string("\\b" + w + "\\b").search(s.to_lower()):
				return true
		return false
	for row: Array in G3WordsGen.FACTS:
		assert_eq(is_opinion.call(str(row[0])), not row[1], "%s" % row[0])
	_each("g3e.fact_opinion", func(ex: Dictionary, _l: int) -> void:
		var sentences: Array = ex.data.sentences
		var facts: Array = ex.data.facts
		for i in sentences.size():
			assert_eq(is_opinion.call(str(sentences[i])), not facts[i], str(sentences[i]))
		if sentences.size() == 1:
			assert_eq(_right(ex), "a fact" if facts[0] else "an opinion")
		else:
			assert_eq(_right(ex), str(sentences[0])))
