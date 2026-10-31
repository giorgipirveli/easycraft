extends Node
## The steps of tools/colony_smoke.gd (spec §21c), on real terrain through the real systems: the child's body climbs as
## flying does (its own position), the SpaceDirector opens the Star Map, a planet's card lands through the sandbox's trip,
## and the colony is walked into part by part (the child's body put in each part, as walking does).

const TIMEOUT := 600.0
const SEED := 12345
const CLIMB_SPEED := 60.0         # m/s: a quick flight up (the real flight is 11 m/s)
const PART_WAIT := 8.0            # seconds a part may take to load and say its fact
const FRAMES := 3.0               # seconds of frames timed under the Great Dome, then on the plains far away
const SETTLE := 4.0               # seconds to let the terrain stream in before timing

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _left: Node
var _part := 0
var _frames: Array[float] = []
var _dome_frames: Array[float] = []
var _dome_again: Array[float] = []
var _planet := &"mars"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.missions.fly(SpaceRules.MARS)   # spec §21d: on the route (tools/mission_smoke.gd flies a mission)
	Profile.data.missions.fly(SpaceRules.MOON)
	for slot: String in ["sandbox_1", "sandbox_19", "sandbox_16"]:
		WorldSaves.delete(slot)
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("COLONY_SMOKE begin")


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
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += Vector3(12, 3, 7)
			_next(0.1)
		1:
			if _climb(p, space, delta):
				_next(0.0)
		2:
			_land(sandbox, space, &"mars", "Mars")
		3:
			if not _arrived(sandbox, "landing on Mars"):
				return
			_check(Game.universe == SpaceRules.MARS and Game.slot() == "sandbox_19", "Mars's own world (%s)" % Game.slot())
			_arrival(sandbox, p, "Mars Colony")
			var animals: Node = sandbox.get_node_or_null("AnimalDirector")
			_check(animals != null and animals.process_mode == Node.PROCESS_MODE_DISABLED,
				"no animals outside on Mars: no life we know of")
			_check(ShopRules.catalog(ShopRules.BLOCKS, SpaceRules.MARS).has(BlockIds.DOME_GLASS), "Tilly sells dome glass")
			_go_to(p, ColonyRules.DOME)
			_next(0.0)
		4:
			if _dome(sandbox, p):
				_part = 0
				_next(0.0)
		5:
			if _walk_parts(sandbox, p):
				_next(0.0)
		6:   # frames (headless: the CPU side) under the Great Dome, its animals about: twice in a row, then far away
			_go_to(p, ColonyRules.DOME)
			_frames.clear()
			_next(SETTLE)
		7:
			_frames.append(delta * 1000.0)
			if _step_t < FRAMES:
				return
			_dome_frames = _frames.duplicate()
			_frames.clear()
			_next(0.0)
		8:
			_frames.append(delta * 1000.0)
			if _step_t < FRAMES:
				return
			_dome_again = _frames.duplicate()
			var c := (p.world.generator_shape() as SpaceShape).colony
			var far := c.centre + Vector2i(260, 0)
			p.spawn_at(Vector3(far.x + 0.5, p.world.find_standing_y(far.x, far.y) + 0.05, far.y + 0.5))
			_frames.clear()
			_next(SETTLE)
		9:
			_frames.append(delta * 1000.0)
			if _step_t < FRAMES:
				return
			var a := _stats(_dome_frames)
			var b := _stats(_dome_again)
			var plains := _stats(_frames)
			print("COLONY_SMOKE frames (headless: the CPU side) under_dome avg_ms=%.1f worst_ms=%.1f, again avg_ms=%.1f worst_ms=%.1f, far_plains avg_ms=%.1f worst_ms=%.1f" % [
				a.x, a.y, b.x, b.y, plains.x, plains.y])
			_check(b.y < 250.0, "no long frame under the Great Dome (%.0f ms)" % b.y)
			_go_to(p, ColonyRules.LAB)
			_next(SETTLE)
		10:
			_lab(sandbox, p)
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += Vector3(0, 3, 0)
			_next(0.1)
		11:
			if _climb(p, space, delta):
				_next(0.0)
		12:
			_planet = &"moon"
			_land(sandbox, space, &"moon", "The Moon")
		13:
			if not _arrived(sandbox, "landing on the Moon"):
				return
			_check(Game.universe == SpaceRules.MOON and Game.slot() == "sandbox_16", "the Moon's own world (%s)" % Game.slot())
			_arrival(sandbox, p, "Moon Colony")
			_go_to(p, ColonyRules.DOME)
			_next(0.0)
		14:
			if _dome(sandbox, p):
				_part = 0
				_next(0.0)
		15:
			if _walk_parts(sandbox, p):
				_finish()


## (average, worst) of frame times.
func _stats(list: Array) -> Vector2:
	var avg := 0.0
	var worst := 0.0
	for f: float in list:
		avg += f
		worst = maxf(worst, f)
	return Vector2(avg / maxf(list.size(), 1.0), worst)


## The Star Map shows, the planet's card, LAND.
func _land(sandbox: Node, space: SpaceDirector, id: StringName, title: String) -> void:
	_check(space.panel.visible, "the Star Map opened")
	space.panel.body_for(id).pressed.emit()
	_check(space.panel.card_title() == title, "%s's card" % title)
	_check(space.panel.action_button.text == "LAND", "LAND on %s (%s)" % [title, space.panel.action_button.text])
	space.panel.action_button.pressed.emit()
	_left = sandbox
	_next(0.1)


## On arrival: the colony is there, a short walk from the pad; MY MAP shows it; the explorer's checklist lists it; the
## Great Dome's animals are looked after.
func _arrival(sandbox: Node, p: Player, name: String) -> void:
	var shape := p.world.generator_shape() as SpaceShape
	_check(shape != null and shape.colony != null, "%s: the colony stands here" % name)
	if shape == null or shape.colony == null:
		_finish()
		return
	var pad := Vector2(shape.spawn_column())
	_check(Vector2(shape.colony.entrance()).distance_to(pad) < 32.0, "its airlock a short walk from the pad (%.0f)" %
		Vector2(shape.colony.entrance()).distance_to(pad))
	var marks: Array = sandbox.places_director.marks
	var mine := marks.filter(func(m: Dictionary) -> bool: return m.id == "sight_colony")
	_check(mine.size() == 1 and mine[0].name == name, "MY MAP shows the %s" % name)
	var own := UniverseRegistry.sights(Game.universe)
	var list := PlanetGuideRules.checklist(shape.sights(), own, {}, Vector3.ZERO)
	_check(list.any(func(e: Dictionary) -> bool: return e.name == name), "the explorer's checklist lists the %s" % name)
	_check(sandbox.get("colony_animals") is ColonyAnimals, "the Great Dome's animals are looked after")


## Under the Great Dome in the real terrain: glass, grass, the garden, the animals, bees and butterflies; its fact.
func _dome(sandbox: Node, p: Player) -> bool:
	var c := (p.world.generator_shape() as SpaceShape).colony
	var g := c.world(7, 7)
	var glass := Vector3i(g.x, c.ground + 2, g.y)
	var lawn := Vector3i(c.centre.x, c.ground - 1, c.centre.y)
	var loaded := p.world.is_editable(glass) and p.world.is_editable(lawn)
	var herd: ColonyAnimals = sandbox.get("colony_animals")
	var n := herd.alive().size() if herd else 0
	var sights_now: SpaceSights = sandbox.get("sights")
	var said := sights_now != null and sights_now.found.has("sight:colony")
	if (not loaded or n < 5 or not said) and _step_t < 20.0:
		return false
	_check(p.world.get_block(glass) == BlockIds.DOME_GLASS, "%s: the Great Dome's glass" % _planet)
	_check(p.world.get_block(lawn) == BlockIds.GRASS, "%s: its grass" % _planet)
	var soil := c.world(ColonyLayout.ROWS[0], 3)
	_check(p.world.get_block(Vector3i(soil.x, c.ground - 1, soil.y)) == BlockIds.GREENHOUSE_SOIL, "its garden's soil")
	_check(n >= 5, "%s: the dome's animals came (%d)" % [_planet, n])
	var inside := 0
	for a: Animal in herd.alive().values():
		if c.in_great_dome(floori(a.global_position.x), floori(a.global_position.z)):
			inside += 1
	_check(inside == n, "all of them under the glass (%d of %d)" % [inside, n])
	var sights: SpaceSights = sandbox.get("sights")
	_check(sights != null and sights.found.has("sight:colony"), "%s: walking in says the Great Dome's fact" % _planet)
	var bugs := sandbox.get_node_or_null("ColonyInsects") as MeadowInsects
	_check(bugs != null and bugs.flying(), "bees and butterflies over the dome's grass")
	return true


## Every part in turn: the child stands in it, its fact is said (kept in the world's secrets).
func _walk_parts(sandbox: Node, p: Player) -> bool:
	var sights: SpaceSights = sandbox.get("sights")
	var part: StringName = ColonyRules.PARTS[_part]
	if sights.found.has("sight:" + String(part)):
		_check(true, "%s: %s says its fact" % [_planet, part])
	elif _step_t < PART_WAIT:
		return false   # the child stands there (put there once: a spawn waits for the terrain)
	else:
		var at := Player.position_or_none(p)
		_check(false, "%s: %s says its fact (at %s: sight %s, ground %d, processing %s)" % [_planet, part, at,
			sights.shape.sight_at(floori(at.x), floori(at.z)) if at.is_finite() else &"?",
			sights.shape.height_at(floori(p.global_position.x), floori(p.global_position.z)), sights.can_process()])
	_part += 1
	_step_t = 0.0
	if _part >= ColonyRules.PARTS.size():
		return true
	_go_to(p, ColonyRules.PARTS[_part])
	return false


## The lab's bench opens the Science Lab (spec §23: "the Science Lab works there").
func _lab(sandbox: Node, p: Player) -> void:
	var c := (p.world.generator_shape() as SpaceShape).colony
	var d: Vector2i = ColonyLayout.DOMES[ColonyRules.LAB]
	var at := c.world(d.x - 1, d.y + 3)
	var cell := Vector3i(at.x, c.ground, at.y)
	_check(p.world.get_block(cell) == BlockIds.LAB_BENCH, "the lab's bench stands in the lab")
	var interactor: Node = sandbox.get("_interactor")
	interactor.lab_bench_tapped.emit(cell)
	var lab: LabPanel = sandbox.get("lab_panel")
	_check(lab != null and lab.visible, "a tap on it opens the Science Lab")
	if lab:
		lab.close()


func _go_to(p: Player, part: StringName) -> void:
	var c := (p.world.generator_shape() as SpaceShape).colony
	var at := c.part_centre(part)
	p.set_physics_mode(PhysicsMode.Mode.NORMAL)
	var y := p.world.find_standing_y(at.x, at.y)
	if part == ColonyRules.MINE:
		y = c.ground - 4   # the pit's floor
	p.spawn_at(Vector3(at.x + 0.5, y + 0.05, at.y + 0.5))


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


## True once a new world scene stands (after `_left`); fails after 60 s (the landing is played first).
func _arrived(sandbox: Node, what: String) -> bool:
	if sandbox != _left:
		return true
	if _step_t > 60.0:
		_check(false, what)
		_finish()
	return false


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("COLONY_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("COLONY_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
