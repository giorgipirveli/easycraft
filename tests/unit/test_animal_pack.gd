extends GutTest
## More animals (owner feedback #41, 2026-09-24 20:42: "include more different animals"; spec §14.19): every
## animal has a species row (size, speed, herd), a home (its universe and biome), food, voices, a mind and a
## box model; each universe's descriptor names its animals, and a world only grows its own universe's animals,
## each where it fits (ducks by the water, deer by the woods, seals on the lake ice ...). Green Meadows keeps
## its old herds: the new kinds replace some of them through a seeded roll of their own.

const SEED := 12345
const PACK: Array[StringName] = [&"horse", &"donkey", &"goat", &"deer", &"duck", &"frog", &"turtle", &"squirrel",
	&"owl", &"hedgehog", &"camel", &"lizard", &"fennec", &"penguin", &"polar_bear", &"arctic_fox", &"seal",
	&"gummy_bunny", &"candy_bird"]
const MEADOWS_NEW: Array[StringName] = [&"horse", &"donkey", &"goat", &"deer", &"duck", &"frog", &"turtle",
	&"squirrel", &"owl", &"hedgehog"]
const DESERT: Array[StringName] = [&"camel", &"lizard", &"fennec"]
const FROST: Array[StringName] = [&"penguin", &"polar_bear", &"arctic_fox", &"seal"]
const CANDY: Array[StringName] = [&"gummy_bunny", &"candy_bird"]


func after_each() -> void:
	UniverseRegistry.reset()


func _spawns(shape: MeadowsShape, kinds: Array[StringName], cells: int) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for cx in range(-cells, cells):
		for cz in range(-cells, cells):
			all.append_array(AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz), kinds))
	return all


# --- The tables ---

func test_every_animal_has_a_home_herd_speed_food_voices_health_and_a_mind() -> void:
	for sp: StringName in AnimalRules.SPECIES:
		var d: Dictionary = AnimalRules.SPECIES[sp]
		assert_true(d.habitat in [&"land", &"water"], "%s: land or water" % sp)
		assert_gt((d.size as Vector3).x, 0.0, "%s has a size" % sp)
		assert_gt(float(d.speed), 0.0, "%s walks" % sp)
		assert_gte((d.herd as Vector2i).x, 1, "%s: a herd of at least one" % sp)
		assert_lte((d.herd as Vector2i).x, (d.herd as Vector2i).y, str(sp))
		assert_eq((d.colors as Array).size(), 2, "%s: a body and a detail colour" % sp)
		# Pip and the pet dragon are only given, never wild; M3 Task 20b: a befriended monster only comes from the wand
		if not PetRules.KINDS.get(sp, {}).get("tame") in [PetRules.GIVEN, PetRules.BY_WAND]:
			assert_false(AnimalHomes.biomes(sp).is_empty(), "%s lives somewhere" % sp)
		assert_false(AnimalFood.foods(sp).is_empty(), "%s eats something" % sp)
		for id: int in AnimalFood.foods(sp):
			assert_true(BlockIds.is_valid(id) or ItemIds.is_item(id), "%s eats a real block or item (%d)" % [sp, id])
		for sound: StringName in [VoiceRules.animal_call(sp), VoiceRules.animal_hurt(sp), VoiceRules.animal_happy(sp)]:
			assert_ne(sound, &"", "%s has a voice" % sp)
		assert_true(AnimalRules.HEALTH.has(sp), "%s has health" % sp)
		assert_true(AnimalRules.DROPS.has(sp) or sp == &"sheep", "%s: what it leaves is written down (sheep: wool)" % sp)
		assert_true(AnimalSpecies.TRAITS.has(sp), "%s has a mind of its own" % sp)
		assert_true(AnimalSpecies.table(sp) is MindSpecies)


func test_the_new_kinds_are_all_there() -> void:
	for sp in PACK:
		assert_true(AnimalRules.SPECIES.has(sp), str(sp))
		assert_eq(int(AnimalRules.SPECIES[sp].weight), 0, "%s is placed by its home, never by the farm weights" % sp)


func test_every_new_kind_has_a_box_model_of_its_own() -> void:
	var fallback := 36   # one box: 12 triangles (BlockyAnimal's fallback for a species without boxes)
	for sp in PACK:
		var faces := BlockyAnimal.mesh_for(sp).get_faces().size()
		assert_gt(faces, fallback * 3, "%s is built from its own boxes" % sp)
		assert_same(BlockyAnimal.mesh_for(sp), BlockyAnimal.mesh_for(sp), "%s's mesh is cached" % sp)


func test_the_big_ones_are_big_and_the_small_ones_small() -> void:
	var size := func(sp: StringName) -> float: return (AnimalRules.SPECIES[sp].size as Vector3).y
	assert_gt(size.call(&"horse"), size.call(&"cow"), "a horse is taller than a cow")
	assert_gt(size.call(&"camel"), size.call(&"horse"), "a camel taller still")
	assert_gt(size.call(&"polar_bear"), size.call(&"cow"))
	assert_lt(size.call(&"frog"), size.call(&"rabbit"))
	assert_lt(size.call(&"turtle"), size.call(&"sheep"))
	assert_lt(float(AnimalRules.SPECIES[&"turtle"].speed), 1.0, "a turtle is slow")
	assert_gt(float(AnimalRules.SPECIES[&"lizard"].speed), 3.5, "a lizard darts")


func test_foods_fit_the_animal() -> void:
	assert_true(AnimalFood.eats(&"penguin", ItemIds.TREAT_FISH), "penguins like fish")
	assert_true(AnimalFood.eats(&"seal", ItemIds.TREAT_FISH))
	assert_true(AnimalFood.eats(&"polar_bear", ItemIds.TREAT_FISH))
	assert_false(AnimalFood.eats(&"penguin", BlockIds.GRASS), "no penguin eats grass")
	assert_true(AnimalFood.eats(&"horse", BlockIds.GRASS), "a horse grazes")
	assert_true(AnimalFood.eats(&"camel", BlockIds.DEAD_BUSH), "a camel eats the desert's thorny plants")
	assert_true(AnimalFood.eats(&"gummy_bunny", BlockIds.GUMDROP), "candy animals eat candy")
	assert_true(AnimalFood.eats(&"candy_bird", BlockIds.SPRINKLES))
	assert_true(AnimalFood.eats(&"duck", ItemIds.TREAT_SEEDS), "birds peck seeds")
	for sp: StringName in [&"sheep", &"cow", &"pig", &"chicken", &"rabbit", &"dog", &"cat"]:
		assert_true(AnimalFood.eats(sp, BlockIds.GRASS), "%s still likes grass (M2 Task 18)" % sp)
		assert_true(AnimalFood.eats(sp, BlockIds.LEAVES), str(sp))
	assert_false(AnimalFood.eats(&"dragon", BlockIds.GRASS), "an unknown animal eats nothing")


# --- Universes name their animals ---

func test_every_universe_names_its_animals() -> void:
	var meadows := UniverseRegistry.animals(1)
	for sp: StringName in [&"dog", &"cat", &"pig", &"cow", &"sheep", &"chicken", &"rabbit", &"fish", &"fox", &"parrot"]:
		assert_true(meadows.has(sp), "Green Meadows keeps its %s" % sp)
	for sp in MEADOWS_NEW:
		assert_true(meadows.has(sp), "Green Meadows gets the %s" % sp)
	assert_eq(UniverseRegistry.animals(2), DESERT, "the desert's animals")
	assert_eq(UniverseRegistry.animals(3), FROST, "Frostpeak's animals")
	assert_eq(UniverseRegistry.animals(4), CANDY, "the Candy Kingdom's animals")
	for u in range(1, 5):
		for sp: StringName in UniverseRegistry.animals(u):
			assert_true(AnimalRules.SPECIES.has(sp), "universe %d names a real animal: %s" % [u, sp])
	for sp in PACK:
		var homes := 0
		for u in range(1, 5):
			if UniverseRegistry.animals(u).has(sp):
				homes += 1
		assert_eq(homes, 1, "%s lives in exactly one universe" % sp)


func test_a_universe_that_names_no_animals_keeps_green_meadows_ones() -> void:
	var bare := RefCounted.new()
	UniverseRegistry.use(3, bare)
	assert_eq(UniverseRegistry.animals(3), UniverseRegistry.animals(1))


# --- Spawning per universe and biome ---

func test_each_universe_grows_only_its_own_animals() -> void:
	for u in range(2, 5):
		var shape := UniverseRegistry.shape_for(u, SEED)
		var kinds := UniverseRegistry.animals(u)
		var seen := {}
		for s: Dictionary in _spawns(shape, kinds, 16):
			assert_true(kinds.has(s.species), "universe %d: no %s here" % [u, s.species])
			seen[s.species] = true
		for sp: StringName in kinds:
			assert_true(seen.has(sp), "universe %d has %s somewhere (%s)" % [u, sp, seen.keys()])


func test_the_desert_animals_stand_on_sand_or_an_oasis_bank() -> void:
	var shape := UniverseRegistry.shape_for(2, SEED) as DesertShape
	for s: Dictionary in _spawns(shape, DESERT, 12):
		var p: Vector3 = s.pos
		var x := floori(p.x)
		var z := floori(p.z)
		assert_eq(p.y, float(shape.height_at(x, z)), "%s stands on the ground" % s.species)
		assert_gt(shape.height_at(x, z), MeadowsShape.SEA_LEVEL + 1, "%s never in the oasis pond" % s.species)
		assert_false(shape.tree_at(x, z), "%s never inside a cactus or a palm" % s.species)


func test_seals_lie_on_the_lake_ice_and_penguins_by_the_lakes() -> void:
	var shape := UniverseRegistry.shape_for(3, SEED) as FrostShape
	var seals := 0
	var penguins := 0
	var lakeside_penguins := 0
	for cx in range(-20, 20):
		for cz in range(-20, 20):
			var list := AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz), FROST)
			for s: Dictionary in list:
				var p: Vector3 = s.pos
				var x := floori(p.x)
				var z := floori(p.z)
				if s.species == &"seal":
					seals += 1
					assert_eq(shape.terrain_at(x, z), FrostShape.LAKE, "a seal on a frozen lake")
					assert_eq(p.y, float(MeadowsShape.SEA_LEVEL), "on top of the ice")
				elif s.species == &"penguin":
					penguins += 1
				elif not AnimalHomes.on_ice(shape, x, z):
					assert_eq(p.y, float(shape.height_at(x, z)), "%s stands on the snow" % s.species)
			if not list.is_empty():
				var c: Vector3 = list[0].pos   # the herd's centre
				if AnimalHomes.near_lake(shape, floori(c.x), floori(c.z)):
					assert_true(list[0].species in [&"penguin", &"seal", &"polar_bear"],
						"by a frozen lake live penguins, seals and polar bears, not %s" % list[0].species)
					lakeside_penguins += int(list[0].species == &"penguin")
	assert_gt(lakeside_penguins, 0, "penguin flocks by the lakes")
	assert_gt(seals, 0, "some seals")
	assert_gt(penguins, 0, "some penguins")


func test_candy_birds_live_in_the_candy_cane_forests() -> void:
	var shape := UniverseRegistry.shape_for(4, SEED) as CandyShape
	var birds := 0
	for cx in range(-16, 16):
		for cz in range(-16, 16):
			var list := AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz), CANDY)
			for s: Dictionary in list:
				var p: Vector3 = s.pos
				assert_false(shape.is_river(floori(p.x), floori(p.z)), "%s never in a chocolate river" % s.species)
			if not list.is_empty() and list[0].species == &"candy_bird":
				birds += 1
				var c: Vector3 = list[0].pos   # the herd's centre
				assert_true(shape.forest_at(floori(c.x), floori(c.z)), "a candy bird flock in a candy-cane forest")
	assert_gt(birds, 0)


func test_green_meadows_grows_the_new_kinds_where_they_fit() -> void:
	var shape := MeadowsShape.new(SEED)
	var seen := {}
	for s: Dictionary in _spawns(shape, UniverseRegistry.animals(1), 16):
		var p: Vector3 = s.pos
		var x := floori(p.x)
		var z := floori(p.z)
		seen[s.species] = true
		if AnimalRules.SPECIES[s.species].habitat == &"land":
			assert_eq(shape.column_block(shape.height_at(x, z) - 1, shape.height_at(x, z)), BlockIds.GRASS,
				"%s stands on grass" % s.species)
	for sp in MEADOWS_NEW:
		assert_true(seen.has(sp), "Green Meadows has %s (%s)" % [sp, seen.keys()])


func test_the_new_kinds_come_to_their_own_places() -> void:
	var shape := MeadowsShape.new(SEED)
	for cx in range(-16, 16):
		for cz in range(-16, 16):
			var cell := Vector2i(cx, cz)
			var list := AnimalRules.spawns_for_cell(shape, cell, UniverseRegistry.animals(1))
			if list.is_empty():
				continue
			var sp: StringName = list[0].species
			var c: Vector3 = list[0].pos
			if sp in [&"duck", &"frog", &"turtle"]:
				assert_true(AnimalHomes.fits(shape, AnimalHomes.SHORE, floori(c.x), floori(c.z)), "%s by the water" % sp)
			elif sp in [&"deer", &"squirrel", &"owl"]:
				assert_true(AnimalHomes.fits(shape, AnimalHomes.WOODS, floori(c.x), floori(c.z)), "%s by the woods" % sp)
			elif sp == &"goat":
				assert_true(AnimalHomes.fits(shape, AnimalHomes.HILLS, floori(c.x), floori(c.z)), "a goat on the hills")


func test_the_old_herds_stay_where_no_new_kind_came() -> void:
	var shape := MeadowsShape.new(SEED)
	var old: Array[StringName] = []
	for sp: StringName in UniverseRegistry.animals(1):
		if not MEADOWS_NEW.has(sp):
			old.append(sp)
	var replaced := 0
	var kept := 0
	for cx in range(-12, 12):
		for cz in range(-12, 12):
			var cell := Vector2i(cx, cz)
			var before := AnimalRules.spawns_for_cell(shape, cell, old)
			var after := AnimalRules.spawns_for_cell(shape, cell, UniverseRegistry.animals(1))
			if after.is_empty() or not MEADOWS_NEW.has(after[0].species):
				assert_eq(str(after), str(before), "cell %s keeps its herd" % cell)
				kept += int(not after.is_empty())
			else:
				assert_false(before.is_empty(), "a new kind only takes the place of a herd that was there")
				replaced += 1
	assert_gt(replaced, 20, "many herds are new kinds now")
	assert_gt(kept, 20, "and many old herds stay")


func test_spawns_stay_deterministic_per_cell_in_every_universe() -> void:
	for u in range(1, 5):
		var cell := Vector2i(3, -2)
		var a := AnimalRules.spawns_for_cell(UniverseRegistry.shape_for(u, SEED), cell, UniverseRegistry.animals(u))
		var b := AnimalRules.spawns_for_cell(UniverseRegistry.shape_for(u, SEED), cell, UniverseRegistry.animals(u))
		assert_eq(str(a), str(b), "universe %d" % u)


func test_no_animal_ever_attacks() -> void:
	for sp: StringName in AnimalRules.SPECIES:
		assert_false(AnimalRules.attacks(sp), "%s never attacks (the polar bear is gentle)" % sp)
