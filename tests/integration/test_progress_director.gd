extends GutTest
## M3 Task 12: the world's ProgressDirector (one per game): the pet's presents during active play only,
## new places explored, friends played with, the level-up celebration for this game's player only, the
## name tag's code, and the host's hooks (monsters beaten near players, waves and bosses won).


## Stand-ins for the host's directors: just their signals.
class Monsters:
	extends Node
	signal monster_defeated(kind: StringName, level: int, pos: Vector3)


class Waves:
	extends Node
	signal wave_ended(wave: int, result: StringName)


class Boss:
	extends Node
	signal fight_ended(won: bool, percent: int)


## Owner #45a: a boss director of another universe (BossDirector.boss_kind).
class DesertBoss:
	extends Boss
	var boss_kind := &"serpent"


var d: ProgressData
var me: Player
var hud: Hud
var director: ProgressDirector
var pet := [""]
var saves := [0]


func before_each() -> void:
	d = ProgressData.new()
	pet[0] = ""
	saves[0] = 0
	me = _player(multiplayer.get_unique_id(), Vector3(10, 20, 10))
	director = _director(true)


func after_each() -> void:
	Progress.end()
	Session.progress_reset()


func _player(peer: int, at: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.global_position = at
	p._spawned = true
	p.set_physics_process(false)
	return p


func _director(with_hud: bool) -> ProgressDirector:
	var dir := ProgressDirector.new()
	dir.data_override = d
	dir.player = me
	if with_hud:
		hud = Hud.new()
		add_child_autofree(hud)
		dir.hud = hud
	dir.pet_near = func() -> String: return pet[0]
	dir.save_profile = func() -> void: saves[0] += 1
	dir.set_process(false)   # the test ticks it by hand
	add_child_autofree(dir)
	return dir


## One second of play: the player walks a little (moving counts as playing).
func _walk(seconds: int, step := Vector3(0.5, 0, 0)) -> void:
	for i in seconds:
		me.global_position += step
		director.tick(1.0)


func _stand(seconds: int) -> void:
	for i in seconds:
		director.tick(1.0)


func test_counting_begins_with_the_world_and_ends_with_it() -> void:
	assert_true(Progress.is_counting())
	Progress.event(&"photo_taken")
	assert_eq(d.count(&"photo_taken"), 1)
	remove_child(director)
	assert_false(Progress.is_counting(), "leaving the world stops counting")
	director.free()


func test_a_pet_brings_a_present_after_active_play() -> void:
	pet[0] = "Rex"
	_walk(int(PresentRules.interval_s(0)) - 1)
	assert_false(d.present_waiting)
	_walk(1)
	assert_true(d.present_waiting)
	assert_string_contains(hud.banner.showing() + " ".join(hud.banner._queue.map(func(e: Array) -> String: return e[0])),
		"Rex brought you a present")


func test_no_present_while_the_child_is_away() -> void:
	pet[0] = "Rex"
	_walk(10)
	_stand(int(PresentRules.interval_s(0)) * 3)
	assert_false(d.present_waiting, "standing still for an hour is not playing")
	assert_almost_eq(d.present_s, 10.0 + PresentRules.IDLE_S, 1.01, "the clock stopped a minute after the last move")


func test_no_present_without_a_pet_near() -> void:
	_walk(int(PresentRules.interval_s(0)) + 10)
	assert_false(d.present_waiting)
	assert_eq(d.present_s, 0.0)


func test_no_present_while_asleep() -> void:
	pet[0] = "Rex"
	me.sleeping = true
	_walk(int(PresentRules.interval_s(0)) + 10)
	assert_false(d.present_waiting)
	me.sleeping = false


func test_a_new_place_counts_once_and_the_start_does_not() -> void:
	_walk(3)
	assert_eq(d.count(&"area_explored"), 0, "where the world started")
	me.global_position += Vector3(ProgressDirector.AREA, 0, 0)
	_walk(1)
	assert_eq(d.count(&"area_explored"), 1)
	me.global_position -= Vector3(ProgressDirector.AREA, 0, 0)
	_walk(1)
	me.global_position += Vector3(ProgressDirector.AREA, 0, 0)
	_walk(1)
	assert_eq(d.count(&"area_explored"), 1, "a place already seen this time")


func test_a_friend_counts_once() -> void:
	_player(7, Vector3(12, 20, 10))
	_walk(1)
	_walk(5)
	assert_eq(d.count(&"friend_played/player"), 1)


func test_bot_friends_count_once_when_one_joins_later() -> void:
	var old_bot := Node3D.new()
	old_bot.add_to_group(&"bot_friends")
	add_child_autofree(old_bot)
	_walk(1)
	assert_eq(d.count(&"friend_played"), 0, "friends already there when the world loaded")
	var new_bot := Node3D.new()
	new_bot.add_to_group(&"bot_friends")
	add_child_autofree(new_bot)
	_walk(2)
	assert_eq(d.count(&"friend_played/bot"), 1)
	var another := Node3D.new()
	another.add_to_group(&"bot_friends")
	add_child_autofree(another)
	_walk(2)
	assert_eq(d.count(&"friend_played/bot"), 1, "bot friends count once a session: BYE and add again is no XP farm")


func test_a_level_up_is_celebrated_here_and_the_tag_follows() -> void:
	Progress.event(&"boss_beaten")
	assert_eq(me.progress_tag, Progress.tag())
	assert_eq(me.progress_tag.get_slice(":", 0), "2")
	var texts := [hud.banner.showing()] + hud.banner._queue.map(func(e: Array) -> String: return e[0])
	assert_has(texts, "Level 2!")


func test_goals_and_badges_show_a_banner() -> void:
	Progress.pick_goal(2, &"tame_dog")
	Progress.event(&"animal_tamed/dog")
	var texts := [hud.banner.showing()] + hud.banner._queue.map(func(e: Array) -> String: return e[0])
	assert_has(texts, "Goal done: Tame a dog!")
	assert_has(texts, "New badge: First pet!")


func test_a_guests_game_saves_its_profile_when_it_matters() -> void:
	director.saves_profile = true
	Progress.event(&"animal_tamed/dog")
	assert_gt(saves[0], 0, "a badge is saved at once on a guest's game (the host saves with its world)")


func test_the_host_counts_monsters_waves_and_bosses() -> void:
	var monsters := Monsters.new()
	var waves := Waves.new()
	var boss := Boss.new()
	for n in [monsters, waves, boss]:
		add_child_autofree(n)
	director.watch_host(monsters, waves, boss)
	monsters.monster_defeated.emit(&"slime", 1, me.global_position + Vector3(3, 0, 0))
	monsters.monster_defeated.emit(&"goblin", 1, me.global_position + Vector3(300, 0, 0))
	assert_eq(d.count(&"monster_defeated/slime"), 1)
	assert_eq(d.count(&"monster_defeated/goblin"), 0, "far away")
	waves.wave_ended.emit(1, WaveRules.WON)
	waves.wave_ended.emit(2, WaveRules.KNOCKED_OUT)
	assert_eq(d.count(&"wave_won"), 1)
	boss.fight_ended.emit(false, 40)
	boss.fight_ended.emit(true, 0)
	assert_eq(d.count(&"boss_beaten/golem"), 1)


## Owner #45a: the boss beaten is the world's own (the Sand Serpent, not always "golem"), and Monster Wave's
## arena waves count as arena waves (and still as waves), in the universe they happen in.
func test_the_real_boss_and_the_arenas_waves_count() -> void:
	var waves := Waves.new()
	var boss := DesertBoss.new()
	for n in [waves, boss]:
		add_child_autofree(n)
	var u_before: Callable = Progress.universe
	Progress.universe = func() -> int: return 2
	director.watch_host(null, waves, boss, true)
	waves.wave_ended.emit(1, WaveRules.WON)
	boss.fight_ended.emit(true, 0)
	Progress.universe = u_before
	assert_eq(d.count(&"boss_beaten/serpent"), 1)
	assert_eq(d.count(&"boss_beaten/golem"), 0)
	assert_eq(d.count(&"wave_won/arena"), 1)
	assert_eq(d.count(&"wave_won"), 1)
	assert_eq(d.count_in(&"boss_beaten/serpent", 2), 1, "in the desert")
