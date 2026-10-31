extends GutTest
## M2 Task 16: one world's secrets are saved with the world (a chest opens once, a temple stays solved,
## the areas explored give the Secret Book's found / total), and a broken save never breaks anything.


func _full() -> SecretState:
	var s := SecretState.new()
	s.found["temple_1_2_3"] = true
	s.opened["treasure_0_0_1"] = true
	s.solved["temple_1_2_3"] = true
	s.chimed["room_-1_0_2"] = true
	s.explore(Vector2i(1, 2), 3)
	s.explore(Vector2i(-1, 0), 2)
	s.caught["a3_-4_0"] = true
	s.stars.append(Vector3i(10, 40, -3))
	s.dusks = 4
	s.nights = 3
	s.wanderer_rewarded = 4
	return s


func test_round_trip() -> void:
	var back := SecretState.from_save(JSON.parse_string(JSON.stringify(_full().to_save())))
	assert_eq(back.found.keys(), ["temple_1_2_3"])
	assert_eq(back.opened.keys(), ["treasure_0_0_1"])
	assert_eq(back.solved.keys(), ["temple_1_2_3"])
	assert_eq(back.chimed.keys(), ["room_-1_0_2"])
	assert_eq(back.explored, {Vector2i(1, 2): 3, Vector2i(-1, 0): 2})
	assert_eq(back.caught.keys(), ["a3_-4_0"])
	assert_eq(back.stars, [Vector3i(10, 40, -3)] as Array[Vector3i])
	assert_eq([back.dusks, back.nights, back.wanderer_rewarded], [4, 3, 4])


func test_a_broken_save_falls_back_to_nothing_found() -> void:
	for bad: Variant in [null, "junk", 5, [], {"found": "x", "explored": [[1], ["a", 2, 3], [1, 2, NAN]], "stars": [[1, 2]],
			"dusks": -3, "nights": "many", "opened": [1, 2]}]:
		var s := SecretState.from_save(bad)
		assert_eq(s.found.size() + s.opened.size() + s.explored.size() + s.stars.size(), 0, str(bad))
		assert_eq(s.dusks, 0)
		assert_eq(s.nights, 0)


func test_huge_lists_are_capped() -> void:
	var ids: Array = []
	for i in SecretState.MAX_IDS + 50:
		ids.append("treasure_%d_0_0" % i)
	var stars: Array = []
	for i in 30:
		stars.append([i, 40, 0])
	var s := SecretState.from_save({"found": ids, "stars": stars})
	assert_eq(s.found.size(), SecretState.MAX_IDS)
	assert_eq(s.stars.size(), SecretState.MAX_STARS)


func test_exploring_an_area_counts_once() -> void:
	var s := SecretState.new()
	assert_true(s.explore(Vector2i(0, 0), 3))
	assert_false(s.explore(Vector2i(0, 0), 3), "already explored")
	assert_true(s.explore(Vector2i(0, 1), 1))
	assert_eq(s.counts(), Vector2i(0, 4), "0 found of the 4 secrets in the areas explored")


## The Secret Book counts the secrets found in the explored areas (found / total).
func test_found_counts_only_secrets_of_explored_areas() -> void:
	var s := SecretState.new()
	s.explore(Vector2i(1, 2), 3)
	s.found["temple_1_2_3"] = true
	s.found["room_1_2_0"] = true
	s.found["treasure_9_9_0"] = true    # an area not explored (an old save): not counted
	assert_eq(s.counts(), Vector2i(2, 3))
