extends GutTest
## M2 Task 4: a monster (spec §12.4): cheap shared looks per kind and level, a health bar once hurt,
## hits with knockback and defeat, the goblin (a chaser with a 0.8 s club wind-up) and the slime (a
## jumper that hurts on touch), and resting far from every player. Solo: this game is the host.

const FLOOR := 10
const DT := 1.0 / 60.0

var _mode_before: StringName
var _n := 0


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR


func after_each() -> void:
	Game.mode = _mode_before


## Growls and swings still playing when the test run quits show up as leaks at exit: stop them.
func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _monster(kind: StringName, level: int, pos: Vector3, yaw: float = 0.0) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "t%d" % _n, "pos": pos, "yaw": yaw, "wild": true, "universe": 1})
	m.block_at = _flat
	add_child_autofree(m)
	return m


## Solid ground under the test area (the terrain's collision).
func _ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


## A player standing still at `feet` (this game's own player: peer 1).
func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _steps(m: Monster, n: int) -> void:
	for i in n:
		if is_instance_valid(m):
			m._physics_process(DT)


## Steps until `done` (monsters look for players every Monster.PERCEIVE_EVERY, so the first look
## comes within about 0.3 s), at most `limit` steps.
func _steps_until(m: Monster, done: Callable, limit: int = 60) -> void:
	for i in limit:
		if done.call():
			return
		_steps(m, 1)


func _bodies(m: Monster) -> Array[Node]:
	return m.find_children("*", "MeshInstance3D", true, false).filter(
		func(n: Node) -> bool: return not n.get_parent().name == "HealthBar" and n.name != "AlertMark" \
			and n.get_parent().name != "Shimmer")   # the ? / ! (Task 5); a candy sneaker's shimmer (M3 Task 4)


# --- Looks ---

func test_every_kind_and_level_is_one_or_two_shared_meshes_and_a_small_body() -> void:
	for kind in MonsterRules.KINDS:
		for level in range(1, 6):
			var m := _monster(kind, level, Vector3(0, 40, 0))
			assert_true(m.is_in_group(&"monsters"))
			assert_eq(m.collision_layer, Monster.LAYER)
			assert_eq(m.collision_mask, 1, "only the world stops it")
			assert_between(_bodies(m).size(), 1, 2, "%s %d: body (and a goblin's club arm)" % [kind, level])
			var shapes := m.find_children("*", "CollisionShape3D", false, false)
			assert_eq(shapes.size(), 1)
			var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
			assert_lte(maxf(box.size.x, box.size.z), 1.0, "%s %d: a small footprint" % [kind, level])
			assert_eq(m.hp, MonsterRules.hp(kind, level))


func test_the_same_kind_and_level_share_meshes_and_levels_differ() -> void:
	var a := _monster(MonsterRules.GOBLIN, 2, Vector3(0, 40, 0))
	var b := _monster(MonsterRules.GOBLIN, 2, Vector3(3, 40, 0))
	var c := _monster(MonsterRules.GOBLIN, 3, Vector3(6, 40, 0))
	assert_same((_bodies(a)[0] as MeshInstance3D).mesh, (_bodies(b)[0] as MeshInstance3D).mesh)
	assert_ne((_bodies(a)[0] as MeshInstance3D).mesh, (_bodies(c)[0] as MeshInstance3D).mesh)
	assert_same(MonsterModels.mesh_for(MonsterRules.SLIME, 4), MonsterModels.mesh_for(MonsterRules.SLIME, 4))


func test_a_level_l_monster_has_l_spikes_and_grows_with_its_level() -> void:
	for kind in MonsterRules.KINDS:
		var last := 0.0
		for level in range(1, 6):
			assert_eq(MonsterModels.spike_count(kind, level), level, "%s %d" % [kind, level])
			var size := MonsterModels.mesh_for(kind, level).get_aabb().size
			assert_gt(size.y, last, "%s %d is taller" % [kind, level])
			last = size.y
		assert_has(MonsterModels.colors_of(kind, 3), MonsterRules.level_color(3), "%s wears its level colour" % kind)


func test_monster_meshes_share_the_animals_material() -> void:
	var mat := MonsterModels.mesh_for(MonsterRules.SLIME, 1).surface_get_material(0)
	assert_same(mat, BlockyAnimal.mesh_for(&"pig").surface_get_material(0), "no new shader to compile")
	assert_same(MonsterModels.coin_mesh().surface_get_material(0), mat)


func test_the_health_bar_shows_once_hurt() -> void:
	var m := _monster(MonsterRules.GOBLIN, 1, Vector3(0, 40, 0))
	var bar := m.find_child("HealthBar", true, false) as Node3D
	assert_not_null(bar)
	m._process(DT)
	assert_false(bar.visible, "no bar at full health")
	m.take_hit(3, Vector3(0, 40, 3), Vector3.ZERO)
	m._process(DT)
	assert_true(bar.visible)
	var fill := bar.find_child("Fill", true, false) as Node3D
	assert_almost_eq(fill.scale.x, 0.5, 0.01, "half its health left")


# --- Hits ---

func test_a_hit_hurts_and_pushes_it_back() -> void:
	var m := _monster(MonsterRules.GOBLIN, 3, Vector3(0, 40, 0))
	m.take_hit(4, Vector3(0, 40, 2), Vector3(0, 3, -6))
	assert_eq(m.hp, MonsterRules.hp(MonsterRules.GOBLIN, 3) - 4)
	assert_almost_eq(m.velocity, Vector3(0, 3, -6), Vector3.ONE * 0.01)
	m.take_hit(-5, Vector3.ZERO, Vector3.INF)
	assert_eq(m.hp, MonsterRules.hp(MonsterRules.GOBLIN, 3) - 4, "a negative hit never heals")
	assert_true(m.velocity.is_finite())


func test_a_defeated_monster_is_announced_once_and_gone() -> void:
	var m := _monster(MonsterRules.SLIME, 1, Vector3(0, 40, 0))
	watch_signals(m)
	m.take_hit(3, Vector3.ZERO, Vector3.ZERO)
	assert_signal_not_emitted(m, "defeated")
	m.take_hit(3, Vector3.ZERO, Vector3.ZERO)
	assert_signal_emit_count(m, "defeated", 1)
	assert_eq(m.hp, 0)
	assert_true(m.is_queued_for_deletion())
	m.take_hit(3, Vector3.ZERO, Vector3.ZERO)
	assert_signal_emit_count(m, "defeated", 1, "only once")


# --- The goblin: a chaser ---

func test_a_goblin_chases_a_player_it_sees() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(0.5, FLOOR, -10.5))
	await get_tree().physics_frame   # players join between frames
	_steps(g, 60)
	assert_eq(g.state, Monster.State.CHASE)
	assert_lt(g.global_position.z, -1.0, "runs at the player (models face -Z)")


func test_a_goblin_sees_a_player_in_front_but_not_one_behind_it() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, 0.5))
	var behind := _player(Vector3(0.5, FLOOR, 10.5))
	await get_tree().physics_frame                 # players join between frames
	assert_null(g.perceive(), "behind it (models face -Z)")
	behind.global_position = Vector3(0.5, FLOOR, -10.5)
	await get_tree().physics_frame
	assert_eq(g.perceive(), behind, "in front of it")


## Integration with M2 Task 2: a knocked-out player lies still, so monsters leave them alone.
func test_a_monster_never_notices_a_knocked_out_player() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -6.5))
	p.knocked_out = true
	await get_tree().physics_frame
	assert_null(g.perceive(), "lying down: not a target")


func test_a_chasing_monster_gives_up_on_a_player_who_is_knocked_out() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -6.5))
	await get_tree().physics_frame
	_steps_until(g, func() -> bool: return g.state == Monster.State.CHASE)
	assert_eq(g.target(), p)
	p.knocked_out = true
	_steps(g, 12)
	assert_null(g.target(), "stops chasing")
	assert_eq(g.state, Monster.State.WANDER)


func test_a_goblin_winds_up_its_club_before_it_hits() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -0.8))
	await get_tree().physics_frame
	_steps_until(g, func() -> bool: return g.state == Monster.State.WINDUP)
	assert_eq(g.state, Monster.State.WINDUP)
	assert_true(g.winding, "everyone sees the club go up")
	_steps(g, 30)
	assert_eq(p.health.hp, Health.MAX_HP, "not yet: 0.5 s into the wind-up")
	_steps(g, 20)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.GOBLIN, 1), "the club lands after 0.8 s")
	assert_false(g.winding)


func test_stepping_away_during_the_wind_up_dodges_the_club() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -0.8))
	await get_tree().physics_frame
	_steps_until(g, func() -> bool: return g.state == Monster.State.WINDUP)
	assert_eq(g.state, Monster.State.WINDUP)
	p.global_position = Vector3(0.5, FLOOR, -5.5)
	_steps(g, 50)
	assert_eq(p.health.hp, Health.MAX_HP, "missed")


func test_a_hit_during_the_wind_up_stops_the_swing() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, 2, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -0.8))
	await get_tree().physics_frame
	_steps_until(g, func() -> bool: return g.state == Monster.State.WINDUP)
	assert_true(g.winding)
	g.take_hit(1, p.global_position, Vector3.ZERO)
	assert_false(g.winding)
	_steps(g, 30)
	assert_eq(p.health.hp, Health.MAX_HP, "the swing was stopped")


# --- The slime: a jumper ---

func test_a_slime_hops_towards_a_player() -> void:
	_ground()
	var s := _monster(MonsterRules.SLIME, 1, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(0.5, FLOOR, -8.5))
	await get_tree().physics_frame
	var highest := 0.0
	for i in 120:
		_steps(s, 1)
		highest = maxf(highest, s.global_position.y)
	assert_gt(highest, FLOOR + 0.4, "it hops")
	assert_lt(s.global_position.z, -1.0, "towards the player")


func test_a_slime_hurts_on_touch_then_waits() -> void:
	_ground()
	var s := _monster(MonsterRules.SLIME, 2, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -0.4))
	await get_tree().physics_frame
	_steps_until(s, func() -> bool: return p.health.hp < Health.MAX_HP)
	var hit := MonsterRules.hit(MonsterRules.SLIME, 2)
	assert_eq(p.health.hp, Health.MAX_HP - hit)
	p.global_position = s.global_position + Vector3(0, 0, -0.4)
	_steps(s, 30)
	assert_eq(p.health.hp, Health.MAX_HP - hit, "waits a moment before the next touch")


# --- Cost ---

func test_a_monster_far_from_every_player_rests() -> void:
	var m := _monster(MonsterRules.GOBLIN, 1, Vector3(500, 40, 500))   # no ground: a simulated one falls
	_player(Vector3(0, FLOOR, 0))
	await get_tree().physics_frame
	_steps(m, 30)
	assert_eq(m.global_position, Vector3(500, 40, 500), "nobody near: it rests and costs nothing")


func test_hp_and_the_wind_up_are_synced_on_change() -> void:
	var m := _monster(MonsterRules.GOBLIN, 1, Vector3(0, 40, 0))
	var cfg := (m.get_node("Sync") as MultiplayerSynchronizer).replication_config
	for prop: String in [".:hp", ".:winding"]:
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE, prop)
		assert_true(cfg.property_get_spawn(NodePath(prop)), "%s arrives with the spawn" % prop)
	for prop: String in [".:position", ".:rotation"]:
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ALWAYS, prop)


# --- Hit feel (lead ruling from the child-psychology notes) ---

func test_a_hit_freezes_the_monster_for_a_moment_then_it_flies_back() -> void:
	_ground()
	var g := _monster(MonsterRules.GOBLIN, 3, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(0.5, FLOOR, 8.5))
	await get_tree().physics_frame
	_steps(g, 7)                                   # it has decided at least once: simulated
	var before := g.global_position
	g.take_hit(1, Vector3(0.5, FLOOR, 3.5), Vector3(0, 2, -6))
	_steps(g, 2)
	assert_eq(g.global_position, before, "hit-stop: still for about %d ms" % int(Monster.HIT_STOP * 1000))
	_steps(g, 12)
	assert_lt(g.global_position.z, before.z - 0.3, "then the push carries it away")


func test_a_hit_squashes_the_monster_on_every_screen() -> void:
	var m := _monster(MonsterRules.SLIME, 2, Vector3(0, 40, 0))
	var body := m.get_child(0) as Node3D
	m._process(DT)
	assert_eq(body.scale, Vector3.ONE)
	m.hp -= 2                                      # what a peer sees when the synced hp drops
	m._process(DT)
	assert_lt(body.scale.y, 0.9, "squashed flat")
	assert_gt(body.scale.x, 1.1, "and wide")
	for i in 20:
		m._process(DT)
	assert_almost_eq(body.scale, Vector3.ONE, Vector3.ONE * 0.05, "then back to its shape")


func test_every_monster_and_coin_sound_is_registered() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for s: StringName in [&"squish", &"growl", &"pop", &"poof", &"coin", &"swing"]:
		assert_true(sounds.has(s), String(s))
	for kind in MonsterRules.KINDS:
		assert_true(sounds.has(MonsterRules.KIND[kind].sound), "%s's voice" % kind)


## Monsters on the way to a player keep a little apart; a goblin next to its target stands still (and
## costs no physics move) instead of pushing into the player.
func test_chasing_goblins_stop_a_step_short_and_keep_apart() -> void:
	_ground()
	var a := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR, 4.5))   # facing -Z: the player
	var b := _monster(MonsterRules.GOBLIN, 1, Vector3(0.7, FLOOR, 4.5))
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	await get_tree().physics_frame
	for i in 150:
		_steps(a, 1)
		_steps(b, 1)
	for g in [a, b]:
		var d := Vector2(g.global_position.x - p.global_position.x, g.global_position.z - p.global_position.z).length()
		assert_between(d, 0.6, MonsterRules.ATTACK_RANGE, "next to the player, not on top of them")
	assert_gt(Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length(), 0.35,
		"not on top of each other")


func test_a_goblin_on_a_ledge_above_the_player_comes_down() -> void:
	var ledge := func(c: Vector3i) -> int: return BlockIds.GRASS if c.y < FLOOR or (c.y < FLOOR + 2 and c.z > 1) else BlockIds.AIR
	var body := StaticBody3D.new()
	for box_def in [[Vector3(80, 1, 80), Vector3(0, FLOOR - 0.5, 0)], [Vector3(80, 2, 20), Vector3(0, FLOOR + 1, 12)]]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = box_def[0]
		shape.shape = box
		shape.position = box_def[1]
		body.add_child(shape)
	add_child_autofree(body)
	var g := _monster(MonsterRules.GOBLIN, 1, Vector3(0.5, FLOOR + 2, 2.5), 0.0)
	g.block_at = ledge
	var p := _player(Vector3(0.5, FLOOR, 1.5))
	await get_tree().physics_frame
	for i in 180:
		_steps(g, 1)
	assert_lt(g.global_position.y, FLOOR + 1.0, "it stepped down to the player")
	assert_lt(p.health.hp, Health.MAX_HP, "and reached them")
