class_name GiftBottle
extends SecretThing
## A friend's bottle (M4 Wave 3, agent I; research D5): it floats on the water near where the child
## started playing (or lies on the beach), bobbing, with a little note inside; a tap opens it
## (SecretTaps: whatever is in the hand). Only this child's game has it (it is for this player alone),
## so it never goes over the network. Its meshes and materials are shared by every bottle.

signal tapped_open(bottle: GiftBottle)

var bottle_id := ""
var from := ""
var floating := true

var _t := 0.0
var _base_y := 0.0
var _body := Node3D.new()

static var _glass: CylinderMesh
static var _cork: CylinderMesh
static var _note: BoxMesh


## {id, from, pos, floating}: a tap box around the bottle on the secret things' layer (tap rays only).
func setup(data: Dictionary) -> void:
	bottle_id = str(data.id)
	from = str(data.get("from", ""))
	floating = bool(data.get("floating", true))
	name = "Bottle_" + bottle_id.validate_node_name()
	position = data.pos
	_base_y = position.y
	collision_layer = LAYER
	collision_mask = 0
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.9, 0.9)
	var shape := CollisionShape3D.new()
	shape.shape = box
	add_child(shape)
	add_child(_body)
	_meshes()
	var glass := MeshInstance3D.new()
	glass.mesh = _glass
	glass.rotation.z = PI / 2.0 if floating else PI / 2.2
	_body.add_child(glass)
	var cork := MeshInstance3D.new()
	cork.mesh = _cork
	cork.position = Vector3(0.36, 0.0, 0.0)
	cork.rotation.z = PI / 2.0
	_body.add_child(cork)
	var note := MeshInstance3D.new()
	note.mesh = _note
	_body.add_child(note)


## The tap (SecretTaps.use): the bottle asks to be opened.
func tapped() -> bool:
	tapped_open.emit(self)
	return true


func _process(delta: float) -> void:
	_t += delta
	if floating:
		position.y = _base_y + sin(_t * 2.0) * 0.08
		_body.rotation.x = sin(_t * 1.3) * 0.18
	_body.rotation.y += delta * 0.4


static func _meshes() -> void:
	if _glass != null:
		return
	_glass = CylinderMesh.new()
	_glass.top_radius = 0.1
	_glass.bottom_radius = 0.16
	_glass.height = 0.6
	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.55, 0.9, 0.75, 0.55)
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.roughness = 0.1
	_glass.material = g
	_cork = CylinderMesh.new()
	_cork.top_radius = 0.09
	_cork.bottom_radius = 0.09
	_cork.height = 0.12
	var c := StandardMaterial3D.new()
	c.albedo_color = Color("9a6a3c")
	_cork.material = c
	_note = BoxMesh.new()
	_note.size = Vector3(0.3, 0.08, 0.12)
	var n := StandardMaterial3D.new()
	n.albedo_color = Color("fff4d6")
	_note.material = n
