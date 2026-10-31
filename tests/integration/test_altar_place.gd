extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.11, §4.4-4.6; G0's place contract): Balance Altar's places
## keep the contracts G0's host and the phones and headsets need. From each altar view every thing to tap is in the free
## band of a 16:9 screen (PlayHud.FREE), at least a fingertip across (LifeReach.FINGER_PX), and never so near another
## that a finger could pick the wrong one; in VR every thing the hands take is within 1.1 m of the stand's eyes (and the
## laser reaches the rest); every material is one the warm-up already holds (the census's draw, instanced or not),
## nothing casts a shadow, the place's own sun is its only light, and nothing is written (the rune line is carved
## geometry: the subject, never a label). The altar shows exactly the pans it is given, and its plaque carves the rune
## line.

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


## A full altar: crystals and gems on the left, gems and balloons on the right (every target has something there).
func _full() -> AltarState:
	return AltarState.make(2, 3, 0, -2, 3)


## Every place at its fullest, each altar view focused.
func _places() -> Array[AltarRoom]:
	var out: Array[AltarRoom] = []
	var hall := TempleHall.new()
	add_child_autofree(hall)
	hall.show_altar(_full(), {})
	out.append(hall)
	var great := TempleHall.new()
	add_child_autofree(great)
	great.raise_great(1.0)
	great.show_altar(AltarState.make(2, 1, 0, -3, 2), {})
	out.append(great)
	var sky := SkyRoom.new()
	add_child_autofree(sky)
	sky.show_altar(_full(), {})
	out.append(sky)
	return out


func _screen_radius(world_at: Vector3, radius: float) -> float:
	var centre := _cam.unproject_position(world_at)
	var side := _cam.global_basis.x * radius
	return centre.distance_to(_cam.unproject_position(world_at + side))


func test_every_thing_to_tap_is_in_the_free_band_a_fingertip_across_and_apart() -> void:
	for place in _places():
		assert_false(place.flat_views().is_empty(), "%s has views" % place.name)
		for view: String in place.flat_views():
			_cam.global_transform = place.camera_transform(view)
			var seen := {}
			var targets := place.flat_targets(view)
			for t: String in targets:
				assert_true(place.has_target(t), "%s %s: %s is a target" % [place.name, view, t])
				var p := place.target_position(t)
				assert_false(_cam.is_position_behind(p), "%s %s: %s is behind the camera" % [place.name, view, t])
				var s := _cam.unproject_position(p)
				assert_true(PlayHud.FREE.has_point(s), "%s %s: %s is off the free band at %s" % [place.name, view, t, s])
				var r := _screen_radius(p, place.target_radius(t))
				assert_gte(r * 2.0, LifeReach.FINGER_PX, "%s %s: %s is %.0f px across" % [place.name, view, t, r * 2.0])
				for other: String in seen:
					assert_gt(s.distance_to(seen[other]), LifeReach.FINGER_PX * 0.5,
						"%s %s: %s and %s are a fingertip apart on the screen" % [place.name, view, t, other])
				seen[t] = s


func test_the_altar_view_offers_every_tool_of_the_room() -> void:
	var places := _places()
	var hall := places[0]
	var targets := hall.flat_targets(hall.start_view)
	for t: String in ["gems_0", "gems_1", "crystal", "bowls", "seal", "bag", "runes"]:
		assert_has(targets, t, "the hall's altar: %s" % t)
	assert_does_not_have(targets, "pump", "no balloon pump in the hall")
	var sky := places[2]
	for t: String in ["pump", "balloons_1", "bag", "bowls"]:
		assert_has(sky.flat_targets(sky.start_view), t, "the Sky Room's altar: %s" % t)


func test_in_vr_the_hands_reach_what_they_take_and_the_laser_the_rest() -> void:
	for place in _places():
		var start_eye := place.vr_stand(place.start_view).origin
		assert_false(place.hand_targets().is_empty(), "%s: the hands take things" % place.name)
		for t: String in place.target_names():
			if place.hand_targets().has(t):
				var stand := place.vr_stand(place.stand_for(t))
				var d := stand.origin.distance_to(place.target_position(t))
				assert_lte(d, HAND, "%s: %s is %.2f m from its stand's eyes" % [place.name, t, d])
			var far := start_eye.distance_to(place.target_position(t))
			assert_lte(far, PlayHost.LASER, "%s: the laser reaches %s (%.1f m)" % [place.name, t, far])


func test_the_two_pans_are_a_two_hand_reach_apart() -> void:
	for place in _places():
		var stand := place.vr_stand(place.start_view)
		var left := place.target_position("gems_0")
		var right := place.target_position("gems_1")
		assert_between(left.distance_to(right), 0.55, 1.1, "%s: the pans' piles, one a hand" % place.name)
		var to_left := stand.basis.inverse() * (left - stand.origin)
		var to_right := stand.basis.inverse() * (right - stand.origin)
		assert_lt(to_left.x, 0.0, "%s: the left pan is on the left" % place.name)
		assert_gt(to_right.x, 0.0, "%s: the right pan on the right" % place.name)


func test_only_warmed_shaders_no_shadows_one_light_and_nothing_written() -> void:
	var census := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			census[ShaderWarmup.key({"material": d.material, "instanced": d.get("instanced", false)})] = true
	var places: Array[Node3D] = []
	places.append_array(_places())
	var arrival := TempleArrival.new()
	add_child_autofree(arrival)
	arrival.set_door_open(true)
	places.append(arrival)
	var labels := 0
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
		var lights := place.find_children("*", "Light3D", true, false).filter(func(l: Node) -> bool:
			return (l as Light3D).is_visible_in_tree())
		assert_eq(lights.size(), 1, "%s: one light, its own" % place.name)
		for l: Node in lights:
			assert_false((l as Light3D).shadow_enabled, "%s: no shadows" % place.name)
	assert_eq(labels, 0, "nothing written in the places: the rune line is carved geometry (rule 0)")


func test_each_place_s_own_sun_puts_the_world_s_away_while_it_shows() -> void:
	var world_sun := DirectionalLight3D.new()
	add_child_autofree(world_sun)
	var makers: Array[Callable] = [func() -> Node3D: return TempleHall.new(), func() -> Node3D: return SkyRoom.new(),
		func() -> Node3D: return TempleArrival.new()]
	for make: Callable in makers:
		var place: Node3D = make.call()
		add_child(place)
		assert_false(world_sun.visible, "%s: the world's sun is put away while it shows" % place.name)
		remove_child(place)
		place.free()
		assert_true(world_sun.visible, "and given back when it goes")


func test_the_altar_shows_exactly_the_pans_it_is_given() -> void:
	var hall := TempleHall.new()
	add_child_autofree(hall)
	hall.show_altar(AltarState.make(2, 3, 0, 9, 3), {})
	var altar := hall.altar
	assert_eq(altar.shown(AltarState.LEFT), {"crystal": 2, "gem": 3, "balloon": 0})
	assert_eq(altar.shown(AltarState.RIGHT), {"crystal": 0, "gem": 9, "balloon": 0})
	assert_eq(altar.lifted_count(), 0)
	hall.show_altar(AltarState.make(2, 3, 0, 9, 3), {"pan": 0, "verb": "lift", "kind": "gem", "count": 2, "twins": 1})
	assert_eq(altar.lifted_count(), 3, "two lifted off the left pan, one off the right: they rise, amber")
	var sky := SkyRoom.new()
	add_child_autofree(sky)
	sky.show_altar(AltarState.make(1, -3, 0, 5, 8), {})
	assert_eq(sky.altar.shown(AltarState.LEFT), {"crystal": 1, "gem": 0, "balloon": 3})
	assert_true(sky.altar.chained(), "frozen: the chains hold the beam")
	sky.show_altar(AltarState.make(1, 0, 0, 8, 8), {}, true)
	assert_false(sky.altar.chained(), "freed: the chains snap")
	assert_true(sky.altar.glimmer_awake(), "the Glimmer wakes beside its crystal")


func test_the_plaque_carves_the_rune_line_at_its_stage() -> void:
	var hall := TempleHall.new()
	add_child_autofree(hall)
	var s := AltarState.make(1, 3, 0, 7, 4)
	for stage in [AltarRunes.PICTURES, AltarRunes.NUMBERS, AltarRunes.LETTERS]:
		hall.altar.stage = stage
		hall.show_altar(s, {})
		assert_eq(hall.altar.carved_line(), AltarRunes.line(s, stage), "stage %d" % stage)
	assert_gt(hall.altar.rune_count(), 0, "the runes are carved geometry")


func test_the_hall_s_ring_turns_its_chandelier_lights_and_the_great_altar_rises() -> void:
	var hall := TempleHall.new()
	add_child_autofree(hall)
	assert_eq(hall.slots(), 10, "ten altars in a ring (§3.5)")
	hall.set_active(3)
	assert_true(hall.ring_hidden(3), "the active altar's slot shows the full altar, not the ring's model")
	assert_false(hall.ring_hidden(2))
	hall.set_freed([0, 1, 2])
	assert_eq(hall.freed_count(), 3)
	hall.set_lit(4)
	assert_eq(hall.lit_count(), 4)
	assert_eq(hall.socket_count(), 11, "eleven crystal sockets")
	assert_false(hall.great_visible())
	hall.raise_great(1.0)
	assert_true(hall.great_visible())
	hall.set_door_open(true)
	assert_true(hall.door_open())


func test_every_glimmer_has_both_poses() -> void:
	for kind: String in AltarHalls.GLIMMERS:
		for pose: String in [GlimmerModel.ASLEEP, GlimmerModel.AWAKE]:
			var m := GlimmerModel.mesh(kind, pose)
			assert_gt(m.get_surface_count(), 0, "%s %s" % [kind, pose])
			var box := m.get_aabb()
			assert_between(box.size.y, 0.04, 0.2, "%s %s fits in a 22 cm crystal or beside it" % [kind, pose])
