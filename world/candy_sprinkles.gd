class_name CandySprinkles
extends Node3D
## Sprinkles falling at night in the Candy Kingdom (M3 Task 4, spec §14.1), on every screen for its own
## player: ONE particle system that follows this game's player, rainbow sprinkles tumbling down around them
## under the open sky (CandyRules.sprinkles_on: at night, not deep in a cave). Cheap: little cubes with the
## shared Fx material (no new shader), world-space particles so they fall while the player walks, and the
## night is looked at four times a second. Nothing here is sent over the network.

const CHECK_EVERY := 0.25
const AMOUNT := 140
const LIFETIME := 4.0
const ABOVE := 9.0                 # the sprinkles start this high over the player's head ...
const AREA := Vector3(14.0, 0.5, 14.0)   # ... over this box (half sizes)
const SIZE := Vector3(0.05, 0.16, 0.05)
const COLORS: Array[Color] = [Color("ff3b5c"), Color("ffd23f"), Color("3fb5ff"), Color("5ee05e"), Color("ffffff"),
	Color("b57bff"), Color("ff8a3d")]

## This game's player (the sprinkles follow it).
var player: Node3D
## () -> float: the time of day (DayCycle).
var time_of_day: Callable = func() -> float: return DayCycle.NOON
## () -> float: how far underground this game's player is, 0..1 (Ambience.underground).
var underground: Callable = func() -> float: return 0.0

static var _mesh: BoxMesh
static var _ramp: Gradient

var _particles := CPUParticles3D.new()
var _check_t := 0.0


func _ready() -> void:
	_particles.name = "Sprinkles"
	_particles.mesh = sprinkle_mesh()
	_particles.amount = Fx.scaled(AMOUNT)   # M5 Task 3: LOW draws half
	_particles.lifetime = LIFETIME
	_particles.preprocess = 0.0
	_particles.local_coords = false
	_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_particles.emission_box_extents = AREA
	_particles.direction = Vector3.DOWN
	_particles.spread = 25.0
	_particles.initial_velocity_min = 0.3
	_particles.initial_velocity_max = 0.9
	_particles.gravity = Vector3(0, -2.4, 0)
	_particles.angular_velocity_min = -180.0
	_particles.angular_velocity_max = 180.0
	_particles.color_initial_ramp = color_ramp()
	_particles.emitting = false
	_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_particles)


## One shared sprinkle: a tiny stick with the Fx material (vertex/particle colours, no new shader).
static func sprinkle_mesh() -> BoxMesh:
	if _mesh == null:
		_mesh = BoxMesh.new()
		_mesh.size = SIZE
		_mesh.material = Fx.material()
	return _mesh


## Every sprinkle gets one of COLORS (a stepped gradient: CPUParticles3D picks a point on it per particle).
static func color_ramp() -> Gradient:
	if _ramp == null:
		_ramp = Gradient.new()
		_ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		var offsets := PackedFloat32Array()
		var colors := PackedColorArray()
		for i in COLORS.size():
			offsets.append(float(i) / COLORS.size())
			colors.append(COLORS[i])
		_ramp.offsets = offsets
		_ramp.colors = colors
	return _ramp


func is_falling() -> bool:
	return _particles.emitting


func particles() -> CPUParticles3D:
	return _particles


func _process(delta: float) -> void:
	tick(delta)


## Every frame the emitter follows the player; four times a second: is it night under the open sky?
func tick(delta: float) -> void:
	if not is_instance_valid(player):
		if _particles.emitting:
			_particles.emitting = false
		return
	_particles.global_position = player.global_position + Vector3(0, ABOVE, 0)
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	var on := CandyRules.sprinkles_on(float(time_of_day.call()), float(underground.call()))
	if _particles.emitting != on:
		_particles.emitting = on
