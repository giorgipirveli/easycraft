extends GutTest
## M3 Task 14a on a real Player with real physics (Jolt): the glider (a slow fall, steering, closing on
## landing; JUMP after the last air jump; a launch pad opens it by itself), the grappling hook through the
## host (pulled to the block, never through a wall, 24 blocks, once a second, a guest's request checked with
## the host's own positions) and ziplines (two posts link, a tap rides down the line and slides off at the
## end; a lone post and a far one say so; a broken post takes its line away; every game draws the lines).
##
## The fake world: a stone floor with its top at y = 10 everywhere (a physics box too) and a stone wall from
## x = 20 up to y = 30 (a physics box too); `cells` adds blocks the rules see (posts, pads, pillars).

class GadgetWorld:
	extends WorldService
	var cells := {}

	func get_block(p: Vector3i) -> int:
		if cells.has(p):
			return cells[p]
		if p.y <= 9 or (p.x >= 20 and p.y <= 30):
			return BlockIds.STONE
		return BlockIds.AIR

	func set_block(p: Vector3i, id: int) -> void:
		var old := get_block(p)
		if old == id:
			return
		cells[p] = id
		block_changed.emit(p, old, id)

	func surface_height(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true

	func is_editable(_pos: Vector3i) -> bool:
		return true


const DT := 1.0 / 60.0
const WALL_CELL := Vector3i(20, 12, 0)

var world: GadgetWorld
var player: Player
var zips: ZiplineDirector
var _said: Array = []
var _mode_before: StringName
var _inv_before: Inventory


func before_each() -> void:
	_mode_before = Game.mode
	_inv_before = Session.my_inventory
	Game.mode = ModeRules.SANDBOX
	Session.gadget_reset()
	_said.clear()
	Session.magic_feedback.connect(_on_said)


func after_each() -> void:
	for a: StringName in [&"move_forward", &"jump"]:
		Input.action_release(a)
	Session.magic_feedback.disconnect(_on_said)
	Game.mode = _mode_before
	Session.my_inventory = _inv_before
	Session.register_world(null)
	Session.survivor_reset()
	Session.gadget_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_said(text: String) -> void:
	_said.append(text)


func _setup() -> void:
	world = GadgetWorld.new()
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	_box(ground, Vector3(400, 10, 400), Vector3(0, 5, 0))       # the floor, its top at 10
	_box(ground, Vector3(10, 40, 400), Vector3(25, 20, 0))      # the wall, its face at x = 20
	world.add_child(ground)
	Session.register_world(world)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	zips = ZiplineDirector.new()
	add_child_autofree(zips)
	zips.block_at = world.get_block
	zips.owner_near = func(_post: Vector3i) -> String: return "Kid"
	world.block_changed.connect(zips.note_block)


func _box(body: StaticBody3D, size: Vector3, center: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = center
	body.add_child(shape)


func _spawn(pos: Vector3) -> void:
	player.spawn_at(pos)
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(10)


## Puts the player high in the air, falling.
func _drop_from(pos: Vector3, vy: float = -12.0) -> void:
	player.global_position = pos
	player.velocity = Vector3(0, vy, 0)
	await wait_physics_frames(1)


# --- Glider ----------------------------------------------------------------------------------------------

func test_the_glider_opens_in_the_air_falls_slowly_steers_and_closes_on_landing() -> void:
	_setup()
	await _spawn(Vector3(0.5, 10.0, 0.5))
	assert_false(player.open_glider(), "not on the ground")
	await _drop_from(Vector3(0.5, 22.0, 0.5))
	assert_true(player.open_glider())
	assert_eq(player.gadget_move, GadgetRules.Move.GLIDE)
	Input.action_press(&"move_forward")
	await wait_physics_frames(40)
	var start := player.global_position
	for i in 30:
		await wait_physics_frames(1)
		assert_gte(player.velocity.y, -GadgetRules.GLIDE_FALL_SPEED - 0.01, "a slow descent")
	var moved := player.global_position - start
	assert_gt(Vector2(moved.x, moved.z).length(), (start.y - player.global_position.y) * 1.5, "it glides far")
	Input.action_release(&"move_forward")
	await wait_until(func() -> bool: return player.is_on_floor(), 10.0, "landed")
	await wait_physics_frames(2)
	assert_eq(player.gadget_move, GadgetRules.Move.NONE, "it closes on landing")


func test_jump_in_the_air_after_the_last_air_jump_opens_the_glider() -> void:
	_setup()
	await _spawn(Vector3(0.5, 10.0, 0.5))
	await _drop_from(Vector3(0.5, 30.0, 0.5))
	player._jumps.jumps_used = player._jumps.max_jumps
	Input.action_press(&"jump")
	await wait_physics_frames(2)
	Input.action_release(&"jump")
	assert_eq(player.gadget_move, GadgetRules.Move.GLIDE)
	player._jumps.jumps_used = 1
	player.toggle_glider()
	assert_eq(player.gadget_move, GadgetRules.Move.NONE, "the GLIDE button folds it again (DROP)")


func test_survivor_needs_a_glider_in_the_bag() -> void:
	_setup()
	Game.mode = ModeRules.SURVIVOR
	Session.my_inventory = Inventory.new()
	await _spawn(Vector3(0.5, 10.0, 0.5))
	await _drop_from(Vector3(0.5, 30.0, 0.5))
	assert_false(player.can_glide(), "no glider")
	Session.my_inventory.add(ItemIds.GLIDER, 1)
	assert_true(player.can_glide(), "bought from Tilly")


func test_a_launch_pad_throws_high_and_the_glider_opens_at_the_top() -> void:
	_setup()
	world.cells[Vector3i(0, 9, 0)] = BlockIds.LAUNCH_PAD
	await _spawn(Vector3(3.5, 10.0, 0.5))
	var peak := [player.global_position.y]   # a lambda keeps its own copy of a plain local
	player.global_position = Vector3(0.5, 10.0, 0.5)
	await wait_until(func() -> bool:
		peak[0] = maxf(peak[0], player.global_position.y)
		return player.gadget_move == GadgetRules.Move.GLIDE, 4.0, "the glider opens by itself")
	assert_eq(player.gadget_move, GadgetRules.Move.GLIDE)
	assert_gt(peak[0] - 10.0, 12.0, "much higher than a jump pad")


func test_every_game_sees_the_glider_and_a_tampered_state_is_nothing() -> void:
	_setup()
	var cfg := (player.get_node("Sync") as MultiplayerSynchronizer).replication_config
	for prop in [".:gadget_move", ".:glider_look"]:
		assert_true(cfg.has_property(NodePath(prop)), prop)
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		assert_true(cfg.property_get_spawn(NodePath(prop)))
	var other: Player = load("res://entities/player/player.tscn").instantiate()
	other.name = "7"
	other.world = world
	add_child_autofree(other)
	other.gadget_move = GadgetRules.Move.GLIDE
	other.glider_look = 2
	await wait_process_frames(2)
	var looks := other.get_node("GadgetLooks") as GadgetLooks
	assert_eq(looks.showing(), [&"canopy"])
	other.gadget_move = 99
	await wait_process_frames(2)
	assert_eq(other.gadget_move, GadgetRules.Move.NONE)
	assert_eq(looks.showing(), [])
	var before := GadgetModels.cached_count()
	for i in 5:
		other.gadget_move = GadgetRules.Move.GLIDE
		await wait_process_frames(1)
		other.gadget_move = GadgetRules.Move.ZIP
		await wait_process_frames(1)
	assert_eq(GadgetModels.cached_count(), before, "no mesh is made per use")

# --- Grappling hook ----------------------------------------------------------------------------------------

func test_the_hook_pulls_the_player_to_the_wall_and_lets_go_with_a_hop() -> void:
	_setup()
	await _spawn(Vector3(8.5, 10.0, 0.5))
	watch_signals(Session)
	assert_true(Session.request_hook(WALL_CELL))
	assert_signal_emitted(Session, "gadget_hooked")
	assert_eq(player.gadget_move, GadgetRules.Move.HOOK)
	assert_true(player.hook_point.is_finite())
	await wait_until(func() -> bool: return player.gadget_move == GadgetRules.Move.NONE, 2.0, "arrived")
	assert_gt(player.global_position.x, 16.5, "pulled across to the wall")
	assert_gt(player.velocity.y, 0.0, "a hop up at the end")


func test_a_wall_in_between_stops_the_hook() -> void:
	_setup()
	world.cells[Vector3i(14, 11, 0)] = BlockIds.BRICK
	world.cells[Vector3i(14, 12, 0)] = BlockIds.BRICK
	world.cells[Vector3i(14, 13, 0)] = BlockIds.BRICK
	await _spawn(Vector3(8.5, 10.0, 0.5))
	assert_false(Session.request_hook(WALL_CELL))
	assert_eq(player.gadget_move, GadgetRules.Move.NONE)
	assert_has(_said, GadgetRules.hook_message("wall"))


func test_the_hook_reaches_24_blocks_and_waits_a_second() -> void:
	_setup()
	await _spawn(Vector3(-8.5, 10.0, 0.5))
	assert_false(Session.request_hook(WALL_CELL), "28 blocks away")
	assert_has(_said, GadgetRules.hook_message("far"))
	player.global_position = Vector3(4.5, 10.0, 0.5)
	var now := [1000]
	Session.gadget_now_ms = func() -> int: return now[0]
	assert_true(Session.request_hook(WALL_CELL))
	player._set_gadget_move(GadgetRules.Move.NONE)
	player.global_position = Vector3(4.5, 10.0, 0.5)
	now[0] = 1500
	assert_false(Session.request_hook(WALL_CELL), "half a second later")
	now[0] = 2000
	assert_true(Session.request_hook(WALL_CELL), "a second later")


func test_the_hook_never_holds_a_player_or_a_monster_only_blocks() -> void:
	_setup()
	await _spawn(Vector3(8.5, 10.0, 0.5))
	var m := Monster.new()
	m.setup({"kind": MonsterRules.GOBLIN, "level": 1, "id": "hook_goblin", "pos": Vector3(14.5, 10.0, 0.5), "yaw": 0.0})
	m.block_at = world.get_block
	add_child_autofree(m)
	m.set_physics_process(false)
	assert_false(Session.request_hook(Vector3i(14, 11, 0)), "where the goblin stands there is no block")
	assert_has(_said, GadgetRules.hook_message("block"))
	assert_eq(player.gadget_move, GadgetRules.Move.NONE)


func test_a_guests_hook_is_checked_with_the_hosts_own_positions() -> void:
	_setup()
	await _spawn(Vector3(8.5, 10.0, 0.5))
	var guest: Player = load("res://entities/player/player.tscn").instantiate()
	guest.name = "5"
	guest.world = world
	add_child_autofree(guest)
	guest.set_physics_process(false)
	guest._spawned = true
	guest.global_position = Vector3(-10.5, 10.0, 0.5)
	watch_signals(Session)
	assert_false(Session.host_hook(5, WALL_CELL), "30 blocks from where the host sees the guest")
	assert_signal_not_emitted(Session, "gadget_hooked")
	guest.global_position = Vector3(6.5, 10.0, 2.5)
	assert_true(Session.host_hook(5, WALL_CELL))
	assert_signal_emitted(Session, "gadget_hooked")
	assert_eq(player.gadget_move, GadgetRules.Move.NONE, "the host's own player is not pulled")
	world.cells[Vector3i(14, 12, 1)] = BlockIds.BRICK
	world.cells[Vector3i(14, 12, 2)] = BlockIds.BRICK
	Session.gadget_reset()
	assert_false(Session.host_hook(5, WALL_CELL), "never through a wall")
	_forgive_messages_to_the_fake_guest()


## The host's kind words to guest 5 go by RPC, and in a test there is no network peer 5: expected errors.
func _forgive_messages_to_the_fake_guest() -> void:
	for e in get_errors():
		e.handled = true


func test_survivor_needs_the_hook_in_the_bag() -> void:
	_setup()
	Game.mode = ModeRules.SURVIVOR
	var inv := Inventory.new()
	Session.set_inventory(player.peer_id, inv)
	await _spawn(Vector3(8.5, 10.0, 0.5))
	assert_false(Session.request_hook(WALL_CELL))
	inv.add(ItemIds.GRAPPLE, 1)
	assert_true(Session.request_hook(WALL_CELL))
	assert_eq(inv.count(ItemIds.GRAPPLE), 1, "a hook is kept")

# --- Ziplines ---------------------------------------------------------------------------------------------

const POST_A := Vector3i(0, 15, 0)    # on a pillar, 5 blocks up
const POST_B := Vector3i(0, 10, 20)   # on the ground, 20 blocks on


func _posts() -> void:
	for y in range(10, 15):
		world.cells[Vector3i(0, y, 0)] = BlockIds.STONE
	world.set_block(POST_A, BlockIds.ZIPLINE_POST)
	world.set_block(POST_B, BlockIds.ZIPLINE_POST)


func test_two_posts_link_and_a_tap_rides_down_the_line_and_slides_off() -> void:
	_setup()
	_posts()
	assert_eq(zips.links.partner_of(POST_A), POST_B)
	await _spawn(Vector3(1.5, 10.0, 0.5))
	assert_true(Session.request_zipline(POST_A))
	assert_eq(player.gadget_move, GadgetRules.Move.ZIP)
	var from := GadgetRules.attach_point(POST_A)
	var to := GadgetRules.attach_point(POST_B)
	await wait_physics_frames(20)
	var s := (player.global_position + Vector3(0, GadgetRules.ZIP_HANG, 0) - from).length()
	var on_line := GadgetRules.zip_feet(from, to, s)
	assert_almost_eq(player.global_position.y, on_line.y, 0.3, "hanging under the line")
	assert_gt(player.velocity.length(), GadgetRules.ZIP_START_SPEED, "downhill it speeds up")
	await wait_until(func() -> bool: return player.gadget_move == GadgetRules.Move.NONE, 6.0, "the end of the line")
	assert_gt(player.global_position.z, 17.0, "carried across")
	assert_gt(player.velocity.z, 1.0, "slides off with its speed")


func test_jump_lets_go_of_the_line() -> void:
	_setup()
	_posts()
	await _spawn(Vector3(1.5, 10.0, 0.5))
	Session.request_zipline(POST_A)
	await wait_physics_frames(10)
	Input.action_press(&"jump")
	await wait_physics_frames(2)
	Input.action_release(&"jump")
	assert_eq(player.gadget_move, GadgetRules.Move.NONE)
	assert_lt(player.global_position.z, 12.0, "let go half way")


func test_a_lone_post_and_a_far_one_say_so_kindly() -> void:
	_setup()
	world.set_block(POST_B, BlockIds.ZIPLINE_POST)
	await _spawn(Vector3(1.5, 10.0, 20.5))
	assert_true(Session.request_zipline(POST_B))
	assert_has(_said, ZiplineDirector.NEEDS_PARTNER)
	assert_eq(player.gadget_move, GadgetRules.Move.NONE)
	player.global_position = Vector3(1.5, 10.0, 0.5)
	assert_false(Session.request_zipline(POST_B), "20 blocks away")
	assert_has(_said, Session.GADGET_GRAB_MESSAGE)


func test_a_broken_post_takes_its_line_away_and_every_game_draws_the_lines() -> void:
	_setup()
	_posts()
	assert_eq(zips.cables().size(), 1)
	assert_eq(zips.poles().size(), 2)
	world.set_block(POST_B, BlockIds.AIR)
	assert_null(zips.links.partner_of(POST_A))
	assert_eq(zips.cables().size(), 0)
	assert_eq(zips.poles().size(), 1, "the waiting post keeps its pole")


func test_the_lines_are_saved_with_the_world() -> void:
	_setup()
	_posts()
	var saved := zips.to_save()
	var again := ZiplineDirector.new()
	add_child_autofree(again)
	again.start(JSON.parse_string(JSON.stringify(saved)))
	assert_eq(again.ride_for(POST_A).get("to"), GadgetRules.attach_point(POST_B))
	var m := WorldMeta.new_random()
	m.ziplines = saved
	assert_eq(ZiplineLinks.from_save(WorldMeta.from_json(m.to_json()).ziplines).partner_of(POST_B), POST_A)
