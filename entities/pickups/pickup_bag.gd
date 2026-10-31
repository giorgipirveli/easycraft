class_name PickupBag
extends StaticBody3D
## A pickup bag (M2 Task 2, spec §12.3): the blocks a knocked-out Survivor player carried, glowing on
## the ground where they fell. The host spawns it for everyone (KnockoutDirector's MultiplayerSpawner),
## keeps what is in it and saves it with the world; a tap within reach asks the host to take it
## (KnockoutRules: the owner's for 5 minutes, then anyone's). Every bag shares one merged mesh and one
## glowing material (never per-bag resources), and one small box on the tap-only layer that practice
## targets use: static, mask 0, so nothing walks into it and only tap rays find it.

const LAYER := PracticeTarget.LAYER
const BOB_HEIGHT := 0.07
const BOB_SPEED := 2.2            # radians per second
const SPIN_SPEED := 0.7
const LIFT := 0.08                # the bag floats a little over the ground
const GLOW := Color(1.0, 0.72, 0.28)

static var _mesh: ArrayMesh
static var _material: StandardMaterial3D
static var _shape: BoxShape3D

var owner_name := ""              # "" = anyone's
## Host: what is in it, [[block id, count], ...] (KnockoutRules).
var items: Array = []
var _born := 0.0                  # host clock (seconds) when its age was 0
var _visual := MeshInstance3D.new()
var _t := 0.0


## data = {id: String, pos: Vector3 (bottom centre), owner: String, items: Array, age: float}
func setup(data: Dictionary) -> void:
	name = str(data.id)
	position = data.pos
	owner_name = str(data.get("owner", ""))
	items = KnockoutRules.clean_items(data.get("items", []))
	set_age(float(data.get("age", 0.0)))
	collision_layer = LAYER
	collision_mask = 0
	add_to_group(&"bags")
	_visual.mesh = mesh()
	_visual.position.y = LIFT
	add_child(_visual)
	var box := CollisionShape3D.new()
	box.shape = shape()
	box.position.y = 0.3
	add_child(box)
	_t = randf() * TAU   # bags side by side don't bob in step


## Seconds since the bag was dropped (it counts on in a restored world).
func age() -> float:
	return _now() - _born


func set_age(seconds: float) -> void:
	_born = _now() - maxf(seconds, 0.0) if is_finite(seconds) else _now()


func center() -> Vector3:
	return global_position + Vector3(0, 0.3, 0)


## For WorldMeta.bags.
func to_save() -> Dictionary:
	return {"owner": owner_name, "pos": [global_position.x, global_position.y, global_position.z],
		"items": items.duplicate(true), "age": age()}


func _process(delta: float) -> void:
	_t += delta
	_visual.position.y = LIFT + BOB_HEIGHT * (1.0 + sin(_t * BOB_SPEED))
	_visual.rotation.y = _t * SPIN_SPEED


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## The one bag mesh: a round-ish sack with a gold tie and a star patch, vertex coloured.
static func mesh() -> ArrayMesh:
	if _mesh == null:
		var sack := Color("b9823f")
		var dark := Color("8a5a26")
		var gold := Color("ffd23f")
		_mesh = WeaponModels.build([
			[Vector3(0, 0.17, 0), Vector3(0.44, 0.3, 0.44), sack],
			[Vector3(0, 0.19, 0), Vector3(0.5, 0.2, 0.36), sack],
			[Vector3(0, 0.19, 0), Vector3(0.36, 0.2, 0.5), sack],
			[Vector3(0, 0.36, 0), Vector3(0.24, 0.08, 0.24), dark],
			[Vector3(0, 0.41, 0), Vector3(0.28, 0.04, 0.28), gold],
			[Vector3(0, 0.47, 0), Vector3(0.18, 0.08, 0.18), dark],
			[Vector3(0, 0.2, -0.255), Vector3(0.14, 0.14, 0.02), gold],
		])
		_mesh.surface_set_material(0, material())
	return _mesh


## The one glowing material every bag shares.
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.7
		_material.emission_enabled = true
		_material.emission = GLOW
		_material.emission_energy_multiplier = 0.55
	return _material


static func shape() -> BoxShape3D:
	if _shape == null:
		_shape = BoxShape3D.new()
		_shape.size = Vector3(0.6, 0.6, 0.6)
	return _shape
