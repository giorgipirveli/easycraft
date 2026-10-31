extends GutTest
## Owner #133, #134 (docs/design/future-lessons.md §2, the cheat and transfer tests; docs/design/games/balance-altar.md
## §3.9, §4.6, ruling 35): the cheat test as a test. Can the temple be won without the knowledge? Bots stand in for
## children (tests/unit/altar_bots.gd, the phase A model's players) and play whole rooms through the production rules
## (AltarRun) for 1,000 seeded visits each, the numbers new every visit. The bar is MasteryRules': the Entrance Hall's 7
## of its 8 judged altars freed first time, the Sky Room's 5 of 6.
## - The hall: knowing the rule reaches it in at least 99 % of visits, slipping on 4 % of moves in at least 90 %;
##   random taps, random moves, one pan only, carrying across, weighing the crystal, both half-habits (always take away,
##   divide by the number), guessing which move and keeping the balance with no plan each in at most 1 %.
## - The Sky Room (transfer): the hall's habit (take away, then share) never reaches it; the rule always does.

const Bots := preload("res://tests/unit/altar_bots.gd")
const VISITS := 1000

var _seen := {}


## VISITS seeded visits of `bot` in `room`: {masters (a share of the visits), right_first (a visit, on average), breaks
## (a visit, on average)}; cached for the file.
func _visits(room: String, bot: String, visits: int = VISITS) -> Dictionary:
	var key := "%s|%s|%d" % [room, bot, visits]
	if _seen.has(key):
		return _seen[key]
	var masters := 0
	var right := 0
	var breaks := 0
	var total := 0
	for seed in visits:
		var v := Bots.play(room, bot, seed)
		masters += 1 if bool(v.masters) else 0
		right += int(v.right_first)
		breaks += int(v.breaks)
		total = int(v.total)
	var out := {"masters": float(masters) / visits, "right_first": float(right) / visits,
		"breaks": float(breaks) / visits}
	gut.p("ALTAR_BOTS %-8s %-28s masters %6.1f %%  %5.2f of %d first time  %6.2f breaks a visit  (%d visits)" % [room,
		bot, out.masters * 100.0, out.right_first, total, out.breaks, visits])
	_seen[key] = out
	return out


func test_knowing_the_rule_reaches_the_hall_s_bar() -> void:
	assert_gte(float(_visits("entrance", Bots.RULE).masters), 0.99, "the rule")
	assert_gte(float(_visits("entrance", Bots.SLIPS).masters), 0.90, "the rule with a slip on 4 % of moves")


func test_guessing_and_half_knowledge_never_reach_the_hall_s_bar() -> void:
	for bot: String in [Bots.RANDOM_TAPS, Bots.RANDOM_MOVES, Bots.ONE_PAN, Bots.ACROSS, Bots.WEIGH, Bots.TAKE_ONLY,
			Bots.SHARE_ONLY, Bots.GUESS, Bots.NO_PLAN]:
		assert_lte(float(_visits("entrance", bot).masters), 0.01, "%s must not master the hall" % bot)


func test_the_greedy_keeper_is_reported_not_a_cheat() -> void:
	## Fair moves aimed at making the crystal more alone are the understanding the hall teaches (§3.9): reported.
	var greedy := _visits("entrance", Bots.GREEDY)
	assert_gte(float(greedy.masters), 0.0)


func test_in_the_sky_room_the_hall_s_habit_never_wins_and_the_rule_always_does() -> void:
	var habit := _visits("sky", Bots.HABIT)
	assert_eq(float(habit.masters), 0.0, "take it away, then share: stuck at every balloon")
	assert_lte(float(habit.right_first), 2.0, "it frees only the two familiar altars")
	assert_eq(float(_visits("sky", Bots.RULE).masters), 1.0, "a gem undoes a balloon: always")
	assert_gte(float(_visits("sky", Bots.SLIPS).masters), 0.90)


func test_guessing_never_reaches_the_sky_room_s_bar_either() -> void:
	for bot: String in [Bots.RANDOM_TAPS, Bots.RANDOM_MOVES, Bots.ONE_PAN, Bots.ACROSS, Bots.TAKE_ONLY, Bots.GUESS,
			Bots.NO_PLAN]:
		assert_lte(float(_visits("sky", bot).masters), 0.01, "%s must not master the Sky Room" % bot)
	_visits("sky", Bots.GREEDY)
