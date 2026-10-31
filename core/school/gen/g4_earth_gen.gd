class_name G4EarthGen
extends RefCounted
## Owner #68 (the grade 4 agent): grade 4 Earth science generators: SchoolGen "g4t.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a
## worked answer and `data`. Units: "Weathering and erosion" (4-ESS2-1), "Mapping Earth's features" (4-ESS2-2),
## "Energy resources" (4-ESS3-1), "Natural hazards" (4-ESS3-2). Heights and depths are real, rounded to the nearest
## hundred metres ("about").

const K := preload("res://core/school/gen/gen_kit.gd")

## [a change, "weathering" (rock broken down), "erosion" (bits carried away) or "deposition" (bits dropped), level].
const CHANGES: Array = [
	["Ice in a crack splits a rock in two.", "weathering", 1],
	["Tree roots push a rock apart.", "weathering", 1],
	["A river carries pebbles downstream.", "erosion", 1],
	["The wind blows sand off a beach.", "erosion", 1],
	["Rain slowly wears the face off an old statue.", "weathering", 2],
	["Moss and lichen crumble the top of a stone wall.", "weathering", 2],
	["Hot days and cold nights crack a desert rock.", "weathering", 2],
	["A glacier drags rocks down a valley.", "erosion", 2],
	["Heavy rain washes soil down a bare hill.", "erosion", 2],
	["Waves carry sand away from a beach.", "erosion", 2],
	["A river drops its mud where it meets the sea.", "deposition", 3],
	["The wind piles sand up into a dune.", "deposition", 3],
	["A melting glacier leaves a heap of rocks behind.", "deposition", 3],
	["Floodwater leaves a layer of mud on a field.", "deposition", 3],
]
const WORK: Array[String] = ["water", "ice", "wind", "plants"]
## [a change, what does the work (water, ice, wind or plants), level].
const CAUSES: Array = [
	["A river carves a deep canyon.", "water", 1],
	["Roots grow into a crack and split a rock.", "plants", 1],
	["Sand dunes creep across a desert.", "wind", 1],
	["A glacier scrapes out a wide valley.", "ice", 1],
	["Waves wear away the bottom of a cliff.", "water", 2],
	["Ice in a crack breaks a boulder apart.", "ice", 2],
	["Blowing sand wears a rock into a strange shape.", "wind", 2],
	["Moss slowly crumbles an old stone wall.", "plants", 2],
	["A stream rounds off sharp pebbles.", "water", 3],
	["A glacier carries huge boulders far away.", "ice", 3],
	["Dust is blown off a dry, bare field.", "wind", 3],
	["A tree's roots lift and crack a pavement.", "plants", 3],
]
## Real mountains and ocean trenches, in metres, rounded to the nearest hundred.
const HEIGHTS: Array = [["Mount Everest", 8800], ["K2", 8600], ["Aconcagua", 7000], ["Denali", 6200],
	["Kilimanjaro", 5900], ["Mont Blanc", 4800], ["Mount Fuji", 3800], ["Mount Kosciuszko", 2200], ["Ben Nevis", 1300]]
const DEPTHS: Array = [["the Mariana Trench", 10900], ["the Philippine Trench", 10500], ["the Kermadec Trench", 10000],
	["the Puerto Rico Trench", 8400]]
const RENEWABLE: Array[String] = ["sunlight", "wind", "flowing river water", "ocean waves", "heat from deep underground",
	"wood from trees that are replanted"]
const NOT_RENEWABLE: Array[String] = ["coal", "oil", "natural gas", "petrol", "uranium"]
## [what makes the electricity, one or many].
const POWER: Array = [["wind turbine", "wind turbines"], ["solar farm", "solar farms"], ["river dam", "river dams"]]
const HAZARDS: Array[String] = ["earthquake", "flood", "volcanic eruption", "tsunami"]
## [an idea, the one hazard it is for].
const IDEAS: Array = [
	["buildings that sway without falling down", "earthquake"],
	["drop, cover and hold on drills at school", "earthquake"],
	["tall cupboards strapped to the wall", "earthquake"],
	["houses built on stilts beside a river", "flood"],
	["high banks built along a river", "flood"],
	["wetlands that soak up extra rain", "flood"],
	["sandbags piled up by the door when rivers rise", "flood"],
	["tools that measure the gases from a crater", "volcanic eruption"],
	["maps showing where lava could flow", "volcanic eruption"],
	["instruments that feel a mountain's slopes swell", "volcanic eruption"],
	["buoys out at sea that spot giant waves", "tsunami"],
	["practice walks from the beach up to high ground", "tsunami"],
]


# --- Weathering and erosion (4-ESS2-1) ----------------------------------------------------------------------------

## "Is this weathering or erosion? Ice in a crack splits a rock in two." (level 3: or deposition)
static func weather_or_erode(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick_level(rng, CHANGES, level)
	var kind: String = row[1]
	var kinds: Array = ["weathering", "erosion", "deposition"] if level == 3 else ["weathering", "erosion"]
	var prompt := "Is this weathering or erosion?  %s" % row[0]
	if level == 1:
		prompt = "Weathering breaks rock; erosion carries the bits away. Which is this?  %s" % row[0]
	elif level == 3:
		prompt = "Is this weathering, erosion or deposition?  %s" % row[0]
	var ex := K.choice(rng, prompt, kind, kinds.filter(func(k: String) -> bool: return k != kind),
		"Weathering breaks rock down. Erosion carries the bits away. Deposition drops them somewhere new.",
		"This is %s: %s" % [kind, {"weathering": "rock is being broken down.", "erosion": "bits are being carried away.",
			"deposition": "carried bits are being dropped."}[kind]])
	ex.data = {"kind": kind}
	return ex


## "What is doing the work here? A glacier scrapes out a wide valley." (water, ice, wind or plants)
static func erosion_cause(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick_level(rng, CAUSES, level)
	var cause: String = row[1]
	var ex := K.choice(rng, "What is doing the work here: water, ice, wind or plants?  %s" % row[0], cause,
		WORK.filter(func(w: String) -> bool: return w != cause),
		"A glacier is a river of ice. Rivers, rain, streams and waves are water. Dunes and dust are moved by wind.",
		{"water": "Water is doing the work.", "ice": "Ice is doing the work.", "wind": "The wind is doing the work.",
			"plants": "Plants are doing the work: roots and moss can break rock."}[cause])
	ex.data = {"change": row[0]}
	return ex


## "A riverbank wears away about 3 cm each year. How much in 6 years?" (level 3: how many years for 1 m?)
static func erosion_rate(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var rate := rng.randi_range(2, 5)
			var years := rng.randi_range(2, 9)
			ex = K.number("A riverbank wears away about %d cm each year. How many cm will it wear away in %d years?" % [rate,
				years], rate * years, "It loses the same amount every year: multiply.",
				"%d years × %d cm = %d cm." % [years, rate, rate * years])
			ex.data = {"rate": rate, "years": years}
		2:
			var rate := rng.randi_range(2, 9)
			var years := rng.randi_range(1, 5) * 10
			ex = K.number("The wind pushes a sand dune about %d m each year. How far does it move in %d years?" % [rate, years],
				rate * years, "Multiply the distance for one year by the number of years.",
				"%d years × %d m = %d m." % [years, rate, rate * years])
			ex.data = {"rate": rate, "years": years}
		_:
			var rate: int = [2, 4, 5, 10, 20, 25][rng.randi_range(0, 5)]
			var metres := rng.randf() < 0.5
			var total := 100 if metres else rate * rng.randi_range(3, 12)
			var how_far := "1 m" if metres else "%d cm" % total
			ex = K.number("Waves wear a cliff back about %d cm each year. How many years until it has worn back %s?" % [rate,
				how_far], total / rate, ("1 m is 100 cm. " if metres else "") + "How many lots of %d cm make %d cm?" % [rate, total],
				"%d cm ÷ %d cm = %d years." % [total, rate, total / rate])
			ex.data = {"rate": rate, "total": total}
	return ex


# --- Mapping Earth's features (4-ESS2-2) --------------------------------------------------------------------------

## "How many volcanoes are on this map?" (level 2-3: earthquakes or mountains too)
static func map_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows := _map(rng, level, false)
	var whats: Array = ["volcanoes"] if level == 1 else ["volcanoes", "earthquakes", "mountains"]
	var what: String = whats[rng.randi_range(0, whats.size() - 1)]
	var symbols: String = {"volcanoes": "v", "earthquakes": "*x", "mountains": "^"}[what]
	var n := 0
	for row: String in rows:
		for ch in row:
			n += int(symbols.contains(ch))
	var ex := K.number("How many %s are on this map?" % what, n, "Use the key to find the right symbol, then count them all.",
		"There are %d %s. Did you notice where they are? Along the coast!" % [n, what],
		{"kind": "map", "rows": rows, "key": true})
	ex.data = {"what": what}
	return ex


## "Where are the volcanoes on this map?" (along the coast; level 3: what lies in the sea beside them)
static func map_pattern(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var trench := level == 3 and rng.randf() < 0.5
	var rows := _map(rng, level, trench)
	var picture := {"kind": "map", "rows": rows, "key": true}
	var ex: Dictionary
	if trench:
		ex = K.choice(rng, "What lies in the sea right beside the line of volcanoes?", "a deep trench",
			["a mountain range", "a sandy beach", "a big island"],
			"Look at the key: which colour is the dark sea next to the coast?",
			"A deep trench runs along the coast, beside the volcanoes. On real maps, trenches and volcanoes are often found together.",
			picture)
	else:
		var whats: Array = ["volcanoes"] if level == 1 else ["volcanoes", "earthquakes", "mountains"]
		var what: String = whats[rng.randi_range(0, whats.size() - 1)]
		var right: String = {"volcanoes": "in a line along the coast", "earthquakes": "along the coast",
			"mountains": "in a chain along the coast"}[what]
		ex = K.choice(rng, "On this map, where are the %s?" % what, right,
			["spread all over the land", "far out in the sea", "in the middle of the land"],
			"Find each one with the key. Is there a pattern?",
			"The %s lie %s. On real maps, many volcanoes, earthquakes and mountains are found near the edges of continents." % [
				what, right.trim_prefix("in a line ").trim_prefix("in a chain ")], picture)
	ex.data = {"trench": trench}
	return ex


## "Mount Everest is about 8,800 m tall and Mont Blanc about 4,800 m. How much taller is Everest?" (level 1: which is
## taller; level 3: a trench's depth and a mountain's height)
static func height_depth(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var a: Array
	var b: Array
	if level < 3:
		var two := _two(rng, HEIGHTS)
		a = two[0]
		b = two[1]
		if level == 1:
			ex = K.choice(rng, "Which is taller: %s (about %s m) or %s (about %s m)?" % [a[0], K.fmt(a[1]), b[0], K.fmt(b[1])],
				a[0] if int(a[1]) > int(b[1]) else b[0], [b[0] if int(a[1]) > int(b[1]) else a[0]],
				"Compare the thousands first.", "%s is taller." % (a[0] if int(a[1]) > int(b[1]) else b[0]))
		else:
			var hi: Array = a if int(a[1]) > int(b[1]) else b
			var lo: Array = b if hi == a else a
			ex = K.number("%s is about %s m tall and %s is about %s m tall. How many metres taller is %s?" % [hi[0], K.fmt(hi[1]),
				lo[0], K.fmt(lo[1]), hi[0]], int(hi[1]) - int(lo[1]), "Subtract the smaller height from the bigger one.",
				"%s − %s = %s m." % [K.fmt(hi[1]), K.fmt(lo[1]), K.fmt(int(hi[1]) - int(lo[1]))])
	else:
		a = DEPTHS[rng.randi_range(0, DEPTHS.size() - 1)]
		b = HEIGHTS[rng.randi_range(0, 3)]
		var diff := absi(int(a[1]) - int(b[1]))
		ex = K.number("%s is about %s m deep. %s is about %s m tall. What is the difference between them, in metres?" % [
			_cap(a[0]), K.fmt(a[1]), b[0], K.fmt(b[1])], diff, "Subtract the smaller number from the bigger one.",
			"%s − %s = %s m." % [K.fmt(maxi(a[1], b[1])), K.fmt(mini(a[1], b[1])), K.fmt(diff)])
	ex.data = {"a": a, "b": b}
	return ex


# --- Energy resources (4-ESS3-1) ----------------------------------------------------------------------------------

## "Coal is a renewable energy resource." (true or false; level 2: which is renewable; 3: which is NOT)
static func renewable(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var yes: Array = []
	yes.append_array(RENEWABLE)
	var no: Array = []
	no.append_array(NOT_RENEWABLE)
	K.shuffle(rng, yes)
	K.shuffle(rng, no)
	var ex: Dictionary
	if level == 1:
		var thing: String = yes[0] if rng.randf() < 0.5 else no[0]
		var is_yes := RENEWABLE.has(thing)
		ex = K.truefalse("%s is a renewable energy resource." % _cap(thing), is_yes,
			"Renewable resources do not run out: the Sun keeps shining, the wind keeps blowing.",
			"%s %s." % [_cap(thing), "is renewable: it will not run out" if is_yes else
				"is not renewable: it took millions of years to form, and once it is used it is gone"])
		ex.data = {"thing": thing}
	elif level == 2:
		ex = K.choice(rng, "Which of these is a renewable energy resource?", yes[0], no.slice(0, 3),
			"Which one will not run out?", "%s is renewable; the others will run out one day." % _cap(yes[0]))
		ex.data = {}
	else:
		ex = K.choice(rng, "Which of these is NOT a renewable energy resource?", no[0], yes.slice(0, 3),
			"Which one will run out one day?", "%s will run out; the others are renewable." % _cap(no[0]))
		ex.data = {}
	return ex


## "One wind turbine makes enough electricity for 300 homes. How many homes can 4 of them power?" (level 3: how many
## are needed for 2,400 homes?)
static func power_homes(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var what: Array = POWER[rng.randi_range(0, POWER.size() - 1)]
	var each: int = [rng.randi_range(1, 5) * 100, rng.randi_range(5, 18) * 50, rng.randi_range(2, 9) * 100][level - 1]
	var count := rng.randi_range(2, [5, 9, 12][level - 1])
	var ex: Dictionary
	if level == 3:
		ex = K.number("One %s makes enough electricity for %s homes. How many %s are needed for %s homes?" % [what[0],
			K.fmt(each), what[1], K.fmt(each * count)], count, "How many lots of %s make %s?" % [K.fmt(each), K.fmt(each * count)],
			"%s ÷ %s = %d %s." % [K.fmt(each * count), K.fmt(each), count, what[1]])
		ex.data = {"each": each, "homes": each * count}
	else:
		ex = K.number("One %s makes enough electricity for %s homes. How many homes can %d %s power?" % [what[0], K.fmt(each),
			count, what[1]], each * count, "Multiply the homes for one by the number of them.",
			"%d × %s = %s homes." % [count, K.fmt(each), K.fmt(each * count)])
		ex.data = {"each": each, "count": count}
	return ex


# --- Natural hazards (4-ESS3-2) -----------------------------------------------------------------------------------

## "Which hazard does this idea protect people from? Houses built on stilts beside a river." (level 1: earthquake or
## flood; 2: or a volcanic eruption; 3: or a tsunami)
static func hazard_idea(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hazards: Array = HAZARDS.slice(0, level + 1)
	var pool: Array = IDEAS.filter(func(row: Array) -> bool: return hazards.has(row[1]))
	var row: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var hazard: String = row[1]
	var ex := K.choice(rng, "Which hazard does this idea protect people from?  %s" % _cap(str(row[0])), hazard,
		hazards.filter(func(h: String) -> bool: return h != hazard),
		"Think about where it would help: shaking ground, rising water, a volcano or giant waves from the sea?",
		"%s help people stay safe in %s %s." % [_cap(str(row[0])), "an" if hazard == "earthquake" else "a", hazard])
	ex.data = {"hazard": hazard}
	return ex


# --- Helpers ------------------------------------------------------------------------------------------------------

## A map: land on one side, sea on the other with a wavy coast; volcanoes and mountains along the coast, earthquakes
## on the coast or just off it (and a deep trench off the coast when `trench`).
static func _map(rng: RandomNumberGenerator, level: int, trench: bool) -> Array:
	var w: int = [10, 12, 12][level - 1]
	var h: int = [5, 6, 6][level - 1]
	var coast: Array = []
	var c: int = w / 2
	for y in h:
		c = clampi(c + rng.randi_range(-1, 1), w / 2 - 1, w / 2 + 1)
		coast.append(c)
	var grid: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			row.append("." if x < int(coast[y]) else "~")
		grid.append(row)
	for y in h:
		var cx: int = coast[y]
		var roll := rng.randf()
		if roll < 0.45:
			grid[y][cx - 1] = "v"
		elif roll < 0.75:
			grid[y][cx - 1] = "^"
		elif level > 1 and roll < 0.9:
			grid[y][cx - 1] = "*"
		if trench:
			grid[y][cx + 1] = "="
		elif level > 1 and rng.randf() < 0.35:
			grid[y][cx] = "x"
	var has_volcano := false
	for row: Array in grid:
		has_volcano = has_volcano or row.has("v")
	if not has_volcano:
		grid[0][int(coast[0]) - 1] = "v"
	var flip := rng.randf() < 0.5
	var out: Array = []
	for row: Array in grid:
		if flip:
			row.reverse()
		out.append("".join(row))
	return out


static func _two(rng: RandomNumberGenerator, rows: Array) -> Array:
	var i := rng.randi_range(0, rows.size() - 1)
	var j := rng.randi_range(0, rows.size() - 2)
	if j >= i:
		j += 1
	return [rows[i], rows[j]]


## A row of this level, or an easier one (this level's rows twice as often).
static func _pick_level(rng: RandomNumberGenerator, rows: Array, level: int) -> Array:
	var pool: Array = []
	for row: Array in rows:
		if int(row.back()) <= level:
			pool.append(row)
			if int(row.back()) == level:
				pool.append(row)
	return pool[rng.randi_range(0, pool.size() - 1)]


static func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)
