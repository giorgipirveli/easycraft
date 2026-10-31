class_name Villager
extends Trader
## A villager of the wild meadows (owner feedback #45b, spec §14.18): a friendly blocky villager who stands in a
## village (a spot of MeadowsPlaces), turns to the nearest player and waves, with a name over the head. In Survivor
## it is a Trader in the group "traders": a tap opens Tilly's shop with her rules and prices (the host checks the
## reach to any trader). No collision (players walk past it; taps find it by Trader.find's ray), no stall; shared
## vertex-coloured meshes per look (WeaponModels' one material), made by the PlacesDirector only near players.

const LOOKS := 4
## Shirt, trousers, hair and hat of each look (a straw hat, a cap, none, a flower).
const _SHIRTS: Array[Color] = [Color("3a7be8"), Color("3fbf5f"), Color("f08a24"), Color("d64545")]
const _TROUSERS: Array[Color] = [Color("5a4632"), Color("2e4a5a"), Color("4a4a58"), Color("6e5a3a")]
const _HAIRS: Array[Color] = [Color("6b3e26"), Color("e0b94f"), Color("2b2222"), Color("c4622d")]
const _SKINS: Array[Color] = [Color("f1c27d"), Color("c68642"), Color("ffdbac"), Color("8d5524")]

static var _looks := {}


## data = {pos: Vector3 (its feet), yaw: float (it faces -Z turned by yaw), look: int, name: String, trades: bool}
func setup(data: Dictionary) -> void:
	var look := clampi(int(data.get("look", 0)), 0, LOOKS - 1)
	name = "Villager"
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	if bool(data.get("trades", false)):
		add_to_group(&"traders")
	add_to_group(&"villagers")
	add_child(_body)
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh_of(look, &"body")
	_body.add_child(mi)
	_arm.position = ARM_SHOULDER
	_body.add_child(_arm)
	var arm := MeshInstance3D.new()
	arm.mesh = _mesh_of(look, &"arm")
	_arm.add_child(arm)
	var label := Label3D.new()
	label.text = str(data.get("name", "Villager"))
	label.font_size = 40
	label.outline_size = 10
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.3, 0)
	add_child(label)
	_hint.visible = false   # Tilly's shop arrow: never over a villager
	add_child(_hint)


func is_greeting() -> bool:
	return _greeting


static func _mesh_of(look: int, part: StringName) -> Mesh:
	var key := "%d/%s" % [look, part]
	if not _looks.has(key):
		var shirt := _SHIRTS[look]
		var skin := _SKINS[look]
		if part == &"arm":
			_looks[key] = WeaponModels.build([
				[Vector3(0, -0.26, 0), Vector3(0.18, 0.52, 0.22), shirt],
				[Vector3(0, -0.58, 0), Vector3(0.16, 0.14, 0.2), skin],
			])
		else:
			_looks[key] = WeaponModels.build(_villager_parts(look))
	return _looks[key]


## A blocky villager facing -Z: legs, a shirt, the left arm (the right one waves), a head with a smile, hair and a
## hat by its look.
static func _villager_parts(look: int) -> Array:
	var face := -0.241
	var shirt := _SHIRTS[look]
	var hair := _HAIRS[look]
	var skin := _SKINS[look]
	var dark := Color("1b1b1b")
	var parts: Array = [
		[Vector3(-0.13, 0.3, 0), Vector3(0.24, 0.6, 0.26), _TROUSERS[look]],
		[Vector3(0.13, 0.3, 0), Vector3(0.24, 0.6, 0.26), _TROUSERS[look]],
		[Vector3(0, 0.95, 0), Vector3(0.6, 0.7, 0.32), shirt],
		[Vector3(-0.4, 1.04, 0), Vector3(0.18, 0.52, 0.22), shirt],
		[Vector3(-0.4, 0.72, 0), Vector3(0.16, 0.14, 0.2), skin],
		[Vector3(0, 1.55, 0), Vector3(0.48, 0.48, 0.48), skin],
		[Vector3(0, 1.82, 0.02), Vector3(0.52, 0.12, 0.52), hair],
		[Vector3(0, 1.58, 0.23), Vector3(0.52, 0.4, 0.08), hair],
		[Vector3(-0.1, 1.6, face), Vector3(0.07, 0.09, 0.01), dark],
		[Vector3(0.1, 1.6, face), Vector3(0.07, 0.09, 0.01), dark],
		[Vector3(0, 1.46, face), Vector3(0.18, 0.04, 0.01), dark],
		[Vector3(-0.17, 1.5, face), Vector3(0.06, 0.04, 0.01), Color("ff9aa2")],
		[Vector3(0.17, 1.5, face), Vector3(0.06, 0.04, 0.01), Color("ff9aa2")],
	]
	match look:
		0:   # a straw hat
			parts.append([Vector3(0, 1.9, 0), Vector3(0.78, 0.04, 0.78), Color("e8c872")])
			parts.append([Vector3(0, 1.98, 0), Vector3(0.5, 0.14, 0.5), Color("e8c872")])
		1:   # a cap with a peak
			parts.append([Vector3(0, 1.88, 0), Vector3(0.54, 0.1, 0.54), Color("3fbf5f")])
			parts.append([Vector3(0, 1.85, -0.34), Vector3(0.4, 0.04, 0.2), Color("2e8a44")])
		3:   # a flower in the hair
			parts.append([Vector3(0.2, 1.86, -0.1), Vector3(0.12, 0.12, 0.12), Color("ffd23f")])
	return parts
