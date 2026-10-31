extends GutTest
## Universe 6, the Glow Caves (spec §5.1): its descriptor (world/universes/glow.gd), read the way M3 Task 5's
## UniverseRegistry reads every universe file, and the ladder it joins: meadows, desert, frost, candy, dragon, glow.
## The Dragon Realm's boss portal now leads to the Glow Caves, whose own leads to the hub (the last universe); the caves
## come with EasyCraft Plus while the build has a store; their crystal (485) opens a portal you build (core 223).

const PATH := "res://world/universes/glow.gd"

var d: Object


func before_all() -> void:
	d = load(PATH).new()


func after_each() -> void:
	UniverseRegistry.reset()


func test_it_is_universe_6_the_glow_caves() -> void:
	assert_eq(d.get("name"), &"glow", "world/universes/<name>.gd")
	assert_eq(d.get("display_name"), "Glow Caves")
	assert_eq(d.get("index"), 6)
	assert_eq(d.get("monster_kinds"), MonsterRules.GLOW_KINDS)
	assert_eq(d.get("boss_kind"), BossRules.SPORE_MOTHER)
	assert_false(DragonRules.has_void(d), "caves have a floor: no void")


func test_its_terrain_rules_generator_and_secrets() -> void:
	var shape: Variant = d.call(&"generator_shape", 99)
	assert_true(shape is GlowShape)
	assert_eq((shape as MeadowsShape).seed, 99)
	var gen: Variant = d.call(&"generator", 99)
	assert_true(gen is GlowGenerator)
	assert_eq((gen as GlowGenerator).glow_shape().height_at(40, -60), (shape as GlowShape).height_at(40, -60))
	var rules: Variant = d.call(&"secret_rules", 99, shape)
	assert_true(rules is GlowSecretRules)
	assert_same((rules as SecretRules).shape, shape)


## Classical pieces already in the game, the underground ones first. On the meadow over the roof the birds and the
## crickets (no ambience of its own); under the roof every cavern is deep underground (the roof is the sky's ground:
## WorldService.sky_height), so the caves' drips play there by the existing rule.
func test_its_music_and_ambience() -> void:
	var pieces := UniverseRegistry.classical(6)
	assert_false(pieces.is_empty())
	assert_true(pieces.has(&"goldberg_aria") or pieces.has(&"moonlight"), "underground pieces")
	assert_true(UniverseRegistry.ambience(6).is_empty(), "the roof's meadow: birds by day, crickets at night")
	assert_eq(AmbienceSoundRules.choose({"underground": 1.0, "own": UniverseRegistry.ambience(6)}), &"drips")


## Through a daylight shaft: a clear sky; in the caves: the soft blue-violet dark (GlowRules' cave mood), never black.
func test_its_sky_and_its_cave_mood() -> void:
	var sky: Dictionary = d.get("sky")
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
	var mood := UniverseRegistry.cave_mood(6)
	assert_false(mood.is_empty(), "the caves' own mood")
	var fog: Color = mood.fog
	assert_gt(fog.b, fog.g, "blue-violet")
	assert_gt(fog.v, 0.2, "never black")
	assert_true(UniverseRegistry.cave_mood(5).is_empty(), "the other universes keep the meadows' caves")


func test_tillys_glow_stock() -> void:
	var stock: Dictionary = d.get("trader_stock")
	assert_gte(stock.size(), 6)
	for id: Variant in stock:
		assert_true(Inventory.ownable(id), BlockIds.display_name(id))
		assert_between(int(stock[id]), 1, 5, BlockIds.display_name(id))
		assert_eq(ShopRules.sell_price(id), 0, "Tilly doesn't buy it back")
	for id in [BlockIds.SPORE_LAMP, BlockIds.GLOW_MOSS, BlockIds.SELENITE]:
		assert_true(stock.has(id), BlockIds.display_name(id))
	for secret_block in [BlockIds.CAVE_GOLD, BlockIds.FAKE_CAVE_STONE, BlockIds.CAVE_PEARL]:
		assert_false(stock.has(secret_block), "never for sale: %s" % BlockIds.display_name(secret_block))


func test_what_its_secrets_say() -> void:
	var words: Dictionary = d.get("secret_words")
	for kind: StringName in SecretRules.PLACED:
		assert_true(str(words.get(kind, "")).begins_with("You found"), String(kind))
	assert_eq(words[SecretRules.ISLAND], "You found a hidden grotto!")


func test_the_ladder_reads_the_glow_caves() -> void:
	assert_eq(UniverseRegistry.size(), 6)
	assert_eq(UniverseRegistry.ladder_name(6), &"glow")
	assert_true(UniverseRegistry.exists(6))
	assert_true(UniverseRegistry.available().has(6))
	assert_eq(UniverseRegistry.display_name(6), "Glow Caves")
	assert_true(UniverseRegistry.shape_for(6, 5) is GlowShape)
	assert_true(UniverseRegistry.generator_for(6, 5) is GlowGenerator)
	assert_true(ShopRules.catalog(ShopRules.BLOCKS, 6).has(BlockIds.SPORE_LAMP), "Tilly sells it in the caves")
	assert_eq(ShopRules.price(BlockIds.CAVE_STONE, 6), 32, "1 Meadows gold, x 32 in universe 6")
	var card := UniverseRegistry.card_colors(6)
	assert_true(card.top is Color and card.ground is Color)
	assert_eq(UniverseRegistry.animals(6), [&"frog"] as Array[StringName], "frogs by the underground lakes")


func test_dragon_leads_to_the_caves_and_the_caves_to_the_hub() -> void:
	var n := UniverseRegistry.size()
	assert_eq(UniverseRules.boss_portal_target(5, n), 6, "the Sky Dragon's portal: the Glow Caves")
	assert_eq(UniverseRules.boss_portal_target(6, n), UniverseRules.HUB, "the caves': every universe you opened")
	assert_eq(UniverseRules.portal_target(5, UniverseRegistry.available()), 6)
	assert_eq(UniverseRules.unlocked_after_boss(5, 5), 6, "beating the Sky Dragon opens the caves")
	assert_eq(UniverseRegistry.hub_entries(6).size(), 6)
	assert_eq(ChatCommands.parse("/universe 6").get("universe"), 6)


func test_the_glow_caves_come_with_plus() -> void:
	assert_true(ShopCatalog.needs_plus(6))
	assert_true(ShopCatalog.plus_universes().has(6))


## Its crystal (item 485, kept for universe 6 since owner #39) places its portal core (223).
func test_its_crystal_and_portal_core() -> void:
	assert_eq(CrystalRules.crystal_of(6), 485)
	assert_eq(ItemIds.CRYSTAL_GLOW, 485)
	assert_true(ItemIds.CRYSTALS.has(ItemIds.CRYSTAL_GLOW))
	assert_eq(ItemIds.display_name(ItemIds.CRYSTAL_GLOW), "Glow Crystal")
	assert_eq(CrystalRules.core_of(6), BlockIds.CORE_GLOW)
	assert_eq(CrystalRules.universe_of_core(BlockIds.CORE_GLOW), 6)
	assert_eq(CrystalRules.item_for_core(BlockIds.CORE_GLOW), ItemIds.CRYSTAL_GLOW)
	assert_true(CrystalRules.SWIRLS.has(6), "its own swirl colours")


## Monster Wave's arena of universe 6 is flat cave stone with flowstone and selenite cover.
func test_the_arena_is_flat_cave_stone() -> void:
	var arena := ArenaShape.new(7, 6)
	assert_eq(arena.palette.top, BlockIds.CAVE_STONE)
	assert_eq(arena.block_at(Vector3i(40, ArenaShape.FLOOR - 1, 40)), BlockIds.CAVE_STONE)
	assert_eq(arena.height_at(300, -200), ArenaShape.FLOOR, "flat everywhere")
	assert_eq(arena.palette.cover, BlockIds.SELENITE)
	assert_eq(ArenaRules.kit_tier(6), ArenaRules.kit_tier(5), "the best kit")
