class_name LeafAvatar
extends Node3D
## Owner #133, #134 (docs/design/games/leaf-voyage.md §4.4 flat; the B2 brief): the child inside the leaf, tiny (the
## child's own blocky avatar, their look from the profile; one look for both graphics styles in phase B, ruling 15),
## flown by LeafVoyageHost: a tap glides it to a thing (`glide_to`, at most GLIDE_MAX s, eased), keys and a game
## controller fly it (`fly`). It carries up to MAX_CARRY sugars as a little stack on its back (`set_carried`).

const HEIGHT := 1.5
const MAX_CARRY := 3
## Seconds per metre of a glide (a short hop is quick), clamped to the host's limit.
const PER_METRE := 0.2

var body: BlockyAvatar
var carried := 0
var _sugars: MultiMeshInstance3D
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _yaw_from := 0.0
var _yaw_to := 0.0
var _t := -1.0
var _time := 1.0
var _speed := 0.0


func _init() -> void:
	name = "LeafAvatar"


func _ready() -> void:
	body = BlockyAvatar.new()
	body.scale = Vector3.ONE * (HEIGHT / 1.8)
	body.rotation.y = PI   # the model faces -Z; the avatar's yaw 0 faces +Z
	add_child(body)
	if Profile.data.avatar != null:
		body.apply_look(Profile.data.avatar)
	var m := LeafKit.Mesher.new()
	m.hexagon(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.16, 0.07, Color("ffe47a"), Color("f0b830"))
	_sugars = LeafKit.multimesh(self, "Carried", m.commit(), LeafKit.glow(), MAX_CARRY,
		AABB(Vector3(-0.6, 0, -0.6), Vector3(1.2, 2.4, 1.2)))
	set_carried(carried)


## Glides to stand at `feet` facing `yaw` (radians: 0 faces +Z) within `limit` seconds; returns how long it takes.
func glide_to(feet: Vector3, yaw: float, limit: float) -> float:
	_from = global_position
	_to = feet
	_yaw_from = rotation.y
	_yaw_to = yaw if not is_nan(yaw) else rotation.y
	_time = clampf(_from.distance_to(feet) * PER_METRE, 0.0, limit)
	_t = 0.0
	if _time <= 0.0:
		_arrive()
	return _time


func gliding() -> bool:
	return _t >= 0.0


## Flies by `velocity` (world, m/s) for `dt` s (keys, a game controller), facing where it goes.
func fly(velocity: Vector3, dt: float) -> void:
	_t = -1.0
	global_position += velocity * dt
	var flat := Vector2(velocity.x, velocity.z)
	if flat.length() > 0.2:
		rotation.y = atan2(flat.x, flat.y)
	_speed = velocity.length()


func step(dt: float) -> void:
	if _t >= 0.0:
		_t += dt
		var k := smoothstep(0.0, 1.0, clampf(_t / maxf(_time, 0.001), 0.0, 1.0))
		global_position = _from.lerp(_to, k)
		rotation.y = lerp_angle(_yaw_from, _yaw_to, k)
		_speed = _from.distance_to(_to) / maxf(_time, 0.001)
		if _t >= _time:
			_arrive()
	if body != null:
		body.animate(_speed, true, dt)
	_speed = move_toward(_speed, 0.0, 8.0 * dt)


## The eyes (world): the first-person camera's place.
func eyes() -> Vector3:
	return global_position + global_basis.y * HEIGHT * 0.88


## Shows `n` sugars on the back (0-MAX_CARRY).
func set_carried(n: int) -> void:
	carried = clampi(n, 0, MAX_CARRY)
	if _sugars == null:
		return
	for i in MAX_CARRY:
		if i < carried:
			_sugars.multimesh.set_instance_transform(i, Transform3D(Basis(),
				Vector3(0, HEIGHT * 0.52 + i * 0.09, -0.2)))
		else:
			_sugars.multimesh.set_instance_transform(i, LeafKit.hidden())


func _arrive() -> void:
	global_position = _to
	rotation.y = _yaw_to
	_t = -1.0
