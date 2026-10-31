extends GutTest
## Owner #81, #82, #85 (brief 2026-09-30 item 4; the world game plan §2b: Pokémon GO's friendship levels, Duolingo's
## study buddies): friendship levels by days together (learning the same day, a present, a cheer), each opening a shared
## reward; study buddies whose days learning together never fall; cheers of kind words only. The numbers are the
## server's (server/modules/src/rules/social_rules.ts); the words are calm.

const SOCIAL_TS := "res://server/modules/src/rules/social_rules.ts"
const PRESSURE: Array[String] = ["hurry", "or else", "last chance", "lose", "only today", "don't miss", "must", "streak",
	"miss out", "sad", "don't go"]


func test_levels_cheers_and_numbers_are_the_servers() -> void:
	var ts := FileAccess.get_file_as_string(SOCIAL_TS)
	for l: Dictionary in FriendshipRules.LEVELS:
		assert_string_contains(ts, '{ at: %d, id: "%s", reward: "%s" }' % [l.at, l.id, l.reward])
	assert_string_contains(ts, "CHEERS = %s;" % JSON.stringify(FriendshipRules.CHEER_IDS).replace(",", ", "))
	assert_string_contains(ts, "BUDDIES_MAX = %d;" % FriendshipRules.BUDDIES_MAX)
	assert_string_contains(ts, "MOMENT_KINDS = %s;" % JSON.stringify(PostcardRules.KINDS).replace(",", ", "))
	assert_eq(FriendshipRules.CHEER_IDS.size(), FriendshipRules.CHEERS.size())


func test_levels_grow_with_days_together() -> void:
	assert_eq(FriendshipRules.level_of(0), 0)
	assert_eq(FriendshipRules.level_of(1), 1)
	assert_eq(FriendshipRules.level_of(7), 2)
	assert_eq(FriendshipRules.level_of(30), 3)
	assert_eq(FriendshipRules.title(0), "Friends")
	assert_eq(FriendshipRules.title(2), "Great friends")
	assert_eq(FriendshipRules.days_words(1), "1 day together")
	assert_eq(FriendshipRules.days_words(9), "9 days together")
	assert_eq(FriendshipRules.next_words(3), "4 more days together to Great friends: a two-seat rover to drive together")
	assert_eq(FriendshipRules.next_words(0), "1 more day together to Good friends: a friendship badge")
	assert_eq(FriendshipRules.next_words(30), "Best friends: a shared room in the colony dome is yours")
	assert_eq(FriendshipRules.reward_of(2), "a two-seat rover to drive together")


func test_news_in_a_childs_words() -> void:
	var w := func(n: Dictionary) -> String: return FriendshipRules.news_words(n)
	assert_eq(w.call({"what": "cheer", "name": "Sam_22", "kind": "amazing", "place": "landed:moon"}),
		"Sam_22 cheered: Amazing! (you landed on the Moon)")
	assert_eq(w.call({"what": "thanks", "name": "Sam_22", "kind": "seeds", "gold": 10}),
		"Sam_22 said thank you for the seeds! +10 gold")
	assert_eq(w.call({"what": "thanks", "name": "Sam_22", "kind": "seeds", "gold": 0}), "Sam_22 said thank you for the seeds!")
	assert_eq(w.call({"what": "present", "name": "Sam_22", "kind": "buddy_egg"}), "Sam_22 sent you a buddy egg! Open it in FRIENDS.")
	assert_eq(w.call({"what": "link_present", "name": "Bo_9", "kind": "seeds"}),
		"Bo_9 joined with your code and got your seeds!")
	assert_eq(w.call({"what": "buddy_ask", "name": "Sam_22"}), "Sam_22 asks: study buddies? Say yes in FRIENDS.")
	assert_eq(w.call({"what": "buddy_yes", "name": "Sam_22"}), "Sam_22 said yes: you're study buddies!")
	assert_eq(w.call({"what": "crew_invite", "name": "Sam_22"}), "Sam_22 asks you to join their crew! See CREW in FRIENDS.")
	assert_eq(w.call({"what": "crew_join", "name": "Sam_22"}), "Sam_22 joined your crew!")
	assert_eq(w.call({"what": "level", "name": "Sam_22", "kind": "great"}),
		"You and Sam_22 are Great friends now: a two-seat rover to drive together!")
	assert_eq(w.call({"what": "who knows"}), "")


func test_moments_to_cheer_and_the_study_buddy_week() -> void:
	assert_eq(FriendshipRules.moment_words("Sam_22", "landed", "moon"), "Sam_22 just landed on the Moon! Send a cheer?")
	assert_eq(FriendshipRules.moment_words("Sam_22", "grade", "g4.maths"), "Sam_22 just mastered grade 4 maths! Send a cheer?")
	assert_eq(FriendshipRules.moment_words("Sam_22", "deposit", "gold"), "Sam_22 just found gold! Send a cheer?")
	assert_eq(FriendshipRules.buddy_words(12), "Study buddies: 12 days learning together")
	assert_eq(FriendshipRules.buddy_row_words([0, 0, 1, 2, 2, 0, 2]), "This week: 3 days together")


func test_every_word_is_kind_and_calm() -> void:
	var lines: Array[String] = [FriendshipRules.BUDDY_GOAL, FriendshipRules.NO_FRIENDS, FriendshipRules.CHEER_LINE]
	for c: String in FriendshipRules.CHEERS.values():
		lines.append(c)
	for l: Dictionary in FriendshipRules.LEVELS:
		lines.append(l.title)
		lines.append(l.words)
	for d in 40:
		lines.append(FriendshipRules.next_words(d))
	for w in lines:
		assert_ne(w, "")
		for p in PRESSURE:
			assert_false(w.to_lower().contains(p), "no pressure (%s): %s" % [p, w])
