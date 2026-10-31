extends GutTest
## Owner #132 (W1), stage 2, with #133 and #134: what a discovery crystal plays. Only real play that needs no reading:
## MAKE (gems of the right values collected until the crystal shows the number: place value, coins, decimals, integers)
## and ORDER (number gems taken smallest first: big numbers, fractions, decimals, negatives, rationals, irrationals).
## From the child's own learning: a review due first, else the next unit of the grade; when that unit has no such play
## yet, a real-play challenge from the child's grade instead, and the unit is recorded (its "play debt"). Never a
## written question; nothing on screen but numbers and signs.

const DAY := 20380
## Nothing plays in Play G0's place: the crystal's own number play (MAKE, ORDER) is what these tests look at.
var NONE := func(_id: String) -> bool: return false


func test_play_g0s_place_comes_first() -> void:
	var p := _profile(4)
	var pick := DiscoveryPlays.pick(p, DAY, 5)
	assert_true(pick.place, "G0's short round")
	assert_true(DiscoveryPlays.g0_plays(str(pick.unit)), "a unit that plays without reading")
	assert_eq(pick.wanted, "g4.maths.big_numbers", "the child's next unit")
	assert_eq(pick.own, pick.unit == pick.wanted)


func test_an_academy_door_plays_its_subjects_unit() -> void:
	var p := _profile(4)
	var unit := DiscoveryPlays.subject_unit(p, "maths", DAY)
	assert_true(unit.begins_with("g4.maths."))
	assert_true(DiscoveryPlays.g0_plays(unit))
	p.school.set_progress(unit, {"s": 2, "d": DAY + 30, "m": DAY - 1})
	assert_ne(DiscoveryPlays.subject_unit(p, "maths", DAY), unit, "the next one not mastered")
	assert_eq(DiscoveryPlays.subject_unit(p, "history", DAY, NONE), "", "nothing plays: coming soon")


func _profile(grade: int) -> ProfileData:
	var p := ProfileData.new()
	p.school.grade = grade
	return p


func test_every_play_a_unit_names_exists_and_every_grade_has_plays() -> void:
	for unit: String in DiscoveryPlays.UNIT_PLAYS:
		assert_false(Curriculum.unit(unit).is_empty(), "a real unit: %s" % unit)
		for kind: String in DiscoveryPlays.UNIT_PLAYS[unit]:
			assert_true(DiscoveryPlays.SETS.has(kind), "%s plays %s" % [unit, kind])
	for g in SchoolData.GRADES:
		assert_false(DiscoveryPlays.grade_units(g).is_empty(), "grade %d has a unit a crystal can play" % g)


func test_every_set_makes_three_challenges_with_only_numbers_and_signs() -> void:
	for kind: String in DiscoveryPlays.SETS:
		for s in 20:
			var cs := DiscoveryPlays.challenges(kind, 1000 + s)
			assert_eq(cs.size(), DiscoveryPlays.PER_CRYSTAL, kind)
			for c: Dictionary in cs:
				assert_eq(DiscoveryRules.word_count(str(c.shown)), 0, "%s shows %s: no word to read" % [kind, c.shown])
				for l: String in c.get("labels", []):
					assert_eq(DiscoveryRules.word_count(l), 0, "%s's gem %s" % [kind, l])
				assert_lte(DiscoveryRules.word_count(str(c.say)), 8, "a short spoken line: %s" % c.say)


func test_make_targets_can_be_made_with_the_gems_and_are_not_made_yet() -> void:
	for kind: String in DiscoveryPlays.SETS:
		if DiscoveryPlays.SETS[kind].kind != "make":
			continue
		for s in 30:
			for c: Dictionary in DiscoveryPlays.challenges(kind, s):
				assert_ne(int(c.start), int(c.target), "%s: something to make" % kind)
				var g := DiscoveryChallenge.new([c])
				var guard := 0
				while g.state() != DiscoveryChallenge.DONE and guard < 80:
					var hint := g.hint()
					assert_ne(hint, -1, "%s: always a gem that helps (%s)" % [kind, c.shown])
					g.take(hint)
					guard += 1
				assert_eq(g.state(), DiscoveryChallenge.DONE, "%s %s made by following the hints" % [kind, c.shown])
				assert_lte(guard, 30, "%s: at most a handful of gems" % kind)


func test_order_values_are_all_different() -> void:
	for kind: String in DiscoveryPlays.SETS:
		if DiscoveryPlays.SETS[kind].kind != "order":
			continue
		for s in 30:
			for c: Dictionary in DiscoveryPlays.challenges(kind, s):
				var seen := {}
				for v: float in c.values:
					assert_false(seen.has(snappedf(v, 0.0001)), "%s: %s twice" % [kind, c.labels])
					seen[snappedf(v, 0.0001)] = true
				assert_eq((c.values as Array).size(), (c.labels as Array).size())


func test_the_same_seed_gives_the_same_challenges() -> void:
	assert_eq(DiscoveryPlays.challenges("place_4digit", 77), DiscoveryPlays.challenges("place_4digit", 77))
	assert_ne(DiscoveryPlays.challenges("place_4digit", 77), DiscoveryPlays.challenges("place_4digit", 78))


func test_a_review_due_with_play_comes_first() -> void:
	var p := _profile(4)
	p.school.set_progress("g4.maths.compare_round", {"s": 2, "d": DAY - 1, "m": DAY - 5})
	var pick := DiscoveryPlays.pick(p, DAY, 5, NONE)
	assert_eq(pick.unit, "g4.maths.compare_round")
	assert_true(pick.own, "its own play")
	assert_eq(pick.kind, "order_big")


func test_the_next_unit_with_play() -> void:
	var p := _profile(4)   # nothing done: the next unit is grade 4's first, Big numbers, which has play
	var pick := DiscoveryPlays.pick(p, DAY, 5, NONE)
	assert_eq(pick.unit, "g4.maths.big_numbers")
	assert_true(pick.own)
	assert_eq(pick.wanted, "g4.maths.big_numbers")


func test_a_unit_without_play_gets_a_grade_challenge_and_is_recorded() -> void:
	var p := _profile(4)
	for id: String in ["g4.maths.big_numbers", "g4.maths.compare_round"]:
		p.school.set_progress(id, {"s": 2, "d": DAY + 10, "m": DAY - 3})
	var pick := DiscoveryPlays.pick(p, DAY, 5, NONE)
	assert_eq(pick.wanted, "g4.maths.add_subtract", "the next unit: no play for it yet")
	assert_false(pick.own)
	assert_true(DiscoveryPlays.grade_units(4).has(str(pick.unit)), "a real-play challenge from the child's grade")
	assert_true(DiscoveryPlays.SETS.has(str(pick.kind)))


func test_a_due_review_without_play_also_gets_a_grade_challenge() -> void:
	var p := _profile(3)
	p.school.set_progress("g3.maths.time", {"s": 2, "d": DAY - 2, "m": DAY - 9})
	var pick := DiscoveryPlays.pick(p, DAY, 5, NONE)
	assert_eq(pick.wanted, "g3.maths.time")
	assert_false(pick.own)


func test_no_grade_chosen_plays_the_first_grade() -> void:
	var pick := DiscoveryPlays.pick(_profile(0), DAY, 5, NONE)
	assert_true(DiscoveryPlays.grade_units(SchoolData.GRADES[0]).has(str(pick.unit)))


func test_every_grade_gets_a_pick() -> void:
	for g in SchoolData.GRADES:
		var pick := DiscoveryPlays.pick(_profile(g), DAY, g, NONE)
		assert_true(DiscoveryPlays.SETS.has(str(pick.kind)), "grade %d" % g)
		assert_eq((pick.challenges as Array).size(), DiscoveryPlays.PER_CRYSTAL)


# --- DiscoveryChallenge: the play itself ------------------------------------------------------------------------------

func _make(start: int, target: int, gems: Array, signed := false) -> DiscoveryChallenge:
	return DiscoveryChallenge.new([{"kind": "make", "start": start, "target": target, "gems": gems, "signed": signed, "scale": 1,
		"shown": str(target), "say": "Make %d!" % target, "labels": gems.map(func(v: int) -> String: return str(v))}])


func test_make_counts_the_gems_taken() -> void:
	var g := _make(0, 47, [10, 1])
	assert_eq(g.take(0), DiscoveryChallenge.TAKEN)
	assert_eq(g.total, 10)
	for i in 3:
		g.take(0)
	for i in 6:
		assert_eq(g.take(1), DiscoveryChallenge.TAKEN)
	assert_eq(g.take(1), DiscoveryChallenge.MADE)
	assert_eq(g.state(), DiscoveryChallenge.DONE)
	assert_eq(g.first_try, 1, "no miss: right the first time")


func test_a_gem_past_the_number_bounces_off() -> void:
	var g := _make(0, 7, [5, 1])
	g.take(0)
	assert_eq(g.take(0), DiscoveryChallenge.BOUNCED, "10 is past 7")
	assert_eq(g.total, 5, "the number stays")
	assert_eq(g.misses, 1)
	g.take(1)
	assert_eq(g.take(1), DiscoveryChallenge.MADE)
	assert_eq(g.first_try, 0)


func test_with_negatives_a_gem_that_takes_you_farther_bounces() -> void:
	var g := _make(8, -5, [10, 1, -1, -10], true)
	assert_eq(g.take(0), DiscoveryChallenge.BOUNCED, "+10 goes the wrong way")
	assert_eq(g.take(3), DiscoveryChallenge.TAKEN, "-10: 8 to -2, closer")
	assert_eq(g.total, -2)
	assert_eq(g.take(3), DiscoveryChallenge.BOUNCED, "-12 is farther than -2")
	for i in 2:
		g.take(2)
	assert_eq(g.take(2), DiscoveryChallenge.MADE)


func test_after_two_misses_the_helpful_gem_is_shown() -> void:
	var g := _make(0, 7, [5, 1])
	assert_eq(g.shown_hint(), -1, "no help before the child tries")
	g.take(0)
	g.take(0)
	g.take(0)
	assert_eq(g.misses, 2)
	assert_eq(g.shown_hint(), 1, "the 1-gem now")


func test_order_takes_the_smallest_first() -> void:
	var g := DiscoveryChallenge.new([{"kind": "order", "values": [3.0, -7.0, 0.0, 12.0], "labels": ["3", "−7", "0", "12"],
		"shown": "", "say": "Smallest first!"}])
	assert_eq(g.take(0), DiscoveryChallenge.BOUNCED, "3 is not the smallest")
	assert_eq(g.take(1), DiscoveryChallenge.TAKEN)
	assert_eq(g.take(2), DiscoveryChallenge.TAKEN)
	assert_eq(g.take(1), DiscoveryChallenge.BOUNCED, "taken already")
	assert_eq(g.take(0), DiscoveryChallenge.TAKEN)
	assert_eq(g.take(3), DiscoveryChallenge.MADE)
	assert_eq(g.misses, 2)


func test_a_crystal_is_three_challenges_then_finished() -> void:
	var cs := DiscoveryPlays.challenges("coins", 3)
	var g := DiscoveryChallenge.new(cs)
	for n in cs.size():
		while g.state() != DiscoveryChallenge.DONE:
			g.take(g.hint())
		assert_eq(g.next(), n < cs.size() - 1, "another challenge, or the end")
	assert_true(g.finished())
	assert_eq(g.first_try, cs.size(), "every one right the first time by the hints")
