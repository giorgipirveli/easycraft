class_name G8ArtsGen
extends RefCounted
## Owner #70, #73 and #111 (research §6.8): grade 8 computing, art and music generators: SchoolGen "g8c.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a
## strategy, never the answer), a worked answer and `data` (tests/unit/test_g8_arts_gen.gd works every answer out again:
## it runs every program with the tests' own text-code interpreter and has its own machine, character code, file size,
## circuit, query, nearest-point, percentage, password, energy, art, scale and music rules).
## - Computing: module_trace (programs of functions), step_count (algorithms' worst cases), state_next (a state
##   machine's events), model_keep (what a model keeps), machine_trace (a little machine's instructions), char_code
##   (ASCII codes), file_size (pictures, sounds and text in bits and bytes), gate_out (logic circuits), truth_rows
##   (truth tables), db_query (database queries), nearest_guess (a nearest-neighbour model), accuracy (a model's
##   percentages), password_space (how many passwords, guessing brakes), trick_sort (safe or a risk), user_test
##   (user tests' numbers), device_energy (watt-hours and kWh).

const K := preload("res://core/school/gen/gen_kit.gd")
const P := preload("res://ui/school/school_picture_g8arts.gd")
const FUNCS: Array[String] = ["boost", "change", "work", "step", "make"]

# --- Computing -------------------------------------------------------------------------------------------------------

## What a program of functions prints. Level 1: one function; level 2: a function that calls another; level 3: a function
## with an if called in a loop, or a function with a loop inside.
static func module_trace(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array = []
	var answer := 0
	var work := ""
	var hint := ""
	match level:
		1:
			var name := FUNCS[rng.randi_range(0, FUNCS.size() - 1)]
			var a := rng.randi_range(2, 12)
			var k := rng.randi_range(2, 9)
			var op := ["*", "+", "-"][rng.randi_range(0, 2)] as String
			if op == "-":
				a += k
			lines = ["def %s(n):" % name, "    return n %s %d" % [op, k], "print(%s(%d))" % [name, a]]
			answer = a * k if op == "*" else (a + k if op == "+" else a - k)
			work = "%s(%d) puts %d into n and returns %d %s %d = %d, so it prints %d." % [name, a, a, a,
				{"*": "×", "+": "+", "-": "−"}[op], k, answer, answer]
			hint = "Put the argument into n, then work out what the function returns."
		2:
			var p := rng.randi_range(2, 9)
			var q := rng.randi_range(2, 5)
			var v := rng.randi_range(2, 12)
			lines = ["def add(x):", "    return x + %d" % p, "def scale(x):", "    return add(x) * %d" % q,
				"print(scale(%d))" % v]
			answer = (v + p) * q
			work = "add(%d) returns %d + %d = %d, so scale returns %d × %d = %d." % [v, v, p, v + p, v + p, q, answer]
			hint = "Work out the inner call first, then use its answer in the outer function."
		_:
			if rng.randi() % 2 == 0:
				var t := rng.randi_range(5, 12)
				var big := rng.randi_range(3, 9)
				var small := rng.randi_range(1, 2)
				var nums: Array = []
				for i in 4:
					nums.append(rng.randi_range(1, 20))
				var said: Array[String] = []
				var parts: Array[String] = []
				for n: int in nums:
					said.append(str(n))
					var b := big if n > t else small
					parts.append(str(b))
					answer += b
				lines = ["def bonus(n):", "    if n > %d:" % t, "        return %d" % big, "    return %d" % small,
					"total = 0", "for s in [%s]:" % ", ".join(said), "    total = total + bonus(s)", "print(total)"]
				work = "Over %d gives %d, otherwise %d: %s = %d." % [t, big, small, " + ".join(parts), answer]
			else:
				var nums: Array = []
				var said: Array[String] = []
				var sum := 0
				for i in rng.randi_range(3, 4):
					var n := rng.randi_range(1, 9)
					nums.append(n)
					said.append(str(n))
					sum += n
				var k := rng.randi_range(2, 3)
				lines = ["def total(items):", "    s = 0", "    for i in items:", "        s = s + i", "    return s",
					"print(total([%s]) * %d)" % [", ".join(said), k]]
				answer = sum * k
				work = "total adds the list: %s = %d. Then %d × %d = %d." % [" + ".join(said), sum, sum, k, answer]
			hint = "Make a table: each value, what the function gives, and the total so far."
	var ex := K.number("What does this program print?", answer, hint, work, {"kind": "text_code", "lines": lines})
	ex.data = {"lines": lines}
	return ex


## Algorithms' worst cases. Level 1: linear search's checks; level 2: binary search's; level 3: bubble sort's
## comparisons n(n − 1) ÷ 2, or how many more checks linear search needs than binary search.
static func step_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var data := {}
	match level:
		1:
			var n := rng.randi_range(12, 500)
			ex = K.number("A linear search looks through %s unsorted items. What is the most checks it can need?" % K.fmt(n),
				n, "In the worst case, where is the item, or is it there at all?",
				"In the worst case the item is last or missing, so all %s items are checked: %s checks." % [K.fmt(n), K.fmt(n)])
			data = {"kind": "linear", "n": n}
		2:
			var n := [10, 15, 20, 31, 32, 50, 64, 100, 200, 500, 1000, 2000, 5000][rng.randi_range(0, 12)] as int
			var k := P.steps_for("binary", n)
			ex = K.number("What is the most checks binary search can need for %s sorted items?" % K.fmt(n), k,
				"Halve the items again and again, rounding down, until 1 is left, and count every check.",
				"What is left: %s. That is %d checks at most." % [_halvings(n), k])
			if n <= 64:
				ex.picture = {"kind": "step_growth", "lines": ["linear", "binary"], "upto": maxi(n, 4)}
			data = {"kind": "binary", "n": n}
		_:
			if rng.randi() % 2 == 0:
				var n := rng.randi_range(5, 40)
				var c := P.steps_for("bubble", n)
				ex = K.number("Bubble sort sorts %d items, every pass to the end. How many comparisons? Use n × (n − 1) ÷ 2." % n,
					c, "Put n into the rule: multiply first, then halve.",
					"%d × %d = %s, and %s ÷ 2 = %s comparisons." % [n, n - 1, K.fmt(n * (n - 1)), K.fmt(n * (n - 1)), K.fmt(c)])
				data = {"kind": "bubble", "n": n}
			else:
				var n := [100, 500, 1000, 5000, 10000, 100000][rng.randi_range(0, 5)] as int
				var b := P.steps_for("binary", n)
				ex = K.number("%s sorted items: how many more checks can linear search need than binary search, at most?" % K.fmt(n),
					n - b, "Work out each worst case first, then take one from the other.",
					"Linear: %s checks. Binary: %d. %s − %d = %s." % [K.fmt(n), b, K.fmt(n), b, K.fmt(n - b)])
				data = {"kind": "gap", "n": n}
	ex.data = data
	return ex


## The halvings of n down to 1 ("16, 8, 4, 2, 1").
static func _halvings(n: int) -> String:
	var said: Array[String] = []
	var v := n
	while v >= 1:
		said.append(K.fmt(v))
		v /= 2
	return ", ".join(said)


## The state machines the generators use: states, and arrows [from, to, event].
const MACHINES := {
	"light": {"states": ["red", "red and amber", "green", "amber"],
		"arrows": [[0, 1, "time"], [1, 2, "time"], [2, 3, "time"], [3, 0, "time"]]},
	"game": {"states": ["menu", "playing", "paused"],
		"arrows": [[0, 1, "tap PLAY"], [1, 2, "tap PAUSE"], [2, 1, "tap PLAY"], [2, 0, "tap MENU"]]},
	"door": {"states": ["closed", "open", "locked"],
		"arrows": [[0, 1, "open"], [1, 0, "close"], [0, 2, "lock"], [2, 0, "unlock"]]},
}


## The state a machine is in after `events` from `start`; an event with no arrow out of the state changes nothing.
static func _state_after(machine: String, start: int, events: Array) -> int:
	var s := start
	for e: Variant in events:
		for a: Array in MACHINES[machine].arrows:
			if int(a[0]) == s and str(a[2]) == str(e):
				s = int(a[1])
				break
	return s


## A state machine: which state after some events. Level 1: one event; level 2: two or three; level 3: three or four,
## some of which have no arrow from the state they arrive in (they change nothing).
static func state_next(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = MACHINES.keys()
	var m := str(names[rng.randi_range(0, names.size() - 1)])
	var mach: Dictionary = MACHINES[m]
	var states: Array = mach.states
	var start := rng.randi_range(0, states.size() - 1)
	var count := 1 if level == 1 else (rng.randi_range(2, 3) if level == 2 else rng.randi_range(3, 4))
	var events: Array = []
	var s := start
	var all_events: Array = []
	for a: Array in mach.arrows:
		if not all_events.has(a[2]):
			all_events.append(a[2])
	for i in count:
		var out: Array = []
		for a: Array in mach.arrows:
			if int(a[0]) == s:
				out.append(a)
		var e := ""
		if level == 3 and all_events.size() > 1 and i > 0 and rng.randi() % 3 == 0:
			e = str(all_events[rng.randi_range(0, all_events.size() - 1)])
		else:
			e = str(out[rng.randi_range(0, out.size() - 1)][2])
		events.append(e)
		s = _state_after(m, s, [e])
	var end := _state_after(m, start, events)
	var steps: Array[String] = []
	var at := start
	for e: Variant in events:
		var nxt := _state_after(m, at, [e])
		steps.append("%s takes it to %s" % [str(e), str(states[nxt])] if nxt != at else "%s changes nothing" % str(e))
		at = nxt
	var said: Array[String] = []
	for e: Variant in events:
		said.append(str(e))
	var wrongs: Array = []
	for i in states.size():
		if i != end:
			wrongs.append(str(states[i]))
	var ex := K.choice(rng, "It starts in the state %s. The events: %s. Which state is it in now?" % [str(states[start]),
		", then ".join(said)],
		str(states[end]), wrongs, "Follow one arrow for each event, in order. An event with no arrow from the state "
		+ "changes nothing.", "From %s: %s." % [str(states[start]), "; ".join(steps)],
		{"kind": "state_machine", "states": states, "arrows": mach.arrows, "current": start})
	ex.data = {"machine": m, "start": start, "events": events}
	return ex


## What a model keeps for its purpose, and what it leaves out (each level's own models).
const MODELS := {
	1: {"a map for a train traveller": [["the order of the stops", "where to change lines", "the names of the stops"],
			["the colour of each house", "the trees in the park", "the shapes of the clouds"]],
		"a model of a traffic light": [["its colours", "how long each colour stays on", "the order of the colours"],
			["the paint on the pole", "who made the bulbs", "the birds on the wires"]],
		"a model of a bouncing ball": [["the height it drops from", "how bouncy it is", "the pull of gravity"],
			["its colour", "who owns it", "the name printed on it"]]},
	2: {"a weather forecast model": [["air pressure", "temperature", "wind speed", "how wet the air is"],
			["what people ate for breakfast", "the price of umbrellas", "the names of the streets"]],
		"a model of a lunch queue": [["pupils arriving each minute", "how long serving takes", "how many serving points"],
			["the colour of the trays", "pupils' favourite songs", "the pictures on the walls"]],
		"a model of a rabbit population": [["rabbits born each month", "rabbits that die each month", "the food there is"],
			["the rabbits' names", "the colour of their fur", "the shapes of their tails"]]},
	3: {"a model of a forest fire spreading": [["how dry the trees are", "the wind's direction", "how close the trees are"],
			["who planted the trees", "the names of the paths", "the birds' songs"]],
		"a model of a lift in a tall building": [["the floors it stops at", "how many people fit", "the buttons pressed"],
			["the music it plays", "the colour of its walls", "the shine of its mirror"]],
		"a model of a phone's battery": [["how full it is", "the power the screen uses", "how long apps run"],
			["the colour of the case", "what the photos show", "the phone's name"]]},
}


## Sort a model's details: keep or leave out. Five details, at least two of each.
static func model_keep(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var table: Dictionary = MODELS[clampi(level, 1, 3)]
	var purposes: Array = table.keys()
	var purpose := str(purposes[rng.randi_range(0, purposes.size() - 1)])
	var keep: Array = (table[purpose][0] as Array).duplicate()
	var leave: Array = (table[purpose][1] as Array).duplicate()
	K.shuffle(rng, keep)
	K.shuffle(rng, leave)
	var nk := rng.randi_range(2, 3)
	var items: Array = []
	var answer: Array = []
	for i in nk:
		items.append(keep[i])
	for i in 5 - nk:
		items.append(leave[i])
	var order: Array = range(5)
	K.shuffle(rng, order)
	var shown: Array = []
	for i: int in order:
		shown.append(items[i])
		answer.append(0 if i < nk else 1)
	var kept: Array[String] = []
	for i in nk:
		kept.append(str(keep[i]))
	var ex := {"type": "sort", "prompt": "Sort the details for %s: keep or leave out?" % purpose,
		"groups": ["keep", "leave out"], "items": shown, "answer": answer,
		"hint": "Ask of each detail: would the model's answer change without it?",
		"explain": "Keep what changes the answer: %s. The rest does not matter for this model." % ", ".join(kept)}
	ex.data = {"purpose": purpose, "level": level}
	return ex


## A program for the School's little machine (LOAD n, ADD n, SUB n, OUT, HALT): the outputs and how many instructions
## run (HALT counts).
static func _machine_run(memory: Array) -> Dictionary:
	var acc := 0
	var out: Array[int] = []
	var ran := 0
	for row: Array in memory:
		ran += 1
		var op := str(row[1]).split(" ")
		match op[0]:
			"LOAD":
				acc = int(op[1])
			"ADD":
				acc += int(op[1])
			"SUB":
				acc -= int(op[1])
			"OUT":
				out.append(acc)
			"HALT":
				break
	return {"out": out, "ran": ran}


## The little machine. Level 1: LOAD, ADD, OUT; level 2: three sums before OUT; level 3: two OUTs (the second asked) or
## how many instructions run.
static func machine_trace(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array[String] = []
	var acc := rng.randi_range(5, 30)
	lines.append("LOAD %d" % acc)
	var sums := 1 if level == 1 else 2
	var outs := 1 if level < 3 else 2
	for o in outs:
		for i in sums:
			if rng.randi() % 2 == 0 or acc < 6:
				var a := rng.randi_range(2, 15)
				lines.append("ADD %d" % a)
				acc += a
			else:
				var s := rng.randi_range(1, mini(acc - 1, 12))
				lines.append("SUB %d" % s)
				acc -= s
		lines.append("OUT")
	lines.append("HALT")
	var memory: Array = []
	for i in lines.size():
		memory.append([i, lines[i]])
	var run := _machine_run(memory)
	var outs_got: Array = run.out
	var steps: Array[String] = []
	var v := 0
	for l in lines:
		var op := l.split(" ")
		if op[0] == "LOAD":
			v = int(op[1])
			steps.append("LOAD puts %d in the accumulator" % v)
		elif op[0] == "ADD":
			steps.append("%d + %s = %d" % [v, op[1], v + int(op[1])])
			v += int(op[1])
		elif op[0] == "SUB":
			steps.append("%d − %s = %d" % [v, op[1], v - int(op[1])])
			v -= int(op[1])
		elif op[0] == "OUT":
			steps.append("OUT shows %d" % v)
	var ex: Dictionary
	var ask := "out"
	if level == 3 and rng.randi() % 2 == 0:
		ask = "count"
		ex = K.number("How many instructions does this program fetch and execute, counting HALT?", int(run.ran),
			"Follow the program counter from address 0 to HALT.",
			"Every instruction runs once, from address 0 to HALT at address %d: %d instructions." % [lines.size() - 1,
				int(run.ran)])
	elif level == 3:
		ask = "second"
		ex = K.number("What number does the second OUT show?", int(outs_got[1]),
			"Keep the accumulator's value line by line, and count the OUTs.", "%s." % "; ".join(steps))
	else:
		ex = K.number("This program runs. What number does OUT show?", int(outs_got[0]),
			"Keep the accumulator's value as each line runs.", "%s." % "; ".join(steps))
	ex.picture = {"kind": "cpu_cycle", "view": "machine", "memory": memory, "pc": 0}
	ex.data = {"memory": memory, "ask": ask}
	return ex


## ASCII codes. Level 1: a capital's code (A = 65); level 2: a small letter's code (a = 97) or the letter for a code;
## level 3: the codes of a short word.
static func char_code(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var i := rng.randi_range(1, 25)
			var ch := String.chr(65 + i)
			ex = K.number("In ASCII, A is 65. What is the code for %s?" % ch, 65 + i,
				"Count on through the alphabet from A.", "%s is %d letters after A, so its code is 65 + %d = %d." % [ch, i, i,
					65 + i])
			ex.data = {"ask": "code", "char": ch}
		2:
			var i := rng.randi_range(0, 25)
			if rng.randi() % 2 == 0:
				var ch := String.chr(97 + i)
				ex = K.number("In ASCII, A is 65 and small a is 97. What is the code for small %s?" % ch, 97 + i,
					"Small letters start at 97 and go up by one.", "%s is %d letters after a, so 97 + %d = %d." % [ch, i, i,
						97 + i])
				ex.data = {"ask": "code", "char": ch}
			else:
				var code := 65 + i
				var wrongs: Array = []
				for d: int in [-1, 1, 2, -2]:
					if code + d >= 65 and code + d <= 90:
						wrongs.append(String.chr(code + d))
				ex = K.choice(rng, "In ASCII, A is 65. Which capital letter has the code %d?" % code, String.chr(code),
					wrongs.slice(0, 3), "Take 65 away, then count on that many letters from A.",
					"%d − 65 = %d letters after A: %s." % [code, i, String.chr(code)])
				ex.data = {"ask": "char", "code": code}
		_:
			var words: Array[String] = ["CAT", "DOG", "SUN", "MAP", "BOX", "HEN", "OWL", "KEY"]
			var w := words[rng.randi_range(0, words.size() - 1)]
			var codes: Array[String] = []
			var small: Array[String] = []
			var off: Array[String] = []
			for ch in w:
				codes.append(str(ch.unicode_at(0)))
				small.append(str(ch.unicode_at(0) + 32))
				off.append(str(ch.unicode_at(0) + 1))
			var swapped: Array[String] = codes.duplicate()
			swapped.reverse()
			var wrongs: Array = [", ".join(small), ", ".join(off)]
			if swapped != codes:
				wrongs.append(", ".join(swapped))
			ex = K.choice(rng, "Which codes store the word %s in ASCII? (A is 65.)" % w, ", ".join(codes), wrongs,
				"Work out each capital letter's place after A, in the word's order.",
				"%s: %s. (Small letters would be 32 more.)" % [w, ", ".join(codes)])
			ex.data = {"ask": "word", "word": w}
	return ex


## File sizes. Level 1: a picture's bits (width × height × bits a pixel); level 2: a picture's bytes, or a sound's bits
## (samples a second × bits × seconds); level 3: a sound's bytes, or text's bytes.
static func file_size(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var kind := ""
	if level == 1:
		kind = "image_bits"
	elif level == 2:
		kind = ["image_bytes", "sound_bits"][rng.randi_range(0, 1)]
	else:
		kind = ["sound_bytes", "text_bytes"][rng.randi_range(0, 1)]
	var data := {"kind": kind}
	match kind:
		"image_bits":
			var w := rng.randi_range(2, 30)
			var h := rng.randi_range(2, 20)
			var b := [1, 2, 4, 8][rng.randi_range(0, 3)] as int
			ex = K.number("A picture is %d pixels wide and %d high, at %d bit%s a pixel. How many bits is it?" % [w, h, b,
				"" if b == 1 else "s"], w * h * b, "Count the pixels first, then multiply by the bits each needs.",
				"%d × %d = %s pixels, and %s × %d = %s bits." % [w, h, K.fmt(w * h), K.fmt(w * h), b, K.fmt(w * h * b)])
			data.merge({"w": w, "h": h, "bits": b})
		"image_bytes":
			var w := rng.randi_range(2, 20) * 10
			var h := rng.randi_range(2, 20) * 10
			var b := [8, 24][rng.randi_range(0, 1)] as int
			ex = K.number("A picture is %d × %d pixels in %d-bit colour. How many bytes is it?" % [w, h, b], w * h * b / 8,
				"Find the bits first, then divide by 8.", "%d × %d = %s pixels; × %d = %s bits; ÷ 8 = %s bytes." % [w, h,
					K.fmt(w * h), b, K.fmt(w * h * b), K.fmt(w * h * b / 8)])
			data.merge({"w": w, "h": h, "bits": b})
		"sound_bits":
			var rate := [1000, 2000, 4000, 8000][rng.randi_range(0, 3)] as int
			var b := [8, 16][rng.randi_range(0, 1)] as int
			var s := rng.randi_range(2, 9)
			ex = K.number("A sound is sampled %s times a second at %d bits a sample. How many bits for %d seconds?" % [
				K.fmt(rate), b, s], rate * b * s, "Use samples a second × bits a sample × seconds.",
				"%s × %d = %s bits a second, and × %d = %s bits." % [K.fmt(rate), b, K.fmt(rate * b), s, K.fmt(rate * b * s)])
			data.merge({"rate": rate, "bits": b, "seconds": s})
		"sound_bytes":
			var rate := [8000, 11025, 22050, 44100][rng.randi_range(0, 3)] as int
			var s := rng.randi_range(2, 10)
			ex = K.number("A sound is sampled %s times a second at 16 bits a sample. How many bytes for %d seconds?" % [
				K.fmt(rate), s], rate * 16 * s / 8, "Work out the bits, then divide by 8 for bytes.",
				"%s × 16 × %d = %s bits; ÷ 8 = %s bytes." % [K.fmt(rate), s, K.fmt(rate * 16 * s), K.fmt(rate * 2 * s)])
			data.merge({"rate": rate, "bits": 16, "seconds": s})
		_:
			var chars := rng.randi_range(20, 900)
			ex = K.number("A message of %s characters is stored at 1 byte (8 bits) a character. How many bits is it?" %
				K.fmt(chars), chars * 8, "Each character is 8 bits.", "%s × 8 = %s bits." % [K.fmt(chars), K.fmt(chars * 8)])
			data.merge({"chars": chars})
	ex.data = data
	return ex


## The circuits the logic generators use, by how many gates.
const CIRCUITS := {
	1: [["AND", "A", "B"], ["OR", "A", "B"], ["NOT", "A"]],
	2: [["AND", ["OR", "A", "B"], "C"], ["OR", ["AND", "A", "B"], "C"], ["AND", ["NOT", "A"], "B"],
		["OR", "A", ["NOT", "B"]], ["NOT", ["AND", "A", "B"]], ["NOT", ["OR", "A", "B"]]],
	3: [["AND", ["OR", "A", "B"], ["NOT", "C"]], ["OR", ["AND", "A", "B"], ["NOT", "C"]],
		["NOT", ["OR", "A", ["NOT", "B"]]], ["AND", ["NOT", "A"], ["OR", "B", "C"]]],
}


## A circuit written in words: (A AND B) OR NOT C.
static func _circuit_said(e: Variant, top: bool = true) -> String:
	if e is String:
		return str(e)
	if str(e[0]) == "NOT":
		return "NOT " + _circuit_said(e[1], false)
	var s := "%s %s %s" % [_circuit_said(e[1], false), str(e[0]), _circuit_said(e[2], false)]
	return s if top else "(%s)" % s


## Will the lamp light? Level 1: one gate; level 2: two; level 3: three.
static func gate_out(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var list: Array = CIRCUITS[clampi(level, 1, 3)]
	var expr: Variant = list[rng.randi_range(0, list.size() - 1)]
	var inputs := {}
	for l in P.circuit_letters(expr):
		inputs[l] = rng.randi_range(0, 1)
	var v := P.circuit_out(expr, inputs)
	var said: Array[String] = []
	for l: String in inputs:
		said.append("%s = %d" % [l, int(inputs[l])])
	var yes := "yes: the output is 1"
	var no := "no: the output is 0"
	var ex := K.choice(rng, "Will the lamp light?", yes if v == 1 else no, [no if v == 1 else yes],
		"Work from the inputs to the lamp, one gate at a time.",
		"With %s, %s gives %d, so the lamp is %s." % [", ".join(said), _circuit_said(expr), v, "on" if v == 1 else "off"],
		{"kind": "gate_circuit", "expr": expr, "inputs": inputs, "out": false})
	ex.data = {"expr": expr, "inputs": inputs}
	return ex


## Truth tables. Level 1: the rows for 2-5 inputs; level 2: the rows of one gate that give 1; level 3: the rows of a
## two-gate circuit that give 1.
static func truth_rows(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var n := rng.randi_range(2, 5)
			ex = K.number("How many rows does a truth table for %d inputs have?" % n, 1 << n,
				"Each input doubles the rows: start from 2 for one input.",
				"%s = %d rows." % [_times("2", n), 1 << n])
			ex.data = {"inputs": n}
		_:
			var expr: Variant
			if level == 2:
				expr = [["AND", "A", "B"], ["OR", "A", "B"], ["AND", "A", ["AND", "B", "C"]], ["OR", "A", ["OR", "B", "C"]],
					["NOT", "A"]][rng.randi_range(0, 4)]
			else:
				var list: Array = CIRCUITS[2]
				expr = list[rng.randi_range(0, list.size() - 1)]
			var letters := P.circuit_letters(expr)
			var n := letters.size()
			var ones := 0
			for row in 1 << n:
				var inputs := {}
				for k in n:
					inputs[letters[k]] = (row >> (n - 1 - k)) & 1
				ones += P.circuit_out(expr, inputs)
			ex = K.number("In the truth table for %s, how many of the %d rows give 1?" % [_circuit_said(expr), 1 << n], ones,
				"Write out every row of inputs, then work out the output for each.",
				"Working out every row: the output is 1 in %d of the %d rows, and 0 in the other %d." % [ones, 1 << n,
					(1 << n) - ones])
			ex.data = {"expr": expr}
	return ex


const PET_NAMES: Array[String] = ["Pip", "Mo", "Bobo", "Luna", "Rex", "Tia", "Max", "Fig"]
const PET_ANIMALS: Array[String] = ["dog", "cat", "rabbit", "hamster"]


## The ids of the records of `rows` (fields id, name, animal, age) that `cond` picks: "animal = 'cat'", "age > 3",
## "age < 3", or two of them joined by AND or OR.
static func _query_picks(rows: Array, cond: String) -> Array[int]:
	var out: Array[int] = []
	for i in rows.size():
		if _cond_true(rows[i], cond):
			out.append(i)
	return out


static func _cond_true(row: Array, cond: String) -> bool:
	if cond.contains(" AND "):
		return _cond_true(row, cond.get_slice(" AND ", 0)) and _cond_true(row, cond.get_slice(" AND ", 1))
	if cond.contains(" OR "):
		return _cond_true(row, cond.get_slice(" OR ", 0)) or _cond_true(row, cond.get_slice(" OR ", 1))
	var parts := cond.split(" ", false, 2)
	var field := ["id", "name", "animal", "age"].find(parts[0])
	var v: Variant = row[field]
	var want := parts[2].trim_prefix("'").trim_suffix("'")
	match parts[1]:
		"=":
			return str(v) == want
		">":
			return int(v) > int(want)
		"<":
			return int(v) < int(want)
	return false


## A database query: how many records does it find? Level 1: WHERE animal = …; level 2: WHERE age > or < …; level 3: two
## conditions joined by AND or OR.
static func db_query(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows: Array = []
	var cond := ""
	var picks: Array[int] = []
	for _try in 40:
		rows = []
		var names := PET_NAMES.duplicate()
		K.shuffle(rng, names)
		var n := rng.randi_range(5, 6)
		for i in n:
			rows.append([i + 1, names[i], PET_ANIMALS[rng.randi_range(0, 3)], rng.randi_range(1, 12)])
		var animal := "'%s'" % str(rows[rng.randi_range(0, n - 1)][2])
		var age := rng.randi_range(3, 9)
		var a := "animal = %s" % animal
		var b := "age %s %d" % [[">", "<"][rng.randi_range(0, 1)], age]
		match level:
			1:
				cond = a
			2:
				cond = b
			_:
				cond = "%s %s %s" % [a, ["AND", "OR"][rng.randi_range(0, 1)], b]
		picks = _query_picks(rows, cond)
		if picks.size() >= 1 and picks.size() < n:
			break
	var query := "SELECT name FROM pets WHERE %s" % cond
	var found: Array[String] = []
	for i in picks:
		found.append(str(rows[i][1]))
	var ex := K.number("How many records does this query find?", picks.size(),
		"Check every record against the WHERE part%s." % (": AND needs both, OR needs either" if level == 3 else ""),
		"It finds %s: %d record%s." % [", ".join(found), picks.size(), "" if picks.size() == 1 else "s"],
		{"kind": "db_table", "name": "pets", "fields": ["id", "name", "animal", "age"], "rows": rows, "key": 0,
			"query": query})
	ex.data = {"rows": rows, "cond": cond}
	return ex


## Two groups of examples measured two ways, for the nearest-neighbour model.
const SETS: Array = [
	{"axes": ["ear length (cm)", "mass (kg)"], "groups": ["cat", "rabbit"], "centres": [[3.0, 4.5], [7.5, 2.0]]},
	{"axes": ["length (cm)", "width (cm)"], "groups": ["leaf A", "leaf B"], "centres": [[2.5, 7.0], [7.0, 3.0]]},
	{"axes": ["width (cm)", "height (cm)"], "groups": ["apple", "pear"], "centres": [[7.0, 7.0], [4.0, 8.5]]},
]


## A new example classified by its nearest training examples. Level 1: near one group, the nearest ringed; level 2:
## between the groups, nothing ringed; level 3: a vote of the 3 nearest, ringed.
static func nearest_guess(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var set: Dictionary = SETS[rng.randi_range(0, SETS.size() - 1)]
	var pts: Array = []
	var new_pt: Array = []
	var k := 3 if level == 3 else 1
	var right := 0
	for _try in 60:
		pts = []
		for g in 2:
			for i in 4:
				var c: Array = set.centres[g]
				pts.append([snappedf(clampf(float(c[0]) + rng.randf_range(-1.5, 1.5), 0.5, 9.5), 0.5),
					snappedf(clampf(float(c[1]) + rng.randf_range(-1.5, 1.5), 0.5, 9.5), 0.5), g])
		var g0: Array = set.centres[0]
		var g1: Array = set.centres[1]
		var t := rng.randf_range(0.15, 0.3) if level == 1 else rng.randf_range(0.35, 0.65)
		if rng.randi() % 2 == 0:
			t = 1.0 - t
		new_pt = [snappedf(lerpf(float(g0[0]), float(g1[0]), t) + rng.randf_range(-0.5, 0.5), 0.5),
			snappedf(lerpf(float(g0[1]), float(g1[1]), t) + rng.randf_range(-0.5, 0.5), 0.5)]
		var near := P.nearest(pts, float(new_pt[0]), float(new_pt[1]), 4)
		var d := func(i: int) -> float: return Vector2(float(pts[i][0]) - float(new_pt[0]), float(pts[i][1]) - float(new_pt[1])).length()
		# a clear answer: no tie at the edge of the k nearest, and the vote not split evenly
		if float(d.call(near[k])) - float(d.call(near[k - 1])) < 0.25:
			continue
		break
	var nearest_k := P.nearest(pts, float(new_pt[0]), float(new_pt[1]), k)
	var votes := [0, 0]
	for i in nearest_k:
		votes[int(pts[i][2])] += 1
	right = 0 if votes[0] > votes[1] else 1
	var groups: Array = set.groups
	var pic := {"kind": "scatter_learn", "axes": set.axes, "groups": groups, "points": pts, "new": new_pt}
	if level != 2:
		pic.near = k
	var prompt := "Which group does the model give the new example, by its nearest example?" if k == 1 \
		else "The 3 nearest examples are ringed. What does their vote say?"
	var explain := "Its nearest example is labelled %s, so the model says %s." % [str(groups[right]), str(groups[right])] \
		if k == 1 else "Most of the 3 nearest are labelled %s, so the vote says %s." % [str(groups[right]), str(groups[right])]
	var ex := K.choice(rng, prompt, str(groups[right]), [str(groups[1 - right])],
		"Find the example closest to the ? and look at its shape and colour." if k == 1
		else "Count the circles and the triangles among the ringed examples.", explain, pic)
	ex.data = {"points": pts, "new": new_pt, "k": k}
	return ex


## A model's percentages. Level 1: right out of 10; level 2: right out of 20, 25 or 50; level 3: a group's share of the
## training data, or how many points better one model is than another.
static func accuracy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var r := rng.randi_range(5, 10)
			ex = K.number("A model gets %d of 10 test examples right. What is its accuracy as a percentage?" % r, r * 10,
				"Make the fraction out of 100.", "%d out of 10 is %d out of 100: %d%%." % [r, r * 10, r * 10])
			ex.data = {"right": r, "of": 10}
		2:
			var of := [20, 25, 50][rng.randi_range(0, 2)] as int
			var r := rng.randi_range(of / 2, of)
			ex = K.number("A model labels %d of %d new examples right. What is its accuracy as a percentage?" % [r, of],
				r * 100 / of, "Make the fraction out of 100.", "%d out of %d is %d out of 100: %d%%." % [r, of, r * 100 / of,
					r * 100 / of])
			ex.data = {"right": r, "of": of}
		_:
			if rng.randi() % 2 == 0:
				var total := [100, 200, 400, 500][rng.randi_range(0, 3)] as int
				var few := total / 100 * rng.randi_range(2, 30)
				ex = K.number("Training photos: %d cats and %d rabbits. What percentage are rabbits?" % [total - few, few],
					few * 100 / total, "Find the total first, then the rabbits' share of 100.",
					"%d + %d = %d photos; %d of %d is %d of 100: %d%%." % [total - few, few, total, few, total,
						few * 100 / total, few * 100 / total])
				ex.data = {"few": few, "total": total}
			else:
				var a := rng.randi_range(70, 95)
				var bh := rng.randi_range(35, 49)
				while bh * 2 == a:
					bh = rng.randi_range(35, 49)
				var b_pct := bh * 2
				ex = K.number("Model A gets %d of 100 right; model B gets %d of 50. How many percentage points apart are they?" % [a, bh],
					absi(a - b_pct), "Turn both into percentages first.",
					"A: %d%%. B: %d of 50 is %d of 100, %d%%. They are %d points apart." % [a, bh, b_pct, b_pct, absi(a - b_pct)])
				ex.data = {"a": a, "b_of_50": bh}
	return ex


## How many passwords. Level 1: an n-digit PIN; level 2: 2 or 3 small letters, or the tries a brake allows in a day;
## level 3: 4 small letters, or how many times more one extra character makes.
static func password_space(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var n := rng.randi_range(2, 6)
			ex = K.number("How many different %d-digit PINs are there?" % n, int(pow(10, n)),
				"Each digit has 10 choices; multiply for every digit.", "%s = %s PINs." % [_times("10", n), K.fmt(int(pow(10, n)))])
			ex.data = {"kind": "pin", "n": n}
		2:
			if rng.randi() % 2 == 0:
				var n := rng.randi_range(2, 3)
				ex = K.number("A password uses only the 26 small letters. How many %d-letter passwords are there?" % n,
					int(pow(26, n)), "Each letter has 26 choices.", "%s = %s passwords." % [_times("26", n),
						K.fmt(int(pow(26, n)))])
				ex.data = {"kind": "letters", "n": n}
			else:
				var tries := [3, 5, 10][rng.randi_range(0, 2)] as int
				var mins := [10, 15, 20, 30, 60][rng.randi_range(0, 4)] as int
				var spells := 24 * 60 / mins
				ex = K.number("Guessing is braked to %d tries every %d minutes. How many tries is that in 24 hours?" % [tries, mins],
					spells * tries, "How many %d-minute spells are there in a day?" % mins,
					"24 × 60 = 1,440 minutes; 1,440 ÷ %d = %d spells; %d × %d = %s tries." % [mins, spells, spells, tries,
						K.fmt(spells * tries)])
				ex.data = {"kind": "brake", "tries": tries, "minutes": mins}
		_:
			if rng.randi() % 2 == 0:
				ex = K.number("A password uses only the 26 small letters. How many 4-letter passwords are there?", 456976,
					"Multiply 26 by itself once for each letter.", "26 × 26 × 26 × 26 = 456,976 passwords.")
				ex.data = {"kind": "letters", "n": 4}
			else:
				var sets := [["digits", 10], ["small letters", 26], ["small letters and digits", 36],
					["small and capital letters", 52]]
				var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
				var n := rng.randi_range(4, 8)
				ex = K.number("A password uses %s (%d symbols). How many times more passwords are there with %d characters than with %d?" % [
					str(s[0]), int(s[1]), n + 1, n], int(s[1]), "What does one more character multiply the count by?",
					"Each extra character has %d choices, so there are %d times as many." % [int(s[1]), int(s[1])])
				ex.data = {"kind": "more", "symbols": int(s[1])}
	return ex


static func _times(v: String, n: int) -> String:
	var parts: Array[String] = []
	for i in n:
		parts.append(v)
	return " × ".join(parts)


## Safe or a risk, by level (the trick_sort table).
const RISKS := {
	1: [["update apps when asked", 0], ["back up your work", 0], ["turn on two-step checks", 0],
		["tell anyone a password", 1], ["click a link in a scary message", 1], ["use one password everywhere", 1]],
	2: [["download apps only from the official store", 0], ["lock your screen", 0], ["check the address bar padlock", 0],
		["type a password on public wireless", 1], ["install a free game from an unknown site", 1],
		["leave a phone unlocked on a desk", 1]],
	3: [["hang up on a caller asking for a code", 0], ["check a sender's real address", 0],
		["report a fake account to a grown-up", 0], ["read a code out to the bank on the phone", 1],
		["send a password to the game's team by message", 1], ["plug in a memory stick found outside", 1]],
}


## Sort into safe or a risk: five actions, at least two of each kind.
static func trick_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows: Array = (RISKS[clampi(level, 1, 3)] as Array).duplicate()
	var safe: Array = rows.filter(func(r: Array) -> bool: return int(r[1]) == 0)
	var risk: Array = rows.filter(func(r: Array) -> bool: return int(r[1]) == 1)
	K.shuffle(rng, safe)
	K.shuffle(rng, risk)
	var ns := rng.randi_range(2, 3)
	var picked: Array = safe.slice(0, ns) + risk.slice(0, 5 - ns)
	K.shuffle(rng, picked)
	var items: Array = []
	var answer: Array = []
	for r: Array in picked:
		items.append(str(r[0]))
		answer.append(int(r[1]))
	var ex := {"type": "sort", "prompt": "Safe to do, or a risk?", "groups": ["safe", "a risk"], "items": items,
		"answer": answer, "hint": "Ask: would an attacker like this, or would it stop them?",
		"explain": "Updates, backups, checks and telling a grown-up keep you safe; giving away codes, passwords or "
			+ "control is a risk."}
	ex.data = {"level": level}
	return ex


## User tests' numbers. Level 1: k of 10 finished, as a percentage; level 2: the mean time; level 3: how many percentage
## points better one design is than another.
static func user_test(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var k := rng.randi_range(3, 10)
			ex = K.number("%d of 10 users finished a task. What percentage finished?" % k, k * 10,
				"Make the fraction out of 100.", "%d out of 10 is %d out of 100: %d%%." % [k, k * 10, k * 10])
			ex.data = {"k": k, "of": 10}
		2:
			var n := rng.randi_range(3, 5)
			var times: Array[int] = []
			var total := 0
			for i in n - 1:
				var t := rng.randi_range(10, 60)
				times.append(t)
				total += t
			var last := rng.randi_range(10, 55)
			while (total + last) % n != 0:
				last += 1
			times.append(last)
			total += last
			var said: Array[String] = []
			for t in times:
				said.append(str(t))
			ex = K.number("Users took %s seconds. What was the mean time in seconds?" % _list_said(said), total / n,
				"Add them, then share by how many users there were.", "%s = %d, and %d ÷ %d = %d seconds." % [" + ".join(said),
					total, total, n, total / n])
			ex.data = {"times": times}
		_:
			var of := [20, 25, 50][rng.randi_range(0, 2)] as int
			var a := rng.randi_range(of / 3, of - 2)
			var b := rng.randi_range(a + 1, of)
			var pa := a * 100 / of
			var pb := b * 100 / of
			ex = K.number("Design A: %d of %d users finished. Design B: %d of %d. How many percentage points better is B?" % [
				a, of, b, of], pb - pa, "Turn both into percentages first.",
				"A: %d of %d is %d%%. B: %d of %d is %d%%. %d − %d = %d points." % [a, of, pa, b, of, pb, pb, pa, pb - pa])
			ex.data = {"a": a, "b": b, "of": of}
	return ex


## "30, 50, 40 and 60"
static func _list_said(items: Array[String]) -> String:
	if items.size() < 2:
		return "".join(items)
	return ", ".join(items.slice(0, items.size() - 1)) + " and " + items[-1]


## A device's energy. Level 1: watt-hours (watts × hours); level 2: kWh (÷ 1,000); level 3: kWh in a year of daily use.
static func device_energy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var h := rng.randi_range(2, 10)
	var things: Array = WATTS.keys()
	var thing := str(things[rng.randi_range(0, things.size() - 1)])
	var ws: Array = WATTS[thing]
	var w := int(ws[rng.randi_range(0, ws.size() - 1)])
	match level:
		1:
			ex = K.number("A %d-watt %s is on for %d hours. How many watt-hours does it use?" % [w, thing, h], w * h,
				"Multiply the power by the hours.", "%d × %d = %s watt-hours." % [w, h, K.fmt(w * h)])
		2:
			ex = K.number("A %d-watt %s is on for %d hours. How many kWh does it use?" % [w, thing, h], _dec(w * h, 1000),
				"Use watts × hours ÷ 1,000.", "%d × %d = %s watt-hours, and %s ÷ 1,000 = %s kWh." % [w, h, K.fmt(w * h),
					K.fmt(w * h), _dec(w * h, 1000)])
		_:
			h = rng.randi_range(1, 6)
			ex = K.number("A %d-watt %s is used %d hours a day for 365 days. How many kWh is that in a year?" % [w, thing, h],
				_dec(w * h * 365, 1000), "Find the watt-hours for a year, then divide by 1,000.",
				"%d × %d = %s watt-hours a day; × 365 = %s; ÷ 1,000 = %s kWh." % [w, h, K.fmt(w * h), K.fmt(w * h * 365),
					_dec(w * h * 365, 1000)])
	ex.data = {"watts": w, "hours": h, "level": level}
	return ex


## Devices and powers they may have, in watts (device_energy).
const WATTS := {"laptop": [20, 40, 50, 60], "desktop computer": [100, 150, 200, 300], "games console": [100, 150, 200],
	"television": [60, 100, 150], "printer": [20, 40, 50]}


## n ÷ d written as the lessons write a decimal: "0.6", "73", "36.5" (no thousands commas: a pad answer).
static func _dec(n: int, d: int) -> String:
	if n % d == 0:
		return str(n / d)
	var s := "%.3f" % (float(n) / d)
	while s.ends_with("0"):
		s = s.trim_suffix("0")
	return s.trim_suffix(".")


# --- Art -------------------------------------------------------------------------------------------------------------

## Art's events and their years (art_order).
const ART_EVENTS := {"paint sold in tubes": 1841, "Monet paints Impression, Sunrise": 1872,
	"the first Impressionist show": 1874, "Seurat begins his dot painting": 1884, "van Gogh paints The Starry Night": 1889,
	"Monet paints his haystacks": 1890, "the Fauves shock Paris": 1905, "Picasso begins Cubism": 1907,
	"the Surrealists' first manifesto": 1924, "Tarsila do Amaral paints Abaporu": 1928, "Dali paints melting clocks": 1931,
	"Pop Art begins in Britain": 1956, "Warhol paints rows of soup cans": 1962}
## Inventions that changed art, and their years (tech_order).
const TECH_EVENTS := {"Ibn al-Haytham explains the camera obscura": 1020, "the oldest photograph that survives": 1826,
	"the daguerreotype": 1839, "Muybridge's galloping horse": 1878, "the first film show": 1895,
	"colour photographs on glass": 1907, "films with sound": 1927, "the first digital camera": 1975}


## n events of `table` at least `gap` years apart, in a seeded order (the right order: by year).
static func _events(rng: RandomNumberGenerator, table: Dictionary, n: int, gap: int) -> Array:
	var names: Array = table.keys()
	for _try in 60:
		K.shuffle(rng, names)
		var pick: Array = names.slice(0, n)
		pick.sort_custom(func(a: Variant, b: Variant) -> bool: return int(table[a]) < int(table[b]))
		var ok := true
		for i in range(1, pick.size()):
			ok = ok and int(table[pick[i]]) - int(table[pick[i - 1]]) >= gap
		if ok:
			return pick
	names.sort_custom(func(a: Variant, b: Variant) -> bool: return int(table[a]) < int(table[b]))
	var out: Array = []
	for i in n:
		out.append(names[i * (names.size() - 1) / maxi(n - 1, 1)])
	return out


static func _order_by_year(rng: RandomNumberGenerator, level: int, table: Dictionary, what: String) -> Dictionary:
	var n := level + 2
	var gap := [0, 15, 5, 2][clampi(level, 1, 3)] as int
	var pick := _events(rng, table, n, gap)
	var said: Array[String] = []
	for e: Variant in pick:
		said.append("%s (%d)" % [str(e), int(table[e])])
	var ex := K.order(rng, "Put these %s in time order, the earliest first." % what, pick,
		"Find the earliest one first, then the next.", "In order: %s." % ", ".join(said))
	var years := {}
	for e: Variant in pick:
		years[e] = int(table[e])
	ex.data = {"years": years}
	return ex


## Modern art's events in time order. Level 1: three far apart; level 2: four; level 3: five, some close together.
static func art_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _order_by_year(rng, level, ART_EVENTS, "events in art")


## Inventions that changed art, in time order (as art_order).
static func tech_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _order_by_year(rng, level, TECH_EVENTS, "inventions")


## The movements and their artists (artist_movement): the first named in the lessons first.
const MOVEMENT_ARTISTS := {"Impressionism": ["Claude Monet", "Berthe Morisot", "Camille Pissarro"],
	"Fauvism": ["Henri Matisse"], "Cubism": ["Pablo Picasso", "Georges Braque"],
	"Surrealism": ["Salvador Dali", "René Magritte"], "Pop Art": ["Andy Warhol", "Roy Lichtenstein"]}


## Match artists to their movements. Level 1: 2 pairs, the best-known artists; level 2: 3-4; level 3: 5, any artist.
static func artist_movement(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var moves: Array = MOVEMENT_ARTISTS.keys()
	K.shuffle(rng, moves)
	var n := 2 if level == 1 else (rng.randi_range(3, 4) if level == 2 else 5)
	var items: Array = []
	var right: Array = []
	for i in n:
		var artists: Array = MOVEMENT_ARTISTS[moves[i]]
		var a := str(artists[0]) if level == 1 else str(artists[rng.randi_range(0, artists.size() - 1)])
		items.append(a)
		right.append(str(moves[i]))
	var shown := right.duplicate()
	for _try in 8:
		K.shuffle(rng, shown)
		var apart := false
		for i in n:
			apart = apart or shown[i] != right[i]
		if apart:
			break
	if shown == right:
		shown.reverse()
	var answer: Array = []
	for r: Variant in right:
		answer.append(shown.find(r))
	var said: Array[String] = []
	for i in n:
		said.append("%s: %s" % [str(items[i]), str(right[i])])
	var ex := {"type": "match", "prompt": "Match each artist to a movement.", "items": items, "matches": shown,
		"answer": answer, "hint": "Think of each artist's best-known pictures, then of what the movement changed.",
		"explain": "%s." % "; ".join(said)}
	ex.data = {"pairs": said}
	return ex


## Pixels. Level 1: width × height; level 2: megapixels; level 3: a print's size in cm at pixels a centimetre.
static func pixel_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var w := rng.randi_range(2, 16) * 10
			var h := rng.randi_range(2, 12) * 10
			ex = K.number("A picture is %d pixels wide and %d high. How many pixels is it?" % [w, h], w * h,
				"Multiply the width by the height.", "%d × %d = %s pixels." % [w, h, K.fmt(w * h)])
			ex.data = {"w": w, "h": h, "ask": "pixels"}
		2:
			var pairs := [[2000, 1500], [3000, 2000], [4000, 3000], [6000, 4000], [2000, 2000], [5000, 3000]]
			var p: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
			var mp := int(p[0]) * int(p[1]) / 1000000
			ex = K.number("A photo is %s pixels wide and %s high. How many million pixels (megapixels) is it?" % [
				K.fmt(int(p[0])), K.fmt(int(p[1]))], mp, "Multiply, then count the millions.",
				"%s × %s = %s pixels: %d megapixels." % [K.fmt(int(p[0])), K.fmt(int(p[1])), K.fmt(int(p[0]) * int(p[1])), mp])
			ex.data = {"w": int(p[0]), "h": int(p[1]), "ask": "megapixels"}
		_:
			var per := [50, 100, 120, 150, 200][rng.randi_range(0, 4)] as int
			var cm := rng.randi_range(3, 20)
			ex = K.number("A raster picture %s pixels wide is printed at %d pixels a centimetre. How wide is the print in cm?" % [
				K.fmt(per * cm), per], cm, "How many groups of %d pixels are there?" % per,
				"%s ÷ %d = %d cm." % [K.fmt(per * cm), per, cm])
			ex.data = {"pixels": per * cm, "per": per, "ask": "print"}
	return ex


## A face's proportions on a head `h` cm tall. Level 1: the eyes (halfway); level 2: the nose's bottom (halfway from the
## eyes to the chin); level 3: the mouth (a third of the way from the nose to the chin), or the face's width (five eyes).
static func face_measure(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var h := [12, 24, 36, 48, 60][rng.randi_range(0, 4)] as int
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A head is drawn %d cm tall. The eyes go halfway down. How many cm from the top are they?" % h, h / 2,
				"Halfway down means half the height.", "%d ÷ 2 = %d cm from the top." % [h, h / 2])
			ex.data = {"head": h, "ask": "eyes"}
		2:
			ex = K.number("A head is %d cm tall: eyes halfway, and the nose's bottom halfway from the eyes to the chin. How many cm from the top is the nose's bottom?" % h,
				h * 3 / 4, "Find the eye line, then go halfway on to the chin.",
				"Eyes: %d cm down. Eyes to chin: %d cm, half is %d. Nose: %d + %d = %d cm." % [h / 2, h / 2, h / 4, h / 2, h / 4,
					h * 3 / 4])
			ex.data = {"head": h, "ask": "nose"}
		_:
			if rng.randi() % 2 == 0:
				ex = K.number("A head is %d cm tall. The nose's bottom is %d cm down; the mouth is a third of the way from the nose to the chin. How many cm from the top is the mouth?" % [
					h, h * 3 / 4], h * 5 / 6, "Find the gap from the nose to the chin, then a third of it.",
					"Nose to chin: %d − %d = %d cm; a third is %d; the mouth is %d + %d = %d cm down." % [h, h * 3 / 4, h / 4,
						h / 12, h * 3 / 4, h / 12, h * 5 / 6])
				ex.data = {"head": h, "ask": "mouth"}
			else:
				var e := rng.randi_range(2, 6)
				ex = K.number("A face is about five eyes wide. Each eye is drawn %d cm wide. How wide is the face, in cm?" % e,
					e * 5, "Count the eye widths across a face.", "Five eyes: %d × 5 = %d cm." % [e, e * 5])
				ex.data = {"eye": e, "ask": "width"}
	return ex


## The grid method. Level 1: how many times bigger a square is; level 2: the mural's width; level 3: the mural's height
## from its width.
static func grid_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var small := [2, 4, 5, 10][rng.randi_range(0, 3)] as int
	var big := [50, 100, 200][rng.randi_range(0, 2)] as int
	if big % small != 0:
		big = 100
	var factor := big / small
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A design has %d cm squares; the wall's grid has %s squares. How many times bigger is each square?" % [
				small, _cm_said(big)], factor, "Turn the wall's square into centimetres first.",
				"%s = %d cm, and %d ÷ %d = %d times bigger." % [_cm_said(big), big, big, small, factor])
			ex.data = {"small": small, "big": big, "ask": "factor"}
		2:
			var w := rng.randi_range(2, 8) * small
			ex = K.number("A design %d cm wide is copied with a grid %d times bigger. How wide is the mural, in cm?" % [w,
				factor], w * factor, "Multiply the design's width by how many times bigger.",
				"%d × %d = %s cm (%s m)." % [w, factor, K.fmt(w * factor), _dec(w * factor, 100)])
			ex.data = {"w": w, "factor": factor, "ask": "width"}
		_:
			var f := [10, 20, 25, 50][rng.randi_range(0, 3)] as int
			var w := rng.randi_range(2, 6) * 10
			var h := rng.randi_range(1, 5) * 10
			ex = K.number("A design %d cm wide and %d cm tall is enlarged onto a wall %s m wide. How tall will the mural be, in cm?" % [
				w, h, _dec(w * f, 100)], h * f, "Find how many times bigger from the widths first.",
				"%s m = %s cm, and %s ÷ %d = %d times. %d × %d = %s cm." % [_dec(w * f, 100), K.fmt(w * f), K.fmt(w * f), w, f,
					h, f, K.fmt(h * f)])
			ex.data = {"w": w, "h": h, "factor": f, "ask": "height"}
	return ex


static func _cm_said(cm: int) -> String:
	return "%d m" % (cm / 100) if cm % 100 == 0 else "%d cm" % cm


## Paint for a mural. Level 1: the wall's area; level 2: tins for one coat; level 3: tins for two coats, or one coat
## round a door.
static func paint_tins(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(3, 12)
	var h := rng.randi_range(2, 5)
	var cover := [5, 8, 10][rng.randi_range(0, 2)] as int
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A wall is %d m by %d m. What is its area in m²?" % [w, h], w * h, "Area is length × width.",
				"%d × %d = %d m²." % [w, h, w * h])
			ex.data = {"area": w * h, "coats": 0, "cover": 0}
		2:
			var tins := ceili(float(w * h) / cover)
			ex = K.number("A wall %d m by %d m needs one coat. A tin covers %d m². How many tins must you buy?" % [w, h, cover],
				tins, "Find the area, divide, then think: can you buy part of a tin?",
				"%d × %d = %d m²; %d ÷ %d = %s, so buy %d tin%s." % [w, h, w * h, w * h, cover, _dec(w * h, cover), tins,
					"" if tins == 1 else "s"])
			ex.data = {"area": w * h, "coats": 1, "cover": cover}
		_:
			if rng.randi() % 2 == 0:
				var tins := ceili(float(w * h * 2) / cover)
				ex = K.number("A wall %d m by %d m needs two coats. A tin covers %d m². How many tins must you buy?" % [w, h, cover],
					tins, "Find the area for both coats, then divide and round up.",
					"%d × %d = %d m²; two coats: %d m²; %d ÷ %d = %s, so buy %d tins." % [w, h, w * h, w * h * 2, w * h * 2, cover,
						_dec(w * h * 2, cover), tins])
				ex.data = {"area": w * h * 2, "coats": 2, "cover": cover}
			else:
				var tins := ceili(float(w * h - 2) / cover)
				ex = K.number("A wall %d m by %d m has a door of 2 m² that is not painted. A tin covers %d m². How many tins for one coat?" % [
					w, h, cover], tins, "Take the door away from the wall's area, then divide and round up.",
					"%d × %d = %d m²; less the door: %d m²; %d ÷ %d = %s, so buy %d tin%s." % [w, h, w * h, w * h - 2, w * h - 2,
						cover, _dec(w * h - 2, cover), tins, "" if tins == 1 else "s"])
				ex.data = {"area": w * h - 2, "coats": 1, "cover": cover}
	return ex


## Each object's features: those that help it work, and those that only change its look (form_function).
const FEATURES := {
	"a desk lamp": [["springs hold the arm", "joints let it bend", "a heavy base stops it tipping", "the shade points the light"],
		["a glossy red finish", "a pattern on the shade", "a shiny gold trim"]],
	"a chair": [["legs that reach the floor", "a seat at the right height", "a backrest for support",
		"legs that let it stack"], ["a bright blue colour", "a flower pattern", "a glossy shine"]],
	"a kettle": [["a handle that stays cool", "a spout for pouring", "a lid that shuts tight",
		"a switch that turns off when it boils"], ["a silver colour", "a stripe of colour", "a shiny finish"]],
	"a backpack": [["padded straps", "a zip that closes", "a waterproof base", "pockets for small things"],
		["a star pattern", "a bright orange colour", "a shiny badge"]],
	"a bike": [["brakes that stop it", "a chain that turns the wheel", "a bell to warn people", "tyres that grip"],
		["sparkly paint", "stickers of stars", "a two-colour frame"]],
}


## Sort an object's features: helps it work, or only changes its look. Level 1: a lamp or a chair; level 2: a kettle or a
## backpack; level 3: any object, with three that help it work or three of looks.
static func form_function(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = [["a desk lamp", "a chair"], ["a kettle", "a backpack"], FEATURES.keys()][clampi(level, 1, 3) - 1]
	var thing := str(names[rng.randi_range(0, names.size() - 1)])
	var work: Array = (FEATURES[thing][0] as Array).duplicate()
	var look: Array = (FEATURES[thing][1] as Array).duplicate()
	K.shuffle(rng, work)
	K.shuffle(rng, look)
	var nw := rng.randi_range(2, 3)
	var picked: Array = []
	for i in nw:
		picked.append([work[i], 0])
	for i in 5 - nw:
		picked.append([look[i], 1])
	K.shuffle(rng, picked)
	var items: Array = []
	var answer: Array = []
	var works: Array[String] = []
	for p: Array in picked:
		items.append(str(p[0]))
		answer.append(int(p[1]))
		if int(p[1]) == 0:
			works.append(str(p[0]))
	var ex := {"type": "sort", "prompt": "Features of %s: do they help it work, or only change its look?" % thing,
		"groups": ["helps it work", "only its look"], "items": items, "answer": answer,
		"hint": "Would it still do its job without this feature?",
		"explain": "These help it work: %s. The others change only how it looks." % "; ".join(works)}
	ex.data = {"thing": thing}
	return ex


## Animation's frames. Level 1: frames at 24 a second; level 2: drawings on twos, or seconds from frames; level 3: a
## whole Short's drawings on twos, in minutes.
static func frame_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var s := rng.randi_range(2, 10)
			ex = K.number("Film shows 24 frames a second. How many frames are in %d seconds?" % s, 24 * s,
				"Multiply the frames a second by the seconds.", "24 × %d = %d frames." % [s, 24 * s])
			ex.data = {"ask": "frames", "seconds": s}
		2:
			if rng.randi() % 2 == 0:
				var s := rng.randi_range(2, 12)
				ex = K.number("An animator draws on twos at 24 frames a second. How many drawings are in %d seconds?" % s, 12 * s,
					"On twos, how many drawings make one second?", "24 ÷ 2 = 12 drawings a second, and 12 × %d = %d." % [s, 12 * s])
				ex.data = {"ask": "drawings", "seconds": s}
			else:
				var f := rng.randi_range(2, 20) * 12
				ex = K.number("A movement takes %d frames at 24 frames a second. How many seconds is that?" % f, _dec(f, 24),
					"Divide the frames by the frames a second.", "%d ÷ 24 = %s seconds." % [f, _dec(f, 24)])
				ex.data = {"ask": "seconds", "frames": f}
		_:
			var m := rng.randi_range(1, 5)
			ex = K.number("A %d-minute Short is drawn on twos at 24 frames a second. How many drawings is that?" % m, m * 60 * 12,
				"Find the seconds and the drawings a second first.",
				"%d minute%s = %d seconds; on twos, 12 drawings a second; %d × 12 = %s drawings." % [m, "" if m == 1 else "s",
					m * 60, m * 60, K.fmt(m * 720)])
			ex.data = {"ask": "short", "minutes": m}
	return ex


## A mobile's arm. Level 1: the hidden weight, one shape a side; level 2: the hidden weight, two shapes on the known side;
## level 3: which way a still arm will tip.
static func balance_mobile(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		var left: Array = []
		var right: Array = []
		var t := 0
		for _try in 40:
			left = [[rng.randi_range(1, 9), rng.randi_range(1, 5)]]
			right = [[rng.randi_range(1, 9), rng.randi_range(1, 5)]]
			if rng.randi() % 2 == 0:
				var d := rng.randi_range(1, 5)
				if d != int(left[0][1]):
					left.append([rng.randi_range(1, 5), d])
			t = int(left[0][0]) * int(left[0][1]) - int(right[0][0]) * int(right[0][1])
			if left.size() > 1:
				t += int(left[1][0]) * int(left[1][1])
			if absi(t) <= 6 and t != 0 and int(left[0][0]) != int(right[0][0]):
				break
		var pic := {"kind": "mobile_balance", "left": left, "right": right, "still": true}
		var said := func(side: Array) -> String:
			var parts: Array[String] = []
			var sum := 0
			for wd: Array in side:
				parts.append("%d × %d" % [int(wd[0]), int(wd[1])])
				sum += int(wd[0]) * int(wd[1])
			return "%s = %d" % [" + ".join(parts), sum]
		var down := "left side down" if t > 0 else ("right side down" if t < 0 else "it balances")
		var wrongs: Array = []
		for c: String in ["left side down", "right side down", "it balances"]:
			if c != down:
				wrongs.append(c)
		var ex := K.choice(rng, "This arm is held still. Which way will it tip when it is let go?", down, wrongs,
			"Work out weight × distance on each side; the bigger side turns down.",
			"Left: %s. Right: %s. %s." % [said.call(left), said.call(right), "The left turns more" if t > 0 else
				("The right turns more" if t < 0 else "They are equal, so it stays level")], pic)
		ex.data = {"left": left, "right": right}
		return ex
	var dk := rng.randi_range(1, 5)
	var known: Array = [[rng.randi_range(1, 8), dk]]
	if level == 2:
		var d2 := rng.randi_range(1, 5)
		while d2 == dk:
			d2 = rng.randi_range(1, 5)
		known.append([rng.randi_range(1, 6), d2])
	var total := 0
	var parts: Array[String] = []
	for wd: Array in known:
		total += int(wd[0]) * int(wd[1])
		parts.append("%d × %d" % [int(wd[0]), int(wd[1])])
	var divisors: Array = []
	for d in range(1, 6):
		if total % d == 0 and total / d <= 10:
			divisors.append(d)
	if divisors.is_empty():
		known = [[3, 2]]
		total = 6
		parts = ["3 × 2"]
		divisors = [2, 3]
	var hd := int(divisors[rng.randi_range(0, divisors.size() - 1)])
	var hw := total / hd
	var known_side := "left" if rng.randi() % 2 == 0 else "right"
	var other := "right" if known_side == "left" else "left"
	var pic := {"kind": "mobile_balance", known_side: known, other: [[hw, hd]], "hide": [other, 0], "still": true}
	var ex := K.number("The mobile balances. What is the hidden weight?", hw,
		"Work out the known side's weight × distance first.",
		"%s: %s = %d. %s: ? × %d = %d, so the hidden weight is %d ÷ %d = %d." % [known_side.capitalize(), " + ".join(parts),
			total, other.capitalize(), hd, total, total, hd, hw], pic)
	ex.data = {"known": known, "distance": hd}
	return ex


## A maquette at 1:n. Level 1: the real size from the model; level 2: the model's size from the real one in metres;
## level 3: the scale from both sizes.
static func maquette(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := [10, 20, 25, 50][rng.randi_range(0, 3)] as int
	var ex: Dictionary
	match level:
		1:
			var model := rng.randi_range(4, 30)
			ex = K.number("A maquette is made at 1:%d. It is %d cm tall. How tall is the real sculpture, in cm?" % [n, model],
				model * n, "At 1:%d the real work is %d times the model." % [n, n],
				"%d × %d = %s cm." % [model, n, K.fmt(model * n)])
			ex.data = {"scale": n, "model": model, "ask": "real"}
		2:
			var model := rng.randi_range(4, 30)
			var real_cm := model * n
			ex = K.number("A sculpture will be %s m tall. How tall is its maquette at 1:%d, in cm?" % [_dec(real_cm, 100), n],
				model, "Turn metres into centimetres, then divide by %d." % n,
				"%s m = %s cm, and %s ÷ %d = %d cm." % [_dec(real_cm, 100), K.fmt(real_cm), K.fmt(real_cm), n, model])
			ex.data = {"scale": n, "real": real_cm, "ask": "model"}
		_:
			var model := rng.randi_range(4, 20)
			var real_cm := model * n
			ex = K.number("A maquette %d cm tall stands for a sculpture %s m tall. The scale is 1:n. What is n?" % [model,
				_dec(real_cm, 100)], n, "How many times taller is the real work? Use the same units.",
				"%s m = %s cm, and %s ÷ %d = %d, so the scale is 1:%d." % [_dec(real_cm, 100), K.fmt(real_cm), K.fmt(real_cm),
					model, n, n])
			ex.data = {"scale": n, "model": model, "ask": "scale"}
	return ex


## Hanging an exhibition (a work's middle at 150 cm). Level 1: its top; level 2: its bottom, or equal gaps on a wall;
## level 3: the hook's height, a drop below the top.
static func hang_height(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var h := rng.randi_range(2, 12) * 10
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A work is %d cm tall and its middle is at 150 cm. How high is its top, in cm?" % h, 150 + h / 2,
				"The top is half the work's height above the middle.", "Half of %d is %d, and 150 + %d = %d cm." % [h, h / 2,
					h / 2, 150 + h / 2])
			ex.data = {"h": h, "ask": "top"}
		2:
			if rng.randi() % 2 == 0:
				ex = K.number("A work %d cm tall hangs with its middle at 150 cm. How high is its bottom edge, in cm?" % h,
					150 - h / 2, "The bottom is half the height below the middle.", "Half of %d is %d, and 150 − %d = %d cm." % [h,
						h / 2, h / 2, 150 - h / 2])
				ex.data = {"h": h, "ask": "bottom"}
			else:
				var n := rng.randi_range(2, 4)
				var widths: Array[int] = []
				var used := 0
				for i in n:
					var w := rng.randi_range(4, 12) * 10
					widths.append(w)
					used += w
				var gaps := n + 1
				var gap := rng.randi_range(4, 12) * 10
				var wall := used + gap * gaps
				var said: Array[String] = []
				for w in widths:
					said.append("%d" % w)
				ex = K.number("Works %s cm wide hang on a wall %s cm long with %d equal gaps (between them and at both ends). How wide is each gap, in cm?" % [
					_list_said(said), K.fmt(wall), gaps], gap, "Find the space the works take, then share out what is left.",
					"%s = %d cm; %s − %d = %d cm; %d ÷ %d = %d cm." % [" + ".join(said), used, K.fmt(wall), used, wall - used,
						wall - used, gaps, gap])
				ex.data = {"widths": widths, "wall": wall, "ask": "gap"}
		_:
			var drop := rng.randi_range(1, 4) * 5
			var top := 150 + h / 2
			ex = K.number("A work %d cm tall has its middle at 150 cm. Its hook is %d cm below its top. How high is the hook, in cm?" % [
				h, drop], top - drop, "Find the top first, then go down to the hook.",
				"Half of %d is %d, so the top is at 150 + %d = %d cm; the hook is %d − %d = %d cm." % [h, h / 2, h / 2, top, top,
					drop, top - drop])
			ex.data = {"h": h, "drop": drop, "ask": "hook"}
	return ex


# --- Music -----------------------------------------------------------------------------------------------------------

## What each composer or musician is known for (composer_match): the Romantic ones first.
const KNOWN_FOR := {"Frédéric Chopin": "piano nocturnes", "Pyotr Tchaikovsky": "Swan Lake", "Bedrich Smetana": "the river Vltava",
	"Clara Schumann": "a great pianist", "Claude Debussy": "the whole-tone scale", "Igor Stravinsky": "The Rite of Spring",
	"Arnold Schoenberg": "all 12 notes equal", "John Cage": "a piece of silence", "Louis Armstrong": "jazz trumpet solos",
	"Ella Fitzgerald": "scat singing", "Claudio Monteverdi": "L'Orfeo"}
const ROMANTICS: Array[String] = ["Frédéric Chopin", "Pyotr Tchaikovsky", "Bedrich Smetana", "Clara Schumann"]
## Music's events and their years (music_order).
const MUSIC_EVENTS := {"Monteverdi's L'Orfeo": 1607, "Mozart's The Magic Flute": 1791, "Smetana's Vltava": 1874,
	"Tchaikovsky's Swan Lake": 1877, "Tchaikovsky's The Nutcracker": 1892, "Stravinsky's The Rite of Spring": 1913,
	"the theremin": 1920, "the musical Show Boat": 1927, "music from recorded sounds": 1948, "Cage's silent piece": 1952}


## A match exercise from pairs [[left, right]]: the right column shuffled, never side by side.
static func _match(rng: RandomNumberGenerator, prompt: String, pairs: Array, hint: String, explain: String) -> Dictionary:
	var items: Array = []
	var right: Array = []
	for p: Array in pairs:
		items.append(p[0])
		right.append(p[1])
	var shown := right.duplicate()
	for _try in 8:
		K.shuffle(rng, shown)
		var apart := false
		for i in shown.size():
			apart = apart or shown[i] != right[i]
		if apart:
			break
	if shown == right:
		shown.reverse()
	var answer: Array = []
	for r: Variant in right:
		answer.append(shown.find(r))
	return {"type": "match", "prompt": prompt, "items": items, "matches": shown, "answer": answer, "hint": hint,
		"explain": explain}


## Match composers and musicians to what they are known for. Level 1: two Romantic composers; level 2: four of any;
## level 3: five of any.
static func composer_match(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = ROMANTICS.duplicate() if level == 1 else KNOWN_FOR.keys()
	K.shuffle(rng, names)
	var n := [2, 4, 5][clampi(level, 1, 3) - 1] as int
	var pairs: Array = []
	var said: Array[String] = []
	for i in n:
		pairs.append([names[i], KNOWN_FOR[names[i]]])
		said.append("%s: %s" % [str(names[i]), str(KNOWN_FOR[names[i]])])
	var ex := _match(rng, "Match each musician to what they are known for.", pairs,
		"Think of each one's most famous music, one at a time.", "%s." % "; ".join(said))
	ex.data = {"pairs": pairs}
	return ex


## Music's events in time order (as art_order).
static func music_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _order_by_year(rng, level, MUSIC_EVENTS, "events in music")


const SHARPS: Array[String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


## A sound's note (letter, sharp or flat, octave) for a pitch in semitones (C4 = 48).
static func _note(p: int, flats: bool = false) -> String:
	var names: Array = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"] if flats else SHARPS
	return "%s%d" % [names[posmod(p, 12)], floori(p / 12.0)]


## A note's name as the lessons write it: "F#4" → "F#", "Bb4" → "Bb".
static func _letter(note: String) -> String:
	return note.left(note.length() - 1)


## Whole-tone scales. Level 1: which notes make the one on C (heard); level 2: the note after one in the scale on C or
## D; level 3: which note is not in it.
static func whole_tone(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := 48 if level == 1 or rng.randi() % 2 == 0 else 50
	var scale: Array[String] = []
	for i in 6:
		scale.append(_letter(_note(start + 2 * i)))
	var ex: Dictionary
	match level:
		1:
			var notes: Array = []
			for i in 6:
				notes.append(_note(start + 2 * i))
			notes.append(_note(start + 12) + ":2")
			ex = K.choice(rng, "Listen. Which notes make this whole-tone scale?", ", ".join(scale),
				["C, D, E, F, G, A", "C, D, E, F#, G, A", "C, Eb, F, F#, G, Bb"],
				"Every step is a whole tone: two semitones, with no smaller steps.",
				"From C, each note is a tone higher: %s, then C again." % ", ".join(scale),
				{"kind": "keyboard", "mark": notes.slice(0, 6).map(func(n: Variant) -> String: return str(n))})
			ex.sound = {"kind": "notes", "notes": notes, "beat": 0.4}
			ex.data = {"start": start, "ask": "notes"}
		2:
			var i := rng.randi_range(1, 4)
			var right := scale[i + 1]
			var wrongs: Array = [_letter(_note(start + 2 * i + 1)), _letter(_note(start + 2 * i + 3))]
			ex = K.choice(rng, "In the whole-tone scale on %s, which note comes after %s?" % [scale[0], scale[i]], right, wrongs,
				"Go up one whole tone: count two semitones on the keyboard.",
				"The scale on %s is %s: after %s comes %s." % [scale[0], ", ".join(scale), scale[i], right])
			ex.data = {"start": start, "ask": "next", "after": scale[i]}
		_:
			var outside: Array[String] = []
			for k in 6:
				outside.append(_letter(_note(start + 2 * k + 1)))
			var right := outside[rng.randi_range(0, 5)]
			var wrongs: Array = scale.duplicate()
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which note is not in the whole-tone scale on %s?" % scale[0], right, wrongs.slice(0, 3),
				"Write out the scale, a tone at a time, then look for the odd one out.",
				"The scale on %s is %s; %s is a semitone away from its neighbours in it, so it is not in the scale." % [scale[0],
					", ".join(scale), right])
			ex.data = {"start": start, "ask": "not", "note": right}
	return ex


## Loops of different lengths that start together: after how many beats do they start together again? Level 1: two
## loops with no shared factor; level 2: two that share one; level 3: three loops.
static func loop_lcm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var loops: Array = [[[2, 3], [3, 4], [2, 5], [3, 5], [4, 5]], [[4, 6], [6, 8], [6, 9], [4, 10], [8, 12]],
		[[2, 3, 4], [3, 4, 6], [2, 5, 6], [3, 4, 5], [4, 6, 8]]][clampi(level, 1, 3) - 1]
	var pick: Array = loops[rng.randi_range(0, loops.size() - 1)]
	var l := 1
	for v: int in pick:
		l = l * v / _gcd(l, v)
	var said: Array[String] = []
	var counts: Array[String] = []
	for v: int in pick:
		said.append(str(v))
		var c: Array[String] = []
		var k := v
		while k <= l:
			c.append(str(k))
			k += v
		counts.append(", ".join(c))
	var work := "%s: they all reach %d." % [" and ".join(counts), l]
	if pick.size() > 2:
		work = "Count in the longest loop, %d: %s. The first count that %s both go into is %d." % [int(pick[-1]),
			counts[-1], " and ".join(said.slice(0, said.size() - 1)), l]
	var ex := K.number("Loops of %s beats start together. After how many beats do they all start together again?" % _list_said(said),
		l, "Count in each loop's length until every count reaches the same number.", work)
	ex.data = {"loops": pick}
	return ex


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return a


## Straight or swung quavers, heard. Level 1: slow; level 2: quicker; level 3: a melody that leaps.
static func swing_hear(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var swung := rng.randi() % 2 == 0
	var pool: Array[String] = ["C4", "D4", "E4", "G4", "A4", "C5", "D5", "E5"]
	var pairs := 3
	var notes: Array = []
	var prev := rng.randi_range(0, 4)
	for i in pairs:
		var a := prev
		var b := clampi(a + (rng.randi_range(-1, 1) if level < 3 else rng.randi_range(-4, 4)), 0, pool.size() - 1)
		if swung:
			notes.append(pool[a] + ":2")
			notes.append(pool[b])
		else:
			notes.append(pool[a])
			notes.append(pool[b])
		prev = b
	notes.append(pool[prev] + (":3" if swung else ":2"))
	var unit := [0.0, 0.2, 0.15, 0.15][clampi(level, 1, 3)] as float
	var beat := unit if swung else unit * 1.5
	var right := "swung: long-short" if swung else "straight: even"
	var ex := K.choice(rng, "Listen. Are these quavers straight or swung?", right,
		["straight: even" if swung else "swung: long-short"], "Listen to each pair: are the two notes the same length?",
		"Each pair goes long-short, long-short: swing." if swung else "Each pair is even, the same length: straight.")
	ex.sound = {"kind": "notes", "notes": notes, "beat": beat}
	ex.data = {"swung": swung}
	return ex


## The blues scales (root, minor third, fourth, sharpened fourth, fifth, minor seventh), as the lessons spell them.
const BLUES := {"C": ["C", "E flat", "F", "F sharp", "G", "B flat"], "G": ["G", "B flat", "C", "C sharp", "D", "F"],
	"D": ["D", "F", "G", "G sharp", "A", "C"], "A": ["A", "C", "D", "D sharp", "E", "G"],
	"F": ["F", "A flat", "B flat", "B", "C", "E flat"]}
## Notes that are not in each blues scale, for wrong choices.
const NOT_BLUES := {"C": ["E", "A", "D", "B"], "G": ["B", "E", "A", "F sharp"], "D": ["F sharp", "B", "E", "C sharp"],
	"A": ["C sharp", "F sharp", "B", "G sharp"], "F": ["A", "D", "G", "E"]}


## Blues scales. Level 1: a note in the C blues scale; level 2: a note in the blues scale of G, D, A or F; level 3: the
## note that is not in one.
static func blues_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var key := "C" if level == 1 else ["G", "D", "A", "F"][rng.randi_range(0, 3)] as String
	var notes: Array = BLUES[key]
	var outs: Array = (NOT_BLUES[key] as Array).duplicate()
	K.shuffle(rng, outs)
	var ex: Dictionary
	if level < 3:
		var right := str(notes[rng.randi_range(1, 5)])
		ex = K.choice(rng, "Which note is in the %s blues scale?" % key, right, outs.slice(0, 3),
			"Build it from %s: up a minor third, a fourth, a sharpened fourth, a fifth and a minor seventh." % key,
			"The %s blues scale is %s." % [key, ", ".join(notes)])
	else:
		var right := str(outs[0])
		var ins: Array = notes.slice(1)
		K.shuffle(rng, ins)
		ex = K.choice(rng, "Which note is not in the %s blues scale?" % key, right, ins.slice(0, 3),
			"Write out the six notes from %s, then find the odd one out." % key,
			"The %s blues scale is %s, so %s is not in it." % [key, ", ".join(notes), right])
	ex.data = {"key": key}
	return ex


## Jazz choruses of 12 bars. Level 1: bars in some choruses; level 2: turns of 4 bars when trading fours; level 3: the
## seconds some choruses last at a tempo.
static func chorus_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c := rng.randi_range(2, 6)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A 12-bar blues is played as %d choruses. How many bars is that?" % c, 12 * c, "Each chorus is 12 bars.",
				"12 × %d = %d bars." % [c, 12 * c])
			ex.data = {"choruses": c, "ask": "bars"}
		2:
			ex = K.number("Two players trade fours for %d choruses of 12 bars. How many turns of 4 bars is that?" % c, 3 * c,
				"How many fours fit in one chorus?", "12 ÷ 4 = 3 turns a chorus, and 3 × %d = %d turns." % [c, 3 * c])
			ex.data = {"choruses": c, "ask": "fours"}
		_:
			var bpm := [60, 80, 96, 120, 144][rng.randi_range(0, 4)] as int
			var beats := 48 * c
			ex = K.number("%d choruses of 12 bars, 4 beats a bar, at %d beats a minute: how many seconds?" % [c, bpm],
				_dec(beats * 60, bpm), "Count the beats first, then the seconds.",
				"12 × 4 × %d = %d beats; %d × 60 ÷ %d = %s seconds." % [c, beats, beats, bpm, _dec(beats * 60, bpm)])
			ex.data = {"choruses": c, "bpm": bpm, "ask": "seconds"}
	return ex


## Loops and tempo in a track. Level 1: the beats in some bars; level 2: the seconds they last; level 3: an echo's
## milliseconds, or how many times a loop plays in a minute.
static func loop_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var bars := [2, 4, 8, 16][rng.randi_range(0, 3)] as int
	var per := [3, 4][rng.randi_range(0, 1)] as int
	var bpm := [60, 75, 80, 96, 100, 120, 125, 150][rng.randi_range(0, 7)] as int
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A loop is %d bars of %d beats. How many beats is that?" % [bars, per], bars * per,
				"Multiply the bars by the beats in each.", "%d × %d = %d beats." % [bars, per, bars * per])
			ex.data = {"ask": "beats", "bars": bars, "per": per}
		2:
			ex = K.number("A loop of %d bars of %d beats plays at %d beats a minute. How many seconds does it last?" % [bars,
				per, bpm], _dec(bars * per * 60, bpm), "Find the beats, then how long each beat lasts.",
				"%d × %d = %d beats; each lasts 60 ÷ %d seconds; %d × 60 ÷ %d = %s seconds." % [bars, per, bars * per, bpm,
					bars * per, bpm, _dec(bars * per * 60, bpm)])
			ex.data = {"ask": "seconds", "bars": bars, "per": per, "bpm": bpm}
		_:
			if rng.randi() % 2 == 0:
				ex = K.number("An echo repeats once every beat at %d beats a minute. How many milliseconds apart are the repeats?" % bpm,
					_dec(60000, bpm), "A minute is 60,000 milliseconds.", "60,000 ÷ %d = %s milliseconds." % [bpm,
						_dec(60000, bpm)])
				ex.data = {"ask": "echo", "bpm": bpm}
			else:
				var loops := [[2, 3, 120], [4, 3, 120], [2, 4, 120], [4, 4, 120], [2, 3, 60], [1, 4, 120], [4, 3, 96]]
				var l: Array = loops[rng.randi_range(0, loops.size() - 1)]
				var b := int(l[0]) * int(l[1])
				ex = K.number("A loop of %d bar%s of %d beats plays at %d beats a minute. How many times does it play in 1 minute?" % [
					int(l[0]), "" if int(l[0]) == 1 else "s", int(l[1]), int(l[2])], _dec(int(l[2]), b),
					"Find how many beats one loop takes, then how many loops fit in the minute's beats.",
					"%d × %d = %d beats a loop; %d beats a minute ÷ %d = %s times." % [int(l[0]), int(l[1]), b, int(l[2]), b,
						_dec(int(l[2]), b)])
				ex.data = {"ask": "loops", "beats": b, "bpm": int(l[2])}
	return ex


## The EQ band each sound mostly lives in (eq_band).
const BANDS := {"bass drum": "low", "bass guitar": "low", "tuba": "low", "double bass": "low", "singing voice": "middle",
	"guitar chords": "middle", "piano chords": "middle", "cymbals": "high", "hi-hat": "high", "triangle": "high",
	"whistle": "high"}


## EQ. Level 1: low or high for a sound; level 2: low, middle or high; level 3: which band to turn down for a muddy or a
## harsh mix.
static func eq_band(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var muddy := rng.randi() % 2 == 0
		var right := "the low band" if muddy else "the high band"
		ex = K.choice(rng, "A mix sounds %s. Which band of EQ would you turn down first?" % ("muddy and boomy" if muddy else
			"harsh and hissy"), right, ["the middle band", "the high band" if muddy else "the low band"],
			"Which sounds are boomy, and which are hissy?",
			"Boom lives in the low band, so turn the low band down." if muddy else
			"Hiss and harshness live in the high band, so turn the high band down.")
		ex.data = {"ask": "fix", "muddy": muddy}
		return ex
	var names: Array = BANDS.keys().filter(func(n: Variant) -> bool: return level == 2 or BANDS[n] != "middle")
	var sound := str(names[rng.randi_range(0, names.size() - 1)])
	var band := str(BANDS[sound])
	var options: Array = ["low", "high"] if level == 1 else ["low", "middle", "high"]
	var wrongs: Array = options.filter(func(o: Variant) -> bool: return o != band).map(func(o: Variant) -> String: return "the %s band" % o)
	ex = K.choice(rng, "Which band of EQ is the %s mostly in?" % sound, "the %s band" % band, wrongs,
		"Is it a deep sound, a voice-like one, or a bright, sizzling one?", "The %s is mostly in the %s band." % [sound, band])
	ex.data = {"ask": "band", "sound": sound}
	return ex


const LETTER_STEPS := "CDEFGAB"


## A note moved `steps` letters up the C major scale ("C4" + 1 = "D4"; "B4" + 1 = "C5").
static func _scale_step(note: String, steps: int) -> String:
	var i := LETTER_STEPS.find(note.left(1)) + 7 * int(note.right(1)) + steps
	return "%s%d" % [LETTER_STEPS[posmod(i, 7)], floori(i / 7.0)]


## A list of notes as "C4, E4 and G4".
static func _notes_said(notes: Array) -> String:
	var s: Array[String] = []
	for n: Variant in notes:
		s.append(str(n))
	return _list_said(s)


## Transposing a short melody. Level 1: up or down an octave; level 2: up a step in C major (a sequence); level 3: up a
## whole tone, with sharps.
static func transpose(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := rng.randi_range(0, 4)
	var mel: Array = []
	for i in 3:
		mel.append(_scale_step("C4", start + [0, 2, 1, 4][rng.randi_range(0, 3)] if i > 0 else start))
	var right: Array = []
	var wrongs: Array = []
	var prompt := ""
	var work := ""
	match level:
		1:
			var up := rng.randi() % 2 == 0
			for n: Variant in mel:
				right.append(_scale_step(str(n), 7 if up else -7))
			prompt = "Move %s %s an octave. What do you get?" % [_notes_said(mel), "up" if up else "down"]
			wrongs = [_shift_all(mel, -7 if up else 7), _shift_all(mel, 1), _shift_all(mel, 0)]
			work = "The same letters, the octave number %s 1: %s." % ["plus" if up else "minus", _notes_said(right)]
		2:
			for n: Variant in mel:
				right.append(_scale_step(str(n), 1))
			prompt = "Move %s up one step of the C major scale (a sequence). What do you get?" % _notes_said(mel)
			wrongs = [_shift_all(mel, -1), _shift_all(mel, 2), _shift_all(mel, 7)]
			work = "Each note moves to the next letter up: %s." % _notes_said(right)
		_:
			var mel_p: Array = []
			for n: Variant in mel:
				mel_p.append(SchoolPictureG8Arts.pitch_of(str(n)))
			for p: Variant in mel_p:
				right.append(_note(int(p) + 2))
			var semi: Array = []
			var thr: Array = []
			for p: Variant in mel_p:
				semi.append(_note(int(p) + 1))
				thr.append(_note(int(p) + 3))
			prompt = "Move %s up a whole tone (2 semitones). What do you get?" % _notes_said(mel)
			wrongs = [_notes_said(semi), _notes_said(thr), _shift_all(mel, 1)]
			work = "Each note goes up 2 semitones: %s." % _notes_said(right)
	var right_said := _notes_said(right)
	var ex := K.choice(rng, prompt, right_said, wrongs.filter(func(w: Variant) -> bool: return str(w) != right_said),
		"Move every note by the same amount, one note at a time.", work)
	ex.data = {"melody": mel, "level": level}
	return ex


static func _shift_all(mel: Array, steps: int) -> String:
	var out: Array = []
	for n: Variant in mel:
		out.append(_scale_step(str(n), steps))
	return _notes_said(out)


## Which instrument can (or cannot) play a note, on the ranges chart. Level 1: a very low or very high note; level 2: a
## note only one of four can play; level 3: the one that cannot.
static func range_fit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = SchoolPictureG8Arts.RANGE_NAMES.duplicate()
	for _try in 80:
		K.shuffle(rng, names)
		var four: Array = names.slice(0, 4)
		var p := rng.randi_range(SchoolPictureG8Arts.pitch_of("E1"), SchoolPictureG8Arts.pitch_of("A7"))
		var note := _note(p)
		if note.contains("#"):
			continue
		var can: Array = []
		for n: Variant in four:
			var rg := SchoolPictureG8Arts.range_of(str(n))
			if p >= rg[0] and p <= rg[1]:
				can.append(n)
		var want := 1 if level < 3 else 3
		if can.size() != want:
			continue
		var pic := {"kind": "instrument_ranges", "instruments": four, "note": note}
		var right := ""
		var wrongs: Array = []
		var prompt := ""
		if level < 3:
			right = "the %s" % str(can[0])
			for n: Variant in four:
				if n != can[0]:
					wrongs.append("the %s" % str(n))
			prompt = "Which of these can play %s?" % note
		else:
			for n: Variant in four:
				if not can.has(n):
					right = "the %s" % str(n)
				else:
					wrongs.append("the %s" % str(n))
			prompt = "Which of these cannot play %s?" % note
		var ex := K.choice(rng, prompt, right, wrongs, "Find the red line at %s, then the bars that reach it." % note,
			"%s's bar %s the line at %s." % [right.left(1).to_upper() + right.substr(1), "reaches" if level < 3 else
				"does not reach", note], pic)
		ex.data = {"note": note, "instruments": four, "ask": "can" if level < 3 else "cannot"}
		return ex
	var fallback := {"kind": "instrument_ranges", "instruments": ["flute", "violin", "cello", "double bass"], "note": "E1"}
	var ex2 := K.choice(rng, "Which of these can play E1?", "the double bass", ["the flute", "the violin", "the cello"],
		"Find the red line at E1, then the bars that reach it.", "The double bass's bar reaches the line at E1.", fallback)
	ex2.data = {"note": "E1", "instruments": fallback.instruments, "ask": "can"}
	return ex2


const MELODIES: Array = [["E5", "D5", "C5", "D5", "E5", "E5", "E5:2"], ["C5", "E5", "G5", "E5", "F5", "D5", "C5:2"],
	["G4", "A4", "B4", "C5", "D5", "B4", "G4:2"], ["A4", "C5", "B4", "G4", "A4", "E4", "A4:2"]]


## Textures, heard. Level 1: one melody alone, or a melody with chords; level 2: any of the three; level 3: a melody with
## chords, or two melodies at once.
static func texture_hear(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kinds: Array = [["mono", "homo"], ["mono", "homo", "poly"], ["homo", "poly"]][clampi(level, 1, 3) - 1]
	var kind := str(kinds[rng.randi_range(0, kinds.size() - 1)])
	var mel: Array = MELODIES[rng.randi_range(0, MELODIES.size() - 1)]
	var sound := {"kind": "notes", "notes": mel, "beat": 0.4}
	match kind:
		"homo":
			sound.parts = [{"notes": ["C4+E4+G4:2", "F3+A3+C4:2", "G3+B3+D4:2", "C4+E4+G4:2"], "volume": 0.6}]
		"poly":
			var later: Array = ["-:2"]
			for n: Variant in mel.slice(0, 5):
				later.append(_scale_step(str(n).split(":")[0], -7))
			later.append("-")
			sound.parts = [{"notes": later, "volume": 0.8}]
	var names := {"mono": "monophonic: one melody alone", "homo": "homophonic: a melody with chords",
		"poly": "polyphonic: melodies together"}
	var wrongs: Array = []
	for k: String in names:
		if k != kind:
			wrongs.append(names[k])
	var ex := K.choice(rng, "Listen. What is the texture?", names[kind], wrongs,
		"How many things play at once, and are they tunes or chords?",
		{"mono": "One melody plays with nothing under it: monophonic.",
			"homo": "A melody plays on top with chords under it: homophonic.",
			"poly": "The melody enters again lower and later, so two melodies sound together: polyphonic."}[kind])
	ex.sound = sound
	ex.data = {"kind": kind}
	return ex


## Where each style of music grew (culture_match).
const PLACES := {"tango": "Argentina and Uruguay", "flamenco": "Spain", "fado": "Portugal", "reggae": "Jamaica",
	"samba": "Brazil", "gamelan": "Indonesia", "calypso": "Trinidad and Tobago", "mariachi": "Mexico", "highlife": "Ghana"}


## Styles and places. Level 1: one style, three places to choose from; level 2: match three; level 3: match five.
static func culture_match(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var styles: Array = PLACES.keys()
	K.shuffle(rng, styles)
	var ex: Dictionary
	if level == 1:
		var s := str(styles[0])
		ex = K.choice(rng, "Where did %s grow?" % s, str(PLACES[s]), [str(PLACES[styles[1]]), str(PLACES[styles[2]])],
			"Think of the lesson's list of styles and places.", "%s grew in %s." % [s.capitalize(), str(PLACES[s])])
	else:
		var n := 3 if level == 2 else 5
		var pairs: Array = []
		var said: Array[String] = []
		for i in n:
			pairs.append([styles[i], PLACES[styles[i]]])
			said.append("%s: %s" % [str(styles[i]), str(PLACES[styles[i]])])
		ex = _match(rng, "Match each style to where it grew.", pairs, "Think of the lesson's list of styles and places.",
			"%s." % "; ".join(said))
	ex.data = {"styles": styles.slice(0, 5)}
	return ex


## Big forms' movements. Level 1: a concerto's three movements in minutes; level 2: a symphony's four; level 3: the
## missing movement from the whole length.
static func form_plan(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 3 if level == 1 else 4
	var mins: Array[int] = []
	var total := 0
	for i in n:
		var m := rng.randi_range(4, 15)
		mins.append(m)
		total += m
	var said: Array[String] = []
	for m in mins:
		said.append(str(m))
	var form := "concerto" if n == 3 else "symphony"
	var ex: Dictionary
	if level < 3:
		ex = K.number("A %s's movements last %s minutes. How many minutes in all?" % [form, _list_said(said)], total,
			"Add the movements.", "%s = %d minutes." % [" + ".join(said), total])
		ex.data = {"minutes": mins, "ask": "total"}
	else:
		var hide := rng.randi_range(0, n - 1)
		var known: Array[String] = []
		var known_sum := 0
		for i in n:
			if i != hide:
				known.append(str(mins[i]))
				known_sum += mins[i]
		ex = K.number("A symphony lasts %d minutes. Three of its movements last %s minutes. How long is the other one?" % [total,
			_list_said(known)], mins[hide], "Add the three you know, then take that from the whole.",
			"%s = %d, and %d − %d = %d minutes." % [" + ".join(known), known_sum, total, known_sum, mins[hide]])
		ex.data = {"minutes": mins, "ask": "missing", "hide": hide}
	return ex


const TREBLE: Array[String] = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5", "A5"]


## Reading notes at sight. Level 1: a marked note between C4 and C5; level 2: any note to A5; level 3: a note in G or F
## major, its sharp or flat from the key signature.
static func note_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var top := 7 if level == 1 else TREBLE.size() - 1
		var notes: Array = []
		for i in 4:
			notes.append(TREBLE[rng.randi_range(0, top)])
		var mark := rng.randi_range(0, 3)
		var right := str(notes[mark]).left(1)
		var i := LETTER_STEPS.find(right)
		ex = K.choice(rng, "Which note is marked in orange?", right, [LETTER_STEPS[(i + 1) % 7], LETTER_STEPS[(i + 6) % 7],
			LETTER_STEPS[(i + 2) % 7]], "Count up the lines and spaces from a note you know, such as E on the bottom line.",
			"The marked note is %s." % str(notes[mark]), {"kind": "stave", "notes": notes, "mark": mark})
		ex.data = {"notes": notes, "mark": mark}
	else:
		var key := "G" if rng.randi() % 2 == 0 else "F"
		var changed := "F" if key == "G" else "B"
		var said := "F sharp" if key == "G" else "B flat"
		var notes: Array = [TREBLE[rng.randi_range(0, 12)], "F5" if key == "G" else "B4", TREBLE[rng.randi_range(0, 12)]]
		K.shuffle(rng, notes)
		var idx := notes.find("F5" if key == "G" else "B4")
		ex = K.choice(rng, "In %s major, how is note %d played?" % [key, idx + 1], said,
			[changed, "F flat" if key == "G" else "B sharp", "E" if key == "G" else "A"],
			"Read the key signature: which note does it change, and how?",
			"%s major's key signature changes every %s to %s." % [key, changed, said],
			{"kind": "key_signature", "key": key, "notes": notes, "title": true})
		ex.data = {"key": key, "notes": notes, "ask": idx}
	return ex


## Each note value's beats (bar_check).
const VALUE_BEATS := {"semibreve": 4.0, "dotted minim": 3.0, "minim": 2.0, "crotchet": 1.0, "quaver": 0.5}


## Beats in bars. Level 1: crotchets and minims; level 2: dotted minims and quavers too; level 3: the value missing to fill
## a bar of 3/4 or 4/4.
static func bar_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var pool: Array = ["crotchet", "minim"] if level == 1 else ["crotchet", "minim", "dotted minim", "quaver"]
		var values: Array = []
		var total := 0.0
		for i in rng.randi_range(3, 5):
			var v := str(pool[rng.randi_range(0, pool.size() - 1)])
			values.append(v)
			total += float(VALUE_BEATS[v])
		var notes: Array = []
		for i in values.size():
			notes.append(TREBLE[rng.randi_range(0, 7)])
		var parts: Array[String] = []
		for v: Variant in values:
			parts.append(_beats_said(float(VALUE_BEATS[v])))
		ex = K.number("How many beats do these notes last in all?", _beats_said(total),
			"Write each note's beats under it, then add them.", "%s = %s beats." % [" + ".join(parts), _beats_said(total)],
			{"kind": "stave", "notes": notes, "values": values})
		ex.data = {"values": values}
	else:
		var per := 3 if rng.randi() % 2 == 0 else 4
		var fills: Array = [["minim", "crotchet"], ["crotchet", "crotchet"], ["dotted minim"], ["minim"], ["crotchet"]]
		var missing := ""
		var have: Array = []
		for _try in 20:
			have = fills[rng.randi_range(0, fills.size() - 1)]
			var sum := 0.0
			for v: Variant in have:
				sum += float(VALUE_BEATS[v])
			var gap := float(per) - sum
			for v: String in VALUE_BEATS:
				if is_equal_approx(float(VALUE_BEATS[v]), gap):
					missing = v
			if missing != "":
				break
		var wrongs: Array = []
		for v: String in ["crotchet", "minim", "dotted minim", "semibreve", "quaver"]:
			if v != missing:
				wrongs.append("a %s" % v)
		var have_said: Array[String] = []
		var sum2 := 0.0
		for v: Variant in have:
			have_said.append("a %s" % str(v))
			sum2 += float(VALUE_BEATS[v])
		ex = K.choice(rng, "A bar of %d/4 has %s. Which one note fills the bar?" % [per, _list_said(have_said)],
			"a %s" % missing, wrongs.slice(0, 3), "Add up the beats there, then take them from %d." % per,
			"%s beats are there; %d − %s = %s, so a %s fills it." % [_beats_said(sum2), per, _beats_said(sum2),
				_beats_said(per - sum2), missing])
		ex.data = {"per": per, "have": have}
	return ex


static func _beats_said(b: float) -> String:
	return str(int(b)) if is_equal_approx(b, roundf(b)) else _dec(int(b * 10), 10)


## Developing a motif (3 notes of C major). Level 1: a sequence up a step; level 2: an inversion (each step turned the
## other way about the first note) or the motif backwards (retrograde); level 3: a sequence down a step, or augmentation.
static func motif_move(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := rng.randi_range(2, 6)
	var motif: Array = [_scale_step("C4", start)]
	for i in 2:
		motif.append(_scale_step(str(motif[-1]), [1, 2, -1, -2][rng.randi_range(0, 3)]))
	var how := ""
	match level:
		1:
			how = "sequence"
		2:
			how = ["inversion", "retrograde"][rng.randi_range(0, 1)]
		_:
			how = ["sequence down", "augmentation"][rng.randi_range(0, 1)]
	var right: Array = []
	match how:
		"sequence":
			right = motif.map(func(n: Variant) -> String: return _scale_step(str(n), 1))
		"sequence down":
			right = motif.map(func(n: Variant) -> String: return _scale_step(str(n), -1))
		"inversion":
			var base := LETTER_STEPS.find(str(motif[0]).left(1)) + 7 * int(str(motif[0]).right(1))
			for n: Variant in motif:
				var k := LETTER_STEPS.find(str(n).left(1)) + 7 * int(str(n).right(1))
				right.append(_scale_step(str(motif[0]), base - k))
		"retrograde":
			right = motif.duplicate()
			right.reverse()
			if right == motif:
				how = "sequence"
				right = motif.map(func(n: Variant) -> String: return _scale_step(str(n), 1))
		"augmentation":
			right = motif.map(func(n: Variant) -> String: return str(n) + ":2")
	var names := {"sequence": "a sequence: a step higher", "sequence down": "a sequence: a step lower",
		"inversion": "an inversion: upside down", "retrograde": "a retrograde: backwards",
		"augmentation": "augmentation: longer notes"}
	var notes: Array = motif.duplicate()
	notes.append("-")
	notes.append_array(right)
	var wrongs: Array = []
	for k: String in names:
		if k != how and (right != motif or k != "retrograde"):
			wrongs.append(names[k])
	K.shuffle(rng, wrongs)
	var work := "The motif %s becomes %s: %s." % [_notes_said(motif), _notes_said(right), names[how]]
	if how == "augmentation":
		work = "The motif %s comes back with the same notes, each twice as long: augmentation." % _notes_said(motif)
	var ex := K.choice(rng, "Listen: the motif, then a change of it. What changed?", names[how], wrongs.slice(0, 2),
		"Compare the second group with the first: higher, lower, upside down, backwards or slower?", work)
	ex.sound = {"kind": "notes", "notes": notes, "beat": 0.4}
	ex.data = {"motif": motif, "how": how, "right": right}
	return ex


## The primary chords of C, G and F major, as the lessons spell them.
const PRIMARY := {"C": {"I": ["C", "E", "G"], "IV": ["F", "A", "C"], "V": ["G", "B", "D"]},
	"G": {"I": ["G", "B", "D"], "IV": ["C", "E", "G"], "V": ["D", "F sharp", "A"]},
	"F": {"I": ["F", "A", "C"], "IV": ["B flat", "D", "F"], "V": ["C", "E", "G"]}}


## Which primary chord fits a melody: a bar's main note (level 1: C major; level 2: G or F major) or two notes in a bar
## (level 3, any of the three keys) that only one of I, IV and V contains.
static func chord_fit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var key := "C" if level == 1 else ["G", "F", "C"][rng.randi_range(0, 1 if level == 2 else 2)] as String
	var chords: Dictionary = PRIMARY[key]
	var want := 1 if level < 3 else 2
	var picked: Array = []
	var fits := ""
	for _try in 60:
		var all_notes: Array = []
		for c: String in chords:
			for n: Variant in chords[c]:
				if not all_notes.has(n):
					all_notes.append(n)
		K.shuffle(rng, all_notes)
		picked = all_notes.slice(0, want)
		var holders: Array = []
		for c: String in chords:
			var ok := true
			for n: Variant in picked:
				ok = ok and (chords[c] as Array).has(n)
			if ok:
				holders.append(c)
		if holders.size() == 1:
			fits = str(holders[0])
			break
	var said := func(c: String) -> String: return "%s: %s" % [c, ", ".join(PackedStringArray(chords[c]))]
	var wrongs: Array = []
	for c: String in chords:
		if c != fits:
			wrongs.append(said.call(c))
	var notes_said: Array[String] = []
	for n: Variant in picked:
		notes_said.append(str(n))
	var ex := K.choice(rng, "In %s major, a bar's main melody note%s %s. Which chord fits?" % [key,
		" is" if want == 1 else "s are", " and ".join(notes_said)], said.call(fits), wrongs,
		"Look for the chord that contains %s." % ("the note" if want == 1 else "both notes"),
		"Chord %s (%s) contains %s, so it fits." % [fits, ", ".join(PackedStringArray(chords[fits])),
			" and ".join(notes_said)])
	ex.data = {"key": key, "notes": picked}
	return ex
