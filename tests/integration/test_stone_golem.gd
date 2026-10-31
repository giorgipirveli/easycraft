extends GutTest
## M2 Task 10: the Stone Golem (spec §12.9) as an entity: cheap shared looks, weapons and bot friends
## hit it like any monster, it rises, walks and attacks in its schedule with clear wind-ups (slam 1.2 s,
## rock 1 s, charge 1 s), the slam hurts only grounded targets within 7, it is dazed for 2 s after a
## slam and takes double damage then, the rock and the charge hurt whoever is where they land or run,
## the boss music plays while it is here, and it never changes a block. Solo: this game is the host.

const FLOOR := 10
const DT := 1.0 / 60.0
const P := BossRules.Phase

var _mode_before: StringName
var _hurts: Array = []
var _n := 0


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_hurts.clear()
	Session.player_hurt.connect(_on_hurt)
	_ground()


func after_each() -> void:
	Session.player_hurt.disconnect(_on_hurt)
	Game.mode = _mode_before
	Session.survivor_reset()
	Music.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_hurt(peer: int, hp: int, from: Vector3) -> void:
	_hurts.append([peer, hp, from])


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _golem(pos: Vector3 = Vector3(0.5, FLOOR, 0.5), max_hp: int = 300, tired: bool = false) -> StoneGolem:
	_n += 1
	var g := StoneGolem.new()
	g.setup({"id": "g%d" % _n, "pos": pos, "yaw": 0.0, "max_hp": max_hp, "tired": tired})
	g.block_at = _flat
	add_child_autofree(g)
	return g


func _ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


## This game's own player (peer 1) standing still at `feet`.
func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


## A bot friend standing at `feet` (group "bots": the Golem hits friends too).
func _bot(feet: Vector3) -> BotFriend:
	var b := BotFriend.new()
	b.setup({"id": "Bot1", "name": "Pip", "personality": "fighter", "look": 0, "pos": feet})
	add_child_autofree(b)
	b.set_physics_process(false)
	b.global_position = feet
	return b


func _steps(g: StoneGolem, n: int) -> void:
	for i in n:
		if is_instance_valid(g):
			g._physics_process(DT)


func _steps_until(g: StoneGolem, done: Callable, limit: int = 600) -> int:
	for i in limit:
		if done.call():
			return i
		_steps(g, 1)
	return limit


# --- Looks and hits ---

func test_a_big_blocky_golem_from_shared_meshes_with_a_small_footprint() -> void:
	var a := _golem()
	var b := _golem(Vector3(8, FLOOR, 0))
	assert_true(a.is_in_group(&"monsters"), "weapons and bot friends find it like a monster")
	assert_eq(a.collision_layer, Monster.LAYER, "weapon taps find it")
	assert_eq(a.collision_mask, 1, "only the world stops it")
	var shapes := a.find_children("*", "CollisionShape3D", false, false)
	assert_eq(shapes.size(), 1)
	var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
	assert_lte(maxf(box.size.x, box.size.z), Buddy.MAX_FOOTPRINT, "a small footprint (Jolt, DEVELOPMENT.md §8)")
	assert_gt(GolemModels.body_mesh().get_aabb().size.y, 2.5, "big: taller than a player")
	var meshes_a := a.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	var meshes_b := b.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	assert_eq(meshes_a, meshes_b, "every golem shares the same meshes")
	assert_same(GolemModels.body_mesh().surface_get_material(0), BlockyAnimal.mesh_for(&"pig").surface_get_material(0),
		"the body draws with the animals' material: no new shader")
	assert_same(GolemModels.rock_mesh().surface_get_material(0), GolemModels.glow_material(), "the glowing rock shares one material")
	assert_same(GolemModels.eyes_mesh().surface_get_material(0), GolemModels.glow_material())


func test_weapons_aim_at_its_big_body() -> void:
	var g := _golem()
	assert_almost_eq(g.hit_center().y, FLOOR + 1.5, 0.3, "the middle of its body")
	assert_gte(g.hit_radius(), 1.2, "generous: children aim loosely")
	var found := false
	for thing in CombatDirector.hittables(get_tree()):
		if thing.node == g:
			found = true
			assert_eq(thing.kind, WeaponRules.MONSTER)
			assert_eq(thing.pos, g.hit_center())
	assert_true(found, "in CombatDirector.hittables")


func test_a_sword_swing_hits_it() -> void:
	var g := _golem()
	g.start_phase(P.WALK)
	var combat := CombatDirector.new()
	combat.block_at = _flat
	add_child_autofree(combat)
	var hits := combat.resolve_melee(Vector3(0.5, FLOOR + 1.0, 3.2), Vector3(0, 0, -1), ItemIds.SWORD)
	assert_eq(hits.size(), 1)
	assert_lt(g.hp, 300, "the sword hurt it")


func test_it_cannot_be_hurt_while_it_rises_and_is_defeated_at_zero_once() -> void:
	var g := _golem()
	assert_eq(g.phase, P.RISE)
	g.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(g.hp, 300, "rising out of the ground: no hits yet")
	g.start_phase(P.WALK)
	var defeats: Array = []
	g.defeated.connect(func(x: StoneGolem) -> void: defeats.append(x))
	g.take_hit(299, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(g.hp, 1)
	g.take_hit(5, Vector3(0, FLOOR, 3), Vector3.ZERO)
	g.take_hit(5, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(g.hp, 0)
	assert_eq(defeats.size(), 1, "defeated once")
	assert_eq(g.phase, P.DOWN)


# --- The schedule ---

func test_it_rises_then_walks_then_winds_up_its_attacks_in_order() -> void:
	var g := _golem()
	_player(Vector3(0.5, FLOOR, 20.5))              # far: nobody is hit, the schedule just runs
	await get_tree().physics_frame
	var seen: Array = [g.phase]
	var times := {}
	var t := 0.0
	var since := 0.0
	for i in int(20.0 / DT):
		_steps(g, 1)
		t += DT
		since += DT
		if g.phase != seen[-1]:
			times[seen[-1]] = times.get(seen[-1], []) + [snappedf(since, DT)]
			seen.append(g.phase)
			since = 0.0
	assert_eq(seen.slice(0, 8), [P.RISE, P.WALK, P.SLAM_WINDUP, P.DAZED, P.WALK, P.ROCK_WINDUP, P.WALK, P.CHARGE_WINDUP])
	assert_almost_eq(float(times[P.RISE][0]), BossRules.RISE_TIME, 2 * DT)
	assert_almost_eq(float(times[P.SLAM_WINDUP][0]), 1.2, 2 * DT, "fists up for 1.2 s")
	assert_almost_eq(float(times[P.DAZED][0]), 2.0, 2 * DT, "dazed for 2 s")
	assert_almost_eq(float(times[P.ROCK_WINDUP][0]), 1.0, 2 * DT, "rock up for 1 s")
	assert_almost_eq(float(times[P.CHARGE_WINDUP][0]), 1.0, 2 * DT, "paws for 1 s")


# --- The slam ---

func test_the_slam_hurts_a_grounded_player_within_7() -> void:
	var g := _golem()
	var p := _player(Vector3(0.5, FLOOR, 5.5))
	await get_tree().physics_frame
	g.start_phase(P.SLAM_WINDUP)
	var frames := _steps_until(g, func() -> bool: return not _hurts.is_empty(), 120)
	assert_almost_eq(frames * DT, 1.2, 2 * DT, "it lands as the 1.2 s wind-up ends")
	assert_eq(_hurts.size(), 1)
	assert_eq(p.health.hp, Health.MAX_HP - 4, "4 HP")
	assert_eq(g.phase, P.DAZED)


func test_nobody_in_the_air_or_further_than_7_is_hurt_by_the_slam() -> void:
	var g := _golem()
	var p := _player(Vector3(0.5, FLOOR, 8.5))
	await get_tree().physics_frame
	g.start_phase(P.SLAM_WINDUP)
	_steps(g, 80)
	assert_eq(p.health.hp, Health.MAX_HP, "8 blocks away")
	p.global_position = Vector3(0.5, FLOOR, 3.5)
	p.physics_mode = PhysicsMode.Mode.FLY
	g.start_phase(P.SLAM_WINDUP)
	_steps(g, 80)
	assert_eq(p.health.hp, Health.MAX_HP, "flying over the grass")
	p.physics_mode = PhysicsMode.Mode.NORMAL
	p.global_position = Vector3(0.5, FLOOR + 1.2, 3.5)   # the top of a jump
	p.velocity = Vector3.ZERO
	g.start_phase(P.SLAM_WINDUP)
	_steps(g, 80)
	assert_eq(p.health.hp, Health.MAX_HP, "jumping over the shockwave")


func test_the_slam_hurts_bot_friends_on_the_ground_too() -> void:
	var g := _golem()
	_player(Vector3(0.5, FLOOR, 30.5))
	var b := _bot(Vector3(3.5, FLOOR, 0.5))
	await get_tree().physics_frame
	g.start_phase(P.SLAM_WINDUP)
	_steps(g, 80)
	assert_eq(b.health.hp, Health.MAX_HP - 4)


func test_dazed_it_takes_double_damage_for_2_seconds() -> void:
	var g := _golem()
	_player(Vector3(0.5, FLOOR, 30.5))
	await get_tree().physics_frame
	g.start_phase(P.SLAM_WINDUP)
	_steps_until(g, func() -> bool: return g.phase == P.DAZED, 120)
	assert_true(g.is_dazed())
	g.take_hit(5, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(g.hp, 290, "double damage while dazed")
	_steps(g, int(1.9 / DT))
	assert_true(g.is_dazed(), "still dazed near the end of the 2 s")
	_steps(g, int(0.2 / DT))
	assert_false(g.is_dazed())
	g.take_hit(5, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(g.hp, 285, "normal damage again")


# --- The rock ---

func test_the_rock_hits_a_player_who_stays_and_misses_one_who_steps_away() -> void:
	var g := _golem()
	var p := _player(Vector3(0.5, FLOOR, 9.5))
	await get_tree().physics_frame
	g._decide()
	g.start_phase(P.ROCK_WINDUP)
	var frames := _steps_until(g, func() -> bool: return g.phase != P.ROCK_WINDUP, 120)
	assert_almost_eq(frames * DT, 1.0, 2 * DT, "held up for 1 s")
	assert_eq(g.rocks_in_flight(), 1, "a glowing rock flies")
	_steps_until(g, func() -> bool: return g.rocks_in_flight() == 0, 180)
	assert_eq(p.health.hp, Health.MAX_HP - 3, "3 HP where it lands")
	g.start_phase(P.ROCK_WINDUP)
	_steps_until(g, func() -> bool: return g.phase != P.ROCK_WINDUP, 120)
	p.global_position = Vector3(4.5, FLOOR, 9.5)          # steps aside while it flies
	_steps_until(g, func() -> bool: return g.rocks_in_flight() == 0, 180)
	assert_eq(p.health.hp, Health.MAX_HP - 3, "dodged")


# --- The charge ---

func test_the_charge_paws_then_runs_straight_about_12_blocks_and_hurts_once() -> void:
	var g := _golem(Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -6.5))           # right in front of it (it faces -Z)
	await get_tree().physics_frame
	await get_tree().physics_frame
	g._decide()
	g.start_phase(P.CHARGE_WINDUP)
	var start := g.global_position
	var frames := _steps_until(g, func() -> bool: return g.phase == P.CHARGE, 120)
	assert_almost_eq(frames * DT, 1.0, 2 * DT, "paws the ground for 1 s")
	assert_lt(g.global_position.distance_to(start), 0.2, "it stands while it paws")
	_steps_until(g, func() -> bool: return g.phase != P.CHARGE, 200)
	var run := Vector2(g.global_position.x - start.x, g.global_position.z - start.z)
	assert_between(run.length(), 10.0, 12.5, "about 12 blocks")
	assert_lt(absf(run.x), 0.5, "straight")
	assert_eq(p.health.hp, Health.MAX_HP - 5, "5 HP, once")


# --- Music and the rule ---

func test_the_boss_music_plays_while_it_is_here() -> void:
	Music.reset()
	var g := _golem()
	assert_eq(Music.current(), &"", "tick not run yet")
	Music.tick(0.1)
	assert_eq(Music.current(), MusicRules.BOSS)
	g.free()
	Music.tick(0.1)
	assert_ne(Music.current(), MusicRules.BOSS)


## A lost fight's Golem sinks for a moment; a new fight may already have begun. Its leaving must not
## stop the new fight's music.
func test_the_boss_music_stays_until_the_last_golem_is_gone() -> void:
	Music.reset()
	var old := _golem()
	var fresh := _golem(Vector3(8.5, FLOOR, 0.5))
	old.free()
	Music.tick(0.1)
	assert_eq(Music.current(), MusicRules.BOSS, "the new Golem still fights")
	fresh.free()
	Music.tick(0.1)
	assert_ne(Music.current(), MusicRules.BOSS)


func test_a_tired_golem_has_less_health() -> void:
	var g := _golem(Vector3(0.5, FLOOR, 0.5), 225, true)
	assert_true(g.tired)
	assert_eq(g.max_hp, 225)
	assert_eq(g.hp, 225)


## Stands in for the world and counts every change anybody makes to it.
class WatchedWorld:
	extends WorldService
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return BlockIds.GRASS if pos.y < 10 or (pos.z == -4 and pos.y < 13) else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func test_it_never_changes_blocks() -> void:
	var w := WatchedWorld.new()
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	var g := _golem()
	g.block_at = w.get_block
	var p := _player(Vector3(0.5, FLOOR, -6.5))       # behind a wall: it charges, throws and slams at it
	await get_tree().physics_frame
	_steps(g, int(30.0 / DT))
	g.take_hit(1000, p.global_position, Vector3.ZERO)
	Session.register_world(before)
	assert_eq(w.edits, 0, "the Golem never edits a block")
	for path in ["res://entities/monsters/stone_golem.gd", "res://entities/monsters/golem_models.gd",
			"res://entities/monsters/golem_rock.gd", "res://core/rules/boss_rules.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["set_block", "request_set_block", "set_voxel(", "do_box", "do_sphere"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])
