extends GutTest
## Owner #70 (2026-09-29: "start from grade 3 and finish all grades accordingly"): grade 3's maths is written for every
## unit of its outline (Common Core 3.OA, 3.NBT, 3.NF, 3.MD, 3.G). Every unit has a lesson of 3 or more cards, at least
## 12 hand-written exercises at levels 1, 2 and 3 in two or more kinds, its own generators (G3MathsGen "g3m",
## G3FractionsGen "g3f", G3MeasureGen "g3g") for endless practice, and rounds that fill at every star count and vary.
## (Every exercise's validity, answers, pictures and words are the shared content test's, test_school_content.gd.)

const GRADE := 3
const UNITS := 18


func test_grade_3_maths_is_written_for_every_unit() -> void:
	var units := Curriculum.units(GRADE, "maths")
	assert_eq(units.size(), UNITS, "the outline's %d maths units" % UNITS)
	for u: Dictionary in units:
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
		assert_gte((c.exercises as Array).size(), 12, "%s: 12 or more hand-written exercises" % id)
		var levels := {}
		var written_types := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.level)] = true
			written_types[str(ex.type)] = true
		assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
		assert_gte(written_types.size(), 2, "%s: two or more kinds of hand-written exercise" % id)
		assert_false((c.generators as Array).is_empty(), "%s: generators for endless practice" % id)
		var types := {}
		var distinct := {}
		for stars in [0, 1, 2]:
			for s in 20:
				var round := RoundPlan.plan(c, s * 7 + stars, stars)
				assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
				for ex in round:
					types[str(ex.type)] = true
					distinct[str(ex.prompt) + str(ex.get("picture", ""))] = true
		assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
		assert_gte(distinct.size(), 25, "%s: varied practice" % id)


func test_every_grade_3_maths_unit_uses_grade_3_generators() -> void:
	for u: Dictionary in Curriculum.units(GRADE, "maths"):
		if not Curriculum.has_content(str(u.id)):
			continue
		for g: Dictionary in Curriculum.content(str(u.id)).generators:
			assert_true(str(g.gen).get_slice(".", 0) in ["g3m", "g3f", "g3g"], "%s uses %s" % [u.id, g.gen])


## Every lesson card's picture can be drawn, and the lesson teaches with pictures (at least one per unit).
func test_every_grade_3_maths_lesson_has_a_picture() -> void:
	for u: Dictionary in Curriculum.units(GRADE, "maths"):
		if not Curriculum.has_content(str(u.id)):
			continue
		var pictures := 0
		for card: Dictionary in Curriculum.content(str(u.id)).lesson:
			if card.has("picture"):
				pictures += 1
				assert_eq(SchoolPicture.problem(card.picture), "", "%s: %s" % [u.id, card.picture])
		assert_gt(pictures, 0, "%s: a lesson with pictures" % u.id)


# --- Every sum is right (the lead's review, 2026-09-29: a wrong sum in a lesson teaches the wrong thing) --------------------

## A number in a sum: a fraction (3/4), a whole number with thousands commas (4,735) or without.
const NUM := "(?:\\d+/\\d+|\\d{1,3}(?:,\\d{3})+|\\d+)"
## Sums and comparisons written with spaces round their signs: "2,456 + 1,378 = 3,834", "3/8 < 5/8", "a = b = c",
## "1/4 of 12 = 3" ("of" multiplies). Never inside a time (4:35) or another number.
static var _chain := RegEx.create_from_string("(?<![\\d/,.:])(" + NUM + "(?: (?:[+−×÷]|of) " + NUM + ")*(?: [=<>] "
	+ NUM + "(?: (?:[+−×÷]|of) " + NUM + ")*)+)(?!\\d|/|[:,]\\d)")
static var _remainder := RegEx.create_from_string("^ remainder (\\d+)")
static var _unit_after := RegEx.create_from_string("^ (tens|ten|hundreds|hundred|thousands|thousand|ones)\\b")


## Every relation in `text` that is only numbers, as [chain, holds]. A chain right after a sign ("12 ones ÷ 3 = 4") or
## right before one that goes on in words or "?" ("… = 3 × ?") is not a whole sum and is left out.
func _sums(text: String) -> Array:
	var out: Array = []
	for m in _chain.search_all(text):
		var before := text.substr(0, m.get_start()).strip_edges(false, true)
		var after := text.substr(m.get_end())
		if before.ends_with("+") or before.ends_with("−") or before.ends_with("×") or before.ends_with("÷") \
				or before.ends_with("-") or after.begins_with(" + ") or after.begins_with(" − ") or after.begins_with(" × ") \
				or after.begins_with(" ÷ ") or after.begins_with(" = ") or after.begins_with(" < ") or after.begins_with(" > "):
			continue
		var chain := m.get_string(1)
		if _unit_after.search(after):   # "= 12 tens": a number of tens, not a sum to check here
			continue
		var rem := _remainder.search(after)
		if after.begins_with(" remainder") and rem == null:   # "= 7 remainder ?"
			continue
		if rem:
			var parts := chain.split(" = ")
			var q := _value(parts[1])
			var sides := parts[0].split(" ÷ ")
			var ok := parts.size() == 2 and sides.size() == 2
			if ok:
				var a := _value(sides[0])
				var b := _value(sides[1])
				var r := float(rem.get_string(1))
				ok = is_equal_approx(a, b * q + r) and r < b
			out.append([chain + " remainder " + rem.get_string(1), ok])
			continue
		out.append([chain, _holds(chain)])
	return out


func _holds(chain: String) -> bool:
	var tokens := chain.split(" ")
	var sides: Array[String] = []
	var rels: Array[String] = []
	var cur := ""
	for t in tokens:
		if t in ["=", "<", ">"]:
			sides.append(cur.strip_edges())
			rels.append(t)
			cur = ""
		else:
			cur += " " + t
	sides.append(cur.strip_edges())
	for i in rels.size():
		var a := _value(sides[i])
		var b := _value(sides[i + 1])
		if is_nan(a) or is_nan(b):
			return false
		if (rels[i] == "=" and not is_equal_approx(a, b)) or (rels[i] == "<" and not a < b) or (rels[i] == ">" and not a > b):
			return false
	return true


## "2 + 3 × 4" -> 14 (× and ÷ first).
func _value(expr: String) -> float:
	var terms: Array[float] = []
	var signs: Array[String] = ["+"]
	var product := NAN
	var op := ""
	for t in expr.strip_edges().split(" "):
		if t in ["+", "−"]:
			terms.append(product)
			signs.append(t)
			product = NAN
		elif t in ["×", "÷", "of"]:
			op = "×" if t == "of" else t
		else:
			var v := NumberAnswer.value(t)
			if is_nan(product):
				product = v
			elif op == "×":
				product *= v
			else:
				product = product / v if v != 0.0 else NAN
	terms.append(product)
	var total := 0.0
	for i in terms.size():
		total += terms[i] if signs[i] == "+" else -terms[i]
	return total


func test_the_sum_checker() -> void:
	assert_eq(_sums("346 + 278 = 724"), [["346 + 278 = 724", false]])
	assert_eq(_sums("3,482 > 3,428, and 2/5 + 1/5 = 3/5."), [["3,482 > 3,428", true], ["2/5 + 1/5 = 3/5", true]])
	assert_eq(_sums("7 tens ÷ 3 = 2 tens, 12 ones ÷ 3 = 4."), [])
	assert_eq(_sums("29 ÷ 4 = 7 remainder 1, so 3 × 4 = 12 = 4 × 3."), [["29 ÷ 4 = 7 remainder 1", true],
		["3 × 4 = 12 = 4 × 3", true]])
	assert_eq(_sums("5 + 5 + 5 = 3 × ? and 4:35 + 25 = 5:00"), [])
	assert_eq(_sums("2 + 3 × 4 = 14"), [["2 + 3 × 4 = 14", true]])
	assert_eq(_sums("500 + 500 = 1,000: 550. ? × 7 = 42 and 17 ÷ 5 = 3 remainder ?"), [["500 + 500 = 1,000", true]])
	assert_eq(_sums("4 × 30 = 12 tens"), [])
	assert_eq(_sums("2/3 = 4/?"), [])
	assert_eq(_sums("So 1/4 of 12 = 3, and 2/3 of 12 = 9."), [["1/4 of 12 = 3", true], ["2/3 of 12 = 9", false]])


## Every sum in a lesson card, a hint or a worked answer holds, and every sum in a question does unless it is a true or
## false question whose answer is false; for the hand-written units and for every grade 3 maths generator.
func test_every_sum_in_grade_3_maths_is_right() -> void:
	var wrong: Array[String] = []
	var checked := 0
	var texts: Array = []   # [where, text, must hold]
	for u: Dictionary in Curriculum.units(GRADE, "maths"):
		if not Curriculum.has_content(str(u.id)):
			continue
		var c := Curriculum.content(str(u.id))
		for card: Dictionary in c.lesson:
			texts.append([u.id, str(card.text), true])
		for ex: Dictionary in c.exercises:
			texts.append_array(_texts_of(str(ex.id), ex))
	for gen in SchoolGen.ids():
		if gen.get_slice(".", 0) in ["g3m", "g3f", "g3g"]:
			for level in [1, 2, 3]:
				for s in 20:
					texts.append_array(_texts_of("%s %d %d" % [gen, level, s], SchoolGen.make(gen, s, level)))
	for p: Array in _columns():
		checked += 1
		if not bool(p[1]):
			wrong.append("%s: a written sum %s" % [p[0], p[2]])
	for t: Array in texts:
		for sum: Array in _sums(str(t[1])):
			checked += 1
			if bool(t[2]) and not bool(sum[1]):
				wrong.append("%s: %s  (in: %s)" % [t[0], sum[0], t[1]])
	gut.p("%d sums checked" % checked)
	assert_gt(checked, 500, "the sums are found")
	assert_eq(wrong, [] as Array[String], "\n".join(wrong))


## Every written sum in a column picture with its answer row ([a, "+ b", c]) in the grade 3 maths lessons and exercises
## and the generators' pictures: [where, it holds, the rows].
func _columns() -> Array:
	var pics: Array = []
	for u: Dictionary in Curriculum.units(GRADE, "maths"):
		if not Curriculum.has_content(str(u.id)):
			continue
		var c := Curriculum.content(str(u.id))
		for card: Dictionary in c.lesson:
			pics.append([u.id, card.get("picture", {})])
		for ex: Dictionary in c.exercises:
			pics.append([ex.id, ex.get("picture", {})])
	for gen in SchoolGen.ids():
		if gen.get_slice(".", 0) in ["g3m", "g3f", "g3g"]:
			for level in [1, 2, 3]:
				for s in 10:
					pics.append([gen, SchoolGen.make(gen, s, level).get("picture", {})])
	var out: Array = []
	for p: Array in pics:
		var pic: Dictionary = p[1]
		if str(pic.get("kind", "")) != "column" or (pic.rows as Array).size() != 3:
			continue
		var rows: Array = pic.rows
		var op := str(rows[1]).left(1)
		var a := _value(str(rows[0]).replace(",", ""))
		var b := _value(str(rows[1]).substr(2).replace(",", ""))
		var c := _value(str(rows[2]).replace(",", ""))
		var want: float = a + b if op == "+" else (a - b if op == "−" else (a * b if op == "×" else a / b))
		out.append([p[0], is_equal_approx(want, c), rows])
	return out


func _texts_of(where: String, ex: Dictionary) -> Array:
	var tf_false: bool = str(ex.get("type", "")) == "truefalse" and ex.get("answer") == false
	return [[where, str(ex.get("prompt", "")), not tf_false], [where, str(ex.get("hint", "")), true],
		[where, str(ex.get("explain", "")), true]]
