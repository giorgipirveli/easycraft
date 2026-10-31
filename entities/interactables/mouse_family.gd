class_name MouseFamily
extends SecretThing
## A mouse village's family (M3 Task 21c): two grown-up mice and a little one in the middle of their room, as tall
## as a tiny child. They turn to the nearest child close by and wave, and squeak hello (at most once in a while); a
## tap makes them squeak and hop. Every game animates them itself (nothing is sent). Cheap: two shared meshes (a
## mouse and its waving arm, WeaponModels' one material), looked at four times a second.

const GREET := 5.0                # a child this close is waved at
const LOOK_EVERY := 0.25
const SQUEAK_EVERY := 8000        # ms between hellos
const SIZE := 0.8                 # a grown-up mouse's scale (the little one is smaller)
const SPOTS: Array[Vector3] = [Vector3(-0.34, 0, 0.05), Vector3(0.34, 0, 0.05), Vector3(0, 0, -0.18)]
const SIZES: Array[float] = [1.0, 0.95, 0.62]
const ARM_SHOULDER := Vector3(0.12, 0.34, 0)

const _GREY := Color("9a8f88")
const _GREY_DARK := Color("7a6f69")
const _PINK := Color("ffb3c1")
const _BELLY := Color("eee4d8")
const _DARK := Color("231f20")
const _APRON := Color("e05a7a")
const _SHIRT := Color("4a8fe0")

static var _meshes := {}

## Hellos squeaked so far (tests).
var squeaks := 0

var _body := Node3D.new()
var _mice: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _greeting := false
var _t := 0.0
var _look_t := 0.0
var _last_squeak_ms := -100000
var _hop: Tween


## data = {id, pos, yaw, secret}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(1.2, 0.5, 0.6), Vector3(0, 0.25, 0))
	add_child(_body)
	for i in SPOTS.size():
		var mouse := Node3D.new()
		mouse.position = SPOTS[i]
		mouse.scale = Vector3.ONE * SIZE * SIZES[i]
		_body.add_child(mouse)
		var mi := _mesh(_mouse_mesh(i), mouse)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var arm := Node3D.new()
		arm.position = ARM_SHOULDER
		mouse.add_child(arm)
		_mesh(_arm_mesh(), arm)
		_mice.append(mouse)
		_arms.append(arm)


func mouse_count() -> int:
	return _mice.size()


## The grown-ups' shared mesh (tests: one mesh for every family).
func shared_mesh() -> Mesh:
	return _mouse_mesh(0)


func greeting() -> bool:
	return _greeting


## Turns to the nearest child within GREET and waves; squeaks hello when one comes near (at most every SQUEAK_EVERY).
func look_around() -> void:
	var nearest := GREET
	var target := Vector3.INF
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Node3D
		if p == null or not p.visible:
			continue
		var d := p.global_position.distance_to(global_position)
		if d < nearest:
			nearest = d
			target = p.global_position
	var was := _greeting
	_greeting = target.is_finite()
	if not _greeting:
		return
	var local := to_local(target)
	_body.rotation.y = atan2(-local.x, -local.z)
	var now := Time.get_ticks_msec()
	if not was and now - _last_squeak_ms >= SQUEAK_EVERY:
		_last_squeak_ms = now
		squeaks += 1
		Audio.play(&"mouse_squeak", global_position + Vector3(0, 0.3, 0), -4.0)


## A tap: they squeak and hop.
func use_tap(_hud: Node) -> bool:
	Audio.play(&"mouse_squeak", global_position + Vector3(0, 0.3, 0), -2.0, 1.15)
	if _hop and _hop.is_valid():
		_hop.kill()
	_hop = create_tween()
	_hop.tween_property(_body, "position:y", 0.18, 0.1).set_ease(Tween.EASE_OUT)
	_hop.tween_property(_body, "position:y", 0.0, 0.14).set_ease(Tween.EASE_IN)
	Fx.burst(get_tree().root, global_position + Vector3(0, 0.6, 0), Color("ff6f91"), 6, 1.2, 0.06, 0.7, -0.5)
	return true


func _process(delta: float) -> void:
	_t += delta
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = LOOK_EVERY
		look_around()
	for i in _arms.size():
		var wave := 2.4 + sin(_t * 10.0 + i) * 0.45 if _greeting else 0.12 + sin(_t * 1.8 + i) * 0.05
		_arms[i].rotation.z = lerpf(_arms[i].rotation.z, wave, clampf(8.0 * delta, 0.0, 1.0))
	for i in _mice.size():   # a little bob, each in its own time
		_mice[i].position.y = maxf(sin(_t * 3.0 + i * 1.3), 0.0) * 0.03


## A standing mouse facing -Z: body, belly, head, round ears, eyes, a pink nose and whiskers, a tail; the grown-ups
## wear an apron or a shirt.
static func _mouse_mesh(i: int) -> Mesh:
	var key := "mouse_%d" % mini(i, 2)
	if not _meshes.has(key):
		var clothes: Color = [_APRON, _SHIRT, _GREY][mini(i, 2)]
		var face := -0.092
		_meshes[key] = WeaponModels.build([
			[Vector3(-0.06, 0.06, 0), Vector3(0.08, 0.12, 0.1), _GREY_DARK],   # feet
			[Vector3(0.06, 0.06, 0), Vector3(0.08, 0.12, 0.1), _GREY_DARK],
			[Vector3(0, 0.24, 0), Vector3(0.2, 0.26, 0.15), clothes],
			[Vector3(0, 0.23, -0.078), Vector3(0.12, 0.16, 0.01), _BELLY],
			[Vector3(-0.12, 0.28, 0), Vector3(0.05, 0.16, 0.06), _GREY],        # the arm that stays down
			[Vector3(0, 0.46, 0), Vector3(0.18, 0.18, 0.18), _GREY],            # head
			[Vector3(0, 0.42, -0.12), Vector3(0.08, 0.07, 0.08), _GREY],        # snout
			[Vector3(0, 0.44, -0.165), Vector3(0.04, 0.035, 0.02), _PINK],      # nose
			[Vector3(-0.1, 0.43, -0.13), Vector3(0.06, 0.006, 0.006), _DARK],   # whiskers
			[Vector3(0.1, 0.43, -0.13), Vector3(0.06, 0.006, 0.006), _DARK],
			[Vector3(-0.045, 0.5, face), Vector3(0.035, 0.045, 0.01), _DARK],   # eyes
			[Vector3(0.045, 0.5, face), Vector3(0.035, 0.045, 0.01), _DARK],
			[Vector3(-0.1, 0.6, 0), Vector3(0.1, 0.1, 0.03), _GREY],            # ears
			[Vector3(0.1, 0.6, 0), Vector3(0.1, 0.1, 0.03), _GREY],
			[Vector3(-0.1, 0.6, -0.016), Vector3(0.065, 0.065, 0.01), _PINK],
			[Vector3(0.1, 0.6, -0.016), Vector3(0.065, 0.065, 0.01), _PINK],
			[Vector3(0, 0.1, 0.13), Vector3(0.025, 0.025, 0.14), _PINK],        # tail
			[Vector3(0, 0.14, 0.21), Vector3(0.025, 0.08, 0.025), _PINK],
		])
	return _meshes[key]


## The waving arm, hanging down from the shoulder (it turns about z).
static func _arm_mesh() -> Mesh:
	if not _meshes.has("arm"):
		_meshes["arm"] = WeaponModels.build([
			[Vector3(0, -0.07, 0), Vector3(0.05, 0.14, 0.06), _GREY],
			[Vector3(0, -0.15, 0), Vector3(0.05, 0.04, 0.05), _PINK],
		])
	return _meshes["arm"]
