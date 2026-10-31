class_name DiscoveryPlays
extends RefCounted
## Owner #132 (W1), stage 2, under owner #133 ("no one will start reading") and #134 ("future lessons, not texts"):
## what a discovery crystal plays. Since Play G0 merged, first G0's short round in its place (`pick`'s `place`: the
## child's own unit when it plays without reading, PlayHost.plays, else a unit of the grade that does; the Academy's
## doors: `subject_unit`). Only where nothing in the grade plays, this file's own number play in the world, where the
## number sense is the move (it duplicates G0's Make it and Order it, which are preferred):
## - **MAKE**: the crystal shows a number; gems of place values (or coins, tenths, negatives) float round it; the child
##   takes gems until the crystal shows exactly that number. A gem that would go past it (or, with negatives, farther
##   from it) bounces off: the world answers, the number stays.
## - **ORDER**: number gems float round the crystal; the child takes them smallest first (big numbers, unit fractions,
##   decimals, negatives, rationals, irrationals); a wrong one bounces off.
## Each crystal is PER_CRYSTAL challenges (about a minute). From the child's own learning (`pick`): a review due first,
## else the next unit of the grade (MasteryRules, the School's order); when that unit has no real play yet (no deep game,
## none of these), a real-play challenge from the child's grade instead, and the unit is reported (`wanted`, `own`
## false: its "play debt"). Never a written question: on screen only numbers and signs; the line is spoken.
## The lead's switch when deep games and Play G0's mechanics merge: `play_for` (one marked call).

const PER_CRYSTAL := 3
## The minus sign shown (a real minus, not a hyphen).
const MINUS := "−"

## Each play: MAKE's gems (whole numbers in 1/scale units), its targets' range and digits; ORDER's maker.
const SETS := {
	"place_4digit": {"kind": "make", "gems": [1000, 100, 10, 1], "scale": 1, "digits": 4},
	"place_big": {"kind": "make", "gems": [100000, 10000, 1000, 100, 10, 1], "scale": 1, "digits": 6},
	"coins": {"kind": "make", "gems": [50, 20, 10, 5, 2, 1], "scale": 1, "coins": true},
	"decimal_hundredths": {"kind": "make", "gems": [100, 10, 1], "scale": 100, "digits": 3},
	"decimal_thousandths": {"kind": "make", "gems": [1000, 100, 10, 1], "scale": 1000, "digits": 4},
	"integers": {"kind": "make", "gems": [10, 1, -1, -10], "scale": 1, "signed": true, "from": false},
	"integers_from": {"kind": "make", "gems": [10, 1, -1, -10], "scale": 1, "signed": true, "from": true},
	"order_big": {"kind": "order", "maker": "big"},
	"order_unit_fractions": {"kind": "order", "maker": "unit_fractions"},
	"order_decimals": {"kind": "order", "maker": "decimals"},
	"order_negatives": {"kind": "order", "maker": "negatives"},
	"order_rationals": {"kind": "order", "maker": "rationals"},
	"order_irrationals": {"kind": "order", "maker": "irrationals"},
}

## The units whose own concept these plays are (their standards: place value, money, comparing fractions, decimals,
## integers, rational and irrational numbers). Every other unit has no crystal play yet.
const UNIT_PLAYS := {
	"g3.maths.numbers_to_10000": ["place_4digit"],   # 3.NBT.1: place value to 10,000
	"g3.maths.money": ["coins"],   # making amounts with coins
	"g3.maths.equivalent_fractions": ["order_unit_fractions"],   # 3.NF.3d: comparing fractions
	"g4.maths.big_numbers": ["place_big"],   # 4.NBT.1-2: place value to a million
	"g4.maths.compare_round": ["order_big"],   # 4.NBT.2: comparing big numbers
	"g4.maths.decimals": ["decimal_hundredths", "order_decimals"],   # 4.NF.6-7: tenths, hundredths, comparing
	"g5.maths.decimal_place_value": ["decimal_thousandths", "order_decimals"],   # 5.NBT.3
	"g6.maths.negatives": ["integers", "order_negatives"],   # 6.NS.5-7
	"g7.maths.integers_add": ["integers_from"],   # 7.NS.1: adding integers
	"g7.maths.rational_numbers": ["order_rationals"],   # 7.NS.2d: rational numbers as decimals, ordered
	"g8.maths.irrational": ["order_irrationals"],   # 8.NS.2: comparing irrational numbers by their size
}

const ORDER_SAY := "Smallest first!"


## Owner #132 (W1) → deep games and Play G0: THE CALL THE LEAD SWITCHES as real play arrives for more units (a deep
## game's level, G0's action mechanics). Today: this file's plays for the units in UNIT_PLAYS, else none ([]).
static func play_for(unit_id: String) -> Array:
	return UNIT_PLAYS.get(unit_id, [])


## The grade the child is in (the first grade until one is chosen).
static func grade_of(profile: ProfileData) -> int:
	return profile.school.grade if SchoolData.GRADES.has(profile.school.grade) else SchoolData.GRADES[0]


## The units of grade `g` a crystal can play, in the School's order.
static func grade_units(g: int) -> Array[String]:
	var out: Array[String] = []
	for id: String in UNIT_PLAYS:
		if id.begins_with("g%d." % g):
			out.append(id)
	return out


## Play G0 (merged): a unit plays in G0's place when enough of it plays without reading (PlayHost.plays: PlayReadless).
static func g0_plays(unit_id: String) -> bool:
	return unit_id != "" and PlayHost.plays(Curriculum.content(unit_id))


## What a crystal plays now for `profile` on `today` (`seed` varies it). On Play G0's foundation first (`plays`: (unit
## id) -> bool, G0's own test by default): {place: true, unit, wanted, own, grade}: G0's short round on the unit the
## child is on (`wanted`: a review due, else the next) when it plays without reading (`own`), else on a unit of the
## grade that does (`wanted` kept as play debt). Only where nothing in the grade plays: {place: false, unit, wanted, own,
## kind, grade, challenges}: this file's own number play in the world (MAKE, ORDER).
static func pick(profile: ProfileData, today: int, seed: int, plays: Callable = Callable()) -> Dictionary:
	var can := plays if plays.is_valid() else g0_plays
	var g := grade_of(profile)
	var wanted := _wanted_unit(profile, g, today)
	if wanted != "" and bool(can.call(wanted)):
		return {"place": true, "unit": wanted, "wanted": wanted, "own": true, "grade": g}
	var other := _grade_playable(profile, g, today, can)
	if other != "":
		return {"place": true, "unit": other, "wanted": wanted, "own": false, "grade": g}
	var own := not play_for(wanted).is_empty()
	var unit := wanted if own else _grade_unit(profile, g, today)
	var kinds: Array = play_for(unit)
	var kind := str(kinds[posmod(seed, kinds.size())])
	return {"place": false, "unit": unit, "wanted": wanted, "own": own, "kind": kind, "grade": g,
		"challenges": challenges(kind, seed)}


## The unit of `subject` (in the child's grade) an Academy door plays: a review due that plays, else the first not
## mastered that plays, else the first that plays; "" when none plays without reading yet (the door says "coming soon").
static func subject_unit(profile: ProfileData, subject: String, today: int, plays: Callable = Callable()) -> String:
	var can := plays if plays.is_valid() else g0_plays
	var ids := _written(grade_of(profile), subject)
	for id: String in ids:
		if MasteryRules.review_due(profile.school.progress(id), today) and bool(can.call(id)):
			return id
	for id: String in ids:
		if MasteryRules.stars(profile.school.progress(id)) < MasteryRules.MASTERED and bool(can.call(id)):
			return id
	for id: String in ids:
		if bool(can.call(id)):
			return id
	return ""


## A unit of the grade that plays: a review due, else the first not mastered, else the first ("" for none).
static func _grade_playable(profile: ProfileData, g: int, today: int, can: Callable) -> String:
	var ids := _written(g, "")
	for id: String in ids:
		if MasteryRules.review_due(profile.school.progress(id), today) and bool(can.call(id)):
			return id
	for id: String in ids:
		if MasteryRules.stars(profile.school.progress(id)) < MasteryRules.MASTERED and bool(can.call(id)):
			return id
	for id: String in ids:
		if bool(can.call(id)):
			return id
	return ""


## The grade's written units (no Explorer lessons), in the School's order; one subject's, or all ("").
static func _written(g: int, subject: String) -> Array[String]:
	var out: Array[String] = []
	for sub: Dictionary in Curriculum.subjects(g):
		if subject != "" and str(sub.id) != subject:
			continue
		for u: Dictionary in Curriculum.units(g, str(sub.id)):
			if Curriculum.has_content(str(u.id)) and not SpendRules.is_bonus(u):
				out.append(str(u.id))
	return out


## A review due (the first in the School's order), else the next unit not mastered; "" when every unit is mastered.
static func _wanted_unit(profile: ProfileData, g: int, today: int) -> String:
	var written := _written(g, "")
	for id: String in written:
		if MasteryRules.review_due(profile.school.progress(id), today):
			return id
	for id: String in written:
		if MasteryRules.stars(profile.school.progress(id)) < MasteryRules.MASTERED:
			return id
	return ""


## The grade's own real-play unit: a review due, else the first not mastered, else one by the day.
static func _grade_unit(profile: ProfileData, g: int, today: int) -> String:
	var units := grade_units(g)
	for id: String in units:
		if MasteryRules.review_due(profile.school.progress(id), today):
			return id
	for id: String in units:
		if MasteryRules.stars(profile.school.progress(id)) < MasteryRules.MASTERED:
			return id
	return units[posmod(today, units.size())]


## PER_CRYSTAL challenges of play `kind` (the same seed, the same challenges). Each: {kind, shown (the numbers on the
## crystal), say (the spoken line), labels (the gems' numbers)}; MAKE also {start, target, gems, signed, scale}; ORDER
## {values}.
static func challenges(kind: String, seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([kind, seed])
	var spec: Dictionary = SETS[kind]
	var out: Array[Dictionary] = []
	var guard := 0
	while out.size() < PER_CRYSTAL and guard < 50:
		guard += 1
		var c := _make(spec, rng) if spec.kind == "make" else _order(str(spec.maker), rng)
		var dup := false
		for o: Dictionary in out:
			dup = dup or str(o.shown) == str(c.shown) and o.get("labels") == c.get("labels")
		if not dup:
			out.append(c)
	return out


# --- MAKE ------------------------------------------------------------------------------------------------------------

static func _make(spec: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var scale := int(spec.scale)
	var gems: Array = spec.gems
	var start := 0
	var target := 0
	if bool(spec.get("signed", false)):
		if bool(spec.get("from", false)):
			start = rng.randi_range(-20, 20)
		var d := rng.randi_range(11, 40) * (1 if rng.randf() < 0.5 else -1)
		if not bool(spec.get("from", false)) and d > 0:
			d = -d   # from zero: the negatives are the new idea (6.NS)
		target = start + d
	elif bool(spec.get("coins", false)):
		target = rng.randi_range(13, 99)
	else:
		var n := int(spec.digits)
		for i in n:
			var lo := 1 if i == 0 else 0
			target = target * 10 + rng.randi_range(lo, 4 if i == 0 else 3)
	var shown := number(target, scale)
	var say := "Make %s!" % spoken(target, scale)
	if bool(spec.get("coins", false)):
		say = "Make %s with coins!" % spoken(target, scale)
	elif start != 0:
		say = "Start at %s. Make %s!" % [spoken(start, scale), spoken(target, scale)]
	var labels: Array[String] = []
	for v: int in gems:
		labels.append(("+" if bool(spec.get("signed", false)) and v > 0 else "") + number(v, scale))
	return {"kind": "make", "start": start, "target": target, "gems": gems.duplicate(), "scale": scale,
		"signed": bool(spec.get("signed", false)), "coins": bool(spec.get("coins", false)), "shown": shown, "say": say,
		"labels": labels}


# --- ORDER -----------------------------------------------------------------------------------------------------------

static func _order(maker: String, rng: RandomNumberGenerator) -> Dictionary:
	var values: Array[float] = []
	var labels: Array[String] = []
	match maker:
		"big":
			var base := rng.randi_range(10, 98) * 1000 + rng.randi_range(0, 999)
			var pool: Array[int] = [base]
			var digits := str(base)
			var tries := 0
			while pool.size() < 4 and tries < 40:
				tries += 1
				var d := digits.split("")
				var i := rng.randi_range(1, d.size() - 1)
				var j := rng.randi_range(1, d.size() - 1)
				var t: String = d[i]
				d[i] = d[j]
				d[j] = t
				if rng.randf() < 0.4:
					d[rng.randi_range(1, d.size() - 1)] = str(rng.randi_range(0, 9))
				var v := int("".join(d))
				if not pool.has(v):
					pool.append(v)
			var step := 1010
			while pool.size() < 4:
				if not pool.has(base + step):
					pool.append(base + step)
				step += 1010
			for v in pool:
				values.append(float(v))
				labels.append(number(v, 1))
		"unit_fractions":
			var dens: Array = [2, 3, 4, 5, 6, 8, 10, 12]
			_shuffle(dens, rng)
			for d: int in dens.slice(0, 4):
				values.append(1.0 / d)
				labels.append("1/%d" % d)
		"decimals":
			var a := rng.randi_range(2, 8)
			var b := rng.randi_range(1, 9)
			while b == a:
				b = rng.randi_range(1, 9)
			for v: int in [a * 100, a * 100 + b * 10, b * 100, a * 100 + b]:
				values.append(v / 1000.0)
				labels.append(number(v, 1000))
		"negatives":
			var pool: Array[int] = []
			while pool.size() < 4:
				var v := rng.randi_range(-15, 12)
				if pool.size() < 2 and v >= 0:
					v = -v - 1   # at least two below zero
				if not pool.has(v):
					pool.append(v)
			for v in pool:
				values.append(float(v))
				labels.append(number(v, 1))
		"rationals":
			var pool := [[-3, 4], [-1, 2], [-1, 5], [3, 10], [2, 5], [13, 20], [3, 4], [7, 10], [-2, 5], [1, 8], [5, 8],
				[-7, 10], [9, 20], [1, 4]]
			_shuffle(pool, rng)
			var taken := {}
			for pq: Array in pool:
				if values.size() >= 4:
					break
				var v := float(pq[0]) / float(pq[1])
				if taken.has(snappedf(v, 0.001)):
					continue
				taken[snappedf(v, 0.001)] = true
				values.append(v)
				var as_decimal := rng.randf() < 0.5 and int(pq[1]) in [2, 4, 5, 10, 20]
				labels.append(number(roundi(v * 100.0), 100) if as_decimal else
					(MINUS if v < 0 else "") + "%d/%d" % [absi(int(pq[0])), int(pq[1])])
		"irrationals":
			var pool := [[2, "√2"], [3, "√3"], [5, "√5"], [6, "√6"], [7, "√7"], [10, "√10"], [1.5, "1.5"],
				[1.6, "1.6"], [1.8, "1.8"], [2.2, "2.2"], [2.5, "2.5"], [3.0, "3"], [2.0, "2"]]
			_shuffle(pool, rng)
			for e: Array in pool:
				if values.size() >= 4:
					break
				var root := str(e[1]).begins_with("√")
				var v := sqrt(float(e[0])) if root else float(e[0])
				var close := false
				for w in values:
					close = close or absf(w - v) < 0.05
				if close:
					continue
				values.append(v)
				labels.append(str(e[1]))
	# shown in a random order (never already sorted)
	var order: Array = range(values.size())
	_shuffle(order, rng)
	var vals: Array[float] = []
	var labs: Array[String] = []
	for i: int in order:
		vals.append(values[i])
		labs.append(labels[i])
	if _sorted(vals):
		vals.reverse()
		labs.reverse()
	return {"kind": "order", "values": vals, "labels": labs, "shown": "", "say": ORDER_SAY}


static func _sorted(v: Array[float]) -> bool:
	for i in range(1, v.size()):
		if v[i] < v[i - 1]:
			return false
	return true


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


# --- Numbers as a child sees and hears them -------------------------------------------------------------------------

## `v` in 1/`scale` units as shown: 1,000s grouped with commas, a real minus, decimals without trailing zeros.
static func number(v: int, scale: int) -> String:
	var neg := v < 0
	var a := absi(v)
	var whole := a / scale
	var frac := a % scale
	var s := _grouped(whole)
	if scale > 1 and frac != 0:
		var places := str(scale).length() - 1
		var f := str(frac).pad_zeros(places)
		while f.ends_with("0"):
			f = f.substr(0, f.length() - 1)
		s += "." + f
	return (MINUS if neg else "") + s


## As the voice says it ("minus 23", "2.35": the device's voice reads digits and points).
static func spoken(v: int, scale: int) -> String:
	return number(v, scale).replace(MINUS, "minus ").replace(",", "")


static func _grouped(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
