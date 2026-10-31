// The desert portal's window (M2 Task 10, research D8 "portal peek"): a moving view into the
// Sandstorm Desert, drawn on one quad with no textures. A warm sky with a sun, three rows of dunes
// drifting at different speeds (near ones faster), streaks of blowing sand, and a soft purple glow at
// the rim. Everything moves with TIME on the GPU: nothing is written from the CPU per frame.
// Unshaded (it shines at night too), both sides drawn. One shared material (DesertPortal).
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 sky_top : source_color = vec4(0.98, 0.62, 0.36, 1.0);
uniform vec4 sky_low : source_color = vec4(1.0, 0.86, 0.58, 1.0);
uniform vec4 sun : source_color = vec4(1.0, 0.97, 0.78, 1.0);
uniform vec4 dune_far : source_color = vec4(0.87, 0.64, 0.38, 1.0);
uniform vec4 dune_mid : source_color = vec4(0.93, 0.72, 0.42, 1.0);
uniform vec4 dune_near : source_color = vec4(0.97, 0.8, 0.5, 1.0);
uniform vec4 sand : source_color = vec4(1.0, 0.9, 0.66, 1.0);
uniform vec4 rim : source_color = vec4(0.62, 0.36, 0.95, 1.0);
uniform float speed = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// The top of a row of dunes at x (0 = the top of the window, 1 = the bottom).
float dune(float x, float base, float height, float freq, float drift) {
	float s = x * freq + drift;
	return base - height * (0.6 * sin(s) + 0.4 * sin(s * 2.3 + 1.7) + 0.35 * noise(vec2(s * 0.8, base * 9.0)));
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	vec3 col = mix(sky_top.rgb, sky_low.rgb, smoothstep(0.0, 0.6, uv.y));
	float d = distance(uv * vec2(1.0, 1.5), vec2(0.7, 0.33));
	col = mix(col, sun.rgb, smoothstep(0.16, 0.12, d));
	col += sun.rgb * 0.18 * smoothstep(0.45, 0.1, d);
	if (uv.y > dune(uv.x, 0.52, 0.05, 5.0, t * 6.0)) {
		col = dune_far.rgb * (0.92 + 0.08 * uv.y);
	}
	if (uv.y > dune(uv.x, 0.66, 0.06, 4.0, t * 11.0 + 2.0)) {
		col = dune_mid.rgb * (0.9 + 0.1 * noise(vec2(uv.x * 20.0 + t * 40.0, uv.y * 12.0)));
	}
	if (uv.y > dune(uv.x, 0.82, 0.07, 3.0, t * 19.0 + 4.0)) {
		col = dune_near.rgb * (0.88 + 0.12 * noise(vec2(uv.x * 30.0 + t * 70.0, uv.y * 18.0)));
	}
	// Blowing sand: thin streaks racing sideways, thicker low down.
	float streak = noise(vec2(uv.x * 7.0 - TIME * 2.6, uv.y * 48.0));
	streak *= noise(vec2(uv.x * 2.0 - TIME * 1.1, uv.y * 6.0 + 3.0));
	col = mix(col, sand.rgb, smoothstep(0.42, 0.62, streak) * (0.35 + 0.5 * uv.y));
	// A soft magic glow at the rim, gently pulsing.
	vec2 e = min(uv, 1.0 - uv);
	float edge = smoothstep(0.12, 0.0, min(e.x * 1.5, e.y));
	col = mix(col, rim.rgb, edge * (0.55 + 0.15 * sin(TIME * 2.0)));
	ALBEDO = col;
}
