class_name GamesDirector
extends Node
## The co-op games in a world (M4 Wave 3, agent H; spec §17.5): hide-and-seek, Storm Run and the team
## photo after a boss. The sandbox adds one on every peer, named "Games" (its RPCs line up).
## Host: checks every request (Session section "M4 H": a start, a find, a look into a hiding spot, a star,
## the photo), runs the round (HideSeekRound, StormRun: pure rules in core/games/), steers the bot friends
## (their game_brain: hide, seek, fetch stars, line up), keeps monsters and the Totem quiet meanwhile
## (monsters_allowed, WaveDirector.game_on), gives everyone who played the game's sticker and keeps
## Storm Run's best, and tells every game what happened.
## Every game: keeps a copy of the round (its clock runs here too), shows the HUD's round line, the
## glowing circle (GameRing) and the stars (StarPool), and moves only its own player: holding the counting
## seeker still, pushing it gently back into the circle or the play area, looking for hiders as a seeker
## and touching stars (each a request to the host), lining up for the team photo and taking it.
## World access is injected (world, bot_list, busy, ...), so tests use stubs.

## Every game: the HUD's round line ("" = no round).
signal line_changed(text: String)
## Every game: a round ended (the end card's words).
signal ended(text: String)
## This game's child got the round's sticker (the words to show).
signal sticker_received(text: String)
## Every game: the TEAM PHOTO button shows (true) or goes.
signal photo_offer_changed(open: bool)
## This game took its team photo.
signal photo_taken

const TICK := 0.25                # host: bot seekers look; players and bots who left leave the round
const LOOK_EVERY := 0.2           # every game: a seeking player looks for hiders
const ASK_AGAIN_MS := 1000        # the same hider or star is asked for at most this often
const CLOCK_SYNC := 5.0           # host: the state again, so every game's clock stays in step
const SCAN_SIZE := 16             # hiding spots are looked for one 16³ box at a time ...
const SCAN_PER_FRAME := 1         # ... one a frame, about 1 s in all (a copy took up to 8 ms at load 40)
const SCAN_DEPTH := 12            # blocks above and below the counting spot
const HIDE_GIVE_UP := 12.0        # a bot that can't reach its spot hides where it is
const WALK_GIVE_UP := 15.0        # a seeking bot that can't reach a spot tries the next
const OPEN_STOPS := 6             # open places a seeking bot also checks
const HINT_SPREAD := 2.5
const STAR_TRIES := 6             # spots tried for a new star
const STAR_CLIMB := 12.0          # a star's ground at most this far above or below where the run began
const PUSH_TOAST := 4.0           # seconds between "back inside" toasts
const HINT_COLOR := Color("fff38a")
const FOUND_COLOR := Color("7fe0ff")

# Host side, injected by the sandbox (tests use stubs).
var world: WorldService
var bot_list: Callable = func() -> Array: return []           # () -> Array of BotFriend
var busy: Callable = func() -> StringName: return &""         # &"wave" / &"boss" while one is on
var monsters_away: Callable = func() -> void: pass            # every wild monster puffs away
var storm_best := 0                                           # the world's best (WorldMeta.storm_best)
var save_best: Callable = func(_best: int) -> void: pass
var tell: Callable = _tell                                    # (peer, text): a toast for that player
var name_of: Callable = _name_of                              # (peer) -> the name everyone sees
## (origin: Vector3i, size: Vector3i) -> Array[Vector3i]: the hiding blocks in a box.
var find_spots: Callable = _find_spots
var rng := RandomNumberGenerator.new()

# Every game.
var local_player: Player
var save_profile: Callable = func() -> void: Profile.save()
## (view: Transform3D) -> void: photo mode takes the team photo from there (PhotoMode.take_team_photo).
var take_photo: Callable = func(_view: Transform3D) -> void: pass
var fov := 70.0

var kind: StringName = &""        # the round on or just over (&"" = none)
var hide := HideSeekRound.new()
var storm := StormRun.new()
var ground_y := 0.0               # the ring stands on this height
var ring := GameRing.new()
var stars := StarPool.new()

var _over_t := 0.0
var _tick_t := 0.0
var _look_t := 0.0
var _clock_t := 0.0
var _line := ""
var _asked := {}                  # hider key or "s<star id>" -> msec
var _pin := Vector3.INF
var _pushed_at := -INF
var _players_in: Array[String] = []   # host: every player who played this round (their stickers)
var _spots := {}                  # host: Vector3i -> block id, hiding spots near the counting spot
var _scan: Array[Vector3i] = []   # host: boxes still to look at
var _plans := {}                  # host: bot key -> its plan
var _photo_offered_at := -1.0     # host
var _offer_t := 0.0               # every game: seconds left of the TEAM PHOTO offer
var _photo := {}                  # every game: the line-up on now
var _photo_t := 0.0
var _photo_step := 0
var spawned_stars := 0            # host: stars this game put out (the smoke run's count)


func _init() -> void:
	rng.randomize()


## Owner #101 (P4): a VR teleport is refused while a round is on (the seeker holds still, the storm is outrun on foot).
func refuses_teleport(_p: Player, _at: Vector3) -> bool:
	return running()


func _ready() -> void:
	add_to_group(&"games_director")
	add_to_group(Player.TELEPORT_RULES)   # owner #101 (P4)
	ring.name = "Ring"
	add_child(ring)
	stars.name = "Stars"
	add_child(stars)
	# A LAN guest's sandbox makes this before it joins, so every handler checks is_host() itself.
	Session.games_start_requested.connect(_on_start_requested)
	Session.games_stop_requested.connect(_on_stop_requested)
	Session.games_find_requested.connect(_on_find_requested)
	Session.games_spot_requested.connect(_on_spot_requested)
	Session.games_star_requested.connect(_on_star_requested)
	Session.games_photo_requested.connect(_on_photo_requested)
	Session.client_ready.connect(_on_client_ready)
	Session.peer_left.connect(_on_peer_left)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## A round is on (not over): no monsters come and the Totem waits.
func running() -> bool:
	if kind == GameRules.HIDE_SEEK:
		return hide.phase == HideSeekRound.Phase.COUNTING or hide.phase == HideSeekRound.Phase.SEEKING
	return kind == GameRules.STORM_RUN and storm.running()


## The night monsters' switch (MonsterDirector.enabled) with the games in: none while a round is on.
func monsters_allowed(enabled: Callable) -> Callable:
	return func() -> bool: return bool(enabled.call()) and not running()


func my_key() -> String:
	return GameRules.player_key(multiplayer.get_unique_id())


## The GAMES page's list of who can seek: {key: name} of every player and bot friend here.
func participant_names() -> Dictionary:
	var out := {}
	for k in _participants():
		out[k] = _display_name(k)
	return out


# --- Who plays ---------------------------------------------------------------------------------------

func _participants() -> Array[String]:
	var out: Array[String] = []
	var peers: Array[int] = []
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and p.is_spawned() and not p.is_queued_for_deletion():
			peers.append(p.peer_id)
	peers.sort()
	for id in peers:
		out.append(GameRules.player_key(id))
	for b in _bots():
		if not b.knocked_out:
			out.append(GameRules.bot_key(b.bot_name))
	return out


func _bots() -> Array[BotFriend]:
	var out: Array[BotFriend] = []
	var list: Array = bot_list.call() if Session.is_host() else get_tree().get_nodes_in_group(&"bot_friends")
	for b: Variant in list:
		if b is BotFriend and is_instance_valid(b) and not (b as BotFriend).is_queued_for_deletion():
			out.append(b)
	return out


func _bot(key: String) -> BotFriend:
	var bot_name := GameRules.bot_of(key)
	if bot_name == "":
		return null
	for b in _bots():
		if b.bot_name == bot_name:
			return b
	return null


func _player(key: String) -> Player:
	var peer := GameRules.peer_of(key)
	return Session._player_for_peer(peer) if peer != 0 else null


func _body(key: String) -> Node3D:
	var p := _player(key)
	return p if p else _bot(key)


func _display_name(key: String) -> String:
	if GameRules.is_bot(key):
		return BotRules.chat_name(GameRules.bot_of(key))
	return str(name_of.call(GameRules.peer_of(key)))


func _name_of(peer: int) -> String:
	if peer == multiplayer.get_unique_id():
		return str(Profile.data.username) if str(Profile.data.username) != "" else "Player"
	return str(Session.chat_names.get(peer, "Friend"))


func _tell(peer: int, text: String) -> void:
	Session.send_feedback(peer, text)


## Every player in the round hears `text` (a toast); `words` (key -> text) gives some their own.
func _tell_players(keys: Array[String], text: String, words: Dictionary = {}) -> void:
	for k in keys:
		var peer := GameRules.peer_of(k)
		if peer != 0 and Session._player_for_peer(peer):
			var t := str(words.get(k, text))
			if t != "":
				tell.call(peer, t)


func _is_blocking(cell: Vector3i) -> bool:
	return world != null and StealthRules.blocks_sight(world.get_block(cell))


func _is_solid(cell: Vector3i) -> bool:
	return world != null and BlockIds.is_solid(world.get_block(cell))


func _block(cell: Vector3i) -> int:
	return world.get_block(cell) if world else BlockIds.AIR


# --- Host: starting and stopping ---------------------------------------------------------------------

func _on_start_requested(peer_id: int, k: StringName, seeker: String) -> void:
	if not Session.is_host():
		return
	var asker := Session._player_for_peer(peer_id)
	if asker == null or not asker.is_spawned():
		return
	var keys := _participants()
	var why := GameRules.start_refusal(k, running(), busy.call(), keys.size())
	if why != &"":
		var text := GameWords.refusal(why)
		if text != "":
			tell.call(peer_id, text)
		return
	if k == GameRules.HIDE_SEEK:
		start_hide_seek(keys, seeker)
	else:
		start_storm(asker.global_position)


## Host: a round of hide-and-seek with everyone in `keys`; `choice` seeks ("" or not playing: random).
func start_hide_seek(keys: Array[String], choice: String = "") -> bool:
	var seeker := HideSeekRound.pick_seeker(keys, choice, rng.randi())
	var body := _body(seeker)
	if body == null:
		return false
	var r := HideSeekRound.new()
	if not r.start(keys, seeker, body.global_position):
		return false
	for k in keys:
		r.names[k] = _display_name(k)
	_begin(GameRules.HIDE_SEEK, r.base.y)
	hide = r
	_players_in = _only_players(keys)
	_start_scan(r.base)
	_broadcast()
	var words := {seeker: GameWords.YOU_SEEK}
	_tell_players(_players_in, GameWords.seeker_is(str(r.names[seeker])), words)
	var b := _bot(seeker)
	if b:
		Session.bot_say(b.bot_name, GameWords.BOT_COUNTING)
	return true


## Host: Storm Run around `at` (the one who asked) with every player and bot friend.
func start_storm(at: Vector3) -> bool:
	if not at.is_finite():
		return false
	var r := StormRun.new()
	r.start(StormRun.make_waypoints(Vector2(at.x, at.z), rng.randi(), _good_ground.bind(at.y)))
	r.best = storm_best
	_begin(GameRules.STORM_RUN, at.y)
	storm = r
	_players_in = _only_players(_participants())
	_broadcast()
	_tell_players(_players_in, GameWords.STORM_START)
	return true


func _begin(k: StringName, y: float) -> void:
	kind = k
	ground_y = y
	hide = HideSeekRound.new()   # the last round's copies go (the new one is set right after)
	storm = StormRun.new()
	_over_t = 0.0
	_clock_t = CLOCK_SYNC
	_asked.clear()
	_plans.clear()
	stars.clear()
	monsters_away.call()
	for b in _bots():
		b.game_brain = _bot_decide


func _only_players(keys: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for k in keys:
		if not GameRules.is_bot(k):
			out.append(k)
	return out


## Can the storm's centre go to `p` (flat)? Ground to stand on near `y`, not water, not a cliff.
func _good_ground(p: Vector2, y: float) -> bool:
	if world == null:
		return false
	var stand := BossRules.stand_y(p.x, p.y, y, world.get_block)
	var below := Vector3i(floori(p.x), floori(stand) - 1, floori(p.y))
	return absf(stand - y) <= 8.0 and BlockIds.is_solid(world.get_block(below)) and world.get_block(below) != BlockIds.WATER


func _on_stop_requested(peer_id: int) -> void:
	if Session.is_host() and running() and Session._player_for_peer(peer_id) != null:
		if kind == GameRules.HIDE_SEEK:
			hide._end(HideSeekRound.ENDED)
		else:
			storm.advance(StormRun.TIME)
		_end_round()


## Host: the round is over. Everyone who played gets the sticker; bots go back to being friends.
func _end_round() -> void:
	var text := ""
	if kind == GameRules.HIDE_SEEK:
		text = GameWords.end_hide(hide.result)
	else:
		text = GameWords.end_storm(storm.score, storm.new_best())
		if storm.best > storm_best:
			storm_best = storm.best
			save_best.call(storm_best)
	_release_bots()
	_broadcast()
	_show_end(text)
	if not multiplayer.get_peers().is_empty():
		_rpc_end.rpc(text)
	for k in _players_in:
		var peer := GameRules.peer_of(k)
		if peer == multiplayer.get_unique_id():
			_receive_sticker(String(kind))
		elif multiplayer.get_peers().has(peer):
			_rpc_sticker.rpc_id(peer, String(kind))


func _release_bots() -> void:
	_plans.clear()
	for b in _bots():
		if _photo.is_empty():
			b.game_brain = Callable()
		b.game_set_pose(BotFriend.POSE_NONE)
		b.game_hold()


# --- Every game: the round's state ---------------------------------------------------------------

func _state() -> Dictionary:
	var d := hide.to_state() if kind == GameRules.HIDE_SEEK else storm.to_state()
	d.ground = ground_y
	return d


## Host: every game gets the round's state.
func _broadcast() -> void:
	_clock_t = CLOCK_SYNC
	if kind != &"" and not multiplayer.get_peers().is_empty():
		_rpc_state.rpc(String(kind), _state())
	_update_line()


@rpc("authority", "call_remote", "reliable")
func _rpc_state(k: String, data: Dictionary) -> void:
	receive_state(StringName(k), data)


## A guest's copy of the host's round.
func receive_state(k: StringName, data: Dictionary) -> void:
	if not GameRules.valid_kind(k):
		return
	kind = k
	ground_y = float(data.get("ground", 0.0)) if typeof(data.get("ground")) in [TYPE_INT, TYPE_FLOAT] else 0.0
	if k == GameRules.HIDE_SEEK:
		hide = HideSeekRound.from_state(data)
		storm = StormRun.new()
	else:
		storm = StormRun.from_state(data)
		hide = HideSeekRound.new()
		stars.clear()
		for id: int in storm.stars:
			stars.show_star(id, storm.stars[id])
	if running():
		_over_t = 0.0   # a new round: the last one's end (still shown here, its message came later) is over
	_update_line()


@rpc("authority", "call_remote", "reliable")
func _rpc_end(text: String) -> void:
	_show_end(text)


func _show_end(text: String) -> void:
	_over_t = GameRules.OVER_TIME
	stars.clear()
	ring.hide_circle()
	ended.emit(text)
	_update_line()


@rpc("authority", "call_remote", "reliable")
func _rpc_sticker(k: String) -> void:
	_receive_sticker(k)


## This game's child gets the round's sticker (kept in the profile, saved at once).
func _receive_sticker(k: String) -> void:
	var n := Profile.data.add_sticker(StringName(k))
	if n <= 0:
		return
	save_profile.call()
	sticker_received.emit(GameWords.sticker(StringName(k), n))


## Host: a guest who joins mid-round sees it (and plays: hides while counting, else seeks); the TEAM
## PHOTO offer too.
func _on_client_ready(peer_id: int) -> void:
	if not Session.is_host():
		return
	if running():
		var key := GameRules.player_key(peer_id)
		if kind == GameRules.HIDE_SEEK:
			hide.join(key)
			hide.names[key] = _display_name(key)
		if not _players_in.has(key):
			_players_in.append(key)
		_broadcast()
	if TeamPhoto.offer_open(_now(), _photo_offered_at):
		_rpc_photo_offer.rpc_id(peer_id, TeamPhoto.OFFER_TIME - (_now() - _photo_offered_at))


func _on_peer_left(peer_id: int) -> void:
	if not Session.is_host():
		return
	var key := GameRules.player_key(peer_id)
	_players_in.erase(key)
	if kind == GameRules.HIDE_SEEK and running() and hide.is_playing(key):
		hide.leave(key)
		_after_change()


## Host: after a find or a leave, the round goes on or ends.
func _after_change() -> void:
	if kind == GameRules.HIDE_SEEK and hide.phase == HideSeekRound.Phase.OVER:
		_end_round()
	else:
		_broadcast()


# --- Every game: the clock, the line, the ring --------------------------------------------------

func _process(delta: float) -> void:
	_photo_process(delta)
	if kind == &"":
		return
	if _over_t > 0.0:
		_over_t -= delta
		if _over_t <= 0.0:
			_clear()
		return
	if not running():
		_clear()   # a copy that ended here before the host's end came (or a stale one)
		return
	var host := Session.is_host()
	if kind == GameRules.HIDE_SEEK:
		var events := hide.advance(delta)
		if host:
			_hide_events(events)
	elif kind == GameRules.STORM_RUN:
		var step := storm.advance(delta)
		for id: int in step.gone:
			stars.hide_star(id, false)
		if host:
			_storm_step(step)
	if host and kind != &"" and _over_t <= 0.0:
		_scan_step()
		_clock_t -= delta
		if _clock_t <= 0.0:
			_broadcast()
	_update_ring()
	_update_line()


## The round is over and its end has been shown: back to normal.
func _clear() -> void:
	kind = &""
	_over_t = 0.0
	hide = HideSeekRound.new()
	storm = StormRun.new()
	stars.clear()
	ring.hide_circle()
	_pin = Vector3.INF
	_update_line()


func _update_ring() -> void:
	if kind == GameRules.STORM_RUN and storm.running():
		ring.show_circle(storm.circle_centre(), ground_y, storm.circle_radius(), GameRing.STORM_TINT)
	elif kind == GameRules.HIDE_SEEK and running():
		ring.show_circle(Vector2(hide.base.x, hide.base.z), ground_y, HideSeekRound.AREA_RADIUS, GameRing.AREA_TINT)
	else:
		ring.hide_circle()


func _update_line() -> void:
	var text := ""
	if _over_t > 0.0:
		text = "Great game!"
	elif kind == GameRules.HIDE_SEEK:
		text = GameWords.hide_line(hide, my_key())
	elif kind == GameRules.STORM_RUN:
		text = GameWords.storm_line(storm)
	if text != _line:
		_line = text
		line_changed.emit(text)


## The HUD's round line now.
func line() -> String:
	return _line


## Is this game's player a seeker now (its taps on hiding spots look inside them: GameTaps)?
func seeking_here() -> bool:
	return kind == GameRules.HIDE_SEEK and _over_t <= 0.0 and hide.phase == HideSeekRound.Phase.SEEKING \
		and hide.is_seeker(my_key())


## Is this game's player the seeker counting right now (the counting screen)?
func counting_here() -> bool:
	return kind == GameRules.HIDE_SEEK and _over_t <= 0.0 and hide.phase == HideSeekRound.Phase.COUNTING \
		and not hide.seekers.is_empty() and hide.seekers[0] == my_key()


# --- Every game: this game's player ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var me := local_player
	if is_instance_valid(me) and me.is_spawned():
		_local_player_step(me, delta)
	if Session.is_host() and kind != &"" and _over_t <= 0.0:
		_tick_t -= delta
		if _tick_t <= 0.0:
			_tick_t = TICK
			_host_tick()


func _local_player_step(me: Player, delta: float) -> void:
	var hold := counting_here() or (_photo_spot(my_key()).is_finite() and _photo_step < 2)
	if hold:
		if not _pin.is_finite():
			_pin = _photo_spot(my_key()) if _photo_spot(my_key()).is_finite() else me.global_position
		me.global_position = _pin
		me.velocity = Vector3.ZERO
		return
	_pin = Vector3.INF
	if not running() or me.is_hiding():
		return
	var push := Vector3.ZERO
	var words := ""
	if kind == GameRules.HIDE_SEEK and hide.is_playing(my_key()):
		push = HideSeekRound.area_push(me.global_position, hide.base)
		words = GameWords.AREA
	elif kind == GameRules.STORM_RUN:
		push = StormRun.push(me.global_position, storm.circle_centre(), storm.circle_radius())
		words = GameWords.PUSHED
		_touch_stars(me)
	if push != Vector3.ZERO:
		push_body(me, push, Player.AUTO_STEP_VELOCITY)
		if _now() - _pushed_at >= PUSH_TOAST:
			_pushed_at = _now()
			Session.magic_feedback.emit(words)
	if kind == GameRules.HIDE_SEEK and hide.phase == HideSeekRound.Phase.SEEKING and hide.is_seeker(my_key()):
		_look_t -= delta
		if _look_t <= 0.0:
			_look_t = LOOK_EVERY
			look_for_hiders(me)


## Moves `body` by a gentle push (a flat velocity) for one physics step, sliding along walls and the
## ground like its own steps; its own velocity is kept, and against a wall or ledge it gets `hop` upwards
## (its own physics then hops onto a 1-block step, like walking into it; a flyer's steering takes it away).
static func push_body(body: CharacterBody3D, push: Vector3, hop: float = 0.0) -> void:
	var own := body.velocity
	body.velocity = push
	body.move_and_slide()
	var blocked := body.is_on_wall()
	body.velocity = own
	if blocked and hop > 0.0 and own.y <= 0.1:
		body.velocity.y = hop


## May this game ask the host about `what` again (at most once a second each)?
func _may_ask(what: String) -> bool:
	var now := Time.get_ticks_msec()
	if _asked.has(what) and now - int(_asked[what]) < ASK_AGAIN_MS:
		return false
	_asked[what] = now
	return true


## A seeking player looks: every hider it sees (from its camera, the stealth rules) is asked about.
func look_for_hiders(me: Player) -> void:
	var cam := me.camera()
	var facing := -cam.global_transform.basis.z if cam and cam.is_inside_tree() else Vector3.FORWARD
	var eye := me.eye_position()
	for k in hide.hiders_left():
		var target := _eye_of(k)
		if target.is_finite() and HideSeekRound.can_see(eye, facing, target, _visibility_of(k), _is_blocking) \
				and _may_ask(k):
			Session.games_request_find(k)


## Where a seeker's look aims at someone (their eyes, lower while crouching).
func _eye_of(key: String) -> Vector3:
	var p := _player(key)
	if p:
		return p.stealth_eye() if p.is_spawned() else Vector3.INF
	var b := _bot(key)
	return b.game_eye() if b and not b.knocked_out else Vector3.INF


## How visible someone is (StealthRules.visibility). The host knows the light around everyone; a guest
## guesses daylight (the host checks again with the real light).
func _visibility_of(key: String) -> float:
	var p := _player(key)
	if p:
		if Session.is_host():
			return p.stealth_visibility()
		var f := Vector3i(p.global_position.floor())
		var bush := StealthRules.in_bush(_block(f), _block(f + Vector3i.UP))
		return StealthRules.visibility(1.0, p.crouching, p.is_hiding() or (p.crouching and bush), p.is_invisible())
	var b := _bot(key)
	if b == null:
		return 0.0
	var feet := Vector3i(b.global_position.floor())
	var crouch := b.game_pose == BotFriend.POSE_CROUCH
	var in_bush := StealthRules.in_bush(_block(feet), _block(feet + Vector3i.UP))
	var light := float(b.get_meta(&"stealth_light", 1.0))
	return StealthRules.visibility(light, crouch, b.game_pose == BotFriend.POSE_INSIDE or (crouch and in_bush), false)


func _touch_stars(me: Player) -> void:
	for id: int in storm.stars:
		if StormRun.can_take(me.global_position, storm.stars[id]) and _may_ask("s%d" % id):
			Session.games_request_star(id)


# --- Host: hide-and-seek ---------------------------------------------------------------------------

func _hide_events(events: Array[StringName]) -> void:
	for e in events:
		match e:
			HideSeekRound.SEEK:
				_tell_players(_players_in, GameWords.SEEK_START)
				for k in hide.seekers:
					var b := _bot(k)
					if b:
						Session.bot_say(b.bot_name, GameWords.BOT_SEEK)
				_broadcast()
			HideSeekRound.HINT:
				_hint()
			HideSeekRound.TIME_UP:
				_end_round()


## A seeker's request: they saw `hider` (their own game checked the view; the host checks the rest with
## the real light: close, visible, a clear line).
func _on_find_requested(peer_id: int, hider: String) -> void:
	if not Session.is_host() or kind != GameRules.HIDE_SEEK or hide.phase != HideSeekRound.Phase.SEEKING:
		return
	var seeker := GameRules.player_key(peer_id)
	var p := Session._player_for_peer(peer_id)
	if p == null or not hide.is_seeker(seeker) or not hide.is_hiding(hider):
		return
	var eye := p.eye_position()
	var target := _eye_of(hider)
	if not target.is_finite():
		return
	if HideSeekRound.can_see(eye, target - eye, target, _visibility_of(hider), _is_blocking, HideSeekRound.FIND_SLACK):
		found(seeker, hider)


## A seeker looks into the barrel, closet or bush at `cell`: everyone hiding in it is found.
func _on_spot_requested(peer_id: int, cell: Vector3i) -> void:
	if not Session.is_host() or kind != GameRules.HIDE_SEEK or hide.phase != HideSeekRound.Phase.SEEKING:
		return
	var seeker := GameRules.player_key(peer_id)
	var p := Session._player_for_peer(peer_id)
	if p == null or not hide.is_seeker(seeker):
		return
	if not HideSeekRound.spot_in_reach(p.eye_position(), cell):
		tell.call(peer_id, GameWords.CLOSER)
		return
	if not check_spot(seeker, cell):
		tell.call(peer_id, GameWords.NOBODY)


## Host: the seeker `seeker` looks into `cell`; true when someone was in it.
func check_spot(seeker: String, cell: Vector3i) -> bool:
	if not BotGamePlans.HIDING_SPOTS.has(_block(cell)):
		return false
	var any := false
	for k in hide.hiders_left():
		if _in_spot(k, cell):
			found(seeker, k)
			any = true
	return any


func _in_spot(key: String, cell: Vector3i) -> bool:
	var p := _player(key)
	if p:
		return HideSeekRound.in_spot(cell, p.hidden_in, p.global_position)
	var b := _bot(key)
	return b != null and HideSeekRound.in_spot(cell, b.game_hidden_in, b.global_position)


## Host: `seeker` found `hider`, who comes out of their spot and seeks too. Everyone hears it.
func found(seeker: String, hider: String) -> void:
	if not hide.find(seeker, hider):
		return
	var at := Vector3.INF
	var p := _player(hider)
	if p:
		at = p.global_position
		if p.is_hiding():
			Session.stealth_broadcast_hidden(p.peer_id, false, p.hidden_in)
	var b := _bot(hider)
	if b:
		b.game_set_pose(BotFriend.POSE_NONE)
		at = b.global_position
		_plans.erase(hider)
		Session.bot_say(b.bot_name, GameWords.BOT_FOUND_ME)
	var sb := _bot(seeker)
	var sname := str(hide.names.get(seeker, "Someone"))
	var hname := str(hide.names.get(hider, "someone"))
	if sb:
		Session.bot_say(sb.bot_name, GameWords.bot_found(hname))
	_tell_players(_players_in, GameWords.found(sname, hname),
		{hider: GameWords.found_you(sname), seeker: GameWords.you_found(hname)})
	if at.is_finite():
		_show_found(at)
		if not multiplayer.get_peers().is_empty():
			_rpc_found.rpc(at)
	_after_change()


@rpc("authority", "call_remote", "reliable")
func _rpc_found(at: Vector3) -> void:
	_show_found(at)


func _show_found(at: Vector3) -> void:
	if not at.is_finite() or not is_inside_tree():
		return
	Fx.burst(get_tree().root, at + Vector3(0, 1.2, 0), FOUND_COLOR, 18, 4.0, 0.12, 0.8, 6.0)
	Audio.play(&"ding", at)


## Host: a sparkle near someone still hiding (after two minutes of seeking), for everyone.
func _hint() -> void:
	var left := hide.hiders_left()
	if left.is_empty():
		return
	var body := _body(left[rng.randi() % left.size()])
	if body == null:
		return
	var at := body.global_position + Vector3(rng.randf_range(-HINT_SPREAD, HINT_SPREAD), 0, rng.randf_range(-HINT_SPREAD, HINT_SPREAD))
	for key: String in _plans:
		if hide.is_seeker(key):
			(_plans[key] as Dictionary).hint = at   # seeking bots go and look there too
	show_hint(at)
	if not multiplayer.get_peers().is_empty():
		_rpc_hint.rpc(at)


@rpc("authority", "call_remote", "reliable")
func _rpc_hint(at: Vector3) -> void:
	show_hint(at)


func show_hint(at: Vector3) -> void:
	if not at.is_finite() or not is_inside_tree():
		return
	Fx.burst(get_tree().root, at + Vector3(0, 1.5, 0), HINT_COLOR, 24, 2.5, 0.12, 1.4, -2.0)
	Audio.play(&"sparkle", at)
	Session.magic_feedback.emit(GameWords.HINT)


## Host, a few times a second: bot seekers look around (the same sight rules as a child); players or bots
## who left leave the round; stars touched by bots count.
func _host_tick() -> void:
	if kind == GameRules.HIDE_SEEK and running():
		for k in hide.seekers.duplicate() + hide.hiders.duplicate():
			if _body(k) == null:
				hide.leave(k)
				_after_change()
				return
		if hide.phase == HideSeekRound.Phase.SEEKING:
			for k in hide.seekers.duplicate():
				var b := _bot(k)
				if b and b.game_pose != BotFriend.POSE_INSIDE:
					_bot_looks(b, k)


func _bot_looks(b: BotFriend, key: String) -> void:
	var facing := Basis(Vector3.UP, b.rotation.y) * Vector3.FORWARD
	for k in hide.hiders_left():
		var target := _eye_of(k)
		if target.is_finite() and HideSeekRound.can_see(b.eye_position(), facing, target, _visibility_of(k), _is_blocking):
			found(key, k)
			if kind != GameRules.HIDE_SEEK or not running():
				return


# --- Host: hiding spots near the counting spot (a few 16³ boxes a frame) ------------------------------

func _start_scan(base: Vector3) -> void:
	_spots.clear()
	_scan.clear()
	var r := int(HideSeekRound.AREA_RADIUS)
	var lo := Vector3i(floori(base.x) - r, floori(base.y) - SCAN_DEPTH, floori(base.z) - r)
	var hi := Vector3i(floori(base.x) + r, floori(base.y) + SCAN_DEPTH, floori(base.z) + r)
	var s := SCAN_SIZE
	for x in range(floori(float(lo.x) / s), floori(float(hi.x) / s) + 1):
		for z in range(floori(float(lo.z) / s), floori(float(hi.z) / s) + 1):
			for y in range(floori(float(lo.y) / s), floori(float(hi.y) / s) + 1):
				_scan.append(Vector3i(x, y, z) * s)
	var c := Vector3(base)
	_scan.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return c.distance_squared_to(Vector3(a) + Vector3.ONE * s * 0.5) > c.distance_squared_to(Vector3(b) + Vector3.ONE * s * 0.5))


## Looks at a few boxes (nearest last in the list: popped first).
func _scan_step() -> void:
	for i in SCAN_PER_FRAME:
		if _scan.is_empty():
			return
		var origin: Vector3i = _scan.pop_back()
		for cell: Vector3i in find_spots.call(origin, Vector3i.ONE * SCAN_SIZE):
			_spots[cell] = _block(cell)


func scan_done() -> bool:
	return _scan.is_empty()


func hiding_spots() -> Dictionary:
	return _spots


func _find_spots(origin: Vector3i, size: Vector3i) -> Array[Vector3i]:
	if world == null:
		return [] as Array[Vector3i]
	return MonsterDirector.find_blocks(world.copy_box(origin, size), origin, BotGamePlans.HIDING_SPOTS)


# --- Host: bot friends in the games -----------------------------------------------------------------

## A bot friend's decision while a game needs it (BotFriend.game_brain); false: its own behaviour.
func _bot_decide(bot: BotFriend) -> bool:
	var key := GameRules.bot_key(bot.bot_name)
	if _photo_spot(key).is_finite():
		bot.game_hold()
		return true
	if kind == GameRules.HIDE_SEEK and running() and hide.is_playing(key):
		var plan: Dictionary = _plans.get(key, {})
		if hide.is_seeker(key):
			if hide.phase == HideSeekRound.Phase.COUNTING:
				bot.game_hold()
			else:
				_bot_seek(bot, key, plan)
		else:
			_bot_hide(bot, plan)
		_plans[key] = plan
		return true
	if kind == GameRules.STORM_RUN and storm.running():
		_bot_storm(bot, key)
		return true
	return false


func _bot_hide(bot: BotFriend, plan: Dictionary) -> void:
	if plan.get("done", false):
		bot.game_hold()
		return
	if not plan.has("stand"):
		if not scan_done():
			bot.game_hold()
			return
		_choose_hide(bot, plan)
	var stand: Vector3 = plan.stand
	plan.t = float(plan.get("t", 0.0)) + BotRules.AI_INTERVAL
	if not stand.is_finite() or bot.game_distance(stand) <= 0.8 or float(plan.t) >= HIDE_GIVE_UP:
		var cell: Vector3i = plan.get("cell", BotGamePlans.NO_CELL)
		if plan.get("how", &"") == &"inside" and StealthRules.is_hiding_block(_block(cell)) and not _taken(cell, bot) \
				and bot.game_distance(stand) <= 1.5:
			bot.game_set_pose(BotFriend.POSE_INSIDE, cell)
		else:
			bot.game_set_pose(BotFriend.POSE_CROUCH)
		plan.done = true
		bot.game_hold()
		return
	bot.game_go(stand, 0.3, BotGamePlans.HIDE_SPEED)


func _taken(cell: Vector3i, by: BotFriend) -> bool:
	for n in get_tree().get_nodes_in_group(&"players"):
		if (n as Player).hidden_in == cell:
			return true
	for b in _bots():
		if b != by and b.game_hidden_in == cell:
			return true
	return false


## Where a hiding bot goes: a free spot (HideSeekRound's area), else a place out of the counting spot's sight.
func _choose_hide(bot: BotFriend, plan: Dictionary) -> void:
	var taken: Array[Vector3i] = []
	for other: Dictionary in _plans.values():
		if other.has("cell"):
			taken.append(other.cell)
	for n in get_tree().get_nodes_in_group(&"players"):
		if (n as Player).is_hiding():
			taken.append((n as Player).hidden_in)
	var cell := BotGamePlans.hide_choice(_spots, taken, hide.base, rng.randi())
	if cell != BotGamePlans.NO_CELL:
		plan.cell = cell
		if BotGamePlans.INSIDE_SPOTS.has(int(_spots[cell])):
			plan.how = &"inside"
			plan.stand = StealthRules.search_spot(cell, bot.global_position, _is_solid)
		else:
			plan.how = &"bush"
			plan.stand = Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)
		return
	var places: Array[Vector3] = []
	var seen: Array[bool] = []
	var eye := hide.base + Vector3(0, CameraRig.HEAD_HEIGHT, 0)
	for p in BotGamePlans.open_places(hide.base, rng.randi()):
		var feet := Vector3(p.x, BossRules.stand_y(p.x, p.y, hide.base.y, _block), p.y)
		places.append(feet)
		seen.append(_clear_line(eye, feet + Vector3(0, CameraRig.HEAD_HEIGHT * StealthRules.CROUCH_EYE, 0)))
	plan.how = &"open"
	plan.stand = BotGamePlans.open_choice(places, seen, rng.randi())


## Nothing blocks the look from `a` to `b` (never through walls, whatever the distance).
func _clear_line(a: Vector3, b: Vector3) -> bool:
	var to := b - a
	var hit := GridRay.cast(a, to, to.length(), _is_blocking)
	return hit == null or hit.position == Vector3i(b.floor())


func _bot_seek(bot: BotFriend, key: String, plan: Dictionary) -> void:
	if plan.has("hint"):
		var h: Vector3 = plan.hint
		if bot.game_distance(h) <= 2.0:
			plan.erase("hint")
		else:
			bot.game_go(h, 1.5, BotGamePlans.SEEK_SPEED)
			return
	if not plan.has("route") or int(plan.i) >= (plan.route as Array).size():
		_plan_route(bot, plan)
	var route: Array = plan.route
	if route.is_empty():
		bot.game_hold()
		return
	var at: Vector3 = route[int(plan.i)]
	var cells: Dictionary = plan.cells
	var cell: Vector3i = cells.get(at, BotGamePlans.NO_CELL)
	var stop := BotGamePlans.SPOT_STOP if cell != BotGamePlans.NO_CELL else 1.5
	if bot.game_distance(at) <= stop + 0.3:
		if cell != BotGamePlans.NO_CELL:
			plan.look = float(plan.get("look", 0.0)) + BotRules.AI_INTERVAL
			bot.game_hold(at)
			if float(plan.look) < BotGamePlans.LOOK_TIME:
				return
			check_spot(key, cell)
		_next_stop(plan)
		return
	plan.walk = float(plan.get("walk", 0.0)) + BotRules.AI_INTERVAL
	if float(plan.walk) >= WALK_GIVE_UP:
		_next_stop(plan)
		return
	bot.game_go(at, stop, BotGamePlans.SEEK_SPEED)


func _next_stop(plan: Dictionary) -> void:
	plan.i = int(plan.i) + 1
	plan.look = 0.0
	plan.walk = 0.0


## A seeking bot's route: the hiding spots it knows of in the play area and a few open places, nearest
## first (it never knows where anyone is).
func _plan_route(bot: BotFriend, plan: Dictionary) -> void:
	var points: Array[Vector3] = []
	var cells := {}
	for cell: Vector3i in _spots:
		var at := Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)
		if Vector2(at.x - hide.base.x, at.z - hide.base.z).length() <= HideSeekRound.AREA_RADIUS:
			points.append(at)
			cells[at] = cell
	var open := BotGamePlans.open_places(hide.base, rng.randi())
	for i in mini(OPEN_STOPS, open.size()):
		var p := open[i]
		points.append(Vector3(p.x, BossRules.stand_y(p.x, p.y, hide.base.y, _block), p.y))
	plan.route = BotGamePlans.search_route(points, bot.global_position, rng.randi())
	plan.cells = cells
	plan.i = 0
	plan.look = 0.0
	plan.walk = 0.0


# --- Host: Storm Run ------------------------------------------------------------------------------------

func _storm_step(step: Dictionary) -> void:
	for id: int in step.gone:
		if not multiplayer.get_peers().is_empty():
			_rpc_star_gone.rpc(id, false, storm.score)
	if step.over:
		_end_round()
		return
	if step.spawn:
		_spawn_star()


## Host: a new star over standing ground inside the circle (a few spots tried: water, holes and unloaded
## ground are skipped).
func _spawn_star() -> void:
	var c := storm.circle_centre()
	var pos := Vector3.INF
	for i in STAR_TRIES:
		var spot := StormRun.star_spot(c, storm.circle_radius(), rng.randf(), rng.randf())
		var feet := _star_ground(spot)
		if feet.is_finite():
			pos = feet + Vector3(0, 1.0, 0)
			break
	if not pos.is_finite():
		return
	spawned_stars += 1
	var id := storm.add_star(pos)
	if id < 0:
		return
	stars.show_star(id, pos)
	if not multiplayer.get_peers().is_empty():
		_rpc_star.rpc(id, pos)


## Standing ground at `spot` (flat) near the round's height (within BossRules.STAND_SEARCH), else the
## surface there when it is within STAR_CLIMB of it; INF for none (water, a hole, unloaded).
func _star_ground(spot: Vector2) -> Vector3:
	var x := floori(spot.x)
	var z := floori(spot.y)
	var heights: Array[float] = [BossRules.stand_y(spot.x, spot.y, ground_y, _block)]
	if world:
		heights.append(float(world.find_standing_y(x, z)))
	for y in heights:
		var feet := Vector3i(x, floori(y), z)
		if absf(y - ground_y) <= STAR_CLIMB and not BlockIds.is_solid(_block(feet)) \
				and not BlockIds.is_solid(_block(feet + Vector3i.UP)) and BlockIds.is_solid(_block(feet + Vector3i.DOWN)) \
				and _block(feet) != BlockIds.WATER:
			return Vector3(spot.x, float(feet.y), spot.y)
	return Vector3.INF


@rpc("authority", "call_remote", "reliable")
func _rpc_star(id: int, pos: Vector3) -> void:
	if kind == GameRules.STORM_RUN and pos.is_finite():
		storm.stars[id] = pos
		stars.show_star(id, pos)


@rpc("authority", "call_remote", "reliable")
func _rpc_star_gone(id: int, taken: bool, score: int) -> void:
	storm.stars.erase(id)
	storm.score = maxi(score, 0)
	stars.hide_star(id, taken)
	_update_line()


## A player touched star `id` (their own game): the host checks it with its own view of them.
func _on_star_requested(peer_id: int, id: int) -> void:
	if not Session.is_host() or kind != GameRules.STORM_RUN or not storm.running() or not storm.stars.has(id):
		return
	var p := Session._player_for_peer(peer_id)
	if p and StormRun.can_take(p.global_position, storm.stars[id], StormRun.STAR_SLACK):
		take_star(id)


## Host: star `id` is the team's.
func take_star(id: int) -> bool:
	if not storm.take(id):
		return false
	stars.hide_star(id, true)
	if not multiplayer.get_peers().is_empty():
		_rpc_star_gone.rpc(id, true, storm.score)
	_update_line()
	return true


func _bot_storm(bot: BotFriend, key: String) -> void:
	var plan: Dictionary = _plans.get(key, {})
	_plans[key] = plan
	var target := int(plan.get("star", -1))
	if not storm.stars.has(target):
		var claimed: Array[int] = []
		for other: String in _plans:
			if other != key:
				claimed.append(int((_plans[other] as Dictionary).get("star", -1)))
		target = BotGamePlans.star_target(storm.stars, bot.global_position, claimed)
		plan.star = target
	if target < 0:
		var c := storm.circle_centre()
		bot.game_go(Vector3(c.x, bot.global_position.y, c.y), 3.0, BotGamePlans.STAR_SPEED)
		return
	var at: Vector3 = storm.stars[target]
	if StormRun.can_take(bot.global_position, at):
		take_star(target)
		plan.star = -1
		return
	bot.game_go(at, 0.2, BotGamePlans.STAR_SPEED)


# --- The team photo after a boss ---------------------------------------------------------------------

## Host: a boss was beaten; TEAM PHOTO shows on every game for TeamPhoto.OFFER_TIME.
func offer_photo() -> void:
	if not Session.is_host():
		return
	_photo_offered_at = _now()
	receive_photo_offer(TeamPhoto.OFFER_TIME)
	if not multiplayer.get_peers().is_empty():
		_rpc_photo_offer.rpc(TeamPhoto.OFFER_TIME)


@rpc("authority", "call_remote", "reliable")
func _rpc_photo_offer(seconds: float) -> void:
	receive_photo_offer(seconds)


func receive_photo_offer(seconds: float) -> void:
	_offer_t = clampf(seconds, 0.0, TeamPhoto.OFFER_TIME)
	photo_offer_changed.emit(_offer_t > 0.0)
	if _offer_t > 0.0:
		Session.magic_feedback.emit(GameWords.PHOTO_OFFER)


func photo_offered() -> bool:
	return _offer_t > 0.0


## Host: TEAM PHOTO was tapped. Everyone near the one who tapped lines up; every game takes its photo.
func _on_photo_requested(peer_id: int) -> void:
	if not Session.is_host() or not TeamPhoto.offer_open(_now(), _photo_offered_at) or not _photo.is_empty():
		return
	var asker := Session._player_for_peer(peer_id)
	if asker == null or not asker.is_spawned():
		return
	var center := asker.global_position
	var keys: Array[String] = []
	for k in _participants():
		var body := _body(k)
		if body and TeamPhoto.is_near(center, body.global_position):
			keys.append(k)
	var yaw := asker.avatar.rotation.y if asker.avatar else 0.0
	var line := TeamPhoto.order(keys, GameRules.player_key(peer_id))
	var feet := TeamPhoto.line_up(center, yaw, line.size())
	var spots := {}
	for i in line.size():
		var f := feet[i]
		spots[line[i]] = Vector3(f.x, BossRules.stand_y(f.x, f.z, center.y, _block), f.z)
	var plan := {"spots": spots, "face": TeamPhoto.face_yaw(yaw), "view": TeamPhoto.camera_view(center, yaw, line.size(), fov, _is_solid)}
	_photo_offered_at = -1.0
	run_photo(plan)
	if not multiplayer.get_peers().is_empty():
		_rpc_photo.rpc(plan)


@rpc("authority", "call_remote", "reliable")
func _rpc_photo(plan: Dictionary) -> void:
	run_photo(plan)


## Every game: the line-up. Its own player goes to its spot facing the camera (the host moves the bots).
func run_photo(plan: Dictionary) -> void:
	if not plan.get("spots") is Dictionary or not plan.get("view") is Transform3D:
		return
	_photo = plan
	_photo_t = 0.0
	_photo_step = 0
	_pin = Vector3.INF
	if _offer_t > 0.0:
		_offer_t = 0.0
		photo_offer_changed.emit(false)
	var face := float(plan.get("face", 0.0))
	var me := local_player
	var mine := _photo_spot(my_key())
	if is_instance_valid(me) and mine.is_finite():
		me.global_position = mine
		me.velocity = Vector3.ZERO
		if me.avatar:
			me.avatar.rotation.y = face
		Session.magic_feedback.emit(GameWords.SAY_CHEESE)
	if Session.is_host():
		for b in _bots():
			var spot := _photo_spot(GameRules.bot_key(b.bot_name))
			if spot.is_finite():
				b.game_set_pose(BotFriend.POSE_NONE)
				b.global_position = spot
				b.velocity = Vector3.ZERO
				b.rotation.y = face
				b.game_brain = _bot_decide
				b.game_hold()


func _photo_spot(key: String) -> Vector3:
	var spots: Variant = _photo.get("spots")
	if spots is Dictionary and (spots as Dictionary).get(key) is Vector3:
		return spots[key]
	return Vector3.INF


func _photo_process(delta: float) -> void:
	if _photo.is_empty():
		if _offer_t > 0.0:
			_offer_t -= delta
			if _offer_t <= 0.0:
				photo_offer_changed.emit(false)
		return
	_photo_t += delta
	if _photo_step == 0 and _photo_t >= TeamPhoto.EMOTE_AT:
		_photo_step = 1
		for key: String in _photo.spots:
			var p := _player(key)
			if p:
				p.show_emote(TeamPhoto.EMOTE)
			var b := _bot(key) if p == null else null
			if b and b.avatar:
				b.avatar.play_emote(TeamPhoto.EMOTE)
	elif _photo_step == 1 and _photo_t >= TeamPhoto.SHOT_AT:
		_photo_step = 2
		if _photo_spot(my_key()).is_finite():
			take_photo.call(_photo.view)
			photo_taken.emit()
	elif _photo_step == 2 and _photo_t >= TeamPhoto.SHOT_AT + 0.6:
		_photo = {}
		_pin = Vector3.INF
		if Session.is_host() and kind == &"":
			for b in _bots():
				b.game_brain = Callable()
