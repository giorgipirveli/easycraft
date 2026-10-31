extends GutTest
## Owner #81, #82 (brief 2026-09-30 item 5; the world game plan §1 "Belonging"): crews. 2-6 friends, a name of two
## words from kid-safe lists, a badge, a crew page with each member's avatar and what each learned this week (never a
## ranking), the crew's weekly learning goal. The lists and numbers are the server's (social_rules.ts).

const SOCIAL_TS := "res://server/modules/src/rules/social_rules.ts"
const RANKING: Array[String] = ["first place", "winner", "top", "best learner", "rank", "leader", "last", "behind"]


func after_all() -> void:
	Curriculum.clear_cache()


func test_the_word_lists_badges_and_sizes_are_the_servers() -> void:
	var ts := FileAccess.get_file_as_string(SOCIAL_TS)
	for w: String in CrewRules.ADJECTIVES + CrewRules.NOUNS:
		assert_string_contains(ts, '"%s"' % w)
	assert_string_contains(ts, "CREW_ADJECTIVES = [\"%s\"" % CrewRules.ADJECTIVES[0])
	assert_string_contains(ts, "BADGES = %s;" % JSON.stringify(CrewRules.BADGES).replace(",", ", "))
	assert_string_contains(ts, "CREW_MIN = %d;" % CrewRules.MIN)
	assert_string_contains(ts, "CREW_MAX = %d;" % CrewRules.MAX)
	assert_string_contains(ts, "CREW_GOAL_PER_MEMBER = %d;" % CrewRules.GOAL_PER_MEMBER)
	assert_eq(CrewRules.ADJECTIVES.size(), 20)
	assert_eq(CrewRules.NOUNS.size(), 20)


func test_a_crews_name_and_goal_in_words() -> void:
	assert_eq(CrewRules.name_of("Brave", "Comets"), "Brave Comets")
	assert_eq(CrewRules.goal_words(4, 12), "This week together: 4 of 12 learning days")
	assert_eq(CrewRules.goal_words(12, 12), "This week together: 12 of 12 learning days. Goal reached!")
	assert_eq(CrewRules.goal_words(15, 12), "This week together: 15 of 12 learning days. Goal reached!")
	assert_eq(CrewRules.size_words(1), "1 of 6 seats filled: invite a friend to learn with you!")
	assert_eq(CrewRules.size_words(4), "4 of 6 seats filled")
	assert_eq(CrewRules.size_words(6), "Every seat is filled!")


func test_what_a_member_learned_this_week() -> void:
	var units: Array = ["g4.maths.equal_fractions", "g4.science.no_such_unit"]
	var t := str(Curriculum.unit("g4.maths.equal_fractions").get("title", ""))
	assert_ne(t, "", "a real unit")
	assert_eq(CrewRules.week_words({"days": 3, "units": units}), "3 learning days. Mastered: %s" % t)
	assert_eq(CrewRules.week_words({"days": 1, "units": []}), "1 learning day this week")
	assert_eq(CrewRules.week_words({"days": 0, "units": []}), "Resting this week")


func test_no_ranking_and_no_pressure_in_any_line() -> void:
	var lines: Array[String] = [CrewRules.ABOUT, CrewRules.GOAL_ABOUT, CrewRules.ROCKET_LATER, CrewRules.goal_words(0, 6),
		CrewRules.goal_words(6, 6), CrewRules.size_words(1), CrewRules.size_words(6),
		CrewRules.week_words({"days": 0, "units": []})]
	for w in lines:
		assert_ne(w, "")
		for r in RANKING:
			assert_false(w.to_lower().contains(r), "never a ranking (%s): %s" % [r, w])
		for p in ["hurry", "lose", "must", "or else", "streak"]:
			assert_false(w.to_lower().contains(p), "no pressure (%s): %s" % [p, w])
