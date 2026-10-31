class_name SkyCycle
extends Node
## Drives one world's sky from DayCycle: turns and colours the sun (it becomes the moon at night),
## recolours the blocky sky or dims the realistic HDRI sky, fades in a moon and stars, and writes
## the open-air light (sun, ambient, fog colour) into WorldService.ambience_base. Ambience puts caves
## and water on top of that every frame; fog distances stay apply_graphics'.
## The host owns the clock and sends it to the clients (Session), which run the same clock in between.

const UPDATE_INTERVAL := 1.0      # seconds between sky updates (the sun moves about 0.1° a second)
const SYNC_INTERVAL := 10.0       # host -> clients clock sync
const STAR_RADIUS := 250.0        # stars and moon float around the camera, inside its far plane (300)
const MOON_RADIUS := 230.0        # in front of the stars
const MOON_SIZE := 26.0
const STAR_COUNT := 320
const STAR_SEED := 20260924

var world: WorldService
var time := DayCycle.START
var running := true
## Survivor games (spec §12.18): the world's game sets how fast the clock runs (SurvivorGames.clock_speed:
## Build to Survive's days 4×, nights 2×). Every peer runs the host's game between the host's syncs.
var game: StringName = SurvivorGames.CLASSIC

var _update_t := 0.0
var _sync_t := SYNC_INTERVAL
var _day_sun := 1.0
var _day_ambient := 0.65
var _sky_material: Material       # the sky material last updated, to catch style switches at once
var _decor := Node3D.new()
var _stars := MeshInstance3D.new()
var _moon := MeshInstance3D.new()
var _star_material := StandardMaterial3D.new()
var _moon_material := StandardMaterial3D.new()


func _ready() -> void:
	_day_sun = world.ambience_base.sun
	_day_ambient = world.ambience_base.ambient
	# The sky changes slowly: spread its lighting (radiance) updates over several frames.
	world.environment().sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	_decor.name = "NightSky"
	_decor.add_to_group(ShaderWarmup.SKY)   # the census counts the sky's bodies as on screen, however far they hang
	add_child(_decor)
	_build_stars()
	_build_moon()
	if Session.is_host():
		Session.client_ready.connect(_on_client_ready)
	else:
		Session.time_received.connect(_on_time_received)
	refresh()


## Jumps the clock (waking up, /time). The host tells every client.
func set_time(t: float) -> void:
	time = DayCycle.wrap_time(t)
	refresh()
	if Session.is_host():
		_sync_t = SYNC_INTERVAL
		Session.broadcast_time(time)


func _process(delta: float) -> void:
	if running:
		time = DayCycle.advance(time, delta * SurvivorGames.clock_speed(game, time))
	var cam := get_viewport().get_camera_3d()
	if cam:
		_decor.position = cam.global_position
	_update_t -= delta
	if _update_t <= 0.0 or world.environment().sky.sky_material != _sky_material:
		refresh()
	if Session.is_host():
		_sync_t -= delta
		if _sync_t <= 0.0:
			_sync_t = SYNC_INTERVAL
			Session.broadcast_time(time)


## Applies the look of the current time now.
func refresh() -> void:
	_update_t = GraphicsPreset.sky_interval(UPDATE_INTERVAL)   # owner #101: every 2 s in a headset
	var look := _tint(DayCycle.look(time))   # M3 Task 5: the universe's daytime colours
	if sun_west:
		look = DayCycle.backwards(look)   # cosmos: Venus spins backwards
	look = SpaceRules.space_look(look, maxf(space, space_climb))   # owner #55: space's black starry sky
	look = DayCycle.sky_meets_fog(look)   # the visuals brief: the far land melts into the sky under the horizon
	var env := world.environment()
	var sun := world.sun()
	var toward: Vector3 = look.light_dir
	sun.basis = Basis.looking_at(-toward, Vector3.BACK)   # the path never passes through ±Z
	sun.light_color = look.light_color
	# The painted sky draws the light's disc in its colour × energy: low over the horizon, where the light fades, that
	# disc would be a dark blot on the bright twilight sky (Venus's sets in the east, right where a child looks); the disc
	# stays out of the sky until the light is full.
	var full: bool = float(look.light_energy) >= (DayCycle.MOON if look.moon_up else DayCycle.SUN) - 0.001
	var disc := DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY if full else DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	if sun.sky_mode != disc:
		sun.sky_mode = disc
	world.ambience_base["ambient_color"] = look.ambient_color
	if world.cave_mood.is_empty():
		env.ambient_light_color = look.ambient_color   # universe 6: the Glow Caves' Ambience writes it (under ceilings)
	world.ambience_base.sun = _day_sun * look.light_energy * (1.0 if look.moon_up else sun_light)   # a world's own sun
	world.ambience_base.ambient = _day_ambient * look.ambient
	world.ambience_base.fog_color = look.fog_color
	_sky_material = env.sky.sky_material
	if _sky_material is ProceduralSkyMaterial:
		var blocky := _sky_material as ProceduralSkyMaterial
		# Only write what changed: every change makes the sky's lighting update again.
		for key: String in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon"]:
			var prop := key + "_color"
			if blocky.get(prop) != look[key]:
				blocky.set(prop, look[key])
		var glow: float = look.sun_glow * (1.0 if look.moon_up else sun_size)   # cosmos: Mercury's big Sun
		if blocky.sun_angle_max != glow:
			blocky.sun_angle_max = glow
	elif _sky_material is PanoramaSkyMaterial:
		var realistic := _sky_material as PanoramaSkyMaterial
		if not is_equal_approx(realistic.energy_multiplier, look.sky_energy):
			realistic.energy_multiplier = look.sky_energy
	# The visuals brief: the photo sky (a clear day's picture) takes the fog's colour at dusk and at night; the painted
	# sky has its own colours for every hour.
	var photo_fog: float = look.get("photo_fog", 0.0) if _sky_material is PanoramaSkyMaterial else 0.0
	if not is_equal_approx(env.fog_sky_affect, photo_fog):
		env.fog_sky_affect = photo_fog
	_star_material.albedo_color.a = look.stars
	_stars.visible = look.stars > 0.01
	_moon_material.albedo_color.a = look.moon
	_moon.visible = look.moon > 0.01 and space < 1.0 and not _own_moons   # owner #55; cosmos: Mars's own moons
	_moon.position = (look.moon_dir as Vector3) * MOON_RADIUS


func _on_client_ready(peer_id: int) -> void:
	Session.send_time(peer_id, time)


func _on_time_received(time_of_day: float) -> void:
	time = DayCycle.wrap_time(time_of_day)
	refresh()


## One mesh of small star quads over the upper sky, facing the camera at the centre.
func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for i in STAR_COUNT:
		var y := rng.randf_range(0.06, 1.0)           # uniform over the sky, never at the horizon
		var angle := rng.randf() * TAU
		var d := Vector3(cos(angle) * sqrt(1.0 - y * y), y, sin(angle) * sqrt(1.0 - y * y))
		var side := d.cross(Vector3.UP if y < 0.99 else Vector3.RIGHT).normalized()
		var up := side.cross(d)
		var s := rng.randf_range(0.45, 1.25)
		var c := d * STAR_RADIUS
		var tint := Color(0.78, 0.86, 1.0) if rng.randf() < 0.5 else Color(1.0, 0.94, 0.8)
		var color := Color.WHITE.lerp(tint, rng.randf()) * rng.randf_range(0.6, 1.0)
		color.a = 1.0
		var a := c - side * s - up * s
		var b := c + side * s - up * s
		var e := c + side * s + up * s
		var f := c - side * s + up * s
		verts.append_array([a, b, e, a, e, f])
		for k in 6:
			colors.append(color)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_night_material(_star_material)
	_star_material.vertex_color_use_as_albedo = true
	_star_material.vertex_color_is_srgb = true
	mesh.surface_set_material(0, _star_material)
	_stars.name = "Stars"
	_stars.mesh = mesh
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_decor.add_child(_stars)


## A pale, softly glowing disc with a few craters, always facing the camera.
func _build_moon() -> void:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(31.5, 31.5)
	var craters: Array[Vector3] = [Vector3(24, 25, 5), Vector3(38, 21, 4), Vector3(35, 39, 6), Vector3(22, 40, 3)]
	for y in size:
		for x in size:
			var p := Vector2(x, y)
			var d := p.distance_to(center)
			var c := Color(0.97, 0.96, 0.88, 0.0)
			if d < 22.0:
				for crater in craters:
					if p.distance_to(Vector2(crater.x, crater.y)) < crater.z:
						c = c.darkened(0.12)
				c.a = clampf(22.0 - d, 0.0, 1.0)
			else:
				c.a = 0.35 * pow(clampf(1.0 - (d - 22.0) / 10.0, 0.0, 1.0), 2.0)   # glow
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var quad := QuadMesh.new()
	quad.size = Vector2(MOON_SIZE, MOON_SIZE)
	_night_material(_moon_material)
	_moon_material.albedo_texture = ImageTexture.create_from_image(img)
	_moon_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = _moon_material
	_moon.name = "Moon"
	_moon.mesh = quad
	_moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_decor.add_child(_moon)


## Unlit, see-through and never fogged (they are far beyond the fog).
static func _night_material(m: StandardMaterial3D) -> void:
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.disable_fog = true
	m.disable_receive_shadows = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED

# --- M3 Task 5: a universe's sky ------------------------------------------------------------------

## The universe's daytime colours (UniverseRegistry.sky): {sky_top, sky_horizon, ground_bottom,
## ground_horizon, fog}. The full day takes them; the night stays the night's. {} = Green Meadows' sky.
## Cosmos (spec §21b.2): an optional `sunset` colour is the glow at the horizon at sunrise and sunset (Mars's blue).
var palette := {}
const SUNSET_GLOW := 0.85         # how far a palette's sunset colour takes the horizon when the sun is on it
## Cosmos (spec §21b.2): how big the Sun looks in this world's sky, × home's (UniverseRegistry.sun_size: Mercury's 3).
## It scales the painted sky's sun (its bright disc and its glow: the sky's sun_angle_max) by day, never the night's
## light; the light itself (its energy, the shadows) stays as it is.
var sun_size := 1.0
## The visuals brief: how bright this world's noon sunlight is, × home's (UniverseRegistry.sun_light: Mars 0.7); the day's
## light only, never the moon's.
var sun_light := 1.0
## Cosmos (spec §21b.2): this world spins backwards (UniverseRegistry.sun_rises_west: Venus): the Sun rises in the west.
var sun_west := false


func _tint(look: Dictionary) -> Dictionary:
	if palette.is_empty():
		return look
	var day := DayCycle.daylight(time)
	for key: String in ["sky_top", "sky_horizon", "ground_bottom", "ground_horizon"]:
		if palette.get(key) is Color:
			look[key] = UniverseRules.sky_color(look[key], palette[key], day)
	if palette.get("fog") is Color:
		look.fog_color = UniverseRules.sky_color(look.fog_color, palette.fog, day)
	if palette.get("sunset") is Color:
		var glow := DayCycle.twilight(time) * SUNSET_GLOW
		for key: String in ["sky_horizon", "ground_horizon"]:
			look[key] = (look[key] as Color).lerp(palette.sunset, glow)
		look.fog_color = (look.fog_color as Color).lerp(palette.sunset, glow * 0.5)
	return look

# --- Owner #55: the sky of space (spec §21) ------------------------------------------------------

const CLIMB_STEP := 0.05          # the climb re-lights the sky in steps this big (the line and the ground always)
const PLANET_DIR := Vector3(0.55, 0.42, -0.72)   # where a space world's planet hangs (a fixed spot in its sky)
const PLANET_PIXELS := 96
const SPOT := Color("c4553a")     # cosmos: Jupiter's Great Red Spot (a sky planet's `spot`)

## How much this world's own sky is space's all day (UniverseRegistry.space_sky: the Moon 1).
var space := 0.0
## How far this game's player has climbed toward the space line (SpaceRules.climb), set by the SpaceDirector.
var space_climb := 0.0
var _planet: MeshInstance3D
var _moons: Array[MeshInstance3D] = []   # cosmos: a world's own small moons beside the planet (Mars's Deimos)
var _own_moons := false                  # the shown bodies are the world's own moons: no moon disc at night


## The climb toward space changed to `c`: re-lights the sky when it moved a step (or reached the line or the ground).
## Returns whether it did.
func set_space_climb(c: float) -> bool:
	var to := clampf(c, 0.0, 1.0) if is_finite(c) else 0.0
	var edge := (to == 0.0 or to == 1.0) and to != space_climb
	if not edge and absf(to - space_climb) < CLIMB_STEP:
		return false
	space_climb = to
	refresh()
	return true


## The planet hanging in this world's sky ({color, land, ring, size}, UniverseRegistry.sky_planet); {} hides it.
## Cosmos: `lumpy` draws a potato-shaped moon, `moons` [{color, land, size, dir, lumpy}] more small bodies elsewhere in
## the sky, `own_moons` says they are the world's own moons (Phobos and Deimos over Mars): the night's moon disc stays
## away. Saturn's rings: `dir` where the planet itself hangs (PLANET_DIR without it: Saturn over the northern horizon),
## `ring_edge` and `pixels` (planet_image).
func show_planet(p: Dictionary) -> void:
	for moon in _moons:
		moon.visible = false
	if not p.get("color") is Color:
		if _planet:
			_planet.visible = false
		_own_moons = false
		return
	if _planet == null:
		_planet = _body("Planet")
	var at: Variant = p.get("dir")
	_show_body(_planet, p, at if at is Vector3 and (at as Vector3).length() > 0.01 else PLANET_DIR)
	_own_moons = p.get("own_moons") == true
	var more: Variant = p.get("moons")
	var i := 0
	for e: Variant in (more as Array if more is Array else []):
		if not e is Dictionary or not (e as Dictionary).get("color") is Color:
			continue
		if i >= _moons.size():
			_moons.append(_body("Moon%d" % (i + 2)))
		var dir: Variant = (e as Dictionary).get("dir")
		_show_body(_moons[i], e, dir if dir is Vector3 and (dir as Vector3).length() > 0.01 else -PLANET_DIR)
		i += 1


## A world's own small moons besides the planet (hidden ones included).
func moons() -> Array[MeshInstance3D]:
	return _moons


func _body(body_name: String) -> MeshInstance3D:
	var b := MeshInstance3D.new()
	b.name = body_name
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_decor.add_child(b)
	return b


## Body b as `p` ({color, land, ring, size, lumpy}) at direction `dir` in the sky: one billboard quad.
func _show_body(b: MeshInstance3D, p: Dictionary, dir: Vector3) -> void:
	var quad := QuadMesh.new()
	var size := float(p.get("size", 60.0))
	quad.size = Vector2(size, size) * (1.6 if p.get("ring") == true or p.get("ring_edge") == true else 1.0)
	var m := StandardMaterial3D.new()
	_night_material(m)
	m.albedo_texture = ImageTexture.create_from_image(planet_image(p))
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = m
	b.mesh = quad
	b.position = dir.normalized() * MOON_RADIUS
	b.visible = true


## The planet node (null before one was shown).
func planet() -> MeshInstance3D:
	return _planet


## A round planet: its colour with soft blobs of land, a thin glowing rim, and a tilted ring when it has one. Cosmos:
## `bands` draws a gas giant's cloud bands instead of land (its colour the pale zones, `land` the belts), `spot` its
## great red storm (Jupiter's Great Red Spot). Saturn's rings: `ring_edge` draws the rings seen edge-on from inside them (a
## thin bright line across its equator and out past its edge, cut dark where Saturn's shadow falls on them just past its
## right edge, and the rings' shadow a dark band on its clouds just under the line); `pixels` a bigger picture for a huge
## planet (PLANET_PIXELS without it). Pluto: `cap` a coloured polar cap over its top (Charon's red one). Triton:
## `spot_color` the great storm's colour (Neptune's dark spot; SPOT, Jupiter's red, without it).
static func planet_image(p: Dictionary) -> Image:
	var n := clampi(int(p.get("pixels", PLANET_PIXELS)), 16, 256)
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var ring: bool = p.get("ring") == true
	var lumpy: bool = p.get("lumpy") == true   # cosmos: a small potato-shaped moon
	var bands: bool = p.get("bands") == true   # cosmos: a gas giant's cloud bands (Jupiter over Europa) ...
	var spot: bool = p.get("spot") == true     # ... and its great red storm
	var edge: bool = p.get("ring_edge") == true   # cosmos: rings seen edge-on (Saturn from its rings)
	var cap: Variant = p.get("cap")                # cosmos: a coloured polar cap (Charon's red one, seen from Pluto)
	var spot_col: Color = p.spot_color if p.get("spot_color") is Color else SPOT   # cosmos: Neptune's dark spot
	var r0 := n * (0.3 if ring or edge else (0.4 if lumpy else 0.46))
	var c := Vector2(n, n) * 0.5 - Vector2(0.5, 0.5)
	var sea: Color = p.color
	var land: Color = p.land if p.get("land") is Color else sea.lightened(0.3)
	var noise := FastNoiseLite.new()
	noise.seed = 555
	noise.frequency = 0.09
	for y in n:
		for x in n:
			var at := Vector2(x, y)
			var d := at.distance_to(c)
			var r := r0
			if lumpy:   # the edge goes in and out round the body
				var a := (at - c).angle()
				r = r0 * (1.0 + 0.13 * sin(a * 2.0 + 0.6) + 0.07 * sin(a * 3.0 + 2.1))
			var col := Color(0, 0, 0, 0)
			if d <= r:
				col = land if noise.get_noise_2d(x, y) > 0.1 else sea
				if bands:   # pale zones and darker belts across it, a little wavy
					var t := (at.y - c.y) / r + 0.04 * noise.get_noise_2d(x * 2.0, y)
					col = sea.lerp(land, smoothstep(0.05, 0.55, sin(t * PI * 3.5)))
				if spot and Vector2((at.x - c.x - r * 0.25) / (r * 0.2), (at.y - c.y - r * 0.32) / (r * 0.11)).length() < 1.0:
					col = spot_col
				if cap is Color and at.y - c.y < -r * 0.55:   # the cap, a little ragged at its edge
					col = (cap as Color).lerp(col, clampf((at.y - c.y + r * 0.72) / (r * 0.17) + 0.3 * noise.get_noise_2d(x, y),
						0.0, 1.0))
				var lit := clampf(1.0 - (at - c + Vector2(r, r) * 0.35).length() / (r * 2.2), 0.0, 1.0)
				col = col.darkened(0.35 * (1.0 - lit))
				col.a = clampf(r - d, 0.0, 1.0)
			elif d <= r + 3.0:
				col = sea.lightened(0.5)
				col.a = 0.45 * (1.0 - (d - r) / 3.0)
			if edge:
				var dy := at.y - c.y
				if d <= r and dy > r * 0.05 and dy < r * 0.16:   # the rings' shadow on its clouds
					col = Color(col.darkened(0.45), col.a)
				if absf(dy) <= maxf(0.75, n * 0.006):   # the rings, edge-on; Saturn's shadow across them past its edge
					var shadow := at.x - c.x > r and at.x - c.x < r * 1.3
					col = Color(0.3, 0.29, 0.33, 0.9) if shadow else Color(1.0, 0.96, 0.86, 0.95)
			if ring:
				var e := Vector2((x - c.x) / (n * 0.48), (y - c.y) / (n * 0.14))
				var q := e.length()
				var front: bool = y > c.y or d > r
				if q > 0.72 and q < 1.0 and front:
					col = Color(1.0, 0.92, 0.72, 0.85).lerp(col, 0.15 if col.a > 0.0 else 0.0)
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return img
