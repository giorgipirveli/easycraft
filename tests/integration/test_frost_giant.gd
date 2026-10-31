extends GutTest
## M3 Task 3 (spec §14.1): the Frost Giant as an entity and through the BossDirector. It is a StoneGolem to
## the director (health bar, honest help, gold, portal, win and loss), draws with shared meshes, climbs out
## of the snow, then stomps (a freezing ring along the ground: a jump clears it, the ground turns icy for a
## few seconds and no block changes), breathes an icy cone (a snow wall between shields a child), pants
## (double damage) and throws a giant snowball; it plays the boss music and never changes a block. Solo:
## this game is the host.

const FLOOR := 10
const DT := 1.0 / 60.0
const P := FrostGiantRules.Phase
const TOTEM := Vector3(20.5, FLOOR, 3.5)

var _mode_before: StringName
var _hurts: Array = []
var _n := 0
var _cells := {}


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_hurts.clear()
	_cells = {}
	Session.player_hurt.connect(_on_hurt)
	var ground := StaticBody3D.new()             # the snow it stands on (the terrain's collision)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


func after_each() -> void:
	Session.player_hurt.disconnect(_on_hurt)
	Game.mode = _mode_before
	Session.survivor_reset()
	Music.reset()
	IcyGround.clear()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_hurt(peer: int, hp: int, from: Vector3) -> void:
	_hurts.append([peer, hp, from])


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.SNOW if p.y < FLOOR else BlockIds.AIR


func _giant(pos: Vector3 = Vector3(0.5, FLOOR, 0.5), max_hp: int = FrostGiantRules.BASE_HP) -> FrostGiant:
	_n += 1
	var g := FrostGiant.new()
	g.setup({"id": "fg%d" % _n, "pos": pos, "yaw": 0.0, "max_hp": max_hp, "tired": false})
	g.block_at = _block
	add_child_autofree(g)
	g.set_physics_process(false)
	return g


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _steps(g: FrostGiant, n: int) -> void:
	for i in n:
		if is_instance_valid(g):
			g._physics_process(DT)


func _steps_until(g: FrostGiant, done: Callable, limit: int = 900) -> int:
	for i in limit:
		if done.call():
			return i
		_steps(g, 1)
	return limit


func test_it_is_a_boss_the_director_knows_with_shared_meshes() -> void:
	var a := _giant()
	var b := _giant(Vector3(10.5, FLOOR, 0.5))
	assert_true(a is StoneGolem, "the BossDirector's fights, bar and help work unchanged")
	assert_true(a.is_in_group(&"monsters"), "weapons and bot friends find it")
	var shapes := a.find_children("*", "CollisionShape3D", false, false)
	assert_eq(shapes.size(), 1)
	var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
	assert_lte(maxf(box.size.x, box.size.z), Buddy.MAX_FOOTPRINT, "a small footprint")
	var meshes_a := a.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	var meshes_b := b.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	assert_eq(meshes_a, meshes_b, "every giant shares the same meshes")
	assert_same(GiantModels.body_mesh().surface_get_material(0), BlockyAnimal.mesh_for(&"pig").surface_get_material(0),
		"the animals' material: no new shader")
	assert_eq(a.boss_kind(), BossRules.FROST_GIANT)


func test_it_takes_hits_once_it_stands_and_double_while_it_pants() -> void:
	var g := _giant()
	assert_eq(g.phase, P.RISE)
	g.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(g.hp, FrostGiantRules.BASE_HP, "climbing out: not yet")
	g.start_phase(P.WALK)
	g.take_hit(50, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(g.hp, FrostGiantRules.BASE_HP - 50)
	g.start_phase(P.PANTING)
	assert_true(g.is_dazed(), "the boss bar's x2 chip")
	g.take_hit(10, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(g.hp, FrostGiantRules.BASE_HP - 70, "panting: double")
	var defeats: Array = []
	g.defeated.connect(func(x: StoneGolem) -> void: defeats.append(x))
	g.take_hit(10000, Vector3(0, FLOOR, 3), Vector3.ZERO)
	g.take_hit(10000, Vector3(0, FLOOR, 3), Vector3.ZERO)
	assert_eq(defeats.size(), 1)
	assert_true(g.is_down())


func test_the_schedule_runs_in_order() -> void:
	var g := _giant()
	_player(Vector3(0.5, FLOOR, 14.5))
	await get_tree().physics_frame
	var seen: Array = [g.phase]
	for i in int(24.0 / DT):
		_steps(g, 1)
		if g.phase != seen[-1]:
			seen.append(g.phase)
	assert_eq(seen.slice(0, 9), [P.RISE, P.WALK, P.STOMP_WARN, P.WALK, P.BREATH_WARN, P.BREATH, P.PANTING, P.WALK, P.THROW_WARN])


func test_the_stomp_hurts_the_ground_round_it_and_makes_it_icy_without_changing_a_block() -> void:
	var g := _giant()
	var p := _player(Vector3(0.5, FLOOR, 4.5))
	await get_tree().physics_frame
	g.start_phase(P.STOMP_WARN)
	var frames := _steps_until(g, func() -> bool: return not _hurts.is_empty(), 200)
	assert_almost_eq(frames * DT, FrostGiantRules.STOMP_WINDUP, 3 * DT, "it lands as the leg comes down")
	assert_eq(p.health.hp, Health.MAX_HP - FrostGiantRules.damage(FrostGiantRules.STOMP))
	var now := Time.get_ticks_msec() / 1000.0
	assert_lt(IcyGround.grip_at(Vector3(3.5, FLOOR, 0.5), now), 1.0, "the ground round it is icy")
	assert_eq(_block(Vector3i(3, FLOOR - 1, 0)), BlockIds.SNOW, "... and still snow: no block changed")
	assert_eq(IcyGround.grip_at(Vector3(3.5, FLOOR, 0.5), now + FrostGiantRules.ICY_TIME + 0.1), 1.0, "for a few seconds")


func test_a_jump_clears_the_stomp() -> void:
	var g := _giant()
	var p := _player(Vector3(0.5, FLOOR + 1.6, 4.5))   # in the air, over the ring
	await get_tree().physics_frame
	g.start_phase(P.STOMP_WARN)
	_steps(g, int(FrostGiantRules.STOMP_WINDUP / DT) + 5)
	assert_eq(_hurts.size(), 0)
	assert_eq(p.health.hp, Health.MAX_HP)


## The breath: a child in front is chilled (a heart every half second); behind a snow wall they are safe.
func test_the_breath_chills_a_child_in_front_and_a_snow_wall_shields() -> void:
	var g := _giant()
	var p := _player(Vector3(0.5, FLOOR, -5.5))       # in front (it faces -Z)
	await get_tree().physics_frame
	g.start_phase(P.BREATH_WARN)
	_steps_until(g, func() -> bool: return g.phase == P.PANTING, 400)
	assert_eq(p.health.hp, Health.MAX_HP - FrostGiantRules.damage(FrostGiantRules.BREATH) * FrostGiantRules.BREATH_TICKS,
		"three chills")
	# a snow wall between them
	for x in range(-3, 4):
		for y in range(FLOOR, FLOOR + 5):
			_cells[Vector3i(x, y, -3)] = BlockIds.SNOW_BRICK
	var before := p.health.hp
	g.start_phase(P.BREATH_WARN)
	_steps_until(g, func() -> bool: return g.phase == P.PANTING, 400)
	assert_eq(p.health.hp, before, "hidden behind the wall")


func test_the_giant_snowball_hits_a_child_who_stays() -> void:
	var g := _giant()
	var p := _player(Vector3(0.5, FLOOR, -8.5))
	await get_tree().physics_frame
	g.start_phase(P.THROW_WARN)
	_steps_until(g, func() -> bool: return g.rocks_in_flight() > 0, 200)
	assert_eq(g.rocks_in_flight(), 1)
	_steps_until(g, func() -> bool: return g.rocks_in_flight() == 0, 200)
	assert_eq(p.health.hp, Health.MAX_HP - FrostGiantRules.damage(FrostGiantRules.SNOWBALL))


func test_the_boss_music_plays_while_it_is_here() -> void:
	Music.reset()
	var g := _giant()
	Music.tick(0.1)
	assert_eq(Music.current(), MusicRules.BOSS)
	g.free()
	Music.tick(0.1)
	assert_ne(Music.current(), MusicRules.BOSS)


class WatchedWorld:
	extends WorldService
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return BlockIds.SNOW if pos.y < 10 or (pos.z == -4 and pos.y < 13) else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func test_it_never_changes_blocks() -> void:
	var w := WatchedWorld.new()
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	var g := _giant()
	g.block_at = w.get_block
	var p := _player(Vector3(0.5, FLOOR, -6.5))
	await get_tree().physics_frame
	_steps(g, int(30.0 / DT))
	g.take_hit(100000, p.global_position, Vector3.ZERO)
	Session.register_world(before)
	assert_eq(w.edits, 0, "the Frost Giant never edits a block")
	for path in ["res://entities/monsters/frost_giant.gd", "res://entities/monsters/giant_models.gd",
			"res://core/rules/frost_giant_rules.gd", "res://world/icy_ground.gd", "res://core/rules/frost_rules.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["set_block", "request_set_block", "set_voxel(", "do_box", "do_sphere"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])


# --- Through the BossDirector ---

func _director(kind: StringName = BossRules.FROST_GIANT) -> BossDirector:
	var d := BossDirector.new()
	d.name = "Boss"
	d.block_at = _block
	d.boss_kind = kind
	d.pay_gold = func(_peer: int, _amount: int) -> void: pass
	var bar := BossBar.new()
	add_child_autofree(bar)
	d.bar = bar
	add_child_autofree(d)
	return d


func test_the_frost_totem_brings_the_frost_giant_and_a_win_opens_the_next_portal() -> void:
	var universe_before := Game.universe
	var unlocked_before := Profile.data.universe_unlocked
	Game.universe = 3
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	assert_eq(d.start(TOTEM), "")
	var g := d.golem()
	assert_true(g is FrostGiant, "the world's boss")
	assert_eq(g.max_hp, FrostGiantRules.max_hp(1))
	d.tick(0.016)
	assert_eq(d.bar.title(), FrostGiantRules.TITLE)
	assert_eq(d.start(TOTEM), "The Frost Giant is already here!", "one at a time, by its name")
	g.start_phase(P.WALK)
	g.take_hit(100000, TOTEM, Vector3.ZERO)
	await get_tree().process_frame
	d.tick(0.016)
	assert_eq(d.bar.title(), FrostGiantRules.WIN_MESSAGE)
	assert_eq(d.portals().size(), 1, "the portal opens by the Totem")
	assert_eq(d.portals()[0].target, 4, "it leads to universe 4")
	assert_gte(Profile.data.universe_unlocked, 4, "beating it unlocks universe 4")
	Game.universe = universe_before
	Profile.data.universe_unlocked = unlocked_before


func test_summon_giant_is_a_sandbox_command() -> void:
	assert_eq(ChatCommands.parse("/summon giant").get("boss"), &"giant")
	assert_true(ChatCommands.suggestions("/summon gi").has("/summon giant"))
	assert_eq(WaveRules.boss_word(BossRules.words(BossRules.FROST_GIANT).name), "The Frost Giant!")
