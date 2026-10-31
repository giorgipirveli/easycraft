class_name CourseBook
extends RefCounted
## A world's courses (M3 Task 7), saved in WorldMeta.smart: each keyed by its START block, with the FINISH its
## first finished run ended on (a tap on FINISH finds the course), the builder's goals (gold, silver, bronze
## ms; the first finished run sets them, CourseRules.default_goals), the best time and who ran it, and the
## best run recorded (RecordedRun) for bot friends to race. At most MAX_COURSES courses and MAX_GHOSTS
## recordings: the courses raced least lately give way. Pure; checked when loaded.
## M4 ghost races: also the world owner's own best time and run ("mine"), apart from anyone's best: the run the
## child can share as a ghost (at most MAX_MINE recordings; one recording when both are the same run).

const MAX_COURSES := 16
const MAX_GHOSTS := 8
const MAX_MINE := 8                      # M4 ghost races: the owner's own recordings
const MAX_NAME := 32
const NONE := Vector3i(2147483647, 2147483647, 2147483647)
const _FAR := 100000000.0

var _courses: Array[Dictionary] = []   # raced least lately first


func starts() -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for c in _courses:
		out.append(c.start)
	return out


## The course that starts at `start` ({} when there is none).
func course(start: Vector3i) -> Dictionary:
	for c in _courses:
		if c.start == start:
			return c
	return {}


func goals(start: Vector3i) -> Array[int]:
	var c := course(start)
	var out: Array[int] = []
	if not c.is_empty():
		out = c.goals
	return out


func best(start: Vector3i) -> int:
	return int(course(start).get("best", 0))


func ghost(start: Vector3i) -> RecordedRun:
	return course(start).get("ghost")


## The START of the course that finishes at `cell`, or NONE.
func start_of_finish(cell: Vector3i) -> Vector3i:
	for c in _courses:
		if c.finish == cell:
			return c.start
	return NONE


## The nearest course within `radius` of `pos` with a recorded best run (a bot can race it), or NONE.
func nearest_with_ghost(pos: Vector3, radius: float) -> Vector3i:
	var best_start := NONE
	var best_d := radius
	for c in _courses:
		if c.ghost == null:
			continue
		var d := CourseRules.top_of(c.start).distance_to(pos)
		if d <= best_d:
			best_d = d
			best_start = c.start
	return best_start


## A run from `start` ended on `finish` in `ms`, by `runner` (`path`: its way, or null). The first finished run
## sets the goals; a new best keeps its name and recording. `own`: the world owner's run (M4 ghost races: their
## own best is kept too). {medal, best, first, mine_best}.
func finished(start: Vector3i, finish: Vector3i, ms: int, runner: String, path: RecordedRun, own: bool = false) -> Dictionary:
	var c := course(start)
	var first := c.is_empty() or (c.goals as Array).is_empty()
	if c.is_empty():
		c = _new_course(start)
		_courses.append(c)
		_trim()
	else:
		_courses.erase(c)
		_courses.append(c)                  # raced lately
	if c.finish == NONE:
		c.finish = finish
	if first:
		c.goals = CourseRules.default_goals(ms)
	var is_best: bool = int(c.best) <= 0 or ms < int(c.best)
	if is_best:
		c.best = ms
		c.best_name = runner.substr(0, MAX_NAME)
		if path != null and not path.full and path.size() >= 2:
			c.ghost = path
			_trim_ghosts(c)
	var mine_best := own and (int(c.mine_ms) <= 0 or ms < int(c.mine_ms))
	if mine_best:
		c.mine_ms = ms
		c.mine = path if path != null and not path.full and path.size() >= 2 else null
		_trim_mine(c)
	return {"medal": CourseRules.medal(ms, c.goals), "best": is_best, "first": first, "mine_best": mine_best}


## The builder's goals for the course at `start` (cleaned). False when there is no such course or they
## are broken.
func set_goals(start: Vector3i, new_goals: Variant) -> bool:
	var c := course(start)
	var g := CourseRules.clean_goals(new_goals)
	if c.is_empty() or g.is_empty():
		return false
	c.goals = g
	return true


func _new_course(start: Vector3i) -> Dictionary:
	return {"start": start, "finish": NONE, "goals": [] as Array[int], "best": 0, "best_name": "", "ghost": null,
		"mine_ms": 0, "mine": null}


func _trim() -> void:
	while _courses.size() > MAX_COURSES:
		_courses.pop_front()


## At most MAX_GHOSTS recordings: the ones raced least lately go first (never `keep`'s).
func _trim_ghosts(keep: Dictionary) -> void:
	var n := 0
	for c in _courses:
		if c.ghost != null:
			n += 1
	for c in _courses:
		if n <= MAX_GHOSTS:
			return
		if c.ghost != null and c != keep:
			c.ghost = null
			n -= 1


## {"courses": [{start, finish?, goals, best, best_name, ghost?}, ...]} (raced least lately first).
func to_save() -> Dictionary:
	var list := []
	for c in _courses:
		var s: Vector3i = c.start
		var e := {"start": [s.x, s.y, s.z], "goals": c.goals, "best": c.best, "best_name": c.best_name}
		if c.finish != NONE:
			var f: Vector3i = c.finish
			e.finish = [f.x, f.y, f.z]
		if c.ghost != null:
			e.ghost = (c.ghost as RecordedRun).to_save()
		if int(c.mine_ms) > 0:   # M4 ghost races: the owner's own best
			e.mine_ms = c.mine_ms
			if c.mine != null and c.mine == c.ghost:
				e.mine_is_best = true
			elif c.mine != null:
				e.mine = (c.mine as RecordedRun).to_save()
		list.append(e)
	return {"courses": list}


## Never fails: a course without a good START is dropped; broken goals, times, names, finishes and
## recordings are cleaned or dropped; at most MAX_COURSES (and MAX_GHOSTS recordings).
static func from_save(data: Variant) -> CourseBook:
	var book := CourseBook.new()
	if not data is Dictionary or not (data as Dictionary).get("courses") is Array:
		return book
	for entry: Variant in data.courses:
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry
		var start: Variant = _cell(e.get("start"))
		if start == null or not book.course(start).is_empty():
			continue
		var c := book._new_course(start)
		var f: Variant = _cell(e.get("finish"))
		if f != null:
			c.finish = f
		c.goals = CourseRules.clean_goals(e.get("goals"))
		var b: Variant = e.get("best")
		c.best = int(b) if typeof(b) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(b)) and float(b) > 0.0 \
			and float(b) <= CourseRules.RUN_MAX_MS else 0
		c.best_name = (e.best_name as String).substr(0, MAX_NAME) if e.get("best_name") is String else ""
		c.ghost = RecordedRun.from_save(e.get("ghost"))
		var m: Variant = e.get("mine_ms")   # M4 ghost races
		if typeof(m) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(m)) and float(m) > 0.0 and float(m) <= CourseRules.RUN_MAX_MS:
			c.mine_ms = int(m)
			c.mine = c.ghost if e.get("mine_is_best") is bool and e.mine_is_best else RecordedRun.from_save(e.get("mine"))
		book._courses.append(c)
		book._trim()
	if not book._courses.is_empty():
		book._trim_ghosts(book._courses.back())
		book._trim_mine(book._courses.back())
	return book


# --- M4 ghost races: the world owner's own best ---

## The owner's own best time on the course at `start` (0: none yet).
func mine_ms(start: Vector3i) -> int:
	return int(course(start).get("mine_ms", 0))


## The owner's own best run on the course at `start` (the ghost they can share), or null.
func mine(start: Vector3i) -> RecordedRun:
	return course(start).get("mine")


## At most MAX_MINE own recordings (the courses raced least lately give theirs up first, never `keep`'s).
func _trim_mine(keep: Dictionary) -> void:
	var n := 0
	for c in _courses:
		if c.mine != null:
			n += 1
	for c in _courses:
		if n <= MAX_MINE:
			return
		if c.mine != null and c != keep:
			c.mine = null
			n -= 1


static func _cell(v: Variant) -> Variant:
	if not v is Array or (v as Array).size() != 3:
		return null
	for x: Variant in v:
		if not typeof(x) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(x)) or absf(float(x)) > _FAR:
			return null
	return Vector3i(int(v[0]), int(v[1]), int(v[2]))
