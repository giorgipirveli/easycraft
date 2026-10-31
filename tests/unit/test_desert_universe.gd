extends GutTest
## M3 Task 2: the Sandstorm Desert's universe descriptor (world/universes/desert.gd), read the way M3
## Task 5's UniverseRegistry reads every universe file: name, display_name, index, generator_shape(seed)
## (a MeadowsShape), generator(seed), monster_kinds, boss_kind, music, sky, trader_stock; and the desert's
## own optional fields: secret_rules, secret_words, weather, traps.

const PATH := "res://world/universes/desert.gd"
const MAX_MUSIC_BYTES := 1_500_000   # like tests/unit/test_music.gd

var d: Object


func before_all() -> void:
	d = load(PATH).new()


func test_it_is_universe_2_the_sandstorm_desert() -> void:
	assert_eq(d.get("name"), &"desert", "world/universes/<name>.gd")
	assert_eq(d.get("display_name"), "Sandstorm Desert")
	assert_eq(d.get("index"), 2)
	assert_eq(d.get("monster_kinds"), MonsterRules.DESERT_KINDS)
	assert_eq(d.get("boss_kind"), BossRules.SERPENT)
	assert_eq(d.get("weather"), &"sandstorm")
	assert_eq(d.get("traps"), true)


func test_its_terrain_rules_and_generator() -> void:
	var shape: Variant = d.call(&"generator_shape", 99)
	assert_true(shape is MeadowsShape, "every system types it MeadowsShape")
	assert_true(shape is DesertShape)
	assert_eq((shape as MeadowsShape).seed, 99)
	var gen: Variant = d.call(&"generator", 99)
	assert_true(gen is VoxelGenerator)
	assert_true(gen is DesertGenerator)
	assert_eq((gen as DesertGenerator).world_seed, 99)
	assert_eq((gen as DesertGenerator).desert_shape().height_at(40, -60), (shape as DesertShape).height_at(40, -60),
		"the generator and the shape agree")
	var rules: Variant = d.call(&"secret_rules", 99, shape)
	assert_true(rules is DesertSecretRules)
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
		assert_between(stream.get_length(), 60.0, 70.0, "a 64 s loop")
		assert_lte(FileAccess.get_file_as_bytes(path).size(), MAX_MUSIC_BYTES, path)


func test_its_sky_colours() -> void:
	var sky: Dictionary = d.get("sky")
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
	assert_gt((sky.sky_horizon as Color).r, (sky.sky_horizon as Color).b, "a warm, sandy horizon")


func test_tillys_desert_stock() -> void:
	var stock: Dictionary = d.get("trader_stock")
	assert_gte(stock.size(), 6, "about six local things (§14.1)")
	for id: Variant in stock:
		assert_eq(typeof(id), TYPE_INT)
		assert_true(Inventory.ownable(id), BlockIds.display_name(id))
		assert_gt(int(stock[id]), 0)
		assert_eq(ShopRules.sell_price(id), 0, "Tilly doesn't buy it back, so no loop can mint gold")
	for secret_block in [BlockIds.PYRAMID_GOLD, BlockIds.ARROW_SLIT, BlockIds.TRAP_SAND, BlockIds.FAKE_SANDSTONE]:
		assert_false(stock.has(secret_block), "never for sale: %s" % BlockIds.display_name(secret_block))


## M3 Task 5's registry finds and reads the file (merged): the ladder's universe 2 is here, not "coming soon".
func test_the_ladder_reads_the_desert() -> void:
	UniverseRegistry.reset()
	assert_true(UniverseRegistry.exists(2))
	assert_true(UniverseRegistry.available().has(2))
	assert_eq(UniverseRegistry.display_name(2), "Sandstorm Desert")
	assert_eq(UniverseRegistry.monster_kinds(2), MonsterRules.DESERT_KINDS)
	assert_eq(UniverseRegistry.boss_kind(2), BossRules.SERPENT)
	assert_true(UniverseRegistry.shape_for(2, 5) is DesertShape)
	assert_true(UniverseRegistry.generator_for(2, 5) is DesertGenerator)
	assert_eq(UniverseRegistry.music(2).get("day"), "res://assets/music/desert_day.ogg")
	assert_true(UniverseRegistry.sky(2).get("sky_horizon") is Color)
	assert_eq(UniverseRegistry.trader_stock(2).get(BlockIds.SANDSTONE), 1)
	assert_true(ShopRules.catalog(ShopRules.BLOCKS, 2).has(BlockIds.SANDSTONE), "Tilly sells it in the desert")
	assert_eq(ShopRules.price(BlockIds.SANDSTONE, 2), 2, "1 Meadows gold, x 2 in universe 2")
	assert_false(ShopRules.catalog(ShopRules.BLOCKS, 1).has(BlockIds.SANDSTONE), "not in Green Meadows")


func test_what_its_secrets_say() -> void:
	var words: Dictionary = d.get("secret_words")
	for kind: StringName in SecretRules.PLACED:
		assert_true(words.has(kind), String(kind))
		assert_true(str(words[kind]).begins_with("You found"), String(kind))
	assert_string_contains(str(words[SecretRules.TEMPLE]), "pyramid")
