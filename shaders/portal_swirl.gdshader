// The portal swirl (M3 Task 5): the inside of a linked portal frame, the floor of the portal hub's stone
// circle and the window of a universe portal. Drawn on one quad with no textures: a whirl turning with TIME
// around a bright heart, and a glowing rim. Everything moves on the GPU: nothing is written from the CPU per
// frame. Unshaded (it shines at night too), both sides drawn. One shared material for every plain portal and
// one per universe (PortalSwirl), all this one shader.
// Owner #43 (our own look, spec §3c): golden, with arms that run through the rainbow (`rainbow` 1: the plain
// portal) and rainbow sparkles; never the old purple. A universe portal sets rainbow 0 and its own colours.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 deep : source_color = vec4(0.72, 0.42, 0.08, 1.0);
uniform vec4 bright : source_color = vec4(1.0, 0.93, 0.62, 1.0);
uniform vec4 rim : source_color = vec4(1.0, 0.78, 0.25, 1.0);
uniform float rainbow = 1.0;
uniform float speed = 1.0;

// A rainbow colour for a phase (0..1 around the wheel).
vec3 hue(float h) {
	return clamp(abs(fract(h + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float t = TIME * speed;
	// Three arms winding in towards the middle, turning.
	float arms = sin(a * 3.0 + r * 8.0 - t * 3.0);
	float glow = smoothstep(-0.2, 1.0, arms) * (1.0 - 0.55 * r);
	vec3 arm_colour = mix(bright.rgb, mix(bright.rgb, hue(a / 6.2832 + r * 0.6 - t * 0.15), 0.8), rainbow);
	vec3 col = mix(deep.rgb, arm_colour, glow);
	// Rainbow sparkles drifting inward.
	float sparkle = sin(a * 11.0 - t * 5.0) * sin(r * 23.0 + t * 7.0);
	col += mix(bright.rgb, hue(a / 6.2832 + t * 0.3), 0.7) * 0.4 * smoothstep(0.93, 1.0, sparkle);
	// A bright heart, gently pulsing.
	col += bright.rgb * (0.45 + 0.1 * sin(t * 2.0)) * smoothstep(0.4, 0.0, r);
	// The rim.
	vec2 e = min(UV, 1.0 - UV);
	float edge = smoothstep(0.1, 0.0, min(e.x, e.y));
	col = mix(col, rim.rgb, edge * (0.6 + 0.2 * sin(t * 2.5)));
	ALBEDO = col;
}
