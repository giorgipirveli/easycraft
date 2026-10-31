extends Node
## The steps of tools/sky_dragon_bench.gd (owner feedback #39): what the Sky Dragon's fight costs on this machine,
## next to the Cake Monster's (the last boss before it). On Monster Wave's arena ground (ArenaShape: flat at y 32,
## 2-block cover beyond 14 blocks), a child stands near the middle; each boss is stepped by hand at 60 Hz for
## BLOCK seconds at a time, the two alternating (so a busy PC slows both alike), for SECONDS each:
## - the host's physics step (its whole fight: flight or walk, attacks, the towers' heal and hits);
## - the looks every screen runs (_process: pose, the dive line; the dragon's towers' beams and sparks included);
## - the dragon's towers' own _process (rising, sparks);
## - world reads a second (block_at calls that reached the world: a real voxel read costs 15-35 µs on this desktop,
##   DEVELOPMENT.md §8, so reads × that is the rest of its cost).
## Writes nothing.

const DT := 1.0 / 60.0
const SECONDS := 60.0
const BLOCK := 5.0
const FLOOR := ArenaShape.FLOOR

var _arena := ArenaShape.new(20260939, 1)
var _reads := 0


func _ready() -> void:
	Game.mode = ModeRules.SANDBOX
	_run.call_deferred()


func _block(p: Vector3i) -> int:
	_reads += 1
	return _arena.block_at(p)


func _run() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, FLOOR, 6.5)
	await get_tree().physics_frame
	var center := Vector3(0.5, FLOOR, 0.5)
	var dragon := SkyDragon.new()
	dragon.setup({"id": "bench_dragon", "pos": BossRules.golem_spot(center), "yaw": 0.0, "max_hp": 100000,
		"tired": false, "center": center})
	dragon.block_at = _block
	add_child(dragon)
	var cake := CakeMonster.new()
	cake.setup({"id": "bench_cake", "pos": Vector3(0.5, FLOOR, -6.5), "yaw": 0.0, "max_hp": 100000, "tired": false})
	cake.block_at = _block
	add_child(cake)
	for n: Node in [dragon, cake]:
		n.set_physics_process(false)
		n.set_process(false)
	var t := {"dragon_step": [], "cake_step": [], "dragon_look": [], "cake_look": [], "towers": []}
	var dragon_reads := 0
	var cake_reads := 0
	var blocks := int(SECONDS / BLOCK)
	for b in blocks:
		for who in ["dragon", "cake"]:
			var boss: StoneGolem = dragon if who == "dragon" else cake
			for i in int(BLOCK / DT):
				p.health.hp = Health.MAX_HP         # the child stays up (the fight goes on)
				var r0 := _reads
				var t0 := Time.get_ticks_usec()
				boss._physics_process(DT)
				var t1 := Time.get_ticks_usec()
				boss._process(DT)
				var t2 := Time.get_ticks_usec()
				t[who + "_step"].append(t1 - t0)
				t[who + "_look"].append(t2 - t1)
				if who == "dragon":
					dragon_reads += _reads - r0
					var t3 := Time.get_ticks_usec()
					for tower in dragon.towers():
						tower.set_process(false)
						tower._process(DT)
					t["towers"].append(Time.get_ticks_usec() - t3)
				else:
					cake_reads += _reads - r0
				if i % 10 == 0:
					await get_tree().process_frame
	print("SKY_BENCH %d s each at 60 Hz, alternating %d s blocks; load %s" % [SECONDS, BLOCK, _load()])
	for key in ["dragon_step", "cake_step", "dragon_look", "cake_look", "towers"]:
		var a: Array = t[key]
		print("SKY_BENCH %-12s avg %6.1f us  p99 %6d us  max %6d us  (%d samples)" % [key, _avg(a), _pct(a, 0.99), _max(a), a.size()])
	print("SKY_BENCH world reads a second: dragon %.1f, cake %.1f (dragon's reads remembered: %d cells)" % [
		dragon_reads / SECONDS, cake_reads / SECONDS, dragon._memory.size()])
	print("SKY_BENCH towers standing %d after %d rise(s) (nobody breaks them here)" % [dragon.standing_towers(), dragon._rises])
	get_tree().quit(0)


static func _avg(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(a.size(), 1)


static func _max(a: Array) -> int:
	var m := 0
	for v in a:
		m = maxi(m, v)
	return m


static func _pct(a: Array, q: float) -> int:
	var s := a.duplicate()
	s.sort()
	return s[clampi(int(s.size() * q), 0, s.size() - 1)] if not s.is_empty() else 0


static func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"
