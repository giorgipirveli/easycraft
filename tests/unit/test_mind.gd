extends GutTest
## Mind (M2 Task 18, owner feedback #24, spec §12.17): senses and drives → the species' tiny net →
## scores tilted by a per-individual personality → a gentle pick; rewards teach the last layer; the
## animals' table makes a fresh creature act sensibly; small saves; and it is light (budget).



func _calm_senses(m: Mind) -> void:
	m.senses.fill(0.0)
	m.senses[Mind.S_HEALTH] = 1.0
	m.senses[Mind.S_OUTCOME] = 0.5


func _mind(id := "a1_1_0", species: StringName = &"sheep") -> Mind:
	return Mind.create(AnimalSpecies.table(species), id)


func _pick_counts(m: Mind, n: int, allowed := -1) -> Dictionary:
	var counts := {}
	for i in n:
		m.interrupt()
		var a := m.think(allowed)
		counts[a] = int(counts.get(a, 0)) + 1
	return counts


func _most(counts: Dictionary) -> int:
	var best := -1
	for a: int in counts:
		if best < 0 or counts[a] > counts[best]:
			best = a
	return best


# --- A fresh creature already acts sensibly (hand-made defaults) ---

func test_a_hungry_animal_on_a_calm_day_grazes() -> void:
	var m := _mind()
	_calm_senses(m)
	m.drives[Mind.HUNGER] = 0.9
	assert_eq(_most(_pick_counts(m, 40)), AnimalSpecies.index(AnimalSpecies.GRAZE))


func test_a_scared_animal_runs() -> void:
	var m := _mind()
	_calm_senses(m)
	m.senses[Mind.S_NEAR] = 0.9
	m.senses[Mind.S_FEAR] = 0.9
	m.senses[Mind.S_THREAT] = 1.0
	m.drives[Mind.FEAR] = 0.8
	assert_eq(_most(_pick_counts(m, 40)), AnimalSpecies.index(AnimalSpecies.FLEE))


func test_a_sleepy_animal_at_night_sleeps() -> void:
	var m := _mind()
	_calm_senses(m)
	m.senses[Mind.S_NIGHT] = 1.0
	m.drives[Mind.SLEEPY] = 0.9
	assert_eq(_most(_pick_counts(m, 40)), AnimalSpecies.index(AnimalSpecies.SLEEP))


func test_an_animal_far_from_its_herd_goes_back_to_it() -> void:
	var m := _mind()
	_calm_senses(m)
	m.drives[Mind.COMPANY] = 0.9
	assert_eq(_most(_pick_counts(m, 40)), AnimalSpecies.index(AnimalSpecies.HERD))


func test_an_animal_runs_over_to_a_player_it_likes() -> void:
	var m := _mind()
	_calm_senses(m)
	m.senses[Mind.S_NEAR] = 0.4
	m.senses[Mind.S_LIKE] = 0.8
	assert_eq(_most(_pick_counts(m, 40)), AnimalSpecies.index(AnimalSpecies.APPROACH))


func test_a_curious_animal_goes_to_look_at_something_new() -> void:
	var m := _mind()
	_calm_senses(m)
	m.senses[Mind.S_NOVEL] = 1.0
	m.drives[Mind.CURIOSITY] = 0.8
	assert_eq(_most(_pick_counts(m, 40)), AnimalSpecies.index(AnimalSpecies.EXPLORE))


func test_actions_that_are_not_possible_are_never_picked() -> void:
	var m := _mind()
	_calm_senses(m)
	m.drives[Mind.HUNGER] = 1.0
	var allowed := (1 << AnimalSpecies.index(AnimalSpecies.WANDER)) | (1 << AnimalSpecies.index(AnimalSpecies.WATCH))
	var counts := _pick_counts(m, 60, allowed)
	for a: int in counts:
		assert_true(a == AnimalSpecies.index(AnimalSpecies.WANDER) or a == AnimalSpecies.index(AnimalSpecies.WATCH), "only allowed actions")


# --- Personality and determinism ---

func test_the_same_id_is_the_same_individual_and_ids_differ() -> void:
	var a := _mind("a3_4_1")
	var b := _mind("a3_4_1")
	var c := _mind("a3_4_2")
	assert_eq(a.personality, b.personality, "same id, same personality")
	assert_ne(a.personality, c.personality, "no two sheep are the same")
	_calm_senses(a)
	_calm_senses(b)
	var picks_a: Array[int] = []
	var picks_b: Array[int] = []
	for i in 30:
		a.interrupt()
		b.interrupt()
		picks_a.append(a.think())
		picks_b.append(b.think())
	assert_eq(picks_a, picks_b, "and the same choices")
	for v in a.personality:
		assert_between(v, -AnimalSpecies.table(&"sheep").personality, AnimalSpecies.table(&"sheep").personality)


func test_personality_tilts_the_scores() -> void:
	var m := _mind()
	_calm_senses(m)
	m.interrupt()
	m.think()
	# The final scores are the net's plus this individual's offsets.
	for i in m.scores.size():
		assert_almost_eq(m.scores[i] - m.raw[i], m.personality[i], 0.0001)


# --- Thinking takes time, events interrupt ---

func test_it_keeps_an_action_for_a_while_unless_something_happens() -> void:
	var m := _mind()
	_calm_senses(m)
	m.interrupt()
	m.think()
	assert_false(m.due(), "just decided")
	m.tick(0.5)
	assert_false(m.due())
	m.tick(20.0)
	assert_true(m.due(), "time to think again")
	m.think()
	m.interrupt()
	assert_true(m.due(), "something happened")


# --- Learning ---

func test_a_reward_makes_the_same_choice_likelier_in_the_same_situation() -> void:
	var m := Mind.create(AnimalSpecies.table(&"sheep"), "a9_9_0", AnimalSpecies.table(&"sheep").make_net(7))
	_calm_senses(m)
	m.senses[Mind.S_NEAR] = 0.5
	m.interrupt()
	var a := m.think()
	var before := m.raw[a]
	m.reward(1.0)
	m.interrupt()
	m.think()
	assert_gt(m.raw[a], before)


func test_learning_off_changes_nothing() -> void:
	var m := Mind.create(AnimalSpecies.table(&"sheep"), "a9_9_0", AnimalSpecies.table(&"sheep").make_net(7))
	m.learning = 0.0
	_calm_senses(m)
	m.interrupt()
	m.think()
	var before := m.net.w2 + m.net.b2
	for i in 20:
		m.reward(1.0)
	assert_eq(m.net.w2 + m.net.b2, before, "the net stays as it was")
	assert_eq(m.lessons, 0)


func test_events_use_the_species_reward_table() -> void:
	var m := Mind.create(AnimalSpecies.table(&"sheep"), "a9_9_0", AnimalSpecies.table(&"sheep").make_net(7))
	assert_gt(AnimalSpecies.table(&"sheep").rewards[&"fed"], 0.0)
	assert_lt(AnimalSpecies.table(&"sheep").rewards[&"hit"], 0.0)
	_calm_senses(m)
	m.interrupt()
	var a := m.think()
	var before := m.raw[a]
	assert_lt(m.feel(&"hit"), 0.0)
	m.interrupt()
	m.think()
	assert_lt(m.raw[a], before, "being hit makes what it was doing less likely")


# --- Thought bubbles ---

func test_thoughts_come_at_most_every_eight_seconds() -> void:
	var m := _mind()
	m.show_thought(Thought.HEART)
	assert_eq(m.take_thought(), Thought.HEART)
	assert_eq(m.take_thought(), -1, "only once")
	m.show_thought(Thought.ZZZ)
	m.tick(5.0)
	assert_eq(m.take_thought(), -1, "too soon after the last one")
	m.tick(Mind.BUBBLE_GAP)
	m.show_thought(Thought.ZZZ)
	assert_eq(m.take_thought(), Thought.ZZZ)


func test_an_action_with_a_picture_brings_its_thought() -> void:
	var m := _mind()
	_calm_senses(m)
	m.senses[Mind.S_NIGHT] = 1.0
	m.drives[Mind.SLEEPY] = 1.0
	m.interrupt()
	assert_eq(m.think(1 << AnimalSpecies.index(AnimalSpecies.SLEEP)), AnimalSpecies.index(AnimalSpecies.SLEEP))
	assert_eq(m.take_thought(), Thought.ZZZ)


# --- Saving ---

func test_save_round_trip() -> void:
	var m := Mind.create(AnimalSpecies.table(&"dog"), "pet1")
	m.memory.feel_about("Tina", 0.9, 0.0, 0.0)
	m.memory.pin("Tina")
	m.drives[Mind.HUNGER] = 0.7
	_calm_senses(m)
	for i in 10:
		m.interrupt()
		m.think()
		m.reward(1.0 if i % 2 == 0 else -0.5)
	var saved := m.to_save()
	var text := JSON.stringify(saved)
	assert_lte(text.length(), 2048, "a saved mind is at most 2 KB")
	var back := Mind.create(AnimalSpecies.table(&"dog"), "pet1")
	back.load_save(JSON.parse_string(text))
	assert_true(back.memory.knows("Tina"))
	assert_almost_eq(back.drives[Mind.HUNGER], 0.7, 0.01)
	_calm_senses(back)
	m.interrupt()
	back.interrupt()
	m.think()
	back.think()
	for i in m.raw.size():
		assert_almost_eq(back.raw[i], m.raw[i], 0.05, "its learning came back")
	for bad: Variant in [null, 5, "x", {"d": [NAN, "a"], "m": 3, "n": "!!"}]:
		var fresh := Mind.create(AnimalSpecies.table(&"dog"), "pet1")
		fresh.load_save(bad)
		for d in fresh.drives:
			assert_between(d, 0.0, 1.0)


# --- Light (spec §12.17: ≤ 20 µs a decision on this desktop) ---

func test_ten_thousand_decisions_take_under_200_ms() -> void:
	var minds: Array[Mind] = []
	for i in 24:
		minds.append(Mind.create(AnimalSpecies.table(AnimalRules.SPECIES.keys()[i % 7]), "a%d" % i))
	# Other agents' work shares this PC (load average 50 on 24 cores made the wall clock 2-3 times
	# slower), so the work is timed as this thread's own CPU time where Linux tells it; else the
	# quickest of five runs on the wall clock.
	var cpu0 := _cpu_us()
	var best := INF
	for run in 5:
		var t0 := Time.get_ticks_usec()
		for k in 2000:
			var m := minds[k % minds.size()]
			m.senses[Mind.S_NEAR] = float(k % 10) * 0.1
			m.senses[Mind.S_NIGHT] = 1.0 if k % 3 == 0 else 0.0
			m.tick(0.1)
			m.interrupt()
			m.think()
		best = minf(best, (Time.get_ticks_usec() - t0) / 1000.0)
	var wall_ms := best * 5.0
	var cpu_ms := (_cpu_us() - cpu0) / 1000.0 if cpu0 >= 0 else wall_ms
	gut.p("MINDS 10000 decisions: %.1f ms CPU (%.2f us each); wall clock %.1f ms (quickest of five runs of 2,000)" % [
		cpu_ms, cpu_ms / 10.0, wall_ms])
	assert_lt(cpu_ms, 200.0)


## This thread's CPU time (µs) from /proc/thread-self/schedstat, or -1 where there is none.
func _cpu_us() -> int:
	var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
	if f == null:
		return -1
	var first := f.get_line().split(" ")[0]
	return first.to_int() / 1000 if first.is_valid_int() else -1


## Found by the minds smoke run: a chicken that had just thought "food" showed no heart when a child
## fed it — the child's action got no answer for up to 8 s.
func test_an_answer_to_the_child_shows_at_once() -> void:
	var m := _mind()
	m.show_thought(Thought.FOOD)
	assert_eq(m.take_thought(), Thought.FOOD)
	m.tick(Mind.REACTION_GAP)
	m.show_thought(Thought.HEART, true)                  # the child just fed it
	assert_eq(m.take_thought(), Thought.HEART, "no waiting for the usual gap")
	m.tick(Mind.REACTION_GAP)
	m.show_thought(Thought.HEART, true)
	assert_eq(m.take_thought(), Thought.HEART, "and again for the next treat")
	m.show_thought(Thought.ZZZ)
	assert_eq(m.take_thought(), Thought.NONE, "its own thoughts still wait")


func test_the_same_thought_again_waits_longer() -> void:
	var m := _mind()
	m.show_thought(Thought.ZZZ)
	assert_eq(m.take_thought(), Thought.ZZZ)
	m.tick(Mind.BUBBLE_GAP + 1.0)
	m.show_thought(Thought.ZZZ)
	assert_eq(m.take_thought(), Thought.NONE, "zzz again so soon: once is enough")
	m.show_thought(Thought.HEART)
	assert_eq(m.take_thought(), Thought.HEART, "something new is shown")
	m.tick(Mind.BUBBLE_GAP * Mind.REPEAT_GAP)
	m.show_thought(Thought.ZZZ)
	assert_eq(m.take_thought(), Thought.ZZZ)
