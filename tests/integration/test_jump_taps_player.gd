extends GutTest
## Owner feedback #54 (2026-09-28) and #75 (2026-09-29: "when i click on jump several times i should start fliying and
## going up not only down"), spec §3b, on a real Player with real physics (Jolt), tapped like a child's thumb on JUMP
## (the touch button and Space press the same action): in the Sandbox the second quick tap takes off flying and every
## tap after it lifts the player higher; in Survivor two taps stay the double jump and the third takes off (flying
## costs gold there); Monster Wave has no flying (the jumps, then the glider); one tap jumps; a slow second tap is a
## double jump; under the glider the taps are the glider's. The fake world: a stone floor with its top at y = 10.
class FlatWorld:
	extends WorldService

	func get_block(p: Vector3i) -> int:
		return BlockIds.STONE if p.y <= 9 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true


const QUICK := 9    # physics frames (60 a second) from one tap to the next: 0.15 s, a child's quick double tap
const UNHURRIED := 18   # 0.30 s: a slower double tap still counts (the limit is 0.35 s)
const STEADY := 15  # 0.25 s: tapping on and on
const SLOW := 27    # 0.45 s: a slow second tap
const FLOOR := 10.0

var world: FlatWorld
var player: Player
var _jumps: Array = []
var _flew := false
var _glided := false
var _mode_before: StringName
var _gold_before := 0
var _inventions_before: InventionData


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	_inventions_before = Profile.data.inventions
	Profile.data.inventions = InventionData.invented_to(InventionLine.PLANE)   # owner #78: Survivor flies a machine
	Game.mode = ModeRules.SANDBOX


func after_each() -> void:
	Input.action_release(&"jump")
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.inventions = _inventions_before
	Session.register_world(null)


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _setup(max_jumps: int = JumpCounter.MAX_JUMPS) -> void:
	world = FlatWorld.new()
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 10, 400)
	shape.shape = box
	shape.position = Vector3(0, 5, 0)
	ground.add_child(shape)
	world.add_child(ground)
	Session.register_world(world)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	player.set_max_jumps(max_jumps)
	player.spawn_at(Vector3(0.5, FLOOR, 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(10)
	_jumps = []
	_flew = false
	_glided = false
	player.jumped.connect(func(i: int) -> void: _jumps.append(i))
	player.physics_mode_changed.connect(func(m: int) -> void: _flew = _flew or m == PhysicsMode.Mode.FLY)
	player.gadget_move_changed.connect(func(m: int) -> void: _glided = _glided or m == GadgetRules.Move.GLIDE)


## Frees this test's player and world at once (a test that plays several patterns sets up again).
func _teardown() -> void:
	Session.register_world(null)
	for n: Node in [player, world]:
		remove_child(n)
		n.free()


## Exactly `n` physics frames (GUT's wait_physics_frames(1) can take two: tap timing needs every frame).
func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## `n` taps on JUMP (pressed for one physics frame each), `gap` physics frames from one tap to the next.
func _tap(n: int, gap: int) -> void:
	for i in n:
		Input.action_press(&"jump")
		await _frames(1)
		Input.action_release(&"jump")
		if i < n - 1:
			await _frames(gap - 1)


## Waits `frames` physics frames; returns the highest the feet got above the floor.
func _peak(frames: int) -> float:
	var peak := player.global_position.y - FLOOR
	for i in frames:
		await _frames(1)
		peak = maxf(peak, player.global_position.y - FLOOR)
	return peak


# --- Quick taps: fly, and every tap lifts higher ------------------------------------------------------------

## Taps `n` quick taps; returns the height the feet reached above the floor once the lift is over (at most
## JumpTaps.MAX_LIFT: 150 frames).
func _taps_fly(n: int, max_jumps: int, gap: int = QUICK) -> float:
	await _setup(max_jumps)
	await _tap(n, gap)
	await _frames(150)
	var what := "%d taps %.2f s apart, %d jumps" % [n, gap / 60.0, max_jumps]
	assert_eq(player.physics_mode, PhysicsMode.Mode.FLY, "%s: flying, as with the FLY button" % what)
	assert_eq(_jumps, [1], "%s: the first tap jumped, the second took off" % what)
	assert_false(_glided, "%s: never the parachute" % what)
	assert_almost_eq(player.velocity.y, 0.0, 0.3, "%s: hovering up there, not falling" % what)
	return player.global_position.y - FLOOR


func test_two_quick_taps_lift_the_player_up_and_start_flying() -> void:
	assert_gt(await _taps_fly(2, JumpCounter.MAX_JUMPS), 3.0, "a clear rise, then hovering")


func test_two_quick_taps_fly_with_the_double_jump_setting_too() -> void:
	assert_gt(await _taps_fly(2, JumpCounter.MIN_JUMPS), 3.0)


func test_a_slower_double_tap_three_tenths_of_a_second_apart_still_flies() -> void:
	assert_gt(await _taps_fly(2, JumpCounter.MAX_JUMPS, UNHURRIED), 3.0)


func test_several_quick_taps_fly_and_keep_going_up() -> void:
	var two := await _taps_fly(2, JumpCounter.MAX_JUMPS)
	_teardown()
	for n in [3, 4, 5, 6]:
		for gap in [QUICK, STEADY]:
			var height := await _taps_fly(n, JumpCounter.MAX_JUMPS, gap)
			assert_gt(height, two + 0.8 * (n - 2), "%d taps %.2f s apart: higher with every tap" % [n, gap / 60.0])
			_teardown()


func test_holding_jump_while_flying_goes_up_and_the_switch_walks_again() -> void:
	await _setup()
	await _tap(2, QUICK)
	await wait_physics_frames(60)
	assert_eq(player.physics_mode, PhysicsMode.Mode.FLY)
	var y := player.global_position.y
	Input.action_press(&"jump")
	await wait_physics_frames(30)
	Input.action_release(&"jump")
	assert_gt(player.global_position.y - y, 2.0, "UP (the JUMP button while flying) climbs")
	assert_eq(player.physics_mode, PhysicsMode.Mode.FLY, "holding UP is no tap: still flying")
	player.cycle_physics_mode()   # the FLY button: GHOST
	player.cycle_physics_mode()   # and WALK
	assert_eq(player.physics_mode, PhysicsMode.Mode.NORMAL)
	await wait_until(func() -> bool: return player.is_on_floor(), 5.0, "back down on the ground, walking")
	assert_true(player.is_on_floor())


# --- Everything else stays as it was --------------------------------------------------------------------------

func test_one_tap_is_one_jump() -> void:
	await _setup()
	await _tap(1, QUICK)
	await wait_physics_frames(90)
	assert_eq(_jumps, [1])
	assert_false(_flew)
	assert_true(player.is_on_floor(), "landed")


func test_a_slow_second_tap_is_a_double_jump() -> void:
	await _setup()
	await _tap(2, SLOW)
	await wait_physics_frames(90)
	assert_eq(_jumps, [1, 2])
	assert_false(_flew, "a slow second tap is no double tap")
	assert_true(player.is_on_floor(), "landed, walking")


func test_survivor_keeps_the_double_jump_and_flies_on_the_third_tap() -> void:
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 1000
	await _setup(JumpCounter.MIN_JUMPS)
	await _tap(2, QUICK)
	await _frames(90)
	assert_eq(_jumps, [1, 2], "two taps: the double jump")
	assert_false(_flew, "two taps never spend gold")
	_teardown()
	await _setup(JumpCounter.MIN_JUMPS)
	await _tap(3, QUICK)
	await _frames(30)
	assert_true(_flew, "tap tap tap: flying (it costs gold, like the FLY button)")
	assert_false(_glided, "not the parachute")


func test_survivor_without_gold_cannot_take_off() -> void:
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 0
	await _setup(JumpCounter.MIN_JUMPS)
	await _tap(3, QUICK)
	await _frames(90)
	assert_false(_flew, "no gold, no flying (the game says so)")


func test_monster_wave_has_no_flying_the_jumps_then_the_glider() -> void:
	Game.mode = ModeRules.WAVE
	await _setup(JumpCounter.MIN_JUMPS)
	await _tap(4, QUICK)
	await _frames(20)
	assert_eq(_jumps.slice(0, 2), [1, 2], "the jumps first")
	assert_false(_flew, "Monster Wave never flies")


func test_the_glider_keeps_its_taps_in_the_air() -> void:
	await _setup()
	player.global_position = Vector3(0.5, FLOOR + 20.0, 0.5)
	player.velocity = Vector3(0, -12, 0)
	await wait_physics_frames(1)
	assert_true(player.open_glider())
	await _tap(2, QUICK)
	await wait_physics_frames(40)
	assert_eq(player.gadget_move, GadgetRules.Move.GLIDE, "still gliding")
	assert_false(_flew, "a double tap under the canopy does not fly")


func test_a_tap_before_a_nap_is_forgotten() -> void:
	await _setup()
	await _tap(1, QUICK)
	player.sleeping = true   # the body stops moving (asleep, riding, hidden or knocked out)
	await _frames(3)
	player.sleeping = false
	await _tap(1, QUICK)
	await _frames(60)
	assert_false(_flew, "the tap from before the nap does not pair with the one after it")
