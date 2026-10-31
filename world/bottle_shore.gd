class_name BottleShore
extends Node3D
## Friends' bottles near this child (M4 Wave 3, agent I; research D5): node "Bottles" of the world scene,
## this game only (a bottle is for its player alone, so nothing goes over the network). When the child
## starts playing (and when a bottle arrives while they play) every bottle waiting on the server floats
## up on the water nearest to them (BottleSpot: else on the beach, else on the ground); a tap opens it
## (OnlineService.open_bottle) and the HUD shows what it says (BottleCard).

## A bottle was opened: {"text", "bottle", "slot"} (OnlineService.open_bottle).
signal opened(result: Dictionary)

const LOOK := Vector3i(BottleSpot.RADIUS, 8, BottleSpot.RADIUS)

var world: WorldService
var player: Node3D                # the child (a Player: once it has spawned)
var service: OnlineService

var _shown := {}          # bottle id -> GiftBottle
var _opening := {}        # bottle ids being opened


## Watches the service's bottles and brings the waiting ones (after the player has spawned).
func start() -> void:
	if service == null:
		return
	if not service.gifts_changed.is_connected(_sync):
		service.gifts_changed.connect(_sync)
	await service.refresh_bottles()
	_sync()


func bottles() -> Array[GiftBottle]:
	var out: Array[GiftBottle] = []
	for id: String in _shown:
		if is_instance_valid(_shown[id]):
			out.append(_shown[id])
	return out


func _sync() -> void:
	if not is_inside_tree() or service == null or player == null:
		return
	if player.has_method(&"is_spawned") and not bool(player.call(&"is_spawned")):
		return
	var waiting := {}
	for b: Dictionary in service.bottles:
		waiting[b.id] = b
	for id: String in _shown.keys():
		if not waiting.has(id) and not _opening.has(id):
			if is_instance_valid(_shown[id]):
				(_shown[id] as Node).queue_free()
			_shown.erase(id)
	var new: Array[Dictionary] = []
	for id: String in waiting:
		if not _shown.has(id):
			new.append(waiting[id])
	if new.is_empty():
		return
	var spots := spots_near(Vector3i(player.global_position.floor()), new.size() + _shown.size())
	var used := 0
	for b in new:
		while used < spots.size() and _taken(spots[used].pos):
			used += 1
		var spot: Dictionary = spots[mini(used, spots.size() - 1)]
		used += 1
		var bottle := GiftBottle.new()
		bottle.setup({"id": b.id, "from": b.from, "pos": spot.pos, "floating": spot.kind == BottleSpot.WATER})
		bottle.tapped_open.connect(_open)
		add_child(bottle)
		_shown[b.id] = bottle


## Where `count` bottles go around `feet` (one bulk copy of the area, searched natively).
func spots_near(feet: Vector3i, count: int) -> Array[Dictionary]:
	var origin := feet - LOOK
	var buf := world.copy_box(origin, LOOK * 2 + Vector3i.ONE)
	var water := BotRules.find_in_buffer(buf, origin, [BlockIds.WATER])
	var sand := BotRules.find_in_buffer(buf, origin, [BlockIds.SAND])
	return BottleSpot.find(feet, count, water, sand, world.get_block)


func _taken(pos: Vector3) -> bool:
	for b in bottles():
		if b.position.distance_to(pos) < BottleSpot.SPREAD:
			return true
	return false


func _open(bottle: GiftBottle) -> void:
	if _opening.has(bottle.bottle_id):
		return
	_opening[bottle.bottle_id] = true
	Audio.play(&"chime", bottle.global_position)
	var r: Dictionary = await service.open_bottle(bottle.bottle_id)
	_opening.erase(bottle.bottle_id)
	if is_instance_valid(bottle):
		Fx.burst(get_tree().root, bottle.global_position, Color("7ee0ff"), 14, 3.0, 0.12, 0.7, 3.0)
		bottle.queue_free()
	_shown.erase(bottle.bottle_id)
	opened.emit(r)
