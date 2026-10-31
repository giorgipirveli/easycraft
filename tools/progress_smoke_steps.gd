extends Node
## The steps of tools/progress_smoke.gd (M3 Task 12), in a new Survivor world on real terrain, through
## the real systems (Session requests, the host's hooks, the HUD and the pause menu): the world counts
## progress and sets the name tag code; two planks placed count; waking them counts a buddy; three
## goblins beaten next to the player count and finish the picked goal "Beat 3 goblins", whose 40 gold the
## host pays; a dog tamed with taps counts; the dog brings a present after active play (the HUD's banner);
## the present opens on the pause menu's BOARD and the host gives 2 lanterns; a new place counts; a secret
## found and a photo saved count; the profile on disk keeps it all.

const TIMEOUT := 180.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _start := {}
var _cells: Array[Vector3i] = []
var _gold := 0
var _dog: Animal
var _taps := 0
var _goals: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 1
	Game.start_new_world = true
	Progress.goal_done.connect(func(goal_id: StringName, gold: int) -> void: _goals.append([goal_id, gold]))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	_step_t += delta
	_run_step(sandbox, sandbox.player, delta)


func _count(kind: StringName) -> int:
	return Progress.data().count(kind)


## A spot for a two-block build near `feet`: two cells of air whose neighbours hold nothing the wand would
## take along (a tree next to it would make the build too big to wake).
func _free_cell(world: WorldService, feet: Vector3i) -> Vector3i:
	for r in range(2, 5):
		for d: Vector3i in [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r)]:
			for dy in range(-2, 6):
				var c := feet + d + Vector3i(0, dy, 0)
				if world.get_block(c) != BlockIds.AIR or world.get_block(c + Vector3i.UP) != BlockIds.AIR \
						or not BlockIds.is_solid(world.get_block(c + Vector3i.DOWN)):
					continue
				var clear := true
				for cell: Vector3i in [c, c + Vector3i.UP]:
					for n: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.FORWARD, Vector3i.BACK]:
						if CaptureRules.is_capturable(world.get_block(cell + n)) and cell + n != c + Vector3i.UP:
							clear = false
				if clear:
					return c
	return feet + Vector3i(2, 0, 0)


func _button(root: Node, prefix: String) -> Button:
	for b: Button in root.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and b.text.begins_with(prefix):
			return b
	return null


func _named(root: Node, node_name: String) -> Button:
	var found := root.find_children(node_name, "Button", true, false)
	return found[0] as Button if found.size() > 0 else null


func _run_step(sandbox: Node, p: Player, delta: float) -> void:
	var world: WorldService = sandbox.get("world")
	match _step:
		0:
			var dir: ProgressDirector = sandbox.get("progress_director")
			_check(dir != null and dir.is_inside_tree(), "the world has its ProgressDirector")
			_check(Progress.is_counting(), "progress counts while the world is played")
			_check(p.progress_tag != "" and p.progress_tag == Progress.tag(), "the name tag code is set (%s)" % p.progress_tag)
			var goals: Array = Progress.data().board.map(func(s: Dictionary) -> String: return str(s.goal))
			_check(goals.size() == BoardRules.SLOTS and goals[0] != "", "the board has its goals %s" % [goals])
			_next()
		1:   # two planks in front of the player, through the host's edit path (Survivor: from the kit)
			_cells = []
			var c := _free_cell(world, Vector3i(p.global_position.floor()))
			_cells.append(c)
			_cells.append(c + Vector3i.UP)
			_start = {"blocks": _count(LevelRules.BLOCK)}
			for cell in _cells:
				Session.request_set_block(cell, BlockIds.PLANKS)
			_check(world.get_block(_cells[0]) == BlockIds.PLANKS and world.get_block(_cells[1]) == BlockIds.PLANKS,
				"two planks placed at %s" % _cells[0])
			_check(_count(LevelRules.BLOCK) == int(_start.blocks) + 2, "blocks placed: %d more" % (_count(LevelRules.BLOCK) - int(_start.blocks)))
			_next()
		2:   # the wand wakes them
			var before := _count(LevelRules.BUDDY)
			var said: Array[String] = []
			var hear := func(text: String) -> void: said.append(text)
			Session.magic_feedback.connect(hear)
			Session.request_spark(_cells[0])
			Session.magic_feedback.disconnect(hear)
			_check(_count(LevelRules.BUDDY) == before + 1, "a buddy woken counts (%d) %s" % [_count(LevelRules.BUDDY), said])
			_next()
		3:   # three goblins beaten next to the player, with "Beat 3 goblins" on the board
			_check(Progress.pick_goal(0, &"beat_goblins"), "the goal 'Beat 3 goblins' is picked")
			_gold = Profile.data.survivor_gold
			_start = {"goblins": _count(&"monster_defeated/goblin")}
			for i in 3:
				sandbox.call(&"summon_monster", &"goblin", 1, p.global_position)
			_next()
		4:
			if _step_t < 0.5:
				return
			var hit := 0
			for n in get_tree().get_nodes_in_group(&"monsters"):
				var m := n as Monster
				if m and m.kind == &"goblin" and m.global_position.distance_to(p.global_position) < 20.0:
					m.take_hit(9999, p.eye_position(), Vector3.ZERO)
					hit += 1
			_check(hit >= 3, "%d goblins came and were beaten" % hit)
			_next()
		5:
			if _step_t < 0.5:
				return
			var n := _count(&"monster_defeated/goblin") - int(_start.goblins)
			_check(n >= 3, "goblins beaten near the player count: %d" % n)
			var done := _goals.filter(func(g: Array) -> bool: return g[0] == &"beat_goblins")
			_check(done.size() == 1 and int(done[0][1]) == 40, "the goal is done with its 40 gold (%s)" % [done])
			_check(Profile.data.survivor_gold >= _gold + 40, "the host paid the goal's gold (%d -> %d)" % [_gold, Profile.data.survivor_gold])
			_next()
		6:   # a dog to tame
			var why: String = sandbox.call(&"summon_animal", &"dog", p.global_position)
			_dog = null
			for n in (sandbox.get("_animals") as Node).get_children():
				var a := n as Animal
				if a and a.species == &"dog" and not a.is_pet() and (_dog == null
						or a.global_position.distance_to(p.global_position) < _dog.global_position.distance_to(p.global_position)):
					_dog = a
			_check(_dog != null, "a dog came (%s)" % why)
			_start = {"tamed": _count(&"animal_tamed/dog")}
			_taps = 0
			_next()
		7:
			if _dog == null or not is_instance_valid(_dog):
				_finish()
				return
			p.global_position = _dog.global_position + Vector3(1.2, 0.2, 0.0)
			p.velocity = Vector3.ZERO
			if _step_t > 0.25 * (_taps + 1) and _taps < 8 and not _dog.is_pet():
				Session.request_pet(_dog.name)
				_taps += 1
			if _dog.is_pet():
				_check(_count(&"animal_tamed/dog") == int(_start.tamed) + 1, "a dog tamed with %d taps counts" % _taps)
				_next()
			elif _step_t > 5.0:
				_check(false, "the dog was not tamed after %d taps" % _taps)
				_next()
		8:   # nearly time for a present; the dog next to the player (a goblin may have knocked it out meanwhile)
			if p.knocked_out:
				return
			var d := Progress.data()
			d.present_waiting = false
			d.present_s = PresentRules.interval_s(d.presents) - 3.0
			_start = {"centre": p.global_position}
			if is_instance_valid(_dog):
				_dog.global_position = p.global_position + Vector3(1.5, 0.3, 0.0)
			_next()
		9:   # keep playing: walk a small circle (two metres across in six seconds), the dog near
			var a := _step_t * TAU / 6.0
			p.global_position = (_start.centre as Vector3) + Vector3(cos(a), 0.0, sin(a)) * 2.0
			p.velocity = Vector3.ZERO
			if Progress.data().present_waiting:
				var hud: Hud = sandbox.get("hud")
				var texts: Array = [hud.banner.showing()] + hud.banner._queue.map(func(e: Array) -> String: return e[0])
				_check(texts.any(func(t: String) -> bool: return t.contains("brought you a present")),
					"the pet's present came after active play (%.1f s): %s" % [_step_t, texts])
				_next()
			elif _step_t > 12.0:
				var dir: ProgressDirector = sandbox.get("progress_director")
				_check(false, "no present after 12 s of play (clock %.1f of %.1f; pet near: '%s', knocked out %s, asleep %s)"
					% [Progress.data().present_s, PresentRules.interval_s(Progress.data().presents), dir.pet_near.call(),
					p.knocked_out, p.sleeping])
				_next()
		10:   # open it on the pause menu's BOARD
			(sandbox.get("pause_menu") as PauseMenu).open()
			_next()
		11:
			if _step_t < 0.3:
				return
			var menu: PauseMenu = sandbox.get("pause_menu")
			var board := _button(menu, "BOARD")
			_check(board != null, "the pause menu has BOARD")
			if board:
				board.pressed.emit()
			_next()
		12:
			if _step_t < 0.3:
				return
			var menu: PauseMenu = sandbox.get("pause_menu")
			var present := _named(menu, "Present")
			_check(present != null, "the present waits on the board")
			if present:
				present.pressed.emit()
			_next()
		13:
			if _step_t < 0.3:
				return
			var menu: PauseMenu = sandbox.get("pause_menu")
			var inv := Session.inventory_of(p.peer_id)
			var before := inv.count(BlockIds.LANTERN)
			var gift := _named(menu, "Gift_lanterns")
			_check(gift != null, "three gifts to pick from (lanterns among them)")
			if gift:
				gift.pressed.emit()
			_check(inv.count(BlockIds.LANTERN) == before + 2, "the host gave 2 lanterns (%d -> %d)" % [before, inv.count(BlockIds.LANTERN)])
			_check(not Progress.data().present_waiting, "the present is opened")
			menu.close()
			_next()
		14:   # a new place (two areas away), then back
			_start = {"areas": _count(LevelRules.EXPLORED), "pos": p.global_position}
			p.global_position += Vector3(ProgressDirector.AREA * 2, 0.0, 0.0)
			_next()
		15:
			if _step_t < 2.5:
				return
			_check(_count(LevelRules.EXPLORED) >= int(_start.areas) + 1, "a new place counts (%d)" % _count(LevelRules.EXPLORED))
			p.global_position = _start.pos
			_next()
		16:   # a secret found (the director's own find path) and a photo saved reach the bus
			var secrets: SecretDirector = sandbox.get("_secrets")
			var before := _count(&"secret_found/geode")
			secrets._rpc_found(String(SecretRules.GEODE), p.global_position)
			_check(_count(&"secret_found/geode") == before + 1, "a geode found counts (%d)" % _count(&"secret_found/geode"))
			var photos := _count(LevelRules.PHOTO)
			(sandbox.get("photo") as PhotoMode).photo_saved.emit("user://photos/smoke.png")
			_check(_count(LevelRules.PHOTO) == photos + 1, "a photo saved counts (%d)" % _count(LevelRules.PHOTO))
			_next()
		17:   # the profile on disk keeps it all
			sandbox.call(&"save_world")
			var text := FileAccess.get_file_as_string(Profile.PATH)
			var saved := ProfileData.from_json(text)
			_check(saved.progress.count(LevelRules.BLOCK) >= 2 and saved.progress.count(&"animal_tamed/dog") >= 1
				and saved.progress.count(&"goal_done") >= 1, "profile.json keeps the progress (XP %d, level %d, badges %s)"
				% [saved.progress.xp, saved.progress.level(), saved.progress.achievements])
			print("PROGRESS_SMOKE counts %s" % [saved.progress.counts])
			_finish()


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("PROGRESS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("PROGRESS_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
