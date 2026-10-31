class_name Scene3DEffects
extends MultiMeshInstance3D
## The Reel Studio (owner #96, spec §5.12b): one effect of a 3D stage (StudioParticles: a flame, smoke, dust, billows,
## sparkles, steam, snow) as ONE multimesh of little boxes, set to exactly the particles alive at the stage's time (a
## seek shows the frame playing reaches), its buffer written in one go. The game's own looks, laid out like a
## CPUParticles3D's multimesh (colours and custom data), so no new shader: a flame, billows and sparkles are the golem's
## glow (the rocket flight's flame), the rest Fx's particles. No shadows; a fixed box, nothing recomputed. A local
## effect rides with its anchor (a rocket's engines).

var effect: Dictionary
## anchor(t) -> Transform3D: where the effect comes from (Scene3DModels.Built.anchor, or its `at` in the world).
var anchor: Callable

var _buf := PackedFloat32Array()
var _anchors := {}

static var _unit_glow: BoxMesh
static var _unit_fx: BoxMesh


func _init(e: Dictionary, anchor_at: Callable) -> void:
	effect = e
	anchor = anchor_at
	name = "Effect_" + str(e.get("kind", ""))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true   # CPUParticles3D's own layout: the same instanced draw, no new shader variant
	mm.mesh = unit_box(bool(StudioParticles.look(e).glow))
	mm.instance_count = StudioParticles.amount(e)
	mm.custom_aabb = AABB(-Vector3.ONE * StudioRules.REACH, Vector3.ONE * StudioRules.REACH * 2.0)
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_buf.resize(mm.instance_count * StudioParticles.STRIDE)
	visible = false


## A unit box in the glow (unshaded) or Fx's (lit) particle material, shared.
static func unit_box(glow: bool) -> BoxMesh:
	if glow:
		if _unit_glow == null:
			_unit_glow = BoxMesh.new()
			_unit_glow.size = Vector3.ONE
			_unit_glow.material = GolemModels.glow_material()
		return _unit_glow
	if _unit_fx == null:
		_unit_fx = BoxMesh.new()
		_unit_fx.size = Vector3.ONE
		_unit_fx.material = Fx.material()
	return _unit_fx


## The particles at `t`.
func pose(t: float) -> void:
	var n := StudioParticles.fill(effect, t, anchor, _buf, _anchors)
	visible = n > 0
	if not visible:
		return
	transform = anchor.call(t) if StudioParticles.is_local(effect) else Transform3D.IDENTITY
	multimesh.visible_instance_count = n
	multimesh.buffer = _buf


## How many particles show now (tests).
func shown() -> int:
	return multimesh.visible_instance_count if visible else 0
