extends GutTest
## Owner #99 (spec §5.13 "As built (owner #99)"; module 0.2.20): the same name on a new device, with proof. The pure
## rules of the game's side: what kind of device this is (the old device's card names it), the 6-digit code as shown and
## as typed, the server's answers read carefully, and the words a child sees (short, plain, kind; no pressure).


func test_the_kind_of_device_for_the_card() -> void:
	var phone := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}
	assert_eq(DeviceMoveRules.device_kind(phone, Vector2i(1080, 2400), 420), "phone", "a 411 dp wide phone")
	assert_eq(DeviceMoveRules.device_kind(phone, Vector2i(1600, 2560), 320), "tablet", "800 dp: a tablet")
	assert_eq(DeviceMoveRules.device_kind(phone, Vector2i(1080, 2400), 0), "phone", "no dpi: a phone")
	assert_eq(DeviceMoveRules.device_kind({}, Vector2i(1920, 1080), 96), "computer")
	var web_phone := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true}
	assert_eq(DeviceMoveRules.device_kind(web_phone, Vector2i(1080, 2400), 420), "phone")
	var web_pc := {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}
	assert_eq(DeviceMoveRules.device_kind(web_pc, Vector2i(2560, 1440), 96), "computer")


func test_a_code_is_shown_in_two_threes_and_typed_any_way() -> void:
	assert_eq(DeviceMoveRules.pretty_code("123456"), "123 456")
	assert_eq(DeviceMoveRules.pretty_code("12345"), "12345")
	assert_eq(DeviceMoveRules.normalize_code(" 123 456 "), "123456")
	assert_eq(DeviceMoveRules.normalize_code("123-456"), "123456")
	for bad: String in ["12345", "1234567", "12a456", ""]:
		assert_eq(DeviceMoveRules.normalize_code(bad), "", bad)


func test_the_card_names_the_device_and_warns() -> void:
	assert_eq(DeviceMoveRules.ask_text("Anna", "computer"), "Someone wants to play as Anna on a computer.")
	assert_eq(DeviceMoveRules.ask_text("Anna", "tablet"), "Someone wants to play as Anna on a tablet.")
	assert_eq(DeviceMoveRules.ask_text("Anna", "toaster"), "Someone wants to play as Anna on another device.")
	assert_eq(DeviceMoveRules.moved_text("phone"), "Your game is on a phone now too.")
	assert_eq(DeviceMoveRules.moved_text(""), "Your game is on another device now too.")
	assert_true(DeviceMoveRules.ASK_NEVER.contains("Never type a code someone tells you"))


func test_the_taken_question_and_the_welcome() -> void:
	assert_eq(DeviceMoveRules.taken_text("Anna"),
		"Someone already has the name Anna. Is it you, from another phone, tablet or computer?")
	assert_eq(DeviceMoveRules.welcome_text("Anna"), "Welcome back, Anna! Your name, progress, looks and gold are here.")


func test_why_an_ask_ended_in_kind_words() -> void:
	for why: String in ["expired", "wrong_code", "declined", "cancelled", "replaced", "", "odd"]:
		var words := DeviceMoveRules.ended_text(why)
		assert_ne(words, "", why)
		assert_true(words.ends_with(".") or words.ends_with("!"), words)
	assert_ne(DeviceMoveRules.ended_text("declined"), DeviceMoveRules.ended_text("expired"))
	assert_eq(DeviceMoveRules.wrong_text(2), "That code is not right. 2 more tries.")
	assert_eq(DeviceMoveRules.wrong_text(1), "That code is not right. 1 more try.")


func test_the_servers_errors_in_plain_words() -> void:
	assert_eq(DeviceMoveRules.error_text("no_such_player"), OnlineRules.message("no_such_player"))
	assert_eq(DeviceMoveRules.error_text("self"), DeviceMoveRules.SELF)
	assert_eq(DeviceMoveRules.error_text("rate_limited", 600), "Too many tries. Wait 10 minutes and try again.")
	assert_eq(DeviceMoveRules.error_text("network"), OnlineRules.message("network"))


func test_a_notification_is_read_carefully() -> void:
	assert_eq(DeviceMoveRules.note("{\"what\": \"asked\", \"kind\": \"computer\"}"), {"what": "asked", "kind": "computer"})
	assert_eq(DeviceMoveRules.note("{\"what\": \"moved\", \"kind\": 7}"), {"what": "moved", "kind": "device"})
	assert_eq(DeviceMoveRules.note("{\"what\": \"steal\"}"), {"what": "", "kind": "device"})
	assert_eq(DeviceMoveRules.note("not json"), {"what": "", "kind": "device"})


func test_the_servers_list_of_asks_is_checked() -> void:
	var list := DeviceMoveRules.asks_from([{"id": "a-1", "kind": "phone", "left_s": 240},
		{"id": "", "kind": "phone", "left_s": 10}, {"id": "a-2", "kind": "x", "left_s": -3}, "junk",
		{"id": "a-3", "kind": "tablet", "left_s": 9999}], 1000)
	assert_eq(list.size(), 2)
	assert_eq(list[0], {"id": "a-1", "kind": "phone", "left_s": 240, "until_msec": 241_000})
	assert_eq(list[1].id, "a-3")
	assert_eq(int(list[1].left_s), DeviceMoveRules.CODE_SECONDS, "never longer than a code lives")
	assert_eq(DeviceMoveRules.asks_from(null, 0), [] as Array[Dictionary])


func test_every_new_line_is_short_and_ends_like_a_sentence() -> void:
	for words: String in DeviceMoveRules.lines():
		assert_lte(words.length(), 120, words)
		assert_true(words[0] == words[0].to_upper(), words)
		assert_true(words.ends_with(".") or words.ends_with("!") or words.ends_with("?") or words.ends_with("..."), words)
