extends GutTest
## Helping a knocked-out teammate up (M4 Wave 2, Agent E; spec §17.5): the host's KnockoutDirector
## with two real players. A friend near makes the knocked-out player wait (GET UP goes at once); a
## teammate who holds HELP UP within reach for 3 s helps them up on the spot with full hearts and
## both cheer; letting go or walking away stops it; only a knocked-out teammate still down, never
## one already getting up; a knocked-out helper can't; a wave counts a helped player as standing.

const SPOT := Vector3(3.5, 10.0, -4.5)

var world: WorldService
var me: Player          # this game's player (the host, peer 1)
var pip: Player         # a guest, peer 7
var director: KnockoutDirector
var _mode_before: StringName
var _gold_before := 0
var _revived: Array = []


static func _floor(cell: Vector3i) -> int:
	return BlockIds.STONE if cell.y <= 9 else BlockIds.AIR


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	Game.mode = ModeRules.SURVIVOR
	_revived.clear()
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	me = _player(str(multiplayer.get_unique_id()), SPOT + Vector3(2, 0, 0))
	pip = _player("7", SPOT)
	director = KnockoutDirector.new()
	director.name = "Knockout"
	director.block_at = _floor
	director.name_of = func(peer_id: int) -> String: return "Mia" if peer_id == me.peer_id else "Pip"
	add_child_autofree(director)
	director.setup_local(me, null)
	director.revived.connect(func(friend: int, helper: int) -> void: _revived.append([friend, helper]))
	await get_tree().physics_frame


func after_each() -> void:
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Session.survivor_reset()


func _player(node_name: String, at: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = node_name
	p.world = world
	add_child_autofree(p)
	p.viewer.free()   # no streaming
	p.set_physics_process(false)
	p.global_position = at
	return p


func _knock_out(p: Player) -> void:
	Session.hurt_player(p.peer_id, Health.MAX_HP + 5, Vector3(9, 9, 9))


func _hold(seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		director.advance(0.1)
		t += 0.1


# --- Waiting for help ---

func test_a_knocked_out_player_waits_when_a_friend_is_near() -> void:
	_knock_out(pip)
	assert_true(pip.knocked_out)
	assert_true(director.is_waiting(pip.peer_id), "Mia is close: she can help")
	_hold(KnockoutRules.KO_TIME + 0.5)
	assert_eq(pip.health.hp, 0, "still down, waiting for a friend")
	_hold(ReviveRules.WAIT_TIME)
	assert_eq(pip.health.hp, Health.MAX_HP, "then up as before")
	assert_false(director.is_waiting(pip.peer_id))


func test_alone_nobody_waits() -> void:
	me.global_position = SPOT + Vector3(ReviveRules.CALL_DISTANCE + 5, 0, 0)
	_knock_out(pip)
	assert_false(director.is_waiting(pip.peer_id))
	_hold(KnockoutRules.KO_TIME + 0.2)
	assert_eq(pip.health.hp, Health.MAX_HP, "up after the usual moment")


func test_get_up_goes_at_once() -> void:
	_knock_out(pip)
	director.request_get_up(pip.peer_id)
	director.advance(0.1)
	assert_eq(pip.health.hp, Health.MAX_HP)
	assert_false(pip.knocked_out)


# --- Helping up ---

func test_holding_help_up_near_them_for_3_seconds_helps_them_up_on_the_spot() -> void:
	watch_signals(Session)
	_knock_out(pip)
	director.request_revive(me.peer_id, pip.peer_id, true)
	assert_eq(director.helper_of(pip.peer_id), me.peer_id)
	_hold(2.9)
	assert_eq(pip.health.hp, 0, "not yet")
	_hold(0.2)
	assert_eq(pip.health.hp, Health.MAX_HP, "full hearts")
	assert_false(pip.knocked_out, "standing again")
	assert_true(pip.health.is_protected())
	assert_eq(_revived, [[pip.peer_id, me.peer_id]])
	assert_signal_emitted_with_parameters(Session, "knockout_respawned", [pip.peer_id, false])   # on the spot, not at home
	assert_true(director.cheered.has(pip.peer_id) and director.cheered.has(me.peer_id), "both cheer")
	assert_eq(director.helper_of(pip.peer_id), 0)


func test_letting_go_stops_and_starts_over() -> void:
	_knock_out(pip)
	director.request_revive(me.peer_id, pip.peer_id, true)
	_hold(2.0)
	director.request_revive(me.peer_id, pip.peer_id, false)
	assert_eq(director.helper_of(pip.peer_id), 0)
	director.request_revive(me.peer_id, pip.peer_id, true)
	_hold(2.0)
	assert_eq(pip.health.hp, 0, "the ring starts over")
	_hold(1.1)
	assert_eq(pip.health.hp, Health.MAX_HP)


func test_walking_away_stops_it() -> void:
	_knock_out(pip)
	director.request_revive(me.peer_id, pip.peer_id, true)
	_hold(1.0)
	me.global_position = SPOT + Vector3(ReviveRules.REACH + 1.0, 0, 0)
	_hold(0.1)
	assert_eq(director.helper_of(pip.peer_id), 0, "out of reach")
	_hold(3.0)
	assert_eq(pip.health.hp, 0)


func test_only_a_knocked_out_teammate_can_be_helped() -> void:
	director.request_revive(me.peer_id, pip.peer_id, true)
	assert_eq(director.helper_of(pip.peer_id), 0, "Pip is up")
	_knock_out(pip)
	director.request_revive(pip.peer_id, pip.peer_id, true)
	assert_eq(director.helper_of(pip.peer_id), 0, "not yourself")


func test_not_once_they_are_getting_up_and_protected() -> void:
	me.global_position = SPOT + Vector3(ReviveRules.CALL_DISTANCE + 5, 0, 0)   # nobody near: up after the usual moment
	_knock_out(pip)
	_hold(KnockoutRules.KO_TIME + 0.1)
	assert_true(pip.health.is_protected())
	me.global_position = SPOT + Vector3(1, 0, 0)
	director.request_revive(me.peer_id, pip.peer_id, true)
	assert_eq(director.helper_of(pip.peer_id), 0)


func test_a_knocked_out_helper_cannot_help() -> void:
	_knock_out(pip)
	_knock_out(me)
	director.request_revive(me.peer_id, pip.peer_id, true)
	assert_eq(director.helper_of(pip.peer_id), 0)


func test_the_helper_hears_why_not_when_too_far() -> void:
	var told: Array = []
	var hear := func(t: String) -> void: told.append(t)
	Session.magic_feedback.connect(hear)
	_knock_out(pip)
	me.global_position = SPOT + Vector3(ReviveRules.REACH + 2.0, 0, 0)
	director.request_revive(me.peer_id, pip.peer_id, true)
	Session.magic_feedback.disconnect(hear)
	assert_eq(told, [ReviveRules.refusal_message(ReviveRules.TOO_FAR)])


func test_sandbox_players_can_be_helped_up_too() -> void:
	Game.mode = ModeRules.SANDBOX
	_knock_out(pip)
	assert_true(director.is_waiting(pip.peer_id))
	director.request_revive(me.peer_id, pip.peer_id, true)
	_hold(3.1)
	assert_eq(pip.health.hp, Health.MAX_HP)


# --- Waves ---

func test_a_wave_counts_a_helped_player_as_standing() -> void:
	var w := WaveDirector.new()
	add_child_autofree(w)
	w.set_process(false)
	w.phase = WaveDirector.Phase.RUNNING
	_knock_out(pip)
	assert_true(w._knocked.has(pip.peer_id))
	director.request_revive(me.peer_id, pip.peer_id, true)
	_hold(3.1)
	assert_false(w._knocked.has(pip.peer_id), "back in the fight: paid if the wave is won")
