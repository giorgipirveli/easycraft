extends Node
## The steps of tools/europa_smoke.gd (cosmos, spec §21b.2), on real terrain through the real systems: the child's body
## climbs as flying does (its own position), the SpaceDirector opens the Star Map, Europa's card lands through the
## sandbox's trip (saves, the new world scene), a vent's plume throws the child up through the player's own pads, and
## the way home is owner #39's portal by the landing pad.

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.EUROPA)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for slot: String in ["sandbox_1", "sandbox_20"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.bodies.erase("europa")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("EUROPA_SMOKE begin")


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
			_check(SpaceRules.WORLDS.has(SpaceRules.EUROPA) and UniverseRegistry.space_available().has(SpaceRules.EUROPA),
				"Europa is a space world to land on")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)   # take off away from the spawn: home must land here
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			_check(space.panel.title_text() == SpaceRules.TITLE, "the Star Map: \"%s\"" % space.panel.title_text())
			space.panel.body_for(&"europa").pressed.emit()
			_check(space.panel.card_title() == "Europa" and space.panel.card_facts().size() == 3,
				"Europa's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "LAND", "LAND on Europa (%s)" % space.panel.action_button.text)
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing on Europa"):
				return
			_check(Game.universe == SpaceRules.EUROPA and Game.slot() == "sandbox_20", "Europa's own Sandbox world (%s)" % Game.slot())
			var shape := p.world.generator_shape() as SpaceShape
			_check(shape != null and shape.planet == SpaceShape.EUROPA, "its terrain is Europa's")
			_check(is_equal_approx(LabRules.world_gravity, 0.13), "Europa's gravity (%.2f)" % LabRules.world_gravity)
			var sky: SkyCycle = sandbox.sky
			_check(sky.space == 1.0, "space's black starry sky (almost no air)")
			_check(sky.planet() != null and sky.planet().visible and (sky.planet().mesh as QuadMesh).size.x > 90.0,
				"giant Jupiter in the sky")
			_check(sky.moons().size() == 2 and sky.moons().all(func(m: MeshInstance3D) -> bool: return m.visible),
				"Io and Ganymede in the sky")
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.LANDING_PAD, "standing on the landing pad (%s)" % BlockIds.display_name(under))
			var monsters: MonsterDirector = sandbox.get_node("Monsters")
			_check(not bool(monsters.enabled.call()), "peaceful: no night monsters")
			var animals: Node = sandbox.get_node_or_null("AnimalDirector")
			_check(animals != null and animals.process_mode == Node.PROCESS_MODE_DISABLED, "no animals: no life we know of")
			var marks: Array = sandbox.places_director.marks
			var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
			_check(ids.has("space_pad"), "MY MAP shows the landing pad")
			for id in ["sight_ocean", "sight_cliffs", "sight_plume"]:
				_check(ids.has(id), "MY MAP shows %s" % id)
			var marked := int(Profile.data.wonder.bodies.get("europa", 0))
			_check(marked & WonderData.LANDED != 0, "the Space Book marks Europa landed on")
			_check(sandbox.get("sights") is SpaceSights, "Europa's sights are watched")
			_check(sandbox.get("geysers") is SpaceGeysers, "its water plumes blow")
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
			_check(fall > 0.1 and fall < Player.GRAVITY * 0.2 * _step_t, "a slow Europa fall (%.2f m/s after %.2f s)" % [fall, _step_t])
			var rules: SpaceSecretRules = sandbox.get_node("Secrets").rules
			_landmark = rules.landmark()
			_check(_landmark.get("name") == "Ice Lander", "the Ice Lander is the landmark")
			var chest: Vector3i = _landmark.chest
			p.spawn_at(Vector3(chest) + Vector3(1.5, 0.05, 0.5))   # on its deck, beside the chest
			_next(0.0)
		6:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			if not secrets.state.found.has(_landmark.id):
				if _step_t > 10.0:
					_check(false, "standing on the Ice Lander's deck finds it")
					_next(0.0)
				return
			_check(true, "standing on the Ice Lander's deck finds it")
			_check(sandbox.places_director.marks.any(func(m: Dictionary) -> bool: return m.id == "space_landmark"),
				"MY MAP shows the Ice Lander once found")
			var shape := p.world.generator_shape() as SpaceShape
			var vent := shape.europa.nearest_vent(shape.spawn_column())
			_vent_top = float(shape.height_at(vent.x, vent.y))
			p.spawn_on_surface(vent.x + 2, vent.y)   # on the plume's mound of salt
			_next(0.0)
		7:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:plume"):
				if _step_t > 10.0:
					_check(false, "standing on a plume's mound says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "standing on a plume's mound says its fact")
			var vent := (p.world.generator_shape() as SpaceShape).europa.nearest_vent(p.world.spawn_column())
			p.spawn_at(Vector3(vent.x + 0.5, _vent_top + 0.05, vent.y + 0.5))   # on the vent at the bottom of its hole
			_next(0.0)
		8:
			if p.global_position.y < _vent_top + 12.0:
				if _step_t > 8.0:
					_check(false, "the water plume throws the child up (y %.1f over the vent at %.0f)" % [p.global_position.y, _vent_top])
					_next(0.0)
				return
			_check(true, "the water plume throws the child up (%.0f blocks over the vent)" % (p.global_position.y - _vent_top))
			var mc := (p.world.generator_shape() as SpaceShape).europa.mesa_centre()
			p.spawn_on_surface(mc.x, mc.y)
			_next(0.0)
		9:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:cliffs"):
				if _step_t > 12.0:
					_check(false, "standing on the ice cliffs says their fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "standing on the ice cliffs says their fact (height %.0f)" % p.global_position.y)
			var e := (p.world.generator_shape() as SpaceShape).europa
			var wc := e.well_centre()
			var a := e.ramp_start() - 0.3   # the shelf at the ramp's end, just over the water
			var shelf := wc + Vector2i(roundi(cos(a) * 9.0), roundi(sin(a) * 9.0))
			p.spawn_at(Vector3(shelf.x + 0.5, EuropaTerrain.OCEAN_TOP + 1.05, shelf.y + 0.5))
			_next(0.0)
		10:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:ocean"):
				if _step_t > 12.0:
					_check(false, "reaching the ocean at the bottom of the well says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "reaching the ocean at the bottom of the well says its fact")
			var water := p.world.get_block(Vector3i(floori(p.global_position.x), EuropaTerrain.OCEAN_TOP - 1, floori(p.global_position.z)))
			_check(water == BlockIds.WATER, "the ocean under the shelf (%s)" % BlockIds.display_name(water))
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			var core: Variant = frames.gates.gate_to(1)
			if core == null:
				_finish()
				return
			var shape_of := frames.gates.shape_of(core)
			p.spawn_at(Vector3(shape_of.lo as Vector3i) + Vector3(0.5, 0.05, 0.5))
			_left = sandbox
			_next(0.1)
		11:
			if not _arrived(sandbox, "walking into the portal home"):
				return
			_check(Game.universe == 1 and Game.slot() == "sandbox_1", "home in Green Meadows (%s)" % Game.slot())
			var col := Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_check(col == _take_off, "landed on the take-off column (%s, took off at %s)" % [col, _take_off])
			_check(is_equal_approx(LabRules.world_gravity, 1.0), "home gravity again")
			_finish()


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
	print("EUROPA_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("EUROPA_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
