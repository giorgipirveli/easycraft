extends GutTest
## Buddy playdates (M4 Wave 3, agent I; research T4, spec §3a "Buddies meet friends' buddies"): when
## friends play together, their buddies notice each other within 16 blocks, wave, walk to each other, do
## a little dance together, one follows the other a little, then both go back to their owners and rest a
## minute. The host decides (at most 10 steps a second); a buddy never meets one of its own owner's.

var rules: PlaydateRules


func before_each() -> void:
	rules = PlaydateRules.new()


func _b(buddy_name: String, owner: int, pos: Vector3) -> Dictionary:
	return {"name": buddy_name, "owner": owner, "pos": pos}


## Steps the rules from t0 to t1 at 10 Hz with the buddies moving as `move` says; every event seen.
func _run(buddies: Array, t0: float, t1: float, move: Callable = Callable()) -> Array:
	var events: Array = []
	var t := t0
	while t <= t1 + 0.0001:
		var r := rules.step(buddies, t)
		events.append_array(r.events)
		if move.is_valid():
			move.call(buddies, r.targets)
		t += PlaydateRules.TICK
	return events


## Moves each buddy 0.5 m a tick towards its target (a buddy walks about 5 m/s).
func _walk(buddies: Array, targets: Dictionary) -> void:
	for b: Dictionary in buddies:
		if targets.has(b.name):
			b.pos = (b.pos as Vector3).move_toward(targets[b.name], 0.5)


func test_two_friends_buddies_meet_wave_dance_follow_and_rest() -> void:
	var buddies := [_b("Blocky", 1, Vector3(0, 10, 0)), _b("Sparkle", 2, Vector3(12, 10, 0))]
	var first := rules.step(buddies, 0.0)
	assert_eq(first.events, [["wave", "Blocky", "Sparkle"]], "they notice each other and wave")
	assert_eq(rules.phase_of("Blocky"), PlaydateRules.WAVE)
	var events := _run(buddies, 0.1, 30.0, _walk)
	assert_true(events.has(["dance", "Blocky", "Sparkle"]), str(events))
	assert_lte((buddies[0].pos as Vector3).distance_to(buddies[1].pos), PlaydateRules.MEET_GAP + 0.6, "they met")
	assert_eq(rules.phase_of("Blocky"), &"", "back to their owners")
	assert_eq(rules.step(buddies, 31.0).events, [], "resting: no second playdate at once")
	assert_eq(rules.step(buddies, 31.0 + PlaydateRules.REST).events, [["wave", "Blocky", "Sparkle"]], "a minute later, again")


func test_the_phases_in_order_with_their_targets() -> void:
	var buddies := [_b("A1", 1, Vector3(0, 0, 0)), _b("B1", 2, Vector3(6, 0, 0))]
	var r := rules.step(buddies, 0.0)
	assert_eq(r.targets.get("A1"), Vector3(0, 0, 0), "while waving they stand")
	r = rules.step(buddies, PlaydateRules.WAVE_TIME)
	assert_eq(rules.phase_of("A1"), PlaydateRules.MEET)
	assert_eq(r.targets.get("A1"), Vector3(3, 0, 0), "they walk to the middle")
	assert_eq(r.targets.get("B1"), Vector3(3, 0, 0))
	# They never arrive (a wall): the dance starts anyway after MEET_TIME.
	r = rules.step(buddies, PlaydateRules.WAVE_TIME + PlaydateRules.MEET_TIME)
	assert_eq(rules.phase_of("A1"), PlaydateRules.DANCE)
	assert_eq(r.events, [["dance", "A1", "B1"]])
	r = rules.step(buddies, PlaydateRules.WAVE_TIME + PlaydateRules.MEET_TIME + PlaydateRules.DANCE_TIME)
	assert_eq(rules.phase_of("A1"), PlaydateRules.FOLLOW)
	assert_eq(r.targets.get("A1"), Vector3(6, 0, 0), "one follows the other")
	assert_false(r.targets.has("B1"), "the other goes back to its owner")


func test_buddies_of_one_owner_never_play_and_far_ones_do_not_notice() -> void:
	var same := [_b("A1", 1, Vector3(0, 0, 0)), _b("A2", 1, Vector3(2, 0, 0))]
	assert_eq(rules.step(same, 0.0).events, [])
	var far := [_b("A1", 1, Vector3(0, 0, 0)), _b("B1", 2, Vector3(16.5, 0, 0))]
	assert_eq(rules.step(far, 0.0).events, [])


func test_each_buddy_plays_with_one_friend_at_a_time_nearest_first() -> void:
	var buddies := [_b("A1", 1, Vector3(0, 0, 0)), _b("B1", 2, Vector3(9, 0, 0)), _b("C1", 3, Vector3(3, 0, 0)),
		_b("D1", 4, Vector3(10, 0, 0))]
	var r := rules.step(buddies, 0.0)
	assert_eq(r.events.size(), 2, str(r.events))
	assert_true(r.events.has(["wave", "A1", "C1"]), "A1's nearest friend")
	assert_true(r.events.has(["wave", "B1", "D1"]))


func test_a_buddy_that_goes_away_ends_its_playdate() -> void:
	var buddies := [_b("A1", 1, Vector3(0, 0, 0)), _b("B1", 2, Vector3(5, 0, 0))]
	rules.step(buddies, 0.0)
	buddies.pop_back()   # woken back into blocks, or its owner left
	var r := rules.step(buddies, 0.1)
	assert_eq(rules.phase_of("A1"), &"")
	assert_false(r.targets.has("A1"))
	var again := [_b("A1", 1, Vector3(0, 0, 0)), _b("B1", 2, Vector3(40, 0, 0))]
	rules.step(again, 0.2)
	assert_eq(rules.phase_of("A1"), &"", "too far: no playdate")
