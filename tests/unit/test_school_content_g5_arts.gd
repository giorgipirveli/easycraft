extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.5): grade 5's computing, art
## and design and music are written for every unit of the outline, building on grades 3 and 4. Each unit teaches with a
## lesson of 4 or more cards that opens with a memory question and ends with something to try in the world (research
## §5.3 rules 1 and 8), has at least 12 hand-written exercises at levels 1, 2 and 3 of at least two kinds, each with a
## hint (a strategy) and a worked answer, and rounds that vary and never show a hand-written exercise twice. The music
## units that teach listening let the child listen (a tune, chords or claps, SchoolSound) in at least 6 exercises each.
## The facts the lessons state are checked where a test can work them out: chords by their semitones, major and minor
## heard by the third above the home note, scales by their tones and semitones, a stave's notes by their letters, beats
## by the notes, how many times a line of code runs (loops inside loops, procedures), a spreadsheet's formulas, the
## composers' years, the robot's programs by RobotCheck. (Every exercise's validity, answers, pictures and words are the
## shared content test's, test_school_content.gd.)

const GRADE := 5
const SUBJECTS: Array[String] = ["computing", "art", "music"]
const UNITS := {"computing": 11, "art": 9, "music": 9}   # research §6.5
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## Music units that teach listening, and the sounds they must use: "rhythm" (claps), "notes" (a tune or chords) or "any".
## great_composers is taught in words, years and a few tunes.
const LISTENING := {"g5.music.major_minor": "notes", "g5.music.chords": "notes", "g5.music.song_structure": "notes",
	"g5.music.write_a_song": "any", "g5.music.world_rhythms": "rhythm", "g5.music.read_melodies": "notes",
	"g5.music.playing_together": "any", "g5.music.music_tech": "any"}
const MIN_SOUNDS := 6
## Semitones above C of each letter (this test's own).
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const MAJOR_SCALE: Array[int] = [2, 2, 1, 2, 2, 2, 1]
const MINOR_SCALE: Array[int] = [2, 1, 2, 2, 1, 2, 2]
const NOTE_BEATS := {"semibreve": 4.0, "dotted minim": 3.0, "minim": 2.0, "crotchet": 1.0, "quaver": 0.5,
	"quavers": 1.0, "rest": 1.0}
## The composers' years (this test's own; every "Name (born-died)" and lifespans picture must agree).
const COMPOSERS := {"Vivaldi": [1678, 1741], "Bach": [1685, 1750], "Handel": [1685, 1759], "Haydn": [1732, 1809],
	"Mozart": [1756, 1791], "Beethoven": [1770, 1827]}


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


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 5 %s" % subject)


func test_grade_5_computing_art_music_are_written_for_every_unit() -> void:
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
	gut.p("%d hand-written exercises in grade 5 computing, art and music" % exercises)


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from earlier) and "Do it in the world" (a challenge to try).
func test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		assert_true(str(cards[0].text).contains("?"), "%s: the first card asks a memory question" % id)
		assert_true(str(cards[-1].text).to_lower().contains("world"), "%s: the last card is something to try in the world" % id)


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


## The generators these units use are their own ("g5a"), each exists, and every one of them is used here.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with("g5a."), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	assert_gt(used.size(), 0, "the units practise with generators")
	for gen in SchoolGen.ids():
		if gen.begins_with("g5a."):
			assert_true(used.has(gen), "%s is used by a grade 5 computing, art or music unit" % gen)


# --- Music facts -----------------------------------------------------------------------------------------------------

## A note's pitch in semitones ("C4" = 48, "Eb4" = 51, "F#3" = 42); -1 for a rest or anything else.
func _pitch(note: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([#b]?)([2-6])$").search(note.split(":")[0])
	if m == null:
		return -1
	var s := int(SEMIS[m.get_string(1)]) + (1 if m.get_string(2) == "#" else -1 if m.get_string(2) == "b" else 0)
	return 12 * int(m.get_string(3)) + s


## "major", "minor" or "" for three letters in root position (root, third, fifth).
func _quality(root: String, third: String, fifth: String) -> String:
	var t := posmod(int(SEMIS[third]) - int(SEMIS[root]), 12)
	var f := posmod(int(SEMIS[fifth]) - int(SEMIS[root]), 12)
	if f != 7:
		return ""
	return "major" if t == 4 else ("minor" if t == 3 else "")


## Every "the C major chord is C, E and G" the lessons state is built by semitones: a major chord's third is 4
## semitones above its root, a minor chord's 3, and the fifth 7; every named chord on a chord stave is its notes.
func test_the_chords_are_built_right() -> void:
	var rule := RegEx.create_from_string("\\b([A-G]) (major|minor) chord is ([A-G]), ([A-G]) and ([A-G])\\b")
	var checked := 0
	for u in Curriculum.units(GRADE, "music"):
		if not Curriculum.has_content(str(u.id)):
			continue
		for t in _texts(str(u.id)):
			for m in rule.search_all(t):
				assert_eq(m.get_string(3), m.get_string(1), "%s: a chord starts on its root: %s" % [u.id, t])
				assert_eq(_quality(m.get_string(3), m.get_string(4), m.get_string(5)), m.get_string(2), "%s: %s" % [u.id, t])
				checked += 1
	for p in _pictures("music"):
		if str(p.kind) != "chord_stave" or not p.has("names"):
			continue
		for i in (p.chords as Array).size():
			var name := str(p.names[i])
			var notes: Array = p.chords[i]
			var letters: Array[String] = []
			for n: String in notes:
				letters.append(n.left(1))
			assert_eq(letters[0], name.left(1), "%s: the root is the lowest note" % name)
			assert_eq(_quality(letters[0], letters[1], letters[2]), "minor" if name.ends_with("m") else "major", "%s: %s" % [name, notes])
			checked += 1
	assert_gte(checked, 8, "chords were checked")


## "Major or minor?" by ear: the right choice is what the sound is. A chord ("C4+E4+G4") is major when its third is 4
## semitones above its lowest note, minor when 3; a tune starts on its home note and is major when it has the note 4
## semitones above it, minor when it has the note 3 above (never both).
func test_major_and_minor_are_heard_right() -> void:
	var heard := 0
	for ex in _exercises("music"):
		if str(ex.type) != "choice" or not ex.get("sound") is Dictionary or str(ex.sound.kind) != "notes":
			continue
		var words: Array[String] = []
		for c: Variant in ex.choices:
			words.append(ExerciseCheck.item_text(c).to_lower())
		if not (words.has("major") and words.has("minor")):
			continue
		var notes: Array = ex.sound.notes
		var first := str(notes[0]).split(":")[0]
		var quality := ""
		if first.contains("+"):
			var parts := first.split("+")
			var third := posmod(_pitch(parts[1]) - _pitch(parts[0]), 12)
			quality = "major" if third == 4 else ("minor" if third == 3 else "")
		else:
			var home := posmod(_pitch(first), 12)
			var classes := {}
			for n: String in notes:
				for part in n.split(":")[0].split("+"):
					if _pitch(part) >= 0:
						classes[posmod(_pitch(part) - home, 12)] = true
			assert_false(classes.has(3) and classes.has(4), "%s: a tune is major or minor, not both" % ex.id)
			quality = "major" if classes.has(4) else ("minor" if classes.has(3) else "")
		assert_ne(quality, "", "%s: the sound has a third" % ex.id)
		assert_eq(words[int(ex.answer)], quality, "%s: %s" % [ex.id, notes])
		heard += 1
	assert_gte(heard, 6, "major and minor were heard")


## A keyboard with a marked scale of eight notes (home to home) goes up by the major scale's tones and semitones (T T S
## T T T S) or the natural minor's (T S T T S T T); a scale the lessons call major is the major one.
func test_the_scales_go_up_by_tones_and_semitones() -> void:
	var scales := 0
	for p in _pictures("music"):
		if str(p.kind) != "keyboard" or (p.get("mark", []) as Array).size() != 8:
			continue
		var steps: Array[int] = []
		for i in 7:
			steps.append(_pitch(str(p.mark[i + 1])) - _pitch(str(p.mark[i])))
		assert_true(steps == MAJOR_SCALE or steps == MINOR_SCALE, "%s: steps %s" % [p.mark, steps])
		if str(p.get("scale", "")) == "major":
			assert_eq(steps, MAJOR_SCALE, "%s: a major scale" % [p.mark])
		elif str(p.get("scale", "")) == "minor":
			assert_eq(steps, MINOR_SCALE, "%s: a natural minor scale" % [p.mark])
		scales += 1
	assert_gte(scales, 3, "scales were checked")


## A choice read from a stave ("Which notes are these?"): the right choice is the notes' letters, and no other is.
func test_the_stave_notes_are_read_right() -> void:
	var read := 0
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "stave":
			continue
		var letters := ""
		for n: String in pic.notes:
			letters += n.left(1)
		for i in (ex.choices as Array).size():
			var c := ExerciseCheck.item_text(ex.choices[i]).replace(" ", "")
			if not RegEx.create_from_string("^[A-G]+$").search(c):
				continue
			assert_eq(c == letters, i == int(ex.answer), "%s: %s on the stave, choice %s" % [ex.id, letters, c])
			read += 1
	assert_gte(read, 8, "stave notes were read")


## "How many beats…?" about written notes (a stave with values, or a rhythm): the notes' beats (semibreve 4, dotted
## minim 3, minim 2, crotchet 1, quaver ½, two quavers 1, a crotchet rest 1).
func test_the_beats_are_counted_right() -> void:
	var counted := 0
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or not str(ex.prompt).to_lower().contains("how many beats"):
			continue
		var beats := 0.0
		if str(pic.kind) == "stave":
			for i in (pic.notes as Array).size():
				beats += float(NOTE_BEATS[str(pic.values[i]) if pic.has("values") else "crotchet"])
		elif str(pic.kind) == "notation":
			for b: String in pic.beats:
				beats += float(NOTE_BEATS[b])
		else:
			continue
		assert_eq(NumberAnswer.value(str(ex.answer)), beats, "%s: %s" % [ex.id, ex.prompt])
		counted += 1
	assert_gte(counted, 4, "beats were counted")


## Every "Bach (1685-1750)" and every lifespans picture has the composer's real years.
func test_the_composers_years_are_right() -> void:
	var rule := RegEx.create_from_string("\\b(Vivaldi|Bach|Handel|Haydn|Mozart|Beethoven) \\((\\d{4})-(\\d{4})\\)")
	var born := RegEx.create_from_string("\\b(Vivaldi|Bach|Handel|Haydn|Mozart|Beethoven) was born in (\\d{4})")
	var checked := 0
	for u in Curriculum.units(GRADE, "music"):
		if not Curriculum.has_content(str(u.id)):
			continue
		for t in _texts(str(u.id)):
			for m in rule.search_all(t):
				assert_eq([int(m.get_string(2)), int(m.get_string(3))], COMPOSERS[m.get_string(1)], "%s: %s" % [u.id, t])
				checked += 1
			for m in born.search_all(t):
				assert_eq(int(m.get_string(2)), int(COMPOSERS[m.get_string(1)][0]), "%s: %s" % [u.id, t])
				checked += 1
	for p in _pictures("music"):
		if str(p.kind) != "lifespans":
			continue
		for row: Array in p.people:
			var who := str(row[0]).get_slice(" ", str(row[0]).get_slice_count(" ") - 1)
			if COMPOSERS.has(who):
				assert_eq([int(row[1]), int(row[2])], COMPOSERS[who], "the lifespans picture: %s" % [row])
				checked += 1
	assert_gte(checked, 6, "the composers' years were checked")


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
	assert_gte(n, 4, "world rhythms copy rhythms")


# --- Computing facts -------------------------------------------------------------------------------------------------

## How many times the line at `mark` runs: a small interpreter for the code pictures' loops and procedures (REPEAT n
## TIMES and REPEAT n with their inner lines; DEFINE name, whose lines run only when a line calls it by its name).
func _times_run(lines: Array, mark: int) -> int:
	var procs := {}
	for i in lines.size():
		var t := str(lines[i]).strip_edges()
		if t.begins_with("DEFINE "):
			procs[t.substr(7)] = i
	var count := [0]
	var top: Array[int] = []
	for i in lines.size():
		if _depth(str(lines[i])) == 0:
			top.append(i)
	_run_lines(lines, top, mark, procs, count, 0)
	return count[0]


func _depth(line: String) -> int:
	return int((line.length() - line.lstrip(" ").length()) / 2.0)


func _inner(lines: Array, at: int) -> Array[int]:
	var out: Array[int] = []
	var d := _depth(str(lines[at]))
	for j in range(at + 1, lines.size()):
		if _depth(str(lines[j])) <= d:
			break
		if _depth(str(lines[j])) == d + 1:
			out.append(j)
	return out


func _run_lines(lines: Array, which: Array[int], mark: int, procs: Dictionary, count: Array, calls: int) -> void:
	if calls > 50:
		return
	for i in which:
		var t := str(lines[i]).strip_edges()
		if i == mark:
			count[0] += 1
		if t.begins_with("DEFINE "):
			continue
		if t.begins_with("REPEAT "):
			for k in int(t.get_slice(" ", 1)):
				_run_lines(lines, _inner(lines, i), mark, procs, count, calls)
		elif procs.has(t):
			_run_lines(lines, _inner(lines, int(procs[t])), mark, procs, count, calls + 1)


func test_the_interpreter_counts_loops_and_calls() -> void:
	var lines := ["DEFINE hop", "  JUMP", "  CLAP", "REPEAT 3 TIMES", "  REPEAT 2 TIMES", "    hop", "  SPIN", "hop"]
	assert_eq(_times_run(lines, 1), 7, "hop runs 3 × 2 + 1 = 7 times")
	assert_eq(_times_run(lines, 6), 3, "SPIN runs once each time round the outer loop")
	assert_eq(_times_run(lines, 5), 6)


## "How many times does the marked line run?" (loops inside loops, procedures): worked out by running the code.
func test_the_loops_and_procedures_are_counted_right() -> void:
	var counted := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or str(pic.get("kind", "")) != "code" or not pic.has("mark") \
				or not str(ex.prompt).to_lower().contains("how many times"):
			continue
		assert_eq(NumberAnswer.value(str(ex.answer)), float(_times_run(pic.lines, int(pic.mark))), "%s: %s" % [ex.id, ex.prompt])
		counted += 1
	assert_gte(counted, 6, "loops and procedures were counted")


## A cell's value in a spreadsheet picture (this test's own): a number, =SUM(B2:B5), =MAX(…), =MIN(…), or =B2+C2,
## =B2-C2, =B2*C2 with cells or numbers.
func _cell(p: Dictionary, ref: String, depth: int = 0) -> float:
	var col := ref.unicode_at(0) - "A".unicode_at(0)
	var row := int(ref.substr(1)) - 1
	var rows: Array = p.cells
	if depth > 20 or row < 0 or row >= rows.size() or col < 0 or col >= (rows[row] as Array).size():
		return NAN
	var t := str(rows[row][col]).strip_edges()
	if not t.begins_with("="):
		return float(t) if t.is_valid_float() else NAN
	var f := t.substr(1)
	var fn := RegEx.create_from_string("^(SUM|MAX|MIN)\\(([A-E])(\\d+):([A-E])(\\d+)\\)$").search(f)
	if fn != null:
		var values: Array[float] = []
		for c in range(fn.get_string(2).unicode_at(0), fn.get_string(4).unicode_at(0) + 1):
			for r in range(int(fn.get_string(3)), int(fn.get_string(5)) + 1):
				values.append(_cell(p, String.chr(c) + str(r), depth + 1))
		match fn.get_string(1):
			"SUM":
				var s := 0.0
				for v in values:
					s += v
				return s
			"MAX":
				return values.max()
			"MIN":
				return values.min()
	var op := RegEx.create_from_string("^([A-E]\\d+|\\d+)([+*-])([A-E]\\d+|\\d+)$").search(f)
	if op != null:
		var a := _term(p, op.get_string(1), depth)
		var b := _term(p, op.get_string(3), depth)
		return a + b if op.get_string(2) == "+" else (a - b if op.get_string(2) == "-" else a * b)
	return NAN


func _term(p: Dictionary, t: String, depth: int) -> float:
	return float(t) if t.is_valid_int() else _cell(p, t, depth + 1)


## "What does B5 show?" about a spreadsheet: its formula worked out (a sum, a biggest, a smallest, a sum of two cells).
func test_the_spreadsheet_formulas_are_worked_out() -> void:
	var cell := RegEx.create_from_string("\\b(?:does|will) ([A-E]\\d+) show")
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or str(pic.get("kind", "")) != "sheet":
			continue
		var m := cell.search(str(ex.prompt))
		if m == null:
			continue
		assert_eq(NumberAnswer.value(str(ex.answer)), _cell(pic, m.get_string(1)), "%s: %s" % [ex.id, ex.prompt])
		checked += 1
	assert_gte(checked, 4, "spreadsheet formulas were worked out")


## "FORWARD 2, TURN RIGHT, FORWARD" as RobotCheck's commands ([] when the text is not a program).
func _program(text: String) -> Array:
	var out: Array = []
	for part in text.split(", "):
		var w := part.strip_edges()
		if w == "TURN LEFT" or w == "TURN RIGHT":
			out.append("L" if w == "TURN LEFT" else "R")
		elif w == "FORWARD":
			out.append("F")
		elif w.begins_with("FORWARD ") and w.substr(8).is_valid_int() and int(w.substr(8)) >= 2:
			for i in int(w.substr(8)):
				out.append("F")
		else:
			return []
	return out


## The robot's facts are run, not trusted: every "code the robot" worked answer reaches the flag within its `max`, and
## in every choice of programs on a board only the right one does (RobotCheck).
func test_the_robot_programs_do_what_the_lessons_say() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		if str(ex.type) == "robot":
			var said := _program(str(ex.explain).get_slice(": ", 1).trim_suffix("."))
			assert_true(RobotCheck.reaches(ex.board, said), "%s: %s" % [ex.id, ex.explain])
			if ex.has("max"):
				assert_lte(said.size(), int(ex.max), "%s: the worked answer fits max" % ex.id)
			checked += 1
		elif str(ex.type) == "choice" and ex.get("picture", {}).get("kind", "") == "robot" and ex.picture.has("goal"):
			var b: Dictionary = ex.picture
			for i in (ex.choices as Array).size():
				var p := _program(str(ex.choices[i]))
				if p.is_empty():
					continue
				assert_eq(RobotCheck.reaches(b, p), i == int(ex.answer), "%s: %s" % [ex.id, ex.choices[i]])
				checked += 1
	assert_gte(checked, 4, "the robot programs were run")


## Research §5.4 rule 6: online safety every grade, and never ask a child for personal details.
func test_the_lessons_never_ask_for_personal_details() -> void:
	var ask := RegEx.create_from_string("(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)")
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			assert_null(ask.search(str(ex.prompt).to_lower()), "%s asks: %s" % [ex.id, ex.prompt])
