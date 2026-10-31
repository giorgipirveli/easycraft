extends GutTest


func test_clean_trims_and_squeezes_spaces() -> void:
	assert_eq(ChatRules.clean("   hello    there  "), "hello there")


func test_clean_strips_control_characters() -> void:
	assert_eq(ChatRules.clean("hi\nthere\t!\u0007"), "hi there !")
	assert_eq(ChatRules.clean("a\u202eb\u200bc"), "abc")   # bidi override and zero-width space


func test_clean_caps_at_120_characters() -> void:
	var long := "a".repeat(300)
	assert_eq(ChatRules.clean(long).length(), ChatRules.MAX_LENGTH)
	assert_eq(ChatRules.MAX_LENGTH, 120)


func test_only_spaces_is_empty() -> void:
	assert_eq(ChatRules.check("   \n ", AgeBand.TEEN_PLUS).get("error"), "empty")


func test_under_13_free_text_is_refused() -> void:
	assert_eq(ChatRules.check("hello, want to build a castle?", AgeBand.UNDER_13).get("error"), "quick_chat_only")


func test_under_13_quick_phrases_pass() -> void:
	for phrase in ChatRules.QUICK_PHRASES:
		assert_eq(ChatRules.check(phrase, AgeBand.UNDER_13).get("text"), phrase, phrase)


func test_quick_phrases_are_short_and_clean() -> void:
	assert_true(ChatRules.QUICK_PHRASES.has("Hi!"))
	assert_true(ChatRules.QUICK_PHRASES.has("Follow me!"))
	assert_true(ChatRules.QUICK_PHRASES.has("Bye!"))
	for phrase in ChatRules.QUICK_PHRASES:
		assert_eq(ChatRules.clean(phrase), phrase)
		assert_eq(ChatRules.filter_code(phrase), "", phrase)


func test_unknown_band_is_treated_as_under_13() -> void:
	assert_eq(ChatRules.effective_band(&""), AgeBand.UNDER_13)
	assert_eq(ChatRules.effective_band(&"adult"), AgeBand.UNDER_13)
	assert_eq(ChatRules.effective_band(AgeBand.TEEN_PLUS), AgeBand.TEEN_PLUS)
	assert_eq(ChatRules.check("hello there", &"adult").get("error"), "quick_chat_only")


func test_teen_free_text_passes_cleaned() -> void:
	assert_eq(ChatRules.check("  Want to build a castle?  ", AgeBand.TEEN_PLUS).get("text"), "Want to build a castle?")


func test_phone_numbers_are_filtered_for_teens() -> void:
	for text in ["call me 555 123 4567", "my number is 555-1234567", "(555) 123-4567", "5 5 5 1 2 3 4"]:
		assert_eq(ChatRules.check(text, AgeBand.TEEN_PLUS).get("error"), "personal_info", text)


func test_a_few_numbers_are_fine() -> void:
	for text in ["I built 25 towers", "meet at 100 64", "level 3 in 2 minutes"]:
		assert_eq(ChatRules.check(text, AgeBand.TEEN_PLUS).get("error", ""), "", text)


func test_emails_links_and_contact_apps_are_filtered() -> void:
	for text in ["mail me at kid@example.com", "go to www.example.com", "see http://x.io", "add me on snapchat",
			"what is your address", "where do you live?"]:
		assert_eq(ChatRules.filter_code(text), "personal_info", text)


func test_bad_words_are_filtered_for_teens() -> void:
	for text in ["you are STUPID", "you're a l0ser", "s t u p i d", "such an idiot!", "stupidest build ever"]:
		assert_eq(ChatRules.check(text, AgeBand.TEEN_PLUS).get("error"), "blocked_word", text)


func test_innocent_words_that_contain_bad_ones_pass() -> void:
	# The username filter matches inside words; chat matches whole words (and their endings) instead.
	for text in ["whatever you say", "nice skill", "that is a scrappy tower", "this hit the wall", "grass and class"]:
		assert_eq(ChatRules.filter_code(text), "", text)


func test_username_filter_is_unchanged() -> void:
	assert_eq(UsernameRules.validate("xxStupidxx"), "blocked_word")
	assert_eq(UsernameRules.validate("Hopper_7"), "")


func test_every_code_has_a_message() -> void:
	for code in ["empty", "quick_chat_only", "personal_info", "blocked_word", "too_fast"]:
		assert_ne(ChatRules.message(code), "", code)


func test_under_13_players_only_receive_quick_phrases() -> void:
	assert_true(ChatRules.can_receive("Hi!", AgeBand.UNDER_13))
	assert_false(ChatRules.can_receive("want to build a castle?", AgeBand.UNDER_13))
	assert_false(ChatRules.can_receive("want to build a castle?", &""))
	assert_true(ChatRules.can_receive("want to build a castle?", AgeBand.TEEN_PLUS))


func test_rate_limit_five_per_ten_seconds_per_player() -> void:
	var limit := ChatRules.RateLimiter.new()
	for i in 5:
		assert_true(limit.allow(7, 100.0 + i), "message %d" % i)
	assert_false(limit.allow(7, 105.0), "6th within 10 s")
	assert_true(limit.allow(8, 105.0), "other players are not limited by player 7")
	assert_false(limit.allow(7, 109.9))
	assert_true(limit.allow(7, 110.0), "the first message left the window")
	assert_false(limit.allow(7, 110.5))


func test_rate_limit_forget_resets_a_player() -> void:
	var limit := ChatRules.RateLimiter.new()
	for i in 5:
		limit.allow(3, 1.0)
	assert_false(limit.allow(3, 1.0))
	limit.forget(3)
	assert_true(limit.allow(3, 1.0))


## Review M9: digits of other scripts are digits too (fullwidth, Arabic-Indic, Persian, Devanagari,
## Thai, maths bold, circled), also mixed with ASCII digits or split by other spaces and dashes.
func test_phone_numbers_in_any_digits_are_filtered() -> void:
	for text in ["try ５５５１２３４", "٥٥٥١٢٣٤", "ring ۵۵۵ ۱۲۳۴", "५५५-१२३४", "๕๕๕๑๒๓๔", "555 ١٢٣٤",
			"𝟓𝟓𝟓𝟏𝟐𝟑𝟒", "⑤⑤⑤①②③④", "555 123–4"]:
		assert_eq(ChatRules.check(text, AgeBand.TEEN_PLUS).get("error"), "personal_info", text)


func test_a_few_digits_in_any_script_are_fine() -> void:
	for text in ["I built ２５ towers", "level ٣ in ٢ minutes"]:
		assert_eq(ChatRules.check(text, AgeBand.TEEN_PLUS).get("error", ""), "", text)


func test_fullwidth_emails_and_links_are_filtered() -> void:
	for text in ["kid＠example．com", "ｗｗｗ．example．com"]:
		assert_eq(ChatRules.filter_code(text), "personal_info", text)


## Review M9: accented letters and look-alike letters of other alphabets read as the plain letter.
func test_accented_and_look_alike_swears_are_filtered() -> void:
	for text in ["fück this", "shít", "FÜCK", "you are stüpid", "ｆｕｃｋ", "fück", "ѕhit", "fuсk",
			"ΙDIOT", "a l٠ser"]:
		assert_eq(ChatRules.check(text, AgeBand.TEEN_PLUS).get("error"), "blocked_word", text)


func test_accented_words_pass_and_keep_their_accents() -> void:
	for text in ["naïve café", "über cool build", "piñata party", "ça va?", "Ελληνικά", "привет всем"]:
		assert_eq(ChatRules.filter_code(text), "", text)
	assert_eq(ChatRules.check("Café crème!", AgeBand.TEEN_PLUS).get("text"), "Café crème!", "the message keeps its accents")
