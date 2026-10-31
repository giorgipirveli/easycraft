class_name SkyDragonTower
extends StaticBody3D
## A sun lantern of the Sky Dragon's fight (owner feedback #39, spec §14.2a; owner #43: golden, never a crystal on a
## dark pillar): it rises out of the ground round the
## arena and heals the dragon a little every second (a glowing beam to it, with sparks running along) until the team
## breaks it with SkyDragonRules.TOWER_HITS hits. It is an entity, never a block: a child of its dragon (top_level,
## so it stands still while the dragon flies) that every screen builds from the dragon's synced tower_spots and
## tower_hits. It is in the group "monsters" with take_hit / hit_center / hit_radius / size while it stands, so
## everything that hits monsters hits it (swords, arrows, spears, blasters, orbs, bot friends' swings) and a tap aims
## at it (the monsters' layer); the host's dragon counts the hits. It never hurts anyone. Shared meshes (the
## animals' material and the Golem's glow material): nothing new to compile.

const BODY := Vector3(1.2, 3.6, 1.2)
const RISE_TIME := 0.8
const BEAM_WIDTH := 0.1
const SPARK_SPEED := 1.3          # sparks a second running up the beam
const SHRINK := 0.12              # each hit takes this much off its crystal's height

var index := 0
var dragon: SkyDragon
var _hits := 0                    # the hits this screen shows (from the dragon's synced tower_hits)
var _t := 0.0
var _body := Node3D.new()
var _crystal := MeshInstance3D.new()
var _beam := MeshInstance3D.new()
var _spark := MeshInstance3D.new()
var _beam_on := false
var _wobble: Tween


func setup(i: int, owner_dragon: SkyDragon) -> void:
	index = i
	dragon = owner_dragon
	name = "Tower%d" % i
	top_level = true
	add_to_group(&"monsters")
	collision_layer = Monster.LAYER       # taps aim at it; nothing collides with it
	collision_mask = 0
	var box := BoxShape3D.new()
	box.size = BODY
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = BODY.y * 0.5
	add_child(shape)
	add_child(_body)
	var base := MeshInstance3D.new()
	base.mesh = SkyDragonModels.tower_base_mesh()
	_body.add_child(base)
	_crystal.mesh = SkyDragonModels.tower_crystal_mesh()
	_body.add_child(_crystal)
	for m: MeshInstance3D in [_beam, _spark]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visible = false
		add_child(m)
	_beam.mesh = SkyDragonModels.beam_mesh()
	_spark.mesh = SkyDragonModels.spark_mesh()
	_body.position.y = -SkyDragonModels.TOWER_HEIGHT


func standing() -> bool:
	return SkyDragonRules.tower_standing(_hits)


func hit_center() -> Vector3:
	return global_position + Vector3(0, BODY.y * 0.5, 0)


## Generous, like a monster's: children aim loosely.
func hit_radius() -> float:
	return 0.9


func size() -> Vector3:
	return BODY


## Anything that hits monsters hits it; the host's dragon counts it (a guest's copy is only a picture).
func take_hit(_damage: int, _from: Vector3, _knockback: Vector3) -> void:
	if multiplayer.is_server() and standing() and is_instance_valid(dragon) and not is_queued_for_deletion():
		dragon.hit_tower(index)


## Every screen: the hits it has taken now (the dragon's synced tower_hits). A new hit wobbles it, sheds shards and
## shrinks its crystal; the last one shatters it: it leaves the group (nothing aims at it any more) and goes dark.
## quiet: a tower built with hits already on it (a guest joining) shows them without the effects.
func show_hits(hits: int, quiet: bool = false) -> void:
	if hits <= _hits:
		return
	var was_standing := standing()
	_hits = hits
	if was_standing and not standing():
		_shatter(quiet)
		return
	_crystal.scale = Vector3(1.0, maxf(1.0 - SHRINK * _hits, 0.4), 1.0)
	if quiet or not is_inside_tree():
		return
	var root := get_tree().root
	Fx.burst(root, hit_center() + Vector3(0, 0.8, 0), SkyDragonModels.CRYSTAL, 10, 5.0, 0.14, 0.6, 12.0)
	Audio.play(&"sky_crystal_shatter", hit_center(), -12.0)
	if _wobble and _wobble.is_valid():
		_wobble.kill()
	_wobble = create_tween()
	_wobble.tween_property(_body, "rotation:z", 0.18, 0.06)
	_wobble.tween_property(_body, "rotation:z", -0.12, 0.1)
	_wobble.tween_property(_body, "rotation:z", 0.0, 0.14)


func _shatter(quiet: bool) -> void:
	remove_from_group(&"monsters")
	collision_layer = 0
	_crystal.visible = false
	set_beam(false)
	if quiet or not is_inside_tree():
		return
	var root := get_tree().root
	var at := global_position + Vector3(0, 2.0, 0)
	Fx.burst(root, at, SkyDragonModels.CRYSTAL, 24, 7.0, 0.2, 0.9, 12.0)
	Fx.burst(root, at, SkyDragonModels.CRYSTAL_CORE, 14, 6.0, 0.16, 0.8, 12.0)
	Audio.play(&"sky_crystal_shatter", at)


func set_beam(on: bool) -> void:
	on = on and standing()
	if on != _beam_on:
		_beam_on = on
		_beam.visible = on
		_spark.visible = on


## Every screen, every frame (the dragon calls it): the beam from its crystal's tip to `to` (the dragon), and a spark
## running up it: the heal on its way.
func aim_beam(to: Vector3) -> void:
	if not _beam_on or not to.is_finite():
		return
	var from := global_position + SkyDragonModels.TOWER_TOP + Vector3(0, _body.position.y, 0)
	var d := to - from
	var length := d.length()
	if length < 0.3:
		return
	var up := Vector3.UP if absf(d.normalized().y) < 0.98 else Vector3.FORWARD
	_beam.global_transform = Transform3D(Basis.looking_at(d, up) * Basis.from_scale(Vector3(BEAM_WIDTH, BEAM_WIDTH, length)), from)
	_spark.global_position = from + d * fmod(_t * SPARK_SPEED, 1.0)


func _process(delta: float) -> void:
	_t += delta
	if _body.position.y < 0.0:        # rising out of the ground
		_body.position.y = minf(_body.position.y + SkyDragonModels.TOWER_HEIGHT / RISE_TIME * delta, 0.0)
	if _beam_on:
		_spark.rotation.y = _t * 4.0
