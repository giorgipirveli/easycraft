// The co-op games' glowing circle (M4 Wave 3, agent H): Storm Run's safe circle and hide-and-seek's play
// area. One open cylinder of radius 1 and height 1, scaled per round (GameRing): glowing bands drifting up
// its wall, strongest at the bottom and fading to nothing at the top. Everything moves on the GPU: the CPU
// only scales the one mesh. Unshaded, both sides, see-through, no shadows. One shared material.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, blend_mix, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.45, 0.62, 1.0, 1.0);
uniform float strength = 0.6;

varying float height;
varying float around;

void vertex() {
	height = VERTEX.y + 0.5;
	around = atan(VERTEX.z, VERTEX.x);
}

void fragment() {
	float fade = 1.0 - smoothstep(0.05, 1.0, height);
	float bands = 0.5 + 0.5 * sin(height * 70.0 - TIME * 3.0 + around * 6.0);
	ALBEDO = tint.rgb * (0.75 + 0.5 * bands);
	ALPHA = strength * fade * (0.3 + 0.7 * bands);
}
