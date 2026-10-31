class_name Curriculum
extends RefCounted
## Owner #68 (spec §22.4, §22.5): the School's curriculum, as data.
## - `data/school/grade<N>.json` (grades 3-8): {grade, ages, subjects: [{id, title, framework, units: [{id, title,
##   standards, goals, file?}]}]}; subjects in SUBJECTS order; a unit id is "g<N>.<subject>.<name>" (SchoolData.valid_id).
## - A written unit names its `file` (under data/school/): {id, lesson: [{text, picture?}], exercises: [ExerciseCheck
##   data], generators: [{gen, level}], play?: its play block (owner #122, PlayBlock)}. A unit without a file, or whose
##   file is missing or broken, is "Coming soon".
## Files are read the first time they are asked for and kept (clear_cache for tests); nothing loads at the game's start.

const DIR := "res://data/school"
## Every school subject, in the order of the School's tabs (owner #70, 2026-09-29: every subject a school teaches; the
## forever roadmap §1). A grade's file lists the subjects it has, in this order.
## The ids and frameworks: docs/design/school-curriculum-research.md §5.2 (eleven subjects and Projects).
const SUBJECTS: Array[String] = ["maths", "science", "english", "history", "geography", "citizenship", "computing", "art",
	"music", "health_pe", "design_tech", "projects"]
const CORE: Array[String] = ["maths", "science", "english"]   # every grade has these
const MAX_UNITS := 18          # the map's grid (spec §22.4)
const MAX_GOALS := 4
const MIN_CARDS := 2
const MAX_CARDS := 8

static var _grades := {}       # grade -> its parsed file ({} when missing or broken)
static var _content := {}      # unit id -> its parsed content ({} when none)


static func grades() -> Array[int]:
	return SchoolData.GRADES.duplicate()


static func grade(g: int) -> Dictionary:
	if not _grades.has(g):
		_grades[g] = parse_grade(_read("%s/grade%d.json" % [DIR, g]))
	return _grades[g]


## Tests: use `d` as grade g's outline.
static func put_grade(g: int, d: Dictionary) -> void:
	_grades[g] = d
	_content.clear()


## Tests: use `c` as unit id's written content (its id and exercise ids as the loader gives them).
static func put_content(id: String, c: Dictionary) -> void:
	_content[id] = parse_content(id, JSON.stringify(c))


static func clear_cache() -> void:
	_grades.clear()
	_content.clear()


static func parse_grade(text: String) -> Dictionary:
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or not json.data is Dictionary:
		return {}
	var d: Dictionary = json.data
	return d if d.get("subjects") is Array else {}


static func subjects(g: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Variant in grade(g).get("subjects", []):
		if s is Dictionary:
			out.append(s)
	return out


static func subject(g: int, id: String) -> Dictionary:
	for s in subjects(g):
		if str(s.get("id", "")) == id:
			return s
	return {}


static func units(g: int, subject_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u: Variant in subject(g, subject_id).get("units", []):
		if u is Dictionary:
			out.append(u)
	return out


## The outline's entry for `id`, with its grade, subject and number (1 = first on the map); {} when there is none.
static func unit(id: String) -> Dictionary:
	if not SchoolData.valid_id(id):
		return {}
	var parts := id.split(".")
	var g := int(parts[0].substr(1))
	var list := units(g, parts[1])
	for i in list.size():
		if str(list[i].get("id", "")) == id:
			var out := list[i].duplicate(true)
			out.grade = g
			out.subject = parts[1]
			out.number = i + 1
			return out
	return {}


## The written unit (lesson, exercises with ids, generators); {} for "Coming soon".
static func content(id: String) -> Dictionary:
	if not _content.has(id):
		var u := unit(id)
		var file := str(u.get("file", ""))
		_content[id] = parse_content(id, _read(DIR.path_join(file))) if file != "" else {}
	return _content[id]


static func has_content(id: String) -> bool:
	return not content(id).is_empty()


## Whether grade g's subject has a written unit (the School's map shows its tab then; CORE subjects always show).
static func has_written(g: int, subject_id: String) -> bool:
	for u in units(g, subject_id):
		if has_content(str(u.get("id", ""))):
			return true
	return false


## A unit file's text as content for unit `id` ({} when broken or another unit's); each exercise gets its id
## ("<unit>#<index>") and a level (1 when it has none).
static func parse_content(id: String, text: String) -> Dictionary:
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or not json.data is Dictionary:
		return {}
	var d: Dictionary = json.data
	if str(d.get("id", "")) != id:
		return {}
	var out := {"id": id, "lesson": [], "exercises": [], "generators": []}
	for card: Variant in d.get("lesson", []):
		if card is Dictionary:
			(out.lesson as Array).append(card)
	var list: Variant = d.get("exercises", [])
	if list is Array:
		for i in (list as Array).size():
			if list[i] is Dictionary:
				var ex: Dictionary = (list[i] as Dictionary).duplicate(true)
				ex.id = "%s#%d" % [id, i]
				ex.level = int(ex.get("level", 1)) if typeof(ex.get("level", 1)) in [TYPE_INT, TYPE_FLOAT] else 0
				(out.exercises as Array).append(ex)
	for gen: Variant in d.get("generators", []):
		if gen is Dictionary:
			(out.generators as Array).append(gen)
	if d.has("play"):   # owner #122 (G0): the unit's play block, as written (PlayBlock checks it)
		out.play = d.play
	return out


## What is wrong with grade g's outline ([] when nothing).
static func outline_problems(g: int) -> Array[String]:
	var out: Array[String] = []
	var d := grade(g)
	if d.is_empty():
		return ["grade %d: no file or a broken one" % g]
	if int(d.get("grade", 0)) != g:
		out.append("grade %d: its file says grade %s" % [g, d.get("grade")])
	var ids: Array[String] = []
	for s in subjects(g):
		ids.append(str(s.get("id", "")))
	# Known subjects, each once, in the tabs' order; every grade keeps the core three (owner #70: every subject).
	var at := -1
	for id in ids:
		var i := SUBJECTS.find(id)
		if i <= at:
			out.append("grade %d: subject %s unknown, twice or out of order (%s)" % [g, id, ids])
		at = maxi(at, i)
	for core: String in CORE:
		if not ids.has(core):
			out.append("grade %d: no %s" % [g, core])
	var seen := {}
	for s in subjects(g):
		var list := units(g, str(s.id))
		if list.size() > MAX_UNITS:
			out.append("grade %d %s: %d units (at most %d)" % [g, s.id, list.size(), MAX_UNITS])
		for u in list:
			var id := str(u.get("id", ""))
			if not id.begins_with("g%d.%s." % [g, s.id]) or not SchoolData.valid_id(id):
				out.append("a bad unit id %s" % id)
			if seen.has(id):
				out.append("%s twice" % id)
			seen[id] = true
			if str(u.get("title", "")).strip_edges() == "":
				out.append("%s has no title" % id)
			var goals: Variant = u.get("goals")
			if not goals is Array or (goals as Array).is_empty() or (goals as Array).size() > MAX_GOALS:
				out.append("%s needs 1-%d goals" % [id, MAX_GOALS])
			var standards: Variant = u.get("standards")
			if not standards is Array or (standards as Array).is_empty():
				out.append("%s needs its standards" % id)
			if u.has("file") and not has_content(id):
				out.append("%s names %s, which is missing or not its content" % [id, u.file])
	return out


## What is wrong with a written unit's content ([] when nothing): its lesson cards, every exercise (ExerciseCheck) and
## every generator it names (SchoolGen).
static func content_problems(id: String) -> Array[String]:
	var out: Array[String] = []
	var c := content(id)
	if c.is_empty():
		return ["%s is not written" % id]
	var cards: Array = c.lesson
	if cards.size() < MIN_CARDS or cards.size() > MAX_CARDS:
		out.append("%s: %d lesson cards (%d-%d)" % [id, cards.size(), MIN_CARDS, MAX_CARDS])
	for i in cards.size():
		if str(cards[i].get("text", "")).strip_edges() == "":
			out.append("%s: lesson card %d has no text" % [id, i + 1])
		if cards[i].has("picture") and not cards[i].picture is Dictionary:
			out.append("%s: lesson card %d's picture" % [id, i + 1])
	for ex: Dictionary in c.exercises:
		var why := ExerciseCheck.problem(ex)
		if why != "":
			out.append("%s: %s" % [ex.id, why])
	for gen: Dictionary in c.generators:
		if not SchoolGen.exists(str(gen.get("gen", ""))):
			out.append("%s: no generator %s" % [id, gen.get("gen", "")])
		var level: Variant = gen.get("level", 1)
		if typeof(level) not in [TYPE_INT, TYPE_FLOAT] or int(level) < 1 or int(level) > 3:
			out.append("%s: %s's level" % [id, gen.get("gen", "")])
	if c.exercises.is_empty() and c.generators.is_empty():
		out.append("%s has nothing to practise" % id)
	for why in PlayBlock.problems(c.get("play")):   # owner #122 (G0): the play block's format
		out.append("%s: %s" % [id, why])
	return out


static func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
