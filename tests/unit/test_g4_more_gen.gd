extends GutTest
## Owner #68 (grade 4 maths): the fractions, decimals, measurement and geometry generators' answers, checked against
## arithmetic done here. Every generated sum written as an equation with a "?" ("2/3 = ?/12", "3/10 + 4/100 = ?/100",
## "5 × 1/4 = ?", "4,875 + 3,110 = ?") is checked by putting the answer in place of the "?" and working out both sides
## with exact fractions.

const SEEDS := 80


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), gen)
			check.call(ex, level)


# --- A small exact evaluator ------------------------------------------------------------------------------------

## [num, den] of an expression of numbers and + − × ÷ separated by spaces; [] when it is not one.
func _eval(text: String) -> Array:
	var tokens := text.strip_edges().split(" ", false)
	if tokens.is_empty() or tokens.size() % 2 == 0:
		return []
	var values: Array = []
	var ops: Array[String] = []
	for i in tokens.size():
		if i % 2 == 0:
			var v := NumberAnswer.parse(tokens[i])
			if v.is_empty():
				return []
			values.append(v)
		else:
			if not ["+", "−", "×", "÷"].has(tokens[i]):
				return []
			ops.append(tokens[i])
	# × and ÷ first
	var i := 0
	while i < ops.size():
		if ops[i] == "×" or ops[i] == "÷":
			var a: Array = values[i]
			var b: Array = values[i + 1]
			var r: Array = [a[0] * b[0], a[1] * b[1]] if ops[i] == "×" else [a[0] * b[1], a[1] * b[0]]
			values[i] = r
			values.remove_at(i + 1)
			ops.remove_at(i)
		else:
			i += 1
	var out: Array = values[0]
	for k in ops.size():
		var b: Array = values[k + 1]
		var sign := 1 if ops[k] == "+" else -1
		out = [out[0] * b[1] + sign * b[0] * out[1], out[1] * b[1]]
	return out


## 1 when the equation holds with the answer in place of "?", 0 when not, -1 when the prompt is no such equation.
func _holds(prompt: String, answer: String) -> int:
	var p := prompt.strip_edges()
	if not p.contains(" = ") or not p.contains("?") or p.count(" = ") != 1:
		return -1
	var eq := p.replace("?", answer.replace(",", ""))
	var sides := eq.split(" = ")
	var left := _eval(sides[0])
	var right := _eval(sides[1])
	if left.is_empty() or right.is_empty() or left[1] == 0 or right[1] == 0:
		return -1
	return 1 if left[0] * right[1] == right[0] * left[1] else 0


func test_the_evaluator() -> void:
	assert_eq(_holds("2/3 = ?/12", "8"), 1)
	assert_eq(_holds("2/3 = ?/12", "9"), 0)
	assert_eq(_holds("3/10 + 4/100 = ?/100", "34"), 1)
	assert_eq(_holds("5 × 1/4 = ?", "5/4"), 1)
	assert_eq(_holds("7/10 − 4/10 = ?", "3/10"), 1)
	assert_eq(_holds("3/5 = ? × 1/5", "3"), 1)
	assert_eq(_holds("2 + 3 × 4 = ?", "14"), 1)
	assert_eq(_holds("How many?", "3"), -1)


func test_every_generated_equation_holds() -> void:
	var checked := 0
	for gen in SchoolGen.ids():
		for level in [1, 2, 3]:
			for s in 40:
				var ex := SchoolGen.make(gen, s, level)
				if str(ex.type) != "number":
					continue
				var h := _holds(str(ex.prompt), str(ex.answer))
				if h >= 0:
					checked += 1
					assert_eq(h, 1, "%s: %s  answer %s" % [gen, ex.prompt, ex.answer])
	gut.p("%d equations checked" % checked)
	assert_gt(checked, 1500, "most number exercises are equations")


# --- Fractions and decimals ------------------------------------------------------------------------------------

func test_fraction_comparisons() -> void:
	_each("g4f.compare_fractions", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var cmp: int = int(d.a) * int(d.d) - int(d.c) * int(d.b)
		var right := ExerciseCheck.answer_text(ex)
		if cmp == 0:
			assert_eq(right, "They are equal")
		else:
			assert_eq(right, "%d/%d" % [d.a, d.b] if cmp > 0 else "%d/%d" % [d.c, d.d]))
	_each("g4f.benchmark_half", func(ex: Dictionary, _l: int) -> void:
		var twice := 2 * int(ex.data.a)
		var b: int = ex.data.b
		assert_eq(ExerciseCheck.answer_text(ex), "exactly 1/2" if twice == b else ("more than 1/2" if twice > b else "less than 1/2")))
	_each("g4f.is_equivalent", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(ex.answer, int(d.a) * int(d.d) == int(d.c) * int(d.b)))
	_each("g4f.compare_decimals", func(ex: Dictionary, _l: int) -> void:
		var x: int = ex.data.x
		var y: int = ex.data.y
		var right := ExerciseCheck.answer_text(ex)
		if x == y:
			assert_eq(right, "They are equal")
		else:
			assert_almost_eq(NumberAnswer.value(right), maxf(x, y) / 100.0, 0.0001))


func test_pictures_that_answer_the_question() -> void:
	_each("g4f.pick_picture", func(ex: Dictionary, _l: int) -> void:
		var pic: Dictionary = ex.choices[int(ex.answer)].picture
		assert_eq([int(pic.num), int(pic.den)], [int(ex.data.a), int(ex.data.b)])
		for c: Dictionary in ex.choices:
			if c != ex.choices[int(ex.answer)]:
				assert_ne(int(c.picture.num) * int(ex.data.b), int(ex.data.a) * int(c.picture.den), "no wrong wall is equal"))
	_each("g4f.decimal_on_line", func(ex: Dictionary, _l: int) -> void:
		assert_true(NumberAnswer.equal(str(ex.answer), str(ex.picture.dot))))


func test_fraction_sums_in_words() -> void:
	_each("g4f.mixed_to_fraction", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(int(ex.answer), int(d.w) * int(d.d) + int(d.a)))
	_each("g4f.add_mixed", func(ex: Dictionary, _l: int) -> void:
		var total: int = ex.data.total
		var den: int = ex.data.d
		var w := int(total / float(den))
		var r := total % den
		var want := str(w) if r == 0 else "%d %d/%d" % [w, r, den]
		assert_eq(ExerciseCheck.answer_text(ex), want))
	_each("g4f.decompose", func(ex: Dictionary, _l: int) -> void:
		for i in (ex.choices as Array).size():
			var sum := _eval(str(ex.choices[i]))
			var same: bool = sum[0] * int(ex.data.d) == int(ex.data.n) * sum[1]
			assert_eq(i == int(ex.answer), same, "%s: %s" % [ex.prompt, ex.choices[i]]))
	_each("g4f.times_between", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var v := float(int(d.n) * int(d.a)) / float(d.d)
		var words := ExerciseCheck.answer_text(ex).split(" and ")
		assert_true(v > float(words[0]) and v < float(words[1]), "%s: %s" % [ex.prompt, words]))
	_each("g4f.fraction_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var want := int(d.a) + int(d.b) if str(ex.prompt).contains("together") else int(d.b)
		assert_true(NumberAnswer.equal(str(ex.answer), "%d/%d" % [want, d.d])))
	_each("g4f.times_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(NumberAnswer.equal(str(ex.answer), "%d/%d" % [int(d.n) * int(d.a), d.d])))


func test_fraction_and_decimal_builds() -> void:
	_each("g4f.build_fraction", func(ex: Dictionary, _l: int) -> void:
		var cells := BuildCheck.example(ex.goal, ex.board)
		var d: Dictionary = ex.data
		assert_eq(cells.size() * int(d.d), int(d.total) * int(d.a)))
	_each("g4f.build_tenths", func(ex: Dictionary, _l: int) -> void:
		assert_eq(BuildCheck.example(ex.goal, ex.board).size(), int(ex.data.a) * int(ex.data.rows)))


func test_decimals_written_both_ways() -> void:
	_each("g4f.fraction_to_decimal", func(ex: Dictionary, _l: int) -> void:
		var p := str(ex.prompt).trim_prefix("Write ").trim_suffix(" as a decimal.")
		var parts := p.split(" ")
		var v := NumberAnswer.value(parts[0]) if parts.size() == 1 else float(parts[0]) + NumberAnswer.value(parts[1])
		assert_almost_eq(NumberAnswer.value(str(ex.answer)), v, 0.00001, p))


# --- Measurement, data and geometry ------------------------------------------------------------------------------

func test_conversions() -> void:
	_each("g4g.convert_units", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var n: int = d.n
		var k: int = d.k
		var p := str(ex.prompt)
		var want := 0
		match level:
			1:
				want = n * k
			2:
				want = n * k + int(p.split(" ")[2])
			_:
				var f := p.split(" ")[1]
				want = n * k + int(k * NumberAnswer.value(f))
		assert_eq(int(ex.answer), want, p))
	_each("g4g.conversion_table", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.answer), int(ex.data.k) * int(ex.data.ask)))


func test_measurement_stories_are_positive() -> void:
	_each("g4g.measure_story", func(ex: Dictionary, _l: int) -> void:
		assert_gt(int(ex.answer), 0, str(ex.prompt)))
	_each("g4g.time_story", func(ex: Dictionary, _l: int) -> void:
		var end: int = int(ex.data.start) + int(ex.data.minutes)
		var h := int(posmod(end, 720) / 60.0)
		assert_eq(ExerciseCheck.answer_text(ex), "%d:%02d" % [12 if h == 0 else h, end % 60]))


func test_area_and_perimeter() -> void:
	_each("g4g.area", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.answer), int(ex.data.w) * int(ex.data.h)))
	_each("g4g.perimeter", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.answer), 2 * (int(ex.data.w) + int(ex.data.h))))
	_each("g4g.missing_side", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.answer), int(ex.data.w)))
	_each("g4g.build_farm", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.goal.area), int(ex.data.w) * int(ex.data.h)))
	_each("g4g.same_area", func(ex: Dictionary, _l: int) -> void:
		var a: Array = ex.data.a
		var b: Array = ex.data.b
		var pa: int = 2 * (int(a[0]) + int(a[1]))
		var pb: int = 2 * (int(b[0]) + int(b[1]))
		assert_eq(int(a[0]) * int(a[1]), int(b[0]) * int(b[1]), "the same area")
		if str(ex.prompt).contains("same perimeter"):
			assert_eq(ex.answer, pa == pb)
		else:
			assert_eq(ex.answer, pa > pb))


func test_line_plots() -> void:
	_each("g4g.plot_read", func(ex: Dictionary, _l: int) -> void:
		var counts: Dictionary = ex.data.counts
		var total := 0
		for k: String in counts:
			total += int(counts[k])
		var p := str(ex.prompt)
		if p.contains("measured"):
			assert_eq(int(ex.answer), total)
		else:
			var k := p.trim_prefix("How many sticks are ").get_slice("/", 0)
			assert_eq(int(ex.answer), int(counts[k])))
	_each("g4g.plot_math", func(ex: Dictionary, _l: int) -> void:
		var counts: Dictionary = ex.data.counts
		var den: int = ex.data.den
		var keys: Array = counts.keys().map(func(k: String) -> int: return int(k))
		var p := str(ex.prompt)
		if p.contains("difference"):
			assert_true(NumberAnswer.equal(str(ex.answer), "%d/%d" % [keys.max() - keys.min(), den]))
		else:
			var k := p.trim_prefix("Pip lays all the ").get_slice("/", 0)
			assert_true(NumberAnswer.equal(str(ex.answer), "%d/%d" % [int(counts[k]) * int(k), den])))


func test_angles() -> void:
	_each("g4g.turn_degrees", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.has("t"):
			var t: Array = d.t
			assert_eq(int(ex.answer) * int(t[1]), 360 * int(t[0]))
		else:
			assert_eq(int(ex.answer) * int(d.deg), 360))
	_each("g4g.angle_add", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.answer), int(ex.data.a) + int(ex.data.b))
		assert_lte(int(ex.answer), 180))
	_each("g4g.angle_missing", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.answer), int(ex.data.whole) - int(ex.data.a))
		assert_gt(int(ex.answer), 0))
	_each("g4g.angle_read", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ExerciseCheck.answer_text(ex), "%d°" % int(ex.picture.deg)))
	_each("g4g.angle_kind", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ExerciseCheck.answer_text(ex), ShapeFacts.angle_kind(int(ex.data.deg))))


func test_shapes() -> void:
	_each("g4g.symmetry_count", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.answer), ShapeFacts.symmetry(str(ex.data.what))))
	_each("g4g.right_angle_count", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.answer), ShapeFacts.right_angles(str(ex.data.what))))
	_each("g4g.shape_name", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ExerciseCheck.answer_text(ex), ShapeFacts.name_of(str(ex.picture.what))))
	_each("g4g.line_kind", func(ex: Dictionary, _l: int) -> void:
		var what := str(ex.picture.what)
		for c: Variant in ex.choices:
			if what == "perpendicular":
				assert_ne(str(c), "intersecting lines", "perpendicular lines intersect too: never both"))
	_each("g4g.mirror_build", func(ex: Dictionary, _l: int) -> void:
		assert_eq(BuildCheck.problem(ex.goal, ex.board), ""))
