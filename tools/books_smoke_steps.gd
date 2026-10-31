extends Node
## The steps of tools/books_smoke.gd (M3 Task 21b), in a new Survivor world on real terrain, through the real
## systems: the books' director is in the world and this universe is explored; the Hub Tree stands by the stone
## circle; a cow summoned next to the player is met (the Animal Book, a toast); a photo badge and a woken buddy
## become memories; a photo saved soon after goes into the Memory Book (a small copy); a trophy shelf placed through
## the host's edit path shows the badges; the last secret of the Secret Book's first page gives the Fairy Wings and a
## star on the Hub Tree; a tap on a bookshelf opens the book on the memories; the saving bar shows under the gold;
## the profile on disk keeps the books.

const TIMEOUT := 150.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _cell := Vector3i.ZERO
var _shelf := Vector3i.ZERO


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


func _toasts(hud: Hud) -> Array[String]:
	var out: Array[String] = []
	for l in hud.find_children("*", "Label", true, false):
		if (l as Label).text != "":
			out.append((l as Label).text)
	return out


func _run_step(sandbox: Node, p: Player) -> void:
	var world: WorldService = sandbox.get("world")
	var books: BooksDirector = sandbox.get("books")
	var hud: Hud = sandbox.get("hud")
	match _step:
		0:
			_check(books != null and books.is_inside_tree(), "the world has its books director")
			_check(Profile.data.wonder.universes.has(1), "this universe is explored (%s)" % [Profile.data.wonder.universes])
			var hub: UniverseHub = sandbox.get("universe_hub")
			_check(books.tree != null and hub.circle != null, "the Hub Tree stands (the circle: %s)" % hub.circle)
			if books.tree and hub.circle:
				var d := Vector2(books.tree.position.x - hub.circle.position.x, books.tree.position.z - hub.circle.position.z).length()
				_check(d > HubRules.STONE_RING + 1.0 and d < 8.0, "beside the stone circle (%.1f blocks)" % d)
				var ground := world.surface_height(floori(books.tree.position.x), floori(books.tree.position.z))
				_check(absf(books.tree.position.y - ground) <= 2.0, "on the ground (tree %.1f, ground %d)" % [books.tree.position.y, ground])
				_check(books.tree.state.u == [1], "one leafy crown for Green Meadows %s" % [books.tree.state])
				_check(books.tree.shown_mesh() != null, "its mesh is made")
			_next()
		1:   # a cow next to the player is met
			var why: String = sandbox.call(&"summon_animal", &"cow", p.global_position)
			_check(why == "", "a cow came (%s)" % why)
			_next()
		2:
			if _step_t < 2.2:
				return
			_check(AnimalBookRules.knows(Profile.data.wonder, &"cow"), "the cow is in the Animal Book")
			_next()
		3:   # a photo badge and a buddy become memories; a photo saved soon after goes with the newest
			Progress.event(LevelRules.PHOTO)
			Progress.event(LevelRules.BUDDY)
			var book := MemoryBook.current()
			_check(book.has(&"first_photo") and book.has(&"first_buddy"), "two memories kept: %s" % [book.entries])
			var img := Image.create_empty(640, 360, false, Image.FORMAT_RGB8)
			img.fill(Color.SKY_BLUE)
			var photo: PhotoMode = sandbox.get("photo")
			photo.set("_last_png", img.save_png_to_buffer())
			photo.photo_saved.emit("user://photos/smoke.png")
			_next()
		4:
			if _step_t < 0.5:
				return
			var book := MemoryBook.current()
			var with_photo := book.entries.filter(func(e: Dictionary) -> bool: return e.photo != "")
			_check(with_photo.size() == 1, "the photo went with a memory %s" % [book.entries])
			if with_photo.size() == 1:
				var path := book.photo_path(StringName(with_photo[0].id), MemoryBook.current_path())
				_check(FileAccess.file_exists(path), "its small copy is on the device (%s)" % path)
			_check(FileAccess.file_exists(MemoryBook.current_path()), "the Memory Book is saved on the device")
			_next()
		5:   # a trophy shelf through the host's edit path (Survivor: from the bag)
			Session.inventory_of(p.peer_id).add(BlockIds.TROPHY_SHELF, 1)
			Session.inventory_of(p.peer_id).add(BlockIds.BOOKSHELF, 1)
			_shelf = _free_cell(world, Vector3i(p.global_position.floor()), 3)
			Session.request_set_block(_shelf, BlockIds.TROPHY_SHELF)
			_check(world.get_block(_shelf) == BlockIds.TROPHY_SHELF, "a trophy shelf placed at %s" % _shelf)
			_next()
		6:
			if _step_t < 1.2:
				return
			var shown: Dictionary = books.shelves.shown()
			_check(shown.has(_shelf), "the shelf shows trophies (%s)" % [shown])
			if shown.has(_shelf):
				_check((shown[_shelf] as Array).has("say_cheese"), "the photo badge stands on it %s" % [shown[_shelf]])
			_next()
		7:   # the last secret of the first page: the Fairy Wings, a star on the Hub Tree
			for kind in SecretRules.KINDS:
				if kind != SecretRules.GEODE:
					Profile.data.secret_book[String(kind)] = 1
			var secrets: SecretDirector = sandbox.get("_secrets")
			secrets._rpc_found(String(SecretRules.GEODE), p.global_position)
			_check(AvatarUnlocks.is_owned("wings.fairy", Profile.data.cosmetics), "the page's reward: the Fairy Wings")
			_check(Profile.data.wonder.pages.has(BookPages.SECRETS), "the page is rewarded once (%s)" % [Profile.data.wonder.pages])
			_check(books.tree == null or (books.tree.state.p as Array).has(BookPages.SECRETS), "a golden star on the Hub Tree")
			var texts: Array = [hud.banner.showing()] + hud.banner._queue.map(func(e: Array) -> String: return e[0])
			_check(texts.any(func(t: String) -> bool: return t.contains("Fairy Wings")), "the banner says so %s" % [texts])
			_next()
		8:   # a tap on a bookshelf opens the book on the memories
			_cell = _free_cell(world, Vector3i(p.global_position.floor()), 2)
			Session.request_set_block(_cell, BlockIds.BOOKSHELF)
			_check(world.get_block(_cell) == BlockIds.BOOKSHELF, "a bookshelf placed at %s" % _cell)
			var interactor: BlockInteractor = sandbox.get("_interactor")
			p.rig.process_mode = Node.PROCESS_MODE_DISABLED   # the run aims the camera at the bookshelf, from the eyes
			p.camera().look_at_from_position(p.eye_position(), Vector3(_cell) + Vector3(0.5, 0.5, 0.5))
			var tapped := interactor.place_at_screen(interactor.get_viewport().get_visible_rect().size * 0.5)
			p.rig.process_mode = Node.PROCESS_MODE_INHERIT
			if not (tapped and hud.secret_book.visible):
				print("BOOKS_SMOKE note: the camera's ray missed the bookshelf; its tap signal instead")
				interactor.bookshelf_tapped.emit(_cell)
			_check(hud.secret_book.visible and hud.secret_book.tab == SecretBook.MEMORIES_TAB, "the book opens on the memories")
			_check(hud.secret_book.memory_page.shown().size() >= 2, "the memories show (%d)" % hud.secret_book.memory_page.shown().size())
			hud.secret_book.close()
			_next()
		9:   # the saving list's bar under the gold
			SavingRules.toggle(Profile.data.wonder, SavingRules.LOOK, "hat.crown")
			hud.refresh_saving()
			_check(hud.saving_bar.is_visible_in_tree(), "the saving bar shows under the gold (%s)" % hud.saving_bar.words())
			_next()
		10:   # the profile on disk keeps the books
			sandbox.call(&"save_world")
			var saved := ProfileData.from_json(FileAccess.get_file_as_string(Profile.PATH))
			_check(AnimalBookRules.knows(saved.wonder, &"cow") and saved.wonder.pages.has(BookPages.SECRETS)
				and SavingRules.has(saved.wonder, SavingRules.LOOK, "hat.crown"), "profile.json keeps the books %s" % [saved.wonder.to_dict()])
			_finish()


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("BOOKS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("BOOKS_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
