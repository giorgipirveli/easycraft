extends GutTest
## Review I1: another player's position, speed and facing arrive over LAN. A tampered NaN must
## never spread from that body into reach checks, following pets or the host's save.

var world: WorldService
var remote: Player


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	remote = load("res://entities/player/player.tscn").instantiate()
	remote.name = "777"                 # a peer other than this game: its body is remote here
	remote.world = world
	add_child_autofree(remote)


func test_a_non_finite_remote_update_keeps_the_last_good_state() -> void:
	remote.position = Vector3(4, 30, -2)
	remote._update_remote(0.016)
	remote.position = Vector3(NAN, 30, INF)
	remote.velocity = Vector3(NAN, 0, 0)
	remote.avatar.rotation = Vector3(0, NAN, 0)
	remote._update_remote(0.016)
	assert_eq(remote.position, Vector3(4, 30, -2), "back where it last was")
	assert_true(remote.velocity.is_finite())
	assert_true(remote.avatar.rotation.is_finite())


## Found in the M12 work: the host streamed terrain around a guest without collision, so animals
## (simulated on the host) near a guest fell through the ground, and wild ones were removed and
## respawned over and over. The host builds collision around each guest, as far as animals live.
func test_the_host_builds_collision_around_a_guest() -> void:
	var collision: Array[VoxelViewer] = []
	for v in remote.find_children("*", "VoxelViewer", true, false):
		if (v as VoxelViewer).requires_collisions:
			collision.append(v)
	assert_eq(collision.size(), 1, "one collision viewer")
	if collision.size() != 1:
		return
	assert_gte(collision[0].view_distance, int(AnimalRules.ACTIVE_DISTANCE) + 8, "covering where animals are simulated")
	assert_false(collision[0].requires_visuals, "collision only: the host never draws a guest's world")


## Real water (M2 Task 14): each player's own game decides its water state and syncs it; every other
## game shows the same swim pose and effects from it (and from the synced speed).
func test_a_remote_swimmer_swims_and_splashes_here_too() -> void:
	remote.position = Vector3(4, 30, -2)
	remote._update_remote(0.016)
	remote.water_state = SwimRules.State.SWIMMING
	remote.velocity = Vector3(0, -9, 0)
	remote._update_remote(0.016)
	assert_eq(remote.avatar.pose, AvatarModel.POSE_SWIM)
	var fx := world.find_children("*", "CPUParticles3D", false, false)
	assert_gt(fx.size(), 0, "the splash shows in this game too")
	remote.water_state = SwimRules.State.DRY
	remote._update_remote(0.016)
	assert_eq(remote.avatar.pose, AvatarModel.POSE_STAND)
	assert_eq(remote.find_children("*", "CPUParticles3D", false, false).size(), 1, "and drips after the swim")


func test_a_bad_remote_water_state_is_kept_in_range() -> void:
	remote.water_state = 99
	remote._update_remote(0.016)
	assert_eq(remote.water_state, SwimRules.State.DIVING)
	remote.water_state = -5
	remote._update_remote(0.016)
	assert_eq(remote.water_state, SwimRules.State.DRY)
