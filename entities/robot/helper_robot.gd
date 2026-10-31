class_name HelperRobot
extends SpaceCreature
## The helper robot at a space world's landing pad (owner #86, spec §21f): it stands by the pad, points the way the
## HUD's compass points (the planet guide's next place, else the aliens; its arm outstretched, turned towards it), and
## when the child comes close it turns to them and waves. The first time the child comes near it greets them (the
## director says its hello). A "!" floats over it while its science quest waits, a "?" while it waits for the child to
## come back. One small box keeps the child from walking through it (the world's layer, like Tilly's counter).

const GREET_DISTANCE := 3.8
const HELLO_DISTANCE := 9.0
const POINT_PITCH := 1.75         # radians: the arm straight out, a little up
const MARK_Y := 2.25

## Where it points (a world position), INF for nowhere.
var point_at := Vector3.INF
## () -> void: the child came near the first time (the director greets).
var on_near: Callable
var arm := Node3D.new()
var mark := Label3D.new()
var greeted := false
var _waving := false
var _t := 0.0


## data = {pos: Vector3 (feet), name: String, badge: Color}
func setup(data: Dictionary) -> void:
	creature_id = &"robot"
	name = "HelperRobot"
	display_name = str(data.get("name", "Robot"))
	position = data.pos
	tap_height = 1.0
	tap_radius = 0.85
	voice = &"bot"
	voice_size = 1.8
	robot = true
	CreatureLook.add(body, RobotModels.helper(data.get("badge", Color("139e9b"))), CreatureLook.ROBOT_RANGE, "Shell")
	arm.name = "Arm"
	arm.position = RobotModels.SHOULDER
	body.add_child(arm)
	CreatureLook.add(arm, RobotModels.arm(), CreatureLook.ROBOT_RANGE, "ArmMesh")
	var tag := Label3D.new()
	tag.name = "NameTag"
	tag.text = display_name
	tag.font_size = 40
	tag.outline_size = 10
	tag.pixel_size = 0.005
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.0, 0)
	add_child(tag)
	mark.name = "Mark"
	mark.font_size = 110
	mark.outline_size = 22
	mark.pixel_size = 0.006
	mark.modulate = Color("ffd23f")
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.position = Vector3(0, MARK_Y, 0)
	mark.visible = false
	add_child(mark)
	bubble.position = Vector3(0, 2.7, 0)
	var box := StaticBody3D.new()
	box.name = "Solid"
	box.collision_layer = Player.WORLD_COLLISION_MASK
	box.collision_mask = 0
	add_child(box)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 1.6, 0.6)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.8, 0)
	box.add_child(cs)


## "!" (a quest waits), "?" (come back to me) or "" (nothing).
func show_mark(text: String) -> void:
	mark.text = text
	mark.visible = text != ""


func mark_text() -> String:
	return mark.text if mark.visible else ""


## It points: its arm is out.
func pointing() -> bool:
	return point_at.is_finite() and not _waving


func think() -> void:
	var child := nearest_player(HELLO_DISTANCE)
	if child.is_finite() and not greeted:
		greeted = true
		if on_near.is_valid():
			on_near.call()
	var was := _waving
	_waving = child.is_finite() and child.distance_to(global_position) <= GREET_DISTANCE
	if _waving and not was:
		AnimGreet.hop(body)   # owner #94: a hop hello as the child walks up
	if _waving:
		face(child)
	else:
		face(point_at)


func ease_frame(delta: float) -> void:
	_t += delta
	var pitch := 0.0
	var roll := 0.0
	if _waving:
		pitch = 0.3
		roll = 2.6 + sin(_t * 9.0) * 0.35   # a big wave over its head
	elif point_at.is_finite():
		pitch = POINT_PITCH
	ease_to(arm, ^"rotation:x", pitch, 6.0 * delta)
	ease_to(arm, ^"rotation:z", roll, 6.0 * delta)
	if mark.visible:
		mark.position.y = MARK_Y + sin(_t * 3.0) * 0.12
