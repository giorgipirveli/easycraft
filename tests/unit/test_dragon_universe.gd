extends GutTest
## Owner feedback #39 (spec §14.2a): the Dragon Realm's universe descriptor (world/universes/dragon.gd), read the way
## M3 Task 5's UniverseRegistry reads every universe file, and the ladder it joins: meadows, desert, frost, candy,
## dragon. The Candy Kingdom's boss portal now leads to the Dragon Realm, whose own leads to the hub (the last
## universe); the realm comes with EasyCraft Plus while the build has a store.

const PATH := "res://world/universes/dragon.gd"

var d: Object


func before_all() -> void:
	d = load(PATH).new()


func after_each() -> void:
	UniverseRegistry.reset()


func test_it_is_universe_5_the_dragon_realm() -> void:
	assert_eq(d.get("name"), &"dragon", "world/universes/<name>.gd")
	assert_eq(d.get("display_name"), "Dragon Realm")
	assert_eq(d.get("index"), 5)
	assert_true(d.get("has_void"), "floating islands over a void (DragonRules)")
	assert_true(DragonRules.has_void(d))
	var kinds: Array = d.get("monster_kinds")
	assert_false(kinds.is_empty(), "its monsters (the realm's own at the merge)")
	for k: StringName in kinds:
		assert_true(MonsterRules.KINDS.has(k), String(k))
	assert_true(BossRules.words(StringName(d.get("boss_kind"))).has("name"), "a boss the BossDirector knows")
	assert_eq(kinds, MonsterRules.DRAGON_KINDS, "the lead's merge: shadow bats and wisp spirits")
	assert_eq(d.get("boss_kind"), BossRules.SKY_DRAGON, "the lead's merge: the Sky Dragon")


func test_its_terrain_rules_generator_and_secrets() -> void:
	var shape: Variant = d.call(&"generator_shape", 99)
	assert_true(shape is MeadowsShape, "every system types it MeadowsShape")
	assert_true(shape is DragonShape)
	assert_eq((shape as MeadowsShape).seed, 99)
	var gen: Variant = d.call(&"generator", 99)
	assert_true(gen is DragonGenerator)
	assert_eq((gen as DragonGenerator).world_seed, 99)
	assert_eq((gen as DragonGenerator).dragon_shape().height_at(40, -60), (shape as DragonShape).height_at(40, -60),
		"the generator and the shape agree")
	var rules: Variant = d.call(&"secret_rules", 99, shape)
	assert_true(rules is DragonSecretRules)
	assert_same((rules as SecretRules).shape, shape)


## The owner loves classical music (feedback #31): two public-domain pieces already in the game, played first here.
func test_its_music_and_ambience() -> void:
	assert_eq(UniverseRegistry.classical(5), [&"gymnopedie", &"mountain_king"] as Array[StringName])
	var music: Dictionary = d.get("music")
	for track: String in music:
		assert_true(ResourceLoader.exists(music[track]), music[track])
	assert_eq(UniverseRegistry.ambience(5).get("day"), &"wind", "a windy sky by day")


## Owner #43 (spec §3c): a sunrise over a sea of clouds, never a black-and-purple void (it was a starry purple sky).
func test_its_sunrise_sky() -> void:
	var sky: Dictionary = d.get("sky")
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
	var top: Color = sky.sky_top
	assert_gt(top.b, top.r, "a morning blue overhead")
	var horizon: Color = sky.sky_horizon
	assert_gt(horizon.r, horizon.b, "a golden horizon")
	var fog: Color = sky.fog
	assert_gt(fog.r, fog.b, "warm peach fog, not purple")
	var ground: Color = sky.ground_bottom
	assert_gt(ground.v, 0.8, "a bright sea of clouds below, not a dark void")


func test_tillys_dragon_stock() -> void:
	var stock: Dictionary = d.get("trader_stock")
	assert_gte(stock.size(), 6, "about six local things (§14.1)")
	for id: Variant in stock:
		assert_eq(typeof(id), TYPE_INT)
		assert_true(Inventory.ownable(id), BlockIds.display_name(id))
		assert_between(int(stock[id]), 1, 5, BlockIds.display_name(id))
		assert_eq(ShopRules.sell_price(id), 0, "Tilly doesn't buy it back, so no loop can mint gold")
	for secret_block in [BlockIds.DRAGON_GOLD, BlockIds.FAKE_FLOATSTONE]:
		assert_false(stock.has(secret_block), "never for sale: %s" % BlockIds.display_name(secret_block))


func test_what_its_secrets_say() -> void:
	var words: Dictionary = d.get("secret_words")
	for kind: StringName in SecretRules.PLACED:
		assert_true(words.has(kind), String(kind))
		assert_true(str(words[kind]).begins_with("You found"), String(kind))
	assert_eq(words[SecretRules.ISLAND], "You found a dragon nest!")


## M3 Task 5's registry finds and reads the file: the ladder's universe 5 is here, not "coming soon".
func test_the_ladder_reads_the_dragon_realm() -> void:
	assert_gte(UniverseRegistry.size(), 5, "the Glow Caves came after it")
	assert_eq(UniverseRegistry.ladder_name(5), &"dragon")
	assert_true(UniverseRegistry.exists(5))
	assert_true(UniverseRegistry.available().has(5))
	assert_eq(UniverseRegistry.display_name(5), "Dragon Realm")
	assert_true(UniverseRegistry.shape_for(5, 5) is DragonShape)
	assert_true(UniverseRegistry.generator_for(5, 5) is DragonGenerator)
	assert_eq(UniverseRegistry.trader_stock(5).get(BlockIds.FLOATSTONE), 1)
	assert_true(ShopRules.catalog(ShopRules.BLOCKS, 5).has(BlockIds.DRAGON_SCALE), "Tilly sells it in the realm")
	assert_eq(ShopRules.price(BlockIds.FLOATSTONE, 5), 16, "1 Meadows gold, x 16 in universe 5")
	assert_false(ShopRules.catalog(ShopRules.BLOCKS, 4).has(BlockIds.DRAGON_SCALE), "not in the Candy Kingdom")
	var card := UniverseRegistry.card_colors(5)
	assert_true(card.top is Color and card.ground is Color)


## The ladder after the Candy Kingdom leads to the Dragon Realm; the realm's boss portal leads to the hub.
func test_candy_leads_to_dragon_and_dragon_to_the_hub() -> void:
	var n := UniverseRegistry.size()
	assert_eq(UniverseRules.boss_portal_target(4, n), 5, "the Cake Monster's portal: the Dragon Realm")
	assert_eq(UniverseRules.boss_portal_target(5, n), 6, "the realm's: the Glow Caves (universe 6 came after it)")
	assert_eq(UniverseRules.portal_target(4, UniverseRegistry.available()), 5)
	assert_eq(UniverseRules.unlocked_after_boss(4, 4), 5, "beating the Cake Monster opens the realm")
	assert_eq(UniverseRegistry.hub_entries(5).size(), 5, "the hub lists all five")
	assert_eq(ChatCommands.parse("/universe 5").get("universe"), 5)


## EasyCraft Plus: the realm is a Plus universe while the build has a store (the existing rule: every universe after
## the first two).
func test_the_dragon_realm_comes_with_plus() -> void:
	assert_true(ShopCatalog.needs_plus(5))
	assert_true(ShopCatalog.plus_universes().has(5))


## Monster Wave's arena of universe 5 is the realm's own flat ground (sky grass on floatstone): no void there.
func test_the_realms_arena_is_flat_sky_grass() -> void:
	var arena := ArenaShape.new(7, 5)
	assert_eq(arena.palette.top, BlockIds.SKY_GRASS)
	assert_eq(arena.block_at(Vector3i(40, ArenaShape.FLOOR - 1, 40)), BlockIds.SKY_GRASS)
	assert_eq(arena.height_at(300, -200), ArenaShape.FLOOR, "flat everywhere")
	assert_between(ArenaRules.kit_tier(5), 1, WeaponRules.TIER_NAMES.size() - 1, "the kit clamps to the best tier")
	assert_eq(ArenaRules.kit_tier(5), ArenaRules.kit_tier(4), "cosmic, like the kingdom's")
	assert_false(DragonRules.world_has_void(d, true), "the arena has no void to fall into")
