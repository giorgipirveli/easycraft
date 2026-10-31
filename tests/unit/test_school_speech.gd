extends GutTest
## Owner #68 (spec §22.1): lessons and exercises are read aloud; maths is written for the eye ("3/4", "×", "= ?", "5 km")
## and said for the ear. SchoolWords: the teacher's kind lines (effort and strategy, never talent; spec §6).


func test_fractions_are_said_as_parts() -> void:
	assert_eq(SchoolSpeech.spoken("3/4"), "3 quarters")
	assert_eq(SchoolSpeech.spoken("1/4"), "1 quarter")
	assert_eq(SchoolSpeech.spoken("1/2"), "1 half")
	assert_eq(SchoolSpeech.spoken("5/8 of the wall"), "5 eighths of the wall")
	assert_eq(SchoolSpeech.spoken("37/100"), "37 hundredths")
	assert_eq(SchoolSpeech.spoken("2/3 = ?/12"), "2 thirds equals what over 12")
	assert_eq(SchoolSpeech.spoken("7/13"), "7 over 13")


func test_signs_are_said_in_words() -> void:
	assert_eq(SchoolSpeech.spoken("3 × 4 = ?"), "3 times 4 equals what?")
	assert_eq(SchoolSpeech.spoken("12 ÷ 3"), "12 divided by 3")
	assert_eq(SchoolSpeech.spoken("7 + 5 − 2"), "7 plus 5 minus 2")
	assert_eq(SchoolSpeech.spoken("45,302 > 45,230"), "45,302 is greater than 45,230")
	assert_eq(SchoolSpeech.spoken("a < b"), "a is less than b")
	assert_eq(SchoolSpeech.spoken("90°"), "90 degrees")


func test_units_after_numbers() -> void:
	assert_eq(SchoolSpeech.spoken("3 km = ? m"), "3 kilometres equals what metres")
	assert_eq(SchoolSpeech.spoken("250 mL and 2 L"), "250 millilitres and 2 litres")
	assert_eq(SchoolSpeech.spoken("5 kg, 40 g, 8 cm"), "5 kilograms, 40 grams, 8 centimetres")
	assert_eq(SchoolSpeech.spoken("1 m"), "1 metre")
	assert_eq(SchoolSpeech.spoken("I am 9"), "I am 9", "a word is not a unit")


func test_the_teacher_praises_effort_and_strategy() -> void:
	for i in 10:
		assert_ne(SchoolWords.right(i), "")
		assert_ne(SchoolWords.right_after_help(i), "")
		assert_ne(SchoolWords.not_yet(i), "")
	for word: String in ["genius", "smart", "clever", "wrong", "failed", "bad"]:
		for line in SchoolWords.RIGHT + SchoolWords.RIGHT_AFTER_HELP + SchoolWords.NOT_YET:
			assert_false(line.to_lower().contains(word), "'%s' in '%s'" % [word, line])


## Owner #68, the grade 4 agent (science, "Sending messages with patterns"): codes are said the way they are sent.
func test_signal_codes_are_said_as_short_and_long() -> void:
	assert_eq(SchoolSpeech.spoken("Which word does this code spell?  • • • / — — — / • —"),
		"Which word does this code spell? short short short, long long long, short long")
	assert_eq(SchoolSpeech.spoken("S is • • • and T is —."), "S is short short short and T is long.")
	assert_eq(SchoolSpeech.spoken("Juno smiled — and waved."), "Juno smiled — and waved.", "a dash in a sentence stays")


func test_pictures_sent_as_ones_and_zeros_are_said_digit_by_digit() -> void:
	assert_eq(SchoolSpeech.spoken("Which picture do these numbers make?  101 / 011 / 000"),
		"Which picture do these numbers make? 1 0 1, 0 1 1, 0 0 0")
	assert_eq(SchoolSpeech.spoken("There are 100 blocks and 1/10 of them are red."),
		"There are 100 blocks and 1 tenth of them are red.", "numbers and fractions stay")


func test_the_round_end_line() -> void:
	assert_eq(SchoolWords.round_score(5, 6), "5 of 6 right the first time!")
	assert_eq(SchoolWords.round_score(1, 6), "1 of 6 right the first time.")
	assert_ne(SchoolWords.round_end(6, 6, true), SchoolWords.round_end(3, 6, false))


## Grades 6-8 (2026-09-29): roots, π, halves, square units and letters with powers are said in words.
func test_the_later_grades_symbols_are_said_in_words() -> void:
	assert_eq(SchoolSpeech.spoken("√49 = 7"), "the square root of 49 equals 7")
	assert_eq(SchoolSpeech.spoken("Use 3.14 for π."), "Use 3.14 for pi.")
	assert_eq(SchoolSpeech.spoken("½ × 8 × 4"), "a half times 8 times 4")
	assert_eq(SchoolSpeech.spoken("30 cm²"), "30 square centimetres")
	assert_eq(SchoolSpeech.spoken("What is its area in cm²?"), "What is its area in square centimetres?")
	assert_eq(SchoolSpeech.spoken("its volume in m³"), "its volume in cubic metres")
	assert_eq(SchoolSpeech.spoken("Solve: x² = 81."), "Solve: x squared equals 81.")
	assert_eq(SchoolSpeech.spoken("V = π × r³"), "V equals pi times r cubed")
	assert_eq(SchoolSpeech.spoken("25% of 80"), "25 percent of 80")
	assert_eq(SchoolSpeech.spoken("10³"), "10 to the power of 3", "a number's power as before")
