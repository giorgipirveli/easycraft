extends GutTest
## Owner #68, grade 5 maths: the generators' answers checked against arithmetic done here, from each exercise's `data`
## (its inputs), for many seeds and every level. The content test checks that every exercise is valid and right by its
## own answer; this checks that the answer is the right one. Decimals are worked in whole thousandths (or hundredths),
## fractions as [top, bottom], expressions with brackets by a small evaluator here, so nothing goes through floats.

const SEEDS := 80
const SUP := "⁰¹²³⁴⁵⁶⁷⁸⁹"


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), gen)
			if ex.is_empty():
				return
			check.call(ex, level)


## True when the exercise's answer (a number, or the right choice's words) has the value num/den.
func _is(ex: Dictionary, num: int, den: int = 1) -> bool:
	var text := str(ex.answer) if str(ex.type) == "number" else ExerciseCheck.answer_text(ex)
	var g := NumberAnswer.gcd(absi(num), den)
	return NumberAnswer.equal(text, "%d/%d" % [num / g, den / g])


func _p10(k: int) -> int:
	return int(pow(10, k))


# --- A small exact evaluator with brackets -----------------------------------------------------------------------------

## [top, bottom] of an expression of numbers, + − × ÷ and brackets, separated by spaces ("(6 + 4) × 3"); [] if not one.
func _eval(text: String) -> Array:
	var tokens: Array[String] = []
	for t in text.replace("(", " ( ").replace(")", " ) ").split(" ", false):
		tokens.append(t)
	var at := [0]
	var out := _sum(tokens, at)
	return out if not out.is_empty() and at[0] == tokens.size() else []


func _sum(tokens: Array[String], at: Array) -> Array:
	var left := _product(tokens, at)
	while not left.is_empty() and at[0] < tokens.size() and tokens[at[0]] in ["+", "−"]:
		var op := tokens[at[0]]
		at[0] += 1
		var right := _product(tokens, at)
		if right.is_empty():
			return []
		var sign := 1 if op == "+" else -1
		left = [left[0] * right[1] + sign * right[0] * left[1], left[1] * right[1]]
	return left


func _product(tokens: Array[String], at: Array) -> Array:
	var left := _atom(tokens, at)
	while not left.is_empty() and at[0] < tokens.size() and tokens[at[0]] in ["×", "÷"]:
		var op := tokens[at[0]]
		at[0] += 1
		var right := _atom(tokens, at)
		if right.is_empty():
			return []
		left = [left[0] * right[0], left[1] * right[1]] if op == "×" else [left[0] * right[1], left[1] * right[0]]
	return left


func _atom(tokens: Array[String], at: Array) -> Array:
	if at[0] >= tokens.size():
		return []
	var t := tokens[at[0]]
	at[0] += 1
	if t == "(":
		var inside := _sum(tokens, at)
		if at[0] >= tokens.size() or tokens[at[0]] != ")":
			return []
		at[0] += 1
		return inside
	return NumberAnswer.parse(t)


func _same(a: Array, b: Array) -> bool:
	return not a.is_empty() and not b.is_empty() and a[1] != 0 and b[1] != 0 and a[0] * b[1] == b[0] * a[1]


func test_the_evaluator() -> void:
	assert_true(_same(_eval("(6 + 4) × 3"), [30, 1]))
	assert_true(_same(_eval("6 + 4 × 3"), [18, 1]))
	assert_true(_same(_eval("2 × (15 − 3 × 4) + 7"), [13, 1]))
	assert_true(_same(_eval("24 ÷ (2 + 4)"), [4, 1]))
	assert_true(_same(_eval("1/2 + 1/3"), [5, 6]))
	assert_eq(_eval("(1 + 2"), [])


# --- Unit 1: powers of ten ----------------------------------------------------------------------------------------------

func test_powers_of_ten() -> void:
	_each("g5n.times_power", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if str(d.op) == "×":
			assert_true(_is(ex, int(d.v) * int(d.p), 1000), str(ex.prompt))
		else:
			assert_true(_is(ex, int(d.v), int(d.p) * 1000), str(ex.prompt)))
	_each("g5n.power_value", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.c) * _p10(int(d.k)), 1000), str(ex.prompt))
		assert_string_contains(str(ex.prompt), "10" + SUP[int(d.k)]))
	_each("g5n.which_power", func(ex: Dictionary, _l: int) -> void:
		var k: int = ex.data.k
		if str(ex.type) == "number":
			assert_eq(int(ex.answer), k)
			assert_string_contains(str(ex.prompt), GenKit.fmt(_p10(k)))
		elif str(ex.prompt).contains(GenKit.fmt(_p10(k))):
			assert_eq(ExerciseCheck.answer_text(ex), "10" + SUP[k])
		else:
			assert_string_contains(str(ex.prompt), "10" + SUP[k])
			assert_eq(ExerciseCheck.answer_text(ex), GenKit.fmt(_p10(k))))
	_each("g5n.digit_times", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var n := str(d.n).replace(",", "")
		var ones := n.find(".") - 1 if n.contains(".") else n.length() - 1
		var at := func(p: int) -> String: return n[ones - p] if p >= 0 else n[ones + 1 - p]
		assert_eq(at.call(int(d.hi)), str(d.d), "the digit in the higher place: %s" % n)
		assert_eq(at.call(int(d.lo)), str(d.d), "the digit in the lower place: %s" % n)
		var times := _p10(int(d.hi) - int(d.lo))
		if bool(d.up):
			assert_true(_is(ex, times), str(ex.prompt))
		else:
			assert_true(_is(ex, 1, times), str(ex.prompt)))
	_each("g5n.missing_power", func(ex: Dictionary, _l: int) -> void:
		var sides := str(ex.prompt).replace("?", str(ex.answer)).split(" = ")
		assert_true(_same(_eval(sides[0]), _eval(sides[1])), "%s with %s" % [ex.prompt, ex.answer]))


# --- Unit 2: decimals to thousandths ------------------------------------------------------------------------------------

func test_decimal_places() -> void:
	_each("g5n.decimal_digit", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var n := str(d.n)
		assert_eq(n.count(str(d.d)), 1, "the digit is there once: %s" % n)
		var point := n.find(".")
		var at := n.find(str(d.d))
		var place := point - at - 1 if at < point else point - at   # ones 0, tenths -1
		assert_eq(place, int(d.place))
		var v := int(d.d) * _p10(place + 3)
		assert_true(_is(ex, v, 1000), "%s: %s" % [ex.prompt, ExerciseCheck.answer_text(ex)]))
	_each("g5n.expanded_decimal", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.t), 1000))
		assert_true(_same(_eval(str(ex.prompt).trim_suffix(" = ?")), [int(ex.data.t), 1000]), str(ex.prompt)))
	_each("g5n.decimal_words", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.w) * int(d.den) + int(d.n), int(d.den)))
		assert_string_contains(str(ex.prompt), NumberWords.say(int(d.n))))


func test_compare_order_and_round_decimals() -> void:
	_each("g5n.compare_decimals", func(ex: Dictionary, _l: int) -> void:
		var a: int = ex.data.a
		var b: int = ex.data.b
		assert_eq(ExerciseCheck.answer_text(ex), "=" if a == b else (">" if a > b else "<"), str(ex.prompt))
		var shown := str(ex.prompt).get_slice("?  ", 1).split(" ? ")
		assert_true(NumberAnswer.equal(shown[0], "%d/1000" % a) and NumberAnswer.equal(shown[1], "%d/1000" % b)))
	_each("g5n.order_decimals", func(ex: Dictionary, _l: int) -> void:
		var last := -INF
		for i: Variant in ex.answer:
			var v := NumberAnswer.value(str(ex.items[int(i)]))
			assert_gt(v, last, "smallest first")
			last = v)
	_each("g5n.round_decimal", func(ex: Dictionary, _l: int) -> void:
		var t: int = ex.data.t
		var unit: int = ex.data.unit   # thousandths in the place rounded to
		var want := floori((t + unit * 0.5) / unit) * unit
		assert_true(_is(ex, want, 1000), "%s -> %s" % [ex.prompt, ex.answer]))
	_each("g5n.decimal_on_line", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.t), 1000))
		assert_true(NumberAnswer.equal(str(ex.answer), str(ex.picture.dot))))


# --- Units 3 and 4: multiply and divide whole numbers ------------------------------------------------------------------

func test_multiplying() -> void:
	_each("g5n.multiply", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.a) * int(ex.data.b))))
	_each("g5n.partial_product", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.col) * int(d.row)))
		var sum := 0
		for c: Variant in ex.picture.cols:
			sum += int(str(c).replace(",", ""))
		assert_eq(sum, int(d.a), "the columns make the first number"))
	_each("g5n.estimate_product", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var lead := func(n: int) -> int:
			var p := _p10(str(n).length() - 1)
			return floori((n + p * 0.5) / p) * p
		assert_true(_is(ex, lead.call(int(d.a)) * lead.call(int(d.b))), str(ex.prompt)))
	_each("g5n.multiply_story", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.a) * int(ex.data.b))))
	_each("g5n.split_product", func(ex: Dictionary, _l: int) -> void:
		var sides := str(ex.prompt).split(" = ")
		assert_eq(ex.answer, _same(_eval(sides[0]), _eval(sides[1])), str(ex.prompt)))


func test_dividing() -> void:
	_each("g5n.divide", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.q)))
		assert_true(_same(_eval(str(ex.prompt).trim_suffix(" = ?")), [int(ex.data.q), 1])))
	_each("g5n.remainder", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		var d: int = ex.data.d
		assert_true(_is(ex, n % d if str(ex.prompt).contains("left over") else int(n / float(d))), str(ex.prompt)))
	_each("g5n.division_story", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		var d: int = ex.data.d
		var kind := str(ex.data.kind)
		if kind == "exact":
			assert_eq(n % d, 0)
		assert_true(_is(ex, ceili(n / float(d)) if kind == "up" else int(n / float(d))), str(ex.prompt)))
	_each("g5n.division_area", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq((int(d.p1) + int(d.p2)) * int(d.d), int(d.n))
		assert_true(_is(ex, int(d.p2) if str(ex.prompt).contains("? part") else int(d.p1) + int(d.p2)), str(ex.prompt)))
	_each("g5n.check_division", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(ex.answer, int(d.shown) * int(d.d) == int(d.n), str(ex.prompt)))


# --- Units 5 and 6: decimals ------------------------------------------------------------------------------------------

func test_adding_and_subtracting_decimals() -> void:
	for gen: String in ["g5n.add_decimals", "g5n.subtract_decimals", "g5n.missing_decimal"]:
		_each(gen, func(ex: Dictionary, _l: int) -> void:
			var sides := str(ex.prompt).split(" = ")
			var left := sides[0].replace("?", str(ex.answer))
			var right := sides[1].replace("?", str(ex.answer))
			assert_true(_same(_eval(left), _eval(right)), "%s with %s" % [ex.prompt, ex.answer]))
	_each("g5n.decimal_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.a) + int(d.b) if str(d.op) == "+" else int(d.a) - int(d.b), 100), str(ex.prompt)))
	_each("g5n.line_up", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.a) + int(ex.data.b), 100), str(ex.prompt)))


func test_multiplying_and_dividing_decimals() -> void:
	for gen: String in ["g5n.decimal_times_whole", "g5n.decimal_times_decimal", "g5n.decimal_divide", "g5n.divide_by_decimal"]:
		_each(gen, func(ex: Dictionary, _l: int) -> void:
			assert_true(_same(_eval(str(ex.prompt).trim_suffix(" = ?")), NumberAnswer.parse(str(ex.answer))),
				"%s = %s" % [ex.prompt, ex.answer]))
	_each("g5n.place_the_point", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.a) * int(d.b), _p10(int(d.pa) + int(d.pb)))))
	_each("g5n.decimal_square", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.a) * int(d.b), 100))
		assert_eq([int(ex.picture.shade_cols), int(ex.picture.shade_rows)], [int(d.b), int(d.a)]))


# --- Unit 7: expressions ----------------------------------------------------------------------------------------------

func test_expressions() -> void:
	for gen: String in ["g5n.brackets", "g5n.order_of_operations"]:
		_each(gen, func(ex: Dictionary, _l: int) -> void:
			assert_true(_same(_eval(str(ex.prompt).trim_suffix(" = ?")), NumberAnswer.parse(str(ex.answer))),
				"%s = %s" % [ex.prompt, ex.answer]))
	_each("g5n.words_to_expression", func(ex: Dictionary, _l: int) -> void:
		var right := _eval(ExerciseCheck.answer_text(ex))
		assert_true(_same(right, [int(ex.data.value), 1]), "%s: %s" % [ex.prompt, ExerciseCheck.answer_text(ex)])
		for i in (ex.choices as Array).size():
			if i != int(ex.answer):
				assert_false(_same(_eval(str(ex.choices[i])), right), "%s is another way to write it" % ex.choices[i]))
	_each("g5n.bracket_place", func(ex: Dictionary, _l: int) -> void:
		var target: int = ex.data.target
		for i in (ex.choices as Array).size():
			assert_eq(i == int(ex.answer), _same(_eval(str(ex.choices[i])), [target, 1]), str(ex.choices[i])))
	_each("g5n.compare_expression", func(ex: Dictionary, _l: int) -> void:
		var k: int = ex.data.k
		var words := ExerciseCheck.answer_text(ex)
		if str(ex.data.op) == "×":
			assert_eq(words, "%d times as large" % k)
		else:
			assert_eq(words, "%s as large" % ("half" if k == 2 else "a third" if k == 3 else "a quarter" if k == 4 else "a tenth")))
	_each("g5n.expression_story", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.value)))
		assert_true(_same(_eval(str(ex.data.expr)), [int(ex.data.value), 1]), str(ex.data.expr)))


# --- Units 8-12: fractions (g5f) -----------------------------------------------------------------------------------------

## [top, bottom] of a mixed number's words ("2 3/4", "3", "3/4"), [] when it is none.
func _mixed(text: String) -> Array:
	var t := text.trim_suffix(" m").trim_suffix(" kg").trim_suffix(" km").trim_suffix(" L")
	var parts := t.split(" ")
	if parts.size() == 1:
		return NumberAnswer.parse(parts[0])
	var w := NumberAnswer.parse(parts[0])
	var f := NumberAnswer.parse(parts[1])
	if w.is_empty() or f.is_empty():
		return []
	return [w[0] * f[1] + f[0], f[1]]


## True when an equation "… = …" with the answer in place of "?" holds (numbers, fractions, + − × ÷, brackets).
func _holds(prompt: String, answer: String) -> bool:
	var sides := prompt.replace("?", answer).split(" = ")
	return sides.size() == 2 and _same(_eval(sides[0]), _eval(sides[1]))


func test_adding_unlike_fractions() -> void:
	for gen: String in ["g5f.add_unlike", "g5f.subtract_unlike"]:
		_each(gen, func(ex: Dictionary, _l: int) -> void:
			var d: Dictionary = ex.data
			var sign := 1 if gen.ends_with("add_unlike") else -1
			assert_true(_is(ex, int(d.a) * int(d.d) + sign * int(d.c) * int(d.b), int(d.b) * int(d.d)), str(ex.prompt))
			assert_true(_holds(str(ex.prompt), str(ex.answer)), str(ex.prompt))
			assert_ne(int(d.b), int(d.d), "different denominators"))
	_each("g5f.common_denominator", func(ex: Dictionary, _l: int) -> void:
		var b: int = ex.data.b
		var d: int = ex.data.d
		var l := b * d / NumberAnswer.gcd(b, d)
		assert_true(_is(ex, l), str(ex.prompt)))
	_each("g5f.add_mixed_unlike", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var want := [(int(d.w1) * int(d.b) + int(d.a)) * int(d.d) + (int(d.w2) * int(d.d) + int(d.c)) * int(d.b),
			int(d.b) * int(d.d)]
		for i in (ex.choices as Array).size():
			assert_eq(i == int(ex.answer), _same(_mixed(str(ex.choices[i])), want), "%s: %s" % [ex.prompt, ex.choices[i]]))
	_each("g5f.benchmark_sum", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var sum := [int(d.a) * int(d.d) + int(d.c) * int(d.b), int(d.b) * int(d.d)]
		var t: Array = d.target
		var cmp: int = sum[0] * int(t[1]) - int(t[0]) * sum[1]
		var words := ExerciseCheck.answer_text(ex)
		assert_true(words.begins_with("exactly") if cmp == 0 else (words.begins_with("more") if cmp > 0 else
			words.begins_with("less")), "%s: %s" % [ex.prompt, words]))
	_each("g5f.sum_mistake", func(ex: Dictionary, _l: int) -> void:
		var sides := str(ex.prompt).trim_prefix("Bram says ").trim_suffix(".").split(" = ")
		assert_eq(ex.answer, _same(_eval(sides[0]), _eval(sides[1])), str(ex.prompt)))
	_each("g5f.unlike_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var sign := 1 if str(d.op) == "+" else -1
		assert_true(_is(ex, int(d.a) * int(d.d) + sign * int(d.c) * int(d.b), int(d.b) * int(d.d)), str(ex.prompt)))


func test_fractions_as_division() -> void:
	_each("g5f.division_to_fraction", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.a), int(ex.data.b)))
		assert_true(_holds(str(ex.prompt), str(ex.answer)), str(ex.prompt)))
	_each("g5f.fraction_to_division", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ExerciseCheck.answer_text(ex), "%d ÷ %d" % [ex.data.a, ex.data.b]))
	_each("g5f.share_story", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.n), int(ex.data.p)), str(ex.prompt)))
	_each("g5f.between_wholes", func(ex: Dictionary, _l: int) -> void:
		var q := int(int(ex.data.a) / float(ex.data.b))
		assert_ne(int(ex.data.a) % int(ex.data.b), 0)
		assert_eq(ExerciseCheck.answer_text(ex), "%d and %d" % [q, q + 1]))
	_each("g5f.share_mixed", func(ex: Dictionary, _l: int) -> void:
		var want := [int(ex.data.n), int(ex.data.p)]
		for i in (ex.choices as Array).size():
			assert_eq(i == int(ex.answer), _same(_mixed(str(ex.choices[i])), want), "%s: %s" % [ex.prompt, ex.choices[i]]))
	_each("g5f.sharing_picture", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.n), int(ex.data.p)))
		assert_eq((ex.picture.bars as Array).size(), int(ex.data.n), "a bar for each thing shared"))


func test_multiplying_fractions() -> void:
	for gen: String in ["g5f.fraction_of_number", "g5f.fraction_times_fraction"]:
		_each(gen, func(ex: Dictionary, _l: int) -> void:
			assert_true(_holds(str(ex.prompt), str(ex.answer)), "%s = %s" % [ex.prompt, ex.answer]))
	_each("g5f.fraction_of_number", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.a) * int(d.n), int(d.b))))
	_each("g5f.fraction_times_fraction", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.a) * int(d.c), int(d.b) * int(d.d))))
	for gen: String in ["g5f.area_model_product", "g5f.fraction_rectangle", "g5f.fraction_story", "g5f.build_product"]:
		_each(gen, func(ex: Dictionary, _l: int) -> void:
			var d: Dictionary = ex.data
			if str(ex.type) == "build":
				var cells := BuildCheck.example(ex.goal, ex.board)
				assert_eq(cells.size() * int(d.b) * int(d.d), int(ex.board.cols) * int(ex.board.rows) * int(d.a) * int(d.c))
			else:
				assert_true(_is(ex, int(d.a) * int(d.c), int(d.b) * int(d.d)), str(ex.prompt))
			if ex.get("picture", {}).get("kind", "") == "fraction_area":
				assert_eq(int(ex.picture.shade_cols) * int(ex.picture.shade_rows) * int(d.b) * int(d.d),
					int(ex.picture.cols) * int(ex.picture.rows) * int(d.a) * int(d.c), "the picture shows the product"))


func test_scaling() -> void:
	_each("g5f.scale_compare", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a: int = d.a
		var b: int = d.b
		var words := ExerciseCheck.answer_text(ex)
		assert_true(words.begins_with("equal") if a == b else (words.begins_with("more") if a > b else
			words.begins_with("less")), "%s: %s" % [ex.prompt, words]))
	_each("g5f.scale_order", func(ex: Dictionary, _l: int) -> void:
		var last := [-1, 1]
		for i: Variant in ex.answer:
			var v := _eval(str(ex.items[int(i)]))
			assert_gt(v[0] * last[1], last[0] * v[1], "smallest first: %s" % [ex.items])
			last = v)
	_each("g5f.scale_truefalse", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var bigger: bool = int(d.a) > int(d.b)
		var smaller: bool = int(d.a) < int(d.b)
		assert_eq(ex.answer, bigger if str(ex.prompt).contains("more than") else smaller, str(ex.prompt)))
	_each("g5f.scale_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var words := ExerciseCheck.answer_text(ex)
		if str(ex.type) == "number":
			assert_true(_is(ex, int(d.n) * int(d.a), int(d.b)), str(ex.prompt))
		elif int(d.a) == int(d.b):
			assert_string_contains(words, "same")
		else:
			assert_string_contains(words, str(d.ref) if int(d.a) < int(d.b) else str(d.other), str(ex.prompt)))
	_each("g5f.scale_factor", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		var smaller := bool(ex.data.smaller)
		for i in (ex.choices as Array).size():
			var v := _eval(str(ex.choices[i]))
			var fits: bool = v[0] < v[1] if smaller else v[0] > v[1]
			assert_eq(i == int(ex.answer), fits, "%s: %s" % [ex.prompt, ex.choices[i]])
		assert_gt(n, 0))


func test_dividing_with_unit_fractions() -> void:
	_each("g5f.unit_divided", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, 1, int(ex.data.b) * int(ex.data.n)))
		assert_true(_holds(str(ex.prompt), str(ex.answer)), str(ex.prompt)))
	_each("g5f.whole_divided", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.n) * int(ex.data.b)))
		assert_true(_holds(str(ex.prompt), str(ex.answer)), str(ex.prompt)))
	_each("g5f.unit_divide_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if str(d.kind) == "bags":
			assert_true(_is(ex, int(d.n) * int(d.b)), str(ex.prompt))
		else:
			assert_true(_is(ex, 1, int(d.n) * int(d.b)), str(ex.prompt)))
	_each("g5f.divide_check", func(ex: Dictionary, _l: int) -> void:
		for i in (ex.choices as Array).size():
			var sides := str(ex.choices[i]).split(" = ")
			var holds := _same(_eval(sides[0]), _eval(sides[1]))
			assert_eq(i == int(ex.answer), holds, "%s: %s" % [ex.prompt, ex.choices[i]]))
	_each("g5f.divide_truefalse", func(ex: Dictionary, _l: int) -> void:
		var sides := str(ex.prompt).split(" = ")
		assert_eq(ex.answer, _same(_eval(sides[0]), _eval(sides[1])), str(ex.prompt)))
