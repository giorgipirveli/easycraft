class_name MeadowInsects
extends Node3D
## Bees and butterflies over Green Meadows (owner feedback #41, spec §14.19), on every screen for its own player
## (CandySprinkles' pattern): TWO small particle systems round this game's player — a few butterflies drifting and
## tumbling, a few bees zipping about — by day, outdoors, over the grass and bushes (InsectRules.on, looked at four
## times a second). Cheap: tiny boxes with the shared Fx material (no new shader), world-space particles, 30 fps,
## no shadows. Nothing here is sent over the network.

const CHECK_EVERY := 0.25
const AREA := Vector3(7.0, 0.8, 7.0)   # half sizes round the player, a little above the ground
const HEIGHT := 1.1
const BUTTERFLY_COLORS: Array[Color] = [Color("fff6d5"), Color("ffd23f"), Color("ff9f43"), Color("6ec6ff"),
	Color("ff8fc8"), Color("ffffff")]
const BEE_COLORS: Array[Color] = [Color("f2c230"), Color("2a2418"), Color("f2c230")]

## This game's player (they follow it).
var player: Node3D
## () -> float: the time of day (DayCycle).
var time_of_day: Callable = func() -> float: return DayCycle.NOON
## () -> float: how far underground this game's player is, 0..1 (Ambience.underground).
var underground: Callable = func() -> float: return 0.0
## () -> int: the block under this game's player's feet.
var ground: Callable = func() -> int: return BlockIds.GRASS

static var _wing: BoxMesh
static var _bee: BoxMesh

var _butterflies := CPUParticles3D.new()
var _bees := CPUParticles3D.new()
var _check_t := 0.0


func _ready() -> void:
	_setup(_butterflies, "Butterflies", wing_mesh(), 10, 5.0, Vector2(0.3, 0.8), _ramp(BUTTERFLY_COLORS))
	_butterflies.angular_velocity_min = -220.0   # tumbling wings
	_butterflies.angular_velocity_max = 220.0
	_butterflies.gravity = Vector3(0, 0.05, 0)
	_setup(_bees, "Bees", bee_mesh(), 8, 3.0, Vector2(0.9, 1.8), _ramp(BEE_COLORS))
	_bees.gravity = Vector3.ZERO


func _setup(p: CPUParticles3D, node_name: String, mesh: Mesh, amount: int, lifetime: float, speed: Vector2,
		ramp: Gradient) -> void:
	p.name = node_name
	p.mesh = mesh
	p.amount = Fx.scaled(amount)   # M5 Task 3: LOW draws half
	p.lifetime = lifetime
	p.fixed_fps = 30
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = AREA
	p.direction = Vector3(1, 0.2, 0)
	p.spread = 180.0
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.damping_min = 0.1
	p.damping_max = 0.4
	p.color_initial_ramp = ramp
	p.emitting = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)


## One shared butterfly: a thin flat tile with the Fx material (particle colours, no new shader).
static func wing_mesh() -> BoxMesh:
	if _wing == null:
		_wing = BoxMesh.new()
		_wing.size = Vector3(0.14, 0.012, 0.1)
		_wing.material = Fx.material()
	return _wing


static func bee_mesh() -> BoxMesh:
	if _bee == null:
		_bee = BoxMesh.new()
		_bee.size = Vector3(0.06, 0.05, 0.09)
		_bee.material = Fx.material()
	return _bee


static func _ramp(colors: Array[Color]) -> Gradient:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var list := PackedColorArray()
	for i in colors.size():
		offsets.append(float(i) / colors.size())
		list.append(colors[i])
	g.offsets = offsets
	g.colors = list
	return g


func flying() -> bool:
	return _butterflies.emitting


func _process(delta: float) -> void:
	tick(delta)


## Every frame they follow the player; four times a second: a sunny meadow under the open sky?
func tick(delta: float) -> void:
	if not is_instance_valid(player):
		_set_on(false)
		return
	var at := player.global_position + Vector3(0, HEIGHT, 0)
	_butterflies.global_position = at
	_bees.global_position = at
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	_set_on(InsectRules.on(float(time_of_day.call()), float(underground.call()), int(ground.call())))


func _set_on(on: bool) -> void:
	if _butterflies.emitting != on:
		_butterflies.emitting = on
		_bees.emitting = on
