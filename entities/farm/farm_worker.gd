class_name FarmWorker
extends Node3D
## One of the Gold Farm's little farmers (M3 Task 10): straw hat, overalls and a hoe. It walks the lanes
## between the crop rows, hoes a while, and now and then carries the harvest to the barn door (a small gold
## sparkle). Pure looks: every game animates its own, from the same seeded plan, and nothing goes over the
## network. Cheap: shared meshes (a body per shirt colour, one arm with the hoe) with WeaponModels' material;
## the animation is a few sines per frame, and it only runs while a player is near (FarmBuilding.set_working).
## It decides where to go next only when it arrives or finishes hoeing (every few seconds, never above 10 Hz).
## Positions are in the farm's own space (FarmSite: the door looks down +Z).

enum Job { WALK, HOE, DELIVER }

const SPEED := 1.1              # metres a second
const HOE_TIME := Vector2(2.2, 4.0)
const HOES_BEFORE_DELIVERY := 3
const LANES: Array[float] = [1.5, 2.5, 3.5]   # between the crop rows (local x)
const DOOR := Vector3(-2.0, 0.0, 2.3)         # just outside the barn door
const SHIRTS: Array[Color] = [Color("d9463b"), Color("3f8fd9"), Color("4caf50")]
const SPARKLE := Color("ffd23f")
const SHOULDER := Vector3(0.22, 0.78, 0.0)

static var _bodies := {}
static var _arm: ArrayMesh

var job: Job = Job.WALK
var target := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _hoe_left := 0.0
var _hoes := 0
var _body := MeshInstance3D.new()
var _arm_pivot := Node3D.new()


## Worker `index` (0..2) of a farm: its shirt, and a plan seeded from the index (every game sees the same).
func setup(index: int) -> void:
	name = "Worker%d" % index
	_rng.seed = 7919 * (index + 1)
	_body.mesh = body_mesh(index)
	_body.visibility_range_end = FarmBuilding.SHOW_WORKERS_WITHIN
	add_child(_body)
	_arm_pivot.position = SHOULDER
	add_child(_arm_pivot)
	var arm := MeshInstance3D.new()
	arm.mesh = arm_mesh()
	arm.visibility_range_end = FarmBuilding.SHOW_WORKERS_WITHIN
	_arm_pivot.add_child(arm)
	position = Vector3(LANES[index % LANES.size()], 0.0, -2.0 + index)
	_pick_next()
	set_process(false)


func _process(delta: float) -> void:
	step(delta)


## One animation step (the building runs it only while a player is near).
func step(delta: float) -> void:
	_t += delta
	match job:
		Job.WALK, Job.DELIVER:
			var to := target - position
			to.y = 0.0
			var d := to.length()
			if d < 0.05:
				_arrived()
				return
			position += to / d * minf(SPEED * delta, d)
			rotation.y = atan2(-to.x, -to.z)
			_body.position.y = absf(sin(_t * 9.0)) * 0.05
			_body.rotation = Vector3(0, 0, sin(_t * 9.0) * 0.06)
			_arm_pivot.rotation.x = sin(_t * 9.0) * 0.4
		Job.HOE:
			_hoe_left -= delta
			var swing := absf(sin(_t * 3.6))
			_arm_pivot.rotation.x = -0.3 - swing * 1.3
			_body.rotation = Vector3(-0.12 - swing * 0.1, 0, 0)
			_body.position.y = 0.0
			if _hoe_left <= 0.0:
				_hoes += 1
				_pick_next()


func _arrived() -> void:
	if job == Job.DELIVER:
		_hoes = 0
		if is_inside_tree():
			Fx.burst(get_tree().root, global_position + Vector3(0, 0.9, 0), SPARKLE, 6, 2.0, 0.08, 0.5, 4.0)
		_pick_next()
		return
	job = Job.HOE
	_hoe_left = _rng.randf_range(HOE_TIME.x, HOE_TIME.y)
	rotation.y = PI * 0.5 * float(_rng.randi_range(0, 3))   # hoe a row: face along or across it


func _pick_next() -> void:
	if _hoes >= HOES_BEFORE_DELIVERY:
		job = Job.DELIVER
		target = DOOR + Vector3(_rng.randf_range(-0.6, 0.6), 0, 0)
		return
	job = Job.WALK
	target = Vector3(LANES[_rng.randi_range(0, LANES.size() - 1)], 0.0, _rng.randf_range(-FarmSite.HALF_D + 0.3, FarmSite.HALF_D - 0.3))


## The body of worker `index` (shirt colour by index), made once.
static func body_mesh(index: int) -> ArrayMesh:
	var i := posmod(index, SHIRTS.size())
	if not _bodies.has(i):
		var overalls := Color("2f5fa8")
		var skin := Color("f1c7a1")
		var straw := Color("e8c65a")
		var boot := Color("5b3a21")
		var shirt: Color = SHIRTS[i]
		_bodies[i] = WeaponModels.build([
			[Vector3(-0.08, 0.06, 0), Vector3(0.13, 0.12, 0.18), boot],
			[Vector3(0.08, 0.06, 0), Vector3(0.13, 0.12, 0.18), boot],
			[Vector3(-0.08, 0.3, 0), Vector3(0.13, 0.36, 0.14), overalls],
			[Vector3(0.08, 0.3, 0), Vector3(0.13, 0.36, 0.14), overalls],
			[Vector3(0, 0.62, 0), Vector3(0.36, 0.3, 0.2), overalls],
			[Vector3(0, 0.84, 0), Vector3(0.36, 0.14, 0.2), shirt],
			[Vector3(-0.22, 0.66, 0), Vector3(0.1, 0.34, 0.1), shirt],       # the left arm (the right holds the hoe)
			[Vector3(0, 1.06, 0), Vector3(0.3, 0.3, 0.28), skin],
			[Vector3(-0.07, 1.08, -0.145), Vector3(0.05, 0.05, 0.01), Color("222222")],
			[Vector3(0.07, 1.08, -0.145), Vector3(0.05, 0.05, 0.01), Color("222222")],
			[Vector3(0, 0.98, -0.145), Vector3(0.1, 0.03, 0.01), Color("a8554a")],
			[Vector3(0, 1.23, 0), Vector3(0.5, 0.04, 0.5), straw],
			[Vector3(0, 1.3, 0), Vector3(0.3, 0.12, 0.3), straw],
			[Vector3(0, 1.26, 0), Vector3(0.31, 0.03, 0.31), Color("c0392b")],
		])
	return _bodies[i]


## The right arm and its hoe, hanging from the shoulder (the pivot), made once.
static func arm_mesh() -> ArrayMesh:
	if _arm == null:
		_arm = WeaponModels.build([
			[Vector3(0, -0.16, 0), Vector3(0.1, 0.34, 0.1), Color("d9d0c0")],
			[Vector3(0, -0.34, -0.2), Vector3(0.04, 0.04, 0.8), Color("8a5a2e")],
			[Vector3(0, -0.44, -0.6), Vector3(0.18, 0.2, 0.03), Color("9aa6b2")],
		])
	return _arm
