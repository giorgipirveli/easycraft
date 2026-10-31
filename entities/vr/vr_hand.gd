class_name VrHand
extends Node3D
## Owner #101 (VR on the Meta Quest): the pointing hand's laser into the world. A thin beam from the controller along
## Player.aim_ray (the hand's aim pose) to the block the trigger would place on or break, a dot there; a short faint beam
## when nothing is in reach. Hidden while the laser is over a panel (Vr.ui_wants_pointer: VR-UI's pointer draws its
## own beam into the UI) and while no player of this game stands in the world.

const BEAM_WIDTH := 0.006
const IDLE_LENGTH := 1.5
const DOT_RADIUS := 0.025
const BEAM_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const DOT_COLOR := Color(1.0, 0.85, 0.25, 0.95)

var beam := MeshInstance3D.new()
var dot := MeshInstance3D.new()
## The beam's length now (tests).
var length := 0.0


func _init() -> void:
	name = "VrHand"
	var box := BoxMesh.new()
	box.size = Vector3(BEAM_WIDTH, BEAM_WIDTH, 1.0)
	beam.mesh = box
	beam.material_override = _material(BEAM_COLOR)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.name = "Beam"
	add_child(beam)
	var ball := SphereMesh.new()
	ball.radius = DOT_RADIUS
	ball.height = DOT_RADIUS * 2.0
	ball.radial_segments = 8
	ball.rings = 4
	dot.mesh = ball
	dot.material_override = _material(DOT_COLOR)
	dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dot.name = "Dot"
	add_child(dot)
	beam.visible = false
	dot.visible = false


static func _material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.disable_receive_shadows = true
	return m


## One frame: the beam from the hand to its target.
func step(player: Player) -> void:
	var on := player != null and player.is_spawned() and not Vr.ui_wants_pointer() and not Vr.seated() \
		and not (Vr.teleport != null and Vr.teleport.aiming) and not Vr.hand_busy(Vr.pointing_hand())   # owner #110
	var ray := player.aim_ray(Vector2.ZERO) if on else []
	if ray.is_empty():
		beam.visible = false
		dot.visible = false
		length = 0.0
		return
	var from: Vector3 = ray[0]
	var dir: Vector3 = (ray[1] as Vector3).normalized()
	var interactor := player.get_node_or_null("BlockInteractor") as BlockInteractor
	var hit: BlockHit = interactor.ray_at(Vector2.ZERO) if interactor else null
	length = hit.distance if hit else IDLE_LENGTH
	var up := Vector3.UP if absf(dir.y) < 0.99 else Vector3.BACK
	beam.global_transform = Transform3D(Basis.looking_at(dir, up) * Basis.from_scale(Vector3(1.0, 1.0, length)),
		from + dir * length * 0.5)
	beam.visible = true
	dot.visible = hit != null
	if hit:
		dot.global_position = from + dir * maxf(length - DOT_RADIUS, 0.0)
