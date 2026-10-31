extends GutTest
## M3 Task 4 (spec §14.1, §5.2): the Candy Kingdom's monsters in the world. The gummy bear hops higher than a
## slime and bounces off walls (MonsterRules.wall_bounce, on real physics); the candy sneaker is dark where the
## light is low (the host measures its light: `light_at`), every screen hides its body then and shows only a
## shimmer within 6 blocks of that screen's player — and always a shimmer and a jingle while its lollipop winds
## up (fair). The night spawns and waves of a candy world bring them. They never change blocks (the M2 tests
## that loop over MonsterRules.KINDS cover doors, lanterns and edits for them too).

const FLOOR := 10
const DT := 1.0 / 60.0
const U := 4

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
	return BlockIds.FROSTING if p.y < FLOOR else BlockIds.AIR


func _monster(kind: StringName, level: int, pos: Vector3, light: float = 1.0) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "cm%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": U})
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


# --- The gummy bear ------------------------------------------------------------------------------------

func test_a_gummy_bear_hops_higher_than_a_slime() -> void:
	_ground()
	var g := _monster(MonsterRules.GUMMY, 1, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(0.5, FLOOR, -6.5))
	await get_tree().physics_frame
	var top := [0.0]
	for i in 180:
		_steps(g, 1)
		top[0] = maxf(top[0], g.velocity.y)
	assert_almost_eq(top[0], MonsterRules.GUMMY_HOP_UP, 0.3, "it hops at a gummy's speed")
	assert_lt(g.global_position.z, -1.0, "towards the child")


## Flying into a wall, it bounces back off it (the pure rule on real physics) instead of sliding down it.
func test_a_gummy_bear_bounces_off_a_real_wall() -> void:
	_ground()
	_box(Vector3(-2.5, FLOOR + 3.0, 0.5), Vector3(1.0, 6.0, 12.0))   # a wall at x = -2
	var g := _monster(MonsterRules.GUMMY, 1, Vector3(0.0, FLOOR + 1.0, 0.5))
	_player(Vector3(12.5, FLOOR, 0.5))
	await get_tree().physics_frame
	g.velocity = Vector3(-6.0, 4.0, 0.0)
	var bounced := [false]
	for i in 40:
		_steps(g, 1)
		if g.velocity.x > 1.0:
			bounced[0] = true
			break
	assert_true(bounced[0], "it came back off the wall (vx %.2f)" % g.velocity.x)
	assert_gt(g.global_position.x, -1.8, "never through it")


func test_a_gummy_bear_nips_a_child_it_lands_on() -> void:
	_ground()
	var g := _monster(MonsterRules.GUMMY, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -0.8))
	await get_tree().physics_frame
	_steps_until(g, func() -> bool: return p.health.hp < Health.MAX_HP, 240)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.GUMMY, 1, U), "a nip, × 8 in universe 4")


# --- The candy sneaker ---------------------------------------------------------------------------------

## The host measures the light where it stands (at its looks); `dark` goes to every screen.
func test_a_sneaker_is_dark_at_night_and_in_plain_sight_by_day() -> void:
	_ground()
	_player(Vector3(0.5, FLOOR, -10.5))
	var night := _monster(MonsterRules.SNEAKER, 1, Vector3(0.5, FLOOR, 0.5), StealthRules.NIGHT)
	var day := _monster(MonsterRules.SNEAKER, 1, Vector3(4.5, FLOOR, 0.5), StealthRules.DAYLIGHT)
	await get_tree().physics_frame
	_steps(night, 6)
	_steps(day, 6)
	assert_true(night.dark, "dark at night")
	assert_false(day.dark, "seen by day")
	var goblin := _monster(MonsterRules.GOBLIN, 1, Vector3(8.5, FLOOR, 0.5), StealthRules.NIGHT)
	_steps(goblin, 6)
	assert_false(goblin.dark, "only sneakers hide in the dark")


## Every screen: in the dark the body is hidden and only a shimmer shows, within 6 blocks of this screen's
## player; far away nothing shows; while it winds up it always shimmers; in the light it is seen.
func test_in_the_dark_a_shimmer_shows_it_only_near_a_player() -> void:
	var s := _monster(MonsterRules.SNEAKER, 2, Vector3(0.5, 40, 0.5), StealthRules.NIGHT)
	s.set_process(false)             # this test steps its looks by hand
	var p := _player(Vector3(0.5, 40, -12.5))
	await get_tree().physics_frame
	var body := s.find_child("Body", true, false) as Node3D
	var shimmer := s.find_child("Shimmer", true, false) as Node3D
	assert_not_null(body)
	assert_not_null(shimmer)
	s.dark = true
	s._process(DT)
	assert_false(body.visible, "dark and far: invisible")
	assert_false(shimmer.visible)
	p.global_position = Vector3(0.5, 40, -4.5)
	await get_tree().physics_frame
	s._process(0.2)
	assert_false(body.visible)
	assert_true(shimmer.visible, "a shimmer within 6 blocks")
	p.global_position = Vector3(0.5, 40, -20.5)
	await get_tree().physics_frame
	s.winding = true
	s._process(0.2)
	assert_true(shimmer.visible, "always a shimmer while it winds up")
	s.winding = false
	s.dark = false
	s._process(0.2)
	assert_true(body.visible, "in the light it is seen like any monster")
	assert_false(shimmer.visible)
	assert_same((shimmer.get_child(0) as MeshInstance3D).mesh, MonsterModels.shimmer_mesh(2), "a shared mesh")


func test_a_sneaker_jingles_winds_up_its_lollipop_then_hits() -> void:
	_ground()
	var s := _monster(MonsterRules.SNEAKER, 1, Vector3(0.5, FLOOR, 0.5), StealthRules.NIGHT)
	var p := _player(Vector3(0.5, FLOOR, -0.9))
	await get_tree().physics_frame
	_steps_until(s, func() -> bool: return s.state == Monster.State.WINDUP, 120)
	assert_eq(s.state, Monster.State.WINDUP)
	assert_true(s.winding, "everyone sees the lollipop go up")
	s._process(DT)
	assert_eq(s.jingles, 1, "a jingle as it starts (every screen)")
	_steps(s, int(MonsterRules.GOBLIN_WINDUP / DT) + 2)
	assert_eq(p.health.hp, Health.MAX_HP, "still winding up after a goblin's time")
	_steps(s, int((MonsterRules.SNEAKER_WINDUP - MonsterRules.GOBLIN_WINDUP) / DT) + 4)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.SNEAKER, 1, U), "the lollipop lands")


func test_stepping_back_dodges_the_sneaker() -> void:
	_ground()
	var s := _monster(MonsterRules.SNEAKER, 1, Vector3(0.5, FLOOR, 0.5), StealthRules.NIGHT)
	var p := _player(Vector3(0.5, FLOOR, -0.9))
	await get_tree().physics_frame
	_steps_until(s, func() -> bool: return s.state == Monster.State.WINDUP)
	p.global_position = Vector3(0.5, FLOOR, -5.5)
	_steps(s, int(MonsterRules.SNEAKER_WINDUP / DT) + 4)
	assert_eq(p.health.hp, Health.MAX_HP, "missed")


# --- The kingdom's nights and waves ----------------------------------------------------------------------

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
	d.kinds = MonsterRules.CANDY_KINDS
	d.universe = U
	d.rng.seed = 7
	add_child_autofree(d)
	return d


func test_a_candy_night_brings_gummy_bears_and_sneakers() -> void:
	var d := _director()
	var measured := []
	d.light_at = func(feet: Vector3) -> float:
		measured.append(feet)
		return StealthRules.NIGHT
	var seen := {}
	for i in 8:
		d.tick()
	for m in d.monsters():
		seen[m.kind] = true
		assert_eq(m.universe, U)
		assert_true(m.light_at.is_valid(), "the director hands every monster the light probe")
	assert_true(seen.has(MonsterRules.GUMMY) and seen.has(MonsterRules.SNEAKER), "%s" % [seen.keys()])


func test_a_candy_totem_wave_brings_gummy_bears_and_sneakers() -> void:
	var roster := WaveRules.roster(3, false, 1, MonsterRules.CANDY_KINDS)
	var kinds := {}
	for m: Dictionary in roster:
		kinds[m.kind] = true
	assert_true(kinds.has(MonsterRules.GUMMY) and kinds.has(MonsterRules.SNEAKER))
	assert_eq(WaveRules.BOSS_AFTER, 5, "five waves before the boss")


func test_candy_monsters_have_their_own_looks() -> void:
	for kind: StringName in MonsterRules.CANDY_KINDS:
		for l in range(1, 6):
			var mesh := MonsterModels.mesh_for(kind, l)
			assert_not_null(mesh)
			assert_same(mesh, MonsterModels.mesh_for(kind, l), "shared per kind and level")
			assert_eq(MonsterModels.spike_count(kind, l), l, "%s %d: the level in spikes" % [kind, l])
	assert_ne(MonsterModels.mesh_for(MonsterRules.GUMMY, 1), MonsterModels.mesh_for(MonsterRules.SLIME, 1))
	assert_not_null(MonsterModels.arm_mesh_for(MonsterRules.SNEAKER, 1), "the sneaker's lollipop")
	assert_null(MonsterModels.arm_mesh_for(MonsterRules.GUMMY, 1), "a gummy bear has no weapon")
	assert_true(MonsterSpecies.HINTS.has("gummy:call"))
	assert_true(MonsterSpecies.HINTS.has("sneaker:zigzag"))
