class_name FlightLook
extends Node3D
## What a player's invented flying machine looks like, in every game (owner #78, spec §21e): the balloon over the
## child with its basket round the feet (the burner's flame while the air is heated), the plane or the jet round the
## child (turned with the avatar; the plane's propellers spin, the jet's exhaust glows), and the kite high up downwind
## on its string from the hand. A child of the Player (its feet at the origin), made the first time a machine is used
## (Player._update_flight_look); the meshes are FlightModels' cached ones and every change is written only when it
## happens.

const KITE_OUT := 7.0      # blocks downwind of the child
const KITE_UP := 7.5       # blocks above the feet
const SPIN := 28.0         # the propellers' turn, radians a second

var _body := MeshInstance3D.new()
var _flame := MeshInstance3D.new()
var _props: Array[MeshInstance3D] = []
var _kite := MeshInstance3D.new()
var _string := MeshInstance3D.new()
var _shown := -1
var _t := 0.0


func _ready() -> void:
	for m: MeshInstance3D in [_body, _flame, _kite, _string]:
		m.visible = false
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.name = "Machine"
	add_child(_body)
	_flame.name = "Flame"
	_body.add_child(_flame)
	for x: float in [-1.4, 1.4]:
		var prop := MeshInstance3D.new()
		prop.name = "Propeller"
		prop.mesh = FlightModels.propeller()
		prop.position = Vector3(x, 1.45, 0.85)
		prop.visible = false
		prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_body.add_child(prop)
		_props.append(prop)
	_kite.name = "Kite"
	_kite.top_level = true
	_kite.mesh = FlightModels.kite()
	add_child(_kite)
	_string.name = "KiteString"
	_string.top_level = true
	_string.mesh = GadgetModels.rope()
	add_child(_string)


## The machine on show (FlightCrafts.Craft), -1 before the first look.
func shown() -> int:
	return _shown


func show_for(p: Player) -> void:
	var craft := p.flight_craft
	if craft != _shown:
		_shown = craft
		_show(craft)
	var s := Vector3.ONE * p.size_scale()
	if scale != s:
		scale = s
	if craft == FlightCrafts.Craft.NONE:
		return
	var delta := get_process_delta_time()
	_t += delta
	if craft == FlightCrafts.Craft.PLANE or craft == FlightCrafts.Craft.JET:
		if _body.rotation.y != p.avatar.rotation.y:
			_body.rotation.y = p.avatar.rotation.y
	match craft:
		FlightCrafts.Craft.BALLOON:
			_flame.visible = p.velocity.y > 0.3   # the burner heats the air: it rises
		FlightCrafts.Craft.PLANE:
			for prop in _props:
				prop.rotation.z = fmod(prop.rotation.z + SPIN * delta, TAU)
		FlightCrafts.Craft.JET:
			_flame.visible = Vector2(p.velocity.x, p.velocity.z).length() > 3.0
		FlightCrafts.Craft.KITE:
			_fly_kite(p)


func _show(craft: int) -> void:
	_body.visible = FlightCrafts.flies(craft)
	_flame.visible = false
	_kite.visible = craft == FlightCrafts.Craft.KITE
	_string.visible = _kite.visible
	_body.rotation = Vector3.ZERO
	match craft:
		FlightCrafts.Craft.BALLOON:
			_body.mesh = FlightModels.balloon()
			_flame.mesh = FlightModels.balloon_flame()
		FlightCrafts.Craft.PLANE:
			_body.mesh = FlightModels.plane()
			_flame.mesh = null
		FlightCrafts.Craft.JET:
			_body.mesh = FlightModels.jet()
			_flame.mesh = FlightModels.jet_glow()
	for prop in _props:
		prop.visible = craft == FlightCrafts.Craft.PLANE


## The kite flies downwind of the child, bobbing a little, facing back along its string.
func _fly_kite(p: Player) -> void:
	var w := Vector3(p.wind.x, 0.0, p.wind.z)
	w = w.normalized() if w.length() > 0.01 else Vector3.FORWARD
	var s := p.size_scale()
	var at := p.global_position + (w * KITE_OUT + Vector3.UP * (KITE_UP + sin(_t * 1.7) * 0.4)) * s \
		+ w.cross(Vector3.UP) * sin(_t * 0.9) * 0.6 * s
	if not at.is_finite():
		return
	_kite.global_transform = Transform3D(Basis.looking_at(-w, Vector3.UP).rotated(w, sin(_t * 1.3) * 0.2)
		.scaled(Vector3.ONE * s), at)
	var hand: Node3D = p.avatar.hand() if p.avatar.has_method(&"hand") else null
	var from := hand.global_position if hand else p.eye_position()
	GadgetLooks.stretch(_string, from, at)
