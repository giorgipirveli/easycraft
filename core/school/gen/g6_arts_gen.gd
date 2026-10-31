class_name G6ArtsGen
extends RefCounted
## Owner #70 and #73 (research §6.6): grade 6 computing, art and music generators: SchoolGen "g6c.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a
## strategy, never the answer), a worked answer and `data` (tests/unit/test_g6_arts_gen.gd works every answer out again
## with its own binary, light, logic, interpreter, spreadsheet, angle, scale, interval, blues and sound rules).
## - Computing: binary_value (binary cards to a number), to_binary (a number to binary), image_bits (pixels,
##   colours from bits, a picture's size in bits and bytes), light_colour (red, green and blue light added), logic_check
##   (AND, OR and NOT in a game's conditions), gate_output (a gate's output, a truth table's row), trace_program (what a
##   program with loops and IF leaves in a variable), flow_path (a flowchart's decision and loop), data_type (numbers,
##   text and true or false; text joins, numbers add), game_decision (nested and combined IFs in a game), storage_size
##   (bits, bytes, kilobytes, megabytes), sheet_model (a spreadsheet model: formulas, totals, averages, what if),
##   guess_count (how many codes a PIN or a password has), phish_check (a trick email's clues), public_private (what is
##   fine to share and what stays private), ai_guess (what a computer learned from its examples).
## - Art: tile_angles (the angles of regular shapes round a point), turn_angle (rotational symmetry), print_order (a
##   layered print's colours, lightest first), nature_numbers (Fibonacci numbers in nature, a ring of stones),
##   critique_step (describe, analyse, interpret, judge), principle_spot (the principle a design shows).
## - Music: scale_notes (major scales and their sharps and flats), interval_size (intervals by their letters and by
##   ear), blues_bar (the 12-bar blues' chords, its bars and beats), music_period (Medieval, Renaissance, Baroque,
##   Classical), offbeat_rhythm (off-beat claps to count and copy), variation_change (what a variation changed, heard),
##   chord_fit (the chord that fits a melody's notes), instrument_family (how instruments of the world make their sound,
##   and where they come from), sound_numbers (octaves double the frequency, frequency from vibrations, thunder's
##   distance).

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Juno"]

# --- Computing -------------------------------------------------------------------------------------------------------

## Binary cards to a number. Level 1: 3-4 cards; level 2: 5 cards; level 3: a byte (8 cards).
static func binary_value(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var width: int = [0, rng.randi_range(3, 4), 5, 8][level]
	var n := rng.randi_range(1, (1 << width) - 1)
	var bits := _bits(n, width)
	var parts := _place_parts(n, width)
	var work := ""
	if parts.size() == 1:
		work = "Only the card worth %s is face up, so the number is %d." % [parts[0], n]
	else:
		work = "The face-up cards (the 1s) are worth %s: %s = %d." % [_and(parts), " + ".join(parts), n]
	var ex := K.number("Face-up cards are 1s and face-down cards are 0s. What number do these binary cards show?", n,
		"Each card is worth double the card on its right. Add up the cards that are face up.", work,
		{"kind": "bit_cards", "bits": bits, "values": true})
	ex.data = {"bits": bits}
	return ex


## A number to binary. Level 1: up to 15 (4 digits); level 2: up to 31 (5 digits); level 3: up to 255 (a byte).
static func to_binary(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var width: int = [0, 4, 5, 8][level]
	var n := rng.randi_range(2 if level == 1 else (1 << (width - 2)), (1 << width) - 1)
	var right := _bits(n, width)
	var wrongs: Array = []
	for cand: int in [n + 1, n - 1, n ^ (1 << (width - 1)), _reverse_bits(n, width), n + 2, n ^ 1, n ^ 2, n ^ 4, n - 2]:
		var b := _bits(cand, width)
		if cand > 0 and cand < (1 << width) and b != right and not wrongs.has(b):
			wrongs.append(b)
		if wrongs.size() == 3:
			break
	var parts := _place_parts(n, width)
	var ex := K.choice(rng, "Which is %d in binary?" % n, right, wrongs,
		"Start with the biggest place value that fits (%s …), take it away, and go on down to 1." % ", ".join(
			_place_values(width).slice(0, 3)),
		"%d = %s, so those places are 1s and the rest 0s: %s." % [n, " + ".join(parts), right])
	ex.data = {"n": n, "width": width}
	return ex


## Pictures as pixels. Level 1: count a picture's pixels; level 2: the colours a number of bits can make, or the bits a
## number of colours needs; level 3: a picture's size in bits and bytes.
static func image_bits(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var w := rng.randi_range(5, 12)
			var h := rng.randi_range(3, 8)
			var rows: Array[String] = []
			for y in h:
				var row := ""
				for x in w:
					row += "1" if rng.randi() % 3 == 0 else "0"
				rows.append(row)
			ex = K.number("How many pixels make this picture?", w * h,
				"Count the pixels in one row and the rows, then multiply.",
				"%d pixels in a row and %d rows: %d × %d = %d pixels." % [w, h, w, h, w * h],
				{"kind": "pixels", "rows": rows})
			ex.data = {"w": w, "h": h}
		2:
			var bits := rng.randi_range(1, 5)
			var colours := 1 << bits
			if rng.randi() % 2 == 0:
				ex = K.number("Each pixel of a picture is stored in %d bit%s. How many different colours can a pixel be?" % [
					bits, "" if bits == 1 else "s"], colours,
					"Each extra bit doubles the colours: 1 bit makes 2 (0 or 1), 2 bits make 4 …",
					("1 bit is 0 or 1: 2 colours." if bits == 1 else "%d bits: %s = %d colours." % [bits,
						" × ".join(_twos(bits)), colours]))
			else:
				ex = K.number("A picture needs %d different colours. How many bits must each pixel have?" % colours, bits,
					"Double from 2 (1 bit) until you reach the number of colours, counting the bits.",
					"1 bit gives 2 colours and each bit more doubles them: %s. So %d bit%s." % [_doubling(bits), bits,
					"" if bits == 1 else "s"])
			ex.data = {"bits": bits, "colours": colours}
		_:
			var w: int = [8, 16, 24, 32][rng.randi_range(0, 3)]
			var h := rng.randi_range(2, 8) * 2
			var bits := [1, 2, 8][rng.randi_range(0, 2)] as int
			var total := w * h * bits
			ex = K.number("A picture is %d pixels wide and %d tall, with %d bit%s for each pixel. How many bytes does it need? (8 bits make a byte.)" % [
				w, h, bits, "" if bits == 1 else "s"], total / 8,
				"Find the pixels (width × height), then the bits, then divide the bits by 8.",
				"%d × %d = %d pixels; × %d bit%s = %d bits; %d ÷ 8 = %d bytes." % [w, h, w * h, bits, "" if bits == 1 else "s",
				total, total, total / 8])
			ex.data = {"w": w, "h": h, "bits": bits}
	return ex


## The colours of light: red, green and blue light add up. Level 1: two lights together; level 2: a colour's three
## numbers (0 or 255); level 3: the numbers for a colour, or black and white.
static func light_colour(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := {"100": "red", "010": "green", "001": "blue", "110": "yellow", "011": "cyan", "101": "magenta",
		"111": "white", "000": "black"}
	var ex := {}
	match level:
		1:
			var pairs: Array = [["red", "green", "yellow"], ["green", "blue", "cyan"], ["red", "blue", "magenta"]]
			var p: Array = pairs[rng.randi_range(0, 2)]
			var wrongs: Array = ["brown", "purple", "white", "orange", "black"]
			if p[2] == "magenta":
				wrongs.erase("purple")
			ex = K.choice(rng, "%s light and %s light shine on a white wall together. What colour do you see where they meet?" % [
				str(p[0]).capitalize(), p[1]], p[2], wrongs.slice(0, 3),
				"Light adds up, it does not mix like paint. Think of a screen's pixels.",
				"%s light and %s light add up to %s." % [str(p[0]).capitalize(), p[1], p[2]])
			ex.data = {"rgb": _rgb_of(p[0]) + _rgb_of(p[1])}
		2:
			var keys: Array = ["100", "010", "001", "110", "011", "101", "111", "000"]
			var key := str(keys[rng.randi_range(0, keys.size() - 1)])
			var nums := _rgb_numbers(key)
			var wrongs: Array = []
			for k: Variant in keys:
				if str(k) != key and wrongs.size() < 3 and rng.randi() % 2 == 0:
					wrongs.append(names[k])
			for k: Variant in keys:
				if str(k) != key and wrongs.size() < 3 and not wrongs.has(names[k]):
					wrongs.append(names[k])
			ex = K.choice(rng, "A pixel's colour is written (red, green, blue), each from 0 to 255. What colour is %s?" % nums,
				names[key], wrongs,
				"255 is that light fully on and 0 is off. Add up the lights that are on.",
				"%s: %s. So the pixel is %s." % [nums, _lights_on(key), names[key]])
			ex.data = {"rgb": key}
		_:
			var keys: Array = ["110", "011", "101", "111", "000", "100", "010", "001"]
			var key := str(keys[rng.randi_range(0, keys.size() - 1)])
			var wrongs: Array = []
			for k: Variant in keys:
				if str(k) != key and wrongs.size() < 3 and (rng.randi() % 2 == 0 or keys.find(k) > 4):
					wrongs.append(_rgb_numbers(str(k)))
			for k: Variant in keys:
				if str(k) != key and wrongs.size() < 3 and not wrongs.has(_rgb_numbers(str(k))):
					wrongs.append(_rgb_numbers(str(k)))
			ex = K.choice(rng, "Which numbers (red, green, blue) make %s light on a screen?" % names[key], _rgb_numbers(key),
				wrongs, "Which of red, green and blue light add up to that colour? Those are 255, the rest 0.",
				"%s is %s, so it is %s." % [str(names[key]).capitalize(), _lights_on(key), _rgb_numbers(key)])
			ex.data = {"rgb": key}
	return ex


## AND, OR and NOT in a game's conditions: true or false. Level 1: AND or OR of two comparisons; level 2: with ≥, ≤
## and =; level 3: NOT as well.
static func logic_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var vars := {"score": rng.randi_range(0, 30), "lives": rng.randi_range(0, 3), "keys": rng.randi_range(0, 4),
		"gems": rng.randi_range(0, 12)}
	var names: Array = vars.keys()
	GenKit.shuffle(rng, names)
	var a := str(names[0])
	var b := str(names[1])
	var ops1: Array[String] = [">", "<"]
	var ops2: Array[String] = [">", "<", "≥", "≤", "="]
	var ops := ops1 if level == 1 else ops2
	var ca := _comparison(rng, a, int(vars[a]), ops)
	var cb := _comparison(rng, b, int(vars[b]), ops)
	var join := "AND" if rng.randi() % 2 == 0 else "OR"
	var cond := "%s %s %s" % [ca, join, cb]
	var not_a := level == 3 and rng.randi() % 2 == 0
	if level == 3:
		cond = "NOT (%s) %s %s" % [ca, join, cb] if not_a else "%s %s NOT (%s)" % [ca, join, cb]
	var va := _compare(int(vars[a]), ca)
	var vb := _compare(int(vars[b]), cb)
	var pa := (not va) if (level == 3 and not_a) else va
	var pb := (not vb) if (level == 3 and not not_a) else vb
	var value := (pa and pb) if join == "AND" else (pa or pb)
	var said := "%s is %d and %s is %d." % [a, int(vars[a]), b, int(vars[b])]
	var work := "%s is %s and %s is %s" % [ca, _tf(va), cb, _tf(vb)]
	if level == 3:
		work += "; NOT turns %s round to %s" % [ca if not_a else cb, _tf(pa if not_a else pb)]
	work += ". %s needs %s, so the whole condition is %s." % [join, "both" if join == "AND" else "at least one",
		_tf(value)]
	var ex := K.truefalse("%s True or false: %s" % [said, cond], value,
		"Work out each side on its own first (true or false), then join them: AND needs both, OR needs one.",
		("True: " if value else "False: ") + work)
	ex.data = {"vars": {a: vars[a], b: vars[b]}, "cond": cond}
	return ex


## A gate's output (level 1: NOT, AND or OR; level 2: a truth table's missing row; level 3: a gate then NOT).
static func gate_output(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var gates: Array = ["AND", "OR", "NOT"] if level == 1 else ["AND", "OR"]
	var gate := str(gates[rng.randi_range(0, gates.size() - 1)])
	var inputs: Array = [rng.randi_range(0, 1)] if gate == "NOT" else [rng.randi_range(0, 1), rng.randi_range(0, 1)]
	var out := SchoolPictureG6Arts.gate_out(gate, inputs)
	var rule := {"AND": "AND sends out 1 only when both inputs are 1", "OR": "OR sends out 1 when either input is 1 (or both)",
		"NOT": "NOT turns its input round"}
	var ex := {}
	if level == 2:
		var rows: Array = [["A", "B", "A %s B" % gate]]
		var ask := rng.randi_range(0, 3)
		for i in 4:
			var ins: Array = [i / 2, i % 2]
			rows.append([str(ins[0]), str(ins[1]), "?" if i == ask else str(SchoolPictureG6Arts.gate_out(gate, ins))])
		inputs = [ask / 2, ask % 2]
		out = SchoolPictureG6Arts.gate_out(gate, inputs)
		ex = K.number("This is the truth table of %s. What goes in the ? box: 1 or 0?" % gate, out,
			"Read the row's A and B, then use the gate's rule.",
			"A is %d and B is %d. %s, so it is %d." % [inputs[0], inputs[1], rule[gate], out], {"kind": "table", "rows": rows})
		ex.data = {"gate": gate, "inputs": inputs}
		return ex
	var pic := {"kind": "logic_gate", "gate": gate, "inputs": inputs, "out": false}
	var work := "The inputs are %s. %s, so it sends out %d." % [" and ".join(PackedStringArray(inputs.map(func(v: Variant) -> String:
		return str(v)))), rule[gate], out]
	if level == 3:
		pic.then = "NOT"
		work = "%s gives %d, then NOT turns it round: %d." % [gate, out, 1 - out]
		out = 1 - out
	ex = K.number("A lit wire is 1 and a dark one is 0. What comes out at the ?: 1 or 0?", out,
		"Use each gate's rule in turn, from left to right.", work, pic)
	ex.data = {"gate": gate, "inputs": inputs, "then": "NOT" if level == 3 else ""}
	return ex


## What a program leaves in a variable. Level 1: SET and CHANGE; level 2: a loop; level 3: REPEAT UNTIL, or an IF in
## a loop.
static func trace_program(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array[String] = []
	var ask := ""
	var work := ""
	var value := 0
	match level:
		1:
			var a := rng.randi_range(2, 9)
			var b := rng.randi_range(2, 6)
			var c := rng.randi_range(1, 5)
			lines = ["SET gems TO %d" % a, "CHANGE gems BY %d" % b, "SET total TO gems * 2", "CHANGE total BY -%d" % c]
			ask = "total"
			value = (a + b) * 2 - c
			work = "gems is %d, then %d + %d = %d. total is %d × 2 = %d, then %d − %d = %d." % [a, a, b, a + b, a + b,
				(a + b) * 2, (a + b) * 2, c, value]
		2:
			var start := rng.randi_range(0, 5)
			var n := rng.randi_range(3, 6)
			var step := rng.randi_range(2, 5)
			lines = ["SET coins TO %d" % start, "REPEAT %d TIMES" % n, "  CHANGE coins BY %d" % step]
			ask = "coins"
			value = start + n * step
			work = "The loop adds %d, %d times: %d × %d = %d. %d + %d = %d." % [step, n, n, step, n * step, start, n * step, value]
		_:
			if rng.randi() % 2 == 0:
				var start := rng.randi_range(1, 3)
				var limit := rng.randi_range(20, 60)
				lines = ["SET size TO %d" % start, "SET steps TO 0", "REPEAT UNTIL size > %d" % limit,
					"  SET size TO size * 2", "  CHANGE steps BY 1"]
				ask = "steps"
				var s := start
				var seen: Array[String] = [str(s)]
				while s <= limit:
					s *= 2
					value += 1
					seen.append(str(s))
				work = "size doubles: %s. It is more than %d after %d doubling%s, so steps is %d." % [", ".join(seen), limit,
					value, "" if value == 1 else "s", value]
			else:
				var n := rng.randi_range(4, 7)
				var at := rng.randi_range(2, n - 1)
				lines = ["SET lap TO 0", "SET stars TO 0", "REPEAT %d TIMES" % n, "  CHANGE lap BY 1", "  IF lap > %d" % at,
					"    CHANGE stars BY 3"]
				ask = "stars"
				value = (n - at) * 3
				work = "lap goes 1 to %d. It is more than %d on %d laps (%d to %d): %d × 3 = %d stars." % [n, at, n - at,
					at + 1, n, n - at, value]
	var ex := K.number("What is %s when the program ends?" % ask, value,
		"Keep each variable on paper and change it line by line. Count how many times each loop goes round.", work,
		{"kind": "code", "lines": lines})
	ex.data = {"lines": lines, "var": ask}
	return ex


## A flowchart: level 1 and 2, which way a decision goes; level 3, how many times a loop goes round.
static func flow_path(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := NAMES[rng.randi_range(0, NAMES.size() - 1)]
	if level < 3:
		var limit := rng.randi_range(4, 12) * 5
		var score := limit + (rng.randi_range(-2, 2) * 5 if level == 1 else rng.randi_range(-1, 1) * 5)
		if level == 1 and score == limit:
			score += 10
		var op := ">" if level == 1 else "≥"
		var yes := score > limit if op == ">" else score >= limit
		var steps: Array = [{"shape": "start", "text": "Start"}, {"shape": "step", "text": "Get the score"},
			{"shape": "decision", "text": "score %s %d?" % [op, limit], "no": "SAY Keep going!"},
			{"shape": "step", "text": "SAY You win a star!"}, {"shape": "end", "text": "End"}]
		var ex := K.choice(rng, "%s's score is %d. What does the game say?" % [who, score],
			"You win a star!" if yes else "Keep going!", ["Keep going!" if yes else "You win a star!"],
			"Follow the arrows. At the diamond, answer its question for this score: yes goes down, no goes to the side.",
			"Is %d %s %d? %s, so it says %s" % [score, op, limit, "Yes" if yes else "No",
				"You win a star!" if yes else "Keep going!"], {"kind": "flowchart", "steps": steps})
		ex.data = {"score": score, "limit": limit, "op": op}
		return ex
	var start := rng.randi_range(0, 2)
	var target := start + rng.randi_range(2, 5)
	var steps3: Array = [{"shape": "start", "text": "Start"}, {"shape": "step", "text": "SET count TO %d" % start},
		{"shape": "step", "text": "CLAP, add 1 to count"}, {"shape": "decision", "text": "count = %d?" % target, "back": 2},
		{"shape": "end", "text": "End"}]
	var claps := target - start
	var ex3 := K.number("How many times does this flowchart clap?", claps,
		"Follow it with your finger and keep count on paper. The no arrow goes back up to the clap.",
		"count goes from %d up to %d, one each clap: %d − %d = %d claps." % [start, target, target, start, claps],
		{"kind": "flowchart", "steps": steps3})
	ex3.data = {"start": start, "target": target}
	return ex3


## Data types. Level 1: which type a value is; level 2: values in quotes are text; level 3: text joins and numbers add.
static func data_type(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var types: Array[String] = ["whole number (integer)", "decimal (real)", "text (string)", "true or false (Boolean)"]
	if level < 3:
		var bank: Array = [["42", 0], ["-7", 0], ["2026", 0], ["3.5", 1], ["0.25", 1], ["9.81", 1], ["\"Tilly\"", 2],
			["\"hello\"", 2], ["TRUE", 3], ["FALSE", 3]]
		if level == 2:
			bank = [["\"42\"", 2], ["\"TRUE\"", 2], ["7.0", 1], ["0", 0], ["\"3.5\"", 2], ["-12", 0], ["FALSE", 3],
				["\"Gem 5\"", 2], ["100.1", 1]]
		var pick: Array = bank[rng.randi_range(0, bank.size() - 1)]
		var t := int(pick[1])
		var why: Array[String] = ["a whole number with no decimal point", "a number with a decimal point",
			"letters or digits inside quotes, which a computer treats as text", "TRUE or FALSE with no quotes"]
		var ex := K.choice(rng, "What type of data is %s?" % pick[0], types[t], types.filter(func(x: String) -> bool:
			return x != types[t]),
			"Quotes make text. A decimal point makes a decimal. TRUE and FALSE on their own are true or false.",
			"%s is %s: %s." % [pick[0], why[t], types[t]])
		ex.data = {"value": pick[0], "type": t}
		return ex
	var a := rng.randi_range(2, 9)
	var b := rng.randi_range(2, 9)
	var text := rng.randi() % 2 == 0
	var right := "%d%d" % [a, b] if text else str(a + b)
	var wrongs: Array = [str(a + b) if text else "%d%d" % [a, b], "%d + %d" % [a, b], str(a * b)]
	var shown := ("\"%d\" + \"%d\"" if text else "%d + %d") % [a, b]
	var ex3 := K.choice(rng, "What does OUTPUT %s show?" % shown, right, wrongs,
		"Are they numbers, or text in quotes? + adds numbers but joins text.",
		("They are text, so + joins them side by side: %s." % right) if text else ("They are numbers, so + adds them: %s." %
			right))
	ex3.data = {"a": a, "b": b, "text": text}
	return ex3


## A game's decisions. Level 1: IF and ELSE; level 2: two conditions with AND or OR; level 3: an IF inside an IF.
static func game_decision(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var gems := rng.randi_range(0, 10)
	var keys := rng.randi_range(0, 2)
	var lines: Array[String] = ["SET gems TO %d" % gems, "SET keys TO %d" % keys]
	var said := ""
	var outs: Array[String] = []
	match level:
		1:
			var need := rng.randi_range(3, 8)
			lines.append_array(["IF gems ≥ %d" % need, "  OUTPUT \"Shop opens\"", "ELSE", "  OUTPUT \"Find more gems\""])
			outs = ["Shop opens", "Find more gems"]
			said = outs[0] if gems >= need else outs[1]
		2:
			var need := rng.randi_range(3, 8)
			var join := "AND" if rng.randi() % 2 == 0 else "OR"
			lines.append_array(["IF gems ≥ %d %s keys > 0" % [need, join], "  OUTPUT \"Door opens\"", "ELSE",
				"  OUTPUT \"Door stays shut\""])
			outs = ["Door opens", "Door stays shut"]
			var ok := (gems >= need and keys > 0) if join == "AND" else (gems >= need or keys > 0)
			said = outs[0] if ok else outs[1]
		_:
			var need := rng.randi_range(3, 8)
			lines.append_array(["IF keys > 0", "  IF gems ≥ %d" % need, "    OUTPUT \"Treasure!\"", "  ELSE",
				"    OUTPUT \"Nearly!\"", "ELSE", "  OUTPUT \"Find a key\""])
			outs = ["Treasure!", "Nearly!", "Find a key"]
			said = outs[2] if keys == 0 else (outs[0] if gems >= need else outs[1])
	var wrongs: Array = outs.filter(func(o: String) -> bool: return o != said)
	var ex := K.choice(rng, "What does this game program output?", said, wrongs,
		"Put the numbers into the first IF. Only the lines under the side that is true run; an inner IF is checked only if its outer one is true.",
		"With gems %d and keys %d, it outputs \"%s\"." % [gems, keys, said], {"kind": "code", "lines": lines})
	ex.data = {"lines": lines}
	return ex


## Storage. Level 1: bits and bytes; level 2: kilobytes and bytes; level 3: how many files fit.
static func storage_size(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var bytes := rng.randi_range(2, 12)
			if rng.randi() % 2 == 0:
				ex = K.number("How many bits are in %d bytes?" % bytes, bytes * 8, "A byte is 8 bits.",
					"%d × 8 = %d bits." % [bytes, bytes * 8])
			else:
				ex = K.number("How many bytes are %d bits?" % (bytes * 8), bytes, "A byte is 8 bits: divide by 8.",
					"%d ÷ 8 = %d bytes." % [bytes * 8, bytes])
			ex.data = {"bytes": bytes}
		2:
			var kb := rng.randi_range(2, 60)
			if rng.randi() % 2 == 0:
				ex = K.number("A kilobyte is 1,000 bytes. How many bytes are in %d kilobytes?" % kb, kb * 1000,
					"Multiply by 1,000.", "%d × 1,000 = %s bytes." % [kb, K.fmt(kb * 1000)])
			else:
				ex = K.number("A file is %s bytes. How many kilobytes is that? (1 kilobyte is 1,000 bytes.)" % K.fmt(kb * 1000), kb,
					"Divide by 1,000.", "%s ÷ 1,000 = %d kilobytes." % [K.fmt(kb * 1000), kb])
			ex.data = {"kb": kb}
		_:
			var each: int = [2, 4, 5, 8][rng.randi_range(0, 3)]
			var gb := rng.randi_range(1, 4)
			var files := gb * 1000 / each
			var what: String = ["photos", "songs", "videos"][rng.randi_range(0, 2)]
			ex = K.number("A memory card holds %d GB (%s MB). Each of %s's %s is %d MB. How many fit?" % [gb, K.fmt(gb * 1000),
				NAMES[rng.randi_range(0, NAMES.size() - 1)], what, each], files,
				"Turn the card's size into MB (1 GB is 1,000 MB), then divide by the size of one file.",
				"%d GB = %s MB, and %s ÷ %d = %s." % [gb, K.fmt(gb * 1000), K.fmt(gb * 1000), each, K.fmt(files)])
			ex.data = {"gb": gb, "each": each}
	return ex


## A spreadsheet model. Level 1: a cost (price × how many); level 2: a total or an average; level 3: what if a cell
## changes.
static func sheet_model(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var items: Array = [["rope", 3], ["lamp", 5], ["tent", 12], ["map", 2], ["bucket", 4], ["kite", 1]]
	GenKit.shuffle(rng, items)
	var cells: Array = [["Item", "Price", "How many", "Cost"]]
	var n := 3
	for i in n:
		cells.append([str(items[i][0]), str(int(items[i][1])), str(rng.randi_range(1, 6)), "=B%d*C%d" % [i + 2, i + 2]])
	cells.append(["Total", "", "", "=SUM(D2:D%d)" % (n + 1)])
	var cost := func(row: int) -> int: return int(cells[row][1]) * int(cells[row][2])
	var total := 0
	for i in n:
		total += cost.call(i + 1)
	var ex := {}
	match level:
		1:
			var row := rng.randi_range(2, n + 1)
			ex = K.number("What will D%d show?" % row, cost.call(row - 1),
				"Read the formula in the cell: multiply the cells it names.",
				"D%d is =B%d*C%d: %s × %s = %d gold." % [row, row, row, cells[row - 1][1], cells[row - 1][2], cost.call(row - 1)],
				{"kind": "sheet", "cells": cells, "mark": "D%d" % row})
			ex.data = {"cells": cells, "ref": "D%d" % row}
		2:
			if rng.randi() % 2 == 0:
				var parts: Array[String] = []
				for i in n:
					parts.append(str(cost.call(i + 1)))
				ex = K.number("What will D%d show?" % (n + 2), total,
					"Work out each cost first, then add the costs the SUM names.",
					"The costs are %s: %s = %d gold." % [", ".join(parts), " + ".join(parts), total],
					{"kind": "sheet", "cells": cells, "mark": "D%d" % (n + 2)})
				ex.data = {"cells": cells, "ref": "D%d" % (n + 2)}
			else:
				var scores: Array[int] = []
				var cells2: Array = [["Game", "Points"]]
				var count := rng.randi_range(3, 4)
				var sum := 0
				for i in count - 1:
					var v := rng.randi_range(2, 20)
					scores.append(v)
					sum += v
				var last := rng.randi_range(2, 20)
				last += posmod(-(sum + last), count)   # so the points share out equally: a whole-number average
				scores.append(last)
				var avg := (sum + last) / count
				for i in count:
					cells2.append(["Game %d" % (i + 1), str(scores[i])])
				cells2.append(["Average", "=AVERAGE(B2:B%d)" % (count + 1)])
				var said: Array[String] = []
				for v in scores:
					said.append(str(v))
				ex = K.number("What will B%d show?" % (count + 2), avg,
					"An average: add the numbers, then share the total by how many there are.",
					"%s = %d, and %d ÷ %d = %d." % [" + ".join(said), avg * count, avg * count, count, avg],
					{"kind": "sheet", "cells": cells2, "mark": "B%d" % (count + 2)})
				ex.data = {"cells": cells2, "ref": "B%d" % (count + 2)}
		_:
			var row := rng.randi_range(2, n + 1)
			var now := int(cells[row - 1][2])
			var later := now + rng.randi_range(1, 4)
			var changed: Array = cells.duplicate(true)
			changed[row - 1][2] = str(later)
			var new_total: int = total - int(cost.call(row - 1)) + int(cells[row - 1][1]) * later
			ex = K.number("What if %s buys %d %ss instead of %d? After C%d changes to %d, what will D%d show?" % [
				NAMES[rng.randi_range(0, NAMES.size() - 1)], later, cells[row - 1][0], now, row, later, n + 2], new_total,
				"Change that one number, work out its row's cost again, then the total.",
				"D%d becomes %s × %d = %d. The total goes from %d to %d." % [row, cells[row - 1][1], later,
					int(cells[row - 1][1]) * later, total, new_total],
				{"kind": "sheet", "cells": cells, "mark": "C%d" % row})
			ex.data = {"cells": changed, "ref": "D%d" % (n + 2)}
	return ex


## How many codes. Level 1: a PIN of 2-4 digits; level 2: letters, or how many times more one digit more makes;
## level 3: how long a computer takes to try them all.
static func guess_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var d := rng.randi_range(2, 4)
			ex = K.number("A lock's code has %d digits, each 0 to 9. How many different codes are there?" % d, int(pow(10, d)),
				"Each digit has 10 choices, and each new digit multiplies the codes by 10.",
				"%s = %s codes." % [" × ".join(_tens(d)), K.fmt(int(pow(10, d)))])
			ex.data = {"digits": d}
		2:
			if rng.randi() % 2 == 0:
				var n := rng.randi_range(2, 3)
				var total := int(pow(26, n))
				ex = K.number("A password is %d small letters (a to z, 26 of them). How many passwords can there be?" % n, total,
					"Each letter has 26 choices: multiply 26 by itself once for each letter.",
					"%s = %s." % [" × ".join(_repeat("26", n)), K.fmt(total)])
				ex.data = {"letters": n}
			else:
				var d := rng.randi_range(3, 5)
				ex = K.number("How many times more codes does a %d-digit PIN have than a %d-digit PIN?" % [d + 1, d], 10,
					"One more digit gives each old code 10 new endings.",
					"%s codes against %s: %s ÷ %s = 10 times more." % [K.fmt(int(pow(10, d + 1))), K.fmt(int(pow(10, d))),
						K.fmt(int(pow(10, d + 1))), K.fmt(int(pow(10, d)))])
				ex.data = {"more": d}
		_:
			var d := rng.randi_range(4, 6)
			var speed: int = [10, 100, 1000][rng.randi_range(0, 2)]
			var codes := int(pow(10, d))
			ex = K.number("A computer tries %s codes a second. A PIN has %d digits (%s codes). How many seconds to try them all?" % [
				K.fmt(speed), d, K.fmt(codes)], codes / speed,
				"Divide the number of codes by how many it tries each second.",
				"%s ÷ %s = %s seconds. Longer passwords take far longer." % [K.fmt(codes), K.fmt(speed), K.fmt(codes / speed)])
			ex.data = {"digits": d, "speed": speed}
	return ex


## A trick email (phishing). Level 1 and 2: safe or not (true or false); level 3: which clue gives it away.
static func phish_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var clues: Array = [
		["from", "prize-team@win-gold-now.biz", "The sender is a stranger's odd address."],
		["urgent", "Reply in the next 10 minutes!", "It rushes you, so you do not stop to think."],
		["password", "Send us your password to claim it.", "It asks for your password; real teams never do."],
		["prize", "You have won 1,000,000 gold!", "It offers a prize you never entered."],
		["link", "log-in-here.biz/claim", "The link goes to a strange website."]]
	var safe_lines: Array = [["Zara", "Our castle", "See you at the castle after school!"],
		["Bram", "Your drawing", "I liked your dragon drawing in class."], ["Mimi", "Book club", "The next book is about owls."]]
	if level == 3:
		GenKit.shuffle(rng, clues)
		var clue: Array = clues[0]
		var pic := _phish_picture([clue])
		var right := str(clue[2])
		var wrongs: Array = ["It has a subject line.", "It is written in English.", "It came in the morning."]
		var ex3 := K.choice(rng, "Which is the clue that this email is a trick?", right, wrongs,
			"Look for something that rushes you, asks for secrets, looks too good, or comes from an odd address or link.",
			"%s Delete it and tell a trusted adult." % right, pic)
		ex3.data = {"clues": [clue[0]]}
		return ex3
	var trick := rng.randi() % 2 == 0
	if not trick:
		var s: Array = safe_lines[rng.randi_range(0, safe_lines.size() - 1)]
		var ex_safe := K.truefalse("This email is from a friend in your class. True or false: it shows clues of a trick.",
			false, "Clues: a stranger's address, a rush, a prize, a request for your password or a strange link.",
			"False: it comes from someone you know and asks for nothing. Still never share your password.",
			{"kind": "phish_mail", "from": s[0], "subject": s[1], "lines": [s[2]]})
		ex_safe.data = {"clues": []}
		return ex_safe
	GenKit.shuffle(rng, clues)
	var used: Array = clues.slice(0, 3 if level == 1 else 2)
	var ex := K.truefalse("True or false: this email shows clues that it is a trick.", true,
		"Clues: a stranger's address, a rush, a prize, a request for your password or a strange link.",
		"True. %s" % " ".join(PackedStringArray(used.map(func(c: Array) -> String: return str(c[2])))), _phish_picture(used))
	var names: Array = []
	for c: Array in used:
		names.append(c[0])
	ex.data = {"clues": names}
	return ex


## Fine to share, or keep private? Level 1: 4 plain cases; level 2: 5; level 3: 6 with harder ones.
static func public_private(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var fine: Array = ["your favourite colour", "your buddy's name in the game", "a drawing of a dragon",
		"the book you are reading", "your favourite animal", "a joke you made up"]
	var private: Array = ["your home address", "your password", "your phone number", "your full birthday",
		"where you are right now", "your school's name"]
	if level == 3:
		fine.append_array(["your game nickname", "a photo of your pet's toy"])
		private.append_array(["a photo in school uniform", "a photo of your street"])
	GenKit.shuffle(rng, fine)
	GenKit.shuffle(rng, private)
	var n: int = [0, 4, 5, 6][level]
	var k := n / 2
	var items: Array = []
	for i in k:
		items.append([fine[i], 0])
	for i in n - k:
		items.append([private[i], 1])
	GenKit.shuffle(rng, items)
	var ex := {"type": "sort", "prompt": "Sort these: fine to share in a game, or keep private?",
		"groups": ["fine to share", "keep private"], "items": items.map(func(it: Array) -> String: return str(it[0])),
		"answer": items.map(func(it: Array) -> int: return int(it[1])),
		"hint": "Could a stranger use it to find you, or get into your account? Then it stays private.",
		"explain": "Private: %s. They could lead a stranger to you or into your account." % _and(items.filter(func(it: Array) -> bool:
			return int(it[1]) == 1).map(func(it: Array) -> String: return str(it[0])))}
	ex.data = {"items": items}
	return ex


## What a computer learned from its examples: every example in one group shares a colour (or a shape) that no
## example in the other has. Level 1: a colour; level 2: a shape; level 3: a colour, and the new one is a shape it
## has only seen in the other group.
static func ai_guess(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var shapes: Array = SchoolPictureG6Arts.SHAPES.duplicate()
	var colours: Array = ["red", "blue", "green", "yellow", "purple", "orange"]
	GenKit.shuffle(rng, shapes)
	GenKit.shuffle(rng, colours)
	var by_colour := level != 2
	var labels: Array = [["yes", "no"], ["blip", "blop"], ["team A", "team B"], ["keep", "skip"]][rng.randi_range(0, 3)]
	var examples: Array = []
	var key: String = str(colours[0]) if by_colour else str(shapes[0])
	for i in 3:   # the first group: all share the key
		if by_colour:
			examples.append([shapes[i], colours[0], labels[0]])
		else:
			examples.append([shapes[0], colours[i], labels[0]])
	for i in 3:   # the other group: never the key
		if by_colour:
			examples.append([shapes[(i + 1) % 4], colours[1 + i], labels[1]])
		else:
			examples.append([shapes[1 + i], colours[(i + 2) % 6], labels[1]])
	var yes := rng.randi() % 2 == 0
	var new: Array = []
	if by_colour and level == 3:   # a twist: a shape only the other group had, or the first group's shape
		new = [shapes[3], colours[0]] if yes else [shapes[0], colours[4 + rng.randi_range(0, 1)]]
	elif by_colour:
		new = [shapes[rng.randi_range(0, 3)], colours[0] if yes else colours[4 + rng.randi_range(0, 1)]]
	else:
		new = [shapes[0] if yes else shapes[1 + rng.randi_range(0, 2)], colours[rng.randi_range(0, 5)]]
	var said := str(labels[0]) if yes else str(labels[1])
	var feature := "colour" if by_colour else "shape"
	if not by_colour:
		key = "a " + key
	var ex := K.choice(rng, "A computer learned from these examples. What will it say about the new one?", said,
		[labels[1] if yes else labels[0]],
		"Find what every example in one group has in common, but the other group never has. Does the new one have it?",
		"Every %s example is %s. The new one %s, so the computer says %s." % [labels[0], key, ("is " + key) if yes else
			("is not " + key), said] + (" It learned the colour, not the shape." if level == 3 else ""),
		{"kind": "ai_examples", "examples": examples, "new": new})
	ex.data = {"examples": examples, "new": new, "feature": feature}
	return ex


# --- Art -------------------------------------------------------------------------------------------------------------

## Regular shapes round a point (360°). Level 1: how many squares, triangles or hexagons fit; level 2: a regular
## shape's angle; level 3: what gap two octagons leave, or whether a shape fits.
static func tile_angles(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var pick: Array = [["square", 4, 90, "squares"], ["triangle", 3, 60, "equilateral triangles"],
				["hexagon", 6, 120, "regular hexagons"]][rng.randi_range(0, 2)]
			ex = K.number("How many %s fit round one point with no gaps?" % pick[3], 360 / int(pick[2]),
				"The angles round a point add up to 360°. Divide by one shape's angle.",
				"Each angle is %d°: 360 ÷ %d = %d." % [pick[2], pick[2], 360 / int(pick[2])],
				{"kind": "tessellation", "shape": pick[0]})
			ex.data = {"sides": pick[1]}
		2:
			var sides: int = [3, 4, 5, 6, 8, 10, 12][rng.randi_range(0, 6)]
			var angle := 180 * (sides - 2) / sides
			ex = K.number("What is each angle of a regular shape with %d sides?" % sides, angle,
				"A shape with n sides has angles adding to (n − 2) × 180°. Share that among its n angles.",
				"(%d − 2) × 180 = %d°, and %d ÷ %d = %d°." % [sides, (sides - 2) * 180, (sides - 2) * 180, sides, angle])
			ex.data = {"sides": sides}
		_:
			if rng.randi() % 2 == 0:
				ex = K.number("Two regular octagons (135° each) meet at a point. How many degrees are left for another tile?",
					90, "Round a point makes 360°. Take away the two octagons' angles.",
					"135 + 135 = 270, and 360 − 270 = 90°: a square fits the gap.", {"kind": "tessellation", "shape": "octagon"})
				ex.data = {"sides": 8}
			else:
				var sides: int = [3, 4, 5, 6, 8, 10][rng.randi_range(0, 5)]
				var angle := 180 * (sides - 2) / sides
				var fits := 360 % angle == 0
				ex = K.truefalse("True or false: regular shapes with %d sides (each angle %d°) tessellate on their own." % [
					sides, angle], fits, "They fit when their angle goes into 360 a whole number of times.",
					("True: 360 ÷ %d = %d, so %d fit round a point." % [angle, 360 / angle, 360 / angle]) if fits else
					("False: 360 ÷ %d is not a whole number, so gaps are left." % angle))
				ex.data = {"sides": sides}
	return ex


## Rotational symmetry. Level 1: the order (count the copies); level 2: the angle of each turn; level 3: the order from
## the angle.
static func turn_angle(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var orders: Array[int] = [2, 3, 4, 5, 6, 8, 9, 10, 12]
	var order := orders[rng.randi_range(0, orders.size() - 1)]
	var motif: String = SchoolPictureG6Arts.MOTIFS[rng.randi_range(0, SchoolPictureG6Arts.MOTIFS.size() - 1)]
	var pic := {"kind": "rotation_motif", "order": order, "motif": motif, "mark": level == 2}
	var ex := {}
	match level:
		1:
			ex = K.number("What is the order of rotational symmetry of this pattern?", order,
				"Count how many times it fits onto itself in one full turn: one for each copy of the shape.",
				"The shape is there %d times, so it fits onto itself %d times: order %d." % [order, order, order], pic)
		2:
			ex = K.number("What angle does this pattern turn through to fit onto itself (the smallest turn)?", 360 / order,
				"A full turn is 360°. Share it by the number of copies.",
				"%d copies: 360 ÷ %d = %d°." % [order, order, 360 / order], pic)
		_:
			ex = K.number("A pattern fits onto itself every %d°. What is its order of rotational symmetry?" % (360 / order),
				order, "How many of those turns make a full turn of 360°?",
				"360 ÷ %d = %d, so it has order %d." % [360 / order, order, order])
	ex.data = {"order": order}
	return ex


## A layered print's colours, lightest first (each layer prints over the one before). Level 1: 3 colours; level 2: 4;
## level 3: 5.
static func print_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ladders: Array = [["cream", "yellow", "orange", "red", "dark red"], ["light grey", "grey", "dark grey", "black"],
		["light blue", "blue", "dark blue", "black"], ["light green", "yellow-green", "green", "dark green"],
		["cream", "light orange", "orange", "dark orange", "black"]]
	var n: int = [0, 3, 4, 5][level]
	var fits: Array = ladders.filter(func(l: Array) -> bool: return l.size() >= n)
	var ladder: Array = fits[rng.randi_range(0, fits.size() - 1)]
	var keep: Array = range(ladder.size())
	GenKit.shuffle(rng, keep)
	keep = keep.slice(0, n)
	keep.sort()
	var colours: Array = keep.map(func(i: int) -> String: return str(ladder[i]))
	var ex := K.order(rng, "Put the inks in the order to print them, first to last.", colours,
		"Print the lightest colour first: a darker ink covers a lighter one, but not the other way round.",
		"Lightest to darkest: %s." % ", ".join(PackedStringArray(colours)),
		{"kind": "print_layers", "layers": colours.slice(0, mini(4, colours.size())), "view": "final"})
	ex.data = {"colours": colours}
	return ex


## Numbers in nature. Level 1: the next Fibonacci number; level 2: a seed head's spirals come in two Fibonacci numbers
## side by side; level 3: the angle between stones in a ring.
static func nature_numbers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var fib: Array[int] = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144]
	var ex := {}
	match level:
		1:
			var at := rng.randi_range(4, 8)
			var run: Array[String] = []
			for i in range(at - 4, at):
				run.append(str(fib[i]))
			ex = K.number("What comes next? %s, …" % ", ".join(run), fib[at],
				"Each number is the two before it added together.",
				"%d + %d = %d." % [fib[at - 2], fib[at - 1], fib[at]])
			ex.data = {"run": fib.slice(at - 4, at)}
		2:
			var at := rng.randi_range(5, 9)
			var what: String = ["sunflower's seed head", "pine cone", "daisy's middle"][rng.randi_range(0, 2)]
			ex = K.number("A %s has %d spirals one way and more the other way: the next Fibonacci number. How many?" % [
				what, fib[at]], fib[at + 1],
				"In the Fibonacci numbers (1, 1, 2, 3, 5, 8 …), each is the two before it added.",
				"Before %d comes %d, so the next is %d + %d = %d." % [fib[at], fib[at - 1], fib[at - 1], fib[at], fib[at + 1]],
				{"kind": "land_art", "design": "seeds", "material": "petals"})
			ex.data = {"spirals": fib[at]}
		_:
			var n: int = [6, 8, 9, 10, 12, 15, 18, 20, 24, 30, 36][rng.randi_range(0, 10)]
			ex = K.number("%s lays %d stones evenly round a circle. What angle is there between two stones next to each other, from the middle?" % [
				NAMES[rng.randi_range(0, NAMES.size() - 1)], n], 360 / n,
				"All the way round the middle is 360°. Share it equally between the gaps.",
				"%d stones make %d gaps: 360 ÷ %d = %d°." % [n, n, n, 360 / n],
				{"kind": "land_art", "design": "circle", "material": "stones"})
			ex.data = {"stones": n}
	return ex


## The four steps of looking at art, about The Great Wave. Level 1: describe or analyse (4 sentences); level 2:
## describe, analyse or interpret (5); level 3: analyse, interpret or judge (6).
static func critique_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var bank := {
		"describe": ["There is a huge blue wave.", "Three long boats are under the wave.", "A small mountain is far away.",
			"The sky is a pale yellow."],
		"analyse": ["The wave's curve leads your eye to the mountain.", "Blue and white make strong contrast.",
			"The big wave makes the mountain look tiny.", "The foam's claws repeat, giving rhythm."],
		"interpret": ["It shows how small people are next to nature.", "The wave is about to crash, so it feels tense.",
			"The boatmen seem brave as they hold on."],
		"judge": ["I think it works: my eye keeps moving round it.", "In my view the contrast makes it powerful.",
			"I think it is great because it feels alive."]}
	var groups: Array = [["describe", "analyse"], ["describe", "analyse", "interpret"], ["analyse", "interpret", "judge"]][level - 1]
	var n: int = [0, 4, 5, 6][level]
	var items: Array = []
	var gi := 0
	var pools := {}
	for g: String in groups:
		var pool: Array = (bank[g] as Array).duplicate()
		GenKit.shuffle(rng, pool)
		pools[g] = pool
	var taken := {}
	while items.size() < n:
		var g := str(groups[gi % groups.size()])
		var k := int(taken.get(g, 0))
		if k < (pools[g] as Array).size():
			items.append([pools[g][k], gi % groups.size()])
			taken[g] = k + 1
		gi += 1
	GenKit.shuffle(rng, items)
	var ex := {"type": "sort", "prompt": "Looking at The Great Wave: sort each sentence into its step.",
		"groups": groups, "items": items.map(func(it: Array) -> String: return str(it[0])),
		"answer": items.map(func(it: Array) -> int: return int(it[1])),
		"hint": "Describe says what you see; analyse how it is made; interpret what it means or feels like; judge what you think of it and why.",
		"explain": "Describe is what is there, analyse is how the artist used line, colour and shape, interpret is the meaning or feeling, and judge is your opinion with a reason."}
	ex.data = {"items": items, "groups": groups}
	return ex


## Which principle a design shows. Level 1: four that look very different; level 2: more; level 3: the kinds of balance,
## or unity against variety.
static func principle_spot(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var sets: Array = [["symmetry", "emphasis", "pattern", "contrast"], ["rhythm", "movement", "radial", "emphasis", "pattern",
		"contrast"], ["symmetry", "asymmetry", "radial", "unity", "variety"]]
	var pool: Array = sets[level - 1]
	var show := str(pool[rng.randi_range(0, pool.size() - 1)])
	var words := {"symmetry": "symmetrical balance", "asymmetry": "asymmetrical balance", "radial": "radial balance",
		"contrast": "contrast", "emphasis": "emphasis", "rhythm": "rhythm", "unity": "unity", "variety": "variety",
		"movement": "movement", "pattern": "pattern"}
	var why := {"symmetry": "the two halves mirror each other", "asymmetry": "one big shape is balanced by several small ones",
		"radial": "everything spreads out from the middle", "contrast": "dark and light, big and small sit side by side",
		"emphasis": "one shape stands out as the focal point", "rhythm": "shapes repeat with a regular beat",
		"unity": "different shapes share one family of colours", "variety": "every shape, colour and size is different",
		"movement": "a curve leads your eye across", "pattern": "one motif repeats in rows"}
	var wrongs: Array = []
	for p: Variant in pool:
		if str(p) != show and wrongs.size() < 3:
			wrongs.append(words[p])
	var ex := K.choice(rng, "Which principle of design does this show most?", words[show], wrongs,
		"Look for what the artist did on purpose: mirror, balance, repeat, contrast, a focal point, or a path for the eye?",
		"It shows %s: %s." % [words[show], why[show]], {"kind": "art_principle", "show": show})
	ex.data = {"show": show}
	return ex


# --- Music -----------------------------------------------------------------------------------------------------------

const LETTERS := "CDEFGAB"
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const MAJOR: Array[int] = [2, 2, 1, 2, 2, 2, 1]
const ORDINAL: Array[String] = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"]


## A major scale's notes as names ("F sharp", "B flat"), home to home.
static func _scale_names(key: String) -> Array[String]:
	var out: Array[String] = []
	var at := posmod(int(SEMIS[key.left(1)]) - (1 if key.ends_with("b") else 0), 12)
	var li := LETTERS.find(key.left(1))
	for i in 8:
		var letter := LETTERS[(li + i) % 7]
		var diff := posmod(at - int(SEMIS[letter]) + 6, 12) - 6
		out.append(letter + (" sharp" if diff == 1 else (" flat" if diff == -1 else "")))
		if i < 7:
			at = posmod(at + MAJOR[i], 12)
	return out


## Major scales. Level 1: which note is sharp or flat in G, D or F major; level 2: the key a signature shows, or a
## scale's nth note; level 3: how many sharps or flats, or a step's semitones.
static func scale_notes(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var keys: Array = ["G", "D", "F"] if level == 1 else ["C", "G", "D", "A", "F", "Bb"]
	var key := str(keys[rng.randi_range(0, keys.size() - 1)])
	var names := _scale_names(key)
	var kname := key.replace("b", " flat")
	var changed: Array[String] = []
	for n in names.slice(0, 7):
		if n.contains(" "):
			changed.append(n)
	var ex := {}
	match level:
		1:
			var right := changed[0] if changed.size() == 1 else _and(changed)
			var wrongs: Array = ["B flat", "F sharp", "C sharp", "E flat", "no sharps or flats"].filter(func(w: String) -> bool:
				return w != right and not changed.has(w))
			ex = K.choice(rng, "Which note of the %s major scale is sharp or flat?" % kname, right, wrongs.slice(0, 3),
				"Build it from %s with the steps tone, tone, semitone, tone, tone, tone, semitone." % kname,
				"The %s major scale is %s: it needs %s." % [kname, ", ".join(names), right])
			ex.data = {"key": key}
		2:
			if rng.randi() % 2 == 0:
				var others: Array = ["C", "G", "D", "A", "F", "Bb"].filter(func(k: String) -> bool: return k != key)
				GenKit.shuffle(rng, others)
				ex = K.choice(rng, "Which major key has this key signature?", kname + " major", others.slice(0, 3).map(
					func(k: String) -> String: return k.replace("b", " flat") + " major"),
					"None is C. Sharps come F, C, G: one is G, two D, three A. Flats come B, E: one is F, two B flat.",
					"%s: %s major." % [("It has " + _and(changed)) if not changed.is_empty() else "It has no sharps or flats",
						kname], {"kind": "key_signature", "key": key})
				ex.data = {"key": key}
			else:
				var i := rng.randi_range(1, 6)
				var right := names[i]
				var wrongs: Array = []
				for w in [names[(i + 1) % 7], names[i - 1], LETTERS[(LETTERS.find(right.left(1)) + 2) % 7],
						right.left(1) if right.contains(" ") else right + " sharp"]:
					if w != right and not wrongs.has(w):
						wrongs.append(w)
				ex = K.choice(rng, "What is the %s note of the %s major scale?" % [ORDINAL[i], kname], right, wrongs.slice(0, 3),
					"Count up from %s as the 1st, using the scale's steps (T T S T T T S)." % kname,
					"The %s major scale is %s, so the %s note is %s." % [kname, ", ".join(names), ORDINAL[i], right])
				ex.data = {"key": key, "degree": i}
		_:
			if rng.randi() % 2 == 0:
				var count := changed.size()
				ex = K.number("How many sharps or flats does %s major have?" % kname, count,
					"Build the scale from %s with T T S T T T S and count the notes that are not white keys." % kname,
					"%s major is %s: %d." % [kname, ", ".join(names), count])
				ex.data = {"key": key}
			else:
				var i := rng.randi_range(0, 6)
				ex = K.number("In %s major, how many semitones is it from the %s note up to the %s?" % [kname, ORDINAL[i],
					ORDINAL[i + 1]], MAJOR[i],
					"Every major scale steps tone, tone, semitone, tone, tone, tone, semitone. A tone is 2 semitones.",
					"%s up to %s is step %d of T T S T T T S: %s, %d semitone%s." % [names[i], names[i + 1], i + 1,
						"a tone" if MAJOR[i] == 2 else "a semitone", MAJOR[i], "s" if MAJOR[i] == 2 else ""])
				ex.data = {"key": key, "step": i}
	return ex


## Intervals. Level 1: up from C on a keyboard; level 2: two notes on the stave; level 3: heard.
static func interval_size(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array[String] = ["unison", "second", "third", "fourth", "fifth", "sixth", "seventh", "octave"]
	var steps: Array = [1, 2, 3, 4, 5, 7] if level < 3 else [1, 2, 4, 7]
	var s := int(steps[rng.randi_range(0, steps.size() - 1)])
	var low_i := 0 if level == 1 else rng.randi_range(0, 12 - s)
	var stave: Array[String] = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5", "A5"]
	if level == 3:
		low_i = rng.randi_range(0, 5)
	var low := stave[low_i]
	var high := stave[low_i + s]
	var letters: Array[String] = []
	for i in range(low_i, low_i + s + 1):
		letters.append(stave[i].left(1))
	var right := names[s]
	var work := "Count the letters, both ends too: %s is %d letters, %s %s." % [", ".join(letters), s + 1,
		"an" if s == 7 else "a", right]
	var ex := {}
	match level:
		1, 2:
			var pool: Array = names.slice(1, 8)
			pool.erase(right)
			GenKit.shuffle(rng, pool)
			var pic := {"kind": "keyboard", "mark": [low, high], "names": true, "keys": 8 if s < 7 else 9} if level == 1 else \
				{"kind": "stave", "notes": [low, high]}
			ex = K.choice(rng, "What interval is it from the lower note up to the higher one?", right, pool.slice(0, 3),
				"Count the letter names from the lower note to the higher one, counting both.", work, pic)
		_:
			var choices: Array = ["a step", "a third", "a fifth", "an octave"]
			var said: String = {1: "a step", 2: "a third", 4: "a fifth", 7: "an octave"}[s]
			var wrongs: Array = choices.filter(func(c: String) -> bool: return c != said)
			ex = K.choice(rng, "Listen: two notes, low then high. Is the jump a step, a third, a fifth or an octave?", said,
				wrongs, "A step is the next note; a third skips one; a fifth is the start of Twinkle, Twinkle's jump; an octave is the same note higher.",
				"It went from %s up to %s. %s" % [low.left(1), high.left(1), work])
			ex.sound = {"kind": "notes", "notes": [low + ":2", high + ":2"]}
	ex.data = {"low": low, "high": high}
	return ex


## The 12-bar blues. Level 1: the chord in a bar (in C); level 2: in G, D, A or E; level 3: its bars and beats.
static func blues_bar(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		var times := rng.randi_range(2, 5)
		if rng.randi() % 2 == 0:
			var ex := K.number("A blues song goes round the 12-bar blues %d times. How many bars is that?" % times, 12 * times,
				"Each time round is 12 bars.", "%d × 12 = %d bars." % [times, 12 * times])
			ex.data = {"times": times, "beats": 1}
			return ex
		var ex2 := K.number("Each bar of a 12-bar blues has 4 beats. How many beats are %d times round?" % times, 48 * times,
			"One time round is 12 bars of 4 beats. Multiply by the times round.",
			"12 × 4 = 48 beats a time round, and %d × 48 = %d." % [times, 48 * times])
		ex2.data = {"times": times, "beats": 4}
		return ex2
	var keys: Array = ["C"] if level == 1 else ["G", "D", "A", "E"]
	var key := str(keys[rng.randi_range(0, keys.size() - 1)])
	var chords := SchoolPictureG6Arts.twelve_bar_chords(key)
	var bar := rng.randi_range(4, 11)
	var right := chords[bar]
	var others: Array = [chords[0], chords[4], chords[8]].filter(func(c: String) -> bool: return c != right)
	var extra := LETTERS[(LETTERS.find(key) + 1) % 7]
	others.append(extra)
	var roman := "I" if right == key else ("IV" if right == chords[4] else "V")
	var ex3 := K.choice(rng, "Which chord goes in bar %d of this 12-bar blues in %s?" % [bar + 1, key], right, others,
		"The pattern is I I I I, IV IV I I, V IV I I. Count up from %s to find IV (4th note) and V (5th)." % key,
		"Bar %d is chord %s: in %s that is %s." % [bar + 1, roman, key, right],
		{"kind": "twelve_bar", "key": key, "hide": [bar], "mark": bar})
	ex3.data = {"key": key, "bar": bar}
	return ex3


## The periods of music. Level 1: Medieval, Renaissance or Baroque; level 2: with the Classical period; level 3: from a
## composer's music.
static func music_period(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var periods: Array[String] = ["Medieval", "Renaissance", "Baroque", "Classical"]
	if level < 3:
		var ranges: Array = [[900, 1380], [1420, 1580], [1620, 1730], [1770, 1810]]
		var p := rng.randi_range(0, 2 if level == 1 else 3)
		var year := rng.randi_range(int(ranges[p][0]), int(ranges[p][1]))
		var pool: Array = periods.slice(0, 3 if level == 1 else 4)
		var ex := K.choice(rng, "Music written in %d belongs to which period?" % year, periods[p],
			pool.filter(func(x: String) -> bool: return x != periods[p]),
			"Medieval is up to about 1400, the Renaissance about 1400-1600, the Baroque 1600-1750, then the Classical period.",
			"%d is in the %s period (%s)." % [year, periods[p], ["about 500-1400", "about 1400-1600", "1600-1750",
				"1750-1820"][p]])
		ex.data = {"year": year}
		return ex
	var who: Array = [["Hildegard of Bingen", 1150, 0], ["Guillaume de Machaut", 1360, 0], ["Thomas Tallis", 1560, 1],
		["Giovanni da Palestrina", 1570, 1], ["William Byrd", 1590, 1], ["Claudio Monteverdi", 1610, 2],
		["Antonio Vivaldi", 1720, 2], ["Johann Sebastian Bach", 1730, 2], ["Joseph Haydn", 1790, 3],
		["Wolfgang Amadeus Mozart", 1785, 3]]
	var pick: Array = who[rng.randi_range(0, who.size() - 1)]
	var right := periods[int(pick[2])]
	var ex3 := K.choice(rng, "%s wrote music around %d. Which period is that?" % [pick[0], pick[1]], right,
		periods.filter(func(x: String) -> bool: return x != right),
		"Place the year: up to about 1400 Medieval, 1400-1600 Renaissance, 1600-1750 Baroque, 1750-1820 Classical.",
		"Around %d is the %s period." % [pick[1], right])
	ex3.data = {"year": pick[1]}
	return ex3


## Off-beat claps. Level 1: count the claps off the beat (on an "and"); level 2 and 3: copy a syncopated rhythm.
static func offbeat_rhythm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var easy: Array = ["x--x--x-", "x--x-x--", "x-x--x-x", "x--xx-x-", "x-xx-x-x"]
	var busy: Array = ["xx-x-xx-", "x--x--xx", "x-xx-xx-", "xx--xx-x", "x-x-xx-x"]
	var bank: Array = easy if level == 2 else (busy if level == 3 else easy + busy)
	var pattern := str(bank[rng.randi_range(0, bank.size() - 1)])
	var boxes: Array[String] = []
	var off: Array[String] = []
	for i in pattern.length():
		if pattern[i] == "x":
			boxes.append(str(i + 1))
			if i % 2 == 1:
				off.append(str(i + 1))
	if level == 1:
		var ex := K.number("The beats are counted 1 & 2 & 3 & 4 &. How many claps are off the beat, on an &?", off.size(),
			"The beats are boxes 1, 3, 5 and 7. The &s between them are boxes 2, 4, 6 and 8.",
			"The claps are in boxes %s; the ones on an & are %s: %d." % [_and(boxes), _and(off) if not off.is_empty() else
				"none", off.size()], {"kind": "beat_grid", "rows": [["claps", pattern]], "count": true})
		ex.data = {"pattern": pattern}
		return ex
	var tempo := rng.randi_range(70, 90) if level == 2 else rng.randi_range(90, 110)
	var ex2 := {"type": "rhythm", "prompt": "Listen, then copy this off-beat rhythm: mark every box with a clap.",
		"hint": "Count 1 & 2 & 3 & 4 & as you listen. Some claps land on the &s, between the beats.",
		"explain": "The claps are in %s %s." % ["box" if boxes.size() == 1 else "boxes", _and(boxes)],
		"sound": {"kind": "rhythm", "pattern": pattern, "tempo": tempo}}
	ex2.data = {"pattern": pattern}
	return ex2


## Theme and variations, heard: a theme, a rest, then a variation. Level 1: the rhythm or the pitch (an octave up)
## changes; level 2: or major turns minor; level 3: or it goes backwards.
static func variation_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var themes: Array = [["C4", "E4", "G4", "E4"], ["C4", "D4", "E4", "C4"], ["G4", "E4", "C4", "E4"], ["C4", "E4", "D4", "G4"],
		["E4", "G4", "C5", "G4"]]
	var theme: Array = themes[rng.randi_range(0, themes.size() - 1)]
	var kinds: Array[String] = ["rhythm", "higher"]
	if level >= 2:
		kinds.append("minor")
	if level == 3:
		kinds.append("backwards")
	var change := kinds[rng.randi_range(0, kinds.size() - 1)]
	var variation: Array = []
	match change:
		"rhythm":
			variation = [str(theme[0]) + ":2", theme[1], str(theme[2]) + ":2", theme[3]]
		"higher":
			variation = theme.map(func(n: String) -> String: return n.left(1) + str(int(n.right(1)) + 1))
		"minor":
			variation = theme.map(func(n: String) -> String: return ("Eb" + n.right(1)) if n.left(1) == "E" else n)
		_:
			variation = theme.duplicate()
			variation.reverse()
	if change == "minor" and variation == theme:
		variation = theme.map(func(n: String) -> String: return n.left(1) + str(int(n.right(1)) + 1))
		change = "higher"
	if change == "backwards" and variation == theme:
		variation = [str(theme[0]) + ":2", theme[1], str(theme[2]) + ":2", theme[3]]
		change = "rhythm"
	var said := {"rhythm": "the rhythm (the notes' lengths)", "higher": "the pitch: the same tune higher",
		"minor": "the harmony: major to minor", "backwards": "the order: it goes backwards"}
	var wrongs: Array = []
	for k: String in ["rhythm", "higher", "minor", "backwards"]:
		if k != change and (kinds.has(k) or wrongs.size() < 1):
			wrongs.append(said[k])
	var why := {"rhythm": "the same notes come back, but some are held twice as long",
		"higher": "every note moves up an octave, the same shape higher", "minor": "E becomes E flat, so major turns minor",
		"backwards": "the same notes come in the opposite order"}
	var ex := K.choice(rng, "Listen: a theme, a short rest, then a variation of it. What changed?", said[change], wrongs,
		"Hum the theme, then compare: are the notes the same? The lengths? The mood? The order?",
		"The %s: %s." % [{"rhythm": "rhythm", "higher": "pitch", "minor": "harmony", "backwards": "order"}[change],
			why[change]])
	var notes: Array = theme.duplicate()
	notes.append("-")
	notes.append_array(variation)
	ex.sound = {"kind": "notes", "notes": notes}
	ex.data = {"theme": theme, "variation": variation, "change": change}
	return ex


## The chord that fits a melody: every note of the melody belongs to the chord. Level 1: one note in C major (chords
## C, F, G); level 2: a bar of 2-3 notes in C major; level 3: a bar in G major (chords G, C, D).
static func chord_fit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var key := "G" if level == 3 else "C"
	var chords: Dictionary = {"C": ["C", "E", "G"], "F": ["F", "A", "C"], "G": ["G", "B", "D"]} if key == "C" else \
		{"G": ["G", "B", "D"], "C": ["C", "E", "G"], "D": ["D", "F#", "A"]}
	var names: Array = chords.keys()
	var chord := str(names[rng.randi_range(0, 2)])
	var own: Array = (chords[chord] as Array).duplicate()
	var unique: Array = own.filter(func(n: String) -> bool:
		var count := 0
		for c: String in chords:
			if (chords[c] as Array).has(n):
				count += 1
		return count == 1)
	var notes: Array = []
	if level == 1:
		notes = [unique[rng.randi_range(0, unique.size() - 1)]]
	else:
		GenKit.shuffle(rng, own)
		notes = [unique[0]]
		for n: Variant in own:
			if notes.size() < rng.randi_range(2, 3) and not notes.has(n):
				notes.append(n)
		GenKit.shuffle(rng, notes)
	var octave := func(n: String) -> String: return n.replace("#", "") + "4"
	var said := _and(notes.map(func(n: String) -> String: return n.replace("#", " sharp")))
	var pic := {}
	if level == 3:
		pic = {"kind": "key_signature", "key": "G", "notes": notes.map(octave), "names": true}
	else:
		pic = {"kind": "stave", "notes": notes.map(octave), "names": true}
	var ex := K.choice(rng, "Which chord fits under %s?" % ("this note" if notes.size() == 1 else "this bar of melody"),
		chord, names.filter(func(c: String) -> bool: return c != chord),
		"A chord fits when the melody's notes are in it. The chords here: %s." % "; ".join(PackedStringArray(names.map(
			func(c: String) -> String: return "%s is %s" % [c, _and((chords[c] as Array).map(func(n: String) -> String:
				return n.replace("#", " sharp")))]))),
		"%s %s in the %s chord (%s)." % [said, ["", "is", "are both", "are all"][notes.size()], chord, _and((chords[chord] as Array).map(
			func(n: String) -> String: return n.replace("#", " sharp")))], pic)
	ex.data = {"key": key, "notes": notes, "chord": chord}
	return ex


## Instruments of the world. Level 1: what makes the sound; level 2: the family's name; level 3: where it comes from.
static func instrument_family(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var table: Array = [["sitar", 0, "India"], ["koto", 0, "Japan"], ["kora", 0, "West Africa"], ["erhu", 0, "China"],
		["djembe", 1, "West Africa"], ["tabla", 1, "India"], ["bodhran", 1, "Ireland"], ["bagpipes", 2, "Scotland"],
		["didgeridoo", 2, "northern Australia"], ["shakuhachi", 2, "Japan"], ["steelpan", 3, "Trinidad and Tobago"],
		["balafon", 3, "West Africa"], ["gamelan gong", 3, "Indonesia"]]
	var pick: Array = table[rng.randi_range(0, table.size() - 1)]
	var fam := int(pick[1])
	var many := str(pick[0]) == "bagpipes"   # "the bagpipes are", not "is"
	var how: Array[String] = ["strings that vibrate", "a stretched skin that vibrates", "air that vibrates in a tube",
		"the instrument itself vibrates"]
	var fams: Array[String] = ["chordophone", "membranophone", "aerophone", "idiophone"]
	var pic := {}
	if SchoolPictureG6Arts.INSTRUMENTS.has(str(pick[0])):
		pic = {"kind": "world_instrument", "what": pick[0]}
	var ex := {}
	match level:
		1:
			ex = K.choice(rng, ("How do the %s make their sound?" if many else "How does the %s make its sound?") % pick[0],
				how[fam], how.filter(func(h: String) -> bool: return h != how[fam]),
				"Look at it: strings, a skin, a tube to blow, or something hard to hit?",
				"The %s%s sound comes from %s." % [pick[0], "'" if many else "'s", how[fam]], pic)
		2:
			ex = K.choice(rng, ("Which family are the %s in?" if many else "Which family is the %s in?") % pick[0], fams[fam],
				fams.filter(func(f: String) -> bool:
				return f != fams[fam]),
				"Chordo- means strings, membrano- a skin, aero- air, and idio- the instrument itself.",
				"The %s%s sound comes from %s, so %s %s." % [pick[0], "'" if many else "'s", how[fam],
					"they are" if many else "it is", ("an " if fams[fam].begins_with("a") or fams[fam].begins_with("i") else "a ")
					+ fams[fam] + ("s" if many else "")], pic)
		_:
			var places: Array = ["India", "Japan", "West Africa", "China", "Ireland", "Scotland", "northern Australia",
				"Trinidad and Tobago", "Indonesia"]
			places.erase(str(pick[2]))
			GenKit.shuffle(rng, places)
			ex = K.choice(rng, ("Where do the %s come from?" if many else "Where does the %s come from?") % pick[0], pick[2],
				places.slice(0, 3), "Think of the lesson's map: which country or region is each instrument played in?",
				"The %s %s from %s." % [pick[0], "come" if many else "comes", pick[2]], pic)
	ex.data = {"instrument": pick[0], "family": fam, "place": pick[2]}
	return ex


## Sound in numbers. Level 1: an octave doubles (or halves) the frequency; level 2: vibrations in some seconds; level 3:
## how far away the thunder is.
static func sound_numbers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var f: int = [110, 220, 440, 131, 262, 196, 330][rng.randi_range(0, 6)]
			if rng.randi() % 2 == 0:
				ex = K.number("A note vibrates %d times a second (%d Hz). How many hertz is the note an octave higher?" % [f, f],
					f * 2, "An octave higher vibrates twice as fast.", "%d × 2 = %d Hz." % [f, f * 2])
				ex.data = {"hz": f, "up": true}
			else:
				ex = K.number("A note is %d Hz. How many hertz is the note an octave lower?" % (f * 2), f,
					"An octave lower vibrates half as fast.", "%d ÷ 2 = %d Hz." % [f * 2, f])
				ex.data = {"hz": f * 2, "up": false}
		2:
			var hz := rng.randi_range(2, 9) * 50
			var s := rng.randi_range(2, 5)
			ex = K.number("A string vibrates %s times in %d seconds. What is its frequency in hertz (vibrations a second)?" % [
				K.fmt(hz * s), s], hz, "Frequency is the vibrations in one second: share them by the seconds.",
				"%s ÷ %d = %d Hz." % [K.fmt(hz * s), s, hz])
			ex.data = {"count": hz * s, "seconds": s}
		_:
			var km := rng.randi_range(1, 6)
			ex = K.number("You see lightning, then count %d seconds to the thunder. Sound goes about 1 km in 3 seconds. How many km away is the storm?" % (
				km * 3), km, "Light arrives almost at once; the sound takes 3 seconds for each kilometre.",
				"%d ÷ 3 = %d km." % [km * 3, km])
			ex.data = {"seconds": km * 3}
	return ex


# --- helpers ---------------------------------------------------------------------------------------------------------

static func _bits(n: int, width: int) -> String:
	var s := ""
	for i in range(width - 1, -1, -1):
		s += "1" if (n >> i) & 1 == 1 else "0"
	return s


static func _reverse_bits(n: int, width: int) -> int:
	var out := 0
	for i in width:
		if (n >> i) & 1 == 1:
			out |= 1 << (width - 1 - i)
	return out


static func _place_values(width: int) -> Array[String]:
	var out: Array[String] = []
	for i in range(width - 1, -1, -1):
		out.append(str(1 << i))
	return out


## The place values of `n`'s 1s, biggest first ("16", "4", "2").
static func _place_parts(n: int, width: int) -> Array[String]:
	var out: Array[String] = []
	for i in range(width - 1, -1, -1):
		if (n >> i) & 1 == 1:
			out.append(str(1 << i))
	return out


static func _and(items: Array) -> String:
	var parts: Array[String] = []
	for it: Variant in items:
		parts.append(str(it))
	if parts.size() <= 1:
		return "".join(parts)
	return ", ".join(parts.slice(0, parts.size() - 1)) + " and " + parts[-1]


static func _twos(n: int) -> Array[String]:
	var out: Array[String] = []
	for i in n:
		out.append("2")
	return out


static func _tens(n: int) -> Array[String]:
	return _repeat("10", n)


static func _repeat(s: String, n: int) -> Array[String]:
	var out: Array[String] = []
	for i in n:
		out.append(s)
	return out


static func _doubling(bits: int) -> String:
	var parts: Array[String] = []
	for i in range(1, bits + 1):
		parts.append("%d bit%s %d" % [i, "" if i == 1 else "s", 1 << i])
	return ", ".join(parts)


static func _rgb_of(name: String) -> Vector3i:
	return {"red": Vector3i(1, 0, 0), "green": Vector3i(0, 1, 0), "blue": Vector3i(0, 0, 1)}[name]


static func _rgb_numbers(key: String) -> String:
	return "(%d, %d, %d)" % [255 if key[0] == "1" else 0, 255 if key[1] == "1" else 0, 255 if key[2] == "1" else 0]


static func _lights_on(key: String) -> String:
	var on: Array[String] = []
	for i in 3:
		if key[i] == "1":
			on.append(["red", "green", "blue"][i])
	if on.is_empty():
		return "every light is off"
	if on.size() == 3:
		return "red, green and blue all on"
	return _and(on) + (" light on" if on.size() == 1 else " light together")


## "score > 12": a comparison of `name` (whose value is `v`) with a number near it, true or false about half the time.
static func _comparison(rng: RandomNumberGenerator, name: String, v: int, ops: Array[String]) -> String:
	var op := ops[rng.randi_range(0, ops.size() - 1)]
	var n := maxi(0, v + rng.randi_range(-3, 3))
	if op == "=" and rng.randi() % 2 == 0:
		n = v
	return "%s %s %d" % [name, op, n]


static func _compare(v: int, comparison: String) -> bool:
	var parts := comparison.split(" ")
	var n := int(parts[2])
	match parts[1]:
		">":
			return v > n
		"<":
			return v < n
		"≥":
			return v >= n
		"≤":
			return v <= n
	return v == n


static func _tf(b: bool) -> String:
	return "true" if b else "false"


## A trick email built from its clues ([what, text, why]).
static func _phish_picture(clues: Array) -> Dictionary:
	var d := {"kind": "phish_mail", "from": "news@game-club.org", "subject": "News for players", "lines": ["Dear player,"]}
	for c: Array in clues:
		match str(c[0]):
			"from":
				d.from = str(c[1])
			"prize":
				d.subject = str(c[1])
			"link":
				d.link = str(c[1])
			_:
				(d.lines as Array).append(str(c[1]))
	return d
