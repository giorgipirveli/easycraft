extends Node
## The steps of tools/io_smoke.gd (cosmos, spec §21b.2), on real terrain through the real systems: the child's body
## climbs as flying does (its own position), the SpaceDirector opens the Star Map, Io's card lands through the sandbox's
## trip (saves, the new world scene), a volcano's plume and the hot lava throw the child up through the player's own
## pads, and the way home is owner #39's portal by the landing pad.

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
var _landmark := {}
var _vent_top := 0.0
var _moat_top := 0.0
var _health := 0
var _highest := -INF


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.IO)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for slot: String in ["sandbox_1", "sandbox_21"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.bodies.erase("io")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("IO_SMOKE begin")


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
			_check(SpaceRules.WORLDS.has(SpaceRules.IO) and UniverseRegistry.space_available().has(SpaceRules.IO),
				"Io is a space world to land on")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)   # take off away from the spawn: home must land here
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			_check(space.panel.title_text() == SpaceRules.TITLE, "the Star Map: \"%s\"" % space.panel.title_text())
			space.panel.body_for(&"io").pressed.emit()
			_check(space.panel.card_title() == "Io" and space.panel.card_facts().size() == 3,
				"Io's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "LAND", "LAND on Io (%s)" % space.panel.action_button.text)
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing on Io"):
				return
			_check(Game.universe == SpaceRules.IO and Game.slot() == "sandbox_21", "Io's own Sandbox world (%s)" % Game.slot())
			var shape := p.world.generator_shape() as SpaceShape
			_check(shape != null and shape.planet == SpaceShape.IO, "its terrain is Io's")
			_check(is_equal_approx(LabRules.world_gravity, 0.18), "Io's gravity (%.2f)" % LabRules.world_gravity)
			var sky: SkyCycle = sandbox.sky
			_check(sky.space == 1.0, "space's black starry sky (almost no air)")
			_check(sky.planet() != null and sky.planet().visible and (sky.planet().mesh as QuadMesh).size.x > 120.0,
				"giant Jupiter in the sky")
			_check(sky.moons().size() == 2 and sky.moons().all(func(m: MeshInstance3D) -> bool: return m.visible),
				"Europa and Ganymede in the sky")
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.LANDING_PAD, "standing on the landing pad (%s)" % BlockIds.display_name(under))
			var monsters: MonsterDirector = sandbox.get_node("Monsters")
			_check(not bool(monsters.enabled.call()), "peaceful: no night monsters")
			var animals: Node = sandbox.get_node_or_null("AnimalDirector")
			_check(animals != null and animals.process_mode == Node.PROCESS_MODE_DISABLED, "no animals: no life we know of")
			var marks: Array = sandbox.places_director.marks
			var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
			_check(ids.has("space_pad"), "MY MAP shows the landing pad")
			for id in ["sight_lake", "sight_mountain", "sight_plume"]:
				_check(ids.has(id), "MY MAP shows %s" % id)
			var marked := int(Profile.data.wonder.bodies.get("io", 0))
			_check(marked & WonderData.LANDED != 0, "the Space Book marks Io landed on")
			_check(sandbox.get("sights") is SpaceSights, "Io's sights are watched")
			_check(sandbox.get("geysers") is SpaceGeysers, "its volcanoes blow")
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
			_check(fall > 0.1 and fall < Player.GRAVITY * 0.25 * _step_t, "a slow Io fall (%.2f m/s after %.2f s)" % [fall, _step_t])
			var rules: SpaceSecretRules = sandbox.get_node("Secrets").rules
			_landmark = rules.landmark()
			_check(_landmark.get("name") == "Volcano Lander", "the Volcano Lander is the landmark")
			var chest: Vector3i = _landmark.chest
			p.spawn_at(Vector3(chest) + Vector3(1.5, 0.05, 0.5))   # on its deck, beside the chest
			_next(0.0)
		6:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			if not secrets.state.found.has(_landmark.id):
				if _step_t > 10.0:
					_check(false, "standing on the Volcano Lander's deck finds it")
					_next(0.0)
				return
			_check(true, "standing on the Volcano Lander's deck finds it")
			_check(sandbox.places_director.marks.any(func(m: Dictionary) -> bool: return m.id == "space_landmark"),
				"MY MAP shows the Volcano Lander once found")
			var shape := p.world.generator_shape() as SpaceShape
			var vent := shape.io.nearest_vent(shape.spawn_column())
			_vent_top = float(shape.height_at(vent.x, vent.y))
			p.spawn_on_surface(vent.x + 4, vent.y)   # on the volcano's cone
			_next(0.0)
		7:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:plume"):
				if _step_t > 10.0:
					_check(false, "standing on a volcano's cone says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "standing on a volcano's cone says its fact")
			var vent := (p.world.generator_shape() as SpaceShape).io.nearest_vent(p.world.spawn_column())
			p.spawn_at(Vector3(vent.x + 0.5, _vent_top + 0.05, vent.y + 0.5))   # on the vent at the bottom of its crater
			_next(0.0)
		8:
			if p.global_position.y < _vent_top + 12.0:
				if _step_t > 8.0:
					_check(false, "the volcano's plume throws the child up (y %.1f over the vent at %.0f)" % [p.global_position.y, _vent_top])
					_next(0.0)
				return
			_check(true, "the volcano's plume throws the child up (%.0f blocks over the vent)" % (p.global_position.y - _vent_top))
			var lc := (p.world.generator_shape() as SpaceShape).io.lake_centre()
			p.spawn_on_surface(lc.x + IoTerrain.LAKE_R + 1, lc.y)   # on the lava lake's rim
			_next(0.0)
		9:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:lake"):
				if _step_t > 12.0:
					_check(false, "the lava lake's rim says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "the lava lake's rim says its fact")
			var shape := p.world.generator_shape() as SpaceShape
			var lc := shape.io.lake_centre()
			var moat := _moat_cell(shape)
			_moat_top = float(shape.height_at(moat.x, moat.y))
			var lava := p.world.get_block(Vector3i(moat.x, int(_moat_top) - 1, moat.y))
			_check(lava == BlockIds.HOT_LAVA, "the moat's hot lava (%s)" % BlockIds.display_name(lava))
			_health = p.health.hp if p.health != null else 0
			_highest = -INF
			p.spawn_at(Vector3(moat.x + 0.5, _moat_top + 0.05, moat.y + 0.5))   # in the hot lava
			p.velocity = Vector3.ZERO
			print("IO_SMOKE info lake %s moat %s" % [lc, moat])
			_next(0.0)
		10:
			_highest = maxf(_highest, p.global_position.y)
			if _highest < _moat_top + 4.0:
				if _step_t > 6.0:
					_check(false, "the hot lava bounces the child up (highest %.1f over the moat at %.0f)" % [_highest, _moat_top])
					_next(0.0)
				return
			_check(true, "the hot lava bounces the child up and out (%.1f blocks over the moat)" % (_highest - _moat_top))
			_check(p.health == null or p.health.hp == _health, "and never hurts (health %d)" % (p.health.hp if p.health else 0))
			var pk := (p.world.generator_shape() as SpaceShape).io.peak_centre()
			p.spawn_on_surface(pk.x, pk.y)
			_next(0.0)
		11:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:mountain"):
				if _step_t > 12.0:
					_check(false, "the mountain's top says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "the mountain's top says its fact (height %.0f)" % p.global_position.y)
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			var core: Variant = frames.gates.gate_to(1)
			if core == null:
				_finish()
				return
			var shape_of := frames.gates.shape_of(core)
			p.spawn_at(Vector3(shape_of.lo as Vector3i) + Vector3(0.5, 0.05, 0.5))
			_left = sandbox
			_next(0.1)
		12:
			if not _arrived(sandbox, "walking into the portal home"):
				return
			_check(Game.universe == 1 and Game.slot() == "sandbox_1", "home in Green Meadows (%s)" % Game.slot())
			var col := Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_check(col == _take_off, "landed on the take-off column (%s, took off at %s)" % [col, _take_off])
			_check(is_equal_approx(LabRules.world_gravity, 1.0), "home gravity again")
			_finish()


## A cell of the lava lake's moat (hot lava), clear of the causeways.
func _moat_cell(shape: SpaceShape) -> Vector2i:
	var lc := shape.io.lake_centre()
	for a in 72:
		var dir := Vector2.from_angle(TAU * a / 72.0)
		var c := lc + Vector2i(roundi(dir.x * (IoTerrain.LAKE_R - 1)), roundi(dir.y * (IoTerrain.LAKE_R - 1)))
		if shape.io_kind(c.x, c.y) == IoTerrain.MOAT:
			return c
	return lc


## The flyer climbs (its own position, as flying does); true once the Star Map shows.
func _climb(p: Player, space: SpaceDirector, delta: float) -> bool:
	if space.panel.visible:
		return true
	if _step_t > 20.0:
		_check(false, "the Star Map opened above the space line (y %.1f)" % p.global_position.y)
		_finish()
		return false
	p.global_position.y = minf(p.global_position.y + CLIMB_SPEED * delta, SpaceRules.SPACE_Y + 2.0)
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
	print("IO_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("IO_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
