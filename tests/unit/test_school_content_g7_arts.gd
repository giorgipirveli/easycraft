extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.7): grade 7's computing, art
## and design and music are written for every unit of the outline, one step up from grade 6 (the spiral). Each unit
## teaches with a lesson of 4 or more cards that opens with a memory question and ends with something to try in the world
## and what comes next (research §5.3 rules 1, 7 and 8), has at least 12 hand-written exercises at levels 1, 2 and 3 of at
## least two kinds, each with a hint (a strategy) and a worked answer, and rounds that vary and never show a hand-written
## exercise twice. The music units that teach listening let the child listen in at least 6 exercises each.
## The facts are worked out again with this test's own rules and tables: every text program is run by the tests' own
## interpreter (tests/fakes/text_code_runner.gd: what it prints, what it leaves in a variable, the line it stops on, the
## output a picture shows), lists and their indexes, linear and binary search, bubble sort, the Caesar cipher, safe IP
## addresses, when copyright ends, colour schemes on the wheel, scale drawings, the rule of thirds, a woodcut's mirrored
## print, primary chords, cadences heard, ornaments, the bass clef, dotted notes and ties, the tempo's sums, the parts of
## a mix, the people's years and their symphonies, and every label's line to its part.
## (Every exercise's validity, answers, pictures and words are the shared content test's, test_school_content.gd.)

const Runner := preload("res://tests/fakes/text_code_runner.gd")
const GRADE := 7
const SUBJECTS: Array[String] = ["computing", "art", "music"]
const UNITS := {"computing": 11, "art": 9, "music": 9}   # research §6.7
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## Music units that teach listening, and the sounds they must use: "rhythm" (claps), "notes" (a tune, chords or parts)
## or "any".
const LISTENING := {"g7.music.chord_progressions": "notes", "g7.music.baroque": "notes", "g7.music.classical_era": "notes",
	"g7.music.popular_music": "any", "g7.music.riffs_hooks": "notes", "g7.music.film_music": "notes",
	"g7.music.perform_together": "any", "g7.music.bass_clef": "notes", "g7.music.folk_music": "any"}
const MIN_SOUNDS := 6
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const LETTERS := "CDEFGAB"
const MAJOR_SCALE: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const NUMERALS: Array[String] = ["I", "ii", "iii", "IV", "V", "vi"]
## Composers and artists of the past (this test's own; every "Name (born-died)" agrees).
const PEOPLE := {"Leonardo": [1452, 1519], "Michelangelo": [1475, 1564], "Raphael": [1483, 1520], "Masaccio": [1401, 1428],
	"Brunelleschi": [1377, 1446], "Dürer": [1471, 1528], "Eyck": [1390, 1441], "Akbar": [1542, 1605],
	"Jahangir": [1569, 1627], "Hokusai": [1760, 1849], "Hiroshige": [1797, 1858], "Moronobu": [1618, 1694],
	"Itten": [1888, 1967], "Albers": [1888, 1976], "Wren": [1632, 1723], "Hadid": [1950, 2016], "Palladio": [1508, 1580],
	"Bach": [1685, 1750], "Handel": [1685, 1759], "Vivaldi": [1678, 1741], "Purcell": [1659, 1695],
	"Pachelbel": [1653, 1706], "Haydn": [1732, 1809], "Mozart": [1756, 1791], "Beethoven": [1770, 1827],
	"Wagner": [1813, 1883], "Prokofiev": [1891, 1953], "Sharp": [1859, 1924],
	"Turing": [1912, 1954], "Kindi": [801, 873], "Caesar": [100, 44], "Lovelace": [1815, 1852], "Bartok": [1881, 1945]}
## How many symphonies each wrote (this test's own; the numbered ones).
const SYMPHONIES := {"Haydn": 104, "Mozart": 41, "Beethoven": 9}
## Beats of each note (this test's own), a dotted note half as long again.
const BEATS := {"semibreve": 4.0, "minim": 2.0, "crotchet": 1.0, "quaver": 0.5, "semiquaver": 0.25}
## The 12-colour painters' wheel from yellow, clockwise (this test's own; SchoolPictureG4Arts.WHEEL agrees).
const WHEEL: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red", "red-purple", "purple",
	"blue-purple", "blue", "blue-green", "green", "yellow-green"]
## Addresses a lesson may show (made for examples and home networks, so no real computer is named): 192.168.x.x,
## 10.x.x.x, 192.0.2.x, 198.51.100.x and 203.0.113.x.
const SAFE_IP := ["192.168.", "10.", "192.0.2.", "198.51.100.", "203.0.113."]
const PERSONAL := "(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)"


func _units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for subject in SUBJECTS:
		out.append_array(Curriculum.units(GRADE, subject))
	return out


func _texts(id: String) -> Array[String]:
	var out: Array[String] = []
	var c := Curriculum.content(id)
	for card: Dictionary in c.lesson:
		out.append(str(card.text))
	for ex: Dictionary in c.exercises:
		out.append_array([str(ex.prompt), str(ex.hint), str(ex.get("explain", ""))])
		for it: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []):
			out.append(ExerciseCheck.item_text(it))
	return out


func _subject_texts(subject: String) -> Array[String]:
	var out: Array[String] = []
	for u in Curriculum.units(GRADE, subject):
		if Curriculum.has_content(str(u.id)):
			out.append_array(_texts(str(u.id)))
	return out


func _exercises(subject: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in Curriculum.units(GRADE, subject):
		if Curriculum.has_content(str(u.id)):
			for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
				out.append(ex)
	return out


## Every picture of a subject's lessons and exercises (and the choices' pictures).
func _pictures(subject: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in Curriculum.units(GRADE, subject):
		if not Curriculum.has_content(str(u.id)):
			continue
		var c := Curriculum.content(str(u.id))
		for card: Dictionary in c.lesson:
			if card.get("picture") is Dictionary:
				out.append(card.picture)
		for ex: Dictionary in c.exercises:
			if ex.get("picture") is Dictionary:
				out.append(ex.picture)
			for ch: Variant in ex.get("choices", []):
				if ch is Dictionary and ch.get("picture") is Dictionary:
					out.append(ch.picture)
	return out


func _right(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 7 %s" % subject)


func test_grade_7_computing_art_music_are_written_for_every_unit() -> void:
	var exercises := 0
	for u in _units():
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), MIN_CARDS, Curriculum.MAX_CARDS, "%s: a lesson of 4 to 8 cards" % id)
		assert_gte((c.exercises as Array).size(), MIN_EXERCISES, "%s: at least %d hand-written exercises" % [id, MIN_EXERCISES])
		exercises += (c.exercises as Array).size()
		var levels := {}
		var types := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.level)] = true
			types[str(ex.type)] = true
		assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
		assert_gte(types.size(), 2, "%s: at least two kinds of hand-written exercise" % id)
		var distinct := {}
		for stars in [0, 1, 2]:
			for s in 20:
				var round := RoundPlan.plan(c, s * 7 + stars, stars)
				assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
				var ids := {}
				for ex in round:
					distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", "")) + str(ex.get("board", ""))] = true
					if not str(ex.id).begins_with("gen:"):
						assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
						ids[ex.id] = true
		assert_gte(distinct.size(), 12, "%s: varied practice" % id)
	gut.p("%d hand-written exercises in grade 7 computing, art and music" % exercises)


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" and "Do it in the world"; the spiral: each lesson names what comes next.
func test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		assert_true(str(cards[0].text).begins_with("Quick memory:") and str(cards[0].text).contains("?"),
			"%s: the first card asks a memory question" % id)
		assert_true(str(cards[-1].text).to_lower().contains("world"), "%s: the last card is something to try in the world" % id)
		assert_true(str(cards[-1].text).contains("Next"), "%s: the last card says what comes next" % id)


func test_the_music_units_let_you_listen() -> void:
	for id: String in LISTENING:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var sounds := 0
		for ex: Dictionary in Curriculum.content(id).exercises:
			if ex.get("sound") is Dictionary and (LISTENING[id] == "any" or str(ex.sound.kind) == LISTENING[id]):
				sounds += 1
		assert_gte(sounds, MIN_SOUNDS, "%s: %d exercises to listen to" % [id, sounds])


## The generators these units use are their own ("g7c"), each exists, and every one of them is used here.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with("g7c."), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	assert_gt(used.size(), 0, "the units practise with generators")
	for gen in SchoolGen.ids():
		if gen.begins_with("g7c."):
			assert_true(used.has(gen), "%s is used by a grade 7 computing, art or music unit" % gen)


## Research §5.4 rule 6: online safety every grade, and never ask a child for personal details.
func test_the_lessons_never_ask_for_personal_details() -> void:
	var ask := RegEx.create_from_string(PERSONAL)
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			assert_null(ask.search(str(ex.prompt).to_lower()), "%s asks: %s" % [ex.id, ex.prompt])


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG7Arts.part_at, at the
## label box's size).
func test_every_label_points_at_its_part() -> void:
	var checked := 0
	for subject in SUBJECTS:
		for ex in _exercises(subject):
			if str(ex.type) != "label" or not SchoolPictureG7Arts.KINDS.has(str(ex.picture.kind)):
				continue
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part := SchoolPictureG7Arts.part_at(ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
	assert_gte(checked, 12, "labels were checked")


# --- Computing facts -------------------------------------------------------------------------------------------------

## Every text program in a picture runs as the picture says: with no mistake unless it marks one (then the program stops
## with a syntax error, or an error, on that line) or its exercise asks which line stops it (worked out in the next
## test), and printing what its output panel shows.
func test_every_program_runs_as_its_picture_shows() -> void:
	var checked := 0
	var asks_line := {}
	for subject in SUBJECTS:
		for ex in _exercises(subject):
			if str(ex.type) == "number" and ex.get("picture") is Dictionary \
					and RegEx.create_from_string("which line|what line").search(str(ex.prompt).to_lower()) != null:
				asks_line[str(ex.picture.lines)] = true
	for subject in SUBJECTS:
		for p in _pictures(subject):
			if str(p.kind) != "text_code":
				continue
			var st := Runner.run(p.lines)
			if p.has("error"):
				assert_ne(str(st.error), "", "%s: the marked mistake stops it" % [p.lines])
				assert_eq(int(st.line), int(p.error) + 1, "%s: it stops on the marked line" % [p.lines])
			elif not asks_line.has(str(p.lines)):
				assert_eq(str(st.error), "", "%s runs (%s on line %d)" % [p.lines, st.error, st.line])
			if p.has("output"):
				assert_eq(st.out, p.output, "%s prints what the picture shows" % [p.lines])
			checked += 1
	assert_gte(checked, 40, "programs were run")


## "What does this program print?", "What is x when the program ends?", "Which line stops the program?" and "What does it
## print on line 2 of its output?" about a text program: worked out by running it.
func test_the_programs_do_what_the_exercises_say() -> void:
	var checked := 0
	var ends := RegEx.create_from_string("what is (\\w+) when (?:the program|it) ends")
	var line_q := RegEx.create_from_string("which line|what line|on which line")
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "text_code":
			continue
		var low := str(ex.prompt).to_lower()
		var st := Runner.run(pic.lines)
		var m := ends.search(low)
		if str(ex.type) == "number" and m != null:
			assert_eq(str(st.error), "", "%s runs" % ex.id)
			assert_almost_eq(NumberAnswer.value(str(ex.answer)), float(st.vars.get(m.get_string(1), NAN)), 0.0001,
				"%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif str(ex.type) == "number" and line_q.search(low) != null:
			assert_ne(str(st.error), "", "%s: the program has a mistake" % ex.id)
			assert_eq(NumberAnswer.value(str(ex.answer)), float(st.line), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif low.contains("print") and not pic.has("output") and str(st.error) == "":
			var said := ", ".join(st.out)
			if str(ex.type) == "number":
				assert_eq((st.out as Array).size(), 1, "%s prints one line" % ex.id)
				assert_almost_eq(NumberAnswer.value(str(ex.answer)), float(said), 0.0001, "%s: %s" % [ex.id, ex.prompt])
				checked += 1
			elif str(ex.type) == "choice":
				assert_eq(_right(ex), said, "%s: %s" % [ex.id, ex.prompt])
				checked += 1
			elif str(ex.type) == "truefalse":
				var claim := RegEx.create_from_string("prints (.+?)\\.?$").search(str(ex.prompt))
				if claim != null:
					assert_eq(claim.get_string(1).replace("\"", "") == said, bool(ex.answer), "%s: %s" % [ex.id, ex.prompt])
					checked += 1
	assert_gte(checked, 25, "programs were run for the exercises")


## "What is gems[2]?" and "What is len(gems)?" about a list picture: the item at that index (from 0; -1 the last), and
## the list's length.
func test_the_lists_are_read_right() -> void:
	var item := RegEx.create_from_string("\\b(\\w+)\\[(-?\\d+)\\]")
	var size := RegEx.create_from_string("len\\((\\w+)\\)")
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "list_boxes" or pic.has("hide"):
			continue
		var items: Array = pic.items
		var right := str(ex.answer) if str(ex.type) == "number" else (_right(ex) if str(ex.type) == "choice" else "")
		if right == "":
			continue
		var m := item.search(str(ex.prompt))
		var n := size.search(str(ex.prompt))
		if n != null:
			assert_eq(right, str(items.size()), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif m != null:
			var i := int(m.get_string(2))
			i += items.size() if i < 0 else 0
			assert_eq(right.replace("\"", ""), str(items[i]).replace("\"", ""), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
	assert_gte(checked, 6, "lists were read")


## The checks a search makes (this test's own): linear from the start until found; binary on a sorted list, looking at
## the middle ((low + high) ÷ 2, rounded down) and keeping the half the target can be in.
func _checks(items: Array, target: int, method: String) -> Array[int]:
	var out: Array[int] = []
	if method == "linear":
		for i in items.size():
			out.append(i)
			if int(items[i]) == target:
				break
		return out
	var lo := 0
	var hi := items.size() - 1
	while lo <= hi:
		var mid := (lo + hi) / 2
		out.append(mid)
		if int(items[mid]) == target:
			break
		if int(items[mid]) < target:
			lo = mid + 1
		else:
			hi = mid - 1
	return out


## Every search picture's "how many checks" and "which item is checked first/next", and every "binary search needs at
## most N checks for M items" (the checks double the items it can search: M < 2^N).
func test_the_searches_are_counted_right() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "search_steps":
			continue
		var low := str(ex.prompt).to_lower()
		var checks := _checks(pic.items, int(pic.target), str(pic.method))
		if str(ex.type) == "number" and low.contains("how many"):
			assert_eq(NumberAnswer.value(str(ex.answer)), float(checks.size()), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif str(ex.type) == "choice" and low.contains("first") and low.contains("check"):
			assert_eq(_right(ex), str(int(pic.items[checks[0]])), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
	var most := RegEx.create_from_string("at most (\\d+) checks (?:for|to search|to find a name in) ([\\d,]+)")
	for t in _subject_texts("computing"):
		for m in most.search_all(t):
			var n := int(m.get_string(2).replace(",", ""))
			var k := 0
			while (1 << k) <= n:
				k += 1
			assert_eq(int(m.get_string(1)), k, t)
			checked += 1
	assert_gte(checked, 8, "searches were counted")


func _bubble_pass(items: Array) -> Dictionary:
	var a := items.duplicate()
	var swaps := 0
	for i in a.size() - 1:
		if int(a[i]) > int(a[i + 1]):
			var t: Variant = a[i]
			a[i] = a[i + 1]
			a[i + 1] = t
			swaps += 1
	return {"items": a, "swaps": swaps}


## Every "What is the list after one pass of bubble sort?" and "How many swaps in the first pass?" about a sort picture.
func test_bubble_sort_is_done_right() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "sort_bars" or str(pic.method) != "bubble" \
				or int(pic.get("pass", 0)) != 0:
			continue
		var low := str(ex.prompt).to_lower()
		var one := _bubble_pass(pic.items)
		if low.contains("one pass") and str(ex.type) == "choice":
			var want: Array[String] = []
			for v: Variant in one.items:
				want.append(str(int(v)))
			assert_eq(_right(ex), ", ".join(want), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif low.contains("swaps") and str(ex.type) == "number":
			assert_eq(NumberAnswer.value(str(ex.answer)), float(one.swaps), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
	assert_gte(checked, 4, "bubble sorts were checked")


func _caesar(text: String, shift: int) -> String:
	var out := ""
	for ch in text:
		var c := ch.unicode_at(0)
		if c >= 65 and c <= 90:
			out += String.chr(65 + posmod(c - 65 + shift, 26))
		else:
			out += ch
	return out


## Every "With a shift of 3, CAT becomes FDW" and "FDW decodes to CAT with a shift of 3" the lessons state.
func test_the_caesar_ciphers_are_right() -> void:
	var enc := RegEx.create_from_string("[Ww]ith a shift of (\\d+), ([A-Z]{2,}(?: [A-Z]{2,})*) becomes ([A-Z]{2,}(?: [A-Z]{2,})*)")
	var dec := RegEx.create_from_string("\\b([A-Z]{2,}(?: [A-Z]{2,})*) decodes to ([A-Z]{2,}(?: [A-Z]{2,})*) with a shift of (\\d+)")
	var checked := 0
	for t in _subject_texts("computing"):
		for m in enc.search_all(t):
			assert_eq(_caesar(m.get_string(2), int(m.get_string(1))), m.get_string(3), t)
			checked += 1
		for m in dec.search_all(t):
			assert_eq(_caesar(m.get_string(2), int(m.get_string(3))), m.get_string(1), t)
			checked += 1
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) == "choice" and pic is Dictionary and str(pic.get("kind", "")) == "cipher_wheel" \
				and pic.has("word") and str(ex.prompt).to_lower().contains("code"):
			var want := _caesar(str(pic.word), -int(pic.shift) if pic.get("decode", false) else int(pic.shift))
			assert_eq(_right(ex), want, "%s: %s" % [ex.id, ex.prompt])
			checked += 1
	assert_gte(checked, 8, "codes were checked")


## Every IP address the lessons show that could be real is one made for examples or home networks (so no real computer
## is named); one with a number over 255 is never an address, and the lessons say so.
func test_the_ip_addresses_are_safe_examples() -> void:
	var quad := RegEx.create_from_string("\\b(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\b")
	var checked := 0
	var texts := _subject_texts("computing")
	for p in _pictures("computing"):
		texts.append(str(p))
	for t in texts:
		for m in quad.search_all(t):
			var ok := true
			for k in [1, 2, 3, 4]:
				ok = ok and int(m.get_string(k)) <= 255
			if not ok:
				continue
			var safe := false
			for s: String in SAFE_IP:
				safe = safe or m.get_string().begins_with(s)
			assert_true(safe, "%s is an example address: %s" % [m.get_string(), t])
			checked += 1
	assert_gte(checked, 6, "IP addresses were checked")


## Copyright lasts 70 years after the creator dies, to the end of that year (the UK and many countries): "died in 1950 …
## from 1 January 2021".
func test_copyright_ends_when_the_lessons_say() -> void:
	var rule := RegEx.create_from_string("died in (\\d{4})[^.]*? (?:from|on) 1 January (\\d{4})")
	var checked := 0
	for t in _subject_texts("computing"):
		for m in rule.search_all(t):
			assert_eq(int(m.get_string(2)), int(m.get_string(1)) + 71, t)
			checked += 1
	assert_gte(checked, 3, "copyright years were checked")


# --- Art facts -------------------------------------------------------------------------------------------------------

func _hue(name: String) -> int:
	return WHEEL.find(name)


## Every "X and Y are complementary" (opposite on the 12-colour wheel), "X, Y and Z are analogous" (side by side) and "X,
## Y and Z make a triad" (a third of the wheel apart) the lessons state, and every colour_scheme picture's colours.
func test_the_colour_schemes_are_right() -> void:
	var colour := "(yellow-orange|red-orange|red-purple|blue-purple|blue-green|yellow-green|yellow|orange|red|purple|blue|green)"
	var comp := RegEx.create_from_string("\\b" + colour + " and " + colour + " are complementary")
	var three := RegEx.create_from_string("\\b" + colour + ", " + colour + " and " + colour + " (are analogous|make a triad)")
	var checked := 0
	for t in _subject_texts("art"):
		for m in comp.search_all(t):
			assert_eq(posmod(_hue(m.get_string(2)) - _hue(m.get_string(1)), 12), 6, t)
			checked += 1
		for m in three.search_all(t):
			var hs: Array[int] = [_hue(m.get_string(1)), _hue(m.get_string(2)), _hue(m.get_string(3))]
			hs.sort()
			var gaps: Array[int] = [hs[1] - hs[0], hs[2] - hs[1], 12 - hs[2] + hs[0]]
			gaps.sort()
			if m.get_string(4) == "make a triad":
				assert_eq(gaps, [4, 4, 4] as Array[int], t)
			else:
				assert_eq(gaps, [1, 1, 10] as Array[int], t)
			checked += 1
	for p in _pictures("art"):
		if str(p.kind) != "colour_scheme" or str(p.scheme) in ["warm", "cool", "monochrome"]:
			continue
		var b := _hue(str(p.base))
		var want: Array = {"complementary": [0, 6], "analogous": [11, 0, 1], "triadic": [0, 4, 8],
			"split": [0, 5, 7]}[str(p.scheme)]
		var got: Array = []
		for c: String in SchoolPictureG7Arts.scheme_colours(str(p.scheme), str(p.base)):
			got.append(posmod(_hue(c) - b, 12))
		got.sort()
		want = want.duplicate()
		want.sort()
		assert_eq(got, want, "%s on %s" % [p.scheme, p.base])
		checked += 1
	assert_gte(checked, 8, "colour schemes were checked")


## Every "At 1:50, 4 cm on the plan is 2 m" (a scale drawing) the lessons state.
func test_the_scale_drawings_are_right() -> void:
	var rule := RegEx.create_from_string("[Aa]t (?:a scale of )?1:(\\d+), (\\d+(?:\\.\\d+)?) cm on the (?:plan|drawing|model) (?:is|stands for|shows) (\\d+(?:\\.\\d+)?) (m|cm)\\b")
	var checked := 0
	for t in _subject_texts("art"):
		for m in rule.search_all(t):
			var real_cm := float(m.get_string(2)) * int(m.get_string(1))
			assert_almost_eq(float(m.get_string(3)) * (100.0 if m.get_string(4) == "m" else 1.0), real_cm, 0.001, t)
			checked += 1
	assert_gte(checked, 4, "scale drawings were checked")


## "Is the subject on a third?": within 0.04 of a third line (1/3 or 2/3 across or down), by this test's own rule.
func test_the_rule_of_thirds_is_judged_right() -> void:
	var checked := 0
	for ex in _exercises("art"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "thirds_frame":
			continue
		var low := str(ex.prompt).to_lower()
		if str(ex.type) != "truefalse" or not low.contains("third"):
			continue
		var x := float(pic.subject[0])
		var y := float(pic.subject[1])
		var near := func(v: float) -> bool: return absf(v - 1.0 / 3.0) < 0.04 or absf(v - 2.0 / 3.0) < 0.04
		var on: bool = near.call(x) or near.call(y)
		if low.contains("where two") or low.contains("crossing"):
			on = near.call(x) and near.call(y)
		assert_eq(bool(ex.answer), on, "%s: %s" % [ex.id, ex.prompt])
		checked += 1
	assert_gte(checked, 3, "photos were judged")


## A woodcut prints mirrored: "Which print does this block make?" has the block's rows reversed left to right as its
## right answer (the raised parts, #, print).
func test_a_block_prints_mirrored() -> void:
	var checked := 0
	for ex in _exercises("art"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "carved_block":
			continue
		var right: Variant = ex.choices[int(ex.answer)]
		if not right is Dictionary or not right.get("picture") is Dictionary:
			continue
		var want: Array = []
		for row: String in pic.rows:
			want.append(row.reverse())
		assert_eq(right.picture.rows, want, "%s: the print is the block mirrored" % ex.id)
		checked += 1
	assert_gte(checked, 2, "prints were checked")


## Every "Leonardo da Vinci (1452-1519)" has the person's years.
func test_the_years_are_right() -> void:
	var names := "|".join(PackedStringArray(PEOPLE.keys()))
	var rule := RegEx.create_from_string("\\b(" + names + ")(?: da Vinci| van Eyck| al-Kindi| of \\w+)? \\((?:about )?(\\d{3,4})(?: BC)?-(\\d{2,4})(?: BC)?\\)")
	var checked := 0
	for subject in SUBJECTS:
		for t in _subject_texts(subject):
			for m in rule.search_all(t):
				assert_eq([int(m.get_string(2)), int(m.get_string(3))], PEOPLE[m.get_string(1)], t)
				checked += 1
		for p in _pictures(subject):
			if str(p.kind) != "lifespans":
				continue
			for row: Array in p.people:
				var who := str(row[0]).get_slice(" ", str(row[0]).get_slice_count(" ") - 1)
				if PEOPLE.has(who):
					assert_eq([int(row[1]), int(row[2])], PEOPLE[who], "the lifespans picture: %s" % [row])
					checked += 1
	assert_gte(checked, 12, "the years were checked")


# --- Music facts -----------------------------------------------------------------------------------------------------

## "C" -> 0, "B flat" or "Bb" -> 10, "F sharp" or "F#" -> 6.
func _named(name: String) -> int:
	var s := int(SEMIS[name.left(1)])
	if name.contains("sharp") or name.contains("#"):
		s += 1
	elif name.contains("flat") or (name.length() >= 2 and name[1] == "b"):
		s -= 1
	return posmod(s, 12)


## The notes (0-11) of chord `numeral` in the major key `key`: the scale's notes 1, 3 and 5 counted from that numeral's
## note (this test's own).
func _chord(key: String, numeral: String) -> Array[int]:
	var home := _named(key)
	var d := NUMERALS.find(numeral)
	var out: Array[int] = []
	for k in [0, 2, 4]:
		out.append(posmod(home + MAJOR_SCALE[(d + k) % 7], 12))
	return out


## A chord's name from its notes: the root's name, and " minor" when its third is 3 semitones up.
func _chord_name(key: String, numeral: String, flats: bool) -> String:
	var notes := _chord(key, numeral)
	var names := ["C", "C sharp", "D", "E flat", "E", "F", "F sharp", "G", "A flat", "A", "B flat", "B"] if flats \
		else ["C", "C sharp", "D", "D sharp", "E", "F", "F sharp", "G", "G sharp", "A", "B flat", "B"]
	return str(names[notes[0]]) + (" minor" if posmod(notes[1] - notes[0], 12) == 3 else "")


## Every "Chord IV in G major is C", every "The C major chord is C, E and G" (and minor), and every chord chart's hidden
## chord asked about.
func test_the_chords_are_right() -> void:
	var checked := 0
	var in_key := RegEx.create_from_string("[Cc]hord (I|ii|iii|IV|V|vi) in ([A-G](?: flat| sharp)?) major is ([A-G](?: flat| sharp)?(?: minor)?)\\b")
	var built := RegEx.create_from_string("\\b([A-G](?: flat| sharp)?) (major|minor) chord is ([A-G](?: flat| sharp)?), ([A-G](?: flat| sharp)?) and ([A-G](?: flat| sharp)?)\\b")
	for t in _subject_texts("music"):
		for m in in_key.search_all(t):
			var key := m.get_string(2)
			assert_eq(m.get_string(3), _chord_name(key, m.get_string(1), key.contains("flat") or key == "F"), t)
			checked += 1
		for m in built.search_all(t):
			var root := _named(m.get_string(3))
			assert_eq(_named(m.get_string(1)), root, t)
			assert_eq(posmod(_named(m.get_string(4)) - root, 12), 4 if m.get_string(2) == "major" else 3, t)
			assert_eq(posmod(_named(m.get_string(5)) - root, 12), 7, t)
			checked += 1
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "chord_chart" \
				or (pic.get("hide", []) as Array).size() != 1:
			continue
		var numeral := str(pic.chords[int(pic.hide[0])])
		var low := str(ex.prompt).to_lower()
		var want := numeral if low.contains("numeral") else SchoolPictureG7Arts.chord_name(str(pic.key), numeral)
		assert_eq(_right(ex), want, "%s: %s" % [ex.id, ex.prompt])
		if not low.contains("numeral"):
			var root := _named(want.left(1) + ("b" if want.contains("b") and want.length() > 1 and want[1] == "b" else ""))
			assert_eq(root, _chord(str(pic.key), numeral)[0], "%s: the chord's root" % ex.id)
		checked += 1
	assert_gte(checked, 10, "chords were checked")


## A chord's root (0-11), from a sound's "C4+E4+G4:2".
func _root(chord: String) -> int:
	var n := chord.split(":")[0].split("+")[0]
	return _named(n.substr(0, n.length() - 1))


## Heard cadences: the first chord of the sound is the home chord (I); a phrase that ends on I is finished (a perfect
## cadence from V, a plagal one from IV), one that ends on V is unfinished (an imperfect cadence).
func test_the_cadences_heard_are_named_right() -> void:
	var checked := 0
	for ex in _exercises("music"):
		if str(ex.type) != "choice" or not ex.get("sound") is Dictionary or str(ex.sound.kind) != "notes":
			continue
		var words := ",".join(PackedStringArray(ex.choices.map(func(c: Variant) -> String: return ExerciseCheck.item_text(c)))).to_lower()
		if not (words.contains("finished") or words.contains("perfect") or words.contains("plagal")):
			continue
		var chords: Array = (ex.sound.notes as Array).filter(func(n: Variant) -> bool: return str(n).contains("+"))
		var home := _root(str(chords[0]))
		var last := posmod(_root(str(chords[-1])) - home, 12)
		var before := posmod(_root(str(chords[-2])) - home, 12)
		var right := _right(ex).to_lower()
		if last == 7:
			assert_true(right.contains("unfinished") or right.contains("imperfect"), "%s ends on V: %s" % [ex.id, right])
		else:
			assert_eq(last, 0, "%s ends on I or V" % ex.id)
			assert_false(right.contains("unfinished") or right.contains("imperfect"), "%s ends on I: %s" % [ex.id, right])
			if right.contains("perfect"):
				assert_eq(before, 7, "%s: a perfect cadence is V to I" % ex.id)
			if right.contains("plagal"):
				assert_eq(before, 5, "%s: a plagal cadence is IV to I" % ex.id)
		checked += 1
	assert_gte(checked, 5, "cadences were heard")


## A note's pitch in semitones ("C4" = 48), -1 for anything else.
func _pitch(note: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([#b]?)([2-6])$").search(note.split(":")[0])
	if m == null:
		return -1
	var s := int(SEMIS[m.get_string(1)]) + (1 if m.get_string(2) == "#" else -1 if m.get_string(2) == "b" else 0)
	return 12 * int(m.get_string(3)) + s


## The bass clef's lines are G, B, D, F and A (from the bottom) and its spaces A, C, E and G; every "name the note" about
## a bass clef picture with one note (or one marked note) has that note's letter as its answer.
func test_the_bass_clef_is_read_right() -> void:
	var checked := 0
	var lines := RegEx.create_from_string("bass clef's lines are ([A-G]), ([A-G]), ([A-G]), ([A-G]) and ([A-G])")
	var spaces := RegEx.create_from_string("bass clef's spaces are ([A-G]), ([A-G]), ([A-G]) and ([A-G])")
	for t in _subject_texts("music"):
		for m in lines.search_all(t):
			assert_eq([m.get_string(1), m.get_string(2), m.get_string(3), m.get_string(4), m.get_string(5)],
				["G", "B", "D", "F", "A"], t)
			checked += 1
		for m in spaces.search_all(t):
			assert_eq([m.get_string(1), m.get_string(2), m.get_string(3), m.get_string(4)], ["A", "C", "E", "G"], t)
			checked += 1
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "clef_stave":
			continue
		if not str(ex.prompt).to_lower().contains("which note") and not str(ex.prompt).to_lower().contains("name the"):
			continue
		var notes: Array = pic.notes
		var note := str(notes[int(pic.mark)]) if pic.has("mark") else (str(notes[0]) if notes.size() == 1 else "")
		if note == "":
			continue
		assert_eq(_right(ex).left(1), note.left(1), "%s: %s is %s" % [ex.id, note, _right(ex)])
		checked += 1
	assert_gte(checked, 8, "the bass clef was read")


## "A dotted minim lasts 3 beats" (a dot adds half the note), "a minim tied to a crotchet lasts 3 beats" (a tie adds them),
## and every "How many beats?" about a clef_stave picture's notes (this test's own beats).
func test_dots_and_ties_add_up() -> void:
	var checked := 0
	var dotted := RegEx.create_from_string("\\ba dotted (minim|crotchet|quaver) lasts ([\\d½¼¾.]+) beats?")
	var tied := RegEx.create_from_string("\\ban? (semibreve|minim|crotchet|quaver) tied to an? (semibreve|minim|crotchet|quaver) lasts ([\\d½¼¾.]+) beats?")
	for t in _subject_texts("music"):
		for m in dotted.search_all(t):
			assert_almost_eq(_beats_said(m.get_string(2)), float(BEATS[m.get_string(1)]) * 1.5, 0.001, t)
			checked += 1
		for m in tied.search_all(t):
			assert_almost_eq(_beats_said(m.get_string(3)), float(BEATS[m.get_string(1)]) + float(BEATS[m.get_string(2)]), 0.001, t)
			checked += 1
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or str(pic.get("kind", "")) != "clef_stave" \
				or not str(ex.prompt).to_lower().contains("how many beats"):
			continue
		var total := 0.0
		for v: Variant in pic.get("values", []):
			var name := str(v).trim_prefix("dotted ")
			total += float(BEATS[name]) * (1.5 if str(v).begins_with("dotted ") else 1.0)
		assert_almost_eq(NumberAnswer.value(str(ex.answer)), total, 0.001, "%s: %s" % [ex.id, ex.prompt])
		checked += 1
	assert_gte(checked, 6, "dots and ties were added up")


func _beats_said(s: String) -> float:
	var v := 0.0
	for ch in s:
		if ch.is_valid_int():
			v = v * 10 + int(ch)
	if s.contains("½"):
		v += 0.5
	if s.contains("¼"):
		v += 0.25
	if s.contains("¾"):
		v += 0.75
	if s.contains("."):
		v = float(s)
	return v


## "32 bars of 4 beats at 120 beats a minute last 64 seconds" (beats ÷ tempo × 60).
func test_the_tempo_sums_are_right() -> void:
	var rule := RegEx.create_from_string("(\\d+) bars of (\\d) beats at (\\d+) beats a minute (?:last|take|lasts) (\\d+) seconds")
	var checked := 0
	for t in _subject_texts("music"):
		for m in rule.search_all(t):
			var s := float(m.get_string(1)) * float(m.get_string(2)) * 60.0 / float(m.get_string(3))
			assert_almost_eq(float(m.get_string(4)), s, 0.001, t)
			checked += 1
	assert_gte(checked, 2, "tempo sums were checked")


## "Which part will you hear most?" about a mixer: the fader set highest; "Haydn wrote 104 symphonies".
func test_the_mix_and_the_symphonies_are_right() -> void:
	var checked := 0
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "mixer" \
				or not str(ex.prompt).to_lower().contains("most"):
			continue
		var best := ""
		var level := -1
		for f: Array in pic.faders:
			if int(f[1]) > level:
				level = int(f[1])
				best = str(f[0])
		assert_eq(_right(ex).to_lower(), best.to_lower(), "%s: %s" % [ex.id, ex.prompt])
		checked += 1
	var rule := RegEx.create_from_string("\\b(Haydn|Mozart|Beethoven) wrote (\\d+|nine) (?:numbered )?symphonies")
	for t in _subject_texts("music"):
		for m in rule.search_all(t):
			var n := 9 if m.get_string(2) == "nine" else int(m.get_string(2))
			assert_eq(n, int(SYMPHONIES[m.get_string(1)]), t)
			checked += 1
	assert_gte(checked, 5, "mixes and symphonies were checked")


## "Copy the rhythm": at most 8 boxes, starting with a clap you can hear, and the worked answer names the boxes.
func test_the_rhythms_to_copy_start_with_a_clap() -> void:
	var n := 0
	for ex in _exercises("music"):
		if str(ex.type) != "rhythm":
			continue
		n += 1
		var p := str(ex.sound.pattern)
		assert_true(p.begins_with("x") and p.length() <= 8, "%s: %s" % [ex.id, p])
		assert_true(str(ex.explain).contains("box"), "%s: the worked answer names the boxes" % ex.id)
	assert_gte(n, 3, "rhythms are copied")


## Ornaments: a trill (Baroque: from the note above, the two notes in turn), a mordent (the note, the one above, the
## note) and a turn (above, the note, below, the note): the choice that names the notes played is right.
func test_the_ornaments_are_played_right() -> void:
	var checked := 0
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "ornament_signs" \
				or not str(ex.prompt).to_lower().contains("notes"):
			continue
		var note := str(pic.note)
		var i := LETTERS.find(note.left(1))
		var up := LETTERS[(i + 1) % 7]
		var down := LETTERS[(i + 6) % 7]
		var n := note.left(1)
		var want := ""
		match str(pic.type):
			"trill":
				want = "%s %s %s %s" % [up, n, up, n]
			"mordent":
				want = "%s %s %s" % [n, up, n]
			"turn":
				want = "%s %s %s %s" % [up, n, down, n]
		assert_true(_right(ex).begins_with(want), "%s: a %s on %s plays %s, not %s" % [ex.id, pic.type, note, want, _right(ex)])
		checked += 1
	assert_gte(checked, 3, "ornaments were checked")
