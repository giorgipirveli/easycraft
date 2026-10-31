extends GutTest
## M2 Task 12, acceptance row 13: the autopilot at night with monsters. With NIGHT RUN on, the
## autopilot jumps to night and summons a full player's worth of monsters around itself (the night
## share of slimes and goblins, levels 1-3), then measures as usual.

const Autopilot := preload("res://tools/autopilot.gd")


func test_a_night_brings_a_full_players_worth_of_monsters() -> void:
	var lineup: Array = Autopilot.night_lineup()
	assert_eq(lineup.size(), MonsterRules.MAX_PER_PLAYER)
	var slimes := lineup.filter(func(e: Array) -> bool: return e[0] == MonsterRules.SLIME).size()
	assert_eq(slimes, roundi(MonsterRules.MAX_PER_PLAYER * MonsterRules.SLIME_SHARE), "the night's share of slimes")
	for e: Array in lineup:
		assert_has(MonsterRules.KINDS, e[0])
		assert_between(int(e[1]), 1, 3, "a level Meadows nights bring")


func test_the_night_run_is_off_unless_asked() -> void:
	assert_false(Game.autopilot_night)
