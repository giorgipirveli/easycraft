extends Node
## The steps of tools/quest_smoke.gd (owner #45a), in a new Survivor world of the Sandstorm Desert on real
## terrain, through the real systems (the sandbox's wiring, the interactor's taps, the SecretDirector's find
## path, the host's gold, the HUD's MORE panel): Zara the explorer stands by the spawn where QuestRules puts
## her, on the ground, with a "!" bubble; a tap on her opens her card; LET'S GO starts "The golden scarab"
## and the arrow points at the nearest buried treasure; an explorer bot friend asked to "follow the arrow"
## leads the way; the treasure found moves the story on; walking to the pyramid does the "follow" step; the
## pyramid solved turns the bubble to "?"; walking back to Zara ends it: the keepsake, the title (on the
## name tag), 200 gold from the host, a place; the quest book and the Secret Book's keepsakes page show it;
## the profile on disk keeps it.

const TIMEOUT := 240.0
const UNIVERSE := 2

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _gold := 0
var _zara: QuestGiver
var _target := Vector3.INF
var _bot: BotFriend


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = UNIVERSE
	Game.start_new_world = true
	Profile.data.universe_unlocked = maxi(Profile.data.universe_unlocked, UNIVERSE)
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


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _run_step(sandbox: Node, p: Player) -> void:
	var q: QuestDirector = sandbox.quests()
	var d := Progress.data()
	match _step:
		0:
			_check(q != null and q.name == "Quests" and q.mode == ModeRules.SURVIVOR and q.universe == UNIVERSE,
				"the world's quest director")
			_check(q.more_button != null and (sandbox.hud as Hud).more.buttons().has(q.more_button),
				"QUESTS is in the MORE panel")
			_gold = Profile.data.survivor_gold
			_next()
		1:
			if not q.givers.has(&"zara"):
				if _step_t > 20.0:
					_check(false, "Zara never came")
					_finish()
				return
			_zara = q.givers[&"zara"]
			var shape: MeadowsShape = sandbox.world.generator_shape()
			var spot := QuestRules.giver_for_world(shape.seed, shape, shape.spawn_column())
			_check(_zara.global_position == spot.pos, "Zara stands at her spot %s" % spot.pos)
			var spawn := shape.spawn_column()
			var dist := Vector2(spot.pos.x - spawn.x, spot.pos.z - spawn.y).length()
			_check(dist >= 12.0 and dist <= 20.0, "by the spawn (%.1f blocks)" % dist)
			var ground := shape.height_at(floori(spot.pos.x), floori(spot.pos.z))
			_check(absf(spot.pos.y - ground) < 0.01, "on the ground (%d)" % ground)
			q.tick()
			_check(_zara.bubble_text() == QuestGiver.BUBBLE_NEW, "a '!' over her head")
			p.spawn_at(_zara.global_position + Vector3(0, 0.5, 3.0))
			_next()
		2:
			if _step_t < 0.5:
				return
			var to := _zara.global_position - p.global_position
			p.rig.yaw = atan2(-to.x, -to.z)
			if _step_t < 1.0:
				return
			var cam := p.camera()
			var chest := _zara.global_position + Vector3(0, QuestGiver.CHEST_HEIGHT, 0)
			var tapped := false
			if not cam.is_position_behind(chest):
				tapped = (p.get_node("BlockInteractor") as BlockInteractor).place_at_screen(cam.unproject_position(chest))
			_check(tapped and q.card.is_open(), "a tap on Zara opens her card")
			if not q.card.is_open():
				q.open_card(&"zara")
			_check(_has_text(q.card, "The golden scarab") and _has_text(q.card, "LET'S GO!"), "her card tells the story")
			(q.card.find_children("LetsGo", "Button", true, false)[0] as Button).pressed.emit()
			_check(d.quests.active == &"zara_scarab", "LET'S GO starts it")
			_next()
		3:
			q.tick()
			if not q.arrow.is_pointing():
				if _step_t > 20.0:
					_check(false, "the arrow never pointed")
					_finish()
				return
			_target = q.arrow.target
			var near := QuestDirector.nearest_place(q.secrets.rules, &"treasure", p.global_position, {}, QuestDirector.TARGET_RADIUS * 2)
			_check(_target == near, "the arrow points at the nearest buried treasure (%s)" % _target)
			var bots: BotDirector = sandbox.get_node_or_null("BotDirector")
			_bot = bots.add(BotRules.EXPLORER) if bots else null
			_next()
		4:
			if _step_t < 1.0:
				return
			if _bot:
				_bot.clock = 100.0
				_bot._last_said = -INF
				Session.bot_talk_reset()
				Session._host_bot_talk(p.peer_id, "follow the arrow")
				_check(_bot.talk_order() == BotRules.GUIDE and _bot._talk_point.distance_to(_target) < 2.0,
					"an explorer friend leads the way to the treasure (%s to %s)" % [_bot.talk_order(), _bot._talk_point])
			else:
				_check(false, "no bot friend")
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			secrets._rpc_found(String(SecretRules.TREASURE), _target)   # the Secret Director's own find path
			_check(QuestRules.current_step(d, &"zara_scarab").get("type", &"") == QuestRules.REACH,
				"the treasure found: now follow it to the pyramid")
			_next()
		5:
			q.tick()
			if not q.arrow.is_pointing() or q.arrow.target == _target:
				if _step_t > 20.0:
					_check(false, "no arrow to the pyramid")
					_finish()
				return
			_target = q.arrow.target
			_check(q.arrow.what == "the puzzle temple", "the arrow shows the pyramid ('%s')" % q.arrow.what)
			p.spawn_at(_target + Vector3(6, 25, 0))
			_next()
		6:
			q.tick()
			if QuestRules.current_step(d, &"zara_scarab").get("type", &"") != QuestRules.DO:
				if _step_t > 30.0:
					_check(false, "walking to the pyramid did not count (at %s, target %s)" % [p.global_position, _target])
					_finish()
				return
			_check(true, "walked to the pyramid (%.1f blocks from it)" % Vector2(p.global_position.x - _target.x,
				p.global_position.z - _target.z).length())
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			secrets._rpc_found(String(SecretRules.TEMPLE), _target)
			q.tick()
			_check(QuestRules.current_step(d, &"zara_scarab").get("type", &"") == QuestRules.GO, "solved: back to Zara")
			_check(_zara.bubble_text() == QuestGiver.BUBBLE_BACK, "a '?' over her head")
			p.spawn_at(_zara.global_position + Vector3(2, 0.5, 0))
			_next()
		7:
			q.tick()
			if not QuestRules.is_done(d, &"zara_scarab"):
				if _step_t > 20.0:
					_check(false, "coming back to Zara did not end the story")
					_finish()
				return
			_check(QuestRules.keepsakes(d).has(&"scarab"), "the keepsake: a golden scarab")
			_check(Profile.data.survivor_gold == _gold + 200, "the host paid 200 gold (%d -> %d)" % [_gold, Profile.data.survivor_gold])
			_check(d.quests.places.size() == 1 and int(d.quests.places[0].u) == UNIVERSE, "a new place: %s" % [d.quests.places])
			_check(d.count(&"quest_done/zara_scarab") == 1 and d.count(&"quest_step") == 4, "counted (steps %d)" % d.count(&"quest_step"))
			var hud: Hud = sandbox.hud
			var banners := hud.banner.showing() + " " + " ".join(hud.banner._queue.map(func(e: Array) -> String: return e[0]))
			_check(banners.contains("Story done: The golden scarab!"), "the banner")
			_check(Progress.choose_title(&"q_zara_scarab") and p.progress_tag.ends_with(":q_zara_scarab"),
				"the title on the name tag (%s)" % p.progress_tag)
			q.more_button.pressed.emit()
			_check(q.book.is_open() and _has_text(q.book, "Zara 1/2"), "the quest book")
			(q.book.find_children("Keepsakes", "Button", true, false)[0] as Button).pressed.emit()
			_check(_has_text(q.book, "1 of %d keepsakes" % QuestRules.CHAINS.size()), "the keepsakes page")
			q.book.close()
			hud.secret_book.open()
			hud.secret_book.show_page(2)
			_check(hud.secret_book.slot_texts().has("A golden scarab"), "the Secret Book's keepsakes page")
			hud.secret_book.close()
			sandbox.save_world()
			_next()
		8:
			if _step_t < 1.0:
				return
			var saved := ProfileData.from_json(FileAccess.get_file_as_string("user://profile.json"))
			_check(saved.progress.quests.done.has("zara_scarab"), "the profile on disk keeps the story")
			_finish()


func _has_text(page: QuestOverlay, part: String) -> bool:
	for t in page.texts():
		if t.contains(part):
			return true
	return false


func _check(ok: bool, what: String) -> void:
	print("QUEST_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("QUEST_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3, true).timeout.connect(func() -> void: get_tree().quit(0 if _fails.is_empty() else 1))
