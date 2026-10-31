class_name VrInput
extends Node
## Owner #101 (VR on the Meta Quest): the two Touch controllers play as one game pad. Every button the game already
## knows goes out as the pad input GamepadRules.QUEST_BUTTONS names (InputEventJoypadButton / Motion from one fake pad,
## DEVICE), so the input map's one table (GamepadRules.BINDINGS), PadFocus and the CONTROLLER card work unchanged; an
## event goes first into the VR canvas (Vr.ui_viewport(): a menu there takes its press) and then to the game
## (Input.parse_input_event, which also moves the actions Input.get_vector reads).
## VR's own parts: the walking hand's stick walks (the left stick's axes); the pointing hand's stick turns (snap 45° by
## default, VrRules.snap_step; "smooth" opt-in) and never looks round; the pointing hand's trigger is TAP (place, use,
## talk) and HOLD 0.25 s (break, with the break ring) on the laser's target, as a finger is on the phone
## (TouchClassifier); a controller buzzes on a place, a break and a snap turn. The left-handed setting swaps the hands.

## The fake pad's device id (Godot knows up to 16 pads; real ones count up from 0) and its name (GamepadRules.QUEST).
const DEVICE := 12
const JOY_NAME := "Meta Quest Touch"
## The tracker inputs each control reads, in order (the OpenXR action map's names first, WebXR's after).
const CONTROLS := {
	"ax": [&"ax_button"],
	"by": [&"by_button"],
	"grip": [&"grip_click", &"grip"],
	"menu": [&"menu_button"],
	"stick_click": [&"primary_click", &"thumbstick_click"],
	"trigger": [&"trigger", &"trigger_click"],
	"stick": [&"primary", &"thumbstick"],
}

## The JoyButton each pressed control sent (its release sends the same one).
var _sent := {}
## Control key -> held (with VrRules.trigger_down's hysteresis for the analog ones).
var _held := {}
var _axes := {}
var _turn_armed := true
var _trigger_held := false
var _classifier := TouchClassifier.new()
var _clock := 0.0
## Radians turned in the last step (tests; the vignette reads a smooth turn).
var turned := 0.0
## Tests: what the trigger acts on instead of the player's BlockInteractor (place_crosshair, break_crosshair,
## show_break_progress, ray_at).
var target: Object = null
## The turning stick's push away this frame (VrTeleport aims while it is up).
var teleport_y := 0.0
## Each hand's trigger as a press (VrRules.trigger_down: on at 0.6, off under 0.35), this frame.
var _pressed := {}


## A hand's trigger is pressed (Vr.trigger_pressed, the lead's frozen name: VR-UI's presses and this side's read it).
func pressed(side: StringName) -> bool:
	return bool(_pressed.get(side, false))
## Haptic pulses asked for (tests).
var buzzes := 0


## One frame (Vr calls it while a session runs; `player` is this game's player in the world, or null).
func step(delta: float, player: Player) -> void:
	_clock += delta
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		_pressed[side] = VrRules.trigger_down(_float(side, "trigger", false), bool(_pressed.get(side, false)))
	var point := Vr.pointing_hand()
	var other := VrRules.LEFT if point == VrRules.RIGHT else VrRules.RIGHT
	var walk := _vector(other) if not Vr.body_waits() else Vector2.ZERO   # owner #110: MODEL VIEW's body waits
	_axis(JOY_AXIS_LEFT_X, walk.x)
	_axis(JOY_AXIS_LEFT_Y, -walk.y)   # a stick pushed away is +y on a tracker, -y on a pad
	var turning := _vector(point)
	teleport_y = turning.y   # P3: pushed away, it aims a teleport (VrTeleport)
	_turn(turning.x if absf(turning.y) < VrRules.TELEPORT_PUSH else 0.0, delta)
	for key: String in GamepadRules.QUEST_BUTTONS:
		var parts := key.split(":")
		var side: StringName = point if parts[0] == "point" else (other if parts[0] == "other" else StringName(parts[0]))
		_button_control(key, side, parts[1], int(GamepadRules.QUEST_BUTTONS[key]), player)
	var squeeze := _float(point, "trigger", _trigger_held)
	if Vr.seated():
		_throttle(squeeze)   # P3: in the rocket's seat the trigger is the throttle (RT, rocket_throttle)
	else:
		_throttle(0.0)
		var busy := Vr.grabber != null and Vr.grabber.busy(point)   # owner #110: a held thing's trigger (its `used`)
		var table: VrBuildTable = Vr.build_table if not busy and is_instance_valid(Vr.build_table) \
			and Vr.build_table.wants_trigger(point) else null
		if table != null:
			_trigger(squeeze, player, false, table)   # owner #110 idea 5: the hand at the Build Table builds there
		elif busy or not _bow(player, point, other):   # P4: a bow in the other hand is drawn with this one
			_trigger(squeeze, player, busy)
		if not busy and table == null:
			_swing(player, point, delta)   # P4: opt-in swings


## Lets go of every button and centres the sticks (the session ends: nothing may stay pressed in the game).
func release_all() -> void:
	for key: String in _sent.keys():
		_send_button(int(_sent[key]), false)
	_sent.clear()
	_held.clear()
	_claimed.clear()
	for axis: int in _axes.keys():
		if float(_axes[axis]) != 0.0:
			_send_axis(axis, 0.0)
	_axes.clear()
	_classifier.cancel()
	_trigger_held = false

# --- Reading the controllers ---

static func _tracker(side: StringName) -> XRPositionalTracker:
	return XRServer.get_tracker(VrRig.tracker_name(side)) as XRPositionalTracker


## A control's value: the first of its tracker inputs that is set, or null.
static func read(side: StringName, control: String) -> Variant:
	var t := _tracker(side)
	if t == null:
		return null
	for n: StringName in CONTROLS.get(control, []):
		var v: Variant = t.get_input(n)
		if v != null:
			return v
	return null


func _vector(side: StringName) -> Vector2:
	var v: Variant = read(side, "stick")
	return v if v is Vector2 else Vector2.ZERO


## A control as 0..1 (a button is 0 or 1).
func _float(side: StringName, control: String, _was: bool) -> float:
	var v: Variant = read(side, control)
	if v is bool:
		return 1.0 if v else 0.0
	return float(v) if v is float or v is int else 0.0

# --- Sending it as a pad ---

func _button_control(key: String, side: StringName, control: String, button: int, player: Player) -> void:
	var was := bool(_held.get(key, false))
	var down := VrRules.trigger_down(_float(side, control, was), was)
	if down == was:
		return
	_held[key] = down
	if control == "grip" and _grip_to_hands(key, side, down):
		return   # owner #110 (R1): the grip took something; the hotbar steps only when nothing is there
	if down and Vr.body_waits() and button != JOY_BUTTON_START and button != JOY_BUTTON_DPAD_RIGHT:
		return   # owner #110: in MODEL VIEW only the menu and MORE (to end it) reach the game
	if down:
		var sent := button
		if GamepadRules.QUEST_FLYING.has(button) and _flying(player) and not PadFocus.menu_has_pad():
			sent = int(GamepadRules.QUEST_FLYING[button])
		_sent[key] = sent
		_send_button(sent, true)
	elif _sent.has(key):
		_send_button(int(_sent[key]), false)
		_sent.erase(key)


## Owner #110 (R1): the grip's press goes to the hands first (VrGrabber.claim: a thing near or under the laser, a brick,
## the Build Table's edge); taken, its release is theirs too. False: the hotbar's step as before.
var _claimed := {}


func _grip_to_hands(key: String, side: StringName, down: bool) -> bool:
	if down:
		if Vr.grabber != null and Vr.grabber.claim(side):
			_claimed[key] = true
			return true
		return false
	if _claimed.has(key):
		_claimed.erase(key)
		if Vr.grabber != null:
			Vr.grabber.let_go(side)
		return true
	return false


static func _flying(player: Player) -> bool:
	return player != null and player.physics_mode != PhysicsMode.Mode.NORMAL


func _axis(axis: int, value: float) -> void:
	var was := float(_axes.get(axis, 0.0))
	if absf(value - was) < 0.01 and not (value == 0.0 and was != 0.0):
		return
	_axes[axis] = value
	_send_axis(axis, value)


func _send_button(button: int, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = DEVICE
	e.button_index = button as JoyButton
	e.pressed = pressed
	e.pressure = 1.0 if pressed else 0.0
	_send(e)


func _send_axis(axis: int, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = DEVICE
	e.axis = axis as JoyAxis
	e.axis_value = value
	_send(e)


## The VR canvas first (a menu there takes a press: the game never sees it), then the game.
static func _send(e: InputEvent) -> void:
	var vp := Vr.ui_viewport()
	if vp != null:
		vp.push_input(e)
		if e.is_pressed() and vp.is_input_handled():
			return
	Input.parse_input_event(e)

# --- VR's own: turning, the trigger ---

func _turn(x: float, delta: float) -> void:
	turned = 0.0
	var degrees := VrRules.snap_degrees(str(Vr.setting(VrRules.TURN)))
	if degrees <= 0.0:
		turned = VrRules.smooth_turn(x, delta)
	else:
		var s := VrRules.snap_step(x, _turn_armed, degrees)
		_turn_armed = s.armed
		turned = float(s.turn)
		if turned != 0.0:
			_buzz(Vr.pointing_hand(), VrRules.HAPTIC_TURN)
	if turned != 0.0:
		Vr.turn(turned)


func _trigger(value: float, player: Player, busy := false, table: Object = null) -> void:
	var interactor: Object = table if table != null else (target if target != null else _interactor(player))
	# owner #110: the Build Table builds with a menu up too (the School's rounds), never in a paused game
	var may := interactor != null and not busy and (not get_tree().paused if table != null else _world_may_act(player))
	var down := VrRules.trigger_down(value, _trigger_held)
	if not may:
		if _classifier.owns(0):
			_classifier.cancel()
			if interactor:
				interactor.show_break_progress(null, -1.0)
		_trigger_held = down
		return
	if down != _trigger_held:
		_trigger_held = down
		if down:
			_classifier.down(0, Vector2.ZERO, _clock)
		elif _classifier.owns(0):
			interactor.show_break_progress(null, -1.0)
			if _classifier.up(0, Vector2.ZERO, _clock) == TouchClassifier.Gesture.TAP:
				_act(interactor, &"place_crosshair", VrRules.HAPTIC_PLACE)
	if _classifier.update(_clock) == TouchClassifier.Gesture.HOLD:
		interactor.show_break_progress(null, -1.0)
		_act(interactor, &"break_crosshair", VrRules.HAPTIC_BREAK)
	elif _classifier.owns(0):
		var progress := _classifier.hold_progress(_clock)
		interactor.show_break_progress(interactor.ray_at(Vector2.ZERO) if progress >= 0.0 else null, progress)


## The trigger's place or break on `interactor`, with its buzz when it was used. VR P5's follow-up (a): the player's
## BlockInteractor runs it in the physics step when the physics has its own thread (BlockInteractor.in_space: its rays
## read the physics space); a test's stand-in at once.
func _act(interactor: Object, method: StringName, pulse: Array) -> void:
	var buzz := func(ok: bool) -> void:
		if ok:
			_buzz(Vr.pointing_hand(), pulse)
	if interactor is BlockInteractor:
		(interactor as BlockInteractor).in_space(Callable(interactor, method), buzz)
	else:
		buzz.call(bool(interactor.call(method)))


# --- P4 (owner #101): the bow drawn with two hands, swings ---

## The bow being drawn, its power now, shots and swings (tests).
var drawing := false
var draw_power := 0.0
var shots := 0
var swings := 0
var _bow_was_down := false
var _swinging := false
var _last_hand := Vector3.INF


## A bow in the hand (it hangs in the other hand: Vr.item_anchor): the pointing hand squeezes its trigger at the bow
## (VrRules.BOW_GRAB) to take the string, pulls back (the farther, the stronger: VrRules.bow_power) and lets go to shoot
## along the string through the bow. True while it has the trigger (no TAP/HOLD then); a squeeze away from the bow is
## the trigger's usual tap (a tap shoots at the laser's point, as before).
func _bow(player: Player, point: StringName, other: StringName) -> bool:
	var interactor := _interactor(player)
	var item := interactor.selected_block() if interactor else 0
	if interactor == null or WeaponRules.base_of(item) != ItemIds.BOW or not _world_may_act(player):
		if drawing:
			drawing = false
			if player:
				player.set_aiming(false)
		_bow_was_down = pressed(point)
		return false
	var string_at := Vr.hand_grip(point).origin
	var bow_at := Vr.hand_grip(other).origin
	var apart := string_at.distance_to(bow_at) / maxf(Vr.world_scale(), 0.01)
	var down := pressed(point)
	if not drawing and down and not _bow_was_down and VrRules.bow_grabs(apart):
		drawing = true
		player.set_aiming(true)
		_buzz(point, VrRules.HAPTIC_PLACE)
	_bow_was_down = down
	if not drawing:
		return false
	draw_power = VrRules.bow_power(apart)
	if down:
		return true
	drawing = false
	player.set_aiming(false)
	if draw_power > 0.05:
		var dir := (bow_at - string_at).normalized()
		if interactor.weapons.attack_towards(item, bow_at + dir * WeaponUser.FAR, draw_power, false, true):   # owner #124: straight
			shots += 1
			_buzz(other, VrRules.HAPTIC_BREAK)
	return true


## Owner #128: a melee weapon held in the pointing hand (a sword, an axe, a mace…) swung fast (in the play space: walking
## never counts) attacks once along the hand's aim, with no button (VrRules.SWING, on by default); empty hands, blocks,
## a bow or a wand are never swung. WeaponUser's cooldown and the host's reach and cone decide, as for the ATTACK button.
func _swing(player: Player, point: StringName, delta: float) -> void:
	if not bool(Vr.setting(VrRules.SWING)) or delta <= 0.0 or not _world_may_act(player) or drawing or Vr.rig == null:
		_swinging = false
		_last_hand = Vector3.INF
		return
	var local := Vr.rig.global_transform.affine_inverse() * Vr.hand_grip(point).origin
	var speed := 0.0
	if _last_hand.is_finite():
		speed = (local - _last_hand).length() / delta / maxf(Vr.world_scale(), 0.01)
	_last_hand = local
	var s := VrRules.swing_step(speed, _swinging)
	_swinging = s.swinging
	if not s.hit:
		return
	var interactor := _interactor(player)
	var weapons := interactor.weapons
	var item := interactor.selected_block()   # owner #128: only the weapon in the hand, never fists or the best one
	if not WeaponRules.is_weapon(item) or WeaponRules.stats(item).get("kind", &"") != WeaponRules.MELEE:
		return
	var ray := Vr.pointer_ray()
	if ray.is_empty():
		return
	if weapons.attack_towards(item, CombatDirector.chest(player) + (ray[1] as Vector3) * 2.0, 1.0):
		swings += 1
		_buzz(point, VrRules.HAPTIC_BREAK)


## The pointing trigger as a pad's right trigger (the rocket's throttle: its action and FlightCockpit read it); 0 lets it
## go when the child leaves the seat.
func _throttle(value: float) -> void:
	_axis(JOY_AXIS_TRIGGER_RIGHT, value)


## The world takes the trigger: a player stands in it, the laser is not over a panel, no menu has the pad, no pause.
func _world_may_act(player: Player) -> bool:
	return player != null and player.is_spawned() and not Vr.ui_wants_pointer() and not PadFocus.menu_has_pad() \
		and not get_tree().paused


static func _interactor(player: Player) -> BlockInteractor:
	return player.get_node_or_null("BlockInteractor") as BlockInteractor if player != null else null


func _buzz(side: StringName, pulse: Array) -> void:
	buzzes += 1
	Vr.haptic(side, float(pulse[0]), float(pulse[1]))
