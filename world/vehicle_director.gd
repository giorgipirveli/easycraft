class_name VehicleDirector
extends Node
## Owner #109 (spec §3b "Cars"): node "Vehicles" in the sandbox, on every game: its "Cars" (Vehicle nodes, the host's
## MultiplayerSpawner "CarSpawner" makes them on every game) and the cars' requests, which the host decides.
## Every game with a player: MORE → CARS opens the garage (GaragePanel: GET IT in the Sandbox, BUY and CALL MY CAR in
## Survivor, PUT AWAY); the RIDE button says DRIVE or GET IN next to a car with a free seat (RideDirector asks
## nearest_car) and HOP OFF in it (Session's ride-off request: the host lets the rider out beside the car, never inside
## blocks); HORN (spot `horn`) in a car and FLY / LAND (spot `car_fly`) for a flying car's driver, UP and DOWN while it
## flies; a tap on a car gets in (a tap on a pickup holding blocks loads 8, holding nothing placeable unloads it);
## H honks, E (and the physics switch's key or pad button: Triangle / Y) hops off; the camera swings round behind a
## moving car (never in VR), a rider's own car stays out of its camera's spring arm, a big car's camera sits further back;
## in VR a black blink on getting in and out, facing the car's front. A guest's cars are its profile's (it says which
## when it arrives, trusted like its LAN gold).
## Host: one of each kind per child (by name), PER_PLAYER out at once, MAX_CARS in a world, none in the arena; who may
## get in (able to ride, near the car, a free seat), the driver's stick (Vehicle), riders who can't ride any more get out
## (10 times a second), the pickup's bed (Survivor: from and back into the bag; the Sandbox tips it out behind), the save.

signal garage_toggled(open: bool)

const HORN_KEY := KEY_H
const OUT_KEY := KEY_E
const CHECK_EVERY := 0.1

## The cars (Vehicle nodes; the spawner puts them here on every game).
var cars_root := Node3D.new()
var spawner := MultiplayerSpawner.new()
## This game's player and HUD (none until the player is there: setup_local), where the garage opens.
var player: Player
var hud: Hud
var ui_parent: Node
## Tests: the host's 10-a-second check (default: every physics step).
var host_checks := true
## Saves this game's profile (a car bought; tests put their own).
var save_profile: Callable = func() -> void: Profile.save()
## The garage's MORE button and the garage (while open).
var cars_button: TouchButton
var garage: GaragePanel

var _next := 1
var _born := 0
var _owned := {}        # host: a guest's peer id -> Array[StringName] its profile owns (it says so when it arrives)
var _check := 0.0
var _horn_wait := {}    # host: car name -> seconds until its horn sounds again
var _in_car := false    # this game: its player sat in a car at the last look
var _camera_was := -1.0


func _ready() -> void:
	cars_root.name = "Cars"
	add_child(cars_root)
	spawner.name = "CarSpawner"
	add_child(spawner)
	spawner.spawn_path = spawner.get_path_to(cars_root)
	spawner.spawn_function = _make_car
	if Session.is_host():
		Session.ride_off_requested.connect(func(peer: int) -> void: host_get_out(peer))
		Session.peer_left.connect(_on_peer_left)


func _make_car(data: Variant) -> Node:
	var v := Vehicle.new()
	v.setup(data)
	return v


## Every car in this world.
func cars() -> Array[Vehicle]:
	var list: Array[Vehicle] = []
	for c in cars_root.get_children():
		if c is Vehicle and not c.is_queued_for_deletion():
			list.append(c)
	return list


## `owner`'s car of `kind` in this world, or null.
func car_of(owner: String, kind: StringName) -> Vehicle:
	for c in cars():
		if c.owner_name == owner and c.kind == kind:
			return c
	return null


## The car player `peer` sits in, or null.
func car_with(peer: int) -> Vehicle:
	for c in cars():
		if c.has_rider(peer):
			return c
	return null


## A player's name, which owns their cars: this game's is the profile's, a guest its chat name.
func name_of(peer: int) -> String:
	if peer == multiplayer.get_unique_id():
		var n := str(Profile.data.username)
		return n if n != "" else "player"
	return str(Session.chat_names.get(peer, "friend %d" % peer))


## The kinds player `peer` owns (Survivor): this game's profile's; a guest's as it said.
func owned_by(peer: int) -> Array:
	if peer == multiplayer.get_unique_id():
		return VehicleRules.owned_kinds(Profile.data.bought)
	return _owned.get(peer, [])


static func _may_ride(p: Player) -> bool:
	return p != null and p.is_spawned() and not p.knocked_out and not p.sleeping and not p.is_hiding()


## Host: a line for player `peer` (this game's own, or a guest still here).
func _tell(peer: int, text: String) -> void:
	if text != "" and (peer == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer)):
		Session.send_feedback(peer, text)


func _refuse(peer: int, reason: String, kind: StringName = &"") -> String:
	_tell(peer, VehicleRules.words(reason, kind))
	return reason


func _solid(c: Vector3i) -> bool:
	var w := Session.world
	return w != null and BlockIds.is_solid(w.get_block(c))


# --- Requests (every game -> the host) ------------------------------------------------------------------------------

## GET IT (the Sandbox) or CALL MY CAR (an owned one): the car comes in front of this game's child, facing the way the
## camera looks.
func request_car(kind: StringName, colour: int) -> void:
	var yaw := _look_yaw()
	if Session.is_host():
		host_car(multiplayer.get_unique_id(), kind, colour, yaw)
	else:
		_rpc_car.rpc_id(1, String(kind), colour, yaw)


func request_buy(kind: StringName, colour: int) -> void:
	var yaw := _look_yaw()
	if Session.is_host():
		host_buy(multiplayer.get_unique_id(), kind, colour, yaw)
	else:
		_rpc_buy.rpc_id(1, String(kind), colour, yaw)


func request_put_away(kind: StringName) -> void:
	if Session.is_host():
		host_put_away(multiplayer.get_unique_id(), kind)
	else:
		_rpc_put_away.rpc_id(1, String(kind))


func request_get_in(car_name: String) -> void:
	if Session.is_host():
		host_get_in(multiplayer.get_unique_id(), car_name)
	else:
		_rpc_get_in.rpc_id(1, car_name)


## HOP OFF: the rides' own request (the host's ride-off signal lets this game's child out of its car).
func request_get_out() -> void:
	Session.request_ride_off()


func request_horn() -> void:
	if Session.is_host():
		host_horn(multiplayer.get_unique_id())
	else:
		_rpc_horn.rpc_id(1)


func request_fly(on: bool) -> void:
	if Session.is_host():
		host_fly(multiplayer.get_unique_id(), on)
	else:
		_rpc_fly.rpc_id(1, on)


func request_load(car_name: String, block: int) -> void:
	if Session.is_host():
		host_load(multiplayer.get_unique_id(), car_name, block)
	else:
		_rpc_load.rpc_id(1, car_name, block)


func request_unload(car_name: String) -> void:
	if Session.is_host():
		host_unload(multiplayer.get_unique_id(), car_name)
	else:
		_rpc_unload.rpc_id(1, car_name)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_car(kind: String, colour: int, yaw: float) -> void:
	if Session.is_host():
		host_car(multiplayer.get_remote_sender_id(), StringName(kind.left(32)), colour, yaw)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_buy(kind: String, colour: int, yaw: float) -> void:
	if Session.is_host():
		host_buy(multiplayer.get_remote_sender_id(), StringName(kind.left(32)), colour, yaw)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_put_away(kind: String) -> void:
	if Session.is_host():
		host_put_away(multiplayer.get_remote_sender_id(), StringName(kind.left(32)))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_get_in(car_name: String) -> void:
	if Session.is_host():
		host_get_in(multiplayer.get_remote_sender_id(), car_name.left(32))


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_horn() -> void:
	if Session.is_host():
		host_horn(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _rpc_fly(on: bool) -> void:
	if Session.is_host():
		host_fly(multiplayer.get_remote_sender_id(), on)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_load(car_name: String, block: int) -> void:
	if Session.is_host():
		host_load(multiplayer.get_remote_sender_id(), car_name.left(32), block)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_unload(car_name: String) -> void:
	if Session.is_host():
		host_unload(multiplayer.get_remote_sender_id(), car_name.left(32))


## A guest tells the host which cars its profile owns (when it arrives, and after it bought one).
@rpc("any_peer", "call_remote", "reliable")
func _rpc_owned(kinds: PackedStringArray) -> void:
	if not Session.is_host():
		return
	var list: Array[StringName] = []
	for k in kinds:
		if CarKinds.exists(StringName(k)) and not list.has(StringName(k)):
			list.append(StringName(k))
	_owned[multiplayer.get_remote_sender_id()] = list


## Host -> the guest who bought a car: it is the guest's own now (its profile keeps it).
@rpc("authority", "call_remote", "reliable")
func _rpc_bought(kind: String) -> void:
	_own(StringName(kind))


## This game's profile owns `kind` now (it saves).
func _own(kind: StringName) -> void:
	if not CarKinds.exists(kind):
		return
	var id := VehicleRules.owned_id(kind)
	if not Profile.data.bought.has(id) and Profile.data.bought.size() < SpendRules.MAX_BOUGHT:
		Profile.data.bought.append(id)
		save_profile.call()
	if is_instance_valid(garage):
		garage.refresh()


# --- Host ------------------------------------------------------------------------------------------------------------

## Host: player `peer` wants its car of `kind` out (GET IT, CALL MY CAR), in `colour`, in front of it looking `yaw`. ""
## when it came, else why not (and the child hears why).
func host_car(peer: int, kind: StringName, colour: int, yaw: float) -> String:
	if not Session.is_host():
		return "busy"
	if not Game.allows(ModeRules.BUILDING):
		return _refuse(peer, "arena")
	var p := Session._player_for_peer(peer)
	if not _may_ride(p):
		return _refuse(peer, "busy")
	var why := VehicleRules.may_get(kind, Game.allows(ModeRules.INFINITE_GOLD), owned_by(peer))
	if why != "":
		return _refuse(peer, why, kind)
	var owner := name_of(peer)
	var mine := car_of(owner, kind)
	var bodies: Array = Session._player_bodies()
	for c in cars():
		if c != mine:
			bodies.append(VehicleRules.car_aabb(c.global_position, c.rotation.y, c.kind))   # never on a parked car
	var spot := VehicleRules.place_spot(p.global_position, yaw if is_finite(yaw) else 0.0, kind, _solid, bodies)
	if spot.is_empty():
		return _refuse(peer, "no_room", kind)
	if mine != null:
		if mine.has_riders():
			return _refuse(peer, "ridden", kind)
		mine.host_place(spot.pos, spot.yaw)
		mine.colour = colour
		mine.host_fx(&"puff")
		_tell(peer, "Beep beep! Here's your %s!" % CarKinds.display_name(kind))
		return ""
	var list: Array = []
	for c in cars():
		list.append({"owner": c.owner_name, "born": c.born, "ridden": c.has_riders(), "car": c})
	var home := VehicleRules.goes_home(list, owner)
	if home >= 0:
		var gone: Vehicle = list[home].car
		_tell(peer, "Your %s went back to the garage." % CarKinds.display_name(gone.kind))
		gone.queue_free()
	elif list.size() >= VehicleRules.MAX_CARS:
		return _refuse(peer, "world_full")
	var car := host_spawn({"kind": String(kind), "colour": colour, "owner": owner, "pos": spot.pos, "yaw": spot.yaw})
	if car:
		car.host_fx(&"puff")
	_tell(peer, "Beep beep! Here's your %s! Get in with DRIVE." % CarKinds.display_name(kind))
	return ""


## Host: a car comes into the world (the garage, a save). Its name is new; it is the newest born.
func host_spawn(data: Dictionary) -> Vehicle:
	var d := data.duplicate()
	var p: Variant = d.get("pos", Vector3.ZERO)
	if p is Array:
		d.pos = Vector3(float(p[0]), float(p[1]), float(p[2]))
	_born += 1
	d.born = _born
	d.id = "Car%d" % _next
	_next += 1
	return spawner.spawn(d) as Vehicle


## Host (Survivor): player `peer` buys `kind` with its Survivor gold; it is its own for good (its profile's) and comes
## out at once.
func host_buy(peer: int, kind: StringName, colour: int, yaw: float) -> String:
	if not Session.is_host():
		return "busy"
	if not CarKinds.exists(kind):
		return _refuse(peer, "unknown")
	if Game.allows(ModeRules.INFINITE_GOLD):
		return host_car(peer, kind, colour, yaw)   # the Sandbox: free
	if owned_by(peer).has(kind):
		return _refuse(peer, "owned", kind)
	if not Session.gold_spend(peer, CarKinds.price(kind)):
		return _refuse(peer, "gold", kind)
	if peer == multiplayer.get_unique_id():
		_own(kind)
	else:
		var list: Array = _owned.get(peer, []).duplicate()
		list.append(kind)
		_owned[peer] = list
		if multiplayer.get_peers().has(peer):
			_rpc_bought.rpc_id(peer, String(kind))
	_tell(peer, "The %s is yours! It waits in your garage in every Survivor world." % CarKinds.display_name(kind))
	host_car(peer, kind, colour, yaw)
	return ""


## Host: player `peer` sends its car of `kind` back to the garage (never while somebody is in it).
func host_put_away(peer: int, kind: StringName) -> String:
	var car := car_of(name_of(peer), kind)
	if car == null:
		return "none"
	if car.has_riders():
		return _refuse(peer, "ridden", kind)
	car.host_fx(&"puff")
	car.queue_free()
	_tell(peer, "Your %s is back in the garage." % CarKinds.display_name(kind))
	return ""


## Host: player `peer` asks to get into `car_name`. "" when it got in, else why not.
func host_get_in(peer: int, car_name: String) -> String:
	if not Session.is_host():
		return "busy"
	var car := cars_root.get_node_or_null(NodePath(car_name)) as Vehicle
	if car == null or car.is_queued_for_deletion():
		return "unknown"
	var p := Session._player_for_peer(peer)
	if not _may_ride(p) or p.is_riding() or car_with(peer) != null:
		return _refuse(peer, "busy")
	if not VehicleRules.can_board(p.global_position, car.global_position, car.kind, car.rotation.y,
			VehicleRules.HOST_TOLERANCE):
		return _refuse(peer, "too_far")
	var seat := car.host_board(peer)
	if seat < 0:
		return _refuse(peer, "full")
	if seat == 0:
		car.host_fx(&"start")
		_tell(peer, "Vroom! The stick drives." + (" FLY lifts it up!" if CarKinds.flies(car.kind) else ""))
	else:
		_tell(peer, "Hop in! You're riding along in the %s." % CarKinds.display_name(car.kind))
	return ""


## Host: player `peer` gets out of its car, beside it and never inside blocks; its own game is told where to stand.
func host_get_out(peer: int) -> void:
	var car := car_with(peer)
	if car == null:
		return
	var s := CarKinds.size(car.kind)
	var spot := RideRules.dismount_spot(car.global_position, Vector3i(ceili(s.x), ceili(s.y), ceili(s.z)), car.rotation.y,
		_solid)
	car.host_leave(peer)
	if peer == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer):
		Session.send_ride_off(peer, spot)


## Host: the driver's FLY (on) or LAND (off) for its flying car.
func host_fly(peer: int, on: bool) -> String:
	var car := car_with(peer)
	if car == null or car.driver() != peer or not CarKinds.flies(car.kind):
		return "not_driving"
	car.host_fly(on)
	return ""


## Host: anyone in a car honks it (on every game), now and then.
func host_horn(peer: int) -> String:
	var car := car_with(peer)
	if car == null:
		return "not_in_a_car"
	var now := Time.get_ticks_msec() / 1000.0
	if float(_horn_wait.get(String(car.name), -INF)) > now:
		return "wait"
	_horn_wait[String(car.name)] = now + VehicleRules.HORN_EVERY
	car.host_fx(&"horn")
	return ""


## Host: player `peer` loads 8 of `block` into the pickup `car_name` (Survivor: from its bag).
func host_load(peer: int, car_name: String, block: int) -> String:
	var car := cars_root.get_node_or_null(NodePath(car_name)) as Vehicle
	var p := Session._player_for_peer(peer)
	if car == null or not CarKinds.carries_load(car.kind) or not _may_ride(p):
		return "unknown"
	if not VehicleRules.can_board(p.global_position, car.global_position, car.kind, car.rotation.y,
			VehicleRules.HOST_TOLERANCE):
		return _refuse(peer, "too_far")
	if not VehicleRules.loadable(block):
		return _refuse(peer, "not_a_block")
	var room := VehicleRules.CARGO_MAX - VehicleRules.cargo_total(car.cargo)
	var n := mini(VehicleRules.LOAD_STEP, room)
	var bag: Inventory = null
	if not Game.allows(ModeRules.UNLIMITED_BLOCKS):
		bag = Session.inventory_of(peer)
		n = mini(n, bag.count(block))
		if n <= 0 and room > 0:
			return _refuse(peer, "no_blocks")
	var r := VehicleRules.cargo_add(car.cargo, block, n)
	if int(r.added) <= 0:
		return _refuse(peer, "bed_full")
	if bag:
		bag.take(block, int(r.added))
	car.cargo = r.cargo
	car.host_fx(&"thud")
	_tell(peer, "%d %s loaded!" % [int(r.added), BlockIds.display_name(block)])
	return ""


## Host: the pickup's load comes out: Survivor back into the bag of player `peer`; the Sandbox tips it out behind the
## truck as real blocks (where there is room).
func host_unload(peer: int, car_name: String) -> String:
	var car := cars_root.get_node_or_null(NodePath(car_name)) as Vehicle
	var p := Session._player_for_peer(peer)
	if car == null or car.cargo.is_empty() or not _may_ride(p):
		return "unknown"
	if not VehicleRules.can_board(p.global_position, car.global_position, car.kind, car.rotation.y,
			VehicleRules.HOST_TOLERANCE):
		return _refuse(peer, "too_far")
	var load := car.cargo
	if not Game.allows(ModeRules.UNLIMITED_BLOCKS):
		var bag := Session.inventory_of(peer)
		for i in range(0, load.size() - 1, 2):
			bag.add(load[i], load[i + 1])
		_tell(peer, "The load is back in your bag!")
	else:
		var world := Session.world
		var back := car.global_position + Basis(Vector3.UP, car.rotation.y) * Vector3(0, 0, CarKinds.size(car.kind).z * 0.5 + 1.6)
		var bodies := Session._player_bodies()
		var free := func(c: Vector3i) -> bool:
			if world == null or world.get_block(c) != BlockIds.AIR:
				return false
			for b: AABB in bodies:
				if b.intersects(AABB(Vector3(c), Vector3.ONE)):
					return false
			return true
		var cells := VehicleRules.tip_cells(back, VehicleRules.cargo_total(load), free, _solid)
		var k := 0
		for i in range(0, load.size() - 1, 2):
			for j in load[i + 1]:
				if k < cells.size():
					world.set_block(cells[k], load[i])
				k += 1
		_tell(peer, "Tipped out!")
	car.cargo = PackedInt32Array()
	car.host_fx(&"thud")
	return ""


func _physics_process(delta: float) -> void:
	if not host_checks or not Session.is_host():
		return
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	host_check()


## Host, 10 times a second: riders who are gone, knocked out, asleep or hiding get out.
func host_check() -> void:
	for car in cars():
		for peer in VehicleRules.riders(car.seats):
			var p := Session._player_for_peer(peer)
			if p == null or p.is_queued_for_deletion():
				car.host_leave(peer)
			elif not _may_ride(p):
				host_get_out(peer)


func _on_peer_left(peer: int) -> void:
	for car in cars():
		car.host_leave(peer)
	_owned.erase(peer)


# --- The save ------------------------------------------------------------------------------------------------------

## The parked cars (and the ridden ones, where they are).
func to_save() -> Array:
	var out: Array = []
	for c in cars():
		out.append(c.to_save())
	return out


## Host: the saved cars come back (VehicleRules.clean_save'd), parked where they were.
func restore(saved: Array) -> void:
	for d: Dictionary in saved:
		if cars().size() >= VehicleRules.MAX_CARS:
			break
		var car := host_spawn({"kind": d.kind, "colour": d.colour, "owner": d.owner, "pos": d.pos, "yaw": d.yaw,
			"cargo": PackedInt32Array(d.get("cargo", []))})
		if car:
			car.host_place(car.global_position, float(d.yaw))


# --- This game -------------------------------------------------------------------------------------------------------

## This game's player and HUD: MORE → CARS, HORN and FLY, the garage's place, the taps on cars. A guest says which cars
## its profile owns.
func setup_local(p: Player, h: Hud, parent: Node) -> void:
	player = p
	hud = h
	ui_parent = parent
	if hud:
		hud.add_car_controls()
		hud.horn_button.pressed.connect(request_horn)
		hud.car_fly_button.pressed.connect(func() -> void:
			var car := my_car()
			if car:
				request_fly(not car.flying))
		cars_button = TouchButton.new()
		cars_button.name = "Cars"
		cars_button.text = "CARS"
		cars_button.symbol = &"car"
		hud.more.add(cars_button, true)
		cars_button.pressed.connect(open_garage)
		cars_button.visible = Game.allows(ModeRules.BUILDING)   # no cars in the arena
	if player:
		player.ride_changed.connect(_on_ride_changed)
		var tap := player.get_node_or_null("BlockInteractor") as BlockInteractor
		if tap:
			tap.vehicle_tap = tap_at_screen
	if not Session.is_host() and multiplayer.has_multiplayer_peer():
		_rpc_owned.rpc_id(1, PackedStringArray(VehicleRules.owned_kinds(Profile.data.bought).map(
			func(k: StringName) -> String: return String(k))))
	_show_buttons()


## The car this game's player sits in, or null.
func my_car() -> Vehicle:
	if not is_instance_valid(player) or not player.in_car():
		return null
	return player.riding_vehicle


## RideDirector: the nearest car with a free seat this game's player could get into (null for none) and its distance².
func nearest_car(feet: Vector3) -> Vehicle:
	var best: Vehicle = null
	var best_d := INF
	for c in cars():
		if VehicleRules.free_seat(c.seats) < 0:
			continue
		if not VehicleRules.can_board(feet, c.global_position, c.kind, c.rotation.y):
			continue
		var d := feet.distance_squared_to(c.global_position)
		if d < best_d:
			best = c
			best_d = d
	return best


## Where this game's camera looks (the car comes in front of the child).
func _look_yaw() -> float:
	if not is_instance_valid(player):
		return 0.0
	if player.rig.vr_mode():
		return VrRules.yaw_of(Vr.head_transform().basis)
	return player.rig.yaw


## How this game's child drives: a PC's keys, a pad's (or the Quest's controllers') buttons, or the screen's.
func _device() -> StringName:
	if Vr.active() or PadFocus.playing_with_pad():
		return VehicleRules.PAD
	if PlatformRules.keyboard_first(PlatformRules.current()):
		return VehicleRules.KEYBOARD
	return VehicleRules.TOUCH


func open_garage() -> void:
	if garage_open() or ui_parent == null:
		return
	garage = GaragePanel.new(self)
	ui_parent.add_child(garage)
	garage.closed.connect(close_garage)
	if PlatformRules.captures_mouse(PlatformRules.current()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # a PC clicks the garage (the next click looks around again)
	garage_toggled.emit(true)


func close_garage() -> void:
	if is_instance_valid(garage):
		garage.queue_free()
	garage = null
	garage_toggled.emit(false)


func garage_open() -> bool:
	return is_instance_valid(garage) and not garage.is_queued_for_deletion()


## Android Back: the garage closes first.
func close_if_open() -> bool:
	if garage_open():
		close_garage()
		return true
	return false


## BlockInteractor: a tap on a car gets in (a pickup's bed holding blocks loads it, holding nothing placeable unloads
## it); a tap through this game's own car does nothing (no building through it). False when no car was tapped.
func tap_at_screen(screen_pos: Vector2) -> bool:
	if not is_instance_valid(player) or not player.is_inside_tree():
		return false
	var ray := player.aim_ray(screen_pos)
	var from: Vector3 = ray[0]
	var to: Vector3 = from + (ray[1] as Vector3) * PlacementRules.ray_length(from, player.eye_position())
	var query := PhysicsRayQueryParameters3D.create(from, to, Vehicle.LAYER, [player.get_rid()])
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	var car := hit.get("collider") as Vehicle if not hit.is_empty() else null
	if car == null:
		return false
	if player.in_car():
		return true
	var held := (player.get_node("BlockInteractor") as BlockInteractor).selected_block()
	if CarKinds.carries_load(car.kind) and VehicleRules.loadable(held):
		request_load(String(car.name), held)
	elif CarKinds.carries_load(car.kind) and not car.cargo.is_empty() and not BlockIds.is_valid(held):
		request_unload(String(car.name))
	else:
		request_get_in(String(car.name))
	return true


func _unhandled_input(event: InputEvent) -> void:
	if my_car() == null:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		if key.physical_keycode == HORN_KEY:
			request_horn()
			get_viewport().set_input_as_handled()
		elif key.physical_keycode == OUT_KEY:
			request_get_out()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"physics_mode") and not event is InputEventKey:   # a pad's Triangle / Y, the Quest's
		request_get_out()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	local_step(delta)


## This game, every frame: the buttons, the horn on JUMP in a ground car, the camera behind a moving car.
func local_step(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var car := my_car()
	if (car != null) != _in_car:
		_on_ride_changed(car != null)
	_show_buttons()
	if car == null:
		return
	if car.driver() == player.peer_id and not CarKinds.flies(car.kind) and Input.is_action_just_pressed(&"jump"):
		request_horn()   # JUMP in a ground car honks (it never hops off: HOP OFF does)
	if not player.rig.vr_mode() and not player.rig.first_person:
		player.rig.yaw = VehicleRules.chase_yaw(player.rig.yaw, car.rotation.y, absf(car.shown_speed),
			player.rig.since_look(), delta)


func _show_buttons() -> void:
	if not is_instance_valid(hud) or hud.horn_button.get_parent() == null:
		return
	var car := my_car()
	hud.horn_button.visible = car != null and hud.jump_button.visible
	var flyer := car != null and CarKinds.flies(car.kind) and car.driver() == player.peer_id
	hud.car_fly_button.visible = flyer and hud.jump_button.visible
	var word := "LAND" if flyer and car.flying else "FLY"
	if hud.car_fly_button.text != word:
		hud.car_fly_button.text = word
		hud.car_fly_button.symbol = &"down" if word == "LAND" else &"fly"
		hud.car_fly_button.queue_redraw()
	var up_down := flyer and car.flying
	if hud._ride_fly != up_down and (car != null or not player.is_riding()):
		hud.set_ride_up_down(up_down)


## This game's player got in or out of a car: the camera (further back for a big car, never stopped by its own car),
## VR's black blink and the car's front to face.
func _on_ride_changed(_on: bool) -> void:
	var car := my_car()
	var now := car != null
	if now == _in_car:
		return
	_in_car = now
	var arm := player.rig.arm if is_instance_valid(player) else null
	if now:
		if arm:
			arm.add_excluded_object(car.get_rid())
			_camera_was = arm.spring_length
			if not player.rig.first_person and not player.rig.vr_mode():
				arm.spring_length = maxf(arm.spring_length, CarKinds.camera_distance(car.kind))
		if Vr.active():
			player.global_position = car.seat_position(player.peer_id)   # on the seat first: the blink lands there
			Vr.blink()
			Vr.face(car.rotation.y)
		if car.driver() == player.peer_id and is_instance_valid(hud):
			var hint := VehicleRules.drive_hint(CarKinds.flies(car.kind), _device())
			if hint != "":
				hud.toast.call_deferred(hint, 5.0)   # after the host's line ("Vroom!")
	else:
		if arm:
			for c in cars():
				arm.remove_excluded_object(c.get_rid())
			if _camera_was >= 0.0 and not player.rig.first_person and not player.rig.vr_mode():
				player.rig.set_size_scale(player.rig.size_scale)   # its own distance again
		_camera_was = -1.0
		if Vr.active():
			Vr.blink()
	_show_buttons()
