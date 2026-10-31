extends GutTest
## Owner #45a (spec §14.17): quest givers and their picture-story chains. Tilly in Green Meadows and a helper
## in each other universe give short chains of 3-5 steps made of what the world already has; a chain ends
## with a keepsake, a title, fixed gold (Survivor) and a new place. Fair fun: no timers, nothing expires,
## nothing is lost, rewards are fixed; a chain can be stopped and picked up later.

const TIME_WORDS := ["time", "timer", "second", "minute", "hour", "date", "day", "expire", "deadline", "streak",
	"hurry", "quick", "fast", "last chance", "countdown", "reset"]


func _data() -> ProgressData:
	return ProgressData.new()


func test_tilly_and_a_helper_in_every_other_universe() -> void:
	assert_eq(QuestRules.giver(&"tilly").universe, 1)
	var universes := {}
	for id: StringName in QuestRules.GIVERS:
		var g := QuestRules.giver(id)
		universes[int(g.universe)] = id
		assert_true(ProgressPictures.knows(g.picture), "%s has a picture" % id)
		assert_ne(str(g.name), "")
	for u in range(1, UniverseRegistry.size() + 1):
		assert_true(universes.has(u), "universe %d has a quest giver" % u)
	assert_eq(QuestRules.giver_in(2), &"zara")
	assert_eq(QuestRules.giver_in(3), &"bram")
	assert_eq(QuestRules.giver_in(4), &"mimi")
	assert_eq(QuestRules.giver_in(5), &"nell", "owner #39's Dragon Realm has Nell the dragon keeper")
	assert_eq(QuestRules.giver_in(99), &"")


func test_every_chain_is_a_short_picture_story_with_its_rewards() -> void:
	assert_gte(QuestRules.CHAINS.size(), 8)
	var ids := {}
	var keepsakes := {}
	var titles := {}
	for c: Dictionary in QuestRules.CHAINS:
		assert_false(ids.has(c.id), "one of each: %s" % c.id)
		ids[c.id] = true
		assert_true(QuestRules.GIVERS.has(c.giver), "%s has a giver" % c.id)
		assert_between((c.steps as Array).size(), 3, 5, "%s has 3-5 steps" % c.id)
		assert_true(ProgressPictures.knows(c.picture), "%s has a picture" % c.id)
		assert_lte(str(c.title).split(" ").size(), 4, "a short chain name: %s" % c.title)
		assert_ne(str(c.story), "", "%s tells its story" % c.id)
		var k := QuestRules.keepsake(c.id)
		assert_false(keepsakes.has(k.id), "one keepsake each: %s" % k.id)
		keepsakes[k.id] = true
		assert_true(ProgressPictures.knows(k.picture), "keepsake %s has a picture" % k.id)
		assert_lte(str(k.words).split(" ").size(), 4)
		var title := QuestRules.title_words(QuestRules.title_id(c.id))
		assert_false(titles.has(title), "one title each: %s" % title)
		titles[title] = true
		assert_between(title.split(" ").size(), 1, 3, "a short title: %s" % title)
		assert_gt(QuestRules.gold_for(c.id), 0, "%s pays fixed gold in Survivor" % c.id)
		var last: Dictionary = (c.steps as Array).back()
		assert_eq(last.type, QuestRules.GO, "%s ends back at its giver" % c.id)
		for s: Dictionary in c.steps:
			assert_true(ProgressPictures.knows(s.picture), "%s: step picture %s" % [c.id, s.picture])
			assert_lte(str(s.words).split(" ").size(), 7, "short step words: %s" % s.words)
			match s.type:
				QuestRules.DO:
					assert_true(LevelRules.is_kind(s.kind), "%s counts a real event: %s" % [c.id, s.kind])
					assert_between(int(s.need), 1, 5, "a small number: %s" % s.words)
				QuestRules.REACH:
					assert_true(SecretRules.is_kind(s.kind), "%s walks to a real place: %s" % [c.id, s.kind])
				QuestRules.GO:
					pass
				_:
					fail_test("unknown step type %s" % s.type)
			if s.has("find"):
				assert_true(SecretRules.is_kind(s.find), "%s's arrow shows a real place: %s" % [c.id, s.find])
	for giver: StringName in QuestRules.GIVERS:
		assert_gte(QuestRules.chains_of(giver).size(), 2, "%s has stories" % giver)


func test_the_chains_use_secrets_animals_crafting_and_treasures() -> void:
	var families := {}
	var treasure_kinds := 0
	for c: Dictionary in QuestRules.CHAINS:
		for s: Dictionary in c.steps:
			if s.type == QuestRules.DO:
				families[LevelRules.family(s.kind)] = true
				var detail := String(s.kind).get_slice("/", 1)
				if TreasurePlaces.KINDS.has(StringName(detail)):
					treasure_kinds += 1
	for f: StringName in [LevelRules.SECRET, LevelRules.TAMED, LevelRules.CRAFTED, LevelRules.MONSTER]:
		assert_true(families.has(f), "a chain uses %s" % f)
	assert_gt(treasure_kinds, 0, "a chain uses the #42 treasures")


## Fair fun: fixed rewards, no clock anywhere in the stories.
func test_no_timer_or_hurry_anywhere_in_the_chains() -> void:
	var text := JSON.stringify(QuestRules.CHAINS).to_lower() + JSON.stringify(QuestRules.GIVERS).to_lower()
	for w: String in TIME_WORDS:
		assert_false(text.contains(w), "no '%s' in the quest stories" % w)
	for c: Dictionary in QuestRules.CHAINS:
		assert_eq(QuestRules.gold_for(c.id), QuestRules.gold_for(c.id), "the same gold every time")
		assert_eq(QuestRules.gold_for(c.id), UniverseRules.gold(int(c.gold), int(QuestRules.giver(c.giver).universe)),
			"%s: base × 2^(u−1)" % c.id)


func test_a_giver_offers_its_stories_in_order_and_only_where_they_can_be_done() -> void:
	var d := _data()
	var first: StringName = QuestRules.chains_of(&"tilly")[0]
	var second: StringName = QuestRules.chains_of(&"tilly")[1]
	assert_eq(QuestRules.offered(d, &"tilly", ModeRules.SANDBOX), first)
	d.quests.done.append(String(first))
	assert_eq(QuestRules.offered(d, &"tilly", ModeRules.SANDBOX), second, "the next story after the first")
	for c: Dictionary in QuestRules.CHAINS:
		if QuestRules.needs_survivor(c.id):
			assert_false(QuestRules.allowed_in(c.id, ModeRules.SANDBOX), "%s crafts: Survivor only" % c.id)
		assert_true(QuestRules.allowed_in(c.id, ModeRules.SURVIVOR))
		assert_false(QuestRules.allowed_in(c.id, ModeRules.WAVE), "no stories in the arena")
	assert_true(QuestRules.needs_survivor(&"bram_lantern"), "the lantern is crafted")
	assert_false(QuestRules.needs_survivor(&"tilly_map"))
	for id in QuestRules.chains_of(&"tilly"):
		d.quests.done.append(String(id))
	assert_eq(QuestRules.offered(d, &"tilly", ModeRules.SANDBOX), &"", "every story told")


func test_starting_a_chain_counts_its_first_step_from_now_in_its_universe() -> void:
	var d := _data()
	d.record(&"secret_found/treasure", 1, 1)
	assert_true(QuestRules.start(d, &"tilly_map"))
	assert_eq(d.quests.active, &"tilly_map")
	assert_eq(QuestRules.step_index(d, &"tilly_map"), 0)
	assert_eq(QuestRules.step_progress(d, &"tilly_map"), Vector2i(0, 1), "the treasure dug up before does not count")
	d.record(&"secret_found/treasure", 1, 2)
	assert_eq(QuestRules.check(d), [] as Array[Dictionary], "a desert treasure is not Tilly's")
	d.record(&"secret_found/treasure", 1, 1)
	var got := QuestRules.check(d)
	assert_eq(got.size(), 1)
	assert_eq(got[0].chain, &"tilly_map")
	assert_eq(int(got[0].step), 0)
	assert_false(got[0].finished)
	assert_eq(QuestRules.step_index(d, &"tilly_map"), 1, "on to the next step")
	assert_false(QuestRules.start(d, &"no_such_chain"))


func test_reach_and_come_back_steps_are_done_by_arriving() -> void:
	var d := _data()
	QuestRules.start(d, &"zara_scarab")
	d.record(&"secret_found/treasure", 1, 2)
	QuestRules.check(d)
	assert_eq(QuestRules.current_step(d, &"zara_scarab").type, QuestRules.REACH)
	assert_false(QuestRules.arrive(d, &"zara_scarab", QuestRules.GO), "arriving at the giver is not the pyramid")
	assert_true(QuestRules.arrive(d, &"zara_scarab", QuestRules.REACH))
	assert_eq(QuestRules.current_step(d, &"zara_scarab").type, QuestRules.DO)
	d.record(&"secret_found/temple", 1, 2)
	QuestRules.check(d)
	assert_eq(QuestRules.current_step(d, &"zara_scarab").type, QuestRules.GO)
	assert_true(QuestRules.arrive(d, &"zara_scarab", QuestRules.GO))
	assert_true(QuestRules.is_ready_to_finish(d, &"zara_scarab"), "every step done: the rewards wait")


## A place found while walking to it still counts for the step that asks to find it.
func test_a_find_during_the_walk_there_counts_for_the_next_step() -> void:
	var d := _data()
	QuestRules.start(d, &"zara_scarab")
	d.record(&"secret_found/treasure", 1, 2)
	QuestRules.check(d)
	d.record(&"secret_found/temple", 1, 2)   # solved before the walk was counted as arrived
	QuestRules.check(d)
	assert_eq(QuestRules.current_step(d, &"zara_scarab").type, QuestRules.GO,
		"the walk counts as arrived and the find counts too")


func test_finishing_gives_the_rewards_once() -> void:
	var d := _data()
	_run_to_the_end(d, &"tilly_map")
	assert_true(QuestRules.is_ready_to_finish(d, &"tilly_map"))
	var place := {"u": 1, "seed": 42, "x": 10.0, "y": 20.0, "z": -30.0}
	assert_true(QuestRules.finish(d, &"tilly_map", place))
	assert_true(d.quests.done.has("tilly_map"))
	assert_eq(d.quests.active, &"")
	assert_has(QuestRules.keepsakes(d), QuestRules.keepsake(&"tilly_map").id)
	assert_has(QuestRules.titles(d), QuestRules.title_id(&"tilly_map"))
	assert_eq(d.quests.places.size(), 1)
	assert_eq(d.quests.places[0].chain, "tilly_map")
	assert_false(QuestRules.finish(d, &"tilly_map", place), "done is done: no second reward")
	assert_eq(d.quests.places.size(), 1)
	assert_false(QuestRules.start(d, &"tilly_map"), "a finished story is not started again")


func test_a_chain_can_be_stopped_and_picked_up_later_without_losing_anything() -> void:
	var d := _data()
	QuestRules.start(d, &"tilly_pets")
	d.record(&"animal_tamed/dog", 1, 1)
	QuestRules.check(d)
	var step := QuestRules.step_index(d, &"tilly_pets")
	assert_eq(step, 1)
	QuestRules.stop(d)
	assert_eq(d.quests.active, &"")
	assert_true(QuestRules.is_started(d, &"tilly_pets"), "waiting where it was")
	d.record(&"monster_defeated/slime", 3, 1)
	assert_eq(QuestRules.check(d), [] as Array[Dictionary], "a stopped story waits: nothing moves on")
	assert_true(QuestRules.resume(d, &"tilly_pets"))
	assert_eq(QuestRules.step_index(d, &"tilly_pets"), step, "the same step")
	var p := QuestRules.step_progress(d, &"tilly_pets")
	assert_eq(p.x, 0, "counted again from the pick-up, never taken away")


func test_starting_another_chain_keeps_the_first_where_it_was() -> void:
	var d := _data()
	QuestRules.start(d, &"tilly_pets")
	d.record(&"animal_tamed/cat", 1, 1)
	QuestRules.check(d)
	d.record(&"monster_defeated/slime", 1, 1)
	assert_eq(QuestRules.step_progress(d, &"tilly_pets").x, 1)
	assert_true(QuestRules.start(d, &"tilly_map"))
	assert_eq(d.quests.active, &"tilly_map")
	assert_true(QuestRules.resume(d, &"tilly_pets"))
	assert_eq(QuestRules.step_progress(d, &"tilly_pets").x, 1, "the slime beaten before still counts")


func test_a_friends_help_adds_to_the_step() -> void:
	var d := _data()
	QuestRules.start(d, &"tilly_pets")
	d.record(&"animal_tamed/dog", 1, 1)
	QuestRules.check(d)
	assert_true(QuestRules.help(d, &"tilly_pets", &"monster_defeated/slime", 2))
	assert_eq(QuestRules.step_progress(d, &"tilly_pets").x, 2)
	assert_false(QuestRules.help(d, &"tilly_pets", &"photo_taken", 1), "help counts only what the step asks")
	assert_false(QuestRules.help(d, &"tilly_map", &"secret_found/treasure", 1), "only the chain being followed")


func test_a_chain_title_shows_on_the_name_tag() -> void:
	var t := QuestRules.title_id(&"zara_scarab")
	assert_true(QuestRules.is_title(t))
	assert_true(LevelRules.is_title(t))
	assert_eq(LevelRules.title_text(t), "Pyramid Pal")
	assert_eq(NameTag.text_for("Hop", "5:%s" % t), "Hop\nLv 5 Pyramid Pal")
	assert_false(QuestRules.is_title(&"q_no_such_chain"))
	assert_eq(NameTag.text_for("Hop", "5:q_no_such_chain"), "Hop\nLv 5 %s" % LevelRules.START_TITLE)


func test_a_saved_chain_title_counts_only_once_its_story_is_done() -> void:
	var t := String(QuestRules.title_id(&"tilly_map"))
	assert_eq(ProgressData.from_dict({"title": t}).title, &"", "not earned yet")
	assert_eq(ProgressData.from_dict({"title": t, "quests": {"done": ["tilly_map"]}}).title, StringName(t))


func test_matching_a_step_is_by_kind_or_family() -> void:
	assert_true(QuestRules.matches(&"monster_defeated/slime", &"monster_defeated/slime"))
	assert_true(QuestRules.matches(&"animal_tamed", &"animal_tamed/cat"))
	assert_false(QuestRules.matches(&"animal_tamed/dog", &"animal_tamed/cat"))
	assert_false(QuestRules.matches(&"monster_defeated/slime", &"monster_defeated"))


## Where a helper stands: by the spawn on dry, level ground, clear of Tilly's stall, the Totem and the hub
## circle, and never on the straight way from the spawn to them (the treasure pack keeps 60 blocks clear).
func test_a_helper_stands_near_the_spawn_off_the_ways() -> void:
	for u: int in [2, 3, 4]:
		for world_seed: int in [7, 42, 1234, 99991]:
			var shape := UniverseRegistry.shape_for(u, world_seed)
			var spawn := shape.spawn_column()
			var spot := QuestRules.giver_for_world(world_seed, shape, spawn)
			var p: Vector3 = spot.pos
			var d := Vector2(p.x - (spawn.x + 0.5), p.z - (spawn.y + 0.5)).length()
			assert_between(d, 12.0, 20.0, "u%d seed %d: near the spawn (%.1f)" % [u, world_seed, d])
			assert_lt(d, 60.0, "inside the treasure pack's clear zone")
			var marks := QuestRules.landmarks(world_seed, shape, spawn)
			for m: Vector3 in marks:
				assert_gte(Vector2(p.x - m.x, p.z - m.z).length(), QuestRules.CLEAR_OF - 0.01, "clear of a landmark")
				assert_gte(QuestRules.way_distance(Vector2(p.x, p.z), Vector2(spawn.x + 0.5, spawn.y + 0.5), Vector2(m.x, m.z)),
					QuestRules.WAY_CLEAR - 0.01, "u%d seed %d: off the way to %s" % [u, world_seed, m])
			assert_eq(QuestRules.giver_for_world(world_seed, shape, spawn), spot, "every game agrees")


func test_the_giver_spot_prefers_dry_level_ground() -> void:
	var flat := func(_x: int, _z: int) -> int: return 20
	var dry_east := func(x: int, _z: int) -> bool: return x > 10
	var no_trees := func(_x: int, _z: int) -> bool: return false
	var spot := QuestRules.giver_spot(5, Vector2i.ZERO, flat, dry_east, no_trees, [] as Array[Vector3])
	assert_gt((spot.pos as Vector3).x, 10.0, "on the dry side")
	assert_eq((spot.pos as Vector3).y, 20.0)


func _run_to_the_end(d: ProgressData, chain_id: StringName) -> void:
	QuestRules.start(d, chain_id)
	var u := QuestRules.universe_of(chain_id)
	for i in 8:
		var s := QuestRules.current_step(d, chain_id)
		if s.is_empty():
			return
		match s.type:
			QuestRules.DO:
				d.record(s.kind, int(s.need), u)
				QuestRules.check(d)
			_:
				QuestRules.arrive(d, chain_id, s.type)


## Nell's stories (the Dragon Realm, owner #39) are made of the realm's own things: its monsters (shadow bats, wisps)
## and the secrets its islands hold, so every step can be done there.
func test_nells_stories_use_only_the_dragon_realms_monsters_and_secrets() -> void:
	var chains := QuestRules.chains_of(&"nell")
	assert_eq(chains.size(), 2)
	for id: StringName in chains:
		var c := QuestRules.chain(id)
		for s: Dictionary in c.steps:
			var kind := String(s.get("kind", ""))
			if kind.begins_with("monster_defeated/"):
				assert_true(MonsterRules.DRAGON_KINDS.has(StringName(kind.get_slice("/", 1))), "%s: %s" % [c.id, kind])
			elif kind.begins_with("secret_found/"):
				assert_true(SecretRules.PLACED.has(StringName(kind.get_slice("/", 1))), "%s: %s" % [c.id, kind])
			if s.has("find"):
				assert_true(SecretRules.PLACED.has(s.find), "%s: the arrow shows %s" % [c.id, s.find])
	assert_eq(QuestRules.in_universe(5), "in the Dragon Realm")


## Universe 6, the Glow Caves: Mira the cave guide tells two stories made of the caves' own monsters and secrets.
func test_miras_stories_use_only_the_glow_caves_monsters_and_secrets() -> void:
	assert_eq(QuestRules.giver_in(6), &"mira")
	var chains := QuestRules.chains_of(&"mira")
	assert_eq(chains.size(), 2)
	for id: StringName in chains:
		var c := QuestRules.chain(id)
		for s: Dictionary in c.steps:
			var kind := String(s.get("kind", ""))
			if kind.begins_with("monster_defeated/"):
				assert_true(MonsterRules.GLOW_KINDS.has(StringName(kind.get_slice("/", 1))), "%s: %s" % [c.id, kind])
			elif kind.begins_with("secret_found/"):
				assert_true(SecretRules.PLACED.has(StringName(kind.get_slice("/", 1))), "%s: %s" % [c.id, kind])
			if s.has("find"):
				assert_true(SecretRules.PLACED.has(s.find), "%s: the arrow shows %s" % [c.id, s.find])
	assert_eq(QuestRules.in_universe(6), "in the Glow Caves")
