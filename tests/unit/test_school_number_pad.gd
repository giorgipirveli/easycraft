extends GutTest
## Owner #68 (spec §22.1): the School's own number pad (like the age question's AgePad, owner #57: no phone keyboard).
## Digits and DELETE always; `.`, `/` and `-` only when the answer needs them, and only where they make sense.

const P := preload("res://core/school/number_pad.gd")


func test_the_extra_keys_come_from_the_answer() -> void:
	assert_eq(P.keys_for("70000"), [] as Array[String])
	assert_eq(P.keys_for("0.62"), ["."] as Array[String])
	assert_eq(P.keys_for("5/8"), ["/"] as Array[String])
	assert_eq(P.keys_for("-3"), ["-"] as Array[String])
	assert_eq(P.keys_for("-1/2"), ["/", "-"] as Array[String])
	assert_eq(P.keys_for("70,000"), [] as Array[String], "a comma is never typed")


func test_digits_and_delete() -> void:
	assert_eq(P.press("", "7", []), "7")
	assert_eq(P.press("7", "0", []), "70")
	assert_eq(P.press("70", P.DELETE, []), "7")
	assert_eq(P.press("", P.DELETE, []), "")
	assert_eq(P.press("123456789", "1", []), "123456789", "at most MAX_CHARS")
	assert_eq(P.press("1", "x", []), "1", "not a key")


func test_a_dot_only_when_allowed_once_and_never_in_a_fraction() -> void:
	assert_eq(P.press("3", ".", []), "3", "no dot key for this answer")
	assert_eq(P.press("3", ".", ["."]), "3.")
	assert_eq(P.press("3.", ".", ["."]), "3.", "one dot")
	assert_eq(P.press("", ".", ["."]), "0.", "a dot first reads 0.")
	assert_eq(P.press("3/", ".", [".", "/"]), "3/")


func test_a_slash_needs_a_digit_before_it_and_comes_once() -> void:
	assert_eq(P.press("", "/", ["/"]), "")
	assert_eq(P.press("5", "/", ["/"]), "5/")
	assert_eq(P.press("5/", "/", ["/"]), "5/")
	assert_eq(P.press("5/8", "/", ["/"]), "5/8")
	assert_eq(P.press("0.5", "/", ["/", "."]), "0.5")


func test_minus_only_first() -> void:
	assert_eq(P.press("", "-", ["-"]), "-")
	assert_eq(P.press("-", "-", ["-"]), "-")
	assert_eq(P.press("3", "-", ["-"]), "3")
	assert_eq(P.press("", "-", []), "")
	assert_eq(P.press("-", ".", [".", "-"]), "-0.")


func test_shown_groups_thousands() -> void:
	assert_eq(P.shown(""), "?")
	assert_eq(P.shown("7"), "7")
	assert_eq(P.shown("1234"), "1,234")
	assert_eq(P.shown("472305"), "472,305")
	assert_eq(P.shown("1000000"), "1,000,000")
	assert_eq(P.shown("-12500"), "-12,500")
	assert_eq(P.shown("12345.67"), "12,345.67")
	assert_eq(P.shown("5/8"), "5/8")
	assert_eq(P.shown("3."), "3.")


func test_a_year_is_shown_plain() -> void:
	assert_eq(P.shown("1850", false), "1850", "a year: no thousands comma")
	assert_eq(P.shown("", false), "?")
	assert_eq(P.shown("2026", true), "2,026", "grouped unless asked")
