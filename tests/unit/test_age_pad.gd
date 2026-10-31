extends GutTest
## Owner #57 ("there should be just window to type age"): the game's own number pad for "How old are you?" (no phone
## keyboard, the same on every phone and browser). Up to two digits, no leading zero, a delete key.


func test_digits_build_the_age() -> void:
	assert_eq(AgePad.press("", "1"), "1")
	assert_eq(AgePad.press("1", "2"), "12")
	assert_eq(AgePad.press("12", "3"), "12", "two digits at most")


func test_no_leading_zero_and_delete() -> void:
	assert_eq(AgePad.press("", "0"), "", "an age does not start with 0")
	assert_eq(AgePad.press("1", "0"), "10")
	assert_eq(AgePad.press("12", AgePad.DELETE), "1")
	assert_eq(AgePad.press("", AgePad.DELETE), "")


func test_ok_needs_an_age() -> void:
	assert_false(AgePad.is_complete(""))
	assert_true(AgePad.is_complete("7"))
	assert_true(AgePad.is_complete("12"))
	assert_eq(AgePad.value("12"), 12)
	assert_eq(AgePad.value(""), 0)
