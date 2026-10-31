extends Node
## The steps of tools/pluto_smoke.gd (cosmos, spec §21b.2), on real terrain through the real systems: the child's body
## climbs as flying does (its own position), the SpaceDirector opens the Star Map, Pluto's card lands through the
## sandbox's trip (saves, the new world scene), the fall and the jump are the player's own at 0.063 gravity, the sights are
## found by standing at them, and the way home is owner #39's portal by the landing pad.

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
var _start_y := 0.0
var _highest := -INF
var _sights: Array[StringName] = [&"lookout", &"heart", &"hills", &"mountains", &"dark", &"bright"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.PLUTO)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	for slot: String in ["sandbox_1", "sandbox_26"]:
		WorldSaves.delete(slot)
	Profile.data.wonder.bodies.erase("pluto")
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("PLUTO_SMOKE begin")


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


func _shape(p: Player) -> SpaceShape:
	return p.world.generator_shape() as SpaceShape


func _run_step(sandbox: Node, delta: float) -> void:
	var p: Player = sandbox.player
	var space: SpaceDirector = sandbox.get("space")
	match _step:
		0:
			_check(Game.slot() == "sandbox_1", "a new Green Meadows Sandbox world (%s)" % Game.slot())
			_check(SpaceRules.WORLDS.has(SpaceRules.PLUTO) and UniverseRegistry.space_available().has(SpaceRules.PLUTO),
				"Pluto is a space world to land on")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += OFF_SPAWN + Vector3(0, 3, 0)   # take off away from the spawn: home must land here
			_take_off = Vector2i(floori(p.global_position.x), floori(p.global_position.z))
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			_check(space.panel.title_text() == SpaceRules.TITLE, "the Star Map: \"%s\"" % space.panel.title_text())
			space.panel.body_for(&"pluto").pressed.emit()
			_check(space.panel.card_title() == "Pluto" and space.panel.card_facts().size() == 3,
				"Pluto's card: %s, %d facts" % [space.panel.card_title(), space.panel.card_facts().size()])
			_check(space.panel.action_button.text == "LAND", "LAND on Pluto (%s)" % space.panel.action_button.text)
			space.panel.action_button.pressed.emit()
			_left = sandbox
			_next(0.1)
		3:
			if not _arrived(sandbox, "landing on Pluto"):
				return
			_check(Game.universe == SpaceRules.PLUTO and Game.slot() == "sandbox_26", "Pluto's own Sandbox world (%s)" % Game.slot())
			var shape := _shape(p)
			_check(shape != null and shape.planet == SpaceShape.PLUTO, "its terrain is Pluto's")
			_check(is_equal_approx(LabRules.world_gravity, 0.063), "Pluto's gravity (%.3f)" % LabRules.world_gravity)
			var sky: SkyCycle = sandbox.sky
			_check(sky.space > 0.4 and sky.space < 0.8, "a thin air: mostly space's black sky (%.2f)" % sky.space)
			var haze: Color = sky.palette.get("sky_horizon", Color.BLACK)
			_check(haze.b > haze.r + 0.3, "a blue haze along the horizon (%s)" % haze)
			_check(is_equal_approx(sky.sun_size, 0.025), "the Sun a tiny bright star (%.3f)" % sky.sun_size)
			_check(sky.sun_west, "the Sun rises in the west: Pluto spins backwards")
			_check(sky.get_node("NightSky/Stars").visible, "stars by day")
			_check(not p.world.photo_sky, "never Earth's photo sky")
			var charon := sky.planet()
			_check(charon != null and charon.visible and (charon.mesh as QuadMesh).size.x >= 50.0, "Charon big in the sky")
			if charon:
				_check(charon.position.normalized().x < -0.8, "in the west (%s)" % charon.position.normalized())
			_check(not sky.get_node("NightSky/Moon").visible, "never home's moon disc")
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
			var marked := int(Profile.data.wonder.bodies.get("pluto", 0))
			_check(marked & WonderData.LANDED != 0, "the Space Book marks Pluto landed on")
			_check(sandbox.get("sights") is SpaceSights, "Pluto's sights are watched")
			_check(sandbox.get("geysers") == null, "no geysers on Pluto")
			_check(not p.in_void_world(), "solid ground everywhere")
			var creatures: SpaceCreatures = sandbox.get("creatures")
			_check(creatures != null and creatures.robot != null and creatures.robot.display_name == "Nixie",
				"Nixie the helper robot")
			_check(creatures != null and creatures.camp != null, "the aliens' camp")
			if creatures and creatures.camp:
				var at: Vector3 = creatures.site.pos
				_check(shape.pluto_kind(floori(at.x), floori(at.z)) == PlutoTerrain.UPLANDS, "the camp on the uplands (%s)" % at)
			_health = p.health.hp if p.health != null else 0
			_next(1.0)
		4:
			var frames: PortalDirector = sandbox.get_node("PortalFrames")
			_check(frames.gates.gate_to(1) != null, "the portal home stands by the pad (%s)" % str(frames.gates.to_save()))
			var pl := _shape(p).pluto
			var scope := Vector3i(pl.lookout.x - 2, pl.lookout_y + 3, pl.lookout.y)
			_check(p.world.get_block(scope) == BlockIds.TELESCOPE, "the Charon Lookout's telescope by the pad")
			var globe := Vector3i(pl.lookout.x + 1, pl.lookout_y + 1, pl.lookout.y + 1)
			_check(p.world.get_block(globe) == BlockIds.CHARON_GLOBE, "and its globe of Charon")
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			p.global_position += Vector3(0, 6, 0)
			p.velocity = Vector3.ZERO
			_next(0.0)
		5:
			if _step_t < 0.3:
				return
			var fall := -p.velocity.y
			_check(fall > 0.1 and fall < Player.GRAVITY * 0.1 * _step_t, "a slow Pluto fall (%.2f m/s after %.2f s)" % [
				fall, _step_t])
			_next(0.0)
		6:
			if not p.is_on_floor():
				if _step_t > 12.0:
					_check(false, "back on the ground after the fall")
					_next(0.0)
				return
			_start_y = p.global_position.y
			_highest = _start_y
			Input.action_press(&"jump")
			_next(0.0)
		7:
			if _step_t > 0.15:
				Input.action_release(&"jump")
			_highest = maxf(_highest, p.global_position.y)
			if _step_t < 1.0 or p.velocity.y > 0.0:
				if _step_t > 15.0:
					_check(false, "a jump (highest %.1f over the ground)" % (_highest - _start_y))
					_next(0.0)
				return
			_check(_highest - _start_y > 20.0, "a very high, floaty jump (%.1f blocks up in %.1f s)" % [
				_highest - _start_y, _step_t])
			var rules: SpaceSecretRules = sandbox.get_node("Secrets").rules
			_landmark = rules.landmark()
			_check(_landmark.get("name") == "Balloon Lander", "the Balloon Lander is the landmark")
			var chest: Vector3i = _landmark.chest
			p.spawn_at(Vector3(chest) + Vector3(1.5, 0.05, 0.5))   # on its deck, beside the chest
			_next(0.0)
		8:
			var secrets: SecretDirector = sandbox.get_node("Secrets")
			if not secrets.state.found.has(_landmark.id):
				if _step_t > 10.0:
					_check(false, "standing on the Balloon Lander's deck finds it")
					_next(0.0)
				return
			_check(true, "standing on the Balloon Lander's deck finds it")
			_check(sandbox.places_director.marks.any(func(m: Dictionary) -> bool: return m.id == "space_landmark"),
				"MY MAP shows the Balloon Lander once found")
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
			_check(p.health == null or p.health.hp == _health, "nothing on Pluto hurt the child (health %d)" % [
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
			_check((sandbox.sky as SkyCycle).space < 0.5 and is_equal_approx((sandbox.sky as SkyCycle).sun_size, 1.0)
				and not (sandbox.sky as SkyCycle).sun_west, "home's own sky and Sun again")
			_finish()


## Stands the child at sight `id`'s spot (the lookout: on its floor, beside the telescope).
func _stand_at(p: Player, id: StringName) -> void:
	var shape := _shape(p)
	if id == &"lookout":
		var lk := shape.pluto.lookout
		p.spawn_on_surface(lk.x, lk.y + 2)
		return
	for e: Dictionary in shape.sights():
		if e.id == id:
			var at: Vector3 = e.pos
			p.spawn_on_surface(floori(at.x), floori(at.z))
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
	print("PLUTO_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("PLUTO_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Input.action_release(&"jump")
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
