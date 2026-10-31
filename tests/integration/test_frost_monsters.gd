extends GutTest
## M3 Task 3 (spec §14.1): Frostpeak's monsters in the world. The yeti (a tank) lifts a snowball over its
## head (everyone sees it), then throws it where the child will be: a child who stands still is hit, a
## sidestep dodges it, a wall between stops the throw; up close it smashes the snowball down. The ice bat
## (the flyer) flutters over the ground, hovers and screeches, dives at a child (a sidestep dodges it),
## stays low for a moment, and rests hanging under a ceiling; it wakes when it sees a child. Their night
## spawns and waves come in Frostpeak. They never change blocks (the M2 tests that loop over
## MonsterRules.KINDS cover doors, lanterns and edits for them too).

const FLOOR := 10
const DT := 1.0 / 60.0

var _mode_before: StringName
var _n := 0
var _players: Array[Vector3] = []
var _cells := {}


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_players = [Vector3(0.5, FLOOR, 0.5)]
	_cells = {}


func after_each() -> void:
	Game.mode = _mode_before
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.SNOW if p.y < FLOOR else BlockIds.AIR


func _monster(kind: StringName, level: int, pos: Vector3, yaw: float = 0.0) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "fm%d" % _n, "pos": pos, "yaw": yaw, "wild": true, "universe": 3})
	m.block_at = _block
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


## The ground, and a box for every solid cell in _cells (the terrain's collision).
func _ground() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	shape.position = Vector3(0, FLOOR - 0.5, 0)
	body.add_child(shape)
	for p: Vector3i in _cells:
		if BlockIds.is_solid(_cells[p]):
			var s := CollisionShape3D.new()
			var b := BoxShape3D.new()
			b.size = Vector3.ONE
			s.shape = b
			s.position = Vector3(p) + Vector3(0.5, 0.5, 0.5)
			body.add_child(s)
	add_child_autofree(body)


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


# --- The yeti ---------------------------------------------------------------------------------------

func _winds_up_and_throws(y: Monster) -> void:
	_steps_until(y, func() -> bool: return y.state == Monster.State.WINDUP, 180)
	assert_eq(y.state, Monster.State.WINDUP)
	assert_true(y.winding, "everyone sees the snowball go up")
	_steps(y, int(MonsterRules.GOBLIN_WINDUP / DT) + 2)
	assert_eq(y.globs_in_flight(), 0, "still holding it up after a goblin's time")
	_steps_until(y, func() -> bool: return y.globs_in_flight() > 0, int((MonsterRules.YETI_WINDUP - MonsterRules.GOBLIN_WINDUP) / DT) + 6)
	assert_eq(y.globs_in_flight(), 1, "then the snowball flies")


func test_a_yeti_lifts_a_snowball_then_throws_it_and_a_child_standing_still_is_hit() -> void:
	_ground()
	var y := _monster(MonsterRules.YETI, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -7.5))
	await get_tree().physics_frame
	_winds_up_and_throws(y)
	assert_eq(p.health.hp, Health.MAX_HP, "nothing yet: it is flying")
	_steps_until(y, func() -> bool: return y.globs_in_flight() == 0, 120)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.YETI, 1, 3), "the snowball lands on them")


func test_a_sidestep_dodges_the_snowball() -> void:
	_ground()
	var y := _monster(MonsterRules.YETI, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -7.5))
	await get_tree().physics_frame
	_winds_up_and_throws(y)
	p.global_position += Vector3(2.5, 0, 0)
	_steps_until(y, func() -> bool: return y.globs_in_flight() == 0, 120)
	assert_eq(p.health.hp, Health.MAX_HP, "dodged")


func test_the_snowball_leads_a_running_child() -> void:
	_ground()
	var y := _monster(MonsterRules.YETI, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -8.5))
	p.velocity = Vector3(3.0, 0.0, 0.0)
	await get_tree().physics_frame
	_winds_up_and_throws(y)
	var landing: Vector3 = y.glob_landing(0)
	assert_gt(landing.x, p.global_position.x + 1.0, "aimed where the runner is going")
	assert_lte(landing.x - p.global_position.x, MonsterRules.MAX_LEAD + 0.01)


## A snow wall between the yeti and the child: it never throws through it (children hide behind walls).
func test_a_wall_between_stops_the_throw() -> void:
	for x in range(-3, 4):
		for yy in range(FLOOR, FLOOR + 4):
			_cells[Vector3i(x, yy, -4)] = BlockIds.SNOW_BRICK
	_ground()
	var y := _monster(MonsterRules.YETI, 1, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -7.5))
	await get_tree().physics_frame
	for i in 240:
		y._target = p
		y.awareness.see(p.global_position)
		_steps(y, 1)
		assert_eq(y.globs_in_flight(), 0, "no snowball through the wall")
	assert_eq(p.health.hp, Health.MAX_HP)


func test_up_close_it_smashes_the_snowball_down() -> void:
	_ground()
	var y := _monster(MonsterRules.YETI, 2, Vector3(0.5, FLOOR, 0.5))
	var p := _player(Vector3(0.5, FLOOR, -1.0))
	await get_tree().physics_frame
	_steps_until(y, func() -> bool: return y.state == Monster.State.WINDUP)
	assert_true(y.winding)
	_steps(y, int(MonsterRules.YETI_WINDUP / DT) + 4)
	assert_eq(y.globs_in_flight(), 0, "no throw this close")
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.YETI, 2, 3), "the smash lands")


func test_a_yeti_is_slow_and_hard_to_push() -> void:
	var y := _monster(MonsterRules.YETI, 3, Vector3(0.5, 40, 0.5))
	y.take_hit(1, Vector3(0.5, 40, 2.5), Vector3(0, 3, -6))
	assert_almost_eq(y.velocity, Vector3(0, 3, -6) * MonsterRules.YETI_PUSH, Vector3.ONE * 0.01)
	assert_eq(y.hp, MonsterRules.hp(MonsterRules.YETI, 3, 3) - 1, "universe 3's health")


func test_the_yeti_holds_its_snowball_up_while_it_winds_up() -> void:
	var y := _monster(MonsterRules.YETI, 3, Vector3(0.5, 40, 0.5))
	var arms := y.find_child("Arm", true, false) as Node3D
	assert_not_null(arms, "its arms turn on their own pivot")
	var mesh := arms.get_child(0) as MeshInstance3D
	var calm := mesh.mesh
	y.winding = true
	y._process(DT)
	assert_ne(mesh.mesh, calm, "a snowball in its hands while it winds up")
	assert_same(mesh.mesh, MonsterModels.arm_mesh_for(MonsterRules.YETI, 3, 0, true), "a shared mesh")
	y.winding = false
	y._process(DT)
	assert_same(mesh.mesh, calm)


# --- The ice bat ---------------------------------------------------------------------------------------

func test_a_bat_flies_over_the_ground_and_does_not_fall() -> void:
	_ground()
	var b := _monster(MonsterRules.ICE_BAT, 1, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(20.5, FLOOR, 20.5))              # within 32 blocks, so it moves (and out of sight)
	await get_tree().physics_frame
	var low := [INF]
	for i in 240:
		_steps(b, 1)
		if i > 120:
			low[0] = minf(low[0], b.global_position.y)
	assert_gt(low[0], FLOOR + MonsterRules.BAT_CRUISE - 1.2, "it flutters above the snow (%.1f)" % low[0])
	assert_lt(b.global_position.y, FLOOR + MonsterRules.BAT_CRUISE + 1.5, "not off into the sky")


func _bat_after(p: Player) -> Monster:
	var b := _monster(MonsterRules.ICE_BAT, 1, Vector3(4.5, FLOOR + 3.5, 0.5))
	b.velocity = Vector3.ZERO
	return b


func test_a_bat_signals_then_dives_and_a_child_standing_still_is_hit() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var b := _bat_after(p)
	await get_tree().physics_frame
	_steps_until(b, func() -> bool: return b.state == Monster.State.WINDUP, 300)
	assert_eq(b.state, Monster.State.WINDUP, "it hovers and screeches first")
	assert_true(b.winding)
	var start := b.global_position
	_steps(b, int(MonsterRules.BAT_WINDUP / DT) - 4)
	assert_lt(b.global_position.distance_to(start), 0.6, "it hovers in place while it signals")
	assert_eq(p.health.hp, Health.MAX_HP)
	_steps_until(b, func() -> bool: return p.health.hp < Health.MAX_HP, 120)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.ICE_BAT, 1, 3), "the dive lands")
	_steps(b, 20)
	assert_lt(b.global_position.y, FLOOR + 2.2, "then it stays low for a moment (a sword reaches it)")


## Found by the smoke run on real terrain: a bat whose hover spot was inside a hill never got there, so it
## never dived. It hovers on another side (or right over the child) when its side is blocked.
func test_a_bat_whose_side_is_blocked_hovers_on_another_side_and_dives() -> void:
	for x in range(3, 7):
		for y in range(FLOOR, FLOOR + 5):
			for z in range(-6, 7):
				_cells[Vector3i(x, y, z)] = BlockIds.SNOW       # a hill between the bat and the child
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var b := _monster(MonsterRules.ICE_BAT, 1, Vector3(10.5, FLOOR + 8, 0.5))
	await get_tree().physics_frame
	for i in 600:
		b._target = p
		b.awareness.see(p.global_position)
		_steps(b, 1)
		if p.health.hp < Health.MAX_HP:
			break
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(MonsterRules.ICE_BAT, 1, 3), "it found a way to dive")


func test_a_sidestep_dodges_the_dive() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var b := _bat_after(p)
	await get_tree().physics_frame
	_steps_until(b, func() -> bool: return b.state == Monster.State.WINDUP, 300)
	_steps_until(b, func() -> bool: return b.state != Monster.State.WINDUP, 120)
	p.global_position += Vector3(0, 0, 2.5)
	_steps(b, int(MonsterRules.BAT_DIVE_TIME / DT) + 10)
	assert_eq(p.health.hp, Health.MAX_HP, "dodged")


func test_a_tired_bat_hangs_under_a_ceiling_and_wakes_when_it_sees_a_child() -> void:
	for x in range(-6, 7):
		for z in range(-6, 7):
			_cells[Vector3i(x, FLOOR + 5, z)] = BlockIds.STONE      # a cave's ceiling
	_ground()
	var b := _monster(MonsterRules.ICE_BAT, 1, Vector3(0.5, FLOOR + 2, 0.5))
	var far := _player(Vector3(28.5, FLOOR, 0.5))                  # near enough to be simulated, out of sight
	await get_tree().physics_frame
	b.tire()
	_steps_until(b, func() -> bool: return b.perched, 300)
	assert_true(b.perched, "it hangs up there")
	assert_almost_eq(b.global_position.y + b.size().y, FLOOR + 5.0, 0.2, "right under the ceiling")
	var at := b.global_position
	_steps(b, 60)
	assert_eq(b.global_position, at, "resting: not a step (and no physics move)")
	far.global_position = Vector3(0.5, FLOOR, 3.5)                 # a child walks in under it
	await get_tree().physics_frame
	_steps_until(b, func() -> bool: return not b.perched, 120)
	assert_false(b.perched, "awake")


## Doors keep walkers out (M2 Task 8); a bat flies, so it is a roof that keeps it out (ruling: a house
## without a roof lets bats in over its walls).
func test_a_house_with_a_roof_keeps_bats_out() -> void:
	for x in range(5, 13):
		for z in range(-4, 5):
			_cells[Vector3i(x, FLOOR + 2, z)] = BlockIds.PLANKS          # the roof
			for y in [FLOOR, FLOOR + 1]:
				if x == 5 or x == 12 or z == -4 or z == 4:
					_cells[Vector3i(x, y, z)] = BlockIds.PLANKS
	_cells[Vector3i(5, FLOOR, 0)] = BlockIds.DOOR
	_cells[Vector3i(5, FLOOR + 1, 0)] = BlockIds.DOOR
	_ground()
	var p := _player(Vector3(8.5, FLOOR, 0.5))
	var bats: Array[Monster] = []
	for i in 3:
		bats.append(_monster(MonsterRules.ICE_BAT, 3 + i, Vector3(-2.5 + i, FLOOR + 3, -2.5 + i * 2)))
	await get_tree().physics_frame
	for i in 600:
		for b in bats:
			b._target = p
			b.awareness.see(p.global_position)
			_steps(b, 1)
			var at := b.global_position
			assert_false(at.x > 5.0 and at.x < 12.0 and at.z > -4.0 and at.z < 4.0 and at.y < FLOOR + 2.0,
				"a bat got into the house at %s" % at)
	assert_eq(p.health.hp, Health.MAX_HP, "nobody reached the child")


func test_a_bat_is_two_shared_meshes_and_its_wings_flap() -> void:
	var b := _monster(MonsterRules.ICE_BAT, 2, Vector3(0.5, 40, 0.5))
	var wings := b.find_child("Arm", true, false) as Node3D
	assert_not_null(wings, "its wings")
	var mesh := wings.get_child(0) as MeshInstance3D
	var seen := {}
	for i in 30:
		b.global_position += Vector3(0.05, 0, 0)
		b._process(DT)
		seen[mesh.mesh] = true
	assert_gt(seen.size(), 1, "the wings go up and down")
	for m: Mesh in seen:
		assert_true(m == MonsterModels.arm_mesh_for(MonsterRules.ICE_BAT, 2, 0, false, 0)
			or m == MonsterModels.arm_mesh_for(MonsterRules.ICE_BAT, 2, 0, false, 1), "shared wing meshes")


# --- Frostpeak's nights and waves ---------------------------------------------------------------------

func test_a_frost_night_brings_yetis_and_bats() -> void:
	var d := MonsterDirector.new()
	d.name = "Monsters"
	d.player_positions = func() -> Array[Vector3]: return _players
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	d.lights_near = func(_p: Vector3) -> Array[Vector3i]: return [] as Array[Vector3i]
	d.home_beds = func() -> Array[Vector3i]: return [] as Array[Vector3i]
	d.time_of_day = func() -> float: return DayCycle.MIDNIGHT
	d.enabled = func() -> bool: return true
	d.block_at = _block
	d.kinds = MonsterRules.FROST_KINDS
	d.universe = 3
	d.rng.seed = 7
	add_child_autofree(d)
	var seen := {}
	for i in 8:
		d.tick()
	for m in d.monsters():
		seen[m.kind] = true
		assert_eq(m.universe, 3)
	assert_true(seen.has(MonsterRules.YETI) and seen.has(MonsterRules.ICE_BAT), "%s" % [seen.keys()])


func test_a_frost_totem_wave_brings_yetis_and_bats() -> void:
	var kinds := {}
	for m: Dictionary in WaveRules.roster(3, false, 1, MonsterRules.FROST_KINDS):
		kinds[m.kind] = true
	assert_true(kinds.has(MonsterRules.YETI) and kinds.has(MonsterRules.ICE_BAT))
	assert_eq(WaveRules.BOSS_AFTER, 5, "five waves before the boss")
	assert_true(ChatCommands.MONSTERS.has("yeti") and ChatCommands.MONSTERS.has("bat"), "/summon yeti, /summon bat")
