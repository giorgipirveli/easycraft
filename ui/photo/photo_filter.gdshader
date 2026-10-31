shader_type canvas_item;
// Photo mode's one post-process pass (M3 Task 16). One long-lived ShaderMaterial on a full-screen
// ColorRect; each filter (PhotoFilters) only sets these uniforms. It is drawn over the 3D picture and
// under the frame and the buttons, and only while a filter other than NORMAL is chosen.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec3 tint = vec3(1.0);
uniform float saturation = 1.0;
uniform float contrast = 1.0;
uniform float brightness = 0.0;
uniform float levels = 0.0;
uniform float outline = 0.0;
uniform float vignette = 0.0;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	c = mix(vec3(luma(c)), c, saturation);
	c = (c - 0.5) * contrast + 0.5 + brightness;
	c *= tint;
	if (levels > 0.0) {
		c = floor(clamp(c, 0.0, 1.0) * levels + 0.5) / levels;
	}
	if (outline > 0.0) {
		vec2 px = SCREEN_PIXEL_SIZE * 1.5;
		float gx = luma(texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0)).rgb)
			- luma(texture(screen_texture, SCREEN_UV - vec2(px.x, 0.0)).rgb);
		float gy = luma(texture(screen_texture, SCREEN_UV + vec2(0.0, px.y)).rgb)
			- luma(texture(screen_texture, SCREEN_UV - vec2(0.0, px.y)).rgb);
		float edge = smoothstep(0.06, 0.2, length(vec2(gx, gy)));
		c = mix(c, vec3(0.06, 0.05, 0.08), edge * outline);
	}
	if (vignette > 0.0) {
		vec2 d = (SCREEN_UV - 0.5) * vec2(1.3, 1.0);
		c *= 1.0 - vignette * smoothstep(0.35, 0.8, length(d));
	}
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
