extends GutTest
## M3 Task 3: Frostpeak's universe descriptor (world/universes/frost.gd), read the way M3 Task 5's
## UniverseRegistry reads every universe file: name, display_name, index, generator_shape(seed) (a
## MeadowsShape), generator(seed), monster_kinds, boss_kind, music, sky, trader_stock; and the optional
## fields the desert introduced: secret_rules, secret_words, weather (a snowstorm).

const PATH := "res://world/universes/frost.gd"
const MAX_MUSIC_BYTES := 1_500_000   # like tests/unit/test_music.gd

var d: Object


func before_all() -> void:
	d = load(PATH).new()


func after_each() -> void:
	UniverseRegistry.reset()


func test_it_is_universe_3_frostpeak() -> void:
	assert_eq(d.get("name"), &"frost", "world/universes/<name>.gd")
	assert_eq(d.get("display_name"), "Frostpeak")
	assert_eq(d.get("index"), 3)
	assert_eq(d.get("monster_kinds"), MonsterRules.FROST_KINDS)
	assert_eq(d.get("boss_kind"), BossRules.FROST_GIANT)
	assert_eq(d.get("weather"), &"snowstorm")
	assert_ne(d.get("traps"), true, "Frostpeak's dangers are ice and weather, not traps")


func test_its_terrain_rules_and_generator() -> void:
	var shape: Variant = d.call(&"generator_shape", 99)
	assert_true(shape is MeadowsShape, "every system types it MeadowsShape")
	assert_true(shape is FrostShape)
	assert_eq((shape as MeadowsShape).seed, 99)
	var gen: Variant = d.call(&"generator", 99)
	assert_true(gen is FrostGenerator)
	assert_eq((gen as FrostGenerator).world_seed, 99)
	assert_eq((gen as FrostGenerator).frost_shape().height_at(40, -60), (shape as FrostShape).height_at(40, -60),
		"the generator and the shape agree")
	var rules: Variant = d.call(&"secret_rules", 99, shape)
	assert_true(rules is FrostSecretRules)
	assert_same((rules as SecretRules).shape, shape)


func test_its_music_loops_are_there_and_small() -> void:
	var music: Dictionary = d.get("music")
	assert_eq(music.keys(), ["day", "night"], "the boss keeps Green Meadows' loop")
	for track: String in music:
		var path: String = music[track]
		assert_true(ResourceLoader.exists(path), path)
		var stream := load(path) as AudioStreamOggVorbis
		assert_not_null(stream, path)
		assert_true(stream.loop, "%s loops" % path)
		assert_gt(stream.get_length(), 30.0, "a loop long enough not to nag")
		assert_lte(FileAccess.get_file_as_bytes(path).size(), MAX_MUSIC_BYTES, path)


func test_its_sky_colours() -> void:
	var sky: Dictionary = d.get("sky")
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
	var horizon: Color = sky.sky_horizon
	assert_gt(minf(horizon.r, minf(horizon.g, horizon.b)), 0.8, "a pale, snowy horizon")
	assert_gte(horizon.b, horizon.r, "a cold one")


func test_tillys_frost_stock() -> void:
	var stock: Dictionary = d.get("trader_stock")
	assert_gte(stock.size(), 6, "about six local things (§14.1)")
	for id: Variant in stock:
		assert_eq(typeof(id), TYPE_INT)
		assert_true(Inventory.ownable(id), BlockIds.display_name(id))
		assert_gt(int(stock[id]), 0)
		assert_eq(ShopRules.sell_price(id), 0, "Tilly doesn't buy it back, so no loop can mint gold")
		assert_eq(BlockLibrary.page_of(id), FrostBlocks.PAGE, "Frostpeak's own blocks")
	assert_false(stock.has(BlockIds.FAKE_SNOW), "never for sale: the secret floor")
	assert_false(stock.has(BlockIds.FROZEN_ORE), "ore is dug, not bought")


func test_the_ladder_reads_frostpeak() -> void:
	assert_true(UniverseRegistry.exists(3))
	assert_true(UniverseRegistry.available().has(3))
	assert_eq(UniverseRegistry.display_name(3), "Frostpeak")
	assert_eq(UniverseRegistry.monster_kinds(3), MonsterRules.FROST_KINDS)
	assert_eq(UniverseRegistry.boss_kind(3), BossRules.FROST_GIANT)
	assert_true(UniverseRegistry.shape_for(3, 5) is FrostShape)
	assert_true(UniverseRegistry.generator_for(3, 5) is FrostGenerator)
	assert_eq(UniverseRegistry.music(3).get("day"), "res://assets/music/frost_day.ogg")
	assert_eq(UniverseRegistry.trader_stock(3).get(BlockIds.PACKED_SNOW), 1)
	assert_true(ShopRules.catalog(ShopRules.BLOCKS, 3).has(BlockIds.PACKED_SNOW), "Tilly sells it in Frostpeak")
	assert_eq(ShopRules.price(BlockIds.PACKED_SNOW, 3), 4, "1 Meadows gold, x 4 in universe 3")
	assert_false(ShopRules.catalog(ShopRules.BLOCKS, 1).has(BlockIds.PACKED_SNOW), "not in Green Meadows")
	assert_eq(UniverseRules.next_universe(3), 4, "the Frost Giant's portal leads on to universe 4")


func test_what_its_secrets_say() -> void:
	var words: Dictionary = d.get("secret_words")
	for kind: StringName in SecretRules.PLACED:
		assert_true(words.has(kind), String(kind))
		assert_true(str(words[kind]).begins_with("You found"), String(kind))
	assert_string_contains(str(words[SecretRules.ROOM]), "igloo")
	assert_string_contains(str(words[SecretRules.TEMPLE]), "ice")
