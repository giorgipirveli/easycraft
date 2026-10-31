class_name G4MeasureGen
extends RefCounted
## Owner #68 (spec §22.5): grade 4 maths generators for measurement, data and geometry (Common Core 4.MD, 4.G; units
## 13-17 of the outline): SchoolGen "g4g.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) ->
## Dictionary`, seeded, level 1-3, each with a hint, a worked answer and `data` (its inputs, for tests). Metric units,
## time and gold (spec §22.6 ruling 4). Shapes and their facts come from ShapeFacts. Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]
## [big unit, small unit, how many small in one big]
const CONVERSIONS: Array = [["km", "m", 1000], ["m", "cm", 100], ["cm", "mm", 10], ["kg", "g", 1000], ["L", "mL", 1000],
	["hours", "minutes", 60], ["minutes", "seconds", 60], ["days", "hours", 24]]
## [what is measured, the unit, wrong units that are clearly wrong]
const UNIT_CHOICES: Array = [
	["the length of a pencil", "centimetres", ["kilometres", "kilograms", "litres"]],
	["the distance to the next village", "kilometres", ["centimetres", "grams", "millilitres"]],
	["how tall a door is", "metres", ["kilometres", "grams", "minutes"]],
	["how heavy a dog is", "kilograms", ["grams", "litres", "metres"]],
	["how heavy a strawberry is", "grams", ["kilograms", "kilometres", "hours"]],
	["how much water a bath holds", "litres", ["millilitres", "metres", "grams"]],
	["how much medicine fits on a spoon", "millilitres", ["litres", "kilograms", "kilometres"]],
	["how long a sneeze lasts", "seconds", ["hours", "days", "metres"]],
	["how long a football match lasts", "minutes", ["seconds", "days", "kilograms"]],
	["how long a flight across the ocean takes", "hours", ["seconds", "grams", "centimetres"]],
	["how thick a coin is", "millimetres", ["metres", "kilometres", "litres"]],
	["how heavy a horse is", "kilograms", ["grams", "millilitres", "centimetres"]],
]
## Angle fractions of a full turn: [top, bottom, degrees].
const TURNS: Array = [[1, 4, 90], [1, 2, 180], [3, 4, 270], [1, 3, 120], [1, 6, 60], [1, 12, 30], [1, 8, 45], [1, 36, 10],
	[2, 3, 240], [1, 360, 1]]
const LINE_WORDS := {"point": "point", "line": "line", "ray": "ray", "segment": "line segment", "parallel": "parallel lines",
	"perpendicular": "perpendicular lines", "intersecting": "intersecting lines"}
## A shape and the names it could never be mistaken for being (a square is also a rectangle: never both in one question).
const SHAPE_WRONGS := {
	"square": ["pentagon", "triangle_right", "trapezium", "hexagon"],
	"rectangle": ["square", "kite", "pentagon", "triangle_obtuse"],
	"rhombus": ["rectangle", "trapezium", "pentagon", "triangle_acute"],
	"parallelogram": ["kite", "rectangle", "hexagon", "triangle_equal"],
	"trapezium": ["parallelogram", "rectangle", "kite", "pentagon"],
	"kite": ["trapezium", "parallelogram", "hexagon", "triangle_right"],
	"triangle_right": ["triangle_equal", "square", "kite", "pentagon"],
	"triangle_obtuse": ["triangle_right", "triangle_equal", "rhombus", "hexagon"],
	"triangle_equal": ["triangle_right", "triangle_obtuse", "square", "hexagon"],
	"pentagon": ["hexagon", "octagon", "square", "triangle_equal"],
	"hexagon": ["pentagon", "octagon", "rectangle", "kite"],
	"octagon": ["hexagon", "pentagon", "circle", "square"],
}


# --- Unit 13: measure and convert (4.MD.1, 4.MD.2) ----------------------------------------------------------------

## "3 km = ? m", "3 km 250 m = ? m", "4 1/2 hours = ? minutes"
static func convert_units(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c: Array = CONVERSIONS[rng.randi_range(0, CONVERSIONS.size() - 1)]
	var big: String = c[0]
	var small: String = c[1]
	var k: int = c[2]
	var n := rng.randi_range(2, 9)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("%d %s = ? %s" % [n, big, small], n * k, "1 %s = %s %s." % [_one(big), K.fmt(k), small],
				"%d × %s = %s %s" % [n, K.fmt(k), K.fmt(n * k), small])
		2:
			var extra := rng.randi_range(1, k - 1)
			ex = K.number("%d %s %d %s = ? %s" % [n, big, extra, small, small], n * k + extra,
				"Change the %s into %s, then add the %d %s." % [big, small, extra, small],
				"%d × %s = %s, and %s + %d = %s %s." % [n, K.fmt(k), K.fmt(n * k), K.fmt(n * k), extra, K.fmt(n * k + extra), small])
		_:
			var top := 1
			var bottom := 2
			if k % 4 == 0 and rng.randf() < 0.5:
				top = [1, 3][rng.randi_range(0, 1)]
				bottom = 4
			var value := n * k + int(k * top / float(bottom))
			ex = K.number("%d %d/%d %s = ? %s" % [n, top, bottom, big, small], value,
				"%d/%d of 1 %s is %s %s." % [top, bottom, _one(big), K.fmt(int(k * top / float(bottom))), small],
				"%d %s = %s %s and %d/%d %s = %s %s: %s %s." % [n, big, K.fmt(n * k), small, top, bottom, _one(big),
					K.fmt(int(k * top / float(bottom))), small, K.fmt(value), small])
	ex.data = {"big": big, "small": small, "k": k, "n": n}
	return ex


## "Which unit would you use to measure how heavy a dog is?"
static func which_unit(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var row: Array = UNIT_CHOICES[rng.randi_range(0, UNIT_CHOICES.size() - 1)]
	var ex := K.choice(rng, "Which unit would you use to measure %s?" % row[0], row[1], row[2],
		"Is it a length, a mass (how heavy), a capacity (how much it holds) or a time? Then think how big it is.",
		"We measure %s in %s." % [row[0], row[1]])
	ex.data = {"row": row}
	return ex


static func measure_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var ex: Dictionary
	match rng.randi_range(0, 3 if level > 1 else 2):
		0:
			var km := rng.randi_range(1, 5)
			var walked := rng.randi_range(1, km * 100 - 1) * 10
			ex = K.number("A path is %d km long. %s has walked %s m. How many more metres to the end?" % [km, who, K.fmt(walked)],
				km * 1000 - walked, "Change %d km into metres first." % km,
				"%d km = %s m, and %s − %s = %s m." % [km, K.fmt(km * 1000), K.fmt(km * 1000), K.fmt(walked), K.fmt(km * 1000 - walked)])
		1:
			var litres := rng.randi_range(1, 3)
			var poured := rng.randi_range(1, litres * 20 - 1) * 50
			ex = K.number("A potion bottle holds %d L. %s pours out %s mL. How many millilitres are left?" % [litres, who,
				K.fmt(poured)], litres * 1000 - poured, "1 L = 1,000 mL.",
				"%d L = %s mL, and %s − %s = %s mL." % [litres, K.fmt(litres * 1000), K.fmt(litres * 1000), K.fmt(poured),
					K.fmt(litres * 1000 - poured)])
		2:
			var kg := rng.randi_range(1, 4)
			var used := rng.randi_range(1, kg * 10 - 1) * 100
			ex = K.number("A bag of flour weighs %d kg. %s uses %s g for a cake. How many grams are left?" % [kg, who, K.fmt(used)],
				kg * 1000 - used, "1 kg = 1,000 g.", "%d kg = %s g, and %s − %s = %s g." % [kg, K.fmt(kg * 1000),
					K.fmt(kg * 1000), K.fmt(used), K.fmt(kg * 1000 - used)])
		_:
			var n := rng.randi_range(3, 9)
			var price := rng.randi_range(12, 60) * 5
			var cost := rng.randi_range(1, int(n * price / 2.0 / 10.0)) * 10
			ex = K.number("Tilly sells %d lanterns for %d gold each. She spends %d gold on wood. How much gold does she keep?" % [n,
				price, cost], n * price - cost, "Two steps: what the lanterns bring, then take away the wood.",
				"%d × %d = %s gold, and %s − %d = %s gold." % [n, price, K.fmt(n * price), K.fmt(n * price), cost, K.fmt(n * price - cost)])
	ex.data = {"answer": ex.answer}
	return ex


## "Zara starts building at 3:15 and builds for 45 minutes. At what time does she stop?" (with the clock)
static func time_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var h := rng.randi_range(1, 10)
	var m := rng.randi_range(0, 11) * 5
	var minutes := rng.randi_range(2, 9) * 5 if level == 1 else rng.randi_range(4, 20) * 5
	var end := h * 60 + m + minutes
	var right := _clock(end)
	var ex := K.choice(rng, "%s starts building at %s and builds for %d minutes. At what time does %s stop?" % [who, _clock(h * 60 + m),
		minutes, who], right, [_clock(end + 15), _clock(end - 15), _clock(end + 60)],
		"Count on from %s: first to the next hour, then the minutes left." % _clock(h * 60 + m),
		"%s + %d minutes = %s." % [_clock(h * 60 + m), minutes, right], {"kind": "clock", "h": h, "m": m})
	ex.data = {"start": h * 60 + m, "minutes": minutes}
	return ex


## A conversion table with one "?"
static func conversion_table(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c: Array = CONVERSIONS[rng.randi_range(0, CONVERSIONS.size() - 1)]
	var k: int = c[2]
	var ask := rng.randi_range(4, 9) if level > 1 else 3
	var rows: Array = [[c[0], c[1]], ["1", K.fmt(k)], ["2", K.fmt(2 * k)], [str(ask), "?"]]
	var ex := K.number("Finish the table: how many %s are in %d %s?" % [c[1], ask, c[0]], ask * k,
		"Each row adds %s %s." % [K.fmt(k), c[1]], "%d × %s = %s %s" % [ask, K.fmt(k), K.fmt(ask * k), c[1]],
		{"kind": "table", "rows": rows})
	ex.data = {"k": k, "ask": ask}
	return ex


# --- Unit 14: area and perimeter (4.MD.3) --------------------------------------------------------------------------

static func area(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f := _farm(rng, level)
	var ex := K.number("What is the area of this farm, in square metres?", f.w * f.h, "Area = length × width.",
		"%d × %d = %d square metres." % [f.w, f.h, f.w * f.h], f.picture)
	ex.data = {"w": f.w, "h": f.h}
	return ex


static func perimeter(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f := _farm(rng, level)
	var ex := K.number("How long is the fence all the way round this farm, in metres?", 2 * (f.w + f.h),
		"Add all four sides: two long sides and two short sides.",
		"%d + %d + %d + %d = %d m." % [f.w, f.h, f.w, f.h, 2 * (f.w + f.h)], f.picture)
	ex.data = {"w": f.w, "h": f.h}
	return ex


## "This farm has an area of 48 square metres. How long is the side marked ?"
static func missing_side(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(3, 12)
	var h := rng.randi_range(2, 9)
	var by_area := level < 3 or rng.randf() < 0.5
	var pic := {"kind": "rect", "w": mini(w, 12), "h": mini(h, 12), "unit": "m", "grid": false, "unknown": "w"}
	var ex: Dictionary
	if by_area:
		ex = K.number("This farm has an area of %d square metres. How long is the side marked ?" % (w * h), w,
			"Area = length × width. Which number times %d makes %d?" % [h, w * h], "%d × %d = %d, so the side is %d m." % [w, h,
				w * h, w], pic)
	else:
		ex = K.number("The fence all the way round this farm is %d m long. How long is the side marked ?" % (2 * (w + h)), w,
			"Half the fence is one long side and one short side.", "%d ÷ 2 = %d, and %d − %d = %d m." % [2 * (w + h), w + h,
				w + h, h, w], pic)
	ex.data = {"w": w, "h": h, "by_area": by_area}
	return ex


## "Build a farm with an area of 12 and a fence of 14."
static func build_farm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(2, 6)
	var h := rng.randi_range(2, 5)
	var goal := {"kind": "rectangle", "area": w * h}
	var prompt := "Build a farm with an area of %d squares." % (w * h)
	if level >= 2:
		goal.perimeter = 2 * (w + h)
		prompt = "Build a farm with an area of %d squares and a fence of %d all the way round." % [w * h, 2 * (w + h)]
	var ex := K.build(prompt, {"cols": 10, "rows": 7, "block": BlockIds.GRASS, "given": [], "view": "farm"}, goal,
		"Try a rectangle: how many rows, and how many squares in each row?",
		"A %d by %d farm has an area of %d and a fence of %d." % [w, h, w * h, 2 * (w + h)])
	ex.data = {"w": w, "h": h}
	return ex


## "A 2 by 6 farm and a 3 by 4 farm have the same area. They have the same perimeter too." True or false?
static func same_area(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var areas: Array[int] = [12, 16, 18, 20, 24, 36]
	var n: int = areas[rng.randi_range(0, areas.size() - 1)]
	var dims: Array = []
	for f in range(1, n + 1):
		if n % f == 0 and f * f <= n and f > 1:
			dims.append([f, int(n / float(f))])
	if dims.size() < 2:
		dims.append([1, n])
	K.shuffle(rng, dims)
	var a: Array = dims[0]
	var b: Array = dims[1]
	var pa: int = 2 * (a[0] + a[1])
	var pb: int = 2 * (b[0] + b[1])
	var ex: Dictionary
	if rng.randf() < 0.4:
		ex = K.truefalse("A %d by %d farm and a %d by %d farm both have an area of %d. They have the same perimeter too." % [
			a[0], a[1], b[0], b[1], n], pa == pb, "Work out both fences: add the four sides.",
			"The fences are %d m and %d m: the same area does not mean the same perimeter." % [pa, pb])
	else:
		ex = K.truefalse("A %d by %d farm and a %d by %d farm both have an area of %d. The %d by %d farm needs the longer fence." % [
			a[0], a[1], b[0], b[1], n, a[0], a[1]], pa > pb, "Work out both fences: add the four sides.",
			"The %d by %d farm's fence is %d m and the %d by %d farm's is %d m." % [a[0], a[1], pa, b[0], b[1], pb])
	ex.data = {"a": a, "b": b}
	return ex


# --- Unit 15: line plots (4.MD.4) -------------------------------------------------------------------------------

## "How many sticks are 3/8 m long?" / "How many sticks were measured?"
static func plot_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p := _plot(rng, level)
	var counts: Dictionary = p.counts
	var ex: Dictionary
	if rng.randf() < 0.5:
		var keys := counts.keys()
		var k: String = keys[rng.randi_range(0, keys.size() - 1)]
		ex = K.number("How many sticks are %s/%d m long?" % [k, p.den], int(counts[k]), "Count the Xs above %s/%d." % [k, p.den],
			"There are %d Xs above %s/%d." % [int(counts[k]), k, p.den], p)
	else:
		var total := 0
		for key: String in counts:
			total += int(counts[key])
		ex = K.number("How many sticks were measured?", total, "Every X is one stick: count them all.",
			"There are %d Xs, so %d sticks." % [total, total], p)
	ex.data = {"counts": counts, "den": p.den}
	return ex


## "What is the difference between the longest and the shortest stick?" / "the 3/8 m sticks end to end"
static func plot_math(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p := _plot(rng, level)
	var counts: Dictionary = p.counts
	var den: int = p.den
	var lo := 99
	var hi := -1
	for key: String in counts:
		lo = mini(lo, int(key))
		hi = maxi(hi, int(key))
	var ex: Dictionary
	if level < 3 or rng.randf() < 0.5:
		ex = K.number("What is the difference in length between the longest and the shortest stick, in metres?",
			"%d/%d" % [hi - lo, den], "Find the Xs furthest right and furthest left, then take away.",
			"%d/%d − %d/%d = %d/%d m." % [hi, den, lo, den, hi - lo, den], p)
	else:
		var keys := counts.keys()
		var k: String = keys[rng.randi_range(0, keys.size() - 1)]
		var c := int(counts[k])
		ex = K.number("Pip lays all the %s/%d m sticks end to end. How long is the line, in metres?" % [k, den], "%d/%d" % [
			c * int(k), den], "How many %s/%d m sticks are there? Add them up." % [k, den],
			"%d sticks × %s/%d m = %d/%d m." % [c, k, den, c * int(k), den], p)
	ex.data = {"counts": counts, "den": den}
	return ex


# --- Unit 16: angles (4.MD.5, 4.MD.6, 4.MD.7) ---------------------------------------------------------------------

## "An angle that turns through 1/4 of a full circle measures how many degrees?"
static func turn_degrees(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = TURNS.slice(0, 3) if level == 1 else TURNS
	var t: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.5:
		var deg: int = [10, 15, 20, 30, 40, 45, 60, 90, 120][rng.randi_range(0, 8)]
		ex = K.number("How many turns of %d° make one full turn?" % deg, int(360 / float(deg)), "A full turn is 360°.",
			"360 ÷ %d = %d." % [deg, int(360 / float(deg))])
		ex.data = {"deg": deg}
		return ex
	ex = K.number("An angle that turns through %d/%d of a full circle measures how many degrees?" % [t[0], t[1]], t[2],
		"A full circle is 360°. Find %d/%d of 360." % [t[0], t[1]], "360 ÷ %d × %d = %d°." % [t[1], t[0], t[2]])
	ex.data = {"t": t}
	return ex


## Two angles side by side: "What is the size of the whole angle?"
static func angle_add(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var step := 10 if level == 1 else 5
	var a := rng.randi_range(2, 8) * step
	var b := rng.randi_range(2, 8) * step
	if a + b > 170:
		b = 170 - a
	var ex := K.number("What is the size of the whole angle, in degrees?", a + b, "The whole angle is the two parts added.",
		"%d° + %d° = %d°." % [a, b, a + b], {"kind": "angle", "deg": a + b, "parts": [a, b]})
	ex.data = {"a": a, "b": b}
	return ex


## "The whole angle is a right angle. What is the angle marked ?"
static func angle_missing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var whole: int = [90, 90, 180][rng.randi_range(0, 2)] if level > 1 else 90
	var a := rng.randi_range(2, int(whole / 10.0) - 2) * 10 + (0 if level == 1 else rng.randi_range(0, 1) * 5)
	var names := {90: "a right angle (90°)", 180: "a straight angle (180°)"}
	var ex := K.number("The whole angle is %s. One part is %d°. What is the part marked ?" % [names[whole], a], whole - a,
		"Take the part you know away from the whole.", "%d° − %d° = %d°." % [whole, a, whole - a],
		{"kind": "angle", "deg": whole, "parts": [a, whole - a], "hide": 1})
	ex.data = {"whole": whole, "a": a}
	return ex


## An angle on a protractor: "How many degrees is this angle?"
static func angle_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var deg := rng.randi_range(2, 16) * 10
	if level == 3:
		deg = rng.randi_range(5, 33) * 5
	var right := "%d°" % deg
	var wrongs: Array = []
	if 180 - deg != deg:
		wrongs.append("%d°" % (180 - deg))
	wrongs.append("%d°" % (deg + 10))
	wrongs.append("%d°" % (deg - 10))
	var ex := K.choice(rng, "How many degrees is this angle?", right, wrongs,
		"Start at 0 on the line the angle starts from, and count up to the other line.",
		"From 0 to the second line is %d°." % deg, {"kind": "angle", "deg": deg, "protractor": true})
	ex.data = {"deg": deg}
	return ex


## "About how big is this angle?"
static func angle_estimate(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var sizes: Array[int] = [30, 90, 150]
	var target: int = sizes[rng.randi_range(0, 2)]
	var deg := target + rng.randi_range(-8, 8) if target != 90 else 90
	var ex := K.choice(rng, "About how big is this angle?", "about %d°" % target, ["about 30°", "about 90°",
		"about 150°"].filter(func(x: String) -> bool: return x != "about %d°" % target),
		"Compare it with a right angle (the corner of a square): smaller, the same, or bigger?",
		"It is %s, so about %d°." % [ShapeFacts.angle_kind(deg) + ("" if deg == 90 else " (%s a right angle)" % (
			"smaller than" if deg < 90 else "bigger than")), target], {"kind": "angle", "deg": deg})
	ex.data = {"deg": deg}
	return ex


## "How many one-degree angles fit in a right angle?"
static func one_degree(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var options: Array = [["a right angle", 90], ["a straight angle", 180], ["a full turn", 360]]
	var o: Array = options[rng.randi_range(0, 2)]
	if level > 1 and rng.randf() < 0.5:
		var deg := rng.randi_range(11, 170)
		o = ["an angle of %d°" % deg, deg]
	var ex := K.number("How many one-degree angles fit in %s?" % o[0], o[1], "An angle of n degrees is n one-degree angles.",
		"%d one-degree angles make %s." % [o[1], o[0]])
	ex.data = {"deg": o[1]}
	return ex


# --- Unit 17: lines, shapes and symmetry (4.G.1, 4.G.2, 4.G.3) --------------------------------------------------

static func line_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var group: Array = ["point", "line", "ray", "segment"] if level == 1 or rng.randf() < 0.4 else ["parallel",
		"perpendicular", "intersecting", "segment"]
	var what: String = group[rng.randi_range(0, 2 if group.has("parallel") else 3)]
	var wrongs: Array = []
	for g: String in group:
		if g != what and not (what == "perpendicular" and g == "intersecting"):
			wrongs.append(LINE_WORDS[g])
	var hints := {"point": "A point is one exact place.", "line": "A line goes on for ever both ways: arrows at both ends.",
		"ray": "A ray starts at a point and goes on for ever one way.", "segment": "A segment has two end points.",
		"parallel": "Parallel lines never meet, like train tracks.", "perpendicular": "Perpendicular lines meet at a right angle.",
		"intersecting": "Intersecting lines cross each other."}
	var words: String = LINE_WORDS[what]
	var explain := ("These are %s. %s" % [words, hints[what]]) if words.ends_with("lines") else ("This is %s %s. %s" % [
		Lang.article(words), words, hints[what]])
	var ex := K.choice(rng, "What does the picture show?", words, wrongs, hints[what], explain, {"kind": "lines", "what": what})
	ex.data = {"what": what}
	return ex


static func angle_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var deg: int = [rng.randi_range(2, 8) * 10, 90, rng.randi_range(10, 17) * 10, 180][rng.randi_range(0, 3)]
	if level == 3:
		deg = rng.randi_range(3, 35) * 5
	var kind := ShapeFacts.angle_kind(deg)
	var picture := {} if level == 3 else {"kind": "angle", "deg": deg}
	var prompt := "Is an angle of %d° acute, right, obtuse or straight?" % deg if level == 3 else "What kind of angle is this?"
	var ex := K.choice(rng, prompt, kind, ["acute", "right", "obtuse", "straight"].filter(func(x: String) -> bool: return x != kind),
		"Acute is less than a right angle (90°), obtuse is between 90° and 180°, straight is 180°.",
		"%d° is %s." % [deg, kind] if level == 3 else "It is %s." % kind, picture)
	ex.data = {"deg": deg}
	return ex


static func shape_name(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var keys: Array = SHAPE_WRONGS.keys()
	if level == 1:
		keys = ["square", "rectangle", "triangle_right", "pentagon", "hexagon", "octagon"]
	var what: String = keys[rng.randi_range(0, keys.size() - 1)]
	var wrongs: Array = []
	for w: String in SHAPE_WRONGS[what]:
		wrongs.append(ShapeFacts.name_of(w))
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "What is this shape called?", ShapeFacts.name_of(what), wrongs.slice(0, 3),
		"Count its sides and look at its corners and which sides are parallel.",
		"It is %s %s: %d sides." % [Lang.article(ShapeFacts.name_of(what)), ShapeFacts.name_of(what), ShapeFacts.sides(what)],
		{"kind": "shape", "what": what, "marks": true})
	ex.data = {"what": what}
	return ex


## "Which shape has exactly one pair of parallel sides?" (the choices are pictures)
static func shape_property(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var questions: Array = [
		["Which shape has exactly one pair of parallel sides?", "trapezium", ["square", "parallelogram", "kite"]],
		["Which shape has no parallel sides?", "kite", ["rectangle", "parallelogram", "rhombus"]],
		["Which triangle has a right angle?", "triangle_right", ["triangle_equal", "triangle_obtuse", "triangle_acute"]],
		["Which triangle has an obtuse angle?", "triangle_obtuse", ["triangle_right", "triangle_equal", "triangle_acute"]],
		["Which shape has 6 sides?", "hexagon", ["pentagon", "octagon", "rectangle"]],
		["Which shape has 5 sides?", "pentagon", ["hexagon", "square", "triangle_equal"]],
		["Which shape has four right angles and sides that are not all equal?", "rectangle", ["square", "rhombus", "trapezium"]],
		["Which shape has 3 lines of symmetry?", "triangle_equal", ["square", "rectangle", "kite"]],
	]
	var q: Array = questions[rng.randi_range(0, 5 if level == 1 else questions.size() - 1)]
	var wrongs: Array = []
	for w: String in q[2]:
		wrongs.append({"picture": {"kind": "shape", "what": w, "marks": true}})
	var ex := K.choice(rng, q[0], {"picture": {"kind": "shape", "what": q[1], "marks": true}}, wrongs,
		"Look at each shape's sides and corners one by one.", "It is the %s." % ShapeFacts.name_of(q[1]))
	ex.data = {"what": q[1]}
	return ex


static func symmetry_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var shapes: Array = ["square", "rectangle", "kite", "triangle_equal", "hexagon"] if level == 1 else ["square", "rectangle",
		"rhombus", "kite", "parallelogram", "trapezium", "triangle_equal", "pentagon", "hexagon", "octagon"]
	var what: String = shapes[rng.randi_range(0, shapes.size() - 1)]
	var n := ShapeFacts.symmetry(what)
	var ex := K.number("How many lines of symmetry does this %s have?" % ShapeFacts.name_of(what), n,
		"A line of symmetry folds the shape so both halves match exactly.",
		"This %s has %d line%s of symmetry." % [ShapeFacts.name_of(what), n, Lang.plural_s(n)],
		{"kind": "shape", "what": what})
	ex.data = {"what": what}
	return ex


static func right_angle_count(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var shapes: Array = ["square", "rectangle", "triangle_right", "kite", "trapezium", "parallelogram", "hexagon",
		"triangle_equal", "rhombus"]
	var what: String = shapes[rng.randi_range(0, shapes.size() - 1)]
	var n := ShapeFacts.right_angles(what)
	var ex := K.number("How many right angles does this %s have?" % ShapeFacts.name_of(what), n,
		"A right angle is a square corner, like the corner of a page.",
		"This %s has %d right angle%s." % [ShapeFacts.name_of(what), n, Lang.plural_s(n)], {"kind": "shape", "what": what})
	ex.data = {"what": what}
	return ex


## "Finish the build so both halves match." (the game's Mirror mode on the block board)
static func mirror_build(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var count: int = [0, 3, 5, 7][level]
	var given: Array = []
	var tries := 0
	while given.size() < count and tries < 100:
		tries += 1
		var c := [rng.randi_range(0, 3), rng.randi_range(0, 3)]
		if not given.has(c):
			given.append(c)
	var ex := K.build("Finish the build so both halves match, like in a mirror.", {"cols": 8, "rows": 4,
		"block": BlockIds.BLUE, "given": given, "view": "wall"}, {"kind": "mirror", "sum": 7},
		"Each block on the left needs a twin the same distance from the red line on the right.",
		"Every block has its twin on the other side of the line.")
	ex.data = {"given": given}
	return ex


# --- Helpers -------------------------------------------------------------------------------------------------------

## A farm's sides and its picture: small with squares (level 1), bigger (2), or bigger than the picture's grid (3).
static func _farm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(2, 6) if level == 1 else rng.randi_range(4, 12)
	var h := rng.randi_range(2, 5) if level == 1 else rng.randi_range(3, 9)
	var pic := {"kind": "rect", "w": w, "h": h, "unit": "m", "grid": level == 1}
	if level == 3:
		w = rng.randi_range(11, 40)
		h = rng.randi_range(6, 25)
		pic = {"kind": "rect", "w": clampi(int(w / 4.0), 3, 10), "h": clampi(int(h / 4.0), 2, 7), "unit": "m", "grid": false,
			"label_w": "%d m" % w, "label_h": "%d m" % h}
	return {"w": w, "h": h, "picture": pic}


## A line plot of sticks' lengths in eighths (or quarters at level 1).
static func _plot(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den := 4 if level == 1 else 8
	var from := 1
	var to := den
	var counts := {}
	var values: Array = range(from, to + 1)
	K.shuffle(rng, values)
	for i in rng.randi_range(3, mini(5, values.size())):
		counts[str(values[i])] = rng.randi_range(1, 4)
	return {"kind": "line_plot", "den": den, "from": 0, "to": to, "counts": counts, "unit": "Length of the sticks (m)"}


## "3:05" from minutes after midnight (a 12-hour clock).
static func _clock(minutes: int) -> String:
	var m := posmod(minutes, 12 * 60)
	var h := int(m / 60.0)
	return "%d:%02d" % [12 if h == 0 else h, m % 60]


static func _one(unit: String) -> String:
	return unit.trim_suffix("s") if unit in ["hours", "minutes", "seconds", "days"] else unit
