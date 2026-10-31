// The realistic avatar's skin (M3 Task 9): the Kenney texture, recoloured by region for the look.
// region_mask (tools/make_avatar_masks.py) says how much each texel is skin (r), hair (g), shirt (b)
// and pants (a); the shoes are found by their UV rectangle. Skin is tinted (its painted shading
// kept); hair, shirt, pants and shoes take the look's colour times the texel's brightness relative to
// its region (region_gain), so folds and strands stay. Patterns: stripes on the shirt, glowing stars
// on the clothes, or metal. AvatarSkin keeps one material per look; this shader is shared by all.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D region_mask : hint_default_black, filter_linear_mipmap, repeat_disable;
uniform vec3 skin_tint = vec3(1.0);
uniform vec4 hair_color : source_color = vec4(0.35, 0.23, 0.13, 1.0);
uniform vec4 shirt_color : source_color = vec4(1.0);
uniform vec4 pants_color : source_color = vec4(0.2, 0.25, 0.4, 1.0);
// alpha 0 keeps the painted sneakers
uniform vec4 shoe_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec4 pattern_color : source_color = vec4(1.0);
// 1 / the typical (linear) brightness of hair, shirt, pants and shoes in this texture
uniform vec4 region_gain = vec4(25.0, 1.6, 7.4, 1.67);
uniform int pattern = 0;   // 0 none, 1 stripes, 2 stars, 3 metal (AvatarCatalog.PATTERN_*)
uniform float glow = 0.0;
uniform vec4 shoe_rect = vec4(0.625, 0.125, 0.8125, 0.5078);   // (x0, y0, x1, y1) in UV
// Owner 48: a face with cartoon eyelashes and rosy cheeks (and nothing more: no make-up). cheeks and eyes
// are the painted face's spots in UV (AvatarSkin.FACE_SPOTS): left and right.
uniform float lashes = 0.0;
uniform float blush = 0.0;
uniform vec4 cheeks = vec4(0.258, 0.242, 0.359, 0.242);
uniform vec4 eyes = vec4(0.273, 0.214, 0.345, 0.214);

float luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Distance (texels) from p to the segment a-b.
float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// How much texel p (in texels) is an eyelash of the eye at e whose outer corner is towards `side` (-1, +1):
// the upper lid's arc and two little flicks at the outer corner.
float lash(vec2 p, vec2 e, float side) {
	float d = min(seg(p, e + vec2(-4.0 * side, -1.0), e + vec2(0.0, -2.2)), seg(p, e + vec2(0.0, -2.2), e + vec2(4.2 * side, -1.2)));
	d = min(d, seg(p, e + vec2(4.2 * side, -1.2), e + vec2(6.6 * side, -3.4)));
	d = min(d, seg(p, e + vec2(2.4 * side, -2.0), e + vec2(4.0 * side, -4.2)));
	return 1.0 - smoothstep(0.3, 0.75, d);
}

void fragment() {
	vec3 base = texture(albedo_tex, UV).rgb;
	vec4 w = texture(region_mask, UV);
	float lum = luma(base);
	vec3 skin = clamp(base * skin_tint, 0.0, 1.0);
	vec3 hair = clamp(hair_color.rgb * pow(clamp(lum * region_gain.x, 0.0, 2.0), 0.75), 0.0, 1.0);
	float cloth = clamp(lum * region_gain.y, 0.0, 1.4);
	vec3 shirt = clamp(shirt_color.rgb * cloth, 0.0, 1.0);
	vec3 pants = clamp(pants_color.rgb * clamp(lum * region_gain.z, 0.0, 1.4), 0.0, 1.0);
	vec3 emit = vec3(0.0);
	float rough = 0.85;
	float metal = 0.0;
	if (pattern == 1) {
		float band = step(0.5, fract(UV.y * 20.0));
		shirt = mix(shirt, clamp(pattern_color.rgb * cloth, 0.0, 1.0), band);
	} else if (pattern == 2) {
		vec2 grid = UV * 36.0;
		vec2 cell = floor(grid);
		float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		float star = step(0.86, h) * (1.0 - smoothstep(0.12, 0.3, length(fract(grid) - 0.5)));
		shirt = mix(shirt, pattern_color.rgb, star);
		pants = mix(pants, pattern_color.rgb, star);
		emit = pattern_color.rgb * star * glow * (w.b + w.a);
	} else if (pattern == 3) {
		rough = 0.35;
		metal = 0.65;
	}
	float rest = clamp(1.0 - w.r - w.g - w.b - w.a, 0.0, 1.0);
	vec3 col = base * rest + skin * w.r + hair * w.g + shirt * w.b + pants * w.a;
	if (blush > 0.0 || lashes > 0.0) {
		vec2 p = UV * 256.0;
		// A soft pink glow, no edge: on the phones' OpenGL renderer a stronger, redder one read as red spots.
		float rosy = max(1.0 - smoothstep(0.0, 7.0, distance(p, cheeks.xy * 256.0)),
			1.0 - smoothstep(0.0, 7.0, distance(p, cheeks.zw * 256.0)));
		col = mix(col, col * vec3(1.0, 0.8, 0.84) + vec3(0.05, 0.01, 0.02), rosy * rosy * 0.45 * blush);
		vec2 left = eyes.xy * 256.0;
		vec2 right = eyes.zw * 256.0;
		float line = max(lash(p, left, left.x < right.x ? -1.0 : 1.0), lash(p, right, left.x < right.x ? 1.0 : -1.0));
		col = mix(col, vec3(0.03, 0.02, 0.02), line * lashes);
	}
	float in_shoe = step(shoe_rect.x, UV.x) * step(UV.x, shoe_rect.z) * step(shoe_rect.y, UV.y) * step(UV.y, shoe_rect.w);
	vec3 shoes = clamp(shoe_color.rgb * clamp(lum * region_gain.w, 0.0, 1.4), 0.0, 1.0);
	col = mix(col, shoes, in_shoe * shoe_color.a);
	float clothes = clamp(w.b + w.a, 0.0, 1.0);
	ALBEDO = col;
	ROUGHNESS = mix(0.85, rough, clothes);
	METALLIC = metal * clothes;
	EMISSION = emit;
}
