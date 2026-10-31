extends GutTest
## Owner #70 and #73: grade 7 computing, art and music generators (SchoolGen "g7c.<name>", core/school/gen/g7_arts_gen.gd).
## Every answer is worked out again here from the exercise's data, picture, sound or prompt with this test's own rules:
## programs are run by the tests' own text-code interpreter (tests/fakes/text_code_runner.gd); searches, bubble and merge
## sort, test data, IP addresses, routes, the Caesar cipher, data cleaning, validation, feeds, copyright years, licences,
## the colour wheel, heads, scales, thirds, prints, the years of art, chords and cadences, ornaments, periods, the bass
## clef, beats, riffs, film themes, mixes, tempo and folk metres.

const Runner := preload("res://tests/fakes/text_code_runner.gd")
const GENS: Array[String] = ["text_output", "syntax_error", "list_item", "list_loop", "function_value", "linear_checks",
	"binary_checks", "bubble_step", "merge_step", "test_data", "ip_address", "route_hops", "caesar_word", "clean_data",
	"validate_entry", "habit_check", "public_domain", "licence_use", "scheme_pick", "head_heights", "scale_drawing",
	"thirds_place", "block_print", "art_dates", "primary_chord", "cadence_ear", "ornament_play", "era_facts", "bass_note",
	"dotted_beats", "riff_repeat", "film_cue", "mix_balance", "song_length", "folk_metre"]
const SEEDS := 50
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const LETTERS := "CDEFGAB"
const MAJOR: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const WHEEL: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red", "red-purple", "purple",
	"blue-purple", "blue", "blue-green", "green", "yellow-green"]
const ROUTER_LINKS: Array[String] = ["AB", "BC", "AD", "CF", "DE", "EF", "BE"]
## Which check catches which kind of mistake (this test's own words).
const CHECK_WORDS := {"empty": "presence check", "blank": "presence check", "no age": "presence check",
	"ten in the age": "type check", "as lots": "type check", "word free": "type check",
	"150": "range check", "130": "range check", "month": "range check",
	"only 4 letters": "length check", "30 digits": "length check", "60 letters": "length check",
	"no @": "format check", "DD/MM/YYYY": "format check", "postcode": "format check"}
const TRICK_WORDS := {"by itself": "autoplay", "never reaches an end": "endless scroll", "red number": "notifications",
	"Hearts": "likes"}
const LICENCE_RULES := {"CC0": [true, true, true, false], "CC BY": [false, true, true, false], "CC BY-SA": [false, true, true, true],
	"CC BY-NC": [false, false, true, false], "CC BY-ND": [false, true, false, false], "all rights reserved": [false, false, false, false]}
## [no credit needed, may sell, may change, same licence for new versions]
const EVENTS := {"Jan van Eyck paints the Arnolfini Portrait": 1434, "Leonardo starts the Mona Lisa": 1503,
	"Michelangelo finishes the statue of David": 1504, "Raphael finishes The School of Athens": 1511,
	"Michelangelo finishes the Sistine Chapel ceiling": 1512, "Dürer makes his Rhinoceros woodcut": 1515,
	"Akbar becomes the Mughal emperor": 1556, "The Blue Mosque is finished, with Iznik tiles": 1616,
	"Work begins on the Taj Mahal": 1632}
const PERIODS := {"Bach": ["Baroque", 1685], "Handel": ["Baroque", 1685], "Vivaldi": ["Baroque", 1678],
	"Purcell": ["Baroque", 1659], "Pachelbel": ["Baroque", 1653], "Haydn": ["Classical", 1732], "Mozart": ["Classical", 1756]}
const BEATS := {"semibreve": 4.0, "dotted minim": 3.0, "minim": 2.0, "dotted crotchet": 1.5, "crotchet": 1.0,
	"dotted quaver": 0.75, "quaver": 0.5, "semiquaver": 0.25}


func _all(gen: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make("g7c." + gen, s, level)
			ex["_level"] = level
			out.append(ex)
	return out


func _right(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func _value(ex: Dictionary) -> float:
	return NumberAnswer.value(str(ex.answer))


func _ints(t: String) -> Array[int]:
	var out: Array[int] = []
	for m in RegEx.create_from_string("-?\\d[\\d,]*").search_all(t):
		out.append(int(m.get_string().replace(",", "")))
	return out


func test_every_generator_exists_and_is_valid() -> void:
	for g in GENS:
		assert_true(SchoolGen.exists("g7c." + g), g)
		for ex in _all(g):
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [g, ex.get("prompt", "")])
			assert_true(ex.has("data"), "%s has its data" % g)
			assert_true(ex.has("explain"), "%s has a worked answer" % g)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy" % g)
			for p: Variant in [ex.get("picture")]:
				if p is Dictionary:
					assert_eq(SchoolPicture.problem(p), "", "%s: its picture %s" % [g, p])
			if ex.has("sound"):
				assert_eq(SchoolSound.problem(ex.sound), "", "%s: its sound" % g)
	var names: Array[String] = []
	for id in SchoolGen.ids():
		if id.begins_with("g7c."):
			names.append(id.substr(4))
	names.sort()
	var want := GENS.duplicate()
	want.sort()
	assert_eq(names, want, "every g7c generator is tested here")


# --- programs ----------------------------------------------------------------------------------------------------------

func test_the_runner_runs_text_code() -> void:
	var st := Runner.run(["total = 0", "for i in range(1, 5):", "    if i % 2 == 0:", "        total = total + i", "print(total)",
		"gems = [4, 7]", "gems.append(9)", "print(len(gems), gems[-1], 7 / 2, 7 // 2)"])
	assert_eq(st.error, "")
	assert_eq(st.out, ["6", "3 9 3.5 3"])
	assert_eq(Runner.run(["def area(w, h):", "    return w * h", "print(area(3, 4))"]).out, ["12"])
	assert_eq(Runner.run(["if x > 5", "    print(1)"]).line, 1, "a missing colon")
	assert_eq(Runner.run(["for i in range(3):", "print(i)"]).line, 2, "the line that should step in")
	assert_eq(Runner.run(["print(\"hi)"]).error, "syntax", "a missing quote mark")
	assert_eq(Runner.run(["x = 3", "if x = 3:", "    print(x)"]).line, 2, "= for ==")
	assert_eq(Runner.run(["pritn(\"hi\")"]).error, "name", "a misspelt command")
	assert_eq(Runner.run(["gems = [1, 2]", "print(gems[2])"]).error, "index")
	assert_eq(Runner.run(["print(5 / 0)"]).error, "zero")
	assert_eq(Runner.run(["print(\"5\" + 5)"]).error, "type")
	assert_eq(Runner.run(["print(\"5\" + \"5\")", "print(5 + 5)"]).out, ["55", "10"], "text joins, numbers add")
	assert_eq(Runner.run(["print(max([3, 9, 2]), min(4, 1), str(12) + \"!\")"]).out, ["9 1 12!"])
	assert_eq(Runner.run(["n = 1", "while n < 20:", "    n = n * 2", "print(n)"]).out, ["32"])


func test_the_programs_print_what_the_answers_say() -> void:
	var n := 0
	for g: String in ["text_output", "list_item", "list_loop", "function_value"]:
		for ex in _all(g):
			var p: Dictionary = ex.picture
			if str(p.kind) == "text_code":
				var st := Runner.run(p.lines)
				assert_eq(st.error, "", "%s runs: %s" % [g, p.lines])
				assert_eq((st.out as Array).size(), 1, "%s prints one line" % g)
				assert_eq(float(st.out[0]), _value(ex), "%s: %s" % [g, p.lines])
				n += 1
			elif str(p.kind) == "func_machine":
				var st := Runner.run(["def f(n):", "    return " + str(p.body), "print(f(%s))" % p.args[0]])
				assert_eq(float(st.out[0]), _value(ex), "%s: %s" % [g, p])
				n += 1
			else:
				var i := int(RegEx.create_from_string("\\[(-?\\d+)\\]").search(str(ex.prompt)).get_string(1))
				assert_eq(str(p.items[i]), str(ex.answer), "%s: %s" % [g, ex.prompt])
				n += 1
	assert_gt(n, 500)


## The mistake: the program stops with a syntax error on the marked line (or the line the answer names), and the named
## mistake is the one on that line (this test's own look at the line).
func test_the_mistakes_are_found() -> void:
	for ex in _all("syntax_error"):
		var lines: Array = ex.picture.lines
		var st := Runner.run(lines)
		assert_eq(st.error, "syntax", str(lines))
		var at := int(ex.picture.error) if ex.picture.has("error") else int(_value(ex)) - 1
		assert_eq(int(st.line), at + 1, "%s stops on line %d" % [lines, at + 1])
		if str(ex.type) != "choice":
			continue
		var line := str(lines[at])
		var kind := ""
		if line.count("\"") % 2 == 1:
			kind = "a missing quote mark"
		elif line.count("(") != line.count(")"):
			kind = "a missing bracket"
		elif line.strip_edges().begins_with("if") and line.contains(" = "):
			kind = "= where == should be"
		elif (line.begins_with("if") or line.begins_with("for")) and not line.ends_with(":"):
			kind = "a missing colon"
		elif line == line.strip_edges() and at > 0 and str(lines[at - 1]).ends_with(":"):
			kind = "a line that should step in"
		assert_eq(_right(ex), kind, str(lines))


# --- searching and sorting -----------------------------------------------------------------------------------------------

func _linear(items: Array, target: int) -> int:
	for i in items.size():
		if int(items[i]) == target:
			return i + 1
	return items.size()


func _binary(items: Array, target: int) -> Array[int]:
	var lo := 0
	var hi := items.size() - 1
	var out: Array[int] = []
	while lo <= hi:
		var mid := floori((lo + hi) / 2.0)
		out.append(mid)
		if int(items[mid]) == target:
			break
		if int(items[mid]) < target:
			lo = mid + 1
		else:
			hi = mid - 1
	return out


func test_the_searches_are_counted() -> void:
	for ex in _all("linear_checks"):
		assert_eq(_value(ex), float(_linear(ex.picture.items, int(ex.picture.target))), str(ex.prompt))
		if ex._level == 3:
			assert_false((ex.picture.items as Array).has(ex.picture.target), "level 3's target is not there")
	for ex in _all("binary_checks"):
		if ex._level == 3:
			var n := int(ex.data.n)
			var k := 0
			while (1 << k) <= n:
				k += 1
			assert_eq(_value(ex), float(k), "%d items need at most %d checks" % [n, k])
			var most := 0
			var items: Array = range(n)
			for t in [-1, 0, n / 3, n - 1, n]:
				most = maxi(most, _binary(items, t).size())
			assert_lte(most, k, "no search of %d items needs more" % n)
			continue
		var checks := _binary(ex.picture.items, int(ex.picture.target))
		if ex._level == 1:
			assert_eq(_right(ex), str(ex.picture.items[checks[0]]), str(ex.prompt))
		else:
			assert_eq(_value(ex), float(checks.size()), str(ex.prompt))


func _bubble_once(items: Array) -> Dictionary:
	var a := items.duplicate()
	var swaps := 0
	for i in a.size() - 1:
		if int(a[i]) > int(a[i + 1]):
			var t: Variant = a[i]
			a[i] = a[i + 1]
			a[i + 1] = t
			swaps += 1
	return {"a": a, "swaps": swaps}


func test_bubble_and_merge_sort() -> void:
	for ex in _all("bubble_step"):
		var p := _bubble_once(ex.picture.items)
		match int(ex._level):
			1:
				assert_eq(_value(ex), float((p.a as Array)[-1]))
			2:
				assert_eq(_right(ex), ", ".join(PackedStringArray((p.a as Array).map(func(x: Variant) -> String: return str(x)))))
			3:
				assert_eq(_value(ex), float(p.swaps))
	for ex in _all("merge_step"):
		if ex._level == 2:
			assert_eq(pow(2.0, _value(ex)), float(ex.data.n), str(ex.prompt))
			continue
		var all: Array = (ex.data.a as Array) + (ex.data.b as Array)
		all.sort()
		if ex._level == 1:
			assert_eq(_value(ex), float(all[0]))
		else:
			assert_eq(_right(ex), ", ".join(PackedStringArray(all.map(func(x: Variant) -> String: return str(x)))))


func test_the_test_data_is_named_right() -> void:
	for ex in _all("test_data"):
		var a := int(ex.data.a)
		var b := int(ex.data.b)
		if ex._level == 3:
			var code := str(ex.prompt).get_slice("code says: ", 1)
			var rejects_a := code.contains("x > %d" % a)
			assert_eq(_right(ex), str(a if rejects_a else b), code)
			continue
		var v := str(ex.data.value)
		var want := "erroneous"
		if v.is_valid_int() and int(v) >= a and int(v) <= b:
			want = "boundary" if int(v) == a or int(v) == b else "normal"
		assert_eq(_right(ex), want, "%s in %d-%d" % [v, a, b])


# --- networks and codes --------------------------------------------------------------------------------------------------

func _ip_ok(ip: String) -> bool:
	var parts := ip.split(".")
	if parts.size() != 4:
		return false
	for p in parts:
		if not p.is_valid_int() or int(p) < 0 or int(p) > 255:
			return false
	return true


func test_ip_addresses_and_packets() -> void:
	for ex in _all("ip_address"):
		match int(ex._level):
			1:
				assert_eq(bool(ex.answer), _ip_ok(str(ex.data.ip)), str(ex.data.ip))
			2:
				assert_eq(_value(ex), ceilf(float(ex.data.n) / float(ex.data.size)), str(ex.prompt))
			3:
				for i in (ex.choices as Array).size():
					assert_eq(_ip_ok(ExerciseCheck.item_text(ex.choices[i])), i == int(ex.answer), str(ex.choices))


func _route_ok(r: String) -> bool:
	if not "AD".contains(r[0]) or not "CF".contains(r[r.length() - 1]):
		return false
	for i in range(1, r.length()):
		if not (ROUTER_LINKS.has(r[i - 1] + r[i]) or ROUTER_LINKS.has(r[i] + r[i - 1])):
			return false
	return true


func test_the_routes_are_counted() -> void:
	for ex in _all("route_hops"):
		var routes: Array = ex.picture.routes
		for r: String in routes:
			assert_true(_route_ok(r), r)
		match int(ex._level):
			1:
				assert_eq(_value(ex), float(str(routes[0]).length()))
			2:
				var best := 0
				for i in routes.size():
					if str(routes[i]).length() < str(routes[best]).length():
						best = i
				assert_eq(_right(ex), "packet %d" % (best + 1))
			3:
				var broken := str(ex.data.broken)
				var i := int(_right(ex).get_slice(" ", 1)) - 1
				assert_false(str(routes[i]).contains(broken))
				for j in routes.size():
					if j != i:
						assert_true(str(routes[j]).contains(broken), "only one route avoids %s" % broken)


func _caesar(t: String, k: int) -> String:
	var out := ""
	for ch in t:
		out += String.chr(65 + posmod(ch.unicode_at(0) - 65 + k, 26))
	return out


func test_the_caesar_cipher() -> void:
	for ex in _all("caesar_word"):
		var w := str(ex.data.word)
		var k := int(ex.data.shift)
		match int(ex._level):
			1:
				assert_eq(_right(ex), _caesar(w, k))
				assert_true(str(ex.prompt).contains(w) and str(ex.prompt).contains(str(k)))
			2:
				assert_eq(_right(ex), w)
				assert_true(str(ex.prompt).contains(_caesar(w, k)))
			3:
				assert_eq(_value(ex), float(k))
				assert_true(str(ex.prompt).contains(_caesar(w, k)))


# --- data, safety and sharing --------------------------------------------------------------------------------------------

func _possible(v: int, ages: bool) -> bool:
	return (v >= 5 and v <= 18) if ages else (v >= 100 and v <= 200)


func test_the_data_is_cleaned() -> void:
	for ex in _all("clean_data"):
		var rows: Array = ex.picture.rows
		var ages := str(ex.picture.head[1]) == "Age"
		var bad: Array[int] = []
		var good: Array[int] = []
		for r: Array in rows:
			if _possible(int(r[1]), ages):
				good.append(int(r[1]))
			else:
				bad.append(int(r[1]))
		assert_eq(bad.size(), 1, "one impossible value: %s" % [rows])
		match int(ex._level):
			1:
				assert_eq(_right(ex), str(bad[0]))
			2:
				var seen := {}
				var copies := 0
				for r: Array in rows:
					if seen.has(str(r)):
						copies += 1
					seen[str(r)] = true
				assert_eq(copies, 1)
				assert_eq(_value(ex), float(rows.size() - 2))
			3:
				var total := 0
				for v in good:
					total += v
				assert_eq(total % good.size(), 0, "a whole mean")
				assert_eq(_value(ex), float(total / good.size()))


func test_the_right_check_catches_it() -> void:
	for ex in _all("validate_entry"):
		var p := str(ex.prompt)
		if p.begins_with("A box takes"):
			var n := _ints(p)
			var v := _right(ex)
			assert_true(v.is_valid_int() and int(v) >= n[0] and int(v) <= n[1], p)
			for c: Variant in ex.choices:
				var t := ExerciseCheck.item_text(c)
				if t != v:
					assert_false(t.is_valid_int() and int(t) >= n[0] and int(t) <= n[1], "%s passes too" % t)
			continue
		var want := ""
		for w: String in CHECK_WORDS:
			if p.to_lower().contains(w.to_lower()):
				want = CHECK_WORDS[w]
		assert_eq(_right(ex), want, p)


func test_feeds_and_habits() -> void:
	for ex in _all("habit_check"):
		match int(ex._level):
			1:
				var want := ""
				for w: String in TRICK_WORDS:
					if str(ex.prompt).contains(w):
						want = TRICK_WORDS[w]
				assert_eq(_right(ex), want, str(ex.prompt))
			2:
				assert_true(G7ArtsGen.HEALTHY.has(_right(ex)))
			3:
				if ex.data.has("secs"):
					assert_eq(_value(ex), float(int(ex.data.mins) * 60 / int(ex.data.secs)))
				else:
					assert_eq(_value(ex), float(int(ex.data.hours) * 60 / 20))


func test_copyright_and_licences() -> void:
	for ex in _all("public_domain"):
		var died := int(ex.data.died)
		if ex._level == 2:
			assert_eq(bool(ex.answer), died + 71 <= 2026, str(ex.prompt))
		else:
			assert_eq(_value(ex), float(died + 71), str(ex.prompt))
			assert_true(bool(ex.get("year", false)), "a year shows as 1990, not 1,990")
	for ex in _all("licence_use"):
		match int(ex._level):
			1:
				var p := str(ex.prompt)
				var rules: Array = LICENCE_RULES[_right(ex)]
				if p.contains("without asking and without writing a credit"):
					assert_true(rules[0])
				elif p.contains("not sell"):
					assert_false(rules[1])
				elif p.contains("same licence"):
					assert_true(rules[3])
				elif p.contains("not change"):
					assert_false(rules[2])
				elif p.contains("ask before"):
					assert_eq(_right(ex), "all rights reserved")
				else:
					assert_eq(_right(ex), "CC BY", p)
			2:
				var lic := str(ex.data.licence)
				var rules: Array = LICENCE_RULES[lic]
				var p := str(ex.prompt)
				var want := true
				if p.contains("sell"):
					want = rules[1]
				elif p.contains("change") or p.contains("remix"):
					want = rules[2]
				elif p.contains("without a credit"):
					want = rules[0]
				elif p.contains("without asking"):
					want = false
				assert_eq(bool(ex.answer), want, "%s: %s" % [lic, p])
			3:
				var rules: Array = LICENCE_RULES[_right(ex)]
				assert_true(rules[1] and rules[2], _right(ex))


# --- art ---------------------------------------------------------------------------------------------------------------

func test_the_colour_schemes() -> void:
	for ex in _all("scheme_pick"):
		var b := WHEEL.find(str(ex.data.base))
		match int(ex._level):
			1:
				assert_eq(_right(ex), WHEEL[(b + 6) % 12])
			2:
				assert_eq(_right(ex), "%s and %s" % [WHEEL[(b + 11) % 12], WHEEL[(b + 1) % 12]])
			3:
				assert_eq(_right(ex), "%s and %s" % [WHEEL[(b + 4) % 12], WHEEL[(b + 8) % 12]])


func test_heads_scales_and_thirds() -> void:
	for ex in _all("head_heights"):
		var n := _ints(str(ex.prompt))
		var p := str(ex.prompt)
		if p.contains("How tall is each head"):
			assert_eq(_value(ex), float(n[1]) / float(n[0]), p)
		elif p.contains("hips"):
			assert_eq(_value(ex), float(n[1]) / 2.0, p)
		elif p.contains("knees"):
			assert_eq(_value(ex), float(n[1]) * 6.0 / 8.0, p)
		else:
			assert_eq(_value(ex), float(n[0]) * float(n[1]), p)
	for ex in _all("scale_drawing"):
		var p := str(ex.prompt)
		var n := _ints(p)
		var scale := n[1]
		if p.contains("on the plan. How many metres"):
			assert_almost_eq(_value(ex), float(n[2]) * scale / 100.0, 0.001, p)
		elif p.contains("You draw"):
			assert_almost_eq(_value(ex), float(n[0]) * 100.0 / 50.0, 0.001, p)
		else:
			assert_almost_eq(_value(ex), float(n[2]) * 100.0 / 20.0, 0.001, p)
	for ex in _all("thirds_place"):
		match int(ex._level):
			1:
				var x := float(ex.picture.subject[0])
				var y := float(ex.picture.subject[1])
				var near := func(v: float) -> bool: return absf(v - 1.0 / 3.0) < 0.04 or absf(v - 2.0 / 3.0) < 0.04
				assert_eq(bool(ex.answer), bool(near.call(x) or near.call(y)))
			2:
				var x := float(ex.picture.subject[0])
				var y := float(ex.picture.subject[1])
				assert_eq(_right(ex), ("top " if y < 0.5 else "bottom ") + ("left" if x < 0.5 else "right"))
			3:
				assert_eq(_value(ex), float(_ints(str(ex.prompt))[0]) * 2.0 / 3.0, str(ex.prompt))


func test_prints_and_years() -> void:
	for ex in _all("block_print"):
		if str(ex.type) == "number":
			assert_eq(_value(ex), float(_ints(str(ex.prompt))[1]))
			continue
		var want: Array = []
		for r: String in ex.picture.rows:
			want.append(r.reverse())
		assert_eq((ex.choices[int(ex.answer)] as Dictionary).picture.rows, want, "the print is the block mirrored")
	for ex in _all("art_dates"):
		match int(ex._level):
			1:
				for c: Variant in ex.choices:
					assert_lte(int(EVENTS[_right(ex)]), int(EVENTS[ExerciseCheck.item_text(c)]))
			2:
				var n := _ints(str(ex.prompt))
				assert_eq(_value(ex), float(absi(n[1] - n[0])))
			3:
				var order: Array = []
				for i: Variant in ex.answer:
					order.append(EVENTS[ExerciseCheck.item_text(ex.items[int(i)])])
				var sorted := order.duplicate()
				sorted.sort()
				assert_eq(order, sorted, "earliest first")


# --- music -------------------------------------------------------------------------------------------------------------

func _named(n: String) -> int:
	var s := int(SEMIS[n.left(1)])
	if n.contains("sharp") or n.ends_with("#"):
		s += 1
	elif n.contains("flat") or (n.length() == 2 and n.ends_with("b")):
		s -= 1
	return posmod(s, 12)


func _chord(key: String, numeral: String) -> Array[int]:
	var d := ["I", "ii", "iii", "IV", "V", "vi"].find(numeral)
	var out: Array[int] = []
	for k in [0, 2, 4]:
		out.append(posmod(_named(key) + MAJOR[(d + k) % 7], 12))
	return out


func test_the_primary_chords() -> void:
	for ex in _all("primary_chord"):
		var key := str(ex.data.key)
		match int(ex._level):
			1:
				var root := _chord(key, str(ex.data.numeral))[0]
				assert_eq(_named(_right(ex).trim_suffix(" major")), root, str(ex.prompt))
			2:
				var got: Array[int] = []
				for n in _right(ex).replace(" and ", ", ").split(", "):
					got.append(_named(n))
				assert_eq(got, _chord(key, str(ex.data.numeral)), str(ex.prompt))
			3:
				var note := _named(str(ex.data.note))
				var numeral := _right(ex).get_slice(" ", 0)
				assert_true(_chord(key, numeral).has(note), "%s is in %s" % [ex.data.note, numeral])
				for other: String in ["I", "IV", "V"]:
					if other != numeral:
						assert_false(_chord(key, other).has(note), "only one chord holds it")


func _root_of(sound_note: String) -> int:
	var n := sound_note.split(":")[0].split("+")[0]
	return _named(n.substr(0, n.length() - 1))


func test_the_cadences_heard() -> void:
	for ex in _all("cadence_ear"):
		var notes: Array = ex.sound.notes
		var home := _root_of(str(notes[0]))
		var last := posmod(_root_of(str(notes[-1])) - home, 12)
		var before := posmod(_root_of(str(notes[-2])) - home, 12)
		var right := _right(ex)
		if last == 7:
			assert_true(right.begins_with("unfinished") or right.begins_with("imperfect"), right)
		else:
			assert_eq(last, 0)
			if right.begins_with("perfect"):
				assert_eq(before, 7)
			elif right.begins_with("plagal"):
				assert_eq(before, 5)
			else:
				assert_eq(right, "finished")
		for n: String in notes:   # every chord is the key's major or minor triad, root first
			var parts := n.split(":")[0].split("+")
			var r := _named(parts[0].substr(0, parts[0].length() - 1))
			var third := posmod(_named(parts[1].substr(0, parts[1].length() - 1)) - r, 12)
			assert_true(third in [3, 4] and posmod(_named(parts[2].substr(0, parts[2].length() - 1)) - r, 12) == 7, n)


func test_the_ornaments() -> void:
	for ex in _all("ornament_play"):
		var note := str(ex.picture.note)
		var i := LETTERS.find(note.left(1))
		var up := LETTERS[(i + 1) % 7]
		var down := LETTERS[(i + 6) % 7]
		var n := note.left(1)
		var want: String = {"trill": "%s %s %s %s %s %s %s %s" % [up, n, up, n, up, n, up, n], "mordent": "%s %s %s" % [n, up, n],
			"turn": "%s %s %s %s" % [up, n, down, n]}[str(ex.picture.type)]
		assert_eq(_right(ex), want)


func test_the_periods_and_the_bass_clef() -> void:
	for ex in _all("era_facts"):
		match int(ex._level):
			1:
				assert_eq(_right(ex), str(PERIODS[str(ex.data.who)][0]))
			2:
				var f := str(ex.data.feature)
				var baroque := f.contains("harpsichord") or f.contains("ground bass") or f.contains("terraced") or f.contains("fugue")
				assert_eq(_right(ex), "Baroque" if baroque else "Classical", f)
			3:
				assert_eq(_value(ex), float(int(PERIODS[str(ex.data.b)][1]) - int(PERIODS[str(ex.data.a)][1])))
	var lines := {"G2": "G", "B2": "B", "D3": "D", "F3": "F", "A3": "A"}
	for ex in _all("bass_note"):
		var p: Dictionary = ex.picture
		var note := str(p.notes[int(p.get("mark", 0))])
		# this test's own placing: the lines from the bottom G, B, D, F, A; so the letter is the note's own
		var pos := LETTERS.find(note.left(1)) + 7 * int(note.right(1)) - (LETTERS.find("G") + 14)
		assert_between(pos, -2, 10, note)
		assert_eq(_right(ex), note.left(1))
		if ex._level == 1:
			assert_true(lines.has(note) and pos % 2 == 0, "%s is on a line" % note)


func test_the_beats_riffs_and_tempo() -> void:
	for ex in _all("dotted_beats"):
		var total := 0.0
		for v: String in ex.picture.values:
			total += float(BEATS[v])
		assert_almost_eq(_value(ex), total, 0.001, str(ex.picture.values))
	for ex in _all("riff_repeat"):
		match int(ex._level):
			1:
				var n := _ints(str(ex.prompt))
				assert_eq(_value(ex), float(n[1]) / float(n[0]))
			2:
				var riff: Array = ex.data.riff
				var moved := _right(ex).split(", ")
				var shift := posmod(int(SEMIS[moved[0]]) - int(SEMIS[str(riff[0])]), 12)
				for i in riff.size():
					assert_eq(posmod(int(SEMIS[moved[i]]) - int(SEMIS[str(riff[i])]), 12), shift, "every note moves the same: %s" % [moved])
			3:
				assert_eq(_value(ex), float((ex.sound.notes as Array).count("-")), "a rest after each riff")
	for ex in _all("song_length"):
		var n := _ints(str(ex.prompt))
		match int(ex._level):
			1:
				var sum := 0
				for v in n:
					sum += v
				assert_eq(_value(ex), float(sum))
			2:
				assert_eq(_value(ex), float(n[0]) * float(n[1]) * 60.0 / float(n[2]))
			3:
				assert_eq(_value(ex), float(n[0]) * float(n[1]) * 60.0 / float(n[2]))
	for ex in _all("folk_metre"):
		var p := str(ex.prompt)
		match int(ex._level):
			1:
				var t := RegEx.create_from_string("(\\d+)/(\\d)").search(p)
				var top := float(t.get_string(1))
				assert_eq(_value(ex), top if t.get_string(2) == "8" else top * 2.0, p)
			2:
				assert_eq(_value(ex), float(_ints(p)[2]) / 6.0, p)
			3:
				assert_eq(_value(ex), float(_ints(p)[0]) / 3.0, p)


func test_the_film_cues_and_the_mix() -> void:
	var scenes := {"chase": "fast", "sunrise": "rising", "sneak": "quiet", "storm": "crashing", "hero": "fanfare", "villain": "low, slow",
		"comedy": "bouncy", "farewell": "soft strings"}
	for ex in _all("film_cue"):
		match int(ex._level):
			1:
				assert_true(_right(ex).contains(scenes[str(ex.picture.frames[0])]), _right(ex))
			2:
				var notes: Array = ex.sound.notes
				var first := str(notes[0])
				var want := "the hero arriving"
				if first.contains("3"):
					want = "the villain appearing"
				elif notes.has("-"):
					want = "someone sneaking at night"
				elif str(ex.sound.get("tone", "")) == "pure":
					want = "friends saying goodbye"
				assert_eq(_right(ex), want)
			3:
				var minor := false
				for n: String in ex.sound.notes:
					minor = minor or n.contains("Eb")
				assert_eq(_right(ex), "the hero is in trouble and losing hope" if minor else "the hero wins and is full of hope")
	for ex in _all("mix_balance"):
		var faders: Array = ex.picture.faders
		var top := 0
		for i in faders.size():
			if int(faders[i][1]) > int(faders[top][1]):
				top = i
		match int(ex._level):
			1:
				assert_eq(_right(ex), str(faders[top][0]))
			2:
				assert_true(str(ex.prompt).contains(_right(ex)))
				assert_ne(_right(ex), str(faders[top][0]), "the tune is not already the loudest")
			3:
				var v := int(ex.picture.mark)
				var best := 0
				for i in faders.size():
					if i != v:
						best = maxi(best, int(faders[i][1]))
				assert_eq(_value(ex), float(best + 2 - int(faders[v][1])))
				assert_lte(best + 2, 10, "the fader can go that high")
