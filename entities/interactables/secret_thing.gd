class_name SecretThing
extends StaticBody3D
## Something a secret brings into the world (M2 Task 16): a treasure chest, a riddle note, a temple's plate
## pictures or the Wanderer. The host's SecretDirector spawns it for everyone near players and removes it
## when nobody is near. At most one small box on its own physics layer, which only tap rays look for:
## players walk through it and it never touches the terrain. Its meshes and materials are shared.

const LAYER := 512                # physics layer 10: secret things (tap rays only)

var secret_id := ""               # the SecretRules id it belongs to ("" for the Wanderer)
## Stays when every player is far (owner 42: a rainbow and its pot are seen from afar and fade by themselves).
var stays := false


## Name, place and turn from the spawn data {id, pos (feet), yaw, secret}; a tap box when box_size isn't zero.
func _base(data: Dictionary, box_size: Vector3, box_center: Vector3) -> void:
	name = str(data.id)
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	secret_id = str(data.get("secret", ""))
	collision_layer = LAYER
	collision_mask = 0
	add_to_group(&"secret_things")
	if box_size != Vector3.ZERO:
		var box := BoxShape3D.new()
		box.size = box_size
		var shape := CollisionShape3D.new()
		shape.shape = box
		shape.position = box_center
		add_child(shape)


## The cell it stands in (its feet).
func cell() -> Vector3i:
	return Vector3i(global_position.floor())


func _mesh(mesh: Mesh, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	parent.add_child(mi)
	return mi
