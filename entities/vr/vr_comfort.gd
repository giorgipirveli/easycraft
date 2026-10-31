class_name VrComfort
extends MeshInstance3D
## Owner #101 (VR on the Meta Quest, the plan's ruling 3: comfort first, for children): one small inside-out sphere
## round the eyes (a child of the head), drawn over everything: the comfort vignette (the view's edges darken while the
## child moves: VrRules.vignette), the black fade (every jump in place; a head inside a wall) and Feel's red tint (a
## hurt, capped at VrRules.TINT_MAX). Hidden while all three are clear (a full-view blend costs fill rate twice over,
## once per eye).

const RADIUS := 0.3
## Over the world, under the VR panels (VR-UI's eye panel and loading room draw at 127 without depth test), so a
## loading card still shows over a black fade.
const RENDER_PRIORITY := 100

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, depth_test_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float vignette = 0.0;
uniform float fade = 0.0;
uniform vec4 tint = vec4(1.0, 0.16, 0.1, 0.0);

varying vec3 dir;

void vertex() {
	dir = normalize(VERTEX);
}

void fragment() {
	float ang = acos(clamp(-dir.z, -1.0, 1.0));
	// the clear middle shrinks as the vignette grows: 80 degrees round the middle at its weakest, 32 at its strongest
	float inner = mix(1.4, 0.55, vignette);
	float v = smoothstep(inner, inner + 0.35, ang) * step(0.001, vignette);
	float a = max(v, tint.a);
	vec3 c = tint.a > v ? tint.rgb : vec3(0.0);
	ALBEDO = mix(c, vec3(0.0), fade);
	ALPHA = mix(a, 1.0, fade);
}
"""

static var _shader: Shader

## 0 clear .. 1 dark edges (the child moving).
var vignette := 0.0
## 0 clear .. 1 black (a fade).
var fade := 0.0
## 0 clear .. 1 black (the head inside a block, or leaning past where the body could go).
var head_block := 0.0
## Feel's tint (its alpha already capped).
var tint := Color(1.0, 0.16, 0.1, 0.0)
## 0 clear .. 1 black: a knock-out dims the view (VrRules.KNOCKOUT_DIM: 40 % left; the HELP UP words on the panel).
var dim := 0.0


func _init() -> void:
	name = "VrComfort"
	var m := SphereMesh.new()
	m.radius = RADIUS
	m.height = RADIUS * 2.0
	m.radial_segments = 24
	m.rings = 12
	mesh = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.render_priority = RENDER_PRIORITY
	material_override = mat
	visible = false


## How black the view is now (a fade, the head in a wall, a knock-out's dim).
func black() -> float:
	return maxf(maxf(fade, head_block), dim)


## Writes the values into the material; shown only while something is not clear.
func apply() -> void:
	var mat := material_override as ShaderMaterial
	var b := black()
	mat.set_shader_parameter(&"vignette", vignette)
	mat.set_shader_parameter(&"fade", b)
	mat.set_shader_parameter(&"tint", tint)
	visible = b > 0.001 or vignette > 0.001 or tint.a > 0.001
