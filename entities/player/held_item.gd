class_name HeldItem
extends Node3D
## The weapon or tool in the avatar's hand (M1b Task 11). It hangs under the avatar's hand() node:
## the grip sits at the hand's origin and the item points along the hand's -Z. Attack and draw
## animations move the item around the hand, so they work with any avatar (box-built arms or a
## skeleton's bone attachment). An avatar that also swings its arm (BlockyAvatar.play_attack) asks
## for a smaller wrist motion (arm_helps = true) so the two add up to one swing.
## M2 Task 6: tier items look like their kind (WeaponModels) in their tier's material; shields are
## held too; the spear's thrust pushes the item forward along the hand's -Z.

## Keyframes per attack: [pitch, yaw, seconds] relative to the hand; pitch > 0 raises the tip. An
## optional 4th value pushes the item forward (m) and is never scaled by the arm's share.
const SWINGS := {
	&"thrust": [[0.0, 0.0, 0.06, -0.08], [0.0, 0.0, 0.08, 0.55], [0.0, 0.0, 0.2, 0.0]],
	&"slash": [[1.4, 0.0, 0.08], [-0.9, 0.0, 0.1], [0.0, 0.0, 0.16]],
	&"sweep": [[0.2, 1.3, 0.07], [0.2, -1.3, 0.12], [0.0, 0.0, 0.15]],
	&"spin": [[0.3, 0.0, 0.05], [0.3, 0.0, 0.25], [0.0, 0.0, 0.12]],
	&"smash": [[1.7, 0.0, 0.32], [-1.1, 0.0, 0.09], [-1.1, 0.0, 0.12], [0.0, 0.0, 0.2]],
	&"chop": [[1.3, 0.3, 0.12], [-0.7, -0.1, 0.1], [0.0, 0.0, 0.16]],
	&"pick": [[1.5, 0.0, 0.08], [-0.8, 0.0, 0.08], [0.0, 0.0, 0.14]],
	&"throw": [[-1.2, 0.0, 0.1], [1.0, 0.0, 0.08], [0.0, 0.0, 0.15]],
	&"shoot": [[0.15, 0.0, 0.04], [0.0, 0.0, 0.12]],
	&"blast": [[0.3, 0.0, 0.04, -0.1], [0.0, 0.0, 0.14, 0.0]],   # M3 Task 14b: a blaster's kick
}
const ARM_SHARE := 0.35        # of the motion, when the avatar's arm does the rest
const BOW_REST_PITCH := PI / 2.0   # an idle bow hangs along the arm

var item_id := 0
var thrown := false             # a boomerang or spear in flight is not in the hand
## Invisibility potion (M2 Task 6): the item turns see-through with its holder.
var ghost := false:
	set(value):
		ghost = value
		_apply_material()
var _mesh := MeshInstance3D.new()
var _swing: Tween
var _pitch := 0.0
var _yaw := 0.0
var _aim := 0.0
var _aiming := false
var _arm_aims := false
var _push := 0.0
var _base := 0


func _ready() -> void:
	add_child(_mesh)


## Shows a weapon's or shield's model, or nothing for anything else (blocks, the wand, stamps).
func show_item(id: int) -> void:
	item_id = id
	_base = WeaponRules.base_of(id)
	_mesh.mesh = WeaponModels.mesh_for(id) if WeaponRules.is_holdable(id) else null
	_apply_material()
	visible = _mesh.mesh != null
	_pitch = 0.0
	_yaw = 0.0
	_push = 0.0
	if _swing and _swing.is_valid():
		_swing.kill()


## The attack animation of a weapon (combo: the sword's swing number).
func play_attack(weapon_id: int, combo: int = 0, arm_helps: bool = false) -> void:
	var swing := swing_name(weapon_id, combo)
	var keys: Array = SWINGS.get(swing, [])
	if keys.is_empty() or not is_inside_tree():
		return
	if _swing and _swing.is_valid():
		_swing.kill()
	var share := ARM_SHARE if arm_helps and swing != &"blast" else 1.0   # a blaster's kick is the hand's alone (M3 Task 14b)
	_swing = create_tween()
	for k: Array in keys:
		_swing.tween_property(self, "_pitch", float(k[0]) * share, k[2]).set_trans(Tween.TRANS_SINE)
		_swing.parallel().tween_property(self, "_yaw", float(k[1]) * share, k[2]).set_trans(Tween.TRANS_SINE)
		if k.size() > 3:
			_swing.parallel().tween_property(self, "_push", float(k[3]), k[2]).set_trans(Tween.TRANS_SINE)


## Bow drawn (true) or relaxed. arm_helps: the avatar raises its arms itself.
func set_aiming(on: bool, arm_helps: bool = false) -> void:
	_aiming = on
	_arm_aims = arm_helps


static func swing_name(weapon_id: int, combo: int) -> StringName:
	if BlasterRules.is_blaster(weapon_id):
		return &"blast"   # M3 Task 14b
	match WeaponRules.base_of(weapon_id):
		ItemIds.SWORD:
			return [&"slash", &"sweep", &"spin"][clampi(combo, 0, 2)]
		ItemIds.HAMMER, ItemIds.MACE:
			return &"smash"
		ItemIds.SPEAR:
			return &"throw" if combo == WeaponRules.THROW else &"thrust"
		ItemIds.AXE:
			return &"chop"
		ItemIds.PICKAXE:
			return &"pick"
		ItemIds.BOOMERANG:
			return &"throw"
		ItemIds.BOW:
			return &"shoot"
		WeaponRules.FISTS:
			return &"punch"            # owner feedback #29: no item in the hand, only the arm moves
	return &""


func _process(delta: float) -> void:
	visible = _mesh.mesh != null and not thrown
	_aim = move_toward(_aim, 1.0 if _aiming else 0.0, delta * 8.0)
	var bow := _base == ItemIds.BOW
	var rest := BOW_REST_PITCH if bow else 0.0
	if bow and _arm_aims:
		rest = lerpf(BOW_REST_PITCH, 0.0, _aim)    # the raised arm already holds it upright
	rotation = Vector3(rest + _pitch, _yaw, 0.0)
	position = Vector3(0.0, 0.0, -_push)


## The tier's shared material (none for wood), or the see-through ghost look while invisible.
func _apply_material() -> void:
	var tier := WeaponRules.tier_of(item_id)
	if ghost:
		_mesh.material_override = Player.ghost_material()
	else:
		_mesh.material_override = WeaponModels.tier_material(tier) if tier > WeaponRules.TIER_WOOD else null
