class_name RideDirector
extends Node
## Rideable buddies (M3 Task 20a, spec §16 "the dragon you built and fly"): node "Rides" in the sandbox on every
## game.
## Every game with a player: the RIDE context button (HudLayout spot `ride`) shows only next to a saddled buddy
## nobody rides (and as HOP OFF while riding); a tap, or Y on a keyboard, asks the host. The host's answer to
## getting off (where to stand) moves this game's player.
## Host: decides every ride (RideRules): who may get on (a saddle, near it, free, not knocked out, asleep or
## hiding), whose stick moves which buddy (only its rider's), getting off (never inside blocks), and, 10 times a
## second, riders who can't ride any more (gone, knocked out) and Survivor flights that have landed.

const SCAN_EVERY := 0.1
const RIDE_KEY := KEY_Y   # desktop: Y gets on and off, like the button

const _REFUSALS := {
	"no_saddle": "Build a saddle into your buddy to ride it!",
	"too_far": "Get closer to ride!",
	"taken": "Someone is riding that buddy!",
	"busy": "You can't ride right now.",
}

## The world's buddies (the sandbox's Buddies node).
var buddies_root: Node
## Owner #41: the world's animals (the sandbox's Animals node): a saddled horse or camel is ridden too.
var animals_root: Node
## This game's player and HUD (none until the player is there; setup_local).
var player: Player
var hud: Hud
## The buddy (or, owner #41, the saddled horse or camel) the RIDE button would get on (null: the button hides).
var nearby: Node3D
## Tests: the host's clock for Survivor landings and riders (default: every physics step).
var host_checks := true
## Owner #109: the world's cars (VehicleDirector): next to a car with a free seat RIDE says DRIVE (or GET IN) and gets
## in; in a car it says HOP OFF (the same ride-off request: the host lets the child out of its car).
var cars: VehicleDirector

var _scan := 0.0
var _decide := 0.0


func _ready() -> void:
	Session.ride_off_received.connect(_on_ride_off)
	if Session.is_host():   # (a LAN guest's sandbox joins after this: every host step checks again)
		Session.ride_requested.connect(func(peer: int, buddy_name: String) -> void: host_ride(peer, buddy_name))
		Session.ride_off_requested.connect(func(peer: int) -> void: host_ride_off(peer))
		Session.ride_input_received.connect(host_ride_input)
		Session.peer_left.connect(func(peer: int) -> void: host_ride_off(peer))


## This game's player and HUD: the RIDE button.
func setup_local(p: Player, h: Hud) -> void:
	player = p
	hud = h
	if hud:
		hud.add_ride_controls()
		hud.ride_button.pressed.connect(press_ride)
	if player:
		player.ride_changed.connect(_on_ride_changed)


## The RIDE button (and Y): on near a saddled buddy, off while riding.
func press_ride() -> void:
	if not is_instance_valid(player):
		return
	if player.is_riding():
		Session.request_ride_off()
	elif nearby is Vehicle and is_instance_valid(cars):   # owner #109
		cars.request_get_in(String(nearby.name))
	elif is_instance_valid(nearby):
		Session.request_ride(String(nearby.name))


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == RIDE_KEY:
		press_ride()


func _process(delta: float) -> void:
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = SCAN_EVERY
	scan()


func _physics_process(delta: float) -> void:
	if not host_checks or not Session.is_host():
		return
	_decide -= delta
	if _decide > 0.0:
		return
	_decide = RideRules.DECIDE_EVERY
	host_check()


## This game: the saddled buddy next to its player that nobody rides, for the RIDE button (10 times a second).
func scan() -> void:
	if not is_instance_valid(player):
		return
	if player.is_riding():
		nearby = null
		_show(true, true)
		return
	var best: Node3D = null
	var best_d := INF
	if _may_ride(player):
		for b in _buddies():
			if b.ride_kind == RideRules.Kind.NONE or b.rider_peer != 0 or b.visiting:
				continue
			if not RideRules.can_mount(player.global_position, b.global_position, b.size_blocks):
				continue
			var d := player.global_position.distance_squared_to(b.global_position)
			if d < best_d:
				best = b
				best_d = d
		for a in _mounts():   # owner #41: a saddled horse or camel
			if a.rider_peer != 0 or not RideRules.can_mount(player.global_position, a.global_position, a.size_blocks):
				continue
			var d := player.global_position.distance_squared_to(a.global_position)
			if d < best_d:
				best = a
				best_d = d
		if is_instance_valid(cars):   # owner #109: a car with a free seat
			var car := cars.nearest_car(player.global_position)
			if car and player.global_position.distance_squared_to(car.global_position) < best_d:
				best = car
	nearby = best
	_show(best != null, false)


func _show(on: bool, riding: bool) -> void:
	if not is_instance_valid(hud):
		return
	if not riding and nearby is Vehicle:   # owner #109: DRIVE, or GET IN for a passenger's seat
		hud.show_ride_button(on, false, (nearby as Vehicle).board_word(), &"car")
	else:
		hud.show_ride_button(on, riding)


func _on_ride_changed(on: bool) -> void:
	_scan = 0.0
	if is_instance_valid(hud):
		hud.set_ride_up_down(on and is_instance_valid(player.riding) and player.riding.ride_kind == RideRules.Kind.FLY)
	if on and is_instance_valid(player):
		Audio.play(&"jump", player.global_position, -4.0)


func _on_ride_off(spot: Vector3) -> void:
	if is_instance_valid(player):
		player.get_off_at(spot)


# --- Host -------------------------------------------------------------------------------------------------

## Host: player `peer` asks to ride `buddy_name`. "" when it got on, else why not (and the player is told).
func host_ride(peer: int, buddy_name: String) -> String:
	if not Session.is_host() or buddies_root == null:
		return "busy"
	var b := buddies_root.get_node_or_null(NodePath(buddy_name)) as Buddy
	if b == null:
		return host_ride_animal(peer, buddy_name)   # owner #41: a saddled horse or camel
	var p := Session._player_for_peer(peer)
	var error := ""
	if b == null or b.is_queued_for_deletion() or b.visiting or b.ride_kind == RideRules.Kind.NONE:
		error = "no_saddle"
	elif p == null or not _may_ride(p) or _ridden_by(peer) != null or _animal_ridden_by(peer) != null:
		error = "busy"
	elif b.rider_peer != 0:
		error = "taken"
	elif not RideRules.can_mount(p.global_position, b.global_position, b.size_blocks, RideRules.HOST_TOLERANCE):
		error = "too_far"
	if error != "":
		_tell(peer, _REFUSALS[error])
		return error
	b.start_ride(peer)
	_tell(peer, RideRules.mount_line(b.ride_mode))
	Session.progress_tell(peer, StringName("%s/%s" % [LevelRules.RIDDEN, String(RideRules.Kind.find_key(b.ride_mode)).to_lower()]))   # owner #45a
	return ""


## Host: player `peer` gets off (whatever it rides), next to the buddy and never inside blocks.
func host_ride_off(peer: int) -> void:
	if not Session.is_host():
		return
	var b := _ridden_by(peer)
	if b != null:
		end_ride(b)
	var a := _animal_ridden_by(peer)   # owner #41
	if a != null:
		end_animal_ride(a)


## Host: the stick of player `peer`, for `buddy_name`; only a buddy's own rider steers it.
func host_ride_input(peer: int, buddy_name: String, wish: Vector3) -> void:
	if buddies_root == null or not Session.is_host():
		return
	var b := buddies_root.get_node_or_null(NodePath(buddy_name)) as Buddy
	if b != null and b.rider_peer == peer and peer != 0:
		b.set_ride_input(wish)
	elif b == null and animals_root != null:   # owner #41: a horse's or camel's own rider steers it
		var a := animals_root.get_node_or_null(NodePath(buddy_name)) as Animal
		if a != null and a.rider_peer == peer and peer != 0:
			a.set_ride_input(wish)


## Host: the rider gets off `b`; its own game is told where to stand.
func end_ride(b: Buddy) -> void:
	var peer := b.rider_peer
	var world := Session.world
	var spot := RideRules.dismount_spot(b.global_position, b.size_blocks, b.rotation.y,
		func(c: Vector3i) -> bool: return world != null and BlockIds.is_solid(world.get_block(c)))
	b.end_ride()
	if peer != 0:
		Session.send_ride_off(peer, spot)


## Host, 10 times a second: riders who are gone, knocked out, asleep or hiding get off; in Survivor a flight is
## over when the flyer lands.
func host_check() -> void:
	var free_fly := Game.allows(ModeRules.FREE_FLY)
	for b in _buddies():
		if b.rider_peer == 0:
			continue
		var p := Session._player_for_peer(b.rider_peer)
		if p == null or not _may_ride(p):
			end_ride(b)
		elif RideRules.ride_over(b.ride_mode, free_fly, b.was_airborne(), b.resting()):
			var peer := b.rider_peer
			end_ride(b)
			_tell(peer, "Nice landing!")
	for a in _animal_mounts_ridden():   # owner #41: a horse's or camel's rider who can't ride any more gets off
		var p := Session._player_for_peer(a.rider_peer)
		if p == null or not _may_ride(p) or not a.saddled:
			end_animal_ride(a)


## Host: a line for player `peer` (this game's own, or a guest still here).
func _tell(peer: int, text: String) -> void:
	if peer == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer):
		Session.send_feedback(peer, text)


## The buddy player `peer` rides, or null.
func _ridden_by(peer: int) -> Buddy:
	for b in _buddies():
		if b.rider_peer == peer:
			return b
	return null


static func _may_ride(p: Player) -> bool:
	return p.is_spawned() and not p.knocked_out and not p.sleeping and not p.is_hiding()


func _buddies() -> Array[Buddy]:
	var list: Array[Buddy] = []
	if buddies_root == null:
		return list
	for child in buddies_root.get_children():
		if child is Buddy and not child.is_queued_for_deletion():
			list.append(child)
	return list

# --- Owner feedback #41: riding a horse or a camel (spec §14.19) -----------------------------------------------
# A tamed horse or camel that got a SADDLE rides like a buddy (AnimalRideRules): the same RIDE button, the same
# requests, the host decides, the host moves it (Animal._ride_step), getting off beside it (RideRules).

const NO_SADDLE_ANIMAL := "Tame it, then tap it holding a SADDLE to ride it!"

## Host: player `peer` asks to ride the animal `animal_name`.
func host_ride_animal(peer: int, animal_name: String) -> String:
	var a := animals_root.get_node_or_null(NodePath(animal_name)) as Animal if animals_root else null
	var p := Session._player_for_peer(peer)
	var error := ""
	if a == null or a.is_queued_for_deletion() or a.ride_kind == RideRules.Kind.NONE:
		error = "no_saddle"
	elif p == null or not _may_ride(p) or _ridden_by(peer) != null or _animal_ridden_by(peer) != null:
		error = "busy"
	elif a.rider_peer != 0:
		error = "taken"
	elif not RideRules.can_mount(p.global_position, a.global_position, a.size_blocks, RideRules.HOST_TOLERANCE):
		error = "too_far"
	if error != "":
		_tell(peer, NO_SADDLE_ANIMAL if error == "no_saddle" else _REFUSALS[error])
		return error
	a.start_ride(peer)
	_tell(peer, RideRules.mount_line(a.ride_kind))
	return ""


## Host: the rider gets off `a`, beside it and never inside blocks; its own game is told where to stand.
func end_animal_ride(a: Animal) -> void:
	var peer := a.rider_peer
	var world := Session.world
	var spot := RideRules.dismount_spot(a.global_position, a.size_blocks, a.rotation.y,
		func(c: Vector3i) -> bool: return world != null and BlockIds.is_solid(world.get_block(c)))
	a.end_ride()
	if peer != 0:
		Session.send_ride_off(peer, spot)


func _animal_ridden_by(peer: int) -> Animal:
	for a in _animal_mounts_ridden():
		if a.rider_peer == peer:
			return a
	return null


## The saddled horses and camels nobody rides (the RIDE button's candidates).
func _mounts() -> Array[Animal]:
	var list: Array[Animal] = []
	if animals_root == null:
		return list
	for child in animals_root.get_children():
		var a := child as Animal
		if a and a.ride_kind != RideRules.Kind.NONE and not a.is_queued_for_deletion():
			list.append(a)
	return list


func _animal_mounts_ridden() -> Array[Animal]:
	var list: Array[Animal] = []
	if animals_root == null:
		return list
	for child in animals_root.get_children():
		var a := child as Animal
		if a and a.rider_peer != 0 and not a.is_queued_for_deletion():
			list.append(a)
	return list
