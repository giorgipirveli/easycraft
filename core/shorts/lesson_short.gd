class_name LessonShort
extends RefCounted
## "Lesson in a minute" (owner #94, spec §5.12b): a Short made at run time from a written School unit's lesson (its
## cards: {text, picture?}). The unit's title with Professor Hoot, then its cards in turn: each card's picture pops in
## and slowly draws closer while its words are the caption and the voice; a card without a picture gets Hoot and its
## number. The minute is shared out: every card's first sentence (the cards without a picture go first when even that
## is too long, never the first card), then more sentences card by card while they fit; a sentence too long for the
## caption's band is split where it breathes (a semicolon, a colon, a comma).
## The end says where the whole lesson is: LEARN IT (the School on this unit). Made only when the feed needs it (the one
## on the screen and the next): hundreds of units cost nothing until watched.
## Owner #96's review (a lesson with no pictures was a row of numbers): a card without a picture borrows one of the unit's
## own exercise pictures (one that asks nothing: no "?" and no hidden part), else it shows its headline big (the words
## before its colon, or its first clause: "Producers are plants"; each sentence brings its own), popping, sliding or
## dropping in turn. The lesson's "Quick memory" (a question on an earlier unit, its answer in brackets) is left out:
## the minute teaches this unit.

const PREFIX := "lesson:"
const BUDGET := 60.0
const TITLE_MIN := 3.5
const END_CAPTION := "Tap LEARN IT to read it all and practise."
const END_SECONDS := 4.0
const SCENE_MIN := 3.0
const PAUSE := 0.9            # a breath after the voice, so the caption can be read to its end
const PICTURE_W := 340.0
const ZOOM := 1.05            # a picture draws slowly closer while its words are said
const HEADLINE_MOST := 44     # letters a card's big headline may have
const MEMORY := "Quick memory"  # a lesson's review of an earlier unit: left out of the minute
## Words a headline never ends on ("Insulators do not: plastic, ..." has none).
const DANGLING: Array[String] = ["not", "is", "are", "was", "were", "be", "do", "does", "the", "a", "an", "of", "to",
	"and", "or", "as", "like", "such", "for", "with", "in", "on", "at", "by", "from", "into", "than", "that", "include",
	"includes", "means", "called"]

static var _stop := RegEx.create_from_string("[.!?][\"”’)]*\\s+(?=[A-Z0-9\"“‘(])")


## The Short's id for a unit ("lesson:g4.science.circuits"), and back ("" when it is not one).
static func id_for(unit_id: String) -> String:
	return PREFIX + unit_id


static func unit_of(short_id: String) -> String:
	return short_id.trim_prefix(PREFIX) if short_id.begins_with(PREFIX) else ""


## The Short for written unit `unit_id` ({} when the unit has no lesson).
static func make(unit_id: String) -> Dictionary:
	var u := Curriculum.unit(unit_id)
	var c := Curriculum.content(unit_id)
	if u.is_empty() or c.is_empty() or (c.lesson as Array).is_empty():
		return {}
	var subject := str(u.subject)
	var tint := "#" + ShortRules.topic_colour(subject).darkened(0.25).to_html(false)
	var box := "#" + ShortRules.topic_colour(subject).darkened(0.45).to_html(false)
	var parts: Array = []   # per card: its sentences, each as its chunks
	var kept: Array = []
	for card: Dictionary in c.lesson:
		var list: Array = []
		for sentence in teaching(sentences(str(card.get("text", "")))):
			list.append(chunks(sentence))
		if not list.is_empty():   # a card that was only a Quick memory is left out, its picture with it
			parts.append(list)
			kept.append(card)
	if kept.is_empty():
		return {}
	var cards: Array = _with_pictures(kept, c.exercises)
	var title := str(u.title)
	var title_say := "A lesson in a minute: %s." % title
	var title_seconds := _round(maxf(TITLE_MIN, ShortRules.speech_seconds(title_say) + 0.6))
	var used := _share(parts, cards, BUDGET - title_seconds - END_SECONDS)
	var scenes: Array = [_title_scene(title, title_say, title_seconds, subject, int(u.grade), tint)]
	var content_start := scenes.size()
	var shown := 0
	for i in cards.size():
		if int(used[i]) == 0:
			continue
		shown += 1
		var first := true
		var head := ""
		for k in int(used[i]):
			var said := headline(str(parts[i][k][0]))   # each sentence brings its own headline when it has one
			var fresh := said != "" and said != head
			if said != "":
				head = said
			for chunk: String in parts[i][k]:
				scenes.append(_card_scene(chunk, cards[i], shown, first, tint, box, head, fresh))
				first = false
				fresh = false
	scenes.append(_end_scene(tint))
	_stretch(scenes, content_start, scenes.size() - 1)
	return {"id": id_for(unit_id), "title": title, "topic": subject, "grade": int(u.grade), "link": {"unit": unit_id},
		"lesson": true, "scenes": scenes}


## `text`'s sentences (a full stop inside a number, 2.5, stays).
static func sentences(text: String) -> Array[String]:
	var out: Array[String] = []
	var from := 0
	for m in _stop.search_all(text):
		out.append(text.substr(from, m.get_end() - from).strip_edges())
		from = m.get_end()
	var rest := text.substr(from).strip_edges()
	if rest != "":
		out.append(rest)
	return out


## A card's sentences without its "Quick memory" (the question on an earlier unit and its answer in brackets). Owner #94
## (lesson quality, round 2): the whole memory goes, its lead-in line and question too ("Quick memory: in grade 5 you
## learned latitude. What is the latitude of the Equator? (0°.)"), up to its bracketed answer, or up to the lesson's own
## "Today" or "Now" (kept); a memory whose answer has no brackets ("Expand 3(x + 2). Multiply both terms: 3x + 6.") and
## no "Today" after it is all memory.
static func teaching(list: Array[String]) -> Array[String]:
	var out: Array[String] = []
	var in_memory := false
	for sentence in list:
		if sentence.begins_with(MEMORY):
			in_memory = true
			continue
		if in_memory:
			if sentence.begins_with("(") and sentence.ends_with(")"):
				in_memory = false
				continue
			if not (sentence.begins_with("Today") or sentence.begins_with("Now")):
				continue
			in_memory = false
		out.append(sentence)
	return out


## A sentence in pieces the caption's band holds (LESSON_MAX_CAPTION letters), cut after a semicolon, a colon or a
## comma nearest the middle, else at the space nearest it. Joined with spaces they are the sentence again.
static func chunks(sentence: String) -> Array[String]:
	if sentence.length() <= ShortRules.LESSON_MAX_CAPTION:
		return [sentence]
	var cut := -1
	for mark: String in ["; ", ": ", ", ", " "]:
		var best := -1
		var from := 0
		while true:
			var at := sentence.find(mark, from)
			if at < 0:
				break
			var end := at + mark.length() - 1   # the space after the mark
			if end > 10 and end < sentence.length() - 10 \
					and (best < 0 or absi(end - sentence.length() / 2) < absi(best - sentence.length() / 2)):
				best = end
			from = at + 1
		if best > 0 and absi(best - sentence.length() / 2) < sentence.length() / 3:
			cut = best
			break
	if cut < 0:
		cut = sentence.rfind(" ", sentence.length() / 2)
	if cut <= 0:
		return [sentence.left(ShortRules.LESSON_MAX_CAPTION)]
	var out: Array[String] = []
	out.append_array(chunks(sentence.left(cut)))
	out.append_array(chunks(sentence.substr(cut + 1)))
	return out


## How many sentences of each card fit in `room` seconds: a first sentence each (cards without a picture give way first,
## then the last ones; the first card and two cards always stay), then more, card by card, while they fit.
static func _share(parts: Array, cards: Array, room: float) -> Array:
	var used: Array = []
	for i in parts.size():
		used.append(1 if not (parts[i] as Array).is_empty() else 0)
	var total := _time(parts, used)
	while total > room and _kept(used) > 2:
		var drop := -1
		for i in range(parts.size() - 1, 0, -1):
			if int(used[i]) > 0 and not (cards[i] as Dictionary).has("picture"):
				drop = i
				break
		if drop < 0:
			for i in range(parts.size() - 1, 0, -1):
				if int(used[i]) > 0:
					drop = i
					break
		used[drop] = 0
		total = _time(parts, used)
	var grew := true
	while grew:
		grew = false
		for i in parts.size():
			if int(used[i]) == 0 or int(used[i]) >= (parts[i] as Array).size():
				continue
			var more := _sentence_time(parts[i][int(used[i])])
			if total + more <= room:
				used[i] = int(used[i]) + 1
				total += more
				grew = true
	return used


static func _kept(used: Array) -> int:
	var n := 0
	for u: int in used:
		if u > 0:
			n += 1
	return n


static func _time(parts: Array, used: Array) -> float:
	var t := 0.0
	for i in parts.size():
		for k in int(used[i]):
			t += _sentence_time(parts[i][k])
	return t


static func _sentence_time(pieces: Array) -> float:
	var t := 0.0
	for p: String in pieces:
		t += _scene_seconds(p)
	return t


static func _scene_seconds(words: String) -> float:
	return _round(maxf(SCENE_MIN, ShortRules.speech_seconds(words) + PAUSE))


static func _round(s: float) -> float:
	return ceilf(s * 10.0) / 10.0


## A short lesson is held longer on its cards, so every Short lasts half a minute at least.
static func _stretch(scenes: Array, from: int, to: int) -> void:
	var total := 0.0
	for s: Dictionary in scenes:
		total += float(s.seconds)
	var short := ShortRules.LESSON_MIN_SECONDS - total
	if short <= 0.0 or to <= from:
		return
	var each := _round(short / (to - from))
	for i in range(from, to):
		scenes[i].seconds = minf(float(scenes[i].seconds) + each, ShortRules.SCENE_MAX)
		_hold(scenes[i])


## After a stretch, a picture's slow zoom lasts the whole scene again.
static func _hold(scene: Dictionary) -> void:
	for a: Dictionary in scene.actors:
		for m: Dictionary in a.moves:
			if m.do == "grow":
				m.dur = maxf(float(scene.seconds) - float(m.at) - 0.1, 0.1)


# --- The scenes -----------------------------------------------------------------------------------------------------

static func _title_scene(title: String, say: String, seconds: float, subject: String, grade: int, tint: String) -> Dictionary:
	return {"seconds": seconds, "background": "tint", "tint": tint, "caption": title, "say": say,
		"sounds": [{"at": 0.2, "effect": "pop"}, {"at": 0.5, "tune": {"kind": "notes", "notes": ["C5", "E5", "G5:2"], "beat": 0.16}}],
		"actors": [
			{"kind": "words", "text": "LESSON IN A MINUTE", "at": [180, 70], "size": 24, "color": "ink", "box": "yellow",
				"moves": [{"do": "pop", "at": 0.2}]},
			{"kind": "words", "text": title, "at": [180, 185], "size": 38, "width": 320, "color": "white",
				"moves": [{"do": "draw", "at": 0.5, "dur": 1.0}]},
			{"kind": "character", "who": "hoot", "at": [110, 360], "size": 150,
				"moves": [{"do": "drop", "at": 0.1, "height": 420}, {"do": "bounce", "at": 1.6, "height": 18}]},
			{"kind": "words", "text": "%s · Grade %d" % [ShortRules.topic_title(subject), grade], "at": [262, 360], "size": 22,
				"width": 170, "color": "white", "box": "ink", "moves": [{"do": "slide", "at": 0.7, "from": [520, 360]}]},
		]}


## The lesson's cards, those without a picture given one of the unit's exercise pictures that asks nothing, in turn.
static func _with_pictures(lesson: Array, exercises: Array) -> Array:
	var used: Array = []
	for card: Dictionary in lesson:
		if card.has("picture"):
			used.append(card.picture)
	var spare: Array = []
	for ex: Variant in exercises:
		var pic: Variant = (ex as Dictionary).get("picture") if ex is Dictionary else null
		if pic is Dictionary and not used.has(pic) and not spare.has(pic) and asks_nothing(pic):
			spare.append(pic)
	var out: Array = []
	for card: Dictionary in lesson:
		var copy := card.duplicate()
		if not copy.has("picture") and not spare.is_empty():
			copy.picture = spare.pop_front()
		out.append(copy)
	return out


## A picture that shows and asks nothing: no "?" anywhere in it, no hidden, missing or unknown part.
static func asks_nothing(pic: Dictionary) -> bool:
	if SchoolPicture.problem(pic) != "" or JSON.stringify(pic).contains("?"):
		return false
	for key: String in ["hide", "unknown", "missing", "mark", "blank", "ask", "question", "hidden"]:
		if pic.has(key):
			return false
	return true


## A card's headline, shown big when it has no picture: the words before its colon, else its first clause, else the
## whole sentence when it is short ("" when none fits HEADLINE_MOST letters).
static func headline(sentence: String) -> String:
	var t := sentence.strip_edges()
	var at := -1   # the first of its colon, semicolon or comma
	for mark: String in [":", ";", ","]:
		var found := t.find(mark)
		if found >= 0 and (at < 0 or found < at):
			at = found
	var head := t.left(at).strip_edges() if at >= 0 else t.trim_suffix(".").strip_edges()
	if head.length() < 4 or head.length() > HEADLINE_MOST:
		return ""
	var words := head.to_lower().split(" ", false)
	if DANGLING.has(words[words.size() - 1]):
		return ""
	return head


static func _card_scene(words: String, card: Dictionary, number: int, first: bool, tint: String, box: String = "#1f2a4a",
		head: String = "", fresh: bool = false) -> Dictionary:
	var seconds := _scene_seconds(words)
	var actors: Array = []
	var sounds: Array = []
	if card.has("picture"):
		var zoom_at := 0.6 if first else 0.0
		actors.append({"kind": "picture", "picture": card.picture, "at": [180, 250], "w": PICTURE_W,
			"moves": [{"do": "pop" if first else "appear", "at": 0.1 if first else 0.0},
				{"do": "grow", "at": zoom_at, "dur": maxf(seconds - zoom_at - 0.1, 0.1), "to": ZOOM, "ease": "linear"}]})
		if first:
			sounds.append({"at": 0.1, "effect": "pop"})
	elif head != "":   # its headline, big, coming in a new way each card
		var entrances: Array = [{"do": "pop", "at": 0.2}, {"do": "slide", "at": 0.2, "from": [-200, 170]},
			{"do": "drop", "at": 0.1, "height": 260}]
		var how: Dictionary = entrances[number % 3] if first else {"do": "pop", "at": 0.15}
		var arrives := first or fresh   # a card's first scene, or its next sentence's new headline
		actors.append({"kind": "shape", "shape": "spark", "at": [180, 170], "size": 300, "color": "yellow",
			"moves": [{"do": "draw", "at": 0.5, "dur": 0.6}, {"do": "out", "at": 1.3}] if arrives else []})
		actors.append({"kind": "words", "text": head, "at": [180, 170], "size": 30, "width": 290, "color": "white", "box": box,
			"moves": [how if arrives else {"do": "appear", "at": 0.0}, {"do": "pulse", "at": 1.6, "amount": 0.06}]})
		actors.append({"kind": "shape", "shape": "circle", "at": [300, 330], "size": 64, "color": "cream",
			"moves": [{"do": "pop" if first else "appear", "at": 0.5 if first else 0.0}]})
		actors.append({"kind": "words", "text": str(number), "at": [300, 331], "size": 34, "color": "ink", "on": "cream",
			"moves": [{"do": "pop" if first else "appear", "at": 0.6 if first else 0.0}]})
		actors.append({"kind": "character", "who": "hoot", "at": [92, 350], "size": 130,
			"moves": [{"do": "slide", "at": 0.3, "from": [-120, 350]}, {"do": "bounce", "at": 1.4, "height": 14}] if first else
				[{"do": "bounce", "at": 0.4, "height": 10}]})
		if arrives:
			sounds.append({"at": 0.3 if first else 0.15, "effect": "pop"})
	else:
		actors.append({"kind": "shape", "shape": "spark", "at": [238, 220], "size": 230, "color": "yellow",
			"moves": [{"do": "draw", "at": 0.25, "dur": 0.6}] if first else []})
		actors.append({"kind": "shape", "shape": "circle", "at": [238, 220], "size": 150, "color": "cream",
			"moves": [{"do": "pop" if first else "appear", "at": 0.2 if first else 0.0}, {"do": "pulse", "at": 1.2}]})
		actors.append({"kind": "words", "text": str(number), "at": [238, 222], "size": 80, "color": "ink", "on": "cream",
			"moves": [{"do": "pop" if first else "appear", "at": 0.35 if first else 0.0}]})
		actors.append({"kind": "character", "who": "hoot", "at": [92, 360], "size": 130,
			"moves": [{"do": "slide", "at": 0.1, "from": [-120, 360]}] if first else []})
		if first:
			sounds.append({"at": 0.35, "effect": "ding"})
	return {"seconds": seconds, "background": "tint", "tint": tint, "caption": words, "say": words, "sounds": sounds,
		"actors": actors}


static func _end_scene(tint: String) -> Dictionary:
	return {"seconds": END_SECONDS, "background": "tint", "tint": tint, "caption": END_CAPTION, "say": END_CAPTION,
		"sounds": [{"at": 0.4, "effect": "chime"}],
		"actors": [
			{"kind": "character", "who": "hoot", "at": [110, 330], "size": 160,
				"moves": [{"do": "pop", "at": 0.1}, {"do": "bounce", "at": 1.0, "height": 24}]},
			{"kind": "words", "text": "LEARN IT", "at": [252, 190], "size": 40, "color": "white", "box": "green",
				"moves": [{"do": "pop", "at": 0.4}, {"do": "pulse", "at": 1.4, "times": 2}]},
		]}
