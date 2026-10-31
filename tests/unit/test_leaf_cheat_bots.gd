extends GutTest
## Owner #133, #134 (docs/design/future-lessons.md §2, the cheat and transfer tests; docs/design/games/leaf-voyage.md
## §3.9, §4.6, ruling 23): the cheat test as a test. Can the leaf be mastered without the knowledge? Bots stand in for
## children (tests/unit/leaf_bots.gd) and play the production rules (LeafSim, LeafWeather, LeafBeats) for 1,000 seeded
## runs each. Guessing never masters the sunflower (random taps, always open, always shut, "more air, more sugar",
## "open when it's bright": under 1 %); the rule does (over 99 %, flat and in VR); a slow child who knows it mostly does
## (over 60 % flat, 95 % VR: knowledge decides). In the desert the sunflower's habit never wins and the cool-night rule
## always does: the idea has to change shape (transfer). A child who only watches the cells (shuts the doors as they
## drain) can master the sunflower without the weather idea, but never the desert: that is what the transfer is for
## (docs/devlog/parts/game-leaf-b.md, "The cheat test").

const Bots := preload("res://tests/unit/leaf_bots.gd")
const RUNS := 1000

var _seen := {}


## RUNS seeded runs of `policy` in `voyage`: {masters, wins (the desert's own: 6 sugars, never drooping), beats (a run,
## on average)}, each a share of the runs; cached for the file. A bot that never uses its random stream plays the same
## run for every seed: two seeds are checked to be the same and stand for all of them.
func _runs(voyage: String, policy: String, mode: String = "flat", runs: int = RUNS, step: float = Bots.DT) -> Dictionary:
	var key := "%s|%s|%s|%d|%f" % [voyage, policy, mode, runs, step]
	if _seen.has(key):
		return _seen[key]
	var masters := 0
	var wins := 0
	var beats := 0
	var played := runs
	if Bots.SAME_EVERY_SEED.has(policy):
		var a := Bots.play(voyage, policy, mode, 0, step)
		var b := Bots.play(voyage, policy, mode, 7919, step)
		var passed := func(r: Dictionary) -> bool: return bool(r.passed)
		assert_eq(a.results.map(passed), b.results.map(passed), "%s plays the same run for every seed" % policy)
		assert_eq(a.sugar, b.sugar)
		played = 1
	for seed in played:
		var r := Bots.play(voyage, policy, mode, seed, step)
		beats += int(r.passed)
		masters += 1 if Bots.masters(voyage, r) else 0
		wins += 1 if Bots.wins_desert(r) else 0
	var out := {"masters": float(masters) / played, "wins": float(wins) / played, "beats": float(beats) / played}
	var desert := ("  wins %6.1f %%" % (out.wins * 100.0)) if voyage == "5.T1" else ""
	gut.p("LEAF_BOTS %-4s %-13s %-4s masters %6.1f %%%s  %.2f beats a run  (%d runs, dt %.3f)" % [voyage, policy, mode,
		out.masters * 100.0, desert, out.beats, runs, step])
	_seen[key] = out
	return out


func test_guessing_never_masters_the_sunflower() -> void:
	for mode: String in ["flat", "vr"]:
		for policy: String in [Bots.RANDOM, Bots.ALWAYS_OPEN, Bots.ALWAYS_CLOSED, Bots.GREEDY, Bots.BRIGHT]:
			assert_lt(float(_runs("5.1", policy, mode).masters), 0.01, "%s (%s) must not master the leaf" % [policy, mode])


func test_knowing_the_rule_masters_the_sunflower() -> void:
	for mode: String in ["flat", "vr"]:
		assert_gt(float(_runs("5.1", Bots.RULE, mode).masters), 0.99, "the rule (%s)" % mode)


func test_a_slow_child_who_knows_the_rule_mostly_masters_it_too() -> void:
	assert_gt(float(_runs("5.1", Bots.SLOW, "flat").masters), 0.60, "flat: 0.8 s a door, 4 s to react")
	assert_gt(float(_runs("5.1", Bots.SLOW, "vr").masters), 0.95, "VR: 0.6 s a door")


func test_in_the_desert_the_sunflower_s_habit_never_wins_and_the_cool_night_rule_always_does() -> void:
	var habit := _runs("5.T1", Bots.HABIT)
	assert_eq(float(habit.masters), 0.0, "open in daylight, as the sunflower did: never")
	assert_eq(float(habit.wins), 0.0, "and the cactus dries")
	assert_eq(float(_runs("5.T1", Bots.CLOUD_HABIT).masters), 0.0, "waiting for a cloud that never comes")
	var rule := _runs("5.T1", Bots.RULE)
	assert_eq(float(rule.masters), 1.0, "open when it's cool (at night): always")
	assert_eq(float(rule.wins), 1.0, "6 sugars, the stem never drooping")


func test_guessing_never_masters_the_desert_either() -> void:
	for policy: String in [Bots.RANDOM, Bots.ALWAYS_OPEN, Bots.ALWAYS_CLOSED, Bots.GREEDY, Bots.BRIGHT]:
		assert_lt(float(_runs("5.T1", policy).masters), 0.01, policy)


func test_watching_the_cells_is_caught_by_the_desert() -> void:
	var sunflower := _runs("5.1", Bots.WATCH)
	gut.p("LEAF_BOTS finding: watching the cells masters the sunflower in %.1f %% of runs" % (sunflower.masters * 100.0))
	var desert := _runs("5.T1", Bots.WATCH)
	assert_lt(float(desert.masters), 0.01, "the dry sand and the blazing day drain the stem faster than watching saves it")
	assert_eq(float(desert.wins), 0.0)


func test_the_rule_still_wins_at_the_game_s_own_frame_rate() -> void:
	assert_gt(float(_runs("5.1", Bots.RULE, "flat", 100, 1.0 / 30.0).masters), 0.99, "steps of 1/30 s, as a phone draws")
	assert_eq(float(_runs("5.T1", Bots.RULE, "flat", 100, 1.0 / 30.0).masters), 1.0)
	assert_lt(float(_runs("5.1", Bots.RANDOM, "flat", 100, 1.0 / 30.0).masters), 0.02)
