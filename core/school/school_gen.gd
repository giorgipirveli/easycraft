class_name SchoolGen
extends RefCounted
## Owner #68 (spec §22.5): the School's exercise generators, by id "<source>.<name>": `g4m.round_to` is
## `static func round_to(rng: RandomNumberGenerator, level: int) -> Dictionary` of core/school/gen/g4_maths_gen.gd. A
## generator returns an exercise in ExerciseCheck's form; the same seed and level always give the same exercise. A
## function whose name starts with "_" is a helper, not a generator. A new source (grade 5's maths…) is a SOURCES line.

const SOURCES := {
	"g4m": "res://core/school/gen/g4_maths_gen.gd",        # grade 4 maths: whole numbers and operations (units 1-8)
	"g4f": "res://core/school/gen/g4_fractions_gen.gd",    # grade 4 maths: fractions and decimals (units 9-12)
	"g4g": "res://core/school/gen/g4_measure_gen.gd",      # grade 4 maths: measurement, data and geometry (units 13-17)
	"g4s": "res://core/school/gen/g4_science_gen.gd",      # grade 4 science: rock layers and fossils
	"g4e": "res://core/school/gen/g4_english_gen.gd",      # grade 4 English: words that sound alike
	"g4p": "res://core/school/gen/g4_physical_gen.gd",     # grade 4 science: energy, waves, light, messages
	"g4l": "res://core/school/gen/g4_life_gen.gd",         # grade 4 science: plant and animal parts, senses
	"g4t": "res://core/school/gen/g4_earth_gen.gd",        # grade 4 science: erosion, maps, resources, hazards
	"g5n": "res://core/school/gen/g5_numbers_gen.gd",      # grade 5 maths: whole numbers, decimals, expressions (units 1-7)
	"g5f": "res://core/school/gen/g5_fractions_gen.gd",    # grade 5 maths: fractions (units 8-12)
	"g5m": "res://core/school/gen/g5_measure_gen.gd",      # grade 5 maths: volume, units, the grid, shapes (units 13-16)
	"g6n": "res://core/school/gen/g6_number_gen.gd",       # grade 6 maths: ratios, rates, percent, the number system (units 1-8)
	"g6a": "res://core/school/gen/g6_algebra_gen.gd",      # grade 6 maths: the plane, expressions, equations, geometry, statistics (units 9-17)
	"g7n": "res://core/school/gen/g7_number_gen.gd",       # grade 7 maths: proportion, percent, integers, rationals, algebra (units 1-8)
	"g7g": "res://core/school/gen/g7_geometry_gen.gd",     # grade 7 maths: scale, triangles, circles, angles, volume, sampling, probability (9-15)
	"g8n": "res://core/school/gen/g8_algebra_gen.gd",      # grade 8 maths: irrationals, exponents, roots, equations, systems, functions (1-8)
	"g8g": "res://core/school/gen/g8_geometry_gen.gd",     # grade 8 maths: models, transformations, Pythagoras, volume, statistics (9-16)
	"g3h": "res://core/school/gen/g3_humanities_gen.gd",   # grade 3 history, geography, citizenship: compass, grid refs, years, gold
	"g3s": "res://core/school/gen/g3_science_gen.gd",      # grade 3 science: living things to design (the research's 18 units)
	"g3e": "res://core/school/gen/g3_words_gen.gd",        # grade 3 English: plurals, tenses, comparing, spelling, punctuation
	"g3m": "res://core/school/gen/g3_maths_gen.gd",        # grade 3 maths: numbers to 10,000, the four operations, times tables (units 1-8)
	"g3f": "res://core/school/gen/g3_fractions_gen.gd",    # grade 3 maths: fractions, money (units 9-12)
	"g3g": "res://core/school/gen/g3_measure_gen.gd",      # grade 3 maths: time, measures, area, perimeter, shapes, graphs (13-18)
	"g3a": "res://core/school/gen/g3_arts_gen.gd",         # grade 3 computing, art and music: robots, loops, bugs, paint, patterns, listening
	"g3p": "res://core/school/gen/g3_health_gen.gd",       # grade 3 health and PE, D&T, projects: pulse, sleep, food, nets, maps
	"g4h": "res://core/school/gen/g4_humanities_gen.gd",   # grade 4 history, geography, citizenship: years, numerals, scale, capitals, gold
	"g4a": "res://core/school/gen/g4_arts_gen.gd",         # grade 4 computing, art and music: events, IF, variables, tables, the wheel, the stave, rounds
	"g4w": "res://core/school/gen/g4_health_gen.gd",       # grade 4 health and PE, D&T, projects: space, jumps, labels, circuits, bread
	"g4d": "res://core/school/gen/g4_data_gen.gd",         # grade 4 maths: tables, line graphs and pie charts (the research's unit 18)
	"g4c": "res://core/school/gen/g4_core_gen.gd",         # grade 4 science and English: circuits, heat, states, sound, digestion, myths, accounts, linking words
	"g5h": "res://core/school/gen/g5_humanities_gen.gd",   # grade 5 history, geography, citizenship: Olympiads, BC/AD, Roman and Maya numbers, lat/long, time zones, gold
	"g5w": "res://core/school/gen/g5_health_gen.gd",       # grade 5 health and PE, D&T, projects: courts, gears, cams, bridges, views, fair
	"g5a": "res://core/school/gen/g5_arts_gen.gd",         # grade 5 computing, art and music: game variables, nested loops, procedures, packets, sheets, mosaics, chords, forms
	"g5c": "res://core/school/gen/g5_core_gen.gd",         # grade 5 maths, science, English (research's new units): percent, angles, forces, circuits, life cycles, heart, quotes, writing
	"g6h": "res://core/school/gen/g6_humanities_gen.gd",   # grade 6 history, geography, citizenship: centuries, quipus, caravans, grid refs, contours, climate graphs, layers, tax, compound interest
	"g6c": "res://core/school/gen/g6_arts_gen.gd",         # grade 6 computing, art and music: binary, light, logic, programs, sheets, passwords, AI, tiles, prints, scales, intervals, blues, sound
	"g6w": "res://core/school/gen/g6_health_gen.gd",       # grade 6 health and PE, D&T, projects: pulse, FITT, formations, relays, 5 A DAY, first aid, Naismith, levers, gears, sensors, food zones, materials, markets, weather
	"g6k": "res://core/school/gen/g6_core_gen.gd",         # grade 6 maths, science, English (research's last units): toolkit, skeleton, nutrition, classifying, light, energy, design, reading, writing, sources, talks
	"g7c": "res://core/school/gen/g7_arts_gen.gd",         # grade 7 computing, art and music: text code, lists, functions, searches, sorts, tests, IP, ciphers, data, feeds, copyright, colour schemes, figures, scale, thirds, prints, chords, cadences, ornaments, the bass clef, riffs, film cues, mixes
	"g7h": "res://core/school/gen/g7_hum_gen.gd",          # grade 7 history, geography, citizenship: dates, type, the Pole Star, reigns, Kepler, plates, rocks, glaciers, coasts, biomes, water, time zones, laws, petitions, charts, profit, credit
	"g7w": "res://core/school/gen/g7_life_gen.gd",         # grade 7 health and PE, D&T, projects: tactics, badminton and tennis scores, heart-rate zones, dance counts, tournaments, sleep, adverts, drugs and the law, conflicts, help; resistors, LEDs, microcontrollers, fabrics, recipes, food waste, life cycles, tests; sea miles, water, energy, profit
	"g8h": "res://core/school/gen/g8_hum_gen.gd",          # grade 8 history, geography, citizenship: modern dates, railways, wars' sides, rations, chips; CO2, pyramids, energy, water in food, density, tourism, ocean zones, Mercator, GIS; seats, votes, ages, tax, budgets, loans, the rule of 72, refunds, the Global Goals, data
	"g8c": "res://core/school/gen/g8_arts_gen.gd",         # grade 8 computing, art and music: programs of functions, worst cases, state machines, models, a little machine, ASCII, file sizes, logic circuits, truth tables, queries, nearest neighbours, passwords, user tests, energy; art and music (see its header)
	"g8l": "res://core/school/gen/g8_life_gen.gd",         # grade 8 health and PE, D&T, projects: formations, match stats, fitness tests and profiles, activity, thinking traps, setbacks, online respect, chance and mystery boxes, pressure and the law, CPR counts, surveys, screen time; specifications, plans, cutting lists, smart materials, density, thresholds, batteries, loops, levers, gear trains, pulleys, efficiency, safety factors, nutrients, labels, dietary needs, processing, footprints, circular loops, cost per year, standby, automation; reliability, budgets, frames, sources, years, litter rates, correlation, surveys
	"g7k": "res://core/school/gen/g7_core_gen.gd",         # grade 7 maths, science, English (the last units): primes, HCF and LCM, rounding, estimates, speed, cut axes; the periodic table, separating, pH, light and colour, the air; evidence, history and fiction, speeches, arguments, signal words, points of view
	"g8k": "res://core/school/gen/g8_core_gen.gd",         # grade 8 maths, science, English (the research's last 14 units): brackets, factorising, parabolas, sin cos tan; pressure, floating, energy bills, reactions, circuits, transport, breeding; evidence, old stories, arguments, explaining, narrative, talks
}

static var _scripts := {}


static func exists(gen_id: String) -> bool:
	var parts := gen_id.split(".")
	if parts.size() != 2 or parts[1].begins_with("_"):
		return false
	var s := _script(parts[0])
	return s != null and _names(s).has(parts[1])


## Every generator id.
static func ids() -> Array[String]:
	var out: Array[String] = []
	for source: String in SOURCES:
		for n in _names(_script(source)):
			out.append("%s.%s" % [source, n])
	return out


## The exercise generator `gen_id` makes from `seed` at `level` (1-3), with its id ("gen:<gen_id>:<seed>:<level>") and
## level; {} for an unknown generator.
static func make(gen_id: String, seed: int, level: int) -> Dictionary:
	if not exists(gen_id):
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var parts := gen_id.split(".")
	var ex: Variant = _script(parts[0]).call(parts[1], rng, clampi(level, 1, 3))
	if not ex is Dictionary:
		return {}
	var out: Dictionary = ex
	out.id = "gen:%s:%d:%d" % [gen_id, seed, level]
	out.level = clampi(level, 1, 3)
	return out


static func _script(source: String) -> Script:
	if not SOURCES.has(source):
		return null
	if not _scripts.has(source):
		_scripts[source] = load(SOURCES[source])
	return _scripts[source]


static func _names(s: Script) -> Array[String]:
	var out: Array[String] = []
	if s == null:
		return out
	for m: Dictionary in s.get_script_method_list():
		var n := str(m.name)
		if not n.begins_with("_") and (int(m.flags) & METHOD_FLAG_STATIC) and not out.has(n):
			out.append(n)
	return out
