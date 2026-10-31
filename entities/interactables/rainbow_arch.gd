class_name RainbowArch
extends SecretThing
## A rainbow (owner feedback #42, spec §12.16b): six see-through bands arching TreasureRules.RAINBOW_SPAN
## blocks from its foot (the pot of gold) to its other foot, across the view of the player it came for. One
## shared mesh and material; it fades in by itself (GeometryInstance3D.transparency, no material per
## rainbow). Nothing to tap; it stays whoever is near until the host lets it fade.

const FADE := 2.0                 # seconds to fade in

var _arch: MeshInstance3D
var _t := 0.0


## data = {id, pos (its foot, at the pot), yaw}
func setup(data: Dictionary) -> void:
	_base(data, Vector3.ZERO, Vector3.ZERO)
	stays = true
	_arch = _mesh(TreasureModels.rainbow(TreasureRules.RAINBOW_SPAN))
	_arch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arch.transparency = 1.0


func _process(delta: float) -> void:
	if _t >= FADE:
		return
	_t += delta
	_arch.transparency = clampf(1.0 - _t / FADE, 0.0, 1.0)
