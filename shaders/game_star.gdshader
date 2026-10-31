// Storm Run's stars (M4 Wave 3, agent H): one shared five-pointed star mesh (StarPool), turning about its
// upright axis and bobbing on the GPU (nothing is written from the CPU per frame); each star turns at its
// own phase from where it stands. Unshaded (it shines at night), both sides. One shared material.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.84, 0.18, 1.0);
uniform vec4 rim : source_color = vec4(1.0, 0.98, 0.75, 1.0);

varying float edge;

void vertex() {
	edge = clamp(length(VERTEX.xy) / 0.45, 0.0, 1.0);
	float a = TIME * 2.2 + NODE_POSITION_WORLD.x * 0.7 + NODE_POSITION_WORLD.z * 0.3;
	float c = cos(a);
	float s = sin(a);
	VERTEX.xz = vec2(c * VERTEX.x - s * VERTEX.z, s * VERTEX.x + c * VERTEX.z);
	VERTEX.y += sin(TIME * 3.0 + NODE_POSITION_WORLD.z) * 0.12;
}

void fragment() {
	ALBEDO = mix(color.rgb, rim.rgb, smoothstep(0.55, 1.0, edge) * 0.6 + 0.15 * sin(TIME * 5.0));
}
