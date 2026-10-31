class_name G7ArtsGen
extends RefCounted
## Owner #70 and #73 (research §6.7): grade 7 computing, art and music generators: SchoolGen "g7c.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a
## strategy, never the answer), a worked answer and `data` (tests/unit/test_g7_arts_gen.gd works every answer out again:
## it runs every program with the tests' own text-code interpreter and has its own search, sort, cipher, route, wheel,
## scale, chord, cadence, ornament, note and beat rules).
## - Computing: text_output (what a text program prints), syntax_error (the mistake that stops a program), list_item
##   (items by index, length, append), list_loop (a loop over a list: total, count, biggest), function_value (functions
##   with parameters and return), linear_checks, binary_checks (how many checks a search makes), bubble_step (a pass of
##   bubble sort), merge_step (merging and splitting), test_data (normal, boundary and erroneous tests), ip_address
##   (IP addresses and packets), route_hops (packets' routes through routers), caesar_word (the Caesar cipher),
##   clean_data (mistakes in collected data), validate_entry (validation checks), habit_check (feeds' tricks and healthy
##   habits), public_domain (when copyright ends), licence_use (what a licence allows).
## - Art: scheme_pick (colour schemes on the wheel), head_heights (a figure measured in heads), scale_drawing (plans at
##   1:50 and 1:100), thirds_place (the rule of thirds), block_print (a woodcut's mirrored print, editions), art_dates
##   (works of 1400-1650 in time order).
## - Music: primary_chord (I, IV and V in a key), cadence_ear (finished or unfinished, heard), ornament_play (trills,
##   mordents and turns), era_facts (Baroque and Classical), bass_note (the bass clef), dotted_beats (dotted notes and
##   ties), riff_repeat (riffs: repeats, moving them, heard), film_cue (music for a scene, leitmotifs heard), mix_balance
##   (a mixing desk), song_length (bars, tempo and seconds), folk_metre (jigs, reels and waltzes).

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Juno", "Ollie", "Priya", "Sam", "Kofi", "Lena"]
const VARS: Array[String] = ["gems", "coins", "score", "blocks", "stars"]
const LETTERS := "CDEFGAB"
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const MAJOR: Array[int] = [0, 2, 4, 5, 7, 9, 11]

# --- Computing -------------------------------------------------------------------------------------------------------

## What a text program prints. Level 1: variables and sums (× before +); level 2: if and else; level 3: a for loop over
## a range, or a while loop that doubles.
static func text_output(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var v := VARS[rng.randi_range(0, VARS.size() - 1)]
	var lines: Array = []
	var answer := 0
	var work := ""
	var hint := ""
	match level:
		1:
			var a := rng.randi_range(2, 9)
			var b := rng.randi_range(2, 9)
			var k := rng.randi_range(2, 4)
			lines = ["%s = %d" % [v, a], "%s = %s + %d" % [v, v, b], "print(%s * %d)" % [v, k]]
			answer = (a + b) * k
			work = "%s starts at %d, then %d + %d = %d. It prints %d × %d = %d." % [v, a, a, b, a + b, a + b, k, answer]
			hint = "Go line by line and keep the variable's value on paper; = puts a new value in."
		2:
			var c := rng.randi_range(5, 30)
			var t := rng.randi_range(8, 25)
			var x := rng.randi_range(2, 6)
			var y := rng.randi_range(2, 6)
			lines = ["%s = %d" % [v, c], "if %s > %d:" % [v, t], "    %s = %s - %d" % [v, v, x], "else:",
				"    %s = %s + %d" % [v, v, y], "print(%s)" % v]
			if c > t:
				answer = c - x
				work = "%d > %d is true, so only the if part runs: %d − %d = %d." % [c, t, c, x, answer]
			else:
				answer = c + y
				work = "%d > %d is false, so only the else part runs: %d + %d = %d." % [c, t, c, y, answer]
			hint = "Is the if line's test true or false? Only one of the two stepped-in parts runs."
		_:
			if rng.randi() % 2 == 0:
				var lo := rng.randi_range(1, 4)
				var hi := lo + rng.randi_range(3, 5)
				lines = ["total = 0", "for i in range(%d, %d):" % [lo, hi], "    total = total + i", "print(total)"]
				var nums: Array[String] = []
				for i in range(lo, hi):
					nums.append(str(i))
					answer += i
				work = "range(%d, %d) gives %s (it stops before %d). The total: %s = %d." % [lo, hi, ", ".join(nums), hi,
					" + ".join(nums), answer]
			else:
				var n := rng.randi_range(1, 3)
				var limit := rng.randi_range(20, 90)
				lines = ["n = %d" % n, "while n < %d:" % limit, "    n = n * 2", "print(n)"]
				var seq: Array[String] = [str(n)]
				while n < limit:
					n *= 2
					seq.append(str(n))
				answer = n
				work = "n doubles while it is less than %d: %s. %d is not less than %d, so the loop stops and it prints %d." % [
					limit, ", ".join(seq), n, limit, n]
			hint = "Make a table: write the variables' values each time round the loop."
	var ex := K.number("What does this program print?", answer, hint, work, {"kind": "text_code", "lines": lines})
	ex.data = {"lines": lines}
	return ex


const MISTAKES := {"colon": "a missing colon", "bracket": "a missing bracket", "quote": "a missing quote mark",
	"equals": "= where == should be", "step": "a line that should step in"}


## The mistake that stops a text program (the marked line). Level 1: a missing colon or bracket; level 2: a missing
## quote mark, = for ==, or a line that should step in; level 3: which line (from 1) has the mistake.
static func syntax_error(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var v := VARS[rng.randi_range(0, VARS.size() - 1)]
	var n := rng.randi_range(2, 9)
	var kinds: Array = ["colon", "bracket"] if level == 1 else (["quote", "equals", "step"] if level == 2 else
		["colon", "bracket", "quote", "equals", "step"])
	var kind := str(kinds[rng.randi_range(0, kinds.size() - 1)])
	var lines: Array = ["%s = %d" % [v, n], "if %s > 5:" % v, "    print(\"Well done!\")", "for i in range(3):",
		"    print(%s)" % v]
	var at := 0
	match kind:
		"colon":
			at = [1, 3][rng.randi_range(0, 1)]
			lines[at] = str(lines[at]).trim_suffix(":")
		"bracket":
			at = [2, 4][rng.randi_range(0, 1)]
			lines[at] = str(lines[at]).trim_suffix(")")
		"quote":
			at = 2
			lines[at] = "    print(\"Well done!)"
		"equals":
			at = 1
			lines[at] = "if %s = 5:" % v
		"step":
			at = [2, 4][rng.randi_range(0, 1)]
			lines[at] = str(lines[at]).strip_edges()
	if level == 3:
		var ex3 := K.number("This program will not run: one line breaks the language's rules. Which line (1-5) has the mistake?",
			at + 1, "Check each line: a colon after if and for, brackets and quote marks in pairs, == to compare, and the lines inside a block stepped in.",
			"Line %d has %s: %s." % [at + 1, MISTAKES[kind], _fix_said(kind)], {"kind": "text_code", "lines": lines})
		ex3.data = {"lines": lines, "kind": kind}
		return ex3
	var wrongs: Array = []
	for k: String in MISTAKES:
		if k != kind:
			wrongs.append(MISTAKES[k])
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "The marked line stops this program. What is the mistake?", MISTAKES[kind], wrongs.slice(0, 3),
		"Look closely at the end and the start of the marked line: colons, brackets, quote marks, = or ==, and its step in.",
		"It is %s: %s." % [MISTAKES[kind], _fix_said(kind)], {"kind": "text_code", "lines": lines, "error": at})
	ex.data = {"lines": lines, "kind": kind}
	return ex


static func _fix_said(kind: String) -> String:
	match kind:
		"colon":
			return "a line that starts a block (if, for) ends with a colon"
		"bracket":
			return "every ( needs its )"
		"quote":
			return "text starts and ends with a quote mark"
		"equals":
			return "= puts a value in, == compares two values"
	return "the lines inside a block step in 4 spaces"


## Items of a list by index (from 0). Level 1: gems[i] from a picture of the list; level 2: gems[-1] or len after
## append; level 3: a program that changes an item and appends one.
static func list_item(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var items := _distinct(rng, rng.randi_range(4, 6), 1, 30)
	var ex := {}
	match level:
		1:
			var i := rng.randi_range(0, items.size() - 1)
			var strs: Array = []
			for x: int in items:
				strs.append(str(x))
			ex = K.number("What is gems[%d]?" % i, items[i], "Indexes start at 0: gems[0] is the first box. Count along the boxes.",
				"Counting from 0, box %d holds %d, so gems[%d] is %d." % [i, items[i], i, items[i]],
				{"kind": "list_boxes", "name": "gems", "items": strs, "index": true})
			ex.data = {"items": items, "i": i}
		2:
			var list_text := "gems = [%s]" % ", ".join(PackedStringArray(items.map(func(x: int) -> String: return str(x))))
			var add := rng.randi_range(1, 30)
			var lines: Array = [list_text, "gems.append(%d)" % add]
			if rng.randi() % 2 == 0:
				lines.append("print(len(gems))")
				ex = K.number("What does this program print?", items.size() + 1,
					"append adds one item at the end; len counts the items.",
					"The list had %d items; append adds %d at the end, so len(gems) is %d." % [items.size(), add, items.size() + 1],
					{"kind": "text_code", "lines": lines})
			else:
				lines.append("print(gems[-1])")
				ex = K.number("What does this program print?", add, "-1 is the index of the last item. Where does append put its item?",
					"append puts %d at the end, and gems[-1] is the last item: %d." % [add, add], {"kind": "text_code", "lines": lines})
			ex.data = {"lines": lines}
		_:
			var items4 := items.slice(0, 4)
			var x := rng.randi_range(1, 30)
			var y := rng.randi_range(1, 30)
			var lines: Array = ["gems = [%s]" % ", ".join(PackedStringArray(items4.map(func(q: int) -> String: return str(q)))),
				"gems[1] = %d" % x, "gems.append(%d)" % y, "print(gems[1] + gems[4])"]
			ex = K.number("What does this program print?", x + y,
				"Draw the list as boxes numbered from 0 and change them line by line.",
				"gems[1] becomes %d; append puts %d in box 4. %d + %d = %d." % [x, y, x, y, x + y], {"kind": "text_code", "lines": lines})
			ex.data = {"lines": lines}
	return ex


## A loop over a list. Level 1: the total; level 2: how many items are over a number; level 3: the biggest.
static func list_loop(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var items := _distinct(rng, [0, rng.randi_range(3, 4), 5, 5][level], 1, 30)
	var list_text := "gems = [%s]" % ", ".join(PackedStringArray(items.map(func(x: int) -> String: return str(x))))
	var lines: Array = []
	var answer := 0
	var work := ""
	match level:
		1:
			lines = [list_text, "total = 0", "for g in gems:", "    total = total + g", "print(total)"]
			for x: int in items:
				answer += x
			work = "The loop adds each item: %s = %d." % [" + ".join(PackedStringArray(items.map(func(x: int) -> String: return str(x)))), answer]
		2:
			var t := rng.randi_range(8, 22)
			lines = [list_text, "count = 0", "for g in gems:", "    if g > %d:" % t, "        count = count + 1", "print(count)"]
			var over: Array[String] = []
			for x: int in items:
				if x > t:
					answer += 1
					over.append(str(x))
			work = ("The items over %d are %s: count is %d." % [t, ", ".join(over), answer]) if answer > 0 \
				else "No item is over %d, so count stays 0." % t
		_:
			lines = [list_text, "best = gems[0]", "for g in gems:", "    if g > best:", "        best = g", "print(best)"]
			answer = items.max()
			work = "best starts at %d and changes whenever an item is bigger; the biggest is %d." % [items[0], answer]
	var ex := K.number("What does this program print?", answer, "Go round the loop once for each item and keep the variable's value on paper.",
		work, {"kind": "text_code", "lines": lines})
	ex.data = {"lines": lines}
	return ex


const ONE_PARAM := [["double", "n * 2"], ["triple", "n * 3"], ["add_ten", "n + 10"], ["square", "n * n"]]


## Functions with parameters that return a value. Level 1: one parameter (a program, or a function machine); level 2:
## two parameters; level 3: a function's result passed to a function.
static func function_value(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var f: Array = ONE_PARAM[rng.randi_range(0, ONE_PARAM.size() - 1)]
			var x := rng.randi_range(2, 12)
			var out := _one(str(f[0]), x)
			var work := "n takes the value %d, and the function returns %s = %d." % [x, str(f[1]).replace("n", str(x)).replace("*", "×"), out]
			if rng.randi() % 2 == 0:
				var lines: Array = ["def %s(n):" % f[0], "    return %s" % f[1], "print(%s(%d))" % [f[0], x]]
				ex = K.number("What does this program print?", out, "The number in brackets goes into the parameter n; then work out the return line.",
					work, {"kind": "text_code", "lines": lines})
				ex.data = {"lines": lines}
			else:
				ex = K.number("%d goes into the function. What comes out?" % x, out,
					"Put the argument in place of the parameter n in the return line.", work,
					{"kind": "func_machine", "name": str(f[0]), "params": ["n"], "args": [str(x)], "body": str(f[1]), "out": "?"})
				ex.data = {"name": f[0], "x": x}
		2:
			var a := rng.randi_range(2, 9)
			var b := rng.randi_range(2, 9)
			var lines: Array = []
			var out := 0
			var work := ""
			match rng.randi_range(0, 2):
				0:
					lines = ["def area(w, h):", "    return w * h", "print(area(%d, %d))" % [a, b]]
					out = a * b
					work = "w is %d and h is %d: %d × %d = %d." % [a, b, a, b, out]
				1:
					lines = ["def perimeter(w, h):", "    return 2 * (w + h)", "print(perimeter(%d, %d))" % [a, b]]
					out = 2 * (a + b)
					work = "w is %d and h is %d: 2 × (%d + %d) = %d." % [a, b, a, b, out]
				_:
					lines = ["def cost(price, count):", "    return price * count", "print(cost(%d, %d))" % [a, b]]
					out = a * b
					work = "price is %d and count is %d: %d × %d = %d gold." % [a, b, a, b, out]
			ex = K.number("What does this program print?", out, "The arguments go into the parameters in order: the first into the first.",
				work, {"kind": "text_code", "lines": lines})
			ex.data = {"lines": lines}
		_:
			var x := rng.randi_range(2, 9)
			var y := rng.randi_range(2, 9)
			var z := rng.randi_range(2, 9)
			var lines: Array = []
			var out := 0
			var work := ""
			if rng.randi() % 2 == 0:
				lines = ["def add(a, b):", "    return a + b", "print(add(add(%d, %d), %d))" % [x, y, z]]
				out = x + y + z
				work = "The inner call first: add(%d, %d) is %d. Then add(%d, %d) is %d." % [x, y, x + y, x + y, z, out]
			else:
				lines = ["def double(n):", "    return n * 2", "def add_one(n):", "    return n + 1", "print(double(add_one(%d)))" % x]
				out = (x + 1) * 2
				work = "The inner call first: add_one(%d) is %d. Then double(%d) is %d." % [x, x + 1, x + 1, out]
			ex = K.number("What does this program print?", out, "Work from the inside out: the call in the brackets runs first.",
				work, {"kind": "text_code", "lines": lines})
			ex.data = {"lines": lines}
	return ex


static func _one(name: String, n: int) -> int:
	match name:
		"double":
			return n * 2
		"triple":
			return n * 3
		"add_ten":
			return n + 10
	return n * n


## How many checks a linear search makes, from the start. Levels 1-2: the target is in the list (5-6, then 8-10
## items); level 3: it is not there.
static func linear_checks(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var items := _distinct(rng, [0, rng.randi_range(5, 6), rng.randi_range(8, 10), rng.randi_range(6, 9)][level], 1, 40)
	var target := 0
	var answer := 0
	var work := ""
	if level < 3:
		var i := rng.randi_range(1, items.size() - 1)
		target = items[i]
		answer = i + 1
		work = "It checks %s: %d checks (%d is item %d from the start)." % [", ".join(PackedStringArray(items.slice(0, i + 1).map(
			func(x: int) -> String: return str(x)))), answer, target, i + 1]
	else:
		target = 41 + rng.randi_range(0, 8)
		answer = items.size()
		work = "%d is not in the list, and a linear search only knows that after checking all %d items: %d checks." % [target,
			items.size(), answer]
	var ex := K.number("A linear search looks for %d, checking one item after another from the start. How many checks does it make?" % target,
		answer, "Count along from the first item until you reach the target, or the end.", work,
		{"kind": "search_steps", "items": items, "target": target, "method": "linear", "steps": 0})
	ex.data = {"items": items, "target": target}
	return ex


## Binary search on a sorted list. Level 1: which item it checks first; level 2: how many checks it makes; level 3:
## the most checks it can need for a list of N items.
static func binary_checks(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	if level == 3:
		var n: int = [7, 15, 16, 31, 50, 63, 100, 127, 200, 500, 1000, 1023, 1024, 2000][rng.randi_range(0, 13)]
		var halves: Array[String] = []
		var m := n
		while m >= 1:
			halves.append(K.fmt(m))
			m /= 2
		ex = K.number("A sorted list has %s items. What is the most checks binary search can need to find one?" % K.fmt(n), halves.size(),
			"Each check throws away half of what is left. Halve %s again and again (rounding down) until 1 is left, and count." % K.fmt(n),
			"What is left: %s. That is %d checks at most." % [", ".join(halves), halves.size()])
		ex.data = {"n": n}
		return ex
	var items := _distinct(rng, rng.randi_range(7, 13), 2, 60)
	items.sort()
	var lo := 0
	var hi := items.size() - 1
	var mid := (lo + hi) / 2
	if level == 1:
		var target: int = items[rng.randi_range(0, items.size() - 1)]
		var wrongs: Array = []
		for c: int in [items[0], items[-1], items[mid - 1], items[mid + 1], target]:
			if c != items[mid] and not wrongs.has(c):
				wrongs.append(c)
		ex = K.choice(rng, "Binary search looks for %d in this sorted list. Which number does it check first?" % target, str(items[mid]),
			wrongs.slice(0, 3).map(func(x: int) -> String: return str(x)),
			"Binary search starts in the middle: add the first and last index and halve it, rounding down.",
			"The indexes go 0 to %d; (0 + %d) ÷ 2 = %d rounded down, so it checks item %d first: %d." % [hi, hi, mid, mid, items[mid]],
			{"kind": "search_steps", "items": items, "target": target, "method": "binary", "steps": 0})
		ex.data = {"items": items, "target": target}
		return ex
	var target: int = items[rng.randi_range(0, items.size() - 1)]
	var seen: Array[String] = []
	while lo <= hi:
		mid = (lo + hi) / 2
		seen.append(str(items[mid]))
		if items[mid] == target:
			break
		if items[mid] < target:
			lo = mid + 1
		else:
			hi = mid - 1
	ex = K.number("Binary search looks for %d in this sorted list. How many checks does it make?" % target, seen.size(),
		"Check the middle item (rounding down), keep the half the target is in, and count each check.",
		"It checks %s: %d check%s." % [", ".join(seen), seen.size(), "" if seen.size() == 1 else "s"],
		{"kind": "search_steps", "items": items, "target": target, "method": "binary", "steps": 0})
	ex.data = {"items": items, "target": target}
	return ex


## One pass of bubble sort. Level 1: the number at the end after one pass; level 2: the list after one pass; level 3:
## how many swaps the first pass makes.
static func bubble_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var items := _distinct(rng, [0, 4, 5, 6][level], 1, 20)
	while _is_sorted(items):
		K.shuffle(rng, items)
	var after := items.duplicate()
	var swaps := 0
	for i in after.size() - 1:
		if after[i] > after[i + 1]:
			var t: int = after[i]
			after[i] = after[i + 1]
			after[i + 1] = t
			swaps += 1
	var pic := {"kind": "sort_bars", "items": items, "method": "bubble"}
	var ex := {}
	match level:
		1:
			ex = K.number("After one pass of bubble sort (smallest to biggest), which number is at the end?", items.max(),
				"Each swap carries a bigger number along. What happens to the biggest one?",
				"The biggest number, %d, is swapped along every pair until it reaches the end." % items.max(), pic)
		2:
			var right := _csv(after)
			var wrongs: Array = []
			var sorted := items.duplicate()
			sorted.sort()
			var first_only := items.duplicate()
			if first_only[0] > first_only[1]:
				var t: int = first_only[0]
				first_only[0] = first_only[1]
				first_only[1] = t
			var rev := after.duplicate()
			rev.reverse()
			for c: Array in [sorted, items, first_only, rev]:
				var s := _csv(c)
				if s != right and not wrongs.has(s):
					wrongs.append(s)
			var fill := 0
			while wrongs.size() < 2:
				var alt := after.duplicate()
				var j := fill % (alt.size() - 1)
				var t: int = alt[j]
				alt[j] = alt[j + 1]
				alt[j + 1] = t
				if _csv(alt) != right and not wrongs.has(_csv(alt)):
					wrongs.append(_csv(alt))
				fill += 1
			ex = K.choice(rng, "What is the list after one pass of bubble sort (smallest to biggest)?", right, wrongs.slice(0, 3),
				"Compare the first two, swap them if the bigger is first, then move along one and do it again to the end.",
				"Comparing each pair from the left and swapping when the bigger is first gives %s (%d swap%s)." % [right, swaps,
					"" if swaps == 1 else "s"], pic)
		_:
			ex = K.number("How many swaps does the first pass of bubble sort make (smallest to biggest)?", swaps,
				"Go along the pairs one by one, swapping on paper, and count each swap.",
				"Pass 1 goes from %s to %s with %d swap%s." % [_csv(items), _csv(after), swaps, "" if swaps == 1 else "s"], pic)
	ex.data = {"items": items}
	return ex


## Merge sort. Level 1: the first number of two sorted lists merged; level 2: how many times a list halves until every
## group is one item; level 3: the merged list.
static func merge_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		2:
			var k := rng.randi_range(1, 5)
			var n := 1 << k
			var halves: Array[String] = []
			var m := n
			while m > 1:
				m /= 2
				halves.append(str(m))
			ex = K.number("Merge sort splits a list of %d items in half, then the halves in half, until every group has 1 item. How many rounds of splitting is that?" % n,
				k, "Halve %d again and again until you reach 1, and count the halvings." % n,
				"%d halves to %s: %d round%s of splitting." % [n, ", ".join(halves), k, "" if k == 1 else "s"])
			ex.data = {"n": n}
		_:
			var all := _distinct(rng, 6, 1, 40)
			var a := all.slice(0, 3)
			var b := all.slice(3)
			a.sort()
			b.sort()
			var merged := all.duplicate()
			merged.sort()
			if level == 1:
				ex = K.number("Merge the sorted lists %s and %s into one sorted list. Which number goes first?" % [_csv(a), _csv(b)],
					merged[0], "Only the first number of each list can be the smallest. Compare those two.",
					"Compare the fronts, %d and %d: %d is smaller, so it goes first." % [a[0], b[0], merged[0]])
			else:
				var wrongs: Array = [_csv(a + b), _csv(b + a)]
				var alt := merged.duplicate()
				var t: int = alt[2]
				alt[2] = alt[3]
				alt[3] = t
				wrongs.append(_csv(alt))
				wrongs = wrongs.filter(func(w: String) -> bool: return w != _csv(merged))
				ex = K.choice(rng, "Merge the sorted lists %s and %s. What is the merged list?" % [_csv(a), _csv(b)], _csv(merged), wrongs,
					"Compare the two front numbers, move the smaller one to the new list, and repeat.",
					"Taking the smaller front number each time gives %s." % _csv(merged))
			ex.data = {"a": a, "b": b}
	return ex


const RANGES := [["a player's age", 5, 12], ["a level number", 1, 20], ["a test score", 0, 100], ["a number of players", 2, 8]]


## Test data for a rule "X must be A to B". Level 1: normal or erroneous; level 2: boundary or normal; level 3: which
## test finds a bug at the edge.
static func test_data(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rule: Array = RANGES[rng.randi_range(0, RANGES.size() - 1)]
	var what := str(rule[0])
	var a := int(rule[1])
	var b := int(rule[2])
	var ex := {}
	var choices: Array = ["normal", "boundary", "erroneous"]
	if level == 3:
		var bug_low := rng.randi() % 2 == 0
		var code := "if x > %d and x <= %d:" % [a, b] if bug_low else "if x >= %d and x < %d:" % [a, b]
		var right := a if bug_low else b
		var mid := (a + b) / 2
		var wrongs: Array = [str(mid), str(b if bug_low else a), "\"cat\""]
		ex = K.choice(rng, "%s must be %d to %d, but the code says: %s Which test finds the bug?" % [what.capitalize(), a, b, code],
			str(right), wrongs, "Test the edges: try the smallest and the biggest allowed values in the code in your head.",
			"%d is allowed but the code turns it away (%s). Only a test at that edge finds the bug." % [right,
				"it is not > %d" % a if bug_low else "it is not < %d" % b])
		ex.data = {"a": a, "b": b, "bug_low": bug_low}
		return ex
	var value := ""
	var kind := ""
	if level == 1:
		if rng.randi() % 2 == 0:
			value = str(rng.randi_range(a + 1, b - 1))
			kind = "normal"
		else:
			value = ["\"ten\"", str(-rng.randi_range(3, 9)), str(b + rng.randi_range(40, 200)), "\"?\""][rng.randi_range(0, 3)]
			kind = "erroneous"
	else:
		if rng.randi() % 2 == 0:
			value = str([a, b][rng.randi_range(0, 1)])
			kind = "boundary"
		else:
			value = str(rng.randi_range(a + 1, b - 1))
			kind = "normal"
	var explain := ""
	match kind:
		"normal":
			explain = "%s is inside %d to %d and not at an edge: normal data, which should be accepted." % [value, a, b]
		"boundary":
			explain = "%s is at the edge of %d to %d: boundary data. It should be accepted, and edges are where bugs hide." % [value, a, b]
		_:
			explain = "%s is not a number from %d to %d: erroneous data, which the program should turn away." % [value, a, b]
	ex = K.choice(rng, "%s must be %d to %d. What kind of test data is %s?" % [what.capitalize(), a, b, value], kind,
		choices.filter(func(c: String) -> bool: return c != kind),
		"Is it allowed at all? If it is, is it right at an edge of the range?", explain)
	ex.data = {"a": a, "b": b, "value": value}
	return ex


const SAFE_PREFIXES := ["192.168.1.", "192.168.0.", "10.0.0.", "203.0.113.", "198.51.100.", "192.0.2."]


## IP addresses and packets. Level 1: can this be an IP address? Level 2: how many packets a message makes; level 3:
## which could be an IP address.
static func ip_address(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var good := rng.randi() % 2 == 0
			var ip := _safe_ip(rng) if good else _bad_ip(rng)
			ex = K.truefalse("Can %s be an IP address?" % ip, good, "An IP address (version 4) is four numbers, each from 0 to 255, with dots between.",
				("True: four numbers, each 0 to 255." if good else "False: %s is more than 255, and each part must be 0 to 255." % _big_part(ip)))
			ex.data = {"ip": ip}
		2:
			var size := rng.randi_range(4, 12)
			var n := rng.randi_range(size + 3, size * 6)
			var packets := (n + size - 1) / size
			ex = K.number("A message of %d letters is split into packets of at most %d letters. How many packets does it make?" % [n, size], packets,
				"How many full packets fit? One more packet carries any letters left over.",
				("%d ÷ %d = %d exactly: %d packets." % [n, size, packets, packets]) if n % size == 0 else
				("%d full packets hold %d letters; the last %d letters need one more: %d packets." % [n / size, (n / size) * size,
					n % size, packets]))
			ex.data = {"n": n, "size": size}
		_:
			var right := _safe_ip(rng)
			var p := right.split(".")
			var wrongs: Array = ["%s.%s.%s.%s.%d" % [p[0], p[1], p[2], p[3], rng.randi_range(1, 9)],
				"%s.%s.%d" % [p[0], p[1], rng.randi_range(1, 99)], _bad_ip(rng), "%s.%s.%s.%s" % [p[0], "one", p[2], p[3]]]
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which of these could be an IP address?", right, wrongs.slice(0, 3),
				"Count the parts (four) and check each is a number from 0 to 255.",
				"%s has four parts, each a number from 0 to 255." % right)
			ex.data = {"ip": right}
	return ex


static func _safe_ip(rng: RandomNumberGenerator) -> String:
	return str(SAFE_PREFIXES[rng.randi_range(0, SAFE_PREFIXES.size() - 1)]) + str(rng.randi_range(2, 254))


static func _bad_ip(rng: RandomNumberGenerator) -> String:
	var parts: Array[String] = ["192", "168", str(rng.randi_range(0, 9)), str(rng.randi_range(2, 254))]
	parts[rng.randi_range(2, 3)] = str(rng.randi_range(256, 399))
	return ".".join(parts)


static func _big_part(ip: String) -> String:
	for part in ip.split("."):
		if part.is_valid_int() and int(part) > 255:
			return part
	return ""


## Every route through the routers' map (SchoolPictureG7Arts' ROUTER_LINKS, the computer joining A and D, the server C
## and F) that visits no router twice, shortest first.
static func _routes() -> Array[String]:
	var links := {"A": "BD", "B": "ACE", "C": "BF", "D": "AE", "E": "DFB", "F": "CE"}
	var out: Array[String] = []
	var stack: Array = [["A"], ["D"]]
	while not stack.is_empty():
		var path: Array = stack.pop_back()
		var last := str(path[-1])
		if last in ["C", "F"]:
			out.append("".join(PackedStringArray(path)))
		for nxt in str(links[last]):
			if not path.has(nxt):
				stack.append(path + [nxt])
	out.sort_custom(func(x: String, y: String) -> bool: return x.length() < y.length() or (x.length() == y.length() and x < y))
	return out


## Packets' routes through routers. Level 1: how many routers a packet passes; level 2: which packet passes the fewest;
## level 3: which route still works when a router breaks.
static func route_hops(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var all := _routes()
	var ex := {}
	match level:
		1:
			var r1 := all[rng.randi_range(0, all.size() - 1)]
			ex = K.number("How many routers does packet 1 pass through on its way to the server?", r1.length(),
				"Follow packet 1's line from you to the server and count the lettered boxes.",
				"Packet 1 goes through %s: %d routers." % [", ".join(PackedStringArray(r1.split(""))), r1.length()],
				{"kind": "internet_trip", "view": "routes", "routes": [r1]})
			ex.data = {"routes": [r1]}
		2:
			var picks: Array = []
			var short := all.filter(func(x: String) -> bool: return x.length() == 3)
			picks.append(short[rng.randi_range(0, short.size() - 1)])
			var long := all.filter(func(x: String) -> bool: return x.length() >= 4)
			K.shuffle(rng, long)
			picks.append(long[0])
			if long.size() > 1 and str(long[1]).length() != str(long[0]).length():
				picks.append(long[1])
			K.shuffle(rng, picks)
			var best := 0
			for i in picks.size():
				if str(picks[i]).length() < str(picks[best]).length():
					best = i
			var names: Array = []
			for i in picks.size():
				names.append("packet %d" % (i + 1))
			var said: Array[String] = []
			for i in picks.size():
				said.append("packet %d: %d" % [i + 1, str(picks[i]).length()])
			ex = K.choice(rng, "Which packet passes through the fewest routers?", names[best],
				names.filter(func(nm: String) -> bool: return nm != names[best]), "Count the routers on each packet's route.",
				"Routers passed: %s. Packet %d passes the fewest." % [", ".join(said), best + 1],
				{"kind": "internet_trip", "view": "routes", "routes": picks})
			ex.data = {"routes": picks}
		_:
			var broken := "BE"[rng.randi_range(0, 1)]
			var ok := all.filter(func(x: String) -> bool: return not x.contains(broken))
			var bad := all.filter(func(x: String) -> bool: return x.contains(broken))
			K.shuffle(rng, ok)
			K.shuffle(rng, bad)
			var picks: Array = [ok[0], bad[0]]
			if bad.size() > 1:
				picks.append(bad[1])
			K.shuffle(rng, picks)
			var right := picks.find(ok[0])
			var names: Array = []
			for i in picks.size():
				names.append("packet %d" % (i + 1))
			ex = K.choice(rng, "Router %s breaks. Which packet's route still reaches the server?" % broken, names[right],
				names.filter(func(nm: String) -> bool: return nm != names[right]),
				"Look for the route that never goes through router %s." % broken,
				"Packet %d goes through %s and never uses %s; the others pass through %s. The internet has many routes, so packets find a way round." % [
					right + 1, ", ".join(PackedStringArray(str(ok[0]).split(""))), broken, broken],
				{"kind": "internet_trip", "view": "routes", "routes": picks, "mark": broken})
			ex.data = {"routes": picks, "broken": broken}
	return ex


const WORDS: Array[String] = ["CAT", "OWL", "FOX", "SUN", "MOON", "GOLD", "STAR", "SHIP", "TOWER", "RIVER", "HELLO", "MAGIC",
	"CASTLE", "DRAGON", "ROCKET", "PLANET", "BRIDGE", "SECRET", "GARDEN", "FOREST"]
## Codes the generator never shows (a code that spells a word a child should not meet).
const BLOCKED: Array[String] = ["ASS", "POO", "PEE", "WEE", "BUM", "SEX", "DIE", "KILL", "HATE", "DEAD", "FAT", "UGLY", "GUN"]


## The Caesar cipher. Level 1: code a short word (shift 1-3); level 2: decode a word (shift 3-10); level 3: find the
## shift from a word and its code.
static func caesar_word(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := WORDS.filter(func(w: String) -> bool: return w.length() <= (4 if level == 1 else 6))
	var word := ""
	var shift := 0
	var code := ""
	for _t in 20:
		word = str(pool[rng.randi_range(0, pool.size() - 1)])
		shift = rng.randi_range(1, 3) if level == 1 else rng.randi_range(3, 10) if level == 2 else rng.randi_range(2, 12)
		code = _caesar(word, shift)
		if _clean(code) and _clean(_caesar(word, shift + 1)) and _clean(_caesar(word, shift - 1)) and _clean(_caesar(word, -shift)):
			break
	var ex := {}
	match level:
		1:
			var wrongs: Array = [_caesar(word, shift + 1), _caesar(word, -shift), _caesar(word, shift - 1) if shift > 1 else _caesar(word, shift + 2)]
			ex = K.choice(rng, "With a shift of %d, what is the code for %s?" % [shift, word], code, wrongs,
				"Find each letter on the outer ring and read the letter %d places on (the inner ring)." % shift,
				"Each letter moves %d on: %s becomes %s." % [shift, word, code], {"kind": "cipher_wheel", "shift": shift, "mark": word.left(1)})
		2:
			var wrongs: Array = [_caesar(code, shift), _caesar(word, 1), _caesar(word, -1)]
			wrongs = wrongs.filter(func(w: String) -> bool: return w != word)
			ex = K.choice(rng, "A message was coded with a shift of %d: %s. What does it say?" % [shift, code], word, wrongs,
				"Decode by going back %d places for each letter: find it on the inner ring and read the outer ring." % shift,
				"Going back %d places, %s decodes to %s." % [shift, code, word], {"kind": "cipher_wheel", "shift": shift})
		_:
			ex = K.number("%s became %s in a Caesar cipher. What was the shift?" % [word, code], shift,
				"How many letters along the alphabet is the first code letter from the first plain letter?",
				"%s to %s is %d places on (every letter moves the same)." % [word.left(1), code.left(1), shift])
	ex.data = {"word": word, "shift": shift}
	return ex


static func _caesar(text: String, shift: int) -> String:
	var out := ""
	for ch in text:
		var c := ch.unicode_at(0)
		out += String.chr(65 + posmod(c - 65 + shift, 26)) if c >= 65 and c <= 90 else ch
	return out


static func _clean(code: String) -> bool:
	for b: String in BLOCKED:
		if code.contains(b):
			return false
	return true


## Mistakes in collected data. Level 1: which value is impossible; level 2: the rows left once a copy and an
## impossible value are removed; level 3: the mean once the mistake is removed.
static func clean_data(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := NAMES.duplicate()
	K.shuffle(rng, names)
	var ages_col := rng.randi() % 2 == 0
	var head: Array = ["Name", "Age"] if ages_col else ["Name", "Height cm"]
	var n: int = [0, 5, 6, 5][level]
	var values: Array[int] = []
	for _t in 200:   # level 3: until the good values' total shares evenly (a whole mean)
		values.clear()
		var total := 0
		for i in n - 1:
			values.append(rng.randi_range(9, 13) if ages_col else rng.randi_range(128, 160))
			total += values[-1]
		if level != 3 or total % (n - 1) == 0:
			break
	var bad := (rng.randi_range(110, 190) if ages_col else rng.randi_range(12, 25)) if rng.randi() % 2 == 0 \
		else (rng.randi_range(110, 190) if ages_col else rng.randi_range(350, 480))
	var at := rng.randi_range(0, n - 1)
	var rows: Array = []
	var k := 0
	for i in n:
		if i == at:
			rows.append([names[i], str(bad)])
		else:
			rows.append([names[i], str(values[k])])
			k += 1
	var unit := "an age" if ages_col else "a height in centimetres"
	var ex := {}
	match level:
		1:
			var wrongs: Array = []
			for v in values:
				if not wrongs.has(str(v)):
					wrongs.append(str(v))
			ex = K.choice(rng, "This data was collected from a class. Which value must be a mistake?", str(bad), wrongs.slice(0, 3),
				"Which value could not be true for a child of about 12?",
				"%d cannot be %s of a child in the class, so it is a typing mistake to check and fix." % [bad, unit],
				{"kind": "data_sheet", "head": head, "rows": rows})
		2:
			var copy := rng.randi_range(0, n - 1)
			while copy == at:
				copy = rng.randi_range(0, n - 1)
			rows.insert(copy + 1, (rows[copy] as Array).duplicate())
			ex = K.number("One row was typed twice and one value is impossible. How many rows are left when you remove both?", rows.size() - 2,
				"Find the row that appears twice and the value that cannot be true; take them away from the rows.",
				"There are %d rows. Remove the copy of %s's row and the row with %d: %d rows are left." % [rows.size(), rows[copy][0],
					bad, rows.size() - 2], {"kind": "data_sheet", "head": head, "rows": rows})
		_:
			var total := 0
			for v in values:
				total += v
			var mean := total / values.size()
			ex = K.number("Remove the impossible value, then find the mean (the average) of the rest.", mean,
				"Cross out the value that cannot be true. Add the others and divide by how many there are.",
				"Without %d: %s = %d, and %d ÷ %d = %d." % [bad, " + ".join(PackedStringArray(values.map(func(v: int) -> String: return str(v)))),
					total, total, values.size(), mean], {"kind": "data_sheet", "head": head, "rows": rows})
	ex.data = {"rows": rows, "bad": bad}
	return ex


const CHECKS := {"presence check": ["The name box was left empty.", "No age was typed in at all.", "The email box is blank."],
	"type check": ["Someone typed ten in the age box, which takes numbers.", "The number of pets was typed as lots.",
		"A price box holds the word free."],
	"range check": ["Someone typed 150 in the age box (ages 5 to 12).", "A test score of 130 was typed (scores 0 to 100).",
		"A month was typed as 14."],
	"length check": ["A new password has only 4 letters (it needs 12 or more).", "A phone number has 30 digits.",
		"A nickname is 60 letters long (the most is 16)."],
	"format check": ["An email address has no @ sign.", "A date was typed as 2026-13 when the form wants DD/MM/YYYY.",
		"A postcode was typed with no space and letters missing."]}


## Validation: the check that catches a bad entry. Level 1: presence or type; level 2: range or length; level 3:
## format, or which entry passes a range check.
static func validate_entry(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	if level == 3 and rng.randi() % 2 == 0:
		var lo := rng.randi_range(1, 10)
		var hi := lo + rng.randi_range(5, 20)
		var right := rng.randi_range(lo, hi)
		var wrongs: Array = [str(lo - rng.randi_range(1, 5)), str(hi + rng.randi_range(1, 20)), "\"twelve\""]
		wrongs = wrongs.filter(func(w: String) -> bool: return w != str(right))
		ex = K.choice(rng, "A box takes whole numbers from %d to %d. Which entry passes the range check?" % [lo, hi], str(right), wrongs,
			"A range check lets through numbers from the lowest to the highest allowed, edges included.",
			"%d is from %d to %d, so it passes." % [right, lo, hi])
		ex.data = {"lo": lo, "hi": hi}
		return ex
	var kinds: Array = [["presence check", "type check"], ["range check", "length check"], ["format check"]][level - 1]
	var kind := str(kinds[rng.randi_range(0, kinds.size() - 1)])
	var cases: Array = CHECKS[kind]
	var said := str(cases[rng.randi_range(0, cases.size() - 1)])
	var wrongs: Array = CHECKS.keys().filter(func(c: String) -> bool: return c != kind)
	K.shuffle(rng, wrongs)
	ex = K.choice(rng, "%s Which check would catch it?" % said, kind, wrongs.slice(0, 3),
		"Is something missing, the wrong kind of thing, too big or small, too long or short, or in the wrong pattern?",
		"A %s: %s." % [kind, {"presence check": "it checks something was entered", "type check": "it checks the entry is the right kind (a number, a date)",
			"range check": "it checks a number is between the lowest and highest allowed", "length check": "it checks how many letters or digits there are",
			"format check": "it checks the entry follows a pattern (an @ in an email, a date's slashes)"}[kind]])
	ex.data = {"kind": kind}
	return ex


const TRICKS := {"autoplay": "The next video starts by itself before you choose it.",
	"endless scroll": "New posts keep loading, so the feed never reaches an end.",
	"notifications": "A red number tells you something new is waiting for you.",
	"likes": "Hearts and a number show how many people liked a post."}
const HEALTHY: Array[String] = ["Turn notifications off at night", "Charge your phone outside your bedroom",
	"Set your own time limit before you start", "Take a break and look away every 20 minutes"]
const UNHEALTHY: Array[String] = ["Scroll until the feed runs out", "Check your likes every few minutes",
	"Keep the phone on your pillow with the sound on", "Compare yourself with edited photos"]


## Feeds and healthy habits. Level 1: the trick a feed uses; level 2: the healthy habit; level 3: the sums of a feed.
static func habit_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var kind := str(TRICKS.keys()[rng.randi_range(0, TRICKS.size() - 1)])
			var wrongs: Array = TRICKS.keys().filter(func(t: String) -> bool: return t != kind)
			ex = K.choice(rng, "%s Which design trick is this?" % TRICKS[kind], kind, wrongs,
				"Think of what the app does to make you keep looking.",
				"That is %s: it is designed to keep you on the app a little longer." % kind, {"kind": "phone_feed", "mark": _feed_part(kind)})
			ex.data = {"kind": kind}
		2:
			var right := HEALTHY[rng.randi_range(0, HEALTHY.size() - 1)]
			var wrongs: Array = UNHEALTHY.duplicate()
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which is a healthy habit with phones and feeds?", right, wrongs.slice(0, 3),
				"Which choice puts you in charge, not the app?",
				"%s: you decide when to stop, and sleep, eyes and mood stay well." % right)
			ex.data = {"right": right}
		_:
			if rng.randi() % 2 == 0:
				var secs: int = [10, 12, 15, 20, 30][rng.randi_range(0, 4)]
				var mins := rng.randi_range(2, 6) * 5
				ex = K.number("Short videos last %d seconds each. How many can play in %d minutes of scrolling?" % [secs, mins], mins * 60 / secs,
					"Turn the minutes into seconds first, then share them out between the videos.",
					"%d minutes is %d × 60 = %d seconds; %d ÷ %d = %d videos." % [mins, mins, mins * 60, mins * 60, secs, mins * 60 / secs])
				ex.data = {"secs": secs, "mins": mins}
			else:
				var hours := rng.randi_range(1, 4)
				ex = K.number("The 20-20-20 rule: every 20 minutes on a screen, look at something about 6 metres away for 20 seconds. How many breaks is that in %d hour%s?" % [
					hours, "" if hours == 1 else "s"], hours * 3, "How many 20-minute parts are in one hour?",
					"An hour has 3 parts of 20 minutes, so %d hour%s make %d × 3 = %d breaks." % [hours, "" if hours == 1 else "s", hours,
						hours * 3])
				ex.data = {"hours": hours}
	return ex


static func _feed_part(kind: String) -> String:
	return "notification" if kind == "notifications" else kind


## When copyright ends: 70 years after the creator dies, to the end of that year (the UK and many countries). Level 1:
## from which year a work is free; level 2: is it free now (2026)?; level 3: the year, with the year it was made too.
static func public_domain(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: Array = [["An author", "book"], ["A painter", "painting"], ["A songwriter", "song"], ["A photographer", "photo"]][rng.randi_range(0, 3)]
	var died := rng.randi_range(1900, 1990)
	var free := died + 71
	var ex := {}
	match level:
		1:
			ex = K.number("%s died in %d. Copyright lasts 70 years after the creator dies, to the end of that year. From which year is the %s free for anyone to use?" % [
				who[0], died, who[1]], free, "Add 70 to the year they died; the work is free from the next 1 January.",
				"%d + 70 = %d. Copyright ends at the end of %d, so it is free from 1 January %d." % [died, died + 70, died + 70, free])
			ex.year = true
		2:
			var now := 2026
			died = rng.randi_range(1930, 1975)
			free = died + 71
			ex = K.truefalse("It is %d. %s died in %d. Is the %s free for anyone to use now? (Copyright lasts 70 years after death.)" % [
				now, who[0], died, who[1]], free <= now, "Work out the first free year (the year of death + 71) and compare it with %d." % now,
				"It is free from 1 January %d, which is %s %d." % [free, "before or in" if free <= now else "after", now])
		_:
			var made := died - rng.randi_range(5, 40)
			ex = K.number("%s made a %s in %d and died in %d. From which year is it free for anyone to use? (Copyright lasts 70 years after death.)" % [
				who[0], who[1], made, died], free, "Which year counts: when it was made, or when its creator died?",
				"It is the year of death that counts: %d + 70 = %d, so it is free from 1 January %d." % [died, died + 70, free])
			ex.year = true
	ex.data = {"died": died}
	return ex


const LICENCE_SAYS := {"CC0": "anyone may use it for anything, with no need to credit", "CC BY": "anyone may use it if they credit the maker",
	"CC BY-SA": "anyone may use it with credit, and share new versions under the same licence",
	"CC BY-NC": "anyone may use it with credit, but not to make money", "CC BY-ND": "anyone may share it with credit, but not change it",
	"all rights reserved": "you must ask the owner before using it"}
const LICENCE_ASKS := [["You want to use a picture without asking and without writing a credit.", "CC0"],
	["You may use a song if you write who made it.", "CC BY"],
	["You may change a photo, but your new version must use the same licence.", "CC BY-SA"],
	["You may use a drawing in your school poster, but you may not sell it.", "CC BY-NC"],
	["You may share a poem with a credit, but you must not change a word.", "CC BY-ND"],
	["You must write to the owner and ask before you use the photo.", "all rights reserved"]]


## What a licence allows. Level 1: the licence that fits; level 2: may you do this with it?; level 3: which licences let
## you sell your remix.
static func licence_use(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var pick: Array = LICENCE_ASKS[rng.randi_range(0, LICENCE_ASKS.size() - 1)]
			var wrongs: Array = LICENCE_SAYS.keys().filter(func(l: String) -> bool: return l != str(pick[1]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "%s Which licence is it?" % pick[0], str(pick[1]), wrongs.slice(0, 3),
				"BY means credit, SA share alike, NC not for money, ND no changes; CC0 gives the work to everyone.",
				"%s: %s." % [pick[1], LICENCE_SAYS[pick[1]]])
			ex.data = {"licence": pick[1]}
		2:
			var cases: Array = [["CC BY-NC", "sell T-shirts with it", false], ["CC BY", "use it in a video if you credit the maker", true],
				["CC BY-ND", "change its colours and share your version", false], ["CC0", "use it without a credit", true],
				["all rights reserved", "put it in your game without asking", false], ["CC BY-SA", "remix it and share your remix under CC BY-SA", true]]
			var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
			ex = K.truefalse("A picture has the licence %s. May you %s?" % [c[0], c[1]], bool(c[2]),
				"Read the licence's letters: what does each one allow or forbid?",
				"%s: %s. %s" % ["True" if c[2] else "False", c[0] + " means " + str(LICENCE_SAYS[c[0]]), "So you may." if c[2] else "So you may not."])
			ex.data = {"licence": c[0]}
		_:
			var right: String = ["CC0", "CC BY"][rng.randi_range(0, 1)]
			ex = K.choice(rng, "You want to change a picture and sell badges with your version. Which licence lets you?", right,
				["CC BY-NC", "CC BY-ND", "all rights reserved"],
				"Rule out any licence with NC (no money), ND (no changes) or all rights reserved.",
				"%s: %s. NC forbids selling, ND forbids changes, and all rights reserved means asking first." % [right, LICENCE_SAYS[right]])
			ex.data = {"licence": right}
	return ex


# --- Art -------------------------------------------------------------------------------------------------------------

const WHEEL: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red", "red-purple", "purple",
	"blue-purple", "blue", "blue-green", "green", "yellow-green"]


## Colour schemes on the 12-colour wheel. Level 1: a primary's or secondary's complementary colour; level 2: a colour's
## analogous neighbours; level 3: the other two of a triad.
static func scheme_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	var pic := {"kind": "colour_wheel", "size": 12, "names": true}
	match level:
		1:
			var b: int = [0, 2, 4, 6, 8, 10][rng.randi_range(0, 5)]
			var right := WHEEL[(b + 6) % 12]
			var wrongs: Array = [WHEEL[(b + 4) % 12], WHEEL[(b + 8) % 12], WHEEL[(b + 2) % 12]]
			ex = K.choice(rng, "Which colour is complementary to %s?" % WHEEL[b], right, wrongs,
				"Complementary colours sit opposite each other on the wheel.",
				"%s and %s are opposite on the wheel: complementary colours, the strongest contrast." % [WHEEL[b].capitalize(), right], pic)
			ex.data = {"base": WHEEL[b]}
		2:
			var b := rng.randi_range(0, 11)
			var right := "%s and %s" % [WHEEL[(b + 11) % 12], WHEEL[(b + 1) % 12]]
			var wrongs: Array = ["%s and %s" % [WHEEL[(b + 6) % 12], WHEEL[(b + 4) % 12]], "%s and %s" % [WHEEL[(b + 2) % 12], WHEEL[(b + 10) % 12]],
				"%s and %s" % [WHEEL[(b + 5) % 12], WHEEL[(b + 7) % 12]]]
			ex = K.choice(rng, "Which two colours make an analogous scheme with %s?" % WHEEL[b], right, wrongs,
				"Analogous colours sit side by side on the wheel.",
				"The neighbours of %s on the wheel are %s: calm, because they share colour." % [WHEEL[b], right], pic)
			ex.data = {"base": WHEEL[b]}
		_:
			var b := rng.randi_range(0, 11)
			var right := "%s and %s" % [WHEEL[(b + 4) % 12], WHEEL[(b + 8) % 12]]
			var wrongs: Array = ["%s and %s" % [WHEEL[(b + 3) % 12], WHEEL[(b + 9) % 12]], "%s and %s" % [WHEEL[(b + 1) % 12], WHEEL[(b + 11) % 12]],
				"%s and %s" % [WHEEL[(b + 6) % 12], WHEEL[(b + 2) % 12]]]
			ex = K.choice(rng, "Which two colours make a triad with %s?" % WHEEL[b], right, wrongs,
				"A triad is three colours spaced evenly: every fourth colour round the 12-colour wheel.",
				"Counting 4 on from %s gives %s, and 4 more gives %s: a triangle on the wheel." % [WHEEL[b], WHEEL[(b + 4) % 12],
					WHEEL[(b + 8) % 12]], pic)
			ex.data = {"base": WHEEL[b]}
	return ex


## A figure measured in heads (a grown-up about 8 heads tall; the hips halfway, the knees at 6). Level 1: a head's
## height; level 2: where the hips or knees are; level 3: a child 6 heads tall, or the arm span.
static func head_heights(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var h := rng.randi_range(2, 5)
	var ex := {}
	match level:
		1:
			ex = K.number("A figure 8 heads tall is drawn %d cm tall. How tall is each head?" % (8 * h), h,
				"The height is shared into 8 equal heads.", "%d ÷ 8 = %d cm a head." % [8 * h, h],
				{"kind": "figure_study", "view": "heads"})
		2:
			if rng.randi() % 2 == 0:
				ex = K.number("A figure 8 heads tall is drawn %d cm tall. How far down from the top of the head are the hips?" % (8 * h), 4 * h,
					"The hips are halfway down the body.", "Halfway: 4 heads of %d cm, 4 × %d = %d cm." % [h, h, 4 * h])
			else:
				ex = K.number("A figure 8 heads tall is drawn %d cm tall. The knees are 6 heads down. How far down is that?" % (8 * h), 6 * h,
					"Find one head first, then take 6 of them.", "One head is %d ÷ 8 = %d cm; 6 × %d = %d cm." % [8 * h, h, h, 6 * h])
		_:
			if rng.randi() % 2 == 0:
				var c := rng.randi_range(2, 5)
				ex = K.number("A young child is about 6 heads tall. You draw one %d cm tall. How tall is each head?" % (6 * c), c,
					"Share the height into the number of heads.", "%d ÷ 6 = %d cm a head: a child's head is big for its body." % [6 * c, c],
					{"kind": "figure_study", "view": "heads", "heads": 6})
				h = c
			else:
				ex = K.number("Arms stretched out, a grown-up's arm span is about as wide as they are tall. A figure is 8 heads of %d cm. About how wide is the arm span?" % h,
					8 * h, "Find the height first: 8 heads.", "The height is 8 × %d = %d cm, so the arm span is about %d cm too." % [h, 8 * h, 8 * h])
	ex.data = {"h": h}
	return ex


## Scale drawings. Level 1: 1:100 (1 cm on the plan is 1 m); level 2: 1:50 (1 cm is half a metre); level 3: a real
## length drawn at 1:50 or modelled at 1:20.
static func scale_drawing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var cm := rng.randi_range(2, 15)
			ex = K.number("A plan is drawn at 1:100. A wall is %d cm long on the plan. How many metres long is the real wall?" % cm, cm,
				"At 1:100, everything real is 100 times bigger. How many centimetres make a metre?",
				"At 1:100, %d cm on the plan is %d × 100 = %d cm, which is %d m." % [cm, cm, cm * 100, cm])
			ex.data = {"scale": 100, "cm": cm}
		2:
			var cm := rng.randi_range(2, 20)
			var m := cm / 2.0
			ex = K.number("A plan is drawn at 1:50. A room is %d cm wide on the plan. How many metres wide is the real room?" % cm, _num(m),
				"At 1:50, 1 cm on the plan stands for 50 cm, half a metre.",
				"At 1:50, %d cm on the plan is %d × 50 = %s cm, which is %s m." % [cm, cm, K.fmt(cm * 50), _num(m)])
			ex.data = {"scale": 50, "cm": cm}
		_:
			if rng.randi() % 2 == 0:
				var m := rng.randi_range(2, 12)
				ex = K.number("You draw a %d m long garden at 1:50. How many centimetres long is it on the plan?" % m, m * 2,
					"Turn metres into centimetres, then divide by 50.", "%d m is %d cm; %d ÷ 50 = %d cm on the plan." % [m, m * 100, m * 100, m * 2])
				ex.data = {"scale": 50, "m": m}
			else:
				var m := rng.randi_range(1, 6)
				ex = K.number("A model is made at 1:20. A real door is %d m tall. How many centimetres tall is the model door?" % m, m * 5,
					"Turn metres into centimetres, then divide by 20.", "%d m is %d cm; %d ÷ 20 = %d cm." % [m, m * 100, m * 100, m * 5])
				ex.data = {"scale": 20, "m": m}
	return ex


const THINGS: Array[String] = ["tree", "tower", "boat", "buddy"]


## The rule of thirds. Level 1: is the subject on a third line? Level 2: which crossing is it on? Level 3: where the lines
## fall on a photo so many pixels wide or tall.
static func thirds_place(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var thing := THINGS[rng.randi_range(0, THINGS.size() - 1)]
	var ex := {}
	match level:
		1:
			var on := rng.randi() % 2 == 0
			var x: float = [1.0 / 3.0, 2.0 / 3.0][rng.randi_range(0, 1)] if on else 0.5
			var y: float = [0.45, 0.5, 0.55][rng.randi_range(0, 2)]
			var subject := [snappedf(x, 0.01), y]
			ex = K.truefalse("Is the %s on one of the thirds lines?" % thing, on, "Find the two lines a third and two thirds of the way across.",
				("True: it stands on a line a third of the way across, not in the dead centre." if on else
					"False: it is in the middle, halfway across; a thirds line is a third or two thirds across."),
				{"kind": "thirds_frame", "subject": subject, "thing": thing, "grid": true})
			ex.data = {"subject": subject}
		2:
			var kx := rng.randi_range(0, 1)
			var ky := rng.randi_range(0, 1)
			var subject := [snappedf([1.0 / 3.0, 2.0 / 3.0][kx], 0.01), snappedf([1.0 / 3.0, 2.0 / 3.0][ky], 0.01)]
			var right := ("top " if ky == 0 else "bottom ") + ("left" if kx == 0 else "right")
			var wrongs: Array = ["top left", "top right", "bottom left", "bottom right"].filter(func(w: String) -> bool: return w != right)
			ex = K.choice(rng, "Which crossing of the thirds lines is the %s on?" % thing, right, wrongs,
				"There are four crossings. Is it in the top or the bottom half, the left or the right?",
				"It sits where the %s line crosses the %s line: the %s crossing." % ["upper" if ky == 0 else "lower", "left" if kx == 0 else "right", right],
				{"kind": "thirds_frame", "subject": subject, "thing": thing, "grid": true})
			ex.data = {"subject": subject}
		_:
			var third := rng.randi_range(2, 6) * 100
			if rng.randi() % 2 == 0:
				ex = K.number("A photo is %s pixels wide. How far from the left edge is the right-hand thirds line?" % K.fmt(3 * third), 2 * third,
					"Find a third of the width, then take two of them.",
					"A third of %s is %d; two thirds is %d pixels." % [K.fmt(3 * third), third, 2 * third])
			else:
				ex = K.number("A photo is %s pixels tall. You put the horizon on the lower thirds line. How far down from the top is it?" % K.fmt(3 * third), 2 * third,
					"The lower line is two thirds of the way down.",
					"A third of %s is %d; two thirds down is %d pixels." % [K.fmt(3 * third), third, 2 * third])
			ex.data = {"third": third}
	return ex


## A woodcut prints mirrored. Levels 1-2: which print a block makes (3 × 3, 4 × 4); level 3: a 5 × 5 block or an
## edition's numbers.
static func block_print(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3 and rng.randi() % 2 == 0:
		var total := rng.randi_range(8, 40)
		var this := rng.randi_range(1, total)
		var ex3 := K.number("A print is numbered %d/%d in pencil. How many prints are in the whole edition?" % [this, total], total,
			"The number after the line is the edition's size; the one before says which print this is.",
			"%d/%d is print %d of an edition of %d prints." % [this, total, this, total])
		ex3.data = {"this": this, "total": total}
		return ex3
	var n: int = [0, 3, 4, 5][level]
	var rows: Array = []
	for _t in 50:
		rows = []
		for y in n:
			var row := ""
			for x in n:
				row += "#" if rng.randi() % 2 == 0 else "."
			rows.append(row)
		var mirrored := _mirror(rows)
		var flipped := rows.duplicate()
		flipped.reverse()
		if mirrored != rows and flipped != rows and flipped != mirrored and _swap(rows) != mirrored and _swap(rows) != flipped:
			break
	var right := {"picture": {"kind": "carved_block", "rows": _mirror(rows), "view": "print"}}
	var upside := rows.duplicate()
	upside.reverse()
	var wrongs: Array = [{"picture": {"kind": "carved_block", "rows": rows, "view": "print"}},
		{"picture": {"kind": "carved_block", "rows": upside, "view": "print"}},
		{"picture": {"kind": "carved_block", "rows": _swap(rows), "view": "print"}}]
	var ex := K.choice(rng, "The dark squares are the raised parts that take the ink. Which print does this block make?", right, wrongs,
		"The paper lies face down on the block, so the print is the block turned over, left to right.",
		"The print is the block mirrored left to right: the raised parts print dark, the cut parts stay white.",
		{"kind": "carved_block", "rows": rows, "view": "block"})
	ex.data = {"rows": rows}
	return ex


static func _mirror(rows: Array) -> Array:
	var out: Array = []
	for r: String in rows:
		out.append(r.reverse())
	return out


static func _swap(rows: Array) -> Array:
	var out: Array = []
	for r: String in rows:
		out.append(r.replace("#", "x").replace(".", "#").replace("x", "."))
	return out


## Works of art of 1400-1650 with their years (certain ones only).
const ART_EVENTS := [["Jan van Eyck paints the Arnolfini Portrait", 1434], ["Leonardo starts the Mona Lisa", 1503],
	["Michelangelo finishes the statue of David", 1504], ["Raphael finishes The School of Athens", 1511],
	["Michelangelo finishes the Sistine Chapel ceiling", 1512], ["Dürer makes his Rhinoceros woodcut", 1515],
	["Akbar becomes the Mughal emperor", 1556], ["The Blue Mosque is finished, with Iznik tiles", 1616],
	["Work begins on the Taj Mahal", 1632]]


## Art in time order. Level 1: which came first; level 2: the years between two; level 3: four in order.
static func art_dates(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ev := ART_EVENTS.duplicate()
	K.shuffle(rng, ev)
	var ex := {}
	match level:
		1:
			var a: Array = ev[0]
			var b: Array = ev[1]
			var first: Array = a if int(a[1]) < int(b[1]) else b
			var later: Array = b if first == a else a
			ex = K.choice(rng, "Which came first?", str(first[0]), [str(later[0])], "Recall the years, or think which person lived earlier.",
				"%s in %d, %d years before: %s in %d." % [first[0], first[1], int(later[1]) - int(first[1]), str(later[0]).to_lower(), later[1]])
			ex.data = {"a": a, "b": b}
		2:
			var a: Array = ev[0]
			var b: Array = ev[1]
			var early: Array = a if int(a[1]) < int(b[1]) else b
			var late: Array = b if early == a else a
			ex = K.number("%s in %d. %s in %d. How many years apart are they?" % [early[0], early[1], late[0], late[1]],
				int(late[1]) - int(early[1]), "Take the earlier year from the later one.",
				"%d − %d = %d years." % [late[1], early[1], int(late[1]) - int(early[1])])
			ex.data = {"a": a, "b": b}
		_:
			var four := ev.slice(0, 4)
			four.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
			var names: Array = four.map(func(e: Array) -> String: return str(e[0]))
			ex = K.order(rng, "Put these in time order, the earliest first.", names, "Think of the years: the 1400s, the 1500s, then the 1600s.",
				"; ".join(PackedStringArray(four.map(func(e: Array) -> String: return "%d %s" % [e[1], str(e[0]).to_lower()]))) + ".")
			ex.data = {"events": four}
	return ex


# --- Music -----------------------------------------------------------------------------------------------------------

const KEYS: Array[String] = ["C", "G", "F", "D"]


## A major key's chord for a numeral (I-vi): its notes' names ("Bb" a flat, "F#" a sharp).
static func _chord_notes(key: String, numeral: String) -> Array[String]:
	var d: int = ["I", "ii", "iii", "IV", "V", "vi"].find(numeral)
	var home := posmod(int(SEMIS[key.left(1)]) - (1 if key.ends_with("b") else 0), 12)
	var li := LETTERS.find(key.left(1))
	var out: Array[String] = []
	for k in [0, 2, 4]:
		var step: int = d + k
		var letter := LETTERS[(li + step) % 7]
		var diff := posmod(posmod(home + MAJOR[step % 7], 12) - int(SEMIS[letter]) + 6, 12) - 6
		out.append(letter + ("#" if diff == 1 else ("b" if diff == -1 else "")))
	return out


## "B flat", "F sharp", "C".
static func _said(note: String) -> String:
	if note.length() == 2:
		return note.left(1) + (" sharp" if note[1] == "#" else " flat")
	return note


## The primary chords I, IV and V. Level 1: the name of I, IV or V in a key; level 2: its notes; level 3: the chord that
## fits a melody note.
static func primary_chord(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var key := KEYS[rng.randi_range(0, KEYS.size() - 1)]
	var ex := {}
	match level:
		1:
			var numeral: String = ["I", "IV", "V"][rng.randi_range(0, 2)]
			var right := _said(_chord_notes(key, numeral)[0]) + " major"
			var wrongs: Array = []
			for nm: String in ["I", "ii", "IV", "V", "vi"]:
				var w := _said(_chord_notes(key, nm)[0]) + " major"
				if w != right and not wrongs.has(w):
					wrongs.append(w)
			ex = K.choice(rng, "Which chord is %s in %s major?" % [numeral, _said(key)], right, wrongs.slice(0, 3),
				"Count up the %s major scale from %s: I is the 1st note, IV the 4th, V the 5th." % [_said(key), _said(key)],
				"Chord %s in %s major is %s: its root is note %d of the scale." % [numeral, _said(key), right, {"I": 1, "IV": 4, "V": 5}[numeral]])
			ex.data = {"key": key, "numeral": numeral}
		2:
			var numeral: String = ["I", "IV", "V"][rng.randi_range(0, 2)]
			var right := _notes_said(_chord_notes(key, numeral))
			var wrongs: Array = []
			for nm: String in ["I", "ii", "iii", "IV", "V", "vi"]:
				var w := _notes_said(_chord_notes(key, nm))
				if w != right and not wrongs.has(w):
					wrongs.append(w)
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which notes make chord %s in %s major?" % [numeral, _said(key)], right, wrongs.slice(0, 3),
				"Find the root (note %d of the scale), then skip a note twice: root, third, fifth." % {"I": 1, "IV": 4, "V": 5}[numeral],
				"Chord %s's root is %s; with the notes a third and a fifth above: %s." % [numeral, _said(_chord_notes(key, numeral)[0]), right])
			ex.data = {"key": key, "numeral": numeral}
		_:
			var only: Array = []
			for deg in 7:
				var n := _chord_notes(key, "I")[0] if deg == 0 else _scale_note(key, deg)
				var holders: Array = []
				for nm: String in ["I", "IV", "V"]:
					if _chord_notes(key, nm).has(n):
						holders.append(nm)
				if holders.size() == 1:
					only.append([n, holders[0]])
			var pick: Array = only[rng.randi_range(0, only.size() - 1)]
			var names: Array = []
			for nm: String in ["I", "IV", "V"]:
				names.append("%s (%s)" % [nm, _said(_chord_notes(key, nm)[0])])
			var right := "%s (%s)" % [pick[1], _said(_chord_notes(key, str(pick[1]))[0])]
			ex = K.choice(rng, "A melody in %s major holds the note %s. Which primary chord fits under it?" % [_said(key), _said(str(pick[0]))], right,
				names.filter(func(x: String) -> bool: return x != right),
				"A chord fits when the melody note is one of its three notes. Spell I, IV and V.",
				"%s is in chord %s (%s), and in neither of the others." % [_said(str(pick[0])), pick[1], _notes_said(_chord_notes(key, str(pick[1])))])
			ex.data = {"key": key, "note": pick[0]}
	return ex


static func _scale_note(key: String, deg: int) -> String:
	var home := posmod(int(SEMIS[key.left(1)]) - (1 if key.ends_with("b") else 0), 12)
	var letter := LETTERS[(LETTERS.find(key.left(1)) + deg) % 7]
	var diff := posmod(posmod(home + MAJOR[deg], 12) - int(SEMIS[letter]) + 6, 12) - 6
	return letter + ("#" if diff == 1 else ("b" if diff == -1 else ""))


static func _notes_said(notes: Array[String]) -> String:
	return "%s, %s and %s" % [_said(notes[0]), _said(notes[1]), _said(notes[2])]


## A chord as a sound's note: its three notes from the root, rising ("D4+F#4+A4:2").
static func _chord_sound(key: String, numeral: String) -> String:
	var notes := _chord_notes(key, numeral)
	var octave := 3 if "GAB".contains(notes[0].left(1)) else 4
	var parts: Array[String] = []
	var last := -1
	for n in notes:
		var i := LETTERS.find(n.left(1))
		if last >= 0 and i < last:
			octave += 1
		last = i
		parts.append("%s%d" % [n, octave])
	return "+".join(parts) + ":2"


const CADENCES := {"perfect": [["I", "IV", "V", "I"], ["I", "vi", "V", "I"], ["I", "ii", "V", "I"]],
	"plagal": [["I", "V", "IV", "I"], ["I", "vi", "IV", "I"]],
	"imperfect": [["I", "IV", "I", "V"], ["I", "vi", "ii", "V"], ["I", "ii", "IV", "V"]]}


## Cadences heard. Level 1: finished or unfinished (C major); level 2: perfect, plagal or imperfect (C major); level 3:
## the same in G, F or D major.
static func cadence_ear(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var key: String = "C" if level < 3 else ["G", "F", "D"][rng.randi_range(0, 2)]
	var kind: String = ["perfect", "plagal", "imperfect"][rng.randi_range(0, 2)]
	var prog: Array = CADENCES[kind][rng.randi_range(0, (CADENCES[kind] as Array).size() - 1)]
	var notes: Array = []
	for nm: String in prog:
		notes.append(_chord_sound(key, nm))
	var sound := {"kind": "notes", "notes": notes}
	var said_prog := ", ".join(PackedStringArray(prog))
	var ex := {}
	if level == 1:
		var right := "unfinished" if kind == "imperfect" else "finished"
		ex = K.choice(rng, "Listen to the four chords. Does the music sound finished or unfinished?", right,
			["finished" if right == "unfinished" else "unfinished"], "Does the last chord feel like home, or does it want to go on?",
			"The chords are %s. %s" % [said_prog, "It ends on V, which wants to go home: unfinished." if kind == "imperfect"
				else "It ends on I, the home chord: finished."])
	else:
		var labels := {"perfect": "perfect (V to I)", "plagal": "plagal (IV to I)", "imperfect": "imperfect (ends on V)"}
		ex = K.choice(rng, "Listen to the chords in %s major. Which cadence ends the music?" % _said(key), labels[kind],
			labels.values().filter(func(x: String) -> bool: return x != labels[kind]),
			"Listen to the last two chords: does it end at home (I)? Is the chord before it V or IV?",
			"The chords are %s. The last two are %s to %s: a %s cadence." % [said_prog, prog[2], prog[3], kind])
	ex.sound = sound
	ex.data = {"key": key, "chords": prog}
	return ex


## Ornaments' notes. Level 1: a trill or a mordent; level 2: a turn; level 3: any, on a B or an E (the step to C or F is
## a semitone, the letters still go one up).
static func ornament_play(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var type: String = ["trill", "mordent"][rng.randi_range(0, 1)] if level == 1 else ("turn" if level == 2 else
		["trill", "mordent", "turn"][rng.randi_range(0, 2)])
	var note: String = ["C5", "D5", "G4", "A4", "F4"][rng.randi_range(0, 4)] if level < 3 else ["B4", "E5", "E4"][rng.randi_range(0, 2)]
	var up := _white(note, 1).left(1)
	var down := _white(note, -1).left(1)
	var n := note.left(1)
	var pats := {"trill": "%s %s %s %s %s %s %s %s" % [up, n, up, n, up, n, up, n], "mordent": "%s %s %s" % [n, up, n],
		"turn": "%s %s %s %s" % [up, n, down, n], "lower": "%s %s %s" % [n, down, n]}
	var right := str(pats[type])
	var wrongs: Array = []
	for k: String in pats:
		if k != type:
			wrongs.append(pats[k])
	var what := {"trill": "a trill: from the note above, the two notes in turn, quickly", "mordent": "a mordent: the note, the one above, the note",
		"turn": "a turn: the note above, the note, the one below, the note"}
	var ex := K.choice(rng, "Which notes does this ornament play?", right, wrongs,
		"Name the ornament from its sign first: tr, a short zigzag, or a lying S.",
		"It is %s: %s." % [what[type], right], {"kind": "ornament_signs", "type": type, "note": note})
	ex.data = {"type": type, "note": note}
	return ex


static func _white(note: String, k: int) -> String:
	var i := LETTERS.find(note.left(1)) + 7 * int(note.right(1)) + k
	return LETTERS[posmod(i, 7)] + str(floori(i / 7.0))


const COMPOSERS := {"Bach": [1685, 1750, "Baroque"], "Handel": [1685, 1759, "Baroque"], "Vivaldi": [1678, 1741, "Baroque"],
	"Purcell": [1659, 1695, "Baroque"], "Pachelbel": [1653, 1706, "Baroque"], "Haydn": [1732, 1809, "Classical"],
	"Mozart": [1756, 1791, "Classical"]}
const ERA_FEATURES := [["a harpsichord filling in the chords (the continuo)", "Baroque"], ["a ground bass repeating under the music", "Baroque"],
	["sudden changes between loud and soft (terraced dynamics)", "Baroque"], ["a fugue, one tune chasing itself in every part", "Baroque"],
	["a symphony in four movements", "Classical"], ["an Alberti bass: a broken chord, low, high, middle, high", "Classical"],
	["the piano growing louder bit by bit (a crescendo)", "Classical"], ["clear, balanced question-and-answer phrases", "Classical"]]


## Baroque (about 1600-1750) and Classical (about 1750-1820). Level 1: a composer's period; level 2: a feature's period;
## level 3: the years between composers' births and deaths.
static func era_facts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	var names: Array = COMPOSERS.keys()
	match level:
		1:
			var who := str(names[rng.randi_range(0, names.size() - 1)])
			var c: Array = COMPOSERS[who]
			ex = K.choice(rng, "%s lived from %d to %d. Which period of music is that?" % [who, c[0], c[1]], str(c[2]),
				["Baroque", "Classical", "Medieval"].filter(func(x: String) -> bool: return x != str(c[2])),
				"The Baroque ran from about 1600 to 1750, and the Classical era from about 1750 to 1820.",
				"%s (%d-%d) wrote music in the %s period." % [who, c[0], c[1], c[2]])
			ex.data = {"who": who}
		2:
			var f: Array = ERA_FEATURES[rng.randi_range(0, ERA_FEATURES.size() - 1)]
			ex = K.choice(rng, "You hear %s. Which period does it point to?" % f[0], str(f[1]),
				["Baroque", "Classical"].filter(func(x: String) -> bool: return x != str(f[1])),
				"Baroque: harpsichords, continuo, ground basses, fugues. Classical: the piano, symphonies, clear balanced tunes.",
				"%s is typical of the %s period." % [str(f[0]).capitalize(), f[1]])
			ex.data = {"feature": f[0]}
		_:
			K.shuffle(rng, names)
			var a := str(names[0])
			var b := str(names[1])
			var ya := int(COMPOSERS[a][0])
			var yb := int(COMPOSERS[b][0])
			if ya == yb:
				b = str(names[2])
				yb = int(COMPOSERS[b][0])
			var early := a if ya < yb else b
			var late := b if early == a else a
			var ye := int(COMPOSERS[early][0])
			var yl := int(COMPOSERS[late][0])
			ex = K.number("%s was born in %d and %s in %d. How many years apart were they born?" % [early, ye, late, yl], yl - ye,
				"Take the earlier year from the later one.", "%d − %d = %d years." % [yl, ye, yl - ye])
			ex.data = {"a": early, "b": late}
	return ex


const BASS_LINES: Array[String] = ["G2", "B2", "D3", "F3", "A3"]
const BASS_SPACES: Array[String] = ["A2", "C3", "E3", "G3"]
const BASS_LEDGER: Array[String] = ["E2", "F2", "B3", "C4"]


## Name the note on the bass clef. Level 1: a note on a line; level 2: in a space or on a ledger line; level 3: the
## marked note of four.
static func bass_note(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array[String] = []
	pool.assign(BASS_LINES if level == 1 else (BASS_SPACES + BASS_LEDGER if level == 2 else BASS_LINES + BASS_SPACES))
	var note := pool[rng.randi_range(0, pool.size() - 1)]
	var pic := {"kind": "clef_stave", "clef": "bass", "notes": [note]}
	if level == 3:
		var notes: Array = []
		for i in 4:
			notes.append((BASS_LINES + BASS_SPACES)[rng.randi_range(0, 8)])
		var m := rng.randi_range(0, 3)
		notes[m] = note
		pic = {"kind": "clef_stave", "clef": "bass", "notes": notes, "mark": m}
	var letter := note.left(1)
	var wrongs: Array = []
	for l in "CDEFGAB":
		if l != letter:
			wrongs.append(l)
	K.shuffle(rng, wrongs)
	var where := "on a line" if BASS_LINES.has(note) else ("in a space" if BASS_SPACES.has(note) else "on a ledger line")
	var ex := K.choice(rng, "Which note is %s on the bass clef?" % ("the orange one" if level == 3 else "this"), letter, wrongs.slice(0, 3),
		"The bass clef's lines from the bottom are G, B, D, F, A (Good Boys Deserve Fun Always); its spaces A, C, E, G (All Cows Eat Grass).",
		"It is %s: %s." % [where, letter], pic)
	ex.data = {"note": note}
	return ex


const WHOLE_VALUES: Array[String] = ["semibreve", "dotted minim", "minim", "crotchet"]
const PART_VALUES: Array[String] = ["dotted crotchet", "quaver", "crotchet", "minim"]
const BEATS := {"semibreve": 4.0, "dotted minim": 3.0, "minim": 2.0, "dotted crotchet": 1.5, "crotchet": 1.0,
	"dotted quaver": 0.75, "quaver": 0.5, "semiquaver": 0.25}


## Dotted notes and ties: how many beats notes last in all. Level 1: whole beats (a dotted minim); level 2: a dotted
## crotchet and quavers; level 3: with a tie and a dotted quaver.
static func dotted_beats(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var values: Array = []
	var notes: Array = []
	var ties: Array = []
	var pool: Array[String] = ["C5", "B4", "A4", "G4", "F4", "E4"]
	var n: int = [0, rng.randi_range(2, 3), 4, 4][level]
	for i in n:
		if level == 1:
			values.append(WHOLE_VALUES[rng.randi_range(1, 3)])
		elif level == 2:
			values.append(PART_VALUES[rng.randi_range(0, 3)])
		else:
			values.append(["dotted crotchet", "quaver", "dotted quaver", "semiquaver", "minim", "crotchet"][rng.randi_range(0, 5)])
		notes.append(pool[rng.randi_range(0, pool.size() - 1)])
	if level == 2 and not values.has("dotted crotchet"):
		values[0] = "dotted crotchet"
	if level == 3:
		notes[1] = notes[0]
		ties = [0]
	var total := 0.0
	var parts: Array[String] = []
	for v: String in values:
		total += float(BEATS[v])
		parts.append(_num(float(BEATS[v])))
	var pic := {"kind": "clef_stave", "clef": "treble", "notes": notes, "values": values}
	if not ties.is_empty():
		pic.ties = ties
	var ex := K.number("How many beats do these notes last in all?", _num(total),
		"A dot adds half the note again. A tie joins two notes into one longer note: add both.",
		"%s: %s = %s beats." % [", ".join(PackedStringArray(values)), " + ".join(parts), _num(total)], pic)
	ex.data = {"values": values}
	return ex


const RIFFS: Array = [["C", "E", "G", "A"], ["C", "D", "E", "G"], ["E", "G", "A", "C"], ["G", "A", "C", "D"], ["A", "G", "E", "D"],
	["C", "G", "A", "E"]]


## Riffs. Level 1: how many times a riff repeats to fill some bars; level 2: the riff moved to start on F or G; level 3:
## heard: how many times the riff plays.
static func riff_repeat(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var bars: int = [1, 2, 4][rng.randi_range(0, 2)]
			var total := bars * rng.randi_range(2, 8)
			ex = K.number("A riff is %d bar%s long. It repeats all through a %d-bar verse. How many times does it play?" % [bars, "" if bars == 1 else "s", total],
				total / bars, "How many riffs of that length fit into the verse?", "%d ÷ %d = %d times." % [total, bars, total / bars])
			ex.data = {"bars": bars, "total": total}
		2:
			var riff: Array = RIFFS[rng.randi_range(0, RIFFS.size() - 1)]
			var up: int = [3, 4][rng.randi_range(0, 1)]   # letters up: a fourth (C to F) or a fifth (C to G)
			var moved: Array = []
			for l: String in riff:
				moved.append(LETTERS[(LETTERS.find(l) + up) % 7])
			var start := LETTERS[(LETTERS.find(str(riff[0])) + up) % 7]
			var right := ", ".join(PackedStringArray(moved))
			var wrongs: Array = []
			for k in [up - 1, up + 1, 2]:
				var w: Array = []
				for l: String in riff:
					w.append(LETTERS[(LETTERS.find(l) + k) % 7])
				var s := ", ".join(PackedStringArray(w))
				if s != right and not wrongs.has(s):
					wrongs.append(s)
			ex = K.choice(rng, "The riff %s moves up so it starts on %s. What are its notes now?" % [", ".join(PackedStringArray(riff)), start], right, wrongs,
				"Every note moves up by the same number of letters as the first one.",
				"%s to %s is %d letters up, so every note moves %d letters: %s." % [riff[0], start, up, up, right])
			ex.data = {"riff": riff, "up": up}
		_:
			var riff: Array = RIFFS[rng.randi_range(0, RIFFS.size() - 1)]
			var times := rng.randi_range(2, 4)
			var notes: Array = []
			for t in times:
				for l: String in riff.slice(0, 3):
					notes.append("%s4" % l)
				notes.append("-")
			ex = K.number("Listen. How many times does the riff play?", times, "Listen for the start of the pattern each time it comes back; count on your fingers.",
				"The riff %s plays %d times, with a short rest after each." % [", ".join(PackedStringArray(riff.slice(0, 3))), times])
			ex.sound = {"kind": "notes", "notes": notes, "beat": 0.4}
			ex.data = {"riff": riff.slice(0, 3), "times": times}
	return ex


const CUES := {"chase": "fast and loud: drums, short repeated notes", "sunrise": "slow, rising, growing louder, in a major key",
	"sneak": "quiet and low, with short plucked notes", "storm": "loud and low: crashing cymbals, a minor key",
	"hero": "a bold brass fanfare in a major key", "villain": "low, slow brass in a minor key",
	"comedy": "a bouncy bassoon and plucked strings", "farewell": "slow, soft strings in a minor key"}
## Themes to hear: each scene's tune (SchoolSound notes) and tone.
const THEMES := {"hero": [["C4", "G4", "C5:2", "E5", "G5:3"], "bright", 1.0],
	"villain": [["C3:2", "Eb3:2", "F#3:2", "C3:2"], "hollow", 1.0],
	"sneak": [["E4", "-", "F4", "-", "E4", "-", "B3", "-"], "plucked", 0.4],
	"farewell": [["E4:2", "G4:2", "C5:3", "B4", "A4:4"], "pure", 0.7]}


## Music for a scene. Level 1: the music that fits a scene; level 2: heard: which scene a theme is for; level 3: a
## leitmotif changed: what it tells us.
static func film_cue(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var scene := str(CUES.keys()[rng.randi_range(0, CUES.size() - 1)])
			var wrongs: Array = CUES.keys().filter(func(s: String) -> bool: return s != scene).map(func(s: String) -> String: return str(CUES[s]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which music fits this scene best?", str(CUES[scene]), wrongs.slice(0, 3),
				"How should the audience feel: excited, calm, scared, happy, sad? Pick the speed, loudness, key and instruments that match.",
				"For a %s scene: %s." % [scene, CUES[scene]], {"kind": "film_strip", "frames": [scene]})
			ex.data = {"scene": scene}
		2:
			var scene := str(THEMES.keys()[rng.randi_range(0, THEMES.size() - 1)])
			var t: Array = THEMES[scene]
			var words := {"hero": "the hero arriving", "villain": "the villain appearing", "sneak": "someone sneaking at night",
				"farewell": "friends saying goodbye"}
			ex = K.choice(rng, "Listen to this theme. Which moment is it for?", words[scene],
				words.values().filter(func(w: String) -> bool: return w != words[scene]),
				"Is it high or low, major or minor, loud or quiet, smooth or spiky?",
				"%s: %s." % [str(words[scene]).capitalize(), {"hero": "high, rising and bright, in a major key", "villain": "low and slow, in a minor key, with a clash",
					"sneak": "quiet, short notes with gaps", "farewell": "slow and soft, falling at the end"}[scene]])
			ex.sound = {"kind": "notes", "notes": t[0], "tone": t[1], "volume": t[2]}
			ex.data = {"scene": scene}
		_:
			var sad := rng.randi() % 2 == 0
			var notes: Array = ["C4", "G4", "C5:2", "E5", "G5:3"] if not sad else ["C4:2", "G4:2", "C5:2", "Eb5:2"]
			var right := "the hero wins and is full of hope" if not sad else "the hero is in trouble and losing hope"
			ex = K.choice(rng, "The hero's theme returns near the end of the film. Listen. What is the music telling us?", right,
				["the hero wins and is full of hope", "the hero is in trouble and losing hope", "a new character arrives"].filter(func(w: String) -> bool: return w != right),
				"A leitmotif can change: faster or slower, major or minor. How has it changed?",
				("Bright, fast and in a major key, as at the start: the hero is winning." if not sad else
					"The same theme, slower and in a minor key (E flat for E): the hero is in trouble and losing hope."))
			ex.sound = {"kind": "notes", "notes": notes, "tone": "bright" if not sad else "hollow"}
			ex.data = {"sad": sad}
	return ex


const PARTS: Array[String] = ["vocals", "guitar", "bass", "drums", "keys"]


## A mixing desk. Level 1: which part you hear most; level 2: which fader to raise so the tune is heard; level 3: how
## many steps up.
static func mix_balance(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var parts := PARTS.duplicate()
	K.shuffle(rng, parts)
	var n := 4
	var top := rng.randi_range(0, n - 1)
	var voice := (top + rng.randi_range(1, n - 1)) % n
	var top_level := rng.randi_range(5, 8)
	var faders: Array = []
	var others := _distinct(rng, n - 1, 1, top_level - 1)
	var k := 0
	for i in n:
		if i == top:
			faders.append([parts[i], top_level])
		else:
			faders.append([parts[i], others[k]])
			k += 1
	var ex := {}
	match level:
		1:
			ex = K.choice(rng, "Which part will you hear the most?", str(faders[top][0]),
				faders.filter(func(f: Array) -> bool: return f != faders[top]).map(func(f: Array) -> String: return str(f[0])),
				"The higher a fader is pushed up, the louder its part.", "%s is set highest, at %d." % [str(faders[top][0]).capitalize(), top_level],
				{"kind": "mixer", "faders": faders, "meters": true})
		2:
			var tune := str(faders[voice][0])
			ex = K.choice(rng, "The tune is in the %s part, and it must be heard over the rest. Which fader should go up?" % tune, tune,
				faders.filter(func(f: Array) -> bool: return str(f[0]) != tune).map(func(f: Array) -> String: return str(f[0])),
				"Balance: the part with the tune should be the loudest.",
				"The %s part is at %d but the %s part is at %d: push the %s up above it." % [tune, faders[voice][1], faders[top][0], top_level, tune],
				{"kind": "mixer", "faders": faders})
		_:
			var need := top_level + 2 - int(faders[voice][1])
			ex = K.number("The %s part must be 2 steps louder than the loudest other part. How many steps must its fader go up?" % faders[voice][0], need,
				"Find the loudest other part, add 2, then take away where the fader is now.",
				"The loudest other part is at %d; %d + 2 = %d; %d − %d = %d steps." % [top_level, top_level, top_level + 2, top_level + 2,
					faders[voice][1], need], {"kind": "mixer", "faders": faders, "mark": voice})
	ex.data = {"faders": faders}
	return ex


## A song's length. Level 1: the bars of its parts; level 2: the seconds at a tempo; level 3: the tempo from the time.
static func song_length(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var intro: int = [2, 4][rng.randi_range(0, 1)]
			var verse: int = [8, 16][rng.randi_range(0, 1)]
			var chorus: int = [8, 16][rng.randi_range(0, 1)]
			var total := intro + 2 * verse + 3 * chorus
			ex = K.number("A song: intro %d bars, verse %d, chorus %d, verse %d, chorus %d, chorus %d. How many bars in all?" % [intro, verse, chorus,
				verse, chorus, chorus], total, "Add the parts; the chorus comes three times.",
				"%d + %d + %d + %d + %d + %d = %d bars." % [intro, verse, chorus, verse, chorus, chorus, total],
				{"kind": "song_form", "sections": ["intro", "verse", "chorus", "verse", "chorus", "chorus"]})
			ex.data = {"intro": intro, "verse": verse, "chorus": chorus}
		2:
			var tempo: int = [60, 80, 90, 100, 120, 150][rng.randi_range(0, 5)]
			var bars: int = [8, 16, 20, 24, 32, 40][rng.randi_range(0, 5)]
			var beats := bars * 4
			while beats * 60 % tempo != 0:
				bars += 1
				beats = bars * 4
			ex = K.number("%d bars of 4 beats at %d beats a minute. How many seconds do they last?" % [bars, tempo], beats * 60 / tempo,
				"Find the beats first, then how many beats pass each second.",
				"%d × 4 = %d beats. At %d a minute, that is %d × 60 ÷ %d = %d seconds." % [bars, beats, tempo, beats, tempo, beats * 60 / tempo])
			ex.data = {"bars": bars, "tempo": tempo}
		_:
			var tempo: int = [60, 80, 90, 100, 120, 150][rng.randi_range(0, 5)]
			var bars: int = [8, 16, 20, 30, 40][rng.randi_range(0, 4)]
			while bars * 4 * 60 % tempo != 0:
				bars += 1
			var secs := bars * 4 * 60 / tempo
			ex = K.number("%d bars of 4 beats take %d seconds. What is the tempo in beats a minute?" % [bars, secs], tempo,
				"Find the beats, then how many would fit in 60 seconds.",
				"%d × 4 = %d beats in %d seconds, so %d × 60 ÷ %d = %d beats a minute." % [bars, bars * 4, secs, bars * 4, secs, tempo])
			ex.data = {"bars": bars, "secs": secs}
	return ex


const METRES := {"6/8": [6, "a jig"], "3/4": [6, "a waltz"], "4/4": [8, "a reel"], "2/4": [4, "a polka"]}


## Folk dances' time: jigs in 6/8, reels in 4/4, waltzes in 3/4, polkas in 2/4. Level 1: quavers in a bar; level 2:
## bars from quavers; level 3: how many beats a 6/8 or 12/8 bar has (dotted crotchets).
static func folk_metre(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var t := str(METRES.keys()[rng.randi_range(0, METRES.size() - 1)])
			var q := int(METRES[t][0])
			ex = K.number("%s is in %s. How many quavers fit in one bar?" % [str(METRES[t][1]).capitalize(), t], q,
				"A quaver is half a crotchet, and an 8 at the bottom means the bar counts in quavers.",
				"%s: %s." % [t, "6 quavers (the 8 counts quavers)" if t == "6/8" else "%s crotchets, and 2 quavers each: %d quavers" % [t.left(1), q]])
			ex.data = {"time": t}
		2:
			var bars := rng.randi_range(4, 16)
			ex = K.number("A jig in 6/8 has %d quavers of tune. How many bars is that?" % (bars * 6), bars,
				"How many quavers does each 6/8 bar hold?", "6 quavers a bar: %d ÷ 6 = %d bars." % [bars * 6, bars])
			ex.data = {"bars": bars}
		_:
			var t: String = ["6/8", "12/8", "9/8"][rng.randi_range(0, 2)]
			var beats := int(t.get_slice("/", 0)) / 3
			ex = K.number("In %s the quavers are grouped in threes, and each group is one beat (a dotted crotchet). How many beats are in a bar?" % t, beats,
				"How many groups of 3 quavers make the top number?",
				"%s quavers in groups of 3: %s ÷ 3 = %d beats a bar." % [t.get_slice("/", 0), t.get_slice("/", 0), beats])
			ex.data = {"time": t}
	return ex


# --- helpers ---------------------------------------------------------------------------------------------------------

## `count` different whole numbers from lo to hi, in a seeded order.
static func _distinct(rng: RandomNumberGenerator, count: int, lo: int, hi: int) -> Array[int]:
	var out: Array[int] = []
	while out.size() < count:
		var v := rng.randi_range(lo, hi)
		if not out.has(v):
			out.append(v)
	return out


static func _is_sorted(a: Array) -> bool:
	for i in a.size() - 1:
		if a[i] > a[i + 1]:
			return false
	return true


static func _csv(a: Array) -> String:
	return ", ".join(PackedStringArray(a.map(func(x: Variant) -> String: return str(x))))


## A number as the lessons write it: 3, 2.5, 0.75.
static func _num(v: float) -> String:
	if v == floorf(v):
		return str(int(v))
	return str(snappedf(v, 0.01))
