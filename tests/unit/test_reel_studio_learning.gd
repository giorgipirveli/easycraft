extends GutTest
## Owner #94 and #96 (spec §5.12b): the learning reels, round 2 ("educational, like how to build a rocket, lessons
## explanations, learning animations ... we must keep reels high quality"). Twelve live 3D reels, each teaching one idea
## in 40-55 s. Every one passes the checkers and is in the feed; every number on the screen is worked out again here
## from the game's own tables (StarMap, WonderFacts, DepositKinds, RefiningRules, the School's units) or from the cited
## constants below (sources in docs/devlog/parts/reels-2.md), and the 3D shows what the words say (the north leaning to
## the Sun in June, the Moon between Earth and the Sun at new moon, a wooden block floating half under...).

const REELS: Array[String] = ["volcano_erupts", "water_cycle_3d", "seasons_tilt", "day_and_night", "pyramid_build",
	"lever_pulley", "moon_phases_3d", "plants_food", "plates_mountains", "volume_blocks", "gold_prospecting",
	"float_or_sink"]

# Cited constants (docs/devlog/parts/reels-2.md has each source).
const TILT_DEG := 23.44                 # Earth's axial tilt (NASA Earth Fact Sheet: obliquity to orbit)
const PERIHELION_MKM := 147.092         # million km, early January (NASA Earth Fact Sheet)
const APHELION_MKM := 152.099           # million km, early July
const SYNODIC_DAYS := 29.53             # new moon to new moon (NASA)
const OCEAN_SHARE := 96.5               # per cent of Earth's water in the oceans (USGS Water Science School)
const OAK_LITRES_A_YEAR := 151000.0     # a large oak tree gives off ~40,000 US gallons a year (USGS)
const EVEREST_M := 8848.86              # Nepal and China's 2020 measurement
const HIMALAYA_CM_A_YEAR := 1.0         # still rising "more than 1 cm a year" (USGS, This Dynamic Earth)
const PLATE_CM_A_YEAR := [2.0, 5.0]     # typical plate speeds, "about as fast as fingernails grow" (USGS, NOAA)
const BASALT_LAVA_C := [1100.0, 1200.0] # basaltic lava erupts at about 1,100-1,200 °C (USGS Volcano Hazards Program)
const GOLD_DENSITY := 19.32             # g/cm³ (Encyclopaedia Britannica, "gold"); water 1.00
const DENSITY := {"water": 1000.0, "wood": 500.0, "ice": 917.0, "stone": 2700.0, "iron": 7870.0}   # kg/m³


func after_each() -> void:
	ShortLibrary.clear_cache()


func _reel(id: String) -> Dictionary:
	var s := ShortLibrary.get_short(id)
	assert_false(s.is_empty(), "%s loads" % id)
	return s


func _words(s: Dictionary) -> String:
	var out: Array[String] = [str(s.title)]
	for scene: Dictionary in s.scenes:
		out.append(str(scene.caption))
		out.append(str(scene.say))
		for a: Dictionary in scene.get("actors", []):
			for key: String in ["text", "suffix", "prefix"]:
				if a.has(key):
					out.append(str(a[key]))
	return "\n".join(out)


func _model(s: Dictionary, id: String) -> Dictionary:
	var m := StudioRules.model(s.stage, id)
	assert_false(m.is_empty(), "%s has a model %s" % [s.id, id])
	return m


func _where(s: Dictionary, id: String, t: float) -> Vector3:
	return StudioMotion.world(s.stage, _model(s, id), t).origin


func _cells(m: Dictionary) -> int:
	return StudioShapes.cells(m).size()


func _scene_start(s: Dictionary, i: int) -> float:
	return ShortTimeline.scene_start(s, i)


# --- Every reel ----------------------------------------------------------------------------------------------------

func test_every_learning_reel_checks_plays_live_and_is_in_the_feed() -> void:
	var feed := ShortLibrary.hand_ids()
	for id in REELS:
		var s := _reel(id)
		assert_eq(ShortCheck.problems(s), [] as Array[String], id)
		assert_eq(ReelCheck.problems(s), [] as Array[String], id)
		assert_true(feed.has(id), "%s is in data/shorts/shorts.json" % id)
		assert_true(s.get("stage") is Dictionary, "%s is a 3D reel" % id)
		assert_false(s.has("video"), "%s plays live: a few KB, offline, sharp (no video in the APK)" % id)
		assert_between(ShortTimeline.length(s), 40.0, 55.0, "%s teaches its idea in 40-55 s" % id)
		assert_true(str(s.link.get("unit", "")) != "", "%s's LEARN IT opens its School unit" % id)


# --- How a volcano erupts ------------------------------------------------------------------------------------------

func test_the_volcano_and_io_are_the_star_map_s() -> void:
	var s := _reel("volcano_erupts")
	var words := _words(s)
	var io := "\n".join(StarMap.body(&"io").facts)
	assert_string_contains(io, "about 400 volcanoes")
	assert_string_contains(io, "Jupiter's pull squeezes Io")
	assert_string_contains(words, "about 400 volcanoes")
	assert_string_contains(words, "Jupiter's pull squeezes Io")
	assert_string_contains(words, "1,000 °C")
	assert_gt(BASALT_LAVA_C[0], 1000.0, "lava hotter than 1,000 °C: true of the runny lava that pours down the slopes")
	var chamber := _model(s, "chamber")
	assert_lt(StudioRules.vec(chamber.at).y, -4.0, "the magma chamber is deep under the ground")
	var magma := _model(s, "magma")
	var top := -INF
	for c: Vector3i in StudioShapes.cells(magma):
		top = maxf(top, StudioRules.vec(magma.at).y + c.y + 1)
	assert_between(top, 8.0, 11.0, "the magma rises up the pipe to the crater")


# --- The water cycle -----------------------------------------------------------------------------------------------

func test_the_water_cycle_has_the_lesson_s_four_stages_in_order() -> void:
	var s := _reel("water_cycle_3d")
	var stages := ["EVAPORATION", "CONDENSATION", "PRECIPITATION", "COLLECTION"]
	for i in stages.size():
		var found := false
		for a: Dictionary in s.scenes[i + 1].actors:
			found = found or str(a.get("text", "")) == "%d. %s" % [i + 1, stages[i]]
		assert_true(found, "scene %d names stage %d: %s" % [i + 2, i + 1, stages[i]])
	var lesson := JSON.stringify(FileAccess.get_file_as_string("res://data/school/g6/science/water_cycle.json")).to_lower()
	for stem: String in ["evaporat", "condens", "precipitat"]:
		assert_string_contains(lesson, stem, "the School's lesson teaches the same word")
	assert_string_contains(_words(s), "97 drops in every 100")
	assert_eq(roundi(OCEAN_SHARE), 97)
	assert_string_contains(_words(s), "invisible", "the drawn vapour is said to be invisible")


# --- Why we have seasons -------------------------------------------------------------------------------------------

func _north_to_sun(s: Dictionary, t: float) -> float:
	var axis := StudioMotion.world(s.stage, _model(s, "axis"), t)
	var north := axis.basis.y.normalized()
	var to_sun := (_where(s, "sun", t) - axis.origin).normalized()
	return north.dot(to_sun)


func test_the_seasons_tilt_leans_the_north_to_the_sun_in_june_and_away_in_december() -> void:
	var s := _reel("seasons_tilt")
	var axis := _model(s, "axis")
	assert_almost_eq(StudioRules.vec(axis.turn).z, snappedf(TILT_DEG, 0.1), 0.001, "tilted 23.4°")
	assert_string_contains(_words(s), "TILTED 23.4°")
	assert_string_contains(_words(s), "about 23 degrees")
	var june := _scene_start(s, 2) + 5.0
	var december := _scene_start(s, 3) + 7.0
	assert_almost_eq(_north_to_sun(s, june), sin(deg_to_rad(23.4)), 0.01, "June: the north leans toward the Sun")
	assert_almost_eq(_north_to_sun(s, december), -sin(deg_to_rad(23.4)), 0.01, "December: away from it")
	var a0 := StudioMotion.world(s.stage, axis, 1.0).basis.y.normalized()
	var a1 := StudioMotion.world(s.stage, axis, 7.3).basis.y.normalized()
	assert_almost_eq(a0.dot(a1), 1.0, 0.0001, "the axis points the same way all year round")
	assert_eq(int(axis.moves[0].dir), 1, "anticlockwise seen from above the north, as Earth goes")
	var words := _words(s)
	assert_string_contains(words, "JANUARY: %d MILLION km" % roundi(PERIHELION_MKM))
	assert_string_contains(words, "JULY: %d MILLION km" % roundi(APHELION_MKM))
	assert_lt(PERIHELION_MKM, APHELION_MKM, "closest in January, in the northern winter")


# --- Why day turns to night ----------------------------------------------------------------------------------------

func test_day_and_night_carries_the_home_from_the_day_side_into_the_night() -> void:
	var s := _reel("day_and_night")
	var earth := _model(s, "earth")
	var spin: Dictionary = earth.moves[0]
	assert_almost_eq(1.0 / float(spin.rate), 20.0, 0.001, "one spin is the reel's day")
	assert_string_contains(_words(s), "once every 24 hours")
	var sunset := _scene_start(s, 3) + 5.0
	var side := func(t: float) -> float:
		var e := _where(s, "earth", t)
		return (_where(s, "home", t) - e).normalized().dot((_where(s, "sun", t) - e).normalized())
	assert_gt(side.call(sunset - 2.0), 0.3, "the home is in the sunshine before")
	assert_almost_eq(side.call(sunset), 0.0, 0.05, "at the line between day and night as the sticker says sunset")
	assert_lt(side.call(sunset + 2.0), -0.3, "and in the night after")
	var sun := _model(s, "sun")
	assert_gt(StudioRules.vec(sun.at).x, 0.0, "the Sun rises in the east (+x, north is -z)")
	assert_gt(StudioRules.vec(sun.moves[0].to).y, StudioRules.vec(sun.at).y, "and climbs")


# --- How the pyramids were built -----------------------------------------------------------------------------------

func test_the_pyramid_s_numbers_are_wonder_facts() -> void:
	var s := _reel("pyramid_build")
	var facts := "\n".join(WonderFacts.WONDERS.pyramid.facts) + "\n" + str(WonderFacts.WONDERS.pyramid.built)
	var words := _words(s)
	for pair: Array in [["4,500 years", "4,500 YEARS"], ["146 m", "146 m"], ["3,800 years", "3,800 YEARS"],
			["2.3 million", "2.3 million"], ["Khufu", "Khufu"], ["smooth white stone", "smooth white stone"]]:
		assert_string_contains(facts, pair[0], "WonderFacts says it")
		assert_string_contains(words, pair[1], "and so does the reel")
	var counted := false
	for a: Dictionary in s.scenes[2].actors:
		counted = counted or (a.kind == "count" and float(a.to) == 2300000.0)
	assert_true(counted, "the blocks are counted up to 2,300,000")
	var widths: Array[int] = []
	for k in range(2, 10):
		var lo := 1 << 30
		for c: Vector3i in StudioShapes.cells(_model(s, "course%d" % k)):
			lo = mini(lo, c.x)
		widths.append(-lo)
	for i in range(1, widths.size()):
		assert_eq(widths[i], widths[i - 1] - 1, "each course is one block smaller on every side")


# --- Levers and pulleys --------------------------------------------------------------------------------------------

func test_the_lever_balances_and_the_pulleys_share_the_load() -> void:
	var s := _reel("lever_pulley")
	var words := _words(s)
	var load_arm := absf(StudioRules.vec(_model(s, "barrel").at).x)
	var push_arm := absf(StudioRules.vec(_model(s, "pusher").at).x)
	assert_eq(str(_model(s, "barrel").on), "plank")
	assert_eq(str(_model(s, "pusher").on), "plank")
	assert_almost_eq(60.0 * load_arm, 20.0 * push_arm, 0.001, "60 kg at 1 m balances 20 kg at 3 m")
	assert_string_contains(words, "LOAD 60 kg")
	assert_string_contains(words, "PUSH 20 kg")
	assert_string_contains(words, "60 × 1 = 20 × 3")
	var holding := 0
	for m: Dictionary in s.stage.models:
		if str(m.model) == "rope" and (str(m.get("from")) == "axle_m" or str(m.get("to")) == "axle_m") \
				and str(m.get("to")) != "load_b":
			holding += 1
	assert_eq(holding, 2, "two ropes hold the moving pulley")
	assert_string_contains(words, "PULL %d kg" % (60 / holding))
	var lb := _model(s, "load_b")
	var rise := StudioRules.vec(lb.moves[2].to).y - StudioRules.vec(lb.moves[1].to).y
	assert_almost_eq(rise, 1.0, 0.001, "the load rises 1 m in scene 4")
	var pulled := 0.0
	for a: Dictionary in s.scenes[3].actors:
		if a.kind == "count" and str(a.get("suffix", "")).contains("PULLED"):
			pulled = float(a.to)
	assert_almost_eq(pulled, rise * holding, 0.001, "while 2 m of rope is pulled")


# --- The Moon's phases ---------------------------------------------------------------------------------------------

func test_the_moon_s_phases_come_from_where_it_is() -> void:
	var s := _reel("moon_phases_3d")
	var phase := func(t: float) -> float:
		var e := _where(s, "earth", t)
		return (_where(s, "moon", t) - e).normalized().dot((_where(s, "sun", t) - e).normalized())
	var t3 := _scene_start(s, 2)
	assert_gt(phase.call(t3), 0.999, "new moon: between Earth and the Sun")
	assert_almost_eq(phase.call(t3 + 10.0), 0.0, 0.01, "first quarter a quarter of the way round")
	assert_lt(phase.call(t3 + 20.0), -0.999, "full moon: on the far side of Earth")
	assert_string_contains(_words(s), "29½ days")
	assert_almost_eq(SYNODIC_DAYS, 29.5, 0.05)
	for i in 3:
		assert_eq(int(_model(s, "moon").moves[i].dir), 1, "the Moon goes round anticlockwise, seen from the north")
	var from_earth := 0
	for k: Dictionary in s.stage.camera:
		if float(k.at) >= t3 and float(k.at) < t3 + 20.0:
			assert_eq(str(k.get("aim", "")), "moon", "scenes 3-4 keep the Moon in the middle")
			assert_eq(str(k.get("follow", "")), "eye")
			from_earth += 1
	assert_gt(from_earth, 0)
	assert_lt(_where(s, "eye", t3).distance_to(_where(s, "earth", t3)), float(_model(s, "earth").size),
		"seen from Earth itself")


# --- How plants make food ------------------------------------------------------------------------------------------

func test_the_plant_drinks_from_the_soil_and_the_oak_s_drink_is_the_usgs_s() -> void:
	var s := _reel("plants_food")
	assert_string_contains(_words(s), "over 100,000 litres")
	assert_gt(OAK_LITRES_A_YEAR, 100000.0)
	for i in 4:
		var m := _model(s, "water%d" % i)
		assert_lt(StudioRules.vec(m.at).y, -2.0, "a drop starts in the soil")
		assert_gt(StudioRules.vec(m.moves[m.moves.size() - 2].to).y, 5.0, "and ends up in the leaves")
	var words := _words(s).to_lower()
	for w: String in ["carbon dioxide", "sunlight", "sugar", "oxygen", "chlorophyll", "roots"]:
		assert_string_contains(words, w)


# --- How mountains grow --------------------------------------------------------------------------------------------

func test_the_plates_push_together_and_the_numbers_are_the_surveys() -> void:
	var s := _reel("plates_mountains")
	assert_gt(StudioRules.vec(_model(s, "left").moves[0].to).x, 0.0, "the left plate moves right")
	assert_lt(StudioRules.vec(_model(s, "right").moves[0].to).x, 0.0, "the right plate moves left")
	var words := _words(s)
	assert_string_contains(words, "EVEREST: %s m" % ShortActor.number_words(roundf(EVEREST_M)))
	assert_string_contains(words, "1 cm A YEAR")
	assert_eq(HIMALAYA_CM_A_YEAR, 1.0)
	assert_string_contains(words, "A FEW cm A YEAR")
	assert_between(PLATE_CM_A_YEAR[0], 1.0, 5.0)
	var layers := {}
	for f: Dictionary in _model(s, "left").fill:
		layers[str(f.block)] = true
	for f: Dictionary in _model(s, "range").fill:
		assert_true(layers.has(str(f.block)) or str(f.block) == "SNOW", "the mountains are the same layers, bent")


# --- Volume with blocks --------------------------------------------------------------------------------------------

func test_the_cubes_count_out_the_volumes() -> void:
	var s := _reel("volume_blocks")
	var cuboid := 0
	for id: String in ["c1", "c2", "c3", "c4", "row2", "row3", "layer2"]:
		cuboid += _cells(_model(s, id))
	assert_eq(cuboid, 4 * 3 * 2, "the cuboid is 24 cubes")
	var big := 0
	for id: String in ["big1", "big2", "big3"]:
		big += _cells(_model(s, id))
	assert_eq(big, 27)
	assert_eq(_cells(_model(s, "small")), 8)
	var words := _words(s)
	for sum: String in ["4 × 3 = 12", "12 × 2 = 24", "3 × 3 × 3 = 27", "2 × 2 × 2 = 8", "4 × 4 × 4 = ?"]:
		assert_string_contains(words, sum)


# --- How gold is found ---------------------------------------------------------------------------------------------

func test_gold_is_found_as_the_game_s_prospecting_finds_it() -> void:
	var s := _reel("gold_prospecting")
	var gold: Dictionary = DepositKinds.DATA[DepositKinds.GOLD]
	assert_string_contains(str(gold.setting), "white quartz veins in old hills")
	var words := _words(s)
	assert_string_contains(words, "white quartz veins, deep inside old hills")
	for c: Vector3i in StudioShapes.cells(_model(s, "vein")):
		assert_eq(int(StudioShapes.cells(_model(s, "vein"))[c]), int(gold.ore), "the vein is the game's gold quartz")
		break
	var gravel := false
	for f: Dictionary in _model(s, "land").fill:
		gravel = gravel or str(f.block) == "GOLD_GRAVEL"
	assert_true(gravel, "the bend's gravel is the game's gold gravel")
	assert_eq(int(gold.sign_block), BlockIds.GOLD_GRAVEL)
	assert_string_contains(RefiningRules.fact(&"pan_gold"), "Light sand washes out; heavy gold stays")
	assert_string_contains(words, "Light sand washes out; gold stays")
	assert_string_contains(words, "19 × HEAVIER THAN WATER")
	assert_eq(floori(GOLD_DENSITY), 19)


# --- Why things float or sink --------------------------------------------------------------------------------------

func _settles(s: Dictionary, id: String) -> float:
	var m := _model(s, id)
	return StudioRules.vec(m.moves[m.moves.size() - 1].to).y


func test_things_float_as_deep_as_their_density_says() -> void:
	var s := _reel("float_or_sink")
	assert_almost_eq(_settles(s, "wood"), -DENSITY.wood / DENSITY.water, 0.001, "wood: half under")
	assert_almost_eq(_settles(s, "ice"), -DENSITY.ice / DENSITY.water, 0.001, "ice: nine tenths under")
	assert_almost_eq(DENSITY.ice / DENSITY.water, 0.9, 0.02, "the sticker's 9/10")
	assert_string_contains(_words(s), "9/10")
	var floor_y := _settles(s, "stone")
	assert_eq(_settles(s, "lump"), floor_y, "the iron lump sinks to the floor like the stone")
	assert_gt(DENSITY.stone, DENSITY.water)
	var iron := 0.0
	var floor_plate := {}
	for id: String in ["floor", "side_a", "side_b", "end_a", "end_b"]:
		var st := StudioRules.vec(_model(s, id).stretch)
		iron += st.x * st.y * st.z
		if id == "floor":
			floor_plate = {"l": st.x, "w": st.z}
	var lump := float(_model(s, "lump").size)
	assert_almost_eq(pow(lump, 3.0), iron, 0.001, "the lump is the boat's iron in one piece")
	var draft := iron * DENSITY.iron / DENSITY.water / (float(floor_plate.l) * float(floor_plate.w))
	assert_almost_eq(-_settles(s, "boat"), draft, 0.001, "the boat sinks until it pushes aside its own weight of water")
	assert_lt(draft, StudioRules.vec(_model(s, "side_a").stretch).y, "below its rim: it floats")
