extends GutTest
## Build to Survive's score (spec §12.18), per player name in the world (WorldMeta.game_scores): nights
## survived in a row without a knock-out, and the best. A score inside one world: never lost by being away.
## (Monster Hunter's hunt and packs went with #44; Monster Wave keeps its own best, ArenaRules.)


func test_a_new_record_starts_at_zero() -> void:
	assert_eq(GameScores.new_record(), {"nights": 0, "best_nights": 0})


func test_a_night_survived_counts_and_raises_the_best() -> void:
	var r := GameScores.new_record()
	assert_true(GameScores.night_survived(r), "the first night is a new best")
	assert_eq(r.nights, 1)
	assert_eq(r.best_nights, 1)
	GameScores.night_survived(r)
	assert_eq(r.nights, 2)
	assert_eq(r.best_nights, 2)


func test_a_knock_out_starts_the_nights_again_but_keeps_the_best() -> void:
	var r := GameScores.new_record()
	for i in 3:
		GameScores.night_survived(r)
	GameScores.knocked_out(r, SurvivorGames.BUILD)
	assert_eq(r.nights, 0)
	assert_eq(r.best_nights, 3)
	assert_false(GameScores.night_survived(r), "1 is not a new best")
	assert_eq(r.best_nights, 3)


func test_a_classic_knock_out_changes_nothing() -> void:
	var r := GameScores.new_record()
	GameScores.night_survived(r)
	var before := r.duplicate()
	GameScores.knocked_out(r, SurvivorGames.CLASSIC)
	assert_eq(r, before)


func test_saved_scores_are_read_defensively() -> void:
	var clean := GameScores.clean_all({"Kid": {"nights": 2, "best_nights": 5},
		"": {"nights": 4}, "Bad": "nope", "Weird": {"nights": -3, "best_nights": "x"},
		"Old": {"nights": 1, "best_nights": 1, "hunt": 9, "pack": 3}, "Big": {"nights": 1e30}})
	assert_eq(clean.Kid, {"nights": 2, "best_nights": 5})
	assert_false(clean.has(""), "no empty name")
	assert_false(clean.has("Bad"))
	assert_eq(clean.Weird, {"nights": 0, "best_nights": 0}, "never negative")
	assert_eq(clean.Old, {"nights": 1, "best_nights": 1}, "Monster Hunter's old keys are dropped")
	assert_eq(clean.Big.nights, GameScores.MAX_SCORE, "capped")
	assert_eq(GameScores.clean_all("broken"), {})
	assert_eq(GameScores.clean_all(null), {})


func test_the_best_is_never_below_the_run() -> void:
	assert_eq(GameScores.clean({"nights": 7, "best_nights": 2}).best_nights, 7)


func test_at_most_sixteen_players_per_world() -> void:
	var many := {}
	for i in 30:
		many["P%d" % i] = GameScores.new_record()
	assert_eq(GameScores.clean_all(many).size(), GameScores.MAX_PLAYERS)
