extends Node
## The steps of tools/titan_smoke.gd (cosmos, spec §21b.2), on real terrain through the real systems: the child's body
## climbs as flying does (its own position), the SpaceDirector opens the Star Map, Titan's card lands through the
## sandbox's trip (saves, the new world scene), the methane sea is swum in and leapt out of through the player's own
## swimming (JUMP held, as a child would), and the way home is owner #39's portal by the landing pad.

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
var _highest := -INF
var _swam := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.TITAN)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for slot: String in ["sandbox_1", "sandbox_22"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.bodies.erase("titan")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("TITAN_SMOKE begin")


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
			_check(SpaceRules.WORLDS.has(SpaceRules.TITAN) and UniverseRegistry.space_available().has(SpaceRules.TITAN),
				"Titan is a space world to land on")
			_check(BlockLibrary.liquid_methane() == 0.0, "home's water is water")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)   # take off away from the spawn: home must land here
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			_check(space.panel.title_text() == SpaceRules.TITLE, "the Star Map: \"%s\"" % space.panel.title_text())
			space.panel.body_for(&"titan").pressed.emit()
			_check(space.panel.card_title() == "Titan" and space.panel.card_facts().size() == 3,
				"Titan's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "LAND", "LAND on Titan (%s)" % space.panel.action_button.text)
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing on Titan"):
				return
			_check(Game.universe == SpaceRules.TITAN and Game.slot() == "sandbox_22", "Titan's own Sandbox world (%s)" % Game.slot())
			var shape := p.world.generator_shape() as SpaceShape
			_check(shape != null and shape.planet == SpaceShape.TITAN, "its terrain is Titan's")
			_check(is_equal_approx(LabRules.world_gravity, 0.14), "Titan's gravity (%.2f)" % LabRules.world_gravity)
			var sky: SkyCycle = sandbox.sky
			_check(sky.space == 0.0, "thick air: never space's black sky")
			var top: Color = sky.palette.get("sky_top", Color.BLACK)
			_check(top.r > top.b + 0.2, "an orange haze by day (%s)" % top)
			_check(not p.world.photo_sky, "never Earth's photo sky")
			_check(sky.planet() != null and sky.planet().visible and (sky.planet().mesh as QuadMesh).size.x > 120.0,
				"Saturn and its rings in the sky")
			_check(sky.moons().all(func(m: MeshInstance3D) -> bool: return not m.visible), "the haze hides Saturn's other moons")
			_check(BlockLibrary.liquid_methane() == 1.0, "its water looks like liquid methane")
			var amb := sandbox.get_node_or_null("Ambience") as Ambience
			_check(amb != null and amb.methane and not amb.chocolate, "the view under it is amber")
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.LANDING_PAD, "standing on the landing pad (%s)" % BlockIds.display_name(under))
			var monsters: MonsterDirector = sandbox.get_node("Monsters")
			_check(not bool(monsters.enabled.call()), "peaceful: no night monsters")
			var animals: Node = sandbox.get_node_or_null("AnimalDirector")
			_check(animals != null and animals.process_mode == Node.PROCESS_MODE_DISABLED, "no animals: no life we know of")
			var marks: Array = sandbox.places_director.marks
			var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
			_check(ids.has("space_pad"), "MY MAP shows the landing pad")
			for id in ["sight_sea", "sight_dunes", "sight_mountain"]:
				_check(ids.has(id), "MY MAP shows %s" % id)
			var marked := int(Profile.data.wonder.bodies.get("titan", 0))
			_check(marked & WonderData.LANDED != 0, "the Space Book marks Titan landed on")
			_check(sandbox.get("sights") is SpaceSights, "Titan's sights are watched")
			_check(sandbox.get("geysers") == null, "no geysers on Titan")
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
			_check(fall > 0.1 and fall < Player.GRAVITY * 0.2 * _step_t, "a slow Titan fall (%.2f m/s after %.2f s)" % [fall, _step_t])
			var rules: SpaceSecretRules = sandbox.get_node("Secrets").rules
			_landmark = rules.landmark()
			_check(_landmark.get("name") == "Landing Probe", "the Landing Probe is the landmark")
			var chest: Vector3i = _landmark.chest
			p.spawn_at(Vector3(chest) + Vector3(1.5, 0.05, 0.5))   # on its top, beside the chest
			_next(0.0)
		6:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			if not secrets.state.found.has(_landmark.id):
				if _step_t > 10.0:
					_check(false, "standing on the Landing Probe finds it")
					_next(0.0)
				return
			_check(true, "standing on the Landing Probe finds it")
			_check(sandbox.places_director.marks.any(func(m: Dictionary) -> bool: return m.id == "space_landmark"),
				"MY MAP shows the Landing Probe once found")
			var shape := p.world.generator_shape() as SpaceShape
			var beach := shape.titan.sea_beach_toward(shape.spawn_column())
			p.spawn_on_surface(beach.x, beach.y)   # on the methane sea's beach
			_next(0.0)
		7:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:sea"):
				if _step_t > 12.0:
					_check(false, "the methane sea's beach says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "the methane sea's beach says its fact")
			var shape := p.world.generator_shape() as SpaceShape
			var beach := shape.titan.sea_beach_toward(shape.spawn_column())
			var into := Vector2(shape.titan.sea_centre() - beach).normalized() * 14.0
			var at := beach + Vector2i(roundi(into.x), roundi(into.y))   # well out in the sea
			var liquid := p.world.get_block(Vector3i(at.x, TitanTerrain.LIQUID_TOP - 1, at.y))
			_check(liquid == BlockIds.WATER, "the sea is liquid (shown as methane) (%s)" % BlockIds.display_name(liquid))
			_health = p.health.hp if p.health != null else 0
			p.spawn_at(Vector3(at.x + 0.5, TitanTerrain.LIQUID_TOP - 1.3, at.y + 0.5))   # floating in it
			_swam = false
			_highest = -INF
			_next(0.0)
		8:
			if not _swam:
				if p.water_state >= SwimRules.State.SWIMMING:
					_swam = true
					_check(true, "swimming in the methane sea (%s)" % SwimRules.State.keys()[p.water_state])
					Input.action_press(&"jump")   # JUMP held, as a child would
				elif _step_t > 8.0:
					_check(false, "swimming in the methane sea (state %d at %s)" % [p.water_state, p.global_position])
					_next(0.0)
				return
			_highest = maxf(_highest, p.global_position.y)
			if _highest < TitanTerrain.LIQUID_TOP + 3.0 or p.velocity.y > 0.0:   # up 3 blocks, then its top
				if _step_t > 8.0:
					Input.action_release(&"jump")
					_check(false, "JUMP leaps the swimmer out (highest %.1f, the methane's top %d)" % [_highest, TitanTerrain.LIQUID_TOP])
					_next(0.0)
				return
			Input.action_release(&"jump")
			_check(true, "JUMP leaps the swimmer out like a dolphin (feet %.1f blocks over the methane at the top, %.1f s)" % [
				_highest - TitanTerrain.LIQUID_TOP, _step_t])
			_check(p.health == null or p.health.hp == _health, "and the methane never hurts (health %d)" % (p.health.hp if p.health else 0))
			var dune := (p.world.generator_shape() as SpaceShape).titan.first_dune_south_of(p.world.spawn_column())
			p.spawn_on_surface(dune.x, dune.y)
			_next(0.0)
		9:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:dunes"):
				if _step_t > 12.0:
					_check(false, "a dune says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.DUNE_SAND, "a dune says its fact, standing on dark grains (%s)" % BlockIds.display_name(under))
			var pk := (p.world.generator_shape() as SpaceShape).titan.peak_centre()
			p.spawn_on_surface(pk.x, pk.y)
			_next(0.0)
		10:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:mountain"):
				if _step_t > 12.0:
					_check(false, "the icy mountains' top says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "the icy mountains' top says its fact (height %.0f)" % p.global_position.y)
			var lake := _nearest_lake(p.world.generator_shape() as SpaceShape, p.world.spawn_column())
			p.spawn_on_surface(lake.x + lake.z + 1, lake.y)   # on a lake's beach
			print("TITAN_SMOKE info lake %s" % lake)
			_next(0.0)
		11:
			var sights: SpaceSights = sandbox.get("sights")
			if not sights.found.has("sight:lake"):
				if _step_t > 12.0:
					_check(false, "a methane lake's beach says its fact (at %s)" % p.global_position)
					_next(0.0)
				return
			_check(true, "a methane lake's beach says its fact")
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
			_check(BlockLibrary.liquid_methane() == 0.0, "home's water is water again")
			_finish()


## The methane lake nearest `from` ((centre x, centre z, radius)).
func _nearest_lake(shape: SpaceShape, from: Vector2i) -> Vector3i:
	var best := Vector3i.ZERO
	var best_d := INF
	var c := Vector2i(floori(from.x / float(TitanTerrain.LAKE_CELL)), floori(from.y / float(TitanTerrain.LAKE_CELL)))
	for dz in range(-4, 5):
		for dx in range(-4, 5):
			var l := shape.titan.lake_in_cell(c + Vector2i(dx, dz))
			if l.z > 0 and Vector2(l.x - from.x, l.y - from.y).length() < best_d:
				best_d = Vector2(l.x - from.x, l.y - from.y).length()
				best = l
	return best


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
	print("TITAN_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("TITAN_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Input.action_release(&"jump")
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
