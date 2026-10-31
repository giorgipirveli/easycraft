class_name PotOfGold
extends SecretThing
## The pot of gold at a rainbow's end (owner feedback #42, spec §12.16b). Walking up to it is enough: the host
## (TreasureDirector) gives each player its fixed pile of gold once per rainbow. It glows gold, stays while
## its rainbow shows (whoever is near) and goes with it.

const PULSE := 0.9

var rainbow := 0                  # its rainbow's number

var _glow: MeshInstance3D
var _t := 0.0


## data = {id, pos (feet), n}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0))
	stays = true
	rainbow = int(data.get("n", 0))
	_mesh(TreasureModels.pot())
	_glow = _mesh(InteractableModels.glow_quad())
	_glow.material_override = InteractableModels.glow_material(ItemRarity.LEGENDARY)
	_glow.position = Vector3(0, 0.5, 0)
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	_t += delta
	var s := 1.0 + 0.15 * sin(_t * PULSE * TAU)
	_glow.scale = Vector3(s, s, s)
