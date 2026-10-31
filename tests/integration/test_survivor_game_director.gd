extends GutTest
## Survivor games on the host (spec §12.18), with stubs like the MonsterDirector tests. Build to Survive: a
## sheltered player is invisible to monsters (so never chased or hit), nights survived count at sunrise, a
## knock-out starts the run again and (solo) brings the morning, nights are fiercer outside, beds need a
## shelter. (Monster Hunter went into Monster Wave with owner feedback #44: test_arena_director.gd.)


const FLOOR := 10

var _time := DayCycle.NOON
var _now := 100.0
var _blocks := {}
var _set_times: Array[float] = []
var _toasts: Array[String] = []
var _paid: Array = []
var _scores_heard: Array = []
var _mode_before: StringName
var _gold_before := 0
var _me: Player


func before_each() -> void:
	_time = DayCycle.NOON
	_now = 100.0
	_blocks.clear()
	_set_times.clear()
	_toasts.clear()
	_paid.clear()
	_scores_heard.clear()
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 0
	Session.magic_feedback.connect(_on_toast)
	Session.hunt_paid.connect(_on_paid)
	Session.game_score_received.connect(_on_score)
	_me = _player(Vector3(0.5, FLOOR, 0.5))


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_toast)
	Session.hunt_paid.disconnect(_on_paid)
	Session.game_score_received.disconnect(_on_score)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Session.survivor_reset()


func _on_toast(text: String) -> void:
	_toasts.append(text)


func _on_paid(gold: int, combo: int) -> void:
	_paid.append([gold, combo])


func _on_score(score: Dictionary) -> void:
	_scores_heard.append(score)


func _block(p: Vector3i) -> int:
	if _blocks.has(p):
		return _blocks[p]
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _monsters() -> MonsterDirector:
	var d := MonsterDirector.new()
	d.name = "Monsters"
	d.player_positions = func() -> Array[Vector3]:
		var out: Array[Vector3] = []
		for p: Player in get_tree().get_nodes_in_group(&"players"):
			out.append(p.global_position)
		return out
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	d.lights_near = func(_p: Vector3) -> Array[Vector3i]: return [] as Array[Vector3i]
	d.home_beds = func() -> Array[Vector3i]: return [] as Array[Vector3i]
	d.time_of_day = func() -> float: return _time
	d.enabled = func() -> bool: return true
	d.block_at = _block
	d.rng.seed = 20260924
	add_child_autofree(d)
	return d


func _director(game: StringName, monsters: MonsterDirector = null) -> SurvivorGameDirector:
	var g := SurvivorGameDirector.new()
	g.name = "SurvivorGame"
	g.game = game
	g.time_of_day = func() -> float: return _time
	g.set_time = func(t: float) -> void:
		_set_times.append(t)
		_time = t
	g.now = func() -> float: return _now
	g.block_at = _block
	g.name_of = func(peer: int) -> String: return "P%d" % peer
	g.monsters = monsters if monsters else _monsters()
	g.rng.seed = 7
	add_child_autofree(g)
	g.start()
	return g


## A plank house around the feet (walls 2 out, 2 high, a roof above the head) with a doorway on +X.
func _house(feet: Vector3i, door: int = BlockIds.DOOR) -> void:
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			if absi(dx) == 2 or absi(dz) == 2:
				for dy in 2:
					_blocks[feet + Vector3i(dx, dy, dz)] = BlockIds.PLANKS
			_blocks[feet + Vector3i(dx, 2, dz)] = BlockIds.PLANKS
	for dy in 2:
		_blocks[feet + Vector3i(2, dy, 0)] = door


# --- Build to Survive ---

func test_a_player_in_a_closed_house_is_sheltered_and_invisible_to_monsters() -> void:
	var g := _director(SurvivorGames.BUILD)
	_house(Vector3i(0, FLOOR, 0))
	g.tick()
	assert_true(_me.sheltered)
	assert_eq(g.shelter_of(_me.peer_id), ShelterRules.SAFE)
	assert_eq(Monster.visibility_of(_me), 0.0, "monsters can't see them")
	for dy in 2:
		_blocks[Vector3i(2, FLOOR + dy, 0)] = BlockIds.DOOR_OPEN
	g.tick()
	assert_false(_me.sheltered, "the door is open")
	assert_eq(g.shelter_of(_me.peer_id), ShelterRules.GAP)
	assert_gt(Monster.visibility_of(_me), 0.0)


func test_a_monster_next_to_a_sheltered_player_never_sees_them() -> void:
	var d := _monsters()
	var g := _director(SurvivorGames.BUILD, d)
	_time = DayCycle.MIDNIGHT
	_house(Vector3i(0, FLOOR, 0))
	d.summon(MonsterRules.GOBLIN, 3, _me.global_position)
	var m := d.monsters()[0]
	m.global_position = _me.global_position + Vector3(1, 0, 0)   # even inside with them
	m.rotation.y = PI * 0.5
	g.tick()
	assert_null(m.perceive(), "a sheltered player is never seen, so never chased or hit")
	for dy in 2:
		_blocks[Vector3i(2, FLOOR + dy, 0)] = BlockIds.DOOR_OPEN
	g.tick()
	assert_true(Monster.visibility_of(_me) > 0.0)


func test_a_night_survived_counts_at_sunrise() -> void:
	var g := _director(SurvivorGames.BUILD)
	_time = DayCycle.SUNSET + 0.01
	g.tick()
	_time = DayCycle.SUNRISE + 0.001
	g.tick()
	assert_eq(g.record_of(_me.peer_id).nights, 1)
	assert_eq(g.record_of(_me.peer_id).best_nights, 1)
	assert_has(_toasts, BuildRules.morning_line(1, true))
	assert_eq(_scores_heard.back().nights, 1, "the player hears their score")
	assert_eq(g.scores["P1"].nights, 1, "kept by name (saved with the world)")


func test_a_knock_out_at_night_ends_the_run_and_solo_brings_the_morning() -> void:
	var g := _director(SurvivorGames.BUILD)
	g.scores["P1"] = {"nights": 4, "best_nights": 6}
	_time = DayCycle.MIDNIGHT
	g.tick()
	Session.knockout_received.emit(_me.peer_id, true)
	assert_eq(g.record_of(_me.peer_id).nights, 0)
	assert_eq(g.record_of(_me.peer_id).best_nights, 6)
	Session.knockout_respawned.emit(_me.peer_id, true)
	assert_eq(_set_times, [DayCycle.SUNRISE] as Array[float], "you wake at home in the morning")
	g.tick()
	assert_eq(g.record_of(_me.peer_id).nights, 0, "that night does not count")


func test_with_friends_the_night_goes_on_until_everyone_is_down() -> void:
	var g := _director(SurvivorGames.BUILD)
	_player(Vector3(30.5, FLOOR, 0.5), 5)
	_time = DayCycle.MIDNIGHT
	g.tick()
	Session.knockout_received.emit(_me.peer_id, true)
	Session.knockout_respawned.emit(_me.peer_id, true)
	assert_eq(_set_times, [] as Array[float], "a friend is still up")
	_time = DayCycle.SUNRISE + 0.001
	g.tick()
	assert_eq(g.record_of(5).nights, 1, "the friend made it")
	assert_eq(g.record_of(_me.peer_id).nights, 0)


func test_a_knock_out_by_day_changes_no_night() -> void:
	var g := _director(SurvivorGames.BUILD)
	g.scores["P1"] = {"nights": 2, "best_nights": 2}
	Session.knockout_received.emit(_me.peer_id, true)
	Session.knockout_respawned.emit(_me.peer_id, true)
	assert_eq(_set_times, [] as Array[float])
	assert_eq(g.record_of(_me.peer_id).nights, 0, "a knock-out ends the run whenever it comes")


func test_nights_are_fiercer_outside() -> void:
	var d := _monsters()
	_director(SurvivorGames.BUILD, d)
	assert_eq(d.per_player_cap, 14)
	assert_eq(d.level_bonus, 1)
	var c := _monsters()
	_director(SurvivorGames.CLASSIC, c)
	assert_eq(c.per_player_cap, MonsterRules.MAX_PER_PLAYER)
	assert_eq(c.level_bonus, 0)


func test_a_fiercer_night_brings_more_than_ten_near_a_player() -> void:
	var d := _monsters()
	_director(SurvivorGames.BUILD, d)
	_time = DayCycle.MIDNIGHT
	for i in 10:
		d.summon(MonsterRules.SLIME, 1, _me.global_position + Vector3(20, 0, 0))
	d.tick()
	assert_gt(d.monsters().size(), 10)
	for m in d.monsters():
		if m.wild:
			assert_gte(m.level, 2, "one level up (the spawn is near the world spawn: level 1 + 1, ±1)")


func test_a_bed_needs_a_shelter_in_build_to_survive() -> void:
	var g := _director(SurvivorGames.BUILD)
	assert_eq(g.sleep_refusal(_me.peer_id), "Build walls and a roof around your bed first!")
	_house(Vector3i(0, FLOOR, 0))
	assert_eq(g.sleep_refusal(_me.peer_id), "")
	var c := _director(SurvivorGames.CLASSIC)
	_blocks.clear()
	assert_eq(c.sleep_refusal(_me.peer_id), "", "Classic beds as before")


func test_classic_pays_coins_as_before() -> void:
	var d := _monsters()
	var g := _director(SurvivorGames.CLASSIC, d)
	g.tick()
	assert_eq(d.monsters().size(), 0, "nothing comes by day")
	d.summon(MonsterRules.GOBLIN, 2, _me.global_position)
	d.monsters()[0].take_hit(100, _me.global_position, Vector3.ZERO)
	assert_gt(d.coins().size(), 0, "coins as before")
	assert_eq(_paid.size(), 0)
