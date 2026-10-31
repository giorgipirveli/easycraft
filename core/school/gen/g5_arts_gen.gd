class_name G5ArtsGen
extends RefCounted
## Owner #70 and #73 (research §6.5): grade 5 computing, art and music generators: SchoolGen "g5a.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a
## strategy, never the answer), a worked answer and `data` (tests/unit/test_g5_arts_gen.gd works every answer out again
## with its own interpreter, pen, spreadsheet, chart, music and fact tables).
## - Computing: trace_game (score, lives and level change as a program runs), nested_count (how many times a line in
##   loops inside loops runs), pen_loop (what a pen program with loops draws), call_count (procedures called again and
##   again), bounce_sim (a growing plant, a bouncing ball, a falling ball that speeds up), packet_count (a message in
##   packets, put back in order), rank_results (the simple rules a search engine ranks by), sheet_sum (a spreadsheet's
##   formulas), chart_read (read a chart, and one whose axis does not start at 0), odd_shadow (the pasted-in thing whose
##   shadow falls the wrong way).
## - Art: mosaic_tiles (tiles in a mosaic and its border), column_order (Doric, Ionic, Corinthian), building_facts
##   (famous buildings: what, where, how they are held up), light_and_shadow (shadow, cast shadow, which is lit right),
##   weave_next (plain, twill and basket weave: the next row).
## - Music: major_or_minor (hear it), build_chord (skip a letter; which chord is on the stave), scale_steps (tones and
##   semitones, the major scale's pattern), form_count (binary, ternary, rondo; hear the form), syllable_beats (a note
##   for each syllable; rhymes), composer_years (Vivaldi, Bach, Handel, Haydn, Mozart), world_pattern (copy a pattern,
##   count the hits, layers together), melody_beats (a melody's beats and bars), conduct (the beat patterns),
##   loop_time (loops, bars and seconds in a music maker).

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Juno"]
const ORDINALS: Array[String] = ["1st", "2nd", "3rd", "4th"]

# --- Computing -------------------------------------------------------------------------------------------------------

## Variables at work: a game's score, lives and level change as its program runs. Level 1: SET and CHANGE; level 2: a
## loop that changes two variables; level 3: an IF inside the loop that goes up a level once the score is big enough.
static func trace_game(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array[String] = []
	var ask := ""
	var value := 0
	var work := ""
	match level:
		1:
			var score := rng.randi_range(0, 5) * 10
			var lives := rng.randi_range(3, 5)
			var gain := rng.randi_range(1, 6) * 5
			var lost := rng.randi_range(1, 2)
			lines = ["SET score TO %d" % score, "SET lives TO %d" % lives, "CHANGE score BY %d" % gain,
				"CHANGE lives BY -%d" % lost]
			if rng.randi() % 2 == 0:
				ask = "score"
				value = score + gain
				work = "score starts at %d, then CHANGE adds %d: %d + %d = %d. The lives lines change another box." % [
					score, gain, score, gain, value]
			else:
				ask = "lives"
				value = lives - lost
				work = "lives starts at %d, then CHANGE takes away %d: %d − %d = %d." % [lives, lost, lives, lost, value]
		2:
			var lives := rng.randi_range(5, 9)
			var n := rng.randi_range(2, 4)
			var gain := rng.randi_range(2, 5) * 5
			lines = ["SET score TO 0", "SET lives TO %d" % lives, "REPEAT %d TIMES" % n, "  CHANGE score BY %d" % gain,
				"  CHANGE lives BY -1"]
			if rng.randi() % 2 == 0:
				ask = "score"
				value = n * gain
				work = "The loop runs %d times and adds %d each time: %d × %d = %d." % [n, gain, n, gain, value]
			else:
				ask = "lives"
				value = lives - n
				work = "The loop runs %d times and takes away 1 each time: %d − %d = %d." % [n, lives, n, value]
		3:
			var n := rng.randi_range(3, 5)
			var gain := rng.randi_range(2, 4) * 5
			var at := gain * rng.randi_range(1, n - 1) + (0 if rng.randi() % 2 == 0 else gain / 2)
			lines = ["SET score TO 0", "SET level TO 1", "REPEAT %d TIMES" % n, "  CHANGE score BY %d" % gain,
				"  IF score > %d" % at, "    CHANGE level BY 1"]
			ask = "level"
			var score := 0
			var ups: Array[String] = []
			value = 1
			for i in n:
				score += gain
				if score > at:
					value += 1
					ups.append(str(score))
			work = "score goes %s. It is more than %d at %s: %d time%s, so level is 1 + %d = %d." % [
				_score_steps(gain, n), at, " and ".join(ups), ups.size(), "" if ups.size() == 1 else "s", ups.size(), value]
	var ex := K.number("What is %s when the program ends?" % ask, value,
		"Keep each variable on paper and change it line by line. SET puts a value in; CHANGE adds (a minus takes away).",
		work, {"kind": "code", "lines": lines})
	ex.data = {"lines": lines, "var": ask}
	return ex


static func _score_steps(gain: int, n: int) -> String:
	var parts: Array[String] = []
	for i in n:
		parts.append(str(gain * (i + 1)))
	return ", ".join(parts)


## Loops inside loops: how many times does the marked line run? Level 1: two small loops; level 2: two loops and a line
## in the outer loop (either may be marked); level 3: three loops.
static func nested_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var acts: Array[String] = ["STAMP a star", "PLACE a block", "CLAP", "PLANT a seed", "DRAW a dot"]
	var act := acts[rng.randi_range(0, acts.size() - 1)]
	var lines: Array[String] = []
	var mark := 0
	var count := 0
	var work := ""
	match level:
		1:
			var a := rng.randi_range(2, 3)
			var b := rng.randi_range(2, 4)
			lines = ["REPEAT %d TIMES" % a, "  REPEAT %d TIMES" % b, "    " + act]
			mark = 2
			count = a * b
			work = "The inner loop runs it %d times, and the outer loop runs the inner loop %d times: %d × %d = %d." % [
				b, a, a, b, count]
		2:
			var a := rng.randi_range(2, 5)
			var b := rng.randi_range(3, 6)
			lines = ["REPEAT %d TIMES" % a, "  REPEAT %d TIMES" % b, "    " + act, "  MOVE to the next row"]
			if rng.randi() % 2 == 0:
				mark = 2
				count = a * b
				work = "%d times in each row, and %d rows: %d × %d = %d." % [b, a, a, b, count]
			else:
				mark = 3
				count = a
				work = "MOVE is in the outer loop only (under its REPEAT, not the inner one), so it runs %d times." % a
		3:
			var a := rng.randi_range(2, 3)
			var b := rng.randi_range(2, 3)
			var c := rng.randi_range(2, 4)
			lines = ["REPEAT %d TIMES" % a, "  REPEAT %d TIMES" % b, "    REPEAT %d TIMES" % c, "      " + act]
			mark = 3
			count = a * b * c
			work = "Multiply the loops: %d × %d × %d = %d." % [a, b, c, count]
	var ex := K.number("How many times does the marked line run?", count,
		"Start with the innermost loop: how many times does it run the line? Then how many times does the loop around it run?",
		work, {"kind": "code", "lines": lines, "mark": mark})
	ex.data = {"lines": lines, "mark": mark}
	return ex


## A pen program with loops. Level 1: how long is the line a loop draws; level 2: a row of squares (loops inside loops,
## the pen lifted between them); level 3: which drawing does the program make?
static func pen_loop(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		return _which_drawing(rng)
	var lines: Array[String] = []
	var length := 0
	var work := ""
	if level == 1:
		var n := rng.randi_range(2, 4)
		var k := rng.randi_range(1, 3)
		var turn := "TURN LEFT" if rng.randi() % 2 == 0 else "TURN RIGHT"
		lines = ["REPEAT %d TIMES" % n, "  FORWARD %d" % k, "  " + turn]
		length = n * k
		work = "Each time round it draws a line %d square%s long, and it goes round %d times: %d × %d = %d." % [k,
			"" if k == 1 else "s", n, n, k, length]
	else:
		var a := rng.randi_range(2, 3)
		var k := rng.randi_range(1, 2)
		lines = ["REPEAT %d TIMES" % a, "  REPEAT 4 TIMES", "    FORWARD %d" % k, "    TURN LEFT", "  PEN UP",
			"  FORWARD %d" % (k + 1), "  PEN DOWN"]
		length = a * 4 * k
		work = "Each square has 4 sides of %d: 4 × %d = %d. There are %d squares: %d × %d = %d. The pen is up for the gaps." % [
			k, k, 4 * k, a, a, 4 * k, length]
	var ex := K.number("The pen draws what this program says. How long is the line it draws, in squares?", length,
		"Work out one time round the loop first, then multiply by how many times it runs. PEN UP moves draw nothing.",
		work, {"kind": "code", "lines": lines})
	ex.data = {"lines": lines}
	return ex


static func _which_drawing(rng: RandomNumberGenerator) -> Dictionary:
	# [program, its name in words]; the wrong drawings change one thing in it
	var k := rng.randi_range(1, 2)
	var programs: Array = [
		[["REPEAT 4 TIMES", "  FORWARD %d" % (k + 1), "  TURN LEFT"], "a square"],
		[["REPEAT 3 TIMES", "  FORWARD 1", "  TURN LEFT", "  FORWARD 1", "  TURN RIGHT"], "a staircase"],
		[["REPEAT 2 TIMES", "  FORWARD %d" % (k + 2), "  TURN LEFT", "  FORWARD %d" % k, "  TURN LEFT"], "a rectangle"],
		[["REPEAT 3 TIMES", "  REPEAT 4 TIMES", "    FORWARD 1", "    TURN LEFT", "  FORWARD 2"],
			"three squares joined along a line"]]
	var pick: Array = programs[rng.randi_range(0, programs.size() - 1)]
	var right: Array[String] = []
	right.assign(pick[0])
	var wrongs: Array = []
	for variant in _pen_variants(right):
		if wrongs.size() < 3 and _pen_segments(variant) != _pen_segments(right) and _pen_segments(variant).size() > 0:
			var dup := false
			for w: Dictionary in wrongs:
				dup = dup or _pen_segments(w.picture.lines) == _pen_segments(variant)
			if not dup:
				wrongs.append({"picture": {"kind": "pen", "lines": variant, "cols": 8, "rows": 5}})
	var ex := K.choice(rng, "Which drawing does this program make? The pen starts at the green dot, facing right.",
		{"picture": {"kind": "pen", "lines": right, "cols": 8, "rows": 5}}, wrongs,
		"Follow the program with your finger on squared paper: one time round the loop first, then again.",
		"It draws %s: %s." % [pick[1], _pen_words(right)], {"kind": "code", "lines": right})
	ex.data = {"lines": right}
	return ex


## Programs one change away from `lines`: a loop's number, a FORWARD's number, a turn the other way.
static func _pen_variants(lines: Array[String]) -> Array:
	var out: Array = []
	for i in lines.size():
		var t := lines[i].strip_edges()
		var indent := lines[i].substr(0, lines[i].length() - lines[i].lstrip(" ").length())
		var swaps: Array[String] = []
		if t.begins_with("REPEAT "):
			var n := int(t.get_slice(" ", 1))
			for m in [n - 1, n + 1]:
				if m >= 1:
					swaps.append("REPEAT %d TIMES" % m)
		elif t.begins_with("FORWARD "):
			var n := int(t.get_slice(" ", 1))
			for m in [n + 1, n - 1]:
				if m >= 1:
					swaps.append("FORWARD %d" % m)
		elif t == "TURN LEFT":
			swaps.append("TURN RIGHT")
		elif t == "TURN RIGHT":
			swaps.append("TURN LEFT")
		for sw in swaps:
			var v: Array[String] = lines.duplicate()
			v[i] = indent + sw
			out.append(v)
	return out


## The squares' sides a pen program draws on 8 × 5 paper from the bottom left, facing right ([] when it leaves the
## paper): SchoolPictureG5Arts.trace's rules, kept here so generators need no picture code.
static func _pen_segments(lines: Array) -> Array:
	var state := {"pos": Vector2i(0, 5), "facing": 1, "pen": true, "segments": [], "ok": true}
	var top: Array[int] = []
	for i in lines.size():
		if not str(lines[i]).begins_with(" "):
			top.append(i)
	_pen_do(lines, top, state)
	if not state.ok:
		return []
	var out: Array = state.segments
	out.sort()
	return out


static func _pen_do(lines: Array, which: Array[int], st: Dictionary) -> void:
	var steps: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for i in which:
		var t := str(lines[i]).strip_edges()
		if t.begins_with("REPEAT "):
			var inner: Array[int] = []
			var d := str(lines[i]).length() - str(lines[i]).lstrip(" ").length()
			for j in range(i + 1, lines.size()):
				var dj := str(lines[j]).length() - str(lines[j]).lstrip(" ").length()
				if dj <= d:
					break
				if dj == d + 2:
					inner.append(j)
			for k in int(t.get_slice(" ", 1)):
				_pen_do(lines, inner, st)
		elif t.begins_with("FORWARD"):
			for k in (int(t.get_slice(" ", 1)) if t.contains(" ") else 1):
				var next: Vector2i = st.pos + steps[int(st.facing)]
				if next.x < 0 or next.y < 0 or next.x > 8 or next.y > 5:
					st.ok = false
					return
				if st.pen:
					var a: Vector2i = st.pos
					(st.segments as Array).append("%d,%d-%d,%d" % [mini(a.x, next.x), mini(a.y, next.y), maxi(a.x, next.x),
						maxi(a.y, next.y)])
				st.pos = next
		elif t == "TURN LEFT":
			st.facing = (int(st.facing) + 3) % 4
		elif t == "TURN RIGHT":
			st.facing = (int(st.facing) + 1) % 4
		elif t == "PEN UP" or t == "PEN DOWN":
			st.pen = t == "PEN DOWN"


static func _pen_words(lines: Array[String]) -> String:
	var parts: Array[String] = []
	for l in lines:
		parts.append(l.strip_edges())
	return ", ".join(parts)


## Procedures: DEFINE names some steps; a line that is only the name runs them. How many times does the marked line
## run? Level 1: called a few times; level 2: called in a loop (and maybe once more); level 3: a loop inside the
## procedure, called in a loop.
static func call_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array[String] = ["hop", "cheer", "spin", "bounce", "dance"]
	var name := names[rng.randi_range(0, names.size() - 1)]
	var acts: Array[String] = ["JUMP", "CLAP", "NOD", "STAMP", "WAVE a hand"]
	var act := acts[rng.randi_range(0, acts.size() - 1)]
	var lines: Array[String] = []
	var mark := 1
	var count := 0
	var work := ""
	match level:
		1:
			var k := rng.randi_range(2, 3)
			lines = ["DEFINE " + name, "  " + act, "  TURN round"]
			for i in k:
				lines.append(name)
			count = k
			work = "The steps under DEFINE run only when %s is called. It is called %d times, so %s runs %d times." % [
				name, k, act, k]
		2:
			var n := rng.randi_range(2, 5)
			var extra := rng.randi() % 2 == 0
			lines = ["DEFINE " + name, "  " + act, "  TURN round", "REPEAT %d TIMES" % n, "  " + name]
			if extra:
				lines.append(name)
			count = n + (1 if extra else 0)
			work = "The loop calls %s %d times%s: %s runs %d times." % [name, n, ", and it is called once more" if extra
				else "", act, count]
		3:
			var m := rng.randi_range(2, 3)
			var n := rng.randi_range(2, 4)
			lines = ["DEFINE " + name, "  REPEAT %d TIMES" % m, "    " + act, "REPEAT %d TIMES" % n, "  " + name]
			mark = 2
			count = m * n
			work = "Each call runs %s %d times, and the loop calls %s %d times: %d × %d = %d." % [act, m, name, n, n, m, count]
	var ex := K.number("How many times does the marked line run?", count,
		"The steps under DEFINE wait until something calls the procedure by its name. Count the calls, then how many times each call runs the line.",
		work, {"kind": "code", "lines": lines, "mark": mark})
	ex.data = {"lines": lines, "mark": mark}
	return ex


## Simulate it: level 1 a plant that grows the same each day; level 2 a ball that falls at a steady speed and bounces
## up from the floor; level 3 a falling ball that speeds up each step (gravity).
static func bounce_sim(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array[String] = []
	var ask := ""
	var value := 0
	var work := ""
	match level:
		1:
			var h := rng.randi_range(1, 5)
			var g := rng.randi_range(2, 4)
			var n := rng.randi_range(3, 6)
			lines = ["SET height TO %d" % h, "REPEAT %d TIMES" % n, "  CHANGE height BY %d" % g]
			ask = "height"
			value = h + n * g
			work = "It grows %d each day for %d days: %d × %d = %d, and %d + %d = %d." % [g, n, n, g, n * g, h, n * g, value]
		2:
			var v := rng.randi_range(2, 3)
			var k := rng.randi_range(2, 4)
			var n := k + rng.randi_range(1, 3)
			lines = ["SET y TO %d" % (v * k), "SET speed TO -%d" % v, "REPEAT %d TIMES" % n, "  CHANGE y BY speed",
				"  IF y = 0", "    SET speed TO %d" % v]
			ask = "y"
			var y := v * k
			var speed := -v
			var seen: Array[String] = []
			for i in n:
				y += speed
				if y == 0:
					speed = v
				seen.append(str(y))
			value = y
			work = "Step by step, y is %s: it falls %d a step, reaches the floor (0), and the IF sends it back up." % [
				", ".join(seen), v]
		3:
			var n := rng.randi_range(3, 5)
			var h := n * (n + 1) / 2 + rng.randi_range(0, 10)
			lines = ["SET y TO %d" % h, "SET speed TO 0", "REPEAT %d TIMES" % n, "  CHANGE speed BY -1", "  CHANGE y BY speed"]
			ask = "y"
			var y := h
			var seen: Array[String] = []
			for i in n:
				y -= i + 1
				seen.append(str(y))
			value = y
			work = "The speed gets 1 faster each step (−1, −2, −3 …), so y goes %s: it falls further every step." % ", ".join(seen)
	var ex := K.number("This simulation runs step by step. What is %s when it ends?" % ask, value,
		"Make a table: one row for each time round the loop. Write every variable after each line.", work,
		{"kind": "code", "lines": lines})
	ex.data = {"lines": lines, "var": ask}
	return ex


const MESSAGES: Array[String] = ["SEE YOU AT THE LAKE", "MEET AT THE OAK TREE", "BRING THE MAP", "THE BOAT IS READY",
	"LOOK UP AT THE MOON", "HELLO FROM THE CAVE", "FEED THE BUDDIES"]


## How messages travel. Level 1: how many packets a message needs; level 2: packets arrive out of order: put them back
## by their numbers; level 3: a picture's kilobytes in packets.
static func packet_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	match level:
		1:
			var length := rng.randi_range(12, 40)
			var size := rng.randi_range(3, 8)
			var n := int(ceil(length / float(size)))
			var ex := K.number("A message has %d letters and spaces. Each packet carries %d of them. How many packets does it need?" % [
				length, size], n,
				"Share the letters into packets of the same size. A last packet that is not full is still a packet.",
				_packets_work(length, size, n, "letters and spaces"))
			ex.data = {"total": length, "size": size}
			return ex
		2:
			for _try in 50:
				var message := MESSAGES[rng.randi_range(0, MESSAGES.size() - 1)]
				var size := rng.randi_range(4, 6)
				var parts: Array[String] = []
				var at := 0
				while at < message.length():
					parts.append(message.substr(at, size).replace(" ", "·"))
					at += size
				var distinct := {}
				for p in parts:
					distinct[p] = true
				if parts.size() < 3 or parts.size() > 5 or distinct.size() != parts.size():
					continue
				var order: Array = range(parts.size())
				while order == range(parts.size()):
					K.shuffle(rng, order)
				return _packets_in_order(rng, message, size, parts, order)
			var fallback: Array[String] = ["BRING", "·THE·", "MAP"]
			return _packets_in_order(rng, "BRING THE MAP", 5, fallback, [2, 0, 1])
		3:
			var size: int = [4, 5, 8, 10][rng.randi_range(0, 3)]
			var kb := rng.randi_range(5, 30) * size + rng.randi_range(0, size - 1)
			var n := int(ceil(kb / float(size)))
			var ex := K.number("A picture is %d KB (kilobytes). Each packet carries %d KB of it. How many packets does it need?" % [
				kb, size], n, "Divide the picture into packets of the same size. A last packet that is not full is still a packet.",
				_packets_work(kb, size, n, "KB"))
			ex.data = {"total": kb, "size": size}
			return ex
	return {}


static func _packets_in_order(rng: RandomNumberGenerator, message: String, size: int, parts: Array[String],
		order: Array) -> Dictionary:
	var ex := K.order(rng, "The packets arrived in a muddle. Put them in order to read the message.", parts,
		"Every packet has its number: 1 of %d, 2 of %d … The number, not when it came, says where it goes." % [parts.size(),
			parts.size()], "By their numbers: %s. The message: %s." % [", ".join(parts), message],
		{"kind": "packets", "message": message, "size": size, "order": order})
	ex.data = {"message": message, "size": size, "order": order}
	return ex


static func _packets_work(total: int, size: int, n: int, what: String) -> String:
	if total % size == 0:
		return "%d ÷ %d = %d: %d full packets of %d %s." % [total, size, n, n, size, what]
	return "%d ÷ %d = %d remainder %d: %d full packets and one more for the last %d, so %d packets." % [total, size,
		total / size, total % size, total / size, total % size, n]


const PAGES: Array[String] = ["Bee Club", "Honey Farm", "Garden Tips", "Nature Notes", "Buzz Facts", "Meadow News"]


## How a (simple) search engine ranks: the pages with more of your search words first; a tie goes to the page more
## other pages link to. Level 1: 3 pages, different words; level 2: a tie; level 3: 4 pages with ties.
static func rank_results(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 4 if level == 3 else 3
	var pages: Array = PAGES.duplicate()
	K.shuffle(rng, pages)
	pages = pages.slice(0, n)
	var words: Array[int] = []
	var links: Array[int] = []
	for _try in 200:
		words.clear()
		links.clear()
		for i in n:
			words.append(rng.randi_range(1, 4))
			links.append(rng.randi_range(0, 30))
		var distinct_links := {}
		for l in links:
			distinct_links[l] = true
		var distinct_words := {}
		for w in words:
			distinct_words[w] = true
		var tied := distinct_words.size() < n
		if distinct_links.size() == n and ((level == 1 and not tied) or (level > 1 and tied)):
			break
		if _try == 199:
			words.assign([4, 2, 1] if level == 1 else ([3, 3, 1] if level == 2 else [3, 3, 1, 2]))
			links.assign([12, 20, 5] if n == 3 else [12, 20, 5, 9])
	var idx: Array = range(n)
	idx.sort_custom(func(a: int, b: int) -> bool: return words[a] > words[b] or (words[a] == words[b] and links[a] > links[b]))
	var in_order: Array = []
	var rows: Array = [["Page", "Search words", "Links to it"]]
	for i in n:
		rows.append([str(pages[i]), str(words[i]), str(links[i])])
	var said: Array[String] = []
	for i: int in idx:
		in_order.append(str(pages[i]))
		said.append("%s (%d words, %d links)" % [pages[i], words[i], links[i]])
	var ex := K.order(rng, "This search engine puts pages with more of your search words first; if two have the same, the one more pages link to comes first. Put the pages in order.",
		in_order, "Sort by search words first, biggest first. Only when two pages have the same words, look at the links.",
		"First to last: %s." % ", ".join(said), {"kind": "table", "rows": rows})
	ex.data = {"pages": pages, "words": words, "links": links}
	return ex


## Spreadsheets. Level 1: what a SUM shows; level 2: SUM of more, MAX, MIN, or a price times how many; level 3: change
## a number and the formula works it out again.
static func sheet_sum(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var buddies: Array = ["Pip", "Moss", "Fizz", "Bolt", "Lumo"]
	K.shuffle(rng, buddies)
	if level == 2 and rng.randi() % 3 == 0:   # price × how many
		var items: Array = ["rope", "lamp", "seeds", "bucket"]
		K.shuffle(rng, items)
		var cells: Array = [["Item", "Cost", "How many", "Total"]]
		var n := rng.randi_range(2, 3)
		for i in n:
			cells.append([str(items[i]), str(rng.randi_range(2, 9)), str(rng.randi_range(2, 6)), "=B%d*C%d" % [i + 2, i + 2]])
		var r := rng.randi_range(2, n + 1)
		var cost := int(cells[r - 1][1])
		var many := int(cells[r - 1][2])
		var ex := K.number("What will D%d show?" % r, cost * many,
			"A formula starts with =. B%d*C%d means the number in B%d times the number in C%d." % [r, r, r, r],
			"D%d = B%d × C%d = %d × %d = %d gold." % [r, r, r, cost, many, cost * many],
			{"kind": "sheet", "cells": cells, "show": "formulas", "mark": "D%d" % r})
		ex.data = {"cells": cells, "cell": "D%d" % r}
		return ex
	var n := 3 if level == 1 else rng.randi_range(3, 5)
	var cells: Array = [["Buddy", "Gems"]]
	var values: Array[int] = []
	for i in n:
		var v := rng.randi_range(2, 25)
		values.append(v)
		cells.append([str(buddies[i]), str(v)])
	var fn := "SUM"
	if level == 2:
		fn = ["SUM", "MAX", "MIN"][rng.randi_range(0, 2)]
	var last := n + 1
	cells.append([{"SUM": "Total", "MAX": "Most", "MIN": "Fewest"}[fn], "=%s(B2:B%d)" % [fn, last]])
	var target := "B%d" % (n + 2)
	var prompt := "What will %s show?" % target
	var changed := ""
	if level == 3:
		var row := rng.randi_range(2, last)
		var old := values[row - 2]
		var now := old
		while now == old:
			now = rng.randi_range(2, 30)
		values[row - 2] = now
		changed = "B%d" % row
		prompt = "%s changes %s from %d to %d. What will %s show now?" % [NAMES[rng.randi_range(0, NAMES.size() - 1)],
			changed, old, now, target]
	var result := 0
	match fn:
		"SUM":
			for v in values:
				result += v
		"MAX":
			result = values.max()
		"MIN":
			result = values.min()
	var listed: Array[String] = []
	for v in values:
		listed.append(str(v))
	var work := ""
	match fn:
		"SUM":
			work = "SUM adds B2 to B%d: %s = %d." % [last, " + ".join(listed), result]
		"MAX":
			work = "MAX finds the biggest of %s: %d." % [", ".join(listed), result]
		"MIN":
			work = "MIN finds the smallest of %s: %d." % [", ".join(listed), result]
	if level == 3:
		work = "The formula works it out again with the new number. " + work
	var ex := K.number(prompt, result,
		"A formula starts with =. B2:B%d means every cell from B2 down to B%d. SUM adds them, MAX finds the biggest, MIN the smallest." % [
			last, last], work, {"kind": "sheet", "cells": cells, "show": "formulas", "mark": target})
	ex.data = {"cells": cells, "cell": target, "changed": changed, "values": values, "fn": fn}
	return ex


## Read a column chart. Level 1: one bar's value; level 2: how many more one bar is than another; level 3: a chart
## whose axis starts above 0, so a bar that looks 2 or 3 times as tall is only a little more.
static func chart_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = ["Pip", "Moss", "Fizz", "Bolt"]
	K.shuffle(rng, names)
	if level < 3:
		var step: int = [1, 2, 5][rng.randi_range(0, 2)]
		var top := step * 10
		var bars: Array = []
		var values: Array[int] = []
		while values.size() < 4:
			var v := step * rng.randi_range(1, 10)
			if not values.has(v):
				values.append(v)
		for i in 4:
			bars.append([str(names[i]), values[i]])
		var pic := {"kind": "column_chart", "bars": bars, "to": top, "step": step, "title": "Gems found"}
		if level == 1:
			var i := rng.randi_range(0, 3)
			var ex := K.number("How many gems did %s find?" % names[i], values[i],
				"Go from the top of the bar straight across to the numbers on the side.",
				"The top of %s's bar is level with %d." % [names[i], values[i]], pic)
			ex.data = {"bars": bars, "from": 0, "ask": [i]}
			return ex
		var a := rng.randi_range(0, 3)
		var b := (a + rng.randi_range(1, 3)) % 4
		if values[a] < values[b]:
			var t := a
			a = b
			b = t
		var ex := K.number("How many more gems did %s find than %s?" % [names[a], names[b]], values[a] - values[b],
			"Read both bars on the numbers at the side, then take the smaller from the bigger.",
			"%s: %d, %s: %d. %d − %d = %d." % [names[a], values[a], names[b], values[b], values[a], values[b],
				values[a] - values[b]], pic)
		ex.data = {"bars": bars, "from": 0, "ask": [a, b]}
		return ex
	var from := rng.randi_range(4, 9) * 10
	var small := rng.randi_range(1, 3)
	var times := rng.randi_range(2, 3)
	var big := small * times
	var to := from + big + rng.randi_range(0, mini(2, 10 - big))
	var bars: Array = [[str(names[0]), from + small], [str(names[1]), from + big]]
	var ex := K.number("This chart starts at %d, not 0. %s's bar looks %d times as tall as %s's. How many more gems did %s really find?" % [
		from, names[1], times, names[0], names[1]], big - small,
		"Read the real numbers on the side, not how tall the bars look. Then take one from the other.",
		"%s found %d and %s found %d: %d − %d = %d more. Starting the axis at %d makes a small difference look big." % [
			names[1], from + big, names[0], from + small, from + big, from + small, big - small, from],
		{"kind": "column_chart", "bars": bars, "from": from, "to": to, "step": 1, "title": "Gems found"})
	ex.data = {"bars": bars, "from": from, "ask": [1, 0]}
	return ex


## Real or edited: shadows fall away from the sun, so a thing whose shadow falls towards it was pasted in. Level 1: two
## things; level 2: three; level 3: four.
static func odd_shadow(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kinds: Array[String] = ["tree", "person", "post"]
	var n := level + 1
	var things: Array[String] = []
	for i in n:
		things.append(kinds[rng.randi_range(0, kinds.size() - 1)])
	var sun := "left" if rng.randi() % 2 == 0 else "right"
	var odd := rng.randi_range(0, n - 1)
	var choices: Array = []
	for i in n:
		choices.append("the %s from the left" % ORDINALS[i])
	var away := "right" if sun == "left" else "left"
	var ex := K.choice(rng, "The sun is on the %s. One thing was pasted into this photo from another one. Which?" % sun,
		str(choices[odd]), choices.filter(func(c: String) -> bool: return c != str(choices[odd])),
		"Where does light make shadows fall: towards the sun, or away from it? Look for the shadow that is different.",
		"Shadows fall away from the sun: to the %s. The %s thing from the left has its shadow towards the sun, so it came from another photo." % [
			away, ORDINALS[odd]], {"kind": "shadow_photo", "things": things, "sun": sun, "odd": odd})
	ex.data = {"sun": sun, "odd": odd, "things": things}
	return ex


# --- Art ---------------------------------------------------------------------------------------------------------------

const TILE_COLOURS: Array[String] = ["blue", "white", "red", "yellow", "green", "black"]


## Mosaic tiles. Level 1: a rectangle's tiles; level 2: count one colour's tiles in a picture; level 3: a border one
## tile wide round a panel.
static func mosaic_tiles(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var colours: Array = TILE_COLOURS.duplicate()
	K.shuffle(rng, colours)
	match level:
		1:
			var w := rng.randi_range(6, 15)
			var h := rng.randi_range(4, 12)
			var ex := K.number("A mosaic panel is %d tiles wide and %d tiles tall, with no gaps. How many tiles does it need?" % [w, h],
				w * h, "Think of it as rows of tiles: how many rows, and how many tiles in each?",
				"%d rows of %d tiles: %d × %d = %d tiles." % [h, w, h, w, w * h])
			ex.data = {"w": w, "h": h}
			return ex
		2:
			var w := rng.randi_range(4, 8)
			var h := rng.randi_range(3, 5)
			var rows: Array[String] = []
			var count := 0
			for y in h:
				var row := ""
				for x in w:
					var a := rng.randi() % 3 == 0
					row += "a" if a else "b"
					count += 1 if a else 0
				rows.append(row)
			if count == 0:
				rows[0] = "a" + rows[0].substr(1)
				count = 1
			var colour := str(colours[0])
			var ex := K.number("How many %s tiles are in this mosaic?" % colour, count,
				"Count row by row, and add the rows up. Touching each tile as you count helps.",
				"Row by row: %s. That is %d %s tiles." % [_row_counts(rows, "a"), count, colour],
				{"kind": "mosaic", "rows": rows, "key": {"a": colour, "b": str(colours[1])}})
			ex.data = {"rows": rows, "letter": "a"}
			return ex
		_:
			var w := rng.randi_range(5, 10)
			var h := rng.randi_range(4, 7)
			var rows: Array[String] = []
			for y in h:
				var row := ""
				for x in w:
					row += "a" if x == 0 or y == 0 or x == w - 1 or y == h - 1 else "b"
				rows.append(row)
			var border := w * h - (w - 2) * (h - 2)
			var ex := K.number("This mosaic is %d tiles wide and %d tall, with a border one tile wide. How many tiles are in the border?" % [
				w, h], border, "Count all the tiles, then take away the tiles inside the border (2 fewer each way).",
				"All: %d × %d = %d. Inside: %d × %d = %d. Border: %d − %d = %d." % [w, h, w * h, w - 2, h - 2, (w - 2) * (h - 2),
					w * h, (w - 2) * (h - 2), border],
				{"kind": "mosaic", "rows": rows, "key": {"a": str(colours[0]), "b": str(colours[1])}})
			ex.data = {"w": w, "h": h, "rows": rows}
			return ex


static func _row_counts(rows: Array[String], letter: String) -> String:
	var parts: Array[String] = []
	for r in rows:
		parts.append(str(r.count(letter)))
	var total := 0
	for p in parts:
		total += int(p)
	return "%s = %d" % [" + ".join(parts), total] if parts.size() > 1 else parts[0]


const ORDERS := {"doric": "a plain cushion under a flat slab", "ionic": "two scrolls, like curled ram's horns",
	"corinthian": "leaves of the acanthus plant"}


## The Greek orders. Level 1: which order is this column; level 2: which order is described; level 3: pick the
## column of an order.
static func column_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = ORDERS.keys()
	var o := str(names[rng.randi_range(0, 2)])
	var others: Array = names.filter(func(n: String) -> bool: return n != o)
	var hint := "Look at the top of the column (its capital): plain, scrolls, or leaves?"
	var why := "The %s capital has %s." % [o.capitalize(), ORDERS[o]]
	var other_names: Array = others.map(func(n: String) -> String: return n.capitalize())
	var other_pictures: Array = others.map(func(n: String) -> Dictionary: return {"picture": {"kind": "greek_column", "orders": [n]}})
	var ex := {}
	match level:
		1:
			ex = K.choice(rng, "Which Greek order is this column?", o.capitalize(), other_names, hint, why,
				{"kind": "greek_column", "orders": [o]})
		2:
			ex = K.choice(rng, "Which Greek order's capital (the top of the column) has %s?" % ORDERS[o], o.capitalize(), other_names,
				"Doric is the plainest, Ionic has scrolls, Corinthian is the fanciest.", why)
		_:
			ex = K.choice(rng, "Which column is %s?" % o.capitalize(), {"picture": {"kind": "greek_column", "orders": [o]}},
				other_pictures, hint, why)
	ex.data = {"order": o}
	return ex


## Famous buildings: [name, the country (only for a drawing of one famous building)].
const BUILDING_FACTS := {"pyramid": ["the Great Pyramid of Giza", "Egypt"], "parthenon": ["the Parthenon", "Greece"],
	"pantheon": ["the Pantheon", "Italy"], "aqueduct": ["a Roman aqueduct", ""], "cathedral": ["a Gothic cathedral", ""],
	"taj_mahal": ["the Taj Mahal", "India"], "pagoda": ["a pagoda", ""], "skyscraper": ["a skyscraper", ""]}
const SPANS := {"lintel": "post and lintel", "round_arch": "a round arch", "pointed_arch": "a pointed arch",
	"pantheon": "a dome", "parthenon": "post and lintel", "aqueduct": "round arches", "cathedral": "pointed arches",
	"skyscraper": "a steel frame"}


## Level 1: which building is this; level 2: which country is it in (the famous one of its kind); level 3: how is it
## held up (post and lintel, arches, a dome, a frame).
static func building_facts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	if level == 3:
		var keys: Array = SPANS.keys()
		var what := str(keys[rng.randi_range(0, keys.size() - 1)])
		var right := str(SPANS[what])
		var wrongs: Array = []
		for s: String in ["post and lintel", "a round arch", "a pointed arch", "a dome", "a steel frame"]:
			if s != right and not (right.begins_with("round") and s == "a round arch") \
					and not (right.begins_with("pointed") and s == "a pointed arch"):
				wrongs.append(s)
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "How does this hold up its roof or its top?", right, wrongs.slice(0, 3),
			"Look at the openings: a flat beam across posts, a curve, a curve with a point, or a round roof?",
			"It uses %s." % right, {"kind": "building", "what": what})
		ex.data = {"what": what}
		return ex
	var keys: Array = BUILDING_FACTS.keys()
	if level == 2:
		keys = keys.filter(func(k: String) -> bool: return str(BUILDING_FACTS[k][1]) != "")
	var what := str(keys[rng.randi_range(0, keys.size() - 1)])
	var col := level - 1
	var right := str(BUILDING_FACTS[what][col])
	var wrongs: Array = []
	for k: String in keys:
		var w := str(BUILDING_FACTS[k][col])
		if w != right and w != "" and not wrongs.has(w):
			wrongs.append(w)
	K.shuffle(rng, wrongs)
	var prompt := "Which building is this?" if level == 1 else "Which country is %s in?" % BUILDING_FACTS[what][0]
	var where := str(BUILDING_FACTS[what][1])
	ex = K.choice(rng, prompt, right, wrongs.slice(0, 3),
		"Look at its shape: steps, columns, arches, a dome, pointed towers or floors of roofs?",
		("It is %s, in %s." % [BUILDING_FACTS[what][0], where]) if where != "" else "It is %s." % BUILDING_FACTS[what][0],
		{"kind": "building", "what": what})
	ex.data = {"what": what}
	return ex


## Light and shadow in a still life. Level 1: which side of an object is in shadow; level 2: where the cast shadow
## falls; level 3: which drawing is shaded right for the light.
static func light_and_shadow(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var objects: Array[String] = ["apple", "pear", "lemon", "jug", "bowl", "bottle", "cup"]
	var obj := objects[rng.randi_range(0, objects.size() - 1)]
	var light := "left" if rng.randi() % 2 == 0 else "right"
	var dark := "right" if light == "left" else "left"
	var ex := {}
	match level:
		1:
			ex = K.choice(rng, "The lamp is on the %s. Which side of the %s is in shadow?" % [light, obj], "the %s side" % dark,
				["the %s side" % light, "the top", "none of it"], "Light can only reach the side that faces the lamp.",
				"The %s side faces away from the lamp, so it is in shadow; the %s side is lit." % [dark, light],
				{"kind": "still_life", "objects": [obj], "light": light, "shade": false})
		2:
			ex = K.choice(rng, "The lamp is on the %s. Where does the %s's cast shadow fall?" % [light, obj],
				"on the table, to the %s" % dark, ["on the table, to the %s" % light, "on the %s itself" % obj,
				"on the wall above it"], "The object blocks the light. Where is the light blocked?",
				"The %s blocks the light, so its cast shadow falls on the table on the side away from the lamp: to the %s." % [
					obj, dark], {"kind": "still_life", "objects": [obj], "light": light, "shade": false})
		_:
			var more: Array[String] = objects.filter(func(o: String) -> bool: return o != obj)
			var pair: Array = [obj, more[rng.randi_range(0, more.size() - 1)]]
			ex = K.choice(rng, "The lamp is on the %s. Which drawing is shaded for that light?" % light,
				{"picture": {"kind": "still_life", "objects": pair, "light": light}},
				[{"picture": {"kind": "still_life", "objects": pair, "light": dark}}],
				"Find the highlights: they face the lamp. The cast shadows point away from it.",
				"The drawing that fits has its highlights on the %s, facing the lamp, and its cast shadows to the %s." % [
					light, dark])
	ex.data = {"light": light}
	return ex


## Weaving: which row comes next? Level 1: plain weave (over one, under one, swapping each row); level 2: twill (each
## row one step along: diagonal lines); level 3: basket weave (pairs of threads, each row twice).
static func weave_next(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := 8 if rng.randi() % 2 == 0 else 6
	var rows: Array[String] = []
	var next := ""
	var name := ""
	match level:
		1:
			name = "plain weave"
			var first := "ou".repeat(w / 2) if rng.randi() % 2 == 0 else "uo".repeat(w / 2)
			for i in rng.randi_range(2, 3):
				rows.append(first if i % 2 == 0 else _flip(first))
			next = _flip(rows[-1])
		2:
			name = "twill"
			var first := "oouuoouu"
			var dir := 1 if rng.randi() % 2 == 0 else -1
			var row := first
			for i in 3:
				rows.append(row)
				row = _shift(row, dir)
			next = row
		_:
			name = "basket weave"
			w = 8
			var first := "oouu".repeat(2) if rng.randi() % 2 == 0 else "uuoo".repeat(2)
			var start := rng.randi_range(0, 1)
			var seq: Array[String] = [first, first, _flip(first), _flip(first)]
			for i in 4:
				rows.append(seq[(start + i) % 4])
			next = seq[(start + 4) % 4]
	var wrongs: Array = []
	for cand: String in [_flip(next), _shift(next, 1), _shift(next, -1), rows[-1], _flip(rows[-1]),
			"oouuoouu".left(next.length()), "uuoouuoo".left(next.length()), "ooouuuoo".left(next.length())]:
		if cand != next and not wrongs.has(cand) and wrongs.size() < 3:
			wrongs.append(cand)
	var as_pic := func(r: String) -> Dictionary: return {"picture": {"kind": "weave", "rows": [r]}}
	var ex := K.choice(rng, "This is %s. Which row comes next?" % name, as_pic.call(next), wrongs.map(as_pic),
		"Look at how each row changes from the one before, then do the same again.",
		"The next row is %s (o over, u under): %s." % [next, {"plain weave": "each row swaps over and under",
			"twill": "each row moves one step along, making diagonal lines",
			"basket weave": "pairs of threads, each pattern woven twice"}[name]],
		{"kind": "weave", "rows": rows})
	ex.data = {"rows": rows, "rule": name}
	return ex


static func _flip(r: String) -> String:
	return r.replace("o", "x").replace("u", "o").replace("x", "u")


## The row moved one step along (dir 1: to the right, -1: to the left), wrapping round.
static func _shift(r: String, dir: int) -> String:
	return r.right(1) + r.left(r.length() - 1) if dir == 1 else r.substr(1) + r.left(1)


# --- Music -------------------------------------------------------------------------------------------------------------

## Chords of the white keys: [the notes on the stave (root position), major or minor].
const CHORDS := {"C": [["C4", "E4", "G4"], "major"], "F": [["F4", "A4", "C5"], "major"], "G": [["G4", "B4", "D5"], "major"],
	"Am": [["A4", "C5", "E5"], "minor"], "Dm": [["D4", "F4", "A4"], "minor"], "Em": [["E4", "G4", "B4"], "minor"]}
## Five notes up from home and back: [notes, major or minor].
const TUNES := [[["C4", "D4", "E4", "F4", "G4", "F4", "E4", "D4", "C4:2"], "major"],
	[["F4", "G4", "A4", "Bb4", "C5", "Bb4", "A4", "G4", "F4:2"], "major"],
	[["G4", "A4", "B4", "C5", "D5", "C5", "B4", "A4", "G4:2"], "major"],
	[["A4", "B4", "C5", "D5", "E5", "D5", "C5", "B4", "A4:2"], "minor"],
	[["D4", "E4", "F4", "G4", "A4", "G4", "F4", "E4", "D4:2"], "minor"],
	[["E4", "F#4", "G4", "A4", "B4", "A4", "G4", "F#4", "E4:2"], "minor"]]


static func _chord_name(key: String) -> String:
	return "%s %s" % [key.left(1), CHORDS[key][1]]


## Major or minor, by ear. Level 1: a chord; level 2: a broken chord (its notes one by one, up and down); level 3: a
## tune of five notes up and back.
static func major_or_minor(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var notes: Array = []
	var quality := ""
	var what := ""
	if level < 3:
		var keys: Array = CHORDS.keys()
		var key := str(keys[rng.randi_range(0, keys.size() - 1)])
		var c: Array = CHORDS[key][0]
		quality = str(CHORDS[key][1])
		if level == 1:
			notes = ["%s+%s+%s:3" % [c[0], c[1], c[2]]]
			what = "chord"
		else:
			notes = [c[0], c[1], c[2], c[1], "%s:2" % c[0]]
			what = "broken chord"
	else:
		var t: Array = TUNES[rng.randi_range(0, TUNES.size() - 1)]
		notes = (t[0] as Array).duplicate()
		quality = str(t[1])
		what = "tune"
	var ex := K.choice(rng, "Listen. Is this %s major or minor?" % what, quality, ["minor" if quality == "major" else "major"],
		"Major usually sounds bright and happy; minor sounds darker or sad. %s" % ("Listen to the middle note of the chord."
			if level < 3 else "Listen for the third note up from the home note."),
		"It is %s: %s." % [quality, "its third note is 4 semitones above the home note, a bright sound" if quality == "major"
			else "its third note is only 3 semitones above the home note, a darker sound"])
	ex.sound = {"kind": "notes", "notes": notes}
	ex.data = {"notes": notes}
	return ex


## Building chords: a root, then skip a letter, then skip another. Level 1: which notes make a major chord; level 2: a
## minor chord; level 3: which chord is on the stave.
static func build_chord(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var majors: Array[String] = ["C", "F", "G"]
	var minors: Array[String] = ["Am", "Dm", "Em"]
	var ex := {}
	if level < 3:
		var key := majors[rng.randi_range(0, 2)] if level == 1 else minors[rng.randi_range(0, 2)]
		var letters := _letters(CHORDS[key][0])
		var right := "%s, %s and %s" % letters
		var wrongs: Array = []
		var root := str(letters[0])
		var at := "CDEFGAB".find(root)
		for cand: Array in [[root, _letter(at + 1), _letter(at + 2)], [root, _letter(at + 3), _letter(at + 5)],
				[root, _letter(at + 2), _letter(at + 5)], [_letter(at + 2), _letter(at + 4), _letter(at + 6)]]:
			var t := "%s, %s and %s" % cand
			if t != right and not wrongs.has(t):
				wrongs.append(t)
		ex = K.choice(rng, "Which notes make the %s chord?" % _chord_name(key), right, wrongs.slice(0, 3),
			"Start on the chord's own note, then skip a letter, then skip another (like C, skip D, E).",
			"From %s, skip a letter to %s, skip another to %s: the %s chord is %s, %s and %s." % [root, letters[1], letters[2],
				_chord_name(key), letters[0], letters[1], letters[2]])
		ex.data = {"key": key}
		return ex
	var keys: Array = CHORDS.keys()
	var key := str(keys[rng.randi_range(0, keys.size() - 1)])
	var wrongs: Array = []
	for k: String in keys:
		if k != key:
			wrongs.append(_chord_name(k))
	K.shuffle(rng, wrongs)
	var letters := _letters(CHORDS[key][0])
	ex = K.choice(rng, "Which chord is on the stave?", _chord_name(key), wrongs.slice(0, 3),
		"Read the lowest note: it names the chord. Then count the semitones up to the middle note: 4 is major, 3 is minor.",
		"The notes are %s, %s and %s. %s is the lowest, and it is %s: the %s chord." % [letters[0], letters[1], letters[2],
			letters[0], CHORDS[key][1], _chord_name(key)], {"kind": "chord_stave", "chords": [CHORDS[key][0]]})
	ex.data = {"key": key}
	return ex


static func _letters(notes: Array) -> Array:
	var out: Array = []
	for n: String in notes:
		out.append(n.left(1))
	return out


static func _letter(i: int) -> String:
	return "CDEFGAB"[posmod(i, 7)]


const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const MAJOR_STEPS: Array[int] = [2, 2, 1, 2, 2, 2, 1]


## Tones and semitones. Level 1: in C major, is a step a tone or a semitone; level 2: how many semitones between two
## white keys; level 3: the note a major scale needs a sharp or a flat for.
static func scale_steps(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var scale: Array[String] = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"]
	var ex := {}
	match level:
		1:
			var i := rng.randi_range(0, 6)
			var semis := MAJOR_STEPS[i]
			ex = K.choice(rng, "In the C major scale, is the step from %s up to %s a tone or a semitone?" % [scale[i].left(1),
				scale[i + 1].left(1)], "a tone" if semis == 2 else "a semitone", ["a semitone" if semis == 2 else "a tone"],
				"On the keyboard, is there a black key between the two white keys?",
				"%s to %s is %s: %s." % [scale[i].left(1), scale[i + 1].left(1), "a tone" if semis == 2 else "a semitone",
					"a black key sits between them (2 semitones)" if semis == 2 else "no black key between them (1 semitone)"],
				{"kind": "keyboard", "mark": [scale[i], scale[i + 1]], "names": true})
			ex.data = {"from": scale[i], "to": scale[i + 1]}
		2:
			var a := rng.randi_range(0, 5)
			var b := rng.randi_range(a + 1, 7)
			var semis := _semis(scale[b]) - _semis(scale[a])
			ex = K.number("How many semitones is it from %s up to %s? Count every key, black and white." % [scale[a].left(1),
				scale[b].left(1) + (" (the high C)" if b == 7 else "")], semis,
				"A semitone is the very next key, black or white. Count the steps from key to key.",
				"From %s, count every key up to %s: %d semitones." % [scale[a].left(1), scale[b].left(1), semis],
				{"kind": "keyboard", "mark": [scale[a], scale[b]], "names": true})
			ex.data = {"from": scale[a], "to": scale[b]}
		_:
			var cases: Array = [["G4", 7, "F#", ["F", "E", "G#"]], ["F4", 4, "Bb", ["B", "A", "C"]], ["D4", 3, "F#", ["F", "E", "G"]],
				["D4", 7, "C#", ["C", "B", "D"]]]
			var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
			var home := str(c[0])
			var nth := int(c[1])
			ex = K.choice(rng, "A major scale always goes up tone, tone, semitone, tone, tone, tone, semitone. What is note %d of the %s major scale?" % [
				nth, home.left(1)], str(c[2]), c[3],
				"Start on %s and step up the pattern on the keyboard: a tone is two keys along, a semitone one." % home.left(1),
				"Up the pattern from %s: %s. Note %d is %s." % [home.left(1), ", ".join(_major_scale(home)), nth, c[2]],
				{"kind": "keyboard", "mark": [home], "names": true, "keys": 10})
			ex.data = {"home": home, "nth": nth}
	return ex


static func _semis(note: String) -> int:
	return int(SEMIS[note.left(1)]) + 12 * int(note.right(1))


## The eight notes of a major scale from `home` (a white key), sharps and flats named as a scale spells them (each
## letter once).
static func _major_scale(home: String) -> Array[String]:
	var out: Array[String] = []
	var at := _semis(home)
	var letter := "CDEFGAB".find(home.left(1))
	for i in 8:
		var l := _letter(letter + i)
		var want := posmod(at, 12)
		var diff := posmod(want - int(SEMIS[l]) + 6, 12) - 6
		out.append(l + ("#" if diff == 1 else ("b" if diff == -1 else "")))
		if i < 7:
			at += MAJOR_STEPS[i]
	return out


const FORM_NAMES := {"A B": "binary form", "A B A": "ternary form", "A B A C A": "rondo form"}


## A song's form. Level 1: how many times a part is played; level 2: the name of a form; level 3: hear three phrases
## and say their form.
static func form_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var forms: Array = [["A", "B", "A", "C", "A"], ["A", "B", "A", "C", "A", "B", "A"],
				["verse", "chorus", "verse", "chorus", "bridge", "chorus"], ["intro", "verse", "chorus", "verse", "chorus"],
				["A", "A", "B", "A"]]
			var f: Array = forms[rng.randi_range(0, forms.size() - 1)]
			var part := "chorus" if f.has("chorus") else "A"
			var n := f.count(part)
			ex = K.number("How many times is the %s played in this song?" % part, n,
				"Touch each block of the %s as you count." % part,
				"%s: the %s comes %d times." % [" ".join(f), part, n], {"kind": "song_form", "sections": f})
			ex.data = {"sections": f, "part": part}
		2:
			var keys: Array = FORM_NAMES.keys()
			var f := str(keys[rng.randi_range(0, keys.size() - 1)])
			var wrongs: Array = []
			for k: String in keys:
				if k != f:
					wrongs.append(FORM_NAMES[k])
			wrongs.append("verse and chorus")
			ex = K.choice(rng, "What is the form %s called?" % f, str(FORM_NAMES[f]), wrongs,
				"Binary has two parts, ternary three (the first comes back), and in a rondo the A keeps coming back between new parts.",
				"%s is %s." % [f, FORM_NAMES[f]], {"kind": "song_form", "sections": Array(f.split(" "))})
			ex.data = {"form": f}
		_:
			var phrases: Array = [["C4", "E4", "G4", "E4"], ["F4", "A4", "F4", "D4"], ["G4", "G4", "C5", "C5"],
				["E4", "D4", "C4", "D4"]]
			K.shuffle(rng, phrases)
			var forms: Array[String] = ["A B A", "A A B", "A B B", "A B C"]
			var f := forms[rng.randi_range(0, forms.size() - 1)]
			var notes: Array = []
			for letter in f.split(" "):
				notes.append_array(phrases["ABC".find(letter)])
			ex = K.choice(rng, "Listen to the three phrases (four notes each). Which form did you hear?", f,
				forms.filter(func(x: String) -> bool: return x != f),
				"Give the first phrase the letter A. Is the next phrase the same (A again) or new (B)?",
				"The phrases go %s: the same phrase has the same letter." % f)
			ex.sound = {"kind": "notes", "notes": notes, "beat": 0.4}
			ex.data = {"form": f, "notes": notes}
	return ex


## Words and their syllables, as they are sung (one note each).
const SYLLABLES := {"cat": "cat", "moon": "moon", "garden": "gar-den", "rainbow": "rain-bow", "tiger": "ti-ger",
	"sunshine": "sun-shine", "river": "ri-ver", "happy": "hap-py", "mountain": "moun-tain", "castle": "cas-tle",
	"butterfly": "but-ter-fly", "elephant": "el-e-phant", "banana": "ba-na-na", "dinosaur": "di-no-saur",
	"umbrella": "um-brel-la", "adventure": "ad-ven-ture", "wonderful": "won-der-ful", "computer": "com-pu-ter",
	"caterpillar": "cat-er-pil-lar", "helicopter": "hel-i-cop-ter", "watermelon": "wa-ter-mel-on"}
const RHYMES: Array = [["night", "light", "bright", "kite"], ["day", "play", "stay", "grey"], ["tree", "sea", "free", "bee"],
	["star", "far", "car", "guitar"], ["cat", "hat", "bat", "flat"], ["sing", "ring", "king", "spring"],
	["snow", "go", "slow", "glow"], ["fun", "sun", "run", "done"]]
const LINES: Array = [["the", "buddies", "dance"], ["a", "rainbow", "in", "the", "sky"], ["we", "sail", "across", "the", "sea"],
	["the", "happy", "tiger", "sings"], ["my", "garden", "is", "green"], ["the", "butterfly", "flies", "high"]]
const SHORT_WORDS := {"the": 1, "a": 1, "in": 1, "sky": 1, "we": 1, "sail": 1, "across": 2, "sea": 1, "sings": 1,
	"my": 1, "is": 1, "green": 1, "flies": 1, "high": 1, "dance": 1, "buddies": 2}


static func _syl(word: String) -> int:
	if SYLLABLES.has(word):
		return str(SYLLABLES[word]).split("-").size()
	return int(SHORT_WORDS[word])


## Fitting words to a melody: one note for each syllable. Level 1: a word's syllables; level 2: a line's; level 3: a
## rhyme for a chorus.
static func syllable_beats(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var words: Array = SYLLABLES.keys()
			var w := str(words[rng.randi_range(0, words.size() - 1)])
			ex = K.number("How many syllables (beats) does the word “%s” have?" % w, _syl(w),
				"Clap the word as you say it slowly: one clap for each beat.",
				"%s: %d syllables, so it needs %d notes." % [SYLLABLES[w], _syl(w), _syl(w)])
			ex.data = {"words": [w]}
		2:
			var line: Array = LINES[rng.randi_range(0, LINES.size() - 1)]
			var total := 0
			var parts: Array[String] = []
			var counts: Array[String] = []
			for w: String in line:
				total += _syl(w)
				parts.append(str(SYLLABLES.get(w, w)))
				counts.append(str(_syl(w)))
			ex = K.number("A song line goes: “%s”. One note for each syllable: how many notes does the line need?" % " ".join(line),
				total, "Clap the line slowly. Long words have more than one clap.",
				"%s: %s = %d notes." % [" ".join(parts), " + ".join(counts), total])
			ex.data = {"words": line}
		_:
			var g: int = rng.randi_range(0, RHYMES.size() - 1)
			var group: Array = (RHYMES[g] as Array).duplicate()
			K.shuffle(rng, group)
			var word := str(group[0])
			var right := str(group[1])
			var wrongs: Array = []
			var others: Array = range(RHYMES.size())
			K.shuffle(rng, others)
			for o: int in others:
				if o != g and wrongs.size() < 3:
					wrongs.append(str(RHYMES[o][rng.randi_range(0, 3)]))
			ex = K.choice(rng, "Which word rhymes with “%s”, to end the next line of a chorus?" % word, right, wrongs,
				"Say the word, then each choice after it. Rhyming words end with the same sound.",
				"“%s” and “%s” end with the same sound, so they rhyme." % [word, right])
			ex.data = {"word": word, "group": g}
	return ex


## The composers' years (every one of them had had his birthday in the year he died, so his age is died − born).
const COMPOSERS := {"Vivaldi": [1678, 1741], "Bach": [1685, 1750], "Handel": [1685, 1759], "Haydn": [1732, 1809],
	"Mozart": [1756, 1791]}


## Level 1: how many years a composer lived; level 2: how many years after one another two were born; level 3: who was
## alive in a year (on a timeline).
static func composer_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = COMPOSERS.keys()
	K.shuffle(rng, names)
	var ex := {}
	match level:
		1:
			var who := str(names[0])
			var y: Array = COMPOSERS[who]
			ex = K.number("%s was born in %d and died in %d. How many years did he live?" % [who, y[0], y[1]], int(y[1]) - int(y[0]),
				"Take the year he was born from the year he died.",
				"%d − %d = %d years." % [y[1], y[0], int(y[1]) - int(y[0])])
			ex.data = {"who": [who]}
		2:
			var a := str(names[0])
			var b := str(names[1])
			if int(COMPOSERS[a][0]) == int(COMPOSERS[b][0]):
				b = str(names[2])
			if int(COMPOSERS[a][0]) > int(COMPOSERS[b][0]):
				var t := a
				a = b
				b = t
			var gap := int(COMPOSERS[b][0]) - int(COMPOSERS[a][0])
			ex = K.number("%s was born in %d and %s in %d. How many years after %s was %s born?" % [a, COMPOSERS[a][0], b,
				COMPOSERS[b][0], a, b], gap, "Take the earlier year from the later one.",
				"%d − %d = %d years." % [COMPOSERS[b][0], COMPOSERS[a][0], gap])
			ex.data = {"who": [a, b]}
		_:
			for _try in 200:
				var shown: Array = names.slice(0, 3)
				var year := rng.randi_range(1690, 1800)
				var alive: Array = shown.filter(func(n: String) -> bool:
					return int(COMPOSERS[n][0]) < year and year < int(COMPOSERS[n][1]))
				if alive.size() != 1:
					K.shuffle(rng, names)
					continue
				var people: Array = []
				for n: String in shown:
					people.append([n, COMPOSERS[n][0], COMPOSERS[n][1]])
				var right := str(alive[0])
				ex = K.choice(rng, "Which of these composers was alive in %d?" % year, right,
					shown.filter(func(n: String) -> bool: return n != right),
					"Find %d on the timeline and look straight up: whose life bar does the line cross?" % year,
					"%s lived from %d to %d, so he was alive in %d; the others were not born yet or had died." % [right,
						COMPOSERS[right][0], COMPOSERS[right][1], year],
					{"kind": "lifespans", "people": people, "from": 1650, "to": 1850, "year": year})
				ex.data = {"who": shown, "year": year}
				break
			if ex.is_empty():   # Haydn (1732-1809) alone was alive in 1800
				ex = K.choice(rng, "Which of these composers was alive in 1800?", "Haydn", ["Vivaldi", "Mozart"],
					"Find 1800 on the timeline and look straight up: whose life bar does the line cross?",
					"Haydn lived from 1732 to 1809, so he was alive in 1800; the others had died.",
					{"kind": "lifespans", "people": [["Vivaldi", 1678, 1741], ["Haydn", 1732, 1809], ["Mozart", 1756, 1791]],
						"from": 1650, "to": 1850, "year": 1800})
				ex.data = {"who": ["Vivaldi", "Haydn", "Mozart"], "year": 1800}
	return ex


## Patterns of eight boxes (half a beat each), each starting with a hit.
const PATTERNS: Array[String] = ["x--x--x-", "x-x-xx-x", "x-xx-x-x", "xx-x-x--", "x--x-x--", "x-x--x-x", "x-xx-xx-",
	"x--xx-x-"]
const WORLD_INSTRUMENTS: Array[String] = ["djembe", "bell", "shaker", "surdo", "agogo", "gong", "drum"]


## Rhythms of the world. Level 1: copy a pattern (the rhythm type); level 2: how many hits in a row of a beat grid;
## level 3: two layers: on how many steps do both play together?
static func world_pattern(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	var insts: Array = WORLD_INSTRUMENTS.duplicate()
	K.shuffle(rng, insts)
	match level:
		1:
			var p := PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
			var boxes: Array[String] = []
			for i in p.length():
				if p[i] == "x":
					boxes.append(str(i + 1))
			ex = {"type": "rhythm", "prompt": "Listen to this %s pattern, then mark the boxes where it plays. Each box is half a beat." % insts[0],
				"hint": "Listen again and count along: 1 & 2 & 3 & 4 &. Which counts have a hit?",
				"explain": "It plays in boxes %s and %s." % [", ".join(boxes.slice(0, boxes.size() - 1)), boxes[-1]],
				"sound": {"kind": "rhythm", "pattern": p, "tempo": 80}}
			ex.data = {"pattern": p}
		2:
			var p := PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
			if rng.randi() % 2 == 0:
				p += PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
			ex = K.number("How many times does the %s play in this loop?" % insts[0], p.count("x"),
				"Count the coloured boxes in its row. Counting in fours helps.",
				"Its row has %d coloured boxes: it plays %d times." % [p.count("x"), p.count("x")],
				{"kind": "beat_grid", "rows": [[str(insts[0]), p]]})
			ex.data = {"rows": [p]}
		_:
			var a := PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
			var b := PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
			while b == a:
				b = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
			var both: Array[String] = []
			for i in a.length():
				if a[i] == "x" and b[i] == "x":
					both.append(str(i + 1))
			ex = K.number("Two layers play together. On how many steps do the %s and the %s both play?" % [insts[0], insts[1]],
				both.size(), "Go along the steps one by one: is there a coloured box in both rows?",
				"Both play on step%s %s: %d step%s." % ["" if both.size() == 1 else "s", ", ".join(both) if not both.is_empty()
					else "none", both.size(), "" if both.size() == 1 else "s"],
				{"kind": "beat_grid", "rows": [[str(insts[0]), a], [str(insts[1]), b]], "count": true})
			ex.data = {"rows": [a, b]}
	return ex


const STAVE: Array[String] = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5"]
const HALVES := {"semibreve": 8, "dotted minim": 6, "minim": 4, "crotchet": 2, "quaver": 1}


## A melody's rhythm on the stave. Level 1: crotchets, minims and semibreves: how many beats; level 2: quavers (in
## pairs) and dotted minims too; level 3: how many bars of 3/4 they fill.
static func melody_beats(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var values: Array[String] = []
	var halves := 0
	var want_bars := rng.randi_range(2, 3)
	for _try in 200:
		values.clear()
		halves = 0
		var n := rng.randi_range(3, 5) if level == 1 else rng.randi_range(4, 7)
		while values.size() < n:
			var v := ""
			match level:
				1:
					v = ["crotchet", "minim", "semibreve", "crotchet"][rng.randi_range(0, 3)]
				_:
					v = ["crotchet", "minim", "dotted minim", "quaver", "crotchet"][rng.randi_range(0, 4)]
			if v == "quaver":
				if values.size() + 2 > 8:
					continue
				values.append_array(["quaver", "quaver"])
				halves += 2
			else:
				values.append(v)
				halves += int(HALVES[v])
		if level < 3 or halves == want_bars * 6:
			break
	if level == 3 and halves != want_bars * 6:   # a sure one: dotted minims only
		values.clear()
		for i in want_bars:
			values.append("dotted minim")
		halves = want_bars * 6
	var notes: Array[String] = []
	for i in values.size():
		notes.append(STAVE[rng.randi_range(0, STAVE.size() - 1)])
	var beats := halves / 2
	var listing: Array[String] = []
	for v in values:
		listing.append("½" if v == "quaver" else str(int(HALVES[v]) / 2))
	var ex := {}
	if level < 3:
		ex = K.number("How many beats do these notes last?", beats,
			"Semibreve 4, dotted minim 3, minim 2, crotchet 1, quaver ½. Add them up note by note.",
			"%s = %d beats." % [" + ".join(listing), beats], {"kind": "stave", "notes": notes, "values": values})
	else:
		ex = K.number("The time signature is 3/4. How many full bars do these notes fill?", beats / 3,
			"3/4 means 3 beats in each bar. Add up the beats, then see how many 3s they make.",
			"%s = %d beats, and %d ÷ 3 = %d bars." % [" + ".join(listing), beats, beats, beats / 3],
			{"kind": "stave", "notes": notes, "values": values, "time": "3/4"})
	ex.data = {"values": values}
	return ex


## Playing together: the conductor's beat patterns. Level 1: which way the hand goes on a beat; level 2: how many beats
## the conductor beats for some bars; level 3: which beat goes a way.
const DIRECTIONS := {2: ["down", "up"], 3: ["down", "right", "up"], 4: ["down", "left", "right", "up"]}


static func conduct(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var beats: int = [2, 3, 4][rng.randi_range(0, 2)]
	var ways: Array = DIRECTIONS[beats]
	var ex := {}
	match level:
		1:
			var b := rng.randi_range(2, beats)
			var right := str(ways[b - 1])
			ex = K.choice(rng, "In %d/4, the conductor's hand goes down on beat 1. Which way does it go on beat %d?" % [beats, b],
				right, ["down", "left", "right", "up"].filter(func(w: String) -> bool: return w != right),
				"Beat 1 is always down and the last beat always up, ready for the next bar. Think about the pattern's shape.",
				"In %d/4 the hand goes %s: beat %d goes %s." % [beats, ", ".join(ways), b, right],
				{"kind": "beat_pattern", "beats": beats})
			ex.data = {"beats": beats, "beat": b}
		2:
			var bars := rng.randi_range(4, 16)
			ex = K.number("A conductor beats this pattern for %d bars. How many beats is that?" % bars, bars * beats,
				"Count the beats in one pattern: that is one bar. Then multiply by the bars.",
				"The pattern has %d beats: %d × %d = %d beats." % [beats, bars, beats, bars * beats],
				{"kind": "beat_pattern", "beats": beats})
			ex.data = {"beats": beats, "bars": bars}
		_:
			var b := rng.randi_range(1, beats)
			var way := str(ways[b - 1])
			ex = K.number("In %d/4, on which beat does the conductor's hand go %s?" % [beats, way], b,
				"Beat 1 is always down and the last beat always up. Picture the pattern with your own hand.",
				"In %d/4 the hand goes %s, so it goes %s on beat %d." % [beats, ", ".join(ways), way, b])
			ex.data = {"beats": beats, "beat": b}
	return ex


## Music technology: loops, bars and time. Level 1: a loop played again and again; level 2: how long some bars last at
## a tempo; level 3: read a music maker's tracks.
static func loop_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var bars := rng.randi_range(1, 4)
			var times := rng.randi_range(2, 8)
			ex = K.number("A drum loop is %d bar%s long. It plays %d times. How many bars of music is that?" % [bars,
				"" if bars == 1 else "s", times], bars * times, "Each time the loop plays, it adds its bars again.",
				"%d × %d = %d bars." % [times, bars, bars * times])
			ex.data = {"bars": bars, "times": times}
		2:
			var tempo: int = [60, 80, 120][rng.randi_range(0, 2)]
			var bars := rng.randi_range(2, 8)
			var seconds := bars * 4 * 60 / tempo
			ex = K.number("A song in 4/4 has %d beats a minute. How many seconds do %d bars last?" % [tempo, bars], seconds,
				"Work out the beats first (4 in a bar). Then how many seconds is one beat at this speed?",
				"%d bars × 4 = %d beats. At %d beats a minute, a beat lasts %s, so %d beats last %d seconds." % [bars, bars * 4,
					tempo, {60: "1 second", 80: "¾ of a second", 120: "½ a second"}[tempo], bars * 4, seconds])
			ex.data = {"tempo": tempo, "bars": bars}
		_:
			var names: Array[String] = ["drums", "bass", "tune"]
			var tracks: Array = []
			for n in names:
				var clips: Array = []
				var at := 0
				while at < 8:
					var length := rng.randi_range(1, 3)
					if at + length > 8:
						length = 8 - at
					if rng.randi() % 3 != 0:
						clips.append([at, length])
					at += length
				if clips.is_empty():
					clips.append([0, 2])
				tracks.append([n, clips])
			var all_play: Array[String] = []
			for bar in 8:
				var every := true
				for t: Array in tracks:
					var here := false
					for c: Array in t[1]:
						here = here or (bar >= int(c[0]) and bar < int(c[0]) + int(c[1]))
					every = every and here
				if every:
					all_play.append(str(bar + 1))
			ex = K.number("In how many bars are all three tracks playing at once?", all_play.size(),
				"Go bar by bar: is there a clip in every track's row in that bar?",
				("All three play in bar%s %s: %d bar%s." % ["" if all_play.size() == 1 else "s", ", ".join(all_play),
					all_play.size(), "" if all_play.size() == 1 else "s"]) if not all_play.is_empty()
					else "No bar has a clip in all three rows: 0.", {"kind": "tracks", "tracks": tracks, "bars": 8})
			ex.data = {"tracks": tracks}
	return ex
