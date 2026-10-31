extends GutTest
## Review M1: the host refuses every edit that touches bedrock, whichever way it arrives: one tap,
## a batch, a stamp, a mirror copy. Solo play (OfflineMultiplayerPeer), so this game is the host
## and every edit goes through Session, as in the real game. A real, unsaved world; the bedrock
## cells are put in the air above the spawn column, next to the (not yet spawned) player.

var world: WorldService
var player: Player
var interactor: BlockInteractor
var base: Vector3i   # the player's feet cell


func before_all() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child(world)
	var c := world.spawn_column()
	base = Vector3i(c.x, maxi(world.surface_height(c.x, c.y), MeadowsShape.SEA_LEVEL) + 20, c.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	world.add_child(viewer)
	viewer.global_position = Vector3(base)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child(player)
	player.viewer.free()   # the viewer above streams the test area
	player.global_position = Vector3(base) + Vector3(0.5, 0.0, 0.5)
	interactor = player.get_node("BlockInteractor")
	Session.register_world(world)
	await wait_until(_area_loaded, 15.0, "terrain loads")


func after_all() -> void:
	Session.world = null
	player.free()
	world.free()


func _area_loaded() -> bool:
	for corner: Vector3i in [Vector3i(-16, -8, -16), Vector3i(16, 12, 16), Vector3i(-16, 12, 16), Vector3i(16, -8, -16)]:
		if not world.is_editable(base + corner):
			return false
	return true


func test_a_tap_never_breaks_or_replaces_bedrock() -> void:
	var rock := base + Vector3i(2, 0, -1)
	world.set_block(rock, BlockIds.BEDROCK)
	watch_signals(Session)
	assert_false(Session.request_set_block(rock, BlockIds.AIR), "break")
	assert_false(Session.request_set_block(rock, BlockIds.STONE), "replace")
	assert_eq(world.get_block(rock), BlockIds.BEDROCK)
	assert_signal_emit_count(Session, "edit_rejected", 2)
	assert_signal_emitted_with_parameters(Session, "magic_feedback", [PlacementRules.BEDROCK_MESSAGE])
	var stone := rock + Vector3i.UP   # the same tap on a plain block works
	world.set_block(stone, BlockIds.STONE)
	assert_true(Session.request_set_block(stone, BlockIds.AIR))
	assert_eq(world.get_block(stone), BlockIds.AIR)


func test_a_batch_skips_bedrock_and_applies_the_rest() -> void:
	var rock := base + Vector3i(-2, 0, 2)
	var spot := base + Vector3i(-2, 1, 2)
	world.set_block(rock, BlockIds.BEDROCK)
	world.set_block(spot, BlockIds.AIR)
	assert_true(Session.request_set_blocks([[rock, BlockIds.AIR], [spot, BlockIds.BRICK]]), "the brick applies")
	assert_eq(world.get_block(rock), BlockIds.BEDROCK)
	assert_eq(world.get_block(spot), BlockIds.BRICK)
	assert_false(Session.request_set_blocks([[rock, BlockIds.STONE], [rock, BlockIds.AIR]]), "nothing to apply")
	assert_eq(world.get_block(rock), BlockIds.BEDROCK)


## A house stamped on the bedrock floor: its planks floor would replace the bedrock.
func test_a_stamp_on_bedrock_keeps_the_bedrock_and_builds_the_rest() -> void:
	var anchor := base + Vector3i(0, 0, -6)
	var changes := Blueprints.place(ItemIds.STAMP_HOUSE, anchor, Vector3i(0, 0, -1))
	var floor_cells: Array[Vector3i] = []
	for e: Array in changes:
		if (e[0] as Vector3i).y == anchor.y - 1:
			floor_cells.append(e[0])
	assert_gt(floor_cells.size(), 0)
	for p in floor_cells:
		world.set_block(p, BlockIds.BEDROCK)
	assert_true(interactor.apply_edits(changes))
	var wrong := 0
	for e: Array in changes:
		var want: int = BlockIds.BEDROCK if floor_cells.has(e[0]) else e[1]
		if world.get_block(e[0]) != want:
			wrong += 1
	assert_eq(wrong, 0, "the floor stays bedrock, every other stamp block is built")


func test_a_mirror_copy_never_lands_on_bedrock() -> void:
	var left := base + Vector3i(-3, 2, -2)
	var right := MirrorRules.mirror(left, MirrorRules.Axis.X, base.x)
	assert_ne(left, right)
	world.set_block(left, BlockIds.AIR)
	world.set_block(right, BlockIds.BEDROCK)
	interactor.mirror_enabled = true
	interactor.mirror_axis = MirrorRules.Axis.X
	interactor.mirror_plane = base.x
	assert_true(interactor.apply_edits([[left, BlockIds.BRICK]]))
	interactor.mirror_enabled = false
	assert_eq(world.get_block(left), BlockIds.BRICK)
	assert_eq(world.get_block(right), BlockIds.BEDROCK, "the mirror copy is refused")
