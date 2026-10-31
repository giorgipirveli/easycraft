class_name G5HealthGen
extends RefCounted
## Owner #70 and #73 (research §6.5): grade 5 health and PE, design and technology, and projects generators: where to
## place a shot in a net game and the tennis score, a clear pass, a dance's counts and a motif's claps, personal bests
## and goals, facts about medicines, tobacco, vaping and alcohol, allergens and high temperatures, bedtimes, an
## orienteering map's scale, paces and bearings, gears and their turns, cams, a bridge's spans and tests, a build's views
## and scale drawings, a program that controls a model, a seasonal recipe, seasons and cooking times, making from waste
## and how long waste lasts, fibres and weaves, fair tests and design criteria, a Roman town's grid, an expedition's food
## webs and biomes' weather, and a fair's money. SchoolGen "g5w.<name>", `static func <name>(rng: RandomNumberGenerator,
## level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs,
## for tests/unit/test_g5_health_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi"]


# --- Health and PE: net and wall games (g5.health_pe.net_wall_games) ---------------------------------------------

## A net court from above: you (blue) are about to hit; the red player (level 3: two red players) stands somewhere on the
## other side. "Where should you aim?": the target spot farthest from every red player, at least a square clearer than
## any other. Level 1: a short and a deep spot; levels 2-3: the four corners.
static func court_target(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var sport := "badminton" if level < 3 or rng.randf() < 0.5 else "tennis"
	var spots: Array = [[7.0, 3.0, "A"], [11.2, 3.0, "B"]] if level == 1 else \
		[[7.0, 0.9, "A"], [7.0, 5.1, "B"], [11.2, 0.9, "C"], [11.2, 5.1, "D"]]
	var reds := 2 if level == 3 else 1
	for _try in 400:
		var others: Array = []
		for i in reds:
			others.append([snappedf(rng.randf_range(6.8, 11.6), 0.1), snappedf(rng.randf_range(0.6, 5.4), 0.1), "d"])
		if level == 1:
			others[0][1] = snappedf(rng.randf_range(1.5, 4.5), 0.1)
		if reds == 2 and Vector2(float(others[0][0]), float(others[0][1])).distance_to(
				Vector2(float(others[1][0]), float(others[1][1]))) < 2.0:
			continue
		var reach: Array[float] = []
		for s: Array in spots:
			var best := INF
			for o: Array in others:
				best = minf(best, Vector2(float(s[0]), float(s[1])).distance_to(Vector2(float(o[0]), float(o[1]))))
			reach.append(best)
		var top := 0
		for i in reach.size():
			if reach[i] > reach[top]:
				top = i
		var clear := true
		for i in reach.size():
			if i != top and reach[top] - reach[i] < 1.0:
				clear = false
		if not clear or reach[top] < 2.5:
			continue
		var you: Array = [snappedf(rng.randf_range(1.5, 4.0), 0.1), snappedf(rng.randf_range(1.2, 4.8), 0.1), "a"]
		var players: Array = [you] + others
		var tags: Array = []
		for s: Array in spots:
			tags.append(str(s[2]))
		var tag := str(tags[top])
		var ex := {"type": "choice", "choices": tags, "answer": top,
			"picture": {"kind": "net_court", "sport": sport, "players": players, "spots": spots}}
		ex.prompt = "You are blue and about to hit. Which spot should you aim for, so the %s hardest to reach?" % (
			"red players find it" if reds == 2 else "red player finds it")
		ex.hint = "Look at each yellow spot. Which one is farthest from every red player on the other side?"
		ex.explain = "%s: it is about %d squares from the nearest red player, farther than any other spot. Aim for the space!" % [
			tag, int(round(reach[top]))]
		ex.data = {"players": players, "spots": spots}
		return ex
	return {}


## Tennis scoring (love, 15, 30, 40, game; deuce and advantage at 40-40), the server's score first. Level 1: points won
## so far; level 2: points in order; level 3: from deuce.
static func tennis_score(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pair := PEOPLE.duplicate()
	K.shuffle(rng, pair)
	var server := str(pair[0])
	var receiver := str(pair[1])
	var points: Array = []
	var prompt: String
	if level == 1:
		var s := rng.randi_range(0, 3)
		var r := rng.randi_range(0, 3 if s < 3 else 2)
		for i in s:
			points.append("s")
		for i in r:
			points.append("r")
		prompt = "In tennis, %s is serving. %s has won %d point%s and %s has won %d. What is the score?" % [server, server,
			s, "" if s == 1 else "s", receiver, r]
	elif level == 2:
		for _try in 50:
			points.clear()
			for i in rng.randi_range(3, 5):
				points.append("s" if rng.randf() < 0.5 else "r")
			var s := points.count("s")
			var r := points.count("r")
			if s <= 3 and r <= 3 and not (s == 3 and r == 3):
				break
		var names: Array = points.map(func(p: String) -> String: return server if p == "s" else receiver)
		prompt = "%s is serving. The points are won by %s, in that order. What is the score now?" % [server, _and(names)]
	else:
		points = ["s", "s", "s", "r", "r", "r"]
		var more: Array = []
		for i in rng.randi_range(1, 3):
			more.append("s" if rng.randf() < 0.5 else "r")
		if more.size() == 3 and more[0] == more[1]:   # a game already won after two: keep it to two points
			more.resize(2)
		points.append_array(more)
		var names: Array = more.map(func(p: String) -> String: return server if p == "s" else receiver)
		prompt = "%s is serving and the score is deuce (40-all). %s. What is the score now?" % [server,
			("The next point goes to %s" % names[0]) if more.size() == 1 else "The next %d points go to %s, in that order" % [
				more.size(), ", then ".join(names)]]
	var right := _call(points, server, receiver)
	var wrongs: Array = []
	var s := points.count("s")
	var r := points.count("r")
	for alt: Array in [[r, s], [s + 1, r], [s, r + 1], [maxi(s - 1, 0), r], [s, maxi(r - 1, 0)], [s + 2, r]]:
		var pts: Array = []
		for i in int(alt[0]):
			pts.append("s")
		for i in int(alt[1]):
			pts.append("r")
		var c := _call(pts, server, receiver)
		if c != right and not wrongs.has(c):
			wrongs.append(c)
	if level < 3 and s != r:
		var swapped := "%s-%s" % [["love", "15", "30", "40"][r], ["love", "15", "30", "40"][s]]
		if swapped != right and not wrongs.has(swapped):
			wrongs.push_front(swapped)
	var explain := "%s has won %d point%s and %s %d: the score is %s." % [server, s, "" if s == 1 else "s", receiver, r,
		right] + (" The server's score is said first." if not right.ends_with("all") else "")
	if level == 3:
		var won_s := points.slice(6).count("s")
		var won_r := points.slice(6).count("r")
		explain = "After deuce, %s won %d point%s and %s won %d: %s." % [server, won_s, "" if won_s == 1 else "s", receiver,
			won_r, right if right != "deuce" else "level again, so deuce"]
	var ex := K.choice(rng, prompt, right, wrongs.slice(0, 3),
		"Count each player's points: love, 15, 30, 40. At 40-all it is deuce, and a game needs two clear points.", explain)
	ex.data = {"points": points, "server": server, "receiver": receiver}
	return ex


static func _call(points: Array, server: String, receiver: String) -> String:
	var s := points.count("s")
	var r := points.count("r")
	var word := ["love", "15", "30", "40"]
	if s >= 4 and s - r >= 2:
		return "game to " + server
	if r >= 4 and r - s >= 2:
		return "game to " + receiver
	if s >= 3 and r >= 3:
		return "deuce" if s == r else "advantage " + (server if s > r else receiver)
	if s == r:
		return "%s-all" % word[s]
	return "%s-%s" % [word[s], word[r]]


# --- Health and PE: tactics (g5.health_pe.tactics) ----------------------------------------------------------------

## Blue has the ball; which pass is safe (no red player near the line to that teammate), or (level 3, sometimes) which
## pass would be intercepted? Built so every pass is clearly open (every red player 1.2 squares or more from its line)
## or clearly closed (a red player within 0.6 of it).
static func pass_lane(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var mates := 2 if level == 1 else 3
	var extra := 1 if level == 3 else 0
	var ask := "blocked" if level == 3 and rng.randf() < 0.4 else "safe"
	var tags := ["A", "B", "C"]
	var answer := rng.randi_range(0, mates - 1)
	for _try in 600:
		var carrier := Vector2(snappedf(rng.randf_range(1.2, 2.6), 0.1), snappedf(rng.randf_range(2.2, 4.8), 0.1))
		var mate_at: Array[Vector2] = []
		var ok := true
		for i in mates:
			var p := Vector2(snappedf(rng.randf_range(5.0, 10.5), 0.1), snappedf(rng.randf_range(0.7, 6.3), 0.1))
			for q in mate_at:
				if p.distance_to(q) < 2.2:
					ok = false
			mate_at.append(p)
		if not ok:
			continue
		var reds: Array[Vector2] = []
		for i in mates:   # a red player in the path of each closed pass
			var closed := (i != answer) if ask == "safe" else (i == answer)
			if closed:
				var t := rng.randf_range(0.4, 0.65)
				var along := carrier.lerp(mate_at[i], t)
				var side := (mate_at[i] - carrier).orthogonal().normalized() * rng.randf_range(-0.3, 0.3)
				reds.append(Vector2(snappedf((along + side).x, 0.1), snappedf((along + side).y, 0.1)))
		for i in extra + (1 if reds.size() < 2 else 0):   # others out of every open pass's way
			reds.append(Vector2(snappedf(rng.randf_range(4.0, 11.0), 0.1), snappedf(rng.randf_range(0.5, 6.5), 0.1)))
		var fine := true
		for i in mates:
			var nearest := INF
			for rd in reds:
				nearest = minf(nearest, _lane_gap(carrier, mate_at[i], rd))
			var closed := (i != answer) if ask == "safe" else (i == answer)
			if closed and nearest > 0.6 or not closed and nearest < 1.2:
				fine = false
		for rd in reds:
			if rd.distance_to(carrier) < 1.5:
				fine = false
			for m in mate_at:
				if rd.distance_to(m) < 1.2:
					fine = false
		if not fine:
			continue
		var players: Array = [[carrier.x, carrier.y, "a"]]
		for i in mates:
			players.append([mate_at[i].x, mate_at[i].y, "a", tags[i]])
		for rd in reds:
			players.append([rd.x, rd.y, "d"])
		var tag := str(tags[answer])
		var ex := {"type": "choice", "choices": tags.slice(0, mates), "answer": answer,
			"picture": {"kind": "pitch", "cols": 12, "rows": 7, "players": players, "ball": 0}}
		if ask == "safe":
			ex.prompt = "You are blue and have the ball. Which teammate can you pass to safely, with no red player in the way?"
			ex.explain = "%s: the path to %s is clear. A red player stands in the path of each other pass, ready to intercept." % [
				tag, tag]
		else:
			ex.prompt = "You are blue and have the ball. Which pass would the red team most likely intercept?"
			ex.explain = "%s: a red player stands right in the path of that pass. The other passes are clear." % tag
		ex.hint = "Imagine a straight line from the ball to each blue letter. Is a red square on it, or close to it?"
		ex.data = {"players": players, "ask": ask}
		return ex
	return {}


static func _lane_gap(a: Vector2, b: Vector2, p: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


# --- Health and PE: create a dance (g5.health_pe.create_a_dance) --------------------------------------------------

## Level 1: counts of eight in beats; level 2: when a dancer starts in a canon; level 3: a dance's form (ABA, ABACA) in
## counts.
static func dance_counts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var n := rng.randi_range(2, 8)
		ex = K.number("A dance phrase lasts %d counts of eight. How many beats is that?" % n, str(8 * n),
			"Each count of eight is 8 beats. How many lots of 8?", "%d × 8 = %d beats." % [n, 8 * n])
		ex.data = {"kind": "phrase", "eights": n}
	elif level == 2:
		var dancer := rng.randi_range(3, 6)
		var gap := rng.randi_range(1, 4)
		var start := 1 + (dancer - 1) * gap
		ex = K.number("In a canon, dancer 1 starts on count 1, and each dancer starts %d count%s after the one before. On which count does dancer %d start?" % [
			gap, "" if gap == 1 else "s", dancer], str(start),
			"Between dancer 1 and dancer %d there is one gap fewer than the number of dancers." % dancer,
			"%d gaps of %d count%s: %d × %d = %d, so dancer %d starts on count 1 + %d = %d." % [dancer - 1, gap,
				"" if gap == 1 else "s", dancer - 1, gap, (dancer - 1) * gap, dancer, (dancer - 1) * gap, start])
		ex.data = {"kind": "canon", "dancer": dancer, "gap": gap}
	else:
		var form := "ABA" if rng.randf() < 0.5 else "ABACA"
		var lengths := {"A": 8 * rng.randi_range(1, 4), "B": 8 * rng.randi_range(1, 4), "C": 8 * rng.randi_range(1, 3)}
		var total := 0
		var parts: Array[String] = []
		for part in form:
			total += int(lengths[part])
			parts.append(str(lengths[part]))
		var said := "section A lasts %d counts and section B %d counts" % [lengths.A, lengths.B]
		if form == "ABACA":
			said = "section A lasts %d counts, section B %d and section C %d" % [lengths.A, lengths.B, lengths.C]
		ex = K.number("A group's dance has the form %s: %s. How many counts is the whole dance?" % [form, said], str(total),
			"Write each letter of the form as its counts, then add them all.",
			"%s: %s = %d counts." % [form, " + ".join(parts), total])
		ex.data = {"kind": "structure", "form": form, "lengths": lengths}
	return ex


## "Copy the rhythm" of a dance motif's claps: 4, 6 or 8 half-beat boxes, a clap first, at least two claps and a rest.
static func motif_claps(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n: int = [4, 6, 8][level - 1]
	var pattern := ""
	for _try in 50:
		pattern = "x"
		for i in n - 1:
			pattern += "x" if rng.randf() < 0.55 else "-"
		if pattern.count("x") >= 2 and pattern.count("-") >= 1:
			break
	if pattern.count("-") == 0:
		pattern = pattern.substr(0, n - 1) + "-"
	var boxes: Array[String] = []
	for i in n:
		if pattern[i] == "x":
			boxes.append(str(i + 1))
	var ex := {"type": "rhythm", "prompt": "Listen to the motif's claps, then copy its claps and rests in the boxes.",
		"hint": "Each box is half a beat. Listen for the gaps: they are rests.",
		"explain": "Claps in boxes %s, and rests in the others: %s." % [_and(boxes), pattern],
		"sound": {"kind": "rhythm", "pattern": pattern, "tempo": [80, 90, 100][rng.randi_range(0, 2)]}}
	ex.data = {"pattern": pattern}
	return ex


# --- Health and PE: personal best (g5.health_pe.personal_best) ----------------------------------------------------

## Level 1: the best of three jumps (the longest); level 2: a bar graph of four weeks' results, how much better; level 3:
## the best of three sprint times (the fastest) or the mean of three tries.
static func pb_best(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	if level == 1:
		var v: Array = []
		while v.size() < 3:
			var x := rng.randi_range(105, 185)
			if not v.has(x):
				v.append(x)
		ex = K.number("%s did three standing long jumps: %d cm, %d cm and %d cm. What is %s's personal best, in centimetres?" % [
			who, v[0], v[1], v[2], who], str(v.max()), "In a jump or a throw, the best try is the one that goes farthest.",
			"%d cm is the longest of the three: %s's personal best." % [v.max(), who])
		ex.data = {"kind": "longest", "values": v}
	elif level == 2:
		var what: Array = [["skips in 30 seconds", 5], ["catches in a row", 2], ["keepy-uppies", 2]][rng.randi_range(0, 2)]
		var step := int(what[1])
		var v: Array = []
		var x := rng.randi_range(2, 4) * step
		for i in 4:
			v.append(x)
			x += rng.randi_range(0, 2) * step
		if int(v[3]) == int(v[0]):
			v[3] = int(v[0]) + step
		var top := int(ceil(float(v.max()) / step)) * step
		top = maxi(top, step * 4)
		var bars: Array = []
		for i in 4:
			bars.append(["week %d" % (i + 1), v[i]])
		ex = K.number("The graph shows %s's %s each week. How many more were there in week 4 than in week 1?" % [who,
			str(what[0])], str(int(v[3]) - int(v[0])), "Read week 1's bar and week 4's bar on the scale, then find the difference.",
			"Week 4: %d. Week 1: %d. %d − %d = %d more." % [v[3], v[0], v[3], v[0], int(v[3]) - int(v[0])],
			{"kind": "bar_graph", "bars": bars, "step": step, "top": top, "name": str(what[0])})
		ex.data = {"kind": "improve", "values": v}
	elif rng.randf() < 0.5:
		var v: Array = []
		while v.size() < 3:
			var t := rng.randi_range(58, 75) / 10.0
			if not v.has(t):
				v.append(t)
		var right := "%.1f s" % v.min()
		var wrongs: Array = []
		for t: Variant in v:
			if t != v.min():
				wrongs.append("%.1f s" % float(t))
		wrongs.append("%.1f s" % (float(v.max()) + 0.3))
		ex = K.choice(rng, "%s ran 30 m three times, in %.1f s, %.1f s and %.1f s. Which is %s's personal best?" % [who,
			v[0], v[1], v[2], who], right, wrongs, "In a race, is the best time the biggest number or the smallest?",
			"%s: the fastest run takes the least time, so the smallest number is the best." % right)
		ex.data = {"kind": "fastest", "values": v}
	else:
		var mean := rng.randi_range(20, 60)
		var d := rng.randi_range(1, 6)
		var e := rng.randi_range(0, d)
		var v: Array = [mean - d, mean + d - e, mean + e]
		K.shuffle(rng, v)
		ex = K.number("%s held a plank three times: %d, %d and %d seconds. What is the mean (the average) time, in seconds?" % [
			who, v[0], v[1], v[2]], str(mean), "Add the three times, then share the total by 3.",
			"%d + %d + %d = %d, and %d ÷ 3 = %d seconds." % [v[0], v[1], v[2], mean * 3, mean * 3, mean])
		ex.data = {"kind": "mean", "values": v}
	return ex


## A goal and a plan. Level 1: how many more to reach the goal; level 2: how many weeks, adding the same each week; level
## 3: where the plan gets to after some weeks.
static func goal_plan(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var what: String = ["press-ups", "sit-ups", "skips", "star jumps", "catches"][rng.randi_range(0, 4)]
	var ex: Dictionary
	if level == 1:
		var now := rng.randi_range(8, 30)
		var goal := now + rng.randi_range(3, 15)
		ex = K.number("%s can do %d %s in a row now. The goal is %d. How many more does %s need?" % [who, now, what, goal, who],
			str(goal - now), "The gap between now and the goal: take the smaller number from the bigger.",
			"%d − %d = %d more." % [goal, now, goal - now])
		ex.data = {"kind": "more", "now": now, "goal": goal}
	elif level == 2:
		var step := rng.randi_range(2, 5)
		var weeks := rng.randi_range(2, 6)
		var now := rng.randi_range(8, 25)
		var goal := now + step * weeks
		ex = K.number("%s can do %d %s now. The plan adds %d more each week. How many weeks until %s reaches the goal of %d?" % [
			who, now, what, step, who, goal], str(weeks), "Find how many more are needed, then how many lots of the weekly step that is.",
			"%d − %d = %d more, and %d ÷ %d = %d weeks." % [goal, now, goal - now, goal - now, step, weeks])
		ex.data = {"kind": "weeks", "now": now, "goal": goal, "step": step}
	else:
		var now := rng.randi_range(20, 45)
		var step: int = [5, 5, 10][rng.randi_range(0, 2)]
		var weeks := rng.randi_range(3, 8)
		var then := now + step * weeks
		ex = K.number("%s can hold a plank for %d seconds. The plan adds %d seconds each week. How long can %s hold it after %d weeks, in seconds?" % [
			who, now, step, who, weeks], str(then), "Work out the seconds the plan adds in all those weeks, then add them to now.",
			"%d × %d = %d seconds more, and %d + %d = %d seconds." % [weeks, step, step * weeks, now, step * weeks, then])
		ex.data = {"kind": "after", "now": now, "step": step, "weeks": weeks}
	return ex


# --- Health and PE: medicines and harmful substances (g5.health_pe.medicines_harmful) -----------------------------

## Facts to check, true or false: level 1 medicines, level 2 tobacco and vaping, level 3 alcohol and the law (UK law,
## the UK Chief Medical Officers, the NHS). Each [statement, truth, hint, worked answer].
const FACTS := {
	1: [["You should only take a medicine that a trusted adult gives you.", true,
		"Who knows which medicine is right for you, and how much?",
		"True: a trusted adult, a doctor or a pharmacist makes sure it is the right medicine and the right amount."],
		["It is fine to take a friend's medicine if you feel ill in the same way.", false,
		"Is a medicine chosen for one person, or for anyone?",
		"False: a medicine is chosen for one person, at the right amount for them. Never take someone else's."],
		["A medicine's label tells you how much to take and how often.", true, "What is written on a medicine's box or bottle?",
		"True: the label, and the leaflet inside, say how much, how often and who it is for. A grown-up reads it."],
		["Some medicines and tablets can look like sweets.", true, "Why must you never eat tablets you find?",
		"True: so never take anything unless a trusted adult gives it to you."],
		["Medicines should be kept out of reach of young children.", true, "Where are medicines kept at home?",
		"True: up high or locked away, where small children cannot reach them."],
		["If one dose of a medicine helps, two doses will help twice as much.", false, "Can too much of a medicine harm you?",
		"False: too much medicine can make you very ill. Only the amount on the label, given by a trusted adult."],
		["A pharmacist is an expert in medicines who can give advice.", true, "Who works in a chemist's shop?",
		"True: pharmacists are trained in medicines. They can advise a grown-up about many common illnesses."]],
	2: [["Nicotine, which is in cigarettes and most vapes, is addictive.", true, "What does addictive mean?",
		"True: nicotine is addictive, so it is very hard to stop once you start. That is why it is best never to start."],
		["Smoking harms the heart and the lungs.", true, "What does breathing in smoke do to the parts that breathe and pump?",
		"True: smoking damages the lungs and the heart, and causes many cancers."],
		["Breathing in other people's smoke is harmless.", false, "Does smoke stay only with the person who smokes?",
		"False: second-hand smoke harms the people around, especially children. That is why smoking is banned indoors in public places."],
		["Vapes are made for children to try.", false, "Who are vapes meant for?",
		"False: vapes are only meant to help adults who smoke to stop smoking. They are not for children, or anyone who does not smoke."],
		["Most adults in the UK do not smoke.", true, "Think about the grown-ups you know.",
		"True: most adults do not smoke, and fewer people smoke every year."],
		["Tobacco smoke has thousands of chemicals in it, and many are harmful.", true, "Is smoke just air?",
		"True: tobacco smoke has thousands of chemicals, and about 70 of them can cause cancer."],
		["Smoking can make your teeth yellow and your breath smell.", true, "What does smoke leave behind in the mouth?",
		"True: tar in the smoke stains teeth and fingers, and makes breath and clothes smell."]],
	3: [["In the UK, it is against the law for a shop to sell alcohol to anyone under 18.", true,
		"At what age does the UK let shops sell alcohol to someone?",
		"True: shops may only sell alcohol to adults, 18 or over. Other countries have their own laws."],
		["In the UK, it is against the law to sell cigarettes or nicotine vapes to anyone under 18.", true,
		"Do the laws on cigarettes and vapes protect children?",
		"True: selling cigarettes or nicotine vapes to under-18s is against the law."],
		["Alcohol slows down how the brain and body work.", true, "What happens to people's balance and speech after a lot of alcohol?",
		"True: alcohol slows the brain, so people react more slowly and make riskier choices."],
		["Alcohol is especially harmful to young people, whose brains are still growing.", true,
		"Are children's bodies and brains finished growing?", "True: young bodies and brains are still growing, so alcohol harms them more."],
		["The UK's Chief Medical Officers advise that an alcohol-free childhood is the healthiest choice.", true,
		"What do the UK's top doctors say about children and alcohol?", "True: their advice is that an alcohol-free childhood is the healthiest and best."],
		["Too much alcohol can affect balance, speech and the choices people make.", true, "What does alcohol do to the brain?",
		"True: it slows the brain, so balance, speech and good choices all suffer."],
		["It is safe to drink from a bottle if you do not know what is in it.", false, "Could an unknown bottle hold something harmful?",
		"False: it could hold alcohol or a cleaning liquid. Never drink it: ask a trusted adult."],
		["If someone offers you a cigarette or a vape, you can say no.", true, "Whose body is it?",
		"True: you can always say no, walk away and tell a trusted adult. Real friends accept a no."]],
}


static func health_facts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var bank: Array = FACTS[level]
	var f: Array = bank[rng.randi_range(0, bank.size() - 1)]
	var ex := K.truefalse(str(f[0]), bool(f[1]), str(f[2]), str(f[3]))
	ex.data = {"statement": str(f[0])}
	return ex


# --- Health and PE: allergies and illness (g5.health_pe.allergies_illness) ----------------------------------------

## Foods made with each allergen, and plain foods with none of the UK's 14 labelled allergens.
const ALLERGEN_FOODS := {"milk": ["cheese", "butter", "yoghurt", "cream", "custard"],
	"eggs": ["mayonnaise", "meringue", "an omelette", "egg fried rice"],
	"peanuts": ["peanut butter", "satay sauce", "peanut brittle"],
	"wheat": ["bread", "pasta", "couscous", "a flour tortilla"],
	"sesame": ["tahini", "hummus made with tahini", "a bun with sesame seeds"],
	"fish": ["tuna", "salmon", "fish fingers", "anchovies"], "soya": ["tofu", "soy sauce", "edamame beans"]}
const ALLERGY_NAMES := {"milk": "a milk allergy", "eggs": "an egg allergy", "peanuts": "a peanut allergy",
	"wheat": "a wheat allergy", "sesame": "a sesame allergy", "fish": "a fish allergy", "soya": "a soya allergy"}
## Foods named in the plural ("carrots have"), for the worked answers' words.
const MANY: Array[String] = ["carrots", "potatoes", "peas", "grapes", "edamame beans", "anchovies", "fish fingers"]
const PLAIN_FOODS: Array[String] = ["rice", "an apple", "carrots", "a banana", "potatoes", "peas", "grapes", "cucumber",
	"an orange", "plain chicken"]


## Level 1: which food contains the allergen; level 2: which food is safe; level 3: sort foods by the allergen.
static func allergen_find(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var allergens := ALLERGEN_FOODS.keys()
	var allergen := str(allergens[rng.randi_range(0, allergens.size() - 1)])
	var has: Array = (ALLERGEN_FOODS[allergen] as Array).duplicate()
	var free: Array = PLAIN_FOODS.duplicate()
	K.shuffle(rng, has)
	K.shuffle(rng, free)
	var who := _who(rng)
	var ex: Dictionary
	if level == 1:
		ex = K.choice(rng, "%s has %s. Which of these foods has %s in it?" % [who, ALLERGY_NAMES[allergen], allergen],
			has[0], free.slice(0, 3), "Think about what each food is made from.",
			"%s %s %s in %s. The others have no %s in them." % [_cap(str(has[0])), _has(str(has[0])), allergen,
				_it(str(has[0])), allergen])
		ex.data = {"kind": "contains", "allergen": allergen}
	elif level == 2:
		var wrongs: Array = has.slice(0, 3)
		ex = K.choice(rng, "%s has %s. Which of these foods is safe for %s to eat?" % [who, ALLERGY_NAMES[allergen], who],
			free[0], wrongs, "Which foods are made with %s? The safe one has none." % allergen,
			"%s %s no %s in %s. %s all have %s in them." % [_cap(str(free[0])), _has(str(free[0])), allergen,
				_it(str(free[0])), _cap(_and(wrongs)), allergen])
		ex.data = {"kind": "safe", "allergen": allergen}
	else:
		var n_has := mini(3, has.size())
		var items: Array = []
		for i in n_has:
			items.append([has[i], 0])
		for i in 5 - n_has:
			items.append([free[i], 1])
		K.shuffle(rng, items)
		var short := allergen if allergen != "eggs" else "egg"
		ex = {"type": "sort", "prompt": "%s has %s. Sort the foods: which have %s in them?" % [who, ALLERGY_NAMES[allergen],
			allergen], "groups": ["has %s" % short, "no %s" % short], "items": items.map(func(it: Array) -> String:
				return str(it[0])), "answer": items.map(func(it: Array) -> int: return int(it[1])),
			"hint": "Think about what each food is made from. Check the ones made from %s first." % allergen,
			"explain": "With %s: %s. No %s: the others." % [allergen, _and(has.slice(0, n_has)), allergen]}
		ex.data = {"kind": "sort", "allergen": allergen}
	return ex


## A high temperature (a fever) in a child is 38 °C or more (NHS). Level 1: is this one high?; level 2: which one is
## high?; level 3: how much a temperature fell.
static func fever_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	if level == 1:
		var t := rng.randi_range(360, 396) / 10.0
		ex = K.truefalse("%s's temperature is %.1f °C. That is a high temperature." % [who, t], t >= 38.0,
			"Compare it with 38 °C: a high temperature is 38 °C or more.",
			"%s: %.1f °C is %s 38 °C." % ["True" if t >= 38.0 else "False", t, "at or above" if t >= 38.0 else "below"])
		ex.data = {"kind": "one", "temps": [t]}
	elif level == 2:
		var high := rng.randi_range(380, 398) / 10.0
		var temps: Array = [high]
		while temps.size() < 4:
			var t := rng.randi_range(360, 378) / 10.0
			if not temps.has(t):
				temps.append(t)
		var wrongs: Array = []
		for t: Variant in temps.slice(1):
			wrongs.append("%.1f °C" % float(t))
		ex = K.choice(rng, "Which of these is a high temperature for a child?", "%.1f °C" % high, wrongs,
			"A high temperature is 38 °C or more. Which one reaches 38?",
			"%.1f °C: it is 38 °C or more. The others are below 38 °C." % high)
		ex.data = {"kind": "which", "temps": temps}
	else:
		var a := rng.randi_range(381, 396)
		var b := rng.randi_range(365, 375)
		ex = K.number("%s's temperature was %.1f °C. After resting and drinking water, it was %.1f °C. By how many degrees did it fall?" % [
			who, a / 10.0, b / 10.0], _dec(a - b), "Take the lower temperature from the higher one, lining up the decimal points.",
			"%.1f − %.1f = %s degrees." % [a / 10.0, b / 10.0, _dec(a - b)])
		ex.data = {"kind": "fall", "temps": [a / 10.0, b / 10.0]}
	return ex


# --- Health and PE: sleep and screens (g5.health_pe.sleep_screens) -------------------------------------------------

## Times in minutes from midnight. Level 1: hours asleep; level 2: when to be asleep for the hours you need; level 3:
## when screens go off, an hour before that. The clock shows the time to wake up.
static func bedtime(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var wake: int = [6 * 60, 6 * 60 + 30, 7 * 60, 7 * 60 + 30, 8 * 60][rng.randi_range(0, 4)]
	var clock := {"kind": "digital_clock", "h": wake / 60, "m": wake % 60, "twelve": true}
	var ex: Dictionary
	if level == 1:
		wake = [6, 7, 8][rng.randi_range(0, 2)] * 60
		clock = {"kind": "digital_clock", "h": wake / 60, "m": 0, "twelve": true}
		var sleep := rng.randi_range(19, 21) * 60
		while (24 * 60 - sleep + wake) / 60 > 12:
			sleep += 60
		var hours := (24 * 60 - sleep + wake) / 60
		ex = K.number("%s falls asleep at %s and wakes up at the time on the clock. How many hours of sleep is that?" % [who,
			_clock(sleep)], str(hours), "Count the hours up to midnight, then the hours after midnight, and add them.",
			"From %s to midnight is %d hours, and from midnight to %s is %d more: %d + %d = %d hours." % [_clock(sleep),
				(24 * 60 - sleep) / 60, _clock(wake), wake / 60, (24 * 60 - sleep) / 60, wake / 60, hours], clock)
		ex.data = {"kind": "hours", "sleep": sleep, "wake": wake}
		return ex
	var need: int = [9 * 60, 9 * 60 + 30, 10 * 60, 10 * 60 + 30, 11 * 60][rng.randi_range(0, 4)]
	var asleep := wake - need
	var need_words := "%d%s hours" % [need / 60, " and a half" if need % 60 else ""]
	if level == 2:
		ex = K.choice(rng, "%s needs %s of sleep and wakes up at the time on the clock. By what time should %s be asleep?" % [
			who, need_words, who], _clock(asleep), [_clock(asleep + 60), _clock(asleep - 60), _clock(asleep + 30)],
			"Count back from the wake-up time: first back to midnight, then on into the evening.",
			"Back %s from %s is %s." % [need_words, _clock(wake), _clock(asleep)], clock)
		ex.data = {"kind": "asleep", "wake": wake, "need": need}
	else:
		ex = K.choice(rng, "%s needs %s of sleep and wakes up at the time on the clock. Screens go off an hour before sleep. When do screens go off?" % [
			who, need_words], _clock(asleep - 60), [_clock(asleep), _clock(asleep - 120), _clock(asleep - 30)],
			"First find when to be asleep, counting back from the wake-up time. Then go back one more hour.",
			"Asleep by %s (%s before %s), so screens off an hour earlier: %s." % [_clock(asleep), need_words, _clock(wake),
				_clock(asleep - 60)], clock)
		ex.data = {"kind": "screens", "wake": wake, "need": need}
	return ex


# --- Health and PE: orienteering (g5.health_pe.orienteering) -------------------------------------------------------

## Level 1: a simple scale (1 cm stands for 10-100 m); level 2: 1:5,000 or 1:10,000 with half centimetres; level 3: a
## real distance back to centimetres on the map.
static func map_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var per: int = [10, 20, 50, 100][rng.randi_range(0, 3)]
		var cm := rng.randi_range(2, 9)
		ex = K.number("On a map, 1 cm stands for %d m. Two controls are %d cm apart on the map. How far apart are they on the ground, in metres?" % [
			per, cm], str(cm * per), "Every centimetre on the map is the same distance on the ground: multiply.",
			"%d × %d = %d m." % [cm, per, cm * per])
		ex.data = {"kind": "to_ground", "cm": cm, "m_per_cm": per, "metres": cm * per}
	else:
		var scale: int = [5000, 10000][rng.randi_range(0, 1)]
		var per := scale / 100
		var halves := rng.randi_range(3, 17)
		var cm := halves / 2.0
		var metres := int(cm * per)
		var name := "1:5,000" if scale == 5000 else "1:10,000"
		if level == 2:
			ex = K.number("An orienteering map has a scale of %s, so 1 cm on the map is %d m on the ground. A leg is %s cm long on the map. How long is it on the ground, in metres?" % [
				name, per, _half(cm)], str(metres), "Multiply the centimetres by the metres each centimetre stands for.",
				"%s × %d = %d m." % [_half(cm), per, metres])
			ex.data = {"kind": "to_ground", "cm": cm, "m_per_cm": per, "metres": metres}
		else:
			ex = K.number("On a %s map, 1 cm stands for %d m. A path is %d m long. How long is it on the map, in centimetres?" % [
				name, per, metres], _half(cm), "How many lots of %d m fit into %d m?" % [per, metres],
				"%d ÷ %d = %s cm on the map." % [metres, per, _half(cm)])
			ex.data = {"kind": "to_map", "cm": cm, "m_per_cm": per, "metres": metres}
	return ex


## Pace counting: a pace is two steps (each time the same foot lands). Level 1: paces for 200-400 m; level 2: for 50,
## 150 or 250 m; level 3: metres from a count of paces.
static func pace_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var per: int = [60, 64, 66, 70, 72, 76, 80][rng.randi_range(0, 6)]
	var metres: int = [[200, 300, 400], [50, 150, 250], [50, 150, 200, 250, 350]][level - 1][rng.randi_range(0,
		[2, 2, 4][level - 1])]
	var paces := per * metres / 100
	var ex: Dictionary
	if level < 3:
		ex = K.number("%s counts %d paces to walk 100 m. How many paces will %s count to walk %d m?" % [who, per, who,
			metres], str(paces), "How many lots of 100 m is it? Halves count too.",
			"%d m is %s lots of 100 m: %s × %d = %d paces." % [metres, _half(metres / 100.0), _half(metres / 100.0), per,
				paces])
		ex.data = {"kind": "paces", "per100": per, "metres": metres, "paces": paces}
	else:
		ex = K.number("%s counts %d paces to walk 100 m. On the course, %s counted %d paces from one control to the next. How far was that, in metres?" % [
			who, per, who, paces], str(metres), "How many lots of %d paces are in %d? Each lot is 100 m." % [per, paces],
			"%d ÷ %d = %s, and %s × 100 = %d m." % [paces, per, _half(metres / 100.0), _half(metres / 100.0), metres])
		ex.data = {"kind": "metres", "per100": per, "metres": metres, "paces": paces}
	return ex


const COMPASS_POINTS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const POINT_NAMES := {"N": "north", "NE": "north-east", "E": "east", "SE": "south-east", "S": "south",
	"SW": "south-west", "W": "west", "NW": "north-west"}


## Bearings: degrees clockwise from north. Level 1: the direction an arrow points; level 2: a point's bearing, or the
## point of a bearing; level 3: a new bearing after turning.
static func bearing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var i := rng.randi_range(0, 7)
	var point := COMPASS_POINTS[i]
	var deg := i * 45
	var others: Array = COMPASS_POINTS.duplicate()
	others.erase(point)
	K.shuffle(rng, others)
	var ex: Dictionary
	if level == 1:
		ex = K.choice(rng, "Which direction does the orange arrow point?", point, others.slice(0, 3),
			"Start at N, at the top, and go round clockwise: N, NE, E, SE, S, SW, W, NW.",
			"%s: the arrow points %s." % [point, POINT_NAMES[point]], {"kind": "compass", "points": 8, "bearing": deg})
		ex.data = {"kind": "name", "point": point}
	elif level == 2:
		if rng.randf() < 0.5:
			ex = K.number("A bearing is measured clockwise from north, in degrees. What is the bearing of %s (%s)?" % [
				POINT_NAMES[point], point], str(deg), "North is 0°, east 90°, south 180° and west 270°. The points between are halfway.",
				"%s is %d × 45° = %d° clockwise from north." % [point, i, deg])
			ex.data = {"kind": "degrees", "point": point}
		else:
			ex = K.choice(rng, "Which direction is a bearing of %d°?" % deg, point, others.slice(0, 3),
				"Each of the 8 points is 45° round from the one before, starting at north, 0°.",
				"%d° is %d × 45°: %s (%s)." % [deg, i, point, POINT_NAMES[point]])
			ex.data = {"kind": "point", "point": point, "bearing": deg}
	else:
		var turn: int = [90, -90, 180, 45, -45][rng.randi_range(0, 4)]
		var words := {90: "turn right by 90°", -90: "turn left by 90°", 180: "turn round to walk the opposite way",
			45: "turn right by 45°", -45: "turn left by 45°"}
		var after := posmod(deg + turn, 360)
		ex = K.number("You are walking on a bearing of %d°. You %s. What is your new bearing, in degrees?" % [deg,
			words[turn]], str(after), "Turning right adds to a bearing; turning left takes away. Past 360°, start again at 0°.",
			"%d° %s %d° = %s°%s." % [deg, "+" if turn > 0 else "−", absi(turn), _minus(deg + turn),
				"" if deg + turn == after else ", which is %d°" % after])
		ex.data = {"kind": "turn", "bearing": deg, "turn": turn}
	return ex


# --- Design and technology: gears and pulleys (g5.design_tech.gears_pulleys) --------------------------------------

## Two meshing gears: the teeth that pass are the same for both. Level 1: turns of the small driver to turn the big gear
## once; level 2: the big gear's turns (slower); level 3: a big driver turning a small gear (faster).
static func gear_turns(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var small: int = [8, 10, 12][rng.randi_range(0, 2)]
	var k := rng.randi_range(2, 3 if small == 12 else 4)
	var big := small * k
	var ex: Dictionary
	if level == 1:
		ex = K.number("The small gear has %d teeth and drives the big gear, which has %d teeth. How many times must the small gear turn to turn the big gear once?" % [
			small, big], str(k), "In one turn of the big gear, all its teeth pass. How many turns of the small gear is that many teeth?",
			"%d ÷ %d = %d turns of the small gear." % [big, small, k], {"kind": "gears", "gears": [small, big], "turn": "cw"})
		ex.data = {"driver": small, "driven": big, "driver_turns": k, "driven_turns": 1, "ask": "driver"}
	elif level == 2:
		var m := rng.randi_range(1, 4)
		ex = K.number("A driver gear with %d teeth turns %d times. It drives a gear with %d teeth. How many times does that gear turn?" % [
			small, k * m, big], str(m), "Find how many teeth pass, then how many turns of the bigger gear that is.",
			"%d × %d = %d teeth pass, and %d ÷ %d = %d turn%s. A big driven gear turns slower." % [k * m, small, k * m * small,
				k * m * small, big, m, "" if m == 1 else "s"], {"kind": "gears", "gears": [small, big], "turn": "cw", "labels": ["driver", "driven"]})
		ex.data = {"driver": small, "driven": big, "driver_turns": k * m, "driven_turns": m, "ask": "driven"}
	else:
		var t := rng.randi_range(2, 5)
		ex = K.number("A big driver gear with %d teeth turns a small gear with %d teeth. The big gear turns %d times. How many times does the small gear turn?" % [
			big, small, t], str(t * k), "Find how many teeth pass, then how many turns of the small gear that is.",
			"%d × %d = %d teeth pass, and %d ÷ %d = %d turns. A small driven gear turns faster." % [t, big, t * big, t * big,
				small, t * k], {"kind": "gears", "gears": [big, small], "turn": "cw", "labels": ["driver", "driven"]})
		ex.data = {"driver": big, "driven": small, "driver_turns": t, "driven_turns": t * k, "ask": "driven"}
	return ex


## Which way the last gear turns (meshing gears turn opposite ways): 2, 3 or 4 gears; at level 3 sometimes two pulleys on
## a belt instead (an open belt turns both the same way, a crossed belt opposite ways).
static func gear_direction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var cw := rng.randf() < 0.5
	var first := "clockwise" if cw else "anticlockwise"
	var other := "anticlockwise" if cw else "clockwise"
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.4:
		var crossed := rng.randf() < 0.5
		var sizes: Array = [rng.randi_range(2, 5), rng.randi_range(2, 6)]
		var last := other if crossed else first
		ex = K.choice(rng, "Pulley A turns %s. A belt%s joins it to pulley B. Which way does pulley B turn?" % [first,
			" that crosses over in the middle" if crossed else ""], last, [other if last == first else first],
			"Follow the belt: does it keep going the same way round, or does it cross over?",
			"%s: %s." % [_cap(last), "a crossed belt turns the second pulley the opposite way" if crossed else "an open belt turns both pulleys the same way"],
			{"kind": "pulleys", "sizes": sizes, "turn": "cw" if cw else "acw", "crossed": crossed, "labels": ["A", "B"]})
		ex.data = {"kind": "pulleys", "first": first, "crossed": crossed}
		return ex
	var n := level + 1 if level < 3 else rng.randi_range(3, 4)
	var teeth: Array = []
	for i in n:
		teeth.append([10, 12, 16, 20, 24][rng.randi_range(0, 4)])
	var last := first if n % 2 == 1 else other
	ex = K.choice(rng, "The first gear turns %s, as its arrow shows. Which way does the last gear turn?" % first, last,
		[first if last == other else other],
		"Meshing gears turn opposite ways. Go along the row, changing direction at each gear.",
		"%s: the %d gears turn %s." % [_cap(last), n, ", ".join(range(n).map(func(k: int) -> String:
			return first if k % 2 == 0 else other))],
		{"kind": "gears", "gears": teeth, "turn": "cw" if cw else "acw"})
	ex.data = {"kind": "gears", "n": n, "first": first}
	return ex


# --- Design and technology: cams (g5.design_tech.cams_toys) --------------------------------------------------------

const CAM_WORDS := {"round": "round (off-centre)", "pear": "pear-shaped", "snail": "snail", "oval": "oval"}


## Level 1: rises of a follower on a round, pear or snail cam (once a turn); level 2: on an oval cam (twice a turn); level
## 3: how high the follower rises: the cam's farthest edge from the axle less its nearest.
static func cam_rises(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var shape: String = ["round", "pear", "snail"][rng.randi_range(0, 2)] if level == 1 else "oval"
		var turns := rng.randi_range(2, 9)
		var each := 2 if shape == "oval" else 1
		ex = K.number("The handle turns this %s cam %d times. How many times does the follower rise?" % [CAM_WORDS[shape],
			turns], str(each * turns), "How many times does the follower go up in one turn of this shape of cam?",
			"%s %s cam lifts the follower %s each turn: %d × %d = %d rises." % ["An" if shape == "oval" else "A", CAM_WORDS[shape],
				"twice" if each == 2 else "once", turns, each, each * turns],
			{"kind": "cam", "shape": shape, "turn": rng.randi_range(0, 11) * 30})
		ex.data = {"kind": "rises", "shape": shape, "turns": turns}
	else:
		var near := rng.randi_range(4, 8) * 0.5
		var far := near + rng.randi_range(2, 6) * 0.5
		ex = K.number("A cam's edge is %s cm from its axle at the nearest point and %s cm at the farthest. How far does the follower rise and fall, in cm?" % [
			_half(near), _half(far)], _half(far - near), "The follower rides from the nearest edge to the farthest: find the difference.",
			"%s − %s = %s cm." % [_half(far), _half(near), _half(far - near)],
			{"kind": "cam", "shape": "round", "labels": true})
		ex.data = {"kind": "lift", "near": near, "far": far}
	return ex


# --- Design and technology: bridges (g5.design_tech.bridges) -------------------------------------------------------

## A beam bridge's spans and piers. Level 1: spans across a river; level 2: piers in the river (one fewer than spans:
## the ends rest on the banks); level 3: piers from their spacing.
static func bridge_piers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var span: int = [10, 12, 15, 20, 25][rng.randi_range(0, 4)]
	var spans := rng.randi_range(2, 4) if level < 3 else rng.randi_range(4, 7)
	var length := span * spans
	var pic := {"kind": "bridge", "type": "beam", "spans": spans} if spans <= 4 else {}
	var ex: Dictionary
	if level == 1:
		ex = K.number("A beam bridge crosses a river %d m wide. Each span is %d m long. How many spans does it need?" % [
			length, span], str(spans), "How many lots of %d m make %d m?" % [span, length],
			"%d ÷ %d = %d spans." % [length, span, spans], pic)
		ex.data = {"kind": "spans", "length": length, "span": span}
	elif level == 2:
		ex = K.number("A beam bridge crosses a river %d m wide in spans of %d m. Its two ends rest on the banks. How many piers stand in the river?" % [
			length, span], str(spans - 1), "Find the spans first. A pier stands between each span and the next.",
			"%d ÷ %d = %d spans, and between %d spans there %s." % [length, span, spans, spans,
				"is 1 pier" if spans == 2 else "are %d piers" % (spans - 1)], pic)
		ex.data = {"kind": "piers", "length": length, "span": span}
	else:
		ex = K.number("A long beam bridge crosses %d m of water with a pier every %d m, and its ends rest on the banks. How many piers does it need?" % [
			length, span], str(spans - 1), "Work out the spans, then remember the ends need no pier.",
			"%d ÷ %d = %d spans, so %d − 1 = %d piers." % [length, span, spans, spans, spans - 1])
		ex.data = {"kind": "piers", "length": length, "span": span}
	return ex


## A table of bridge tests. Level 1: which held the most washers; level 2: a load in grams; level 3: which held the most
## for its own mass (a clear winner, never simply the one with the biggest load).
static func bridge_test(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := ["A", "B", "C"]
	var ex: Dictionary
	if level == 1:
		var held: Array = []
		while held.size() < 3:
			var x := rng.randi_range(6, 30)
			if not held.has(x):
				held.append(x)
		var rows: Array = [["bridge", "washers held"]]
		var data_rows: Array = []
		for i in 3:
			rows.append([names[i], str(held[i])])
			data_rows.append([names[i], held[i]])
		var best: String = names[held.find(held.max())]
		ex = K.choice(rng, "The table shows how many washers each paper bridge held before it sagged too far. Which bridge was strongest?",
			best, names.filter(func(n: String) -> bool: return n != best), "Find the biggest number in the washers column.",
			"Bridge %s held %d washers, the most." % [best, held.max()], {"kind": "table", "rows": rows})
		ex.data = {"kind": "most", "rows": data_rows}
	elif level == 2:
		var washers := rng.randi_range(8, 40)
		var each: int = [5, 10, 20, 25][rng.randi_range(0, 3)]
		ex = K.number("Bridge %s held %d washers before it sagged. Each washer has a mass of %d g. What load did it hold, in grams?" % [
			names[rng.randi_range(0, 2)], washers, each], str(washers * each), "The same mass for every washer: multiply.",
			"%d × %d = %d g." % [washers, each, washers * each])
		ex.data = {"kind": "grams", "washers": washers, "each": each}
	else:
		for _try in 200:
			var rows: Array = []
			for i in 3:
				var own := rng.randi_range(4, 12) * 10
				var times := rng.randi_range(8, 30)
				rows.append([names[i], own, own * times])
			var ratio := rows.map(func(r: Array) -> float: return float(r[2]) / float(r[1]))
			var top: int = ratio.find(ratio.max())
			var loads := rows.map(func(r: Array) -> int: return int(r[2]))
			var clear := true
			for i in 3:
				if i != top and float(ratio[top]) - float(ratio[i]) < 3.0:
					clear = false
			if not clear or int(loads.find(loads.max())) == top:
				continue
			var table: Array = [["bridge", "its own mass", "load held"]]
			for r: Array in rows:
				table.append([str(r[0]), "%d g" % int(r[1]), "%s g" % K.fmt(int(r[2]))])
			var best := str(rows[top][0])
			ex = K.choice(rng, "Engineers want a bridge that holds the most for its own mass. Which bridge is best, by the table?",
				best, names.filter(func(n: String) -> bool: return n != best),
				"For each bridge, how many times its own mass did it hold? Divide the load by its own mass.",
				"Bridge %s held %d times its own mass (%s ÷ %d). %s" % [best, int(ratio[top]), K.fmt(int(rows[top][2])),
					int(rows[top][1]), "The others held %d and %d times theirs." % _others(ratio, top)],
				{"kind": "table", "rows": table})
			ex.data = {"kind": "ratio", "rows": rows}
			return ex
	return ex


static func _others(ratio: Array, top: int) -> Array:
	var out: Array = []
	for i in ratio.size():
		if i != top:
			out.append(int(ratio[i]))
	return out


# --- Design and technology: design on screen (g5.design_tech.design_on_screen) -------------------------------------

## A block model (stacks of 0-3 blocks on a 2-3 by 2-4 base). Level 1: count its blocks from the plan's numbers;
## level 2: pick its front view; level 3: pick its side view (from the right). The views are drawn as their columns.
static func block_views(rng: RandomNumberGenerator, level: int) -> Dictionary:
	for _try in 300:
		var depth := rng.randi_range(2, 3)
		var cols := rng.randi_range(2, 4) if level > 1 else rng.randi_range(3, 4)
		var rows: Array = []
		var total := 0
		for i in depth:
			var row := ""
			for c in cols:
				var h := rng.randi_range(0, 3)
				row += str(h)
				total += h
			rows.append(row)
		if total < 4:
			continue
		var front := _digits(SchoolPictureG5Life.front_view(rows))
		var side := _digits(SchoolPictureG5Life.side_view(rows))
		if level == 1:
			var ex := K.number("This plan shows a model from above. Each number is how many blocks are stacked there. How many blocks are in the model?",
				str(total), "Add up all the numbers on the plan: each one is a stack.",
				"%s = %d blocks." % [" + ".join(_chars(_join(rows)).filter(func(ch: String) -> bool: return ch != "0")),
					total], {"kind": "views", "heights": rows, "show": "plan", "numbers": true, "label": true})
			ex.data = {"kind": "count", "heights": rows}
			return ex
		var want := front if level == 2 else side
		var other := side if level == 2 else front
		var wrongs: Array = []
		for w: String in [other, _rev(want), _bump(want, rng)]:
			if w != want and not wrongs.has(w) and w.replace("0", "") != "":
				wrongs.append(w)
		if wrongs.size() < 2 or want == other:
			continue
		var pic := func(w: String) -> Dictionary: return {"picture": {"kind": "views", "heights": [w], "show": "front"}}
		var ex := K.choice(rng, "Here is a model of blocks. Which is its %s?" % ("front view" if level == 2 else
			"side view, seen from the right"), pic.call(want), wrongs.map(pic), "For each column you see, find the tallest stack in it."
			if level == 2 else "Stand on the right: the front row is on your left. Find the tallest stack in each row.",
			"Its %s shows the tallest stack in each %s: %s blocks high." % ["front view" if level == 2 else "side view",
				"column, left to right" if level == 2 else "row, from front to back", ", ".join(_chars(want))],
			{"kind": "views", "heights": rows, "show": "model"})
		ex.data = {"kind": "front" if level == 2 else "side", "heights": rows}
		return ex
	return {}


static func _digits(a: Array) -> String:
	var out := ""
	for x: Variant in a:
		out += str(int(x))
	return out


## `w` with one column one block taller or shorter (0-3).
static func _bump(w: String, rng: RandomNumberGenerator) -> String:
	var i := rng.randi_range(0, w.length() - 1)
	var h := int(w[i])
	var nh := h + 1 if h < 3 and (h == 0 or rng.randf() < 0.5) else h - 1
	return w.substr(0, i) + str(nh) + w.substr(i + 1)


## Scale drawings. Level 1: 1 cm stands for 2-5 m; level 2: 1:20, 1:50 or 1:100 to real centimetres, or metres; level 3:
## a real length back to the drawing.
static func scale_drawing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var per := rng.randi_range(2, 5)
		var cm := rng.randi_range(2, 9)
		ex = K.number("On a blueprint, 1 cm stands for %d m. A wall is %d cm long on the blueprint. How long is the real wall, in metres?" % [
			per, cm], str(per * cm), "Each centimetre on the drawing is %d m for real: multiply." % per,
			"%d × %d = %d m." % [cm, per, cm * per])
		ex.data = {"kind": "to_real", "scale": per * 100, "draw_cm": cm, "real_cm": per * cm * 100, "unit": 100}
	elif level == 2:
		var scale: int = [20, 50, 100][rng.randi_range(0, 2)]
		var cm := rng.randi_range(2, 9)
		var metres := rng.randf() < 0.5 and scale >= 50
		var real := scale * cm
		ex = K.number("A drawing has a scale of 1:%d: every 1 cm on it is %d cm for real. A table is %d cm long on the drawing. How long is the real table, in %s?" % [
			scale, scale, cm, "metres" if metres else "centimetres"], _dec10(real / 10) if metres else str(real),
			"Multiply by %d to find the real centimetres%s." % [scale, ", then 100 cm make 1 m" if metres else ""],
			"%d × %d = %d cm%s." % [cm, scale, real, (", which is %s m" % _dec10(real / 10)) if metres else ""])
		ex.data = {"kind": "to_real", "scale": scale, "draw_cm": cm, "real_cm": real, "unit": 100 if metres else 1}
	else:
		var scale: int = [10, 20, 50][rng.randi_range(0, 2)]
		var cm := rng.randi_range(2, 12)
		var real := scale * cm
		ex = K.number("At a scale of 1:%d, how long should a %s m shelf be drawn, in centimetres?" % [scale, _dec10(real / 10)],
			str(cm), "Change the metres into centimetres, then share by %d." % scale,
			"%s m is %d cm, and %d ÷ %d = %d cm on the drawing." % [_dec10(real / 10), real, real, scale, cm])
		ex.data = {"kind": "to_drawing", "scale": scale, "draw_cm": cm, "real_cm": real}
	return ex


# --- Design and technology: control it with code (g5.design_tech.control_with_code) --------------------------------

## sensor, what it compares with ("<" or ">"), the output, and a range of readings.
const SENSORS: Array = [["light", "<", "night light", "LED", 20, 60], ["temperature", ">", "fan", "fan", 20, 30],
	["distance", "<", "parking sensor", "buzzer", 10, 50], ["moisture", "<", "plant waterer", "pump", 20, 60]]


## A program that controls a model. Level 1: true or false, is the output on?; level 2: on or off?; level 3: how long a
## loop of flashes takes.
static func control_trace(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var repeats := rng.randi_range(3, 8)
		var on := rng.randi_range(1, 3)
		var off := rng.randi_range(1, 3)
		var lines := ["REPEAT %d" % repeats, "  LED ON", "  WAIT %d" % on, "  LED OFF", "  WAIT %d" % off]
		ex = K.number("This program flashes a light. WAIT 1 means wait 1 second. How many seconds does the program take to run?",
			str(repeats * (on + off)), "Find the seconds for one time round the loop, then times by how many repeats.",
			"One time round: %d + %d = %d seconds. %d × %d = %d seconds." % [on, off, on + off, repeats, on + off,
				repeats * (on + off)], {"kind": "code", "lines": lines})
		ex.data = {"kind": "loop", "repeats": repeats, "on": on, "off": off}
		return ex
	var s: Array = SENSORS[rng.randi_range(0, SENSORS.size() - 1)]
	var threshold := rng.randi_range(int(s[4]), int(s[5]))
	var reading := threshold
	while reading == threshold:
		reading = rng.randi_range(maxi(0, threshold - 15), threshold + 15)
	var lines := ["FOREVER", "  IF %s %s %d" % [s[0], s[1], threshold], "    %s ON" % s[3], "  ELSE", "    %s OFF" % s[3]]
	var on: bool = reading < threshold if str(s[1]) == "<" else reading > threshold
	var word := "less than" if str(s[1]) == "<" else "more than"
	var why := "%d is %s %d" % [reading, word if on else ("not " + word), threshold]
	var pic := {"kind": "code", "lines": lines, "mark": 1}
	if level == 1:
		ex = K.truefalse("This program runs a %s. Its %s sensor reads %d. The %s is on." % [s[2], s[0], reading, s[3]], on,
			"Check the IF line: is the reading %s %d?" % [word, threshold],
			"%s: %s, so the program %s." % ["True" if on else "False", why, "turns it ON" if on else "goes to ELSE: OFF"], pic)
	else:
		ex = K.choice(rng, "This program runs a %s. Its %s sensor reads %d. Is the %s on or off?" % [s[2], s[0], reading,
			s[3]], "on" if on else "off", ["off" if on else "on"], "Put the reading into the IF line. Is it true?",
			"%s: %s, so the program runs %s." % ["On" if on else "Off", why, "the IF part" if on else "the ELSE part"], pic)
	ex.data = {"kind": "if", "sensor": str(s[0]), "op": str(s[1]), "threshold": threshold, "reading": reading}
	return ex


# --- Design and technology: seasonal cooking (g5.design_tech.seasonal_cooking) -------------------------------------

## Savoury dishes for 4 in season in the UK: [dish, [[ingredient, amount, unit]]] (every amount a multiple of 4).
const RECIPES: Array = [["leek and potato soup", [["leeks", 4, ""], ["potatoes", 800, " g"], ["vegetable stock", 1200, " mL"]]],
	["pumpkin soup", [["pumpkin", 800, " g"], ["garlic cloves", 4, ""], ["vegetable stock", 800, " mL"]]],
	["pea and mint soup", [["peas", 600, " g"], ["mint leaves", 12, ""], ["vegetable stock", 800, " mL"]]],
	["courgette and tomato pasta", [["pasta", 400, " g"], ["courgettes", 4, ""], ["tomatoes", 8, ""]]],
	["asparagus omelette", [["eggs", 8, ""], ["asparagus spears", 16, ""], ["grated cheese", 100, " g"]]],
	["roasted roots", [["parsnips", 4, ""], ["carrots", 8, ""], ["olive oil", 40, " mL"]]]]


## Scaling a recipe for 4. Level 1: for 8 or 2; level 2: for 6; level 3: for 10 or 3.
static func recipe_servings(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var r: Array = RECIPES[rng.randi_range(0, RECIPES.size() - 1)]
	var item: Array = r[1][rng.randi_range(0, 2)]
	var target: int = [[8, 2], [6, 6], [10, 3]][level - 1][rng.randi_range(0, 1)]
	var amount := int(item[1])
	if target == 10 and amount % 2 != 0:
		target = 8
	var result := amount * target / 4
	var unit := str(item[2])
	var how := {8: "double it", 2: "halve it", 6: "find half as much again and add it", 10: "double it, then add half as much again",
		3: "find a quarter and take it away"}
	var uses := ("%d%s of %s" % [amount, unit, item[0]]) if unit != "" else "%d %s" % [amount, item[0]]
	var factor := _num_text(target / 4.0)
	var ex := K.number("A recipe for %s serves 4 people and uses %s. How %s for %d people?" % [r[0], uses,
		"much" if unit != "" else "many", target], str(result), "Compare %d people with 4 people: %s." % [target, how[target]],
		"%d people is %s times 4, so %s × %s = %s%s." % [target, factor, K.fmt(amount), factor, K.fmt(result), unit])
	ex.data = {"recipe": str(r[0]), "item": str(item[0]), "amount": amount, "base": 4, "target": target}
	return ex


## When foods are in season in the UK.
const SEASON_FOODS := {"spring": ["asparagus", "rhubarb", "wild garlic"],
	"summer": ["strawberries", "raspberries", "peas", "broad beans", "courgettes", "cherries"],
	"autumn": ["apples", "pears", "pumpkins", "butternut squash"],
	"winter": ["leeks", "parsnips", "Brussels sprouts", "kale", "swede"]}
const SEASONS: Array[String] = ["spring", "summer", "autumn", "winter"]


## Level 1: which food is in season now; level 2: when a food is in season; level 3: sort foods into two seasons.
static func season_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var season := SEASONS[rng.randi_range(0, 3)]
	var mine: Array = (SEASON_FOODS[season] as Array).duplicate()
	K.shuffle(rng, mine)
	var ex: Dictionary
	if level == 1:
		var wrongs: Array = []
		for s in SEASONS:
			if s != season:
				var list: Array = SEASON_FOODS[s]
				wrongs.append(list[rng.randi_range(0, list.size() - 1)])
		ex = K.choice(rng, "Which of these is in season in the UK in %s?" % season, mine[0], wrongs,
			"Think of each food growing outside. When is it ready to pick in the UK?",
			"%s: ready in %s. The others are ready in %s." % [_cap(str(mine[0])), season, _and(wrongs.map(
				func(f: String) -> String: return _season_of(f)))])
		ex.data = {"kind": "food", "season": season}
	elif level == 2:
		var food := str(mine[0])
		ex = K.choice(rng, "In the UK, in which season is this food in season: %s?" % food, season, SEASONS.filter(
			func(s: String) -> bool: return s != season), "Picture the weather when this food is picked outside in the UK.",
			"%s: in season in %s in the UK." % [_cap(food), season])
		ex.data = {"kind": "season", "food": food}
	else:
		var other := SEASONS[(SEASONS.find(season) + rng.randi_range(1, 3)) % 4]
		var theirs: Array = (SEASON_FOODS[other] as Array).duplicate()
		K.shuffle(rng, theirs)
		var items: Array = []
		for f: Variant in mine.slice(0, mini(3, mine.size())):
			items.append([f, 0])
		for f: Variant in theirs.slice(0, 5 - items.size()):
			items.append([f, 1])
		K.shuffle(rng, items)
		ex = {"type": "sort", "prompt": "Sort these foods by when they are in season in the UK.", "groups": [season, other],
			"items": items.map(func(it: Array) -> String: return str(it[0])),
			"answer": items.map(func(it: Array) -> int: return int(it[1])),
			"hint": "Think of each food growing outside: is it ready in %s or in %s?" % [season, other],
			"explain": "%s: %s. %s: %s." % [_cap(season), _and(items.filter(func(it: Array) -> bool: return int(it[1]) == 0).map(
				func(it: Array) -> String: return str(it[0]))), _cap(other), _and(items.filter(func(it: Array) -> bool:
					return int(it[1]) == 1).map(func(it: Array) -> String: return str(it[0])))]}
		ex.data = {"kind": "sort"}
	return ex


static func _season_of(food: String) -> String:
	for s: String in SEASON_FOODS:
		if (SEASON_FOODS[s] as Array).has(food):
			return s
	return ""


## Cooking times. Level 1: the total minutes; level 2: when it is ready; level 3: when to start.
static func cook_timing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var dish := str(RECIPES[rng.randi_range(0, RECIPES.size() - 1)][0])
	var prep: int = [10, 15, 20][rng.randi_range(0, 2)]
	var cook: int = [20, 25, 30, 35, 40, 45][rng.randi_range(0, 5)]
	var ex: Dictionary
	if level == 1:
		ex = K.number("Making the %s: %d minutes to get it ready and %d minutes to cook it. How many minutes is that altogether?" % [
			dish, prep, cook], str(prep + cook), "Add the time to get ready and the time to cook.",
			"%d + %d = %d minutes." % [prep, cook, prep + cook])
		ex.data = {"kind": "total", "prep": prep, "cook": cook}
	elif level == 2:
		var start := (17 * 60) + rng.randi_range(0, 7) * 5
		var ready := start + prep + cook
		ex = K.choice(rng, "You start making the %s at %s. It takes %d minutes to get ready and %d minutes to cook. When will it be ready?" % [
			dish, _clock(start), prep, cook], _clock(ready), [_clock(ready + 10), _clock(ready - 10), _clock(start + cook)],
			"Find the total minutes, then count on from the start time. 60 minutes make an hour.",
			"%d + %d = %d minutes, and %d minutes after %s is %s." % [prep, cook, prep + cook, prep + cook, _clock(start),
				_clock(ready)])
		ex.data = {"kind": "ready", "prep": prep, "cook": cook, "start": start}
	else:
		var ready := (18 * 60) + rng.randi_range(0, 4) * 15
		var start := ready - prep - cook
		ex = K.choice(rng, "You want to eat the %s at %s. It takes %d minutes to get ready and %d minutes to cook. When must you start?" % [
			dish, _clock(ready), prep, cook], _clock(start), [_clock(start + 10), _clock(start - 10), _clock(ready - cook)],
			"Find the total minutes, then count back from the time you want to eat.",
			"%d + %d = %d minutes, and %d minutes before %s is %s." % [prep, cook, prep + cook, prep + cook, _clock(ready),
				_clock(start)])
		ex.data = {"kind": "start", "prep": prep, "cook": cook, "ready": ready}
	return ex


# --- Design and technology: reuse and redesign (g5.design_tech.reuse_redesign) -----------------------------------

const MAKES: Array = [["planter", "plastic bottles"], ["pencil pot", "tins"], ["bird feeder", "juice cartons"],
	["draught stopper", "old socks"], ["bag", "old T-shirts"]]


## Level 1: things made from a stack of waste, no leftovers; level 2: whole things, with some left over; level 3: waste
## collected over weeks.
static func reuse_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var m: Array = MAKES[rng.randi_range(0, MAKES.size() - 1)]
	var per := rng.randi_range(2, 5)
	var ex: Dictionary
	if level == 1:
		var n := rng.randi_range(3, 9)
		ex = K.number("Each %s is made from %d %s. The class has %d %s. How many can they make?" % [m[0], per, m[1], per * n,
			m[1]], str(n), "How many lots of %d are in %d?" % [per, per * n], "%d ÷ %d = %d." % [per * n, per, n])
		ex.data = {"have": per * n, "per": per}
	elif level == 2:
		var n := rng.randi_range(3, 9)
		var left := rng.randi_range(1, per - 1)
		var have := per * n + left
		ex = K.number("Each %s is made from %d %s. The class has %d %s. How many whole ones can they make?" % [m[0], per, m[1],
			have, m[1]], str(n), "Share %d into lots of %d. What is left over cannot make a whole one." % [have, per],
			"%d ÷ %d = %d, with %d left over: %d whole ones." % [have, per, n, left, n])
		ex.data = {"have": have, "per": per}
	else:
		var weekly := rng.randi_range(3, 12)
		var weeks := rng.randi_range(2, 4)
		var have := weekly * weeks
		var n := have / per
		ex = K.number("A class collects %d %s a week for %d weeks. Each %s needs %d. How many whole ones can they make?" % [
			weekly, m[1], weeks, m[0], per], str(n), "First find how many they collect, then share them into lots of %d." % per,
			"%d × %d = %d, and %d ÷ %d = %d%s." % [weekly, weeks, have, have, per, n,
				"" if have % per == 0 else " with %d left over" % (have % per)])
		ex.data = {"have": have, "per": per}
	return ex


## How long waste takes to break down (scientists' estimates, in years), each at least twice the one before.
const BREAKDOWN := {"a paper towel": [0.06, "about 3 weeks"], "an apple core": [0.17, "about 2 months"],
	"a wool glove": [1.0, "about a year"], "a plastic bag": [20.0, "about 20 years"], "a tin can": [50.0, "about 50 years"],
	"an aluminium can": [200.0, "about 200 years"], "a plastic bottle": [450.0, "about 450 years"]}


## Put waste in order of how long it takes to break down: 3, 4 or 5 things.
static func breakdown_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := BREAKDOWN.keys()
	K.shuffle(rng, names)
	var pick: Array = names.slice(0, level + 2)
	pick.sort_custom(func(a: String, b: String) -> bool: return float(BREAKDOWN[a][0]) < float(BREAKDOWN[b][0]))
	var ex := K.order(rng, "Put these in order of how long they take to break down, the quickest first.", pick,
		"Things from plants and animals rot quickest. Metal lasts longer, and plastic longest of all.",
		"; ".join(pick.map(func(n: String) -> String: return "%s, %s" % [n, BREAKDOWN[n][1]])) + ".")
	ex.data = {"items": pick}
	return ex


# --- Design and technology: fabrics and clothes (g5.design_tech.fabrics_clothes) ---------------------------------

const FIBRES := {"plant": ["cotton", "linen", "hemp", "jute"], "animal": ["wool", "silk", "cashmere", "alpaca wool"],
	"oil": ["polyester", "nylon", "acrylic", "elastane"]}


## Sort fibres. Level 1: natural or made (4); level 2: from plants, from animals or made from oil (5); level 3: the same
## with 6.
static func fibre_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var counts: Array = [[1, 1, 2], [2, 1, 2], [2, 2, 2]][level - 1]
	if level == 2:
		counts = [[2, 1, 2], [1, 2, 2], [2, 2, 1]][rng.randi_range(0, 2)]
	var items: Array = []
	var kinds := ["plant", "animal", "oil"]
	for k in 3:
		var list: Array = (FIBRES[kinds[k]] as Array).duplicate()
		K.shuffle(rng, list)
		for i in int(counts[k]):
			items.append([list[i], k])
	K.shuffle(rng, items)
	var ex: Dictionary
	if level == 1:
		ex = {"type": "sort", "prompt": "Sort the fibres: natural fibres come from plants and animals; made fibres are made in factories.",
			"groups": ["natural fibre", "made fibre"], "items": items.map(func(it: Array) -> String: return str(it[0])),
			"answer": items.map(func(it: Array) -> int: return 1 if int(it[1]) == 2 else 0),
			"hint": "Could it grow on a plant or an animal? If not, it was made from oil in a factory.",
			"explain": "Natural: %s. Made: %s." % [_and(_named(items, [0, 1])), _and(_named(items, [2]))]}
	else:
		ex = {"type": "sort", "prompt": "Sort the fibres by where they come from.", "groups": ["from plants", "from animals",
			"made from oil"], "items": items.map(func(it: Array) -> String: return str(it[0])),
			"answer": items.map(func(it: Array) -> int: return int(it[1])),
			"hint": "Cotton and linen grow on plants; wool and silk come from animals. The rest are made from oil.",
			"explain": "Plants: %s. Animals: %s. Oil: %s." % [_and(_named(items, [0])), _and(_named(items, [1])),
				_and(_named(items, [2]))]}
	ex.data = {"items": items.map(func(it: Array) -> String: return str(it[0]))}
	return ex


static func _named(items: Array, kinds: Array) -> Array:
	var out: Array = []
	for it: Array in items:
		if kinds.has(int(it[1])):
			out.append(str(it[0]))
	return out if not out.is_empty() else ["none"]


## The next row of a weave. Levels 1-2: a plain weave (over one, under one; each row the opposite of the one before);
## level 3: a twill (over two, under two; each row one thread along, making diagonal lines).
static func weave_next(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var width := 4 if level == 1 else rng.randi_range(5, 8) if level == 2 else 8
	var shown := 2 if level == 1 else 3
	var rows: Array = []
	var kind := "plain" if level < 3 else "twill"
	var first := ""
	var start := rng.randi_range(0, 3)
	for i in width:
		if kind == "plain":
			first += "o" if (i + start) % 2 == 0 else "u"
		else:
			first += "o" if ((i + start) % 4) < 2 else "u"
	rows.append(first)
	for r in shown - 1:
		rows.append(_next_row(str(rows[-1]), kind))
	var want := _next_row(str(rows[-1]), kind)
	var wrongs: Array = []
	var last := str(rows[-1])
	var back := last.substr(1) + last.substr(0, 1)
	var all_over := ""
	var halves := ""
	for i in width:
		all_over += "o"
		halves += "o" if i < width / 2 else "u"
	for w: String in [last, back, _next_row(want, "plain"), _rev(want), halves, all_over]:
		if w != want and not wrongs.has(w):
			wrongs.append(w)
	var pic := func(w: String) -> Dictionary: return {"picture": {"kind": "weave", "rows": [w]}}
	var ex := K.choice(rng, "Here is a %s weave. Which row comes next?" % kind, pic.call(want), wrongs.slice(0, 3).map(pic),
		"In a plain weave, each row does the opposite of the row before." if kind == "plain" else
		"In a twill, each row is the row before moved one thread along, so the pattern makes diagonal lines.",
		"The next row goes %s." % ", ".join(_chars(want).map(func(ch: String) -> String:
			return "over" if ch == "o" else "under")), {"kind": "weave", "rows": rows, "numbers": true})
	ex.data = {"rows": rows, "kind": kind}
	return ex


static func _next_row(row: String, kind: String) -> String:
	if kind == "plain":
		var out := ""
		for ch in row:
			out += "u" if ch == "o" else "o"
		return out
	return row.substr(row.length() - 1) + row.substr(0, row.length() - 1)   # a whole number of repeats: 4 or 8


# --- Design and technology: test and review (g5.design_tech.test_and_review) ---------------------------------------

## [the test, what each result measures, its unit, the smallest and largest mean]
const TESTS: Array = [["the toy car rolled", "down the ramp", "cm", 60, 200], ["the paper bridge held", "before it sagged",
	"washers", 8, 40], ["the torch shone for", "on one battery", "minutes", 20, 90], ["the balloon car travelled",
	"across the floor", "cm", 100, 300]]


## Fair tests, repeated. Level 1: the mean of 3 results; level 2: of 4; level 3: 4 results with one odd one (a slip) to
## leave out before finding the mean of the other 3.
static func test_average(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t: Array = TESTS[rng.randi_range(0, TESTS.size() - 1)]
	var n := 4 if level == 2 else 3
	var mean := rng.randi_range(int(t[3]) + 4, int(t[4]) - 4)
	var v: Array = []
	for i in n - 1:
		v.append(mean + rng.randi_range(-3, 3))
	var sum := 0
	for x: Variant in v:
		sum += int(x)
	v.append(mean * n - sum)
	K.shuffle(rng, v)
	var ex: Dictionary
	if level < 3:
		ex = K.number("In a fair test done %d times, %s %s %s. What is the mean (the average) result?" % [n, t[0],
			_and(v), "%s %s" % [t[2], t[1]]], str(mean), "Add all the results, then share the total by how many results there are.",
			"%s = %d, and %d ÷ %d = %d %s." % [" + ".join(v.map(func(x: int) -> String: return str(x))), mean * n, mean * n, n,
				mean, t[2]])
		ex.data = {"values": v}
	else:
		var odd := rng.randi_range(0, 3)
		var slip := maxi(1, mean / 4)
		v.insert(odd, slip)
		var kept: Array = v.duplicate()
		kept.remove_at(odd)
		ex = K.number("In a fair test done 4 times, %s %s %s. One result was a slip. Leave it out: what is the mean of the other three?" % [
			t[0], _and(v), "%s %s" % [t[2], t[1]]], str(mean),
			"Find the result far from the others and leave it out. Then add the rest and share by 3.",
			"Leave out %d. %s = %d, and %d ÷ 3 = %d %s." % [slip, " + ".join(kept.map(func(x: int) -> String: return str(x))),
				mean * 3, mean * 3, mean, t[2]])
		ex.data = {"values": v, "odd": odd}
	return ex


const CRITERIA: Array[String] = ["holds 6 pencils", "easy to open", "strong", "looks good", "costs little",
	"waterproof", "easy to carry", "made from waste"]


## Two designs scored out of 5 against three criteria (a table). Level 1: which design scored more; level 2: a design's
## total; level 3: by how many points the winner wins.
static func criteria_score(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var crit: Array = CRITERIA.duplicate()
	K.shuffle(rng, crit)
	crit = crit.slice(0, 3)
	var a: Array = []
	var b: Array = []
	var ta := 0
	var tb := 0
	while ta == tb:
		a.clear()
		b.clear()
		ta = 0
		tb = 0
		for i in 3:
			a.append(rng.randi_range(1, 5))
			b.append(rng.randi_range(1, 5))
			ta += int(a[i])
			tb += int(b[i])
	var rows: Array = [["criterion", "design A", "design B"]]
	for i in 3:
		rows.append([crit[i], str(a[i]), str(b[i])])
	var pic := {"kind": "table", "rows": rows}
	var sums := "A: %d + %d + %d = %d. B: %d + %d + %d = %d." % [a[0], a[1], a[2], ta, b[0], b[1], b[2], tb]
	var ex: Dictionary
	if level == 1:
		var win := "design A" if ta > tb else "design B"
		ex = K.choice(rng, "Two designs were tested and scored out of 5 for each criterion. Which design scored more in total?",
			win, ["design B" if ta > tb else "design A"], "Add up each design's scores, then compare the totals.",
			"%s %s scored more." % [sums, _cap(win)], pic)
		ex.data = {"kind": "winner", "a": a, "b": b}
	elif level == 2:
		var which := "A" if rng.randf() < 0.5 else "B"
		ex = K.number("Two designs were scored out of 5 for each criterion. What is design %s's total score?" % which,
			str(ta if which == "A" else tb), "Add the three scores in design %s's column." % which, sums, pic)
		ex.data = {"kind": "total", "a": a, "b": b, "design": which}
	else:
		ex = K.number("Two designs were scored out of 5 for each criterion. By how many points does the winning design win?",
			str(absi(ta - tb)), "Find both totals, then the difference between them.",
			"%s %d − %d = %d points." % [sums, maxi(ta, tb), mini(ta, tb), absi(ta - tb)], pic)
		ex.data = {"kind": "by", "a": a, "b": b}
	return ex


# --- Projects: a Roman town (g5.projects.roman_town) ---------------------------------------------------------------

const ROMAN := {"F": "the forum", "B": "the baths", "T": "the temple", "A": "the amphitheatre", "G": "the gate"}


## A Roman town on a coordinate grid (0-8 each way). Level 1: tap where a building goes; level 2: a building's
## coordinates; level 3: how far along the roads (grid lines, 10 m a square) from one building to another.
static func roman_grid(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var labels: Array = ROMAN.keys()
	K.shuffle(rng, labels)
	var points: Array = []
	var taken := {}
	while points.size() < 4:
		var p := Vector2i(rng.randi_range(1, 7), rng.randi_range(1, 7))
		if taken.has(p):
			continue
		taken[p] = true
		points.append({"x": p.x, "y": p.y, "label": labels[points.size()]})
	var target: Dictionary = points[0]
	var name := str(ROMAN[str(target.label)])
	var shown: Array = points.slice(1) if level == 1 else points
	var grid := {"x_max": 8, "y_max": 8, "points": shown}
	var ex: Dictionary
	if level == 1:
		ex = {"type": "point", "prompt": "Build %s at (%d, %d). Tap that point on the town's grid." % [name, target.x,
			target.y], "grid": grid, "answer": [target.x, target.y], "hint": "The first number goes along, the second goes up.",
			"explain": "%d along the bottom, then %d up: (%d, %d)." % [target.x, target.y, target.x, target.y]}
		ex.data = {"kind": "tap", "points": points, "target": str(target.label)}
	elif level == 2:
		var right := "(%d, %d)" % [target.x, target.y]
		var wrongs: Array = []
		for w: Vector2i in [Vector2i(target.y, target.x), Vector2i(target.x + 1, target.y), Vector2i(target.x, target.y - 1),
				Vector2i(target.x - 1, target.y + 1)]:
			var t := "(%d, %d)" % [w.x, w.y]
			if t != right and not wrongs.has(t):
				wrongs.append(t)
		ex = K.choice(rng, "On the town's grid, %s is marked %s. What are its coordinates?" % [name, target.label], right,
			wrongs.slice(0, 3), "Read along the bottom first, then up the side.",
			"%s is %d along and %d up: %s." % [_cap(name), target.x, target.y, right], {"kind": "grid", "x_max": 8,
				"y_max": 8, "points": shown})
		ex.data = {"kind": "name", "points": points, "target": str(target.label)}
	else:
		var from: Dictionary = points[1]
		for p: Dictionary in points.slice(1):
			if int(p.x) != int(target.x) and int(p.y) != int(target.y):
				from = p
		var dx := absi(int(target.x) - int(from.x))
		var dy := absi(int(target.y) - int(from.y))
		ex = K.number("Roman roads run along the grid lines, and each square is 10 m. How far is it from %s (%s) to %s (%s) along the roads, in metres?" % [
			ROMAN[str(from.label)], from.label, name, target.label], str((dx + dy) * 10),
			"Count the squares along, then the squares up or down, and add them. Then times by 10.",
			"%d along + %d up or down = %d squares, and %d × 10 = %d m." % [dx, dy, dx + dy, dx + dy, (dx + dy) * 10],
			{"kind": "grid", "x_max": 8, "y_max": 8, "points": shown})
		ex.data = {"kind": "walk", "points": points, "target": str(target.label), "from": str(from.label)}
	return ex


# --- Projects: a biome expedition (g5.projects.biome_expedition) ---------------------------------------------------

## Three food webs: [name, [[living thing, col, row]], [[food, eater]]] (the arrows point to the eater).
const WEBS: Array = [
	["desert", [["grass", 0, 3], ["mesquite", 2, 3], ["grasshopper", 0, 2], ["kangaroo rat", 2, 2], ["lizard", 1, 1],
		["rattlesnake", 3, 1], ["hawk", 2, 0]], [[0, 2], [1, 3], [2, 4], [4, 6], [3, 5], [5, 6], [4, 5]]],
	["Arctic tundra", [["lichen", 0, 3], ["grass", 2, 3], ["caribou", 0, 2], ["lemming", 2, 2], ["arctic hare", 3, 2],
		["snowy owl", 1, 1], ["arctic fox", 3, 1], ["wolf", 1, 0]], [[0, 2], [1, 3], [1, 4], [3, 5], [3, 6], [4, 6],
		[4, 7], [2, 7]]],
	["woodland", [["oak tree", 0, 3], ["grass", 3, 3], ["caterpillar", 0, 2], ["mouse", 1, 2], ["rabbit", 3, 2],
		["blue tit", 0, 1], ["fox", 2, 1], ["sparrowhawk", 0, 0]], [[0, 2], [0, 3], [1, 4], [2, 5], [5, 7], [3, 6], [4, 6]]],
]


## Level 1: which is a producer (a plant); level 2: which of these an animal eats; level 3: if one living thing
## disappeared, which animal would lose some of its food.
static func expedition_web(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var web: Array = WEBS[rng.randi_range(0, WEBS.size() - 1)]
	var nodes: Array = web[1]
	var links: Array = web[2]
	var names: Array = nodes.map(func(n: Array) -> String: return str(n[0]))
	var eaten_by := {}
	var eats := {}
	for l: Array in links:
		(eaten_by.get_or_add(int(l[0]), []) as Array).append(int(l[1]))
		(eats.get_or_add(int(l[1]), []) as Array).append(int(l[0]))
	var pic := {"kind": "food_web", "nodes": nodes, "links": links}
	var where := "this %s food web" % web[0]
	var ex: Dictionary
	for _try in 100:
		if level == 1:
			var plants: Array = []
			var animals: Array = []
			for i in names.size():
				(animals if eats.has(i) else plants).append(names[i])
			K.shuffle(rng, plants)
			K.shuffle(rng, animals)
			ex = K.choice(rng, "In %s, which living thing is a producer?" % where, plants[0], animals.slice(0, 3),
				"A producer makes its own food from sunlight. No arrow points into it.",
				"The %s: it is a plant, which makes its own food from sunlight. The food chains start from the plants." % plants[0],
				pic)
			ex.data = {"kind": "producer", "subject": plants[0]}
			return ex
		var i := rng.randi_range(0, names.size() - 1)
		if level == 2:
			if not eats.has(i):
				continue
			var food := int((eats[i] as Array)[rng.randi_range(0, (eats[i] as Array).size() - 1)])
			var plant_eater := false
			for f: int in eats[i]:
				plant_eater = plant_eater or not eats.has(f)
			var wrongs: Array = []   # plants for a meat eater, its own hunters, and animals as high up as it
			for j in names.size():
				if j == i or (eats[i] as Array).has(j):
					continue
				var plant := not eats.has(j)
				var hunter := eaten_by.has(i) and (eaten_by[i] as Array).has(j)
				var as_high := eats.has(j) and int(nodes[j][2]) <= int(nodes[i][2])
				if (plant and not plant_eater) or hunter or as_high:
					wrongs.append(names[j])
			if wrongs.size() < 2:
				continue
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "In %s, which of these does the %s eat?" % [where, names[i]], names[food], wrongs.slice(0, 3),
				"Find the arrows that point into the %s. Each one starts at something it eats." % names[i],
				"The %s: an arrow goes from the %s to the %s, because energy passes to the animal that eats it." % [names[food],
					names[food], names[i]], pic)
			ex.data = {"kind": "eats", "subject": names[i]}
			return ex
		if not eaten_by.has(i):
			continue
		var eater := int((eaten_by[i] as Array)[rng.randi_range(0, (eaten_by[i] as Array).size() - 1)])
		var below := _downstream(i, eaten_by)   # every animal that loses food, even through another
		var wrongs: Array = []
		for j in names.size():
			if j != i and eats.has(j) and not below.has(j):
				wrongs.append(names[j])
		if wrongs.size() < 2:
			continue
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "In %s, if all the %s disappeared, which animal would lose some of its food?" % [where,
			_plural(str(names[i]))], names[eater], wrongs.slice(0, 3),
			"Follow the arrows out of the %s. They point to the animals that eat it." % names[i],
			"The %s: an arrow goes from the %s to the %s, so the %s eats it." % [names[eater], names[i], names[eater],
				names[eater]], pic)
		ex.data = {"kind": "loses", "subject": names[i]}
		return ex
	return ex


## Every living thing that eats `i`, or eats something that does, and so on.
static func _downstream(i: int, eaten_by: Dictionary) -> Dictionary:
	var out := {}
	var todo: Array = [i]
	while not todo.is_empty():
		var k: int = todo.pop_back()
		for j: int in eaten_by.get(k, []):
			if not out.has(j):
				out[j] = true
				todo.append(j)
	return out


static func _plural(n: String) -> String:
	if n in ["grass", "lichen", "mesquite", "caribou"]:
		return n
	if n == "mouse":
		return "mice"
	if n.ends_with("fox"):
		return n + "es"
	if n.ends_with("y"):
		return n.substr(0, n.length() - 1) + "ies"
	return n + "s"


## Biomes' typical yearly weather: [name, lowest and highest average °C, lowest and highest rain in mm a year].
const BIOMES: Array = [["hot desert", 25, 32, 50, 250], ["rainforest", 25, 28, 2000, 3000], ["tundra", -12, -6, 150, 250],
	["woodland", 8, 12, 700, 1200]]


## A table of three biomes' average temperature and yearly rain. Level 1: the wettest, driest, warmest or coldest;
## level 2: how much more rain; level 3: how much warmer (below zero too).
static func biome_weather(rng: RandomNumberGenerator, level: int) -> Dictionary:
	for _try in 200:
		var pick: Array = BIOMES.duplicate()
		K.shuffle(rng, pick)
		pick = pick.slice(0, 3)
		var rows: Array = []
		for b: Array in pick:
			var rain_step := 100 if int(b[4]) > 1000 else 10
			rows.append([str(b[0]), rng.randi_range(int(b[1]), int(b[2])),
				rng.randi_range(int(b[3]) / rain_step, int(b[4]) / rain_step) * rain_step])
		var table: Array = [["biome", "average °C", "rain a year"]]
		for r: Array in rows:
			table.append([str(r[0]), _minus(int(r[1])), "%s mm" % K.fmt(int(r[2]))])
		var pic := {"kind": "table", "rows": table}
		var ex: Dictionary
		if level == 1:
			var kind: String = ["wettest", "driest", "warmest", "coldest"][rng.randi_range(0, 3)]
			var col := 2 if kind in ["wettest", "driest"] else 1
			var most := kind in ["wettest", "warmest"]
			var sorted := rows.duplicate()
			sorted.sort_custom(func(a: Array, b: Array) -> bool: return float(a[col]) > float(b[col]))
			var best: Array = sorted[0] if most else sorted[-1]
			var next: Array = sorted[1] if most else sorted[-2]
			if absf(float(best[col]) - float(next[col])) < (3.0 if col == 1 else 50.0):
				continue
			var q := {"wettest": "gets the most rain", "driest": "gets the least rain", "warmest": "is warmest on average",
				"coldest": "is coldest on average"}
			ex = K.choice(rng, "The expedition's table shows three biomes. Which one %s?" % q[kind], str(best[0]),
				rows.filter(func(r: Array) -> bool: return r != best).map(func(r: Array) -> String: return str(r[0])),
				"Look down the %s column and find the %s number." % ["rain" if col == 2 else "temperature",
					"biggest" if most else "smallest"],
				"The %s: %s, the %s in the table." % [best[0], _minus(int(best[col])) + (" mm" if col == 2 else " °C"),
					"most" if most else ("least" if col == 2 else "coldest")], pic)
			ex.data = {"kind": kind, "rows": rows}
			return ex
		var sorted := rows.duplicate()
		var col := 2 if level == 2 else 1
		sorted.sort_custom(func(a: Array, b: Array) -> bool: return float(a[col]) > float(b[col]))
		var hi: Array = sorted[0]
		var lo: Array = sorted[rng.randi_range(1, 2)]
		var gap := int(hi[col]) - int(lo[col])
		if gap <= 0:
			continue
		if level == 2:
			ex = K.number("How much more rain does the %s get in a year than the %s, in millimetres?" % [hi[0], lo[0]], str(gap),
				"Find both amounts in the rain column, then take the smaller from the bigger.",
				"%s − %s = %s mm." % [K.fmt(int(hi[2])), K.fmt(int(lo[2])), K.fmt(gap)], pic)
			ex.data = {"kind": "rain_gap", "rows": rows, "a": hi[2], "b": lo[2]}
		else:
			ex = K.number("How many degrees warmer on average is the %s (%s °C) than the %s (%s °C)?" % [hi[0], _minus(int(hi[1])),
				lo[0], _minus(int(lo[1]))], str(gap), "Count up from the colder temperature. Below zero, count up to 0 first.",
				("From %s °C up to 0 is %d degrees, then up to %d °C is %d more: %d degrees." % [_minus(int(lo[1])),
					-int(lo[1]), int(hi[1]), int(hi[1]), gap]) if int(lo[1]) < 0 else "%d − %d = %d degrees." % [int(hi[1]),
					int(lo[1]), gap], pic)
			ex.data = {"kind": "warmer", "rows": rows, "a": hi[1], "b": lo[1]}
		return ex
	return {}


## "−8" with the minus sign, as the lessons write it.
static func _minus(n: int) -> String:
	return ("−%d" % -n) if n < 0 else str(n)


# --- Projects: a fair on a budget (g5.projects.fair_with_budget) ---------------------------------------------------

## Money in gold. Level 1: the budget left after two costs; level 2: a price after a discount (10, 20, 25 or 50% off);
## level 3: the profit from tickets after costs.
static func fair_money(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var budget: int = [100, 150, 200, 250][rng.randi_range(0, 3)]
		var things: Array = [["bunting", 15, 45], ["prizes", 30, 70], ["paint for posters", 10, 30], ["hoopla rings", 10, 25],
			["lemonade", 20, 40]]
		K.shuffle(rng, things)
		var costs: Array = [rng.randi_range(int(things[0][1]), int(things[0][2])), rng.randi_range(int(things[1][1]),
			int(things[1][2]))]
		var left := budget - int(costs[0]) - int(costs[1])
		ex = K.number("The fair's budget is %d gold. The %s cost %d gold and the %s cost %d gold. How much of the budget is left?" % [
			budget, things[0][0], costs[0], things[1][0], costs[1]], str(left), "Add what was spent, then take it from the budget.",
			"%d + %d = %d spent, and %d − %d = %d gold left." % [costs[0], costs[1], int(costs[0]) + int(costs[1]), budget,
				int(costs[0]) + int(costs[1]), left])
		ex.data = {"kind": "left", "budget": budget, "costs": costs}
	elif level == 2:
		var percent: int = [10, 20, 25, 50][rng.randi_range(0, 3)]
		var step: int = {10: 10, 20: 5, 25: 4, 50: 2}[percent]
		var price := rng.randi_range(2, 12) * step
		var off := price * percent / 100
		var item: String = ["a cake stall's big cake", "a hoopla prize", "a painted sign", "a basket of apples", "a kite"][
			rng.randi_range(0, 4)]
		ex = K.number("At the fair, %s costs %d gold. It has %d%% off. What is the new price, in gold?" % [item, price, percent],
			str(price - off), "Find %d%% of the price first: %s. Then take it off." % [percent,
				{10: "a tenth", 20: "a fifth", 25: "a quarter", 50: "a half"}[percent]],
			"%d%% of %d is %d, and %d − %d = %d gold." % [percent, price, off, price, off, price - off])
		ex.data = {"kind": "discount", "price": price, "percent": percent}
	else:
		for _try in 50:
			var each: float = [1.5, 2.0, 2.5][rng.randi_range(0, 2)]
			var tickets := rng.randi_range(4, 16) * 4
			var costs := rng.randi_range(4, 12) * 5
			var income := tickets * each
			if income <= costs + 5:
				continue
			var profit := income - costs
			ex = K.number("The fair sold %d tickets at %s gold each. It cost %d gold to put on. What was the profit, in gold?" % [
				tickets, _gold(each), costs], _gold(profit), "Profit is the money that came in, less what it cost.",
				"%d × %s = %s gold in, and %s − %d = %s gold profit." % [tickets, _gold(each), _gold(income), _gold(income), costs,
					_gold(profit)])
			ex.data = {"kind": "profit", "tickets": tickets, "each": each, "costs": costs}
			return ex
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return PEOPLE[rng.randi_range(0, PEOPLE.size() - 1)]


## "a, b and c"
static func _and(items: Array) -> String:
	var s: Array = items.map(func(x: Variant) -> String: return str(x))
	if s.size() <= 1:
		return "".join(s)
	return ", ".join(s.slice(0, s.size() - 1)) + " and " + str(s[-1])


static func _has(food: String) -> String:
	return "have" if MANY.has(food) else "has"


static func _it(food: String) -> String:
	return "them" if MANY.has(food) else "it"


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


## Minutes from midnight as "9:30 pm".
static func _clock(minutes: int) -> String:
	var m := posmod(minutes, 24 * 60)
	var h := m / 60
	return "%d:%02d %s" % [12 if h % 12 == 0 else h % 12, m % 60, "am" if h < 12 else "pm"]


## Tenths as a decimal: 15 -> "1.5", 20 -> "2".
static func _dec(tenths: int) -> String:
	return str(tenths / 10) if tenths % 10 == 0 else "%d.%d" % [tenths / 10, tenths % 10]


## Tenths of a whole (as in _dec) for amounts written in tenths: 25 -> "2.5".
static func _dec10(tenths: int) -> String:
	return _dec(tenths)


## A number with no more decimals than it needs: 1.5 -> "1.5", 0.75 -> "0.75", 2.0 -> "2".
static func _num_text(x: float) -> String:
	if x == floorf(x):
		return str(int(x))
	return ("%.2f" % x).rstrip("0")


static func _chars(s: String) -> Array:
	var out: Array = []
	for ch in s:
		out.append(ch)
	return out


static func _join(parts: Array) -> String:
	var out := ""
	for p: Variant in parts:
		out += str(p)
	return out


static func _rev(s: String) -> String:
	var out := ""
	for ch in s:
		out = ch + out
	return out


## 3.0 -> "3", 3.5 -> "3.5".
static func _half(x: float) -> String:
	return str(int(x)) if x == floorf(x) else "%.1f" % x


## Gold as the lessons write money: 2.5 -> "2.50", 3.0 -> "3".
static func _gold(x: float) -> String:
	return str(int(x)) if x == floorf(x) else "%.2f" % x
