class_name ScoutDrone
extends SpaceCreature
## The scout drone (owner #86, spec §21f: "drones that scout ahead"): a little four-rotor drone that flies ahead of
## this game's child towards the next place to explore (the one the robot and the HUD's compass point to), a few
## blocks over the ground, and circles over the child when every place is explored. A tap asks it what it saw: how
## far and which way the place is (the director says it). No collision.

const SPIN := 22.0                # the rotors' turns (radians a second)
const CLEARANCE := 2.5            # never lower than this over the ground under it

## () -> Vector3: the child's feet (INF: none); () -> Vector3: where it scouts to (INF: circle over the child).
var child_position: Callable
var target: Callable
## (x, z) -> float: the ground's top at a column.
var ground_y: Callable
var _goal := Vector3.INF
var _t := 0.0
var _rotors: Array[Node3D] = []
var _bob := 0.0


## data = {pos: Vector3}
func setup(data: Dictionary) -> void:
	creature_id = &"drone"
	name = "ScoutDrone"
	display_name = CreatureWords.DRONE_NAME
	position = data.pos
	tap_height = 0.0
	tap_radius = 0.7
	reach = 10.0                  # it flies over the child's head
	voice = &"pet"
	voice_size = 0.7
	robot = true
	CreatureLook.add(body, RobotModels.drone(), CreatureLook.ROBOT_RANGE, "Frame")
	for i in RobotModels.ROTORS.size():
		var r := Node3D.new()
		r.name = "Rotor%d" % i
		r.position = RobotModels.ROTORS[i] + Vector3(0, 0.05, 0)
		body.add_child(r)
		CreatureLook.add(r, RobotModels.rotor(), CreatureLook.ROBOT_RANGE)
		_rotors.append(r)
	bubble.position = Vector3(0, 0.9, 0)


func think() -> void:
	if not child_position.is_valid():
		return
	var child: Vector3 = child_position.call()
	if not child.is_finite():
		_goal = Vector3.INF
		return
	var to: Vector3 = target.call() if target.is_valid() else Vector3.INF
	if global_position.distance_to(child) > RobotRules.DRONE_TELEPORT:
		global_position = child + Vector3(0, RobotRules.DRONE_HEIGHT, 0)
	_goal = RobotRules.drone_goal(child, to, _t)
	if ground_y.is_valid():
		_goal.y = maxf(_goal.y, float(ground_y.call(floori(_goal.x), floori(_goal.z))) + CLEARANCE)
	if to.is_finite():
		face(to)


func ease_frame(delta: float) -> void:
	_t += delta
	for i in _rotors.size():
		_rotors[i].rotation.y += SPIN * delta * (1.0 if i % 2 == 0 else -1.0)
	if _goal.is_finite():   # it bobs in the air on its way (one transform set a frame)
		var at := RobotRules.drone_step(global_position - Vector3(0, _bob, 0), _goal, delta)
		_bob = sin(_t * 2.4) * 0.08
		global_position = at + Vector3(0, _bob, 0)
