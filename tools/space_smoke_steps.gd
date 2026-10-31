extends Node
## The steps of tools/space_smoke.gd (owner feedback #55), on real terrain through the real systems: the child's body
## climbs as flying does (its own position; the jump/fly input is another agent's), the SpaceDirector turns the sky and
## opens the picker, a card lands through the sandbox's trip (saves, the new world scene), and the way home is owner
## #39's portal (or HOME in the picker).

const TIMEOUT := 480.0
const SEED := 12345
const CLIMB_SPEED := 60.0         # m/s: a quick flight up (the real flight is 11 m/s)
const OFF_SPAWN := Vector3(12, 0, 7)

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _left: Node
var _take_off := Vector2i.ZERO
var _saw_climb := false
var _landmark := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.MOON)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for slot: String in ["sandbox_1", "sandbox_16", "sandbox_17", "survivor_1", "survivor_u17"]:
		WorldSaves.delete(slot)
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("SPACE_SMOKE begin")


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
		_wait = 1.5   # a new world: let it settle (and build its portal home)
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, delta)


func _run_step(sandbox: Node, delta: float) -> void:
	var p: Player = sandbox.player
	var space: SpaceDirector = sandbox.get("space")
	match _step:
		0:
			_check(Game.slot() == "sandbox_1", "a new Green Meadows Sandbox world (%s)" % Game.slot())
			_check(space != null and space.panel != null, "the space director and its picker are there")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)   # take off away from the spawn: home must land here, not there
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_saw_climb = false
			_next(0.1)
		1:
			if _climb(p, sandbox, space, delta):
				_check(_saw_climb, "the sky turned to space on the way up")
				_next(0.0)
		2:
			_check(get_tree().paused, "played alone, the picker holds the game still")
			_check(space.panel.title_text() == SpaceRules.TITLE, "\"%s\"" % space.panel.title_text())
			_check(space.panel.bodies.size() == StarMap.bodies().size(), "the Star Map: %d bodies" % space.panel.bodies.size())
			space.panel.body_for(&"moon").pressed.emit()
			_check(space.panel.card_title() == "The Moon" and space.panel.card_facts().size() == 3,
				"the Moon's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "LAND", "LAND on the Moon")
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing on the Moon"):
				return
			_check(Game.universe == SpaceRules.MOON and Game.slot() == "sandbox_16", "the Moon's own Sandbox world (%s)" % Game.slot())
			_check(p.world.universe == SpaceRules.MOON and p.world.generator_shape() is SpaceShape, "its terrain is the Moon's")
			_check(is_equal_approx(LabRules.world_gravity, 0.35), "the Moon's gravity (%.2f)" % LabRules.world_gravity)
			_check(is_equal_approx(sandbox.sky.space, 1.0) and sandbox.sky.planet() != null and sandbox.sky.planet().visible,
				"a space sky with the home planet in it")
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.LANDING_PAD, "standing on the landing pad (%s)" % BlockIds.display_name(under))
			var monsters: MonsterDirector = sandbox.get_node("Monsters")
			_check(not bool(monsters.enabled.call()), "peaceful: no night monsters")
			var marks: Array = sandbox.places_director.marks
			_check(marks.any(func(m: Dictionary) -> bool: return m.id == "space_pad"), "MY MAP shows the landing pad")
			_check(sandbox.map_button != null and sandbox.map_button.visible, "the MAP button shows")
			_next(1.0)
		4:
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			_check(frames.gates.gate_to(1) != null, "the portal home stands by the pad (%s)" % str(frames.gates.to_save()))
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			p.global_position += Vector3(0, 6, 0)
			p.velocity = Vector3.ZERO
			_next(0.0)
		5:
			if _step_t < 0.3:
				return
			var fall := -p.velocity.y
			_check(fall > 0.3 and fall < Player.GRAVITY * 0.5 * _step_t, "a slow Moon fall (%.2f m/s after %.2f s)" % [fall, _step_t])
			var rules: SpaceSecretRules = sandbox.get_node("Secrets").rules
			_landmark = rules.landmark()
			_check(_landmark.get("name") == "Moon Base", "the Moon Base is the landmark")
			var at: Vector3i = _landmark.anchor
			p.spawn_at(Vector3(at) + Vector3(1.5, 0.05, 1.5))
			_next(0.0)
		6:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			if not secrets.state.found.has(_landmark.id):
				if _step_t > 10.0:
					_check(false, "walking into the Moon Base finds it")
					_next(0.0)
				return
			_check(true, "walking into the Moon Base finds it")
			_check(sandbox.places_director.marks.any(func(m: Dictionary) -> bool: return m.id == "space_landmark"),
				"MY MAP shows the Moon Base once found")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			_next(0.1)
		7:
			if _climb(p, sandbox, space, delta):
				_check(space.panel.home_button.visible and space.panel.home_button.text == "HOME",
					"from the Moon, HOME sits by STAY HERE")
				space.panel.home_button.pressed.emit()
				_left = sandbox
				_next(0.1)
		8:
			if not _arrived(sandbox, "going home"):
				return
			_check(Game.universe == 1 and Game.slot() == "sandbox_1", "home in Green Meadows (%s)" % Game.slot())
			var col := Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_check(col == _take_off, "landed on the take-off column (%s, took off at %s)" % [col, _take_off])
			var ground := p.world.find_standing_y(col.x, col.y)
			_check(absf(p.global_position.y - ground) < 1.6, "on the ground, not in the sky (%.1f vs %d)" % [p.global_position.y, ground])
			_check(is_equal_approx(LabRules.world_gravity, 1.0), "home gravity again")
			_check(p.physics_mode == PhysicsMode.Mode.NORMAL, "walking")
			_next(0.5)
		9:
			Session.close()
			Profile.data.survivor_gold = maxi(Profile.data.survivor_gold, 500)
			Profile.data.inventions = InventionData.invented_to(InventionLine.PLANE)   # owner #78: Survivor flies what
			Profile.data.inventions.craft = InventionLine.PLANE                        # the child invented
			Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.COZY, 1)
			_left = sandbox
			_next(0.1)
		10:
			if not _arrived(sandbox, "a new Survivor world"):
				return
			_check(Game.slot() == "survivor_1", "a new Survivor world (%s)" % Game.slot())
			Session.inventory_of(p.peer_id).add(ItemIds.SWORD_COSMIC, 1)
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)
			_check(p.physics_mode == PhysicsMode.Mode.FLY, "Survivor flies (an invented plane, paid)")
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		11:
			if _climb(p, sandbox, space, delta):
				space.panel.body_for(&"boing").pressed.emit()
				space.panel.action_button.pressed.emit()
				_left = sandbox
				_next(0.1)
		12:
			if not _arrived(sandbox, "landing on Planet Boing"):
				return
			_check(Game.universe == SpaceRules.BOING and Game.slot() == "survivor_u17", "Planet Boing's Survivor world (%s)" % Game.slot())
			_check(Session.inventory_of(p.peer_id).count(ItemIds.SWORD_COSMIC) == 1, "the bag came along")
			_check(is_equal_approx(LabRules.world_gravity, 0.6), "Boing's gravity (%.2f)" % LabRules.world_gravity)
			_next(1.0)
		13:
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			var core: Variant = frames.gates.gate_to(1)
			_check(core != null, "the portal home stands by the pad")
			if core == null:
				_finish()
				return
			var shape := frames.gates.shape_of(core)
			p.global_position = Vector3(shape.lo as Vector3i) + Vector3(0.5, 0.05, 0.5)
			_left = sandbox
			_next(0.1)
		14:
			if not _arrived(sandbox, "walking into the portal home"):
				return
			_check(Game.universe == 1 and Game.slot() == "survivor_1", "home in the Survivor world (%s)" % Game.slot())
			_check(Session.inventory_of(p.peer_id).count(ItemIds.SWORD_COSMIC) == 1, "the bag came home")
			var col := Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_check(col == _take_off, "landed on the take-off column (%s, took off at %s)" % [col, _take_off])
			_finish()


## The flyer climbs (its own position, as flying does); true once the picker shows.
func _climb(p: Player, sandbox: Node, space: SpaceDirector, delta: float) -> bool:
	if space.panel.visible:
		return true
	if _step_t > 20.0:
		_check(false, "the picker opened above the space line (y %.1f)" % p.global_position.y)
		_finish()
		return false
	p.global_position.y = minf(p.global_position.y + CLIMB_SPEED * delta, SpaceRules.SPACE_Y + 2.0)
	if p.global_position.y > SpaceRules.HINT_Y and sandbox.sky.space_climb > 0.4:
		_saw_climb = true
	return false


## True once a new world scene stands (after `_left`); fails after 20 s.
func _arrived(sandbox: Node, what: String) -> bool:
	if sandbox != _left:
		return true
	if _step_t > 20.0:
		_check(false, what)
		_finish()
	return false


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("SPACE_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("SPACE_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
