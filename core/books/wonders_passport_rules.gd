class_name WondersPassportRules
extends RefCounted
## The Wonders Passport (owner #78, spec §24): a page of the Books with a stamp for every wonder of both tours (the
## Seven Wonders of the Ancient World, the New Seven Wonders: WonderFacts), stamped the first time the child reaches it (WonderData.stamp, saved in the profile and merged by the
## server backup like the Space Book's marks), and each wonder's fact quiz: a few questions, each paying
## EarnRules.FACT_QUIZ_GOLD once when it is answered right the first time (never for a question answered before, never
## for time or for coming back: the fair-fun rules, spec §6). Pure rules; the page is WondersPassportPage, the quiz
## WonderQuizView.


## The passport's stamps in the tour's order: [{id, name, stamped, stars (questions right the first time), questions}].
static func stamps(w: WonderData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in WonderFacts.ORDER:
		var qs: Array = WonderFacts.of(id).get("quiz", [])
		var stars := 0
		for q: Dictionary in qs:
			if w.quiz_right(str(q.id)):
				stars += 1
		out.append({"id": id, "name": WonderFacts.display_name(id), "stamped": w.stamped(id), "stars": stars,
			"questions": qs.size()})
	return out


## "3 of 7 stamps · 4 quiz stars" (the stars once there is one).
static func count_words(w: WonderData) -> String:
	var stamped := 0
	var stars := 0
	for e in stamps(w):
		stamped += 1 if bool(e.stamped) else 0
		stars += int(e.stars)
	var words := "%d of %d stamps" % [stamped, WonderFacts.ORDER.size()]
	return words + (" · %d quiz stars" % stars if stars > 0 else "")


## Where to get a stamp not stamped yet (a tour away from the landing square: its way there first).
static func clue(id: StringName) -> String:
	var way := str(WonderFacts.tour_info(WonderFacts.tour_of(id)).get("way", ""))
	if way != "":
		return "Fly up to space, tap Earth on the Star Map and land at the Wonders of the World. Then %s and walk to %s." \
			% [way, WonderFacts.called(id)]
	return "Fly up to space, tap Earth on the Star Map and land at the Wonders of the World. Then walk to %s." \
		% WonderFacts.called(id)


## How many of tour `tour`'s wonders are stamped.
static func tour_stamped(w: WonderData, tour: StringName) -> int:
	var n := 0
	for id: StringName in WonderFacts.tour_ids(tour):
		n += 1 if w.stamped(id) else 0
	return n


## What a new stamp says (`id`: the wonder just stamped; its tour's last stamp says so).
static func stamp_words(w: WonderData, id: StringName = &"") -> String:
	var n := stamps(w).filter(func(e: Dictionary) -> bool: return bool(e.stamped)).size()
	if n >= WonderFacts.ORDER.size():
		return "Stamp! Your Wonders Passport is full: you visited all %d wonders!" % n
	var tour := WonderFacts.tour_of(id)
	var ids := WonderFacts.tour_ids(tour)
	if tour != &"" and tour_stamped(w, tour) >= ids.size():
		return "Stamp! You have all %d stamps of %s! %d of %d wonders in your Wonders Passport." % [ids.size(),
			str(WonderFacts.tour_info(tour).name), n, WonderFacts.ORDER.size()]
	return "Stamp! %d of %d wonders in your Wonders Passport." % [n, WonderFacts.ORDER.size()]


## After a wonder is reached: "2 of 7 wonders visited! Next: the Colossus of Rhodes. Follow the arrow." (the guide's
## checklist, PlanetGuideRules).
static func progress_words(list: Array[Dictionary], from: Vector3) -> String:
	var done := list.filter(func(e: Dictionary) -> bool: return bool(e.found)).size()
	if done >= list.size():
		return "You visited all %d wonders! Take their quizzes in your Wonders Passport (the BOOK)." % list.size()
	return "%d of %d wonders visited! Next: %s. Follow the arrow." % [done, list.size(), _called(PlanetGuideRules.next(list, from))]


## A guide's entry as a sentence says it ("the Colossus of Rhodes", "Petra").
static func _called(e: Dictionary) -> String:
	var id := StringName(e.get("id", &""))
	return WonderFacts.called(id) if WonderFacts.has(id) else "the " + str(e.get("name", ""))


## After a wonder of tour `tour` is reached: how many of that tour are visited and which is next; once the tour is done,
## where the next tour not done waits, in the tours' order (`list`: the guide's checklist of every tour). Its way: the
## road to it, or (back to the landing square's tour) the road this tour is at the end of.
static func tour_progress_words(list: Array[Dictionary], from: Vector3, tour: StringName) -> String:
	var mine := list.filter(func(e: Dictionary) -> bool: return WonderFacts.tour_of(e.id) == tour)
	var done := mine.filter(func(e: Dictionary) -> bool: return bool(e.found)).size()
	var name := str(WonderFacts.tour_info(tour).get("name", "the wonders"))
	if done < mine.size():
		var typed: Array[Dictionary] = []
		typed.assign(mine)
		return "%d of %d of %s visited! Next: %s. Follow the arrow." % [done, mine.size(), name,
			_called(PlanetGuideRules.next(typed, from))]
	if list.all(func(e: Dictionary) -> bool: return bool(e.found)):
		return progress_words(list, from)
	var other := &""
	for t: StringName in WonderFacts.TOUR_IDS:
		if t != tour and list.any(func(e: Dictionary) -> bool: return WonderFacts.tour_of(e.id) == t and not bool(e.found)):
			other = t
			break
	var road := str(WonderFacts.tour_info(other).road)
	if road == "":
		road = str(WonderFacts.tour_info(tour).road)
	return "You visited all %d of %s! %s wait along the %s. Follow the arrow." % [mine.size(), name,
		str(WonderFacts.tour_info(other).heading), road]


# --- The fact quiz ---

## Wonder `id`'s questions ({id, q, choices, right}).
static func questions(id: StringName) -> Array:
	return WonderFacts.of(id).get("quiz", [])


## The quiz may be taken once the wonder is stamped (a fact quiz at a wonder: the child has been there).
static func may_quiz(w: WonderData, id: StringName) -> bool:
	return w.stamped(id) and not questions(id).is_empty()


## Choice `pick` for question `qid`: {right, gold (EarnRules.FACT_QUIZ_GOLD the first time it is right, else 0),
## first (the first answer to it), words (what the child hears)}. Records the first answer in `w`.
static func answer(w: WonderData, qid: String, pick: int) -> Dictionary:
	var q := WonderFacts.question(qid)
	if q.is_empty():
		return {"right": false, "gold": 0, "first": false, "words": ""}
	var right := pick == int(q.right)
	var first := not w.quiz.has(qid)
	var pays := w.answer(qid, right)
	var gold := EarnRules.FACT_QUIZ_GOLD if pays else 0
	var said := ""
	if right:
		said = "Right! +%d gold!" % gold if gold > 0 else "Right!"
	else:
		said = "Not quite. The answer is: %s." % str((q.choices as Array)[int(q.right)])
	return {"right": right, "gold": gold, "first": first, "words": said}
