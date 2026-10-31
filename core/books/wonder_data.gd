class_name WonderData
extends RefCounted
## The books' part of the profile (M3 Task 21b; ProfileData.wonder): the Animal Book's marks (AnimalBookRules),
## the saving list (SavingRules), the Secret Book pages already rewarded (BookPages), the universes explored
## (the Hub Tree's crowns, HubTreeRules) and the Space Book's marks (spec §21b.2: the Star Map's bodies seen and landed
## on, SpaceBookRules), and the Wonders Passport (owner #78, spec §24: the wonders' stamps and their fact quizzes'
## answers, WondersPassportRules), and universe 6's Cave Book (the Glow Caves' wonders solved and sights found,
## GlowWonderRules.BOOK). Account-wide, parsed field by field (a bad field falls back on its
## own), kept by the server backup (merge_from never loses anything). Nothing here has a date or a clock. The
## Memory Book is not here: it stays on this device (MemoryBook).

## The Animal Book's marks: met, fed, a friend (a pet). Fed and friend include met.
const MET := 1
const FED := 2
const FRIEND := 4
const ALL_MARKS := MET | FED | FRIEND
const MAX_SPECIES := 64
const MAX_UNIVERSES := 20
## The Space Book's marks: a body's card opened on the Star Map (seen), a world landed on (landed includes seen).
const SEEN := 1
const LANDED := 2
const ALL_BODY_MARKS := SEEN | LANDED
## Owner #78: the Wonders Passport's stamp, and the fact quizzes' answers.
const STAMPED := 1
const ALL_WONDER_MARKS := STAMPED
const RIGHT := 1
const TRIED := 2
const ALL_QUIZ_MARKS := RIGHT | TRIED
## Universe 6: a Cave Book page found.
const FOUND := 1
const ALL_CAVE_MARKS := FOUND

## Species (String, AnimalRules.SPECIES) -> marks.
var animals := {}
## The saving list: {"kind": SavingRules.SHOP | LOOK, "id": String}, in the order the child added them.
var saving: Array[Dictionary] = []
## Secret Book pages whose reward was given (BookPages ids), in the order they were done.
var pages: Array[String] = []
## Universes the child played a world of (Survivor or Sandbox), in ladder order.
var universes: Array[int] = []
## The Space Book: a Star Map body's id (String, StarMap) -> marks (SEEN, LANDED).
var bodies := {}
## Owner #78 (spec §24): the Wonders Passport: a wonder's id (String, WonderFacts) -> marks (STAMPED: visited).
var wonders := {}
## The wonders' fact quizzes: a question's id (String, WonderFacts) -> RIGHT (right the first time: it paid) and/or
## TRIED (answered, not right the first time: it never pays). Answered once, never paid again.
var quiz := {}
## Universe 6, the Cave Book: a page's kind (String, GlowWonderRules.BOOK) -> FOUND.
var caves := {}


func is_empty() -> bool:
	return animals.is_empty() and saving.is_empty() and pages.is_empty() and universes.is_empty() and bodies.is_empty() \
		and wonders.is_empty() and quiz.is_empty() and caves.is_empty()


## Universe 6: the Cave Book's page `kind` (a wonder solved, a sight found); true the first time.
func find_cave(kind: StringName) -> bool:
	if not GlowWonderRules.BOOK.has(kind) or cave_found(kind):
		return false
	caves[str(kind)] = FOUND
	return true


func cave_found(kind: StringName) -> bool:
	return int(caves.get(str(kind), 0)) & FOUND != 0


## Owner #78: the child reached wonder `id`: its stamp in the Wonders Passport; true the first time.
func stamp(id: StringName) -> bool:
	if not WonderFacts.has(id):
		return false
	var was := int(wonders.get(str(id), 0))
	wonders[str(id)] = was | STAMPED
	return was & STAMPED == 0


func stamped(id: StringName) -> bool:
	return int(wonders.get(str(id), 0)) & STAMPED != 0


## Owner #78: question `qid` of a wonder's fact quiz was answered (`right`). Only the first answer counts: true when it
## pays (right the first time); a question answered before never pays again.
func answer(qid: String, right: bool) -> bool:
	if WonderFacts.question(qid).is_empty() or quiz.has(qid):
		return false
	quiz[qid] = RIGHT if right else TRIED
	return right


## Right the first time (a star in the passport).
func quiz_right(qid: String) -> bool:
	return int(quiz.get(qid, 0)) & RIGHT != 0


## The card of Star Map body `id` was opened: true the first time (the Space Book gains it).
func see_body(id: StringName) -> bool:
	return _mark_body(str(id), SEEN)


## The child landed on space world u: true the first time (its body is seen and landed on); false for a world that is
## not a Star Map body to land on (a universe, a number no body has).
func land_on_world(u: int) -> bool:
	if not SpaceRules.is_space(u):
		return false
	var id := StarMap.body_for_world(u)
	return id != &"" and _mark_body(str(id), SEEN | LANDED)


func _mark_body(id: String, marks: int) -> bool:
	if StarMap.body(StringName(id)).is_empty():
		return false
	var was := int(bodies.get(id, 0))
	bodies[id] = was | marks
	return bodies[id] != was


## Universe u was played for the first time: true (the Hub Tree grows a crown, the Memory Book may keep it).
func explore(u: int) -> bool:
	if u < 1 or u > MAX_UNIVERSES or universes.has(u):
		return false
	universes.append(u)
	universes.sort()
	return true


func to_dict() -> Dictionary:
	return {"animals": animals.duplicate(), "saving": saving.duplicate(true), "pages": pages.duplicate(),
		"universes": universes.duplicate(), "bodies": bodies.duplicate(), "wonders": wonders.duplicate(),
		"quiz": quiz.duplicate(), "caves": caves.duplicate()}


static func from_dict(v: Variant) -> WonderData:
	var w := WonderData.new()
	if not v is Dictionary:
		return w
	var src: Dictionary = v
	var a: Variant = src.get("animals")
	if a is Dictionary:
		for sp: Variant in a:
			var m: Variant = a[sp]
			if sp is String and AnimalRules.SPECIES.has(StringName(sp)) and typeof(m) in [TYPE_INT, TYPE_FLOAT] \
					and is_finite(float(m)) and float(m) == floorf(float(m)) and int(m) >= 1 and int(m) <= ALL_MARKS \
					and w.animals.size() < MAX_SPECIES:
				w.animals[sp] = int(m)
	var s: Variant = src.get("saving")
	if s is Array:
		for e: Variant in s:
			var clean := SavingRules.clean(e)
			if not clean.is_empty() and not SavingRules.has(w, clean.kind, clean.id) and w.saving.size() < SavingRules.MAX:
				w.saving.append(clean)
	var p: Variant = src.get("pages")
	if p is Array:
		for id: Variant in p:
			if id is String and BookPages.is_page(id) and not w.pages.has(id):
				w.pages.append(id)
	var bs: Variant = src.get("bodies")
	if bs is Dictionary:
		for id: Variant in bs:
			var m: Variant = bs[id]
			if id is String and typeof(m) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(m)) and float(m) == floorf(float(m)) \
					and int(m) >= 1 and int(m) <= ALL_BODY_MARKS:
				w._mark_body(id, int(m) | SEEN)
	var ws: Variant = src.get("wonders")   # owner #78: the Wonders Passport
	if ws is Dictionary:
		for id: Variant in ws:
			var m: Variant = ws[id]
			if id is String and WonderFacts.has(StringName(id)) and _mark(m, ALL_WONDER_MARKS):
				w.wonders[id] = int(m)
	var qz: Variant = src.get("quiz")
	if qz is Dictionary:
		for qid: Variant in qz:
			var m: Variant = qz[qid]
			if qid is String and not WonderFacts.question(qid).is_empty() and _mark(m, ALL_QUIZ_MARKS):
				w.quiz[qid] = int(m)
	var cv: Variant = src.get("caves")   # universe 6: the Cave Book
	if cv is Dictionary:
		for kind: Variant in cv:
			if kind is String and GlowWonderRules.BOOK.has(StringName(kind)) and _mark(cv[kind], ALL_CAVE_MARKS):
				w.caves[kind] = int(cv[kind])
	var u: Variant = src.get("universes")
	if u is Array:
		for n: Variant in u:
			if typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)) and float(n) == floorf(float(n)):
				w.explore(int(n))
	return w


## Keeps the best of both copies (the server backup's merge, ProfileBackup): every mark, every page and
## universe; the saving list is this copy's with the other's added after it.
func merge_from(other: WonderData) -> void:
	for sp: String in other.animals:
		if animals.has(sp) or animals.size() < MAX_SPECIES:
			animals[sp] = int(animals.get(sp, 0)) | int(other.animals[sp])
	for e in other.saving:
		if not SavingRules.has(self, e.kind, e.id) and saving.size() < SavingRules.MAX:
			saving.append(e.duplicate())
	for id in other.pages:
		if not pages.has(id):
			pages.append(id)
	for n in other.universes:
		explore(n)
	for id: String in other.bodies:
		_mark_body(id, int(other.bodies[id]))
	for id: String in other.wonders:   # owner #78: every stamp and every answer of both copies
		wonders[id] = int(wonders.get(id, 0)) | int(other.wonders[id])
	for qid: String in other.quiz:
		quiz[qid] = int(quiz.get(qid, 0)) | int(other.quiz[qid])
	for kind: String in other.caves:   # universe 6: every Cave Book page of both copies
		caves[kind] = int(caves.get(kind, 0)) | int(other.caves[kind])


## A saved mark: a whole number from 1 to `all`.
static func _mark(m: Variant, all: int) -> bool:
	return typeof(m) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(m)) and float(m) == floorf(float(m)) and int(m) >= 1 \
		and int(m) <= all
