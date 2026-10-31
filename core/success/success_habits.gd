class_name SuccessHabits
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2.6, §3; the brief: "one small good habit chosen; a plant grows on each
## day it is kept; a missed day never kills it: gentle, never guilt; no streak pressure"): the habit garden's rules over
## SuccessData.habit and .garden. The habits are data/success/goals.json's ("habits": small good things, each with a
## picture). Once a day the child says whether they did it; "not today" is thanked (honesty is the point) and today's
## answer can be changed. The plant grows a little on every kept day and never shrinks: days are counted in all, never
## in a row, and nothing here counts a run of days. Habits take weeks to stick and one missed day hardly matters
## (Lally et al. 2010): the words say so. Choosing another habit starts its own plant; the first stays in the garden at
## its size and grows on if the child comes back to it.

## Days kept for each stage: a seed, a sprout, two leaves, four leaves, a little plant, a bushy plant, a bud, a flower.
const STAGES: Array[int] = [0, 1, 3, 5, 8, 12, 18, 25]
const STAGE_WORDS: Array[String] = ["a seed", "a sprout", "two leaves", "four leaves", "a little plant", "a bushy plant",
	"a bud", "a flower"]
## After the flower, one more flower every FLOWER_DAYS kept days, up to MAX_FLOWERS.
const FLOWER_DAYS := 7
const MAX_FLOWERS := 8
const PICK := "Pick one small good habit. Your plant grows on every day you do it."
const ASK := "Did you do it today?"
const GREW := "Well done! Your plant grew."
const NOT_TODAY := "That's OK. Thank you for being honest. Tomorrow is a new day."
const BACK := "Welcome back! Your plant waited for you. Did you do it today?"
const TAKES_TIME := "Habits take a few weeks to stick, and one day off hardly matters. Just carry on."


static func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h: Variant in SuccessGoals.data().get("habits", []):
		if h is Dictionary:
			out.append(h)
	return out


static func habit(id: String) -> Dictionary:
	for h in list():
		if str(h.id) == id:
			return h
	return {}


static func title(id: String) -> String:
	return str(habit(id).get("title", ""))


## Starts the plant of habit `id` on `day` (false for an unknown habit). The plant growing now goes into the garden at
## its size; a habit already in the garden comes back with its days.
static func choose(d: SuccessData, id: String, day: int) -> bool:
	if habit(id).is_empty():
		return false
	if not d.habit.is_empty() and str(d.habit.h) == id:
		return true
	if not d.habit.is_empty() and int(d.habit.n) > 0:
		d.into_garden(str(d.habit.h), int(d.habit.n))
	var n := 0
	for i in range(d.garden.size() - 1, -1, -1):
		if str(d.garden[i].h) == id:
			n = int(d.garden[i].n)
			d.garden.remove_at(i)
	d.habit = {"h": id, "c": day, "k": [], "n": n, "l": 0, "y": false}
	return true


## Today's answer: yes grows the plant (once a day); no is thanked; a yes changed to no today takes today's day back.
static func answer(d: SuccessData, day: int, yes: bool) -> void:
	if d.habit.is_empty() or day <= 0:
		return
	var days: Array = d.habit.k
	if yes and not days.has(day):
		days.append(day)
		days.sort()
		if days.size() > SuccessData.MAX_DAYS:
			days.pop_front()
		d.habit.n = mini(int(d.habit.n) + 1, SuccessData.MAX_COUNT)
	elif not yes and days.has(day):
		days.erase(day)
		d.habit.n = maxi(int(d.habit.n) - 1, 0)
	d.habit.l = maxi(int(d.habit.l), day)
	if int(d.habit.l) == day:
		d.habit.y = yes


static func kept_on(d: SuccessData, day: int) -> bool:
	return not d.habit.is_empty() and (d.habit.k as Array).has(day)


static func answered_on(d: SuccessData, day: int) -> bool:
	return not d.habit.is_empty() and int(d.habit.l) == day


static func days_kept(d: SuccessData) -> int:
	return int(d.habit.get("n", 0)) if not d.habit.is_empty() else 0


## The plant's stage (0 .. STAGES.size() - 1) after `n` kept days: it only ever grows.
static func stage(n: int) -> int:
	var s := 0
	for i in STAGES.size():
		if n >= STAGES[i]:
			s = i
	return s


## Flowers after the first one (a plant kept for weeks flowers more).
static func flowers(n: int) -> int:
	if n < STAGES.back():
		return 0
	return mini(1 + (n - STAGES.back()) / FLOWER_DAYS, MAX_FLOWERS)


## Days kept in the 7 days up to `day`.
static func this_week(d: SuccessData, day: int) -> int:
	var n := 0
	for k: Variant in d.habit.get("k", []):
		if int(k) <= day and day - int(k) < 7:
			n += 1
	return n


## What the garden says now: pick a habit, ask today, thank today's answer, or welcome back after days away.
static func words(d: SuccessData, day: int) -> String:
	if d.habit.is_empty():
		return PICK
	if answered_on(d, day):
		return GREW if bool(d.habit.y) else NOT_TODAY
	if int(d.habit.l) > 0 and day - int(d.habit.l) >= 2:
		return BACK
	return ASK


## The grown-ups' honest line ("" before a habit was chosen and kept).
static func grown_ups_line(d: SuccessData) -> String:
	if d.habit.is_empty():
		return ""
	var n := days_kept(d)
	return "Habit: %s. Kept on %d day%s since %s (in all, not in a row: a missed day takes nothing away)." % [
		title(str(d.habit.h)), n, "" if n == 1 else "s", SchoolClock.short_date(int(d.habit.c))]
