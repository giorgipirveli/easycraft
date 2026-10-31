extends Node
## The steps of tools/venus_smoke.gd (cosmos, spec §21b.2), on real terrain through the real systems: the child's body
## climbs as flying does (its own position), the SpaceDirector opens the Star Map, Venus's card lands through the
## sandbox's trip (saves, the new world scene), the fall is a real fall caught by the player's own void step, the sights
## are found by standing at them, and the way home is owner #39's portal by the landing pad.

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
var _carried: Array = []
var _low := INF
var _stood := Vector3.ZERO
var _sights: Array[StringName] = [&"scope", &"dock", &"garden", &"homes", &"lookout"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.VENUS)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for slot: String in ["sandbox_1", "sandbox_24"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.bodies.erase("venus")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("VENUS_SMOKE begin")


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
			_check(SpaceRules.WORLDS.has(SpaceRules.VENUS) and UniverseRegistry.space_available().has(SpaceRules.VENUS),
				"Venus is a space world to land on")
			_check(not (sandbox.sky as SkyCycle).sun_west, "home's Sun rises in the east")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)   # take off away from the spawn: home must land here
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			_check(space.panel.title_text() == SpaceRules.TITLE, "the Star Map: \"%s\"" % space.panel.title_text())
			space.panel.body_for(&"venus").pressed.emit()
			_check(space.panel.card_title() == "Venus" and space.panel.card_facts().size() == 3,
				"Venus's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "LAND", "LAND on Venus (%s)" % space.panel.action_button.text)
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing on Venus"):
				return
			_check(Game.universe == SpaceRules.VENUS and Game.slot() == "sandbox_24",
				"Venus's own Sandbox world (%s)" % Game.slot())
			var shape := p.world.generator_shape() as SpaceShape
			_check(shape != null and shape.planet == SpaceShape.VENUS, "its terrain is Venus's cloud city")
			_check(is_equal_approx(LabRules.world_gravity, 0.9), "Venus's gravity (%.2f)" % LabRules.world_gravity)
			var sky: SkyCycle = sandbox.sky
			_check(sky.space == 0.0, "thick air: a sky of its own")
			_check(is_equal_approx(sky.sun_size, 1.4), "the Sun a little bigger (%.1f)" % sky.sun_size)
			_check(sky.sun_west, "Venus spins backwards: its Sun rises in the west")
			var toward := p.world.sun().global_transform.basis.z
			if DayCycle.wrap_time(sky.time) < DayCycle.NOON and DayCycle.daylight(sky.time) > 0.5:
				_check(toward.x < 0.0, "this morning the Sun is in the west (toward %s)" % toward)
			var mat := p.world.environment().sky.sky_material as ProceduralSkyMaterial
			_check(mat != null and mat.sky_top_color.r > mat.sky_top_color.b + 0.2, "a golden sky (%s)" % (
				mat.sky_top_color if mat else Color.BLACK))
			_check(not p.world.photo_sky, "never Earth's photo sky")
			_check(sky.planet() != null and sky.planet().visible and (sky.planet().mesh as QuadMesh).size.x < 8.0,
				"Earth, a tiny point")
			var under := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.1, 0)).floor()))
			_check(under == BlockIds.LANDING_PAD, "standing on the landing pad (%s)" % BlockIds.display_name(under))
			var monsters: MonsterDirector = sandbox.get_node("Monsters")
			_check(not bool(monsters.enabled.call()), "peaceful: no night monsters")
			var animals: Node = sandbox.get_node_or_null("AnimalDirector")
			_check(animals != null and animals.process_mode == Node.PROCESS_MODE_DISABLED, "no animals: no life we know of")
			var marks: Array = sandbox.places_director.marks
			var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
			_check(ids.has("space_pad"), "MY MAP shows the landing pad")
			for id in _sights:
				_check(ids.has("sight_" + String(id)), "MY MAP shows the %s" % id)
			var marked := int(Profile.data.wonder.bodies.get("venus", 0))
			_check(marked & WonderData.LANDED != 0, "the Space Book marks Venus landed on")
			_check(sandbox.get("sights") is SpaceSights, "Venus's sights are watched")
			_check(sandbox.get("geysers") == null, "no geysers on Venus")
			_check(sandbox.get("lightning") is VenusLightning, "lightning far below in the clouds")
			_check(p.in_void_world(), "the city floats over the clouds: a warm breeze catches a faller")
			var creatures: SpaceCreatures = sandbox.get("creatures")
			_check(creatures != null and creatures.camp != null, "the robots and the aliens' camp")
			if creatures and creatures.camp:
				var at: Vector3 = creatures.site.pos
				_check(shape.venus.camp_spot(floori(at.x), floori(at.z)), "the camp on its own deck (%s)" % at)
			_health = p.health.hp if p.health != null else 0
			_next(1.0)
		4:
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			_check(frames.gates.gate_to(1) != null, "the portal home stands by the pad (%s)" % str(frames.gates.to_save()))
			var v := (p.world.generator_shape() as SpaceShape).venus
			var sp := p.world.spawn_column()
			var out := -v.north()
			var scope := sp + out * VenusTerrain.SCOPE_OUT
			_check(p.world.get_block(Vector3i(scope.x, VenusTerrain.DECK_Y + 1, scope.y)) == BlockIds.TELESCOPE,
				"the cloud scope by the pad")
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			var edge := sp + out * 12 + Vector2i(6, 0)
			p.spawn_at(Vector3(edge.x + 0.5, VenusTerrain.DECK_Y + 0.05, edge.y + 0.5))   # on the landing deck
			_carried.clear()
			if not p.carried_back.is_connected(_on_carried):
				p.carried_back.connect(_on_carried)
			_next(1.0)
		5:
			if _step_t < 0.8:
				return
			_stood = p.global_position
			var v := (p.world.generator_shape() as SpaceShape).venus
			var off := p.world.spawn_column() - v.north() * 34
			p.global_position = Vector3(off.x + 0.5, VenusTerrain.DECK_Y + 0.5, off.y + 0.5)   # off the deck, over the clouds
			p.velocity = Vector3.ZERO
			_low = INF
			_next(0.0)
		6:
			_low = minf(_low, p.global_position.y)
			if _carried.is_empty() and _step_t < 12.0:
				return
			_check(not _carried.is_empty(), "a warm breeze lifted the child back")
			_check(_low < VenusTerrain.DECK_Y - 10.0 and _low > VenusTerrain.CLOUD_HIGH,
				"a real fall, never into the clouds (lowest y %.1f)" % _low)
			_next(0.6)
		7:
			var feet := p.global_position
			_check(feet.y > VenusTerrain.DECK_Y - 0.5 and Vector2(feet.x - _stood.x, feet.z - _stood.z).length() < 1.5,
				"back on the deck where it stood (%s, stood at %s)" % [feet, _stood])
			var toast := sandbox.hud.get("_toast_label") as Label
			_check(toast != null and toast.text.contains("breeze"), "it says \"%s\"" % (toast.text if toast else ""))
			var rules: SpaceSecretRules = sandbox.get_node("Secrets").rules
			_landmark = rules.landmark()
			_check(_landmark.get("name") == "Research Blimp", "the Research Blimp is the landmark")
			var chest: Vector3i = _landmark.chest
			p.spawn_at(Vector3(chest) + Vector3(-0.5, 0.05, 0.5))   # in its gondola, beside the chest
			_next(0.0)
		8:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			if not secrets.state.found.has(_landmark.id):
				if _step_t > 10.0:
					_check(false, "walking into the Research Blimp's gondola finds it")
					_next(0.0)
				return
			_check(true, "walking into the Research Blimp's gondola finds it")
			_check(sandbox.places_director.marks.any(func(m: Dictionary) -> bool: return m.id == "space_landmark"),
				"MY MAP shows the Research Blimp once found")
			_stand_at(p, _sights[0])
			_next(0.0)
		9, 10, 11, 12, 13:
			var id := _sights[_step - 9]
			if not _found(sandbox, id, "the %s says its fact" % id):
				return
			if _step < 13:
				_stand_at(p, _sights[_step - 8])
				_next(0.0)
				return
			_check(p.health == null or p.health.hp == _health, "nothing on Venus hurt the child (health %d)" % [
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
		14:
			if not _arrived(sandbox, "walking into the portal home"):
				return
			_check(Game.universe == 1 and Game.slot() == "sandbox_1", "home in Green Meadows (%s)" % Game.slot())
			var col := Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_check(col == _take_off, "landed on the take-off column (%s, took off at %s)" % [col, _take_off])
			_check(is_equal_approx(LabRules.world_gravity, 1.0), "home gravity again")
			_check(not (sandbox.sky as SkyCycle).sun_west, "home's Sun rises in the east again")
			_finish()


func _on_carried(to: Vector3) -> void:
	_carried.append(to)


## Stands the child at sight `id`'s spot.
func _stand_at(p: Player, id: StringName) -> void:
	var v := (p.world.generator_shape() as SpaceShape).venus
	for e: Array in v.sight_spots():
		if e[0] == id:
			var at: Vector2i = e[1]
			p.spawn_on_surface(at.x, at.y)
			return


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
	print("VENUS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("VENUS_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
