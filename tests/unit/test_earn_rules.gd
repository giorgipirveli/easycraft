extends GutTest
## Owner #79 (spec §25.1): Survivor gold for learning, puzzles, the Lab and secrets, in one table (EarnRules). A School
## answer right the first time pays a few gold, with a daily cap so it never becomes a grind; a unit mastered pays its
## 100 once; a Lab experiment's first star and the first secret of each kind pay once each; nothing ever pays for time,
## for opening a lesson or for reading. The words say what the gold was for.

const DAY := 20_000

var profile: ProfileData


func before_each() -> void:
	profile = ProfileData.new()
	profile.survivor_gold = 25


func test_the_table_names_every_way_to_earn_and_only_learning_pays() -> void:
	var ids: Array[String] = []
	for row: Dictionary in EarnRules.TABLE:
		ids.append(str(row.id))
		assert_true(int(row.gold) > 0, "%s pays something" % row.id)
		assert_ne(str(row.get("when", "")), "", "%s says when" % row.id)
	for id in ["answer", "unit", "lab_star", "secret", "secret_kind", "fact_quiz", "friend_learned", "friend_welcome"]:
		assert_has(ids, id)
	for id in ["time", "open_lesson", "read", "login"]:
		assert_does_not_have(ids, id, "never for %s" % id)
	assert_eq(EarnRules.UNIT_GOLD, MasteryRules.UNIT_GOLD, "the School's 100 stays the one number")


func test_a_day_of_learning_buys_the_first_rocket_part() -> void:
	# The tuning (spec §25.1): a day's rounds and a unit mastered is about one rocket part (SpendRules' guide).
	var day := EarnRules.ANSWER_DAY_CAP + EarnRules.UNIT_GOLD + EarnRules.LAB_STAR_GOLD
	assert_between(day, 200, 400)
	assert_between(EarnRules.ANSWER_GOLD, 2, 10, "a few gold an answer")
	assert_eq(EarnRules.ANSWER_DAY_CAP % EarnRules.ANSWER_GOLD, 0)


func test_an_answer_right_the_first_time_pays_until_the_day_is_full() -> void:
	var paid := 0
	for i in 100:
		paid += EarnRules.answer_gold(profile, DAY)
	assert_eq(paid, EarnRules.ANSWER_DAY_CAP, "capped")
	assert_eq(profile.survivor_gold, 25 + EarnRules.ANSWER_DAY_CAP)
	assert_eq(EarnRules.answer_gold(profile, DAY), 0)
	assert_eq(EarnRules.answer_gold(profile, DAY + 1), EarnRules.ANSWER_GOLD, "a new day")
	assert_eq(EarnRules.answer_gold(profile, DAY), 0, "a clock turned back never pays the day again")
	assert_eq(EarnRules.answer_left(profile, DAY + 1), EarnRules.ANSWER_DAY_CAP - EarnRules.ANSWER_GOLD)


func test_the_day_record_survives_a_save_and_bad_data() -> void:
	EarnRules.answer_gold(profile, DAY)
	var back := ProfileData.from_json(profile.to_json())
	assert_eq(back.earn_today, {"d": DAY, "g": EarnRules.ANSWER_GOLD})
	for bad: Variant in ["x", [1], {"d": -3, "g": 5}, {"d": DAY, "g": 1e20}, {"d": "a", "g": 1}]:
		var p := ProfileData.from_json(JSON.stringify({"version": 1, "earn_today": bad}))
		assert_true(p.earn_today.is_empty() or int(p.earn_today.g) <= EarnRules.ANSWER_DAY_CAP, str(bad))


func test_credit_adds_whole_positive_gold_only() -> void:
	assert_eq(EarnRules.credit(profile, 25), 25)
	assert_eq(EarnRules.credit(profile, -5), 0)
	assert_eq(EarnRules.credit(profile, 0), 0)
	assert_eq(profile.survivor_gold, 50)
	profile.survivor_gold = Wallet.MAX_GOLD - 3
	assert_eq(EarnRules.credit(profile, 100), 3, "never past the wallet's top")


func test_the_words_say_what_the_gold_was_for() -> void:
	assert_eq(EarnRules.answer_words(5), "+5 gold: right the first time!")
	assert_eq(EarnRules.round_words(30), "+30 gold for answers right the first time!")
	assert_eq(EarnRules.lab_words(), "+%d gold!" % EarnRules.LAB_STAR_GOLD)
	assert_eq(EarnRules.secret_words(), "+%d gold: your first one of these!" % EarnRules.SECRET_KIND_GOLD)
	assert_string_contains(EarnRules.DAY_FULL_WORDS, "today")
	for w in [EarnRules.answer_words(5), EarnRules.round_words(30), EarnRules.lab_words(), EarnRules.DAY_FULL_WORDS]:
		for pressure in ["hurry", "don't miss", "last chance", "lose", "only today"]:
			assert_false(w.to_lower().contains(pressure), "no pressure: %s" % w)


func test_the_first_secret_of_a_kind_pays_once() -> void:
	assert_eq(EarnRules.secret_gold(1), EarnRules.SECRET_KIND_GOLD, "the first of its kind")
	assert_eq(EarnRules.secret_gold(2), 0)
	assert_eq(EarnRules.secret_gold(0), 0, "an unknown kind")
