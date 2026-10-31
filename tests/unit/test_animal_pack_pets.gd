extends GutTest
## Owner feedback #41's pets (spec §14.19 with §14.7's table): a horse and a camel (two treats, then a saddle to
## ride), a donkey (two treats; it carries a chest of 9 slots), a fennec fox and an arctic fox (two treats; they
## sniff out treasure like the fox). The donkey's chest as pure rules, and the chat's /summon for every new kind.


func test_the_new_pets_are_tamed_with_two_treats() -> void:
	for kind: StringName in [&"horse", &"camel", &"donkey", &"fennec", &"arctic_fox"]:
		assert_true(PetRules.is_pet_kind(kind), str(kind))
		assert_true(PetRules.tames_by_treats(kind), "%s wants treats" % kind)
		assert_false(PetRules.tames_by_petting(kind), str(kind))
		assert_true(AnimalRules.SPECIES[kind].tameable, str(kind))
		assert_true(PetRules.counts_toward_cap(kind), "%s is one of a child's 3 pets" % kind)
	assert_eq(PetRules.favourite(&"horse"), ItemIds.TREAT_BERRIES, "a horse's apple: the berries")
	assert_eq(PetRules.favourite(&"camel"), ItemIds.TREAT_SEEDS, "a camel's grain: the seed cracker")


func test_what_each_new_pet_does() -> void:
	assert_true(PetRules.has_perk(&"horse", PetRules.RIDE), "a horse is ridden")
	assert_true(PetRules.has_perk(&"camel", PetRules.RIDE))
	assert_true(PetRules.has_perk(&"donkey", PetRules.CHEST), "a donkey carries a chest")
	assert_true(PetRules.has_perk(&"fennec", PetRules.SNIFF), "a fennec sniffs out treasure")
	assert_true(PetRules.has_perk(&"arctic_fox", PetRules.SNIFF))
	assert_true(PetRules.digs(&"arctic_fox"), "and digs like the fox")
	assert_false(PetRules.is_pet_kind(&"penguin"), "wild animals stay wild")
	assert_false(PetRules.is_pet_kind(&"goat"))


func test_the_arctic_fox_and_the_fennec_are_foxes_of_their_own() -> void:
	assert_ne(AnimalRules.SPECIES[&"arctic_fox"].colors[0], AnimalRules.SPECIES[&"fox"].colors[0], "white, not orange")
	assert_true(UniverseRegistry.animals(3).has(&"arctic_fox"), "Frostpeak's")
	assert_false(UniverseRegistry.animals(3).has(&"fox"), "Green Meadows' fox stays at home")
	assert_true(UniverseRegistry.animals(2).has(&"fennec"), "the desert's")
	assert_eq(PetRules.sniff_every(&"arctic_fox"), PetRules.sniff_every(&"fox"), "the same nose")


# --- The donkey's chest ---

func test_a_chest_has_nine_slots_of_up_to_99() -> void:
	var chest := DonkeyChest.clean([])
	assert_eq(chest.size(), DonkeyChest.SLOTS * 2)
	assert_eq(DonkeyChest.SLOTS, 9)
	assert_true(DonkeyChest.is_empty(chest))
	var r := DonkeyChest.put(chest, BlockIds.PLANKS, 150)
	assert_eq(r.moved, 150, "into two slots")
	assert_eq(DonkeyChest.slot(r.chest, 0), Vector2i(BlockIds.PLANKS, 99))
	assert_eq(DonkeyChest.slot(r.chest, 1), Vector2i(BlockIds.PLANKS, 51))
	r = DonkeyChest.put(r.chest, BlockIds.PLANKS, 10)
	assert_eq(DonkeyChest.slot(r.chest, 1), Vector2i(BlockIds.PLANKS, 61), "tops up its own kind first")
	r = DonkeyChest.put(r.chest, BlockIds.STONE, 5)
	assert_eq(DonkeyChest.slot(r.chest, 2), Vector2i(BlockIds.STONE, 5))


func test_a_full_chest_takes_only_what_fits() -> void:
	var chest := DonkeyChest.clean([])
	for i in 9:
		chest = DonkeyChest.put(chest, BlockIds.DIRT, 99).chest
	assert_eq(DonkeyChest.room_for(chest, BlockIds.DIRT), 0)
	var r := DonkeyChest.put(chest, BlockIds.STONE, 10)
	assert_eq(r.moved, 0, "no room")


func test_taking_a_slot_takes_it_whole() -> void:
	var chest: PackedInt32Array = DonkeyChest.put(DonkeyChest.clean([]), BlockIds.GLASS, 7).chest
	var r := DonkeyChest.take(chest, 0)
	assert_eq(r.id, BlockIds.GLASS)
	assert_eq(r.count, 7)
	assert_true(DonkeyChest.is_empty(r.chest))
	assert_eq(DonkeyChest.take(r.chest, 0).count, 0, "an empty slot gives nothing")
	assert_eq(DonkeyChest.take(chest, 12).count, 0, "no slot 12")


func test_only_real_things_go_in_and_a_bad_save_is_cleaned() -> void:
	assert_eq(DonkeyChest.put(DonkeyChest.clean([]), BlockIds.BEDROCK, 5).moved, 0, "never bedrock")
	assert_eq(DonkeyChest.put(DonkeyChest.clean([]), 9999, 5).moved, 0, "never an unknown id")
	var bad := DonkeyChest.clean([BlockIds.STONE, 500, "x", 3, BlockIds.BEDROCK, 4, NAN, 2])
	assert_eq(DonkeyChest.slot(bad, 0), Vector2i(BlockIds.STONE, 99), "capped")
	assert_eq(DonkeyChest.slot(bad, 1), Vector2i.ZERO)
	assert_eq(DonkeyChest.slot(bad, 2), Vector2i.ZERO)
	assert_eq(DonkeyChest.slot(bad, 3), Vector2i.ZERO)
	assert_true(DonkeyChest.is_empty(DonkeyChest.clean("junk")))


# --- Saves ---

func test_a_saddle_and_a_donkeys_chest_are_saved_with_the_world() -> void:
	var m := WorldMeta.new()
	m.pets = [{"species": "horse", "name": "Maple", "pos": [1.0, 40.0, 2.0], "id": "a1_1_0", "saddled": true},
		{"species": "donkey", "name": "Daisy", "pos": [3.0, 40.0, 2.0], "id": "a2_1_0",
			"chest": [BlockIds.PLANKS, 40, BlockIds.GLASS, 3]}]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.pets.size(), 2)
	assert_true(back.pets[0].get("saddled", false), "the horse keeps its saddle")
	var chest := DonkeyChest.clean(back.pets[1].get("chest"))
	assert_eq(DonkeyChest.slot(chest, 0), Vector2i(BlockIds.PLANKS, 40), "the donkey keeps what it carries")
	assert_eq(DonkeyChest.slot(chest, 1), Vector2i(BlockIds.GLASS, 3))


func test_a_hand_edited_save_never_saddles_a_donkey_nor_fills_a_horse() -> void:
	var m := WorldMeta.from_json('{"pets":[{"species":"donkey","name":"Daisy","pos":[1,2,3],"id":"p1","saddled":true},'
		+ '{"species":"horse","name":"Maple","pos":[1,2,3],"id":"p2","saddled":"yes","chest":[1,5]}]}')
	assert_eq(m.pets.size(), 2)
	assert_false(m.pets[0].has("saddled"), "a donkey takes no saddle")
	assert_false(m.pets[1].has("saddled"), "only a real true")
	assert_false(m.pets[1].has("chest"), "a horse carries no chest")


# --- The chat ---

func test_summon_knows_every_new_animal() -> void:
	for kind in ["horse", "donkey", "goat", "deer", "duck", "frog", "turtle", "squirrel", "owl", "hedgehog", "camel",
			"lizard", "fennec", "penguin", "polar_bear", "arctic_fox", "seal", "gummy_bunny", "candy_bird"]:
		assert_eq(ChatCommands.parse("/summon %s" % kind).get("species"), StringName(kind), kind)
