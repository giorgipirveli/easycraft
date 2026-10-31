extends GutTest
## Survivor games (spec §12.18): a world keeps the game it was made with and each player's scores; worlds
## saved before are CLASSIC with no scores; broken values read as the defaults.


func test_a_new_world_is_classic_with_no_scores() -> void:
	var m := WorldMeta.new_random()
	assert_eq(m.game, SurvivorGames.CLASSIC)
	assert_eq(m.game_scores, {})


func test_the_game_and_the_scores_are_saved() -> void:
	var m := WorldMeta.new_random()
	m.mode = ModeRules.SURVIVOR
	m.game = SurvivorGames.BUILD
	m.game_scores = {"Kid": {"nights": 3, "best_nights": 5}}
	var q := WorldMeta.from_json(m.to_json())
	assert_eq(q.game, SurvivorGames.BUILD)
	assert_eq(q.game_scores, m.game_scores)
	m.game = &"hunter"
	assert_eq(WorldMeta.from_json(m.to_json()).game, SurvivorGames.CLASSIC, "the first plan's Monster Hunter (#44)")


func test_worlds_saved_before_are_classic() -> void:
	var old := '{"version":1,"seed":5,"mode":"survivor","difficulty":"brave"}'
	var q := WorldMeta.from_json(old)
	assert_eq(q.game, SurvivorGames.CLASSIC)
	assert_eq(q.game_scores, {})
	assert_eq(q.difficulty, DifficultyRules.BRAVE, "everything else as before")


func test_broken_values_read_as_the_defaults() -> void:
	var q := WorldMeta.from_json('{"seed":5,"game":"tag","game_scores":{"Kid":{"nights":-4,"pack":0},"":{}}}')
	assert_eq(q.game, SurvivorGames.CLASSIC)
	assert_eq(q.game_scores, {"Kid": GameScores.new_record()})
	q = WorldMeta.from_json('{"seed":5,"game":7,"game_scores":[1,2]}')
	assert_eq(q.game, SurvivorGames.CLASSIC)
	assert_eq(q.game_scores, {})
