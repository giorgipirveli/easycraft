extends GutTest
## M3 Task 4: a world of universe 4 is the Candy Kingdom. WorldService.setup(..., 4) takes the kingdom's terrain
## rules and generator (UniverseRegistry: world.descriptor()), the ground it generates is the kingdom's, and
## --universe=4 picks it for a Survivor world. Its water looks like chocolate (one uniform on the shared water
## material; the next world's water is water again); a player landing on a gumdrop bounces back up (walking on
## one does not); sprinkles fall round this game's player at night under the open sky.

const FAKE_ARGS := ["--survivor", "--new-world", "--universe=4"]


func after_each() -> void:
	BlockLibrary.set_liquid(&"")


func test_universe_4_is_the_candy_kingdom() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 4)
	add_child_autofree(w)
	assert_eq(w.universe, 4)
	assert_eq(w.descriptor().get("name"), &"candy")
	assert_true(w.generator_shape() is CandyShape)
	assert_eq(w.surface_height(10, 20), CandyShape.new(77).height_at(10, 20))
	assert_eq(w.spawn_column(), CandyShape.new(77).spawn_column())


func test_the_kingdom_generates_its_own_ground() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 4)
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
	assert_eq(w.get_block(below), BlockIds.FROSTING, "frosting under the spawn")
	var gen := CandyGenerator.new()
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "the candy generator's block (cake, or a cave)")
	assert_eq(w.get_block(below + Vector3i(0, 2, 0)), BlockIds.AIR)


func test_the_developer_argument() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", FAKE_ARGS), 4)


func test_the_water_is_chocolate_here_and_water_elsewhere() -> void:
	BlockLibrary.build()
	BlockLibrary.set_liquid(&"chocolate")
	assert_eq(BlockLibrary.liquid_chocolate(), 1.0)
	BlockLibrary.set_liquid(&"")
	assert_eq(BlockLibrary.liquid_chocolate(), 0.0, "the next world's water is water again")
	var lib := BlockLibrary.build()
	var water := lib.models[BlockIds.WATER] as VoxelBlockyModel
	assert_true(water.collision_aabbs.is_empty(), "chocolate or not, it is still water: you swim in it")


# --- Gumdrops bounce ----------------------------------------------------------------------------------------

class CandyFloor:
	extends WorldService
	var top_block := BlockIds.GUMDROP

	func get_block(p: Vector3i) -> int:
		if p.y == 9:
			return top_block
		return BlockIds.CAKE if p.y < 9 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true


var _world: CandyFloor
var _player: Player


func _setup(top: int) -> void:
	_world = CandyFloor.new()
	_world.top_block = top
	add_child_autofree(_world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 10, 200)
	shape.shape = box
	shape.position = Vector3(0, 5, 0)
	ground.add_child(shape)
	_world.add_child(ground)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = _world
	add_child_autofree(_player)


## Dropped from 4 blocks up, the player lands and then goes back up again (and settles).
func _bounce_after_landing(top: int) -> float:
	_setup(top)
	_player.spawn_at(Vector3(0.5, 10.0, 0.5))
	await wait_until(func() -> bool: return _player.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(5)
	_player.global_position = Vector3(0.5, 14.0, 0.5)   # a drop of 4 blocks
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(1)
	var landed := false
	var rise := 0.0
	var low := 99.0
	for i in 120:
		await wait_physics_frames(1)
		var y := _player.global_position.y
		if _player.is_on_floor():
			landed = true
		if landed:
			low = minf(low, y)
			rise = maxf(rise, y - low)
	return rise


func test_landing_on_a_gumdrop_bounces_the_player_back_up() -> void:
	var rise := await _bounce_after_landing(BlockIds.GUMDROP)
	assert_gt(rise, 1.0, "boing: back up over a block (%.2f)" % rise)


func test_landing_on_frosting_does_not_bounce() -> void:
	var rise := await _bounce_after_landing(BlockIds.FROSTING)
	assert_lt(rise, 0.2, "it just lands (%.2f)" % rise)


# --- Sprinkles at night ---------------------------------------------------------------------------------------

func test_sprinkles_fall_round_the_player_at_night_under_the_sky() -> void:
	var holder := Node3D.new()
	add_child_autofree(holder)
	holder.global_position = Vector3(30, 40, -20)
	var t := [DayCycle.MIDNIGHT]
	var under := [0.0]
	var s := CandySprinkles.new()
	s.player = holder
	s.time_of_day = func() -> float: return t[0]
	s.underground = func() -> float: return under[0]
	add_child_autofree(s)
	s.set_process(false)
	s.tick(1.0)
	assert_true(s.is_falling(), "at night")
	assert_almost_eq(s.particles().global_position, holder.global_position + Vector3(0, CandySprinkles.ABOVE, 0), Vector3.ONE * 0.01,
		"above the player's head")
	assert_false(s.particles().local_coords, "they fall in the world while the player walks on")
	assert_same(s.particles().mesh, CandySprinkles.sprinkle_mesh(), "one shared sprinkle")
	assert_same((s.particles().mesh as BoxMesh).material, Fx.material(), "the shared Fx material: no new shader")
	t[0] = DayCycle.NOON
	s.tick(1.0)
	assert_false(s.is_falling(), "not by day")
	t[0] = DayCycle.MIDNIGHT
	under[0] = 0.9
	s.tick(1.0)
	assert_false(s.is_falling(), "not in a cave")
