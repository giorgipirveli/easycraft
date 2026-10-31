// A whole world as a sphere in the rocket flight (owner #79: "the Earth and the Moon as real spheres", spec §25.3):
// one shader for every body (FlightLooks), the map picked by `mode`:
//   0  an RGB map with clouds in alpha (the Earth): the clouds turn their own way (cloud_spin)
//   1  a grey map tinted (the Moon, Mercury)
//   2  an RGB map (Mars)
//   3  a grey noise map painted between two colours (every other world: the Star Map's colours)
// Lit by the Sun without the scene's lights (unshaded: its own day and night, a soft line between them), an air glow
// at the edge (rim, alpha its strength) for worlds with air. No shadows, no fog (far beyond it). The equirectangular map
// has longitude 0 in the middle; `spin` turns the ground (a fraction of a turn).
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;

uniform sampler2D surface : source_color, filter_linear_mipmap, repeat_enable;
uniform int mode = 0;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 tint2 : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform vec3 sun_dir = vec3(0.75, 0.5, 0.35);
uniform float spin = 0.0;
uniform float cloud_spin = 0.0;
uniform vec4 rim : source_color = vec4(0.45, 0.7, 1.0, 0.0);
uniform float night = 0.12;

varying vec3 world_normal;

void vertex() {
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	vec2 uv = vec2(fract(UV.x + spin), UV.y);
	vec4 t = texture(surface, uv);
	vec3 base;
	if (mode == 1) {
		float g = t.r;
		base = vec3(g) * tint.rgb;
	} else if (mode == 3) {
		base = mix(tint2.rgb, tint.rgb, smoothstep(0.3, 0.7, t.r));
	} else {
		base = t.rgb;
	}
	if (mode == 0) {
		float c = texture(surface, vec2(fract(UV.x + cloud_spin), UV.y)).a;
		base = mix(base, vec3(0.95), c * 0.9);
	}
	float lit = dot(normalize(world_normal), normalize(sun_dir));
	float day = smoothstep(-0.12, 0.22, lit);
	vec3 col = base * mix(night, 1.0, day) * (0.72 + 0.28 * clamp(lit, 0.0, 1.0));
	float edge = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	col += rim.rgb * rim.a * pow(edge, 2.5) * (0.25 + 0.75 * day);
	ALBEDO = col;
}
