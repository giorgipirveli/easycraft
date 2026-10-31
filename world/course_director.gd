class_name CourseDirector
extends Node
## Game Blocks' courses in a world (M3 Task 7, spec §14.4, §3a; §16's "friends racing your course"). The
## sandbox adds one on every peer, always named "Courses".
## Every peer, for its own player (setup_local): watch() looks at the feet every physics frame, but reads blocks
## only when the feet move to another cell: stepping on START (and off it), a CHECKPOINT or FINISH (while
## racing), a teleport pad, and coins walked through (while racing) are told to the host
## (Session.request_smart_touch). A fall while racing (more than 12 blocks below the checkpoint, into water
## or out of the world) brings the player back to the checkpoint, on their own game. The HUD's race clock
## follows the run the host sends (state_changed).
## Host: every runner's run (CourseRun) on its own clock, checked touches only (Session: the block is there,
## the body it knows is on it): START arms, stepping off starts the clock, FINISH counts only after START.
## Results: the time, the coins (course score, never gold) and a medal by the course's goals (CourseBook: the
## first finished run sets them, the builder changes them in the goals panel). Every running runner's way is
## sampled 10 times a second; the best run is kept (3 minutes at most) for bot friends to race (race_bot).
## A runner knocked out, gone, far away or running for too long stops. Saved in WorldMeta.smart.courses.

## Host: a runner's clock started (they stepped off START): waiting bot friends go too.
signal run_started(peer_id: int, start: Vector3i)
## Host: a runner finished.
signal run_finished(peer_id: int, start: Vector3i, ms: int, medal: StringName)
## Local: this player's run changed (the race clock).
signal state_changed(state: Dictionary)

const CHECK_EVERY := 0.1
const GHOST_RADIUS := 64.0          # a bot races the nearest recorded course within this of its player
const STANDING := 0.06              # feet this close to a block's top stand on it
const NO_COURSE := "Finish a course first: then a bot friend can race your best run!"
const FALL_BACK := "Back to your checkpoint!"

## Host: the host's clock (ms; tests set their own).
var now_ms: Callable = Time.get_ticks_msec
## Host: a runner's name for the others' toast.
var name_of: Callable = func(peer_id: int) -> String: return str(Session.chat_names.get(peer_id, "A friend"))
## Local: a few words on this player's screen (the HUD's toast).
var toast: Callable = func(_text: String) -> void: pass
var book := CourseBook.new()

var _runs := {}                     # host: peer -> CourseRun
var _racers := {}                   # host: bot friend -> the START it waits at
var _rng := RandomNumberGenerator.new()
var _check_t := 0.0

var player: Player                  # this game's own player
var state := {}                     # this player's run, as the host sent it
var _state_ms := 0                  # when it came (the clock runs on from there)
var _feet_key := Vector4i(0, -100000, 0, 0)   # the feet's cell and whether they stand, last frame
var _floor: Array = []              # [cell, id] of the Game Block or pad under the feet
var _coins_told := {}


func _ready() -> void:
	_rng.randomize()
	add_to_group(Player.TELEPORT_RULES)   # owner #101 (P4): no VR teleport while racing (it would skip checkpoints)


## Owner #101: a VR teleport is refused for this game's player while it races a course.
func refuses_teleport(p: Player, _at: Vector3) -> bool:
	return p == player and is_racing()


# --- Host: start, save ----------------------------------------------------------------------------------

## Host: a world's saved courses (WorldMeta.smart); listens to the host's checked touches and panel asks.
func start(saved: Dictionary) -> void:
	book = CourseBook.from_save(saved.get("courses"))
	if not Session.smart_touch_requested.is_connected(touch):
		Session.smart_touch_requested.connect(touch)
	if not Session.course_info_requested.is_connected(_on_info_requested):
		Session.course_info_requested.connect(_on_info_requested)
	if not Session.course_goals_requested.is_connected(_on_goals_requested):
		Session.course_goals_requested.connect(_on_goals_requested)


func to_save() -> Dictionary:
	return book.to_save()


func is_running(peer_id: int) -> bool:
	return _runs.has(peer_id) and (_runs[peer_id] as CourseRun).is_on()


func elapsed_of(peer_id: int) -> int:
	return (_runs[peer_id] as CourseRun).elapsed(_now()) if _runs.has(peer_id) else 0


func _now() -> int:
	return int(now_ms.call())


# --- Host: touches ----------------------------------------------------------------------------------------

## Host (Session.smart_touch_requested, already checked): a runner's feet on a Game Block.
func touch(peer_id: int, id: int, cell: Vector3i, left: bool) -> void:
	var run: CourseRun = _runs.get(peer_id)
	match id:
		BlockIds.START:
			if left:
				if run and run.armed and run.start == cell:
					run.go(_now())
					_send(peer_id, "go")
					run_started.emit(peer_id, cell)
			else:
				if run == null:
					run = CourseRun.new()
					_runs[peer_id] = run
				run.arm(cell, _now())
				_send(peer_id, "armed")
		BlockIds.CHECKPOINT:
			if run and run.checkpoint(cell):
				_send(peer_id, "checkpoint")
		BlockIds.COIN:
			if run and run.coin(cell):
				_send(peer_id, "coin")
		BlockIds.FINISH:
			if run:
				_finish(peer_id, run, cell)


func _finish(peer_id: int, run: CourseRun, finish: Vector3i) -> void:
	run.record(CourseRules.top_of(finish))   # the recording ends on FINISH (a racing bot does too)
	var ms := run.finish(_now())
	if ms < 0:
		return                          # stood on START and never left it: nothing to time
	_runs.erase(peer_id)
	var who := _runner_name(peer_id)
	var res := book.finished(run.start, finish, ms, who, run.path, peer_id == multiplayer.get_unique_id())
	var s := _state(run, "finish")
	s.ms = ms
	s.medal = String(res.medal)
	s.best = res.best
	s.goals = book.goals(run.start)
	s.mine_best = res.mine_best   # M4 ghost races: the owner's own new best (it can go on the showcase)
	Session.send_course_state(peer_id, s)
	var words := tr("%s finished: %s%s") % [who, CourseRules.format_time(ms), _medal_words(res.medal)]
	for other in _others(peer_id):
		Session.send_feedback(other, words)
	run_finished.emit(peer_id, run.start, ms, res.medal)
	Session.progress_tell(peer_id, StringName("race_finished/%s" % res.medal) if res.medal != &"" else &"race_finished")   # M3 Task 12 (+ the medal: owner #45a)


func _runner_name(peer_id: int) -> String:
	var n := str(name_of.call(peer_id))
	return n if n != "" else "A friend"


static func _medal_words(medal: StringName) -> String:
	match medal:
		CourseRules.GOLD:
			return "  GOLD!"
		CourseRules.SILVER:
			return "  SILVER!"
		CourseRules.BRONZE:
			return "  BRONZE!"
	return "!"


func _others(peer_id: int) -> Array[int]:
	var out: Array[int] = []
	for id in [multiplayer.get_unique_id()] + Array(multiplayer.get_peers()):
		if id != peer_id and not out.has(id):
			out.append(id)
	return out


func _state(run: CourseRun, event: String) -> Dictionary:
	return {"on": run.is_on(), "armed": run.armed, "elapsed": run.elapsed(_now()), "coins": run.coins,
		"spot": run.spot, "event": event, "start": run.start}


func _send(peer_id: int, event: String) -> void:
	Session.send_course_state(peer_id, _state(_runs[peer_id], event))


func _stop(peer_id: int) -> void:
	_runs.erase(peer_id)
	Session.send_course_state(peer_id, {"on": false, "armed": false, "elapsed": 0, "coins": 0, "event": "stop"})


func _process(delta: float) -> void:
	tick(delta)


## Host: runners are sampled 10 times a second (their way, for bot friends); one knocked out, gone, far away
## or running for too long stops.
func tick(delta: float) -> void:
	if not multiplayer.is_server() or _runs.is_empty():
		return
	var now := _now()
	for peer: int in _runs.keys():
		var run: CourseRun = _runs[peer]
		if not run.running or run.path.full or run.path.size() * 100 > run.elapsed(now):
			continue   # M5 Task 3: no sample due this frame (one every 100 ms): no look-up of the runner's body
		var p := _player(peer)
		if p == null or p.knocked_out:
			_stop(peer)
			continue
		while run.path.size() * 100 <= run.elapsed(now) and not run.path.full:
			if not run.path.add(p.global_position):
				break
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	for peer: int in _runs.keys():
		var run: CourseRun = _runs[peer]
		var p := _player(peer)
		if p == null or p.knocked_out:   # knocked out or gone: the run stops (looked at 10 times a second)
			_stop(peer)
			continue
		if p and (run.elapsed(now) > CourseRules.RUN_MAX_MS
				or p.global_position.distance_to(CourseRules.top_of(run.start)) > CourseRules.COURSE_RADIUS):
			_stop(peer)


# --- Host: the goals panel --------------------------------------------------------------------------------

## The course whose START or FINISH is at `cell` (NONE when nobody finished it yet).
func course_at(cell: Vector3i) -> Vector3i:
	if not book.course(cell).is_empty():
		return cell
	return book.start_of_finish(cell)


## What the goals panel shows for the START or FINISH at `cell`.
func info_of(cell: Vector3i) -> Dictionary:
	var start := course_at(cell)
	if start == CourseBook.NONE:
		return {"cell": cell, "none": true}
	var c := book.course(start)
	return {"cell": cell, "none": false, "start": start, "goals": book.goals(start), "best": int(c.best),
		"best_name": str(c.best_name), "ghost": c.ghost != null, "mine_ms": book.mine_ms(start)}


func _on_info_requested(peer_id: int, cell: Vector3i) -> void:
	Session.send_course_info(peer_id, info_of(cell))


func _on_goals_requested(peer_id: int, cell: Vector3i, goals: Array) -> void:
	var start := course_at(cell)
	if start != CourseBook.NONE and book.set_goals(start, goals):
		Session.send_course_info(peer_id, info_of(cell))


# --- Host: bot friends race the best run ------------------------------------------------------------------

## Host: `bot` races the recorded best run of the course nearest its player, as its own run, a little faster
## or slower (0.9-1.1). It waits by START until a runner starts that course. "" when it will, else why not.
func race_bot(bot: BotFriend) -> String:
	if bot == null or not is_instance_valid(bot):
		return NO_COURSE
	var lead := bot._leader()
	var near := lead.global_position if lead else bot.global_position
	var start := book.nearest_with_ghost(near, GHOST_RADIUS)
	if start == CourseBook.NONE:
		return NO_COURSE
	bot.race_ready(book.ghost(start), _rng.randf_range(0.9, 1.1))
	if not bot.race_done.is_connected(_on_bot_done):
		bot.race_done.connect(_on_bot_done)
	_racers[bot] = start
	if not run_started.is_connected(_on_run_started):
		run_started.connect(_on_run_started)
	return ""


func _on_run_started(_peer_id: int, start: Vector3i) -> void:
	for bot: BotFriend in _racers.keys():
		if not is_instance_valid(bot) or not bot.is_racing():
			_racers.erase(bot)
		elif _racers[bot] == start:
			bot.race_go()


func _on_bot_done(bot: BotFriend, ms: int) -> void:
	_racers.erase(bot)
	var words := tr("%s finished: %s!") % [BotRules.chat_name(bot.bot_name), CourseRules.format_time(ms)]
	for id in _others(-1):
		Session.send_feedback(id, words)


# --- Every peer: this game's own player -------------------------------------------------------------------

## This game's player: its feet are watched, its run shown (the HUD listens to state_changed).
func setup_local(p: Player) -> void:
	player = p
	if not Session.course_state_received.is_connected(_on_state):
		Session.course_state_received.connect(_on_state)


func is_racing() -> bool:
	return bool(state.get("on", false))


## The race clock's time now (ms): the host's, running on locally between its messages.
func clock_ms() -> int:
	if not is_racing() or bool(state.get("armed", false)):
		return 0
	return int(state.get("elapsed", 0)) + Time.get_ticks_msec() - _state_ms


func _on_state(given: Dictionary) -> void:
	var s := given
	if state_filter.is_valid():   # M4 ghost races: a race against a ghost has the ghost's medal
		s = state_filter.call(given)
	state = s
	_state_ms = Time.get_ticks_msec()
	if str(s.get("event", "")) in ["armed", "stop", "finish"]:
		_coins_told.clear()
	_local_fx(s)
	state_changed.emit(s)


func _local_fx(s: Dictionary) -> void:
	if not is_instance_valid(player):
		return
	var at := player.global_position
	match str(s.get("event", "")):
		"armed":
			Audio.play(&"plate_click", at)
		"go":
			Audio.play(&"ding", at)
		"checkpoint":
			Audio.play(&"sparkle", at)
			Fx.burst(get_tree().root, at + Vector3(0, 1.0, 0), Color("5b9dff"), 16, 3.0, 0.1, 0.8, -1.0)
		"coin":
			Audio.play(&"coin", at)
			Fx.burst(get_tree().root, at + Vector3(0, 1.2, 0), Color("ffd23f"), 10, 2.5, 0.08, 0.5, 2.0)
		"finish":
			Audio.play(&"chime", at)
			for c in [Color("ff5c8a"), Color("ffd23f"), Color("46e0ff"), Color("7ee06b")]:
				Fx.burst(get_tree().root, at + Vector3(0, 1.2, 0), c, 10, 5.0, 0.12, 1.0, 6.0)


func _physics_process(_delta: float) -> void:
	watch()


## This game's player: tells the host what its feet touch (only when they move to another cell), and brings
## it back to the checkpoint after a fall while racing.
func watch() -> void:
	if not is_instance_valid(player) or not player.is_spawned() or player.knocked_out or player.world == null:
		return
	var feet := player.global_position
	var racing := is_racing()
	if racing and CourseRules.fell(feet, state.get("spot", feet), player.water_state != SwimRules.State.DRY
			and player.water_state != SwimRules.State.WADING):
		_fall_back()
		return
	var cell := Vector3i(feet.floor())
	var standing := absf(feet.y - roundf(feet.y)) < STANDING and player.physics_mode != PhysicsMode.Mode.GHOST
	var key := Vector4i(cell.x, cell.y, cell.z, 1 if standing else 0)
	if key == _feet_key:
		return                          # the same cell as last frame: nothing new under the feet
	_feet_key = key
	var get_block: Callable = player.world.get_block
	var now_floor: Array = []
	if standing:
		now_floor = CourseRules.floor_block(feet, player.body_radius(), get_block)
	if now_floor != _floor:
		if not _floor.is_empty() and _floor[1] == BlockIds.START:
			_touch(BlockIds.START, _floor[0], true)   # stepped off START: go!
		_floor = now_floor
		if not now_floor.is_empty():
			var id: int = now_floor[1]
			if id == BlockIds.START or id == BlockIds.TELEPORT_PAD or racing:
				_touch(id, now_floor[0])
	if racing:
		for c: Vector3i in [cell, cell + Vector3i.UP]:
			if not _coins_told.has(c) and int(get_block.call(c)) == BlockIds.COIN:
				_coins_told[c] = true
				_touch(BlockIds.COIN, c)


func _fall_back() -> void:
	var spot: Vector3 = state.get("spot", player.global_position)
	player.spawn_at(spot)
	_floor = []
	_feet_key = Vector4i(0, -100000, 0, 0)
	Fx.burst(get_tree().root, spot + Vector3(0, 1.0, 0), Color(1, 1, 1, 0.9), 12, 2.5, 0.12, 0.45, 2.0)
	toast.call(FALL_BACK)

# --- M4 ghost races: a world of its own (a showcase visit) and a race against a ghost ---
# A visit's world never registers with Session (read-only by construction, M4 I), so a visit's director is its
# own host: its player's touches go straight to touch() once the block is really there (touch_sink), its runner
# is its own player (player_of). A race against a friend's ghost shows the ghost's medal (state_filter:
# GhostRaces). Empty Callables: the game's usual way (Session's checked touches, the host's players).

## (id: int, cell: Vector3i, left: bool) -> void: where this player's touches go (default: Session's request).
var touch_sink := Callable()
## (peer_id: int) -> Player: the host's player of a runner (default: Session's).
var player_of := Callable()
## (state: Dictionary) -> Dictionary: this player's run as the race clock shows it.
var state_filter := Callable()


func _touch(id: int, cell: Vector3i, left: bool = false) -> void:
	if touch_sink.is_valid():
		touch_sink.call(id, cell, left)
	else:
		Session.request_smart_touch(id, cell, left)


func _player(peer_id: int) -> Player:
	return player_of.call(peer_id) if player_of.is_valid() else Session._player_for_peer(peer_id)


## A visit: this game is its own host, its player the only runner, its world only its own.
func setup_own_world(p: Player, world_block_at: Callable) -> void:
	player_of = func(_peer_id: int) -> Player: return p
	touch_sink = func(id: int, cell: Vector3i, left: bool) -> void:
		if int(world_block_at.call(cell)) == id:
			touch(multiplayer.get_unique_id(), id, cell, left)
	setup_local(p)
