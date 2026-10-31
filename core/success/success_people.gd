class_name SuccessPeople
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2.3, [S5]; the brief: "the worlds' people with names, jobs, wishes and
## needs ...; meet them, remember them in the book, help first, keep promises (deliver on time), introduce two people
## who can help each other; their warmth grows (never a public score); new chances open; mentors teach a skill when asked
## politely; people different from you"): the Connections Book's rules over SuccessData.people.
## The people are data/success/people.json: {id, name, job, place, colour, look (SuccessCast's clothes), hello, wish,
## needs, helped_by (who can help with that: introductions), offers, skill and tip (a mentor's), chance (what opens when
## they trust you), different (how they differ from many children: older, from far away, a wheelchair, sign language)}.
## A practice room's step says what the child did there in its "book": {meet: [ids]}, {help: id}, {promise: id},
## {intro: [a, b]}, {mentor: id}, or a list of them; LifeScreen records a finished try's (owner #115's hook). Warmth
## rises by kind acts, at most WARMTH_PER_TRY a person each try (trust takes time), and shows only as words about the
## person, never a number.

const PATH := "res://data/success/people.json"
const WARMTH_PER_TRY := 2
const CHANCE_AT := 3
const WARMTH_WORDS: Array[String] = ["%s hasn't met you yet.", "%s knows you.", "%s smiles when you come by.",
	"%s trusts you.", "%s counts on you.", "%s is a good friend."]
const ACTIONS: Array[String] = ["meet", "help", "promise", "intro", "mentor"]

static var _data := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var json := JSON.new()
		var text := FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
		_data = json.data if text != "" and json.parse(text) == OK and json.data is Dictionary else {"people": []}
	return _data


static func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Variant in data().get("people", []):
		if p is Dictionary:
			out.append(p)
	return out


static func person(id: String) -> Dictionary:
	for p in list():
		if str(p.id) == id:
			return p
	return {}


static func has(id: String) -> bool:
	return not person(id).is_empty()


static func name_of(id: String) -> String:
	return str(person(id).get("name", id))


## Records what a child did in a try on `day` (the steps' "book" entries, in order). Unknown people are left out.
static func record(d: SuccessData, actions: Array, day: int) -> void:
	var gained := {}
	for a: Variant in actions:
		if not a is Dictionary:
			continue
		for kind: String in a:
			var who: Array[String] = []
			var v: Variant = a[kind]
			if v is Array:
				for x: Variant in v:
					who.append(str(x))
			else:
				who.append(str(v))
			match kind:
				"meet":
					for id in who:
						_warm(d, id, day, 0, "", gained)
				"help":
					for id in who:
						_warm(d, id, day, 1, "h", gained)
				"promise":
					for id in who:
						_warm(d, id, day, 1, "p", gained)
				"intro":
					for id in who:
						_warm(d, id, day, 1, "i", gained)
				"mentor":
					for id in who:
						_warm(d, id, day, 1, "t", gained)


static func _warm(d: SuccessData, id: String, day: int, by: int, count: String, gained: Dictionary) -> void:
	if not has(id):
		return
	var p := d.person(id)
	if int(p.m) <= 0:
		p.m = day
	var up := mini(by, WARMTH_PER_TRY - int(gained.get(id, 0))) if by > 0 else 0
	p.w = clampi(maxi(int(p.w), 1) + maxi(up, 0), 0, SuccessData.MAX_WARMTH)
	gained[id] = int(gained.get(id, 0)) + maxi(up, 0)
	match count:
		"t":
			p.t = true
		"h", "p", "i":
			p[count] = mini(int(p[count]) + 1, SuccessData.MAX_COUNT)
	d.set_person(id, p)


## The "book" entries of the steps a child finished (the try's log: [{id, ...}]), in order.
static func actions_from(steps: Array, log: Array) -> Array[Dictionary]:
	var done := {}
	for e: Variant in log:
		if e is Dictionary:
			done[str((e as Dictionary).get("id", ""))] = true
	var out: Array[Dictionary] = []
	for s: Variant in steps:
		if not s is Dictionary or not done.has(str((s as Dictionary).get("id", ""))):
			continue
		var book: Variant = (s as Dictionary).get("book")
		if book is Dictionary:
			out.append(book)
		elif book is Array:   # several things done in one step: [{meet: [...]}, {help: ...}]
			for b: Variant in book:
				if b is Dictionary:
					out.append(b)
	return out


static func met_count(d: SuccessData) -> int:
	var n := 0
	for p in list():
		if d.met(str(p.id)):
			n += 1
	return n


## A person's warmth in words ("Amara smiles when you come by."): never a number, never compared with anyone.
static func warmth_words(id: String, w: int) -> String:
	return WARMTH_WORDS[clampi(w, 0, WARMTH_WORDS.size() - 1)] % name_of(id)


## The new chances that opened: what the people who trust you told you.
static func chances(d: SuccessData) -> Array[String]:
	var out: Array[String] = []
	for p in list():
		if int(d.person(str(p.id)).w) >= CHANCE_AT and str(p.get("chance", "")) != "":
			out.append(str(p.chance))
	return out


## The mentors' tips learned: "Omar taught you: Check twice, fix once."
static func tips(d: SuccessData) -> Array[String]:
	var out: Array[String] = []
	for p in list():
		if bool(d.person(str(p.id)).t) and str(p.get("tip", "")) != "":
			out.append("%s taught you: %s" % [str(p.name), str(p.tip)])
	return out


## The grown-ups' honest line ("" before anyone was met).
static func grown_ups_line(d: SuccessData) -> String:
	var met := met_count(d)
	if met == 0:
		return ""
	var h := 0
	var pr := 0
	var intro := 0
	var tip := 0
	for p in list():
		var x := d.person(str(p.id))
		h += int(x.h)
		pr += int(x.p)
		intro += int(x.i)
		tip += 1 if bool(x.t) else 0
	intro /= 2   # an introduction counts on both people
	return "The Connections Book: met %d %s, helped %d %s, kept %d %s, made %d %s, learned %d mentor's %s." % [
		met, _plural(met, "person", "people"), h, _plural(h, "time", "times"), pr, _plural(pr, "promise", "promises"),
		intro, _plural(intro, "introduction", "introductions"), tip, _plural(tip, "tip", "tips")]


static func _plural(n: int, one: String, many: String) -> String:
	return one if n == 1 else many
