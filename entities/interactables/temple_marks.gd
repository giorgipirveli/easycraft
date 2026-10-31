class_name TempleMarks
extends SecretThing
## The pictures painted on a puzzle temple's three pressure plates (M2 Task 16): a sun, a moon and a star,
## for children who can't read yet. One shared quad and one shared material per picture (Pictures). The
## node sits at the temple's middle plate; its yaw turns the pictures upright for someone walking in.

const LIFT := 0.01                # above the plate's top


## data = {id, pos (the middle plate's cell corner), yaw, secret, plates: Array[Vector3i], symbols: Array}
func setup(data: Dictionary) -> void:
	_base(data, Vector3.ZERO, Vector3.ZERO)
	var plates: Array = data.get("plates", [])
	var symbols: Array = data.get("symbols", [])
	for i in mini(plates.size(), symbols.size()):
		var cell: Vector3i = plates[i]
		var mi := MeshInstance3D.new()
		mi.mesh = InteractableModels.picture_quad()
		mi.material_override = Pictures.material(int(symbols[i]))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.top_level = true   # its position is a world position: the plate's top
		mi.position = Vector3(cell) + Vector3(0.5, BlockLibrary.PLATE_HEIGHT + LIFT, 0.5)
		mi.rotation.y = rotation.y
