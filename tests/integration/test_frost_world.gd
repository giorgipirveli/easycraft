extends GutTest
## M3 Task 3: a world of universe 3 is Frostpeak. WorldService.setup(..., 3) takes Frostpeak's terrain rules
## and generator (UniverseRegistry's descriptor), the ground it generates is Frostpeak's, and --universe=3
## picks it for a Survivor world.


func test_universe_3_is_frostpeak() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 3)
	add_child_autofree(w)
	assert_eq(w.universe, 3)
	assert_not_null(w.descriptor())
	assert_eq(w.descriptor().get("name"), &"frost")
	assert_true(w.generator_shape() is FrostShape)
	assert_eq(w.surface_height(10, 20), FrostShape.new(77).height_at(10, 20))
	assert_eq(w.spawn_column(), FrostShape.new(77).spawn_column())


func test_frostpeak_generates_its_own_ground() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 3)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var below := Vector3i(spawn.x, h - 1, spawn.y)
	var deeper := below + Vector3i(0, -2, 0)
	await wait_until(func() -> bool: return w.is_editable(below) and w.is_editable(deeper), 15.0, "terrain loads")
	assert_eq(w.get_block(below), BlockIds.SNOWY_GRASS, "snowy grass under the spawn")
	var gen := FrostGenerator.new()
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "Frostpeak's generator's block")
	assert_eq(w.get_block(below + Vector3i(0, 2, 0)), BlockIds.AIR)


func test_the_developer_argument() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=3"]), 3)
