class_name PlacesDirector
extends Node
## The places of the wild meadows in a played world (owner feedback #45b, spec §14.18), the sandbox's node "Places"
## on every game. The host looks a few times a second (never every frame) for players inside a place's find circle
## and marks it found for the whole world (WorldMeta.places_found); every game keeps the found list (a guest asks the
## host for it when it arrives) and says "You found Maplebrook!" on the finder's screen. The world map shows only
## found places (found_places). Villagers stand in the villages near players (the host: near every player, so a
## guest's trade reaches one; a guest: near its own player) and go when nobody is near; in Survivor a tap on one
## opens Tilly's shop with her rules (villagers are Traders in the group "traders").
## Hooks for other tasks: place_found (host), found_places() and mark() (the quest chains' places on the map),
## places.places_near / nearest / village_centre (a village's centre for a quest giver).

## Host: a player found a place (its dictionary; the finder's peer id).
signal place_found(place: Dictionary, peer_id: int)
## Every game: the found list changed (the map redraws).
signal found_changed

const TICK := 0.5
const LOOK := 64.0                 # places this near a player are checked
const VILLAGERS_NEAR := 72.0       # a village this near a player has its villagers
const VILLAGERS_GONE := 104.0      # ... until nobody is this near
const HIGH := 32.0                 # a player this far above or below a place (flying over) doesn't find it
const NAMES: Array[String] = ["Rosa", "Ben", "Mila", "Theo", "Ada", "Sam", "Nell", "Otto", "Ivy", "Leo", "Pia", "Max",
	"Lena", "Finn", "Zoe", "Tom"]

## The world's places (null in a world without them: the old meadows, the other universes, an arena).
var places: MeadowsPlaces
## The ids of the places found in this world, in the order they were found.
var found: Array[String] = []
## Other tasks' found places on the map ({id, kind, name, pos}); not saved here.
var marks: Array[Dictionary] = []
## Survivor: a tap on a villager opens Tilly's shop.
var trades := false
## Off in tests (they call tick()).
var auto_tick := true
## (text) -> void: this game's words for the player (the HUD's toast).
var toast: Callable

var _t := 0.0
var _villagers := {}               # place id -> Node3D holding its villagers


## Host (or solo): the world's terrain and secrets, and the found places saved with the world. shared: the world
## generator's own places (the same ones, already worked out on its threads for the terrain around the players, so
## looking them up here costs nothing new), or null for places of its own.
func setup_host(shape: MeadowsShape, rules: SecretRules, saved: Array[String], shared: MeadowsPlaces = null) -> void:
	places = _places_for(shape, rules, shared)
	found = WorldMeta.clean_places(saved)


## A guest: the same places from the host's seed and terrain; the host sends the found list.
func setup_client(shape: MeadowsShape, rules: SecretRules, shared: MeadowsPlaces = null) -> void:
	places = _places_for(shape, rules, shared)
	if places != null and multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		_rpc_hello.rpc_id(1)


static func _places_for(shape: MeadowsShape, rules: SecretRules, shared: MeadowsPlaces) -> MeadowsPlaces:
	if not shape is MeadowsBiomeShape:
		return null
	return shared if shared != null and shared.seed == rules.seed else MeadowsPlaces.new(rules.seed, shape, rules)


func enabled() -> bool:
	return places != null


func found_ids() -> Array[String]:
	return found.duplicate()


## What the world map shows: every found place ({id, kind, name, pos: its centre}), then the marks.
func found_places() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if places != null:
		for id in found:
			var p := places.find(id)
			if not p.is_empty():
				var a: Vector3i = p.anchor
				out.append({"id": id, "kind": p.kind, "name": p.name, "pos": Vector3(a.x + 0.5, a.y, a.z + 0.5)})
	out.append_array(marks)
	return out


## Another task's found place on the map ({id, kind, name, pos}); the same id again replaces it.
func mark(entry: Dictionary) -> void:
	for i in marks.size():
		if marks[i].get("id") == entry.get("id"):
			marks[i] = entry
			found_changed.emit()
			return
	marks.append(entry)
	found_changed.emit()


func villagers_of(place_id: String) -> Array:
	var holder: Node = _villagers.get(place_id)
	return holder.get_children() if holder != null and is_instance_valid(holder) and not holder.is_queued_for_deletion() else []


func _process(delta: float) -> void:
	if not auto_tick or places == null:
		return
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()


## One look: the host's finds, then the villagers near the bodies this game looks after.
func tick() -> void:
	if places == null:
		return
	var bodies := _bodies()
	if _is_host():
		_check_finds(bodies)
	_update_villagers(bodies)


func _is_host() -> bool:
	return not multiplayer.has_multiplayer_peer() or multiplayer.is_server()


## The host: every player; a guest: its own.
func _bodies() -> Array[Node3D]:
	var out: Array[Node3D] = []
	var me := str(multiplayer.get_unique_id()) if multiplayer.has_multiplayer_peer() else "1"
	for n in get_tree().get_nodes_in_group(&"players"):
		var b := n as Node3D
		if b == null or not b.is_inside_tree() or b.is_queued_for_deletion():
			continue
		if _is_host() or String(b.name) == me:
			out.append(b)
	return out


func _check_finds(bodies: Array[Node3D]) -> void:
	for b in bodies:
		var pos := b.global_position
		for p: Dictionary in places.places_near(pos, LOOK):
			if found.has(p.id):
				continue
			var a: Vector3i = p.anchor
			if Vector2(a.x + 0.5 - pos.x, a.z + 0.5 - pos.z).length() <= float(p.radius) and absf(pos.y - a.y) < HIGH:
				var peer := int(String(b.name)) if String(b.name).is_valid_int() else 1
				_add_found(p.id, peer)
				place_found.emit(p, peer)
				if multiplayer.has_multiplayer_peer() and not multiplayer.get_peers().is_empty():
					_rpc_found.rpc(p.id, peer)


func _add_found(id: String, finder: int) -> void:
	if found.has(id) or not MeadowsPlaces.is_place_id(id) or found.size() >= WorldMeta.MAX_PLACES_FOUND:
		return
	found.append(id)
	found_changed.emit()
	var me := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	if finder == me and places != null:
		var p := places.find(id)
		if not p.is_empty():
			if toast.is_valid():
				toast.call("You found %s! It's on your map." % p.name)
			Audio.play(&"sparkle")


@rpc("authority", "call_remote", "reliable")
func _rpc_found(id: String, finder: int) -> void:
	_add_found(id, finder)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_hello() -> void:
	if multiplayer.is_server():
		_rpc_found_list.rpc_id(multiplayer.get_remote_sender_id(), found)


@rpc("authority", "call_remote", "reliable")
func _rpc_found_list(ids: Array) -> void:
	for id: Variant in ids:
		if id is String:
			_add_found(id, 0)


# --- Villagers ---

func _update_villagers(bodies: Array[Node3D]) -> void:
	var want := {}
	for b in bodies:
		for p: Dictionary in places.places_near(b.global_position, VILLAGERS_NEAR):
			if p.has("villagers"):
				want[p.id] = p
	for id: String in want:
		if not _villagers.has(id):
			_spawn_villagers(want[id])
	for id: String in _villagers.keys():
		if want.has(id):
			continue
		var holder: Node3D = _villagers[id]
		var near := false
		for b in bodies:
			if Vector2(holder.position.x - b.global_position.x, holder.position.z - b.global_position.z).length() < VILLAGERS_GONE:
				near = true
		if not near:
			_villagers.erase(id)
			holder.queue_free()


func _spawn_villagers(p: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = p.id
	var a: Vector3i = p.anchor
	holder.position = Vector3(a.x, 0, a.z)
	add_child(holder)
	var spots: Array = p.villagers
	for i in spots.size():
		var v := Villager.new()
		var at: Vector3 = spots[i][0]
		var pick := absi(hash(p.id + str(i)))
		holder.add_child(v)
		v.setup({"pos": at - holder.position, "yaw": float(spots[i][1]), "look": pick % Villager.LOOKS,
			"name": NAMES[(pick >> 3) % NAMES.size()], "trades": trades})
	_villagers[p.id] = holder
