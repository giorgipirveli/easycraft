extends Node
## The steps of tools/gifts_smoke.gd (M4 Wave 3, agent I), on real terrain through the real systems:
## Hopper's new Sandbox world with this device's OnlineService on the game's fake server; SHARE in the
## MORE panel; a picked build sent to Mia (who opens it into a stamp); Hopper's showcase put up; Mia's
## bottle floating up near Hopper and opened with a tap; two buddies of two owners on a playdate; then
## Mia visits Hopper's showcase (the visit scene) and leaves a sticker. MEASURE lines time the picker,
## the showcase snapshot, the visit's arrival and its frames.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const TIMEOUT := 240.0

var server: RefCounted
var hopper: OnlineService
var mia: OnlineService
var _t := 0.0
var _step := -1
var _step_t := 0.0
var _fails: Array[String] = []
var _tower: Array[Vector3i] = []
var _frames: Array[float] = []
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup()


func _setup() -> void:
	_busy = true
	var dir := OS.get_user_data_dir()
	server = FakeServer.new()
	server.make_account("smoke-hopper", "Hopper")
	server.make_account("smoke-mia", "Mia_2")
	server.befriend(server.id_of("Hopper"), server.id_of("Mia_2"))
	hopper = _service("smoke-hopper", "Hopper", dir)
	mia = _service("smoke-mia", "Mia_2", dir)
	add_child(mia)
	Session.use_online_service(hopper)
	_check(await hopper.sign_in() == "", "Hopper signs in (the fake server)")
	_check(await mia.sign_in() == "", "Mia signs in")
	await hopper.refresh_friends()
	await mia.refresh_friends()
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	_step = 0
	_busy = false


func _service(device: String, username: String, dir: String) -> OnlineService:
	var s := OnlineService.new()
	s.name = "Smoke_" + username
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.save_profile = func() -> void: pass
	s.prefs_path = dir.path_join(device + "_online.json")
	s.gift_book = GiftStampBook.new()
	s.gift_book_path = dir.path_join(device + "_gifts.json")
	s.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	return s


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	if _busy or _step < 0:
		return
	_step_t += delta
	var scene := get_tree().current_scene
	if _step < 7:
		if scene == null or scene.get("player") == null or not (scene.player as Player).is_spawned():
			return
	_busy = true
	await _run_step(scene, delta)
	_busy = false


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _run_step(scene: Node, _delta: float) -> void:
	match _step:
		0:
			var sb: TouchButton = scene.get("share_button")
			_check(sb != null and sb.visible, "SHARE shows in the MORE panel (signed in, friends allowed, my world)")
			_check(sb != null and scene.hud.more.grid.get_children().has(sb), "SHARE sits in the MORE box")
			var p: Player = scene.player
			var world: WorldService = scene.world
			var c := _free_cell(world, Vector3i(p.global_position.floor()))
			_tower = [c, c + Vector3i.UP, c + Vector3i(0, 2, 0)]
			for cell in _tower:
				Session.request_set_block(cell, BlockIds.BRICK)
			_check(world.get_block(_tower[2]) == BlockIds.BRICK, "a tower of three bricks at %s" % c)
			_next()
		1:   # GIFT A BUILD: pick the tower, send it to Mia
			var panel: SharePanel = scene.get("share_panel")
			panel.open()
			panel.start_pick()
			var t0 := Time.get_ticks_usec()
			panel.pick_cell(_tower[1])
			print("MEASURE pick a %d-block build %.2f ms" % [(panel.picked.get("blocks", {}) as Dictionary).size(),
				(Time.get_ticks_usec() - t0) / 1000.0])
			_check((panel.picked.get("blocks", {}) as Dictionary).size() == 3, "the tower is picked (%s)" % panel.message.text)
			_check(panel.outline.mesh != null, "it glows")
			panel.show_friends()
			(panel.find_child("Friend_Mia_2", true, false) as Button).pressed.emit()
			await _until(func() -> bool: return not panel.visible, 5.0)
			var sent: Array = server.gifts.get(server.id_of("Mia_2"), [])
			_check(sent.size() == 1 and BuildCodec.count_of(sent[0].build) == 3, "Mia's present is on the server")
			await mia.refresh_gifts()
			var slot := -1
			if not mia.gifts.is_empty():
				var opened: Dictionary = await mia.open_gift(mia.gifts[0].id)
				slot = int(opened.slot)
			_check(slot >= 0 and mia.gift_book.blocks_of(slot).size() == 3, "Mia opens it into a stamp of three bricks")
			_next()
		2:   # MY SHOWCASE: the area around Hopper
			var panel: SharePanel = scene.get("share_panel")
			panel.open()
			panel.start_area()
			var t0 := Time.get_ticks_usec()
			var text := ShowcaseArea.snapshot_buffer(scene.world.copy_box(panel.area.origin, panel.area.size))
			print("MEASURE showcase snapshot 32^3: %.1f ms, %d chars, %d blocks" % [(Time.get_ticks_usec() - t0) / 1000.0,
				text.length(), BuildCodec.count_of(text)])
			var origin: Vector3i = panel.area.origin
			panel.publish()
			await _until(func() -> bool: return not panel.visible, 10.0)
			var up: Dictionary = server.showcases.get(server.id_of("Hopper"), {})
			_check(not up.is_empty(), "the showcase is on the server (%s)" % panel.message.text)
			if not up.is_empty():
				var shown := BuildCodec.decode(up.build, BuildCodec.SHOWCASE)
				_check(shown.get(_tower[0] - origin) == BlockIds.BRICK and shown.get(_tower[2] - origin) == BlockIds.BRICK,
					"the whole tower is in it")
				_showcase_bricks = shown.values().count(BlockIds.BRICK)
			_next()
		3:   # Mia's bottle floats up near Hopper; a tap opens it
			_check(await mia.send_bottle(hopper.backend.user_id(), "Nice build!") == "", "Mia sends a bottle")
			var shore: BottleShore = scene.get("bottles")
			await _until(func() -> bool: return shore.bottles().size() == 1, 10.0)
			_check(shore.bottles().size() == 1, "it floats up near Hopper")
			if shore.bottles().size() == 1:
				var b := shore.bottles()[0]
				var d := b.global_position.distance_to(scene.player.global_position)
				print("GIFTS_SMOKE bottle %s at %s, %.1f blocks away" % ["on the water" if b.floating else "on land",
					b.global_position, d])
				_check(d < 40.0, "near the player")
				SecretTaps.use(b, get_tree())
				var card: BottleCard = scene.get("bottle_card")
				await _until(func() -> bool: return card.visible, 5.0)
				_check(card.visible and card.result.get("bottle", {}).get("phrase", "") == "Nice build!", "the card says 'Nice build!'")
				card.close()
			_next()
		4:   # two buddies of two owners: a playdate
			var p: Player = scene.player
			var at := p.global_position + Vector3(4, 1, 0)
			var blocks := {Vector3i.ZERO: BlockIds.CRYSTAL, Vector3i(0, 1, 0): BlockIds.CRYSTAL}
			scene.call(&"_spawn_buddy", blocks, at, 0.0, "Sparkly", p.peer_id)
			scene.call(&"_spawn_buddy", blocks, at + Vector3(6, 0, 0), 0.0, "Glowy", 99)   # a friend's
			var dates: PlaydateDirector = scene.call(&"playdates")
			await _until(func() -> bool: return dates.shown.any(func(e: Array) -> bool: return e[0] == "dance"), 20.0)
			_check(dates.shown.any(func(e: Array) -> bool: return e[0] == "wave"), "they notice each other and wave")
			_check(dates.shown.any(func(e: Array) -> bool: return e[0] == "dance"), "they meet and dance (%s)" % [dates.shown])
			var t0 := Time.get_ticks_usec()
			for i in 100:
				dates.step()
			print("MEASURE playdate step (2 buddies): %.3f ms" % ((Time.get_ticks_usec() - t0) / 100000.0))
			_next()
		5:   # Mia visits Hopper's showcase
			var r: Dictionary = await mia.showcase_of(hopper.backend.user_id())
			_check(r.text == "" and not (r.showcase as Dictionary).is_empty(), "Mia gets Hopper's showcase (%s)" % r.text)
			hopper.sign_out()   # Hopper goes away; Mia visits
			Session.use_online_service(mia)
			_step_t = 0.0
			_visit_start = Time.get_ticks_msec()
			Session.start_visit(r.showcase)
			_next()
		6:
			_next()
		7:   # the visit scene
			var v := scene as VisitWorld
			if v == null or v.player == null or not v.player.is_spawned():
				return
			print("MEASURE visit: the visitor stands on the island %d ms after VISIT" % (Time.get_ticks_msec() - _visit_start))
			var o := v.generator.origin
			var bricks := 0
			for x in v.generator.size.x:
				for y in v.generator.size.y:
					for z in v.generator.size.z:
						if v.world.get_block(o + Vector3i(x, y, z)) == BlockIds.BRICK:
							bricks += 1
			_check(bricks == _showcase_bricks and bricks >= 3, "Hopper's tower stands in the visit (%d of %d bricks)" % [bricks,
				_showcase_bricks])
			_check(v.sign_label.text.contains("Hopper"), "Hopper's name on the sign")
			_check(Session.world == null, "read-only: the visit world is not Session's")
			_frames.clear()
			_next()
		8:   # three seconds in the visit: frame times
			_frames.append(_delta * 1000.0)
			if _step_t < 3.0:
				return
			var worst := 0.0
			var total := 0.0
			for f in _frames:
				worst = maxf(worst, f)
				total += f
			print("MEASURE visit frames: %d frames, avg %.1f ms, worst %.1f ms (headless, load %s)" % [_frames.size(),
				total / maxf(_frames.size(), 1), worst, _load()])
			var v := scene as VisitWorld
			(v.panel.find_child("Sticker", true, false) as Button).pressed.emit()
			(v.panel.find_child("Sticker_star", true, false) as Button).pressed.emit()
			await _until(func() -> bool: return (server.guestbooks.get(server.id_of("Hopper"), []) as Array).size() == 1, 5.0)
			_check((server.guestbooks.get(server.id_of("Hopper"), []) as Array).size() == 1, "Mia's star is in Hopper's guestbook")
			_next()
		_:
			_finish()


var _visit_start := 0
var _showcase_bricks := 0


func _until(cond: Callable, seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call() and Time.get_ticks_msec() < end:
		await get_tree().process_frame


## A column of three free cells on solid ground near `feet`, nothing buildable around it.
func _free_cell(world: WorldService, feet: Vector3i) -> Vector3i:
	for r in range(3, 7):
		for d: Vector3i in [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r)]:
			for dy in range(-2, 6):
				var c := feet + d + Vector3i(0, dy, 0)
				if not BlockIds.is_solid(world.get_block(c + Vector3i.DOWN)) or CaptureRules.is_capturable(world.get_block(c + Vector3i.DOWN)):
					continue
				var clear := true
				for y in 4:
					for n: Vector3i in [Vector3i.ZERO, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
						if world.get_block(c + Vector3i(0, y, 0) + n) != BlockIds.AIR:
							clear = false
				if clear:
					return c
	return feet + Vector3i(3, 0, 0)


func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


func _check(ok: bool, what: String) -> void:
	print("GIFTS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("GIFTS_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Session.use_online_service(null)
	get_tree().quit(0 if _fails.is_empty() else 1)
