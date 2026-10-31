extends Node
## Game feel on this device (M2 spec §12.10): Feel.shake(metres, seconds) wobbles the local camera
## (CameraRig), Feel.vibrate(ms) buzzes an Android phone, Feel.flash(alpha) tints the screen's
## edges red for a moment, Feel.slam(distance) is the Stone Golem's slam (Task 10). When this device's
## player is hurt (Session.player_hurt) it plays all three, bigger on a knock-out (FeelRules).
## Settings: Vibration (buzz and shake, default ON) and Reduce motion (no shake or camera bob, softer
## flashes, default OFF; anything else that moves the view checks motion_allowed()). Never more than
## 3 flashes a second. Everything here is local: nothing is sent over the network.

const FLASH_COLOR := Color(1.0, 0.16, 0.1)
const FLASH_LAYER := 90           # above the HUD and the pause menu

## Flashes started since the game began (tests and diagnostics).
var flashes := 0

var _clock := 0.0
var _last_flash := -INF
var _flash_peak := 0.0
var _flash_time := 0.0
var _flash_elapsed := 0.0
var _layer := CanvasLayer.new()
var _edges := TextureRect.new()
var _player_id := 0               # the local Player node whose hearts _last_hp follows
var _last_hp := Health.MAX_HP


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.layer = FLASH_LAYER
	add_child(_layer)
	_edges.name = "HurtFlash"
	_edges.texture = _edge_texture()
	_edges.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_edges.stretch_mode = TextureRect.STRETCH_SCALE
	_edges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edges.modulate = Color(FLASH_COLOR, 0.0)
	_edges.visible = false
	_layer.add_child(_edges)
	_edges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Session.player_hurt.connect(_on_player_hurt)


## False with Reduce motion on: no screen shake and no camera bob. Owner #101: false in VR too (a headset never moves the
## view by itself: everything that checks this takes its calm way).
func motion_allowed() -> bool:
	return not bool(Profile.data.settings.get("reduce_motion", false)) and not Vr.active()


func shake(strength: float, seconds: float) -> void:
	if Vr.active():
		return   # owner #101: never a camera move the child did not make (the buzz and the sound stay)
	var s := Profile.data.settings
	if not FeelRules.can_shake(bool(s.get("vibration", true)), bool(s.get("reduce_motion", false))):
		return
	var rig := _local_rig()
	if rig:
		rig.shake(strength, seconds)


func vibrate(ms: int) -> void:
	if Vr.active():
		_vr_buzz(ms)
		return
	var buzz := buzz_ms(ms)
	if buzz > 0:
		Input.vibrate_handheld(buzz)


## Owner #101: in VR a buzz is both controllers' (the Vibration setting still turns it off).
const VR_BUZZ := 0.6


func _vr_buzz(ms: int) -> void:
	if ms <= 0 or not bool(Profile.data.settings.get("vibration", true)):
		return
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		Vr.haptic(side, VR_BUZZ, ms / 1000.0)


## How long vibrate(ms) buzzes here: 0 where the device can't (M7: PlatformRules.can_vibrate, Android phones in the game
## and in the browser) or the child turned vibration off.
func buzz_ms(ms: int) -> int:
	return FeelRules.vibration_ms(ms, bool(Profile.data.settings.get("vibration", true)),
		PlatformRules.can_vibrate(PlatformRules.current()))


## A red tint at the screen's edges that fades out; softer with Reduce motion; ignored when the last
## flash started less than FeelRules.MIN_FLASH_INTERVAL ago.
func flash(alpha: float) -> void:
	if alpha <= 0.0 or not FeelRules.can_flash(_clock, _last_flash):
		return
	var reduce := not motion_allowed()
	_last_flash = _clock
	_flash_peak = FeelRules.flash_alpha(alpha, reduce)
	_flash_time = FeelRules.flash_time(reduce)
	_flash_elapsed = 0.0
	flashes += 1
	_show_flash()


## The Golem's slam, felt by this device's player `distance` blocks away (FeelRules.slam_feel).
func slam(distance: float) -> void:
	var f := FeelRules.slam_feel(distance)
	if not f.is_empty():
		shake(f.shake, f.seconds)
		vibrate(f.buzz_ms)


func flash_alpha() -> float:
	return _edges.modulate.a


func flash_visible() -> bool:
	return _edges.visible


func flash_overlay() -> Control:
	return _edges


## Stops a flash at once and forgets the hearts (tests).
func reset() -> void:
	_last_flash = -INF
	_flash_time = 0.0
	_flash_peak = 0.0
	flashes = 0
	_player_id = 0
	_last_hp = Health.MAX_HP
	_show_flash()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_clock += delta
	if _flash_time > 0.0:
		_flash_elapsed += delta
		_show_flash()
		if _flash_elapsed >= _flash_time:
			_flash_time = 0.0


func _show_flash() -> void:
	var a := FeelRules.flash_alpha_at(_flash_peak, _flash_elapsed, _flash_time)
	_edges.modulate.a = a
	_edges.visible = a > 0.0 and not Vr.active()   # an invisible full-screen overlay would still cost fill rate
	if Vr.active():
		Vr.tint(Color(FLASH_COLOR, a * VrRules.TINT_MAX))   # owner #101: a faint red tint over the headset's view


## Only this device's player; a heal, regeneration or respawn (hearts up) is not felt. A new world
## has a new Player node, whose hearts start full.
func _on_player_hurt(peer_id: int, hp: int, _from: Vector3) -> void:
	if peer_id != multiplayer.get_unique_id():
		return
	var player := _local_player()
	var id := player.get_instance_id() if player else 0
	if id != _player_id:
		_player_id = id
		_last_hp = Health.MAX_HP
	var f := FeelRules.hurt_feel(_last_hp, hp)
	_last_hp = hp
	if f.is_empty():
		return
	shake(f.shake, f.seconds)
	vibrate(f.buzz_ms)
	flash(f.flash)


func _local_player() -> Node:
	for p in get_tree().get_nodes_in_group(&"players"):
		if p.get("is_local") == true:
			return p
	return null


## The rig of the camera this device looks through (none in the menu).
func _local_rig() -> CameraRig:
	var n: Node = get_viewport().get_camera_3d()
	for i in 4:
		if n == null or n is CameraRig:
			break
		n = n.get_parent()
	return n as CameraRig


## Clear in the middle, red towards the edges and corners.
static func _edge_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 1)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.15, 0.5)
	t.width = 64
	t.height = 64
	return t
