extends GutTest
## Owner #68 (grade 4 maths): the generators' answers checked against arithmetic done here, from each exercise's `data`
## (its inputs), for many seeds and every level. The content test checks that every exercise is valid and right by its
## own answer; this one checks that the answer is the right one.

const SEEDS := 80


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), gen)
			check.call(ex, level)


func _value(ex: Dictionary) -> int:
	return int(str(ex.answer).replace(",", ""))


func _choice_text(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


func test_digit_value() -> void:
	_each("g4m.digit_value", func(ex: Dictionary, _l: int) -> void:
		var s := str(ex.data.n)
		var place: int = ex.data.place
		var d := int(s[s.length() - 1 - place])
		assert_eq(_choice_text(ex), GenKit.fmt(d * int(pow(10, place))), str(ex.prompt)))


func test_expanded_and_blocks_give_the_number() -> void:
	_each("g4m.expanded_form", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_value(ex), int(ex.data.n))
		var sum := 0
		for part in str(ex.prompt).trim_suffix(" = ?").split(" + "):
			sum += int(part.replace(",", ""))
		assert_eq(sum, int(ex.data.n), str(ex.prompt)))
	_each("g4m.blocks_number", func(ex: Dictionary, _l: int) -> void:
		var p: Dictionary = ex.picture
		assert_eq(_value(ex), int(p.thousands) * 1000 + int(p.hundreds) * 100 + int(p.tens) * 10 + int(p.ones)))


func test_number_words_names_the_number() -> void:
	_each("g4m.number_words", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_choice_text(ex), GenKit.fmt(int(ex.data.n)))
		assert_string_contains(str(ex.prompt), NumberWords.say(int(ex.data.n))))


func test_compare_and_order() -> void:
	_each("g4m.compare", func(ex: Dictionary, _l: int) -> void:
		var a: int = ex.data.a
		var b: int = ex.data.b
		assert_eq(_choice_text(ex), "=" if a == b else (">" if a > b else "<")))
	_each("g4m.order_numbers", func(ex: Dictionary, _l: int) -> void:
		var shown: Array = []
		for i: int in ex.answer:
			shown.append(int(str(ex.items[i]).replace(",", "")))
		var sorted := shown.duplicate()
		sorted.sort()
		assert_eq(shown, sorted))


func test_rounding() -> void:
	_each("g4m.round_to", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		var p := int(pow(10, int(ex.data.place)))
		assert_eq(_value(ex), int(floor(n / float(p) + 0.5)) * p, str(ex.prompt))
		assert_lte(_value(ex), 1_000_000))
	_each("g4m.round_true_false", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		var p := int(pow(10, int(ex.data.place)))
		var claimed := int(str(ex.prompt).get_slice(" is ", 1).trim_suffix(".").replace(",", ""))
		assert_eq(ex.answer, claimed == int(floor(n / float(p) + 0.5)) * p, str(ex.prompt)))


func test_adding_and_taking_away() -> void:
	_each("g4m.add_big", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_value(ex), int(ex.data.a) + int(ex.data.b))
		assert_lte(_value(ex), 1_000_000))
	_each("g4m.sub_big", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_value(ex), int(ex.data.a) - int(ex.data.b))
		assert_gt(_value(ex), 0))
	_each("g4m.missing_addend", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_value(ex) + int(ex.data.a), int(ex.data.total)))
	_each("g4m.add_sub_story", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var v := _value(ex)
		if d.has("c"):
			assert_eq(v, int(d.a) - int(d.b) - int(d.c))
		else:
			assert_true(v == int(d.a) + int(d.b) or v == int(d.a) - int(d.b), str(ex.prompt))
		assert_gt(v, 0, str(ex.prompt)))


func test_times_as_many() -> void:
	_each("g4m.times_as_many", func(ex: Dictionary, level: int) -> void:
		var n: int = ex.data.n
		var t: int = ex.data.times
		assert_eq(_value(ex), [0, n * t, n, t][level]))
	_each("g4m.build_times", func(ex: Dictionary, _l: int) -> void:
		assert_eq(int(ex.goal.rows), int(ex.data.n) * int(ex.data.k)))


func test_multiplying_and_dividing() -> void:
	for gen: String in ["g4m.mult_tens", "g4m.mult_1digit", "g4m.mult_2x2"]:
		_each(gen, func(ex: Dictionary, _l: int) -> void:
			assert_eq(_value(ex), int(ex.data.a) * int(ex.data.b)))
	_each("g4m.mult_story", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_value(ex), int(ex.data.per) * int(ex.data.n)))
	_each("g4m.div_exact", func(ex: Dictionary, _l: int) -> void:
		assert_eq(_value(ex) * int(ex.data.b), int(ex.data.a))
		assert_lt(int(ex.data.a), 10_000, "at most four digits"))
	_each("g4m.div_remainder", func(ex: Dictionary, _l: int) -> void:
		var a: int = ex.data.a
		var b: int = ex.data.b
		assert_eq(_choice_text(ex), "%d remainder %d" % [int(a / float(b)), a % b])
		assert_lt(a, 10_000))


func test_remainders_in_stories() -> void:
	_each("g4m.remainder_story", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		var b: int = ex.data.b
		var q := int(n / float(b))
		var p := str(ex.prompt)
		if p.contains("needed"):
			assert_eq(_value(ex), q + 1)
		elif p.contains("full"):
			assert_eq(_value(ex), q)
		else:
			assert_eq(_value(ex), n % b))


func test_factors_multiples_and_primes() -> void:
	_each("g4m.is_factor", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ex.answer, int(ex.data.n) % int(ex.data.f) == 0))
	_each("g4m.not_factor", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		for i in (ex.choices as Array).size():
			assert_eq(i == int(ex.answer), n % int(ex.choices[i]) != 0, "%s: %s" % [ex.prompt, ex.choices[i]]))
	_each("g4m.is_multiple", func(ex: Dictionary, _l: int) -> void:
		var k: int = ex.data.k
		for i in (ex.choices as Array).size():
			assert_eq(i == int(ex.answer), int(ex.choices[i]) % k == 0))
	_each("g4m.prime_composite", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		var count := 0
		for f in range(1, n + 1):
			if n % f == 0:
				count += 1
		assert_eq(_choice_text(ex), "prime" if count == 2 else "composite", str(n)))
	_each("g4m.factor_pairs_count", func(ex: Dictionary, _l: int) -> void:
		var n: int = ex.data.n
		var pairs := 0
		for f in range(1, n + 1):
			if n % f == 0 and f * f <= n:
				pairs += 1
		assert_eq(_value(ex), pairs))


func test_patterns() -> void:
	_each("g4m.next_term", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if d.has("terms"):
			var t: Array = d.terms
			var step: int = t[1] - t[0]
			var ratio := float(t[1]) / float(t[0])
			var next: int = t[3] + step if t[2] - t[1] == step else int(t[3] * ratio)
			assert_eq(_value(ex), next, str(ex.prompt))
		else:
			assert_eq(_value(ex), int(d.start) + (int(d.nth) - 1) * int(d.step)))
	_each("g4m.tower_pattern", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(_value(ex), int(d.start) + (int(d.ask) - 1) * int(d.step)))
	_each("g4m.odd_even_pattern", func(ex: Dictionary, _l: int) -> void:
		var start: int = ex.data.start
		var step: int = ex.data.step
		var parities := {}
		for i in 6:
			parities[(start + i * step) % 2] = true
		var p := str(ex.prompt)
		if p.contains("take turns"):
			assert_eq(ex.answer, parities.size() == 2)
		elif p.contains("be odd"):
			assert_eq(ex.answer, parities.size() == 1 and start % 2 == 1)
		else:
			assert_eq(ex.answer, parities.size() == 1 and start % 2 == 0))
