class_name G8GeometryGen
extends RefCounted
## Owner #68 (spec §22.5): grade 8 maths generators for linear models, geometry and statistics (Common Core 8.F.4-5, 8.G,
## 8.SP; units 9-16 of the outline): SchoolGen "g8g.<name>", `static func <name>(rng: RandomNumberGenerator, level: int)
## -> Dictionary`, seeded, level 1-3, each with a hint, a worked answer and `data` (its inputs, for
## tests/unit/test_g8_maths_gen.gd). Volumes use 3.14 for π, worked in hundredths. Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
## Pythagorean triples: whole-number right triangles.
const TRIPLES: Array = [[3, 4, 5], [5, 12, 13], [8, 15, 17], [7, 24, 25], [6, 8, 10], [9, 12, 15], [12, 16, 20], [20, 21, 29]]


# --- Unit 9: linear models (8.F.4, 8.F.5) -------------------------------------------------------------------------------

## "A plant is 5 cm tall and grows 2 cm a week. How tall after 7 weeks?"; level 3: the rate from two readings.
static func linear_model(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := rng.randi_range(2, 20)
	var rate := rng.randi_range(2, 9)
	var t := rng.randi_range(3, 12)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A plant is %d cm tall and grows %d cm a week. How tall is it after %d weeks, in cm?" % [start, rate, t], str(start + rate * t),
				"Start + rate × weeks.", "%d + %d × %d = %d cm." % [start, rate, t, start + rate * t])
			ex.data = {"start": start, "rate": rate, "t": t, "ask": "value"}
		2:
			ex = K.choice(rng, "A taxi charges %d coins to start and %d coins a km. Which function gives the cost c for k km?" % [start, rate],
				"c = %dk + %d" % [rate, start], ["c = %dk + %d" % [start, rate], "c = %dk" % (rate + start), "c = k + %d" % (rate + start)],
				"The rate goes with k; the start is added.", "c = %dk + %d." % [rate, start])
			ex.data = {"start": start, "rate": rate, "t": 0, "ask": "equation"}
		_:
			var t2 := t + rng.randi_range(2, 6)
			ex = K.number("A tank holds %d L after %d minutes and %d L after %d minutes, filling at a steady rate. How many litres a minute?" % [start + rate * t, t,
				start + rate * t2, t2], str(rate), "Change in litres ÷ change in minutes.",
				"(%d − %d) ÷ (%d − %d) = %d L a minute." % [start + rate * t2, start + rate * t, t2, t, rate])
			ex.data = {"start": start, "rate": rate, "t": t, "ask": "rate"}
	return ex


# --- Unit 10: transformations (8.G.1, 8.G.3) ----------------------------------------------------------------------------

## Where a point lands after a translation, reflection, rotation or dilation.
static func transform(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var x := _nonzero(rng, 8)
	var y := _nonzero(rng, 8)
	var kinds: Array = ["translate", "reflect_x", "reflect_y"] if level == 1 else (["rotate180", "rotate90", "translate"] if level == 2 else ["dilate", "rotate90", "rotate180"])
	var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
	var a := rng.randi_range(-5, 5)
	var b := rng.randi_range(-5, 5)
	var k := rng.randi_range(2, 3)
	var to := Vector2i(x, y)
	var words := ""
	match kind:
		"translate":
			if x + a == 0 and y + b == 0:
				a += 1
			to = Vector2i(x + a, y + b)
			words = "moved %d %s and %d %s" % [absi(a), "right" if a >= 0 else "left", absi(b), "up" if b >= 0 else "down"]
		"reflect_x":
			to = Vector2i(x, -y)
			words = "reflected across the x-axis"
		"reflect_y":
			to = Vector2i(-x, y)
			words = "reflected across the y-axis"
		"rotate180":
			to = Vector2i(-x, -y)
			words = "rotated 180° about the origin"
		"rotate90":
			to = Vector2i(y, -x)
			words = "rotated 90° clockwise about the origin"
		_:
			to = Vector2i(k * x, k * y)
			words = "enlarged (dilated) by a scale factor of %d from the origin" % k
	var right := _pt(to)
	var wrongs: Array = [_pt(Vector2i(-to.x, to.y)), _pt(Vector2i(to.x, -to.y)), _pt(Vector2i(to.y, to.x))]
	var ex := K.choice(rng, "The point %s is %s. Where does it land?" % [_pt(Vector2i(x, y)), words], right,
		wrongs.filter(func(w: String) -> bool: return w != right),
		{"translate": "Add to x for right, to y for up.", "reflect_x": "Across the x-axis, y changes sign.",
			"reflect_y": "Across the y-axis, x changes sign.", "rotate180": "Both signs change.",
			"rotate90": "Clockwise 90°: (x, y) becomes (y, −x).", "dilate": "Multiply both numbers by the scale factor."}[kind],
		"%s becomes %s." % [_pt(Vector2i(x, y)), right])
	ex.data = {"x": x, "y": y, "kind": kind, "a": a, "b": b, "k": k}
	return ex


# --- Unit 11: congruence and similarity (8.G.2, 8.G.4) ------------------------------------------------------------------

## A missing side in similar shapes.
static func similar_side(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var s1 := rng.randi_range(2, 9)
	var s2 := rng.randi_range(2, 9)
	var num := rng.randi_range(2, 4)
	var den := 1 if level < 3 else 2
	if level == 3 and num % 2 == 0:
		num += 1
	# the big shape is num/den times the small one; keep the answer whole
	if level == 3 and s2 % 2 == 1:
		s2 += 1
	if level == 3 and s1 % 2 == 1:
		s1 += 1
	var big1 := s1 * num / den
	var big2 := s2 * num / den
	var ex := K.number("Two triangles are similar. The small one has sides %d cm and %d cm; the big one's matching sides are %d cm and ? cm. What is the missing side?" % [s1, s2, big1],
		str(big2), "Find the scale factor from the matching sides.", "The scale factor is %d ÷ %d = %s, so %d × %s = %d cm." % [big1, s1,
			str(num) if den == 1 else "%d/%d" % [num, den], s2, str(num) if den == 1 else "%d/%d" % [num, den], big2])
	ex.data = {"s1": s1, "s2": s2, "num": num, "den": den}
	return ex


# --- Unit 12: angles in triangles and parallel lines (8.G.5) ------------------------------------------------------------

## Parallel lines and a transversal, a triangle's exterior angle, or the angle sum.
static func parallel_angles(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(25, 155)
	var kinds: Array = ["corresponding", "alternate"] if level == 1 else (["co-interior", "corresponding", "alternate"] if level == 2 else ["exterior", "co-interior"])
	var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
	var ex: Dictionary
	if kind == "exterior":
		var p := rng.randi_range(25, 80)
		var q := rng.randi_range(25, 80)
		ex = K.number("A triangle has inside angles of %d° and %d°. What is the exterior angle at the third corner, in degrees?" % [p, q], str(p + q),
			"An exterior angle equals the two opposite inside angles added.", "%d + %d = %d°." % [p, q, p + q])
		ex.data = {"kind": kind, "a": p, "b": q}
	else:
		var answer := 180 - a if kind == "co-interior" else a
		ex = K.number("Two parallel lines are crossed by a transversal. One angle is %d°. What is its %s angle, in degrees?" % [a, kind], str(answer),
			{"corresponding": "Corresponding angles are equal.", "alternate": "Alternate angles are equal.",
				"co-interior": "Co-interior angles add up to 180°."}[kind],
			("%s angles are equal: %d°." % [kind.capitalize(), a]) if kind != "co-interior" else "180 − %d = %d°." % [a, answer])
		ex.data = {"kind": kind, "a": a, "b": 0}
	return ex


# --- Unit 13: the Pythagorean theorem (8.G.6-8) -------------------------------------------------------------------------

## The hypotenuse, a leg, or the distance between two points.
static func pythagoras(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t: Array = TRIPLES[rng.randi_range(0, 4 if level == 1 else TRIPLES.size() - 1)]
	var a: int = t[0]
	var b: int = t[1]
	var c: int = t[2]
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A right triangle has legs of %d cm and %d cm. How long is the hypotenuse, in cm?" % [a, b], str(c),
				"a² + b² = c².", "%d² + %d² = %d + %d = %d = %d², so c = %d cm." % [a, b, a * a, b * b, c * c, c, c])
			ex.data = {"a": a, "b": b, "c": c, "ask": "c"}
		2:
			ex = K.number("A right triangle has a hypotenuse of %d cm and one leg of %d cm. How long is the other leg, in cm?" % [c, a], str(b),
				"c² − a² = b².", "%d² − %d² = %d − %d = %d = %d², so %d cm." % [c, a, c * c, a * a, b * b, b, b])
			ex.data = {"a": a, "b": b, "c": c, "ask": "b"}
		_:
			var x1 := rng.randi_range(-5, 5)
			var y1 := rng.randi_range(-5, 5)
			ex = K.number("How far apart are the points (%s, %s) and (%s, %s)?" % [_signed(x1), _signed(y1), _signed(x1 + a), _signed(y1 + b)], str(c),
				"Make a right triangle: across %d and up %d." % [a, b], "√(%d² + %d²) = √%d = %d." % [a, b, c * c, c])
			ex.data = {"a": a, "b": b, "c": c, "ask": "distance"}
	return ex


# --- Unit 14: volume of cylinders, cones and spheres (8.G.9) ------------------------------------------------------------

## π = 3.14, worked in hundredths.
static func round_volume(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var shapes: Array = ["cylinder"] if level == 1 else (["cylinder", "cone"] if level == 2 else ["sphere", "cone"])
	var shape: String = shapes[rng.randi_range(0, shapes.size() - 1)]
	var r := rng.randi_range(1, 6)
	var h := rng.randi_range(2, 10)
	var v100 := 0
	var words := ""
	match shape:
		"cylinder":
			v100 = 314 * r * r * h
			words = "A cylinder has a radius of %d cm and a height of %d cm." % [r, h]
		"cone":
			h = rng.randi_range(1, 4) * 3
			v100 = 314 * r * r * h / 3
			words = "A cone has a radius of %d cm and a height of %d cm." % [r, h]
		_:
			r = rng.randi_range(1, 3) * 3
			v100 = 4 * 314 * r * r * r / 3
			words = "A sphere has a radius of %d cm." % r
	var ex := K.number("%s What is its volume, in cm³? Use 3.14 for π." % words, _dec100(v100),
		{"cylinder": "V = π × r² × h.", "cone": "V = 1/3 × π × r² × h, a third of the cylinder.", "sphere": "V = 4/3 × π × r³."}[shape],
		"The volume is %s cm³." % _dec100(v100))
	ex.data = {"shape": shape, "r": r, "h": h}
	return ex


# --- Unit 15: scatter plots (8.SP.1-3) ----------------------------------------------------------------------------------

## The trend in some data, or a prediction from a line of fit.
static func scatter(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var trend: String = ["positive", "negative", "none"][rng.randi_range(0, 2)]
		var pairs: Array[String] = []
		var ys: Array[int] = []
		for i in 6:
			var x := (i + 1) * 2
			var y := 0
			match trend:
				"positive":
					y = 10 + 3 * x + rng.randi_range(-2, 2)
				"negative":
					y = 60 - 3 * x + rng.randi_range(-2, 2)
				_:
					y = [22, 35, 18, 40, 25, 30][(i + rng.randi_range(0, 5)) % 6]
			ys.append(y)
			pairs.append("(%d, %d)" % [x, y])
		var words := {"positive": "positive: as x rises, y rises", "negative": "negative: as x rises, y falls", "none": "no clear pattern"}
		ex = K.choice(rng, "Data: %s. What kind of pattern does the scatter plot show?" % ", ".join(pairs), words[trend],
			(words.values() as Array).filter(func(w: String) -> bool: return w != words[trend]), "Look at how y changes as x grows.",
			"The pattern is %s." % words[trend])
		ex.data = {"trend": trend, "ys": ys, "m": 0, "b": 0, "x": 0}
	else:
		var m := rng.randi_range(2, 8)
		var b := rng.randi_range(5, 40)
		var x := rng.randi_range(5, 20)
		ex = K.number("A line of fit for hours practised (x) and score (y) is y = %dx + %d. Predict the score for %d hours." % [m, b, x], str(m * x + b),
			"Put x into the equation.", "%d × %d + %d = %d." % [m, x, b, m * x + b])
		ex.data = {"trend": "", "ys": [], "m": m, "b": b, "x": x}
	return ex


# --- Unit 16: two-way tables (8.SP.4) -----------------------------------------------------------------------------------

## Reading a two-way table of pupils who do and don't play an instrument and a sport.
static func two_way(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var both := rng.randi_range(3, 15)
	var inst_only := rng.randi_range(2, 12)
	var sport_only := rng.randi_range(2, 12)
	var neither := rng.randi_range(2, 12)
	var table := "Both: %d. Instrument only: %d. Sport only: %d. Neither: %d." % [both, inst_only, sport_only, neither]
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A two-way table of pupils: %s How many play a sport?" % table, str(both + sport_only),
				"Add everyone who plays a sport.", "%d + %d = %d." % [both, sport_only, both + sport_only])
			ex.data = {"both": both, "inst": inst_only, "sport": sport_only, "neither": neither, "ask": "sport"}
		2:
			var total := both + inst_only + sport_only + neither
			ex = K.number("A two-way table of pupils: %s How many pupils are there in all?" % table, str(total), "Add all four groups.",
				"%d + %d + %d + %d = %d." % [both, inst_only, sport_only, neither, total])
			ex.data = {"both": both, "inst": inst_only, "sport": sport_only, "neither": neither, "ask": "total"}
		_:
			var f := _reduced(both, both + inst_only)
			ex = K.number("A two-way table of pupils: %s Of the pupils who play an instrument, what fraction also play a sport?" % table,
				_frac_text(f), "Both ÷ everyone who plays an instrument.", "%d out of %d = %s." % [both, both + inst_only, _frac_text(f)])
			ex.data = {"both": both, "inst": inst_only, "sport": sport_only, "neither": neither, "ask": "fraction"}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------------

static func _nonzero(rng: RandomNumberGenerator, top: int) -> int:
	var v := rng.randi_range(1, top)
	return v if rng.randf() < 0.5 else -v


static func _signed(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


static func _pt(p: Vector2i) -> String:
	return "(%s, %s)" % [_signed(p.x), _signed(p.y)]


static func _dec100(h: int) -> String:
	if h % 100 == 0:
		return str(h / 100)
	return "%d.%s" % [h / 100, str(h % 100).pad_zeros(2).rstrip("0")]


static func _reduced(num: int, den: int) -> Array:
	var g := NumberAnswer.gcd(num, den)
	return [num / g, den / g]


static func _frac_text(f: Array) -> String:
	return str(f[0]) if int(f[1]) == 1 else "%d/%d" % [f[0], f[1]]
