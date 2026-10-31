extends GutTest
## OnlineRules (M4 Wave 1, Agent C; spec §17.1-17.3): the account from the server's answer, who may
## play with friends (consent first for under-13), which PLAY ONLINE screen shows, invites, and every
## error in plain, kind words.

const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."


# --- The account ---

func test_the_account_takes_the_servers_metadata() -> void:
	var a := OnlineRules.account({"ok": true, "username": "Pip", "age_band": "under_13", "consent": "verified",
		"online_allowed": true, "chat": "quick"}, AgeBand.TEEN_PLUS)
	assert_eq(a.username, "Pip")
	assert_eq(a.age_band, AgeBand.UNDER_13, "the server's band wins over the phone's")
	assert_eq(a.consent, OnlineRules.CONSENT_VERIFIED)
	assert_true(a.online_allowed)
	assert_eq(a.chat, OnlineRules.CHAT_QUICK)


func test_the_servers_claimed_flag_and_whether_consent_can_start() -> void:
	var a := OnlineRules.account({"ok": true, "claimed": true, "consent_available": false}, AgeBand.UNDER_13)
	assert_eq(a.claimed, true)
	assert_eq(a.consent_available, false)
	var old_server := OnlineRules.account({"ok": true}, AgeBand.UNDER_13)
	assert_eq(old_server.claimed, null, "unknown: the name decides")
	assert_eq(old_server.consent_available, true, "unknown: try, the server answers")


func test_metadata_may_come_nested() -> void:
	var a := OnlineRules.account({"ok": true, "username": "Bo", "metadata": {"age_band": "13_plus", "consent": "none",
		"online_allowed": false, "chat": "off"}}, AgeBand.UNDER_13)
	assert_eq(a.age_band, AgeBand.TEEN_PLUS)
	assert_false(a.online_allowed)
	assert_eq(a.chat, OnlineRules.CHAT_OFF)


func test_missing_or_bad_fields_fall_back_to_the_safe_side() -> void:
	var young := OnlineRules.account({"ok": true, "consent": "maybe", "online_allowed": "yes", "chat": 3}, AgeBand.UNDER_13)
	assert_eq(young.age_band, AgeBand.UNDER_13, "no band on the server: the phone's")
	assert_eq(young.consent, OnlineRules.CONSENT_NONE)
	assert_false(young.online_allowed, "under-13: off until a grown-up turns it on")
	assert_eq(young.chat, OnlineRules.CHAT_QUICK, "under-13 chat is quick phrases at most")
	var teen := OnlineRules.account({}, AgeBand.TEEN_PLUS)
	assert_true(teen.online_allowed, "13+: on unless a grown-up turned it off")
	assert_eq(teen.chat, OnlineRules.CHAT_FILTERED)
	var unknown := OnlineRules.account({}, &"")
	assert_eq(unknown.age_band, AgeBand.UNDER_13, "no band anywhere: the strictest rules")


func test_under_13_never_gets_free_text_chat_whatever_the_server_says() -> void:
	var a := OnlineRules.account({"age_band": "under_13", "chat": "filtered"}, AgeBand.UNDER_13)
	assert_eq(a.chat, OnlineRules.CHAT_QUICK)
	assert_eq(OnlineRules.chat_choices(AgeBand.UNDER_13), [OnlineRules.CHAT_OFF, OnlineRules.CHAT_QUICK])
	assert_eq(OnlineRules.chat_choices(AgeBand.TEEN_PLUS), [OnlineRules.CHAT_OFF, OnlineRules.CHAT_QUICK, OnlineRules.CHAT_FILTERED])


# --- Consent gating (§17.2) ---

func _acct(band: StringName, consent: String, allowed: bool) -> Dictionary:
	return OnlineRules.account({"age_band": String(band), "consent": consent, "online_allowed": allowed}, band)


func test_under_13_plays_with_friends_only_after_verified_consent_and_a_grown_ups_yes() -> void:
	assert_false(OnlineRules.social_allowed(_acct(AgeBand.UNDER_13, "none", true)))
	assert_false(OnlineRules.social_allowed(_acct(AgeBand.UNDER_13, "pending", true)))
	assert_false(OnlineRules.social_allowed(_acct(AgeBand.UNDER_13, "verified", false)))
	assert_true(OnlineRules.social_allowed(_acct(AgeBand.UNDER_13, "verified", true)))


func test_13_plus_plays_unless_a_grown_up_switched_it_off() -> void:
	assert_true(OnlineRules.social_allowed(_acct(AgeBand.TEEN_PLUS, "none", true)))
	assert_false(OnlineRules.social_allowed(_acct(AgeBand.TEEN_PLUS, "none", false)))


func test_no_account_yet_means_nothing_social() -> void:
	assert_false(OnlineRules.social_allowed({}))


func test_the_play_online_screens_in_order() -> void:
	assert_eq(OnlineRules.screen(_acct(AgeBand.UNDER_13, "none", false), false, true), OnlineRules.SCREEN_SAFE_CARD,
		"the stay-safe card before anything online")
	assert_eq(OnlineRules.screen(_acct(AgeBand.UNDER_13, "none", false), false, false), OnlineRules.SCREEN_CLAIM,
		"the server needs the claim first (it sets the band); a child's name stays unfindable until consent")
	assert_eq(OnlineRules.screen(_acct(AgeBand.UNDER_13, "none", false), true, false), OnlineRules.SCREEN_ASK_GROWNUP)
	assert_eq(OnlineRules.screen(_acct(AgeBand.UNDER_13, "pending", false), true, false), OnlineRules.SCREEN_WAIT_GROWNUP)
	assert_eq(OnlineRules.screen(_acct(AgeBand.UNDER_13, "verified", false), true, false), OnlineRules.SCREEN_PARENT_OFF)
	assert_eq(OnlineRules.screen(_acct(AgeBand.TEEN_PLUS, "none", false), true, false), OnlineRules.SCREEN_PARENT_OFF)
	assert_eq(OnlineRules.screen(_acct(AgeBand.UNDER_13, "verified", true), true, false), OnlineRules.SCREEN_HOME)
	assert_eq(OnlineRules.screen(_acct(AgeBand.TEEN_PLUS, "none", true), false, false), OnlineRules.SCREEN_CLAIM)
	assert_eq(OnlineRules.screen(_acct(AgeBand.TEEN_PLUS, "none", true), true, false), OnlineRules.SCREEN_HOME)
	assert_eq(OnlineRules.screen(_acct(AgeBand.TEEN_PLUS, "none", true), true, true), OnlineRules.SCREEN_SAFE_CARD,
		"the card again after a long break")


func test_the_stay_safe_card_shows_first_and_after_a_long_break() -> void:
	var day := 86400
	assert_true(OnlineRules.safe_card_due(0, 1_800_000_000), "never seen")
	assert_false(OnlineRules.safe_card_due(1_800_000_000, 1_800_000_000 + 3 * day))
	assert_true(OnlineRules.safe_card_due(1_800_000_000, 1_800_000_000 + (OnlineRules.SAFE_CARD_DAYS + 1) * day))
	assert_true(OnlineRules.safe_card_due(1_800_000_000 + day, 1_800_000_000), "a clock that went back shows it again")


func test_the_username_is_claimed_when_the_server_says_so_or_has_the_profiles_name() -> void:
	assert_true(OnlineRules.is_claimed("Pip", "Kit", true), "the server's claimed flag wins")
	assert_false(OnlineRules.is_claimed("Pip", "Pip", false))
	assert_true(OnlineRules.is_claimed("Pip", "Pip"))
	assert_true(OnlineRules.is_claimed("pip", "Pip"), "uniqueness is case-insensitive (§5.13)")
	assert_false(OnlineRules.is_claimed("XyZabcDEfg", "Pip"), "Nakama's random name until the claim")
	assert_false(OnlineRules.is_claimed("", ""))


# --- Friends ---

func test_nakamas_friend_states() -> void:
	assert_eq(OnlineRules.friend_state(0), OnlineRules.FRIEND)
	assert_eq(OnlineRules.friend_state(1), OnlineRules.SENT)
	assert_eq(OnlineRules.friend_state(2), OnlineRules.RECEIVED)
	assert_eq(OnlineRules.friend_state(3), OnlineRules.BLOCKED)
	assert_eq(OnlineRules.friend_state(7), &"")


func test_a_typed_friend_name_is_checked_before_it_goes_to_the_server() -> void:
	assert_eq(OnlineRules.check_friend_name("  Bo_2 ", "Pip"), "")
	assert_eq(OnlineRules.check_friend_name("", "Pip"), "empty_name")
	assert_eq(OnlineRules.check_friend_name("pip", "Pip"), "self")
	assert_eq(OnlineRules.check_friend_name("a b", "Pip"), "no_such_player", "a name no player can have")


# --- Invites (notification 101 / 102) ---

func test_an_invite_carries_a_match_a_friend_and_a_world() -> void:
	var inv := OnlineRules.parse_invite(JSON.stringify({"match_id": MATCH, "from_username": "Pip", "world_name": "Survivor"}), "u-1")
	assert_eq(inv.match_id, MATCH)
	assert_eq(inv.from_username, "Pip")
	assert_eq(inv.from_id, "u-1")
	assert_eq(inv.world_name, "Survivor")
	assert_eq(OnlineRules.invite_text(inv), "Pip invites you to their world!")


func test_broken_invites_are_dropped() -> void:
	for content: String in ["", "{", "[]", JSON.stringify({"match_id": "nope", "from_username": "Pip"}),
			JSON.stringify({"match_id": MATCH}), JSON.stringify({"match_id": MATCH, "from_username": "a b c"}),
			JSON.stringify({"match_id": 5, "from_username": "Pip"})]:
		assert_eq(OnlineRules.parse_invite(content, "u-1"), {}, content)


func test_a_world_name_is_one_of_ours_or_plain_world() -> void:
	var inv := OnlineRules.parse_invite(JSON.stringify({"match_id": MATCH, "from_username": "Pip", "world_name": "call 555 1234"}), "u")
	assert_eq(inv.world_name, "", "free text from the network never reaches the screen")
	assert_eq(OnlineRules.world_name(ModeRules.SANDBOX), "Sandbox")
	assert_eq(OnlineRules.world_name(ModeRules.SURVIVOR), "Survivor")


func test_the_match_id_of_a_cancelled_invite() -> void:
	assert_eq(OnlineRules.cancelled_match(JSON.stringify({"match_id": MATCH})), MATCH)
	assert_eq(OnlineRules.cancelled_match("{}"), "")


func test_four_players_at_most() -> void:
	assert_eq(OnlineRules.MAX_PLAYERS, 4)
	assert_true(OnlineRules.can_invite(1))
	assert_true(OnlineRules.can_invite(3))
	assert_false(OnlineRules.can_invite(4))


# --- Plain words ---

const CODES: Array[String] = ["taken", "too_short", "too_long", "bad_chars", "must_start_with_letter", "personal_info",
	"blocked_word", "bad_name", "consent_needed", "not_friends", "full", "offline", "no_such_player", "self", "empty_name",
	"blocked", "rate_limited", "online_off", "network", "not_yet", "no_provider", "already_friends", "not_signed_in",
	"bad_request", "unauthorized", "server", "consent_unavailable", "not_allowed_online", "not_claimed",
	"not_invited", "chat_not_allowed", "busy", "cannot_report_self", "match_full", "no_server", "spend_limit",
	"too_many_farms"]


func test_every_error_is_plain_kind_and_short() -> void:
	var banned: Array[String] = ["miss you", "don't go", "last chance", "hurry", "stupid", "error", "exception",
		"failed", "invalid", "rpc", "http", "null", "json"]
	for code in CODES:
		var text := OnlineRules.message(code)
		assert_ne(text, "", code)
		if code.contains("_"):
			assert_false(text.contains(code), "never the code itself: %s" % text)
		assert_lte(text.split(" ").size(), 12, "short enough to read aloud: %s" % text)
		for phrase in banned:
			assert_false(text.to_lower().contains(phrase), "%s: \"%s\" has \"%s\"" % [code, text, phrase])


## M4 Task 10 review C and D (module 0.2.10): the two new economy limits have words of their own.
func test_the_economy_limits_of_module_0_2_10_have_their_own_words() -> void:
	for code: String in ["spend_limit", "too_many_farms"]:
		assert_ne(OnlineRules.message(code), OnlineRules.message(""), code)
	assert_ne(OnlineRules.message("spend_limit"), OnlineRules.message("too_many_farms"))


func test_a_refused_join_says_why() -> void:
	assert_eq(OnlineRules.message("match: match_full"), OnlineRules.message("full"))
	assert_eq(OnlineRules.message("match: not_invited"), OnlineRules.message("not_invited"))
	assert_eq(OnlineRules.message("match: Match not found"), OnlineRules.message("match_gone"))


func test_codes_we_do_not_know_still_read_kindly() -> void:
	assert_eq(OnlineRules.message("zzz_new_code"), OnlineRules.message(""))
	assert_eq(OnlineRules.message("socket: connection refused"), OnlineRules.message("network"),
		"a transport failure reads as the internet one")


func test_the_name_rules_share_their_words_with_the_first_launch_screen() -> void:
	assert_eq(OnlineRules.message("blocked_word"), UsernameRules.message("blocked_word"))
	assert_eq(OnlineRules.message("too_short"), UsernameRules.message("too_short"))


## Owner #93 ("play alone without an internet"): a "can't reach the game" comes with what still works on this device
## (a line of its own: the troubles' words stay short).
func test_no_internet_words_come_with_what_works_alone() -> void:
	for text: String in [OnlineRules.message("network"), NetWords.text(NetWords.NO_SERVER),
			NetWords.text(NetWords.TIMEOUT)]:
		var hint := OnlineRules.play_alone_hint(text)
		for mode: String in ["SANDBOX", "SURVIVOR", "MONSTER WAVE", "SCHOOL"]:
			assert_string_contains(hint, mode)
		assert_string_contains(hint, "gold")
	assert_eq(OnlineRules.play_alone_hint(OnlineRules.message("full")), "", "other troubles need no hint")
	assert_eq(OnlineRules.play_alone_hint("The server is resting."), "")


## The gold-double bug's leftover (module 0.2.19): the host's last word on this player's gold as the server heard it.
func test_the_account_keeps_the_hosts_last_report_when_the_server_says_it() -> void:
	var a := OnlineRules.account({"hosted": {"match_id": MATCH, "seq": 3.0}}, AgeBand.TEEN_PLUS)
	assert_eq(a.hosted, {"match_id": MATCH, "seq": 3})
	assert_eq(OnlineRules.account({"hosted": null}, AgeBand.TEEN_PLUS).hosted, {"match_id": "", "seq": 0}, "none yet")
	assert_eq(OnlineRules.account({"hosted": {"match_id": 5, "seq": "x"}}, AgeBand.TEEN_PLUS).hosted,
		{"match_id": "", "seq": 0})
	assert_false(OnlineRules.account({}, AgeBand.TEEN_PLUS).has("hosted"), "an older server can't say")
