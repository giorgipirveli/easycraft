extends Node
## The steps of tools/mercury_smoke.gd (cosmos, spec §21b.2), on real terrain through the real systems: the child's body
## climbs as flying does (its own position), the SpaceDirector opens the Star Map, Mercury's card lands through the
## sandbox's trip (saves, the new world scene), the sights are found by standing on them, and the way home is owner
## #39's portal by the landing pad.

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
var _health := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.MERCURY)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for slot: String in ["sandbox_1", "sandbox_23"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.bodies.erase("mercury")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("MERCURY_SMOKE begin")


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
			_check(SpaceRules.WORLDS.has(SpaceRules.MERCURY) and UniverseRegistry.space_available().has(SpaceRules.MERCURY),
				"Mercury is a space world to land on")
			_check((sandbox.sky as SkyCycle).sun_size == 1.0, "home's Sun")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)   # take off away from the spawn: home must land here
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			_check(space.panel.title_text() == SpaceRules.TITLE, "the Star Map: \"%s\"" % space.panel.title_text())
			space.panel.body_for(&"mercury").pressed.emit()
			_check(space.panel.card_title() == "Mercury" and space.panel.card_facts().size() == 3,
				"Mercury's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "LAND", "LAND on Mercury (%s)" % space.panel.action_button.text)
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing on Mercury"):
				return
			_check(Game.universe == SpaceRules.MERCURY and Game.slot() == "sandbox_23",
				"Mercury's own Sandbox world (%s)" % Game.slot())
			var shape := p.world.generator_shape() as SpaceShape
			_check(shape != null and shape.planet == SpaceShape.MERCURY, "its terrain is Mercury's")
			_check(is_equal_approx(LabRules.world_gravity, 0.38), "Mercury's gravity (%.2f)" % LabRules.world_gravity)
			var sky: SkyCycle = sandbox.sky
			_check(sky.space == 1.0, "almost no air: space's black sky")
			_check(sky.sun_size == 3.0, "the Sun three times as big (%.1f)" % sky.sun_size)
			var mat := p.world.environment().sky.sky_material as ProceduralSkyMaterial
			_check(mat != null and is_equal_approx(mat.sun_angle_max, DayCycle.SUN_GLOW * 3.0),
				"the sky's Sun is three times as big by day (%s)" % (mat.sun_angle_max if mat else -1.0))
			_check(not p.world.photo_sky, "never Earth's photo sky")
			_check(sky.planet() != null and sky.planet().visible and (sky.planet().mesh as QuadMesh).size.x < 10.0,
				"Venus, a tiny bright point")
			_check(sky.moons().filter(func(m: MeshInstance3D) -> bool: return m.visible).size() == 2,
				"Earth and our Moon, two tiny points")
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.LANDING_PAD, "standing on the landing pad (%s)" % BlockIds.display_name(under))
			var monsters: MonsterDirector = sandbox.get_node("Monsters")
			_check(not bool(monsters.enabled.call()), "peaceful: no night monsters")
			var animals: Node = sandbox.get_node_or_null("AnimalDirector")
			_check(animals != null and animals.process_mode == Node.PROCESS_MODE_DISABLED, "no animals: no life we know of")
			var marks: Array = sandbox.places_director.marks
			var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
			_check(ids.has("space_pad"), "MY MAP shows the landing pad")
			for id in ["sight_thermometer", "sight_scarp", "sight_crater", "sight_ice"]:
				_check(ids.has(id), "MY MAP shows %s" % id)
			var marked := int(Profile.data.wonder.bodies.get("mercury", 0))
			_check(marked & WonderData.LANDED != 0, "the Space Book marks Mercury landed on")
			_check(sandbox.get("sights") is SpaceSights, "Mercury's sights are watched")
			_check(sandbox.get("geysers") == null, "no geysers on Mercury")
			_health = p.health.hp if p.health != null else 0
			_next(1.0)
		4:
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			_check(frames.gates.gate_to(1) != null, "the portal home stands by the pad (%s)" % str(frames.gates.to_save()))
			var t := (p.world.generator_shape() as SpaceShape).thermometer_column()
			var bulb := Vector3i(t.x, p.world.surface_height(t.x, t.y) + 1, t.y)
			_check(p.world.get_block(bulb) == BlockIds.THERMO_BULB, "the thermometer stands by the pad (%s)" % bulb)
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			p.global_position += Vector3(0, 6, 0)
			p.velocity = Vector3.ZERO
			_next(0.0)
		5:
			if _step_t < 0.3:
				return
			var fall := -p.velocity.y
			_check(fall > 0.3 and fall < Player.GRAVITY * 0.5 * _step_t, "a slow Mercury fall (%.2f m/s after %.2f s)" % [
				fall, _step_t])
			var rules: SpaceSecretRules = sandbox.get_node("Secrets").rules
			_landmark = rules.landmark()
			_check(_landmark.get("name") == "Sunshade Lander", "the Sunshade Lander is the landmark")
			var chest: Vector3i = _landmark.chest
			p.spawn_at(Vector3(chest) + Vector3(1.5, 0.05, 0.5))   # on its deck, beside the chest
			_next(0.0)
		6:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			if not secrets.state.found.has(_landmark.id):
				if _step_t > 10.0:
					_check(false, "standing on the Sunshade Lander finds it")
					_next(0.0)
				return
			_check(true, "standing on the Sunshade Lander finds it")
			_check(sandbox.places_director.marks.any(func(m: Dictionary) -> bool: return m.id == "space_landmark"),
				"MY MAP shows the Sunshade Lander once found")
			var t := (p.world.generator_shape() as SpaceShape).thermometer_column()
			p.spawn_on_surface(t.x + 2, t.y)   # beside the thermometer
			_next(0.0)
		7:
			if not _found(sandbox, &"thermometer", "standing by the thermometer says its fact"):
				return
			var face := (p.world.generator_shape() as SpaceShape).mercury.great_face_toward(p.world.spawn_column())
			p.spawn_on_surface(face.x, face.y)
			_next(0.0)
		8:
			if not _found(sandbox, &"scarp", "the long cliff's face says its fact"):
				return
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.MERCURY_ROCK, "standing on the cliff's rocky face (%s)" % BlockIds.display_name(under))
			var c := (p.world.generator_shape() as SpaceShape).mercury.nearest_crater(p.world.spawn_column())
			p.spawn_on_surface(c.x, c.y)
			_next(0.0)
		9:
			if not _found(sandbox, &"crater", "a big crater's peak says its fact"):
				return
			var ic := (p.world.generator_shape() as SpaceShape).mercury.ice_centre()
			p.spawn_on_surface(ic.x, ic.y)
			_next(0.0)
		10:
			if not _found(sandbox, &"ice", "the ice crater says its fact"):
				return
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.SHADOW_ICE, "standing on the shadowed crater's ice (%s)" % BlockIds.display_name(under))
			_check(p.health == null or p.health.hp == _health, "nothing on Mercury hurt the child (health %d)" % [
				p.health.hp if p.health else 0])
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
			_check((sandbox.sky as SkyCycle).sun_size == 1.0, "home's Sun again")
			_finish()


## True once sight `id` was found (its fact said); fails after 12 s.
func _found(sandbox: Node, id: StringName, what: String) -> bool:
	var sights: SpaceSights = sandbox.get("sights")
	if sights.found.has("sight:" + String(id)):
		_check(true, what)
		return true
	if _step_t > 12.0:
		_check(false, "%s (at %s)" % [what, (sandbox.player as Player).global_position])
		_next(0.0)
	return false


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
	print("MERCURY_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("MERCURY_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
