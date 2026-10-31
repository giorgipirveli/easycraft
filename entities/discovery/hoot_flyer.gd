class_name HootFlyer
extends Node3D
## Owner #132 (W1), stage 3: Professor Hoot comes to the child (the brief's "Hoot flies in, lands near the child and says
## one line, then flies to the Academy"). Out of the sky he glides down to land a few metres from the child, turned to
## them, bobbing gently while his line is said (DiscoveryDirector: his card, or a headset's toast strip); then he flies
## off to the Academy's top (or up and away where there is none) and is gone. A picture only: no body, nothing sent.
## The learning places' look (2026-10-18): the one shared owl (HootModel: his body with his face and cap, and his two
## wings), drawn with the rooms' warmed lit material: three draws. His wings beat as he flies and fold at his sides when
## he lands (a little settle as his feet touch); landed, he bobs and now and then ruffles his wings.

const SCALE := 1.6
const IN_SECONDS := 2.4
const OUT_SECONDS := 3.2
## The wings' beat in flight: how far up (radians), how fast (beats a second).
const BEAT := 1.05
const BEATS := 2.6

## Where he lands, and where he flies off to.
var landing := Vector3.INF
var away := Vector3.INF
var leaving := false
## He stands on the ground (landed and not yet off again).
var landed := false
var _bird := Node3D.new()
var _wings: Array[Node3D] = []
var _flying := false
var _t := 0.0
var _tween: Tween


func _init() -> void:
	name = "HootFlyer"
	_bird.name = "Owl"
	_bird.scale = Vector3.ONE * SCALE
	add_child(_bird)
	_mesh(_bird, "Body", HootModel.mesh(HootModel.BODY))
	for part: StringName in [HootModel.WING_LEFT, HootModel.WING_RIGHT]:
		var pivot := Node3D.new()
		pivot.name = "WingLeft" if part == HootModel.WING_LEFT else "WingRight"
		pivot.position = HootModel.shoulder(part)
		_bird.add_child(pivot)
		_mesh(pivot, "Wing", HootModel.mesh(part))
		_wings.append(pivot)


static func _mesh(parent: Node3D, node_name: String, mesh: Mesh) -> void:
	var m := MeshInstance3D.new()
	m.name = node_name
	m.mesh = mesh
	m.material_override = LifeRoomDecor.lit_material()
	parent.add_child(m)


## Flies in from the sky to land at `to`, turned to `child` (both world positions); added to the world first.
func fly_in(to: Vector3, child: Vector3) -> void:
	landing = to
	var from_dir := (to - child)
	from_dir.y = 0.0
	if from_dir.length() < 0.01:
		from_dir = Vector3.FORWARD
	global_position = to + from_dir.normalized() * 8.0 + Vector3.UP * 12.0
	_face(child)
	_flying = true
	landed = false
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "global_position", to, IN_SECONDS)
	_tween.tween_callback(_land)
	Audio.play(&"hoot", to + Vector3.UP)


## Flies off to `to` and is gone.
func fly_away(to: Vector3) -> void:
	if leaving:
		return
	leaving = true
	landed = false
	_flying = true
	away = to
	if _tween and _tween.is_valid():
		_tween.kill()
	_face(to)
	if not is_inside_tree():
		queue_free()
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "global_position", to, OUT_SECONDS)
	_tween.tween_callback(queue_free)


## His feet touch the ground: the wings fold, a little settle.
func _land() -> void:
	_flying = false
	landed = true
	var settle := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle.tween_property(_bird, "scale", Vector3(SCALE * 1.06, SCALE * 0.9, SCALE * 1.06), 0.1)
	settle.tween_property(_bird, "scale", Vector3.ONE * SCALE, 0.25)


## How far his wings are up now (radians; 0: folded).
func wing_angle() -> float:
	return absf(_wings[0].rotation.z) if not _wings.is_empty() else 0.0


func _process(delta: float) -> void:
	_t += delta
	var up := 0.0
	if _flying:
		up = (0.55 + 0.45 * sin(_t * TAU * BEATS)) * BEAT   # a strong beat, never quite folded
		_bird.position.y = sin(_t * TAU * BEATS + 1.2) * 0.08
		_bird.rotation.x = -0.18   # leaning into his flight
	else:
		var ruffle := maxf(0.0, sin(_t * 0.9) - 0.96) * 6.0   # now and then, a little ruffle of his wings
		up = ruffle * 0.35
		_bird.position.y = sin(_t * 5.0) * 0.03   # a gentle bob while his line is said
		_bird.rotation.x = 0.0
	if not _flying and landed:
		up = minf(up, 0.3)
	for i in _wings.size():
		var target := up * (-1.0 if i == 0 else 1.0)   # out and up: the left wing turns about -Z, the right about +Z
		_wings[i].rotation.z = target if _flying else lerpf(_wings[i].rotation.z, target, minf(1.0, delta * 12.0))


## Turned to look at `at` (the owl's model faces -Z).
func _face(at: Vector3) -> void:
	var d := at - global_position
	d.y = 0.0
	if d.length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)
