class_name G4HealthGen
extends RefCounted
## Owner #70 and #73 (research §6.4): grade 4 health and PE, design and technology, and projects generators: finding
## space in an invasion game, jumps and relay times to measure and improve, circuit training and the parts of fitness,
## food labels' traffic lights and the sugar in drinks, an orienteering map, circuits that light (or not), wheels that
## roll, fabric to cut for a bag, triangles in a frame, bread for more loaves and its baking times, the food group a meal
## is missing, a user survey, materials for a job, inventions in time order, a museum's objects by civilisation, a river
## town's fields, and a tune's shape by ear. SchoolGen "g4w.<name>", `static func <name>(rng: RandomNumberGenerator,
## level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs,
## for tests/unit/test_g4_health_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi"]
const TAGS: Array[String] = ["A", "B", "C"]

# --- Health and PE: attack and defend (g4.health_pe.invasion_games) ------------------------------------------------

const PITCH := Vector2i(12, 7)


## Players on a pitch seen from above (blue circles: your team, red squares: the other team; the ball with one of
## yours): "Which teammate is in the most space?" Level 1: two teammates and two others; level 2: three and three; level
## 3: three teammates and four others, or "Which teammate is marked most closely?". Built so the answer is clear: the
## free teammate's nearest other player is 3 squares or more away, every other teammate has one within 1.5 squares.
static func find_space(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var mates := 2 if level == 1 else 3
	var others: int = [2, 3, 4][level - 1]
	var marked := level == 3 and rng.randf() < 0.4
	var answer := rng.randi_range(0, mates - 1)
	for _try in 400:
		var carrier := Vector2(rng.randi_range(0, 2), rng.randi_range(2, 4)) + Vector2(0.5, 0.5)
		var taken: Array[Vector2] = [carrier]
		var mate_at: Array[Vector2] = []
		var ok := true
		for i in mates:
			var p := _free_square(rng, taken, 3, 11, 2.0)
			if p == Vector2(-1, -1):
				ok = false
				break
			mate_at.append(p)
			taken.append(p)
		if not ok:
			continue
		var other_at: Array[Vector2] = []
		# the special one: for "space" the answer is free and each other teammate is marked; for "marked" only the answer
		for i in mates:
			if (i != answer) != marked:
				var near := _next_to(rng, mate_at[i], taken)
				if near == Vector2(-1, -1):
					ok = false
					break
				other_at.append(near)
				taken.append(near)
		if not ok or other_at.size() > others:
			continue
		while other_at.size() < others:
			var p := _free_square(rng, taken, 1, 11, 1.0)
			if p == Vector2(-1, -1):
				ok = false
				break
			other_at.append(p)
			taken.append(p)
		if not ok:
			continue
		var gaps: Array[float] = []
		for m in mate_at:
			gaps.append(_nearest(m, other_at))
		var clear := true
		for i in mates:
			if i == answer:
				continue
			if marked:
				clear = clear and gaps[i] >= 3.0
			else:
				clear = clear and gaps[i] <= 1.5
		clear = clear and (gaps[answer] <= 1.5 if marked else gaps[answer] >= 3.0)
		if not clear:
			continue
		var players: Array = [[carrier.x, carrier.y, "a"]]
		for i in mates:
			players.append([mate_at[i].x, mate_at[i].y, "a", TAGS[i]])
		for o in other_at:
			players.append([o.x, o.y, "d"])
		var tag := TAGS[answer]
		var ex := {"type": "choice", "choices": TAGS.slice(0, mates), "answer": answer,
			"picture": {"kind": "pitch", "cols": PITCH.x, "rows": PITCH.y, "players": players, "ball": 0}}
		if marked:
			ex.prompt = "Your team is blue and has the ball. Which of your teammates is marked most closely by the other team?"
			ex.hint = "Marking means staying very close to a player. Find the red square nearest to a blue letter."
			ex.explain = "%s: a red player is right beside %s, so a pass to %s could be stopped. The others have more space." % [
				tag, tag, tag]
		else:
			ex.prompt = "Your team is blue and has the ball. Which teammate is in the most space to pass to?"
			ex.hint = "Space means no red player close by. Look round each blue letter for red squares."
			ex.explain = "%s: the nearest red player is about %d squares away. The other teammates each have a red player right beside them." % [
				tag, int(round(gaps[answer]))]
		ex.data = {"players": players, "ask": "marked" if marked else "space"}
		return ex
	return {}


# --- Health and PE: athletics (g4.health_pe.athletics) -------------------------------------------------------------

## A long jump in metres and centimetres. Level 1: "2 m 35 cm is how many centimetres?"; level 2: how much further than
## last week; level 3: a triple jump's hop, step and jump added up.
static func jump_measure(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	if level == 1:
		var cm := rng.randi_range(120, 340)
		while cm % 100 == 0:
			cm = rng.randi_range(120, 340)
		ex = K.number("%s's long jump measured %s. How many centimetres is that?" % [who, _m_cm(cm)], str(cm),
			"1 m is 100 cm. Change the metres into centimetres, then add the rest.",
			"%d m is %d cm, and %d cm + %d cm = %d cm." % [cm / 100, cm / 100 * 100, cm / 100 * 100, cm % 100, cm])
		ex.data = {"jumps": [cm], "ask": "cm"}
	elif level == 2:
		var before := rng.randi_range(150, 300)
		var better := rng.randi_range(3, 40)
		var now := before + better
		ex = K.number("%s jumped %s last week and %s today. How many centimetres further is today's jump?" % [who,
			_m_cm(before), _m_cm(now)], str(better),
			"Change both jumps into centimetres, then take the smaller from the bigger.",
			"%d cm today and %d cm last week: %d − %d = %d cm further. A new personal best!" % [now, before, now, before,
				better])
		ex.data = {"jumps": [before, now], "ask": "further"}
	else:
		var parts: Array[int] = [rng.randi_range(150, 260), rng.randi_range(120, 220), rng.randi_range(150, 260)]
		var total := parts[0] + parts[1] + parts[2]
		ex = K.number("%s's triple jump: the hop was %s, the step %s and the jump %s. How far is that altogether, in centimetres?" % [
			who, _m_cm(parts[0]), _m_cm(parts[1]), _m_cm(parts[2])], str(total),
			"Change each part into centimetres, then add all three.",
			"%d + %d + %d = %d cm, which is %s." % [parts[0], parts[1], parts[2], total, _m_cm(total)])
		ex.data = {"jumps": parts, "ask": "total"}
	return ex


## A relay team's time. Level 1: two legs added; level 2: four legs; level 3: how many seconds faster than last week.
static func relay_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var legs: Array[int] = []
	for i in (2 if level == 1 else 4):
		legs.append(rng.randi_range(12, 19))
	var total := 0
	for t in legs:
		total += t
	var sums := " + ".join(legs.map(func(t: int) -> String: return str(t)))
	var ex: Dictionary
	if level < 3:
		ex = K.number("In a relay, the runners' legs took %s seconds. What was the team's time, in seconds?" % _and(legs),
			str(total), "A relay team's time is every runner's time added together.",
			"%s = %d seconds." % [sums, total])
		ex.data = {"legs": legs}
	else:
		var faster := rng.randi_range(2, 9)
		ex = K.number("Last week the relay team took %d seconds. This week the legs took %s seconds. How many seconds faster were they?" % [
			total + faster, _and(legs)], str(faster), "Add this week's legs, then find the difference from last week.",
			"This week: %s = %d seconds. %d − %d = %d seconds faster." % [sums, total, total + faster, total, faster])
		ex.data = {"legs": legs, "last": total + faster}
	return ex


# --- Health and PE: parts of fitness (g4.health_pe.fitness_parts) --------------------------------------------------

## Circuit training: stations, seconds of work at each, rests between. Level 1: the work only; level 2: with the rests
## between stations; level 3: rounds of the circuit, in whole minutes.
static func circuit_training(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		for _try in 100:
			var n := rng.randi_range(4, 8)
			var work: int = [20, 30, 40, 45][rng.randi_range(0, 3)]
			var rounds := rng.randi_range(2, 3)
			var secs := n * work * rounds
			if secs % 60 != 0:
				continue
			ex = K.number("A circuit has %d stations of %d seconds each. You go round it %d times. How many minutes of exercise is that?" % [
				n, work, rounds], str(secs / 60), "Find the seconds for one round, times by the rounds, then share by 60.",
				"One round: %d × %d = %d seconds. %d rounds: %d × %d = %d seconds, and %d ÷ 60 = %d minutes." % [n, work,
					n * work, rounds, n * work, rounds, secs, secs, secs / 60])
			ex.data = {"stations": n, "work": work, "rest": 0, "rounds": rounds, "ask": "minutes"}
			return ex
	var n := rng.randi_range(4, 8)
	var work: int = [20, 30, 40][rng.randi_range(0, 2)]
	if level == 1:
		ex = K.number("A circuit has %d stations. You exercise for %d seconds at each one. How many seconds of exercise is that?" % [
			n, work], str(n * work), "The same time at every station: multiply.",
			"%d stations × %d seconds = %d seconds." % [n, work, n * work])
		ex.data = {"stations": n, "work": work, "rest": 0, "rounds": 1, "ask": "seconds"}
		return ex
	var rest: int = [10, 15, 20][rng.randi_range(0, 2)]
	var total := n * work + (n - 1) * rest
	ex = K.number("%d stations of %d seconds, with a %d second rest between one station and the next. How many seconds from start to finish?" % [
		n, work, rest], str(total), "Count the rests: there is one fewer rest than stations.",
		"Work: %d × %d = %d. Rests: %d × %d = %d. %d + %d = %d seconds." % [n, work, n * work, n - 1, rest, (n - 1) * rest,
			n * work, (n - 1) * rest, total])
	ex.data = {"stations": n, "work": work, "rest": rest, "rounds": 1, "ask": "seconds"}
	return ex


## The part of fitness each exercise builds most.
const FITNESS := {
	"stamina": ["a long, steady jog", "swimming lengths", "a long bike ride", "skipping for 5 minutes"],
	"strength": ["press-ups", "squats", "a plank", "climbing a rope", "a tug of war"],
	"speed": ["a 30 m sprint", "a sprint relay", "sprint starts", "a race to a cone"],
	"flexibility": ["touching your toes", "a butterfly stretch", "a calf stretch", "yoga stretches"],
}


## "Sort the exercises by the part of fitness they build most." Level 1: 2 parts, 4 exercises; level 2: 3 and 5; level
## 3: 3 and 6.
static func fitness_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var groups := _pick(rng, FITNESS.keys(), 2 if level == 1 else 3)
	var count: int = [4, 5, 6][level - 1]
	var items: Array = []
	var answer: Array = []
	var order: Array = groups.duplicate()
	while order.size() < count:
		order.append(groups[rng.randi_range(0, groups.size() - 1)])
	var used := {}
	for g: String in order:
		var pool: Array = (FITNESS[g] as Array).filter(func(e: String) -> bool: return not used.has(e))
		var e: String = pool[rng.randi_range(0, pool.size() - 1)]
		used[e] = true
		items.append(e)
		answer.append(groups.find(g))
	var idx: Array = range(items.size())
	K.shuffle(rng, idx)
	var shown: Array = []
	var shown_answer: Array = []
	for i: int in idx:
		shown.append(items[i])
		shown_answer.append(answer[i])
	var parts: Array[String] = []
	for gi in groups.size():
		var in_group: Array[String] = []
		for i in shown.size():
			if int(shown_answer[i]) == gi:
				in_group.append(str(shown[i]))
		parts.append("%s: %s." % [str(groups[gi]).capitalize(), ", ".join(in_group)])
	var ex := {"type": "sort", "prompt": "Which part of fitness does each exercise build most?", "groups": groups,
		"items": shown, "answer": shown_answer,
		"hint": "Stamina is keeping going; strength is pushing, pulling and lifting; speed is going fast; flexibility is stretching.",
		"explain": " ".join(parts)}
	ex.data = {"items": shown, "groups": groups}
	return ex


# --- Health and PE: reading food labels (g4.health_pe.food_labels) ------------------------------------------------

## The UK's traffic lights for food, per 100 g: [low if at most, high if more than] (grams).
const LIGHTS := {"Fat": [3.0, 17.5], "Saturates": [1.5, 5.0], "Sugars": [5.0, 22.5], "Salt": [0.3, 1.5]}
## Amounts drawn well inside each level (tenths of a gram): nutrient -> {level: [from, to]}.
const RANGES := {"Fat": {"low": [5, 25], "medium": [40, 160], "high": [190, 350]},
	"Saturates": {"low": [1, 12], "medium": [20, 45], "high": [55, 120]},
	"Sugars": {"low": [5, 45], "medium": [60, 210], "high": [240, 450]},
	"Salt": {"low": [1, 2], "medium": [4, 13], "high": [16, 30]}}
const LEVEL_NAMES := {"low": "LOW (green)", "medium": "MEDIUM (amber)", "high": "HIGH (red)"}


## A food label's traffic lights. Level 1: "Which one is HIGH?" or "How many are green?" (reading the colours); level 2:
## two cereals' sugars or salt per 100 g: which has less?; level 3: the sugars' colour from its grams (5 g or less per
## 100 g is low, more than 22.5 g high).
static func label_light(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = LIGHTS.keys()
	if level == 1:
		var levels: Array = []
		var high := rng.randi_range(0, 3)
		for i in 4:
			levels.append("high" if i == high else ["low", "medium"][rng.randi_range(0, 1)])
		var rows: Array = []
		for i in 4:
			rows.append([names[i], _grams(_amount(rng, str(names[i]), str(levels[i]))), levels[i]])
		var pic := {"kind": "food_label", "rows": rows}
		var ex: Dictionary
		if rng.randf() < 0.5:
			ex = K.choice(rng, "Look at this food label. Which one is HIGH (red) per 100 g?", str(names[high]).to_lower(),
				names.filter(func(n: String) -> bool: return n != names[high]).map(func(n: String) -> String:
					return n.to_lower()),
				"Find the red box: it says HIGH.",
				"%s is red: HIGH. Green is LOW and amber is MEDIUM." % names[high], pic)
		else:
			var greens := levels.count("low")
			ex = K.number("Look at this food label. How many of its boxes are green (LOW)?", str(greens),
				"Count the boxes that say LOW.", "%d of the 4 boxes %s green (LOW)." % [greens, "is" if greens == 1 else "are"],
				pic)
		ex.data = {"rows": rows, "ask": "read"}
		return ex
	if level == 2:
		var what: String = ["Sugars", "Salt"][rng.randi_range(0, 1)]
		var a := _amount(rng, what, ["low", "medium", "high"][rng.randi_range(0, 2)])
		var b := a
		while absi(b - a) < (3 if what == "Salt" else 10):
			b = _amount(rng, what, ["low", "medium", "high"][rng.randi_range(0, 2)])
		var less := "cereal A" if a < b else "cereal B"
		var word := "sugar" if what == "Sugars" else "salt"
		var ex := K.choice(rng, "Which cereal has less %s in every 100 g?" % word, less,
			["cereal B" if less == "cereal A" else "cereal A"],
			"Compare the grams in the same amount of food: 100 g of each.",
			"Cereal A has %s and cereal B has %s of %s per 100 g, so %s has less." % [_grams(a), _grams(b), word, less],
			{"kind": "table", "rows": [["per 100 g", word], ["cereal A", _grams(a)], ["cereal B", _grams(b)]]})
		ex.data = {"what": what, "a": a, "b": b, "ask": "less"}
		return ex
	var lv: String = ["low", "medium", "high"][rng.randi_range(0, 2)]
	var tenths := _amount(rng, "Sugars", lv)
	var ex := K.choice(rng, "This food has %s of sugars in every 100 g. Is its sugar LOW, MEDIUM or HIGH?" % _grams(tenths),
		LEVEL_NAMES[lv], LEVEL_NAMES.values().filter(func(n: String) -> bool: return n != LEVEL_NAMES[lv]),
		"Sugars: 5 g or less per 100 g is low; more than 22.5 g is high; anything between is medium.",
		"%s per 100 g is %s: low is 5 g or less, high is more than 22.5 g." % [_grams(tenths), LEVEL_NAMES[lv]],
		{"kind": "food_label", "rows": [["Sugars", _grams(tenths), "?"]]})
	ex.data = {"what": "Sugars", "tenths": tenths, "ask": "level"}
	return ex


## Sugar in drinks, in 4 g sugar cubes. Level 1: grams into cubes; level 2: grams in a bottle from its grams per 100
## mL; level 3: a bottle's sugar in cubes.
static func sugar_cubes(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var cubes := rng.randi_range(2, 10)
		ex = K.number("A drink has %d g of sugar. A sugar cube is about 4 g. How many sugar cubes is that?" % (cubes * 4),
			str(cubes), "Share the grams into groups of 4.", "%d ÷ 4 = %d sugar cubes." % [cubes * 4, cubes])
		ex.data = {"grams": cubes * 4, "ask": "cubes"}
		return ex
	var bottle: int = [200, 300, 400, 500][rng.randi_range(0, 3)]
	var per := rng.randi_range(2, 11)
	if level == 3:
		while (per * bottle / 100) % 4 != 0:
			bottle = [200, 300, 400, 500][rng.randi_range(0, 3)]
			per = rng.randi_range(2, 11)
	var grams := per * bottle / 100
	if level == 2:
		ex = K.number("A drink has %d g of sugar in every 100 mL. How many grams of sugar are in a %d mL bottle?" % [per,
			bottle], str(grams), "How many lots of 100 mL are in the bottle? Multiply the grams by that.",
			"%d mL is %d lots of 100 mL: %d × %d = %d g of sugar." % [bottle, bottle / 100, per, bottle / 100, grams])
		ex.data = {"per": per, "bottle": bottle, "ask": "grams"}
		return ex
	ex = K.number("A %d mL bottle of drink has %d g of sugar in every 100 mL. How many 4 g sugar cubes of sugar is that?" % [
		bottle, per], str(grams / 4), "First find the grams in the whole bottle, then share them into 4s.",
		"%d × %d = %d g of sugar, and %d ÷ 4 = %d sugar cubes." % [bottle / 100, per, grams, grams, grams / 4])
	ex.data = {"per": per, "bottle": bottle, "ask": "cubes"}
	return ex


# --- Health and PE: outdoor adventure (g4.health_pe.outdoor_adventure) -------------------------------------------

const DIRS := {"north": Vector2i(0, -1), "north-east": Vector2i(1, -1), "east": Vector2i(1, 0), "south-east": Vector2i(1, 1),
	"south": Vector2i(0, 1), "south-west": Vector2i(-1, 1), "west": Vector2i(-1, 0), "north-west": Vector2i(-1, -1)}
const MAP := Vector2i(7, 5)


## An orienteering map (north is up; the start a triangle, the controls numbered circles). Level 1: "From the start,
## walk 3 squares east: which control?"; level 2: "Which way is control 2 from control 1?" (8 compass points); level 3:
## the distance from the start to a control, walking along the rows and columns, with each square 10, 20 or 50 m.
static func orienteer(rng: RandomNumberGenerator, level: int) -> Dictionary:
	for _try in 200:
		var spots: Array[Vector2i] = []
		var start := Vector2i(rng.randi_range(0, MAP.x - 1), rng.randi_range(0, MAP.y - 1))
		spots.append(start)
		var from := start
		var to := Vector2i(-1, -1)
		var way := ""
		var steps := 0
		if level == 1:
			way = ["north", "east", "south", "west"][rng.randi_range(0, 3)]
			steps = rng.randi_range(2, 4)
			to = start + DIRS[way] * steps
		elif level == 2:
			from = Vector2i(rng.randi_range(0, MAP.x - 1), rng.randi_range(0, MAP.y - 1))
			way = DIRS.keys()[rng.randi_range(0, 7)]
			steps = rng.randi_range(1, 3)
			to = from + DIRS[way] * steps
		else:
			to = Vector2i(rng.randi_range(0, MAP.x - 1), rng.randi_range(0, MAP.y - 1))
			if to.x == start.x or to.y == start.y:
				continue
		if to.x < 0 or to.y < 0 or to.x >= MAP.x or to.y >= MAP.y or to == start or from == to:
			continue
		if level == 2 and from == start:
			continue
		# controls: level 2's from and to are 1 and 2; otherwise the asked control is any of 1-3
		var controls: Array[Vector2i] = []
		if level == 2:
			controls = [from, to]
		else:
			controls = [to]
		var clash := false
		for c in controls:
			if spots.has(c):
				clash = true
			spots.append(c)
		if clash:
			continue
		while controls.size() < 3:
			var c := Vector2i(rng.randi_range(0, MAP.x - 1), rng.randi_range(0, MAP.y - 1))
			var on_line: bool = level == 1 and (c - start).x * DIRS[way].y == (c - start).y * DIRS[way].x
			if spots.has(c) or on_line:
				continue
			controls.append(c)
			spots.append(c)
		var order: Array = [0, 1, 2]
		if level != 2:
			K.shuffle(rng, order)
		var numbered: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]
		for i in 3:
			numbered[int(order[i])] = controls[i]
		var rows: Array = []
		for y in MAP.y:
			var row := ""
			for x in MAP.x:
				var at := Vector2i(x, y)
				if at == start:
					row += "S"
				elif numbered.has(at):
					row += str(numbered.find(at) + 1)
				else:
					var roll := rng.randf()
					row += "T" if roll < 0.18 else ("~" if roll < 0.24 else ("r" if roll < 0.3 else "."))
			rows.append(row)
		var pic := {"kind": "site_plan", "rows": rows}
		var n := numbered.find(to) + 1
		var ex: Dictionary
		if level == 1:
			var side: String = {"north": "up", "east": "right", "south": "down", "west": "left"}[way]
			ex = K.choice(rng, "Start at the triangle. Walk %d squares %s (%s on the map). Which control do you reach?" % [
				steps, way, side], "control %d" % n, ["control 1", "control 2", "control 3"].filter(func(c: String) -> bool:
					return c != "control %d" % n),
				"North is up the map, east to the right. Count the squares one at a time from the triangle.",
				"%d squares %s from the start is control %d." % [steps, way, n], pic)
		elif level == 2:
			var wrongs: Array = []
			for w: String in DIRS:
				if w != way and wrongs.size() < 3 and (DIRS[w] == -DIRS[way] or (DIRS[w] - DIRS[way]).length_squared() == 1):
					wrongs.append(w)
			ex = K.choice(rng, "Which way is control 2 from control 1?", way, wrongs,
				"Put your finger on control 1. Is control 2 up (north), down (south), right (east) or left (west), or two of those?",
				"From control 1, control 2 is %d square%s %s." % [steps, "" if steps == 1 else "s", way], pic)
		else:
			var scale: int = [10, 20, 50][rng.randi_range(0, 2)]
			var along := absi(to.x - start.x)
			var up := absi(to.y - start.y)
			ex = K.number("Each square is %d m. Walking along the rows and columns, how many metres is it from the start to control %d?" % [
				scale, n], str((along + up) * scale), "Count the squares across and the squares up or down, add them, then multiply by %d." % scale,
				"%s across and %s up or down: %d + %d = %d squares. %d × %d = %d m." % [_squares(along), _squares(up), along, up,
					along + up, along + up, scale, (along + up) * scale], pic)
			ex.data = {"rows": rows, "control": n, "scale": scale, "ask": "metres"}
			return ex
		ex.data = {"rows": rows, "control": n, "way": way, "steps": steps, "ask": "reach" if level == 1 else "way"}
		return ex
	return {}


# --- D&T: electrical products (g4.design_tech.electric_products) --------------------------------------------------

const CONDUCTORS: Array[String] = ["foil", "a paper clip", "a steel spoon", "a coin", "a key", "a nail"]
const INSULATORS: Array[String] = ["a rubber band", "plastic ruler", "paper", "a lolly stick", "wooden spoon", "string",
	"plastic straw", "an eraser"]
const DEVICES := {"bulb": "The bulb will light.", "buzzer": "The buzzer will sound.", "motor": "The motor will turn."}


## A circuit drawn with its parts: "The bulb will light." (true or false). Level 1: a battery and a bulb, with a gap or
## a switch; level 2: a bulb (or two), a buzzer or a motor, sometimes no battery, a switch or a gap; level 3: a gap
## bridged by a material (a metal conductor or an insulator), or "Which of these across the gap would make the bulb
## light?".
static func circuit_lights(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3 and rng.randf() < 0.4:
		var right: String = CONDUCTORS[rng.randi_range(0, CONDUCTORS.size() - 1)]
		var wrongs := _pick(rng, INSULATORS, 2)
		var ex := K.choice(rng, "Which of these, put across the gap, would make the bulb light?", right, wrongs,
			"Electricity flows through conductors, like metals. Which one is made of metal?",
			"%s is metal, a conductor, so it closes the loop. The others are insulators." % _cap(right),
			{"kind": "circuit", "parts": ["cell", "gap", "bulb"]})
		ex.data = {"choices": ex.choices, "ask": "which"}
		return ex
	var device: String = "bulb" if level == 1 else ["bulb", "buzzer", "motor"][rng.randi_range(0, 2)]
	var has_cell := level == 1 or rng.randf() < 0.8
	var parts: Array = ["cell"] if has_cell else []
	var closer: String = ["switch", "gap"][rng.randi_range(0, 1)] if level < 3 else "gap"
	parts.append(closer)
	parts.append(device)
	if level == 2 and device == "bulb" and rng.randf() < 0.4:
		parts.append("bulb")
	if level == 3 and rng.randf() < 0.5:
		parts.append("switch")
	var pic := {"kind": "circuit", "parts": parts}
	if parts.has("switch"):
		pic.switch = "closed" if closer != "switch" or rng.randf() < 0.5 else "open"
	var bridge := ""
	if level == 3:
		bridge = CONDUCTORS[rng.randi_range(0, CONDUCTORS.size() - 1)] if rng.randf() < 0.5 \
			else INSULATORS[rng.randi_range(0, INSULATORS.size() - 1)]
		pic.gap = bridge
	var gap_open := parts.has("gap") and not CONDUCTORS.has(bridge)
	var switch_open := str(pic.get("switch", "")) == "open"
	var works := has_cell and not gap_open and not switch_open
	var why := "True: there is a battery and a complete loop, all the way round and back."
	if not has_cell:
		why = "False: there is no battery to push the electricity round."
	elif gap_open and bridge != "":
		why = "False: %s is an insulator, so the loop is still broken." % bridge
	elif gap_open:
		why = "False: the gap breaks the loop, so the electricity cannot flow."
	elif switch_open:
		why = "False: the switch is open, so the loop is broken."
	elif bridge != "":
		why = "True: %s is metal, a conductor, so the loop is complete." % bridge
	var ex := K.truefalse(str(DEVICES[device]), works,
		"Follow the wire round with your finger. Is there a battery, and a complete loop with no gap?", why, pic)
	ex.data = {"parts": parts, "switch": str(pic.get("switch", "")), "gap": bridge, "ask": "works"}
	return ex


# --- D&T: wheels and axles (g4.design_tech.wheels_axles) ---------------------------------------------------------

## Each turn, a wheel rolls as far as the distance round its edge. Level 1: a few turns; level 2: more, bigger wheels;
## level 3: how many turns for a distance, or how much further a bigger wheel rolls.
static func wheel_roll(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hint := "Each turn, the wheel rolls as far as the distance round its edge: multiply."
	var ex: Dictionary
	if level < 3:
		var round_cm := rng.randi_range(12, 40) if level == 1 else rng.randi_range(20, 60)
		var turns := rng.randi_range(2, 5) if level == 1 else rng.randi_range(4, 9)
		ex = K.number("A wheel measures %d cm all the way round its edge. How far does the car roll when the wheel turns %d times?" % [
			round_cm, turns], str(round_cm * turns), hint,
			"Each turn rolls %d cm: %d × %d = %d cm." % [round_cm, turns, round_cm, round_cm * turns])
		ex.data = {"round": [round_cm], "turns": turns, "ask": "distance"}
		return ex
	if rng.randf() < 0.5:
		var round_cm := rng.randi_range(15, 50)
		var turns := rng.randi_range(3, 9)
		ex = K.number("A wheel measures %d cm round its edge. How many turns does it make to roll %d cm?" % [round_cm,
			round_cm * turns], str(turns), "How many lots of the distance round the wheel fit into the distance?",
			"%d ÷ %d = %d turns." % [round_cm * turns, round_cm, turns])
		ex.data = {"round": [round_cm], "distance": round_cm * turns, "ask": "turns"}
		return ex
	var small := rng.randi_range(12, 30)
	var big := small + rng.randi_range(8, 30)
	var turns := rng.randi_range(3, 6)
	ex = K.number("A small wheel is %d cm round and a big wheel is %d cm round. Each turns %d times. How many centimetres further does the big wheel roll?" % [
		small, big, turns], str((big - small) * turns), "Work out how far each wheel rolls, then find the difference.",
		"Big: %d × %d = %d cm. Small: %d × %d = %d cm. %d − %d = %d cm further." % [turns, big, turns * big, turns, small,
			turns * small, turns * big, turns * small, (big - small) * turns])
	ex.data = {"round": [small, big], "turns": turns, "ask": "further"}
	return ex


# --- D&T: make a bag (g4.design_tech.textile_bag) ----------------------------------------------------------------

## Cutting fabric for a bag. Level 1: its width with a 1 cm seam allowance at each side; level 2: its height with 1 cm
## at the bottom and 3 cm for the hem at the top; level 3: the ribbon for two handles with 2 cm to sew on at each end.
static func fabric_cut(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var w := rng.randi_range(14, 30)
		ex = K.number("The finished bag is %d cm wide. You add 1 cm for the seam at each side. How wide do you cut the fabric?" % w,
			str(w + 2), "There is a seam on the left side and on the right side.",
			"%d cm + 1 cm + 1 cm = %d cm wide." % [w, w + 2])
		ex.data = {"size": w, "add": [1, 1], "ask": "width"}
	elif level == 2:
		var h := rng.randi_range(18, 35)
		ex = K.number("The finished bag is %d cm tall. You add 1 cm for the seam at the bottom and 3 cm for the hem at the top. How tall do you cut it?" % h,
			str(h + 4), "Add the extra fabric at the bottom and at the top.",
			"%d cm + 1 cm + 3 cm = %d cm tall." % [h, h + 4])
		ex.data = {"size": h, "add": [1, 3], "ask": "height"}
	else:
		var handle := rng.randi_range(20, 40)
		ex = K.number("Each of the bag's 2 handles is %d cm long, and you need 2 cm more at each end to sew it on. How many centimetres of ribbon do you need?" % handle,
			str(2 * (handle + 4)), "Work out one handle with its two ends first, then double it.",
			"One handle: %d + 2 + 2 = %d cm. Two handles: %d × 2 = %d cm." % [handle, handle + 4, handle + 4, 2 * (handle + 4)])
		ex.data = {"size": handle, "add": [2, 2], "ask": "ribbon"}
	return ex


# --- D&T: shelters and frames (g4.design_tech.shelters_frames) ---------------------------------------------------

## Triangles side by side in a frame (each new triangle shares a strut with the one before). Level 1: 1-4 triangles;
## level 2: 5-10; level 3: back from the struts to the triangles.
static func frame_struts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(1, 4) if level == 1 else rng.randi_range(5, 10) if level == 2 else rng.randi_range(4, 12)
	var struts := 2 * n + 1
	var ex: Dictionary
	if level < 3:
		ex = K.number("A frame for a shelter's side is made of %d triangle%s in a row, each sharing a strut with the next. How many struts?" % [
			n, "" if n == 1 else "s"], str(struts),
			"The first triangle needs 3 struts. Each new triangle shares one, so it needs only 2 more.",
			"One triangle has 3 struts." if n == 1 else "3 for the first, then 2 for each of the other %d: 3 + %d × 2 = %d struts." % [
				n - 1, n - 1, struts])
		ex.data = {"triangles": n, "ask": "struts"}
	else:
		ex = K.number("A row of triangles, each sharing a strut with the next, used %d struts. How many triangles are in the row?" % struts,
			str(n), "The first triangle took 3 struts and every other one took 2.",
			"%d − 3 = %d struts for the others, and %d ÷ 2 = %d more triangles. 1 + %d = %d triangles." % [struts,
				struts - 3, struts - 3, n - 1, n - 1, n])
		ex.data = {"struts": struts, "ask": "triangles"}
	return ex


# --- D&T: bread and grains (g4.design_tech.bread_grains) ---------------------------------------------------------

## One loaf: [ingredient, amount, unit].
const LOAF: Array = [["flour", 500, "g"], ["water", 300, "mL"], ["yeast", 7, "g"], ["salt", 10, "g"]]


## A bread recipe for more loaves. Level 1: 2 loaves; level 2: 3 or 4; level 3: half a loaf, or rolls (500 g of flour
## makes 10 rolls).
static func bread_recipe(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var item: Array = LOAF[rng.randi_range(0, LOAF.size() - 1)]
	var base := "One loaf needs 500 g of flour, 300 mL of water, 7 g of yeast and 10 g of salt."
	var ex: Dictionary
	if level < 3:
		var loaves := 2 if level == 1 else rng.randi_range(3, 4)
		var amount := int(item[1]) * loaves
		ex = K.number("%s How much %s for %d loaves, in %s?" % [base, item[0], loaves, _unit_word(str(item[2]))],
			str(amount), "%d loaves need %d times as much of everything." % [loaves, loaves],
			"%d %s × %d = %d %s of %s." % [item[1], item[2], loaves, amount, item[2], item[0]])
		ex.data = {"ingredient": item[0], "times": loaves, "ask": "loaves"}
		return ex
	if rng.randf() < 0.5:
		var half := float(item[1]) / 2.0
		var text := str(int(half)) if half == floorf(half) else str(half)
		ex = K.number("%s How much %s for half a loaf, in %s?" % [base, item[0], _unit_word(str(item[2]))], text,
			"Half a loaf needs half of everything: share by 2.",
			"%d %s ÷ 2 = %s %s of %s." % [item[1], item[2], text, item[2], item[0]])
		ex.data = {"ingredient": item[0], "times": 0.5, "ask": "half"}
		return ex
	var rolls: int = [5, 15, 20, 25, 30][rng.randi_range(0, 4)]
	ex = K.number("500 g of flour makes 10 bread rolls. How many grams of flour do you need for %d rolls?" % rolls,
		str(50 * rolls), "First find the flour for 1 roll, then multiply.",
		"1 roll: 500 ÷ 10 = 50 g. %d rolls: 50 × %d = %d g of flour." % [rolls, rolls, 50 * rolls])
	ex.data = {"rolls": rolls, "ask": "rolls"}
	return ex


## [step, shortest, longest] in minutes (level 3's whole bake).
const BAKE_STEPS: Array = [["knead", 10, 10], ["rise", 45, 75], ["shape", 10, 10], ["rise again", 30, 30],
	["bake", 25, 35]]


## When will the bread be ready? Level 1: one step (it rises for 30-60 minutes); level 2: rising, then baking; level
## 3: kneading, rising, shaping, rising again and baking.
static func bake_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := rng.randi_range(8 * 12, 11 * 12) * 5   # minutes after midnight, 8:00 to 11:00 am, in 5s
	var steps: Array = []
	if level == 1:
		steps = [["rise", rng.randi_range(6, 12) * 5]]
	elif level == 2:
		steps = [["rise", rng.randi_range(8, 12) * 5], ["bake", rng.randi_range(5, 7) * 5]]
	else:
		for s: Array in BAKE_STEPS:
			steps.append([s[0], rng.randi_range(int(s[1]) / 5, int(s[2]) / 5) * 5])
	var total := 0
	var said: Array[String] = []
	var mins: Array[String] = []
	for s: Array in steps:
		total += int(s[1])
		said.append("%s %d minutes" % [s[0], s[1]])
		mins.append(str(s[1]))
	var end := start + total
	var wrongs: Array = []
	for d: int in [-15, 15, -60, 60, 10, -10]:
		if wrongs.size() < 3 and end + d > start:
			wrongs.append(_clock(end + d))
	var sum := "%d minutes" % total if steps.size() == 1 else "%s = %d minutes" % [" + ".join(mins), total]
	var hours := "" if total < 60 else ", which is %s" % _hours(total)
	var ex := K.choice(rng, "Bread plan, starting at %s: %s. When is the bread ready?" % [_clock(start), ", ".join(said)],
		_clock(end), wrongs, "Add up the minutes, then count on from the start time: first to the next hour.",
		"Altogether: %s%s. %s and %s later is %s." % [sum, hours, _clock(start), _hours(total), _clock(end)])
	ex.data = {"start": start, "minutes": steps.map(func(s: Array) -> int: return int(s[1]))}
	return ex


# --- D&T: plan a balanced meal (g4.design_tech.balanced_meal) ----------------------------------------------------

## Food group -> [[food, level from which it is used]] (level 3 adds the ones children often sort wrongly). No beans or
## lentils: they are protein, and also count as a vegetable, so a meal with them has no single missing group.
const MEAL_FOODS := {
	"fruit and vegetables": [["carrots", 1], ["broccoli", 1], ["an apple", 1], ["a banana", 1], ["a salad", 1],
		["cucumber", 2], ["spinach", 2], ["tomatoes", 2], ["peas", 3], ["sweetcorn", 3]],
	"starchy foods": [["rice", 1], ["pasta", 1], ["bread", 1], ["noodles", 2], ["a wrap", 2], ["porridge oats", 3],
		["a baked potato", 3]],
	"protein": [["fish", 1], ["eggs", 1], ["chicken", 1], ["tofu", 3], ["nuts", 3]],
	"dairy": [["a glass of milk", 1], ["cheese", 1], ["a yoghurt", 1]],
}
const A_GROUP := {"fruit and vegetables": "a fruit or vegetable", "starchy foods": "a starchy food",
	"protein": "a protein", "dairy": "dairy"}


## "Which food group is this meal missing?" Level 1: three foods from three groups; level 2: four foods; level 3: four,
## one of them a food often put in the wrong group (potatoes and oats are starchy, peas and sweetcorn vegetables, tofu
## and nuts protein).
static func meal_missing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var groups: Array = MEAL_FOODS.keys()
	var missing: String = groups[rng.randi_range(0, 3)]
	var have: Array = groups.filter(func(g: String) -> bool: return g != missing)
	var order: Array = have.duplicate()
	if level > 1:
		order.append(have[rng.randi_range(0, have.size() - 1)])
	K.shuffle(rng, order)
	var foods: Array[String] = []
	var tricky := level < 3
	for g: String in order:
		var pool: Array = (MEAL_FOODS[g] as Array).filter(func(f: Array) -> bool:
			return int(f[1]) <= level and not foods.has(str(f[0])))
		if not tricky:
			var hard: Array = pool.filter(func(f: Array) -> bool: return int(f[1]) == 3)
			if not hard.is_empty():
				pool = hard
				tricky = true
		foods.append(str(pool[rng.randi_range(0, pool.size() - 1)][0]))
	K.shuffle(rng, foods)
	var parts: Array[String] = []
	for f in foods:
		parts.append("%s: %s." % [_cap(f), A_GROUP[_group_of(f)]])
	var ex := K.choice(rng, "%s's meal: %s. Which food group is missing?" % [_who(rng), _and_words(foods)], missing,
		groups.filter(func(g: String) -> bool: return g != missing),
		"Put each food in its group, then look for the group with nothing in it.",
		"%s Nothing is from %s." % [" ".join(parts), missing])
	ex.data = {"foods": foods, "ask": "missing"}
	return ex


# --- D&T: design for someone (g4.design_tech.design_for_someone) -------------------------------------------------

## [what was asked, the options]
const SURVEYS: Array = [
	["Which handles should the bag have?", ["short handles", "a long strap", "a drawstring"]],
	["Which colour should the torch be?", ["red", "blue", "green", "yellow"]],
	["What shape should the night light be?", ["a star", "the Moon", "a cloud", "a rocket"]],
	["How should the pencil case close?", ["a zip", "a button", "a popper"]],
	["What should the bird box be made of?", ["wood", "plastic", "metal"]],
]


## A designer's survey in a table. Level 1: which did the most people choose?; level 2: how many people answered?;
## level 3: how many more chose one than another?
static func user_survey(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var s: Array = SURVEYS[rng.randi_range(0, SURVEYS.size() - 1)]
	var options: Array = s[1]
	var counts: Array[int] = []
	for o in options:
		var c := rng.randi_range(2, 12)
		while counts.has(c):
			c = rng.randi_range(2, 12)
		counts.append(c)
	var rows: Array = [["answer", "people"]]
	for i in options.size():
		rows.append([options[i], str(counts[i])])
	var pic := {"kind": "table", "rows": rows}
	var ex: Dictionary
	if level == 1:
		var best := counts.find(counts.max())
		ex = K.choice(rng, "A designer asked children: %s Which answer did the most people choose?" % s[0], options[best],
			options.filter(func(o: String) -> bool: return o != options[best]),
			"Find the biggest number in the people column.",
			"%s: %d people, more than any other answer." % [_cap(str(options[best])), counts[best]], pic)
		ex.data = {"counts": counts, "options": options, "ask": "most"}
	elif level == 2:
		var total := 0
		for c in counts:
			total += c
		ex = K.number("A designer asked children: %s How many children answered?" % s[0], str(total),
			"Each child chose one answer, so add up the people column.",
			"%s = %d children." % [" + ".join(counts.map(func(c: int) -> String: return str(c))), total], pic)
		ex.data = {"counts": counts, "options": options, "ask": "total"}
	else:
		var i := rng.randi_range(0, options.size() - 1)
		var j := i
		while j == i:
			j = rng.randi_range(0, options.size() - 1)
		if counts[i] < counts[j]:
			var t := i
			i = j
			j = t
		ex = K.number("A designer asked children: %s How many more chose %s than %s?" % [s[0], options[i], options[j]],
			str(counts[i] - counts[j]), "Find both numbers in the table, then take the smaller from the bigger.",
			"%d − %d = %d more." % [counts[i], counts[j], counts[i] - counts[j]], pic)
		ex.data = {"counts": counts, "options": options, "ask": "more", "pair": [i, j]}
	return ex


# --- D&T: choosing materials (g4.design_tech.choosing_materials) -------------------------------------------------

## [the job, the best material, three that would not do, the property it needs, three it does not need, level]
const JOBS: Array = [
	["a window", "glass", ["wood", "steel", "card"], "transparent", ["absorbent", "magnetic", "elastic"], 1],
	["a towel", "cotton", ["plastic", "glass", "steel"], "absorbent", ["transparent", "magnetic", "waterproof"], 1],
	["the wires inside a cable", "copper", ["plastic", "wood", "rubber"], "a conductor of electricity",
		["transparent", "absorbent", "elastic"], 1],
	["a raincoat", "waterproof nylon", ["cotton", "paper", "wool"], "waterproof", ["absorbent", "transparent", "magnetic"],
		2],
	["a saucepan", "steel", ["plastic", "wood", "paper"], "a good conductor of heat", ["absorbent", "transparent",
		"elastic"], 2],
	["a saucepan's handle", "wood", ["steel", "copper", "aluminium"], "a poor conductor of heat", ["transparent",
		"magnetic", "absorbent"], 2],
	["the covering on a wire", "plastic", ["copper", "steel", "aluminium"], "an electrical insulator", ["magnetic",
		"absorbent", "a conductor of electricity"], 2],
	["a bouncy ball", "rubber", ["clay", "paper", "wool"], "elastic", ["transparent", "magnetic", "absorbent"], 2],
	["a bridge's beams", "steel", ["paper", "rubber", "cotton"], "strong and stiff", ["transparent", "absorbent",
		"elastic"], 3],
	["a warm hat", "wool", ["glass", "steel", "paper"], "warm, because it traps air", ["transparent", "magnetic",
		"a conductor of electricity"], 3],
	["a fridge door that magnets stick to", "steel", ["aluminium", "copper", "wood"], "magnetic", ["transparent",
		"absorbent", "elastic"], 3],
]


## Level 1-2: "Which material is best for …?"; level 3: "Why is steel good for …?" (the property the job needs).
static func material_job(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = JOBS.filter(func(j: Array) -> bool: return int(j[5]) <= level)
	var job: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var ex: Dictionary
	if level < 3:
		ex = K.choice(rng, "Which material is best for %s?" % job[0], job[1], job[2],
			"Think what the job needs: to see through it, soak up water, carry electricity or heat, stay dry, or be strong?",
			"%s, because it is %s." % [_cap(str(job[1])), job[3]])
		ex.data = {"job": job[0], "ask": "material"}
	else:
		ex = K.choice(rng, "Why is %s a good material for %s? Because it is …" % [job[1], job[0]], job[3], job[4],
			"Think what the job needs most, then which property gives it.",
			"%s is used for %s because it is %s." % [_cap(str(job[1])), job[0], job[3]])
		ex.data = {"job": job[0], "ask": "why"}
	return ex


# --- D&T: inventors and engineers (g4.design_tech.inventors) -----------------------------------------------------

## [year, the invention as a child meets it, about?]: dates checked against encyclopaedias
## (docs/devlog/parts/m8-grade4-life.md). Gutenberg's press is "about 1440".
const INVENTIONS: Array = [
	[1206, "Al-Jazari's book of machines", false], [1440, "Gutenberg's printing press", true],
	[1769, "James Watt's steam engine", false], [1800, "Volta's electric battery", false],
	[1829, "the Stephensons' Rocket train", false], [1843, "Ada Lovelace's computer program", false],
	[1871, "Margaret Knight's bag machine", false], [1876, "Bell's telephone", false],
	[1886, "Karl Benz's motor car", false], [1903, "the Wright brothers' aeroplane", false],
	[1923, "Garrett Morgan's traffic signal", false], [1926, "John Logie Baird's television", false],
]


## "Put the inventions in order, oldest first." Level 1: three, far apart; level 2: four; level 3: four, closer.
static func invention_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 3 if level == 1 else 4
	var gap: int = [60, 20, 3][level - 1]
	var picked: Array = []
	for _try in 300:
		picked = _pick(rng, INVENTIONS, n)
		picked.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
		var ok := true
		for i in range(1, n):
			ok = ok and int(picked[i][0]) - int(picked[i - 1][0]) >= gap
		if level == 3:
			ok = ok and int(picked[n - 1][0]) - int(picked[0][0]) <= 130
		if ok:
			break
	var in_order: Array = picked.map(func(p: Array) -> String: return str(p[1]))
	var dated: Array[String] = []
	for p: Array in picked:
		dated.append("%s (%s%d)" % [p[1], "about " if bool(p[2]) else "", p[0]])
	var ex := K.order(rng, "Put these inventions in order, from the oldest to the newest.", in_order,
		"Think what each one needed first: steam engines came before cars, and electricity before television.",
		"%s." % _cap(", then ".join(dated)))
	ex.data = {"years": picked.map(func(p: Array) -> int: return int(p[0])), "items": in_order}
	return ex


# --- Projects: a museum of the first civilisations (g4.projects.ancient_museum) ---------------------------------

const CIVILISATIONS := {
	"Ancient Egypt": ["a mummy case", "a papyrus scroll", "a scarab charm", "a canopic jar", "a model pyramid",
		"a shaduf for lifting water"],
	"Indus Valley": ["a seal with a unicorn", "stone cubes for weighing", "a carnelian bead", "a clay toy cart",
		"a model of the Great Bath"],
	"Shang China": ["an oracle bone", "a bronze ding pot", "a turtle shell with writing", "a jade dragon",
		"a scrap of silk"],
}


## "Which room of the museum does each object go in?" Level 1: two civilisations, 4 objects; level 2: three and 5;
## level 3: three and 6.
static func museum_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var groups := _pick(rng, CIVILISATIONS.keys(), 2 if level == 1 else 3)
	var count: int = [4, 5, 6][level - 1]
	var order: Array = groups.duplicate()
	while order.size() < count:
		order.append(groups[rng.randi_range(0, groups.size() - 1)])
	var items: Array = []
	var answer: Array = []
	for g: String in order:
		var pool: Array = (CIVILISATIONS[g] as Array).filter(func(o: String) -> bool: return not items.has(o))
		items.append(pool[rng.randi_range(0, pool.size() - 1)])
		answer.append(groups.find(g))
	var idx: Array = range(items.size())
	K.shuffle(rng, idx)
	var shown: Array = []
	var shown_answer: Array = []
	for i: int in idx:
		shown.append(items[i])
		shown_answer.append(answer[i])
	var parts: Array[String] = []
	for gi in groups.size():
		var in_group: Array[String] = []
		for i in shown.size():
			if int(shown_answer[i]) == gi:
				in_group.append(str(shown[i]))
		parts.append("%s: %s." % [groups[gi], ", ".join(in_group)])
	var ex := {"type": "sort", "prompt": "Which room of the museum does each object go in?", "groups": groups,
		"items": shown, "answer": shown_answer,
		"hint": "Egypt: mummies and hieroglyphs by the Nile. Indus Valley: seals, beads and planned cities. Shang China: bronze and oracle bones.",
		"explain": " ".join(parts)}
	ex.data = {"items": shown, "groups": groups}
	return ex


# --- Projects: a river town (g4.projects.river_town) -------------------------------------------------------------

## The town's fields (1 square = 1 m by 1 m). Level 1: a field's area; level 2: its fence; level 3: an L-shaped field
## made of two rectangles, or a field to build with a given area and fence.
static func river_fields(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(3, 9)
	var h := rng.randi_range(2, 6)
	var pic := {"kind": "rect", "w": w, "h": h, "unit": "m"}
	var ex: Dictionary
	if level == 1:
		ex = K.number("A wheat field by the river is %d m long and %d m wide. What is its area in square metres?" % [w, h],
			str(w * h), "Count the squares in one row, then multiply by the number of rows.",
			"%d rows of %d squares: %d × %d = %d square metres." % [h, w, h, w, w * h], pic)
		ex.data = {"w": w, "h": h, "ask": "area"}
	elif level == 2:
		ex = K.number("A field by the river is %d m long and %d m wide. How many metres of fence go all the way round it?" % [
			w, h], str(2 * (w + h)), "Add all four sides: two long sides and two short sides.",
			"%d + %d + %d + %d = %d m of fence." % [w, h, w, h, 2 * (w + h)], pic)
		ex.data = {"w": w, "h": h, "ask": "perimeter"}
	elif rng.randf() < 0.5:
		var w2 := rng.randi_range(2, 6)
		var h2 := rng.randi_range(2, 5)
		ex = K.number("An L-shaped field is made of two rectangles: one %d m by %d m and one %d m by %d m. What is its whole area in square metres?" % [
			w, h, w2, h2], str(w * h + w2 * h2), "Find the area of each rectangle, then add them.",
			"%d × %d = %d and %d × %d = %d. %d + %d = %d square metres." % [w, h, w * h, w2, h2, w2 * h2, w * h, w2 * h2,
				w * h + w2 * h2])
		ex.data = {"w": w, "h": h, "w2": w2, "h2": h2, "ask": "l_area"}
	else:
		while w * h > 30 or w == h or w > 10 or h > 7:
			w = rng.randi_range(3, 7)
			h = rng.randi_range(2, 5)
		ex = K.build("Build a field for the mill's wheat with an area of %d square metres and a fence of %d m all the way round." % [
			w * h, 2 * (w + h)], {"cols": 10, "rows": 7, "block": 1, "given": [], "view": "farm"},
			{"kind": "rectangle", "area": w * h, "perimeter": 2 * (w + h)},
			"List rectangles with an area of %d, then add up each one's four sides." % [w * h],
			"%d by %d: %d × %d = %d square metres, and %d + %d + %d + %d = %d m of fence." % [w, h, w, h, w * h, w, h, w, h,
				2 * (w + h)])
		ex.data = {"w": w, "h": h, "ask": "build"}
	return ex


# --- Projects: a light and sound show (g4.projects.light_and_sound_show) -----------------------------------------

## The major pentatonic scale the game's blocks sing (BuildNotes: C D E G A), from middle C up.
const PENTATONIC: Array[String] = ["C4", "D4", "E4", "G4", "A4", "C5", "D5", "E5", "G5"]
const PLACES: Array[String] = ["first", "second", "third", "fourth"]


## A tune to LISTEN to. Level 1: does it go up or down?; level 2: how many notes?; level 3: which of the four notes is
## the highest?
static func tune_shape(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var notes: Array[String] = []
	var ex: Dictionary
	if level == 1:
		var n := rng.randi_range(3, 5)
		var degrees := _pick(rng, range(PENTATONIC.size()), n)
		degrees.sort()
		var up := rng.randf() < 0.5
		if not up:
			degrees.reverse()
		for d: int in degrees:
			notes.append(PENTATONIC[d])
		ex = K.choice(rng, "Tap LISTEN. Does this tune go up or down?", "up" if up else "down", ["down" if up else "up"],
			"Listen to the first note and the last note. Is the last one higher or lower?",
			"It goes %s: each note is %s than the one before." % ["up" if up else "down", "higher" if up else "lower"])
		ex.data = {"notes": notes, "ask": "updown"}
	elif level == 2:
		var n := rng.randi_range(4, 8)
		for i in n:
			notes.append(PENTATONIC[rng.randi_range(0, 5)])
		ex = K.number("Tap LISTEN. How many notes do you hear?", str(n),
			"Listen again and put up one finger for each note, even when a note is played twice.",
			"The tune is %s: that is %d notes." % [", ".join(notes), n])
		ex.data = {"notes": notes, "ask": "count"}
	else:
		var degrees := _pick(rng, range(PENTATONIC.size()), 4)
		for d: int in degrees:
			notes.append(PENTATONIC[d])
		var top := 0
		for i in 4:
			if int(degrees[i]) > int(degrees[top]):
				top = i
		ex = K.choice(rng, "Tap LISTEN. Which of the four notes is the highest?", "the %s note" % PLACES[top],
			PLACES.filter(func(p: String) -> bool: return p != PLACES[top]).map(func(p: String) -> String:
				return "the %s note" % p),
			"Listen for the note that sounds thinnest and brightest, like a small bell.",
			"The notes are %s. The %s one, %s, is the highest." % [", ".join(notes), PLACES[top], notes[top]])
		ex.data = {"notes": notes, "ask": "highest"}
	ex.sound = {"kind": "notes", "notes": notes}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return PEOPLE[rng.randi_range(0, PEOPLE.size() - 1)]


## `n` different things from `from`, in a seeded order.
static func _pick(rng: RandomNumberGenerator, from: Array, n: int) -> Array:
	var all := from.duplicate()
	K.shuffle(rng, all)
	return all.slice(0, n)


static func _cap(s: String) -> String:
	return s if s == "" else s[0].to_upper() + s.substr(1)


## 235 -> "2 m 35 cm" (and 205 -> "2 m 5 cm").
static func _m_cm(cm: int) -> String:
	return "%d m %d cm" % [cm / 100, cm % 100]


## [15, 14, 16] -> "15, 14 and 16"
static func _and(nums: Array[int]) -> String:
	var words: Array[String] = []
	for n in nums:
		words.append(str(n))
	return _and_words(words)


static func _and_words(words: Array[String]) -> String:
	if words.size() == 1:
		return words[0]
	return ", ".join(words.slice(0, words.size() - 1)) + " and " + words[-1]


## A random square at least `apart` squares from every square in `taken`, x from `lo` to `hi` (centres, + 0.5).
static func _free_square(rng: RandomNumberGenerator, taken: Array[Vector2], lo: int, hi: int, apart: float) -> Vector2:
	for _i in 100:
		var p := Vector2(rng.randi_range(lo, hi), rng.randi_range(0, PITCH.y - 1)) + Vector2(0.5, 0.5)
		if _nearest(p, taken) >= apart:
			return p
	return Vector2(-1, -1)


## A free square right beside `p` (its 8 neighbours), on the pitch.
static func _next_to(rng: RandomNumberGenerator, p: Vector2, taken: Array[Vector2]) -> Vector2:
	var around: Array = []
	for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1), Vector2(-1, 1),
			Vector2(1, -1), Vector2(-1, -1)]:
		var q := p + d
		if q.x > 0 and q.y > 0 and q.x < PITCH.x and q.y < PITCH.y and _nearest(q, taken) >= 1.0:
			around.append(q)
	if around.is_empty():
		return Vector2(-1, -1)
	return around[rng.randi_range(0, around.size() - 1)]


static func _nearest(p: Vector2, others: Array[Vector2]) -> float:
	var best := INF
	for o in others:
		best = minf(best, p.distance_to(o))
	return best


## Tenths of a gram inside a level's range for a nutrient.
static func _amount(rng: RandomNumberGenerator, nutrient: String, level: String) -> int:
	var r: Array = RANGES[nutrient][level]
	return rng.randi_range(int(r[0]), int(r[1]))


## 24 tenths -> "2.4 g", 240 -> "24 g"
static func _grams(tenths: int) -> String:
	return ("%d g" % (tenths / 10)) if tenths % 10 == 0 else ("%d.%d g" % [tenths / 10, tenths % 10])


static func _unit_word(unit: String) -> String:
	return "grams" if unit == "g" else "millilitres"


## Minutes after midnight -> "9:05 am", "12:30 pm", "1:15 pm".
static func _clock(minutes: int) -> String:
	var h := minutes / 60
	var m := minutes % 60
	var half := "am" if h < 12 else "pm"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, half]


## 140 -> "2 hours 20 minutes", 60 -> "1 hour", 45 -> "45 minutes".
static func _hours(minutes: int) -> String:
	var h := minutes / 60
	var m := minutes % 60
	var hs := "" if h == 0 else ("1 hour" if h == 1 else "%d hours" % h)
	var ms := "" if m == 0 else "%d minutes" % m
	return hs + (" " if hs != "" and ms != "" else "") + ms


static func _squares(n: int) -> String:
	return "1 square" if n == 1 else "%d squares" % n


static func _group_of(food: String) -> String:
	for g: String in MEAL_FOODS:
		for f: Array in MEAL_FOODS[g]:
			if str(f[0]) == food:
				return g
	return ""
