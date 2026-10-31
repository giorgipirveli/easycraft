extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.6's fade, §3.8 "How the voice carries the symbols", ruling
## 10, §4.6): the rune line carved under the pans, at every stage of the fade, and its spoken reading. Pictures (the
## crystal's icon and gem dots in fives), numbers (numerals), letters (the crystal's rune becomes x: standard notation),
## runes only (the same line; the pans are in mist). The crystal is never "c" (ruling 10). Hoot reads the line at an
## altar's start and the answer at its free, in at most 12 words; every rune says its name when touched.

const MAX_WORDS := 12


func test_the_line_at_every_stage() -> void:
	var s := AltarState.make(1, 3, 0, 7, 4)
	assert_eq(AltarRunes.line(s, AltarRunes.PICTURES), "◇ + ●●● = ●●●●● ●●", "gem dots in fives")
	assert_eq(AltarRunes.line(s, AltarRunes.NUMBERS), "◇ + 3 = 7")
	assert_eq(AltarRunes.line(s, AltarRunes.LETTERS), "x + 3 = 7")
	assert_eq(AltarRunes.line(s, AltarRunes.RUNES), "x + 3 = 7", "runes only: the same line, the pans in mist")


func test_every_form_s_line_in_letters() -> void:
	assert_eq(AltarRunes.line(AltarState.make(0, 9, 1, 2, 7), AltarRunes.LETTERS), "9 = x + 2", "the crystal on the right")
	assert_eq(AltarRunes.line(AltarState.make(3, 0, 0, 12, 4), AltarRunes.LETTERS), "3x = 12")
	assert_eq(AltarRunes.line(AltarState.make(2, 1, 0, 7, 3), AltarRunes.LETTERS), "2x + 1 = 7")
	assert_eq(AltarRunes.line(AltarState.make(1, -3, 0, 5, 8), AltarRunes.LETTERS), "x − 3 = 5", "balloons are minus")
	assert_eq(AltarRunes.line(AltarState.make(1, 0, 0, 4, 4), AltarRunes.LETTERS), "x = 4", "freed: the answer")
	assert_eq(AltarRunes.line(AltarState.make(3, 0, 0, 12, 4), AltarRunes.NUMBERS), "3◇ = 12")
	assert_eq(AltarRunes.line(AltarState.make(2, 0, 0, 6, 3), AltarRunes.PICTURES), "◇◇ = ●●●●● ●")
	assert_eq(AltarRunes.line(AltarState.make(2, 2, 1, 4, 2), AltarRunes.LETTERS), "2x + 2 = x + 4",
		"crystals on both pans (wing 8)")
	assert_eq(AltarRunes.line(AltarState.make(1, 0, 0, 0, 0), AltarRunes.LETTERS), "x = 0")


func test_every_rune_says_its_name() -> void:
	var tokens := AltarRunes.tokens(AltarState.make(2, -3, 0, 5, 4), AltarRunes.LETTERS)
	assert_eq(tokens.map(func(t: Dictionary) -> String: return str(t.glyph)), ["2x", "−", "3", "=", "5"])
	assert_eq(tokens.map(func(t: Dictionary) -> String: return str(t.name)), ["two x", "minus", "three", "equals", "five"])
	var pictures := AltarRunes.tokens(AltarState.make(1, 3, 0, 7, 4), AltarRunes.PICTURES)
	assert_eq(pictures.map(func(t: Dictionary) -> String: return str(t.name)), ["crystal", "plus", "three", "equals", "seven"])
	assert_eq(pictures.map(func(t: Dictionary) -> String: return str(t.rune)),
		[AltarRunes.CRYSTAL, AltarRunes.PLUS, AltarRunes.GEMS, AltarRunes.EQUALS, AltarRunes.GEMS])
	assert_eq(int(pictures[2].n), 3)
	assert_eq(int(pictures[2].pan), AltarState.LEFT)
	assert_eq(int(pictures[4].pan), AltarState.RIGHT)


func test_the_spoken_reading_at_each_stage() -> void:
	var s := AltarState.make(1, 3, 0, 7, 4)
	assert_eq(AltarRunes.say(s, AltarRunes.PICTURES), "A crystal and three gems weigh seven gems.", "R1")
	assert_eq(AltarRunes.say(s, AltarRunes.NUMBERS), "A crystal plus three equals seven.", "R3")
	assert_eq(AltarRunes.say(s, AltarRunes.LETTERS), "x plus three equals seven.", "R3")
	assert_eq(AltarRunes.say(AltarState.make(2, 0, 0, 6, 3), AltarRunes.PICTURES), "Two crystals weigh six gems.")
	assert_eq(AltarRunes.say(AltarState.make(1, -3, 0, 5, 8), AltarRunes.PICTURES),
		"A crystal and three balloons weigh five gems.")
	assert_eq(AltarRunes.say(AltarState.make(0, 9, 1, 2, 7), AltarRunes.PICTURES), "Nine gems weigh a crystal and two gems.")
	assert_eq(AltarRunes.say(AltarState.make(2, 1, 0, 7, 3), AltarRunes.LETTERS), "Two x plus one equals seven.")
	assert_eq(AltarRunes.say(AltarState.make(1, 0, 0, 1, 1), AltarRunes.PICTURES), "A crystal weighs a gem.")


func test_the_answer_at_the_free() -> void:
	assert_eq(AltarRunes.answer_say(AltarState.make(1, 0, 0, 4, 4)), "One crystal weighs four gems.", "R2")
	assert_eq(AltarRunes.answer_say(AltarState.make(0, 1, 1, 0, 1)), "One crystal weighs one gem.")
	assert_eq(AltarRunes.answer_say(AltarState.make(1, 2, 0, 6, 4)), "", "not freed yet")


func test_numbers_are_said_as_words() -> void:
	assert_eq(AltarRunes.number_word(0), "zero")
	assert_eq(AltarRunes.number_word(7), "seven")
	assert_eq(AltarRunes.number_word(13), "thirteen")
	assert_eq(AltarRunes.number_word(20), "twenty")
	assert_eq(AltarRunes.number_word(21), "twenty-one")
	assert_eq(AltarRunes.number_word(99), "ninety-nine")


func test_every_reading_of_every_altar_is_at_most_twelve_words() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var tools: Array[String] = ["bowls", "gem_bag", "pump"]
	for form: String in AltarGen.forms():
		for i in 40:
			var s := AltarGen.make(form, rng)
			for step in 4:   # a few random twin moves on: the line changes with every move
				for stage in [AltarRunes.PICTURES, AltarRunes.NUMBERS, AltarRunes.LETTERS, AltarRunes.RUNES]:
					var said := AltarRunes.say(s, stage)
					assert_between(PlayReadless.words(said), 1, MAX_WORDS, "%s stage %d: %s" % [s, stage, said])
					for t: Dictionary in AltarRunes.tokens(s, stage):
						assert_ne(str(t.name), "", "%s: every rune has a name" % s)
				var ops := AltarMoves.legal_ops(s, tools, 3)
				s = AltarMoves.apply(s, ops[rng.randi_range(0, ops.size() - 1)])
			if s.freed():
				assert_between(PlayReadless.words(AltarRunes.answer_say(s)), 1, MAX_WORDS)
