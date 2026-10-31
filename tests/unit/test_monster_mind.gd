extends GutTest
## Monster minds as rules (M2 Task 18 part 2, spec §12.17): fair, signalled tactics picked by a small
## learned mind (straight at you, zigzag, go round, wait by cover, back off when hurt, call a friend);
## a species' table per world that learns within a cap; easing off after the child's knock-outs; slow
## learning in Sandbox, none in Cozy; a one-time hint of what they learned.


var _minds: MonsterMinds


func before_each() -> void:
	_minds = MonsterMinds.new()


## The senses of a monster looking at a child `d` blocks away.
func _situation(m: Mind, d: float, ranged := false, facing := false, melee := false, health := 1.0,
		shot := false, friends := false) -> void:
	m.senses.fill(0.0)
	m.senses[MonsterSpecies.S_NEAR] = clampf(1.0 - d / 16.0, 0.0, 1.0)
	m.senses[MonsterSpecies.S_RANGED] = 1.0 if ranged else 0.0
	m.senses[MonsterSpecies.S_FACING] = 1.0 if facing else 0.0
	m.senses[MonsterSpecies.S_MELEE] = 1.0 if melee else 0.0
	m.senses[MonsterSpecies.S_HEALTH] = health
	m.senses[MonsterSpecies.S_SHOT] = 1.0 if shot else 0.0
	m.senses[MonsterSpecies.S_KIN] = 1.0 if friends else 0.0
	m.senses[Mind.S_OUTCOME] = 0.5


func _goblin(id := "g1", net: TinyNet = null) -> Mind:
	var table := MonsterSpecies.table(MonsterRules.GOBLIN)
	return Mind.create(table, id, net if net else table.make_net(7))


func _counts(m: Mind, mask: int, n := 60) -> Dictionary:
	var out := {}
	for i in n:
		m.interrupt()
		var a := m.think(mask)
		out[MonsterSpecies.ACTIONS[a]] = int(out.get(MonsterSpecies.ACTIONS[a], 0)) + 1
	return out


func test_the_tactics_are_the_fair_ones_of_the_spec() -> void:
	assert_eq(MonsterSpecies.ACTIONS, [MonsterSpecies.STRAIGHT, MonsterSpecies.ZIGZAG, MonsterSpecies.GO_ROUND, MonsterSpecies.WAIT, MonsterSpecies.BACK_OFF, MonsterSpecies.CALL] as Array[StringName])
	for kind in MonsterRules.KINDS:
		assert_eq(MonsterSpecies.table(kind).actions, MonsterSpecies.ACTIONS)


## Found while tuning: TinyNet clamps weights to ±MAX_WEIGHT, so a hand-made weight over it quietly acts
## as the cap (part 1's dogs, 4.55, and rabbits, 4.2, acted as 4; MAX_WEIGHT is 5 since). Every
## species' hand-made numbers must fit.
func test_hand_made_weights_are_never_clipped() -> void:
	var tables: Array[MindSpecies] = [BotSpecies.table()]
	for kind in MonsterRules.KINDS:
		tables.append(MonsterSpecies.table(kind))
	for sp: StringName in AnimalRules.SPECIES:
		tables.append(AnimalSpecies.table(sp))
	for t in tables:
		for w in t.output_defaults:
			assert_between(w, -TinyNet.MAX_WEIGHT, TinyNet.MAX_WEIGHT, String(t.id))


func test_what_is_possible_depends_on_the_moment() -> void:
	var far := MonsterSpecies.allowed(10.0, true, false, 1.0, false, true)
	for t in [MonsterSpecies.STRAIGHT, MonsterSpecies.ZIGZAG, MonsterSpecies.GO_ROUND, MonsterSpecies.WAIT, MonsterSpecies.CALL]:
		assert_ne(far & MonsterSpecies.bit(t), 0, "%s far from an archer, a friend near" % t)
	assert_eq(far & MonsterSpecies.bit(MonsterSpecies.BACK_OFF), 0, "not hurt: no backing off")
	var close := MonsterSpecies.allowed(3.0, false, false, 0.4, false, false)
	assert_eq(close, MonsterSpecies.bit(MonsterSpecies.STRAIGHT) | MonsterSpecies.bit(MonsterSpecies.BACK_OFF), "close and hurt: straight in or back off")
	assert_eq(MonsterSpecies.allowed(10.0, false, false, 1.0, false, false) & MonsterSpecies.bit(MonsterSpecies.WAIT), 0,
		"waiting by cover is against an archer or a child who faces it")


func test_a_fresh_goblin_mostly_comes_straight_at_you() -> void:
	var m := _goblin()
	_situation(m, 10.0, true)
	var c := _counts(m, MonsterSpecies.allowed(10.0, true, false, 1.0, false, false))
	assert_gt(int(c.get(MonsterSpecies.STRAIGHT, 0)), 25, "%s" % [c])


func test_a_badly_hurt_goblin_steps_back_more_often() -> void:
	var m := _goblin()
	var mask := MonsterSpecies.allowed(3.0, false, false, 0.2, false, false)
	_situation(m, 3.0, false, false, false, 1.0)
	var healthy := _counts(m, mask)
	_situation(m, 3.0, false, false, false, 0.2)
	var hurt := _counts(m, mask)
	assert_gt(int(hurt.get(MonsterSpecies.BACK_OFF, 0)), int(healthy.get(MonsterSpecies.BACK_OFF, 0)) + 10, "hurt %s, healthy %s" % [hurt, healthy])


## The plan's test: a goblin hit by arrows from far learns to zigzag within a few encounters.
func test_goblins_shot_from_far_learn_to_zigzag_within_a_few_encounters() -> void:
	var table := MonsterSpecies.table(MonsterRules.GOBLIN)
	var net := table.make_net(3)
	var mask := MonsterSpecies.allowed(12.0, true, false, 1.0, false, false)
	var encounters := 0
	for i in 12:
		var m := _goblin("g%d" % i, net)                       # a new goblin every night, one table per world
		_situation(m, 12.0, true, false, false, 1.0, true)
		if MonsterSpecies.odds(m, mask)[MonsterSpecies.index(MonsterSpecies.ZIGZAG)] > MonsterSpecies.odds(m, mask)[MonsterSpecies.index(MonsterSpecies.STRAIGHT)]:
			break
		encounters += 1
		m.interrupt()
		m.think(mask)
		if m.action == MonsterSpecies.index(MonsterSpecies.ZIGZAG):
			m.feel(&"landed")                                    # weaving in, it reached the child
		else:
			m.feel(&"shot")                                      # an arrow: straight lines are easy to hit
	assert_lte(encounters, 5, "zigzags after %d encounters" % encounters)


func test_learning_is_capped_by_the_universe() -> void:
	var net := MonsterSpecies.table(MonsterRules.GOBLIN).make_net(3)
	MonsterSpecies.cap(net, 1)
	var m := _goblin("g", net)
	_situation(m, 12.0, true, false, false, 1.0, true)
	for i in 200:
		m.interrupt()
		m.think(MonsterSpecies.bit(MonsterSpecies.STRAIGHT))
		m.feel(&"shot")
	for i in net.w2.size():
		assert_lte(absf(net.w2[i] - net.base2[i]), MonsterSpecies.MAX_DRIFT + 0.0001)
	var n2 := MonsterSpecies.table(MonsterRules.GOBLIN).make_net(3)
	MonsterSpecies.cap(n2, 3)
	assert_gt(n2.max_delta, net.max_delta, "later universes learn more")
	assert_lte(n2.max_delta, TinyNet.MAX_DELTA)


# --- Fair-fun guards ---

func test_cozy_worlds_never_learn_and_keep_it_simple() -> void:
	_minds.difficulty = DifficultyRules.COZY
	assert_eq(_minds.learning(0), 0.0)
	var all := MonsterSpecies.allowed(10.0, true, true, 0.3, false, true)
	assert_eq(_minds.restrict(all, 0, 0.0), MonsterSpecies.bit(MonsterSpecies.STRAIGHT) | MonsterSpecies.bit(MonsterSpecies.BACK_OFF))


func test_sandbox_monsters_learn_slowly() -> void:
	_minds.gentle = true
	assert_almost_eq(_minds.learning(0), MonsterMinds.GENTLE_LEARNING, 0.0001)
	assert_lt(MonsterMinds.GENTLE_LEARNING, 0.5)
	_minds.gentle = false
	assert_eq(_minds.learning(0), 1.0)


## From the very same moment (same net, same senses, same pick), a gentle mind's lesson moves its table
## exactly GENTLE_LEARNING as far (the exact ratio lives here: in a scene two goblins never see quite
## the same moment, lead 19:10).
func test_a_gentle_mind_learns_a_fraction_as_much_from_the_same_moment() -> void:
	var drift := {}
	for rate: float in [1.0, MonsterMinds.GENTLE_LEARNING]:
		var net := MonsterSpecies.table(MonsterRules.GOBLIN).make_net(3)
		var m := _goblin("g", net)
		_situation(m, 12.0, true, false, false, 1.0, true)
		m.interrupt()
		m.think(MonsterSpecies.bit(MonsterSpecies.STRAIGHT))
		m.learning = rate
		m.feel(&"shot")
		var d := 0.0
		for i in net.w2.size():
			d += absf(net.w2[i] - net.base2[i])
		drift[rate] = d
	assert_gt(drift[1.0], 0.0)
	assert_almost_eq(drift[MonsterMinds.GENTLE_LEARNING], drift[1.0] * MonsterMinds.GENTLE_LEARNING, drift[1.0] * 0.001, "%s" % [drift])


func test_they_ease_off_after_the_childs_knock_outs() -> void:
	assert_eq(_minds.ease_of(7), 0.0)
	_minds.note_knockout(7)
	assert_almost_eq(_minds.ease_of(7), 0.5, 0.001)
	_minds.note_knockout(7)
	assert_eq(_minds.ease_of(7), 1.0, "two knock-outs: plain monsters")
	assert_eq(_minds.ease_of(8), 0.0, "another child: not eased")
	assert_eq(_minds.learning(7), 0.0, "no learning from knocking a child out again and again")
	var all := MonsterSpecies.allowed(10.0, true, true, 1.0, false, true)
	assert_eq(_minds.restrict(all, 7, 0.99), MonsterSpecies.bit(MonsterSpecies.STRAIGHT), "only straight at a knocked-out child")
	for i in 60:
		_minds.tick(10.0)
	assert_lt(_minds.ease_of(7), 0.05, "ten minutes later it has faded")
	assert_eq(_minds.restrict(all, 7, 0.99), all)


# --- The one-time hint ---

func test_a_hint_tells_the_child_once_what_the_monsters_learned() -> void:
	var said: Array[String] = []
	_minds.hint.connect(func(text: String) -> void: said.append(text))
	var table := MonsterSpecies.table(MonsterRules.GOBLIN)
	var net := table.make_net(3)
	_minds.check_hints(MonsterRules.GOBLIN, net)
	assert_eq(said.size(), 0, "nothing learned yet")
	var m := _goblin("g", net)
	for i in 8:
		_situation(m, 12.0, true, false, false, 1.0, true)
		m.interrupt()
		if i % 2 == 0:
			m.think(MonsterSpecies.bit(MonsterSpecies.STRAIGHT))
			m.feel(&"shot")                                      # straight at the archer: an arrow
		else:
			m.think(MonsterSpecies.bit(MonsterSpecies.ZIGZAG))
			m.feel(&"landed")                                    # weaving in: it got there
		_minds.check_hints(MonsterRules.GOBLIN, net)
	assert_eq(said.size(), 1, "one hint, only for what worked: %s" % [said])
	assert_string_contains(said[0], "zigzag")
	assert_string_contains(said[0].to_lower(), "goblin")
	assert_has(_minds.hints_given, "goblin:zigzag")
	for i in 5:
		_minds.check_hints(MonsterRules.GOBLIN, net)
	assert_eq(said.size(), 1, "never twice in a world")
	var again := MonsterMinds.new()
	again.load_hints(_minds.hints_given)
	var said2: Array[String] = []
	again.hint.connect(func(text: String) -> void: said2.append(text))
	again.check_hints(MonsterRules.GOBLIN, net)
	assert_eq(said2.size(), 0, "not after a reload either")


func test_hints_are_friendly_pictures_in_words_and_never_scary() -> void:
	for key: String in MonsterSpecies.HINTS:
		var text: String = MonsterSpecies.HINTS[key]
		assert_lte(text.length(), 60, key)
		assert_true(text.ends_with("!"), key)
		for bad in ["die", "kill", "dead", "blood", "hurt you"]:
			assert_false(text.to_lower().contains(bad), "%s: %s" % [key, text])


func test_saved_hints_are_checked() -> void:
	var m := MonsterMinds.new()
	m.load_hints(["goblin:zigzag", "nope", 5, "slime:call", "goblin:zigzag"])
	assert_eq(m.hints_given, ["goblin:zigzag", "slime:call"] as Array[String])
	assert_eq(MonsterMinds.clean_hints("x"), [] as Array[String])


func test_weapons_the_child_holds() -> void:
	assert_eq(MonsterSpecies.weapon_class(ItemIds.BOW), MonsterSpecies.RANGED)
	assert_eq(MonsterSpecies.weapon_class(ItemIds.BOOMERANG), MonsterSpecies.RANGED)
	assert_eq(MonsterSpecies.weapon_class(ItemIds.SPEAR), MonsterSpecies.RANGED, "a spear is thrown")
	assert_eq(MonsterSpecies.weapon_class(ItemIds.SWORD), MonsterSpecies.MELEE)
	assert_eq(MonsterSpecies.weapon_class(0), MonsterSpecies.NO_WEAPON)
	assert_eq(MonsterSpecies.weapon_class(BlockIds.STONE), MonsterSpecies.NO_WEAPON)


func test_monster_tables_fit_the_world_budget_with_the_animals() -> void:
	var book := MindBook.new()
	for sp: StringName in AnimalRules.SPECIES:
		if PetRules.is_pet_kind(sp) and not PetRules.tames_by_petting(sp) and not PetRules.tames_by_treats(sp):
			continue   # owner 39: a given pet (Pip, the dragon) is never wild: its mind is its own, never the book's
		_teach(book.net_for(AnimalSpecies.table(sp)))
	for kind in MonsterRules.KINDS:
		_teach(book.net_for(MonsterSpecies.table(kind)))
	var saved := book.to_save()
	assert_lte(JSON.stringify(saved).length(), MindBook.MAX_TOTAL)
	assert_true(saved.has("monster:goblin") and saved.has("monster:slime"), "%s" % [saved.keys()])


func _teach(net: TinyNet) -> void:
	var x := PackedFloat32Array()
	x.resize(TinyNet.INPUTS)
	x.fill(0.5)
	for i in 20:
		net.forward(x)
		net.learn(i % net.outputs, 1.0 if i % 2 == 0 else -1.0, 0.3, net.last_hidden())
