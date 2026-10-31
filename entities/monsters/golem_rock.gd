class_name GolemRock
extends Node3D
## The Stone Golem's thrown rock as every peer sees it (M2 Task 10): a glowing lump (shared mesh and
## glow material) flying BossRules.rock_point's arc from the Golem's hand to where it lands, trailing a
## few sparks, and bursting into bits there. It is only a picture: the host's Golem decides who it hits
## (at the same moment, from the same numbers). It frees itself; top_level so the Golem's moves don't
## carry it.

const SPIN := 7.0

var from := Vector3.ZERO
var to := Vector3.ZERO
var time := 1.0
## M3 Task 2: the Sand Serpent's sand ball flies the same arc with its own look and dust.
var look: Mesh
var dust: Array[Color] = [GolemModels.ROCK, GolemModels.STONE]
## M3 Task 3: the Frost Giant's snowball lands with its own sound.
var sound := &"rock_crash"
var _t := 0.0
var _mesh := MeshInstance3D.new()


func setup(start: Vector3, end: Vector3) -> void:
	from = start
	to = end
	time = BossRules.rock_time(start, end)


func _ready() -> void:
	top_level = true
	_mesh.mesh = look if look != null else GolemModels.rock_mesh()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	global_position = from


func _process(delta: float) -> void:
	_t += delta
	var k := _t / maxf(time, 0.01)
	global_position = BossRules.rock_point(from, to, k)
	_mesh.rotation = Vector3(_t * SPIN, _t * SPIN * 0.6, 0.0)
	if k >= 1.0:
		var root := get_tree().root
		Fx.burst(root, to + Vector3(0, 0.3, 0), dust[0], 14, 5.0, 0.16, 0.6, 14.0)
		Fx.burst(root, to + Vector3(0, 0.3, 0), dust[-1], 10, 4.0, 0.2, 0.7, 14.0)
		Audio.play(sound, to)
		queue_free()
