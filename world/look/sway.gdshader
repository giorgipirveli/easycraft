shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// Leaves and plants that move in the wind (the visuals brief, docs/devlog/parts/visuals.md): a block page's cut-out
// material (BlockLibrary: its picture, the mesher's corner shade in COLOR, cut at half alpha, both sides) whose vertices
// sway a few centimetres. The offset is a function of the vertex's place in the world, so two leaf blocks side by side
// move together (no cracks). `rooted` plants (flowers, wheat) keep their feet and sway at the top; leaves move whole.
// `sway` 0 holds everything still (LOW, Reduce motion). REALISTIC: the page's photo picture and its normal map.

uniform sampler2D pixel_tex : source_color, filter_nearest_mipmap, repeat_disable;
uniform sampler2D photo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D photo_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool realistic = false;
uniform vec2 uv_scale = vec2(1.0);   // REALISTIC: a cropped page keeps fewer rows (BlockLibrary.page_uv_scale)
uniform float sway = 1.0;
uniform float rooted = 0.0;

void vertex() {
	if (sway > 0.0) {   // LOW, Reduce motion: no vertex work at all (a uniform branch)
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float lift = mix(1.0, clamp(fract(w.y + 0.001) * 1.1, 0.0, 1.0), rooted);   // a plant's feet stay in the ground
		float phase = TIME * 1.7 + w.x * 0.37 + w.z * 0.29;
		float gust = 0.6 + 0.4 * sin(TIME * 0.31 + w.x * 0.05 + w.z * 0.04);
		vec3 move = vec3(sin(phase), 0.0, cos(phase * 0.83 + 1.1) * 0.7) * (mix(0.035, 0.07, rooted) * gust * lift * sway);
		VERTEX += (vec4(move, 0.0) * MODEL_MATRIX).xyz;   // into the mesh's space (a chunk: moved, never turned)
	}
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec4 t = realistic ? texture(photo_tex, uv) : texture(pixel_tex, uv);
	ALBEDO = t.rgb * COLOR.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = realistic ? 0.85 : 1.0;
	if (realistic) {
		NORMAL_MAP = texture(photo_normal, uv).rgb;
	}
}
