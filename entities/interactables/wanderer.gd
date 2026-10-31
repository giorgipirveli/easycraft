class_name Wanderer
extends SecretThing
## The Wanderer (M2 Task 16, spec §12.16): a rare hooded visitor who comes at dusk near a player and asks a
## riddle with three picture answers. Tapping him shows the riddle on this device; the answer goes to the
## host (Session.request_wanderer_answer), which rewards the first right answer once, and he vanishes in
## sparkles. Every peer animates him: a slow float and a turn towards the nearest player.

const TURN_SPEED := 2.0
const FLOAT := 0.06

var riddle := 0                   # index into Riddles.WANDERER_RIDDLES
var dusk := 0                     # the world's dusk he came on

var _body := Node3D.new()
var _t := 0.0


## data = {id, pos, yaw, riddle, dusk}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(0.8, 1.9, 0.7), Vector3(0, 0.95, 0))
	riddle = int(data.get("riddle", 0))
	dusk = int(data.get("dusk", 0))
	add_child(_body)
	_mesh(InteractableModels.wanderer(), _body)
	_mesh(InteractableModels.wanderer_eyes(), _body)


func question() -> Dictionary:
	return Riddles.wanderer_riddle(riddle)


func _process(delta: float) -> void:
	_t += delta
	_body.position.y = FLOAT + sin(_t * 1.6) * FLOAT
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var to := cam.global_position - global_position
	if Vector2(to.x, to.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(TURN_SPEED * delta, 0.0, 1.0))
