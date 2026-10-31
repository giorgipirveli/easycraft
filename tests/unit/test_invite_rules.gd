extends GutTest
## Owner #79, #81, #82, #85 (spec §25.2; the world game plan §2, §2b): the game's side of the invite program. A code is
## typed any way; the links carry only the code; the page's words name a friend by the in-game name only, never push;
## the Explorer ranks (1, 3, 5, 10, 25, 50, 100 friends who learned) are things to show; the profile keeps a code typed
## before the server took it, the guide's name and the first unit mastered until the server has heard.

func test_a_code_is_typed_any_way() -> void:
	assert_eq(InviteRules.canonical("BLUE-OTTER-42"), "BLUEOTTER42")
	assert_eq(InviteRules.canonical("  blue otter 42 "), "BLUEOTTER42")
	assert_eq(InviteRules.canonical("Blue_Otter-42"), "BLUEOTTER42")
	assert_eq(InviteRules.canonical("blue!otter"), "")
	assert_eq(InviteRules.canonical(""), "")
	assert_true(InviteRules.looks_like_code("blue otter 42"))
	assert_true(InviteRules.looks_like_code("CLASS-JADE-OWL-27"))
	assert_false(InviteRules.looks_like_code("hello"), "a code ends with its number")
	assert_false(InviteRules.looks_like_code("42"), "and starts with a word")
	assert_false(InviteRules.looks_like_code("x".repeat(InviteRules.MAX_TYPED + 1) + "1"))
	assert_eq(InviteRules.shown("  blue otter 42 "), "BLUE-OTTER-42", "shown as it will be read out")


func test_the_links_carry_only_the_code() -> void:
	assert_eq(InviteRules.link("BLUE-OTTER-42"), "https://178-104-20-64.sslip.io/play/?invite=BLUE-OTTER-42")
	assert_eq(InviteRules.pages_link("BLUE-OTTER-42"), "https://giorgipirveli.github.io/easycraft/?invite=BLUE-OTTER-42")
	assert_eq(InviteRules.store_link("BLUE-OTTER-42"),
		"https://play.google.com/store/apps/details?id=com.giorgi.easycraft&referrer=invite%3DBLUE-OTTER-42")
	assert_eq(InviteRules.share_text("BLUE-OTTER-42"),
		"Come and learn with me in EasyCraft! My invite code: BLUE-OTTER-42\nhttps://178-104-20-64.sslip.io/play/?invite=BLUE-OTTER-42")


func test_a_web_page_address_gives_its_code() -> void:
	assert_eq(InviteRules.code_from_query("?invite=BLUE-OTTER-42"), "BLUE-OTTER-42")
	assert_eq(InviteRules.code_from_query("?x=1&invite=blue-otter-42&y=2"), "BLUE-OTTER-42")
	assert_eq(InviteRules.code_from_query("?invite=BLUE%20OTTER%2042"), "BLUE-OTTER-42")
	assert_eq(InviteRules.code_from_query("?invite=<script>"), "")
	assert_eq(InviteRules.code_from_query("?inviter=BLUE-OTTER-42"), "")
	assert_eq(InviteRules.code_from_query(""), "")


func test_the_rewards_match_the_server() -> void:
	# server/modules/src/rules/referral_rules.ts: the same numbers (the server pays; the game says them).
	assert_eq(InviteRules.WELCOME_GOLD, 100)
	assert_eq(InviteRules.INVITER_GOLD, 250)
	assert_eq(InviteRules.LEARNER_GOLD, 50)
	assert_eq(InviteRules.TREE_GOLD, 25)
	assert_eq(InviteRules.LANDED_GOLD, 150)


func test_the_explorer_ranks_are_things_to_show() -> void:
	var at: Array[int] = []
	for r: Dictionary in InviteRules.RANKS:
		at.append(int(r.at))
		assert_ne(str(r.title), "")
		assert_ne(str(r.reward), "")
		for power in ["stronger", "damage", "faster", "weaker"]:
			assert_false(str(r.reward).contains(power), "never power: %s" % r.reward)
	assert_eq(at, [1, 3, 5, 10, 25, 50, 100])
	assert_eq(InviteRules.rank_for(0), {})
	assert_eq(int(InviteRules.rank_for(1).at), 1)
	assert_eq(int(InviteRules.rank_for(4).at), 3)
	assert_eq(int(InviteRules.rank_for(250).at), 100)
	assert_eq(int(InviteRules.next_rank(4).at), 5)
	assert_eq(InviteRules.next_rank(100), {})
	assert_eq(InviteRules.mentor_title(0), "")
	assert_eq(InviteRules.mentor_title(1), "Mentor")
	assert_eq(InviteRules.mentor_title(5), "Mentor of 5")
	assert_eq(InviteRules.mentor_title(12), "Mentor of 10")


func test_the_words_name_a_friend_by_the_in_game_name_only_and_never_push() -> void:
	assert_eq(InviteRules.news_words({"what": "learned", "name": "Sam_22", "gold": 250}),
		"Your friend Sam_22 joined and learned! +250 gold")
	assert_eq(InviteRules.news_words({"what": "joined", "name": "Sam_22", "gold": 0}), "Your friend Sam_22 joined with your code!")
	assert_eq(InviteRules.news_words({"what": "joined", "name": "", "gold": 0}), "A new friend joined with your code!")
	assert_eq(InviteRules.news_words({"what": "tree", "name": "", "gold": 25}),
		"A friend of your friend learned! Your tree grows. +25 gold")
	assert_eq(InviteRules.news_words({"what": "landed", "name": "Sam_22", "gold": 150}),
		"Your friend Sam_22 landed on the Moon! +150 gold")
	assert_string_contains(InviteRules.news_words({"what": "learned", "name": "Sam_22", "gold": 0}), "still counts")
	assert_eq(InviteRules.welcome_words("Alex_7", 100), "Welcome, explorer! Alex_7's code brought you +100 gold.")
	assert_eq(InviteRules.learner_words("Alex_7", 50), "You learned a whole unit with your guide Alex_7: +50 gold!")
	var all: Array[String] = [InviteRules.WHY, InviteRules.GROWN_UP_LINE, InviteRules.NO_ONE_LINE,
		InviteRules.news_words({"what": "learned", "name": "S", "gold": 0})]
	for code in ["unknown", "own_code", "already_used", "not_new", "already_in", "group_full", "locked", "bad"]:
		all.append(InviteRules.error_words(code))
	for w in all:
		for pressure in ["hurry", "or else", "last chance", "lose", "only today", "don't miss", "must invite"]:
			assert_false(w.to_lower().contains(pressure), "no pressure: %s" % w)
	assert_string_contains(InviteRules.GROWN_UP_LINE, "no personal information")
	assert_eq(InviteRules.tree_words(23), "Your tree: 23 children learning")
	assert_eq(InviteRules.tree_words(1), "Your tree: 1 child learning")


func test_the_profile_keeps_what_the_server_has_not_heard_yet() -> void:
	var d := InviteData.new()
	assert_true(d.is_empty())
	d.pending_code = "BLUE-OTTER-42"
	assert_true(d.note_learned(20_000))
	assert_false(d.note_learned(20_005), "the first unit once")
	assert_eq(d.learned_day, 20_000)
	assert_true(d.note_landed("moon"))
	assert_false(d.note_landed("moon"))
	assert_eq(d.events_to_send(), [{"event": "learned"}, {"event": "landed", "where": "moon"}] as Array[Dictionary])
	d.mark_sent("learned")
	assert_eq(d.events_to_send(), [{"event": "landed", "where": "moon"}] as Array[Dictionary])
	var back := InviteData.from_dict(d.to_dict())
	assert_eq(back.to_dict(), d.to_dict())
	var junk := InviteData.from_dict({"pending_code": "<b>", "used": "yes", "guide": 5, "learned_day": -3, "sent": ["x", 1],
		"landed": ["moon", "pluto"]})
	assert_eq(junk.pending_code, "")
	assert_false(junk.used)
	assert_eq(junk.guide, "")
	assert_eq(junk.learned_day, 0)
	assert_eq(junk.sent, [] as Array[String])
	assert_eq(junk.landed, ["moon"] as Array[String])


func test_two_copies_of_the_profile_merge_without_losing_anything() -> void:
	var a := InviteData.new()
	a.used = true
	a.guide = "Alex_7"
	a.note_learned(20_010)
	var b := InviteData.new()
	b.note_learned(20_000)
	b.mark_sent("learned")
	b.pending_code = "RED-FOX-11"
	a.merge_from(b)
	assert_true(a.used)
	assert_eq(a.guide, "Alex_7")
	assert_eq(a.learned_day, 20_000, "the first day")
	assert_eq(a.sent, ["learned"] as Array[String], "never sent twice")
	assert_eq(a.pending_code, "", "a code already used is not kept waiting")


func test_the_profile_saves_it() -> void:
	var p := ProfileData.new()
	p.invite.guide = "Alex_7"
	p.invite.used = true
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.invite.guide, "Alex_7")
	assert_true(back.invite.used)
