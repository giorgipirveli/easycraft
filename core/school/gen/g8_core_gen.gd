class_name G8CoreGen
extends RefCounted
## Owner #70, #73 and #111 (research §6.8): grade 8 maths, science and English generators for the research's last 14
## units: expanding brackets, factorising quadratics, points and crossings of parabolas; naming a right-angled
## triangle's sides, finding a side and an angle with sine, cosine and tangent; pressure from force and area, pressure
## and depth, floating and density; energy in joules, kilowatt-hours, meter readings and bills; temperature changes,
## exothermic and endothermic changes, bond energies; Ohm's law, series voltages and parallel currents; transport routes
## in plants and the body, the parts' jobs, the oxygen a breath keeps; choosing parents for breeding, selective breeding
## or genetic engineering; the strongest evidence, explicit or inferred, old stories under new ones, archetypes, an
## argument's parts, credible sources, formal style, graphics for information, precise words, time order, telling
## details, signals of a time shift, media for a talk and slides. SchoolGen "g8k.<name>", `static func <name>(rng:
## RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer
## and `data` (its inputs, for tests/unit/test_g8_core_gen.gd).

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Ana", "Mo", "Zara", "Bram", "Tilly", "Kofi", "Mei", "Rafi"]


# --- Helpers ------------------------------------------------------------------------------------------------------------

static func _pick(rng: RandomNumberGenerator, a: Array) -> Variant:
	return a[rng.randi_range(0, a.size() - 1)]


## `n` different items of `a`, in a seeded random order.
static func _some(rng: RandomNumberGenerator, a: Array, n: int) -> Array:
	var b := a.duplicate()
	K.shuffle(rng, b)
	return b.slice(0, mini(n, b.size()))


## A number as the lessons write it: 1,200, −4, 2.5, 0.75.
static func _t(v: float) -> String:
	var neg := v < -0.0000001
	var x := absf(v)
	var s := ""
	if is_equal_approx(x, roundf(x)):
		s = K.fmt(roundi(x))
	else:
		s = ("%.3f" % x).rstrip("0").rstrip(".")
	return ("−" if neg else "") + s


## A number as an answer: no commas, an ASCII minus.
static func _a(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(roundi(v))
	return ("%.3f" % v).rstrip("0").rstrip(".")


## A whole number in brackets when it is negative: (−3), 4.
static func _p(v: int) -> String:
	return "(−%d)" % absi(v) if v < 0 else str(v)


## "+ 3" or "− 3" after a term.
static func _signed(v: int) -> String:
	return ("+ %d" if v >= 0 else "− %d") % absi(v)


## A coefficient and its letter: "x", "−x", "3x", "−3x²".
static func _term(c: int, letter: String) -> String:
	if c == 1:
		return letter
	if c == -1:
		return "−" + letter
	return ("−%d" % absi(c) if c < 0 else str(c)) + letter


## ax² + bx + c as the lessons write it: "x² + 5x + 6", "2x² − 3x", "x² − 49".
static func _poly(c2: int, c1: int, c0: int) -> String:
	var out := ""
	for pair: Array in [[c2, "x²"], [c1, "x"], [c0, ""]]:
		var c: int = pair[0]
		if c == 0:
			continue
		var letter: String = pair[1]
		var mag := str(absi(c)) if (absi(c) != 1 or letter == "") else ""
		if out == "":
			out = ("−" if c < 0 else "") + mag + letter
		else:
			out += (" + " if c > 0 else " − ") + mag + letter
	return out if out != "" else "0"


## (x + 3), (x − 5), (2x + 1).
static func _br(c1: int, c0: int) -> String:
	return "(%s)" % _poly(0, c1, c0)


## "a" or "an" before a whole number under 100 said aloud: an 8, an 11, an 18, an 80; a 6, a 12.
static func _a_n(n: float) -> String:
	var t := str(roundi(absf(n)))
	return "an" if t.begins_with("8") or t == "11" or t == "18" else "a"


## The hypotenuse, the opposite side, the adjacent side.
static func _side(role: String) -> String:
	return "the hypotenuse" if role == "hyp" else "the %s side" % ROLE_NAMES[role]


static func _gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


## "n/d" in lowest terms (a whole number when d divides n).
static func _frac(n: int, d: int) -> String:
	var g := _gcd(n, d)
	if d / g == 1:
		return str(n / g)
	return "%d/%d" % [n / g, d / g]


## `s` with its first letter a capital (String.capitalize would make every word's first letter one).
static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


static func _r2(v: float) -> float:
	return snappedf(v, 0.01)


## Sine, cosine or tangent of `deg`, to 2 decimal places, as the lessons give it.
static func _trig(f: String, deg: float) -> float:
	var r := deg_to_rad(deg)
	match f:
		"sin":
			return _r2(sin(r))
		"cos":
			return _r2(cos(r))
	return _r2(tan(r))


static func _two(v: float) -> String:
	return "%.2f" % v


# --- Maths: expanding and factorising -------------------------------------------------------------------------------

## Expand brackets: a number times a bracket (1); two brackets (2); special products and (2x + a)(x + b) (3).
static func expand_brackets(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var k := rng.randi_range(2, 9)
			var p := rng.randi_range(1, 5)
			var q := rng.randi_range(1, 9) * (1 if rng.randf() < 0.6 else -1)
			var ask := "x" if rng.randf() < 0.5 else "number"
			var expr := "%d%s" % [k, _br(p, q)]
			var full := _poly(0, k * p, k * q)
			var want := k * p if ask == "x" else k * q
			var prompt := "Expand %s. What number goes in front of x?" % expr if ask == "x" else \
				"Expand %s. What is the number term (the term with no x)?" % expr
			ex = K.number(prompt, _a(want), "Multiply each term inside the brackets by the number outside.",
				"%d × %s = %s and %d × %s = %s, so %s = %s." % [k, _term(p, "x"), _term(k * p, "x"), k, _p(q), _t(k * q),
				expr, full])
			ex.data = {"k": k, "p": p, "q": q, "ask": ask}
		2:
			var p := 0
			var q := 0
			while p == 0 or q == 0 or p + q == 0:
				p = rng.randi_range(-9, 9)
				q = rng.randi_range(-9, 9)
			var ask := "x" if rng.randf() < 0.5 else "number"
			var expr := _br(1, p) + _br(1, q)
			var full := _poly(1, p + q, p * q)
			var want := p + q if ask == "x" else p * q
			var prompt := "Expand %s. What number goes in front of x?" % expr if ask == "x" else \
				"Expand %s. What is the number term?" % expr
			var pic := {}
			if p > 0 and q > 0:
				pic = {"kind": "area_model", "cols": ["x", str(p)], "rows": ["x", str(q)]}
			ex = K.number(prompt, _a(want), "Multiply every term in the first bracket by every term in the second: four products.",
				"x × x = x², x × %s = %s, %s × x = %s, %s × %s = %s: %s." % [_p(q), _term(q, "x"), _p(p), _term(p, "x"),
				_p(p), _p(q), _t(p * q), full], pic)
			ex.data = {"p": p, "q": q, "ask": ask}
		_:
			var kind: String = _pick(rng, ["square_plus", "square_minus", "difference", "coefficient"])
			var a := rng.randi_range(2, 9)
			var b := rng.randi_range(1, 7)
			var expr := ""
			var right := []
			var wrongs: Array = []
			var why := ""
			match kind:
				"square_plus":
					expr = "%s²" % _br(1, a)
					right = [1, 2 * a, a * a]
					wrongs = [[1, 0, a * a], [1, a, a * a], [1, 2 * a, 2 * a]]
					why = "%s² = %s%s = x² + %dx + %dx + %d = %s." % [_br(1, a), _br(1, a), _br(1, a), a, a, a * a,
						_poly(1, 2 * a, a * a)]
				"square_minus":
					expr = "%s²" % _br(1, -a)
					right = [1, -2 * a, a * a]
					wrongs = [[1, 0, -a * a], [1, 2 * a, a * a], [1, -2 * a, -a * a]]
					why = "%s² = %s%s = x² − %dx − %dx + %d = %s." % [_br(1, -a), _br(1, -a), _br(1, -a), a, a, a * a,
						_poly(1, -2 * a, a * a)]
				"difference":
					expr = _br(1, a) + _br(1, -a)
					right = [1, 0, -a * a]
					wrongs = [[1, 0, a * a], [1, -2 * a, -a * a], [1, 2 * a, -a * a]]
					why = "x² − %dx + %dx − %d: the middle terms cancel, leaving %s." % [a, a, a * a, _poly(1, 0, -a * a)]
				_:
					expr = _br(2, a) + _br(1, b)
					right = [2, 2 * b + a, a * b]
					wrongs = [[2, a + b, a * b], [1, 2 * b + a, a * b], [2, 2 * b + a, a + b]]
					why = "2x × x = 2x², 2x × %d = %dx, %d × x = %dx, %d × %d = %d: %s." % [b, 2 * b, a, a, a, b, a * b,
						_poly(2, 2 * b + a, a * b)]
			var shown: Array = []
			for w: Variant in wrongs:
				if w != right and not shown.has(_poly(w[0], w[1], w[2])):
					shown.append(_poly(w[0], w[1], w[2]))
			ex = K.choice(rng, "Which is %s expanded?" % expr, _poly(right[0], right[1], right[2]), shown,
				"Write the brackets out in full and multiply every term by every term; then collect like terms.", why)
			ex.data = {"kind": kind, "a": a, "b": b}
	return ex


## Factorise: a common factor (1); x² + bx + c with positive numbers (2); with signs, or a difference of two squares (3).
static func factorise_quadratic(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var k := rng.randi_range(2, 6)
			var p := 1
			var q := 1
			while _gcd(p, q) != 1 or (p == 1 and q == 1):
				p = rng.randi_range(1, 5)
				q = rng.randi_range(1, 9)
			var expr := _poly(0, k * p, k * q)
			var right := "%d%s" % [k, _br(p, q)]
			var cands: Array = [[k * p, 1, q], [k, p, k * q], [p, k, q], [k * q, p, 1]]
			if k % 2 == 0 and k >= 4:
				cands.append([2, k * p / 2, k * q / 2])
			var wrongs: Array = []
			for c: Array in cands:
				var t := "%d%s" % [c[0], _br(c[1], c[2])]
				var same: bool = int(c[0]) * int(c[1]) == k * p and int(c[0]) * int(c[2]) == k * q
				if int(c[0]) > 1 and t != right and not wrongs.has(t) and (not same or int(c[0]) != k):
					wrongs.append(t)
			ex = K.choice(rng, "Factorise %s completely." % expr, right, wrongs.slice(0, 3),
				"Find the highest common factor of the two numbers and take it outside the brackets.",
				"The highest common factor of %d and %d is %d: %s = %s." % [k * p, k * q, k, expr, right])
			ex.data = {"k": k, "p": p, "q": q}
		2:
			var p := rng.randi_range(2, 9)
			var q := rng.randi_range(2, 9)
			var expr := _poly(1, p + q, p * q)
			ex = K.number("%s = (x + %d)(x + ?). What number goes in the gap?" % [expr, p], _a(q),
				"Find the number that multiplies with %d to make %d; check that the two add to %d." % [p, p * q, p + q],
				"%d × %d = %d and %d + %d = %d, so %s = (x + %d)(x + %d)." % [p, q, p * q, p, q, p + q, expr, p, q])
			ex.data = {"p": p, "q": q}
		_:
			if rng.randf() < 0.35:
				var n := rng.randi_range(2, 9)
				var expr := _poly(1, 0, -n * n)
				ex = K.choice(rng, "Factorise %s." % expr, _br(1, n) + _br(1, -n), [_br(1, -n) + _br(1, -n),
					_br(1, n) + _br(1, n), _br(1, n * n) + _br(1, -1)],
					"Is it a square take away a square? Then it is a difference of two squares.",
					"%s = x² − %d²: a difference of two squares, so %s%s." % [expr, n, _br(1, n), _br(1, -n)])
				ex.data = {"kind": "difference", "n": n}
			else:
				var p := 0
				var q := 0
				while p == 0 or q == 0 or p + q == 0 or p == q or (p > 0 and q > 0):
					p = rng.randi_range(-9, 9)
					q = rng.randi_range(-9, 9)
				var expr := _poly(1, p + q, p * q)
				var right := _br(1, p) + _br(1, q)
				var wrongs: Array = []
				for c: Array in [[-p, -q], [p, -q], [-p, q]]:
					var t := _br(1, c[0]) + _br(1, c[1])
					if int(c[0]) + int(c[1]) != p + q or int(c[0]) * int(c[1]) != p * q:
						if t != right and not wrongs.has(t):
							wrongs.append(t)
				ex = K.choice(rng, "Factorise %s." % expr, right, wrongs,
					"Find two numbers that multiply to the number term and add to the number in front of x; watch the signs.",
					"%s × %s = %s and %s + %s = %s, so %s = %s." % [_p(p), _p(q), _t(p * q), _p(p), _p(q), _t(p + q), expr,
					right])
				ex.data = {"kind": "trinomial", "p": p, "q": q}
	return ex


## The graph of y = x² + c at a point (1); where y = x² − n² crosses the x-axis (2); the crossings of y = (x − p)(x − q)
## expanded (3).
static func parabola_point(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c := rng.randi_range(-9, 9)
			var k := 0
			while k == 0:
				k = rng.randi_range(-4, 4)
			var pic := {"kind": "parabola", "c": c}
			var eq := SchoolPictureG8Core.equation(pic)
			ex = K.number("On the graph of %s, what is y when x = %s?" % [eq, _t(k)], _a(k * k + c),
				"Square x first: a negative number squared is positive. Then add or take away the number.",
				"%s² = %d, and %d %s = %s." % [_p(k), k * k, k * k, _signed(c), _t(k * k + c)], pic)
			ex.data = {"c": c, "x": k}
		2:
			var n := rng.randi_range(1, 5)
			var pic := {"kind": "parabola", "c": -n * n, "from": -6, "to": 6}
			var eq := SchoolPictureG8Core.equation(pic)
			ex = K.number("The graph of %s crosses the x-axis at two points. What is the positive x where it crosses?"
				% eq, _a(n), "On the x-axis y = 0, so find the number whose square is the number term.",
				"0 = x² − %d, so x² = %d: x = %d or x = −%d. The positive one is %d." % [n * n, n * n, n, n, n], pic)
			ex.data = {"c": -n * n, "n": n}
		_:
			var p := 0
			var q := 0
			while p == q or absi(p - q) > 8 or p == 0 or q == 0:
				p = rng.randi_range(-4, 6)
				q = rng.randi_range(-4, 6)
			var lo := mini(p, q)
			var hi := maxi(p, q)
			var pic := {"kind": "parabola", "b": -(p + q), "c": p * q, "from": lo - 2, "to": hi + 2}
			var eq := SchoolPictureG8Core.equation(pic)
			var ask := "larger" if rng.randf() < 0.5 else "smaller"
			ex = K.number("The graph of %s crosses the x-axis twice. What is the %s x where it crosses?" % [eq, ask],
				_a(hi if ask == "larger" else lo),
				"Where it crosses, y = 0: factorise, then make each bracket equal 0.",
				"%s = %s%s, which is 0 when x = %s or x = %s. The %s is %s." % [_poly(1, -(p + q), p * q), _br(1, -lo),
				_br(1, -hi), _t(lo), _t(hi), ask, _t(hi if ask == "larger" else lo)], pic)
			ex.data = {"p": p, "q": q, "ask": ask}
	return ex


# --- Maths: sine, cosine and tangent ----------------------------------------------------------------------------------

const ROLE_NAMES := {"hyp": "hypotenuse", "opp": "opposite", "adj": "adjacent"}
const RATIOS := {"sin": "sin x = opposite ÷ hypotenuse", "cos": "cos x = adjacent ÷ hypotenuse",
	"tan": "tan x = opposite ÷ adjacent"}
## Pythagorean triples (two legs, then the hypotenuse).
const TRIPLES: Array = [[3, 4, 5], [5, 12, 13], [8, 15, 17], [7, 24, 25], [20, 21, 29], [6, 8, 10], [9, 12, 15]]
## The angles of the lessons' table, and their ratios to 2 decimal places.
const TABLE_ANGLES: Array[int] = [30, 37, 45, 53, 60]


## The ratio that uses two sides.
static func _ratio_for(a: String, b: String) -> String:
	var both := [a, b]
	if both.has("opp") and both.has("hyp"):
		return "sin"
	if both.has("adj") and both.has("hyp"):
		return "cos"
	return "tan"


## The lessons' table of sines, cosines and tangents (2 decimal places).
static func _trig_table() -> Dictionary:
	var rows: Array = [["angle"], ["sin"], ["cos"], ["tan"]]
	for a: int in TABLE_ANGLES:
		rows[0].append("%d°" % a)
		rows[1].append(_two(_trig("sin", a)))
		rows[2].append(_two(_trig("cos", a)))
		rows[3].append(_two(_trig("tan", a)))
	return {"kind": "table", "rows": rows}


## Name a side from the marked angle (1); choose the ratio for two sides (2); write a ratio as a fraction (3).
static func trig_sides(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var angle := rng.randi_range(5, 13) * 5
	var at: String = _pick(rng, ["left", "top"])
	match level:
		1:
			var letters := ["a", "b", "c"]
			K.shuffle(rng, letters)
			var sides := {"hyp": letters[0], "opp": letters[1], "adj": letters[2]}
			var role: String = _pick(rng, ["hyp", "opp", "adj"])
			var hints := {"hyp": "The hypotenuse is across from the right angle: the longest side.",
				"opp": "The opposite side is across from the angle x: it does not touch it.",
				"adj": "The adjacent side touches the angle x, and it is not the longest side."}
			var pic := {"kind": "trig_triangle", "angle": angle, "at": at, "sides": sides}
			var asks := {"hyp": "Which side is the hypotenuse?", "opp": "Which side is opposite the marked angle x?",
				"adj": "Which side is adjacent to the marked angle x (and is not the hypotenuse)?"}
			ex = K.choice(rng, asks[role], sides[role],
				[letters[0], letters[1], letters[2]], hints[role],
				"Side %s is the hypotenuse (across from the right angle), side %s is opposite x and side %s is adjacent to x." % [
				sides.hyp, sides.opp, sides.adj], pic)
			ex.data = {"angle": angle, "at": at, "sides": sides, "role": role}
		2:
			var roles := ["hyp", "opp", "adj"]
			K.shuffle(rng, roles)
			var known: String = roles[0]
			var want: String = roles[1]
			var f := _ratio_for(known, want)
			var n := rng.randi_range(3, 20)
			var sides := {known: "%d cm" % n, want: "?"}
			var pic := {"kind": "trig_triangle", "angle": angle, "at": at, "sides": sides, "angle_label": "%d°" % angle}
			ex = K.choice(rng, "You know %s and want %s. Which ratio links them?" % [_side(known), _side(want)], RATIOS[f],
				[RATIOS.sin, RATIOS.cos, RATIOS.tan],
				"Name the two sides from the angle, then find the ratio whose fraction has both of them.",
				"%s and %s are both in %s (SOH CAH TOA)." % [_cap(_side(known)), _side(want), RATIOS[f]], pic)
			ex.data = {"known": known, "want": want, "ratio": f}
		_:
			var t: Array = _pick(rng, TRIPLES)
			var k := rng.randi_range(1, 2)
			var u := int(t[0]) * k
			var v := int(t[1]) * k
			var w := int(t[2]) * k
			if rng.randf() < 0.5:
				var s := u
				u = v
				v = s
			var f: String = _pick(rng, ["sin", "cos", "tan"])
			var num := u if f != "cos" else v
			var den := w if f != "tan" else v
			var shape := clampi(roundi(rad_to_deg(atan(float(u) / v))), 10, 80)
			var pic := {"kind": "trig_triangle", "angle": shape, "sides": {"opp": str(u), "adj": str(v), "hyp": str(w)}}
			ex = K.number("What is %s x? Write it as a fraction." % f, _frac(num, den),
				"Use SOH CAH TOA: find which two sides %s needs, and put the right one on top." % f,
				"%s x = %s ÷ %s = %d/%d%s." % [f, ROLE_NAMES["opp" if f != "cos" else "adj"], ROLE_NAMES["hyp" if f != "tan"
				else "adj"], num, den, "" if _frac(num, den) == "%d/%d" % [num, den] else ", or %s" % _frac(num, den)], pic)
			ex.data = {"opp": u, "adj": v, "hyp": w, "ratio": f}
	return ex


## Find a side: the opposite with sine (1); the adjacent with cosine, or the opposite with tangent (2); a side on the
## bottom of the fraction, by dividing (3). The ratio is given to 2 decimal places.
static func trig_side(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var angle := rng.randi_range(4, 14) * 5
	var unit: String = _pick(rng, ["cm", "m"])
	var known := "hyp"
	var want := "opp"
	var f := "sin"
	match level:
		1:
			pass
		2:
			if rng.randf() < 0.5:
				want = "adj"
				f = "cos"
			else:
				known = "adj"
				f = "tan"
		_:
			if rng.randf() < 0.5:
				known = "opp"
				want = "hyp"
				f = "sin"
			else:
				known = "opp"
				want = "adj"
				f = "tan"
	var v := _trig(f, angle)
	var n := 0.0
	var ans := 0.0
	var how := ""
	if level < 3:
		n = float(_pick(rng, [10, 20, 30, 40, 50, 60, 80, 100]))
		ans = snappedf(n * v, 0.01)
		how = "%s = %s × %s %d° = %s × %s = %s %s." % [ROLE_NAMES[want], ROLE_NAMES[known], f, angle, _t(n), _two(v),
			_t(ans), unit]
	else:
		n = float(rng.randi_range(3, 25))
		ans = snappedf(n / v, 0.1)
		how = "%s %d° = %s ÷ %s, so %s = %s ÷ %s, about %s %s." % [f, angle, ROLE_NAMES["opp"], ROLE_NAMES[want], ROLE_NAMES[want],
			_t(n), _two(v), _t(ans), unit]
	var pic := {"kind": "trig_triangle", "angle": angle, "sides": {known: "%s %s" % [_t(n), unit], want: "?"},
		"angle_label": "%d°" % angle}
	var round_words := " Give it to 1 decimal place." if level == 3 else ""
	var ex := K.number("%s is %s %s and angle x is %d°. %s %d° = %s. How long is %s, in %s?%s" % [
		_cap(_side(known)), _t(n), unit, angle, f, angle, _two(v), _side(want), unit, round_words], _a(ans),
		"Choose the ratio with both sides in it. If the side you want is on top of the fraction, multiply; if it is on the bottom, divide.",
		how, pic)
	ex.data = {"angle": angle, "known": known, "want": want, "ratio": f, "value": v, "side": n}
	return ex


## The sides that give each angle of the table exactly: [angle, ratio, top side, bottom side] for k = 1.
const EXACT: Array = [[30, "sin", 1, 2], [60, "cos", 1, 2], [45, "tan", 1, 1], [37, "sin", 3, 5], [37, "cos", 4, 5],
	[37, "tan", 3, 4], [53, "sin", 4, 5], [53, "cos", 3, 5]]
const SCENES := {"sin": ["ramp", "A ramp's slope is %s m long and it rises %s m."],
	"cos": ["ladder", "A ladder %s m long stands with its foot %s m from the wall."],
	"tan": ["ramp", "A roof rises %s m over a run of %s m."]}


## Find an angle with the table: from a ratio's value (1); from two sides (2); a ramp, a ladder or a roof (3).
static func trig_angle(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var e: Array = _pick(rng, EXACT)
	var angle: int = e[0]
	var f: String = e[1]
	var ex: Dictionary
	var top_name := "opposite" if f != "cos" else "adjacent"
	var bottom_name := "hypotenuse" if f != "tan" else "adjacent"
	match level:
		1:
			var v := _trig(f, angle)
			ex = K.number("%s x = %s. Use the table: what is the angle x, in degrees?" % [f, _two(v)], _a(angle),
				"Find the row for %s, then look along it for the value; read the angle above it." % f,
				"In the %s row, %s is under %d°, so x = %d°." % [f, _two(v), angle, angle], _trig_table())
		2:
			var k := rng.randi_range(2, 6)
			var top := int(e[2]) * k
			var bottom := int(e[3]) * k
			ex = K.number("The %s side is %d cm and the %s is %d cm. Use the table to find x, to the nearest degree." % [
				top_name, top, bottom_name, bottom], _a(angle),
				"Work out the ratio as a decimal, then find it in that ratio's row of the table.",
				"%s x = %d ÷ %d = %s, and the table has %s %d° = %s, so x is about %d°." % [f, top, bottom, _two(float(top)
				/ bottom), f, angle, _two(_trig(f, angle)), angle], _trig_table())
		_:
			var k := rng.randi_range(1, 4)
			var top := int(e[2]) * k
			var bottom := int(e[3]) * k
			var scene: Array = SCENES[f]
			var other := 30 if angle != 30 else 37
			var said := ""
			var sides := {}
			if f == "sin":
				said = scene[1] % [_t(bottom), _t(top)]
				sides = {"hyp": "%d m" % bottom, "opp": "%d m" % top}
			elif f == "cos":
				said = scene[1] % [_t(bottom), _t(top)]
				sides = {"hyp": "%d m" % bottom, "adj": "%d m" % top}
			else:
				said = scene[1] % [_t(top), _t(bottom)]
				sides = {"opp": "%d m" % top, "adj": "%d m" % bottom}
			var pic := {"kind": "trig_triangle", "angle": angle, "scene": scene[0], "sides": sides, "angle_label": "?"}
			var clue := [[angle, _trig(f, angle)], [other, _trig(f, other)]]
			K.shuffle(rng, clue)
			ex = K.number("%s %s %d° = %s and %s %d° = %s. What angle does it make with the ground, in degrees?" % [said,
				f, clue[0][0], _two(clue[0][1]), f, clue[1][0], _two(clue[1][1])], _a(angle),
				"Name the two sides you know from the angle at the ground, work out their ratio, and match it.",
				"%s x = %d ÷ %d = %s, which is %s %d°: the angle is about %d°." % [f, top, bottom, _two(float(top) / bottom),
				f, angle, angle], pic)
	ex.data = {"angle": angle, "ratio": f}
	return ex


# --- Science: pressure ------------------------------------------------------------------------------------------------

const LOADS: Array[String] = ["A loaded crate", "A garden shed", "A full water tank", "A stack of pallets",
	"A pile of hay bales"]
## A block's sides (cm) and its three faces' areas.
const BLOCKS: Array = [[2, 5, 10], [4, 5, 10], [5, 10, 20], [3, 4, 12], [2, 6, 8]]


## Pressure = force ÷ area: in pascals (1); in N/cm², or a force from a pressure (2); a block's biggest pressure (3).
static func pressure_calc(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var area: int = _pick(rng, [2, 4, 5, 8, 10])
			var p: int = _pick(rng, [50, 100, 120, 150, 200, 250, 300, 400, 500])
			var thing: String = _pick(rng, LOADS)
			ex = K.number("%s pushes down with a force of %s N on %d m² of floor. What pressure does it put on the floor, in pascals?"
				% [thing, _t(p * area), area], _a(p),
				"Pressure = force ÷ area: divide the newtons by the square metres.",
				"%s ÷ %d = %s Pa: %s newtons on each square metre." % [_t(p * area), area, _t(p), _t(p)])
			ex.data = {"force": p * area, "area": area, "unit": "Pa"}
		2:
			if rng.randf() < 0.5:
				var area: int = _pick(rng, [20, 40, 50, 80, 100])
				var p := rng.randi_range(2, 20)
				var thing: String = _pick(rng, ["A table's four legs", "A bike's two tyres", "A ladder's two feet",
					"A stool's three legs"])
				ex = K.number("%s press down with %s N on %d cm² in all. What is the pressure, in N/cm²?" % [thing,
					_t(p * area), area], _a(p), "Divide the force in newtons by the area in square centimetres.",
					"%s ÷ %d = %d N/cm²." % [_t(p * area), area, p])
				ex.data = {"force": p * area, "area": area, "unit": "N/cm²"}
			else:
				var area: float = _pick(rng, [0.5, 2.0, 3.0, 4.0])
				var p: int = _pick(rng, [1000, 1500, 2000, 3000, 5000])
				ex = K.number("Water presses on a %s m² window with a pressure of %s Pa. What force pushes on the window, in newtons?"
					% [_t(area), _t(p)], _a(p * area), "Turn the rule round: force = pressure × area.",
					"%s × %s = %s N." % [_t(p), _t(area), _t(p * area)])
				ex.data = {"pressure": p, "area": area}
		_:
			var b: Array = _pick(rng, BLOCKS)
			var faces := [int(b[0]) * int(b[1]), int(b[0]) * int(b[2]), int(b[1]) * int(b[2])]
			var small: int = faces.min()
			var k := rng.randi_range(1, 5)
			var force := small * k
			ex = K.number("A %d cm × %d cm × %d cm block weighs %s N. Which face down gives the biggest pressure? What is that pressure, in N/cm²?"
				% [b[0], b[1], b[2], _t(force)], _a(k),
				"The smallest face makes the biggest pressure: find the smallest area, then divide the force by it.",
				"The faces are %d, %d and %d cm². The smallest is %d cm²: %s ÷ %d = %d N/cm²." % [faces[0], faces[1],
				faces[2], small, _t(force), small, k])
			ex.data = {"sides": b, "force": force}
	return ex


## Pressure and depth: where it is greatest (1); the water's pressure at a depth, about 10 kPa a metre (2); the total
## with the air's 100 kPa, or the depth for a total (3).
static func depth_pressure(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			if rng.randf() < 0.5:
				var depths := _some(rng, [2, 5, 8, 12, 15, 20, 25, 30], 3)
				var deep: int = depths.max()
				var said: Array = depths.map(func(dd: int) -> String: return "%d m down" % dd)
				ex = K.choice(rng, "A diver swims at three depths in the sea. Where does the water press hardest on them?",
					"%d m down" % deep, said, "Think about how much water is above the diver at each depth.",
					"At %d m there is the most water above, so the pressure is greatest." % deep)
				ex.data = {"depths": depths}
			else:
				var pic := {"kind": "fluid_pressure", "view": "spouts", "words": false}
				ex = K.choice(rng, "Three holes are made in a tall tank of water. From which hole does the water come out fastest?",
					"the bottom hole", ["the top hole", "the middle hole", "all the same"],
					"Where is the water deepest? The deeper it is, the more pressure pushes it out.",
					"The bottom hole is deepest, with the most water above it, so its pressure and its jet are the strongest.",
					pic)
				ex.data = {"holes": 3}
		2:
			var d := rng.randi_range(1, 12) * 5
			ex = K.number("Sea water adds about 10 kPa of pressure for every metre of depth. How much pressure does the water add at %d m, in kPa?"
				% d, _a(d * 10), "Multiply the depth in metres by the pressure each metre adds.",
				"%d × 10 = %s kPa." % [d, _t(d * 10)])
			ex.data = {"depth": d}
		_:
			if rng.randf() < 0.5:
				var d := rng.randi_range(1, 8) * 5
				ex = K.number("The air presses with about 100 kPa at the surface, and sea water adds about 10 kPa a metre. What is the total pressure on a diver at %d m, in kPa?"
					% d, _a(100 + d * 10), "Add the air's pressure to the pressure the water adds at that depth.",
					"%d × 10 = %d kPa from the water, plus 100 kPa from the air: %d kPa." % [d, d * 10, 100 + d * 10])
				ex.data = {"depth": d, "find": "total"}
			else:
				var d := rng.randi_range(1, 8) * 5
				ex = K.number("The air gives about 100 kPa and sea water adds about 10 kPa a metre. At what depth is the total pressure %d kPa, in metres?"
					% (100 + d * 10), _a(d), "Take away the air's 100 kPa first; then find how many metres make the rest.",
					"%d − 100 = %d kPa from the water, and %d ÷ 10 = %d m." % [100 + d * 10, d * 10, d * 10, d])
				ex.data = {"depth": d, "find": "depth"}
	return ex


## Densities (g/cm³), from tables of materials; water is 1.
const DENSITIES: Array = [["cork", 0.24], ["pine wood", 0.5], ["oak wood", 0.75], ["candle wax", 0.9], ["ice", 0.92],
	["polypropylene plastic", 0.9], ["PVC plastic", 1.4], ["glass", 2.5], ["granite", 2.7], ["aluminium", 2.7],
	["iron", 7.9], ["copper", 9.0], ["lead", 11.3], ["gold", 19.3]]
## Density (g/cm³) and a volume (cm³) that make a whole mass.
const DENSITY_CASES: Array = [[0.4, 50], [0.5, 40], [0.6, 50], [0.75, 40], [0.8, 50], [1.2, 50], [1.5, 40], [2.5, 20],
	[0.25, 80], [0.9, 100]]


## Floating: a material floats or sinks by its density (1); a density from mass and volume (2); how much of a floating
## block is under water, or the water a floating boat pushes aside (3).
static func float_sink(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var m: Array = _pick(rng, DENSITIES)
			var floats := float(m[1]) < 1.0
			ex = K.choice(rng, "%s has a density of about %s g/cm³; water's is 1 g/cm³. Does a solid block of it float or sink in water?"
				% [_cap(str(m[0])), _t(m[1])],
				"it floats" if floats else "it sinks", ["it sinks" if floats else "it floats"],
				"Compare its density with water's: less dense than water floats, denser sinks.",
				"%s g/cm³ is %s than 1 g/cm³, so it %s." % [_t(m[1]), "less" if floats else "more", "floats" if floats
				else "sinks"])
			ex.data = {"material": m[0], "density": m[1]}
		2:
			var c: Array = _pick(rng, DENSITY_CASES)
			var d := float(c[0])
			var vol := int(c[1]) * rng.randi_range(1, 3)
			var mass := d * vol
			ex = K.number("A block has a mass of %s g and a volume of %d cm³. What is its density, in g/cm³?" % [_t(mass), vol],
				_a(d), "Density = mass ÷ volume.",
				"%s ÷ %d = %s g/cm³: %s." % [_t(mass), vol, _t(d), "less than water's 1, so it floats" if d < 1.0 else
				"more than water's 1, so it sinks"])
			ex.data = {"mass": mass, "volume": vol}
		_:
			if rng.randf() < 0.5:
				var m: Array = _pick(rng, DENSITIES.filter(func(x: Array) -> bool: return float(x[1]) < 1.0))
				ex = K.number("A block of %s (density %s g/cm³) floats in fresh water (1 g/cm³). What fraction of it is under the surface? Give a decimal."
					% [m[0], _t(m[1])], _a(m[1]),
					"It sinks until the water it pushes aside weighs as much as the block: compare the two densities.",
					"The water pushed aside weighs as much as the block, so the part under water is %s ÷ 1 = %s of it." % [
					_t(m[1]), _t(m[1])])
				ex.data = {"material": m[0], "density": m[1]}
			else:
				var mass := rng.randi_range(2, 18) * 50
				ex = K.number("A toy boat with a mass of %d g floats in a bath. What mass of water does it push aside, in grams?"
					% mass, _a(mass), "A floating thing's upthrust balances its weight. Upthrust is the weight of the water pushed aside.",
					"Upthrust = its weight, and upthrust is the weight of the water pushed aside: %d g of water." % mass)
				ex.data = {"mass": mass}
	return ex


# --- Science: energy, power and bills -----------------------------------------------------------------------------------

## Appliances and a typical power (watts).
const APPLIANCES: Array = [["an LED bulb", 10], ["a laptop", 50], ["a TV", 100], ["a fridge", 150],
	["a microwave", 800], ["a toaster", 1000], ["a hair dryer", 1800], ["a heater", 2000], ["an iron", 2400],
	["a kettle", 3000], ["an electric shower", 9000]]


## Energy (J) = power (W) × time (s): in seconds (1); in minutes, in kJ (2); a power from energy and time (3).
static func energy_joules(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var app: Array = _pick(rng, APPLIANCES)
	var w := int(app[1])
	var ex: Dictionary
	match level:
		1:
			var s: int = _pick(rng, [2, 5, 10, 20, 30, 60])
			ex = K.number("%s uses %s W. How much energy does it transfer in %d seconds, in joules?" % [_cap(str(app[0])), _t(w), s], _a(w * s), "A watt is a joule every second: multiply the watts by the seconds.",
				"%s × %d = %s J." % [_t(w), s, _t(w * s)])
			ex.data = {"watts": w, "seconds": s}
		2:
			var mins := rng.randi_range(1, 10)
			ex = K.number("%s uses %s W. How much energy does it transfer in %d minutes, in kilojoules (kJ)?" % [_cap(str(app[0])), _t(w), mins], _a(w * mins * 60 / 1000.0),
				"Change the minutes to seconds, multiply by the watts, then divide by 1,000 for kJ.",
				"%d minutes = %d s; %s × %d = %s J = %s kJ." % [mins, mins * 60, _t(w), mins * 60, _t(w * mins * 60),
				_t(w * mins * 60 / 1000.0)])
			ex.data = {"watts": w, "minutes": mins}
		_:
			var s: int = _pick(rng, [10, 20, 30, 60])
			ex = K.number("A machine transfers %s J of energy in %d seconds. What is its power, in watts?" % [_t(w * s), s],
				_a(w), "Power is energy each second: divide the joules by the seconds.",
				"%s ÷ %d = %s W." % [_t(w * s), s, _t(w)])
			ex.data = {"joules": w * s, "seconds": s}
	return ex


## Kilowatt-hours = kilowatts × hours: whole kW (1); watts and minutes (2); a day of appliances (3).
static func energy_kwh(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var kw := rng.randi_range(1, 3)
			var h := rng.randi_range(2, 8)
			ex = K.number("A %d kW heater is on for %d hours. How many kilowatt-hours (kWh) of energy does it use?" % [kw, h],
				_a(kw * h), "Energy in kWh = power in kW × time in hours.", "%d × %d = %d kWh." % [kw, h, kw * h])
			ex.data = {"kw": kw, "hours": h}
		2:
			var app: Array = _pick(rng, APPLIANCES.filter(func(x: Array) -> bool: return int(x[1]) >= 800))
			var w := int(app[1])
			var mins: int = _pick(rng, [6, 12, 15, 30, 45, 60, 90, 120])
			var kwh := w / 1000.0 * mins / 60.0
			ex = K.number("%s uses %s W. How many kWh does it use in %d minutes?" % [_cap(str(app[0])), _t(w), mins],
				_a(snappedf(kwh, 0.001)), "Change watts to kilowatts (÷ 1,000) and minutes to hours (÷ 60), then multiply.",
				"%s W = %s kW and %d minutes = %s h: %s × %s = %s kWh." % [_t(w), _t(w / 1000.0), mins, _t(mins / 60.0),
				_t(w / 1000.0), _t(mins / 60.0), _t(snappedf(kwh, 0.001))])
			ex.data = {"watts": w, "minutes": mins}
		_:
			var apps := _some(rng, APPLIANCES, 3)
			var rows: Array = [["appliance", "power", "hours a day"]]
			var total := 0.0
			var parts: Array = []
			for a: Array in apps:
				var h: float = _pick(rng, [0.5, 1.0, 2.0, 3.0, 4.0])
				if int(a[1]) >= 2000:
					h = _pick(rng, [0.25, 0.5])
				rows.append([str(a[0]).trim_prefix("a ").trim_prefix("an "), "%s W" % _t(a[1]), _t(h)])
				total += int(a[1]) / 1000.0 * h
				parts.append("%s × %s" % [_t(int(a[1]) / 1000.0), _t(h)])
			total = snappedf(total, 0.001)
			ex = K.number("A home uses these appliances each day. How many kWh do they use in all in a day?", _a(total),
				"For each one, change watts to kW and multiply by its hours; then add them up.",
				"%s = %s kWh." % [" + ".join(parts), _t(total)], {"kind": "table", "rows": rows})
			ex.data = {"rows": rows}
	return ex


const PRICES: Array[float] = [0.2, 0.25, 0.3, 0.4, 0.5]


## Meter readings and bills: the units between two readings (1); the cost of units (2); a week's bill with a daily
## standing charge (3).
static func energy_cost(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := rng.randi_range(10000, 89000)
	var used := rng.randi_range(20, 150)
	var labels: Array = _pick(rng, [["Monday", "next Monday"], ["1 May", "1 June"], ["start", "end"]])
	var pic := {"kind": "energy_meter", "readings": [[labels[0], str(start)], [labels[1], str(start + used)]],
		"unit": "kWh"}
	var price: float = _pick(rng, PRICES)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("Here are two readings of a home's electricity counter. How many kWh (units) were used between them?",
				_a(used), "Take the first reading away from the second.",
				"%d − %d = %d kWh." % [start + used, start, used], pic)
			ex.data = {"start": start, "used": used}
		2:
			ex = K.number("A home used %d kWh. Each unit (1 kWh) costs %s gold. How much does that cost, in gold?" % [used,
				_t(price)], _a(snappedf(used * price, 0.01)), "Multiply the number of units by the price of one unit.",
				"%d × %s = %s gold." % [used, _t(price), _t(snappedf(used * price, 0.01))])
			ex.data = {"used": used, "price": price}
		_:
			var charge: float = _pick(rng, [0.5, 1.0])
			var bill := snappedf(used * price + 7 * charge, 0.01)
			ex = K.number("These readings are a week apart. A unit costs %s gold, and there is a standing charge of %s gold a day. What is the week's bill, in gold?"
				% [_t(price), _t(charge)], _a(bill),
				"Find the units used, multiply by the price, then add 7 days of the standing charge.",
				"%d units × %s = %s gold; 7 × %s = %s gold; %s gold in all." % [used, _t(price), _t(snappedf(used * price,
				0.01)), _t(charge), _t(7 * charge), _t(bill)], pic)
			ex.data = {"start": start, "used": used, "price": price, "charge": charge}
	return ex


# --- Science: hot and cold reactions -------------------------------------------------------------------------------------

const EXO: Array[String] = ["a candle burning", "a campfire", "respiration in your cells", "an acid neutralising an alkali",
	"iron powder rusting in a hand warmer", "calcium oxide reacting with water", "a gel warmer's liquid crystallising",
	"a firework exploding"]
const ENDO: Array[String] = ["photosynthesis in a leaf", "heating limestone to make lime", "citric acid with baking soda",
	"ammonium nitrate dissolving in a cold pack", "baking soda breaking down in a hot oven", "ice melting",
	"urea dissolving in water"]
const DEVICES: Array = [["a cold pack for a sprained ankle", "endo"], ["a hand warmer for a winter walk", "exo"],
	["a self-heating can of soup", "exo"], ["a cooling pad for a sore knee", "endo"], ["a heat pad for cold feet", "exo"],
	["an ice-free cold pack for a picnic", "endo"]]
const EXO_USE: Array[String] = ["iron powder rusting fast", "calcium oxide reacting with water",
	"a gel pack's liquid crystallising"]
const ENDO_USE: Array[String] = ["ammonium nitrate dissolving in water", "urea dissolving in water",
	"citric acid with baking soda"]
const EXO_WORDS := "exothermic: it gives out heat"
const ENDO_WORDS := "endothermic: it takes in heat"


## A temperature change: exothermic or endothermic (1); by how many degrees (2); which of three mixtures (3).
static func temp_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1, 2:
			var t0 := rng.randi_range(15, 24)
			var dt := rng.randi_range(3, 20) * (1 if rng.randf() < 0.5 else -1)
			var t1 := t0 + dt
			var pic := {"kind": "thermometer", "from": -10, "to": 50, "step": 10, "values": [t0, t1],
				"names": ["before", "after"], "minor": 4}
			if level == 1:
				ex = K.choice(rng, "Two chemicals are mixed. The thermometer shows the temperature before and after. What kind of change is it?",
					EXO_WORDS if dt > 0 else ENDO_WORDS, [ENDO_WORDS if dt > 0 else EXO_WORDS],
					"Did the mixture get warmer or colder? Warmer means energy went out to the surroundings.",
					"It went from %d °C to %d °C: %s, so it is %s." % [t0, t1, "warmer" if dt > 0 else "colder", EXO_WORDS if
					dt > 0 else ENDO_WORDS], pic)
			else:
				ex = K.number("A mixture's temperature %s from %d °C to %d °C. By how many degrees did it change?" % ["rose" if
					dt > 0 else "fell", t0, t1], _a(absi(dt)), "Find the difference between the two temperatures.",
					"%d − %d = %d °C: %s." % [maxi(t0, t1), mini(t0, t1), absi(dt), "it rose, so it is exothermic" if dt > 0
					else "it fell, so it is endothermic"], pic)
			ex.data = {"before": t0, "after": t1}
		_:
			var names := ["A", "B", "C"]
			var rows: Array = [["mixture", "start (°C)", "end (°C)"]]
			var changes: Array[int] = []
			var ask := "most heat" if rng.randf() < 0.5 else "endothermic"
			for _t in 50:
				changes.clear()
				for k in 3:
					changes.append(rng.randi_range(-9, 15))
				var ok := not changes.has(0)
				if ask == "most heat":
					var top: int = changes.max()
					ok = ok and top > 0 and changes.count(top) == 1
				else:
					ok = ok and changes.filter(func(c: int) -> bool: return c < 0).size() == 1
				if ok:
					break
			var answer := ""
			for k in 3:
				var t0 := rng.randi_range(18, 22)
				rows.append([names[k], str(t0), str(t0 + changes[k])])
				if ask == "most heat" and changes[k] == changes.max():
					answer = names[k]
				if ask == "endothermic" and changes[k] < 0:
					answer = names[k]
			var prompt := "Which mixture gave out the most heat?" if ask == "most heat" else "Which mixture took in heat (endothermic)?"
			var said: Array = []
			for k in 3:
				said.append("%s %s by %d °C" % [names[k], "rose" if changes[k] > 0 else "fell", absi(changes[k])])
			ex = K.choice(rng, prompt, "mixture " + answer, ["mixture A", "mixture B", "mixture C"],
				"Work out each change: a rise gives out heat, a fall takes it in; compare their sizes.",
				"%s: so mixture %s." % [", ".join(said), answer], {"kind": "table", "rows": rows})
			ex.data = {"changes": changes, "ask": ask}
	return ex


## Exothermic or endothermic: one change (1); sort six (2); the change a device should use (3).
static func reaction_type(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var exo := rng.randf() < 0.5
			var item: String = _pick(rng, EXO if exo else ENDO)
			ex = K.choice(rng, "Is this exothermic or endothermic: %s?" % item, EXO_WORDS if exo else ENDO_WORDS,
				[ENDO_WORDS if exo else EXO_WORDS],
				"Would the surroundings get warmer or colder? Warmer means energy is given out.",
				"%s %s, so it is %s." % [_cap(item), "gives out heat" if exo else "takes in heat", "exothermic" if exo
				else "endothermic"])
			ex.data = {"item": item, "exo": exo}
		2:
			var n_exo := rng.randi_range(2, 4)
			var items: Array = _some(rng, EXO, n_exo) + _some(rng, ENDO, 6 - n_exo)
			K.shuffle(rng, items)
			var groups := ["gives out heat", "takes in heat"]
			var answer: Array = []
			for it: String in items:
				answer.append(0 if EXO.has(it) else 1)
			ex = {"type": "sort", "prompt": "Sort these changes: exothermic (gives out heat) or endothermic (takes in heat)?",
				"groups": groups, "items": items, "answer": answer,
				"hint": "Ask of each one: does it warm its surroundings, or cool them?",
				"explain": "Exothermic, giving out heat: %s. The others take heat in: endothermic." % ", ".join(
					items.filter(func(x: String) -> bool: return EXO.has(x)))}
			ex.data = {"items": items}
		_:
			var dev: Array = _pick(rng, DEVICES)
			var exo := str(dev[1]) == "exo"
			var right: String = _pick(rng, EXO_USE if exo else ENDO_USE)
			ex = K.choice(rng, "An engineer designs %s. Which change could it use?" % dev[0], right,
				_some(rng, ENDO_USE if exo else EXO_USE, 2),
				"Does the device need to warm things up or cool them down? Then pick a change that does that.",
				"It must %s, so it needs an %s change: %s." % ["warm up" if exo else "cool down", "exothermic" if exo else
				"endothermic", right])
			ex.data = {"device": dev[0], "right": right}
	return ex


## Energy level diagrams and bonds: the energy given out or taken in (1); breaking and making bonds: which kind (2);
## how much overall (3).
static func bond_energy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var exo := rng.randf() < 0.5
			var hi := rng.randi_range(5, 18) * 50
			var lo := hi - rng.randi_range(2, mini(9, hi / 50 - 2)) * 50
			var r := hi if exo else lo
			var p := lo if exo else hi
			var pic := {"kind": "energy_profile", "type": "exo" if exo else "endo", "values": [r, p], "hide": "change"}
			ex = K.number("The energy level diagram shows the reactants and the products. How much energy is %s, in kJ?" % (
				"given out" if exo else "taken in"), _a(hi - lo),
				"The change is the gap between the reactants' level and the products' level.",
				"%d − %d = %d kJ %s: the products have %s energy than the reactants." % [hi, lo, hi - lo, "given out" if exo
				else "taken in", "less" if exo else "more"], pic)
			ex.data = {"reactants": r, "products": p}
		_:
			var broken := rng.randi_range(20, 200) * 10
			var made := broken
			while made == broken:
				made = rng.randi_range(20, 200) * 10
			var exo := made > broken
			var said := "Breaking the bonds takes in %s kJ. Making the new bonds gives out %s kJ." % [_t(broken), _t(made)]
			if level == 2:
				ex = K.choice(rng, said + " Is the reaction exothermic or endothermic?", "exothermic" if exo else
					"endothermic", ["endothermic" if exo else "exothermic"],
					"Compare the two: if making gives out more than breaking takes in, energy is left over to give out.",
					"%s kJ out and %s kJ in: %s, so it is %s." % [_t(made), _t(broken), "more out than in" if exo else
					"more in than out", "exothermic" if exo else "endothermic"])
			else:
				ex = K.number(said + " How much energy is %s overall, in kJ?" % ("given out" if exo else "taken in"),
					_a(absi(made - broken)), "Find the difference between the energy taken in and the energy given out.",
					"%s − %s = %s kJ %s overall." % [_t(maxi(made, broken)), _t(mini(made, broken)), _t(absi(made - broken)),
					"given out" if exo else "taken in"])
			ex.data = {"broken": broken, "made": made}
	return ex


# --- Science: current, voltage and resistance ------------------------------------------------------------------------

## Ohm's law: V = I × R (1); the ammeter's reading, I = V ÷ R (2); a lamp's resistance, R = V ÷ I (3).
static func ohms_law(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var r := 0
	var i := 0.0
	for _t in 60:
		r = _pick(rng, [2, 3, 4, 5, 6, 8, 10, 12, 20])
		i = _pick(rng, [0.25, 0.5, 1.0, 1.5, 2.0, 3.0])
		if r * i <= 24.0 and is_equal_approx(snappedf(r * i, 0.5), r * i):
			break
	var v := r * i
	match level:
		1:
			ex = K.number("A current of %s A flows through %s %d ohm resistor. What is the voltage across it, in volts?" % [
				_t(i), _a_n(r), r], _a(v), "Voltage = current × resistance.", "V = I × R = %s × %d = %s V." % [_t(i), r, _t(v)])
		2:
			var pic := {"kind": "meter_circuit", "layout": "series", "volts": v, "parts": [["resistor", r]],
				"meters": [["A", "main", "?"]], "names": true}
			ex = K.number("The cell gives %s V across %s %d ohm resistor. What does the ammeter read, in amps?" % [_t(v),
				_a_n(r), r],
				_a(i), "Current = voltage ÷ resistance.", "I = V ÷ R = %s ÷ %d = %s A." % [_t(v), r, _t(i)], pic)
		_:
			var pic := {"kind": "meter_circuit", "layout": "series", "volts": v, "parts": [["lamp"]],
				"meters": [["A", "main", i]]}
			ex = K.number("The ammeter reads %s A and the cell gives %s V. What is the lamp's resistance, in ohms?" % [_t(i),
				_t(v)], _a(r), "Resistance = voltage ÷ current.", "R = V ÷ I = %s ÷ %s = %d ohms." % [_t(v), _t(i), r], pic)
	ex.data = {"ohms": r, "amps": i, "volts": v}
	return ex


## Series circuits: the voltages add up to the cell's (1); the current from the total resistance (2); one part's
## voltage from the current (3).
static func series_volts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 2 if level < 3 else 3
	var ohms: Array = []
	var amps := 0.0
	var volts := 0.0
	for _t in 80:
		ohms.clear()
		for k in n:
			ohms.append(rng.randi_range(1, 10))
		amps = _pick(rng, [0.5, 1.0, 1.5, 2.0])
		var total := 0
		for o: int in ohms:
			total += o
		volts = amps * total
		if volts <= 24.0 and is_equal_approx(snappedf(volts, 0.5), volts):
			break
	var parts: Array = []
	for o: int in ohms:
		parts.append(["lamp" if level == 1 else "resistor", o])
	var ex: Dictionary
	match level:
		1:
			var v0 := amps * int(ohms[0])
			var pic := {"kind": "meter_circuit", "layout": "series", "volts": volts, "parts": parts,
				"meters": [["V", "0", v0], ["V", "1", "?"]]}
			ex = K.number("The cell gives %s V. One lamp has %s V across it. What does the voltmeter across the other lamp read, in volts?"
				% [_t(volts), _t(v0)], _a(volts - v0),
				"In series the cell's voltage is shared: the voltages across the parts add up to the cell's.",
				"%s − %s = %s V." % [_t(volts), _t(v0), _t(volts - v0)], pic)
		2:
			var pic := {"kind": "meter_circuit", "layout": "series", "volts": volts, "parts": parts,
				"meters": [["A", "main", "?"]], "names": true}
			ex = K.number("%s %d ohm and %s %d ohm resistor are in series with a %s V cell. What does the ammeter read, in amps?" % [
				_cap(_a_n(ohms[0])), ohms[0], _a_n(ohms[1]), ohms[1], _t(volts)], _a(amps),
				"In series the resistances add up. Then current = voltage ÷ total resistance.",
				"%d + %d = %d ohms; %s ÷ %d = %s A." % [ohms[0], ohms[1], int(ohms[0]) + int(ohms[1]), _t(volts),
				int(ohms[0]) + int(ohms[1]), _t(amps)], pic)
		_:
			var k := rng.randi_range(0, 2)
			var total := int(ohms[0]) + int(ohms[1]) + int(ohms[2])
			var pic := {"kind": "meter_circuit", "layout": "series", "volts": volts, "parts": parts,
				"meters": [["V", str(k), "?"]], "names": true}
			ex = K.number("Three resistors (%d, %d and %d ohms) are in series with a %s V cell. What is the voltage across the %d ohm resistor?"
				% [ohms[0], ohms[1], ohms[2], _t(volts), ohms[k]], _a(amps * int(ohms[k])),
				"Find the current first (voltage ÷ total resistance), then voltage = current × that resistance.",
				"Total %d ohms, so I = %s ÷ %d = %s A; V = %s × %d = %s V." % [total, _t(volts), total, _t(amps), _t(amps),
				ohms[k], _t(amps * int(ohms[k]))], pic)
	ex.data = {"ohms": ohms, "volts": volts}
	return ex


## Resistances that give a whole or tenths current from 6 V or 12 V.
const BRANCH_OHMS := {6: [2, 3, 4, 6, 10, 12, 15, 20, 30], 12: [3, 4, 6, 8, 10, 12, 20, 24, 30, 40, 60]}


## Parallel circuits: the main current is the branches' sum (1); a branch from the main and another (2); three branches
## from their resistances (3).
static func parallel_amps(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var v: int = _pick(rng, [6, 12])
	var n := 2 if level < 3 else 3
	var ohms: Array = _some(rng, BRANCH_OHMS[v], n)
	var cur: Array[float] = []
	for o: int in ohms:
		cur.append(snappedf(float(v) / o, 0.01))
	var total := 0.0
	for c in cur:
		total += c
	total = snappedf(total, 0.01)
	var parts: Array = []
	for o: int in ohms:
		parts.append(["lamp", o])
	var ex: Dictionary
	match level:
		1:
			var pic := {"kind": "meter_circuit", "layout": "parallel", "volts": v, "parts": parts,
				"meters": [["A", "0", cur[0]], ["A", "1", cur[1]], ["A", "main", "?"]]}
			ex = K.number("Two lamps are in parallel. Their branches carry %s A and %s A. What does the ammeter by the cell read, in amps?"
				% [_t(cur[0]), _t(cur[1])], _a(total), "In parallel the branch currents add up to the current from the cell.",
				"%s + %s = %s A." % [_t(cur[0]), _t(cur[1]), _t(total)], pic)
		2:
			var pic := {"kind": "meter_circuit", "layout": "parallel", "volts": v, "parts": parts,
				"meters": [["A", "main", total], ["A", "0", cur[0]], ["A", "1", "?"]]}
			ex = K.number("The ammeter by the cell reads %s A and one branch carries %s A. What does the other branch carry, in amps?"
				% [_t(total), _t(cur[0])], _a(snappedf(total - cur[0], 0.01)),
				"The branches share the cell's current: take the known branch away from the total.",
				"%s − %s = %s A." % [_t(total), _t(cur[0]), _t(snappedf(total - cur[0], 0.01))], pic)
		_:
			var pic := {"kind": "meter_circuit", "layout": "parallel", "volts": v, "parts": parts,
				"meters": [["A", "main", "?"]], "names": true}
			var said: Array = []
			for k in n:
				said.append("%d ÷ %d = %s A" % [v, ohms[k], _t(cur[k])])
			ex = K.number("Three lamps (%d, %d and %d ohms) are in parallel with a %d V cell. What does the ammeter by the cell read, in amps?"
				% [ohms[0], ohms[1], ohms[2], v], _a(total),
				"Each branch has the cell's full voltage: find each branch's current (voltage ÷ resistance), then add.",
				"%s; together %s A." % ["; ".join(said), _t(total)], pic)
	ex.data = {"volts": v, "ohms": ohms}
	return ex


# --- Science: transport in plants and animals ---------------------------------------------------------------------------

const ROUTES := {
	"water through a plant": ["water in the soil", "a root hair cell", "the xylem in the root", "the xylem in the stem",
		"a leaf", "a stoma", "the air, as water vapour"],
	"blood through the heart": ["the vena cava", "the right atrium", "the right ventricle", "the pulmonary artery",
		"the lungs", "the pulmonary vein", "the left atrium", "the left ventricle", "the aorta"],
	"oxygen from the air into the blood": ["the nose or mouth", "the windpipe", "a bronchus", "a bronchiole",
		"an air sac (alveolus)", "a capillary", "a red blood cell"],
	"sugar from a leaf to a root": ["a leaf cell making sugar", "the phloem in the leaf", "the phloem in the stem",
		"the phloem in the root", "a root cell storing it"],
}
const JOBS: Array = [["xylem", "carries water and minerals up"], ["phloem", "carries sugars both ways"],
	["root hair cells", "take in water from the soil"], ["stomata", "let water vapour out"],
	["arteries", "carry blood away from the heart"], ["veins", "bring blood back to the heart"],
	["capillaries", "pass substances to cells"], ["red blood cells", "carry oxygen"], ["plasma", "carries dissolved food"],
	["white blood cells", "fight germs"], ["platelets", "help blood to clot"], ["valves", "stop blood flowing backwards"],
	["alveoli", "let gases into and out of blood"]]
## Parts easily mixed up with each other.
const LOOKALIKES: Array = [["xylem", "phloem", "stomata"], ["arteries", "veins", "capillaries"],
	["red blood cells", "white blood cells", "plasma", "platelets"], ["root hair cells", "stomata", "xylem"],
	["valves", "platelets", "capillaries"], ["alveoli", "capillaries", "veins"]]


## Order a transport route: 4 steps (1), 5 (2), 6 (3).
static func transport_route(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := level + 3
	var names: Array = ROUTES.keys().filter(func(k: String) -> bool: return (ROUTES[k] as Array).size() >= n)
	var name: String = _pick(rng, names)
	var route: Array = ROUTES[name]
	var start := rng.randi_range(0, route.size() - n)
	var steps := route.slice(start, start + n)
	var ex := K.order(rng, "Put these in the order of the route: %s." % name, steps,
		"Start where it enters, then follow it step by step to where it ends up.",
		"In order: %s." % ", then ".join(steps))
	ex.data = {"route": name, "start": start, "n": n}
	return ex


## The jobs of transport's parts: a part's job (1); match four (2); which part does a job, among look-alikes (3).
static func transport_job(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var job_of := {}
	for j: Array in JOBS:
		job_of[j[0]] = j[1]
	match level:
		1:
			var j: Array = _pick(rng, JOBS)
			var others: Array = []
			for o: Array in _some(rng, JOBS, 4):
				if o[0] != j[0] and others.size() < 3:
					others.append(o[1])
			ex = K.choice(rng, "What is the job of the %s?" % j[0], j[1], others,
				"Think about where the part is and what travels through it or past it.",
				"The %s %s." % [j[0], j[1]])
			ex.data = {"part": j[0]}
		2:
			var picks := _some(rng, JOBS, 4)
			var pairs: Array = []
			for j: Array in picks:
				pairs.append([j[0], j[1]])
			var idx: Array = range(4)
			for _t in 20:
				K.shuffle(rng, idx)
				if idx.all(func(i: int) -> bool: return idx[i] != i):
					break
			var matches: Array = []
			for i: int in idx:
				matches.append(pairs[i][1])
			var answer: Array = []
			for p: Array in pairs:
				answer.append(matches.find(p[1]))
			ex = {"type": "match", "prompt": "Match each part to its job.", "items": pairs.map(func(p: Array) -> String:
				return p[0]), "matches": matches, "answer": answer,
				"hint": "Start with the one you are surest of, then match the rest.",
				"explain": _cap("; ".join(pairs.map(func(p: Array) -> String: return "the %s %s" % [p[0], p[1]])) + ".")}
			ex.data = {"parts": pairs.map(func(p: Array) -> String: return p[0])}
		_:
			var group: Array = _pick(rng, LOOKALIKES)
			var part: String = _pick(rng, group)
			var wrongs: Array = group.filter(func(g: String) -> bool: return g != part)
			ex = K.choice(rng, "Which part has this job: “%s”?" % job_of[part], part, wrongs,
				"These parts are easy to mix up: think about what each one carries or does, and where.",
				"The %s %s." % [part, job_of[part]])
			ex.data = {"part": part}
	return ex


const VOLUMES: Array[int] = [300, 400, 500, 600, 700, 800]


## Oxygen in a breath: 21% of the air (1); the oxygen the body keeps, 21% in and 16% out (2); in a minute (3).
static func air_in_out(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var vol: int = _pick(rng, VOLUMES)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("You breathe in %d mL of air, and about 21%% of air is oxygen. How many mL of oxygen is that?" % vol,
				_a(vol * 21 / 100.0), "Find 1% (divide by 100), then multiply by 21.",
				"%d ÷ 100 = %s, and %s × 21 = %s mL of oxygen." % [vol, _t(vol / 100.0), _t(vol / 100.0),
				_t(vol * 21 / 100.0)])
		2:
			ex = K.number("Breathed-in air is about 21%% oxygen; breathed-out air about 16%%. In a %d mL breath, how many mL of oxygen does the body keep?"
				% vol, _a(vol * 5 / 100.0), "The body keeps the difference: 21% − 16% of the breath.",
				"21 − 16 = 5%%, and 5%% of %d mL = %s mL." % [vol, _t(vol * 5 / 100.0)])
		_:
			var rate := rng.randi_range(12, 20)
			ex = K.number("At rest a teenager takes %d breaths a minute, each %d mL. The body keeps about 5%% of each breath as oxygen. How many mL of oxygen a minute?"
				% [rate, vol], _a(vol * 5 / 100.0 * rate),
				"Find the oxygen kept from one breath, then multiply by the breaths in a minute.",
				"5%% of %d = %s mL a breath; %s × %d = %s mL a minute." % [vol, _t(vol * 5 / 100.0), _t(vol * 5 / 100.0), rate,
				_t(vol * 5 / 100.0 * rate)])
			ex.data = {"volume": vol, "rate": rate}
			return ex
	ex.data = {"volume": vol}
	return ex


# --- Science: breeding and genes ---------------------------------------------------------------------------------------

const BREED_GOALS: Array = [["tomato plants", "the most tomatoes", "tomatoes a plant"],
	["wheat plants", "the heaviest grains", "grams of grain"], ["sheep", "the finest wool", "wool score"],
	["roses", "the strongest scent", "scent score"], ["hens", "the most eggs", "eggs a year"]]
const BREED_STEPS: Array[String] = ["decide which trait you want", "choose parents that show it most",
	"breed them together", "choose the young that show it most", "breed those, generation after generation"]
const BRED: Array[String] = ["dog breeds from wolves", "broccoli from wild cabbage", "cows that give more milk",
	"wheat with short, strong stems", "sheep with finer wool", "hens that lay more eggs", "roses with bigger flowers"]
const ENGINEERED: Array[String] = ["bacteria making human insulin", "Golden Rice making beta-carotene",
	"cotton that makes its own pest killer", "maize that resists insect pests", "papaya that resists a virus",
	"microbes making cheese-making enzymes"]
const BENEFITS: Array[String] = ["more food from the same land", "less pesticide sprayed", "medicines such as insulin",
	"crops that survive drought", "vitamins in everyday foods"]
const WORRIES: Array[String] = ["genes spreading to wild plants", "harm to insects that are not pests",
	"who owns the seeds", "long-term effects need testing", "less variety in crops"]


## Selective breeding: choose two parents (1); the steps in order (2); a herd's mean after some generations (3).
static func breed_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g: Array = _pick(rng, BREED_GOALS)
	var ex: Dictionary
	match level:
		1:
			var names := ["A", "B", "C", "D"]
			var scores := _some(rng, range(20, 61), 4)
			var rows: Array = [["parent", str(g[2])]]
			for k in 4:
				rows.append([names[k], str(scores[k])])
			var order: Array = range(4)
			order.sort_custom(func(a: int, b: int) -> bool: return int(scores[a]) > int(scores[b]))
			var best: Array = [names[order[0]], names[order[1]]]
			best.sort()
			var right := "%s and %s" % [best[0], best[1]]
			var wrongs: Array = []
			for pair: Array in [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]:
				var t := "%s and %s" % [names[pair[0]], names[pair[1]]]
				if t != right:
					wrongs.append(t)
			ex = K.choice(rng, "A breeder wants %s with %s. Which two should be the parents?" % [g[0], g[1]], right,
				_some(rng, wrongs, 3), "Look along the table for the two that show the trait most.",
				"%s and %s have the highest scores (%s and %s), so they are the parents." % [best[0], best[1],
				scores[names.find(best[0])], scores[names.find(best[1])]], {"kind": "table", "rows": rows})
			ex.data = {"scores": scores, "names": names}
		2:
			ex = K.order(rng, "A breeder wants %s with %s. Put the steps of selective breeding in order." % [g[0], g[1]],
				BREED_STEPS, "First decide what you want; the last step goes on for many generations.",
				"In order: %s." % ", then ".join(BREED_STEPS))
			ex.data = {"goal": g[0]}
		_:
			var start := rng.randi_range(10, 16) * 500
			var add: int = _pick(rng, [100, 150, 200, 250])
			var gens := rng.randi_range(2, 6)
			ex = K.number("In this example, a herd's cows give a mean of %s litres of milk a year. Each generation of selective breeding adds about %d litres. What is the mean after %d generations?"
				% [_t(start), add, gens], _a(start + add * gens), "Multiply the gain each generation by the generations, then add it on.",
				"%d × %d = %s litres more; %s + %s = %s litres." % [add, gens, _t(add * gens), _t(start), _t(add * gens),
				_t(start + add * gens)])
			ex.data = {"start": start, "add": add, "generations": gens}
	return ex


## Selective breeding or genetic engineering: one (1); sort six (2); a benefit or a question it raises (3).
static func gm_or_bred(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var bred := rng.randf() < 0.5
			var item: String = _pick(rng, BRED if bred else ENGINEERED)
			ex = K.choice(rng, "How were these made: %s?" % item, "by selective breeding" if bred else
				"by genetic engineering", ["by genetic engineering" if bred else "by selective breeding"],
				"Did people choose parents over generations, or move a gene from one living thing into another?",
				"%s: %s." % [_cap(item), "people chose parents over many generations" if bred else
				"a gene was moved into them from another living thing"])
			ex.data = {"item": item, "bred": bred}
		2:
			var n := rng.randi_range(2, 4)
			var items: Array = _some(rng, BRED, n) + _some(rng, ENGINEERED, 6 - n)
			K.shuffle(rng, items)
			var answer: Array = []
			for it: String in items:
				answer.append(0 if BRED.has(it) else 1)
			ex = {"type": "sort", "prompt": "Sort these: selective breeding or genetic engineering?",
				"groups": ["selective breeding", "genetic engineering"], "items": items, "answer": answer,
				"hint": "Breeding chooses parents; engineering moves a gene from one living thing to another.",
				"explain": "Bred by choosing parents over generations: %s. The others had a gene moved into them." % ", ".join(
					items.filter(func(x: String) -> bool: return BRED.has(x)))}
			ex.data = {"items": items}
		_:
			var n := rng.randi_range(2, 4)
			var items: Array = _some(rng, BENEFITS, n) + _some(rng, WORRIES, 6 - n)
			K.shuffle(rng, items)
			var answer: Array = []
			for it: String in items:
				answer.append(0 if BENEFITS.has(it) else 1)
			ex = {"type": "sort", "prompt": "Genetically modified (GM) crops: sort each point into a benefit or a worry people raise.",
				"groups": ["a benefit", "a worry or question"], "items": items, "answer": answer,
				"hint": "Does it say what GM crops could do for people, or what might go wrong or needs checking?",
				"explain": "Benefits: %s. Worries and questions: %s." % [", ".join(items.filter(func(x: String) -> bool:
					return BENEFITS.has(x))), ", ".join(items.filter(func(x: String) -> bool: return WORRIES.has(x)))]}
			ex.data = {"items": items}
	return ex


# --- English: the strongest evidence -----------------------------------------------------------------------------------

## [level, a passage (our own), a claim about it, the strongest words, weaker words, words that prove nothing].
const EVIDENCE: Array = [
	[1, "Kofi checked the knot three times before he let the boat drift out. The sea was calm and blue.",
		"Kofi is careful.", "“checked the knot three times”", "“he let the boat drift out”", "“The sea was calm and blue”"],
	[1, "Mei's hands shook as she stepped on stage. The hall was full, and the lights were hot.", "Mei is nervous.",
		"“Mei's hands shook”", "“she stepped on stage”", "“the lights were hot”"],
	[1, "The bakery opened at six, and by seven its queue reached the corner. Rain fell all morning.",
		"The bakery is popular.", "“its queue reached the corner”", "“The bakery opened at six”", "“Rain fell all morning”"],
	[2, "Zara read the instructions twice and laid out every part before she picked up the screwdriver.",
		"Zara works carefully.", "“read the instructions twice”", "“picked up the screwdriver”", "“Zara read”"],
	[2, "It was a grey Tuesday. The river had risen a metre overnight and swept the old bridge away.",
		"The flood was powerful.", "“swept the old bridge away”", "“The river had risen”", "“It was a grey Tuesday”"],
	[2, "Bram stayed after the match to fold every chair, though his friends had gone for pizza.",
		"Bram is helpful.", "“stayed after the match to fold every chair”", "“his friends had gone”", "“gone for pizza”"],
	[3, "Ana said she didn't care about the race. That night she polished her trainers until they shone.",
		"Ana cares about the race.", "“polished her trainers until they shone”", "“That night”",
		"“she didn't care about the race”"],
	[3, "Grandad never wound the broken watch, but he touched it in his pocket every morning for forty years.",
		"The watch matters to Grandad.", "“touched it in his pocket every morning”", "“never wound the broken watch”",
		"“in his pocket”"],
	[3, "The new boy ate his lunch by the bins. When the ball rolled to him, he kicked it back without looking up.",
		"The new boy feels shut out.", "“ate his lunch by the bins”", "“kicked it back”", "“When the ball rolled”"],
]
## [a short passage, [statements the text says], [statements a reader infers], [inferences it does not support]].
const READINGS: Array = [
	["Tilly wiped the flour off her hands, checked the oven again and set out six plates.",
		["Tilly set out six plates.", "Tilly checked the oven."], ["Tilly is expecting guests.", "Tilly has been baking."],
		["Tilly dislikes cooking.", "Tilly lives alone."]],
	["The cat stared at the fish tank all afternoon, its tail twitching.",
		["The cat stared at the tank.", "Its tail was twitching."], ["The cat wants the fish.", "The cat is alert."],
		["The cat is asleep.", "The tank is empty."]],
	["Rafi's phone buzzed again. He turned it face down and kept reading.",
		["Rafi's phone buzzed.", "Rafi kept reading."], ["Rafi wants to finish reading.", "The messages can wait."],
		["Rafi's phone is broken.", "Rafi is waiting for a call."]],
	["Snow lay smooth over the path, and there were no footprints yet.",
		["Snow lay over the path.", "There were no footprints."], ["Nobody has walked there since it snowed.",
		"It snowed not long ago."], ["It is summer.", "Many people walked by."]],
]


## The strongest evidence for a claim: clear (1); specific over vague (2); for an inference, where what a character does
## outweighs what they say (3).
static func evidence_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var e: Array = _pick(rng, EVIDENCE.filter(func(x: Array) -> bool: return int(x[0]) == level))
	var ex := K.choice(rng, "Read: “%s” Claim: %s Which words prove it best?" % [e[1], e[2]], e[3], [e[4], e[5]],
		"Which words are most directly about the claim, and hardest to read any other way?",
		"%s proves it most directly; %s says less about it, and %s does not prove it." % [e[3], e[4], e[5]])
	ex.data = {"claim": e[2]}
	return ex


## Explicit or inferred: one statement (1); sort four (2); the inference the text supports (3).
static func evidence_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var r: Array = _pick(rng, READINGS)
	var ex: Dictionary
	match level:
		1:
			var said := rng.randf() < 0.5
			var s: String = _pick(rng, r[1] if said else r[2])
			ex = K.choice(rng, "Read: “%s” Is “%s” said in the text, or inferred?" % [r[0], s.trim_suffix(".")],
				"said in the text (explicit)" if said else "inferred from clues", ["inferred from clues" if said else
				"said in the text (explicit)"], "Look for the same idea in the text's own words. If it is not there, you worked it out.",
				"“%s” is %s." % [s.trim_suffix("."), "in the text's own words: explicit" if said else
				"not said; the clues lead to it: an inference"])
			ex.data = {"statement": s, "said": said}
		2:
			var items: Array = (r[1] as Array) + (r[2] as Array)
			K.shuffle(rng, items)
			var answer: Array = []
			for it: String in items:
				answer.append(0 if (r[1] as Array).has(it) else 1)
			ex = {"type": "sort", "prompt": "Read: “%s” Sort the statements." % r[0], "groups": ["said (explicit)",
				"inferred"], "items": items, "answer": answer,
				"hint": "Find each one in the text's own words; if you had to work it out, it is inferred.",
				"explain": "Said: %s Inferred: %s" % [" ".join(r[1]), " ".join(r[2])]}
			ex.data = {"passage": r[0]}
		_:
			var right: String = _pick(rng, r[2])
			ex = K.choice(rng, "Read: “%s” Which inference does the text support best?" % r[0], right, r[3],
				"Check each one against the clues: which one do the details point to?",
				"The details point to “%s”; nothing in the text supports the others." % right.trim_suffix("."))
			ex.data = {"passage": r[0], "right": right}
	return ex


# --- English: old stories, new versions ----------------------------------------------------------------------------------

const OLD_STORIES: Array[String] = ["The Boy Who Cried Wolf", "The Tortoise and the Hare", "King Midas", "Icarus",
	"Cinderella", "Pandora's box", "Romeo and Juliet", "the Odyssey", "Frankenstein"]
## [level, a new story of our own, the older story it draws on].
const NEW_VERSIONS: Array = [
	[1, "Jo keeps posting fake alerts in her class chat for fun. When she finds a real problem, nobody believes her.",
		"The Boy Who Cried Wolf"],
	[1, "A fast, boastful robot stops to show off during a race, and a slow, steady robot rolls past to win.",
		"The Tortoise and the Hare"],
	[1, "A boy wishes everything he touches would turn to gold, then cannot eat his dinner or hug his sister.",
		"King Midas"],
	[2, "Ignoring her teacher's warning, a girl flies her new drone higher and higher to beat a record, until it overheats and falls.",
		"Icarus"],
	[2, "Lina's stepfamily treat her like a servant. A kind old engineer helps her finish a robot for the fair, but she must leave by midnight.",
		"Cinderella"],
	[2, "A curious boy opens the one box his grandmother told him never to touch. Troubles fly out over the town; only hope stays inside.",
		"Pandora's box"],
	[3, "Two rival bakers' children fall in love. A lost message leads to a sad mistake, which at last makes the families make peace.",
		"Romeo and Juliet"],
	[3, "After ten years fighting far from home, a space captain struggles to get back, while strangers try to take over her house.",
		"the Odyssey"],
	[3, "A scientist builds a living robot, then turns away from it. Rejected and angry, it turns on its maker.", "Frankenstein"],
]
## [character, archetype].
const ARCHETYPES: Array[String] = ["trickster", "mentor", "hero", "monster"]
const CHARACTERS: Array = [["Anansi the spider", "trickster", "wins by clever tricks, not strength"],
	["Br'er Rabbit", "trickster", "talks his way out of trouble"], ["Merlin", "mentor", "teaches young Arthur"],
	["Athena", "mentor", "guides Odysseus with advice"], ["Theseus", "hero", "goes into the labyrinth to save others"],
	["Hua Mulan", "hero", "takes her father's place to protect him"], ["the Minotaur", "monster", "lurks in the labyrinth"],
	["Medusa", "monster", "turns people to stone with a look"]]
const NEW_CHARACTERS: Array = [["Grandma Ifeoma, who teaches Kai to sail and gives him her compass", "mentor"],
	["Pip, a market boy who fools a greedy merchant with a riddle", "trickster"],
	["the giant robot that guards the only bridge and attacks travellers", "monster"],
	["Sami, who leaves home to bring medicine back to her village", "hero"],
	["old Mr Okafor, who shows Lina how to solder and says she can do it", "mentor"],
	["Nell, who swaps the labels so the bullies eat the sour sweets", "trickster"]]


## Which older story a new one draws on: fables (1); myths and fairy tales (2); older works (3).
static func story_pattern(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var v: Array = _pick(rng, NEW_VERSIONS.filter(func(x: Array) -> bool: return int(x[0]) == level))
	var wrongs: Array = _some(rng, OLD_STORIES.filter(func(s: String) -> bool: return s != v[2]), 3)
	var ex := K.choice(rng, "%s Which older story does this draw on?" % v[1], v[2], wrongs,
		"Look past the new setting: which older story has the same pattern of events?",
		"It keeps the pattern of %s and changes the setting and the people." % v[2])
	ex.data = {"story": v[1], "old": v[2]}
	return ex


## Archetypes: name a character's type (1); match four (2); the type of a character in a new story (3).
static func archetype_match(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = _pick(rng, CHARACTERS)
			ex = K.choice(rng, "In old stories, %s %s. Which type of character is this?" % [c[0], c[2]], c[1], ARCHETYPES,
				"Think about the job the character does in the story: tricking, teaching, saving or threatening.",
				"%s %s: a %s." % [_cap(str(c[0])), c[2], c[1]])
			ex.data = {"character": c[0]}
		2:
			var picks: Array = []
			for t: String in ARCHETYPES:
				picks.append(_pick(rng, CHARACTERS.filter(func(x: Array) -> bool: return x[1] == t)))
			var matches: Array = ARCHETYPES.duplicate()
			for _t in 20:
				K.shuffle(rng, matches)
				if range(4).all(func(i: int) -> bool: return matches[i] != picks[i][1]):
					break
			var answer: Array = []
			for p: Array in picks:
				answer.append(matches.find(p[1]))
			ex = {"type": "match", "prompt": "Match each character from old stories to its type.",
				"items": picks.map(func(p: Array) -> String: return p[0]), "matches": matches, "answer": answer,
				"hint": "Ask what each one does in their story: tricks, teaches, saves or threatens.",
				"explain": "; ".join(picks.map(func(p: Array) -> String: return "%s: %s" % [p[0], p[1]])) + "."}
			ex.data = {"characters": picks.map(func(p: Array) -> String: return p[0])}
		_:
			var c: Array = _pick(rng, NEW_CHARACTERS)
			ex = K.choice(rng, "In a new story: %s. Which old character type is this?" % c[0], c[1], ARCHETYPES,
				"Match what the character does to a type: tricking, teaching, saving or threatening.",
				"This character plays the old part of the %s, in a new setting." % c[1])
			ex.data = {"character": c[0]}
	return ex


# --- English: argue like a pro --------------------------------------------------------------------------------------------

## Arguments: [claim, counterclaim, rebuttal, evidence, conclusion].
const ARGUMENTS: Array = [
	["Our school should start a garden.", "Some say a garden takes too much time.",
		"However, a rota needs only an hour a week.", "80% of pupils said they would help.",
		"So let us start digging this spring."],
	["Lunch break should be longer.", "Some argue it would make home time later.",
		"Yet registration could be shorter instead.", "Active pupils focus better after lunch.",
		"A longer lunch would help everyone learn."],
	["The library should open on Saturdays.", "Admittedly, staff would need extra pay.",
		"Even so, volunteers could run it.", "300 people signed a petition for it.",
		"Saturday opening would serve the whole town."],
	["Our town needs safe cycle lanes.", "Some say cycle lanes slow down traffic.",
		"However, fewer cars can mean less traffic.", "More children cycle where lanes are safe.",
		"Safe lanes would make our town healthier."],
	["The school field needs more trees.", "It is true that trees take up space.",
		"But trees round the edge leave room to play.", "Trees cool a playground on hot days.",
		"Let us plant trees round the field this year."],
]
const PARTS_OF: Array[String] = ["the claim", "a counterclaim", "a rebuttal", "evidence", "a conclusion"]
## [what to find out, the most credible source, less credible sources].
const SOURCES: Array = [
	["how much sleep teenagers need", "a national health service's guidance",
		["an advert for a mattress", "a post by an unnamed account", "a friend's guess"]],
	["whether a new medicine works", "a published study of many patients",
		["the maker's advert", "a video by a stranger", "one person's story"]],
	["how fast the sea level is rising", "a national science agency's report",
		["a blog with no author", "a holiday company's leaflet", "a comment under a video"]],
	["the number of people living in a city", "the national statistics office",
		["a quiz website", "a tourist poster", "a rumour in class"]],
	["whether a snack is healthy", "a health body's advice and the label",
		["the snack's advert", "a famous person's post", "the cartoon on the packet"]],
]
const SOURCE_CHECKS: Array = [["Who wrote it, and what do they know?", ["How long is it?", "How nice does it look?",
	"How many likes does it have?"]], ["Can I find the same fact in another good source?", ["Is it in bold?",
	"Was it the first result?", "Does it agree with me?"]], ["Could the writer gain from what they say?",
	["Is the font easy to read?", "Is it short?", "Does it have pictures?"]]]
## [informal, formal, other informal versions].
const FORMAL: Array = [
	[1, "Loads of kids think the canteen food is rubbish.", "Many pupils are unhappy with the canteen food.",
		["Loads of pupils think the food is rubbish.", "The canteen food is, like, really bad."]],
	[1, "You'd be mad not to recycle.", "Recycling is a sensible choice for everyone.",
		["Only mad people don't recycle!", "Recycling is, like, the best thing ever."]],
	[2, "Phones in class are a total nightmare.", "Phones in class can distract pupils.",
		["Phones in class are a nightmare, honestly.", "Phones in class are totally the worst."]],
	[2, "The new park is awesome and everyone loves it.", "The new park is popular with many residents.",
		["Everyone loves the awesome new park.", "The new park is well cool."]],
	[3, "Homework is a massive waste of time, if you ask me.", "Too much homework may not help pupils learn.",
		["If you ask me, homework is pointless.", "Homework is a waste of time, obviously."]],
	[3, "Kids these days never go outside.", "Many young people now spend less time outdoors.",
		["Young people never ever go outside now.", "Kids are always inside, it's crazy."]],
]


## An argument's parts: name one (1); sort two arguments' claims, counterclaims and rebuttals (2); put one in order (3).
static func argument_part(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var a: Array = _pick(rng, ARGUMENTS)
			var k := rng.randi_range(1, 3)
			ex = K.choice(rng, "An argument claims: “%s” What part of it is this sentence: “%s”?" % [a[0], a[k]],
				PARTS_OF[k], PARTS_OF.slice(0, 4),
				"Does it say what you argue, what the other side says, your answer to them, or a fact that backs you up?",
				"“%s” is %s." % [a[k], PARTS_OF[k]])
			ex.data = {"argument": a[0], "part": k}
		2:
			var two := _some(rng, ARGUMENTS, 2)
			var items: Array = []
			var answer_of := {}
			for a: Array in two:
				for k in 3:
					items.append(a[k])
					answer_of[a[k]] = k
			K.shuffle(rng, items)
			ex = {"type": "sort", "prompt": "These sentences come from two arguments. Sort them.", "groups": ["claim",
				"counterclaim", "rebuttal"], "items": items, "answer": items.map(func(it: String) -> int:
					return int(answer_of[it])),
				"hint": "Signal words help: “Some say” or “Admittedly” bring in the other side; “However” or “Yet” answers it.",
				"explain": "The claims: “%s” and “%s”. Counterclaims begin “Some say”, “Admittedly” or “It is true”; rebuttals answer them with “However”, “Yet”, “Even so” or “But”." % [
					str(two[0][0]).trim_suffix("."), str(two[1][0]).trim_suffix(".")]}
			ex.data = {"arguments": [two[0][0], two[1][0]]}
		_:
			var a: Array = _pick(rng, ARGUMENTS)
			var steps := [a[0], a[3], a[1], a[2], a[4]]
			ex = K.order(rng, "Put this argument in a strong order.", steps,
				"State the claim and back it up first; then bring in the other side, answer it, and end strongly.",
				"The claim first (“%s”), then its evidence, the counterclaim, your rebuttal, and the conclusion last." %
				str(a[0]).trim_suffix("."))
			ex.data = {"argument": a[0]}
	return ex


## Credible sources: the most trustworthy (1); the least (2); the question that best checks a source (3).
static func credible_source(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1, 2:
			var s: Array = _pick(rng, SOURCES)
			var weak: Array = s[2]
			if level == 1:
				ex = K.choice(rng, "You want evidence about %s. Which source is most trustworthy?" % s[0], s[1], weak,
					"Who knows most about it, checks their facts, and gains nothing from what you believe?",
					"%s: experts who check their facts. The others may guess, or gain from it." % _cap(str(s[1])))
			else:
				var worst: String = _pick(rng, weak)
				var others: Array = [s[1]] + weak.filter(func(w: String) -> bool: return w != worst).slice(0, 1)
				ex = K.choice(rng, "Evidence about %s: which of these would you trust least?" % s[0], worst, others,
					"Ask who made it, what they know, and whether they gain from it.",
					"%s: it may not check its facts, or it gains from what people believe." % _cap(worst))
			ex.data = {"topic": s[0]}
		_:
			var c: Array = _pick(rng, SOURCE_CHECKS)
			ex = K.choice(rng, "Which question tells you most about whether a source can be trusted?", c[0], c[1],
				"Think about who stands behind the facts, not how the page looks.",
				"“%s” is about the facts and who stands behind them; the others are about looks or luck." % c[0])
			ex.data = {"check": c[0]}
	return ex


## Formal style: the formal version of a sentence (levels 1-3: plainer to subtler).
static func formal_style(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f: Array = _pick(rng, FORMAL.filter(func(x: Array) -> bool: return int(x[0]) == level))
	var ex := K.choice(rng, "An argument for a council says: “%s” Which is the best formal version?" % f[1], f[2], f[3],
		"Formal writing drops slang, exaggeration and chatty words, and stays calm and exact.",
		"“%s” keeps the point without slang or exaggeration." % f[2])
	ex.data = {"informal": f[1]}
	return ex


# --- English: explain complex ideas --------------------------------------------------------------------------------------

## [information, the graphic that shows it best, the information in 32 letters or fewer (to match)].
const GRAPHICS: Array = [["the steps of the water cycle", "a cycle diagram", "the water cycle's steps"],
	["the parts of a volcano", "a labelled diagram", "a volcano's parts"],
	["rainfall in each month of a year", "a bar chart", "rainfall each month"],
	["how a town's population grew since 1900", "a line graph", "a town's population since 1900"],
	["three planets' sizes, moons and days", "a table", "three planets compared"],
	["where the world's rainforests are", "a map", "where rainforests are"],
	["a voyage's events, in order of date", "a timeline", "a voyage's events by date"],
	["the share of each gas in the air", "a pie chart", "each gas's share of the air"],
	["how to make paper, step by step", "a flowchart", "making paper, step by step"]]
## [level, a sentence with a gap, the precise word, vague words].
const PRECISE: Array = [
	[1, "When water is heated, it ___ into the air.", "evaporates", ["goes", "gets"]],
	[1, "The heart ___ blood around the body.", "pumps", ["moves", "does"]],
	[1, "A magnet ___ iron nails.", "attracts", ["gets", "likes"]],
	[1, "In autumn, many trees ___ their leaves.", "shed", ["lose out", "do"]],
	[2, "Water vapour ___ into droplets on a cold window.", "condenses", ["turns", "goes back"]],
	[2, "The Moon ___ the Earth about once a month.", "orbits", ["goes around", "moves near"]],
	[2, "Green plants make sugar by ___.", "photosynthesis", ["eating", "growing"]],
	[3, "Wind and waves slowly ___ the cliff.", "erode", ["hurt", "change"]],
	[3, "The volcano ___ ash high into the sky.", "ejected", ["put", "did"]],
	[3, "A bridge's cables carry the deck's ___ to the towers.", "load", ["stuff", "things"]],
]
const DEFINED: Array = [["erosion", "Erosion (rock being worn away) shapes coasts.",
	["Erosion is a thing that happens.", "Erosion is very interesting."]], ["a predator",
	"A predator (an animal that hunts) needs speed.", ["A predator is quite a big deal.",
	"Predators are in lots of places."]], ["condensation", "Condensation (gas turning to liquid) wets glass.",
	["Condensation is something with water.", "Condensation is a long word."]], ["a circuit",
	"A circuit (a complete loop) lets current flow.", ["A circuit is in many machines.",
	"Circuits are electrical and stuff."]]]


## Graphics for information: the right one (1); match four (2); between graphics that look alike (3).
static func graphic_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var kinds: Array = GRAPHICS.map(func(g: Array) -> String: return g[1])
	match level:
		1, 3:
			var g: Array = _pick(rng, GRAPHICS)
			var wrongs: Array = []
			if level == 3:
				var close := {"a bar chart": ["a line graph", "a pie chart", "a table"], "a line graph": ["a bar chart",
					"a table", "a pie chart"], "a pie chart": ["a bar chart", "a table", "a line graph"], "a table": ["a bar chart",
					"a labelled diagram", "a map"], "a cycle diagram": ["a flowchart", "a timeline", "a table"], "a flowchart": [
					"a cycle diagram", "a timeline", "a labelled diagram"], "a timeline": ["a flowchart", "a line graph",
					"a table"], "a map": ["a labelled diagram", "a table", "a pie chart"], "a labelled diagram": ["a map",
					"a flowchart", "a table"]}
				wrongs = close[g[1]]
			else:
				wrongs = _some(rng, kinds.filter(func(k: String) -> bool: return k != g[1]), 3)
			ex = K.choice(rng, "An explanation includes %s. Which graphic shows it best?" % g[0], g[1], wrongs,
				"What shape is the information: steps, parts, amounts, change over time, places, or comparisons?",
				"%s suits %s." % [_cap(str(g[1])), g[0]])
			ex.data = {"info": g[0]}
		_:
			var picks := _some(rng, GRAPHICS, 4)
			var matches: Array = picks.map(func(g: Array) -> String: return g[1])
			var shown := matches.duplicate()
			for _t in 20:
				K.shuffle(rng, shown)
				if range(4).all(func(i: int) -> bool: return shown[i] != matches[i]):
					break
			var answer: Array = []
			for m: String in matches:
				answer.append(shown.find(m))
			ex = {"type": "match", "prompt": "Match each kind of information to the graphic that shows it best.",
				"items": picks.map(func(g: Array) -> String: return g[2]), "matches": shown,
				"answer": answer, "hint": "Steps want arrows, amounts want bars, change over time wants a line, places want a map.",
				"explain": _cap("; ".join(picks.map(func(g: Array) -> String: return "%s: %s" % [g[2], g[1]])) + ".")}
			ex.data = {"infos": picks.map(func(g: Array) -> String: return g[0])}
	return ex


## Precise words: fill a gap (1-2); a term defined for the reader (3, or a harder gap).
static func precise_word(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.5:
		var d: Array = _pick(rng, DEFINED)
		ex = K.choice(rng, "Which sentence defines %s for a reader who does not know the word?" % d[0], d[1], d[2],
			"A definition says exactly what the word means, the first time it is used.",
			"“%s” tells the reader what %s means." % [d[1], d[0]])
		ex.data = {"term": d[0]}
		return ex
	var p: Array = _pick(rng, PRECISE.filter(func(x: Array) -> bool: return int(x[0]) == level))
	ex = K.choice(rng, "Which word is the most precise in this explanation? “%s”" % p[1], p[2], p[3],
		"Choose the exact word a scientist or an expert would use, not an everyday one.",
		"“%s” is exact: %s" % [p[2], str(p[1]).replace("___", p[2])])
	ex.data = {"sentence": p[1]}
	return ex


# --- English: craft a narrative --------------------------------------------------------------------------------------------

## Stories told with a flashback: [the opening line (its last event), events in time order].
const FLASHBACKS: Array = [
	["Mo held the medal up high.", ["Mo starts training for the race", "Mo falls and hurts his knee",
		"Mo's knee slowly heals", "Mo trains again, harder", "Mo crosses the finish line", "Mo holds up the medal"]],
	["Nobody believed Ana's story about the cove.", ["Ana finds an old map in the attic", "Ana and Kofi set off",
		"a storm traps them in a cave", "they find the hidden cove", "the coastguard finds them",
		"Ana tells the story at school"]],
	["Kai sat in the old oak's shade, remembering.", ["Great-grandad plants an acorn", "the oak grows taller than the house",
		"a storm breaks a branch", "the family mends the tree", "Kai sits in its shade"]],
	["Zara and Mei laughed as they glued the last piece.", ["Zara breaks Mei's model by accident",
		"Zara hides what she did", "Mei gets the blame", "Zara tells the truth", "the girls fix the model together"]],
]
## [a feeling or trait, telling words, a telling detail that shows it, other telling words].
const SHOW_TELL: Array = [
	["nervous", "Tilly's hands shook as she held the card.", ["Tilly was very nervous.", "Tilly felt nervous about it."]],
	["proud", "Bram hung his certificate right by the door.", ["Bram was proud of himself.",
		"Bram felt really proud."]],
	["tired", "Mei's eyes closed before the bus left the stop.", ["Mei was very tired.", "Mei felt tired out."]],
	["cold", "Kofi stamped his feet and blew on his fingers.", ["Kofi was cold.", "It was very cold for Kofi."]],
	["excited", "Rafi ran to the door at every sound.", ["Rafi was excited.", "Rafi felt so excited."]],
	["kind", "Zara gave her umbrella to the man in the rain.", ["Zara was a kind person.", "Zara is very kind."]],
]
const REFLECTIONS: Array = [["Losing taught me more than winning ever did.", ["Then we went home for tea.",
	"The race was on a Tuesday."]], ["Only later did I see how that day changed me.", ["The bus came at four.",
	"It was cloudy that day."]], ["Now I see that asking for help was brave.", ["We all sat down.",
	"Mum made pasta that night."]]]
## [the shift, the words that signal it, other words].
const SHIFTS: Array = [["a jump back in time (a flashback)", "Three summers earlier,", ["Meanwhile,", "Next,"]],
	["two things happening at the same time", "Meanwhile,", ["Years later,", "Before that,"]],
	["a jump forward in time", "Years later,", ["Meanwhile,", "Long ago,"]],
	["a return to the present after a flashback", "Now, back on the cliff,", ["Three summers earlier,", "Meanwhile,"]],
	["a move to a new place", "Across town,", ["Later that day,", "Before then,"]]]
const FLASH_VERBS: Array = [["She had never seen the sea before that day.", ["She never sees the sea.",
	"She will see the sea one day."]], ["He had trained for months before the race.", ["He trains for the race.",
	"He is going to train hard."]], ["They had lived by the river once.", ["They live by the river.",
	"They will live by the river."]]]


## Time order: put a flashback story's events in the order they happened: 4 events (1), 5 (2), 6 (3).
static func time_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := level + 3
	var s: Array = _pick(rng, FLASHBACKS.filter(func(x: Array) -> bool: return (x[1] as Array).size() >= n))
	var events: Array = s[1]
	var keep: Array = [events.size() - 1]
	var rest: Array = range(events.size() - 1)
	K.shuffle(rng, rest)
	keep.append_array(rest.slice(0, n - 1))
	keep.sort()
	var steps: Array = keep.map(func(i: int) -> String: return events[i])
	var ex := K.order(rng, "A story opens: “%s” Then it flashes back. Put these events in the order they happened." % s[0],
		steps, "The opening is the end of the story. Find the earliest event, then follow what each one leads to.",
		"In time order: %s." % "; ".join(steps))
	ex.data = {"opening": s[0], "keep": keep}
	return ex


## Telling details: the sentence that shows a feeling (1); sort showing from telling (2); a reflection (3).
static func telling_detail(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var t: Array = _pick(rng, SHOW_TELL)
			ex = K.choice(rng, "Which sentence shows that someone is %s, without saying the word?" % t[0], t[1], t[2],
				"Look for an action or a detail you could picture, not a feeling word.",
				"“%s” lets the reader see it: the reader works out the feeling." % t[1])
			ex.data = {"feeling": t[0]}
		2:
			var picks := _some(rng, SHOW_TELL, 3)
			var items: Array = []
			var answer_of := {}
			for t: Array in picks:
				items.append(t[1])
				answer_of[t[1]] = 0
				var told: String = _pick(rng, t[2])
				items.append(told)
				answer_of[told] = 1
			K.shuffle(rng, items)
			ex = {"type": "sort", "prompt": "Sort the sentences: do they show the feeling, or just tell it?",
				"groups": ["shows", "tells"], "items": items, "answer": items.map(func(it: String) -> int:
					return int(answer_of[it])),
				"hint": "A sentence that names the feeling tells it; a detail you can picture shows it.",
				"explain": "The details you can picture show the feeling; the sentences that name it tell it: %s" % " ".join(
					items.filter(func(it: String) -> bool: return answer_of[it] == 1))}
			ex.data = {"feelings": picks.map(func(t: Array) -> String: return t[0])}
		_:
			var r: Array = _pick(rng, REFLECTIONS)
			ex = K.choice(rng, "Which sentence would make a story's ending reflective?", r[0], r[1],
				"A reflection thinks about what the events meant, not what happened next.",
				"“%s” looks back and says what it meant." % r[0])
			ex.data = {"reflection": r[0]}
	return ex


## Signals of a shift in time and place: a flashback's or the present's (1); any shift (2); the tense that slides into a
## flashback (3).
static func shift_signal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var f: Array = _pick(rng, FLASH_VERBS)
		ex = K.choice(rng, "A story is told in the past tense. Which sentence slides into a flashback, further back in time?",
			f[0], f[1], "A flashback inside a past-tense story uses “had” with the verb.",
			"“%s” uses “had”, so it reaches further back than the story's past." % f[0])
		ex.data = {"sentence": f[0]}
		return ex
	var pool: Array = SHIFTS.slice(0, 1) + SHIFTS.slice(3, 4) if level == 1 else SHIFTS
	var s: Array = _pick(rng, pool)
	ex = K.choice(rng, "Which words signal %s?" % s[0], s[1], s[2],
		"Think about where in time or place each phrase moves the reader.",
		"“%s” signals %s." % [s[1], s[0]])
	ex.data = {"shift": s[0]}
	return ex


# --- English: present with multimedia ----------------------------------------------------------------------------------------

## [a point in a talk, the media that supports it best, the point in 32 letters or fewer (to match)].
const MEDIA: Array = [["how a volcano erupts", "a short video clip", "a volcano erupting"],
	["how pupils travel to school", "a bar chart", "how pupils travel to school"],
	["where the new park will be", "a map", "where the new park will be"],
	["what the old harbour looked like", "an old photograph", "the old harbour, long ago"],
	["how a blackbird's song sounds", "a sound recording", "a blackbird's song"],
	["how the temperature changed over a year", "a line graph", "a year's temperatures"],
	["the steps to make compost", "a flowchart", "making compost, step by step"]]
const DISTRACTIONS: Array[String] = ["loud music under your voice", "a spinning animated title",
	"a slide full of small text", "a joke picture with no link"]
const SLIDE_GOOD: Array[String] = ["a short title", "big, clear text", "one chart that makes the point", "key words only",
	"credit for a photo", "one idea a slide"]
const SLIDE_BAD: Array[String] = ["your whole script on it", "tiny text", "clashing colours", "spinning effects",
	"five pictures at once", "a different font each line"]
const TALKS: Array = [["Plastic on our beach", ["Most litter is plastic", "It harms sea birds", "Some of it is very small",
	"Nets and ropes last for years", "Bottle tops are common"]], ["Why bees matter", ["Bees carry pollen",
	"Many crops need them", "Wild flowers help bees", "Bees need clean water", "Some bees live alone"]],
	["Saving energy at home", ["Switch off at the wall", "Use LED bulbs", "Boil only what you need",
	"Take shorter showers", "Wash clothes at 30 degrees"]]]


## Media for a talk: the media that fits a point (1); match four (2); what would distract (3).
static func media_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var kinds: Array = MEDIA.map(func(m: Array) -> String: return m[1])
	match level:
		1:
			var m: Array = _pick(rng, MEDIA)
			ex = K.choice(rng, "In your talk you explain %s. Which media would help most?" % m[0], m[1],
				_some(rng, kinds.filter(func(k: String) -> bool: return k != m[1]), 3),
				"Ask what the audience needs to see or hear to understand this point.",
				"%s shows %s better than words alone." % [_cap(str(m[1])), m[0]])
			ex.data = {"point": m[0]}
		2:
			var picks := _some(rng, MEDIA, 4)
			var matches: Array = picks.map(func(m: Array) -> String: return m[1])
			var shown := matches.duplicate()
			for _t in 20:
				K.shuffle(rng, shown)
				if range(4).all(func(i: int) -> bool: return shown[i] != matches[i]):
					break
			var answer: Array = []
			for m: String in matches:
				answer.append(shown.find(m))
			ex = {"type": "match", "prompt": "Match each point in a talk to the media that supports it best.",
				"items": picks.map(func(m: Array) -> String: return m[2]), "matches": shown,
				"answer": answer, "hint": "Numbers want charts, places want maps, sounds want a recording, a process wants moving pictures or steps.",
				"explain": _cap("; ".join(picks.map(func(m: Array) -> String: return "%s: %s" % [m[2], m[1]])) + ".")}
			ex.data = {"points": picks.map(func(m: Array) -> String: return m[0])}
		_:
			var bad: String = _pick(rng, DISTRACTIONS)
			ex = K.choice(rng, "A talk about how pupils travel to school. Which of these would distract from the point?", bad,
				["a bar chart of how pupils travel", "a map of the safe routes", "a photo of the bike shed"],
				"Media should make the point clearer; anything that pulls eyes or ears away from it distracts.",
				"%s pulls attention away from the point; the others make it clearer." % _cap(bad))
			ex.data = {"distraction": bad}
	return ex


## A slide feature's group: 0 helps the audience, 1 distracts them.
static func _good_or_bad(it: String) -> int:
	return 0 if SLIDE_GOOD.has(it) else 1


## Slides: a good habit (1); sort what helps from what distracts (2); improve a crammed slide (3).
static func slide_rule(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var good: String = _pick(rng, SLIDE_GOOD)
			ex = K.choice(rng, "Which of these makes a slide easier for the audience?", good, _some(rng, SLIDE_BAD, 3),
				"The audience should be able to read it at a glance and then listen to you.",
				"%s helps the audience; the others make them read instead of listen." % _cap(good))
			ex.data = {"good": good}
		2:
			var n := rng.randi_range(2, 4)
			var items: Array = _some(rng, SLIDE_GOOD, n) + _some(rng, SLIDE_BAD, 6 - n)
			K.shuffle(rng, items)
			ex = {"type": "sort", "prompt": "Sort these features of slides.", "groups": ["helps the audience",
				"distracts them"], "items": items, "answer": items.map(_good_or_bad),
				"hint": "Could the audience take it in at a glance and keep listening to you?",
				"explain": "Helps: %s. Distracts: %s." % [", ".join(items.filter(func(it: String) -> bool:
					return SLIDE_GOOD.has(it))), ", ".join(items.filter(func(it: String) -> bool: return SLIDE_BAD.has(it)))]}
			ex.data = {"items": items}
		_:
			var t: Array = _pick(rng, TALKS)
			var pic := {"kind": "slide_design", "title": t[0], "bullets": t[1], "busy": true}
			ex = K.choice(rng, "What would improve this slide the most?", "cut it to a few key words, in big text",
				["add more colours and effects", "read every line out loud", "make the text smaller to fit more"],
				"What stops the audience reading it at a glance?",
				"It is crammed with small text in clashing colours: cut it to a few key words in big, clear text, and say the rest.",
				pic)
			ex.data = {"title": t[0]}
	return ex
