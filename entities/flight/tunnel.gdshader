// The flight's tunnels (owner #86, movie-style moments in our own look, spec §25.3): the inside of a long open cylinder
// round the rocket. The warp tunnel: gold and rainbow streaks racing past, rings of light (our portals' colours, §3c);
// the wormhole: the same with `twist` winding them into a swirl, in its own colours. Added light (it glows, never hides
// what is behind it), nothing written to depth, the far ends fade out. Everything moves on the GPU (TIME); `strength`
// fades it in and out.
shader_type spatial;
render_mode unshaded, cull_front, blend_add, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 color_a : source_color = vec4(1.0, 0.82, 0.35, 1.0);
uniform vec4 color_b : source_color = vec4(0.4, 0.85, 1.0, 1.0);
uniform float strength = 1.0;
uniform float twist = 0.0;
uniform float rainbow = 1.0;
uniform float speed = 1.0;

vec3 hue(float h) {
	return clamp(abs(fract(h + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void fragment() {
	float t = TIME * speed;
	float around = fract(UV.x + twist * UV.y + twist * t * 0.05);
	float lane = floor(around * 48.0);
	float offset = hash(lane) * 7.0;
	// Streaks: dashes racing along the tunnel, each lane its own.
	float dash = fract(UV.y * 3.0 + t * (1.2 + hash(lane + 3.0)) + offset);
	float streak = smoothstep(0.0, 0.05, dash) * (1.0 - smoothstep(0.05, 0.45, dash));
	float thin = 1.0 - smoothstep(0.0, 0.35, abs(fract(around * 48.0) - 0.5));
	// Rings of light flying past.
	float rings = pow(max(sin((UV.y * 14.0 + t * 2.0) * 6.2832), 0.0), 24.0);
	vec3 lane_col = mix(color_a.rgb, color_b.rgb, hash(lane + 11.0));
	lane_col = mix(lane_col, hue(hash(lane) + t * 0.05), rainbow * 0.6);
	vec3 col = lane_col * streak * thin * 1.4 + mix(color_a.rgb, color_b.rgb, 0.5) * rings * 0.5;
	col += mix(color_b.rgb, color_a.rgb, 0.5 + 0.5 * sin(around * 6.2832 * 2.0 + t)) * 0.06;
	float ends = smoothstep(0.0, 0.2, UV.y) * (1.0 - smoothstep(0.8, 1.0, UV.y));
	ALBEDO = col * ends * strength;
}
