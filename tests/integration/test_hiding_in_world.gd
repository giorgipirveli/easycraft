extends GutTest
## M2 Task 5 end to end on a real (unsaved) world, solo (this game is the host): a tap on a barrel or
## closet close by hides the player inside through the host (whatever is in the hand; no block is
## placed), a tap while inside comes out on the side it went in, a tap from too far away says so, and
## a bush is walked into. The test area is in the air above the spawn column.

var world: WorldService
var player: Player
var interactor: BlockInteractor
var director: StealthDirector
var base: Vector3i   # the player's feet cell


func before_all() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child(world)
	var c := world.spawn_column()
	base = Vector3i(c.x, maxi(world.surface_height(c.x, c.y), MeadowsShape.SEA_LEVEL) + 24, c.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	world.add_child(viewer)
	viewer.global_position = Vector3(base)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child(player)
	player.viewer.free()
	player.set_physics_process(false)
	player.rig.process_mode = Node.PROCESS_MODE_DISABLED   # the test aims the camera
	player._spawned = true
	interactor = player.get_node("BlockInteractor")
	Session.register_world(world)
	director = StealthDirector.new()
	director.block_at = world.get_block
	director.surface_height = world.surface_height
	director.local_player = player
	add_child(director)
	director.start_host()
	director.watch_blocks(world)
	await wait_until(_area_loaded, 15.0, "terrain loads")


func after_all() -> void:
	Session.world = null
	director.free()
	player.free()
	world.free()


func before_each() -> void:
	if player.is_hiding():
		player.set_hidden(false, player.hidden_in)
	_floor(base)


func _area_loaded() -> bool:
	for corner: Vector3i in [Vector3i(-8, -2, -8), Vector3i(8, 4, 8)]:
		if not world.is_editable(base + corner):
			return false
	return true


## A small stone floor under the test area, and air above it.
func _floor(at: Vector3i) -> void:
	for x in range(-4, 5):
		for z in range(-4, 5):
			world.set_block(at + Vector3i(x, -1, z), BlockIds.STONE)
			for y in 3:
				world.set_block(at + Vector3i(x, y, z), BlockIds.AIR)


func _tap_at(cell: Vector3i, from: Vector3) -> bool:
	player.global_position = from
	player.camera().global_position = player.eye_position()
	player.camera().look_at(Vector3(cell) + Vector3(0.5, 0.5, 0.5))
	return interactor.place_at_screen(interactor.get_viewport().get_visible_rect().size * 0.5)


func test_a_tap_on_a_barrel_hides_the_player_inside_and_a_tap_brings_them_out() -> void:
	var barrel := base + Vector3i(2, 0, 0)
	world.set_block(barrel, BlockIds.BARREL)
	interactor.hotbar[interactor.selected_slot] = BlockIds.PLANKS
	await get_tree().physics_frame
	assert_true(_tap_at(barrel, Vector3(base) + Vector3(0.5, 0, 0.5)))
	assert_true(player.is_hiding(), "inside")
	assert_eq(player.hidden_in, barrel)
	assert_eq(world.get_block(barrel + Vector3i.UP), BlockIds.AIR, "no plank was placed on it")
	assert_almost_eq(player.global_position, Vector3(barrel) + Vector3(0.5, 0, 0.5), Vector3.ONE * 0.01)
	assert_true(interactor.place_at_screen(Vector2(10, 10)), "any tap")
	assert_false(player.is_hiding(), "out again")
	assert_almost_eq(player.global_position, Vector3(base) + Vector3(1.5, 0, 0.5), Vector3.ONE * 0.01,
		"on the side it went in, right next to the barrel")


func test_even_with_a_sword_in_hand() -> void:
	var closet := base + Vector3i(0, 0, 2)
	world.set_block(closet, BlockIds.CLOSET)
	interactor.hotbar[interactor.selected_slot] = ItemIds.SWORD
	await get_tree().physics_frame
	_tap_at(closet, Vector3(base) + Vector3(0.5, 0, 0.5))
	assert_true(player.is_hiding(), "a tap on a closet is a hide, not a swing")


func test_a_tap_on_a_barrel_too_far_away_says_so() -> void:
	var barrel := base + Vector3i(4, 0, 0)
	world.set_block(barrel, BlockIds.BARREL)
	await get_tree().physics_frame
	watch_signals(Session)
	_tap_at(barrel, Vector3(base) + Vector3(-3.5, 0, 0.5))
	assert_false(player.is_hiding())
	assert_signal_emitted_with_parameters(Session, "magic_feedback", [StealthRules.TOO_FAR_MESSAGE])


func test_breaking_the_barrel_brings_the_player_out() -> void:
	var barrel := base + Vector3i(-2, 0, 0)
	world.set_block(barrel, BlockIds.BARREL)
	await get_tree().physics_frame
	_tap_at(barrel, Vector3(base) + Vector3(0.5, 0, 0.5))
	assert_true(player.is_hiding())
	world.set_block(barrel, BlockIds.AIR)
	assert_false(player.is_hiding())


func test_a_bush_is_walked_into_and_crouching_there_hides() -> void:
	var bush := base + Vector3i(1, 0, -2)
	world.set_block(bush, BlockIds.BUSH)
	player.global_position = Vector3(bush) + Vector3(0.5, 0, 0.5)
	director.refresh(player)
	assert_true(player.stealth_in_bush)
	assert_false(player.is_hidden(), "standing up in it: seen")
	player.set_crouching(true)
	assert_true(player.is_hidden())
	player.set_crouching(false)
