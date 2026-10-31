extends GutTest
## Owner #68, grade 6 maths (G6NumberGen "g6n", G6AlgebraGen "g6a"): each generator's answer is worked out again here from
## the exercise's `data`, for many seeds and every level, and every exercise must be valid (ExerciseCheck). Decimals are
## whole thousandths and fractions [top, bottom], so nothing goes through floats.

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


## True when the exercise's answer (a number, or the right choice's words) has the value num/den.
func _is(ex: Dictionary, num: int, den: int = 1) -> bool:
	var text := str(ex.answer) if str(ex.type) == "number" else ExerciseCheck.answer_text(ex)
	var g := NumberAnswer.gcd(absi(num), absi(den))
	return NumberAnswer.equal(text, "%d/%d" % [num / g, den / g])


func _gcd(a: int, b: int) -> int:
	return NumberAnswer.gcd(a, b)


func _signed(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


# --- g6n ------------------------------------------------------------------------------------------------------------------

func test_ratio_words_name_the_amounts_in_the_asked_order() -> void:
	_each("g6n.ratio_words", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var want: String = {"ab": "%d : %d" % [d.a, d.b], "ba": "%d : %d" % [d.b, d.a], "a_all": "%d : %d" % [d.a, int(d.a) + int(d.b)]}[str(d.ask)]
		assert_eq(ExerciseCheck.answer_text(ex), want, str(ex.prompt)))


func test_equal_ratios() -> void:
	_each("g6n.ratio_table", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.k2) * (int(d.s) if d.missing == "s" else int(d.r))), str(ex.prompt)))


func test_unit_rates() -> void:
	_each("g6n.unit_rate", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.ask == "rate":
			assert_true(_is(ex, int(d.rate10), 10), str(ex.prompt))
		else:
			assert_true(_is(ex, int(d.n)), str(ex.prompt)))


func test_the_better_buy_is_the_cheapest_for_each_one() -> void:
	_each("g6n.better_buy", func(ex: Dictionary, _l: int) -> void:
		var packs: Array = ex.data.packs
		var best := 0
		for i in packs.size():
			if int(packs[i][1]) * int(packs[best][0]) < int(packs[best][1]) * int(packs[i][0]):
				best = i
		assert_eq(ExerciseCheck.answer_text(ex), "Pack %s" % "ABC"[best], str(ex.prompt)))


func test_percent_of_and_the_whole() -> void:
	_each("g6n.percent_of", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.ask == "part":
			assert_true(_is(ex, int(d.p) * int(d.n), 100), str(ex.prompt))
		else:
			assert_true(_is(ex, int(d.n)), str(ex.prompt)))
	_each("g6n.percent_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var off := int(d.p) * int(d.n)
		assert_true(_is(ex, int(d.n) * 100 + (off if d.up else -off), 100), str(ex.prompt)))


func test_converting_with_a_ratio() -> void:
	_each("g6n.convert_ratio", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.to_small:
			assert_true(_is(ex, int(d.small)), str(ex.prompt))
		else:
			assert_true(_is(ex, int(d.small), int(d.factor)), str(ex.prompt)))


func test_dividing_fractions() -> void:
	_each("g6n.frac_divide", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.a) * int(d.d), int(d.b) * int(d.c)), str(ex.prompt)))


func test_long_division_and_decimals() -> void:
	_each("g6n.long_divide", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.q)), str(ex.prompt)))
	_each("g6n.decimal_ops", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		if str(d.op) == "+":
			assert_true(_is(ex, a + b, 1000), str(ex.prompt))
		elif str(d.op) == "−":
			assert_true(_is(ex, a - b, 1000), str(ex.prompt))
		elif str(d.op) == "×":
			assert_true(_is(ex, a * b, 1000000), str(ex.prompt))
		else:
			assert_true(_is(ex, a, b), str(ex.prompt)))


func test_factors_and_multiples() -> void:
	_each("g6n.gcf", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, _gcd(int(ex.data.a), int(ex.data.b))), str(ex.prompt)))
	_each("g6n.lcm", func(ex: Dictionary, _l: int) -> void:
		var a := int(ex.data.a)
		var b := int(ex.data.b)
		assert_true(_is(ex, a * b / _gcd(a, b)), str(ex.prompt)))
	_each("g6n.factor_sum", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(_gcd(int(d.m), int(d.n)), 1, "the sum in brackets has no common factor")
		assert_true(_is(ex, int(d.g) if d.ask_g else int(d.n)), str(ex.prompt)))


func test_negative_numbers() -> void:
	_each("g6n.compare_integers", func(ex: Dictionary, _l: int) -> void:
		var values: Array = ex.data.values
		var sorted := values.duplicate()
		sorted.sort()
		if str(ex.data.ask) == "min":
			assert_eq(ExerciseCheck.answer_text(ex), "%s°C" % _signed(int(sorted[0])))
		elif str(ex.data.ask) == "max":
			assert_eq(ExerciseCheck.answer_text(ex), _signed(int(sorted[-1])))
		else:
			assert_eq(ExerciseCheck.answer_text(ex), ", ".join(sorted.map(func(v: int) -> String: return _signed(v)))))
	_each("g6n.absolute_value", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if str(d.ask) == "abs":
			assert_true(_is(ex, absi(int(d.a))))
		elif str(d.ask) == "farther":
			assert_eq(ExerciseCheck.answer_text(ex), _signed(int(d.a)) if absi(int(d.a)) > int(d.b) else str(d.b))
		else:
			assert_true(_is(ex, int(d.b) - int(d.a))))


# --- g6a ------------------------------------------------------------------------------------------------------------------

func test_the_coordinate_plane() -> void:
	_each("g6a.quadrant", func(ex: Dictionary, _l: int) -> void:
		var x := int(ex.data.x)
		var y := int(ex.data.y)
		if str(ex.data.ask) == "quadrant":
			var q := (0 if y > 0 else 3) if x > 0 else (1 if y > 0 else 2)
			assert_eq(ExerciseCheck.answer_text(ex), G6AlgebraGen.QUADRANTS[q])
		elif str(ex.data.ask) == "x":
			assert_eq(ExerciseCheck.answer_text(ex), "(%s, %s)" % [_signed(x), _signed(-y)])
		else:
			assert_eq(ExerciseCheck.answer_text(ex), "(%s, %s)" % [_signed(-x), _signed(y)]))
	_each("g6a.axis_distance", func(ex: Dictionary, _l: int) -> void:
		var a: Array = ex.data.a
		var b: Array = ex.data.b
		assert_true(int(a[0]) == int(b[0]) or int(a[1]) == int(b[1]), "the points share x or y")
		assert_true(_is(ex, absi(int(a[0]) - int(b[0])) + absi(int(a[1]) - int(b[1]))), str(ex.prompt)))


func test_powers_and_expressions() -> void:
	_each("g6a.power_value", func(ex: Dictionary, _l: int) -> void:
		var total := 0
		for t: Array in ex.data.terms:
			var v := 1
			for _i in int(t[1]):
				v *= int(t[0])
			total += v
		assert_true(_is(ex, total), str(ex.prompt)))
	_each("g6a.evaluate", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		var want: int = {"ax+b": a * int(d.x) + b, "a(x+b)": a * (int(d.x) + b), "ax+by": a * int(d.x) + b * int(d.y)}[str(d.form)]
		assert_true(_is(ex, want), str(ex.prompt)))
	_each("g6a.write_expression", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ExerciseCheck.answer_text(ex), str(G6AlgebraGen.PHRASES[int(ex.data.i)][1])))


func test_equivalent_expressions() -> void:
	_each("g6a.distribute", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		var c := int(d.c)
		var sign := "−" if d.minus else "+"
		var expanded := "%dx %s %d" % [a * b, sign, a * c]
		var factored := "%d(%sx %s %d)" % [a, "" if b == 1 else str(b), sign, c]
		assert_eq(ExerciseCheck.answer_text(ex), expanded if level < 3 else factored, str(ex.prompt)))
	_each("g6a.like_terms", func(ex: Dictionary, _l: int) -> void:
		var x := 0
		for c: int in ex.data.coefs:
			x += c
		var n := 0
		for c: int in ex.data.consts:
			n += c
		var term := "x" if x == 1 else "%dx" % x
		var want := term if n == 0 else "%s + %d" % [term, n]
		if x == 0:
			want = str(n)
		assert_eq(ExerciseCheck.answer_text(ex), want, str(ex.prompt)))
	_each("g6a.equivalent_tf", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ex.answer, int(ex.data.claimed) == int(ex.data.a) * int(ex.data.c), str(ex.prompt)))


func test_equations_and_inequalities() -> void:
	_each("g6a.solve_one_step", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var x := int(d.x1000)
		var a := int(d.a)
		var r: int = {"+": x + a * 1000, "−": x - a * 1000, "×": x * a, "÷": x / a}[str(d.op)]
		assert_gt(r, 0, "the right side is positive")
		assert_true(str(ex.prompt).contains(" = %s." % G6AlgebraGen._dec(r)), "%s: the equation holds for x" % ex.prompt)
		assert_true(_is(ex, x, 1000), str(ex.prompt)))
	_each("g6a.inequality", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var n := int(d.n)
		if level == 3:
			assert_eq(ExerciseCheck.answer_text(ex), "p %s %d" % [d.op, n])
			return
		for i in (ex.choices as Array).size():
			var v := int(str(ex.choices[i]))
			var holds: bool = {">": v > n, "<": v < n, "≥": v >= n, "≤": v <= n}[str(d.op)]
			assert_eq(i == int(ex.answer), holds, "%s: %d" % [ex.prompt, v]))


func test_rules_tables_and_graphs() -> void:
	_each("g6a.table_rule", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var m := int(d.m)
		var c := int(d.c)
		if level < 3:
			assert_true(_is(ex, m * int(d.x) + c), str(ex.prompt))
		else:
			assert_eq(ExerciseCheck.answer_text(ex), "y = %dx + %d" % [m, c] if c > 0 else "y = %dx" % m))


func test_areas() -> void:
	_each("g6a.area", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var b := int(d.b)
		var h := int(d.h)
		var t := int(d.t)
		var top := b - t if b - t > 0 else b + t
		var want: int = {"triangle": b * h / 2, "parallelogram": b * h, "trapezium": (top + b) * h / 2, "house": b * h + b * t / 2}[str(d.shape)]
		assert_true(_is(ex, want), str(ex.prompt)))


func test_volume_and_surface_area() -> void:
	_each("g6a.volume_fraction", func(ex: Dictionary, _l: int) -> void:
		var num := 1
		var den := 1
		for e: Array in ex.data.edges:
			num *= int(e[0])
			den *= int(e[1])
		if int(ex.data.cube) == 1:
			assert_true(_is(ex, num, den), str(ex.prompt))
		else:
			assert_true(_is(ex, num * 8, den), str(ex.prompt)))
	_each("g6a.surface_area", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var l := int(d.l)
		var w := int(d.w)
		var h := int(d.h)
		assert_true(_is(ex, 2 * (l * w + l * h + w * h)), str(ex.prompt)))


func test_statistics() -> void:
	_each("g6a.centre_spread", func(ex: Dictionary, _l: int) -> void:
		var values: Array = ex.data.values
		var sorted := values.duplicate()
		sorted.sort()
		var n := sorted.size()
		if str(ex.data.ask) == "range":
			assert_true(_is(ex, int(sorted[-1]) - int(sorted[0])))
		elif str(ex.data.ask) == "median":
			var twice := 2 * int(sorted[n / 2]) if n % 2 == 1 else int(sorted[n / 2 - 1]) + int(sorted[n / 2])
			assert_true(_is(ex, twice, 2))
		elif str(ex.data.ask) == "mean":
			var total := 0
			for v: int in values:
				total += v
			assert_eq(total % n, 0, "a whole-number mean")
			assert_true(_is(ex, total, n))
		else:
			assert_eq(n, 8)
			var q1_twice := int(sorted[1]) + int(sorted[2])   # the middle of the lower four
			var q3_twice := int(sorted[5]) + int(sorted[6])   # the middle of the upper four
			assert_true(_is(ex, q3_twice - q1_twice, 2), "IQR: " + str(ex.prompt)))
	_each("g6a.stat_question", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ExerciseCheck.answer_text(ex), str(G6AlgebraGen.STAT_QUESTIONS[int(ex.data.i)][0])))


func test_data_displays() -> void:
	_each("g6a.box_plot", func(ex: Dictionary, level: int) -> void:
		var five: Array = ex.data.five
		for i in 4:
			assert_lt(int(five[i]), int(five[i + 1]), "the five numbers rise")
		if level == 1:
			assert_true(_is(ex, int(five[2])))
		elif level == 2:
			assert_true(_is(ex, int(five[3]) - int(five[1])))
		else:
			assert_eq(ExerciseCheck.answer_text(ex), "half"))
	_each("g6a.dot_count", func(ex: Dictionary, _l: int) -> void:
		var count := 0
		for v: int in ex.data.values:
			if v >= int(ex.data.lo) and v <= int(ex.data.hi):
				count += 1
		assert_true(_is(ex, count), str(ex.prompt)))
