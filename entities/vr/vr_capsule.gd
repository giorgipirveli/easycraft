class_name VrCapsule
extends MeshInstance3D
## Owner #101 (VR on the Meta Quest, P3): the rocket's capsule round the seated child in a headset: a dark round room
## with a window ahead (a ring of warm light round it), the frame that moves with the child (the strongest help against
## a flight's sickness: the eyes see the capsule still while the stars stream past). RocketFlight puts it on the seat
## (VrSeat) in VR only; the flat game keeps its 2D cockpit hull.
## The dashboard: a node, `Dashboard`, ahead of the chest and a little below the eyes, tilted towards them (+Z faces the
## child). VR-UI's FlightCockpit in its dashboard mode puts its quad there (the path agreed in both notes:
## RocketFlight/VrSeat/VrCapsule/Dashboard; RocketFlight.vr_dashboard()).

const RADIUS := 1.25
const DASHBOARD_AT := Vector3(0.0, -0.32, -0.55)
const DASHBOARD_TILT := -35.0   # degrees round x: its face looks up at the eyes

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform vec4 shell : source_color = vec4(0.13, 0.15, 0.21, 1.0);
uniform vec4 rim : source_color = vec4(1.0, 0.78, 0.35, 1.0);

varying vec3 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec3 d = normalize(local);
	float yaw = atan(d.x, -d.z);
	float pitch = asin(clamp(d.y, -1.0, 1.0));
	float w = (yaw / 0.8) * (yaw / 0.8) + ((pitch - 0.08) / 0.55) * ((pitch - 0.08) / 0.55);
	if (w < 1.0) {
		discard;
	}
	float edge = smoothstep(1.0, 1.18, w);
	vec3 wall = shell.rgb * (0.75 + 0.35 * d.y) + vec3(0.03) * step(0.96, fract(pitch * 6.0));
	ALBEDO = mix(rim.rgb, wall, edge);
}
"""

static var _shader: Shader

var dashboard := Node3D.new()
var _layers := 1


func _init(layers_mask: int = 1) -> void:
	name = "VrCapsule"
	var m := SphereMesh.new()
	m.radius = RADIUS
	m.height = RADIUS * 2.0
	m.radial_segments = 32
	m.rings = 16
	mesh = m
	layers = layers_mask
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	material_override = mat
	dashboard.name = "Dashboard"
	dashboard.position = DASHBOARD_AT
	dashboard.rotation = Vector3(deg_to_rad(DASHBOARD_TILT), 0.0, 0.0)
	add_child(dashboard)
	_layers = layers_mask


## Owner #106/#108: out in the open (the way home's end, watched from a spot by the pad) the round room is not drawn;
## the dashboard (its words) stays with the child.
func show_shell(on: bool) -> void:
	layers = _layers if on else 0
