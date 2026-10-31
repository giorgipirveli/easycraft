extends Node
## The steps of tools/games_smoke.gd (M4 Wave 3, agent H), in a new Sandbox world on real terrain, through
## the real sandbox, Session and GamesDirector: two bot friends join; hide-and-seek (the child seeks, the
## Totem and the night monsters wait, the counting holds the child still, the bots hide — one in a barrel
## 10 blocks away — a look into the barrel and a find end it, a sticker); Storm Run (stars on the real
## ground inside the circle, the push back in, END GAME, the best kept with the world); the team photo
## (TEAM PHOTO shows, the line-up, photo mode saves the picture). Prints the frame and process times of
## each part (desktop numbers, a rough guide) and the cost of looking for hiding spots in one 16³ box.

const TIMEOUT := 150.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _barrel := Vector3i.ZERO
var _pinned := Vector3.INF
var _part := ""
var _costs := {}                  # part -> [frames, sum ms, worst ms, sum process ms, worst process ms]
var _done := false
var _in_barrel := ""
var _games: GamesDirector         # its steps run (and are timed) here
var _director := {}               # part -> [steps, total us, worst us]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


## Runs the director's own process and physics steps, to time them alone (per part).
func _physics_process(delta: float) -> void:
	if _games and is_instance_valid(_games) and not get_tree().paused:
		var t0 := Time.get_ticks_usec()
		_games._physics_process(delta)
		_time(Time.get_ticks_usec() - t0)


func _time(us: int) -> void:
	if _part == "":
		return
	var d: Array = _director.get(_part, [0, 0, 0])
	_director[_part] = [d[0] + 1, d[1] + us, maxi(d[2], us)]


func _process(delta: float) -> void:
	if _done:
		return
	if _games and is_instance_valid(_games) and not get_tree().paused:
		var t0 := Time.get_ticks_usec()
		_games._process(delta)
		_time(Time.get_ticks_usec() - t0)
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _part != "":
		var c: Array = _costs.get(_part, [0, 0.0, 0.0, 0.0, 0.0])
		var ms := delta * 1000.0
		var proc := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		_costs[_part] = [c[0] + 1, c[1] + ms, maxf(c[2], ms), c[3] + proc, maxf(c[4], proc)]
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, sandbox.player)


func _run_step(sandbox: Node, p: Player) -> void:
	var games := sandbox.get("games") as GamesDirector
	var bots := sandbox.get("_bot_director") as BotDirector
	var me := GameRules.player_key(p.peer_id)
	match _step:
		0:
			_check(games != null and games.name == "Games", "the sandbox has its GamesDirector")
			games.set_process(false)
			games.set_physics_process(false)
			_games = games
			_check(sandbox.pause_menu.friends == bots, "the pause menu's FRIENDS row (GAMES is in its panel)")
			bots.add(BotRules.EXPLORER)
			bots.add(BotRules.BUILDER)
			var x := floori(p.global_position.x) + 10
			var z := floori(p.global_position.z)
			_barrel = Vector3i(x, p.world.find_standing_y(x, z), z)
			p.world.set_block(_barrel, BlockIds.BARREL)
			_check(p.world.get_block(_barrel) == BlockIds.BARREL, "a barrel 10 blocks away")
			_part = "quiet"
			_next(3.0)
		1:
			_part = "hide_counting"
			Session.games_request_start(GameRules.HIDE_SEEK, me)
			_check(games.running() and games.kind == GameRules.HIDE_SEEK, "hide-and-seek started")
			_check(games.hide.seekers == ([me] as Array[String]), "the child seeks")
			_check(games.counting_here(), "the counting screen")
			_check(not bool(sandbox._monsters.enabled.call()), "no night monsters during the round")
			_check((sandbox.waves() as WaveDirector).request_start(p.peer_id, 1) == &"game", "the Totem waits")
			_check(sandbox.hud.game_line.visible, "the HUD's round line: %s" % sandbox.hud.game_line.label.text)
			_pinned = p.global_position
			_next(0.5)
		2:
			p.global_position += Vector3(3, 0, 0)
			_next(0.2)
		3:
			_check(p.global_position.distance_to(_pinned) < 0.2, "the counting child holds still")
			_next(0.0)
		4:
			if _all_hidden(bots) or _step_t > 16.0:
				for b in bots.bots():
					_check(b.game_pose != BotFriend.POSE_NONE, "%s hid (%s)" % [b.bot_name, ["", "crouching", "inside"][b.game_pose]])
				var inside := bots.bots().filter(func(b: BotFriend) -> bool: return b.game_hidden_in == _barrel)
				_check(inside.size() == 1, "one friend is in the barrel")
				if inside.size() == 1:
					_in_barrel = GameRules.bot_key((inside[0] as BotFriend).bot_name)
				_part = "hide_seeking"
				games._process(HideSeekRound.COUNT_TIME)   # the rest of the counting at once
				_next(0.5)
		5:
			_check(games.hide.phase == HideSeekRound.Phase.SEEKING, "ready or not")
			_check(not games.counting_here(), "the counting screen goes")
			var near := Vector3(_barrel.x - 1.5, p.world.find_standing_y(_barrel.x - 2, _barrel.z) + 0.05, _barrel.z + 0.5)
			p.global_position = near
			Session.games_request_spot(_barrel)
			var left := games.hide.hiders_left()
			_check(not games.hide.is_hiding(_in_barrel), "the one in the barrel was found (%d left; the child's own look may find the other)" % left.size())
			if left.size() == 1:
				var b := games._bot(left[0])
				var fx := floori(b.global_position.x)
				var fz := floori(b.global_position.z) + 2   # on the ground 2 blocks away (never inside a slope)
				p.global_position = Vector3(fx + 0.5, p.world.find_standing_y(fx, fz) + 0.05, fz + 0.5)
				_next(0.4)   # the host's own player: seen at once; a moment for the physics to settle
				return
			_next(0.5)
		6:
			var left := games.hide.hiders_left()
			if left.size() == 1:
				Session.games_request_find(left[0])
			_next(0.5)
		7:
			_check(not games.running(), "everyone found: the round is over")
			_check(int(Profile.data.stickers.get("hide_seek", 0)) >= 1, "the child got the sticker")
			for b in bots.bots():
				_check(not b.game_brain.is_valid(), "%s is a friend again" % b.bot_name)
			_next(GameRules.OVER_TIME + 0.5)
		8:
			_part = "storm"
			Session.games_request_start(GameRules.STORM_RUN, "")
			_check(games.running() and games.kind == GameRules.STORM_RUN, "Storm Run started")
			_next(6.0)
		9:
			_check(games.spawned_stars >= 3, "stars appear (%d so far, %d out now, score %d)" % [games.spawned_stars, games.stars.count(), games.storm.score])
			var good := true
			for id: int in games.storm.stars:
				var s: Vector3 = games.storm.stars[id]
				var cell := Vector3i(s.floor())
				good = good and not BlockIds.is_solid(p.world.get_block(cell)) \
					and StormRun.outside_by(s, games.storm.circle_centre(), games.storm.circle_radius()) <= 0.0
			_check(good, "every star floats in the air inside the circle")
			_check(games.ring.visible, "the glowing circle shows")
			var c := games.storm.circle_centre()
			var ox := floori(c.x + games.storm.circle_radius() + 6.0)
			p.global_position = Vector3(ox + 0.5, p.world.find_standing_y(ox, floori(c.y)) + 0.05, floori(c.y) + 0.5)
			_pinned = p.global_position
			_next(1.5)
		10:
			var out_before := StormRun.outside_by(_pinned, games.storm.circle_centre(), games.storm.circle_radius())
			var out_now := StormRun.outside_by(p.global_position, games.storm.circle_centre(), games.storm.circle_radius())
			_check(out_now < out_before - 2.0, "pushed gently back in (%.1f -> %.1f blocks outside)" % [out_before, out_now])
			var id := games.storm.add_star(p.global_position + Vector3(0, 1.0, 0))
			if id >= 0:
				games.stars.show_star(id, games.storm.stars[id])
				Session.games_request_star(id)
			_check(games.storm.score >= 1, "a star for the team (score %d)" % games.storm.score)
			Session.games_request_stop()
			_check(not games.running(), "END GAME")
			_check(int(sandbox.meta.storm_best) == games.storm.best and games.storm.best >= 1, "the best is kept with the world (%d)" % sandbox.meta.storm_best)
			_next(GameRules.OVER_TIME + 0.5)
		11:
			_part = "photo"
			games.offer_photo()
			_check(sandbox.hud.team_photo_button.visible, "TEAM PHOTO shows after a boss")
			Session.games_request_photo()
			_check(not sandbox.hud.team_photo_button.visible, "and goes when tapped")
			_check(p.global_position.is_equal_approx(games._photo_spot(me)), "lined up")
			_next(TeamPhoto.SHOT_AT + 2.0)
		12:
			var photo: PhotoMode = sandbox.photo
			_check(photo.last_path != "", "the team photo was saved (%s)" % photo.last_path)
			photo.close()
			_part = ""
			_scan_cost(games, p)
			_report()
			_finish()


func _all_hidden(bots: BotDirector) -> bool:
	for b in bots.bots():
		if b.game_pose == BotFriend.POSE_NONE:
			return false
	return true


## One 16³ box searched for hiding spots on the real terrain, the way the host does it (a few a frame).
func _scan_cost(games: GamesDirector, p: Player) -> void:
	var origin := Vector3i(p.global_position.floor()) - Vector3i(8, 8, 8)
	var worst := 0
	var total := 0
	for i in 20:
		var t0 := Time.get_ticks_usec()
		games._find_spots(origin + Vector3i(i % 4, 0, i / 4) * 16, Vector3i.ONE * 16)
		var us := Time.get_ticks_usec() - t0
		total += us
		worst = maxi(worst, us)
	print("GAMES_SMOKE cost scan_box avg_ms=%.3f worst_ms=%.3f (boxes of 16^3; 3 a frame)" % [total / 20000.0, worst / 1000.0])


func _report() -> void:
	for part: String in _costs:
		var c: Array = _costs[part]
		var n := maxi(int(c[0]), 1)
		print("GAMES_SMOKE cost %s frames=%d avg_ms=%.2f worst_ms=%.2f process_avg_ms=%.2f process_worst_ms=%.2f" % [
			part, n, c[1] / n, c[2], c[3] / n, c[4]])
	for part: String in _director:
		var d: Array = _director[part]
		print("GAMES_SMOKE cost director %s steps=%d avg_us=%d worst_us=%d" % [part, d[0], d[1] / maxi(int(d[0]), 1), d[2]])
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	print("GAMES_SMOKE load %s" % (f.get_line() if f else "?"))


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("GAMES_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	if _done:
		return
	_done = true
	print("GAMES_SMOKE done failed=%d" % _fails.size())
	Music.reset()
	var tree := get_tree()
	tree.create_timer(0.2, true).timeout.connect(func() -> void: tree.quit(0 if _fails.is_empty() else 1))
