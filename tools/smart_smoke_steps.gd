extends Node
## The steps of tools/smart_smoke.gd (M3 Task 7), on real terrain through the real systems (a new Sandbox
## world). A floor is laid next to the player first (O: the player's feet cell), then:
##   lever (2,0,0) and lamp (3,0,0); a powered doorway (6,0..1,0) with a button (7,0,0) and a plate (6,0,1);
##   teleport pads in the floor at (0,-1,3) and (12,-1,3);
##   a course in the floor: START (0,-1,-3), a coin (3,0,-3), CHECKPOINT (6,-1,-3), FINISH (10,-1,-3).

const TIMEOUT := 150.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _o := Vector3i.ZERO
var _bot: BotFriend
var _states: Array = []
var _stood := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.start_new_world = true
	Game.start_world(ModeRules.SANDBOX, true)
	Session.course_state_received.connect(func(s: Dictionary) -> void: _states.append(s))
	Session.magic_feedback.connect(func(text: String) -> void: print("SMART_SMOKE feedback: %s" % text))
	print("SMART_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox)


func _c(x: int, y: int, z: int) -> Vector3i:
	return _o + Vector3i(x, y, z)


func _top(x: int, y: int, z: int) -> Vector3:
	return CourseRules.top_of(_c(x, y, z))


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var w: WorldService = p.world
	match _step:
		0:
			_o = Vector3i(floori(p.global_position.x), roundi(p.global_position.y), floori(p.global_position.z))
			for x in range(-2, 15):
				for z in range(-5, 7):
					w.set_block(_c(x, -1, z), BlockIds.STONE)
					for y in range(0, 4):
						w.set_block(_c(x, y, z), BlockIds.AIR)
			p.global_position = Vector3(_o) + Vector3(-1.5, 0.0, 0.5)
			p.velocity = Vector3.ZERO
			_check(Session.request_set_block(_c(2, 0, 0), BlockIds.LEVER), "a lever placed through the host's edit path")
			for e: Array in [[_c(3, 0, 0), BlockIds.LAMP], [_c(6, 0, 0), BlockIds.POWERED_DOOR],
					[_c(6, 1, 0), BlockIds.POWERED_DOOR], [_c(7, 0, 0), BlockIds.BUTTON], [_c(6, 0, 1), BlockIds.PRESSURE_PLATE],
					[_c(0, -1, 3), BlockIds.TELEPORT_PAD], [_c(12, -1, 3), BlockIds.TELEPORT_PAD],
					[_c(0, -1, -3), BlockIds.START], [_c(3, 0, -3), BlockIds.COIN], [_c(6, -1, -3), BlockIds.CHECKPOINT],
					[_c(10, -1, -3), BlockIds.FINISH]]:
				w.set_block(e[0], e[1])
			_next(1.5)
		1:
			if not _stood:   # the floor's collision is rebuilt after the edits: stand the player on it again
				_stood = true
				p.global_position = Vector3(_o) + Vector3(-1.5, 0.0, 0.5)
				p.velocity = Vector3.ZERO
				_wait = 0.8
				return
			_check(p.global_position.distance_to(Vector3(_o) + Vector3(-1.5, 0.0, 0.5)) < 0.5,
				"the player stands on the new floor (%s)" % p.global_position)
			_check(_ray_through_doorway(p) == false, "a closed powered door stops a physics ray")
			_check(Session.request_smart_tap(_c(2, 0, 0)), "a tap on the lever goes through the host")
			_check(w.get_block(_c(2, 0, 0)) == BlockIds.LEVER_ON and w.get_block(_c(3, 0, 0)) == BlockIds.LAMP_ON,
				"the lever lights the lamp it touches")
			_check(Session.request_smart_tap(_c(7, 0, 0)), "a tap on the button")
			_check(w.get_block(_c(6, 0, 0)) == BlockIds.POWERED_DOOR_OPEN and w.get_block(_c(6, 1, 0)) == BlockIds.POWERED_DOOR_OPEN,
				"the button opens the whole doorway")
			_next(0.4)
		2:
			_check(_ray_through_doorway(p), "an open powered door lets a physics ray through (no mesh collision)")
			_next(1.0)
		3:
			_check(w.get_block(_c(7, 0, 0)) == BlockIds.BUTTON and w.get_block(_c(6, 0, 0)) == BlockIds.POWERED_DOOR,
				"a second later the button pops up and the doorway closes")
			p.global_position = Vector3(_c(6, 0, 1)) + Vector3(0.5, 0.125, 0.5)
			p.velocity = Vector3.ZERO
			_next(0.5)
		4:
			_check(w.get_block(_c(6, 0, 0)) == BlockIds.POWERED_DOOR_OPEN, "standing on the plate opens it")
			p.global_position = Vector3(_o) + Vector3(-1.5, 0.0, 1.5)
			_next(0.5)
		5:
			_check(w.get_block(_c(6, 0, 0)) == BlockIds.POWERED_DOOR, "stepping off closes it")
			p.global_position = _top(0, -1, 3)
			p.velocity = Vector3.ZERO
			_next(0.6)
		6:
			var d := Vector2(p._spawn_target.x - _top(12, -1, 3).x, p._spawn_target.z - _top(12, -1, 3).z).length()
			_check(d < 0.1, "a teleport pad carried the player to the other pad (%.2f away)" % d)
			_next(1.5)
		7:
			_check(p.is_spawned() and p.global_position.distance_to(_top(12, -1, 3)) < 1.0,
				"standing on the other pad, not sent straight back (%s)" % p.global_position)
			_states.clear()
			p.global_position = _top(0, -1, -3)
			p.velocity = Vector3.ZERO
			_next(0.4)
		8:
			_check(_last().get("armed", false), "on START: the clock is armed")
			p.global_position = Vector3(_c(1, 0, -3)) + Vector3(0.5, 0.0, 0.5)
			_next(0.8)
		9:
			_check(_last().get("on", false) and not _last().get("armed", true), "off START: the clock runs")
			var hud: Hud = sandbox.hud
			_check(hud.race_clock.visible, "the race clock shows")
			p.global_position = Vector3(_c(3, 0, -3)) + Vector3(0.5, 0.0, 0.5)
			_next(0.8)
		10:
			_check(int(_last().get("coins", 0)) == 1, "walking through the coin counts it (%s)" % _last().get("coins"))
			p.global_position = _top(6, -1, -3)
			_next(0.8)
		11:
			_check(_last().get("event", "") == "checkpoint", "the checkpoint")
			p.global_position = _top(6, -1, -3) + Vector3(0, -14, 0)
			_next(1.5)
		12:
			_check(p.global_position.distance_to(_top(6, -1, -3)) < 1.0, "a fall comes back to the checkpoint (%s)" % p.global_position)
			p.global_position = _top(10, -1, -3)
			p.velocity = Vector3.ZERO
			_next(0.8)
		13:
			var s := _last()
			_check(s.get("event", "") == "finish" and s.get("medal", "") == "gold",
				"FINISH: the first run's time and a gold medal (%s %s)" % [s.get("ms"), s.get("medal")])
			_check((sandbox.hud as Hud).race_clock.picture.kind == CourseRules.GOLD, "the race clock shows the medal")
			var courses: CourseDirector = sandbox.get_node("Courses")
			_check(courses.book.ghost(_c(0, -1, -3)) != null, "the best run is recorded for bots")
			var friends: BotDirector = sandbox.get("_bot_director")
			_bot = friends.add(BotRules.FIGHTER) if friends else null
			_check(_bot != null, "a bot friend joins")
			_check(friends != null and friends.race(_bot.bot_name) == "", "RACE ME!: it will race the course")
			_next(0.5)
		14:
			_check(_bot.is_racing() and not _bot.race_running(), "it waits by START")
			p.global_position = _top(0, -1, -3)
			p.velocity = Vector3.ZERO
			_next(0.4)
		15:
			p.global_position = Vector3(_c(1, 0, -3)) + Vector3(0.5, 0.0, 0.5)
			_next(0.3)
		16:
			_check(_bot.race_running(), "the child stepped off START: the bot runs too")
			_next(0.1)
		17:
			if _bot.is_racing() and _step_t < 20.0:
				return
			_check(not _bot.is_racing(), "the bot finished its run")
			var end := _top(10, -1, -3)
			_check(Vector2(_bot.global_position.x - end.x, _bot.global_position.z - end.z).length() < 1.5,
				"at the FINISH (%s)" % _bot.global_position)
			sandbox.call("save_world")
			var saved := WorldSaves.load_meta(Game.slot())
			_check(TeleportLinks.from_save(saved.smart.get("teleports")).partner_of(_c(0, -1, 3)) == _c(12, -1, 3),
				"the teleport pair is saved")
			var book := CourseBook.from_save(saved.smart.get("courses"))
			_check(book.best(_c(0, -1, -3)) > 0 and book.ghost(_c(0, -1, -3)) != null, "the course, its best time and run are saved")
			_next(1.0)
		18:
			_finish()


## A physics ray across the doorway, at knee height: true when nothing stops it.
func _ray_through_doorway(p: Player) -> bool:
	var from := Vector3(_c(6, 0, -2)) + Vector3(0.5, 0.5, 0.5)
	var to := Vector3(_c(6, 0, 1)) + Vector3(0.5, 0.5, 0.2)
	var q := PhysicsRayQueryParameters3D.create(from, to, Player.WORLD_COLLISION_MASK, [p.get_rid()])
	return p.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _last() -> Dictionary:
	return _states.back() if not _states.is_empty() else {}


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("SMART_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("SMART_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
