extends Node
## The steps of tools/creatures_smoke.gd (owner #86, spec §21f), on real terrain through the real systems: the taps go
## through the child's own BlockInteractor (a screen point on the creature, as a finger or a click), the sights are
## found by standing on them (SpaceSights), the alien buddy comes through the buddy system (BuddyMagicDirector), the
## drum game hears the child's feet on its drums.

const TIMEOUT := 420.0
const SEED := 12345
const MARS := 19
const BOING := 17

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _left: Node
var _place := ""
var _hops := 0
var _off := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot: String in ["sandbox_19", "sandbox_17"]:
		WorldSaves.delete(slot)
	Profile.data.creatures = CreatureData.new()
	for kind: String in Profile.data.buddy_magic.minis.keys():
		if AlienRules.is_alien_kind(StringName(kind)):
			Profile.data.buddy_magic.minis.erase(kind)
	Profile.data.survivor_gold = 500
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, MARS)
	print("CREATURES_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if sandbox != _scene:
		_scene = sandbox
		_wait = 2.0   # a new world: let it settle
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, delta)


func _run_step(sandbox: Node, _delta: float) -> void:
	var p: Player = sandbox.player
	var c: SpaceCreatures = sandbox.get("creatures")
	match _step:
		0:
			_check(Game.universe == MARS and Game.slot() == "sandbox_19", "a new Mars Sandbox world (%s)" % Game.slot())
			_check(c != null, "the robots and aliens are here (node %s)" % (c.name if c else "none"))
			if c == null:
				_finish()
				return
			var shape := c.shape
			var pad := shape.spawn_column()
			var pad3 := Vector3(pad.x + 0.5, 0, pad.y + 0.5)
			var r := c.robot.global_position
			_check(_flat(r, pad3) <= 7.0, "the helper robot %s stands by the landing pad (%.1f)" % [c.robot.display_name,
				_flat(r, pad3)])
			var feet := Vector3i(r.floor())
			_check(BlockIds.is_solid(p.world.get_block(feet + Vector3i.DOWN)) and not BlockIds.is_solid(p.world.get_block(feet)),
				"it stands on the ground, not in it (%s)" % feet)
			_check(c.rover != null and _flat(c.rover.global_position, p.global_position) < 5.0, "the rover buddy drove to the child")
			_check(c.drone != null and c.drone.global_position.y > r.y + 2.0, "the drone hovers")
			_check(c.camp != null, "the aliens' camp")
			if c.camp:
				_check(_flat(c.camp.global_position, pad3) > 24.0 and _flat(c.camp.global_position, pad3) < 53.0,
					"a short walk from the pad (%.0f)" % _flat(c.camp.global_position, pad3))
			var ids: Array = sandbox.places_director.marks.map(func(m: Dictionary) -> String: return str(m.id))
			_check(ids.has("space_aliens"), "MY MAP shows the camp")
			var guide: Dictionary = sandbox.hud.compass.guide.call(r)
			var to: Vector3 = Vector3(guide.chest) if guide.has("chest") else Vector3.INF
			_check(to.is_finite() and _flat(c.robot.point_at, to) < 1.5, "its arm points where the compass points (%s, %s)" % [
				c.robot.point_at, to])
			_check(c.robot.mark_text() == "!", "its quest waits (!)")
			_stand_near(p, c.robot, 3.0)
			_next(0.6)
		1:
			_check(_tap(sandbox, c.robot), "a tap on the robot (the BlockInteractor)")
			_check(c.card.is_open(), "its card opens: %s" % [c.card.texts()])
			_press(c, CreatureWords.QUEST_GO)
			_check(RobotRules.quest_step(c.found) == RobotRules.DIG, "the science quest starts: dig a sample")
			_place = RobotRules.quest_place(c.found)
			_check(_place.begins_with("sight:"), "its place is the guide's next place (%s)" % _place)
			_stand_near(p, c.rover, 2.5)
			_next(0.6)
		2:
			_check(_tap(sandbox, c.rover), "a tap on the rover")
			_check(c.found.has(RobotRules.SAMPLE), "it dug a sample")
			_next(SpaceCreatures.SAY_DELAY + 0.4)
		3:
			_check(c.rover.bubble.text == CreatureWords.robot(MARS).sample, "the sample's fact (%s)" % c.rover.bubble.text)
			var at := c.place_position(_place)
			_check(c.robot.point_at == at, "the robot points to the quest's place")
			p.spawn_at(at + Vector3(0, 0.1, 0))
			_next(0.5)
		4:
			if not c.found.has(_place):
				if _step_t > 20.0:
					_check(false, "the quest's place found (%s at %s)" % [_place, p.global_position])
					_next(0.0)
				return
			_check(true, "the quest's place found by standing on it (%s)" % _place)
			p.spawn_at(c.robot.global_position + Vector3(0, 0.1, 3.0))
			_next(0.8)
		5:
			_check(c.robot.mark_text() == "?", "come back to me (?)")
			_stand_near(p, c.robot, 3.0)
			_next(0.5)
		6:
			var gold := Profile.data.survivor_gold
			_check(_tap(sandbox, c.robot) and c.card.choice_buttons.size() == 3, "its question, three answers")
			var q := RobotRules.next_question(MARS, Profile.data.creatures)
			if c.card.choice_buttons.size() == 3:
				c.card.choice_buttons[int(q.answer)].pressed.emit()
			_check(Profile.data.survivor_gold == gold + EarnRules.FACT_QUIZ_GOLD, "right the first time: +%d gold (%d -> %d)" % [
				EarnRules.FACT_QUIZ_GOLD, gold, Profile.data.survivor_gold])
			_check(RobotRules.quest_step(c.found) == RobotRules.FINISHED, "the science quest is done")
			c.card.close()
			p.spawn_at(c.camp.global_position + c.camp.global_basis * Vector3(0, 0.1, -4.5))
			_next(0.8)
		7:
			if not c.found.has(RobotRules.CAMP):
				if _step_t > 6.0:
					_check(false, "the camp visited (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "walking into the camp visits it")
			_stand_near(p, c.camp.explorer, 2.5)
			_next(0.5)
		8:
			_check(_tap(sandbox, c.camp.explorer), "a tap on Zib the explorer")
			var words := " ".join(PackedStringArray(c.card.texts()))
			_check(words.contains(CreatureWords.HONEST), "its words stay honest")
			_press(c, CreatureWords.GIVE)
			_check(Profile.data.creatures.is_friend(&"zib") and Profile.data.creatures.owns("gift_zib"),
				"a friend for the sample, and its present")
			_press(c, CreatureWords.COME)
			_check(Profile.data.creatures.buddy == "zib", "Zib comes along")
			_next(0.2)
		9:
			var mini: Animal = sandbox.buddy_magic.mini_of(p.peer_id, &"alien_zib")
			if mini == null:
				if _step_t > 6.0:
					_check(false, "Zib's mini-buddy follows the child")
					_next(0.0)
				return
			_check(true, "Zib's mini-buddy follows the child (%s, %.1f away)" % [mini.name, mini.global_position.distance_to(p.global_position)])
			_check(not c.camp.explorer.visible, "not at its camp any more")
			_stand_near(p, c.camp.trader, 2.5)
			_next(0.5)
		10:
			_check(_tap(sandbox, c.camp.trader), "a tap on Quix the trader")
			var gold := Profile.data.survivor_gold
			_press(c, "%s: %d gold" % [CreatureWords.souvenir("sun_marble").name, AlienRules.price("sun_marble")])
			_check(Profile.data.creatures.owns("sun_marble") and Profile.data.survivor_gold == gold - AlienRules.price("sun_marble"),
				"a souvenir bought for gold")
			c.card.close()
			_next(3.0)   # the world round the camp settles (its chunks stream in) before the frame costs
		11:
			_frame_cost(c)
			_left = sandbox
			sandbox.save_world()
			Game.new_world_seed = SEED
			Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, BOING)
			_next(0.1)
		12:
			if sandbox == _left:
				return
			_check(Game.universe == BOING, "a new Planet Boing Sandbox world")
			_check(c != null and c.village != null and c.camp == null, "an alien village")
			if c == null or c.village == null:
				_finish()
				return
			_check(c.robot.display_name == "Sprocket", "its helper robot")
			_check(_flat(c.robot.point_at, c.site.pos) < 1.0, "no sights here: the robot points at the village")
			var zib: Animal = sandbox.buddy_magic.mini_of(p.peer_id, &"alien_zib")
			_check(zib != null, "Zib came along to Planet Boing (the buddy system)")
			_stand_near(p, c.village.chief, 2.5)
			_next(0.5)
		13:
			if not p.is_on_floor() or not _tap(sandbox, c.village.chief):   # Planet Boing's moss bounces a child
				if _step_t > 8.0:
					var cam := p.camera()
					var at := c.village.chief.tap_center()
					var from := cam.global_position
					var hit := SpaceCreature.find(get_tree(), from, (at - from).normalized(), p.eye_position())
					var wall := p.world.raycast(from, (at - from).normalized(), from.distance_to(at))
					_check(false, "a tap on Bopsy the chief (at %s, chief at %s, floor %s, cam %s, finds %s, wall %s)" % [
						p.global_position, c.village.chief.global_position, p.is_on_floor(), from,
						hit.name if hit else "none", wall.position if wall else "none"])
					_next(0.0)
				elif fmod(_step_t, 1.0) < get_process_delta_time():
					_stand_near(p, c.village.chief, 2.5)
				return
			_check(true, "a tap on Bopsy the chief")
			_press(c, CreatureWords.PLAY_ECHO)
			_check(c.village.playing, "a game of Echo")
			_hops = 0
			_off = true
			_next(0.0)
		14:
			var v := c.village
			if v.game.won or not v.playing:
				_check(v.game.won, "the whole song hopped on the drums (%d hops, %d misses)" % [_hops, v.game.misses])
				_check(Profile.data.creatures.is_friend(&"bopsy"), "Bopsy is a friend")
				_press(c, CreatureWords.COME)
				_check(Profile.data.creatures.buddy == "bopsy", "Bopsy comes along now")
				_next(1.0)
				return
			if _step_t > 90.0:
				_check(false, "Echo won in time (round %d)" % v.game.round_number())
				_next(0.0)
				return
			if not v.game.listening or _step_t < 0.25:
				return
			_step_t = 0.0
			if _off:
				var pad := v.pads[v.game.song[v.game.at]].global_position
				p.global_position = pad + Vector3(0, AlienModels.PAD_TOP + 0.05, 0)
				_hops += 1
			else:
				p.global_position = v.global_position + Vector3(0, 0.3, 0)
			p.velocity = Vector3.ZERO
			_off = not _off
		15:
			_check(sandbox.buddy_magic.mini_of(p.peer_id, &"alien_zib") == null, "Zib went back to its camp (one alien at a time)")
			_check(sandbox.buddy_magic.mini_of(p.peer_id, &"alien_bopsy") != null, "Bopsy follows")
			_finish()


## The creatures' per-frame work in the real world (their thinking and easing, the director's look round), each the
## best of RUNS runs (the PC is shared: the best run is the least disturbed one), against Tilly's own per-frame work
## (an accepted cost, measured the same way).
const RUNS := 5
const FRAMES := 240


func _frame_cost(c: SpaceCreatures) -> void:
	var nodes: Array = c.get_tree().get_nodes_in_group(SpaceCreature.GROUP)
	var tilly := Trader.new()
	tilly.setup({"pos": c.robot.global_position + Vector3(3, 0, 0), "yaw": 0.0, "hint": false})
	c.add_child(tilly)
	var tilly_ms := _best(func() -> void: tilly._process(1.0 / 60.0))
	tilly.queue_free()
	var total := 0.0
	for pass_i in 2:   # twice: a disturbed first pass shows as a difference
		total = 0.0
		for n in nodes:
			var ms := _best(func() -> void: (n as SpaceCreature)._process(1.0 / 60.0))
			total += ms
			print("CREATURES_FRAME_MS pass %d %s %.4f" % [pass_i, n.name, ms])
		var director := _best(func() -> void: c._process(1.0 / 60.0))
		total += director
		print("CREATURES_FRAME_MS pass %d director %.4f" % [pass_i, director])
	var meshes := c.find_children("*", "MeshInstance3D", true, false).size()
	var labels := c.find_children("*", "Label3D", true, false).size()
	print("CREATURES_FRAME_MS total %.4f creatures=%d meshes=%d labels=%d tilly=%.4f" % [total, nodes.size(), meshes,
		labels, tilly_ms])
	_check(total < maxf(0.25, tilly_ms * 12.0), "their frame cost is small: %.4f ms a frame for all %d (Tilly: %.4f)" % [
		total, nodes.size(), tilly_ms])


func _best(work: Callable) -> float:
	var best := INF
	for r in RUNS:
		var t0 := Time.get_ticks_usec()
		for f in FRAMES:
			work.call()
		best = minf(best, (Time.get_ticks_usec() - t0) / 1000.0 / FRAMES)
	return best


## Puts the child `dist` in front of `thing`, looking at it.
func _stand_near(p: Player, thing: Node3D, dist: float) -> void:
	var at := thing.global_position
	var away := Vector3(p.global_position.x - at.x, 0, p.global_position.z - at.z)
	away = away.normalized() if away.length() > 0.1 else Vector3.BACK
	var spot := at + away * dist
	spot.y = float(p.world.find_standing_y(floori(spot.x), floori(spot.z)))
	p.global_position = spot + Vector3(0, 0.05, 0)
	p.velocity = Vector3.ZERO
	p.rig.yaw = atan2(-(at.x - spot.x), -(at.z - spot.z))
	p.rig.pitch = -0.25


## A tap on `thing` through the child's own BlockInteractor: the screen point its middle shows at.
func _tap(sandbox: Node, thing: SpaceCreature) -> bool:
	var p: Player = sandbox.player
	var cam := p.camera()
	var interactor: BlockInteractor = sandbox.get("_interactor")
	if cam.is_position_behind(thing.tap_center()):
		return false
	var before := (sandbox.get("creatures") as SpaceCreatures).card.is_open()
	var screen := cam.unproject_position(thing.tap_center())
	var used := interactor.place_at_screen(screen)
	return used and (thing is RoverBuddy or before or (sandbox.get("creatures") as SpaceCreatures).card.is_open())


func _press(c: SpaceCreatures, text: String) -> void:
	var b := c.card.button_named(text)
	_check(b != null, "a %s button (%s)" % [text, c.card.texts()])
	if b:
		b.pressed.emit()


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("CREATURES_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("CREATURES_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
