class_name G3MeasureGen
extends RefCounted
## Owner #70 (grade 3 maths, units 13-18 of the outline: time on 12- and 24-hour clocks, length, mass and volume, area,
## perimeter, shapes, lines and right angles, bar graphs, pictograms and line plots; Common Core 3.MD, 3.G with England
## Year 4 and Singapore P3). Each is `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`
## (SchoolGen "g3g.<name>"), seeded, level 1-3, returning an exercise with a hint about the strategy, a worked answer and
## `data` (its inputs, for tests). Metric units and time (spec §22.6 ruling 4). Pictures of SchoolPictureG3
## (ui/school/school_picture_g3.gd). Helpers start with "_".
## Numbers and operations: G3MathsGen ("g3m"); fractions and money: G3FractionsGen ("g3f").

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]
## [bigger unit, smaller unit, how many small in one big]
const LENGTHS: Array = [["km", "m", 1000], ["m", "cm", 100], ["cm", "mm", 10]]
const MASS_VOLUME: Array = [["kg", "g", 1000], ["L", "mL", 1000]]
## What would be measured, and the unit (the wrong ones are clearly wrong).
const UNIT_CHOICES: Array = [
	["the mass of a dog", "kilograms (kg)", ["litres (L)", "kilometres (km)", "millimetres (mm)"]],
	["the mass of a strawberry", "grams (g)", ["kilograms (kg)", "litres (L)", "metres (m)"]],
	["how much water a bath holds", "litres (L)", ["grams (g)", "kilometres (km)", "millimetres (mm)"]],
	["how much medicine is in a spoon", "millilitres (mL)", ["kilograms (kg)", "kilometres (km)", "litres (L)"]],
	["the length of a football pitch", "metres (m)", ["grams (g)", "millilitres (mL)", "kilograms (kg)"]],
	["the length of an ant", "millimetres (mm)", ["kilometres (km)", "litres (L)", "kilograms (kg)"]],
	["the distance between two towns", "kilometres (km)", ["millimetres (mm)", "grams (g)", "litres (L)"]],
	["the width of a book", "centimetres (cm)", ["kilometres (km)", "litres (L)", "kilograms (kg)"]],
]
## About how much? [question, right, wrongs]
const ESTIMATES: Array = [
	["About how heavy is an apple?", "150 g", ["150 kg", "15 kg", "2 g"]],
	["About how heavy is a bag of flour?", "1 kg", ["1 g", "100 kg", "10 g"]],
	["About how much water fills a bath?", "150 L", ["150 mL", "2 L", "5 mL"]],
	["About how much does a cup hold?", "250 mL", ["250 L", "25 L", "2 mL"]],
	["About how tall is a door?", "2 m", ["2 cm", "20 m", "2 km"]],
	["About how long is a pencil?", "15 cm", ["15 m", "15 mm", "1 km"]],
	["About how far can you walk in an hour?", "4 km", ["4 m", "4 cm", "400 km"]],
	["About how heavy is a grown-up?", "70 kg", ["70 g", "7 kg", "700 kg"]],
	["About how much does a teaspoon hold?", "5 mL", ["5 L", "50 L", "500 mL"]],
	["About how long is a bee?", "15 mm", ["15 m", "15 km", "150 cm"]],
	["About how heavy is a paper clip?", "1 g", ["1 kg", "100 g", "10 kg"]],
	["About how much milk is in a big bottle?", "2 L", ["2 mL", "200 L", "20 mL"]],
]
## Graph topics: [what is counted, the categories].
const TOPICS: Array = [["votes for favourite buddies", ["Cats", "Dogs", "Owls", "Foxes", "Bats"]],
	["votes for favourite colours", ["Red", "Blue", "Green", "Gold", "Pink"]],
	["blocks built each day", ["Mon", "Tue", "Wed", "Thu", "Fri"]],
	["fruit picked on the farm", ["Apples", "Pears", "Plums", "Figs", "Limes"]]]
const ANGLE_WORDS: Array[String] = ["smaller than a right angle", "a right angle", "bigger than a right angle"]
const ANGLE_NAMES: Array[String] = ["an acute angle", "a right angle", "an obtuse angle"]


# --- Unit 13: time (3.MD.1; UK Y4 12- and 24-hour clocks; SG P3) ---------------------------------------------------------------

## "What time does the clock show?"
static func read_clock(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var h := rng.randi_range(1, 12)
	var m := rng.randi_range(0, 11) * 5 if level == 1 else rng.randi_range(0, 59)
	if level == 3:
		m = rng.randi_range(31, 58)
	var right := _clock(h, m)
	var wrongs: Array = []
	var swapped_h := roundi(m / 5.0) % 12
	if swapped_h == 0:
		swapped_h = 12
	wrongs.append(_clock(swapped_h, (h * 5) % 60))
	wrongs.append(_clock(h % 12 + 1, m))
	wrongs.append(_clock(h, (m + 5) % 60) if m < 55 else _clock(h, m - 5))
	if level > 1:
		wrongs.append(_clock(h, (m + 10) % 60) if m < 50 else _clock(h, m - 10))
	var ex := K.choice(rng, "What time does the clock show?", right, wrongs,
		"The short hand shows the hour it has just passed. The long hand shows the minutes: count in 5s, then in 1s.",
		"The short hand has passed %d and the long hand shows %d minutes: %s." % [h, m, right], {"kind": "clock", "h": h, "m": m})
	ex.data = {"h": h, "m": m}
	return ex


## 12-hour and 24-hour clocks: "3:45 in the afternoon is which 24-hour time?" or the digital clock "18:20 is …?"
static func to_24h(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var h := rng.randi_range(13, 21) if rng.randf() < 0.7 else rng.randi_range(7, 11)
	var m := rng.randi_range(0, 11) * 5 if level == 1 else rng.randi_range(0, 59)
	var twelve := (h + 11) % 12 + 1
	var to_24 := level == 1 or rng.randf() < 0.5
	var ex: Dictionary
	if to_24:
		var right := "%02d:%02d" % [h, m]
		var wrongs: Array = ["%02d:%02d" % [(h + 12) % 24, m], "%02d:%02d" % [(h + 1) % 24, m], "%02d:%02d" % [twelve + 10, m]]
		ex = K.choice(rng, "The show starts at %s %s. How is that written on a 24-hour clock?" % [_clock(twelve, m), _part_of_day(h)],
			right, wrongs, "After 12 noon, add 12 to the hour. Before noon the hour stays, with a 0 in front.",
			"%s %s is %s." % [_clock(twelve, m), _part_of_day(h), right])
	else:
		var right2 := "%s %s" % [_clock(twelve, m), _part_of_day(h)]
		var wrong_part := "in the morning" if h >= 12 else "in the afternoon"
		var wrongs2: Array = ["%s %s" % [_clock(twelve, m), wrong_part], "%s %s" % [_clock(maxi(1, h - 10) if h > 12 else twelve % 12 + 1, m),
			_part_of_day(h)], "%s %s" % [_clock(twelve % 12 + 1, m), _part_of_day(h)]]
		ex = K.choice(rng, "What time does the 24-hour clock show?", right2, wrongs2,
			"Hours after 12 are in the afternoon or evening: take away 12 to find the 12-hour time.",
			"%02d:%02d is %s." % [h, m, right2], {"kind": "digital_clock", "h": h, "m": m})
	ex.data = {"h": h, "m": m, "to_24": to_24}
	return ex


## "A film starts at 2:15 and ends at 3:05. How many minutes long is it?"
static func duration(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := rng.randi_range(8 * 12, 16 * 12) * 5   # 8:00 to 16:00, in minutes after midnight
	var minutes := 0
	if level == 1:
		start = start - start % 60 + rng.randi_range(0, 6) * 5
		minutes = rng.randi_range(2, 11 - int((start % 60) / 5.0)) * 5
	elif level == 2:
		minutes = rng.randi_range(4, 12) * 5
		if start % 60 + minutes < 60:
			start += 60 - start % 60 - 5   # it goes past the hour
	else:
		start += rng.randi_range(0, 4)
		minutes = rng.randi_range(65, 150)
	var end := start + minutes
	var h24 := level == 3
	var what: String = ["film", "swim", "boat ride", "cake in the oven"][rng.randi_range(0, 3)]
	var ex := K.number("A %s starts at %s and ends at %s. How many minutes does it take?" % [what, _time(start, h24), _time(end, h24)],
		minutes, _count_on_hint(start, end, h24), _duration_steps(start, end, h24), {"kind": "clock", "h": _hour12(start), "m": start % 60} if level < 3 else {})
	ex.data = {"start": start, "end": end}
	return ex


## "Zara starts building at 4:40 and builds for 35 minutes. At what time does Zara stop?"
static func end_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var start := rng.randi_range(8 * 12, 16 * 12) * 5
	var minutes := rng.randi_range(2, 8) * 5
	if level == 1:
		start = start - start % 60 + rng.randi_range(0, 4) * 5
		minutes = rng.randi_range(2, 11 - int((start % 60) / 5.0)) * 5
	elif level == 2:
		minutes = rng.randi_range(4, 11) * 5
	else:
		start += rng.randi_range(0, 4)
		minutes = rng.randi_range(50, 130)
	var end := start + minutes
	var h24 := level == 3
	var right := _time(end, h24)
	var wrongs: Array = [_time(end + 10, h24), _time(end - 10, h24), _time(end + 60, h24)]
	var ex := K.choice(rng, "%s starts building at %s and builds for %d minutes. At what time does %s stop?" % [who,
		_time(start, h24), minutes, who], right, wrongs,
		"Count on from %s: first the minutes to the next o'clock, %s, then the minutes that are left." % [_time(start, h24),
			_time(start - start % 60 + 60, h24)] if start % 60 != 0 and end > start - start % 60 + 60 else
			"Count on %d minutes from %s." % [minutes, _time(start, h24)],
		_end_steps(start, minutes, h24), {"kind": "clock", "h": _hour12(start), "m": start % 60})
	ex.data = {"start": start, "minutes": minutes, "h24": h24}
	return ex


## "3 hours = ? minutes", "2 weeks = ? days", "1 hour 25 minutes = ? minutes"
static func time_units(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pairs: Array = [["hours", "minutes", 60], ["minutes", "seconds", 60]]
	if level == 2:
		pairs = [["weeks", "days", 7], ["years", "months", 12], ["days", "hours", 24]]
	elif level == 3:
		pairs = [["hours", "minutes", 60], ["minutes", "seconds", 60], ["weeks", "days", 7], ["years", "months", 12]]
	var p: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
	var a := rng.randi_range(2, 5 if level < 3 else 3)
	var extra := rng.randi_range(1, int(p[2]) - 1) if level == 3 else 0
	var prompt := "%d %s = ? %s" % [a, p[0], p[1]]
	if extra > 0:
		prompt = "%d %s %d %s = ? %s" % [a, p[0], extra, p[1], p[1]]
	var answer := a * int(p[2]) + extra
	var ex := K.number(prompt, answer, "1 %s = %d %s." % [str(p[0]).trim_suffix("s"), int(p[2]), p[1]],
		("%d × %d = %d %s" % [a, int(p[2]), answer, p[1]]) if extra == 0 else
			("%d × %d = %d, and %d + %d = %d %s." % [a, int(p[2]), a * int(p[2]), a * int(p[2]), extra, answer, p[1]]))
	ex.data = {"a": a, "factor": int(p[2]), "extra": extra}
	return ex


# --- Unit 14: length, mass and volume (3.MD.2; UK Y4 measurement; SG P3) ---------------------------------------------------

## "3 m = ? cm", "3 m 45 cm = ? cm", "700 cm = ? m"
static func convert_length(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _convert(rng, level, LENGTHS)


## "4 kg = ? g", "2 L 250 mL = ? mL", "3,000 g = ? kg"
static func convert_mass_volume(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _convert(rng, level, MASS_VOLUME)


## A kitchen scale's dial: "How many grams does the scale show?"
static func read_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var top := 10
	var step := 1
	var minor := 0
	var unit := "kg"
	var value := rng.randi_range(1, 9)
	if level == 2:
		unit = "g"
		top = 1000
		step = 100
		minor = 1
		value = rng.randi_range(1, 19) * 50
	elif level == 3:
		unit = "g"
		if rng.randf() < 0.5:
			top = 500
			step = 50
			minor = 4
			value = rng.randi_range(1, 49) * 10
		else:
			top = 2000
			step = 200
			minor = 1
			value = rng.randi_range(1, 19) * 100
	var small := step / float(minor + 1)
	var ex := K.number("How many %s does the scale show?" % ("kilograms" if unit == "kg" else "grams"), value,
		"The numbers go up %s %s at a time. %s" % [K.fmt(step), unit, "Each small mark between them is %s %s." % [_num(small),
			unit] if minor > 0 else "Read the number the needle points to."],
		"The needle points to %s %s." % [K.fmt(value), unit],
		{"kind": "dial_scale", "top": top, "step": step, "value": value, "unit": unit, "minor": minor,
			"block": [BlockIds.LANTERN, BlockIds.BRICK, BlockIds.PLANKS, BlockIds.GOLD][rng.randi_range(0, 3)]})
	ex.data = {"value": value, "unit": unit}
	return ex


## A measuring jug: "How much water is in the jug?"
static func read_jug(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var unit := "L"
	var top := rng.randi_range(5, 10)
	var step := 1
	var minor := 0
	var fill := rng.randi_range(1, top)
	if level == 2:
		unit = "mL"
		top = 1000
		step = [100, 200][rng.randi_range(0, 1)]
		fill = rng.randi_range(1, int(top / float(step))) * step
	elif level == 3:
		unit = "mL"
		minor = 1
		if rng.randf() < 0.5:
			top = 1000
			step = 200
			fill = rng.randi_range(1, 9) * 100
		else:
			top = 500
			step = 100
			fill = rng.randi_range(1, 9) * 50
	var ex := K.number("How much water is in the jug, in %s?" % ("litres" if unit == "L" else "millilitres"), fill,
		"The marks go up %s %s at a time.%s Read the mark at the top of the water." % [K.fmt(step), unit,
			" A small mark is halfway between two numbers." if minor > 0 else ""],
		"The water comes up to %s %s." % [K.fmt(fill), unit],
		{"kind": "jug", "top": top, "fill": fill, "step": step, "unit": unit, "minor": minor})
	ex.data = {"fill": fill, "unit": unit}
	return ex


## A ruler: "How long is the stick?" (level 2: it does not start at 0; level 3 in millimetres)
static func read_ruler(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var from := 0
	var mm := 0   # the length in millimetres
	var ruler := {"kind": "ruler", "to": 12}
	if level == 1:
		mm = rng.randi_range(2, 11) * 10
	elif level == 2:
		from = rng.randi_range(1, 4)
		mm = rng.randi_range(2, 12 - from) * 10
	else:
		mm = rng.randi_range(15, 115)
		if mm % 10 == 0:
			mm += 3
		ruler.mm = true
	ruler.length = str(mm / 10.0) if mm % 10 != 0 else str(int(mm / 10.0))
	ruler.from = str(from)
	var in_mm := level == 3
	var ex := K.number("How long is the stick, in %s?" % ("millimetres" if in_mm else "centimetres"),
		mm if in_mm else int(mm / 10.0),
		"Start counting where the stick starts, not at the end of the ruler." if level == 2 else
			("Each centimetre has 10 small millimetre marks. Count the whole centimetres, then the small marks." if in_mm else
				"The stick starts at 0. Read the number at its other end."),
		("It goes from %d cm to %d cm: %d − %d = %d cm." % [from, from + int(mm / 10.0), from + int(mm / 10.0), from, int(mm / 10.0)])
			if level == 2 else ("%d cm and %d mm = %d mm." % [int(mm / 10.0), mm % 10, mm] if in_mm else
				"The stick ends at %d, so it is %d cm long." % [int(mm / 10.0), int(mm / 10.0)]), ruler)
	ex.data = {"from": from, "mm": mm, "in_mm": in_mm}
	return ex


## "Which unit would you use to measure the mass of a dog?" (levels 2-3: "About how heavy is an apple?")
static func which_unit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var i := 0
	if level == 1:
		i = rng.randi_range(0, UNIT_CHOICES.size() - 1)
		var u: Array = UNIT_CHOICES[i]
		ex = K.choice(rng, "Which unit would you use to measure %s?" % u[0], u[1], u[2],
			"Is it a length, a mass (how heavy) or how much it holds? Is it big or small?",
			"%s: %s." % [_first_upper(str(u[0])), u[1]])
	else:
		i = rng.randi_range(0, ESTIMATES.size() - 1)
		var e: Array = ESTIMATES[i]
		ex = K.choice(rng, e[0], e[1], e[2], "Think of things you know: a paper clip is about 1 g, a bag of flour 1 kg, a door 2 m tall.",
			"%s About %s." % [e[0], e[1]])
	ex.data = {"i": i, "estimate": level > 1}
	return ex


## One-step measuring stories in the same units (add, take away, multiply, share).
static func measure_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var kind := rng.randi_range(0, 4)
	var a := 0
	var b := 0
	var prompt := ""
	var answer := 0
	var how := ""
	match kind:
		0:
			a = rng.randi_range(12, 95) * [1, 10, 10][level - 1]
			b = rng.randi_range(12, 95) * [1, 10, 10][level - 1]
			prompt = "A melon has a mass of %s g and a pear %s g. What is their mass together, in grams?" % [K.fmt(a), K.fmt(b)]
			answer = a + b
			how = "%s + %s = %s g" % [K.fmt(a), K.fmt(b), K.fmt(answer)]
		1:
			a = [1000, 2000, 1000][level - 1]
			b = rng.randi_range(1, 9) * [100, 50, 25][level - 1]
			prompt = "A jug holds %s mL of juice. %s pours out %s mL. How many millilitres are left?" % [K.fmt(a), who, K.fmt(b)]
			answer = a - b
			how = "%s − %s = %s mL" % [K.fmt(a), K.fmt(b), K.fmt(answer)]
		2:
			a = rng.randi_range(2, [5, 9, 12][level - 1])
			b = rng.randi_range(2, [5, 9, 9][level - 1])
			prompt = "A bucket holds %d L of water. How many litres do %d buckets hold?" % [a, b]
			answer = a * b
			how = "%d × %d = %d L" % [b, a, answer]
		3:
			b = rng.randi_range(2, [5, 8, 9][level - 1])
			answer = rng.randi_range(2, [5, 9, 12][level - 1])
			a = b * answer
			prompt = "%s shares %d kg of flour equally into %d bags. How many kilograms go in each bag?" % [who, a, b]
			how = "%d ÷ %d = %d kg" % [a, b, answer]
		_:
			a = rng.randi_range(40, [99, 300, 900][level - 1])
			b = rng.randi_range(10, a - 10)
			prompt = "A rope is %s m long. %s cuts off %s m. How long is the rope now, in metres?" % [K.fmt(a), who, K.fmt(b)]
			answer = a - b
			how = "%s − %s = %s m" % [K.fmt(a), K.fmt(b), K.fmt(answer)]
	var ex := K.number(prompt, answer, "The units are the same, so work with the numbers: add, take away, multiply or share?",
		how + ".")
	ex.data = {"kind": kind, "a": a, "b": b}
	return ex


# --- Unit 15: area (3.MD.5, 3.MD.6, 3.MD.7; SG P3) ----------------------------------------------------------------------------

## "Each square is 1 square unit. What is the area of the shape?"
static func count_squares(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows := _shape_rows(rng, level)
	var area := _area(rows)
	var ex := K.number("Each square is 1 square unit. What is the area of the shape, in square units?", area,
		"Count the squares row by row. For a rectangle, you can multiply the rows by the squares in a row.",
		"The shape covers %d squares: its area is %d square units." % [area, area],
		{"kind": "unit_squares", "rows": rows})
	ex.data = {"rows": rows}
	return ex


## "What is the area of the rectangle, in square metres?" (the rect picture)
static func rect_area(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(2, [6, 10, 12][level - 1])
	var h := rng.randi_range(2, [5, 8, 9][level - 1])
	var unit := "m" if rng.randf() < 0.5 else "cm"
	var ex := K.number("What is the area of the rectangle, in square %s?" % ("metres" if unit == "m" else "centimetres"), w * h,
		"Area = the rows of squares × the squares in each row: length × width.",
		"%d × %d = %d square %s." % [w, h, w * h, "metres" if unit == "m" else "centimetres"],
		{"kind": "rect", "w": w, "h": h, "unit": unit, "grid": level == 1})
	ex.data = {"w": w, "h": h}
	return ex


## "Build a farm with an area of 12 squares." (the block board; level 3 with no side shorter than 3)
static func area_build(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var areas: Array = [[6, 8, 10, 12], [12, 15, 16, 18, 20], [12, 15, 18, 20, 24]][level - 1]
	var area: int = areas[rng.randi_range(0, areas.size() - 1)]
	var min_side := 3 if level == 3 else 2
	var ex := K.build("Build a rectangle farm with an area of %d squares, with no side shorter than %d." % [area, min_side],
		{"cols": 10, "rows": 7, "block": BlockIds.GRASS, "given": [], "view": "farm"},
		{"kind": "rectangle", "area": area, "min_side": min_side},
		"Which two numbers multiply to make %d? Make that many rows with that many squares in each." % area,
		"For example %s: %s." % [_factor_pair(area, min_side), "the area is %d squares" % area])
	ex.data = {"area": area, "min_side": min_side}
	return ex


## An L-shape split into two rectangles: "What is the area of the L-shape?" (level 3: each square is 2 m by 2 m)
static func l_area(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(4, 7 if level < 3 else 6)
	var h := rng.randi_range(4, 6 if level < 3 else 5)
	var cw := rng.randi_range(2, w - 2)   # a notch 2 or more squares each way, so its sides' words have room
	var ch := rng.randi_range(2, h - 2)
	var rows: Array[String] = []
	for y in h:
		rows.append(("a".repeat(w - cw) + ".".repeat(cw)) if y < ch else "b".repeat(w))
	var per := 2 if level == 3 else 1
	var unit := "m"
	var top_area := (w - cw) * ch * per * per
	var bottom_area := w * (h - ch) * per * per
	var ex := K.number("What is the area of the L-shape, in square metres?", top_area + bottom_area,
		"Split the shape into two rectangles. Find the area of each, then add.",
		"Top: %d × %d = %d. Bottom: %d × %d = %d. Together: %d + %d = %d square metres." % [(w - cw) * per, ch * per, top_area,
			w * per, (h - ch) * per, bottom_area, top_area, bottom_area, top_area + bottom_area],
		{"kind": "unit_squares", "rows": rows, "grid": level == 1, "labels": true, "per": per, "unit": unit})
	ex.data = {"rows": rows, "per": per}
	return ex


## "The area is 24 square metres. What is the missing side?"
static func missing_side_area(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(2, [6, 9, 12][level - 1])
	var h := rng.randi_range(2, [5, 8, 9][level - 1])
	var unit := "m" if level < 3 or rng.randf() < 0.5 else "cm"
	var name := "metres" if unit == "m" else "centimetres"
	var ex := K.number("The area of the rectangle is %d square %s. How long is the side marked ?, in %s?" % [w * h, name, name], w,
		"Area = length × width. Which number times %d makes %d?" % [h, w * h],
		"%d × %d = %d, so the missing side is %d %s." % [w, h, w * h, w, unit],
		{"kind": "rect", "w": w, "h": h, "unit": unit, "grid": false, "unknown": "w"})
	ex.data = {"w": w, "h": h}
	return ex


# --- Unit 16: perimeter (3.MD.8; UK Y4; SG P3) ---------------------------------------------------------------------------------

## "What is the perimeter of the rectangle?" (level 3: a square, in words)
static func rect_perimeter(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(2, [6, 10, 12][level - 1])
	var h := rng.randi_range(2, [5, 8, 9][level - 1])
	var unit := "m" if rng.randf() < 0.5 else "cm"
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.5:
		h = w
		ex = K.number("A square has sides of %d %s. What is its perimeter, in %s?" % [w, unit, _unit_name(unit)], 4 * w,
			"A square has 4 equal sides. Add them, or multiply by 4.", "4 × %d = %d %s." % [w, 4 * w, unit])
	else:
		ex = K.number("What is the perimeter of the rectangle, in %s?" % _unit_name(unit), 2 * (w + h),
			"The perimeter is the distance all the way round: add all four sides.",
			"%d + %d + %d + %d = %d %s." % [w, h, w, h, 2 * (w + h), unit],
			{"kind": "rect", "w": w, "h": h, "unit": unit, "grid": level == 1})
	ex.data = {"w": w, "h": h}
	return ex


## A shape with its sides' lengths: "What is the perimeter?"
static func polygon_perimeter(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var shapes: Array = [["triangle_equal", "triangle_acute", "triangle_right", "square", "rectangle"],
		["rhombus", "kite", "parallelogram", "trapezium", "pentagon", "triangle_acute"],
		["hexagon", "octagon", "pentagon", "trapezium", "kite"]][level - 1]
	var what: String = shapes[rng.randi_range(0, shapes.size() - 1)]
	var unit := "cm" if rng.randf() < 0.6 else "m"
	var sides := _side_lengths(rng, what)
	var total := 0
	var labels: Array = []
	for s in sides:
		total += s
		labels.append("%d %s" % [s, unit])
	var texts: Array[String] = []
	for s in sides:
		texts.append(str(s))
	var ex := K.number("What is the perimeter of the %s, in %s?" % [ShapeFacts.name_of(what), _unit_name(unit)], total,
		"Add every side, all the way round. Tick each side as you add it.",
		"%s = %d %s." % [" + ".join(texts), total, unit], {"kind": "side_lengths", "what": what, "labels": labels})
	ex.data = {"what": what, "sides": sides}
	return ex


## "The perimeter is 24 cm. What is the missing side?" (level 3: an L-shape)
static func missing_side(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var unit := "cm" if rng.randf() < 0.6 else "m"
	var sides: Array[int] = []
	var pic := {}
	var hide := 0
	if level < 3:
		var shapes: Array = [["triangle_acute", "triangle_right", "triangle_equal"], ["rectangle", "kite", "trapezium", "pentagon"]][level - 1]
		var what: String = shapes[rng.randi_range(0, shapes.size() - 1)]
		sides = _side_lengths(rng, what)
		hide = rng.randi_range(0, sides.size() - 1)
		pic = {"kind": "side_lengths", "what": what, "labels": _labels(sides, hide, unit)}
	else:
		var w := rng.randi_range(5, 12)
		var hh := rng.randi_range(4, 10)
		var x := rng.randi_range(2, w - 2)
		var h1 := rng.randi_range(2, hh - 2)
		sides = [w, h1, w - x, hh - h1, x, hh]
		hide = rng.randi_range(0, 5)
		pic = {"kind": "side_lengths", "points": [[0, 0], [w, 0], [w, h1], [x, h1], [x, hh], [0, hh]],
			"labels": _labels(sides, hide, unit)}
	var total := 0
	for s in sides:
		total += s
	var known := total - sides[hide]
	var ex := K.number("The perimeter of the shape is %d %s. How long is the side marked ?, in %s?" % [total, unit, _unit_name(unit)],
		sides[hide], "Add the sides you know. Then take that away from the perimeter.",
		"The other sides add up to %d. %d − %d = %d %s." % [known, total, known, sides[hide], unit], pic)
	ex.data = {"sides": sides, "hide": hide}
	return ex


## The perimeter of a shape of squares: count the edges (level 3: the sides' lengths, each square 2 cm)
static func grid_perimeter(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows := _shape_rows(rng, level, level == 3)
	var per := 2 if level == 3 and rng.randf() < 0.5 else 1
	var p := _perimeter(rows) * per
	var pic := {"kind": "unit_squares", "rows": rows}
	var prompt := "Each square is 1 cm long. What is the perimeter of the shape, in centimetres?"
	if level == 3:
		pic = {"kind": "unit_squares", "rows": rows, "grid": false, "labels": true, "per": per, "unit": "cm"}
		prompt = "What is the perimeter of the shape, in centimetres?"
	var ex := K.number(prompt, p, "Go all the way round the outside and add up every side. Do not count the inside lines.",
		"All the way round the outside is %d cm." % p, pic)
	ex.data = {"rows": rows, "per": per}
	return ex


## The same perimeter, a different area: which rectangle has the same perimeter (level 1), is the area the same too
## (level 2), build one with both (level 3).
static func same_perimeter(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var w := rng.randi_range(2, 6)
	var h := rng.randi_range(w + 2, 9)
	var p := 2 * (w + h)
	var w2 := w + 1
	var h2 := h - 1
	if level == 1:
		var wrongs: Array = ["%d m by %d m" % [w2, h], "%d m by %d m" % [w, h + 2], "%d m by %d m" % [w + 1, h + 1]]
		ex = K.choice(rng, "Which rectangle has the same perimeter as a %d m by %d m rectangle?" % [w, h], "%d m by %d m" % [w2, h2],
			wrongs, "Work out each perimeter: add the two sides, then double.",
			"%d + %d = %d, doubled is %d m. %d + %d = %d too, so %d m by %d m has the same perimeter." % [w, h, w + h, p, w2, h2,
				w2 + h2, w2, h2])
	elif level == 2:
		if rng.randf() < 0.35:
			w2 = h
			h2 = w
		ex = K.truefalse("A %d m by %d m farm and a %d m by %d m farm have the same perimeter. Do they have the same area too?" %
			[w, h, w2, h2], w * h == w2 * h2, "Work out both areas: length × width.",
			("Both perimeters are %d m, but the areas are %d × %d = %d and %d × %d = %d square metres." % [p, w, h, w * h, w2, h2,
				w2 * h2]) if w * h != w2 * h2 else ("Yes: it is the same farm turned round. Both areas are %d × %d = %d square metres." %
				[w, h, w * h]))
	else:
		var bw := rng.randi_range(2, 6)
		var bh := rng.randi_range(2, 5)
		ex = K.build("Build a rectangle farm with an area of %d squares and a fence of %d all the way round." % [bw * bh, 2 * (bw + bh)],
			{"cols": 10, "rows": 7, "block": BlockIds.GRASS, "given": [], "view": "farm"},
			{"kind": "rectangle", "area": bw * bh, "perimeter": 2 * (bw + bh)},
			"Which rectangles have an area of %d? Work out the fence of each one." % (bw * bh),
			"%d by %d: the area is %d and the fence is %d + %d + %d + %d = %d." % [bw, bh, bw * bh, bw, bh, bw, bh, 2 * (bw + bh)])
		w = bw
		h = bh
		w2 = 0
		h2 = 0
	ex.data = {"w": w, "h": h, "w2": w2, "h2": h2}
	return ex


# --- Unit 17: shapes, lines and right angles (3.G.1, 3.G.2; SG P3; UK Y3-4 geometry) -------------------------------------------

## "What is this shape called?"
static func name_shape(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pic := {}
	var right := ""
	var wrongs: Array = []
	if level == 1:
		var what: String = ["square", "rectangle", "triangle_acute", "triangle_right", "pentagon", "hexagon", "octagon"][rng.randi_range(0, 6)]
		right = "triangle" if what.begins_with("triangle") else ShapeFacts.name_of(what)
		for n: String in ["square", "rectangle", "triangle", "pentagon", "hexagon", "octagon"]:
			if n != right and not (right == "square" and n == "rectangle"):
				wrongs.append(n)
		K.shuffle(rng, wrongs)
		wrongs = wrongs.slice(0, 3)
		pic = {"kind": "shape", "what": what, "marks": true}
	elif level == 2:
		# never a name some books give it too: a square is also a rectangle, a rhombus, a kite and (to some) a trapezium
		var names := {"square": ["triangle", "pentagon", "hexagon", "octagon"], "rectangle": ["square", "rhombus", "kite", "pentagon"],
			"rhombus": ["square", "rectangle", "pentagon", "hexagon"], "parallelogram": ["rectangle", "square", "kite", "pentagon"],
			"trapezium": ["parallelogram", "rectangle", "square", "rhombus"], "kite": ["square", "rectangle", "parallelogram", "trapezium"]}
		var what: String = names.keys()[rng.randi_range(0, names.size() - 1)]
		right = ShapeFacts.name_of(what)
		wrongs = (names[what] as Array).duplicate()
		pic = {"kind": "shape", "what": what, "marks": true}
	else:
		var kinds: Array = [["equilateral triangle", "triangle_equal", ["right-angled triangle", "scalene triangle"]],
			["isosceles triangle", "triangle_acute", ["equilateral triangle", "right-angled triangle", "scalene triangle"]],
			["scalene triangle", "triangle_obtuse", ["equilateral triangle", "isosceles triangle", "right-angled triangle"]],
			["right-angled triangle", "triangle_right", ["equilateral triangle", "isosceles triangle"]]]
		var k: Array = kinds[rng.randi_range(0, kinds.size() - 1)]
		right = k[0]
		wrongs = (k[2] as Array).duplicate()
		var s := rng.randi_range(3, 9)
		match str(k[1]):
			"triangle_equal":
				pic = {"kind": "side_lengths", "what": "triangle_equal", "labels": ["%d cm" % s, "%d cm" % s, "%d cm" % s]}
			"triangle_acute":
				pic = {"kind": "side_lengths", "what": "triangle_acute", "labels": ["%d cm" % (s + 1), "%d cm" % s, "%d cm" % (s + 1)]}
			"triangle_obtuse":
				pic = {"kind": "side_lengths", "what": "triangle_obtuse", "labels": ["%d cm" % (s + 3), "%d cm" % (s + 5), "%d cm" % s]}
			_:
				pic = {"kind": "shape", "what": "triangle_right", "marks": true}
	var ex := K.choice(rng, "What is this shape called?", right, wrongs,
		"Count the sides and the corners. Look for right angles and for sides of the same length.", _shape_reason(right), pic)
	ex.data = {"name": right}
	return ex


## "This shape has 4 right angles. True or false?" (sides, right angles, pairs of parallel sides; level 3 also families)
static func shape_true(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3 and rng.randf() < 0.4:
		var facts: Array = [["Every square is a rectangle.", true, "A square has 4 right angles, so it is a rectangle too."],
			["Every rectangle is a square.", false, "A rectangle's sides do not have to be all the same length."],
			["Every square is a rhombus.", true, "A square has 4 equal sides, so it is a rhombus too."],
			["Every rhombus is a square.", false, "A rhombus does not have to have right angles."],
			["A triangle can have two right angles.", false, "Two right angles would make two sides parallel: they would never meet."],
			["A triangle can have one right angle.", true, "A right-angled triangle has one."],
			["A rectangle has 4 right angles.", true, "Every corner of a rectangle is a right angle."],
			["A kite has 2 pairs of parallel sides.", false, "A kite has no parallel sides."]]
		var f: Array = facts[rng.randi_range(0, facts.size() - 1)]
		var fx := K.truefalse(f[0], f[1], "Think of the shape's sides and corners. Can you picture one that is different?", f[2])
		fx.data = {"what": "", "fact": "family", "n": 0, "truth": f[1]}
		return fx
	var pool: Array = ["square", "rectangle", "triangle_right", "triangle_equal", "pentagon", "hexagon"]
	if level > 1:
		pool.append_array(["rhombus", "parallelogram", "trapezium", "kite", "octagon"])
	var what: String = pool[rng.randi_range(0, pool.size() - 1)]
	var fact: String = ["sides", "right angles", "pairs of parallel sides"][rng.randi_range(0, level - 1)]
	var truth := ShapeFacts.sides(what)
	if fact == "right angles":
		truth = ShapeFacts.right_angles(what)
	elif fact == "pairs of parallel sides":
		truth = ShapeFacts.parallel_pairs(what)
	var n := truth if rng.randf() < 0.5 else maxi(0, truth + [-1, 1, 2][rng.randi_range(0, 2)])
	if n == truth and rng.randf() < 0.3:
		n = truth + 1
	var words: String = fact if n != 1 else {"sides": "side", "right angles": "right angle",
		"pairs of parallel sides": "pair of parallel sides"}[fact]
	var ex := K.truefalse("This shape has %d %s. True or false?" % [n, words], n == truth,
		"Count carefully and touch each one as you count. A right angle is a square corner.",
		"It has %s %s." % ["no" if truth == 0 else str(truth), fact if truth != 1 else {"sides": "side",
			"right angles": "right angle", "pairs of parallel sides": "pair of parallel sides"}[fact]], {"kind": "shape", "what": what})
	ex.data = {"what": what, "fact": fact, "n": n, "truth": n == truth}
	return ex


## "How many right angles does this shape have?"
static func right_angles(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = ["square", "rectangle", "triangle_right", "triangle_equal"]
	if level > 1:
		pool.append_array(["rhombus", "parallelogram", "trapezium", "kite", "pentagon", "hexagon", "triangle_acute"])
	var what: String = pool[rng.randi_range(0, pool.size() - 1)]
	var n := ShapeFacts.right_angles(what)
	var ex := K.number("How many right angles does this shape have inside it?", n,
		"A right angle is a square corner, like the corner of a book. Check every corner.",
		"The %s has %s right angle%s." % [ShapeFacts.name_of(what), "no" if n == 0 else str(n), "" if n == 1 else "s"],
		{"kind": "shape", "what": what})
	ex.data = {"what": what}
	return ex


## "This angle is … a right angle." (level 3: acute, right or obtuse)
static func angle_size(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var degs: Array = [[30, 45, 60, 90, 120, 135, 150], [20, 30, 40, 50, 60, 70, 90, 110, 120, 130, 140, 160],
		[20, 35, 50, 65, 90, 115, 130, 145, 160]][level - 1]
	var deg: int = degs[rng.randi_range(0, degs.size() - 1)]
	var k := 0 if deg < 90 else (1 if deg == 90 else 2)
	var words: Array = ANGLE_NAMES if level == 3 else ANGLE_WORDS
	var ex := K.choice(rng, "Which is true? This angle is …" if level < 3 else "What kind of angle is this?", words[k],
		words, "Hold a square corner, like the corner of a book, against it. Is the angle smaller, the same or bigger?",
		"It is %s." % words[k] + (" An acute angle is smaller than a right angle; an obtuse one is bigger." if level == 3 else ""),
		{"kind": "angle", "deg": deg})
	ex.data = {"deg": deg}
	return ex


## "What kind of lines are these?" (parallel, perpendicular, intersecting)
static func lines_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kinds: Array = ["parallel", "perpendicular"] if level == 1 else ["parallel", "perpendicular", "intersecting"]
	var what: String = kinds[rng.randi_range(0, kinds.size() - 1)]
	var right := "%s lines" % what
	var wrongs: Array = []
	for w: String in ["parallel", "perpendicular", "intersecting"]:
		if w != what and not (what == "perpendicular" and w == "intersecting") and (level > 1 or w != "intersecting"):
			wrongs.append("%s lines" % w)
	var ex := K.choice(rng, "What kind of lines are these?", right, wrongs,
		"Parallel lines never meet. Perpendicular lines meet at a right angle. Intersecting lines cross.",
		{"parallel": "They never meet, however far they go: parallel lines.",
			"perpendicular": "They meet at a right angle: perpendicular lines.",
			"intersecting": "They cross, but not at a right angle: intersecting lines."}[what], {"kind": "lines", "what": what})
	ex.data = {"what": what}
	return ex


## "The shape is cut into equal parts. What fraction is one part?" (level 3: hexagons, triangles, diagonals)
static func cut_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pic := {}
	var parts := 0
	if level == 1:
		parts = rng.randi_range(2, 4)
		pic = {"kind": "cut_shape", "shape": ["circle", "rectangle", "square"][rng.randi_range(0, 2)], "parts": parts, "shade": 1}
	elif level == 2:
		parts = [6, 8, 4, 9][rng.randi_range(0, 3)]
		pic = {"kind": "cut_shape", "shape": ["rectangle", "square"][rng.randi_range(0, 1)], "parts": parts, "way": "grid", "shade": 1}
	else:
		var cuts: Array = [["hexagon", 6], ["hexagon", 3], ["hexagon", 2], ["triangle", 3], ["triangle", 4], ["triangle", 2]]
		var c: Array = cuts[rng.randi_range(0, cuts.size() - 1)]
		parts = c[1]
		pic = {"kind": "cut_shape", "shape": c[0], "parts": parts, "shade": 1}
		if rng.randf() < 0.3:
			parts = [2, 4][rng.randi_range(0, 1)]
			pic = {"kind": "cut_shape", "shape": "square", "way": "diagonals", "parts": parts, "shade": 1}
	var ex := K.number("The shape is cut into equal parts. What fraction of the whole shape is the shaded part?", "1/%d" % parts,
		"Count the equal parts. One part of them is 1 over that number.",
		"There are %d equal parts, so each one is 1/%d of the shape." % [parts, parts], pic)
	ex.data = {"parts": parts}
	return ex


# --- Unit 18: bar graphs, pictograms and line plots (3.MD.3, 3.MD.4; SG P3; UK Y3-4 statistics) ------------------------------

## A pictogram: "How many voted for Owls?" (level 3 with half symbols)
static func pictogram_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := _pictogram(rng, level)
	var rows: Array = g.picture.rows
	var i := rng.randi_range(0, rows.size() - 1)
	var value := int(rows[i][1])
	var each := int(g.picture.each)
	var ex := K.number("The pictogram shows %s. How many for %s?" % [g.topic, rows[i][0]], value,
		"Look at the key: each symbol stands for %d.%s Count the symbols and multiply." % [each,
			" Half a symbol is %d." % int(each / 2.0) if level == 3 else ""],
		_symbols_said(str(rows[i][0]), value, each), g.picture)
	ex.data = {"rows": rows, "each": each, "i": i}
	return ex


## A pictogram: "How many more for Cats than Owls?" (level 3: how many altogether)
static func pictogram_compare(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := _pictogram(rng, level)
	var rows: Array = g.picture.rows
	var each := int(g.picture.each)
	var ex: Dictionary
	var a := 0
	var b := 1
	var total := 0
	for r: Array in rows:
		total += int(r[1])
	if level == 3 and rng.randf() < 0.5:
		ex = K.number("The pictogram shows %s. How many are there altogether?" % g.topic, total,
			"Find each row's number from the key, then add them all.", "%s = %d." % [" + ".join(_values(rows)), total], g.picture)
		a = -1
		b = -1
	else:
		var order := range(rows.size())
		order.sort_custom(func(x: int, y: int) -> bool: return int(rows[x][1]) > int(rows[y][1]))
		a = order[0]
		b = order[rng.randi_range(1, rows.size() - 1)]
		if int(rows[a][1]) == int(rows[b][1]):
			b = order[rows.size() - 1]
		var diff := int(rows[a][1]) - int(rows[b][1])
		ex = K.number("The pictogram shows %s. How many more for %s than for %s?" % [g.topic, rows[a][0], rows[b][0]], diff,
			"Find both numbers from the key (each symbol is %d), then take the smaller from the bigger." % each,
			"%s: %d. %s: %d. %d − %d = %d." % [rows[a][0], int(rows[a][1]), rows[b][0], int(rows[b][1]), int(rows[a][1]),
				int(rows[b][1]), diff], g.picture)
	ex.data = {"rows": rows, "a": a, "b": b}
	return ex


## A bar graph with a scale: "How many for Red?" (level 3: a bar that ends between two lines)
static func bar_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := _bar_graph(rng, level)
	var bars: Array = g.picture.bars
	var i := rng.randi_range(0, bars.size() - 1)
	var value := int(bars[i][1])
	var step := int(g.picture.step)
	var ex := K.number("The bar graph shows %s. How many for %s?" % [g.topic, bars[i][0]], value,
		"The scale goes up in %ds. Follow the top of the bar across to the numbers.%s" % [step,
			" A bar that ends halfway between two lines is %d more than the lower line." % int(step / 2.0) if level == 3 else ""],
		"The %s bar reaches %d." % [bars[i][0], value], g.picture)
	ex.data = {"bars": bars, "i": i}
	return ex


## A bar graph: which is the most (level 1), how many more or fewer (level 2), how many altogether (level 3)
static func bar_compare(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := _bar_graph(rng, level)
	var bars: Array = g.picture.bars
	var order := range(bars.size())
	order.sort_custom(func(x: int, y: int) -> bool: return int(bars[x][1]) > int(bars[y][1]))
	var ex: Dictionary
	var ask := level - 1
	if level == 1:
		var names: Array = []
		for b: Array in bars:
			names.append(b[0])
		var top: int = order[0]
		ex = K.choice(rng, "The bar graph shows %s. Which has the most?" % g.topic, bars[top][0],
			names.filter(func(n: String) -> bool: return n != str(bars[top][0])), "Find the tallest bar.",
			"%s has the tallest bar: %d." % [bars[top][0], int(bars[top][1])], g.picture)
	elif level == 2:
		var a: int = order[0]
		var b: int = order[bars.size() - 1]
		var fewer := rng.randf() < 0.5
		var diff := int(bars[a][1]) - int(bars[b][1])
		ex = K.number(("The bar graph shows %s. How many fewer for %s than for %s?" % [g.topic, bars[b][0], bars[a][0]]) if fewer else
			("The bar graph shows %s. How many more for %s than for %s?" % [g.topic, bars[a][0], bars[b][0]]), diff,
			"Read both bars on the scale, then take the smaller number from the bigger one.",
			"%s: %d. %s: %d. %d − %d = %d." % [bars[a][0], int(bars[a][1]), bars[b][0], int(bars[b][1]), int(bars[a][1]),
				int(bars[b][1]), diff], g.picture)
	else:
		var total := 0
		for b: Array in bars:
			total += int(b[1])
		ex = K.number("The bar graph shows %s. How many is that altogether?" % g.topic, total,
			"Read every bar on the scale, then add them all.", "%s = %d." % [" + ".join(_values(bars)), total], g.picture)
	ex.data = {"bars": bars, "ask": ask}
	return ex


## "Which bar graph shows: Red 4, Blue 7, Green 2?" (the choices are bar graphs)
static func bar_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = (TOPICS[1][1] as Array).slice(0, 3)
	var step := 1 if level == 1 else 2
	var top := 10 if level == 1 else 12
	var values: Array[int] = []
	for i in 3:
		values.append(rng.randi_range(1, int(top / float(step))) * step)
	var right := {"kind": "bar_graph", "bars": [[names[0], values[0]], [names[1], values[1]], [names[2], values[2]]], "step": step, "top": top}
	var wrongs: Array = []
	var swapped := right.duplicate(true)
	swapped.bars = [[names[0], values[1]], [names[1], values[0]], [names[2], values[2]]]
	if values[0] != values[1]:
		wrongs.append({"picture": swapped})
	for k in 2:
		var off := right.duplicate(true)
		var j := rng.randi_range(0, 2)
		var v := values[j] + step if values[j] + step <= top else values[j] - step
		off.bars[j] = [names[j], v]
		wrongs.append({"picture": off})
	var ex := K.choice(rng, "Which bar graph shows %s %d, %s %d and %s %d?" % [names[0], values[0], names[1], values[1], names[2],
		values[2]], {"picture": right}, wrongs, "Check every bar against its number on the scale, one by one.",
		"%s reaches %d, %s %d and %s %d." % [names[0], values[0], names[1], values[1], names[2], values[2]])
	ex.data = {"values": values}
	return ex


## A line plot of lengths in halves (level 3 in quarters): "How many leaves are 2½ cm long?", "Which length is the most
## common?", "How many are longer than 2 cm?"
static func plot_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p := _plot(rng, level)
	var counts: Dictionary = p.counts   # quarters -> count
	var marks: Array = counts.keys()
	var ask := 0 if level == 1 else rng.randi_range(0, 2)
	var ex: Dictionary
	var at := 0
	if ask == 0:
		at = marks[rng.randi_range(0, marks.size() - 1)]
		ex = K.number("The line plot shows the lengths of some leaves. How many leaves are %s cm long?" % _q_text(at),
			int(counts[at]), "Find %s on the line and count the X marks above it. Each X is one leaf." % _q_text(at),
			"There %s above %s." % ["is 1 X mark" if int(counts[at]) == 1 else "are %d X marks" % int(counts[at]), _q_text(at)],
			p.picture)
	elif ask == 1:
		var best: int = marks[0]
		for q: int in marks:
			if int(counts[q]) > int(counts[best]):
				best = q
		var wrongs: Array = []
		for q: int in marks:
			if q != best:
				wrongs.append("%s cm" % _q_text(q))
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "The line plot shows the lengths of some leaves. Which length is the most common?",
			"%s cm" % _q_text(best), wrongs.slice(0, 3), "Find the tallest pile of X marks.",
			"%s cm has the most X marks: %d." % [_q_text(best), int(counts[best])], p.picture)
		at = best
	else:
		at = int(p.cut)
		var n := 0
		for q: int in marks:
			if q > at:
				n += int(counts[q])
		ex = K.number("The line plot shows the lengths of some leaves. How many leaves are longer than %s cm?" % _q_text(at),
			n, "Count every X mark to the right of %s, not on it." % _q_text(at),
			"To the right of %s there are %d X marks." % [_q_text(at), n], p.picture)
	ex.data = {"counts": counts, "ask": ask, "at": at}
	return ex


## "Which line plot shows these lengths: 2, 2½, 2½, 3?" (the choices are line plots)
static func plot_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var parts := 2 if level < 3 else 4
	var from := rng.randi_range(1, 3)
	var n := (2 if level < 3 else 1) * parts   # marks
	var lengths: Array[int] = []   # in quarters
	var step := int(4.0 / parts)
	for _i in 3 + level:
		lengths.append(from * 4 + rng.randi_range(0, n) * step)
	lengths.sort()
	var right := _plot_picture(from, from + (2 if level < 3 else 1), parts, lengths)
	var wrongs: Array = []
	for k in 3:
		var moved := lengths.duplicate()
		var j := rng.randi_range(0, moved.size() - 1)
		var q: int = moved[j] + step if moved[j] + step <= (from + (2 if level < 3 else 1)) * 4 else moved[j] - step
		moved[j] = q
		var pic := _plot_picture(from, from + (2 if level < 3 else 1), parts, moved)
		if JSON.stringify(pic.counts, "", true) != JSON.stringify(right.counts, "", true):
			wrongs.append({"picture": pic})
	var texts: Array[String] = []
	for q in lengths:
		texts.append(_q_text(q))
	var ex := K.choice(rng, "Some sticks are %s cm long. Which line plot shows them?" % ", ".join(texts), {"picture": right}, wrongs,
		"Each stick is one X above its length. Check each length, and count the X marks.",
		"One X for each stick: %s." % ", ".join(texts))
	ex.data = {"lengths": lengths}
	return ex


# --- Helpers -----------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return NAMES[rng.randi_range(0, NAMES.size() - 1)]


static func _unit_name(unit: String) -> String:
	return {"cm": "centimetres", "m": "metres", "mm": "millimetres", "km": "kilometres"}.get(unit, unit)


## 2.5 -> "2.5", 3.0 -> "3"
static func _num(v: float) -> String:
	return str(roundi(v)) if absf(v - roundf(v)) < 0.001 else String.num(v, 1)


## Unit conversions: level 1 big to small, level 2 with a remainder ("3 m 45 cm"), level 3 small to big.
static func _convert(rng: RandomNumberGenerator, level: int, table: Array) -> Dictionary:
	var c: Array = table[rng.randi_range(0, table.size() - 1)]
	var big: String = c[0]
	var small: String = c[1]
	var f: int = c[2]
	var a := rng.randi_range(2, 9)
	var extra := 0
	var prompt := "%d %s = ? %s" % [a, big, small]
	var answer := a * f
	var to_small := true
	if level == 2:
		extra = rng.randi_range(1, f - 1)
		if f == 1000 and rng.randf() < 0.6:
			extra = rng.randi_range(1, 19) * 50
		prompt = "%d %s %s %s = ? %s" % [a, big, K.fmt(extra), small, small]
		answer = a * f + extra
	elif level == 3:
		to_small = false
		prompt = "%s %s = ? %s" % [K.fmt(a * f), small, big]
		answer = a
	var ex := K.number(prompt, answer, "1 %s = %s %s. %s" % [big, K.fmt(f), small,
		"Divide to change into the bigger unit." if not to_small else "Multiply to change into the smaller unit."],
		("%d × %s = %s %s" % [a, K.fmt(f), K.fmt(a * f), small] + (", and %s + %s = %s %s." % [K.fmt(a * f), K.fmt(extra),
			K.fmt(answer), small] if extra > 0 else ".")) if to_small else
			"%s ÷ %s = %d, so %s %s = %d %s." % [K.fmt(a * f), K.fmt(f), a, K.fmt(a * f), small, a, big])
	ex.data = {"a": a, "factor": f, "extra": extra, "to_small": to_small}
	return ex


## The rows of a shape of squares: a rectangle (level 1), an L-shape (level 2), an L or a step shape (level 3);
## `labelled`: an L with a notch 2 or more squares each way (room for its sides' words).
static func _shape_rows(rng: RandomNumberGenerator, level: int, labelled: bool = false) -> Array[String]:
	var w := rng.randi_range(2, 5) if level == 1 else rng.randi_range(3, 7)
	var h := rng.randi_range(2, 4) if level == 1 else rng.randi_range(3, 5)
	if labelled:
		w = rng.randi_range(4, 7)
		h = rng.randi_range(4, 5)
	var rows: Array[String] = []
	if level == 1:
		for y in h:
			rows.append("#".repeat(w))
		return rows
	var cw := rng.randi_range(2, w - 2) if labelled else rng.randi_range(1, w - 1)
	var ch := rng.randi_range(2, h - 2) if labelled else rng.randi_range(1, h - 1)
	var step := level == 3 and not labelled and rng.randf() < 0.5 and w >= 4 and h >= 3
	for y in h:
		var line := ""
		for x in w:
			var cut := x >= w - cw and y < ch
			if step:
				cut = x >= w - cw and y < ch or (x >= w - int(cw / 2.0) - 1 and y < 1)
			line += "." if cut else "#"
		rows.append(line)
	if _area(rows) == 0:
		rows[h - 1] = "#".repeat(w)
	return rows


static func _area(rows: Array) -> int:
	var n := 0
	for r: Variant in rows:
		for ch in str(r):
			n += 0 if ch == "." else 1
	return n


## The number of unit edges around a shape of squares.
static func _perimeter(rows: Array) -> int:
	var h := rows.size()
	var w := str(rows[0]).length()
	var n := 0
	for y in h:
		for x in w:
			if str(rows[y])[x] == ".":
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h or str(rows[ny])[nx] == ".":
					n += 1
	return n


## A pair of sides for a rectangle of `area` with no side shorter than `least`: "3 by 4".
static func _factor_pair(area: int, least: int) -> String:
	for a in range(least, area + 1):
		if area % a == 0 and int(area / float(a)) >= least and a <= 7 and int(area / float(a)) <= 10:
			return "%d by %d" % [a, int(area / float(a))]
	return "%d by 1" % area


## Side lengths that suit how the shape is drawn (ShapeFacts' corners, from the first corner round).
static func _side_lengths(rng: RandomNumberGenerator, what: String) -> Array[int]:
	var s := rng.randi_range(3, 12)
	var t := rng.randi_range(2, 9)
	var out: Array[int] = []
	match what:
		"triangle_equal", "square", "rhombus", "pentagon", "hexagon", "octagon":
			for _i in ShapeFacts.sides(what):
				out.append(s)
		"triangle_acute":   # drawn with two equal sides
			out.assign([s + 1, s, s + 1])
		"triangle_right":   # its legs 3 and 4 (times k), the long side 5
			var k := rng.randi_range(1, 3)
			out.assign([3 * k, 4 * k, 5 * k])
		"rectangle", "parallelogram":   # drawn longer than tall
			var short := rng.randi_range(2, s)
			out.assign([s + 2, short, s + 2, short])
		"kite":
			out.assign([t, t + 4, t + 4, t])
		"trapezium":   # drawn with its top about half its bottom, the slanting sides a little longer than the top
			out.assign([s, s + 1, 2 * s, s + 1])
		_:
			for _i in ShapeFacts.sides(what):
				out.append(s)
	return out


## Side labels with one "?" at `hide`.
static func _labels(sides: Array[int], hide: int, unit: String) -> Array:
	var out: Array = []
	for i in sides.size():
		out.append("?" if i == hide else "%d %s" % [sides[i], unit])
	return out


static func _shape_reason(name: String) -> String:
	var why := {"square": "4 equal sides and 4 right angles", "rectangle": "4 right angles, its opposite sides equal",
		"triangle": "3 straight sides and 3 corners", "pentagon": "5 straight sides", "hexagon": "6 straight sides",
		"octagon": "8 straight sides", "rhombus": "4 equal sides, but no right angles",
		"parallelogram": "2 pairs of parallel sides, but no right angles",
		"trapezium": "exactly 1 pair of parallel sides", "kite": "2 pairs of equal sides next to each other",
		"equilateral triangle": "3 equal sides", "isosceles triangle": "2 equal sides",
		"scalene triangle": "no equal sides", "right-angled triangle": "a right angle"}
	return "It is a%s %s: it has %s." % ["n" if name.begins_with("i") or name.begins_with("e") or name.begins_with("o") else "",
		name, why.get(name, "its own sides and corners")]


## A pictogram and what it counts: {topic, picture}.
static func _pictogram(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var topic: Array = TOPICS[rng.randi_range(0, TOPICS.size() - 1)]
	var each: int = 2 if level == 1 else ([5, 10][rng.randi_range(0, 1)] if level == 2 else [2, 4, 10][rng.randi_range(0, 2)])
	var names: Array = (topic[1] as Array).duplicate()
	var n := rng.randi_range(3, 4)
	var rows: Array = []
	var used := {}
	for i in n:
		var symbols := rng.randi_range(1, 6)
		var value := symbols * each
		if level == 3 and rng.randf() < 0.5 and symbols >= 2:
			value -= int(each / 2.0)
		while used.has(value):
			value += each
		used[value] = true
		rows.append([names[i], value])
	return {"topic": topic[0], "picture": {"kind": "pictogram", "rows": rows, "each": each}}


## A bar graph and what it counts: {topic, picture}.
static func _bar_graph(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var topic: Array = TOPICS[rng.randi_range(0, TOPICS.size() - 1)]
	var scales: Array = [[1, 10], [2, 12]] if level == 1 else ([[5, 40], [10, 80], [5, 50]] if level == 2 else [[2, 16], [10, 60], [20, 100]])
	var sc: Array = scales[rng.randi_range(0, scales.size() - 1)]
	var step: int = sc[0]
	var top: int = sc[1]
	var names: Array = (topic[1] as Array).duplicate()
	var n := rng.randi_range(3, 4)
	var bars: Array = []
	var used := {}
	for i in n:
		var v := rng.randi_range(1, int(top / float(step))) * step
		if level == 3 and rng.randf() < 0.6 and v > step:
			v -= int(step / 2.0)
		var tries := 0
		while used.has(v) and tries < 50:
			tries += 1
			v = rng.randi_range(1, int(top / float(step))) * step
		used[v] = true
		bars.append([names[i], v])
	return {"topic": topic[0], "picture": {"kind": "bar_graph", "bars": bars, "step": step, "top": top}}


## A line plot of leaf lengths: {counts: {quarters: count}, cut (a mark to count past), picture}.
static func _plot(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var parts := 2 if level < 3 else 4
	var from := rng.randi_range(1, 3)
	var wholes := 3 if level < 3 else 2
	var step := int(4.0 / parts)
	var counts := {}
	var marks := wholes * parts + 1
	for i in marks:
		var c := rng.randi_range(0, 4)
		if c > 0:
			counts[from * 4 + i * step] = c
	if counts.size() < 2:
		counts[from * 4] = 2
		counts[from * 4 + step] = 3
	var most := 0
	var tied := 0
	for q: int in counts:
		if int(counts[q]) > most:
			most = int(counts[q])
			tied = 0
		if int(counts[q]) == most:
			tied += 1
	if tied > 1:   # one length is the most common
		for q: int in counts:
			if int(counts[q]) == most:
				counts[q] = most + 1
				break
	var keys: Array = counts.keys()
	keys.sort()
	var cut: int = keys[int(keys.size() / 2.0) - 1] if keys.size() > 2 else keys[0]
	var lengths: Array[int] = []
	for q: int in keys:
		for _j in int(counts[q]):
			lengths.append(q)
	return {"counts": counts, "cut": cut, "picture": _plot_picture(from, from + wholes, parts, lengths)}


static func _plot_picture(from: int, to: int, parts: int, lengths: Array) -> Dictionary:
	var counts := {}
	for q: Variant in lengths:
		var key := _q_text(int(q))
		counts[key] = int(counts.get(key, 0)) + 1
	return {"kind": "fraction_plot", "from": from, "to": to, "parts": parts, "counts": counts, "unit": "cm"}


## A number of quarters as a plot's words: 10 -> "2½", 3 -> "¾", 12 -> "3" (SchoolPictureG3.quarter_text).
static func _q_text(q: int) -> String:
	var whole := int(q / 4.0)
	var sym: String = ["", "¼", "½", "¾"][q % 4]
	return (str(whole) if whole > 0 or sym == "" else "") + sym


## "Owls has 3 symbols: 3 × 2 = 6." or "… 3 and a half symbols: 3 × 2 = 6, and half a symbol is 1: 7."
static func _symbols_said(name: String, value: int, each: int) -> String:
	var whole := int(value / float(each))
	var half := value - whole * each
	if half == 0 and whole == 1:
		return "%s has 1 symbol: %d." % [name, value]
	if half == 0:
		return "%s has %d symbols: %d × %d = %d." % [name, whole, whole, each, value]
	return "%s has %d and a half symbols: %d × %d = %d, and half a symbol is %d. %d + %d = %d." % [name, whole, whole, each,
		whole * each, half, whole * each, half, value]


static func _first_upper(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


static func _values(rows: Array) -> Array[String]:
	var out: Array[String] = []
	for r: Array in rows:
		out.append(str(r[1]))
	return out


## "3:05" (a 12-hour clock's hour 1-12)
static func _clock(h: int, m: int) -> String:
	return "%d:%02d" % [h, m]


static func _hour12(minutes: int) -> int:
	return (int(minutes / 60.0) + 11) % 12 + 1


## A time of day from minutes after midnight: "3:05" (12-hour) or "15:05" (24-hour).
static func _time(minutes: int, h24: bool) -> String:
	var h := int(minutes / 60.0) % 24
	var m := minutes % 60
	return "%02d:%02d" % [h, m] if h24 else _clock((h + 11) % 12 + 1, m)


static func _part_of_day(h: int) -> String:
	if h < 12:
		return "in the morning"
	if h < 18:
		return "in the afternoon"
	return "in the evening"


## How to count on from start to end: in one jump within the hour, or to the next o'clock first.
static func _count_on_hint(start: int, end: int, h24: bool) -> String:
	var next_hour := start - start % 60 + 60
	if start % 60 == 0 or end <= next_hour:
		return "Count on from %s in 5s and 1s to %s." % [_time(start, h24), _time(end, h24)]
	return "Count on from %s to the next o'clock, %s, then on to %s. Add the jumps." % [_time(start, h24),
		_time(next_hour, h24), _time(end, h24)]


## "4:40 + 35 minutes: 20 minutes to 5:00, then 15 more: 5:15."
static func _end_steps(start: int, minutes: int, h24: bool) -> String:
	var end := start + minutes
	var next_hour := start - start % 60 + 60
	if start % 60 == 0 or end <= next_hour:
		return "%s + %d minutes = %s." % [_time(start, h24), minutes, _time(end, h24)]
	var first := next_hour - start
	var rest := minutes - first
	var hours := int(rest / 60.0)
	var left := rest % 60
	var mid := ""
	if hours > 0:
		mid = ", then %s more to %s" % ["1 hour" if hours == 1 else "%d hours" % hours, _time(next_hour + hours * 60, h24)]
	if left == 0:
		return "%s + %d minutes: %d minutes to %s%s: %s." % [_time(start, h24), minutes, first, _time(next_hour, h24), mid,
			_time(end, h24)]
	return "%s + %d minutes: %d minutes to %s%s, then %d more: %s." % [_time(start, h24), minutes, first,
		_time(next_hour, h24), mid, left, _time(end, h24)]


## "From 2:15 to 3:00 is 45 minutes, and on to 3:05 is 5 more: 50 minutes."
static func _duration_steps(start: int, end: int, h24: bool) -> String:
	var next_hour := start - start % 60 + 60
	if start % 60 == 0 or end <= next_hour:
		return "From %s to %s is %d minutes." % [_time(start, h24), _time(end, h24), end - start]
	var first := next_hour - start
	var rest := end - next_hour
	return "From %s to %s is %d minutes, and on to %s is %d more: %d + %d = %d minutes." % [_time(start, h24),
		_time(next_hour, h24), first, _time(end, h24), rest, first, rest, end - start]
