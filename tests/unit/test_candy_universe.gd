extends GutTest
## M3 Task 4: the Candy Kingdom's universe descriptor (world/universes/candy.gd), read the way M3 Task 5's
## UniverseRegistry reads every universe file: name, display_name, index, generator_shape(seed) (a
## MeadowsShape), generator(seed), monster_kinds, boss_kind, music, sky, trader_stock; the optional fields the
## desert brought (secret_rules, secret_words, weather) and the kingdom's own: liquid (the water is chocolate)
## and classical (the pieces of classical music that fit it, for the audio pass).

const PATH := "res://world/universes/candy.gd"
const MAX_MUSIC_BYTES := 1_500_000   # like tests/unit/test_music.gd

var d: Object


func before_all() -> void:
	d = load(PATH).new()


func test_it_is_universe_4_the_candy_kingdom() -> void:
	assert_eq(d.get("name"), &"candy", "world/universes/<name>.gd")
	assert_eq(d.get("display_name"), "Candy Kingdom")
	assert_eq(d.get("index"), 4)
	assert_eq(d.get("monster_kinds"), MonsterRules.CANDY_KINDS)
	assert_eq(d.get("boss_kind"), BossRules.CAKE)
	assert_eq(d.get("weather"), &"sprinkles")
	assert_eq(d.get("liquid"), &"chocolate")


func test_its_terrain_rules_and_generator() -> void:
	var shape: Variant = d.call(&"generator_shape", 99)
	assert_true(shape is MeadowsShape, "every system types it MeadowsShape")
	assert_true(shape is CandyShape)
	assert_eq((shape as MeadowsShape).seed, 99)
	var gen: Variant = d.call(&"generator", 99)
	assert_true(gen is CandyGenerator)
	assert_eq((gen as CandyGenerator).world_seed, 99)
	assert_eq((gen as CandyGenerator).candy_shape().height_at(40, -60), (shape as CandyShape).height_at(40, -60),
		"the generator and the shape agree")
	var rules: Variant = d.call(&"secret_rules", 99, shape)
	assert_true(rules is CandySecretRules)
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
		assert_between(stream.get_length(), 20.0, 120.0, path)
		assert_lte(FileAccess.get_file_as_bytes(path).size(), MAX_MUSIC_BYTES, path)


## The owner loves classical music (feedback #31): the kingdom names the pieces it plays first (M5 Task 2: MusicPieces
## ids, the Nutcracker's Waltz of the Flowers and its own Minute Waltz; no public-domain Sugar Plum Fairy exists).
func test_it_names_its_classical_pieces() -> void:
	var classical := UniverseRegistry.classical(4)
	assert_true(classical.has(&"waltz_flowers"), "The Nutcracker's Land of Sweets")
	assert_true(classical.has(&"minute_waltz"), "its own piece")
	for id: StringName in classical:
		assert_true(MusicPieces.has(id), String(id))


func test_its_sky_colours() -> void:
	var sky: Dictionary = d.get("sky")
	for key in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"]:
		assert_true(sky.get(key) is Color, key)
	assert_gt((sky.sky_top as Color).r, (sky.sky_top as Color).g, "a pink sky")


func test_tillys_candy_stock() -> void:
	var stock: Dictionary = d.get("trader_stock")
	assert_gte(stock.size(), 6, "about six local things (§14.1)")
	for id: Variant in stock:
		assert_eq(typeof(id), TYPE_INT)
		assert_true(Inventory.ownable(id), BlockIds.display_name(id))
		assert_gt(int(stock[id]), 0)
		assert_eq(ShopRules.sell_price(id), 0, "Tilly doesn't buy it back, so no loop can mint gold")
	for secret_block in [BlockIds.GOLDEN_CANDY, BlockIds.FAKE_CHOCOLATE]:
		assert_false(stock.has(secret_block), "never for sale: %s" % BlockIds.display_name(secret_block))


## M3 Task 5's registry finds and reads the file: the ladder's universe 4 is here, not "coming soon".
func test_the_ladder_reads_the_candy_kingdom() -> void:
	UniverseRegistry.reset()
	assert_true(UniverseRegistry.exists(4))
	assert_true(UniverseRegistry.available().has(4))
	assert_eq(UniverseRegistry.display_name(4), "Candy Kingdom")
	assert_eq(UniverseRegistry.monster_kinds(4), MonsterRules.CANDY_KINDS)
	assert_eq(UniverseRegistry.boss_kind(4), BossRules.CAKE)
	assert_true(UniverseRegistry.shape_for(4, 5) is CandyShape)
	assert_true(UniverseRegistry.generator_for(4, 5) is CandyGenerator)
	assert_eq(UniverseRegistry.music(4).get("day"), "res://assets/music/candy_day.ogg")
	assert_eq(UniverseRegistry.trader_stock(4).get(BlockIds.FROSTING), 1)
	assert_true(ShopRules.catalog(ShopRules.BLOCKS, 4).has(BlockIds.GINGERBREAD), "Tilly sells it in the kingdom")
	assert_eq(ShopRules.price(BlockIds.FROSTING, 4), 8, "1 Meadows gold, × 8 in universe 4")
	assert_false(ShopRules.catalog(ShopRules.BLOCKS, 1).has(BlockIds.FROSTING), "not in Green Meadows")


func test_what_its_secrets_say() -> void:
	var words: Dictionary = d.get("secret_words")
	for kind: StringName in SecretRules.PLACED:
		assert_true(words.has(kind), String(kind))
		assert_true(str(words[kind]).begins_with("You found"), String(kind))
	assert_string_contains(str(words[SecretRules.TEMPLE]), "gingerbread")
