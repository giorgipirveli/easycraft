extends GutTest


func test_valid() -> void:
	assert_eq(UsernameRules.validate("Hopper_7"), "")


func test_too_short() -> void:
	assert_eq(UsernameRules.validate("ab"), "too_short")


func test_too_long() -> void:
	assert_eq(UsernameRules.validate("abcdefghijklmnopq"), "too_long")


func test_must_start_with_letter() -> void:
	assert_eq(UsernameRules.validate("7hopper"), "must_start_with_letter")


func test_spaces_only_rejected() -> void:
	assert_eq(UsernameRules.validate("   "), "too_short")


func test_inner_space_rejected() -> void:
	assert_eq(UsernameRules.validate("hop per"), "bad_chars")


func test_emoji_rejected() -> void:
	assert_eq(UsernameRules.validate("hop😀er"), "bad_chars")


func test_cyrillic_lookalike_rejected() -> void:
	assert_eq(UsernameRules.validate("hоpper"), "bad_chars")


func test_phone_number_rejected() -> void:
	assert_eq(UsernameRules.validate("call5551234567"), "personal_info")


func test_bad_word_rejected_case_insensitive() -> void:
	assert_eq(UsernameRules.validate("xxStupidxx"), "blocked_word")


func test_every_code_has_message() -> void:
	for code in ["too_short", "too_long", "must_start_with_letter", "bad_chars", "personal_info", "blocked_word"]:
		assert_ne(UsernameRules.message(code), "", code)


func test_phone_number_split_by_underscores_rejected() -> void:
	assert_eq(UsernameRules.validate("a555_123_4567"), "personal_info")
	assert_eq(UsernameRules.validate("Mom555_12_34_567"), "personal_info")


func test_a_few_digits_are_fine() -> void:
	assert_eq(UsernameRules.validate("Hopper2025_12"), "")


## Deferred M1 minor (the Scunthorpe problem): a blocked word hidden inside an innocent word is fine.
func test_innocent_names_that_contain_a_blocked_word_pass() -> void:
	for name in ["Peacock", "Whatever", "Skillful", "Scrappy", "Dickens", "Tweedle", "Skyscraper",
			"Closer_7", "Cockatoo", "Dumbledore", "Hitchcock", "Sk1llz", "Chateau"]:
		assert_eq(UsernameRules.validate(name), "", name)


## ... while real bad names stay blocked, also next to an innocent word, run together or in l33t.
func test_real_bad_names_are_still_blocked() -> void:
	for name in ["xxStupidxx", "iamstupid", "BigDick", "bigdick", "Killer99", "k1ll3r", "UrDumb",
			"Peacock_dick", "SkillKill", "Scrap_crap", "sh1thead", "Hitler_1", "Whatever_idiot"]:
		assert_eq(UsernameRules.validate(name), "blocked_word", name)
