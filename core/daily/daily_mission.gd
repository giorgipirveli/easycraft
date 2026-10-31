class_name DailyMission
extends RefCounted
## Owner #85 (Wordle's lesson; the world game plan §2b; brief docs/superpowers/plans/2026-09-30-daily-mission-brief.md
## item 1): the Daily Mission. One short challenge a day, **the same for every player of a grade**: seeded by the UTC
## day and the grade, SIZE exercises from that grade's generators across subjects, easy to harder (LEVELS). A subject's
## unit is picked from the outline (only its written units, never an Explorer lesson a child must buy); the unit's
## generators come first (a generator makes any level), a unit with none gives one of its own exercises. Only the few
## picked units are read (the School's files are never all loaded).
## "The same" holds for one version of the game's School (a new version may add units: the card names the date and
## grade, so friends still compare the same day). The card's words show the stars, never the answers, and carry the
## invite link (InviteRules). Nothing pushes: no timers, no countdown, a missed day is a rest day (DailyData).

const SIZE := 5
const LEVELS: Array[int] = [1, 1, 2, 2, 3]
const DAY_SECONDS := 86400
const SEED_MIX := 1_000_003
const MONTHS: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September",
	"October", "November", "December"]

const GROWN_UPS_LINE := "Grown-ups: share today's mission card. It shows the stars, never the answers, and carries " \
	+ "only the invite link."
const REST_LINE := "Rest days are fine: your mission days never go down."
const DONE_LINE := "A new mission comes every day, the same for your whole grade."
const STAR_TEXT := "⭐"      # the shared text's pictures (messages show them; the game's own font draws its stars)
const MISS_TEXT := "⚪"


## The UTC day number of a unix time.
static func day_of(unix: float) -> int:
	return floori(unix / DAY_SECONDS)


static func today() -> int:
	return day_of(Time.get_unix_time_from_system())


static func date_key(day: int) -> String:
	var d := Time.get_date_dict_from_unix_time(day * DAY_SECONDS)
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]


static func date_words(day: int) -> String:
	var d := Time.get_date_dict_from_unix_time(day * DAY_SECONDS)
	return "%d %s %d" % [int(d.day), MONTHS[clampi(int(d.month) - 1, 0, 11)], int(d.year)]


static func seed_of(day: int, grade: int) -> int:
	return day * SEED_MIX + grade * 7919


## The grade's written units of a subject (outline only: a unit that names its file; Explorer lessons left out).
static func units(grade: int, subject: String) -> Array[String]:
	var out: Array[String] = []
	for u: Dictionary in Curriculum.units(grade, subject):
		if str(u.get("file", "")) != "" and not SpendRules.is_bonus(u):
			out.append(str(u.get("id", "")))
	return out


## The grade's subjects that have written units, in the School's order.
static func subjects(grade: int) -> Array[String]:
	var out: Array[String] = []
	for s: Dictionary in Curriculum.subjects(grade):
		var id := str(s.get("id", ""))
		if not units(grade, id).is_empty():
			out.append(id)
	return out


## The day's mission for `grade`: SIZE exercises (ExerciseCheck's form, each with "daily_subject" and "daily_unit"),
## easy to harder; fewer only when the grade has nothing written.
static func plan(day: int, grade: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var order := subjects(grade)
	if order.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_of(day, grade)
	GenKit.shuffle(rng, order)
	for i in SIZE:
		for k in order.size():   # a subject whose units can't be read gives way to the next
			var ex := _exercise(grade, order[(i + k) % order.size()], LEVELS[i], rng)
			if not ex.is_empty():
				out.append(ex)
				break
	return out


static func _exercise(grade: int, subject: String, level: int, rng: RandomNumberGenerator) -> Dictionary:
	var list := units(grade, subject)
	if list.is_empty():
		return {}
	var start := rng.randi_range(0, list.size() - 1)
	var seed := rng.randi()   # drawn every time: later picks never depend on what a file holds
	for k in list.size():
		var id := list[(start + k) % list.size()]
		var ex := _from_content(Curriculum.content(id), level, seed)
		if not ex.is_empty():
			ex.daily_subject = subject
			ex.daily_unit = id
			return ex
	return {}


## One exercise of a written unit: a generator of it at `level`, else its own exercise nearest that level (a choice's
## choices in a seeded order, as the School's rounds show them).
static func _from_content(c: Dictionary, level: int, seed: int) -> Dictionary:
	if c.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var gens: Array[String] = []
	for g: Variant in c.get("generators", []):
		if g is Dictionary and SchoolGen.exists(str((g as Dictionary).get("gen", ""))) and not gens.has(str(g.gen)):
			gens.append(str(g.gen))
	if not gens.is_empty():
		var made := SchoolGen.make(gens[rng.randi_range(0, gens.size() - 1)], rng.randi(), level)
		if not made.is_empty() and ExerciseCheck.problem(made) == "":
			return made
	var own: Array = (c.get("exercises", []) as Array).filter(func(ex: Variant) -> bool:
		return ex is Dictionary and ExerciseCheck.problem(ex) == "")
	if own.is_empty():
		return {}
	var best := -1
	for ex: Dictionary in own:
		var l := int(ex.get("level", 1))
		if best < 0 or absi(l - level) < absi(best - level) or (absi(l - level) == absi(best - level) and l < best):
			best = l
	var near: Array = own.filter(func(ex: Dictionary) -> bool: return int(ex.get("level", 1)) == best)
	return RoundPlan._mixed((near[rng.randi_range(0, near.size() - 1)] as Dictionary).duplicate(true), seed)


# --- Words and the card --------------------------------------------------------------------------------------------

static func stars_in(stars: String) -> int:
	return stars.count("1")


static func score_words(stars: int) -> String:
	return "Today's Mission: %d of %d!" % [stars, SIZE]


static func praise(stars: int) -> String:
	if stars >= SIZE:
		return "Every one right the first time. Brilliant!"
	if stars >= 3:
		return "Great work! Every answer helps you learn."
	return "Well done for trying every one. That's how we learn!"


static func intro_words(grade: int) -> String:
	return "%d questions from your grade's subjects. The same mission for every grade %d explorer today!" % [SIZE, grade]


static func days_words(n: int) -> String:
	return "%d mission day%s" % [n, "" if n == 1 else "s"]


## The stars as the shared text's pictures ("⭐⭐⭐⭐⚪"), like Wordle's grid: no answers.
static func share_stars(stars: String) -> String:
	var out := ""
	for c in stars:
		out += STAR_TEXT if c == "1" else MISS_TEXT
	return out


## The invite link when the child has a code, else the game's own page.
static func link(code: String) -> String:
	return InviteRules.link(code) if code != "" else InviteRules.PLAY_URL


## What SHARE and COPY pass on: the date, the grade, the stars and the invite (never a question or an answer).
static func share_text(day: int, grade: int, stars: String, code: String) -> String:
	var head := "EasyCraft Daily Mission, %s, grade %d\n%s %s\n" % [date_words(day), grade, share_stars(stars),
		score_words(stars_in(stars))]
	if code != "":
		return head + InviteRules.share_text(code)
	return head + "Come and learn with me in EasyCraft!\n" + InviteRules.PLAY_URL
