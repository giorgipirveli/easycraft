class_name ShootingStar
extends Node3D
## A shooting star falling from the sky to the ground (M2 Task 16): a bright block with a sparkling trail
## (the shared Fx material), then a burst where it lands. Every peer plays it from the host's RPC; the host
## puts the meteor's blocks down when it lands. Frees itself.

const TRAIL_EVERY := 0.07

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _trail := 0.0
var _star := MeshInstance3D.new()


static func fall(parent: Node, from: Vector3, to: Vector3) -> ShootingStar:
	var s := ShootingStar.new()
	s._from = from
	s._to = to
	parent.add_child(s)
	return s


func _ready() -> void:
	_star.mesh = InteractableModels.star()
	_star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_star)
	global_position = _from
	Audio.play(&"star_fall", _to, -2.0)


func _process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / SurpriseRules.STAR_FALL_TIME, 0.0, 1.0)
	global_position = _from.lerp(_to, k * k)
	_star.rotation += Vector3(3.0, 4.0, 2.0) * delta
	_trail -= delta
	if _trail <= 0.0:
		_trail = TRAIL_EVERY
		Fx.burst(get_tree().root, global_position, Color("fff3a8"), 4, 0.6, 0.12, 0.7, 0.0)
	if k >= 1.0:
		Fx.burst(get_tree().root, _to + Vector3(0, 0.5, 0), Color("ffd23f"), 40, 7.0, 0.16, 1.2, 8.0)
		Fx.burst(get_tree().root, _to + Vector3(0, 0.5, 0), Color("b89cff"), 24, 5.0, 0.12, 1.0, 6.0)
		Audio.play(&"star_land", _to)
		queue_free()
