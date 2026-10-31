extends GutTest
## Owner #94 (spec §5.12b): the hand-made Shorts (data/shorts). Every one is valid (ShortCheck: its actors, pictures,
## seconds, words and link), there are at least 16, the index lists every file once, the words are kind, British and in
## the font, and every fact is real: the numbers a Short says are worked out again here from the game's own tables
## (RocketParts, MissionRules, StarMap, WonderFacts) or from the sources in docs/devlog/parts/shorts.md.

const NO_GUILT := "res://tests/unit/test_no_guilt_words.gd"
const SCHOOL := "res://tests/unit/test_school_content.gd"
## Surface gravity, m/s² (NASA's planetary fact sheets; Jupiter at its cloud tops).
const GRAVITY := {"earth": 9.81, "moon": 1.62, "mars": 3.71, "jupiter": 24.79, "pluto": 0.62}
## A good standing jump on Earth, the Short's start: 30 cm.
const EARTH_JUMP_CM := 30.0
## Where the Seven Wonders of the Ancient World stood (latitude, longitude): the sites' own coordinates.
const WONDER_PLACES := {"Pyramid": [29.979, 31.134], "Babylon": [32.536, 44.421], "Artemis": [37.950, 27.364],
	"Zeus": [37.638, 21.630], "Mausoleum": [37.038, 27.424], "Colossus": [36.451, 28.226], "Lighthouse": [31.214, 29.885]}
## The Moon's phases repeat every 29.53 days (the synodic month; NASA).
const SYNODIC_MONTH := 29.53


func after_each() -> void:
	ShortLibrary.clear_cache()
	Curriculum.clear_cache()


func _short(id: String) -> Dictionary:
	var s := ShortLibrary.hand(id)
	assert_false(s.is_empty(), "%s loads" % id)
	return s


func _texts(s: Dictionary) -> Array[String]:
	var out: Array[String] = [str(s.title)]
	for scene: Dictionary in s.scenes:
		out.append(str(scene.caption))
		out.append(str(scene.say))
		for a: Dictionary in scene.actors:
			for key: String in ["text", "prefix", "suffix"]:
				if a.has(key):
					out.append(str(a[key]))
			for p: Dictionary in a.get("points", []):
				out.append(str(p.get("label", "")))
	return out


## Every text of every hand-made Short, joined, lower case.
func _all_words() -> Array[String]:
	var out: Array[String] = []
	for id in ShortLibrary.hand_ids():
		out.append_array(_texts(_short(id)))
	return out


func _actors(s: Dictionary, kind: String) -> Array:
	var out: Array = []
	for scene: Dictionary in s.scenes:
		for a: Dictionary in scene.actors:
			if a.kind == kind:
				out.append(a)
	return out


func _has_words(s: Dictionary, text: String) -> bool:
	for t in _texts(s):
		if t.contains(text):
			return true
	return false


func _counts_to(s: Dictionary) -> Array:
	var out: Array = []
	for a in _actors(s, "count"):
		out.append(float(a.to))
	return out


# --- The set --------------------------------------------------------------------------------------------------------

func test_every_hand_made_short_is_valid() -> void:
	var ids := ShortLibrary.hand_ids()
	assert_gte(ids.size(), 16, "at least 16 hand-made Shorts")
	for id in ids:
		assert_eq(ShortCheck.problems(_short(id)), [] as Array[String], id)


func test_the_index_lists_every_file_once() -> void:
	var files: Array[String] = []
	for f in DirAccess.get_files_at(ShortLibrary.DIR):
		if f.ends_with(".json") and f != "shorts.json":
			files.append(f.trim_suffix(".json"))
	for f in DirAccess.get_files_at(ShortLibrary.CINEMATIC):   # owner #96: the Reel Studio's cinematic reels
		if f.ends_with(".json"):
			files.append(f.trim_suffix(".json"))
	files.sort()
	var listed := ShortLibrary.hand_ids().duplicate()
	listed.sort()
	assert_eq(listed, files)


func test_the_brief_topics_are_all_there() -> void:
	for id: String in ["rocket_parts", "rocket_push", "rocket_stages", "crew_flight", "planet_orbits", "moon_phases",
			"jump_gravity", "venus_hot", "saturn_rings", "moon_ice_fuel", "lever_lift", "water_cycle", "photosynthesis",
			"pizza_fractions", "place_value", "food_chain", "bulb_circuit", "seven_wonders"]:
		assert_true(ShortLibrary.hand_ids().has(id), id)


func test_each_is_one_idea_in_3_to_6_scenes_ending_with_a_question() -> void:
	for id in ShortLibrary.hand_ids():
		var s := _short(id)
		var n: int = s.scenes.size()
		assert_true(n >= 3 and n <= 6, "%s: %d scenes" % [id, n])
		var length := ShortTimeline.length(s)
		assert_true(length >= 20.0 and length <= 60.0, "%s: %.1f s" % [id, length])
		assert_true(str(s.scenes[n - 1].caption).ends_with("?"), "%s ends with a question to wonder about" % id)
		assert_true(str(s.scenes[n - 1].say).ends_with("?"), "%s's voice asks it too" % id)


func test_the_words_are_kind_british_and_in_the_font() -> void:
	var banned: Array = (load(NO_GUILT) as GDScript).get_script_constant_map().BANNED
	var school := (load(SCHOOL) as GDScript).get_script_constant_map()
	var found: Array[String] = []
	for t in _all_words():
		var lower := t.to_lower()
		for w: String in banned + Array(school.UNKIND) + Array(school.US_SPELLINGS):
			if RegEx.create_from_string("\\b" + w + "\\b").search(lower):
				found.append("'%s' in: %s" % [w, t])
		for ch in t:
			if ch.unicode_at(0) > 127 and not str(school.ALLOWED).contains(ch):
				found.append("'%s' in: %s" % [ch, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


## Owner #94's learning reels, round 2: "How gold is found" teaches the metal itself (the game's prospecting: quartz
## veins, flakes in river gravel, panning). There "gold" is the subject, never a reward; every other word stays banned.
const GOLD_IS_THE_SUBJECT: Array[String] = ["gold_prospecting"]


func test_nothing_rewards_watching() -> void:
	for id in ShortLibrary.hand_ids():
		for t in _texts(_short(id)):
			var lower := t.to_lower()
			for w: String in ["gold", "coins", "points", "reward", "prize", "keep watching", "watch more"]:
				if w == "gold" and GOLD_IS_THE_SUBJECT.has(id):
					continue
				assert_false(RegEx.create_from_string("\\b" + w + "\\b").search(lower) != null, "'%s' in: %s" % [w, t])


# --- Rockets: the game's own numbers (RocketParts, RocketCheck, MissionRules) ---------------------------------------

func test_rocket_parts_numbers_are_the_games() -> void:
	var s := _short("rocket_parts")
	assert_eq(RocketParts.fuel(BlockIds.FUEL_TANK), 94.0, "a tank holds 94 t of fuel and oxygen")
	assert_true(_counts_to(s).has(94.0))
	assert_true(_has_words(s, "94 tonnes"))
	assert_eq(RocketCheck.FINS_NEEDED, 3, "three fins")
	assert_true(_has_words(s, "3 FINS"))
	assert_eq(RocketParts.seats(BlockIds.CREW_CAPSULE), 1, "a seat for one astronaut")
	assert_true(RocketCheck._pointed({Vector3i.ZERO: BlockIds.CREW_CAPSULE}), "the capsule's cone is a pointed top")


func test_rocket_push_is_the_lift_off_rule() -> void:
	var s := _short("rocket_push")
	var push := RocketParts.push(BlockIds.ROCKET_ENGINE)
	var tank := RocketParts.mass_full(BlockIds.FUEL_TANK)
	var engine := RocketParts.mass_full(BlockIds.ROCKET_ENGINE)
	assert_eq(push, 250.0)
	assert_eq(tank, 100.0)
	var two := 2.0 * tank + engine
	var three := 3.0 * tank + engine
	var two_engines := 3.0 * tank + 2.0 * engine
	assert_eq([two, three, two_engines], [204.0, 304.0, 308.0])
	assert_lte(two * RocketCheck.LIFT_MARGIN, push, "204 t lifts on one engine")
	assert_gt(three * RocketCheck.LIFT_MARGIN, push, "304 t does not")
	assert_lte(two_engines * RocketCheck.LIFT_MARGIN, 2.0 * push, "two engines lift 308 t")
	for n in [204.0, 304.0, 308.0, 500.0, 250.0]:
		assert_true(_counts_to(s).has(n) or _has_words(s, "%d t" % int(n)), "%d on the screen" % int(n))
	# The puzzle: five full tanks need three engines.
	var engines := 1
	while (5.0 * tank + engines * engine) * RocketCheck.LIFT_MARGIN > engines * push:
		engines += 1
	assert_eq(engines, 3)


func test_rocket_stages_speeds_and_tanks() -> void:
	var s := _short("rocket_stages")
	var moon: Dictionary = MissionRules.MISSIONS[0]
	assert_eq(str(moon.id), "moon")
	assert_almost_eq(MissionRules.need(moon), 15.3, 0.001)
	assert_true(_counts_to(s).has(15.3))
	assert_eq(RocketParts.mass_full(BlockIds.FUEL_TANK), 100.0)
	assert_eq(RocketParts.mass_empty(BlockIds.FUEL_TANK), 6.0)
	assert_true(_counts_to(s).has(6.0))


func test_crew_flight_supplies_are_worked_out_like_the_board() -> void:
	var s := _short("crew_flight")
	var mars: Dictionary = MissionRules.MISSIONS[1]
	assert_eq(str(mars.id), "mars")
	assert_eq(int(mars.days), 210)
	assert_true(_counts_to(s).has(210.0), "the real trip")
	assert_false(_counts_to(s).has(420.0), "owner #98: no more days to add up")
	assert_eq(RocketParts.keeps(BlockIds.SERVICE_MODULE), 1, "owner #98: one module keeps one astronaut the whole way")
	var rocket := RocketPlan.cells(mars, 2)
	assert_eq(int(RocketParts.count(rocket).get(BlockIds.SERVICE_MODULE, 0)), 2, "two friends: two modules")
	assert_true(RocketCheck.check(rocket, mars, 2).ok)
	assert_false(RocketCheck.check(rocket, mars, 3).ok, "the puzzle: three friends need a third")
	assert_true(bool(mars.air), "Mars has air: a heat shield and a parachute")
	assert_eq(RocketCheck.LEGS_NEEDED, 3)


# --- Space: the Star Map's real years and facts, NASA's numbers --------------------------------------------------------

func test_the_orbits_go_round_at_the_real_years() -> void:
	var s := _short("planet_orbits")
	var earth := -1.0
	var checked := 0
	for scene: Dictionary in s.scenes:
		for a: Dictionary in scene.actors:
			if a.kind == "planet" and str(a.body) == "earth":
				for m: Dictionary in a.moves:
					if m.do == "orbit":
						earth = float(m.period)
	assert_gt(earth, 0.0)
	for scene: Dictionary in s.scenes:
		for a: Dictionary in scene.actors:
			if a.kind != "planet":
				continue
			for m: Dictionary in a.moves:
				if m.do == "orbit":
					var want := StarMap.year_days(StringName(str(a.body))) / StarMap.year_days(&"earth") * earth
					assert_almost_eq(float(m.period), want, want * 0.005, "%s goes round at its real year" % a.body)
					assert_eq(int(m.get("dir", 1)), -1, "anticlockwise, seen from above the Sun's north")
					checked += 1
	assert_gt(checked, 8)
	assert_eq(roundi(StarMap.year_days(&"mercury")), 88)
	assert_eq(roundi(StarMap.year_days(&"earth")), 365)
	assert_almost_eq(StarMap.year_days(&"jupiter") / 365.25, 11.9, 0.1, "almost 12 years")
	assert_almost_eq(StarMap.year_days(&"saturn") / 365.25, 29.5, 0.1, "about 29 years")


func test_the_moons_phases_take_29_and_a_half_days() -> void:
	var s := _short("moon_phases")
	assert_true(_counts_to(s).has(29.5))
	assert_almost_eq(29.5, SYNODIC_MONTH, 0.05)
	# The big Moon's phase: new at the start, full half-way, new again at the end.
	for a in _actors(s, "shape"):
		if a.shape == "moon_phase" and float(a.get("value", 0)) == 0.0:
			var at_full := ShortTimeline.actor_state(a, 0.5 + 10.5 * 0.5)
			assert_almost_eq(float(at_full.value), 0.5, 0.001)


func test_a_jump_on_each_world_is_worked_out_from_its_gravity() -> void:
	var s := _short("jump_gravity")
	var heights := {}
	for w: String in GRAVITY:
		heights[w] = EARTH_JUMP_CM * GRAVITY.earth / GRAVITY[w]
	assert_almost_eq(float(heights.moon) / 100.0, 1.8, 0.05, "the Moon: 1.8 m")
	assert_almost_eq(float(heights.mars), 80.0, 5.0, "Mars: about 80 cm")
	assert_almost_eq(float(heights.jupiter), 12.0, 0.5, "Jupiter: about 12 cm")
	assert_almost_eq(float(heights.pluto) / 100.0, 4.7, 0.05, "Pluto: 4.7 m")
	assert_almost_eq(GRAVITY.earth / GRAVITY.moon, 6.0, 0.1, "six times more gently")
	for words: String in ["30 cm", "1.8 m", "80 cm", "4.7 m", "12 cm"]:
		assert_true(_has_words(s, words), words)
	# The bars are as tall as the jumps (Earth, Mars, the Moon, Pluto).
	var bars := {}
	for a in _actors(s, "line"):
		if float((a.from as Array)[1]) == 410.0:
			bars[float((a.from as Array)[0])] = 410.0 - float((a.to as Array)[1])
	var scale := float(bars[60.0]) / EARTH_JUMP_CM
	for pair: Array in [[140.0, "mars"], [220.0, "moon"], [300.0, "pluto"]]:
		assert_almost_eq(float(bars[pair[0]]), float(heights[pair[1]]) * scale, 2.0, "%s's bar" % pair[1])
	# The Star Map says the same.
	assert_string_contains(" ".join(StarMap.body(&"moon").facts), "6 times higher")


func test_venus_and_mercury_as_the_star_map_says() -> void:
	var s := _short("venus_hot")
	var mercury := " ".join(StarMap.body(&"mercury").facts)
	var venus := " ".join(StarMap.body(&"venus").facts)
	assert_string_contains(mercury, "430 °C")
	assert_string_contains(mercury, "−180 °C")
	assert_string_contains(venus, "465 °C")
	assert_string_contains(venus, "melt lead")
	for n in [430.0, 465.0]:
		assert_true(_counts_to(s).has(n) or _actors(s, "count").any(func(a: Dictionary) -> bool: return float(a.from) == n))
	assert_true(_counts_to(s).has(-180.0))
	assert_lt(StarMap.ORBITS[&"mercury"][0], StarMap.ORBITS[&"venus"][0], "Mercury is nearer the Sun")


func test_saturn_as_the_star_map_says() -> void:
	var s := _short("saturn_rings")
	var saturn := " ".join(StarMap.body(&"saturn").facts)
	assert_string_contains(saturn, "ice and rock")
	assert_string_contains(saturn, "as big as houses")
	assert_string_contains(saturn, "float")
	assert_true(_counts_to(s).has(282000.0))
	assert_true(_has_words(s, "10 m"))


func test_water_splits_into_one_part_hydrogen_to_eight_oxygen() -> void:
	var s := _short("moon_ice_fuel")
	var hydrogen := 2.0 * 1.008
	var oxygen := 15.999
	var water := hydrogen + oxygen
	assert_almost_eq(9.0 * hydrogen / water, 1.0, 0.02, "9 kg of water: 1 kg of hydrogen")
	assert_almost_eq(9.0 * oxygen / water, 8.0, 0.02, "and 8 kg of oxygen")
	assert_true(_has_words(s, "1 kg hydrogen") and _has_words(s, "8 kg oxygen"))
	assert_string_contains(str(DepositKinds.data(DepositKinds.MOON_ICE).setting), "never see the Sun")
	assert_string_contains(RocketParts.words(BlockIds.SPACE_ENGINE), "hydrogen")


# --- Science, nature, maths, history -------------------------------------------------------------------------------

func test_the_lever_balances() -> void:
	var s := _short("lever_lift")
	assert_eq(60 * 1, 20 * 3)
	assert_true(_has_words(s, "60 × 1 = 60") and _has_words(s, "20 × 3 = 60"))
	# The seesaw's load is 1 part from the pivot and the push 3 parts.
	for a in _actors(s, "line"):
		if a.has("at") and float((a.at as Array)[0]) == 100.0:
			assert_eq(float((a.from as Array)[0]), 30.0)
	var load := 0.0
	var push := 0.0
	for scene: Dictionary in s.scenes:
		for a: Dictionary in scene.actors:
			if a.kind == "shape" and a.get("shape") == "rect" and a.get("color") == "brown":
				load = 100.0 - float((a.at as Array)[0])
			if a.kind == "character" and a.who == "pip" and push == 0.0:
				push = float((a.at as Array)[0]) - 100.0
	assert_almost_eq(push / load, 3.0, 0.001, "3 times as far from the pivot")


func test_pizza_fractions_are_equal() -> void:
	var s := _short("pizza_fractions")
	assert_eq(4.0 / 8.0, 1.0 / 2.0)
	assert_eq(2.0 / 4.0, 4.0 / 8.0)
	assert_eq(2.0 / 8.0, 1.0 / 4.0)
	assert_lt(3.0 / 8.0, 1.0 / 2.0, "the puzzle: a half is more")
	for a in _actors(s, "shape"):
		if a.shape == "pizza":
			for m: Dictionary in a.moves:
				if m.do == "value":
					assert_lte(float(m.to), float(a.slices), "a pizza never has more slices shaded than it has")


func test_place_value_adds_up() -> void:
	var s := _short("place_value")
	assert_eq(300 + 40 + 5, 345)
	assert_gt(543, 345)
	var biggest := 0
	for p: Array in [[3, 4, 5], [3, 5, 4], [4, 3, 5], [4, 5, 3], [5, 3, 4], [5, 4, 3]]:
		biggest = maxi(biggest, p[0] * 100 + p[1] * 10 + p[2])
	assert_eq(biggest, 543, "the puzzle's answer is on the screen already")
	for a in _actors(s, "picture"):
		var p: Dictionary = a.picture
		if int(p.get("hundreds", 0)) == 3:
			assert_eq(int(p.hundreds) * 100 + int(p.tens) * 10 + int(p.ones), 345, "the blocks are 345")


func test_the_seven_wonders_are_where_they_stood() -> void:
	var s := _short("seven_wonders")
	var maps := _actors(s, "map")
	assert_gt(maps.size(), 1)
	var points: Array = maps[0].points
	assert_eq(points.size(), WonderFacts.ANCIENT.size(), "seven")
	for p: Dictionary in points:
		var real: Array = WONDER_PLACES[str(p.label)]
		assert_almost_eq(float(p.lat), float(real[0]), 0.05, "%s's latitude" % p.label)
		assert_almost_eq(float(p.long), float(real[1]), 0.05, "%s's longitude" % p.label)
	var standing := 0
	for w: StringName in WonderFacts.ANCIENT:
		if WonderFacts.WONDERS[w].status == WonderFacts.STANDING:
			standing += 1
	assert_eq(standing, 1, "only the Great Pyramid still stands")
	assert_string_contains(" ".join(WonderFacts.TOUR_FACTS), "about 2,000 years old")
	assert_true(_counts_to(s).has(2000.0))
