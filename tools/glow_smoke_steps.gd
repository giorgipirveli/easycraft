extends Node
## The steps of tools/glow_smoke.gd (universe 6), in a new Survivor world of the Glow Caves (Cozy), through the real
## systems: the player stands on the home hall's cavern floor under its ceiling, with the caves' rules (their secrets
## and wonders, the soft blue-violet cave mood, the roof as the open sky's ground); a giant glowshroom near the spawn is
## really there; the nearest Rain Carver's rock is in the world, its tap spots come near the child, and scooping and
## pouring rainwater through the real taps (SecretTaps) dissolves its limestone door in the world, pays the wonder's
## fixed gold once and opens the Cave Book's page; the nearest Drip Stone's stalactite, stump and pearls are there and
## its steps' cells are air; the arena of universe 6 is flat. It ends with two short cost windows back at the spawn
## (once its land has streamed in): with the Cave Wonders' director, and without it (its own share).

const TIMEOUT := 300.0
const U := 6
const SETTLE := 12.0              # seconds back at the spawn before the cost windows
const COST := 4.0
const W := preload("res://core/rules/glow_wonder_rules.gd")

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _first := true
var _fails: Array[String] = []
var _plant := Vector3i.MAX
var _wonder := {}
var _gold := 0
var _frames: Array[Vector2] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = U
	Game.new_world_difficulty = DifficultyRules.COZY
	Game.start_new_world = true
	Profile.data.universe_unlocked = maxi(Profile.data.universe_unlocked, U)   # the private profile's copy only
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-seed="):
			Game.new_world_seed = int(a.trim_prefix("--smoke-seed="))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("GLOW_SMOKE begin universe=%d" % Game.universe)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null:
		return
	var p: Player = sandbox.player
	if not p.is_spawned():
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	var first := _first
	_first = false
	_run_step(sandbox, first)


func _run_step(sandbox: Node, first: bool) -> void:
	var p: Player = sandbox.player
	var w: WorldService = sandbox.world
	var shape := w.generator_shape() as GlowShape
	var secrets := sandbox.get_node("Secrets") as SecretDirector
	var wonders := sandbox.get("glow_wonders") as GlowWondersDirector
	match _step:
		0:
			print("GLOW_SMOKE info seed=%d spawn=%s" % [sandbox.meta.seed, Vector3i(p.global_position.floor())])
			_check(w.universe == U and shape != null, "a Glow Caves world (universe %d)" % w.universe)
			if shape == null:
				_finish()
				return
			var feet := Vector3i(p.global_position.floor())
			var under := w.get_block(feet + Vector3i.DOWN)
			_check(under in [BlockIds.CAVE_STONE, BlockIds.GLOW_MOSS, BlockIds.FLOWSTONE, BlockIds.LAKE_STONE],
				"standing on the cavern floor (block %d)" % under)
			var c := shape.column(feet.x, feet.z)
			_check(c.y < c.z and BlockIds.is_solid(w.get_block(Vector3i(feet.x, c.y, feet.z))), "a ceiling over the home hall")
			_check(w.sky_height(feet.x, feet.z) == shape.roof_at(feet.x, feet.z), "the open sky's ground is the roof")
			_check(not w.cave_mood.is_empty(), "the caves' soft blue-violet dark")
			_check(secrets.rules is GlowSecretRules, "its secrets are the caves'")
			_check(wonders != null and wonders.wonders != null, "the Cave Wonders' director")
			_next(0.0)
		1:
			if first:
				var s := shape.spawn_column()
				for r in range(6, 90):
					for i in maxi(r * 6, 1):
						var a := TAU * i / maxi(r * 6, 1)
						var x := s.x + roundi(cos(a) * r)
						var z := s.y + roundi(sin(a) * r)
						if shape.plant_at(x, z) in [GlowShape.BLUE_GIANT, GlowShape.ROSE_GIANT] \
								and wonders.wonders.footprint(SecretRules.area_of(x, z)).grow(4).has_point(Vector2i(x, z)) == false \
								and secrets.rules.secrets_near(Vector3(x, 0, z), 12.0).is_empty():
							_plant = Vector3i(x, shape.height_at(x, z), z)
							break
					if _plant != Vector3i.MAX:
						break
				if _plant != Vector3i.MAX:
					p.spawn_at(Vector3(_plant) + Vector3(3.5, 0.0, 0.5))
				return
			if _plant != Vector3i.MAX and not w.is_editable(_plant) and _step_t < 25.0:
				return
			_check(_plant != Vector3i.MAX and w.get_block(_plant) == BlockIds.SHROOM_STEM,
				"a giant glowshroom near the spawn at %s (block %d)" % [_plant, w.get_block(_plant) if _plant != Vector3i.MAX else -1])
			_next(0.0)
		2:
			if first:
				_wonder = _nearest(wonders, p.global_position, W.RAIN)
				if _wonder.is_empty():
					_check(false, "a Rain Carver nearby")
					_step = 3
					return
				print("GLOW_SMOKE info rain=%s at %s" % [_wonder.id, _wonder.anchor])
				p.spawn_at(Vector3(_wonder.basin as Vector3i) + Vector3(-1.5, 0.0, 0.5))
				return
			var door: Array = _wonder.limestone
			if (not w.is_editable(door[0]) or _spots(wonders, _wonder.id).is_empty()) and _step_t < 25.0:
				return
			_check(w.get_block(door[0]) == BlockIds.LIMESTONE and w.get_block((_wonder.granite as Array)[0]) == BlockIds.GRANITE,
				"the Rain Carver's limestone door and granite wall are in the world")
			_check(w.get_block(_wonder.basin) == BlockIds.WATER, "its basin of rainwater")
			var spots := _spots(wonders, _wonder.id)
			_check(spots.size() == 1 + door.size() + (_wonder.granite as Array).size(), "its tap spots came near the child (%d)" % spots.size())
			_gold = Session.gold_of(p.peer_id)
			var basin := _spot(spots, &"basin")
			var lime := _spot(spots, &"limestone")
			for i in W.POURS_TO_OPEN:
				SecretTaps.use(basin, get_tree())
				SecretTaps.use(lime, get_tree())
			_next(0.5)
		3:
			if not _wonder.is_empty() and _wonder.kind == W.RAIN:
				for cell: Vector3i in _wonder.limestone:
					_check(w.get_block(cell) == BlockIds.AIR, "rainwater dissolved the limestone at %s" % cell)
				_check(wonders.is_solved(_wonder.id), "the Rain Carver is solved and kept with the world")
				_check(Session.gold_of(p.peer_id) - _gold == W.reward_gold(U), "its fixed gold, once (%d)" % (Session.gold_of(p.peer_id) - _gold))
				_check(Profile.data.wonder.cave_found(W.RAIN), "the Cave Book's page")
			_next(0.0)
		4:
			if first:
				_wonder = _nearest(wonders, p.global_position, W.DRIP)
				if _wonder.is_empty():
					_check(false, "a Drip Stone nearby")
					_step = 5
					return
				print("GLOW_SMOKE info drip=%s at %s" % [_wonder.id, _wonder.anchor])
				p.spawn_at(Vector3(_wonder.anchor as Vector3i) - Vector3(_wonder.dir as Vector3i) * 2.0 + Vector3(0.5, 0.0, 0.5))
				return
			if not w.is_editable(_wonder.tip) and _step_t < 25.0:
				return
			_check(w.get_block(_wonder.tip) == BlockIds.STALACTITE, "the drip stone's stalactite")
			_check(w.get_block(_wonder.anchor) == BlockIds.FLOWSTONE, "its stump")
			_check(w.get_block(_wonder.pearls) == BlockIds.CAVE_PEARL, "pearls up on the ledge")
			var air := true
			for cells: Array in _wonder.steps:
				for cell: Vector3i in cells:
					air = air and w.get_block(cell) == BlockIds.AIR
			_check(air, "the steps' cells wait for the drops")
			_next(0.0)
		5:
			var arena := ArenaShape.new(sandbox.meta.seed, U)
			var flat := true
			for i in 40:
				flat = flat and arena.height_at(i * 37 - 700, 500 - i * 29) == ArenaShape.FLOOR
			_check(flat and arena.palette.top == BlockIds.CAVE_STONE, "the arena of universe 6 is flat cave stone")
			_next(0.0)
		6:
			if first:   # the cost window where the child starts, once the land round it has streamed in
				var s := shape.spawn_column()
				p.spawn_at(Vector3(s.x + 0.5, shape.height_at(s.x, s.y), s.y + 0.5))
				_wait = SETTLE
				return
			if _cost("home"):
				_next(0.0)
		7:
			if first:
				wonders.set_process(false)   # the same window without the wonders' director: its own share
			if _cost("home_without_wonders"):
				wonders.set_process(true)
				_finish()


## Measures a COST window; true when it is done (prints GLOW_SMOKE cost <label> ...).
func _cost(label: String) -> bool:
	_frames.append(Vector2(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
	if _step_t < COST:
		return false
	var total := Vector2.ZERO
	var worst := Vector2.ZERO
	for f in _frames:
		total += f
		worst = Vector2(maxf(worst.x, f.x), maxf(worst.y, f.y))
	var avg := total / maxf(_frames.size(), 1.0)
	print("GLOW_SMOKE cost %s frames=%d physics_avg_ms=%.2f physics_worst_ms=%.2f process_avg_ms=%.2f process_worst_ms=%.2f" % [
		label, _frames.size(), avg.x, worst.x, avg.y, worst.y])
	_frames.clear()
	return true


func _nearest(d: GlowWondersDirector, from: Vector3, kind: StringName) -> Dictionary:
	var best := {}
	var best_d := INF
	for w: Dictionary in d.wonders.wonders_near(from, 400.0):
		if w.kind != kind:
			continue
		var dist := Vector2(w.anchor.x - from.x, w.anchor.z - from.z).length()
		if dist < best_d:
			best_d = dist
			best = w
	return best


func _spots(d: GlowWondersDirector, id: String) -> Array[WonderThing]:
	var out: Array[WonderThing] = []
	for t in d.things():
		if t.wonder_id == id and not t.is_queued_for_deletion():
			out.append(t)
	return out


func _spot(spots: Array[WonderThing], part: StringName) -> WonderThing:
	for t in spots:
		if t.part == part:
			return t
	return null


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0
	_first = true


func _check(ok: bool, what: String) -> void:
	print("GLOW_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("GLOW_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(1 if not _fails.is_empty() else 0))
