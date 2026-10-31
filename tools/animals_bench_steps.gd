extends Node
## The steps of tools/animals_bench.gd (owner feedback #41): what 40 animals near a player cost on the host, the
## new kinds against M1b's farm animals, in alternating 2 s blocks of real physics frames (the animals stepped by
## hand, the time measured around them: their decisions, minds, swimming, sliding, climbing and move_and_slide).
## The player walks a slow circle among them (so they look, watch, run and follow). The day turns to night half way
## (herds sleep, owls wake). Also the chorus's cost per frame with all 80 animals round the listener.

## Stone below GROUND, air above; the cells the run sets (a pond, an ice patch, trees).
class FlatWorld:
	extends WorldService
	const GROUND := 10
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.STONE if pos.y < GROUND else BlockIds.AIR)

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
const NEW: Array[StringName] = [&"horse", &"donkey", &"goat", &"deer", &"duck", &"frog", &"turtle", &"squirrel", &"owl",
	&"hedgehog", &"camel", &"lizard", &"fennec", &"penguin", &"polar_bear", &"arctic_fox", &"seal", &"gummy_bunny",
	&"candy_bird", &"duck"]
const OLD: Array[StringName] = [&"sheep", &"cow", &"pig", &"chicken", &"dog", &"rabbit", &"cat", &"sheep", &"chicken", &"pig"]
const COUNT := 40
const BLOCK := 120                 # frames per block (2 s at 60)

var world: FlatWorld
var player: Player
var fresh: Array[Animal] = []
var farm: Array[Animal] = []
var _time := DayCycle.NOON
var _frame := 0
var _frames := 2400
var _new_ms: Array[float] = []
var _old_ms: Array[float] = []
var _chorus_ms: Array[float] = []
var _chorus: AnimalChorus
var _running := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			_frames = int(float(a.trim_prefix("--seconds=")) * 60.0)
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
	for x in range(-18, -8):             # a pond (the swimmers float on it: water above the ground's physics)
		for z in range(-5, 5):
			world.cells[Vector3i(x, G, z)] = BlockIds.WATER
	for x in range(8, 18):               # an ice patch (the sliders)
		for z in range(-5, 5):
			world.cells[Vector3i(x, G - 1, z)] = BlockIds.ICE
	for t in 6:                          # trees (dens, the squirrel's trunk)
		var at := Vector3i(roundi(cos(t) * 12.0), G, roundi(sin(t) * 12.0))
		for y in 5:
			world.cells[at + Vector3i(0, y, 0)] = BlockIds.LOG
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child(player)
	player.set_physics_process(false)
	player.viewer.free()
	player._spawned = true
	player.global_position = Vector3(0.5, G, 0.5)
	Session.chat_names[player.peer_id] = "Bench"
	for i in COUNT:
		fresh.append(_animal(NEW[i % NEW.size()], "n%d_0_%d" % [i / 4, i % 4], i, 0.0))
		farm.append(_animal(OLD[i % OLD.size()], "o%d_0_%d" % [i / 4, i % 4], i, PI))
	var cam := Camera3D.new()
	add_child(cam)
	cam.global_position = player.global_position + Vector3(0, 3, 0)
	cam.current = true
	_chorus = AnimalChorus.new()
	add_child(_chorus)
	_chorus.set_process(false)
	await get_tree().physics_frame
	print("ANIMALS_BENCH start animals=%d+%d frames=%d load=%s" % [fresh.size(), farm.size(), _frames, _load()])
	_running = true


func _animal(species: StringName, id: String, i: int, turn: float) -> Animal:
	var a := Animal.new()
	var angle := i * 2.39996 + turn
	var r := 4.0 + (i % 10) * 1.6
	a.setup({"species": species, "id": id, "pos": Vector3(cos(angle) * r + 0.5, G + 0.2, sin(angle) * r + 0.5), "yaw": 0.0})
	a.world = world
	add_child(a)
	a.set_physics_process(false)
	return a


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_frame += 1
	var t := _frame / 60.0
	player.global_position = Vector3(cos(t * 0.15) * 6.0 + 0.5, G, sin(t * 0.15) * 6.0 + 0.5)   # a slow walk
	player.velocity = Vector3(-sin(t * 0.15), 0, cos(t * 0.15)) * 0.9
	_time = DayCycle.NOON if _frame < _frames / 2 else 0.95
	var new_block := (_frame / BLOCK) % 2 == 0
	var list := fresh if new_block else farm
	var t0 := Time.get_ticks_usec()
	for a in list:
		if is_instance_valid(a):
			a._physics_process(delta)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	(_new_ms if new_block else _old_ms).append(ms)
	var c0 := Time.get_ticks_usec()
	_chorus.step(delta)
	_chorus_ms.append((Time.get_ticks_usec() - c0) / 1000.0)
	if _frame >= _frames:
		_running = false
		_report()


func _report() -> void:
	for pair: Array in [["new", _new_ms, fresh], ["farm", _old_ms, farm]]:
		var s: Array[float] = []
		s.assign(pair[1])
		s.sort()
		var avg := 0.0
		for v in s:
			avg += v
		avg /= maxf(s.size(), 1)
		print("ANIMALS_BENCH %s animals=%d frames=%d avg_ms=%.3f p99_ms=%.3f max_ms=%.3f per_animal_us=%.1f" % [pair[0],
			(pair[2] as Array).size(), s.size(), avg, s[int(s.size() * 0.99)], s.back(), avg * 1000.0 / COUNT])
	var c := _chorus_ms.duplicate()
	c.sort()
	var cavg := 0.0
	for v: float in c:
		cavg += v
	print("ANIMALS_BENCH chorus animals=%d avg_ms=%.4f max_ms=%.3f" % [COUNT * 2, cavg / maxf(c.size(), 1), c.back()])
	print("ANIMALS_BENCH done load=%s swimmers_afloat=%d" % [_load(), _afloat()])
	get_tree().quit(0)


func _afloat() -> int:
	var n := 0
	for a in fresh:
		if is_instance_valid(a) and AnimalRules.swims(a.species) and world.get_block(Vector3i((a.global_position + Vector3(0, 0.1, 0)).floor())) == BlockIds.WATER:
			n += 1
	return n


func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"
