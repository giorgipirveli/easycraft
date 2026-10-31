extends GutTest
## M2 Task 9: the Monster Totem is saved with the world (where it stands, which way it faces, and the
## wave it offers next), and broken entries are handled.


func test_the_totem_and_its_wave_round_trip() -> void:
	var m := WorldMeta.new()
	m.totem_pos = Vector3(20.5, 33, -4.5)
	m.totem_yaw = 1.25
	m.wave_next = 6
	var back := WorldMeta.from_json(m.to_json())
	assert_true(back.has_totem())
	assert_eq(back.totem_pos, Vector3(20.5, 33, -4.5))
	assert_almost_eq(back.totem_yaw, 1.25, 0.0001)
	assert_eq(back.wave_next, 6)


func test_a_new_world_has_no_totem_yet_and_offers_wave_1() -> void:
	var m := WorldMeta.new()
	assert_false(m.has_totem())
	assert_eq(m.wave_next, 1)
	var back := WorldMeta.from_json(m.to_json())
	assert_false(back.has_totem())
	assert_eq(back.wave_next, 1)


func test_broken_totem_entries() -> void:
	assert_false(WorldMeta.from_json('{"totem": "here"}').has_totem())
	assert_false(WorldMeta.from_json('{"totem": {"pos": [1, 2]}}').has_totem())
	var m := WorldMeta.from_json('{"totem": {"pos": [1, 2, 3], "yaw": "x", "wave": -4}}')
	assert_true(m.has_totem())
	assert_eq(m.totem_yaw, 0.0)
	assert_eq(m.wave_next, 1, "never below wave 1")
	assert_eq(WorldMeta.from_json('{"totem": {"pos": [1, 2, 3], "wave": 1e9}}').wave_next, WaveRules.MAX_WAVE)
	assert_eq(WorldMeta.from_json('{"totem": {"pos": [1, 2, 3], "wave": 4.7}}').wave_next, 4)
