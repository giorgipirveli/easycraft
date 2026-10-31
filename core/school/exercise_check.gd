class_name ExerciseCheck
extends RefCounted
## Owner #68 (spec §22.1, §22.5): the School's exercise types and their checkers. An exercise is a Dictionary (the data
## files' JSON, or what a generator makes):
## - every one: type, prompt, hint; optional level (1-3), picture (SchoolPicture data), sound (SchoolSound data: a tune
##   or claps, played by LISTEN), explain (the worked answer).
## - "choice": choices (2-6: text, or {"text"?, "picture"?}), answer (the index). Response: the index tapped.
## - "truefalse": answer (bool). Response: bool.
## - "number": answer (a number as text, NumberAnswer), optional accept (more right answers), pad (the extra keys; default
##   from the answer), year (true: a year, shown "1850", not "1,850"; a whole number). Response: the text typed.
## - "order": items (2-6), answer (the items' indexes in the right order; never already in order). Response: the indexes
##   tapped, in order.
## - "build": board and goal (BuildCheck). Response: every block on the board (Array of Vector2i).
## - "point" (grade 5, 5.G.1-2): grid (GridCheck) and answer [x, y]. Response: the Vector2i tapped (GridAnswer).
## - "sort" (the research §5.3: living or not, source or not, …): groups (2-3 names), items (2-6), answer (each item's
##   group index; at least two groups used). Response: each item's group (-1 = not sorted yet).
## - "match" (§5.3: word and meaning, instrument and family, animal and young): items (2-5, the left), matches (as many,
##   the right, shown in their own order), answer (each item's match index, each used once; never already side by
##   side). Response: each item's match (-1 = not matched yet).
## - "label" (§5.3: label the diagram): picture (required), spots (2-5 numbered pins, [x, y] as fractions of LABEL_BOX,
##   at least PIN_GAP apart; [x, y, tx, ty]: the pin beside the drawing with a line to its part at tx, ty), labels (as many, words), answer (each label's spot index, each used once; never already
##   in order). Response: each label's spot (-1 = not placed yet).

const TYPES: Array[String] = ["choice", "truefalse", "number", "order", "build", "point", "sort", "match", "robot",
	"rhythm", "mix", "label"]
const MAX_GROUPS := 3
const MAX_GROUP := 24             # letters in a group's name (it shows on the items)
const MAX_PAIRS := 5
const MAX_MATCH := 32             # letters on each side of a pair (two narrow columns)
const LABEL_BOX := Vector2(520, 250)   # the picture a label exercise's pins sit on (LabelAnswer)
const MAX_LABEL := 24             # letters in a label (three to a row under the picture)
const PIN_GAP := 56.0             # the least distance between two pins' centres on LABEL_BOX, so a finger hits one
const MAX_CHOICES := 6
const MAX_ITEMS := 6
## The most letters each text may have, so every exercise fits its panel (ExercisePanel.SIZE) at the School's sizes.
const MAX_PROMPT := 180
const MAX_HINT := 200
const MAX_EXPLAIN := 260
const MAX_CHOICE := 48


## "" when the exercise is complete and can be answered; otherwise what is wrong with it.
static func problem(ex: Dictionary) -> String:
	var type := str(ex.get("type", ""))
	if not TYPES.has(type):
		return "unknown type '%s'" % type
	if not ex.get("prompt") is String or str(ex.prompt).strip_edges() == "":
		return "no prompt"
	if not ex.get("hint") is String or str(ex.hint).strip_edges() == "":
		return "no hint"
	if ex.has("explain") and not ex.explain is String:
		return "explain must be text"
	if str(ex.prompt).length() > MAX_PROMPT or str(ex.hint).length() > MAX_HINT \
			or str(ex.get("explain", "")).length() > MAX_EXPLAIN:
		return "too many words: a prompt at most %d letters, a hint %d, an explanation %d" % [MAX_PROMPT, MAX_HINT,
			MAX_EXPLAIN]
	if ex.has("sound") and SchoolSound.problem(ex.sound) != "":   # the research's "listen and choose" (§5.3)
		return "its sound: %s" % SchoolSound.problem(ex.sound)
	var level: Variant = ex.get("level", 1)
	if typeof(level) not in [TYPE_INT, TYPE_FLOAT] or int(level) < 1 or int(level) > 3:
		return "level must be 1-3"
	match type:
		"choice":
			var choices: Variant = ex.get("choices")
			if not choices is Array or (choices as Array).size() < 2 or (choices as Array).size() > MAX_CHOICES:
				return "2-%d choices" % MAX_CHOICES
			var seen := {}
			for c: Variant in choices:
				var key := _choice_key(c)
				if key == "":
					return "a choice is empty or longer than %d letters" % MAX_CHOICE
				if seen.has(key):
					return "two choices are the same: %s" % key
				seen[key] = true
			if not _is_index(ex.get("answer"), (choices as Array).size()):
				return "the answer must be a choice's index"
		"truefalse":
			if not ex.get("answer") is bool:
				return "the answer must be true or false"
		"number":
			var answer: Variant = ex.get("answer")
			if not answer is String or not NumberAnswer.is_number(answer):
				return "the answer must be a number"
			if str(answer).replace(",", "").length() > NumberPad.MAX_CHARS:
				return "the answer is too long for the pad"
			for a: Variant in ex.get("accept", []):
				if not a is String or not NumberAnswer.is_number(a):
					return "accept must list numbers"
			if ex.has("year") and (not ex.year is bool or (ex.year and not str(answer).replace(",", "").is_valid_int())):
				return "year is true or false, and a year is a whole number"
		"order":
			var items: Variant = ex.get("items")
			if not items is Array or (items as Array).size() < 2 or (items as Array).size() > MAX_ITEMS:
				return "2-%d items" % MAX_ITEMS
			var seen := {}
			for it: Variant in items:
				var key := _choice_key(it)
				if key == "" or seen.has(key):
					return "items must be different and not empty"
				seen[key] = true
			var answer: Variant = ex.get("answer")
			var n := (items as Array).size()
			if not answer is Array or (answer as Array).size() != n:
				return "the answer must order every item"
			var used := {}
			for i: Variant in answer:
				if not _is_index(i, n) or used.has(int(i)):
					return "the answer must use each item once"
				used[int(i)] = true
			var shown_in_order := true
			for i in n:
				shown_in_order = shown_in_order and int(answer[i]) == i
			if shown_in_order:
				return "the items are already in the right order"
		"build":
			if not ex.get("board") is Dictionary or not ex.get("goal") is Dictionary:
				return "a build needs a board and a goal"
			var why := BuildCheck.problem(ex.goal, ex.board)
			if why != "":
				return why
		"point":   # grade 5: tap a point on a coordinate grid
			var why := GridCheck.point_problem(ex.get("grid"), ex.get("answer"))
			if why != "":
				return why
		"sort":
			var groups: Variant = ex.get("groups")
			if not groups is Array or (groups as Array).size() < 2 or (groups as Array).size() > MAX_GROUPS:
				return "2-%d groups" % MAX_GROUPS
			for g: Variant in groups:
				if not g is String or str(g).strip_edges() == "" or str(g).length() > MAX_GROUP:
					return "a group's name is 1-%d letters" % MAX_GROUP
			var why := _items_problem(ex.get("items"), MAX_ITEMS)
			if why != "":
				return why
			var answer: Variant = ex.get("answer")
			var n := (ex.items as Array).size()
			if not answer is Array or (answer as Array).size() != n:
				return "the answer must give every item its group"
			var used := {}
			for g: Variant in answer:
				if not _is_index(g, (groups as Array).size()):
					return "the answer must name a group for every item"
				used[int(g)] = true
			if used.size() < 2:
				return "the answer must use at least two groups"
		"mix":
			if not ColourMix.RECIPES.has(str(ex.get("target", ""))):
				return "the target is a colour the paints make: %s" % ", ".join(PackedStringArray(ColourMix.RECIPES.keys()))
		"rhythm":
			if not ex.get("sound") is Dictionary or str(ex.sound.get("kind", "")) != "rhythm":
				return "a rhythm to copy needs claps: a sound of kind rhythm"
			if str(ex.sound.get("pattern", "")).length() > 8:
				return "a rhythm to copy is at most 8 beat boxes (half beats)"
		"robot":
			var why := RobotCheck.problem(ex.get("board"))
			if why != "":
				return why
			if ex.has("max"):
				if typeof(ex.max) not in [TYPE_INT, TYPE_FLOAT] or int(ex.max) < 1:
					return "max: a number of commands"
				if RobotCheck.shortest(ex.board).size() > int(ex.max):
					return "no program is as short as max"
		"match":
			var why := _items_problem(ex.get("items"), MAX_PAIRS)
			if why == "":
				why = _items_problem(ex.get("matches"), MAX_PAIRS)
			if why != "":
				return why
			var n := (ex.items as Array).size()
			if (ex.matches as Array).size() != n:
				return "as many matches as items"
			for it: Variant in (ex.items as Array) + (ex.matches as Array):
				if item_text(it).length() > MAX_MATCH:
					return "each side of a pair is at most %d letters" % MAX_MATCH
			var answer: Variant = ex.get("answer")
			if not answer is Array or (answer as Array).size() != n:
				return "the answer must match every item"
			var used := {}
			var side_by_side := true
			for i in n:
				var m: Variant = answer[i]
				if not _is_index(m, n) or used.has(int(m)):
					return "the answer must use each match once"
				used[int(m)] = true
				side_by_side = side_by_side and int(m) == i
			if side_by_side:
				return "the matches are already side by side"
		"label":
			return _label_problem(ex)
	return ""


static func _label_problem(ex: Dictionary) -> String:
	if not ex.get("picture") is Dictionary:
		return "a label exercise needs a picture"
	var why := _items_problem(ex.get("labels"), MAX_PAIRS)
	if why != "":
		return "labels: " + why
	var n := (ex.labels as Array).size()
	for l: Variant in ex.labels:
		if not l is String or str(l).length() > MAX_LABEL:
			return "a label is words of at most %d letters" % MAX_LABEL
	var spots: Variant = ex.get("spots")
	if not spots is Array or (spots as Array).size() != n:
		return "as many spots as labels"
	var at: Array[Vector2] = []
	for sp: Variant in spots:
		if not sp is Array or not (sp as Array).size() in [2, 4]:
			return "a spot is [x, y], or [x, y, part x, part y] with a line to the part"
		for v: Variant in sp:
			if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or float(v) < 0.0 or float(v) > 1.0:
				return "a spot is on the picture: its numbers from 0 to 1"
		var f := Vector2(float(sp[0]), float(sp[1]))
		for other in at:
			if other.distance_to(f * LABEL_BOX) < PIN_GAP:
				return "two spots are too close for a finger (%d px apart at least)" % int(PIN_GAP)
		at.append(f * LABEL_BOX)
	var answer: Variant = ex.get("answer")
	if not answer is Array or (answer as Array).size() != n:
		return "the answer must place every label"
	var used := {}
	var in_order := true
	for i in n:
		var m: Variant = answer[i]
		if not _is_index(m, n) or used.has(int(m)):
			return "the answer must use each spot once"
		used[int(m)] = true
		in_order = in_order and int(m) == i
	if in_order:
		return "the labels are already in the spots' order"
	return ""


## "" when `items` is a list of 2..most different, non-empty items.
static func _items_problem(items: Variant, most: int) -> String:
	if not items is Array or (items as Array).size() < 2 or (items as Array).size() > most:
		return "2-%d items" % most
	var seen := {}
	for it: Variant in items:
		var key := _choice_key(it)
		if key == "" or seen.has(key):
			return "items must be different and not empty"
		seen[key] = true
	return ""


static func is_right(ex: Dictionary, response: Variant) -> bool:
	match str(ex.get("type", "")):
		"choice":
			return typeof(response) == TYPE_INT and response == int(ex.get("answer", -1))
		"truefalse":
			return response is bool and response == ex.get("answer")
		"number":
			if not response is String:
				return false
			if NumberAnswer.equal(response, str(ex.get("answer", ""))):
				return true
			for a: Variant in ex.get("accept", []):
				if NumberAnswer.equal(response, str(a)):
					return true
			return false
		"order":
			var answer: Array = ex.get("answer", [])
			if not response is Array or (response as Array).size() != answer.size():
				return false
			for i in answer.size():
				if typeof(response[i]) not in [TYPE_INT, TYPE_FLOAT] or int(response[i]) != int(answer[i]):
					return false
			return true
		"build":
			return response is Array and BuildCheck.check(ex.get("goal", {}), ex.get("board", {}), response)
		"point":
			return response is Vector2i and response == GridCheck.point(ex.get("answer"))
		"mix":
			return ColourMix.matches(str(ex.get("target", "")), response)
		"rhythm":
			return response is String and response == str(ex.get("sound", {}).get("pattern", ""))
		"robot":
			return response is Array and RobotCheck.reaches(ex.get("board", {}), response) \
				and (response as Array).size() <= int(ex.get("max", RobotCheck.MAX_PROGRAM))
		"sort", "match", "label":   # every item in its group, with its match, every label on its spot
			var answer: Array = ex.get("answer", [])
			if not response is Array or (response as Array).size() != answer.size():
				return false
			for i in answer.size():
				if typeof(response[i]) not in [TYPE_INT, TYPE_FLOAT] or int(response[i]) != int(answer[i]):
					return false
			return true
	return false


## A right response (what the worked answer shows).
static func answer_of(ex: Dictionary) -> Variant:
	match str(ex.get("type", "")):
		"choice":
			return int(ex.get("answer", -1))
		"truefalse":
			return ex.get("answer")
		"number":
			return str(ex.get("answer", "")).replace(",", "")
		"order":
			var out: Array[int] = []
			for i: Variant in ex.get("answer", []):
				out.append(int(i))
			return out
		"build":
			return BuildCheck.example(ex.get("goal", {}), ex.get("board", {}))
		"point":
			return GridCheck.point(ex.get("answer"))
		"mix":
			return (ColourMix.RECIPES.get(str(ex.get("target", "")), {}) as Dictionary).duplicate()
		"rhythm":
			return str(ex.get("sound", {}).get("pattern", ""))
		"robot":
			return RobotCheck.shortest(ex.get("board", {}))
		"sort", "match", "label":
			var out: Array[int] = []
			for i: Variant in ex.get("answer", []):
				out.append(int(i))
			return out
	return null


## The right answer in words ("12", "3,000", "True", "4,021, 4,201, 4,210"); "" for a build (the board shows it).
static func answer_text(ex: Dictionary) -> String:
	match str(ex.get("type", "")):
		"choice":
			return item_text((ex.get("choices", []) as Array)[int(ex.answer)])
		"truefalse":
			return "True" if ex.answer else "False"
		"number":
			return NumberPad.shown(str(ex.answer).replace(",", ""), grouped(ex))
		"order":
			var words: Array[String] = []
			for i: Variant in ex.answer:
				words.append(item_text((ex.items as Array)[int(i)]))
			return ", ".join(words)
		"point":
			var p: Variant = GridCheck.point(ex.get("answer"))
			return GridCheck.text(p) if p != null else ""
		"sort":   # "Living: a tree, a frog. Not living: a rock, a cloud."
			var parts: Array[String] = []
			for g in (ex.groups as Array).size():
				var words: Array[String] = []
				for i in (ex.items as Array).size():
					if int(ex.answer[i]) == g:
						words.append(item_text(ex.items[i]))
				if not words.is_empty():
					var name := str(ex.groups[g])
					parts.append("%s: %s." % [name.left(1).to_upper() + name.substr(1), ", ".join(words)])
			return " ".join(parts)
		"mix":   # "1 red and 1 yellow"
			return ColourMix.words(ColourMix.RECIPES.get(str(ex.get("target", "")), {}))
		"rhythm":   # "clap, rest, clap"
			var beats: Array[String] = []
			for ch in str(ex.get("sound", {}).get("pattern", "")):
				beats.append("clap" if ch == "x" else "rest")
			return ", ".join(beats)
		"robot":   # "FORWARD, TURN RIGHT, FORWARD"
			return RobotCheck.words(RobotCheck.shortest(ex.get("board", {})))
		"label":   # "1: mouth, 2: stomach", pin by pin
			var pins: Array[String] = []
			for p in (ex.spots as Array).size():
				var i := -1
				for k in (ex.answer as Array).size():
					if int(ex.answer[k]) == p:
						i = k
				pins.append("%d: %s" % [p + 1, item_text(ex.labels[i]) if i >= 0 else "?"])
			return ", ".join(pins)
		"match":   # "cat: kitten, dog: puppy"
			var pairs: Array[String] = []
			for i in (ex.items as Array).size():
				pairs.append("%s: %s" % [item_text(ex.items[i]), item_text(ex.matches[int(ex.answer[i])])])
			return ", ".join(pairs)
	return ""


## Whether a number exercise's answer is grouped by thousands ("3,000"); a year is not ("1850").
static func grouped(ex: Dictionary) -> bool:
	return not (ex.get("year") is bool and ex.year)


## The pad's extra keys for a number exercise.
static func pad_keys(ex: Dictionary) -> Array[String]:
	if ex.get("pad") is Array:
		var out: Array[String] = []
		for k: Variant in ex.pad:
			if NumberPad.EXTRAS.has(str(k)):
				out.append(str(k))
		return out
	return NumberPad.keys_for(str(ex.get("answer", "")))


## A choice's or an item's words ("" for a picture without words).
static func item_text(item: Variant) -> String:
	if item is Dictionary:
		return str((item as Dictionary).get("text", ""))
	return str(item)


static func _choice_key(c: Variant) -> String:
	if item_text(c).length() > MAX_CHOICE:
		return ""
	if c is Dictionary:
		var d := c as Dictionary
		if not d.has("text") and not d.get("picture") is Dictionary:
			return ""
		return str(d.get("text", "")) + JSON.stringify(d.get("picture", {}), "", true)
	return str(c).strip_edges() if c is String else ""


static func _is_index(v: Variant, n: int) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and float(v) == floorf(float(v)) and int(v) >= 0 and int(v) < n
