extends GutTest
## Owner #68, grade 7 maths (G7NumberGen "g7n", G7GeometryGen "g7g"): each generator's answer is worked out again here
## from the exercise's `data`, for many seeds and every level, and every exercise must be valid (ExerciseCheck).
## Fractions are [top, bottom] and circles are in hundredths, so nothing goes through floats.

const SEEDS := 80


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			check.call(ex, level)


func _is(ex: Dictionary, num: int, den: int = 1) -> bool:
	var text := str(ex.answer) if str(ex.type) == "number" else ExerciseCheck.answer_text(ex)
	if den < 0:
		num = -num
		den = -den
	var g := NumberAnswer.gcd(absi(num), den)
	return NumberAnswer.equal(text, "%d/%d" % [num / g, den / g])


func _signed(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


# --- g7n ------------------------------------------------------------------------------------------------------------------

func test_proportional_relationships() -> void:
	_each("g7n.unit_rate_fraction", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.a) * int(d.d), int(d.b) * int(d.c)), str(ex.prompt)))
	_each("g7n.is_proportional", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ex.answer, int(ex.data.c) == 0, str(ex.prompt)))
	_each("g7n.constant_k", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.k10), 10), str(ex.prompt)))


func test_percent_problems() -> void:
	_each("g7n.percent_change", func(ex: Dictionary, _l: int) -> void:
		var old := int(ex.data.old)
		var now := int(ex.data.now)
		assert_true(_is(ex, absi(now - old) * 100, old), str(ex.prompt)))
	_each("g7n.discount_tax", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var n := int(d.n)
		var p := int(d.p)
		if d.kind == "discount":
			assert_true(_is(ex, n * (100 - p), 100), str(ex.prompt))
		elif d.kind == "tax":
			assert_true(_is(ex, n * (100 + p), 100), str(ex.prompt))
		else:
			assert_true(_is(ex, n * p * int(d.years), 100), str(ex.prompt)))


func test_integers() -> void:
	_each("g7n.add_integers", func(ex: Dictionary, _l: int) -> void:
		var terms: Array = ex.data.terms
		var total := int(terms[0])
		for i in (ex.data.ops as Array).size():
			total += int(terms[i + 1]) if ex.data.ops[i] == "+" else -int(terms[i + 1])
		assert_true(_is(ex, total), str(ex.prompt)))
	_each("g7n.multiply_integers", func(ex: Dictionary, _l: int) -> void:
		var f: Array = ex.data.factors
		if ex.data.op == "÷":
			assert_true(_is(ex, int(f[0])), str(ex.prompt))
		else:
			var p := 1
			for v: int in f:
				p *= v
			assert_true(_is(ex, p), str(ex.prompt)))


func test_rational_numbers() -> void:
	_each("g7n.frac_decimal", func(ex: Dictionary, level: int) -> void:
		var n := int(ex.data.n)
		var d := int(ex.data.d)
		if level == 2:
			var m := d
			while m % 2 == 0:
				m /= 2
			while m % 5 == 0:
				m /= 5
			assert_eq(ExerciseCheck.answer_text(ex), "it ends" if m == 1 else "it repeats", str(ex.prompt))
		else:
			assert_true(_is(ex, n, d), str(ex.prompt)))
	_each("g7n.rational_ops", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		var c := int(d.c)
		var e := int(d.d)
		if d.op == "+":
			assert_true(_is(ex, a * e + c * b, b * e), str(ex.prompt))
		elif d.op == "−":
			assert_true(_is(ex, a * e - c * b, b * e), str(ex.prompt))
		elif d.op == "×":
			assert_true(_is(ex, a * c, b * e), str(ex.prompt))
		else:
			assert_true(_is(ex, a * e, b * c), str(ex.prompt)))


func test_expressions_equations_inequalities() -> void:
	_each("g7n.expand_simplify", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		var c := int(d.c)
		var bx := "" if b == 1 else str(b)
		if level < 3:
			assert_eq(ExerciseCheck.answer_text(ex), "%dx − %d" % [a * b + int(d.e), a * c], str(ex.prompt))
		else:
			assert_eq(NumberAnswer.gcd(b, c), 1, "the factor outside is the greatest")
			assert_eq(ExerciseCheck.answer_text(ex), "%d(%sx + %d)" % [a, bx, c], str(ex.prompt)))
	_each("g7n.two_step", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		var x := int(d.x)
		var rhs := 0
		if d.form == "ax+b":
			rhs = a * x + b
		elif d.form == "x/a-b":
			assert_eq(x % a, 0, "x ÷ a is whole")
			rhs = x / a - b
		else:
			rhs = -a * x + b
		assert_true(str(ex.prompt).contains("= %s." % _signed(rhs)), "%s: the right side" % ex.prompt)
		assert_true(_is(ex, x), str(ex.prompt)))
	_each("g7n.solve_inequality", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var op := str(d.op)
		var flip := {">": "<", "<": ">", "≥": "≤", "≤": "≥"}
		var want := "x %s %s" % [flip[op] if d.negative else op, _signed(int(d.x))]
		assert_eq(ExerciseCheck.answer_text(ex), want, str(ex.prompt)))


# --- g7g ------------------------------------------------------------------------------------------------------------------

func test_scale_drawings() -> void:
	_each("g7g.scale_length", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var k := int(d.k)
		if d.ask == "real":
			assert_true(_is(ex, int(d.d) * k))
		elif d.ask == "drawing":
			assert_true(_is(ex, int(d.d)))
		else:
			assert_true(_is(ex, int(d.d) * k * int(d.w) * k)))


func test_triangles_and_slices() -> void:
	_each("g7g.triangle_possible", func(ex: Dictionary, _l: int) -> void:
		var s: Array = ex.data.sides
		var a := int(s[0])
		var b := int(s[1])
		var c := int(s[2])
		assert_eq(ex.answer, a + b > c and a + c > b and b + c > a, str(ex.prompt)))
	_each("g7g.third_angle", func(ex: Dictionary, level: int) -> void:
		if level < 3:
			var third := 180 - int(ex.data.a) - int(ex.data.b)
			assert_gt(third, 0, "a real triangle")
			assert_true(_is(ex, third), str(ex.prompt))
		else:
			assert_eq(ExerciseCheck.answer_text(ex), str(G7GeometryGen.SLICES[int(ex.data.slice)][2])))


func test_circles() -> void:
	_each("g7g.circle", func(ex: Dictionary, _l: int) -> void:
		var r := int(ex.data.r)
		if ex.data.ask == "circumference":
			assert_true(_is(ex, 2 * 314 * r, 100), str(ex.prompt))
		else:
			assert_true(_is(ex, 314 * r * r, 100), str(ex.prompt)))


func test_angle_facts() -> void:
	_each("g7g.angle_fact", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var total: int = 180 if d.kind == "supplementary" else (90 if d.kind == "complementary" else 0)
		if level < 3:
			assert_true(_is(ex, int(d.a) if d.kind == "vertical" else total - int(d.a)), str(ex.prompt))
		else:
			assert_true(_is(ex, total, int(d.m) + 1), str(ex.prompt)))


func test_prisms_and_areas() -> void:
	_each("g7g.prism", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var b := int(d.b)
		var h := int(d.h)
		var l := int(d.l)
		if d.kind == "prism":
			assert_true(_is(ex, b * h * l))
		elif d.kind == "triangular":
			assert_true(_is(ex, b * h * l, 2))
		else:
			assert_true(_is(ex, b * h - l * l)))


func test_sampling_and_probability() -> void:
	_each("g7g.sampling", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if level == 1:
			assert_eq(ex.answer, G7GeometryGen.SAMPLES[int(d.i)][1])
		else:
			assert_true(_is(ex, int(d.k) * int(d.total), int(d.n)), str(ex.prompt)))
	_each("g7g.probability", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.kind == "bag":
			assert_true(_is(ex, int(d.a), int(d.a) + int(d.b)))
		elif d.kind == "compound":
			assert_true(_is(ex, int(d.a), int(d.b)))
		else:
			assert_true(_is(ex, int(d.b), int(d.a))))
