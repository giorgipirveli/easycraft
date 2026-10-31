class_name Birds
extends MultiMeshInstance3D
## Owner #94 (the animations brief §2): a small flock of birds circling high over this game's player by day
## (LifeRules.birds_on), each flapping then gliding round its own circle (LifeRules.bird). ONE multimesh: a body and two
## wings a bird, all little boxes of Fx's particle material (no new shader: drawn instanced exactly like a
## CPUParticles3D, with colours and custom data), no shadows, a fixed bounding box (nothing recomputed as they fly).
## The flock's middle drifts after the player. Hidden (and not updated) when off. Nothing is sent.

const BODY := Vector3(0.14, 0.1, 0.34)
const WING := Vector3(0.36, 0.03, 0.17)
const COLORS: Array[Color] = [Color("3b3a40"), Color("4a4238"), Color("2f3440")]
const FOLLOW := 0.4   # how fast the flock's middle drifts after the player (share a second)

## The birds flying (LOW flies half: Fx.scaled).
var count := 0
var _t := 0.0
var _middle := Vector3.INF

static var _box: BoxMesh


func _init() -> void:
	name = "Birds"
	count = Fx.scaled(LifeRules.BIRDS)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true   # CPUParticles3D's own layout: the same instanced draw, no new shader variant
	mm.mesh = box_mesh()
	mm.instance_count = count * 3
	var reach := LifeRules.FLOCK_RADIUS.y + 4.0
	mm.custom_aabb = AABB(Vector3(-reach, -8.0, -reach), Vector3(reach * 2.0, 16.0, reach * 2.0))
	for i in count:
		var c: Color = COLORS[i % COLORS.size()]
		mm.set_instance_color(i * 3, c)
		mm.set_instance_color(i * 3 + 1, c.lightened(0.15))
		mm.set_instance_color(i * 3 + 2, c.lightened(0.15))
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


## One shared unit box with Fx's material (every part is it, scaled).
static func box_mesh() -> BoxMesh:
	if _box == null:
		_box = BoxMesh.new()
		_box.size = Vector3.ONE
		_box.material = Fx.material()
	return _box


## Shows or hides the flock (hidden, nothing is updated; shown again, it starts over the player).
func set_on(on: bool) -> void:
	if visible != on:
		visible = on
		if not on:
			_middle = Vector3.INF


## Moves the flock `delta` seconds on round `feet` (the player's): the middle drifts after them, high above.
func step(delta: float, feet: Vector3) -> void:
	if not visible:
		return
	_t += delta
	var goal := feet + Vector3(0.0, LifeRules.FLOCK_HEIGHT, 0.0)
	_middle = goal if not _middle.is_finite() else _middle.lerp(goal, clampf(FOLLOW * delta, 0.0, 1.0))
	global_position = _middle
	var mm := multimesh
	for i in count:
		var turn := _turn(i, _t)
		var at := LifeRules.bird_at(i, _t)
		var flap := LifeRules.bird_flap(i, _t)
		for part in 3:
			mm.set_instance_transform(i * 3 + part, _part(turn, at, flap, part))


## Bird `i`'s part (0 its body, 1 its left wing, 2 its right one) `t` seconds on, round the flock's middle.
static func part_transform(i: int, part: int, t: float) -> Transform3D:
	return _part(_turn(i, t), LifeRules.bird_at(i, t), LifeRules.bird_flap(i, t), part)


static func _turn(i: int, t: float) -> Basis:
	return Basis(Vector3.UP, LifeRules.bird_heading(i, t)) * Basis(Vector3.FORWARD, LifeRules.bird_bank(i))


static func _part(turn: Basis, at: Vector3, flap: float, part: int) -> Transform3D:
	if part == 0:
		return Transform3D(turn * Basis.from_scale(BODY), at)
	var s := -1.0 if part == 1 else 1.0
	var wing := turn * Basis(Vector3.BACK, s * flap)   # > 0: the tips up
	var root := at + turn.x * s * BODY.x * 0.5
	return Transform3D(wing * Basis.from_scale(WING), root + wing.x * s * WING.x * 0.5)


## Where the flock's middle is now (tests).
func middle() -> Vector3:
	return _middle
