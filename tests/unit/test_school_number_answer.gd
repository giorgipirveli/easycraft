extends GutTest
## Owner #68 (spec §22.5): a number typed on the School's pad is compared with the answer by its exact value: whole
## numbers, decimals, fractions and negatives, never through floats. Anything that is not a number is simply not right.


func test_whole_numbers_with_or_without_commas() -> void:
	assert_eq(NumberAnswer.parse("70000"), [70000, 1])
	assert_eq(NumberAnswer.parse("70,000"), [70000, 1], "the answers in the data are written with commas")
	assert_eq(NumberAnswer.parse("08"), [8, 1], "a leading zero is still eight")
	assert_eq(NumberAnswer.parse("0"), [0, 1])


func test_decimals_are_exact() -> void:
	assert_eq(NumberAnswer.parse("0.62"), [31, 50])
	assert_eq(NumberAnswer.parse("0.50"), [1, 2])
	assert_eq(NumberAnswer.parse(".5"), [1, 2])
	assert_eq(NumberAnswer.parse("3.0"), [3, 1])
	assert_eq(NumberAnswer.parse("12.25"), [49, 4])


func test_fractions_are_reduced() -> void:
	assert_eq(NumberAnswer.parse("5/8"), [5, 8])
	assert_eq(NumberAnswer.parse("10/16"), [5, 8])
	assert_eq(NumberAnswer.parse("12/4"), [3, 1])
	assert_eq(NumberAnswer.parse("0/7"), [0, 1])


func test_negatives() -> void:
	assert_eq(NumberAnswer.parse("-3"), [-3, 1])
	assert_eq(NumberAnswer.parse("-0"), [0, 1], "minus zero is zero")
	assert_eq(NumberAnswer.parse("-1/2"), [-1, 2])
	assert_eq(NumberAnswer.parse("-0.25"), [-1, 4])


func test_what_is_not_a_number() -> void:
	for text: String in ["", ".", "/", "-", "3/0", "1/2/3", "1.2.3", "abc", "--1", "1-", "1/-2", "1.5/2", "/4", "4/",
			"12345678901234567890", "1 2", "+3"]:
		assert_eq(NumberAnswer.parse(text), [], "'%s' is not a number" % text)
		assert_false(NumberAnswer.is_number(text), text)


func test_equal_compares_values() -> void:
	assert_true(NumberAnswer.equal("5/8", "10/16"))
	assert_true(NumberAnswer.equal("0.5", "1/2"))
	assert_true(NumberAnswer.equal("3", "3.0"))
	assert_true(NumberAnswer.equal("70,000", "70000"))
	assert_false(NumberAnswer.equal("3", "4"))
	assert_false(NumberAnswer.equal("0.5", "0.05"))
	assert_false(NumberAnswer.equal("", ""), "nothing typed is never right")
	assert_false(NumberAnswer.equal("3/0", "3/0"))


func test_value_is_a_float_for_sorting() -> void:
	assert_almost_eq(NumberAnswer.value("3/4"), 0.75, 0.000001)
	assert_almost_eq(NumberAnswer.value("-2.5"), -2.5, 0.000001)
	assert_true(is_nan(NumberAnswer.value("x")))
