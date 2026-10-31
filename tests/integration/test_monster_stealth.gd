extends GutTest
## M2 Task 5 (spec §12.5): how monsters perceive players and bot friends — sight scaled by visibility,
## hearing by noise radii, the ? and ! marks (synced), searching the last known spot for 6 s, hidden
## and knocked-out players and knocked-out bots left alone, bots hurt through hurt(). Solo: this game
## is the host.

const FLOOR := 10
const DT := 1.0 / 60.0

var _mode_before: StringName
var _n := 0


## A stand-in bot friend (the M2 Task 15 contract: group "bots", chest(), hurt(amount, from)).
class FakeBot:
	extends CharacterBody3D
	var hurts: Array[int] = []

	func _ready() -> void:
		add_to_group(&"bots")

	func chest() -> Vector3:
		return global_position + Vector3(0, 1.0, 0)

	func hurt(amount: int, _from: Vector3) -> void:
		hurts.append(amount)


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	StealthDirector.clear_noises()


func after_each() -> void:
	Game.mode = _mode_before
	StealthDirector.clear_noises()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _monster(kind: StringName, pos: Vector3, level: int = 1) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "s%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": 1})
	m.block_at = _flat
	add_child_autofree(m)
	return m


func _ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _bot(feet: Vector3) -> FakeBot:
	var b := FakeBot.new()
	add_child_autofree(b)
	b.global_position = feet
	return b


func _steps(m: Monster, n: int) -> void:
	for i in n:
		if is_instance_valid(m):
			m._physics_process(DT)


func _steps_until(m: Monster, done: Callable, limit: int = 60) -> void:
	for i in limit:
		if done.call():
			return
		_steps(m, 1)


# --- Sight ---

func test_a_crouching_player_in_the_dark_is_not_seen_from_far_away() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))   # faces -Z
	var p := _player(Vector3(0.5, FLOOR, -7.5))
	p.stealth_light = StealthRules.NIGHT
	p.set_crouching(true)
	await get_tree().physics_frame
	assert_null(g.perceive(), "8 blocks away, crouching at night (review focus 5)")
	p.global_position = Vector3(0.5, FLOOR, -2.5)
	await get_tree().physics_frame
	assert_eq(g.perceive(), p, "3 blocks away: seen")
	p.global_position = Vector3(0.5, FLOOR, -7.5)
	p.set_crouching(false)
	p.stealth_light = StealthRules.DAYLIGHT
	await get_tree().physics_frame
	assert_eq(g.perceive(), p, "standing in daylight: seen")


func test_hidden_players_are_never_seen_even_right_in_front() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -1.5))
	p.stealth_in_bush = true
	p.set_crouching(true)
	await get_tree().physics_frame
	assert_null(g.perceive(), "crouching in a bush")
	p.set_crouching(false)
	p.stealth_in_bush = false
	p.set_hidden(true, Vector3i(0, FLOOR, -2))
	await get_tree().physics_frame
	assert_null(g.perceive(), "inside a barrel")


func test_an_invisible_player_is_never_seen() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -3.5))
	p.drink(ItemIds.POTION_INVIS)
	await get_tree().physics_frame
	assert_null(g.perceive())


# --- Hearing ---

func test_a_walking_player_behind_it_is_heard_then_seen() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, 4.5))                        # behind it
	p.velocity = Vector3(Player.WALK_SPEED, 0, 0)                     # walking: heard 6 blocks away
	await get_tree().physics_frame
	assert_null(g.perceive(), "behind it: not seen")
	_steps_until(g, func() -> bool: return g.state == Monster.State.SUSPICIOUS)
	assert_eq(g.state, Monster.State.SUSPICIOUS, "heard: ?")
	assert_eq(g.alert, StealthRules.MARK_QUESTION)
	assert_almost_eq(g.awareness.spot, p.global_position, Vector3.ONE * 0.01, "it goes to the noise")
	_steps_until(g, func() -> bool: return g.state == Monster.State.CHASE, 120)
	assert_eq(g.state, Monster.State.CHASE, "turned round, saw the player: !")
	assert_eq(g.alert, StealthRules.MARK_BANG)
	assert_eq(g.alert_peer, p.peer_id, "whose danger arrow")


func test_a_player_crouching_past_behind_it_is_not_heard() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, 3.5))
	p.set_crouching(true)
	p.velocity = Vector3(3, 0, 0)
	await get_tree().physics_frame
	_steps(g, 40)
	assert_eq(g.awareness.state, StealthRules.Alert.NONE, "crouching is heard 1.5 blocks away only")
	assert_eq(g.alert, StealthRules.MARK_NONE)


func test_a_broken_block_or_a_landing_is_heard_and_old_noises_are_not() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(30.5, FLOOR, 0.5))                                # keeps it awake, far away
	await get_tree().physics_frame
	StealthDirector.add_noise(Vector3(0.5, FLOOR, 8.5), StealthRules.NOISE_BREAK, false, Time.get_ticks_msec() / 1000.0 - 1.0)
	_steps(g, 20)
	assert_eq(g.awareness.state, StealthRules.Alert.NONE, "a second ago: gone")
	StealthDirector.add_noise(Vector3(0.5, FLOOR, 5.5), StealthRules.NOISE_BREAK)
	_steps_until(g, func() -> bool: return g.state == Monster.State.SUSPICIOUS)
	assert_eq(g.state, Monster.State.SUSPICIOUS)
	assert_almost_eq(g.awareness.spot, Vector3(0.5, FLOOR, 5.5), Vector3.ONE * 0.01)


func test_a_far_archer_is_heard_by_the_monster_it_hits() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(0.5, FLOOR, 15.5))
	await get_tree().physics_frame
	StealthDirector.add_noise(Vector3(0.5, FLOOR, 15.5), StealthRules.NOISE_ATTACK, true)
	g.take_hit(1, Vector3(0.5, FLOOR + 0.5, 1.0), Vector3.ZERO)      # the arrow, next to it
	assert_eq(g.awareness.state, StealthRules.Alert.SUSPICIOUS, "?: it comes to see who shot")
	assert_almost_eq(g.awareness.spot, Vector3(0.5, FLOOR, 15.5), Vector3.ONE * 0.01, "where the archer stands")


# --- Losing you, searching, hiding ---

func test_losing_you_it_searches_the_last_known_spot_6_seconds_then_wanders() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -5.5))
	await get_tree().physics_frame
	_steps_until(g, func() -> bool: return g.state == Monster.State.CHASE)
	assert_eq(g.alert, StealthRules.MARK_BANG)
	p.stealth_in_bush = true                                          # ducks into a bush
	p.set_crouching(true)
	_steps_until(g, func() -> bool: return g.state == Monster.State.SEARCH, 400)
	assert_eq(g.state, Monster.State.SEARCH, "got to the last known spot: searching")
	assert_eq(g.alert, StealthRules.MARK_QUESTION)
	_steps(g, int(5.4 / DT))
	assert_eq(g.state, Monster.State.SEARCH, "5.4 s later: still searching")
	_steps(g, int(1.0 / DT))
	assert_eq(g.state, Monster.State.WANDER, "after 6 s: wanders again")
	assert_eq(g.alert, StealthRules.MARK_NONE)
	assert_null(g.target())
	assert_eq(p.health.hp, Health.MAX_HP, "a hidden player is never hurt")


func test_a_monster_that_saw_you_hide_searches_next_to_the_spot() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -8.5))
	await get_tree().physics_frame
	_steps_until(g, func() -> bool: return g.state == Monster.State.CHASE)
	var spot := Vector3(0.5, FLOOR, -8.5)
	p.set_hidden(true, Vector3i(0, FLOOR, -10))
	g.saw_hide(p, spot)
	_steps_until(g, func() -> bool: return g.state == Monster.State.SEARCH, 400)
	assert_eq(g.state, Monster.State.SEARCH)
	assert_lt(Vector2(g.global_position.x - spot.x, g.global_position.z - spot.z).length(), StealthRules.ARRIVE + 0.5,
		"right next to the hiding spot")
	_steps(g, int(6.5 / DT))
	assert_eq(g.state, Monster.State.WANDER, "never finds you: gives up")
	assert_eq(p.health.hp, Health.MAX_HP)


func test_a_monster_that_never_saw_you_is_not_sent_to_the_spot() -> void:
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(20.5, FLOOR, 20.5))
	g.saw_hide(p, Vector3(20.5, FLOOR, 20.5))
	assert_eq(g.awareness.state, StealthRules.Alert.NONE)


func test_hiding_during_the_wind_up_dodges_the_club() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -0.8))
	await get_tree().physics_frame
	_steps_until(g, func() -> bool: return g.state == Monster.State.WINDUP)
	assert_true(g.winding)
	p.set_hidden(true, Vector3i(0, FLOOR, -1))
	_steps(g, 60)
	assert_eq(p.health.hp, Health.MAX_HP, "hiding really hides")


# --- Bot friends ---

func test_goblins_see_and_club_bot_friends() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, 12.5))                       # behind it, standing still
	var b := _bot(Vector3(0.5, FLOOR, -0.8))
	await get_tree().physics_frame
	assert_eq(g.perceive(), b, "bots are perceived like players")
	_steps_until(g, func() -> bool: return not b.hurts.is_empty(), 120)
	assert_eq(b.hurts, [MonsterRules.hit(MonsterRules.GOBLIN, 1)] as Array[int], "hurt(n, from), not Session.hurt_player")
	assert_eq(p.health.hp, Health.MAX_HP)
	assert_eq(g.alert_peer, 0, "no player's danger arrow for a bot")


func test_a_knocked_out_bot_is_left_alone() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(0.5, FLOOR, 12.5))
	var b := _bot(Vector3(0.5, FLOOR, -2.5))
	await get_tree().physics_frame
	assert_eq(g.perceive(), b)
	b.remove_from_group(&"bots")                                     # what a knocked-out bot does
	await get_tree().physics_frame
	assert_null(g.perceive())


func test_a_slime_hops_at_a_bot_and_hurts_it_on_touch() -> void:
	_ground()
	var s := _monster(MonsterRules.SLIME, Vector3(0.5, FLOOR, 0.5), 2)
	_player(Vector3(0.5, FLOOR, 12.5))
	var b := _bot(Vector3(0.5, FLOOR, -0.4))
	await get_tree().physics_frame
	_steps_until(s, func() -> bool: return not b.hurts.is_empty(), 120)
	assert_eq(b.hurts.size(), 1)


# --- The ? and ! marks ---

func test_the_marks_float_over_its_head_on_every_screen() -> void:
	var g := _monster(MonsterRules.GOBLIN, Vector3(0, 40, 0))
	var mark := g.find_child("AlertMark", true, false) as MeshInstance3D
	assert_not_null(mark)
	g._process(DT)
	assert_false(mark.visible, "calm: nothing")
	g.alert = StealthRules.MARK_QUESTION                             # what a guest receives
	g._process(DT)
	assert_true(mark.visible)
	assert_same(mark.mesh, AlertMarks.mesh(StealthRules.MARK_QUESTION))
	g.alert = StealthRules.MARK_BANG
	g._process(DT)
	assert_same(mark.mesh, AlertMarks.mesh(StealthRules.MARK_BANG))
	assert_gt(mark.global_position.y, g.global_position.y + g.size().y, "over its head")
	g.alert = StealthRules.MARK_NONE
	g._process(DT)
	assert_false(mark.visible)


func test_marks_are_shared_meshes_with_the_animals_material() -> void:
	assert_same(AlertMarks.mesh(StealthRules.MARK_BANG), AlertMarks.mesh(StealthRules.MARK_BANG))
	assert_ne(AlertMarks.mesh(StealthRules.MARK_BANG), AlertMarks.mesh(StealthRules.MARK_QUESTION))
	var mat := BlockyAnimal.mesh_for(&"pig").surface_get_material(0)
	for m in [StealthRules.MARK_QUESTION, StealthRules.MARK_BANG]:
		assert_same(AlertMarks.mesh(m).surface_get_material(0), mat, "no new shader to compile")


func test_the_alert_is_synced_on_change() -> void:
	var m := _monster(MonsterRules.SLIME, Vector3(0, 40, 0))
	var cfg := (m.get_node("Sync") as MultiplayerSynchronizer).replication_config
	for prop: String in [".:alert", ".:alert_peer"]:
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE, prop)
		assert_true(cfg.property_get_spawn(NodePath(prop)), prop)
