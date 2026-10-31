extends GutTest
## Owner #70, grade 3 maths (G3MathsGen "g3m", units 1-8; G3FractionsGen "g3f", units 9-12; G3MeasureGen "g3g", units
## 13-18): each generator's answer is
## worked out again here from the exercise's `data`, for many seeds and every level, and every exercise must be valid
## (ExerciseCheck, the picture's own check). The shared content test also runs them all through their checkers.

const SEEDS := 60


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			for p: Variant in _pictures(ex):
				assert_eq(SchoolPicture.problem(p), "", "%s: its picture %s" % [gen, p])
			assert_true(ex.has("data"), "%s keeps its inputs" % gen)
			check.call(ex, level)


func _pictures(ex: Dictionary) -> Array:
	var out: Array = []
	if ex.has("picture"):
		out.append(ex.picture)
	for c: Variant in ex.get("choices", []):
		if c is Dictionary and c.has("picture"):
			out.append(c.picture)
	return out


## True when the exercise's answer (a number, or the right choice's words) has the value num/den.
func _is(ex: Dictionary, num: int, den: int = 1) -> bool:
	var text := str(ex.answer) if str(ex.type) == "number" else ExerciseCheck.answer_text(ex)
	return NumberAnswer.equal(text.replace(",", ""), "%d/%d" % [num, den])


func _said(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


## A number sentence's value: "45 + 30 = ?" -> [45 + 30]; "a × b = c" -> true when it holds.
func _eval(text: String) -> int:
	var t := text.replace(",", "").strip_edges()
	for op: String in [" + ", " − ", " × ", " ÷ "]:
		var at := t.rfind(op)
		if at > 0:
			var a := _eval(t.left(at))
			var b := _eval(t.substr(at + op.length()))
			match op:
				" + ":
					return a + b
				" − ":
					return a - b
				" × ":
					return a * b
				_:
					return a / b if b != 0 and a % b == 0 else -99999
	return int(t)


func _holds(sentence: String) -> bool:
	var sides := sentence.split(" = ")
	return sides.size() == 2 and _eval(sides[0]) == _eval(sides[1])


func _roman(n: int) -> String:
	var out := ""
	for pair: Array in [[100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while n >= int(pair[0]):
			out += str(pair[1])
			n -= int(pair[0])
	return out


func _round(n: int, to: int) -> int:
	var lower := n - n % to
	return lower + to if n % to * 2 >= to else lower


# --- Unit 1: numbers to 10,000 -------------------------------------------------------------------------------------------

func test_place_value_blocks_and_expanded_form() -> void:
	_each("g3m.place_value", func(ex: Dictionary, _l: int) -> void:
		var s := str(ex.data.n)
		var place: int = ex.data.place
		assert_eq(_said(ex), GenKit.fmt(int(s[s.length() - 1 - place]) * int(pow(10, place))), str(ex.prompt)))
	_each("g3m.blocks_number", func(ex: Dictionary, _l: int) -> void:
		var p: Dictionary = ex.picture
		var n := int(p.thousands) * 1000 + int(p.hundreds) * 100 + int(p.tens) * 10 + int(p.ones)
		assert_eq(n, int(ex.data.n))
		assert_true(_is(ex, n + int(ex.data.add)), str(ex.prompt)))
	_each("g3m.expanded", func(ex: Dictionary, _l: int) -> void:
		var sum := 0
		for part in str(ex.prompt).trim_suffix(" = ?").split(" + "):
			sum += int(part.replace(",", ""))
		assert_eq(sum, int(ex.data.n), str(ex.prompt))
		assert_true(_is(ex, sum)))


func test_compare_order_and_round() -> void:
	_each("g3m.compare", func(ex: Dictionary, _l: int) -> void:
		var a: int = ex.data.a
		var b: int = ex.data.b
		assert_eq(_said(ex), "=" if a == b else (">" if a > b else "<")))
	_each("g3m.order_numbers", func(ex: Dictionary, _l: int) -> void:
		var shown: Array[int] = []
		for i: int in ex.answer:
			shown.append(int(str(ex.items[i]).replace(",", "")))
		var sorted := shown.duplicate()
		sorted.sort()
		if ex.data.greatest_first:
			sorted.reverse()
		assert_eq(shown, sorted, str(ex.prompt)))
	_each("g3m.round_number", func(ex: Dictionary, level: int) -> void:
		var n: int = ex.data.n
		var to: int = ex.data.to
		assert_true(_is(ex, _round(n, to)), "%d to %d" % [n, to])
		assert_true(to in [[10], [10, 100], [100, 1000]][level - 1], "the place suits the level"))


func test_roman_numerals() -> void:
	_each("g3m.roman", func(ex: Dictionary, level: int) -> void:
		var n: int = ex.data.n
		assert_lte(n, [20, 50, 100][level - 1])
		if ex.data.to_roman:
			assert_eq(_said(ex), _roman(n), str(ex.prompt))
		else:
			assert_true(_is(ex, n), str(ex.prompt))
			assert_true(str(ex.prompt).contains(_roman(n)), str(ex.prompt)))
	assert_eq(_roman(49), "XLIX")
	assert_eq(_roman(94), "XCIV")


# --- Unit 2: add and subtract ---------------------------------------------------------------------------------------------

func test_bonds_friendly_numbers_and_columns() -> void:
	_each("g3m.bond", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.total) - int(ex.data.a)), str(ex.prompt)))
	_each("g3m.mental", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.a) + int(d.b) if d.add else int(d.a) - int(d.b)), str(ex.prompt))
		assert_eq(_eval(str(ex.prompt).trim_suffix(" = ?")), int(str(ex.answer))))
	_each("g3m.column_add", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.a) + int(ex.data.b)), str(ex.prompt))
		assert_lte(int(ex.data.a) + int(ex.data.b), 10000, "to 10,000")
		assert_string_contains(str(ex.explain), GenKit.fmt(int(ex.data.a) + int(ex.data.b))))
	_each("g3m.column_subtract", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.a) - int(ex.data.b)), str(ex.prompt))
		assert_gt(int(ex.data.a) - int(ex.data.b), 0))


func test_checking_with_the_inverse_and_stories() -> void:
	var trues := 0
	for s in 60:
		var ex := SchoolGen.make("g3m.check_inverse", s, 2)
		trues += 1 if ex.answer else 0
	assert_between(trues, 12, 48, "both answers come up")
	_each("g3m.check_inverse", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var right := int(d.a) + int(d.b) if d.add else int(d.a) - int(d.b)
		assert_eq(ex.answer, int(d.claimed) == right, str(ex.prompt))
		assert_gte(int(d.claimed), 0))
	_each("g3m.add_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var right := int(d.a) + int(d.b) if d.add else int(d.a) - int(d.b)
		assert_true(_is(ex, right), str(ex.prompt))
		assert_gt(right, 0, str(ex.prompt))
		assert_lte(right, 10000, str(ex.prompt)))


# --- Unit 3: equal groups and arrays --------------------------------------------------------------------------------------

func test_equal_groups_and_arrays() -> void:
	_each("g3m.groups_total", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.groups) * int(ex.data.each)))
		assert_eq(int(ex.picture.groups), int(ex.data.groups))
		assert_eq(int(ex.picture.each), int(ex.data.each)))
	_each("g3m.groups_sentence", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_said(ex), "%d × %d" % [ex.data.groups, ex.data.each])
		for i in (ex.choices as Array).size():
			if i != int(ex.answer):
				assert_ne(str(ex.choices[i]), "%d × %d" % [ex.data.each, ex.data.groups], "never the turned-round fact as wrong"))
	_each("g3m.array_build", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.goal.rows), int(ex.data.rows))
		assert_eq(int(ex.goal.cols), int(ex.data.cols))
		assert_eq(BuildCheck.example(ex.goal, ex.board).size(), int(ex.data.rows) * int(ex.data.cols)))
	_each("g3m.repeated_add", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var right: int = [int(d.n), int(d.each), int(d.n) * int(d.each)][int(d.ask)]
		assert_true(_is(ex, right), str(ex.prompt))
		assert_eq(str(ex.prompt).count(" + "), int(d.n) - 1, "the number is added n times"))
	_each("g3m.groups_story", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.groups) * int(ex.data.each)), str(ex.prompt)))


# --- Unit 4: sharing and grouping -----------------------------------------------------------------------------------------

func test_sharing_grouping_and_the_unknown_number() -> void:
	_each("g3m.share", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.data.total) % int(ex.data.groups), 0)
		assert_true(_is(ex, int(ex.data.total) / int(ex.data.groups)), str(ex.prompt)))
	_each("g3m.grouping", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.total) / int(ex.data.size)), str(ex.prompt)))
	_each("g3m.divide_build", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.goal.rows) * int(ex.goal.cols), int(ex.data.total))
		assert_eq(int(ex.goal.rows), int(ex.data.rows)))
	_each("g3m.unknown_factor", func(ex: Dictionary, _l: int) -> void:
		assert_true(_holds(str(ex.prompt).replace("?", str(ex.answer))), str(ex.prompt)))
	_each("g3m.divide_story", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.total) / int(ex.data.by)), str(ex.prompt)))


func test_fact_families() -> void:
	_each("g3m.fact_family", func(ex: Dictionary, _l: int) -> void:
		for i in (ex.choices as Array).size():
			assert_eq(_holds(str(ex.choices[i])), i == int(ex.answer), "%s: %s" % [ex.prompt, ex.choices[i]])
		assert_eq(int(ex.data.a) * int(ex.data.b), int(ex.data.c)))


# --- Unit 5: times tables --------------------------------------------------------------------------------------------------

func test_times_and_division_facts() -> void:
	_each("g3m.times_fact", func(ex: Dictionary, level: int) -> void:
		assert_true(_is(ex, int(ex.data.a) * int(ex.data.b)))
		assert_eq(_eval(str(ex.prompt).trim_suffix(" = ?")), int(ex.answer))
		assert_lte(int(ex.data.b), 12)
		if level == 2:
			assert_true(int(ex.data.a) in [6, 7, 8, 9], "level 2: the tables of 6, 7, 8 and 9"))
	_each("g3m.divide_fact", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.b)))
		assert_eq(_eval(str(ex.prompt).trim_suffix(" = ?")), int(ex.answer)))


func test_the_times_grid_and_patterns() -> void:
	_each("g3m.grid_hidden", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.row) * int(ex.data.col)))
		assert_eq(ex.picture.hide, [[int(ex.data.row), int(ex.data.col)]]))
	_each("g3m.even_odd", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_said(ex), "even" if int(ex.data.a) * int(ex.data.b) % 2 == 0 else "odd"))
	_each("g3m.in_table", func(ex: Dictionary, _l: int) -> void:
		var t: int = ex.data.table
		for i in (ex.choices as Array).size():
			assert_eq(int(ex.choices[i]) % t == 0, i == int(ex.answer), "%s: %s" % [ex.prompt, ex.choices[i]]))
	_each("g3m.skip_count", func(ex: Dictionary, _l: int) -> void:
		var shown := str(ex.prompt).trim_prefix("What comes next?  ").trim_suffix(", ?").split(", ")
		var step := int(shown[1]) - int(shown[0])
		assert_eq(absi(step), int(ex.data.table))
		assert_true(_is(ex, int(shown[3]) + step), str(ex.prompt)))


# --- Unit 6: multiplying made easier ----------------------------------------------------------------------------------------

func test_swapping_splitting_and_grouping() -> void:
	_each("g3m.swap", func(ex: Dictionary, level: int) -> void:
		if level == 1:
			assert_true(_holds(str(ex.prompt).replace("?", str(ex.answer))), str(ex.prompt))
		else:
			assert_eq(ex.answer, _holds(str(ex.prompt)), str(ex.prompt)))
	_each("g3m.split", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if level == 3:
			for i in (ex.choices as Array).size():
				assert_eq(_eval(str(ex.choices[i])) == int(d.a) * int(d.b), i == int(ex.answer), str(ex.choices[i]))
		elif level == 2:
			var sides := str(ex.prompt).split(" = ")
			assert_eq(_eval(sides[0]), _eval(sides[1]), str(ex.prompt))
			assert_true(_is(ex, int(d.a) * int(d.b)), str(ex.prompt))
		else:
			assert_true(_holds(str(ex.prompt).replace("?", str(ex.answer))), str(ex.prompt)))
	_each("g3m.group_three", func(ex: Dictionary, _l: int) -> void:
		var nums: Array = ex.data.nums
		assert_true(_is(ex, int(nums[0]) * int(nums[1]) * int(nums[2]))))
	_each("g3m.split_area", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.a) * int(ex.data.b)))
		var cols: Array = ex.picture.cols
		assert_eq(int(cols[0]) + int(cols[1]), int(ex.data.b), "the parts make the side"))


# --- Unit 7: multiply and divide by one digit -------------------------------------------------------------------------------

func test_multiplying_and_dividing_by_one_digit() -> void:
	_each("g3m.times_tens", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.data.tens) % 10, 0)
		if str(ex.prompt).ends_with("= ?"):
			assert_true(_is(ex, int(ex.data.a) * int(ex.data.tens)), str(ex.prompt))
		else:
			assert_true(_holds(str(ex.prompt).replace("?", str(ex.answer))), str(ex.prompt)))
	_each("g3m.short_multiply", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.a) * int(ex.data.b)))
		assert_string_contains(str(ex.explain), GenKit.fmt(int(ex.data.a) * int(ex.data.b))))
	_each("g3m.short_divide", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.data.total) % int(ex.data.by), 0)
		assert_true(_is(ex, int(ex.data.total) / int(ex.data.by)), str(ex.prompt)))
	_each("g3m.remainder", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var q := int(d.total) / int(d.by)
		var left := int(d.total) % int(d.by)
		assert_gt(left, 0, "there is a remainder")
		assert_true(_is(ex, left if d.ask_left else q), str(ex.prompt)))
	_each("g3m.remainder_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var q := int(d.total) / int(d.by)
		var left := int(d.total) % int(d.by)
		assert_true(_is(ex, [q + 1, q, left][int(d.ask)]), str(ex.prompt)))


# --- Unit 8: two-step problems ------------------------------------------------------------------------------------------------

func test_two_step_stories() -> void:
	_each("g3m.two_step", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		var c := int(d.c)
		var right: int = [a + b - c, a * b + c, a * b - c, a / b - c if b > 0 else 0, a + (a - b),
			(a + b) / c if c > 0 else 0][int(d.kind)]
		assert_true(_is(ex, right), str(ex.prompt))
		assert_gt(right, 0, str(ex.prompt)))
	_each("g3m.letter_unknown", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var right: int = [int(d.result) - int(d.known), int(d.known) - int(d.result), int(d.result) / int(d.known),
			int(d.result) / int(d.known)][int(d.form)]
		assert_true(_is(ex, right), str(ex.prompt))
		var sentence := str(ex.prompt).get_slice(": ", 1).get_slice(". What", 0)
		if int(d.form) >= 2:
			sentence = str(ex.prompt).get_slice(". ", 1).get_slice(". What", 0) if int(d.form) == 2 else sentence
		assert_true(_holds(sentence.replace("n", str(right))), "%s -> %s" % [ex.prompt, sentence]))


func test_estimating_and_bar_models() -> void:
	_each("g3m.estimate_check", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var right := int(d.a) + int(d.b) if d.add else int(d.a) - int(d.b)
		assert_eq(ex.answer, int(d.claimed) == right, str(ex.prompt))
		if int(d.claimed) != right:
			assert_gte(absi(int(d.claimed) - right), 300, "far enough off for rounding to show it"))
	_each("g3m.model_sentence", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var right: String = ["%s + %s = ?" % [GenKit.fmt(int(d.a)), GenKit.fmt(int(d.b))],
			"%s − %s = ?" % [GenKit.fmt(int(d.a)), GenKit.fmt(int(d.b))], "%d × %d = ?" % [int(d.n), int(d.e)],
			"%s − %s = ?" % [GenKit.fmt(int(d.a)), GenKit.fmt(int(d.b))]][int(d.kind)]
		assert_eq(_said(ex), right, str(ex.picture)))


# --- Unit 9: fractions of a whole and of a set ------------------------------------------------------------------------------

func test_naming_and_picking_fractions() -> void:
	_each("g3f.name_fraction", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var p: Dictionary = ex.picture
		assert_eq(int(p.parts), int(d.den))
		assert_eq(int(p.shade), int(d.num))
		assert_false(p.get("unequal", false))
		assert_true(_is(ex, int(d.den) - int(d.num) if d.not_shaded else int(d.num), int(d.den)), str(ex.prompt)))
	_each("g3f.pick_picture", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		for i in (ex.choices as Array).size():
			var p: Dictionary = ex.choices[i].picture
			var shows: bool = int(p.parts) == int(d.den) and int(p.shade) == int(d.num) and not p.get("unequal", false)
			assert_eq(shows, i == int(ex.answer), "%s: %s" % [ex.prompt, p]))
	_each("g3f.fraction_of_set", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(int(d.total) % int(d.den), 0)
		assert_true(_is(ex, int(d.total) / int(d.den) * int(d.num)), str(ex.prompt)))


func test_equal_parts_and_building_fractions() -> void:
	_each("g3f.equal_parts", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if level == 1:
			assert_eq(ex.answer, not d.unequal)
		else:
			assert_eq(ex.answer, not d.unequal and int(d.claim) == int(d.parts), str(ex.prompt))
		assert_eq(bool(ex.picture.get("unequal", false)), bool(d.unequal)))
	_each("g3f.build_fraction", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(int(d.total) % int(d.den), 0, "the wall splits into equal parts")
		assert_eq(BuildCheck.example(ex.goal, ex.board).size(), int(d.total) / int(d.den) * int(d.num)))


# --- Unit 10: fractions on a number line -----------------------------------------------------------------------------------------

func test_fractions_on_the_line() -> void:
	_each("g3f.fraction_on_line", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, int(d.num), int(d.den)))
		assert_true(NumberAnswer.equal(str(ex.picture.dot), "%d/%d" % [d.num, d.den]), "the dot is the answer"))
	_each("g3f.jumps", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.num), int(ex.data.den)), str(ex.prompt)))
	_each("g3f.whole_as_fraction", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(_is(ex, [1, int(d.w), int(d.w), int(d.w) * int(d.den)][int(d.form)]), str(ex.prompt))
		var sides := str(ex.prompt).replace("?", str(ex.answer)).split(" = ")
		assert_true(NumberAnswer.equal(sides[0], sides[1]), str(ex.prompt)))
	_each("g3f.order_on_line", func(ex: Dictionary, _l: int) -> void:
		var last := -1.0
		for i: int in ex.answer:
			var v := NumberAnswer.value(str(ex.items[i]))
			assert_gt(v, last, str(ex.items))
			last = v)
	_each("g3f.compare_to_one", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.num
		var d: int = ex.data.den
		assert_eq(_said(ex), "equal to 1" if n == d else ("less than 1" if n < d else "more than 1")))


# --- Unit 11: equal fractions and comparing ---------------------------------------------------------------------------------------

func test_equal_fractions_and_comparing() -> void:
	_each("g3f.equivalent_missing", func(ex: Dictionary, _l: int) -> void:
		var sides := str(ex.prompt).replace("?", str(ex.answer)).split(" = ")
		assert_true(NumberAnswer.equal(sides[0], sides[1]), str(ex.prompt))
		if ex.has("picture"):
			var rows: Array = ex.picture.rows
			assert_true(NumberAnswer.equal("%d/%d" % [rows[0].shade, rows[0].den], "%d/%d" % [rows[1].shade, rows[1].den]),
				"the wall shows equal fractions"))
	_each("g3f.is_equivalent", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(ex.answer, int(d.a) * int(d.d) == int(d.b) * int(d.c), str(ex.prompt)))
	_each("g3f.compare_fractions", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var l := int(d.a) * int(d.d)
		var r := int(d.b) * int(d.c)
		assert_true(int(d.a) == int(d.c) or int(d.b) == int(d.d), "the same top or the same bottom")
		assert_eq(_said(ex), "=" if l == r else (">" if l > r else "<"), str(ex.prompt)))
	_each("g3f.add_same", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var top := int(d.a) + int(d.b) if d.add else int(d.a) - int(d.b)
		assert_gt(top, 0, str(ex.prompt))
		assert_true(_is(ex, top, int(d.den)), str(ex.prompt)))
	_each("g3f.order_unit_fractions", func(ex: Dictionary, _l: int) -> void:
		var last := -1.0
		for i: int in ex.answer:
			var v := NumberAnswer.value(str(ex.items[i]))
			assert_gt(v, last, str(ex.items))
			last = v)


# --- Unit 12: money ----------------------------------------------------------------------------------------------------------------

func test_money() -> void:
	_each("g3f.money_total", func(ex: Dictionary, _l: int) -> void:
		var total := 0
		for i in (ex.data.prices as Array).size():
			total += int(ex.data.prices[i]) * int(ex.data.qty[i])
		assert_true(_is(ex, total), str(ex.prompt)))
	_each("g3f.money_change", func(ex: Dictionary, _l: int) -> void:
		var spent := 0
		for p: int in ex.data.prices:
			spent += p
		assert_gt(int(ex.data.pay) - spent, 0, str(ex.prompt))
		assert_true(_is(ex, int(ex.data.pay) - spent), str(ex.prompt)))
	_each("g3f.can_afford", func(ex: Dictionary, _l: int) -> void:
		var spent := 0
		for p: int in ex.data.prices:
			spent += p
		assert_eq(ex.answer, int(ex.data.have) >= spent, str(ex.prompt)))
	_each("g3f.price_list", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var cost := int(d.qa) * int(d.prices[int(d.a)]) + int(d.prices[int(d.b)])
		assert_ne(int(d.a), int(d.b))
		assert_true(_is(ex, 100 - cost if level == 3 else cost), str(ex.prompt))
		if level == 3:
			assert_gt(100 - cost, 0))


# --- Unit 13: time --------------------------------------------------------------------------------------------------------------------

func _time(minutes: int, h24: bool) -> String:
	var h := int(minutes / 60.0) % 24
	return "%02d:%02d" % [h, minutes % 60] if h24 else "%d:%02d" % [(h + 11) % 12 + 1, minutes % 60]


func test_reading_clocks() -> void:
	_each("g3g.read_clock", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_said(ex), "%d:%02d" % [ex.picture.h, ex.picture.m]))
	_each("g3g.to_24h", func(ex: Dictionary, _l: int) -> void:
		var h: int = ex.data.h
		var m: int = ex.data.m
		if ex.data.to_24:
			assert_eq(_said(ex), "%02d:%02d" % [h, m], str(ex.prompt))
		else:
			var part := "in the morning" if h < 12 else ("in the afternoon" if h < 18 else "in the evening")
			assert_eq(_said(ex), "%d:%02d %s" % [(h + 11) % 12 + 1, m, part], str(ex.prompt)))


func test_how_long_and_when_it_ends() -> void:
	_each("g3g.duration", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.data.end) - int(ex.data.start)), str(ex.prompt)))
	_each("g3g.end_time", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(_said(ex), _time(int(d.start) + int(d.minutes), d.h24), str(ex.prompt)))
	_each("g3g.time_units", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(int(d.factor) in [60, 7, 12, 24])
		assert_true(_is(ex, int(d.a) * int(d.factor) + int(d.extra)), str(ex.prompt)))


# --- Unit 14: length, mass and volume ----------------------------------------------------------------------------------------------------

func test_converting_units() -> void:
	for gen: String in ["g3g.convert_length", "g3g.convert_mass_volume"]:
		_each(gen, func(ex: Dictionary, _l: int) -> void:
			var d: Dictionary = ex.data
			assert_true(int(d.factor) in [10, 100, 1000])
			if d.to_small:
				assert_true(_is(ex, int(d.a) * int(d.factor) + int(d.extra)), str(ex.prompt))
			else:
				assert_true(_is(ex, int(d.a)), str(ex.prompt))
				assert_string_contains(str(ex.prompt), GenKit.fmt(int(d.a) * int(d.factor))))


func test_reading_scales_jugs_and_rulers() -> void:
	_each("g3g.read_scale", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.picture.value)))
		assert_eq(int(ex.picture.value), int(ex.data.value))
		var small := float(ex.picture.step) / (int(ex.picture.get("minor", 0)) + 1)
		assert_almost_eq(fmod(float(ex.picture.value), small), 0.0, 0.001, "the needle is on a mark"))
	_each("g3g.read_jug", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.picture.fill)))
		var small := float(ex.picture.step) / (int(ex.picture.get("minor", 0)) + 1)
		assert_almost_eq(fmod(float(ex.picture.fill), small), 0.0, 0.001, "the water is at a mark"))
	_each("g3g.read_ruler", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(NumberAnswer.equal(str(ex.picture.length), "%d/10" % int(d.mm)), "the stick is as long as the answer")
		assert_true(_is(ex, int(d.mm) if d.in_mm else int(d.mm) / 10), str(ex.prompt))
		if not d.in_mm:
			assert_eq(int(d.mm) % 10, 0, "whole centimetres"))


func test_units_and_measuring_stories() -> void:
	_each("g3g.which_unit", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.estimate:
			assert_eq(_said(ex), str(G3MeasureGen.ESTIMATES[int(d.i)][1]))
		else:
			assert_eq(_said(ex), str(G3MeasureGen.UNIT_CHOICES[int(d.i)][1])))
	_each("g3g.measure_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var a := int(d.a)
		var b := int(d.b)
		var right: int = [a + b, a - b, a * b, a / b if b > 0 else 0, a - b][int(d.kind)]
		assert_true(_is(ex, right), str(ex.prompt))
		assert_gt(right, 0))


# --- Unit 15: area ------------------------------------------------------------------------------------------------------------------------

func _count(rows: Array) -> int:
	var n := 0
	for r: Variant in rows:
		n += str(r).length() - str(r).count(".")
	return n


func test_area() -> void:
	_each("g3g.count_squares", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, _count(ex.picture.rows))))
	_each("g3g.rect_area", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.picture.w) * int(ex.picture.h))))
	_each("g3g.area_build", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.goal.area), int(ex.data.area))
		assert_eq(BuildCheck.example(ex.goal, ex.board).size(), int(ex.data.area), "a farm that fits the board"))
	_each("g3g.l_area", func(ex: Dictionary, _l: int) -> void:
		var per := int(ex.data.per)
		assert_true(_is(ex, _count(ex.picture.rows) * per * per), str(ex.picture)))
	_each("g3g.missing_side_area", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, int(ex.picture.w)))
		assert_string_contains(str(ex.prompt), str(int(ex.picture.w) * int(ex.picture.h))))


# --- Unit 16: perimeter ------------------------------------------------------------------------------------------------------------------

func test_perimeter() -> void:
	_each("g3g.rect_perimeter", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, 2 * (int(ex.data.w) + int(ex.data.h)))))
	_each("g3g.polygon_perimeter", func(ex: Dictionary, _l: int) -> void:
		var total := 0
		for label: Variant in ex.picture.labels:
			total += int(str(label).get_slice(" ", 0))
		assert_eq((ex.picture.labels as Array).size(), ShapeFacts.sides(str(ex.data.what)))
		assert_true(_is(ex, total), str(ex.picture)))
	_each("g3g.missing_side", func(ex: Dictionary, _l: int) -> void:
		var sides: Array = ex.data.sides
		var total := 0
		for s: int in sides:
			total += s
		assert_string_contains(str(ex.prompt), "is %d " % total)
		assert_eq(str(ex.picture.labels[int(ex.data.hide)]), "?")
		assert_true(_is(ex, int(sides[int(ex.data.hide)]))))
	_each("g3g.grid_perimeter", func(ex: Dictionary, _l: int) -> void:
		var total := 0
		for s: Dictionary in SchoolPictureG3.square_sides(ex.picture.rows):
			total += int(s.len)
		assert_true(_is(ex, total * int(ex.data.per)), str(ex.picture)))
	_each("g3g.same_perimeter", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if level == 1:
			var p := 2 * (int(d.w) + int(d.h))
			for i in (ex.choices as Array).size():
				var t := str(ex.choices[i]).replace(" m", "").split(" by ")
				assert_eq(2 * (int(t[0]) + int(t[1])) == p, i == int(ex.answer), str(ex.choices[i]))
		elif level == 2:
			assert_eq(2 * (int(d.w) + int(d.h)), 2 * (int(d.w2) + int(d.h2)), "the same perimeter")
			assert_eq(ex.answer, int(d.w) * int(d.h) == int(d.w2) * int(d.h2))
		else:
			var cells := BuildCheck.example(ex.goal, ex.board)
			assert_eq(cells.size(), int(d.w) * int(d.h), "a farm with that area and fence fits the board"))


# --- Unit 17: shapes, lines and right angles ------------------------------------------------------------------------------------------------

func test_shapes_and_their_facts() -> void:
	_each("g3g.name_shape", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_said(ex), str(ex.data.name))
		var p: Dictionary = ex.picture
		if str(p.kind) == "shape" and not str(p.what).begins_with("triangle"):
			assert_eq(str(ex.data.name), ShapeFacts.name_of(str(p.what))))
	_each("g3g.shape_true", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if str(d.fact) == "family":
			return
		var truth := ShapeFacts.sides(str(d.what))
		if str(d.fact) == "right angles":
			truth = ShapeFacts.right_angles(str(d.what))
		elif str(d.fact) == "pairs of parallel sides":
			truth = ShapeFacts.parallel_pairs(str(d.what))
		assert_eq(ex.answer, int(d.n) == truth, str(ex.prompt)))
	_each("g3g.right_angles", func(ex: Dictionary, _l: int) -> void:
		assert_true(_is(ex, ShapeFacts.right_angles(str(ex.data.what)))))
	_each("g3g.angle_size", func(ex: Dictionary, _l: int) -> void:
		var deg: int = ex.data.deg
		var k := 0 if deg < 90 else (1 if deg == 90 else 2)
		assert_true(_said(ex) in [G3MeasureGen.ANGLE_WORDS[k], G3MeasureGen.ANGLE_NAMES[k]], str(deg))
		assert_true(deg == 90 or absi(deg - 90) >= 20, "never too close to a right angle to see"))
	_each("g3g.lines_kind", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_said(ex), "%s lines" % ex.data.what)
		if str(ex.data.what) == "perpendicular":
			assert_false((ex.choices as Array).has("intersecting lines"), "perpendicular lines also intersect"))
	_each("g3g.cut_fraction", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.picture.parts), int(ex.data.parts))
		assert_true(_is(ex, 1, int(ex.data.parts))))


# --- Unit 18: graphs ------------------------------------------------------------------------------------------------------------------------

func test_pictograms() -> void:
	_each("g3g.pictogram_read", func(ex: Dictionary, _l: int) -> void:
		var rows: Array = ex.picture.rows
		assert_true(_is(ex, int(rows[int(ex.data.i)][1])))
		assert_string_contains(str(ex.prompt), str(rows[int(ex.data.i)][0])))
	_each("g3g.pictogram_compare", func(ex: Dictionary, _l: int) -> void:
		var rows: Array = ex.picture.rows
		var d: Dictionary = ex.data
		if int(d.a) < 0:
			var total := 0
			for r: Array in rows:
				total += int(r[1])
			assert_true(_is(ex, total))
		else:
			assert_true(_is(ex, int(rows[int(d.a)][1]) - int(rows[int(d.b)][1])))
			assert_gt(int(rows[int(d.a)][1]), int(rows[int(d.b)][1]), "more than"))


func test_bar_graphs() -> void:
	_each("g3g.bar_read", func(ex: Dictionary, _l: int) -> void:
		var bars: Array = ex.picture.bars
		assert_true(_is(ex, int(bars[int(ex.data.i)][1]))))
	_each("g3g.bar_compare", func(ex: Dictionary, level: int) -> void:
		var values: Array[int] = []
		for b: Array in ex.picture.bars:
			values.append(int(b[1]))
		var most: int = values.max()
		var least: int = values.min()
		assert_eq(values.count(most), 1, "one bar is the tallest")
		if level == 1:
			for b: Array in ex.picture.bars:
				if int(b[1]) == most:
					assert_eq(_said(ex), str(b[0]))
		elif level == 2:
			assert_true(_is(ex, most - least))
		else:
			var total := 0
			for v in values:
				total += v
			assert_true(_is(ex, total)))
	_each("g3g.bar_pick", func(ex: Dictionary, _l: int) -> void:
		var values: Array = ex.data.values
		for i in (ex.choices as Array).size():
			var shown: Array = []
			for b: Array in ex.choices[i].picture.bars:
				shown.append(int(b[1]))
			assert_eq(shown == values, i == int(ex.answer), str(shown)))


func test_line_plots() -> void:
	_each("g3g.plot_read", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var counts := {}
		for k: Variant in ex.picture.counts:
			counts[SchoolPictureG3.quarters_of(str(k))] = int(ex.picture.counts[k])
		if int(d.ask) == 0:
			assert_true(_is(ex, int(counts.get(int(d.at), 0))), str(ex.prompt))
		elif int(d.ask) == 1:
			var best := -1
			for q: int in counts:
				if best < 0 or counts[q] > counts[best]:
					best = q
			var ties := 0
			for q: int in counts:
				ties += 1 if counts[q] == counts[best] else 0
			assert_eq(ties, 1, "one length is the most common")
			assert_eq(_said(ex), "%s cm" % SchoolPictureG3.quarter_text(best))
		else:
			var n := 0
			for q: int in counts:
				n += counts[q] if q > int(d.at) else 0
			assert_true(_is(ex, n), str(ex.prompt)))
	_each("g3g.plot_pick", func(ex: Dictionary, _l: int) -> void:
		var want := {}
		for q: int in ex.data.lengths:
			var key := SchoolPictureG3.quarter_text(q)
			want[key] = int(want.get(key, 0)) + 1
		for i in (ex.choices as Array).size():
			var got: Dictionary = ex.choices[i].picture.counts
			assert_eq(got == want, i == int(ex.answer), str(got)))


func test_every_grade_3_maths_generator_is_tested_here() -> void:
	var text := FileAccess.get_file_as_string("res://tests/unit/test_g3_maths_gen.gd")
	for id in SchoolGen.ids():
		if id.get_slice(".", 0) in ["g3m", "g3f", "g3g"]:   # the other grade 3 sources are tested in their own files
			assert_string_contains(text, "\"%s\"" % id, "%s has a test" % id)
