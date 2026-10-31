extends GutTest
## Universe 6, the Glow Caves (spec §5.1, §5.2's sneaker): its monsters in the world. The spore puff hides in the dark
## like the candy sneaker (its own shimmer of glowing spots; the child's lantern shows it close by), swells up and
## bumps; the cave crawler is blind: it never sees a child, it hears one who walks or runs near it and feels one who
## touches it, so a child who crouch-walks past is never found; it raises its glowing feelers before a nip. A golden
## spore puff glows gold in the dark and runs away (the caves' golden monster). Both have their own looks and their
## minds' hints; a Glow Caves night brings them.

const FLOOR := 10
const DT := 1.0 / 60.0
const U := 6

var _mode_before: StringName
var _n := 0
var _players: Array[Vector3] = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_players = [Vector3(0.5, FLOOR, 0.5)]


func after_each() -> void:
	Game.mode = _mode_before
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _flat(p: Vector3i) -> int:
	return BlockIds.CAVE_STONE if p.y < FLOOR else BlockIds.AIR


func _monster(kind: StringName, level: int, pos: Vector3, light: float = StealthRules.DARK_CAVE, golden := false,
		u: int = U) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "gm%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": u,
		"golden": golden})
	m.block_at = _flat
	m.light_at = func(_feet: Vector3) -> float: return light
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


func _box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = center


func _ground() -> void:
	_box(Vector3(0, FLOOR - 0.5, 0), Vector3(80, 1, 80))


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	p.stealth_light = StealthRules.DARK_CAVE
	return p


func _steps(m: Monster, n: int) -> void:
	for i in n:
		if is_instance_valid(m):
			m._physics_process(DT)


func _steps_until(m: Monster, done: Callable, limit: int = 120) -> void:
	for i in limit:
		if done.call():
			return
		_steps(m, 1)


# --- The spore puff ------------------------------------------------------------------------------------------

func test_a_spore_puff_is_dark_in_the_caves_and_seen_by_a_spore_lamp() -> void:
	_ground()
	_player(Vector3(0.5, FLOOR, -10.5))
	var dark := _monster(MonsterRules.SPORE_PUFF, 1, Vector3(0.5, FLOOR, 0.5), StealthRules.DARK_CAVE)
	var lit := _monster(MonsterRules.SPORE_PUFF, 1, Vector3(4.5, FLOOR, 0.5), StealthRules.NEAR_LIGHT)
	await get_tree().physics_frame
	_steps(dark, 6)
	_steps(lit, 6)
	assert_true(dark.dark, "in the caves' dark")
	assert_false(lit.dark, "a spore lamp near it shows it")


## Every screen: hidden far off in the dark; a shimmer of glowing spots a little nearer; the child's lantern shows it
## close by; its swelling always shows.
func test_the_puffs_shimmer_and_the_childs_lantern() -> void:
	var s := _monster(MonsterRules.SPORE_PUFF, 2, Vector3(0.5, 40, 0.5))
	s.set_process(false)
	var p := _player(Vector3(0.5, 40, -14.5))
	await get_tree().physics_frame
	var body := s.find_child("Body", true, false) as Node3D
	var shimmer := s.find_child("Shimmer", true, false) as Node3D
	assert_not_null(body)
	assert_not_null(shimmer)
	s.dark = true
	s._process(0.2)
	assert_false(body.visible, "dark and far: hidden")
	assert_false(shimmer.visible)
	p.global_position = Vector3(0.5, 40, -6.5)
	await get_tree().physics_frame
	s._process(0.2)
	assert_false(body.visible)
	assert_true(shimmer.visible, "its glowing spots within 8 blocks")
	p.global_position = Vector3(0.5, 40, -3.0)
	await get_tree().physics_frame
	s._process(0.2)
	assert_true(body.visible, "the child's lantern shows it close by")
	assert_same((shimmer.get_child(0) as MeshInstance3D).mesh, MonsterModels.shimmer_mesh(2, MonsterRules.SPORE_PUFF),
		"its own shimmer, shared")
	assert_ne(MonsterModels.shimmer_mesh(2, MonsterRules.SPORE_PUFF), MonsterModels.shimmer_mesh(2))


## (In universe 1's scale, so the bump is counted in hearts; universe 6 multiplies it by 32 like every monster's.)
func test_a_spore_puff_swells_then_bumps() -> void:
	_ground()
	var s := _monster(MonsterRules.SPORE_PUFF, 1, Vector3(0.5, FLOOR, 0.5), StealthRules.DARK_CAVE, false, 1)
	var p := _player(Vector3(0.5, FLOOR, -0.9))
	p.stealth_light = StealthRules.NEAR_LIGHT   # in the glow: the puff sees it
	await get_tree().physics_frame
	_steps_until(s, func() -> bool: return s.state == Monster.State.WINDUP, 120)
	assert_eq(s.state, Monster.State.WINDUP, "it swells up first")
	assert_true(s.winding)
	_steps(s, int(MonsterRules.PUFF_WINDUP / DT) + 4)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.SPORE_PUFF, 1, 1), "a little bump")


# --- The cave crawler ----------------------------------------------------------------------------------------

## Blind: a child standing in plain sight in front of it, in the glow, is not seen; walking near it is heard.
func test_a_blind_crawler_hears_a_walking_child_and_never_sees_a_still_one() -> void:
	_ground()
	var c := _monster(MonsterRules.CRAWLER, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -4.5))
	p.stealth_light = StealthRules.NEAR_LIGHT   # bright as day: a sighted monster would see it
	await get_tree().physics_frame
	assert_null(c.perceive(), "standing still in front of it: not found")
	p.velocity = Vector3(0, 0, 3.0)             # walking
	assert_same(c.perceive(), p, "a walking child 4 blocks off is heard")
	p.crouching = true
	p.velocity = Vector3(0, 0, 1.5)             # crouch-walking
	assert_null(c.perceive(), "a crouch-walk passes it")
	p.crouching = false
	p.velocity = Vector3.ZERO
	p.global_position = Vector3(0.5, FLOOR, -0.9)
	await get_tree().physics_frame
	assert_same(c.perceive(), p, "a child who touches it is felt")


func test_a_crawler_raises_its_feelers_then_nips() -> void:
	_ground()
	var c := _monster(MonsterRules.CRAWLER, 1, Vector3(0.5, FLOOR, 0.5), StealthRules.DARK_CAVE, false, 1)
	var p := _player(Vector3(0.5, FLOOR, -1.0))
	await get_tree().physics_frame
	_steps_until(c, func() -> bool: return c.state == Monster.State.WINDUP, 120)
	assert_eq(c.state, Monster.State.WINDUP)
	_steps(c, int(MonsterRules.CRAWLER_WINDUP / DT) + 4)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.CRAWLER, 1, 1), "a little nip")


## The caves' golden monster: a golden spore puff glows gold in the dark (never hidden) and runs from a child.
func test_a_golden_spore_puff_shows_and_flees() -> void:
	_ground()
	var g := _monster(MonsterRules.SPORE_PUFF, 1, Vector3(0.5, FLOOR, 0.5), StealthRules.DARK_CAVE, true)
	assert_true(g.golden, "spore puffs come golden too")
	_player(Vector3(0.5, FLOOR, -3.5))
	await get_tree().physics_frame
	_steps(g, 30)
	assert_false(g.dark, "a golden one glows: never hidden")
	assert_gt(g.global_position.z, 0.6, "it runs away")
	assert_true(MonsterRules.can_be_golden(MonsterRules.SPORE_PUFF))
	assert_false(MonsterRules.can_be_golden(MonsterRules.CRAWLER))


# --- The caves' nights ---------------------------------------------------------------------------------------

func _director() -> MonsterDirector:
	var d := MonsterDirector.new()
	d.name = "Monsters"
	d.player_positions = func() -> Array[Vector3]: return _players
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	d.lights_near = func(_p: Vector3) -> Array[Vector3i]: return [] as Array[Vector3i]
	d.home_beds = func() -> Array[Vector3i]: return [] as Array[Vector3i]
	d.time_of_day = func() -> float: return DayCycle.MIDNIGHT
	d.enabled = func() -> bool: return true
	d.block_at = _flat
	d.kinds = MonsterRules.GLOW_KINDS
	d.universe = U
	d.rng.seed = 7
	add_child_autofree(d)
	return d


func test_a_glow_caves_night_brings_spore_puffs_and_crawlers() -> void:
	var d := _director()
	d.light_at = func(_feet: Vector3) -> float: return StealthRules.DARK_CAVE
	var seen := {}
	for i in 8:
		d.tick()
	for m in d.monsters():
		seen[m.kind] = true
	assert_true(seen.has(MonsterRules.SPORE_PUFF) and seen.has(MonsterRules.CRAWLER), "%s" % [seen.keys()])


func test_glow_monsters_have_their_own_looks_and_hints() -> void:
	for kind: StringName in MonsterRules.GLOW_KINDS:
		for l in range(1, 6):
			var mesh := MonsterModels.mesh_for(kind, l)
			assert_same(mesh, MonsterModels.mesh_for(kind, l), "shared per kind and level")
			assert_eq(MonsterModels.spike_count(kind, l), l, "%s %d: the level in spikes" % [kind, l])
			assert_true(MonsterModels.colors_of(kind, l).has(MonsterRules.level_color(l)), "%s %d: its level colour" % [kind, l])
		assert_ne(MonsterModels.mesh_for(kind, 1), MonsterModels.mesh_for(MonsterRules.SLIME, 1))
		assert_not_null(MonsterModels.arm_mesh_for(kind, 1), "%s's part that moves for its signal" % kind)
		assert_true(MonsterModels.lights_up(kind), "%s glows as it winds up" % kind)
		for tactic in ["zigzag", "go_round", "wait", "back_off", "call"]:
			assert_true(MonsterSpecies.HINTS.has("%s:%s" % [kind, tactic]), "%s:%s" % [kind, tactic])
	assert_eq(VoiceRules.monster_idle(MonsterRules.CRAWLER), &"crawler_click")
