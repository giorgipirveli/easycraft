class_name Fireflies
extends CPUParticles3D
## Owner #94 (the animations brief §2): a few fireflies drifting and blinking round this game's player over the meadow
## at night (LifeRules.fireflies_on). ONE particle system in the world's space: tiny boxes with the golem's glow (its
## unshaded vertex colours, drawn instanced like the rocket's flame: no new shader), each one blinking on and off
## (its size's curve), 30 fps, no shadows. Off until the night says so. Nothing is sent.

const AREA := Vector3(7.0, 0.7, 7.0)
const HEIGHT := 0.9
const LIFETIME := 4.0
const COLORS: Array[Color] = [Color("d8ff6a"), Color("f5ff8a"), Color("b8ff5a"), Color("fff27a")]

static var _box: BoxMesh
static var _blink: Curve


func _init() -> void:
	name = "Fireflies"
	mesh = glow_mesh()
	amount = Fx.scaled(LifeRules.FIREFLIES)   # LOW draws half
	lifetime = LIFETIME
	fixed_fps = 30
	local_coords = false
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = AREA
	direction = Vector3(1, 0.3, 0)
	spread = 180.0
	initial_velocity_min = 0.1
	initial_velocity_max = 0.4
	gravity = Vector3(0, 0.03, 0)
	damping_min = 0.02
	damping_max = 0.1
	scale_amount_curve = blink_curve()
	var ramp := Gradient.new()
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var list := PackedColorArray()
	for i in COLORS.size():
		offsets.append(float(i) / COLORS.size())
		list.append(COLORS[i])
	ramp.offsets = offsets
	ramp.colors = list
	color_initial_ramp = ramp
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emitting = false


## One shared tiny glowing box (the golem's glow: unshaded, the particle's own colour).
static func glow_mesh() -> BoxMesh:
	if _box == null:
		_box = BoxMesh.new()
		_box.size = Vector3.ONE * 0.06
		_box.material = GolemModels.glow_material()
	return _box


## A firefly's size over its life: it blinks on and off three times (a size of 0 is dark).
static func blink_curve() -> Curve:
	if _blink == null:
		_blink = Curve.new()
		for p: Vector2 in [Vector2(0.0, 0.0), Vector2(0.12, 1.0), Vector2(0.24, 0.05), Vector2(0.4, 0.05),
				Vector2(0.52, 1.0), Vector2(0.64, 0.05), Vector2(0.78, 0.05), Vector2(0.88, 1.0), Vector2(1.0, 0.0)]:
			_blink.add_point(p)
	return _blink


## Follows the player's feet (the particles stay where they were born: world space).
func follow(feet: Vector3) -> void:
	global_position = feet + Vector3(0, HEIGHT, 0)


func set_on(on: bool) -> void:
	if emitting != on:
		emitting = on
