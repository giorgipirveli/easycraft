class_name BlasterUser
extends Node
## The local player's blasters (M3 Task 14b, spec §13.4), a child of the WeaponUser ("Blasters"). With a
## blaster in the hand, ATTACK (R, the left mouse button with a captured mouse) fires it straight ahead with
## light aim assist, and keeps firing at its rate while held (a magazine, then its reload); a tap on the
## screen fires where the finger points. Arcing blasters (the snowballs, the paint) lob their shot to land
## where you aim. Every shot is a request to the host (Session.request_blast), which checks it again and
## flies it for everyone; this game plays the kick and the sound at once. The WeaponUser asks this node
## first (hooks at the top of its attack_pressed / attack_released, use_at_screen and handle_input), so the
## blasters live in their own file.

## The game's clock in msec (tests replace it).
var clock: Callable = Time.get_ticks_msec
var weapons: WeaponUser
var holding := false              # ATTACK held with a blaster: it keeps firing
## Shots this game kicked off (tests).
var shots_sent := 0

var _magazines := {}              # blaster id -> BlasterRules.Magazine (this game's pace; the host keeps its own)


static func attach(to: WeaponUser) -> BlasterUser:
	var b := BlasterUser.new()
	b.name = "Blasters"
	b.weapons = to
	to.add_child(b)
	return b


func handles(id: int) -> bool:
	return BlasterRules.is_blaster(id)


func _selected() -> int:
	return weapons.interactor.selected_block()


func _player() -> Player:
	return weapons.player()


## ATTACK pressed: true when a blaster is in the hand (it fires; the WeaponUser does nothing else).
func pressed() -> bool:
	var item := _selected()
	if not handles(item):
		return false
	holding = true
	fire(item, _center_point(item))
	return true


func released() -> void:
	holding = false


## A tap on the screen with a blaster: it fires where the finger points (at a monster there, if any).
func fire_at_screen(screen_pos: Vector2) -> bool:
	var item := _selected()
	if not handles(item) or not _player().is_spawned():
		return false
	var thing := weapons.interactor.hittable_at(screen_pos, WeaponUser.FAR)
	var point := weapons._center_of(thing) if thing else weapons.aim_point(screen_pos)
	return fire(item, point)


## Mouse buttons with a captured mouse (a blaster in the hand): either fires, holding keeps firing.
func handle_input(event: InputEvent) -> bool:
	if event.is_action_pressed(&"break") or event.is_action_pressed(&"place"):
		return pressed()
	if event.is_action_released(&"break") or event.is_action_released(&"place"):
		released()
		return true
	return false


## Fires `item` towards `point` if its magazine is ready: the kick and sound here, the shot on the host.
## In Survivor without ammo nothing kicks (the host says what is missing). Returns true when it fired.
func fire(item: int, point: Vector3) -> bool:
	var p := _player()
	if p == null or not p.is_spawned() or not handles(item):
		return false
	var now: int = clock.call()
	var mag := _magazine(item)
	if not mag.can_fire(now):
		return false
	var from := weapons.shot_from(item)   # owner #124: in VR the gun in the hand, else the eye
	var dir := _aim(item, from, point)
	if not _has_ammo(item):
		Session.request_blast(item, dir)          # the host explains ("Out of Foam Darts!")
		holding = false
		return false
	mag.fire(now)
	shots_sent += 1
	weapons._face(dir)
	p.play_attack(item, 0)
	Audio.play(BlasterRules.sound(item), from, -2.0)
	if from != p.eye_position():
		Session.request_shot_origin(from)
	Session.request_blast(item, dir)
	return true


## Seconds until the blaster in the hand is reloaded (0: ready or not reloading).
func reload_left(item: int) -> float:
	return _magazine(item).reload_left(clock.call()) if handles(item) else 0.0


func _magazine(item: int) -> BlasterRules.Magazine:
	if not _magazines.has(item):
		_magazines[item] = BlasterRules.Magazine.new(item)
	return _magazines[item]


func _has_ammo(item: int) -> bool:
	if Game.allows(ModeRules.UNLIMITED_BLOCKS):
		return true
	var inv := Session.inventory_of(multiplayer.get_unique_id()) if Session.is_host() else Session.my_inventory
	return inv.count(BlasterRules.ammo_of(item)) > 0


## Straight at the point, or (a blaster whose shots fall) lobbed to land on it.
func _aim(item: int, eye: Vector3, point: Vector3) -> Vector3:
	var g := BlasterRules.gravity(item)
	if g > 1.0 and point.is_finite():
		return WeaponRules.launch_direction(eye, point, BlasterRules.speed(item), g)
	var d := point - eye
	return d if d.length() > 0.001 else weapons._camera_forward()


## Straight ahead from the screen's middle, pulled onto a thing close to the aim (like the bow).
func _center_point(item: int) -> Vector3:
	var point := weapons.aim_point(get_viewport().get_visible_rect().size * 0.5)
	var eye := _player().eye_position()
	var positions: Array = []
	for t in CombatDirector.hittables(get_tree(), _player()):
		if t.kind == WeaponRules.MONSTER or t.kind == WeaponRules.DUMMY or t.kind == WeaponRules.BULLSEYE_TARGET:
			positions.append(t.pos)
	var reach := BlasterRules.speed(item) * BlasterRules.life(item)
	var i := WeaponRules.assist_target(eye, point - eye, positions, reach, WeaponRules.RANGED_ASSIST_ANGLE)
	return positions[i] if i >= 0 else point


## Held ATTACK keeps firing at the blaster's rate; another slot (or no player) lets go.
func _process(_delta: float) -> void:
	if not holding:
		return
	var item := _selected()
	var p := _player()
	if not handles(item) or p == null or not p.is_spawned():
		holding = false
		return
	if _magazine(item).can_fire(clock.call()):
		fire(item, _center_point(item))
