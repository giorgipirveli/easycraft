extends GutTest
## Sleeping in a bed and going home, on a real Player (M1b Task 10).

const BED := Vector3i(4, 30, -2)

var world: WorldService
var player: Player


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = "1"
	player.world = world
	add_child_autofree(player)
	player.viewer.free()   # no terrain streaming: these tests never need loaded blocks


## The avatar model lies down (AvatarModel.set_pose, the same for both styles): on its back, face
## up, the head at the pillow end of the bed (+Z), resting on the mattress. (Merge of Tasks 10 + 13:
## the model owns the pose, so the body is measured at its pivot, 0.9 above the feet when standing.)
func test_a_sleeper_lies_on_the_bed_with_the_head_on_the_pillow() -> void:
	player.set_sleeping(true, BED)
	assert_true(player.sleeping)
	assert_eq(player.global_position, BedRules.lie_position(BED))
	var body := player.avatar.body_pivot().global_transform
	assert_gt((body.basis * Vector3.FORWARD).y, 0.9, "the face (-Z) looks up")
	assert_gt((body.basis * Vector3.UP).z, 0.9, "the head points to +Z, the pillow end")
	var head := body * Vector3(0, CameraRig.HEAD_HEIGHT - 0.9, 0)
	assert_between(head.z, BED.z + 0.5, BED.z + 1.0, "the head rests on the pillow")
	assert_between(head.y, BED.y + BedRules.TOP, BED.y + BedRules.TOP + 0.6, "on the mattress")
	player.set_sleeping(false, BED)
	assert_false(player.sleeping)
	var up := player.avatar.body_pivot().global_transform.basis * Vector3.UP
	assert_gt(up.y, 0.9, "standing again")
	assert_eq(player.avatar.position, Vector3.ZERO)


func test_a_sleeper_puffs_zzz_until_it_wakes() -> void:
	player.set_sleeping(true, BED)
	await wait_seconds(0.3)
	assert_gt(player.find_children("*", "Label3D", true, false).size(), 0, "a Z floats up")
	player.set_sleeping(false, BED)
	await wait_seconds(Player.ZZZ_RISE_TIME + 0.2)
	assert_eq(player.find_children("*", "Label3D", true, false).size(), 0, "no more Zs once awake")


func test_going_home_heads_for_the_bed() -> void:
	player.set_home(true, BED)
	player.go_home()
	assert_false(player.is_spawned(), "it waits for the terrain there")
	assert_eq(player._spawn_target, BedRules.home_position(BED))


func test_without_a_home_going_home_is_the_world_spawn() -> void:
	player.go_home()
	var c := world.spawn_column()
	assert_eq(Vector2(player._spawn_target.x, player._spawn_target.z), Vector2(c.x + 0.5, c.y + 0.5))
	assert_true(is_nan(player._spawn_target.y), "on the surface there")


func test_falling_out_of_the_world_goes_home() -> void:
	player.set_home(true, BED)
	player.global_position = Vector3(50.5, -70.0, 50.5)
	player._rescue_to_surface()
	assert_eq(player._spawn_target, BedRules.home_position(BED))


func test_ghosts_below_the_world_still_pop_up_where_they_are() -> void:
	player.set_home(true, BED)
	player.set_physics_mode(PhysicsMode.Mode.GHOST)
	player.global_position = Vector3(50.5, -70.0, 50.5)
	player._rescue_to_surface()
	assert_eq(Vector2(player.global_position.x, player.global_position.z), Vector2(50.5, 50.5))
	assert_gt(player.global_position.y, SpawnRules.FALL_LIMIT_Y)


## Review M4: /tp, /spawn, /fly and /size moved or changed a sleeper who kept lying down (still
## counted as asleep in a bed far away). The command wakes them up first.
class RunnerSandbox:
	extends Node
	var player: Player
	var world: WorldService


func test_moving_commands_wake_a_sleeper_first() -> void:
	var runner := ChatCommandRunner.new()
	var sb := RunnerSandbox.new()
	sb.player = player
	sb.world = world
	runner.sandbox = sb
	add_child_autofree(runner)          # run() asks the tree for this game's peer id
	for text in ["/tp 10 40 10", "/spawn", "/fly", "/size giant"]:
		player.set_sleeping(true, BED)
		watch_signals(Session)
		runner.run(text)
		assert_signal_emitted(Session, "bed_wake_requested", text)
		player.set_sleeping(false, BED)
		player.set_physics_mode(PhysicsMode.Mode.NORMAL)
	sb.free()


## The developer autopilot's 2 km flight is a ghost flight in every world (dev menu WORLD starts a Survivor world, whose
## rules refuse Ghost mode: the "flight" became a walk that stuck at the first cliff). Only a player the autopilot
## flies (`autopilot_ghost`) may ghost in Survivor; any other Survivor player still may not.
func test_only_the_autopilot_may_ghost_in_survivor() -> void:
	var before := Game.mode
	Game.mode = ModeRules.SURVIVOR
	player.set_physics_mode(PhysicsMode.Mode.GHOST)
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL, "Survivor has no Ghost mode")
	player.autopilot_ghost = true
	player.set_physics_mode(PhysicsMode.Mode.GHOST)
	assert_eq(player.physics_mode, PhysicsMode.Mode.GHOST, "the autopilot flies through hills")
	Game.mode = before
