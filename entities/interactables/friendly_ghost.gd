class_name FriendlyGhost
extends SecretThing
## A friendly ghost of a haunted house (owner feedback #42, spec §12.16b): it floats about its home spot,
## turns to look at the player, giggles now and then, and a tap shows its picture riddle on this device. The
## answer goes to the host (Session.request_wanderer_answer: its name starts with "ghost_"), whose
## TreasureDirector opens the house's chest for the right one. Every peer animates it the same way (from
## the clock, nothing sent).

const FLOAT := 0.12
const DRIFT := 0.45               # blocks it wanders from its home spot
const TURN_SPEED := 2.5
const GIGGLE_EVERY := Vector2(7.0, 14.0)
const GIGGLE_NEAR := 14.0         # it giggles only for someone this close

var riddle := 0                   # index into TreasureRules.GHOST_RIDDLES
var index := 0                    # its house's first or second ghost

var _body := Node3D.new()
var _home := Vector3.ZERO
var _t := 0.0
var _giggle_in := 0.0


## data = {id, pos, yaw, secret, riddle, index}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(0.8, 1.3, 0.8), Vector3(0, 0.8, 0))
	riddle = int(data.get("riddle", 0))
	index = int(data.get("index", 0))
	_home = position
	_t = index * 2.1
	_giggle_in = GIGGLE_EVERY.x + index * 3.0
	add_child(_body)
	var mi := _mesh(TreasureModels.ghost(), _body)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func question() -> Dictionary:
	return TreasureRules.ghost_riddle(riddle)


## A tap: the riddle with its three picture answers (SecretTaps).
func use_tap(hud: Node) -> bool:
	if hud == null:
		return false
	var q := question()
	var me := String(name)
	hud.call(&"show_riddle", q.question, q.choices,
		func(choice: int) -> void: Session.request_wanderer_answer(me, choice))
	Audio.play(&"giggle", global_position + Vector3(0, 1, 0))
	return true


func _process(delta: float) -> void:
	_t += delta
	position = _home + Vector3(cos(_t * 0.5) * DRIFT, 0.0, sin(_t * 0.7) * DRIFT)
	_body.position.y = FLOAT + sin(_t * 1.9) * FLOAT
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var to := cam.global_position - global_position
	if Vector2(to.x, to.z).length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(TURN_SPEED * delta, 0.0, 1.0))
	_giggle_in -= delta
	if _giggle_in <= 0.0:
		_giggle_in = lerpf(GIGGLE_EVERY.x, GIGGLE_EVERY.y, 0.5 + 0.5 * sin(_t * 3.1))
		if to.length() <= GIGGLE_NEAR:
			Audio.play(&"giggle", global_position + Vector3(0, 1, 0))
