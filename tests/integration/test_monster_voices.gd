extends GutTest
## Monster voices (the audio pass, owner feedback #27): a monster cries out when a hit lands (on every
## peer, from the synced hearts) and grunts, squishes, moans or clicks now and then while it moves about
## near a player (VoiceRules). Solo: this game is the host.

var _n := 0
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR


func after_each() -> void:
	Game.mode = _mode_before


func after_all() -> void:
	Audio.stop_all()


func _monster(kind: StringName, pos: Vector3) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": 3, "id": "voice%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": 1})
	m.block_at = func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 10 else BlockIds.AIR
	add_child_autofree(m)
	return m


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "1"
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func test_a_hit_monster_cries_out_in_its_own_voice() -> void:
	_player(Vector3(0, 10, 0))
	for kind: StringName in [MonsterRules.SLIME, MonsterRules.GOBLIN, MonsterRules.MUMMY, MonsterRules.SCORPION]:
		var m := _monster(kind, Vector3(0, 10, 4))
		await wait_physics_frames(2)   # the player list is refreshed once per physics frame
		m._process(0.016)
		m.take_hit(1, Vector3(0, 10, 0), Vector3.ZERO)
		m._process(0.016)
		assert_eq(Audio.last_sound, VoiceRules.monster_hurt(kind), String(kind))



## M5 Task 2: the idle grunts now come from one chorus per device (test_monster_chorus.gd: near the camera, a few
## a minute; far ones quiet).
