extends Node
## The steps of tools/minds_bench.gd (M2 Task 18): what creature minds cost on this machine.
## - per decision: an animal's whole mind step (senses, drives, memory, a pick), a bot friend's, and a
##   monster's (its tick and tactic steering; a tactic pick) (part 2);
## - per frame: 24 animals (six herds) and three friends simulated by hand for 40 s (half by day,
##   half by night, a player walking a circle and building now and then), in alternating 2 s blocks
##   with the animals' minds on and off (off = the M1b random wander), so a busy PC slows both alike;
##   20 monsters (goblins and slimes, levels 1-3) chase the player by day in the same frames (part 2).
## Writes nothing (a stand-in world in memory).

## Stone below GROUND, air above; blocks set by the run; box copies are native fills (like the real one).
class FlatWorld:
	extends WorldService
	const GROUND := 10
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.STONE if pos.y < GROUND else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block

	func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		var stone := clampi(GROUND - origin.y, 0, size.y)
		if stone > 0:
			buf.fill_area(BlockIds.STONE, Vector3i.ZERO, Vector3i(size.x, stone, size.z), VoxelBuffer.CHANNEL_TYPE)
		for pos: Vector3i in cells:
			var p := pos - origin
			if p.x >= 0 and p.y >= 0 and p.z >= 0 and p.x < size.x and p.y < size.y and p.z < size.z:
				buf.set_voxel(cells[pos], p.x, p.y, p.z, VoxelBuffer.CHANNEL_TYPE)
		return buf

	func spawn_column() -> Vector2i:
		return Vector2i.ZERO

	func surface_height(_x: int, _z: int) -> int:
		return GROUND - 1

	func find_standing_y(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return true


const G := FlatWorld.GROUND
const HERDS: Array[StringName] = [&"sheep", &"cow", &"pig", &"chicken", &"dog", &"rabbit"]
const FRAMES := 2400
const BLOCK := 120

var world: FlatWorld
var player: Player
var animals: Array[Animal] = []
var bots: Array[BotFriend] = []
var monsters: Array[Monster] = []
var _monster_ms: Array[float] = []
var _minds := {}                  # animal -> its mind while the minds are off
var _time := DayCycle.NOON
var _frame := 0
var _on: Array[float] = []        # animals' ms per frame, minds on
var _off: Array[float] = []       # ... minds off
var _bot_ms: Array[float] = []
var _running := false
var think_us := 0.0
var hold_us := 0.0
var monster_step_us := 0.0
var monster_pick_us := 0.0
var _moving_on := 0
var _moving_off := 0


func _ready() -> void:
	_setup.call_deferred()


func _setup() -> void:
	world = FlatWorld.new()
	world.name = "BenchWorld"   # kept out of the tree: a WorldService in the tree builds its terrain
	Session.register_world(world)
	MindBook.current = MindBook.new()
	Animal.time_source = func() -> float: return _time
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_position = Vector3(0, G - 0.5, 0)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child(player)
	player.set_physics_process(false)
	player.viewer.free()
	player._spawned = true
	player.global_position = Vector3(0.5, G, 0.5)
	Session.chat_names[player.peer_id] = "Bench"
	for h in HERDS.size():
		var home := Vector3(cos(h * TAU / HERDS.size()), 0, sin(h * TAU / HERDS.size())) * 14.0 + Vector3(0.5, G, 0.5)
		for y in 4:
			world.cells[Vector3i(floori(home.x) + 4, G + y, floori(home.z))] = BlockIds.LOG   # a tree by each herd
		for i in 4:
			var a := Animal.new()
			a.setup({"species": HERDS[h], "id": "a%d_0_%d" % [h, i], "pos": home + Vector3(i % 2 * 1.5, 0, i / 2 * 1.5)})
			a.world = world
			add_child(a)
			a.set_physics_process(false)
			animals.append(a)
	var container := Node3D.new()
	add_child(container)
	var combat := CombatDirector.new()
	combat.name = "Combat"
	add_child(combat)
	combat.block_at = world.get_block
	var director := BotDirector.new()
	director.container = container
	director.world = world
	director.spawn = func(data: Dictionary) -> Node:
		var b := BotFriend.new()
		b.setup(data)
		b.world = world
		b.combat = null                  # friends swing without hurting: the 20 monsters stay for the whole run
		container.add_child(b)
		b.set_physics_process(false)
		return b
	add_child(director)
	await get_tree().physics_frame
	for p in BotRules.PERSONALITIES:
		bots.append(director.add(p))
	MonsterMinds.current = MonsterMinds.new()
	for i in 20:
		var m := Monster.new()
		var a := i * TAU / 20.0
		m.setup({"kind": MonsterRules.GOBLIN if i % 2 == 0 else MonsterRules.SLIME, "level": 1 + i % 3,
			"id": "bench%d" % i, "pos": Vector3(cos(a) * 10.0, G, sin(a) * 10.0), "yaw": PI * 0.5 - a, "wild": true})   # facing the middle
		m.block_at = world.get_block
		add_child(m)
		m.set_physics_process(false)
		monsters.append(m)
	var r0 := Time.get_ticks_usec()
	for i in 200:
		_now()
	_read_cost = (Time.get_ticks_usec() - r0) / 200.0
	_per_decision()
	Mind.profiling = true
	Mind.spent_us = 0
	Mind.steps = 0
	Mind.thinks = 0
	_running = true


## One mind step, many times: an animal's (thinking every time, and as usual) and a friend's.
func _per_decision() -> void:
	var a := animals[0]
	var n := 5000
	var t0 := _now()
	for i in n:
		a.mind.interrupt()
		a._mind_decide()
	think_us = float(_now() - t0) / n
	t0 = _now()
	for i in n:
		a._mind_decide()
	hold_us = float(_now() - t0) / n
	var b := bots[0]
	t0 = _now()
	for i in n:
		b._mind_tick(player, player.global_position)
	var tick_us := float(_now() - t0) / n
	t0 = _now()
	for i in 1000:
		b._mind_design(i)
	var design_us := float(_now() - t0) / 1000.0
	t0 = _now()
	for i in 1000:
		b._mind_pick_find(true, true)
	var find_us := float(_now() - t0) / 1000.0
	print("MINDS_BENCH per decision: animal %.2f us thinking, %.2f us keeping its action; friend tick %.2f us, design pick %.2f us, find pick %.2f us" % [
		think_us, hold_us, tick_us, design_us, find_us])
	var g := monsters[0]
	g._target = player
	g.awareness.see(player.global_position)
	g._mind_ready()
	g.use_tactic(MonsterSpecies.ZIGZAG, player)
	t0 = _now()
	for i in n:
		g._mind_tick()
		g._tactic_steer(player, true)
	monster_step_us = float(_now() - t0) / n
	t0 = _now()
	for i in 1000:
		g._pick_tactic(player, 10.0)
	monster_pick_us = float(_now() - t0) / 1000.0
	print("MINDS_BENCH per decision: monster tick + tactic steering %.2f us, a tactic pick %.2f us" % [monster_step_us, monster_pick_us])


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_frame += 1
	var minds_on := (_frame / BLOCK) % 2 == 0
	if minds_on and not _minds.is_empty():
		for a: Animal in _minds:
			a.mind = _minds[a]
		_minds.clear()
	elif not minds_on and _minds.is_empty():
		for a in animals:
			_minds[a] = a.mind
			a.mind = null
	_time = DayCycle.NOON if _frame < FRAMES / 2 else 0.95
	var angle := _frame * delta * 0.3
	player.velocity = Vector3(-sin(angle), 0, cos(angle)) * 1.8
	player.global_position = Vector3(cos(angle), 0, sin(angle)) * 6.0 + Vector3(0.5, G, 0.5)
	if _frame % 120 == 0:
		world.set_block(Vector3i(roundi(player.global_position.x) + 2, G + (_frame / 120) % 3, roundi(player.global_position.z)), BlockIds.BRICK)
	var t0 := _now()
	for a in animals:
		a._physics_process(delta)
	var animal_ms := (_now() - t0) / 1000.0
	t0 = _now()
	for b in bots:
		b._physics_process(delta)
	_bot_ms.append((_now() - t0) / 1000.0)
	t0 = _now()
	for m in monsters:
		if is_instance_valid(m):
			m._physics_process(delta)
	_monster_ms.append((_now() - t0) / 1000.0)
	(_on if minds_on else _off).append(animal_ms)
	var moving := 0
	for a in animals:
		if a._dir != Vector3.ZERO or not a.velocity.is_zero_approx():
			moving += 1
	if minds_on:
		_moving_on += moving
	else:
		_moving_off += moving
	if _frame >= FRAMES:
		_running = false
		_report(delta)


func _report(delta: float) -> void:
	var sleeping := 0
	for a in animals:
		if a.mind and a.mind_action() == AnimalSpecies.SLEEP:
			sleeping += 1
	print("MINDS_BENCH frames=%d (physics %.0f Hz) sleeping at the end=%d/%d" % [FRAMES, 1.0 / delta, sleeping, animals.size()])
	print("MINDS_BENCH animals per frame: minds on mean %.3f ms p99 %.3f ms | minds off mean %.3f ms p99 %.3f ms" % [
		_mean(_on), _p99(_on), _mean(_off), _p99(_off)])
	print("MINDS_BENCH friends per frame: mean %.3f ms p99 %.3f ms" % [_mean(_bot_ms), _p99(_bot_ms)])
	var chasing := 0
	var alive := 0
	for m in monsters:
		if is_instance_valid(m):
			alive += 1
			if m.tactic != &"":
				chasing += 1
	print("MINDS_BENCH monsters alive %d, chasing with a tactic %d, picks %d" % [alive, chasing, Mind.thinks])
	# 20 monsters decide 10 times a second: 20 * 10 / 60 decisions per frame (each a tick + steering).
	var monster_minds_ms := (20.0 * 10.0 / 60.0 * monster_step_us) / 1000.0
	print("MINDS_BENCH monsters per frame (20, whole physics step): mean %.3f ms p99 %.3f ms; with a tactic at the end %d; their minds about %.3f ms per frame plus picks" % [
		_mean(_monster_ms), _p99(_monster_ms), chasing, monster_minds_ms])
	# The minds' own steps (Mind.profiling, wall clock), over the frames the animals had their minds on.
	var on_frames := maxf(_on.size(), 1.0)
	print("MINDS_BENCH walking animals per frame: minds on %.1f, minds off %.1f (a walking animal moves every physics step)" % [
		_moving_on / on_frames, _moving_off / maxf(_off.size(), 1.0)])
	print("MINDS_BENCH mind steps: %.2f per frame (%.3f picks); wall clock %.1f us each (includes being preempted on this busy PC)" % [
		Mind.steps / on_frames, Mind.thinks / on_frames, float(Mind.spent_us) / maxf(Mind.steps, 1.0)])
	# Mind.thinks counts every pick in the minds-on frames (animals, friends and monsters alike; monsters'
	# picks cost monster_pick_us, a little more than an animal's think).
	print("MINDS_BENCH minds' CPU per frame (steps x %.2f us + picks x %.2f us more): %.3f ms" % [hold_us, think_us - hold_us,
		(Mind.steps * hold_us + Mind.thinks * (think_us - hold_us)) / 1000.0 / on_frames])
	print("MINDS_BENCH all minds per frame, 20 monsters + 24 animals + 3 friends: %.3f ms (budget 0.3 ms)" % [
		(Mind.steps * hold_us + Mind.thinks * maxf(think_us - hold_us, monster_pick_us)) / 1000.0 / on_frames + monster_minds_ms])
	Mind.profiling = false
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	print("MINDS_BENCH load %s; frame and decision times are %s (a clock read costs %.1f us, in every frame figure)" % [
		f.get_line() if f else "?", "this thread's CPU time" if _cpu_ok else "wall clock", _read_cost])
	Animal.time_source = Callable()
	Session.world = null
	for n in get_children():
		n.queue_free()                   # leave nothing half-simulated behind at quit
	world.queue_free()
	get_tree().quit.call_deferred(0)


var _cpu_ok := true
var _read_cost := 0.0


## Microseconds of this thread's CPU time (Linux: /proc/thread-self/schedstat), so other agents' load
## on this shared PC doesn't count; the wall clock elsewhere.
func _now() -> int:
	if _cpu_ok:
		var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
		var first := f.get_line().split(" ")[0] if f else ""
		if first.is_valid_int():
			return first.to_int() / 1000
		_cpu_ok = false
	return Time.get_ticks_usec()


static func _mean(v: Array[float]) -> float:
	var s := 0.0
	for x in v:
		s += x
	return s / maxf(v.size(), 1.0)


static func _p99(v: Array[float]) -> float:
	var s := v.duplicate()
	s.sort()
	return s[mini(s.size() - 1, floori(s.size() * 0.99))] if not s.is_empty() else 0.0
