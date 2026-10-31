class_name FlightLooks
extends RefCounted
## The rocket flight's looks (owner #79, #86, #87; spec §25.3), made once and kept (a material freed with the last
## flight would compile its shader again the next time: DEVELOPMENT.md §8): each world's sphere (planet.gdshader: the
## Earth with its clouds, the Moon's and Mercury's grey maps, Mars's map, any other world painted from its Star Map
## colours), the landing ground (the dust tile in the blocks' own shader: nearest pixels, tinted per world), the pad, the
## Sun's disc and the stars (the night sky's own settings, SkyCycle's), the nebula's puffs, the tunnels. The pictures are
## assets/flight/ (tools/make_flight_textures.py): the small ones load when a flight starts, the worlds' big maps on a
## worker thread (poll(), need()); nothing here loads a world's descriptor (the Moon's took 360 ms on the main thread):
## the Star Map's colours are read from its tables, the skies of the worlds with air and Mercury's big Sun are copied
## here (test_flight_looks.gd keeps them equal to the worlds' own).

const PLANET_SHADER := "res://entities/flight/planet.gdshader"
const TUNNEL_SHADER := "res://entities/flight/tunnel.gdshader"
const EARTH_MAP := "res://assets/flight/earth.png"
const MOON_MAP := "res://assets/flight/moon.png"
const MARS_MAP := "res://assets/flight/mars.png"
const MERCURY_MAP := "res://assets/flight/mercury.png"
const NOISE_MAP := "res://assets/flight/noise.png"
const DUST_MAP := "res://assets/flight/dust.png"
const CLOUD_MAP := "res://assets/flight/cloud.png"
## The Sun's direction in the flight's space (toward it): from the right, a little behind and above, so the world
## ahead and the Earth behind both show a lit side and a line between day and night.
const SUN_DIR := Vector3(0.75, 0.5, 0.35)
const TEAL := Color("139e9b")     # the brand's teal (spec §3c): the landing pad's ring
const GOLD := Color("ffd23f")
## The sky over a world with air ([top, horizon]: the descriptors' sky_top and sky_horizon; Venus's pale yellow clouds).
const SKY := {
	SpaceRules.MARS: [Color(0.8, 0.56, 0.42), Color(0.93, 0.76, 0.6)],
	SpaceRules.TITAN: [Color(0.86, 0.55, 0.26), Color(0.97, 0.78, 0.46)],
	SpaceRules.BOING: [Color(0.48, 0.31, 0.84), Color(0.9, 0.72, 1.0)],
	SpaceRules.RAINBOW: [Color(0.73, 0.64, 0.96), Color(1.0, 0.88, 0.96)],
	SpaceRules.VENUS: [Color(0.92, 0.78, 0.45), Color(1.0, 0.92, 0.7)],
}
## How big the Sun looks there, × home's (the descriptors' sun_size: Mercury's 3, Venus's 1.4, Saturn's rings' 0.1,
## Pluto's 0.025, Triton's 0.033, Ganymede's 0.19).
const SUN_SIZE := {SpaceRules.MERCURY: 3.0, SpaceRules.VENUS: 1.4, SpaceRules.RINGS: 0.1, SpaceRules.PLUTO: 0.025,
	SpaceRules.TRITON: 0.033, SpaceRules.GANYMEDE: 0.19}

static var _planets := {}
static var _earth: ShaderMaterial
static var _ground: StandardMaterial3D
static var _night: StandardMaterial3D
static var _sun: StandardMaterial3D
static var _puffs := {}
static var _tunnels := {}
static var _sphere: SphereMesh
static var _waiting := {}   # a map's path -> [[material, parameter], ...] until its thread has loaded it


## How world `u` looks: {"mode", "map", "tint", "tint2", "rim", "ground" (the landing ground's colour), "sky" (the sky
## over a world with air; Color(0, 0, 0, 0): space's black), "sun_size"}.
static func look(u: int) -> Dictionary:
	var body := star_body(u)
	var c1: Color = body.get("color", Color("a0a0a8"))
	var c2: Color = body.get("color2", c1.darkened(0.3))
	var out := {"mode": 3, "map": NOISE_MAP, "tint": c1, "tint2": c2, "rim": Color(c1.lightened(0.3), 0.0),
		"ground": c1.lerp(c2, 0.3).lightened(0.25), "sky": Color(0, 0, 0, 0), "sun_size": float(SUN_SIZE.get(u, 1.0))}
	match u:
		SpaceRules.MOON:
			out.merge({"mode": 1, "map": MOON_MAP, "tint": Color(0.97, 0.97, 0.99), "ground": Color(1.0, 1.0, 1.03)}, true)
		SpaceRules.MARS:
			out.merge({"mode": 2, "map": MARS_MAP, "ground": Color(1.0, 0.58, 0.36)}, true)
		SpaceRules.MERCURY:
			out.merge({"mode": 1, "map": MERCURY_MAP, "tint": Color(0.86, 0.82, 0.76), "ground": Color(0.82, 0.79, 0.74)}, true)
	if FlightPlan.has_air(u):
		var sky: Array = SKY.get(u, [c1.lightened(0.2), c1.lightened(0.5)])
		out.sky = (sky[0] as Color).lerp(sky[1], 0.5)
		out.rim = Color(sky[1] as Color, 0.8)
	return out


## World u's Star Map body ({} for none), from the Star Map's own tables (never a universe's descriptor).
static func star_body(u: int) -> Dictionary:
	for b: Dictionary in StarMap.SOLAR + StarMap.FAR:
		if int(b.world) == u and str(b.kind) != "universe":
			return b
	return {}


static func earth_look() -> Dictionary:
	return {"mode": 0, "map": EARTH_MAP, "tint": Color.WHITE, "tint2": Color.WHITE, "rim": Color(0.45, 0.72, 1.0, 1.0)}


## World u's sphere material (one per world, kept).
static func planet_material(u: int) -> ShaderMaterial:
	if not _planets.has(u):
		_planets[u] = _planet(look(u))
	return _planets[u]


static func earth_material() -> ShaderMaterial:
	if _earth == null:
		_earth = _planet(earth_look())
	return _earth


static func _planet(lk: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(PLANET_SHADER)
	picture(str(lk.map), m, &"surface")
	m.set_shader_parameter(&"mode", int(lk.mode))
	m.set_shader_parameter(&"tint", lk.tint)
	m.set_shader_parameter(&"tint2", lk.tint2)
	m.set_shader_parameter(&"rim", lk.rim)
	m.set_shader_parameter(&"sun_dir", SUN_DIR)
	return m


## The map at `path` for `m`'s parameter `param`: at once when it is loaded (or small), else from a worker thread
## (poll() hands it over; need() waits for it when it must show now).
static func picture(path: String, m: ShaderMaterial, param: StringName) -> void:
	if path != EARTH_MAP and path != MOON_MAP and path != MARS_MAP and path != MERCURY_MAP \
			or ResourceLoader.has_cached(path):
		m.set_shader_parameter(param, load(path))
		return
	if not _waiting.has(path):
		_waiting[path] = []
		ResourceLoader.load_threaded_request(path)
	(_waiting[path] as Array).append([m, param])


## True when `m`'s map is in (no thread still loads it): a sphere shows only then (a landing's first frames show the
## stars while its world's map arrives; waiting for it held a frame 270 ms behind the other loads).
static func has_map(m: Material) -> bool:
	for path: String in _waiting:
		for pair: Array in _waiting[path]:
			if pair[0] == m:
				return false
	return true


## Hands over the maps the worker threads have loaded; true when none is still loading.
static func poll() -> bool:
	for path: String in _waiting.keys():
		match ResourceLoader.load_threaded_get_status(path):
			ResourceLoader.THREAD_LOAD_LOADED:
				_hand_over(path)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_waiting.erase(path)
	return _waiting.is_empty()


## Takes every map a thread still loads (waiting for them): a flight or a cockpit that ends leaves no load behind (a
## threaded load nobody takes stays pending to the engine's shutdown).
static func settle() -> void:
	for path: String in _waiting.keys():
		_hand_over(path)


## `m` must show now: waits for its map if a thread still loads it.
static func need(m: Material) -> void:
	for path: String in _waiting.keys():
		for pair: Array in _waiting[path]:
			if pair[0] == m:
				_hand_over(path)
				return


static func _hand_over(path: String) -> void:
	var tex: Texture2D = ResourceLoader.load_threaded_get(path)
	for pair: Array in _waiting.get(path, []):
		(pair[0] as ShaderMaterial).set_shader_parameter(pair[1], tex)
	_waiting.erase(path)


## A unit sphere (radius 1) every body shares; its node's scale is its radius.
static func sphere() -> SphereMesh:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 1.0
		_sphere.height = 2.0
		_sphere.radial_segments = 64
		_sphere.rings = 32
	return _sphere


## The landing ground: the dust tile in the blocks' own settings (the same shader as every block: no new compile),
## tinted per world through the mesh's colours.
static func ground_material() -> StandardMaterial3D:
	if _ground == null:
		_ground = StandardMaterial3D.new()
		_ground.albedo_texture = load(DUST_MAP)
		_ground.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		_ground.vertex_color_use_as_albedo = true
		_ground.roughness = 1.0
	return _ground


## The night sky's settings (SkyCycle._night_material: unshaded, see-through, never fogged, both sides) with vertex
## colours: the stars, the light-speed streaks.
static func night_material() -> StandardMaterial3D:
	if _night == null:
		_night = StandardMaterial3D.new()
		SkyCycle._night_material(_night)
		_night.vertex_color_use_as_albedo = true
		_night.vertex_color_is_srgb = true
	return _night


## The Sun's glowing disc: a picture on a quad that always faces the camera (the night sky's moon settings).
static func sun_material() -> StandardMaterial3D:
	if _sun == null:
		_sun = StandardMaterial3D.new()
		SkyCycle._night_material(_sun)
		_sun.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_sun.albedo_texture = ImageTexture.create_from_image(_glow_image(Color(1.0, 0.95, 0.75), 64))
	return _sun


## A nebula's puff in `color` (the same settings as the Sun: one shader).
static func puff_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _puffs.has(key):
		var m := StandardMaterial3D.new()
		SkyCycle._night_material(m)
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_texture = load(CLOUD_MAP)
		m.albedo_color = color
		_puffs[key] = m
	return _puffs[key]


## A tunnel's material: &"warp" (gold and the rainbow) or &"wormhole" (teal, violet and gold, twisted).
static func tunnel_material(kind: StringName) -> ShaderMaterial:
	if not _tunnels.has(kind):
		var m := ShaderMaterial.new()
		m.shader = load(TUNNEL_SHADER)
		if kind == &"wormhole":
			m.set_shader_parameter(&"color_a", Color(0.35, 1.0, 0.85))
			m.set_shader_parameter(&"color_b", Color(0.75, 0.5, 1.0))
			m.set_shader_parameter(&"twist", 2.5)
			m.set_shader_parameter(&"rainbow", 0.3)
			m.set_shader_parameter(&"speed", 0.8)
		_tunnels[kind] = m
	return _tunnels[kind]


## A soft round glow: bright in the middle, fading to nothing at the edge.
static func _glow_image(color: Color, size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5 - Vector2(0.5, 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c) / (size * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			var core := 1.0 if d < 0.3 else 0.0
			img.set_pixel(x, y, Color(color.r, color.g, color.b, clampf(a * a * 0.9 + core, 0.0, 1.0)))
	img.generate_mipmaps()
	return img
