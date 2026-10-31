// The cockpit's hologram of the destination (owner #86: "glowing cockpit screens and a hologram of the destination", in
// our own look): its map wrapped round a turning globe in one glowing colour, with scan lines drifting down and a soft
// halo. `mode` reads the map like the flight's planet shader (0 RGB with clouds in alpha, 1 grey, 2 RGB, 3 noise).
shader_type canvas_item;

uniform sampler2D surface : filter_linear, repeat_enable;
uniform int mode = 1;
uniform float spin = 0.0;
uniform vec4 glow : source_color = vec4(0.45, 1.0, 0.92, 1.0);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		COLOR = vec4(glow.rgb, 0.3 * (1.0 - smoothstep(1.0, 1.25, r)));
	} else {
		float z = sqrt(1.0 - r * r);
		float lon = atan(p.x, z) / 6.2832;
		float lat = asin(clamp(p.y, -1.0, 1.0)) / 3.14159;
		vec4 t = texture(surface, vec2(fract(lon + 0.5 + spin), lat + 0.5));
		float lum = mode == 1 || mode == 3 ? t.r : dot(t.rgb, vec3(0.3, 0.59, 0.11));
		if (mode == 0) {
			lum = max(lum, t.a * 0.9);
		}
		float scan = 0.72 + 0.28 * sin(UV.y * 110.0 - TIME * 5.0);
		float rim = pow(1.0 - z, 3.0);
		vec3 col = glow.rgb * (0.25 + 1.1 * lum) * (0.55 + 0.45 * z) * scan + glow.rgb * rim * 0.8;
		COLOR = vec4(col, 0.9);
	}
}
