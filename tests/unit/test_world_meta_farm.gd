extends GutTest
## M3 Task 10: a world's Gold Farm is saved in WorldMeta (one per world): where it stands, its levels and
## whether its owner left inside it (and when).


func test_a_world_without_a_farm_saves_none() -> void:
	var m := WorldMeta.new()
	assert_eq(m.farm, {})
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.farm, {})


func test_the_farm_round_trips() -> void:
	var m := WorldMeta.new()
	m.farm = FarmRules.left_inside(FarmRules.new_farm(Vector3i(-12, 41, 30), 3, 2, 1), 1_800_000_000, true)
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.farm, m.farm)
	assert_eq(back.farm.pos, Vector3i(-12, 41, 30))


func test_a_broken_farm_entry_is_no_farm_and_the_rest_of_the_world_loads() -> void:
	var d: Dictionary = JSON.parse_string(WorldMeta.new().to_json())
	d.seed = 77
	d.farm = {"pos": "here", "facing": 1}
	var back := WorldMeta.from_json(JSON.stringify(d))
	assert_eq(back.farm, {})
	assert_eq(back.seed, 77)


func test_worlds_saved_before_the_farm_have_none() -> void:
	var d: Dictionary = JSON.parse_string(WorldMeta.new().to_json())
	d.erase("farm")
	assert_eq(WorldMeta.from_json(JSON.stringify(d)).farm, {})


func test_a_packed_farm_round_trips() -> void:
	var m := WorldMeta.new()
	m.farm = FarmRules.packed(FarmRules.new_farm(Vector3i(1, 2, 3), 0, 1, 2))
	assert_eq(WorldMeta.from_json(m.to_json()).farm, {"packed": true, "rate": 1, "cap": 2})
