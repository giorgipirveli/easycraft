extends Node
## The steps of tools/dragon_monster_bench.gd (owner #39): what 20 wisps, 20 shadow bats and 20 ice bats cost.
## Each group rings a player who walks a small circle on a flat stand-in world (so they chase, signal, swoop and
## throw sparks); the groups take turns in 2 s blocks (a busy PC slows each alike), and the physics step and the
## looks (_process) of the 20 are timed separately, in this thread's CPU time. The player is healed every frame so
## the chase never stops. Writes nothing.

## Stone below GROUND, air above.
class FlatWorld:
	extends WorldService
	const GROUND := 10

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < GROUND else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		pass

	func is_editable(_pos: Vector3i) -> bool:
		return false


const G := FlatWorld.GROUND
const KINDS: Array[StringName] = [MonsterRules.ICE_BAT, MonsterRules.SHADOW_BAT, MonsterRules.WISP]
const FRAMES := 3600
const BLOCK := 120

var world: FlatWorld
var player: Player
var groups := {}                  # kind -> Array[Monster]
var _step_ms := {}                # kind -> Array[float]
var _look_ms := {}
var _frame := 0
var _running := false
var _cpu_ok := true


func _ready() -> void:
	_setup.call_deferred()


func _setup() -> void:
	world = FlatWorld.new()
	world.name = "BenchWorld"      # kept out of the tree: a WorldService in the tree builds its terrain
	Session.register_world(world)
	MindBook.current = MindBook.new()
	MonsterMinds.current = MonsterMinds.new()
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
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
	for kind in KINDS:
		var list: Array[Monster] = []
		for i in 20:
			var m := Monster.new()
			var a := i * TAU / 20.0
			var at := Vector3(cos(a) * 9.0, G + 2.0, sin(a) * 9.0)
			m.setup({"kind": kind, "level": 1 + i % 5, "id": "%s%d" % [kind, i], "pos": at, "yaw": PI * 0.5 - a,
				"wild": true, "universe": 1})
			m.block_at = world.get_block
			add_child(m)
			m.set_physics_process(false)
			m.set_process(false)
			list.append(m)
		groups[kind] = list
		_step_ms[kind] = [] as Array[float]
		_look_ms[kind] = [] as Array[float]
	await get_tree().physics_frame
	_running = true


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_frame += 1
	var kind: StringName = KINDS[(_frame / BLOCK) % KINDS.size()]
	var angle := _frame * delta * 0.3
	player.velocity = Vector3(-sin(angle), 0, cos(angle)) * 1.5
	player.global_position = Vector3(cos(angle), 0, sin(angle)) * 5.0 + Vector3(0.5, G, 0.5)
	player.health.hp = Health.MAX_HP
	var t0 := _now()
	for m: Monster in groups[kind]:
		if is_instance_valid(m):
			m._physics_process(delta)
	(_step_ms[kind] as Array).append((_now() - t0) / 1000.0)
	t0 = _now()
	for m: Monster in groups[kind]:
		if is_instance_valid(m):
			m._process(delta)
	(_look_ms[kind] as Array).append((_now() - t0) / 1000.0)
	if _frame >= FRAMES:
		_running = false
		_report()


func _report() -> void:
	for kind in KINDS:
		var winding := 0
		for m: Monster in groups[kind]:
			if is_instance_valid(m) and m.state == Monster.State.CHASE:
				winding += 1
		print("DRAGON_BENCH %s x20: physics step mean %.3f ms p99 %.3f ms | looks mean %.3f ms p99 %.3f ms | chasing at the end %d" % [
			kind, _mean(_step_ms[kind]), _p99(_step_ms[kind]), _mean(_look_ms[kind]), _p99(_look_ms[kind]), winding])
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	print("DRAGON_BENCH load %s; times are %s" % [f.get_line() if f else "?", "this thread's CPU time" if _cpu_ok else "wall clock"])
	Session.world = null
	for n in get_children():
		n.queue_free()
	world.queue_free()
	Audio.stop_all()
	get_tree().quit.call_deferred(0)


## Microseconds of this thread's CPU time (Linux: /proc/thread-self/schedstat); the wall clock elsewhere.
func _now() -> int:
	if _cpu_ok:
		var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
		var first := f.get_line().split(" ")[0] if f else ""
		if first.is_valid_int():
			return first.to_int() / 1000
		_cpu_ok = false
	return Time.get_ticks_usec()


static func _mean(v: Array) -> float:
	var s := 0.0
	for x: float in v:
		s += x
	return s / maxf(v.size(), 1.0)


static func _p99(v: Array) -> float:
	var s := v.duplicate()
	s.sort()
	return s[mini(s.size() - 1, floori(s.size() * 0.99))] if not s.is_empty() else 0.0
