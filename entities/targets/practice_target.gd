class_name PracticeTarget
extends StaticBody3D
## A placeable practice target (M1b Task 11): the base of PracticeDummy and Bullseye. The host
## spawns it for everyone (CombatDirector's MultiplayerSpawner) and saves it with the world. It is
## one merged mesh plus one small box on its own physics layer, which only tap rays look for:
## players, animals and buddies walk through it, and it never touches the terrain.

const LAYER := 16                 # physics layer 5: practice targets
const POPUP_TIME := 0.9
const WOBBLE_STIFFNESS := 60.0
const WOBBLE_DAMPING := 5.0

var item_id := 0
var hits_taken := 0
var last_damage := 0
var _visual := Node3D.new()       # leans (wobbles) around the target's feet
var _tilt := Vector2.ZERO         # lean towards local -Z (x) and +X (y), radians
var _tilt_vel := Vector2.ZERO


## data = {item: ItemIds.DUMMY or BULLSEYE, pos: Vector3 (feet), yaw: float, id: String}
func setup(data: Dictionary) -> void:
	item_id = int(data.item)
	name = str(data.id)
	position = data.pos
	rotation.y = float(data.yaw)
	collision_layer = LAYER
	collision_mask = 0
	add_to_group(&"targets")
	add_child(_visual)
	var mi := MeshInstance3D.new()
	mi.mesh = WeaponModels.mesh_for(item_id)
	_visual.add_child(mi)
	var box := BoxShape3D.new()
	box.size = collision_size()
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = collision_center()
	add_child(shape)


static func kind_for(item: int) -> StringName:
	return WeaponRules.BULLSEYE_TARGET if item == ItemIds.BULLSEYE else WeaponRules.DUMMY


func kind() -> StringName:
	return kind_for(item_id)


func to_save() -> Dictionary:
	return {"item": item_id, "pos": [global_position.x, global_position.y, global_position.z], "yaw": rotation.y}


## The cell the target stands in (its feet).
func cell() -> Vector3i:
	return Vector3i(global_position.floor())


## Where hits aim (and arrows and boomerangs hit), and how big it is.
func center() -> Vector3:
	return to_global(WeaponModels.DUMMY_CENTER)


func radius() -> float:
	return 0.35


func collision_size() -> Vector3:
	return Vector3(0.5, 1.8, 0.4)


func collision_center() -> Vector3:
	return Vector3(0, 0.9, 0)


## Everyone sees the hit: a wobble away from the attacker and, for damage, a floating number.
@rpc("authority", "call_local", "reliable")
func show_hit(amount: int, from: Vector3) -> void:
	hits_taken += 1
	last_damage = amount
	var away := to_local(global_position + (global_position - from).normalized())
	var push := 2.5 + amount * 0.3
	_tilt_vel += Vector2(away.z, -away.x).normalized() * push if away.length() > 0.01 else Vector2(push, 0.0)
	Audio.play(&"hit", center())
	Fx.burst(get_tree().root, center(), Color("e0c38c"), 8, 2.5, 0.08, 0.4, 8.0)
	if amount > 0:
		popup(get_tree().root, center() + Vector3(0, 0.7, 0), str(amount), Color("ffd23f"))


## A floating label that rises and fades away (hit numbers, bullseye scores).
static func popup(parent: Node, pos: Vector3, text: String, color: Color, size: int = 72) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.outline_modulate = Color(0.1, 0.05, 0.0, 0.9)
	l.font_size = size
	l.outline_size = 14
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	parent.add_child(l)
	l.global_position = pos
	var t := l.create_tween()
	t.set_parallel()
	t.tween_property(l, "global_position", pos + Vector3(randf_range(-0.2, 0.2), 0.9, 0), POPUP_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(l, "modulate:a", 0.0, POPUP_TIME * 0.5).set_delay(POPUP_TIME * 0.5)
	t.chain().tween_callback(l.queue_free)
	return l


func _process(delta: float) -> void:
	if _tilt == Vector2.ZERO and _tilt_vel == Vector2.ZERO:
		return
	_tilt_vel += (-_tilt * WOBBLE_STIFFNESS - _tilt_vel * WOBBLE_DAMPING) * delta
	_tilt += _tilt_vel * delta
	if _tilt.length() < 0.002 and _tilt_vel.length() < 0.01:
		_tilt = Vector2.ZERO
		_tilt_vel = Vector2.ZERO
	_visual.rotation = Vector3(_tilt.x, 0.0, _tilt.y)
