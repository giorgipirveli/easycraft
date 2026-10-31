extends Node
## The steps of tools/buddy_magic_smoke.gd (M3 Task 20b), on real terrain through the real systems (a new Sandbox
## world, solo: this game is the host). A stone pad is laid at the spawn (O: the player's feet cell), then: a snowman
## (three painted white blocks and an orange nose) at x 3, z 0 is woken; a level-1 slime is summoned, calmed and
## befriended; a Stone Golem is summoned and beaten; the child does the Bunny Hop four times by the snowman; a
## 2 x 3 brick tower at x -3 is saved as a stamp and placed at x 6, z -4, then undone; the world is saved.

const TIMEOUT := 180.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _o := Vector3i.ZERO
var _said: Array[String] = []
var _snowman: Buddy
var _slime: Monster
var _golem: StoneGolem
var _golem_at := Vector3.ZERO
var _emotes := 0
var _stood := false
var _stamps: MyStampBook


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--smoke-seed="):
			Game.new_world_seed = arg.trim_prefix("--smoke-seed=").to_int()   # repeat a world
	Profile.data.buddy_magic = BuddyMagicData.new()   # a private profile: start its buddy magic afresh
	_stamps = MyStampBook.new()
	MyStampBook.use(_stamps, "user://my_stamps_smoke.json")
	Game.start_new_world = true
	Game.start_world(ModeRules.SANDBOX, true)
	Session.magic_feedback.connect(func(text: String) -> void:
		_said.append(text)
		print("MAGIC_SMOKE feedback: %s" % text))
	print("MAGIC_SMOKE begin load=%s" % _load())


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


func _said_has(part: String) -> bool:
	return _said.any(func(s: String) -> bool: return s.contains(part))


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var w: WorldService = p.world
	var magic: BuddyMagicDirector = sandbox.buddy_magic
	match _step:
		0:
			print("MAGIC_SMOKE world seed=%d (repeat it with -- --smoke-seed=%d)" % [sandbox.meta.seed, sandbox.meta.seed])
			_o = Vector3i(floori(p.global_position.x), roundi(p.global_position.y), floori(p.global_position.z))
			for x in range(-6, 12):
				for z in range(-10, 8):
					w.set_block(_c(x, -1, z), BlockIds.STONE)
					for y in range(0, 7):
						w.set_block(_c(x, y, z), BlockIds.AIR)
			for y in 3:
				w.set_block(_c(3, y, 0), BlockIds.PAINTED_WHITE)
			w.set_block(_c(4, 2, 0), BlockIds.PAINTED_ORANGE)
			for y in 3:
				w.set_block(_c(-3, y, 0), BlockIds.BRICK)
				w.set_block(_c(-2, y, 0), BlockIds.BRICK)
			p.global_position = Vector3(_o) + Vector3(1.0, 0.0, 0.5)
			_next(1.5)
		1:
			if not _stood:   # the pad's collision is rebuilt after the edits: stand the player on it again
				_stood = true
				p.global_position = Vector3(_o) + Vector3(1.0, 0.0, 0.5)
				p.velocity = Vector3.ZERO
				_wait = 0.8
				return
			Session.request_spark(_c(3, 1, 0))   # WAKE UP (the wand's card) sparks the same way
			var list: Array = sandbox.call("_buddy_nodes")
			_snowman = list[0] if list.size() == 1 else null
			_check(_snowman != null and _snowman.recipe == &"snowman", "a snowman wakes as the Jolly Snowman")
			_check(_snowman != null and _snowman.buddy_name == "Frosty", "its own name")
			_check(_said_has("A secret shape! Frosty the Jolly Snowman is alive!"), "the secret shape's words")
			_check(Profile.data.buddy_magic.has_found(&"snowman"), "the Secret Book's recipe is filled in")
			_check(Profile.data.buddy_magic.album.size() == 1 and Profile.data.buddy_magic.album[0].name == "Frosty",
				"the Buddy Album has it")
			_next(BuddyMagicDirector.SAY_LATER + 0.3)
		2:
			_check(_said_has("New in your Secret Book"), "the book's words, a moment later")
			var monsters: MonsterDirector = sandbox.get("_monsters")
			monsters.summon(MonsterRules.SLIME, 1, p.global_position + Vector3(0, 0, -3))
			_next(0.4)
		3:
			var monsters: MonsterDirector = sandbox.get("_monsters")
			_slime = monsters.monsters()[0] if not monsters.monsters().is_empty() else null
			_check(_slime != null, "a slime came")
			if _slime:
				_slime.global_position = p.global_position + Vector3(1.5, 0.3, -1.5)
				_slime.state = Monster.State.WANDER   # calm (Sandbox monsters are gentle, it may have seen the child)
				Session.request_befriend(String(_slime.name))
			var friends := magic.pets.pets_of(p.peer_id).filter(func(a: Animal) -> bool: return a.species == BefriendRules.SPECIES)
			_check(friends.size() == 1 and (friends[0] as Animal).variant == MonsterRules.SLIME, "the slime is a pet friend now")
			_check(_slime == null or _slime.is_queued_for_deletion(), "the monster is gone")
			_check(_said_has("is your friend now"), "the friend's words")
			_next(0.5)
		4:
			_check(sandbox.summon_boss(p.global_position + Vector3(0, 0, -8)) == "", "a Stone Golem rises")
			_next(4.0)
		5:
			var boss: BossDirector = sandbox.get("_boss")
			_golem = boss.golem()
			if _golem == null:
				_check(false, "the golem is there")
				_next(0.0)
				return
			_golem_at = _golem.hit_center()
			for i in 200:
				if not is_instance_valid(_golem) or _golem.is_queued_for_deletion():
					break
				_golem.take_hit(50, p.global_position, Vector3.ZERO)
			_next(0.3)
		6:
			var mini := magic.mini_of(p.peer_id, BossRules.GOLEM)
			_check(mini != null and mini.pet_name == "Pebble", "the Pebble Golem hopped out")
			_check(Profile.data.buddy_magic.minis.has("golem"), "it lives in the profile")
			_check(mini != null and mini.global_position.distance_to(_golem_at) < 4.0, "out of the boss's spot")
			p.global_position = Vector3(_o) + Vector3(2.0, 0.0, 1.5)   # next to the snowman
			p.velocity = Vector3.ZERO
			_next(0.5)
		7:
			if _emotes < 4 and _step_t >= 0.6:
				_step_t = 0.0
				_emotes += 1
				p.avatar.stop_emote()
				_check(p.play_emote(&"dance_hop"), "dance %d" % _emotes)
				if _emotes == 3:
					_check(is_instance_valid(_snowman) and TrickRules.knows(_snowman.trick_state, &"dance_hop"),
						"three dances: the snowman learned it")
					_check(_said.any(func(t: String) -> bool: return t.contains("Frosty") and t.contains("learned to dance!")),
						"the words (the slime friend by the child learns it too)")
			if _emotes < 4 or _step_t < 0.3:
				return
			_check(magic.shown.has([0, String(_snowman.name), TrickRules.DANCE]), "the fourth time it dances along")
			p.avatar.stop_emote()
			_next(0.2)
		8:
			_check(_said_has("Pebble Golem"), "the mini's words, a moment later")
			var bar: MyStampBar = sandbox.my_stamp_bar
			sandbox.hud.palette.new_stamp_requested.emit()
			_check(bar.visible and p.get_node("BlockInteractor").tap_override.is_valid(), "NEW STAMP: the next tap picks")
			bar.pick_cell(_c(-3, 1, 0))
			bar.save_button.pressed.emit()
			_check(_stamps.slots() == ([0] as Array[int]) and _stamps.blocks_of(0).size() == 6, "the tower is My Stamp 1")
			var interactor: BlockInteractor = p.get_node("BlockInteractor")
			_check(interactor._stamp(MyStampBook.item_of(0), _c(6, 0, -4)), "placed like a preset stamp")
			_next(0.3)
		9:
			var interactor: BlockInteractor = p.get_node("BlockInteractor")
			var placed := 0
			for x in range(4, 9):
				for y in range(0, 4):
					for z in range(-7, -2):
						if w.get_block(_c(x, y, z)) == BlockIds.BRICK:
							placed += 1
			_check(placed == 6, "every block of the stamp (%d)" % placed)
			interactor.undo()
			_next(0.3)
		10:
			var left := 0
			for x in range(4, 9):
				for y in range(0, 4):
					for z in range(-7, -2):
						if w.get_block(_c(x, y, z)) == BlockIds.BRICK:
							left += 1
			_check(left == 0, "one undo took it all away")
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(meta.buddies.size() == 1 and meta.buddies[0].get("tricks") == ["dance_hop"], "the snowman's trick is saved")
			_check(meta.pets.any(func(e: Dictionary) -> bool: return e.get("variant") == "slime"), "the friend is saved a slime")
			_check(not meta.pets.any(func(e: Dictionary) -> bool: return e.get("variant") == "golem"),
				"the Pebble Golem is never saved in a world")
			_finish()


static func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("MAGIC_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("MAGIC_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
