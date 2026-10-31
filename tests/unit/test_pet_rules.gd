extends GutTest
## Pets with perks (M3 Task 11, spec §14.7, §5.9): the kinds of pet (an easy table to extend: the baby
## dragon of owner #39 is one more row), treats 430-434, the happiness heart (never needed, never
## punishing), names (a list for everyone; a typed name through the username filter for 13+ only),
## collars (8 colours) and Pip the robot, who lives in the profile and follows the child between worlds.


# --- Kinds ---

func test_every_kind_has_a_body_perks_a_way_to_become_a_pet_and_a_favourite_treat() -> void:
	for kind: StringName in PetRules.KINDS:
		assert_true(AnimalRules.SPECIES.has(kind), "%s has an animal body" % kind)
		assert_true(BlockyAnimal.COLLAR.has(kind), "%s wears a collar" % kind)
		assert_true(AnimalSpecies.TRAITS.has(kind), "%s has mind traits" % kind)
		var row: Dictionary = PetRules.KINDS[kind]
		assert_true(row.tame in [PetRules.BY_PETS, PetRules.BY_TREATS, PetRules.GIVEN, PetRules.BY_WAND], str(kind))   # M3 Task 20b: the wand befriends
		assert_false((row.perks as Array).is_empty(), "%s has a perk" % kind)
		for perk: StringName in row.perks:
			assert_true(PetRules.PERKS.has(perk), "%s: %s is a known perk" % [kind, perk])
		assert_true(ItemIds.TREATS.has(int(row.favourite)), "%s has a favourite treat" % kind)


func test_the_perks_of_each_kind() -> void:
	assert_true(PetRules.has_perk(&"cat", PetRules.GLOW))
	assert_true(PetRules.has_perk(&"dog", PetRules.COINS))
	assert_true(PetRules.has_perk(&"dog", PetRules.BARK))
	assert_true(PetRules.has_perk(&"dog", PetRules.SNIFF))
	assert_true(PetRules.has_perk(&"fox", PetRules.SNIFF))
	assert_true(PetRules.has_perk(&"parrot", PetRules.ECHO))
	assert_true(PetRules.has_perk(&"parrot", PetRules.POINT))
	assert_true(PetRules.has_perk(&"pip", PetRules.GLOW), "Pip's lamp lights the way")
	assert_false(PetRules.has_perk(&"cat", PetRules.BARK))
	assert_false(PetRules.has_perk(&"sheep", PetRules.GLOW), "farm animals are never pets")
	assert_false(PetRules.is_pet_kind(&"cow"))


func test_the_fox_sniffs_more_often_than_the_dog() -> void:
	assert_lt(PetRules.sniff_every(&"fox"), PetRules.sniff_every(&"dog"))
	assert_eq(PetRules.sniff_every(&"dog"), TreasureSniff.EVERY, "the dog keeps M2 Task 17's pace")
	assert_gt(PetRules.sniff_pace(&"fox"), PetRules.sniff_pace(&"dog"), "and trots there faster")
	assert_true(PetRules.digs(&"fox"), "the fox digs a little dirt puff")
	assert_eq(PetRules.sniff_every(&"cat"), INF, "cats don't sniff out treasure")


func test_how_each_kind_becomes_a_pet() -> void:
	assert_true(PetRules.tames_by_petting(&"dog"))
	assert_true(PetRules.tames_by_petting(&"cat"))
	assert_false(PetRules.tames_by_petting(&"fox"), "a fox wants treats")
	assert_true(PetRules.tames_by_treats(&"fox"))
	assert_true(PetRules.tames_by_treats(&"parrot"))
	assert_false(PetRules.tames_by_petting(&"pip"), "Pip is a gift")
	assert_false(PetRules.tames_by_treats(&"pip"))
	assert_false(PetRules.tames_by_treats(&"cow"))
	assert_true(AnimalRules.SPECIES[&"fox"].tameable)
	assert_true(AnimalRules.SPECIES[&"parrot"].tameable)
	assert_false(AnimalRules.SPECIES[&"pip"].tameable, "never tamed in the wild")


func test_taming_by_treats_takes_a_few_from_the_same_child() -> void:
	var fed := {}
	assert_false(PetRules.treat_tames(fed, 7), "one treat is a start")
	assert_false(PetRules.treat_tames(fed, 9), "another child's treat counts for them")
	assert_true(PetRules.treat_tames(fed, 7), "the second from the same child tames it")
	assert_eq(PetRules.TREATS_TO_TAME, 2)


func test_pip_never_counts_toward_the_pet_cap() -> void:
	assert_true(PetRules.counts_toward_cap(&"dog"))
	assert_true(PetRules.counts_toward_cap(&"parrot"))
	assert_false(PetRules.counts_toward_cap(&"pip"))


func test_pips_never_wild() -> void:
	assert_eq(int(AnimalRules.SPECIES[&"pip"].weight), 0)
	for s in _spawns(10):
		assert_ne(s.species, &"pip")


# --- Treats ---

func test_treats_are_items_430_to_434() -> void:
	assert_eq(ItemIds.TREATS, [430, 431, 432, 433, 434] as Array[int])
	for id in ItemIds.TREATS:
		assert_true(PetRules.is_treat(id))
		assert_true(ItemIds.is_item(id))
		assert_true(ItemIds.is_hotbar_valid(id))
		assert_false(BlockIds.is_valid(id), "never a block")
		assert_ne(ItemIds.display_name(id), "")
		assert_true(Inventory.ownable(id), "a Survivor bag holds treats")
	assert_false(PetRules.is_treat(BlockIds.GRASS), "grass is Task 18's animal snack, not a pet treat")
	assert_false(PetRules.is_treat(ItemIds.SWORD))


func test_tilly_sells_treats_cheaply() -> void:
	for id in ItemIds.TREATS:
		assert_between(ShopRules.price(id), 1, 5, "cheap")
		assert_true(ShopRules.catalog(ShopRules.POTIONS).has(id), "on Tilly's potions and treats shelf")
		assert_false(ShopRules.SELL_PRICES.has(id), "never sold back (no gold loop)")


# --- The happiness heart ---

func test_petting_and_treats_raise_the_heart() -> void:
	var h := PetRules.HAPPY_START
	assert_gt(PetRules.after_pat(h), h)
	assert_gt(PetRules.after_treat(h, &"dog", ItemIds.TREAT_FISH), PetRules.after_pat(h), "a treat more than a pat")
	assert_gt(PetRules.after_treat(h, &"dog", ItemIds.TREAT_BISCUIT), PetRules.after_treat(h, &"dog", ItemIds.TREAT_FISH),
		"its favourite most")
	assert_eq(PetRules.after_treat(0.99, &"cat", ItemIds.TREAT_FISH), 1.0, "a full heart stays full")


func test_the_heart_falls_slowly_while_playing_and_never_below_the_floor() -> void:
	var h := 1.0
	h = PetRules.after_time(h, 60.0)
	assert_almost_eq(h, 1.0 - PetRules.FALL_PER_MINUTE, 0.0001, "a minute takes a little")
	assert_gt(PetRules.after_time(1.0, 20.0 * 60.0), 0.7, "twenty minutes still leave a big heart")
	assert_eq(PetRules.after_time(1.0, 100000.0), PetRules.HAPPY_FLOOR, "never below the floor")
	assert_gt(PetRules.HAPPY_FLOOR, 0.0, "never an empty heart")
	assert_eq(PetRules.after_time(0.1, 60.0), PetRules.HAPPY_FLOOR)
	assert_eq(PetRules.after_time(0.5, -60.0), 0.5, "time never runs backwards into happiness")


func test_a_sad_pet_just_shows_a_smaller_heart_and_plays_a_little_less() -> void:
	var low := PetRules.HAPPY_FLOOR
	assert_lt(PetRules.heart_scale(low), PetRules.heart_scale(1.0))
	assert_gte(PetRules.heart_scale(low), 0.5, "still a heart you can see")
	assert_lt(PetRules.play_factor(low), PetRules.play_factor(1.0))
	assert_gte(PetRules.play_factor(low), 0.5, "it still plays")
	assert_true(PetRules.follows(low), "it never leaves")
	assert_true(PetRules.obeys(low), "it never refuses")
	assert_true(PetRules.perks_work(low), "its perk always works")


func test_the_heart_syncs_in_small_steps() -> void:
	assert_eq(PetRules.synced(0.712), 0.7)
	assert_eq(PetRules.synced(0.726), 0.75)
	assert_eq(PetRules.synced(0.0), PetRules.HAPPY_FLOOR)


func test_saved_happiness_is_cleaned() -> void:
	assert_eq(PetRules.clean_happiness(0.8), 0.8)
	assert_eq(PetRules.clean_happiness(5.0), 1.0)
	assert_eq(PetRules.clean_happiness(-2.0), PetRules.HAPPY_FLOOR)
	assert_eq(PetRules.clean_happiness("lots"), PetRules.HAPPY_START)
	assert_eq(PetRules.clean_happiness(NAN), PetRules.HAPPY_START)
	assert_eq(PetRules.clean_happiness(null), PetRules.HAPPY_START)


# --- Names ---

func test_a_new_pet_gets_a_fun_name_and_pip_is_pip() -> void:
	assert_true(PetRules.FUN_NAMES.has(PetRules.first_name(&"dog", "a1_2_0")))
	assert_eq(PetRules.first_name(&"dog", "a1_2_0"), PetRules.first_name(&"dog", "a1_2_0"), "the same animal, the same name")
	assert_eq(PetRules.first_name(&"pip", "pip_1"), "Pip")
	assert_gte(PetRules.FUN_NAMES.size(), 24)


func test_every_name_on_the_list_passes_the_username_filter() -> void:
	for n in PetRules.FUN_NAMES:
		assert_eq(UsernameRules.validate(n), "", n)
		assert_lte(n.length(), PetRules.MAX_NAME)
		assert_false(BotRules.NAMES.has(n), "a pet is never named like a bot friend: %s" % n)
	assert_eq(Animal.PET_NAMES, PetRules.FUN_NAMES, "M1b's pet names are the list")


func test_under_13_players_pick_from_the_list_only() -> void:
	assert_eq(PetRules.name_refusal("Biscuit", AgeBand.UNDER_13), "")
	assert_eq(PetRules.name_refusal("Sparkles", AgeBand.UNDER_13), "list_only")
	assert_eq(PetRules.name_refusal("Sparkles", &""), "list_only", "no band: the under-13 rules")
	assert_ne(PetRules.name_message("list_only"), "")


func test_13_plus_players_may_type_a_name_through_the_filter() -> void:
	assert_eq(PetRules.name_refusal("Sparkles", AgeBand.TEEN_PLUS), "")
	assert_eq(PetRules.name_refusal("Biscuit", AgeBand.TEEN_PLUS), "")
	assert_eq(PetRules.name_refusal("stupiddog", AgeBand.TEEN_PLUS), "blocked_word")
	assert_eq(PetRules.name_refusal("a", AgeBand.TEEN_PLUS), "too_short")
	assert_eq(PetRules.name_refusal("Call 5551234567", AgeBand.TEEN_PLUS), "bad_chars")
	assert_eq(PetRules.name_refusal("  Sparkles  ", AgeBand.TEEN_PLUS), "", "spaces round it are trimmed")
	assert_eq(PetRules.clean_name("  Sparkles  "), "Sparkles")


func test_a_saved_name_that_is_not_allowed_becomes_a_fun_name() -> void:
	assert_eq(PetRules.saved_name("Luna", &"cat", "p1"), "Luna")
	assert_true(PetRules.FUN_NAMES.has(PetRules.saved_name("killer", &"cat", "p1")), "a hand-edited save")
	assert_true(PetRules.FUN_NAMES.has(PetRules.saved_name("", &"cat", "p1")))
	assert_eq(PetRules.saved_name("", &"pip", "pip_1"), "Pip")


# --- Collars ---

func test_eight_collar_colours_or_the_owners_own() -> void:
	assert_eq(PetRules.COLLARS.size(), 8)
	for i in 8:
		assert_true(PetRules.valid_collar(i))
		assert_eq(PetRules.collar_color(i, 5), PetRules.COLLARS[i])
	assert_false(PetRules.valid_collar(8))
	assert_false(PetRules.valid_collar(-2))
	assert_eq(PetRules.collar_color(PetRules.OWNER_COLOUR, 3), AnimalRules.collar_color(3), "unchosen: the owner's colour")
	assert_eq(PetRules.clean_collar(12), PetRules.OWNER_COLOUR)
	assert_eq(PetRules.clean_collar("red"), PetRules.OWNER_COLOUR)
	assert_eq(PetRules.clean_collar(4.0), 4)


# --- Pip the robot (M3 Task 15's tutorial gives him) ---

func test_give_pip_puts_pip_in_the_profile_once() -> void:
	var p := ProfileData.new()
	assert_true(p.pip.is_empty(), "no Pip before the tutorial")
	assert_true(PetRules.give_pip(p))
	assert_eq(p.pip.name, "Pip")
	assert_eq(int(p.pip.collar), PetRules.OWNER_COLOUR)
	assert_eq(float(p.pip.happiness), PetRules.HAPPY_START)
	p.pip.name = "Bolt"
	assert_false(PetRules.give_pip(p), "only once")
	assert_eq(p.pip.name, "Bolt", "and never reset")


func test_pip_is_saved_with_the_profile_and_cleaned() -> void:
	var p := ProfileData.new()
	PetRules.give_pip(p)
	p.pip = PetRules.pip_record("Bolt", 3, 0.9)
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.pip, p.pip)
	assert_eq(PetRules.clean_pip({"name": "killer", "collar": 99, "happiness": "x"}),
		{"name": "Pip", "collar": PetRules.OWNER_COLOUR, "happiness": PetRules.HAPPY_START})
	assert_eq(PetRules.clean_pip("junk"), {})
	assert_eq(PetRules.clean_pip({}), {})
	assert_eq(ProfileData.from_json("{\"pip\": 5}").pip, {})


func test_a_profile_backup_never_loses_pip() -> void:
	var local := ProfileData.new()
	local.username = "Ana"
	PetRules.give_pip(local)
	local.updated_at = 100
	var remote := ProfileData.new()
	remote.username = "Ana"
	remote.survivor_gold = 500
	remote.updated_at = 200
	var merged: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(remote)).profile
	assert_eq(merged.pip.name, "Pip", "the newer backup had no Pip: the phone's Pip stays")
	assert_false(ProfileBackup.is_new(local), "a child with Pip has progress")


func _spawns(cells: int) -> Array[Dictionary]:
	var shape := MeadowsShape.new(12345)
	var all: Array[Dictionary] = []
	for cx in range(-cells, cells):
		for cz in range(-cells, cells):
			all.append_array(AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz)))
	return all


# --- Wild foxes and parrots ---

func test_wild_foxes_live_by_the_woods_and_parrots_by_the_water() -> void:
	var shape := MeadowsShape.new(12345)
	var foxes := 0
	var parrots := 0
	for cx in range(-16, 16):
		for cz in range(-16, 16):
			var cell := Vector2i(cx, cz)
			for s: Dictionary in AnimalRules.spawns_for_cell(shape, cell):
				if s.species == &"fox" or s.species == &"parrot":
					var p: Vector3 = s.pos
					assert_eq(shape.column_block(shape.height_at(floori(p.x), floori(p.z)) - 1, shape.height_at(floori(p.x), floori(p.z))),
						BlockIds.GRASS, "%s stands on grass" % s.species)
				if s.species == &"fox":
					foxes += 1
				elif s.species == &"parrot":
					parrots += 1
	assert_gt(foxes, 0, "some foxes by the woods")
	assert_gt(parrots, 0, "some parrots by the water")


func test_the_wild_pets_never_change_the_other_herds() -> void:
	var shape := MeadowsShape.new(12345)
	for cx in range(-8, 8):
		for cz in range(-8, 8):
			var cell := Vector2i(cx, cz)
			var center := cell * AnimalRules.CELL + Vector2i(16, 16)
			var kept := AnimalRules.wild_pet_at(shape, cell, center, &"sheep")
			assert_true(kept in [&"sheep", &"fox", &"parrot"])
			assert_eq(AnimalRules.wild_pet_at(shape, cell, center, &"fish"), &"fish", "fish stay fish")


func test_summon_pip_and_the_new_kinds_are_known_to_the_chat() -> void:
	for kind in ["fox", "parrot", "pip"]:
		var cmd := ChatCommands.parse("/summon %s" % kind)
		assert_eq(cmd.get("species"), StringName(kind), kind)


func test_give_puts_a_treat_in_the_hand_in_sandbox() -> void:
	for id in ItemIds.TREATS:
		var cmd := ChatCommands.parse("/give %s" % ItemIds.display_name(id))
		assert_eq(cmd.get("id"), id, ItemIds.display_name(id))
	assert_true(ChatCommands.giveable_ids().has(ItemIds.TREAT_BOLT))
