extends GutTest
## Owner #122 (docs/design/learning-is-play.md §5.1, Make it): a number answer is made with the world's things, and the
## made value is their exact sum: a tower of cubes (to 20), base-ten blocks (and tenths, hundredths, thousandths),
## coins for gold, cups in a jug for millilitres, weights on a scale for grams, fraction bars, a frog's jumps for
## negatives, and the machine's keys when nothing else fits. ExerciseCheck referees the sum's text.


func _ex(answer: String, prompt: String = "How many?") -> Dictionary:
	return {"type": "number", "prompt": prompt, "answer": answer, "hint": "Count."}


func test_the_maker_fits_the_answer() -> void:
	assert_eq(PlayMake.maker(_ex("12")), "tower")
	assert_eq(PlayMake.maker(_ex("0")), "tower")
	assert_eq(PlayMake.maker(_ex("347")), "base_ten")
	assert_eq(PlayMake.maker(_ex("3.75")), "base_ten", "decimals: tenths and hundredths")
	assert_eq(PlayMake.maker(_ex("35", "Tilly pays 65 gold from 100 gold. How much change?")), "coins")
	assert_eq(PlayMake.maker(_ex("750", "How many ml are left in the jug?")), "jug")
	assert_eq(PlayMake.maker(_ex("450", "The cake weighs how many g?")), "scale")
	assert_eq(PlayMake.maker(_ex("3/4")), "fraction")
	assert_eq(PlayMake.maker(_ex("-12")), "frog")
	assert_eq(PlayMake.maker(_ex("9999999")), "dial", "too many blocks: the machine's keys")
	assert_eq(PlayMake.maker(_ex("2/97")), "dial")


func test_a_unit_s_maker_is_used_when_it_fits() -> void:
	assert_eq(PlayMake.maker(_ex("12"), "coins"), "coins")
	assert_eq(PlayMake.maker(_ex("3/4"), "coins"), "fraction", "coins can't make a fraction")


func test_the_pieces_offered() -> void:
	assert_eq(PlayMake.pieces(_ex("12"), "tower"), ["1"] as Array[String])
	assert_eq(PlayMake.pieces(_ex("347"), "base_ten"), ["1000", "100", "10", "1"] as Array[String],
		"one place more than the answer needs, so its size is not given away")
	assert_eq(PlayMake.pieces(_ex("3.75"), "base_ten"), ["10", "1", "0.1", "0.01"] as Array[String])
	assert_true(PlayMake.pieces(_ex("35"), "coins").has("20"))
	assert_true(PlayMake.pieces(_ex("-12"), "frog").has("-10"))
	var bars := PlayMake.pieces(_ex("3/4"), "fraction")
	assert_true(bars.has("1/4"))
	assert_gte(bars.size(), 3, "more than one size of bar: choosing the size is part of it")


func test_the_made_value_is_the_exact_sum() -> void:
	assert_eq(PlayMake.total(["100", "100", "100", "10", "10", "10", "10", "1", "1", "1", "1", "1", "1", "1"]), "347")
	assert_eq(PlayMake.total(["1/2", "1/4"]), "3/4")
	assert_eq(PlayMake.total(["1", "0.1", "0.1", "0.01"]), "1.21")
	assert_eq(PlayMake.total(["-10", "-1", "-1"]), "-12")
	assert_eq(PlayMake.total([]), "0")
	assert_true(ExerciseCheck.is_right(_ex("3/4"), PlayMake.total(["1/4", "1/4", "1/4"])))
	assert_true(ExerciseCheck.is_right(_ex("0.75"), PlayMake.total(["0.1", "0.1", "0.1", "0.1", "0.1", "0.1", "0.1",
		"0.01", "0.01", "0.01", "0.01", "0.01"])))


func test_a_right_build_is_made_from_the_pieces() -> void:
	for a: String in ["12", "347", "3.75", "-12", "3/4", "7/4", "35", "0"]:
		var ex := _ex(a)
		var m := PlayMake.maker(ex)
		var build := PlayMake.decompose(a, PlayMake.pieces(ex, m))
		assert_true(ExerciseCheck.is_right(ex, PlayMake.total(build)), "%s with %s: %s" % [a, m, build])
		for p in build:
			assert_true(PlayMake.pieces(ex, m).has(p), "%s is offered" % p)


func test_the_ghost_does_one_step_towards_the_answer() -> void:
	var pieces := PlayMake.pieces(_ex("347"), "base_ten")
	assert_eq(PlayMake.ghost_step("347", pieces, []), {"add": "100"})
	assert_eq(PlayMake.ghost_step("347", pieces, ["100", "100", "100", "10", "10", "10", "10", "1", "1", "1", "1", "1", "1"]),
		{"add": "1"})
	assert_eq(PlayMake.ghost_step("347", pieces, ["1000"]), {"remove": "1000"}, "too much: one comes off")
	assert_eq(PlayMake.ghost_step("12", ["1"], ["1"].duplicate()), {"add": "1"})


func test_the_world_says_too_much_or_too_little() -> void:
	assert_eq(PlayMake.compare(["10", "1"], _ex("12")), -1)
	assert_eq(PlayMake.compare(["10", "1", "1"], _ex("12")), 0)
	assert_eq(PlayMake.compare(["10", "10"], _ex("12")), 1)


func test_the_machines_keys_type_any_number() -> void:
	var ex := _ex("-2/97")
	assert_eq(PlayMake.keys(ex), ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "/", "-", NumberPad.DELETE] as Array[String])
	var typed := ""
	for k in ["-", "2", "/", "9", "7"]:
		typed = PlayMake.type_key(typed, k, ex)
	assert_eq(typed, "-2/97")
	assert_true(ExerciseCheck.is_right(ex, typed))


func test_every_number_in_the_school_can_be_made() -> void:
	var n := 0
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				for ex: Dictionary in Curriculum.content(str(u.id)).get("exercises", []):
					if str(ex.type) != "number":
						continue
					n += 1
					var m := PlayMake.maker(ex)
					if m == "dial":
						continue
					var build := PlayMake.decompose(str(ex.answer), PlayMake.pieces(ex, m))
					assert_true(ExerciseCheck.is_right(ex, PlayMake.total(build)), "%s (%s): %s" % [ex.id, m, ex.answer])
					assert_lte(build.size(), PlayMake.MAX_PIECES, "%s fits the place" % ex.id)
	assert_gt(n, 2000)
	Curriculum.clear_cache()
