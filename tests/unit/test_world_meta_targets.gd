extends GutTest
## Practice targets are saved with the world (M1b Task 11).


func test_targets_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.targets = [{"item": ItemIds.DUMMY, "pos": [1.5, 20.0, -3.5], "yaw": 1.25},
		{"item": ItemIds.BULLSEYE, "pos": [4.5, 21.0, 0.5], "yaw": 0.0}]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.targets.size(), 2)
	assert_eq(int(back.targets[0].item), ItemIds.DUMMY)
	assert_eq(back.targets[0].pos, [1.5, 20.0, -3.5])
	assert_almost_eq(float(back.targets[0].yaw), 1.25, 0.0001)
	assert_eq(int(back.targets[1].item), ItemIds.BULLSEYE)


func test_old_saves_have_no_targets() -> void:
	assert_eq(WorldMeta.from_json('{"seed": 5}').targets, [])


func test_broken_targets_are_dropped_and_the_list_is_capped() -> void:
	var list: Array = [
		{"item": ItemIds.SWORD, "pos": [0, 0, 0], "yaw": 0},        # not a target item
		{"item": ItemIds.DUMMY, "pos": [0, 0]},                     # bad position
		{"item": ItemIds.DUMMY, "pos": [0, "x", 0]},
		"junk",
		{"item": "116", "pos": [0, 0, 0]},
	]
	for i in WeaponRules.MAX_TARGETS + 5:
		list.append({"item": ItemIds.BULLSEYE, "pos": [i, 10, 0]})   # no yaw: defaults to 0
	var back := WorldMeta.from_json(JSON.stringify({"seed": 1, "targets": list}))
	assert_eq(back.targets.size(), WeaponRules.MAX_TARGETS)
	for t: Dictionary in back.targets:
		assert_eq(int(t.item), ItemIds.BULLSEYE)
		assert_eq(float(t.yaw), 0.0)
