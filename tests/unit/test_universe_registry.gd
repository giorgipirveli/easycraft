extends GutTest
## M3 Task 5 (spec §14.1): the universe ladder's registry. Universe 1 (Green Meadows) is today's world;
## universes 2–4 are descriptors in their own files (world/universes/<name>.gd), written by other tasks:
## the registry works with one universe or four, and a universe whose file doesn't exist is "coming soon".

const FAKE := preload("res://tests/fakes/fake_universe.gd")


func after_each() -> void:
	UniverseRegistry.reset()


func _hide_all_but_meadows() -> void:
	for u in range(2, UniverseRegistry.size() + 1):
		UniverseRegistry.use(u, null)


func test_the_ladder_is_meadows_desert_frost_candy_dragon_glow() -> void:
	assert_eq(UniverseRegistry.size(), 6, "owner 39: the Dragon Realm after the Candy Kingdom; then the Glow Caves")
	var names: Array[StringName] = [&"meadows", &"desert", &"frost", &"candy", &"dragon", &"glow"]
	var shown := ["Green Meadows", "Sandstorm Desert", "Frostpeak", "Candy Kingdom", "Dragon Realm", "Glow Caves"]
	for u in range(1, 7):
		assert_eq(UniverseRegistry.ladder_name(u), names[u - 1])
		assert_eq(UniverseRegistry.path_for(u), "res://world/universes/%s.gd" % names[u - 1])
		assert_eq(UniverseRegistry.display_name(u), shown[u - 1], "the ladder names it even before its file exists")


func test_green_meadows_is_universe_1_and_always_there() -> void:
	_hide_all_but_meadows()
	assert_true(UniverseRegistry.exists(1))
	var d := UniverseRegistry.descriptor(1)
	assert_not_null(d)
	assert_eq(d.get("index"), 1)
	assert_eq(d.get("name"), &"meadows")
	assert_eq(UniverseRegistry.available(), [1] as Array[int], "works with one universe")
	assert_eq(UniverseRegistry.boss_kind(1), &"golem")
	assert_true(UniverseRegistry.monster_kinds(1).has(MonsterRules.SLIME))
	assert_true(UniverseRegistry.monster_kinds(1).has(MonsterRules.GOBLIN))


func test_meadows_terrain_is_todays_terrain() -> void:
	var shape := UniverseRegistry.shape_for(1, 12345)
	var today := MeadowsShape.new(12345)
	for p: Vector2i in [Vector2i(0, 0), Vector2i(100, -40), Vector2i(-333, 777)]:
		assert_eq(shape.height_at(p.x, p.y), today.height_at(p.x, p.y))
	assert_eq(shape.spawn_column(), today.spawn_column())
	var gen := UniverseRegistry.generator_for(1, 12345)
	assert_true(gen is MeadowsGenerator)
	assert_eq((gen as MeadowsGenerator).world_seed, 12345)


func test_a_universe_without_its_file_is_coming_soon() -> void:
	_hide_all_but_meadows()
	for u in range(2, UniverseRegistry.size() + 1):
		assert_false(UniverseRegistry.exists(u), "universe %d" % u)
		assert_null(UniverseRegistry.descriptor(u))
	assert_false(UniverseRegistry.exists(0))
	assert_false(UniverseRegistry.exists(UniverseRegistry.size() + 1), "past the ladder")
	var shape := UniverseRegistry.shape_for(3, 7)
	assert_true(shape is MeadowsShape, "a world of a missing universe still has ground (Green Meadows')")


func test_it_works_with_every_universe_of_the_ladder() -> void:
	for u in range(2, UniverseRegistry.size() + 1):
		UniverseRegistry.use(u, FAKE.new())
	assert_eq(UniverseRegistry.available(), [1, 2, 3, 4, 5, 6] as Array[int], "six with the Glow Caves")


func test_a_descriptor_is_read_through_its_interface() -> void:
	UniverseRegistry.use(2, FAKE.new())
	assert_eq(UniverseRegistry.display_name(2), "Test Land")
	assert_eq(UniverseRegistry.monster_kinds(2), [&"mummy", &"scorpion"] as Array[StringName])
	assert_eq(UniverseRegistry.boss_kind(2), &"serpent")
	assert_eq(UniverseRegistry.music(2), {"day": "res://assets/music/night.ogg"})
	assert_eq(UniverseRegistry.sky(2).sky_top, Color(1.0, 0.6, 0.3))
	assert_eq(UniverseRegistry.trader_stock(2), {BlockIds.COAL: 2})
	var shape := UniverseRegistry.shape_for(2, 99)
	assert_eq(shape.height_at(50, -50), FAKE.HEIGHT)
	assert_eq(shape.spawn_column(), Vector2i(3, 5))
	assert_true(UniverseRegistry.generator_for(2, 99) is VoxelGeneratorFlat, "its own terrain generator")


func test_missing_fields_read_as_safe_defaults() -> void:
	var bare := GDScript.new()
	bare.source_code = "extends RefCounted\nvar index := 3\n"
	bare.reload()
	UniverseRegistry.use(3, bare.new())
	assert_true(UniverseRegistry.exists(3))
	assert_eq(UniverseRegistry.display_name(3), "Frostpeak", "the ladder's name")
	assert_eq(UniverseRegistry.monster_kinds(3), [] as Array[StringName])
	assert_eq(UniverseRegistry.boss_kind(3), &"")
	assert_eq(UniverseRegistry.music(3), {})
	assert_eq(UniverseRegistry.sky(3), {})
	assert_eq(UniverseRegistry.trader_stock(3), {})
	assert_true(UniverseRegistry.shape_for(3, 5) is MeadowsShape, "no shape: Green Meadows' ground")
	assert_true(UniverseRegistry.generator_for(3, 5) is MeadowsGenerator, "no generator: Green Meadows' generator")


func test_a_broken_shape_falls_back_to_meadows() -> void:
	var odd := GDScript.new()
	odd.source_code = "extends RefCounted\nfunc generator_shape(_s: int) -> Object:\n\treturn RefCounted.new()\n"
	odd.reload()
	UniverseRegistry.use(4, odd.new())
	assert_true(UniverseRegistry.shape_for(4, 5) is MeadowsShape)


func test_broken_field_types_are_ignored() -> void:
	var odd := GDScript.new()
	odd.source_code = "extends RefCounted\nvar display_name = 42\nvar music = \"loud\"\nvar sky = [1]\nvar trader_stock = 3\nvar monster_kinds = \"slime\"\n"
	odd.reload()
	UniverseRegistry.use(4, odd.new())
	assert_eq(UniverseRegistry.display_name(4), "Candy Kingdom")
	assert_eq(UniverseRegistry.music(4), {})
	assert_eq(UniverseRegistry.sky(4), {})
	assert_eq(UniverseRegistry.trader_stock(4), {})
	assert_eq(UniverseRegistry.monster_kinds(4), [] as Array[StringName])


func test_the_hub_lists_only_unlocked_universes_from_the_registry() -> void:
	UniverseRegistry.use(2, FAKE.new())
	UniverseRegistry.use(3, null)
	UniverseRegistry.use(4, null)
	var entries := UniverseRegistry.hub_entries(3)
	assert_eq(entries.size(), 3)
	assert_eq([entries[0].open, entries[1].open, entries[2].open], [true, true, false])
	assert_eq(UniverseRegistry.hub_entries(1).size(), 1)


func test_every_universe_has_picture_colours_for_its_hub_card() -> void:
	for u in range(1, 5):
		var c := UniverseRegistry.card_colors(u)
		for key in ["top", "bottom", "ground"]:
			assert_true(c.get(key) is Color, "universe %d %s" % [u, key])
