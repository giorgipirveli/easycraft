class_name ColonyAnimals
extends Node
## Host-side: the Great Dome's animals (owner #77: "domes for living creatures", spec §21c.2), the game's own animals living
## only under the glass on the Moon and on Mars (where nothing lives outside: its AnimalDirector is off). ColonyRules.HERD
## on ColonyLayout.animal_spots: bunnies, chickens and ducks on the grass, fish in the pond. When a player comes within
## NEAR of the Great Dome they come (one a tick, once the terrain is there); when every player is farther than FAR they
## go (nothing else sends them home on Mars; a child between two places, not standing yet, sends nobody away). One that wandered out through a doorway goes back to its spot inside. A
## child's pet is never touched (a tamed bunny may follow its child out; its spot stays taken while it lives); one that was
## defeated comes back after AnimalRules.REFILL_TIME. World access is injected, so tests drive it with stubs.

const TICK := 0.5
const NEAR := 72.0                # a player this close to the Great Dome's middle (sideways) brings them
const FAR := 110.0                # every player farther: they go
## One animal built a tick: building one costs a frame 5-15 ms on this desktop (its node, meshes, mind, sync; the smoke
## run's measurements in the notes), so the herd comes over a few seconds as a child walks up, never in one long frame.
const MAX_SPAWNS_PER_TICK := 1
const PREFIX := "colony_"

var layout: ColonyLayout
## Holds the Animal nodes (the sandbox's animals).
var container: Node
## () -> Array[Vector3]: every player's feet.
var player_positions: Callable
## (pos: Vector3) -> bool: the terrain (and its collision) is there.
var is_ready: Callable
## (data: Dictionary) -> void: brings an animal to life (the sandbox's animal spawner).
var spawn: Callable
## () -> float: seconds on the host's clock (tests drive it).
var now: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
## Off in tests (they call tick()).
var auto_tick := true

var _t := 0.0
var _away := {}                   # a defeated animal's id -> when it may come back


func _process(delta: float) -> void:
	if not auto_tick:
		return
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()


## The Great Dome's animal `animal_id` was defeated (CombatDirector.animal_defeated): its spot stays empty a while.
func note_defeated(animal_id: String, _species: StringName = &"", _pos: Vector3 = Vector3.ZERO, _by: int = 0) -> void:
	if animal_id.begins_with(PREFIX):
		_away[animal_id] = float(now.call()) + AnimalRules.REFILL_TIME


## The Great Dome's animals alive now (pets among them), by id.
func alive() -> Dictionary:
	var out := {}
	for n in container.get_children():
		var a := n as Animal
		if a != null and not a.is_queued_for_deletion() and a.animal_id.begins_with(PREFIX):
			out[a.animal_id] = a
	return out


func tick() -> void:
	if layout == null or container == null:
		return
	var mid := layout.great_middle()
	var near := false
	var players: Array[Vector3] = player_positions.call()
	var close := players.is_empty()   # nobody standing yet (a child between two places): nothing goes
	for p: Vector3 in players:
		var d := Vector2(p.x - mid.x, p.z - mid.z).length()
		near = near or d <= NEAR
		close = close or d <= FAR
	var spots := layout.animal_spots()
	var here := alive()
	for id: String in here:
		var a: Animal = here[id]
		if a.is_pet():
			continue   # a child's pet goes where its child goes
		if not close:
			a.queue_free()
			continue
		var slot := int(id.trim_prefix(PREFIX))
		if slot >= 0 and slot < spots.size() and not layout.in_great_dome(floori(a.global_position.x), floori(a.global_position.z)):
			a.global_position = spots[slot].pos + Vector3(0, 0.05, 0)   # wandered out through a doorway: back inside
			a.velocity = Vector3.ZERO
	if not near:
		return
	var t := float(now.call())
	var fresh := MAX_SPAWNS_PER_TICK
	for s: Dictionary in spots:
		if fresh <= 0:
			break
		var id := PREFIX + str(s.slot)
		if here.has(id) or float(_away.get(id, -INF)) > t:
			continue
		if not is_ready.call(s.pos):
			continue
		spawn.call({"species": s.species, "id": id, "pos": s.pos + Vector3(0, 0.05, 0), "yaw": randf() * TAU, "owner": 0,
			"name": "", "sitting": false})
		fresh -= 1
