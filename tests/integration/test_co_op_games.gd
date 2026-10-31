extends GutTest
## The co-op games in a world (M4 Wave 3, agent H; spec §17.5): hide-and-seek with players and bot
## friends, Storm Run and the team photo after a boss, run by the host's GamesDirector. Solo play
## (OfflineMultiplayerPeer): this game is the host; a second Player named "5" stands in for a guest whose
## requests arrive as Session's signals (the RPC path emits the same). Every start, find, look into a
## spot, star and photo is a request the host checks.

## Stone below GROUND, air above; hiding spots and walls are cells.
class FlatWorld:
	extends WorldService
	const GROUND := 10
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.STONE if pos.y < GROUND else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func spawn_column() -> Vector2i:
		return Vector2i.ZERO

	func surface_height(_x: int, _z: int) -> int:
		return GROUND - 1

	func find_standing_y(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return true


const STEP := 1.0 / 60.0
const G := FlatWorld.GROUND

var world: FlatWorld
var me: Player
var guest: Player
var bots: BotDirector
var games: GamesDirector
var told: Array = []              # [peer, text]
var saved_best: Array[int] = []
var photos: Array[Transform3D] = []
var puffs := 0
var _toasts: Array[String] = []
var _container: Node3D
var _session_world: WorldService
var _mode: StringName
var _style: String
var _stickers: Dictionary


func before_each() -> void:
	_session_world = Session.world
	_mode = Game.mode
	_style = str(Profile.data.settings.style)
	_stickers = Profile.data.stickers.duplicate()
	Profile.data.settings.style = "blocky"
	Game.mode = ModeRules.SANDBOX
	world = FlatWorld.new()
	autofree(world)
	Session.register_world(world)
	told.clear()
	saved_best.clear()
	photos.clear()
	puffs = 0
	_ground()


func after_each() -> void:
	Session.world = _session_world
	Game.mode = _mode
	Profile.data.settings.style = _style
	Profile.data.stickers = _stickers
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():   # the finds' dings and the stars' coins (DEVELOPMENT.md §8)
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _ground() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(300, 1, 300)
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = Vector3(0, G - 0.5, 0)


func _player(peer: int, pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	return p


## This game's player at the middle, the director, and `n` bot friends next to it.
func _setup(n_bots: int = 1) -> void:
	me = _player(multiplayer.get_unique_id(), Vector3(0.5, G, 0.5))
	_container = Node3D.new()
	add_child_autofree(_container)
	bots = BotDirector.new()
	bots.container = _container
	bots.world = world
	bots.spawn = func(data: Dictionary) -> Node:
		var b := BotFriend.new()
		b.setup(data)
		b.world = world
		_container.add_child(b)
		b.set_physics_process(false)
		return b
	add_child_autofree(bots)
	games = GamesDirector.new()
	games.name = "Games"
	games.world = world
	games.bot_list = bots.bots
	games.tell = func(peer: int, text: String) -> void: told.append([peer, text])
	games.save_best = func(best: int) -> void: saved_best.append(best)
	games.save_profile = func() -> void: pass
	games.take_photo = func(view: Transform3D) -> void: photos.append(view)
	games.monsters_away = func() -> void: puffs += 1
	games.find_spots = _spots_in
	games.local_player = me
	add_child_autofree(games)
	games.set_process(false)
	games.set_physics_process(false)
	await get_tree().physics_frame
	for i in n_bots:
		bots.add([BotRules.EXPLORER, BotRules.BUILDER, BotRules.FIGHTER][i])


## The hiding blocks of the stand-in world inside a box (the director's own search copies boxes).
func _spots_in(origin: Vector3i, size: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for cell: Vector3i in world.cells:
		var r := Vector3i(cell - origin)
		if r.x >= 0 and r.y >= 0 and r.z >= 0 and r.x < size.x and r.y < size.y and r.z < size.z \
				and BotGamePlans.HIDING_SPOTS.has(world.cells[cell]):
			out.append(cell)
	return out


func _bot() -> BotFriend:
	return bots.bots()[0]


func _key(b: BotFriend) -> String:
	return GameRules.bot_key(b.bot_name)


func _mine() -> String:
	return GameRules.player_key(me.peer_id)


## Runs the director (and every bot) for `seconds` of game time.
func _run(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		games._process(STEP)
		games._physics_process(STEP)
		for b in bots.bots():
			b._physics_process(STEP)
		t += STEP


func _on_toast(text: String) -> void:
	_toasts.append(text)


func _texts() -> Array[String]:
	var out: Array[String] = []
	for e: Array in told:
		out.append(str(e[1]))
	return out


# --- Starting ---

func test_hide_and_seek_needs_a_friend_and_starts_with_the_chosen_seeker() -> void:
	await _setup(0)
	Session.games_request_start(GameRules.HIDE_SEEK, "")
	assert_false(games.running(), "alone: no round")
	assert_has(_texts(), GameWords.refusal(GameRules.ALONE))
	bots.add(BotRules.EXPLORER)
	Session.games_request_start(GameRules.HIDE_SEEK, _key(_bot()))
	assert_true(games.running())
	assert_eq(games.kind, GameRules.HIDE_SEEK)
	assert_eq(games.hide.seekers, [_key(_bot())] as Array[String], "the child chose the bot")
	assert_true(games.hide.is_hiding(_mine()))
	assert_eq(games.hide.names[_key(_bot())], BotRules.chat_name(_bot().bot_name), "a bot is named as a bot")
	assert_eq(puffs, 1, "the wild monsters puff away")
	assert_has(_texts(), GameWords.seeker_is(BotRules.chat_name(_bot().bot_name)))
	Session.games_request_start(GameRules.STORM_RUN, "")
	assert_has(_texts(), GameWords.refusal(GameRules.RUNNING), "one round at a time")
	assert_eq(games.kind, GameRules.HIDE_SEEK)


func test_monsters_and_the_totem_wait_while_a_round_is_on() -> void:
	await _setup(1)
	var night := games.monsters_allowed(func() -> bool: return true)
	assert_true(night.call())
	var waves := WaveDirector.new()
	add_child_autofree(waves)
	var wave_words: Array[String] = []
	waves.game_on = games.running
	waves.tell = func(_peer: int, text: String) -> void: wave_words.append(text)
	Session.games_request_start(GameRules.HIDE_SEEK, _mine())
	assert_false(night.call(), "no night monsters during a round")
	assert_eq(waves.request_start(me.peer_id, 1), &"game", "the Totem starts no wave")
	assert_eq(waves.request_boss(me.peer_id), &"game", "nor the boss")
	assert_eq(wave_words[0], GameWords.WAVE_WAITS)
	games.busy = func() -> StringName: return GameRules.WAVE
	games.hide._end(HideSeekRound.ENDED)
	games._clear()
	assert_true(night.call(), "after the round they come again")
	Session.games_request_start(GameRules.STORM_RUN, "")
	assert_false(games.running(), "and no round starts during a wave")
	assert_has(_texts(), GameWords.refusal(GameRules.WAVE))


# --- Counting ---

func test_the_counting_seeker_holds_still_for_thirty_seconds() -> void:
	await _setup(1)
	Session.games_request_start(GameRules.HIDE_SEEK, _mine())
	assert_true(games.counting_here(), "the counting screen")
	assert_has(_texts(), GameWords.YOU_SEEK)
	var start := me.global_position
	games._physics_process(STEP)
	me.global_position += Vector3(4, 0, 0)
	games._physics_process(STEP)
	assert_eq(me.global_position, start, "no peeking, no walking")
	assert_false(games.seeking_here(), "taps on hiding spots still hide while counting")
	_run(HideSeekRound.COUNT_TIME + 0.1)
	assert_false(games.counting_here())
	assert_true(games.seeking_here(), "now a tap on a barrel looks inside it (GameTaps)")
	assert_eq(games.hide.phase, HideSeekRound.Phase.SEEKING)
	assert_has(_texts(), GameWords.SEEK_START)
	me.global_position += Vector3(4, 0, 0)
	games._physics_process(STEP)
	assert_ne(me.global_position, start, "seeking: free to go")


# --- Finding ---

func _seek_with_bot_hiding(at: Vector3) -> BotFriend:
	Session.games_request_start(GameRules.HIDE_SEEK, _mine())
	games.hide.advance(HideSeekRound.COUNT_TIME + 0.1)
	var b := _bot()
	b.game_brain = Callable()   # held where the test puts it
	b.global_position = at
	b.rotation.y = 0.0
	return b


func test_a_seeker_finds_a_hider_they_see_close_and_the_hider_joins_them() -> void:
	await _setup(1)
	var b := _seek_with_bot_hiding(Vector3(0.5, G, -4.5))
	Session.games_request_find(_key(b))
	assert_true(games.hide.is_hiding(_key(b)), "5 blocks away: not yet")
	b.global_position = Vector3(0.5, G, -2.0)
	Session.games_request_find(_key(b))
	assert_true(games.hide.is_seeker(_key(b)), "found: the bot seeks now")
	assert_has(_texts(), GameWords.you_found(BotRules.chat_name(b.bot_name)))


func test_never_through_a_wall_and_never_a_hidden_one() -> void:
	await _setup(1)
	var b := _seek_with_bot_hiding(Vector3(0.5, G, -2.0))
	for y in [G, G + 1, G + 2]:
		world.cells[Vector3i(0, y, -1)] = BlockIds.STONE
	Session.games_request_find(_key(b))
	assert_true(games.hide.is_hiding(_key(b)), "a wall between")
	world.cells.clear()
	world.cells[Vector3i(0, G, -2)] = BlockIds.BARREL
	b.game_set_pose(BotFriend.POSE_INSIDE, Vector3i(0, G, -2))
	Session.games_request_find(_key(b))
	assert_true(games.hide.is_hiding(_key(b)), "inside a barrel nobody sees you")
	assert_eq(b.game_pose, BotFriend.POSE_INSIDE)


func test_a_tap_on_a_hiding_spot_finds_whoever_is_inside() -> void:
	await _setup(1)
	var cell := Vector3i(0, G, -3)
	world.cells[cell] = BlockIds.BARREL
	world.cells[Vector3i(3, G, 0)] = BlockIds.CLOSET
	var b := _seek_with_bot_hiding(Vector3(0.5, G, -3.5))
	b.game_set_pose(BotFriend.POSE_INSIDE, cell)
	assert_eq(b.game_hidden_in, cell)
	me.global_position = Vector3(0.5, G, 20.5)
	Session.games_request_spot(cell)
	assert_has(_texts(), GameWords.CLOSER, "too far to look inside")
	assert_true(games.hide.is_hiding(_key(b)))
	me.global_position = Vector3(0.5, G, 0.5)
	Session.games_request_spot(Vector3i(3, G, 0))
	assert_has(_texts(), GameWords.NOBODY, "an empty closet")
	Session.games_request_spot(cell)
	assert_false(games.hide.is_hiding(_key(b)), "found in the barrel")
	assert_eq(b.game_pose, BotFriend.POSE_NONE, "and out of it")
	assert_eq(b.game_hidden_in, BotFriend.NO_SPOT)


func test_everyone_found_ends_the_round_with_a_sticker_for_every_child() -> void:
	await _setup(1)
	watch_signals(games)
	var before := int(Profile.data.stickers.get("hide_seek", 0))
	var b := _seek_with_bot_hiding(Vector3(0.5, G, -2.0))
	Session.games_request_find(_key(b))
	assert_eq(games.hide.phase, HideSeekRound.Phase.OVER)
	assert_false(games.running())
	assert_signal_emitted_with_parameters(games, "ended", [GameWords.end_hide(HideSeekRound.ALL_FOUND)])
	assert_eq(int(Profile.data.stickers.get("hide_seek", 0)), before + 1, "a sticker, never gold")
	assert_signal_emitted(games, "sticker_received")
	assert_false(b.game_brain.is_valid(), "the bot is a friend again")
	_run(GameRules.OVER_TIME + 0.1)
	assert_eq(games.kind, &"", "back to normal")
	assert_eq(games.line(), "")


func test_time_is_up_after_three_minutes_and_hints_come_before() -> void:
	await _setup(1)
	var b := _seek_with_bot_hiding(Vector3(20.5, G, 0.5))
	b.game_set_pose(BotFriend.POSE_CROUCH)
	_toasts.clear()
	Session.magic_feedback.connect(_on_toast)
	games._process(HideSeekRound.HINT_AFTER + 0.1)
	Session.magic_feedback.disconnect(_on_toast)
	assert_has(_toasts, GameWords.HINT, "a sparkle near the hider after two minutes")
	games._process(HideSeekRound.SEEK_TIME)
	assert_false(games.running())
	assert_eq(games.hide.result, HideSeekRound.TIME_UP)


# --- Bots ---

func test_a_hiding_bot_goes_into_a_free_barrel_within_thirty_blocks() -> void:
	await _setup(1)
	var cell := Vector3i(12, G, 0)
	world.cells[cell] = BlockIds.BARREL
	world.cells[Vector3i(40, G, 0)] = BlockIds.BARREL   # outside the area
	Session.games_request_start(GameRules.HIDE_SEEK, _mine())
	var b := _bot()
	_run(8.0)
	assert_eq(b.game_pose, BotFriend.POSE_INSIDE, "hidden inside")
	assert_eq(b.game_hidden_in, cell)
	await wait_process_frames(2)
	assert_false(b.visible, "nobody sees it (nor its name)")
	assert_true(games.hide.is_hiding(_key(b)))


func test_without_spots_a_bot_crouches_somewhere_away_from_the_seeker() -> void:
	await _setup(1)
	Session.games_request_start(GameRules.HIDE_SEEK, _mine())
	var b := _bot()
	_run(12.5)
	assert_eq(b.game_pose, BotFriend.POSE_CROUCH)
	var d := Vector2(b.global_position.x - 0.5, b.global_position.z - 0.5).length()
	assert_gte(d, BotGamePlans.MIN_HIDE - 1.0, "away from the counting spot")
	assert_lte(d, BotGamePlans.HIDE_RADIUS + 1.0)


func test_a_seeking_bot_is_fair_slower_than_a_child_and_finds_the_barrel_it_checks() -> void:
	await _setup(1)
	var cell := Vector3i(6, G, 6)
	world.cells[cell] = BlockIds.BARREL
	var b := _bot()
	b.global_position = Vector3(0.5, G, 0.5)
	Session.games_request_start(GameRules.HIDE_SEEK, _key(b))
	me.global_position = Vector3(6.5, G, 5.2)
	me.set_hidden(true, cell)
	_run(HideSeekRound.COUNT_TIME + 0.1)
	assert_eq(games.hide.phase, HideSeekRound.Phase.SEEKING)
	var fastest := 0.0
	var last := b.global_position
	var t := 0.0
	while games.hide.is_hiding(_mine()) and t < 90.0:
		_run(0.5)
		t += 0.5
		fastest = maxf(fastest, Vector2(b.global_position.x - last.x, b.global_position.z - last.z).length() / 0.5)
		last = b.global_position
	assert_false(games.hide.is_hiding(_mine()), "the bot looked into the barrel (%.1f s)" % t)
	assert_gt(t, 1.0, "it had to walk there and look")
	assert_lte(fastest, BotGamePlans.SEEK_SPEED + 0.6, "never faster than a seeking bot walks")
	assert_lt(BotGamePlans.SEEK_SPEED, Player.WALK_SPEED)


# --- Storm Run ---

func test_storm_run_brings_stars_the_team_collects_and_keeps_the_best() -> void:
	await _setup(1)
	games.storm_best = 0
	Session.games_request_start(GameRules.STORM_RUN, "")
	assert_true(games.running())
	assert_eq(puffs, 1)
	var spawned := games.spawned_stars
	_run(4.0)
	# Counted as they appear: the team's bot friend fetches stars meanwhile, so the ones still out can be only one
	# (a flake in a full suite, 2026-09-25).
	assert_gt(games.spawned_stars - spawned, 1, "stars appear")
	for id: int in games.storm.stars:
		var s: Vector3 = games.storm.stars[id]
		assert_lte(StormRun.outside_by(s, games.storm.circle_centre(), games.storm.circle_radius()), 0.0, "inside the circle")
	var id := games.storm.add_star(me.global_position + Vector3(0.5, 1.0, 0.0))
	games.stars.show_star(id, games.storm.stars[id])
	var score := games.storm.score
	Session.games_request_star(id)
	assert_eq(games.storm.score, score + 1, "one for the team")
	assert_false(games.stars.has_star(id))
	var far := games.storm.add_star(me.global_position + Vector3(9.0, 1.0, 0.0))
	Session.games_request_star(far)
	assert_true(games.storm.stars.has(far), "too far to take")
	var before := int(Profile.data.stickers.get("storm_run", 0))
	games._process(StormRun.TIME)
	assert_false(games.running())
	assert_eq(saved_best, [games.storm.best] as Array[int], "a new best is saved with the world")
	assert_eq(int(Profile.data.stickers.get("storm_run", 0)), before + 1)


func test_bots_fetch_stars_for_the_team() -> void:
	await _setup(1)
	Session.games_request_start(GameRules.STORM_RUN, "")
	var b := _bot()
	var at := b.global_position + Vector3(3.0, 1.0, 0.0)
	var id := games.storm.add_star(at)
	games.stars.show_star(id, at)
	var score := games.storm.score
	var t := 0.0
	while games.storm.stars.has(id) and t < 5.0:
		for s: int in games.storm.stars.keys():
			if s != id:
				games.storm.stars.erase(s)   # only this one
		for i in 6:
			b._physics_process(STEP)
		t += 0.1
	assert_false(games.storm.stars.has(id), "the bot took it")
	assert_eq(games.storm.score, score + 1)


func test_outside_the_circle_you_are_gently_pushed_back_in() -> void:
	await _setup(0)
	Session.games_request_start(GameRules.STORM_RUN, "")
	var c := games.storm.circle_centre()
	me.global_position = Vector3(c.x + 45.0, G, c.y)
	var before := StormRun.outside_by(me.global_position, c, games.storm.circle_radius())
	var hp := me.health.hp
	for i in 60:
		games._physics_process(STEP)
	var after := StormRun.outside_by(me.global_position, games.storm.circle_centre(), games.storm.circle_radius())
	assert_lt(after, before - 3.0, "back towards the circle")
	assert_eq(me.global_position.y, float(G), "never lifted or dropped")
	assert_eq(me.health.hp, hp, "no damage")


func test_a_ledge_in_the_way_gets_a_hop_like_walking_into_it() -> void:
	await _setup(0)
	Session.games_request_start(GameRules.STORM_RUN, "")
	var c := games.storm.circle_centre()
	var ledge := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 1, 40)
	shape.shape = box
	ledge.add_child(shape)
	add_child_autofree(ledge)
	ledge.global_position = Vector3(c.x + 43.5, G + 0.5, c.y)   # one block high, between the child and the circle
	me.global_position = Vector3(c.x + 45.0, G, c.y)
	await get_tree().physics_frame
	var hopped := false
	for i in 60:
		games._physics_process(STEP)
		hopped = hopped or me.velocity.y > 0.0
		me.velocity.y = 0.0
	assert_true(hopped, "pushed against a ledge: a hop, as the child's own steps do")


# --- Guests ---

func test_a_guests_requests_are_checked_by_the_host() -> void:
	await _setup(1)
	guest = _player(5, Vector3(30.5, G, 0.5))
	Session.games_start_requested.emit(5, GameRules.HIDE_SEEK, GameRules.player_key(5))
	assert_true(games.running(), "a guest may ask for a round")
	assert_eq(games.hide.seekers, [GameRules.player_key(5)] as Array[String])
	Session.games_start_requested.emit(5, GameRules.STORM_RUN, "")
	assert_has(told, [5, GameWords.refusal(GameRules.RUNNING)], "and hears why not")
	games.hide.advance(HideSeekRound.COUNT_TIME + 0.1)
	var b := _bot()
	b.game_brain = Callable()
	b.global_position = Vector3(0.5, G, -2.0)
	Session.games_find_requested.emit(5, _key(b))
	assert_true(games.hide.is_hiding(_key(b)), "the guest is 30 blocks away: they can't see it")
	Session.games_find_requested.emit(me.peer_id, _key(b))
	assert_true(games.hide.is_hiding(_key(b)), "a hider can't find anyone")
	Session.games_find_requested.emit(99, _key(b))
	assert_true(games.hide.is_hiding(_key(b)), "someone who isn't here")
	guest.global_position = Vector3(0.5, G, 0.5)
	Session.games_find_requested.emit(5, _key(b))
	assert_false(games.hide.is_hiding(_key(b)), "close and in sight: found")


func test_a_guests_copy_of_the_round_shows_the_same() -> void:
	await _setup(1)
	Session.games_request_start(GameRules.STORM_RUN, "")
	_run(3.0)
	var copy := GamesDirector.new()
	add_child_autofree(copy)
	copy.set_process(false)
	copy.set_physics_process(false)
	copy.receive_state(games.kind, games._state())
	assert_true(copy.running())
	assert_eq(copy.stars.count(), games.stars.count(), "the same stars")
	assert_eq(copy.storm.circle_centre(), games.storm.circle_centre(), "the same circle")
	copy._process(0.0)
	assert_eq(copy.line(), games.line(), "the same round line")
	copy.receive_state(&"tag", {})
	assert_eq(copy.kind, GameRules.STORM_RUN, "a game nobody knows changes nothing")
	var next := GamesDirector.new()
	add_child_autofree(next)
	next.set_process(false)
	next.set_physics_process(false)
	next._show_end(GameWords.end_hide(HideSeekRound.ALL_FOUND))   # the last round's end card, still up here
	next.receive_state(games.kind, games._state())                  # when the host's next round begins
	next._process(GameRules.OVER_TIME + 0.1)
	assert_true(next.running(), "a new round is never wiped by the last one's end")
	assert_eq(next.kind, GameRules.STORM_RUN)


# --- The team photo ---

func test_after_a_boss_everyone_near_lines_up_cheers_and_the_photo_is_taken() -> void:
	await _setup(2)
	var near := bots.bots()[0]
	var far := bots.bots()[1]
	near.global_position = Vector3(3.5, G, 2.5)
	far.global_position = Vector3(40.5, G, 0.5)
	watch_signals(games)
	Session.games_request_photo()
	assert_eq(photos.size(), 0, "no boss beaten: no photo")
	games.offer_photo()
	assert_signal_emitted_with_parameters(games, "photo_offer_changed", [true])
	assert_true(games.photo_offered())
	me.avatar.rotation.y = 0.5
	Session.games_request_photo()
	var spots: Dictionary = games._photo.spots
	assert_eq(spots.size(), 2, "me and the friend near me; not the one 40 blocks away")
	assert_true(spots.has(_mine()) and spots.has(_key(near)))
	assert_false(games.photo_offered(), "the button goes")
	assert_eq(me.global_position, spots[_mine()], "lined up")
	assert_almost_eq(me.avatar.rotation.y, 0.5, 0.001, "facing the camera")
	assert_eq(near.global_position, spots[_key(near)])
	assert_almost_eq(me.global_position.distance_to(near.global_position), TeamPhoto.SPACING, 0.01, "side by side")
	games._process(TeamPhoto.EMOTE_AT + 0.01)
	assert_eq(me.avatar.emote(), TeamPhoto.EMOTE, "everyone cheers")
	assert_eq(near.avatar.emote(), TeamPhoto.EMOTE)
	assert_eq(photos.size(), 0)
	games._process(TeamPhoto.SHOT_AT - TeamPhoto.EMOTE_AT)
	assert_eq(photos.size(), 1, "the shot, while they cheer")
	var view: Transform3D = photos[0]
	var forward := Basis(Vector3.UP, 0.5) * Vector3.FORWARD
	assert_gt((view.origin - me.global_position).dot(forward), 2.0, "the camera stands in front of the line")
	Session.games_request_photo()
	assert_eq(photos.size(), 1, "one photo per boss")


func test_the_photo_offer_lasts_twenty_seconds() -> void:
	await _setup(0)
	watch_signals(games)
	games.offer_photo()
	games._process(TeamPhoto.OFFER_TIME + 0.1)
	assert_false(games.photo_offered())
	assert_signal_emitted_with_parameters(games, "photo_offer_changed", [false])
	games._photo_offered_at -= TeamPhoto.OFFER_TIME + 1.0   # the host's clock moved on too
	Session.games_request_photo()
	assert_true(games._photo.is_empty(), "too late")


# --- Saves ---

func test_the_best_storm_score_is_kept_with_the_world() -> void:
	var m := WorldMeta.new()
	m.storm_best = 23
	assert_eq(WorldMeta.from_json(m.to_json()).storm_best, 23)
	assert_eq(WorldMeta.from_json('{"storm_best": -4}').storm_best, 0)
	assert_eq(WorldMeta.from_json('{"storm_best": "x"}').storm_best, 0)
	assert_eq(WorldMeta.from_json("{}").storm_best, 0)
