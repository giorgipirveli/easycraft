extends GutTest
## Owner #94 ("lessons quality improvements up to grade 7"; brief docs/superpowers/plans/2026-09-30-lesson-quality-brief.md):
## the School's quality bar for a written unit, from the way the research says a unit teaches
## (docs/design/school-curriculum-research.md §5.3):
## - the lesson opens with a memory question ("Quick memory:" or "Remember?") and ends with something to try in the
##   world or what comes next (rules 1, 7 and 8), in 4-8 cards;
## - its pictures teach: one at least, two in the subjects that draw (maths, science, geography, D&T, computing, art,
##   music);
## - its practice has three kinds of exercise at least, three hand-written exercises or a generator at every level, a
##   hint on every one that is a real strategy (three words or more, never only "…") and a worked answer (four words
##   or more, or a worked sum), and no hint that says the right choice's words;
## - no body-shape words outside health and PE (§5.4 rule 4; the health units' kind words);
## - (round 3, 2026-10-01) practice that teaches by doing: at most MAX_CHOICE_SHARE of a unit's hand-written exercises
##   are choice or true-or-false; the rest sort, match, order, label, number, build, point, rhythm, robot or mix.
## The units not there yet are NOT_YET (and NOT_YET_VARIED for the variety rule alone); the lists only shrink
## (`python3 tools/school_audit.py --not-yet` prints them, and the audit measures the same rules as `bar`). Grades 3-6 every subject; grade 7 the subjects written before the
## owner paused it (#94): maths, science, English, history, geography, citizenship (from round 2, 2026-10-01),
## computing, art and music; and health and PE, D&T and projects since they were written (2026-10-17).

const GRADES: Array[int] = [3, 4, 5, 6, 7]
const GRADE7_SUBJECTS: Array[String] = ["maths", "science", "english", "history", "geography", "citizenship",
	"computing", "art", "music", "health_pe", "design_tech", "projects"]
const DRAWING_SUBJECTS: Array[String] = ["maths", "science", "geography", "design_tech", "computing", "art", "music"]
const MIN_CARDS := 4
const MIN_KINDS := 3
const MIN_A_LEVEL := 3
const MIN_HINT_WORDS := 3
const MIN_EXPLAIN_WORDS := 4
const BODY_WORDS := "\\b(skinny|scrawny|chubby|plump|overweight|fatty(?! acids?)|slim|slender)\\b"
## The units under the bar today (owner #94's audit, 2026-09-30: 395 of 614); a unit left the list when it was
## rewritten. Empty since round 5 (2026-10-01): every unit in scope meets the bar, and a new or changed unit must too.
const NOT_YET: Array[String] = []
## Round 3 (2026-10-01, the lead's third brief): at most this share of a unit's hand-written exercises are choice or
## true-or-false (100 units were over 80% and 352 over 70%, most of grade 3-7 English and science).
const MAX_CHOICE_SHARE := 0.7
## The units still over MAX_CHOICE_SHARE and under the bar for that alone; a unit leaves when it has its variety.
const NOT_YET_VARIED: Array[String] = []

var _words := RegEx.create_from_string("[A-Za-z][A-Za-z'’-]*|\\d+")
var _next := RegEx.create_from_string("\\bnext\\b")
var _body := RegEx.create_from_string(BODY_WORDS)


func _in_scope() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in GRADES:
		for s: Dictionary in Curriculum.subjects(g):
			if g == 7 and not GRADE7_SUBJECTS.has(str(s.id)):
				continue
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				if Curriculum.has_content(str(u.id)):
					out.append({"id": str(u.id), "subject": str(s.id)})
	return out


func _word_count(t: String) -> int:
	return _words.search_all(t).size()


func _weak_hint(h: String) -> bool:
	var t := h.strip_edges()
	return t.ends_with("…") or t.ends_with("...") or _word_count(t) < MIN_HINT_WORDS


func _thin_explain(e: String) -> bool:
	return _word_count(e) < MIN_EXPLAIN_WORDS and not e.contains("=")


## A choice's hint that says the right choice's words (four letters or more) when the question does not.
func _gives_away(ex: Dictionary) -> bool:
	if str(ex.type) != "choice":
		return false
	var right := ExerciseCheck.item_text((ex.choices as Array)[int(ex.answer)]).to_lower().strip_edges()
	right = right.trim_suffix(".")
	if right.length() < 4:
		return false
	return str(ex.hint).to_lower().contains(right) and not str(ex.prompt).to_lower().contains(right)


func _texts(c: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for card: Dictionary in c.lesson:
		out.append(str(card.get("text", "")))
	for ex: Dictionary in c.exercises:
		for key: String in ["prompt", "hint", "explain"]:
			out.append(str(ex.get(key, "")))
		for it: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []) \
				+ ex.get("labels", []):
			out.append(ExerciseCheck.item_text(it))
	return out


## More than MAX_CHOICE_SHARE of the hand-written exercises are choice or true-or-false (round 3).
func _mostly_choice(exercises: Array) -> bool:
	if exercises.is_empty():
		return false
	var choosing := 0
	for ex: Dictionary in exercises:
		if str(ex.type) in ["choice", "truefalse"]:
			choosing += 1
	return float(choosing) / exercises.size() > MAX_CHOICE_SHARE + 0.000001


## What keeps a unit under the bar ([] when it meets it); the audit's `bar_problems` says the same.
func bar(id: String, subject: String) -> Array[String]:
	var c := Curriculum.content(id)
	var lesson: Array = c.lesson
	var out: Array[String] = []
	var first := str((lesson[0] as Dictionary).get("text", "")) if not lesson.is_empty() else ""
	var last := str((lesson[-1] as Dictionary).get("text", "")).to_lower() if not lesson.is_empty() else ""
	if not (first.begins_with("Quick memory:") or first.begins_with("Remember?")):
		out.append("memory")
	if not (last.contains("try it in the world") or _next.search(last) != null):
		out.append("world")
	if lesson.size() < MIN_CARDS or lesson.size() > Curriculum.MAX_CARDS:
		out.append("cards")
	var pictures := 0
	for card: Dictionary in lesson:
		if card.has("picture"):
			pictures += 1
	if pictures < (2 if DRAWING_SUBJECTS.has(subject) else 1):
		out.append("pictures")
	var kinds := {}
	var levels := {1: 0, 2: 0, 3: 0}
	for ex: Dictionary in c.exercises:
		kinds[str(ex.type)] = true
		levels[int(ex.level)] = int(levels.get(int(ex.level), 0)) + 1
	if kinds.size() < MIN_KINDS:
		out.append("kinds")
	if _mostly_choice(c.exercises):
		out.append("variety")
	var generated := {}
	for g: Dictionary in c.generators:
		generated[int(g.get("level", 1))] = true
	for lv: int in [1, 2, 3]:
		if int(levels[lv]) < MIN_A_LEVEL and not generated.has(lv):
			out.append("levels")
			break
	for ex: Dictionary in c.exercises:
		if _weak_hint(str(ex.get("hint", ""))):
			out.append("hints")
			break
	for ex: Dictionary in c.exercises:
		if _thin_explain(str(ex.get("explain", ""))):
			out.append("explains")
			break
	for ex: Dictionary in c.exercises:
		if _gives_away(ex):
			out.append("gives")
			break
	if subject != "health_pe":
		for t in _texts(c):
			if _body.search(t.to_lower()) != null:
				out.append("body")
				break
	return out


func test_every_unit_meets_the_bar_or_is_not_yet_rewritten() -> void:
	var under := 0
	var units := _in_scope()
	var unvaried := 0
	for u in units:
		var why := bar(str(u.id), str(u.subject))
		if NOT_YET.has(str(u.id)):
			under += 1
			assert_ne(why, [] as Array[String], "%s meets the bar now: take it out of NOT_YET" % u.id)
			continue
		if NOT_YET_VARIED.has(str(u.id)):
			unvaried += 1
			assert_true(why.has("variety"), "%s has its variety now: take it out of NOT_YET_VARIED" % u.id)
			why.erase("variety")
		assert_eq(why, [] as Array[String], "%s is under the bar" % u.id)
	gut.p("%d of %d units under the bar; %d still mostly choice" % [under, units.size(), unvaried])


func test_not_yet_names_only_written_units_and_stays_empty() -> void:
	var ids := {}
	for u in _in_scope():
		ids[str(u.id)] = true
	assert_gt(ids.size(), 640, "grades 3-6 and grade 7's written subjects are in scope")
	for id in NOT_YET:
		assert_true(ids.has(id), "%s is a written unit in scope" % id)
	assert_eq(NOT_YET.size(), 0, "the list only shrinks, and it has been empty since round 5 (2026-10-01)")
	var seen := {}
	for id in NOT_YET_VARIED:
		assert_true(ids.has(id), "%s (NOT_YET_VARIED) is a written unit in scope" % id)
		assert_false(seen.has(id), "%s is listed once" % id)
		seen[id] = true


## Owner #94 (round 2): the moving kinds made for the School (SchoolPictureMotion.KINDS: the water cycle, the Moon's
## phases, orbits, pendulums, a rocket's stages) each teach on a lesson card, and an exercise that asks its picture to
## move ("animate": true) has a picture that moves.
func test_every_moving_kind_teaches_on_a_lesson_card() -> void:
	var used := {}
	for u in _in_scope():
		var c := Curriculum.content(str(u.id))
		for card: Dictionary in c.lesson:
			if card.has("picture") and SchoolPicture.animates(card.picture):
				used[str((card.picture as Dictionary).kind)] = true
		for ex: Dictionary in c.exercises:
			if ex.has("picture") and bool((ex.picture as Dictionary).get("animate", false)):
				assert_true(SchoolPicture.animates(ex.picture), "%s: an exercise's moving picture moves" % u.id)
	for kind: String in SchoolPictureMotion.KINDS:
		assert_true(used.has(kind), "a lesson card teaches with the moving %s" % kind)


func test_the_bar_finds_what_it_should() -> void:
	assert_true(_weak_hint("thrifty…"), "a hint of '…' is weak")
	assert_true(_weak_hint("Good feeling."), "two words are not a strategy")
	assert_false(_weak_hint("Careful with money, in a good way."), "a strategy is a hint")
	assert_true(_thin_explain("Yes."), "a word is not a worked answer")
	assert_false(_thin_explain("60 ÷ 6 = 10."), "a worked sum is")
	var tells := {"type": "choice", "prompt": "Which word sounds good?", "choices": ["thrifty", "stingy"], "answer": 0,
		"hint": "Thrifty sounds good.", "explain": "Thrifty sounds good; stingy sounds mean."}
	assert_true(_gives_away(tells), "a hint that says the answer")
	tells.hint = "Which word would you like someone to call you?"
	assert_false(_gives_away(tells), "a hint that helps")
	var choosing: Array = []
	for i in 10:
		choosing.append({"type": "choice" if i < 6 else ("truefalse" if i < 8 else "sort")})
	assert_true(_mostly_choice(choosing), "8 of 10 choice or true-or-false is mostly choice")
	choosing[7] = {"type": "match"}
	assert_false(_mostly_choice(choosing), "7 of 10 is at the bar")
	assert_false(_mostly_choice([]), "no hand-written exercises: generators only")
	assert_not_null(_body.search("a skinny dog"), "a body-shape word")
	assert_null(_body.search("a slimy snail"), "a whole word only")
	assert_not_null(_body.search("a fatty cat"), "fatty about a body")
	assert_null(_body.search("lipase makes fatty acids and glycerol"), "fatty acids are chemistry, not a body word")
