extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5, §3.5b, §3.8, §3.10, rulings 8, 25, 32): one voyage inside
## the plant, as B2's host will play it: Hoot's line, the ghost shows one door, the child shuts the rest, the cells fill
## and the leaf stands (B1); then the weather's turns, the first ones voiced, the rest silent and judged; help only after
## misses (and it makes the beat helped), a longer window after two misses, the "too dry" rescue, extra turns while the
## bud isn't full, the bud's "Let's grow back!"; in the desert, the night's lines and the jars'. No nodes: the host acts
## on the cues.

const DT := 0.1
const Bots := preload("res://tests/unit/leaf_bots.gd")


## Steps `run` for `seconds`, calling `each` (run) before every step; the cues it gave.
func _play(run: LeafRun, seconds: float, each: Callable = Callable()) -> Array[Dictionary]:
	var cues: Array[Dictionary] = []
	for i in int(round(seconds / DT)):
		if each.is_valid():
			each.call(run)
		run.step(DT)
		cues.append_array(run.take_cues())
	return cues


func _said(cues: Array) -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in cues:
		if c.has("say"):
			out.append(str(c.say))
	return out


## The child who knows the rule: sets the doors the weather asks for, one a step, and carries every waiting sugar.
func _rule(run: LeafRun) -> void:
	var w := run.weather_now()
	var want: bool = run.phase == LeafRun.PLAY and bool(w.get("open", false))
	for i in run.sim.doors.size():
		if run.sim.doors[i] != want:
			run.toggle(i)
			return
	while run.take():
		run.deliver("gold")


func _shut_all(run: LeafRun) -> void:
	for i in run.sim.doors.size():
		if run.sim.doors[i]:
			run.toggle(i)


## From the start to the weather's first moment, the child shutting every door at once: the cues on the way.
func _to_play(run: LeafRun) -> Array[Dictionary]:
	run.start()
	var cues := run.take_cues()
	var guard := 0
	while run.phase != LeafRun.PLAY and guard < 400:
		_shut_all(run)
		run.step(DT)
		cues.append_array(run.take_cues())
		guard += 1
	return cues


func test_act_1_hoot_speaks_the_ghost_shuts_one_door_and_the_child_the_rest() -> void:
	var run := LeafRun.make("5.1", 1)
	run.start()
	var cues := run.take_cues()
	assert_eq(run.phase, LeafRun.ACT1)
	assert_eq(_said(cues), ["L6"] as Array[String], "Look! The water is escaping through the doors.")
	assert_eq(run.sim.open_count(), 6, "the mist pours from six open doors")
	cues = _play(run, 4.5)
	var ghost := cues.filter(func(c: Dictionary) -> bool: return str(c.get("ghost", "")) == "door")
	assert_eq(ghost.size(), 1, "the ghost shows one door")
	assert_false(run.sim.doors[int(ghost[0].door)], "and it is shut")
	assert_true(_said(cues).has("L7"), "Squeeze the doors shut. Your turn!")
	run.toggle(int(ghost[0].door) + 1 if int(ghost[0].door) < 5 else 0)
	cues = run.take_cues()
	assert_eq(_said(cues), ["L8"] as Array[String], "the child's first door: Yes! The water stays in now.")
	cues = _play(run, 12.0, _shut_all)
	var b1 := cues.filter(func(c: Dictionary) -> bool: return c.has("beat"))
	assert_eq(b1.size(), 1)
	assert_eq(str(b1[0].beat.id), "B1")
	assert_eq(str(b1[0].beat.kind), SkillShown.SOLVED, "copying the demonstration still counts")
	var said := _said(cues)
	assert_lt(said.find("L10"), said.find("L11"), "the cells are full, then the see-why line")
	assert_lt(said.find("L11"), said.find("L12"), "then the weather: The green workshops have stopped. They need air.")
	assert_true(run.sim.standing())
	assert_eq(run.phase, LeafRun.PLAY, "the weather plays")
	assert_gt(run.sim.water, 0.85, "the fill brought the leaf up to the design's start of Act 2")


func test_act_1_idling_brings_the_hint_then_a_second_ghost_and_the_beat_is_helped() -> void:
	var run := LeafRun.make("5.1", 1)
	run.start()
	var cues := _play(run, 4.5)
	cues = _play(run, 11.0)
	assert_true(_said(cues).has("L9"), "Squeeze the two green sides together.")
	cues = _play(run, 11.0)
	var ghosts := cues.filter(func(c: Dictionary) -> bool: return str(c.get("ghost", "")) == "door")
	assert_eq(ghosts.size(), 1, "the ghost does another door")
	cues = _play(run, 15.0, _shut_all)
	var b1 := cues.filter(func(c: Dictionary) -> bool: return c.has("beat"))
	assert_eq(str(b1[0].beat.kind), SkillShown.HELPED, "a second ghost: helped")


func test_show_me_in_act_1_makes_the_beat_helped() -> void:
	var run := LeafRun.make("5.1", 1)
	run.start()
	_play(run, 4.5)
	run.show_me()
	var cues := _play(run, 15.0, _shut_all)
	var b1 := cues.filter(func(c: Dictionary) -> bool: return c.has("beat"))
	assert_eq(str(b1[0].beat.kind), SkillShown.HELPED)


func test_the_first_turns_are_voiced_and_the_rest_silent() -> void:
	var run := LeafRun.make("5.1", 1)
	var cues := _to_play(run)
	var carry_less := func(r: LeafRun) -> void:   # the doors by the rule; the sugar left for the ghost's demonstration
		var want: bool = bool(r.weather_now().get("open", false))
		for i in r.sim.doors.size():
			if r.sim.doors[i] != want:
				r.toggle(i)
				return
	cues.append_array(_play(run, run.weather.start_of(run.weather.index_of("cloud2")) + 1.0, carry_less))
	var said := _said(cues)
	assert_true(said.has("L15"), "the first cloud: A cloud! It's cooler now. Open the doors!")
	assert_true(said.has("L16"), "the first sugar: Air plus light makes sugar.")
	assert_true(said.has("L18"), "the first blaze: Sun's back! Close the doors!")
	assert_true(said.has("L19"), "the ghost carries a sugar: Carry the sugar to the gold pipe.")
	assert_true(cues.any(func(c: Dictionary) -> bool: return str(c.get("ghost", "")) == "carry"))
	cues = _play(run, 70.0, _rule)
	for line: String in ["L15", "L18", "L19", "L9", "L27"]:
		assert_false(_said(cues).has(line), "the silent turns: %s is not said" % line)
	var beats := cues.filter(func(c: Dictionary) -> bool: return c.has("beat"))
	assert_gt(beats.size(), 3, "silent beats judged")
	for b: Dictionary in beats:
		assert_eq(str(b.beat.kind), SkillShown.SOLVED, "%s: %s" % [b.beat.id, b.beat.note])


func test_the_trap_answers_an_open_door_and_a_wait() -> void:
	var run := LeafRun.make("5.1", 1)
	_to_play(run)
	assert_eq(str(run.weather_now().id), "trap")
	var cues := _play(run, 7.0)
	assert_true(_said(cues).has("L14"), "waiting in the blaze: Wait for the sun to hide.")
	run.toggle(0)
	cues = run.take_cues()
	assert_true(_said(cues).has("L13"), "a door opened in the blaze: Too hot! The water rushes out.")


func test_two_missed_turns_bring_a_longer_window_and_help_that_counts_as_help() -> void:
	var run := LeafRun.make("5.1", 1)
	run.start()
	_play(run, 25.0, _rule)
	var cloud2 := run.weather.index_of("cloud2")
	var wrong := func(r: LeafRun) -> void:   # always shut: misses the clouds
		_shut_all(r)
	_play(run, run.weather.start_of(cloud2) - run.t, _rule)
	var cues := _play(run, 35.5, wrong)   # cloud 2 missed, blaze 2 passed
	cues.append_array(_play(run, 21.0, wrong))   # cloud 3 missed: two misses
	var said := _said(cues)
	assert_true(bool(run.weather.segments[run.weather.index_of("cloud4")].longer), "the next cloud lasts longer")
	cues = _play(run, run.weather.start_of(run.weather.index_of("cloud4")) - run.t + 7.0, wrong)
	assert_true(_said(cues).has("L15"), "into the window with the doors still wrong: Hoot says the cue")
	cues = _play(run, 60.0, _rule)
	var c4 := run.beats.results.filter(func(r: Dictionary) -> bool: return str(r.id) == "C4")
	assert_eq(str(c4[0].kind), SkillShown.HELPED, "after the hint it does not count")
	assert_string_contains(str(c4[0].note), "long window")


func test_too_dry_brings_hoot_and_the_ghost_and_the_beat_is_helped() -> void:
	var run := LeafRun.make("5.1", 1)
	run.start()
	_play(run, 25.0, _rule)
	var open_all := func(r: LeafRun) -> void:
		for i in r.sim.doors.size():
			if not r.sim.doors[i]:
				r.toggle(i)
				return
	var blaze2 := run.weather.index_of("blaze2")
	_play(run, run.weather.start_of(blaze2) - run.t, _rule)
	run.sim.water = 0.4   # a leaf already low, every door thrown open in the blaze
	var cues := _play(run, 6.0, open_all)
	assert_true(_said(cues).has("L27"), "The leaf is too dry! Close the doors.")
	assert_true(cues.any(func(c: Dictionary) -> bool: return c.has("rescue")))
	_play(run, 10.0)   # to the end of the blaze, where Z2 is judged
	var z2 := run.beats.results.filter(func(r: Dictionary) -> bool: return str(r.id) == "Z2")
	assert_eq(str(z2[0].kind), SkillShown.HELPED)


func test_the_bud_asks_for_more_turns_and_the_voyage_ends_when_it_is_full() -> void:
	var run := LeafRun.make("5.1", 1)
	run.start()
	var no_carry := func(r: LeafRun) -> void:   # knows the doors, never carries the sugar
		var want: bool = r.phase == LeafRun.PLAY and bool(r.weather_now().get("open", false))
		for i in r.sim.doors.size():
			if r.sim.doors[i] != want:
				r.toggle(i)
				return
	_play(run, 320.0, no_carry)
	assert_eq(run.weather.turn_count(), 6, "the bud asked for two more turns")
	assert_eq(run.phase, LeafRun.DONE, "after the sixth turn the voyage ends anyway")
	assert_true(run.sim.bud_full(), "the ghost topped the bud up: the plant never fails")
	var carrier := LeafRun.make("5.1", 2)
	carrier.start()
	var cues := _play(carrier, 300.0, _rule)
	assert_eq(carrier.weather.turn_count(), 4, "a full bud: no extra turn")
	assert_eq(carrier.phase, LeafRun.DONE)
	assert_true(_said(cues).has("L21"), "The bud is full! Let's grow back and see!")
	var shown := SkillShown.begin()
	carrier.record(shown)
	assert_eq(shown.total("g5.science.plants_air_water"), 7)
	assert_eq(shown.right_first("g5.science.plants_air_water"), 7)


func test_a_sugar_in_the_blue_pipe_bobs_back() -> void:
	var run := LeafRun.make("5.1", 1)
	run.sim.made = 2.0
	assert_true(run.take())
	assert_false(run.deliver("blue"), "the blue pipe brings water in")
	assert_eq(_said(run.take_cues()), ["L20"] as Array[String])
	assert_eq(run.carried(), 1, "still in the child's hands")
	assert_true(run.deliver("gold"))
	assert_eq(run.carried(), 0)


func test_praise_follows_a_solved_beat_and_never_twice_in_a_row() -> void:
	var run := LeafRun.make("5.1", 3)
	run.start()
	var cues := _play(run, 300.0, _rule)
	var praise: Array[String] = []
	for id in _said(cues):
		if id.begins_with("P"):
			praise.append(id)
	assert_gte(praise.size(), 3, "praise for the strategy after solved beats")
	for i in range(1, praise.size()):
		assert_ne(praise[i], praise[i - 1], "never the same twice in a row")


func test_the_desert_night_speaks_at_its_moments_and_records_the_transfer() -> void:
	var run := LeafRun.make("5.T1", 1)
	run.start()
	var cues := run.take_cues()
	assert_eq(run.phase, LeafRun.PLAY, "no act 1: the doors start shut")
	assert_eq(_said(cues), ["D3"] as Array[String], "Phew, it's baking! Keep the doors shut.")
	cues = _play(run, 13.0)
	assert_true(_said(cues).has("D4"), "waiting for a cloud: No clouds in the desert. When does it cool down?")
	var cool := func(r: LeafRun) -> void:
		var want: bool = bool(r.weather_now().get("open", false))
		for i in r.sim.doors.size():
			if r.sim.doors[i] != want:
				r.toggle(i)
				return
		while r.take():
			r.deliver("gold")
	cues = _play(run, 40.0, cool)
	assert_true(_said(cues).has("D5"), "dusk: The sun is setting. Feel that cool air?")
	assert_true(_said(cues).has("D6"), "the first jar: The cactus keeps the air in jars for tomorrow!")
	cues = _play(run, 110.0, cool)
	assert_true(_said(cues).has("D7"), "building behind shut doors: Doors shut, and it still builds. Clever cactus!")
	assert_eq(run.phase, LeafRun.DONE)
	var shown := SkillShown.begin()
	run.record(shown)
	assert_eq(shown.total("g5.science.plants_air_water"), 6)
	assert_eq(shown.transfer("g5.science.plants_air_water"), 6, "solved somewhere new")


func test_through_the_whole_run_guessing_still_never_masters_and_the_rule_does() -> void:
	for policy: String in [Bots.RULE, Bots.RANDOM, Bots.ALWAYS_OPEN, Bots.BRIGHT]:
		var masters := 0
		var runs := 150
		for seed in runs:
			var run := LeafRun.make("5.1", seed)
			var bot: RefCounted = Bots.new(policy, "flat", seed)
			run.start()
			var guard := 0
			while run.phase != LeafRun.DONE and guard < 6000:
				if run.phase == LeafRun.PLAY:
					bot.act_run(run)
				else:
					_shut_all(run)   # act 1 copies the demonstration: the most a guesser could hope for
				run.step(DT)
				run.take_cues()
				guard += 1
			var shown := SkillShown.begin()
			run.record(shown)
			var unit := "g5.science.plants_air_water"
			if MasteryRules.is_mastery(shown.right_first(unit), shown.total(unit)):
				masters += 1
		gut.p("LEAF_RUN_BOTS 5.1 %s: masters %.1f %% through the whole run (help, longer windows, extra turns)" % [policy,
			100.0 * masters / runs])
		if policy == Bots.RULE:
			assert_gt(float(masters) / runs, 0.99)
		else:
			assert_lt(float(masters) / runs, 0.01, policy)


func test_help_in_the_desert_says_the_desert_s_own_cue_and_only_then_counts_as_help() -> void:
	var run := LeafRun.make("5.T1", 1)
	run.start()
	run.take_cues()
	var habit := func(r: LeafRun) -> void:   # the sunflower's habit: open in daylight, shut at night
		var want: bool = not bool(r.weather_now().get("night", false))
		for i in r.sim.doors.size():
			if r.sim.doors[i] != want:
				r.toggle(i)
				return
	var day3 := run.weather.index_of("day3")
	_play(run, run.weather.start_of(day3), habit)
	var cues := _play(run, 9.0, habit)   # two missed days: the third day's dawn gets help
	assert_true(_said(cues).has("D3"), "Hoot says the desert's own cue: Phew, it's baking! Keep the doors shut.")
	_play(run, 30.0, habit)
	var dawn2 := run.beats.results.filter(func(r: Dictionary) -> bool: return str(r.id) == "Dawn2")
	assert_ne(str(dawn2[0].help), "", "helped (the hint, or the ghost after it), because the help was really given")
	assert_eq(str(dawn2[0].kind), SkillShown.HELPED)


func test_show_me_with_nothing_to_show_is_no_help() -> void:
	var run := LeafRun.make("5.1", 1)
	_to_play(run)
	_play(run, 2.0)   # the trap blaze: the doors shut, nothing waiting
	run.take_cues()
	run.show_me()
	var cues := run.take_cues()
	assert_false(cues.any(func(c: Dictionary) -> bool: return c.has("ghost")), "nothing to show")
	assert_true(run.beats.open_now().is_empty() or not run.beats._help.has(str(run.beats.open_now()[0].id)))
	var c2 := run.weather.index_of("cloud2")
	_play(run, run.weather.start_of(c2) - run.t + 1.0, _rule)
	run.show_me()   # the doors are right and the sugar carried: still nothing to show
	_play(run, 40.0, _rule)
	var r := run.beats.results.filter(func(b: Dictionary) -> bool: return str(b.id) == "C2")
	assert_eq(str(r[0].kind), SkillShown.SOLVED, "an empty SHOW ME doesn't cost the beat")


func test_your_turn_is_not_said_once_every_door_is_shut() -> void:
	var run := LeafRun.make("5.1", 1)
	run.start()
	run.take_cues()
	_play(run, 3.1)   # the ghost has begun its door
	for i in range(1, run.sim.doors.size()):
		run.toggle(i)   # the child shuts all the others before it arrives
	var cues := _play(run, 3.0)
	assert_false(_said(cues).has("L7"), "no 'Your turn!' once the doors are shut")
