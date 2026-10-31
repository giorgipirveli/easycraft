extends GutTest
## M3 Task 2: a world of universe 2 is the Sandstorm Desert. WorldService.setup(..., 2) takes the desert's
## terrain rules and generator (the stand-in for M3 Task 5's UniverseRegistry: world.descriptor()), the
## ground it generates is the desert's, and --universe=2 picks it for a Survivor world.

const FAKE_ARGS := ["--survivor", "--new-world", "--universe=2"]


func test_universe_2_is_the_desert_and_1_is_green_meadows() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 2)
	add_child_autofree(w)
	assert_eq(w.universe, 2)
	assert_not_null(w.descriptor())
	assert_eq(w.descriptor().get("name"), &"desert")
	assert_true(w.generator_shape() is DesertShape)
	assert_eq(w.surface_height(10, 20), DesertShape.new(77).height_at(10, 20))
	assert_eq(w.spawn_column(), DesertShape.new(77).spawn_column())
	var m: WorldService = load("res://world/world.tscn").instantiate()
	m.setup("", 77)
	add_child_autofree(m)
	assert_eq(m.universe, 1)
	assert_null(m.descriptor())
	assert_false(m.generator_shape() is DesertShape)


func test_the_desert_generates_its_own_ground() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 2)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var below := Vector3i(spawn.x, h - 1, spawn.y)
	var deeper := below + Vector3i(0, -DesertShape.SAND_DEPTH, 0)
	await wait_until(func() -> bool: return w.is_editable(below) and w.is_editable(deeper), 15.0, "terrain loads")
	assert_eq(w.get_block(below), BlockIds.SAND, "sand under the spawn")
	var gen := DesertGenerator.new()
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "the desert generator's block (sandstone, or a cave)")
	assert_eq(w.get_block(below + Vector3i(0, 2, 0)), BlockIds.AIR)


func test_the_developer_argument() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", FAKE_ARGS), 2)
	assert_eq(main.call(&"_universe_arg", ["--survivor"]), 1)
	assert_eq(main.call(&"_universe_arg", ["--universe=0"]), 1)
