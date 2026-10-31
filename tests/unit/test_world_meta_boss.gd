extends GutTest
## M2 Task 10: the Stone Golem's honest help (research G3) and the portal are saved per world.


func test_a_new_world_has_no_help_and_no_portal() -> void:
	var m := WorldMeta.new_random()
	assert_eq(m.boss_help, BossRules.new_help())
	assert_false(m.has_portal())


func test_help_and_portal_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.boss_help = {"losses": 3, "best": 20, "wins": 1}
	m.portal_pos = Vector3(23.5, 12, 3.5)
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.boss_help, {"losses": 3, "best": 20, "wins": 1})
	assert_true(back.has_portal())
	assert_eq(back.portal_pos, Vector3(23.5, 12, 3.5))


func test_broken_boss_data_reads_as_none() -> void:
	for bad: Variant in [null, "x", 3, [], {"losses": "many", "portal": [1, 2]}, {"portal": [1, "x", 2]}]:
		var m := WorldMeta.from_json(JSON.stringify({"seed": 5, "boss": bad}))
		assert_eq(m.boss_help, BossRules.new_help(), "help from %s" % str(bad))
		assert_false(m.has_portal(), "portal from %s" % str(bad))
	var old := WorldMeta.from_json(JSON.stringify({"seed": 5}))
	assert_eq(old.boss_help, BossRules.new_help(), "a world saved before M2 Task 10")
