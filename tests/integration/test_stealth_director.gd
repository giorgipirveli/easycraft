extends GutTest
## M2 Task 5: the StealthDirector — the light around players and bot friends, bushes, the noise log
## (landings, broken blocks, attacks), and hiding in barrels and closets through the host (reach,
## taken, knock-outs, a broken barrel), with monsters that saw it searching next to the spot.
## Solo: this game is the host. World access is stubbed.

const FLOOR := 10
const BARREL_CELL := Vector3i(2, FLOOR, 0)
const DT := 1.0 / 60.0

var _blocks := {}                 # cell -> id over a flat grass floor
var _surface := FLOOR
var _time := DayCycle.NOON
var _lamp := false
var _feedback: Array[String] = []


func before_each() -> void:
	_blocks = {BARREL_CELL: BlockIds.BARREL}
	_surface = FLOOR
	_time = DayCycle.NOON
	_lamp = false
	_feedback.clear()
	StealthDirector.clear_noises()
	Session.magic_feedback.connect(_on_feedback)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_feedback)
	StealthDirector.clear_noises()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_feedback(text: String) -> void:
	_feedback.append(text)


func _block(p: Vector3i) -> int:
	if _blocks.has(p):
		return _blocks[p]
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _director() -> StealthDirector:
	var d := StealthDirector.new()
	d.block_at = _block
	d.time_of_day = func() -> float: return _time
	d.surface_height = func(_x: int, _z: int) -> int: return _surface
	d.lights_near = func(_head: Vector3) -> bool: return _lamp
	add_child_autofree(d)
	d.set_physics_process(false)   # the tests step it themselves (a busy PC runs extra physics frames)
	d.start_host()
	return d


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


# --- Light and bushes ---

func test_the_light_around_a_player_by_day_at_night_in_a_cave_and_by_a_lantern() -> void:
	var d := _director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	d.refresh(p)
	assert_eq(p.stealth_light, 1.0, "noon")
	_time = DayCycle.MIDNIGHT
	d.refresh(p)
	assert_eq(p.stealth_light, 0.45, "midnight")
	_lamp = true
	d.refresh(p)
	assert_eq(p.stealth_light, 1.0, "by a lantern")
	_lamp = false
	_surface = FLOOR + 30                     # deep under the generated ground ...
	_blocks[Vector3i(0, FLOOR + 5, 0)] = BlockIds.STONE   # ... with a ceiling
	d.refresh(p)
	assert_almost_eq(p.stealth_light, 0.3, 0.001, "a dark cave")


func test_standing_in_a_bush_is_noticed() -> void:
	var d := _director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	d.refresh(p)
	assert_false(p.stealth_in_bush)
	_blocks[Vector3i(0, FLOOR, 0)] = BlockIds.BUSH
	d.refresh(p)
	assert_true(p.stealth_in_bush)
	p.set_crouching(true)
	assert_true(p.is_hidden(), "crouching in it: hidden")


func test_bot_friends_get_their_light_too() -> void:
	var d := _director()
	var bot := Node3D.new()
	add_child_autofree(bot)
	bot.global_position = Vector3(3.5, FLOOR, 3.5)
	_time = DayCycle.MIDNIGHT
	d.refresh(bot)
	assert_eq(float(bot.get_meta(&"stealth_light")), 0.45)
	assert_eq(Monster.visibility_of(bot), 0.45)


func test_the_host_measures_every_player_and_bot_five_times_a_second() -> void:
	var d := _director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var bot := CharacterBody3D.new()
	bot.add_to_group(&"bots")
	add_child_autofree(bot)
	bot.global_position = Vector3(3.5, FLOOR, 3.5)
	_time = DayCycle.MIDNIGHT
	await get_tree().physics_frame
	d._physics_process(DT)
	assert_eq(p.stealth_light, 0.45)
	assert_eq(float(bot.get_meta(&"stealth_light", 1.0)), 0.45)
	_time = DayCycle.NOON
	d._physics_process(DT)
	assert_eq(p.stealth_light, 0.45, "not every frame")
	for i in int(StealthDirector.REFRESH / DT) + 1:
		d._physics_process(DT)
	assert_eq(p.stealth_light, 1.0, "within 0.2 s")


# --- Noises ---

func test_noises_are_heard_within_their_radius_for_half_a_second() -> void:
	var t := 100.0
	StealthDirector.add_noise(Vector3(0, FLOOR, 0), StealthRules.NOISE_BREAK, false, t)
	assert_eq(StealthDirector.heard_at(Vector3(6, FLOOR, 0), t + 0.1), Vector3(0, FLOOR, 0))
	assert_false(StealthDirector.heard_at(Vector3(8, FLOOR, 0), t + 0.1).is_finite(), "too far")
	assert_false(StealthDirector.heard_at(Vector3(6, FLOOR, 0), t + StealthRules.NOISE_TIME + 0.1).is_finite(), "over")


func test_attacks_are_logged_where_the_attacker_stands() -> void:
	var d := _director()
	var p := _player(Vector3(0.5, FLOOR, 20.5))
	await get_tree().physics_frame
	Session.attack_requested.emit(p.peer_id, ItemIds.BOW, Vector3.FORWARD, 1.0)
	var now := d.now()
	assert_eq(StealthDirector.heard_at(Vector3(0.5, FLOOR, 16.0), now), p.global_position, "6 blocks around the archer")
	assert_eq(StealthDirector.last_attack_near(Vector3(0.5, FLOOR, 0.5), now), p.global_position,
		"a monster the arrow hits hears where it came from")


func test_a_landing_thuds() -> void:
	var d := _director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	d.local_player = p
	await get_tree().physics_frame
	p.velocity = Vector3(0, -9.5, 0)
	d._physics_process(DT)
	assert_false(StealthDirector.heard_at(Vector3(6.5, FLOOR, 0.5), d.now()).is_finite())
	p.velocity = Vector3.ZERO
	d._physics_process(DT)
	assert_true(StealthDirector.heard_at(Vector3(6.5, FLOOR, 0.5), d.now()).is_finite(), "8 blocks")
	assert_eq(d.local_noise(), StealthRules.NOISE_LANDING, "the HUD's noise bars show it")


func test_breaking_a_block_is_heard() -> void:
	var d := _director()
	d._on_block_changed(Vector3i(5, FLOOR - 1, 0), BlockIds.GRASS, BlockIds.AIR)
	assert_true(StealthDirector.heard_at(Vector3(10.5, FLOOR, 0.5), d.now()).is_finite(), "7 blocks")
	StealthDirector.clear_noises()
	d._on_block_changed(Vector3i(5, FLOOR, 0), BlockIds.AIR, BlockIds.STONE)
	assert_false(StealthDirector.heard_at(Vector3(5.5, FLOOR, 0.5), d.now()).is_finite(), "placing is quiet")


func test_the_huds_noise_follows_walking_and_crouching() -> void:
	var d := _director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	d.local_player = p
	assert_eq(d.local_noise(), 0.0)
	p.velocity = Vector3(6, 0, 0)
	assert_eq(d.local_noise(), StealthRules.NOISE_WALK)
	p.set_crouching(true)
	assert_eq(d.local_noise(), StealthRules.NOISE_CROUCH)


# --- Hiding in barrels and closets ---

func test_tapping_a_barrel_nearby_hides_the_player_inside() -> void:
	_director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	watch_signals(Session)
	Session.stealth_request_hide(BARREL_CELL)
	assert_true(p.is_hiding(), "the host said yes")
	assert_eq(p.hidden_in, BARREL_CELL)
	assert_signal_emitted_with_parameters(Session, "stealth_hidden_changed", [p.peer_id, true, BARREL_CELL])
	Session.stealth_request_unhide()
	assert_false(p.is_hiding(), "tap again: out")


func test_hiding_needs_a_hiding_spot_close_by_with_nobody_inside() -> void:
	_director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var other := _player(Vector3(3.5, FLOOR, 1.5), 9)
	await get_tree().physics_frame
	_blocks[Vector3i(9, FLOOR, 0)] = BlockIds.CLOSET
	Session.stealth_request_hide(Vector3i(9, FLOOR, 0))
	assert_false(p.is_hiding())
	assert_eq(_feedback, [StealthRules.TOO_FAR_MESSAGE] as Array[String])
	Session.stealth_request_hide(Vector3i(1, FLOOR, 0))
	assert_false(p.is_hiding(), "grass is no hiding spot")
	other.hidden_in = BARREL_CELL
	Session.stealth_request_hide(BARREL_CELL)
	assert_false(p.is_hiding())
	assert_eq(_feedback.back(), StealthRules.TAKEN_MESSAGE)


func test_no_hiding_while_knocked_out() -> void:
	_director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	p.knocked_out = true
	Session.stealth_request_hide(BARREL_CELL)
	assert_false(p.is_hiding())


func test_breaking_the_barrel_or_a_knock_out_brings_the_player_out() -> void:
	var d := _director()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	Session.stealth_request_hide(BARREL_CELL)
	assert_true(p.is_hiding())
	d._on_block_changed(BARREL_CELL, BlockIds.BARREL, BlockIds.AIR)
	assert_false(p.is_hiding(), "no barrel, no hiding")
	Session.stealth_request_hide(BARREL_CELL)
	assert_true(p.is_hiding())
	Session.player_hurt.emit(p.peer_id, 0, Vector3.ZERO)
	assert_false(p.is_hiding(), "knocked out: out first")


func test_a_monster_that_saw_you_go_in_searches_next_to_the_barrel() -> void:
	_director()
	var p := _player(Vector3(0.5, FLOOR, -5.5))
	_blocks[Vector3i(1, FLOOR, -6)] = BlockIds.BARREL
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)
	var g := Monster.new()
	g.setup({"kind": MonsterRules.GOBLIN, "level": 1, "id": "d1", "pos": Vector3(0.5, FLOOR, 0.5), "yaw": 0.0, "wild": true, "universe": 1})
	g.block_at = _block
	add_child_autofree(g)
	await get_tree().physics_frame
	for i in 30:
		g._physics_process(DT)
	assert_eq(g.awareness.state, StealthRules.Alert.ALERT, "it sees the player")
	var far := Monster.new()
	far.setup({"kind": MonsterRules.SLIME, "level": 1, "id": "d2", "pos": Vector3(0.5, FLOOR, 20.5), "yaw": 0.0, "wild": true, "universe": 1})
	far.block_at = _block
	add_child_autofree(far)
	Session.stealth_request_hide(Vector3i(1, FLOOR, -6))
	assert_true(p.is_hiding())
	assert_false(g.awareness.sees)
	assert_almost_eq(g.awareness.spot, Vector3(0.5, FLOOR, -5.5), Vector3.ONE * 0.01, "next to the barrel, where the player went in")
	assert_eq(far.awareness.state, StealthRules.Alert.NONE, "a monster that saw nothing is not sent there")
