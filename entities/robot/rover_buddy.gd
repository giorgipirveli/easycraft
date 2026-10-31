class_name RoverBuddy
extends SpaceCreature
## The rover buddy (owner #86, spec §21f: "rover buddies that follow the child and dig samples"): a little six-wheeled
## rover that trundles after this game's child, a little behind and to their right (RobotRules.rover_goal), over the
## ground (its own height from the blocks under it), and comes to them at once when left far behind. A tap asks it to
## dig: it tips its scoop down, a puff of the ground's dust, a beep (the director says what the sample is). No
## collision: the child walks past it.

const DIG_TIME := 1.1

## () -> Vector3: the child's feet (INF: none); () -> Vector3: the way they face.
var child_position: Callable
var child_forward: Callable
## (x, z) -> float: the ground's top at a column (the first free y).
var ground_y: Callable
## The dust's colour (the planet's ground).
var dust := Color("c9ccd6")
var _goal := Vector3.INF
var _dig_t := 0.0
var _wheels_t := 0.0
var _col := Vector2i(0x7fffffff, 0)
var _col_y := NAN


## data = {pos: Vector3 (feet), dust: Color}
func setup(data: Dictionary) -> void:
	creature_id = &"rover"
	name = "RoverBuddy"
	display_name = CreatureWords.ROVER_NAME
	position = data.pos
	dust = data.get("dust", dust)
	tap_height = 0.55
	tap_radius = 0.75
	voice = &"pet"
	voice_size = 0.9
	robot = true
	CreatureLook.add(body, RobotModels.rover(), CreatureLook.ROBOT_RANGE, "Deck")
	bubble.position = Vector3(0, 1.6, 0)


## The child asked: it digs (its scoop down, a puff of dust, a beep).
func dig() -> void:
	_dig_t = DIG_TIME
	Audio.play(&"beep", global_position)
	if is_inside_tree():
		Fx.burst(get_tree().root, global_position + Vector3(0, 0.3, 0) + body.global_basis * Vector3(0, 0, -0.8), dust, 20,
			2.2)


func digging() -> bool:
	return _dig_t > 0.0


func think() -> void:
	if not child_position.is_valid():
		return
	var child: Vector3 = child_position.call()
	if not child.is_finite():
		_goal = Vector3.INF
		return
	var fwd: Vector3 = child_forward.call() if child_forward.is_valid() else Vector3.FORWARD
	if RobotRules.rover_teleports(global_position, child):
		global_position = RobotRules.rover_goal(child, fwd)
		global_position.y = _ground(global_position)
	_goal = RobotRules.rover_goal(child, fwd)


func ease_frame(delta: float) -> void:
	if _dig_t > 0.0:
		_dig_t -= delta
		ease_to(body, ^"rotation:x", -0.35 if _dig_t > DIG_TIME * 0.4 else 0.0, 8.0 * delta)
		return
	ease_to(body, ^"rotation:x", 0.0, 8.0 * delta)
	if not _goal.is_finite():
		return
	var at := global_position
	var next := RobotRules.rover_step(at, _goal, delta)
	next.y = lerpf(at.y, _ground(next), clampf(10.0 * delta, 0.0, 1.0))
	if next.is_equal_approx(at):
		ease_to(body, ^"position:y", 0.0, 8.0 * delta)
		return
	if Vector2(next.x - at.x, next.z - at.z).length() > 0.0005:
		_turn_target = RobotRules.yaw_to(at, next) - global_rotation.y
		_wheels_t += delta
		body.position.y = absf(sin(_wheels_t * 14.0)) * 0.03   # a little bump over the ground
	global_position = next


## The ground under `p`, looked up once per column it drives onto (a block read is a locked read).
func _ground(p: Vector3) -> float:
	var col := Vector2i(floori(p.x), floori(p.z))
	if col != _col and ground_y.is_valid():
		_col = col
		_col_y = float(ground_y.call(col.x, col.y))
	return _col_y if not is_nan(_col_y) else p.y
