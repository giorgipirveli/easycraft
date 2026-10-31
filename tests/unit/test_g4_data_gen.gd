extends GutTest
## Owner #70 and #73, grade 4 maths "Tables, line graphs and pie charts" (G4DataGen, "g4d"; Singapore P4 statistics):
## reading and completing tables (a cell, a difference, a total, a missing number from a row's or a column's total),
## reading line graphs (a point, a point between two lines, when it was highest, when it showed a value) and their
## changes (up or down, by how much, the biggest rise), and pie charts (a slice's fraction, how many a slice stands for,
## how many more, how many were asked). Each answer is worked out again here from the exercise's picture and `data`,
## for many seeds and every level, and every exercise must be valid (ExerciseCheck, the picture's own check).

const SEEDS := 80


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			assert_ne(str(ex.get("explain", "")), "", "%s: a worked answer" % gen)
			assert_ne(str(ex.get("hint", "")), str(ex.get("explain", "")), "%s: the hint is a strategy" % gen)
			assert_true(ex.get("data") is Dictionary, "%s: its data" % gen)
			assert_true(ex.has("picture"), "%s: a table, a graph or a chart to read" % gen)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % gen)
			if ExerciseCheck.problem(ex) == "" and ex.get("data") is Dictionary and ex.has("picture"):
				check.call(ex, level)


func _number_is(ex: Dictionary, expected: float) -> void:
	assert_eq(str(ex.type), "number", str(ex.prompt))
	assert_almost_eq(NumberAnswer.value(str(ex.answer)), expected, 0.0001, str(ex.prompt))


func _choice_is(ex: Dictionary, expected: String) -> void:
	assert_eq(str(ex.type), "choice", str(ex.prompt))
	assert_eq(ExerciseCheck.answer_text(ex), expected, str(ex.prompt))


## A table picture's cell as a number ("1,250" -> 1250).
func _cell(rows: Array, r: int, c: int) -> int:
	return int(str(rows[r][c]).replace(",", ""))


# --- Tables ------------------------------------------------------------------------------------------------------------

func test_reading_a_table() -> void:
	_each("g4d.table_read", _check_reading_a_table)


func _check_reading_a_table(ex: Dictionary, level: int) -> void:
	var rows: Array = ex.picture.rows
	assert_eq(str(ex.picture.kind), "table")
	var header: Array = rows[0]
	var r := int(ex.data.r)
	var c := int(ex.data.c)
	assert_true(str(ex.prompt).contains(str(rows[r][0])) or str(ex.data.ask) in ["total_col", "most"],
		"the prompt names the row")
	match str(ex.data.ask):
		"cell":
			assert_true(str(ex.prompt).to_lower().contains(str(header[c]).to_lower()), "the prompt names the column")
			_number_is(ex, _cell(rows, r, c))
		"most":
			var best := 1
			for i in range(2, rows.size()):
				if _cell(rows, i, c) > _cell(rows, best, c):
					best = i
			for i in range(1, rows.size()):
				if i != best:
					assert_ne(_cell(rows, i, c), _cell(rows, best, c), "one row has the most")
			_choice_is(ex, str(rows[best][0]))
		"diff":
			var r2 := int(ex.data.r2)
			assert_true(str(ex.prompt).contains(str(rows[r2][0])), "the prompt names both rows")
			assert_gt(_cell(rows, r, c), _cell(rows, r2, c), "how many more: the first is bigger")
			_number_is(ex, _cell(rows, r, c) - _cell(rows, r2, c))
		"total_row":
			var sum := 0
			for k in range(1, (rows[r] as Array).size()):
				sum += _cell(rows, r, k)
			_number_is(ex, sum)
		"total_col":
			assert_true(str(ex.prompt).to_lower().contains(str(header[c]).to_lower()), "the prompt names the column")
			var sum := 0
			for k in range(1, rows.size()):
				sum += _cell(rows, k, c)
			_number_is(ex, sum)
		_:
			fail_test("unknown ask %s" % ex.data.ask)
	if level == 1:
		assert_true(str(ex.data.ask) in ["cell", "most"], "level 1 reads the table")
	elif level == 3:
		assert_true(str(ex.data.ask) in ["total_row", "total_col"], "level 3 adds a row or a column")


## A table with totals and one "?": the missing number is the total less the others (or the others added), worked out
## both along its row and down its column when the table has a total row too.
func test_completing_a_table() -> void:
	_each("g4d.table_missing", _check_completing_a_table)


func _check_completing_a_table(ex: Dictionary, level: int) -> void:
	var rows: Array = ex.picture.rows
	var header: Array = rows[0]
	assert_eq(str(header[-1]), "Total", "a Total column")
	var qr := -1
	var qc := -1
	for r in rows.size():
		for c in (rows[r] as Array).size():
			if str(rows[r][c]) == "?":
				assert_eq(qr, -1, "one number is missing")
				qr = r
				qc = c
	assert_gt(qr, 0, "a missing number")
	var last := (rows[qr] as Array).size() - 1
	var along := 0
	if qc == last:   # a row's total: add the row
		for c in range(1, last):
			along += _cell(rows, qr, c)
	else:
		along = _cell(rows, qr, last)
		for c in range(1, last):
			if c != qc:
				along -= _cell(rows, qr, c)
	_number_is(ex, along)
	var total_row := str(rows[-1][0]) == "Total"
	if total_row and qr != rows.size() - 1:   # down its column too
		var down := _cell(rows, rows.size() - 1, qc)
		for r in range(1, rows.size() - 1):
			if r != qr:
				down -= _cell(rows, r, qc)
		_number_is(ex, down)
	if total_row:   # every row and column adds up
		for r in range(1, rows.size()):
			if r == qr:
				continue
			var sum := 0
			for c in range(1, last):
				sum += _cell(rows, r, c)
			assert_eq(sum, _cell(rows, r, last), "row %d adds up" % r)
	assert_eq(total_row, level == 3, "level 3 has a total row too")
	assert_eq(last, 3 if level == 1 else 4, "levels 2 and 3 have three columns of numbers")


# --- Line graphs -------------------------------------------------------------------------------------------------------

func _value_at(ex: Dictionary, i: int) -> float:
	return float(ex.picture.points[i][1])


func test_reading_a_line_graph() -> void:
	_each("g4d.line_read", _check_reading_a_line_graph)


func _check_reading_a_line_graph(ex: Dictionary, level: int) -> void:
	assert_eq(str(ex.picture.kind), "line_graph")
	var points: Array = ex.picture.points
	var step := float(ex.picture.step)
	var from := float(ex.picture.get("from", 0))
	var i := int(ex.data.i)
	match str(ex.data.ask):
		"read":
			assert_true(str(ex.prompt).contains(str(points[i][0])), "the prompt names the time")
			_number_is(ex, _value_at(ex, i))
			var on_line := is_equal_approx(fmod(_value_at(ex, i) - from, step), 0.0)
			if level == 1:
				assert_true(on_line, "level 1 reads a value on a line")
		"highest", "lowest":
			var best := 0
			for k in points.size():
				if (_value_at(ex, k) > _value_at(ex, best)) == (str(ex.data.ask) == "highest") \
						and _value_at(ex, k) != _value_at(ex, best):
					best = k
			for k in points.size():
				if k != best:
					assert_ne(_value_at(ex, k), _value_at(ex, best), "one point is the %s" % ex.data.ask)
			_choice_is(ex, str(points[best][0]))
		"when":
			var v := float(ex.data.value)
			var hits := 0
			for k in points.size():
				if is_equal_approx(_value_at(ex, k), v):
					hits += 1
			assert_eq(hits, 1, "one point shows the value asked")
			assert_true(str(ex.prompt).contains(SchoolPictureG4Core.degrees(v)), "the prompt gives the value")
			_choice_is(ex, str(points[i][0]))
			assert_almost_eq(_value_at(ex, i), v, 0.0001)
		_:
			fail_test("unknown ask %s" % ex.data.ask)
	if level >= 2:
		assert_true(str(ex.data.ask) != "read" or not is_equal_approx(fmod(_value_at(ex, i) - from, step), 0.0)
			or level == 3, "level 2's readings are between two lines")


func test_changes_on_a_line_graph() -> void:
	_each("g4d.line_change", _check_changes_on_a_line_graph)


func _check_changes_on_a_line_graph(ex: Dictionary, level: int) -> void:
	var points: Array = ex.picture.points
	match str(ex.data.ask):
		"direction":
			var i := int(ex.data.i)
			var a := _value_at(ex, i)
			var b := _value_at(ex, i + 1)
			assert_true(str(ex.prompt).contains(str(points[i][0])) and str(ex.prompt).contains(str(points[i + 1][0])))
			_choice_is(ex, "It went up." if b > a else "It went down." if b < a else "It stayed the same.")
		"by":
			var i := int(ex.data.i)
			var j := int(ex.data.j)
			assert_lt(i, j)
			var a := _value_at(ex, i)
			var b := _value_at(ex, j)
			assert_ne(a, b, "it changed")
			var words := "rise" if b > a else "fall"
			assert_true(str(ex.prompt).contains(words), "the prompt says %s" % words)
			_number_is(ex, absf(b - a))
		"most":
			var best := 0
			for k in points.size() - 1:
				if _value_at(ex, k + 1) - _value_at(ex, k) > _value_at(ex, best + 1) - _value_at(ex, best):
					best = k
			for k in points.size() - 1:
				if k != best:
					assert_lt(_value_at(ex, k + 1) - _value_at(ex, k), _value_at(ex, best + 1) - _value_at(ex, best),
						"one rise is the biggest")
			_choice_is(ex, "%s to %s" % [points[best][0], points[best + 1][0]])
		_:
			fail_test("unknown ask %s" % ex.data.ask)
	var asks := {1: ["direction"], 2: ["by"], 3: ["by", "most"]}
	assert_true(str(ex.data.ask) in asks[level], "level %d asks %s" % [level, ex.data.ask])


# --- Pie charts --------------------------------------------------------------------------------------------------------

func test_pie_charts() -> void:
	_each("g4d.pie_read", _check_pie_charts)


func _check_pie_charts(ex: Dictionary, level: int) -> void:
	assert_eq(str(ex.picture.kind), "pie_chart")
	var slices: Array = ex.picture.slices
	var whole := 0
	for s: Array in slices:
		whole += int(s[1])
	var i := int(ex.data.i)
	var total := int(ex.data.get("total", 0))
	var of_i := total * int(slices[i][1]) / whole
	if total > 0:
		assert_eq(total % whole, 0, "the number asked shares into the parts")
		assert_true(str(ex.prompt).contains(str(total)) or str(ex.data.ask) == "asked", "the prompt gives how many")
	match str(ex.data.ask):
		"fraction":
			_number_is(ex, float(slices[i][1]) / whole)
		"how_many":
			_number_is(ex, of_i)
		"more":
			var j := int(ex.data.j)
			var of_j := total * int(slices[j][1]) / whole
			assert_gt(of_i, of_j, "how many more: the first is bigger")
			_number_is(ex, of_i - of_j)
		"asked":
			assert_true(str(ex.prompt).contains(str(of_i)), "the prompt gives the slice's number")
			_number_is(ex, total)
		_:
			fail_test("unknown ask %s" % ex.data.ask)
	var asks := {1: ["fraction", "how_many"], 2: ["how_many", "fraction"], 3: ["more", "asked"]}
	assert_true(str(ex.data.ask) in asks[level], "level %d asks %s" % [level, ex.data.ask])
	if level == 1:
		assert_true(whole in [2, 4], "level 1: halves and quarters")
	else:
		assert_true(whole in [3, 4, 6, 8, 12], "levels 2-3: thirds to twelfths")
