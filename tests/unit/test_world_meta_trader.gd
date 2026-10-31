extends GutTest
## M2 Task 7: Tilly's stall is saved with the world (placed once, when the world is made), and so is
## whether the player has visited her yet (the one-time hint arrow over her stall).


func test_a_new_world_has_no_trader_yet_and_the_hint_is_on() -> void:
	var m := WorldMeta.new()
	assert_false(m.has_trader())
	assert_false(m.trader_visited)


func test_the_stall_and_the_visit_round_trip() -> void:
	var m := WorldMeta.new()
	m.trader_pos = Vector3(52.5, 31.0, -19.5)
	m.trader_yaw = 1.25
	m.trader_visited = true
	var back := WorldMeta.from_json(m.to_json())
	assert_true(back.has_trader())
	assert_eq(back.trader_pos, Vector3(52.5, 31.0, -19.5))
	assert_almost_eq(back.trader_yaw, 1.25, 0.0001)
	assert_true(back.trader_visited)


func test_a_world_without_a_trader_saves_none() -> void:
	var back := WorldMeta.from_json(WorldMeta.new().to_json())
	assert_false(back.has_trader())
	assert_false(JSON.parse_string(WorldMeta.new().to_json()).has("trader"))


func test_broken_trader_entries_are_ignored() -> void:
	for bad: String in ['"x"', '{"pos": [1, 2]}', '{"pos": [1, "a", 3]}', '{"pos": null}', '[1, 2, 3]']:
		var m := WorldMeta.from_json('{"seed": 5, "trader": %s}' % bad)
		assert_false(m.has_trader(), bad)
		assert_eq(m.seed, 5, "the rest of the save still loads")
	var m := WorldMeta.from_json('{"trader": {"pos": [1, 2, 3], "yaw": "left", "visited": "yes"}}')
	assert_true(m.has_trader())
	assert_eq(m.trader_yaw, 0.0, "a bad yaw faces north")
	assert_false(m.trader_visited, "a bad flag keeps the hint")
