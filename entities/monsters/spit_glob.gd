class_name SpitGlob
extends Node3D
## A scorpion's poison glob as every peer sees it (M3 Task 2): a green blob (a shared mesh with the
## animals' material) flying MonsterRules.spit_point's arc from the stinger to where it lands, then a
## green splat there. It is only a picture: the host's scorpion decides who it hits (at the same moment,
## from the same numbers). It frees itself; top_level so the scorpion's moves don't carry it.

const SPLAT := Color("8fdc3c")

var from := Vector3.ZERO
var to := Vector3.ZERO
var time := 1.0
## M3 Task 3: the yeti's snowball flies the same way with its own look, splat and sound.
var look: Mesh
var splat := SPLAT
var sound := &"splat"
## Owner #39: a wisp's spark flies straight and slowly (MonsterRules.spark_point) instead of the glob's arc; set it
## before setup. The host may end it early where a wall or a child stopped it (end_at).
var straight := false
var _t := 0.0
var _mesh := MeshInstance3D.new()


func setup(start: Vector3, end: Vector3) -> void:
	from = start
	to = end
	time = MonsterRules.spark_time(start, end) if straight else MonsterRules.spit_time(start, end)


## It ends here now (a wall or a child stopped it): the burst and the sound, then it is gone.
func end_at(pos: Vector3) -> void:
	if is_queued_for_deletion():
		return
	Fx.burst(get_tree().root, pos, splat, 12, 3.5, 0.1, 0.5, 12.0)
	Audio.play(sound, pos)
	queue_free()


func _ready() -> void:
	top_level = true
	_mesh.mesh = look if look != null else MonsterModels.glob_mesh()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	global_position = from


func _process(delta: float) -> void:
	_t += delta
	var k := _t / maxf(time, 0.01)
	global_position = MonsterRules.spark_point(from, to, _t) if straight else MonsterRules.spit_point(from, to, k)
	if k >= 1.0:
		Fx.burst(get_tree().root, to + Vector3(0, 0.15, 0), splat, 12, 3.5, 0.1, 0.5, 12.0)
		Audio.play(sound, to)
		queue_free()
