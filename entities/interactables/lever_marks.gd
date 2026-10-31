class_name LeverMarks
extends SecretThing
## The pictures painted over a dungeon vault's three levers (owner feedback #42): a key, a crown and a gem,
## for children who can't read yet; the vault's note draws them in the order to flip the levers. One shared
## quad and one shared material per picture (Pictures), standing on the wall above each lever and facing
## into the hall.

const FROM_WALL := 0.52           # from the lever's cell middle to just in front of its wall face


## data = {id, pos (the first lever's cell), secret, levers: Array[Vector3i], symbols: Array, side: Vector3i
## (from the levers' wall into the hall)}
func setup(data: Dictionary) -> void:
	_base(data, Vector3.ZERO, Vector3.ZERO)
	var levers: Array = data.get("levers", [])
	var symbols: Array = data.get("symbols", [])
	var side: Vector3i = data.get("side", Vector3i(1, 0, 0))
	for i in mini(levers.size(), symbols.size()):
		var cell: Vector3i = levers[i]
		var mi := MeshInstance3D.new()
		mi.mesh = TreasureModels.picture_sign()
		mi.material_override = Pictures.material(int(symbols[i]))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.top_level = true   # a world position: on the wall above the lever
		mi.position = Vector3(cell) + Vector3(0.5, 1.5, 0.5) + Vector3(side) * FROM_WALL
		mi.rotation.y = atan2(float(side.x), float(side.z))
