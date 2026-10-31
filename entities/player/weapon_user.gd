class_name WeaponUser
extends Node
## The local player's weapons, tools and practice targets (M1b Task 11), a child of the
## BlockInteractor. A tap (or a click with a captured mouse) uses the selected item where it points:
## a tool uses its block power on a block, a weapon attacks towards the point (an arrow lands where
## you tap), a dummy or bullseye item places one. The ATTACK button, R and the left mouse button
## attack straight ahead (with light aim assist for the bow and the boomerang); holding them with
## the bow draws it, and letting go shoots.
## Attacks go to the host (Session.request_attack), tool powers are ordinary block batches
## (BlockInteractor -> Session.request_set_blocks, checked like any build) and targets are placed
## by the host (Session.request_place_target).
## M2 Task 6: tier items work like their kind; a better tool digs faster. The spear thrusts; a tap on
## something beyond its reach, or ATTACK held and let go, throws it (Session.request_spear_throw).
## Shields are held when selected and protect by themselves; the best one in the hotbar is the
## player's carried_shield (Sandbox). Potions are drunk from the hotbar slot (BlockInteractor.tap_slot).
## Owner feedback #29: ATTACK always attacks, whatever the hand holds (ready_weapon: the held weapon,
## else the best melee weapon in the hotbar comes to hand, else a punch, WeaponRules.FISTS).

const FAR := 60.0              # aim distance for ranged weapons
const TAP_POWER := 1.0         # a tap shoots a full-power arrow
const MAX_BREAK_FX := 12       # block-break bursts per tool use

var interactor: BlockInteractor
## M3 Task 14b: the blasters' own controls (entities/player/blaster_user.gd).
@onready var blasters: BlasterUser = BlasterUser.attach(self)
var drawing := false
var _draw_held := 0.0
var _ready_ms := 0             # local cooldown (the host checks it again)
var _combo := 0
var _last_swing_ms := -100000


func player() -> Player:
	return interactor.player


## Items this node takes over from block placing (a shield or potion tap does nothing in the world).
func handles(id: int) -> bool:
	return WeaponRules.is_weapon(id) or ItemIds.is_target(id) or WeaponRules.is_shield(id) or PotionRules.is_potion(id) \
		or BlasterRules.is_blaster(id) or BlasterRules.is_ammo(id)   # M3 Task 14b (ammo in the hand does nothing)


## A tap on the screen (or a click with a captured mouse).
func use_at_screen(screen_pos: Vector2) -> bool:
	var item := interactor.selected_block()
	if not player().is_spawned():
		return false
	if ItemIds.is_target(item):
		return _place_target(item, interactor.ray_at(screen_pos))
	if blasters.handles(item):
		return blasters.fire_at_screen(screen_pos)   # M3 Task 14b
	if not WeaponRules.is_weapon(item):
		return false                      # shields protect by themselves; potions are drunk from the hotbar
	var thing := interactor.hittable_at(screen_pos, FAR)
	var hit := interactor.ray_at(screen_pos)
	if thing == null and hit != null and WeaponRules.stats(item).power != &"":
		return _use_power(item, hit)
	var point := _center_of(thing) if thing else aim_point(screen_pos)
	var throw := WeaponRules.wants_throw(item, CombatDirector.chest(player()).distance_to(point))
	return attack_towards(item, point, TAP_POWER, throw)


## ATTACK button, R, or the left mouse button with a captured mouse: pressed. It always attacks
## (owner feedback #29): with the weapon in the hand, else the best one in the hotbar, else fists.
func attack_pressed() -> void:
	if blasters.pressed():
		return                            # M3 Task 14b: a blaster in the hand fires (BlasterUser)
	if interactor.gadgets.attack():
		return                            # M3 Task 14a: the hook or an orb in the hand is used
	var p := player()
	if not p.is_spawned() or p.sleeping or p.knocked_out:
		return
	var item := ready_weapon()
	var base := WeaponRules.base_of(item)
	if base == ItemIds.BOW or base == ItemIds.SPEAR:   # held: the bow draws, the spear gets ready to fly
		drawing = true
		_draw_held = 0.0
		if base == ItemIds.BOW:
			player().set_aiming(true)
		_face(_camera_forward())
		return
	attack_towards(item, _assisted_point(item), 1.0)


## What ATTACK attacks with (owner feedback #29): the weapon in the hand; else the best melee weapon
## in the hotbar, whose slot is selected so the child sees it come to hand; else WeaponRules.FISTS.
func ready_weapon() -> int:
	var item := interactor.selected_block()
	if WeaponRules.is_weapon(item):
		return item
	var slot := WeaponRules.best_melee_slot(interactor.hotbar)
	if slot < 0:
		return WeaponRules.FISTS
	interactor.select_slot(slot)
	item = interactor.selected_block()
	var p := player()
	p.held_item = item            # in the hand now, not at the next frame: this swing shows it
	p._update_held_item()
	return item


## ... and released: a drawn bow shoots, harder the longer it was held; a spear held long enough
## is thrown, else it thrusts.
func attack_released() -> void:
	blasters.released()                   # M3 Task 14b
	if not drawing:
		return
	_stop_drawing()
	var item := interactor.selected_block()
	if WeaponRules.base_of(item) == ItemIds.SPEAR:
		var throw := _draw_held >= WeaponRules.SPEAR_THROW_HOLD
		attack_towards(item, aim_point(get_viewport().get_visible_rect().size * 0.5) if throw else _assisted_point(item), 1.0, throw)
		return
	if WeaponRules.base_of(item) != ItemIds.BOW:
		return
	attack_towards(item, _assisted_point(item), WeaponRules.draw_power(_draw_held))


## Keyboard and mouse. Returns true when the event was used.
func handle_input(event: InputEvent, crosshair_mode: bool, center: Vector2) -> bool:
	if event.is_action_pressed(&"attack"):
		attack_pressed()
		return true
	if event.is_action_released(&"attack"):
		attack_released()
		return true
	var item := interactor.selected_block()
	if crosshair_mode and blasters.handles(item):
		return blasters.handle_input(event)   # M3 Task 14b
	if not crosshair_mode or not WeaponRules.is_weapon(item):
		return false
	if event.is_action_pressed(&"break"):
		if WeaponRules.base_of(item) in [ItemIds.BOW, ItemIds.SPEAR]:
			attack_pressed()
		else:
			use_at_screen(center)
		return true
	if event.is_action_released(&"break"):
		attack_released()
		return true
	if event.is_action_pressed(&"place"):
		use_at_screen(center)
		return true
	return false


## Attacks towards a world point: a swing (the host checks what it reaches), an arrow lobbed to
## land there, a boomerang thrown that way, or (throw) a spear lobbed onto it.
## Owner #124: where a shot of `item` leaves this player: in VR the weapon in the hand (Vr.muzzle: a blaster's barrel, the
## bow hand), else the eye.
func shot_from(item: int) -> Vector3:
	var p := player()
	if p != null and p.is_local and p.rig.vr_mode():
		var m: Vector3 = Vr.muzzle(item)
		if m.is_finite():
			return m
	return p.eye_position()


## `straight` (owner #124, a bow drawn in VR): the arrow flies along `point` - its bow, never lobbed to land on `point`.
func attack_towards(item: int, point: Vector3, power: float, throw: bool = false, straight: bool = false) -> bool:
	var w := WeaponRules.stats(item)
	var now := Time.get_ticks_msec()
	if w.is_empty() or now < _ready_ms:
		return false
	var p := player()
	if WeaponRules.base_of(item) == ItemIds.SPEAR:
		if p.spear_out():
			Session.send_feedback(multiplayer.get_unique_id(), "Walk to your spear to pick it up!")
			return false
		if throw:
			return _throw_spear(item, point, now)
	var dir := point - p.eye_position()
	var from := p.eye_position()
	match w.kind:
		WeaponRules.MELEE:
			dir = point - CombatDirector.chest(p)
			_combo = WeaponRules.combo_next(item, _combo, (now - _last_swing_ms) / 1000.0)
			_last_swing_ms = now
		WeaponRules.BOW:
			from = shot_from(item)   # owner #124
			if straight:
				dir = point - from
			else:
				var speed := WeaponRules.arrow_velocity(Vector3.FORWARD, power).length()
				dir = WeaponRules.launch_direction(from, point, speed)
		WeaponRules.BOOMERANG:
			if p._boomerang_flying():
				return false
			from = shot_from(item)   # owner #124
			dir = point - from
	if dir.length() < 0.001:
		dir = _camera_forward()
	_ready_ms = now + int(float(w.cooldown) * 1000.0)
	_face(dir)
	p.play_attack(item, _combo if WeaponRules.base_of(item) == ItemIds.SWORD else 0)
	Audio.play(w.sound, p.global_position)
	if from != p.eye_position():
		Session.request_shot_origin(from)   # owner #124: the host starts the shot at the weapon
	Session.request_attack(item, dir.normalized(), power)
	return true


## Where the screen point aims, up to FAR away: a block face, or a point in the air.
func aim_point(screen_pos: Vector2) -> Vector3:
	var ray := player().aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var dir: Vector3 = ray[1]
	var reach := from.distance_to(player().eye_position()) + FAR
	var hit := player().world.raycast(from, dir, reach)
	return from + dir * (hit.distance if hit else reach)


func _assisted_point(item: int) -> Vector3:
	var point := aim_point(get_viewport().get_visible_rect().size * 0.5)
	var w := WeaponRules.stats(item)
	if w.kind == WeaponRules.MELEE:
		return point                      # the host pulls swings onto nearby targets
	var eye := player().eye_position()
	var things := CombatDirector.hittables(get_tree(), player())
	var positions: Array = []
	for t in things:
		positions.append(t.pos)
	var i := WeaponRules.assist_target(eye, point - eye, positions, float(w.reach), WeaponRules.RANGED_ASSIST_ANGLE)
	return positions[i] if i >= 0 else point


func _center_of(node: Node3D) -> Vector3:
	for t in CombatDirector.hittables(get_tree(), player()):
		if t.node == node:
			return t.pos
	return node.global_position


# --- Tool powers ------------------------------------------------------------------------------

func _use_power(item: int, hit: BlockHit) -> bool:
	var now := Time.get_ticks_msec()
	if now < _ready_ms:
		return false
	var p := player()
	var world := p.world
	var feet_y := floori(p.global_position.y + 0.01)
	var edits := ToolPowers.for_tool(item, hit.position, hit.previous_position - hit.position, feet_y, world.get_block)
	if edits.is_empty():
		return false
	var old: Array[int] = []
	for e: Array in edits:
		old.append(world.get_block(e[0]))
	# A felled tree is not mirrored: its mirror image would be random ground, not a tree.
	if not interactor.apply_edits(edits, WeaponRules.base_of(item) != ItemIds.AXE):
		return false
	_ready_ms = now + int(WeaponRules.power_cooldown(item) * 1000.0)   # a better tier digs faster
	var target := Vector3(hit.position) + Vector3(0.5, 0.5, 0.5)
	var dir := target - CombatDirector.chest(p)
	_face(dir)
	p.play_attack(item, 0)
	Audio.play(&"swing", p.global_position)
	Audio.play(&"smash" if item == ItemIds.HAMMER else &"break", target)
	var step := maxi(edits.size() / MAX_BREAK_FX, 1)
	for i in range(0, edits.size(), step):
		Fx.break_block(world, edits[i][0], old[i])
	if item == ItemIds.HAMMER:
		Fx.burst(world, target + Vector3(0, 0.6, 0), Color("b89a7c"), 24, 6.0, 0.16, 0.6, 10.0)
		Session.request_attack(item, dir.normalized(), 1.0)   # the smash pushes what stands near
	interactor.edited.emit(&"break")
	return true


# --- Practice targets -------------------------------------------------------------------------

func _place_target(item: int, hit: BlockHit) -> bool:
	if hit == null:
		return false
	var cell := hit.previous_position
	if not WeaponRules.target_spot_ok(cell, player().world.get_block):
		Session.send_feedback(multiplayer.get_unique_id(), "Targets need flat ground and room above.")
		return false
	# It faces the player who places it.
	Session.request_place_target(item, cell, player().rig.yaw + PI)
	return true


# --- Helpers ----------------------------------------------------------------------------------

func _face(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() > 0.01 and not player().rig.first_person:
		player().avatar.rotation.y = atan2(-dir.x, -dir.z)


func _camera_forward() -> Vector3:
	return -player().camera().global_basis.z


func _stop_drawing() -> void:
	drawing = false
	player().set_aiming(false)


func _process(delta: float) -> void:
	var p := player()
	if p == null:
		return
	var item := interactor.selected_block()
	var held := item if WeaponRules.is_holdable(item) else 0
	if p.held_item != held:
		p.held_item = held
	var shield := WeaponRules.best_shield(interactor.hotbar)   # Sandbox protection (M2 Task 6)
	if p.carried_shield != shield:
		p.carried_shield = shield
	if drawing:
		_draw_held += delta
		var base := WeaponRules.base_of(item)
		if (base != ItemIds.BOW and base != ItemIds.SPEAR) or not p.is_spawned():
			_stop_drawing()


# --- Spear throw (M2 Task 6) ---

## Lobs the spear onto `point` (the host flies it; one spear out per player).
func _throw_spear(item: int, point: Vector3, now: int) -> bool:
	var p := player()
	var dir := WeaponRules.launch_direction(p.eye_position(), point, WeaponRules.SPEAR_THROW_SPEED, WeaponRules.SPEAR_GRAVITY)
	_ready_ms = now + int(float(WeaponRules.stats(item).cooldown) * 1000.0)
	_face(dir)
	p.play_attack(item, WeaponRules.THROW)
	Audio.play(&"swing", p.global_position)
	Session.request_spear_throw(item, dir)
	return true
