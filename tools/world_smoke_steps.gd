extends Node
## The steps of tools/world_smoke.gd (owner feedback #45b), in a new Sandbox world of seed 12345 with the real
## terrain, streaming, directors and save: the world is the wild meadows (terrain version 2), the nearest village is
## in the generated terrain (the well, the paths, a house door), walking in finds it (the host's PlacesDirector, the
## save), its villagers stand there (no trade in the Sandbox), the world map shows it and a tap sets the find arrow,
## a lighthouse's lamp, a birch forest and a snowy top in the real chunks.

const SEED := 12345
const TIMEOUT := 420.0
const STEP_TIMEOUT := 60.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _village := {}
var _lighthouse := {}
var _birch := Vector2i.ZERO
var _peak := Vector2i.ZERO
var _ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	Game.new_world_seed = SEED
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	_step_t += delta
	if _t > TIMEOUT or _step_t > STEP_TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_run_step(sandbox)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var world: WorldService = p.world
	var director: PlacesDirector = sandbox.get("places_director")
	match _step:
		0:
			var meta: WorldMeta = sandbox.get("meta")
			_check(meta.terrain == 2, "a new world is the wild meadows (terrain %d)" % meta.terrain)
			_check(world.generator_shape() is MeadowsBiomeShape, "its shape is MeadowsBiomeShape")
			_check(Session.world_terrain == 2, "the host would tell its guests terrain 2")
			_check(director != null and director.enabled(), "the places director has the world's places")
			var hud: Hud = sandbox.get("hud")
			var map_button: TouchButton = sandbox.get("map_button")
			_check(map_button != null and hud.more.buttons().has(map_button), "MAP is in the MORE panel")
			var home := world.spawn_column()
			_village = director.places.nearest(Vector3(home.x, 40, home.y), MeadowsPlaces.VILLAGE, 8)
			_lighthouse = director.places.nearest(Vector3(home.x, 40, home.y), MeadowsPlaces.LIGHTHOUSE, 10)
			_check(not _village.is_empty(), "a village within 2 km")
			if _village.is_empty():
				_finish()
				return
			var a: Vector3i = _village.anchor
			print("WORLD_SMOKE info village=%s '%s' at %s, %.0f blocks from the spawn" % [_village.id, _village.name, a,
				Vector2(a.x - home.x, a.z - home.y).length()])
			_ms = Time.get_ticks_msec()
			p.spawn_at(Vector3(a.x + 3.5, a.y + 0.2, a.z + 0.5))
			_next(0.5)
		1:
			var a: Vector3i = _village.anchor
			var well := world.get_block(Vector3i(a.x + 1, a.y, a.z))
			if _wait_for(well == BlockIds.STONE_BRICK and world.get_block(Vector3i(a.x, a.y, a.z)) == BlockIds.WATER,
					"the village's well is in the generated terrain"):
				print("WORLD_SMOKE info village streamed in %d ms" % (Time.get_ticks_msec() - _ms))
				_check(world.get_block(Vector3i(a.x + 3, a.y - 1, a.z)) == BlockIds.PATH, "its plaza is a dirt path")
				var door: Vector3i = (_village.doors as Array)[0][0]
				_check(world.get_block(door) == BlockIds.DOOR_OPEN, "a house's door is open at %s" % door)
				_next(0.2)
		2:
			if _wait_for(director.found.has(_village.id), "walking in finds the village"):
				var hud: Hud = sandbox.get("hud")
				var toast: Label = hud.get("_toast_label")
				_check(toast != null and toast.text.contains(String(_village.name)), "the screen says so ('%s')" % (toast.text if toast else ""))
				_next(0.6)
		3:
			var here: Array = director.villagers_of(_village.id)
			_check(here.size() == (_village.villagers as Array).size() and here.size() > 0, "its %d villagers stand there" % here.size())
			_check(here.all(func(v: Node) -> bool: return not v.is_in_group(&"traders")), "Sandbox villagers wave but don't trade")
			var map: WorldMapPanel = sandbox.get("world_map")
			(sandbox.get("map_button") as TouchButton).pressed.emit()
			_check(map.is_open(), "MAP opens the world map")
			_check(map.badges.size() == 1 and map.badges[0].tooltip_text == String(_village.name), "the map shows the village, and nothing else")
			if map.badges.size() > 0:
				map.badges[0].pressed.emit()
			var arrow: FindArrow = sandbox.get_node("ChatCommands").get("find_arrow")
			_check(not map.is_open(), "a tap on the village closes the map")
			_check(arrow != null and arrow.is_pointing() and arrow.what == String(_village.name), "and sets the find arrow to it")
			sandbox.call(&"save_world")
			var saved := WorldSaves.load_meta(String(sandbox.get("_slot")))
			_check(saved.places_found.has(_village.id), "the world saves the find")
			_next(0.2)
		4:
			if _lighthouse.is_empty():
				print("WORLD_SMOKE info no lighthouse within 10 regions")
				_step = 6
				return
			var a: Vector3i = _lighthouse.anchor
			print("WORLD_SMOKE info lighthouse=%s '%s' at %s" % [_lighthouse.id, _lighthouse.name, a])
			var door: Vector3i = (_lighthouse.doors as Array)[0][1]
			p.spawn_at(Vector3(door.x + 0.5, door.y + 0.2, door.z + 0.5))
			_next(0.5)
		5:
			var lamp := Vector3i.ZERO
			for b: Array in _lighthouse.boxes:
				if b[2] == BlockIds.GOLD_LAMP:
					lamp = b[0]
			if _wait_for(world.get_block(lamp) == BlockIds.GOLD_LAMP, "the lighthouse's lamp is lit at %s" % lamp):
				var steps: Array = _lighthouse.stairs
				_check(world.get_block(steps[0]) == BlockIds.PLANKS and world.get_block(steps[steps.size() - 1]) == BlockIds.PLANKS,
					"its stair is there, first step to last")
				_next(1.0)
		6:
			if not _lighthouse.is_empty():
				_check(director.found.has(_lighthouse.id), "the lighthouse is found too")
			var shape := world.generator_shape() as MeadowsBiomeShape
			var home := world.spawn_column()
			_birch = _column_of(shape, home, MeadowsBiomeShape.BIRCH)
			_peak = _snowy(shape, home)
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.spawn_at(Vector3(_birch.x + 0.5, shape.height_at(_birch.x, _birch.y) + 12, _birch.y + 0.5))
			_next(0.5)
		7:
			var h := world.surface_height(_birch.x, _birch.y)
			if not _wait_for(world.is_area_ready(Vector3(_birch.x, h + 4, _birch.y)), "the birch forest streamed"):
				return
			_check(_count_near(world, Vector3i(_birch.x, h, _birch.y), 12, [BlockIds.BIRCH_LOG, BlockIds.BIRCH_LEAVES]) > 0,
				"birches in a birch forest at %s" % _birch)
			var shape := world.generator_shape() as MeadowsBiomeShape
			p.spawn_at(Vector3(_peak.x + 0.5, shape.height_at(_peak.x, _peak.y) + 6, _peak.y + 0.5))
			_next(0.5)
		8:
			var top := Vector3i(_peak.x, world.surface_height(_peak.x, _peak.y) - 1, _peak.y)
			if _wait_for(world.get_block(top) == BlockIds.SNOW, "snow on a mountain top at %s" % top):
				_finish()


func _column_of(shape: MeadowsBiomeShape, home: Vector2i, biome: int) -> Vector2i:
	for r in range(64, 3000, 16):
		for a in 24:
			var q := home + Vector2i(roundi(cos(TAU * a / 24.0) * r), roundi(sin(TAU * a / 24.0) * r))
			if shape.column(q.x, q.y).y == biome and shape.tree_kind(q.x, q.y) == MeadowsBiomeShape.NO_TREE:
				return q
	return home


func _snowy(shape: MeadowsBiomeShape, home: Vector2i) -> Vector2i:
	for r in range(64, 4000, 16):
		for a in 24:
			var q := home + Vector2i(roundi(cos(TAU * a / 24.0) * r), roundi(sin(TAU * a / 24.0) * r))
			if shape.height_at(q.x, q.y) >= MeadowsBiomeShape.SNOW_LINE + 3:
				return q
	return home


func _count_near(world: WorldService, c: Vector3i, r: int, ids: Array) -> int:
	var n := 0
	for y in range(c.y - 2, c.y + 10):
		for z in range(c.z - r, c.z + r + 1, 2):
			for x in range(c.x - r, c.x + r + 1, 2):
				if world.get_block(Vector3i(x, y, z)) in ids:
					n += 1
	return n


func _wait_for(ok: bool, what: String) -> bool:
	if ok:
		_check(true, what)
	elif _step_t > STEP_TIMEOUT - 1.0:
		_check(false, what)
		_finish()
	return ok


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("WORLD_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("WORLD_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(1 if not _fails.is_empty() else 0))
