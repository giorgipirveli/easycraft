extends GutTest
## Terrain streaming per player (M1b acceptance run 3 on the emulator): the player's view streamed
## collision for every chunk out to the view distance (128), built on the main thread, and flights
## still had 108-145 ms frames with scripts idle. Collision is only needed close by: for the body
## and for animals, which are simulated within AnimalRules.ACTIVE_DISTANCE of a player.

var world: WorldService


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)


func _player(peer: int) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	return p


func _collision_viewers(p: Player) -> Array[VoxelViewer]:
	var list: Array[VoxelViewer] = []
	for v in p.find_children("*", "VoxelViewer", true, false):
		if (v as VoxelViewer).requires_collisions:
			list.append(v)
	return list


func test_the_local_player_builds_collision_only_close_by() -> void:
	var me := _player(multiplayer.get_unique_id())
	assert_true(me.viewer.requires_visuals, "the view streams what you see")
	assert_false(me.viewer.requires_collisions, "but no collision out to the view distance")
	var near := _collision_viewers(me)
	assert_eq(near.size(), 1, "one collision viewer")
	if near.size() != 1:
		return
	assert_eq(near[0].view_distance, Player.COLLISION_DISTANCE)
	assert_gte(near[0].view_distance, int(AnimalRules.ACTIVE_DISTANCE) + 8, "covering where animals are simulated")
	assert_false(near[0].requires_visuals)


func test_a_guest_on_the_host_gets_the_same_collision_viewer() -> void:
	var guest := _player(4242)
	var near := _collision_viewers(guest)
	assert_eq(near.size(), 1)
	if near.size() == 1:
		assert_eq(near[0].view_distance, Player.COLLISION_DISTANCE)
