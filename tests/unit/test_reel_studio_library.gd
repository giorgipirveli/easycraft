extends GutTest
## Owner #96 (spec §5.12b, the Reel Studio): the cinematic reels. Each is a Short the checker passes and the feed lists;
## every number on the screen is worked out again from the game's own tables (a reel and the game never disagree); a
## video reel's video is here, plays, is as long as its Short, is small enough for a phone and never shows a black or
## blank frame (ReelPack, assets/reels/reels.json from tools/reel_render.sh).

const LIVE: Array[String] = ["rocket_launch", "moon_landing", "solar_orrery", "build_rocket"]
const VIDEO: Array[String] = ["saturn_up_close", "moon_colony", "venus_city", "seven_wonders_flyover"]
const PLANETS: Array[StringName] = [&"mercury", &"venus", &"earth", &"mars", &"jupiter", &"saturn", &"uranus", &"neptune"]


func after_each() -> void:
	ShortLibrary.clear_cache()


func _reel(id: String) -> Dictionary:
	return ShortLibrary.get_short(id)


func _words(s: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for scene: Dictionary in s.scenes:
		out.append(str(scene.caption))
		out.append(str(scene.say))
		for a: Dictionary in scene.get("actors", []):
			if a.has("text"):
				out.append(str(a.text))
	return out


func test_every_reel_checks_and_is_in_the_feed() -> void:
	var feed := ShortLibrary.hand_ids()
	for id in LIVE + VIDEO:
		var s := _reel(id)
		assert_false(s.is_empty(), id)
		assert_eq(ShortCheck.problems(s), [] as Array[String], id)
		assert_true(feed.has(id), "%s is in data/shorts/shorts.json" % id)
		assert_true(s.has("stage"), "%s has its 3D stage" % id)
		var secs := ShortTimeline.length(s)
		assert_between(secs, 30.0, 60.0, "%s: 30-60 s" % id)
	for id in LIVE:
		assert_false(_reel(id).has("video"), "%s plays live (cheap on a phone: test_reel_studio_bench notes)" % id)
	for id in VIDEO:
		assert_eq(str(_reel(id).get("video")), id, "%s is a rendered video" % id)


func test_the_videos_are_here_small_as_long_as_their_reels_and_never_black() -> void:
	var total := 0
	for id in VIDEO:
		assert_eq(ReelCheck.problems(_reel(id)), [] as Array[String], id)
		total += FileAccess.get_file_as_bytes(ReelPack.video_path(id)).size()
	assert_lte(total, ReelPack.ANDROID_CAP, "all together fit the APK (%d KiB)" % (total / 1024))
	for id in LIVE:
		assert_eq(ReelCheck.problems(_reel(id)), [] as Array[String], id)


func test_the_checker_finds_what_is_wrong_with_a_video() -> void:
	var s := _reel("saturn_up_close").duplicate(true)
	s.video = "no_such_reel"
	assert_string_contains("\n".join(ReelCheck.problems(s)), "no video")
	s = _reel("saturn_up_close").duplicate(true)
	s.scenes[4].seconds = 16
	assert_string_contains("\n".join(ReelCheck.problems(s)), "plays", "a video as long as its Short")
	s = _reel("saturn_up_close").duplicate(true)
	s.stage.camera[0].at = 1.0
	assert_string_contains("\n".join(ReelCheck.problems(s)), "key at 0")


func test_the_launch_s_numbers_are_the_rocket_s() -> void:
	var r := RocketCheck.check(StudioRockets.cells("moon"), MissionRules.for_world(SpaceRules.MOON))
	var words := "\n".join(_words(_reel("rocket_launch")))
	assert_string_contains(words, "PUSH %s t" % ShortActor.number_words(float(r.push)), "9 engines × 250 t")
	assert_eq(float(r.push), 9.0 * RocketParts.push(BlockIds.ROCKET_ENGINE))
	assert_string_contains(words, "WEIGHT %s t" % ShortActor.number_words(roundf(float(r.mass))))
	assert_gt(float(r.push), float(r.mass) * RocketCheck.LIFT_MARGIN, "push beats weight: it lifts off")
	assert_string_contains(words, "three stages")
	assert_eq((r.stages as Array).size(), 3)


func test_the_build_s_parts_are_the_rocket_s() -> void:
	var s := _reel("build_rocket")
	var rocket := StudioRockets.rocket("moon")
	var built := {}
	for g: Dictionary in StudioRules.model(s.stage, "rocket").build:
		for b: Variant in g.blocks:
			built[ShortCheck.block_id(b)] = true
	for id: int in RocketParts.count(rocket.cells):
		assert_true(built.has(id), "every part drops in: %s" % BlockIds.display_name(id))


func test_the_orrery_goes_round_at_the_real_years() -> void:
	var s := _reel("solar_orrery")
	var earth_period := 0.0
	for id: StringName in PLANETS:
		var m := StudioRules.model(s.stage, str(id))
		assert_false(m.is_empty(), "%s is there" % id)
		var orbit: Dictionary = m.moves[0]
		if id == &"earth":
			earth_period = float(orbit.period)
	assert_almost_eq(earth_period, 10.0, 0.001, "one Earth year is 10 s (the sticker says so)")
	var days := StarMap.days_since_2000(1790856000.0)   # 2026-10-01 12:00 UTC
	for id: StringName in PLANETS:
		var m := StudioRules.model(s.stage, str(id))
		assert_almost_eq(float(m.moves[0].period), 10.0 * StarMap.year_days(id) / StarMap.year_days(&"earth"), 0.01,
			"%s: its real year's share" % id)
		var at := StudioRules.vec(m.at)
		var lon := atan2(-at.z, at.x)
		assert_almost_eq(angle_difference(lon, StarMap.longitude(id, days)), 0.0, 0.01,
			"%s starts where it was on 1 October 2026" % id)
		assert_eq(int(m.moves[0].dir), 1, "anticlockwise seen from the Sun's north")
	var words := "\n".join(_words(s))
	assert_string_contains(words, "88 days")
	assert_almost_eq(StarMap.year_days(&"mercury"), 88.0, 0.5)
	assert_string_contains(words, "12 years")
	assert_almost_eq(StarMap.year_days(&"jupiter") / 365.25, 11.86, 0.01)
	assert_string_contains(words, "29 years")
	assert_almost_eq(StarMap.year_days(&"saturn") / 365.25, 29.46, 0.02)
	assert_string_contains(words, "165")
	assert_almost_eq(StarMap.year_days(&"neptune") / 365.25, 164.8, 0.2)


func test_the_moon_and_space_facts_are_the_star_map_s() -> void:
	var facts := func(id: StringName) -> String: return "\n".join(StarMap.body(id).facts)
	assert_string_contains(facts.call(&"moon"), "6 times higher")
	assert_string_contains("\n".join(_words(_reel("moon_landing"))), "6 × HIGHER")
	assert_string_contains(facts.call(&"moon"), "1969", "the first landing's year")
	assert_string_contains("\n".join(_words(_reel("moon_landing"))), "1969")
	assert_string_contains(facts.call(&"venus"), "465 °C")
	assert_string_contains("\n".join(_words(_reel("venus_city"))), "465 °C")
	assert_string_contains(facts.call(&"saturn"), "ice and rock")
	assert_string_contains("\n".join(_words(_reel("saturn_up_close"))), "ice and rock")
	assert_string_contains(facts.call(&"saturn"), "as big as houses")


func test_the_wonders_are_the_tour_s_seven() -> void:
	var s := _reel("seven_wonders_flyover")
	for id: StringName in WonderFacts.ANCIENT:
		var m := StudioRules.model(s.stage, str(id))
		assert_eq(str(m.get("wonder", "")), str(id), "%s flies by, as world 41 builds it" % id)
	var words := "\n".join(_words(s))
	assert_string_contains(str(WonderFacts.WONDERS.pyramid.built), "4,500 years")
	assert_string_contains(words, "4,500 years")
	assert_string_contains("\n".join(WonderFacts.TOUR_FACTS), "Only the Great Pyramid still stands")
	assert_string_contains(words, "Six")
	assert_string_contains("\n".join(WonderFacts.WONDERS.artemis.facts), "more than 100 marble columns")
	assert_string_contains(words, "over 100")
