extends GutTest
## Owner #68, grade 5 maths units 13-16 (G5MeasureGen, "g5m"): volume, converting units and line plots, the coordinate
## grid, shape families. Each generator's answer is worked out again here from the exercise's `data`, for many seeds and
## every level, and every exercise must be valid (ExerciseCheck, the picture's own check).

const SEEDS := 80


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % gen)
			check.call(ex, level)


## True when the exercise's answer (a number, or the right choice's words) has the value num/den.
func _is(ex: Dictionary, num: int, den: int = 1) -> bool:
	var text := str(ex.answer) if str(ex.type) == "number" else ExerciseCheck.answer_text(ex)
	var g := NumberAnswer.gcd(absi(num), den)
	return NumberAnswer.equal(text, "%d/%d" % [num / g, den / g])


# --- Unit 13: volume -------------------------------------------------------------------------------------------------

func test_counting_cubes_adds_every_box() -> void:
	_each("g5m.cube_count", func(ex: Dictionary, level: int) -> void:
		var total := 0
		for b: Array in ex.data.boxes:
			total += int(b[0]) * int(b[1]) * int(b[2])
		assert_true(_is(ex, total), str(ex.prompt))
		assert_eq(str(ex.picture.kind), "cubes")
		assert_eq((ex.picture.boxes as Array).size(), (ex.data.boxes as Array).size(), "the picture shows every box")
		if level == 3:
			assert_eq((ex.data.boxes as Array).size(), 2, "level 3 adds two boxes"))


func test_the_volume_formula_and_its_missing_side() -> void:
	_each("g5m.volume_formula", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var v := int(d.l) * int(d.w) * int(d.h)
		if str(d.unknown) == "":
			assert_true(_is(ex, v), str(ex.prompt))
		else:
			assert_eq(str(d.unknown), "h", "the missing side is the height")
			assert_true(_is(ex, int(d.h)), str(ex.prompt))
			assert_true(str(ex.prompt).contains(str(v)), "the prompt gives the volume"))


func test_a_volume_claim_is_true_only_when_it_is_right() -> void:
	_each("g5m.volume_check", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(ex.answer, int(d.claimed) == int(d.l) * int(d.w) * int(d.h), str(ex.prompt)))
	var trues := 0
	for s in 40:
		if SchoolGen.make("g5m.volume_check", s, 2).answer == true:
			trues += 1
	assert_between(trues, 8, 32, "true and false both come up")


# --- Unit 14: converting units and line plots --------------------------------------------------------------------------

func test_converting_units_multiplies_or_divides_by_the_factor() -> void:
	_each("g5m.change_units", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_true(int(d.factor) in [10, 100, 1000], "a metric factor")
		if d.to_small:
			assert_true(_is(ex, int(d.small)), str(ex.prompt))
		else:
			assert_true(_is(ex, int(d.small), int(d.factor)), str(ex.prompt)))


func test_the_biggest_amount_is_the_answer() -> void:
	_each("g5m.compare_units", func(ex: Dictionary, _l: int) -> void:
		var amounts: Array = ex.data.small
		var best := 0
		for i in amounts.size():
			if int(amounts[i]) > int(amounts[best]):
				best = i
		var seen := {}
		for a: Variant in amounts:
			assert_false(seen.has(int(a)), "no two amounts are the same")
			seen[int(a)] = true
		assert_eq(ExerciseCheck.answer_text(ex), str(ex.data.words[best]), str(ex.prompt)))


func test_a_line_plot_total_or_fair_share() -> void:
	_each("g5m.plot_total", func(ex: Dictionary, _l: int) -> void:
		var num := 0
		var den := 1
		for f: Array in ex.data.parts:
			num = num * int(f[1]) + int(f[0]) * den
			den *= int(f[1])
		den *= int(ex.data.get("share", 1))
		assert_true(_is(ex, num, den), str(ex.prompt)))


# --- Unit 15: the coordinate grid --------------------------------------------------------------------------------------

func test_tapping_a_point() -> void:
	_each("g5m.plot_point", func(ex: Dictionary, _l: int) -> void:
		assert_eq(str(ex.type), "point")
		assert_eq(GridCheck.point(ex.answer), Vector2i(int(ex.data.x), int(ex.data.y)))
		assert_true(str(ex.prompt).contains("(%d, %d)" % [ex.data.x, ex.data.y]), str(ex.prompt)))


func test_moving_a_point() -> void:
	_each("g5m.move_point", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		assert_eq(GridCheck.point(ex.answer), Vector2i(int(d.x) + int(d.dx), int(d.y) + int(d.dy)), str(ex.prompt)))


func test_reading_a_point() -> void:
	_each("g5m.read_point", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ExerciseCheck.answer_text(ex), "(%d, %d)" % [ex.data.x, ex.data.y])
		var shown: Array = ex.picture.points
		assert_eq(Vector2i(int(shown[0].x), int(shown[0].y)), Vector2i(int(ex.data.x), int(ex.data.y)), "the picture shows the point"))


func test_two_rules_and_their_pairs() -> void:
	_each("g5m.two_rules", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if level < 3:
			assert_true(_is(ex, int(d.b) * int(d.n)), str(ex.prompt))
		else:
			assert_eq(ExerciseCheck.answer_text(ex), "%d times" % (int(d.b) / int(d.a)), str(ex.prompt))
			assert_eq(int(d.b) % int(d.a), 0, "B's step is a multiple of A's"))


# --- Unit 16: shape families -------------------------------------------------------------------------------------------

func test_every_x_is_a_y_follows_the_family_tree() -> void:
	_each("g5m.family_true", func(ex: Dictionary, _l: int) -> void:
		var verdict := ShapeFamily.is_a(str(ex.data.x), str(ex.data.y))
		assert_ne(verdict, ShapeFamily.DEPENDS, "never asks what books disagree on")
		assert_eq(ex.answer, verdict == ShapeFamily.ALWAYS, str(ex.prompt)))


func test_the_shape_that_always_has_the_property() -> void:
	_each("g5m.family_property", func(ex: Dictionary, _l: int) -> void:
		var prop := str(ex.data.property)
		for i in (ex.choices as Array).size():
			assert_eq(i == int(ex.answer), ShapeFamily.has(ExerciseCheck.item_text(ex.choices[i]), prop),
				"%s: %s" % [ex.prompt, ex.choices[i]]))


func test_naming_a_triangle() -> void:
	_each("g5m.triangle_kind", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		var want := ""
		if d.has("sides"):
			var s: Array = d.sides
			var pairs := int(s[0] == s[1]) + int(s[1] == s[2]) + int(s[0] == s[2])
			want = "equilateral" if pairs == 3 else ("isosceles" if pairs == 1 else "scalene")
		else:
			var a: Array = d.angles
			assert_eq(int(a[0]) + int(a[1]) + int(a[2]), 180, "the angles make 180°")
			var big := maxi(int(a[0]), maxi(int(a[1]), int(a[2])))
			want = "right" if big == 90 else ("obtuse" if big > 90 else "acute")
		assert_eq(ExerciseCheck.answer_text(ex), want, str(ex.prompt)))


# --- The units -----------------------------------------------------------------------------------------------------------

func test_grade_5_maths_is_written_for_every_unit() -> void:
	var written := 0
	for u: Dictionary in Curriculum.units(5, "maths"):
		if u.has("file"):   # the research's new units (owner #73) are written next
			assert_true(Curriculum.has_content(str(u.id)), "%s is written" % u.id)
			written += 1
	assert_gte(written, 16, "grade 5's 16 maths units of 2026-09-28")
