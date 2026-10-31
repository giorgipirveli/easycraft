extends Node
## The steps of tools/lab_smoke.gd (spec §23), in a new Survivor world on real terrain, through the real systems: the
## lab bench is crafted at a Workbench through the host's crafting (3 planks, 1 glass, 1 iron) and placed through the
## host's edit path; a tap on it opens the Lab over the world; float or sink needs its supplies from the bag (without
## them the Lab says what it needs, with them the bag gives 1 planks and 1 stone); the experiment is done by taps; the
## Lab Book has its star and the book's LAB tab shows it; Android Back closes the Lab; the profile on disk keeps it.

const TIMEOUT := 150.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _bench := Vector3i.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 1
	Game.start_new_world = true
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
	_run_step(sandbox, sandbox.player)


## An air cell with solid ground under it and air above, `r` blocks from the feet.
func _free_cell(world: WorldService, feet: Vector3i, r: int) -> Vector3i:
	for d: Vector3i in [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r)]:
		for dy in range(-2, 4):
			var c := feet + d + Vector3i(0, dy, 0)
			if world.get_block(c) == BlockIds.AIR and world.get_block(c + Vector3i.UP) == BlockIds.AIR \
					and BlockIds.is_solid(world.get_block(c + Vector3i.DOWN)):
				return c
	return feet + Vector3i(r, 0, 0)


func _run_step(sandbox: Node, p: Player) -> void:
	var world: WorldService = sandbox.get("world")
	var hud: Hud = sandbox.get("hud")
	var inv := Session.inventory_of(p.peer_id)
	match _step:
		0:   # a Workbench beside the player, then the bench crafted at it
			if _step_t < 1.0:
				return
			for id: int in [BlockIds.PLANKS, BlockIds.STONE, BlockIds.GLASS, BlockIds.IRON]:   # the starter kit's planks
				inv.take(id, inv.count(id))
			inv.add(BlockIds.CRAFTING_TABLE, 1)
			var table := _free_cell(world, Vector3i(p.global_position.floor()), 2)
			Session.request_set_block(table, BlockIds.CRAFTING_TABLE)
			_check(world.get_block(table) == BlockIds.CRAFTING_TABLE, "a Workbench placed at %s" % table)
			for id: int in [BlockIds.PLANKS, BlockIds.GLASS, BlockIds.IRON]:
				inv.add(id, 3 if id == BlockIds.PLANKS else 1)
			var made := Session.host_craft(p.peer_id, &"lab_bench")
			_check(bool(made.ok), "the lab bench crafted at the Workbench (%s)" % [made])
			_check(inv.count(BlockIds.LAB_BENCH) == 1, "the bench is in the bag")
			_check(inv.count(BlockIds.PLANKS) == 0 and inv.count(BlockIds.GLASS) == 0 and inv.count(BlockIds.IRON) == 0,
				"3 planks, 1 glass and 1 iron went into it")
			_next()
		1:   # placed through the host's edit path, then a tap on it opens the Lab
			_bench = _free_cell(world, Vector3i(p.global_position.floor()), -3)   # the other way from the Workbench
			Session.request_set_block(_bench, BlockIds.LAB_BENCH)
			_check(world.get_block(_bench) == BlockIds.LAB_BENCH, "the bench placed at %s" % _bench)
			var interactor: BlockInteractor = sandbox.get("_interactor")
			p.rig.process_mode = Node.PROCESS_MODE_DISABLED   # the run aims the camera at the bench, from the eyes
			p.camera().look_at_from_position(p.eye_position(), Vector3(_bench) + Vector3(0.5, 0.5, 0.5))
			var tapped := interactor.place_at_screen(interactor.get_viewport().get_visible_rect().size * 0.5)
			p.rig.process_mode = Node.PROCESS_MODE_INHERIT
			var panel: LabPanel = sandbox.get("lab_panel")
			if not (tapped and panel != null and panel.visible):
				print("LAB_SMOKE note: the camera's ray missed the bench; its tap signal instead")
				interactor.lab_bench_tapped.emit(_bench)
				panel = sandbox.get("lab_panel")
			_check(panel != null and panel.visible, "a tap on the bench opens the Lab")
			_check(panel != null and panel.get_parent() == hud, "over the HUD")
			_check(panel != null and panel.screen.page == LabScreen.LIST, "on its list of experiments")
			_check(hud.look_area.blockers.has(panel), "a tap on the Lab never builds behind it")
			_next()
		2:   # float or sink: the supplies come from the bag
			var lab: LabScreen = (sandbox.get("lab_panel") as LabPanel).screen
			lab.open("float_sink")
			var w := lab.predict_answer
			for i in w.picked.size():
				w.tap(i)
			lab.try_button.pressed.emit()
			_check(lab.page == LabScreen.PREDICT, "no supplies in the bag: still predicting")
			_check(lab.note.text.contains("1 Planks and 1 Stone"), "the Lab says what it needs (%s)" % lab.note.text)
			inv.add(BlockIds.PLANKS, 2)
			inv.add(BlockIds.STONE, 1)
			lab.try_button.pressed.emit()
			_check(lab.page == LabScreen.TRY, "with them: the tank")
			_check(inv.count(BlockIds.PLANKS) == 1 and inv.count(BlockIds.STONE) == 0, "the bag gave 1 planks and 1 stone")
			for b: Button in lab.view.thing_buttons:
				b.pressed.emit()
			_check(lab.model.done(), "every thing dropped by taps")
			lab.what_button.pressed.emit()
			_check(lab.page == LabScreen.WHY, "what happened and why")
			_check(Profile.data.lab.has_star("float_sink"), "the Lab Book's star")
			_check(Profile.data.lab.guess("float_sink") != null and not Profile.data.lab.matched("float_sink"),
				"the guess is kept (everything floats: it did not match, and nothing says it was wrong)")
			_next()
		3:   # Android Back closes the Lab; the book's LAB tab shows the star
			sandbox.call(&"go_back")
			var panel: LabPanel = sandbox.get("lab_panel")
			_check(not panel.visible, "Android Back closes the Lab")
			hud.secret_book.open_tab(SecretBook.LAB_TAB)
			var i := LabExperiments.ids().find("float_sink")
			_check(hud.secret_book.lab_page.tile_star(i), "the book's LAB tab: a star on float or sink")
			hud.secret_book.close()
			_next()
		4:   # the profile on disk keeps the Lab Book
			sandbox.call(&"save_world")
			Profile.save()
			var saved := ProfileData.from_json(FileAccess.get_file_as_string(Profile.PATH))
			_check(saved.lab.has_star("float_sink"), "profile.json keeps the Lab Book %s" % [saved.lab.to_dict()])
			_finish()


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("LAB_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("LAB_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
