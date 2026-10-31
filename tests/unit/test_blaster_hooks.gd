extends GutTest
## M3 Task 14b: the small hooks the blasters need elsewhere: monsters count a blaster as a ranged weapon
## (their tactics), items have their rarity, /give knows them, and every blaster sound exists.


func test_monsters_see_a_blaster_as_a_ranged_weapon() -> void:
	for id in ItemIds.BLASTERS:
		assert_eq(MonsterSpecies.weapon_class(id), MonsterSpecies.RANGED, ItemIds.display_name(id))
	assert_eq(MonsterSpecies.weapon_class(ItemIds.SWORD), MonsterSpecies.MELEE, "unchanged")


func test_blasters_and_ammo_have_their_rarity() -> void:
	for id in ItemIds.BLASTERS + ItemIds.AMMO:
		assert_eq(ItemRarity.of_item(id), BlasterRules.rarity(id), ItemIds.display_name(id))
	assert_eq(ItemRarity.of_item(ItemIds.SWORD_IRON), ItemRarity.RARE, "tiers unchanged")
	assert_eq(ItemRarity.of_item(BlockIds.DIRT), -1)


func test_give_knows_the_blasters() -> void:
	assert_eq(ChatCommands.item_for_name("foam blaster"), ItemIds.FOAM_BLASTER)
	assert_eq(ChatCommands.item_for_name("confetti rocket"), ItemIds.CONFETTI_ROCKET)
	assert_eq(ChatCommands.item_for_name("party rockets"), ItemIds.PARTY_ROCKETS)


func test_every_blaster_sound_exists() -> void:
	for b in ItemIds.BLASTERS:
		var s := BlasterRules.sound(b)
		assert_true(Audio.SOUNDS.has(s), "%s: %s" % [ItemIds.display_name(b), s])
	for s: StringName in [&"bubble_pop", &"confetti_boom", &"party_horn", &"pinata_burst", &"splat", &"snow_splat"]:
		assert_true(Audio.SOUNDS.has(s), String(s))
