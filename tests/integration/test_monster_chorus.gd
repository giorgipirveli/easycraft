extends GutTest
## M5 Task 2 (spec §15.2): real monsters round this device's camera, and the MonsterChorus that voices them. A night
## of 20 goblins used to be ~120 grunts a minute (every goblin its own 6-14 s timer); now a few, through one budget.
## A cry when a hit lands is never held back.

const DT := 0.1

var _n := 0
var _mode_before: StringName
var _cam: Camera3D
var _sounds: Array = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_sounds.clear()
	Audio.sound_played.connect(_on_sound)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.global_position = Vector3(0, 12, 0)
	_cam.current = true


func after_each() -> void:
	Audio.sound_played.disconnect(_on_sound)
	Game.mode = _mode_before
	_cam.free()


func after_all() -> void:
	Audio.stop_all()


func _on_sound(sound: StringName, at: Vector3, db: float) -> void:
	_sounds.append([sound, at, db])


func _monster(kind: StringName, pos: Vector3) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": 2, "id": "mc%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": 1})
	m.block_at = func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 10 else BlockIds.AIR
	add_child_autofree(m)
	m.set_physics_process(false)
	m.set_process(false)
	return m


func _chorus() -> MonsterChorus:
	var c := MonsterChorus.new()
	c.rng.seed = 5
	add_child_autofree(c)
	c.set_process(false)
	return c


func _count(sound: StringName) -> int:
	return _sounds.filter(func(s: Array) -> bool: return s[0] == sound).size()


func test_a_night_of_twenty_goblins_is_calm() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var goblins: Array[Monster] = []
	for i in 20:
		var a := rng.randf() * TAU
		var d := rng.randf_range(2.0, 18.0)
		goblins.append(_monster(MonsterRules.GOBLIN, Vector3(cos(a) * d, 10, sin(a) * d)))
	var chorus := _chorus()
	var voiced: Array = []
	chorus.called.connect(func(_m: Monster, sound: StringName, _db: float) -> void: voiced.append(sound))
	for i in int(600.0 / DT):          # ten minutes
		chorus.step(DT)
		if i % 10 == 0:
			for g in goblins:
				g._process(DT * 10)       # the monsters' own looks: they never grunt by themselves now
	# (Audio drops the same sound 3 times in 80 ms of real time, and this runs ten minutes in a moment: count the
	# chorus's voices, and that nothing else grunted.)
	assert_lte(_count(&"grunt"), voiced.size(), "no goblin grunts on its own")
	var per_minute := voiced.size() / 10.0
	gut.p("MONSTER_CHORUS 20 goblins: %.1f grunts a minute" % per_minute)
	assert_between(per_minute, 2.0, 6.0, "a few grunts a minute, not ~120")


func test_a_monster_near_the_camera_is_heard_through_the_chorus_a_far_one_is_not() -> void:
	var near := _monster(MonsterRules.MUMMY, Vector3(0, 10, 8))
	_monster(MonsterRules.SCORPION, Vector3(0, 10, 30))
	var chorus := _chorus()
	var heard: Array = []
	chorus.called.connect(func(m: Monster, sound: StringName, db: float) -> void: heard.append([m, sound, db]))
	for i in int(60.0 / DT):
		chorus.step(DT)
	assert_gt(heard.size(), 0, "the mummy moans now and then")
	for h: Array in heard:
		assert_same(h[0], near, "only the one within 20 blocks of the camera")
		assert_eq(h[1], VoiceRules.monster_idle(MonsterRules.MUMMY))
	assert_eq(_count(VoiceRules.monster_idle(MonsterRules.SCORPION)), 0, "the far scorpion keeps quiet")


func test_a_perched_bat_asleep_under_a_ceiling_is_quiet() -> void:
	var bat := _monster(MonsterRules.ICE_BAT, Vector3(0, 10, 4))
	bat.perched = true
	var chorus := _chorus()
	for i in int(60.0 / DT):
		chorus.step(DT)
	assert_eq(_count(VoiceRules.monster_idle(MonsterRules.ICE_BAT)), 0)


func test_a_cry_when_a_hit_lands_is_never_held_back_and_the_chorus_waits() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "1"
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0, 10, 0)
	await wait_physics_frames(2)         # the player list is refreshed once per physics frame
	var g := _monster(MonsterRules.GOBLIN, Vector3(0, 10, 4))
	var chorus := _chorus()
	for i in int(20.0 / DT):
		chorus.step(DT)
	g._process(DT)
	g.hp -= 1                            # what every screen sees
	g._process(DT)
	assert_eq(_count(VoiceRules.monster_hurt(MonsterRules.GOBLIN)), 1, "the cry plays at once")
	assert_gte(chorus.rules.next_time(), chorus.now() + MonsterChorusRules.AFTER_VOICE - 0.01, "the chorus waits")
	assert_eq(chorus.rules.last_heard(MonsterRules.GOBLIN), chorus.now(), "and the goblins rest")
