class_name G4PhysicalGen
extends RefCounted
## Owner #68 (the grade 4 agent): grade 4 physical science generators: SchoolGen "g4p.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a
## worked answer and `data`. Units: "Energy and speed" (4-PS3-1, 4-PS3-3), "Energy on the move" (4-PS3-2, 4-PS3-4),
## "Waves" (4-PS4-1), "Light and seeing" (4-PS4-2), "Sending messages with patterns" (4-PS4-3). Only identical things
## are compared by speed (the same mass), so the faster one has more energy.

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Nell"]
## Things that roll or slide: [one, many, it …, they …].
const MOVERS: Array = [["cart", "carts", "rolls", "roll"], ["ball", "balls", "rolls", "roll"],
	["sled", "sleds", "slides", "slide"], ["marble", "marbles", "rolls", "roll"], ["toy car", "toy cars", "rolls", "roll"]]
const FORMS: Array[String] = ["sound", "light", "heat", "an electric current"]
## [situation, how its energy travels, level]: one way only in each.
const TRAVELS: Array = [
	["A drum's beat reaches your ears.", "sound", 1],
	["Sunlight reaches a leaf on a tree.", "light", 1],
	["A hot pan warms the spoon standing in it.", "heat", 1],
	["A wire carries power from a battery to a bell.", "an electric current", 1],
	["A lantern lights up a dark cave.", "light", 1],
	["A friend's shout reaches you across the field.", "sound", 1],
	["A radiator warms the air of a cold room.", "heat", 2],
	["A cable brings electricity to a house.", "an electric current", 2],
	["Thunder rumbles across the valley.", "sound", 2],
	["Moonlight shows you the path at night.", "light", 2],
	["A mug of hot cocoa warms your hands.", "heat", 2],
	["A charger's cable fills a phone's battery.", "an electric current", 2],
	["A lighthouse's beam reaches a ship far out at sea.", "light", 3],
	["A whale's song carries through the ocean.", "sound", 3],
	["A hot-water bottle warms a cold bed.", "heat", 3],
	["A wire from a solar panel runs a water pump.", "an electric current", 3],
	["A doorbell's ring reaches you upstairs.", "sound", 3],
	["The warm sand warms your bare feet.", "heat", 3],
]
const ENERGIES: Array[String] = ["light", "sound", "motion", "heat"]
## [device, "from electricity" (built to change electricity into …) or "into electricity" (makes electricity from …),
## the one energy, level]. Each device is built for one job.
const DEVICES: Array = [
	["lamp", "from electricity", "light", 1],
	["doorbell", "from electricity", "sound", 1],
	["fan", "from electricity", "motion", 1],
	["electric heater", "from electricity", "heat", 1],
	["loudspeaker", "from electricity", "sound", 2],
	["toaster", "from electricity", "heat", 2],
	["electric train's motor", "from electricity", "motion", 2],
	["torch", "from electricity", "light", 2],
	["solar panel", "into electricity", "light", 3],
	["wind turbine", "into electricity", "motion", 3],
	["bicycle's dynamo", "into electricity", "motion", 3],
	["microphone", "into electricity", "sound", 3],
	["hot-rock power station", "into electricity", "heat", 3],
]
## Light's path: [its source as said, the picture's source ("sun", "lamp", or "" for no picture)].
const SOURCES: Array = [["the Sun", "sun"], ["the lantern", "lamp"], ["the campfire", ""], ["the torch", ""],
	["the lamp", ""]]
## [the thing lit, its block for the picture].
const LIT: Array = [["the pumpkin", 272], ["the snowman", 274], ["the bookshelf", 218], ["the golden trophy", 34],
	["the cactus", 69], ["the barrel", 30]]
## Things that make their own light, and things we see only by light they bounce.
const MAKES_LIGHT: Array[String] = ["the Sun", "a lit candle", "a campfire", "a lantern", "a torch that is on",
	"a flash of lightning", "a glowing firefly", "a star at night"]
const NO_LIGHT: Array[String] = ["the Moon", "a mirror", "a white wall", "a shiny coin", "a window", "a snowy field",
	"a bike's reflector", "a torch that is off", "a glass of water", "a diamond ring", "a book"]
## The Moon, a bike's reflector, a diamond and a switched-off torch trick many: a harder level asks them.
const TRICKY: Array[String] = ["the Moon", "a bike's reflector", "a torch that is off", "a diamond ring", "a mirror",
	"a shiny coin", "a glowing firefly", "a star at night", "a flash of lightning"]
## International Morse code: short signals •, long ones —.
const MORSE := {"A": "• —", "D": "— • •", "E": "•", "H": "• • • •", "I": "• •", "M": "— —", "N": "— •", "O": "— — —",
	"R": "• — •", "S": "• • •", "T": "—"}
## Words from those letters: [word, level].
const MORSE_WORDS: Array = [["TEA", 1], ["EAT", 1], ["TEN", 1], ["NET", 1], ["MAT", 1], ["TIN", 1], ["MEN", 1],
	["SEA", 2], ["HAT", 2], ["HOT", 2], ["SON", 2], ["DOT", 2], ["RED", 2], ["SIT", 2], ["HEN", 2], ["MOON", 2],
	["RAIN", 2], ["SEAT", 2], ["NOTE", 2], ["HORSE", 3], ["STORM", 3], ["TRAIN", 3], ["DREAM", 3], ["STONE", 3],
	["HEAT", 3], ["DOOR", 3]]
## The drum code's words: A is 1 beat … H is 8.
const BEAT_WORDS: Array = [["CAB", 1], ["BAD", 1], ["BED", 1], ["DAB", 1], ["ACE", 1], ["BEE", 1], ["DAD", 1],
	["HEAD", 2], ["BEAD", 2], ["FACE", 2], ["CAGE", 2], ["EACH", 2], ["CAFE", 2], ["FADE", 2], ["BADGE", 3],
	["BEACH", 3], ["HEDGE", 3]]
const DRUM := "Drum code: A = 1 beat, B = 2, C = 3, D = 4, E = 5, F = 6, G = 7, H = 8."


# --- Energy and speed (4-PS3-1, 4-PS3-3) --------------------------------------------------------------------------

## "Zara's and Bram's carts are exactly alike. … Which cart has more energy?" (level 1: metres each second; 2: the
## same distance in different times; 3: three in a table, distance and time).
static func faster_energy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var mover: Array = MOVERS[rng.randi_range(0, MOVERS.size() - 1)]
	var names := _names(rng, 3 if level == 3 else 2)
	var speeds := {}
	var ex: Dictionary
	if level == 3:
		var vs := _distinct(rng, 3, 2, 9)
		var rows: Array = [[mover[0], "distance", "time"]]
		var parts: Array[String] = []
		for i in 3:
			var t := rng.randi_range(2, 5)
			speeds[names[i]] = [vs[i] * t, t]
			rows.append([names[i], "%d m" % (vs[i] * t), "%d seconds" % t])
			parts.append("%s: %d ÷ %d = %d" % [names[i], vs[i] * t, t, vs[i]])
		var best: String = names[vs.find(vs.max())]
		var choices: Array = []
		for n in names:
			choices.append("%s's %s" % [n, mover[0]])
		ex = K.choice(rng, "Three %s, exactly alike, %s along. Which one has the most energy?" % [mover[1], mover[3]],
			"%s's %s" % [best, mover[0]], choices.filter(func(c: String) -> bool: return not c.begins_with(best + "'s")),
			"Work out each speed: the distance ÷ the time. The fastest has the most energy.",
			"%s m each second. %s's is fastest, so it has the most energy." % [", ".join(parts), best],
			{"kind": "table", "rows": rows})
	else:
		var same := rng.randf() < 0.15
		var a := rng.randi_range(2, 9)
		var b := a if same else _other(rng, a, 2, 9)
		var right := "They have the same energy"
		var prompt: String
		var explain: String
		if level == 1:
			speeds = {names[0]: [a, 1], names[1]: [b, 1]}
			prompt = ("%s's and %s's %s are exactly alike. %s's %s %d m each second; %s's %s %d m each second. "
				+ "Which has more energy?") % [names[0], names[1], mover[1], names[0], mover[2], a, names[1], mover[2], b]
			explain = "The same speed gives the same energy." if same else "%s's %s is faster, so it has more energy of motion." % [
				names[0] if a > b else names[1], mover[0]]
		else:
			var d := a * b * rng.randi_range(1, 2)   # a distance both times divide
			speeds = {names[0]: [d, d / a], names[1]: [d, d / b]}
			prompt = ("%s's and %s's %s are exactly alike. Both %s %d m. %s's takes %d seconds; %s's takes %d seconds. "
				+ "Which has more energy?") % [names[0], names[1], mover[1], mover[3], d, names[0], d / a, names[1], d / b]
			explain = "They take the same time, so they are just as fast and have the same energy." if same else \
				"%s's %s takes less time for the same distance, so it is faster and has more energy." % [
					names[0] if a > b else names[1], mover[0]]
		if not same:
			right = "%s's %s" % [names[0] if a > b else names[1], mover[0]]
		var wrongs: Array = ["%s's %s" % [names[0], mover[0]], "%s's %s" % [names[1], mover[0]], "They have the same energy"]
		ex = K.choice(rng, prompt, right, wrongs.filter(func(w: String) -> bool: return w != right),
			"The faster of two things just alike has more energy."
				+ ("" if level == 1 else " Less time for the same distance means faster."),
			explain)
	ex.data = {"speeds": speeds}
	return ex


## "Put these identical carts in order from least energy to most." (speeds; level 3: distances in the same time)
static func energy_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var mover: Array = MOVERS[rng.randi_range(0, MOVERS.size() - 1)]
	var n := 3 if level == 1 else 4
	var vs := _distinct(rng, n, 1, 9)
	vs.sort()
	var in_order: Array = []
	var prompt: String
	var explain: String
	if level < 3:
		for v: int in vs:
			in_order.append("%s %d m each second" % [mover[2], v])
		prompt = "%s %s, exactly alike, %s at different speeds. Put them in order from least energy to most." % [
			"Three" if n == 3 else "Four", mover[1], mover[3]]
		explain = "Slowest first: %s m each second. The faster, the more energy." % ", ".join(
			vs.map(func(v: int) -> String: return str(v)))
	else:
		var t := rng.randi_range(2, 4)
		for v: int in vs:
			in_order.append("%s %d m" % [mover[2], v * t])
		prompt = "Four %s, exactly alike, %s for %d seconds each. Put them in order from least energy to most." % [mover[1],
			mover[3], t]
		explain = "In the same time, the one that goes furthest is fastest and has the most energy: %s m." % ", ".join(
			vs.map(func(v: int) -> String: return str(v * t)))
	var ex := K.order(rng, prompt, in_order, "The faster something moves, the more energy it has.", explain)
	ex.data = {"speeds": vs}
	return ex


# --- Energy on the move (4-PS3-2, 4-PS3-4) ------------------------------------------------------------------------

## "How does the energy travel here? A drum's beat reaches your ears." (sound, light, heat or an electric current)
static func energy_travels(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick_level(rng, TRAVELS, level)
	var form: String = row[1]
	var wrongs: Array = []
	for f in FORMS:
		if f != form:
			wrongs.append("by " + f)
	var ex := K.choice(rng, "How does the energy travel here?  %s" % row[0], "by " + form, wrongs,
		"Sound is heard, light is seen, heat is felt as warmth, and an electric current flows along wires.",
		"It travels by %s." % form)
	ex.data = {"situation": row[0], "form": form}
	return ex


## "A doorbell is built to change electricity into what?" (levels 1-2); "A solar panel makes electricity. What kind of
## energy does it change into electricity?" (level 3)
static func energy_changes(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick_level(rng, DEVICES, level)
	var device: String = row[0]
	var energy: String = row[2]
	var article := "An" if "aeiou".contains(device.left(1)) else "A"
	var ex: Dictionary
	if str(row[1]) == "from electricity":
		ex = K.choice(rng, "%s %s is built to change electricity into what?" % [article, device], energy,
			ENERGIES.filter(func(e: String) -> bool: return e != energy),
			"Think of what the %s is for: what do you see, hear or feel when it is working?" % device,
			"%s %s changes electricity into %s." % [article, device, energy])
	else:
		ex = K.choice(rng, "%s %s makes electricity. What kind of energy does it change into electricity?" % [article, device],
			energy, ENERGIES.filter(func(e: String) -> bool: return e != energy),
			"What does the %s take in: light, sound, motion or heat?" % device,
			"%s %s changes %s into electricity." % [article, device, energy])
	ex.data = {"device": device, "energy": energy}
	return ex


# --- Waves (4-PS4-1) ----------------------------------------------------------------------------------------------

## "Which wave has the bigger amplitude?" / "…the longer wavelength?" (level 3: three waves, and which carries the
## most energy when their wavelengths match)
static func wave_compare(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 3 if level == 3 else 2
	var asks: Array = [["bigger amplitude"]] if level == 1 else [["bigger amplitude", "smaller amplitude"],
		["longer wavelength", "shorter wavelength"]]
	if level == 3:
		asks.append(["most energy"])
	var group: Array = asks[rng.randi_range(0, asks.size() - 1)]
	var asked: String = group[rng.randi_range(0, group.size() - 1)]
	var by_amp := asked.ends_with("amplitude") or asked == "most energy"
	var same := level == 2 and rng.randf() < 0.15   # two waves only: "the same" never hides a third
	var amps := _distinct(rng, n, 1, 4)
	var counts := _distinct(rng, n, 1, 6)
	if by_amp:
		var c := rng.randi_range(2, 4)
		counts = []
		for i in n:
			counts.append(c if asked == "most energy" or level == 1 else rng.randi_range(1, 6))
		if same:
			amps[1] = amps[0]
	elif same:
		counts[1] = counts[0]
	var waves: Array = []
	for i in n:
		waves.append({"amp": amps[i], "count": counts[i]})
	var names: Array[String] = ["wave A", "wave B", "wave C"]
	var values: Array = []
	for i in n:
		values.append(amps[i] if by_amp else -counts[i])
	var want_big := asked.begins_with("bigger") or asked.begins_with("longer") or asked == "most energy"
	var best: int = values.max() if want_big else values.min()
	var right := "They are the same" if values.count(best) > 1 else names[values.find(best)]
	var choices: Array = names.slice(0, n)
	choices.append("They are the same")
	var superlative := {"bigger amplitude": "biggest amplitude", "smaller amplitude": "smallest amplitude",
		"longer wavelength": "longest wavelength", "shorter wavelength": "shortest wavelength"}
	var question := "Which wave carries the most energy?" if asked == "most energy" else "Which wave has the %s?" % (
		superlative[asked] if n == 3 else asked)
	var hint := "The amplitude is how tall a wave is, from its middle line to a crest." if by_amp else \
		"The wavelength is the distance from one crest to the next. Crests far apart: a long wavelength."
	if asked == "most energy":
		hint = "These waves are just as long. The taller a wave, the more energy it carries."
	var why := "its crests stand highest above the middle line"
	if asked == "most energy":
		why = "it is the tallest, so it carries the most energy"
	elif by_amp and not want_big:
		why = "its crests stand lowest above the middle line"
	elif not by_amp:
		why = "its crests are furthest apart" if want_big else "its crests are closest together"
	var explain := ("Their %s match." % ("amplitudes" if by_amp else "wavelengths")) if right == "They are the same" else \
		"%s: %s." % [_cap(right), why]
	var ex := K.choice(rng, question, right, choices.filter(func(c: String) -> bool: return c != right), hint, explain,
		{"kind": "wave", "waves": waves, "names": true})
	ex.data = {"asked": asked}
	return ex


## "How many whole wavelengths are in this picture?" (level 3: "This rope is 12 m long …: how long is one wavelength?")
static func wave_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var count := rng.randi_range([1, 2, 2][level - 1], [3, 5, 6][level - 1])
	var picture := {"kind": "wave", "waves": [{"amp": rng.randi_range(2, 4), "count": count}]}
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.6:
		var wl := rng.randi_range(2, 5)
		ex = K.number("This wave on a rope is %d m long, from end to end. How long is one wavelength?" % (wl * count), wl,
			"Count the whole waves, then share the length between them.",
			"There are %d whole waves in %d m: %d ÷ %d = %d m each." % [count, wl * count, wl * count, count, wl], picture)
		ex.data = {"length": wl * count}
		return ex
	var crests := rng.randf() < 0.5
	ex = K.number("How many %s are in this picture?" % ("crests" if crests else "whole wavelengths"), count,
		"A crest is a top of the wave." if crests else "One wavelength goes from a crest to the next crest: one up and one down.",
		"Count them: %d." % count, picture)
	ex.data = {"count": count}
	return ex


## "Put the waves in order from the smallest amplitude to the biggest." (level 3: from the shortest wavelength)
static func wave_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var by_amp := level < 3 or rng.randf() < 0.4
	var amps := _distinct(rng, 3, 1, 4)
	var counts := _distinct(rng, 3, 1, 6)
	if by_amp:
		var c := rng.randi_range(2, 4)
		counts = [c, c, c] if level == 1 else [rng.randi_range(1, 6), rng.randi_range(1, 6), rng.randi_range(1, 6)]
	var waves: Array = []
	for i in 3:
		waves.append({"amp": amps[i], "count": counts[i]})
	var idx: Array = [0, 1, 2]
	idx.sort_custom(func(a: int, b: int) -> bool:
		return amps[a] < amps[b] if by_amp else counts[a] > counts[b])
	var in_order: Array = []
	for i: int in idx:
		in_order.append(["wave A", "wave B", "wave C"][i])
	var ex := K.order(rng, "Put the waves in order from the %s." % ("smallest amplitude to the biggest" if by_amp else
		"shortest wavelength to the longest"), in_order,
		"The amplitude is how tall a wave is." if by_amp else "Crests close together mean a short wavelength.",
		"From the %s: %s." % ["smallest amplitude" if by_amp else "shortest wavelength", ", ".join(in_order)],
		{"kind": "wave", "waves": waves, "names": true})
	ex.data = {"by_amp": by_amp}
	return ex


# --- Light and seeing (4-PS4-2) -----------------------------------------------------------------------------------

## "Zara sees the pumpkin by the light of the lantern. Put the light's path in order." (level 3: in a mirror)
static func light_path(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var source: Array = SOURCES[rng.randi_range(0, 1 if level == 1 else SOURCES.size() - 1)]
	var lit: Array = LIT[rng.randi_range(0, LIT.size() - 1)]
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var eyes := "%s's eyes" % who
	var picture := {}
	if str(source[1]) != "":
		picture = {"kind": "rays", "source": source[1], "object": lit[1], "mirror": level == 3}
	var ex: Dictionary
	if level == 3:
		ex = K.order(rng, "%s sees %s in a mirror, lit by %s. Put the light's path in order, from start to end." % [who,
			lit[0], source[0]], [source[0], lit[0], "the mirror", eyes],
			"Light starts at its source. What does it bounce off before it reaches the eyes?",
			"%s makes the light; it bounces off %s, then off the mirror, and into %s." % [_cap(source[0]), lit[0], eyes],
			picture)
	else:
		ex = K.order(rng, "%s sees %s by the light of %s. Put the light's path in order, from start to end." % [who, lit[0],
			source[0]], [source[0], lit[0], eyes], "Light starts at its source. Eyes do not send light out: they take it in.",
			"%s makes the light; it bounces off %s and goes into %s." % [_cap(source[0]), lit[0], eyes], picture)
	ex.data = {"source": source[0]}
	return ex


## "Which of these is a source of light?" (level 2: which is NOT; level 3: "… makes its own light." true or false)
static func light_source(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var thing: String = TRICKY[rng.randi_range(0, TRICKY.size() - 1)]
		var makes := MAKES_LIGHT.has(thing)
		ex = K.truefalse("%s makes its own light." % _cap(thing), makes,
			"A source of light makes light. Other things are seen only when light bounces off them.",
			"%s %s." % [_cap(thing), "makes its own light" if makes else
				"makes no light of its own: we see it by the light it bounces"])
		ex.data = {"thing": thing}
		return ex
	var sources := _copy(MAKES_LIGHT)
	var others := _copy(NO_LIGHT)
	K.shuffle(rng, sources)
	K.shuffle(rng, others)
	if level == 1:
		ex = K.choice(rng, "Which of these is a source of light?", sources[0], others.slice(0, 3),
			"A source of light makes its own light.", "%s makes its own light; the others only bounce light." % _cap(sources[0]))
		ex.data = {"right": sources[0]}
	else:
		ex = K.choice(rng, "Which of these is NOT a source of light?", others[0], sources.slice(0, 3),
			"Which one makes no light of its own?", "%s makes no light of its own; the others do." % _cap(others[0]))
		ex.data = {"right": others[0]}
	return ex


# --- Sending messages with patterns (4-PS4-3) ---------------------------------------------------------------------

## "This picture was sent as 1s and 0s. How many dark squares does it have?" (or light ones)
static func pixel_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var size: Vector2i = [Vector2i(3, 3), Vector2i(5, 4), Vector2i(6, 5)][level - 1]
	var rows := _pixels(rng, size)
	var dark := level < 3 or rng.randf() < 0.5
	var n := 0
	for row: String in rows:
		n += row.count("1" if dark else "0")
	var ex := K.number("How many %s squares are in this picture?" % ("dark" if dark else "light"), n,
		"Count row by row. In the code, each %s square is a %s." % ["dark" if dark else "light", "1" if dark else "0"],
		"There are %d %s squares, so %d of the picture's numbers are %ss." % [n, "dark" if dark else "light", n,
			"1" if dark else "0"],
		{"kind": "pixels", "rows": rows})
	ex.data = {"dark": dark}
	return ex


## "1 means dark, 0 means light. Which numbers send the top row?" (level 3: which picture do the numbers make?)
static func pixel_row(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var rows := _pixels(rng, Vector2i(3, 3))
		var sent := " / ".join(rows)
		var wrongs: Array = []
		for v in _pixel_variants(rng, rows):
			wrongs.append({"picture": {"kind": "pixels", "rows": v}})
		ex = K.choice(rng, "1 means dark and 0 means light. The rows are split by /. Which picture do these numbers make?  %s" % sent,
			{"picture": {"kind": "pixels", "rows": rows}}, wrongs, "Paint the first row from the first numbers, then the next.",
			"%s: row by row, a dark square for each 1." % sent)
		ex.data = {"rows": sent}
		return ex
	var size: Vector2i = [Vector2i(4, 3), Vector2i(5, 4)][level - 1]
	var rows := _pixels(rng, size)
	var r := 0 if level == 1 else rng.randi_range(0, size.y - 1)
	var right := _spaced(rows[r])
	var flipped := ""
	for ch in str(rows[r]):
		flipped += "0" if ch == "1" else "1"
	var candidates: Array = [flipped, _reversed(rows[r])]
	for i in size.y:
		candidates.append(rows[i])
	for i in 20:
		candidates.append(_pixels(rng, Vector2i(size.x, 1))[0])
	var wrongs: Array = []
	for c: String in candidates:
		if c != rows[r] and not wrongs.has(_spaced(c)) and wrongs.size() < 3:
			wrongs.append(_spaced(c))
	var which: String = ["top", "second", "third"][r] if r < 3 else "bottom"
	if r == size.y - 1:
		which = "bottom"
	ex = K.choice(rng, "1 means a dark square and 0 a light one. Which numbers send the %s row?" % which, right,
		wrongs, "Read the %s row from left to right: dark is 1, light is 0." % which,
		"The %s row, left to right: %s." % [which, right], {"kind": "pixels", "rows": rows})
	ex.data = {"row": r}
	return ex


## "A picture is 6 squares wide and 4 tall. How many 1s and 0s does it take to send it?" (level 3: at 10 numbers a
## second, how many seconds?)
static func pixel_size(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range([2, 4, 10][level - 1], [5, 12, 30][level - 1])
	var h := rng.randi_range([2, 3, 10][level - 1], [5, 10, 20][level - 1])
	var ex: Dictionary
	if level == 3:
		h = rng.randi_range(1, 2) * 10
		ex = K.number(("A picture is %d squares wide and %d squares tall. Zara's machine sends 10 of its 1s and 0s "
			+ "each second. How many seconds does the whole picture take?") % [w, h],
			w * h / 10, "First find how many squares there are, one number for each. Then share them into tens.",
			"%d × %d = %d numbers; %d ÷ 10 = %d seconds." % [w, h, w * h, w * h, w * h / 10])
		ex.data = {"w": w, "h": h, "per_second": 10}
		return ex
	ex = K.number("A picture is %d squares wide and %d squares tall. How many 1s and 0s does it take to send it?" % [w, h],
		w * h, "Each square is sent as one number: a 1 or a 0. How many squares are there?",
		"%d rows of %d squares: %d × %d = %d numbers." % [h, w, h, w, w * h])
	ex.data = {"w": w, "h": h}
	return ex


## "Drum code: A = 1 beat … Which word is 3, 1, 2 beats?" (level 3: how many beats does a word take in all?)
static func beat_code(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick_level(rng, BEAT_WORDS, level)
	var word: String = row[0]
	var beats: Array[String] = []
	var total := 0
	for ch in word:
		var b := ch.unicode_at(0) - "A".unicode_at(0) + 1
		beats.append(str(b))
		total += b
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.5:
		ex = K.number("%s How many beats does the word %s take in all?" % [DRUM, word], total,
			"Find each letter's beats, then add them up.",
			"%s: %s = %d beats." % [word, " + ".join(beats), total])
	else:
		var wrongs: Array = []
		for other: Array in BEAT_WORDS:
			if str(other[0]).length() == word.length() and other[0] != word:
				wrongs.append(other[0])
		wrongs.append(_reversed(word))
		K.shuffle(rng, wrongs)
		wrongs = wrongs.filter(func(w: String) -> bool: return w != word).slice(0, 3)
		ex = K.choice(rng, "%s Which word is %s beats?" % [DRUM, ", ".join(beats)], word, wrongs,
			"Turn each number back into its letter: 1 is A, 2 is B, and so on.",
			"%s is %s." % [", ".join(beats), word])
	ex.data = {"word": word}
	return ex


## "Morse code: letters are split by /. Which word is • • • / • / • — ?" (level 3: also the other way: the code of a
## word); the code's table is shown.
static func morse_word(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row: Array = _pick_level(rng, MORSE_WORDS, level)
	var word: String = row[0]
	var letters: Array = []
	for ch in word:
		if not letters.has(ch):
			letters.append(ch)
	var extra: Array = MORSE.keys().filter(func(l: String) -> bool: return not letters.has(l))
	K.shuffle(rng, extra)
	while letters.size() < 5 and not extra.is_empty():
		letters.append(extra.pop_back())
	letters.sort()
	var codes: Array = []
	for l: String in letters:
		codes.append(MORSE[l])
	var picture := {"kind": "table", "rows": [letters, codes]}
	var sent := _morse(word)
	var ex: Dictionary
	var others: Array = []
	for w: Array in MORSE_WORDS:
		if str(w[0]).length() == word.length() and w[0] != word:
			others.append(w[0])
	K.shuffle(rng, others)
	if level == 3 and rng.randf() < 0.5:
		var wrongs: Array = [_morse(_reversed(word))]
		for o: String in others:
			wrongs.append(_morse(o))
		wrongs = wrongs.filter(func(w: String) -> bool: return w != sent).slice(0, 3)
		ex = K.choice(rng, "Morse code: letters are split by /. Which is the code for %s?" % word, sent, wrongs,
			"Look up each letter of %s in the table, in order." % word, "%s is %s." % [word, sent], picture)
	else:
		ex = K.choice(rng, "Morse code: letters are split by /. Which word does this code spell?  %s" % sent, word,
			others.slice(0, 3),
			"Find each part in the table: • is a short signal, — a long one.", "%s spells %s." % [sent, word], picture)
	ex.data = {"word": word}
	return ex


# --- Helpers ------------------------------------------------------------------------------------------------------

static func _names(rng: RandomNumberGenerator, n: int) -> Array[String]:
	var all: Array = _copy(NAMES)
	K.shuffle(rng, all)
	var out: Array[String] = []
	for i in n:
		out.append(str(all[i]))
	return out


## `n` different whole numbers from lo to hi (unsorted).
static func _distinct(rng: RandomNumberGenerator, n: int, lo: int, hi: int) -> Array:
	var all: Array = range(lo, hi + 1)
	K.shuffle(rng, all)
	return all.slice(0, n)


static func _other(rng: RandomNumberGenerator, not_this: int, lo: int, hi: int) -> int:
	var v := rng.randi_range(lo, hi - 1)
	return v + 1 if v >= not_this else v


## A row of this level, or an easier one (this level's rows twice as often).
static func _pick_level(rng: RandomNumberGenerator, rows: Array, level: int) -> Array:
	var pool: Array = []
	for row: Array in rows:
		if int(row.back()) <= level:
			pool.append(row)
			if int(row.back()) == level:
				pool.append(row)
	return pool[rng.randi_range(0, pool.size() - 1)]


## A random picture of 1s and 0s, `size` (columns, rows), with dark and light squares in every picture.
static func _pixels(rng: RandomNumberGenerator, size: Vector2i) -> Array:
	var rows: Array = []
	for y in size.y:
		var row := ""
		for x in size.x:
			row += "1" if rng.randf() < 0.5 else "0"
		rows.append(row)
	var all := "".join(rows)
	if not all.contains("1") or not all.contains("0"):
		rows[0] = "1" + str(rows[0]).substr(1) if not all.contains("1") else "0" + str(rows[0]).substr(1)
	return rows


## Three pictures a little different from `rows` (one square changed, dark and light swapped, turned left to right).
static func _pixel_variants(rng: RandomNumberGenerator, rows: Array) -> Array:
	var out: Array = []
	var inverted: Array = []
	var mirrored: Array = []
	for row: String in rows:
		var inv := ""
		for ch in row:
			inv += "0" if ch == "1" else "1"
		inverted.append(inv)
		mirrored.append(_reversed(row))
	for cand: Array in [inverted, mirrored]:
		if cand != rows and not out.has(cand):
			out.append(cand)
	var guard := 0
	while out.size() < 3 and guard < 60:
		guard += 1
		var changed := rows.duplicate()
		var y := rng.randi_range(0, rows.size() - 1)
		var x := rng.randi_range(0, str(rows[y]).length() - 1)
		var row := str(changed[y])
		changed[y] = row.substr(0, x) + ("0" if row[x] == "1" else "1") + row.substr(x + 1)
		if not out.has(changed):
			out.append(changed)
	return out


## A plain, writable copy (a const array stays read-only when duplicated).
static func _copy(a: Array) -> Array:
	var out: Array = []
	out.append_array(a)
	return out


## "the Moon" -> "The Moon" (only the first letter).
static func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)


static func _spaced(row: String) -> String:
	var parts: Array[String] = []
	for ch in row:
		parts.append(ch)
	return " ".join(parts)


static func _reversed(s: String) -> String:
	var out := ""
	for i in range(s.length() - 1, -1, -1):
		out += s[i]
	return out


static func _morse(word: String) -> String:
	var parts: Array[String] = []
	for ch in word:
		parts.append(str(MORSE[ch]))
	return " / ".join(parts)
