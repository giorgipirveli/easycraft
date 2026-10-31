extends GutTest
## A creature's small memory (M2 Task 18, spec §12.17): up to 8 players by name (like, fear, last
## seen) and up to 8 places (food, den, danger, favourite), forgetting over time.


func test_it_remembers_how_it_feels_about_players_by_name() -> void:
	var m := MindMemory.new()
	assert_false(m.knows("Tina"))
	assert_true(m.saw("Tina", 1.0), "a new face")
	assert_false(m.saw("Tina", 2.0), "not new any more")
	m.feel_about("Tina", 0.5, 0.0, 3.0)
	m.feel_about("Bob", 0.0, 0.8, 3.0)
	assert_almost_eq(m.like("Tina"), 0.5, 0.001)
	assert_almost_eq(m.fear("Bob"), 0.8, 0.001)
	assert_eq(m.like("Nobody"), 0.0)
	m.feel_about("Tina", 5.0, 0.0, 4.0)
	assert_eq(m.like("Tina"), 1.0, "capped at 1")
	m.feel_about("Bob", 0.0, -5.0, 4.0)
	assert_eq(m.fear("Bob"), 0.0, "never below 0")


func test_one_look_tells_everything_it_feels_about_a_player() -> void:
	var m := MindMemory.new()
	m.feel_about("Tina", 0.6, 0.2, 1.0)
	var e := m.entry("Tina")
	assert_almost_eq(float(e.like), 0.6, 0.001)
	assert_almost_eq(float(e.fear), 0.2, 0.001)
	assert_true(m.entry("Stranger").is_empty(), "a stranger")
	assert_eq(float(m.entry("Stranger").get("like", 0.0)), 0.0)


func test_it_knows_at_most_eight_players_and_forgets_the_least_important() -> void:
	var m := MindMemory.new()
	m.feel_about("Owner", 1.0, 0.0, 0.0)
	m.pin("Owner")
	m.feel_about("Friend", 0.9, 0.0, 1.0)
	for i in 20:
		m.saw("Stranger%d" % i, 10.0 + i)
	assert_eq(m.players.size(), MindMemory.MAX_PLAYERS)
	assert_true(m.knows("Owner"), "its owner is never forgotten")
	assert_true(m.knows("Friend"), "someone it likes stays longer than a passer-by")
	assert_true(m.knows("Stranger19"), "the newest face is there")
	assert_false(m.knows("Stranger0"), "old passers-by went first")


func test_fear_fades_quickly_and_liking_slowly() -> void:
	var m := MindMemory.new()
	m.feel_about("Hitter", 0.0, 1.0, 0.0)
	m.feel_about("Feeder", 1.0, 0.0, 0.0)
	for i in 120:
		m.forget(float(i + 1), 1.0)
	assert_lt(m.fear("Hitter"), 0.3, "after two minutes the fright is mostly gone")
	assert_gt(m.like("Feeder"), 0.7, "a kind player is remembered much longer")


func test_forgotten_strangers_leave_the_memory_but_an_owner_stays() -> void:
	var m := MindMemory.new()
	m.saw("Passer", 0.0)
	m.feel_about("Owner", 0.2, 0.0, 0.0)
	m.pin("Owner")
	for i in 900:
		m.forget(float(i + 1), 1.0)
	assert_false(m.knows("Passer"))
	assert_true(m.knows("Owner"))
	assert_gte(m.like("Owner"), MindMemory.OWNER_LIKE, "a pet always likes its owner")


func test_places_merge_nearby_and_keep_at_most_eight() -> void:
	var m := MindMemory.new()
	m.note_place(MindMemory.FOOD, Vector3(10, 5, 10), 1.0, 0.0)
	m.note_place(MindMemory.FOOD, Vector3(11, 5, 10), 1.0, 1.0)
	assert_eq(m.places.size(), 1, "two spots next to each other are one place")
	assert_almost_eq(m.place(MindMemory.FOOD).x, 10.5, 0.01)
	m.note_place(MindMemory.DANGER, Vector3(10, 5, 10), 1.0, 2.0)
	assert_eq(m.places.size(), 2, "a different kind of place is its own")
	for i in 20:
		m.note_place(MindMemory.FAVOURITE, Vector3(100 + i * 10, 5, 0), 0.1 + i * 0.01, 3.0 + i)
	assert_eq(m.places.size(), MindMemory.MAX_PLACES)
	assert_true(m.place(MindMemory.FOOD).is_finite(), "the important places stay")
	assert_false(m.place(&"nothing").is_finite())


func test_the_nearest_place_of_a_kind() -> void:
	var m := MindMemory.new()
	m.note_place(MindMemory.DEN, Vector3(0, 5, 0), 1.0, 0.0)
	m.note_place(MindMemory.DEN, Vector3(40, 5, 0), 1.0, 0.0)
	assert_eq(m.place(MindMemory.DEN, Vector3(35, 5, 0)), Vector3(40, 5, 0))
	assert_eq(m.place(MindMemory.DEN, Vector3(3, 5, 0)), Vector3(0, 5, 0))


func test_places_fade_when_not_visited() -> void:
	var m := MindMemory.new()
	m.note_place(MindMemory.DANGER, Vector3(0, 5, 0), 1.0, 0.0)
	for i in 3600:
		m.forget(float(i + 1), 1.0)
	assert_false(m.place(MindMemory.DANGER).is_finite(), "an old fright is forgotten")


func test_save_round_trip_and_bad_saves() -> void:
	var m := MindMemory.new()
	m.feel_about("Tina", 0.9, 0.0, 1.0)
	m.pin("Tina")
	m.feel_about("Bob", 0.0, 0.5, 1.0)
	m.note_place(MindMemory.DEN, Vector3(1.5, 12, -3.3), 1.0, 1.0)
	var back := MindMemory.from_save(JSON.parse_string(JSON.stringify(m.to_save())))
	assert_almost_eq(back.like("Tina"), 0.9, 0.01)
	assert_almost_eq(back.fear("Bob"), 0.5, 0.01)
	assert_almost_eq(back.place(MindMemory.DEN), Vector3(1.5, 12, -3.3), Vector3.ONE * 0.01)
	for i in 30:
		back.forget(1000.0 + i * 100.0, 100.0)
	assert_true(back.knows("Tina"), "still pinned after loading")
	for bad: Variant in [null, 3, "x", {"p": "no"}, {"p": [["", 1, 0, 0], [5, "a"], ["Ok", NAN, 2, 0]]},
			{"l": [["den", 1, 2], ["weird", 1, 2, 3, 1], ["den", NAN, 0, 0, 1]]}]:
		var mem := MindMemory.from_save(bad)
		assert_lte(mem.players.size(), 1)
		assert_eq(mem.places.size(), 0, "broken places are dropped: %s" % [bad])
	var long := MindMemory.new()
	for i in 12:
		long.feel_about("Player_with_a_long_name_%d" % i, 0.5, 0.5, float(i))
		long.note_place(MindMemory.FOOD, Vector3(i * 10, 0, 0), 1.0, float(i))
	assert_lte(JSON.stringify(long.to_save()).length(), 1200, "a full memory saves small")
