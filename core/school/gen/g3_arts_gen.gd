class_name G3ArtsGen
extends RefCounted
## Owner #70 and #73 (research §6.3): grade 3 computing, art and music generators: SchoolGen "g3a.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a
## strategy), a worked answer and `data` (tests/unit/test_g3_arts_gen.gd works every answer out again).
## - Music (listening: a SchoolSound on the exercise): count_claps, which_rhythm, claps_in_rhythm, copy_rhythm (the
##   "rhythm" type: mark the boxes that clap), higher_lower, tune_direction, faster_slower. A rhythm never starts with a rest (a rest before the first clap can't be heard).
## - Art: mix_colour (primaries make secondaries; white makes a tint, black a shade; all three make brown), mix_paint
##   (the "mix" type: drops of paint in a bowl),
##   next_in_pattern (every item of a pattern differs in shape as well as colour: never colour alone, spec §5.15).
## - Computing (RobotCheck's robot: FORWARD one square the way it faces, TURN LEFT and TURN RIGHT a quarter turn;
##   pictures are SchoolPictureArts "robot" boards): robot_moves, code_robot (the "code the robot" type), loop_count,
##   fix_the_bug. Wrong programs are checked by running them (RobotCheck.reaches).

const K := preload("res://core/school/gen/gen_kit.gd")
const CLAPS := {"crotchet": "x-", "quavers": "xx", "rest": "--"}
const WORDS := {"crotchet": "ta", "quavers": "ti-ti", "rest": "rest"}
const CLAP_COUNT := {"crotchet": 1, "quavers": 2, "rest": 0}
const NOTE_NAMES: Array[String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const LOW := 53                   # F3: the lowest note asked about (phone speakers play it well enough)
const HIGH := 84                  # C6
## The notes tunes move on (C major, C4 to E5).
const SCALE: Array[String] = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5"]
const SHAPES: Array[String] = ["up", "down", "up, then down", "down, then up"]
const SECONDARY := {"red+yellow": "orange", "yellow+blue": "green", "blue+red": "purple"}
const TINT := {"red": "pink", "blue": "light blue", "green": "light green", "purple": "lilac", "yellow": "cream",
	"orange": "light orange"}
## Yellow is left out: yellow with black turns a greenish olive, not a darker yellow.
const SHADE := {"red": "dark red", "blue": "dark blue", "green": "dark green", "purple": "dark purple",
	"orange": "dark orange"}
## Pattern pieces: a colour and a shape each; the pieces of one pattern differ in both.
const PIECES: Array[String] = ["red circle", "blue square", "yellow triangle", "green circle", "purple square",
	"orange triangle"]
const NUMBER_WORDS: Array[String] = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]


# --- Music -----------------------------------------------------------------------------------------------------------

static func count_claps(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var beats := _rhythm(rng, 8 if level == 3 else 4, level)
	var pattern := _pattern(beats)
	var n := pattern.count("x")
	var ex := K.number("Listen. How many claps do you hear?", n,
		"Tap your knee once for every clap as you listen. You can play it again as often as you like.",
		"You heard %s. That is %d claps: ta is one clap, ti-ti is two quick claps and a rest is none." % [_words(beats), n])
	ex.sound = {"kind": "rhythm", "pattern": pattern, "tempo": [80, 90, 100][level - 1]}
	ex.data = {"beats": beats}
	return ex


static func which_rhythm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var right := _rhythm(rng, 4, 2)
	var wrongs: Array = []
	var tries := 0
	while wrongs.size() < (2 if level == 1 else 3) and tries < 300:
		tries += 1
		var w: Array = _changed(rng, right) if level == 3 and wrongs.size() < 2 else _rhythm(rng, 4, 2)
		if _distance(w, right) < (2 if level == 1 else 1) or wrongs.has(w):
			continue
		wrongs.append(w)
	var pic := func(b: Array) -> Dictionary:
		return {"picture": {"kind": "notation", "beats": b, "words": level < 3}}
	var ex := K.choice(rng, "Listen. Which rhythm did you hear?", pic.call(right), wrongs.map(pic),
		"Say it along as you listen: ta for one clap on a beat, ti-ti for two quick claps, and stay quiet for a rest.",
		"You heard %s." % _words(right))
	ex.sound = {"kind": "rhythm", "pattern": _pattern(right), "tempo": 80 if level == 1 else 90}
	ex.data = {"beats": right}
	return ex


static func claps_in_rhythm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var beats := _rhythm(rng, 8 if level == 3 else 4, maxi(level, 2))
	var parts: Array[String] = []
	var n := 0
	for b: Variant in beats:
		parts.append(str(CLAP_COUNT[str(b)]))
		n += int(CLAP_COUNT[str(b)])
	var picture := {"kind": "notation", "beats": beats, "words": level == 1, "bars": level == 3}
	var ex := K.number("How many claps does this rhythm have?", n,
		"A crotchet (ta) is one clap. Two joined quavers (ti-ti) are two claps. A rest is no clap at all.",
		"%s: %s = %d claps." % [_words(beats), " + ".join(parts), n], picture)
	ex.data = {"beats": beats}
	return ex


## "Copy the rhythm" (the "rhythm" type): hear it, mark the boxes that clap. Each beat is two boxes (the pattern's
## half beats): ta claps the first, ti-ti both, a rest neither. Level 1: 2 beats, level 2: 3, level 3: 4 (8 boxes).
static func copy_rhythm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var beats := _rhythm(rng, level + 1, 3 if level == 3 else 2)
	var pattern := _pattern(beats)
	var boxes: Array[String] = []
	for i in pattern.length():
		if pattern[i] == "x":
			boxes.append(str(i + 1))
	var where := boxes[0] if boxes.size() == 1 else "%s and %s" % [", ".join(boxes.slice(0, -1)), boxes[-1]]
	var ex := {"type": "rhythm", "prompt": "Listen, then copy the rhythm: tap each box where you hear a clap.",
		"hint": "Each beat has two boxes. ta: a clap in the first box. ti-ti: claps in both. A rest: no clap at all.",
		"explain": "You heard %s: claps in boxes %s." % [_words(beats), where],
		"sound": {"kind": "rhythm", "pattern": pattern, "tempo": [70, 75, 80][level - 1]}}
	ex.data = {"beats": beats}
	return ex


static func higher_lower(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var gap: int = [rng.randi_range(7, 12), rng.randi_range(3, 6), rng.randi_range(0, 2)][level - 1]
	var up := rng.randi() % 2 == 0
	var first := rng.randi_range(LOW, HIGH - gap) if up else rng.randi_range(LOW + gap, HIGH)
	var second := first + gap if up else first - gap
	var a := _note_name(first)
	var b := _note_name(second)
	var right := "the same" if gap == 0 else "higher" if up else "lower"
	var how := "a big jump" if gap >= 7 else "a jump" if gap >= 3 else "a small step"
	var explain := "Both notes were the same: the tune stayed still." if gap == 0 else \
		"The second note was %s: %s %s from the first." % [right, how, "up" if up else "down"]
	var wrongs: Array = ["lower" if right == "higher" else "higher"]
	if level == 3:
		wrongs = ["higher", "lower", "the same"].filter(func(w: String) -> bool: return w != right)
	var ex := K.choice(rng, "Listen to two notes. Is the second note higher or lower than the first?" if level < 3 else
		"Listen to two notes. Is the second note higher, lower or the same as the first?", right, wrongs,
		"Hum the first note, then the second. Does your voice go up, go down or stay where it is?", explain)
	ex.sound = {"kind": "notes", "notes": [a + ":2", "-", b + ":2"]}
	ex.data = {"first": a, "second": b}
	return ex


static func tune_direction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(4, 5) if level == 1 else rng.randi_range(5, 7)
	var shape: String = SHAPES[rng.randi_range(0, 1 if level == 1 else 3)]
	var notes := _tune(rng, shape, n)
	var hint := "Draw the tune in the air with your finger as you listen: up for a higher note, down for a lower one."
	var explain: String = {"up": "Each note is higher than the one before: the tune climbs like stairs.",
		"down": "Each note is lower than the one before: the tune goes down like stairs.",
		"up, then down": "The notes climb to a high note, then come back down, like a hill.",
		"down, then up": "The notes go down to a low note, then climb back up, like a valley."}[shape]
	var ex: Dictionary
	if level < 3:
		var wrongs: Array = SHAPES.slice(0, 2 if level == 1 else 4).filter(func(s: String) -> bool: return s != shape)
		ex = K.choice(rng, "Listen. Which way does the tune go?", shape, wrongs, hint, explain)
	else:
		var wrongs: Array = []
		for s: String in SHAPES:
			if s != shape:
				wrongs.append({"picture": {"kind": "melody", "notes": _tune(rng, s, n)}})
		ex = K.choice(rng, "Listen. Which picture shows the shape of the tune?", {"picture": {"kind": "melody",
			"notes": notes}}, wrongs, hint, explain)
	ex.sound = {"kind": "notes", "notes": notes}
	ex.data = {"shape": shape}
	return ex


static func faster_slower(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kinds: Array[String] = ["faster", "slower"]
	if level == 3:
		kinds.append("stay the same")
	var trend: String = kinds[rng.randi_range(0, kinds.size() - 1)]
	var gaps: Array = []   # half beats from one clap to the next
	if trend == "stay the same":
		var g := rng.randi_range(1, 3)
		for i in rng.randi_range(6, 8 if g < 3 else 7):
			gaps.append(g)
	else:
		var top := 4 if level == 1 else rng.randi_range(3, 4)
		var bottom := 1 if level == 1 else top - 2
		for g in range(top, bottom - 1, -1):
			for i in (rng.randi_range(2, 3) if g > 1 else 3):
				gaps.append(g)
		while _sum(gaps) + 1 > 26:
			gaps.remove_at(gaps.size() / 2)
		if trend == "slower":
			gaps.reverse()
	var pattern := "x"
	for g: Variant in gaps:
		pattern += "-".repeat(int(g) - 1) + "x"
	var explain: String = {"faster": "The gaps between the claps get shorter, so the claps get faster.",
		"slower": "The gaps between the claps get longer, so the claps get slower.",
		"stay the same": "Every gap between the claps is the same, so the speed stays the same: a steady beat."}[trend]
	var ex := K.choice(rng, "Listen. Do the claps get faster or slower?" if level < 3 else
		"Listen. Do the claps get faster, get slower or stay the same?", trend,
		kinds.filter(func(k: String) -> bool: return k != trend),
		"Listen to the gaps between the claps. Shorter gaps mean faster; longer gaps mean slower.", explain)
	ex.sound = {"kind": "rhythm", "pattern": pattern, "tempo": 110}
	ex.data = {"gaps": gaps}
	return ex


# --- Art -------------------------------------------------------------------------------------------------------------

static func mix_colour(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pairs: Array = SECONDARY.keys()
	var ex: Dictionary
	var d := {}
	var kind := 0 if level == 1 else rng.randi_range(1, 2) if level == 2 else rng.randi_range(3, 5)
	match kind:
		0, 5:   # two primaries: what do they make? (level 3: choose the patch)
			var pair: PackedStringArray = str(pairs[rng.randi_range(0, 2)]).split("+")
			if rng.randi() % 2 == 0:
				pair.reverse()
			var made := str(SECONDARY[pair[0] + "+" + pair[1]] if SECONDARY.has(pair[0] + "+" + pair[1]) else
				SECONDARY[pair[1] + "+" + pair[0]])
			d = {"a": pair[0], "b": pair[1], "made": made, "ask": "made"}
			var others: Array = ["orange", "green", "purple", "brown"].filter(func(c: String) -> bool: return c != made)
			var prompt := "Mix %s paint and %s paint. What colour do you make?" % [pair[0], pair[1]]
			var hint := "Red and yellow make orange, yellow and blue make green, blue and red make purple."
			if kind == 0:
				hint = "Picture the two paints swirling together. Which colour sits between them on the colour wheel?"
			var explain := "%s and %s make %s, a secondary colour." % [_cap(pair[0]), pair[1], made]
			var pic := {"kind": "swatches", "items": [pair[0], "+", pair[1], "=", "?"]}
			if kind == 0:
				ex = K.choice(rng, prompt, made, others.slice(0, 2 + rng.randi_range(0, 1)), hint, explain, pic)
			else:
				var patch := func(c: String) -> Dictionary: return {"picture": {"kind": "swatches", "items": [c],
					"names": false}}
				ex = K.choice(rng, "Mix %s paint and %s paint. Which patch shows the colour you make?" % [pair[0],
					pair[1]], patch.call(made), others.map(patch), hint, explain, pic)
		1:   # which two primaries make it?
			var key := str(pairs[rng.randi_range(0, 2)])
			var pair := key.split("+")
			var made := str(SECONDARY[key])
			d = {"a": pair[0], "b": pair[1], "made": made, "ask": "pair"}
			var wrongs: Array = []
			for k: Variant in pairs:
				if str(k) != key:
					wrongs.append("%s and %s" % Array(str(k).split("+")))
			ex = K.choice(rng, "Which two primary colours mix to make %s?" % made, "%s and %s" % [pair[0], pair[1]],
				wrongs, "The primary colours are red, yellow and blue. On a colour wheel, %s sits between the two that make it." % made,
				"%s and %s make %s." % [_cap(pair[0]), pair[1], made],
				{"kind": "swatches", "items": ["?", "+", "?", "=", made]})
		2:   # a colour with white or black: what do you make?
			var white := rng.randi() % 2 == 0
			var pool: Array = (TINT if white else SHADE).keys()
			var base := str(pool[rng.randi_range(0, pool.size() - 1)])
			var made := str(TINT[base] if white else SHADE[base])
			var add := "white" if white else "black"
			d = {"a": base, "b": add, "made": made, "ask": "made"}
			var wrongs: Array = [base, str(SHADE.get(base, "grey")) if white else str(TINT[base]), "brown" if white else "grey"]
			ex = K.choice(rng, "Mix %s paint with a little %s. What colour do you make?" % [base, add], made, wrongs,
				"White makes a colour lighter. Black makes it darker.",
				"%s with white makes %s, a tint of %s." % [_cap(base), made, base] if white else
				"%s with black makes %s, a shade of %s." % [_cap(base), made, base],
				{"kind": "swatches", "items": [base, "+", add, "=", "?"]})
		3:   # what do you add to make a tint or a shade?
			var white := rng.randi() % 2 == 0
			var pool: Array = (TINT if white else SHADE).keys()
			var base := str(pool[rng.randi_range(0, pool.size() - 1)])
			var made := str(TINT[base] if white else SHADE[base])
			var add := "white" if white else "black"
			d = {"a": base, "b": add, "made": made, "ask": "add"}
			var wrongs: Array = ["black" if white else "white"]
			for c: String in ["yellow", "blue", "red"]:
				if c != base and wrongs.size() < 3:
					wrongs.append(c)
			ex = K.choice(rng, "What do you mix into %s paint to make %s?" % [base, made], add, wrongs,
				"Is the new colour lighter or darker than %s? Lighter needs white; darker needs black." % base,
				"%s is %s than %s, so you add %s: %s is a %s of %s." % [_cap(made), "lighter" if white else "darker",
					base, add, made, "tint" if white else "shade", base],
				{"kind": "swatches", "items": [base, "+", "?", "=", made]})
		4:   # all three primaries
			d = {"a": "all three", "b": "", "made": "brown", "ask": "made"}
			ex = K.choice(rng, "What colour do you make if you mix red, yellow and blue paint all together?", "brown",
				["white", "orange", "purple"], "Each new colour you mix in makes the paint darker and muddier.",
				"All three primary colours together make a muddy brown.",
				{"kind": "swatches", "items": ["red", "+", "yellow", "+", "blue", "=", "?"]})
	ex.data = d
	return ex


## "Mix the colour" (the "mix" type, ColourMix): level 1 a secondary colour, level 2 a tint or a shade of one paint,
## level 3 a colour of three paints (brown, a tint or a shade of a secondary, grey).
static func mix_paint(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var targets: Array = [["orange", "green", "purple"], ["pink", "light blue", "cream", "dark red", "dark blue"],
		["brown", "light green", "lilac", "dark green", "grey"]][level - 1]
	var target: String = targets[rng.randi_range(0, targets.size() - 1)]
	var recipe: Dictionary = ColourMix.RECIPES[target]
	var hint := "Which primary colours make it? Does it need white to make it lighter, or black to make it darker?"
	if level == 1:
		hint = "Which two primary colours sit either side of %s on the colour wheel?" % target
	var ex := {"type": "mix", "target": target,
		"prompt": "Mix %s in the bowl: tap the paint pots to add drops." % target, "hint": hint,
		"explain": "%s is %s. Twice as much of each makes the same colour." % [_cap(target), ColourMix.words(recipe)]}
	ex.data = {"target": target}
	return ex


static func next_in_pattern(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var units: Array = [[[0, 1]], [[0, 1, 1], [0, 0, 1], [0, 1, 2]], [[0, 1, 2, 1], [0, 0, 1, 1], [0, 1, 0, 2],
		[0, 1, 1, 2]]][level - 1]
	var shape: Array = units[rng.randi_range(0, units.size() - 1)]
	var pieces: Array = PIECES.duplicate()
	K.shuffle(rng, pieces)
	var chosen: Array = []   # one piece of each shape: never colour alone
	var shapes := {}
	for p: Variant in pieces:
		var shape_of := str(p).get_slice(" ", 1)
		if not shapes.has(shape_of):
			shapes[shape_of] = true
			chosen.append(p)
	var unit: Array = []
	for i: Variant in shape:
		unit.append(chosen[int(i)])
	var count := rng.randi_range(4, 6) if level == 1 else rng.randi_range(unit.size() + 2, 7)
	var shown: Array = []
	for i in count:
		shown.append(unit[i % unit.size()])
	var next: String = unit[count % unit.size()]
	var patch := func(c: Variant) -> Dictionary: return {"picture": {"kind": "swatches", "items": [c]}}
	var wrongs: Array = []
	for c: Variant in chosen.slice(0, 3):
		if str(c) != next and wrongs.size() < 2:
			wrongs.append(patch.call(c))
	var distinct: Array = []
	for u: Variant in unit:
		if not distinct.has(u):
			distinct.append(u)
	var ex := K.choice(rng, "What comes next in the pattern?", patch.call(next), wrongs,
		"Find the part that repeats. Say the pattern out loud as you point, and keep going past the end.",
		"The part that repeats is: %s. So after the last one comes %s." % [", ".join(unit), next],
		{"kind": "swatches", "items": shown + ["?"], "names": false})
	ex.data = {"unit": unit}
	return ex


# --- Computing -------------------------------------------------------------------------------------------------------
## The robot is RobotCheck's (the "code the robot" type): "F" one square forward the way it faces, "L" and "R" a
## quarter turn where it stands. In words a run of FORWARDs is written short, "FORWARD 3" for three, as the lessons
## teach ("FORWARD 3 is short for FORWARD, FORWARD, FORWARD").

static func robot_moves(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var board := {}
	var right: Array[String] = []
	for _try in 120:
		board = _board(rng, level)
		right = RobotCheck.shortest(board)
		if right.size() >= 2 and _said(right).length() <= ExerciseCheck.MAX_CHOICE and _turns(right) >= [0, 1, 2][level - 1]:
			break
	var wrongs: Array = []
	for w: Array in _near_programs(rng, right):
		var text := _said(w)
		if wrongs.size() < 3 and text.length() <= ExerciseCheck.MAX_CHOICE and not wrongs.has(text) \
				and text != _said(right) and not RobotCheck.reaches(board, w):
			wrongs.append(text)
	var ex := K.choice(rng, "Which program takes the robot to the flag?" if not board.has("walls") else
		"Which program takes the robot to the flag without bumping into a wall?", _said(right), wrongs,
		"First see which way the robot faces. Then follow each program with your finger, one step at a time.",
		"%s: %s, and the robot is on the flag." % [_said(right), _told(right)], _picture(board))
	ex.data = {"board": board}
	return ex


## "Code the robot": the child writes the program (RobotAnswer); level 3 asks for a shortest one.
static func code_robot(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var board := {}
	var best: Array[String] = []
	for _try in 120:
		board = _board(rng, level, level >= 2)
		best = RobotCheck.shortest(board)
		if best.size() >= [2, 4, 6][level - 1]:
			break
	var prompt := "Write a program that takes the robot to the flag."
	if board.has("gems"):
		prompt = "Write a program that takes the robot to the flag. Pick up every gem on the way!"
	if level == 3:
		prompt = prompt.trim_suffix(".").trim_suffix("!") + ", in at most %d commands." % best.size()
	var ex := {"type": "robot", "prompt": prompt, "board": board,
		"hint": "Which way does the robot face? Point that way, then plan one square at a time: a turn does not move it.",
		"explain": "A program that works: %s." % _said(best)}
	if level == 3:
		ex.max = best.size()
	ex.data = {"board": board}
	return ex


static func loop_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var first: Array[String] = []
	var body: Array[String] = []
	var n := 0
	var cells: Array[Vector2i] = []
	for _try in 60:
		first.clear()
		body.clear()
		match level:
			1:
				n = rng.randi_range(2, 5)
				body.append_array(_forwards(rng.randi_range(1, int(7.0 / n))))
			2:
				n = rng.randi_range(2, 4)
				body.append_array(_forwards(rng.randi_range(1, 3)))
				body.append("R" if rng.randi() % 2 == 0 else "L")
			_:
				n = rng.randi_range(2, 3)
				first.append_array(_forwards(rng.randi_range(1, 2)))
				var up := "L" if rng.randi() % 2 == 0 else "R"
				body.append(up)
				body.append_array(_forwards(rng.randi_range(1, 2)))
				body.append("R" if up == "L" else "L")
				body.append_array(_forwards(rng.randi_range(1, 2)))
		cells = _trail(first, body, n)
		if _fits(cells):
			break
	var one := body.count("F")
	var before := first.count("F")
	var total := before + n * one
	var loop := "repeat %d times [%s]" % [n, _said(body)]
	var said := loop if first.is_empty() else "%s, then %s" % [_said(first), loop]
	var explain := ""
	if first.is_empty():
		explain = "Each time round it moves %d square%s, and it goes round %d times: %d × %d = %d squares." % [one,
			"" if one == 1 else "s", n, n, one, total]
	else:
		explain = "First %d. Each time round moves %d, so %d times round moves %d × %d = %d. Altogether %d + %d = %d squares." \
			% [before, one, n, n, one, n * one, before, n * one, total]
	var ex := K.number("The robot runs this program: %s. How many squares does it move altogether?" % said, total,
		"Count the FORWARDs in one time round the loop (turns do not move it). Then add that many for every time round.",
		explain, _trail_picture(cells, rng))
	ex.data = {"first": first, "repeats": n, "body": body}
	return ex


static func fix_the_bug(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var board := {}
	var program: Array[String] = []
	var buggy: Array[String] = []
	var at := 0
	for _try in 150:
		board = _board(rng, level)
		program = RobotCheck.shortest(board)
		if program.size() < 2 or program.size() > [4, 5, 6][level - 1]:
			continue
		at = rng.randi_range(0, program.size() - 1)
		buggy = program.duplicate()
		var others: Array = RobotCheck.COMMANDS.filter(func(c: String) -> bool: return c != program[at])
		buggy[at] = others[rng.randi_range(0, others.size() - 1)]
		if not RobotCheck.reaches(board, buggy) and _numbered(buggy).length() <= 100:
			break
	var wrongs: Array = []
	var tries := 0
	while wrongs.size() < 3 and tries < 200:
		tries += 1
		var i := rng.randi_range(0, buggy.size() - 1)
		var c: String = RobotCheck.COMMANDS[rng.randi_range(0, 2)]
		var fixed := buggy.duplicate()
		fixed[i] = c
		var text := "step %d: %s" % [i + 1, RobotCheck.WORDS[c]]
		if c != buggy[i] and not RobotCheck.reaches(board, fixed) and not wrongs.has(text):
			wrongs.append(text)
	var pic := _picture(board)
	var path: Array = []
	for c: Vector2i in RobotCheck.run(board, buggy).path:
		path.append([c.x, c.y])
	pic.path = path
	var ex := K.choice(rng, "This program should take the robot to the flag, but it has a bug: %s. Which change fixes it?"
		% _numbered(buggy), "step %d: %s" % [at + 1, RobotCheck.WORDS[program[at]]], wrongs,
		"Follow the program one step at a time with your finger. Where does the robot first go the wrong way?",
		"Step %d should be %s, not %s. Then the robot reaches the flag." % [at + 1, RobotCheck.WORDS[program[at]],
			RobotCheck.WORDS[buggy[at]]], pic)
	ex.data = {"board": board, "program": program, "buggy": buggy}
	return ex


# --- helpers ---------------------------------------------------------------------------------------------------------

## A rhythm of `beats` beats (crotchets, quavers, rests) that starts with a sound: level 1 crotchets and one rest at
## most; level 2 at least one pair of quavers; level 3 quavers and a rest.
static func _rhythm(rng: RandomNumberGenerator, beats: int, level: int) -> Array:
	var kinds: Array = ["crotchet", "rest"] if level == 1 else ["crotchet", "quavers", "rest"]
	var out: Array = []
	for _try in 100:
		out = ["crotchet" if level == 1 or rng.randi() % 2 == 0 else "quavers"]
		for i in beats - 1:
			out.append(kinds[rng.randi_range(0, kinds.size() - 1)])
		var rests := out.count("rest")
		if rests > (1 if beats <= 4 else 2):
			continue
		if level >= 2 and not out.has("quavers"):
			continue
		if level == 3 and rests == 0:
			continue
		break
	return out


## The rhythm with one beat (not the first) changed.
static func _changed(rng: RandomNumberGenerator, beats: Array) -> Array:
	var out := beats.duplicate()
	var i := rng.randi_range(1, out.size() - 1)
	var others: Array = ["crotchet", "quavers", "rest"].filter(func(k: String) -> bool: return k != str(out[i]))
	out[i] = others[rng.randi_range(0, 1)]
	return out


static func _distance(a: Array, b: Array) -> int:
	var n := 0
	for i in a.size():
		n += 1 if str(a[i]) != str(b[i]) else 0
	return n


static func _pattern(beats: Array) -> String:
	var out := ""
	for b: Variant in beats:
		out += str(CLAPS[str(b)])
	return out


## "ta, ti-ti, rest, ta"
static func _words(beats: Array) -> String:
	var out: Array[String] = []
	for b: Variant in beats:
		out.append(str(WORDS[str(b)]))
	return ", ".join(out)


static func _note_name(midi: int) -> String:
	return "%s%d" % [NOTE_NAMES[midi % 12], midi / 12 - 1]


## `n` notes of SCALE in a shape (steps of one note), the last one held for two beats.
static func _tune(rng: RandomNumberGenerator, shape: String, n: int) -> Array:
	var steps: Array[int] = []
	match shape:
		"up":
			for i in n - 1:
				steps.append(1)
		"down":
			for i in n - 1:
				steps.append(-1)
		_:
			var turn := rng.randi_range(1, n - 2)
			for i in n - 1:
				var first_half := i < turn
				steps.append((1 if first_half else -1) * (1 if shape == "up, then down" else -1))
	var lo := 0
	var hi := 0
	var at := 0
	for s in steps:
		at += s
		lo = mini(lo, at)
		hi = maxi(hi, at)
	var start := rng.randi_range(-lo, SCALE.size() - 1 - hi)
	var out: Array = [SCALE[start]]
	at = start
	for s in steps:
		at += s
		out.append(SCALE[at])
	out[-1] = str(out[-1]) + ":2"
	return out


static func _sum(a: Array) -> int:
	var n := 0
	for v: Variant in a:
		n += int(v)
	return n


## A board in RobotCheck's form: level 1 open ground (the way there has one turn at most), level 2 a wall or two,
## level 3 walls that make the way round longer; `gems` adds a gem (level 2) or one or two (level 3).
static func _board(rng: RandomNumberGenerator, level: int, gems := false) -> Dictionary:
	for _try in 300:
		var cols := rng.randi_range(3, 5) if level == 1 else rng.randi_range(4, 6)
		var rows := rng.randi_range(3, 5) if level == 1 else rng.randi_range(4, 6)
		var start := Vector2i(rng.randi_range(0, cols - 1), rng.randi_range(0, rows - 1))
		var goal := Vector2i(rng.randi_range(0, cols - 1), rng.randi_range(0, rows - 1))
		if goal == start:
			continue
		var b := {"cols": cols, "rows": rows, "start": [start.x, start.y], "goal": [goal.x, goal.y],
			"facing": RobotCheck.HEADINGS[rng.randi_range(0, 3)]}
		var open := RobotCheck.shortest(b)
		if level == 1:
			if open.size() >= 2 and _turns(open) <= 1:
				return b
			continue
		var used := {start: true, goal: true}
		var walls: Array = []
		for i in (rng.randi_range(1, 2) if level == 2 else rng.randi_range(2, 4)):
			var w := Vector2i(rng.randi_range(0, cols - 1), rng.randi_range(0, rows - 1))
			if not used.has(w):
				used[w] = true
				walls.append([w.x, w.y])
		if walls.is_empty():
			continue
		b.walls = walls
		if gems:
			var found: Array = []
			for i in (1 if level == 2 else rng.randi_range(1, 2)):
				var g := Vector2i(rng.randi_range(0, cols - 1), rng.randi_range(0, rows - 1))
				if not used.has(g):
					used[g] = true
					found.append([g.x, g.y])
			if not found.is_empty():
				b.gems = found
		if RobotCheck.problem(b) != "":
			continue
		var best := RobotCheck.shortest(b)
		if best.size() > (9 if level == 2 else 14) or (level == 3 and best.size() <= open.size()):
			continue   # level 3: the walls are in the way
		return b
	return {"cols": 4, "rows": 4, "start": [0, 3], "facing": "N", "goal": [3, 0]}   # never needed in 3 × 500 seeds


static func _turns(program: Array) -> int:
	return program.count("L") + program.count("R")


static func _forwards(k: int) -> Array[String]:
	var out: Array[String] = []
	for i in k:
		out.append("F")
	return out


## "FORWARD 2, TURN RIGHT, FORWARD": a run of FORWARDs written short.
static func _said(program: Array) -> String:
	var out: Array[String] = []
	var run := 0
	for i in program.size() + 1:
		var c := str(program[i]) if i < program.size() else ""
		if c == "F":
			run += 1
			continue
		if run > 0:
			out.append("FORWARD" if run == 1 else "FORWARD %d" % run)
			run = 0
		if c != "":
			out.append(str(RobotCheck.WORDS[c]))
	return ", ".join(out)


## "two squares forward, then a quarter turn right, then one square forward"
static func _told(program: Array) -> String:
	var out: Array[String] = []
	var run := 0
	for i in program.size() + 1:
		var c := str(program[i]) if i < program.size() else ""
		if c == "F":
			run += 1
			continue
		if run > 0:
			out.append("%s square%s forward" % [NUMBER_WORDS[run] if run < 10 else str(run), "" if run == 1 else "s"])
			run = 0
		if c != "":
			out.append("a quarter turn %s" % ("left" if c == "L" else "right"))
	return ", then ".join(out)


## "1 FORWARD, 2 TURN LEFT, 3 FORWARD": every command with its step number.
static func _numbered(program: Array) -> String:
	var out: Array[String] = []
	for i in program.size():
		out.append("%d %s" % [i + 1, RobotCheck.WORDS[str(program[i])]])
	return ", ".join(out)


## Programs a child might write by mistake: a turn the other way, one FORWARD too many or too few, a turn left out,
## an extra turn at the start.
static func _near_programs(rng: RandomNumberGenerator, program: Array) -> Array:
	var out: Array = []
	for i in program.size():
		var p: Array = program.duplicate()
		match str(program[i]):
			"L", "R":
				p[i] = "R" if program[i] == "L" else "L"
				out.append(p)
				var q: Array = program.duplicate()
				q.remove_at(i)
				out.append(q)
			"F":
				var more: Array = program.duplicate()
				more.insert(i, "F")
				out.append(more)
				var less: Array = program.duplicate()
				less.remove_at(i)
				out.append(less)
	for t: String in ["L", "R"]:
		var p: Array = program.duplicate()
		p.push_front(t)
		out.append(p)
	K.shuffle(rng, out)
	return out


## The squares a loop program visits from (0, 0), facing east: `first`, then `body` `n` times.
static func _trail(first: Array, body: Array, n: int) -> Array[Vector2i]:
	var at := Vector2i.ZERO
	var facing := 1   # RobotCheck.HEADINGS: N, E, S, W
	var cells: Array[Vector2i] = [at]
	var program: Array = first.duplicate()
	for i in n:
		program.append_array(body)
	for c: Variant in program:
		match str(c):
			"L":
				facing = (facing + 3) % 4
			"R":
				facing = (facing + 1) % 4
			_:
				at += RobotCheck.STEP[RobotCheck.HEADINGS[facing]]
				cells.append(at)
	return cells


static func _fits(cells: Array[Vector2i]) -> bool:
	var lo := cells[0]
	var hi := cells[0]
	for c in cells:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	return hi.x - lo.x < 8 and hi.y - lo.y < 8


## A board picture for a loop's trail: turned a random quarter turn (the robot's start facing turns with it), the
## robot where it starts and a flag where it ends (none when it ends where it started).
static func _trail_picture(cells: Array[Vector2i], rng: RandomNumberGenerator) -> Dictionary:
	var turns := rng.randi_range(0, 3)
	var turned: Array[Vector2i] = []
	for c in cells:
		var t := c
		for i in turns:
			t = Vector2i(-t.y, t.x)   # a quarter turn clockwise (y grows downwards)
		turned.append(t)
	var lo := turned[0]
	var hi := turned[0]
	for c in turned:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var size := Vector2i(maxi(hi.x - lo.x + 1, 3), maxi(hi.y - lo.y + 1, 3))
	var pad := (size - (hi - lo + Vector2i.ONE)) / 2
	var start := turned[0] - lo + pad
	var end := turned[-1] - lo + pad
	var pic := {"kind": "robot", "cols": size.x, "rows": size.y, "start": [start.x, start.y],
		"facing": RobotCheck.HEADINGS[(1 + turns) % 4]}
	if end != start:
		pic.goal = [end.x, end.y]
	return pic


static func _picture(board: Dictionary) -> Dictionary:
	var pic := {"kind": "robot", "cols": board.cols, "rows": board.rows, "start": board.start, "facing": board.facing,
		"goal": board.goal}
	for k: String in ["walls", "gems"]:
		if board.has(k):
			pic[k] = board[k]
	return pic


## The text with its first letter a capital ("light blue" -> "Light blue"; String.capitalize() makes "Light Blue").
static func _cap(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1)
