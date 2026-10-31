extends GutTest
## M3 Task 4 (spec §14.1): the Cake Monster as an entity. It fits the BossDirector like the Golem (it is a
## StoneGolem to it: health bar, honest help, win and loss), draws with shared meshes, and each layer has its
## own signalled attack: the frosting wave (three tiers; a jump clears it), three cherries (two tiers; a step
## aside dodges them), the spin (one tier; out of its way). Its tiers fall off at two thirds and a third of its
## health (a pause with a line that says what comes next; no hit skips a layer); after every attack it is
## dizzy (double damage). It plays the boss music and never changes a block. Solo: this game is the host.

const FLOOR := 10
const DT := 1.0 / 60.0
const P := CakeRules.Phase
const HP := 420

var _mode_before: StringName
var _hurts: Array = []
var _said: Array = []
var _n := 0


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_hurts.clear()
	_said.clear()
	Session.player_hurt.connect(_on_hurt)
	Session.magic_feedback.connect(_on_said)


func after_each() -> void:
	Session.player_hurt.disconnect(_on_hurt)
	Session.magic_feedback.disconnect(_on_said)
	Game.mode = _mode_before
	Session.survivor_reset()
	Music.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_hurt(peer: int, hp: int, from: Vector3) -> void:
	_hurts.append([peer, hp, from])


func _on_said(text: String) -> void:
	_said.append(text)


func _flat(p: Vector3i) -> int:
	return BlockIds.FROSTING if p.y < FLOOR else BlockIds.AIR


func _cake(pos: Vector3 = Vector3(0.5, FLOOR, 0.5), max_hp: int = HP) -> CakeMonster:
	_n += 1
	var c := CakeMonster.new()
	c.setup({"id": "c%d" % _n, "pos": pos, "yaw": 0.0, "max_hp": max_hp, "tired": false})
	c.block_at = _flat
	add_child_autofree(c)
	c.set_physics_process(false)
	return c


func _ground() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = Vector3(0, FLOOR - 0.5, 0)


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _steps(c: CakeMonster, n: int) -> void:
	for i in n:
		if is_instance_valid(c):
			c._physics_process(DT)


func _steps_until(c: CakeMonster, done: Callable, limit: int = 900) -> int:
	for i in limit:
		if done.call():
			return i
		_steps(c, 1)
	return limit


func test_it_is_a_boss_the_director_knows_with_shared_meshes() -> void:
	var a := _cake()
	var b := _cake(Vector3(10.5, FLOOR, 0.5))
	assert_true(a is StoneGolem, "the BossDirector's fights, bar and help work unchanged")
	assert_true(a.is_in_group(&"monsters"), "weapons and bot friends find it")
	assert_eq(a.boss_kind(), BossRules.CAKE)
	var shapes := a.find_children("*", "CollisionShape3D", false, false)
	assert_eq(shapes.size(), 1)
	var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
	assert_lte(maxf(box.size.x, box.size.z), Buddy.MAX_FOOTPRINT, "a small footprint")
	var meshes_a := a.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	var meshes_b := b.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	assert_eq(meshes_a, meshes_b, "every cake shares the same meshes")
	assert_same(CakeModels.tier_mesh(0).surface_get_material(0), BlockyAnimal.mesh_for(&"pig").surface_get_material(0),
		"the animals' material: no new shader")
	assert_eq(a.layers(), 3)


func test_it_can_be_hit_except_while_it_rises_or_drops_a_layer_and_dizzy_doubles() -> void:
	var c := _cake()
	assert_eq(c.phase, P.RISE)
	c.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(c.hp, HP, "rising: not yet")
	c.start_phase(P.WALK)
	c.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(c.hp, HP - 50)
	c.start_phase(P.DIZZY)
	assert_true(c.is_dazed(), "the boss bar's x2 chip")
	c.take_hit(10, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(c.hp, HP - 70, "dizzy: double")


## At two thirds the top tier falls: a pause (no hits), a line saying what comes next, a lower cake; at a third
## the middle tier; a big hit never takes two tiers at once.
func test_its_layers_fall_off_one_at_a_time() -> void:
	var c := _cake()
	c.start_phase(P.WALK)
	var tall := c.height()
	c.take_hit(HP, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(c.hp, floori(HP * 2 / 3.0), "the top tier's line: no layer skipped")
	assert_eq(c.layers(), 2)
	assert_eq(c.phase, P.LAYER_DROP, "a pause while the layer falls")
	assert_true(_said.has(CakeRules.LAYER_LINES[2]), "it says what comes next: %s" % [_said])
	assert_lt(c.height(), tall, "a lower cake")
	c.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(c.hp, floori(HP * 2 / 3.0), "no hits while the layer falls")
	_steps(c, int(CakeRules.DROP_TIME / DT) + 2)
	assert_eq(c.phase, P.WALK)
	c.take_hit(HP, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(c.layers(), 1)
	assert_true(_said.has(CakeRules.LAYER_LINES[1]))
	_steps(c, int(CakeRules.DROP_TIME / DT) + 2)
	var defeats: Array = []
	c.defeated.connect(func(x: StoneGolem) -> void: defeats.append(x))
	c.take_hit(HP, Vector3(0, FLOOR, 3), Vector3.ZERO)
	c.take_hit(HP, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(defeats.size(), 1, "then it is beaten, once")
	assert_true(c.is_down())


## Every screen: the fallen tier goes (hidden once it has tumbled off), from the synced health alone.
func test_every_screen_shows_the_tiers_left() -> void:
	var c := _cake()
	c._process(DT)
	assert_eq(c.tiers_shown(), 3)
	c.hp = floori(HP * 2 / 3.0)
	for i in 90:
		c._process(DT)
	assert_eq(c.tiers_shown(), 2, "the top tier fell off")
	c.hp = 10
	for i in 90:
		c._process(DT)
	assert_eq(c.tiers_shown(), 1)


func test_the_schedule_changes_with_the_layers() -> void:
	_ground()
	var c := _cake()
	_player(Vector3(0.5, FLOOR, 14.5))
	await get_tree().physics_frame
	var seen: Array = [c.phase]
	for i in int(12.0 / DT):
		_steps(c, 1)
		if c.phase != seen[-1]:
			seen.append(c.phase)
	assert_eq(seen.slice(0, 5), [P.RISE, P.WALK, P.WAVE_WARN, P.DIZZY, P.WALK], "three tiers: the frosting wave")
	c.take_hit(HP, Vector3.ZERO, Vector3.ZERO)
	_steps_until(c, func() -> bool: return c.phase == P.WALK)
	_steps_until(c, func() -> bool: return c.phase != P.WALK)
	assert_eq(c.phase, P.CHERRY_WARN, "two tiers: cherries")
	_steps_until(c, func() -> bool: return c.phase == P.WALK)
	c.take_hit(HP, Vector3.ZERO, Vector3.ZERO)
	_steps_until(c, func() -> bool: return c.phase == P.WALK)
	_steps_until(c, func() -> bool: return c.phase != P.WALK)
	assert_eq(c.phase, P.SPIN_WARN, "one tier: the spin")


func test_the_frosting_wave_hits_the_ground_nearby_and_a_jump_clears_it() -> void:
	_ground()
	var c := _cake()
	var p := _player(Vector3(0.5, FLOOR, 4.5))
	await get_tree().physics_frame
	c.start_phase(P.WAVE_WARN)
	var frames := _steps_until(c, func() -> bool: return not _hurts.is_empty(), 200)
	assert_almost_eq(frames * DT, CakeRules.WAVE_WINDUP, 3 * DT, "it lands as the wind-up ends")
	assert_eq(p.health.hp, Health.MAX_HP - CakeRules.damage(CakeRules.WAVE))
	assert_eq(c.phase, P.DIZZY)
	_hurts.clear()
	p.global_position = Vector3(0.5, FLOOR + 1.6, 4.5)   # in the air
	c.start_phase(P.WAVE_WARN)
	_steps(c, int(CakeRules.WAVE_WINDUP / DT) + 5)
	assert_eq(_hurts.size(), 0, "jumped over the wave")


func test_three_cherries_fly_and_a_child_who_keeps_moving_is_safe() -> void:
	_ground()
	var c := _cake()
	c.hp = floori(HP * 0.5)                          # two tiers
	var p := _player(Vector3(0.5, FLOOR, 8.5))
	await get_tree().physics_frame
	c.start_phase(P.CHERRY_WARN)
	_steps_until(c, func() -> bool: return c.rocks_in_flight() > 0, 200)
	assert_eq(c.rocks_in_flight(), 3, "three cherries")
	_steps_until(c, func() -> bool: return c.rocks_in_flight() == 0, 200)
	assert_eq(p.health.hp, Health.MAX_HP - CakeRules.damage(CakeRules.CHERRIES), "one landed on them")
	c.start_phase(P.CHERRY_WARN)
	_steps_until(c, func() -> bool: return c.rocks_in_flight() > 0, 200)
	p.global_position += Vector3(1.25, 0, 3.0)       # between the cherries and past them
	_steps_until(c, func() -> bool: return c.rocks_in_flight() == 0, 200)
	assert_eq(p.health.hp, Health.MAX_HP - CakeRules.damage(CakeRules.CHERRIES), "the second volley missed")


func test_the_spin_runs_at_the_child() -> void:
	_ground()
	var c := _cake()
	c.hp = 20                                        # one tier
	var p := _player(Vector3(0.5, FLOOR, -6.5))
	await get_tree().physics_frame
	c.start_phase(P.SPIN_WARN)
	_steps_until(c, func() -> bool: return c.phase == P.DIZZY, 400)
	assert_eq(p.health.hp, Health.MAX_HP - CakeRules.damage(CakeRules.SPIN), "the spin ran over them")
	assert_lt(c.global_position.z, -5.0, "it went the way it faced them")


func test_the_boss_music_plays_while_it_is_here() -> void:
	Music.reset()
	var c := _cake()
	Music.tick(0.1)
	assert_eq(Music.current(), MusicRules.BOSS)
	c.free()
	Music.tick(0.1)
	assert_ne(Music.current(), MusicRules.BOSS)


class WatchedWorld:
	extends WorldService
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return BlockIds.FROSTING if pos.y < 10 or (pos.z == -4 and pos.y < 13) else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func test_it_never_changes_blocks() -> void:
	_ground()
	var w := WatchedWorld.new()
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	var c := _cake()
	c.block_at = w.get_block
	var p := _player(Vector3(0.5, FLOOR, -6.5))
	await get_tree().physics_frame
	for hp in [HP, 250, 60]:
		c.hp = hp
		_steps(c, int(12.0 / DT))
	c.take_hit(1000, p.global_position, Vector3.ZERO)
	Session.register_world(before)
	assert_eq(w.edits, 0, "the Cake Monster never edits a block")
	for path in ["res://entities/monsters/cake_monster.gd", "res://entities/monsters/cake_models.gd",
			"res://core/rules/cake_rules.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["set_block", "request_set_block", "set_voxel(", "do_box", "do_sphere"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])
