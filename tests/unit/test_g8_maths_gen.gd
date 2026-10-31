extends GutTest
## Owner #68, grade 8 maths (G8AlgebraGen "g8n", G8GeometryGen "g8g"): each generator's answer is worked out again here
## from the exercise's `data`, for many seeds and every level, and every exercise must be valid (ExerciseCheck).

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


# --- g8n ------------------------------------------------------------------------------------------------------------------

func test_irrational_numbers() -> void:
	_each("g8n.irrational", func(ex: Dictionary, level: int) -> void:
		if level == 1:
			assert_true(G8AlgebraGen.IRRATIONAL.has(ExerciseCheck.answer_text(ex)))
			for c: Variant in ex.choices:
				if ExerciseCheck.item_text(c) != ExerciseCheck.answer_text(ex):
					assert_true(G8AlgebraGen.RATIONAL.has(ExerciseCheck.item_text(c)), "the others are rational")
		else:
			var n := int(ex.data.n)
			var lo := 1
			while (lo + 1) * (lo + 1) <= n:
				lo += 1
			assert_ne(lo * lo, n, "not a square number")
			assert_eq(ExerciseCheck.answer_text(ex), "between %d and %d" % [lo, lo + 1]))


func test_exponent_rules() -> void:
	_each("g8n.exponent_rules", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		if d.rule == "times":
			assert_true(_is(ex, a + b))
		elif d.rule == "divide":
			assert_true(_is(ex, a - b))
		elif d.rule == "power":
			assert_true(_is(ex, a * b))
		else:
			assert_true(_is(ex, 1, int(pow(int(d.base), -a))) if a < 0 else _is(ex, 1), str(ex.prompt)))


func test_roots() -> void:
	_each("g8n.roots", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.r)), str(ex.prompt)))


func test_scientific_notation() -> void:
	_each("g8n.sci_notation", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.e)), str(ex.prompt))
		if d.kind == "big":
			var n := int(d.m10) * int(pow(10, int(d.e) - 1))
			assert_true(str(ex.prompt).begins_with(GenKit.fmt(n)), "the number is m × 10^e"))


func test_slope() -> void:
	_each("g8n.slope", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.m) if d.ask == "m" else int(d.b)), str(ex.prompt)))


func test_linear_equations() -> void:
	_each("g8n.both_sides", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if level < 3:
			var a := int(d.a)
			var c := int(d.c)
			assert_true(_is(ex, int(d.d) - int(d.b), a - c), str(ex.prompt))
		else:
			var words := {"one": "exactly one solution", "none": "no solution", "many": "infinitely many solutions"}
			assert_eq(ExerciseCheck.answer_text(ex), words[str(d.kind)], str(ex.prompt)))


func test_systems() -> void:
	_each("g8n.system", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var x := int(d.x)
		var y := int(d.y)
		assert_eq(int(d.m1) * x + int(d.b1), y, "the point is on line 1")
		assert_eq(int(d.m2) * x + int(d.b2), y, "the point is on line 2")
		assert_ne(int(d.m1), int(d.m2), "the lines cross once")
		assert_true(_is(ex, x if d.ask == "x" else y), str(ex.prompt)))


func test_functions() -> void:
	_each("g8n.is_function", func(ex: Dictionary, level: int) -> void:
		if level < 3:
			assert_eq(ex.answer, not ex.data.repeat, str(ex.prompt))
		else:
			assert_eq(ExerciseCheck.answer_text(ex).begins_with("yes"), bool(ex.data.linear), str(ex.prompt)))


# --- g8g ------------------------------------------------------------------------------------------------------------------

func test_linear_models() -> void:
	_each("g8g.linear_model", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.ask == "value":
			assert_true(_is(ex, int(d.start) + int(d.rate) * int(d.t)))
		elif d.ask == "equation":
			assert_eq(ExerciseCheck.answer_text(ex), "c = %dk + %d" % [d.rate, d.start])
		else:
			assert_true(_is(ex, int(d.rate))))


func test_transformations() -> void:
	_each("g8g.transform", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var x := int(d.x)
		var y := int(d.y)
		var to := Vector2i(x, y)
		if d.kind == "translate":
			to = Vector2i(x + int(d.a), y + int(d.b))
		elif d.kind == "reflect_x":
			to = Vector2i(x, -y)
		elif d.kind == "reflect_y":
			to = Vector2i(-x, y)
		elif d.kind == "rotate180":
			to = Vector2i(-x, -y)
		elif d.kind == "rotate90":
			to = Vector2i(y, -x)
		else:
			to = Vector2i(int(d.k) * x, int(d.k) * y)
		assert_eq(ExerciseCheck.answer_text(ex), "(%s, %s)" % [_signed(to.x), _signed(to.y)], str(ex.prompt)))


func test_similarity() -> void:
	_each("g8g.similar_side", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.s2) * int(d.num), int(d.den)), str(ex.prompt))
		assert_eq((int(d.s2) * int(d.num)) % int(d.den), 0, "a whole-number side"))


func test_angles() -> void:
	_each("g8g.parallel_angles", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var want: int = {"corresponding": a, "alternate": a, "co-interior": 180 - a, "exterior": a + int(d.b)}[str(d.kind)]
		assert_true(_is(ex, want), str(ex.prompt)))


func test_pythagoras() -> void:
	_each("g8g.pythagoras", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		var c := int(d.c)
		assert_eq(a * a + b * b, c * c, "a right triangle")
		assert_true(_is(ex, b if d.ask == "b" else c), str(ex.prompt)))


func test_round_volumes() -> void:
	_each("g8g.round_volume", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var r := int(d.r)
		var h := int(d.h)
		var want: int = {"cylinder": 314 * r * r * h, "cone": 314 * r * r * h, "sphere": 4 * 314 * r * r * r}[str(d.shape)]
		var den: int = {"cylinder": 100, "cone": 300, "sphere": 300}[str(d.shape)]
		assert_true(_is(ex, want, den), str(ex.prompt)))


func test_scatter_plots() -> void:
	_each("g8g.scatter", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if level == 3:
			assert_true(_is(ex, int(d.m) * int(d.x) + int(d.b)))
			return
		var ys: Array = d.ys
		if d.trend == "positive":
			assert_gt(int(ys[-1]), int(ys[0]) + 5, "rising")
		elif d.trend == "negative":
			assert_lt(int(ys[-1]), int(ys[0]) - 5, "falling")
		assert_true(ExerciseCheck.answer_text(ex).begins_with({"positive": "positive", "negative": "negative", "none": "no clear"}[str(d.trend)])))


func test_two_way_tables() -> void:
	_each("g8g.two_way", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var both := int(d.both)
		if d.ask == "sport":
			assert_true(_is(ex, both + int(d.sport)))
		elif d.ask == "total":
			assert_true(_is(ex, both + int(d.inst) + int(d.sport) + int(d.neither)))
		else:
			assert_true(_is(ex, both, both + int(d.inst))))
