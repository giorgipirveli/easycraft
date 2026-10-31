extends GutTest
## Regression found on the emulator (M1b): after the vertical-streaming change, continuing a world
## saved in mid-air (e.g. after flying) waited the full 10 s spawn timeout, because the ground the
## spawn waits for lay outside the streamed box around the parked player.

var world: WorldService
var player: Player


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	player.set_view_distance(GraphicsPreset.MIN_VIEW_DISTANCE)


func test_a_mid_air_save_spawns_quickly() -> void:
	var c := world.spawn_column()
	var target := Vector3(c.x + 0.5, world.surface_height(c.x, c.y) + 70.0, c.y + 0.5)
	var start := Time.get_ticks_msec()
	player.spawn_at(target)
	await wait_until(func() -> bool: return player.is_spawned(), Player.SPAWN_TIMEOUT + 2.0, "spawned")
	assert_true(player.is_spawned())
	assert_lt(Time.get_ticks_msec() - start, int(Player.SPAWN_TIMEOUT * 1000.0 * 0.6), "well before the timeout")
