extends GutTest
## Owner #45a (spec §14.17): at least 30 more picture goals on the adventure board, in every universe and
## mode: the desert, Frostpeak, Candy, crafting, Monster Wave, pets, the #41 animals, the #42 treasures, races,
## building and quests. Every goal counts a kind something in the game really raises (the integration tests
## raise each new one through the real code), says where its counter can rise, and a goal only the Sandbox
## can finish never pays gold.

## Every family a board goal counts, and where the real code raises it (proof in the named tests).
const RAISED_BY := {
	&"monster_defeated": "ProgressDirector.watch_host (test_progress_director)",
	&"secret_found": "the sandbox's SecretDirector.found_shown (test_progress_director, test_quest_counters)",
	&"block_placed": "Session.progress_placed (test_progress_bus)",
	&"wave_won": "ProgressDirector.watch_host (test_quest_counters: the arena's waves)",
	&"boss_beaten": "ProgressDirector.watch_host (test_quest_counters: the real boss)",
	&"buddy_woken": "sandbox._on_spark",
	&"animal_tamed": "sandbox._on_pet, PetDirector.on_treat (test_quest_counters)",
	&"photo_taken": "PhotoMode.photo_saved",
	&"race_finished": "CourseDirector (test_quest_counters: the medal)",
	&"friend_played": "ProgressDirector._meet_friends",
	&"area_explored": "ProgressDirector._explore (test_quest_counters: the universe)",
	&"item_crafted": "Session.host_craft (test_quest_counters)",
	&"pet_fed": "PetDirector.on_treat (test_quest_counters)",
	&"buddy_ridden": "RideDirector.host_ride (test_quest_counters)",
	&"quest_done": "QuestDirector (test_quest_director)",
}
const OLD_GOALS := 23


func test_at_least_thirty_new_goals_each_a_picture_and_four_words() -> void:
	assert_gte(BoardRules.GOALS.size(), OLD_GOALS + 30)
	var ids := {}
	for g: Dictionary in BoardRules.GOALS:
		assert_false(ids.has(g.id), "one of each: %s" % g.id)
		ids[g.id] = true
		assert_lte(str(g.words).split(" ").size(), 4, str(g.words))
		assert_true(ProgressPictures.knows(g.picture), "%s has a picture" % g.id)
		assert_true(LevelRules.is_kind(g.kind), "%s counts a real event" % g.id)
		assert_true(RAISED_BY.has(LevelRules.family(g.kind)), "%s: something raises %s" % [g.id, g.kind])
		for m: StringName in BoardRules.modes_of(g.id):
			assert_has(ModeRules.MODES, m, "%s: a real mode" % g.id)
		var u := BoardRules.universe_of(g.id)
		assert_between(u, 0, UniverseRegistry.size(), "%s: anywhere or a real universe" % g.id)


func test_every_theme_of_the_owner_has_goals() -> void:
	var families := {}
	var universes := {}
	var wave_only := 0
	var treasure := 0
	for g: Dictionary in BoardRules.GOALS:
		families[LevelRules.family(g.kind)] = true
		universes[BoardRules.universe_of(g.id)] = true
		if BoardRules.modes_of(g.id) == ([ModeRules.WAVE] as Array[StringName]):
			wave_only += 1
		if TreasurePlaces.KINDS.has(StringName(String(g.kind).get_slice("/", 1))):
			treasure += 1
	for u in [2, 3, 4]:
		assert_true(universes.has(u), "goals in universe %d" % u)
	for f: StringName in [LevelRules.CRAFTED, LevelRules.FED, LevelRules.RIDDEN, LevelRules.QUEST_DONE, LevelRules.RACE]:
		assert_true(families.has(f), "goals for %s" % f)
	assert_gte(wave_only, 2, "Monster Wave goals")
	assert_gte(treasure, 5, "the #42 treasures")
	for species: StringName in [&"fox", &"parrot"]:
		assert_false(BoardRules.goal(StringName("tame_" + species)).is_empty(), "a goal for the %s" % species)


## Research §1.8 as before, and the owner's rule: a Sandbox-only goal never pays Survivor gold.
func test_creative_and_sandbox_only_goals_pay_no_gold() -> void:
	for g: Dictionary in BoardRules.GOALS:
		var f := LevelRules.family(g.kind)
		if f in [LevelRules.BLOCK, LevelRules.BUDDY, LevelRules.PHOTO, LevelRules.FRIEND, LevelRules.FED,
				LevelRules.RIDDEN, LevelRules.QUEST_DONE]:
			assert_eq(BoardRules.gold_for(g.id), 0, "%s is its own reward" % g.id)
		else:
			assert_gt(BoardRules.gold_for(g.id), 0, "%s pays a little gold in Survivor" % g.id)
		if BoardRules.modes_of(g.id) == ([ModeRules.SANDBOX] as Array[StringName]):
			assert_eq(BoardRules.gold_for(g.id), 0, "%s: Sandbox only, no gold" % g.id)


func test_a_goal_of_a_universe_counts_only_there() -> void:
	var d := ProgressData.new()
	BoardRules.ensure_board(d)
	assert_true(BoardRules.pick(d, 0, &"desert_secrets"))
	d.record(&"secret_found/geode", 2, 1)
	assert_eq(BoardRules.progress(d, 0), Vector2i(0, 3), "meadows secrets are not desert ones")
	d.record(&"secret_found/geode", 1, 2)
	d.record(&"secret_found/temple", 1, 2)
	assert_eq(BoardRules.progress(d, 0), Vector2i(2, 3))
	d.record(&"secret_found/room", 1, 2)
	assert_has(BoardRules.check(d), &"desert_secrets")


func test_goals_count_from_the_pick_in_their_universe_too() -> void:
	var d := ProgressData.new()
	BoardRules.ensure_board(d)
	d.record(&"monster_defeated/yeti", 2, 3)
	BoardRules.pick(d, 1, &"beat_yetis")
	assert_eq(BoardRules.progress(d, 1), Vector2i(0, 3), "the yetis beaten before the pick don't count")


## The #41 animals come in their own pack: their goals are listed only once that animal is in the game.
func test_goals_for_animals_not_in_the_game_yet_wait() -> void:
	var d := ProgressData.new()
	BoardRules.ensure_board(d)
	var gated := 0
	for g: Dictionary in BoardRules.GOALS:
		if g.has("species"):
			gated += 1
			assert_eq(g.kind, StringName("animal_tamed/%s" % g.species), "%s counts that animal" % g.id)
			assert_eq(BoardRules.available(g.id), AnimalRules.SPECIES.has(g.species))
			if not AnimalRules.SPECIES.has(g.species):
				assert_does_not_have(BoardRules.choices(d), g.id, "%s waits for the animal" % g.id)
				assert_false(BoardRules.pick(d, 0, g.id))
	assert_gte(gated, 3, "goals ready for the #41 animals")
	assert_true(BoardRules.available(&"tame_fox"), "the fox is in the game")


func test_the_list_offers_every_available_goal_not_on_the_board() -> void:
	var d := ProgressData.new()
	BoardRules.ensure_board(d)
	var available := 0
	for g: Dictionary in BoardRules.GOALS:
		if BoardRules.available(g.id):
			available += 1
	assert_eq(BoardRules.choices(d).size(), available - BoardRules.SLOTS)


func test_new_families_give_xp_and_belong_to_a_style() -> void:
	assert_eq(LevelRules.xp_for(&"item_crafted/glass"), 10)
	assert_eq(LevelRules.xp_for(&"pet_fed/fox"), 5)
	assert_eq(LevelRules.xp_for(&"buddy_ridden/fly"), 10)
	assert_eq(LevelRules.xp_for(&"quest_step"), 20)
	assert_eq(LevelRules.xp_for(&"quest_done/tilly_map"), 100)
	assert_eq(LevelRules.style_of(&"item_crafted"), &"crafter")
	assert_eq(LevelRules.style_of(&"pet_fed"), &"animals")
	assert_eq(LevelRules.style_of(&"buddy_ridden"), &"magic")
	assert_eq(LevelRules.style_of(&"quest_done"), &"quester")
	assert_eq(LevelRules.title_text(&"crafter"), "Master Crafter")
	assert_eq(LevelRules.title_text(&"quester"), "Quest Hero")
