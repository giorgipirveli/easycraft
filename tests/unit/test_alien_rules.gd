extends GutTest
## Owner #86 (spec §21f): friendly aliens. Where their camp or village is (a short walk from the landing pad, on calm,
## level, safe ground: never lava, methane, a well or a crater), how an alien becomes a friend (the buddy system: a
## friendship, a present, one alien buddy who comes along into every world), the souvenirs for gold, and what the
## profile keeps (CreatureData).

const SEED := 12345

var _profile: ProfileData


func before_each() -> void:
	_profile = ProfileData.new()
	SpendRules.clear_extra()


func after_each() -> void:
	SpendRules.clear_extra()


func _shape(planet: StringName, world_seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(world_seed, planet)


func test_every_world_with_aliens_finds_a_calm_level_site_near_the_pad() -> void:
	for planet: StringName in SpaceShape.PLANETS:
		for world_seed: int in [SEED, 777, 424242]:
			var shape := _shape(planet, world_seed)
			var village := planet in [SpaceShape.BOING, SpaceShape.RAINBOW]
			var half := AlienRules.SQUARE_HALF if village else AlienRules.CAMP_HALF
			var t0 := Time.get_ticks_usec()
			var site := AlienRules.village_site(shape, world_seed) if village else AlienRules.site(shape, world_seed, [], half)
			var ms := (Time.get_ticks_usec() - t0) / 1000.0
			var at: Vector3 = site.pos
			var c := Vector2i(floori(at.x), floori(at.z))
			var pad := shape.spawn_column()
			var dist := Vector2(c - pad).length()
			assert_between(dist, 25.0, 52.0, "%s/%d: a short walk from the pad (%.0f)" % [planet, world_seed, dist])
			assert_eq(int(at.y), shape.height_at(c.x, c.y), "%s: on the ground" % planet)
			assert_true(AlienRules.safe_ground(shape, c.x, c.y), "%s/%d: calm, safe ground" % [planet, world_seed])
			var level := true
			for dz in range(-half, half + 1, AlienRules.SAMPLE_STEP):
				for dx in range(-half, half + 1, AlienRules.SAMPLE_STEP):
					level = level and absi(shape.height_at(c.x + dx, c.y + dz) - int(at.y)) <= AlienRules.STEP_MAX
			assert_true(level, "%s/%d: level ground" % [planet, world_seed])
			if village:   # among the giant mushrooms and spires: none grows out of a home, the square or the chief
				assert_true(AlienRules.village_clear(shape, at, float(site.yaw)), "%s/%d: nothing grows out of it" % [
					planet, world_seed])
			else:
				var clear := true
				var reach := half + shape.feature_reach() + 2
				for dz in range(-reach, reach + 1):
					for dx in range(-reach, reach + 1):
						clear = clear and not shape.tree_at(c.x + dx, c.y + dz)
				assert_true(clear, "%s/%d: no boulder or crystal on it" % [planet, world_seed])
			var front := Vector3.FORWARD.rotated(Vector3.UP, float(site.yaw))
			var to_pad := Vector3(pad.x - c.x, 0, pad.y - c.y).normalized()
			assert_gt(front.dot(to_pad), 0.95, "%s: it faces the pad" % planet)
			assert_lt(ms, 250.0, "%s: found fast enough at a world's load (%.1f ms)" % [planet, ms])
			gut.p("SITE %s seed %d: %.0f blocks, %.1f ms" % [planet, world_seed, dist, ms])


func test_the_same_seed_puts_it_in_the_same_place_and_it_keeps_clear_of_the_landmark() -> void:
	var shape := _shape(SpaceShape.MARS)
	var a := AlienRules.site(shape, SEED)
	assert_eq(AlienRules.site(_shape(SpaceShape.MARS), SEED), a, "every game finds the same spot")
	var at: Vector3 = a.pos
	var b := AlienRules.site(shape, SEED, [{"at": Vector2(at.x, at.z), "r": AlienRules.LANDMARK_CLEAR}])
	assert_gt(Vector2(b.pos.x, b.pos.z).distance_to(Vector2(at.x, at.z)), AlienRules.LANDMARK_CLEAR - 1.0,
		"a landmark there: somewhere else")


func test_never_on_lava_methane_or_in_a_crater() -> void:
	var io := _shape(SpaceShape.IO)
	var lake := io.io.lake_centre()
	assert_false(AlienRules.safe_ground(io, lake.x, lake.y), "Io's lava lake")
	var titan := _shape(SpaceShape.TITAN)
	var sea := titan.titan.sea_beach_toward(titan.spawn_column())
	var wet := false
	for dz in range(0, 80):
		if titan.is_river(sea.x, sea.y - dz):
			wet = true
			assert_false(AlienRules.safe_ground(titan, sea.x, sea.y - dz), "Titan's methane")
			break
	assert_true(wet, "the test found the methane")
	var europa := _shape(SpaceShape.EUROPA)
	var well := europa.europa.well_centre()
	assert_false(AlienRules.safe_ground(europa, well.x, well.y), "Europa's ocean well")


func test_the_real_bodies_have_camps_and_the_playful_planets_villages() -> void:
	for u in [16, 19, 20, 21, 22, 23]:
		assert_true(AlienRules.has_camp(u), str(u))
		assert_false(AlienRules.has_village(u))
	for u in [17, 18]:
		assert_true(AlienRules.has_village(u))
		assert_false(AlienRules.has_camp(u))
	assert_false(AlienRules.has_camp(1), "never at home")
	assert_eq(AlienRules.befriendable(19), &"zib")
	assert_eq(AlienRules.befriendable(17), &"bopsy")
	assert_true(AlienRules.can_befriend(&"zib"))
	assert_false(AlienRules.can_befriend(&"quix"), "a trader trades")


func test_an_explorer_becomes_a_friend_for_a_sample_and_gives_a_present() -> void:
	var data := _profile.creatures
	assert_eq(AlienRules.state(data, &"zib", false), AlienRules.NEW)
	data.meet(&"zib")
	assert_eq(AlienRules.state(data, &"zib", false), AlienRules.WANTS, "it asks for a sample")
	assert_eq(AlienRules.state(data, &"zib", true), AlienRules.CAN_GIVE, "the rover dug one")
	var gift := AlienRules.befriend(_profile, &"zib")
	assert_eq(gift, "gift_zib")
	assert_true(data.owns("gift_zib"), "its present")
	assert_eq(AlienRules.state(data, &"zib", true), AlienRules.FRIEND)
	assert_true(_profile.buddy_magic.minis.has("alien_zib"), "its mini-buddy's record waits (the buddy system)")
	assert_eq(AlienRules.befriend(_profile, &"zib"), "", "once")
	assert_eq(AlienRules.befriend(_profile, &"quix"), "", "a trader is not a buddy")


func test_one_alien_buddy_comes_along_at_a_time() -> void:
	AlienRules.befriend(_profile, &"zib")
	AlienRules.befriend(_profile, &"nuri")
	assert_false(AlienRules.comes_along(_profile, &"alien_zib"), "a friend waits at its camp until asked")
	assert_true(AlienRules.comes_along(_profile, BossRules.GOLEM), "a boss's mini always comes")
	assert_eq(AlienRules.come_along(_profile, &"zib"), "")
	assert_eq(AlienRules.state(_profile.creatures, &"zib", false), AlienRules.BUDDY)
	assert_true(AlienRules.comes_along(_profile, &"alien_zib"))
	assert_eq(AlienRules.come_along(_profile, &"nuri"), "zib", "Zib goes back to its camp")
	assert_false(AlienRules.comes_along(_profile, &"alien_zib"))
	assert_true(AlienRules.comes_along(_profile, &"alien_nuri"))
	assert_true(_profile.creatures.is_friend(&"zib"), "still friends")
	assert_eq(AlienRules.come_along(_profile, &"blip"), "", "not a friend yet: nothing changes")
	assert_eq(_profile.creatures.buddy, "nuri")
	assert_eq(AlienRules.stay_home(_profile), "nuri")
	assert_false(AlienRules.comes_along(_profile, &"alien_nuri"))


func test_an_alien_buddy_is_a_mini_buddy_with_its_own_tiny_look() -> void:
	for u: int in [16, 17, 18, 19, 20, 21, 22, 23]:
		var id := AlienRules.befriendable(u)
		var kind := AlienRules.mini_kind(id)
		assert_true(MiniRules.gives_mini(kind), "%s is a mini-buddy kind" % kind)
		assert_true(AlienRules.is_alien_kind(kind))
		assert_eq(AlienRules.alien_of_kind(kind), id)
		assert_eq(MiniRules.kind_of_id(MiniRules.animal_id(kind, 3)), kind, "its animal id reads back")
		var record := MiniRules.record(kind)
		assert_eq(str(record.name), CreatureWords.alien_name(id), "its own name")
		assert_true(PetDirector.is_profile_pet(MiniRules.animal_id(kind, 3)), "worlds never save it: it lives in the profile")
	assert_false(AlienRules.is_alien_kind(BossRules.GOLEM))


func test_souvenirs_cost_gold_once_and_hang_on_the_gold_shops_shelf() -> void:
	_profile.survivor_gold = 100
	assert_eq(AlienRules.stock(&"quix"), ["sun_marble", "singing_pebble"] as Array[String])
	assert_eq(AlienRules.buy(_profile, "sun_marble"), SpendRules.OK)
	assert_eq(_profile.survivor_gold, 20)
	assert_true(_profile.creatures.owns("sun_marble"))
	assert_eq(AlienRules.buy(_profile, "sun_marble"), SpendRules.OWNED)
	assert_eq(AlienRules.buy(_profile, "singing_pebble"), SpendRules.NOT_ENOUGH)
	assert_eq(AlienRules.buy(_profile, "gift_zib"), SpendRules.UNKNOWN, "a present is never sold")
	var shelf := SpendRules.items(SpendRules.DECOR, _profile)
	var names := shelf.map(func(it: Dictionary) -> String: return str(it.name))
	assert_true(names.has("Three-Sun Marble"), "on the DECORATIONS shelf")
	assert_false(names.has("Glimmer Gem"), "no presents there")
	var marble: Array = shelf.filter(func(it: Dictionary) -> bool: return it.id == "alien:sun_marble")
	assert_true(bool(marble[0].owned))
	_profile.survivor_gold = 500
	assert_eq(SpendRules.buy(_profile, "alien:star_compass"), SpendRules.OK, "bought in the Gold Shop too")
	assert_true(_profile.creatures.owns("star_compass"))


func test_the_profile_keeps_friends_questions_and_souvenirs() -> void:
	var d := _profile.creatures
	d.meet(&"blip")
	AlienRules.befriend(_profile, &"zib")
	AlienRules.come_along(_profile, &"zib")
	d.pay_question("mars_red")
	d.add_souvenir("sun_marble")
	assert_false(d.meet(&"nobody"), "unknown aliens are dropped")
	assert_false(d.pay_question("nope"))
	assert_false(d.add_souvenir("rock"))
	var back := ProfileData.from_json(_profile.to_json())
	assert_eq(back.creatures.to_dict(), d.to_dict(), "saved and loaded")
	assert_true(back.buddy_magic.minis.has("alien_zib"), "its mini-buddy's record too")
	var junk := CreatureData.from_dict({"met": ["blip", 5, "nobody"], "friends": ["pim"], "buddy": "zib",
		"quiz": ["mars_red", "x"], "souvenirs": ["gift_pim", null]})
	assert_eq(junk.met, ["blip", "pim"] as Array[String])
	assert_eq(junk.buddy, "", "a buddy must be a friend")
	assert_eq(junk.quiz, ["mars_red"] as Array[String])
	assert_eq(CreatureData.from_dict("broken").to_dict(), CreatureData.new().to_dict())


func test_a_backup_merge_never_loses_a_friend() -> void:
	var a := CreatureData.new()
	a.befriend(&"zib")
	a.pay_question("mars_red")
	var b := CreatureData.new()
	b.befriend(&"nuri")
	b.buddy = "nuri"
	b.add_souvenir("ice_flute")
	a.merge_from(b)
	assert_true(a.is_friend(&"zib") and a.is_friend(&"nuri"))
	assert_eq(a.buddy, "nuri", "the other copy's buddy when this one has none")
	assert_true(a.owns("ice_flute") and a.paid("mars_red"))
	var mine := ProfileData.new()
	mine.survivor_gold = 99
	mine.creatures.befriend(&"blip")
	mine.updated_at = 10
	var theirs := ProfileData.new()
	theirs.creatures.befriend(&"pim")
	theirs.updated_at = 20
	var merged: ProfileData = ProfileBackup.merge(mine, theirs.to_json()).profile
	assert_true(merged.creatures.is_friend(&"blip") and merged.creatures.is_friend(&"pim"), "both copies' friends")
	assert_false(ProfileBackup.is_new(mine), "a friend is progress")
