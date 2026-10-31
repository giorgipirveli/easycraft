class_name G4DataGen
extends RefCounted
## Owner #70 and #73 (research §6.4, Singapore P4 and England Y5 statistics): grade 4 maths "Tables, line graphs and pie
## charts": reading tables (a cell, the row with the most, how many more, a row's or a column's total), completing tables
## with totals (a missing number from its row's total, or from a total row too), reading line graphs (a point on or
## between the scale's lines, the highest or lowest point, when it showed a value) and their changes (up or down, how
## much it rose or fell, the biggest rise), and pie charts cut into equal parts (a slice's fraction, how many a slice
## stands for, how many more, how many were asked). SchoolGen "g4d.<name>", `static func <name>(rng:
## RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer,
## a picture (SchoolPicture's table, SchoolPictureG4Core's line_graph and pie_chart) and `data` (for
## tests/unit/test_g4_data_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")

## What a table shows: its first column's heading and rows, its columns, the prompt's first sentence and its questions
## ({r}, {r2}: rows; {c}: a column, lower-case when `low`).
const TABLES: Array = [
	{"intro": "The table shows the fruit picked on Zara's farm.", "head": "Day", "rows": ["Mon", "Tue", "Wed", "Thu"],
		"cols": ["Apples", "Pears", "Plums"], "low": true, "cell": "How many {c} were picked on {r}?",
		"more": "How many more {c} were picked on {r} than on {r2}?",
		"row_total": "How many pieces of fruit were picked on {r} altogether?",
		"col_total": "How many {c} were picked on the four days altogether?", "most": "On which day were the most {c} picked?"},
	{"intro": "The table shows the blocks four friends mined.", "head": "Player", "rows": ["Tilly", "Bram", "Zara", "Mimi"],
		"cols": ["Stone", "Coal", "Iron"], "low": true, "cell": "How many {c} blocks did {r} mine?",
		"more": "How many more {c} blocks did {r} mine than {r2}?", "row_total": "How many blocks did {r} mine altogether?",
		"col_total": "How many {c} blocks did the four friends mine altogether?", "most": "Who mined the most {c} blocks?"},
	{"intro": "The table shows the votes for a class pet.", "head": "Class", "rows": ["4A", "4B", "4C", "4D"],
		"cols": ["Cats", "Dogs", "Fish"], "low": true, "cell": "How many children in class {r} voted for {c}?",
		"more": "How many more children voted for {c} in class {r} than in class {r2}?",
		"row_total": "How many children in class {r} voted altogether?",
		"col_total": "How many children voted for {c} altogether?", "most": "Which class had the most votes for {c}?"},
	{"intro": "The table shows the pages three friends read each week.", "head": "Week",
		"rows": ["Week 1", "Week 2", "Week 3", "Week 4"], "cols": ["Tilly", "Bram", "Zara"], "low": false,
		"cell": "How many pages did {c} read in {r}?", "more": "How many more pages did {c} read in {r} than in {r2}?",
		"row_total": "How many pages did the three friends read in {r} altogether?",
		"col_total": "How many pages did {c} read in the four weeks altogether?", "most": "In which week did {c} read the most pages?"},
]
## What a line graph shows: its title, the labels along the bottom, what is asked ({x}: a label), its unit words, and
## its shape: "up" (never falls), "hill" (rises, then falls) or "any".
const LINES: Array = [
	{"name": "Temperature (°C)", "labels": ["6:00", "8:00", "10:00", "12:00", "14:00", "16:00"], "what": "the temperature",
		"read": "What was the temperature at {x}, in °C?", "when": "At what time was the temperature {v} °C?", "unit": " °C",
		"at": "at", "shape": "hill", "most": "At what time was it warmest?", "least": "At what time was it coldest?",
		"min_step": 2},
	{"name": "Height of a sunflower (cm)", "labels": ["Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6"],
		"what": "the sunflower's height", "read": "How tall was the sunflower in {x}, in cm?",
		"when": "In which week was the sunflower {v} cm tall?", "unit": " cm", "at": "in", "shape": "up",
		"most": "In which week was the sunflower tallest?", "least": "In which week was the sunflower shortest?",
		"min_step": 2},
	{"name": "Gold coins Bram has saved", "labels": ["Jan", "Feb", "Mar", "Apr", "May", "Jun"], "what": "Bram's savings",
		"read": "How many gold coins had Bram saved by {x}?", "when": "In which month had Bram saved {v} coins?", "unit": " coins",
		"at": "in", "shape": "up", "most": "In which month had Bram saved the most coins?",
		"least": "In which month had Bram saved the fewest coins?", "min_step": 2},
	{"name": "Visitors to the museum", "labels": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], "what": "the number of visitors",
		"read": "How many visitors came to the museum on {x}?", "when": "On which day did {v} visitors come?", "unit": " visitors",
		"at": "on", "shape": "any", "most": "On which day did the most visitors come?",
		"least": "On which day did the fewest visitors come?", "min_step": 10},
	{"name": "Water in the rain barrel (L)", "labels": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], "what": "the water in the barrel",
		"read": "How many litres of water were in the barrel on {x}?", "when": "On which day were there {v} litres in the barrel?",
		"unit": " L", "at": "on", "shape": "any", "most": "On which day was there the most water in the barrel?",
		"least": "On which day was there the least water in the barrel?", "min_step": 2},
]
## What a pie chart shows: the slices' names, the prompt's first sentence ({n}: how many were asked), and its questions.
const PIES: Array = [
	{"names": ["Apples", "Pears", "Plums", "Grapes"], "intro": "{n} children voted for their favourite fruit.",
		"about": "the votes for favourite fruit", "who": "children", "chose": "voted for {x}",
		"asked": "How many children voted altogether?"},
	{"names": ["Walk", "Bus", "Bike", "Car"], "intro": "{n} children said how they come to school.",
		"about": "how some children come to school", "who": "children", "chose": "chose {x}",
		"asked": "How many children were asked altogether?"},
	{"names": ["Cats", "Dogs", "Fish", "Rabbits"], "intro": "{n} people chose the pet they would like best.",
		"about": "the pets some people would like best", "who": "people", "chose": "chose {x}",
		"asked": "How many people chose a pet altogether?"},
	{"names": ["Berries", "Carrots", "Seeds", "Nuts"], "intro": "{n} buddies picked their favourite snack.",
		"about": "the snacks some buddies picked", "who": "buddies", "chose": "picked {x}",
		"asked": "How many buddies picked a snack altogether?"},
	{"names": ["Red", "Blue", "Green", "Yellow"], "intro": "{n} players chose a colour for their team.",
		"about": "the colours some players chose", "who": "players", "chose": "chose {x}",
		"asked": "How many players chose a colour altogether?"},
]
## The ways to cut a pie into slices of equal parts, by the whole: each a list of slice sizes.
const CUTS := {
	2: [[1, 1]],
	4: [[2, 1, 1], [1, 2, 1], [3, 1], [1, 1, 1, 1], [1, 1, 2]],
	3: [[1, 1, 1], [2, 1]],
	6: [[3, 2, 1], [2, 2, 1, 1], [1, 3, 2], [4, 1, 1], [3, 1, 1, 1]],
	8: [[4, 2, 1, 1], [3, 3, 2], [4, 3, 1], [2, 1, 4, 1], [5, 2, 1], [2, 2, 3, 1]],
	12: [[6, 3, 2, 1], [4, 4, 3, 1], [5, 4, 3], [6, 4, 2], [3, 3, 4, 2]],
}


# --- Tables ------------------------------------------------------------------------------------------------------------

## Read a table: a cell or the row with the most in a column (level 1), how many more in one row than another (level 2),
## a row's or a column's total (level 3).
static func table_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t: Dictionary = TABLES[rng.randi_range(0, TABLES.size() - 1)]
	var n_rows := 3 if level < 3 else 4
	var n_cols := 2 if level == 1 else 3
	var lo: int = [2, 5, 12][level - 1]
	var hi: int = [20, 60, 150][level - 1]
	var values := _grid(rng, n_rows, n_cols, lo, hi)
	var picture := _table_picture(t, values)
	var rows: Array = picture.rows
	var ex: Dictionary
	var d := {}
	var c := rng.randi_range(1, n_cols)
	var col_words := _col(t, c)
	if level == 1 and rng.randf() < 0.5:
		var r := rng.randi_range(1, n_rows)
		var v: int = values[r - 1][c - 1]
		ex = K.number("%s %s" % [t.intro, _q(t.cell, rows[r][0], col_words)], v,
			"Find the row for %s, then go across to the %s column." % [rows[r][0], rows[0][c]],
			"The %s row meets the %s column at %s." % [rows[r][0], rows[0][c], K.fmt(v)], picture)
		d = {"ask": "cell", "r": r, "c": c}
	elif level == 1:
		for _try in 50:   # one row has the most
			var col: Array = []
			for r in n_rows:
				col.append(values[r][c - 1])
			if col.count(col.max()) == 1:
				break
			values = _grid(rng, n_rows, n_cols, lo, hi)
			picture = _table_picture(t, values)
			rows = picture.rows
		var best := 0
		for r in n_rows:
			if values[r][c - 1] > values[best][c - 1]:
				best = r
		var names: Array = []
		for r in n_rows:
			names.append(rows[r + 1][0])
		ex = K.choice(rng, "%s %s" % [t.intro, _q(t.most, "", col_words)], names[best],
			names.filter(func(x: String) -> bool: return x != names[best]),
			"Look down the %s column for the biggest number." % rows[0][c],
			"The biggest number in the %s column is %s, for %s." % [rows[0][c], K.fmt(values[best][c - 1]), names[best]], picture)
		d = {"ask": "most", "r": best + 1, "c": c}
	elif level == 2:
		var a := rng.randi_range(0, n_rows - 1)
		var b := (a + rng.randi_range(1, n_rows - 1)) % n_rows
		if values[a][c - 1] == values[b][c - 1]:
			values[a][c - 1] += rng.randi_range(3, 9)
			picture = _table_picture(t, values)
			rows = picture.rows
		if values[a][c - 1] < values[b][c - 1]:
			var s := a
			a = b
			b = s
		var va: int = values[a][c - 1]
		var vb: int = values[b][c - 1]
		ex = K.number("%s %s" % [t.intro, _q(t.more, rows[a + 1][0], col_words, rows[b + 1][0])], va - vb,
			"Read both numbers in the %s column, then take the smaller from the bigger." % rows[0][c],
			"%s: %s. %s: %s. %s − %s = %s." % [rows[a + 1][0], K.fmt(va), rows[b + 1][0], K.fmt(vb), K.fmt(va), K.fmt(vb),
				K.fmt(va - vb)], picture)
		d = {"ask": "diff", "r": a + 1, "r2": b + 1, "c": c}
	elif rng.randf() < 0.5:
		var r := rng.randi_range(1, n_rows)
		var parts: Array[String] = []
		var sum := 0
		for k in n_cols:
			parts.append(K.fmt(values[r - 1][k]))
			sum += values[r - 1][k]
		ex = K.number("%s %s" % [t.intro, _q(t.row_total, rows[r][0], "")], sum,
			"Add every number in the %s row." % rows[r][0], "%s = %s." % [" + ".join(parts), K.fmt(sum)], picture)
		d = {"ask": "total_row", "r": r, "c": c}
	else:
		var parts: Array[String] = []
		var sum := 0
		for r in n_rows:
			parts.append(K.fmt(values[r][c - 1]))
			sum += values[r][c - 1]
		ex = K.number("%s %s" % [t.intro, _q(t.col_total, "", col_words)], sum,
			"Add every number in the %s column." % rows[0][c], "%s = %s." % [" + ".join(parts), K.fmt(sum)], picture)
		d = {"ask": "total_col", "r": 1, "c": c}
	ex.data = d
	return ex


## Complete a table with totals: one number is "?". Level 1: two columns and a Total; level 2: three; level 3: a Total row
## as well (the missing number can be found along its row or down its column).
static func table_missing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t: Dictionary = TABLES[rng.randi_range(0, TABLES.size() - 1)]
	var n_rows := 3
	var n_cols := 2 if level == 1 else 3
	var lo: int = [4, 8, 10][level - 1]
	var hi: int = [30, 60, 90][level - 1]
	var values := _grid(rng, n_rows, n_cols, lo, hi)
	var grid: Array = []   # the numbers with their totals
	for r in n_rows:
		var row: Array = (values[r] as Array).duplicate()
		var sum := 0
		for v: int in values[r]:
			sum += v
		row.append(sum)
		grid.append(row)
	if level == 3:
		var totals: Array = []
		for c in n_cols + 1:
			var sum := 0
			for r in n_rows:
				sum += int(grid[r][c])
			totals.append(sum)
		grid.append(totals)
	var qr := rng.randi_range(0, grid.size() - 1)
	var qc := rng.randi_range(0, n_cols) if rng.randf() < 0.75 else n_cols
	var answer: int = grid[qr][qc]
	var header: Array = [t.head]
	header.append_array((t.cols as Array).slice(0, n_cols))
	header.append("Total")
	var rows: Array = [header]
	for r in grid.size():
		var row: Array = [t.rows[r] if r < n_rows else "Total"]
		for c in n_cols + 1:
			row.append("?" if r == qr and c == qc else K.fmt(int(grid[r][c])))
		rows.append(row)
	var picture := {"kind": "table", "rows": rows}
	var row_name := str(rows[qr + 1][0])
	var others: Array[String] = []
	for c in n_cols:
		if c != qc:
			others.append(K.fmt(int(grid[qr][c])))
	var explain: String
	var hint: String
	if qc == n_cols:
		explain = "The %s row's total: %s = %s." % [row_name, " + ".join(others), K.fmt(answer)]
		hint = "A total is all the numbers in its row added together."
	else:
		explain = "Along the %s row: %s − %s = %s." % [row_name, K.fmt(int(grid[qr][n_cols])), " − ".join(others),
			K.fmt(answer)]
		hint = "The numbers in a row add up to its total: take the numbers you know away from the total."
	if level == 3:
		hint += " The Total row adds up each column too."
	var ex := K.number("%s One number is missing. What is the missing number?" % t.intro, answer, hint, explain, picture)
	ex.data = {"r": qr + 1, "c": qc + 1, "cols": n_cols, "total_row": level == 3}
	return ex


static func _grid(rng: RandomNumberGenerator, n_rows: int, n_cols: int, lo: int, hi: int) -> Array:
	var out: Array = []
	for r in n_rows:
		var row: Array = []
		for c in n_cols:
			row.append(rng.randi_range(lo, hi))
		out.append(row)
	return out


static func _table_picture(t: Dictionary, values: Array) -> Dictionary:
	var header: Array = [t.head]
	header.append_array((t.cols as Array).slice(0, (values[0] as Array).size()))
	var rows: Array = [header]
	for r in values.size():
		var row: Array = [t.rows[r]]
		for v: int in values[r]:
			row.append(K.fmt(v))
		rows.append(row)
	return {"kind": "table", "rows": rows}


static func _col(t: Dictionary, c: int) -> String:
	var name := str(t.cols[c - 1])
	return name.to_lower() if bool(t.low) else name


static func _q(template: String, r: String, c: String, r2: String = "") -> String:
	return template.format({"r": r, "c": c, "r2": r2})


# --- Line graphs -------------------------------------------------------------------------------------------------------

## Read a line graph: a point on a line of the scale or the highest point (level 1); a point halfway between two lines
## or the lowest point (level 2); when it showed a value, or a point between lines on a scale of 10s or 20s (level 3).
static func line_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var roll := rng.randf()
	var ask := "read"
	if level == 1 and roll >= 0.7:
		ask = "highest"
	elif level == 2 and roll >= 0.6:
		ask = "lowest"
	elif level == 3 and roll >= 0.4:
		ask = "when"
	var g := _line(rng, level)
	for _try in 40:   # one highest or lowest point; a value shown once
		if ask == "read" or (ask in ["highest", "lowest"] and _extreme(g.picture.points, ask == "highest") >= 0) \
				or (ask == "when" and not _once(g.picture.points).is_empty()):
			break
		g = _line(rng, level)
	var t: Dictionary = g.topic
	var pic: Dictionary = g.picture
	var points: Array = pic.points
	var step := int(pic.step)
	var ex: Dictionary
	var d := {}
	if ask in ["highest", "lowest"] and _extreme(points, ask == "highest") < 0:
		ask = "read"
	if ask == "when" and _once(points).is_empty():
		ask = "read"
	if ask == "read":
		var i: int = int(g.half) if level > 1 else rng.randi_range(0, points.size() - 1)
		var v := float(points[i][1])
		var hint := "Go up from %s to the line, then across to the scale. The scale goes up in %ds." % [points[i][0], step]
		if level > 1:
			hint += " A point halfway between two lines is half a step, %s, above the lower line." % _num(step / 2.0)
		ex = K.number("The line graph shows %s. %s" % [t.what, _x(t.read, points[i][0])], _num(v), hint,
			"The point for %s is at %s%s." % [points[i][0], _num(v), t.unit], pic)
		d = {"ask": "read", "i": i}
	elif ask in ["highest", "lowest"]:
		var best := _extreme(points, ask == "highest")
		ex = _label_choice(rng, "The line graph shows %s. %s" % [t.what, t.most if ask == "highest" else t.least], points, best,
			"Find the %s point on the line, then read its label at the bottom." % ask,
			"The %s point is %s%s, %s %s." % [ask, _num(float(points[best][1])), t.unit, t.at, points[best][0]], pic)
		d = {"ask": ask, "i": best}
	else:
		var once := _once(points)
		var i: int = once[rng.randi_range(0, once.size() - 1)]
		var v := float(points[i][1])
		ex = _label_choice(rng, "The line graph shows %s. %s" % [t.what, str(t.when).format({"v": _num(v)})], points, i,
			"Find %s on the scale, go across to the line, then down to the label." % _num(v),
			"The line is at %s%s %s %s." % [_num(v), t.unit, t.at, points[i][0]], pic)
		d = {"ask": "when", "i": i, "value": v}
	ex.data = d
	return ex


## Changes on a line graph: up, down or the same between two labels (level 1); how much it rose or fell (level 2);
## how much it rose or fell over more than one step, or where it rose the most (level 3).
static func line_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var most := level == 3 and rng.randf() < 0.5
	var g := _line(rng, level, level == 1)
	for _try in 40:
		if not most or int(g.rise_best) >= 0:
			break
		g = _line(rng, level)
	if int(g.rise_best) < 0:
		most = false
	var t: Dictionary = g.topic
	var pic: Dictionary = g.picture
	var points: Array = pic.points
	var ex: Dictionary
	var d := {}
	if level == 1:
		var i := rng.randi_range(0, points.size() - 2)
		for k in points.size() - 1:   # sometimes it stays the same: show that one
			if float(points[k][1]) == float(points[k + 1][1]) and rng.randf() < 0.5:
				i = k
		var a := float(points[i][1])
		var b := float(points[i + 1][1])
		var right := "It went up." if b > a else "It went down." if b < a else "It stayed the same."
		ex = K.choice(rng, "The line graph shows %s. What happened to %s from %s to %s?" % [t.what, t.what, points[i][0],
			points[i + 1][0]], right, ["It went up.", "It went down.", "It stayed the same."],
			"Look at the line between the two points: does it slope up, slope down or stay flat?",
			"From %s%s to %s%s: %s" % [_num(a), t.unit, _num(b), t.unit, right.to_lower()], pic)
		d = {"ask": "direction", "i": i}
	elif most:
		var best := int(g.rise_best)
		var right := "%s to %s" % [points[best][0], points[best + 1][0]]
		var wrongs: Array = []
		for k in points.size() - 1:
			if k != best:
				wrongs.append("%s to %s" % [points[k][0], points[k + 1][0]])
		K.shuffle(rng, wrongs)
		var a := float(points[best][1])
		var b := float(points[best + 1][1])
		ex = K.choice(rng, "The line graph shows %s. Between which two labels next to each other did it rise the most?" % t.what,
			right, wrongs.slice(0, 3), "The steepest part of the line going up is the biggest rise.",
			"From %s to %s it rose from %s to %s: %s − %s = %s, the biggest rise." % [points[best][0], points[best + 1][0],
				_num(a), _num(b), _num(b), _num(a), _num(b - a)], pic)
		d = {"ask": "most", "i": best}
	else:
		var pairs: Array = []
		for i in points.size() - 1:
			for j in range(i + 1, points.size()):
				var near := j == i + 1
				if float(points[i][1]) != float(points[j][1]) and near == (level == 2):
					pairs.append([i, j])
		if pairs.is_empty():   # the lowest and highest points always differ
			var lo := _arg(points, false)
			var hi := _arg(points, true)
			pairs.append([mini(lo, hi), maxi(lo, hi)])
		var pair: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
		var i: int = pair[0]
		var j: int = pair[1]
		var a := float(points[i][1])
		var b := float(points[j][1])
		var words := "rise" if b > a else "fall"
		ex = K.number("The line graph shows %s. By how much did %s %s from %s to %s?" % [t.what, t.what, words,
			points[i][0], points[j][0]], _num(absf(b - a)),
			"Read both points on the scale, then take the smaller from the bigger.",
			"%s: %s. %s: %s. %s − %s = %s%s." % [points[i][0], _num(a), points[j][0], _num(b), _num(maxf(a, b)), _num(minf(a, b)),
				_num(absf(b - a)), t.unit], pic)
		d = {"ask": "by", "i": i, "j": j}
	ex.data = d
	return ex


## A line graph for `level`: its topic, its picture, the index of a point halfway between two of the scale's lines (0
## when none) and of the biggest rise between labels next to each other (-1 when two rises tie or nothing rises).
## Level 1: a scale of 2s, 5s or 10s and every point on a line; level 2: 2s, 4s or 10s with points halfway between
## lines; level 3: 10s or 20s, halfway too. At most 8 steps high, with room above the top point.
static func _line(rng: RandomNumberGenerator, level: int, flat_ok: bool = false) -> Dictionary:
	var t: Dictionary = LINES[rng.randi_range(0, LINES.size() - 1)]
	var steps: Array = ([[2, 5, 10], [2, 4, 10], [10, 20]][level - 1] as Array).filter(func(x: int) -> bool:
		return x >= int(t.min_step))
	var step: int = steps[rng.randi_range(0, steps.size() - 1)]
	var n := 6 if level == 3 else rng.randi_range(5, 6)
	var halves := level > 1
	var unit := step / 2 if halves else step
	var most := 8 * step
	var values: Array[int] = []
	for _try in 100:
		values.clear()
		var v := rng.randi_range(1, 3) * unit
		var peak := rng.randi_range(2, n - 2)
		for k in n:
			values.append(v)
			var move := rng.randi_range(0 if flat_ok else 1, 2 if not halves else 3) * unit
			if str(t.shape) == "up":
				v += move
			elif str(t.shape) == "hill":
				v += move if k < peak else -move
			else:
				v += move if rng.randf() < 0.6 else -move
			v = clampi(v, 0, most)
		if values.max() != values.min() and (not halves or values.any(func(x: int) -> bool: return x % step != 0)):
			break
	if halves and not values.any(func(x: int) -> bool: return x % step != 0):   # make one point halfway
		var k := rng.randi_range(0, n - 1)
		values[k] = values[k] + unit if values[k] + unit <= most else values[k] - unit
	var top := maxi(ceili(float(values.max()) / step) * step, step * 2)
	if top == values.max():
		top += step   # room above the highest point
	var points: Array = []
	for k in n:
		points.append([t.labels[k], values[k]])
	var halfs: Array[int] = []
	for k in n:
		if values[k] % step != 0:
			halfs.append(k)
	var rise_best := -1
	var best_rise := 0
	var tie := false
	for k in n - 1:
		var r := values[k + 1] - values[k]
		if r > best_rise:
			best_rise = r
			rise_best = k
			tie = false
		elif r == best_rise and r > 0:
			tie = true
	return {"topic": t, "picture": {"kind": "line_graph", "points": points, "step": step, "top": top, "name": t.name},
		"half": halfs[rng.randi_range(0, halfs.size() - 1)] if not halfs.is_empty() else 0,
		"rise_best": -1 if tie else rise_best}


## The highest (or lowest) point's index, or -1 when two points share it.
static func _extreme(points: Array, highest: bool) -> int:
	var best := _arg(points, highest)
	for k in points.size():
		if k != best and float(points[k][1]) == float(points[best][1]):
			return -1
	return best


static func _arg(points: Array, highest: bool) -> int:
	var best := 0
	for k in points.size():
		if (float(points[k][1]) > float(points[best][1])) if highest else (float(points[k][1]) < float(points[best][1])):
			best = k
	return best


## The points whose value no other point shows.
static func _once(points: Array) -> Array[int]:
	var out: Array[int] = []
	for k in points.size():
		var hits := 0
		for m in points.size():
			if float(points[m][1]) == float(points[k][1]):
				hits += 1
		if hits == 1:
			out.append(k)
	return out


## A choice of the graph's labels: the right one and up to 3 others.
static func _label_choice(rng: RandomNumberGenerator, prompt: String, points: Array, right: int, hint: String,
		explain: String, pic: Dictionary) -> Dictionary:
	var wrongs: Array = []
	for k in points.size():
		if k != right:
			wrongs.append(points[k][0])
	K.shuffle(rng, wrongs)
	return K.choice(rng, prompt, points[right][0], wrongs.slice(0, 3), hint, explain, pic)


static func _x(template: String, x: String) -> String:
	return template.format({"x": x})


## A value as the graphs write it: 12, 7.5.
static func _num(v: float) -> String:
	return K.fmt(roundi(v)) if is_equal_approx(v, roundf(v)) else String.num(v, 1)


# --- Pie charts --------------------------------------------------------------------------------------------------------

## A pie chart cut into equal parts: a slice's fraction or how many it stands for (levels 1-2: halves and quarters, then
## thirds, sixths and eighths); how many more chose one than another, or how many were asked when a slice's number is
## known (level 3: sixths, eighths and twelfths).
static func pie_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t: Dictionary = PIES[rng.randi_range(0, PIES.size() - 1)]
	var wholes: Array = [[4, 4, 2], [3, 6, 8], [6, 8, 12]][level - 1]
	var whole: int = wholes[rng.randi_range(0, wholes.size() - 1)]
	var cuts: Array = CUTS[whole]
	var sizes: Array = cuts[rng.randi_range(0, cuts.size() - 1)]
	var names: Array = (t.names as Array).slice(0, sizes.size())
	var slices: Array = []
	for k in sizes.size():
		slices.append([names[k], sizes[k]])
	var pic := {"kind": "pie_chart", "slices": slices, "lines": true}
	var most_times := maxi(2, 48 / whole) if level < 3 else maxi(2, 120 / whole)
	var total := whole * rng.randi_range(2, most_times)
	var i := rng.randi_range(0, sizes.size() - 1)
	var of_i: int = total * int(sizes[i]) / whole
	var chose := str(t.chose).format({"x": names[i]})
	var intro := str(t.intro).format({"n": total})
	var ex: Dictionary
	var d := {"i": i, "total": total}
	var parts_words := "%d of the %d equal parts" % [int(sizes[i]), whole]
	if level < 3 and rng.randf() < (0.5 if level == 1 else 0.4):
		var g := _gcd(int(sizes[i]), whole)
		var simple := "%d/%d" % [int(sizes[i]) / g, whole / g]
		ex = K.number("The pie chart shows %s. What fraction of the %s %s?" % [t.about, t.who, chose], simple,
			"Count the equal parts of the whole circle, then the parts in the %s slice." % names[i],
			"%s is %s: %d/%d%s." % [names[i], parts_words, int(sizes[i]), whole,
				"" if g == 1 else ", the same as %s" % simple], pic)
		d.ask = "fraction"
		d.erase("total")
	elif level < 3:
		ex = K.number("%s How many %s %s?" % [intro, t.who, chose],
			of_i, "The whole circle is all %d. Find what one part stands for, then count the %s slice's parts." % [total, names[i]],
			"One part is %d ÷ %d = %d. %s has %s: %d × %d = %d." % [total, whole, total / whole, names[i], _parts(int(sizes[i])),
				int(sizes[i]), total / whole, of_i], pic)
		d.ask = "how_many"
	elif rng.randf() < 0.5:
		var j := i
		for _try in 20:
			j = rng.randi_range(0, sizes.size() - 1)
			if int(sizes[j]) != int(sizes[i]):
				break
		if int(sizes[j]) == int(sizes[i]):   # every slice the same size: ask how many were asked instead
			return _pie_asked(rng, t, pic, sizes, whole, total, i, names)
		if int(sizes[j]) > int(sizes[i]):
			var s := i
			i = j
			j = s
		of_i = total * int(sizes[i]) / whole
		var of_j: int = total * int(sizes[j]) / whole
		ex = K.number("%s How many more %s %s than %s?" % [intro, t.who, str(t.chose).format({"x": names[i]}), names[j]],
			of_i - of_j, "Find what one part stands for. How many more parts does the %s slice have than the %s slice?" % [
				names[i], names[j]],
			"One part is %d ÷ %d = %d. %s has %s more than %s: %d × %d = %d." % [total, whole, total / whole, names[i],
				_parts(int(sizes[i]) - int(sizes[j])), names[j], int(sizes[i]) - int(sizes[j]), total / whole, of_i - of_j], pic)
		d = {"ask": "more", "i": i, "j": j, "total": total}
	else:
		return _pie_asked(rng, t, pic, sizes, whole, total, i, names)
	ex.data = d
	return ex


static func _pie_asked(_rng: RandomNumberGenerator, t: Dictionary, pic: Dictionary, sizes: Array, whole: int, total: int,
		i: int, names: Array) -> Dictionary:
	var of_i: int = total * int(sizes[i]) / whole
	var each: int = total / whole
	var ex := K.number("The pie chart shows %s. %d %s %s. %s" % [t.about, of_i, t.who, str(t.chose).format({"x": names[i]}),
		t.asked], total,
		"The %s slice is %d of the %d equal parts. What does one part stand for? Then the whole circle is %d parts." % [
			names[i], int(sizes[i]), whole, whole],
		("1 part stands for %d. " % of_i if int(sizes[i]) == 1 else "%d parts stand for %d, so one part is %d ÷ %d = %d. " % [
			int(sizes[i]), of_i, of_i, int(sizes[i]), each]) + "All %d parts: %d × %d = %d." % [whole, whole, each, total], pic)
	ex.data = {"ask": "asked", "i": i, "total": total}
	return ex


static func _parts(n: int) -> String:
	return "1 part" if n == 1 else "%d parts" % n


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return a
