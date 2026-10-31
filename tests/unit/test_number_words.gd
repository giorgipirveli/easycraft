extends GutTest
## Owner #68: numbers in English words for the School ("Which number is forty-two thousand six hundred and five?"),
## the British way the game speaks (§22.6 ruling 3: "and" before the last tens and ones).


func test_small_numbers() -> void:
	assert_eq(NumberWords.say(0), "zero")
	assert_eq(NumberWords.say(7), "seven")
	assert_eq(NumberWords.say(13), "thirteen")
	assert_eq(NumberWords.say(40), "forty")
	assert_eq(NumberWords.say(42), "forty-two")
	assert_eq(NumberWords.say(99), "ninety-nine")


func test_hundreds_take_and() -> void:
	assert_eq(NumberWords.say(100), "one hundred")
	assert_eq(NumberWords.say(305), "three hundred and five")
	assert_eq(NumberWords.say(999), "nine hundred and ninety-nine")


func test_thousands_and_millions() -> void:
	assert_eq(NumberWords.say(1000), "one thousand")
	assert_eq(NumberWords.say(2005), "two thousand and five")
	assert_eq(NumberWords.say(42605), "forty-two thousand six hundred and five")
	assert_eq(NumberWords.say(472305), "four hundred and seventy-two thousand three hundred and five")
	assert_eq(NumberWords.say(1000000), "one million")
	assert_eq(NumberWords.say(1000050), "one million and fifty")
	assert_eq(NumberWords.say(3200100), "three million two hundred thousand one hundred")


func test_every_number_says_something_different() -> void:
	var seen := {}
	for n in range(0, 2100):
		var w := NumberWords.say(n)
		assert_false(seen.has(w), "%d and %s both say '%s'" % [n, seen.get(w, -1), w])
		seen[w] = n
