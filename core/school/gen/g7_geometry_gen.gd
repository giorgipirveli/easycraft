class_name G7GeometryGen
extends RefCounted
## Owner #68 (spec §22.5): grade 7 maths generators for geometry, sampling and probability (Common Core 7.G, 7.SP; units
## 9-15 of the outline): SchoolGen "g7g.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) ->
## Dictionary`, seeded, level 1-3, each with a hint, a worked answer and `data` (its inputs, for
## tests/unit/test_g7_maths_gen.gd). Circles use 3.14 for π, worked in hundredths, never floats. Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
## [a solid, a slice, what the slice is]
const SLICES: Array = [
	["a cube", "parallel to a face", "a square"],
	["a cuboid", "parallel to its end", "a rectangle"],
	["a square-based pyramid", "parallel to its base", "a square"],
	["a cylinder", "parallel to its base", "a circle"],
	["a cylinder", "straight down through its middle", "a rectangle"],
	["a cone", "parallel to its base", "a circle"],
	["a triangular prism", "parallel to its end", "a triangle"],
]
const SHAPES: Array[String] = ["a square", "a rectangle", "a circle", "a triangle"]
## [a sample, is it random and fair]
const SAMPLES: Array = [
	["30 names picked from a hat holding every pupil's name", true],
	["the first 30 pupils through the gate", false],
	["only the football club's members", false],
	["every 10th name on the full school list", true],
	["pupils who answer an online poll", false],
	["30 pupils chosen by a computer at random", true],
]


# --- Unit 9: scale drawings (7.G.1) -------------------------------------------------------------------------------------

## "A map's scale is 1 cm : 5 km. Two towns are 7 cm apart. How far apart are they?"
static func scale_length(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var k: int = [2, 5, 10, 20, 50][rng.randi_range(0, 4)]
	var d := rng.randi_range(2, 12)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A map's scale is 1 cm : %d km. Two towns are %d cm apart on the map. How many km apart are they?" % [k, d], str(d * k),
				"Each cm stands for %d km." % k, "%d × %d = %d km." % [d, k, d * k])
			ex.data = {"k": k, "d": d, "ask": "real"}
		2:
			ex = K.number("A plan's scale is 1 cm : %d m. A wall is %d m long. How long is it on the plan, in cm?" % [k, d * k], str(d),
				"How many lots of %d m?" % k, "%d ÷ %d = %d cm." % [d * k, k, d])
			ex.data = {"k": k, "d": d, "ask": "drawing"}
		_:
			var w := rng.randi_range(2, 8)
			ex = K.number("On a plan with scale 1 cm : %d m, a garden is %d cm by %d cm. What is its real area in m²?" % [k, d, w], str(d * k * w * k),
				"Find the real length and width first.", "%d m by %d m = %d m²." % [d * k, w * k, d * k * w * k])
			ex.data = {"k": k, "d": d, "w": w, "ask": "area"}
	return ex


# --- Unit 10: drawing shapes and slicing solids (7.G.2, 7.G.3) ----------------------------------------------------------

## "Can sides of 3, 4 and 8 cm make a triangle?"
static func triangle_possible(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var b := rng.randi_range(2, 9)
	var c := rng.randi_range(maxi(1, absi(a - b) - 2), a + b + 3)
	if level == 1 and rng.randf() < 0.5:
		c = a + b + rng.randi_range(1, 4)
	var ok := a + b > c and a + c > b and b + c > a
	var ex := K.truefalse("Can sides of %d cm, %d cm and %d cm make a triangle?" % [a, b, c], ok,
		"The two shorter sides must add up to more than the longest.",
		("Yes: the two shorter sides add up to more than the longest." if ok else "No: the two shorter sides are too short to meet."))
	ex.data = {"sides": [a, b, c]}
	return ex


## "A triangle has angles of 50° and 60°. What is the third?"; level 3: slicing solids.
static func third_angle(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var a := rng.randi_range(2, 12) * 5 if level == 1 else rng.randi_range(20, 100)
		var b := rng.randi_range(2, 12) * 5 if level == 1 else rng.randi_range(20, 150 - a)
		b = mini(b, 170 - a)
		ex = K.number("A triangle has angles of %d° and %d°. What is the third angle, in degrees?" % [a, b], str(180 - a - b),
			"A triangle's angles add up to 180°.", "180 − %d − %d = %d°." % [a, b, 180 - a - b])
		ex.data = {"a": a, "b": b, "slice": -1}
	else:
		var i := rng.randi_range(0, SLICES.size() - 1)
		var row: Array = SLICES[i]
		ex = K.choice(rng, "You slice %s %s. What shape is the cut face?" % [row[0], row[1]], row[2],
			SHAPES.filter(func(s: String) -> bool: return s != row[2]).slice(0, 3), "Picture the knife going through.",
			"Slicing %s %s gives %s." % [row[0], row[1], row[2]])
		ex.data = {"a": 0, "b": 0, "slice": i}
	return ex


# --- Unit 11: circles (7.G.4) -------------------------------------------------------------------------------------------

## The circumference or area of a circle (π = 3.14).
static func circle(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var r := rng.randi_range(1, 10)
	var ask: String = ["circumference", "area"][rng.randi_range(0, 1)] if level > 1 else "circumference"
	var by_diameter := level == 3 and rng.randf() < 0.5
	var given := "a diameter of %d cm" % (2 * r) if by_diameter else "a radius of %d cm" % r
	var ex: Dictionary
	if ask == "circumference":
		var c100 := 2 * 314 * r
		ex = K.number("A circle has %s. What is its circumference, in cm? Use 3.14 for π." % given, _dec100(c100),
			"Circumference = 2 × π × radius (or π × diameter).", "2 × 3.14 × %d = %s cm." % [r, _dec100(c100)])
	else:
		var a100 := 314 * r * r
		ex = K.number("A circle has %s. What is its area, in cm²? Use 3.14 for π." % given, _dec100(a100),
			"Area = π × radius × radius.", "3.14 × %d × %d = %s cm²." % [r, r, _dec100(a100)])
	ex.data = {"r": r, "ask": ask}
	return ex


# --- Unit 12: angle facts (7.G.5) ---------------------------------------------------------------------------------------

## Supplementary, complementary and vertical angles; level 3 with x.
static func angle_fact(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kinds: Array = ["supplementary", "complementary"] if level == 1 else ["supplementary", "complementary", "vertical"]
	var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
	var total: int = {"supplementary": 180, "complementary": 90, "vertical": 0}[kind]
	var ex: Dictionary
	if level < 3:
		var a := rng.randi_range(10, 80) if kind == "complementary" else rng.randi_range(20, 160)
		var answer := a if kind == "vertical" else total - a
		ex = K.number("Two angles are %s. One is %d°. What is the other, in degrees?" % [kind, a], str(answer),
			{"supplementary": "Supplementary angles add up to 180°.", "complementary": "Complementary angles add up to 90°.",
				"vertical": "Vertical (opposite) angles are equal."}[kind],
			("%d − %d = %d°." % [total, a, answer]) if kind != "vertical" else "Vertical angles are equal: %d°." % a)
		ex.data = {"kind": kind, "a": a, "m": 0}
	else:
		if kind == "vertical":
			kind = "supplementary"
			total = 180
		var m := rng.randi_range(2, 4)
		var unit := total / (m + 1) if total % (m + 1) == 0 else 0
		while unit == 0:
			m += 1
			unit = total / (m + 1) if total % (m + 1) == 0 else 0
		ex = K.number("Two %s angles are x and %dx. What is x, in degrees?" % [kind, m], str(unit),
			"x + %dx = %d, so %dx = %d." % [m, total, m + 1, total], "%d ÷ %d = %d°." % [total, m + 1, unit])
		ex.data = {"kind": kind, "a": 0, "m": m}
	return ex


# --- Unit 13: area, surface area and volume (7.G.6) ---------------------------------------------------------------------

## A prism's volume, a triangular prism, or a shape with a hole.
static func prism(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 10) * 2
	var h := rng.randi_range(2, 9)
	var l := rng.randi_range(2, 12)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A prism's end has an area of %d cm² and it is %d cm long. What is its volume in cm³?" % [b * h, l], str(b * h * l),
				"Volume = area of the end × length.", "%d × %d = %d cm³." % [b * h, l, b * h * l])
			ex.data = {"kind": "prism", "b": b, "h": h, "l": l}
		2:
			ex = K.number("A triangular prism's end has a base of %d cm and a height of %d cm. It is %d cm long. What is its volume in cm³?" % [b, h, l],
				str(b * h / 2 * l), "Find the triangle's area, then times the length.",
				"½ × %d × %d = %d cm²; × %d = %d cm³." % [b, h, b * h / 2, l, b * h / 2 * l])
			ex.data = {"kind": "triangular", "b": b, "h": h, "l": l}
		_:
			var hole := rng.randi_range(1, mini(b, h) - 1)
			ex = K.number("A rectangle %d cm by %d cm has a square hole %d cm by %d cm cut out. What area is left, in cm²?" % [b, h, hole, hole],
				str(b * h - hole * hole), "The whole rectangle minus the hole.", "%d − %d = %d cm²." % [b * h, hole * hole, b * h - hole * hole])
			ex.data = {"kind": "hole", "b": b, "h": h, "l": hole}
	return ex


# --- Unit 14: samples and populations (7.SP.1-4) ------------------------------------------------------------------------

## Which sample is fair; level 2-3: estimate the population from a sample.
static func sampling(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var i := rng.randi_range(0, SAMPLES.size() - 1)
		var row: Array = SAMPLES[i]
		ex = K.truefalse("To learn about the whole school, is this a fair random sample: %s?" % row[0], row[1],
			"In a random sample, every pupil has the same chance of being picked.",
			("Yes: every pupil has the same chance." if row[1] else "No: some pupils are much more likely to be picked."))
		ex.data = {"i": i, "n": 0, "k": 0, "total": 0}
	else:
		var n: int = [20, 25, 40, 50][rng.randi_range(0, 3)]
		var k := rng.randi_range(2, n - 2)
		var total := n * rng.randi_range(5, 20)
		var est := k * total / n
		while (k * total) % n != 0:
			k += 1
			est = k * total / n
		ex = K.number("In a random sample of %d pupils, %d like chess. About how many of the school's %d pupils like chess?" % [n, k, total], str(est),
			"The same fraction of the whole school.", "%d/%d of %d is %d." % [k, n, total, est])
		ex.data = {"i": -1, "n": n, "k": k, "total": total}
	return ex


# --- Unit 15: probability (7.SP.5-8) ------------------------------------------------------------------------------------

## A bag of counters, two events together, or an expected number.
static func probability(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var red := rng.randi_range(1, 9)
			var blue := rng.randi_range(1, 9)
			var f := _reduced(red, red + blue)
			ex = K.number("A bag has %d red and %d blue counters. You pick one without looking. What is the probability it is red?" % [red, blue],
				_frac_text(f), "Red counters out of all the counters.", "%d out of %d: %s." % [red, red + blue, _frac_text(f)])
			ex.data = {"kind": "bag", "a": red, "b": blue, "n": 0}
		2:
			var pairs: Array = [["a coin shows heads twice in two tosses", 1, 4], ["a dice shows 6 and a coin shows heads", 1, 12],
				["two dice both show an even number", 1, 4], ["a coin shows tails and a dice shows 1 or 2", 1, 6]]
			var i := rng.randi_range(0, pairs.size() - 1)
			var row: Array = pairs[i]
			ex = K.number("What is the probability that %s?" % row[0], K.frac(int(row[1]), int(row[2])),
				"Multiply the probabilities of the two events.", "The probability is %s." % K.frac(int(row[1]), int(row[2])))
			ex.data = {"kind": "compound", "a": row[1], "b": row[2], "n": i}
		_:
			var faces: int = [6, 6, 4, 10][rng.randi_range(0, 3)]
			var rolls := faces * rng.randi_range(5, 20)
			ex = K.number("A fair spinner has %d equal parts, one of them gold. It is spun %d times. About how many times should it land on gold?" % [faces, rolls],
				str(rolls / faces), "Probability × number of spins.", "1/%d × %d = %d." % [faces, rolls, rolls / faces])
			ex.data = {"kind": "expected", "a": faces, "b": rolls, "n": 0}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------------

## Hundredths as a decimal: 3140 -> "31.4".
static func _dec100(h: int) -> String:
	if h % 100 == 0:
		return str(h / 100)
	return "%d.%s" % [h / 100, str(h % 100).pad_zeros(2).rstrip("0")]


static func _reduced(num: int, den: int) -> Array:
	var g := NumberAnswer.gcd(num, den)
	return [num / g, den / g]


static func _frac_text(f: Array) -> String:
	return str(f[0]) if int(f[1]) == 1 else "%d/%d" % [f[0], f[1]]
