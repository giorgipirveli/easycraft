class_name TreasureChest
extends SecretThing
## A treasure chest (M2 Task 16, spec §12.16). Opening it goes through Session.request_open_chest and the
## host decides: within reach, once per world, and a temple's chest only once its plates are solved. An
## unopened chest glows in the rarity colour of its best loot (§13.2); a sky island's chest is golden.
## `opened` and `locked` are synced to every peer.

const OPEN_ANGLE := -1.9          # radians the lid swings back
const PULSE := 1.1                # glow pulses per second

var chest_kind: StringName = &"buried"
var rarity := LootRules.COMMON
var golden := false
var locked := false
var opened := false:
	set(value):
		opened = value
		_show_state()

var _lid := Node3D.new()
var _glow: MeshInstance3D
var _swing: Tween
var _t := 0.0


## data = {id, pos, yaw, secret, chest_kind, rarity, golden, opened, locked}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(0.8, 0.7, 0.55), Vector3(0, 0.33, 0))
	chest_kind = StringName(data.get("chest_kind", "buried"))
	rarity = int(data.get("rarity", 0))
	golden = bool(data.get("golden", false))
	locked = bool(data.get("locked", false))
	_mesh(InteractableModels.chest_base(golden))
	_lid.position = InteractableModels.LID_PIVOT
	add_child(_lid)
	_mesh(InteractableModels.chest_lid(golden), _lid)
	TreasureModels.dress(self, chest_kind)   # owner 42: a loot cart's wheels
	if chest_kind == MouseVillages.CHEST_KIND:
		scale = Vector3.ONE * MouseVillages.CHEST_SCALE   # M3 Task 21c: the mice's tiny chest
	_glow = _mesh(InteractableModels.glow_quad())
	_glow.material_override = InteractableModels.glow_material(rarity)
	_glow.position = Vector3(0, 0.4, 0)
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	opened = bool(data.get("opened", false))
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	for prop in [".:opened", ".:locked"]:
		cfg.add_property(NodePath(prop))
		cfg.property_set_replication_mode(NodePath(prop), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


## Everyone sees it open: the lid swings back and treasure sparkles out in the rarity's colour. The host
## calls it before setting `opened`, so the lid swings instead of snapping open.
@rpc("authority", "call_local", "reliable")
func play_open() -> void:
	_glow.visible = false
	if not is_inside_tree():
		_lid.rotation.x = OPEN_ANGLE
		return
	if not (_swing and _swing.is_valid()):
		_swing = create_tween()
		_swing.tween_property(_lid, "rotation:x", OPEN_ANGLE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var top := global_position + Vector3(0, 0.6, 0)
	Fx.burst(get_tree().root, top, LootRules.rarity_color(rarity), 26, 5.0, 0.12, 1.0, 5.0)
	Fx.burst(get_tree().root, top, Color("ffd23f"), 18, 3.5, 0.09, 1.2, 3.0)
	Audio.play(&"chest_open", top)


## An opened chest has no glow and an open lid (snapped open when it was not seen opening: spawned open
## after a reload, or synced to a late joiner).
func _show_state() -> void:
	if _glow == null:
		return
	_glow.visible = not opened
	if opened and not (_swing and _swing.is_valid()):
		_lid.rotation.x = OPEN_ANGLE


func lid_angle() -> float:
	return _lid.rotation.x


func _process(delta: float) -> void:
	if opened or _glow == null:
		return
	_t += delta
	var s := 1.0 + 0.12 * sin(_t * PULSE * TAU)
	_glow.scale = Vector3(s, s, s)
