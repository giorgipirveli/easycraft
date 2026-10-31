extends GutTest
## Owner feedback #50 ("please improve sounds, now there is a lot chicken sounds only everywhere"): the
## animals' idle calls heard on one device share one budget (at most one call every 6-10 s), a kind rests
## after it called (so one kind never dominates) and kinds not heard lately come first, the nearest animals
## call first (farther ones quieter and rarer), a kind's takes never repeat back to back, and the loudest
## recordings (the chickens) are evened out with the others. A child's own animal voice (hurt, happy) is
## never blocked; it only makes the chorus wait a moment.

const KINDS: Array[StringName] = [&"chicken", &"cow", &"sheep", &"pig", &"dog", &"cat"]


## 20 chickens from 2 to 18 blocks away, and a cow, a sheep, a pig, a dog and a cat.
func _crowd() -> Array:
	var c := []
	for i in 20:
		c.append({"kind": &"chicken", "dist": 2.0 + i * 0.8})
	for pair in [[&"cow", 5.0], [&"sheep", 8.0], [&"pig", 11.0], [&"dog", 14.0], [&"cat", 17.0]]:
		c.append({"kind": pair[0], "dist": pair[1]})
	return c


## `seconds` of a chorus over `cands` in steps of `step`: every call as [time, kind, dist].
func _run(rules: AnimalChorusRules, cands: Array, seconds: float, seed: int = 1, step: float = 0.1, from: float = 0.0) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out := []
	var t := from
	while t < from + seconds:
		var i := rules.next_call(t, cands, rng)
		if i >= 0:
			out.append([t, cands[i].kind, cands[i].dist])
		t += step
	return out


func test_one_budget_at_most_one_call_every_six_to_ten_seconds() -> void:
	for seed in 5:
		var calls := _run(AnimalChorusRules.new(), _crowd(), 600.0, seed)
		for i in range(1, calls.size()):
			assert_gte(calls[i][0] - calls[i - 1][0], AnimalChorusRules.GAP_MIN - 0.001, "gap before call %d" % i)
		var per_min := calls.size() / 10.0
		assert_between(per_min, 4.0, 60.0 / AnimalChorusRules.GAP_MIN, "calls a minute: %.1f (seed %d)" % [per_min, seed])
	assert_between(AnimalChorusRules.GAP_MIN, 6.0, AnimalChorusRules.GAP_MAX)
	assert_lte(AnimalChorusRules.GAP_MAX, 10.0)


func test_a_kind_rests_after_it_called_so_one_kind_never_dominates() -> void:
	var calls := _run(AnimalChorusRules.new(), _crowd(), 600.0, 2)
	var last := {}
	var count := {}
	for i in calls.size():
		var kind: StringName = calls[i][1]
		if last.has(kind):
			assert_gte(calls[i][0] - float(last[kind]), AnimalChorusRules.KIND_REST - 0.001, "%s rested" % kind)
		if i > 0:
			assert_ne(kind, calls[i - 1][1], "never the same kind twice in a row (call %d)" % i)
		last[kind] = calls[i][0]
		count[kind] = int(count.get(kind, 0)) + 1
	var share := float(count.get(&"chicken", 0)) / calls.size()
	assert_lte(share, 0.3, "20 of 25 animals are chickens, yet chickens are %.0f%% of the calls" % (share * 100.0))
	for kind in KINDS:
		assert_true(count.has(kind), "the %s is heard too (%s)" % [kind, count])


func test_a_lone_flock_is_calm() -> void:
	var hens := []
	for i in 20:
		hens.append({"kind": &"chicken", "dist": 2.0 + i * 0.8})
	var calls := _run(AnimalChorusRules.new(), hens, 600.0, 3)
	assert_lte(calls.size() / 10.0, 60.0 / AnimalChorusRules.KIND_REST + 0.2, "20 chickens alone: %d calls in 10 min" % calls.size())
	assert_gte(calls.size(), 15, "but they are still heard now and then")


func test_kinds_not_heard_lately_come_first() -> void:
	var rules := AnimalChorusRules.new()
	var rng := RandomNumberGenerator.new()
	rules.heard(&"sheep", 0.0)
	rules.heard(&"chicken", 20.0)
	var cands := [{"kind": &"chicken", "dist": 3.0}, {"kind": &"sheep", "dist": 4.0}, {"kind": &"cow", "dist": 12.0}]
	assert_eq(cands[rules.choose(cands, 30.0, rng)].kind, &"cow", "never heard beats the sheep heard 30 s ago")
	rules.heard(&"cow", 30.0)
	assert_eq(cands[rules.choose(cands, 31.0, rng)].kind, &"sheep", "the chickens still rest, the cow just called")
	assert_eq(rules.choose([{"kind": &"chicken", "dist": 3.0}], 31.0, rng), -1, "a resting kind stays quiet")


func test_the_nearest_animals_call_first() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var rules := AnimalChorusRules.new()
	var two := [{"kind": &"chicken", "dist": 18.0}, {"kind": &"chicken", "dist": 3.0}]
	var near := 0
	for i in 400:
		near += int(rules.choose(two, 100.0, rng) == 1)
	assert_gt(near, 320, "the chicken 3 blocks away calls most (%d of 400)" % near)
	var kinds := [{"kind": &"sheep", "dist": 19.0}, {"kind": &"cow", "dist": 4.0}]
	assert_eq(kinds[rules.choose(kinds, 100.0, rng)].kind, &"cow", "both new: the near kind first")


func test_farther_ones_are_quieter_and_rarer() -> void:
	assert_eq(AnimalChorusRules.call_chance(2.0), 1.0)
	assert_eq(AnimalChorusRules.call_chance(AnimalChorusRules.NEAR), 1.0)
	assert_almost_eq(AnimalChorusRules.call_chance(AnimalChorusRules.RADIUS), AnimalChorusRules.FAR_CHANCE, 0.001)
	assert_eq(AnimalChorusRules.call_chance(AnimalChorusRules.RADIUS + 1.0), 0.0, "beyond 20 blocks: never")
	var prev := 2.0
	var prev_db := 99.0
	for d in range(2, 21):
		assert_lte(AnimalChorusRules.call_chance(d), prev)
		prev = AnimalChorusRules.call_chance(d)
		assert_lte(AnimalChorusRules.volume_db(&"sheep", d), prev_db)
		prev_db = AnimalChorusRules.volume_db(&"sheep", d)
	assert_gte(AnimalChorusRules.volume_db(&"sheep", 3.0) - AnimalChorusRules.volume_db(&"sheep", 20.0), 5.0,
		"a far sheep is quieter on top of the distance fall-off")
	var near := _run(AnimalChorusRules.new(), [{"kind": &"sheep", "dist": 4.0}], 600.0, 5).size()
	var far := _run(AnimalChorusRules.new(), [{"kind": &"sheep", "dist": 19.0}], 600.0, 5).size()
	assert_lt(far, near * 0.8, "a far sheep calls less often (%d vs %d near)" % [far, near])


func test_beyond_twenty_blocks_nothing_is_heard() -> void:
	assert_eq(AnimalChorusRules.RADIUS, VoiceRules.CALL_RADIUS)
	var far := []
	for i in 10:
		far.append({"kind": &"cow", "dist": 20.5 + i})
	assert_eq(_run(AnimalChorusRules.new(), far, 600.0).size(), 0)


func test_nobody_near_then_a_call_comes_soon() -> void:
	var rules := AnimalChorusRules.new()
	var rng := RandomNumberGenerator.new()
	assert_eq(rules.next_call(0.0, [], rng), -1)
	var calls := _run(rules, [{"kind": &"dog", "dist": 3.0}], 5.0, 1, 0.1, 0.1)
	assert_false(calls.is_empty(), "a dog walks up: heard within a second or so")
	assert_lte(calls[0][0], AnimalChorusRules.RETRY + 0.2)


func test_a_childs_own_animal_voice_makes_the_chorus_wait() -> void:
	var rules := AnimalChorusRules.new()
	var rng := RandomNumberGenerator.new()
	rules.heard(&"chicken", 10.0)   # a petted chicken clucked (never blocked; Animal.cheer plays it)
	assert_eq(rules.next_call(10.0 + AnimalChorusRules.AFTER_VOICE - 0.1, _crowd(), rng), -1, "a moment of quiet after it")
	var calls := _run(rules, _crowd(), 30.0, 1, 0.1, 10.0 + AnimalChorusRules.AFTER_VOICE)
	assert_false(calls.is_empty())
	for c in calls:
		if c[1] == &"chicken":
			assert_gte(c[0] - 10.0, AnimalChorusRules.KIND_REST - 0.001, "the chickens rest after their own voice")


func test_the_loudest_recordings_are_evened_out() -> void:
	# Measured (EBU R128, through a phone speaker's 500 Hz high-pass): chickens -12 LUFS, rabbits -15, sheep
	# -17, cats -17, dogs -19, pigs -22, cows -26 (docs/devlog/parts/owner-50-sounds.md).
	assert_lte(VoiceRules.call_gain_db(&"chicken"), -4.0, "the chickens were the loudest")
	assert_gte(VoiceRules.call_gain_db(&"cow") - VoiceRules.call_gain_db(&"chicken"), 6.0)
	for species: StringName in AnimalRules.SPECIES:
		assert_between(VoiceRules.call_gain_db(species), -8.0, 3.0, String(species))
	assert_eq(VoiceRules.call_gain_db(&"no_such_kind"), 0.0, "a kind without a measured level is left as it is")
	assert_lt(AnimalChorusRules.volume_db(&"chicken", 5.0), AnimalChorusRules.volume_db(&"cow", 5.0))


func test_the_same_take_never_plays_twice_in_a_row() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	for count in range(2, 6):
		var last := -1
		var seen := {}
		for i in 300:
			var take := AnimalChorusRules.take(count, last, rng)
			assert_between(take, 0, count - 1)
			assert_ne(take, last, "take %d of %d twice in a row" % [take, count])
			seen[take] = true
			last = take
		assert_eq(seen.size(), count, "every take is used")
	assert_eq(AnimalChorusRules.take(1, 0, rng), 0, "one take: always it")
	assert_eq(AnimalChorusRules.take(0, -1, rng), 0)
