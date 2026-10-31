class_name G5NumbersGen
extends RefCounted
## Owner #68 (spec §22.5): grade 5 maths generators for whole numbers, decimals and expressions (Common Core 5.NBT,
## 5.OA.1-2; units 1-7 of the outline): SchoolGen "g5n.<name>", `static func <name>(rng: RandomNumberGenerator,
## level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a worked answer and `data` (its inputs, for
## tests/unit/test_g5_maths_gen.gd). Decimals are worked in whole thousandths or hundredths, never floats. Helpers start
## with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]
const SUP := "⁰¹²³⁴⁵⁶⁷⁸⁹"
const PLACE_NAMES := {3: "thousands", 2: "hundreds", 1: "tens", 0: "ones", -1: "tenths", -2: "hundredths",
	-3: "thousandths"}


# --- Unit 1: powers of ten (5.NBT.1, 5.NBT.2) ----------------------------------------------------------------------

## "3.45 × 100 = ?", "7,200 ÷ 100 = ?"
static func times_power(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: int = [10, 100, 1000][rng.randi_range(0, 2)]
	var v := 0   # thousandths
	var op := "×"
	match level:
		1:
			v = rng.randi_range(2, 999) * 1000
		2:
			if rng.randf() < 0.5:
				op = "÷"
				v = rng.randi_range(2, 999) * p * 1000
			else:
				p = [10, 100][rng.randi_range(0, 1)]
				v = rng.randi_range(11, 999) * 100   # 1.1 … 99.9
				if v % 1000 == 0:
					v += 100
		_:
			if rng.randf() < 0.5:
				v = rng.randi_range(101, 9999) * 10 if rng.randf() < 0.6 else rng.randi_range(1001, 9999)
				if v % 1000 == 0:
					v += 10
			else:
				op = "÷"
				if rng.randf() < 0.5:
					v = rng.randi_range(12, 9999) * 1000
				else:
					p = [10, 100][rng.randi_range(0, 1)]
					v = rng.randi_range(11, 999) * 100
	var places := str(p).length() - 1
	var answer := v * p if op == "×" else int(v / float(p))
	var way := "left" if op == "×" else "right"
	var ex := K.number("%s %s %s = ?" % [_dec(v), op, K.fmt(p)], _dec(answer),
		"%s %s moves every digit %s to the %s." % [op, K.fmt(p), _places_word(places), way],
		"Every digit moves %s to the %s: %s %s %s = %s." % [_places_word(places), way, _dec(v), op, K.fmt(p), _dec(answer)])
	ex.data = {"v": v, "p": p, "op": op}
	return ex


## "10³ = ?", "4 × 10³ = ?", "3.6 × 10² = ?"
static func power_value(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var k := rng.randi_range(1, 4) if level == 1 else rng.randi_range(2, 5)
	var c := 1000   # the number in front, in thousandths
	var prompt := "10%s = ?" % _sup(k)
	if level == 2:
		c = rng.randi_range(2, 9) * 1000
		prompt = "%d × 10%s = ?" % [c / 1000, _sup(k)]
	elif level == 3:
		if rng.randf() < 0.5:
			c = rng.randi_range(11, 99) * 100   # 1.1 … 9.9
			k = rng.randi_range(1, 3)
			if c % 1000 == 0:
				c += 100
		else:
			c = rng.randi_range(101, 999) * 10   # 1.01 … 9.99
			k = rng.randi_range(2, 3)
			if c % 100 == 0:
				c += 10
		prompt = "%s × 10%s = ?" % [_dec(c), _sup(k)]
	var answer := c * K.pow10(k)
	var power := K.fmt(K.pow10(k))
	var ex := K.number(prompt, _dec(answer), "10%s is 1 followed by %d zeros: %s." % [_sup(k), k, power],
		"10%s = %s%s" % [_sup(k), power, "" if c == 1000 else ", and %s × %s = %s." % [_dec(c), power, _dec(answer)]])
	ex.data = {"c": c, "k": k}
	return ex


## "Which is the same as 100,000?" (10⁵), "Which number is 10⁴?", "1,000,000 = 10 to the power of ?"
static func which_power(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var k := rng.randi_range(2, 6)
	var n := K.fmt(K.pow10(k))
	var ex: Dictionary
	match level:
		1:
			ex = K.choice(rng, "Which is the same as %s?" % n, "10" + _sup(k), ["10" + _sup(k - 1), "10" + _sup(k + 1),
				"%d × 10" % k], "Count the zeros in %s." % n, "%s has %d zeros, so it is 10%s." % [n, k, _sup(k)])
		2:
			ex = K.choice(rng, "Which number is 10%s?" % _sup(k), n, [K.fmt(K.pow10(k - 1)), K.fmt(K.pow10(k + 1)),
				str(10 * k)], "10%s means %d tens multiplied together." % [_sup(k), k],
				"10%s = 1 followed by %d zeros = %s." % [_sup(k), k, n])
		_:
			ex = K.number("%s = 10 to the power of ?" % n, k, "How many tens are multiplied to make %s? Count its zeros." % n,
				"%s has %d zeros: %s = 10%s." % [n, k, n, _sup(k)])
	ex.data = {"k": k}
	return ex


## "In 4,770, the 7 in the hundreds is worth how many times the 7 in the tens?"; level 3 in decimals, both ways.
static func digit_times(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d := rng.randi_range(1, 9)
	var hi := 0
	var lo := 0
	var up := true
	var places: Array = [3, 2, 1, 0]
	match level:
		1:
			lo = rng.randi_range(0, 2)
			hi = lo + 1
		2:
			lo = rng.randi_range(0, 1)
			hi = lo + 2
		_:
			places = [1, 0, -1, -2, -3]
			lo = rng.randi_range(-3, -1)
			hi = mini(lo + rng.randi_range(1, 2), 1)
			up = rng.randf() < 0.5
	var whole := ""
	var part := ""
	for p: int in places:
		var digit := d
		if p != hi and p != lo:
			digit = rng.randi_range(1 if p == places[0] else 0, 9)
			if digit == d:
				digit = (d % 9) + 1 if p == places[0] else (d + 1) % 10
		if p >= 0:
			whole += str(digit)
		else:
			part += str(digit)
	var n := K.fmt(int(whole)) + ("." + part if part != "" else "")
	var times := K.pow10(hi - lo)
	var worth_hi := _dec(d * K.pow10(hi + 3))
	var worth_lo := _dec(d * K.pow10(lo + 3))
	var ex: Dictionary
	if up:
		ex = K.number("In %s, the %d in the %s is worth how many times the %d in the %s?" % [n, d, PLACE_NAMES[hi], d,
			PLACE_NAMES[lo]], times, "Each place is worth 10 times the place to its right.",
			"The %d in the %s is worth %s and the %d in the %s is worth %s: %s times as much." % [d, PLACE_NAMES[hi], worth_hi,
				d, PLACE_NAMES[lo], worth_lo, K.fmt(times)])
	else:
		ex = K.number("In %s, the %d in the %s is what fraction of the %d in the %s?" % [n, d, PLACE_NAMES[lo], d,
			PLACE_NAMES[hi]], "1/%d" % times, "Each place is worth 1/10 of the place to its left.",
			"The %d in the %s is worth %s and the other %s: 1/%d of it." % [d, PLACE_NAMES[lo], worth_lo, worth_hi, times])
	ex.data = {"n": n, "d": d, "hi": hi, "lo": lo, "up": up}
	return ex


## "56 × ? = 5,600", "? ÷ 100 = 0.37"
static func missing_power(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: int = [10, 100, 1000][rng.randi_range(0, 2)]
	var ex: Dictionary
	match level:
		1:
			var a := rng.randi_range(2, 99)
			ex = K.number("%d × ? = %s" % [a, K.fmt(a * p)], p, "How many zeros were added to %d?" % a,
				"%d × %s = %s" % [a, K.fmt(p), K.fmt(a * p)])
		2:
			var a := rng.randi_range(12, 999)
			ex = K.number("? × %s = %s" % [K.fmt(p), K.fmt(a * p)], a, "Take the zeros of %s away from %s." % [K.fmt(p),
				K.fmt(a * p)], "%s × %s = %s" % [K.fmt(a), K.fmt(p), K.fmt(a * p)])
		_:
			p = [10, 100][rng.randi_range(0, 1)]
			var v := rng.randi_range(11, 999) * 10   # hundredths × 10: 0.11 … 9.99 with one or two places
			if rng.randf() < 0.5:
				ex = K.number("%s × ? = %s" % [_dec(v, 100), _dec(v * p, 100)], p,
					"How many places did the digits move to the left?", "%s × %s = %s" % [_dec(v, 100), K.fmt(p), _dec(v * p, 100)])
			else:
				ex = K.number("? ÷ %s = %s" % [K.fmt(p), _dec(v, 100)], _dec(v * p, 100),
					"Undo it: multiply %s by %s." % [_dec(v, 100), K.fmt(p)], "%s ÷ %s = %s" % [_dec(v * p, 100), K.fmt(p),
						_dec(v, 100)])
	ex.data = {"p": p}
	return ex


# --- Unit 2: decimals to thousandths (5.NBT.3, 5.NBT.4) --------------------------------------------------------------

## "In 4.716, what is the 1 worth?"
static func decimal_digit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits: Array = range(1, 10)
	K.shuffle(rng, digits)
	var whole_n := 2 if level == 3 else 1
	var part_n := 2 if level == 1 else 3
	var whole := ""
	var part := ""
	for i in whole_n:
		whole += str(digits[i])
	for i in part_n:
		part += str(digits[whole_n + i])
	var n := whole + "." + part
	var place := -rng.randi_range(1, part_n) if level < 3 else rng.randi_range(-part_n, whole_n - 1)
	var at := whole_n - 1 - place if place >= 0 else whole_n - place
	var d := int(n[at])
	var right := _dec(d * K.pow10(place + 3))
	var wrongs: Array = []
	for p in [1, 0, -1, -2, -3]:
		if p != place and wrongs.size() < 3:
			wrongs.append(_dec(d * K.pow10(p + 3)))
	var pic := {"kind": "places", "numbers": [n]} if level == 1 else {}
	var ex := K.choice(rng, "In %s, what is the %d worth?" % [n, d], right, wrongs,
		"Say the places after the point: tenths, hundredths, thousandths.",
		"The %d is in the %s place, so it is worth %s." % [d, PLACE_NAMES[place], right], pic)
	ex.data = {"n": n, "d": d, "place": place}
	return ex


## "3 + 0.4 + 0.05 + 0.007 = ?"; level 3: "4 × 10 + 2 × 1 + 3 × 1/10 + 6 × 1/1000 = ?"
static func expanded_decimal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t := 0
	var terms: Array[String] = []
	if level < 3:
		var w := rng.randi_range(1, 9)
		t = w * 1000
		terms.append(str(w))
		var places := 2 if level == 1 else 3
		for i in places:
			var digit := rng.randi_range(1, 9) if level == 1 or i == 0 or rng.randf() < 0.7 else 0
			if digit > 0:
				var v := digit * K.pow10(2 - i)
				t += v
				terms.append(_dec(v))
		if terms.size() == 1:
			t += 400
			terms.append("0.4")
	else:
		var parts := [[rng.randi_range(1, 9), 10000, "10"], [rng.randi_range(0, 9), 1000, "1"], [rng.randi_range(1, 9), 100,
			"1/10"], [rng.randi_range(0, 9), 10, "1/100"], [rng.randi_range(1, 9), 1, "1/1000"]]
		for part: Array in parts:
			if int(part[0]) > 0:
				t += int(part[0]) * int(part[1])
				terms.append("%d × %s" % [part[0], part[2]])
	var sum := " + ".join(terms)
	var hint := "1/10 is a tenth, 1/100 a hundredth and 1/1000 a thousandth. Put each part in its place." if level == 3 \
		else "Put each part in its place: ones, then tenths, hundredths and thousandths."
	var ex := K.number("%s = ?" % sum, _dec(t), hint, "%s = %s" % [sum, _dec(t)])
	ex.data = {"t": t}
	return ex


## "Which number is four and twenty-six thousandths?"
static func decimal_words(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den: int = [[10, 100], [100, 1000], [1000]][level - 1][rng.randi_range(0, 1 if level < 3 else 0)]
	var w := rng.randi_range(0, 20 if level < 3 else 99)
	var n := rng.randi_range(1, den - 1)
	if den > 10 and n % 10 == 0:
		n += 1
	var words := {10: ["tenth", "tenths"], 100: ["hundredth", "hundredths"], 1000: ["thousandth", "thousandths"]}
	var said := "%s %s" % [NumberWords.say(n), words[den][0] if n == 1 else words[den][1]]
	if w > 0:
		said = "%s and %s" % [NumberWords.say(w), said]
	var right := _dec(w * den + n, den)
	var wrongs: Array = []
	for other: int in [10, 100, 1000, 10000]:
		if other != den and n < other:
			wrongs.append(_dec_text(w, n, other))
	wrongs.append("%d.%d" % [n, w] if w > 0 else str(n))
	var ex := K.choice(rng, "Which number is %s?" % said, right, wrongs.slice(0, 3) if wrongs.size() > 3 else wrongs,
		"The last word says the place of the last digit: %s." % words[den][1],
		"%s is %s." % [said, right])
	ex.data = {"w": w, "n": n, "den": den}
	return ex


## "Which sign makes this true?  0.45 ? 0.405"
static func compare_decimals(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	var at := ""
	var bt := ""
	match level:
		1:
			a = rng.randi_range(1, 99) * 10
			b = clampi(a + rng.randi_range(1, 8) * 10 * (1 if rng.randf() < 0.5 else -1), 10, 990)
			if b == a:
				b = a + 10 if a < 990 else a - 10
		2:
			a = rng.randi_range(1, 9) * 100
			b = rng.randi_range(1, 999)
			if b % 100 == 0:
				b += 5
		_:
			var w := rng.randi_range(1, 9) * 1000
			a = w + rng.randi_range(1, 9) * 100
			b = w + rng.randi_range(1, 999)
			if b % 100 == 0:
				b += 5
			if rng.randf() < 0.2:
				b = a
				bt = _dec(a) + "0"
	at = _dec(a)
	if bt == "":
		bt = _dec(b)
	if rng.randf() < 0.5:
		var t := a
		a = b
		b = t
		var tt := at
		at = bt
		bt = tt
	var sign := "=" if a == b else (">" if a > b else "<")
	var ex := K.choice(rng, "Which sign makes this true?  %s ? %s" % [at, bt], sign, [">", "<", "="].filter(
		func(x: String) -> bool: return x != sign), "Line up the points. Compare the tenths first, then the hundredths, then the thousandths.",
		"%s is %s thousandths and %s is %s thousandths, so %s %s %s." % [at, K.fmt(a), bt, K.fmt(b), at, sign, bt])
	ex.data = {"a": a, "b": b}
	return ex


## Four decimals (three at level 1), smallest first.
static func order_decimals(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var base := rng.randi_range(2, 8) * 100 + (rng.randi_range(1, 3) * 1000 if level == 3 else 0)
	var pool: Array = [base, base + rng.randi_range(1, 9) * 10, base + rng.randi_range(1, 9), base + 100 + rng.randi_range(0, 9) * 10,
		base - 100 + rng.randi_range(1, 99) * (10 if level == 1 else 1), base + rng.randi_range(11, 99)]
	if level == 1:
		pool = pool.map(func(v: int) -> int: return int(v / 10.0) * 10)
	var values: Array = []
	for v: int in pool:
		if not values.has(v) and v > 0:
			values.append(v)
	K.shuffle(rng, values)
	values = values.slice(0, 3 if level == 1 else 4)
	values.sort()
	var texts: Array = values.map(func(v: int) -> String: return _dec(v))
	var ex := K.order(rng, "Put these in order, smallest first.", texts,
		"Line up the points. Compare the tenths first, then the hundredths, then the thousandths.",
		"Smallest first: %s." % ", ".join(texts))
	ex.data = {"values": values}
	return ex


## "Round 3.267 to the nearest tenth."
static func round_decimal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var unit: int = [1000, 100, 10][level - 1]
	var t := rng.randi_range(1, 9) * 1000 + rng.randi_range(1, 99) * 10 if level == 1 else rng.randi_range(1001, 9999)
	if t % unit == 0:
		t += int(unit * 0.5)
	var lo := int(t / float(unit)) * unit
	var rounded := int((t + unit * 0.5) / unit) * unit
	var places: int = [0, 1, 2][level - 1]
	var words: String = ["whole number", "tenth", "hundredth"][level - 1]
	var next := int(t / (unit / 10.0)) % 10
	var pic := {}
	if level < 3:
		pic = {"kind": "number_line", "from": _dec(lo), "to": _dec(lo + unit), "step": ["0.1", "0.01"][level - 1],
			"dot": _dec(t), "labels": "ends"}
	var ex := K.number("Round %s to the nearest %s." % [_dec(t), words], _fixed(rounded, places),
		"Look at the next digit after the %s place: 5 or more rounds up, less than 5 rounds down." % ["ones", "tenths",
			"hundredths"][level - 1], "%s is between %s and %s. The next digit is %d, so it rounds %s to %s." % [_dec(t),
			_fixed(lo, places), _fixed(lo + unit, places), next, "up" if rounded > lo else "down", _fixed(rounded, places)], pic)
	ex.data = {"t": t, "unit": unit}
	return ex


## "What number is at the dot?" on a line of hundredths (level 1) or thousandths.
static func decimal_on_line(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var step := 10 if level == 1 else 1   # thousandths
	var from := rng.randi_range(0, 9) * 1000 + rng.randi_range(0, 9) * 100 + (0 if level == 1 else rng.randi_range(0, 9) * 10)
	var t := from + rng.randi_range(1, 9) * step
	var ex := K.number("What number is at the dot?", _dec(t), "The line is cut into %s. Count the steps from %s." % [
		"hundredths" if level == 1 else "thousandths", _dec(from)],
		"The dot is %d %s after %s: %s." % [int((t - from) / float(step)), "hundredths" if level == 1 else "thousandths",
			_dec(from), _dec(t)], {"kind": "number_line", "from": _dec(from), "to": _dec(from + 10 * step),
			"step": "0.01" if level == 1 else "0.001", "dot": _dec(t), "labels": "ends"})
	ex.data = {"t": t}
	return ex


# --- Unit 3: multiply whole numbers (5.NBT.5) ------------------------------------------------------------------------

static func multiply(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	match level:
		1:
			if rng.randf() < 0.5:
				a = rng.randi_range(101, 999)
				b = rng.randi_range(3, 9)
			else:
				a = rng.randi_range(12, 39)
				b = rng.randi_range(12, 29)
		2:
			a = rng.randi_range(101, 999)
			b = rng.randi_range(12, 99)
		_:
			a = rng.randi_range(1001, 9999)
			b = rng.randi_range(12, 99)
	var ex := K.number("%s × %d = ?" % [K.fmt(a), b], K.fmt(a * b), _multiply_hint(a, b), _multiply_steps(a, b))
	ex.data = {"a": a, "b": b}
	return ex


## An area model of a × b with one part "?".
static func partial_product(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(12, 99) if level == 1 else rng.randi_range(101, 999)
	var b := rng.randi_range(3, 9) if level == 1 else rng.randi_range(12, 99)
	var cols := _parts(a)
	var rows := _parts(b)
	var hide := Vector2i(rng.randi_range(0, cols.size() - 1), rng.randi_range(0, rows.size() - 1))
	if level == 3:
		hide = Vector2i(0, 0)   # the biggest part
	var cells: Array = []
	for j in rows.size():
		var row: Array = []
		for i in cols.size():
			row.append("?" if Vector2i(i, j) == hide else K.fmt(cols[i] * rows[j]))
		cells.append(row)
	var col: int = cols[hide.x]
	var r: int = rows[hide.y]
	var ex := K.number("The area model shows %s × %d. What number goes in the ? part?" % [K.fmt(a), b], K.fmt(col * r),
		"Multiply the number above the ? part by the number beside it.", "%s × %s = %s" % [K.fmt(col), K.fmt(r),
			K.fmt(col * r)], {"kind": "area_model", "cols": cols.map(func(v: int) -> String: return K.fmt(v)),
			"rows": rows.map(func(v: int) -> String: return K.fmt(v)), "cells": cells})
	ex.data = {"a": a, "b": b, "col": col, "row": r}
	return ex


## "Which is the best estimate of 487 × 32?"
static func estimate_product(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(1001, 9999) if level == 3 else rng.randi_range(101, 999)
	var b := rng.randi_range(3, 9) if level == 1 else rng.randi_range(12, 99)
	var la := _lead(a)
	var lb := _lead(b)
	var right := la * lb
	var ex := K.choice(rng, "Which is the best estimate of %s × %d?" % [K.fmt(a), b], K.fmt(right), [K.fmt(right * 10),
		K.fmt(int(right / 10.0)), K.fmt(right * 100)], "Round each number to its first digit's place, then multiply.",
		"%s is about %s and %d is about %s. %s × %s = %s." % [K.fmt(a), K.fmt(la), b, K.fmt(lb), K.fmt(la), K.fmt(lb),
			K.fmt(right)])
	ex.data = {"a": a, "b": b}
	return ex


static func multiply_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(101, 999) if level < 3 else rng.randi_range(1001, 4999)
	var b := rng.randi_range(3, 9) if level == 1 else rng.randi_range(12, 99)
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var stories: Array[String] = [
		"A farm has %d rows with %s carrots in each row. How many carrots are there?" % [b, K.fmt(a)],
		"Each crate holds %d bottles of juice. How many bottles fill %s crates?" % [b, K.fmt(a)],
		"A castle wall has %d rows of %s blocks. How many blocks is that?" % [b, K.fmt(a)],
		"%s's buddy hops %s times a day. How many hops is that in %d days?" % [who, K.fmt(a), b],
	]
	var ex := K.number(stories[rng.randi_range(0, stories.size() - 1)], K.fmt(a * b), "Multiply: %s × %d." % [K.fmt(a), b],
		_multiply_steps(a, b))
	ex.data = {"a": a, "b": b}
	return ex


## "34 × 12 = 34 × 10 + 34 × 2" true or false (a common mix-up: 30 × 10 + 4 × 2).
static func split_product(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(12, 99) if level < 3 else rng.randi_range(101, 999)
	var b := rng.randi_range(12, 99)
	if b % 10 == 0:
		b += 3
	if a % 10 == 0:
		a += 1
	var bt := int(b / 10.0) * 10
	var bo := b % 10
	var statement := "%s × %d = %s × %d + %s × %d" % [K.fmt(a), b, K.fmt(a), bt, K.fmt(a), bo]
	var right := true
	var roll := rng.randf()
	if roll < 0.3:
		statement = "%s × %d = %s × %d + %d" % [K.fmt(a), b, K.fmt(a), bt, bo]
		right = false
	elif roll < 0.6:
		var at := int(a / 10.0) * 10
		statement = "%s × %d = %s × %d + %d × %d" % [K.fmt(a), b, K.fmt(at), bt, a % 10, bo]
		right = false
	var ex := K.truefalse(statement.replace(",", ""), right, "Every part of %d must be multiplied by all of %s." % [b, K.fmt(a)],
		"%s × %d = %s × %d + %s × %d = %s + %s = %s." % [K.fmt(a), b, K.fmt(a), bt, K.fmt(a), bo, K.fmt(a * bt), K.fmt(a * bo),
			K.fmt(a * b)])
	ex.data = {"a": a, "b": b}
	return ex


# --- Unit 4: divide by two-digit numbers (5.NBT.6) --------------------------------------------------------------------

static func divide(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d := 0
	var q := 0
	match level:
		1:
			d = rng.randi_range(11, 25)
			q = rng.randi_range(2, 12)
		2:
			d = rng.randi_range(12, 49)
			q = rng.randi_range(maxi(11, ceili(100.0 / d)), int(999.0 / d))
		_:
			d = rng.randi_range(12, 99)
			q = rng.randi_range(maxi(20, ceili(1000.0 / d)), int(9999.0 / d))
	var n := d * q
	var ex := K.number("%s ÷ %d = ?" % [K.fmt(n), d], q, "How many %ds make %s? Start with %d × 10 = %s." % [d, K.fmt(n), d,
		K.fmt(d * 10)], "%d × %d = %s, so %s ÷ %d = %d." % [d, q, K.fmt(n), K.fmt(n), d, q])
	ex.data = {"n": n, "d": d, "q": q}
	return ex


static func remainder(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d := rng.randi_range(11, 40 if level < 3 else 99)
	var q := rng.randi_range(4, int(999.0 / d) - 1) if level < 3 else rng.randi_range(int(1000.0 / d) + 1, int(9998.0 / d) - 1)
	var r := rng.randi_range(1, d - 1)
	var n := q * d + r
	var ex: Dictionary
	var steps := "%d × %d = %s, and %s − %s = %d." % [d, q, K.fmt(q * d), K.fmt(n), K.fmt(q * d), r]
	if rng.randf() < 0.5:
		ex = K.number("%s is shared into groups of %d. How many are left over?" % [K.fmt(n), d], r,
			"Find the biggest multiple of %d that is not more than %s." % [d, K.fmt(n)], steps + " %d are left over." % r)
	else:
		ex = K.number("How many whole groups of %d fit into %s?" % [d, K.fmt(n)], q,
			"Find the biggest multiple of %d that is not more than %s." % [d, K.fmt(n)], steps + " So %d whole groups fit." % q)
	ex.data = {"n": n, "d": d}
	return ex


static func division_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d := rng.randi_range(12, 48)
	var q := rng.randi_range(4, int(999.0 / d) - 1) if level < 3 else rng.randi_range(int(1000.0 / d) + 1, int(9998.0 / d) - 1)
	var kinds: Array[String] = ["exact", "up", "down"]
	var kind := kinds[rng.randi_range(0, 0 if level == 1 else 2)]
	var n := q * d if kind == "exact" else q * d + rng.randi_range(1, d - 1)
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var ex: Dictionary
	match kind:
		"exact":
			ex = K.number("%s gold is shared equally among %d buddies. How much gold does each buddy get?" % [K.fmt(n), d], q,
				"Divide: %s ÷ %d." % [K.fmt(n), d], "%s ÷ %d = %d gold each, because %d × %d = %s." % [K.fmt(n), d, q, d, q, K.fmt(n)])
		"up":
			ex = K.number("A boat holds %d children. How many boats are needed for %s children?" % [d, K.fmt(n)], q + 1,
				"Divide, then think: what about the children left over?", "%s ÷ %d = %d with %d left over. They need one more boat: %d." % [
					K.fmt(n), d, q, n - q * d, q + 1])
		_:
			ex = K.number("%s packs %s eggs into boxes of %d. How many boxes can %s fill?" % [who, K.fmt(n), d, who], q,
				"Divide. Can the eggs left over fill a box?", "%s ÷ %d = %d with %d left over, which is not a full box: %d boxes." % [
					K.fmt(n), d, q, n - q * d, q])
	ex.data = {"n": n, "d": d, "kind": kind}
	return ex


## The area model of n ÷ d: "What number goes in the ? part?" (level 3: "What is n ÷ d?").
static func division_area(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d := rng.randi_range(12, 40)
	var p1 := rng.randi_range(1, 3 if level == 1 else 9) * 10
	var p2 := rng.randi_range(2, 9)
	var n := (p1 + p2) * d
	var pic := {"kind": "area_model", "cols": [str(p1), "?"], "rows": [str(d)], "cells": [[K.fmt(p1 * d), K.fmt(p2 * d)]]}
	var ex: Dictionary
	var how := "%d × %d = %s, so the ? is %d. %s ÷ %d = %d + %d = %d." % [d, p2, K.fmt(p2 * d), p2, K.fmt(n), d, p1, p2, p1 + p2]
	if level < 3:
		ex = K.number("Zara works out %s ÷ %d with an area model. What number goes in the ? part?" % [K.fmt(n), d], p2,
			"Which number times %d makes %s?" % [d, K.fmt(p2 * d)], how, pic)
	else:
		ex = K.number("The area model shows %s ÷ %d. What is %s ÷ %d?" % [K.fmt(n), d, K.fmt(n), d], p1 + p2,
			"Find the ? part first, then add the parts on top.", how, pic)
	ex.data = {"n": n, "d": d, "p1": p1, "p2": p2}
	return ex


static func check_division(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d := rng.randi_range(12, 49 if level < 3 else 99)
	var q := rng.randi_range(12, 49 if level == 1 else 99)
	var n := d * q
	var shown := q
	if rng.randf() < 0.5:
		shown = q + [1, -1, 10, -10][rng.randi_range(0, 3)]
	var ex := K.truefalse("%s ÷ %d = %d" % [K.fmt(n), d, shown], shown == q, "Check by multiplying back: %d × %d." % [shown, d],
		"%d × %d = %s, so it is %s." % [shown, d, K.fmt(shown * d), "true" if shown == q else "false: %s ÷ %d = %d" % [K.fmt(n), d, q]])
	ex.data = {"n": n, "d": d, "shown": shown}
	return ex


# --- Unit 5: add and subtract decimals (5.NBT.7) ------------------------------------------------------------------------

static func add_decimals(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var parts: Array = []
	match level:
		1:
			parts = [_tenths(rng, 11, 99), _tenths(rng, 11, 99)]
		2:
			parts = [_hundredths(rng, 101, 999), _tenths(rng, 11, 99)]
			K.shuffle(rng, parts)
		_:
			parts = [_hundredths(rng, 101, 999), _tenths(rng, 11, 99), _hundredths(rng, 101, 499)]
			K.shuffle(rng, parts)
	var sum := 0
	var texts: Array[String] = []
	for p: int in parts:
		sum += p
		texts.append(_dec(p, 100))
	var hint := "Line up the decimal points, so tenths are under tenths."
	for p: int in parts:
		if p % 10 == 0 and level > 1:
			hint += " Write %s as %s if it helps." % [_dec(p, 100), _fixed(p * 10, 2)]
			break
	var ex := K.number("%s = ?" % " + ".join(texts), _dec(sum, 100), hint, "%s = %s" % [" + ".join(texts), _dec(sum, 100)])
	ex.data = {"parts": parts}
	return ex


static func subtract_decimals(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	var hint := "Line up the decimal points. Write every number with the same places, like 5.20."
	match level:
		1:
			a = _tenths(rng, 30, 99)
			b = _tenths(rng, 11, int(a / 10.0) - 1)
		2:
			a = _tenths(rng, 30, 99) if rng.randf() < 0.5 else _hundredths(rng, 301, 999)
			b = _hundredths(rng, 101, a - 10) if a % 10 == 0 else _tenths(rng, 11, int(a / 10.0) - 1)
		_:
			a = rng.randi_range(3, 12) * 100
			b = _hundredths(rng, 101, a - 50)
			hint = "Write %d as %d.00, then take away." % [int(a / 100.0), int(a / 100.0)]
	var ex := K.number("%s − %s = ?" % [_dec(a, 100), _dec(b, 100)], _dec(a - b, 100), hint,
		"%s − %s = %s" % [_fixed(a * 10, 2), _fixed(b * 10, 2), _dec(a - b, 100)])
	ex.data = {"a": a, "b": b}
	return ex


static func decimal_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := _tenths(rng, 11, 49) if level == 1 else _hundredths(rng, 101, 499)
	var b := _tenths(rng, 11, 49) if level < 3 else _hundredths(rng, 101, 499)
	var names := NAMES.duplicate()
	K.shuffle(rng, names)
	var op := "+" if rng.randf() < 0.5 else "−"
	if op == "−" and b >= a:
		var t := a
		a = b
		b = t
	if a == b:
		op = "+"
	var ex: Dictionary
	var stories_add: Array[String] = [
		"A potion needs %s L of water and %s L of berry juice. How many litres is that altogether?",
		"%s's buddy weighs %s kg and %s's buddy weighs %s kg. How many kg do they weigh together?",
	]
	var stories_sub: Array[String] = [
		"%s jumped %s m and %s jumped %s m. How much further did %s jump, in metres?",
		"A path is %s km long. %s has walked %s km. How many km are left?",
	]
	if op == "+":
		if rng.randf() < 0.5:
			ex = K.number(stories_add[0] % [_dec(a, 100), _dec(b, 100)], _dec(a + b, 100), "Add, with the points lined up.",
				"%s + %s = %s L" % [_dec(a, 100), _dec(b, 100), _dec(a + b, 100)])
		else:
			ex = K.number(stories_add[1] % [names[0], _dec(a, 100), names[1], _dec(b, 100)], _dec(a + b, 100),
				"Add, with the points lined up.", "%s + %s = %s kg" % [_dec(a, 100), _dec(b, 100), _dec(a + b, 100)])
	else:
		if rng.randf() < 0.5:
			ex = K.number(stories_sub[0] % [names[0], _dec(a, 100), names[1], _dec(b, 100), names[0]], _dec(a - b, 100),
				"Take the shorter jump away from the longer one.", "%s − %s = %s m" % [_dec(a, 100), _dec(b, 100), _dec(a - b, 100)])
		else:
			ex = K.number(stories_sub[1] % [_dec(a, 100), names[0], _dec(b, 100)], _dec(a - b, 100),
				"Take the part walked away from the whole path.", "%s − %s = %s km" % [_dec(a, 100), _dec(b, 100),
					_dec(a - b, 100)])
	ex.data = {"a": a, "b": b, "op": "+" if op == "+" else "-"}
	return ex


## "2.6 + ? = 4.15", "? − 1.25 = 3.6"
static func missing_decimal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := _tenths(rng, 11, 59) if level == 1 else _hundredths(rng, 101, 599)
	var b := _tenths(rng, 11, 49) if level < 3 else _hundredths(rng, 101, 499)
	var ex: Dictionary
	if level < 3:
		ex = K.number("%s + ? = %s" % [_dec(a, 100), _dec(a + b, 100)], _dec(b, 100),
			"What do you add to %s to make %s? Or take %s away from %s." % [_dec(a, 100), _dec(a + b, 100), _dec(a, 100),
				_dec(a + b, 100)], "%s − %s = %s" % [_dec(a + b, 100), _dec(a, 100), _dec(b, 100)])
	else:
		ex = K.number("? − %s = %s" % [_dec(b, 100), _dec(a, 100)], _dec(a + b, 100),
			"Undo the take away: add %s and %s." % [_dec(b, 100), _dec(a, 100)],
			"%s + %s = %s" % [_dec(a, 100), _dec(b, 100), _dec(a + b, 100)])
	ex.data = {"a": a, "b": b}
	return ex


## "What is 2.5 + 1.25?" with the lined-up answer and the not-lined-up one.
static func line_up(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var at := rng.randi_range(11, 99)                 # tenths
	var bh := rng.randi_range(101, 999)               # hundredths
	if at % 10 == 0:
		at += 1
	if bh % 10 == 0:
		bh += 3
	var right := at * 10 + bh
	var wrong := at + bh                              # 2.5 read as 25 hundredths
	var pic := {"kind": "column", "rows": [_dec(at * 10, 100), "+ " + _dec(bh, 100), "?"], "lines": [1]} if level == 1 else {}
	var ex := K.choice(rng, "What is %s + %s?" % [_dec(at * 10, 100), _dec(bh, 100)], _dec(right, 100), [_fixed(wrong * 10, 2),
		_dec(right + 100, 100)], "Line up the decimal points: tenths under tenths, hundredths under hundredths.",
		"%s = %s, and %s + %s = %s." % [_dec(at * 10, 100), _fixed(at * 100, 2), _fixed(at * 100, 2), _dec(bh, 100),
			_dec(right, 100)], pic)
	ex.data = {"a": at * 10, "b": bh}
	return ex


# --- Unit 6: multiply and divide decimals (5.NBT.7) --------------------------------------------------------------------

static func decimal_times_whole(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den := 100 if level == 2 else 10
	var a := rng.randi_range(1, 9) if level == 1 else (rng.randi_range(101, 999) if level == 2 else rng.randi_range(11, 99))
	if a % 10 == 0:
		a += 1
	var n := rng.randi_range(2, 9) if level < 3 else rng.randi_range(11, 25)
	var places := 2 if den == 100 else 1
	var ex := K.number("%s × %d = ?" % [_dec(a, den), n], _dec(a * n, den),
		"Multiply as if there were no point: %d × %d. Then put the point back." % [a, n],
		"%d × %d = %d, and %s has %d decimal place%s, so %s × %d = %s." % [a, n, a * n, _dec(a, den), places,
			"s" if places > 1 else "", _dec(a, den), n, _dec(a * n, den)])
	ex.data = {"a": a, "n": n, "den": den}
	return ex


static func decimal_times_decimal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(1, 9) if level == 1 else rng.randi_range(11, 99)
	var b := rng.randi_range(1, 9) if level < 3 else rng.randi_range(11, 99)
	if a % 10 == 0:
		a += 1
	if b % 10 == 0:
		b += 1
	var ex := K.number("%s × %s = ?" % [_dec(a, 10), _dec(b, 10)], _dec(a * b, 100),
		"Multiply %d × %d. Tenths times tenths make hundredths: the answer has 2 decimal places." % [a, b],
		"%d × %d = %d, so %s × %s = %s." % [a, b, a * b, _dec(a, 10), _dec(b, 10), _dec(a * b, 100)])
	ex.data = {"a": a, "b": b}
	return ex


static func decimal_divide(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den := 100 if level == 2 else 10
	var q := rng.randi_range(11, 99) if den == 10 else rng.randi_range(101, 399)
	if q % 10 == 0:
		q += 1
	var n := rng.randi_range(2, 9) if level < 3 else rng.randi_range(11, 20)
	var a := q * n
	var unit := "tenths" if den == 10 else "hundredths"
	var ex := K.number("%s ÷ %d = ?" % [_dec(a, den), n], _dec(q, den),
		"Think of %s as %d %s. Share them into %d equal groups." % [_dec(a, den), a, unit, n],
		"%d %s ÷ %d = %d %s, which is %s." % [a, unit, n, q, unit, _dec(q, den)])
	ex.data = {"a": a, "n": n, "den": den}
	return ex


static func divide_by_decimal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var q := 0
	var d := 0      # in hundredths
	match level:
		1:
			d = [50, 10, 20][rng.randi_range(0, 2)]
			var w := rng.randi_range(1, 9)
			q = int(w * 100.0 / d)
		2:
			d = rng.randi_range(2, 9) * 10
			q = rng.randi_range(2, 9)
		_:
			d = rng.randi_range(2, 9)
			q = rng.randi_range(2, 12)
	var a := q * d   # hundredths
	var scale := 10 if d % 10 == 0 else 100
	var ex := K.number("%s ÷ %s = ?" % [_dec(a, 100), _dec(d, 100)], q,
		"How many %ss fit in %s? Or multiply both numbers by %d first." % [_dec(d, 100), _dec(a, 100), scale],
		"%s ÷ %s is the same as %s ÷ %s = %d." % [_dec(a, 100), _dec(d, 100), K.fmt(int(a * scale / 100.0)),
			K.fmt(int(d * scale / 100.0)), q])
	ex.data = {"q": q, "d": d}
	return ex


## "36 × 14 = 504. So what is 3.6 × 1.4?"
static func place_the_point(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	for _t in 60:
		a = rng.randi_range(11, 99) if level < 3 else rng.randi_range(101, 999)
		b = rng.randi_range(2, 9) if level == 1 else rng.randi_range(11, 99)
		if a % 10 != 0 and b % 10 != 0 and (a * b) % 10 != 0:
			break
	var pa := rng.randi_range(1, 2)
	var pb := 0 if level == 1 else rng.randi_range(0, 1)
	var p := a * b
	var right := _point(p, pa + pb)
	var wrongs: Array = []
	for shift: int in [pa + pb - 1, pa + pb + 1, pa + pb + 2, 0]:
		var w := _point(p, shift)
		if shift >= 0 and w != right and not wrongs.has(w):
			wrongs.append(w)
	var ex := K.choice(rng, "%d × %d = %s. So what is %s × %s?" % [a, b, K.fmt(p), _point(a, pa), _point(b, pb)], right,
		wrongs.slice(0, 3), "Count the decimal places in both numbers. The answer has that many too.",
		"%s has %d decimal place%s and %s has %d: the answer has %d, so it is %s." % [_point(a, pa), pa, "s" if pa > 1 else "",
			_point(b, pb), pb, pa + pb, right])
	ex.data = {"a": a, "b": b, "pa": pa, "pb": pb}
	return ex


## "The square is cut into hundredths. What is 0.3 × 0.6?"
static func decimal_square(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(1, 9)
	var b := rng.randi_range(1, 9)
	var prompt := "The square is cut into hundredths. What is %s × %s?" % [_dec(a, 10), _dec(b, 10)]
	if level == 3:
		prompt = "What is %s × %s? The square can help." % [_dec(a, 10), _dec(b, 10)]
	var ex := K.number(prompt, _dec(a * b, 100), "Count the small squares shaded both ways.",
		"%d rows of %d make %d hundredths: %s × %s = %s." % [a, b, a * b, _dec(a, 10), _dec(b, 10), _dec(a * b, 100)],
		{"kind": "fraction_area", "cols": 10, "rows": 10, "shade_cols": b, "shade_rows": a, "w": _dec(b, 10),
			"h": _dec(a, 10)})
	ex.data = {"a": a, "b": b}
	return ex


# --- Unit 7: expressions and brackets (5.OA.1, 5.OA.2) -----------------------------------------------------------------

static func brackets(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var text := ""
	var value := 0
	var steps := ""
	match level:
		1:
			var a := rng.randi_range(2, 12)
			var b := rng.randi_range(2, 12)
			var c := rng.randi_range(2, 9)
			if rng.randf() < 0.5:
				text = "(%d + %d) × %d" % [a, b, c]
				value = (a + b) * c
				steps = "%d × %d = %d" % [a + b, c, value]
			else:
				var big := maxi(a, b) + 2
				text = "%d × (%d − %d)" % [c, big, mini(a, b)]
				value = c * (big - mini(a, b))
				steps = "%d × %d = %d" % [c, big - mini(a, b), value]
		2:
			if rng.randf() < 0.5:
				var a := rng.randi_range(8, 20)
				var b := rng.randi_range(1, a - 2)
				var c := rng.randi_range(1, 6)
				var d := rng.randi_range(1, 6)
				text = "(%d − %d) × (%d + %d)" % [a, b, c, d]
				value = (a - b) * (c + d)
				steps = "%d × %d = %d" % [a - b, c + d, value]
			else:
				var b := rng.randi_range(1, 6)
				var c := rng.randi_range(1, 6)
				var q := rng.randi_range(2, 9)
				text = "%d ÷ (%d + %d)" % [q * (b + c), b, c]
				value = q
				steps = "%d ÷ %d = %d" % [q * (b + c), b + c, q]
		_:
			var b := rng.randi_range(2, 6)
			var c := rng.randi_range(2, 5)
			var a := b * c + rng.randi_range(1, 9)
			var d := rng.randi_range(2, 6)
			if rng.randf() < 0.5:
				text = "(%d − %d × %d) × %d" % [a, b, c, d]
				value = (a - b * c) * d
				steps = "(%d − %d) × %d = %d × %d = %d" % [a, b * c, d, a - b * c, d, value]
			else:
				var e := rng.randi_range(1, 9)
				text = "%d × (%d + %d) − %d" % [d, b, c, e]
				value = d * (b + c) - e
				steps = "%d × %d − %d = %d − %d = %d" % [d, b + c, e, d * (b + c), e, value]
	var ex := K.number("%s = ?" % text, value, "Work out the brackets first." if level < 3 else
		"Brackets first; inside them, × comes before − and +.", "%s = %s" % [text, steps])
	ex.data = {"value": value}
	return ex


static func order_of_operations(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var text := ""
	var value := 0
	var steps := ""
	match level:
		1:
			var a := rng.randi_range(2, 20)
			var b := rng.randi_range(2, 9)
			var c := rng.randi_range(2, 9)
			if rng.randf() < 0.5:
				text = "%d + %d × %d" % [a, b, c]
				value = a + b * c
				steps = "%d + %d = %d" % [a, b * c, value]
			else:
				a = b * c + rng.randi_range(1, 20)
				text = "%d − %d × %d" % [a, b, c]
				value = a - b * c
				steps = "%d − %d = %d" % [a, b * c, value]
		2:
			var a := rng.randi_range(3, 12)
			var b := rng.randi_range(3, 9)
			var d := rng.randi_range(2, 6)
			var k := rng.randi_range(1, mini(9, int(a * b / float(d))))
			text = "%d × %d − %d ÷ %d" % [a, b, d * k, d]
			value = a * b - k
			steps = "%d − %d = %d" % [a * b, k, value]
		_:
			var c := rng.randi_range(2, 6)
			var q := rng.randi_range(2, 8)
			var d := rng.randi_range(2, 5)
			var a := rng.randi_range(2, 20)
			var e := rng.randi_range(1, a + q * d - 1)
			text = "%d + %d ÷ %d × %d − %d" % [a, q * c, c, d, e]
			value = a + q * d - e
			steps = "%d + %d × %d − %d = %d + %d − %d = %d" % [a, q, d, e, a, q * d, e, value]
	var ex := K.number("%s = ?" % text, value, "× and ÷ come before + and −, from left to right.", "%s = %s" % [text, steps])
	ex.data = {"value": value}
	return ex


## "Which expression means: add 8 and 7, then multiply by 2?"
static func words_to_expression(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kinds: Array = [[0, 1], [2, 3], [2, 4]][level - 1]
	var kind: int = kinds[rng.randi_range(0, 1)]
	var a := rng.randi_range(2, 12)
	var b := rng.randi_range(2, 12)
	var c := rng.randi_range(2, 9)
	var words := ""
	var right := ""
	var value := 0
	var wrongs: Array = []   # [text, value]
	match kind:
		0:
			words = "add %d and %d, then multiply by %d" % [a, b, c]
			right = "%d × (%d + %d)" % [c, a, b]
			value = c * (a + b)
			wrongs = [["%d × %d + %d" % [c, a, b], c * a + b], ["%d + %d × %d" % [a, b, c], a + b * c],
				["%d + %d + %d" % [a, b, c], a + b + c]]
		1:
			words = "multiply %d by %d, then add %d" % [a, b, c]
			right = "%d × %d + %d" % [a, b, c]
			value = a * b + c
			wrongs = [["%d × (%d + %d)" % [a, b, c], a * (b + c)], ["(%d + %d) × %d" % [a, c, b], (a + c) * b],
				["%d + %d × %d" % [a, b, c], a + b * c]]
		2:
			b = a + rng.randi_range(2, 12)
			words = "subtract %d from %d, then multiply by %d" % [a, b, c]
			right = "(%d − %d) × %d" % [b, a, c]
			value = (b - a) * c
			wrongs = [["%d − %d × %d" % [b, a, c], b - a * c], ["%d × %d − %d" % [c, b, a], c * b - a],
				["(%d − %d) + %d" % [b, a, c], b - a + c]]
		3:
			a = b * rng.randi_range(2, 9)
			words = "divide %d by %d, then add %d" % [a, b, c]
			right = "%d ÷ %d + %d" % [a, b, c]
			value = int(a / float(b)) + c
			wrongs = [["%d + %d ÷ %d" % [c, a, b], value], ["(%d + %d) × %d" % [a, c, b], (a + c) * b],
				["%d × %d + %d" % [a, b, c], a * b + c]]
			wrongs.remove_at(0)   # the same thing written the other way round: never a wrong choice
			wrongs.append(["%d − %d + %d" % [a, b, c], a - b + c])
		_:
			var q := rng.randi_range(2, 9)
			b = a + c * q
			words = "take %d away from %d, then divide by %d" % [a, b, c]
			right = "(%d − %d) ÷ %d" % [b, a, c]
			value = q
			wrongs = [["%d − %d × %d" % [b, a, c], b - a * c], ["%d − %d − %d" % [b, a, c], b - a - c],
				["(%d − %d) × %d" % [b, a, c], (b - a) * c]]
	var texts: Array = []
	for w: Array in wrongs:
		if int(w[1]) != value:
			texts.append(w[0])
	var ex := K.choice(rng, "Which expression means: %s?" % words, right, texts,
		"What is done first goes in brackets, unless × or ÷ already come first.", "%s = %d" % [right, value])
	ex.data = {"value": value}
	return ex


## "Where do the brackets go to make 2 + 3 × 4 = 20 true?"
static func bracket_place(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var b := rng.randi_range(2, 9)
	var c := rng.randi_range(2, 9)
	var plus := level == 1 or rng.randf() < 0.5
	if not plus and a <= b:
		a = b + rng.randi_range(1, 6)
	var op := "+" if plus else "−"
	var target := (a + b) * c if plus else (a - b) * c
	var plain := "%d %s %d × %d" % [a, op, b, c]
	var right := "(%d %s %d) × %d" % [a, op, b, c]
	var wrongs: Array = ["%d %s (%d × %d)" % [a, op, b, c]]
	if level == 3:
		var d := rng.randi_range(2, 9)
		target = (a + b) * c + d if plus else (a - b) * c + d
		plain = "%d %s %d × %d + %d" % [a, op, b, c, d]
		right = "(%d %s %d) × %d + %d" % [a, op, b, c, d]
		var others: Array = [["%d %s %d × (%d + %d)" % [a, op, b, c, d], a + b * (c + d) if plus else a - b * (c + d)],
			["(%d %s %d × %d) + %d" % [a, op, b, c, d], (a + b * c if plus else a - b * c) + d],
			["%d %s (%d × %d + %d)" % [a, op, b, c, d], a + b * c + d if plus else a - (b * c + d)]]
		wrongs = [plain]   # no brackets: always another number
		for o: Array in others:
			if int(o[1]) != target:
				wrongs.append(o[0])
	var ex := K.choice(rng, "Where do the brackets go to make  %s = %d  true?" % [plain, target], right, wrongs,
		"Try each one: work out the brackets first.", "%s = %d × %d%s = %d" % [right, a + b if plus else a - b, c,
			"" if level < 3 else " + %d" % (target - (a + b if plus else a - b) * c), target])
	ex.data = {"target": target}
	return ex


## "How does 4 × (253 + 17) compare with 253 + 17?" without working it out.
static func compare_expression(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(101, 999) if level < 3 else rng.randi_range(1001, 9999)
	var b := rng.randi_range(11, 99)
	var times := level == 1 or rng.randf() < 0.5
	var k: int = rng.randi_range(2, 9) if times else [2, 3, 4, 10][rng.randi_range(0, 3)]
	var sum := "%s + %d" % [K.fmt(a), b]
	var parts := {2: "half", 3: "a third", 4: "a quarter", 10: "a tenth"}
	var ex: Dictionary
	if times:
		ex = K.choice(rng, "Without working it out: how does %d × (%s) compare with %s?" % [k, sum, sum], "%d times as large" % k,
			["%d more" % k, "the same", "%d less" % k], "%d × (…) means %d lots of the same sum." % [k, k],
			"%d × (%s) is %d lots of %s, so it is %d times as large." % [k, sum, k, sum, k])
	else:
		ex = K.choice(rng, "Without working it out: how does (%s) ÷ %d compare with %s?" % [sum, k, sum], "%s as large" % parts[k],
			["%d times as large" % k, "%d less" % k, "the same"], "(…) ÷ %d shares the same sum into %d equal parts." % [k, k],
			"Dividing by %d makes one of %d equal parts: %s as large." % [k, k, parts[k]])
	ex.data = {"k": k, "op": "×" if times else "÷"}
	return ex


static func expression_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := NAMES.duplicate()
	K.shuffle(rng, names)
	var kind := rng.randi_range(0, 1) if level == 1 else rng.randi_range(0, 3)
	var prompt := ""
	var expr := ""
	var value := 0
	match kind:
		0:
			var a := rng.randi_range(3, 9)
			var b := rng.randi_range(4, 12)
			var c := rng.randi_range(2, 9)
			prompt = "%s buys %d packs of %d seeds and finds %d more seeds. How many seeds does %s have?" % [names[0], a, b, c,
				names[0]]
			expr = "%d × %d + %d" % [a, b, c]
			value = a * b + c
		1:
			var a := rng.randi_range(20, 90)
			var b := rng.randi_range(2, 9)
			var c := rng.randi_range(2, 9)
			prompt = "%s has %d gold and earns %d gold a day for %d days. How much gold does %s have then?" % [names[0], a, b, c,
				names[0]]
			expr = "%d + %d × %d" % [a, b, c]
			value = a + b * c
		2:
			var a := rng.randi_range(3, 9)
			var b := rng.randi_range(6, 15)
			var c := rng.randi_range(1, b - 2)
			prompt = "%s builds %d towers of %d blocks, then takes %d blocks off each tower. How many blocks are left?" % [
				names[0], a, b, c]
			expr = "%d × (%d − %d)" % [a, b, c]
			value = a * (b - c)
		_:
			var b := rng.randi_range(2, 6)
			var q := rng.randi_range(4, 12)
			var c := rng.randi_range(1, q - 1)
			prompt = "%s shares %d apples equally among %d buddies. Each buddy eats %d. How many apples does each buddy have left?" % [
				names[0], b * q, b, c]
			expr = "%d ÷ %d − %d" % [b * q, b, c]
			value = q - c
	var ex := K.number(prompt, value, "Write it as an expression first: %s." % expr, "%s = %d" % [expr, value])
	ex.data = {"expr": expr, "value": value}
	return ex


# --- Helpers -------------------------------------------------------------------------------------------------------

## A decimal from whole parts of `den` (1000: thousandths): 3450 -> "3.45", 345000 -> "345", 5 -> "0.005".
static func _dec(t: int, den: int = 1000) -> String:
	var places := str(den).length() - 1
	var whole := int(t / float(den))
	var part := t - whole * den
	var text := K.fmt(whole)
	if part == 0:
		return text
	var digits := str(part).lpad(places, "0")
	while digits.ends_with("0"):
		digits = digits.left(-1)
	return text + "." + digits


## Thousandths with exactly `places` decimal places: (4000, 1) -> "4.0", (3100, 2) -> "3.10".
static func _fixed(t: int, places: int) -> String:
	var whole := int(t / 1000.0)
	if places == 0:
		return K.fmt(whole)
	var part := int((t - whole * 1000) / float(K.pow10(3 - places)))
	return "%s.%s" % [K.fmt(whole), str(part).lpad(places, "0")]


## w and n/den written with `den`'s places: (4, 26, 10000) -> "4.0026".
static func _dec_text(w: int, n: int, den: int) -> String:
	return "%d.%s" % [w, str(n).lpad(str(den).length() - 1, "0")]


## A whole number with `places` decimal places put in: (504, 2) -> "5.04".
static func _point(n: int, places: int) -> String:
	if places == 0:
		return K.fmt(n)
	var s := str(n).lpad(places + 1, "0")
	return s.left(s.length() - places) + "." + s.right(places)


static func _sup(k: int) -> String:
	var out := ""
	for ch in str(k):
		out += SUP[int(ch)]
	return out


static func _places_word(n: int) -> String:
	return "1 place" if n == 1 else "%d places" % n


## Round to the first digit's place: 487 -> 500, 32 -> 30.
static func _lead(n: int) -> int:
	var p := K.pow10(str(n).length() - 1)
	return int((n + p * 0.5) / p) * p


## A number's non-zero place parts: 342 -> [300, 40, 2].
static func _parts(n: int) -> Array:
	var out: Array = []
	var s := str(n)
	for i in s.length():
		var d := int(s[i])
		if d > 0:
			out.append(d * K.pow10(s.length() - 1 - i))
	return out


## A tenths value in hundredths (11 -> 110 = 1.1), never a whole number.
static func _tenths(rng: RandomNumberGenerator, lo: int, hi: int) -> int:
	var t := rng.randi_range(lo, maxi(lo, hi))
	if t % 10 == 0:
		t += 1
	return t * 10


## Hundredths with two places (345 = 3.45), never ending in 0.
static func _hundredths(rng: RandomNumberGenerator, lo: int, hi: int) -> int:
	var h := rng.randi_range(lo, maxi(lo, hi))
	if h % 10 == 0:
		h += 1
	return h


static func _multiply_hint(a: int, b: int) -> String:
	if b < 10:
		return "Multiply the ones, then the tens, then the hundreds, and carry when you need to."
	return "Split %d into %d + %d. Multiply %s by each part, then add." % [b, int(b / 10.0) * 10, b % 10, K.fmt(a)]


static func _multiply_steps(a: int, b: int) -> String:
	if b < 10:
		var parts := _parts(a)
		var bits: Array[String] = []
		for p: int in parts:
			bits.append(K.fmt(p * b))
		return "%s × %d = %s = %s" % [K.fmt(a), b, " + ".join(bits), K.fmt(a * b)]
	var t := int(b / 10.0) * 10
	var o := b % 10
	if o == 0:
		return "%s × %d = %s" % [K.fmt(a), b, K.fmt(a * b)]
	return "%s × %d = %s and %s × %d = %s. %s + %s = %s." % [K.fmt(a), o, K.fmt(a * o), K.fmt(a), t, K.fmt(a * t),
		K.fmt(a * o), K.fmt(a * t), K.fmt(a * b)]
