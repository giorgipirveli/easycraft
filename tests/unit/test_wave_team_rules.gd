extends GutTest
## Totem waves grow with the team (M4 Wave 2, Agent E; spec §12.8, §17.5): +50% monsters for each
## player or bot friend beyond the first (like the Stone Golem's health, BotFriend.team_size),
## capped at 20 (Sandbox's gentle waves at 8). A bigger wave is the same wave plus more monsters, so
## children can still learn it.


func test_one_player_gets_the_wave_as_before() -> void:
	for n in range(1, 12):
		assert_eq(WaveRules.size(n, false, 1), WaveRules.size(n, false), "wave %d" % n)
		assert_eq(WaveRules.roster(n, false, 1), WaveRules.roster(n, false))
	assert_eq(WaveRules.size(1, false, 0), 5, "no team counts as one player")
	assert_eq(WaveRules.size(1, false, -2), 5)


func test_half_again_for_each_extra_player() -> void:
	assert_eq(WaveRules.size(1, false, 2), 8, "5 x 1.5, rounded up")
	assert_eq(WaveRules.size(1, false, 3), 10, "5 x 2")
	assert_eq(WaveRules.size(1, false, 4), 13, "5 x 2.5, rounded up")
	assert_eq(WaveRules.size(3, false, 2), 14, "9 x 1.5, rounded up")


func test_never_more_than_20_or_8_when_gentle() -> void:
	assert_eq(WaveRules.size(8, false, 2), WaveRules.MAX_SIZE, "19 x 1.5 is capped")
	for team in range(1, 8):
		for n in range(1, 20):
			assert_lte(WaveRules.size(n, false, team), WaveRules.MAX_SIZE)
			assert_lte(WaveRules.size(n, true, team), WaveRules.GENTLE_MAX_SIZE)
	assert_eq(WaveRules.size(1, true, 4), WaveRules.GENTLE_MAX_SIZE, "Sandbox: 13 is gently 8")


func test_a_bigger_wave_is_the_same_wave_plus_more() -> void:
	for team in range(1, 5):
		var roster := WaveRules.roster(3, false, team)
		assert_eq(roster.size(), WaveRules.size(3, false, team))
		assert_eq(roster.slice(0, WaveRules.size(3, false)), WaveRules.roster(3, false), "team %d starts with the solo wave" % team)
		assert_eq(roster, WaveRules.roster(3, false, team), "always the same monsters for this team")
		var lv := WaveRules.levels(3, false)
		for m: Dictionary in roster:
			assert_between(int(m.level), lv.x, lv.y, "no stronger monsters, only more")
