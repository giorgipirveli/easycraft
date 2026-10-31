extends GutTest
## Owner #105 (2026-10-15 23:14): "when starting playing create a password". The game's side of the password rules (the
## server checks them again: server/modules/src/rules/password_rules.ts) and the words a child sees.


func test_a_password_is_at_least_6_not_the_name_not_a_common_one() -> void:
	assert_eq(PasswordRules.problem("sunny-river-7", "Anna_7"), "")
	assert_eq(PasswordRules.problem("abc12", "Anna_7"), "too_short")
	assert_eq(PasswordRules.problem("ANNA_7", "Anna_7"), "is_name")
	for common: String in ["123456", "password", "Password1", "qwerty", "111111", "abc123", "easycraft"]:
		assert_eq(PasswordRules.problem(common, "Anna_7"), "too_common", common)
	assert_eq(PasswordRules.problem("zzzzzzzz", "Anna_7"), "too_common", "one character again and again")
	assert_eq(PasswordRules.problem("x".repeat(PasswordRules.MAX_LEN + 1), "Anna_7"), "too_long")
	assert_eq(PasswordRules.problem("bad\ttext", "Anna_7"), "bad_chars")
	for run: String in ["fedcba", "poiuyt", "lkjhgf", "098765", "moon234567", "tigerqwerty", "7mnbvcxz"]:
		assert_eq(PasswordRules.problem(run, "Anna_7"), "straight_run", run)
	for near: String in ["anna12", "12anna", "Anna2024", "anna_7!", "7ANNA77"]:
		assert_eq(PasswordRules.problem(near, "Anna_7"), "is_name", near)
	assert_eq(PasswordRules.problem("willow3comet", "Anna_7"), "", "two words and a number")
	assert_eq(PasswordRules.problem("annamoon7", "Anna_7"), "")
	assert_eq(PasswordRules.problem("moon7tiger", "Anna_7"), "too_common", "the example the game shows is never usable")
	assert_eq(PasswordRules.problem("a9é" + "ä".repeat(60), "Anna_7"), "too_long", "over 72 bytes, under 64 characters (bcrypt)")
	assert_true(PasswordRules.message("too_common").contains("two words and a number"), "one clear reason and an idea")


func test_the_same_common_list_as_the_server() -> void:
	var ts := FileAccess.get_file_as_string("res://server/modules/src/rules/password_rules.ts")
	for word: String in PasswordRules.COMMON:
		assert_true(ts.contains("\"%s\"" % word), word)
	assert_true(ts.contains("MIN_LEN = %d" % PasswordRules.MIN_LEN))
	assert_true(ts.contains("MAX_LEN = %d" % PasswordRules.MAX_LEN))
	assert_true(ts.contains("RUN_LEN = %d" % PasswordRules.RUN_LEN))
	for run: String in PasswordRules.RUNS:
		assert_true(ts.contains("\"%s\"" % run), run)


func test_the_words() -> void:
	assert_eq(PasswordRules.NEVER_TELL, "Never tell anyone your password. Not even a friend.")
	assert_eq(PasswordRules.WRONG, "That name and password don't match.")
	assert_eq(PasswordRules.LOGGED_OUT, "This device was logged out. LOG IN to play here.")
	assert_eq(PasswordRules.error_text("wrong_password"), PasswordRules.WRONG)
	assert_eq(PasswordRules.error_text("wrong_password", 0, true), PasswordRules.WRONG_OWN, "one's own: no name was typed")
	assert_eq(PasswordRules.error_text("locked", 900), "Too many tries: wait 15 minutes.")
	assert_eq(PasswordRules.error_text("locked", 30), "Too many tries: wait 1 minute.")
	assert_eq(PasswordRules.error_text("slow_down", 120),
		"Too many tries for this name. Try again in 2 minutes, or ask a grown-up for a key.", "the lead's words for the brake")
	assert_eq(PasswordRules.TRIED,
		"Someone tried to log in as you on a new device. If it wasn't you, a grown-up can change your password.")
	assert_eq(PasswordRules.error_text("is_name"), PasswordRules.message("is_name"))
	assert_eq(PasswordRules.error_text("network"), OnlineRules.message("network"))
	for code: String in ["too_short", "too_long", "bad_chars", "is_name", "too_common", "mismatch"]:
		assert_ne(PasswordRules.message(code), "", code)


func test_every_line_is_short_and_ends_like_a_sentence() -> void:
	for words: String in PasswordRules.lines():
		assert_lte(words.length(), 140, words)
		assert_true(words.ends_with(".") or words.ends_with("!") or words.ends_with("?"), words)
