extends GutTest
## Owner #37: a world keeps its day count for market day (WorldMeta.market); old and broken saves start at day 1.


func test_the_day_count_is_saved_and_read_back() -> void:
	var m := WorldMeta.new_random()
	m.market = {"day": 9}
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.market, {"day": 9})


func test_a_world_saved_before_starts_at_day_one() -> void:
	var m := WorldMeta.from_json(JSON.stringify({"seed": 5}))
	assert_eq(m.market, {"day": 1})
	assert_eq(WorldMeta.new_random().market, {"day": 1})


func test_a_broken_count_starts_at_day_one() -> void:
	for bad: Variant in ["x", [1], {"day": "nine"}, {"day": -4}]:
		var m := WorldMeta.from_json(JSON.stringify({"seed": 5, "market": bad}))
		assert_eq(m.market, {"day": 1}, str(bad))
