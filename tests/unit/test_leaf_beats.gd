extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.10, §4.6; future-lessons.md §3.5): the game never asks a
## question to check; it judges beats from what the leaf did. A silent blaze is passed when the leaf never droops and by
## its second half at most two of six doors are open; a silent cloud when at least 1.6 sugars are built in it and the
## doors are open at least 0.4 more than in the blaze before (the design's 2.0 put a child who knows the rule but reacts
## in 4.4 s on a phone at a knife edge: docs/devlog/parts/game-leaf-b.md); the desert's night when half the doors stay
## open, its dawn when all but two are shut by the end of it. The voiced turns teach and are not judged; help makes a beat HELPED;
## a transfer voyage's beats are NEW_SETTING; every beat is one SkillShown event for the voyage's unit.

const DT := 0.1
const UNIT := "g5.science.plants_air_water"


## Plays the voyage's script from `from` to `to` seconds: each step `policy` sets the leaf (doors, water, sugar) for
## the weather `w`, then the beats observe it. Returns the beats judged on the way.
func _play(beats: LeafBeats, weather: LeafWeather, sim: LeafSim, policy: Callable, from: float, to: float) -> Array:
	var judged := []
	for i in int(round((to - from) / DT)):
		var w := weather.at(from + i * DT)
		policy.call(w, sim)
		judged.append_array(beats.observe(w, sim, DT))
	return judged


func _sim(id: String) -> LeafSim:
	var sim := LeafSim.make(LeafVoyages.voyage(id).sim)
	sim.water = 0.8
	return sim


func _doors(sim: LeafSim, n: int) -> void:
	for i in sim.doors.size():
		sim.set_door(i, i < n)


## The rule, perfectly: open in the cloud (building 0.2 sugar a second), shut otherwise; the leaf stays at 0.8.
func _rule(w: Dictionary, sim: LeafSim) -> void:
	_doors(sim, 6 if bool(w.open) else 0)
	sim.water = 0.8
	if str(w.kind) == "cloud":
		sim.made += 0.2 * DT


func _by_id(results: Array) -> Dictionary:
	var out := {}
	for r: Dictionary in results:
		out[str(r.id)] = r
	return out


func test_the_voiced_turns_teach_and_only_the_silent_ones_are_judged() -> void:
	var weather := LeafWeather.for_voyage("5.1")
	var beats := LeafBeats.for_voyage("5.1", weather)
	var judged := _play(beats, weather, _sim("5.1"), _rule, 0.0, weather.total())
	judged.append_array(beats.finish())
	assert_eq(judged.map(func(r: Dictionary) -> String: return str(r.id)), ["C2", "Z2", "C3", "Z3", "C4", "Z4"],
		"the trap, the voiced first cloud and blaze, and the evening are not judged")
	for r: Dictionary in judged:
		assert_true(bool(r.passed), "%s: %s" % [r.id, r.note])
		assert_eq(str(r.kind), SkillShown.SOLVED)


func test_a_blaze_needs_shut_doors_in_its_second_half_and_a_leaf_that_never_droops() -> void:
	var cases := {
		"all shut": [0, 0.8, true],
		"two open in the second half": [2, 0.8, true],
		"three open in the second half": [3, 0.8, false],
		"drooped once": [0, 0.54, false],
	}
	for key: String in cases:
		var c: Array = cases[key]
		var weather := LeafWeather.for_voyage("5.1")
		var beats := LeafBeats.for_voyage("5.1", weather)
		var sim := _sim("5.1")
		var z2 := weather.index_of("blaze2")
		var start := weather.start_of(z2)
		_play(beats, weather, sim, _rule, 0.0, start)
		var late := func(w: Dictionary, s: LeafSim) -> void:
			var second_half := float(w.since) >= 0.5 * float(w.seconds)
			_doors(s, int(c[0]) if second_half else 6)
			s.water = 0.8
			if float(w.since) > 3.0 and float(w.since) < 3.2:
				s.water = float(c[1])   # a moment in the blaze
		var judged := _play(beats, weather, sim, late, start, start + 15.5)
		var z := _by_id(judged).get("Z2", {}) as Dictionary
		assert_false(z.is_empty(), "%s: Z2 judged when the blaze ends" % key)
		assert_eq(bool(z.get("passed", false)), bool(c[2]), "%s: %s" % [key, z.get("note", "")])


func test_a_cloud_needs_two_sugars_and_doors_open_more_than_in_the_blaze_before() -> void:
	var cases := {
		"open after a shut blaze, 2.2 sugars": [6, 0, 0.11, true],
		"1.7 sugars (a slow child who knows the rule)": [6, 0, 0.085, true],
		"1.5 sugars": [6, 0, 0.075, false],
		"open in the blaze too": [6, 6, 0.11, false],
		"4 open after 1 open (0.67 - 0.17 = 0.5)": [4, 1, 0.11, true],
		"3 open after 1 open (0.5 - 0.17 = 0.33)": [3, 1, 0.11, false],
	}
	for key: String in cases:
		var c: Array = cases[key]
		var weather := LeafWeather.for_voyage("5.1")
		var beats := LeafBeats.for_voyage("5.1", weather)
		var sim := _sim("5.1")
		var policy := func(w: Dictionary, s: LeafSim) -> void:
			s.water = 0.8
			if str(w.id) == "blaze1":
				_doors(s, int(c[1]))
			elif str(w.id) == "cloud2":
				_doors(s, int(c[0]))
				s.made += float(c[2]) * DT   # sugars a second
			else:
				_rule(w, s)
		var c2 := weather.index_of("cloud2")
		var judged := _play(beats, weather, sim, policy, 0.0, weather.start_of(c2) + 20.5)
		var r := _by_id(judged).get("C2", {}) as Dictionary
		assert_false(r.is_empty(), "%s: C2 judged" % key)
		assert_eq(bool(r.get("passed", false)), bool(c[3]), "%s: %s" % [key, r.get("note", "")])


func test_the_desert_judges_its_days_nights_and_dawns() -> void:
	var cases := {
		"the cool-night rule": [0, 3, 0, true, true, true],
		"two open at night": [0, 2, 0, true, false, true],
		"three still open when the dawn ends": [0, 6, 3, true, true, false],
		"open by day (the sunflower's habit)": [6, 0, 6, false, false, false],
	}
	for key: String in cases:
		var c: Array = cases[key]
		var weather := LeafWeather.for_voyage("5.T1")
		var beats := LeafBeats.for_voyage("5.T1", weather)
		var sim := _sim("5.T1")
		var policy := func(w: Dictionary, s: LeafSim) -> void:
			s.water = 0.8
			if bool(w.night):
				_doors(s, int(c[1]))
			elif float(w.since) < 8.0 and int(w.index) > 0:
				_doors(s, int(c[2]))   # the dawn
			else:
				_doors(s, int(c[0]))
		var judged := _play(beats, weather, sim, policy, 0.0, weather.total())
		judged.append_array(beats.finish())
		var r := _by_id(judged)
		assert_eq(r.keys(), ["Day1", "Night1", "Dawn1", "Day2", "Night2", "Dawn2"], key)
		assert_eq(bool(r.Day1.passed), bool(c[3]), "%s: Day1 %s" % [key, r.Day1.note])
		assert_eq(bool(r.Night1.passed), bool(c[4]), "%s: Night1 %s" % [key, r.Night1.note])
		assert_eq(bool(r.Dawn1.passed), bool(c[5]), "%s: Dawn1 %s" % [key, r.Dawn1.note])


func test_help_makes_a_beat_helped_and_a_shown_answer_shown() -> void:
	var weather := LeafWeather.for_voyage("5.1")
	var beats := LeafBeats.for_voyage("5.1", weather)
	var sim := _sim("5.1")
	var c3 := weather.index_of("cloud3")
	_play(beats, weather, sim, _rule, 0.0, weather.start_of(c3) + 5.0)
	beats.help("hint")   # Hoot says the cue in a silent cloud
	var z3 := weather.index_of("blaze3")
	_play(beats, weather, sim, _rule, weather.start_of(c3) + 5.0, weather.start_of(z3) + 3.0)
	beats.help("shown")   # the ghost shut the doors for the child
	var judged := _play(beats, weather, sim, _rule, weather.start_of(z3) + 3.0, weather.total())
	judged.append_array(beats.finish())
	var r := _by_id(beats.results)
	assert_true(bool(r.C3.passed), "the doors were right")
	assert_eq(str(r.C3.kind), SkillShown.HELPED, "after Hoot's hint it doesn't count")
	assert_eq(str(r.Z3.kind), SkillShown.SHOWN, "the ghost did it")
	assert_eq(str(r.C4.kind), SkillShown.SOLVED, "help belongs to the beat it was given in")


func test_a_missed_beat_does_not_count_and_says_what_was_missing() -> void:
	var weather := LeafWeather.for_voyage("5.1")
	var beats := LeafBeats.for_voyage("5.1", weather)
	var shut := func(w: Dictionary, s: LeafSim) -> void:
		_doors(s, 0)
		s.water = 0.8
	_play(beats, weather, _sim("5.1"), shut, 0.0, weather.total())
	beats.finish()
	var r := _by_id(beats.results)
	assert_false(bool(r.C2.passed), "always shut builds nothing in the cloud")
	assert_eq(str(r.C2.kind), SkillShown.HELPED, "a missed beat is not right the first time")
	assert_string_contains(str(r.C2.note), "sugar")
	assert_true(bool(r.Z2.passed), "but its blazes pass: 3 of 6, never a round")


func test_the_act_1_beat_is_solved_unless_the_ghost_had_to_help_again() -> void:
	var weather := LeafWeather.for_voyage("5.1")
	var beats := LeafBeats.for_voyage("5.1", weather)
	var b1 := beats.act1_done(false)
	assert_eq(str(b1.id), "B1")
	assert_eq(str(b1.kind), SkillShown.SOLVED, "copying the first door still counts (G0's ruling 34)")
	var again := LeafBeats.for_voyage("5.1", weather).act1_done(true)
	assert_eq(str(again.kind), SkillShown.HELPED)


func test_the_events_go_to_the_voyage_s_unit_a_round_or_more() -> void:
	var weather := LeafWeather.for_voyage("5.1")
	var beats := LeafBeats.for_voyage("5.1", weather)
	beats.act1_done(false)
	_play(beats, weather, _sim("5.1"), _rule, 0.0, weather.total())
	beats.finish()
	var shown := SkillShown.begin()
	beats.record(shown)
	assert_eq(shown.units(), [UNIT] as Array[String])
	assert_eq(shown.total(UNIT), 7, "B1 and the six silent beats: at least 7 events (§3.10)")
	assert_eq(shown.right_first(UNIT), 7)
	assert_true(MasteryRules.is_mastery(shown.right_first(UNIT), shown.total(UNIT)))
	for e: Dictionary in shown.events[UNIT]:   # the lead's ruling on finding 2: what the sunflower's beats show
		assert_string_contains(str(e.note), "the water-and-air balance")


func test_a_transfer_voyage_s_beats_are_new_setting_and_kept_apart() -> void:
	var weather := LeafWeather.for_voyage("5.T1")
	var beats := LeafBeats.for_voyage("5.T1", weather)
	var cool := func(w: Dictionary, s: LeafSim) -> void:
		_doors(s, 6 if bool(w.open) else 0)
		s.water = 0.8
	_play(beats, weather, _sim("5.T1"), cool, 0.0, weather.total())
	beats.finish()
	var shown := SkillShown.begin()
	beats.record(shown)
	assert_eq(shown.total(UNIT), 6, "a full round of six")
	assert_eq(shown.transfer(UNIT), 6, "every one solved somewhere new")
	for e: Dictionary in shown.events[UNIT]:
		assert_eq(str(e.kind), SkillShown.NEW_SETTING)
		assert_string_contains(str(e.note), "desert")
		assert_string_contains(str(e.note), "the weather idea", "the lead's ruling on finding 2: the desert shows it")


func test_the_extra_turns_are_judged_too_and_a_longer_window_says_so() -> void:
	var weather := LeafWeather.for_voyage("5.1")
	var beats := LeafBeats.for_voyage("5.1", weather)
	weather.lengthen(weather.index_of("cloud3"), 0.3)
	assert_true(weather.add_turn())
	_play(beats, weather, _sim("5.1"), _rule, 0.0, weather.total())
	beats.finish()
	var r := _by_id(beats.results)
	assert_eq(r.keys(), ["C2", "Z2", "C3", "Z3", "C4", "Z4", "C5", "Z5"], "more evidence, never less")
	assert_true(bool(r.C5.passed))
	assert_string_contains(str(r.C3.note), "long window")
