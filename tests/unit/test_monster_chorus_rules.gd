extends GutTest
## M5 Task 2 (spec §15.2; the M5 plan's note after owner #50): the monsters' idle voices heard on one device share
## one budget, like #50's animal chorus. Before, every monster rolled its own 6-14 s timer: a night of 20 goblins
## round a child was about 120 grunts a minute. MonsterChorusRules: at most one idle voice every GAP_MIN..GAP_MAX
## seconds, a kind rests KIND_REST after it spoke, the nearest first, farther ones rarer and quieter, nothing
## beyond RADIUS; a cry or a growl (a child's fight, never held back) keeps it quiet a moment.

const DT := 0.1


func _crowd(kinds: Array, count: int, rng: RandomNumberGenerator) -> Array:
	var out := []
	for i in count:
		out.append({"kind": kinds[i % kinds.size()], "dist": rng.randf_range(2.0, 18.0)})
	return out


## [time, kind, dist] of every voice in `seconds`.
func _run(candidates: Array, seconds: float, seed_value: int) -> Array:
	var rules := MonsterChorusRules.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := []
	var t := 0.0
	while t < seconds:
		var i := rules.next_call(t, candidates, rng)
		if i >= 0:
			out.append([t, candidates[i].kind, float(candidates[i].dist)])
		t += DT
	return out


func test_a_night_of_twenty_goblins_is_a_few_voices_a_minute() -> void:
	for s in 5:
		var rng := RandomNumberGenerator.new()
		rng.seed = 40 + s
		var calls := _run(_crowd([MonsterRules.GOBLIN], 20, rng), 600.0, s)
		var per_minute := calls.size() / 10.0
		assert_between(per_minute, 2.0, 6.0, "seed %d: %.1f grunts a minute (was ~120)" % [s, per_minute])


func test_one_budget_and_a_kind_rests_after_it_spoke() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var calls := _run(_crowd([MonsterRules.GOBLIN, MonsterRules.SLIME, MonsterRules.MUMMY], 24, rng), 600.0, 3)
	var last := {}
	for i in calls.size():
		if i > 0:
			assert_gte(calls[i][0] - calls[i - 1][0], MonsterChorusRules.GAP_MIN - 0.001, "one budget")
		if last.has(calls[i][1]):
			assert_gte(calls[i][0] - last[calls[i][1]], MonsterChorusRules.KIND_REST - 0.001, "%s rests" % calls[i][1])
		last[calls[i][1]] = calls[i][0]
	assert_eq(last.size(), 3, "every kind is heard")
	assert_lte(calls.size() / 10.0, 12.0, "three kinds: still calm")


func test_the_nearest_speaks_first() -> void:
	var rules := MonsterChorusRules.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var near := 0
	for i in 200:
		var pick := rules.choose([{"kind": MonsterRules.GOBLIN, "dist": 16.0}, {"kind": MonsterRules.GOBLIN, "dist": 3.0}], 0.0, rng)
		near += int(pick == 1)
	assert_gt(near, 150, "the goblin next to you grunts most")


func test_farther_ones_are_quieter_and_rarer_and_nothing_beyond_the_radius() -> void:
	assert_eq(MonsterChorusRules.call_chance(3.0), 1.0)
	assert_lt(MonsterChorusRules.call_chance(MonsterChorusRules.RADIUS), 0.6)
	assert_eq(MonsterChorusRules.call_chance(MonsterChorusRules.RADIUS + 0.5), 0.0)
	assert_lt(MonsterChorusRules.volume_db(MonsterRules.GOBLIN, 18.0), MonsterChorusRules.volume_db(MonsterRules.GOBLIN, 3.0))
	assert_eq(_run([{"kind": MonsterRules.GOBLIN, "dist": MonsterChorusRules.RADIUS + 1.0}], 120.0, 5).size(), 0)
	assert_eq(MonsterChorusRules.RADIUS, Monster.SOUND_DISTANCE, "as far as a monster was ever heard")


func test_a_cry_or_a_growl_keeps_it_quiet_and_lets_that_kind_rest() -> void:
	var rules := MonsterChorusRules.new()
	var rng := RandomNumberGenerator.new()
	var goblins := [{"kind": MonsterRules.GOBLIN, "dist": 4.0}]
	rules.heard(MonsterRules.GOBLIN, 10.0)
	assert_eq(rules.next_call(10.5, goblins, rng), -1, "just heard: quiet")
	assert_eq(rules.last_heard(MonsterRules.GOBLIN), 10.0)
	assert_gte(rules.next_time(), 10.0 + MonsterChorusRules.AFTER_VOICE)
	var slimes := goblins + [{"kind": MonsterRules.SLIME, "dist": 5.0}]
	var t := rules.next_time()
	assert_eq(rules.next_call(t, slimes, rng), 1, "the goblins rest: the slime's turn")


func test_monsters_never_voice_on_their_own_any_more() -> void:
	var src := FileAccess.get_file_as_string("res://entities/monsters/monster.gd")
	assert_false(src.contains("func voice_tick"), "every idle voice goes through the chorus")
	assert_false(src.contains("monster_wait"))
