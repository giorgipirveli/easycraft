extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.11, §4.4-4.6; G0's place contract, play-g0.md §7): Inside a
## Leaf's places keep the contracts G0's host and the phones and headsets need. From each place's flat view every thing
## to tap is in the free band of a 16:9 screen (PlayHud.FREE), at least a fingertip across (LifeReach.FINGER_PX), never
## hidden behind a cell or a column, and never so near another that a finger could pick the wrong one; in VR every thing
## the hands take or squeeze is within 1.1 m of a stand's eyes (and the laser reaches the rest); every material is one
## the warm-up already holds (the census's draw, instanced or not), nothing casts a shadow, there is one light, and there
## is nothing to read.

const HAND := 1.1

var _view: SubViewport
var _cam: Camera3D


func before_all() -> void:
	Profile.data.settings.reduce_motion = true


func after_all() -> void:
	Profile.data.settings.reduce_motion = false


func before_each() -> void:
	_view = SubViewport.new()   # the game's narrowest canvas (16:9; phones are wider): the headless window is square
	_view.size = Vector2i(PlayHud.CANVAS)
	add_child_autofree(_view)
	_cam = Camera3D.new()
	_cam.fov = PlayHost.FOV
	_view.add_child(_cam)


## Every place at its fullest: a sugar waiting at every spot, every door open, the bud full; and each dressing.
func _places() -> Array[LeafRoom]:
	var out: Array[LeafRoom] = []
	for dressing: String in ["sunflower", "cactus"]:
		var place := LeafPlace.new(dressing)
		add_child_autofree(place)
		place.show_all()
		out.append(place)
	var garden := LeafGarden.new()
	add_child_autofree(garden)
	out.append(garden)
	return out


func _screen_radius(world_at: Vector3, radius: float) -> float:
	var centre := _cam.unproject_position(world_at)
	var side := _cam.global_basis.x * radius
	return centre.distance_to(_cam.unproject_position(world_at + side))


func test_every_thing_to_tap_is_in_the_free_band_a_fingertip_across_and_in_plain_sight() -> void:
	for place in _places():
		for view: String in place.flat_views():
			_cam.global_transform = place.camera_transform(view)
			var seen := {}
			for t: String in place.flat_targets(view):
				assert_true(place.has_target(t), "%s %s: %s is a target" % [place.name, view, t])
				var p := place.target_position(t)
				assert_false(_cam.is_position_behind(p), "%s %s: %s is behind the camera" % [place.name, view, t])
				var s := _cam.unproject_position(p)
				assert_true(PlayHud.FREE.has_point(s), "%s %s: %s is off the free band at %s" % [place.name, view, t, s])
				var r := _screen_radius(p, place.target_radius(t))
				assert_gte(r * 2.0, LifeReach.FINGER_PX, "%s %s: %s is %.0f px across" % [place.name, view, t, r * 2.0])
				if place is LeafPlace:
					var leaf := place as LeafPlace
					assert_true(leaf.space.clear_line(leaf.to_local(_cam.global_position), leaf.to_local(p)),
						"%s %s: nothing hides %s" % [place.name, view, t])
				for other: String in seen:
					assert_gt(s.distance_to(seen[other]), LifeReach.FINGER_PX * 0.5,
						"%s %s: %s and %s are a fingertip apart on the screen" % [place.name, view, t, other])
				seen[t] = s


func test_in_vr_the_hands_reach_what_they_take_or_squeeze_and_the_laser_the_rest() -> void:
	for place in _places():
		var start_eye := place.vr_stand(place.start_view).origin
		for t: String in place.target_names():
			if place.hand_targets().has(t):
				var stand := place.vr_stand(place.stand_for(t))
				var d := stand.origin.distance_to(place.target_position(t))
				assert_lte(d, HAND, "%s: %s is %.2f m from its stand's eyes" % [place.name, t, d])
			var far := start_eye.distance_to(place.target_position(t))
			assert_lte(far, PlayHost.LASER, "%s: the laser reaches %s (%.1f m)" % [place.name, t, far])


func test_only_warmed_shaders_no_shadows_one_light_and_nothing_to_read() -> void:
	var census := {}
	var labels := 0
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			census[ShaderWarmup.key({"material": d.material, "instanced": d.get("instanced", false)})] = true
	var places: Array[Node3D] = []
	places.append_array(_places())
	var dive := LeafDive.new()
	add_child_autofree(dive)
	places.append(dive)
	for place: Node3D in places:
		if place is LifeRoom:
			(place as LifeRoom).glow((place as LifeRoom).target_names())
		for g: Node in place.find_children("*", "GeometryInstance3D", true, false):
			assert_eq((g as GeometryInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				"%s %s casts no shadow" % [place.name, g.name])
			if g is Label3D:
				labels += 1
				continue
			for d: Dictionary in ShaderWarmup.draws_of(g):
				if not d.has("material"):
					continue
				var k := ShaderWarmup.key({"material": d.material, "instanced": d.instanced})
				assert_true(census.has(k), "%s %s: %s (instanced %s) is not warmed" % [place.name, g.name, d.material,
					d.instanced])
		var lights := place.find_children("*", "Light3D", true, false)
		assert_lte(lights.size(), 1, "%s: one light" % place.name)
		for l: Node in lights:
			assert_false((l as Light3D).shadow_enabled, "%s: no shadows" % place.name)
	assert_eq(labels, 0, "nothing to read in the places (rule 0)")


## B2 (finding 5): a voyage opens from the menu's School, so everything it draws is warmed before the menu shows
## (ShaderWarmup.FIRST: the census saw it on screen in the menu's phase, tools/shader_probe_steps.gd's `leaf`): the
## web never compiles a shader mid-voyage. The places, the avatar and Hoot.
func test_everything_a_voyage_draws_is_warmed_before_the_menu() -> void:
	var tiers := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			var k := ShaderWarmup.key({"material": d.material, "instanced": d.get("instanced", false)})
			tiers[k] = mini(int(tiers.get(k, ShaderWarmup.LATER)), ShaderWarmup.tier(d))
	var places: Array[Node3D] = []
	places.append_array(_places())
	var dive := LeafDive.new()
	add_child_autofree(dive)
	places.append(dive)
	var kid := LeafAvatar.new()
	add_child_autofree(kid)
	kid.set_carried(2)
	places.append(kid)
	for place: Node3D in places:
		for g: Node in place.find_children("*", "GeometryInstance3D", true, false):
			for d: Dictionary in ShaderWarmup.draws_of(g):
				if not d.has("material"):
					continue
				var k := ShaderWarmup.key({"material": d.material, "instanced": d.instanced})
				assert_eq(int(tiers.get(k, ShaderWarmup.LATER)), ShaderWarmup.FIRST, "%s %s is warmed before the menu" % [
					place.name, g.name])


## The suns lighting anything under this test (the world's and the places').
func _lit_suns() -> Array[DirectionalLight3D]:
	var out: Array[DirectionalLight3D] = []
	for n: Node in find_children("*", "DirectionalLight3D", true, false):
		if (n as DirectionalLight3D).is_visible_in_tree():
			out.append(n as DirectionalLight3D)
	return out


## The rooms' look (2026-10-17) gives each room its own sun (LifeRoomSun), which puts the world's suns away while the
## room shows: the leaf's places light themselves with it, so the world 1.5 km below never lights the leaf and a night
## inside is dark (finding 4); and their weather drives that very light (a second, default sun would hide theirs).
func test_each_place_s_own_sun_is_the_only_light_while_it_shows_and_its_weather_drives_it() -> void:
	var world_sun := DirectionalLight3D.new()
	add_child_autofree(world_sun)
	var makers: Array[Callable] = [func() -> Node3D: return LeafPlace.new("sunflower"),
		func() -> Node3D: return LeafPlace.new("cactus"), func() -> Node3D: return LeafGarden.new(),
		func() -> Node3D: return LeafDive.new()]
	for make: Callable in makers:
		var place: Node3D = make.call()
		add_child(place)
		var what := "%s %s" % [place.name, (place as LeafPlace).dressing if place is LeafPlace else ""]
		var lit := _lit_suns()
		assert_eq(lit.size(), 1, "%s: one sun lights it" % what)
		assert_true(lit.size() == 1 and place.is_ancestor_of(lit[0]), "%s: its own" % what)
		assert_false(world_sun.visible, "%s: the world's sun is put away while it shows" % what)
		var want := Color()
		if place is LeafPlace:
			var leaf := place as LeafPlace
			leaf.show_all(true)
			want = (LeafPlace.LOOKS[leaf.weather_kind] as Dictionary).sun
		elif place is LeafGarden:
			(place as LeafGarden).set_evening(true)
			want = Color("ffd2a0")
		if want != Color():
			lit = _lit_suns()
			assert_true(lit.size() == 1 and lit[0].light_color.is_equal_approx(want),
				"%s: the night or the evening reaches the light that shows" % what)
		remove_child(place)
		place.free()
		assert_true(world_sun.visible, "%s: and the world's sun is given back when it goes" % what)


## The leaf draws its own sky (tinted by its weather) in its own filmic tone, as its pictures were made: the rooms'
## default dome and daylight tone stay out of it.
func test_the_leaf_shows_its_own_sky_in_its_own_tone() -> void:
	for place in _places():
		var dome := place.get_node_or_null("Decor/Sky") as Node3D
		assert_true(dome == null or not dome.is_visible_in_tree(), "%s: no second sky dome" % place.name)
		assert_eq(place.env.tonemap_mode, Environment.TONE_MAPPER_FILMIC, "%s: its own tone" % place.name)
		assert_almost_eq(place.env.tonemap_exposure, 1.0, 0.001, "%s: its own exposure" % place.name)
