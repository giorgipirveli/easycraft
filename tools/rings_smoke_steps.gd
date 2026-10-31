extends Node
## The steps of tools/rings_smoke.gd (cosmos, spec §21b.2), on real terrain through the real systems: the child's body
## climbs as flying does (its own position), the SpaceDirector opens the Star Map, Saturn's card lands through the
## sandbox's trip (saves, the new world scene) in its rings, the fall is a real fall (a slow one, at 0.05 gravity) caught
## by the player's own void step, the sights are found by standing at them, and the way home is owner #39's portal by the
## landing pad.

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
var _sights: Array[StringName] = [&"scope", &"station", &"cassini", &"c_ring", &"f_ring", &"pan"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.RINGS)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for slot: String in ["sandbox_1", "sandbox_25"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.bodies.erase("saturn")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("RINGS_SMOKE begin")


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


func _rings(p: Player) -> RingsTerrain:
	return (p.world.generator_shape() as SpaceShape).rings


func _run_step(sandbox: Node, delta: float) -> void:
	var p: Player = sandbox.player
	var space: SpaceDirector = sandbox.get("space")
	match _step:
		0:
			_check(Game.slot() == "sandbox_1", "a new Green Meadows Sandbox world (%s)" % Game.slot())
			_check(SpaceRules.WORLDS.has(SpaceRules.RINGS) and UniverseRegistry.space_available().has(SpaceRules.RINGS),
				"Saturn's rings are a space world to land on")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)   # take off away from the spawn: home must land here
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			_check(space.panel.title_text() == SpaceRules.TITLE, "the Star Map: \"%s\"" % space.panel.title_text())
			space.panel.body_for(&"saturn").pressed.emit()
			_check(space.panel.card_title() == "Saturn" and space.panel.card_facts().size() == 3,
				"Saturn's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "Saturn's rings: LAND",
				"LAND in Saturn's rings (%s)" % space.panel.action_button.text)
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing in Saturn's rings"):
				return
			_check(Game.universe == SpaceRules.RINGS and Game.slot() == "sandbox_25",
				"the rings' own Sandbox world (%s)" % Game.slot())
			var shape := p.world.generator_shape() as SpaceShape
			_check(shape != null and shape.planet == SpaceShape.RINGS, "its terrain is Saturn's rings")
			_check(is_equal_approx(LabRules.world_gravity, 0.05), "the rings' gravity (%.2f)" % LabRules.world_gravity)
			var sky: SkyCycle = sandbox.sky
			_check(sky.space == 1.0, "no air: space's black sky")
			_check(is_equal_approx(sky.sun_size, 0.1), "the Sun about ten times smaller (%.2f)" % sky.sun_size)
			_check(not sky.sun_west, "the Sun rises in the east")
			_check(sky.get_node("NightSky/Stars").visible, "stars in the black sky")
			_check(not p.world.photo_sky, "never Earth's photo sky")
			var planet := sky.planet()
			_check(planet != null and planet.visible and (planet.mesh as QuadMesh).size.x >= 300.0,
				"Saturn huge in the sky (%s)" % ((planet.mesh as QuadMesh).size if planet else Vector2.ZERO))
			if planet:
				_check(planet.position.normalized().z < -0.9, "over the northern horizon (%s)" % planet.position.normalized())
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
			var marked := int(Profile.data.wonder.bodies.get("saturn", 0))
			_check(marked & WonderData.LANDED != 0, "the Space Book marks Saturn landed on")
			_check(sandbox.get("sights") is SpaceSights, "the rings' sights are watched")
			_check(sandbox.get("geysers") == null, "no geysers in the rings")
			_check(sandbox.get("lightning") == null, "no lightning: no air")
			_check(p.in_void_world(), "the chunks float over open space: the suit's jets catch a faller")
			var creatures: SpaceCreatures = sandbox.get("creatures")
			_check(creatures != null and creatures.camp != null, "the robots and the aliens' camp")
			if creatures and creatures.camp:
				var at: Vector3 = creatures.site.pos
				_check(shape.rings.camp_spot(floori(at.x), floori(at.z)), "the camp on its own chunk (%s)" % at)
			_health = p.health.hp if p.health != null else 0
			_next(1.0)
		4:
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			_check(frames.gates.gate_to(1) != null, "the portal home stands by the pad (%s)" % str(frames.gates.to_save()))
			var sp := p.world.spawn_column()
			_check(p.world.get_block(Vector3i(sp.x, RingsTerrain.TOP_BASE + 1, sp.y - RingsTerrain.SCOPE_OUT))
				== BlockIds.TELESCOPE, "the Saturn scope by the pad")
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			var edge := sp + Vector2i(-6, -12)
			p.spawn_at(Vector3(edge.x + 0.5, RingsTerrain.TOP_BASE + 0.05, edge.y + 0.5))   # on the landing chunk
			_carried.clear()
			if not p.carried_back.is_connected(_on_carried):
				p.carried_back.connect(_on_carried)
			_next(1.0)
		5:
			if _step_t < 0.8:
				return
			_stood = p.global_position
			var r := _rings(p)
			var sp := p.world.spawn_column()
			var off := Vector2i.ZERO
			for k in range(26, 200):   # the first open space north of the landing chunk
				var c := sp + Vector2i(0, -k)
				if r.kind_at(c.x, c.y) == RingsTerrain.VOID and r.kind_at(c.x + 1, c.y) == RingsTerrain.VOID \
						and r.kind_at(c.x - 1, c.y) == RingsTerrain.VOID and r.kind_at(c.x, c.y - 1) == RingsTerrain.VOID:
					off = c
					break
			_check(off != Vector2i.ZERO, "open space between the chunks (%s)" % off)
			p.global_position = Vector3(off.x + 0.5, RingsTerrain.TOP_BASE + 0.5, off.y + 0.5)   # off the chunk
			p.velocity = Vector3.ZERO
			_low = INF
			_next(0.0)
		6:
			_low = minf(_low, p.global_position.y)
			if _carried.is_empty() and _step_t < 16.0:
				return
			_check(not _carried.is_empty(), "the space suit's jets carried the child back (%.1f s)" % _step_t)
			_check(_low < RingsTerrain.TOP_BASE - 8.0 and _low > RingsTerrain.LIFT_Y - 3.0,
				"a real (slow) fall, never far under the rings (lowest y %.1f)" % _low)
			_next(0.6)
		7:
			var feet := p.global_position
			_check(feet.y > RingsTerrain.TOP_BASE - 0.5 and Vector2(feet.x - _stood.x, feet.z - _stood.z).length() < 1.5,
				"back on the ice where it stood (%s, stood at %s)" % [feet, _stood])
			var toast := sandbox.hud.get("_toast_label") as Label
			_check(toast != null and toast.text.contains("jets"), "it says \"%s\"" % (toast.text if toast else ""))
			var rules: SpaceSecretRules = sandbox.get_node("Secrets").rules
			_landmark = rules.landmark()
			_check(_landmark.get("name") == "Ring Explorer", "the Ring Explorer is the landmark")
			var inside: Vector3i = _landmark.anchor
			p.spawn_at(Vector3(inside) + Vector3(0.5, 0.05, 0.5))   # in its room, beside the chest
			_next(0.0)
		8:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			if not secrets.state.found.has(_landmark.id):
				if _step_t > 10.0:
					_check(false, "walking into the Ring Explorer finds it")
					_next(0.0)
				return
			_check(true, "walking into the Ring Explorer finds it")
			_check(sandbox.places_director.marks.any(func(m: Dictionary) -> bool: return m.id == "space_landmark"),
				"MY MAP shows the Ring Explorer once found")
			_stand_at(p, _sights[0])
			_next(0.0)
		9, 10, 11, 12, 13, 14:
			var id := _sights[_step - 9]
			if not _found(sandbox, id, "the %s says its fact" % id):
				return
			if _step < 14:
				_stand_at(p, _sights[_step - 8])
				_next(0.0)
				return
			_check(p.health == null or p.health.hp == _health, "nothing in the rings hurt the child (health %d)" % [
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
		15:
			if not _arrived(sandbox, "walking into the portal home"):
				return
			_check(Game.universe == 1 and Game.slot() == "sandbox_1", "home in Green Meadows (%s)" % Game.slot())
			var col := Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_check(col == _take_off, "landed on the take-off column (%s, took off at %s)" % [col, _take_off])
			_check(is_equal_approx(LabRules.world_gravity, 1.0), "home gravity again")
			_check((sandbox.sky as SkyCycle).space < 1.0, "home's own sky again")
			_finish()


func _on_carried(to: Vector3) -> void:
	_carried.append(to)


## Stands the child at sight `id`'s spot.
func _stand_at(p: Player, id: StringName) -> void:
	for e: Array in _rings(p).sight_spots():
		if e[0] == id:
			var at: Vector2i = e[1]
			p.spawn_on_surface(at.x, at.y)
			return


## True once sight `id` was found (its fact said); fails after 15 s (the far sights' terrain loads first).
func _found(sandbox: Node, id: StringName, what: String) -> bool:
	var sights: SpaceSights = sandbox.get("sights")
	if sights.found.has("sight:" + String(id)):
		_check(true, what)
		return true
	if _step_t > 15.0:
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
	print("RINGS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("RINGS_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
