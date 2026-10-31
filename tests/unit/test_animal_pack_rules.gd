extends GutTest
## What the new animals do (owner feedback #41, spec §14.19), as pure rules: a goat jumps up 2 blocks, a deer
## is shy, a hedgehog curls up, ducks and their kin swim, penguins and seals belly-slide on ice, a squirrel runs
## up tree trunks, an owl is awake at night, a frog and a gummy bunny hop high, and a turtle now and then lays
## an egg on sand that hatches when a child finds it.


func _block_at(cells: Dictionary, ground := 10) -> Callable:
	return func(p: Vector3i) -> int: return cells.get(p, BlockIds.STONE if p.y < ground else BlockIds.AIR)


func test_a_goat_jumps_up_two_blocks_the_others_one() -> void:
	assert_eq(AnimalRules.climb_height(&"goat"), 2)
	for sp: StringName in [&"sheep", &"horse", &"deer", &"camel", &"penguin"]:
		assert_eq(AnimalRules.climb_height(sp), 1, str(sp))
	var g := float(20.0)   # Animal.GRAVITY
	var goat_top := pow(sqrt(2.0 * g * float(AnimalRules.SPECIES[&"goat"].hop)), 2.0) / (2.0 * g)
	assert_gt(goat_top, 2.1, "the goat's hop clears a 2-block step")
	assert_lt(float(AnimalRules.SPECIES[&"sheep"].hop), 2.0, "a sheep's doesn't")


func test_a_deer_runs_from_anyone_walking_up_close_a_sheep_only_from_a_rush() -> void:
	var deer := Vector3(0, 10, 0)
	var walker := Vector3(7, 10, 0)
	var walking := Vector3(-2.0, 0, 0)            # walking towards it, not rushing
	var away := AnimalRules.flee_from(&"deer", deer, walker, walking)
	assert_almost_eq(away.x, -1.0, 0.01, "the deer runs the other way")
	assert_eq(AnimalRules.flee_from(&"sheep", deer, walker, walking), Vector3.ZERO, "a sheep stays calm")
	assert_eq(AnimalRules.flee_from(&"deer", deer, Vector3(12, 10, 0), walking), Vector3.ZERO, "far enough: calm")
	assert_eq(AnimalRules.flee_from(&"deer", deer, walker, Vector3.ZERO), Vector3.ZERO, "someone standing still is fine")
	assert_ne(AnimalRules.flee_from(&"deer", deer, Vector3(3, 10, 0), Vector3.ZERO), Vector3.ZERO,
		"but not that close")
	var rush := Vector3(-6.0, 0, 0)
	assert_ne(AnimalRules.flee_from(&"sheep", deer, Vector3(3, 10, 0), rush), Vector3.ZERO, "a rush scares a sheep (M1b)")


func test_a_hedgehog_curls_up_instead_of_running() -> void:
	assert_true(AnimalRules.curls_up(&"hedgehog"))
	assert_false(AnimalRules.curls_up(&"rabbit"))
	assert_between(AnimalRules.CURL_TIME, 2.0, 8.0, "a few seconds, then it uncurls")


func test_swimmers_may_step_into_water_the_others_never() -> void:
	var cells := {Vector3i(1, 10, 0): BlockIds.WATER, Vector3i(1, 9, 0): BlockIds.WATER}
	var at := _block_at(cells)
	for sp: StringName in [&"duck", &"frog", &"turtle", &"penguin", &"seal", &"polar_bear"]:
		assert_true(AnimalRules.swims(sp), str(sp))
		assert_true(AnimalRules.can_step(sp, Vector3i(1, 10, 0), at), "%s swims" % sp)
	for sp: StringName in [&"sheep", &"horse", &"camel", &"deer", &"gummy_bunny"]:
		assert_false(AnimalRules.swims(sp), str(sp))
		assert_false(AnimalRules.can_step(sp, Vector3i(1, 10, 0), at), "%s keeps out of the water" % sp)


func test_penguins_and_seals_belly_slide_on_ice() -> void:
	var ice := FrostRules.grip(BlockIds.ICE)
	assert_gt(AnimalRules.slide_factor(&"penguin", ice), 1.5, "a penguin slides faster on ice")
	assert_gt(AnimalRules.slide_factor(&"seal", ice), 1.5)
	assert_eq(AnimalRules.slide_factor(&"penguin", 1.0), 1.0, "and waddles on snow")
	assert_eq(AnimalRules.slide_factor(&"polar_bear", ice), 1.0, "a bear only slips")
	assert_true(AnimalRules.slides_on(&"penguin", ice))
	assert_false(AnimalRules.slides_on(&"penguin", 1.0))


func test_a_squirrel_runs_up_tree_trunks() -> void:
	assert_true(AnimalRules.climbs_trees(&"squirrel"))
	assert_false(AnimalRules.climbs_trees(&"deer"))
	for id: int in [BlockIds.LOG, BlockIds.PINE_LOG, BlockIds.PALM_LOG]:
		assert_true(AnimalRules.is_trunk(id), BlockIds.display_name(id))
	assert_false(AnimalRules.is_trunk(BlockIds.STONE))
	assert_false(AnimalRules.is_trunk(BlockIds.LEAVES), "it stops at the leaves")


func test_an_owl_is_awake_at_night_and_asleep_by_day() -> void:
	assert_true(AnimalRules.nocturnal(&"owl"))
	assert_false(AnimalRules.nocturnal(&"sheep"))
	assert_true(AnimalRules.feels_night(&"owl", false), "by day an owl feels its night: time to sleep")
	assert_false(AnimalRules.feels_night(&"owl", true), "at night it is awake")
	assert_true(AnimalRules.feels_night(&"sheep", true))


func test_frogs_and_gummy_bunnies_hop_high() -> void:
	assert_gt(AnimalRules.walk_hop(&"frog"), AnimalRules.walk_hop(&"sheep"))
	assert_gt(AnimalRules.walk_hop(&"gummy_bunny"), AnimalRules.walk_hop(&"rabbit"))
	assert_lt(AnimalRules.walk_hop(&"turtle"), AnimalRules.walk_hop(&"sheep"), "a turtle just plods")
	assert_eq(AnimalRules.walk_hop(&"sheep"), AnimalRules.WALK_HOP, "M1b's hop for everyone else")
	assert_eq(AnimalRules.hop_every(&"sheep"), AnimalRules.HOP_EVERY)


func test_a_turtle_lays_an_egg_on_sand_now_and_then() -> void:
	assert_true(AnimalRules.lays_egg(&"turtle", BlockIds.SAND, false, AnimalRules.EGG_EVERY + 1.0, 0.0))
	assert_false(AnimalRules.lays_egg(&"turtle", BlockIds.GRASS, false, AnimalRules.EGG_EVERY + 1.0, 0.0), "only on sand")
	assert_false(AnimalRules.lays_egg(&"turtle", BlockIds.SAND, true, AnimalRules.EGG_EVERY + 1.0, 0.0), "one egg at a time")
	assert_false(AnimalRules.lays_egg(&"turtle", BlockIds.SAND, false, 10.0, 0.0), "not again so soon")
	assert_false(AnimalRules.lays_egg(&"turtle", BlockIds.SAND, false, AnimalRules.EGG_EVERY + 1.0, 0.99), "now and then")
	assert_false(AnimalRules.lays_egg(&"duck", BlockIds.SAND, false, AnimalRules.EGG_EVERY + 1.0, 0.0), "only turtles")
	assert_gte(AnimalRules.EGG_EVERY, 60.0, "rare: a small secret")


func test_an_egg_hatches_when_a_child_comes_close() -> void:
	var egg := Vector3(4.5, 10, 4.5)
	var far: Array[Vector3] = [Vector3(12, 10, 4)]
	var near: Array[Vector3] = [Vector3(12, 10, 4), Vector3(5.5, 10, 5.0)]
	assert_eq(AnimalRules.hatch_by(egg, far), -1)
	assert_eq(AnimalRules.hatch_by(egg, near), 1, "the child who found it")
	assert_eq(AnimalRules.hatch_by(Vector3.INF, near), -1, "no egg")
