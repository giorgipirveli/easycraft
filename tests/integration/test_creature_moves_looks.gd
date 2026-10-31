extends GutTest
## M5 Task 2 (spec §15.2): monster and boss moves on real bodies. Slimes and gummy bears crouch (a synced wind-up
## every screen sees) before they pounce at a child they see; every monster and boss leans back when a hit lands;
## the Golem and the Frost Giant breathe while they stand; a boss that wins a fight cheers for
## CreatureMoves.WIN_TIME with its own roar before it sinks. One shared CreatureMoves, poses only. Solo: host.

const FLOOR := 10
const DT := 1.0 / 60.0

var _mode_before: StringName
var _n := 0
var _sounds: Array[StringName] = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_sounds.clear()
	Audio.sound_played.connect(_on_sound)


func after_each() -> void:
	Audio.sound_played.disconnect(_on_sound)
	Game.mode = _mode_before
	Music.reset()


func after_all() -> void:
	Audio.stop_all()


func _on_sound(sound: StringName, _at: Vector3, _db: float) -> void:
	_sounds.append(sound)


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _monster(kind: StringName, pos: Vector3, level: int = 1) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "cm%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": 1})
	m.block_at = _flat
	add_child_autofree(m)
	m.set_physics_process(false)
	m.set_process(false)
	return m


func _steps(m: Node, n: int) -> void:
	for i in n:
		if is_instance_valid(m):
			m.call(&"_physics_process", DT)


func _body(n: Node3D) -> Node3D:
	return n.get(&"_body") as Node3D


# --- The jumpers' pounce ---------------------------------------------------------------------------------------

func _pounce_check(kind: StringName) -> void:
	_ground()
	var s := _monster(kind, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(0.5, FLOOR, -2.0))   # 2.5 blocks ahead: in pounce range, out of touch
	await get_tree().physics_frame
	for i in 180:
		if s.winding:
			break
		_steps(s, 1)
	assert_true(s.winding, "%s: it winds up before it pounces (synced: every screen sees)" % kind)
	assert_eq(s.state, Monster.State.WINDUP)
	var y := s.global_position.y
	var z := s.global_position.z
	assert_almost_eq(y, float(FLOOR), 0.1, "it crouches on the ground")
	for i in 8:
		s._process(DT)
	assert_lt(_body(s).scale.y, 0.85, "low")
	assert_gt(_body(s).scale.x, 1.05, "and wide")
	_steps(s, int(CreatureMoves.POUNCE_WINDUP / DT) + 6)
	assert_false(s.winding, "then it pounces")
	assert_gt(s.global_position.y, y + 0.1, "up")
	assert_lt(s.global_position.z, z - 0.1, "at the child")


func test_a_slime_crouches_then_pounces_at_a_child_it_sees() -> void:
	await _pounce_check(MonsterRules.SLIME)


func test_a_gummy_bear_crouches_then_pounces_too() -> void:
	await _pounce_check(MonsterRules.GUMMY)


func test_a_slime_far_from_the_child_just_hops() -> void:
	_ground()
	var s := _monster(MonsterRules.SLIME, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(0.5, FLOOR, -12.0))
	await get_tree().physics_frame
	var wound := false
	for i in 90:
		_steps(s, 1)
		wound = wound or s.winding
	assert_false(wound, "out of pounce range: hops, no wind-up")


func test_every_screen_shows_the_crouch_from_the_synced_wind_up() -> void:
	var s := _monster(MonsterRules.SLIME, Vector3(0, 40, 0))
	s.winding = true                    # what a guest sees arrive
	for i in 20:
		s._process(DT)
	assert_lt(_body(s).scale.y, 0.8)
	s.winding = false
	for i in 20:
		s._process(DT)
	assert_almost_eq(_body(s).scale, Vector3.ONE, Vector3.ONE * 0.02, "back to its shape")


# --- Every hit: a recoil -------------------------------------------------------------------------------------------

func test_every_monster_leans_back_when_a_hit_lands_then_stands_straight() -> void:
	for kind: StringName in [MonsterRules.GOBLIN, MonsterRules.SLIME, MonsterRules.MUMMY, MonsterRules.YETI,
			MonsterRules.GUMMY, MonsterRules.WISP]:
		var m := _monster(kind, Vector3(_n * 3.0, 40, 0), 2)
		m._process(DT)
		m.hp -= 1                        # what every screen sees: the synced hearts drop
		m._process(DT)
		assert_gt(_body(m).rotation.x, 0.1, "%s leans back" % kind)
		for i in 40:
			m._process(DT)
		assert_almost_eq(_body(m).rotation.x, 0.0, 0.001, "%s stands straight again" % kind)


# --- Bosses ------------------------------------------------------------------------------------------------------

func _boss(script: GDScript) -> StoneGolem:
	_n += 1
	var b: StoneGolem = script.new()
	b.setup({"id": "b%d" % _n, "pos": Vector3(_n * 20.0, FLOOR, 0.5), "yaw": 0.0, "max_hp": 300, "tired": false})
	b.block_at = _flat
	add_child_autofree(b)
	b.set_physics_process(false)
	b.set_process(false)
	return b


const GROUND_BOSSES := [preload("res://entities/monsters/stone_golem.gd"), preload("res://entities/monsters/sand_serpent.gd"),
	preload("res://entities/monsters/frost_giant.gd"), preload("res://entities/monsters/cake_monster.gd")]


func test_a_boss_that_wins_cheers_with_its_roar_then_sinks() -> void:
	for script: GDScript in GROUND_BOSSES:
		var b := _boss(script)
		_stand(b)
		b._process(DT)
		var y := b.global_position.y
		_sounds.clear()
		b.go_to_sleep()
		var hop := 0.0
		for i in int(CreatureMoves.WIN_TIME * 0.9 / DT):
			b._physics_process(DT)
			b._process(DT)
			hop = maxf(hop, _body(b).position.y)
		var what := String(b.boss_kind())
		assert_true(b.win_sound() in _sounds, "%s: its roar (%s)" % [what, b.win_sound()])
		assert_true(Audio.SOUNDS.has(b.win_sound()), "%s: a sound Audio knows" % what)
		assert_almost_eq(b.global_position.y, y, 0.01, "%s: it stays up while it cheers" % what)
		assert_gt(hop, 0.05, "%s: a hop of joy" % what)
		for i in int((CreatureMoves.WIN_TIME * 0.1 + StoneGolem.SINK_TIME + 0.3) / DT):
			if is_instance_valid(b) and not b.is_queued_for_deletion():
				b._physics_process(DT)
		assert_true(not is_instance_valid(b) or b.is_queued_for_deletion(), "%s: then it sinks and is gone" % what)


## M5 Task 6 (the whole-game review): the roar is for a boss that won; a defeated boss must stay quiet on every screen.
## The host knew a defeat by its own `_defeated`, which a guest's copy never sets (take_hit runs on the host only): a
## guest's copy that got the synced DOWN with 0 hearts would have roared over the defeat's own crumble. (Godot 4.7 never
## sends a change made in the frame the node is freed, so this can't be heard today; the synced hearts make it certain.)
func test_a_guests_copy_of_a_defeated_boss_stays_quiet() -> void:
	for script: GDScript in GROUND_BOSSES + [preload("res://entities/monsters/sky_dragon.gd")]:
		var own: Dictionary = script.get_script_constant_map().get("P", BossRules.Phase)   # each boss's own phases
		for won: bool in [false, true]:
			var b := _boss(script)
			b.global_position = Vector3.ZERO   # within hearing
			b._process(DT)
			var tries := Audio.played + Audio.dropped
			b.hp = 120 if won else 0     # what a guest's copy gets: hearts left (it won) or none (defeated) ...
			b.phase = int(own.DOWN)      # ... and down (take_hit and go_to_sleep run on the host only)
			b._process(DT)
			# DOWN plays nothing but the win roar; Audio may drop a sound heard in the last 80 ms, so count the tries
			assert_eq(Audio.played + Audio.dropped - tries, 1 if won else 0,
				"%s: %s" % [b.boss_kind(), "it won: its roar" if won else "no win roar for a defeat"])
			if won:
				assert_eq(Audio.last_sound, b.win_sound())
			b.free()
	var until := Time.get_ticks_msec() + 100   # Audio's same-sound window is real time (80 ms): the later tests hear
	while Time.get_ticks_msec() < until:       # their own roars (a SceneTree timer runs on the frames' fixed time here)
		await get_tree().process_frame


func test_the_golem_raises_and_pumps_its_arms_when_it_wins() -> void:
	var g := _boss(GROUND_BOSSES[0])
	g.start_phase(BossRules.Phase.WALK)
	g.go_to_sleep()
	var top := 0.0
	for i in int(CreatureMoves.WIN_TIME / DT):
		g._process(DT)
		top = maxf(top, (g.get(&"_arm_l") as Node3D).rotation.x)
	assert_gt(top, 2.0, "arms over its head")


func test_the_golem_and_the_frost_giant_breathe_while_they_stand() -> void:
	for script: GDScript in [GROUND_BOSSES[0], GROUND_BOSSES[2]]:
		var b := _boss(script)
		_stand(b)                        # standing: nobody to walk to
		var lo := INF
		var hi := -INF
		var arms_lo := INF
		var arms_hi := -INF
		for i in int(CreatureMoves.BREATH_PERIOD / DT):
			b._process(DT)
			lo = minf(lo, _body(b).position.y)
			hi = maxf(hi, _body(b).position.y)
			var a := (b.get(&"_arm_l") as Node3D).rotation.x
			arms_lo = minf(arms_lo, a)
			arms_hi = maxf(arms_hi, a)
		assert_gt(hi - lo, 0.02, "%s: its chest rises and falls" % b.boss_kind())
		assert_gt(arms_hi - arms_lo, 0.05, "%s: its arms sway" % b.boss_kind())


func test_every_boss_leans_back_when_a_hit_lands() -> void:
	for script: GDScript in GROUND_BOSSES:
		var b := _boss(script)
		_stand(b)
		for i in 5:
			b._process(DT)
		var before := _lean(b)
		b.hp -= 5
		b._process(DT)
		b._process(DT)
		assert_gt(_lean(b) - before, 0.05, "%s leans back" % b.boss_kind())
		for i in 40:
			b._process(DT)
		assert_lt(absf(_lean(b) - before), 0.04, "%s stands again" % b.boss_kind())


## The part that leans: the body (the serpent: its head).
func _lean(b: StoneGolem) -> float:
	if b is SandSerpent:
		return (b.get(&"_head") as Node3D).rotation.x
	return _body(b).rotation.x


## Up and standing: WALK (the serpent: UP, out of the sand).
func _stand(b: StoneGolem) -> void:
	b.start_phase(SerpentRules.Phase.UP if b is SandSerpent else BossRules.Phase.WALK)


func test_the_sky_dragon_roars_as_it_flies_off_after_a_win() -> void:
	var d := _boss(preload("res://entities/monsters/sky_dragon.gd"))
	d._process(DT)
	_sounds.clear()
	d.go_to_sleep()
	d._process(DT)
	assert_true(d.win_sound() in _sounds, "its roar")
