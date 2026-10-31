shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
// EasyCraft water, both graphics styles. Blocky: the pixel atlas' water tile, like every other
// block, deeper blue and less see-through at a glancing angle, the sun glinting on it and (not on LOW) a gentle
// shimmer in texel-sized steps (the visuals brief, docs/devlog/parts/visuals.md). Realistic: animated wave normals in
// world space, shiny, clearer when looking straight down than at a glancing angle.

uniform sampler2D atlas : source_color, filter_nearest_mipmap, repeat_disable;
uniform sampler2D waves : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool realistic = false;
uniform vec3 deep_color : source_color = vec3(0.05, 0.25, 0.45);
// M3 Task 4: the Candy Kingdom's water is chocolate (1.0 there, 0.0 everywhere else; BlockLibrary.set_liquid).
uniform float chocolate = 0.0;
uniform vec3 chocolate_color : source_color = vec3(0.42, 0.23, 0.12);
// Cosmos (spec §21b.2): Titan's lakes and sea are liquid methane (1.0 there; BlockLibrary.set_liquid): amber and glassy.
uniform float methane = 0.0;
uniform vec3 methane_color : source_color = vec3(0.4, 0.26, 0.1);
// M5 Task 3: the LOW preset's simpler water (BlockLibrary.set_simple_water): no wave normals (two texture reads and
// the normal mapping of every water pixel saved); still shiny and clearer from above.
uniform bool simple = false;

varying vec3 world_pos;
varying float world_up;   // 1 on the water's top face

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_up = step(0.5, (MODEL_MATRIX * vec4(NORMAL, 0.0)).y);
}

void fragment() {
	if (realistic) {
		if (!simple) {
			vec2 p = world_pos.xz + vec2(world_pos.y * 0.37);   // side faces ripple too
			vec3 n1 = texture(waves, p * 0.12 + vec2(TIME * 0.020, TIME * 0.013)).rgb;
			vec3 n2 = texture(waves, p * 0.21 - vec2(TIME * 0.017, -TIME * 0.011)).rgb;
			NORMAL_MAP = mix(n1, n2, 0.5);
			NORMAL_MAP_DEPTH = 0.7;
		}
		float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		vec3 own = mix(chocolate_color, methane_color, methane);   // chocolate or methane (never both)
		ALBEDO = mix(deep_color, own, max(chocolate, methane)) * COLOR.rgb;
		ROUGHNESS = mix(0.06, 0.22, chocolate);
		SPECULAR = 0.7;
		ALPHA = mix(mix(mix(0.62, 0.95, fresnel), 0.97, chocolate), mix(0.72, 0.95, fresnel), methane);
	} else {
		vec4 t = texture(atlas, UV);
		float light = dot(t.rgb, vec3(0.333));
		vec3 own = mix(chocolate_color, methane_color, methane);   // chocolate or methane (never both)
		float liquid = max(chocolate, methane);
		float across = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);   // 0 looking down, 1 along it
		vec3 water = mix(t.rgb, deep_color, 0.45 + 0.4 * across);
		if (!simple) {
			vec2 cell = floor(world_pos.xz * 16.0) * 0.0625;   // the tile's 16 texels a block: the shimmer stays blocky
			float swell = sin(dot(cell, vec2(1.3, 0.7)) + TIME * 1.4) + sin(dot(cell, vec2(-0.6, 1.7)) - TIME * 1.1);
			water *= 1.0 + 0.035 * world_up * swell;
		}
		ALBEDO = mix(water, own * (0.7 + 0.8 * light), liquid) * COLOR.rgb;
		ALPHA = mix(mix(mix(max(t.a, 0.78), 0.95, across), 0.95, chocolate), 0.85, methane);
		ROUGHNESS = mix(0.35, 1.0, liquid);   // the sun glints on water, never on chocolate or methane
		SPECULAR = 0.3 * (1.0 - liquid);
	}
}
