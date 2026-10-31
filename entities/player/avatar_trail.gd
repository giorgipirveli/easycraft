class_name AvatarTrail
extends CPUParticles3D
## A running trail (M3 Task 9): little cubes left behind while the body runs on the ground. They stay
## where they were dropped (world space) and use the one shared particle material (Fx.material), with
## each style's colours as a shared gradient, so no trail ever makes a material.

## Style -> colours (each cube picks one at random from the gradient), cube size, rise speed
## (negative gravity floats up), lifetime.
const STYLES := {
	&"sparkles": {"colors": [Color("fffde7"), Color("ffe082"), Color("ffffff")], "size": 0.06, "rise": 1.2, "life": 0.7},
	&"bubbles": {"colors": [Color("b3e5fc"), Color("e1f5fe"), Color("81d4fa")], "size": 0.08, "rise": 1.6, "life": 0.9},
	&"hearts": {"colors": [Color("f06292"), Color("ff8a80"), Color("f8bbd0")], "size": 0.08, "rise": 0.9, "life": 0.8},
	&"stars": {"colors": [Color("ffd54f"), Color("fff59d"), Color("ffca28")], "size": 0.07, "rise": 0.6, "life": 0.9},
	&"rainbow": {"colors": [Color("e53935"), Color("fb8c00"), Color("fdd835"), Color("43a047"), Color("1e88e5"), Color("8e24aa")],
		"size": 0.08, "rise": 0.2, "life": 0.8},
	&"confetti": {"colors": [Color("ef5350"), Color("ffee58"), Color("66bb6a"), Color("42a5f5"), Color("ab47bc")],
		"size": 0.06, "rise": -1.5, "life": 0.9},
	# Owner 35 (spec §18): in what a grown-up buys (EasyCraft Plus; the Sky Pack; the Ocean Pack)
	&"snowflakes": {"colors": [Color("ffffff"), Color("e1f5fe"), Color("b3e5fc")], "size": 0.06, "rise": -0.6, "life": 1.0},
	&"feathers": {"colors": [Color("ffffff"), Color("ffe0b2"), Color("ffcc80")], "size": 0.07, "rise": -0.3, "life": 1.0},
	&"little_fish": {"colors": [Color("ff9800"), Color("ffd54f"), Color("4fc3f7")], "size": 0.08, "rise": 0.8, "life": 0.8},
	# Owner 36 (spec §14.6b): with the costume pack's astronaut, ninja and robot
	&"rocket": {"colors": [Color("ff7043"), Color("ffca28"), Color("fff8e1")], "size": 0.07, "rise": 0.9, "life": 0.6},
	&"smoke": {"colors": [Color("9e9e9e"), Color("cfd8dc"), Color("eceff1")], "size": 0.1, "rise": 0.5, "life": 1.0},
	&"sparks": {"colors": [Color("4fc3f7"), Color("e1f5fe"), Color("fff176")], "size": 0.05, "rise": 1.4, "life": 0.5},
}
## Runs faster than this (m/s) on the ground leave a trail.
const RUN_FROM := 2.5

static var _gradients := {}
static var _meshes := {}

var style: StringName = &""


func _init() -> void:
	name = "Trail"
	local_coords = false
	emitting = false
	amount = 18
	explosiveness = 0.0
	emission_shape = EMISSION_SHAPE_BOX
	emission_box_extents = Vector3(0.22, 0.05, 0.18)
	position = Vector3(0, 0.12, 0)
	direction = Vector3.UP
	spread = 35.0
	initial_velocity_min = 0.2
	initial_velocity_max = 0.7
	angular_velocity_min = -180.0
	angular_velocity_max = 180.0
	scale_amount_min = 0.6
	scale_amount_max = 1.0
	color = Color.WHITE
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func setup(trail_style: StringName) -> void:
	style = trail_style if STYLES.has(trail_style) else &"sparkles"
	var s: Dictionary = STYLES[style]
	lifetime = s.life
	gravity = Vector3(0, s.rise, 0)
	mesh = _mesh(s.size)
	color_initial_ramp = _gradient(style)


## Called every physics frame with the body's ground speed.
func update(speed: float, on_ground: bool) -> void:
	var on := on_ground and speed > RUN_FROM
	if emitting != on:
		emitting = on


static func _mesh(size: float) -> BoxMesh:
	if not _meshes.has(size):
		var m := BoxMesh.new()
		m.size = Vector3.ONE * size
		m.material = Fx.material()
		_meshes[size] = m
	return _meshes[size]


static func _gradient(trail_style: StringName) -> Gradient:
	if not _gradients.has(trail_style):
		_gradients[trail_style] = Celebration.gradient(STYLES[trail_style].colors)
	return _gradients[trail_style]
