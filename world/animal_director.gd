class_name AnimalDirector
extends Node
## Host-side: brings the animals of each area to life when a player comes near (AnimalRules
## spawns: the same animals return to the same area), keeps at most MAX_PER_PLAYER around each
## player, and sends far-away wild animals home. Pets are never removed. World access is injected,
## so tests can drive it with stubs. A defeated animal (owner feedback #26, note_defeated) comes back to
## its area only after AnimalRules.REFILL_TIME: herds thin out for a while, and the world never runs empty.

const TICK := 1.0
const CACHE_LIMIT := 512          # remembered areas
## Animals built per tick, over all players: building one costs (nodes, shapes, sync), and the
## first tick used to build up to 20 in one frame (8-11 ms on the desktop; M1b acceptance run 1).
const MAX_SPAWNS_PER_TICK := 3
## M7 (the browser's freezes): areas whose herd is worked out per tick, the nearest first (areas_near). Working one out
## reads the terrain's rules (about 1 ms on the desktop, several times that on a phone); the first tick near a child
## worked out all ~16 in reach at once (17 ms here, a second after arriving).
const NEW_AREAS_PER_TICK := 3

var shape: MeadowsShape
var container: Node               # holds the Animal nodes
var player_positions: Callable    # () -> Array[Vector3]
var is_ready: Callable            # (pos: Vector3) -> bool: terrain (and collision) loaded there
var spawn: Callable               # (data: Dictionary) -> void
## Owner #41: the animals this world's universe names (UniverseRegistry.animals; empty: Green Meadows').
var kinds: Array[StringName] = []
## Owner #41: (cell: Vector3i) -> block id (a turtle lays its eggs on sand); unset: no eggs.
var block_at: Callable
## Owner #41: () -> float in 0..1, the roll for a turtle's egg (tests fix it).
var roll: Callable = func() -> float: return randf()

## Owner #41: a turtle's egg hatched at `pos` into a baby turtle (a child came close: a small secret found).
signal egg_hatched(pos: Vector3, finder: Vector3)

var _eggs := 0                    # babies hatched so far (their ids)

## () -> float: seconds on the host's clock (tests drive it).
var now: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0

## The frame spikes (2026-09-30): a tick worked out its new areas' herds and built its animals in one frame (world 41:
## an area 3-6 ms on the desktop, an animal 3-5 ms; ticks of 9-19 ms, a phone 3-5x, often in the frame the terrain's
## collision is built). True in a world (the sandbox): the tick only queues them, and each frame does one piece (step):
## the next animal, else the next area. Tests leave it off and see a tick's work at once.
var one_a_frame := false

var _t := 0.0
var _away := {}                   # owner feedback #26: defeated animal id -> when it may come back
var _cells := {}                  # Vector2i -> Array[Dictionary]
var _new_areas := 0               # worked out this tick
var _queue: Array[Dictionary] = []   # one_a_frame: the tick's animals still to build, in order
var _area_queue: Array[Vector2i] = []   # one_a_frame: the tick's new areas still to work out, nearest first


func _process(delta: float) -> void:
	step()
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()


## One frame's piece of the ticks' work (one_a_frame): the next queued animal is built, else the next queued area's
## herd is worked out; nothing when none waits.
func step() -> void:
	if not _queue.is_empty():
		spawn.call(_queue.pop_front())
	elif not _area_queue.is_empty():
		var cell: Vector2i = _area_queue.pop_front()
		if not _cells.has(cell):
			_work_out(cell)


## Animals queued by the last ticks, not built yet.
func queued() -> int:
	return _queue.size()


## Areas queued by the last ticks, not worked out yet.
func areas_queued() -> int:
	return _area_queue.size()


## Host: the animal `animal_id` was defeated (CombatDirector.animal_defeated); its spot stays empty
## for AnimalRules.REFILL_TIME.
func note_defeated(animal_id: String, _species: StringName = &"", _pos: Vector3 = Vector3.ZERO, _by: int = 0) -> void:
	_away[animal_id] = float(now.call()) + AnimalRules.REFILL_TIME


func _still_away(animal_id: String, t: float) -> bool:
	if not _away.has(animal_id):
		return false
	if t < float(_away[animal_id]):
		return true
	_away.erase(animal_id)
	return false


## M5 Task 3: the host phone's graphics preset: LOW keeps fewer animals around each child (GraphicsPreset animals_near;
## 0: AnimalRules' cap only).
var near_cap := 0


func apply_preset(preset: String) -> void:
	near_cap = int(GraphicsPreset.params(preset).animals_near)


## How many more animals may come for a child with `nearby` around them.
func spawn_budget(nearby: int) -> int:
	var budget := AnimalRules.spawn_budget(nearby)
	return mini(budget, maxi(near_cap - nearby, 0)) if near_cap > 0 else budget


func tick() -> void:
	var t := float(now.call())
	var players: Array[Vector3] = player_positions.call()
	var alive := {}
	for q: Dictionary in _queue:   # coming in the next frames: already there
		alive[q.id] = q.pos
	for n in container.get_children():
		var a := n as Animal
		if a == null or a.is_queued_for_deletion():
			continue
		if AnimalRules.should_despawn(a.global_position, players, a.is_pet()):
			a.queue_free()
		else:
			alive[a.animal_id] = a.global_position
			if a.egg_at.is_finite() or AnimalRules.SPECIES[a.species].get("lays", false):
				_turtle_tick(a, players, alive)   # owner #41: eggs on sand, hatching when a child comes
	var fresh := MAX_SPAWNS_PER_TICK
	_new_areas = 0
	for p in players:
		var nearby := 0
		for pos: Vector3 in alive.values():
			if Vector2(pos.x - p.x, pos.z - p.z).length() <= AnimalRules.SPAWN_RADIUS * 1.5:
				nearby += 1
		var budget := spawn_budget(nearby)
		var r := AnimalRules.SPAWN_RADIUS
		for cell in areas_near(p):
			if budget <= 0 or fresh <= 0:
				break
			for s: Dictionary in _spawns(cell):
				if budget <= 0 or fresh <= 0:
					break
				var pos: Vector3 = s.pos
				if alive.has(s.id) or Vector2(pos.x - p.x, pos.z - p.z).length() > r or _still_away(s.id, t):
					continue
				if not is_ready.call(pos):
					continue
				var data := {"species": s.species, "id": s.id, "pos": pos, "yaw": randf() * TAU,
					"owner": 0, "name": "", "sitting": false}
				if one_a_frame:
					_queue.append(data)
				else:
					spawn.call(data)
				alive[s.id] = pos
				budget -= 1
				fresh -= 1


## The areas (AnimalRules.CELL squares) within AnimalRules.SPAWN_RADIUS of `p`, the nearest (by its middle) first.
static func areas_near(p: Vector3) -> Array[Vector2i]:
	var r := AnimalRules.SPAWN_RADIUS
	var c0 := Vector2i(floori((p.x - r) / AnimalRules.CELL), floori((p.z - r) / AnimalRules.CELL))
	var c1 := Vector2i(floori((p.x + r) / AnimalRules.CELL), floori((p.z + r) / AnimalRules.CELL))
	var here := Vector2(p.x, p.z)
	var out: Array[Vector2i] = []
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			out.append(Vector2i(cx, cz))
	var far := func(c: Vector2i) -> float:
		return (Vector2(c * AnimalRules.CELL) + Vector2.ONE * AnimalRules.CELL * 0.5).distance_squared_to(here)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return far.call(a) < far.call(b))
	return out


## The areas whose herds are worked out (in the order they were).
func known_areas() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(_cells.keys())
	return out


## Area `cell`'s herd, worked out once; [] when this tick has worked out NEW_AREAS_PER_TICK already (a later tick).
## With one_a_frame the area is queued instead (step works it out in a later frame) and [] is returned now.
func _spawns(cell: Vector2i) -> Array:
	if not _cells.has(cell):
		if _new_areas >= NEW_AREAS_PER_TICK:
			return []
		if one_a_frame:
			if not _area_queue.has(cell):
				_new_areas += 1
				_area_queue.append(cell)
			return []
		_new_areas += 1
		_work_out(cell)
	return _cells[cell]


func _work_out(cell: Vector2i) -> void:
	if _cells.size() >= CACHE_LIMIT:
		_cells.clear()
	_cells[cell] = AnimalRules.spawns_for_cell(shape, cell, kinds)


# --- Owner feedback #41: a turtle's egg (spec §14.19) ------------------------------------------------------------

## Host, every tick: a wild grown-up turtle standing on sand now and then lays an egg (AnimalRules.lays_egg); a
## child who comes within AnimalRules.HATCH_NEAR of an egg makes it hatch into a baby turtle next to it.
func _turtle_tick(a: Animal, players: Array[Vector3], alive: Dictionary) -> void:
	var i := AnimalRules.hatch_by(a.egg_at, players)
	if i >= 0:
		var pos := a.egg_at
		a.egg_at = Vector3.INF
		_eggs += 1
		var id := "egg%d_%s" % [_eggs, a.animal_id]
		spawn.call({"species": a.species, "id": id, "pos": pos, "yaw": randf() * TAU, "owner": 0, "name": "",
			"sitting": false, "baby": true, "hatched": true})
		alive[id] = pos
		egg_hatched.emit(pos, players[i])
		return
	if a.is_pet() or a.baby or not block_at.is_valid():
		return
	a.since_egg += TICK
	var feet := a.global_position
	var under: int = block_at.call(Vector3i(Vector3(feet.x, feet.y - 0.5, feet.z).floor()))
	if AnimalRules.lays_egg(a.species, under, a.egg_at.is_finite(), a.since_egg, float(roll.call())):
		a.egg_at = Vector3(floorf(feet.x) + 0.5, floorf(feet.y + 0.01), floorf(feet.z) + 0.5)
		a.since_egg = 0.0
